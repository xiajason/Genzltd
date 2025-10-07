#!/bin/bash

# GitHub Secrets配置脚本
set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# 检查GitHub CLI
check_gh_cli() {
    if ! command -v gh &> /dev/null; then
        log_error "GitHub CLI (gh) 未安装"
        log_info "请先安装GitHub CLI:"
        echo "  brew install gh"
        echo "  或者访问: https://cli.github.com/"
        exit 1
    fi
    
    # 检查是否已登录
    if ! gh auth status &> /dev/null; then
        log_error "GitHub CLI 未登录"
        log_info "请先登录GitHub:"
        echo "  gh auth login"
        exit 1
    fi
    
    log_success "GitHub CLI 已配置"
}

# 获取仓库信息
get_repo_info() {
    log_info "获取GitHub仓库信息..."
    
    # 检查是否在Git仓库中
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log_error "当前目录不是Git仓库"
        exit 1
    fi
    
    # 获取远程仓库URL
    local remote_url
    remote_url=$(git remote get-url origin 2>/dev/null || echo "")
    
    if [ -z "$remote_url" ]; then
        log_warning "未找到远程仓库，需要手动设置"
        read -p "请输入GitHub仓库URL (例如: https://github.com/username/repo.git): " remote_url
        if [ -z "$remote_url" ]; then
            log_error "仓库URL不能为空"
            exit 1
        fi
    fi
    
    # 提取仓库信息
    if [[ $remote_url =~ github\.com[:/]([^/]+)/([^/]+)\.git ]]; then
        export GITHUB_OWNER="${BASH_REMATCH[1]}"
        export GITHUB_REPO="${BASH_REMATCH[2]}"
    else
        log_error "无法解析GitHub仓库URL: $remote_url"
        exit 1
    fi
    
    log_success "仓库信息: $GITHUB_OWNER/$GITHUB_REPO"
}

# 设置GitHub Secrets
setup_secrets() {
    log_info "设置GitHub Secrets..."
    
    # 阿里云服务器IP
    log_info "设置 ALIBABA_CLOUD_SERVER_IP..."
    echo "47.115.168.107" | gh secret set ALIBABA_CLOUD_SERVER_IP --repo "$GITHUB_OWNER/$GITHUB_REPO"
    
    # 阿里云服务器用户名
    log_info "设置 ALIBABA_CLOUD_SERVER_USER..."
    echo "root" | gh secret set ALIBABA_CLOUD_SERVER_USER --repo "$GITHUB_OWNER/$GITHUB_REPO"
    
    # 部署路径
    log_info "设置 ALIBABA_CLOUD_DEPLOY_PATH..."
    echo "/opt/jobfirst" | gh secret set ALIBABA_CLOUD_DEPLOY_PATH --repo "$GITHUB_OWNER/$GITHUB_REPO"
    
    # SSH私钥
    log_info "设置 ALIBABA_CLOUD_SSH_PRIVATE_KEY..."
    if [ -f "$HOME/.ssh/github_actions_key" ]; then
        cat "$HOME/.ssh/github_actions_key" | gh secret set ALIBABA_CLOUD_SSH_PRIVATE_KEY --repo "$GITHUB_OWNER/$GITHUB_REPO"
        log_success "SSH私钥已设置"
    else
        log_error "SSH私钥文件不存在: $HOME/.ssh/github_actions_key"
        exit 1
    fi
    
    log_success "所有GitHub Secrets已设置完成"
}

# 验证Secrets
verify_secrets() {
    log_info "验证GitHub Secrets..."
    
    local secrets=(
        "ALIBABA_CLOUD_SERVER_IP"
        "ALIBABA_CLOUD_SERVER_USER"
        "ALIBABA_CLOUD_DEPLOY_PATH"
        "ALIBABA_CLOUD_SSH_PRIVATE_KEY"
    )
    
    for secret in "${secrets[@]}"; do
        if gh secret list --repo "$GITHUB_OWNER/$GITHUB_REPO" | grep -q "$secret"; then
            log_success "✅ $secret 已设置"
        else
            log_error "❌ $secret 未设置"
        fi
    done
}

# 触发部署
trigger_deployment() {
    log_info "触发GitHub Actions部署..."
    
    # 检查是否有未提交的更改
    if ! git diff-index --quiet HEAD --; then
        log_warning "检测到未提交的更改，正在提交..."
        git add .
        git commit -m "feat: 配置GitHub Actions自动部署

- 设置阿里云服务器连接信息
- 配置Docker构建和部署流程
- 添加健康检查和监控功能"
    fi
    
    # 推送到远程仓库
    log_info "推送到远程仓库..."
    git push origin main
    
    log_success "代码已推送，GitHub Actions将自动触发部署"
}

# 监控部署状态
monitor_deployment() {
    log_info "监控部署状态..."
    
    echo "等待GitHub Actions启动..."
    sleep 10
    
    # 获取最新的workflow运行状态
    gh run list --repo "$GITHUB_OWNER/$GITHUB_REPO" --limit 1
    
    echo ""
    log_info "查看详细部署日志:"
    echo "gh run watch --repo $GITHUB_OWNER/$GITHUB_REPO"
    echo ""
    log_info "在浏览器中查看:"
    echo "https://github.com/$GITHUB_OWNER/$GITHUB_REPO/actions"
}

# 主函数
main() {
    log_info "开始配置GitHub Actions自动部署..."
    
    check_gh_cli
    get_repo_info
    setup_secrets
    verify_secrets
    
    echo ""
    log_success "🎉 GitHub Secrets配置完成！"
    echo ""
    echo "=== 下一步操作 ==="
    echo "1. 触发部署: $0 --trigger"
    echo "2. 监控状态: $0 --monitor"
    echo "3. 查看Actions: https://github.com/$GITHUB_OWNER/$GITHUB_REPO/actions"
}

# 显示帮助信息
show_help() {
    echo "GitHub Actions自动部署配置脚本"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help     显示帮助信息"
    echo "  -t, --trigger  触发部署"
    echo "  -m, --monitor  监控部署状态"
    echo "  -s, --secrets  仅设置Secrets"
    echo ""
    echo "示例:"
    echo "  $0              # 配置Secrets"
    echo "  $0 --trigger    # 触发部署"
    echo "  $0 --monitor    # 监控状态"
}

# 处理命令行参数
case "${1:-}" in
    -h|--help)
        show_help
        exit 0
        ;;
    -t|--trigger)
        get_repo_info
        trigger_deployment
        monitor_deployment
        ;;
    -m|--monitor)
        get_repo_info
        monitor_deployment
        ;;
    -s|--secrets)
        check_gh_cli
        get_repo_info
        setup_secrets
        verify_secrets
        ;;
    "")
        main
        ;;
    *)
        log_error "未知选项: $1"
        show_help
        exit 1
        ;;
esac
