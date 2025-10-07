#!/bin/bash

# LoomaCRM AI版容器化服务关闭脚本
# 提供安全、优雅的关闭流程

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 获取脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# 日志文件
LOG_FILE="$PROJECT_ROOT/logs/shutdown_looma_crm_ai.log"

# 确保日志目录存在
mkdir -p "$(dirname "$LOG_FILE")"

# 日志函数
log_info() {
    local message="$1"
    echo -e "${BLUE}[INFO]${NC} $message"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] $message" >> "$LOG_FILE"
}

log_success() {
    local message="$1"
    echo -e "${GREEN}[SUCCESS]${NC} $message"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [SUCCESS] $message" >> "$LOG_FILE"
}

log_warning() {
    local message="$1"
    echo -e "${YELLOW}[WARNING]${NC} $message"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [WARNING] $message" >> "$LOG_FILE"
}

log_error() {
    local message="$1"
    echo -e "${RED}[ERROR]${NC} $message"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] $message" >> "$LOG_FILE"
}

log_step() {
    local message="$1"
    echo -e "${PURPLE}[STEP]${NC} $message"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [STEP] $message" >> "$LOG_FILE"
}

# 显示帮助信息
show_help() {
    echo -e "${CYAN}LoomaCRM AI版容器化服务关闭脚本${NC}"
    echo "=========================================="
    echo ""
    echo "用法: $0 [选项] [服务类型]"
    echo ""
    echo "服务类型:"
    echo "  all             关闭所有服务 (默认)"
    echo "  api             仅关闭API服务"
    echo "  database        仅关闭数据库容器"
    echo "  monitoring      仅关闭监控服务"
    echo ""
    echo "选项:"
    echo "  --force         强制关闭，跳过确认"
    echo "  --graceful      优雅关闭 (默认)"
    echo "  --immediate     立即关闭"
    echo "  --cleanup       关闭后清理资源"
    echo "  --backup        关闭前备份数据"
    echo "  --verbose       详细输出"
    echo "  --help          显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0                           # 关闭所有服务"
    echo "  $0 api                       # 仅关闭API服务"
    echo "  $0 database --force          # 强制关闭数据库"
    echo "  $0 all --backup --cleanup    # 备份后关闭所有服务并清理"
    echo ""
}

# 检查服务是否运行
check_service_running() {
    local port=$1
    local service_name=$2
    
    if lsof -i :$port > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# 检查容器是否运行
check_container_running() {
    local container_name=$1
    
    if docker ps --format "table {{.Names}}" | grep -q "^${container_name}$"; then
        return 0
    else
        return 1
    fi
}

# 优雅关闭API服务
graceful_shutdown_api_service() {
    local service_name=$1
    local port=$2
    local stop_script_path=$3
    
    log_info "优雅关闭 $service_name..."
    
    # 直接使用强制关闭，避免调用可能有问题的stop.sh脚本
    force_shutdown_api_service "$service_name" "$port"
}

# 强制关闭API服务
force_shutdown_api_service() {
    local service_name=$1
    local port=$2
    
    log_warning "强制关闭 $service_name (端口 $port)..."
    
    # 查找占用端口的进程
    local pid=$(lsof -ti :$port)
    if [ -n "$pid" ]; then
        log_info "找到进程 PID: $pid"
        kill -TERM "$pid" 2>/dev/null
        sleep 3
        
        # 检查进程是否还在运行
        if kill -0 "$pid" 2>/dev/null; then
            log_warning "进程仍在运行，使用 SIGKILL"
            kill -KILL "$pid" 2>/dev/null
        fi
        
        log_success "$service_name 已强制关闭"
    else
        log_info "$service_name 未运行"
    fi
}

# 关闭API服务
shutdown_api_services() {
    log_step "关闭API服务..."
    
    local api_services=(
        "API网关:9000:$PROJECT_ROOT/api-services/looma-api-gateway/scripts/stop.sh"
        "用户API:9001:$PROJECT_ROOT/api-services/looma-user-api/scripts/stop.sh"
        "简历API:9002:$PROJECT_ROOT/api-services/looma-resume-api/scripts/stop.sh"
        "公司API:9003:$PROJECT_ROOT/api-services/looma-company-api/scripts/stop.sh"
        "职位API:9004:$PROJECT_ROOT/api-services/looma-job-api/scripts/stop.sh"
    )
    
    for service_info in "${api_services[@]}"; do
        IFS=':' read -r name port stop_script <<< "$service_info"
        
        if check_service_running "$port" "$name"; then
            if [ "$SHUTDOWN_MODE" = "immediate" ]; then
                force_shutdown_api_service "$name" "$port"
            else
                graceful_shutdown_api_service "$name" "$port" "$stop_script"
            fi
        else
            log_info "$name 未运行"
        fi
    done
    
    log_success "API服务关闭完成"
}

# 优雅关闭数据库容器
graceful_shutdown_database_containers() {
    log_step "优雅关闭数据库容器..."
    
    if [ ! -f "$PROJECT_ROOT/docker-compose.database.yml" ]; then
        log_error "Docker Compose配置文件不存在"
        return 1
    fi
    
    cd "$PROJECT_ROOT"
    
    # 发送SIGTERM信号给容器
    log_info "发送优雅关闭信号..."
    docker-compose -f docker-compose.database.yml stop
    
    # 等待容器优雅关闭
    log_info "等待容器优雅关闭..."
    sleep 10
    
    # 检查容器状态
    local running_containers=$(docker-compose -f docker-compose.database.yml ps -q | wc -l)
    if [ "$running_containers" -gt 0 ]; then
        log_warning "部分容器仍在运行，强制关闭..."
        docker-compose -f docker-compose.database.yml kill
        sleep 5
    fi
    
    log_success "数据库容器已优雅关闭"
}

# 强制关闭数据库容器
force_shutdown_database_containers() {
    log_step "强制关闭数据库容器..."
    
    if [ ! -f "$PROJECT_ROOT/docker-compose.database.yml" ]; then
        log_error "Docker Compose配置文件不存在"
        return 1
    fi
    
    cd "$PROJECT_ROOT"
    
    # 强制停止并删除容器
    docker-compose -f docker-compose.database.yml kill
    docker-compose -f docker-compose.database.yml rm -f
    
    log_success "数据库容器已强制关闭"
}

# 关闭数据库容器
shutdown_database_containers() {
    if [ "$SHUTDOWN_MODE" = "immediate" ]; then
        force_shutdown_database_containers
    else
        graceful_shutdown_database_containers
    fi
}

# 关闭监控服务
shutdown_monitoring_services() {
    log_step "关闭监控服务..."
    
    local monitoring_containers=("looma-prometheus" "looma-grafana")
    
    for container in "${monitoring_containers[@]}"; do
        if check_container_running "$container"; then
            log_info "关闭 $container..."
            docker stop "$container" 2>/dev/null
            if [ $? -eq 0 ]; then
                log_success "$container 已关闭"
            else
                log_warning "$container 关闭失败"
            fi
        else
            log_info "$container 未运行"
        fi
    done
    
    log_success "监控服务关闭完成"
}

# 备份数据
backup_data() {
    log_step "备份数据..."
    
    local backup_dir="$PROJECT_ROOT/backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    # 备份数据库数据
    if [ -d "$PROJECT_ROOT/docker/volumes" ]; then
        log_info "备份数据库数据..."
        cp -r "$PROJECT_ROOT/docker/volumes" "$backup_dir/"
        log_success "数据库数据已备份到: $backup_dir"
    fi
    
    # 备份配置文件
    if [ -f "$PROJECT_ROOT/docker-compose.database.yml" ]; then
        log_info "备份配置文件..."
        cp "$PROJECT_ROOT/docker-compose.database.yml" "$backup_dir/"
        log_success "配置文件已备份"
    fi
    
    log_success "数据备份完成: $backup_dir"
}

# 清理资源
cleanup_resources() {
    log_step "清理资源..."
    
    # 清理停止的容器
    log_info "清理停止的容器..."
    docker container prune -f
    
    # 清理未使用的网络
    log_info "清理未使用的网络..."
    docker network prune -f
    
    # 清理未使用的卷
    log_info "清理未使用的卷..."
    docker volume prune -f
    
    # 清理未使用的镜像
    log_info "清理未使用的镜像..."
    docker image prune -f
    
    log_success "资源清理完成"
}

# 显示关闭状态
show_shutdown_status() {
    log_step "检查关闭状态..."
    
    echo ""
    echo -e "${CYAN}=== API服务状态 ===${NC}"
    local api_ports=(9000 9001 9002 9003 9004)
    local api_names=("API网关" "用户API" "简历API" "公司API" "职位API")
    
    for i in "${!api_ports[@]}"; do
        local port=${api_ports[$i]}
        local name=${api_names[$i]}
        if check_service_running "$port" "$name"; then
            log_warning "$name (端口$port) - 仍在运行"
        else
            log_success "$name (端口$port) - 已关闭"
        fi
    done
    
    echo ""
    echo -e "${CYAN}=== 数据库容器状态 ===${NC}"
    if [ -f "$PROJECT_ROOT/docker-compose.database.yml" ]; then
        cd "$PROJECT_ROOT"
        docker-compose -f docker-compose.database.yml ps
    else
        log_warning "Docker Compose配置文件不存在"
    fi
    
    echo ""
    echo -e "${CYAN}=== 系统资源使用 ===${NC}"
    if command -v docker &> /dev/null; then
        docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}" 2>/dev/null || log_info "无运行中的容器"
    fi
}

# 确认关闭操作
confirm_shutdown() {
    local service_type="$1"
    
    if [ "$FORCE_MODE" = true ]; then
        return 0
    fi
    
    echo ""
    echo -e "${YELLOW}⚠️  确认关闭操作${NC}"
    echo "=================================="
    echo "服务类型: $service_type"
    echo "关闭模式: $SHUTDOWN_MODE"
    echo "备份数据: $([ "$BACKUP_MODE" = true ] && echo "是" || echo "否")"
    echo "清理资源: $([ "$CLEANUP_MODE" = true ] && echo "是" || echo "否")"
    echo ""
    
    read -p "确认执行关闭操作? (y/N): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        return 0
    else
        log_info "操作已取消"
        exit 0
    fi
}

# 主函数
main() {
    local service_type="all"
    local force_mode=false
    local graceful_mode=true
    local immediate_mode=false
    local cleanup_mode=false
    local backup_mode=false
    local verbose_mode=false
    
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            --force)
                force_mode=true
                shift
                ;;
            --graceful)
                graceful_mode=true
                immediate_mode=false
                shift
                ;;
            --immediate)
                immediate_mode=true
                graceful_mode=false
                shift
                ;;
            --cleanup)
                cleanup_mode=true
                shift
                ;;
            --backup)
                backup_mode=true
                shift
                ;;
            --verbose)
                verbose_mode=true
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            all|api|database|monitoring)
                service_type="$1"
                shift
                ;;
            *)
                log_error "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # 设置全局变量
    FORCE_MODE="$force_mode"
    SHUTDOWN_MODE="$([ "$immediate_mode" = true ] && echo "immediate" || echo "graceful")"
    CLEANUP_MODE="$cleanup_mode"
    BACKUP_MODE="$backup_mode"
    VERBOSE_MODE="$verbose_mode"
    
    # 显示开始信息
    echo -e "${CYAN}LoomaCRM AI版容器化服务关闭脚本${NC}"
    echo "=========================================="
    echo "开始时间: $(date)"
    echo "服务类型: $service_type"
    echo "关闭模式: $SHUTDOWN_MODE"
    echo "强制模式: $([ "$FORCE_MODE" = true ] && echo "是" || echo "否")"
    echo ""
    
    # 确认操作
    confirm_shutdown "$service_type"
    
    # 备份数据
    if [ "$BACKUP_MODE" = true ]; then
        backup_data
    fi
    
    # 根据服务类型执行关闭操作
    case "$service_type" in
        all)
            shutdown_api_services
            shutdown_database_containers
            shutdown_monitoring_services
            ;;
        api)
            shutdown_api_services
            ;;
        database)
            shutdown_database_containers
            ;;
        monitoring)
            shutdown_monitoring_services
            ;;
    esac
    
    # 清理资源
    if [ "$CLEANUP_MODE" = true ]; then
        cleanup_resources
    fi
    
    # 显示关闭状态
    show_shutdown_status
    
    # 完成信息
    echo ""
    log_success "LoomaCRM AI版容器化服务关闭完成"
    echo "结束时间: $(date)"
    echo "日志文件: $LOG_FILE"
}

# 检查参数
if [ $# -eq 0 ]; then
    show_help
    exit 1
fi

# 执行主函数
main "$@"
