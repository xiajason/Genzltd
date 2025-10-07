#!/bin/bash
# 阿里云数据库优化启动脚本
# 基于腾讯云成功经验的阿里云优化实施

echo "🚀 阿里云数据库优化实施"
echo "================================"
echo "目标: 将成功率从66.7%提升到100%"
echo "基于: 腾讯云成功经验"
echo "时间: $(date)"
echo ""

# 检查SSH连接
echo "🔍 检查阿里云服务器连接..."
ssh -i ~/.ssh/cross_cloud_key -o ConnectTimeout=10 root@47.115.168.107 "echo '✅ 阿里云服务器连接正常'" || {
    echo "❌ 无法连接到阿里云服务器"
    echo "请检查SSH密钥和网络连接"
    exit 1
}

echo ""
echo "📋 优化计划:"
echo "第一阶段: 诊断和准备 (30分钟)"
echo "第二阶段: 修复Elasticsearch (20分钟)"
echo "第三阶段: 修复Neo4j (20分钟)"
echo "第四阶段: 系统优化 (15分钟)"
echo "总时间: 约85分钟"
echo ""

# 确认开始
read -p "是否开始实施优化？(y/N): " confirm
if [[ $confirm != [yY] ]]; then
    echo "❌ 用户取消实施"
    exit 0
fi

echo ""
echo "🚀 开始实施优化..."
echo "================================"

# 第一阶段：诊断和准备
echo "🔍 第一阶段：诊断和准备"
echo "------------------------"
echo "1. 检查容器状态..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker ps -a"

echo ""
echo "2. 检查系统资源..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "free -h && df -h"

echo ""
echo "3. 检查数据库资源使用..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker stats --no-stream --format 'table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}'"

echo ""
echo "✅ 第一阶段完成"
echo ""

# 第二阶段：修复Elasticsearch
echo "🔧 第二阶段：修复Elasticsearch"
echo "------------------------"
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
echo "✅ 第二阶段完成"
echo ""

# 第三阶段：修复Neo4j
echo "🔧 第三阶段：修复Neo4j"
echo "------------------------"
echo "1. 检查Neo4j日志..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker logs production-neo4j | grep -i password | tail -5"

echo ""
echo "2. 设置Neo4j密码..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker exec production-neo4j neo4j-admin set-initial-password jobfirst_password_2024"

echo ""
echo "3. 修复文件权限..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker exec production-neo4j chown -R neo4j:neo4j /var/lib/neo4j/data/"
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker exec production-neo4j chmod -R 755 /var/lib/neo4j/data/"

echo ""
echo "4. 重启Neo4j..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker restart production-neo4j"

echo ""
echo "⏳ 等待Neo4j启动..."
sleep 30

echo ""
echo "5. 验证Neo4j连接..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker exec production-neo4j cypher-shell -u neo4j -p jobfirst_password_2024 'RETURN 1'"

echo ""
echo "✅ 第三阶段完成"
echo ""

# 第四阶段：系统优化
echo "🔧 第四阶段：系统优化"
echo "------------------------"
echo "1. 优化容器资源限制..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker update --memory=1g --memory-swap=1g production-elasticsearch"
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker update --memory=512m --memory-swap=512m production-neo4j"

echo ""
echo "2. 设置CPU限制..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker update --cpus=1.0 production-elasticsearch"
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker update --cpus=1.0 production-neo4j"

echo ""
echo "3. 检查优化结果..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker stats --no-stream --format 'table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}'"

echo ""
echo "✅ 第四阶段完成"
echo ""

# 最终验证
echo "🔍 最终验证"
echo "------------------------"
echo "运行完整数据库测试..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "python3 alibaba_cloud_database_manager.py"

echo ""
echo "🎉 优化实施完成！"
echo "================================"
echo "预期结果: 成功率从66.7%提升到100%"
echo "完成时间: $(date)"
echo "================================"
EOF"