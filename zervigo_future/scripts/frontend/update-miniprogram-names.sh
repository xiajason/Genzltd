#!/bin/bash

# JobFirst小程序端名称更新脚本
# 将所有的"ADIRP数智招聘"替换为"JobFirst简历管理"

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 获取脚本所在目录的绝对路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
MINIPROGRAM_DIR="$PROJECT_ROOT/frontend/miniprogram"

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

# 检查小程序目录
check_miniprogram_dir() {
    if [ ! -d "$MINIPROGRAM_DIR" ]; then
        log_error "小程序目录不存在: $MINIPROGRAM_DIR"
        exit 1
    fi
    
    log_success "小程序目录检查通过: $MINIPROGRAM_DIR"
}

# 备份原文件
backup_files() {
    log_info "创建备份目录..."
    
    BACKUP_DIR="$PROJECT_ROOT/backup/miniprogram_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    cp -r "$MINIPROGRAM_DIR" "$BACKUP_DIR/"
    
    log_success "备份完成: $BACKUP_DIR"
}

# 更新文件内容
update_file_content() {
    local file_path="$1"
    local temp_file="${file_path}.tmp"
    
    # 使用sed进行替换
    sed -i.tmp \
        -e 's/ADIRP数智招聘/JobFirst简历管理/g' \
        -e 's/ADIRP/JobFirst/g' \
        -e 's/adirp\.com/jobfirst.com/g' \
        -e 's/api\.adirp\.com/api.jobfirst.com/g' \
        -e 's/dev-api\.adirp\.com/dev-api.jobfirst.com/g' \
        -e 's/test-api\.adirp\.com/test-api.jobfirst.com/g' \
        -e 's/support@adirp\.com/support@jobfirst.com/g' \
        -e 's/智能招聘，连接未来/智能简历管理，助力职业发展/g' \
        -e 's/智能匹配，精准求职/智能简历管理，助力职业发展/g' \
        -e 's/智能招聘小程序/简历管理小程序/g' \
        -e 's/招聘系统/简历管理系统/g' \
        -e 's/招聘平台/简历管理平台/g' \
        -e 's/招聘解决方案/简历管理解决方案/g' \
        "$file_path"
    
    # 检查是否有临时文件生成
    if [ -f "$temp_file" ]; then
        rm "$temp_file"
    fi
}

# 更新所有文件
update_all_files() {
    log_info "开始更新文件内容..."
    
    # 查找所有需要更新的文件
    local files_to_update=(
        "$MINIPROGRAM_DIR"/*.js
        "$MINIPROGRAM_DIR"/*.json
        "$MINIPROGRAM_DIR"/*.md
        "$MINIPROGRAM_DIR"/*.wxml
        "$MINIPROGRAM_DIR"/*.wxss
        "$MINIPROGRAM_DIR"/pages/*/*.js
        "$MINIPROGRAM_DIR"/pages/*/*.wxml
        "$MINIPROGRAM_DIR"/pages/*/*.wxss
        "$MINIPROGRAM_DIR"/utils/*.js
        "$MINIPROGRAM_DIR"/config/*.js
    )
    
    local updated_count=0
    
    for pattern in "${files_to_update[@]}"; do
        for file in $pattern; do
            if [ -f "$file" ]; then
                log_info "更新文件: $file"
                update_file_content "$file"
                updated_count=$((updated_count + 1))
            fi
        done
    done
    
    log_success "文件更新完成，共更新 $updated_count 个文件"
}

# 验证更新结果
verify_updates() {
    log_info "验证更新结果..."
    
    # 检查是否还有ADIRP引用
    local remaining_adirp=$(grep -r "ADIRP" "$MINIPROGRAM_DIR" 2>/dev/null || true)
    
    if [ -n "$remaining_adirp" ]; then
        log_warning "发现剩余的ADIRP引用:"
        echo "$remaining_adirp"
    else
        log_success "所有ADIRP引用已成功更新"
    fi
    
    # 检查JobFirst引用
    local jobfirst_count=$(grep -r "JobFirst" "$MINIPROGRAM_DIR" 2>/dev/null | wc -l)
    log_info "JobFirst引用数量: $jobfirst_count"
}

# 显示更新摘要
show_update_summary() {
    log_info "更新摘要:"
    echo "  - 项目名称: ADIRP数智招聘 → JobFirst简历管理"
    echo "  - 域名: adirp.com → jobfirst.com"
    echo "  - API地址: api.adirp.com → api.jobfirst.com"
    echo "  - 邮箱: support@adirp.com → support@jobfirst.com"
    echo "  - 标语: 智能招聘，连接未来 → 智能简历管理，助力职业发展"
    echo "  - 功能定位: 招聘平台 → 简历管理平台"
}

# 显示帮助信息
show_help() {
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  update      Update all ADIRP references to JobFirst (default)"
    echo "  backup      Create backup before updating"
    echo "  verify      Verify update results"
    echo "  summary     Show update summary"
    echo "  help        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 update   # Update all references"
    echo "  $0 backup   # Create backup only"
    echo "  $0 verify   # Verify updates"
}

# 主函数
main() {
    case "${1:-update}" in
        update)
            check_miniprogram_dir
            backup_files
            update_all_files
            verify_updates
            show_update_summary
            ;;
        backup)
            check_miniprogram_dir
            backup_files
            ;;
        verify)
            check_miniprogram_dir
            verify_updates
            ;;
        summary)
            show_update_summary
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "Unknown command: $1"
            show_help
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"
