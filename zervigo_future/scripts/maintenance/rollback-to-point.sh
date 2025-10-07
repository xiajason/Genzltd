#!/bin/bash

# JobFirst系统回滚脚本
# 用于回滚到指定的系统回滚点

set -e

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
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
    echo -e "${CYAN}JobFirst系统回滚脚本${NC}"
    echo ""
    echo "用法: $0 <回滚点ID> [选项]"
    echo ""
    echo "参数:"
    echo "  <回滚点ID>    要回滚到的回滚点ID (例如: rollback_point_20250906_131058)"
    echo ""
    echo "选项:"
    echo "  --dry-run     仅显示回滚计划，不执行实际回滚"
    echo "  --force       强制回滚，跳过确认提示"
    echo "  --help        显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 rollback_point_20250906_131058"
    echo "  $0 rollback_point_20250906_131058 --dry-run"
    echo "  $0 rollback_point_20250906_131058 --force"
    echo ""
    echo "可用的回滚点:"
    ls -1 backup/ | grep rollback_point | sed 's/^/  /'
}

# 检查回滚点是否存在
check_rollback_point() {
    local rollback_id=$1
    local rollback_path="backup/$rollback_id"
    
    if [ ! -d "$rollback_path" ]; then
        log_error "回滚点不存在: $rollback_id"
        log_info "可用的回滚点:"
        ls -1 backup/ | grep rollback_point | sed 's/^/  /'
        exit 1
    fi
    
    if [ ! -f "$rollback_path/ROLLBACK_METADATA.md" ]; then
        log_error "回滚点元数据文件不存在: $rollback_path/ROLLBACK_METADATA.md"
        exit 1
    fi
    
    log_success "回滚点验证通过: $rollback_id"
    return 0
}

# 显示回滚点信息
show_rollback_info() {
    local rollback_id=$1
    local rollback_path="backup/$rollback_id"
    
    log_info "回滚点信息:"
    echo ""
    cat "$rollback_path/ROLLBACK_METADATA.md" | head -20
    echo ""
}

# 停止当前服务
stop_current_services() {
    log_info "停止当前运行的服务..."
    
    # 停止前端服务
    if [ -f /tmp/jobfirst_frontend.pid ]; then
        FRONTEND_PID=$(cat /tmp/jobfirst_frontend.pid)
        kill $FRONTEND_PID 2>/dev/null || true
        rm -f /tmp/jobfirst_frontend.pid
        log_success "前端服务已停止"
    fi
    
    # 停止AI服务
    if [ -f /tmp/jobfirst_ai_service.pid ]; then
        AI_SERVICE_PID=$(cat /tmp/jobfirst_ai_service.pid)
        kill $AI_SERVICE_PID 2>/dev/null || true
        rm -f /tmp/jobfirst_ai_service.pid
        log_success "AI服务已停止"
    fi
    
    # 停止Resume服务
    if [ -f /tmp/jobfirst_resume_service.pid ]; then
        RESUME_SERVICE_PID=$(cat /tmp/jobfirst_resume_service.pid)
        kill $RESUME_SERVICE_PID 2>/dev/null || true
        rm -f /tmp/jobfirst_resume_service.pid
        log_success "Resume服务已停止"
    fi
    
    # 停止User服务
    if [ -f /tmp/jobfirst_user_service.pid ]; then
        USER_SERVICE_PID=$(cat /tmp/jobfirst_user_service.pid)
        kill $USER_SERVICE_PID 2>/dev/null || true
        rm -f /tmp/jobfirst_user_service.pid
        log_success "User服务已停止"
    fi
    
    # 停止API Gateway
    if [ -f /tmp/jobfirst_api_gateway.pid ]; then
        API_GATEWAY_PID=$(cat /tmp/jobfirst_api_gateway.pid)
        kill $API_GATEWAY_PID 2>/dev/null || true
        rm -f /tmp/jobfirst_api_gateway.pid
        log_success "API Gateway已停止"
    fi
    
    # 停止所有air进程
    pkill -f "air" 2>/dev/null || true
    log_success "所有air热加载进程已停止"
}

# 恢复代码
restore_code() {
    local rollback_id=$1
    local rollback_path="backup/$rollback_id"
    
    log_info "恢复代码文件..."
    
    # 备份当前代码（以防回滚失败）
    local current_backup="backup/current_before_rollback_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$current_backup"
    
    if [ -d "backend" ]; then
        cp -r backend "$current_backup/"
        log_info "当前backend代码已备份到: $current_backup"
    fi
    
    if [ -d "frontend-taro" ]; then
        cp -r frontend-taro "$current_backup/"
        log_info "当前frontend-taro代码已备份到: $current_backup"
    fi
    
    if [ -d "scripts" ]; then
        cp -r scripts "$current_backup/"
        log_info "当前scripts代码已备份到: $current_backup"
    fi
    
    # 恢复回滚点代码
    if [ -d "$rollback_path/backend" ]; then
        rm -rf backend
        cp -r "$rollback_path/backend" .
        log_success "backend代码已恢复"
    fi
    
    if [ -d "$rollback_path/frontend-taro" ]; then
        rm -rf frontend-taro
        cp -r "$rollback_path/frontend-taro" .
        log_success "frontend-taro代码已恢复"
    fi
    
    if [ -d "$rollback_path/scripts" ]; then
        rm -rf scripts
        cp -r "$rollback_path/scripts" .
        log_success "scripts代码已恢复"
    fi
    
    if [ -d "$rollback_path/nginx" ]; then
        rm -rf nginx
        cp -r "$rollback_path/nginx" .
        log_success "nginx配置已恢复"
    fi
}

# 恢复配置文件
restore_config() {
    local rollback_id=$1
    local rollback_path="backup/$rollback_id"
    
    log_info "恢复配置文件..."
    
    if [ -f "$rollback_path/docker-compose.yml" ]; then
        cp "$rollback_path/docker-compose.yml" .
        log_success "docker-compose.yml已恢复"
    fi
    
    if [ -d "$rollback_path/consul" ]; then
        rm -rf consul
        cp -r "$rollback_path/consul" .
        log_success "consul配置已恢复"
    fi
}

# 恢复数据库
restore_database() {
    local rollback_id=$1
    local rollback_path="backup/$rollback_id/database_backup"
    
    log_info "恢复数据库..."
    
    # 检查数据库服务状态
    if ! brew services list | grep mysql | grep started > /dev/null; then
        log_warning "MySQL服务未运行，启动MySQL服务..."
        brew services start mysql
        sleep 5
    fi
    
    if ! brew services list | grep postgresql | grep started > /dev/null; then
        log_warning "PostgreSQL服务未运行，启动PostgreSQL服务..."
        brew services start postgresql@14
        sleep 5
    fi
    
    if ! brew services list | grep redis | grep started > /dev/null; then
        log_warning "Redis服务未运行，启动Redis服务..."
        brew services start redis
        sleep 5
    fi
    
    # 恢复MySQL数据库
    if [ -f "$rollback_path/mysql_jobfirst_20250906_131058.sql" ]; then
        log_info "恢复MySQL数据库..."
        mysql -u root -e "DROP DATABASE IF EXISTS jobfirst; CREATE DATABASE jobfirst;"
        mysql -u root jobfirst < "$rollback_path/mysql_jobfirst_20250906_131058.sql"
        log_success "MySQL数据库已恢复"
    fi
    
    # 恢复PostgreSQL数据库
    if [ -f "$rollback_path/postgres_jobfirst_vector_20250906_131058.sql" ]; then
        log_info "恢复PostgreSQL数据库..."
        psql -U szjason72 -d postgres -c "DROP DATABASE IF EXISTS jobfirst_vector; CREATE DATABASE jobfirst_vector;"
        psql -U szjason72 jobfirst_vector < "$rollback_path/postgres_jobfirst_vector_20250906_131058.sql"
        log_success "PostgreSQL数据库已恢复"
    fi
    
    # 恢复Redis数据
    if [ -f "$rollback_path/redis_jobfirst_20250906_131058.rdb" ]; then
        log_info "恢复Redis数据..."
        redis-cli FLUSHALL
        cp "$rollback_path/redis_jobfirst_20250906_131058.rdb" /usr/local/var/db/redis/dump.rdb
        redis-cli SHUTDOWN
        brew services restart redis
        sleep 3
        log_success "Redis数据已恢复"
    fi
}

# 验证回滚结果
verify_rollback() {
    local rollback_id=$1
    
    log_info "验证回滚结果..."
    
    # 检查关键文件是否存在
    local files_to_check=(
        "backend/cmd/basic-server/main.go"
        "backend/internal/ai-service/ai_service.py"
        "frontend-taro/src/services/aiService.ts"
        "scripts/start-dev-environment.sh"
    )
    
    for file in "${files_to_check[@]}"; do
        if [ -f "$file" ]; then
            log_success "文件存在: $file"
        else
            log_error "文件不存在: $file"
            return 1
        fi
    done
    
    # 检查数据库连接
    if mysql -u root -e "USE jobfirst; SELECT 1;" > /dev/null 2>&1; then
        log_success "MySQL数据库连接正常"
    else
        log_error "MySQL数据库连接失败"
        return 1
    fi
    
    if psql -U szjason72 -d jobfirst_vector -c "SELECT 1;" > /dev/null 2>&1; then
        log_success "PostgreSQL数据库连接正常"
    else
        log_error "PostgreSQL数据库连接失败"
        return 1
    fi
    
    if redis-cli ping > /dev/null 2>&1; then
        log_success "Redis连接正常"
    else
        log_error "Redis连接失败"
        return 1
    fi
    
    log_success "回滚验证通过"
    return 0
}

# 主回滚函数
rollback_to_point() {
    local rollback_id=$1
    local dry_run=$2
    local force=$3
    
    log_info "开始回滚到: $rollback_id"
    
    if [ "$dry_run" = "true" ]; then
        log_info "=== 回滚计划 (DRY RUN) ==="
        echo "1. 停止当前运行的服务"
        echo "2. 备份当前代码到 backup/current_before_rollback_$(date +%Y%m%d_%H%M%S)"
        echo "3. 恢复代码文件从 backup/$rollback_id/"
        echo "4. 恢复配置文件从 backup/$rollback_id/"
        echo "5. 恢复数据库从 backup/$rollback_id/database_backup/"
        echo "6. 验证回滚结果"
        echo ""
        log_info "回滚计划完成 (DRY RUN)"
        return 0
    fi
    
    # 确认回滚
    if [ "$force" != "true" ]; then
        echo ""
        log_warning "⚠️  即将回滚到: $rollback_id"
        log_warning "⚠️  当前代码将被备份，然后替换为回滚点代码"
        log_warning "⚠️  数据库将被恢复到回滚点状态"
        echo ""
        read -p "确认继续回滚? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "回滚已取消"
            exit 0
        fi
    fi
    
    # 执行回滚步骤
    log_info "=== 开始执行回滚 ==="
    
    # 1. 停止当前服务
    stop_current_services
    
    # 2. 恢复代码
    restore_code "$rollback_id"
    
    # 3. 恢复配置
    restore_config "$rollback_id"
    
    # 4. 恢复数据库
    restore_database "$rollback_id"
    
    # 5. 验证回滚结果
    if verify_rollback "$rollback_id"; then
        log_success "=== 回滚完成 ==="
        log_info "系统已成功回滚到: $rollback_id"
        log_info "可以使用以下命令启动系统:"
        log_info "  ./scripts/start-dev-environment.sh start"
        log_info "  ./scripts/start-dev-environment.sh health"
    else
        log_error "=== 回滚失败 ==="
        log_error "回滚过程中出现错误，请检查日志"
        exit 1
    fi
}

# 主函数
main() {
    local rollback_id=""
    local dry_run="false"
    local force="false"
    
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                dry_run="true"
                shift
                ;;
            --force)
                force="true"
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                if [ -z "$rollback_id" ]; then
                    rollback_id="$1"
                else
                    log_error "未知参数: $1"
                    show_help
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # 检查参数
    if [ -z "$rollback_id" ]; then
        log_error "请指定回滚点ID"
        show_help
        exit 1
    fi
    
    # 检查回滚点
    if ! check_rollback_point "$rollback_id"; then
        exit 1
    fi
    
    # 显示回滚点信息
    show_rollback_info "$rollback_id"
    
    # 执行回滚
    rollback_to_point "$rollback_id" "$dry_run" "$force"
}

# 执行主函数
main "$@"
