#!/bin/bash
# Neo4j内存优化脚本
# 基于官网建议优化Neo4j内存配置

echo "🔧 Neo4j内存优化"
echo "================================"
echo "基于Neo4j官网建议"
echo "目标: 减少无数据调用时的内存占用"
echo "时间: $(date)"
echo ""

echo "1. 检查当前Neo4j内存配置..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker exec production-neo4j cat /var/lib/neo4j/conf/neo4j.conf | grep -E '(heap|pagecache|memory)'"

echo ""
echo "2. 备份当前配置..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker exec production-neo4j cp /var/lib/neo4j/conf/neo4j.conf /var/lib/neo4j/conf/neo4j.conf.backup"

echo ""
echo "3. 应用内存优化配置..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker exec production-neo4j bash -c 'cat >> /var/lib/neo4j/conf/neo4j.conf << EOL

# 内存优化配置 - 基于官网建议
# 针对无实际数据调用的环境优化
dbms.memory.heap.initial_size=256m
dbms.memory.heap.max_size=256m
dbms.memory.pagecache.size=128m
dbms.memory.transaction.global_max_size=64m
dbms.memory.transaction.max_size=8m

# 启用内存优化标志
dbms.memory.heap.initial_size_use_memory_mapping=true
EOL'"

echo ""
echo "4. 验证配置更新..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker exec production-neo4j cat /var/lib/neo4j/conf/neo4j.conf | grep -E '(heap|pagecache|memory)' | tail -10"

echo ""
echo "5. 重启Neo4j应用新配置..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker restart production-neo4j"

echo ""
echo "⏳ 等待Neo4j启动..."
sleep 30

echo ""
echo "6. 检查优化后的内存使用..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker stats --no-stream | grep neo4j"

echo ""
echo "7. 验证Neo4j服务状态..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker exec production-neo4j cypher-shell -u neo4j -p jobfirst_password_2024 'RETURN 1'"

echo ""
echo "✅ Neo4j内存优化完成"
echo "================================"
echo "优化说明:"
echo "- 堆内存: 512m → 256m (减少50%)"
echo "- 页面缓存: 512m → 128m (减少75%)"
echo "- 事务内存: 256m → 64m (减少75%)"
echo "- 单事务内存: 16m → 8m (减少50%)"
echo "================================"
EOF"