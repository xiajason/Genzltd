#!/bin/bash

# 监控主脚本
# 创建时间: 2025年1月27日
# 版本: v1.0

# 获取当前时间戳
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# 运行系统监控
echo "运行系统监控..."
./monitoring/scripts/collection/system_monitor.sh

# 运行数据库监控
echo "运行数据库监控..."
./monitoring/scripts/collection/database_monitor.sh

# 运行存储监控
echo "运行存储监控..."
./monitoring/scripts/collection/storage_monitor.sh

# 运行性能监控
echo "运行性能监控..."
./monitoring/scripts/collection/performance_monitor.sh

# 运行告警检查
echo "运行告警检查..."
./monitoring/scripts/alerting/alert_manager.sh

# 运行数据分析
echo "运行数据分析..."
./monitoring/scripts/analysis/analyze_monitoring_data.sh

echo "监控完成"
