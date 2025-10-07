#!/bin/bash

# 即插即用区块链微服务健康检查脚本
# 检查所有区块链服务的运行状态

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

# 区块链数据库端口
BLOCKCHAIN_MYSQL_PORT=3307
BLOCKCHAIN_POSTGRES_PORT=5433
BLOCKCHAIN_REDIS_PORT=6380

# 统计变量
total_services=0
running_services=0
healthy_services=0

echo -e "${BLUE}🔍 即插即用区块链微服务健康检查${NC}"

# 检查端口是否被占用
check_port() {
    lsof -i :$1 >/dev/null 2>&1
    return $?
}

# 检查服务健康状态
check_service_health() {
    local service_name=$1
    local port=$2
    local health_endpoint=$3
    
    total_services=$((total_services + 1))
    
    if check_port $port; then
        running_services=$((running_services + 1))
        echo -e "${GREEN}[RUNNING] $service_name (端口: $port)${NC}"
        
        # 检查健康端点
        if [ -n "$health_endpoint" ]; then
            local health_url="http://localhost:$port$health_endpoint"
            local health_response=$(curl -s -o /dev/null -w "%{http_code}" "$health_url" 2>/dev/null)
            
            if [ "$health_response" = "200" ]; then
                healthy_services=$((healthy_services + 1))
                echo -e "  ${GREEN}✅ 健康检查通过${NC}"
            else
                echo -e "  ${YELLOW}⚠️  健康检查失败 (HTTP: $health_response)${NC}"
            fi
        else
            healthy_services=$((healthy_services + 1))
            echo -e "  ${GREEN}✅ 服务运行正常${NC}"
        fi
    else
        echo -e "${RED}[STOPPED] $service_name (端口: $port)${NC}"
    fi
}

# 检查区块链核心服务
check_blockchain_services() {
    echo -e "${BLUE}[INFO] === 区块链核心服务状态 ===${NC}"
    
    check_service_health "区块链配置服务" $BLOCKCHAIN_CONFIG_PORT "/health"
    check_service_health "身份确权服务" $IDENTITY_SERVICE_PORT "/health"
    check_service_health "DAO治理服务" $GOVERNANCE_SERVICE_PORT "/health"
    check_service_health "跨链聚合服务" $CROSSCHAIN_SERVICE_PORT "/health"
    check_service_health "主区块链服务" $BLOCKCHAIN_SERVICE_PORT "/health"
}

# 检查区块链网关
check_blockchain_gateway() {
    echo -e "${BLUE}[INFO] === 区块链API网关状态 ===${NC}"
    
    check_service_health "区块链网关" $BLOCKCHAIN_GATEWAY_PORT "/health"
}

# 检查区块链监控
check_blockchain_monitoring() {
    echo -e "${BLUE}[INFO] === 区块链监控服务状态 ===${NC}"
    
    check_service_health "区块链监控" $BLOCKCHAIN_MONITOR_PORT "/health"
}

# 检查区块链数据库
check_blockchain_databases() {
    echo -e "${BLUE}[INFO] === 区块链数据库服务状态 ===${NC}"
    
    check_service_health "区块链MySQL" $BLOCKCHAIN_MYSQL_PORT
    check_service_health "区块链PostgreSQL" $BLOCKCHAIN_POSTGRES_PORT
    check_service_health "区块链Redis" $BLOCKCHAIN_REDIS_PORT
}

# 检查区块链相关进程
check_blockchain_processes() {
    echo -e "${BLUE}[INFO] === 区块链相关进程状态 ===${NC}"
    
    local blockchain_processes=$(ps aux | grep -E "(blockchain|identity|governance|crosschain)" | grep -v grep | wc -l)
    
    if [ "$blockchain_processes" -gt 0 ]; then
        echo -e "${GREEN}[INFO] 发现 $blockchain_processes 个区块链相关进程${NC}"
        ps aux | grep -E "(blockchain|identity|governance|crosschain)" | grep -v grep | while read line; do
            echo -e "  ${CYAN}$line${NC}"
        done
    else
        echo -e "${YELLOW}[INFO] 未发现区块链相关进程${NC}"
    fi
}

# 检查区块链相关文件
check_blockchain_files() {
    echo -e "${BLUE}[INFO] === 区块链相关文件状态 ===${NC}"
    
    # 检查配置文件
    if [ -f "./config/blockchain-config.yaml" ]; then
        echo -e "${GREEN}[INFO] 区块链配置文件存在${NC}"
    else
        echo -e "${YELLOW}[WARNING] 区块链配置文件不存在${NC}"
    fi
    
    # 检查日志文件
    if [ -d "./logs/blockchain" ]; then
        local log_count=$(find ./logs/blockchain -name "*.log" | wc -l)
        echo -e "${GREEN}[INFO] 发现 $log_count 个区块链日志文件${NC}"
    else
        echo -e "${YELLOW}[WARNING] 区块链日志目录不存在${NC}"
    fi
    
    # 检查PID文件
    local pid_files=$(find . -name "*.blockchain.pid" -o -name "*.identity.pid" -o -name "*.governance.pid" -o -name "*.crosschain.pid" 2>/dev/null | wc -l)
    if [ "$pid_files" -gt 0 ]; then
        echo -e "${YELLOW}[WARNING] 发现 $pid_files 个PID文件${NC}"
    else
        echo -e "${GREEN}[INFO] 未发现PID文件${NC}"
    fi
}

# 计算运行率
calculate_running_rate() {
    if [ $total_services -eq 0 ]; then
        echo "0%"
    else
        local rate=$((running_services * 100 / total_services))
        echo "${rate}%"
    fi
}

# 计算健康率
calculate_health_rate() {
    if [ $total_services -eq 0 ]; then
        echo "0%"
    else
        local rate=$((healthy_services * 100 / total_services))
        echo "${rate}%"
    fi
}

# 生成状态报告
generate_status_report() {
    echo -e "${BLUE}[INFO] === 区块链服务状态报告 ===${NC}"
    
    local running_rate=$(calculate_running_rate)
    local health_rate=$(calculate_health_rate)
    
    echo -e "${CYAN}总服务数: $total_services${NC}"
    echo -e "${CYAN}运行服务数: $running_services${NC}"
    echo -e "${CYAN}健康服务数: $healthy_services${NC}"
    echo -e "${CYAN}运行率: $running_rate${NC}"
    echo -e "${CYAN}健康率: $health_rate${NC}"
    
    # 根据状态给出建议
    if [ $running_services -eq $total_services ] && [ $healthy_services -eq $total_services ]; then
        echo -e "${GREEN}🎉 所有区块链服务运行正常！${NC}"
        return 0
    elif [ $running_services -eq $total_services ]; then
        echo -e "${YELLOW}⚠️  所有服务已运行，但部分服务健康检查失败${NC}"
        return 1
    elif [ $running_services -gt 0 ]; then
        echo -e "${YELLOW}⚠️  部分区块链服务未运行${NC}"
        return 1
    else
        echo -e "${RED}❌ 所有区块链服务未运行${NC}"
        return 1
    fi
}

# 主检查流程
main() {
    echo -e "${BLUE}🔍 即插即用区块链微服务健康检查中...${NC}"
    
    # 检查区块链服务
    check_blockchain_services
    
    # 检查区块链网关
    check_blockchain_gateway
    
    # 检查区块链监控
    check_blockchain_monitoring
    
    # 检查区块链数据库
    check_blockchain_databases
    
    # 检查区块链相关进程
    check_blockchain_processes
    
    # 检查区块链相关文件
    check_blockchain_files
    
    # 生成状态报告
    generate_status_report
    
    return $?
}

# 执行主流程
main "$@"
