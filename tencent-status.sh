#!/bin/bash
# 腾讯云Future版状态检查脚本

echo "🔍 检查腾讯云Future版服务状态..."

cd /opt/future-deployment

# 检查容器状态
echo "📦 检查容器状态..."
docker-compose ps

# 检查端口状态
echo "🔌 检查端口状态..."
netstat -tlnp | grep -E "(7510|7511|6383|5435|27019|7476|7689|9203|8083)"

# 检查服务健康
echo "🏥 检查服务健康..."
curl -s http://localhost:7510/health || echo "AI网关服务异常"
curl -s http://localhost:7511/health || echo "简历AI服务异常"

echo "✅ 状态检查完成！"
