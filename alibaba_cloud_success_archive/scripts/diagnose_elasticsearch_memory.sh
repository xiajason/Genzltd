#!/bin/bash
# 诊断Elasticsearch内存问题

echo "🔍 诊断Elasticsearch内存问题"
echo "=========================================="
echo "时间: $(date)"
echo "目标: 分析Elasticsearch内存配置和OOM问题"
echo ""

# 1. 检查Elasticsearch容器状态
echo "1. 检查Elasticsearch容器状态..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker ps --filter name=production-elasticsearch --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"

echo ""
echo "2. 检查Elasticsearch容器详细状态..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker inspect production-elasticsearch | grep -E '(Status|Health|RestartCount|ExitCode)'"

echo ""
echo "3. 检查Elasticsearch日志 (最近30行)..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker logs --tail 30 production-elasticsearch"

echo ""
echo "4. 检查系统内存使用情况..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "free -h"

echo ""
echo "5. 检查Elasticsearch JVM配置..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker exec production-elasticsearch cat /etc/elasticsearch/jvm.options | grep -E '^-Xm[as]'"

echo ""
echo "6. 检查Elasticsearch环境变量..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker inspect production-elasticsearch | grep -A 20 'Env'"

echo ""
echo "7. 检查Elasticsearch进程状态..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker exec production-elasticsearch ps aux | grep elasticsearch"

echo ""
echo "8. 检查Elasticsearch端口监听..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "netstat -tlnp | grep 9200"

echo ""
echo "9. 尝试连接Elasticsearch..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "curl -s http://localhost:9200/_cluster/health"

echo ""
echo "✅ Elasticsearch内存问题诊断完成"
echo "=========================================="
echo "完成时间: $(date)"
echo "=========================================="
EOF"