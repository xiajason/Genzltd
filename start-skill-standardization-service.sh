#!/bin/bash

# 技能标准化服务启动脚本
# 创建时间: 2025年10月3日
# 用途: 启动技能标准化API服务

set -e

echo "🚀 启动技能标准化API服务"
echo "================================"

# 设置环境变量
export PYTHONPATH="${PYTHONPATH}:$(pwd)/zervigo_future/ai-services"
export SKILL_STANDARDIZATION_PORT=8209
export SKILL_STANDARDIZATION_HOST=0.0.0.0

# 检查Python环境
echo "🔍 检查Python环境..."
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 未安装"
    exit 1
fi

echo "✅ Python3 版本: $(python3 --version)"

# 检查必要的Python包
echo "🔍 检查Python依赖..."
required_packages=("sanic" "structlog" "aiohttp" "asyncio")
for package in "${required_packages[@]}"; do
    if ! python3 -c "import $package" 2>/dev/null; then
        echo "❌ 缺少Python包: $package"
        echo "请运行: pip3 install $package"
        exit 1
    fi
done

echo "✅ 所有Python依赖已安装"

# 检查端口是否被占用
echo "🔍 检查端口 $SKILL_STANDARDIZATION_PORT..."
if lsof -Pi :$SKILL_STANDARDIZATION_PORT -sTCP:LISTEN -t >/dev/null; then
    echo "⚠️ 端口 $SKILL_STANDARDIZATION_PORT 已被占用"
    echo "正在尝试停止现有服务..."
    pkill -f "skill_standardization_api.py" || true
    sleep 2
    
    if lsof -Pi :$SKILL_STANDARDIZATION_PORT -sTCP:LISTEN -t >/dev/null; then
        echo "❌ 无法释放端口 $SKILL_STANDARDIZATION_PORT"
        exit 1
    fi
fi

echo "✅ 端口 $SKILL_STANDARDIZATION_PORT 可用"

# 创建日志目录
mkdir -p logs
echo "✅ 日志目录已创建"

# 启动技能标准化API服务
echo "🚀 启动技能标准化API服务..."
echo "   端口: $SKILL_STANDARDIZATION_PORT"
echo "   主机: $SKILL_STANDARDIZATION_HOST"
echo "   日志: logs/skill_standardization_api.log"

cd zervigo_future/ai-services

# 启动服务
nohup python3 skill_standardization_api.py > ../../logs/skill_standardization_api.log 2>&1 &
SERVICE_PID=$!

# 等待服务启动
echo "⏳ 等待服务启动..."
sleep 5

# 检查服务状态
if ps -p $SERVICE_PID > /dev/null; then
    echo "✅ 技能标准化API服务启动成功 (PID: $SERVICE_PID)"
    
    # 测试服务健康状态
    echo "🔍 测试服务健康状态..."
    sleep 3
    
    if curl -s http://localhost:$SKILL_STANDARDIZATION_PORT/health > /dev/null; then
        echo "✅ 服务健康检查通过"
        
        # 显示服务信息
        echo ""
        echo "📋 服务信息:"
        echo "   API服务地址: http://localhost:$SKILL_STANDARDIZATION_PORT"
        echo "   健康检查: http://localhost:$SKILL_STANDARDIZATION_PORT/health"
        echo "   API文档: http://localhost:$SKILL_STANDARDIZATION_PORT/api/v1/skills/"
        echo "   进程ID: $SERVICE_PID"
        echo "   日志文件: logs/skill_standardization_api.log"
        echo ""
        echo "🎯 可用的API端点:"
        echo "   POST /api/v1/skills/standardize - 技能标准化"
        echo "   POST /api/v1/skills/batch_standardize - 批量技能标准化"
        echo "   POST /api/v1/skills/calculate_level - 计算技能等级"
        echo "   POST /api/v1/skills/match - 技能匹配"
        echo "   GET  /api/v1/skills/search - 搜索技能"
        echo "   GET  /api/v1/skills/categories - 获取技能分类"
        echo "   GET  /api/v1/skills/stats - 获取技能统计"
        echo "   POST /api/v1/skills/recommend - 技能推荐"
        echo ""
        echo "🔧 测试命令:"
        echo "   python3 ../../test-skill-standardization-system.py"
        echo ""
        echo "🛑 停止服务:"
        echo "   kill $SERVICE_PID"
        echo "   或运行: ./stop-skill-standardization-service.sh"
        
    else
        echo "❌ 服务健康检查失败"
        echo "请检查日志: logs/skill_standardization_api.log"
        exit 1
    fi
    
else
    echo "❌ 技能标准化API服务启动失败"
    echo "请检查日志: logs/skill_standardization_api.log"
    exit 1
fi

cd ../..

echo ""
echo "🎉 技能标准化API服务启动完成！"
echo "现在可以运行测试脚本验证功能。"
