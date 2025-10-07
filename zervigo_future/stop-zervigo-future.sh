#!/bin/bash

# Zervigo Future版关闭脚本
# 功能: 停止Zervigo Future版所有服务
# 作者: AI Assistant
# 日期: 2025年9月28日

set -e

echo "🛑 停止 Zervigo Future版服务集群"
echo "=================================="

# 进入项目目录
cd "$(dirname "$0")"

echo "🛑 停止Zervigo Future版服务..."

# 停止所有服务进程
echo "📝 停止 Basic Server 1 (7520)..."
if [ -f "backend/logs/basic-server-1.pid" ]; then
    PID=$(cat backend/logs/basic-server-1.pid)
    if ps -p $PID > /dev/null 2>&1; then
        kill $PID
        echo "✅ Basic Server 1 已停止 (PID: $PID)"
    else
        echo "ℹ️  Basic Server 1 未运行"
    fi
    rm -f backend/logs/basic-server-1.pid
fi

echo "📝 停止 API Gateway (7521)..."
if [ -f "backend/logs/api-gateway.pid" ]; then
    PID=$(cat backend/logs/api-gateway.pid)
    if ps -p $PID > /dev/null 2>&1; then
        kill $PID
        echo "✅ API Gateway 已停止 (PID: $PID)"
    else
        echo "ℹ️  API Gateway 未运行"
    fi
    rm -f backend/logs/api-gateway.pid
fi

echo "📝 停止 User Service (7530)..."
if [ -f "backend/logs/user-service.pid" ]; then
    PID=$(cat backend/logs/user-service.pid)
    if ps -p $PID > /dev/null 2>&1; then
        kill $PID
        echo "✅ User Service 已停止 (PID: $PID)"
    else
        echo "ℹ️  User Service 未运行"
    fi
    rm -f backend/logs/user-service.pid
fi

echo "📝 停止 Basic Server 2 (7531)..."
if [ -f "backend/logs/basic-server-2.pid" ]; then
    PID=$(cat backend/logs/basic-server-2.pid)
    if ps -p $PID > /dev/null 2>&1; then
        kill $PID
        echo "✅ Basic Server 2 已停止 (PID: $PID)"
    else
        echo "ℹ️  Basic Server 2 未运行"
    fi
    rm -f backend/logs/basic-server-2.pid
fi

echo "📝 停止 Resume Service (7532)..."
if [ -f "backend/logs/resume-service.pid" ]; then
    PID=$(cat backend/logs/resume-service.pid)
    if ps -p $PID > /dev/null 2>&1; then
        kill $PID
        echo "✅ Resume Service 已停止 (PID: $PID)"
    else
        echo "ℹ️  Resume Service 未运行"
    fi
    rm -f backend/logs/resume-service.pid
fi

echo "📝 停止 Company Service (7534)..."
if [ -f "backend/logs/company-service.pid" ]; then
    PID=$(cat backend/logs/company-service.pid)
    if ps -p $PID > /dev/null 2>&1; then
        kill $PID
        echo "✅ Company Service 已停止 (PID: $PID)"
    else
        echo "ℹ️  Company Service 未运行"
    fi
    rm -f backend/logs/company-service.pid
fi

echo "📝 停止 Job Service (7539)..."
if [ -f "backend/logs/job-service.pid" ]; then
    PID=$(cat backend/logs/job-service.pid)
    if ps -p $PID > /dev/null 2>&1; then
        kill $PID
        echo "✅ Job Service 已停止 (PID: $PID)"
    else
        echo "ℹ️  Job Service 未运行"
    fi
    rm -f backend/logs/job-service.pid
fi

echo "📝 停止 AI Service (7540)..."
if [ -f "logs/ai-service-proxy.pid" ]; then
    PID=$(cat logs/ai-service-proxy.pid)
    if ps -p $PID > /dev/null 2>&1; then
        kill $PID
        echo "✅ AI Service Proxy 已停止 (PID: $PID)"
    else
        echo "ℹ️  AI Service Proxy 未运行"
    fi
    rm -f logs/ai-service-proxy.pid
fi

echo ""
echo "🔨 强制停止所有相关进程..."
pkill -f "zervigo_future" || true
pkill -f "basic-server" || true
pkill -f "api-gateway" || true
pkill -f "user-service" || true
pkill -f "resume-service" || true
pkill -f "company-service" || true
pkill -f "job-service" || true
pkill -f "ai-service-proxy" || true

echo ""
echo "🧹 清理PID文件..."
rm -f backend/logs/*.pid
rm -f logs/*.pid

echo ""
echo "🔍 检查停止状态..."
echo "✅ Basic Server 1 (7520): $(curl -s http://localhost:7520/health 2>/dev/null | jq -r '.status // "stopped"' || echo 'stopped')"
echo "✅ API Gateway (7521): $(curl -s http://localhost:7521/health 2>/dev/null | jq -r '.status // "stopped"' || echo 'stopped')"
echo "✅ User Service (7530): $(curl -s http://localhost:7530/health 2>/dev/null | jq -r '.status // "stopped"' || echo 'stopped')"
echo "✅ Basic Server 2 (7531): $(curl -s http://localhost:7531/health 2>/dev/null | jq -r '.status // "stopped"' || echo 'stopped')"
echo "✅ Resume Service (7532): $(curl -s http://localhost:7532/health 2>/dev/null | jq -r '.status // "stopped"' || echo 'stopped')"
echo "✅ Company Service (7534): $(curl -s http://localhost:7534/health 2>/dev/null | jq -r '.status // "stopped"' || echo 'stopped')"
echo "✅ Job Service (7539): $(curl -s http://localhost:7539/health 2>/dev/null | jq -r '.status // "stopped"' || echo 'stopped')"
echo "✅ AI Service (7540): $(curl -s http://localhost:7540/health 2>/dev/null | jq -r '.status // "stopped"' || echo 'stopped')"

echo ""
echo "🎉 Zervigo Future版已完全停止！"
echo "=================================="
echo "📊 停止状态:"
echo "   - Basic Server 1 (7520): ✅ 已停止"
echo "   - API Gateway (7521): ✅ 已停止"
echo "   - User Service (7530): ✅ 已停止"
echo "   - Basic Server 2 (7531): ✅ 已停止"
echo "   - Resume Service (7532): ✅ 已停止"
echo "   - Company Service (7534): ✅ 已停止"
echo "   - Job Service (7539): ✅ 已停止"
echo "   - AI Service (7540): ✅ 已停止"
echo ""
echo "🚀 重新启动: ./start-zervigo-future.sh"
