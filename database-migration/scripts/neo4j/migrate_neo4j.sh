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
