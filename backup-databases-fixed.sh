#!/bin/bash
# 修复后的数据库备份脚本
# 解决密码认证、路径和工具问题

set -e

# 配置
BACKUP_DIR="/Users/szjason72/genzltd/database-backups/fixed"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
LOG_FILE="/Users/szjason72/genzltd/logs/backup-databases-fixed.log"

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

echo "🗄️  开始修复后的数据库备份..."
echo "备份目录: $BACKUP_DIR"
echo "时间戳: $TIMESTAMP"
echo "=================================="

# 1. 备份本地化数据库（修复路径问题）
log_info "开始备份本地化数据库..."

# 备份PostgreSQL（已成功，保持原样）
log_info "备份PostgreSQL数据库..."
if brew services list | grep -q "postgresql.*started"; then
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
fi

# 备份Redis（已成功，保持原样）
log_info "备份Redis数据..."
if brew services list | grep -q "redis.*started"; then
    redis-cli BGSAVE
    sleep 5
    RDB_FILE=$(redis-cli CONFIG GET dir | tail -1)/dump.rdb
    if [ -f "$RDB_FILE" ]; then
        cp "$RDB_FILE" "$BACKUP_DIR/redis_dump_${TIMESTAMP}.rdb"
        log_success "Redis数据备份完成"
    fi
fi

# 备份MongoDB（修复工具问题）
log_info "备份MongoDB数据..."
if brew services list | grep -q "mongodb.*started"; then
    # 使用mongosh替代mongo
    DATABASES=$(mongosh --eval "db.adminCommand('listDatabases').databases.forEach(function(d) { print(d.name) })" --quiet | grep -v -E "(admin|config|local)")
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
fi

# 备份MySQL（修复路径问题）
log_info "备份MySQL数据..."
MYSQL_DATA_DIR="/opt/homebrew/var/mysql"
if [ -d "$MYSQL_DATA_DIR" ]; then
    log_info "备份MySQL数据目录: $MYSQL_DATA_DIR"
    tar -czf "$BACKUP_DIR/mysql_data_directory_${TIMESTAMP}.tar.gz" -C "$(dirname "$MYSQL_DATA_DIR")" "$(basename "$MYSQL_DATA_DIR")"
    if [ $? -eq 0 ]; then
        log_success "MySQL数据目录备份完成"
    else
        log_error "MySQL数据目录备份失败"
    fi
fi

# 备份Neo4j（修复路径问题）
log_info "备份Neo4j数据..."
NEO4J_DATA_DIR="/opt/homebrew/var/neo4j"
if [ -d "$NEO4J_DATA_DIR" ]; then
    log_info "备份Neo4j数据目录: $NEO4J_DATA_DIR"
    tar -czf "$BACKUP_DIR/neo4j_data_directory_${TIMESTAMP}.tar.gz" -C "$(dirname "$NEO4J_DATA_DIR")" "$(basename "$NEO4J_DATA_DIR")"
    if [ $? -eq 0 ]; then
        log_success "Neo4j数据目录备份完成"
    else
        log_error "Neo4j数据目录备份失败"
    fi
fi

# 2. 备份容器化数据库（修复密码问题）
log_info "开始备份容器化数据库..."

# 备份MySQL容器（修复密码问题）
log_info "备份MySQL容器 (future-mysql)..."
if docker ps | grep -q "future-mysql"; then
    log_info "MySQL容器运行中，开始备份..."
    
    # 使用正确的密码
    DATABASES=$(docker exec future-mysql mysql -u root -pmysql_root_2025 -e "SHOW DATABASES;" | grep -v -E "(Database|information_schema|performance_schema|mysql|sys)")
    
    for db in $DATABASES; do
        if [ "$db" != "" ]; then
            log_info "备份数据库: $db"
            docker exec future-mysql mysqldump -u root -pmysql_root_2025 --single-transaction --routines --triggers "$db" > "$BACKUP_DIR/mysql_container_${db}_${TIMESTAMP}.sql"
            if [ $? -eq 0 ]; then
                log_success "MySQL容器数据库 $db 备份完成"
            else
                log_error "MySQL容器数据库 $db 备份失败"
            fi
        fi
    done
    
    # 备份MySQL容器数据目录
    log_info "备份MySQL容器数据目录..."
    docker cp future-mysql:/var/lib/mysql "$BACKUP_DIR/mysql_container_data_${TIMESTAMP}"
    if [ $? -eq 0 ]; then
        log_success "MySQL容器数据目录备份完成"
    else
        log_error "MySQL容器数据目录备份失败"
    fi
fi

# 备份PostgreSQL容器
log_info "备份PostgreSQL容器 (future-postgres)..."
if docker ps | grep -q "future-postgres"; then
    log_info "PostgreSQL容器运行中，开始备份..."
    
    DATABASES=$(docker exec future-postgres psql -U jobfirst_future -l -t | cut -d'|' -f1 | grep -v -E "(template|postgres)" | tr -d ' ')
    
    for db in $DATABASES; do
        if [ "$db" != "" ]; then
            log_info "备份数据库: $db"
            docker exec future-postgres pg_dump -U jobfirst_future "$db" > "$BACKUP_DIR/postgresql_container_${db}_${TIMESTAMP}.sql"
            if [ $? -eq 0 ]; then
                log_success "PostgreSQL容器数据库 $db 备份完成"
            else
                log_error "PostgreSQL容器数据库 $db 备份失败"
            fi
        fi
    done
    
    # 备份PostgreSQL容器数据目录
    log_info "备份PostgreSQL容器数据目录..."
    docker cp future-postgres:/var/lib/postgresql/data "$BACKUP_DIR/postgresql_container_data_${TIMESTAMP}"
    if [ $? -eq 0 ]; then
        log_success "PostgreSQL容器数据目录备份完成"
    else
        log_error "PostgreSQL容器数据目录备份失败"
    fi
fi

# 备份Redis容器
log_info "备份Redis容器 (future-redis)..."
if docker ps | grep -q "future-redis"; then
    log_info "Redis容器运行中，开始备份..."
    
    # 创建Redis快照
    docker exec future-redis redis-cli -a future_redis_password_2025 BGSAVE
    sleep 5
    
    # 复制RDB文件
    docker cp future-redis:/data/dump.rdb "$BACKUP_DIR/redis_container_dump_${TIMESTAMP}.rdb"
    if [ $? -eq 0 ]; then
        log_success "Redis容器数据备份完成"
    else
        log_error "Redis容器数据备份失败"
    fi
    
    # 备份Redis容器数据目录
    docker cp future-redis:/data "$BACKUP_DIR/redis_container_data_${TIMESTAMP}"
    if [ $? -eq 0 ]; then
        log_success "Redis容器数据目录备份完成"
    else
        log_error "Redis容器数据目录备份失败"
    fi
fi

# 备份MongoDB容器
log_info "备份MongoDB容器 (future-mongodb)..."
if docker ps | grep -q "future-mongodb"; then
    log_info "MongoDB容器运行中，开始备份..."
    
    DATABASES=$(docker exec future-mongodb mongosh -u jobfirst_future -p secure_future_password_2025 --authenticationDatabase admin --eval "db.adminCommand('listDatabases').databases.forEach(function(d) { print(d.name) })" --quiet | grep -v -E "(admin|config|local)")
    
    for db in $DATABASES; do
        if [ "$db" != "" ]; then
            log_info "备份数据库: $db"
            docker exec future-mongodb mongodump -u jobfirst_future -p secure_future_password_2025 --authenticationDatabase admin --db "$db" --out /tmp/backup
            docker cp future-mongodb:/tmp/backup "$BACKUP_DIR/mongodb_container_${db}_${TIMESTAMP}"
            if [ $? -eq 0 ]; then
                log_success "MongoDB容器数据库 $db 备份完成"
            else
                log_error "MongoDB容器数据库 $db 备份失败"
            fi
        fi
    done
    
    # 备份MongoDB容器数据目录
    docker cp future-mongodb:/data/db "$BACKUP_DIR/mongodb_container_data_${TIMESTAMP}"
    if [ $? -eq 0 ]; then
        log_success "MongoDB容器数据目录备份完成"
    else
        log_error "MongoDB容器数据目录备份失败"
    fi
fi

# 备份Neo4j容器
log_info "备份Neo4j容器 (future-neo4j)..."
if docker ps | grep -q "future-neo4j"; then
    log_info "Neo4j容器运行中，开始备份..."
    
    # 备份Neo4j数据目录
    docker cp future-neo4j:/data "$BACKUP_DIR/neo4j_container_data_${TIMESTAMP}"
    if [ $? -eq 0 ]; then
        log_success "Neo4j容器数据目录备份完成"
    else
        log_error "Neo4j容器数据目录备份失败"
    fi
    
    # 备份Neo4j数据库
    docker exec future-neo4j neo4j-admin dump --database=neo4j --to=/tmp/neo4j_backup.dump
    docker cp future-neo4j:/tmp/neo4j_backup.dump "$BACKUP_DIR/neo4j_container_database_${TIMESTAMP}.dump"
    if [ $? -eq 0 ]; then
        log_success "Neo4j容器数据库备份完成"
    else
        log_error "Neo4j容器数据库备份失败"
    fi
fi

# 备份Elasticsearch容器
log_info "备份Elasticsearch容器 (future-elasticsearch)..."
if docker ps | grep -q "future-elasticsearch"; then
    log_info "Elasticsearch容器运行中，开始备份..."
    
    # 备份Elasticsearch数据目录
    docker cp future-elasticsearch:/usr/share/elasticsearch/data "$BACKUP_DIR/elasticsearch_container_data_${TIMESTAMP}"
    if [ $? -eq 0 ]; then
        log_success "Elasticsearch容器数据目录备份完成"
    else
        log_error "Elasticsearch容器数据目录备份失败"
    fi
    
    # 备份Elasticsearch索引
    docker exec future-elasticsearch curl -X GET "localhost:9200/_cat/indices?v" > "$BACKUP_DIR/elasticsearch_container_indices_${TIMESTAMP}.txt"
    if [ $? -eq 0 ]; then
        log_success "Elasticsearch容器索引列表备份完成"
    else
        log_error "Elasticsearch容器索引列表备份失败"
    fi
fi

# 备份Weaviate容器
log_info "备份Weaviate容器 (future-weaviate)..."
if docker ps | grep -q "future-weaviate"; then
    log_info "Weaviate容器运行中，开始备份..."
    
    # 备份Weaviate数据目录
    docker cp future-weaviate:/var/lib/weaviate "$BACKUP_DIR/weaviate_container_data_${TIMESTAMP}"
    if [ $? -eq 0 ]; then
        log_success "Weaviate容器数据目录备份完成"
    else
        log_error "Weaviate容器数据目录备份失败"
    fi
    
    # 备份Weaviate模式
    docker exec future-weaviate curl -X GET "http://localhost:8080/v1/schema" > "$BACKUP_DIR/weaviate_container_schema_${TIMESTAMP}.json"
    if [ $? -eq 0 ]; then
        log_success "Weaviate容器模式备份完成"
    else
        log_error "Weaviate容器模式备份失败"
    fi
fi

# 生成备份报告
echo ""
echo "📊 修复后的数据库备份完成报告"
echo "=================================="
echo "备份目录: $BACKUP_DIR"
echo "备份时间: $(date)"
echo "备份文件:"
ls -la "$BACKUP_DIR" | grep "$TIMESTAMP"
echo "=================================="

log_success "修复后的数据库备份完成！"
echo "备份日志: $LOG_FILE"
