#!/bin/bash

# =============================================================================
# Git Webhook 自动触发脚本
# =============================================================================
# 功能: 接收Git Webhook事件，自动触发CI/CD流水线
# 支持: GitHub, GitLab, Gitee等主流Git平台
# 环境: 腾讯云轻量应用服务器
# =============================================================================

set -e

# 配置
WEBHOOK_SECRET="${WEBHOOK_SECRET:-your-webhook-secret}"
PROJECT_DIR="/opt/jobfirst"
LOG_FILE="/opt/jobfirst/logs/webhook.log"
CICD_SCRIPT="$PROJECT_DIR/scripts/cicd-pipeline.sh"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日志函数
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

# 验证Webhook签名
verify_signature() {
    local payload="$1"
    local signature="$2"
    local secret="$3"
    
    if [ -z "$signature" ] || [ -z "$secret" ]; then
        return 1
    fi
    
    # 计算期望的签名
    local expected_signature=$(echo -n "$payload" | openssl dgst -sha256 -hmac "$secret" -binary | base64)
    
    # 比较签名
    if [ "$signature" = "$expected_signature" ]; then
        return 0
    else
        return 1
    fi
}

# 解析Git事件
parse_git_event() {
    local payload="$1"
    local event_type="$2"
    
    # 使用jq解析JSON（如果没有jq，使用简单的grep）
    if command -v jq &> /dev/null; then
        local ref=$(echo "$payload" | jq -r '.ref // empty')
        local repository=$(echo "$payload" | jq -r '.repository.name // empty')
        local pusher=$(echo "$payload" | jq -r '.pusher.name // empty')
        local commits=$(echo "$payload" | jq -r '.commits | length // 0')
    else
        # 简单的grep解析
        local ref=$(echo "$payload" | grep -o '"ref":"[^"]*"' | cut -d'"' -f4)
        local repository=$(echo "$payload" | grep -o '"name":"[^"]*"' | head -1 | cut -d'"' -f4)
        local pusher=$(echo "$payload" | grep -o '"name":"[^"]*"' | tail -1 | cut -d'"' -f4)
        local commits=$(echo "$payload" | grep -o '"commits"' | wc -l)
    fi
    
    echo "$ref|$repository|$pusher|$commits"
}

# 判断是否需要部署
should_deploy() {
    local ref="$1"
    local repository="$2"
    local event_type="$3"
    
    # 只处理主分支的推送事件
    if [ "$event_type" = "push" ] && [[ "$ref" =~ ^refs/heads/(main|master|develop)$ ]]; then
        return 0
    fi
    
    # 处理标签推送
    if [ "$event_type" = "push" ] && [[ "$ref" =~ ^refs/tags/v[0-9] ]]; then
        return 0
    fi
    
    return 1
}

# 确定部署环境
determine_environment() {
    local ref="$1"
    
    if [[ "$ref" =~ ^refs/heads/(main|master)$ ]]; then
        echo "production"
    elif [[ "$ref" =~ ^refs/heads/develop$ ]]; then
        echo "staging"
    elif [[ "$ref" =~ ^refs/tags/v[0-9] ]]; then
        echo "production"
    else
        echo "development"
    fi
}

# 触发CI/CD流水线
trigger_cicd() {
    local environment="$1"
    local repository="$2"
    local pusher="$3"
    local ref="$4"
    
    log "触发CI/CD流水线 - 环境: $environment, 仓库: $repository, 推送者: $pusher, 分支: $ref"
    
    # 切换到项目目录
    cd "$PROJECT_DIR" || {
        log_error "无法切换到项目目录: $PROJECT_DIR"
        return 1
    }
    
    # 拉取最新代码
    log "拉取最新代码..."
    if [ -d ".git" ]; then
        git pull origin "$(echo "$ref" | sed 's/refs\/heads\///')" || {
            log_error "代码拉取失败"
            return 1
        }
    fi
    
    # 执行CI/CD流水线
    log "执行CI/CD流水线..."
    if [ -f "$CICD_SCRIPT" ]; then
        bash "$CICD_SCRIPT" deploy "$environment" || {
            log_error "CI/CD流水线执行失败"
            return 1
        }
    else
        log_error "CI/CD脚本不存在: $CICD_SCRIPT"
        return 1
    fi
    
    log_success "CI/CD流水线执行完成"
    return 0
}

# 处理Webhook请求
handle_webhook() {
    local method="$1"
    local content_type="$2"
    local signature="$3"
    local event_type="$4"
    
    # 读取请求体
    local payload
    if [ "$method" = "POST" ]; then
        payload=$(cat)
    else
        log_error "不支持的HTTP方法: $method"
        return 1
    fi
    
    # 验证签名
    if ! verify_signature "$payload" "$signature" "$WEBHOOK_SECRET"; then
        log_error "Webhook签名验证失败"
        return 1
    fi
    
    # 解析Git事件
    local event_info=$(parse_git_event "$payload" "$event_type")
    local ref=$(echo "$event_info" | cut -d'|' -f1)
    local repository=$(echo "$event_info" | cut -d'|' -f2)
    local pusher=$(echo "$event_info" | cut -d'|' -f3)
    local commits=$(echo "$event_info" | cut -d'|' -f4)
    
    log "收到Git事件 - 类型: $event_type, 仓库: $repository, 推送者: $pusher, 分支: $ref, 提交数: $commits"
    
    # 判断是否需要部署
    if should_deploy "$ref" "$repository" "$event_type"; then
        local environment=$(determine_environment "$ref")
        trigger_cicd "$environment" "$repository" "$pusher" "$ref"
    else
        log "跳过部署 - 分支: $ref, 事件类型: $event_type"
    fi
    
    return 0
}

# 启动Webhook服务器
start_webhook_server() {
    local port="${1:-8088}"
    
    log "启动Git Webhook服务器 - 端口: $port"
    
    # 创建日志目录
    mkdir -p "$(dirname "$LOG_FILE")"
    
    # 启动简单的HTTP服务器
    while true; do
        {
            # 读取HTTP请求头
            read -r request_line
            local method=$(echo "$request_line" | cut -d' ' -f1)
            local path=$(echo "$request_line" | cut -d' ' -f2)
            
            # 读取其他头部信息
            local content_type=""
            local content_length=""
            local signature=""
            local event_type=""
            
            while read -r header; do
                [ -z "$header" ] && break
                
                case "$header" in
                    Content-Type:*)
                        content_type=$(echo "$header" | cut -d' ' -f2)
                        ;;
                    Content-Length:*)
                        content_length=$(echo "$header" | cut -d' ' -f2)
                        ;;
                    X-Hub-Signature-256:*)
                        signature=$(echo "$header" | cut -d' ' -f2)
                        ;;
                    X-GitHub-Event:*)
                        event_type=$(echo "$header" | cut -d' ' -f2)
                        ;;
                    X-Gitlab-Event:*)
                        event_type=$(echo "$header" | cut -d' ' -f2)
                        ;;
                esac
            done
            
            # 处理Webhook请求
            if [ "$path" = "/webhook" ]; then
                handle_webhook "$method" "$content_type" "$signature" "$event_type"
                echo "HTTP/1.1 200 OK"
                echo "Content-Type: application/json"
                echo ""
                echo '{"status":"success","message":"Webhook processed"}'
            else
                echo "HTTP/1.1 404 Not Found"
                echo "Content-Type: application/json"
                echo ""
                echo '{"status":"error","message":"Not found"}'
            fi
        } | nc -l -p "$port" -q 1
    done
}

# 显示帮助信息
show_help() {
    echo "Git Webhook 自动触发脚本"
    echo ""
    echo "用法:"
    echo "  $0 [命令] [选项]"
    echo ""
    echo "命令:"
    echo "  start [端口]     - 启动Webhook服务器 (默认端口: 8088)"
    echo "  test            - 测试Webhook配置"
    echo "  help            - 显示帮助信息"
    echo ""
    echo "环境变量:"
    echo "  WEBHOOK_SECRET  - Webhook密钥 (默认: your-webhook-secret)"
    echo ""
    echo "示例:"
    echo "  $0 start 8088              # 在8088端口启动Webhook服务器"
    echo "  WEBHOOK_SECRET=mysecret $0 start  # 使用自定义密钥启动"
}

# 测试Webhook配置
test_webhook() {
    log "测试Webhook配置..."
    
    # 检查必要工具
    local tools=("openssl" "nc")
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            log_error "缺少必要工具: $tool"
            exit 1
        fi
    done
    
    # 测试签名验证
    local test_payload='{"test":"data"}'
    local test_signature=$(echo -n "$test_payload" | openssl dgst -sha256 -hmac "$WEBHOOK_SECRET" -binary | base64)
    
    if verify_signature "$test_payload" "$test_signature" "$WEBHOOK_SECRET"; then
        log_success "签名验证测试通过"
    else
        log_error "签名验证测试失败"
        exit 1
    fi
    
    # 检查项目目录
    if [ -d "$PROJECT_DIR" ]; then
        log_success "项目目录存在: $PROJECT_DIR"
    else
        log_error "项目目录不存在: $PROJECT_DIR"
        exit 1
    fi
    
    # 检查CI/CD脚本
    if [ -f "$CICD_SCRIPT" ]; then
        log_success "CI/CD脚本存在: $CICD_SCRIPT"
    else
        log_error "CI/CD脚本不存在: $CICD_SCRIPT"
        exit 1
    fi
    
    log_success "Webhook配置测试通过"
}

# 主函数
main() {
    case "${1:-help}" in
        "start")
            start_webhook_server "$2"
            ;;
        "test")
            test_webhook
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            log_error "未知命令: $1"
            show_help
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"
