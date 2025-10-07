#!/bin/bash

# 系统资源监控脚本
# 创建时间: 2025年1月27日
# 版本: v1.0

# 获取当前时间戳
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="monitoring/logs/system/system_$TIMESTAMP.log"

# 监控CPU使用率
monitor_cpu() {
    echo "[$TIMESTAMP] CPU监控开始" >> $LOG_FILE
    top -l 1 | grep "CPU usage" >> $LOG_FILE
    echo "" >> $LOG_FILE
}

# 监控内存使用情况
monitor_memory() {
    echo "[$TIMESTAMP] 内存监控开始" >> $LOG_FILE
    vm_stat >> $LOG_FILE
    echo "" >> $LOG_FILE
}

# 监控磁盘使用情况
monitor_disk() {
    echo "[$TIMESTAMP] 磁盘监控开始" >> $LOG_FILE
    df -h >> $LOG_FILE
    echo "" >> $LOG_FILE
}

# 监控网络连接
monitor_network() {
    echo "[$TIMESTAMP] 网络监控开始" >> $LOG_FILE
    netstat -an | grep ESTABLISHED | wc -l >> $LOG_FILE
    echo "" >> $LOG_FILE
}

# 监控进程数量
monitor_processes() {
    echo "[$TIMESTAMP] 进程监控开始" >> $LOG_FILE
    ps aux | wc -l >> $LOG_FILE
    echo "" >> $LOG_FILE
}

# 主监控函数
main() {
    echo "开始系统资源监控..."
    monitor_cpu
    monitor_memory
    monitor_disk
    monitor_network
    monitor_processes
    echo "系统资源监控完成"
}

# 执行监控
main "$@"
