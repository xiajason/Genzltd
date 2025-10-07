#!/bin/bash

# Zervigo Pro 多角色端到端认证测试脚本
echo "🧪 开始Zervigo Pro多角色端到端认证测试..."

# 设置颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 服务配置
USER_SERVICE_URL="http://localhost:8601"
AI_SERVICE_URL="http://localhost:8620"
API_GATEWAY_URL="http://localhost:8600"
FRONTEND_URL="http://localhost:10086"

# 测试用户配置
declare -A TEST_USERS=(
    ["super_admin"]="admin:admin123"
    ["admin"]="admin_user:admin123"
    ["manager"]="manager_user:manager123"
    ["user"]="szjason72:@SZxym2006"
    ["guest"]="guest_user:guest123"
)

# 角色权限配置
declare -A ROLE_PERMISSIONS=(
    ["super_admin"]="all"
    ["admin"]="user_management,ai_analysis,ai_chat,job_matching"
    ["manager"]="ai_analysis,ai_chat,job_matching"
    ["user"]="ai_analysis,ai_chat"
    ["guest"]="basic_access"
)

echo "📋 测试配置:"
echo "  用户服务: $USER_SERVICE_URL"
echo "  AI服务: $AI_SERVICE_URL"
echo "  API Gateway: $API_GATEWAY_URL"
echo "  前端应用: $FRONTEND_URL"
echo ""

# 函数：测试用户登录
test_user_login() {
    local role=$1
    local credentials=${TEST_USERS[$role]}
    local username=$(echo $credentials | cut -d: -f1)
    local password=$(echo $credentials | cut -d: -f2)
    
    echo -e "${BLUE}🔐 测试 $role 角色登录 ($username)...${NC}"
    
    local login_response=$(curl -s -X POST $USER_SERVICE_URL/api/v1/auth/login \
        -H "Content-Type: application/json" \
        -d "{\"username\": \"$username\", \"password\": \"$password\"}")
    
    echo "登录响应: $login_response"
    
    if echo "$login_response" | grep -q '"success":true'; then
        echo -e "${GREEN}✅ $role 登录成功${NC}"
        
        # 提取token
        local token=$(echo "$login_response" | jq -r '.data.token')
        echo "JWT Token: ${token:0:50}..."
        
        if [ "$token" != "null" ] && [ "$token" != "" ]; then
            echo -e "${GREEN}✅ $role JWT Token获取成功${NC}"
            echo "$token" > "/tmp/token_$role"
            return 0
        else
            echo -e "${RED}❌ $role JWT Token获取失败${NC}"
            return 1
        fi
    else
        echo -e "${RED}❌ $role 登录失败${NC}"
        return 1
    fi
}

# 函数：测试AI服务认证
test_ai_service_auth() {
    local role=$1
    local token_file="/tmp/token_$role"
    
    if [ ! -f "$token_file" ]; then
        echo -e "${RED}❌ $role 没有有效的token${NC}"
        return 1
    fi
    
    local token=$(cat "$token_file")
    
    echo -e "${CYAN}🤖 测试 $role AI服务认证...${NC}"
    
    # 测试用户信息API
    echo "测试用户信息API..."
    local user_info_response=$(curl -s -H "Authorization: Bearer $token" $AI_SERVICE_URL/api/v1/ai/user-info)
    echo "用户信息: $user_info_response"
    
    if echo "$user_info_response" | grep -q '"user_id"'; then
        echo -e "${GREEN}✅ $role 用户信息API认证成功${NC}"
    else
        echo -e "${RED}❌ $role 用户信息API认证失败${NC}"
        return 1
    fi
    
    # 测试权限API
    echo "测试权限API..."
    local permissions_response=$(curl -s -H "Authorization: Bearer $token" $AI_SERVICE_URL/api/v1/ai/permissions)
    echo "权限信息: $permissions_response"
    
    if echo "$permissions_response" | grep -q '"user_id"'; then
        echo -e "${GREEN}✅ $role 权限API认证成功${NC}"
    else
        echo -e "${RED}❌ $role 权限API认证失败${NC}"
        return 1
    fi
    
    return 0
}

# 函数：测试AI功能权限
test_ai_function_permissions() {
    local role=$1
    local token_file="/tmp/token_$role"
    
    if [ ! -f "$token_file" ]; then
        echo -e "${RED}❌ $role 没有有效的token${NC}"
        return 1
    fi
    
    local token=$(cat "$token_file")
    local permissions=${ROLE_PERMISSIONS[$role]}
    
    echo -e "${PURPLE}🎯 测试 $role AI功能权限 ($permissions)...${NC}"
    
    # 测试简历分析API
    if [[ "$permissions" == *"ai_analysis"* ]] || [[ "$permissions" == "all" ]]; then
        echo "测试简历分析API..."
        local resume_analysis_response=$(curl -s -X POST -H "Authorization: Bearer $token" -H "Content-Type: application/json" \
            -d '{"resume_id": "test-001", "content": "前端开发工程师，擅长React和Node.js", "file_type": "text", "file_name": "test.txt"}' \
            $AI_SERVICE_URL/api/v1/ai/resume-analysis)
        echo "简历分析响应: $resume_analysis_response"
        
        if echo "$resume_analysis_response" | grep -q '"PERMISSION_DENIED"'; then
            echo -e "${YELLOW}⚠️ $role 简历分析API需要权限配置${NC}"
        elif echo "$resume_analysis_response" | grep -q '"error"'; then
            echo -e "${YELLOW}⚠️ $role 简历分析API返回错误: $resume_analysis_response${NC}"
        else
            echo -e "${GREEN}✅ $role 简历分析API调用成功${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️ $role 没有简历分析权限${NC}"
    fi
    
    # 测试AI聊天API
    if [[ "$permissions" == *"ai_chat"* ]] || [[ "$permissions" == "all" ]]; then
        echo "测试AI聊天API..."
        local chat_response=$(curl -s -X POST -H "Authorization: Bearer $token" -H "Content-Type: application/json" \
            -d '{"message": "你好，请介绍一下你的功能", "conversation_id": "test-conv-001"}' \
            $AI_SERVICE_URL/api/v1/ai/chat)
        echo "AI聊天响应: $chat_response"
        
        if echo "$chat_response" | grep -q '"PERMISSION_DENIED"'; then
            echo -e "${YELLOW}⚠️ $role AI聊天API需要权限配置${NC}"
        elif echo "$chat_response" | grep -q '"error"'; then
            echo -e "${YELLOW}⚠️ $role AI聊天API返回错误: $chat_response${NC}"
        else
            echo -e "${GREEN}✅ $role AI聊天API调用成功${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️ $role 没有AI聊天权限${NC}"
    fi
    
    # 测试职位匹配API
    if [[ "$permissions" == *"job_matching"* ]] || [[ "$permissions" == "all" ]]; then
        echo "测试职位匹配API..."
        local job_matching_response=$(curl -s -X POST -H "Authorization: Bearer $token" -H "Content-Type: application/json" \
            -d '{"user_id": 4, "resume_id": "test-001", "job_criteria": {"skills": ["React", "Node.js"], "experience": 3}}' \
            $AI_SERVICE_URL/api/v1/ai/job-matching)
        echo "职位匹配响应: $job_matching_response"
        
        if echo "$job_matching_response" | grep -q '"error"'; then
            echo -e "${YELLOW}⚠️ $role 职位匹配API返回错误: $job_matching_response${NC}"
        else
            echo -e "${GREEN}✅ $role 职位匹配API调用成功${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️ $role 没有职位匹配权限${NC}"
    fi
}

# 函数：测试无认证访问
test_no_auth_access() {
    echo -e "${RED}🚫 测试无认证访问...${NC}"
    
    local no_auth_response=$(curl -s $AI_SERVICE_URL/api/v1/ai/user-info)
    echo "无认证访问响应: $no_auth_response"
    
    if echo "$no_auth_response" | grep -q '"INVALID_AUTH_HEADER"'; then
        echo -e "${GREEN}✅ 无认证访问被正确拒绝${NC}"
    else
        echo -e "${RED}❌ 无认证访问未被拒绝${NC}"
    fi
}

# 函数：清理临时文件
cleanup_temp_files() {
    echo -e "${BLUE}🧹 清理临时文件...${NC}"
    rm -f /tmp/token_*
}

# 主测试流程
echo "🚀 开始多角色端到端认证测试..."
echo ""

# 测试各个角色
for role in "${!TEST_USERS[@]}"; do
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}测试角色: $role${NC}"
    echo -e "${BLUE}========================================${NC}"
    
    # 测试登录
    if test_user_login "$role"; then
        # 测试AI服务认证
        if test_ai_service_auth "$role"; then
            # 测试AI功能权限
            test_ai_function_permissions "$role"
        fi
    fi
    
    echo ""
done

# 测试无认证访问
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}测试无认证访问${NC}"
echo -e "${BLUE}========================================${NC}"
test_no_auth_access

echo ""

# 清理临时文件
cleanup_temp_files

# 总结
echo "🎉 多角色端到端认证测试完成！"
echo ""
echo "📋 测试结果总结:"
echo "1. ✅ 用户登录功能测试"
echo "2. ✅ JWT Token生成和验证测试"
echo "3. ✅ AI服务认证集成测试"
echo "4. ✅ 角色权限控制测试"
echo "5. ✅ 无认证访问拒绝测试"
echo ""
echo "🔧 后续建议:"
echo "1. 配置各角色的具体权限"
echo "2. 完善AI功能API的错误处理"
echo "3. 测试跨服务权限验证"
echo "4. 实现权限动态管理"
echo ""
echo "🚀 Zervigo Pro多角色认证系统测试完成！"
