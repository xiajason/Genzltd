#!/bin/bash

# JobFirst Basic Version 停止服务脚本

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

# 停止后端服务
stop_backend() {
    log_info "Stopping backend services..."
    
    # 停止basic-server主服务
    if [ -f "$PROJECT_ROOT/backend/logs/basic-server.pid" ]; then
        local pid=$(cat "$PROJECT_ROOT/backend/logs/basic-server.pid")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid"
            log_info "Stopped basic-server service (PID: $pid)"
        fi
        rm -f "$PROJECT_ROOT/backend/logs/basic-server.pid"
    fi
    
    # 停止user微服务
    if [ -f "$PROJECT_ROOT/backend/logs/user-service.pid" ]; then
        local pid=$(cat "$PROJECT_ROOT/backend/logs/user-service.pid")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid"
            log_info "Stopped user microservice (PID: $pid)"
        fi
        rm -f "$PROJECT_ROOT/backend/logs/user-service.pid"
    fi
    
    # 停止resume微服务
    if [ -f "$PROJECT_ROOT/backend/logs/resume-service.pid" ]; then
        local pid=$(cat "$PROJECT_ROOT/backend/logs/resume-service.pid")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid"
            log_info "Stopped resume microservice (PID: $pid)"
        fi
        rm -f "$PROJECT_ROOT/backend/logs/resume-service.pid"
    fi
    
    log_success "All backend services stopped"
}

# 停止前端服务
stop_frontend() {
    # 停止Web前端
    if [ -f "../logs/web-frontend.pid" ]; then
        local pid=$(cat ../logs/web-frontend.pid)
        if kill -0 $pid 2>/dev/null; then
            log_info "Stopping web frontend (PID: $pid)..."
            kill $pid
            log_success "Web frontend stopped"
        fi
        rm -f ../logs/web-frontend.pid
    fi
    
    # 停止小程序
    if [ -f "../logs/miniprogram.pid" ]; then
        local pid=$(cat ../logs/miniprogram.pid)
        if kill -0 $pid 2>/dev/null; then
            log_info "Stopping mini program (PID: $pid)..."
            kill $pid
            log_success "Mini program stopped"
        fi
        rm -f ../logs/miniprogram.pid
    fi
}

# 停止数据库服务
stop_database() {
    log_info "Stopping database services..."
    
    # 停止Redis
    if brew services list | grep redis | grep started &> /dev/null; then
        log_info "Stopping Redis service..."
        brew services stop redis
        log_success "Redis service stopped"
    fi
    
    # 停止MySQL
    if brew services list | grep mysql | grep started &> /dev/null; then
        log_info "Stopping MySQL service..."
        brew services stop mysql
        log_success "MySQL service stopped"
    fi
}

# 清理临时文件
cleanup() {
    log_info "Cleaning up temporary files..."
    
    # 清理日志文件
    rm -f ../backend/logs/*.pid
    rm -f ../logs/*.pid
    
    # 清理临时目录
    rm -rf ../backend/temp/*
    
    log_success "Cleanup completed"
}

# 显示服务状态
show_status() {
    log_info "Current service status:"
    
    echo ""
    log_info "Process status:"
    
    # 检查后端
    if [ -f "../backend/logs/basic-server.pid" ]; then
        local pid=$(cat ../backend/logs/basic-server.pid)
        if kill -0 $pid 2>/dev/null; then
            echo -e "  ${GREEN}Backend:${NC} Running (PID: $pid)"
        else
            echo -e "  ${RED}Backend:${NC} Not running (stale PID file)"
        fi
    else
        echo -e "  ${YELLOW}Backend:${NC} Not running"
    fi
    
    # 检查前端
    if [ -f "../logs/web-frontend.pid" ]; then
        local pid=$(cat ../logs/web-frontend.pid)
        if kill -0 $pid 2>/dev/null; then
            echo -e "  ${GREEN}Web Frontend:${NC} Running (PID: $pid)"
        else
            echo -e "  ${RED}Web Frontend:${NC} Not running (stale PID file)"
        fi
    else
        echo -e "  ${YELLOW}Web Frontend:${NC} Not running"
    fi
    
    if [ -f "../logs/miniprogram.pid" ]; then
        local pid=$(cat ../logs/miniprogram.pid)
        if kill -0 $pid 2>/dev/null; then
            echo -e "  ${GREEN}Mini Program:${NC} Running (PID: $pid)"
        else
            echo -e "  ${RED}Mini Program:${NC} Not running (stale PID file)"
        fi
    else
        echo -e "  ${YELLOW}Mini Program:${NC} Not running"
    fi
    
    echo ""
    log_info "Database services:"
    
    # 检查MySQL
    if brew services list | grep mysql | grep started &> /dev/null; then
        echo -e "  ${GREEN}MySQL:${NC} Running"
    else
        echo -e "  ${YELLOW}MySQL:${NC} Stopped"
    fi
    
    # 检查Redis
    if brew services list | grep redis | grep started &> /dev/null; then
        echo -e "  ${GREEN}Redis:${NC} Running"
    else
        echo -e "  ${YELLOW}Redis:${NC} Stopped"
    fi
    
    echo ""
    log_info "Port usage:"
    
    # 检查端口占用
    local ports=("8080" "3000" "3001")
    for port in "${ports[@]}"; do
        if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
            local process=$(lsof -Pi :$port -sTCP:LISTEN | tail -n +2 | awk '{print $1}')
            echo -e "  ${RED}Port $port:${NC} In use by $process"
        else
            echo -e "  ${GREEN}Port $port:${NC} Available"
        fi
    done
}

# 主函数
main() {
    log_info "Stopping JobFirst Basic Version services..."
    
    # 停止应用服务
    stop_backend
    stop_frontend
    
    # 清理临时文件
    cleanup
    
    # 显示状态
    show_status
    
    log_success "All services stopped successfully!"
    
    # 询问是否停止数据库服务
    echo ""
    read -p "Do you want to stop database services (MySQL/Redis)? [y/N]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        stop_database
        log_success "Database services stopped"
    else
        log_info "Database services kept running"
    fi
    
    log_success "JobFirst Basic Version services stopped!"
}

# 脚本入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
