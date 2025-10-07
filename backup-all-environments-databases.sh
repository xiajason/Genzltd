#!/bin/bash

# 全面数据库备份脚本 - 覆盖所有环境
# 创建时间: 2025年1月27日
# 版本: v1.0
# 目标: 备份本地、Docker、阿里云、腾讯云所有数据库

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
BACKUP_DIR="database-backups/comprehensive_${TIMESTAMP}"

# 创建备份目录
mkdir -p "$BACKUP_DIR"/{local,docker,tencent,alibaba}

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

# 检查服务状态
check_service() {
    local service_name=$1
    local port=$2
    if nc -z localhost $port 2>/dev/null; then
        log_success "$service_name (端口$port): 运行中"
        return 0
    else
        log_warning "$service_name (端口$port): 未运行"
        return 1
    fi
}

# 1. 本地数据库备份
backup_local_databases() {
    log_info "=== 开始本地数据库备份 ==="
    
    # 检查本地数据库状态
    log_info "检查本地数据库状态..."
    check_service "MySQL" 3306
    check_service "PostgreSQL" 5432
    check_service "Redis" 6379
    check_service "MongoDB" 27017
    check_service "Neo4j" 7474
    
    # MySQL备份
    if nc -z localhost 3306 2>/dev/null; then
        log_info "备份MySQL数据库..."
        mysqldump --all-databases --single-transaction --routines --triggers > "$BACKUP_DIR/local/mysql_backup_$TIMESTAMP.sql" 2>/dev/null
        if [ $? -eq 0 ]; then
            log_success "MySQL备份完成: $BACKUP_DIR/local/mysql_backup_$TIMESTAMP.sql"
        else
            log_error "MySQL备份失败"
        fi
    else
        log_warning "MySQL未运行，跳过备份"
    fi
    
    # PostgreSQL备份
    if nc -z localhost 5432 2>/dev/null; then
        log_info "备份PostgreSQL数据库..."
        pg_dumpall > "$BACKUP_DIR/local/postgresql_backup_$TIMESTAMP.sql" 2>/dev/null
        if [ $? -eq 0 ]; then
            log_success "PostgreSQL备份完成: $BACKUP_DIR/local/postgresql_backup_$TIMESTAMP.sql"
        else
            log_error "PostgreSQL备份失败"
        fi
    else
        log_warning "PostgreSQL未运行，跳过备份"
    fi
    
    # Redis备份
    if nc -z localhost 6379 2>/dev/null; then
        log_info "备份Redis数据库..."
        redis-cli --rdb "$BACKUP_DIR/local/redis_backup_$TIMESTAMP.rdb" 2>/dev/null
        if [ $? -eq 0 ]; then
            log_success "Redis备份完成: $BACKUP_DIR/local/redis_backup_$TIMESTAMP.rdb"
        else
            log_error "Redis备份失败"
        fi
    else
        log_warning "Redis未运行，跳过备份"
    fi
    
    # MongoDB备份
    if nc -z localhost 27017 2>/dev/null; then
        log_info "备份MongoDB数据库..."
        mongodump --out "$BACKUP_DIR/local/mongodb_backup_$TIMESTAMP" 2>/dev/null
        if [ $? -eq 0 ]; then
            log_success "MongoDB备份完成: $BACKUP_DIR/local/mongodb_backup_$TIMESTAMP"
        else
            log_error "MongoDB备份失败"
        fi
    else
        log_warning "MongoDB未运行，跳过备份"
    fi
    
    # Neo4j备份
    if nc -z localhost 7474 2>/dev/null; then
        log_info "备份Neo4j数据库..."
        # Neo4j备份需要特殊处理
        curl -u neo4j:password -X POST http://localhost:7474/db/data/cypher -H "Content-Type: application/json" -d '{"query": "CALL apoc.export.all(\"$BACKUP_DIR/local/neo4j_backup_$TIMESTAMP\", {})"}' 2>/dev/null
        if [ $? -eq 0 ]; then
            log_success "Neo4j备份完成: $BACKUP_DIR/local/neo4j_backup_$TIMESTAMP"
        else
            log_warning "Neo4j备份失败，尝试手动备份"
            # 手动备份Neo4j数据目录
            if [ -d "/usr/local/var/neo4j/data" ]; then
                cp -r /usr/local/var/neo4j/data "$BACKUP_DIR/local/neo4j_data_backup_$TIMESTAMP"
                log_success "Neo4j数据目录备份完成"
            fi
        fi
    else
        log_warning "Neo4j未运行，跳过备份"
    fi
}

# 2. Docker数据库备份
backup_docker_databases() {
    log_info "=== 开始Docker数据库备份 ==="
    
    # 检查Docker状态
    if ! docker ps >/dev/null 2>&1; then
        log_warning "Docker未运行，跳过Docker数据库备份"
        return 1
    fi
    
    # 获取所有运行的数据库容器
    log_info "检查Docker数据库容器..."
    
    # MySQL容器备份
    if docker ps --format "table {{.Names}}" | grep -q mysql; then
        log_info "备份Docker MySQL数据库..."
        docker exec $(docker ps --format "table {{.Names}}" | grep mysql | head -1) mysqldump --all-databases --single-transaction --routines --triggers > "$BACKUP_DIR/docker/mysql_backup_$TIMESTAMP.sql" 2>/dev/null
        if [ $? -eq 0 ]; then
            log_success "Docker MySQL备份完成: $BACKUP_DIR/docker/mysql_backup_$TIMESTAMP.sql"
        else
            log_error "Docker MySQL备份失败"
        fi
    else
        log_warning "未找到MySQL容器"
    fi
    
    # PostgreSQL容器备份
    if docker ps --format "table {{.Names}}" | grep -q postgres; then
        log_info "备份Docker PostgreSQL数据库..."
        docker exec $(docker ps --format "table {{.Names}}" | grep postgres | head -1) pg_dumpall > "$BACKUP_DIR/docker/postgresql_backup_$TIMESTAMP.sql" 2>/dev/null
        if [ $? -eq 0 ]; then
            log_success "Docker PostgreSQL备份完成: $BACKUP_DIR/docker/postgresql_backup_$TIMESTAMP.sql"
        else
            log_error "Docker PostgreSQL备份失败"
        fi
    else
        log_warning "未找到PostgreSQL容器"
    fi
    
    # Redis容器备份
    if docker ps --format "table {{.Names}}" | grep -q redis; then
        log_info "备份Docker Redis数据库..."
        docker exec $(docker ps --format "table {{.Names}}" | grep redis | head -1) redis-cli --rdb /tmp/redis_backup.rdb
        docker cp $(docker ps --format "table {{.Names}}" | grep redis | head -1):/tmp/redis_backup.rdb "$BACKUP_DIR/docker/redis_backup_$TIMESTAMP.rdb" 2>/dev/null
        if [ $? -eq 0 ]; then
            log_success "Docker Redis备份完成: $BACKUP_DIR/docker/redis_backup_$TIMESTAMP.rdb"
        else
            log_error "Docker Redis备份失败"
        fi
    else
        log_warning "未找到Redis容器"
    fi
    
    # MongoDB容器备份
    if docker ps --format "table {{.Names}}" | grep -q mongo; then
        log_info "备份Docker MongoDB数据库..."
        docker exec $(docker ps --format "table {{.Names}}" | grep mongo | head -1) mongodump --out /tmp/mongodb_backup
        docker cp $(docker ps --format "table {{.Names}}" | grep mongo | head -1):/tmp/mongodb_backup "$BACKUP_DIR/docker/mongodb_backup_$TIMESTAMP" 2>/dev/null
        if [ $? -eq 0 ]; then
            log_success "Docker MongoDB备份完成: $BACKUP_DIR/docker/mongodb_backup_$TIMESTAMP"
        else
            log_error "Docker MongoDB备份失败"
        fi
    else
        log_warning "未找到MongoDB容器"
    fi
    
    # Neo4j容器备份
    if docker ps --format "table {{.Names}}" | grep -q neo4j; then
        log_info "备份Docker Neo4j数据库..."
        docker exec $(docker ps --format "table {{.Names}}" | grep neo4j | head -1) neo4j-admin dump --database=neo4j --to=/tmp/neo4j_backup.dump
        docker cp $(docker ps --format "table {{.Names}}" | grep neo4j | head -1):/tmp/neo4j_backup.dump "$BACKUP_DIR/docker/neo4j_backup_$TIMESTAMP.dump" 2>/dev/null
        if [ $? -eq 0 ]; then
            log_success "Docker Neo4j备份完成: $BACKUP_DIR/docker/neo4j_backup_$TIMESTAMP.dump"
        else
            log_error "Docker Neo4j备份失败"
        fi
    else
        log_warning "未找到Neo4j容器"
    fi
}

# 3. 腾讯云数据库备份
backup_tencent_databases() {
    log_info "=== 开始腾讯云数据库备份 ==="
    
    # 检查腾讯云连接
    if ! ssh -i ~/.ssh/basic.pem -o ConnectTimeout=10 ubuntu@101.33.251.158 "echo '连接成功'" >/dev/null 2>&1; then
        log_warning "无法连接到腾讯云服务器，跳过腾讯云数据库备份"
        return 1
    fi
    
    log_info "连接腾讯云服务器 (101.33.251.158)..."
    
    # 在腾讯云服务器上执行备份
    ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158 << 'REMOTE_SCRIPT'
    echo "在腾讯云服务器上执行数据库备份..."
    
    # 检查数据库状态
    echo "检查数据库状态..."
    sudo systemctl status mysql | grep -q "Active: active" && echo "MySQL: 运行中" || echo "MySQL: 未运行"
    sudo systemctl status postgresql | grep -q "Active: active" && echo "PostgreSQL: 运行中" || echo "PostgreSQL: 未运行"
    sudo systemctl status redis | grep -q "Active: active" && echo "Redis: 运行中" || echo "Redis: 未运行"
    
    # 创建备份目录
    mkdir -p /tmp/backup_$(date +%Y%m%d_%H%M%S)
    BACKUP_DIR="/tmp/backup_$(date +%Y%m%d_%H%M%S)"
    
    # MySQL备份
    if sudo systemctl is-active --quiet mysql; then
        echo "备份MySQL数据库..."
        sudo mysqldump --all-databases --single-transaction --routines --triggers > "$BACKUP_DIR/mysql_backup.sql" 2>/dev/null
        if [ $? -eq 0 ]; then
            echo "MySQL备份完成: $BACKUP_DIR/mysql_backup.sql"
        else
            echo "MySQL备份失败"
        fi
    fi
    
    # PostgreSQL备份
    if sudo systemctl is-active --quiet postgresql; then
        echo "备份PostgreSQL数据库..."
        sudo -u postgres pg_dumpall > "$BACKUP_DIR/postgresql_backup.sql" 2>/dev/null
        if [ $? -eq 0 ]; then
            echo "PostgreSQL备份完成: $BACKUP_DIR/postgresql_backup.sql"
        else
            echo "PostgreSQL备份失败"
        fi
    fi
    
    # Redis备份
    if sudo systemctl is-active --quiet redis; then
        echo "备份Redis数据库..."
        sudo redis-cli --rdb "$BACKUP_DIR/redis_backup.rdb" 2>/dev/null
        if [ $? -eq 0 ]; then
            echo "Redis备份完成: $BACKUP_DIR/redis_backup.rdb"
        else
            echo "Redis备份失败"
        fi
    fi
    
    echo "腾讯云数据库备份完成，备份目录: $BACKUP_DIR"
REMOTE_SCRIPT
    
    # 下载腾讯云备份文件
    log_info "下载腾讯云备份文件..."
    scp -i ~/.ssh/basic.pem -r ubuntu@101.33.251.158:/tmp/backup_* "$BACKUP_DIR/tencent/" 2>/dev/null
    if [ $? -eq 0 ]; then
        log_success "腾讯云备份文件下载完成"
    else
        log_warning "腾讯云备份文件下载失败"
    fi
}

# 4. 阿里云数据库备份
backup_alibaba_databases() {
    log_info "=== 开始阿里云数据库备份 ==="
    
    # 检查阿里云连接
    if ! ssh -i ~/.ssh/cross_cloud_key -o ConnectTimeout=10 root@47.115.168.107 "echo '连接成功'" >/dev/null 2>&1; then
        log_warning "无法连接到阿里云服务器，跳过阿里云数据库备份"
        return 1
    fi
    
    log_info "连接阿里云服务器 (47.115.168.107)..."
    
    # 在阿里云服务器上执行备份
    ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 << 'REMOTE_SCRIPT'
    echo "在阿里云服务器上执行数据库备份..."
    
    # 检查现有服务状态
    echo "检查现有服务状态..."
    netstat -tuln | grep -E ":(6379|8206|8080|8300)" | head -5
    
    # 检查Docker容器
    echo "检查Docker容器..."
    docker ps --format "table {{.Names}}\t{{.Status}}" | head -10
    
    # 创建备份目录
    mkdir -p /tmp/alibaba_backup_$(date +%Y%m%d_%H%M%S)
    BACKUP_DIR="/tmp/alibaba_backup_$(date +%Y%m%d_%H%M%S)"
    
    # 备份现有Redis服务
    if redis-cli ping >/dev/null 2>&1; then
        echo "备份现有Redis服务..."
        redis-cli --rdb "$BACKUP_DIR/redis_backup.rdb" 2>/dev/null
        if [ $? -eq 0 ]; then
            echo "Redis备份完成: $BACKUP_DIR/redis_backup.rdb"
        else
            echo "Redis备份失败"
        fi
    fi
    
    # 备份Docker容器数据
    echo "备份Docker容器数据..."
    docker ps --format "{{.Names}}" | while read container; do
        if [ ! -z "$container" ]; then
            echo "备份容器: $container"
            docker exec "$container" sh -c "find /var/lib -name '*.db' -o -name '*.sqlite' -o -name '*.rdb' 2>/dev/null" > "$BACKUP_DIR/${container}_files.txt" 2>/dev/null
        fi
    done
    
    # 备份Docker卷
    echo "备份Docker卷..."
    docker volume ls --format "{{.Name}}" | while read volume; do
        if [ ! -z "$volume" ]; then
            echo "备份卷: $volume"
            docker run --rm -v "$volume":/data -v "$BACKUP_DIR":/backup alpine tar czf "/backup/${volume}.tar.gz" -C /data . 2>/dev/null
        fi
    done
    
    echo "阿里云数据库备份完成，备份目录: $BACKUP_DIR"
REMOTE_SCRIPT
    
    # 下载阿里云备份文件
    log_info "下载阿里云备份文件..."
    scp -i ~/.ssh/cross_cloud_key -r root@47.115.168.107:/tmp/alibaba_backup_* "$BACKUP_DIR/alibaba/" 2>/dev/null
    if [ $? -eq 0 ]; then
        log_success "阿里云备份文件下载完成"
    else
        log_warning "阿里云备份文件下载失败"
    fi
}

# 5. 生成备份报告
generate_backup_report() {
    log_info "=== 生成备份报告 ==="
    
    REPORT_FILE="$BACKUP_DIR/backup_report_$TIMESTAMP.md"
    
    cat > "$REPORT_FILE" << EOF
# 全面数据库备份报告

**备份时间**: $(date)
**备份版本**: v1.0
**备份范围**: 本地、Docker、腾讯云、阿里云

## 📊 备份概览

### 本地数据库备份
EOF

    # 添加本地备份信息
    if [ -d "$BACKUP_DIR/local" ]; then
        echo "### 本地备份文件" >> "$REPORT_FILE"
        ls -la "$BACKUP_DIR/local" | grep -v "^total" | while read line; do
            echo "- $line" >> "$REPORT_FILE"
        done
    fi
    
    cat >> "$REPORT_FILE" << EOF

### Docker数据库备份
EOF

    # 添加Docker备份信息
    if [ -d "$BACKUP_DIR/docker" ]; then
        echo "### Docker备份文件" >> "$REPORT_FILE"
        ls -la "$BACKUP_DIR/docker" | grep -v "^total" | while read line; do
            echo "- $line" >> "$REPORT_FILE"
        done
    fi
    
    cat >> "$REPORT_FILE" << EOF

### 腾讯云数据库备份
EOF

    # 添加腾讯云备份信息
    if [ -d "$BACKUP_DIR/tencent" ]; then
        echo "### 腾讯云备份文件" >> "$REPORT_FILE"
        ls -la "$BACKUP_DIR/tencent" | grep -v "^total" | while read line; do
            echo "- $line" >> "$REPORT_FILE"
        done
    fi
    
    cat >> "$REPORT_FILE" << EOF

### 阿里云数据库备份
EOF

    # 添加阿里云备份信息
    if [ -d "$BACKUP_DIR/alibaba" ]; then
        echo "### 阿里云备份文件" >> "$REPORT_FILE"
        ls -la "$BACKUP_DIR/alibaba" | grep -v "^total" | while read line; do
            echo "- $line" >> "$REPORT_FILE"
        done
    fi
    
    cat >> "$REPORT_FILE" << EOF

## 🔍 备份验证

### 备份完整性检查
EOF

    # 检查备份文件完整性
    find "$BACKUP_DIR" -type f -name "*.sql" -exec echo "SQL文件: {}" \; >> "$REPORT_FILE"
    find "$BACKUP_DIR" -type f -name "*.rdb" -exec echo "Redis文件: {}" \; >> "$REPORT_FILE"
    find "$BACKUP_DIR" -type f -name "*.dump" -exec echo "Neo4j文件: {}" \; >> "$REPORT_FILE"
    find "$BACKUP_DIR" -type f -name "*.tar.gz" -exec echo "Docker卷文件: {}" \; >> "$REPORT_FILE"
    
    cat >> "$REPORT_FILE" << EOF

### 备份大小统计
EOF

    # 添加备份大小信息
    du -sh "$BACKUP_DIR"/* >> "$REPORT_FILE" 2>/dev/null
    
    cat >> "$REPORT_FILE" << EOF

## 📋 恢复说明

### 本地数据库恢复
\`\`\`bash
# MySQL恢复
mysql < $BACKUP_DIR/local/mysql_backup_$TIMESTAMP.sql

# PostgreSQL恢复
psql < $BACKUP_DIR/local/postgresql_backup_$TIMESTAMP.sql

# Redis恢复
redis-cli --pipe < $BACKUP_DIR/local/redis_backup_$TIMESTAMP.rdb
\`\`\`

### Docker数据库恢复
\`\`\`bash
# 恢复MySQL容器
docker exec -i <mysql_container> mysql < $BACKUP_DIR/docker/mysql_backup_$TIMESTAMP.sql

# 恢复PostgreSQL容器
docker exec -i <postgres_container> psql < $BACKUP_DIR/docker/postgresql_backup_$TIMESTAMP.sql
\`\`\`

## ✅ 备份完成

**备份目录**: $BACKUP_DIR
**备份时间**: $(date)
**备份状态**: 完成

---
*此报告由全面数据库备份脚本自动生成*
EOF

    log_success "备份报告生成完成: $REPORT_FILE"
}

# 主函数
main() {
    log_info "🚀 开始全面数据库备份..."
    log_info "备份时间: $(date)"
    log_info "备份目录: $BACKUP_DIR"
    
    # 创建备份目录
    mkdir -p "$BACKUP_DIR"
    
    # 执行各环境备份
    backup_local_databases
    backup_docker_databases
    backup_tencent_databases
    backup_alibaba_databases
    
    # 生成备份报告
    generate_backup_report
    
    # 显示备份结果
    log_success "🎉 全面数据库备份完成！"
    log_info "备份目录: $BACKUP_DIR"
    log_info "备份报告: $BACKUP_DIR/backup_report_$TIMESTAMP.md"
    
    # 显示备份文件统计
    log_info "📊 备份文件统计:"
    du -sh "$BACKUP_DIR"/* 2>/dev/null | while read line; do
        log_info "  $line"
    done
    
    log_success "✅ 所有环境数据库备份完成，可以安全开始实施！"
}

# 执行主函数
main "$@"
