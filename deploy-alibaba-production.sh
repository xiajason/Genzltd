#!/bin/bash

# 阿里云生产环境部署脚本

echo "🚀 部署阿里云生产环境"
echo "======================"

# 确保在正确的目录
cd /opt/production || { echo "Error: /opt/production directory not found."; exit 1; }

# 停止并移除旧的Docker容器
echo "📦 停止并移除旧的Docker容器..."
docker-compose down --remove-orphans

# 拉取最新的Docker镜像 (如果使用私有仓库)
echo "⬇️ 拉取最新的Docker镜像..."
# docker pull your-registry/loomacrm-production:latest
# docker pull your-registry/zervigo-future-production:latest
# docker pull your-registry/zervigo-dao-production:latest
# docker pull your-registry/zervigo-blockchain-production:latest

# 启动新的Docker容器
echo "🚀 启动新的Docker容器..."
docker-compose up -d

echo "⏳ 等待服务启动..."
sleep 30 # 等待服务完全启动

echo "🔍 检查服务状态..."
docker-compose ps

echo "✅ 阿里云生产环境部署完成！"
echo "======================"
echo "请运行 './verify-production-deployment.sh' 进行最终验证。"