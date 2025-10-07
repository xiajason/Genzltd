#!/bin/bash
# AI身份社交网络停止脚本

echo "🛑 停止AI身份社交网络..."
echo "=========================="

# 停止进程函数
stop_process() {
    local name=$1
    local pid_file=$2
    
    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            echo "🛑 停止 $name (PID: $pid)..."
            kill "$pid"
            sleep 2
            
            # 强制停止如果还在运行
            if kill -0 "$pid" 2>/dev/null; then
                echo "⚠️  强制停止 $name..."
                kill -9 "$pid"
            fi
            
            echo "✅ $name 已停止"
        else
            echo "⚠️  $name 进程不存在"
        fi
        rm -f "$pid_file"
    else
        echo "⚠️  $name 进程文件不存在"
    fi
}

# 停止所有AI服务进程
echo "🤖 停止AI服务..."
stop_process "LoomaCRM Future" "/tmp/ai-identity-network-looma.pid"
stop_process "AI网关服务" "/tmp/ai-identity-network-gateway.pid"
stop_process "简历AI服务" "/tmp/ai-identity-network-resume.pid"
stop_process "MinerU服务" "/tmp/ai-identity-network-mineru.pid"
stop_process "AI模型服务" "/tmp/ai-identity-network-models.pid"
stop_process "Zervigo Future" "/tmp/ai-identity-network-zervigo.pid"

# 停止Docker服务
echo "🐳 停止Docker服务..."
cd /Users/szjason72/genzltd/looma_crm_future

if [ -f "docker-compose-future.yml" ]; then
    echo "🛑 停止Future版Docker服务..."
    docker-compose -f docker-compose-future.yml down
    echo "✅ Docker服务已停止"
else
    echo "⚠️  Docker配置文件不存在"
fi

# 停止Zervigo服务
echo "🏢 停止Zervigo服务..."
cd ../zervigo_future

if [ -f "stop-zervigo-future.sh" ]; then
    ./stop-zervigo-future.sh
    echo "✅ Zervigo服务已停止"
else
    echo "⚠️  Zervigo停止脚本不存在"
fi

# 清理临时文件
echo "🧹 清理临时文件..."
rm -f /tmp/ai-identity-network-*.pid
rm -f /tmp/ai-identity-network-health-report.txt

# 清理Python进程
echo "🐍 清理Python进程..."
pkill -f "python -m looma_crm"
pkill -f "python -m services.ai_services"
pkill -f "python -m ai_gateway"
pkill -f "python -m resume_ai"
pkill -f "python -m mineru"
pkill -f "python -m ai_models"

echo ""
echo "✅ AI身份社交网络已完全停止！"
echo "=========================="
echo "🔧 如需重新启动，请运行: ./start-ai-identity-network.sh"
echo "📊 如需查看日志，请运行: ./view-ai-identity-network-logs.sh"
