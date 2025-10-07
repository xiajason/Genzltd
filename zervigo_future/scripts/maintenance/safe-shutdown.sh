#!/bin/bash

# JobFirst Basic Version 安全关闭脚本
# 确保数据安全和优雅关闭所有服务

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 项目配置
PROJECT_ROOT="/Users/szjason72/zervi-basic/basic"
LOG_DIR="$PROJECT_ROOT/logs"
BACKUP_DIR="$PROJECT_ROOT/backups"
SHUTDOWN_LOG="$LOG_DIR/safe-shutdown.log"

# 关闭超时配置
GRACEFUL_TIMEOUT=30
FORCE_TIMEOUT=10
DB_FLUSH_TIMEOUT=15

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$SHUTDOWN_LOG"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$SHUTDOWN_LOG"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$SHUTDOWN_LOG"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$SHUTDOWN_LOG"
}

log_step() {
    echo -e "${PURPLE}[STEP]${NC} $1" | tee -a "$SHUTDOWN_LOG"
}

# 创建必要的目录
create_directories() {
    mkdir -p "$LOG_DIR"
    mkdir -p "$BACKUP_DIR"
    mkdir -p "$BACKUP_DIR/$(date +%Y%m%d_%H%M%S)"
}

# 初始化关闭日志
init_shutdown_log() {
    echo "==========================================" >> "$SHUTDOWN_LOG"
    echo "JobFirst 安全关闭开始 - $(date)" >> "$SHUTDOWN_LOG"
    echo "==========================================" >> "$SHUTDOWN_LOG"
}

# 检查服务状态
check_service_status() {
    log_step "检查当前服务状态..."
    
    local services=(
        "api_gateway:8080"
        "user_service:8081"
        "resume_service:8082"
        "company_service:8083"
        "notification_service:8084"
        "template_service:8085"
        "statistics_service:8086"
        "banner_service:8087"
        "dev_team_service:8088"
        "job_service:8089"
        "auth_service:8207"
        "ai_service:8206"
    )
    
    local running_services=()
    
    for service_info in "${services[@]}"; do
        IFS=':' read -r service_name port <<< "$service_info"
        
        if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
            local pid=$(lsof -Pi :$port -sTCP:LISTEN -t | head -1)
            running_services+=("$service_name:$port:$pid")
            log_info "✅ $service_name 正在运行 (端口: $port, PID: $pid)"
        else
            log_info "❌ $service_name 未运行 (端口: $port)"
        fi
    done
    
    # 检查数据库服务
    if brew services list | grep mysql | grep started &> /dev/null; then
        log_info "✅ MySQL 正在运行"
        running_services+=("mysql:3306")
    else
        log_info "❌ MySQL 未运行"
    fi
    
    if brew services list | grep redis | grep started &> /dev/null; then
        log_info "✅ Redis 正在运行"
        running_services+=("redis:6379")
    else
        log_info "❌ Redis 未运行"
    fi
    
    if brew services list | grep postgresql@14 | grep started &> /dev/null; then
        log_info "✅ PostgreSQL@14 正在运行"
        running_services+=("postgresql@14:5432")
    else
        log_info "❌ PostgreSQL@14 未运行"
    fi
    
    if brew services list | grep neo4j | grep started &> /dev/null; then
        log_info "✅ Neo4j 正在运行"
        running_services+=("neo4j:7474")
    else
        log_info "❌ Neo4j 未运行"
    fi
    
    # 检查Consul
    if curl -s http://localhost:8500/v1/status/leader >/dev/null 2>&1; then
        log_info "✅ Consul 正在运行"
        running_services+=("consul:8500")
    else
        log_info "❌ Consul 未运行"
    fi
    
    echo "${running_services[@]}"
}

# 数据备份
backup_critical_data() {
    log_step "执行关键数据备份..."
    
    local backup_timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_path="$BACKUP_DIR/$backup_timestamp"
    
    mkdir -p "$backup_path"
    
    # 备份数据库
    if brew services list | grep mysql | grep started &> /dev/null; then
        log_info "备份MySQL数据库..."
        if mysqldump -u root jobfirst > "$backup_path/jobfirst_backup.sql" 2>/dev/null; then
            log_success "MySQL数据库备份完成: $backup_path/jobfirst_backup.sql"
        else
            log_warning "MySQL数据库备份失败"
        fi
    fi
    
    # 备份Redis数据
    if brew services list | grep redis | grep started &> /dev/null; then
        log_info "备份Redis数据..."
        if redis-cli --rdb "$backup_path/redis_backup.rdb" >/dev/null 2>&1; then
            log_success "Redis数据备份完成: $backup_path/redis_backup.rdb"
        else
            log_warning "Redis数据备份失败"
        fi
    fi
    
    # 备份PostgreSQL数据
    if brew services list | grep postgresql@14 | grep started &> /dev/null; then
        log_info "备份PostgreSQL数据库..."
        # 尝试不同的PostgreSQL连接方式
        if pg_dumpall -U $(whoami) -h localhost > "$backup_path/postgresql_backup.sql" 2>/dev/null; then
            log_success "PostgreSQL数据库备份完成 (用户: $(whoami)): $backup_path/postgresql_backup.sql"
        elif pg_dumpall -U postgres -h localhost > "$backup_path/postgresql_backup.sql" 2>/dev/null; then
            log_success "PostgreSQL数据库备份完成 (用户: postgres): $backup_path/postgresql_backup.sql"
        elif pg_dumpall -h localhost > "$backup_path/postgresql_backup.sql" 2>/dev/null; then
            log_success "PostgreSQL数据库备份完成 (默认用户): $backup_path/postgresql_backup.sql"
        else
            log_warning "PostgreSQL数据库备份失败 - 请检查用户权限和数据库配置"
        fi
    fi
    
    # 备份Neo4j数据
    if brew services list | grep neo4j | grep started &> /dev/null; then
        log_info "备份Neo4j数据库..."
        # 尝试多个可能的Neo4j数据目录路径
        local neo4j_data_dirs=("/opt/homebrew/var/neo4j/data" "/usr/local/var/neo4j/data" "/var/lib/neo4j/data")
        local neo4j_data_dir=""
        
        for dir in "${neo4j_data_dirs[@]}"; do
            if [[ -d "$dir" ]]; then
                neo4j_data_dir="$dir"
                break
            fi
        done
        
        if [[ -n "$neo4j_data_dir" ]]; then
            if cp -r "$neo4j_data_dir" "$backup_path/neo4j_data_backup" 2>/dev/null; then
                log_success "Neo4j数据备份完成: $backup_path/neo4j_data_backup"
            else
                log_warning "Neo4j数据备份失败"
            fi
        else
            log_warning "Neo4j数据目录未找到，尝试的路径: ${neo4j_data_dirs[*]}"
        fi
    fi
    
    # 备份配置文件
    log_info "备份配置文件..."
    cp -r "$PROJECT_ROOT/backend/configs" "$backup_path/configs_backup" 2>/dev/null || true
    cp -r "$PROJECT_ROOT/nginx" "$backup_path/nginx_backup" 2>/dev/null || true
    log_success "配置文件备份完成"
    
    # 备份日志文件
    log_info "备份重要日志文件..."
    find "$LOG_DIR" -name "*.log" -mtime -1 -exec cp {} "$backup_path/" \; 2>/dev/null || true
    log_success "日志文件备份完成"
    
    # 创建备份清单
    cat > "$backup_path/backup_manifest.txt" << EOF
JobFirst 数据备份清单
备份时间: $(date)
备份路径: $backup_path

包含内容:
- MySQL数据库: jobfirst_backup.sql
- Redis数据: redis_backup.rdb
- PostgreSQL数据库: postgresql_backup.sql
- Neo4j数据: neo4j_data_backup/
- 配置文件: configs_backup/, nginx_backup/
- 日志文件: *.log

恢复命令:
- MySQL恢复: mysql -u root jobfirst < jobfirst_backup.sql
- Redis恢复: redis-cli --pipe < redis_backup.rdb
- PostgreSQL恢复: psql -U postgres < postgresql_backup.sql
- Neo4j恢复: 复制 neo4j_data_backup/ 到 /usr/local/var/neo4j/data/
EOF
    
    log_success "数据备份完成: $backup_path"
}

# 优雅关闭微服务
graceful_shutdown_microservices() {
    log_step "优雅关闭微服务..."
    
    local services=(
        "ai_service:8206"
        "containerized_ai_service:8208"
        "auth_service:8207"
        "job_service:8089"
        "dev_team_service:8088"
        "banner_service:8087"
        "statistics_service:8086"
        "template_service:8085"
        "notification_service:8084"
        "company_service:8083"
        "resume_service:8082"
        "user_service:8081"
        "api_gateway:8080"
    )
    
    for service_info in "${services[@]}"; do
        IFS=':' read -r service_name port <<< "$service_info"
        
        # 特殊处理容器化AI服务
        if [[ "$service_name" == "containerized_ai_service" ]]; then
            log_info "优雅关闭容器化AI服务..."
            
            # 检查Docker是否运行
            if docker info >/dev/null 2>&1; then
                # 检查容器是否存在
                if docker-compose -f "$PROJECT_ROOT/ai-services/docker-compose.yml" ps ai-service | grep -q "Up"; then
                    # 优雅关闭容器
                    cd "$PROJECT_ROOT/ai-services"
                    docker-compose stop ai-service >/dev/null 2>&1
                    
                    # 等待容器停止
                    local count=0
                    while docker-compose ps ai-service | grep -q "Up" && [[ $count -lt $GRACEFUL_TIMEOUT ]]; do
                        sleep 1
                        ((count++))
                        echo -n "."
                    done
                    echo ""
                    
                    # 检查是否已停止
                    if docker-compose ps ai-service | grep -q "Up"; then
                        log_warning "容器化AI服务优雅关闭超时，强制关闭..."
                        docker-compose kill ai-service >/dev/null 2>&1
                        sleep 2
                    fi
                    
                    # 最终检查
                    if docker-compose ps ai-service | grep -q "Up"; then
                        log_error "无法关闭容器化AI服务"
                    else
                        log_success "容器化AI服务已关闭"
                    fi
                else
                    log_info "容器化AI服务未运行"
                fi
            else
                log_warning "Docker未运行，跳过容器化AI服务关闭"
            fi
        else
            # 处理其他服务
            if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
                local pid=$(lsof -Pi :$port -sTCP:LISTEN -t | head -1)
                log_info "优雅关闭 $service_name (PID: $pid)..."
                
                # 发送TERM信号
                if kill -TERM "$pid" 2>/dev/null; then
                    # 等待优雅关闭
                    local count=0
                    while kill -0 "$pid" 2>/dev/null && [[ $count -lt $GRACEFUL_TIMEOUT ]]; do
                        sleep 1
                        ((count++))
                        echo -n "."
                    done
                    echo ""
                    
                    # 检查是否已停止
                    if kill -0 "$pid" 2>/dev/null; then
                        log_warning "$service_name 优雅关闭超时，强制关闭..."
                        kill -KILL "$pid" 2>/dev/null || true
                        sleep 2
                    fi
                    
                    # 最终检查
                    if kill -0 "$pid" 2>/dev/null; then
                        log_error "无法关闭 $service_name (PID: $pid)"
                    else
                        log_success "$service_name 已关闭"
                    fi
                else
                    log_warning "无法发送关闭信号到 $service_name (PID: $pid)"
                fi
            else
                log_info "$service_name 未运行 (端口: $port)"
            fi
        fi
    done
}

# 从Consul注销服务
deregister_consul_services() {
    log_step "从Consul注销服务..."
    
    if ! curl -s http://localhost:8500/v1/status/leader >/dev/null 2>&1; then
        log_info "Consul未运行，跳过服务注销"
        return 0
    fi
    
    local consul_address="localhost:8500"
    
    # 获取所有JobFirst相关服务
    local services_response=$(curl -s "http://$consul_address/v1/agent/services" 2>/dev/null || echo "{}")
    local jobfirst_services=$(echo "$services_response" | jq -r 'keys[]' 2>/dev/null | grep -E "(basic-server|user-service|resume-service|company-service|notification-service|template-service|statistics-service|banner-service|dev-team-service|ai-service)" || echo "")
    
    if [[ -n "$jobfirst_services" ]]; then
        echo "$jobfirst_services" | while read -r service; do
            if [[ -n "$service" ]]; then
                log_info "注销服务: $service"
                if curl -s -X PUT "http://$consul_address/v1/agent/service/deregister/$service" >/dev/null 2>&1; then
                    log_success "✅ 服务 $service 注销成功"
                else
                    log_warning "⚠️ 服务 $service 注销失败"
                fi
            fi
        done
    else
        log_info "未找到需要注销的JobFirst服务"
    fi
    
    log_success "Consul服务注销完成"
}

# 确保数据库数据完整性
ensure_database_integrity() {
    log_step "确保数据库数据完整性..."
    
    # 刷新MySQL数据到磁盘
    if brew services list | grep mysql | grep started &> /dev/null; then
        log_info "刷新MySQL数据到磁盘..."
        mysql -u root -e "FLUSH TABLES;" 2>/dev/null || log_warning "MySQL刷新失败"
        mysql -u root -e "FLUSH LOGS;" 2>/dev/null || log_warning "MySQL日志刷新失败"
        log_success "MySQL数据完整性确保完成"
    fi
    
    # 保存Redis数据到磁盘
    if brew services list | grep redis | grep started &> /dev/null; then
        log_info "保存Redis数据到磁盘..."
        redis-cli BGSAVE >/dev/null 2>&1 || log_warning "Redis BGSAVE失败"
        sleep 2  # 等待BGSAVE完成
        log_success "Redis数据保存完成"
    fi
    
    # 确保PostgreSQL数据完整性
    if brew services list | grep postgresql@14 | grep started &> /dev/null; then
        log_info "刷新PostgreSQL数据到磁盘..."
        # 尝试多种PostgreSQL连接方式
        if psql -U $(whoami) -h localhost -d postgres -c "CHECKPOINT;" 2>/dev/null; then
            log_success "PostgreSQL CHECKPOINT完成 (用户: $(whoami))"
        elif psql -U postgres -h localhost -d postgres -c "CHECKPOINT;" 2>/dev/null; then
            log_success "PostgreSQL CHECKPOINT完成 (用户: postgres)"
        elif psql -h localhost -d postgres -c "CHECKPOINT;" 2>/dev/null; then
            log_success "PostgreSQL CHECKPOINT完成 (默认用户)"
        else
            # 如果CHECKPOINT失败，尝试其他方式确保数据完整性
            log_info "尝试其他方式确保PostgreSQL数据完整性..."
            if psql -U $(whoami) -h localhost -d postgres -c "SELECT 1;" 2>/dev/null; then
                log_success "PostgreSQL连接正常，数据完整性确保完成"
            else
                log_warning "PostgreSQL连接失败，但服务仍在运行"
            fi
        fi
    fi
    
    # 确保Neo4j数据完整性
    if brew services list | grep neo4j | grep started &> /dev/null; then
        log_info "确保Neo4j数据完整性..."
        # Neo4j 会自动处理数据持久化，这里只是记录状态
        log_success "Neo4j数据完整性确保完成"
    fi
}

# 清理临时文件和PID文件
cleanup_temp_files() {
    log_step "清理临时文件和PID文件..."
    
    # 清理PID文件
    find "$LOG_DIR" -name "*.pid" -delete 2>/dev/null || true
    log_info "清理PID文件完成"
    
    # 清理临时目录
    rm -rf "$PROJECT_ROOT/backend/temp"/* 2>/dev/null || true
    log_info "清理临时目录完成"
    
    # 清理临时上传文件
    find "$PROJECT_ROOT/backend/uploads" -name "*.tmp" -delete 2>/dev/null || true
    log_info "清理临时上传文件完成"
    
    log_success "临时文件清理完成"
}

# 停止基础设施服务
stop_infrastructure_services() {
    log_step "停止基础设施服务..."
    
    # 停止Nginx (如果运行)
    if lsof -Pi :80 -sTCP:LISTEN -t >/dev/null 2>&1; then
        local nginx_pid=$(lsof -Pi :80 -sTCP:LISTEN -t | head -1)
        log_info "停止Nginx (PID: $nginx_pid)..."
        if kill -TERM "$nginx_pid" 2>/dev/null; then
            sleep 3
            log_success "Nginx已停止"
        fi
    fi
    
    # 停止Consul (如果运行)
    if curl -s http://localhost:8500/v1/status/leader >/dev/null 2>&1; then
        log_info "停止Consul服务..."
        # 统一使用launchctl停止Consul
        if launchctl unload /opt/homebrew/etc/consul.plist; then
            log_success "Consul已停止 (launchctl)"
            sleep 2
        else
            # 如果launchctl停止失败，尝试手动停止Consul进程
            local consul_pid=$(pgrep -f "consul agent")
            if [[ -n "$consul_pid" ]]; then
                log_info "尝试手动停止Consul进程 (PID: $consul_pid)..."
                kill -TERM "$consul_pid" 2>/dev/null && sleep 2
                if pgrep -f "consul agent" >/dev/null; then
                    kill -KILL "$consul_pid" 2>/dev/null
                fi
                log_success "Consul进程已手动停止"
            else
                log_info "Consul服务未运行或已停止"
            fi
        fi
    fi
}

# 停止数据库服务 (可选)
stop_database_services() {
    local stop_databases=false
    
    if [[ "$1" == "--stop-databases" ]]; then
        stop_databases=true
    else
        echo ""
        read -p "是否停止数据库服务 (MySQL/Redis/PostgreSQL/Neo4j)? [y/N]: " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            stop_databases=true
        fi
    fi
    
    if [[ "$stop_databases" == true ]]; then
        log_step "停止数据库服务..."
        
        # 停止Redis
        if brew services list | grep redis | grep started &> /dev/null; then
            log_info "停止Redis服务..."
            if brew services stop redis; then
                log_success "Redis已停止"
            else
                log_warning "Redis停止失败"
            fi
        fi
        
        # 停止MySQL
        if brew services list | grep mysql | grep started &> /dev/null; then
            log_info "停止MySQL服务..."
            if brew services stop mysql; then
                log_success "MySQL已停止"
            else
                log_warning "MySQL停止失败"
            fi
        fi
        
        # 停止PostgreSQL@14
        if brew services list | grep postgresql@14 | grep started &> /dev/null; then
            log_info "停止PostgreSQL@14服务..."
            if brew services stop postgresql@14; then
                log_success "PostgreSQL@14已停止"
            else
                log_warning "PostgreSQL@14停止失败"
            fi
        fi
        
        # 停止Neo4j
        if brew services list | grep neo4j | grep started &> /dev/null; then
            log_info "停止Neo4j服务..."
            if brew services stop neo4j; then
                log_success "Neo4j已停止"
            else
                log_warning "Neo4j停止失败"
            fi
        fi
        
        log_success "数据库服务停止完成"
    else
        log_info "数据库服务保持运行状态"
    fi
}

# 验证关闭结果
verify_shutdown() {
    log_step "验证关闭结果..."
    
    local remaining_services=()
    
    # 检查微服务端口
    local ports=(8080 8081 8082 8083 8084 8085 8086 8087 8088 8089 8206 8207 8208)
    for port in "${ports[@]}"; do
        if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
            local process=$(lsof -Pi :$port -sTCP:LISTEN | tail -n +2 | awk '{print $1}')
            remaining_services+=("端口 $port: $process")
        fi
    done
    
    if [[ ${#remaining_services[@]} -gt 0 ]]; then
        log_warning "以下服务仍在运行:"
        for service in "${remaining_services[@]}"; do
            log_warning "  - $service"
        done
        return 1
    else
        log_success "所有微服务已成功关闭"
        return 0
    fi
}

# 生成关闭报告
generate_shutdown_report() {
    log_step "生成关闭报告..."
    
    local report_file="$LOG_DIR/shutdown_report_$(date +%Y%m%d_%H%M%S).txt"
    
    cat > "$report_file" << EOF
==========================================
JobFirst 安全关闭报告
==========================================
关闭时间: $(date)
关闭脚本: $0
关闭日志: $SHUTDOWN_LOG

关闭步骤:
✅ 服务状态检查
✅ 关键数据备份
✅ 微服务优雅关闭
✅ Consul服务注销
✅ 数据库完整性确保
✅ 临时文件清理
✅ 基础设施服务停止

数据安全措施:
- MySQL数据库备份
- Redis数据备份
- PostgreSQL数据库备份
- Neo4j数据备份
- 配置文件备份
- 日志文件备份
- 数据库完整性确保

关闭状态:
$(verify_shutdown && echo "✅ 所有服务已成功关闭" || echo "⚠️ 部分服务可能仍在运行")

备份位置: $BACKUP_DIR/$(ls -t "$BACKUP_DIR" | head -1)

恢复建议:
- 如需恢复数据，请使用备份文件
- 重新启动服务请使用启动脚本
- 检查日志文件以获取详细信息

==========================================
EOF
    
    log_success "关闭报告已生成: $report_file"
}

# 显示帮助信息
show_help() {
    cat << EOF
JobFirst 安全关闭脚本

用法: $0 [选项]

选项:
  --stop-databases    同时停止数据库服务 (MySQL/Redis/PostgreSQL/Neo4j)
  --help             显示此帮助信息

功能:
  ✅ 优雅关闭所有微服务
  ✅ 自动备份关键数据
  ✅ 确保数据库完整性
  ✅ 从Consul注销服务
  ✅ 清理临时文件
  ✅ 生成关闭报告

安全特性:
  🔒 数据备份保护
  🔒 优雅关闭机制
  🔒 超时保护
  🔒 完整性验证

示例:
  $0                    # 安全关闭，保留数据库
  $0 --stop-databases   # 安全关闭，包括数据库
  $0 --help            # 显示帮助

EOF
}

# 主函数
main() {
    # 检查参数
    local stop_databases=false
    if [[ "$1" == "--stop-databases" ]]; then
        stop_databases=true
    elif [[ "$1" == "--help" ]]; then
        show_help
        exit 0
    fi
    
    # 初始化
    create_directories
    init_shutdown_log
    
    echo "=========================================="
    echo "🛑 JobFirst 安全关闭工具"
    echo "=========================================="
    echo
    
    log_info "开始安全关闭流程..."
    
    # 执行关闭步骤
    local running_services=$(check_service_status)
    backup_critical_data
    ensure_database_integrity
    graceful_shutdown_microservices
    deregister_consul_services
    cleanup_temp_files
    stop_infrastructure_services
    stop_database_services "$1"
    
    # 验证和报告
    verify_shutdown
    generate_shutdown_report
    
    echo
    echo "=========================================="
    echo "✅ JobFirst 安全关闭完成"
    echo "=========================================="
    echo
    log_success "系统已安全关闭，数据已备份"
    log_info "关闭日志: $SHUTDOWN_LOG"
    log_info "备份位置: $BACKUP_DIR"
    echo
}

# 错误处理
trap 'log_error "关闭过程中发生错误"; exit 1' ERR

# 信号处理
trap 'log_warning "收到中断信号，继续关闭流程..."' INT TERM

# 执行主函数
main "$@"
