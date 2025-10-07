#!/bin/bash

# 即插即用区块链微服务独立启动脚本
# 支持完全独立运行，不依赖现有微服务生态

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 区块链服务端口定义
BLOCKCHAIN_SERVICE_PORT=8301
IDENTITY_SERVICE_PORT=8302
GOVERNANCE_SERVICE_PORT=8303
CROSSCHAIN_SERVICE_PORT=8304
BLOCKCHAIN_GATEWAY_PORT=8401
BLOCKCHAIN_MONITOR_PORT=8402
BLOCKCHAIN_CONFIG_PORT=8403

# 数据库端口 (可选，支持独立数据库)
BLOCKCHAIN_MYSQL_PORT=3307
BLOCKCHAIN_POSTGRES_PORT=5433
BLOCKCHAIN_REDIS_PORT=6380

# 区块链配置
BLOCKCHAIN_MODE="${BLOCKCHAIN_MODE:-standalone}"  # standalone, integrated, hybrid
BLOCKCHAIN_CHAIN="${BLOCKCHAIN_CHAIN:-huawei}"    # huawei, ethereum, both
BLOCKCHAIN_DB="${BLOCKCHAIN_DB:-embedded}"        # embedded, mysql, postgres

echo -e "${BLUE}🚀 启动即插即用区块链微服务 (独立模式)${NC}"
echo -e "${CYAN}模式: $BLOCKCHAIN_MODE | 链: $BLOCKCHAIN_CHAIN | 数据库: $BLOCKCHAIN_DB${NC}"

# 检查端口是否被占用
check_port() {
    lsof -i :$1 >/dev/null 2>&1
    return $?
}

# 检查服务是否运行
check_service() {
    local service_name=$1
    local port=$2
    if check_port $port; then
        echo -e "${GREEN}[SUCCESS] $service_name 已在端口 $port 运行${NC}"
        return 0
    else
        echo -e "${RED}[ERROR] $service_name 未在端口 $port 运行${NC}"
        return 1
    fi
}

# 启动区块链数据库 (可选)
start_blockchain_databases() {
    if [ "$BLOCKCHAIN_DB" = "mysql" ]; then
        echo -e "${BLUE}[INFO] 启动区块链MySQL数据库 (端口: $BLOCKCHAIN_MYSQL_PORT)${NC}"
        # 这里可以启动独立的MySQL实例
    elif [ "$BLOCKCHAIN_DB" = "postgres" ]; then
        echo -e "${BLUE}[INFO] 启动区块链PostgreSQL数据库 (端口: $BLOCKCHAIN_POSTGRES_PORT)${NC}"
        # 这里可以启动独立的PostgreSQL实例
    else
        echo -e "${YELLOW}[INFO] 使用嵌入式数据库${NC}"
    fi
}

# 启动区块链核心服务
start_blockchain_services() {
    echo -e "${BLUE}[INFO] === 启动区块链核心服务 ===${NC}"
    
    # 1. 区块链配置服务
    echo -e "${PURPLE}[INFO] 启动区块链配置服务 (端口: $BLOCKCHAIN_CONFIG_PORT)${NC}"
    # 这里启动区块链配置服务
    
    # 2. 身份确权服务
    echo -e "${PURPLE}[INFO] 启动身份确权服务 (端口: $IDENTITY_SERVICE_PORT)${NC}"
    # 这里启动身份确权服务
    
    # 3. DAO治理服务
    echo -e "${PURPLE}[INFO] 启动DAO治理服务 (端口: $GOVERNANCE_SERVICE_PORT)${NC}"
    # 这里启动DAO治理服务
    
    # 4. 跨链聚合服务
    echo -e "${PURPLE}[INFO] 启动跨链聚合服务 (端口: $CROSSCHAIN_SERVICE_PORT)${NC}"
    # 这里启动跨链聚合服务
    
    # 5. 主区块链服务
    echo -e "${PURPLE}[INFO] 启动主区块链服务 (端口: $BLOCKCHAIN_SERVICE_PORT)${NC}"
    # 这里启动主区块链服务
}

# 启动区块链网关
start_blockchain_gateway() {
    echo -e "${BLUE}[INFO] === 启动区块链API网关 ===${NC}"
    echo -e "${PURPLE}[INFO] 启动区块链网关 (端口: $BLOCKCHAIN_GATEWAY_PORT)${NC}"
    # 这里启动区块链API网关
}

# 启动区块链监控
start_blockchain_monitoring() {
    echo -e "${BLUE}[INFO] === 启动区块链监控服务 ===${NC}"
    echo -e "${PURPLE}[INFO] 启动区块链监控 (端口: $BLOCKCHAIN_MONITOR_PORT)${NC}"
    # 这里启动区块链监控服务
}

# 健康检查
health_check() {
    echo -e "${BLUE}[INFO] === 区块链服务健康检查 ===${NC}"
    
    local all_healthy=true
    
    # 检查区块链核心服务
    check_service "区块链配置服务" $BLOCKCHAIN_CONFIG_PORT || all_healthy=false
    check_service "身份确权服务" $IDENTITY_SERVICE_PORT || all_healthy=false
    check_service "DAO治理服务" $GOVERNANCE_SERVICE_PORT || all_healthy=false
    check_service "跨链聚合服务" $CROSSCHAIN_SERVICE_PORT || all_healthy=false
    check_service "主区块链服务" $BLOCKCHAIN_SERVICE_PORT || all_healthy=false
    
    # 检查区块链网关
    check_service "区块链网关" $BLOCKCHAIN_GATEWAY_PORT || all_healthy=false
    
    # 检查区块链监控
    check_service "区块链监控" $BLOCKCHAIN_MONITOR_PORT || all_healthy=false
    
    if [ "$all_healthy" = true ]; then
        echo -e "${GREEN}[SUCCESS] 所有区块链服务健康运行${NC}"
        return 0
    else
        echo -e "${RED}[ERROR] 部分区块链服务未正常运行${NC}"
        return 1
    fi
}

# 集成模式检查
check_integration_mode() {
    if [ "$BLOCKCHAIN_MODE" = "integrated" ] || [ "$BLOCKCHAIN_MODE" = "hybrid" ]; then
        echo -e "${YELLOW}[INFO] 检查现有微服务生态...${NC}"
        
        # 检查Consul
        if check_port 8500; then
            echo -e "${GREEN}[SUCCESS] Consul服务发现可用${NC}"
        else
            echo -e "${YELLOW}[WARNING] Consul服务发现不可用，将使用独立模式${NC}"
            BLOCKCHAIN_MODE="standalone"
        fi
        
        # 检查API网关
        if check_port 8080; then
            echo -e "${GREEN}[SUCCESS] API网关可用${NC}"
        else
            echo -e "${YELLOW}[WARNING] API网关不可用，将使用独立网关${NC}"
        fi
    fi
}

# 主启动流程
main() {
    echo -e "${BLUE}🚀 即插即用区块链微服务启动中...${NC}"
    
    # 检查集成模式
    check_integration_mode
    
    # 启动数据库
    start_blockchain_databases
    
    # 启动区块链服务
    start_blockchain_services
    
    # 启动区块链网关
    start_blockchain_gateway
    
    # 启动区块链监控
    start_blockchain_monitoring
    
    # 等待服务启动
    echo -e "${YELLOW}[INFO] 等待服务启动...${NC}"
    sleep 5
    
    # 健康检查
    health_check
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}🎉 即插即用区块链微服务启动成功！${NC}"
        echo -e "${CYAN}区块链服务端口: $BLOCKCHAIN_SERVICE_PORT${NC}"
        echo -e "${CYAN}身份确权服务端口: $IDENTITY_SERVICE_PORT${NC}"
        echo -e "${CYAN}DAO治理服务端口: $GOVERNANCE_SERVICE_PORT${NC}"
        echo -e "${CYAN}跨链聚合服务端口: $CROSSCHAIN_SERVICE_PORT${NC}"
        echo -e "${CYAN}区块链网关端口: $BLOCKCHAIN_GATEWAY_PORT${NC}"
        echo -e "${CYAN}区块链监控端口: $BLOCKCHAIN_MONITOR_PORT${NC}"
    else
        echo -e "${RED}❌ 即插即用区块链微服务启动失败${NC}"
        exit 1
    fi
}

# 执行主流程
main "$@"
