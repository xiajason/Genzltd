#!/bin/bash
# 容器化数据库备份脚本
# 备份所有Docker容器中的数据库

set -e

# 配置
BACKUP_DIR="/Users/szjason72/genzltd/database-backups/containerized"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
LOG_FILE="/Users/szjason72/genzltd/logs/backup-containerized-databases.log"

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

echo "🐳 开始备份容器化数据库..."
echo "备份目录: $BACKUP_DIR"
echo "时间戳: $TIMESTAMP"
echo "=================================="

# 检查Docker是否运行
if ! docker info >/dev/null 2>&1; then
    log_error "Docker未运行，无法备份容器化数据库"
    exit 1
fi

# 1. 备份MySQL容器 (future-mysql)
log_info "开始备份MySQL容器 (future-mysql)..."
if docker ps | grep -q "future-mysql"; then
    log_info "MySQL容器运行中，开始备份..."
    
    # 获取所有数据库列表
    DATABASES=$(docker exec future-mysql mysql -u root -e "SHOW DATABASES;" | grep -v -E "(Database|information_schema|performance_schema|mysql|sys)")
    
    for db in $DATABASES; do
        if [ "$db" != "" ]; then
            log_info "备份数据库: $db"
            docker exec future-mysql mysqldump -u root --single-transaction --routines --triggers "$db" > "$BACKUP_DIR/mysql_${db}_${TIMESTAMP}.sql"
            if [ $? -eq 0 ]; then
                log_success "MySQL数据库 $db 备份完成"
            else
                log_error "MySQL数据库 $db 备份失败"
            fi
        fi
    done
    
    # 备份MySQL数据目录
    log_info "备份MySQL容器数据目录..."
    docker cp future-mysql:/var/lib/mysql "$BACKUP_DIR/mysql_data_directory_${TIMESTAMP}"
    if [ $? -eq 0 ]; then
        log_success "MySQL容器数据目录备份完成"
    else
        log_error "MySQL容器数据目录备份失败"
    fi
else
    log_error "MySQL容器 (future-mysql) 未运行"
fi

# 2. 备份PostgreSQL容器 (future-postgres)
log_info "开始备份PostgreSQL容器 (future-postgres)..."
if docker ps | grep -q "future-postgres"; then
    log_info "PostgreSQL容器运行中，开始备份..."
    
    # 获取所有数据库列表
    DATABASES=$(docker exec future-postgres psql -U looma_user -l -t | cut -d'|' -f1 | grep -v -E "(template|postgres)" | tr -d ' ')
    
    for db in $DATABASES; do
        if [ "$db" != "" ]; then
            log_info "备份数据库: $db"
            docker exec future-postgres pg_dump -U looma_user "$db" > "$BACKUP_DIR/postgresql_${db}_${TIMESTAMP}.sql"
            if [ $? -eq 0 ]; then
                log_success "PostgreSQL数据库 $db 备份完成"
            else
                log_error "PostgreSQL数据库 $db 备份失败"
            fi
        fi
    done
    
    # 备份PostgreSQL数据目录
    log_info "备份PostgreSQL容器数据目录..."
    docker cp future-postgres:/var/lib/postgresql/data "$BACKUP_DIR/postgresql_data_directory_${TIMESTAMP}"
    if [ $? -eq 0 ]; then
        log_success "PostgreSQL容器数据目录备份完成"
    else
        log_error "PostgreSQL容器数据目录备份失败"
    fi
else
    log_error "PostgreSQL容器 (future-postgres) 未运行"
fi

# 3. 备份Redis容器 (future-redis)
log_info "开始备份Redis容器 (future-redis)..."
if docker ps | grep -q "future-redis"; then
    log_info "Redis容器运行中，开始备份..."
    
    # 创建Redis快照
    docker exec future-redis redis-cli BGSAVE
    sleep 5  # 等待快照完成
    
    # 复制RDB文件
    docker cp future-redis:/data/dump.rdb "$BACKUP_DIR/redis_dump_${TIMESTAMP}.rdb"
    if [ $? -eq 0 ]; then
        log_success "Redis数据备份完成"
    else
        log_error "Redis数据备份失败"
    fi
    
    # 备份Redis数据目录
    log_info "备份Redis容器数据目录..."
    docker cp future-redis:/data "$BACKUP_DIR/redis_data_directory_${TIMESTAMP}"
    if [ $? -eq 0 ]; then
        log_success "Redis容器数据目录备份完成"
    else
        log_error "Redis容器数据目录备份失败"
    fi
else
    log_error "Redis容器 (future-redis) 未运行"
fi

# 4. 备份MongoDB容器 (future-mongodb)
log_info "开始备份MongoDB容器 (future-mongodb)..."
if docker ps | grep -q "future-mongodb"; then
    log_info "MongoDB容器运行中，开始备份..."
    
    # 获取所有数据库列表
    DATABASES=$(docker exec future-mongodb mongo --eval "db.adminCommand('listDatabases').databases.forEach(function(d) { print(d.name) })" --quiet | grep -v -E "(admin|config|local)")
    
    for db in $DATABASES; do
        if [ "$db" != "" ]; then
            log_info "备份数据库: $db"
            docker exec future-mongodb mongodump --db "$db" --out /tmp/backup
            docker cp future-mongodb:/tmp/backup "$BACKUP_DIR/mongodb_${db}_${TIMESTAMP}"
            if [ $? -eq 0 ]; then
                log_success "MongoDB数据库 $db 备份完成"
            else
                log_error "MongoDB数据库 $db 备份失败"
            fi
        fi
    done
    
    # 备份MongoDB数据目录
    log_info "备份MongoDB容器数据目录..."
    docker cp future-mongodb:/data/db "$BACKUP_DIR/mongodb_data_directory_${TIMESTAMP}"
    if [ $? -eq 0 ]; then
        log_success "MongoDB容器数据目录备份完成"
    else
        log_error "MongoDB容器数据目录备份失败"
    fi
else
    log_error "MongoDB容器 (future-mongodb) 未运行"
fi

# 5. 备份Neo4j容器 (future-neo4j)
log_info "开始备份Neo4j容器 (future-neo4j)..."
if docker ps | grep -q "future-neo4j"; then
    log_info "Neo4j容器运行中，开始备份..."
    
    # 备份Neo4j数据目录
    log_info "备份Neo4j容器数据目录..."
    docker cp future-neo4j:/data "$BACKUP_DIR/neo4j_data_directory_${TIMESTAMP}"
    if [ $? -eq 0 ]; then
        log_success "Neo4j容器数据目录备份完成"
    else
        log_error "Neo4j容器数据目录备份失败"
    fi
    
    # 备份Neo4j数据库
    log_info "备份Neo4j数据库..."
    docker exec future-neo4j neo4j-admin dump --database=neo4j --to=/tmp/neo4j_backup.dump
    docker cp future-neo4j:/tmp/neo4j_backup.dump "$BACKUP_DIR/neo4j_database_${TIMESTAMP}.dump"
    if [ $? -eq 0 ]; then
        log_success "Neo4j数据库备份完成"
    else
        log_error "Neo4j数据库备份失败"
    fi
else
    log_error "Neo4j容器 (future-neo4j) 未运行"
fi

# 6. 备份Elasticsearch容器 (future-elasticsearch)
log_info "开始备份Elasticsearch容器 (future-elasticsearch)..."
if docker ps | grep -q "future-elasticsearch"; then
    log_info "Elasticsearch容器运行中，开始备份..."
    
    # 备份Elasticsearch数据目录
    log_info "备份Elasticsearch容器数据目录..."
    docker cp future-elasticsearch:/usr/share/elasticsearch/data "$BACKUP_DIR/elasticsearch_data_directory_${TIMESTAMP}"
    if [ $? -eq 0 ]; then
        log_success "Elasticsearch容器数据目录备份完成"
    else
        log_error "Elasticsearch容器数据目录备份失败"
    fi
    
    # 备份Elasticsearch索引
    log_info "备份Elasticsearch索引..."
    docker exec future-elasticsearch curl -X GET "localhost:9200/_cat/indices?v" > "$BACKUP_DIR/elasticsearch_indices_${TIMESTAMP}.txt"
    if [ $? -eq 0 ]; then
        log_success "Elasticsearch索引列表备份完成"
    else
        log_error "Elasticsearch索引列表备份失败"
    fi
else
    log_error "Elasticsearch容器 (future-elasticsearch) 未运行"
fi

# 7. 备份Weaviate容器 (future-weaviate)
log_info "开始备份Weaviate容器 (future-weaviate)..."
if docker ps | grep -q "future-weaviate"; then
    log_info "Weaviate容器运行中，开始备份..."
    
    # 备份Weaviate数据目录
    log_info "备份Weaviate容器数据目录..."
    docker cp future-weaviate:/var/lib/weaviate "$BACKUP_DIR/weaviate_data_directory_${TIMESTAMP}"
    if [ $? -eq 0 ]; then
        log_success "Weaviate容器数据目录备份完成"
    else
        log_error "Weaviate容器数据目录备份失败"
    fi
    
    # 备份Weaviate模式
    log_info "备份Weaviate模式..."
    docker exec future-weaviate curl -X GET "http://localhost:8080/v1/schema" > "$BACKUP_DIR/weaviate_schema_${TIMESTAMP}.json"
    if [ $? -eq 0 ]; then
        log_success "Weaviate模式备份完成"
    else
        log_error "Weaviate模式备份失败"
    fi
else
    log_error "Weaviate容器 (future-weaviate) 未运行"
fi

# 8. 备份Docker卷
log_info "开始备份Docker卷..."
VOLUMES=$(docker volume ls --format "{{.Name}}" | grep -E "(future|looma|zervigo)")
for volume in $VOLUMES; do
    log_info "备份Docker卷: $volume"
    docker run --rm -v "$volume":/source -v "$BACKUP_DIR":/backup alpine tar czf "/backup/docker_volume_${volume}_${TIMESTAMP}.tar.gz" -C /source .
    if [ $? -eq 0 ]; then
        log_success "Docker卷 $volume 备份完成"
    else
        log_error "Docker卷 $volume 备份失败"
    fi
done

# 生成备份报告
echo ""
echo "📊 容器化数据库备份完成报告"
echo "=================================="
echo "备份目录: $BACKUP_DIR"
echo "备份时间: $(date)"
echo "备份文件:"
ls -la "$BACKUP_DIR" | grep "$TIMESTAMP"
echo "=================================="

log_success "容器化数据库备份完成！"
echo "备份日志: $LOG_FILE"
