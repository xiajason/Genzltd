#!/bin/bash

# DAO Genie 启动脚本
echo "🚀 启动 DAO Genie 积分制治理系统..."

# 检查Node.js版本
echo "📋 检查环境..."
node_version=$(node --version 2>/dev/null)
if [ $? -ne 0 ]; then
    echo "❌ Node.js 未安装，请先安装 Node.js"
    exit 1
fi
echo "✅ Node.js 版本: $node_version"

# 检查是否在正确的目录
if [ ! -f "package.json" ]; then
    echo "❌ 请在项目根目录运行此脚本"
    exit 1
fi

# 安装依赖
echo "📦 安装依赖..."
npm install

# 生成Prisma客户端
echo "🔧 生成Prisma客户端..."
npx prisma generate

# 推送数据库schema
echo "🗄️ 推送数据库schema..."
npx prisma db push

# 初始化测试数据
echo "🌱 初始化测试数据..."
npx tsx src/scripts/init-test-data.ts

# 启动开发服务器
echo "🎯 启动开发服务器..."
echo "📱 访问地址: http://localhost:3000"
echo "🔧 开发工具: http://localhost:3000/api/trpc"
echo ""
echo "✨ DAO Genie 已启动！"
echo "💡 功能包括:"
echo "   - 创建和参与DAO治理"
echo "   - 提案创建和投票"
echo "   - 积分制投票权重"
echo "   - 实时数据同步"
echo ""

npm run dev