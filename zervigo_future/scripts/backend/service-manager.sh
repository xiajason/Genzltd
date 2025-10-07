#!/bin/bash

# 腾讯云微服务管理脚本
# 用于服务启停、依赖管理和健康检查

set -e

# 配置
DEPLOY_DIR="/opt/jobfirst"
LOG_FILE="/opt/jobfirst/logs/service-manager.log"

# 服务依赖关系
declare -A SERVICE_DEPENDENCIES=(
    ["basic-server"]="mysql redis consul"
    ["user-service"]="mysql redis consul"
    ["ai-service"]="postgresql redis"
    ["resume"]="mysql redis consul"
    ["company-service"]="mysql redis consul"
    ["notification-service"]="mysql redis consul"
    ["banner-service"]="mysql redis consul"
    ["statistics-service"]="mysql redis consul"
    ["template-service"]="mysql redis consul"
)

# 服务启动顺序
SERVICE_START_ORDER=(
    "consul"
    "mysql"
    "redis"
    "postgresql"
    "basic-server"
    "user-service"
    "ai-service"
    "resume"
    "company-service"
    "notification-service"
    "banner-service"
    "statistics-service"
    "template-service"
)

# 服务停止顺序（与启动顺序相反）
SERVICE_STOP_ORDER=(
    "template-service"
    "statistics-service"
    "banner-service"
    "notification-service"
    "company-service"
    "resume"
    "ai-service"
    "user-service"
    "basic-server"
    "postgresql"
    "redis"
    "mysql"
    "consul"
)

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日志函数
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# 错误处理
error_exit() {
    echo -e "${RED}错误: $1${NC}" >&2
    log "ERROR: $1"
    exit 1
}

# 成功信息
success() {
    echo -e "${GREEN}成功: $1${NC}"
    log "SUCCESS: $1"
}

# 警告信息
warning() {
    echo -e "${YELLOW}警告: $1${NC}"
    log "WARNING: $1"
}

# 信息输出
info() {
    echo -e "${BLUE}信息: $1${NC}"
    log "INFO: $1"
}

# 创建必要目录
create_directories() {
    mkdir -p "$(dirname "$LOG_FILE")"
}

# 检查服务是否运行
is_service_running() {
    local service=$1
    case $service in
        "consul")
            systemctl is-active --quiet consul
            ;;
        "mysql")
            systemctl is-active --quiet mysql
            ;;
        "redis")
            systemctl is-active --quiet redis-server
            ;;
        "postgresql")
            systemctl is-active --quiet postgresql
            ;;
        "basic-server")
            pgrep -f "main" > /dev/null
            ;;
        "user-service")
            pgrep -f "user-service" > /dev/null
            ;;
        "ai-service")
            pgrep -f "ai_service.py" > /dev/null
            ;;
        *)
            pgrep -f "$service" > /dev/null
            ;;
    esac
}

# 启动单个服务
start_service() {
    local service=$1
    local force=${2:-false}
    
    if [ "$force" = "false" ] && is_service_running "$service"; then
        info "服务 $service 已在运行"
        return 0
    fi
    
    log "启动服务: $service"
    
    case $service in
        "consul")
            sudo systemctl start consul
            ;;
        "mysql")
            sudo systemctl start mysql
            ;;
        "redis")
            sudo systemctl start redis-server
            ;;
        "postgresql")
            sudo systemctl start postgresql
            ;;
        "basic-server")
            cd "$DEPLOY_DIR/basic-server"
            if [ -f "main.go" ]; then
                go build -o main main.go rbac_apis.go
                nohup ./main > basic-server.log 2>&1 &
                sleep 2
            fi
            ;;
        "user-service")
            cd "$DEPLOY_DIR/user-service"
            if [ -f "main.go" ]; then
                go build -o user-service main.go
                nohup ./user-service > user-service.log 2>&1 &
                sleep 2
            fi
            ;;
        "ai-service")
            cd "$DEPLOY_DIR/ai-service"
            if [ -f "ai_service.py" ]; then
                nohup python3 ai_service.py > ai-service.log 2>&1 &
                sleep 2
            fi
            ;;
        *)
            warning "未知服务: $service"
            return 1
            ;;
    esac
    
    # 等待服务启动
    sleep 3
    
    if is_service_running "$service"; then
        success "服务 $service 启动成功"
    else
        error_exit "服务 $service 启动失败"
    fi
}

# 停止单个服务
stop_service() {
    local service=$1
    local force=${2:-false}
    
    if ! is_service_running "$service"; then
        info "服务 $service 未运行"
        return 0
    fi
    
    log "停止服务: $service"
    
    case $service in
        "consul")
            sudo systemctl stop consul
            ;;
        "mysql")
            sudo systemctl stop mysql
            ;;
        "redis")
            sudo systemctl stop redis-server
            ;;
        "postgresql")
            sudo systemctl stop postgresql
            ;;
        "basic-server")
            pkill -f "main" || true
            ;;
        "user-service")
            pkill -f "user-service" || true
            ;;
        "ai-service")
            pkill -f "ai_service.py" || true
            ;;
        *)
            pkill -f "$service" || true
            ;;
    esac
    
    # 等待服务停止
    sleep 3
    
    if ! is_service_running "$service"; then
        success "服务 $service 停止成功"
    else
        warning "服务 $service 停止可能不完整"
    fi
}

# 启动所有服务（按依赖顺序）
start_all_services() {
    local force=${1:-false}
    
    log "启动所有服务"
    
    for service in "${SERVICE_START_ORDER[@]}"; do
        start_service "$service" "$force"
    done
    
    success "所有服务启动完成"
}

# 停止所有服务（按依赖顺序）
stop_all_services() {
    local force=${1:-false}
    
    log "停止所有服务"
    
    for service in "${SERVICE_STOP_ORDER[@]}"; do
        stop_service "$service" "$force"
    done
    
    success "所有服务停止完成"
}

# 重启所有服务
restart_all_services() {
    local force=${1:-false}
    
    log "重启所有服务"
    stop_all_services "$force"
    sleep 5
    start_all_services "$force"
    success "所有服务重启完成"
}

# 滚动更新服务
rolling_update() {
    local service=$1
    local version=$2
    
    if [ -z "$service" ] || [ -z "$version" ]; then
        error_exit "请指定服务名和版本号"
    fi
    
    log "滚动更新服务: $service 到版本: $version"
    
    # 检查版本是否存在
    local backup_path="$DEPLOY_DIR/backups/v$version"
    if [ ! -d "$backup_path" ]; then
        error_exit "版本 $version 不存在"
    fi
    
    # 停止服务
    stop_service "$service"
    
    # 更新服务文件
    if [ -d "$backup_path/$service" ]; then
        rm -rf "$DEPLOY_DIR/$service"
        cp -r "$backup_path/$service" "$DEPLOY_DIR/"
        log "更新服务文件: $service"
    fi
    
    # 启动服务
    start_service "$service"
    
    success "服务 $service 滚动更新完成"
}

# 健康检查
health_check() {
    local service=${1:-"all"}
    
    log "健康检查: $service"
    
    if [ "$service" = "all" ]; then
        for svc in "${SERVICE_START_ORDER[@]}"; do
            if is_service_running "$svc"; then
                success "✓ $svc 运行正常"
            else
                error_exit "✗ $svc 运行异常"
            fi
        done
    else
        if is_service_running "$service"; then
            success "✓ $service 运行正常"
        else
            error_exit "✗ $service 运行异常"
        fi
    fi
}

# 显示服务状态
show_status() {
    echo "服务状态:"
    echo "=========="
    
    for service in "${SERVICE_START_ORDER[@]}"; do
        if is_service_running "$service"; then
            echo -e "✓ ${GREEN}$service${NC} - 运行中"
        else
            echo -e "✗ ${RED}$service${NC} - 未运行"
        fi
    done
}

# 显示服务依赖
show_dependencies() {
    local service=$1
    
    if [ -z "$service" ]; then
        echo "服务依赖关系:"
        echo "=============="
        for svc in "${!SERVICE_DEPENDENCIES[@]}"; do
            echo "$svc 依赖: ${SERVICE_DEPENDENCIES[$svc]}"
        done
    else
        if [ -n "${SERVICE_DEPENDENCIES[$service]}" ]; then
            echo "$service 依赖: ${SERVICE_DEPENDENCIES[$service]}"
        else
            echo "服务 $service 无依赖或未知服务"
        fi
    fi
}

# 主函数
main() {
    create_directories
    
    case "$1" in
        "start")
            if [ "$2" = "--all" ]; then
                start_all_services "$3"
            else
                start_service "$2" "$3"
            fi
            ;;
        "stop")
            if [ "$2" = "--all" ]; then
                stop_all_services "$3"
            else
                stop_service "$2" "$3"
            fi
            ;;
        "restart")
            if [ "$2" = "--all" ]; then
                restart_all_services "$3"
            else
                stop_service "$2" "$3"
                start_service "$2" "$3"
            fi
            ;;
        "rolling-update")
            rolling_update "$2" "$3"
            ;;
        "health")
            health_check "$2"
            ;;
        "status")
            show_status
            ;;
        "dependencies")
            show_dependencies "$2"
            ;;
        *)
            echo "用法: $0 {start|stop|restart|rolling-update|health|status|dependencies} [service] [options]"
            echo ""
            echo "命令说明:"
            echo "  start [service] [--force]     - 启动服务"
            echo "  stop [service] [--force]      - 停止服务"
            echo "  restart [service] [--force]   - 重启服务"
            echo "  rolling-update <service> <version> - 滚动更新服务"
            echo "  health [service]              - 健康检查"
            echo "  status                        - 显示服务状态"
            echo "  dependencies [service]        - 显示服务依赖"
            echo ""
            echo "特殊选项:"
            echo "  --all                         - 操作所有服务"
            echo "  --force                       - 强制操作"
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"