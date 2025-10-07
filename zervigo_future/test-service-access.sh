#!/bin/bash
# test-service-access.sh

echo "🧪 本地Mac开发环境服务访问测试"
echo "==============================="

# 测试服务访问
echo "🌐 测试服务访问..."

services=(
    "LoomaCRM服务:7500:/health"
    "AI网关服务:7510:/health"
    "简历AI服务:7511:/health"
    "AI模型服务:8002:/health"
    "MinerU服务:8000:/health"
    "MongoDB数据库:27018:/"
    "PostgreSQL数据库:5434:/"
    "Elasticsearch数据库:9202:/"
    "Neo4j数据库:7474:/"
    "Redis缓存:6382:/"
    "Prometheus监控:9091:/"
    "Grafana面板:3001:/"
)

for service in "${services[@]}"; do
    name=$(echo $service | cut -d: -f1)
    port=$(echo $service | cut -d: -f2)
    endpoint=$(echo $service | cut -d: -f3)
    
    echo "测试 $name (端口 $port$endpoint)..."
    if curl -s -o /dev/null -w '%{http_code}' http://localhost:$port$endpoint | grep -q '200\|302'; then
        echo "  ✅ 访问正常"
    else
        echo "  ❌ 访问失败"
    fi
done

echo ""
echo "✅ 服务访问测试完成"
