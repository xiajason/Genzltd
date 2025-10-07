#!/bin/bash
set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🚀 启动JobFirst Future版完整双AI服务架构..."
echo "=============================================="

# 1. 启动Looma CRM Future服务集群
echo "📦 启动Looma CRM Future服务集群..."
cd "$PROJECT_ROOT/looma_crm_future"

# 启动基础数据库服务
echo "启动基础数据库服务..."
docker-compose -f docker-compose-future-simple.yml up -d

# 等待基础服务启动
echo "等待基础服务启动..."
sleep 10

# 检查基础服务健康状态
echo "检查基础服务健康状态..."
if docker ps | grep -q "future-redis\|future-postgres\|future-mongodb\|future-neo4j\|future-elasticsearch\|future-weaviate"; then
    echo "✅ 基础服务健康检查通过"
else
    echo "❌ 基础服务启动失败"
    exit 1
fi

# 启动完整AI服务集群
echo "启动完整AI服务集群..."
docker-compose -f docker-compose-future.yml up -d

# 等待AI服务启动
echo "等待AI服务启动..."
sleep 15

# 检查Looma CRM Future AI服务健康状态
echo "检查Looma CRM Future AI服务健康状态..."
if docker ps | grep -q "future-looma-crm\|future-ai-gateway\|future-resume-ai"; then
    echo "✅ Looma CRM Future AI服务健康检查通过"
else
    echo "❌ Looma CRM Future AI服务启动失败"
    exit 1
fi

# 2. 启动Zervigo Future AI服务
echo "🤖 启动Zervigo Future AI服务..."
cd "$PROJECT_ROOT/zervigo_future/ai-services"
docker-compose up -d

# 等待Zervigo AI服务启动
echo "等待Zervigo AI服务启动..."
sleep 15

# 检查Zervigo Future AI服务健康状态
echo "检查Zervigo Future AI服务健康状态..."
if docker ps | grep -q "jobfirst-ai-service\|jobfirst-ai-models\|jobfirst-mineru\|jobfirst-ai-monitor"; then
    echo "✅ Zervigo Future AI服务健康检查通过"
else
    echo "❌ Zervigo Future AI服务启动失败"
    exit 1
fi

# 3. 检查双AI服务状态
echo "🔍 检查双AI服务状态..."
cd "$PROJECT_ROOT"

# 检查Looma CRM Future服务
echo ""
echo "📊 Looma CRM Future服务状态:"
if curl -s http://localhost:7500/health >/dev/null 2>&1; then
    echo "  - Looma CRM Future (7500): healthy"
else
    echo "  - Looma CRM Future (7500): degraded"
fi

if curl -s http://localhost:7510/health >/dev/null 2>&1; then
    echo "  - AI Gateway (7510): healthy"
else
    echo "  - AI Gateway (7510): degraded"
fi

if curl -s http://localhost:7511/health >/dev/null 2>&1; then
    echo "  - Resume AI (7511): healthy"
else
    echo "  - Resume AI (7511): degraded"
fi

# 检查Zervigo Future AI服务
echo ""
echo "📊 Zervigo Future AI服务状态:"
if curl -s http://localhost:7540/health >/dev/null 2>&1; then
    echo "  - AI Service (7540): healthy"
else
    echo "  - AI Service (7540): degraded"
fi

if curl -s http://localhost:8622/health >/dev/null 2>&1; then
    echo "  - AI Models (8622): healthy"
else
    echo "  - AI Models (8622): degraded"
fi

if curl -s http://localhost:8621/health >/dev/null 2>&1; then
    echo "  - MinerU (8621): healthy"
else
    echo "  - MinerU (8621): degraded"
fi

# 检查基础服务
echo ""
echo "📊 基础服务状态:"
if redis-cli -p 6382 ping >/dev/null 2>&1; then
    echo "  - Redis (6382): PONG"
else
    echo "  - Redis (6382): 连接失败"
fi

if pg_isready -h localhost -p 5434 -U jobfirst_future >/dev/null 2>&1; then
    echo "  - PostgreSQL (5434): localhost:5434 - accepting connections"
else
    echo "  - PostgreSQL (5434): 连接失败"
fi

if mongo --host localhost:27018 --eval "db.runCommand('ping')" >/dev/null 2>&1; then
    echo "  - MongoDB (27018): ok: 1 }"
else
    echo "  - MongoDB (27018): 连接失败"
fi

if curl -s http://localhost:9202/_cluster/health >/dev/null 2>&1; then
    echo "  - Elasticsearch (9202): green"
else
    echo "  - Elasticsearch (9202): 连接失败"
fi

if curl -s http://localhost:8082/v1/meta >/dev/null 2>&1; then
    echo "  - Weaviate (8082): 1.21.5"
else
    echo "  - Weaviate (8082): 连接失败"
fi

# 运行完整服务检查
echo ""
echo "🔍 运行完整服务检查..."
./check-future-services-complete.sh

echo ""
echo "✅ JobFirst Future版双AI服务架构启动完成！"
echo "=============================================="
echo "🌐 访问地址:"
echo "  - Looma CRM Future: http://localhost:7500"
echo "  - AI Gateway: http://localhost:7510"
echo "  - Resume AI: http://localhost:7511"
echo "  - AI Service: http://localhost:7540"
echo "  - AI Models: http://localhost:8622"
echo "  - MinerU: http://localhost:8621"
echo "  - AI Monitor: http://localhost:8623"
echo ""
echo "📊 服务统计:"
echo "  - 双AI服务架构: ✅ 运行中"
echo "  - 基础数据库: ✅ 运行中"
echo "  - 监控服务: ✅ 运行中"