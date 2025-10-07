#!/bin/bash

# 数据库权限管理系统适配脚本
# 确保现有数据库与新增的权限管理系统兼容

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 数据库配置
DB_HOST="localhost"
DB_PORT="3306"
DB_NAME="jobfirst"
DB_USER="root"

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

# 检查数据库连接
check_database_connection() {
    log_info "检查数据库连接..."
    if mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p -e "USE $DB_NAME;" > /dev/null 2>&1; then
        log_success "数据库连接成功"
        return 0
    else
        log_error "数据库连接失败"
        return 1
    fi
}

# 检查必要的表是否存在
check_required_tables() {
    log_info "检查必要的表结构..."
    
    local required_tables=("users" "roles" "permissions" "user_roles" "role_permissions" "casbin_rule")
    local missing_tables=()
    
    for table in "${required_tables[@]}"; do
        if mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p -e "USE $DB_NAME; DESCRIBE $table;" > /dev/null 2>&1; then
            log_success "表 $table 存在"
        else
            log_warning "表 $table 不存在"
            missing_tables+=("$table")
        fi
    done
    
    if [ ${#missing_tables[@]} -eq 0 ]; then
        log_success "所有必要的表都存在"
        return 0
    else
        log_error "缺少以下表: ${missing_tables[*]}"
        return 1
    fi
}

# 检查用户表结构
check_users_table_structure() {
    log_info "检查用户表结构..."
    
    # 检查必要的字段
    local required_fields=("id" "uuid" "username" "email" "password_hash" "first_name" "last_name" "status" "email_verified" "created_at" "updated_at")
    local missing_fields=()
    
    for field in "${required_fields[@]}"; do
        if mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p -e "USE $DB_NAME; SELECT $field FROM users LIMIT 1;" > /dev/null 2>&1; then
            log_success "字段 $field 存在"
        else
            log_warning "字段 $field 不存在"
            missing_fields+=("$field")
        fi
    done
    
    if [ ${#missing_fields[@]} -eq 0 ]; then
        log_success "用户表结构完整"
        return 0
    else
        log_error "用户表缺少以下字段: ${missing_fields[*]}"
        return 1
    fi
}

# 检查角色数据
check_roles_data() {
    log_info "检查角色数据..."
    
    local role_count=$(mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p -e "USE $DB_NAME; SELECT COUNT(*) FROM roles;" 2>/dev/null | tail -n 1)
    
    if [ "$role_count" -gt 0 ]; then
        log_success "角色数据存在 ($role_count 个角色)"
        
        # 检查是否有超级管理员角色
        local super_admin_exists=$(mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p -e "USE $DB_NAME; SELECT COUNT(*) FROM roles WHERE name = 'super_admin';" 2>/dev/null | tail -n 1)
        
        if [ "$super_admin_exists" -gt 0 ]; then
            log_success "超级管理员角色存在"
        else
            log_warning "超级管理员角色不存在，需要创建"
            create_super_admin_role
        fi
    else
        log_warning "没有角色数据，需要初始化"
        initialize_roles
    fi
}

# 创建超级管理员角色
create_super_admin_role() {
    log_info "创建超级管理员角色..."
    
    mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p -e "USE $DB_NAME; INSERT INTO roles (name, display_name, description, level, is_system, is_active, created_at, updated_at) VALUES ('super_admin', 'Super Administrator', 'System super administrator with full access', 5, 1, 1, NOW(), NOW()) ON DUPLICATE KEY UPDATE display_name = 'Super Administrator';" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        log_success "超级管理员角色创建成功"
    else
        log_error "超级管理员角色创建失败"
    fi
}

# 初始化角色
initialize_roles() {
    log_info "初始化基础角色..."
    
    # 创建基础角色
    mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p -e "USE $DB_NAME; 
    INSERT INTO roles (name, display_name, description, level, is_system, is_active, created_at, updated_at) VALUES 
    ('super_admin', 'Super Administrator', 'System super administrator with full access', 5, 1, 1, NOW(), NOW()),
    ('admin', 'Administrator', 'System administrator', 4, 1, 1, NOW(), NOW()),
    ('dev_team', 'Development Team', 'Development team member', 3, 1, 1, NOW(), NOW()),
    ('user', 'Regular User', 'Regular user', 1, 1, 1, NOW(), NOW())
    ON DUPLICATE KEY UPDATE display_name = VALUES(display_name);" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        log_success "基础角色初始化成功"
    else
        log_error "基础角色初始化失败"
    fi
}

# 检查权限数据
check_permissions_data() {
    log_info "检查权限数据..."
    
    local permission_count=$(mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p -e "USE $DB_NAME; SELECT COUNT(*) FROM permissions;" 2>/dev/null | tail -n 1)
    
    if [ "$permission_count" -gt 0 ]; then
        log_success "权限数据存在 ($permission_count 个权限)"
    else
        log_warning "没有权限数据，需要初始化"
        initialize_permissions
    fi
}

# 初始化权限
initialize_permissions() {
    log_info "初始化基础权限..."
    
    # 创建基础权限
    mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p -e "USE $DB_NAME; 
    INSERT INTO permissions (name, display_name, description, resource, action, level, is_system, is_active, created_at, updated_at) VALUES 
    ('user_read', 'Read User Information', 'Read user information', 'user', 'read', 1, 1, 1, NOW(), NOW()),
    ('user_write', 'Create and Update Users', 'Create and update users', 'user', 'write', 2, 1, 1, NOW(), NOW()),
    ('user_delete', 'Delete Users', 'Delete users', 'user', 'delete', 3, 1, 1, NOW(), NOW()),
    ('role_read', 'Read Role Information', 'Read role information', 'role', 'read', 1, 1, 1, NOW(), NOW()),
    ('role_write', 'Create and Update Roles', 'Create and update roles', 'role', 'write', 2, 1, 1, NOW(), NOW()),
    ('role_delete', 'Delete Roles', 'Delete roles', 'role', 'delete', 3, 1, 1, NOW(), NOW()),
    ('permission_read', 'Read Permission Information', 'Read permission information', 'permission', 'read', 1, 1, 1, NOW(), NOW()),
    ('permission_write', 'Create and Update Permissions', 'Create and update permissions', 'permission', 'write', 2, 1, 1, NOW(), NOW()),
    ('permission_delete', 'Delete Permissions', 'Delete permissions', 'permission', 'delete', 3, 1, 1, NOW(), NOW()),
    ('system_read', 'Read System Information', 'Read system information', 'system', 'read', 1, 1, 1, NOW(), NOW()),
    ('system_write', 'Modify System Settings', 'Modify system settings', 'system', 'write', 2, 1, 1, NOW(), NOW()),
    ('system_delete', 'Delete System Data', 'Delete system data', 'system', 'delete', 3, 1, 1, NOW(), NOW())
    ON DUPLICATE KEY UPDATE display_name = VALUES(display_name);" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        log_success "基础权限初始化成功"
    else
        log_error "基础权限初始化失败"
    fi
}

# 检查Casbin规则
check_casbin_rules() {
    log_info "检查Casbin规则..."
    
    local casbin_count=$(mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p -e "USE $DB_NAME; SELECT COUNT(*) FROM casbin_rule;" 2>/dev/null | tail -n 1)
    
    if [ "$casbin_count" -gt 0 ]; then
        log_success "Casbin规则存在 ($casbin_count 条规则)"
    else
        log_warning "没有Casbin规则，需要初始化"
        initialize_casbin_rules
    fi
}

# 初始化Casbin规则
initialize_casbin_rules() {
    log_info "初始化Casbin规则..."
    
    # 创建基础Casbin规则
    mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p -e "USE $DB_NAME; 
    INSERT INTO casbin_rule (ptype, v0, v1, v2) VALUES 
    ('p', 'super_admin', 'user', 'read'),
    ('p', 'super_admin', 'user', 'write'),
    ('p', 'super_admin', 'user', 'delete'),
    ('p', 'super_admin', 'role', 'read'),
    ('p', 'super_admin', 'role', 'write'),
    ('p', 'super_admin', 'role', 'delete'),
    ('p', 'super_admin', 'permission', 'read'),
    ('p', 'super_admin', 'permission', 'write'),
    ('p', 'super_admin', 'permission', 'delete'),
    ('p', 'super_admin', 'system', 'read'),
    ('p', 'super_admin', 'system', 'write'),
    ('p', 'super_admin', 'system', 'delete'),
    ('p', 'admin', 'user', 'read'),
    ('p', 'admin', 'user', 'write'),
    ('p', 'admin', 'role', 'read'),
    ('p', 'admin', 'permission', 'read'),
    ('p', 'dev_team', 'user', 'read'),
    ('p', 'dev_team', 'code', 'read'),
    ('p', 'dev_team', 'code', 'write'),
    ('p', 'dev_team', 'database', 'read'),
    ('p', 'user', 'profile', 'read'),
    ('p', 'user', 'profile', 'write'),
    ('p', 'user', 'resume', 'read'),
    ('p', 'user', 'resume', 'write');" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        log_success "Casbin规则初始化成功"
    else
        log_error "Casbin规则初始化失败"
    fi
}

# 检查用户角色分配
check_user_role_assignments() {
    log_info "检查用户角色分配..."
    
    local assignment_count=$(mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p -e "USE $DB_NAME; SELECT COUNT(*) FROM user_roles;" 2>/dev/null | tail -n 1)
    
    if [ "$assignment_count" -gt 0 ]; then
        log_success "用户角色分配存在 ($assignment_count 个分配)"
    else
        log_warning "没有用户角色分配"
    fi
}

# 生成数据报告
generate_data_report() {
    log_info "生成数据报告..."
    
    echo "=========================================="
    echo "📊 数据库权限管理系统状态报告"
    echo "=========================================="
    
    # 用户统计
    local user_count=$(mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p -e "USE $DB_NAME; SELECT COUNT(*) FROM users;" 2>/dev/null | tail -n 1)
    echo "👥 用户数量: $user_count"
    
    # 角色统计
    local role_count=$(mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p -e "USE $DB_NAME; SELECT COUNT(*) FROM roles;" 2>/dev/null | tail -n 1)
    echo "🎭 角色数量: $role_count"
    
    # 权限统计
    local permission_count=$(mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p -e "USE $DB_NAME; SELECT COUNT(*) FROM permissions;" 2>/dev/null | tail -n 1)
    echo "🔐 权限数量: $permission_count"
    
    # Casbin规则统计
    local casbin_count=$(mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p -e "USE $DB_NAME; SELECT COUNT(*) FROM casbin_rule;" 2>/dev/null | tail -n 1)
    echo "📋 Casbin规则数量: $casbin_count"
    
    # 用户角色分配统计
    local assignment_count=$(mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p -e "USE $DB_NAME; SELECT COUNT(*) FROM user_roles;" 2>/dev/null | tail -n 1)
    echo "🔗 用户角色分配数量: $assignment_count"
    
    echo "=========================================="
}

# 主函数
main() {
    echo "=========================================="
    echo "🔧 数据库权限管理系统适配工具"
    echo "=========================================="
    
    # 检查数据库连接
    if ! check_database_connection; then
        exit 1
    fi
    
    # 检查必要的表
    if ! check_required_tables; then
        log_error "缺少必要的表，请先运行数据库迁移"
        exit 1
    fi
    
    # 检查用户表结构
    if ! check_users_table_structure; then
        log_error "用户表结构不完整，请检查数据库结构"
        exit 1
    fi
    
    # 检查并初始化角色数据
    check_roles_data
    
    # 检查并初始化权限数据
    check_permissions_data
    
    # 检查并初始化Casbin规则
    check_casbin_rules
    
    # 检查用户角色分配
    check_user_role_assignments
    
    # 生成数据报告
    generate_data_report
    
    log_success "数据库权限管理系统适配完成！"
    echo "=========================================="
}

# 运行主函数
main "$@"
