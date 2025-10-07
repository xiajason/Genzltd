#!/bin/bash

# 所有服务综合测试脚本

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

# 服务配置
SERVICES=(
    "API Gateway:8080"
    "AI Service:8206"
    "User Service:8081"
    "Resume Service:8082"
    "Company Service:8083"
    "Notification Service:8084"
    "Banner Service:8085"
    "Statistics Service:8086"
)

TEST_RESULTS=()

# 测试服务健康检查
test_service_health() {
    local service_name="$1"
    local port="$2"
    
    log_info "测试 $service_name 健康检查..."
    
    if curl -s "http://localhost:$port/health" > /dev/null; then
        log_success "$service_name 健康检查通过"
        TEST_RESULTS+=("✅ $service_name 健康检查")
        return 0
    else
        log_error "$service_name 健康检查失败"
        TEST_RESULTS+=("❌ $service_name 健康检查")
        return 1
    fi
}

# 测试服务API
test_service_api() {
    local service_name="$1"
    local port="$2"
    
    case $service_name in
        "API Gateway")
            test_api_gateway "$port"
            ;;
        "AI Service")
            test_ai_service "$port"
            ;;
        "User Service")
            test_user_service "$port"
            ;;
        "Resume Service")
            test_resume_service "$port"
            ;;
        "Company Service")
            test_company_service "$port"
            ;;
        "Notification Service")
            test_notification_service "$port"
            ;;
        "Banner Service")
            test_banner_service "$port"
            ;;
        "Statistics Service")
            test_statistics_service "$port"
            ;;
    esac
}

# 测试API Gateway
test_api_gateway() {
    local port="$1"
    log_info "测试API Gateway功能..."
    
    if curl -s "http://localhost:$port/health" | grep -q "healthy"; then
        log_success "API Gateway功能正常"
        TEST_RESULTS+=("✅ API Gateway功能")
    else
        log_error "API Gateway功能异常"
        TEST_RESULTS+=("❌ API Gateway功能")
    fi
}

# 测试AI Service
test_ai_service() {
    local port="$1"
    log_info "测试AI Service功能..."
    
    if curl -s "http://localhost:$port/api/v1/ai/features" | grep -q "features"; then
        log_success "AI Service功能正常"
        TEST_RESULTS+=("✅ AI Service功能")
    else
        log_error "AI Service功能异常"
        TEST_RESULTS+=("❌ AI Service功能")
    fi
}

# 测试User Service
test_user_service() {
    local port="$1"
    log_info "测试User Service功能..."
    
    if curl -s "http://localhost:$port/health" | grep -q "healthy"; then
        log_success "User Service功能正常"
        TEST_RESULTS+=("✅ User Service功能")
    else
        log_error "User Service功能异常"
        TEST_RESULTS+=("❌ User Service功能")
    fi
}

# 测试Resume Service
test_resume_service() {
    local port="$1"
    log_info "测试Resume Service功能..."
    
    if curl -s "http://localhost:$port/health" | grep -q "healthy"; then
        log_success "Resume Service功能正常"
        TEST_RESULTS+=("✅ Resume Service功能")
    else
        log_error "Resume Service功能异常"
        TEST_RESULTS+=("❌ Resume Service功能")
    fi
}

# 测试Company Service
test_company_service() {
    local port="$1"
    log_info "测试Company Service功能..."
    
    if curl -s "http://localhost:$port/api/v1/companies" | grep -q "companies"; then
        log_success "Company Service功能正常"
        TEST_RESULTS+=("✅ Company Service功能")
    else
        log_error "Company Service功能异常"
        TEST_RESULTS+=("❌ Company Service功能")
    fi
}

# 测试Notification Service
test_notification_service() {
    local port="$1"
    log_info "测试Notification Service功能..."
    
    if curl -s "http://localhost:$port/api/v1/notifications" | grep -q "notifications"; then
        log_success "Notification Service功能正常"
        TEST_RESULTS+=("✅ Notification Service功能")
    else
        log_error "Notification Service功能异常"
        TEST_RESULTS+=("❌ Notification Service功能")
    fi
}

# 测试Banner Service
test_banner_service() {
    local port="$1"
    log_info "测试Banner Service功能..."
    
    if curl -s "http://localhost:$port/api/v1/banners" | grep -q "banners"; then
        log_success "Banner Service功能正常"
        TEST_RESULTS+=("✅ Banner Service功能")
    else
        log_error "Banner Service功能异常"
        TEST_RESULTS+=("❌ Banner Service功能")
    fi
}

# 测试Statistics Service
test_statistics_service() {
    local port="$1"
    log_info "测试Statistics Service功能..."
    
    if curl -s "http://localhost:$port/api/v1/statistics" | grep -q "total_users"; then
        log_success "Statistics Service功能正常"
        TEST_RESULTS+=("✅ Statistics Service功能")
    else
        log_error "Statistics Service功能异常"
        TEST_RESULTS+=("❌ Statistics Service功能")
    fi
}

# 生成测试报告
generate_test_report() {
    log_info "生成综合测试报告..."
    
    local report_file="logs/all-services-test-report.md"
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
# 所有服务综合测试报告

## 测试概述
- 测试时间: $(date)
- 测试类型: 微服务综合功能测试
- 测试范围: 8个微服务

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

## 服务状态

### 已测试服务
EOF

    for service in "${SERVICES[@]}"; do
        service_name=$(echo $service | cut -d: -f1)
        port=$(echo $service | cut -d: -f2)
        echo "- $service_name (端口: $port)" >> "$report_file"
    done

    cat >> "$report_file" << EOF

## 结论
EOF

    if [ $failed_count -eq 0 ]; then
        echo "所有微服务功能测试通过，系统运行正常。" >> "$report_file"
    else
        echo "部分微服务测试存在问题，需要进一步检查。" >> "$report_file"
    fi

    log_success "综合测试报告已生成: $report_file"
}

# 主函数
main() {
    log_info "开始所有服务综合测试..."
    
    # 测试每个服务
    for service in "${SERVICES[@]}"; do
        service_name=$(echo $service | cut -d: -f1)
        port=$(echo $service | cut -d: -f2)
        
        log_info "=== 测试 $service_name ==="
        
        # 测试健康检查
        test_service_health "$service_name" "$port"
        
        # 测试API功能
        test_service_api "$service_name" "$port"
        
        echo ""
    done
    
    # 生成报告
    generate_test_report
    
    # 显示测试结果
    log_info "测试结果汇总:"
    for result in "${TEST_RESULTS[@]}"; do
        echo "  $result"
    done
    
    log_success "所有服务综合测试完成！"
}

# 运行主函数
main "$@"
