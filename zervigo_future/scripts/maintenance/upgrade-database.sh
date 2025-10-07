#!/bin/bash

# JobFirst 数据库升级脚本
# 版本: V3.0 -> V4.0
# 日期: 2025年1月6日
# 描述: 执行数据库升级和初始化

set -e  # 遇到错误立即退出

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

# 配置变量
DB_HOST=${DB_HOST:-"localhost"}
DB_USER=${DB_USER:-"root"}
DB_PASSWORD=${DB_PASSWORD:-""}
DB_NAME=${DB_NAME:-"jobfirst"}
BACKUP_DIR="./backup"
UPGRADE_SCRIPT="./database/mysql/upgrade_script.sql"
INIT_SCRIPT="./database/mysql/upgrade_init_data.sql"

# 检查必要文件
check_files() {
    log_info "检查必要文件..."
    
    if [ ! -f "$UPGRADE_SCRIPT" ]; then
        log_error "升级脚本不存在: $UPGRADE_SCRIPT"
        exit 1
    fi
    
    if [ ! -f "$INIT_SCRIPT" ]; then
        log_error "初始化脚本不存在: $INIT_SCRIPT"
        exit 1
    fi
    
    log_success "必要文件检查完成"
}

# 创建备份目录
create_backup_dir() {
    log_info "创建备份目录..."
    mkdir -p "$BACKUP_DIR"
    log_success "备份目录创建完成: $BACKUP_DIR"
}

# 数据库备份
backup_database() {
    log_info "开始数据库备份..."
    
    BACKUP_FILE="$BACKUP_DIR/jobfirst_backup_$(date +%Y%m%d_%H%M%S).sql"
    
    if [ -n "$DB_PASSWORD" ]; then
        mysqldump -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" > "$BACKUP_FILE"
    else
        mysqldump -h "$DB_HOST" -u "$DB_USER" "$DB_NAME" > "$BACKUP_FILE"
    fi
    
    if [ $? -eq 0 ]; then
        log_success "数据库备份完成: $BACKUP_FILE"
    else
        log_error "数据库备份失败"
        exit 1
    fi
}

# 检查数据库连接
check_database_connection() {
    log_info "检查数据库连接..."
    
    if [ -n "$DB_PASSWORD" ]; then
        mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" -e "SELECT 1;" "$DB_NAME" > /dev/null 2>&1
    else
        mysql -h "$DB_HOST" -u "$DB_USER" -e "SELECT 1;" "$DB_NAME" > /dev/null 2>&1
    fi
    
    if [ $? -eq 0 ]; then
        log_success "数据库连接正常"
    else
        log_error "数据库连接失败"
        exit 1
    fi
}

# 检查现有表结构
check_existing_tables() {
    log_info "检查现有表结构..."
    
    if [ -n "$DB_PASSWORD" ]; then
        TABLE_COUNT=$(mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$DB_NAME';" -s -N)
    else
        TABLE_COUNT=$(mysql -h "$DB_HOST" -u "$DB_USER" -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$DB_NAME';" -s -N)
    fi
    
    log_info "当前数据库表数量: $TABLE_COUNT"
    
    if [ "$TABLE_COUNT" -eq 0 ]; then
        log_warning "数据库为空，将执行完整初始化"
        return 1
    elif [ "$TABLE_COUNT" -lt 10 ]; then
        log_warning "数据库表数量较少，可能是基础版本"
        return 2
    else
        log_info "数据库表数量正常，将执行升级"
        return 0
    fi
}

# 执行升级脚本
execute_upgrade() {
    log_info "开始执行数据库升级..."
    
    if [ -n "$DB_PASSWORD" ]; then
        mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" < "$UPGRADE_SCRIPT"
    else
        mysql -h "$DB_HOST" -u "$DB_USER" "$DB_NAME" < "$UPGRADE_SCRIPT"
    fi
    
    if [ $? -eq 0 ]; then
        log_success "数据库升级完成"
    else
        log_error "数据库升级失败"
        exit 1
    fi
}

# 执行初始化脚本
execute_init() {
    log_info "开始执行数据初始化..."
    
    if [ -n "$DB_PASSWORD" ]; then
        mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" < "$INIT_SCRIPT"
    else
        mysql -h "$DB_HOST" -u "$DB_USER" "$DB_NAME" < "$INIT_SCRIPT"
    fi
    
    if [ $? -eq 0 ]; then
        log_success "数据初始化完成"
    else
        log_error "数据初始化失败"
        exit 1
    fi
}

# 验证升级结果
verify_upgrade() {
    log_info "验证升级结果..."
    
    if [ -n "$DB_PASSWORD" ]; then
        TABLE_COUNT=$(mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$DB_NAME';" -s -N)
        ROLE_COUNT=$(mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" -e "SELECT COUNT(*) FROM roles;" -s -N 2>/dev/null || echo "0")
        PERMISSION_COUNT=$(mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" -e "SELECT COUNT(*) FROM permissions;" -s -N 2>/dev/null || echo "0")
        AI_MODEL_COUNT=$(mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" -e "SELECT COUNT(*) FROM ai_models;" -s -N 2>/dev/null || echo "0")
    else
        TABLE_COUNT=$(mysql -h "$DB_HOST" -u "$DB_USER" -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$DB_NAME';" -s -N)
        ROLE_COUNT=$(mysql -h "$DB_HOST" -u "$DB_USER" -e "SELECT COUNT(*) FROM roles;" -s -N 2>/dev/null || echo "0")
        PERMISSION_COUNT=$(mysql -h "$DB_HOST" -u "$DB_USER" -e "SELECT COUNT(*) FROM permissions;" -s -N 2>/dev/null || echo "0")
        AI_MODEL_COUNT=$(mysql -h "$DB_HOST" -u "$DB_USER" -e "SELECT COUNT(*) FROM ai_models;" -s -N 2>/dev/null || echo "0")
    fi
    
    log_info "升级后统计:"
    log_info "  - 表数量: $TABLE_COUNT"
    log_info "  - 角色数量: $ROLE_COUNT"
    log_info "  - 权限数量: $PERMISSION_COUNT"
    log_info "  - AI模型数量: $AI_MODEL_COUNT"
    
    if [ "$TABLE_COUNT" -ge 25 ] && [ "$ROLE_COUNT" -ge 5 ] && [ "$PERMISSION_COUNT" -ge 20 ] && [ "$AI_MODEL_COUNT" -ge 5 ]; then
        log_success "升级验证通过"
        return 0
    else
        log_warning "升级验证未完全通过，请检查"
        return 1
    fi
}

# 显示升级报告
show_upgrade_report() {
    log_info "生成升级报告..."
    
    REPORT_FILE="$BACKUP_DIR/upgrade_report_$(date +%Y%m%d_%H%M%S).txt"
    
    cat > "$REPORT_FILE" << EOF
JobFirst 数据库升级报告
========================

升级时间: $(date)
升级版本: V3.0 -> V4.0
数据库: $DB_NAME
主机: $DB_HOST

升级内容:
---------
1. 权限管理系统 (6个表)
   - roles: 角色管理
   - permissions: 权限管理
   - role_permissions: 角色权限关联
   - user_roles: 用户角色关联
   - permission_audit_logs: 权限审计日志
   - data_access_logs: 数据访问日志

2. 数据分类标签系统 (2个表)
   - data_classification_tags: 数据分类标签
   - data_lifecycle_policies: 数据生命周期策略

3. AI服务数据库架构 (12个表)
   - ai_models: AI模型管理
   - model_versions: 模型版本管理
   - company_ai_profiles: 企业AI画像
   - company_embeddings: 企业嵌入向量
   - job_ai_analysis: 职位AI分析
   - job_embeddings: 职位嵌入向量
   - user_ai_profiles: 用户AI画像
   - user_embeddings: 用户嵌入向量
   - job_recommendations: 职位推荐
   - company_recommendations: 企业推荐
   - ai_conversations: AI对话会话
   - ai_messages: AI对话消息

4. AI服务监控和缓存 (3个表)
   - ai_service_logs: AI服务日志
   - ai_performance_metrics: AI性能指标
   - ai_cache: AI缓存

5. 个人信息保护升级
   - 为现有表添加加密字段
   - 创建数据脱敏视图
   - 实施4级敏感程度分级保护

6. 企业职位管理升级 (2个表)
   - job_skills: 职位技能关联
   - user_skills: 用户技能
   - 升级jobs表结构

初始化数据:
-----------
- 6个系统角色 (super_admin, system_admin, data_admin, hr_admin, company_admin, regular_user)
- 25个基础权限 (4级权限分级)
- 6个AI模型 (gemma3-4b, gpt-3.5-turbo, claude-3-haiku等)
- 完整的数据分类标签 (80+字段分类)
- 数据生命周期策略

备份信息:
---------
备份文件: $BACKUP_FILE

注意事项:
---------
1. 请确保应用程序已更新以支持新的数据库结构
2. 建议在升级后进行全面测试
3. 定期检查AI服务日志和性能指标
4. 根据数据生命周期策略定期清理过期数据

升级状态: 成功完成
EOF

    log_success "升级报告已生成: $REPORT_FILE"
}

# 主函数
main() {
    echo "=========================================="
    echo "JobFirst 数据库升级脚本 V3.0 -> V4.0"
    echo "=========================================="
    echo ""
    
    # 检查必要文件
    check_files
    
    # 创建备份目录
    create_backup_dir
    
    # 检查数据库连接
    check_database_connection
    
    # 检查现有表结构
    check_existing_tables
    EXISTING_STATUS=$?
    
    # 数据库备份
    backup_database
    
    # 执行升级脚本
    execute_upgrade
    
    # 执行初始化脚本
    execute_init
    
    # 验证升级结果
    verify_upgrade
    VERIFY_STATUS=$?
    
    # 显示升级报告
    show_upgrade_report
    
    echo ""
    echo "=========================================="
    if [ $VERIFY_STATUS -eq 0 ]; then
        log_success "数据库升级完成！"
        echo ""
        echo "下一步操作:"
        echo "1. 更新应用程序代码以支持新的数据库结构"
        echo "2. 重启相关服务"
        echo "3. 进行功能测试"
        echo "4. 检查AI服务配置"
    else
        log_warning "数据库升级完成，但验证未完全通过"
        echo ""
        echo "请检查:"
        echo "1. 数据库连接和权限"
        echo "2. 升级脚本执行日志"
        echo "3. 表结构是否正确创建"
    fi
    echo "=========================================="
}

# 帮助信息
show_help() {
    echo "JobFirst 数据库升级脚本"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help              显示帮助信息"
    echo "  --host HOST             数据库主机 (默认: localhost)"
    echo "  --user USER             数据库用户 (默认: root)"
    echo "  --password PASSWORD     数据库密码"
    echo "  --database DATABASE     数据库名称 (默认: jobfirst)"
    echo "  --backup-dir DIR        备份目录 (默认: ./backup)"
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
        --backup-dir)
            BACKUP_DIR="$2"
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
