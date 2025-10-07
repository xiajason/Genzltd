#!/bin/bash

# 存储监控脚本
# 创建时间: 2025年1月27日
# 版本: v1.0

# 获取当前时间戳
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="monitoring/logs/storage/storage_$TIMESTAMP.log"

# 监控磁盘使用情况
monitor_disk_usage() {
    echo "[$TIMESTAMP] 磁盘使用监控开始" >> $LOG_FILE
    df -h >> $LOG_FILE
    echo "" >> $LOG_FILE
}

# 监控Docker资源使用
monitor_docker_resources() {
    echo "[$TIMESTAMP] Docker资源监控开始" >> $LOG_FILE
    docker system df >> $LOG_FILE
    echo "" >> $LOG_FILE
}

# 监控项目目录大小
monitor_project_size() {
    echo "[$TIMESTAMP] 项目目录大小监控开始" >> $LOG_FILE
    du -sh . >> $LOG_FILE
    echo "" >> $LOG_FILE
}

# 监控数据库备份大小
monitor_backup_size() {
    echo "[$TIMESTAMP] 数据库备份大小监控开始" >> $LOG_FILE
    if [ -d "database-backups" ]; then
        du -sh database-backups/* >> $LOG_FILE
    else
        echo "数据库备份目录不存在" >> $LOG_FILE
    fi
    echo "" >> $LOG_FILE
}

# 主监控函数
main() {
    echo "开始存储监控..."
    monitor_disk_usage
    monitor_docker_resources
    monitor_project_size
    monitor_backup_size
    echo "存储监控完成"
}

# 执行监控
main "$@"
