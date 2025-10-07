#!/bin/bash

# 即插即用区块链微服务独立停止脚本
# 优雅停止所有区块链服务

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

echo -e "${BLUE}🛑 停止即插即用区块链微服务...${NC}"

# 停止区块链服务进程
stop_service() {
    local service_name=$1
    local port=$2
    
    echo -e "${YELLOW}[INFO] 停止 $service_name (端口: $port)${NC}"
    
    # 查找并停止占用端口的进程
    local pid=$(lsof -ti :$port 2>/dev/null)
    if [ -n "$pid" ]; then
        echo -e "${PURPLE}[INFO] 发现进程 PID: $pid${NC}"
        kill -TERM $pid 2>/dev/null
        
        # 等待进程优雅退出
        local count=0
        while [ $count -lt 10 ] && kill -0 $pid 2>/dev/null; do
            sleep 1
            count=$((count + 1))
        done
        
        # 如果进程仍在运行，强制终止
        if kill -0 $pid 2>/dev/null; then
            echo -e "${YELLOW}[WARNING] 进程未响应，强制终止${NC}"
            kill -KILL $pid 2>/dev/null
        fi
        
        echo -e "${GREEN}[SUCCESS] $service_name 已停止${NC}"
    else
        echo -e "${CYAN}[INFO] $service_name 未运行${NC}"
    fi
}

# 停止区块链核心服务
stop_blockchain_services() {
    echo -e "${BLUE}[INFO] === 停止区块链核心服务 ===${NC}"
    
    stop_service "区块链配置服务" $BLOCKCHAIN_CONFIG_PORT
    stop_service "身份确权服务" $IDENTITY_SERVICE_PORT
    stop_service "DAO治理服务" $GOVERNANCE_SERVICE_PORT
    stop_service "跨链聚合服务" $CROSSCHAIN_SERVICE_PORT
    stop_service "主区块链服务" $BLOCKCHAIN_SERVICE_PORT
}

# 停止区块链网关
stop_blockchain_gateway() {
    echo -e "${BLUE}[INFO] === 停止区块链API网关 ===${NC}"
    stop_service "区块链网关" $BLOCKCHAIN_GATEWAY_PORT
}

# 停止区块链监控
stop_blockchain_monitoring() {
    echo -e "${BLUE}[INFO] === 停止区块链监控服务 ===${NC}"
    stop_service "区块链监控" $BLOCKCHAIN_MONITOR_PORT
}

# 停止区块链数据库
stop_blockchain_databases() {
    echo -e "${BLUE}[INFO] === 停止区块链数据库服务 ===${NC}"
    stop_service "区块链MySQL" $BLOCKCHAIN_MYSQL_PORT
    stop_service "区块链PostgreSQL" $BLOCKCHAIN_POSTGRES_PORT
    stop_service "区块链Redis" $BLOCKCHAIN_REDIS_PORT
}

# 清理区块链相关进程
cleanup_blockchain_processes() {
    echo -e "${BLUE}[INFO] === 清理区块链相关进程 ===${NC}"
    
    # 查找所有区块链相关进程
    local blockchain_pids=$(ps aux | grep -E "(blockchain|identity|governance|crosschain)" | grep -v grep | awk '{print $2}')
    
    if [ -n "$blockchain_pids" ]; then
        echo -e "${YELLOW}[INFO] 发现区块链相关进程: $blockchain_pids${NC}"
        for pid in $blockchain_pids; do
            echo -e "${PURPLE}[INFO] 终止进程 PID: $pid${NC}"
            kill -TERM $pid 2>/dev/null
        done
        
        # 等待进程退出
        sleep 3
        
        # 检查是否还有残留进程
        local remaining_pids=$(ps aux | grep -E "(blockchain|identity|governance|crosschain)" | grep -v grep | awk '{print $2}')
        if [ -n "$remaining_pids" ]; then
            echo -e "${YELLOW}[WARNING] 发现残留进程，强制清理${NC}"
            for pid in $remaining_pids; do
                kill -KILL $pid 2>/dev/null
            done
        fi
    else
        echo -e "${CYAN}[INFO] 未发现区块链相关进程${NC}"
    fi
}

# 清理区块链相关文件
cleanup_blockchain_files() {
    echo -e "${BLUE}[INFO] === 清理区块链相关文件 ===${NC}"
    
    # 清理临时文件
    if [ -d "/tmp/blockchain" ]; then
        echo -e "${PURPLE}[INFO] 清理临时文件: /tmp/blockchain${NC}"
        rm -rf /tmp/blockchain
    fi
    
    # 清理日志文件
    if [ -d "./logs/blockchain" ]; then
        echo -e "${PURPLE}[INFO] 清理日志文件: ./logs/blockchain${NC}"
        rm -rf ./logs/blockchain
    fi
    
    # 清理PID文件
    find . -name "*.blockchain.pid" -delete 2>/dev/null
    find . -name "*.identity.pid" -delete 2>/dev/null
    find . -name "*.governance.pid" -delete 2>/dev/null
    find . -name "*.crosschain.pid" -delete 2>/dev/null
}

# 验证停止结果
verify_stop() {
    echo -e "${BLUE}[INFO] === 验证停止结果 ===${NC}"
    
    local all_stopped=true
    
    # 检查端口是否已释放
    local ports=($BLOCKCHAIN_SERVICE_PORT $IDENTITY_SERVICE_PORT $GOVERNANCE_SERVICE_PORT $CROSSCHAIN_SERVICE_PORT $BLOCKCHAIN_GATEWAY_PORT $BLOCKCHAIN_MONITOR_PORT $BLOCKCHAIN_CONFIG_PORT)
    
    for port in "${ports[@]}"; do
        if lsof -i :$port >/dev/null 2>&1; then
            echo -e "${RED}[ERROR] 端口 $port 仍被占用${NC}"
            all_stopped=false
        else
            echo -e "${GREEN}[SUCCESS] 端口 $port 已释放${NC}"
        fi
    done
    
    if [ "$all_stopped" = true ]; then
        echo -e "${GREEN}🎉 所有区块链服务已成功停止${NC}"
        return 0
    else
        echo -e "${RED}❌ 部分区块链服务停止失败${NC}"
        return 1
    fi
}

# 主停止流程
main() {
    echo -e "${BLUE}🛑 即插即用区块链微服务停止中...${NC}"
    
    # 停止区块链服务
    stop_blockchain_services
    
    # 停止区块链网关
    stop_blockchain_gateway
    
    # 停止区块链监控
    stop_blockchain_monitoring
    
    # 停止区块链数据库
    stop_blockchain_databases
    
    # 清理区块链相关进程
    cleanup_blockchain_processes
    
    # 清理区块链相关文件
    cleanup_blockchain_files
    
    # 验证停止结果
    verify_stop
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}🎉 即插即用区块链微服务停止成功！${NC}"
    else
        echo -e "${RED}❌ 即插即用区块链微服务停止失败${NC}"
        exit 1
    fi
}

# 执行主流程
main "$@"
