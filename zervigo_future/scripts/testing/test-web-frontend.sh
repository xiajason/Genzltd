#!/bin/bash

# JobFirst Web前端测试脚本

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
WEB_FRONTEND_DIR="$PROJECT_ROOT/frontend/web"

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

# 检查依赖
check_dependencies() {
    log_info "Checking dependencies..."
    
    if ! command -v curl &> /dev/null; then
        log_error "curl is not installed"
        exit 1
    fi
    
    if ! command -v jq &> /dev/null; then
        log_warning "jq is not installed, some output may not be formatted"
    fi
    
    log_success "Dependencies check completed"
}

# 检查Web前端目录
check_web_frontend_dir() {
    log_info "Checking web frontend directory..."
    
    if [ ! -d "$WEB_FRONTEND_DIR" ]; then
        log_error "Web frontend directory not found: $WEB_FRONTEND_DIR"
        exit 1
    fi
    
    if [ ! -f "$WEB_FRONTEND_DIR/package.json" ]; then
        log_error "package.json not found in web frontend directory"
        exit 1
    fi
    
    log_success "Web frontend directory structure is valid"
}

# 检查Node.js和npm
check_node_environment() {
    log_info "Checking Node.js environment..."
    
    if ! command -v node &> /dev/null; then
        log_error "Node.js is not installed"
        exit 1
    fi
    
    if ! command -v npm &> /dev/null; then
        log_error "npm is not installed"
        exit 1
    fi
    
    NODE_VERSION=$(node --version)
    NPM_VERSION=$(npm --version)
    
    log_success "Node.js: $NODE_VERSION"
    log_success "npm: $NPM_VERSION"
}

# 检查依赖是否已安装
check_dependencies_installed() {
    log_info "Checking if dependencies are installed..."
    
    cd "$WEB_FRONTEND_DIR"
    
    if [ ! -d "node_modules" ]; then
        log_warning "Dependencies not installed. Installing now..."
        npm install
    else
        log_success "Dependencies are already installed"
    fi
}

# 检查Web前端服务器状态
check_web_server_status() {
    log_info "Checking web frontend server status..."
    
    if curl -s http://localhost:3000 > /dev/null 2>&1; then
        log_success "Web frontend server is running on port 3000"
        return 0
    else
        log_info "Web frontend server is not running on port 3000"
        return 1
    fi
}

# 启动Web前端服务器
start_web_server() {
    log_info "Starting web frontend server..."
    
    cd "$WEB_FRONTEND_DIR"
    
    # 检查是否已经有进程在运行
    if pgrep -f "next dev" > /dev/null; then
        log_warning "Web frontend server is already running"
        return 0
    fi
    
    # 启动开发服务器
    nohup npm run dev > "$PROJECT_ROOT/logs/web-frontend.log" 2>&1 &
    DEV_PID=$!
    
    # 保存PID到文件
    echo $DEV_PID > "$WEB_FRONTEND_DIR/dev.pid"
    
    log_info "Web frontend server started with PID: $DEV_PID"
    log_info "Logs: $PROJECT_ROOT/logs/web-frontend.log"
    
    # 等待服务器启动
    log_info "Waiting for server to be ready..."
    for i in {1..30}; do
        if curl -s http://localhost:3000 > /dev/null 2>&1; then
            break
        fi
        sleep 1
    done
    
    # 检查服务器状态
    if curl -s http://localhost:3000 > /dev/null 2>&1; then
        log_success "Web frontend server is ready"
        log_success "Web application available at: http://localhost:3000"
    else
        log_error "Web frontend server failed to start properly"
        exit 1
    fi
}

# 测试Web前端功能
test_web_frontend() {
    log_info "Testing web frontend functionality..."
    
    # 测试主页
    log_info "Testing homepage..."
    if response=$(curl -s http://localhost:3000 2>/dev/null); then
        if echo "$response" | grep -q "JobFirst"; then
            log_success "Homepage is working and contains JobFirst content"
        else
            log_warning "Homepage is working but content may be incomplete"
        fi
    else
        log_error "Failed to access homepage"
        return 1
    fi
    
    # 测试API代理
    log_info "Testing API proxy..."
    if response=$(curl -s http://localhost:3000/api/v1/info 2>/dev/null); then
        if echo "$response" | grep -q "JobFirst"; then
            log_success "API proxy is working correctly"
        else
            log_warning "API proxy is working but response may be unexpected"
        fi
    else
        log_warning "API proxy test failed (backend may not be running)"
    fi
    
    # 测试静态资源
    log_info "Testing static resources..."
    if curl -s -I http://localhost:3000/_next/static/ > /dev/null 2>&1; then
        log_success "Static resources are accessible"
    else
        log_warning "Static resources may not be properly configured"
    fi
    
    log_success "Web frontend functionality tests completed"
}

# 检查构建状态
check_build_status() {
    log_info "Checking build status..."
    
    cd "$WEB_FRONTEND_DIR"
    
    if [ -d ".next" ]; then
        log_success "Production build exists"
        
        # 检查构建文件
        if [ -d ".next/static" ]; then
            log_success "Static assets are built"
        fi
        
        if [ -d ".next/server" ]; then
            log_success "Server-side code is built"
        fi
    else
        log_info "No production build found"
        log_info "Run 'npm run build' to create production build"
    fi
}

# 运行构建测试
run_build_test() {
    log_info "Running build test..."
    
    cd "$WEB_FRONTEND_DIR"
    
    # 清理之前的构建
    if [ -d ".next" ]; then
        rm -rf .next
        log_info "Cleaned previous build"
    fi
    
    # 运行构建
    log_info "Building production version..."
    if npm run build; then
        log_success "Production build completed successfully"
        
        # 检查构建输出
        if [ -d ".next" ]; then
            log_success "Build output directory created"
            
            # 检查关键文件
            if [ -d ".next/static" ]; then
                log_success "Static assets generated"
            fi
            
            if [ -d ".next/server" ]; then
                log_success "Server-side code generated"
            fi
        fi
    else
        log_error "Production build failed"
        return 1
    fi
}

# 检查代码质量
check_code_quality() {
    log_info "Checking code quality..."
    
    cd "$WEB_FRONTEND_DIR"
    
    # 类型检查
    log_info "Running TypeScript type check..."
    if npm run type-check 2>/dev/null; then
        log_success "TypeScript type check passed"
    else
        log_warning "TypeScript type check failed or not configured"
    fi
    
    # 代码检查
    log_info "Running ESLint..."
    if npm run lint 2>/dev/null; then
        log_success "ESLint check passed"
    else
        log_warning "ESLint check failed or not configured"
    fi
}

# 显示Web前端信息
show_web_frontend_info() {
    log_info "Web Frontend Information:"
    echo "  - Directory: $WEB_FRONTEND_DIR"
    echo "  - Framework: Next.js 13+"
    echo "  - UI Library: React 18 + TypeScript"
    echo "  - Component Library: Ant Design 5.x"
    echo "  - Styling: Tailwind CSS"
    echo "  - Development URL: http://localhost:3000"
    
    # 显示package.json信息
    if [ -f "$WEB_FRONTEND_DIR/package.json" ]; then
        echo "  - Package Name: $(jq -r '.name' "$WEB_FRONTEND_DIR/package.json" 2>/dev/null || echo 'Unknown')"
        echo "  - Version: $(jq -r '.version' "$WEB_FRONTEND_DIR/package.json" 2>/dev/null || echo 'Unknown')"
    fi
}

# 运行所有测试
run_all_tests() {
    log_info "Starting web frontend tests..."
    
    check_dependencies
    check_web_frontend_dir
    check_node_environment
    check_dependencies_installed
    show_web_frontend_info
    
    log_info "Running functionality tests..."
    
    if check_web_server_status; then
        test_web_frontend
    else
        log_info "Starting web server for testing..."
        start_web_server
        sleep 3
        test_web_frontend
    fi
    
    log_info "Running build tests..."
    run_build_test
    
    log_info "Running code quality checks..."
    check_code_quality
    
    log_success "All web frontend tests completed!"
}

# 显示帮助信息
show_help() {
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  all         Run all tests (default)"
    echo "  start       Start web frontend server"
    echo "  test        Test web frontend functionality"
    echo "  build       Test production build"
    echo "  quality     Check code quality"
    echo "  info        Show web frontend information"
    echo "  help        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 all       # Run all tests"
    echo "  $0 start     # Start server"
    echo "  $0 test      # Test functionality"
    echo "  $0 build     # Test build"
}

# 主函数
main() {
    case "${1:-all}" in
        all)
            run_all_tests
            ;;
        start)
            check_dependencies
            check_web_frontend_dir
            check_node_environment
            check_dependencies_installed
            start_web_server
            ;;
        test)
            check_dependencies
            if check_web_server_status; then
                test_web_frontend
            else
                log_error "Web frontend server is not running"
                log_info "Use '$0 start' to start the server first"
                exit 1
            fi
            ;;
        build)
            check_dependencies
            check_web_frontend_dir
            check_node_environment
            check_dependencies_installed
            run_build_test
            ;;
        quality)
            check_dependencies
            check_web_frontend_dir
            check_node_environment
            check_code_quality
            ;;
        info)
            check_web_frontend_dir
            show_web_frontend_info
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "Unknown command: $1"
            show_help
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"
