#!/bin/bash

# PostgreSQL数据迁移脚本
# 创建时间: 2025年1月27日
# 版本: v1.0

# 获取当前时间戳
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="../../logs/migration/postgresql_migration_$TIMESTAMP.log"

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
    log_info "检查源PostgreSQL连接..."
    
    if nc -z localhost 5432 2>/dev/null; then
        log_success "源PostgreSQL连接正常"
        return 0
    else
        log_warning "源PostgreSQL未运行"
        return 1
    fi
}

# 检查目标数据库连接
check_target_connection() {
    log_info "检查目标PostgreSQL连接..."
    
    TARGET_HOST=${TARGET_POSTGRES_HOST:-localhost}
    TARGET_PORT=${TARGET_POSTGRES_PORT:-5432}
    
    if nc -z $TARGET_HOST $TARGET_PORT 2>/dev/null; then
        log_success "目标PostgreSQL连接正常"
        return 0
    else
        log_warning "目标PostgreSQL连接失败: $TARGET_HOST:$TARGET_PORT"
        return 1
    fi
}

# 备份源数据库
backup_source_database() {
    log_info "开始备份源PostgreSQL数据库..."
    
    BACKUP_FILE="../../backups/source/postgresql_backup_$TIMESTAMP.sql"
    
    # 获取所有数据库列表
    DATABASES=$(psql -l -t | awk '{print $1}' | grep -v -E "(template|postgres)")
    
    for db in $DATABASES; do
        if [ ! -z "$db" ]; then
            log_info "备份数据库: $db"
            pg_dump $db > "${BACKUP_FILE%.sql}_${db}.sql" 2>/dev/null
            
            if [ $? -eq 0 ]; then
                log_success "数据库 $db 备份完成"
            else
                log_warning "数据库 $db 备份失败"
            fi
        fi
    done
    
    log_success "源数据库备份完成: $BACKUP_FILE"
}

# 迁移数据库结构
migrate_database_structure() {
    log_info "开始迁移数据库结构..."
    
    TARGET_DB=${TARGET_POSTGRES_DATABASE:-unified_analysis}
    
    # 创建目标数据库
    createdb -h $TARGET_HOST -p $TARGET_PORT $TARGET_DB 2>/dev/null
    
    if [ $? -eq 0 ]; then
        log_success "目标数据库 $TARGET_DB 创建成功"
    else
        log_warning "目标数据库创建失败"
    fi
}

# 迁移数据
migrate_data() {
    log_info "开始迁移数据..."
    
    BACKUP_FILES=$(ls ../../backups/source/postgresql_backup_*_*.sql 2>/dev/null)
    
    for backup_file in $BACKUP_FILES; do
        if [ -f "$backup_file" ]; then
            log_info "恢复数据: $backup_file"
            psql -h $TARGET_HOST -p $TARGET_PORT $TARGET_DB < "$backup_file" 2>/dev/null
            
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
    SOURCE_TABLES=$(psql -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public';" 2>/dev/null | tail -1)
    TARGET_TABLES=$(psql -h $TARGET_HOST -p $TARGET_PORT -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public';" 2>/dev/null | tail -1)
    
    if [ "$SOURCE_TABLES" = "$TARGET_TABLES" ]; then
        log_success "表数量验证通过: $SOURCE_TABLES 个表"
    else
        log_warning "表数量不匹配: 源=$SOURCE_TABLES, 目标=$TARGET_TABLES"
    fi
    
    log_success "迁移验证完成"
}

# 主函数
main() {
    log_info "开始PostgreSQL数据迁移..."
    
    # 设置环境变量
    SOURCE_DB=${SOURCE_POSTGRES_DATABASE:-postgres}
    TARGET_DB=${TARGET_POSTGRES_DATABASE:-unified_analysis}
    TARGET_HOST=${TARGET_POSTGRES_HOST:-localhost}
    TARGET_PORT=${TARGET_POSTGRES_PORT:-5432}
    
    # 执行迁移步骤
    check_source_connection || exit 1
    check_target_connection || exit 1
    backup_source_database
    migrate_database_structure
    migrate_data
    validate_migration
    
    log_success "PostgreSQL数据迁移完成"
    echo "迁移日志: $LOG_FILE"
}

# 执行迁移
main "$@"
