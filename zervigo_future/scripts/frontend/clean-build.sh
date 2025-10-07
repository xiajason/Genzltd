#!/bin/bash

# Taro前端构建清理脚本
# 用于清理构建缓存和解决ChunkLoadError问题

set -e

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
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

log_info "开始清理Taro前端构建缓存..."

# 清理dist目录
if [ -d "dist" ]; then
    log_info "清理dist目录..."
    rm -rf dist
    log_success "dist目录已清理"
else
    log_info "dist目录不存在，跳过清理"
fi

# 清理node_modules/.cache目录
if [ -d "node_modules/.cache" ]; then
    log_info "清理node_modules/.cache目录..."
    rm -rf node_modules/.cache
    log_success "node_modules/.cache已清理"
else
    log_info "node_modules/.cache目录不存在，跳过清理"
fi

# 清理.temp目录
if [ -d ".temp" ]; then
    log_info "清理.temp目录..."
    rm -rf .temp
    log_success ".temp目录已清理"
else
    log_info ".temp目录不存在，跳过清理"
fi

# 清理webpack缓存
if [ -d ".webpack" ]; then
    log_info "清理.webpack目录..."
    rm -rf .webpack
    log_success ".webpack目录已清理"
else
    log_info ".webpack目录不存在，跳过清理"
fi

# 清理npm缓存
log_info "清理npm缓存..."
npm cache clean --force
log_success "npm缓存已清理"

# 重新安装依赖
log_info "重新安装依赖..."
npm install
log_success "依赖安装完成"

log_success "构建缓存清理完成！"
log_info "现在可以重新构建项目："
log_info "  npm run build:h5"
log_info "  npm run dev:h5"
