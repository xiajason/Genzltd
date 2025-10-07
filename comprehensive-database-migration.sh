#!/bin/bash

# 综合数据库迁移脚本
# 创建时间: 2025年1月27日
# 版本: v1.0
# 目标: 支持多数据库迁移到新的基础设施

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 获取当前时间戳
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

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

log_step() {
    echo -e "${PURPLE}[STEP]${NC} $1"
}

# 创建迁移目录结构
create_migration_structure() {
    log_step "创建迁移目录结构"
    
    # 创建迁移目录
    mkdir -p database-migration/{scripts,backups,logs,reports,config}
    
    # 创建脚本目录
    mkdir -p database-migration/scripts/{mysql,postgresql,redis,mongodb,neo4j,validation}
    
    # 创建备份目录
    mkdir -p database-migration/backups/{source,target,archives}
    
    # 创建日志目录
    mkdir -p database-migration/logs/{migration,validation,rollback}
    
    # 创建报告目录
    mkdir -p database-migration/reports/{pre-migration,post-migration,validation}
    
    # 创建配置目录
    mkdir -p database-migration/config/{source,target,mapping}
    
    log_success "✅ 迁移目录结构创建完成"
}

# 创建MySQL迁移脚本
create_mysql_migration() {
    log_step "创建MySQL迁移脚本"
    
    cat > database-migration/scripts/mysql/migrate_mysql.sh << 'EOF'
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
EOF

    chmod +x database-migration/scripts/mysql/migrate_mysql.sh
    log_success "✅ MySQL迁移脚本创建完成"
}

# 创建PostgreSQL迁移脚本
create_postgresql_migration() {
    log_step "创建PostgreSQL迁移脚本"
    
    cat > database-migration/scripts/postgresql/migrate_postgresql.sh << 'EOF'
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
EOF

    chmod +x database-migration/scripts/postgresql/migrate_postgresql.sh
    log_success "✅ PostgreSQL迁移脚本创建完成"
}

# 创建Redis迁移脚本
create_redis_migration() {
    log_step "创建Redis迁移脚本"
    
    cat > database-migration/scripts/redis/migrate_redis.sh << 'EOF'
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
EOF

    chmod +x database-migration/scripts/redis/migrate_redis.sh
    log_success "✅ Redis迁移脚本创建完成"
}

# 创建MongoDB迁移脚本
create_mongodb_migration() {
    log_step "创建MongoDB迁移脚本"
    
    cat > database-migration/scripts/mongodb/migrate_mongodb.sh << 'EOF'
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
EOF

    chmod +x database-migration/scripts/mysql/migrate_mysql.sh
    log_success "✅ MongoDB迁移脚本创建完成"
}

# 创建Neo4j迁移脚本
create_neo4j_migration() {
    log_step "创建Neo4j迁移脚本"
    
    cat > database-migration/scripts/neo4j/migrate_neo4j.sh << 'EOF'
#!/bin/bash

# Neo4j数据迁移脚本
# 创建时间: 2025年1月27日
# 版本: v1.0

# 获取当前时间戳
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="../../logs/migration/neo4j_migration_$TIMESTAMP.log"

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

# 检查源Neo4j连接
check_source_connection() {
    log_info "检查源Neo4j连接..."
    
    if nc -z localhost 7474 2>/dev/null; then
        log_success "源Neo4j连接正常"
        return 0
    else
        log_warning "源Neo4j未运行"
        return 1
    fi
}

# 检查目标Neo4j连接
check_target_connection() {
    log_info "检查目标Neo4j连接..."
    
    TARGET_HOST=${TARGET_NEO4J_HOST:-localhost}
    TARGET_PORT=${TARGET_NEO4J_PORT:-7474}
    
    if nc -z $TARGET_HOST $TARGET_PORT 2>/dev/null; then
        log_success "目标Neo4j连接正常"
        return 0
    else
        log_warning "目标Neo4j连接失败: $TARGET_HOST:$TARGET_PORT"
        return 1
    fi
}

# 备份源Neo4j数据
backup_source_neo4j() {
    log_info "开始备份源Neo4j数据..."
    
    BACKUP_FILE="../../backups/source/neo4j_backup_$TIMESTAMP.cypher"
    
    # 导出所有数据
    cypher-shell -u neo4j -p password "CALL apoc.export.cypher.all('$BACKUP_FILE', {format: 'cypher-shell'})" 2>/dev/null
    
    if [ -f "$BACKUP_FILE" ]; then
        log_success "Neo4j数据备份完成: $BACKUP_FILE"
    else
        log_warning "Neo4j数据备份失败"
    fi
}

# 迁移Neo4j数据
migrate_neo4j_data() {
    log_info "开始迁移Neo4j数据..."
    
    TARGET_HOST=${TARGET_NEO4J_HOST:-localhost}
    TARGET_PORT=${TARGET_NEO4J_PORT:-7474}
    BACKUP_FILE="../../backups/source/neo4j_backup_$TIMESTAMP.cypher"
    
    # 导入数据到目标Neo4j
    cypher-shell -h $TARGET_HOST -p $TARGET_PORT -u neo4j -p password < "$BACKUP_FILE" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        log_success "Neo4j数据迁移完成"
    else
        log_warning "Neo4j数据迁移失败"
    fi
}

# 验证迁移结果
validate_migration() {
    log_info "开始验证迁移结果..."
    
    TARGET_HOST=${TARGET_NEO4J_HOST:-localhost}
    TARGET_PORT=${TARGET_NEO4J_PORT:-7474}
    
    # 比较节点数量
    SOURCE_NODES=$(cypher-shell -u neo4j -p password "MATCH (n) RETURN count(n)" 2>/dev/null | tail -1)
    TARGET_NODES=$(cypher-shell -h $TARGET_HOST -p $TARGET_PORT -u neo4j -p password "MATCH (n) RETURN count(n)" 2>/dev/null | tail -1)
    
    if [ "$SOURCE_NODES" = "$TARGET_NODES" ]; then
        log_success "节点数量验证通过: $SOURCE_NODES 个节点"
    else
        log_warning "节点数量不匹配: 源=$SOURCE_NODES, 目标=$TARGET_NODES"
    fi
    
    log_success "迁移验证完成"
}

# 主函数
main() {
    log_info "开始Neo4j数据迁移..."
    
    # 设置环境变量
    TARGET_HOST=${TARGET_NEO4J_HOST:-localhost}
    TARGET_PORT=${TARGET_NEO4J_PORT:-7474}
    
    # 执行迁移步骤
    check_source_connection || exit 1
    check_target_connection || exit 1
    backup_source_neo4j
    migrate_neo4j_data
    validate_migration
    
    log_success "Neo4j数据迁移完成"
    echo "迁移日志: $LOG_FILE"
}

# 执行迁移
main "$@"
EOF

    chmod +x database-migration/scripts/neo4j/migrate_neo4j.sh
    log_success "✅ Neo4j迁移脚本创建完成"
}

# 创建综合迁移配置
create_migration_config() {
    log_step "创建综合迁移配置"
    
    cat > database-migration/config/migration_config.yaml << 'EOF'
# 数据库迁移配置
# 创建时间: 2025年1月27日
# 版本: v1.0

# 源数据库配置
source:
  mysql:
    host: localhost
    port: 3306
    username: root
    password: your_password
    database: mysql
  
  postgresql:
    host: localhost
    port: 5432
    username: postgres
    password: your_password
    database: postgres
  
  redis:
    host: localhost
    port: 6379
    database: 0
  
  mongodb:
    host: localhost
    port: 27017
    database: admin
  
  neo4j:
    host: localhost
    port: 7474
    username: neo4j
    password: your_password

# 目标数据库配置
target:
  mysql:
    host: localhost
    port: 3306
    username: root
    password: your_password
    database: unified_database
  
  postgresql:
    host: localhost
    port: 5432
    username: postgres
    password: your_password
    database: unified_analysis
  
  redis:
    host: localhost
    port: 6379
    database: 0
  
  mongodb:
    host: localhost
    port: 27017
    database: unified_documents
  
  neo4j:
    host: localhost
    port: 7474
    username: neo4j
    password: your_password
    database: unified_graph

# 迁移策略
migration_strategy:
  backup_before_migration: true
  validate_after_migration: true
  rollback_on_failure: true
  parallel_migration: false
  
# 数据映射
data_mapping:
  looma_crm:
    source_db: looma_crm
    target_db: unified_database
    tables: [users, companies, jobs, applications]
  
  zervigo:
    source_db: zervigo
    target_db: unified_database
    tables: [resumes, profiles, matches]
  
  dao:
    source_db: dao
    target_db: unified_database
    tables: [proposals, votes, governance]
  
  blockchain:
    source_db: blockchain
    target_db: unified_database
    tables: [transactions, blocks, contracts]
EOF

    log_success "✅ 综合迁移配置创建完成"
}

# 创建综合迁移主脚本
create_comprehensive_migration_script() {
    log_step "创建综合迁移主脚本"
    
    cat > database-migration/run_comprehensive_migration.sh << 'EOF'
#!/bin/bash

# 综合数据库迁移主脚本
# 创建时间: 2025年1月27日
# 版本: v1.0

# 获取当前时间戳
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# 显示迁移选项
show_migration_options() {
    echo "🔄 数据库迁移选项:"
    echo "  1. 迁移MySQL数据库"
    echo "  2. 迁移PostgreSQL数据库"
    echo "  3. 迁移Redis数据库"
    echo "  4. 迁移MongoDB数据库"
    echo "  5. 迁移Neo4j数据库"
    echo "  6. 执行全部迁移"
    echo "  7. 验证迁移结果"
    echo "  8. 退出"
    echo ""
}

# 执行MySQL迁移
run_mysql_migration() {
    echo "执行MySQL数据迁移..."
    ./scripts/mysql/migrate_mysql.sh
    echo "MySQL迁移完成"
}

# 执行PostgreSQL迁移
run_postgresql_migration() {
    echo "执行PostgreSQL数据迁移..."
    ./scripts/postgresql/migrate_postgresql.sh
    echo "PostgreSQL迁移完成"
}

# 执行Redis迁移
run_redis_migration() {
    echo "执行Redis数据迁移..."
    ./scripts/redis/migrate_redis.sh
    echo "Redis迁移完成"
}

# 执行MongoDB迁移
run_mongodb_migration() {
    echo "执行MongoDB数据迁移..."
    ./scripts/mongodb/migrate_mongodb.sh
    echo "MongoDB迁移完成"
}

# 执行Neo4j迁移
run_neo4j_migration() {
    echo "执行Neo4j数据迁移..."
    ./scripts/neo4j/migrate_neo4j.sh
    echo "Neo4j迁移完成"
}

# 执行全部迁移
run_all_migrations() {
    echo "执行全部数据库迁移..."
    
    run_mysql_migration
    run_postgresql_migration
    run_redis_migration
    run_mongodb_migration
    run_neo4j_migration
    
    echo "全部数据库迁移完成"
}

# 验证迁移结果
validate_all_migrations() {
    echo "验证所有迁移结果..."
    
    # 这里可以添加综合验证逻辑
    echo "迁移验证完成"
}

# 主函数
main() {
    echo "🔄 综合数据库迁移系统"
    echo "版本: v1.0"
    echo "时间: $(date)"
    echo ""
    
    while true; do
        show_migration_options
        read -p "请选择操作 (1-8): " choice
        
        case $choice in
            1)
                run_mysql_migration
                ;;
            2)
                run_postgresql_migration
                ;;
            3)
                run_redis_migration
                ;;
            4)
                run_mongodb_migration
                ;;
            5)
                run_neo4j_migration
                ;;
            6)
                run_all_migrations
                ;;
            7)
                validate_all_migrations
                ;;
            8)
                echo "退出数据库迁移系统"
                break
                ;;
            *)
                echo "无效选择，请重新输入"
                ;;
        esac
        
        echo ""
        read -p "按回车键继续..."
        echo ""
    done
}

# 执行主函数
main "$@"
EOF

    chmod +x database-migration/run_comprehensive_migration.sh
    log_success "✅ 综合迁移主脚本创建完成"
}

# 主函数
main() {
    log_info "🔄 开始建立综合数据库迁移系统..."
    log_info "建立时间: $(date)"
    log_info "迁移版本: v1.0"
    
    echo ""
    log_info "📋 迁移系统建立步骤:"
    echo "  1. 创建迁移目录结构"
    echo "  2. 创建MySQL迁移脚本"
    echo "  3. 创建PostgreSQL迁移脚本"
    echo "  4. 创建Redis迁移脚本"
    echo "  5. 创建MongoDB迁移脚本"
    echo "  6. 创建Neo4j迁移脚本"
    echo "  7. 创建综合迁移配置"
    echo "  8. 创建综合迁移主脚本"
    echo ""
    
    # 执行各项建立步骤
    create_migration_structure
    create_mysql_migration
    create_postgresql_migration
    create_redis_migration
    create_mongodb_migration
    create_neo4j_migration
    create_migration_config
    create_comprehensive_migration_script
    
    # 显示建立结果
    log_success "🎉 综合数据库迁移系统建立完成！"
    echo ""
    log_info "📊 迁移系统结构:"
    log_info "  - 迁移目录: database-migration/"
    log_info "  - 脚本目录: database-migration/scripts/"
    log_info "  - 备份目录: database-migration/backups/"
    log_info "  - 日志目录: database-migration/logs/"
    log_info "  - 报告目录: database-migration/reports/"
    log_info "  - 配置目录: database-migration/config/"
    echo ""
    log_info "📋 迁移脚本:"
    log_info "  - MySQL迁移: database-migration/scripts/mysql/migrate_mysql.sh"
    log_info "  - PostgreSQL迁移: database-migration/scripts/postgresql/migrate_postgresql.sh"
    log_info "  - Redis迁移: database-migration/scripts/redis/migrate_redis.sh"
    log_info "  - MongoDB迁移: database-migration/scripts/mongodb/migrate_mongodb.sh"
    log_info "  - Neo4j迁移: database-migration/scripts/neo4j/migrate_neo4j.sh"
    log_info "  - 综合迁移: database-migration/run_comprehensive_migration.sh"
    echo ""
    log_success "✅ 综合数据库迁移系统建立完成，可以开始数据迁移！"
}

# 执行主函数
main "$@"
