#!/bin/bash

# 经验量化分析服务停止脚本
# 创建时间: 2025年10月3日
# 用途: 停止经验量化分析API服务

set -e

echo "🛑 停止经验量化分析API服务"
echo "================================"

# 设置环境变量
EXPERIENCE_QUANTIFICATION_PORT=8210

# 查找并停止服务进程
echo "🔍 查找经验量化分析API服务进程..."
PIDS=$(pgrep -f "experience_quantification_api.py" || true)

if [ -z "$PIDS" ]; then
    echo "⚠️ 未找到经验量化分析API服务进程"
else
    echo "📋 找到以下进程:"
    for PID in $PIDS; do
        echo "   PID: $PID"
        ps -p $PID -o pid,ppid,cmd --no-headers
    done
    
    echo "🛑 正在停止服务..."
    for PID in $PIDS; do
        echo "   停止进程 $PID..."
        kill $PID || true
    done
    
    # 等待进程结束
    echo "⏳ 等待进程结束..."
    sleep 3
    
    # 检查是否还有进程在运行
    REMAINING_PIDS=$(pgrep -f "experience_quantification_api.py" || true)
    if [ -n "$REMAINING_PIDS" ]; then
        echo "⚠️ 进程仍在运行，强制停止..."
        for PID in $REMAINING_PIDS; do
            echo "   强制停止进程 $PID..."
            kill -9 $PID || true
        done
        sleep 2
    fi
    
    # 最终检查
    FINAL_PIDS=$(pgrep -f "experience_quantification_api.py" || true)
    if [ -z "$FINAL_PIDS" ]; then
        echo "✅ 经验量化分析API服务已成功停止"
    else
        echo "❌ 部分进程仍在运行:"
        for PID in $FINAL_PIDS; do
            echo "   PID: $PID"
        done
    fi
fi

# 检查端口是否已释放
echo "🔍 检查端口 $EXPERIENCE_QUANTIFICATION_PORT..."
if lsof -Pi :$EXPERIENCE_QUANTIFICATION_PORT -sTCP:LISTEN -t >/dev/null; then
    echo "⚠️ 端口 $EXPERIENCE_QUANTIFICATION_PORT 仍被占用"
    PORT_PIDS=$(lsof -Pi :$EXPERIENCE_QUANTIFICATION_PORT -sTCP:LISTEN -t)
    echo "   占用进程: $PORT_PIDS"
    
    # 强制释放端口
    echo "🛑 强制释放端口..."
    for PID in $PORT_PIDS; do
        kill -9 $PID || true
    done
    sleep 2
    
    if ! lsof -Pi :$EXPERIENCE_QUANTIFICATION_PORT -sTCP:LISTEN -t >/dev/null; then
        echo "✅ 端口 $EXPERIENCE_QUANTIFICATION_PORT 已释放"
    else
        echo "❌ 无法释放端口 $EXPERIENCE_QUANTIFICATION_PORT"
    fi
else
    echo "✅ 端口 $EXPERIENCE_QUANTIFICATION_PORT 已释放"
fi

echo ""
echo "🎉 经验量化分析API服务停止完成！"
