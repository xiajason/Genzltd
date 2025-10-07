#!/bin/bash

# Template Service 启动脚本

echo "🚀 启动 Template Service..."
echo "================================"

# 设置工作目录
cd /Users/szjason72/zervi-basic/basic/backend/internal/template-service

# 检查端口是否被占用
if lsof -i :8085 > /dev/null 2>&1; then
    echo "⚠️  端口 8085 已被占用，正在尝试停止现有进程..."
    lsof -ti :8085 | xargs kill -9
    sleep 2
fi

# 编译服务
echo "📦 编译 Template Service..."
go build -o template-service main.go

if [ $? -ne 0 ]; then
    echo "❌ 编译失败"
    exit 1
fi

echo "✅ 编译成功"

# 启动服务
echo "🚀 启动 Template Service on port 8085..."
./template-service &

# 等待服务启动
sleep 3

# 检查服务是否启动成功
if curl -s http://localhost:8085/health > /dev/null; then
    echo "✅ Template Service 启动成功"
    echo "📍 服务地址: http://localhost:8085"
    echo "🔍 健康检查: http://localhost:8085/health"
    echo "📋 API文档: 请参考 MICROSERVICE_REFACTORING_PLAN.md"
    echo ""
    echo "🎯 主要功能："
    echo "  - 模板管理（创建、更新、删除）"
    echo "  - 模板搜索和筛选"
    echo "  - 模板评分系统"
    echo "  - 使用统计"
    echo "  - 热门模板推荐"
    echo ""
    echo "按 Ctrl+C 停止服务"
else
    echo "❌ Template Service 启动失败"
    exit 1
fi

# 保持脚本运行
wait
