#!/bin/bash

# 快速启动阿里云Docker服务脚本
set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 设置默认环境变量（请根据您的实际情况修改）
export ALIBABA_CLOUD_SERVER_IP="${ALIBABA_CLOUD_SERVER_IP:-your-server-ip}"
export ALIBABA_CLOUD_SERVER_USER="${ALIBABA_CLOUD_SERVER_USER:-root}"
export ALIBABA_CLOUD_SSH_PRIVATE_KEY="${ALIBABA_CLOUD_SSH_PRIVATE_KEY:-$HOME/.ssh/github_actions_key}"

log_info "当前配置:"
echo "服务器IP: $ALIBABA_CLOUD_SERVER_IP"
echo "用户名: $ALIBABA_CLOUD_SERVER_USER"
echo "SSH密钥: $ALIBABA_CLOUD_SSH_PRIVATE_KEY"
echo ""

# 检查SSH密钥是否存在
if [ ! -f "$ALIBABA_CLOUD_SSH_PRIVATE_KEY" ]; then
    log_error "SSH密钥文件不存在: $ALIBABA_CLOUD_SSH_PRIVATE_KEY"
    log_info "请设置正确的SSH密钥路径"
    exit 1
fi

# 测试SSH连接
log_info "测试SSH连接..."
if ssh -i "$ALIBABA_CLOUD_SSH_PRIVATE_KEY" -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$ALIBABA_CLOUD_SERVER_USER@$ALIBABA_CLOUD_SERVER_IP" "echo 'SSH连接成功'" 2>/dev/null; then
    log_success "SSH连接测试成功"
else
    log_error "SSH连接测试失败"
    log_info "请检查:"
    echo "1. 服务器IP地址是否正确"
    echo "2. 用户名是否正确"
    echo "3. SSH密钥是否正确"
    echo "4. 服务器是否允许SSH连接"
    exit 1
fi

# 启动Docker服务
log_info "启动阿里云服务器上的Docker服务..."
ssh -i "$ALIBABA_CLOUD_SSH_PRIVATE_KEY" -o StrictHostKeyChecking=no "$ALIBABA_CLOUD_SERVER_USER@$ALIBABA_CLOUD_SERVER_IP" << 'EOF'
    echo "=== 检查Docker状态 ==="
    if systemctl is-active --quiet docker; then
        echo "✅ Docker服务已运行"
    else
        echo "🔄 启动Docker服务..."
        sudo systemctl start docker
        sudo systemctl enable docker
        echo "✅ Docker服务已启动"
    fi
    
    echo ""
    echo "=== Docker版本信息 ==="
    docker --version
    docker-compose --version
    
    echo ""
    echo "=== Docker服务状态 ==="
    systemctl status docker --no-pager -l
    
    echo ""
    echo "=== 检查Docker守护进程 ==="
    if docker info >/dev/null 2>&1; then
        echo "✅ Docker守护进程运行正常"
    else
        echo "❌ Docker守护进程异常"
        exit 1
    fi
    
    echo ""
    echo "=== Docker构建环境检查 ==="
    echo "1. 检查Docker构建x功能:"
    if docker buildx version >/dev/null 2>&1; then
        echo "✅ Docker Buildx 可用"
    else
        echo "⚠️ Docker Buildx 不可用，将使用标准构建"
    fi
    
    echo ""
    echo "2. 检查磁盘空间:"
    df -h /
    
    echo ""
    echo "3. 检查内存使用:"
    free -h
    
    echo ""
    echo "4. 检查Docker系统信息:"
    docker system df
EOF

if [ $? -eq 0 ]; then
    log_success "🎉 阿里云服务器Docker服务已准备就绪！"
    
    echo ""
    echo "=== 下一步操作 ==="
    echo "1. 现在可以运行Docker构建命令:"
    echo "   ssh -i $ALIBABA_CLOUD_SSH_PRIVATE_KEY $ALIBABA_CLOUD_SERVER_USER@$ALIBABA_CLOUD_SERVER_IP 'cd /opt/jobfirst && docker-compose build'"
    echo ""
    echo "2. 或者使用GitHub Actions自动部署"
    echo ""
    echo "3. 检查部署状态:"
    echo "   ssh -i $ALIBABA_CLOUD_SSH_PRIVATE_KEY $ALIBABA_CLOUD_SERVER_USER@$ALIBABA_CLOUD_SERVER_IP 'docker ps'"
else
    log_error "Docker服务启动失败"
    exit 1
fi
