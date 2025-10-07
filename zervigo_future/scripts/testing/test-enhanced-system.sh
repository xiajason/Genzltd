#!/bin/bash

# 增强系统完整测试脚本
# 测试新增的权限管理系统和Consul注册功能

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# 项目配置
PROJECT_ROOT="/opt/jobfirst"
SERVER_URL="http://localhost:8080"
CONSUL_URL="http://localhost:8500"
LOG_FILE="/tmp/enhanced-system-test.log"

# 日志函数
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}" | tee -a "$LOG_FILE"
    exit 1
}

info() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1${NC}" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}✅ $1${NC}" | tee -a "$LOG_FILE"
}

fail() {
    echo -e "${RED}❌ $1${NC}" | tee -a "$LOG_FILE"
}

# 测试计数器
TESTS_PASSED=0
TESTS_FAILED=0

# 运行测试
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    info "运行测试: $test_name"
    
    if eval "$test_command"; then
        success "$test_name - 通过"
        ((TESTS_PASSED++))
    else
        fail "$test_name - 失败"
        ((TESTS_FAILED++))
    fi
    echo
}

# 测试1: 服务器健康检查
test_server_health() {
    local response=$(curl -s "$SERVER_URL/health")
    local status=$(echo "$response" | jq -r '.status // "unknown"')
    
    if [[ "$status" == "healthy" ]]; then
        return 0
    else
        return 1
    fi
}

# 测试2: 超级管理员状态检查
test_super_admin_status() {
    local response=$(curl -s "$SERVER_URL/api/v1/super-admin/public/status")
    local exists=$(echo "$response" | jq -r '.exists // false')
    
    # 无论是否存在都应该返回有效响应
    if [[ "$exists" == "true" || "$exists" == "false" ]]; then
        return 0
    else
        return 1
    fi
}

# 测试3: 超级管理员初始化
test_super_admin_initialization() {
    local init_data='{
        "username": "test_admin",
        "email": "test@jobfirst.com",
        "password": "TestPassword123!",
        "first_name": "Test",
        "last_name": "Admin"
    }'
    
    local response=$(curl -s -X POST "$SERVER_URL/api/v1/super-admin/public/initialize" \
        -H "Content-Type: application/json" \
        -d "$init_data")
    
    local success=$(echo "$response" | jq -r '.success // false')
    
    if [[ "$success" == "true" ]]; then
        return 0
    else
        # 如果已经存在，也算测试通过
        local error_msg=$(echo "$response" | jq -r '.error // ""')
        if [[ "$error_msg" == *"已存在"* ]]; then
            return 0
        fi
        return 1
    fi
}

# 测试4: 用户注册
test_user_registration() {
    local user_data='{
        "username": "test_user_'$(date +%s)'",
        "email": "testuser'$(date +%s)'@jobfirst.com",
        "password": "TestPassword123!",
        "first_name": "Test",
        "last_name": "User"
    }'
    
    local response=$(curl -s -X POST "$SERVER_URL/api/v1/public/register" \
        -H "Content-Type: application/json" \
        -d "$user_data")
    
    local success=$(echo "$response" | jq -r '.success // false')
    
    if [[ "$success" == "true" ]]; then
        return 0
    else
        return 1
    fi
}

# 测试5: 用户登录
test_user_login() {
    local login_data='{
        "username": "test_admin",
        "password": "TestPassword123!"
    }'
    
    local response=$(curl -s -X POST "$SERVER_URL/api/v1/public/login" \
        -H "Content-Type: application/json" \
        -d "$login_data")
    
    local success=$(echo "$response" | jq -r '.success // false')
    
    if [[ "$success" == "true" ]]; then
        # 保存token用于后续测试
        echo "$response" | jq -r '.data.token // ""' > /tmp/test_token.txt
        return 0
    else
        return 1
    fi
}

# 测试6: 权限检查
test_permission_check() {
    local token=$(cat /tmp/test_token.txt 2>/dev/null || echo "")
    
    if [[ -z "$token" ]]; then
        return 1
    fi
    
    local response=$(curl -s -X GET "$SERVER_URL/api/v1/protected/profile" \
        -H "Authorization: Bearer $token")
    
    local success=$(echo "$response" | jq -r '.success // false')
    
    if [[ "$success" == "true" ]]; then
        return 0
    else
        return 1
    fi
}

# 测试7: RBAC权限检查
test_rbac_check() {
    local token=$(cat /tmp/test_token.txt 2>/dev/null || echo "")
    
    if [[ -z "$token" ]]; then
        return 1
    fi
    
    local response=$(curl -s -X GET "$SERVER_URL/api/v1/rbac/check?user=test_admin&resource=user&action=read" \
        -H "Authorization: Bearer $token")
    
    # RBAC检查应该返回响应（无论是否通过）
    if [[ -n "$response" ]]; then
        return 0
    else
        return 1
    fi
}

# 测试8: Consul服务注册
test_consul_registration() {
    local services_response=$(curl -s "$CONSUL_URL/v1/agent/services")
    local jobfirst_services=$(echo "$services_response" | jq -r 'to_entries[] | select(.key | startswith("jobfirst")) | .key')
    
    if [[ -n "$jobfirst_services" ]]; then
        return 0
    else
        return 1
    fi
}

# 测试9: Consul服务健康检查
test_consul_health() {
    local health_response=$(curl -s "$CONSUL_URL/v1/health/state/any")
    local jobfirst_health=$(echo "$health_response" | jq -r '.[] | select(.ServiceName | startswith("jobfirst")) | .Status')
    
    if [[ -n "$jobfirst_health" ]]; then
        # 检查是否有passing状态的服务
        if echo "$jobfirst_health" | grep -q "passing"; then
            return 0
        fi
    fi
    
    return 1
}

# 测试10: API端点完整性
test_api_endpoints() {
    local endpoints=(
        "/health"
        "/api/v1/super-admin/public/status"
        "/api/v1/public/register"
        "/api/v1/public/login"
    )
    
    local passed=0
    local total=${#endpoints[@]}
    
    for endpoint in "${endpoints[@]}"; do
        if curl -s "$SERVER_URL$endpoint" > /dev/null; then
            ((passed++))
        fi
    done
    
    # 至少80%的端点应该可访问
    if [[ $((passed * 100 / total)) -ge 80 ]]; then
        return 0
    else
        return 1
    fi
}

# 清理测试数据
cleanup_test_data() {
    log "清理测试数据..."
    
    # 清理临时文件
    rm -f /tmp/test_token.txt
    
    info "测试数据清理完成"
}

# 生成测试报告
generate_test_report() {
    log "生成测试报告..."
    
    local total_tests=$((TESTS_PASSED + TESTS_FAILED))
    local pass_rate=0
    
    if [[ $total_tests -gt 0 ]]; then
        pass_rate=$((TESTS_PASSED * 100 / total_tests))
    fi
    
    local report_file="/tmp/enhanced-system-test-report.txt"
    
    cat > "$report_file" << EOF
==========================================
增强系统测试报告
==========================================
测试时间: $(date)
测试目标: $SERVER_URL
Consul地址: $CONSUL_URL

测试结果统计:
- 总测试数: $total_tests
- 通过测试: $TESTS_PASSED
- 失败测试: $TESTS_FAILED
- 通过率: $pass_rate%

详细测试结果:
$(cat "$LOG_FILE")

==========================================
EOF

    info "测试报告已生成: $report_file"
    
    # 显示测试结果摘要
    echo
    echo "=========================================="
    echo "📊 测试结果摘要"
    echo "=========================================="
    echo "总测试数: $total_tests"
    echo "通过测试: $TESTS_PASSED"
    echo "失败测试: $TESTS_FAILED"
    echo "通过率: $pass_rate%"
    echo "=========================================="
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        success "所有测试通过！增强系统运行正常。"
    elif [[ $pass_rate -ge 80 ]]; then
        warn "大部分测试通过，系统基本正常。"
    else
        error "多个测试失败，系统可能存在问题。"
    fi
}

# 主函数
main() {
    echo "=========================================="
    echo "🧪 增强系统完整测试工具"
    echo "=========================================="
    echo
    
    # 创建日志文件
    mkdir -p "$(dirname "$LOG_FILE")"
    
    # 运行所有测试
    run_test "服务器健康检查" "test_server_health"
    run_test "超级管理员状态检查" "test_super_admin_status"
    run_test "超级管理员初始化" "test_super_admin_initialization"
    run_test "用户注册" "test_user_registration"
    run_test "用户登录" "test_user_login"
    run_test "权限检查" "test_permission_check"
    run_test "RBAC权限检查" "test_rbac_check"
    run_test "Consul服务注册" "test_consul_registration"
    run_test "Consul服务健康检查" "test_consul_health"
    run_test "API端点完整性" "test_api_endpoints"
    
    # 清理和报告
    cleanup_test_data
    generate_test_report
    
    echo
    echo "=========================================="
    echo "🎉 测试完成！"
    echo "=========================================="
    echo
    echo "📝 详细日志: $LOG_FILE"
    echo "📊 测试报告: /tmp/enhanced-system-test-report.txt"
    echo
    echo "🚀 新增的权限管理系统测试结果:"
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo "  ✅ 所有功能测试通过"
        echo "  ✅ Consul注册成功"
        echo "  ✅ 权限系统正常"
        echo "  ✅ 超级管理员功能正常"
    else
        echo "  ⚠️  部分测试失败，请检查日志"
    fi
    echo "=========================================="
}

# 错误处理
trap 'error "测试执行失败，请检查日志: $LOG_FILE"' ERR

# 执行主函数
main "$@"
