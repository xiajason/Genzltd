#!/bin/bash

# JobFirst 智能关闭脚本 - 安全优雅关闭所有微服务
# 基于smart-startup.sh的对应关闭脚本
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
SHUTDOWN_LOG="$LOG_DIR/smart-shutdown.log"

# 关闭超时配置
GRACEFUL_TIMEOUT=30
FORCE_TIMEOUT=10
DB_FLUSH_TIMEOUT=15

# 服务配置 (与smart-startup.sh保持一致)
VERIFIED_SERVICES=(
    "basic-server:8080"
    "user-service:8081"
    "resume-service:8082"
    "company-service:8083"
    "notification-service:8084"
    "template-service:8085"
    "statistics-service:8086"
    "banner-service:8087"
    "dev-team-service:8088"
    "job-service:8089"
    "unified-auth-service:8207"
)

# AI服务配置
AI_SERVICES=(
    "local-ai-service:8206"
    "containerized-ai-service:8208"
    "mineru-service:8001"
    "ai-models-service:8002"
    "ai-monitor-service:9090"
)

# 待验证的服务
PENDING_SERVICES=(
    "auth-service:8207"
)

# 所有服务（用于状态检查）
ALL_SERVICES=(
    "${VERIFIED_SERVICES[@]}"
    "${AI_SERVICES[@]}"
    "${PENDING_SERVICES[@]}"
)

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

log_mode() {
    echo -e "${CYAN}[MODE]${NC} $1" | tee -a "$SHUTDOWN_LOG"
}

# 创建必要的目录
create_directories() {
    mkdir -p "$LOG_DIR"
    mkdir -p "$BACKUP_DIR"
    mkdir -p "$PROJECT_ROOT/temp"
}

# 检查服务是否运行
is_service_running() {
    local service_name=$1
    local port=$2
    
    # 优先检查端口是否被占用
    if lsof -i ":$port" >/dev/null 2>&1; then
        return 0
    fi
    
    # 检查PID文件是否存在且进程运行
    local pid_file="$LOG_DIR/${service_name}.pid"
    if [[ -f "$pid_file" ]]; then
        local pid=$(cat "$pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            return 0
        fi
    fi
    
    return 1
}

# 优雅关闭服务
graceful_shutdown_service() {
    local service_name=$1
    local port=$2
    local pid_file="$LOG_DIR/${service_name}.pid"
    
    log_info "优雅关闭 $service_name (端口: $port)..."
    
    if [[ -f "$pid_file" ]]; then
        local pid=$(cat "$pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            log_info "发送SIGTERM信号到 $service_name (PID: $pid)"
            kill -TERM "$pid" 2>/dev/null || true
            
            # 等待优雅关闭
            local count=0
            while kill -0 "$pid" 2>/dev/null && [[ $count -lt $GRACEFUL_TIMEOUT ]]; do
                sleep 1
                ((count++))
            done
            
            if kill -0 "$pid" 2>/dev/null; then
                log_warning "$service_name 未在 $GRACEFUL_TIMEOUT 秒内关闭，发送SIGKILL"
                kill -KILL "$pid" 2>/dev/null || true
                sleep 2
            fi
            
            if ! kill -0 "$pid" 2>/dev/null; then
                log_success "$service_name 已成功关闭"
                rm -f "$pid_file"
            else
                log_error "$service_name 关闭失败"
                return 1
            fi
        else
            log_warning "$service_name PID文件存在但进程未运行，清理PID文件"
            rm -f "$pid_file"
        fi
    else
        # 尝试通过端口查找进程
        local pid=$(lsof -ti ":$port" 2>/dev/null | head -1)
        if [[ -n "$pid" ]]; then
            log_info "通过端口 $port 找到进程 $pid，尝试关闭"
            kill -TERM "$pid" 2>/dev/null || true
            sleep 3
            if kill -0 "$pid" 2>/dev/null; then
                kill -KILL "$pid" 2>/dev/null || true
            fi
            log_success "$service_name 已通过端口关闭"
        else
            log_info "$service_name 未运行"
        fi
    fi
}

# 强制关闭服务
force_shutdown_service() {
    local service_name=$1
    local port=$2
    
    log_warning "强制关闭 $service_name (端口: $port)..."
    
    # 通过端口强制关闭
    local pids=$(lsof -ti ":$port" 2>/dev/null)
    if [[ -n "$pids" ]]; then
        echo "$pids" | xargs kill -KILL 2>/dev/null || true
        log_success "$service_name 已强制关闭"
    else
        log_info "$service_name 未运行"
    fi
    
    # 清理PID文件
    rm -f "$LOG_DIR/${service_name}.pid"
}

# 关闭所有微服务
# 关闭AI服务
shutdown_ai_services() {
    log_step "关闭AI服务..."
    
    # 关闭本地化AI服务
    log_info "关闭本地化AI服务..."
    local local_ai_pids=$(lsof -ti :8206 2>/dev/null || true)
    if [[ -n "$local_ai_pids" ]]; then
        log_info "发现本地化AI服务进程: $local_ai_pids"
        for pid in $local_ai_pids; do
            if kill -0 "$pid" 2>/dev/null; then
                log_info "发送SIGTERM信号到本地化AI服务 (PID: $pid)"
                kill "$pid"
                sleep 2
                if kill -0 "$pid" 2>/dev/null; then
                    log_warning "本地化AI服务 (PID: $pid) 未响应SIGTERM，发送SIGKILL"
                    kill -9 "$pid"
                fi
            fi
        done
        log_success "本地化AI服务已关闭"
    else
        log_info "本地化AI服务未运行，跳过"
    fi
    
    # 关闭容器化AI服务
    log_info "关闭容器化AI服务..."
    cd "$PROJECT_ROOT/ai-services" 2>/dev/null || {
        log_warning "ai-services 目录不存在，跳过容器化AI服务关闭"
        return 0
    }
    
    # 关闭所有AI相关容器
    if docker-compose ps -q >/dev/null 2>&1; then
        log_info "停止所有AI服务容器..."
        if docker-compose down; then
            log_success "容器化AI服务已关闭"
        else
            log_warning "容器化AI服务关闭失败"
        fi
    else
        log_info "没有运行中的AI服务容器"
    fi
    
    cd - > /dev/null # 返回原目录
}

shutdown_microservices() {
    log_step "关闭所有微服务..."
    
    # 按启动顺序的逆序关闭服务
    local shutdown_order=(
        "auth-service:8207"
        "dev-team-service:8088"
        "banner-service:8087"
        "statistics-service:8086"
        "template-service:8085"
        "notification-service:8084"
        "job-service:8089"
        "company-service:8083"
        "resume-service:8082"
        "user-service:8081"
        "unified-auth-service:8207"
        "basic-server:8080"
    )
    
    for service_info in "${shutdown_order[@]}"; do
        IFS=':' read -r service_name port <<< "$service_info"
        
        if is_service_running "$service_name" "$port"; then
            graceful_shutdown_service "$service_name" "$port"
        else
            log_info "$service_name 未运行，跳过"
        fi
    done
    
    # 关闭AI服务
    shutdown_ai_services
}

# 关闭基础设施服务
shutdown_infrastructure_services() {
    log_step "关闭基础设施服务..."
    
    # 关闭Consul
    if brew services list | grep consul | grep started &> /dev/null; then
        log_info "关闭Consul服务..."
        if brew services stop consul; then
            log_success "Consul已关闭"
        else
            log_warning "Consul关闭失败"
        fi
    else
        log_info "Consul未运行"
    fi
    
    # 关闭Neo4j
    if brew services list | grep neo4j | grep started &> /dev/null; then
        log_info "关闭Neo4j服务..."
        if brew services stop neo4j; then
            log_success "Neo4j已关闭"
        else
            log_warning "Neo4j关闭失败"
        fi
    else
        log_info "Neo4j未运行"
    fi
    
    # 关闭PostgreSQL@14
    if brew services list | grep postgresql@14 | grep started &> /dev/null; then
        log_info "关闭PostgreSQL@14服务..."
        if brew services stop postgresql@14; then
            log_success "PostgreSQL@14已关闭"
        else
            log_warning "PostgreSQL@14关闭失败"
        fi
    else
        log_info "PostgreSQL@14未运行"
    fi
    
    # 关闭Redis
    if brew services list | grep redis | grep started &> /dev/null; then
        log_info "关闭Redis服务..."
        if brew services stop redis; then
            log_success "Redis已关闭"
        else
            log_warning "Redis关闭失败"
        fi
    else
        log_info "Redis未运行"
    fi
    
    # 关闭MySQL
    if brew services list | grep mysql | grep started &> /dev/null; then
        log_info "关闭MySQL服务..."
        if brew services stop mysql; then
            log_success "MySQL已关闭"
        else
            log_warning "MySQL关闭失败"
        fi
    else
        log_info "MySQL未运行"
    fi
}

# 数据备份和清理
backup_and_cleanup() {
    log_step "执行数据备份和清理..."
    
    # 创建关闭时间戳
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    
    # 备份重要日志
    if [[ -d "$LOG_DIR" ]]; then
        log_info "备份服务日志..."
        tar -czf "$BACKUP_DIR/logs_backup_$timestamp.tar.gz" -C "$LOG_DIR" . 2>/dev/null || true
    fi
    
    # 清理临时文件
    log_info "清理临时文件..."
    find "$PROJECT_ROOT/temp" -type f -mtime +7 -delete 2>/dev/null || true
    
    # 清理旧日志文件
    log_info "清理旧日志文件..."
    find "$LOG_DIR" -name "*.log" -mtime +30 -delete 2>/dev/null || true
    
    log_success "数据备份和清理完成"
}

# 验证关闭状态
verify_shutdown() {
    log_step "验证关闭状态..."
    
    local running_services=()
    
    for service_info in "${ALL_SERVICES[@]}"; do
        IFS=':' read -r service_name port <<< "$service_info"
        
        if is_service_running "$service_name" "$port"; then
            running_services+=("$service_name:$port")
        fi
    done
    
    if [[ ${#running_services[@]} -eq 0 ]]; then
        log_success "所有微服务已成功关闭"
        return 0
    else
        log_warning "以下服务仍在运行:"
        for service in "${running_services[@]}"; do
            log_warning "  - $service"
        done
        return 1
    fi
}

# 生成关闭报告
generate_shutdown_report() {
    log_step "生成关闭报告..."
    
    local report_file="$LOG_DIR/shutdown_report_$(date '+%Y%m%d_%H%M%S').txt"
    
    {
        echo "=========================================="
        echo "JobFirst 智能关闭报告"
        echo "=========================================="
        echo "关闭时间: $(date)"
        echo "关闭模式: 智能优雅关闭"
        echo ""
        echo "服务状态:"
        
        for service_info in "${ALL_SERVICES[@]}"; do
            IFS=':' read -r service_name port <<< "$service_info"
            if is_service_running "$service_name" "$port"; then
                echo "  ❌ $service_name:$port - 仍在运行"
            else
                echo "  ✅ $service_name:$port - 已关闭"
            fi
        done
        
        echo ""
        echo "基础设施服务状态:"
        echo "  MySQL: $(brew services list | grep mysql | awk '{print $2}' || echo 'unknown')"
        echo "  Redis: $(brew services list | grep redis | awk '{print $2}' || echo 'unknown')"
        echo "  PostgreSQL@14: $(brew services list | grep postgresql@14 | awk '{print $2}' || echo 'unknown')"
        echo "  Neo4j: $(brew services list | grep neo4j | awk '{print $2}' || echo 'unknown')"
        echo "  Consul: $(brew services list | grep consul | awk '{print $2}' || echo 'unknown')"
        
        echo ""
        echo "关闭日志: $SHUTDOWN_LOG"
        echo "=========================================="
    } > "$report_file"
    
    log_success "关闭报告已生成: $report_file"
}

# 显示帮助信息
show_help() {
    cat << EOF
JobFirst 智能关闭脚本 - 安全优雅关闭所有微服务

用法: $0 [选项]

选项:
  --force             强制关闭所有服务（跳过优雅关闭）
  --microservices     只关闭微服务，保留基础设施服务
  --infrastructure    只关闭基础设施服务，保留微服务
  --help             显示此帮助信息

关闭模式:
  graceful            优雅关闭 - 发送SIGTERM信号，等待服务自行关闭
  force               强制关闭 - 直接发送SIGKILL信号

关闭顺序:
  1. 微服务 (按启动顺序逆序关闭)
  2. AI服务 (本地化AI服务, 容器化AI服务)
  3. 基础设施服务 (Consul, Neo4j, PostgreSQL@14, Redis, MySQL)
  4. 数据备份和清理
  5. 状态验证和报告

示例:
  $0                                    # 智能优雅关闭所有服务
  $0 --force                           # 强制关闭所有服务
  $0 --microservices                   # 只关闭微服务
  $0 --infrastructure                  # 只关闭基础设施服务

EOF
}

# 主函数
main() {
    local force_mode=false
    local microservices_only=false
    local infrastructure_only=false
    
    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            --force)
                force_mode=true
                shift
                ;;
            --microservices)
                microservices_only=true
                shift
                ;;
            --infrastructure)
                infrastructure_only=true
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                log_error "未知选项: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # 创建必要的目录
    create_directories
    
    # 记录关闭开始
    echo "=========================================="
    echo "🛑 JobFirst 智能关闭工具"
    echo "=========================================="
    echo
    
    log_info "开始智能关闭流程..."
    log_mode "关闭模式: $([ "$force_mode" = true ] && echo "强制关闭" || echo "优雅关闭")"
    
    # 执行关闭步骤
    if [[ "$infrastructure_only" = false ]]; then
        if [[ "$force_mode" = true ]]; then
            log_step "强制关闭所有微服务..."
            for service_info in "${ALL_SERVICES[@]}"; do
                IFS=':' read -r service_name port <<< "$service_info"
                force_shutdown_service "$service_name" "$port"
            done
        else
            shutdown_microservices
        fi
    fi
    
    if [[ "$microservices_only" = false ]]; then
        shutdown_infrastructure_services
    fi
    
    # 数据备份和清理
    backup_and_cleanup
    
    # 验证和报告
    verify_shutdown
    generate_shutdown_report
    
    echo
    echo "=========================================="
    echo "✅ JobFirst 智能关闭完成"
    echo "=========================================="
    echo
    log_success "系统已安全关闭"
    log_info "关闭日志: $SHUTDOWN_LOG"
    echo
}

# 错误处理
trap 'log_error "关闭过程中发生错误"; exit 1' ERR

# 信号处理
trap 'log_warning "收到中断信号，继续关闭流程..."' INT TERM

# 执行主函数
main "$@"
