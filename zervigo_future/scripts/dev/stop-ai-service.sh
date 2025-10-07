#!/bin/bash

# AI服务停止脚本

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

# 停止AI服务
stop_ai_service() {
    log_info "停止AI服务 (容器化部署)..."
    
    # 进入AI服务目录
    if [ -d "ai-services" ]; then
        cd ai-services
        
        # 检查Docker是否运行
        if docker info > /dev/null 2>&1; then
            # 检查容器是否运行
            if docker-compose ps ai-service | grep -q "Up"; then
                log_info "停止AI服务容器..."
                docker-compose stop ai-service
                log_success "AI服务容器已停止"
            else
                log_info "AI服务容器未运行"
            fi
            
            # 可选：清理容器
            log_info "清理AI服务容器..."
            docker-compose down ai-service
            log_success "AI服务容器已清理"
        else
            log_warning "Docker 未运行，跳过容器操作"
        fi
        
        cd ..
    else
        log_warning "未找到 ai-services 目录"
    fi
    
    # 检查端口占用
    if lsof -i :8620 > /dev/null 2>&1; then
        log_info "发现端口8620被占用，强制释放..."
        lsof -ti :8620 | xargs kill -9 2>/dev/null || true
        log_success "端口8620已释放"
    else
        log_info "端口8620未被占用"
    fi
}

# 主函数
main() {
    log_info "=== AI服务停止脚本 ==="
    
    # 停止AI服务
    stop_ai_service
    
    log_success "AI服务已停止"
}

# 执行主函数
main "$@"
