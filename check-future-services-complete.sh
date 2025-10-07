#!/bin/bash

# JobFirst Future版双AI服务架构状态检查脚本
# 检查所有Future版服务的运行状态，包括双AI架构

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
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

log_ai() {
    echo -e "${PURPLE}[AI]${NC} $1"
}

# 检查服务状态
check_service_status() {
    local port=$1
    local service_name=$2
    local service_type=$3
    
    if lsof -i ":$port" >/dev/null 2>&1; then
        echo "  ✅ $service_name (端口$port) - 运行中"
        
        # 特殊处理数据库服务健康检查
        if [ "$service_name" = "PostgreSQL" ]; then
            # 使用pg_isready检查PostgreSQL连接
            if command -v pg_isready >/dev/null 2>&1; then
                if pg_isready -h localhost -p $port -U jobfirst_future -d jobfirst_future >/dev/null 2>&1; then
                    echo "     🏥 健康状态: 正常"
                else
                    echo "     🏥 健康状态: 异常 (连接失败)"
                fi
            else
                # 使用nc检查端口连接
                if nc -z localhost $port 2>/dev/null; then
                    echo "     🏥 健康状态: 正常"
                else
                    echo "     🏥 健康状态: 异常 (连接失败)"
                fi
            fi
        elif [ "$service_name" = "MongoDB" ]; then
            # 使用mongo客户端检查MongoDB连接
            if command -v mongo >/dev/null 2>&1; then
                if mongo --host localhost:$port --eval "db.runCommand('ping')" >/dev/null 2>&1; then
                    echo "     🏥 健康状态: 正常"
                else
                    echo "     🏥 健康状态: 异常 (连接失败)"
                fi
            else
                # 使用nc检查端口连接
                if nc -z localhost $port 2>/dev/null; then
                    echo "     🏥 健康状态: 正常"
                else
                    echo "     🏥 健康状态: 异常 (连接失败)"
                fi
            fi
        elif [ "$service_name" = "Redis" ]; then
            # 使用redis-cli检查Redis连接
            if command -v redis-cli >/dev/null 2>&1; then
                if redis-cli -p $port ping >/dev/null 2>&1; then
                    echo "     🏥 健康状态: 正常"
                else
                    echo "     🏥 健康状态: 异常 (连接失败)"
                fi
            else
                # 使用nc检查端口连接
                if nc -z localhost $port 2>/dev/null; then
                    echo "     🏥 健康状态: 正常"
                else
                    echo "     🏥 健康状态: 异常 (连接失败)"
                fi
            fi
        else
            # 对于HTTP服务，尝试健康检查
            if curl -s http://localhost:$port/health >/dev/null 2>&1; then
                echo "     🏥 健康状态: 正常"
            else
                echo "     🏥 健康状态: 异常 (unknown)"
            fi
        fi
    else
        echo "  ❌ $service_name (端口$port) - 未运行"
    fi
}

log_info "JobFirst Future版双AI服务架构状态检查"

# 检查Looma CRM Future AI服务
log_ai "Looma CRM Future AI服务:"
check_service_status 7500 "Looma CRM Future" "AI"
check_service_status 7510 "AI Gateway" "AI"
check_service_status 7511 "Resume AI" "AI"

# 检查Zervigo Future AI服务
log_ai "Zervigo Future AI服务:"
check_service_status 7540 "AI Service" "AI"
check_service_status 8621 "MinerU" "AI"
check_service_status 8622 "AI Models" "AI"
check_service_status 8623 "AI Monitor" "AI"

# 检查基础服务
log_info "基础服务:"
check_service_status 3306 "MySQL" "Database"
check_service_status 6382 "Redis" "Database"
check_service_status 5434 "PostgreSQL" "Database"
check_service_status 27018 "MongoDB" "Database"
check_service_status 9202 "Elasticsearch" "Database"
check_service_status 8082 "Weaviate" "Database"
check_service_status 7474 "Neo4j" "Database"

# 检查Docker容器状态
log_info "检查Docker容器状态..."

# 定义容器映射
containers=(
    "future-mysql:MySQL"
    "future-redis:Redis"
    "future-postgres:PostgreSQL"
    "future-mongodb:MongoDB"
    "future-neo4j:Neo4j"
    "future-elasticsearch:Elasticsearch"
    "future-weaviate:Weaviate"
    "future-ai-gateway:AI Gateway"
    "future-resume-ai:Resume AI"
    "future-mineru:MinerU"
    "future-ai-models:AI Models"
    "future-prometheus:Prometheus"
    "future-grafana:Grafana"
    "jobfirst-ai-service:AI Service"
    "jobfirst-ai-models:AI Models"
    "jobfirst-mineru:MinerU"
    "jobfirst-ai-monitor:AI Monitor"
)

# 统计变量
total_containers=0
running_containers=0
healthy_containers=0

for container in "${containers[@]}"; do
    container_name=$(echo $container | cut -d: -f1)
    service_name=$(echo $container | cut -d: -f2)
    total_containers=$((total_containers + 1))
    
    if docker ps --format "table {{.Names}}\t{{.Status}}" | grep -q "$container_name"; then
        running_containers=$((running_containers + 1))
        status=$(docker ps --format "table {{.Names}}\t{{.Status}}" | grep "$container_name" | awk '{print $2}')
        
        if [[ "$status" == *"healthy"* ]] || [[ "$status" == *"Up"* ]]; then
            healthy_containers=$((healthy_containers + 1))
            echo "  ✅ $service_name - 运行中 (健康)"
        else
            echo "  ⚠️  $service_name - 运行中 (不健康)"
        fi
    else
        echo "  ❌ $service_name - 未运行"
    fi
done

# 计算统计信息
running_rate=$((running_containers * 100 / total_containers))
health_rate=$((healthy_containers * 100 / total_containers))

log_info "Docker容器统计:"
echo "  总容器数: $total_containers"
echo "  运行中: $running_containers"
echo "  健康状态: $healthy_containers"
echo "  未运行: $((total_containers - running_containers))"
echo "  运行率: $running_rate%"
echo "  健康率: $health_rate%"

# 双AI架构服务统计
looma_ai_running=0
looma_ai_total=3
zervigo_ai_running=0
zervigo_ai_total=4
base_services_running=0
base_services_total=7

# 检查Looma CRM Future AI服务
if docker ps | grep -q "future-looma-crm\|future-ai-gateway\|future-resume-ai"; then
    looma_ai_running=3
fi

# 检查Zervigo Future AI服务
if docker ps | grep -q "jobfirst-ai-service\|jobfirst-ai-models\|jobfirst-mineru\|jobfirst-ai-monitor"; then
    zervigo_ai_running=4
fi

# 检查基础服务
if docker ps | grep -q "future-mysql\|future-redis\|future-postgres\|future-mongodb\|future-neo4j\|future-elasticsearch\|future-weaviate"; then
    base_services_running=7
fi

log_info "双AI架构服务统计:"
echo "  Looma CRM Future AI: $looma_ai_running/$looma_ai_total ($((looma_ai_running * 100 / looma_ai_total))%)"
echo "  Zervigo Future AI: $zervigo_ai_running/$zervigo_ai_total ($((zervigo_ai_running * 100 / zervigo_ai_total))%)"
echo "  基础服务: $base_services_running/$base_services_total ($((base_services_running * 100 / base_services_total))%)"

# 总体服务统计
total_services=14
running_services=0
not_running_services=0

# 检查所有服务端口
services=(
    "7500:Looma CRM Future"
    "7510:AI Gateway"
    "7511:Resume AI"
    "7540:AI Service"
    "8621:MinerU"
    "8622:AI Models"
    "8623:AI Monitor"
    "3306:MySQL"
    "6382:Redis"
    "5434:PostgreSQL"
    "27018:MongoDB"
    "9202:Elasticsearch"
    "8082:Weaviate"
    "7474:Neo4j"
)

for service in "${services[@]}"; do
    port=$(echo $service | cut -d: -f1)
    if lsof -i ":$port" >/dev/null 2>&1; then
        running_services=$((running_services + 1))
    else
        not_running_services=$((not_running_services + 1))
    fi
done

log_info "总体服务统计:"
echo "  总服务数: $total_services"
echo "  运行中: $running_services"
echo "  未运行: $not_running_services"
echo "  运行率: $((running_services * 100 / total_services))%"

# 根据运行状态给出建议
if [ $running_services -eq $total_services ]; then
    log_success "双AI架构所有服务运行正常"
elif [ $running_services -gt $((total_services / 2)) ]; then
    log_warning "双AI架构部分服务运行正常"
else
    log_error "双AI架构大部分服务未运行"
fi

echo ""
echo "🌐 访问地址:"
echo "  Looma CRM Future: http://localhost:7500"
echo "  AI Gateway: http://localhost:7510"
echo "  Resume AI: http://localhost:7511"
echo "  AI Service: http://localhost:7540"
echo "  AI Models: http://localhost:8622"
echo "  MinerU: http://localhost:8621"
echo "  AI Monitor: http://localhost:8623"
echo "  Prometheus: http://localhost:9091"
echo "  Grafana: http://localhost:3001"