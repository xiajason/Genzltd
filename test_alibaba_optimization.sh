#!/bin/bash
# 测试阿里云优化效果

echo "🔍 阿里云优化效果测试"
echo "================================"
echo "时间: $(date)"
echo ""

echo "1. 检查所有容器状态..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker ps -a --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"

echo ""
echo "2. 检查系统资源使用..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "free -h"

echo ""
echo "3. 检查数据库资源使用..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker stats --no-stream"

echo ""
echo "4. 测试Elasticsearch连接..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "curl -s http://localhost:9200/_cluster/health"

echo ""
echo "5. 测试Neo4j连接..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker exec production-neo4j cypher-shell -u neo4j -p jobfirst_password_2024 'RETURN 1'"

echo ""
echo "6. 测试MySQL连接..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker exec production-mysql mysql -u root -pjobfirst_password_2024 -e 'SELECT 1'"

echo ""
echo "7. 测试PostgreSQL连接..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker exec production-postgres psql -U postgres -d postgres -c 'SELECT 1'"

echo ""
echo "8. 测试Redis连接..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker exec production-redis redis-cli ping"

echo ""
echo "9. 测试Weaviate连接..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "curl -s http://localhost:8080/v1/meta"

echo ""
echo "✅ 测试完成"
echo "================================"
EOF"