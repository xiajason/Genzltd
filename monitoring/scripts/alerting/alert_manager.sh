#!/bin/bash

# 告警管理脚本
# 创建时间: 2025年1月27日
# 版本: v1.0

# 获取当前时间戳
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
ALERT_FILE="monitoring/alerts/active/alert_$TIMESTAMP.log"

# 检查CPU使用率
check_cpu_usage() {
    local cpu_usage=$(top -l 1 | grep "CPU usage" | awk '{print $3}' | sed 's/%//')
    if (( $(echo "$cpu_usage > 90" | bc -l) )); then
        echo "[$TIMESTAMP] 告警: CPU使用率过高 ($cpu_usage%)" >> $ALERT_FILE
        return 1
    fi
    return 0
}

# 检查内存使用率
check_memory_usage() {
    local memory_usage=$(vm_stat | grep "Pages free" | awk '{print $3}' | sed 's/\.//')
    if [ "$memory_usage" -lt 1000 ]; then
        echo "[$TIMESTAMP] 告警: 内存使用率过高 (可用内存: $memory_usage 页)" >> $ALERT_FILE
        return 1
    fi
    return 0
}

# 检查磁盘使用率
check_disk_usage() {
    local disk_usage=$(df -h | grep "/dev/disk3s1s1" | awk '{print $5}' | sed 's/%//')
    if [ "$disk_usage" -gt 90 ]; then
        echo "[$TIMESTAMP] 告警: 磁盘使用率过高 ($disk_usage%)" >> $ALERT_FILE
        return 1
    fi
    return 0
}

# 检查数据库连接
check_database_connections() {
    local databases=("3306:MySQL" "5432:PostgreSQL" "6379:Redis" "27017:MongoDB" "7474:Neo4j")
    local failed_databases=()
    
    for db in "${databases[@]}"; do
        local port=$(echo $db | cut -d: -f1)
        local name=$(echo $db | cut -d: -f2)
        
        if ! nc -z localhost $port 2>/dev/null; then
            failed_databases+=("$name")
        fi
    done
    
    if [ ${#failed_databases[@]} -gt 0 ]; then
        echo "[$TIMESTAMP] 告警: 数据库连接失败 (${failed_databases[*]})" >> $ALERT_FILE
        return 1
    fi
    return 0
}

# 主检查函数
main() {
    echo "开始告警检查..."
    
    local alert_count=0
    
    check_cpu_usage || ((alert_count++))
    check_memory_usage || ((alert_count++))
    check_disk_usage || ((alert_count++))
    check_database_connections || ((alert_count++))
    
    if [ $alert_count -gt 0 ]; then
        echo "发现 $alert_count 个告警"
        echo "告警详情: $ALERT_FILE"
    else
        echo "系统运行正常，无告警"
    fi
}

# 执行检查
main "$@"
