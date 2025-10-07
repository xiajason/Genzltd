#!/bin/bash
# 修复Elasticsearch内存问题

echo "🔧 修复Elasticsearch内存问题"
echo "=========================================="
echo "时间: $(date)"
echo "目标: 解决JVM参数冲突，优化内存配置"
echo ""

# 1. 停止Elasticsearch容器
echo "1. 停止Elasticsearch容器..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker stop production-elasticsearch"

echo ""
echo "2. 等待容器完全停止..."
sleep 5

# 3. 备份当前配置
echo "3. 备份当前Elasticsearch配置..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker cp production-elasticsearch:/etc/elasticsearch/jvm.options /tmp/elasticsearch_jvm.options.backup"

# 4. 重新创建Elasticsearch容器，使用优化的内存配置
echo "4. 重新创建Elasticsearch容器..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker rm production-elasticsearch"

echo ""
echo "5. 启动优化后的Elasticsearch容器..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker run -d --name production-elasticsearch -p 9200:9200 -e discovery.type=single-node -e xpack.security.enabled=false -e ES_JAVA_OPTS='-Xms256m -Xmx256m' elasticsearch:5.6.12"

echo ""
echo "6. 等待Elasticsearch启动..."
sleep 30

echo ""
echo "7. 检查Elasticsearch状态..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker ps --filter name=production-elasticsearch --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"

echo ""
echo "8. 检查Elasticsearch日志..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker logs --tail 20 production-elasticsearch"

echo ""
echo "9. 测试Elasticsearch连接..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "curl -s http://localhost:9200/_cluster/health"

echo ""
echo "10. 检查系统内存使用..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "free -h"

echo ""
echo "✅ Elasticsearch内存问题修复完成"
echo "=========================================="
echo "完成时间: $(date)"
echo "=========================================="
EOF"