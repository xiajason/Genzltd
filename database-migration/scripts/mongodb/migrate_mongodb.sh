#!/bin/bash

# MongoDB数据迁移脚本
# 创建时间: 2025年1月27日
# 版本: v1.0

# 获取当前时间戳
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="../../logs/migration/mongodb_migration_$TIMESTAMP.log"

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

# 检查源MongoDB连接
check_source_connection() {
    log_info "检查源MongoDB连接..."
    
    if nc -z localhost 27017 2>/dev/null; then
        log_success "源MongoDB连接正常"
        return 0
    else
        log_warning "源MongoDB未运行"
        return 1
    fi
}

# 检查目标MongoDB连接
check_target_connection() {
    log_info "检查目标MongoDB连接..."
    
    TARGET_HOST=${TARGET_MONGODB_HOST:-localhost}
    TARGET_PORT=${TARGET_MONGODB_PORT:-27017}
    
    if nc -z $TARGET_HOST $TARGET_PORT 2>/dev/null; then
        log_success "目标MongoDB连接正常"
        return 0
    else
        log_warning "目标MongoDB连接失败: $TARGET_HOST:$TARGET_PORT"
        return 1
    fi
}

# 备份源MongoDB数据
backup_source_mongodb() {
    log_info "开始备份源MongoDB数据..."
    
    BACKUP_DIR="../../backups/source/mongodb_backup_$TIMESTAMP"
    mkdir -p "$BACKUP_DIR"
    
    # 获取所有数据库列表
    DATABASES=$(mongo --quiet --eval "db.adminCommand('listDatabases').databases.forEach(function(d) { print(d.name); })" 2>/dev/null | grep -v -E "(admin|local|config)")
    
    for db in $DATABASES; do
        if [ ! -z "$db" ]; then
            log_info "备份数据库: $db"
            mongodump --db $db --out "$BACKUP_DIR" 2>/dev/null
            
            if [ $? -eq 0 ]; then
                log_success "数据库 $db 备份完成"
            else
                log_warning "数据库 $db 备份失败"
            fi
        fi
    done
    
    log_success "源MongoDB数据备份完成: $BACKUP_DIR"
}

# 迁移MongoDB数据
migrate_mongodb_data() {
    log_info "开始迁移MongoDB数据..."
    
    TARGET_HOST=${TARGET_MONGODB_HOST:-localhost}
    TARGET_PORT=${TARGET_MONGODB_PORT:-27017}
    BACKUP_DIR="../../backups/source/mongodb_backup_$TIMESTAMP"
    
    # 恢复数据到目标MongoDB
    mongorestore --host $TARGET_HOST:$TARGET_PORT "$BACKUP_DIR" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        log_success "MongoDB数据迁移完成"
    else
        log_warning "MongoDB数据迁移失败"
    fi
}

# 验证迁移结果
validate_migration() {
    log_info "开始验证迁移结果..."
    
    TARGET_HOST=${TARGET_MONGODB_HOST:-localhost}
    TARGET_PORT=${TARGET_MONGODB_PORT:-27017}
    
    # 比较数据库数量
    SOURCE_DBS=$(mongo --quiet --eval "db.adminCommand('listDatabases').databases.length" 2>/dev/null)
    TARGET_DBS=$(mongo --host $TARGET_HOST:$TARGET_PORT --quiet --eval "db.adminCommand('listDatabases').databases.length" 2>/dev/null)
    
    if [ "$SOURCE_DBS" = "$TARGET_DBS" ]; then
        log_success "数据库数量验证通过: $SOURCE_DBS 个数据库"
    else
        log_warning "数据库数量不匹配: 源=$SOURCE_DBS, 目标=$TARGET_DBS"
    fi
    
    log_success "迁移验证完成"
}

# 主函数
main() {
    log_info "开始MongoDB数据迁移..."
    
    # 设置环境变量
    TARGET_HOST=${TARGET_MONGODB_HOST:-localhost}
    TARGET_PORT=${TARGET_MONGODB_PORT:-27017}
    
    # 执行迁移步骤
    check_source_connection || exit 1
    check_target_connection || exit 1
    backup_source_mongodb
    migrate_mongodb_data
    validate_migration
    
    log_success "MongoDB数据迁移完成"
    echo "迁移日志: $LOG_FILE"
}

# 执行迁移
main "$@"
