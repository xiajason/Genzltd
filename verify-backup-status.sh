#!/bin/bash

# 备份状态验证脚本
# 创建时间: 2025年1月27日
# 版本: v1.0
# 目标: 验证所有环境的数据库备份状态

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# 检查本地数据库状态
check_local_databases() {
    log_info "=== 检查本地数据库状态 ==="
    
    # MySQL
    if nc -z localhost 3306 2>/dev/null; then
        log_success "MySQL (3306): 运行中"
        mysql -e "SHOW DATABASES;" 2>/dev/null | grep -v "Database\|information_schema\|performance_schema\|mysql\|sys" | while read db; do
            if [ ! -z "$db" ]; then
                log_info "  - 数据库: $db"
            fi
        done
    else
        log_warning "MySQL (3306): 未运行"
    fi
    
    # PostgreSQL
    if nc -z localhost 5432 2>/dev/null; then
        log_success "PostgreSQL (5432): 运行中"
        psql -l 2>/dev/null | grep -v "List of databases\|Name\|Owner\|Encoding\|Collate\|Ctype\|Access privileges" | while read line; do
            if [ ! -z "$line" ] && [ "$line" != " " ]; then
                db=$(echo "$line" | awk '{print $1}')
                if [ ! -z "$db" ] && [ "$db" != "template0" ] && [ "$db" != "template1" ] && [ "$db" != "postgres" ]; then
                    log_info "  - 数据库: $db"
                fi
            fi
        done
    else
        log_warning "PostgreSQL (5432): 未运行"
    fi
    
    # Redis
    if nc -z localhost 6379 2>/dev/null; then
        log_success "Redis (6379): 运行中"
        redis-cli info keyspace 2>/dev/null | grep -v "# Keyspace" | while read line; do
            if [ ! -z "$line" ] && [ "$line" != " " ]; then
                log_info "  - $line"
            fi
        done
    else
        log_warning "Redis (6379): 未运行"
    fi
    
    # MongoDB
    if nc -z localhost 27017 2>/dev/null; then
        log_success "MongoDB (27017): 运行中"
        mongo --eval "db.adminCommand('listDatabases')" 2>/dev/null | grep -v "MongoDB shell\|connecting to\|Implicit session\|MongoDB server\|admin\|config\|local" | while read line; do
            if [ ! -z "$line" ] && [ "$line" != " " ]; then
                log_info "  - $line"
            fi
        done
    else
        log_warning "MongoDB (27017): 未运行"
    fi
    
    # Neo4j
    if nc -z localhost 7474 2>/dev/null; then
        log_success "Neo4j (7474): 运行中"
        curl -s http://localhost:7474/db/data/ | grep -q "data" && log_info "  - Neo4j数据库可访问"
    else
        log_warning "Neo4j (7474): 未运行"
    fi
}

# 检查Docker容器状态
check_docker_containers() {
    log_info "=== 检查Docker容器状态 ==="
    
    if ! docker ps >/dev/null 2>&1; then
        log_warning "Docker未运行"
        return 1
    fi
    
    # 检查数据库容器
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(mysql|postgres|redis|mongo|neo4j)" | while read line; do
        if [ ! -z "$line" ] && [ "$line" != "NAMES" ]; then
            log_success "Docker容器: $line"
        fi
    done
}

# 检查腾讯云连接
check_tencent_connection() {
    log_info "=== 检查腾讯云连接 ==="
    
    if ssh -i ~/.ssh/basic.pem -o ConnectTimeout=5 ubuntu@101.33.251.158 "echo '连接成功'" >/dev/null 2>&1; then
        log_success "腾讯云服务器 (101.33.251.158): 连接正常"
        
        # 检查腾讯云数据库状态
        ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158 << 'REMOTE_SCRIPT'
        echo "检查腾讯云数据库状态..."
        
        # MySQL
        if sudo systemctl is-active --quiet mysql; then
            echo "✅ MySQL: 运行中"
            sudo mysql -e "SHOW DATABASES;" 2>/dev/null | grep -v "Database\|information_schema\|performance_schema\|mysql\|sys" | while read db; do
                if [ ! -z "$db" ]; then
                    echo "  - 数据库: $db"
                fi
            done
        else
            echo "❌ MySQL: 未运行"
        fi
        
        # PostgreSQL
        if sudo systemctl is-active --quiet postgresql; then
            echo "✅ PostgreSQL: 运行中"
            sudo -u postgres psql -l 2>/dev/null | grep -v "List of databases\|Name\|Owner\|Encoding\|Collate\|Ctype\|Access privileges" | while read line; do
                if [ ! -z "$line" ] && [ "$line" != " " ]; then
                    db=$(echo "$line" | awk '{print $1}')
                    if [ ! -z "$db" ] && [ "$db" != "template0" ] && [ "$db" != "template1" ] && [ "$db" != "postgres" ]; then
                        echo "  - 数据库: $db"
                    fi
                fi
            done
        else
            echo "❌ PostgreSQL: 未运行"
        fi
        
        # Redis
        if sudo systemctl is-active --quiet redis; then
            echo "✅ Redis: 运行中"
            sudo redis-cli info keyspace 2>/dev/null | grep -v "# Keyspace" | while read line; do
                if [ ! -z "$line" ] && [ "$line" != " " ]; then
                    echo "  - $line"
                fi
            done
        else
            echo "❌ Redis: 未运行"
        fi
REMOTE_SCRIPT
    else
        log_warning "腾讯云服务器 (101.33.251.158): 连接失败"
    fi
}

# 检查阿里云连接
check_alibaba_connection() {
    log_info "=== 检查阿里云连接 ==="
    
    if ssh -i ~/.ssh/cross_cloud_key -o ConnectTimeout=5 root@47.115.168.107 "echo '连接成功'" >/dev/null 2>&1; then
        log_success "阿里云服务器 (47.115.168.107): 连接正常"
        
        # 检查阿里云数据库状态
        ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 << 'REMOTE_SCRIPT'
        echo "检查阿里云数据库状态..."
        
        # 检查现有服务
        echo "现有运行服务:"
        netstat -tuln | grep -E ":(6379|8206|8080|8300)" | head -5
        
        # 检查Docker容器
        echo "Docker容器状态:"
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | head -10
        
        # 检查Redis
        if redis-cli ping >/dev/null 2>&1; then
            echo "✅ Redis: 运行中"
            redis-cli info keyspace 2>/dev/null | grep -v "# Keyspace" | while read line; do
                if [ ! -z "$line" ] && [ "$line" != " " ]; then
                    echo "  - $line"
                fi
            done
        else
            echo "❌ Redis: 未运行"
        fi
        
        # 检查AI服务
        if curl -s http://localhost:8206/health >/dev/null 2>&1; then
            echo "✅ AI服务 (8206): 运行中"
        else
            echo "❌ AI服务 (8206): 未运行"
        fi
        
        # 检查Consul
        if curl -s http://localhost:8300/v1/status/leader >/dev/null 2>&1; then
            echo "✅ Consul (8300): 运行中"
        else
            echo "❌ Consul (8300): 未运行"
        fi
REMOTE_SCRIPT
    else
        log_warning "阿里云服务器 (47.115.168.107): 连接失败"
    fi
}

# 检查现有备份
check_existing_backups() {
    log_info "=== 检查现有备份 ==="
    
    if [ -d "database-backups" ]; then
        log_success "本地备份目录存在"
        ls -la database-backups/ | grep -v "^total\|^d" | while read line; do
            if [ ! -z "$line" ]; then
                log_info "  - $line"
            fi
        done
    else
        log_warning "本地备份目录不存在"
    fi
    
    if [ -d "data-migration-backups" ]; then
        log_success "数据迁移备份目录存在"
        ls -la data-migration-backups/ | grep -v "^total\|^d" | while read line; do
            if [ ! -z "$line" ]; then
                log_info "  - $line"
            fi
        done
    else
        log_warning "数据迁移备份目录不存在"
    fi
}

# 主函数
main() {
    log_info "🔍 开始备份状态验证..."
    log_info "验证时间: $(date)"
    
    check_local_databases
    check_docker_containers
    check_tencent_connection
    check_alibaba_connection
    check_existing_backups
    
    log_success "✅ 备份状态验证完成！"
    log_info "现在可以安全执行全面数据库备份"
}

# 执行主函数
main "$@"
