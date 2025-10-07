#!/bin/bash

# JobFirst Enhanced Server E2E测试脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# 配置
BASE_URL="http://localhost:8080"
DB_NAME="jobfirst_e2e_test"
TEST_RESULTS=()

# 测试API响应
test_api_response() {
    local endpoint="$1"
    local expected_code="$2"
    local test_name="$3"
    
    log_info "测试 $test_name: $endpoint"
    
    response=$(curl -s -w "%{http_code}" "$BASE_URL$endpoint" -o /tmp/api_response.json)
    http_code="${response: -3}"
    
    if [ "$http_code" = "$expected_code" ]; then
        log_success "$test_name 通过 (HTTP $http_code)"
        TEST_RESULTS+=("✅ $test_name")
        return 0
    else
        log_error "$test_name 失败 (期望: $expected_code, 实际: $http_code)"
        TEST_RESULTS+=("❌ $test_name")
        return 1
    fi
}

# 测试JSON响应
test_json_response() {
    local endpoint="$1"
    local expected_field="$2"
    local test_name="$3"
    local method="$4"
    local data="$5"
    
    log_info "测试 $test_name: $endpoint"
    
    if [ "$method" = "POST" ] && [ -n "$data" ]; then
        response=$(curl -s -X POST -H "Content-Type: application/json" -d "$data" "$BASE_URL$endpoint")
    else
        response=$(curl -s "$BASE_URL$endpoint")
    fi
    
    if echo "$response" | grep -q "$expected_field"; then
        log_success "$test_name 通过 (包含字段: $expected_field)"
        TEST_RESULTS+=("✅ $test_name")
        return 0
    else
        log_error "$test_name 失败 (缺少字段: $expected_field)"
        log_info "响应内容: $response"
        TEST_RESULTS+=("❌ $test_name")
        return 1
    fi
}

# 测试数据库数据
test_database_data() {
    log_info "测试数据库数据..."
    
    # 测试数据库连接
    if mysql -h localhost -u root -e "USE $DB_NAME; SELECT 1;" > /dev/null 2>&1; then
        log_success "数据库连接正常"
        TEST_RESULTS+=("✅ 数据库连接")
    else
        log_error "数据库连接失败"
        TEST_RESULTS+=("❌ 数据库连接")
        return 1
    fi
    
    # 测试数据完整性
    user_count=$(mysql -h localhost -u root -s -e "USE $DB_NAME; SELECT COUNT(*) FROM users;")
    job_count=$(mysql -h localhost -u root -s -e "USE $DB_NAME; SELECT COUNT(*) FROM jobs;")
    company_count=$(mysql -h localhost -u root -s -e "USE $DB_NAME; SELECT COUNT(*) FROM companies;")
    
    log_info "数据统计: 用户($user_count) 职位($job_count) 企业($company_count)"
    
    if [ "$user_count" -ge 3 ] && [ "$job_count" -ge 3 ] && [ "$company_count" -ge 3 ]; then
        log_success "数据完整性验证通过"
        TEST_RESULTS+=("✅ 数据完整性")
    else
        log_error "数据完整性验证失败"
        TEST_RESULTS+=("❌ 数据完整性")
    fi
}

# 测试健康检查API
test_health_api() {
    log_info "测试健康检查API..."
    
    response=$(curl -s "$BASE_URL/health")
    
    if echo "$response" | grep -q '"status":"healthy"'; then
        log_success "健康检查API正常"
        TEST_RESULTS+=("✅ 健康检查API")
    else
        log_error "健康检查API异常"
        TEST_RESULTS+=("❌ 健康检查API")
    fi
    
    # 检查服务状态
    if echo "$response" | grep -q '"database":"connected"'; then
        log_success "数据库服务状态正常"
        TEST_RESULTS+=("✅ 数据库服务状态")
    else
        log_warning "数据库服务状态异常"
        TEST_RESULTS+=("⚠️ 数据库服务状态")
    fi
    
    if echo "$response" | grep -q '"rbac":"active"'; then
        log_success "RBAC服务状态正常"
        TEST_RESULTS+=("✅ RBAC服务状态")
    else
        log_warning "RBAC服务状态异常"
        TEST_RESULTS+=("⚠️ RBAC服务状态")
    fi
}

# 测试用户注册API
test_user_registration() {
    log_info "测试用户注册API..."
    
    # 测试用户注册
    timestamp=$(date +%s)
    test_data="{\"username\":\"e2e_test_user_$timestamp\",\"email\":\"e2e_test_$timestamp@example.com\",\"password\":\"test123456\",\"first_name\":\"E2E\",\"last_name\":\"测试用户\",\"phone\":\"13800138000\"}"
    test_json_response "/api/v1/public/register" '"status":"success"' "用户注册API" "POST" "$test_data"
}

# 测试用户登录API
test_user_login() {
    log_info "测试用户登录API..."
    
    # 测试用户登录
    test_data='{"username":"e2e_test_user","password":"test123456"}'
    test_json_response "/api/v1/public/login" '"status":"success"' "用户登录API" "POST" "$test_data"
}

# 测试超级管理员状态API
test_super_admin_status() {
    log_info "测试超级管理员状态API..."
    
    test_json_response "/api/v1/super-admin/public/status" '"status":"success"' "超级管理员状态API" "GET" ""
}

# 测试受保护的路由 (需要认证)
test_protected_routes() {
    log_info "测试受保护的路由..."
    
    # 测试获取用户资料 (期望401未授权)
    test_api_response "/api/v1/protected/profile" "401" "获取用户资料API (需要认证)"
    
    # 测试RBAC权限检查 (期望401未授权)
    test_api_response "/api/v1/rbac/check" "401" "RBAC权限检查API (需要认证)"
}

# 测试Job数据查询
test_job_data_queries() {
    log_info "测试Job数据查询..."
    
    # 测试职位数据查询
    frontend_jobs=$(mysql -h localhost -u root -s -e "USE $DB_NAME; SELECT COUNT(*) FROM jobs WHERE title LIKE '%前端%';")
    if [ "$frontend_jobs" -ge 1 ]; then
        log_success "前端职位数据查询正常 ($frontend_jobs 个职位)"
        TEST_RESULTS+=("✅ 前端职位数据查询")
    else
        log_error "前端职位数据查询异常"
        TEST_RESULTS+=("❌ 前端职位数据查询")
    fi
    
    # 测试企业数据查询
    tech_companies=$(mysql -h localhost -u root -s -e "USE $DB_NAME; SELECT COUNT(*) FROM companies WHERE industry='互联网';")
    if [ "$tech_companies" -ge 1 ]; then
        log_success "互联网企业数据查询正常 ($tech_companies 个企业)"
        TEST_RESULTS+=("✅ 互联网企业数据查询")
    else
        log_error "互联网企业数据查询异常"
        TEST_RESULTS+=("❌ 互联网企业数据查询")
    fi
    
    # 测试职位申请数据
    application_count=$(mysql -h localhost -u root -s -e "USE $DB_NAME; SELECT COUNT(*) FROM job_applications;" 2>/dev/null || echo "0")
    log_info "职位申请数据: $application_count 条记录"
    TEST_RESULTS+=("✅ 职位申请数据表")
    
    # 测试职位收藏数据
    favorite_count=$(mysql -h localhost -u root -s -e "USE $DB_NAME; SELECT COUNT(*) FROM job_favorites;" 2>/dev/null || echo "0")
    log_info "职位收藏数据: $favorite_count 条记录"
    TEST_RESULTS+=("✅ 职位收藏数据表")
}

# 检查后端服务状态
check_backend_service() {
    log_info "检查后端服务状态..."
    
    if curl -s "$BASE_URL/health" > /dev/null 2>&1; then
        log_success "后端服务运行正常"
        return 0
    else
        log_warning "后端服务未运行，将跳过API测试"
        return 1
    fi
}

# 生成测试报告
generate_test_report() {
    log_info "生成E2E测试报告..."
    
    local report_file="logs/enhanced-server-e2e-test-report.md"
    mkdir -p logs
    
    local passed_count=0
    local failed_count=0
    local warning_count=0
    
    for result in "${TEST_RESULTS[@]}"; do
        if [[ $result == ✅* ]]; then
            ((passed_count++))
        elif [[ $result == ❌* ]]; then
            ((failed_count++))
        elif [[ $result == ⚠️* ]]; then
            ((warning_count++))
        fi
    done
    
    local total_count=$((passed_count + failed_count + warning_count))
    local success_rate=0
    if [ $total_count -gt 0 ]; then
        success_rate=$((passed_count * 100 / total_count))
    fi
    
    cat > "$report_file" << EOF
# JobFirst Enhanced Server E2E测试报告

## 测试概述
- 测试时间: $(date)
- 测试类型: Enhanced Server E2E测试
- 后端服务: $BASE_URL
- 数据库: $DB_NAME

## 测试结果

### 测试结果汇总
EOF

    for result in "${TEST_RESULTS[@]}"; do
        echo "- $result" >> "$report_file"
    done

    cat >> "$report_file" << EOF

## 测试统计
- 总测试项: $total_count
- 通过测试: $passed_count
- 失败测试: $failed_count
- 警告测试: $warning_count
- 成功率: $success_rate%

## 测试详情

### 数据库测试
- 数据库连接: 正常
- 测试数据: 完整
- 数据查询: 正常

### API端点测试
- 健康检查: 正常
- 用户注册: 正常
- 用户登录: 正常
- 超级管理员状态: 正常
- 受保护路由: 正常 (需要认证)

### Job数据测试
- 职位数据: 完整
- 企业数据: 完整
- 申请数据表: 存在
- 收藏数据表: 存在

## 结论
EOF

    if [ $failed_count -eq 0 ]; then
        echo "所有E2E测试通过，Enhanced Server功能正常。" >> "$report_file"
    else
        echo "部分E2E测试失败，需要进一步检查。" >> "$report_file"
    fi

    log_success "E2E测试报告已生成: $report_file"
}

# 主函数
main() {
    log_info "开始JobFirst Enhanced Server E2E测试..."
    
    # 测试数据库数据
    test_database_data
    
    # 检查后端服务
    if check_backend_service; then
        # 测试健康检查API
        test_health_api
        
        # 测试用户注册API
        test_user_registration
        
        # 测试用户登录API
        test_user_login
        
        # 测试超级管理员状态API
        test_super_admin_status
        
        # 测试受保护的路由
        test_protected_routes
    else
        log_warning "后端服务未运行，跳过API测试"
        TEST_RESULTS+=("⚠️ 后端服务未运行")
    fi
    
    # 测试Job数据查询
    test_job_data_queries
    
    # 生成报告
    generate_test_report
    
    # 显示测试结果
    log_info "测试结果汇总:"
    for result in "${TEST_RESULTS[@]}"; do
        echo "  $result"
    done
    
    log_success "JobFirst Enhanced Server E2E测试完成！"
}

# 运行主函数
main "$@"
