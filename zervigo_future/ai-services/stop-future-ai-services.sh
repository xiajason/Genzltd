#!/bin/bash

# JobFirst Future版 AI服务停止脚本
echo "🛑 停止JobFirst Future版 AI服务..."

# 停止AI Gateway
if [ -f "ai-services/logs/ai_gateway.pid" ]; then
    AI_GATEWAY_PID=$(cat ai-services/logs/ai_gateway.pid)
    echo "🔧 停止AI Gateway (PID: $AI_GATEWAY_PID)..."
    kill $AI_GATEWAY_PID 2>/dev/null
    rm -f ai-services/logs/ai_gateway.pid
    echo "✅ AI Gateway已停止"
fi

# 停止Resume AI
if [ -f "ai-services/logs/resume_ai.pid" ]; then
    RESUME_AI_PID=$(cat ai-services/logs/resume_ai.pid)
    echo "🔧 停止Resume AI (PID: $RESUME_AI_PID)..."
    kill $RESUME_AI_PID 2>/dev/null
    rm -f ai-services/logs/resume_ai.pid
    echo "✅ Resume AI已停止"
fi

# 强制清理残留进程
pkill -f "future_ai_gateway.py" 2>/dev/null
pkill -f "future_resume_ai.py" 2>/dev/null

echo "🎉 Future版 AI服务停止完成！"
