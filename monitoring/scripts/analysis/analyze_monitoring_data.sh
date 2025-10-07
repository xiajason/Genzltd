#!/bin/bash

# 监控数据分析脚本
# 创建时间: 2025年1月27日
# 版本: v1.0

# 获取当前时间戳
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
REPORT_FILE="monitoring/reports/daily/daily_report_$TIMESTAMP.md"

# 分析系统资源使用情况
analyze_system_resources() {
    echo "## 系统资源分析" >> $REPORT_FILE
    echo "" >> $REPORT_FILE
    
    # 分析CPU使用情况
    echo "### CPU使用情况" >> $REPORT_FILE
    echo "- 平均CPU使用率: $(top -l 1 | grep "CPU usage" | awk '{print $3}' | sed 's/%//')%" >> $REPORT_FILE
    echo "" >> $REPORT_FILE
    
    # 分析内存使用情况
    echo "### 内存使用情况" >> $REPORT_FILE
    echo "- 可用内存: $(vm_stat | grep "Pages free" | awk '{print $3}' | sed 's/\.//') 页" >> $REPORT_FILE
    echo "" >> $REPORT_FILE
    
    # 分析磁盘使用情况
    echo "### 磁盘使用情况" >> $REPORT_FILE
    echo "- 磁盘使用率: $(df -h | grep "/dev/disk3s1s1" | awk '{print $5}')" >> $REPORT_FILE
    echo "" >> $REPORT_FILE
}

# 分析数据库状态
analyze_database_status() {
    echo "## 数据库状态分析" >> $REPORT_FILE
    echo "" >> $REPORT_FILE
    
    # 检查各数据库状态
    echo "### 数据库服务状态" >> $REPORT_FILE
    echo "- MySQL: $(nc -z localhost 3306 2>/dev/null && echo "运行中" || echo "未运行")" >> $REPORT_FILE
    echo "- PostgreSQL: $(nc -z localhost 5432 2>/dev/null && echo "运行中" || echo "未运行")" >> $REPORT_FILE
    echo "- Redis: $(nc -z localhost 6379 2>/dev/null && echo "运行中" || echo "未运行")" >> $REPORT_FILE
    echo "- MongoDB: $(nc -z localhost 27017 2>/dev/null && echo "运行中" || echo "未运行")" >> $REPORT_FILE
    echo "- Neo4j: $(nc -z localhost 7474 2>/dev/null && echo "运行中" || echo "未运行")" >> $REPORT_FILE
    echo "" >> $REPORT_FILE
}

# 分析存储使用情况
analyze_storage_usage() {
    echo "## 存储使用分析" >> $REPORT_FILE
    echo "" >> $REPORT_FILE
    
    # 分析项目目录大小
    echo "### 项目目录大小" >> $REPORT_FILE
    echo "- 项目总大小: $(du -sh . | cut -f1)" >> $REPORT_FILE
    echo "" >> $REPORT_FILE
    
    # 分析Docker资源使用
    echo "### Docker资源使用" >> $REPORT_FILE
    echo "- Docker镜像数量: $(docker images -q | wc -l)" >> $REPORT_FILE
    echo "- 运行容器数量: $(docker ps -q | wc -l)" >> $REPORT_FILE
    echo "- 数据卷数量: $(docker volume ls -q | wc -l)" >> $REPORT_FILE
    echo "" >> $REPORT_FILE
}

# 生成分析报告
generate_analysis_report() {
    echo "# 监控数据分析报告" >> $REPORT_FILE
    echo "" >> $REPORT_FILE
    echo "**分析时间**: $(date)" >> $REPORT_FILE
    echo "**分析版本**: v1.0" >> $REPORT_FILE
    echo "" >> $REPORT_FILE
    
    analyze_system_resources
    analyze_database_status
    analyze_storage_usage
    
    echo "## 建议和下一步" >> $REPORT_FILE
    echo "" >> $REPORT_FILE
    echo "1. 持续监控系统资源使用情况" >> $REPORT_FILE
    echo "2. 定期检查数据库服务状态" >> $REPORT_FILE
    echo "3. 优化存储空间使用" >> $REPORT_FILE
    echo "4. 建立告警机制" >> $REPORT_FILE
    echo "" >> $REPORT_FILE
    echo "---" >> $REPORT_FILE
    echo "*此报告由监控数据分析脚本自动生成*" >> $REPORT_FILE
}

# 主函数
main() {
    echo "开始监控数据分析..."
    generate_analysis_report
    echo "监控数据分析完成"
    echo "分析报告: $REPORT_FILE"
}

# 执行分析
main "$@"
