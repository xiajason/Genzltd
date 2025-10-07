#!/bin/bash

# Future版端到端功能测试启动脚本

echo "🚀 启动JobFirst Future版端到端功能测试..."

# 检查Python环境
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3未安装"
    exit 1
fi

# 检查服务状态
echo "🔍 检查服务状态..."
services=(
    "7530:User Service"
    "7532:Resume Service" 
    "7539:Job Service"
    "7500:LoomaCRM"
    "7510:AI Gateway"
    "7511:Resume AI"
    "8000:MinerU"
    "8002:AI Models"
)

all_services_ready=true
for service in "${services[@]}"; do
    port=$(echo $service | cut -d: -f1)
    name=$(echo $service | cut -d: -f2)
    
    if curl -s --connect-timeout 2 http://localhost:$port/health > /dev/null 2>&1; then
        echo "✅ $name (端口$port) - 正常"
    else
        echo "❌ $name (端口$port) - 未运行"
        all_services_ready=false
    fi
done

# 运行测试
echo ""
echo "🧪 开始执行端到端功能测试..."
echo "============================================================"

python3 run_all_tests.py

echo ""
echo "🎉 Future版端到端功能测试执行完成！"
