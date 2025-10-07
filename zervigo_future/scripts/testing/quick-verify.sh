#!/bin/bash

# JobFirst 快速验证脚本
# 用于快速检查部署状态

set -e

# 配置
DEPLOY_PATH="/opt/jobfirst"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# 快速检查函数
quick_check() {
    local name="$1"
    local command="$2"
    local expected="$3"
    
    log_info "检查 $name..."
    if eval "$command" > /dev/null 2>&1; then
        log_success "$name: $expected"
        return 0
    else
        log_error "$name: 检查失败"
        return 1
    fi
}

# 主函数
main() {
    echo "=== JobFirst 快速部署验证 ==="
    echo
    
    cd $DEPLOY_PATH
    
    # 检查Docker环境
    quick_check "Docker服务" "docker info" "运行正常"
    
    # 检查容器状态
    log_info "检查容器状态..."
    docker-compose ps
    
    # 检查基础设施
    quick_check "MySQL数据库" "docker-compose exec -T mysql mysqladmin ping -h localhost" "连接正常"
    quick_check "Redis缓存" "docker-compose exec -T redis redis-cli ping" "连接正常"
    quick_check "PostgreSQL数据库" "docker-compose exec -T postgres pg_isready -U postgres" "连接正常"
    quick_check "Neo4j数据库" "curl -f http://localhost:7474" "连接正常"
    
    # 检查微服务
    quick_check "Consul服务发现" "curl -f http://localhost:8500/v1/status/leader" "运行正常"
    quick_check "后端服务" "curl -f http://localhost:8080/health" "健康检查通过"
    quick_check "AI服务" "curl -f http://localhost:8000/health" "健康检查通过"
    
    # 检查前端
    quick_check "前端服务" "curl -f http://localhost:3000" "HTTP访问正常"
    
    echo
    echo "=== 服务访问地址 ==="
    echo "前端应用: http://$(hostname -I | awk '{print $1}'):3000"
    echo "后端API: http://$(hostname -I | awk '{print $1}'):8080"
    echo "AI服务: http://$(hostname -I | awk '{print $1}'):8000"
    echo "Consul: http://$(hostname -I | awk '{print $1}'):8500"
    echo "Neo4j: http://$(hostname -I | awk '{print $1}'):7474"
    echo
    
    log_success "🎉 快速验证完成！"
}

# 执行主函数
main "$@"
