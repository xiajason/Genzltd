#!/bin/bash

# 数据库容器化启动脚本
# 用于启动所有数据库容器和监控服务

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
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

# 获取脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo -e "${BLUE}🐳 启动LoomaCRM数据库容器化服务${NC}"
echo "=================================="

# 1. 检查Docker环境
log_info "检查Docker环境..."
if ! command -v docker &> /dev/null; then
    log_error "Docker未安装或未启动"
    exit 1
fi

if ! docker info &> /dev/null; then
    log_error "Docker服务未运行"
    exit 1
fi

log_success "Docker环境检查通过"

# 2. 检查Docker Compose文件
log_info "检查Docker Compose配置文件..."
if [ ! -f "$PROJECT_ROOT/docker-compose.database.yml" ]; then
    log_error "Docker Compose配置文件不存在: docker-compose.database.yml"
    exit 1
fi

log_success "Docker Compose配置文件检查通过"

# 3. 停止本地数据库实例
log_info "停止本地数据库实例..."
log_warning "正在停止本地MongoDB实例 (端口27018)..."
pkill -f "mongod.*27018" 2>/dev/null || true

log_warning "正在停止本地PostgreSQL实例 (端口5434)..."
pkill -f "postgres.*5434" 2>/dev/null || true

log_warning "正在停止本地Redis实例 (端口6382)..."
pkill -f "redis.*6382" 2>/dev/null || true

log_warning "正在停止本地Neo4j实例 (端口7475)..."
pkill -f "neo4j.*7475" 2>/dev/null || true

sleep 3
log_success "本地数据库实例已停止"

# 4. 启动数据库容器
log_info "启动数据库容器..."
cd "$PROJECT_ROOT"

# 启动所有服务
docker-compose -f docker-compose.database.yml up -d

if [ $? -eq 0 ]; then
    log_success "数据库容器启动成功"
else
    log_error "数据库容器启动失败"
    exit 1
fi

# 5. 等待服务就绪
log_info "等待服务就绪..."
sleep 10

# 6. 检查服务状态
log_info "检查服务状态..."

services=("mongodb" "postgresql" "redis" "neo4j" "elasticsearch" "weaviate" "prometheus" "grafana")
for service in "${services[@]}"; do
    if docker-compose -f docker-compose.database.yml ps "$service" | grep -q "Up"; then
        log_success "$service 服务运行正常"
    else
        log_warning "$service 服务状态异常"
    fi
done

# 7. 显示服务信息
echo ""
echo -e "${GREEN}✅ 数据库容器化服务启动完成${NC}"
echo "=================================="
echo ""
echo -e "${BLUE}服务访问信息:${NC}"
echo "MongoDB:     localhost:27018 (admin/looma_admin_password)"
echo "PostgreSQL:  localhost:5434 (looma_user/looma_password)"
echo "Redis:       localhost:6382 (密码: looma_independent_password)"
echo "Neo4j:       localhost:7475 (neo4j/looma_password)"
echo "Elasticsearch: localhost:9202"
echo "Weaviate:    localhost:8091"
echo "Prometheus:  localhost:9090"
echo "Grafana:     localhost:3000 (admin/looma_grafana_password)"
echo ""
echo -e "${BLUE}管理命令:${NC}"
echo "查看状态:    docker-compose -f docker-compose.database.yml ps"
echo "查看日志:    docker-compose -f docker-compose.database.yml logs [服务名]"
echo "停止服务:    docker-compose -f docker-compose.database.yml down"
echo "重启服务:    docker-compose -f docker-compose.database.yml restart [服务名]"
echo ""
echo -e "${GREEN}数据库容器化迁移完成！${NC}"
