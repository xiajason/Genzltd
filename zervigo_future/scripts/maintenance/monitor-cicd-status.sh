#!/bin/bash

# CI/CD 状态监控脚本
# 用于监控GitHub Actions的执行状态

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置
REPO_OWNER="xiajason"
REPO_NAME="zervi-basic"
BRANCH="main"

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

# 检查GitHub CLI是否安装
check_gh_cli() {
    if ! command -v gh &> /dev/null; then
        log_error "GitHub CLI (gh) 未安装"
        log_info "请安装GitHub CLI: https://cli.github.com/"
        log_info "或者访问GitHub仓库页面手动检查: https://github.com/$REPO_OWNER/$REPO_NAME/actions"
        return 1
    fi
    
    # 检查是否已登录
    if ! gh auth status &> /dev/null; then
        log_error "GitHub CLI 未登录"
        log_info "请运行: gh auth login"
        return 1
    fi
    
    log_success "GitHub CLI 已安装并登录"
    return 0
}

# 获取最新的工作流运行状态
get_latest_workflow_status() {
    log_info "获取最新的工作流运行状态..."
    
    # 获取最新的工作流运行
    local latest_run=$(gh run list --repo $REPO_OWNER/$REPO_NAME --branch $BRANCH --limit 1 --json status,conclusion,createdAt,headBranch,displayTitle,url)
    
    if [ -z "$latest_run" ] || [ "$latest_run" = "[]" ]; then
        log_warning "没有找到工作流运行记录"
        return 1
    fi
    
    # 解析状态
    local status=$(echo "$latest_run" | jq -r '.[0].status')
    local conclusion=$(echo "$latest_run" | jq -r '.[0].conclusion')
    local created_at=$(echo "$latest_run" | jq -r '.[0].createdAt')
    local title=$(echo "$latest_run" | jq -r '.[0].displayTitle')
    local url=$(echo "$latest_run" | jq -r '.[0].url')
    
    echo "=== 最新工作流运行状态 ==="
    echo "标题: $title"
    echo "状态: $status"
    echo "结论: $conclusion"
    echo "创建时间: $created_at"
    echo "URL: $url"
    
    # 状态判断
    case "$status" in
        "completed")
            if [ "$conclusion" = "success" ]; then
                log_success "工作流执行成功！"
                return 0
            else
                log_error "工作流执行失败: $conclusion"
                return 1
            fi
            ;;
        "in_progress")
            log_info "工作流正在执行中..."
            return 2
            ;;
        "queued")
            log_info "工作流已排队等待执行..."
            return 2
            ;;
        *)
            log_warning "工作流状态未知: $status"
            return 1
            ;;
    esac
}

# 获取工作流运行详情
get_workflow_details() {
    log_info "获取工作流运行详情..."
    
    # 获取工作流运行ID
    local run_id=$(gh run list --repo $REPO_OWNER/$REPO_NAME --branch $BRANCH --limit 1 --json databaseId | jq -r '.[0].databaseId')
    
    if [ -z "$run_id" ] || [ "$run_id" = "null" ]; then
        log_error "无法获取工作流运行ID"
        return 1
    fi
    
    # 获取工作流运行详情
    local details=$(gh run view $run_id --repo $REPO_OWNER/$REPO_NAME --json status,conclusion,jobs)
    
    echo "=== 工作流运行详情 ==="
    echo "$details" | jq '.'
    
    # 获取作业状态
    local jobs=$(echo "$details" | jq -r '.jobs[] | "\(.name): \(.status) - \(.conclusion // "N/A")"')
    
    echo ""
    echo "=== 作业状态 ==="
    echo "$jobs"
}

# 监控工作流状态
monitor_workflow() {
    log_info "开始监控工作流状态..."
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        log_info "检查第 $attempt 次 (共 $max_attempts 次)..."
        
        local status_result
        get_latest_workflow_status
        status_result=$?
        
        case $status_result in
            0)
                log_success "工作流执行完成！"
                get_workflow_details
                return 0
                ;;
            1)
                log_error "工作流执行失败"
                get_workflow_details
                return 1
                ;;
            2)
                log_info "工作流仍在执行中，等待30秒后重试..."
                sleep 30
                ;;
        esac
        
        attempt=$((attempt + 1))
    done
    
    log_warning "监控超时，请手动检查GitHub Actions页面"
    return 1
}

# 显示帮助信息
show_help() {
    echo "CI/CD 状态监控脚本"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  status     - 获取最新工作流状态"
    echo "  details    - 获取工作流运行详情"
    echo "  monitor    - 持续监控工作流状态"
    echo "  help       - 显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 status    # 获取最新状态"
    echo "  $0 monitor   # 持续监控"
}

# 主函数
main() {
    case "${1:-status}" in
        "status")
            if check_gh_cli; then
                get_latest_workflow_status
            else
                log_info "请访问GitHub仓库页面手动检查:"
                log_info "https://github.com/$REPO_OWNER/$REPO_NAME/actions"
            fi
            ;;
        "details")
            if check_gh_cli; then
                get_workflow_details
            else
                log_info "请访问GitHub仓库页面手动检查:"
                log_info "https://github.com/$REPO_OWNER/$REPO_NAME/actions"
            fi
            ;;
        "monitor")
            if check_gh_cli; then
                monitor_workflow
            else
                log_info "请访问GitHub仓库页面手动检查:"
                log_info "https://github.com/$REPO_OWNER/$REPO_NAME/actions"
            fi
            ;;
        "help"|"--help"|-h)
            show_help
            ;;
        *)
            log_error "未知选项: $1"
            show_help
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"
