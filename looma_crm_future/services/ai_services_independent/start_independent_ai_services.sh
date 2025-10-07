#!/bin/bash

# JobFirst Future版独立AI服务启动脚本
# 实现完全独立的AI服务运行环境

echo "🚀 启动JobFirst Future版独立AI服务集群..."

# 设置环境变量
export AI_GATEWAY_HOST=0.0.0.0
export AI_GATEWAY_PORT=7510
export RESUME_AI_HOST=0.0.0.0
export RESUME_AI_PORT=7511
export REDIS_HOST=localhost:6382
export REDIS_DB=1
export REDIS_KEY_PREFIX="future:"
export DEBUG=False
export MAX_CONCURRENT_REQUESTS=10
export PROCESSING_TIMEOUT=300

# 检查虚拟环境
if [ ! -d "../venv" ]; then
    echo "❌ 虚拟环境不存在，请先创建虚拟环境"
    exit 1
fi

# 激活虚拟环境
echo "📦 激活Python虚拟环境..."
source ../venv/bin/activate

# 检查依赖服务
echo "🔍 检查依赖服务状态..."

# 检查MinerU服务
if curl -s http://localhost:8000/health > /dev/null; then
    echo "✅ MinerU服务 (8000) - 运行正常"
else
    echo "❌ MinerU服务 (8000) - 未运行"
    echo "请先启动Docker MinerU服务"
    exit 1
fi

# 检查AI模型服务
if curl -s http://localhost:8002/health > /dev/null; then
    echo "✅ AI模型服务 (8002) - 运行正常"
else
    echo "❌ AI模型服务 (8002) - 未运行"
    echo "请先启动Docker AI模型服务"
    exit 1
fi

# 检查Redis服务
if redis-cli -h localhost -p 6382 -a "looma_independent_password" -n 1 ping > /dev/null 2>&1; then
    echo "✅ Redis服务 (6382) - 运行正常"
else
    echo "❌ Redis服务 (6382) - 连接失败"
    exit 1
fi

# 创建日志目录
mkdir -p logs

# 启动AI网关服务
echo "🤖 启动Future版AI网关服务 (7510)..."
cd ai_gateway_future
nohup python ai_gateway_future.py > ../logs/ai_gateway.log 2>&1 &
AI_GATEWAY_PID=$!
echo $AI_GATEWAY_PID > ../logs/ai_gateway.pid
cd ..

# 等待AI网关启动
sleep 5

# 检查AI网关状态
if curl -s http://localhost:7510/health > /dev/null; then
    echo "✅ Future版AI网关服务 (7510) - 启动成功"
else
    echo "❌ Future版AI网关服务 (7510) - 启动失败"
    exit 1
fi

# 启动简历AI服务
echo "📄 启动Future版简历AI服务 (7511)..."
cd resume_ai_future
nohup python resume_ai_future.py > ../logs/resume_ai.log 2>&1 &
RESUME_AI_PID=$!
echo $RESUME_AI_PID > ../logs/resume_ai.pid
cd ..

# 等待简历AI服务启动
sleep 5

# 检查简历AI服务状态
if curl -s http://localhost:7511/health > /dev/null; then
    echo "✅ Future版简历AI服务 (7511) - 启动成功"
else
    echo "❌ Future版简历AI服务 (7511) - 启动失败"
    exit 1
fi

# 启动双AI协作管理器
echo "🔗 启动双AI协作管理器..."
cd dual_ai_services
nohup python dual_ai_collaboration_manager.py > ../logs/dual_ai_collaboration.log 2>&1 &
DUAL_AI_PID=$!
echo $DUAL_AI_PID > ../logs/dual_ai_collaboration.pid
cd ..

# 等待双AI协作管理器启动
sleep 3

echo ""
echo "🎉 Future版独立AI服务集群启动完成！"
echo ""
echo "📊 服务状态:"
echo "├── ✅ AI网关服务 (7510) - PID: $AI_GATEWAY_PID"
echo "├── ✅ 简历AI服务 (7511) - PID: $RESUME_AI_PID"
echo "├── ✅ 双AI协作管理器 - PID: $DUAL_AI_PID"
echo "├── ✅ MinerU服务 (8000) - Docker容器"
echo "└── ✅ AI模型服务 (8002) - Docker容器"
echo ""
echo "🔗 服务端点:"
echo "├── AI网关: http://localhost:7510/health"
echo "├── 简历AI: http://localhost:7511/health"
echo "├── AI网关路由: http://localhost:7510/api/v1/route"
echo "└── 简历分析: http://localhost:7511/api/v1/analyze"
echo ""
echo "📝 日志文件:"
echo "├── AI网关: logs/ai_gateway.log"
echo "├── 简历AI: logs/resume_ai.log"
echo "└── 双AI协作: logs/dual_ai_collaboration.log"
echo ""
echo "🛑 停止服务: ./stop_independent_ai_services.sh"
echo ""

# 保存PID到文件
echo "AI_GATEWAY_PID=$AI_GATEWAY_PID" > logs/ai_services.pids
echo "RESUME_AI_PID=$RESUME_AI_PID" >> logs/ai_services.pids
echo "DUAL_AI_PID=$DUAL_AI_PID" >> logs/ai_services.pids

echo "✅ 所有服务启动完成，PID已保存到 logs/ai_services.pids"
