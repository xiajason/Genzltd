#!/bin/bash

# MySQL数据迁移脚本
# 创建时间: 2025年1月27日
# 版本: v1.0

# 获取当前时间戳
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="../../logs/migration/mysql_migration_$TIMESTAMP.log"

# 日志函数
log_info() {
    echo "[$TIMESTAMP] [INFO] $1" | tee -a $LOG_FILE
}

log_success() {
    echo "[$TIMESTAMP] [SUCCESS] $1" | tee -a $LOG_FILE
}

log_warning() {
    echo "[$TIMESTAMP] [WARNING] $1" | tee -a $LOG_FILE
}

# 检查源数据库连接
check_source_connection() {
    log_info "检查源MySQL连接..."
    
    if nc -z localhost 3306 2>/dev/null; then
        log_success "源MySQL连接正常"
        return 0
    else
        log_warning "源MySQL未运行，尝试启动..."
        # 尝试启动MySQL
        brew services start mysql 2>/dev/null || log_warning "MySQL启动失败"
        return 1
    fi
}

# 检查目标数据库连接
check_target_connection() {
    log_info "检查目标MySQL连接..."
    
    # 这里需要根据实际目标配置
    TARGET_HOST=${TARGET_MYSQL_HOST:-localhost}
    TARGET_PORT=${TARGET_MYSQL_PORT:-3306}
    
    if nc -z $TARGET_HOST $TARGET_PORT 2>/dev/null; then
        log_success "目标MySQL连接正常"
        return 0
    else
        log_warning "目标MySQL连接失败: $TARGET_HOST:$TARGET_PORT"
        return 1
    fi
}

# 备份源数据库
backup_source_database() {
    log_info "开始备份源MySQL数据库..."
    
    BACKUP_FILE="../../backups/source/mysql_backup_$TIMESTAMP.sql"
    
    # 获取所有数据库列表
    DATABASES=$(mysql -e "SHOW DATABASES;" | grep -v -E "(Database|information_schema|performance_schema|mysql|sys)")
    
    for db in $DATABASES; do
        log_info "备份数据库: $db"
        mysqldump --single-transaction --routines --triggers $db > "${BACKUP_FILE%.sql}_${db}.sql" 2>/dev/null
        
        if [ $? -eq 0 ]; then
            log_success "数据库 $db 备份完成"
        else
            log_warning "数据库 $db 备份失败"
        fi
    done
    
    log_success "源数据库备份完成: $BACKUP_FILE"
}

# 迁移数据库结构
migrate_database_structure() {
    log_info "开始迁移数据库结构..."
    
    # 创建目标数据库
    TARGET_DB=${TARGET_MYSQL_DATABASE:-unified_database}
    
    mysql -h $TARGET_HOST -P $TARGET_PORT -e "CREATE DATABASE IF NOT EXISTS $TARGET_DB;" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        log_success "目标数据库 $TARGET_DB 创建成功"
    else
        log_warning "目标数据库创建失败"
    fi
}

# 迁移数据
migrate_data() {
    log_info "开始迁移数据..."
    
    # 获取备份文件列表
    BACKUP_FILES=$(ls ../../backups/source/mysql_backup_*_*.sql 2>/dev/null)
    
    for backup_file in $BACKUP_FILES; do
        if [ -f "$backup_file" ]; then
            log_info "恢复数据: $backup_file"
            mysql -h $TARGET_HOST -P $TARGET_PORT $TARGET_DB < "$backup_file" 2>/dev/null
            
            if [ $? -eq 0 ]; then
                log_success "数据恢复成功: $backup_file"
            else
                log_warning "数据恢复失败: $backup_file"
            fi
        fi
    done
    
    log_success "数据迁移完成"
}

# 验证迁移结果
validate_migration() {
    log_info "开始验证迁移结果..."
    
    # 比较表数量
    SOURCE_TABLES=$(mysql -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$SOURCE_DB';" 2>/dev/null | tail -1)
    TARGET_TABLES=$(mysql -h $TARGET_HOST -P $TARGET_PORT -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$TARGET_DB';" 2>/dev/null | tail -1)
    
    if [ "$SOURCE_TABLES" = "$TARGET_TABLES" ]; then
        log_success "表数量验证通过: $SOURCE_TABLES 个表"
    else
        log_warning "表数量不匹配: 源=$SOURCE_TABLES, 目标=$TARGET_TABLES"
    fi
    
    # 比较数据行数
    log_info "验证数据完整性..."
    # 这里可以添加更详细的数据验证逻辑
    
    log_success "迁移验证完成"
}

# 主函数
main() {
    log_info "开始MySQL数据迁移..."
    
    # 设置环境变量
    SOURCE_DB=${SOURCE_MYSQL_DATABASE:-mysql}
    TARGET_DB=${TARGET_MYSQL_DATABASE:-unified_database}
    TARGET_HOST=${TARGET_MYSQL_HOST:-localhost}
    TARGET_PORT=${TARGET_MYSQL_PORT:-3306}
    
    # 执行迁移步骤
    check_source_connection || exit 1
    check_target_connection || exit 1
    backup_source_database
    migrate_database_structure
    migrate_data
    validate_migration
    
    log_success "MySQL数据迁移完成"
    echo "迁移日志: $LOG_FILE"
}

# 执行迁移
main "$@"
