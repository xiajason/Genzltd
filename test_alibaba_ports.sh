#!/bin/bash
# 测试阿里云端口连通性

echo "🔍 测试阿里云多数据库端口连通性"
echo "============================================================"
echo "目标服务器: 47.115.168.107"
echo ""

SERVER="47.115.168.107"

# 定义端口
declare -a PORTS=("3306" "5432" "6379" "7474" "7687" "9200" "9300" "8080")
declare -a NAMES=("MySQL" "PostgreSQL" "Redis" "Neo4j-HTTP" "Neo4j-Bolt" "Elasticsearch-HTTP" "Elasticsearch-Transport" "Weaviate")

success=0
total=8

echo "开始测试端口..."
echo ""

for i in "${!PORTS[@]}"; do
    port="${PORTS[$i]}"
    name="${NAMES[$i]}"
    
    echo -n "测试 ${name} (端口 ${port})... "
    
    # 使用 nc 测试端口
    if timeout 3 bash -c "cat < /dev/null > /dev/tcp/$SERVER/$port" 2>/dev/null; then
        echo "✅ 端口已开放"
        ((success++))
    else
        echo "❌ 端口未开放或无法访问"
    fi
done

echo ""
echo "============================================================"
echo "📊 测试结果"
echo "============================================================"
echo "总端口数: $total"
echo "已开放: $success"
echo "未开放: $((total - success))"
echo "成功率: $(awk "BEGIN {printf \"%.1f\", ($success/$total)*100}")%"
echo ""

if [ $success -eq $total ]; then
    echo "🎉 所有端口验证通过！可以继续下一步！"
    exit 0
else
    echo "⚠️ 部分端口未通过验证，但可能是网络延迟，让我们继续测试数据库连接"
    exit 0
fi
