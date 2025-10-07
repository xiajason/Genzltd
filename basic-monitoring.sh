#!/bin/bash

# 基础监控脚本 - 基于数据库整合报告的统一架构
# 监控本地统一数据库服务状态

echo "🔍 基础监控检查 - $(date)"
echo "=================================="

# 检查MySQL服务 (统一端口3306)
echo "📊 MySQL服务状态 (端口3306):"
if lsof -i :3306 > /dev/null 2>&1; then
    echo "  ✅ MySQL服务运行正常"
    # 测试数据库连接
    if mysql -u root -e "SELECT 1 as test;" > /dev/null 2>&1; then
        echo "  ✅ 数据库连接正常"
    else
        echo "  ❌ 数据库连接失败"
    fi
else
    echo "  ❌ MySQL服务未运行"
fi

# 检查PostgreSQL服务 (统一端口5432)
echo ""
echo "📊 PostgreSQL服务状态 (端口5432):"
if lsof -i :5432 > /dev/null 2>&1; then
    echo "  ✅ PostgreSQL服务运行正常"
else
    echo "  ⚠️  PostgreSQL服务未运行 (可选)"
fi

# 检查Redis服务 (统一端口6379)
echo ""
echo "📊 Redis服务状态 (端口6379):"
if lsof -i :6379 > /dev/null 2>&1; then
    echo "  ✅ Redis服务运行正常"
else
    echo "  ⚠️  Redis服务未运行 (可选)"
fi

# 检查MongoDB服务 (统一端口27017)
echo ""
echo "📊 MongoDB服务状态 (端口27017):"
if lsof -i :27017 > /dev/null 2>&1; then
    echo "  ✅ MongoDB服务运行正常"
else
    echo "  ⚠️  MongoDB服务未运行 (可选)"
fi

# 检查Neo4j服务 (统一端口7474)
echo ""
echo "📊 Neo4j服务状态 (端口7474):"
if lsof -i :7474 > /dev/null 2>&1; then
    echo "  ✅ Neo4j服务运行正常"
else
    echo "  ⚠️  Neo4j服务未运行 (可选)"
fi

# 检查DAO前端服务 (端口3000)
echo ""
echo "📊 DAO前端服务状态 (端口3000):"
if lsof -i :3000 > /dev/null 2>&1; then
    echo "  ✅ DAO前端服务运行正常"
    # 测试健康检查端点
    if curl -s http://localhost:3000/api/health | grep -q "healthy"; then
        echo "  ✅ 健康检查端点正常"
    else
        echo "  ❌ 健康检查端点异常"
    fi
else
    echo "  ❌ DAO前端服务未运行"
fi

# 检查Future版服务 (端口7500-7540)
echo ""
echo "📊 Future版服务状态:"
future_ports=(7500 7510 7511 7512 7513 7514 7515 7516 7517 8000 8001 8002 7540)
running_services=0
for port in "${future_ports[@]}"; do
    if lsof -i :$port > /dev/null 2>&1; then
        ((running_services++))
    fi
done
echo "  📈 Future版服务运行数量: $running_services/${#future_ports[@]}"

# 检查区块链服务 (端口8301-8304)
echo ""
echo "📊 区块链服务状态:"
blockchain_ports=(8301 8302 8303 8304)
blockchain_running=0
for port in "${blockchain_ports[@]}"; do
    if lsof -i :$port > /dev/null 2>&1; then
        ((blockchain_running++))
    fi
done
echo "  📈 区块链服务运行数量: $blockchain_running/${#blockchain_ports[@]}"

# 系统资源使用情况
echo ""
echo "📊 系统资源使用:"
echo "  💾 内存使用: $(ps -o %mem= -p $$ | tr -d ' ')%"
echo "  💽 磁盘使用: $(df -h . | tail -1 | awk '{print $5}')"

echo ""
echo "✅ 基础监控检查完成 - $(date)"
