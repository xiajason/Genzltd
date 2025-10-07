#!/bin/bash

# LoomaCRM AI版统一管理脚本
# 支持容器化数据库和API服务的统一管理

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
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

log_step() {
    echo -e "${PURPLE}[STEP]${NC} $1"
}

# 获取脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# 显示帮助信息
show_help() {
    echo -e "${CYAN}LoomaCRM AI版统一管理脚本${NC}"
    echo "=================================="
    echo ""
    echo "用法: $0 [命令] [选项]"
    echo ""
    echo "命令:"
    echo "  start          启动整个LoomaCRM AI系统"
    echo "  stop           停止整个LoomaCRM AI系统"
    echo "  restart        重启整个LoomaCRM AI系统"
    echo "  status         查看系统状态"
    echo "  logs           查看系统日志"
    echo "  health         健康检查"
    echo "  db-start       仅启动数据库容器"
    echo "  db-stop        仅停止数据库容器"
    echo "  db-status      查看数据库容器状态"
    echo "  api-start      仅启动API服务"
    echo "  api-stop       仅停止API服务"
    echo "  api-status     查看API服务状态"
    echo "  monitor        打开监控面板"
    echo "  help           显示此帮助信息"
    echo ""
    echo "选项:"
    echo "  --force        强制操作，跳过确认"
    echo "  --verbose      详细输出"
    echo "  --no-db        不启动数据库容器"
    echo "  --no-api       不启动API服务"
    echo ""
    echo "示例:"
    echo "  $0 start                    # 启动整个系统"
    echo "  $0 start --no-db            # 启动系统但不启动数据库"
    echo "  $0 db-start                 # 仅启动数据库"
    echo "  $0 status                   # 查看系统状态"
    echo "  $0 monitor                  # 打开监控面板"
}

# 检查Docker环境
check_docker_environment() {
    log_info "检查Docker环境..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker未安装或未启动"
        return 1
    fi
    
    if ! docker info &> /dev/null; then
        log_error "Docker服务未运行"
        return 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose未安装"
        return 1
    fi
    
    log_success "Docker环境检查通过"
    return 0
}

# 启动数据库容器
start_database_containers() {
    log_step "启动数据库容器..."
    
    if [ ! -f "$PROJECT_ROOT/docker-compose.database.yml" ]; then
        log_error "Docker Compose配置文件不存在: docker-compose.database.yml"
        return 1
    fi
    
    cd "$PROJECT_ROOT"
    
    # 启动数据库容器
    docker-compose -f docker-compose.database.yml up -d
    
    if [ $? -eq 0 ]; then
        log_success "数据库容器启动成功"
        
        # 等待服务就绪
        log_info "等待数据库服务就绪..."
        sleep 10
        
        # 检查服务状态
        local db_services=("mongodb" "postgresql" "redis" "neo4j" "elasticsearch" "weaviate" "prometheus" "grafana")
        local running_services=0
        local total_services=${#db_services[@]}
        
        for service in "${db_services[@]}"; do
            if docker-compose -f docker-compose.database.yml ps "$service" | grep -q "Up"; then
                log_success "$service 容器运行正常"
                ((running_services++))
            else
                log_warning "$service 容器状态异常"
            fi
        done
        
        log_info "数据库容器状态: $running_services/$total_services 运行中"
        return 0
    else
        log_error "数据库容器启动失败"
        return 1
    fi
}

# 停止数据库容器
stop_database_containers() {
    log_step "停止数据库容器..."
    
    if [ ! -f "$PROJECT_ROOT/docker-compose.database.yml" ]; then
        log_error "Docker Compose配置文件不存在: docker-compose.database.yml"
        return 1
    fi
    
    cd "$PROJECT_ROOT"
    
    docker-compose -f docker-compose.database.yml down
    
    if [ $? -eq 0 ]; then
        log_success "数据库容器已停止"
        return 0
    else
        log_error "数据库容器停止失败"
        return 1
    fi
}

# 检查服务是否已运行
check_service_running() {
    local port=$1
    local service_name=$2
    
    if lsof -i :$port > /dev/null 2>&1; then
        log_info "$service_name (端口$port) 已在运行"
        return 0
    else
        return 1
    fi
}

# 启动API服务
start_api_services() {
    log_step "启动API服务..."
    
    # 启动API网关
    if [ -f "$PROJECT_ROOT/api-services/looma-api-gateway/scripts/start.sh" ]; then
        if check_service_running 9000 "API网关"; then
            log_success "API网关已在运行"
        else
            log_info "启动API网关..."
            cd "$PROJECT_ROOT/api-services/looma-api-gateway"
            ./scripts/start.sh
            if [ $? -eq 0 ]; then
                log_success "API网关启动成功"
            else
                log_warning "API网关启动失败"
            fi
        fi
    fi
    
    # 启动用户API服务
    if [ -f "$PROJECT_ROOT/api-services/looma-user-api/scripts/start.sh" ]; then
        if check_service_running 9001 "用户API服务"; then
            log_success "用户API服务已在运行"
        else
            log_info "启动用户API服务..."
            cd "$PROJECT_ROOT/api-services/looma-user-api"
            ./scripts/start.sh
            if [ $? -eq 0 ]; then
                log_success "用户API服务启动成功"
            else
                log_warning "用户API服务启动失败"
            fi
        fi
    fi
    
    # 启动其他API服务
    local api_services=("looma-resume-api:9002" "looma-company-api:9003" "looma-job-api:9004")
    for service_info in "${api_services[@]}"; do
        IFS=':' read -r service port <<< "$service_info"
        if [ -f "$PROJECT_ROOT/api-services/$service/scripts/start.sh" ]; then
            if check_service_running $port "$service"; then
                log_success "$service 已在运行"
            else
                log_info "启动$service..."
                cd "$PROJECT_ROOT/api-services/$service"
                ./scripts/start.sh
                if [ $? -eq 0 ]; then
                    log_success "$service 启动成功"
                else
                    log_warning "$service 启动失败"
                fi
            fi
        fi
    done
}

# 停止API服务
stop_api_services() {
    log_step "停止API服务..."
    
    # 停止API网关
    if [ -f "$PROJECT_ROOT/api-services/looma-api-gateway/scripts/stop.sh" ]; then
        log_info "停止API网关..."
        cd "$PROJECT_ROOT/api-services/looma-api-gateway"
        ./scripts/stop.sh
    fi
    
    # 停止用户API服务
    if [ -f "$PROJECT_ROOT/api-services/looma-user-api/scripts/stop.sh" ]; then
        log_info "停止用户API服务..."
        cd "$PROJECT_ROOT/api-services/looma-user-api"
        ./scripts/stop.sh
    fi
    
    # 停止其他API服务
    local api_services=("looma-resume-api" "looma-company-api" "looma-job-api")
    for service in "${api_services[@]}"; do
        if [ -f "$PROJECT_ROOT/api-services/$service/scripts/stop.sh" ]; then
            log_info "停止$service..."
            cd "$PROJECT_ROOT/api-services/$service"
            ./scripts/stop.sh
        fi
    done
    
    log_success "API服务已停止"
}

# 查看系统状态
show_system_status() {
    log_step "查看系统状态..."
    
    echo ""
    echo -e "${CYAN}=== 数据库容器状态 ===${NC}"
    if [ -f "$PROJECT_ROOT/docker-compose.database.yml" ]; then
        cd "$PROJECT_ROOT"
        docker-compose -f docker-compose.database.yml ps
    else
        log_warning "Docker Compose配置文件不存在"
    fi
    
    echo ""
    echo -e "${CYAN}=== API服务状态 ===${NC}"
    local api_ports=(9000 9001 9002 9003 9004)
    local api_names=("API网关" "用户API" "简历API" "公司API" "职位API")
    
    for i in "${!api_ports[@]}"; do
        local port=${api_ports[$i]}
        local name=${api_names[$i]}
        if lsof -i :$port > /dev/null 2>&1; then
            log_success "$name (端口$port) - 运行中"
        else
            log_warning "$name (端口$port) - 未运行"
        fi
    done
    
    echo ""
    echo -e "${CYAN}=== 系统资源使用 ===${NC}"
    if command -v docker &> /dev/null; then
        docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"
    fi
}

# 健康检查
perform_health_check() {
    log_step "执行健康检查..."
    
    local healthy_services=0
    local total_services=0
    
    # 检查数据库容器健康状态
    if [ -f "$PROJECT_ROOT/docker-compose.database.yml" ]; then
        cd "$PROJECT_ROOT"
        local db_services=("mongodb" "postgresql" "redis" "neo4j" "elasticsearch" "weaviate" "prometheus" "grafana")
        
        for service in "${db_services[@]}"; do
            ((total_services++))
            if docker-compose -f docker-compose.database.yml ps "$service" | grep -q "healthy"; then
                log_success "$service - 健康"
                ((healthy_services++))
            else
                log_warning "$service - 不健康"
            fi
        done
    fi
    
    # 检查API服务健康状态
    local api_ports=(9000 9001 9002 9003 9004)
    local api_names=("API网关" "用户API" "简历API" "公司API" "职位API")
    
    for i in "${!api_ports[@]}"; do
        local port=${api_ports[$i]}
        local name=${api_names[$i]}
        ((total_services++))
        
        if curl -s "http://localhost:$port/health" > /dev/null 2>&1; then
            log_success "$name - 健康"
            ((healthy_services++))
        else
            log_warning "$name - 不健康"
        fi
    done
    
    echo ""
    log_info "健康检查结果: $healthy_services/$total_services 服务健康"
    
    if [ $healthy_services -eq $total_services ]; then
        log_success "所有服务都健康运行"
        return 0
    else
        log_warning "部分服务不健康"
        return 1
    fi
}

# 打开监控面板
open_monitoring_panels() {
    log_step "打开监控面板..."
    
    # 检查Grafana是否运行
    if curl -s "http://localhost:3000" > /dev/null 2>&1; then
        log_info "打开Grafana监控面板..."
        open "http://localhost:3000" 2>/dev/null || log_info "请手动访问: http://localhost:3000"
    else
        log_warning "Grafana未运行，请先启动数据库容器"
    fi
    
    # 检查Prometheus是否运行
    if curl -s "http://localhost:9090" > /dev/null 2>&1; then
        log_info "打开Prometheus监控面板..."
        open "http://localhost:9090" 2>/dev/null || log_info "请手动访问: http://localhost:9090"
    else
        log_warning "Prometheus未运行，请先启动数据库容器"
    fi
}

# 主函数
main() {
    local command="$1"
    local force_mode=false
    local verbose_mode=false
    local no_db=false
    local no_api=false
    
    # 解析参数
    shift
    while [[ $# -gt 0 ]]; do
        case $1 in
            --force)
                force_mode=true
                shift
                ;;
            --verbose)
                verbose_mode=true
                shift
                ;;
            --no-db)
                no_db=true
                shift
                ;;
            --no-api)
                no_api=true
                shift
                ;;
            *)
                log_error "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    case "$command" in
        start)
            log_step "启动LoomaCRM AI系统..."
            
            if [ "$no_db" = false ]; then
                if ! check_docker_environment; then
                    exit 1
                fi
                start_database_containers
            fi
            
            if [ "$no_api" = false ]; then
                start_api_services
            fi
            
            log_success "LoomaCRM AI系统启动完成"
            ;;
        stop)
            log_step "停止LoomaCRM AI系统..."
            stop_api_services
            if [ "$no_db" = false ]; then
                stop_database_containers
            fi
            log_success "LoomaCRM AI系统已停止"
            ;;
        restart)
            log_step "重启LoomaCRM AI系统..."
            stop_api_services
            if [ "$no_db" = false ]; then
                stop_database_containers
            fi
            sleep 3
            if [ "$no_db" = false ]; then
                start_database_containers
            fi
            start_api_services
            log_success "LoomaCRM AI系统重启完成"
            ;;
        status)
            show_system_status
            ;;
        health)
            perform_health_check
            ;;
        db-start)
            if ! check_docker_environment; then
                exit 1
            fi
            start_database_containers
            ;;
        db-stop)
            stop_database_containers
            ;;
        db-status)
            if [ -f "$PROJECT_ROOT/docker-compose.database.yml" ]; then
                cd "$PROJECT_ROOT"
                docker-compose -f docker-compose.database.yml ps
            else
                log_error "Docker Compose配置文件不存在"
            fi
            ;;
        api-start)
            start_api_services
            ;;
        api-stop)
            stop_api_services
            ;;
        api-status)
            local api_ports=(9000 9001 9002 9003 9004)
            local api_names=("API网关" "用户API" "简历API" "公司API" "职位API")
            
            for i in "${!api_ports[@]}"; do
                local port=${api_ports[$i]}
                local name=${api_names[$i]}
                if lsof -i :$port > /dev/null 2>&1; then
                    log_success "$name (端口$port) - 运行中"
                else
                    log_warning "$name (端口$port) - 未运行"
                fi
            done
            ;;
        monitor)
            open_monitoring_panels
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "未知命令: $command"
            show_help
            exit 1
            ;;
    esac
}

# 检查参数
if [ $# -eq 0 ]; then
    show_help
    exit 1
fi

# 执行主函数
main "$@"
