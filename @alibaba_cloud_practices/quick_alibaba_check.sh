#!/bin/bash
# 快速检查阿里云当前状态

echo "🔍 阿里云数据库快速状态检查"
echo "================================"
echo "时间: $(date)"
echo ""

# 检查SSH连接
echo "1. 检查服务器连接..."
ssh -i ~/.ssh/cross_cloud_key -o ConnectTimeout=10 root@47.115.168.107 "echo '✅ 服务器连接正常'" || {
    echo "❌ 无法连接到阿里云服务器"
    exit 1
}

echo ""
echo "2. 检查容器状态..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker ps -a --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"

echo ""
echo "3. 检查系统资源..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "free -h"

echo ""
echo "4. 检查数据库资源使用..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker stats --no-stream --format 'table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}'"

echo ""
echo "5. 检查Elasticsearch JVM配置..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker exec production-elasticsearch-1 cat /etc/elasticsearch/jvm.options | grep -E '^-Xm[as]' 2>/dev/null || echo 'Elasticsearch容器可能未运行'"

echo ""
echo "6. 检查Neo4j日志..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker logs production-neo4j-1 | grep -i password | tail -3 2>/dev/null || echo 'Neo4j容器可能未运行'"

echo ""
echo "✅ 快速检查完成"
echo "================================"
EOF"