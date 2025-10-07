#!/bin/bash

# 增强的超级管理员设置脚本
# 基于优秀项目经验，提供完整的超级管理员初始化功能

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 项目配置
PROJECT_ROOT="/opt/jobfirst"
BACKEND_DIR="$PROJECT_ROOT/backend"
CONFIG_FILE="$BACKEND_DIR/configs/config.yaml"
LOG_FILE="$PROJECT_ROOT/logs/super-admin-setup.log"
SSH_DIR="$PROJECT_ROOT/.ssh"

# 日志函数
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}" | tee -a "$LOG_FILE"
    exit 1
}

info() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1${NC}" | tee -a "$LOG_FILE"
}

# 检查系统环境
check_environment() {
    log "检查系统环境..."
    
    # 检查是否为root用户
    if [[ $EUID -eq 0 ]]; then
        warn "建议不要使用root用户运行此脚本"
    fi
    
    # 检查必要工具
    local tools=("mysql" "curl" "jq" "openssl")
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            error "缺少必要工具: $tool"
        fi
    done
    
    # 检查项目目录
    if [[ ! -d "$PROJECT_ROOT" ]]; then
        error "项目目录不存在: $PROJECT_ROOT"
    fi
    
    # 检查配置文件
    if [[ ! -f "$CONFIG_FILE" ]]; then
        error "配置文件不存在: $CONFIG_FILE"
    fi
    
    log "系统环境检查完成"
}

# 检查数据库连接
check_database() {
    log "检查数据库连接..."
    
    # 从配置文件读取数据库信息
    local db_host=$(grep -A 10 "database:" "$CONFIG_FILE" | grep "host:" | awk '{print $2}' | tr -d '"')
    local db_port=$(grep -A 10 "database:" "$CONFIG_FILE" | grep "port:" | awk '{print $2}')
    local db_user=$(grep -A 10 "database:" "$CONFIG_FILE" | grep "username:" | awk '{print $2}' | tr -d '"')
    local db_name=$(grep -A 10 "database:" "$CONFIG_FILE" | grep "database:" | awk '{print $2}' | tr -d '"')
    
    # 测试数据库连接
    if ! mysql -h"$db_host" -P"$db_port" -u"$db_user" -p"$db_password" -e "SELECT 1;" &>/dev/null; then
        error "数据库连接失败"
    fi
    
    log "数据库连接正常"
}

# 检查超级管理员状态
check_super_admin_status() {
    log "检查超级管理员状态..."
    
    # 调用API检查状态
    local response=$(curl -s -X GET "http://localhost:8080/api/v1/super-admin/status" \
        -H "Content-Type: application/json" 2>/dev/null || echo "")
    
    if [[ -n "$response" ]]; then
        local exists=$(echo "$response" | jq -r '.exists // false' 2>/dev/null || echo "false")
        if [[ "$exists" == "true" ]]; then
            warn "超级管理员已存在"
            local username=$(echo "$response" | jq -r '.user.username // ""' 2>/dev/null || echo "")
            if [[ -n "$username" ]]; then
                info "当前超级管理员: $username"
            fi
            
            read -p "是否要重新初始化超级管理员? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                log "取消超级管理员初始化"
                exit 0
            fi
        fi
    fi
}

# 收集用户信息
collect_user_info() {
    log "收集超级管理员信息..."
    
    # 默认值
    DEFAULT_USERNAME="admin"
    DEFAULT_EMAIL="admin@jobfirst.com"
    DEFAULT_FIRST_NAME="Super"
    DEFAULT_LAST_NAME="Admin"
    
    # 获取用户名
    read -p "请输入用户名 [$DEFAULT_USERNAME]: " username
    username=${username:-$DEFAULT_USERNAME}
    
    # 验证用户名
    if [[ ! "$username" =~ ^[a-zA-Z0-9_]{3,20}$ ]]; then
        error "用户名只能包含字母、数字和下划线，长度3-20位"
    fi
    
    # 获取邮箱
    read -p "请输入邮箱 [$DEFAULT_EMAIL]: " email
    email=${email:-$DEFAULT_EMAIL}
    
    # 验证邮箱
    if [[ ! "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        error "邮箱格式不正确"
    fi
    
    # 获取姓名
    read -p "请输入名字 [$DEFAULT_FIRST_NAME]: " first_name
    first_name=${first_name:-$DEFAULT_FIRST_NAME}
    
    read -p "请输入姓氏 [$DEFAULT_LAST_NAME]: " last_name
    last_name=${last_name:-$DEFAULT_LAST_NAME}
    
    # 获取手机号
    read -p "请输入手机号 (可选): " phone
    
    # 获取密码
    while true; do
        read -s -p "请输入密码 (至少8位): " password
        echo
        if [[ ${#password} -ge 8 ]]; then
            break
        else
            warn "密码长度至少8位"
        fi
    done
    
    read -s -p "请确认密码: " password_confirm
    echo
    
    if [[ "$password" != "$password_confirm" ]]; then
        error "两次输入的密码不一致"
    fi
    
    # 生成安全密码（可选）
    read -p "是否生成安全密码? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        password=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-16)
        info "生成的安全密码: $password"
        echo "请妥善保管此密码！" | tee -a "$LOG_FILE"
    fi
    
    log "用户信息收集完成"
}

# 生成SSH密钥
generate_ssh_key() {
    log "生成SSH密钥..."
    
    # 创建SSH目录
    mkdir -p "$SSH_DIR"
    chmod 700 "$SSH_DIR"
    
    # 生成SSH密钥对
    if [[ ! -f "$SSH_DIR/id_rsa" ]]; then
        ssh-keygen -t rsa -b 4096 -f "$SSH_DIR/id_rsa" -N "" -C "$email"
        log "SSH密钥生成完成"
    else
        warn "SSH密钥已存在，跳过生成"
    fi
    
    # 设置权限
    chmod 600 "$SSH_DIR/id_rsa"
    chmod 644 "$SSH_DIR/id_rsa.pub"
    
    # 显示公钥
    info "SSH公钥:"
    cat "$SSH_DIR/id_rsa.pub"
    echo
}

# 初始化超级管理员
initialize_super_admin() {
    log "初始化超级管理员..."
    
    # 准备请求数据
    local request_data=$(cat <<EOF
{
    "username": "$username",
    "email": "$email",
    "password": "$password",
    "first_name": "$first_name",
    "last_name": "$last_name",
    "phone": "$phone"
}
EOF
)
    
    # 调用API初始化超级管理员
    local response=$(curl -s -X POST "http://localhost:8080/api/v1/super-admin/initialize" \
        -H "Content-Type: application/json" \
        -d "$request_data" 2>/dev/null || echo "")
    
    if [[ -z "$response" ]]; then
        error "API调用失败，请检查服务是否运行"
    fi
    
    # 检查响应
    local success=$(echo "$response" | jq -r '.success // false' 2>/dev/null || echo "false")
    if [[ "$success" != "true" ]]; then
        local error_msg=$(echo "$response" | jq -r '.error // "未知错误"' 2>/dev/null || echo "未知错误")
        error "超级管理员初始化失败: $error_msg"
    fi
    
    # 提取token
    local token=$(echo "$response" | jq -r '.data.token // ""' 2>/dev/null || echo "")
    if [[ -n "$token" ]]; then
        echo "$token" > "$PROJECT_ROOT/.super-admin-token"
        chmod 600 "$PROJECT_ROOT/.super-admin-token"
        log "访问令牌已保存到: $PROJECT_ROOT/.super-admin-token"
    fi
    
    log "超级管理员初始化成功"
}

# 验证初始化结果
verify_initialization() {
    log "验证初始化结果..."
    
    # 检查超级管理员状态
    local response=$(curl -s -X GET "http://localhost:8080/api/v1/super-admin/status" \
        -H "Content-Type: application/json" 2>/dev/null || echo "")
    
    if [[ -n "$response" ]]; then
        local exists=$(echo "$response" | jq -r '.exists // false' 2>/dev/null || echo "false")
        if [[ "$exists" == "true" ]]; then
            local user_info=$(echo "$response" | jq -r '.user // {}' 2>/dev/null || echo "{}")
            local role_count=$(echo "$response" | jq -r '.role_count // 0' 2>/dev/null || echo "0")
            local permission_count=$(echo "$response" | jq -r '.permission_count // 0' 2>/dev/null || echo "0")
            
            log "超级管理员验证成功"
            info "用户信息: $user_info"
            info "角色数量: $role_count"
            info "权限数量: $permission_count"
        else
            error "超级管理员验证失败"
        fi
    else
        error "无法验证超级管理员状态"
    fi
}

# 创建管理脚本
create_management_scripts() {
    log "创建管理脚本..."
    
    # 创建快速登录脚本
    cat > "$PROJECT_ROOT/scripts/quick-login.sh" <<EOF
#!/bin/bash
# 快速登录脚本

TOKEN_FILE="$PROJECT_ROOT/.super-admin-token"
if [[ -f "\$TOKEN_FILE" ]]; then
    TOKEN=\$(cat "\$TOKEN_FILE")
    echo "使用保存的令牌登录..."
    curl -X GET "http://localhost:8080/api/v1/protected/profile" \
        -H "Authorization: Bearer \$TOKEN" \
        -H "Content-Type: application/json"
else
    echo "未找到访问令牌，请重新初始化超级管理员"
fi
EOF
    
    chmod +x "$PROJECT_ROOT/scripts/quick-login.sh"
    
    # 创建团队成员管理脚本
    cat > "$PROJECT_ROOT/scripts/manage-team.sh" <<EOF
#!/bin/bash
# 团队成员管理脚本

TOKEN_FILE="$PROJECT_ROOT/.super-admin-token"
if [[ ! -f "\$TOKEN_FILE" ]]; then
    echo "未找到访问令牌，请先初始化超级管理员"
    exit 1
fi

TOKEN=\$(cat "\$TOKEN_FILE")

case "\$1" in
    "list")
        echo "获取团队成员列表..."
        curl -X GET "http://localhost:8080/api/v1/dev-team/admin/members" \
            -H "Authorization: Bearer \$TOKEN" \
            -H "Content-Type: application/json" | jq .
        ;;
    "add")
        if [[ \$# -lt 5 ]]; then
            echo "用法: \$0 add <username> <email> <role> <first_name> [last_name]"
            exit 1
        fi
        echo "添加团队成员..."
        curl -X POST "http://localhost:8080/api/v1/dev-team/admin/members" \
            -H "Authorization: Bearer \$TOKEN" \
            -H "Content-Type: application/json" \
            -d "{
                \"username\": \"\$2\",
                \"email\": \"\$3\",
                \"team_role\": \"\$4\",
                \"first_name\": \"\$5\",
                \"last_name\": \"\${6:-}\"
            }" | jq .
        ;;
    "stats")
        echo "获取团队统计信息..."
        curl -X GET "http://localhost:8080/api/v1/dev-team/admin/stats" \
            -H "Authorization: Bearer \$TOKEN" \
            -H "Content-Type: application/json" | jq .
        ;;
    *)
        echo "用法: \$0 {list|add|stats}"
        echo "  list - 列出团队成员"
        echo "  add - 添加团队成员"
        echo "  stats - 获取团队统计"
        ;;
esac
EOF
    
    chmod +x "$PROJECT_ROOT/scripts/manage-team.sh"
    
    log "管理脚本创建完成"
}

# 显示完成信息
show_completion_info() {
    log "超级管理员设置完成！"
    echo
    echo "=========================================="
    echo "🎉 超级管理员初始化成功！"
    echo "=========================================="
    echo
    echo "📋 登录信息:"
    echo "   用户名: $username"
    echo "   邮箱: $email"
    echo "   密码: [已设置]"
    echo
    echo "🔑 访问令牌: $PROJECT_ROOT/.super-admin-token"
    echo
    echo "🌐 Web界面: http://localhost:8080/login"
    echo "📡 API文档: http://localhost:8080/api-docs"
    echo
    echo "🛠️  管理工具:"
    echo "   快速登录: $PROJECT_ROOT/scripts/quick-login.sh"
    echo "   团队管理: $PROJECT_ROOT/scripts/manage-team.sh"
    echo
    echo "📁 SSH密钥: $SSH_DIR/id_rsa.pub"
    echo
    echo "📝 日志文件: $LOG_FILE"
    echo
    echo "⚠️  请妥善保管以上信息！"
    echo "=========================================="
}

# 主函数
main() {
    echo "=========================================="
    echo "🚀 JobFirst 超级管理员设置工具"
    echo "=========================================="
    echo
    
    # 创建日志目录
    mkdir -p "$(dirname "$LOG_FILE")"
    
    # 执行初始化步骤
    check_environment
    check_database
    check_super_admin_status
    collect_user_info
    generate_ssh_key
    initialize_super_admin
    verify_initialization
    create_management_scripts
    show_completion_info
    
    log "超级管理员设置完成"
}

# 错误处理
trap 'error "脚本执行失败，请检查日志: $LOG_FILE"' ERR

# 执行主函数
main "$@"
