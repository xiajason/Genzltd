#!/bin/bash
# AI身份社交网络启动脚本
# 基于LoomaCRM和Zervigo现有技术基础

echo "🚀 启动AI身份社交网络..."
echo "基于LoomaCRM + Zervigo 现有技术基础"
echo "=================================="

# 检查项目路径
PROJECT_ROOT="/Users/szjason72/genzltd"
if [ ! -d "$PROJECT_ROOT" ]; then
    echo "❌ 项目路径不存在: $PROJECT_ROOT"
    exit 1
fi

cd "$PROJECT_ROOT"

# 1. 启动LoomaCRM Future服务
echo "📊 启动LoomaCRM Future服务..."
cd looma_crm_future

# 检查虚拟环境
if [ ! -d "venv" ]; then
    echo "❌ Python虚拟环境不存在，请先运行: python -m venv venv"
    exit 1
fi

# 激活虚拟环境
source venv/bin/activate

# 启动LoomaCRM Future
echo "🚀 启动LoomaCRM Future (端口7500)..."
python -m looma_crm.app &
LOOMA_PID=$!

# 启动AI网关服务
echo "🤖 启动AI网关服务 (端口7510)..."
cd services/ai_services_independent/ai_gateway_future
python ai_gateway_future.py &
GATEWAY_PID=$!
cd ../../..

# 启动简历AI服务
echo "📝 启动简历AI服务 (端口7511)..."
cd services/ai_services_independent/resume_ai_future
python resume_ai_future.py &
RESUME_PID=$!
cd ../../..

# 注意：MinerU和AI模型服务通过Docker运行，不需要Python模块启动

# 2. 启动Zervigo Future服务
echo "🏢 启动Zervigo Future服务..."
cd ../zervigo_future

# 启动Zervigo Future
echo "🚀 启动Zervigo Future..."
./start-zervigo-future.sh &
ZERVIGO_PID=$!

# 3. 启动Docker服务
echo "🐳 启动Docker服务..."
cd ../looma_crm_future

# 启动Future版Docker服务
echo "📊 启动Future版数据库服务..."
docker-compose -f docker-compose-future.yml up -d

# 等待服务启动
echo "⏳ 等待服务启动..."
sleep 30

# 4. 健康检查
echo "🔍 执行健康检查..."
./health-check-ai-identity-network.sh

# 5. 保存进程ID
echo "$LOOMA_PID" > /tmp/ai-identity-network-looma.pid
echo "$GATEWAY_PID" > /tmp/ai-identity-network-gateway.pid
echo "$RESUME_PID" > /tmp/ai-identity-network-resume.pid
echo "$ZERVIGO_PID" > /tmp/ai-identity-network-zervigo.pid

echo "✅ AI身份社交网络启动完成！"
echo "=================================="
echo "🌐 服务访问地址:"
echo "   LoomaCRM Future: http://localhost:7500"
echo "   AI网关服务: http://localhost:7510"
echo "   简历AI服务: http://localhost:7511"
echo "   Zervigo Future: http://localhost:8080"
echo "=================================="
echo "📊 数据库服务:"
echo "   PostgreSQL: localhost:5434"
echo "   MongoDB: localhost:27018"
echo "   Redis: localhost:6382"
echo "   Neo4j: localhost:7688"
echo "   Weaviate: localhost:8091"
echo "   Elasticsearch: localhost:9202"
echo "=================================="
echo "🔧 管理命令:"
echo "   健康检查: ./health-check-ai-identity-network.sh"
echo "   停止服务: ./stop-ai-identity-network.sh"
echo "   查看日志: ./view-ai-identity-network-logs.sh"
echo "=================================="
