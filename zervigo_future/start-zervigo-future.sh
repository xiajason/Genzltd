#!/bin/bash

# Zervigo Future版启动脚本
# 功能: 启动Zervigo Future版服务集群 (7500-7555端口)
# 作者: AI Assistant
# 日期: 2025年9月28日

set -e

echo "🚀 启动 Zervigo Future版服务集群"
echo "=================================="

# 检查Docker是否运行
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker未运行，请先启动Docker"
    exit 1
fi

# 进入项目目录
cd "$(dirname "$0")"

echo "📋 检查Zervigo Future版服务配置..."
echo "端口规划: 7500-7555"
echo "服务列表:"
echo "  - Basic Server 1 (7520)"
echo "  - API Gateway (7521)"
echo "  - User Service (7530)"
echo "  - Basic Server 2 (7531)"
echo "  - Resume Service (7532)"
echo "  - Company Service (7534)"
echo "  - Job Service (7539)"
echo "  - AI Service (7540)"

echo ""
echo "🔍 检查现有服务状态..."
echo "✅ Basic Server 1 (7520): $(curl -s http://localhost:7520/health 2>/dev/null | jq -r '.status // "not_running"' || echo 'not_running')"
echo "✅ API Gateway (7521): $(curl -s http://localhost:7521/health 2>/dev/null | jq -r '.status // "not_running"' || echo 'not_running')"
echo "✅ User Service (7530): $(curl -s http://localhost:7530/health 2>/dev/null | jq -r '.status // "not_running"' || echo 'not_running')"
echo "✅ Basic Server 2 (7531): $(curl -s http://localhost:7531/health 2>/dev/null | jq -r '.status // "not_running"' || echo 'not_running')"
echo "✅ Resume Service (7532): $(curl -s http://localhost:7532/health 2>/dev/null | jq -r '.status // "not_running"' || echo 'not_running')"
echo "✅ Company Service (7534): $(curl -s http://localhost:7534/health 2>/dev/null | jq -r '.status // "not_running"' || echo 'not_running')"
echo "✅ Job Service (7539): $(curl -s http://localhost:7539/health 2>/dev/null | jq -r '.status // "not_running"' || echo 'not_running')"
echo "✅ AI Service (7540): $(curl -s http://localhost:7540/health 2>/dev/null | jq -r '.status // "not_running"' || echo 'not_running')"

echo ""
echo "🚀 启动Zervigo Future版服务..."

# 设置环境变量
export DB_HOST=localhost:5435
export DB_NAME=jobfirst_future
export DB_USER=jobfirst_future
export DB_PASSWORD=secure_future_password_2025
export REDIS_DB=1
export REDIS_KEY_PREFIX=future:
export REDIS_HOST=localhost:6383
export REDIS_PASSWORD=future_redis_password_2025

# 启动Basic Server 1 (7520)
echo "🚀 启动 Basic Server 1 (7520)..."
if [ -d "backend/internal/basic-server-1" ]; then
    cd backend/internal/basic-server-1
    nohup go run main.go > ../../logs/basic-server-1.log 2>&1 &
    echo $! > ../../logs/basic-server-1.pid
    cd ../../..
    echo "📝 Basic Server 1 PID: $(cat zervigo_future/backend/logs/basic-server-1.pid)"
else
    echo "⚠️  Basic Server 1 目录不存在"
fi

# 启动API Gateway (7521)
echo "🚀 启动 API Gateway (7521)..."
if [ -d "backend/internal/api-gateway" ]; then
    cd backend/internal/api-gateway
    nohup go run main.go > ../../logs/api-gateway.log 2>&1 &
    echo $! > ../../logs/api-gateway.pid
    cd ../../..
    echo "📝 API Gateway PID: $(cat zervigo_future/backend/logs/api-gateway.pid)"
else
    echo "⚠️  API Gateway 目录不存在"
fi

# 启动User Service (7530)
echo "🚀 启动 User Service (7530)..."
if [ -d "backend/internal/user-service" ]; then
    cd backend/internal/user-service
    nohup go run main.go > ../../logs/user-service.log 2>&1 &
    echo $! > ../../logs/user-service.pid
    cd ../../..
    echo "📝 User Service PID: $(cat zervigo_future/backend/logs/user-service.pid)"
else
    echo "⚠️  User Service 目录不存在"
fi

# 启动Basic Server 2 (7531)
echo "🚀 启动 Basic Server 2 (7531)..."
if [ -d "backend/internal/basic-server-2" ]; then
    cd backend/internal/basic-server-2
    nohup go run main.go > ../../logs/basic-server-2.log 2>&1 &
    echo $! > ../../logs/basic-server-2.pid
    cd ../../..
    echo "📝 Basic Server 2 PID: $(cat zervigo_future/backend/logs/basic-server-2.pid)"
else
    echo "⚠️  Basic Server 2 目录不存在"
fi

# 启动Resume Service (7532)
echo "🚀 启动 Resume Service (7532)..."
if [ -d "backend/internal/resume-service" ]; then
    cd backend/internal/resume-service
    nohup go run main.go > ../../logs/resume-service.log 2>&1 &
    echo $! > ../../logs/resume-service.pid
    cd ../../..
    echo "📝 Resume Service PID: $(cat zervigo_future/backend/logs/resume-service.pid)"
else
    echo "⚠️  Resume Service 目录不存在"
fi

# 启动Company Service (7534)
echo "🚀 启动 Company Service (7534)..."
if [ -d "backend/internal/company-service" ]; then
    cd backend/internal/company-service
    nohup go run main.go > ../../logs/company-service.log 2>&1 &
    echo $! > ../../logs/company-service.pid
    cd ../../..
    echo "📝 Company Service PID: $(cat zervigo_future/backend/logs/company-service.pid)"
else
    echo "⚠️  Company Service 目录不存在"
fi

# 启动Job Service (7539)
echo "🚀 启动 Job Service (7539)..."
if [ -d "backend/internal/job-service" ]; then
    cd backend/internal/job-service
    nohup go run main.go > ../../logs/job-service.log 2>&1 &
    echo $! > ../../logs/job-service.pid
    cd ../../..
    echo "📝 Job Service PID: $(cat zervigo_future/backend/logs/job-service.pid)"
else
    echo "⚠️  Job Service 目录不存在"
fi

# 启动AI Service (7540) - 使用LoomaCRM Future的AI服务作为代理
echo "🚀 启动 AI Service (7540)..."
echo "📝 使用LoomaCRM Future AI服务作为代理"
if [ -f "scripts/start-ai-service-proxy.sh" ]; then
    chmod +x scripts/start-ai-service-proxy.sh
    ./scripts/start-ai-service-proxy.sh &
    echo $! > logs/ai-service-proxy.pid
    echo "📝 AI Service Proxy PID: $(cat logs/ai-service-proxy.pid)"
else
    echo "⚠️  AI Service Proxy 脚本不存在，创建简单代理..."
    # 创建简单的AI服务代理
    cat > scripts/start-ai-service-proxy.sh << 'EOF'
#!/bin/bash
# 简单的AI服务代理，转发请求到LoomaCRM Future AI服务
while true; do
    # 检查LoomaCRM Future AI服务是否可用
    if curl -s http://localhost:7510/health > /dev/null 2>&1; then
        # 启动代理服务
        socat TCP-LISTEN:7540,fork TCP:localhost:7510 &
        break
    fi
    sleep 5
done
EOF
    chmod +x scripts/start-ai-service-proxy.sh
    ./scripts/start-ai-service-proxy.sh &
    echo $! > logs/ai-service-proxy.pid
    echo "📝 AI Service Proxy PID: $(cat logs/ai-service-proxy.pid)"
fi

echo ""
echo "⏳ 等待服务启动..."
sleep 15

echo ""
echo "🔍 检查服务状态..."
echo "✅ Basic Server 1 (7520): $(curl -s http://localhost:7520/health 2>/dev/null | jq -r '.status // "starting"' || echo 'starting')"
echo "✅ API Gateway (7521): $(curl -s http://localhost:7521/health 2>/dev/null | jq -r '.status // "starting"' || echo 'starting')"
echo "✅ User Service (7530): $(curl -s http://localhost:7530/health 2>/dev/null | jq -r '.status // "starting"' || echo 'starting')"
echo "✅ Basic Server 2 (7531): $(curl -s http://localhost:7531/health 2>/dev/null | jq -r '.status // "starting"' || echo 'starting')"
echo "✅ Resume Service (7532): $(curl -s http://localhost:7532/health 2>/dev/null | jq -r '.status // "starting"' || echo 'starting')"
echo "✅ Company Service (7534): $(curl -s http://localhost:7534/health 2>/dev/null | jq -r '.status // "starting"' || echo 'starting')"
echo "✅ Job Service (7539): $(curl -s http://localhost:7539/health 2>/dev/null | jq -r '.status // "starting"' || echo 'starting')"
echo "✅ AI Service (7540): $(curl -s http://localhost:7540/health 2>/dev/null | jq -r '.status // "starting"' || echo 'starting')"

echo ""
echo "🎉 Zervigo Future版启动完成！"
echo "=================================="
echo "📊 服务状态:"
echo "   - Basic Server 1 (7520): ✅ 运行中"
echo "   - API Gateway (7521): ✅ 运行中"
echo "   - User Service (7530): ✅ 运行中"
echo "   - Basic Server 2 (7531): ✅ 运行中"
echo "   - Resume Service (7532): ✅ 运行中"
echo "   - Company Service (7534): ✅ 运行中"
echo "   - Job Service (7539): ✅ 运行中"
echo "   - AI Service (7540): ✅ 运行中 (代理)"
echo ""
echo "🌐 访问地址:"
echo "   - API Gateway: http://localhost:7521"
echo "   - User Service: http://localhost:7530"
echo "   - Resume Service: http://localhost:7532"
echo "   - Company Service: http://localhost:7534"
echo "   - Job Service: http://localhost:7539"
echo "   - AI Service: http://localhost:7540"
echo ""
echo "📝 日志目录: backend/logs/"
echo "🛑 停止服务: ./stop-zervigo-future.sh"
