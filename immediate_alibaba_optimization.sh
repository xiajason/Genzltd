#!/bin/bash
# 立即开始阿里云优化实施

echo "🚀 阿里云数据库优化实施开始"
echo "================================"
echo "基于腾讯云成功经验"
echo "目标: 66.7% → 100%"
echo "时间: $(date)"
echo ""

# 第一阶段：检查Elasticsearch JVM配置
echo "🔍 第一阶段：检查Elasticsearch JVM配置"
echo "----------------------------------------"
echo "1. 检查当前JVM配置..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker exec production-elasticsearch cat /etc/elasticsearch/jvm.options | grep -E '^-Xm[as]'"

echo ""
echo "2. 备份当前配置..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker exec production-elasticsearch cp /etc/elasticsearch/jvm.options /etc/elasticsearch/jvm.options.backup"

echo ""
echo "3. 修复JVM参数冲突..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker exec production-elasticsearch sed -i 's/-Xms.*/-Xms1g/g' /etc/elasticsearch/jvm.options"
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker exec production-elasticsearch sed -i 's/-Xmx.*/-Xmx1g/g' /etc/elasticsearch/jvm.options"

echo ""
echo "4. 验证修复结果..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker exec production-elasticsearch cat /etc/elasticsearch/jvm.options | grep -E '^-Xm[as]'"

echo ""
echo "5. 重启Elasticsearch..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker restart production-elasticsearch"

echo ""
echo "⏳ 等待Elasticsearch启动..."
sleep 30

echo ""
echo "6. 验证Elasticsearch状态..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "curl -s http://localhost:9200/_cluster/health"

echo ""
echo "✅ Elasticsearch优化完成"
echo ""

# 第二阶段：检查Neo4j配置
echo "🔍 第二阶段：检查Neo4j配置"
echo "----------------------------------------"
echo "1. 检查Neo4j日志..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker logs production-neo4j | grep -i password | tail -3"

echo ""
echo "2. 设置Neo4j密码..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker exec production-neo4j neo4j-admin set-initial-password jobfirst_password_2024"

echo ""
echo "3. 重启Neo4j..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker restart production-neo4j"

echo ""
echo "⏳ 等待Neo4j启动..."
sleep 30

echo ""
echo "4. 验证Neo4j连接..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker exec production-neo4j cypher-shell -u neo4j -p jobfirst_password_2024 'RETURN 1'"

echo ""
echo "✅ Neo4j优化完成"
echo ""

# 第三阶段：系统资源优化
echo "🔍 第三阶段：系统资源优化"
echo "----------------------------------------"
echo "1. 优化容器资源限制..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker update --memory=1g --memory-swap=1g production-elasticsearch"
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker update --memory=512m --memory-swap=512m production-neo4j"

echo ""
echo "2. 设置CPU限制..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker update --cpus=1.0 production-elasticsearch"
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker update --cpus=1.0 production-neo4j"

echo ""
echo "3. 检查优化结果..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker stats --no-stream"

echo ""
echo "✅ 系统优化完成"
echo ""

# 最终验证
echo "🔍 最终验证"
echo "----------------------------------------"
echo "运行数据库测试..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "python3 alibaba_cloud_database_manager.py"

echo ""
echo "🎉 优化实施完成！"
echo "================================"
echo "完成时间: $(date)"
echo "================================"
EOF"