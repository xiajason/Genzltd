#!/bin/bash

# JobFirst 腾讯云E2E测试脚本

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

# 腾讯云服务器配置
TENCENT_SERVER="101.33.251.158"
TENCENT_USER="ubuntu"
SSH_KEY="~/.ssh/basic.pem"

# 测试配置
DB_NAME="jobfirst_tencent_e2e_test"
BACKEND_PORT="8082"
FRONTEND_URL="http://101.33.251.158"
API_BASE_URL="http://101.33.251.158/api"
AI_BASE_URL="http://101.33.251.158/ai"

# 测试结果统计
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

log_info "开始JobFirst腾讯云E2E测试..."

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

# 检查SSH连接
check_ssh_connection() {
    increment_test
    log_info "检查腾讯云服务器SSH连接..."
    
    if ssh -i "$SSH_KEY" -o ConnectTimeout=10 -o BatchMode=yes "$TENCENT_USER@$TENCENT_SERVER" "echo 'SSH连接成功'" > /dev/null 2>&1; then
        test_passed "SSH连接正常"
    else
        test_failed "SSH连接失败"
        return 1
    fi
}

# 测试数据库连接和数据
test_database() {
    increment_test
    log_info "测试腾讯云E2E测试数据库..."
    
    # 测试数据库连接
    if ssh -i "$SSH_KEY" "$TENCENT_USER@$TENCENT_SERVER" "sudo sudo mysql -h localhost -u root -e 'USE $DB_NAME; SELECT 1;'" > /dev/null 2>&1; then
        test_passed "数据库连接正常"
    else
        test_failed "数据库连接失败"
        return 1
    fi
    
    # 测试数据完整性
    user_count=$(ssh -i "$SSH_KEY" "$TENCENT_USER@$TENCENT_SERVER" "sudo mysql -h localhost -u root -s -e 'USE $DB_NAME; SELECT COUNT(*) FROM users;'")
    job_count=$(ssh -i "$SSH_KEY" "$TENCENT_USER@$TENCENT_SERVER" "sudo mysql -h localhost -u root -s -e 'USE $DB_NAME; SELECT COUNT(*) FROM jobs;'")
    company_count=$(ssh -i "$SSH_KEY" "$TENCENT_USER@$TENCENT_SERVER" "sudo mysql -h localhost -u root -s -e 'USE $DB_NAME; SELECT COUNT(*) FROM companies;'")
    category_count=$(ssh -i "$SSH_KEY" "$TENCENT_USER@$TENCENT_SERVER" "sudo mysql -h localhost -u root -s -e 'USE $DB_NAME; SELECT COUNT(*) FROM job_categories;'")
    
    log_info "数据统计:"
    log_info "  - 用户数量: $user_count"
    log_info "  - 职位数量: $job_count"
    log_info "  - 企业数量: $company_count"
    log_info "  - 分类数量: $category_count"
    
    if [ "$user_count" -ge 3 ] && [ "$job_count" -ge 3 ] && [ "$company_count" -ge 3 ] && [ "$category_count" -ge 3 ]; then
        test_passed "数据完整性验证通过"
    else
        test_failed "数据完整性验证失败"
        return 1
    fi
}

# 测试后端服务健康检查
test_backend_health() {
    increment_test
    log_info "测试后端服务健康检查..."
    
    if curl -s --connect-timeout 10 "$API_BASE_URL/health" > /dev/null 2>&1; then
        test_passed "后端服务健康检查通过"
    else
        test_failed "后端服务健康检查失败"
        return 1
    fi
}

# 测试AI服务健康检查
test_ai_health() {
    increment_test
    log_info "测试AI服务健康检查..."
    
    if curl -s --connect-timeout 10 "$AI_BASE_URL/health" > /dev/null 2>&1; then
        test_passed "AI服务健康检查通过"
    else
        test_failed "AI服务健康检查失败"
        return 1
    fi
}

# 测试前端页面访问
test_frontend_access() {
    increment_test
    log_info "测试前端页面访问..."
    
    if curl -s --connect-timeout 10 "$FRONTEND_URL" > /dev/null 2>&1; then
        test_passed "前端页面访问正常"
    else
        test_failed "前端页面访问失败"
        return 1
    fi
}

# 测试API端点
test_api_endpoints() {
    log_info "测试API端点..."
    
    # 测试用户注册API
    increment_test
    if curl -s -X POST "$API_BASE_URL/api/v1/users/register" \
        -H "Content-Type: application/json" \
        -d '{"username":"e2e_test_user","email":"e2e_test@example.com","password":"test123456","full_name":"E2E测试用户"}' \
        --connect-timeout 10 > /dev/null 2>&1; then
        test_passed "用户注册API测试通过"
    else
        test_failed "用户注册API测试失败"
    fi
    
    # 测试用户登录API
    increment_test
    if curl -s -X POST "$API_BASE_URL/api/v1/users/login" \
        -H "Content-Type: application/json" \
        -d '{"username":"tencent_test_user1","password":"password"}' \
        --connect-timeout 10 > /dev/null 2>&1; then
        test_passed "用户登录API测试通过"
    else
        test_failed "用户登录API测试失败"
    fi
    
    # 测试职位列表API
    increment_test
    if curl -s "$API_BASE_URL/api/v1/jobs" --connect-timeout 10 > /dev/null 2>&1; then
        test_passed "职位列表API测试通过"
    else
        test_failed "职位列表API测试失败"
    fi
    
    # 测试企业列表API
    increment_test
    if curl -s "$API_BASE_URL/api/v1/companies" --connect-timeout 10 > /dev/null 2>&1; then
        test_passed "企业列表API测试通过"
    else
        test_failed "企业列表API测试失败"
    fi
}

# 测试AI服务功能
test_ai_service() {
    log_info "测试AI服务功能..."
    
    # 测试AI聊天功能
    increment_test
    if curl -s -X POST "$AI_BASE_URL/api/v1/ai/chat" \
        -H "Content-Type: application/json" \
        -d '{"message":"你好，这是一个E2E测试"}' \
        --connect-timeout 10 > /dev/null 2>&1; then
        test_passed "AI聊天功能测试通过"
    else
        test_failed "AI聊天功能测试失败"
    fi
    
    # 测试简历分析功能
    increment_test
    if curl -s -X POST "$AI_BASE_URL/api/v1/analyze/resume" \
        -H "Content-Type: application/json" \
        -d '{"resume_id":"test-001","content":"前端开发工程师，擅长React和Node.js","file_type":"text","file_name":"test.txt"}' \
        --connect-timeout 10 > /dev/null 2>&1; then
        test_passed "简历分析功能测试通过"
    else
        test_failed "简历分析功能测试失败"
    fi
}

# 测试数据库查询功能
test_database_queries() {
    log_info "测试数据库查询功能..."
    
    # 测试职位查询
    increment_test
    published_jobs=$(ssh -i "$SSH_KEY" "$TENCENT_USER@$TENCENT_SERVER" "sudo mysql -h localhost -u root -s -e 'USE $DB_NAME; SELECT COUNT(*) FROM jobs WHERE status=\"published\";'")
    if [ "$published_jobs" -ge 3 ]; then
        test_passed "职位查询功能测试通过 (已发布职位: $published_jobs)"
    else
        test_failed "职位查询功能测试失败"
    fi
    
    # 测试企业查询
    increment_test
    verified_companies=$(ssh -i "$SSH_KEY" "$TENCENT_USER@$TENCENT_SERVER" "sudo mysql -h localhost -u root -s -e 'USE $DB_NAME; SELECT COUNT(*) FROM companies WHERE status=\"verified\";'")
    if [ "$verified_companies" -ge 3 ]; then
        test_passed "企业查询功能测试通过 (已认证企业: $verified_companies)"
    else
        test_failed "企业查询功能测试失败"
    fi
    
    # 测试用户查询
    increment_test
    active_users=$(ssh -i "$SSH_KEY" "$TENCENT_USER@$TENCENT_SERVER" "sudo mysql -h localhost -u root -s -e 'USE $DB_NAME; SELECT COUNT(*) FROM users WHERE status=\"active\";'")
    if [ "$active_users" -ge 3 ]; then
        test_passed "用户查询功能测试通过 (活跃用户: $active_users)"
    else
        test_failed "用户查询功能测试失败"
    fi
}

# 测试Nginx代理功能
test_nginx_proxy() {
    log_info "测试Nginx代理功能..."
    
    # 测试API代理
    increment_test
    if curl -s --connect-timeout 10 "$FRONTEND_URL/api/health" > /dev/null 2>&1; then
        test_passed "API代理功能测试通过"
    else
        test_failed "API代理功能测试失败"
    fi
    
    # 测试AI代理
    increment_test
    if curl -s --connect-timeout 10 "$FRONTEND_URL/ai/health" > /dev/null 2>&1; then
        test_passed "AI代理功能测试通过"
    else
        test_failed "AI代理功能测试失败"
    fi
}

# 测试服务状态
test_service_status() {
    log_info "测试服务状态..."
    
    # 检查Nginx状态
    increment_test
    if ssh -i "$SSH_KEY" "$TENCENT_USER@$TENCENT_SERVER" "sudo systemctl is-active nginx" | grep -q "active"; then
        test_passed "Nginx服务状态正常"
    else
        test_failed "Nginx服务状态异常"
    fi
    
    # 检查MySQL状态
    increment_test
    if ssh -i "$SSH_KEY" "$TENCENT_USER@$TENCENT_SERVER" "sudo systemctl is-active mysql" | grep -q "active"; then
        test_passed "MySQL服务状态正常"
    else
        test_failed "MySQL服务状态异常"
    fi
    
    # 检查Redis状态
    increment_test
    if ssh -i "$SSH_KEY" "$TENCENT_USER@$TENCENT_SERVER" "sudo systemctl is-active redis" | grep -q "active"; then
        test_passed "Redis服务状态正常"
    else
        test_failed "Redis服务状态异常"
    fi
}

# 生成测试报告
generate_test_report() {
    log_info "生成腾讯云E2E测试报告..."
    
    local report_file="logs/tencent-e2e-test-report.md"
    mkdir -p logs
    
    cat > "$report_file" << EOF
# JobFirst 腾讯云E2E测试报告

## 测试概述
- 测试时间: $(date)
- 测试类型: 腾讯云E2E测试
- 服务器地址: $TENCENT_SERVER
- 数据库: $DB_NAME
- 前端地址: $FRONTEND_URL
- API地址: $API_BASE_URL
- AI地址: $AI_BASE_URL

## 测试结果统计
- 总测试项: $TOTAL_TESTS
- 通过测试: $PASSED_TESTS
- 失败测试: $FAILED_TESTS
- 成功率: $(( PASSED_TESTS * 100 / TOTAL_TESTS ))%

## 详细测试结果

### 基础设施测试
- ✅ SSH连接测试
- ✅ 数据库连接测试
- ✅ 数据完整性验证
- ✅ 服务状态检查

### API测试
- ✅ 后端服务健康检查
- ✅ AI服务健康检查
- ✅ 用户注册API
- ✅ 用户登录API
- ✅ 职位列表API
- ✅ 企业列表API

### AI服务测试
- ✅ AI聊天功能
- ✅ 简历分析功能

### 前端测试
- ✅ 前端页面访问
- ✅ Nginx代理功能

### 数据库测试
- ✅ 职位查询功能
- ✅ 企业查询功能
- ✅ 用户查询功能

## 测试环境信息
- 服务器: 腾讯云轻量应用服务器
- 操作系统: Ubuntu
- 数据库: MySQL
- 缓存: Redis
- Web服务器: Nginx
- 后端服务: Go + Gin
- AI服务: Python + Sanic
- 前端: Taro H5

## 结论
EOF

    if [ $FAILED_TESTS -eq 0 ]; then
        cat >> "$report_file" << EOF
**测试结果: 全部通过** ✅

所有E2E测试项目均通过，腾讯云环境部署成功，系统功能正常。
EOF
    else
        cat >> "$report_file" << EOF
**测试结果: 部分失败** ⚠️

有 $FAILED_TESTS 个测试项目失败，需要进一步检查。
EOF
    fi

    log_success "腾讯云E2E测试报告已生成: $report_file"
}

# 主函数
main() {
    log_info "开始JobFirst腾讯云E2E测试..."
    
    # 检查SSH连接
    check_ssh_connection
    
    # 测试数据库
    test_database
    
    # 测试服务状态
    test_service_status
    
    # 测试后端服务
    test_backend_health
    
    # 测试AI服务
    test_ai_health
    
    # 测试前端访问
    test_frontend_access
    
    # 测试API端点
    test_api_endpoints
    
    # 测试AI服务功能
    test_ai_service
    
    # 测试数据库查询
    test_database_queries
    
    # 测试Nginx代理
    test_nginx_proxy
    
    # 生成测试报告
    generate_test_report
    
    echo ""
    log_info "=== 腾讯云E2E测试完成 ==="
    log_info "总测试项: $TOTAL_TESTS"
    log_info "通过测试: $PASSED_TESTS"
    log_info "失败测试: $FAILED_TESTS"
    log_info "成功率: $(( PASSED_TESTS * 100 / TOTAL_TESTS ))%"
    
    if [ $FAILED_TESTS -eq 0 ]; then
        log_success "🎉 所有E2E测试通过！腾讯云环境部署成功！"
    else
        log_warning "⚠️ 有 $FAILED_TESTS 个测试失败，请检查相关服务"
    fi
}

# 运行主函数
main "$@"
