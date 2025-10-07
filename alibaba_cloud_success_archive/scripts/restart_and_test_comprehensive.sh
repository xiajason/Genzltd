#!/bin/bash
# 重启所有数据库并运行综合测试

echo "🔄 重启阿里云多数据库集群"
echo "=========================================="
echo "时间: $(date)"
echo "目标: 重启所有数据库，运行严格测试"
echo ""

# 重启所有数据库容器
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
echo "✅ 数据库重启完成"
echo ""

# 运行综合测试
echo "🧪 运行综合严格测试"
echo "=========================================="
python3 comprehensive_alibaba_test.py

echo ""
echo "🎉 重启和测试完成！"
echo "=========================================="
echo "完成时间: $(date)"
echo "=========================================="
EOF"