#!/bin/bash
# 阿里云安全组配置验证脚本
# 验证8个端口是否已经开放

echo "🔍 阿里云多数据库集群安全组配置验证"
echo "============================================================"
echo "验证时间: $(date)"
echo "目标服务器: 47.115.168.107"
echo ""

# 端口列表
declare -A PORTS=(
    ["MySQL"]="3306"
    ["PostgreSQL"]="5432"
    ["Redis"]="6379"
    ["Neo4j HTTP"]="7474"
    ["Neo4j Bolt"]="7687"
    ["Elasticsearch HTTP"]="9200"
    ["Elasticsearch Transport"]="9300"
    ["Weaviate"]="8080"
)

# 验证函数
verify_port() {
    local service=$1
    local port=$2
    local server="47.115.168.107"
    
    echo -n "验证 ${service} (端口 ${port})... "
    
    # 使用 nc (netcat) 测试端口连通性
    if command -v nc &> /dev/null; then
        if timeout 5 nc -zv $server $port 2>&1 | grep -q "succeeded\|open"; then
            echo "✅ 端口已开放"
            return 0
        else
            echo "❌ 端口未开放或无法访问"
            return 1
        fi
    # 如果没有 nc，使用 telnet
    elif command -v telnet &> /dev/null; then
        if timeout 5 telnet $server $port 2>&1 | grep -q "Connected\|Escape"; then
            echo "✅ 端口已开放"
            return 0
        else
            echo "❌ 端口未开放或无法访问"
            return 1
        fi
    # 如果都没有，使用 curl 测试 HTTP 端口
    else
        if timeout 5 curl -s http://$server:$port &> /dev/null; then
            echo "✅ 端口已开放"
            return 0
        else
            echo "❌ 端口未开放或无法访问"
            return 1
        fi
    fi
}

# 验证所有端口
echo "开始验证端口连通性..."
echo ""

total=0
success=0

for service in "${!PORTS[@]}"; do
    port=${PORTS[$service]}
    if verify_port "$service" "$port"; then
        ((success++))
    fi
    ((total++))
done

echo ""
echo "============================================================"
echo "📊 验证结果统计"
echo "============================================================"
echo "总端口数: $total"
echo "已开放: $success"
echo "未开放: $((total - success))"
echo "成功率: $(awk "BEGIN {printf \"%.1f\", ($success/$total)*100}")%"
echo ""

if [ $success -eq $total ]; then
    echo "🎉 所有端口验证通过！阿里云安全组配置正确！"
    echo ""
    echo "下一步："
    echo "1. 运行跨云连接测试: python3 test_cross_cloud_sync.py"
    echo "2. 实施数据库复制配置: ./implement_cross_cloud_sync.sh"
    exit 0
elif [ $success -ge $((total/2)) ]; then
    echo "⚠️ 部分端口已开放，请检查未开放的端口配置"
    echo ""
    echo "需要配置的端口："
    for service in "${!PORTS[@]}"; do
        port=${PORTS[$service]}
        if ! timeout 5 nc -zv 47.115.168.107 $port 2>&1 | grep -q "succeeded\|open"; then
            echo "  - ${service}: ${port}"
        fi
    done
    exit 1
else
    echo "❌ 大部分端口未开放，请配置阿里云安全组"
    echo ""
    echo "配置步骤："
    echo "1. 登录阿里云控制台: https://ecs.console.aliyun.com"
    echo "2. 进入: 网络与安全 > 安全组"
    echo "3. 选择安全组 > 配置规则 > 入方向"
    echo "4. 参考文档: alibaba_cloud_ports_checklist.txt"
    exit 1
fi
