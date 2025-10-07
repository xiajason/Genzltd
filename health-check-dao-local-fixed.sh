#!/bin/bash
# 修复后的本地DAO开发环境健康检查脚本

echo "🔍 检查本地DAO开发环境状态..."

# 定义项目根目录
PROJECT_ROOT="./looma_crm_future/services/dao_services"

# 1. 检查数据库连接
echo "🗄️ 检查数据库状态..."
if nc -z localhost 9506; then
    echo "✅ MySQL (端口9506): 连接正常"
else
    echo "❌ MySQL (端口9506): 连接异常"
fi
if nc -z localhost 9507; then
    echo "✅ Redis (端口9507): 连接正常"
else
    echo "❌ Redis (端口9507): 连接异常"
fi

# 2. 检查Docker容器状态
echo "🐳 检查Docker容器状态..."
cd $PROJECT_ROOT
MYSQL_CONTAINER_ID=$(docker ps -q -f name=dao-mysql-local)
REDIS_CONTAINER_ID=$(docker ps -q -f name=dao-redis-local)

if [ -n "$MYSQL_CONTAINER_ID" ]; then
    MYSQL_STATUS=$(docker inspect -f '{{.State.Status}} (health: {{.State.Health.Status}})' $MYSQL_CONTAINER_ID 2>/dev/null)
    echo "✅ MySQL容器 (dao-mysql-local): 运行正常"
    echo "   - 容器ID: $MYSQL_CONTAINER_ID"
    echo "   - 状态: $MYSQL_STATUS"
    docker port $MYSQL_CONTAINER_ID
else
    echo "❌ MySQL容器 (dao-mysql-local): 未运行或不存在"
fi

if [ -n "$REDIS_CONTAINER_ID" ]; then
    REDIS_STATUS=$(docker inspect -f '{{.State.Status}} (health: {{.State.Health.Status}})' $REDIS_CONTAINER_ID 2>/dev/null)
    echo "✅ Redis容器 (dao-redis-local): 运行正常"
    echo "   - 容器ID: $REDIS_CONTAINER_ID"
    echo "   - 状态: $REDIS_STATUS"
    docker port $REDIS_CONTAINER_ID
else
    echo "❌ Redis容器 (dao-redis-local): 未运行或不存在"
fi

# 3. 检查数据库健康状态 (通过Docker exec)
echo "🏥 检查数据库健康状态..."
if [ -n "$MYSQL_CONTAINER_ID" ] && docker exec dao-mysql-local mysqladmin ping -h localhost -u root -pdao_password_2024 > /dev/null 2>&1; then
    echo "✅ MySQL数据库: 健康检查通过"
else
    echo "❌ MySQL数据库: 健康检查失败"
fi

if [ -n "$REDIS_CONTAINER_ID" ] && docker exec dao-redis-local redis-cli ping > /dev/null 2>&1; then
    echo "✅ Redis缓存: 健康检查通过"
else
    echo "❌ Redis缓存: 健康检查失败"
fi

# 4. 检查DAO数据库结构和数据 (修复版本)
echo "📊 检查DAO数据库结构..."
if [ -n "$MYSQL_CONTAINER_ID" ] && docker exec dao-mysql-local mysql -u root -pdao_password_2024 -e "USE dao_governance; SHOW TABLES;" > /dev/null 2>&1; then
    echo "✅ DAO数据库表结构: 存在"
    
    # 检查成员数据 (修复版本)
    MEMBER_COUNT=$(docker exec dao-mysql-local mysql -u root -pdao_password_2024 -e "USE dao_governance; SELECT COUNT(*) FROM dao_members;" 2>/dev/null | tail -n 1 | tr -d ' ')
    if [ -n "$MEMBER_COUNT" ] && [ "$MEMBER_COUNT" -gt 0 ] 2>/dev/null; then
        echo "✅ DAO成员数据: $MEMBER_COUNT 条数据"
    else
        echo "⚠️ DAO成员数据: 无数据或查询失败"
    fi
    
    # 检查提案数据 (修复版本)
    PROPOSAL_COUNT=$(docker exec dao-mysql-local mysql -u root -pdao_password_2024 -e "USE dao_governance; SELECT COUNT(*) FROM dao_proposals;" 2>/dev/null | tail -n 1 | tr -d ' ')
    if [ -n "$PROPOSAL_COUNT" ] && [ "$PROPOSAL_COUNT" -gt 0 ] 2>/dev/null; then
        echo "✅ DAO提案数据: $PROPOSAL_COUNT 条数据"
    else
        echo "⚠️ DAO提案数据: 无数据或查询失败"
    fi
else
    echo "⚠️ DAO数据库表结构: 需要检查"
fi

# 5. 检查Redis信息
echo "📊 检查Redis信息..."
REDIS_INFO=""
if [ -n "$REDIS_CONTAINER_ID" ]; then
    REDIS_INFO=$(docker exec dao-redis-local redis-cli info 2>/dev/null)
fi
if [ -n "$REDIS_INFO" ]; then
    echo "✅ Redis服务信息: 正常"
    echo "   - redis_version: $(echo "$REDIS_INFO" | grep redis_version | cut -d: -f2)"
    echo "   - uptime_in_seconds: $(echo "$REDIS_INFO" | grep uptime_in_seconds | cut -d: -f2)"
else
    echo "❌ Redis服务信息: 异常"
fi

# 6. 检查项目目录结构
echo "📁 检查项目目录结构..."
if [ -d "$PROJECT_ROOT" ]; then
    echo "✅ DAO服务目录: 存在"
    for dir in resume job dao-governance ai logs config database; do
        if [ -d "$PROJECT_ROOT/$dir" ]; then
            echo "✅ $dir 目录: 存在"
        else
            echo "❌ $dir 目录: 不存在"
        fi
    done
    if [ -f "$PROJECT_ROOT/docker-compose.local.yml" ]; then
        echo "✅ docker-compose.local.yml: 存在"
    else
        echo "❌ docker-compose.local.yml: 不存在"
    fi
    if [ -f "$PROJECT_ROOT/config/development.env" ]; then
        echo "✅ config/development.env: 存在"
    else
        echo "⚠️ config/development.env: 不存在"
    fi
    if [ -f "$PROJECT_ROOT/database/init.sql" ]; then
        echo "✅ database/init.sql: 存在"
    else
        echo "❌ database/init.sql: 不存在"
    fi
else
    echo "❌ DAO服务根目录 ($PROJECT_ROOT): 不存在"
fi

# 7. 检查端口占用情况
echo "🔌 检查端口占用情况..."
check_port() {
    PORT=$1
    SERVICE=$2
    if lsof -i :$PORT > /dev/null; then
        echo "✅ 端口 $PORT: 被 $(lsof -i :$PORT | awk 'NR==2 {print $1}') 占用 (正常)"
    else
        echo "❌ 端口 $PORT: 未被占用 (异常)"
    fi
}
check_port 9506 "MySQL"
check_port 9507 "Redis"

# 8. 检查Docker资源使用情况
echo "💻 检查Docker资源使用情况..."
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"

# 9. 检查磁盘空间
echo "💾 检查磁盘空间..."
df -h

echo ""
echo "🎯 本地DAO开发环境检查完成！"
echo "📋 检查摘要:"
echo "  - 数据库连接: MySQL(9506), Redis(9507)"
echo "  - Docker容器: dao-mysql-local, dao-redis-local"
echo "  - 项目结构: $PROJECT_ROOT"
echo "  - 配置文件: docker-compose.local.yml, development.env, init.sql"
echo ""
echo "🚀 如果所有检查都通过，可以开始DAO服务开发！"
