#!/bin/bash

# 能力评估框架服务启动脚本
# 创建时间: 2025年10月3日
# 用途: 启动能力评估框架API服务

set -e

echo "🚀 启动能力评估框架API服务"
echo "================================"

# 设置环境变量
export PYTHONPATH="${PYTHONPATH}:$(pwd)/zervigo_future/ai-services"
export COMPETENCY_ASSESSMENT_PORT=8211
export COMPETENCY_ASSESSMENT_HOST=0.0.0.0

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
echo "🔍 检查端口 $COMPETENCY_ASSESSMENT_PORT..."
if lsof -Pi :$COMPETENCY_ASSESSMENT_PORT -sTCP:LISTEN -t >/dev/null; then
    echo "⚠️ 端口 $COMPETENCY_ASSESSMENT_PORT 已被占用"
    echo "正在尝试停止现有服务..."
    pkill -f "competency_assessment_api.py" || true
    sleep 2
    
    if lsof -Pi :$COMPETENCY_ASSESSMENT_PORT -sTCP:LISTEN -t >/dev/null; then
        echo "❌ 无法释放端口 $COMPETENCY_ASSESSMENT_PORT"
        exit 1
    fi
fi

echo "✅ 端口 $COMPETENCY_ASSESSMENT_PORT 可用"

# 创建日志目录
mkdir -p logs
echo "✅ 日志目录已创建"

# 启动能力评估框架API服务
echo "🚀 启动能力评估框架API服务..."
echo "   端口: $COMPETENCY_ASSESSMENT_PORT"
echo "   主机: $COMPETENCY_ASSESSMENT_HOST"
echo "   日志: logs/competency_assessment_api.log"

cd zervigo_future/ai-services

# 启动服务
nohup python3 competency_assessment_api.py > ../../logs/competency_assessment_api.log 2>&1 &
SERVICE_PID=$!

# 等待服务启动
echo "⏳ 等待服务启动..."
sleep 5

# 检查服务状态
if ps -p $SERVICE_PID > /dev/null; then
    echo "✅ 能力评估框架API服务启动成功 (PID: $SERVICE_PID)"
    
    # 测试服务健康状态
    echo "🔍 测试服务健康状态..."
    sleep 3
    
    if curl -s http://localhost:$COMPETENCY_ASSESSMENT_PORT/health > /dev/null; then
        echo "✅ 服务健康检查通过"
        
        # 显示服务信息
        echo ""
        echo "📋 服务信息:"
        echo "   API服务地址: http://localhost:$COMPETENCY_ASSESSMENT_PORT"
        echo "   健康检查: http://localhost:$COMPETENCY_ASSESSMENT_PORT/health"
        echo "   API文档: http://localhost:$COMPETENCY_ASSESSMENT_PORT/api/v1/competency/"
        echo "   进程ID: $SERVICE_PID"
        echo "   日志文件: logs/competency_assessment_api.log"
        echo ""
        echo "🎯 可用的API端点:"
        echo "   POST /api/v1/competency/assess_technical - 技术能力评估"
        echo "   POST /api/v1/competency/assess_business - 业务能力评估"
        echo "   POST /api/v1/competency/assess_comprehensive - 综合能力评估"
        echo "   POST /api/v1/competency/batch_assessment - 批量评估"
        echo "   GET  /api/v1/competency/competency_levels - 获取能力等级"
        echo "   GET  /api/v1/competency/technical_competency_types - 获取技术能力类型"
        echo "   GET  /api/v1/competency/business_competency_types - 获取业务能力类型"
        echo "   POST /api/v1/competency/benchmark - 基准对比"
        echo ""
        echo "🔧 测试命令:"
        echo "   python3 ../../test-competency-assessment-system.py"
        echo ""
        echo "🛑 停止服务:"
        echo "   kill $SERVICE_PID"
        echo "   或运行: ./stop-competency-assessment-service.sh"
        
    else
        echo "❌ 服务健康检查失败"
        echo "请检查日志: logs/competency_assessment_api.log"
        exit 1
    fi
    
else
    echo "❌ 能力评估框架API服务启动失败"
    echo "请检查日志: logs/competency_assessment_api.log"
    exit 1
fi

cd ../..

echo ""
echo "🎉 能力评估框架API服务启动完成！"
echo "现在可以运行测试脚本验证功能。"
