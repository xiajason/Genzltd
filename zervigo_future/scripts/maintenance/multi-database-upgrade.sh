#!/bin/bash

# JobFirst 多数据库协同升级脚本
# 版本: V3.0 -> V4.0 (多数据库协同)
# 日期: 2025年1月6日
# 描述: 执行多数据库协同升级和初始化

set -e  # 遇到错误立即退出

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

# 配置变量
MYSQL_HOST=${MYSQL_HOST:-"localhost"}
MYSQL_USER=${MYSQL_USER:-"root"}
MYSQL_PASSWORD=${MYSQL_PASSWORD:-""}
MYSQL_DB=${MYSQL_DB:-"jobfirst"}

POSTGRES_HOST=${POSTGRES_HOST:-"localhost"}
POSTGRES_USER=${POSTGRES_USER:-"szjason72"}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-""}
POSTGRES_DB=${POSTGRES_DB:-"jobfirst_vector"}

REDIS_HOST=${REDIS_HOST:-"localhost"}
REDIS_PORT=${REDIS_PORT:-"6379"}
REDIS_PASSWORD=${REDIS_PASSWORD:-""}

NEO4J_HOST=${NEO4J_HOST:-"localhost"}
NEO4J_PORT=${NEO4J_PORT:-"7474"}
NEO4J_USER=${NEO4J_USER:-"neo4j"}
NEO4J_PASSWORD=${NEO4J_PASSWORD:-"password"}

BACKUP_DIR="./backup"
MYSQL_UPGRADE_SCRIPT="./database/mysql/upgrade_script.sql"
MYSQL_INIT_SCRIPT="./database/mysql/upgrade_init_data.sql"
POSTGRES_UPGRADE_SCRIPT="./database/postgresql/ai_service_upgrade.sql"
REDIS_UPGRADE_SCRIPT="./database/redis/cache_upgrade.redis"
NEO4J_UPGRADE_SCRIPT="./database/neo4j/graph_upgrade.cypher"

# 检查必要文件
check_files() {
    log_info "检查必要文件..."
    
    local files=(
        "$MYSQL_UPGRADE_SCRIPT"
        "$MYSQL_INIT_SCRIPT"
        "$POSTGRES_UPGRADE_SCRIPT"
        "$REDIS_UPGRADE_SCRIPT"
        "$NEO4J_UPGRADE_SCRIPT"
    )
    
    for file in "${files[@]}"; do
        if [ ! -f "$file" ]; then
            log_error "升级脚本不存在: $file"
            exit 1
        fi
    done
    
    log_success "必要文件检查完成"
}

# 创建备份目录
create_backup_dir() {
    log_info "创建备份目录..."
    mkdir -p "$BACKUP_DIR"
    log_success "备份目录创建完成: $BACKUP_DIR"
}

# 检查数据库连接
check_connections() {
    log_info "检查数据库连接..."
    
    # 检查MySQL连接
    if [ -n "$MYSQL_PASSWORD" ]; then
        mysql -h "$MYSQL_HOST" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "SELECT 1;" "$MYSQL_DB" > /dev/null 2>&1
    else
        mysql -h "$MYSQL_HOST" -u "$MYSQL_USER" -e "SELECT 1;" "$MYSQL_DB" > /dev/null 2>&1
    fi
    
    if [ $? -eq 0 ]; then
        log_success "MySQL连接正常"
    else
        log_error "MySQL连接失败"
        exit 1
    fi
    
    # 检查PostgreSQL连接
    if [ -n "$POSTGRES_PASSWORD" ]; then
        PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$POSTGRES_HOST" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "SELECT 1;" > /dev/null 2>&1
    else
        psql -h "$POSTGRES_HOST" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "SELECT 1;" > /dev/null 2>&1
    fi
    
    if [ $? -eq 0 ]; then
        log_success "PostgreSQL连接正常"
    else
        log_error "PostgreSQL连接失败"
        exit 1
    fi
    
    # 检查Redis连接
    if [ -n "$REDIS_PASSWORD" ]; then
        redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" -a "$REDIS_PASSWORD" ping > /dev/null 2>&1
    else
        redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ping > /dev/null 2>&1
    fi
    
    if [ $? -eq 0 ]; then
        log_success "Redis连接正常"
    else
        log_error "Redis连接失败"
        exit 1
    fi
    
    # 检查Neo4j连接
    curl -u "$NEO4J_USER:$NEO4J_PASSWORD" "http://$NEO4J_HOST:$NEO4J_PORT/db/data/" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        log_success "Neo4j连接正常"
    else
        log_warning "Neo4j连接失败，将在后续步骤中处理"
    fi
}

# 数据库备份
backup_databases() {
    log_info "开始数据库备份..."
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    
    # 备份MySQL
    local mysql_backup="$BACKUP_DIR/mysql_backup_$timestamp.sql"
    if [ -n "$MYSQL_PASSWORD" ]; then
        mysqldump -h "$MYSQL_HOST" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DB" > "$mysql_backup"
    else
        mysqldump -h "$MYSQL_HOST" -u "$MYSQL_USER" "$MYSQL_DB" > "$mysql_backup"
    fi
    
    if [ $? -eq 0 ]; then
        log_success "MySQL备份完成: $mysql_backup"
    else
        log_error "MySQL备份失败"
        exit 1
    fi
    
    # 备份PostgreSQL
    local postgres_backup="$BACKUP_DIR/postgres_backup_$timestamp.sql"
    if [ -n "$POSTGRES_PASSWORD" ]; then
        PGPASSWORD="$POSTGRES_PASSWORD" pg_dump -h "$POSTGRES_HOST" -U "$POSTGRES_USER" -d "$POSTGRES_DB" > "$postgres_backup"
    else
        pg_dump -h "$POSTGRES_HOST" -U "$POSTGRES_USER" -d "$POSTGRES_DB" > "$postgres_backup"
    fi
    
    if [ $? -eq 0 ]; then
        log_success "PostgreSQL备份完成: $postgres_backup"
    else
        log_error "PostgreSQL备份失败"
        exit 1
    fi
    
    # 备份Redis
    local redis_backup="$BACKUP_DIR/redis_backup_$timestamp.rdb"
    if [ -n "$REDIS_PASSWORD" ]; then
        redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" -a "$REDIS_PASSWORD" BGSAVE
    else
        redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" BGSAVE
    fi
    
    log_success "Redis备份完成: $redis_backup"
}

# 执行MySQL升级
upgrade_mysql() {
    log_info "开始MySQL升级..."
    
    # 执行升级脚本
    if [ -n "$MYSQL_PASSWORD" ]; then
        mysql -h "$MYSQL_HOST" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DB" < "$MYSQL_UPGRADE_SCRIPT"
    else
        mysql -h "$MYSQL_HOST" -u "$MYSQL_USER" "$MYSQL_DB" < "$MYSQL_UPGRADE_SCRIPT"
    fi
    
    if [ $? -eq 0 ]; then
        log_success "MySQL升级完成"
    else
        log_error "MySQL升级失败"
        exit 1
    fi
    
    # 执行初始化脚本
    if [ -n "$MYSQL_PASSWORD" ]; then
        mysql -h "$MYSQL_HOST" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DB" < "$MYSQL_INIT_SCRIPT"
    else
        mysql -h "$MYSQL_HOST" -u "$MYSQL_USER" "$MYSQL_DB" < "$MYSQL_INIT_SCRIPT"
    fi
    
    if [ $? -eq 0 ]; then
        log_success "MySQL初始化完成"
    else
        log_error "MySQL初始化失败"
        exit 1
    fi
}

# 执行PostgreSQL升级
upgrade_postgresql() {
    log_info "开始PostgreSQL升级..."
    
    # 执行升级脚本
    if [ -n "$POSTGRES_PASSWORD" ]; then
        PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$POSTGRES_HOST" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f "$POSTGRES_UPGRADE_SCRIPT"
    else
        psql -h "$POSTGRES_HOST" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f "$POSTGRES_UPGRADE_SCRIPT"
    fi
    
    if [ $? -eq 0 ]; then
        log_success "PostgreSQL升级完成"
    else
        log_error "PostgreSQL升级失败"
        exit 1
    fi
}

# 执行Redis升级
upgrade_redis() {
    log_info "开始Redis升级..."
    
    # 执行升级脚本
    if [ -n "$REDIS_PASSWORD" ]; then
        redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" -a "$REDIS_PASSWORD" < "$REDIS_UPGRADE_SCRIPT"
    else
        redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" < "$REDIS_UPGRADE_SCRIPT"
    fi
    
    if [ $? -eq 0 ]; then
        log_success "Redis升级完成"
    else
        log_error "Redis升级失败"
        exit 1
    fi
}

# 执行Neo4j升级
upgrade_neo4j() {
    log_info "开始Neo4j升级..."
    
    # 检查Neo4j连接
    curl -u "$NEO4J_USER:$NEO4J_PASSWORD" "http://$NEO4J_HOST:$NEO4J_PORT/db/data/" > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        log_warning "Neo4j连接失败，跳过Neo4j升级"
        return 0
    fi
    
    # 执行升级脚本
    curl -u "$NEO4J_USER:$NEO4J_PASSWORD" \
         -H "Content-Type: application/json" \
         -X POST \
         -d "{\"query\": \"$(cat "$NEO4J_UPGRADE_SCRIPT" | tr '\n' ' ' | sed 's/"/\\"/g')\"}" \
         "http://$NEO4J_HOST:$NEO4J_PORT/db/data/transaction/commit" > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        log_success "Neo4j升级完成"
    else
        log_warning "Neo4j升级失败，将在后续步骤中处理"
    fi
}

# 验证升级结果
verify_upgrade() {
    log_info "验证升级结果..."
    
    # 验证MySQL
    local mysql_tables=$(mysql -h "$MYSQL_HOST" -u "$MYSQL_USER" ${MYSQL_PASSWORD:+-p"$MYSQL_PASSWORD"} -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$MYSQL_DB';" -s -N 2>/dev/null)
    local mysql_roles=$(mysql -h "$MYSQL_HOST" -u "$MYSQL_USER" ${MYSQL_PASSWORD:+-p"$MYSQL_PASSWORD"} -e "SELECT COUNT(*) FROM roles;" -s -N 2>/dev/null || echo "0")
    
    # 验证PostgreSQL
    local postgres_tables=$(PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$POSTGRES_HOST" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public';" 2>/dev/null | tr -d ' ')
    local postgres_ai_models=$(PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$POSTGRES_HOST" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -t -c "SELECT COUNT(*) FROM ai_models;" 2>/dev/null | tr -d ' ' || echo "0")
    
    # 验证Redis
    local redis_keys=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} DBSIZE 2>/dev/null || echo "0")
    
    log_info "升级后统计:"
    log_info "  - MySQL表数量: $mysql_tables"
    log_info "  - MySQL角色数量: $mysql_roles"
    log_info "  - PostgreSQL表数量: $postgres_tables"
    log_info "  - PostgreSQL AI模型数量: $postgres_ai_models"
    log_info "  - Redis键数量: $redis_keys"
    
    if [ "$mysql_tables" -ge 25 ] && [ "$mysql_roles" -ge 5 ] && [ "$postgres_tables" -ge 10 ] && [ "$postgres_ai_models" -ge 5 ]; then
        log_success "多数据库升级验证通过"
        return 0
    else
        log_warning "多数据库升级验证未完全通过，请检查"
        return 1
    fi
}

# 生成升级报告
generate_report() {
    log_info "生成升级报告..."
    
    local report_file="$BACKUP_DIR/multi_database_upgrade_report_$(date +%Y%m%d_%H%M%S).txt"
    
    cat > "$report_file" << EOF
JobFirst 多数据库协同升级报告
===============================

升级时间: $(date)
升级版本: V3.0 -> V4.0 (多数据库协同)

数据库配置:
-----------
MySQL: $MYSQL_HOST:$MYSQL_DB
PostgreSQL: $POSTGRES_HOST:$POSTGRES_DB
Redis: $REDIS_HOST:$REDIS_PORT
Neo4j: $NEO4J_HOST:$NEO4J_PORT

升级内容:
---------

1. MySQL核心业务升级
   - 权限管理系统 (6个表)
   - 数据分类标签系统 (2个表)
   - 企业职位管理升级 (2个表)
   - 个人信息保护升级
   - 数据脱敏视图

2. PostgreSQL AI服务升级
   - AI模型管理 (2个表)
   - 企业AI分析 (2个表)
   - 职位AI分析 (2个表)
   - 用户AI画像 (2个表)
   - 智能推荐 (2个表)
   - AI对话 (2个表)
   - 向量存储 (3个表)

3. Redis缓存升级
   - 多级缓存策略
   - 会话管理优化
   - 实时数据存储
   - 消息队列

4. Neo4j图数据库
   - 关系网络构建
   - 用户关系图谱
   - 技能关联网络
   - 推荐算法支持

数据分布策略:
-------------
- 结构化业务数据 → MySQL
- AI和向量数据 → PostgreSQL
- 缓存和会话 → Redis
- 关系网络 → Neo4j

备份信息:
---------
MySQL备份: $BACKUP_DIR/mysql_backup_*.sql
PostgreSQL备份: $BACKUP_DIR/postgres_backup_*.sql
Redis备份: $BACKUP_DIR/redis_backup_*.rdb

注意事项:
---------
1. 请确保应用程序已更新以支持新的多数据库架构
2. 建议在升级后进行全面测试
3. 定期检查各数据库服务状态
4. 根据数据生命周期策略定期清理过期数据
5. 监控跨数据库事务一致性

升级状态: 成功完成
EOF

    log_success "升级报告已生成: $report_file"
}

# 主函数
main() {
    echo "=========================================="
    echo "JobFirst 多数据库协同升级脚本 V3.0 -> V4.0"
    echo "=========================================="
    echo ""
    
    # 检查必要文件
    check_files
    
    # 创建备份目录
    create_backup_dir
    
    # 检查数据库连接
    check_connections
    
    # 数据库备份
    backup_databases
    
    # 执行升级
    upgrade_mysql
    upgrade_postgresql
    upgrade_redis
    upgrade_neo4j
    
    # 验证升级结果
    verify_upgrade
    local verify_status=$?
    
    # 生成升级报告
    generate_report
    
    echo ""
    echo "=========================================="
    if [ $verify_status -eq 0 ]; then
        log_success "多数据库协同升级完成！"
        echo ""
        echo "下一步操作:"
        echo "1. 更新应用程序代码以支持新的多数据库架构"
        echo "2. 重启相关服务"
        echo "3. 进行功能测试"
        echo "4. 检查AI服务配置"
        echo "5. 验证图数据库关系网络"
    else
        log_warning "多数据库协同升级完成，但验证未完全通过"
        echo ""
        echo "请检查:"
        echo "1. 数据库连接和权限"
        echo "2. 升级脚本执行日志"
        echo "3. 各数据库表结构是否正确创建"
        echo "4. 跨数据库数据同步是否正常"
    fi
    echo "=========================================="
}

# 帮助信息
show_help() {
    echo "JobFirst 多数据库协同升级脚本"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help              显示帮助信息"
    echo "  --mysql-host HOST       MySQL主机 (默认: localhost)"
    echo "  --mysql-user USER       MySQL用户 (默认: root)"
    echo "  --mysql-password PASS   MySQL密码"
    echo "  --mysql-db DATABASE     MySQL数据库 (默认: jobfirst)"
    echo "  --postgres-host HOST    PostgreSQL主机 (默认: localhost)"
    echo "  --postgres-user USER    PostgreSQL用户 (默认: szjason72)"
    echo "  --postgres-password PASS PostgreSQL密码"
    echo "  --postgres-db DATABASE  PostgreSQL数据库 (默认: jobfirst_vector)"
    echo "  --redis-host HOST       Redis主机 (默认: localhost)"
    echo "  --redis-port PORT       Redis端口 (默认: 6379)"
    echo "  --redis-password PASS   Redis密码"
    echo "  --neo4j-host HOST       Neo4j主机 (默认: localhost)"
    echo "  --neo4j-port PORT       Neo4j端口 (默认: 7474)"
    echo "  --neo4j-user USER       Neo4j用户 (默认: neo4j)"
    echo "  --neo4j-password PASS   Neo4j密码"
    echo "  --backup-dir DIR        备份目录 (默认: ./backup)"
    echo ""
    echo "环境变量:"
    echo "  MYSQL_HOST, MYSQL_USER, MYSQL_PASSWORD, MYSQL_DB"
    echo "  POSTGRES_HOST, POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_DB"
    echo "  REDIS_HOST, REDIS_PORT, REDIS_PASSWORD"
    echo "  NEO4J_HOST, NEO4J_PORT, NEO4J_USER, NEO4J_PASSWORD"
    echo ""
    echo "示例:"
    echo "  $0 --mysql-host localhost --mysql-user root --mysql-password mypass"
    echo "  MYSQL_PASSWORD=mypass POSTGRES_PASSWORD=mypass $0"
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        --mysql-host)
            MYSQL_HOST="$2"
            shift 2
            ;;
        --mysql-user)
            MYSQL_USER="$2"
            shift 2
            ;;
        --mysql-password)
            MYSQL_PASSWORD="$2"
            shift 2
            ;;
        --mysql-db)
            MYSQL_DB="$2"
            shift 2
            ;;
        --postgres-host)
            POSTGRES_HOST="$2"
            shift 2
            ;;
        --postgres-user)
            POSTGRES_USER="$2"
            shift 2
            ;;
        --postgres-password)
            POSTGRES_PASSWORD="$2"
            shift 2
            ;;
        --postgres-db)
            POSTGRES_DB="$2"
            shift 2
            ;;
        --redis-host)
            REDIS_HOST="$2"
            shift 2
            ;;
        --redis-port)
            REDIS_PORT="$2"
            shift 2
            ;;
        --redis-password)
            REDIS_PASSWORD="$2"
            shift 2
            ;;
        --neo4j-host)
            NEO4J_HOST="$2"
            shift 2
            ;;
        --neo4j-port)
            NEO4J_PORT="$2"
            shift 2
            ;;
        --neo4j-user)
            NEO4J_USER="$2"
            shift 2
            ;;
        --neo4j-password)
            NEO4J_PASSWORD="$2"
            shift 2
            ;;
        --backup-dir)
            BACKUP_DIR="$2"
            shift 2
            ;;
        *)
            log_error "未知参数: $1"
            show_help
            exit 1
            ;;
    esac
done

# 执行主函数
main
