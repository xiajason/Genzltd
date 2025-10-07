#!/bin/bash

echo "🔍 SCP传输问题诊断脚本"
echo "====================="
echo ""

# 检查环境变量
echo "📋 检查环境变量："
echo "ALIBABA_CLOUD_SERVER_IP: ${ALIBABA_CLOUD_SERVER_IP:-未设置}"
echo "ALIBABA_CLOUD_SERVER_USER: ${ALIBABA_CLOUD_SERVER_USER:-未设置}"
echo "ALIBABA_CLOUD_DEPLOY_PATH: ${ALIBABA_CLOUD_DEPLOY_PATH:-未设置}"
echo ""

# 检查SSH密钥
echo "🔑 检查SSH密钥："
if [ -f "$HOME/.ssh/id_rsa" ]; then
    echo "✅ SSH私钥文件存在"
    ls -la "$HOME/.ssh/id_rsa"
else
    echo "❌ SSH私钥文件不存在"
fi

if [ -f "$HOME/.ssh/id_rsa.pub" ]; then
    echo "✅ SSH公钥文件存在"
    ls -la "$HOME/.ssh/id_rsa.pub"
else
    echo "❌ SSH公钥文件不存在"
fi
echo ""

# 检查部署包文件
echo "📦 检查部署包文件："
if [ -f "smart-deployment.tar.gz" ]; then
    echo "✅ 部署包文件存在"
    ls -la smart-deployment.tar.gz
    echo "文件大小："
    du -h smart-deployment.tar.gz
    echo "文件内容预览："
    tar -tzf smart-deployment.tar.gz | head -5
else
    echo "❌ 部署包文件不存在"
fi
echo ""

# 测试SSH连接
echo "🔌 测试SSH连接："
if [ -n "$ALIBABA_CLOUD_SERVER_IP" ] && [ -n "$ALIBABA_CLOUD_SERVER_USER" ]; then
    echo "尝试SSH连接测试..."
    ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no -i "$HOME/.ssh/id_rsa" "$ALIBABA_CLOUD_SERVER_USER@$ALIBABA_CLOUD_SERVER_IP" "echo 'SSH连接成功'; uname -a" || echo "SSH连接失败"
else
    echo "❌ SSH连接参数不完整"
fi
echo ""

# 测试SCP传输
echo "📤 测试SCP传输："
if [ -f "smart-deployment.tar.gz" ] && [ -n "$ALIBABA_CLOUD_SERVER_IP" ] && [ -n "$ALIBABA_CLOUD_SERVER_USER" ]; then
    echo "尝试SCP传输测试..."
    scp -o ConnectTimeout=10 -o StrictHostKeyChecking=no -i "$HOME/.ssh/id_rsa" smart-deployment.tar.gz "$ALIBABA_CLOUD_SERVER_USER@$ALIBABA_CLOUD_SERVER_IP:/tmp/test-deployment.tar.gz" || echo "SCP传输失败"
    
    # 验证文件是否传输成功
    echo "验证文件传输："
    ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no -i "$HOME/.ssh/id_rsa" "$ALIBABA_CLOUD_SERVER_USER@$ALIBABA_CLOUD_SERVER_IP" "ls -la /tmp/test-deployment.tar.gz && rm -f /tmp/test-deployment.tar.gz" || echo "文件验证失败"
else
    echo "❌ SCP传输参数不完整"
fi
echo ""

# 检查服务器状态
echo "🖥️ 检查服务器状态："
if [ -n "$ALIBABA_CLOUD_SERVER_IP" ] && [ -n "$ALIBABA_CLOUD_SERVER_USER" ]; then
    echo "检查服务器SSH服务状态："
    ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no -i "$HOME/.ssh/id_rsa" "$ALIBABA_CLOUD_SERVER_USER@$ALIBABA_CLOUD_SERVER_IP" "systemctl status sshd || systemctl status ssh || service sshd status || service ssh status" || echo "无法检查SSH服务状态"
    
    echo "检查服务器磁盘空间："
    ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no -i "$HOME/.ssh/id_rsa" "$ALIBABA_CLOUD_SERVER_USER@$ALIBABA_CLOUD_SERVER_IP" "df -h /tmp" || echo "无法检查磁盘空间"
    
    echo "检查服务器权限："
    ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no -i "$HOME/.ssh/id_rsa" "$ALIBABA_CLOUD_SERVER_USER@$ALIBABA_CLOUD_SERVER_IP" "ls -la /tmp && whoami && id" || echo "无法检查权限"
else
    echo "❌ 服务器连接参数不完整"
fi
echo ""

echo "✅ 诊断完成"
