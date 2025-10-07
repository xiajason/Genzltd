#!/bin/bash

# 设置阿里云环境变量脚本
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

# 检查SSH密钥
check_ssh_keys() {
    log_info "检查可用的SSH密钥..."
    
    local keys=()
    local key_paths=(
        "$HOME/.ssh/github_actions_key"
        "$HOME/.ssh/jobfirst_server_key"
        "$HOME/.ssh/id_rsa"
        "$HOME/.ssh/id_ed25519"
    )
    
    for key in "${key_paths[@]}"; do
        if [ -f "$key" ]; then
            keys+=("$key")
            log_info "找到SSH密钥: $key"
        fi
    done
    
    if [ ${#keys[@]} -eq 0 ]; then
        log_error "未找到任何SSH密钥"
        exit 1
    fi
    
    echo "${keys[@]}"
}

# 交互式设置环境变量
setup_env_vars() {
    log_info "设置阿里云环境变量..."
    
    # 检查SSH密钥
    local available_keys
    available_keys=($(check_ssh_keys))
    
    echo ""
    echo "=== 阿里云服务器配置 ==="
    echo ""
    
    # 获取服务器IP
    read -p "请输入阿里云服务器IP地址: " server_ip
    if [ -z "$server_ip" ]; then
        log_error "服务器IP地址不能为空"
        exit 1
    fi
    
    # 获取用户名
    read -p "请输入阿里云服务器用户名 (默认: root): " server_user
    server_user=${server_user:-root}
    
    # 选择SSH密钥
    echo ""
    echo "可用的SSH密钥:"
    for i in "${!available_keys[@]}"; do
        echo "$((i+1)). ${available_keys[$i]}"
    done
    
    read -p "请选择SSH密钥 (输入数字): " key_choice
    if ! [[ "$key_choice" =~ ^[0-9]+$ ]] || [ "$key_choice" -lt 1 ] || [ "$key_choice" -gt ${#available_keys[@]} ]; then
        log_error "无效的选择"
        exit 1
    fi
    
    local selected_key="${available_keys[$((key_choice-1))]}"
    
    # 设置环境变量
    export ALIBABA_CLOUD_SERVER_IP="$server_ip"
    export ALIBABA_CLOUD_SERVER_USER="$server_user"
    export ALIBABA_CLOUD_SSH_PRIVATE_KEY="$selected_key"
    
    log_success "环境变量设置完成"
    echo ""
    echo "=== 环境变量信息 ==="
    echo "ALIBABA_CLOUD_SERVER_IP: $ALIBABA_CLOUD_SERVER_IP"
    echo "ALIBABA_CLOUD_SERVER_USER: $ALIBABA_CLOUD_SERVER_USER"
    echo "ALIBABA_CLOUD_SSH_PRIVATE_KEY: $ALIBABA_CLOUD_SSH_PRIVATE_KEY"
    echo ""
}

# 测试连接
test_connection() {
    log_info "测试SSH连接..."
    
    if ssh -i "$ALIBABA_CLOUD_SSH_PRIVATE_KEY" -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$ALIBABA_CLOUD_SERVER_USER@$ALIBABA_CLOUD_SERVER_IP" "echo 'SSH连接成功'" 2>/dev/null; then
        log_success "SSH连接测试成功"
        return 0
    else
        log_error "SSH连接测试失败"
        return 1
    fi
}

# 启动Docker服务
start_docker() {
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
EOF
    
    if [ $? -eq 0 ]; then
        log_success "Docker服务启动成功"
    else
        log_error "Docker服务启动失败"
        exit 1
    fi
}

# 主函数
main() {
    log_info "开始设置阿里云环境并启动Docker服务..."
    
    setup_env_vars
    
    if test_connection; then
        start_docker
        log_success "🎉 阿里云服务器Docker服务已准备就绪！"
        
        echo ""
        echo "=== 下一步操作 ==="
        echo "1. 现在可以运行Docker构建命令"
        echo "2. 或者使用GitHub Actions自动部署"
        echo "3. 检查部署状态:"
        echo "   ssh -i $ALIBABA_CLOUD_SSH_PRIVATE_KEY $ALIBABA_CLOUD_SERVER_USER@$ALIBABA_CLOUD_SERVER_IP 'docker ps'"
    else
        log_error "无法连接到阿里云服务器，请检查配置"
        exit 1
    fi
}

# 显示帮助信息
show_help() {
    echo "阿里云环境设置脚本"
    echo ""
    echo "用法: $0"
    echo ""
    echo "此脚本将帮助您:"
    echo "1. 设置阿里云服务器环境变量"
    echo "2. 测试SSH连接"
    echo "3. 启动阿里云服务器上的Docker服务"
    echo ""
    echo "需要准备的信息:"
    echo "- 阿里云服务器IP地址"
    echo "- 阿里云服务器用户名"
    echo "- SSH私钥文件"
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
