#!/bin/bash

# ZerviGo 端口配置测试脚本
# 用于验证重构服务的端口配置是否正确

echo "🔍 ZerviGo v3.1.1 端口配置测试"
echo "=================================="

# 定义预期的端口配置
declare -A EXPECTED_PORTS=(
    ["template-service"]="8085"
    ["statistics-service"]="8086"
    ["banner-service"]="8087"
)

# 定义服务名称映射
declare -A SERVICE_NAMES=(
    ["template-service"]="Template Service"
    ["statistics-service"]="Statistics Service"
    ["banner-service"]="Banner Service"
)

echo "📋 预期端口配置:"
for service in "${!EXPECTED_PORTS[@]}"; do
    echo "  ${SERVICE_NAMES[$service]}: ${EXPECTED_PORTS[$service]}"
done

echo ""
echo "🔍 实际服务状态检查:"

# 检查每个服务的实际状态
for service in "${!EXPECTED_PORTS[@]}"; do
    port=${EXPECTED_PORTS[$service]}
    service_name=${SERVICE_NAMES[$service]}
    
    echo -n "  $service_name (端口:$port): "
    
    # 检查端口是否开放
    if lsof -i :$port >/dev/null 2>&1; then
        # 检查健康端点
        health_response=$(curl -s -w "%{http_code}" -o /dev/null http://localhost:$port/health 2>/dev/null)
        if [ "$health_response" = "200" ]; then
            echo "✅ 运行正常"
        else
            echo "⚠️  端口开放但健康检查失败 (HTTP: $health_response)"
        fi
    else
        echo "❌ 端口未开放"
    fi
done

echo ""
echo "🧪 ZerviGo 工具测试:"

# 测试 zervigo 工具
cd /Users/szjason72/zervi-basic/basic/backend/pkg/jobfirst-core/superadmin

if [ -f "./zervigo" ]; then
    echo "  ZerviGo 工具状态检查:"
    ./zervigo status | grep -E "(template-service|statistics-service|banner-service)" | while read line; do
        echo "    $line"
    done
    
    echo ""
    echo "  ZerviGo 帮助信息:"
    ./zervigo help | head -10
else
    echo "  ❌ ZerviGo 工具不存在"
fi

echo ""
echo "📊 测试总结:"
echo "=================================="

# 统计结果
total_services=0
running_services=0

for service in "${!EXPECTED_PORTS[@]}"; do
    port=${EXPECTED_PORTS[$service]}
    total_services=$((total_services + 1))
    
    if lsof -i :$port >/dev/null 2>&1; then
        health_response=$(curl -s -w "%{http_code}" -o /dev/null http://localhost:$port/health 2>/dev/null)
        if [ "$health_response" = "200" ]; then
            running_services=$((running_services + 1))
        fi
    fi
done

echo "  总服务数: $total_services"
echo "  运行服务数: $running_services"
echo "  健康状态: $((running_services * 100 / total_services))%"

if [ $running_services -eq $total_services ]; then
    echo "  🎉 所有重构服务运行正常！"
    exit 0
else
    echo "  ⚠️  部分服务需要检查"
    exit 1
fi
