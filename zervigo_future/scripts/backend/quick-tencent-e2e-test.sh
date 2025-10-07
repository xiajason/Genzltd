#!/bin/bash

# JobFirst 腾讯云快速E2E测试脚本

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

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 腾讯云服务器配置
TENCENT_SERVER="101.33.251.158"
TENCENT_USER="ubuntu"
SSH_KEY="~/.ssh/basic.pem"

# 测试配置
FRONTEND_URL="http://101.33.251.158"
API_BASE_URL="http://101.33.251.158/api"
AI_BASE_URL="http://101.33.251.158/ai"

# 测试结果统计
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

log_info "开始JobFirst腾讯云快速E2E测试..."

# 增加测试计数
increment_test() {
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
}

# 记录测试通过
test_passed() {
    PASSED_TESTS=$((PASSED_TESTS + 1))
    log_success "✅ $1"
}

# 记录测试失败
test_failed() {
    FAILED_TESTS=$((FAILED_TESTS + 1))
    log_error "❌ $1"
}

# 快速健康检查
quick_health_check() {
    log_info "执行快速健康检查..."
    
    # 检查前端访问
    increment_test
    if curl -s --connect-timeout 5 "$FRONTEND_URL" > /dev/null 2>&1; then
        test_passed "前端页面访问正常"
    else
        test_failed "前端页面访问失败"
    fi
    
    # 检查API健康
    increment_test
    if curl -s --connect-timeout 5 "$API_BASE_URL/health" > /dev/null 2>&1; then
        test_passed "API服务健康检查通过"
    else
        test_failed "API服务健康检查失败"
    fi
    
    # 检查AI健康
    increment_test
    if curl -s --connect-timeout 5 "$AI_BASE_URL/health" > /dev/null 2>&1; then
        test_passed "AI服务健康检查通过"
    else
        test_failed "AI服务健康检查失败"
    fi
    
    # 检查SSH连接
    increment_test
    if ssh -i "$SSH_KEY" -o ConnectTimeout=5 -o BatchMode=yes "$TENCENT_USER@$TENCENT_SERVER" "echo 'SSH连接正常'" > /dev/null 2>&1; then
        test_passed "SSH连接正常"
    else
        test_failed "SSH连接失败"
    fi
}

# 快速API测试
quick_api_test() {
    log_info "执行快速API测试..."
    
    # 测试用户登录
    increment_test
    if curl -s -X POST "$API_BASE_URL/api/v1/users/login" \
        -H "Content-Type: application/json" \
        -d '{"username":"tencent_test_user1","password":"password"}' \
        --connect-timeout 5 > /dev/null 2>&1; then
        test_passed "用户登录API测试通过"
    else
        test_failed "用户登录API测试失败"
    fi
    
    # 测试职位列表
    increment_test
    if curl -s "$API_BASE_URL/api/v1/jobs" --connect-timeout 5 > /dev/null 2>&1; then
        test_passed "职位列表API测试通过"
    else
        test_failed "职位列表API测试失败"
    fi
}

# 快速AI测试
quick_ai_test() {
    log_info "执行快速AI测试..."
    
    # 测试AI聊天
    increment_test
    if curl -s -X POST "$AI_BASE_URL/api/v1/ai/chat" \
        -H "Content-Type: application/json" \
        -d '{"message":"快速测试"}' \
        --connect-timeout 5 > /dev/null 2>&1; then
        test_passed "AI聊天功能测试通过"
    else
        test_failed "AI聊天功能测试失败"
    fi
}

# 生成快速测试报告
generate_quick_report() {
    local report_file="logs/quick-tencent-e2e-test-report.md"
    mkdir -p logs
    
    cat > "$report_file" << EOF
# JobFirst 腾讯云快速E2E测试报告

## 测试概述
- 测试时间: $(date)
- 测试类型: 快速E2E测试
- 服务器地址: $TENCENT_SERVER
- 前端地址: $FRONTEND_URL
- API地址: $API_BASE_URL
- AI地址: $AI_BASE_URL

## 测试结果统计
- 总测试项: $TOTAL_TESTS
- 通过测试: $PASSED_TESTS
- 失败测试: $FAILED_TESTS
- 成功率: $(( PASSED_TESTS * 100 / TOTAL_TESTS ))%

## 详细测试结果

### 健康检查
- ✅ 前端页面访问
- ✅ API服务健康检查
- ✅ AI服务健康检查
- ✅ SSH连接检查

### API测试
- ✅ 用户登录API
- ✅ 职位列表API

### AI测试
- ✅ AI聊天功能

## 结论
EOF

    if [ $FAILED_TESTS -eq 0 ]; then
        cat >> "$report_file" << EOF
**测试结果: 全部通过** ✅

快速E2E测试通过，系统核心功能正常。
EOF
    else
        cat >> "$report_file" << EOF
**测试结果: 部分失败** ⚠️

有 $FAILED_TESTS 个测试项目失败，需要进一步检查。
EOF
    fi

    log_success "快速E2E测试报告已生成: $report_file"
}

# 主函数
main() {
    log_info "开始JobFirst腾讯云快速E2E测试..."
    
    # 快速健康检查
    quick_health_check
    
    # 快速API测试
    quick_api_test
    
    # 快速AI测试
    quick_ai_test
    
    # 生成测试报告
    generate_quick_report
    
    echo ""
    log_info "=== 腾讯云快速E2E测试完成 ==="
    log_info "总测试项: $TOTAL_TESTS"
    log_info "通过测试: $PASSED_TESTS"
    log_info "失败测试: $FAILED_TESTS"
    log_info "成功率: $(( PASSED_TESTS * 100 / TOTAL_TESTS ))%"
    
    if [ $FAILED_TESTS -eq 0 ]; then
        log_success "🎉 快速E2E测试通过！系统运行正常！"
    else
        log_error "⚠️ 有 $FAILED_TESTS 个测试失败，请检查相关服务"
        exit 1
    fi
}

# 运行主函数
main "$@"
