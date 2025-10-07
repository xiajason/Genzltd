#!/bin/bash

# JobFirst Future版独立AI服务停止脚本

echo "🛑 停止JobFirst Future版独立AI服务集群..."

# 检查PID文件是否存在
if [ ! -f "logs/ai_services.pids" ]; then
    echo "❌ PID文件不存在，可能服务未启动"
    exit 1
fi

# 读取PID文件
source logs/ai_services.pids

# 停止AI网关服务
if [ ! -z "$AI_GATEWAY_PID" ] && ps -p $AI_GATEWAY_PID > /dev/null; then
    echo "🛑 停止AI网关服务 (PID: $AI_GATEWAY_PID)..."
    kill $AI_GATEWAY_PID
    sleep 2
    
    # 强制停止如果还在运行
    if ps -p $AI_GATEWAY_PID > /dev/null; then
        echo "⚠️  强制停止AI网关服务..."
        kill -9 $AI_GATEWAY_PID
    fi
    echo "✅ AI网关服务已停止"
else
    echo "ℹ️  AI网关服务未运行"
fi

# 停止简历AI服务
if [ ! -z "$RESUME_AI_PID" ] && ps -p $RESUME_AI_PID > /dev/null; then
    echo "🛑 停止简历AI服务 (PID: $RESUME_AI_PID)..."
    kill $RESUME_AI_PID
    sleep 2
    
    # 强制停止如果还在运行
    if ps -p $RESUME_AI_PID > /dev/null; then
        echo "⚠️  强制停止简历AI服务..."
        kill -9 $RESUME_AI_PID
    fi
    echo "✅ 简历AI服务已停止"
else
    echo "ℹ️  简历AI服务未运行"
fi

# 停止双AI协作管理器
if [ ! -z "$DUAL_AI_PID" ] && ps -p $DUAL_AI_PID > /dev/null; then
    echo "🛑 停止双AI协作管理器 (PID: $DUAL_AI_PID)..."
    kill $DUAL_AI_PID
    sleep 2
    
    # 强制停止如果还在运行
    if ps -p $DUAL_AI_PID > /dev/null; then
        echo "⚠️  强制停止双AI协作管理器..."
        kill -9 $DUAL_AI_PID
    fi
    echo "✅ 双AI协作管理器已停止"
else
    echo "ℹ️  双AI协作管理器未运行"
fi

# 清理PID文件
rm -f logs/ai_services.pids
rm -f logs/ai_gateway.pid
rm -f logs/resume_ai.pid
rm -f logs/dual_ai_collaboration.pid

echo ""
echo "🎉 Future版独立AI服务集群已完全停止！"
echo ""
echo "📊 服务状态:"
echo "├── ❌ AI网关服务 (7510) - 已停止"
echo "├── ❌ 简历AI服务 (7511) - 已停止"
echo "├── ❌ 双AI协作管理器 - 已停止"
echo "├── ✅ MinerU服务 (8000) - Docker容器 (继续运行)"
echo "└── ✅ AI模型服务 (8002) - Docker容器 (继续运行)"
echo ""
echo "ℹ️  Docker AI服务 (MinerU和AI模型) 继续运行，如需要停止请手动执行:"
echo "   docker stop mineru-service ai-models-service"
