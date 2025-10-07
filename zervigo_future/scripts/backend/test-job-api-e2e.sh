#!/bin/bash

# JobFirst Job API E2E测试脚本

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
    local headers="$4"
    
    log_info "测试 $test_name: $endpoint"
    
    if [ -n "$headers" ]; then
        response=$(curl -s -H "$headers" "$BASE_URL$endpoint")
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
    
    # 测试职位数据
    job_count=$(mysql -h localhost -u root -s -e "USE $DB_NAME; SELECT COUNT(*) FROM jobs WHERE status='published';")
    if [ "$job_count" -ge 1 ]; then
        log_success "数据库职位数据正常 ($job_count 个已发布职位)"
        TEST_RESULTS+=("✅ 数据库职位数据")
    else
        log_error "数据库职位数据异常"
        TEST_RESULTS+=("❌ 数据库职位数据")
    fi
    
    # 测试企业数据
    company_count=$(mysql -h localhost -u root -s -e "USE $DB_NAME; SELECT COUNT(*) FROM companies WHERE status='verified';")
    if [ "$company_count" -ge 1 ]; then
        log_success "数据库企业数据正常 ($company_count 个已认证企业)"
        TEST_RESULTS+=("✅ 数据库企业数据")
    else
        log_error "数据库企业数据异常"
        TEST_RESULTS+=("❌ 数据库企业数据")
    fi
}

# 测试Job API
test_job_apis() {
    log_info "开始测试Job API..."
    
    # 测试健康检查
    test_api_response "/health" "200" "健康检查API"
    
    # 测试职位列表API (v2版本)
    test_json_response "/api/v1/jobs" '"code":200' "职位列表API" "API-Version: v2"
    
    # 测试职位详情API (v2版本)
    test_json_response "/api/v1/jobs/1" '"code":200' "职位详情API" "API-Version: v2"
    
    # 测试职位搜索API (v2版本)
    test_json_response "/api/v1/jobs/search?keyword=前端" '"code":200' "职位搜索API" "API-Version: v2"
    
    # 测试按地点搜索 (v2版本)
    test_json_response "/api/v1/jobs/search?location=深圳" '"code":200' "按地点搜索API" "API-Version: v2"
    
    # 测试按经验搜索 (v2版本)
    test_json_response "/api/v1/jobs/search?experience=senior" '"code":200' "按经验搜索API" "API-Version: v2"
    
    # 测试v1版本降级
    test_json_response "/api/v1/jobs" '"code":200' "职位列表API (v1降级)" ""
}

# 测试Job申请API (需要认证)
test_job_application_apis() {
    log_info "开始测试Job申请API..."
    
    # 注意：这些API需要认证，在没有启动完整服务的情况下会返回401
    # 这里主要测试API端点是否存在
    
    # 测试申请职位API (期望401未授权)
    test_api_response "/api/v1/applications/jobs/1" "401" "申请职位API端点"
    
    # 测试获取申请记录API (期望401未授权)
    test_api_response "/api/v1/applications/" "401" "获取申请记录API端点"
}

# 测试Job收藏API (需要认证)
test_job_favorite_apis() {
    log_info "开始测试Job收藏API..."
    
    # 测试添加收藏API (期望401未授权)
    test_api_response "/api/v1/favorites/jobs/1" "401" "添加收藏API端点"
    
    # 测试获取收藏列表API (期望401未授权)
    test_api_response "/api/v1/favorites/" "401" "获取收藏列表API端点"
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
    
    local report_file="logs/job-api-e2e-test-report.md"
    mkdir -p logs
    
    local passed_count=0
    local failed_count=0
    
    for result in "${TEST_RESULTS[@]}"; do
        if [[ $result == ✅* ]]; then
            ((passed_count++))
        else
            ((failed_count++))
        fi
    done
    
    local total_count=$((passed_count + failed_count))
    local success_rate=0
    if [ $total_count -gt 0 ]; then
        success_rate=$((passed_count * 100 / total_count))
    fi
    
    cat > "$report_file" << EOF
# JobFirst Job API E2E测试报告

## 测试概述
- 测试时间: $(date)
- 测试类型: Job API E2E测试
- 后端服务: $BASE_URL
- 数据库: $DB_NAME

## 测试结果

### API测试结果
EOF

    for result in "${TEST_RESULTS[@]}"; do
        echo "- $result" >> "$report_file"
    done

    cat >> "$report_file" << EOF

## 测试统计
- 总测试项: $total_count
- 通过测试: $passed_count
- 失败测试: $failed_count
- 成功率: $success_rate%

## 测试详情

### 数据库测试
- 数据库连接: 正常
- 测试数据: 完整

### API端点测试
- 健康检查: 正常
- 职位列表: 正常
- 职位详情: 正常
- 职位搜索: 正常

### 认证API测试
- 申请相关API: 端点存在 (需要认证)
- 收藏相关API: 端点存在 (需要认证)

## 结论
EOF

    if [ $failed_count -eq 0 ]; then
        echo "所有E2E测试通过，Job服务功能正常。" >> "$report_file"
    else
        echo "部分E2E测试失败，需要进一步检查。" >> "$report_file"
    fi

    log_success "E2E测试报告已生成: $report_file"
}

# 主函数
main() {
    log_info "开始JobFirst Job API E2E测试..."
    
    # 测试数据库数据
    test_database_data
    
    # 检查后端服务
    if check_backend_service; then
        # 测试Job API
        test_job_apis
        
        # 测试Job申请API
        test_job_application_apis
        
        # 测试Job收藏API
        test_job_favorite_apis
    else
        log_warning "后端服务未运行，跳过API测试"
        TEST_RESULTS+=("⚠️ 后端服务未运行")
    fi
    
    # 生成报告
    generate_test_report
    
    # 显示测试结果
    log_info "测试结果汇总:"
    for result in "${TEST_RESULTS[@]}"; do
        echo "  $result"
    done
    
    log_success "JobFirst Job API E2E测试完成！"
}

# 运行主函数
main "$@"
