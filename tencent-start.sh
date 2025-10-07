#!/bin/bash
# 腾讯云Future版启动脚本

echo "🚀 启动腾讯云Future版服务..."

cd /opt/future-deployment

# 启动数据库服务
echo "📦 启动数据库服务..."
docker-compose up -d future-redis future-postgres future-mongodb future-neo4j future-elasticsearch future-weaviate

# 等待数据库启动
echo "⏳ 等待数据库启动..."
sleep 30

# 启动AI服务
echo "🤖 启动AI服务..."
docker-compose up -d future-ai-gateway future-resume-ai

# 启动监控服务
echo "📊 启动监控服务..."
docker-compose up -d future-prometheus future-grafana

echo "✅ 腾讯云Future版服务启动完成！"
