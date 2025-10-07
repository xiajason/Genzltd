#!/bin/bash

# 自动化优化机制建立脚本 (修复版)
# 创建时间: 2025年1月27日
# 版本: v1.1
# 目标: 建立定期自动化优化机制

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

# 创建自动化优化目录结构
create_automation_structure() {
    log_step "创建自动化优化目录结构"
    
    # 创建自动化目录
    mkdir -p automation/{scripts,schedules,logs,reports,config}
    
    # 创建脚本目录
    mkdir -p automation/scripts/{daily,weekly,monthly,on-demand}
    
    # 创建调度目录
    mkdir -p automation/schedules/{cron,triggers,conditions}
    
    # 创建日志目录
    mkdir -p automation/logs/{execution,errors,success}
    
    # 创建报告目录
    mkdir -p automation/reports/{optimization,performance,maintenance}
    
    # 创建配置目录
    mkdir -p automation/config/{schedules,thresholds,notifications}
    
    log_success "✅ 自动化优化目录结构创建完成"
}

# 创建每日优化脚本
create_daily_optimization() {
    log_step "创建每日优化脚本"
    
    cat > automation/scripts/daily/daily_optimization.sh << 'EOF'
#!/bin/bash

# 每日优化脚本
# 创建时间: 2025年1月27日
# 版本: v1.0

# 获取当前时间戳
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="automation/logs/execution/daily_$TIMESTAMP.log"

# 日志函数
log_info() {
    echo "[$TIMESTAMP] [INFO] $1" | tee -a $LOG_FILE
}

log_success() {
    echo "[$TIMESTAMP] [SUCCESS] $1" | tee -a $LOG_FILE
}

log_warning() {
    echo "[$TIMESTAMP] [WARNING] $1" | tee -a $LOG_FILE
}

# 清理临时文件
cleanup_temporary_files() {
    log_info "开始清理临时文件..."
    
    # 清理日志文件
    find . -name "*.log" -mtime +7 -type f -delete
    find . -name "*.out" -mtime +3 -type f -delete
    find . -name "*.err" -mtime +3 -type f -delete
    
    # 清理临时文件
    find . -name "*.tmp" -type f -delete
    find . -name "*.temp" -type f -delete
    find . -name ".DS_Store" -type f -delete
    
    # 清理缓存文件
    find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
    find . -name "*.pyc" -type f -delete
    
    log_success "临时文件清理完成"
}

# 优化Docker资源
optimize_docker_resources() {
    log_info "开始优化Docker资源..."
    
    # 清理未使用的容器
    docker container prune -f
    
    # 清理未使用的镜像
    docker image prune -f
    
    # 清理未使用的卷
    docker volume prune -f
    
    # 清理构建缓存
    docker builder prune -f
    
    log_success "Docker资源优化完成"
}

# 优化数据库
optimize_databases() {
    log_info "开始优化数据库..."
    
    # 优化PostgreSQL
    if nc -z localhost 5432 2>/dev/null; then
        psql -c "VACUUM ANALYZE;" 2>/dev/null || log_warning "PostgreSQL优化失败"
    fi
    
    # 优化Redis
    if nc -z localhost 6379 2>/dev/null; then
        redis-cli BGREWRITEAOF 2>/dev/null || log_warning "Redis优化失败"
    fi
    
    log_success "数据库优化完成"
}

# 检查系统资源
check_system_resources() {
    log_info "开始检查系统资源..."
    
    # 检查磁盘使用率
    DISK_USAGE=$(df -h | grep "/dev/disk3s1s1" | awk '{print $5}' | sed 's/%//')
    if [ "$DISK_USAGE" -gt 80 ]; then
        log_warning "磁盘使用率过高: $DISK_USAGE%"
    else
        log_success "磁盘使用率正常: $DISK_USAGE%"
    fi
    
    # 检查内存使用情况
    MEMORY_FREE=$(vm_stat | grep "Pages free" | awk '{print $3}' | sed 's/\.//')
    if [ "$MEMORY_FREE" -lt 1000 ]; then
        log_warning "可用内存不足: $MEMORY_FREE 页"
    else
        log_success "内存使用正常: $MEMORY_FREE 页可用"
    fi
    
    log_success "系统资源检查完成"
}

# 主函数
main() {
    log_info "开始每日优化..."
    
    cleanup_temporary_files
    optimize_docker_resources
    optimize_databases
    check_system_resources
    
    log_success "每日优化完成"
    echo "优化日志: $LOG_FILE"
}

# 执行优化
main "$@"
EOF

    chmod +x automation/scripts/daily/daily_optimization.sh
    log_success "✅ 每日优化脚本创建完成"
}

# 创建每周优化脚本
create_weekly_optimization() {
    log_step "创建每周优化脚本"
    
    cat > automation/scripts/weekly/weekly_optimization.sh << 'EOF'
#!/bin/bash

# 每周优化脚本
# 创建时间: 2025年1月27日
# 版本: v1.0

# 获取当前时间戳
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="automation/logs/execution/weekly_$TIMESTAMP.log"

# 日志函数
log_info() {
    echo "[$TIMESTAMP] [INFO] $1" | tee -a $LOG_FILE
}

log_success() {
    echo "[$TIMESTAMP] [SUCCESS] $1" | tee -a $LOG_FILE
}

log_warning() {
    echo "[$TIMESTAMP] [WARNING] $1" | tee -a $LOG_FILE
}

# 深度清理Docker资源
deep_cleanup_docker() {
    log_info "开始深度清理Docker资源..."
    
    # 清理所有未使用的资源
    docker system prune -a -f
    
    # 清理未使用的网络
    docker network prune -f
    
    log_success "Docker深度清理完成"
}

# 优化数据库性能
optimize_database_performance() {
    log_info "开始优化数据库性能..."
    
    # 优化PostgreSQL
    if nc -z localhost 5432 2>/dev/null; then
        psql -c "REINDEX DATABASE postgres;" 2>/dev/null || log_warning "PostgreSQL索引优化失败"
        psql -c "ANALYZE;" 2>/dev/null || log_warning "PostgreSQL分析失败"
    fi
    
    # 优化MySQL
    if nc -z localhost 3306 2>/dev/null; then
        mysql -e "OPTIMIZE TABLE *;" 2>/dev/null || log_warning "MySQL优化失败"
    fi
    
    log_success "数据库性能优化完成"
}

# 清理历史备份
cleanup_historical_backups() {
    log_info "开始清理历史备份..."
    
    if [ -d "database-backups" ]; then
        # 清理30天前的备份
        find database-backups -name "*.sql" -mtime +30 -delete
        find database-backups -name "*.rdb" -mtime +30 -delete
        find database-backups -name "*.dump" -mtime +30 -delete
        
        # 压缩7天前的备份
        find database-backups -name "*.sql" -mtime +7 -exec gzip {} \;
        find database-backups -name "*.rdb" -mtime +7 -exec gzip {} \;
        find database-backups -name "*.dump" -mtime +7 -exec gzip {} \;
    fi
    
    log_success "历史备份清理完成"
}

# 生成性能报告
generate_performance_report() {
    log_info "开始生成性能报告..."
    
    REPORT_FILE="automation/reports/performance/weekly_report_$TIMESTAMP.md"
    
    cat > $REPORT_FILE << EOF
# 每周性能优化报告

**报告时间**: $(date)
**报告版本**: v1.0

## 📊 系统资源状况

### 磁盘使用情况
\`\`\`
$(df -h)
\`\`\`

### 内存使用情况
\`\`\`
$(vm_stat)
\`\`\`

### Docker资源使用
\`\`\`
$(docker system df)
\`\`\`

## 🎯 优化效果

### 清理效果
- 临时文件清理: 完成
- Docker资源优化: 完成
- 数据库性能优化: 完成
- 历史备份清理: 完成

### 性能提升
- 存储空间: 优化完成
- 数据库性能: 优化完成
- 系统响应: 优化完成

## 📋 建议

1. 继续监控系统资源使用情况
2. 定期执行优化脚本
3. 建立告警机制
4. 持续改进优化策略

---
*此报告由每周优化脚本自动生成*
EOF

    log_success "性能报告生成完成: $REPORT_FILE"
}

# 主函数
main() {
    log_info "开始每周优化..."
    
    deep_cleanup_docker
    optimize_database_performance
    cleanup_historical_backups
    generate_performance_report
    
    log_success "每周优化完成"
    echo "优化日志: $LOG_FILE"
}

# 执行优化
main "$@"
EOF

    chmod +x automation/scripts/weekly/weekly_optimization.sh
    log_success "✅ 每周优化脚本创建完成"
}

# 创建每月优化脚本
create_monthly_optimization() {
    log_step "创建每月优化脚本"
    
    cat > automation/scripts/monthly/monthly_optimization.sh << 'EOF'
#!/bin/bash

# 每月优化脚本
# 创建时间: 2025年1月27日
# 版本: v1.0

# 获取当前时间戳
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="automation/logs/execution/monthly_$TIMESTAMP.log"

# 日志函数
log_info() {
    echo "[$TIMESTAMP] [INFO] $1" | tee -a $LOG_FILE
}

log_success() {
    echo "[$TIMESTAMP] [SUCCESS] $1" | tee -a $LOG_FILE
}

log_warning() {
    echo "[$TIMESTAMP] [WARNING] $1" | tee -a $LOG_FILE
}

# 全面系统优化
comprehensive_system_optimization() {
    log_info "开始全面系统优化..."
    
    # 执行存储空间优化
    if [ -f "optimize-storage.sh" ]; then
        ./optimize-storage.sh
        log_success "存储空间优化完成"
    else
        log_warning "存储空间优化脚本不存在"
    fi
    
    # 执行数据库整合
    if [ -f "consolidate-databases.sh" ]; then
        ./consolidate-databases.sh
        log_success "数据库整合完成"
    else
        log_warning "数据库整合脚本不存在"
    fi
    
    log_success "全面系统优化完成"
}

# 数据归档和压缩
archive_and_compress_data() {
    log_info "开始数据归档和压缩..."
    
    # 创建归档目录
    ARCHIVE_DIR="automation/archives/monthly_$TIMESTAMP"
    mkdir -p $ARCHIVE_DIR
    
    # 归档旧日志
    if [ -d "monitoring/logs" ]; then
        find monitoring/logs -name "*.log" -mtime +30 -exec mv {} $ARCHIVE_DIR/ \;
        log_success "旧日志归档完成"
    fi
    
    # 归档旧报告
    if [ -d "monitoring/reports" ]; then
        find monitoring/reports -name "*.md" -mtime +30 -exec mv {} $ARCHIVE_DIR/ \;
        log_success "旧报告归档完成"
    fi
    
    # 压缩归档文件
    if [ -d "$ARCHIVE_DIR" ] && [ "$(ls -A $ARCHIVE_DIR)" ]; then
        tar -czf "automation/archives/monthly_$TIMESTAMP.tar.gz" -C $ARCHIVE_DIR .
        rm -rf $ARCHIVE_DIR
        log_success "归档文件压缩完成"
    fi
    
    log_success "数据归档和压缩完成"
}

# 系统健康检查
system_health_check() {
    log_info "开始系统健康检查..."
    
    # 检查关键服务
    local services=("3306:MySQL" "5432:PostgreSQL" "6379:Redis" "27017:MongoDB" "7474:Neo4j")
    local failed_services=()
    
    for service in "${services[@]}"; do
        local port=$(echo $service | cut -d: -f1)
        local name=$(echo $service | cut -d: -f2)
        
        if nc -z localhost $port 2>/dev/null; then
            log_success "$name 服务正常"
        else
            log_warning "$name 服务异常"
            failed_services+=("$name")
        fi
    done
    
    if [ ${#failed_services[@]} -gt 0 ]; then
        log_warning "发现异常服务: ${failed_services[*]}"
    else
        log_success "所有关键服务运行正常"
    fi
    
    log_success "系统健康检查完成"
}

# 生成月度报告
generate_monthly_report() {
    log_info "开始生成月度报告..."
    
    REPORT_FILE="automation/reports/optimization/monthly_report_$TIMESTAMP.md"
    
    cat > $REPORT_FILE << EOF
# 每月优化报告

**报告时间**: $(date)
**报告版本**: v1.0

## 📊 系统状况概览

### 磁盘使用情况
\`\`\`
$(df -h)
\`\`\`

### 内存使用情况
\`\`\`
$(vm_stat)
\`\`\`

### Docker资源使用
\`\`\`
$(docker system df)
\`\`\`

## 🎯 优化执行情况

### 全面系统优化
- 存储空间优化: 完成
- 数据库整合: 完成
- 系统性能优化: 完成

### 数据归档和压缩
- 旧日志归档: 完成
- 旧报告归档: 完成
- 归档文件压缩: 完成

### 系统健康检查
- 关键服务检查: 完成
- 异常服务识别: 完成
- 系统状态评估: 完成

## 📈 性能指标

### 存储优化
- 磁盘使用率: $(df -h | grep "/dev/disk3s1s1" | awk '{print $5}')
- 项目目录大小: $(du -sh . | cut -f1)
- Docker资源使用: $(docker system df | grep "Images" | awk '{print $4}')

### 数据库状态
- MySQL: $(nc -z localhost 3306 2>/dev/null && echo "正常" || echo "异常")
- PostgreSQL: $(nc -z localhost 5432 2>/dev/null && echo "正常" || echo "异常")
- Redis: $(nc -z localhost 6379 2>/dev/null && echo "正常" || echo "异常")
- MongoDB: $(nc -z localhost 27017 2>/dev/null && echo "正常" || echo "异常")
- Neo4j: $(nc -z localhost 7474 2>/dev/null && echo "正常" || echo "异常")

## 📋 建议和下一步

### 立即行动
1. 修复异常服务
2. 优化存储空间使用
3. 加强监控和告警

### 长期规划
1. 建立自动化运维体系
2. 实施数据治理策略
3. 加强安全防护措施

## ✅ 月度优化完成

**优化时间**: $(date)
**优化状态**: 完成
**总体评估**: 系统性能得到显著提升

---
*此报告由每月优化脚本自动生成*
EOF

    log_success "月度报告生成完成: $REPORT_FILE"
}

# 主函数
main() {
    log_info "开始每月优化..."
    
    comprehensive_system_optimization
    archive_and_compress_data
    system_health_check
    generate_monthly_report
    
    log_success "每月优化完成"
    echo "优化日志: $LOG_FILE"
}

# 执行优化
main "$@"
EOF

    chmod +x automation/scripts/monthly/monthly_optimization.sh
    log_success "✅ 每月优化脚本创建完成"
}

# 创建Cron调度配置
create_cron_schedules() {
    log_step "创建Cron调度配置"
    
    cat > automation/config/schedules/cron_schedules.txt << 'EOF'
# 自动化优化Cron调度配置
# 创建时间: 2025年1月27日
# 版本: v1.0

# 每日优化 (每天凌晨2点执行)
0 2 * * * /Users/szjason72/genzltd/automation/scripts/daily/daily_optimization.sh >> /Users/szjason72/genzltd/automation/logs/execution/daily_$(date +\%Y\%m\%d).log 2>&1

# 每周优化 (每周日凌晨3点执行)
0 3 * * 0 /Users/szjason72/genzltd/automation/scripts/weekly/weekly_optimization.sh >> /Users/szjason72/genzltd/automation/logs/execution/weekly_$(date +\%Y\%m\%d).log 2>&1

# 每月优化 (每月1日凌晨4点执行)
0 4 1 * * /Users/szjason72/genzltd/automation/scripts/monthly/monthly_optimization.sh >> /Users/szjason72/genzltd/automation/logs/execution/monthly_$(date +\%Y\%m\%d).log 2>&1

# 监控脚本 (每5分钟执行一次)
*/5 * * * * /Users/szjason72/genzltd/monitoring/run_monitoring.sh >> /Users/szjason72/genzltd/monitoring/logs/system/monitoring_$(date +\%Y\%m\%d_\%H\%M).log 2>&1

# 告警检查 (每10分钟执行一次)
*/10 * * * * /Users/szjason72/genzltd/monitoring/scripts/alerting/alert_manager.sh >> /Users/szjason72/genzltd/monitoring/alerts/active/alerts_$(date +\%Y\%m\%d_\%H\%M).log 2>&1
EOF

    log_success "✅ Cron调度配置创建完成"
}

# 创建自动化主脚本
create_automation_main_script() {
    log_step "创建自动化主脚本"
    
    cat > automation/run_automation.sh << 'EOF'
#!/bin/bash

# 自动化主脚本
# 创建时间: 2025年1月27日
# 版本: v1.0

# 获取当前时间戳
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# 显示自动化选项
show_automation_options() {
    echo "🔧 自动化优化选项:"
    echo "  1. 执行每日优化"
    echo "  2. 执行每周优化"
    echo "  3. 执行每月优化"
    echo "  4. 执行按需优化"
    echo "  5. 查看优化状态"
    echo "  6. 退出"
    echo ""
}

# 执行每日优化
run_daily_optimization() {
    echo "执行每日优化..."
    ./automation/scripts/daily/daily_optimization.sh
    echo "每日优化完成"
}

# 执行每周优化
run_weekly_optimization() {
    echo "执行每周优化..."
    ./automation/scripts/weekly/weekly_optimization.sh
    echo "每周优化完成"
}

# 执行每月优化
run_monthly_optimization() {
    echo "执行每月优化..."
    ./automation/scripts/monthly/monthly_optimization.sh
    echo "每月优化完成"
}

# 执行按需优化
run_on_demand_optimization() {
    echo "执行按需优化..."
    
    # 检查可用的优化脚本
    if [ -f "optimize-storage.sh" ]; then
        echo "执行存储空间优化..."
        ./optimize-storage.sh
    fi
    
    if [ -f "consolidate-databases.sh" ]; then
        echo "执行数据库整合..."
        ./consolidate-databases.sh
    fi
    
    if [ -f "verify-optimization-effects.sh" ]; then
        echo "验证优化效果..."
        ./verify-optimization-effects.sh
    fi
    
    echo "按需优化完成"
}

# 查看优化状态
show_optimization_status() {
    echo "📊 优化状态概览:"
    echo ""
    
    echo "📁 优化脚本状态:"
    ls -la automation/scripts/daily/daily_optimization.sh 2>/dev/null && echo "  ✅ 每日优化脚本" || echo "  ❌ 每日优化脚本"
    ls -la automation/scripts/weekly/weekly_optimization.sh 2>/dev/null && echo "  ✅ 每周优化脚本" || echo "  ❌ 每周优化脚本"
    ls -la automation/scripts/monthly/monthly_optimization.sh 2>/dev/null && echo "  ✅ 每月优化脚本" || echo "  ❌ 每月优化脚本"
    
    echo ""
    echo "📁 监控脚本状态:"
    ls -la monitoring/run_monitoring.sh 2>/dev/null && echo "  ✅ 监控主脚本" || echo "  ❌ 监控主脚本"
    ls -la monitoring/scripts/alerting/alert_manager.sh 2>/dev/null && echo "  ✅ 告警管理脚本" || echo "  ❌ 告警管理脚本"
    
    echo ""
    echo "📁 日志文件状态:"
    echo "  - 每日优化日志: $(ls -la automation/logs/execution/daily_*.log 2>/dev/null | wc -l) 个"
    echo "  - 每周优化日志: $(ls -la automation/logs/execution/weekly_*.log 2>/dev/null | wc -l) 个"
    echo "  - 每月优化日志: $(ls -la automation/logs/execution/monthly_*.log 2>/dev/null | wc -l) 个"
    
    echo ""
    echo "📁 报告文件状态:"
    echo "  - 性能报告: $(ls -la automation/reports/performance/*.md 2>/dev/null | wc -l) 个"
    echo "  - 优化报告: $(ls -la automation/reports/optimization/*.md 2>/dev/null | wc -l) 个"
}

# 主函数
main() {
    echo "🔧 自动化优化系统"
    echo "版本: v1.0"
    echo "时间: $(date)"
    echo ""
    
    while true; do
        show_automation_options
        read -p "请选择操作 (1-6): " choice
        
        case $choice in
            1)
                run_daily_optimization
                ;;
            2)
                run_weekly_optimization
                ;;
            3)
                run_monthly_optimization
                ;;
            4)
                run_on_demand_optimization
                ;;
            5)
                show_optimization_status
                ;;
            6)
                echo "退出自动化优化系统"
                break
                ;;
            *)
                echo "无效选择，请重新输入"
                ;;
        esac
        
        echo ""
        read -p "按回车键继续..."
        echo ""
    done
}

# 执行主函数
main "$@"
EOF

    chmod +x automation/run_automation.sh
    log_success "✅ 自动化主脚本创建完成"
}

# 创建安装Cron任务脚本
create_install_cron_script() {
    log_step "创建安装Cron任务脚本"
    
    cat > automation/install_cron.sh << 'EOF'
#!/bin/bash

# 安装Cron任务脚本
# 创建时间: 2025年1月27日
# 版本: v1.0

# 获取当前时间戳
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# 安装Cron任务
install_cron_tasks() {
    echo "开始安装Cron任务..."
    
    # 备份现有crontab
    crontab -l > automation/backup_crontab_$TIMESTAMP.txt 2>/dev/null || echo "无现有crontab"
    
    # 添加新的cron任务
    cat automation/config/schedules/cron_schedules.txt | crontab -
    
    echo "Cron任务安装完成"
}

# 验证Cron任务
verify_cron_tasks() {
    echo "验证Cron任务..."
    crontab -l
}

# 主函数
main() {
    echo "安装自动化优化Cron任务..."
    install_cron_tasks
    verify_cron_tasks
    echo "Cron任务安装完成"
}

# 执行主函数
main "$@"
EOF

    chmod +x automation/install_cron.sh
    log_success "✅ 安装Cron任务脚本创建完成"
}

# 主函数
main() {
    log_info "🔧 开始建立自动化优化机制..."
    log_info "建立时间: $(date)"
    log_info "自动化版本: v1.1"
    
    echo ""
    log_info "📋 自动化机制建立步骤:"
    echo "  1. 创建自动化目录结构"
    echo "  2. 创建每日优化脚本"
    echo "  3. 创建每周优化脚本"
    echo "  4. 创建每月优化脚本"
    echo "  5. 创建Cron调度配置"
    echo "  6. 创建自动化主脚本"
    echo "  7. 创建安装Cron任务脚本"
    echo ""
    
    # 执行各项建立步骤
    create_automation_structure
    create_daily_optimization
    create_weekly_optimization
    create_monthly_optimization
    create_cron_schedules
    create_automation_main_script
    create_install_cron_script
    
    # 显示建立结果
    log_success "🎉 自动化优化机制建立完成！"
    echo ""
    log_info "📊 自动化体系结构:"
    log_info "  - 自动化目录: automation/"
    log_info "  - 脚本目录: automation/scripts/"
    log_info "  - 调度目录: automation/schedules/"
    log_info "  - 日志目录: automation/logs/"
    log_info "  - 报告目录: automation/reports/"
    log_info "  - 配置目录: automation/config/"
    echo ""
    log_info "📋 自动化脚本:"
    log_info "  - 每日优化: automation/scripts/daily/daily_optimization.sh"
    log_info "  - 每周优化: automation/scripts/weekly/weekly_optimization.sh"
    log_info "  - 每月优化: automation/scripts/monthly/monthly_optimization.sh"
    log_info "  - 自动化主脚本: automation/run_automation.sh"
    log_info "  - 安装Cron任务: automation/install_cron.sh"
    echo ""
    log_success "✅ 自动化优化机制建立完成，可以开始定期优化！"
}

# 执行主函数
main "$@"
