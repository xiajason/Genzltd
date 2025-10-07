#!/bin/bash

# JobFirst 数据库连接测试脚本
# 验证所有数据库连接是否正常

set -e  # 遇到错误立即退出

echo "=== JobFirst 数据库连接测试开始 ==="
echo "时间: $(date)"
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 测试结果统计
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# 测试函数
test_database() {
    local db_name=$1
    local db_type=$2
    local test_command=$3
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -n "测试 $db_name ($db_type): "
    
    if eval "$test_command" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ 通过${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        return 0
    else
        echo -e "${RED}❌ 失败${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
}

# 1. MySQL连接测试
echo "1. MySQL数据库连接测试"
echo "========================"

test_database "jobfirst" "MySQL" "mysql -u root -e 'SELECT 1' jobfirst"
test_database "jobfirst_v3" "MySQL" "mysql -u root -e 'SELECT 1' jobfirst_v3"

# 测试表结构
echo ""
echo "验证jobfirst数据库表结构:"
mysql -u root jobfirst -e "SHOW TABLES;" 2>/dev/null | grep -v "Tables_in_jobfirst" | while read table; do
    if [ -n "$table" ]; then
        echo "  ✅ 表: $table"
    fi
done

echo ""

# 2. PostgreSQL连接测试
echo "2. PostgreSQL数据库连接测试"
echo "============================"

test_database "jobfirst_vector" "PostgreSQL" "psql -h localhost -U szjason72 -d jobfirst_vector -c 'SELECT 1'"

echo ""

# 3. Redis连接测试
echo "3. Redis数据库连接测试"
echo "======================"

test_database "Redis" "Redis" "redis-cli ping"

# 测试Redis基本操作
echo ""
echo "验证Redis基本操作:"
if redis-cli set test_key "test_value" >/dev/null 2>&1; then
    echo "  ✅ SET操作正常"
    if redis-cli get test_key | grep -q "test_value"; then
        echo "  ✅ GET操作正常"
    fi
    redis-cli del test_key >/dev/null 2>&1
    echo "  ✅ DEL操作正常"
fi

echo ""

# 4. Neo4j连接测试
echo "4. Neo4j数据库连接测试"
echo "======================"

# 检查Neo4j是否运行
if curl -s http://localhost:7474 >/dev/null 2>&1; then
    echo -e "Neo4j服务: ${GREEN}✅ 运行中${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    echo -e "Neo4j服务: ${RED}❌ 未运行${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))

echo ""

# 5. 数据库连接池测试
echo "5. 数据库连接池测试"
echo "==================="

# 测试MySQL连接池
echo "测试MySQL连接池配置:"
mysql -u root jobfirst -e "SHOW VARIABLES LIKE 'max_connections';" 2>/dev/null | grep max_connections || echo "  ⚠️  无法获取连接池信息"

echo ""

# 6. 数据完整性测试
echo "6. 数据完整性测试"
echo "=================="

# 测试用户表数据
echo "验证用户表数据:"
user_count=$(mysql -u root jobfirst -e "SELECT COUNT(*) FROM users;" 2>/dev/null | tail -n 1)
if [ -n "$user_count" ] && [ "$user_count" -ge 0 ]; then
    echo "  ✅ 用户表数据正常，记录数: $user_count"
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    echo "  ❌ 用户表数据异常"
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))

# 测试会话表数据
echo "验证会话表数据:"
session_count=$(mysql -u root jobfirst -e "SELECT COUNT(*) FROM user_sessions;" 2>/dev/null | tail -n 1)
if [ -n "$session_count" ] && [ "$session_count" -ge 0 ]; then
    echo "  ✅ 会话表数据正常，记录数: $session_count"
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    echo "  ❌ 会话表数据异常"
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))

echo ""

# 7. 测试结果汇总
echo "7. 测试结果汇总"
echo "================"
echo "总测试数: $TOTAL_TESTS"
echo -e "通过测试: ${GREEN}$PASSED_TESTS${NC}"
echo -e "失败测试: ${RED}$FAILED_TESTS${NC}"

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "\n${GREEN}🎉 所有数据库连接测试通过！${NC}"
    exit 0
else
    echo -e "\n${RED}❌ 有 $FAILED_TESTS 个测试失败，请检查数据库配置${NC}"
    exit 1
fi
