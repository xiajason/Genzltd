#!/bin/bash

# 启动 Banner Service (Content Management)

SERVICE_NAME="banner-service"
SERVICE_DIR="/Users/szjason72/zervi-basic/basic/backend/internal/$SERVICE_NAME"
LOG_FILE="$SERVICE_DIR/$SERVICE_NAME.log"

echo "Starting $SERVICE_NAME (Content Management Service)..."

# 检查并杀死可能正在运行的旧进程
PID=$(lsof -t -i:8087)
if [ ! -z "$PID" ]; then
    echo "Killing existing $SERVICE_NAME process (PID: $PID) on port 8087..."
    kill -9 "$PID"
    sleep 1
fi

cd "$SERVICE_DIR" || { echo "Error: Cannot change directory to $SERVICE_DIR"; exit 1; }

# 编译服务
echo "Compiling $SERVICE_NAME..."
go build -o "$SERVICE_NAME" main.go || { echo "Error: Compilation failed"; exit 1; }

# 以后台方式启动服务，并将输出重定向到日志文件
echo "Running $SERVICE_NAME in background, logging to $LOG_FILE"
nohup "./$SERVICE_NAME" > "$LOG_FILE" 2>&1 &

# 获取新启动的PID
NEW_PID=$!
echo "$SERVICE_NAME started with PID: $NEW_PID"
echo "Check logs: tail -f $LOG_FILE"
