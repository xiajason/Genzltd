#!/bin/bash

# 阿里云生产环境监控系统设置脚本

echo "📊 设置阿里云生产环境监控系统"
echo "================================"

# 确保在正确的目录
cd /opt/production/monitoring || { echo "Error: /opt/production/monitoring directory not found."; exit 1; }

echo "📦 启动Prometheus和Grafana..."
docker-compose up -d

echo "⏳ 等待监控服务启动..."
sleep 15

echo "🔍 检查监控服务状态..."
docker-compose ps

echo "✅ 监控系统启动完成！"
echo "======================"
echo "Prometheus: http://[阿里云IP]:9090"
echo "Grafana: http://[阿里云IP]:3000 (admin/admin)"
echo "请确保安全组已开放相应端口。"