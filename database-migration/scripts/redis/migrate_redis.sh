#!/bin/bash

# Redis数据迁移脚本
# 创建时间: 2025年1月27日
# 版本: v1.0

# 获取当前时间戳
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="../../logs/migration/redis_migration_$TIMESTAMP.log"

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

# 检查源Redis连接
check_source_connection() {
    log_info "检查源Redis连接..."
    
    if nc -z localhost 6379 2>/dev/null; then
        log_success "源Redis连接正常"
        return 0
    else
        log_warning "源Redis未运行"
        return 1
    fi
}

# 检查目标Redis连接
check_target_connection() {
    log_info "检查目标Redis连接..."
    
    TARGET_HOST=${TARGET_REDIS_HOST:-localhost}
    TARGET_PORT=${TARGET_REDIS_PORT:-6379}
    
    if nc -z $TARGET_HOST $TARGET_PORT 2>/dev/null; then
        log_success "目标Redis连接正常"
        return 0
    else
        log_warning "目标Redis连接失败: $TARGET_HOST:$TARGET_PORT"
        return 1
    fi
}

# 备份源Redis数据
backup_source_redis() {
    log_info "开始备份源Redis数据..."
    
    BACKUP_FILE="../../backups/source/redis_backup_$TIMESTAMP.rdb"
    
    # 创建RDB快照
    redis-cli BGSAVE 2>/dev/null
    
    # 等待备份完成
    while [ "$(redis-cli LASTSAVE)" = "$(redis-cli LASTSAVE)" ]; do
        sleep 1
    done
    
    # 复制RDB文件
    cp /usr/local/var/db/redis/dump.rdb "$BACKUP_FILE" 2>/dev/null || \
    cp /var/lib/redis/dump.rdb "$BACKUP_FILE" 2>/dev/null || \
    cp ~/dump.rdb "$BACKUP_FILE" 2>/dev/null
    
    if [ -f "$BACKUP_FILE" ]; then
        log_success "Redis数据备份完成: $BACKUP_FILE"
    else
        log_warning "Redis数据备份失败"
    fi
}

# 迁移Redis数据
migrate_redis_data() {
    log_info "开始迁移Redis数据..."
    
    TARGET_HOST=${TARGET_REDIS_HOST:-localhost}
    TARGET_PORT=${TARGET_REDIS_PORT:-6379}
    
    # 使用Redis复制功能
    redis-cli --rdb - | redis-cli -h $TARGET_HOST -p $TARGET_PORT --pipe 2>/dev/null
    
    if [ $? -eq 0 ]; then
        log_success "Redis数据迁移完成"
    else
        log_warning "Redis数据迁移失败"
    fi
}

# 验证迁移结果
validate_migration() {
    log_info "开始验证迁移结果..."
    
    TARGET_HOST=${TARGET_REDIS_HOST:-localhost}
    TARGET_PORT=${TARGET_REDIS_PORT:-6379}
    
    # 比较键数量
    SOURCE_KEYS=$(redis-cli DBSIZE 2>/dev/null)
    TARGET_KEYS=$(redis-cli -h $TARGET_HOST -p $TARGET_PORT DBSIZE 2>/dev/null)
    
    if [ "$SOURCE_KEYS" = "$TARGET_KEYS" ]; then
        log_success "键数量验证通过: $SOURCE_KEYS 个键"
    else
        log_warning "键数量不匹配: 源=$SOURCE_KEYS, 目标=$TARGET_KEYS"
    fi
    
    log_success "迁移验证完成"
}

# 主函数
main() {
    log_info "开始Redis数据迁移..."
    
    # 设置环境变量
    TARGET_HOST=${TARGET_REDIS_HOST:-localhost}
    TARGET_PORT=${TARGET_REDIS_PORT:-6379}
    
    # 执行迁移步骤
    check_source_connection || exit 1
    check_target_connection || exit 1
    backup_source_redis
    migrate_redis_data
    validate_migration
    
    log_success "Redis数据迁移完成"
    echo "迁移日志: $LOG_FILE"
}

# 执行迁移
main "$@"
