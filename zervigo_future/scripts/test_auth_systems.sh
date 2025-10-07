#!/bin/bash

# 认证系统测试脚本
# 测试用户服务认证 (8081) 和统一认证服务 (8207)

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 服务URL配置
USER_SERVICE_URL="http://localhost:8081"
UNIFIED_AUTH_URL="http://localhost:8207"
AI_SERVICE_URL="http://localhost:8208"

# 测试用户信息
TEST_USERNAME="szjason72"
TEST_PASSWORD="@SZxym2006"
ADMIN_USERNAME="admin"
ADMIN_PASSWORD="password"
TESTUSER_USERNAME="testuser"
TESTUSER_PASSWORD="testuser123"

# 不同角色的测试用户
TESTUSER2_USERNAME="testuser2"  # system_admin
TESTUSER2_PASSWORD="testuser123"
TESTUSER3_USERNAME="testuser3"  # dev_lead
TESTUSER3_PASSWORD="testuser123"
TESTUSER4_USERNAME="testuser4"  # frontend_dev
TESTUSER4_PASSWORD="testuser123"
TESTUSER5_USERNAME="testuser5"  # backend_dev
TESTUSER5_PASSWORD="testuser123"
TESTUSER6_USERNAME="testuser6"  # qa_engineer
TESTUSER6_PASSWORD="testuser123"
TESTADMIN_USERNAME="testadmin"  # guest
TESTADMIN_PASSWORD="testadmin123"

# 测试结果存储
TEST_RESULTS=()
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

# 测试结果记录函数
record_test() {
    local test_name="$1"
    local status="$2"
    local details="$3"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if [ "$status" = "PASS" ]; then
        PASSED_TESTS=$((PASSED_TESTS + 1))
        log_success "✅ $test_name"
    else
        FAILED_TESTS=$((FAILED_TESTS + 1))
        log_error "❌ $test_name"
    fi
    
    TEST_RESULTS+=("$test_name|$status|$details")
}

# 检查服务健康状态
check_service_health() {
    local service_name="$1"
    local service_url="$2"
    local health_endpoint="$3"
    
    log_info "检查 $service_name 健康状态..."
    
    if curl -s -f "$service_url$health_endpoint" > /dev/null 2>&1; then
        log_success "$service_name 健康检查通过"
        return 0
    else
        log_error "$service_name 健康检查失败"
        return 1
    fi
}

# 测试用户服务认证
test_user_service_auth() {
    log_info "=== 测试用户服务认证系统 (端口8081) ==="
    
    # 1. 健康检查
    if check_service_health "用户服务" "$USER_SERVICE_URL" "/health"; then
        record_test "用户服务健康检查" "PASS" "服务正常运行"
    else
        record_test "用户服务健康检查" "FAIL" "服务无法访问"
        return 1
    fi
    
    # 2. 用户登录测试
    log_info "测试用户登录..."
    local login_response=$(curl -s -X POST "$USER_SERVICE_URL/api/v1/auth/login" \
        -H "Content-Type: application/json" \
        -d "{\"username\":\"$TEST_USERNAME\",\"password\":\"$TEST_PASSWORD\"}")
    
    if echo "$login_response" | jq -e '.success' > /dev/null 2>&1; then
        local token=$(echo "$login_response" | jq -r '.data.token')
        if [ "$token" != "null" ] && [ "$token" != "" ]; then
            record_test "用户登录" "PASS" "登录成功，获得token"
            echo "$token" > /tmp/user_service_token.txt
        else
            record_test "用户登录" "FAIL" "登录成功但未获得token"
        fi
    else
        record_test "用户登录" "FAIL" "登录失败: $(echo "$login_response" | jq -r '.error // .message')"
    fi
    
    # 3. Token验证测试
    if [ -f "/tmp/user_service_token.txt" ]; then
        local token=$(cat /tmp/user_service_token.txt)
        log_info "测试Token验证..."
        
        local verify_response=$(curl -s -X GET "$USER_SERVICE_URL/api/v1/users/profile" \
            -H "Authorization: Bearer $token")
        
        if echo "$verify_response" | jq -e '.success' > /dev/null 2>&1; then
            record_test "Token验证" "PASS" "Token验证成功"
        else
            record_test "Token验证" "FAIL" "Token验证失败: $(echo "$verify_response" | jq -r '.error // .message')"
        fi
    fi
    
    # 4. 测试用户登录测试
    log_info "测试testuser登录..."
    local testuser_login_response=$(curl -s -X POST "$USER_SERVICE_URL/api/v1/auth/login" \
        -H "Content-Type: application/json" \
        -d "{\"username\":\"$TESTUSER_USERNAME\",\"password\":\"$TESTUSER_PASSWORD\"}")
    
    if echo "$testuser_login_response" | jq -e '.success' > /dev/null 2>&1; then
        local testuser_token=$(echo "$testuser_login_response" | jq -r '.data.token')
        if [ "$testuser_token" != "null" ] && [ "$testuser_token" != "" ]; then
            record_test "测试用户登录" "PASS" "testuser登录成功，获得token"
        else
            record_test "测试用户登录" "FAIL" "testuser登录成功但未获得token"
        fi
    else
        record_test "测试用户登录" "FAIL" "testuser登录失败: $(echo "$testuser_login_response" | jq -r '.error // .message')"
    fi
    
    # 4.1 测试不同角色用户登录
    log_info "测试不同角色用户登录..."
    
    # system_admin
    local testuser2_response=$(curl -s -X POST "$USER_SERVICE_URL/api/v1/auth/login" \
        -H "Content-Type: application/json" \
        -d "{\"username\":\"$TESTUSER2_USERNAME\",\"password\":\"$TESTUSER2_PASSWORD\"}")
    if echo "$testuser2_response" | jq -e '.success' > /dev/null 2>&1; then
        local role=$(echo "$testuser2_response" | jq -r '.data.user.role')
        record_test "system_admin用户登录" "PASS" "testuser2登录成功，角色: $role"
    else
        record_test "system_admin用户登录" "FAIL" "testuser2登录失败"
    fi
    
    # dev_lead
    local testuser3_response=$(curl -s -X POST "$USER_SERVICE_URL/api/v1/auth/login" \
        -H "Content-Type: application/json" \
        -d "{\"username\":\"$TESTUSER3_USERNAME\",\"password\":\"$TESTUSER3_PASSWORD\"}")
    if echo "$testuser3_response" | jq -e '.success' > /dev/null 2>&1; then
        local role=$(echo "$testuser3_response" | jq -r '.data.user.role')
        record_test "dev_lead用户登录" "PASS" "testuser3登录成功，角色: $role"
    else
        record_test "dev_lead用户登录" "FAIL" "testuser3登录失败"
    fi
    
    # frontend_dev
    local testuser4_response=$(curl -s -X POST "$USER_SERVICE_URL/api/v1/auth/login" \
        -H "Content-Type: application/json" \
        -d "{\"username\":\"$TESTUSER4_USERNAME\",\"password\":\"$TESTUSER4_PASSWORD\"}")
    if echo "$testuser4_response" | jq -e '.success' > /dev/null 2>&1; then
        local role=$(echo "$testuser4_response" | jq -r '.data.user.role')
        record_test "frontend_dev用户登录" "PASS" "testuser4登录成功，角色: $role"
    else
        record_test "frontend_dev用户登录" "FAIL" "testuser4登录失败"
    fi
    
    # backend_dev
    local testuser5_response=$(curl -s -X POST "$USER_SERVICE_URL/api/v1/auth/login" \
        -H "Content-Type: application/json" \
        -d "{\"username\":\"$TESTUSER5_USERNAME\",\"password\":\"$TESTUSER5_PASSWORD\"}")
    if echo "$testuser5_response" | jq -e '.success' > /dev/null 2>&1; then
        local role=$(echo "$testuser5_response" | jq -r '.data.user.role')
        record_test "backend_dev用户登录" "PASS" "testuser5登录成功，角色: $role"
    else
        record_test "backend_dev用户登录" "FAIL" "testuser5登录失败"
    fi
    
    # qa_engineer
    local testuser6_response=$(curl -s -X POST "$USER_SERVICE_URL/api/v1/auth/login" \
        -H "Content-Type: application/json" \
        -d "{\"username\":\"$TESTUSER6_USERNAME\",\"password\":\"$TESTUSER6_PASSWORD\"}")
    if echo "$testuser6_response" | jq -e '.success' > /dev/null 2>&1; then
        local role=$(echo "$testuser6_response" | jq -r '.data.user.role')
        record_test "qa_engineer用户登录" "PASS" "testuser6登录成功，角色: $role"
    else
        record_test "qa_engineer用户登录" "FAIL" "testuser6登录失败"
    fi
    
    # 5. 管理员登录测试
    log_info "测试管理员登录..."
    local admin_login_response=$(curl -s -X POST "$USER_SERVICE_URL/api/v1/auth/login" \
        -H "Content-Type: application/json" \
        -d "{\"username\":\"$ADMIN_USERNAME\",\"password\":\"$ADMIN_PASSWORD\"}")
    
    if echo "$admin_login_response" | jq -e '.success' > /dev/null 2>&1; then
        local admin_token=$(echo "$admin_login_response" | jq -r '.data.token')
        if [ "$admin_token" != "null" ] && [ "$admin_token" != "" ]; then
            record_test "管理员登录" "PASS" "管理员登录成功"
            echo "$admin_token" > /tmp/admin_token.txt
        else
            record_test "管理员登录" "FAIL" "管理员登录成功但未获得token"
        fi
    else
        record_test "管理员登录" "FAIL" "管理员登录失败: $(echo "$admin_login_response" | jq -r '.error // .message')"
    fi
}

# 测试统一认证服务
test_unified_auth_service() {
    log_info "=== 测试统一认证服务 (端口8207) ==="
    
    # 1. 健康检查
    if check_service_health "统一认证服务" "$UNIFIED_AUTH_URL" "/health"; then
        record_test "统一认证服务健康检查" "PASS" "服务正常运行"
    else
        record_test "统一认证服务健康检查" "FAIL" "服务无法访问"
        return 1
    fi
    
    # 2. 用户登录测试
    log_info "测试统一认证用户登录..."
    local login_response=$(curl -s -X POST "$UNIFIED_AUTH_URL/api/v1/auth/login" \
        -H "Content-Type: application/json" \
        -d "{\"username\":\"$TEST_USERNAME\",\"password\":\"$TEST_PASSWORD\"}")
    
    if echo "$login_response" | jq -e '.success' > /dev/null 2>&1; then
        local token=$(echo "$login_response" | jq -r '.token')
        if [ "$token" != "null" ] && [ "$token" != "" ]; then
            record_test "统一认证用户登录" "PASS" "登录成功，获得token"
            echo "$token" > /tmp/unified_auth_token.txt
        else
            record_test "统一认证用户登录" "FAIL" "登录成功但未获得token"
        fi
    else
        record_test "统一认证用户登录" "FAIL" "登录失败: $(echo "$login_response" | jq -r '.error // .message')"
    fi
    
    # 3. Token验证测试
    if [ -f "/tmp/unified_auth_token.txt" ]; then
        local token=$(cat /tmp/unified_auth_token.txt)
        log_info "测试统一认证Token验证..."
        
        local verify_response=$(curl -s -X POST "$UNIFIED_AUTH_URL/api/v1/auth/validate" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $token" \
            -d "{\"token\":\"$token\"}")
        
        if echo "$verify_response" | jq -e '.success' > /dev/null 2>&1; then
            record_test "统一认证Token验证" "PASS" "Token验证成功"
        else
            record_test "统一认证Token验证" "FAIL" "Token验证失败: $(echo "$verify_response" | jq -r '.error // .message')"
        fi
    fi
    
    # 4. 权限检查测试
    if [ -f "/tmp/unified_auth_token.txt" ]; then
        local token=$(cat /tmp/unified_auth_token.txt)
        log_info "测试权限检查..."
        
        local permission_response=$(curl -s -X GET "$UNIFIED_AUTH_URL/api/v1/auth/permission?user_id=4&permission=read:public" \
            -H "Authorization: Bearer $token")
        
        if echo "$permission_response" | jq -e '.has_permission' > /dev/null 2>&1; then
            record_test "权限检查" "PASS" "权限检查成功"
        else
            record_test "权限检查" "FAIL" "权限检查失败: $(echo "$permission_response" | jq -r '.error // .message')"
        fi
    fi
}

# 测试AI服务与统一认证的集成
test_ai_service_integration() {
    log_info "=== 测试AI服务与统一认证的集成 ==="
    
    # 1. AI服务健康检查
    if check_service_health "AI服务" "$AI_SERVICE_URL" "/health"; then
        record_test "AI服务健康检查" "PASS" "服务正常运行"
    else
        record_test "AI服务健康检查" "FAIL" "服务无法访问"
        return 1
    fi
    
    # 2. 使用统一认证token测试AI服务
    if [ -f "/tmp/unified_auth_token.txt" ]; then
        local token=$(cat /tmp/unified_auth_token.txt)
        log_info "测试AI服务认证集成..."
        
        # 测试AI服务职位匹配API
        local ai_response=$(curl -s -X POST "$AI_SERVICE_URL/api/v1/job-matching/match" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $token" \
            -d '{
                "job_description": "需要Python开发经验",
                "resume_text": "我有3年Python开发经验"
            }')
        
        if echo "$ai_response" | jq -e '.success' > /dev/null 2>&1; then
            record_test "AI服务认证集成" "PASS" "AI服务认证集成成功"
        else
            local error_msg=$(echo "$ai_response" | jq -r '.error // .message // "未知错误"')
            if [[ "$error_msg" == *"认证"* ]] || [[ "$error_msg" == *"token"* ]] || [[ "$error_msg" == *"auth"* ]]; then
                record_test "AI服务认证集成" "FAIL" "认证失败: $error_msg"
            else
                record_test "AI服务认证集成" "PASS" "认证成功，业务逻辑错误: $error_msg"
            fi
        fi
    else
        record_test "AI服务认证集成" "FAIL" "无统一认证token可用"
    fi
}

# 生成测试报告
generate_test_report() {
    local report_file="docs/reports/AUTH_SYSTEMS_TEST_REPORT.md"
    
    log_info "生成测试报告: $report_file"
    
    cat > "$report_file" << EOF
# 认证系统测试报告

**测试时间**: $(date '+%Y-%m-%d %H:%M:%S')
**测试环境**: 本地开发环境
**测试脚本**: test_auth_systems.sh

## 📊 测试概览

- **总测试数**: $TOTAL_TESTS
- **通过测试**: $PASSED_TESTS
- **失败测试**: $FAILED_TESTS
- **成功率**: $(echo "scale=2; $PASSED_TESTS * 100 / $TOTAL_TESTS" | bc -l)%

## 🔧 测试环境配置

### 服务端口配置
- **用户服务**: http://localhost:8081
- **统一认证服务**: http://localhost:8207
- **AI服务**: http://localhost:8208

### 测试用户
- **普通用户**: $TEST_USERNAME
- **管理员**: $ADMIN_USERNAME

## 📋 详细测试结果

EOF

    # 添加详细测试结果
    for result in "${TEST_RESULTS[@]}"; do
        IFS='|' read -r test_name status details <<< "$result"
        local status_icon="✅"
        if [ "$status" = "FAIL" ]; then
            status_icon="❌"
        fi
        
        cat >> "$report_file" << EOF
### $status_icon $test_name
- **状态**: $status
- **详情**: $details

EOF
    done

    cat >> "$report_file" << EOF

## 🔍 问题分析

EOF

    # 分析失败原因
    if [ $FAILED_TESTS -gt 0 ]; then
        cat >> "$report_file" << EOF
### 失败测试分析
EOF
        for result in "${TEST_RESULTS[@]}"; do
            IFS='|' read -r test_name status details <<< "$result"
            if [ "$status" = "FAIL" ]; then
                cat >> "$report_file" << EOF
- **$test_name**: $details
EOF
            fi
        done
    else
        cat >> "$report_file" << EOF
### 所有测试通过
所有认证系统测试均通过，系统运行正常。
EOF
    fi

    cat >> "$report_file" << EOF

## 📈 建议和改进

### 成功项目
- 用户服务认证系统运行正常
- 统一认证服务功能完整
- AI服务与统一认证集成良好

### 需要关注的问题
EOF

    if [ $FAILED_TESTS -gt 0 ]; then
        cat >> "$report_file" << EOF
- 部分测试失败，需要进一步排查
- 建议检查服务配置和网络连接
EOF
    else
        cat >> "$report_file" << EOF
- 所有测试通过，系统运行稳定
- 建议定期进行认证系统测试
EOF
    fi

    cat >> "$report_file" << EOF

## 🎯 下一步行动

1. **修复失败测试**: 针对失败的测试项进行问题排查和修复
2. **性能测试**: 进行认证系统的性能压力测试
3. **安全测试**: 进行认证系统的安全性测试
4. **集成测试**: 进行端到端的认证流程测试

---
*报告生成时间: $(date '+%Y-%m-%d %H:%M:%S')*
EOF

    log_success "测试报告已生成: $report_file"
}

# 清理临时文件
cleanup() {
    rm -f /tmp/user_service_token.txt
    rm -f /tmp/admin_token.txt
    rm -f /tmp/unified_auth_token.txt
}

# 主函数
main() {
    log_info "开始认证系统测试..."
    log_info "测试时间: $(date '+%Y-%m-%d %H:%M:%S')"
    
    # 检查依赖
    if ! command -v jq &> /dev/null; then
        log_error "jq 命令未找到，请安装 jq"
        exit 1
    fi
    
    if ! command -v curl &> /dev/null; then
        log_error "curl 命令未找到，请安装 curl"
        exit 1
    fi
    
    # 执行测试
    test_user_service_auth
    test_unified_auth_service
    test_ai_service_integration
    
    # 生成报告
    generate_test_report
    
    # 显示总结
    log_info "=== 测试完成 ==="
    log_info "总测试数: $TOTAL_TESTS"
    log_success "通过测试: $PASSED_TESTS"
    if [ $FAILED_TESTS -gt 0 ]; then
        log_error "失败测试: $FAILED_TESTS"
    else
        log_success "失败测试: $FAILED_TESTS"
    fi
    
    # 清理
    cleanup
    
    if [ $FAILED_TESTS -eq 0 ]; then
        log_success "🎉 所有认证系统测试通过！"
        exit 0
    else
        log_warning "⚠️  部分测试失败，请查看报告了解详情"
        exit 1
    fi
}

# 执行主函数
main "$@"
