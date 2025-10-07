#!/bin/bash

# Future版本停止脚本
# 生成时间: 2025-10-05
# 版本: Future v1.0

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 停止Future版本服务
stop_services() {
    log_info "停止Future版本数据库服务..."
    
    if [ -f "docker-compose.yml" ]; then
        docker-compose down --remove-orphans
        log_success "Future版本服务已停止"
    else
        log_error "docker-compose.yml文件不存在"
        exit 1
    fi
}

# 清理资源
cleanup_resources() {
    log_info "清理资源..."
    
    # 清理未使用的容器
    docker container prune -f
    
    # 清理未使用的网络
    docker network prune -f
    
    log_success "资源清理完成"
}

# 显示停止状态
show_status() {
    log_info "Future版本服务状态:"
    echo ""
    docker-compose ps
    echo ""
    
    log_info "已停止的服务:"
    echo "MySQL: dao-mysql"
    echo "PostgreSQL: dao-postgresql"
    echo "Redis: dao-redis"
    echo "Neo4j: dao-neo4j"
    echo "Elasticsearch: dao-elasticsearch"
    echo "Weaviate: dao-weaviate"
    echo "SQLite Manager: dao-sqlite-manager"
    echo ""
}

# 主函数
main() {
    log_info "停止Future版本数据库..."
    echo ""
    
    stop_services
    cleanup_resources
    show_status
    
    log_success "Future版本停止完成！"
}

# 执行主函数
main "$@"
