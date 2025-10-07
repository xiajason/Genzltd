#!/bin/bash
# 本地DAO开发环境健康检查脚本

echo "🔍 检查本地DAO开发环境状态..."

# 检查数据库状态
echo "🗄️ 检查数据库状态..."
databases=("9506:MySQL" "9507:Redis")

for db in "${databases[@]}"; do
    port=$(echo $db | cut -d: -f1)
    name=$(echo $db | cut -d: -f2)
    
    if nc -z localhost $port; then
        echo "✅ $name (端口$port): 连接正常"
    else
        echo "❌ $name (端口$port): 连接异常"
    fi
done

# 检查Docker容器状态
echo "🐳 检查Docker容器状态..."
if docker ps | grep -q "dao-mysql-local"; then
    echo "✅ MySQL容器 (dao-mysql-local): 运行正常"
    # 获取容器详细信息
    echo "   - 容器ID: $(docker ps --filter name=dao-mysql-local --format '{{.ID}}')"
    echo "   - 状态: $(docker ps --filter name=dao-mysql-local --format '{{.Status}}')"
    echo "   - 端口映射: $(docker ps --filter name=dao-mysql-local --format '{{.Ports}}')"
else
    echo "❌ MySQL容器 (dao-mysql-local): 运行异常"
fi

if docker ps | grep -q "dao-redis-local"; then
    echo "✅ Redis容器 (dao-redis-local): 运行正常"
    # 获取容器详细信息
    echo "   - 容器ID: $(docker ps --filter name=dao-redis-local --format '{{.ID}}')"
    echo "   - 状态: $(docker ps --filter name=dao-redis-local --format '{{.Status}}')"
    echo "   - 端口映射: $(docker ps --filter name=dao-redis-local --format '{{.Ports}}')"
else
    echo "❌ Redis容器 (dao-redis-local): 运行异常"
fi

# 检查数据库健康状态
echo "🏥 检查数据库健康状态..."

# 检查MySQL健康状态
if docker exec dao-mysql-local mysqladmin ping -h localhost > /dev/null 2>&1; then
    echo "✅ MySQL数据库: 健康检查通过"
    
    # 检查数据库和表
    echo "📊 检查DAO数据库结构..."
    docker exec dao-mysql-local mysql -u dao_user -pdao_password_2024 -e "USE dao_governance; SHOW TABLES;" 2>/dev/null | grep -E "(dao_members|dao_proposals|dao_votes|dao_rewards|dao_activity_log)" && echo "✅ DAO数据库表结构: 正常" || echo "⚠️ DAO数据库表结构: 需要检查"
    
    # 检查示例数据
    member_count=$(docker exec dao-mysql-local mysql -u dao_user -pdao_password_2024 -e "USE dao_governance; SELECT COUNT(*) FROM dao_members;" 2>/dev/null | tail -1)
    if [ "$member_count" -gt 0 ]; then
        echo "✅ DAO成员数据: $member_count 条记录"
    else
        echo "⚠️ DAO成员数据: 无数据"
    fi
    
    proposal_count=$(docker exec dao-mysql-local mysql -u dao_user -pdao_password_2024 -e "USE dao_governance; SELECT COUNT(*) FROM dao_proposals;" 2>/dev/null | tail -1)
    if [ "$proposal_count" -gt 0 ]; then
        echo "✅ DAO提案数据: $proposal_count 条记录"
    else
        echo "⚠️ DAO提案数据: 无数据"
    fi
else
    echo "❌ MySQL数据库: 健康检查失败"
fi

# 检查Redis健康状态
if docker exec dao-redis-local redis-cli ping > /dev/null 2>&1; then
    echo "✅ Redis缓存: 健康检查通过"
    
    # 检查Redis信息
    echo "📊 检查Redis信息..."
    redis_info=$(docker exec dao-redis-local redis-cli info server 2>/dev/null | grep -E "(redis_version|uptime_in_seconds)")
    if [ -n "$redis_info" ]; then
        echo "✅ Redis服务信息: 正常"
        echo "$redis_info" | while read line; do
            echo "   - $line"
        done
    fi
else
    echo "❌ Redis缓存: 健康检查失败"
fi

# 检查项目目录结构
echo "📁 检查项目目录结构..."
if [ -d "looma_crm_future/services/dao_services" ]; then
    echo "✅ DAO服务目录: 存在"
    
    # 检查子目录
    subdirs=("resume" "job" "dao-governance" "ai" "logs" "config" "database")
    for subdir in "${subdirs[@]}"; do
        if [ -d "looma_crm_future/services/dao_services/$subdir" ]; then
            echo "✅ $subdir 目录: 存在"
        else
            echo "⚠️ $subdir 目录: 不存在"
        fi
    done
    
    # 检查配置文件
    config_files=("docker-compose.local.yml" "config/development.env" "database/init.sql")
    for config_file in "${config_files[@]}"; do
        if [ -f "looma_crm_future/services/dao_services/$config_file" ]; then
            echo "✅ $config_file: 存在"
        else
            echo "⚠️ $config_file: 不存在"
        fi
    done
else
    echo "❌ DAO服务目录: 不存在"
fi

# 检查端口占用情况
echo "🔌 检查端口占用情况..."
ports=("9506" "9507")
for port in "${ports[@]}"; do
    if lsof -i :$port > /dev/null 2>&1; then
        process=$(lsof -i :$port | tail -1 | awk '{print $1}')
        echo "✅ 端口 $port: 被 $process 占用 (正常)"
    else
        echo "❌ 端口 $port: 未被占用 (异常)"
    fi
done

# 检查Docker资源使用情况
echo "💻 检查Docker资源使用情况..."
echo "Docker容器资源使用:"
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}" | grep -E "(dao-mysql-local|dao-redis-local|Container)"

# 检查磁盘空间
echo "💾 检查磁盘空间..."
echo "可用磁盘空间:"
df -h | grep -E "(/dev/|Filesystem)"

echo ""
echo "🎯 本地DAO开发环境检查完成！"
echo "📋 检查摘要:"
echo "  - 数据库连接: MySQL(9506), Redis(9507)"
echo "  - Docker容器: dao-mysql-local, dao-redis-local"
echo "  - 项目结构: looma_crm_future/services/dao_services/"
echo "  - 配置文件: docker-compose.local.yml, development.env, init.sql"
echo ""
echo "🚀 如果所有检查都通过，可以开始DAO服务开发！"
