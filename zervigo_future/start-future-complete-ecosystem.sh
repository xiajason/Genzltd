#!/bin/bash

# JobFirst Future版完整生态系统启动脚本
echo "🚀 启动JobFirst Future版完整生态系统..."

# 启动AI服务
echo "🔧 启动Future版AI服务..."
if [ -f "ai-services/start-future-ai-services.sh" ]; then
    cd ai-services
    ./start-future-ai-services.sh
    cd ..
    echo "✅ Future版AI服务启动完成"
fi

# 等待服务启动
echo "⏳ 等待服务启动..."
sleep 5

# 检查服务状态
echo "🔍 检查服务状态..."
echo "=== AI服务 ==="
curl -s http://localhost:7510/health | jq -r '.service // "未运行"' && echo " (AI Gateway)"
curl -s http://localhost:7511/health | jq -r '.service // "未运行"' && echo " (Resume AI)"

echo "🎉 JobFirst Future版AI服务启动完成！"
