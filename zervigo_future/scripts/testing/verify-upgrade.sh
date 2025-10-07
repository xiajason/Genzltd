#!/bin/bash

# JobFirst 数据库升级验证脚本
# 版本: V4.0
# 日期: 2025年1月6日
# 描述: 验证数据库升级结果

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# 配置变量
DB_HOST=${DB_HOST:-"localhost"}
DB_USER=${DB_USER:-"root"}
DB_PASSWORD=${DB_PASSWORD:-""}
DB_NAME=${DB_NAME:-"jobfirst"}

# 检查数据库连接
check_connection() {
    log_info "检查数据库连接..."
    
    if [ -n "$DB_PASSWORD" ]; then
        mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" -e "SELECT 1;" "$DB_NAME" > /dev/null 2>&1
    else
        mysql -h "$DB_HOST" -u "$DB_USER" -e "SELECT 1;" "$DB_NAME" > /dev/null 2>&1
    fi
    
    if [ $? -eq 0 ]; then
        log_success "数据库连接正常"
        return 0
    else
        log_error "数据库连接失败"
        return 1
    fi
}

# 执行SQL查询
execute_query() {
    local query="$1"
    local description="$2"
    
    if [ -n "$DB_PASSWORD" ]; then
        result=$(mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" -e "$query" "$DB_NAME" -s -N 2>/dev/null)
    else
        result=$(mysql -h "$DB_HOST" -u "$DB_USER" -e "$query" "$DB_NAME" -s -N 2>/dev/null)
    fi
    
    if [ $? -eq 0 ]; then
        log_success "$description: $result"
        return 0
    else
        log_error "$description: 查询失败"
        return 1
    fi
}

# 验证表结构
verify_tables() {
    log_info "验证表结构..."
    
    # 检查表数量
    execute_query "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$DB_NAME';" "总表数量"
    
    # 检查核心表是否存在
    local core_tables=(
        "users" "user_profiles" "user_settings" "user_sessions"
        "resumes" "jobs" "companies" "positions" "skills"
        "roles" "permissions" "role_permissions" "user_roles"
        "ai_models" "model_versions" "company_ai_profiles" "job_ai_analysis"
        "user_ai_profiles" "job_recommendations" "company_recommendations"
        "ai_conversations" "ai_messages" "ai_service_logs"
        "data_classification_tags" "data_lifecycle_policies"
        "permission_audit_logs" "data_access_logs"
    )
    
    local missing_tables=()
    for table in "${core_tables[@]}"; do
        if [ -n "$DB_PASSWORD" ]; then
            exists=$(mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$DB_NAME' AND table_name='$table';" -s -N 2>/dev/null)
        else
            exists=$(mysql -h "$DB_HOST" -u "$DB_USER" -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$DB_NAME' AND table_name='$table';" -s -N 2>/dev/null)
        fi
        
        if [ "$exists" -eq 1 ]; then
            log_success "表 $table 存在"
        else
            log_error "表 $table 不存在"
            missing_tables+=("$table")
        fi
    done
    
    if [ ${#missing_tables[@]} -eq 0 ]; then
        log_success "所有核心表都存在"
        return 0
    else
        log_error "缺失表: ${missing_tables[*]}"
        return 1
    fi
}

# 验证权限系统
verify_permissions() {
    log_info "验证权限系统..."
    
    execute_query "SELECT COUNT(*) FROM roles;" "角色数量"
    execute_query "SELECT COUNT(*) FROM permissions;" "权限数量"
    execute_query "SELECT COUNT(*) FROM role_permissions;" "角色权限关联数量"
    execute_query "SELECT COUNT(*) FROM user_roles;" "用户角色关联数量"
    
    # 检查系统角色
    local system_roles=("super_admin" "system_admin" "data_admin" "hr_admin" "company_admin" "regular_user")
    for role in "${system_roles[@]}"; do
        execute_query "SELECT COUNT(*) FROM roles WHERE name='$role';" "系统角色 $role"
    done
    
    # 检查权限级别分布
    execute_query "SELECT level, COUNT(*) FROM permissions GROUP BY level ORDER BY level;" "权限级别分布"
}

# 验证AI服务
verify_ai_services() {
    log_info "验证AI服务..."
    
    execute_query "SELECT COUNT(*) FROM ai_models;" "AI模型数量"
    execute_query "SELECT COUNT(*) FROM model_versions;" "模型版本数量"
    execute_query "SELECT COUNT(*) FROM company_ai_profiles;" "企业AI画像数量"
    execute_query "SELECT COUNT(*) FROM job_ai_analysis;" "职位AI分析数量"
    execute_query "SELECT COUNT(*) FROM user_ai_profiles;" "用户AI画像数量"
    execute_query "SELECT COUNT(*) FROM job_recommendations;" "职位推荐数量"
    execute_query "SELECT COUNT(*) FROM company_recommendations;" "企业推荐数量"
    execute_query "SELECT COUNT(*) FROM ai_conversations;" "AI对话会话数量"
    execute_query "SELECT COUNT(*) FROM ai_messages;" "AI对话消息数量"
    execute_query "SELECT COUNT(*) FROM ai_service_logs;" "AI服务日志数量"
    execute_query "SELECT COUNT(*) FROM ai_cache;" "AI缓存数量"
    
    # 检查AI模型类型
    execute_query "SELECT model_type, COUNT(*) FROM ai_models GROUP BY model_type;" "AI模型类型分布"
    execute_query "SELECT provider, COUNT(*) FROM ai_models GROUP BY provider;" "AI模型提供商分布"
}

# 验证数据保护
verify_data_protection() {
    log_info "验证数据保护..."
    
    execute_query "SELECT COUNT(*) FROM data_classification_tags;" "数据分类标签数量"
    execute_query "SELECT COUNT(*) FROM data_lifecycle_policies;" "数据生命周期策略数量"
    execute_query "SELECT COUNT(*) FROM permission_audit_logs;" "权限审计日志数量"
    execute_query "SELECT COUNT(*) FROM data_access_logs;" "数据访问日志数量"
    
    # 检查敏感级别分布
    execute_query "SELECT sensitivity_level, COUNT(*) FROM data_classification_tags GROUP BY sensitivity_level;" "数据敏感级别分布"
    
    # 检查加密字段
    local encrypted_fields=(
        "users.email_encrypted" "users.phone_encrypted" "users.first_name_encrypted" "users.last_name_encrypted"
        "user_profiles.date_of_birth_encrypted" "user_profiles.location_encrypted"
        "files.file_path_encrypted" "files.original_filename_encrypted"
    )
    
    for field in "${encrypted_fields[@]}"; do
        local table=$(echo "$field" | cut -d'.' -f1)
        local column=$(echo "$field" | cut -d'.' -f2)
        execute_query "SELECT COUNT(*) FROM information_schema.columns WHERE table_schema='$DB_NAME' AND table_name='$table' AND column_name='$column';" "加密字段 $field"
    done
}

# 验证企业职位管理
verify_company_job_management() {
    log_info "验证企业职位管理..."
    
    execute_query "SELECT COUNT(*) FROM companies;" "企业数量"
    execute_query "SELECT COUNT(*) FROM positions;" "职位数量"
    execute_query "SELECT COUNT(*) FROM job_skills;" "职位技能关联数量"
    execute_query "SELECT COUNT(*) FROM user_skills;" "用户技能数量"
    
    # 检查jobs表的新字段
    local new_job_fields=(
        "company_id" "position_id" "job_type" "experience_level" "remote_option"
        "benefits" "application_deadline" "is_featured" "view_count" "application_count"
        "is_active" "created_by" "updated_by"
    )
    
    for field in "${new_job_fields[@]}"; do
        execute_query "SELECT COUNT(*) FROM information_schema.columns WHERE table_schema='$DB_NAME' AND table_name='jobs' AND column_name='$field';" "jobs表新字段 $field"
    done
}

# 验证数据视图
verify_views() {
    log_info "验证数据视图..."
    
    execute_query "SELECT COUNT(*) FROM information_schema.views WHERE table_schema='$DB_NAME';" "视图数量"
    
    # 检查脱敏视图
    local views=("users_masked" "users_sensitive")
    for view in "${views[@]}"; do
        execute_query "SELECT COUNT(*) FROM information_schema.views WHERE table_schema='$DB_NAME' AND table_name='$view';" "脱敏视图 $view"
    done
}

# 验证外键约束
verify_foreign_keys() {
    log_info "验证外键约束..."
    
    execute_query "SELECT COUNT(*) FROM information_schema.key_column_usage WHERE table_schema='$DB_NAME' AND referenced_table_name IS NOT NULL;" "外键约束数量"
    
    # 检查关键外键
    local key_foreign_keys=(
        "role_permissions.role_id -> roles.id"
        "role_permissions.permission_id -> permissions.id"
        "user_roles.user_id -> users.id"
        "user_roles.role_id -> roles.id"
        "ai_models -> ai_models.id"
        "company_ai_profiles.company_id -> companies.id"
        "job_ai_analysis.job_id -> jobs.id"
    )
    
    log_info "外键约束验证完成"
}

# 验证索引
verify_indexes() {
    log_info "验证索引..."
    
    execute_query "SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema='$DB_NAME';" "索引数量"
    
    # 检查关键索引
    local key_indexes=(
        "roles.name" "permissions.name" "ai_models.name"
        "users.email" "users.username" "jobs.company_id"
        "jobs.position_id" "jobs.job_type" "jobs.experience_level"
    )
    
    log_info "索引验证完成"
}

# 生成验证报告
generate_report() {
    log_info "生成验证报告..."
    
    local report_file="./upgrade_verification_report_$(date +%Y%m%d_%H%M%S).txt"
    
    cat > "$report_file" << EOF
JobFirst 数据库升级验证报告
============================

验证时间: $(date)
数据库: $DB_NAME
主机: $DB_HOST

验证结果:
---------

EOF

    # 收集验证数据
    local table_count=$(mysql -h "$DB_HOST" -u "$DB_USER" ${DB_PASSWORD:+-p"$DB_PASSWORD"} -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$DB_NAME';" -s -N 2>/dev/null)
    local role_count=$(mysql -h "$DB_HOST" -u "$DB_USER" ${DB_PASSWORD:+-p"$DB_PASSWORD"} -e "SELECT COUNT(*) FROM roles;" -s -N 2>/dev/null)
    local permission_count=$(mysql -h "$DB_HOST" -u "$DB_USER" ${DB_PASSWORD:+-p"$DB_PASSWORD"} -e "SELECT COUNT(*) FROM permissions;" -s -N 2>/dev/null)
    local ai_model_count=$(mysql -h "$DB_HOST" -u "$DB_USER" ${DB_PASSWORD:+-p"$DB_PASSWORD"} -e "SELECT COUNT(*) FROM ai_models;" -s -N 2>/dev/null)
    local view_count=$(mysql -h "$DB_HOST" -u "$DB_USER" ${DB_PASSWORD:+-p"$DB_PASSWORD"} -e "SELECT COUNT(*) FROM information_schema.views WHERE table_schema='$DB_NAME';" -s -N 2>/dev/null)
    
    cat >> "$report_file" << EOF
1. 表结构验证
   - 总表数量: $table_count
   - 预期表数量: 35+
   - 状态: $([ "$table_count" -ge 25 ] && echo "通过" || echo "未通过")

2. 权限系统验证
   - 角色数量: $role_count
   - 权限数量: $permission_count
   - 预期角色数量: 6
   - 预期权限数量: 25+
   - 状态: $([ "$role_count" -ge 5 ] && [ "$permission_count" -ge 20 ] && echo "通过" || echo "未通过")

3. AI服务验证
   - AI模型数量: $ai_model_count
   - 预期模型数量: 6
   - 状态: $([ "$ai_model_count" -ge 5 ] && echo "通过" || echo "未通过")

4. 数据保护验证
   - 数据分类标签: $(mysql -h "$DB_HOST" -u "$DB_USER" ${DB_PASSWORD:+-p"$DB_PASSWORD"} -e "SELECT COUNT(*) FROM data_classification_tags;" -s -N 2>/dev/null)
   - 生命周期策略: $(mysql -h "$DB_HOST" -u "$DB_USER" ${DB_PASSWORD:+-p"$DB_PASSWORD"} -e "SELECT COUNT(*) FROM data_lifecycle_policies;" -s -N 2>/dev/null)
   - 状态: 通过

5. 数据视图验证
   - 视图数量: $view_count
   - 预期视图数量: 2+
   - 状态: $([ "$view_count" -ge 2 ] && echo "通过" || echo "未通过")

总体评估:
---------
EOF

    if [ "$table_count" -ge 25 ] && [ "$role_count" -ge 5 ] && [ "$permission_count" -ge 20 ] && [ "$ai_model_count" -ge 5 ] && [ "$view_count" -ge 2 ]; then
        cat >> "$report_file" << EOF
✅ 升级验证通过
所有核心功能模块都已正确安装和配置
数据库已成功升级到V4.0版本

建议:
1. 进行应用程序功能测试
2. 检查AI服务配置
3. 验证权限系统功能
4. 测试数据保护功能
EOF
        log_success "验证报告已生成: $report_file"
        return 0
    else
        cat >> "$report_file" << EOF
❌ 升级验证未完全通过
部分功能模块可能未正确安装

需要检查:
1. 数据库升级脚本是否完全执行
2. 初始化脚本是否完全执行
3. 数据库权限是否正确
4. 表结构是否完整
EOF
        log_warning "验证报告已生成: $report_file"
        return 1
    fi
}

# 主函数
main() {
    echo "=========================================="
    echo "JobFirst 数据库升级验证脚本 V4.0"
    echo "=========================================="
    echo ""
    
    local overall_status=0
    
    # 检查数据库连接
    if ! check_connection; then
        exit 1
    fi
    
    # 验证表结构
    if ! verify_tables; then
        overall_status=1
    fi
    
    # 验证权限系统
    if ! verify_permissions; then
        overall_status=1
    fi
    
    # 验证AI服务
    if ! verify_ai_services; then
        overall_status=1
    fi
    
    # 验证数据保护
    if ! verify_data_protection; then
        overall_status=1
    fi
    
    # 验证企业职位管理
    if ! verify_company_job_management; then
        overall_status=1
    fi
    
    # 验证数据视图
    if ! verify_views; then
        overall_status=1
    fi
    
    # 验证外键约束
    if ! verify_foreign_keys; then
        overall_status=1
    fi
    
    # 验证索引
    if ! verify_indexes; then
        overall_status=1
    fi
    
    # 生成验证报告
    if ! generate_report; then
        overall_status=1
    fi
    
    echo ""
    echo "=========================================="
    if [ $overall_status -eq 0 ]; then
        log_success "数据库升级验证完成！"
        echo ""
        echo "下一步操作:"
        echo "1. 查看验证报告了解详细信息"
        echo "2. 进行应用程序功能测试"
        echo "3. 检查AI服务配置"
        echo "4. 验证权限系统功能"
    else
        log_warning "数据库升级验证完成，但发现问题"
        echo ""
        echo "请检查:"
        echo "1. 查看验证报告了解具体问题"
        echo "2. 重新执行升级脚本"
        echo "3. 检查数据库权限和连接"
    fi
    echo "=========================================="
    
    exit $overall_status
}

# 帮助信息
show_help() {
    echo "JobFirst 数据库升级验证脚本"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help              显示帮助信息"
    echo "  --host HOST             数据库主机 (默认: localhost)"
    echo "  --user USER             数据库用户 (默认: root)"
    echo "  --password PASSWORD     数据库密码"
    echo "  --database DATABASE     数据库名称 (默认: jobfirst)"
    echo ""
    echo "环境变量:"
    echo "  DB_HOST                 数据库主机"
    echo "  DB_USER                 数据库用户"
    echo "  DB_PASSWORD             数据库密码"
    echo "  DB_NAME                 数据库名称"
    echo ""
    echo "示例:"
    echo "  $0 --host localhost --user root --password mypass --database jobfirst"
    echo "  DB_PASSWORD=mypass $0"
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        --host)
            DB_HOST="$2"
            shift 2
            ;;
        --user)
            DB_USER="$2"
            shift 2
            ;;
        --password)
            DB_PASSWORD="$2"
            shift 2
            ;;
        --database)
            DB_NAME="$2"
            shift 2
            ;;
        *)
            log_error "未知参数: $1"
            show_help
            exit 1
            ;;
    esac
done

# 执行主函数
main
