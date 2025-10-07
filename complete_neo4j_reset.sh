#!/bin/bash
# 完全重置Neo4j

echo "🔄 完全重置Neo4j"
echo "=========================================="
echo "时间: $(date)"
echo "目标: 彻底清理并重新创建Neo4j"
echo ""

# 1. 停止所有Neo4j相关容器
echo "1. 停止所有Neo4j相关容器..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker stop production-neo4j 2>/dev/null || true"

echo ""
echo "2. 删除Neo4j容器..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker rm production-neo4j 2>/dev/null || true"

echo ""
echo "3. 强制删除Neo4j数据卷..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker volume rm production-neo4j-data 2>/dev/null || true"

echo ""
echo "4. 清理Neo4j数据目录..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "rm -rf /var/lib/containers/storage/volumes/production-neo4j-data 2>/dev/null || true"

echo ""
echo "5. 重新创建Neo4j数据卷..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker volume create production-neo4j-data"

echo ""
echo "6. 重新启动Neo4j容器..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker run -d --name production-neo4j -p 7474:7474 -p 7687:7687 -v production-neo4j-data:/data -e NEO4J_AUTH=neo4j/f_neo4j_password_2025 -e NEO4J_dbms_memory_pagecache_size=128m -e NEO4J_dbms_memory_heap_initial_size=256m -e NEO4J_dbms_memory_heap_max_size=256m neo4j:latest"

echo ""
echo "7. 等待Neo4j启动..."
sleep 30

echo ""
echo "8. 检查Neo4j状态..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker ps --filter name=production-neo4j"

echo ""
echo "9. 检查Neo4j日志..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker logs --tail 10 production-neo4j"

echo ""
echo "10. 测试Neo4j连接..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker exec production-neo4j cypher-shell -u neo4j -p f_neo4j_password_2025 'RETURN 1 as test'"

echo ""
echo "✅ Neo4j完全重置完成"
echo "=========================================="
echo "完成时间: $(date)"
echo "=========================================="
EOF"