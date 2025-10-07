#!/bin/bash
# stop-local-development.sh

echo "🛑 停止本地Mac开发环境"
echo "======================="

# 停止Zervigo Future版服务
echo "🔧 停止Zervigo Future版服务..."
if [ -f "stop-zervigo-future.sh" ]; then
    ./stop-zervigo-future.sh
    echo "✅ Zervigo Future版服务停止完成"
else
    echo "❌ stop-zervigo-future.sh 脚本不存在"
fi

# 停止AI服务
echo "🔧 停止AI服务..."
if [ -f "ai-services/stop-future-ai-services.sh" ]; then
    cd ai-services
    ./stop-future-ai-services.sh
    cd ..
    echo "✅ AI服务停止完成"
else
    echo "❌ ai-services/stop-future-ai-services.sh 脚本不存在"
fi

# 停止所有相关容器
echo "🔧 停止所有相关容器..."
docker stop $(docker ps -q --filter "name=future-") 2>/dev/null || echo "没有future-*容器运行"
docker stop $(docker ps -q --filter "name=jobfirst-") 2>/dev/null || echo "没有jobfirst-*容器运行"

echo ""
echo "✅ 本地Mac开发环境停止完成！"
