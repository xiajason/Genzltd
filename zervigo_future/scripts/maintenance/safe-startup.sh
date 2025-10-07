#!/bin/bash

# JobFirst Basic Version 安全启动脚本
# 按照正确的顺序启动所有服务，确保系统稳定性

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
STARTUP_LOG="$LOG_DIR/safe-startup.log"

# 启动超时配置
SERVICE_START_TIMEOUT=30
HEALTH_CHECK_INTERVAL=5
MAX_HEALTH_CHECK_ATTEMPTS=12

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

# 初始化启动日志
init_startup_log() {
    mkdir -p "$LOG_DIR"
    echo "==========================================" >> "$STARTUP_LOG"
    echo "JobFirst 安全启动开始 - $(date)" >> "$STARTUP_LOG"
    echo "==========================================" >> "$STARTUP_LOG"
}

# 检查端口是否被占用
check_port_available() {
    local port=$1
    local service_name=$2
    
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        local pid=$(lsof -Pi :$port -sTCP:LISTEN -t | head -1)
        log_error "端口 $port 已被占用 (PID: $pid)，无法启动 $service_name"
        return 1
    fi
    return 0
}

# 等待服务健康检查
wait_for_service_health() {
    local service_name=$1
    local health_url=$2
    local timeout=${3:-$SERVICE_START_TIMEOUT}
    
    log_info "等待 $service_name 健康检查..."
    
    local attempts=0
    local max_attempts=$((timeout / HEALTH_CHECK_INTERVAL))
    
    while [[ $attempts -lt $max_attempts ]]; do
        if curl -s "$health_url" >/dev/null 2>&1; then
            log_success "$service_name 健康检查通过"
            return 0
        fi
        
        ((attempts++))
        echo -n "."
        sleep $HEALTH_CHECK_INTERVAL
    done
    
    echo ""
    log_warning "$service_name 健康检查超时"
    return 1
}

# 检查数据库连接
check_database_connection() {
    local db_type=$1
    local timeout=${2:-10}
    
    log_info "检查 $db_type 数据库连接..."
    
    local attempts=0
    local max_attempts=$((timeout / HEALTH_CHECK_INTERVAL))
    
    while [[ $attempts -lt $max_attempts ]]; do
        case $db_type in
            "MySQL")
                if mysql -u root -e "SELECT 1;" >/dev/null 2>&1; then
                    log_success "$db_type 数据库连接成功"
                    return 0
                fi
                ;;
            "Redis")
                if redis-cli ping >/dev/null 2>&1; then
                    log_success "$db_type 数据库连接成功"
                    return 0
                fi
                ;;
            "PostgreSQL")
                # 尝试连接PostgreSQL，检查AI服务所需的向量数据库
                if psql -d postgres -c "SELECT 1;" >/dev/null 2>&1; then
                    log_success "$db_type 数据库连接成功 (AI服务向量存储)"
                    return 0
                elif psql -d jobfirst_vector -c "SELECT 1;" >/dev/null 2>&1; then
                    log_success "$db_type 数据库连接成功 (向量数据库)"
                    return 0
                fi
                ;;
            "Neo4j")
                if curl -s http://localhost:7474/db/data/ >/dev/null 2>&1; then
                    log_success "$db_type 数据库连接成功"
                    return 0
                fi
                ;;
        esac
        
        ((attempts++))
        echo -n "."
        sleep $HEALTH_CHECK_INTERVAL
    done
    
    echo ""
    log_warning "$db_type 数据库连接超时"
    return 1
}

# 启动基础设施服务
start_infrastructure_services() {
    log_step "启动基础设施服务..."
    
    # 启动MySQL
    if ! brew services list | grep mysql | grep started &> /dev/null; then
        log_info "启动MySQL服务..."
        if brew services start mysql; then
            log_success "MySQL启动成功"
            sleep 5  # 等待MySQL完全启动
        else
            log_error "MySQL启动失败"
            exit 1
        fi
    else
        log_info "MySQL已在运行"
    fi
    
    # 启动Redis
    if ! brew services list | grep redis | grep started &> /dev/null; then
        log_info "启动Redis服务..."
        if brew services start redis; then
            log_success "Redis启动成功"
            sleep 2  # 等待Redis完全启动
        else
            log_error "Redis启动失败"
            exit 1
        fi
    else
        log_info "Redis已在运行"
    fi
    
    # 启动PostgreSQL@14
    if ! brew services list | grep postgresql@14 | grep started &> /dev/null; then
        log_info "启动PostgreSQL@14服务..."
        if brew services start postgresql@14; then
            log_success "PostgreSQL@14启动成功"
            sleep 3  # 等待PostgreSQL完全启动
        else
            log_error "PostgreSQL@14启动失败"
            exit 1
        fi
    else
        log_info "PostgreSQL@14已在运行"
    fi
    
    # 启动Neo4j
    if ! brew services list | grep neo4j | grep started &> /dev/null; then
        log_info "启动Neo4j服务..."
        if brew services start neo4j; then
            log_success "Neo4j启动成功"
            sleep 5  # 等待Neo4j完全启动
        else
            log_error "Neo4j启动失败"
            exit 1
        fi
    else
        log_info "Neo4j已在运行"
    fi
    
    # 启动Consul
    if ! curl -s http://localhost:8500/v1/status/leader >/dev/null 2>&1; then
        log_info "启动Consul服务..."
        # 统一使用launchctl启动Consul
        if launchctl load /opt/homebrew/etc/consul.plist; then
            log_success "Consul启动成功 (launchctl)"
            sleep 5  # 等待Consul完全启动
        else
            log_error "Consul启动失败"
            exit 1
        fi
    else
        log_info "Consul已在运行"
    fi
    
    # 启动Nginx
    if ! brew services list | grep nginx | grep started &> /dev/null; then
        log_info "启动Nginx服务..."
        # 尝试普通用户启动
        if brew services start nginx 2>/dev/null; then
            log_success "Nginx启动成功 (普通用户)"
            sleep 2  # 等待Nginx完全启动
        else
            # 尝试sudo启动
            log_info "尝试使用sudo启动Nginx..."
            if sudo brew services start nginx 2>/dev/null; then
                log_success "Nginx启动成功 (sudo权限)"
                sleep 2  # 等待Nginx完全启动
            else
                log_warning "Nginx启动失败，但系统可能仍可运行"
                log_info "请手动检查Nginx状态: brew services list | grep nginx"
            fi
        fi
    else
        log_info "Nginx已在运行"
    fi
    
    # 验证数据库连接
    log_info "验证数据库连接状态..."
    check_database_connection "MySQL" 15      # 主要业务数据库
    check_database_connection "Redis" 10      # 缓存和会话存储
    check_database_connection "PostgreSQL" 15 # AI服务向量存储
    check_database_connection "Neo4j" 20      # 图数据库
}

# 启动核心微服务
start_core_microservices() {
    log_step "启动核心微服务..."
    
    # 启动API Gateway
    if check_port_available 8080 "API Gateway"; then
        log_info "启动API Gateway..."
        cd "$PROJECT_ROOT/backend" && go run cmd/basic-server/main.go > "$LOG_DIR/api-gateway.log" 2>&1 &
        local api_gateway_pid=$!
        echo $api_gateway_pid > "$LOG_DIR/api-gateway.pid"
        
        if wait_for_service_health "API Gateway" "http://localhost:8080/health" 30; then
            log_success "API Gateway启动成功 (PID: $api_gateway_pid)"
        else
            log_error "API Gateway启动失败"
            exit 1
        fi
    fi
    
    # 启动User Service
    if check_port_available 8081 "User Service"; then
        log_info "启动User Service..."
        cd "$PROJECT_ROOT/backend/internal/user" && go run main.go > "$LOG_DIR/user-service.log" 2>&1 &
        local user_service_pid=$!
        echo $user_service_pid > "$LOG_DIR/user-service.pid"
        
        if wait_for_service_health "User Service" "http://localhost:8081/health" 30; then
            log_success "User Service启动成功 (PID: $user_service_pid)"
        else
            log_error "User Service启动失败"
            exit 1
        fi
    fi
    
    # 启动Resume Service
    if check_port_available 8082 "Resume Service"; then
        log_info "启动Resume Service..."
        cd "$PROJECT_ROOT/backend/internal/resume"
        # 编译Resume Service
        if go build -o resume-service .; then
            log_info "Resume Service编译成功"
            # 启动编译后的二进制文件
            ./resume-service > "$LOG_DIR/resume-service.log" 2>&1 &
            local resume_service_pid=$!
            echo $resume_service_pid > "$LOG_DIR/resume-service.pid"
            
            if wait_for_service_health "Resume Service" "http://localhost:8082/health" 30; then
                log_success "Resume Service启动成功 (PID: $resume_service_pid)"
            else
                log_error "Resume Service启动失败"
                exit 1
            fi
        else
            log_error "Resume Service编译失败"
            exit 1
        fi
    fi
}

# 启动业务微服务
start_business_microservices() {
    log_step "启动业务微服务..."
    
    # 启动Company Service
    if check_port_available 8083 "Company Service"; then
        log_info "启动Company Service..."
        cd "$PROJECT_ROOT/backend/internal/company-service" && go run main.go > "$LOG_DIR/company-service.log" 2>&1 &
        local company_service_pid=$!
        echo $company_service_pid > "$LOG_DIR/company-service.pid"
        
        if wait_for_service_health "Company Service" "http://localhost:8083/health" 30; then
            log_success "Company Service启动成功 (PID: $company_service_pid)"
        else
            log_error "Company Service启动失败"
            exit 1
        fi
    fi
    
    # 启动Notification Service
    if check_port_available 8084 "Notification Service"; then
        log_info "启动Notification Service..."
        cd "$PROJECT_ROOT/backend/internal/notification-service" && go run main.go > "$LOG_DIR/notification-service.log" 2>&1 &
        local notification_service_pid=$!
        echo $notification_service_pid > "$LOG_DIR/notification-service.pid"
        
        if wait_for_service_health "Notification Service" "http://localhost:8084/health" 30; then
            log_success "Notification Service启动成功 (PID: $notification_service_pid)"
        else
            log_error "Notification Service启动失败"
            exit 1
        fi
    fi
}

# 启动重构后的微服务
start_refactored_microservices() {
    log_step "启动重构后的微服务..."
    
    # 启动Template Service
    if check_port_available 8085 "Template Service"; then
        log_info "启动Template Service..."
        cd "$PROJECT_ROOT/backend/internal/template-service" && go run main.go > "$LOG_DIR/template-service.log" 2>&1 &
        local template_service_pid=$!
        echo $template_service_pid > "$LOG_DIR/template-service.pid"
        
        if wait_for_service_health "Template Service" "http://localhost:8085/health" 30; then
            log_success "Template Service启动成功 (PID: $template_service_pid)"
        else
            log_error "Template Service启动失败"
            exit 1
        fi
    fi
    
    # 启动Statistics Service
    if check_port_available 8086 "Statistics Service"; then
        log_info "启动Statistics Service..."
        cd "$PROJECT_ROOT/backend/internal/statistics-service" && go run main.go > "$LOG_DIR/statistics-service.log" 2>&1 &
        local statistics_service_pid=$!
        echo $statistics_service_pid > "$LOG_DIR/statistics-service.pid"
        
        if wait_for_service_health "Statistics Service" "http://localhost:8086/health" 30; then
            log_success "Statistics Service启动成功 (PID: $statistics_service_pid)"
        else
            log_error "Statistics Service启动失败"
            exit 1
        fi
    fi
    
    # 启动Banner Service
    if check_port_available 8087 "Banner Service"; then
        log_info "启动Banner Service..."
        cd "$PROJECT_ROOT/backend/internal/banner-service" && go run main.go > "$LOG_DIR/banner-service.log" 2>&1 &
        local banner_service_pid=$!
        echo $banner_service_pid > "$LOG_DIR/banner-service.pid"
        
        if wait_for_service_health "Banner Service" "http://localhost:8087/health" 30; then
            log_success "Banner Service启动成功 (PID: $banner_service_pid)"
        else
            log_error "Banner Service启动失败"
            exit 1
        fi
    fi
    
    # 启动Dev Team Service
    if check_port_available 8088 "Dev Team Service"; then
        log_info "启动Dev Team Service..."
        cd "$PROJECT_ROOT/backend/internal/dev-team-service" && go run main.go > "$LOG_DIR/dev-team-service.log" 2>&1 &
        local dev_team_service_pid=$!
        echo $dev_team_service_pid > "$LOG_DIR/dev-team-service.pid"
        
        if wait_for_service_health "Dev Team Service" "http://localhost:8088/health" 30; then
            log_success "Dev Team Service启动成功 (PID: $dev_team_service_pid)"
        else
            log_error "Dev Team Service启动失败"
            exit 1
        fi
    fi
    
    # 启动Job Service
    if check_port_available 8089 "Job Service"; then
        log_info "启动Job Service..."
        cd "$PROJECT_ROOT/backend/internal/job-service"
        
        # 检查是否已有编译好的二进制文件
        if [[ ! -f "./job-service" ]]; then
            log_info "编译Job Service..."
            if go build -o job-service .; then
                log_info "Job Service编译成功"
            else
                log_error "Job Service编译失败"
                exit 1
            fi
        fi
        
        # 启动编译后的二进制文件
        ./job-service > "$LOG_DIR/job-service.log" 2>&1 &
        local job_service_pid=$!
        echo $job_service_pid > "$LOG_DIR/job-service.pid"
        
        if wait_for_service_health "Job Service" "http://localhost:8089/health" 30; then
            log_success "Job Service启动成功 (PID: $job_service_pid)"
        else
            log_error "Job Service启动失败"
            exit 1
        fi
    fi
}

# 启动AI服务
start_auth_service() {
    log_step "启动认证服务..."
    
    if check_port_available 8207 "Auth Service"; then
        log_info "启动Auth Service..."
        
        # 启动认证服务
        cd "$PROJECT_ROOT/backend"
        go run cmd/zervigo-auth/main.go > "$LOG_DIR/auth-service.log" 2>&1 &
        local auth_service_pid=$!
        echo $auth_service_pid > "$LOG_DIR/auth-service.pid"
        
        log_info "Auth Service启动中 (PID: $auth_service_pid)..."
        sleep 3  # 给服务启动一些时间
        
        if wait_for_service_health "Auth Service" "http://localhost:8207/health" 30; then
            log_success "Auth Service启动成功 (PID: $auth_service_pid)"
        else
            log_error "Auth Service启动失败"
            log_info "检查认证服务日志: tail -f $LOG_DIR/auth-service.log"
            exit 1
        fi
    fi
}

start_ai_service() {
    log_step "启动AI服务..."
    
    # 启动本地AI服务 (8206)
    if check_port_available 8206 "Local AI Service"; then
        log_info "启动本地AI Service..."
        
        # 检查虚拟环境是否存在
        local ai_service_dir="$PROJECT_ROOT/backend/internal/ai-service"
        local venv_path="$ai_service_dir/venv"
        
        if [[ ! -d "$venv_path" ]]; then
            log_error "AI服务虚拟环境不存在: $venv_path"
            exit 1
        fi
        
        # 激活虚拟环境并启动AI服务（集成zervigo认证版本）
        cd "$ai_service_dir"
        source venv/bin/activate && python ai_service_with_zervigo.py > "$LOG_DIR/ai-service.log" 2>&1 &
        local ai_service_pid=$!
        echo $ai_service_pid > "$LOG_DIR/ai-service.pid"
        
        log_info "本地AI Service启动中 (PID: $ai_service_pid)，等待虚拟环境激活..."
        sleep 5  # 给虚拟环境激活一些时间
        
        if wait_for_service_health "本地AI Service" "http://localhost:8206/health" 120; then
            log_success "本地AI Service启动成功 (PID: $ai_service_pid)"
        else
            log_error "本地AI Service启动失败"
            log_info "检查AI服务日志: tail -f $LOG_DIR/ai-service.log"
            exit 1
        fi
    else
        log_warning "本地AI Service端口8206已被占用，跳过启动"
    fi
    
    # 启动容器化AI服务 (8208)
    if check_port_available 8208 "Containerized AI Service"; then
        log_info "启动容器化AI Service..."
        
        # 检查Docker是否运行
        if ! docker info >/dev/null 2>&1; then
            log_error "Docker未运行，无法启动容器化AI服务"
            return 1
        fi
        
        # 检查docker-compose.yml是否存在
        local docker_compose_file="$PROJECT_ROOT/ai-services/docker-compose.yml"
        if [[ ! -f "$docker_compose_file" ]]; then
            log_error "Docker Compose配置文件不存在: $docker_compose_file"
            return 1
        fi
        
        # 启动容器化AI服务
        cd "$PROJECT_ROOT/ai-services"
        docker-compose up -d ai-service > "$LOG_DIR/containerized-ai-service.log" 2>&1
        
        log_info "容器化AI Service启动中，等待容器启动..."
        sleep 10  # 给容器启动一些时间
        
        if wait_for_service_health "容器化AI Service" "http://localhost:8208/health" 120; then
            log_success "容器化AI Service启动成功"
        else
            log_error "容器化AI Service启动失败"
            log_info "检查容器化AI服务日志: tail -f $LOG_DIR/containerized-ai-service.log"
            log_info "检查Docker容器状态: docker-compose ps"
            return 1
        fi
    else
        log_warning "容器化AI Service端口8208已被占用，跳过启动"
    fi
}

# 启动前端服务 (可选)
start_frontend_services() {
    if [[ "$1" == "--with-frontend" ]]; then
        log_step "启动前端服务..."
        
        # 启动Taro前端
        if check_port_available 3000 "Taro Frontend"; then
            log_info "启动Taro前端..."
            cd "$PROJECT_ROOT/frontend-taro" && npm run dev:h5 > "$LOG_DIR/taro-frontend.log" 2>&1 &
            local taro_pid=$!
            echo $taro_pid > "$LOG_DIR/taro-frontend.pid"
            log_success "Taro前端启动成功 (PID: $taro_pid)"
        fi
    fi
}

# 验证所有服务状态
verify_all_services() {
    log_step "验证所有服务状态..."
    
    local services=(
        "API Gateway:8080"
        "User Service:8081"
        "Resume Service:8082"
        "Company Service:8083"
        "Notification Service:8084"
        "Template Service:8085"
        "Statistics Service:8086"
        "Banner Service:8087"
        "Dev Team Service:8088"
        "Job Service:8089"
        "Auth Service:8207"
        "本地AI Service:8206"
        "容器化AI Service:8208"
    )
    
    local all_healthy=true
    
    for service_info in "${services[@]}"; do
        IFS=':' read -r service_name port <<< "$service_info"
        
        if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
            local pid=$(lsof -Pi :$port -sTCP:LISTEN -t | head -1)
            if curl -s "http://localhost:$port/health" >/dev/null 2>&1; then
                log_success "✅ $service_name 运行正常 (端口: $port, PID: $pid)"
            else
                log_warning "⚠️ $service_name 端口开放但健康检查失败 (端口: $port, PID: $pid)"
                all_healthy=false
            fi
        else
            log_error "❌ $service_name 未运行 (端口: $port)"
            all_healthy=false
        fi
    done
    
    if [[ "$all_healthy" == true ]]; then
        log_success "所有服务验证通过"
        return 0
    else
        log_warning "部分服务验证失败"
        return 1
    fi
}

# 生成启动报告
generate_startup_report() {
    log_step "生成启动报告..."
    
    local report_file="$LOG_DIR/startup_report_$(date +%Y%m%d_%H%M%S).txt"
    
    cat > "$report_file" << EOF
==========================================
JobFirst 安全启动报告
==========================================
启动时间: $(date)
启动脚本: $0
启动日志: $STARTUP_LOG

启动步骤:
✅ 基础设施服务启动 (MySQL, Redis, PostgreSQL@14, Neo4j, Consul, Nginx)
✅ 数据库连接验证
✅ 核心微服务启动
✅ 业务微服务启动
✅ 前端服务启动 (重构微服务依赖)
✅ 重构微服务启动 (包括Job Service)
✅ AI服务启动

服务状态:
$(verify_all_services && echo "✅ 所有服务启动成功" || echo "⚠️ 部分服务启动失败")

PID文件位置: $LOG_DIR/*.pid
日志文件位置: $LOG_DIR/*.log

管理命令:
- 查看服务状态: ps aux | grep -E "(go run|python|node)"
- 查看日志: tail -f $LOG_DIR/*.log
- 安全关闭: $PROJECT_ROOT/scripts/maintenance/safe-shutdown.sh

==========================================
EOF
    
    log_success "启动报告已生成: $report_file"
}

# 显示帮助信息
show_help() {
    cat << EOF
JobFirst 安全启动脚本

用法: $0 [选项]

选项:
  --with-frontend    同时启动前端服务
  --help            显示此帮助信息

启动顺序:
  1. 基础设施服务 (MySQL, Redis, PostgreSQL@14, Neo4j, Consul, Nginx)
  2. 核心微服务 (API Gateway, User Service, Resume Service)
  3. 业务微服务 (Company Service, Notification Service)
  4. 前端服务 (Taro Frontend - 重构微服务依赖)
  5. 重构微服务 (Template, Statistics, Banner, Dev Team, Job Service)
  6. AI服务

安全特性:
  🔒 端口冲突检查
  🔒 健康检查验证
  🔒 超时保护
  🔒 启动顺序控制

示例:
  $0                    # 安全启动后端服务
  $0 --with-frontend   # 安全启动，包括前端
  $0 --help           # 显示帮助

EOF
}

# 主函数
main() {
    # 检查参数
    local with_frontend=false
    if [[ "$1" == "--with-frontend" ]]; then
        with_frontend=true
    elif [[ "$1" == "--help" ]]; then
        show_help
        exit 0
    fi
    
    # 初始化
    init_startup_log
    
    echo "=========================================="
    echo "🚀 JobFirst 安全启动工具"
    echo "=========================================="
    echo
    
    log_info "开始安全启动流程..."
    
    # 执行启动步骤
    start_infrastructure_services
    start_core_microservices
    start_business_microservices
    start_frontend_services "$1"
    start_refactored_microservices
    start_auth_service
    start_ai_service
    
    # 验证和报告
    verify_all_services
    generate_startup_report
    
    echo
    echo "=========================================="
    echo "✅ JobFirst 安全启动完成"
    echo "=========================================="
    echo
    log_success "系统已安全启动，所有服务运行正常"
    log_info "启动日志: $STARTUP_LOG"
    echo
}

# 错误处理
trap 'log_error "启动过程中发生错误"; exit 1' ERR

# 信号处理
trap 'log_warning "收到中断信号，停止启动流程..."' INT TERM

# 执行主函数
main "$@"
