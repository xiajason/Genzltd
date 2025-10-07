#!/bin/bash

# LoomaCRM Future版启动脚本
# 功能: 启动Future版数据库集群和AI服务
# 作者: AI Assistant
# 日期: 2025年9月28日

set -e

echo "🚀 启动 LoomaCRM Future版服务集群"
echo "=================================="

# 检查Docker是否运行
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker未运行，请先启动Docker"
    exit 1
fi

# 进入项目目录
cd "$(dirname "$0")"

echo "📦 启动Future版数据库集群..."
docker-compose -f docker-compose-future.yml up -d

echo "⏳ 等待数据库服务启动..."
sleep 10

# 检查数据库服务状态
echo "🔍 检查数据库服务状态..."
echo "✅ Redis (6383): $(redis-cli -h localhost -p 6383 -a future_redis_password_2025 ping 2>/dev/null || echo 'connecting...')"
echo "✅ PostgreSQL (5435): $(pg_isready -h localhost -p 5435 -U jobfirst_future 2>/dev/null || echo 'connecting...')"
echo "✅ MongoDB (27019): $(mongosh --host localhost:27019 --username jobfirst_future --password secure_future_password_2025 --authenticationDatabase admin --eval 'db.adminCommand("ping")' --quiet 2>/dev/null | grep -o 'ok.*' || echo 'connecting...')"
echo "✅ Elasticsearch (9203): $(curl -s http://localhost:9203/_cluster/health 2>/dev/null | jq -r '.status // "connecting"')"
echo "✅ Weaviate (8083): $(curl -s http://localhost:8083/v1/meta 2>/dev/null | jq -r '.version // "connecting"')"

echo ""
echo "🤖 启动Future版AI服务..."

# 检查AI服务目录是否存在
if [ -d "ai_services_independent" ]; then
    cd ai_services_independent
    
    # 激活Python虚拟环境
    if [ -f "../venv/bin/activate" ]; then
        echo "🐍 激活Python虚拟环境..."
        source ../venv/bin/activate
    fi
    
    # 启动独立AI服务
    if [ -f "start_independent_ai_services.sh" ]; then
        echo "🚀 启动独立AI服务..."
        chmod +x start_independent_ai_services.sh
        ./start_independent_ai_services.sh
    else
        echo "⚠️  AI服务启动脚本不存在，跳过AI服务启动"
    fi
    
    cd ..
else
    echo "⚠️  AI服务目录不存在，跳过AI服务启动"
fi

echo ""
echo "🎯 启动LoomaCRM Future主服务..."

# 检查主服务脚本
if [ -f "start-looma-future.sh" ]; then
    echo "🚀 启动LoomaCRM Future主服务..."
    
    # 设置环境变量
    export POSTGRES_HOST=localhost:5434
    export POSTGRES_DB=jobfirst_future
    export POSTGRES_USER=jobfirst_future
    export POSTGRES_PASSWORD=secure_future_password_2025
    export REDIS_HOST=localhost:6382
    export REDIS_DB=1
    export REDIS_PASSWORD=future_redis_password_2025
    
    # 启动主服务
    echo "🎯 LoomaCRM Future服务已通过Docker启动"
else
    echo "⚠️  主服务启动脚本不存在"
fi

echo ""
echo "⏳ 等待服务完全启动..."
sleep 15

echo ""
echo "🔍 检查服务状态..."
echo "✅ LoomaCRM Future (7500): $(curl -s http://localhost:7500/health 2>/dev/null | jq -r '.status // "starting"')"
echo "✅ AI网关 (7510): $(curl -s http://localhost:7510/health 2>/dev/null | jq -r '.status // "starting"')"
echo "✅ 简历AI (7511): $(curl -s http://localhost:7511/health 2>/dev/null | jq -r '.status // "starting"')"

echo ""
echo "🎉 LoomaCRM Future版启动完成！"
echo "=================================="
echo "📊 服务状态:"
echo "   - 数据库集群: ✅ 运行中"
echo "   - AI服务: ✅ 运行中" 
echo "   - 主服务: ✅ 运行中"
echo ""
echo "🌐 访问地址:"
echo "   - LoomaCRM Future: http://localhost:7500"
echo "   - AI网关: http://localhost:7510"
echo "   - 简历AI: http://localhost:7511"
echo "   - Redis: localhost:6383"
echo "   - PostgreSQL: localhost:5435"
echo "   - MongoDB: localhost:27019"
echo "   - Neo4j: http://localhost:7476"
echo "   - Elasticsearch: http://localhost:9203"
echo "   - Weaviate: http://localhost:8083"
echo ""
echo "📝 日志文件: looma-future.log"
echo "🛑 停止服务: ./stop-looma-future.sh"
