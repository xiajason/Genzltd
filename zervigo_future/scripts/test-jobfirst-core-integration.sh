#!/bin/bash

# JobFirst Core 集成测试脚本
# 测试jobfirst-core与各个微服务的集成效果

echo "=========================================="
echo "JobFirst Core 集成测试"
echo "=========================================="
echo "测试时间: $(date)"
echo

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 测试结果统计
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# 测试函数
test_endpoint() {
    local name="$1"
    local url="$2"
    local expected_status="$3"
    local description="$4"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    echo -e "${BLUE}测试 $TOTAL_TESTS: $name${NC}"
    echo "URL: $url"
    echo "描述: $description"
    
    # 发送请求并获取状态码
    status_code=$(curl -s -o /dev/null -w "%{http_code}" "$url")
    
    if [ "$status_code" = "$expected_status" ]; then
        echo -e "${GREEN}✓ 通过 (状态码: $status_code)${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "${RED}✗ 失败 (期望: $expected_status, 实际: $status_code)${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    echo
}

# 测试JSON响应
test_json_endpoint() {
    local name="$1"
    local url="$2"
    local expected_status="$3"
    local description="$4"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    echo -e "${BLUE}测试 $TOTAL_TESTS: $name${NC}"
    echo "URL: $url"
    echo "描述: $description"
    
    # 发送请求并检查响应
    response=$(curl -s "$url")
    status_code=$(curl -s -o /dev/null -w "%{http_code}" "$url")
    
    if [ "$status_code" = "$expected_status" ]; then
        # 检查是否为有效JSON
        if echo "$response" | jq . > /dev/null 2>&1; then
            echo -e "${GREEN}✓ 通过 (状态码: $status_code, 有效JSON)${NC}"
            PASSED_TESTS=$((PASSED_TESTS + 1))
        else
            echo -e "${RED}✗ 失败 (状态码正确但JSON无效)${NC}"
            FAILED_TESTS=$((FAILED_TESTS + 1))
        fi
    else
        echo -e "${RED}✗ 失败 (期望: $expected_status, 实际: $status_code)${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    echo
}

echo "=========================================="
echo "1. 基础服务健康检查"
echo "=========================================="

# 检查服务是否运行
echo "检查服务运行状态..."
services=("8081:User Service" "8088:Dev Team Service" "8082:Resume Service" "8083:Company Service" "8084:Notification Service" "8085:Template Service" "8086:Statistics Service" "8087:Banner Service")

for service in "${services[@]}"; do
    port=$(echo $service | cut -d: -f1)
    name=$(echo $service | cut -d: -f2)
    
    if lsof -i :$port > /dev/null 2>&1; then
        echo -e "${GREEN}✓ $name (端口 $port) 正在运行${NC}"
    else
        echo -e "${RED}✗ $name (端口 $port) 未运行${NC}"
    fi
done
echo

echo "=========================================="
echo "2. User Service 集成测试"
echo "=========================================="

# User Service 健康检查
test_json_endpoint "User Service 健康检查" "http://localhost:8081/health" "200" "检查User Service是否正常运行"

# User Service API测试
test_json_endpoint "用户列表API" "http://localhost:8081/api/v1/users/" "200" "测试用户列表获取功能"
test_json_endpoint "角色列表API" "http://localhost:8081/api/v1/roles/" "200" "测试角色列表获取功能"
test_json_endpoint "权限列表API" "http://localhost:8081/api/v1/permissions/" "200" "测试权限列表获取功能"
test_json_endpoint "简历权限API" "http://localhost:8081/api/v1/resume-permissions/1" "200" "测试简历权限获取功能"
test_json_endpoint "利益相关方API" "http://localhost:8081/api/v1/stakeholders/" "200" "测试利益相关方获取功能"
test_json_endpoint "评论API" "http://localhost:8081/api/v1/comments/resume/1" "200" "测试评论获取功能"
test_json_endpoint "分享API" "http://localhost:8081/api/v1/shares/resume/1" "200" "测试分享获取功能"
test_json_endpoint "积分API" "http://localhost:8081/api/v1/points/user/1" "200" "测试积分获取功能"

echo "=========================================="
echo "3. Dev Team Service 集成测试"
echo "=========================================="

# Dev Team Service 健康检查
test_json_endpoint "Dev Team Service 健康检查" "http://localhost:8088/health" "200" "检查Dev Team Service是否正常运行"

# Dev Team Service API测试
test_json_endpoint "角色列表API" "http://localhost:8088/api/v1/dev-team/public/roles" "200" "测试开发团队角色列表获取功能"
test_json_endpoint "成员身份检查API" "http://localhost:8088/api/v1/dev-team/public/check-membership/1" "200" "测试成员身份检查功能"

# 需要认证的API测试（这些应该返回401，因为没有提供认证token）
test_endpoint "团队成员列表API (无认证)" "http://localhost:8088/api/v1/dev-team/admin/members" "401" "测试认证中间件是否正常工作"
test_endpoint "操作日志API (无认证)" "http://localhost:8088/api/v1/dev-team/admin/logs" "401" "测试认证中间件是否正常工作"
test_endpoint "团队统计API (无认证)" "http://localhost:8088/api/v1/dev-team/admin/stats" "401" "测试认证中间件是否正常工作"

echo "=========================================="
echo "4. 其他微服务健康检查"
echo "=========================================="

# 其他微服务健康检查
test_json_endpoint "Resume Service 健康检查" "http://localhost:8082/health" "200" "检查Resume Service是否正常运行"
test_json_endpoint "Company Service 健康检查" "http://localhost:8083/health" "200" "检查Company Service是否正常运行"
test_json_endpoint "Notification Service 健康检查" "http://localhost:8084/health" "200" "检查Notification Service是否正常运行"
test_json_endpoint "Template Service 健康检查" "http://localhost:8085/health" "200" "检查Template Service是否正常运行"
test_json_endpoint "Statistics Service 健康检查" "http://localhost:8086/health" "200" "检查Statistics Service是否正常运行"
test_json_endpoint "Banner Service 健康检查" "http://localhost:8087/health" "200" "检查Banner Service是否正常运行"

echo "=========================================="
echo "5. 数据库连接测试"
echo "=========================================="

# 测试数据库连接（通过API响应判断）
echo "测试数据库连接状态..."

# 通过User Service的API响应判断数据库连接
user_response=$(curl -s "http://localhost:8081/api/v1/users/")
if echo "$user_response" | jq -e '.data.users' > /dev/null 2>&1; then
    echo -e "${GREEN}✓ 数据库连接正常 (通过User Service API验证)${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    echo -e "${RED}✗ 数据库连接异常${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))
echo

echo "=========================================="
echo "6. 认证中间件测试"
echo "=========================================="

# 测试认证中间件
echo "测试认证中间件功能..."

# 测试需要认证的端点
protected_endpoints=(
    "http://localhost:8081/api/v1/users/profile:401"
    "http://localhost:8088/api/v1/dev-team/dev/profile:401"
)

for endpoint in "${protected_endpoints[@]}"; do
    url=$(echo $endpoint | cut -d: -f1-3)
    expected_status=$(echo $endpoint | cut -d: -f4)
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    echo -e "${BLUE}测试认证中间件: $url${NC}"
    status_code=$(curl -s -o /dev/null -w "%{http_code}" "$url")
    
    if [ "$status_code" = "$expected_status" ]; then
        echo -e "${GREEN}✓ 认证中间件正常工作 (状态码: $status_code)${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "${RED}✗ 认证中间件异常 (期望: $expected_status, 实际: $status_code)${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
done
echo

echo "=========================================="
echo "7. 性能测试"
echo "=========================================="

# 简单的性能测试
echo "进行简单的性能测试..."

# 测试User Service响应时间
start_time=$(date +%s%N)
curl -s "http://localhost:8081/health" > /dev/null
end_time=$(date +%s%N)
response_time=$(( (end_time - start_time) / 1000000 ))

echo "User Service 响应时间: ${response_time}ms"

if [ $response_time -lt 100 ]; then
    echo -e "${GREEN}✓ 响应时间良好 (< 100ms)${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
elif [ $response_time -lt 500 ]; then
    echo -e "${YELLOW}⚠ 响应时间一般 (< 500ms)${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    echo -e "${RED}✗ 响应时间较慢 (> 500ms)${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))
echo

echo "=========================================="
echo "测试结果汇总"
echo "=========================================="

echo "总测试数: $TOTAL_TESTS"
echo -e "通过测试: ${GREEN}$PASSED_TESTS${NC}"
echo -e "失败测试: ${RED}$FAILED_TESTS${NC}"

# 计算成功率
if [ $TOTAL_TESTS -gt 0 ]; then
    success_rate=$(( (PASSED_TESTS * 100) / TOTAL_TESTS ))
    echo "成功率: $success_rate%"
    
    if [ $success_rate -ge 90 ]; then
        echo -e "${GREEN}🎉 集成测试结果优秀！${NC}"
    elif [ $success_rate -ge 80 ]; then
        echo -e "${YELLOW}👍 集成测试结果良好${NC}"
    elif [ $success_rate -ge 70 ]; then
        echo -e "${YELLOW}⚠️ 集成测试结果一般，需要改进${NC}"
    else
        echo -e "${RED}❌ 集成测试结果较差，需要修复${NC}"
    fi
fi

echo
echo "=========================================="
echo "JobFirst Core 集成测试完成"
echo "测试时间: $(date)"
echo "=========================================="
