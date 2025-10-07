#!/bin/bash

# 统一认证系统测试脚本
# 测试所有API端点的功能

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置
AUTH_SERVICE_URL="http://localhost:8207"
TEST_USERNAME="admin"
TEST_PASSWORD="admin123"

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

# 检查服务是否运行
check_service() {
    log_info "检查认证服务状态..."
    if curl -s "$AUTH_SERVICE_URL/health" > /dev/null; then
        log_success "认证服务正在运行"
        return 0
    else
        log_error "认证服务未运行，请先启动服务"
        return 1
    fi
}

# 测试健康检查
test_health() {
    log_info "测试健康检查端点..."
    response=$(curl -s "$AUTH_SERVICE_URL/health")
    if echo "$response" | jq -e '.status == "healthy"' > /dev/null; then
        log_success "健康检查通过"
        echo "$response" | jq .
    else
        log_error "健康检查失败"
        echo "$response"
        return 1
    fi
}

# 测试用户登录
test_login() {
    log_info "测试用户登录..."
    response=$(curl -s -X POST "$AUTH_SERVICE_URL/api/v1/auth/login" \
        -H "Content-Type: application/json" \
        -d "{\"username\":\"$TEST_USERNAME\",\"password\":\"$TEST_PASSWORD\"}")
    
    if echo "$response" | jq -e '.success == true' > /dev/null; then
        log_success "登录成功"
        TOKEN=$(echo "$response" | jq -r '.token')
        echo "Token: $TOKEN"
        return 0
    else
        log_error "登录失败"
        echo "$response" | jq .
        return 1
    fi
}

# 测试JWT验证
test_validate_jwt() {
    if [ -z "$TOKEN" ]; then
        log_error "没有有效的token，跳过JWT验证测试"
        return 1
    fi
    
    log_info "测试JWT验证..."
    response=$(curl -s -X POST "$AUTH_SERVICE_URL/api/v1/auth/validate" \
        -H "Content-Type: application/json" \
        -d "{\"token\":\"$TOKEN\"}")
    
    if echo "$response" | jq -e '.success == true' > /dev/null; then
        log_success "JWT验证成功"
        echo "$response" | jq .
        USER_ID=$(echo "$response" | jq -r '.user.id')
        return 0
    else
        log_error "JWT验证失败"
        echo "$response" | jq .
        return 1
    fi
}

# 测试权限检查
test_permission_check() {
    if [ -z "$USER_ID" ]; then
        log_error "没有有效的用户ID，跳过权限检查测试"
        return 1
    fi
    
    log_info "测试权限检查..."
    
    # 测试管理员权限
    response=$(curl -s "$AUTH_SERVICE_URL/api/v1/auth/permission?user_id=$USER_ID&permission=admin:users")
    if echo "$response" | jq -e '.has_permission == true' > /dev/null; then
        log_success "管理员权限检查通过"
    else
        log_warning "管理员权限检查失败"
    fi
    echo "$response" | jq .
    
    # 测试普通权限
    response=$(curl -s "$AUTH_SERVICE_URL/api/v1/auth/permission?user_id=$USER_ID&permission=read:own")
    if echo "$response" | jq -e '.has_permission == true' > /dev/null; then
        log_success "普通权限检查通过"
    else
        log_warning "普通权限检查失败"
    fi
    echo "$response" | jq .
}

# 测试用户信息获取
test_get_user() {
    if [ -z "$USER_ID" ]; then
        log_error "没有有效的用户ID，跳过用户信息获取测试"
        return 1
    fi
    
    log_info "测试用户信息获取..."
    response=$(curl -s "$AUTH_SERVICE_URL/api/v1/auth/user?user_id=$USER_ID")
    
    if echo "$response" | jq -e '.id' > /dev/null; then
        log_success "用户信息获取成功"
        echo "$response" | jq .
    else
        log_error "用户信息获取失败"
        echo "$response" | jq .
        return 1
    fi
}

# 测试访问验证
test_validate_access() {
    if [ -z "$USER_ID" ]; then
        log_error "没有有效的用户ID，跳过访问验证测试"
        return 1
    fi
    
    log_info "测试访问验证..."
    response=$(curl -s -X POST "$AUTH_SERVICE_URL/api/v1/auth/access" \
        -H "Content-Type: application/json" \
        -d "{\"user_id\":$USER_ID,\"resource\":\"users\",\"action\":\"admin\"}")
    
    if echo "$response" | jq -e '.has_permission == true' > /dev/null; then
        log_success "访问验证成功"
    else
        log_warning "访问验证失败"
    fi
    echo "$response" | jq .
}

# 测试角色列表获取
test_get_roles() {
    log_info "测试角色列表获取..."
    response=$(curl -s "$AUTH_SERVICE_URL/api/v1/auth/roles")
    
    if echo "$response" | jq -e '.guest' > /dev/null; then
        log_success "角色列表获取成功"
        echo "$response" | jq .
    else
        log_error "角色列表获取失败"
        echo "$response" | jq .
        return 1
    fi
}

# 测试权限列表获取
test_get_permissions() {
    log_info "测试权限列表获取..."
    response=$(curl -s "$AUTH_SERVICE_URL/api/v1/auth/permissions?role=admin")
    
    if echo "$response" | jq -e '.permissions' > /dev/null; then
        log_success "权限列表获取成功"
        echo "$response" | jq .
    else
        log_error "权限列表获取失败"
        echo "$response" | jq .
        return 1
    fi
}

# 测试访问日志记录
test_log_access() {
    if [ -z "$USER_ID" ]; then
        log_error "没有有效的用户ID，跳过访问日志测试"
        return 1
    fi
    
    log_info "测试访问日志记录..."
    response=$(curl -s -X POST "$AUTH_SERVICE_URL/api/v1/auth/log" \
        -H "Content-Type: application/json" \
        -d "{\"user_id\":$USER_ID,\"action\":\"test\",\"resource\":\"api\",\"result\":\"success\",\"ip_address\":\"127.0.0.1\",\"user_agent\":\"test-script\"}")
    
    if echo "$response" | jq -e '.success == true' > /dev/null; then
        log_success "访问日志记录成功"
        echo "$response" | jq .
    else
        log_error "访问日志记录失败"
        echo "$response" | jq .
        return 1
    fi
}

# 主测试函数
main() {
    echo "=========================================="
    echo "🧪 统一认证系统测试开始"
    echo "=========================================="
    
    # 检查服务状态
    if ! check_service; then
        exit 1
    fi
    
    # 运行所有测试
    test_health
    test_login
    test_validate_jwt
    test_permission_check
    test_get_user
    test_validate_access
    test_get_roles
    test_get_permissions
    test_log_access
    
    echo "=========================================="
    echo "✅ 统一认证系统测试完成"
    echo "=========================================="
}

# 运行主函数
main "$@"
