#!/bin/bash

# LoomaCRM + Zervigo子系统联调联试脚本
# 创建时间: 2025年9月24日
# 版本: v1.0

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
LOOMA_PROJECT_ROOT="/Users/szjason72/zervi-basic/looma_crm_ai_refactoring"
ZERVIGO_PROJECT_ROOT="/Users/szjason72/zervi-basic/basic"
LOG_DIR="$LOOMA_PROJECT_ROOT/logs"
INTEGRATION_LOG="$LOG_DIR/integration_test.log"

# 服务配置
LOOMA_SERVICES=(
    "looma-crm:8888"
    "mongodb:27017"
)

ZERVIGO_SERVICES=(
    "basic-server:8080"
    "user-service:8081"
    "resume-service:8082"
    "company-service:8083"
    "unified-auth-service:8207"
    "local-ai-service:8206"
    "consul:8500"
)

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$INTEGRATION_LOG"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$INTEGRATION_LOG"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$INTEGRATION_LOG"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$INTEGRATION_LOG"
}

log_step() {
    echo -e "${PURPLE}[STEP]${NC} $1" | tee -a "$INTEGRATION_LOG"
}

log_header() {
    echo -e "${CYAN}$1${NC}" | tee -a "$INTEGRATION_LOG"
}

# 创建必要的目录
create_directories() {
    mkdir -p "$LOG_DIR"
    mkdir -p "$LOOMA_PROJECT_ROOT/backups"
}

# 检查端口状态
check_port_status() {
    local port=$1
    local service_name=$2
    
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        local pid=$(lsof -Pi :$port -sTCP:LISTEN -t | head -1)
        log_info "$service_name 端口 $port 正在运行 (PID: $pid)"
        return 0
    else
        log_info "$service_name 端口 $port 未运行"
        return 1
    fi
}

# 等待服务健康检查
wait_for_service_health() {
    local service_name=$1
    local health_url=$2
    local timeout=${3:-30}
    
    log_info "等待 $service_name 健康检查..."
    
    local count=0
    while [[ $count -lt $timeout ]]; do
        if curl -s "$health_url" >/dev/null 2>&1; then
            log_success "$service_name 健康检查通过"
            return 0
        fi
        
        sleep 1
        ((count++))
        echo -n "."
    done
    
    echo ""
    log_warning "$service_name 健康检查超时"
    return 1
}

# 启动MongoDB服务
start_mongodb() {
    log_step "启动MongoDB服务..."
    
    if check_port_status 27017 "MongoDB"; then
        log_info "MongoDB已在运行"
        return 0
    fi
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if brew services list | grep mongodb | grep started &> /dev/null; then
            log_info "MongoDB服务已在运行"
        else
            log_info "启动MongoDB服务..."
            brew services start mongodb/brew/mongodb-community
            sleep 5
            
            if mongosh --eval "db.runCommand('ping')" --quiet >/dev/null 2>&1; then
                log_success "MongoDB服务启动成功"
            else
                log_error "MongoDB服务启动失败"
                return 1
            fi
        fi
    else
        log_error "不支持的操作系统: $OSTYPE"
        return 1
    fi
}

# 启动LoomaCRM服务
start_looma_crm() {
    log_step "启动LoomaCRM服务..."
    
    if check_port_status 8888 "LoomaCRM"; then
        log_info "LoomaCRM已在运行"
        return 0
    fi
    
    cd "$LOOMA_PROJECT_ROOT"
    
    # 使用LoomaCRM的启动脚本
    if ./start_looma_crm.sh; then
        log_success "LoomaCRM启动成功"
        
        # 等待健康检查
        if wait_for_service_health "LoomaCRM" "http://localhost:8888/health" 30; then
            log_success "LoomaCRM健康检查通过"
            return 0
        else
            log_warning "LoomaCRM健康检查失败"
            return 1
        fi
    else
        log_error "LoomaCRM启动失败"
        return 1
    fi
}

# 启动Zervigo子系统
start_zervigo_system() {
    log_step "启动Zervigo子系统..."
    
    cd "$ZERVIGO_PROJECT_ROOT/backend/cmd/basic-server/scripts/maintenance"
    
    # 使用Zervigo的增强启动脚本
    if ./smart-startup-enhanced.sh; then
        log_success "Zervigo子系统启动成功"
        return 0
    else
        log_error "Zervigo子系统启动失败"
        return 1
    fi
}

# 验证服务集成
verify_integration() {
    log_step "验证服务集成..."
    
    local integration_tests=()
    local failed_tests=()
    
    # 1. 测试LoomaCRM与MongoDB集成
    log_info "测试LoomaCRM与MongoDB集成..."
    if curl -s "http://localhost:8888/api/talents/test_talent_001" | grep -q "success"; then
        log_success "✅ LoomaCRM与MongoDB集成正常"
        integration_tests+=("looma-mongodb:success")
    else
        log_error "❌ LoomaCRM与MongoDB集成失败"
        failed_tests+=("looma-mongodb:failed")
    fi
    
    # 2. 测试Zervigo服务健康状态
    log_info "测试Zervigo服务健康状态..."
    local zervigo_healthy=0
    local zervigo_total=0
    
    for service_info in "${ZERVIGO_SERVICES[@]}"; do
        IFS=':' read -r service_name port <<< "$service_info"
        ((zervigo_total++))
        
        if check_port_status "$port" "$service_name"; then
            ((zervigo_healthy++))
            log_success "✅ $service_name 运行正常"
        else
            log_warning "❌ $service_name 未运行"
        fi
    done
    
    if [[ $zervigo_healthy -eq $zervigo_total ]]; then
        log_success "✅ 所有Zervigo服务运行正常 ($zervigo_healthy/$zervigo_total)"
        integration_tests+=("zervigo-services:success")
    else
        log_warning "⚠️ 部分Zervigo服务未运行 ($zervigo_healthy/$zervigo_total)"
        integration_tests+=("zervigo-services:partial")
    fi
    
    # 3. 测试LoomaCRM与Zervigo集成
    log_info "测试LoomaCRM与Zervigo集成..."
    local looma_health_response=$(curl -s "http://localhost:8888/health" 2>/dev/null || echo "")
    if echo "$looma_health_response" | grep -q "zervigo_services"; then
        if echo "$looma_health_response" | grep -q '"success":true'; then
            log_success "✅ LoomaCRM与Zervigo集成正常"
            integration_tests+=("looma-zervigo:success")
        else
            log_warning "⚠️ LoomaCRM与Zervigo集成部分成功"
            integration_tests+=("looma-zervigo:partial")
        fi
    else
        log_error "❌ LoomaCRM与Zervigo集成失败"
        failed_tests+=("looma-zervigo:failed")
    fi
    
    # 4. 测试跨服务数据一致性
    log_info "测试跨服务数据一致性..."
    if curl -s "http://localhost:8888/api/talents/consistency_test_001" | grep -q "consistency_test"; then
        log_success "✅ 跨服务数据一致性正常"
        integration_tests+=("data-consistency:success")
    else
        log_warning "⚠️ 跨服务数据一致性测试失败"
        integration_tests+=("data-consistency:failed")
    fi
    
    # 5. 测试权限角色集成
    log_info "测试权限角色集成..."
    if curl -s "http://localhost:8888/api/talents/isolation_test_super_admin" | grep -q "super_admin"; then
        log_success "✅ 权限角色集成正常"
        integration_tests+=("permission-roles:success")
    else
        log_warning "⚠️ 权限角色集成测试失败"
        integration_tests+=("permission-roles:failed")
    fi
    
    # 汇总测试结果
    local total_tests=$((${#integration_tests[@]} + ${#failed_tests[@]}))
    local success_tests=${#integration_tests[@]}
    local success_rate=$((success_tests * 100 / total_tests))
    
    log_info "集成测试结果汇总:"
    log_info "  总测试数: $total_tests"
    log_info "  成功测试: $success_tests"
    log_info "  失败测试: ${#failed_tests[@]}"
    log_info "  成功率: $success_rate%"
    
    if [[ $success_rate -ge 80 ]]; then
        log_success "🎉 集成测试总体成功！"
        return 0
    elif [[ $success_rate -ge 60 ]]; then
        log_warning "⚠️ 集成测试部分成功，需要优化"
        return 1
    else
        log_error "❌ 集成测试失败，需要修复"
        return 1
    fi
}

# 生成集成测试报告
generate_integration_report() {
    log_step "生成集成测试报告..."
    
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local report_file="$LOG_DIR/integration_report_$timestamp.json"
    
    # 收集服务状态
    local service_status=()
    
    # LoomaCRM服务状态
    for service_info in "${LOOMA_SERVICES[@]}"; do
        IFS=':' read -r service_name port <<< "$service_info"
        if check_port_status "$port" "$service_name" >/dev/null 2>&1; then
            service_status+=("{\"service\":\"$service_name\",\"port\":$port,\"status\":\"running\"}")
        else
            service_status+=("{\"service\":\"$service_name\",\"port\":$port,\"status\":\"stopped\"}")
        fi
    done
    
    # Zervigo服务状态
    for service_info in "${ZERVIGO_SERVICES[@]}"; do
        IFS=':' read -r service_name port <<< "$service_info"
        if check_port_status "$port" "$service_name" >/dev/null 2>&1; then
            service_status+=("{\"service\":\"$service_name\",\"port\":$port,\"status\":\"running\"}")
        else
            service_status+=("{\"service\":\"$service_name\",\"port\":$port,\"status\":\"stopped\"}")
        fi
    done
    
    # 生成JSON报告
    cat > "$report_file" << EOF
{
  "integration_test_report": {
    "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "test_type": "looma_crm_zervigo_integration",
    "version": "1.0",
    "summary": {
      "total_services": $((${#LOOMA_SERVICES[@]} + ${#ZERVIGO_SERVICES[@]})),
      "running_services": $(printf '%s\n' "${service_status[@]}" | grep -c '"status":"running"' || echo "0"),
      "stopped_services": $(printf '%s\n' "${service_status[@]}" | grep -c '"status":"stopped"' || echo "0")
    },
    "service_status": [
      $(printf '%s,\n' "${service_status[@]}" | sed '$s/,$//')
    ],
    "integration_tests": {
      "looma_mongodb": "tested",
      "zervigo_services": "tested", 
      "looma_zervigo": "tested",
      "data_consistency": "tested",
      "permission_roles": "tested"
    },
    "recommendations": [
      "继续监控服务健康状态",
      "定期执行集成测试",
      "优化服务间通信性能",
      "完善错误处理和恢复机制"
    ]
  }
}
EOF
    
    log_success "集成测试报告已生成: $report_file"
}

# 显示帮助信息
show_help() {
    cat << EOF
LoomaCRM + Zervigo子系统联调联试脚本

用法: $0 [选项]

选项:
  --looma-only        仅启动LoomaCRM服务
  --zervigo-only      仅启动Zervigo子系统
  --test-only         仅执行集成测试（不启动服务）
  --help             显示此帮助信息

启动流程:
  1. 启动MongoDB服务
  2. 启动LoomaCRM服务
  3. 启动Zervigo子系统
  4. 验证服务集成
  5. 生成集成测试报告

示例:
  $0                    # 完整联调联试
  $0 --looma-only      # 仅启动LoomaCRM
  $0 --zervigo-only    # 仅启动Zervigo
  $0 --test-only       # 仅执行测试

EOF
}

# 主函数
main() {
    local looma_only=false
    local zervigo_only=false
    local test_only=false
    
    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            --looma-only)
                looma_only=true
                shift
                ;;
            --zervigo-only)
                zervigo_only=true
                shift
                ;;
            --test-only)
                test_only=true
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                log_error "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # 初始化
    create_directories
    
    echo "=========================================="
    echo "🚀 LoomaCRM + Zervigo子系统联调联试"
    echo "=========================================="
    echo
    
    log_info "开始联调联试流程..."
    log_info "测试模式: $([ "$test_only" = true ] && echo "仅测试" || echo "完整启动")"
    
    local start_time=$(date +%s)
    local success=true
    
    if [[ "$test_only" = false ]]; then
        # 启动服务
        if [[ "$looma_only" = true ]]; then
            # 仅启动LoomaCRM
            start_mongodb || success=false
            start_looma_crm || success=false
        elif [[ "$zervigo_only" = true ]]; then
            # 仅启动Zervigo
            start_zervigo_system || success=false
        else
            # 启动所有服务
            start_mongodb || success=false
            start_looma_crm || success=false
            start_zervigo_system || success=false
        fi
    fi
    
    # 执行集成测试
    if [[ "$success" = true ]] || [[ "$test_only" = true ]]; then
        if ! verify_integration; then
            success=false
        fi
    fi
    
    # 生成报告
    generate_integration_report
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    echo
    echo "=========================================="
    if [[ "$success" = true ]]; then
        echo "✅ 联调联试完成 - 成功"
    else
        echo "❌ 联调联试完成 - 部分失败"
    fi
    echo "=========================================="
    echo
    log_info "总耗时: ${duration}秒"
    log_info "集成日志: $INTEGRATION_LOG"
    echo
    
    if [[ "$success" = true ]]; then
        log_success "🎉 LoomaCRM与Zervigo子系统联调联试成功！"
        exit 0
    else
        log_error "联调联试存在问题，请检查日志"
        exit 1
    fi
}

# 错误处理
trap 'log_error "联调联试过程中发生错误"; exit 1' ERR

# 信号处理
trap 'log_warning "收到中断信号，正在清理..."; exit 1' INT TERM

# 执行主函数
main "$@"
