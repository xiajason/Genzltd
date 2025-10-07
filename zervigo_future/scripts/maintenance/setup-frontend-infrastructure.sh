#!/bin/bash

# 阿里云前端基础设施设置脚本
# 用于在阿里云服务器上安装Node.js、npm等前端开发环境

set -e

# 配置
NODE_VERSION="18.20.8"
NPM_VERSION="10.8.2"
LOG_FILE="/opt/jobfirst/logs/frontend-infrastructure-setup.log"

# 日志函数
log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $1" | tee -a $LOG_FILE
}

log_success() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [SUCCESS] $1" | tee -a $LOG_FILE
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $1" | tee -a $LOG_FILE
}

log_warning() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WARNING] $1" | tee -a $LOG_FILE
}

# 创建日志目录
mkdir -p $(dirname $LOG_FILE)

log_info "开始设置阿里云前端基础设施..."

# 检查系统信息
check_system() {
    log_info "检查系统信息..."
    echo "操作系统: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
    echo "内核版本: $(uname -r)"
    echo "架构: $(uname -m)"
    log_success "系统信息检查完成"
}

# 更新系统包
update_system() {
    log_info "更新系统包..."
    if command -v yum &> /dev/null; then
        yum update -y
        yum install -y curl wget git
    elif command -v apt-get &> /dev/null; then
        apt-get update -y
        apt-get install -y curl wget git
    else
        log_error "不支持的包管理器"
        exit 1
    fi
    log_success "系统包更新完成"
}

# 安装Node.js
install_nodejs() {
    log_info "安装Node.js $NODE_VERSION..."
    
    # 检查是否已安装Node.js
    if command -v node &> /dev/null; then
        CURRENT_VERSION=$(node --version | cut -d'v' -f2)
        log_warning "Node.js已安装，当前版本: $CURRENT_VERSION"
        
        if [[ "$CURRENT_VERSION" == "$NODE_VERSION" ]]; then
            log_success "Node.js版本正确，跳过安装"
            return 0
        else
            log_info "Node.js版本不匹配，重新安装..."
        fi
    fi
    
    # 下载并安装Node.js
    cd /tmp
    wget "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.xz"
    tar -xf "node-v$NODE_VERSION-linux-x64.tar.xz"
    
    # 移动到系统目录
    sudo mv "node-v$NODE_VERSION-linux-x64" /opt/nodejs
    sudo ln -sf /opt/nodejs/bin/node /usr/local/bin/node
    sudo ln -sf /opt/nodejs/bin/npm /usr/local/bin/npm
    sudo ln -sf /opt/nodejs/bin/npx /usr/local/bin/npx
    
    # 验证安装
    if node --version | grep -q "v$NODE_VERSION"; then
        log_success "Node.js安装成功: $(node --version)"
    else
        log_error "Node.js安装失败"
        exit 1
    fi
    
    # 清理临时文件
    rm -f "node-v$NODE_VERSION-linux-x64.tar.xz"
}

# 配置npm
configure_npm() {
    log_info "配置npm..."
    
    # 设置npm镜像源
    npm config set registry https://registry.npmmirror.com
    npm config set disturl https://npmmirror.com/dist
    npm config set sass_binary_site https://npmmirror.com/mirrors/node-sass
    npm config set electron_mirror https://npmmirror.com/mirrors/electron/
    npm config set puppeteer_download_host https://npmmirror.com/mirrors
    npm config set chromedriver_cdnurl https://npmmirror.com/mirrors/chromedriver
    npm config set operadriver_cdnurl https://npmmirror.com/mirrors/operadriver
    npm config set phantomjs_cdnurl https://npmmirror.com/mirrors/phantomjs
    npm config set selenium_cdnurl https://npmmirror.com/mirrors/selenium
    npm config set node_inspector_cdnurl https://npmmirror.com/mirrors/node-inspector
    
    # 验证配置
    log_info "npm配置信息:"
    npm config list
    
    log_success "npm配置完成"
}

# 安装全局工具
install_global_tools() {
    log_info "安装全局工具..."
    
    # 安装常用全局包
    npm install -g npm@latest
    npm install -g yarn
    npm install -g pnpm
    npm install -g @tarojs/cli
    
    log_success "全局工具安装完成"
}

# 创建前端工作目录
create_frontend_directories() {
    log_info "创建前端工作目录..."
    
    # 创建前端相关目录
    mkdir -p /opt/jobfirst/frontend-taro
    mkdir -p /opt/jobfirst/logs
    mkdir -p /opt/jobfirst/backup/frontend
    mkdir -p /opt/jobfirst/nginx
    
    # 设置权限
    chown -R $(whoami):$(whoami) /opt/jobfirst
    
    log_success "前端工作目录创建完成"
}

# 验证安装
verify_installation() {
    log_info "验证安装..."
    
    echo "=== Node.js信息 ==="
    node --version
    npm --version
    
    echo "=== 全局工具信息 ==="
    yarn --version 2>/dev/null || echo "yarn未安装"
    pnpm --version 2>/dev/null || echo "pnpm未安装"
    taro --version 2>/dev/null || echo "taro未安装"
    
    echo "=== 环境变量 ==="
    echo "NODE_PATH: $NODE_PATH"
    echo "PATH: $PATH"
    
    log_success "安装验证完成"
}

# 主函数
main() {
    log_info "开始设置阿里云前端基础设施..."
    
    check_system
    update_system
    install_nodejs
    configure_npm
    install_global_tools
    create_frontend_directories
    verify_installation
    
    log_success "🎉 阿里云前端基础设施设置完成！"
    log_info "Node.js版本: $(node --version)"
    log_info "npm版本: $(npm --version)"
    log_info "前端工作目录: /opt/jobfirst/frontend-taro"
}

# 错误处理
trap 'log_error "设置过程中发生错误，退出码: $?"' ERR

# 执行主函数
main "$@"
