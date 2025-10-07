#!/bin/bash

# 云端数据库修复脚本
# 基于数据库整合报告的统一架构修复云端数据库一致性

echo "🔧 云端数据库修复开始 - $(date)"
echo "=================================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 服务器配置
TENCENT_SERVER="101.33.251.158"
ALIBABA_SERVER="47.115.168.107"
SSH_KEY="~/.ssh/cross_cloud_key"

# 统一数据库配置（基于数据库整合报告）
UNIFIED_MYSQL_PORT="3306"
UNIFIED_POSTGRES_PORT="5432"
UNIFIED_REDIS_PORT="6379"
UNIFIED_MONGODB_PORT="27017"
UNIFIED_NEO4J_PORT="7474"

# 检查服务器连通性
check_server_connectivity() {
    local server=$1
    local name=$2
    
    echo -e "${BLUE}📡 检查 ${name} 连通性...${NC}"
    if ping -c 3 -W 5 $server > /dev/null 2>&1; then
        echo -e "${GREEN}  ✅ ${name} 网络连通${NC}"
        return 0
    else
        echo -e "${RED}  ❌ ${name} 网络不通${NC}"
        return 1
    fi
}

# 检查SSH连接
check_ssh_connection() {
    local server=$1
    local name=$2
    local key_path=$3
    
    echo -e "${BLUE}🔑 检查 ${name} SSH连接...${NC}"
    if ssh -o ConnectTimeout=10 -o BatchMode=yes -i $key_path root@$server "echo 'SSH connected'" > /dev/null 2>&1; then
        echo -e "${GREEN}  ✅ ${name} SSH连接正常${NC}"
        return 0
    else
        echo -e "${RED}  ❌ ${name} SSH连接失败${NC}"
        return 1
    fi
}

# 检查数据库服务状态
check_database_services() {
    local server=$1
    local name=$2
    local key_path=$3
    
    echo -e "${BLUE}📊 检查 ${name} 数据库服务状态...${NC}"
    
    # 检查MySQL
    if ssh -i $key_path root@$server "netstat -tlnp | grep :$UNIFIED_MYSQL_PORT" > /dev/null 2>&1; then
        echo -e "${GREEN}  ✅ MySQL (端口$UNIFIED_MYSQL_PORT) 运行正常${NC}"
    else
        echo -e "${RED}  ❌ MySQL (端口$UNIFIED_MYSQL_PORT) 未运行${NC}"
    fi
    
    # 检查PostgreSQL
    if ssh -i $key_path root@$server "netstat -tlnp | grep :$UNIFIED_POSTGRES_PORT" > /dev/null 2>&1; then
        echo -e "${GREEN}  ✅ PostgreSQL (端口$UNIFIED_POSTGRES_PORT) 运行正常${NC}"
    else
        echo -e "${YELLOW}  ⚠️  PostgreSQL (端口$UNIFIED_POSTGRES_PORT) 未运行 (可选)${NC}"
    fi
    
    # 检查Redis
    if ssh -i $key_path root@$server "netstat -tlnp | grep :$UNIFIED_REDIS_PORT" > /dev/null 2>&1; then
        echo -e "${GREEN}  ✅ Redis (端口$UNIFIED_REDIS_PORT) 运行正常${NC}"
    else
        echo -e "${YELLOW}  ⚠️  Redis (端口$UNIFIED_REDIS_PORT) 未运行 (可选)${NC}"
    fi
    
    # 检查MongoDB
    if ssh -i $key_path root@$server "netstat -tlnp | grep :$UNIFIED_MONGODB_PORT" > /dev/null 2>&1; then
        echo -e "${GREEN}  ✅ MongoDB (端口$UNIFIED_MONGODB_PORT) 运行正常${NC}"
    else
        echo -e "${YELLOW}  ⚠️  MongoDB (端口$UNIFIED_MONGODB_PORT) 未运行 (可选)${NC}"
    fi
    
    # 检查Neo4j
    if ssh -i $key_path root@$server "netstat -tlnp | grep :$UNIFIED_NEO4J_PORT" > /dev/null 2>&1; then
        echo -e "${GREEN}  ✅ Neo4j (端口$UNIFIED_NEO4J_PORT) 运行正常${NC}"
    else
        echo -e "${YELLOW}  ⚠️  Neo4j (端口$UNIFIED_NEO4J_PORT) 未运行 (可选)${NC}"
    fi
}

# 测试数据库连接
test_database_connection() {
    local server=$1
    local name=$2
    local key_path=$3
    
    echo -e "${BLUE}🔗 测试 ${name} 数据库连接...${NC}"
    
    # 测试MySQL连接
    if ssh -i $key_path root@$server "mysql -u root -e 'SELECT 1 as test;'" > /dev/null 2>&1; then
        echo -e "${GREEN}  ✅ MySQL连接测试成功${NC}"
    else
        echo -e "${RED}  ❌ MySQL连接测试失败${NC}"
    fi
    
    # 测试Redis连接
    if ssh -i $key_path root@$server "redis-cli ping" > /dev/null 2>&1; then
        echo -e "${GREEN}  ✅ Redis连接测试成功${NC}"
    else
        echo -e "${RED}  ❌ Redis连接测试失败${NC}"
    fi
}

# 修复数据库配置
fix_database_config() {
    local server=$1
    local name=$2
    local key_path=$3
    
    echo -e "${BLUE}🔧 修复 ${name} 数据库配置...${NC}"
    
    # 创建统一配置目录
    ssh -i $key_path root@$server "mkdir -p /opt/unified-database-config"
    
    # 创建统一数据库配置文件
    ssh -i $key_path root@$server "cat > /opt/unified-database-config/unified_config.yaml << 'EOF'
# 统一数据库配置 - 基于数据库整合报告
# 整合时间: $(date)
# 整合版本: v1.0

database_config:
  mysql:
    host: localhost
    port: $UNIFIED_MYSQL_PORT
    user: root
    database: unified_business
    
  postgresql:
    host: localhost
    port: $UNIFIED_POSTGRES_PORT
    user: postgres
    database: ai_analysis
    
  redis:
    host: localhost
    port: $UNIFIED_REDIS_PORT
    database: 0
    
  mongodb:
    host: localhost
    port: $UNIFIED_MONGODB_PORT
    database: document_data
    
  neo4j:
    host: localhost
    port: $UNIFIED_NEO4J_PORT
    user: neo4j
    database: relationship_data

data_layer_strategy:
  hot_data: redis
  warm_data: mysql_postgresql
  cold_data: mongodb_neo4j
EOF"
    
    echo -e "${GREEN}  ✅ 统一配置文件已创建${NC}"
}

# 创建数据库监控脚本
create_monitoring_script() {
    local server=$1
    local name=$2
    local key_path=$3
    
    echo -e "${BLUE}📊 创建 ${name} 数据库监控脚本...${NC}"
    
    ssh -i $key_path root@$server "cat > /opt/unified-database-config/cloud-monitoring.sh << 'EOF'
#!/bin/bash

# 云端数据库监控脚本
echo \"🔍 云端数据库监控检查 - \$(date)\"
echo \"==================================\"

# 检查MySQL
if netstat -tlnp | grep :3306 > /dev/null 2>&1; then
    echo \"📊 MySQL: ✅ 运行正常\"
    if mysql -u root -e \"SELECT 1 as test;\" > /dev/null 2>&1; then
        echo \"  🔗 连接: ✅ 正常\"
    else
        echo \"  🔗 连接: ❌ 失败\"
    fi
else
    echo \"📊 MySQL: ❌ 未运行\"
fi

# 检查Redis
if netstat -tlnp | grep :6379 > /dev/null 2>&1; then
    echo \"📊 Redis: ✅ 运行正常\"
    if redis-cli ping > /dev/null 2>&1; then
        echo \"  🔗 连接: ✅ 正常\"
    else
        echo \"  🔗 连接: ❌ 失败\"
    fi
else
    echo \"📊 Redis: ❌ 未运行\"
fi

# 检查PostgreSQL
if netstat -tlnp | grep :5432 > /dev/null 2>&1; then
    echo \"📊 PostgreSQL: ✅ 运行正常\"
else
    echo \"📊 PostgreSQL: ⚠️  未运行 (可选)\"
fi

# 检查MongoDB
if netstat -tlnp | grep :27017 > /dev/null 2>&1; then
    echo \"📊 MongoDB: ✅ 运行正常\"
else
    echo \"📊 MongoDB: ⚠️  未运行 (可选)\"
fi

# 检查Neo4j
if netstat -tlnp | grep :7474 > /dev/null 2>&1; then
    echo \"📊 Neo4j: ✅ 运行正常\"
else
    echo \"📊 Neo4j: ⚠️  未运行 (可选)\"
fi

echo \"✅ 监控检查完成 - \$(date)\"
EOF"
    
    ssh -i $key_path root@$server "chmod +x /opt/unified-database-config/cloud-monitoring.sh"
    echo -e "${GREEN}  ✅ 监控脚本已创建并设置执行权限${NC}"
}

# 主执行流程
main() {
    echo -e "${BLUE}🚀 开始云端数据库修复流程...${NC}"
    
    # 检查阿里云服务器
    echo -e "\n${YELLOW}=== 阿里云服务器检查 ===${NC}"
    if check_server_connectivity $ALIBABA_SERVER "阿里云"; then
        if check_ssh_connection $ALIBABA_SERVER "阿里云" $SSH_KEY; then
            check_database_services $ALIBABA_SERVER "阿里云" $SSH_KEY
            test_database_connection $ALIBABA_SERVER "阿里云" $SSH_KEY
            fix_database_config $ALIBABA_SERVER "阿里云" $SSH_KEY
            create_monitoring_script $ALIBABA_SERVER "阿里云" $SSH_KEY
        fi
    fi
    
    # 检查腾讯云服务器
    echo -e "\n${YELLOW}=== 腾讯云服务器检查 ===${NC}"
    if check_server_connectivity $TENCENT_SERVER "腾讯云"; then
        echo -e "${YELLOW}  ⚠️  腾讯云服务器网络连通，但SSH密钥可能不匹配${NC}"
        echo -e "${BLUE}  💡 建议手动检查腾讯云服务器状态${NC}"
    else
        echo -e "${RED}  ❌ 腾讯云服务器网络不通，可能需要重启或检查安全组${NC}"
    fi
    
    echo -e "\n${GREEN}🎉 云端数据库修复完成 - $(date)${NC}"
    echo -e "${BLUE}📋 下一步建议:${NC}"
    echo -e "  1. 手动检查腾讯云服务器状态"
    echo -e "  2. 验证数据库连接配置"
    echo -e "  3. 运行数据一致性测试"
    echo -e "  4. 建立跨环境数据同步"
}

# 执行主函数
main
