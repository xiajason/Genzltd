#!/bin/bash

# Future版本监控脚本
# 生成时间: 2025-10-05
# 版本: Future v1.0

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

# 检查服务状态
check_service_status() {
    log_info "检查Future版本服务状态..."
    echo ""
    
    # 检查Docker Compose服务
    if [ -f "docker-compose.yml" ]; then
        docker-compose ps
    else
        log_error "docker-compose.yml文件不存在"
        return 1
    fi
    echo ""
}

# 检查数据库连接
check_database_connections() {
    log_info "检查数据库连接..."
    echo ""
    
    # 检查MySQL
    if docker exec blockchain-mysql mysqladmin ping -h localhost --silent; then
        log_success "MySQL: 连接正常"
    else
        log_error "MySQL: 连接失败"
    fi
    
    # 检查PostgreSQL
    if docker exec blockchain-postgresql pg_isready -h localhost; then
        log_success "PostgreSQL: 连接正常"
    else
        log_error "PostgreSQL: 连接失败"
    fi
    
    # 检查Redis
    if docker exec blockchain-redis redis-cli ping | grep -q PONG; then
        log_success "Redis: 连接正常"
    else
        log_error "Redis: 连接失败"
    fi
    
    # 检查Neo4j
    if curl -f http://localhost:7474 > /dev/null 2>&1; then
        log_success "Neo4j: 连接正常"
    else
        log_error "Neo4j: 连接失败"
    fi
    
    # 检查Elasticsearch
    if curl -f http://localhost:9200 > /dev/null 2>&1; then
        log_success "Elasticsearch: 连接正常"
    else
        log_error "Elasticsearch: 连接失败"
    fi
    
    # 检查Weaviate
    if curl -f http://localhost:8080/v1/meta > /dev/null 2>&1; then
        log_success "Weaviate: 连接正常"
    else
        log_error "Weaviate: 连接失败"
    fi
    
    echo ""
}

# 检查资源使用情况
check_resource_usage() {
    log_info "检查资源使用情况..."
    echo ""
    
    # 检查容器资源使用
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"
    echo ""
    
    # 检查磁盘使用
    log_info "磁盘使用情况:"
    df -h
    echo ""
    
    # 检查内存使用
    log_info "内存使用情况:"
    free -h
    echo ""
}

# 检查日志
check_logs() {
    log_info "检查服务日志..."
    echo ""
    
    # 检查各服务的最近日志
    services=("blockchain-mysql" "blockchain-postgresql" "blockchain-redis" "blockchain-neo4j" "blockchain-elasticsearch" "blockchain-weaviate")
    
    for service in "${services[@]}"; do
        log_info "=== $service 日志 ==="
        docker logs --tail 10 "$service" 2>/dev/null || log_warning "$service 日志获取失败"
        echo ""
    done
}

# 检查端口占用
check_ports() {
    log_info "检查端口占用情况..."
    echo ""
    
    ports=(3306 5432 6379 7474 7687 9200 8080 8082)
    
    for port in "${ports[@]}"; do
        if netstat -tuln | grep -q ":$port "; then
            log_success "端口 $port: 正在使用"
        else
            log_warning "端口 $port: 未使用"
        fi
    done
    echo ""
}

# 执行健康检查
run_health_check() {
    log_info "执行健康检查..."
    echo ""
    
    # 执行数据库验证脚本
    if [ -f "scripts/blockchain_database_verification_script.py" ]; then
        docker exec blockchain-sqlite-manager python3 /app/scripts/blockchain_database_verification_script.py
    else
        log_warning "验证脚本不存在，跳过健康检查"
    fi
    echo ""
}

# 显示监控报告
show_monitor_report() {
    log_info "=== Future版本监控报告 ==="
    echo ""
    echo "监控时间: $(date)"
    echo "主机名: $(hostname)"
    echo "系统负载: $(uptime)"
    echo ""
    
    log_info "服务状态摘要:"
    echo "MySQL: 元数据存储"
    echo "PostgreSQL: AI服务数据"
    echo "Redis: 缓存和会话"
    echo "Neo4j: 关系网络"
    echo "Elasticsearch: 全文搜索"
    echo "Weaviate: 向量搜索"
    echo "SQLite: 用户数据"
    echo ""
    
    log_info "外部访问地址:"
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
    log_info "开始监控Future版本..."
    echo ""
    
    check_service_status
    check_database_connections
    check_resource_usage
    check_logs
    check_ports
    run_health_check
    show_monitor_report
    
    log_success "Future版本监控完成！"
}

# 执行主函数
main "$@"
