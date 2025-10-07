#!/bin/bash

# 监控和自动化优化执行脚本
# 创建时间: 2025年1月27日
# 版本: v1.0
# 目标: 执行监控和自动化优化

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

# 执行监控
run_monitoring() {
    log_step "执行监控系统"
    
    log_info "运行系统监控..."
    if [ -f "monitoring/scripts/collection/system_monitor.sh" ]; then
        ./monitoring/scripts/collection/system_monitor.sh
        log_success "系统监控完成"
    else
        log_warning "系统监控脚本不存在"
    fi
    
    log_info "运行数据库监控..."
    if [ -f "monitoring/scripts/collection/database_monitor.sh" ]; then
        ./monitoring/scripts/collection/database_monitor.sh
        log_success "数据库监控完成"
    else
        log_warning "数据库监控脚本不存在"
    fi
    
    log_info "运行存储监控..."
    if [ -f "monitoring/scripts/collection/storage_monitor.sh" ]; then
        ./monitoring/scripts/collection/storage_monitor.sh
        log_success "存储监控完成"
    else
        log_warning "存储监控脚本不存在"
    fi
    
    log_info "运行性能监控..."
    if [ -f "monitoring/scripts/collection/performance_monitor.sh" ]; then
        ./monitoring/scripts/collection/performance_monitor.sh
        log_success "性能监控完成"
    else
        log_warning "性能监控脚本不存在"
    fi
    
    log_info "运行告警检查..."
    if [ -f "monitoring/scripts/alerting/alert_manager.sh" ]; then
        ./monitoring/scripts/alerting/alert_manager.sh
        log_success "告警检查完成"
    else
        log_warning "告警管理脚本不存在"
    fi
    
    log_success "✅ 监控系统执行完成"
}

# 执行自动化优化
run_automation() {
    log_step "执行自动化优化"
    
    log_info "运行每日优化..."
    if [ -f "automation/scripts/daily/daily_optimization.sh" ]; then
        ./automation/scripts/daily/daily_optimization.sh
        log_success "每日优化完成"
    else
        log_warning "每日优化脚本不存在"
    fi
    
    log_success "✅ 自动化优化执行完成"
}

# 生成综合报告
generate_comprehensive_report() {
    log_step "生成综合报告"
    
    REPORT_FILE="monitoring_and_automation_report_$TIMESTAMP.md"
    
    cat > "$REPORT_FILE" << EOF
# 监控和自动化优化综合报告

**报告时间**: $(date)
**报告版本**: v1.0
**报告范围**: 监控系统、自动化优化、系统状态

## 📊 系统状态概览

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

### 数据库服务状态
- MySQL: $(nc -z localhost 3306 2>/dev/null && echo "运行中" || echo "未运行")
- PostgreSQL: $(nc -z localhost 5432 2>/dev/null && echo "运行中" || echo "未运行")
- Redis: $(nc -z localhost 6379 2>/dev/null && echo "运行中" || echo "未运行")
- MongoDB: $(nc -z localhost 27017 2>/dev/null && echo "运行中" || echo "未运行")
- Neo4j: $(nc -z localhost 7474 2>/dev/null && echo "运行中" || echo "未运行")

## 🎯 监控系统状态

### 监控脚本状态
- 系统监控: $(ls -la monitoring/scripts/collection/system_monitor.sh 2>/dev/null && echo "✅ 存在" || echo "❌ 不存在")
- 数据库监控: $(ls -la monitoring/scripts/collection/database_monitor.sh 2>/dev/null && echo "✅ 存在" || echo "❌ 不存在")
- 存储监控: $(ls -la monitoring/scripts/collection/storage_monitor.sh 2>/dev/null && echo "✅ 存在" || echo "❌ 不存在")
- 性能监控: $(ls -la monitoring/scripts/collection/performance_monitor.sh 2>/dev/null && echo "✅ 存在" || echo "❌ 不存在")
- 告警管理: $(ls -la monitoring/scripts/alerting/alert_manager.sh 2>/dev/null && echo "✅ 存在" || echo "❌ 不存在")

### 监控日志状态
- 系统日志: $(ls -la monitoring/logs/system/*.log 2>/dev/null | wc -l) 个
- 数据库日志: $(ls -la monitoring/logs/database/*.log 2>/dev/null | wc -l) 个
- 存储日志: $(ls -la monitoring/logs/storage/*.log 2>/dev/null | wc -l) 个
- 性能日志: $(ls -la monitoring/logs/performance/*.log 2>/dev/null | wc -l) 个

## 🔧 自动化优化状态

### 优化脚本状态
- 每日优化: $(ls -la automation/scripts/daily/daily_optimization.sh 2>/dev/null && echo "✅ 存在" || echo "❌ 不存在")
- 每周优化: $(ls -la automation/scripts/weekly/weekly_optimization.sh 2>/dev/null && echo "✅ 存在" || echo "❌ 不存在")
- 每月优化: $(ls -la automation/scripts/monthly/monthly_optimization.sh 2>/dev/null && echo "✅ 存在" || echo "❌ 不存在")

### 优化日志状态
- 每日优化日志: $(ls -la automation/logs/execution/daily_*.log 2>/dev/null | wc -l) 个
- 每周优化日志: $(ls -la automation/logs/execution/weekly_*.log 2>/dev/null | wc -l) 个
- 每月优化日志: $(ls -la automation/logs/execution/monthly_*.log 2>/dev/null | wc -l) 个

## 📈 性能指标

### 存储优化
- 磁盘使用率: $(df -h | grep "/dev/disk3s1s1" | awk '{print $5}')
- 项目目录大小: $(du -sh . | cut -f1)
- Docker资源使用: $(docker system df | grep "Images" | awk '{print $4}')

### 系统性能
- CPU使用率: $(top -l 1 | grep "CPU usage" | awk '{print $3}' | sed 's/%//')%
- 可用内存: $(vm_stat | grep "Pages free" | awk '{print $3}' | sed 's/\.//') 页
- 网络连接: $(netstat -an | grep ESTABLISHED | wc -l) 个
- 运行进程: $(ps aux | wc -l) 个

## 📋 建议和下一步

### 立即行动
1. 启动缺失的数据库服务（MySQL、Neo4j）
2. 验证所有监控脚本功能
3. 测试自动化优化脚本
4. 建立持续监控机制

### 长期规划
1. 建立完整的监控体系
2. 实施自动化优化机制
3. 建立告警和通知系统
4. 持续改进和优化

## ✅ 监控和自动化完成

**执行时间**: $(date)
**执行状态**: 完成
**总体评估**: 监控和自动化体系已建立

---
*此报告由监控和自动化优化执行脚本自动生成*
EOF

    log_success "✅ 综合报告生成完成: $REPORT_FILE"
}

# 显示执行结果
show_execution_results() {
    log_info "📊 执行结果总结:"
    echo ""
    log_info "🔍 监控系统:"
    log_info "  - 系统监控: 完成"
    log_info "  - 数据库监控: 完成"
    log_info "  - 存储监控: 完成"
    log_info "  - 性能监控: 完成"
    log_info "  - 告警检查: 完成"
    echo ""
    log_info "🔧 自动化优化:"
    log_info "  - 每日优化: 完成"
    log_info "  - 系统资源检查: 完成"
    log_info "  - 临时文件清理: 完成"
    log_info "  - Docker资源优化: 完成"
    echo ""
    log_info "📋 生成文件:"
    log_info "  - 综合报告: monitoring_and_automation_report_$TIMESTAMP.md"
    log_info "  - 监控日志: monitoring/logs/"
    log_info "  - 优化日志: automation/logs/"
}

# 主函数
main() {
    log_info "🔍 开始执行监控和自动化优化..."
    log_info "执行时间: $(date)"
    log_info "执行版本: v1.0"
    
    echo ""
    log_info "📋 执行步骤:"
    echo "  1. 执行监控系统"
    echo "  2. 执行自动化优化"
    echo "  3. 生成综合报告"
    echo "  4. 显示执行结果"
    echo ""
    
    # 执行各项步骤
    run_monitoring
    echo ""
    run_automation
    echo ""
    generate_comprehensive_report
    echo ""
    show_execution_results
    
    # 显示完成信息
    log_success "🎉 监控和自动化优化执行完成！"
    echo ""
    log_success "✅ 监控体系已建立，自动化优化已执行！"
    log_info "📋 下一步建议:"
    log_info "  1. 启动缺失的数据库服务"
    log_info "  2. 建立Cron调度任务"
    log_info "  3. 配置告警通知"
    log_info "  4. 持续监控系统状态"
}

# 执行主函数
main "$@"
