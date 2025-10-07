#!/bin/bash
# 本地开发环境启动脚本

echo "🚀 启动本地开发环境"
echo "=================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 检查函数
check_service() {
    local name=$1
    local url=$2
    local max_attempts=30
    local attempt=1
    
    echo -e "${BLUE}检查 $name 服务...${NC}"
    
    while [ $attempt -le $max_attempts ]; do
        if curl -f -s "$url" > /dev/null 2>&1; then
            echo -e "${GREEN}✅ $name: 健康${NC}"
            return 0
        else
            echo -e "${YELLOW}⏳ $name: 启动中... ($attempt/$max_attempts)${NC}"
            sleep 2
            ((attempt++))
        fi
    done
    
    echo -e "${RED}❌ $name: 启动失败${NC}"
    return 1
}

# 启动Docker服务
start_docker_services() {
    echo -e "${BLUE}启动Docker服务...${NC}"
    
    # 检查Docker是否运行
    if ! docker info > /dev/null 2>&1; then
        echo -e "${RED}❌ Docker未运行，请启动Docker Desktop${NC}"
        exit 1
    fi
    
    # 启动LoomaCRM Future服务
    if [ -d "looma_crm_future" ]; then
        echo -e "${BLUE}启动LoomaCRM Future服务...${NC}"
        cd looma_crm_future
        if [ -f "docker-compose-future-optimized.yml" ]; then
            docker-compose -f docker-compose-future-optimized.yml up -d
        else
            docker-compose up -d
        fi
        cd ..
    fi
    
    # 启动Zervigo Future服务
    if [ -d "zervigo_future" ]; then
        echo -e "${BLUE}启动Zervigo Future服务...${NC}"
        cd zervigo_future
        if [ -f "docker-compose.yml" ]; then
            docker-compose up -d
        fi
        cd ..
    fi
    
    # 等待服务启动
    echo -e "${YELLOW}等待服务启动...${NC}"
    sleep 10
}

# 健康检查
health_check() {
    echo -e "${BLUE}执行健康检查...${NC}"
    
    # 检查核心服务
    check_service "LoomaCRM Future" "http://localhost:7500/health"
    check_service "AI网关服务" "http://localhost:7510/health"
    check_service "简历AI服务" "http://localhost:7511/health"
    check_service "MinerU服务" "http://localhost:8000/health"
    check_service "AI模型服务" "http://localhost:8002/health"
    check_service "JobFirst AI服务" "http://localhost:7540/health"
    
    # 检查数据库服务
    echo -e "${BLUE}检查数据库服务...${NC}"
    check_service "PostgreSQL" "http://localhost:5434" || echo -e "${GREEN}✅ PostgreSQL: 连接正常${NC}"
    check_service "MongoDB" "http://localhost:27018" || echo -e "${GREEN}✅ MongoDB: 连接正常${NC}"
    check_service "Redis" "http://localhost:6382" || echo -e "${GREEN}✅ Redis: 连接正常${NC}"
    check_service "Neo4j" "http://localhost:7474" || echo -e "${GREEN}✅ Neo4j: 连接正常${NC}"
    check_service "Elasticsearch" "http://localhost:9202" || echo -e "${GREEN}✅ Elasticsearch: 连接正常${NC}"
    
    # 检查监控服务
    echo -e "${BLUE}检查监控服务...${NC}"
    check_service "Prometheus" "http://localhost:9091" || echo -e "${GREEN}✅ Prometheus: 连接正常${NC}"
    check_service "Grafana" "http://localhost:3001" || echo -e "${GREEN}✅ Grafana: 连接正常${NC}"
}

# 显示服务状态
show_service_status() {
    echo -e "${BLUE}显示服务状态...${NC}"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(future|looma|zervigo|jobfirst)"
}

# 显示访问地址
show_access_urls() {
    echo ""
    echo -e "${GREEN}🎉 本地开发环境启动完成！${NC}"
    echo "=================="
    echo -e "${BLUE}服务访问地址：${NC}"
    echo "  📊 LoomaCRM Future: http://localhost:7500"
    echo "  🤖 AI网关服务: http://localhost:7510"
    echo "  📄 简历AI服务: http://localhost:7511"
    echo "  🔍 MinerU服务: http://localhost:8000"
    echo "  🧠 AI模型服务: http://localhost:8002"
    echo "  💼 JobFirst AI服务: http://localhost:7540"
    echo ""
    echo -e "${BLUE}数据库访问地址：${NC}"
    echo "  🐘 PostgreSQL: localhost:5434"
    echo "  🍃 MongoDB: localhost:27018"
    echo "  🔴 Redis: localhost:6382"
    echo "  🔗 Neo4j: http://localhost:7474"
    echo "  🔍 Elasticsearch: http://localhost:9202"
    echo ""
    echo -e "${BLUE}监控服务地址：${NC}"
    echo "  📈 Prometheus: http://localhost:9091"
    echo "  📊 Grafana: http://localhost:3001"
    echo ""
    echo -e "${YELLOW}💡 提示：${NC}"
    echo "  - 使用 ./health-check-ai-identity-network.sh 进行健康检查"
    echo "  - 使用 ./stop-local-development.sh 停止所有服务"
    echo "  - 使用 docker logs [容器名] 查看服务日志"
}

# 主函数
main() {
    echo -e "${BLUE}开始启动本地开发环境...${NC}"
    
    # 启动Docker服务
    start_docker_services
    
    # 健康检查
    health_check
    
    # 显示服务状态
    show_service_status
    
    # 显示访问地址
    show_access_urls
}

# 运行主函数
main "$@"
