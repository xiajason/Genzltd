#!/bin/bash

# 权限管理系统测试脚本
# 测试增强服务器的所有功能

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 服务器配置
SERVER_URL="http://localhost:8080"
ADMIN_USERNAME="admin"
ADMIN_PASSWORD="AdminPassword123!"

# 测试结果统计
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

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

# 测试函数
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_status="$3"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    log_info "运行测试: $test_name"
    
    if eval "$test_command" > /dev/null 2>&1; then
        log_success "$test_name - 通过"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        return 0
    else
        log_error "$test_name - 失败"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
}

# 检查服务器是否运行
check_server() {
    log_info "检查增强服务器状态..."
    if curl -s "$SERVER_URL/health" > /dev/null; then
        log_success "增强服务器正在运行"
        return 0
    else
        log_error "增强服务器未运行，请先启动服务器"
        return 1
    fi
}

# 获取管理员Token
get_admin_token() {
    log_info "获取管理员Token..."
    local response=$(curl -s -X POST "$SERVER_URL/api/v1/public/login" \
        -H "Content-Type: application/json" \
        -d "{\"username\":\"$ADMIN_USERNAME\",\"password\":\"$ADMIN_PASSWORD\"}")
    
    local token=$(echo "$response" | jq -r '.data.token // empty')
    if [ -n "$token" ] && [ "$token" != "null" ]; then
        log_success "成功获取管理员Token"
        echo "$token"
        return 0
    else
        log_error "获取管理员Token失败"
        echo ""
        return 1
    fi
}

# 测试健康检查
test_health_check() {
    run_test "健康检查" "curl -s '$SERVER_URL/health' | jq -e '.status == \"healthy\"'"
}

# 测试超级管理员状态
test_super_admin_status() {
    run_test "超级管理员状态检查" "curl -s '$SERVER_URL/api/v1/super-admin/public/status' | jq -e '.data.exists == true'"
}

# 测试用户登录
test_user_login() {
    run_test "用户登录" "curl -s -X POST '$SERVER_URL/api/v1/public/login' -H 'Content-Type: application/json' -d '{\"username\":\"$ADMIN_USERNAME\",\"password\":\"$ADMIN_PASSWORD\"}' | jq -e '.status == \"success\"'"
}

# 测试受保护的端点
test_protected_endpoints() {
    local token="$1"
    run_test "受保护端点访问" "curl -s -X GET '$SERVER_URL/api/v1/protected/profile' -H 'Authorization: Bearer $token' | jq -e '.status == \"success\"'"
}

# 测试RBAC权限检查
test_rbac_permission_check() {
    local token="$1"
    run_test "RBAC权限检查" "curl -s -X GET '$SERVER_URL/api/v1/rbac/check?user=admin&resource=user&action=read' -H 'Authorization: Bearer $token' | jq -e '.status == \"success\"'"
}

# 测试获取用户角色
test_get_user_roles() {
    local token="$1"
    run_test "获取用户角色" "curl -s -X GET '$SERVER_URL/api/v1/rbac/roles' -H 'Authorization: Bearer $token' | jq -e '.status == \"success\"'"
}

# 测试获取用户权限
test_get_user_permissions() {
    local token="$1"
    run_test "获取用户权限" "curl -s -X GET '$SERVER_URL/api/v1/rbac/permissions' -H 'Authorization: Bearer $token' | jq -e '.status == \"success\"'"
}

# 测试用户注册
test_user_registration() {
    local timestamp=$(date +%s)
    local username="testuser$timestamp"
    run_test "用户注册" "curl -s -X POST '$SERVER_URL/api/v1/public/register' -H 'Content-Type: application/json' -d '{\"username\":\"$username\",\"email\":\"$username@example.com\",\"password\":\"TestPassword123!\",\"first_name\":\"Test\",\"last_name\":\"User\"}' | jq -e '.status == \"success\"'"
}

# 主测试函数
main() {
    echo "=========================================="
    echo "🧪 权限管理系统测试工具"
    echo "=========================================="
    
    # 检查服务器
    if ! check_server; then
        exit 1
    fi
    
    # 运行基础测试
    test_health_check
    test_super_admin_status
    test_user_login
    
    # 获取Token进行认证测试
    local token=$(get_admin_token)
    if [ -z "$token" ]; then
        log_error "无法获取Token，跳过需要认证的测试"
        exit 1
    fi
    
    # 运行认证相关测试
    test_protected_endpoints "$token"
    test_rbac_permission_check "$token"
    test_get_user_roles "$token"
    test_get_user_permissions "$token"
    
    # 运行其他测试
    test_user_registration
    
    # 显示测试结果
    echo "=========================================="
    echo "📊 测试结果摘要"
    echo "=========================================="
    echo "总测试数: $TOTAL_TESTS"
    echo "通过测试: $PASSED_TESTS"
    echo "失败测试: $FAILED_TESTS"
    echo "通过率: $(( (PASSED_TESTS * 100) / TOTAL_TESTS ))%"
    echo "=========================================="
    
    if [ $FAILED_TESTS -eq 0 ]; then
        log_success "所有测试通过！权限管理系统运行正常。"
        exit 0
    else
        log_error "有 $FAILED_TESTS 个测试失败，请检查系统配置。"
        exit 1
    fi
}

# 运行主函数
main "$@"
