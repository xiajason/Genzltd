#!/bin/bash

echo "🚀 启动Future版简历上传服务..."

# 检查端口是否被占用
if lsof -Pi :7520 -sTCP:LISTEN -t >/dev/null ; then
    echo "❌ 端口7520已被占用"
    echo "正在停止占用端口的进程..."
    lsof -ti:7520 | xargs kill -9
    sleep 2
fi

# 进入服务目录
cd services/api_services/resume_upload_api

# 检查Python环境
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3未安装"
    exit 1
fi

# 安装依赖
echo "📦 安装依赖..."
pip3 install -r requirements.txt

# 启动服务
echo "🔧 启动简历上传服务..."
nohup python3 resume_upload_service.py > logs/resume_upload_service.log 2>&1 &
PID=$!

echo "✅ 简历上传服务已启动"
echo "📍 PID: $PID"
echo "📍 服务地址: http://localhost:7520"
echo "📍 健康检查: http://localhost:7520/health"
echo "📍 上传接口: http://localhost:7520/api/v1/upload"
echo "📍 日志文件: logs/resume_upload_service.log"

# 等待服务启动
sleep 3

# 检查服务状态
if curl -s http://localhost:7520/health > /dev/null; then
    echo "🎉 服务启动成功！"
else
    echo "❌ 服务启动失败，请检查日志"
fi
