#!/bin/bash

# 腾讯云PostgreSQL权限测试脚本

echo "🔍 腾讯云PostgreSQL权限测试 - $(date)"
echo "=================================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 腾讯云配置
TENCENT_IP="101.33.251.158"
TENCENT_USER="ubuntu"
SSH_KEY="~/.ssh/basic.pem"

echo -e "${BLUE}🎯 测试腾讯云PostgreSQL权限...${NC}"

# 测试不同的用户和数据库组合
test_postgresql_connection() {
    local user=$1
    local database=$2
    local description=$3
    
    echo -e "${BLUE}📊 测试连接: $user@$database ($description)${NC}"
    
    # 测试连接
    if ssh -i $SSH_KEY $TENCENT_USER@$TENCENT_IP "docker exec dao-postgres psql -U $user -d $database -c 'SELECT version();'" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ 连接成功: $user@$database${NC}"
        
        # 测试表创建权限
        if ssh -i $SSH_KEY $TENCENT_USER@$TENCENT_IP "docker exec dao-postgres psql -U $user -d $database -c 'CREATE TABLE IF NOT EXISTS test_permissions_table (id SERIAL PRIMARY KEY, name TEXT);'" > /dev/null 2>&1; then
            echo -e "${GREEN}✅ 表创建成功: $user@$database${NC}"
            
            # 测试表查询权限
            if ssh -i $SSH_KEY $TENCENT_USER@$TENCENT_IP "docker exec dao-postgres psql -U $user -d $database -c 'SELECT COUNT(*) FROM test_permissions_table;'" > /dev/null 2>&1; then
                echo -e "${GREEN}✅ 表查询成功: $user@$database${NC}"
                
                # 清理测试表
                ssh -i $SSH_KEY $TENCENT_USER@$TENCENT_IP "docker exec dao-postgres psql -U $user -d $database -c 'DROP TABLE IF EXISTS test_permissions_table;'" > /dev/null 2>&1
                echo -e "${GREEN}✅ 表清理完成: $user@$database${NC}"
                return 0
            else
                echo -e "${RED}❌ 表查询失败: $user@$database${NC}"
                return 1
            fi
        else
            echo -e "${RED}❌ 表创建失败: $user@$database${NC}"
            return 1
        fi
    else
        echo -e "${RED}❌ 连接失败: $user@$database${NC}"
        return 1
    fi
}

# 测试不同的用户和数据库组合
echo -e "${BLUE}📋 测试不同的用户和数据库组合...${NC}"

# 1. 测试admin用户
test_postgresql_connection "admin" "postgres" "超级管理员用户"
test_postgresql_connection "admin" "dao_vector" "超级管理员访问dao_vector数据库"

# 2. 测试dao_user用户
test_postgresql_connection "dao_user" "dao_vector" "DAO用户访问dao_vector数据库"
test_postgresql_connection "dao_user" "postgres" "DAO用户访问postgres数据库"

# 3. 测试postgres用户
test_postgresql_connection "postgres" "postgres" "默认postgres用户"
test_postgresql_connection "postgres" "dao_vector" "postgres用户访问dao_vector数据库"

echo ""
echo -e "${BLUE}🔍 检查腾讯云PostgreSQL容器状态...${NC}"

# 检查容器状态
ssh -i $SSH_KEY $TENCENT_USER@$TENCENT_IP "docker ps | grep postgres"

echo ""
echo -e "${BLUE}🔍 检查PostgreSQL用户列表...${NC}"

# 查看用户列表
ssh -i $SSH_KEY $TENCENT_USER@$TENCENT_IP "docker exec dao-postgres psql -U postgres -d postgres -c '\du'"

echo ""
echo -e "${BLUE}🔍 检查数据库列表...${NC}"

# 查看数据库列表
ssh -i $SSH_KEY $TENCENT_USER@$TENCENT_IP "docker exec dao-postgres psql -U postgres -d postgres -c '\l'"

echo ""
echo -e "${GREEN}🎉 腾讯云PostgreSQL权限测试完成 - $(date)${NC}"
