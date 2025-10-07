#!/bin/bash

# Future版本启动脚本
# 生成时间: 2025-10-05
# 版本: Future v1.0

set -e

# 颜色定义
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

# 检查Docker Compose文件
check_compose_file() {
    if [ ! -f "docker-compose.yml" ]; then
        log_error "docker-compose.yml文件不存在"
        exit 1
    fi
}

# 启动Future版本服务
start_services() {
    log_info "启动Future版本数据库服务..."
    
    docker-compose up -d
    
    log_success "Future版本服务启动完成"
}

# 等待服务就绪
wait_for_services() {
    log_info "等待服务就绪..."
    
    # 等待MySQL
    log_info "等待MySQL服务..."
    timeout 60 bash -c 'until docker exec blockchain-mysql mysqladmin ping -h localhost --silent; do sleep 2; done'
    
    # 等待PostgreSQL
    log_info "等待PostgreSQL服务..."
    timeout 60 bash -c 'until docker exec blockchain-postgresql pg_isready -h localhost; do sleep 2; done'
    
    # 等待Redis
    log_info "等待Redis服务..."
    timeout 60 bash -c 'until docker exec blockchain-redis redis-cli ping; do sleep 2; done'
    
    # 等待Neo4j
    log_info "等待Neo4j服务..."
    timeout 60 bash -c 'until curl -f http://localhost:7474; do sleep 2; done'
    
    # 等待Elasticsearch
    log_info "等待Elasticsearch服务..."
    timeout 60 bash -c 'until curl -f http://localhost:9200; do sleep 2; done'
    
    # 等待Weaviate
    log_info "等待Weaviate服务..."
    timeout 60 bash -c 'until curl -f http://localhost:8080/v1/meta; do sleep 2; done'
    
    log_success "所有服务已就绪"
}

# 显示服务状态
show_status() {
    log_info "Future版本服务状态:"
    echo ""
    docker-compose ps
    echo ""
    
    log_info "外部访问信息:"
    echo "MySQL: localhost:3306"
    echo "PostgreSQL: localhost:5432"
    echo "Redis: localhost:6379"
    echo "Neo4j: http://localhost:7474"
    echo "Elasticsearch: http://localhost:9200"
    echo "Weaviate: http://localhost:8080"
    echo ""
}

# 主函数
main() {
    log_info "启动Future版本数据库..."
    echo ""
    
    check_compose_file
    start_services
    wait_for_services
    show_status
    
    log_success "Future版本启动完成！"
}

# 执行主函数
main "$@"
