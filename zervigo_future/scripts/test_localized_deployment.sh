#!/bin/bash
set -e

echo "🧪 测试本地化部署包创建脚本"
echo "============================="
echo "当前工作目录: $(pwd)"
echo "当前用户: $(whoami)"

# 设置变量
DEPLOYMENT_DIR="localized-deployment"
AI_SERVICE_DIR="$DEPLOYMENT_DIR/ai-service"
SCRIPTS_DIR="$DEPLOYMENT_DIR/scripts"

echo "设置变量:"
echo "  - DEPLOYMENT_DIR: $DEPLOYMENT_DIR"
echo "  - AI_SERVICE_DIR: $AI_SERVICE_DIR"
echo "  - SCRIPTS_DIR: $SCRIPTS_DIR"

# 创建目录结构
echo "创建目录结构..."
mkdir -p "$AI_SERVICE_DIR"
mkdir -p "$SCRIPTS_DIR"
echo "目录创建完成，检查目录:"
ls -la "$DEPLOYMENT_DIR/" || echo "部署目录不存在"
ls -la "$AI_SERVICE_DIR/" || echo "AI服务目录不存在"
ls -la "$SCRIPTS_DIR/" || echo "脚本目录不存在"

# 创建简单的测试文件
echo "创建测试文件..."
echo "test content" > "$AI_SERVICE_DIR/test.txt"
echo "test script" > "$SCRIPTS_DIR/test.sh"
chmod +x "$SCRIPTS_DIR/test.sh"

echo "检查创建的文件:"
ls -la "$AI_SERVICE_DIR/"
ls -la "$SCRIPTS_DIR/"

echo "✅ 测试脚本执行完成"
