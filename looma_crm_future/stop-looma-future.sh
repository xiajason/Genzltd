#!/bin/bash

# LoomaCRM Future版关闭脚本
# 功能: 停止Future版所有服务
# 作者: AI Assistant
# 日期: 2025年9月28日

set -e

echo "🛑 停止 LoomaCRM Future版服务集群"
echo "=================================="

# 进入项目目录
cd "$(dirname "$0")"

echo "🛑 停止LoomaCRM Future主服务..."
if [ -f "looma-future.pid" ]; then
    LOOMA_PID=$(cat looma-future.pid)
    if ps -p $LOOMA_PID > /dev/null 2>&1; then
        echo "📝 停止LoomaCRM Future进程 (PID: $LOOMA_PID)"
        kill $LOOMA_PID
        sleep 5
        
        # 强制停止如果还在运行
        if ps -p $LOOMA_PID > /dev/null 2>&1; then
            echo "🔨 强制停止LoomaCRM Future进程"
            kill -9 $LOOMA_PID
        fi
    else
        echo "ℹ️  LoomaCRM Future进程未运行"
    fi
    rm -f looma-future.pid
else
    echo "ℹ️  未找到PID文件，尝试停止所有相关进程"
    pkill -f "looma_crm_future" || true
fi

echo ""
echo "🤖 停止Future版AI服务..."
if [ -d "ai_services_independent" ]; then
    cd ai_services_independent
    
    if [ -f "stop_independent_ai_services.sh" ]; then
        echo "🛑 停止独立AI服务..."
        chmod +x stop_independent_ai_services.sh
        ./stop_independent_ai_services.sh
    else
        echo "⚠️  AI服务停止脚本不存在，手动停止相关进程"
        pkill -f "ai_gateway_future" || true
        pkill -f "resume_ai_future" || true
    fi
    
    cd ..
else
    echo "⚠️  AI服务目录不存在，跳过AI服务停止"
fi

echo ""
echo "📦 停止Future版数据库集群..."
docker-compose -f config/docker-compose-future-ports.yml down

echo ""
echo "🧹 清理资源..."

# 停止所有Future版相关容器
echo "🛑 停止所有Future版容器..."
docker stop $(docker ps -aq --filter "name=future-") 2>/dev/null || true

# 清理未使用的容器
echo "🗑️  清理未使用的容器..."
docker container prune -f

echo ""
echo "🔍 检查停止状态..."
echo "✅ LoomaCRM Future (7500): $(curl -s http://localhost:7500/health 2>/dev/null | jq -r '.status // "stopped"' || echo 'stopped')"
echo "✅ AI网关 (7510): $(curl -s http://localhost:7510/health 2>/dev/null | jq -r '.status // "stopped"' || echo 'stopped')"
echo "✅ 简历AI (7511): $(curl -s http://localhost:7511/health 2>/dev/null | jq -r '.status // "stopped"' || echo 'stopped')"

echo ""
echo "🎉 LoomaCRM Future版已完全停止！"
echo "=================================="
echo "📊 停止状态:"
echo "   - 主服务: ✅ 已停止"
echo "   - AI服务: ✅ 已停止"
echo "   - 数据库集群: ✅ 已停止"
echo "   - 容器清理: ✅ 已完成"
echo ""
echo "🚀 重新启动: ./start-looma-future.sh"
