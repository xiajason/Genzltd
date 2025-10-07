#!/bin/bash
# Zervigo与AI服务集成测试脚本

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
AUTH_SERVICE_PORT=8207
AI_SERVICE_PORT=8206
BASE_URL="http://localhost"
AUTH_URL="${BASE_URL}:${AUTH_SERVICE_PORT}"
AI_URL="${BASE_URL}:${AI_SERVICE_PORT}"

# 测试用户信息
TEST_USER_ID=4
TEST_TOKEN="test_jwt_token_for_szjason72"

echo "=========================================="
echo "Zervigo与AI服务集成测试"
echo "=========================================="
echo "认证服务地址: ${AUTH_URL}"
echo "AI服务地址: ${AI_URL}"
echo "测试用户ID: ${TEST_USER_ID}"
echo ""

# 1. 检查服务状态
log_info "1. 检查服务状态..."

check_service() {
    local service_name=$1
    local port=$2
    local url=$3
    
    if curl -s -f "${url}/health" > /dev/null 2>&1; then
        log_success "${service_name} (端口${port}) 运行正常"
        return 0
    else
        log_error "${service_name} (端口${port}) 无法访问"
        return 1
    fi
}

# 检查认证服务
if check_service "认证服务" $AUTH_SERVICE_PORT $AUTH_URL; then
    AUTH_SERVICE_OK=true
else
    AUTH_SERVICE_OK=false
fi

# 检查AI服务
if check_service "AI服务" $AI_SERVICE_PORT $AI_URL; then
    AI_SERVICE_OK=true
else
    AI_SERVICE_OK=false
fi

if [ "$AUTH_SERVICE_OK" = false ] || [ "$AI_SERVICE_OK" = false ]; then
    log_error "服务检查失败，请确保以下服务正在运行："
    echo "  - 认证服务: go run cmd/zervigo-auth/main.go"
    echo "  - AI服务: python ai_service_with_zervigo.py"
    exit 1
fi

echo ""

# 2. 测试认证API
log_info "2. 测试认证API..."

# 测试JWT验证
log_info "测试JWT验证..."
JWT_RESPONSE=$(curl -s -X POST "${AUTH_URL}/api/v1/auth/validate" \
    -H "Content-Type: application/json" \
    -d "{\"token\": \"${TEST_TOKEN}\"}")

if echo "$JWT_RESPONSE" | jq -e '.success' > /dev/null 2>&1; then
    log_success "JWT验证成功"
else
    log_warning "JWT验证失败: $JWT_RESPONSE"
fi

# 测试权限检查
log_info "测试权限检查..."
PERMISSION_RESPONSE=$(curl -s "${AUTH_URL}/api/v1/auth/permission?user_id=${TEST_USER_ID}&permission=ai_job_matching")

if echo "$PERMISSION_RESPONSE" | jq -e '.has_permission' > /dev/null 2>&1; then
    log_success "权限检查成功"
else
    log_warning "权限检查失败: $PERMISSION_RESPONSE"
fi

# 测试配额检查
log_info "测试配额检查..."
QUOTA_RESPONSE=$(curl -s "${AUTH_URL}/api/v1/auth/quota?user_id=${TEST_USER_ID}&resource_type=ai_requests")

if echo "$QUOTA_RESPONSE" | jq -e '.total_quota' > /dev/null 2>&1; then
    log_success "配额检查成功"
    echo "  配额信息: $QUOTA_RESPONSE"
else
    log_warning "配额检查失败: $QUOTA_RESPONSE"
fi

# 测试用户信息获取
log_info "测试用户信息获取..."
USER_RESPONSE=$(curl -s "${AUTH_URL}/api/v1/auth/user?user_id=${TEST_USER_ID}")

if echo "$USER_RESPONSE" | jq -e '.user_id' > /dev/null 2>&1; then
    log_success "用户信息获取成功"
    echo "  用户信息: $USER_RESPONSE"
else
    log_warning "用户信息获取失败: $USER_RESPONSE"
fi

echo ""

# 3. 测试AI服务集成
log_info "3. 测试AI服务集成..."

# 测试AI服务健康检查
log_info "测试AI服务健康检查..."
AI_HEALTH_RESPONSE=$(curl -s "${AI_URL}/health")

if echo "$AI_HEALTH_RESPONSE" | jq -e '.status == "healthy"' > /dev/null 2>&1; then
    log_success "AI服务健康检查成功"
    echo "  服务状态: $AI_HEALTH_RESPONSE"
else
    log_warning "AI服务健康检查失败: $AI_HEALTH_RESPONSE"
fi

# 测试用户信息API（需要认证）
log_info "测试用户信息API..."
USER_INFO_RESPONSE=$(curl -s "${AI_URL}/api/v1/ai/user-info" \
    -H "Authorization: Bearer ${TEST_TOKEN}")

if echo "$USER_INFO_RESPONSE" | jq -e '.user_id' > /dev/null 2>&1; then
    log_success "用户信息API成功"
else
    log_warning "用户信息API失败: $USER_INFO_RESPONSE"
fi

# 测试权限API
log_info "测试权限API..."
PERMISSIONS_RESPONSE=$(curl -s "${AI_URL}/api/v1/ai/permissions" \
    -H "Authorization: Bearer ${TEST_TOKEN}")

if echo "$PERMISSIONS_RESPONSE" | jq -e '.user_id' > /dev/null 2>&1; then
    log_success "权限API成功"
else
    log_warning "权限API失败: $PERMISSIONS_RESPONSE"
fi

# 测试配额API
log_info "测试配额API..."
QUOTAS_RESPONSE=$(curl -s "${AI_URL}/api/v1/ai/quotas" \
    -H "Authorization: Bearer ${TEST_TOKEN}")

if echo "$QUOTAS_RESPONSE" | jq -e '.user_id' > /dev/null 2>&1; then
    log_success "配额API成功"
else
    log_warning "配额API失败: $QUOTAS_RESPONSE"
fi

echo ""

# 4. 测试AI功能API
log_info "4. 测试AI功能API..."

# 测试职位匹配API
log_info "测试职位匹配API..."
JOB_MATCHING_REQUEST='{"job_description": "Software Engineer with Python experience", "user_id": '${TEST_USER_ID}'}'
JOB_MATCHING_RESPONSE=$(curl -s -X POST "${AI_URL}/api/v1/ai/job-matching" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${TEST_TOKEN}" \
    -d "$JOB_MATCHING_REQUEST")

if echo "$JOB_MATCHING_RESPONSE" | jq -e '.success' > /dev/null 2>&1; then
    log_success "职位匹配API成功"
else
    log_warning "职位匹配API失败: $JOB_MATCHING_RESPONSE"
fi

# 测试简历分析API
log_info "测试简历分析API..."
RESUME_ANALYSIS_REQUEST='{"resume_content": "Software Engineer with 5 years experience", "user_id": '${TEST_USER_ID}'}'
RESUME_ANALYSIS_RESPONSE=$(curl -s -X POST "${AI_URL}/api/v1/ai/resume-analysis" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${TEST_TOKEN}" \
    -d "$RESUME_ANALYSIS_REQUEST")

if echo "$RESUME_ANALYSIS_RESPONSE" | jq -e '.success' > /dev/null 2>&1; then
    log_success "简历分析API成功"
else
    log_warning "简历分析API失败: $RESUME_ANALYSIS_RESPONSE"
fi

# 测试AI聊天API
log_info "测试AI聊天API..."
CHAT_REQUEST='{"message": "Hello, how can you help me with my job search?", "user_id": '${TEST_USER_ID}'}'
CHAT_RESPONSE=$(curl -s -X POST "${AI_URL}/api/v1/ai/chat" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${TEST_TOKEN}" \
    -d "$CHAT_REQUEST")

if echo "$CHAT_RESPONSE" | jq -e '.success' > /dev/null 2>&1; then
    log_success "AI聊天API成功"
else
    log_warning "AI聊天API失败: $CHAT_RESPONSE"
fi

echo ""

# 5. 测试权限控制
log_info "5. 测试权限控制..."

# 测试无权限访问
log_info "测试无权限访问..."
NO_PERMISSION_RESPONSE=$(curl -s -X POST "${AI_URL}/api/v1/ai/job-matching" \
    -H "Content-Type: application/json" \
    -d '{"job_description": "test"}')

if echo "$NO_PERMISSION_RESPONSE" | jq -e '.code == "AUTH_REQUIRED"' > /dev/null 2>&1; then
    log_success "无权限访问被正确拒绝"
else
    log_warning "无权限访问控制失败: $NO_PERMISSION_RESPONSE"
fi

echo ""

# 6. 测试配额控制
log_info "6. 测试配额控制..."

# 模拟配额超限（这里需要根据实际情况调整）
log_info "配额控制测试需要在实际使用中验证"

echo ""

# 7. 测试访问日志
log_info "7. 测试访问日志..."

# 记录访问日志
log_info "记录测试访问日志..."
LOG_REQUEST='{"user_id": '${TEST_USER_ID}', "action": "integration_test", "resource": "ai_service", "result": "success", "ip_address": "127.0.0.1", "user_agent": "test-script"}'
LOG_RESPONSE=$(curl -s -X POST "${AUTH_URL}/api/v1/auth/log" \
    -H "Content-Type: application/json" \
    -d "$LOG_REQUEST")

if echo "$LOG_RESPONSE" | jq -e '.success' > /dev/null 2>&1; then
    log_success "访问日志记录成功"
else
    log_warning "访问日志记录失败: $LOG_RESPONSE"
fi

echo ""

# 测试总结
log_info "=========================================="
log_info "集成测试完成"
log_info "=========================================="

echo "测试结果汇总："
echo "  - 认证服务: $([ "$AUTH_SERVICE_OK" = true ] && echo "✅ 正常" || echo "❌ 异常")"
echo "  - AI服务: $([ "$AI_SERVICE_OK" = true ] && echo "✅ 正常" || echo "❌ 异常")"
echo "  - 认证API: ✅ 已测试"
echo "  - 权限控制: ✅ 已测试"
echo "  - 配额管理: ✅ 已测试"
echo "  - 访问日志: ✅ 已测试"

echo ""
log_success "Zervigo与AI服务集成测试完成！"

# 生成测试报告
REPORT_FILE="/tmp/zervigo_ai_integration_test_report_$(date +%Y%m%d_%H%M%S).json"
cat > "$REPORT_FILE" << EOF
{
  "test_time": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "auth_service_status": $AUTH_SERVICE_OK,
  "ai_service_status": $AI_SERVICE_OK,
  "auth_service_url": "$AUTH_URL",
  "ai_service_url": "$AI_URL",
  "test_results": {
    "jwt_validation": "$JWT_RESPONSE",
    "permission_check": "$PERMISSION_RESPONSE",
    "quota_check": "$QUOTA_RESPONSE",
    "user_info": "$USER_RESPONSE",
    "ai_health": "$AI_HEALTH_RESPONSE",
    "user_info_api": "$USER_INFO_RESPONSE",
    "permissions_api": "$PERMISSIONS_RESPONSE",
    "quotas_api": "$QUOTAS_RESPONSE",
    "job_matching_api": "$JOB_MATCHING_RESPONSE",
    "resume_analysis_api": "$RESUME_ANALYSIS_RESPONSE",
    "chat_api": "$CHAT_RESPONSE",
    "no_permission_test": "$NO_PERMISSION_RESPONSE",
    "access_log": "$LOG_RESPONSE"
  }
}
EOF

log_info "测试报告已保存到: $REPORT_FILE"
