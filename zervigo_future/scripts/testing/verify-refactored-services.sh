#!/bin/bash

# 重构服务验证脚本
# 验证三个重构后的微服务是否正常运行

echo "🔍 重构服务验证脚本 (v3.1.1)"
echo "=================================="

# 服务配置
declare -A SERVICES=(
    ["template-service"]="8085:模板管理服务"
    ["statistics-service"]="8086:数据统计服务"
    ["banner-service"]="8087:内容管理服务"
)

echo "📋 服务配置:"
for service in "${!SERVICES[@]}"; do
    port_desc=${SERVICES[$service]}
    port=${port_desc%%:*}
    desc=${port_desc#*:}
    echo "  $service (端口:$port) - $desc"
done

echo ""
echo "🔍 服务状态检查:"

# 检查每个服务
total_services=0
healthy_services=0

for service in "${!SERVICES[@]}"; do
    port_desc=${SERVICES[$service]}
    port=${port_desc%%:*}
    desc=${port_desc#*:}
    
    total_services=$((total_services + 1))
    
    echo -n "  $service (端口:$port): "
    
    # 检查端口是否开放
    if lsof -i :$port >/dev/null 2>&1; then
        # 检查健康端点
        health_response=$(curl -s -w "%{http_code}" -o /dev/null http://localhost:$port/health 2>/dev/null)
        if [ "$health_response" = "200" ]; then
            echo "✅ 健康"
            healthy_services=$((healthy_services + 1))
            
            # 获取服务信息
            service_info=$(curl -s http://localhost:$port/health 2>/dev/null | jq -r '.service // "unknown"' 2>/dev/null)
            echo "      服务名称: $service_info"
        else
            echo "⚠️  端口开放但健康检查失败 (HTTP: $health_response)"
        fi
    else
        echo "❌ 端口未开放"
    fi
done

echo ""
echo "🧪 API 功能测试:"

# Template Service API 测试
echo "  Template Service API 测试:"
template_response=$(curl -s -w "%{http_code}" -o /tmp/template_response.json http://localhost:8085/api/v1/template/public/categories 2>/dev/null)
if [ "$template_response" = "200" ]; then
    echo "    ✅ 分类列表 API 正常"
else
    echo "    ❌ 分类列表 API 失败 (HTTP: $template_response)"
fi

# Statistics Service API 测试
echo "  Statistics Service API 测试:"
stats_response=$(curl -s -w "%{http_code}" -o /tmp/stats_response.json http://localhost:8086/api/v1/statistics/public/overview 2>/dev/null)
if [ "$stats_response" = "200" ]; then
    echo "    ✅ 统计概览 API 正常"
else
    echo "    ❌ 统计概览 API 失败 (HTTP: $stats_response)"
fi

# Banner Service API 测试
echo "  Banner Service API 测试:"
banner_response=$(curl -s -w "%{http_code}" -o /tmp/banner_response.json http://localhost:8087/api/v1/content/public/banners 2>/dev/null)
if [ "$banner_response" = "200" ]; then
    echo "    ✅ Banner 列表 API 正常"
else
    echo "    ❌ Banner 列表 API 失败 (HTTP: $banner_response)"
fi

echo ""
echo "📊 验证总结:"
echo "=================================="
echo "  总服务数: $total_services"
echo "  健康服务数: $healthy_services"
echo "  健康状态: $((healthy_services * 100 / total_services))%"

if [ $healthy_services -eq $total_services ]; then
    echo ""
    echo "🎉 所有重构服务验证通过！"
    echo "✅ Template Service (8085) - 模板管理服务"
    echo "✅ Statistics Service (8086) - 数据统计服务"  
    echo "✅ Banner Service (8087) - 内容管理服务"
    echo ""
    echo "🚀 ZerviGo v3.1.1 重构服务支持已就绪！"
    exit 0
else
    echo ""
    echo "⚠️  部分服务需要检查"
    exit 1
fi
