#!/bin/bash
# 强制修复Neo4j密码循环问题

echo "🔧 强制修复Neo4j密码循环问题"
echo "=========================================="
echo "时间: $(date)"
echo "目标: 彻底解决Neo4j密码循环问题"
echo ""

# 1. 完全停止并删除Neo4j容器
echo "1. 完全停止并删除Neo4j容器..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker stop production-neo4j && docker rm production-neo4j"

echo ""
echo "2. 清理Neo4j数据卷中的认证文件..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker volume rm production-neo4j-data"

echo ""
echo "3. 重新创建Neo4j数据卷..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker volume create production-neo4j-data"

echo ""
echo "4. 重新启动Neo4j容器 (使用环境变量设置密码)..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker run -d --name production-neo4j -p 7474:7474 -p 7687:7687 -v production-neo4j-data:/data -e NEO4J_AUTH=neo4j/f_neo4j_password_2025 -e NEO4J_dbms_memory_pagecache_size=128m -e NEO4J_dbms_memory_heap_initial_size=256m -e NEO4J_dbms_memory_heap_max_size=256m neo4j:latest"

echo ""
echo "5. 等待Neo4j完全启动..."
sleep 60

echo ""
echo "6. 检查Neo4j状态..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker ps --filter name=production-neo4j --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"

echo ""
echo "7. 检查Neo4j日志 (最近20行)..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker logs --tail 20 production-neo4j"

echo ""
echo "8. 测试Neo4j连接..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker exec production-neo4j cypher-shell -u neo4j -p f_neo4j_password_2025 'RETURN 1 as test'"

echo ""
echo "9. 检查Neo4j端口监听..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "netstat -tlnp | grep -E '(7474|7687)'"

echo ""
echo "✅ Neo4j强制修复完成"
echo "=========================================="
echo "完成时间: $(date)"
echo "=========================================="
EOF"