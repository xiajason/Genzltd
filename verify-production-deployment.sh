#!/bin/bash

# 阿里云生产环境部署验证脚本

echo "✅ 验证阿里云生产环境部署"
echo "=========================="

# 检查Docker容器状态
echo "🔍 检查Docker容器状态..."
docker-compose ps
if [ $? -ne 0 ]; then
    echo "❌ Docker容器检查失败！"
    exit 1
fi
echo "✅ Docker容器运行正常。"

# 检查LoomaCRM主服务
echo "🔍 检查LoomaCRM主服务 (端口8800)..."
curl -s http://localhost:8800/health
if [ $? -ne 0 ]; then
    echo "❌ LoomaCRM主服务健康检查失败！"
    exit 1
fi
echo "✅ LoomaCRM主服务健康。"

# 检查Zervigo Future版API Gateway
echo "🔍 检查Zervigo Future版API Gateway (端口8200)..."
curl -s http://localhost:8200/health
if [ $? -ne 0 ]; then
    echo "❌ Zervigo Future版API Gateway健康检查失败！"
    exit 1
fi
echo "✅ Zervigo Future版API Gateway健康。"

# 检查Prometheus
echo "🔍 检查Prometheus (端口9090)..."
curl -s http://localhost:9090/api/v1/query?query=up
if [ $? -ne 0 ]; then
    echo "❌ Prometheus健康检查失败！"
    exit 1
fi
echo "✅ Prometheus运行正常。"

echo "🎉 阿里云生产环境部署验证成功！"
echo "================================"