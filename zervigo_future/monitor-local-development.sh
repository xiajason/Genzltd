#!/bin/bash
# monitor-local-development.sh

echo "📊 本地Mac开发环境服务状态监控"
echo "==============================="

# 检查Docker容器状态
echo "🐳 Docker容器状态:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""

# 检查服务健康状态
echo "🌐 服务健康状态:"
services=(
    "LoomaCRM:7500"
    "AI网关:7510"
    "简历AI:7511"
    "AI模型:8002"
    "MinerU:8000"
    "MongoDB:27018"
    "PostgreSQL:5434"
    "Elasticsearch:9202"
    "Neo4j:7474"
    "Redis:6382"
    "Prometheus:9091"
    "Grafana:3001"
)

for service in "${services[@]}"; do
    name=$(echo $service | cut -d: -f1)
    port=$(echo $service | cut -d: -f2)
    
    echo -n "$name (端口 $port): "
    if curl -s -o /dev/null -w '%{http_code}' http://localhost:$port | grep -q '200\|302'; then
        echo "✅ 健康"
    else
        echo "❌ 不健康"
    fi
done

echo ""

# 检查系统资源
echo "📊 系统资源使用:"
echo "内存使用:"
vm_stat | head -5

echo ""
echo "磁盘使用:"
df -h | grep -E '(Filesystem|/dev/)'

echo ""
echo "✅ 服务状态监控完成"
