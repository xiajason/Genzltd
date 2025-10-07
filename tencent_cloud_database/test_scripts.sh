#!/bin/bash

# 脚本测试脚本
# 用于验证所有脚本的语法和逻辑

echo "🧪 开始测试腾讯云数据库脚本..."

# 测试simple_download.sh语法
echo "📝 测试 simple_download.sh 语法..."
if bash -n simple_download.sh; then
    echo "✅ simple_download.sh 语法正确"
else
    echo "❌ simple_download.sh 语法错误"
fi

# 测试download_database_images.sh语法
echo "📝 测试 download_database_images.sh 语法..."
if bash -n download_database_images.sh; then
    echo "✅ download_database_images.sh 语法正确"
else
    echo "❌ download_database_images.sh 语法错误"
fi

# 测试deploy_to_tencent.sh语法
echo "📝 测试 deploy_to_tencent.sh 语法..."
if bash -n deploy_to_tencent.sh; then
    echo "✅ deploy_to_tencent.sh 语法正确"
else
    echo "❌ deploy_to_tencent.sh 语法错误"
fi

# 检查目录结构
echo "📁 检查目录结构..."
if [ -d "future" ] && [ -d "dao" ] && [ -d "blockchain" ]; then
    echo "✅ 目录结构正确"
else
    echo "⚠️  目录结构不完整，运行脚本时会自动创建"
fi

# 检查脚本权限
echo "🔐 检查脚本权限..."
for script in simple_download.sh download_database_images.sh deploy_to_tencent.sh; do
    if [ -x "$script" ]; then
        echo "✅ $script 有执行权限"
    else
        echo "⚠️  $script 没有执行权限，正在修复..."
        chmod +x "$script"
    fi
done

echo "🎯 脚本测试完成！"
echo ""
echo "📋 可用命令:"
echo "  ./simple_download.sh              # 下载数据库镜像"
echo "  ./download_database_images.sh     # 完整下载脚本"
echo "  ./deploy_to_tencent.sh future     # 部署Future版"
echo "  ./deploy_to_tencent.sh dao        # 部署DAO版"
echo "  ./deploy_to_tencent.sh blockchain # 部署区块链版"
