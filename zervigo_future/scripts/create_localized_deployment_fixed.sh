#!/bin/bash
set -e

# 增强的错误处理函数
error_exit() {
    echo "❌ 错误: $1" >&2
    echo "当前工作目录: $(pwd)"
    echo "当前用户: $(whoami)"
    echo "环境变量:"
    env | grep -E "(PWD|HOME|PATH|GITHUB)" || true
    echo "目录内容:"
    ls -la || true
    exit 1
}

# 捕获错误
trap 'error_exit "脚本执行失败，退出码: $?"' ERR

echo "🎯 创建本地化部署包 (修复版本)"
echo "================================"
echo "开始时间: $(date)"
echo "当前工作目录: $(pwd)"
echo "当前用户: $(whoami)"

# 验证环境
echo ""
echo "🔍 环境验证:"
if [ -z "$PWD" ]; then
    error_exit "PWD环境变量未设置"
fi

if [ ! -w "." ]; then
    error_exit "当前目录不可写"
fi

# 设置变量
DEPLOYMENT_DIR="localized-deployment"
AI_SERVICE_DIR="$DEPLOYMENT_DIR/ai-service"
SCRIPTS_DIR="$DEPLOYMENT_DIR/scripts"

echo ""
echo "📋 配置信息:"
echo "  - DEPLOYMENT_DIR: $DEPLOYMENT_DIR"
echo "  - AI_SERVICE_DIR: $AI_SERVICE_DIR"
echo "  - SCRIPTS_DIR: $SCRIPTS_DIR"

# 清理旧的部署包
echo ""
echo "🧹 清理旧的部署包..."
if [ -d "$DEPLOYMENT_DIR" ]; then
    echo "删除旧的部署包目录: $DEPLOYMENT_DIR"
    rm -rf "$DEPLOYMENT_DIR"
fi

# 创建目录结构
echo ""
echo "📁 创建目录结构..."
echo "创建部署包根目录: $DEPLOYMENT_DIR"
if ! mkdir -p "$DEPLOYMENT_DIR"; then
    error_exit "无法创建部署包根目录"
fi

echo "创建AI服务目录: $AI_SERVICE_DIR"
if ! mkdir -p "$AI_SERVICE_DIR"; then
    error_exit "无法创建AI服务目录"
fi

echo "创建脚本目录: $SCRIPTS_DIR"
if ! mkdir -p "$SCRIPTS_DIR"; then
    error_exit "无法创建脚本目录"
fi

# 验证目录创建
echo ""
echo "✅ 验证目录创建:"
echo "部署包根目录:"
ls -la "$DEPLOYMENT_DIR/" || error_exit "部署包根目录不存在"

echo "AI服务目录:"
ls -la "$AI_SERVICE_DIR/" || error_exit "AI服务目录不存在"

echo "脚本目录:"
ls -la "$SCRIPTS_DIR/" || error_exit "脚本目录不存在"

# 创建AI服务组件
echo ""
echo "🤖 创建AI服务组件..."

# 创建AI服务主文件
echo "创建AI服务主文件: $AI_SERVICE_DIR/main.py"
cat > "$AI_SERVICE_DIR/main.py" << 'EOF'
#!/usr/bin/env python3
"""
简化的AI服务 - 本地化版本
基于成功经验的轻量级AI服务实现
"""

from flask import Flask, request, jsonify
import json
import os
import logging
import sys
from datetime import datetime

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

app = Flask(__name__)

@app.route('/health', methods=['GET'])
def health_check():
    """健康检查端点"""
    return jsonify({
        "status": "healthy",
        "service": "ai-service-localized",
        "version": "1.0.0",
        "message": "AI服务运行正常",
        "timestamp": str(datetime.now())
    })

@app.route('/process', methods=['POST'])
def process_request():
    """处理AI请求"""
    try:
        data = request.get_json()
        if not data:
            return jsonify({"error": "无效的请求数据"}), 400
        
        # 简单的AI处理逻辑
        text = data.get('text', '')
        result = {
            "input": text,
            "processed": f"AI处理结果: {text[:50]}...",
            "confidence": 0.95,
            "status": "success",
            "timestamp": str(datetime.now())
        }
        
        logger.info(f"处理AI请求: {text[:20]}...")
        return jsonify(result)
        
    except Exception as e:
        logger.error(f"AI请求处理失败: {e}")
        return jsonify({
            "error": "AI请求处理失败",
            "message": str(e),
            "status": "error"
        }), 500

@app.route('/status', methods=['GET'])
def get_status():
    """获取服务状态"""
    return jsonify({
        "service": "ai-service-localized",
        "status": "running",
        "uptime": "unknown",
        "version": "1.0.0"
    })

if __name__ == '__main__':
    logger.info("启动AI服务...")
    app.run(host='0.0.0.0', port=8206, debug=False)
EOF

# 创建requirements.txt
echo "创建requirements.txt: $AI_SERVICE_DIR/requirements.txt"
cat > "$AI_SERVICE_DIR/requirements.txt" << 'EOF'
flask==2.3.3
pandas==2.0.3
requests==2.31.0
python-dotenv==1.0.0
EOF

# 创建启动脚本
echo "创建启动脚本: $AI_SERVICE_DIR/start_ai_service.sh"
cat > "$AI_SERVICE_DIR/start_ai_service.sh" << 'EOF'
#!/bin/bash
set -e

echo "🚀 启动AI服务 (本地化版本)"
echo "=========================="

# 检查Python环境
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 未安装"
    exit 1
fi

# 创建虚拟环境
if [ ! -d "venv" ]; then
    echo "创建Python虚拟环境..."
    python3 -m venv venv
fi

# 激活虚拟环境
echo "激活虚拟环境..."
source venv/bin/activate

# 安装依赖
echo "安装Python依赖..."
pip install --upgrade pip
pip install -r requirements.txt

# 启动服务
echo "启动AI服务..."
python main.py
EOF

chmod +x "$AI_SERVICE_DIR/start_ai_service.sh"

# 创建部署脚本
echo "创建部署脚本: $SCRIPTS_DIR/deploy_ai_service.sh"
cat > "$SCRIPTS_DIR/deploy_ai_service.sh" << 'EOF'
#!/bin/bash
set -e

echo "📦 部署AI服务到阿里云"
echo "===================="

# 设置变量
AI_SERVICE_DIR="/opt/zervigo/ai-service"
SERVICE_USER="root"

# 创建服务目录
echo "创建服务目录: $AI_SERVICE_DIR"
mkdir -p "$AI_SERVICE_DIR"

# 复制文件
echo "复制AI服务文件..."
cp -r ai-service/* "$AI_SERVICE_DIR/"

# 设置权限
echo "设置文件权限..."
chmod +x "$AI_SERVICE_DIR/start_ai_service.sh"
chown -R "$SERVICE_USER:$SERVICE_USER" "$AI_SERVICE_DIR"

# 创建systemd服务文件
echo "创建systemd服务文件..."
cat > /etc/systemd/system/ai-service-localized.service << 'SERVICE_EOF'
[Unit]
Description=AI Service Localized
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/zervigo/ai-service
ExecStart=/opt/zervigo/ai-service/start_ai_service.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
SERVICE_EOF

# 重载systemd并启动服务
echo "启动AI服务..."
systemctl daemon-reload
systemctl enable ai-service-localized
systemctl start ai-service-localized

echo "✅ AI服务部署完成"
systemctl status ai-service-localized --no-pager
EOF

chmod +x "$SCRIPTS_DIR/deploy_ai_service.sh"

# 创建部署清单
echo "创建部署清单: $DEPLOYMENT_DIR/deployment_manifest.txt"
cat > "$DEPLOYMENT_DIR/deployment_manifest.txt" << EOF
本地化部署包清单
================
创建时间: $(date)
创建用户: $(whoami)
工作目录: $(pwd)

包含组件:
1. AI服务主文件 (main.py)
2. Python依赖文件 (requirements.txt)
3. 启动脚本 (start_ai_service.sh)
4. 部署脚本 (deploy_ai_service.sh)

文件结构:
$DEPLOYMENT_DIR/
├── ai-service/
│   ├── main.py
│   ├── requirements.txt
│   └── start_ai_service.sh
├── scripts/
│   └── deploy_ai_service.sh
└── deployment_manifest.txt

部署说明:
1. 将整个部署包上传到目标服务器
2. 执行 scripts/deploy_ai_service.sh 进行部署
3. 服务将在端口8206上运行
4. 健康检查端点: /health
5. AI处理端点: /process
EOF

# 最终验证
echo ""
echo "🔍 最终验证:"
echo "检查部署包结构:"
find "$DEPLOYMENT_DIR" -type f -exec ls -la {} \;

echo ""
echo "检查文件内容:"
echo "AI服务主文件大小: $(wc -l < "$AI_SERVICE_DIR/main.py") 行"
echo "requirements.txt内容:"
cat "$AI_SERVICE_DIR/requirements.txt"

echo ""
echo "检查脚本权限:"
ls -la "$AI_SERVICE_DIR/start_ai_service.sh"
ls -la "$SCRIPTS_DIR/deploy_ai_service.sh"

echo ""
echo "✅ 本地化部署包创建完成！"
echo "部署包位置: $DEPLOYMENT_DIR"
echo "包含文件数: $(find "$DEPLOYMENT_DIR" -type f | wc -l)"
echo "总大小: $(du -sh "$DEPLOYMENT_DIR" | cut -f1)"
echo "完成时间: $(date)"
