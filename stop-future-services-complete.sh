#!/bin/bash
set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🛑 停止JobFirst Future版完整双AI服务架构..."
echo "=============================================="

# 1. 停止Zervigo Future AI服务
echo "停止Zervigo Future AI服务..."
cd "$PROJECT_ROOT/zervigo_future/ai-services"
docker-compose down 2>/dev/null || true

# 2. 停止Looma CRM Future服务
echo "停止Looma CRM Future服务..."
cd "$PROJECT_ROOT/looma_crm_future"

# 停止完整AI服务集群（包含Neo4j）
echo "停止完整AI服务集群..."
docker-compose -f docker-compose-future.yml down 2>/dev/null || true

# 停止基础数据库服务
echo "停止基础数据库服务..."
docker-compose -f docker-compose-future-simple.yml down 2>/dev/null || true

# 确保Neo4j容器被停止
echo "确保Neo4j容器被停止..."
docker stop future-neo4j 2>/dev/null || true
docker rm future-neo4j 2>/dev/null || true

# 确保Neo4j Java进程被停止
echo "确保Neo4j Java进程被停止..."
neo4j_pids=$(lsof -ti :7474 2>/dev/null)
if [ -n "$neo4j_pids" ]; then
    echo "停止Neo4j Java进程: $neo4j_pids"
    echo "$neo4j_pids" | xargs kill -9 2>/dev/null || true
fi

# 3. 清理端口
echo "清理端口..."
ports=(7500 7510 7511 7540 8621 8622 8623 6382 5434 27018 9202 8082 7474 7687)
for port in "${ports[@]}"; do
    pids=$(lsof -ti ":$port" 2>/dev/null)
    if [ -n "$pids" ]; then
        echo "清理端口 $port..."
        echo "$pids" | xargs kill -9 2>/dev/null || true
    fi
done

# 4. 验证停止状态
echo "验证服务停止状态..."
cd "$PROJECT_ROOT"

# 检查Docker容器
echo "检查Docker容器状态..."
if docker ps | grep -q "future\|jobfirst"; then
    echo "⚠️  仍有容器在运行:"
    docker ps | grep "future\|jobfirst"
else
    echo "✅ 所有容器已停止"
fi

# 检查端口占用
echo "检查端口占用..."
running_ports=()
for port in "${ports[@]}"; do
    if lsof -i ":$port" >/dev/null 2>&1; then
        running_ports+=("$port")
    fi
done

if [ ${#running_ports[@]} -eq 0 ]; then
    echo "✅ 所有端口已清理"
else
    echo "⚠️  以下端口仍被占用: ${running_ports[*]}"
fi

echo ""
echo "✅ JobFirst Future版双AI服务架构停止完成！"
echo "=============================================="
echo "📊 停止统计:"
echo "  - 双AI服务架构: ✅ 已停止"
echo "  - 基础数据库: ✅ 已停止"
echo "  - 监控服务: ✅ 已停止"
echo "  - 端口清理: ✅ 已完成"
