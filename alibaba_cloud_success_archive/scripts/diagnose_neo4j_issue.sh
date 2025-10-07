#!/bin/bash
# 诊断Neo4j启动问题

echo "🔍 诊断Neo4j启动问题"
echo "=========================================="
echo "时间: $(date)"
echo "目标: 检查Neo4j启动状态和日志"
echo ""

# 检查Neo4j容器状态
echo "1. 检查Neo4j容器状态..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker ps --filter name=production-neo4j --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"

echo ""
echo "2. 检查Neo4j容器详细状态..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker inspect production-neo4j | grep -E '(Status|Health|RestartCount|ExitCode)'"

echo ""
echo "3. 检查Neo4j容器日志 (最近50行)..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker logs --tail 50 production-neo4j"

echo ""
echo "4. 检查Neo4j端口监听状态..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "netstat -tlnp | grep -E '(7474|7687)'"

echo ""
echo "5. 检查Neo4j进程状态..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker exec production-neo4j ps aux | grep neo4j"

echo ""
echo "6. 检查Neo4j配置文件..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker exec production-neo4j cat /var/lib/neo4j/conf/neo4j.conf | grep -E '(password|auth|bolt|http)'"

echo ""
echo "7. 尝试直接连接Neo4j..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker exec production-neo4j cypher-shell -u neo4j -p f_neo4j_password_2025 'RETURN 1 as test'"

echo ""
echo "8. 检查Neo4j数据库文件权限..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker exec production-neo4j ls -la /var/lib/neo4j/"

echo ""
echo "9. 检查Neo4j内存使用情况..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker exec production-neo4j free -h"

echo ""
echo "✅ Neo4j诊断完成"
echo "=========================================="
echo "完成时间: $(date)"
echo "=========================================="
EOF"