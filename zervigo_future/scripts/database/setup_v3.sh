#!/bin/bash

# JobFirst V3.0 数据库初始化脚本
# 用于创建完整的V3.0数据库结构和填充模拟数据

set -e

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

# 显示帮助信息
show_help() {
    echo "JobFirst V3.0 数据库初始化脚本"
    echo ""
    echo "使用方法:"
    echo "  $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help              显示帮助信息"
    echo "  -d, --database DB       指定数据库名称 (默认: jobfirst_v3)"
    echo "  -u, --user USER         指定数据库用户 (默认: root)"
    echo "  -p, --password PASS     指定数据库密码"
    echo "  -H, --host HOST         指定数据库主机 (默认: localhost)"
    echo "  -P, --port PORT         指定数据库端口 (默认: 3306)"
    echo "  --drop-db               删除现有数据库"
    echo "  --skip-seed             跳过数据填充"
    echo "  --force                 强制执行，不询问确认"
    echo ""
    echo "示例:"
    echo "  $0                      # 使用默认配置初始化数据库"
    echo "  $0 -d mydb -u myuser    # 指定数据库名和用户"
    echo "  $0 --drop-db --force    # 强制删除并重建数据库"
}

# 默认配置
DB_NAME="jobfirst_v3"
DB_USER="root"
DB_PASSWORD=""
DB_HOST="localhost"
DB_PORT="3306"
DROP_DB=false
SKIP_SEED=false
FORCE=false

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -d|--database)
            DB_NAME="$2"
            shift 2
            ;;
        -u|--user)
            DB_USER="$2"
            shift 2
            ;;
        -p|--password)
            DB_PASSWORD="$2"
            shift 2
            ;;
        -H|--host)
            DB_HOST="$2"
            shift 2
            ;;
        -P|--port)
            DB_PORT="$2"
            shift 2
            ;;
        --drop-db)
            DROP_DB=true
            shift
            ;;
        --skip-seed)
            SKIP_SEED=true
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        *)
            log_error "未知选项: $1"
            show_help
            exit 1
            ;;
    esac
done

# 检查MySQL客户端
if ! command -v mysql &> /dev/null; then
    log_error "MySQL客户端未安装或不在PATH中"
    exit 1
fi

# 获取数据库密码
if [[ -z "$DB_PASSWORD" ]]; then
    read -s -p "请输入数据库密码: " DB_PASSWORD
    echo
fi

# 显示配置信息
log_info "数据库初始化配置:"
echo "  数据库名称: $DB_NAME"
echo "  数据库用户: $DB_USER"
echo "  数据库主机: $DB_HOST"
echo "  数据库端口: $DB_PORT"
echo "  删除现有数据库: $DROP_DB"
echo "  跳过数据填充: $SKIP_SEED"
echo "  强制执行: $FORCE"
echo ""

# 确认执行
if [[ "$FORCE" == false ]]; then
    read -p "确认执行数据库初始化? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "数据库初始化已取消"
        exit 0
    fi
fi

# 测试数据库连接
log_info "测试数据库连接..."
if ! mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" -e "SELECT 1;" &>/dev/null; then
    log_error "数据库连接失败，请检查连接参数"
    exit 1
fi
log_success "数据库连接成功"

# 删除现有数据库（如果需要）
if [[ "$DROP_DB" == true ]]; then
    log_info "删除现有数据库..."
    mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" -e "DROP DATABASE IF EXISTS $DB_NAME;"
    log_success "数据库已删除"
fi

# 执行数据库初始化
log_info "执行数据库结构初始化..."
if ! mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" < "$(dirname "$0")/init_v3.sql"; then
    log_error "数据库结构初始化失败"
    exit 1
fi
log_success "数据库结构初始化完成"

# 执行数据填充（如果需要）
if [[ "$SKIP_SEED" == false ]]; then
    log_info "执行数据填充..."
    if ! mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" < "$(dirname "$0")/seed_v3.sql"; then
        log_error "数据填充失败"
        exit 1
    fi
    log_success "数据填充完成"
fi

# 验证数据库
log_info "验证数据库..."
TABLE_COUNT=$(mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" -D "$DB_NAME" -e "SHOW TABLES;" -s -N | wc -l)
log_info "数据库表数量: $TABLE_COUNT"

if [[ "$SKIP_SEED" == false ]]; then
    USER_COUNT=$(mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" -D "$DB_NAME" -e "SELECT COUNT(*) FROM users;" -s -N)
    RESUME_COUNT=$(mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" -D "$DB_NAME" -e "SELECT COUNT(*) FROM resumes;" -s -N)
    SKILL_COUNT=$(mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" -D "$DB_NAME" -e "SELECT COUNT(*) FROM skills;" -s -N)
    COMPANY_COUNT=$(mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" -D "$DB_NAME" -e "SELECT COUNT(*) FROM companies;" -s -N)
    
    log_info "数据统计:"
    echo "  用户数量: $USER_COUNT"
    echo "  简历数量: $RESUME_COUNT"
    echo "  技能数量: $SKILL_COUNT"
    echo "  公司数量: $COMPANY_COUNT"
fi

log_success "数据库初始化完成！"
log_info "数据库名称: $DB_NAME"
log_info "连接命令: mysql -h $DB_HOST -P $DB_PORT -u $DB_USER -p $DB_NAME"
