#!/bin/bash
echo "=== ZerviGo v3.1.1 服务监控 ==="
echo "时间: $(date)"
echo ""

# 检查重构后的微服务
echo "重构后的微服务状态:"
echo "Template Service (8085): $(curl -s http://localhost:8085/health | jq -r '.status')"
echo "Statistics Service (8086): $(curl -s http://localhost:8086/health | jq -r '.status')"
echo "Banner Service (8087): $(curl -s http://localhost:8087/health | jq -r '.status')"

echo ""
echo "=== 完整系统状态 ==="
./backend/pkg/jobfirst-core/superadmin/zervigo
