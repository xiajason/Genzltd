#!/bin/bash
# 腾讯云Docker镜像打包脚本

echo "🚀 开始打包Docker镜像..."

# 创建打包目录
mkdir -p docker-images
cd docker-images

echo "📦 打包核心服务镜像 (PostgreSQL + Redis + Nginx)..."
docker save -o dao-core-services.tar postgres:15-alpine redis:7.2-alpine nginx:alpine

echo "📦 打包区块链服务镜像 (Node.js)..."
docker save -o blockchain-services.tar node:18-alpine

echo "🗜️ 压缩镜像文件..."
gzip dao-core-services.tar
gzip blockchain-services.tar

echo "📊 检查文件大小..."
ls -lh *.tar.gz

echo "✅ 镜像打包完成！"
echo ""
echo "文件列表:"
echo "  - dao-core-services.tar.gz (核心服务: PostgreSQL + Redis + Nginx)"
echo "  - blockchain-services.tar.gz (区块链服务: Node.js)"
echo ""
echo "下一步: 上传到腾讯云服务器"
