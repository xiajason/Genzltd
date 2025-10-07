#!/bin/bash

# Future版本部署脚本
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

# 检查Docker和Docker Compose
check_dependencies() {
    log_info "检查依赖..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker未安装，请先安装Docker"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose未安装，请先安装Docker Compose"
        exit 1
    fi
    
    log_success "依赖检查通过"
}

# 创建目录结构
create_directories() {
    log_info "创建目录结构..."
    
    mkdir -p data/{mysql,postgresql,redis,neo4j,elasticsearch,weaviate,sqlite}
    mkdir -p logs/{mysql,postgresql,redis,neo4j,elasticsearch,weaviate,sqlite}
    mkdir -p scripts
    
    log_success "目录结构创建完成"
}

# 设置权限
set_permissions() {
    log_info "设置目录权限..."
    
    chmod -R 755 data/
    chmod -R 755 logs/
    chmod -R 755 scripts/
    
    log_success "权限设置完成"
}

# 停止现有服务
stop_existing_services() {
    log_info "停止现有Future版本服务..."
    
    if [ -f "docker-compose.yml" ]; then
        docker-compose down --remove-orphans || true
    fi
    
    log_success "现有服务已停止"
}

# 启动Future版本服务
start_dao_services() {
    log_info "启动Future版本数据库服务..."
    
    docker-compose up -d
    
    log_success "Future版本服务启动完成"
}

# 等待服务就绪
wait_for_services() {
    log_info "等待服务就绪..."
    
    # 等待MySQL
    log_info "等待MySQL服务..."
    timeout 60 bash -c 'until docker exec dao-mysql mysqladmin ping -h localhost --silent; do sleep 2; done'
    
    # 等待PostgreSQL
    log_info "等待PostgreSQL服务..."
    timeout 60 bash -c 'until docker exec dao-postgresql pg_isready -h localhost; do sleep 2; done'
    
    # 等待Redis
    log_info "等待Redis服务..."
    timeout 60 bash -c 'until docker exec dao-redis redis-cli ping; do sleep 2; done'
    
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

# 执行数据库结构创建
create_database_structures() {
    log_info "创建数据库结构..."
    
    # 复制脚本到容器
    docker cp dao_database_structure_executor.py dao-sqlite-manager:/app/scripts/
    docker cp dao_mysql_database_structure.sql dao-sqlite-manager:/app/scripts/
    docker cp dao_postgresql_database_structure.sql dao-sqlite-manager:/app/scripts/
    docker cp dao_sqlite_database_structure.py dao-sqlite-manager:/app/scripts/
    docker cp dao_redis_database_structure.py dao-sqlite-manager:/app/scripts/
    docker cp dao_neo4j_database_structure.py dao-sqlite-manager:/app/scripts/
    docker cp dao_elasticsearch_database_structure.py dao-sqlite-manager:/app/scripts/
    docker cp dao_weaviate_database_structure.py dao-sqlite-manager:/app/scripts/
    docker cp dao_database_verification_script.py dao-sqlite-manager:/app/scripts/
    
    # 执行数据库结构创建
    docker exec dao-sqlite-manager python3 /app/scripts/dao_database_structure_executor.py
    
    log_success "数据库结构创建完成"
}

# 验证部署
verify_deployment() {
    log_info "验证部署..."
    
    # 执行验证脚本
    docker exec dao-sqlite-manager python3 /app/scripts/dao_database_verification_script.py
    
    log_success "部署验证完成"
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
    log_info "开始部署Future版本数据库..."
    echo ""
    
    check_dependencies
    create_directories
    set_permissions
    stop_existing_services
    start_dao_services
    wait_for_services
    create_database_structures
    verify_deployment
    show_status
    
    log_success "Future版本部署完成！"
    echo ""
    log_info "使用以下命令管理服务:"
    echo "启动: docker-compose up -d"
    echo "停止: docker-compose down"
    echo "查看状态: docker-compose ps"
    echo "查看日志: docker-compose logs -f"
}

# 执行主函数
main "$@"
