#!/bin/bash

# Consul健康管理脚本
# 用于监控Consul服务状态、UI访问和微服务健康检查

set -e

CONSUL_HOST="localhost"
CONSUL_PORT="8500"
CONSUL_UI_URL="http://${CONSUL_HOST}:${CONSUL_PORT}/ui/"

echo "=== Consul健康管理监控 ==="
echo "时间: $(date)"
echo "Consul地址: ${CONSUL_HOST}:${CONSUL_PORT}"
echo "Consul UI: ${CONSUL_UI_URL}"
echo ""

# 1. 检查Consul服务状态
echo "1. Consul服务状态检查:"
if curl -s http://${CONSUL_HOST}:${CONSUL_PORT}/v1/status/leader > /dev/null; then
    LEADER=$(curl -s http://${CONSUL_HOST}:${CONSUL_PORT}/v1/status/leader)
    echo "   ✅ Consul服务运行正常"
    echo "   📍 集群Leader: ${LEADER}"
else
    echo "   ❌ Consul服务无法访问"
    exit 1
fi

# 2. 检查Consul UI
echo -e "\n2. Consul UI检查:"
UI_STATUS=$(curl -s -o /dev/null -w "%{http_code}" ${CONSUL_UI_URL})
if [ "$UI_STATUS" = "200" ]; then
    echo "   ✅ Consul UI可访问 (HTTP ${UI_STATUS})"
    echo "   🌐 访问地址: ${CONSUL_UI_URL}"
else
    echo "   ❌ Consul UI无法访问 (HTTP ${UI_STATUS})"
fi

# 3. 检查集群成员
echo -e "\n3. 集群成员检查:"
MEMBERS=$(curl -s http://${CONSUL_HOST}:${CONSUL_PORT}/v1/agent/members)
echo "   📊 集群成员:"
echo "$MEMBERS" | jq -r '.[] | "   - " + .Name + ": 状态=" + (.Status | tostring) + ", 端口=" + (.Port | tostring)'

# 4. 检查已注册服务
echo -e "\n4. 已注册服务检查:"
SERVICES=$(curl -s http://${CONSUL_HOST}:${CONSUL_PORT}/v1/agent/services | jq 'keys')
SERVICE_COUNT=$(echo "$SERVICES" | jq 'length')
echo "   📋 已注册服务数量: ${SERVICE_COUNT}"
echo "   📝 服务列表:"
echo "$SERVICES" | jq -r '.[] | "   - " + .'

# 5. 健康检查状态
echo -e "\n5. 健康检查状态:"
HEALTH_CHECKS=$(curl -s http://${CONSUL_HOST}:${CONSUL_PORT}/v1/health/state/any)
PASSING_COUNT=$(echo "$HEALTH_CHECKS" | jq '[.[] | select(.Status == "passing")] | length')
WARNING_COUNT=$(echo "$HEALTH_CHECKS" | jq '[.[] | select(.Status == "warning")] | length')
CRITICAL_COUNT=$(echo "$HEALTH_CHECKS" | jq '[.[] | select(.Status == "critical")] | length')

echo "   🟢 通过: ${PASSING_COUNT}"
echo "   🟡 警告: ${WARNING_COUNT}"
echo "   🔴 严重: ${CRITICAL_COUNT}"

if [ "$CRITICAL_COUNT" -gt 0 ]; then
    echo "   ⚠️  发现严重健康检查问题:"
    echo "$HEALTH_CHECKS" | jq -r '.[] | select(.Status == "critical") | "   - " + .ServiceName + ": " + .Output'
fi

# 6. 服务健康详情
echo -e "\n6. 服务健康详情:"
echo "$HEALTH_CHECKS" | jq -r '.[] | select(.ServiceName != "") | "   " + .ServiceName + ": " + .Status + " - " + .Output'

# 7. 端口占用检查
echo -e "\n7. Consul端口占用检查:"
echo "   🔍 检查Consul相关端口:"
for port in 8500 8501 8502 8600 8300 8301 8302; do
    if lsof -i :${port} > /dev/null 2>&1; then
        echo "   ✅ 端口 ${port}: 已占用"
    else
        echo "   ❌ 端口 ${port}: 未占用"
    fi
done

# 8. 数据目录检查
echo -e "\n8. Consul数据目录检查:"
DATA_DIR="/Users/szjason72/zervi-basic/basic/consul/data"
if [ -d "$DATA_DIR" ]; then
    echo "   ✅ 数据目录存在: ${DATA_DIR}"
    echo "   📁 目录大小: $(du -sh ${DATA_DIR} | cut -f1)"
    echo "   📊 文件数量: $(find ${DATA_DIR} -type f | wc -l)"
else
    echo "   ❌ 数据目录不存在: ${DATA_DIR}"
fi

echo -e "\n=== 监控完成 ==="
echo "💡 提示: 访问 ${CONSUL_UI_URL} 查看图形化界面"
echo "📊 使用 'consul members' 查看集群状态"
echo "🔍 使用 'consul catalog services' 查看服务目录"
