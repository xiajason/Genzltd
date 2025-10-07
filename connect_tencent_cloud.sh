#!/bin/bash

# 腾讯云服务器连接脚本
# 使用密码方式连接（如果SSH密钥不可用）

echo "🚀 连接腾讯云服务器进行Future版第5次重启测试"
echo "=== 服务器信息 ==="
echo "服务器IP: 101.33.251.158"
echo "用户名: ubuntu"
echo "测试时间: $(date)"

# 尝试使用SSH密钥连接
echo "🔑 尝试使用SSH密钥连接..."
ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ubuntu@101.33.251.158 << 'REMOTE_SCRIPT'
echo "✅ 成功连接到腾讯云服务器"
echo "📊 当前时间: $(date)"
echo "📁 当前目录: $(pwd)"
echo "🔍 检查Future版目录..."
ls -la /opt/jobfirst-multi-version/future/ 2>/dev/null || echo "Future版目录不存在"
echo "🐳 检查Docker容器状态..."
docker ps -a | grep future || echo "未找到Future版容器"
REMOTE_SCRIPT

if [ $? -ne 0 ]; then
    echo "❌ SSH密钥连接失败，请检查密钥文件或使用密码连接"
    echo "💡 建议："
    echo "1. 确保SSH密钥文件存在且权限正确"
    echo "2. 或者使用密码方式连接"
    echo "3. 检查服务器防火墙设置"
fi
