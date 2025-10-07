#!/bin/bash
# 修复Neo4j密码循环问题

echo "🔧 修复Neo4j密码循环问题"
echo "=========================================="
echo "时间: $(date)"
echo "目标: 停止密码循环，重新配置Neo4j"
echo ""

# 1. 停止Neo4j容器
echo "1. 停止Neo4j容器..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker stop production-neo4j"

echo ""
echo "2. 等待容器完全停止..."
sleep 5

# 3. 备份当前配置
echo "3. 备份当前Neo4j配置..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker cp production-neo4j:/var/lib/neo4j/conf/neo4j.conf /tmp/neo4j.conf.backup"

# 4. 清理Neo4j数据目录中的密码文件
echo "4. 清理Neo4j密码文件..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker run --rm -v production-neo4j-data:/data alpine sh -c 'rm -f /data/dbms/auth.ini /data/dbms/auth /data/dbms/auth.db'"

# 5. 重新配置Neo4j密码设置
echo "5. 重新配置Neo4j密码设置..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker run --rm -v production-neo4j-data:/data -e NEO4J_AUTH=neo4j/f_neo4j_password_2025 neo4j:latest"

# 6. 启动Neo4j容器
echo "6. 启动Neo4j容器..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker start production-neo4j"

echo ""
echo "7. 等待Neo4j启动..."
sleep 30

echo ""
echo "8. 检查Neo4j状态..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker ps --filter name=production-neo4j --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"

echo ""
echo "9. 测试Neo4j连接..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker exec production-neo4j cypher-shell -u neo4j -p f_neo4j_password_2025 'RETURN 1 as test'"

echo ""
echo "10. 检查Neo4j日志 (最近10行)..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker logs --tail 10 production-neo4j"

echo ""
echo "✅ Neo4j密码循环问题修复完成"
echo "=========================================="
echo "完成时间: $(date)"
echo "=========================================="
EOF"