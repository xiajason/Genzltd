#!/bin/bash

# JobFirst系统腾讯云轻量服务器部署脚本
# 用于在腾讯云轻量应用服务器上直接部署系统

set -e

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 配置变量
SERVER_IP=""
SERVER_USER="root"
SERVER_PORT="22"
DEPLOY_PATH="/opt/jobfirst"
BACKUP_PATH="/opt/jobfirst-backup"

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 显示帮助信息
show_help() {
    echo -e "${CYAN}JobFirst系统腾讯云轻量服务器部署脚本${NC}"
    echo ""
    echo "用法: $0 <服务器IP> [选项]"
    echo ""
    echo "参数:"
    echo "  <服务器IP>    腾讯云轻量服务器的公网IP地址"
    echo ""
    echo "选项:"
    echo "  --user USER    服务器用户名 (默认: root)"
    echo "  --port PORT    SSH端口 (默认: 22)"
    echo "  --path PATH    部署路径 (默认: /opt/jobfirst)"
    echo "  --backup       部署前备份现有系统"
    echo "  --restart      部署后重启服务"
    echo "  --help         显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 123.456.789.0"
    echo "  $0 123.456.789.0 --user ubuntu --port 2222"
    echo "  $0 123.456.789.0 --backup --restart"
    echo ""
    echo "前置条件:"
    echo "  1. 服务器已安装: Go 1.21+, Python 3.11+, Node.js 18+, MySQL 8.0, Redis 7.0"
    echo "  2. 服务器已配置: Nginx, 防火墙规则"
    echo "  3. 本地已配置: SSH密钥认证"
    echo "  4. 服务器已创建: 数据库和用户"
}

# 检查前置条件
check_prerequisites() {
    log_info "检查部署前置条件..."
    
    # 检查服务器IP
    if [ -z "$SERVER_IP" ]; then
        log_error "请提供服务器IP地址"
        show_help
        exit 1
    fi
    
    # 检查SSH连接
    log_info "测试SSH连接..."
    if ! ssh -o ConnectTimeout=10 -o BatchMode=yes $SERVER_USER@$SERVER_IP "echo 'SSH连接成功'" > /dev/null 2>&1; then
        log_error "无法连接到服务器 $SERVER_IP"
        log_info "请确保:"
        log_info "  1. 服务器IP地址正确"
        log_info "  2. SSH服务正在运行"
        log_info "  3. 已配置SSH密钥认证"
        log_info "  4. 防火墙允许SSH连接"
        exit 1
    fi
    
    log_success "SSH连接正常"
    
    # 检查服务器环境
    log_info "检查服务器环境..."
    ssh $SERVER_USER@$SERVER_IP << 'EOF'
        # 检查Go版本
        if ! command -v go &> /dev/null; then
            echo "ERROR: Go未安装"
            exit 1
        fi
        echo "Go版本: $(go version)"
        
        # 检查Python版本
        if ! command -v python3 &> /dev/null; then
            echo "ERROR: Python3未安装"
            exit 1
        fi
        echo "Python版本: $(python3 --version)"
        
        # 检查Node.js版本
        if ! command -v node &> /dev/null; then
            echo "ERROR: Node.js未安装"
            exit 1
        fi
        echo "Node.js版本: $(node --version)"
        
        # 检查MySQL
        if ! command -v mysql &> /dev/null; then
            echo "ERROR: MySQL未安装"
            exit 1
        fi
        echo "MySQL已安装"
        
        # 检查Redis
        if ! command -v redis-server &> /dev/null; then
            echo "ERROR: Redis未安装"
            exit 1
        fi
        echo "Redis已安装"
        
        # 检查Nginx
        if ! command -v nginx &> /dev/null; then
            echo "ERROR: Nginx未安装"
            exit 1
        fi
        echo "Nginx已安装"
        
        echo "服务器环境检查完成"
EOF
    
    if [ $? -eq 0 ]; then
        log_success "服务器环境检查通过"
    else
        log_error "服务器环境检查失败"
        exit 1
    fi
}

# 备份现有系统
backup_existing_system() {
    log_info "备份现有系统..."
    
    ssh $SERVER_USER@$SERVER_IP << EOF
        if [ -d "$DEPLOY_PATH" ]; then
            log_info "备份现有部署到 $BACKUP_PATH"
            sudo rm -rf $BACKUP_PATH
            sudo cp -r $DEPLOY_PATH $BACKUP_PATH
            sudo chown -R $SERVER_USER:$SERVER_USER $BACKUP_PATH
            echo "备份完成: $BACKUP_PATH"
        else
            echo "没有找到现有部署，跳过备份"
        fi
EOF
    
    log_success "系统备份完成"
}

# 创建部署目录结构
create_deploy_structure() {
    log_info "创建部署目录结构..."
    
    ssh $SERVER_USER@$SERVER_IP << EOF
        # 创建部署目录
        sudo mkdir -p $DEPLOY_PATH
        sudo chown -R $SERVER_USER:$SERVER_USER $DEPLOY_PATH
        
        # 创建子目录
        mkdir -p $DEPLOY_PATH/{backend,frontend,scripts,configs,logs,uploads}
        mkdir -p $DEPLOY_PATH/backend/{cmd,internal,pkg}
        mkdir -p $DEPLOY_PATH/frontend/{dist,src}
        
        echo "部署目录结构创建完成"
EOF
    
    log_success "部署目录结构创建完成"
}

# 部署后端代码
deploy_backend() {
    log_info "部署后端代码..."
    
    # 创建临时压缩包
    local temp_dir=$(mktemp -d)
    local backend_archive="$temp_dir/backend.tar.gz"
    
    # 压缩后端代码
    tar -czf "$backend_archive" \
        --exclude="*.log" \
        --exclude="tmp" \
        --exclude="temp" \
        --exclude="node_modules" \
        --exclude=".git" \
        backend/
    
    # 上传到服务器
    scp "$backend_archive" $SERVER_USER@$SERVER_IP:/tmp/
    
    # 解压到部署目录
    ssh $SERVER_USER@$SERVER_IP << EOF
        cd $DEPLOY_PATH
        tar -xzf /tmp/backend.tar.gz
        rm /tmp/backend.tar.gz
        
        # 设置权限
        chmod +x backend/scripts/*.sh
        
        echo "后端代码部署完成"
EOF
    
    # 清理临时文件
    rm -rf "$temp_dir"
    
    log_success "后端代码部署完成"
}

# 部署前端代码
deploy_frontend() {
    log_info "部署前端代码..."
    
    # 检查前端是否已构建
    if [ ! -d "frontend-taro/dist" ]; then
        log_warning "前端未构建，开始构建..."
        cd frontend-taro
        npm run build:h5
        cd ..
    fi
    
    # 创建临时压缩包
    local temp_dir=$(mktemp -d)
    local frontend_archive="$temp_dir/frontend.tar.gz"
    
    # 压缩前端代码
    tar -czf "$frontend_archive" \
        --exclude="node_modules" \
        --exclude=".git" \
        --exclude="src" \
        --exclude="*.log" \
        -C frontend-taro dist/
    
    # 上传到服务器
    scp "$frontend_archive" $SERVER_USER@$SERVER_IP:/tmp/
    
    # 解压到部署目录
    ssh $SERVER_USER@$SERVER_IP << EOF
        cd $DEPLOY_PATH
        tar -xzf /tmp/frontend.tar.gz
        rm /tmp/frontend.tar.gz
        
        echo "前端代码部署完成"
EOF
    
    # 清理临时文件
    rm -rf "$temp_dir"
    
    log_success "前端代码部署完成"
}

# 部署配置文件
deploy_configs() {
    log_info "部署配置文件..."
    
    # 创建生产环境配置
    cat > /tmp/config.prod.yaml << 'EOF'
# JobFirst Production Configuration

# 环境配置
environment: production
version: "1.0.0"
mode: "basic"

# 服务器配置
server:
  port: "8080"
  host: "0.0.0.0"
  read_timeout: 30s
  write_timeout: 30s
  max_header_bytes: 1048576

# 数据库配置 (生产环境)
database:
  driver: "mysql"
  host: "localhost"
  port: "3306"
  name: "jobfirst"
  user: "jobfirst"
  password: "jobfirst_prod_2024"
  charset: "utf8mb4"
  parse_time: true
  loc: "Local"
  max_open_conns: 100
  max_idle_conns: 10
  conn_max_lifetime: 3600s

# Redis配置 (生产环境)
redis:
  host: "localhost"
  port: "6379"
  password: "redis_prod_2024"
  db: 0
  pool_size: 10
  min_idle_conns: 5
  max_retries: 3
  dial_timeout: 5s
  read_timeout: 3s
  write_timeout: 3s

# JWT配置
jwt:
  secret: "jobfirst-prod-secret-key-2024"
  expires_in: 24h
  refresh_expires_in: 168h
  issuer: "jobfirst-prod"

# 文件上传配置
upload:
  max_size: 10485760  # 10MB
  allowed_types: ["pdf", "doc", "docx", "jpg", "jpeg", "png"]
  upload_dir: "/opt/jobfirst/uploads"
  temp_dir: "/opt/jobfirst/temp"

# 日志配置
logging:
  level: "info"
  format: "json"
  output: "file"
  file: "/opt/jobfirst/logs/basic-server.log"
  max_size: 100
  max_age: 30
  max_backups: 10

# 缓存配置
cache:
  default_ttl: 3600s
  user_session_ttl: 7200s
  resume_data_ttl: 1800s
  template_data_ttl: 7200s

# 安全配置
security:
  bcrypt_cost: 12
  rate_limit: 1000
  rate_limit_window: 1m
  cors_origins: ["*"]
  cors_methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
  cors_headers: ["Origin", "Content-Type", "Accept", "Authorization", "API-Version", "X-Requested-With", "X-API-Key", "X-Client-Version"]

# 积分系统配置
points:
  default_balance: 100
  resume_create_reward: 10
  resume_share_reward: 5
  template_use_cost: 2
  file_upload_cost: 1

# AI功能配置
ai:
  enabled: true
  service_url: "http://localhost:8206"
  api_key: ""
  timeout: 30s
  max_retries: 3

# 监控配置
monitoring:
  enabled: true
  metrics_port: "9090"
  health_check_interval: 30s
  prometheus_enabled: true

# Consul服务发现配置
consul:
  enabled: true
  host: "localhost"
  port: "8500"
  scheme: "http"
  datacenter: "dc1"
  token: ""
  service_name: "jobfirst-backend"
  service_id: "jobfirst-backend-1"
  service_tags: ["jobfirst", "backend", "api"]
  health_check_url: "http://localhost:8080/api/v1/consul/status"
  health_check_interval: "10s"
  health_check_timeout: "3s"
  deregister_after: "30s"
EOF

    # 创建Nginx配置
    cat > /tmp/nginx.conf << 'EOF'
server {
    listen 80;
    server_name _;
    
    # 前端静态文件
    location / {
        root /opt/jobfirst/frontend/dist/build/h5;
        index index.html;
        try_files $uri $uri/ /index.html;
    }
    
    # API代理
    location /api/ {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # 超时设置
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }
    
    # AI服务代理
    location /ai/ {
        proxy_pass http://localhost:8206/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # 健康检查
    location /health {
        proxy_pass http://localhost:8080/api/v1/consul/status;
        access_log off;
    }
}
EOF

    # 创建AI服务配置
    cat > /tmp/ai_service.env << 'EOF'
# AI服务生产环境配置
AI_SERVICE_PORT=8206
POSTGRES_HOST=localhost
POSTGRES_USER=jobfirst
POSTGRES_DB=jobfirst_vector
POSTGRES_PASSWORD=postgres_prod_2024
LOG_LEVEL=INFO
LOG_FILE=/opt/jobfirst/logs/ai-service.log
WORKERS=4
MAX_REQUESTS=1000
MAX_REQUESTS_JITTER=100
EOF

    # 上传配置文件
    scp /tmp/config.prod.yaml $SERVER_USER@$SERVER_IP:$DEPLOY_PATH/configs/
    scp /tmp/nginx.conf $SERVER_USER@$SERVER_IP:$DEPLOY_PATH/configs/
    scp /tmp/ai_service.env $SERVER_USER@$SERVER_IP:$DEPLOY_PATH/configs/
    
    # 清理临时文件
    rm -f /tmp/config.prod.yaml /tmp/nginx.conf /tmp/ai_service.env
    
    log_success "配置文件部署完成"
}

# 安装依赖和构建
install_dependencies() {
    log_info "安装依赖和构建应用..."
    
    ssh $SERVER_USER@$SERVER_IP << EOF
        cd $DEPLOY_PATH
        
        # 安装Go依赖
        cd backend
        go mod tidy
        go mod download
        
        # 构建后端
        go build -o basic-server ./cmd/basic-server/main.go
        chmod +x basic-server
        
        # 安装Python依赖
        cd internal/ai-service
        pip3 install -r requirements.txt
        
        # 构建前端（如果需要）
        cd $DEPLOY_PATH/frontend
        if [ -d "dist" ]; then
            echo "前端已构建"
        else
            echo "前端需要构建"
        fi
        
        echo "依赖安装和构建完成"
EOF
    
    log_success "依赖安装和构建完成"
}

# 配置系统服务
setup_system_services() {
    log_info "配置系统服务..."
    
    # 创建后端服务
    cat > /tmp/jobfirst-backend.service << 'EOF'
[Unit]
Description=JobFirst Backend Service
After=network.target mysql.service redis.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/jobfirst/backend
ExecStart=/opt/jobfirst/backend/basic-server
Restart=always
RestartSec=5
Environment=GIN_MODE=release
Environment=CONFIG_PATH=/opt/jobfirst/configs/config.prod.yaml

[Install]
WantedBy=multi-user.target
EOF

    # 创建AI服务
    cat > /tmp/jobfirst-ai.service << 'EOF'
[Unit]
Description=JobFirst AI Service
After=network.target postgresql.service redis.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/jobfirst/backend/internal/ai-service
ExecStart=/usr/bin/python3 ai_service.py
Restart=always
RestartSec=5
EnvironmentFile=/opt/jobfirst/configs/ai_service.env

[Install]
WantedBy=multi-user.target
EOF

    # 上传服务文件
    scp /tmp/jobfirst-backend.service $SERVER_USER@$SERVER_IP:/tmp/
    scp /tmp/jobfirst-ai.service $SERVER_USER@$SERVER_IP:/tmp/
    
    # 安装服务
    ssh $SERVER_USER@$SERVER_IP << 'EOF'
        sudo mv /tmp/jobfirst-backend.service /etc/systemd/system/
        sudo mv /tmp/jobfirst-ai.service /etc/systemd/system/
        sudo systemctl daemon-reload
        sudo systemctl enable jobfirst-backend
        sudo systemctl enable jobfirst-ai
        echo "系统服务配置完成"
EOF
    
    # 清理临时文件
    rm -f /tmp/jobfirst-backend.service /tmp/jobfirst-ai.service
    
    log_success "系统服务配置完成"
}

# 配置数据库
setup_database() {
    log_info "配置数据库..."
    
    ssh $SERVER_USER@$SERVER_IP << 'EOF'
        # 创建MySQL数据库和用户
        mysql -u root -e "
            CREATE DATABASE IF NOT EXISTS jobfirst;
            CREATE USER IF NOT EXISTS 'jobfirst'@'localhost' IDENTIFIED BY 'jobfirst_prod_2024';
            GRANT ALL PRIVILEGES ON jobfirst.* TO 'jobfirst'@'localhost';
            FLUSH PRIVILEGES;
        "
        
        # 创建PostgreSQL数据库和用户
        sudo -u postgres psql -c "
            CREATE DATABASE jobfirst_vector;
            CREATE USER jobfirst WITH PASSWORD 'postgres_prod_2024';
            GRANT ALL PRIVILEGES ON DATABASE jobfirst_vector TO jobfirst;
        "
        
        # 导入数据库结构
        if [ -f "/opt/jobfirst/backend/database/mysql/init.sql" ]; then
            mysql -u jobfirst -pjobfirst_prod_2024 jobfirst < /opt/jobfirst/backend/database/mysql/init.sql
        fi
        
        echo "数据库配置完成"
EOF
    
    log_success "数据库配置完成"
}

# 启动服务
start_services() {
    log_info "启动服务..."
    
    ssh $SERVER_USER@$SERVER_IP << 'EOF'
        # 启动数据库服务
        sudo systemctl start mysql
        sudo systemctl start postgresql
        sudo systemctl start redis
        
        # 启动应用服务
        sudo systemctl start jobfirst-backend
        sudo systemctl start jobfirst-ai
        
        # 重启Nginx
        sudo systemctl restart nginx
        
        # 检查服务状态
        echo "=== 服务状态 ==="
        sudo systemctl status mysql --no-pager -l
        sudo systemctl status redis --no-pager -l
        sudo systemctl status jobfirst-backend --no-pager -l
        sudo systemctl status jobfirst-ai --no-pager -l
        sudo systemctl status nginx --no-pager -l
        
        echo "服务启动完成"
EOF
    
    log_success "服务启动完成"
}

# 验证部署
verify_deployment() {
    log_info "验证部署..."
    
    # 等待服务启动
    sleep 10
    
    # 检查服务状态
    ssh $SERVER_USER@$SERVER_IP << 'EOF'
        echo "=== 端口检查 ==="
        netstat -tlnp | grep -E ":(80|3306|6379|8080|8206|5432)"
        
        echo "=== 服务检查 ==="
        curl -f http://localhost:8080/api/v1/consul/status || echo "后端服务检查失败"
        curl -f http://localhost:8206/health || echo "AI服务检查失败"
        curl -f http://localhost/health || echo "Nginx检查失败"
        
        echo "=== 日志检查 ==="
        tail -n 10 /opt/jobfirst/logs/basic-server.log || echo "后端日志不存在"
        tail -n 10 /opt/jobfirst/logs/ai-service.log || echo "AI服务日志不存在"
EOF
    
    log_success "部署验证完成"
}

# 主部署函数
deploy_to_cloud() {
    local backup_flag="$1"
    local restart_flag="$2"
    
    log_info "开始部署到腾讯云轻量服务器: $SERVER_IP"
    
    # 检查前置条件
    check_prerequisites
    
    # 备份现有系统
    if [ "$backup_flag" = "true" ]; then
        backup_existing_system
    fi
    
    # 创建部署结构
    create_deploy_structure
    
    # 部署代码
    deploy_backend
    deploy_frontend
    deploy_configs
    
    # 安装依赖
    install_dependencies
    
    # 配置服务
    setup_system_services
    setup_database
    
    # 启动服务
    start_services
    
    # 验证部署
    verify_deployment
    
    log_success "=== 部署完成 ==="
    log_info "系统访问地址:"
    log_info "  前端: http://$SERVER_IP"
    log_info "  API: http://$SERVER_IP/api/v1/"
    log_info "  健康检查: http://$SERVER_IP/health"
    log_info ""
    log_info "管理命令:"
    log_info "  查看后端日志: ssh $SERVER_USER@$SERVER_IP 'tail -f /opt/jobfirst/logs/basic-server.log'"
    log_info "  查看AI服务日志: ssh $SERVER_USER@$SERVER_IP 'tail -f /opt/jobfirst/logs/ai-service.log'"
    log_info "  重启后端: ssh $SERVER_USER@$SERVER_IP 'sudo systemctl restart jobfirst-backend'"
    log_info "  重启AI服务: ssh $SERVER_USER@$SERVER_IP 'sudo systemctl restart jobfirst-ai'"
}

# 主函数
main() {
    local backup_flag="false"
    local restart_flag="false"
    
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            --user)
                SERVER_USER="$2"
                shift 2
                ;;
            --port)
                SERVER_PORT="$2"
                shift 2
                ;;
            --path)
                DEPLOY_PATH="$2"
                shift 2
                ;;
            --backup)
                backup_flag="true"
                shift
                ;;
            --restart)
                restart_flag="true"
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                if [ -z "$SERVER_IP" ]; then
                    SERVER_IP="$1"
                else
                    log_error "未知参数: $1"
                    show_help
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # 检查参数
    if [ -z "$SERVER_IP" ]; then
        log_error "请提供服务器IP地址"
        show_help
        exit 1
    fi
    
    # 执行部署
    deploy_to_cloud "$backup_flag" "$restart_flag"
}

# 执行主函数
main "$@"
