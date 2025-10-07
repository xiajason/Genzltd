#!/bin/bash

# JobFirst 生产环境构建脚本
# 用于构建生产环境的所有组件

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

# 检查环境
check_environment() {
    log_info "检查构建环境..."
    
    # 检查Go版本
    if ! command -v go &> /dev/null; then
        log_error "Go is not installed"
        exit 1
    fi
    GO_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
    log_success "Go version: $GO_VERSION"
    
    # 检查Node.js版本
    if ! command -v node &> /dev/null; then
        log_error "Node.js is not installed"
        exit 1
    fi
    NODE_VERSION=$(node --version)
    log_success "Node.js version: $NODE_VERSION"
    
    # 检查Python版本
    if ! command -v python3 &> /dev/null; then
        log_error "Python3 is not installed"
        exit 1
    fi
    PYTHON_VERSION=$(python3 --version)
    log_success "Python version: $PYTHON_VERSION"
}

# 构建后端服务
build_backend() {
    log_info "构建后端服务..."
    
    cd "$PROJECT_ROOT/backend"
    
    # 清理旧的构建文件
    rm -f basic-server
    
    # 设置环境变量
    export CGO_ENABLED=0
    export GOOS=linux
    export GOARCH=amd64
    
    # 构建
    go build -a -installsuffix cgo -ldflags '-w -s' -o basic-server cmd/basic-server/main.go
    
    if [ -f "basic-server" ]; then
        log_success "后端服务构建成功"
        ls -lh basic-server
    else
        log_error "后端服务构建失败"
        exit 1
    fi
}

# 构建AI服务
build_ai_service() {
    log_info "构建AI服务..."
    
    cd "$PROJECT_ROOT/backend/internal/ai-service"
    
    # 检查requirements.txt
    if [ ! -f "requirements.txt" ]; then
        log_warning "requirements.txt not found, skipping AI service build"
        return
    fi
    
    # 创建虚拟环境
    if [ ! -d "venv" ]; then
        python3 -m venv venv
    fi
    
    # 激活虚拟环境并安装依赖
    source venv/bin/activate
    pip install --upgrade pip
    pip install -r requirements.txt
    
    log_success "AI服务依赖安装完成"
}

# 构建前端
build_frontend() {
    log_info "构建前端应用..."
    
    cd "$PROJECT_ROOT/frontend-taro"
    
    # 安装依赖
    if [ ! -d "node_modules" ]; then
        log_info "安装前端依赖..."
        npm install
    fi
    
    # 构建微信小程序
    log_info "构建微信小程序..."
    NODE_ENV=production npm run build:weapp
    
    # 构建H5
    log_info "构建H5版本..."
    NODE_ENV=production npm run build:h5
    
    # 检查构建结果
    if [ -d "dist" ]; then
        log_success "前端构建成功"
        du -sh dist/
    else
        log_error "前端构建失败"
        exit 1
    fi
}

# 创建部署包
create_deployment_package() {
    log_info "创建部署包..."
    
    cd "$PROJECT_ROOT"
    
    # 创建部署目录
    DEPLOY_DIR="deploy-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$DEPLOY_DIR"
    
    # 复制后端服务
    cp backend/basic-server "$DEPLOY_DIR/"
    cp backend/configs/config.yaml "$DEPLOY_DIR/"
    
    # 复制AI服务
    mkdir -p "$DEPLOY_DIR/ai-service"
    cp -r backend/internal/ai-service/* "$DEPLOY_DIR/ai-service/"
    
    # 复制前端构建结果
    mkdir -p "$DEPLOY_DIR/frontend"
    cp -r frontend-taro/dist "$DEPLOY_DIR/frontend/"
    
    # 复制数据库脚本
    mkdir -p "$DEPLOY_DIR/database"
    cp -r database/mysql/* "$DEPLOY_DIR/database/"
    
    # 复制部署脚本
    cp scripts/deploy.sh "$DEPLOY_DIR/"
    cp scripts/start-local.sh "$DEPLOY_DIR/"
    cp scripts/stop-local.sh "$DEPLOY_DIR/"
    
    # 复制配置文件
    cp DEPLOYMENT_GUIDE.md "$DEPLOY_DIR/"
    cp DEVELOPMENT_GUIDE.md "$DEPLOY_DIR/"
    
    # 创建部署信息文件
    cat > "$DEPLOY_DIR/deploy-info.txt" << EOF
JobFirst 生产环境部署包
构建时间: $(date)
构建版本: $(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
Go版本: $(go version 2>/dev/null || echo "unknown")
Node版本: $(node --version 2>/dev/null || echo "unknown")
Python版本: $(python3 --version 2>/dev/null || echo "unknown")

包含组件:
- 后端服务 (basic-server)
- AI服务 (ai-service)
- 前端应用 (微信小程序 + H5)
- 数据库脚本
- 部署脚本和文档

部署说明:
1. 解压部署包到目标服务器
2. 按照 DEPLOYMENT_GUIDE.md 进行部署
3. 运行 ./deploy.sh 进行一键部署
EOF
    
    # 创建压缩包
    tar -czf "${DEPLOY_DIR}.tar.gz" "$DEPLOY_DIR"
    
    log_success "部署包创建完成: ${DEPLOY_DIR}.tar.gz"
    ls -lh "${DEPLOY_DIR}.tar.gz"
    
    # 显示部署包内容
    log_info "部署包内容:"
    tar -tzf "${DEPLOY_DIR}.tar.gz" | head -20
    echo "..."
}

# 清理构建文件
cleanup() {
    log_info "清理构建文件..."
    
    cd "$PROJECT_ROOT"
    
    # 清理Go构建缓存
    go clean -cache
    
    # 清理Node.js缓存
    cd frontend-taro
    rm -rf node_modules/.cache
    
    log_success "清理完成"
}

# 主函数
main() {
    log_info "开始构建JobFirst生产环境..."
    
    check_environment
    build_backend
    build_ai_service
    build_frontend
    create_deployment_package
    cleanup
    
    log_success "生产环境构建完成！"
    log_info "部署包已创建，可以上传到生产服务器进行部署"
}

# 运行主函数
main "$@"
