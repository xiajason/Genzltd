#!/bin/bash

# 数据资源监控体系建立脚本
# 创建时间: 2025年1月27日
# 版本: v1.0
# 目标: 建立持续的数据资源监控体系

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 获取当前时间戳
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${PURPLE}[STEP]${NC} $1"
}

# 创建监控目录结构
create_monitoring_structure() {
    log_step "创建监控目录结构"
    
    # 创建监控目录
    mkdir -p monitoring/{logs,reports,scripts,config,alerts}
    
    # 创建日志目录
    mkdir -p monitoring/logs/{system,database,storage,performance}
    
    # 创建报告目录
    mkdir -p monitoring/reports/{daily,weekly,monthly}
    
    # 创建脚本目录
    mkdir -p monitoring/scripts/{collection,analysis,alerting}
    
    # 创建配置目录
    mkdir -p monitoring/config/{thresholds,rules,notifications}
    
    # 创建告警目录
    mkdir -p monitoring/alerts/{active,resolved,archived}
    
    log_success "✅ 监控目录结构创建完成"
}

# 创建系统资源监控脚本
create_system_monitoring() {
    log_step "创建系统资源监控脚本"
    
    cat > monitoring/scripts/collection/system_monitor.sh << 'EOF'
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
EOF

    chmod +x monitoring/scripts/collection/system_monitor.sh
    log_success "✅ 系统资源监控脚本创建完成"
}

# 创建数据库监控脚本
create_database_monitoring() {
    log_step "创建数据库监控脚本"
    
    cat > monitoring/scripts/collection/database_monitor.sh << 'EOF'
#!/bin/bash

# 数据库监控脚本
# 创建时间: 2025年1月27日
# 版本: v1.0

# 获取当前时间戳
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="monitoring/logs/database/database_$TIMESTAMP.log"

# 监控MySQL
monitor_mysql() {
    echo "[$TIMESTAMP] MySQL监控开始" >> $LOG_FILE
    if nc -z localhost 3306 2>/dev/null; then
        echo "MySQL: 运行中" >> $LOG_FILE
        # 可以添加更多MySQL监控指标
    else
        echo "MySQL: 未运行" >> $LOG_FILE
    fi
    echo "" >> $LOG_FILE
}

# 监控PostgreSQL
monitor_postgresql() {
    echo "[$TIMESTAMP] PostgreSQL监控开始" >> $LOG_FILE
    if nc -z localhost 5432 2>/dev/null; then
        echo "PostgreSQL: 运行中" >> $LOG_FILE
        # 可以添加更多PostgreSQL监控指标
    else
        echo "PostgreSQL: 未运行" >> $LOG_FILE
    fi
    echo "" >> $LOG_FILE
}

# 监控Redis
monitor_redis() {
    echo "[$TIMESTAMP] Redis监控开始" >> $LOG_FILE
    if nc -z localhost 6379 2>/dev/null; then
        echo "Redis: 运行中" >> $LOG_FILE
        # 可以添加更多Redis监控指标
    else
        echo "Redis: 未运行" >> $LOG_FILE
    fi
    echo "" >> $LOG_FILE
}

# 监控MongoDB
monitor_mongodb() {
    echo "[$TIMESTAMP] MongoDB监控开始" >> $LOG_FILE
    if nc -z localhost 27017 2>/dev/null; then
        echo "MongoDB: 运行中" >> $LOG_FILE
        # 可以添加更多MongoDB监控指标
    else
        echo "MongoDB: 未运行" >> $LOG_FILE
    fi
    echo "" >> $LOG_FILE
}

# 监控Neo4j
monitor_neo4j() {
    echo "[$TIMESTAMP] Neo4j监控开始" >> $LOG_FILE
    if nc -z localhost 7474 2>/dev/null; then
        echo "Neo4j: 运行中" >> $LOG_FILE
        # 可以添加更多Neo4j监控指标
    else
        echo "Neo4j: 未运行" >> $LOG_FILE
    fi
    echo "" >> $LOG_FILE
}

# 主监控函数
main() {
    echo "开始数据库监控..."
    monitor_mysql
    monitor_postgresql
    monitor_redis
    monitor_mongodb
    monitor_neo4j
    echo "数据库监控完成"
}

# 执行监控
main "$@"
EOF

    chmod +x monitoring/scripts/collection/database_monitor.sh
    log_success "✅ 数据库监控脚本创建完成"
}

# 创建存储监控脚本
create_storage_monitoring() {
    log_step "创建存储监控脚本"
    
    cat > monitoring/scripts/collection/storage_monitor.sh << 'EOF'
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
EOF

    chmod +x monitoring/scripts/collection/storage_monitor.sh
    log_success "✅ 存储监控脚本创建完成"
}

# 创建性能监控脚本
create_performance_monitoring() {
    log_step "创建性能监控脚本"
    
    cat > monitoring/scripts/collection/performance_monitor.sh << 'EOF'
#!/bin/bash

# 性能监控脚本
# 创建时间: 2025年1月27日
# 版本: v1.0

# 获取当前时间戳
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="monitoring/logs/performance/performance_$TIMESTAMP.log"

# 监控系统负载
monitor_system_load() {
    echo "[$TIMESTAMP] 系统负载监控开始" >> $LOG_FILE
    uptime >> $LOG_FILE
    echo "" >> $LOG_FILE
}

# 监控内存使用情况
monitor_memory_usage() {
    echo "[$TIMESTAMP] 内存使用监控开始" >> $LOG_FILE
    vm_stat >> $LOG_FILE
    echo "" >> $LOG_FILE
}

# 监控CPU使用情况
monitor_cpu_usage() {
    echo "[$TIMESTAMP] CPU使用监控开始" >> $LOG_FILE
    top -l 1 | grep "CPU usage" >> $LOG_FILE
    echo "" >> $LOG_FILE
}

# 监控网络连接
monitor_network_connections() {
    echo "[$TIMESTAMP] 网络连接监控开始" >> $LOG_FILE
    netstat -an | grep ESTABLISHED | wc -l >> $LOG_FILE
    echo "" >> $LOG_FILE
}

# 主监控函数
main() {
    echo "开始性能监控..."
    monitor_system_load
    monitor_memory_usage
    monitor_cpu_usage
    monitor_network_connections
    echo "性能监控完成"
}

# 执行监控
main "$@"
EOF

    chmod +x monitoring/scripts/collection/performance_monitor.sh
    log_success "✅ 性能监控脚本创建完成"
}

# 创建监控配置
create_monitoring_config() {
    log_step "创建监控配置"
    
    # 创建监控阈值配置
    cat > monitoring/config/thresholds/monitoring_thresholds.yaml << 'EOF'
# 监控阈值配置
# 创建时间: 2025年1月27日
# 版本: v1.0

# 系统资源阈值
system:
  cpu_usage:
    warning: 70
    critical: 90
  
  memory_usage:
    warning: 80
    critical: 95
  
  disk_usage:
    warning: 80
    critical: 90

# 数据库阈值
database:
  connection_timeout:
    warning: 5
    critical: 10
  
  response_time:
    warning: 1000
    critical: 5000

# 存储阈值
storage:
  backup_size:
    warning: 5GB
    critical: 10GB
  
  docker_usage:
    warning: 80
    critical: 90

# 性能阈值
performance:
  system_load:
    warning: 2.0
    critical: 4.0
  
  network_connections:
    warning: 1000
    critical: 2000
EOF

    # 创建监控规则配置
    cat > monitoring/config/rules/monitoring_rules.yaml << 'EOF'
# 监控规则配置
# 创建时间: 2025年1月27日
# 版本: v1.0

# 监控频率
frequency:
  system: "5分钟"
  database: "1分钟"
  storage: "10分钟"
  performance: "2分钟"

# 告警规则
alerts:
  - name: "CPU使用率过高"
    condition: "cpu_usage > 90"
    severity: "critical"
    action: "发送邮件通知"
  
  - name: "内存使用率过高"
    condition: "memory_usage > 95"
    severity: "critical"
    action: "发送邮件通知"
  
  - name: "磁盘使用率过高"
    condition: "disk_usage > 90"
    severity: "critical"
    action: "发送邮件通知"
  
  - name: "数据库连接失败"
    condition: "database_connection_failed"
    severity: "critical"
    action: "发送邮件通知"

# 通知配置
notifications:
  email:
    enabled: true
    recipients: ["admin@example.com"]
    smtp_server: "smtp.example.com"
    smtp_port: 587
  
  webhook:
    enabled: false
    url: "https://hooks.slack.com/services/..."
EOF

    log_success "✅ 监控配置创建完成"
}

# 创建监控分析脚本
create_monitoring_analysis() {
    log_step "创建监控分析脚本"
    
    cat > monitoring/scripts/analysis/analyze_monitoring_data.sh << 'EOF'
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
EOF

    chmod +x monitoring/scripts/analysis/analyze_monitoring_data.sh
    log_success "✅ 监控分析脚本创建完成"
}

# 创建告警脚本
create_alerting_system() {
    log_step "创建告警系统"
    
    cat > monitoring/scripts/alerting/alert_manager.sh << 'EOF'
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
EOF

    chmod +x monitoring/scripts/alerting/alert_manager.sh
    log_success "✅ 告警系统创建完成"
}

# 创建监控主脚本
create_monitoring_main_script() {
    log_step "创建监控主脚本"
    
    cat > monitoring/run_monitoring.sh << 'EOF'
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
EOF

    chmod +x monitoring/run_monitoring.sh
    log_success "✅ 监控主脚本创建完成"
}

# 主函数
main() {
    log_info "🔍 开始建立数据资源监控体系..."
    log_info "建立时间: $(date)"
    log_info "监控版本: v1.0"
    
    echo ""
    log_info "📋 监控体系建立步骤:"
    echo "  1. 创建监控目录结构"
    echo "  2. 创建系统资源监控"
    echo "  3. 创建数据库监控"
    echo "  4. 创建存储监控"
    echo "  5. 创建性能监控"
    echo "  6. 创建监控配置"
    echo "  7. 创建监控分析"
    echo "  8. 创建告警系统"
    echo "  9. 创建监控主脚本"
    echo ""
    
    # 执行各项建立步骤
    create_monitoring_structure
    create_system_monitoring
    create_database_monitoring
    create_storage_monitoring
    create_performance_monitoring
    create_monitoring_config
    create_monitoring_analysis
    create_alerting_system
    create_monitoring_main_script
    
    # 显示建立结果
    log_success "🎉 数据资源监控体系建立完成！"
    echo ""
    log_info "📊 监控体系结构:"
    log_info "  - 监控目录: monitoring/"
    log_info "  - 日志目录: monitoring/logs/"
    log_info "  - 报告目录: monitoring/reports/"
    log_info "  - 脚本目录: monitoring/scripts/"
    log_info "  - 配置目录: monitoring/config/"
    log_info "  - 告警目录: monitoring/alerts/"
    echo ""
    log_info "📋 监控脚本:"
    log_info "  - 系统监控: monitoring/scripts/collection/system_monitor.sh"
    log_info "  - 数据库监控: monitoring/scripts/collection/database_monitor.sh"
    log_info "  - 存储监控: monitoring/scripts/collection/storage_monitor.sh"
    log_info "  - 性能监控: monitoring/scripts/collection/performance_monitor.sh"
    log_info "  - 告警管理: monitoring/scripts/alerting/alert_manager.sh"
    log_info "  - 数据分析: monitoring/scripts/analysis/analyze_monitoring_data.sh"
    log_info "  - 监控主脚本: monitoring/run_monitoring.sh"
    echo ""
    log_success "✅ 数据资源监控体系建立完成，可以开始持续监控！"
}

# 执行主函数
main "$@"
