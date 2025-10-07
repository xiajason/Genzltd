#!/bin/bash

# JobFirst Taro 前端开发启动脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 获取脚本所在目录的绝对路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

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

# 检查Node.js
check_node() {
    if ! command -v node &> /dev/null; then
        log_error "Node.js is not installed. Please install Node.js first."
        log_info "Install command: brew install node"
        exit 1
    fi
    log_success "Node.js is installed: $(node --version)"
}

# 检查npm
check_npm() {
    if ! command -v npm &> /dev/null; then
        log_error "npm is not installed. Please install npm first."
        exit 1
    fi
    log_success "npm is installed: $(npm --version)"
}

# 安装Taro前端依赖
install_taro_deps() {
    log_info "Installing Taro frontend dependencies..."
    
    cd "$PROJECT_ROOT/frontend-taro"
    
    if [ -f "package.json" ]; then
        npm install
        log_success "Taro frontend dependencies installed"
    else
        log_error "package.json not found in frontend-taro directory"
        exit 1
    fi
    
    cd "$PROJECT_ROOT"
}

# 启动Taro H5开发服务器
start_taro_h5() {
    log_info "Starting Taro H5 development server..."
    
    cd "$PROJECT_ROOT/frontend-taro"
    
    log_info "Taro H5 will be available at: http://localhost:10086"
    log_info "Press Ctrl+C to stop the development server"
    
    npm run dev:h5
}

# 启动Taro微信小程序开发
start_taro_weapp() {
    log_info "Starting Taro WeChat Mini Program development..."
    
    cd "$PROJECT_ROOT/frontend-taro"
    
    log_info "Building WeChat Mini Program..."
    log_info "Please open WeChat Developer Tools and import the dist/weapp directory"
    
    npm run dev:weapp
}

# 显示帮助信息
show_help() {
    echo "JobFirst Taro 前端开发启动脚本"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  h5     启动 H5 开发服务器 (默认)"
    echo "  weapp  启动微信小程序开发"
    echo "  help   显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0        # 启动 H5 开发服务器"
    echo "  $0 h5     # 启动 H5 开发服务器"
    echo "  $0 weapp  # 启动微信小程序开发"
}

# 主函数
main() {
    local mode=${1:-h5}
    
    log_info "Starting JobFirst Taro Frontend Development..."
    log_info "Project root: $PROJECT_ROOT"
    
    # 检查依赖
    check_node
    check_npm
    
    # 安装依赖
    install_taro_deps
    
    # 根据模式启动服务
    case $mode in
        h5)
            start_taro_h5
            ;;
        weapp)
            start_taro_weapp
            ;;
        help)
            show_help
            ;;
        *)
            log_error "Unknown mode: $mode"
            show_help
            exit 1
            ;;
    esac
}

# 脚本入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

