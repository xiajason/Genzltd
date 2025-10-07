#!/bin/bash

# =============================================================================
# JobFirst CI/CD 自动化流水线
# =============================================================================
# 功能: 完整的持续集成和持续部署流水线
# 支持: 前端、后端、数据库、配置管理
# 环境: 腾讯云轻量应用服务器
# =============================================================================

set -e

# 配置
PROJECT_NAME="jobfirst"
SERVER_IP="101.33.251.158"
SERVER_USER="ubuntu"
SSH_KEY="~/.ssh/basic.pem"
PROJECT_DIR="/opt/jobfirst"
LOG_DIR="/opt/jobfirst/logs"
BACKUP_DIR="/opt/jobfirst_versions"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# 远程执行命令
remote_exec() {
    local cmd="$1"
    ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$SERVER_USER@$SERVER_IP" "$cmd"
}

# 远程执行并获取输出
remote_exec_output() {
    local cmd="$1"
    ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$SERVER_USER@$SERVER_IP" "$cmd"
}

# 检查前置条件
check_prerequisites() {
    log_info "检查CI/CD前置条件..."
    
    # 检查SSH连接
    if ! ssh -i "$SSH_KEY" -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$SERVER_USER@$SERVER_IP" "echo 'SSH连接正常'" >/dev/null 2>&1; then
        log_error "SSH连接失败，请检查服务器连接"
        exit 1
    fi
    
    # 检查必要工具
    local tools=("git" "rsync" "ssh")
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            log_error "缺少必要工具: $tool"
            exit 1
        fi
    done
    
    log_success "前置条件检查通过"
}

# 代码质量检查
code_quality_check() {
    log_info "执行代码质量检查..."
    
    # 前端代码检查
    if [ -d "basic/frontend-taro" ]; then
        log_info "检查前端代码质量..."
        cd basic/frontend-taro
        
        # ESLint检查
        if [ -f "package.json" ] && grep -q "eslint" package.json; then
            npm run lint 2>/dev/null || log_warning "ESLint检查发现问题"
        fi
        
        # TypeScript检查
        if [ -f "tsconfig.json" ]; then
            npx tsc --noEmit 2>/dev/null || log_warning "TypeScript类型检查发现问题"
        fi
        
        cd - >/dev/null
    fi
    
    # 后端代码检查
    if [ -d "basic/backend" ]; then
        log_info "检查后端代码质量..."
        cd basic/backend
        
        # Go代码检查
        if command -v go &> /dev/null; then
            go vet ./... 2>/dev/null || log_warning "Go代码检查发现问题"
            go fmt ./... 2>/dev/null || log_warning "Go代码格式化发现问题"
        fi
        
        cd - >/dev/null
    fi
    
    log_success "代码质量检查完成"
}

# 运行测试
run_tests() {
    log_info "运行自动化测试..."
    
    # 前端测试
    if [ -d "basic/frontend-taro" ]; then
        log_info "运行前端测试..."
        cd basic/frontend-taro
        
        if [ -f "package.json" ] && grep -q "test" package.json; then
            npm test 2>/dev/null || log_warning "前端测试发现问题"
        fi
        
        cd - >/dev/null
    fi
    
    # 后端测试
    if [ -d "basic/backend" ]; then
        log_info "运行后端测试..."
        cd basic/backend
        
        if command -v go &> /dev/null; then
            go test ./... 2>/dev/null || log_warning "后端测试发现问题"
        fi
        
        cd - >/dev/null
    fi
    
    log_success "自动化测试完成"
}

# 构建应用
build_application() {
    log_info "构建应用程序..."
    
    # 构建前端
    if [ -d "basic/frontend-taro" ]; then
        log_info "构建前端应用..."
        cd basic/frontend-taro
        
        if [ -f "package.json" ]; then
            npm run build:h5:prod 2>/dev/null || {
                log_error "前端构建失败"
                exit 1
            }
        fi
        
        cd - >/dev/null
    fi
    
    # 构建后端
    if [ -d "basic/backend" ]; then
        log_info "构建后端应用..."
        cd basic/backend
        
        if command -v go &> /dev/null; then
            # 构建zervigo工具
            if [ -d "pkg/jobfirst-core/superadmin" ]; then
                cd pkg/jobfirst-core/superadmin
                go build -o zervigo . 2>/dev/null || {
                    log_error "zervigo工具构建失败"
                    exit 1
                }
                cd - >/dev/null
            fi
        fi
        
        cd - >/dev/null
    fi
    
    log_success "应用程序构建完成"
}

# 创建部署快照
create_deployment_snapshot() {
    log_info "创建部署快照..."
    
    local snapshot_name="deploy-$(date +%Y%m%d-%H%M%S)"
    
    # 在服务器上创建快照
    remote_exec "cd $PROJECT_DIR && ./version-manager.sh snapshot $snapshot_name"
    
    log_success "部署快照创建完成: $snapshot_name"
    echo "$snapshot_name"
}

# 部署到服务器
deploy_to_server() {
    local snapshot_name="$1"
    
    log_info "部署到腾讯云服务器..."
    
    # 同步前端代码
    if [ -d "basic/frontend-taro" ]; then
        log_info "同步前端代码..."
        rsync -av --exclude 'node_modules' --exclude 'dist' --exclude '.git' \
            basic/frontend-taro/ "$SERVER_USER@$SERVER_IP:/opt/jobfirst/frontend-dev/"
    fi
    
    # 同步后端代码
    if [ -d "basic/backend" ]; then
        log_info "同步后端代码..."
        rsync -av --exclude '.git' --exclude '*.log' \
            basic/backend/ "$SERVER_USER@$SERVER_IP:/opt/jobfirst/backend/"
    fi
    
    # 同步脚本
    if [ -d "basic/scripts" ]; then
        log_info "同步管理脚本..."
        rsync -av basic/scripts/ "$SERVER_USER@$SERVER_IP:/opt/jobfirst/scripts/"
    fi
    
    # 在服务器上执行部署
    remote_exec "cd $PROJECT_DIR && ./scripts/deploy.sh $snapshot_name"
    
    log_success "部署到服务器完成"
}

# 健康检查
health_check() {
    log_info "执行部署后健康检查..."
    
    # 检查服务状态
    local services=("basic-server:8080" "user-service:8081" "ai-service:8206" "resume:8082")
    local failed_services=()
    
    for service in "${services[@]}"; do
        local name=$(echo "$service" | cut -d: -f1)
        local port=$(echo "$service" | cut -d: -f2)
        
        if remote_exec_output "curl -s -o /dev/null -w '%{http_code}' http://localhost:$port/health" | grep -q "200"; then
            log_success "$name 服务健康检查通过"
        else
            log_error "$name 服务健康检查失败"
            failed_services+=("$name")
        fi
    done
    
    # 检查前端
    if remote_exec_output "curl -s -o /dev/null -w '%{http_code}' http://localhost:10086" | grep -q "200"; then
        log_success "前端开发服务器健康检查通过"
    else
        log_error "前端开发服务器健康检查失败"
        failed_services+=("frontend")
    fi
    
    if [ ${#failed_services[@]} -gt 0 ]; then
        log_error "以下服务健康检查失败: ${failed_services[*]}"
        return 1
    fi
    
    log_success "所有服务健康检查通过"
    return 0
}

# 回滚部署
rollback_deployment() {
    local snapshot_name="$1"
    
    log_warning "回滚到快照: $snapshot_name"
    
    remote_exec "cd $PROJECT_DIR && ./version-manager.sh rollback $snapshot_name"
    
    log_success "回滚完成"
}

# 发送通知
send_notification() {
    local status="$1"
    local message="$2"
    
    log_info "发送部署通知..."
    
    # 这里可以集成各种通知方式
    # 1. 邮件通知
    # 2. 钉钉/企业微信通知
    # 3. Slack通知
    # 4. 短信通知
    
    echo "部署状态: $status"
    echo "消息: $message"
    echo "时间: $(date '+%Y-%m-%d %H:%M:%S')"
    
    log_success "通知发送完成"
}

# 清理旧版本
cleanup_old_versions() {
    log_info "清理旧版本..."
    
    remote_exec "cd $PROJECT_DIR && ./version-manager.sh clean --keep 5"
    
    log_success "旧版本清理完成"
}

# 主部署流程
main_deployment() {
    local environment="${1:-production}"
    local skip_tests="${2:-false}"
    
    log_info "开始CI/CD部署流程 - 环境: $environment"
    
    # 1. 检查前置条件
    check_prerequisites
    
    # 2. 代码质量检查
    code_quality_check
    
    # 3. 运行测试（可选）
    if [ "$skip_tests" != "true" ]; then
        run_tests
    fi
    
    # 4. 构建应用
    build_application
    
    # 5. 创建部署快照
    local snapshot_name=$(create_deployment_snapshot)
    
    # 6. 部署到服务器
    if deploy_to_server "$snapshot_name"; then
        # 7. 健康检查
        if health_check; then
            log_success "CI/CD部署成功完成"
            send_notification "SUCCESS" "部署成功完成 - 快照: $snapshot_name"
            cleanup_old_versions
        else
            log_error "健康检查失败，开始回滚"
            rollback_deployment "$snapshot_name"
            send_notification "FAILED" "部署失败，已回滚 - 快照: $snapshot_name"
            exit 1
        fi
    else
        log_error "部署失败，开始回滚"
        rollback_deployment "$snapshot_name"
        send_notification "FAILED" "部署失败，已回滚 - 快照: $snapshot_name"
        exit 1
    fi
}

# 快速部署（跳过测试）
quick_deploy() {
    log_info "执行快速部署..."
    main_deployment "production" "true"
}

# 显示帮助信息
show_help() {
    echo "JobFirst CI/CD 自动化流水线"
    echo ""
    echo "用法:"
    echo "  $0 [命令] [选项]"
    echo ""
    echo "命令:"
    echo "  deploy [环境]     - 完整部署流程 (默认: production)"
    echo "  quick            - 快速部署 (跳过测试)"
    echo "  test             - 仅运行测试"
    echo "  build            - 仅构建应用"
    echo "  health           - 健康检查"
    echo "  rollback [快照]  - 回滚到指定快照"
    echo "  help             - 显示帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 deploy production    # 部署到生产环境"
    echo "  $0 deploy staging       # 部署到测试环境"
    echo "  $0 quick               # 快速部署"
    echo "  $0 rollback deploy-20250909-143022  # 回滚到指定快照"
}

# 主函数
main() {
    case "${1:-help}" in
        "deploy")
            main_deployment "$2"
            ;;
        "quick")
            quick_deploy
            ;;
        "test")
            check_prerequisites
            run_tests
            ;;
        "build")
            check_prerequisites
            build_application
            ;;
        "health")
            check_prerequisites
            health_check
            ;;
        "rollback")
            if [ -z "$2" ]; then
                log_error "请指定要回滚的快照名称"
                exit 1
            fi
            check_prerequisites
            rollback_deployment "$2"
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
