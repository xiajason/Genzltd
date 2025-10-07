#!/bin/bash

# 腾讯云前端开发环境设置脚本
# 基于现有的构建流程建立开发环境

set -e

# 配置
DEPLOY_DIR="/opt/jobfirst"
FRONTEND_DEV_DIR="$DEPLOY_DIR/frontend-dev"
FRONTEND_SOURCE_DIR="/Users/szjason72/zervi-basic/basic/frontend-taro"
NGINX_CONFIG="/etc/nginx/sites-enabled/default"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日志函数
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# 错误处理
error_exit() {
    echo -e "${RED}错误: $1${NC}" >&2
    exit 1
}

# 成功信息
success() {
    echo -e "${GREEN}成功: $1${NC}"
}

# 信息输出
info() {
    echo -e "${BLUE}信息: $1${NC}"
}

# 创建前端开发环境
create_frontend_dev_env() {
    log "创建前端开发环境"
    
    # 创建开发环境目录
    mkdir -p "$FRONTEND_DEV_DIR"
    
    # 从本地同步源代码
    info "同步前端源代码到开发环境"
    rsync -av --exclude 'node_modules' --exclude 'dist' --exclude '.git' \
        "$FRONTEND_SOURCE_DIR/" "$FRONTEND_DEV_DIR/"
    
    success "前端开发环境创建完成"
}

# 安装开发依赖
install_dev_dependencies() {
    log "安装开发依赖"
    
    cd "$FRONTEND_DEV_DIR"
    
    # 检查Node.js版本
    if ! command -v node &> /dev/null; then
        error_exit "Node.js未安装，请先安装Node.js"
    fi
    
    # 安装依赖
    npm install
    
    success "开发依赖安装完成"
}

# 配置开发环境
configure_dev_env() {
    log "配置开发环境"
    
    cd "$FRONTEND_DEV_DIR"
    
    # 创建开发环境配置
    cat > .env.development << EOF
# 开发环境配置
NODE_ENV=development
TARO_ENV=h5
API_BASE_URL=http://101.33.251.158:8080
ENABLE_MOCK_DATA=true
ENABLE_DEBUG_LOGS=true
ENABLE_TEST_PAGES=true
EOF
    
    # 创建生产环境配置
    cat > .env.production << EOF
# 生产环境配置
NODE_ENV=production
TARO_ENV=h5
API_BASE_URL=http://101.33.251.158
ENABLE_MOCK_DATA=false
ENABLE_DEBUG_LOGS=false
ENABLE_TEST_PAGES=false
EOF
    
    success "开发环境配置完成"
}

# 配置Nginx开发环境
configure_nginx_dev() {
    log "配置Nginx开发环境"
    
    # 备份原配置
    sudo cp "$NGINX_CONFIG" "$NGINX_CONFIG.backup"
    
    # 添加开发环境配置
    sudo tee -a "$NGINX_CONFIG" << EOF

# 前端开发环境
server {
    listen 8080;
    server_name 101.33.251.158;
    root $FRONTEND_DEV_DIR/dist;
    index index.html;
    
    # 开发环境配置
    location / {
        try_files \$uri \$uri/ /index.html;
    }
    
    # API代理
    location /api/ {
        proxy_pass http://localhost:8080/api/v1/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
    
    # 热重载支持
    location /sockjs-node {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
EOF
    
    # 重新加载Nginx
    sudo nginx -t && sudo systemctl reload nginx
    
    success "Nginx开发环境配置完成"
}

# 启动开发服务器
start_dev_server() {
    log "启动开发服务器"
    
    cd "$FRONTEND_DEV_DIR"
    
    # 启动开发服务器
    nohup npm run dev:h5 > dev-server.log 2>&1 &
    
    success "开发服务器启动完成"
    info "开发环境访问地址: http://101.33.251.158:8080"
}

# 构建生产版本
build_production() {
    log "构建生产版本"
    
    cd "$FRONTEND_DEV_DIR"
    
    # 运行生产构建
    npm run build:h5:prod
    
    # 验证构建
    npm run verify:production
    
    # 部署到生产目录
    sudo cp -r dist/* /var/www/html/
    
    success "生产版本构建和部署完成"
}

# 显示开发环境状态
show_dev_status() {
    log "显示开发环境状态"
    
    echo "前端开发环境状态:"
    echo "=================="
    echo "开发环境目录: $FRONTEND_DEV_DIR"
    echo "生产环境目录: /var/www/html"
    echo "开发服务器: $(pgrep -f 'npm run dev:h5' > /dev/null && echo '运行中' || echo '未运行')"
    echo "Nginx状态: $(systemctl is-active nginx)"
    echo ""
    echo "访问地址:"
    echo "开发环境: http://101.33.251.158:8080"
    echo "生产环境: http://101.33.251.158"
}

# 主函数
main() {
    case "$1" in
        "setup")
            create_frontend_dev_env
            install_dev_dependencies
            configure_dev_env
            configure_nginx_dev
            ;;
        "start")
            start_dev_server
            ;;
        "build")
            build_production
            ;;
        "status")
            show_dev_status
            ;;
        "stop")
            pkill -f "npm run dev:h5" || true
            success "开发服务器已停止"
            ;;
        *)
            echo "用法: $0 {setup|start|build|status|stop}"
            echo ""
            echo "命令说明:"
            echo "  setup   - 设置前端开发环境"
            echo "  start   - 启动开发服务器"
            echo "  build   - 构建生产版本"
            echo "  status  - 显示开发环境状态"
            echo "  stop    - 停止开发服务器"
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"
