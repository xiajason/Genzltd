#!/bin/bash

# 腾讯云版本控制实施方案执行脚本
# 基于 TENCENT_CLOUD_VERSION_CONTROL_IMPLEMENTATION_GUIDE.md

set -e

# 配置变量
SERVER_IP="101.33.251.158"
SSH_KEY="~/.ssh/basic.pem"
PROJECT_DIR="/opt/jobfirst"
GO_VERSION="1.25.0"

log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1"
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1"
}

# 检查SSH连接
check_ssh_connection() {
    log_info "检查SSH连接..."
    if ssh -i $SSH_KEY ubuntu@$SERVER_IP "echo 'SSH连接成功'"; then
        log_info "SSH连接正常"
    else
        log_error "SSH连接失败"
        exit 1
    fi
}

# 安装Go 1.25.0
install_go() {
    log_info "安装Go $GO_VERSION..."
    ssh -i $SSH_KEY ubuntu@$SERVER_IP << 'EOF'
        # 下载Go 1.25.0
        wget https://go.dev/dl/go1.25.0.linux-amd64.tar.gz
        
        # 移除旧版本
        sudo rm -rf /usr/local/go
        
        # 安装新版本
        sudo tar -C /usr/local -xzf go1.25.0.linux-amd64.tar.gz
        
        # 验证安装
        /usr/local/go/bin/go version
        
        # 设置环境变量
        echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
        source ~/.bashrc
        
        # 清理下载文件
        rm go1.25.0.linux-amd64.tar.gz
EOF
    log_info "Go $GO_VERSION 安装完成"
}

# 第一阶段：基础设置
phase1_basic_setup() {
    log_info "开始第一阶段：基础设置"
    
    # 1.1 配置Git仓库
    phase1_git_setup
    
    # 1.2 设置COS备份
    phase1_cos_backup
    
    # 1.3 配置DNS和SSL
    phase1_dns_ssl
    
    log_info "第一阶段完成"
}

# 1.1 配置Git仓库
phase1_git_setup() {
    log_info "配置Git仓库..."
    ssh -i $SSH_KEY ubuntu@$SERVER_IP << 'EOF'
        cd /opt/jobfirst
        
        # 初始化Git仓库
        git init
        
        # 设置Git配置
        git config user.name "Tencent Cloud Server"
        git config user.email "server@jobfirst.com"
        
        # 创建.gitignore文件
        cat > .gitignore << 'EOL'
# 日志文件
*.log
logs/

# 临时文件
tmp/
temp/

# 备份文件
backup/
*.backup

# 数据库文件
*.db
*.sqlite

# 配置文件（包含敏感信息）
config/secrets.yaml
config/database.yaml

# 进程文件
*.pid

# 上传文件
uploads/

# 版本备份
/opt/backup/versions/
EOL
        
        # 创建初始提交
        git add .
        git commit -m "Initial commit: JobFirst system deployment"
        
        echo "Git仓库配置完成"
EOF
    log_info "Git仓库配置完成"
}

# 1.2 设置COS备份
phase1_cos_backup() {
    log_info "设置COS备份..."
    ssh -i $SSH_KEY ubuntu@$SERVER_IP << 'EOF'
        # 下载COS命令行工具
        wget https://cosbrowser.cloud.tencent.com/software/coscli/coscli-linux
        
        # 重命名并设置权限
        mv coscli-linux coscli
        chmod +x coscli
        
        # 移动到系统路径
        sudo mv coscli /usr/local/bin/
        
        # 创建备份脚本目录
        mkdir -p /opt/jobfirst/scripts
        
        # 创建COS备份脚本
        cat > /opt/jobfirst/scripts/backup-to-cos.sh << 'EOL'
#!/bin/bash

# COS备份脚本
BUCKET_NAME="your-bucket-name"
BACKUP_DIR="/opt/backup/versions"
COS_PATH="jobfirst/backups/"

log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1"
}

log_info "开始备份到COS..."

# 备份版本文件
if [ -d "$BACKUP_DIR" ]; then
    log_info "备份版本文件到COS..."
    coscli sync "$BACKUP_DIR" "cos://$BUCKET_NAME/$COS_PATH" --delete
    
    if [ $? -eq 0 ]; then
        log_info "备份成功！"
    else
        log_info "备份失败！"
        exit 1
    fi
else
    log_info "备份目录不存在，跳过备份"
fi
EOL
        
        # 设置执行权限
        chmod +x /opt/jobfirst/scripts/backup-to-cos.sh
        
        echo "COS备份设置完成"
EOF
    log_info "COS备份设置完成"
}

# 1.3 配置DNS和SSL
phase1_dns_ssl() {
    log_info "配置DNS和SSL..."
    ssh -i $SSH_KEY ubuntu@$SERVER_IP << 'EOF'
        # 创建SSL证书目录
        mkdir -p /opt/jobfirst/ssl
        
        # 创建Nginx SSL配置
        cat > /etc/nginx/sites-available/jobfirst-ssl << 'EOL'
server {
    listen 80;
    server_name jobfirst.yourdomain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl;
    server_name jobfirst.yourdomain.com;

    ssl_certificate /opt/jobfirst/ssl/your-cert.crt;
    ssl_certificate_key /opt/jobfirst/ssl/your-key.key;

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOL
        
        # 启用站点
        ln -s /etc/nginx/sites-available/jobfirst-ssl /etc/nginx/sites-enabled/
        
        # 测试配置
        nginx -t
        
        echo "DNS和SSL配置完成"
EOF
    log_info "DNS和SSL配置完成"
}

# 主函数
main() {
    log_info "开始实施腾讯云版本控制方案..."
    
    check_ssh_connection
    install_go
    phase1_basic_setup
    
    log_info "版本控制方案实施完成！"
    log_info "请按照实施指南继续第二阶段和第三阶段的配置"
}

# 执行主函数
main "$@"
