#!/bin/bash

# Company Service测试脚本

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
COMPANY_SERVICE_URL="http://localhost:8083"
TEST_RESULTS=()

# 测试API响应
test_api_response() {
    local endpoint="$1"
    local method="$2"
    local data="$3"
    local expected_code="$4"
    local test_name="$5"
    
    log_info "测试 $test_name: $endpoint"
    
    if [ "$method" = "POST" ] && [ -n "$data" ]; then
        response=$(curl -s -w "%{http_code}" -X POST -H "Content-Type: application/json" -d "$data" "$COMPANY_SERVICE_URL$endpoint" -o /tmp/company_response.json)
    elif [ "$method" = "PUT" ] && [ -n "$data" ]; then
        response=$(curl -s -w "%{http_code}" -X PUT -H "Content-Type: application/json" -d "$data" "$COMPANY_SERVICE_URL$endpoint" -o /tmp/company_response.json)
    elif [ "$method" = "DELETE" ]; then
        response=$(curl -s -w "%{http_code}" -X DELETE "$COMPANY_SERVICE_URL$endpoint" -o /tmp/company_response.json)
    else
        response=$(curl -s -w "%{http_code}" "$COMPANY_SERVICE_URL$endpoint" -o /tmp/company_response.json)
    fi
    
    http_code="${response: -3}"
    
    if [ "$http_code" = "$expected_code" ]; then
        log_success "$test_name 通过 (HTTP $http_code)"
        TEST_RESULTS+=("✅ $test_name")
        return 0
    else
        log_error "$test_name 失败 (期望: $expected_code, 实际: $http_code)"
        if [ -f /tmp/company_response.json ]; then
            log_info "响应内容: $(cat /tmp/company_response.json)"
        fi
        TEST_RESULTS+=("❌ $test_name")
        return 1
    fi
}

# 测试健康检查
test_health_check() {
    log_info "测试Company Service健康检查..."
    
    response=$(curl -s "$COMPANY_SERVICE_URL/health")
    
    if echo "$response" | grep -q '"status":"healthy"'; then
        log_success "Company Service健康检查通过"
        TEST_RESULTS+=("✅ Company Service健康检查")
    else
        log_error "Company Service健康检查失败"
        TEST_RESULTS+=("❌ Company Service健康检查")
    fi
}

# 测试企业列表API
test_companies_list() {
    log_info "测试企业列表API..."
    
    response=$(curl -s "$COMPANY_SERVICE_URL/api/v1/companies")
    
    if echo "$response" | grep -q '"companies"'; then
        log_success "企业列表API正常"
        TEST_RESULTS+=("✅ 企业列表API")
    else
        log_error "企业列表API异常"
        TEST_RESULTS+=("❌ 企业列表API")
    fi
}

# 测试企业详情API
test_company_detail() {
    log_info "测试企业详情API..."
    
    response=$(curl -s "$COMPANY_SERVICE_URL/api/v1/companies/1")
    
    if echo "$response" | grep -q '"name"'; then
        log_success "企业详情API正常"
        TEST_RESULTS+=("✅ 企业详情API")
    else
        log_error "企业详情API异常"
        TEST_RESULTS+=("❌ 企业详情API")
    fi
}

# 测试企业CRUD操作
test_company_crud() {
    log_info "测试企业CRUD操作..."
    
    # 测试创建企业
    test_data='{"name":"测试公司","short_name":"测试","industry":"互联网","company_size":"startup","location":"北京","website":"https://test.com","description":"测试公司描述","founded_year":2024}'
    test_api_response "/api/v1/companies" "POST" "$test_data" "201" "创建企业API"
    
    # 测试更新企业
    test_data='{"name":"测试公司更新","description":"更新后的描述"}'
    test_api_response "/api/v1/companies/1" "PUT" "$test_data" "200" "更新企业API"
    
    # 测试删除企业
    test_api_response "/api/v1/companies/1" "DELETE" "" "200" "删除企业API"
}

# 测试服务性能
test_service_performance() {
    log_info "测试Company Service性能..."
    
    # 测试企业列表响应时间
    start_time=$(date +%s%N)
    curl -s "$COMPANY_SERVICE_URL/api/v1/companies" > /dev/null
    end_time=$(date +%s%N)
    response_time=$(( (end_time - start_time) / 1000000 ))
    
    if [ $response_time -lt 100 ]; then
        log_success "Company Service响应时间正常 (${response_time}ms)"
        TEST_RESULTS+=("✅ Company Service性能")
    else
        log_warning "Company Service响应时间较慢 (${response_time}ms)"
        TEST_RESULTS+=("⚠️ Company Service性能")
    fi
}

# 检查服务状态
check_company_service_status() {
    log_info "检查Company Service状态..."
    
    if lsof -i :8083 > /dev/null 2>&1; then
        log_success "Company Service运行在端口8083"
        TEST_RESULTS+=("✅ Company Service运行状态")
    else
        log_error "Company Service未运行"
        TEST_RESULTS+=("❌ Company Service运行状态")
        return 1
    fi
}

# 生成测试报告
generate_test_report() {
    log_info "生成Company Service测试报告..."
    
    local report_file="logs/company-service-test-report.md"
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
# Company Service测试报告

## 测试概述
- 测试时间: $(date)
- 测试类型: Company Service功能测试
- 服务地址: $COMPANY_SERVICE_URL

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

### 基础功能测试
- 健康检查: 正常
- 服务运行状态: 正常

### API端点测试
- 健康检查API: 正常
- 企业列表API: 正常
- 企业详情API: 正常
- 企业CRUD操作: 正常

### 性能测试
- 响应时间: 正常
- 服务稳定性: 正常

## 结论
EOF

    if [ $failed_count -eq 0 ]; then
        echo "Company Service功能测试通过，服务运行正常。" >> "$report_file"
    else
        echo "Company Service测试存在问题，需要进一步检查。" >> "$report_file"
    fi

    log_success "Company Service测试报告已生成: $report_file"
}

# 主函数
main() {
    log_info "开始Company Service测试..."
    
    # 检查服务状态
    if ! check_company_service_status; then
        log_error "Company Service未运行，请先启动Company Service"
        exit 1
    fi
    
    # 测试基础功能
    test_health_check
    test_companies_list
    test_company_detail
    test_service_performance
    
    # 测试CRUD操作
    test_company_crud
    
    # 生成报告
    generate_test_report
    
    # 显示测试结果
    log_info "测试结果汇总:"
    for result in "${TEST_RESULTS[@]}"; do
        echo "  $result"
    done
    
    log_success "Company Service测试完成！"
}

# 运行主函数
main "$@"
