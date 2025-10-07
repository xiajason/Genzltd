#!/bin/bash
# 腾讯云Future版停止脚本

echo "🛑 停止腾讯云Future版服务..."

cd /opt/future-deployment

# 停止所有服务
echo "🛑 停止所有服务..."
docker-compose down

echo "✅ 腾讯云Future版服务已停止！"
