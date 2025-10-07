#!/bin/bash

# JobFirst系统CI/CD自动化部署脚本
# 支持GitHub Actions、GitLab CI等CI/CD平台

set -e

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置变量
SERVER_IP="${DEPLOY_SERVER_IP:-}"
SERVER_USER="${DEPLOY_SERVER_USER:-root}"
DEPLOY_PATH="${DEPLOY_PATH:-/opt/jobfirst}"
BRANCH="${GITHUB_REF_NAME:-main}"
COMMIT_SHA="${GITHUB_SHA:-$(git rev-parse HEAD)}"

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

# 检查环境变量
check_environment() {
    log_info "检查部署环境..."
    
    if [ -z "$SERVER_IP" ]; then
        log_error "DEPLOY_SERVER_IP环境变量未设置"
        exit 1
    fi
    
    if [ -z "$SSH_PRIVATE_KEY" ]; then
        log_error "SSH_PRIVATE_KEY环境变量未设置"
        exit 1
    fi
    
    log_success "环境变量检查通过"
}

# 配置SSH
setup_ssh() {
    log_info "配置SSH连接..."
    
    # 创建SSH目录
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    
    # 写入SSH私钥
    echo "$SSH_PRIVATE_KEY" > ~/.ssh/id_rsa
    chmod 600 ~/.ssh/id_rsa
    
    # 配置SSH客户端
    cat > ~/.ssh/config << EOF
Host deploy-server
    HostName $SERVER_IP
    User $SERVER_USER
    Port 22
    IdentityFile ~/.ssh/id_rsa
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
EOF
    
    chmod 600 ~/.ssh/config
    
    # 测试SSH连接
    ssh -o ConnectTimeout=10 deploy-server "echo 'SSH连接成功'"
    
    log_success "SSH配置完成"
}

# 构建前端
build_frontend() {
    log_info "构建前端应用..."
    
    cd frontend-taro
    
    # 安装依赖
    npm ci
    
    # 构建H5版本
    npm run build:h5
    
    # 构建微信小程序版本
    npm run build:weapp
    
    cd ..
    
    log_success "前端构建完成"
}

# 构建后端
build_backend() {
    log_info "构建后端应用..."
    
    cd backend
    
    # 下载依赖
    go mod download
    
    # 构建后端服务
    CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o basic-server ./cmd/basic-server/main.go
    
    cd ..
    
    log_success "后端构建完成"
}

# 创建部署包
create_deployment_package() {
    log_info "创建部署包..."
    
    local package_name="jobfirst-deploy-${COMMIT_SHA:0:8}.tar.gz"
    
    # 创建临时目录
    local temp_dir=$(mktemp -d)
    local deploy_dir="$temp_dir/jobfirst"
    
    # 复制文件
    mkdir -p "$deploy_dir"
    cp -r backend "$deploy_dir/"
    cp -r frontend-taro/dist "$deploy_dir/frontend/"
    cp -r scripts "$deploy_dir/"
    cp -r nginx "$deploy_dir/"
    cp docker-compose.yml "$deploy_dir/"
    
    # 创建部署信息文件
    cat > "$deploy_dir/DEPLOY_INFO" << EOF
部署时间: $(date)
Git提交: $COMMIT_SHA
分支: $BRANCH
构建者: $GITHUB_ACTOR
工作流: $GITHUB_WORKFLOW
运行ID: $GITHUB_RUN_ID
EOF
    
    # 创建压缩包
    cd "$temp_dir"
    tar -czf "$package_name" jobfirst/
    
    # 移动到当前目录
    mv "$package_name" "$OLDPWD/"
    cd "$OLDPWD"
    
    # 清理临时目录
    rm -rf "$temp_dir"
    
    log_success "部署包创建完成: $package_name"
    echo "$package_name"
}

# 上传部署包
upload_deployment_package() {
    local package_name="$1"
    
    log_info "上传部署包到服务器..."
    
    # 上传到服务器
    scp "$package_name" deploy-server:/tmp/
    
    # 解压到部署目录
    ssh deploy-server << EOF
        # 停止服务
        sudo systemctl stop jobfirst-backend || true
        sudo systemctl stop jobfirst-ai || true
        
        # 备份当前版本
        if [ -d "$DEPLOY_PATH" ]; then
            sudo mv "$DEPLOY_PATH" "${DEPLOY_PATH}-backup-$(date +%Y%m%d-%H%M%S)"
        fi
        
        # 解压新版本
        cd /tmp
        tar -xzf "$package_name"
        sudo mv jobfirst "$DEPLOY_PATH"
        sudo chown -R root:root "$DEPLOY_PATH"
        
        # 设置权限
        sudo chmod +x "$DEPLOY_PATH/scripts"/*.sh
        
        # 清理
        rm -f "$package_name"
        
        echo "部署包上传完成"
EOF
    
    log_success "部署包上传完成"
}

# 更新配置文件
update_configs() {
    log_info "更新配置文件..."
    
    ssh deploy-server << 'EOF'
        # 更新后端配置
        if [ -f "/opt/jobfirst/configs/config.prod.yaml" ]; then
            # 备份现有配置
            sudo cp /opt/jobfirst/configs/config.prod.yaml /opt/jobfirst/configs/config.prod.yaml.backup
        fi
        
        # 创建生产环境配置
        sudo tee /opt/jobfirst/configs/config.prod.yaml > /dev/null << 'CONFIG_EOF'
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

# 数据库配置
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

# Redis配置
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
  max_size: 10485760
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
CONFIG_EOF
        
        # 更新Nginx配置
        sudo tee /etc/nginx/sites-available/jobfirst > /dev/null << 'NGINX_EOF'
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
NGINX_EOF
        
        # 启用Nginx站点
        sudo ln -sf /etc/nginx/sites-available/jobfirst /etc/nginx/sites-enabled/
        sudo rm -f /etc/nginx/sites-enabled/default
        
        echo "配置文件更新完成"
EOF
    
    log_success "配置文件更新完成"
}

# 重启服务
restart_services() {
    log_info "重启服务..."
    
    ssh deploy-server << 'EOF'
        # 重启数据库服务
        sudo systemctl restart mysql
        sudo systemctl restart postgresql
        sudo systemctl restart redis
        
        # 重启应用服务
        sudo systemctl restart jobfirst-backend
        sudo systemctl restart jobfirst-ai
        
        # 重启Nginx
        sudo systemctl restart nginx
        
        # 检查服务状态
        echo "=== 服务状态 ==="
        sudo systemctl status jobfirst-backend --no-pager -l
        sudo systemctl status jobfirst-ai --no-pager -l
        sudo systemctl status nginx --no-pager -l
        
        echo "服务重启完成"
EOF
    
    log_success "服务重启完成"
}

# 验证部署
verify_deployment() {
    log_info "验证部署..."
    
    # 等待服务启动
    sleep 15
    
    # 检查服务状态
    ssh deploy-server << 'EOF'
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

# 发送通知
send_notification() {
    local status="$1"
    local message="$2"
    
    log_info "发送部署通知..."
    
    # 发送到Slack（如果配置了）
    if [ -n "$SLACK_WEBHOOK_URL" ]; then
        curl -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"JobFirst部署$status: $message\"}" \
            "$SLACK_WEBHOOK_URL"
    fi
    
    # 发送到钉钉（如果配置了）
    if [ -n "$DINGTALK_WEBHOOK_URL" ]; then
        curl -X POST -H 'Content-type: application/json' \
            --data "{\"msgtype\":\"text\",\"text\":{\"content\":\"JobFirst部署$status: $message\"}}" \
            "$DINGTALK_WEBHOOK_URL"
    fi
    
    log_success "通知发送完成"
}

# 主部署函数
main() {
    log_info "开始CI/CD自动化部署..."
    log_info "服务器: $SERVER_IP"
    log_info "分支: $BRANCH"
    log_info "提交: $COMMIT_SHA"
    
    # 检查环境
    check_environment
    
    # 配置SSH
    setup_ssh
    
    # 构建应用
    build_frontend
    build_backend
    
    # 创建部署包
    local package_name=$(create_deployment_package)
    
    # 上传部署包
    upload_deployment_package "$package_name"
    
    # 更新配置
    update_configs
    
    # 重启服务
    restart_services
    
    # 验证部署
    verify_deployment
    
    # 清理本地文件
    rm -f "$package_name"
    
    log_success "=== CI/CD部署完成 ==="
    log_info "系统访问地址:"
    log_info "  前端: http://$SERVER_IP"
    log_info "  API: http://$SERVER_IP/api/v1/"
    log_info "  健康检查: http://$SERVER_IP/health"
    
    # 发送成功通知
    send_notification "成功" "系统已成功部署到 $SERVER_IP"
}

# 错误处理
trap 'log_error "部署失败，退出码: $?"; send_notification "失败" "部署过程中出现错误"; exit 1' ERR

# 执行主函数
main "$@"
