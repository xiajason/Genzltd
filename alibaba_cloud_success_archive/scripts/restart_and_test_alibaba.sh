#!/bin/bash
# 阿里云多数据库集群重启和严格测试脚本

echo "🚀 阿里云多数据库集群重启和严格测试"
echo "=========================================="
echo "时间: $(date)"
echo "目标: 验证优化效果，观察系统运行状况"
echo ""

# 第一阶段：重启所有数据库容器
echo "🔄 第一阶段：重启所有数据库容器"
echo "----------------------------------------"
echo "1. 停止所有数据库容器..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker stop production-mysql production-postgres production-redis production-neo4j production-elasticsearch production-weaviate"

echo ""
echo "2. 等待容器完全停止..."
sleep 10

echo ""
echo "3. 启动所有数据库容器..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker start production-mysql production-postgres production-redis production-neo4j production-elasticsearch production-weaviate"

echo ""
echo "4. 等待容器启动..."
sleep 30

echo ""
echo "5. 检查容器状态..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker ps -a --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"

echo ""
echo "✅ 第一阶段完成：容器重启"
echo ""

# 第二阶段：系统资源检查
echo "📊 第二阶段：系统资源检查"
echo "----------------------------------------"
echo "1. 检查系统内存使用..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "free -h"

echo ""
echo "2. 检查磁盘使用情况..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "df -h"

echo ""
echo "3. 检查数据库资源使用..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker stats --no-stream"

echo ""
echo "✅ 第二阶段完成：系统资源检查"
echo ""

# 第三阶段：数据库连接测试
echo "🔍 第三阶段：数据库连接测试"
echo "----------------------------------------"
echo "1. 测试MySQL连接..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker exec production-mysql mysql -u root -pjobfirst_password_2024 -e 'SELECT 1 as test'"

echo ""
echo "2. 测试PostgreSQL连接..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker exec production-postgres psql -U postgres -d postgres -c 'SELECT 1 as test'"

echo ""
echo "3. 测试Redis连接..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker exec production-redis redis-cli ping"

echo ""
echo "4. 测试Neo4j连接..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker exec production-neo4j cypher-shell -u neo4j -p jobfirst_password_2024 'RETURN 1 as test'"

echo ""
echo "5. 测试Elasticsearch连接..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "curl -s http://localhost:9200/_cluster/health"

echo ""
echo "6. 测试Weaviate连接..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "curl -s http://localhost:8080/v1/meta"

echo ""
echo "✅ 第三阶段完成：数据库连接测试"
echo ""

# 第四阶段：性能监控
echo "📈 第四阶段：性能监控"
echo "----------------------------------------"
echo "1. 持续监控资源使用 (30秒)..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "timeout 30 docker stats --format 'table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}'"

echo ""
echo "2. 检查系统负载..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "uptime"

echo ""
echo "3. 检查进程状态..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "ps aux | grep -E '(mysql|postgres|redis|neo4j|elasticsearch|weaviate)' | head -10"

echo ""
echo "✅ 第四阶段完成：性能监控"
echo ""

# 第五阶段：优化效果验证
echo "🎯 第五阶段：优化效果验证"
echo "----------------------------------------"
echo "1. 检查Neo4j内存配置..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker exec production-neo4j cat /var/lib/neo4j/conf/neo4j.conf | grep -E '(heap|pagecache|memory)' | tail -10"

echo ""
echo "2. 检查Elasticsearch JVM配置..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker exec production-elasticsearch cat /etc/elasticsearch/jvm.options | grep -E '^-Xm[as]'"

echo ""
echo "3. 最终资源使用统计..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker stats --no-stream --format 'table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}'"

echo ""
echo "✅ 第五阶段完成：优化效果验证"
echo ""

echo "🎉 阿里云多数据库集群重启和严格测试完成！"
echo "=========================================="
echo "完成时间: $(date)"
echo "=========================================="
EOF"