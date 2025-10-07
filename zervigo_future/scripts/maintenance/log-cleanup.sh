#!/bin/bash

# JobFirst 日志清理工具
# 解决logs目录积累大量无效文档的问题

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 项目配置
PROJECT_ROOT="/Users/szjason72/zervi-basic/basic"
LOG_DIR="$PROJECT_ROOT/logs"
BACKUP_DIR="$PROJECT_ROOT/backups"

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

# 显示当前日志状态
show_log_status() {
    log_step "当前日志状态..."
    
    if [[ -d "$LOG_DIR" ]]; then
        local total_files=$(find "$LOG_DIR" -type f | wc -l)
        local total_size=$(du -sh "$LOG_DIR" | cut -f1)
        local log_files=$(find "$LOG_DIR" -name "*.log" | wc -l)
        local pid_files=$(find "$LOG_DIR" -name "*.pid" | wc -l)
        local report_files=$(find "$LOG_DIR" -name "*report*.txt" | wc -l)
        
        echo "日志目录: $LOG_DIR"
        echo "总文件数: $total_files"
        echo "总大小: $total_size"
        echo "日志文件: $log_files"
        echo "PID文件: $pid_files"
        echo "报告文件: $report_files"
        echo
        
        # 显示大文件
        log_info "大文件 (>10MB):"
        find "$LOG_DIR" -type f -size +10M -exec ls -lh {} \; 2>/dev/null | while read line; do
            echo "  $line"
        done
        echo
        
        # 显示旧文件
        log_info "旧文件 (>7天):"
        find "$LOG_DIR" -type f -mtime +7 -exec ls -lh {} \; 2>/dev/null | while read line; do
            echo "  $line"
        done
    else
        log_warning "日志目录不存在: $LOG_DIR"
    fi
}

# 清理旧日志文件
cleanup_old_logs() {
    log_step "清理旧日志文件..."
    
    local days=${1:-7}
    
    # 清理旧日志文件
    local old_logs=$(find "$LOG_DIR" -name "*.log" -mtime +$days 2>/dev/null | wc -l)
    if [[ $old_logs -gt 0 ]]; then
        log_info "清理 $old_logs 个超过 $days 天的日志文件..."
        find "$LOG_DIR" -name "*.log" -mtime +$days -delete 2>/dev/null || true
        log_success "已清理 $old_logs 个旧日志文件"
    else
        log_info "没有超过 $days 天的日志文件"
    fi
    
    # 清理旧PID文件
    local old_pids=$(find "$LOG_DIR" -name "*.pid" -mtime +1 2>/dev/null | wc -l)
    if [[ $old_pids -gt 0 ]]; then
        log_info "清理 $old_pids 个超过1天的PID文件..."
        find "$LOG_DIR" -name "*.pid" -mtime +1 -delete 2>/dev/null || true
        log_success "已清理 $old_pids 个旧PID文件"
    else
        log_info "没有超过1天的PID文件"
    fi
    
    # 清理旧报告文件
    local old_reports=$(find "$LOG_DIR" -name "*report*.txt" -mtime +30 2>/dev/null | wc -l)
    if [[ $old_reports -gt 0 ]]; then
        log_info "清理 $old_reports 个超过30天的报告文件..."
        find "$LOG_DIR" -name "*report*.txt" -mtime +30 -delete 2>/dev/null || true
        log_success "已清理 $old_reports 个旧报告文件"
    else
        log_info "没有超过30天的报告文件"
    fi
}

# 压缩大日志文件
compress_large_logs() {
    log_step "压缩大日志文件..."
    
    local size_limit=${1:-10}
    
    # 压缩大日志文件
    local large_files=$(find "$LOG_DIR" -name "*.log" -size +${size_limit}M 2>/dev/null | wc -l)
    if [[ $large_files -gt 0 ]]; then
        log_info "压缩 $large_files 个超过 ${size_limit}MB 的日志文件..."
        find "$LOG_DIR" -name "*.log" -size +${size_limit}M -exec gzip {} \; 2>/dev/null || true
        log_success "已压缩 $large_files 个大日志文件"
    else
        log_info "没有超过 ${size_limit}MB 的日志文件"
    fi
}

# 归档重要日志
archive_important_logs() {
    log_step "归档重要日志..."
    
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    mkdir -p "$BACKUP_DIR"
    
    # 归档当前smart脚本日志
    if [[ -f "$LOG_DIR/smart-startup.log" ]]; then
        cp "$LOG_DIR/smart-startup.log" "$BACKUP_DIR/startup_log_$timestamp.log"
        log_info "已归档启动日志: startup_log_$timestamp.log"
    fi
    
    if [[ -f "$LOG_DIR/smart-shutdown.log" ]]; then
        cp "$LOG_DIR/smart-shutdown.log" "$BACKUP_DIR/shutdown_log_$timestamp.log"
        log_info "已归档关闭日志: shutdown_log_$timestamp.log"
    fi
    
    # 归档服务日志
    local service_logs=$(find "$LOG_DIR" -name "*-service.log" -mtime -1 2>/dev/null | wc -l)
    if [[ $service_logs -gt 0 ]]; then
        log_info "归档 $service_logs 个最近的服务日志..."
        find "$LOG_DIR" -name "*-service.log" -mtime -1 -exec cp {} "$BACKUP_DIR/" \; 2>/dev/null || true
        log_success "已归档 $service_logs 个服务日志"
    fi
}

# 清理临时文件
cleanup_temp_files() {
    log_step "清理临时文件..."
    
    # 清理项目临时文件
    if [[ -d "$PROJECT_ROOT/temp" ]]; then
        local temp_files=$(find "$PROJECT_ROOT/temp" -type f -mtime +1 2>/dev/null | wc -l)
        if [[ $temp_files -gt 0 ]]; then
            log_info "清理 $temp_files 个临时文件..."
            find "$PROJECT_ROOT/temp" -type f -mtime +1 -delete 2>/dev/null || true
            log_success "已清理 $temp_files 个临时文件"
        else
            log_info "没有需要清理的临时文件"
        fi
    fi
    
    # 清理系统临时文件
    local system_temp=$(find /tmp -name "*jobfirst*" -o -name "*zervi*" 2>/dev/null | wc -l)
    if [[ $system_temp -gt 0 ]]; then
        log_info "清理 $system_temp 个系统临时文件..."
        find /tmp -name "*jobfirst*" -o -name "*zervi*" -delete 2>/dev/null || true
        log_success "已清理 $system_temp 个系统临时文件"
    fi
}

# 生成清理报告
generate_cleanup_report() {
    log_step "生成清理报告..."
    
    local report_file="$LOG_DIR/cleanup_report_$(date '+%Y%m%d_%H%M%S').txt"
    
    {
        echo "=========================================="
        echo "JobFirst 日志清理报告"
        echo "=========================================="
        echo "清理时间: $(date)"
        echo "清理脚本: $0"
        echo ""
        echo "清理前状态:"
        echo "  日志目录: $LOG_DIR"
        echo "  总文件数: $(find "$LOG_DIR" -type f 2>/dev/null | wc -l)"
        echo "  总大小: $(du -sh "$LOG_DIR" 2>/dev/null | cut -f1)"
        echo ""
        echo "清理操作:"
        echo "  ✅ 旧日志文件清理 (7天+)"
        echo "  ✅ 旧PID文件清理 (1天+)"
        echo "  ✅ 旧报告文件清理 (30天+)"
        echo "  ✅ 大日志文件压缩 (10MB+)"
        echo "  ✅ 重要日志归档"
        echo "  ✅ 临时文件清理"
        echo ""
        echo "清理后状态:"
        echo "  日志目录: $LOG_DIR"
        echo "  总文件数: $(find "$LOG_DIR" -type f 2>/dev/null | wc -l)"
        echo "  总大小: $(du -sh "$LOG_DIR" 2>/dev/null | cut -f1)"
        echo ""
        echo "归档目录: $BACKUP_DIR"
        echo "归档文件数: $(find "$BACKUP_DIR" -type f 2>/dev/null | wc -l)"
        echo "归档大小: $(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1)"
        echo ""
        echo "=========================================="
    } > "$report_file"
    
    log_success "清理报告已生成: $report_file"
}

# 显示帮助信息
show_help() {
    cat << EOF
JobFirst 日志清理工具

用法: $0 [选项]

选项:
  --days DAYS         清理超过指定天数的日志文件 (默认: 7)
  --size SIZE         压缩超过指定大小的日志文件 (默认: 10MB)
  --status            只显示日志状态，不执行清理
  --archive-only      只执行归档，不执行清理
  --help             显示此帮助信息

清理操作:
  1. 显示当前日志状态
  2. 清理旧日志文件 (7天+)
  3. 清理旧PID文件 (1天+)
  4. 清理旧报告文件 (30天+)
  5. 压缩大日志文件 (10MB+)
  6. 归档重要日志
  7. 清理临时文件
  8. 生成清理报告

示例:
  $0                    # 执行完整清理
  $0 --days 3          # 清理超过3天的日志
  $0 --size 5          # 压缩超过5MB的日志
  $0 --status          # 只显示状态
  $0 --archive-only    # 只执行归档

EOF
}

# 主函数
main() {
    local days=7
    local size=10
    local status_only=false
    local archive_only=false
    
    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            --days)
                days="$2"
                shift 2
                ;;
            --size)
                size="$2"
                shift 2
                ;;
            --status)
                status_only=true
                shift
                ;;
            --archive-only)
                archive_only=true
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                log_error "未知选项: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    echo "=========================================="
    echo "🧹 JobFirst 日志清理工具"
    echo "=========================================="
    echo
    
    # 显示日志状态
    show_log_status
    
    if [[ "$status_only" = true ]]; then
        log_info "只显示状态，不执行清理"
        exit 0
    fi
    
    # 执行清理操作
    if [[ "$archive_only" = true ]]; then
        archive_important_logs
    else
        cleanup_old_logs "$days"
        compress_large_logs "$size"
        archive_important_logs
        cleanup_temp_files
    fi
    
    # 生成清理报告
    generate_cleanup_report
    
    echo
    echo "=========================================="
    echo "✅ JobFirst 日志清理完成"
    echo "=========================================="
    echo
    log_success "日志清理完成，系统已优化"
    echo
}

# 错误处理
trap 'log_error "清理过程中发生错误"; exit 1' ERR

# 执行主函数
main "$@"
