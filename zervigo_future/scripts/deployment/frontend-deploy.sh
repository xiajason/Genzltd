#!/bin/bash

# JobFirst 前端独立部署脚本
# 用于快速部署前端更新，不影响后端微服务

set -e

# 配置
FRONTEND_PATH="/opt/jobfirst/frontend-taro"
NGINX_PATH="/opt/jobfirst/nginx"
BACKUP_PATH="/opt/jobfirst/backup/frontend"
LOG_FILE="/opt/jobfirst/logs/frontend-deploy.log"

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

# 创建必要目录
create_directories() {
    log_info "创建必要目录..."
    mkdir -p $FRONTEND_PATH $NGINX_PATH $BACKUP_PATH
    mkdir -p $(dirname $LOG_FILE)
    log_success "目录创建完成"
}

# 检查Docker环境
check_docker() {
    log_info "检查Docker环境..."
    if ! command -v docker &> /dev/null; then
        log_error "Docker未安装"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        log_error "Docker服务未运行"
        exit 1
    fi
    
    log_success "Docker环境检查通过"
}

# 备份现有前端文件
backup_frontend() {
    log_info "备份现有前端文件..."
    
    if [ -d "$FRONTEND_PATH/dist" ]; then
        BACKUP_NAME="frontend_$(date +%Y%m%d_%H%M%S)"
        cp -r $FRONTEND_PATH/dist $BACKUP_PATH/$BACKUP_NAME
        log_success "前端文件已备份: $BACKUP_NAME"
    else
        log_warning "未找到现有前端文件，跳过备份"
    fi
}

# 部署新前端文件
deploy_frontend() {
    log_info "部署新前端文件..."
    
    # 检查部署包是否存在
    if [ ! -f "/tmp/frontend-deployment.tar.gz" ]; then
        log_error "未找到前端部署包: /tmp/frontend-deployment.tar.gz"
        exit 1
    fi
    
    # 解压部署包
    cd /tmp
    tar -xzf frontend-deployment.tar.gz
    
    # 检查解压结果
    if [ ! -d "frontend-h5-build" ]; then
        log_error "前端构建文件解压失败"
        exit 1
    fi
    
    # 部署新文件
    rm -rf $FRONTEND_PATH/dist
    cp -r frontend-h5-build $FRONTEND_PATH/dist
    
    # 更新Nginx配置（如果存在）
    if [ -f "nginx/frontend.conf" ]; then
        cp nginx/frontend.conf $NGINX_PATH/frontend.conf
        log_success "Nginx配置已更新"
    fi
    
    log_success "前端文件部署完成"
}

# 重启前端服务
restart_frontend_service() {
    log_info "重启前端服务..."
    
    cd /opt/jobfirst
    
    if [ -f "docker-compose.yml" ]; then
        # 检查前端容器是否存在
        if docker-compose ps frontend | grep -q "Up"; then
            log_info "重启现有前端容器..."
            docker-compose restart frontend
        else
            log_info "启动前端容器..."
            docker-compose up -d frontend
        fi
        
        # 等待服务启动
        sleep 5
        
        # 检查服务状态
        if docker-compose ps frontend | grep -q "Up"; then
            log_success "前端服务启动成功"
        else
            log_error "前端服务启动失败"
            docker-compose logs frontend
            exit 1
        fi
    else
        log_error "未找到docker-compose.yml文件"
        exit 1
    fi
}

# 验证部署
verify_deployment() {
    log_info "验证前端部署..."
    
    # 检查容器状态
    if docker-compose ps frontend | grep -q "Up"; then
        log_success "前端容器运行正常"
    else
        log_error "前端容器未运行"
        return 1
    fi
    
    # 检查文件是否存在
    if [ -d "$FRONTEND_PATH/dist" ] && [ -f "$FRONTEND_PATH/dist/index.html" ]; then
        log_success "前端文件部署正确"
    else
        log_error "前端文件部署异常"
        return 1
    fi
    
    # 测试HTTP访问
    if curl -f -s http://localhost:3000 > /dev/null; then
        log_success "前端服务HTTP访问正常"
    else
        log_warning "前端服务HTTP访问异常，可能还在启动中"
    fi
    
    log_success "前端部署验证完成"
}

# 清理临时文件
cleanup() {
    log_info "清理临时文件..."
    rm -f /tmp/frontend-deployment.tar.gz
    rm -rf /tmp/frontend-h5-build
    rm -rf /tmp/nginx
    log_success "临时文件清理完成"
}

# 主函数
main() {
    log_info "开始JobFirst前端独立部署流程..."
    
    create_directories
    check_docker
    backup_frontend
    deploy_frontend
    restart_frontend_service
    verify_deployment
    cleanup
    
    log_success "🎉 前端独立部署完成！"
    log_info "前端访问地址: http://$(hostname -I | awk '{print $1}'):3000"
}

# 错误处理
trap 'log_error "部署过程中发生错误，退出码: $?"' ERR

# 执行主函数
main "$@"
