#!/bin/bash

# 超级管理员初始化脚本
# 用于为项目负责人设置超级管理员权限
# 执行时间: 2025-09-06

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

# 检查是否以root权限运行
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "此脚本需要root权限运行"
        log_info "请使用: sudo $0"
        exit 1
    fi
}

# 检查MySQL服务状态
check_mysql() {
    log_info "检查MySQL服务状态..."
    if ! systemctl is-active --quiet mysql; then
        log_error "MySQL服务未运行，请先启动MySQL服务"
        log_info "启动命令: systemctl start mysql"
        exit 1
    fi
    log_success "MySQL服务运行正常"
}

# 获取数据库连接信息
get_db_config() {
    log_info "获取数据库配置信息..."
    
    # 从配置文件读取数据库信息
    if [ -f "/opt/jobfirst/backend/configs/config.yaml" ]; then
        DB_HOST=$(grep -A 10 "database:" /opt/jobfirst/backend/configs/config.yaml | grep "host:" | awk '{print $2}' | tr -d '"')
        DB_PORT=$(grep -A 10 "database:" /opt/jobfirst/backend/configs/config.yaml | grep "port:" | awk '{print $2}')
        DB_NAME=$(grep -A 10 "database:" /opt/jobfirst/backend/configs/config.yaml | grep "name:" | awk '{print $2}' | tr -d '"')
        DB_USER=$(grep -A 10 "database:" /opt/jobfirst/backend/configs/config.yaml | grep "username:" | awk '{print $2}' | tr -d '"')
    else
        # 默认配置
        DB_HOST="localhost"
        DB_PORT="3306"
        DB_NAME="jobfirst"
        DB_USER="root"
    fi
    
    log_info "数据库配置: $DB_USER@$DB_HOST:$DB_PORT/$DB_NAME"
}

# 获取MySQL root密码
get_mysql_password() {
    if [ -z "$MYSQL_ROOT_PASSWORD" ]; then
        echo -n "请输入MySQL root密码: "
        read -s MYSQL_ROOT_PASSWORD
        echo
    fi
}

# 测试数据库连接
test_db_connection() {
    log_info "测试数据库连接..."
    if ! mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$MYSQL_ROOT_PASSWORD" -e "SELECT 1;" >/dev/null 2>&1; then
        log_error "数据库连接失败，请检查密码和配置"
        exit 1
    fi
    log_success "数据库连接成功"
}

# 创建超级管理员用户
create_super_admin() {
    log_info "创建超级管理员用户..."
    
    # 获取用户信息
    echo -n "请输入您的用户名 (默认: admin): "
    read ADMIN_USERNAME
    ADMIN_USERNAME=${ADMIN_USERNAME:-admin}
    
    echo -n "请输入您的邮箱: "
    read ADMIN_EMAIL
    
    echo -n "请输入您的真实姓名: "
    read ADMIN_REAL_NAME
    
    echo -n "请输入您的密码: "
    read -s ADMIN_PASSWORD
    echo
    
    echo -n "请确认您的密码: "
    read -s ADMIN_PASSWORD_CONFIRM
    echo
    
    if [ "$ADMIN_PASSWORD" != "$ADMIN_PASSWORD_CONFIRM" ]; then
        log_error "密码不匹配，请重新运行脚本"
        exit 1
    fi
    
    # 生成UUID
    ADMIN_UUID=$(uuidgen)
    
    # 生成密码哈希
    ADMIN_PASSWORD_HASH=$(echo -n "$ADMIN_PASSWORD" | openssl dgst -sha256 | cut -d' ' -f2)
    
    # 检查用户是否已存在
    USER_EXISTS=$(mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$MYSQL_ROOT_PASSWORD" -D"$DB_NAME" -sN -e "SELECT COUNT(*) FROM users WHERE username='$ADMIN_USERNAME' OR email='$ADMIN_EMAIL';" 2>/dev/null || echo "0")
    
    if [ "$USER_EXISTS" -gt 0 ]; then
        log_warning "用户 $ADMIN_USERNAME 或邮箱 $ADMIN_EMAIL 已存在"
        echo -n "是否更新为超级管理员? (y/N): "
        read UPDATE_USER
        if [[ $UPDATE_USER =~ ^[Yy]$ ]]; then
            # 更新现有用户
            mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$MYSQL_ROOT_PASSWORD" -D"$DB_NAME" <<EOF
UPDATE users SET 
    password_hash = '$ADMIN_PASSWORD_HASH',
    first_name = '$ADMIN_REAL_NAME',
    status = 'active',
    email_verified = 1,
    updated_at = NOW()
WHERE username = '$ADMIN_USERNAME' OR email = '$ADMIN_EMAIL';

-- 获取用户ID
SET @user_id = (SELECT id FROM users WHERE username = '$ADMIN_USERNAME' OR email = '$ADMIN_EMAIL' LIMIT 1);

-- 插入或更新开发团队成员记录
INSERT INTO dev_team_users (
    user_id, 
    team_role, 
    server_access_level, 
    code_access_modules, 
    database_access, 
    service_restart_permissions, 
    status, 
    created_at, 
    updated_at
) VALUES (
    @user_id,
    'super_admin',
    'full',
    '["frontend", "backend", "database", "config"]',
    '["all"]',
    '["all"]',
    'active',
    NOW(),
    NOW()
) ON DUPLICATE KEY UPDATE
    team_role = 'super_admin',
    server_access_level = 'full',
    code_access_modules = '["frontend", "backend", "database", "config"]',
    database_access = '["all"]',
    service_restart_permissions = '["all"]',
    status = 'active',
    updated_at = NOW();
EOF
            log_success "用户 $ADMIN_USERNAME 已更新为超级管理员"
        else
            log_info "跳过用户更新"
            exit 0
        fi
    else
        # 创建新用户
        mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$MYSQL_ROOT_PASSWORD" -D"$DB_NAME" <<EOF
-- 创建用户
INSERT INTO users (
    uuid,
    username,
    email,
    password_hash,
    first_name,
    status,
    email_verified,
    created_at,
    updated_at
) VALUES (
    '$ADMIN_UUID',
    '$ADMIN_USERNAME',
    '$ADMIN_EMAIL',
    '$ADMIN_PASSWORD_HASH',
    '$ADMIN_REAL_NAME',
    'active',
    1,
    NOW(),
    NOW()
);

-- 获取新创建的用户ID
SET @user_id = LAST_INSERT_ID();

-- 创建开发团队成员记录
INSERT INTO dev_team_users (
    user_id, 
    team_role, 
    server_access_level, 
    code_access_modules, 
    database_access, 
    service_restart_permissions, 
    status, 
    created_at, 
    updated_at
) VALUES (
    @user_id,
    'super_admin',
    'full',
    '["frontend", "backend", "database", "config"]',
    '["all"]',
    '["all"]',
    'active',
    NOW(),
    NOW()
);
EOF
        log_success "超级管理员用户 $ADMIN_USERNAME 创建成功"
    fi
}

# 创建SSH密钥对
create_ssh_keys() {
    log_info "创建SSH密钥对..."
    
    SSH_DIR="/opt/jobfirst/.ssh"
    mkdir -p "$SSH_DIR"
    chmod 700 "$SSH_DIR"
    
    if [ ! -f "$SSH_DIR/id_rsa" ]; then
        ssh-keygen -t rsa -b 4096 -f "$SSH_DIR/id_rsa" -N "" -C "jobfirst-super-admin"
        chmod 600 "$SSH_DIR/id_rsa"
        chmod 644 "$SSH_DIR/id_rsa.pub"
        log_success "SSH密钥对创建成功"
    else
        log_info "SSH密钥对已存在"
    fi
    
    # 显示公钥
    log_info "SSH公钥内容:"
    echo "----------------------------------------"
    cat "$SSH_DIR/id_rsa.pub"
    echo "----------------------------------------"
    
    # 更新数据库中的SSH公钥
    SSH_PUBLIC_KEY=$(cat "$SSH_DIR/id_rsa.pub")
    mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$MYSQL_ROOT_PASSWORD" -D"$DB_NAME" <<EOF
UPDATE dev_team_users 
SET ssh_public_key = '$SSH_PUBLIC_KEY'
WHERE team_role = 'super_admin' AND user_id = (
    SELECT id FROM users WHERE username = '$ADMIN_USERNAME'
);
EOF
    log_success "SSH公钥已更新到数据库"
}

# 创建管理员管理脚本
create_admin_scripts() {
    log_info "创建管理员管理脚本..."
    
    # 创建添加团队成员脚本
    cat > /opt/jobfirst/scripts/add-team-member.sh << 'EOF'
#!/bin/bash

# 添加团队成员脚本
# 用法: ./add-team-member.sh <username> <role> <email> <real_name>

if [ $# -ne 4 ]; then
    echo "用法: $0 <username> <role> <email> <real_name>"
    echo "角色选项: super_admin, system_admin, dev_lead, frontend_dev, backend_dev, qa_engineer, guest"
    exit 1
fi

USERNAME=$1
ROLE=$2
EMAIL=$3
REAL_NAME=$4

# 生成随机密码
PASSWORD=$(openssl rand -base64 12)
PASSWORD_HASH=$(echo -n "$PASSWORD" | openssl dgst -sha256 | cut -d' ' -f2)
UUID=$(uuidgen)

# 插入数据库
mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$MYSQL_ROOT_PASSWORD" -D"$DB_NAME" <<EOF
-- 创建用户
INSERT INTO users (
    uuid, username, email, password_hash, first_name, status, email_verified, created_at, updated_at
) VALUES (
    '$UUID', '$USERNAME', '$EMAIL', '$PASSWORD_HASH', '$REAL_NAME', 'active', 1, NOW(), NOW()
);

-- 获取用户ID
SET @user_id = LAST_INSERT_ID();

-- 创建开发团队成员记录
INSERT INTO dev_team_users (
    user_id, team_role, server_access_level, code_access_modules, database_access, service_restart_permissions, status, created_at, updated_at
) VALUES (
    @user_id, '$ROLE', 'limited', '[]', '[]', '[]', 'active', NOW(), NOW()
);
EOF

echo "团队成员 $USERNAME 添加成功"
echo "用户名: $USERNAME"
echo "密码: $PASSWORD"
echo "角色: $ROLE"
echo "请将密码安全地提供给团队成员"
EOF

    chmod +x /opt/jobfirst/scripts/add-team-member.sh
    
    # 创建查看团队成员脚本
    cat > /opt/jobfirst/scripts/list-team-members.sh << 'EOF'
#!/bin/bash

# 查看团队成员脚本

mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$MYSQL_ROOT_PASSWORD" -D"$DB_NAME" <<EOF
SELECT 
    u.username,
    u.email,
    u.first_name,
    u.last_name,
    dtu.team_role,
    dtu.server_access_level,
    dtu.status,
    dtu.created_at
FROM users u
JOIN dev_team_users dtu ON u.id = dtu.user_id
WHERE dtu.deleted_at IS NULL
ORDER BY dtu.created_at DESC;
EOF
EOF

    chmod +x /opt/jobfirst/scripts/list-team-members.sh
    
    log_success "管理员管理脚本创建成功"
}

# 设置环境变量
setup_environment() {
    log_info "设置环境变量..."
    
    cat >> /opt/jobfirst/.env << EOF

# 开发团队管理配置
DEV_TEAM_ENABLED=true
SUPER_ADMIN_USERNAME=$ADMIN_USERNAME
SUPER_ADMIN_EMAIL=$ADMIN_EMAIL
EOF
    
    log_success "环境变量设置完成"
}

# 创建快速登录脚本
create_quick_login() {
    log_info "创建快速登录脚本..."
    
    cat > /opt/jobfirst/scripts/quick-login.sh << EOF
#!/bin/bash

# 超级管理员快速登录脚本

echo "=== JobFirst 超级管理员快速登录 ==="
echo "用户名: $ADMIN_USERNAME"
echo "邮箱: $ADMIN_EMAIL"
echo "角色: 超级管理员"
echo "权限: 完全访问"
echo ""
echo "您可以使用以下方式登录:"
echo "1. Web界面: http://101.33.251.158/login"
echo "2. API接口: 使用JWT token进行认证"
echo "3. SSH访问: 使用生成的SSH密钥"
echo ""
echo "SSH公钥已配置，您可以直接使用SSH密钥登录服务器"
echo "SSH公钥位置: /opt/jobfirst/.ssh/id_rsa.pub"
EOF

    chmod +x /opt/jobfirst/scripts/quick-login.sh
    
    log_success "快速登录脚本创建成功"
}

# 主函数
main() {
    echo "=========================================="
    echo "    JobFirst 超级管理员初始化脚本"
    echo "=========================================="
    echo ""
    
    check_root
    check_mysql
    get_db_config
    get_mysql_password
    test_db_connection
    create_super_admin
    create_ssh_keys
    create_admin_scripts
    setup_environment
    create_quick_login
    
    echo ""
    echo "=========================================="
    log_success "超级管理员初始化完成！"
    echo "=========================================="
    echo ""
    echo "您的超级管理员信息:"
    echo "用户名: $ADMIN_USERNAME"
    echo "邮箱: $ADMIN_EMAIL"
    echo "角色: 超级管理员"
    echo "权限: 完全访问"
    echo ""
    echo "可用的管理脚本:"
    echo "- /opt/jobfirst/scripts/add-team-member.sh    # 添加团队成员"
    echo "- /opt/jobfirst/scripts/list-team-members.sh  # 查看团队成员"
    echo "- /opt/jobfirst/scripts/quick-login.sh        # 快速登录信息"
    echo ""
    echo "下一步:"
    echo "1. 重启后端服务以加载新配置"
    echo "2. 使用您的账号登录系统"
    echo "3. 开始添加其他团队成员"
    echo ""
    log_success "初始化完成！您现在拥有完全的管理员权限！"
}

# 执行主函数
main "$@"
