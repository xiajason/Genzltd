#!/bin/bash

# 每日优化脚本
# 创建时间: 2025年1月27日
# 版本: v1.0

# 获取当前时间戳
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="../../logs/daily_$TIMESTAMP.log"

# 日志函数
log_info() {
    echo "[$TIMESTAMP] [INFO] $1" | tee -a $LOG_FILE
}

log_success() {
    echo "[$TIMESTAMP] [SUCCESS] $1" | tee -a $LOG_FILE
}

log_warning() {
    echo "[$TIMESTAMP] [WARNING] $1" | tee -a $LOG_FILE
}

# 清理临时文件
cleanup_temporary_files() {
    log_info "开始清理临时文件..."
    
    # 清理日志文件
    find . -name "*.log" -mtime +7 -type f -delete
    find . -name "*.out" -mtime +3 -type f -delete
    find . -name "*.err" -mtime +3 -type f -delete
    
    # 清理临时文件
    find . -name "*.tmp" -type f -delete
    find . -name "*.temp" -type f -delete
    find . -name ".DS_Store" -type f -delete
    
    # 清理缓存文件
    find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
    find . -name "*.pyc" -type f -delete
    
    log_success "临时文件清理完成"
}

# 优化Docker资源
optimize_docker_resources() {
    log_info "开始优化Docker资源..."
    
    # 清理未使用的容器
    docker container prune -f
    
    # 清理未使用的镜像
    docker image prune -f
    
    # 清理未使用的卷
    docker volume prune -f
    
    # 清理构建缓存
    docker builder prune -f
    
    log_success "Docker资源优化完成"
}

# 优化数据库
optimize_databases() {
    log_info "开始优化数据库..."
    
    # 优化PostgreSQL
    if nc -z localhost 5432 2>/dev/null; then
        psql -c "VACUUM ANALYZE;" 2>/dev/null || log_warning "PostgreSQL优化失败"
    fi
    
    # 优化Redis
    if nc -z localhost 6379 2>/dev/null; then
        redis-cli BGREWRITEAOF 2>/dev/null || log_warning "Redis优化失败"
    fi
    
    log_success "数据库优化完成"
}

# 检查系统资源
check_system_resources() {
    log_info "开始检查系统资源..."
    
    # 检查磁盘使用率
    DISK_USAGE=$(df -h | grep "/dev/disk3s1s1" | awk '{print $5}' | sed 's/%//')
    if [ "$DISK_USAGE" -gt 80 ]; then
        log_warning "磁盘使用率过高: $DISK_USAGE%"
    else
        log_success "磁盘使用率正常: $DISK_USAGE%"
    fi
    
    # 检查内存使用情况
    MEMORY_FREE=$(vm_stat | grep "Pages free" | awk '{print $3}' | sed 's/\.//')
    if [ "$MEMORY_FREE" -lt 1000 ]; then
        log_warning "可用内存不足: $MEMORY_FREE 页"
    else
        log_success "内存使用正常: $MEMORY_FREE 页可用"
    fi
    
    log_success "系统资源检查完成"
}

# 主函数
main() {
    log_info "开始每日优化..."
    
    cleanup_temporary_files
    optimize_docker_resources
    optimize_databases
    check_system_resources
    
    log_success "每日优化完成"
    echo "优化日志: $LOG_FILE"
}

# 执行优化
main "$@"
