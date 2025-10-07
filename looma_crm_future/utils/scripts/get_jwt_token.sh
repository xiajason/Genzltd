#!/bin/bash

# JWT Token获取脚本
# 用于Looma CRM与Zervigo集成测试

set -e

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置 - Future版本Zervigo认证服务在7530端口
AUTH_URL="http://localhost:7530"
DEFAULT_USERNAME="admin"
DEFAULT_PASSWORD="password"

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

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# 显示帮助信息
show_help() {
    echo "JWT Token获取脚本"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -u, --username USERNAME    指定用户名 (默认: admin)"
    echo "  -p, --password PASSWORD    指定密码 (默认: password)"
    echo "  -h, --help                显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0                                    # 使用默认admin用户"
    echo "  $0 -u szjason72 -p @SZxym2006        # 使用szjason72用户"
    echo "  $0 -u testuser -p testuser123        # 使用testuser用户"
    echo ""
    echo "可用测试用户:"
    echo "  admin/password          - super_admin角色，所有权限"
    echo "  szjason72/@SZxym2006    - guest角色，read:public权限"
    echo "  testuser/testuser123    - guest角色，read:public权限"
    echo "  testuser2/testuser123   - system_admin角色"
}

# 检查依赖
check_dependencies() {
    if ! command -v curl &> /dev/null; then
        log_error "curl 命令未找到，请安装 curl"
        exit 1
    fi
    
    if ! command -v jq &> /dev/null; then
        log_error "jq 命令未找到，请安装 jq"
        exit 1
    fi
}

# 检查认证服务状态
check_auth_service() {
    log_info "检查统一认证服务状态..."
    
    if curl -s -f "$AUTH_URL/health" > /dev/null 2>&1; then
        log_success "统一认证服务运行正常"
        return 0
    else
        log_error "统一认证服务无法访问: $AUTH_URL"
        log_info "请确保Zervigo服务已启动:"
        log_info "  cd /Users/szjason72/zervi-basic/basic"
        log_info "  ./scripts/maintenance/smart-startup-enhanced.sh"
        return 1
    fi
}

# 获取JWT token
get_jwt_token() {
    local username="$1"
    local password="$2"
    
    log_info "正在获取JWT token..."
    log_info "用户名: $username"
    
    local response=$(curl -s -X POST "$AUTH_URL/api/v1/auth/login" \
        -H "Content-Type: application/json" \
        -d "{\"username\":\"$username\",\"password\":\"$password\"}")
    
    if echo "$response" | jq -e '.success' > /dev/null 2>&1; then
        local token=$(echo "$response" | jq -r '.token')
        local user_info=$(echo "$response" | jq -r '.user')
        local permissions=$(echo "$response" | jq -r '.permissions')
        
        log_success "Token获取成功！"
        echo ""
        echo "=== Token信息 ==="
        echo "Token: $token"
        echo ""
        echo "=== 用户信息 ==="
        echo "$user_info" | jq .
        echo ""
        echo "=== 权限信息 ==="
        echo "$permissions" | jq .
        echo ""
        
        # 保存token到文件
        echo "$token" > /tmp/jwt_token.txt
        log_info "Token已保存到: /tmp/jwt_token.txt"
        
        return 0
    else
        local error_msg=$(echo "$response" | jq -r '.error // .message // "未知错误"')
        log_error "Token获取失败: $error_msg"
        echo ""
        echo "=== 错误响应 ==="
        echo "$response" | jq .
        return 1
    fi
}

# 验证token
validate_token() {
    local token="$1"
    
    log_info "验证token有效性..."
    
    local response=$(curl -s -X POST "$AUTH_URL/api/v1/auth/validate" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $token" \
        -d "{\"token\":\"$token\"}")
    
    if echo "$response" | jq -e '.success' > /dev/null 2>&1; then
        log_success "Token验证成功！"
        echo ""
        echo "=== 验证结果 ==="
        echo "$response" | jq .
        return 0
    else
        local error_msg=$(echo "$response" | jq -r '.error // .message // "未知错误"')
        log_error "Token验证失败: $error_msg"
        return 1
    fi
}

# 显示使用示例
show_usage_examples() {
    local token="$1"
    
    echo ""
    echo "=== 使用示例 ==="
    echo ""
    echo "1. 测试Looma CRM健康检查:"
    echo "   curl http://localhost:8888/health"
    echo ""
    echo "2. 测试Zervigo集成健康检查:"
    echo "   curl http://localhost:8888/api/zervigo/health"
    echo ""
    echo "3. 测试认证保护的API:"
    echo "   curl -H \"Authorization: Bearer $token\" \\"
    echo "        http://localhost:8888/api/zervigo/talents/test123/sync"
    echo ""
    echo "4. 测试AI聊天API:"
    echo "   curl -X POST \\"
    echo "        -H \"Authorization: Bearer $token\" \\"
    echo "        -H \"Content-Type: application/json\" \\"
    echo "        -d '{\"message\": \"Tell me about this talent\"}' \\"
    echo "        http://localhost:8888/api/zervigo/talents/test123/chat"
    echo ""
    echo "5. 测试职位匹配API:"
    echo "   curl -H \"Authorization: Bearer $token\" \\"
    echo "        http://localhost:8888/api/zervigo/talents/test123/matches"
    echo ""
}

# 主函数
main() {
    local username="$DEFAULT_USERNAME"
    local password="$DEFAULT_PASSWORD"
    
    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -u|--username)
                username="$2"
                shift 2
                ;;
            -p|--password)
                password="$2"
                shift 2
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log_error "未知选项: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    echo "🚀 JWT Token获取脚本"
    echo "===================="
    echo ""
    
    # 检查依赖
    check_dependencies
    
    # 检查认证服务
    if ! check_auth_service; then
        exit 1
    fi
    
    # 获取token
    if get_jwt_token "$username" "$password"; then
        local token=$(cat /tmp/jwt_token.txt)
        
        # 验证token
        if validate_token "$token"; then
            # 显示使用示例
            show_usage_examples "$token"
            
            log_success "🎉 JWT Token获取和验证完成！"
            log_info "现在可以使用token进行Looma CRM集成测试了"
        else
            log_error "Token验证失败，请检查token有效性"
            exit 1
        fi
    else
        log_error "Token获取失败，请检查用户名和密码"
        exit 1
    fi
}

# 执行主函数
main "$@"
