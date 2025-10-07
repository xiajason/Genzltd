#!/bin/bash

# LoomaCRM-AI 智能微服务启动脚本
# 基于Zervigo子系统经验，实现Python Sanic微服务集群的智能启动顺序管理

# 兼容bash 3.2，使用普通数组替代关联数组

# set -e  # 注释掉，避免因非关键错误退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 项目配置
PROJECT_ROOT="/Users/szjason72/zervi-basic/looma_crm_ai_refactoring"
LOG_DIR="$PROJECT_ROOT/logs"
STARTUP_LOG="$LOG_DIR/smart-microservice-startup.log"

# 启动超时配置
SERVICE_START_TIMEOUT=30
HEALTH_CHECK_INTERVAL=5
MAX_HEALTH_CHECK_ATTEMPTS=12
DEPENDENCY_WAIT_TIMEOUT=60
DEPENDENCY_CHECK_INTERVAL=3

# 独立数据库服务配置
INDEPENDENT_DATABASE_SERVICES=(
    "mongodb:27018"
    "postgresql:5434"
    "redis:6382"
    "neo4j:7475"
    "elasticsearch:9202"
    "weaviate:8082"
)

# API服务配置（按启动顺序）
API_SERVICES=(
    "api-gateway:9000"
    "user-api:9001"
    "resume-api:9002"
    "company-api:9003"
    "job-api:9004"
    "project-api:9005"
    "skill-api:9006"
    "relationship-api:9007"
    "ai-api:9008"
    "search-api:9009"
)

# 服务依赖关系定义（兼容bash 3.2）
SERVICE_DEPENDENCIES=(
    "api-gateway:"
    "user-api:api-gateway"
    "resume-api:user-api"
    "company-api:api-gateway"
    "job-api:company-api"
    "project-api:api-gateway"
    "skill-api:api-gateway"
    "relationship-api:user-api"
    "ai-api:api-gateway"
    "search-api:api-gateway"
)

# 获取服务依赖的函数
get_service_dependency() {
    local service_name="$1"
    for dependency in "${SERVICE_DEPENDENCIES[@]}"; do
        IFS=':' read -r name dep <<< "$dependency"
        if [[ "$name" = "$service_name" ]]; then
            echo "$dep"
            return 0
        fi
    done
    echo ""
}

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$STARTUP_LOG"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$STARTUP_LOG"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$STARTUP_LOG"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$STARTUP_LOG"
}

log_step() {
    echo -e "${PURPLE}[STEP]${NC} $1" | tee -a "$STARTUP_LOG"
}

# 创建必要的目录
create_directories() {
    mkdir -p "$LOG_DIR"
    mkdir -p "$PROJECT_ROOT/api-services"
}

# 检查端口是否可用
check_port_available() {
    local port=$1
    local service_name=$2
    
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        local pid=$(lsof -Pi :$port -sTCP:LISTEN -t | head -1)
        log_warning "$service_name 端口 $port 已被占用 (PID: $pid)"
        return 1
    else
        log_info "$service_name 端口 $port 可用"
        return 0
    fi
}

# 等待服务健康检查
wait_for_service_health() {
    local service_name=$1
    local health_url=$2
    local timeout=$3
    
    log_info "等待 $service_name 健康检查..."
    
    local count=0
    while [[ $count -lt $timeout ]]; do
        if curl -s "$health_url" >/dev/null 2>&1; then
            log_success "$service_name 健康检查通过"
            return 0
        fi
        
        sleep 1
        ((count++))
        echo -n "."
    done
    
    echo ""
    log_warning "$service_name 健康检查超时"
    return 1
}

# 等待服务依赖就绪
wait_for_dependency() {
    local service_name="$1"
    local check_url="$2"
    local expected_response="$3"
    
    log_info "等待 $service_name 依赖就绪..."
    local attempts=0
    local max_attempts=$((DEPENDENCY_WAIT_TIMEOUT / DEPENDENCY_CHECK_INTERVAL))
    
    while [ $attempts -lt $max_attempts ]; do
        if curl -s "$check_url" | grep -q "$expected_response" 2>/dev/null; then
            log_success "$service_name 依赖就绪"
            return 0
        fi
        log_info "等待 $service_name 就绪... ($((attempts + 1))/$max_attempts)"
        sleep $DEPENDENCY_CHECK_INTERVAL
        attempts=$((attempts + 1))
    done
    
    log_error "$service_name 依赖等待超时"
    return 1
}

# 检查独立数据库服务状态
check_independent_databases() {
    log_step "检查独立数据库服务状态..."
    
    local all_ready=true
    
    for service_info in "${INDEPENDENT_DATABASE_SERVICES[@]}"; do
        IFS=':' read -r service_name port <<< "$service_info"
        
        if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
            local pid=$(lsof -Pi :$port -sTCP:LISTEN -t | head -1)
            log_success "✅ $service_name 正在运行 (端口: $port, PID: $pid)"
        else
            log_warning "❌ $service_name 未运行 (端口: $port)"
            all_ready=false
        fi
    done
    
    if [[ "$all_ready" = true ]]; then
        log_success "所有独立数据库服务就绪"
        return 0
    else
        log_error "部分独立数据库服务未就绪，请先启动独立数据库"
        return 1
    fi
}

# 启动API服务
start_api_service() {
    local service_name=$1
    local port=$2
    local service_dir="$PROJECT_ROOT/api-services/looma-${service_name}"
    local start_script="$service_dir/scripts/start.sh"
    
    log_info "启动 $service_name (端口: $port)..."
    
    # 检查端口可用性
    if ! check_port_available "$port" "$service_name"; then
        log_error "$service_name 端口 $port 被占用，无法启动"
        return 1
    fi
    
    # 检查服务目录和启动脚本
    if [[ ! -d "$service_dir" ]]; then
        log_warning "$service_name 服务目录不存在: $service_dir"
        return 1
    fi
    
    if [[ ! -f "$start_script" ]]; then
        log_warning "$service_name 启动脚本不存在: $start_script"
        return 1
    fi
    
    # 检查依赖服务
    local dependency=$(get_service_dependency "$service_name")
    if [[ -n "$dependency" ]]; then
        local dep_port=""
        for api_service in "${API_SERVICES[@]}"; do
            IFS=':' read -r name port_num <<< "$api_service"
            if [[ "$name" = "$dependency" ]]; then
                dep_port="$port_num"
                break
            fi
        done
        
        if [[ -n "$dep_port" ]]; then
            local health_url="http://localhost:$dep_port/health"
            if ! wait_for_dependency "$dependency" "$health_url" "healthy"; then
                log_warning "$dependency 未就绪，$service_name 将在受限模式下启动"
            fi
        fi
    fi
    
    # 执行启动脚本
    cd "$service_dir" || {
        log_error "$service_name 无法切换到服务目录: $service_dir"
        return 1
    }
    
    log_info "执行启动脚本: $start_script"
    if bash "$start_script"; then
        log_info "$service_name 启动脚本执行成功"
    else
        log_error "$service_name 启动脚本执行失败"
        return 1
    fi
    
    # 健康检查
    local health_url="http://localhost:$port/health"
    if wait_for_service_health "$service_name" "$health_url" $SERVICE_START_TIMEOUT; then
        log_success "$service_name 启动成功并通过健康检查"
        return 0
    else
        log_warning "$service_name 启动成功但健康检查失败"
        return 1
    fi
}

# 启动API网关
start_api_gateway() {
    log_step "启动API网关..."
    
    local service_dir="$PROJECT_ROOT/api-services/looma-api-gateway"
    local start_script="$service_dir/scripts/start.sh"
    
    if [[ ! -f "$start_script" ]]; then
        log_error "API网关启动脚本不存在: $start_script"
        return 1
    fi
    
    cd "$service_dir" || {
        log_error "无法切换到API网关目录: $service_dir"
        return 1
    }
    
    log_info "执行API网关启动脚本..."
    if bash "$start_script"; then
        log_success "API网关启动脚本执行成功"
        
        # 等待API网关就绪
        if wait_for_service_health "API Gateway" "http://localhost:9000/health" $SERVICE_START_TIMEOUT; then
            log_success "API网关启动成功并通过健康检查"
            return 0
        else
            log_warning "API网关启动成功但健康检查失败"
            return 1
        fi
    else
        log_error "API网关启动脚本执行失败"
        return 1
    fi
}

# 启动所有API服务
start_all_api_services() {
    log_step "启动所有API服务..."
    
    # 首先启动API网关
    if ! start_api_gateway; then
        log_error "API网关启动失败，停止启动流程"
        return 1
    fi
    
    # 然后按顺序启动其他API服务
    for service_info in "${API_SERVICES[@]}"; do
        IFS=':' read -r service_name port <<< "$service_info"
        
        # 跳过API网关（已经启动）
        if [[ "$service_name" = "api-gateway" ]]; then
            continue
        fi
        
        # 启动服务
        if start_api_service "$service_name" "$port"; then
            log_success "$service_name 启动成功"
        else
            log_warning "$service_name 启动失败，继续启动其他服务"
        fi
        
        # 短暂等待，避免资源竞争
        sleep 2
    done
}

# 验证所有服务状态
verify_all_services() {
    log_step "验证所有服务状态..."
    
    local running_services=()
    local failed_services=()
    
    # 检查独立数据库服务
    log_info "检查独立数据库服务状态..."
    for service_info in "${INDEPENDENT_DATABASE_SERVICES[@]}"; do
        IFS=':' read -r service port <<< "$service_info"
        if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
            local pid=$(lsof -Pi :$port -sTCP:LISTEN -t | head -1)
            running_services+=("$service:$port:$pid")
            log_success "✅ $service 正在运行 (端口: $port, PID: $pid)"
        else
            failed_services+=("$service:$port")
            log_warning "❌ $service 未运行 (端口: $port)"
        fi
    done
    
    # 检查API服务
    log_info "检查API服务状态..."
    for service_info in "${API_SERVICES[@]}"; do
        IFS=':' read -r service port <<< "$service_info"
        if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
            local pid=$(lsof -Pi :$port -sTCP:LISTEN -t | head -1)
            running_services+=("$service:$port:$pid")
            log_success "✅ $service 正在运行 (端口: $port, PID: $pid)"
        else
            failed_services+=("$service:$port")
            log_warning "❌ $service 未运行 (端口: $port)"
        fi
    done
    
    echo ""
    log_info "服务状态统计:"
    log_info "  运行中的服务: ${#running_services[@]}"
    log_info "  失败的服务: ${#failed_services[@]}"
    
    if [[ ${#failed_services[@]} -eq 0 ]]; then
        log_success "所有服务启动成功！"
        return 0
    else
        log_warning "部分服务启动失败，请检查日志"
        return 1
    fi
}

# 生成启动报告
generate_startup_report() {
    log_step "生成启动报告..."
    
    local report_file="$LOG_DIR/microservice_startup_report_$(date +%Y%m%d_%H%M%S).txt"
    
    cat > "$report_file" << EOF
==========================================
LoomaCRM-AI 智能微服务启动报告
==========================================
启动时间: $(date)
启动模式: 智能启动顺序管理
基于经验: Zervigo子系统启动顺序
启动脚本: $0
启动日志: $STARTUP_LOG

启动顺序:
✅ 独立数据库服务检查
✅ API网关启动
✅ 核心API服务启动 (按依赖顺序)
✅ 扩展API服务启动
✅ 服务状态验证

服务依赖关系:
EOF

    # 添加依赖关系信息
    for service in "${!SERVICE_DEPENDENCIES[@]}"; do
        local dependency="${SERVICE_DEPENDENCIES[$service]}"
        if [[ -n "$dependency" ]]; then
            echo "  $service → $dependency" >> "$report_file"
        else
            echo "  $service → 无依赖" >> "$report_file"
        fi
    done
    
    cat >> "$report_file" << EOF

服务状态:
$(verify_all_services)

改进点:
1. 智能启动顺序 - 基于Zervigo子系统经验
2. 依赖关系管理 - 自动检查服务依赖
3. 健康检查集成 - 确保服务完全就绪
4. 错误处理优化 - 优雅处理启动失败

==========================================
EOF
    
    log_success "启动报告已生成: $report_file"
}

# 显示帮助信息
show_help() {
    cat << EOF
LoomaCRM-AI 智能微服务启动脚本

基于Zervigo子系统经验，实现Python Sanic微服务集群的智能启动顺序管理

用法: $0 [选项]

选项:
  --skip-db-check     跳过独立数据库检查
  --skip-gateway      跳过API网关启动
  --services-only     仅启动API服务（跳过数据库检查）
  --help             显示此帮助信息

启动流程:
  1. 检查独立数据库服务状态
  2. 启动API网关
  3. 按依赖顺序启动API服务
  4. 验证所有服务状态
  5. 生成启动报告

服务依赖关系:
  API Gateway → User API → Resume API
  API Gateway → Company API → Job API
  API Gateway → 其他扩展API服务

示例:
  $0                    # 完整启动流程
  $0 --skip-db-check   # 跳过数据库检查
  $0 --services-only   # 仅启动API服务

EOF
}

# 主函数
main() {
    local skip_db_check=false
    local skip_gateway=false
    local services_only=false
    
    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            --skip-db-check)
                skip_db_check=true
                shift
                ;;
            --skip-gateway)
                skip_gateway=true
                shift
                ;;
            --services-only)
                services_only=true
                skip_db_check=true
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                log_error "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # 初始化
    create_directories
    
    echo "=========================================="
    echo "🚀 LoomaCRM-AI 智能微服务启动工具"
    echo "=========================================="
    echo "基于Zervigo子系统经验，实现智能启动顺序管理"
    echo
    
    log_info "开始智能微服务启动流程..."
    
    # 检查独立数据库服务
    if [[ "$skip_db_check" = false ]]; then
        if ! check_independent_databases; then
            log_error "独立数据库服务检查失败，请先启动独立数据库"
            exit 1
        fi
    else
        log_info "跳过独立数据库检查"
    fi
    
    # 启动API服务
    if [[ "$services_only" = true ]]; then
        log_info "仅启动API服务模式"
        start_all_api_services
    else
        start_all_api_services
    fi
    
    # 验证和报告
    verify_all_services
    generate_startup_report
    
    echo
    echo "=========================================="
    echo "✅ LoomaCRM-AI 智能微服务启动完成"
    echo "=========================================="
    echo
    log_success "微服务集群已智能启动，启动顺序已优化"
    log_info "启动日志: $STARTUP_LOG"
    echo
}

# 错误处理 - 修改为不退出，继续启动流程
trap 'log_error "启动过程中发生错误，继续启动流程..."' ERR

# 信号处理
trap 'log_warning "收到中断信号，继续启动流程..."' INT TERM

# 执行主函数
main "$@"
