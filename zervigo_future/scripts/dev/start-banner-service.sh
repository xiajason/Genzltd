#!/bin/bash
# Zervigo Pro Banner Service 启动脚本

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SERVICE_NAME="banner-service"
SERVICE_PORT=8612
PID_FILE="/tmp/jobfirst_${SERVICE_NAME}.pid"
SERVICE_DIR="backend/internal/${SERVICE_NAME}"

# 检查端口是否被占用
check_port() {
    lsof -i :$1 >/dev/null 2>&1
    return $?
}

# 启动服务
start_service() {
    echo -e "${BLUE}=== ${SERVICE_NAME} 启动脚本 ===${NC}"
    if check_port $SERVICE_PORT; then
        echo -e "${RED}[ERROR] ${SERVICE_NAME} 已在端口 $SERVICE_PORT 运行${NC}"
        exit 1
    fi

    echo -e "${BLUE}[INFO] 启动 ${SERVICE_NAME}...${NC}"
    echo -e "${BLUE}[INFO] 启动 ${SERVICE_NAME} 在端口 ${SERVICE_PORT}...${NC}"

    cd "$SERVICE_DIR" || { echo -e "${RED}[ERROR] 无法进入服务目录: $SERVICE_DIR${NC}"; exit 1; }

    air &
    PID=$!
    echo $PID > "$PID_FILE"
    
    sleep 5 # 等待服务启动

    if check_port $SERVICE_PORT; then
        echo -e "${GREEN}[SUCCESS] ${SERVICE_NAME} 启动成功 (PID: $PID)${NC}"
        echo -e "${BLUE}[INFO] 服务地址: http://localhost:$SERVICE_PORT${NC}"
        echo -e "${BLUE}[INFO] 健康检查: http://localhost:$SERVICE_PORT/health${NC}"
    else
        echo -e "${RED}[ERROR] ${SERVICE_NAME} 启动失败${NC}"
        echo -e "${YELLOW}[INFO] 检查日志或手动调试${NC}"
        exit 1
    fi
    cd ../../..
}

# 停止服务
stop_service() {
    echo -e "${BLUE}=== 停止 ${SERVICE_NAME} ===${NC}"
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if kill "$PID" 2>/dev/null; then
            echo -e "${GREEN}[SUCCESS] ${SERVICE_NAME} (PID: $PID) 已停止${NC}"
        else
            echo -e "${YELLOW}[WARNING] 无法杀死进程 $PID，可能已停止或PID文件错误${NC}"
        fi
        rm -f "$PID_FILE"
    else
        echo -e "${YELLOW}[WARNING] ${SERVICE_NAME} 的PID文件不存在，尝试查找并杀死进程...${NC}"
        # 尝试通过端口查找并杀死进程
        lsof -ti :$SERVICE_PORT | xargs kill -9 2>/dev/null || true
        echo -e "${GREEN}[SUCCESS] 尝试清理端口 $SERVICE_PORT${NC}"
    fi
    # 停止air进程
    pkill -f "air -c ${SERVICE_DIR}/.air.toml" 2>/dev/null
    echo -e "${GREEN}[SUCCESS] 所有air热加载进程已停止${NC}"
}

# 主逻辑
case "$1" in
    start)
        start_service
        ;;
    stop)
        stop_service
        ;;
    restart)
        stop_service
        start_service
        ;;
    status)
        if check_port $SERVICE_PORT; then
            echo -e "${GREEN}${SERVICE_NAME} 正在运行在端口 $SERVICE_PORT${NC}"
        else
            echo -e "${RED}${SERVICE_NAME} 未运行${NC}"
        fi
        ;;
    *)
        echo "用法: $0 {start|stop|restart|status}"
        exit 1
        ;;
esac
