#!/bin/bash
# 本地化数据库备份脚本
# 备份所有通过Homebrew安装的数据库

set -e

# 配置
BACKUP_DIR="/Users/szjason72/genzltd/database-backups/local"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
LOG_FILE="/Users/szjason72/genzltd/logs/backup-local-databases.log"

# 创建备份目录
mkdir -p "$BACKUP_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

# 日志函数
log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS: $1" | tee -a "$LOG_FILE"
}

echo "🗄️  开始备份本地化数据库..."
echo "备份目录: $BACKUP_DIR"
echo "时间戳: $TIMESTAMP"
echo "=================================="

# 1. 备份MySQL数据库
log_info "开始备份MySQL数据库..."
if brew services list | grep -q "mysql.*started"; then
    # MySQL服务运行中
    log_info "MySQL服务运行中，开始备份..."
    
    # 获取所有数据库列表
    DATABASES=$(mysql -u root -e "SHOW DATABASES;" | grep -v -E "(Database|information_schema|performance_schema|mysql|sys)")
    
    for db in $DATABASES; do
        if [ "$db" != "" ]; then
            log_info "备份数据库: $db"
            mysqldump -u root --single-transaction --routines --triggers "$db" > "$BACKUP_DIR/mysql_${db}_${TIMESTAMP}.sql"
            if [ $? -eq 0 ]; then
                log_success "MySQL数据库 $db 备份完成"
            else
                log_error "MySQL数据库 $db 备份失败"
            fi
        fi
    done
else
    log_info "MySQL服务未运行，检查数据目录..."
    # 备份MySQL数据目录
    MYSQL_DATA_DIR="/usr/local/var/mysql"
    if [ -d "$MYSQL_DATA_DIR" ]; then
        log_info "备份MySQL数据目录: $MYSQL_DATA_DIR"
        tar -czf "$BACKUP_DIR/mysql_data_directory_${TIMESTAMP}.tar.gz" -C "$(dirname "$MYSQL_DATA_DIR")" "$(basename "$MYSQL_DATA_DIR")"
        if [ $? -eq 0 ]; then
            log_success "MySQL数据目录备份完成"
        else
            log_error "MySQL数据目录备份失败"
        fi
    else
        log_error "MySQL数据目录不存在: $MYSQL_DATA_DIR"
    fi
fi

# 2. 备份PostgreSQL数据库
log_info "开始备份PostgreSQL数据库..."
if brew services list | grep -q "postgresql.*started"; then
    log_info "PostgreSQL服务运行中，开始备份..."
    
    # 获取所有数据库列表
    DATABASES=$(psql -U $(whoami) -l -t | cut -d'|' -f1 | grep -v -E "(template|postgres)" | tr -d ' ')
    
    for db in $DATABASES; do
        if [ "$db" != "" ]; then
            log_info "备份数据库: $db"
            pg_dump -U $(whoami) "$db" > "$BACKUP_DIR/postgresql_${db}_${TIMESTAMP}.sql"
            if [ $? -eq 0 ]; then
                log_success "PostgreSQL数据库 $db 备份完成"
            else
                log_error "PostgreSQL数据库 $db 备份失败"
            fi
        fi
    done
else
    log_info "PostgreSQL服务未运行，检查数据目录..."
    # 备份PostgreSQL数据目录
    PG_DATA_DIR="/usr/local/var/postgresql@14"
    if [ -d "$PG_DATA_DIR" ]; then
        log_info "备份PostgreSQL数据目录: $PG_DATA_DIR"
        tar -czf "$BACKUP_DIR/postgresql_data_directory_${TIMESTAMP}.tar.gz" -C "$(dirname "$PG_DATA_DIR")" "$(basename "$PG_DATA_DIR")"
        if [ $? -eq 0 ]; then
            log_success "PostgreSQL数据目录备份完成"
        else
            log_error "PostgreSQL数据目录备份失败"
        fi
    else
        log_error "PostgreSQL数据目录不存在: $PG_DATA_DIR"
    fi
fi

# 3. 备份Redis数据
log_info "开始备份Redis数据..."
if brew services list | grep -q "redis.*started"; then
    log_info "Redis服务运行中，开始备份..."
    
    # 创建Redis快照
    redis-cli BGSAVE
    sleep 5  # 等待快照完成
    
    # 查找RDB文件
    RDB_FILE=$(redis-cli CONFIG GET dir | tail -1)/dump.rdb
    if [ -f "$RDB_FILE" ]; then
        cp "$RDB_FILE" "$BACKUP_DIR/redis_dump_${TIMESTAMP}.rdb"
        if [ $? -eq 0 ]; then
            log_success "Redis数据备份完成"
        else
            log_error "Redis数据备份失败"
        fi
    else
        log_error "Redis RDB文件不存在: $RDB_FILE"
    fi
else
    log_info "Redis服务未运行，检查数据目录..."
    # 备份Redis数据目录
    REDIS_DATA_DIR="/usr/local/var/db/redis"
    if [ -d "$REDIS_DATA_DIR" ]; then
        log_info "备份Redis数据目录: $REDIS_DATA_DIR"
        tar -czf "$BACKUP_DIR/redis_data_directory_${TIMESTAMP}.tar.gz" -C "$(dirname "$REDIS_DATA_DIR")" "$(basename "$REDIS_DATA_DIR")"
        if [ $? -eq 0 ]; then
            log_success "Redis数据目录备份完成"
        else
            log_error "Redis数据目录备份失败"
        fi
    else
        log_error "Redis数据目录不存在: $REDIS_DATA_DIR"
    fi
fi

# 4. 备份MongoDB数据
log_info "开始备份MongoDB数据..."
if brew services list | grep -q "mongodb.*started"; then
    log_info "MongoDB服务运行中，开始备份..."
    
    # 获取所有数据库列表
    DATABASES=$(mongo --eval "db.adminCommand('listDatabases').databases.forEach(function(d) { print(d.name) })" --quiet | grep -v -E "(admin|config|local)")
    
    for db in $DATABASES; do
        if [ "$db" != "" ]; then
            log_info "备份数据库: $db"
            mongodump --db "$db" --out "$BACKUP_DIR/mongodb_${db}_${TIMESTAMP}"
            if [ $? -eq 0 ]; then
                log_success "MongoDB数据库 $db 备份完成"
            else
                log_error "MongoDB数据库 $db 备份失败"
            fi
        fi
    done
else
    log_info "MongoDB服务未运行，检查数据目录..."
    # 备份MongoDB数据目录
    MONGO_DATA_DIR="/usr/local/var/mongodb"
    if [ -d "$MONGO_DATA_DIR" ]; then
        log_info "备份MongoDB数据目录: $MONGO_DATA_DIR"
        tar -czf "$BACKUP_DIR/mongodb_data_directory_${TIMESTAMP}.tar.gz" -C "$(dirname "$MONGO_DATA_DIR")" "$(basename "$MONGO_DATA_DIR")"
        if [ $? -eq 0 ]; then
            log_success "MongoDB数据目录备份完成"
        else
            log_error "MongoDB数据目录备份失败"
        fi
    else
        log_error "MongoDB数据目录不存在: $MONGO_DATA_DIR"
    fi
fi

# 5. 备份Neo4j数据
log_info "开始备份Neo4j数据..."
# Neo4j数据目录
NEO4J_DATA_DIR="/usr/local/var/lib/neo4j"
if [ -d "$NEO4J_DATA_DIR" ]; then
    log_info "备份Neo4j数据目录: $NEO4J_DATA_DIR"
    tar -czf "$BACKUP_DIR/neo4j_data_directory_${TIMESTAMP}.tar.gz" -C "$(dirname "$NEO4J_DATA_DIR")" "$(basename "$NEO4J_DATA_DIR")"
    if [ $? -eq 0 ]; then
        log_success "Neo4j数据目录备份完成"
    else
        log_error "Neo4j数据目录备份失败"
    fi
else
    log_error "Neo4j数据目录不存在: $NEO4J_DATA_DIR"
fi

# 生成备份报告
echo ""
echo "📊 备份完成报告"
echo "=================================="
echo "备份目录: $BACKUP_DIR"
echo "备份时间: $(date)"
echo "备份文件:"
ls -la "$BACKUP_DIR" | grep "$TIMESTAMP"
echo "=================================="

log_success "本地化数据库备份完成！"
echo "备份日志: $LOG_FILE"
