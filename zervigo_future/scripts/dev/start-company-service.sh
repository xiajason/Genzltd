#!/bin/bash

# Company Service 启动脚本
echo "🏢 启动Company Service..."

# 设置颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 服务配置
SERVICE_NAME="company-service"
SERVICE_PORT=8603
SERVICE_DIR="backend/internal/company-service"

# 检查服务是否已运行
check_port() {
    if lsof -i :$1 > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# 启动服务
start_service() {
    echo -e "${BLUE}[INFO] 启动 $SERVICE_NAME...${NC}"
    
    if check_port $SERVICE_PORT; then
        echo -e "${YELLOW}[WARNING] $SERVICE_NAME 已在端口 $SERVICE_PORT 运行${NC}"
        return 0
    fi
    
    cd $SERVICE_DIR
    
    # 检查可执行文件
    if [ ! -f "$SERVICE_NAME" ]; then
        echo -e "${BLUE}[INFO] 编译 $SERVICE_NAME...${NC}"
        go build -o $SERVICE_NAME .
        if [ $? -ne 0 ]; then
            echo -e "${RED}[ERROR] 编译失败${NC}"
            return 1
        fi
    fi
    
    # 启动服务
    echo -e "${BLUE}[INFO] 启动 $SERVICE_NAME 在端口 $SERVICE_PORT...${NC}"
    ./$SERVICE_NAME &
    SERVICE_PID=$!
    
    # 等待服务启动
    sleep 3
    
    if check_port $SERVICE_PORT; then
        echo -e "${GREEN}[SUCCESS] $SERVICE_NAME 启动成功 (PID: $SERVICE_PID)${NC}"
        echo -e "${CYAN}[INFO] 服务地址: http://localhost:$SERVICE_PORT${NC}"
        echo -e "${CYAN}[INFO] 健康检查: http://localhost:$SERVICE_PORT/health${NC}"
    else
        echo -e "${RED}[ERROR] $SERVICE_NAME 启动失败${NC}"
        return 1
    fi
}

# 主函数
main() {
    echo -e "${BLUE}=== $SERVICE_NAME 启动脚本 ===${NC}"
    start_service
}

# 执行主函数
main "$@"
