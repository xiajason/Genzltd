#!/bin/bash

# 连接到阿里云服务器并启动Docker服务
set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
check_env_vars() {
    log_info "检查环境变量..."
    
    if [ -z "$ALIBABA_CLOUD_SERVER_IP" ]; then
        log_error "ALIBABA_CLOUD_SERVER_IP 环境变量未设置"
        exit 1
    fi
    
    if [ -z "$ALIBABA_CLOUD_SERVER_USER" ]; then
        log_error "ALIBABA_CLOUD_SERVER_USER 环境变量未设置"
        exit 1
    fi
    
    if [ -z "$ALIBABA_CLOUD_SSH_PRIVATE_KEY" ]; then
        log_error "ALIBABA_CLOUD_SSH_PRIVATE_KEY 环境变量未设置"
        exit 1
    fi
    
    log_success "环境变量检查通过"
    log_info "服务器IP: $ALIBABA_CLOUD_SERVER_IP"
    log_info "用户名: $ALIBABA_CLOUD_SERVER_USER"
}

# 查找SSH私钥
find_ssh_key() {
    log_info "查找SSH私钥..."
    
    # 可能的私钥文件
    local possible_keys=(
        "$HOME/.ssh/github_actions_key"
        "$HOME/.ssh/jobfirst_server_key"
        "$HOME/.ssh/id_rsa"
        "$HOME/.ssh/id_ed25519"
    )
    
    for key in "${possible_keys[@]}"; do
        if [ -f "$key" ]; then
            log_info "找到SSH私钥: $key"
            echo "$key"
            return 0
        fi
    done
    
    log_error "未找到SSH私钥文件"
    return 1
}

# 测试SSH连接
test_ssh_connection() {
    local ssh_key="$1"
    log_info "测试SSH连接..."
    
    if ssh -i "$ssh_key" -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$ALIBABA_CLOUD_SERVER_USER@$ALIBABA_CLOUD_SERVER_IP" "echo 'SSH连接成功'" 2>/dev/null; then
        log_success "SSH连接测试成功"
        return 0
    else
        log_warning "SSH连接测试失败，尝试其他密钥..."
        return 1
    fi
}

# 启动Docker服务
start_docker_service() {
    local ssh_key="$1"
    log_info "启动阿里云服务器上的Docker服务..."
    
    ssh -i "$ssh_key" -o StrictHostKeyChecking=no "$ALIBABA_CLOUD_SERVER_USER@$ALIBABA_CLOUD_SERVER_IP" << 'EOF'
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
EOF
    
    if [ $? -eq 0 ]; then
        log_success "Docker服务启动成功"
    else
        log_error "Docker服务启动失败"
        exit 1
    fi
}

# 检查Docker构建环境
check_docker_build_env() {
    local ssh_key="$1"
    log_info "检查Docker构建环境..."
    
    ssh -i "$ssh_key" -o StrictHostKeyChecking=no "$ALIBABA_CLOUD_SERVER_USER@$ALIBABA_CLOUD_SERVER_IP" << 'EOF'
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
        
        echo ""
        echo "5. 检查网络连接:"
        ping -c 3 registry-1.docker.io || echo "⚠️ 无法连接到Docker Hub"
EOF
    
    log_success "Docker构建环境检查完成"
}

# 主函数
main() {
    log_info "开始连接到阿里云服务器并启动Docker服务..."
    
    check_env_vars
    
    # 查找SSH私钥
    local ssh_key
    ssh_key=$(find_ssh_key)
    
    # 测试SSH连接
    if ! test_ssh_connection "$ssh_key"; then
        log_error "无法建立SSH连接，请检查服务器信息和密钥"
        exit 1
    fi
    
    # 启动Docker服务
    start_docker_service "$ssh_key"
    
    # 检查Docker构建环境
    check_docker_build_env "$ssh_key"
    
    log_success "🎉 阿里云服务器Docker服务已准备就绪！"
    
    echo ""
    echo "=== 下一步操作 ==="
    echo "1. 在阿里云服务器上运行Docker构建:"
    echo "   ssh -i $ssh_key $ALIBABA_CLOUD_SERVER_USER@$ALIBABA_CLOUD_SERVER_IP"
    echo "2. 或者使用GitHub Actions自动部署"
    echo "3. 检查部署状态:"
    echo "   ssh -i $ssh_key $ALIBABA_CLOUD_SERVER_USER@$ALIBABA_CLOUD_SERVER_IP 'docker ps'"
}

# 显示帮助信息
show_help() {
    echo "阿里云服务器Docker服务启动脚本"
    echo ""
    echo "用法: $0"
    echo ""
    echo "环境变量:"
    echo "  ALIBABA_CLOUD_SERVER_IP     阿里云服务器IP地址"
    echo "  ALIBABA_CLOUD_SERVER_USER   阿里云服务器用户名"
    echo "  ALIBABA_CLOUD_SSH_PRIVATE_KEY SSH私钥路径"
    echo ""
    echo "示例:"
    echo "  export ALIBABA_CLOUD_SERVER_IP='your-server-ip'"
    echo "  export ALIBABA_CLOUD_SERVER_USER='root'"
    echo "  export ALIBABA_CLOUD_SSH_PRIVATE_KEY='~/.ssh/github_actions_key'"
    echo "  $0"
}

# 处理命令行参数
case "${1:-}" in
    -h|--help)
        show_help
        exit 0
        ;;
    "")
        main
        ;;
    *)
        log_error "未知选项: $1"
        show_help
        exit 1
        ;;
esac
