#!/bin/bash
# health-check-ai-identity-network.sh

echo "🔍 本地Mac开发环境健康检查"
echo "==============================="

# 检查Docker状态
echo "🐳 检查Docker状态..."
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""

# 检查服务健康状态
echo "🌐 检查服务健康状态..."

services=(
    "LoomaCRM服务:7500"
    "AI网关服务:7510"
    "简历AI服务:7511"
    "AI模型服务:8002"
    "MinerU服务:8000"
    "MongoDB数据库:27018"
    "PostgreSQL数据库:5434"
    "Elasticsearch数据库:9202"
    "Neo4j数据库:7474"
    "Redis缓存:6382"
    "Prometheus监控:9091"
    "Grafana面板:3001"
)

for service in "${services[@]}"; do
    name=$(echo $service | cut -d: -f1)
    port=$(echo $service | cut -d: -f2)
    
    echo "检查 $name (端口 $port)..."
    if curl -s -o /dev/null -w '%{http_code}' http://localhost:$port | grep -q '200\|302'; then
        echo "  ✅ 端口 $port: 健康"
    else
        echo "  ❌ 端口 $port: 不健康"
    fi
done

echo ""

# 检查系统资源
echo "📊 检查系统资源..."
echo "内存使用:"
vm_stat | head -5

echo ""
echo "磁盘使用:"
df -h | grep -E '(Filesystem|/dev/)'

echo ""
echo "✅ 健康检查完成"
