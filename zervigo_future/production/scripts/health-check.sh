#!/bin/bash

# 健康检查脚本
echo "🔍 开始健康检查..."

# 检查Docker容器状态
echo "📦 检查Docker容器状态..."
docker-compose ps

# 检查服务健康状态
echo "🏥 检查服务健康状态..."
curl -f http://localhost:8800/health && echo "✅ LoomaCRM健康" || echo "❌ LoomaCRM不健康"
curl -f http://localhost:8200/health && echo "✅ Zervigo Future健康" || echo "❌ Zervigo Future不健康"
curl -f http://localhost:9200/health && echo "✅ Zervigo DAO健康" || echo "❌ Zervigo DAO不健康"
curl -f http://localhost:8300/health && echo "✅ Zervigo 区块链健康" || echo "❌ Zervigo 区块链不健康"

# 检查监控服务
echo "📊 检查监控服务..."
curl -f http://localhost:9090/api/v1/query?query=up && echo "✅ Prometheus健康" || echo "❌ Prometheus不健康"
curl -f http://localhost:3000/api/health && echo "✅ Grafana健康" || echo "❌ Grafana不健康"

echo "🎉 健康检查完成！"
