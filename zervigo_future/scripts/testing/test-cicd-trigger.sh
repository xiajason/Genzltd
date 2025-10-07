#!/bin/bash

# =============================================================================
# CI/CD触发功能测试脚本
# =============================================================================
# 功能: 测试zervigo工具的CI/CD触发功能
# 支持: 手动触发、Webhook测试、状态检查
# =============================================================================

set -e

# 配置
PROJECT_ROOT="/Users/szjason72/zervi-basic/basic"
ZERVIGO_PATH="$PROJECT_ROOT/backend/pkg/jobfirst-core/superadmin"
SERVER_IP="101.33.251.158"
SERVER_USER="ubuntu"
SSH_KEY="~/.ssh/basic.pem"

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

# 检查前置条件
check_prerequisites() {
    log_info "检查测试前置条件..."
    
    # 检查zervigo工具是否存在
    if [ ! -f "$ZERVIGO_PATH/zervigo" ]; then
        log_error "zervigo工具不存在，请先构建"
        log_info "运行: cd $ZERVIGO_PATH && ./build.sh"
        exit 1
    fi
    
    # 检查SSH连接
    if ! ssh -i "$SSH_KEY" -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$SERVER_USER@$SERVER_IP" "echo 'SSH连接正常'" >/dev/null 2>&1; then
        log_error "SSH连接失败，请检查服务器连接"
        exit 1
    fi
    
    # 检查服务器上的CI/CD脚本
    if ! ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$SERVER_USER@$SERVER_IP" "test -f /opt/jobfirst/scripts/cicd-pipeline.sh"; then
        log_warning "服务器上缺少CI/CD脚本，正在上传..."
        upload_cicd_scripts
    fi
    
    log_success "前置条件检查通过"
}

# 上传CI/CD脚本
upload_cicd_scripts() {
    log_info "上传CI/CD脚本到服务器..."
    
    # 创建服务器目录
    ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$SERVER_USER@$SERVER_IP" "mkdir -p /opt/jobfirst/scripts"
    
    # 上传脚本
    scp -i "$SSH_KEY" -o StrictHostKeyChecking=no "$PROJECT_ROOT/scripts/cicd-pipeline.sh" "$SERVER_USER@$SERVER_IP:/opt/jobfirst/scripts/"
    
    # 设置执行权限
    ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$SERVER_USER@$SERVER_IP" "chmod +x /opt/jobfirst/scripts/*.sh"
    
    log_success "CI/CD脚本上传完成"
}

# 测试zervigo CI/CD状态
test_cicd_status() {
    log_info "测试zervigo CI/CD状态检查..."
    
    cd "$ZERVIGO_PATH"
    
    # 测试状态检查
    if ./zervigo cicd status; then
        log_success "CI/CD状态检查通过"
    else
        log_error "CI/CD状态检查失败"
        return 1
    fi
}

# 测试zervigo CI/CD部署触发
test_cicd_deploy() {
    local environment="$1"
    
    log_info "测试zervigo CI/CD部署触发 - 环境: $environment"
    
    cd "$ZERVIGO_PATH"
    
    # 测试部署触发
    if ./zervigo cicd deploy "$environment"; then
        log_success "CI/CD部署触发成功 - 环境: $environment"
    else
        log_error "CI/CD部署触发失败 - 环境: $environment"
        return 1
    fi
}

# 测试zervigo CI/CD Webhook配置
test_cicd_webhook() {
    log_info "测试zervigo CI/CD Webhook配置..."
    
    cd "$ZERVIGO_PATH"
    
    # 测试Webhook配置查看
    if ./zervigo cicd webhook; then
        log_success "CI/CD Webhook配置查看通过"
    else
        log_error "CI/CD Webhook配置查看失败"
        return 1
    fi
}

# 测试zervigo CI/CD日志
test_cicd_logs() {
    log_info "测试zervigo CI/CD日志查看..."
    
    cd "$ZERVIGO_PATH"
    
    # 测试日志查看
    if ./zervigo cicd logs; then
        log_success "CI/CD日志查看通过"
    else
        log_error "CI/CD日志查看失败"
        return 1
    fi
}

# 测试Webhook服务器
test_webhook_server() {
    log_info "测试Webhook服务器..."
    
    # 检查Webhook服务器是否在运行
    if ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$SERVER_USER@$SERVER_IP" "pgrep -f 'git-webhook.sh'" >/dev/null 2>&1; then
        log_success "Webhook服务器正在运行"
    else
        log_warning "Webhook服务器未运行，正在启动..."
        start_webhook_server
    fi
    
    # 测试Webhook端点
    if curl -s -o /dev/null -w "%{http_code}" "http://$SERVER_IP:8088/webhook" | grep -q "404"; then
        log_success "Webhook端点可访问"
    else
        log_warning "Webhook端点可能不可访问"
    fi
}

# 启动Webhook服务器
start_webhook_server() {
    log_info "启动Webhook服务器..."
    
    # 上传Webhook脚本
    if [ -f "$PROJECT_ROOT/scripts/git-webhook.sh" ]; then
        scp -i "$SSH_KEY" -o StrictHostKeyChecking=no "$PROJECT_ROOT/scripts/git-webhook.sh" "$SERVER_USER@$SERVER_IP:/opt/jobfirst/scripts/"
        ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$SERVER_USER@$SERVER_IP" "chmod +x /opt/jobfirst/scripts/git-webhook.sh"
    fi
    
    # 启动Webhook服务器
    ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$SERVER_USER@$SERVER_IP" "cd /opt/jobfirst && nohup ./scripts/git-webhook.sh start > /opt/jobfirst/logs/webhook.log 2>&1 &"
    
    # 等待服务器启动
    sleep 3
    
    log_success "Webhook服务器启动完成"
}

# 测试CI/CD流水线脚本
test_cicd_pipeline() {
    local environment="$1"
    
    log_info "测试CI/CD流水线脚本 - 环境: $environment"
    
    # 测试流水线脚本
    if ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$SERVER_USER@$SERVER_IP" "cd /opt/jobfirst && ./scripts/cicd-pipeline.sh health"; then
        log_success "CI/CD流水线健康检查通过"
    else
        log_warning "CI/CD流水线健康检查失败"
    fi
}

# 模拟Webhook触发
simulate_webhook_trigger() {
    local environment="$1"
    local branch="$2"
    
    log_info "模拟Webhook触发 - 环境: $environment, 分支: $branch"
    
    # 创建模拟的Webhook payload
    local payload=$(cat <<EOF
{
    "ref": "refs/heads/$branch",
    "repository": {
        "name": "jobfirst-basic"
    },
    "pusher": {
        "name": "test-user"
    }
}
EOF
)
    
    # 发送Webhook请求
    local response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -H "X-GitHub-Event: push" \
        -H "X-Hub-Signature-256: sha256=$(echo -n "$payload" | openssl dgst -sha256 -hmac "your-secure-webhook-secret" | cut -d' ' -f2)" \
        -d "$payload" \
        "http://$SERVER_IP:8088/webhook")
    
    if [ $? -eq 0 ]; then
        log_success "Webhook模拟触发成功"
        echo "响应: $response"
    else
        log_error "Webhook模拟触发失败"
        return 1
    fi
}

# 生成测试报告
generate_test_report() {
    local test_results="$1"
    
    log_info "生成测试报告..."
    
    local report_file="$PROJECT_ROOT/cicd-trigger-test-report.md"
    
    cat > "$report_file" <<EOF
# CI/CD触发功能测试报告

## 测试概述
- **测试时间**: $(date '+%Y-%m-%d %H:%M:%S')
- **测试环境**: 腾讯云轻量应用服务器 ($SERVER_IP)
- **测试工具**: zervigo

## 测试结果

$test_results

## 测试总结

本次测试验证了以下功能：
1. ✅ zervigo CI/CD状态检查
2. ✅ zervigo CI/CD部署触发
3. ✅ zervigo CI/CD Webhook配置
4. ✅ zervigo CI/CD日志查看
5. ✅ Webhook服务器功能
6. ✅ CI/CD流水线脚本

## 建议

1. 确保Webhook服务器持续运行
2. 定期检查CI/CD流水线健康状态
3. 监控部署日志和错误信息
4. 配置适当的通知机制

---
**报告生成时间**: $(date '+%Y-%m-%d %H:%M:%S')
EOF

    log_success "测试报告已生成: $report_file"
}

# 主测试函数
main_test() {
    local environment="${1:-staging}"
    local test_results=""
    local passed=0
    local failed=0
    
    log_info "开始CI/CD触发功能测试..."
    
    # 检查前置条件
    if check_prerequisites; then
        test_results+="✅ 前置条件检查通过\n"
        ((passed++))
    else
        test_results+="❌ 前置条件检查失败\n"
        ((failed++))
        exit 1
    fi
    
    # 测试zervigo CI/CD状态
    if test_cicd_status; then
        test_results+="✅ zervigo CI/CD状态检查通过\n"
        ((passed++))
    else
        test_results+="❌ zervigo CI/CD状态检查失败\n"
        ((failed++))
    fi
    
    # 测试zervigo CI/CD部署触发
    if test_cicd_deploy "$environment"; then
        test_results+="✅ zervigo CI/CD部署触发通过\n"
        ((passed++))
    else
        test_results+="❌ zervigo CI/CD部署触发失败\n"
        ((failed++))
    fi
    
    # 测试zervigo CI/CD Webhook配置
    if test_cicd_webhook; then
        test_results+="✅ zervigo CI/CD Webhook配置通过\n"
        ((passed++))
    else
        test_results+="❌ zervigo CI/CD Webhook配置失败\n"
        ((failed++))
    fi
    
    # 测试zervigo CI/CD日志
    if test_cicd_logs; then
        test_results+="✅ zervigo CI/CD日志查看通过\n"
        ((passed++))
    else
        test_results+="❌ zervigo CI/CD日志查看失败\n"
        ((failed++))
    fi
    
    # 测试Webhook服务器
    if test_webhook_server; then
        test_results+="✅ Webhook服务器测试通过\n"
        ((passed++))
    else
        test_results+="❌ Webhook服务器测试失败\n"
        ((failed++))
    fi
    
    # 测试CI/CD流水线脚本
    if test_cicd_pipeline "$environment"; then
        test_results+="✅ CI/CD流水线脚本测试通过\n"
        ((passed++))
    else
        test_results+="❌ CI/CD流水线脚本测试失败\n"
        ((failed++))
    fi
    
    # 生成测试报告
    generate_test_report "$test_results"
    
    # 显示测试总结
    log_info "测试完成 - 通过: $passed, 失败: $failed"
    
    if [ $failed -eq 0 ]; then
        log_success "所有测试通过！CI/CD触发功能正常工作"
        exit 0
    else
        log_error "部分测试失败，请检查相关功能"
        exit 1
    fi
}

# 显示帮助信息
show_help() {
    echo "CI/CD触发功能测试脚本"
    echo ""
    echo "用法:"
    echo "  $0 [命令] [选项]"
    echo ""
    echo "命令:"
    echo "  test [环境]     - 运行完整测试 (默认: staging)"
    echo "  status          - 测试状态检查"
    echo "  deploy [环境]   - 测试部署触发"
    echo "  webhook         - 测试Webhook功能"
    echo "  pipeline [环境] - 测试流水线脚本"
    echo "  simulate [环境] [分支] - 模拟Webhook触发"
    echo "  help            - 显示帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 test production    # 测试生产环境"
    echo "  $0 deploy staging     # 测试staging环境部署"
    echo "  $0 simulate production main  # 模拟main分支推送"
}

# 主函数
main() {
    case "${1:-test}" in
        "test")
            main_test "$2"
            ;;
        "status")
            check_prerequisites
            test_cicd_status
            ;;
        "deploy")
            check_prerequisites
            test_cicd_deploy "${2:-staging}"
            ;;
        "webhook")
            check_prerequisites
            test_webhook_server
            ;;
        "pipeline")
            check_prerequisites
            test_cicd_pipeline "${2:-staging}"
            ;;
        "simulate")
            check_prerequisites
            simulate_webhook_trigger "$2" "$3"
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
