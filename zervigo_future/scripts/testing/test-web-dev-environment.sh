#!/bin/bash

# Web端开发环境测试脚本
# 测试所有服务和API接口

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
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

# 测试API接口
test_api() {
    local url=$1
    local expected_status=$2
    local description=$3
    
    log_info "测试: $description"
    
    response=$(curl -s -w "%{http_code}" -o /tmp/api_response.json "$url")
    http_code="${response: -3}"
    
    if [ "$http_code" = "$expected_status" ]; then
        log_success "$description - HTTP $http_code"
        if [ -f /tmp/api_response.json ]; then
            echo "响应: $(cat /tmp/api_response.json)"
        fi
        return 0
    else
        log_error "$description - HTTP $http_code (期望: $expected_status)"
        if [ -f /tmp/api_response.json ]; then
            echo "响应: $(cat /tmp/api_response.json)"
        fi
        return 1
    fi
}

# 测试用户登录
test_user_login() {
    log_info "测试用户登录..."
    
    response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -d '{"username":"admin","password":"password"}' \
        http://localhost:8080/api/v2/auth/login)
    
    if echo "$response" | grep -q "token"; then
        log_success "用户登录测试通过"
        echo "响应: $response"
        return 0
    else
        log_error "用户登录测试失败"
        echo "响应: $response"
        return 1
    fi
}

# 测试简历列表
test_resume_list() {
    log_info "测试简历列表..."
    
    response=$(curl -s -H "Authorization: Bearer test-token" \
        http://localhost:8080/api/v1/resume/list)
    
    if echo "$response" | grep -q "resumes\|data"; then
        log_success "简历列表测试通过"
        echo "响应: $response"
        return 0
    else
        log_warning "简历列表测试失败 (可能需要认证)"
        echo "响应: $response"
        return 1
    fi
}

# 测试AI聊天
test_ai_chat() {
    log_info "测试AI聊天..."
    
    response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -d '{"message":"你好"}' \
        http://localhost:8206/api/v1/chat/aiChat)
    
    if echo "$response" | grep -q "response\|message"; then
        log_success "AI聊天测试通过"
        echo "响应: $response"
        return 0
    else
        log_warning "AI聊天测试失败"
        echo "响应: $response"
        return 1
    fi
}

# 主测试函数
main() {
    log_info "开始Web端开发环境测试..."
    echo ""
    
    # 测试服务健康状态
    log_info "=== 测试服务健康状态 ==="
    test_api "http://localhost:8080/health" "200" "API Gateway健康检查"
    test_api "http://localhost:8081/health" "200" "User Service健康检查"
    test_api "http://localhost:8082/health" "200" "Resume Service健康检查"
    test_api "http://localhost:8083/health" "200" "Banner Service健康检查"
    test_api "http://localhost:8084/health" "200" "Template Service健康检查"
    test_api "http://localhost:8085/health" "200" "Notification Service健康检查"
    test_api "http://localhost:8086/health" "200" "Statistics Service健康检查"
    test_api "http://localhost:8206/health" "200" "AI Service健康检查"
    test_api "http://localhost:10086" "200" "前端服务检查"
    echo ""
    
    # 测试API接口
    log_info "=== 测试API接口 ==="
    test_user_login
    echo ""
    test_resume_list
    echo ""
    test_ai_chat
    echo ""
    
    # 测试数据库连接
    log_info "=== 测试数据库连接 ==="
    
    # 测试MySQL
    if mysql -u root -e "SELECT 1;" > /dev/null 2>&1; then
        log_success "MySQL连接正常"
    else
        log_error "MySQL连接失败"
    fi
    
    # 测试PostgreSQL
    if psql -U szjason72 -d jobfirst_vector -c "SELECT 1;" > /dev/null 2>&1; then
        log_success "PostgreSQL连接正常"
    else
        log_error "PostgreSQL连接失败"
    fi
    
    # 测试Redis
    if redis-cli ping > /dev/null 2>&1; then
        log_success "Redis连接正常"
    else
        log_error "Redis连接失败"
    fi
    echo ""
    
    # 总结
    log_info "=== 测试总结 ==="
    log_success "Web端开发环境测试完成！"
    echo ""
    log_info "访问地址:"
    echo "  🌐 前端应用: http://localhost:10086"
    echo "  🛠️ 开发工具: http://localhost:10086/pages/dev-tools/index"
    echo "  🔗 API Gateway: http://localhost:8080"
    echo "  🤖 AI Service: http://localhost:8206"
    echo "  📊 Neo4j Browser: http://localhost:7474"
    echo ""
    log_info "开发建议:"
    echo "  1. 使用开发工具页面进行功能测试"
    echo "  2. 修改代码会自动热加载"
    echo "  3. 查看浏览器控制台获取详细日志"
    echo "  4. 使用 ./scripts/web-dev-environment.sh status 查看服务状态"
}

# 运行测试
main "$@"
