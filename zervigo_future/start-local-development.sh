#!/bin/bash
# start-local-development.sh

echo "🚀 启动本地Mac开发环境"
echo "======================="

# 检查Docker状态
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker未运行，请先启动Docker"
    exit 1
fi

# 启动Zervigo Future版服务
echo "🔧 启动Zervigo Future版服务..."
if [ -f "start-zervigo-future.sh" ]; then
    ./start-zervigo-future.sh
    echo "✅ Zervigo Future版服务启动完成"
else
    echo "❌ start-zervigo-future.sh 脚本不存在"
fi

# 启动AI服务
echo "🔧 启动AI服务..."
if [ -f "start-future-complete-ecosystem.sh" ]; then
    ./start-future-complete-ecosystem.sh
    echo "✅ AI服务启动完成"
else
    echo "❌ start-future-complete-ecosystem.sh 脚本不存在"
fi

# 等待服务启动
echo "⏳ 等待服务启动..."
sleep 10

# 健康检查
echo "🔍 执行健康检查..."
if [ -f "health-check-ai-identity-network.sh" ]; then
    ./health-check-ai-identity-network.sh
else
    echo "❌ health-check-ai-identity-network.sh 脚本不存在"
fi

echo ""
echo "✅ 本地Mac开发环境启动完成！"
echo "访问地址："
echo "  LoomaCRM: http://localhost:7500"
echo "  AI网关: http://localhost:7510"
echo "  简历AI: http://localhost:7511"
echo "  AI模型: http://localhost:8002"
echo "  MinerU: http://localhost:8000"
echo "  监控系统: http://localhost:9091"
echo "  仪表板: http://localhost:3001"
