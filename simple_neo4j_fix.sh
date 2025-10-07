#!/bin/bash
# 简单修复Neo4j

echo "🔧 简单修复Neo4j"
echo "=========================================="
echo "时间: $(date)"
echo "目标: 使用简单方法修复Neo4j"
echo ""

# 1. 停止并删除现有Neo4j
echo "1. 停止并删除现有Neo4j..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker stop production-neo4j && docker rm production-neo4j"

echo ""
echo "2. 使用Docker Compose重新创建Neo4j..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "cd /root && docker-compose up -d neo4j"

echo ""
echo "3. 等待Neo4j启动..."
sleep 30

echo ""
echo "4. 检查Neo4j状态..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker ps --filter name=production-neo4j"

echo ""
echo "5. 测试Neo4j连接..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker exec production-neo4j cypher-shell -u neo4j -p f_neo4j_password_2025 'RETURN 1 as test'"

echo ""
echo "✅ Neo4j简单修复完成"
echo "=========================================="
echo "完成时间: $(date)"
echo "=========================================="
EOF"