#!/bin/bash

# JobFirst Future版 AI服务启动脚本
echo "🚀 启动JobFirst Future版 AI服务..."

# 检查Python环境
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3未安装"
    exit 1
fi

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 启动AI Gateway
echo "🔧 启动AI Gateway (端口7510)..."
cd future-ai-gateway
if [ ! -f "future_ai_gateway.py" ]; then
    echo "❌ AI Gateway代码不存在"
    exit 1
fi

# 后台启动AI Gateway
nohup python3 future_ai_gateway.py > ../logs/ai_gateway.log 2>&1 &
AI_GATEWAY_PID=$!
echo "✅ AI Gateway已启动，PID: $AI_GATEWAY_PID"

# 等待AI Gateway启动
sleep 3

# 启动Resume AI
echo "🔧 启动Resume AI (端口7511)..."
cd ../future-resume-ai
if [ ! -f "future_resume_ai.py" ]; then
    echo "❌ Resume AI代码不存在"
    exit 1
fi

# 后台启动Resume AI
nohup python3 future_resume_ai.py > ../logs/resume_ai.log 2>&1 &
RESUME_AI_PID=$!
echo "✅ Resume AI已启动，PID: $RESUME_AI_PID"

# 保存PID到文件
echo "$AI_GATEWAY_PID" > ../logs/ai_gateway.pid
echo "$RESUME_AI_PID" > ../logs/resume_ai.pid

echo "🎉 Future版 AI服务启动完成！"
echo "📊 服务状态："
echo "   - AI Gateway (7510): PID $AI_GATEWAY_PID"
echo "   - Resume AI (7511): PID $RESUME_AI_PID"
