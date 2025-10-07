#!/bin/bash

echo "🐍 激活Looma CRM AI重构虚拟环境"
echo "================================"

# 检查虚拟环境是否存在
if [ ! -d "venv" ]; then
    echo "❌ 虚拟环境不存在，正在创建..."
    python3 -m venv venv
    echo "✅ 虚拟环境创建完成"
fi

# 激活虚拟环境
echo "🔄 激活虚拟环境..."
source venv/bin/activate

# 检查核心依赖
echo "🔍 检查核心依赖..."
python3 -c "
import sys
try:
    import sanic, sqlalchemy, asyncpg, redis, neo4j, weaviate, elasticsearch
    print('✅ 所有核心依赖已安装')
except ImportError as e:
    print(f'❌ 缺少依赖: {e}')
    print('请运行: pip install -r requirements-core.txt')
    sys.exit(1)
"

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 虚拟环境激活成功！"
    echo "📋 可用命令："
    echo "  python looma_crm/app.py          # 启动Looma CRM"
    echo "  python -m pytest tests/          # 运行测试"
    echo "  pip install -r requirements-core.txt  # 安装核心依赖"
    echo ""
    echo "💡 提示：使用 'deactivate' 退出虚拟环境"
else
    echo "❌ 虚拟环境激活失败"
    exit 1
fi
