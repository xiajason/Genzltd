#!/bin/bash

# JobFirst 智能启动脚本 - 混合启动模式
# 基于项目现状和开发调试需求设计
# 支持开发、测试、生产三种启动模式

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
STARTUP_LOG="$LOG_DIR/smart-startup.log"

# 启动超时配置
SERVICE_START_TIMEOUT=30
HEALTH_CHECK_INTERVAL=5
MAX_HEALTH_CHECK_ATTEMPTS=12

# 服务配置 (基于已验证的服务)
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

# 待验证的服务
PENDING_SERVICES=(
    "auth-service:8207"
)

# AI服务配置
AI_SERVICES=(
    "local-ai-service:8206"
    "containerized-ai-service:8208"
    "mineru-service:8001"
    "ai-models-service:8002"
    "ai-monitor-service:9090"
)

# 所有服务（用于状态检查）
ALL_SERVICES=(
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
    "local-ai-service:8206"
    "containerized-ai-service:8208"
    "mineru-service:8001"
    "ai-models-service:8002"
    "ai-monitor-service:9090"
    "unified-auth-service:8207"
    "auth-service:8207"
)

# 启动模式定义
get_startup_mode() {
    case "$1" in
        "development") echo "standalone" ;;
        "testing") echo "hybrid" ;;
        "production") echo "service-discovery" ;;
        *) echo "standalone" ;;
    esac
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

log_mode() {
    echo -e "${CYAN}[MODE]${NC} $1" | tee -a "$STARTUP_LOG"
}

# 创建必要的目录
create_directories() {
    mkdir -p "$LOG_DIR"
    mkdir -p "$PROJECT_ROOT/backend/uploads"
    mkdir -p "$PROJECT_ROOT/backend/temp"
}

# 初始化启动日志
init_startup_log() {
    echo "==========================================" >> "$STARTUP_LOG"
    echo "JobFirst 智能启动开始 - $(date)" >> "$STARTUP_LOG"
    echo "==========================================" >> "$STARTUP_LOG"
}

# 检测启动模式
detect_startup_mode() {
    local mode=""
    
    # 1. 检查环境变量
    if [[ -n "$BASIC_SERVER_MODE" ]]; then
        mode="$BASIC_SERVER_MODE"
        log_mode "使用环境变量指定的启动模式: $mode"
    elif [[ -n "$ENVIRONMENT" ]]; then
        mode=$(get_startup_mode "$ENVIRONMENT")
        log_mode "根据环境变量ENVIRONMENT=$ENVIRONMENT选择模式: $mode"
    else
        # 2. 检查Consul可用性
        if check_consul_availability; then
            mode="hybrid"
            log_mode "检测到Consul可用，使用混合模式"
        else
            mode="standalone"
            log_mode "Consul不可用，使用独立模式"
        fi
    fi
    
    echo "$mode"
}

# 检查Consul可用性
check_consul_availability() {
    if curl -s http://localhost:8500/v1/status/leader >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# 检查端口是否可用
check_port_available() {
    local port=$1
    local service_name=$2
    
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        log_warning "$service_name 端口 $port 已被占用"
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

# 启动基础设施服务
start_infrastructure_services() {
    log_step "启动基础设施服务..."
    
    # 启动MySQL
    if ! brew services list | grep mysql | grep started &> /dev/null; then
        log_info "启动MySQL服务..."
        if brew services start mysql; then
            log_success "MySQL启动成功"
            sleep 5
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
            sleep 3
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
            sleep 5
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
            sleep 5
        else
            log_error "Neo4j启动失败"
            exit 1
        fi
    else
        log_info "Neo4j已在运行"
    fi
}

# 启动Consul服务（统一使用brew services）
start_consul_service() {
    local mode=$1
    
    if [[ "$mode" == "standalone" ]]; then
        log_info "独立模式：跳过Consul启动"
        return 0
    fi
    
    log_info "启动Consul服务发现..."
    
    if ! check_consul_availability; then
        # 统一使用launchctl启动Consul
        log_info "使用launchctl启动Consul..."
        if launchctl load /opt/homebrew/etc/consul.plist; then
            log_success "Consul启动成功 (launchctl)"
            sleep 5
        else
            log_warning "Consul启动失败，继续使用独立模式"
            return 1
        fi
    else
        log_info "Consul已在运行"
    fi
}

# 启动Basic-Server
start_basic_server() {
    local mode=$1
    
    log_step "启动Basic-Server (模式: $mode)..."
    
    if check_port_available 8080 "Basic-Server"; then
        log_info "启动Basic-Server..."
        
        # 设置环境变量
        export BASIC_SERVER_MODE="$mode"
        if [[ "$mode" == "standalone" ]]; then
            export CONSUL_ENABLED=false
        else
            export CONSUL_ENABLED=true
        fi
        
        cd "$PROJECT_ROOT/backend/cmd/basic-server"
        ./start_basic_server.sh start
        local basic_server_pid=$(cat "$LOG_DIR/basic-server.pid" 2>/dev/null || echo "")
        
        if wait_for_service_health "Basic-Server" "http://localhost:8080/health" 30; then
            log_success "Basic-Server启动成功 (PID: $basic_server_pid, 模式: $mode)"
        else
            log_error "Basic-Server启动失败"
            exit 1
        fi
    else
        log_error "Basic-Server端口8080被占用"
        exit 1
    fi
}

# 启动已验证的核心微服务
start_verified_core_microservices() {
    local mode=$1
    
    log_step "启动已验证的核心微服务..."
    
    # 启动User Service
    if check_port_available 8081 "User Service"; then
        log_info "启动User Service..."
        cd "$PROJECT_ROOT/backend/internal/user"
        ./start_user_service.sh start
        local user_service_pid=$(cat "$LOG_DIR/user-service.pid" 2>/dev/null || echo "")
        
        if wait_for_service_health "User Service" "http://localhost:8081/health" 30; then
            log_success "User Service启动成功 (PID: $user_service_pid)"
        else
            log_warning "User Service启动失败，继续启动其他服务"
        fi
    fi
    
    # 启动Resume Service
    if check_port_available 8082 "Resume Service"; then
        log_info "启动Resume Service..."
        cd "$PROJECT_ROOT/backend/internal/resume"
        
        # 编译Resume Service
        if go build -o resume-service .; then
            log_info "Resume Service编译成功"
            ./resume-service > "$LOG_DIR/resume-service.log" 2>&1 &
            local resume_service_pid=$!
            echo $resume_service_pid > "$LOG_DIR/resume-service.pid"
            
            if wait_for_service_health "Resume Service" "http://localhost:8082/health" 30; then
                log_success "Resume Service启动成功 (PID: $resume_service_pid)"
            else
                log_warning "Resume Service启动失败，继续启动其他服务"
            fi
        else
            log_warning "Resume Service编译失败，跳过启动"
        fi
    fi
}

# 启动业务微服务
start_business_microservices() {
    log_step "启动业务微服务..."
    
    # 启动Company Service
    if check_port_available 8083 "Company Service"; then
        log_info "启动Company Service..."
        cd "$PROJECT_ROOT/backend/internal/company-service"
        go run main.go > "$LOG_DIR/company-service.log" 2>&1 &
        local company_service_pid=$!
        echo $company_service_pid > "$LOG_DIR/company-service.pid"
        
        if wait_for_service_health "Company Service" "http://localhost:8083/health" 30; then
            log_success "Company Service启动成功 (PID: $company_service_pid)"
        else
            log_warning "Company Service启动失败，继续启动其他服务"
        fi
    fi
    
    # 启动Job Service
    if check_port_available 8089 "Job Service"; then
        log_info "启动Job Service..."
        cd "$PROJECT_ROOT/backend/internal/job-service"
        go run main.go > "$LOG_DIR/job-service.log" 2>&1 &
        local job_service_pid=$!
        echo $job_service_pid > "$LOG_DIR/job-service.pid"
        
        if wait_for_service_health "Job Service" "http://localhost:8089/health" 30; then
            log_success "Job Service启动成功 (PID: $job_service_pid)"
        else
            log_warning "Job Service启动失败，继续启动其他服务"
        fi
    fi
}

# 启动统一认证服务
start_unified_auth_service() {
    log_step "启动统一认证服务..."
    
    # 启动统一认证服务
    if check_port_available 8207 "Unified Auth Service"; then
        log_info "启动统一认证服务..."
        cd "$PROJECT_ROOT/backend/cmd/unified-auth"
        
        # 设置环境变量
        export JWT_SECRET="jobfirst-unified-auth-secret-key-2024"
        export DATABASE_URL="root:@tcp(localhost:3306)/jobfirst?charset=utf8mb4&parseTime=True&loc=Local"
        export AUTH_SERVICE_PORT="8207"
        
        ./unified-auth > "$LOG_DIR/unified-auth-service.log" 2>&1 &
        local unified_auth_pid=$!
        echo $unified_auth_pid > "$LOG_DIR/unified-auth-service.pid"
        
        if wait_for_service_health "Unified Auth Service" "http://localhost:8207/health" 30; then
            log_success "统一认证服务启动成功 (PID: $unified_auth_pid)"
        else
            log_warning "统一认证服务启动失败，继续启动其他服务"
        fi
    fi
}

# 启动Company服务
start_company_service() {
    log_step "启动Company服务..."
    
    if check_port_available 8083 "Company Service"; then
        log_info "启动Company服务..."
        cd "$PROJECT_ROOT/backend/internal/company-service"
        
        # 编译Company Service
        log_info "编译Company Service..."
        if go build -o company-service .; then
            log_success "Company Service编译成功"
        else
            log_error "Company Service编译失败"
            return 1
        fi
        
        ./company-service > "$LOG_DIR/company-service.log" 2>&1 &
        local company_pid=$!
        echo $company_pid > "$LOG_DIR/company-service.pid"
        
        if wait_for_service_health "Company Service" "http://localhost:8083/health" 30; then
            log_success "Company服务启动成功 (PID: $company_pid)"
        else
            log_warning "Company服务启动失败，继续启动其他服务"
        fi
    fi
}

# 启动Job服务
start_job_service() {
    log_step "启动Job服务..."
    
    if check_port_available 8089 "Job Service"; then
        log_info "启动Job服务..."
        cd "$PROJECT_ROOT/backend/internal/job-service"
        
        # 编译Job Service
        log_info "编译Job Service..."
        if go build -o job-service .; then
            log_success "Job Service编译成功"
        else
            log_error "Job Service编译失败"
            return 1
        fi
        
        ./job-service > "$LOG_DIR/job-service.log" 2>&1 &
        local job_pid=$!
        echo $job_pid > "$LOG_DIR/job-service.pid"
        
        if wait_for_service_health "Job Service" "http://localhost:8089/health" 30; then
            log_success "Job服务启动成功 (PID: $job_pid)"
        else
            log_warning "Job服务启动失败，继续启动其他服务"
        fi
    fi
}

# 启动Notification服务
start_notification_service() {
    log_step "启动Notification服务..."
    
    if check_port_available 8084 "Notification Service"; then
        log_info "启动Notification服务..."
        cd "$PROJECT_ROOT/backend/internal/notification-service"
        
        # 编译Notification Service
        log_info "编译Notification Service..."
        if go build -o notification-service .; then
            log_success "Notification Service编译成功"
        else
            log_error "Notification Service编译失败"
            return 1
        fi
        
        ./notification-service > "$LOG_DIR/notification-service.log" 2>&1 &
        local notification_pid=$!
        echo $notification_pid > "$LOG_DIR/notification-service.pid"
        
        if wait_for_service_health "Notification Service" "http://localhost:8084/health" 30; then
            log_success "Notification服务启动成功 (PID: $notification_pid)"
        else
            log_warning "Notification服务启动失败，继续启动其他服务"
        fi
    fi
}

# 启动Template服务
start_template_service() {
    log_step "启动Template服务..."
    
    if check_port_available 8085 "Template Service"; then
        log_info "启动Template服务..."
        cd "$PROJECT_ROOT/backend/internal/template-service"
        
        # 编译Template Service
        log_info "编译Template Service..."
        if go build -o template-service .; then
            log_success "Template Service编译成功"
        else
            log_error "Template Service编译失败"
            return 1
        fi
        
        ./template-service > "$LOG_DIR/template-service.log" 2>&1 &
        local template_pid=$!
        echo $template_pid > "$LOG_DIR/template-service.pid"
        
        if wait_for_service_health "Template Service" "http://localhost:8085/health" 30; then
            log_success "Template服务启动成功 (PID: $template_pid)"
        else
            log_warning "Template服务启动失败，继续启动其他服务"
        fi
    fi
}

# 启动Statistics服务
start_statistics_service() {
    log_step "启动Statistics服务..."
    
    if check_port_available 8086 "Statistics Service"; then
        log_info "启动Statistics服务..."
        cd "$PROJECT_ROOT/backend/internal/statistics-service"
        
        # 编译Statistics Service
        log_info "编译Statistics Service..."
        if go build -o statistics-service .; then
            log_success "Statistics Service编译成功"
        else
            log_error "Statistics Service编译失败"
            return 1
        fi
        
        ./statistics-service > "$LOG_DIR/statistics-service.log" 2>&1 &
        local statistics_pid=$!
        echo $statistics_pid > "$LOG_DIR/statistics-service.pid"
        
        if wait_for_service_health "Statistics Service" "http://localhost:8086/health" 30; then
            log_success "Statistics服务启动成功 (PID: $statistics_pid)"
        else
            log_warning "Statistics服务启动失败，继续启动其他服务"
        fi
    fi
}

# 启动Banner服务
start_banner_service() {
    log_step "启动Banner服务..."
    
    if check_port_available 8087 "Banner Service"; then
        log_info "启动Banner服务..."
        cd "$PROJECT_ROOT/backend/internal/banner-service"
        
        # 编译Banner Service
        log_info "编译Banner Service..."
        if go build -o banner-service .; then
            log_success "Banner Service编译成功"
        else
            log_error "Banner Service编译失败"
            return 1
        fi
        
        ./banner-service > "$LOG_DIR/banner-service.log" 2>&1 &
        local banner_pid=$!
        echo $banner_pid > "$LOG_DIR/banner-service.pid"
        
        if wait_for_service_health "Banner Service" "http://localhost:8087/health" 30; then
            log_success "Banner服务启动成功 (PID: $banner_pid)"
        else
            log_warning "Banner服务启动失败，继续启动其他服务"
        fi
    fi
}

# 启动Dev-Team服务
start_dev_team_service() {
    log_step "启动Dev-Team服务..."
    
    if check_port_available 8088 "Dev-Team Service"; then
        log_info "启动Dev-Team服务..."
        cd "$PROJECT_ROOT/backend/internal/dev-team-service"
        
        # 编译Dev-Team Service
        log_info "编译Dev-Team Service..."
        if go build -o dev-team-service .; then
            log_success "Dev-Team Service编译成功"
        else
            log_error "Dev-Team Service编译失败"
            return 1
        fi
        
        ./dev-team-service > "$LOG_DIR/dev-team-service.log" 2>&1 &
        local dev_team_pid=$!
        echo $dev_team_pid > "$LOG_DIR/dev-team-service.pid"
        
        if wait_for_service_health "Dev-Team Service" "http://localhost:8088/health" 30; then
            log_success "Dev-Team服务启动成功 (PID: $dev_team_pid)"
        else
            log_warning "Dev-Team服务启动失败，继续启动其他服务"
        fi
    fi
}

# 启动本地化AI服务
start_local_ai_service() {
    log_step "启动本地化AI服务..."
    
    if check_port_available 8206 "Local AI Service"; then
        log_info "启动本地化AI服务..."
        cd "$PROJECT_ROOT/backend/internal/ai-service"
        
        # 激活Python虚拟环境并启动服务
        source venv/bin/activate && python ai_service_with_zervigo.py > "$LOG_DIR/local-ai-service.log" 2>&1 &
        local ai_service_pid=$!
        echo $ai_service_pid > "$LOG_DIR/local-ai-service.pid"
        
        if wait_for_service_health "Local AI Service" "http://localhost:8206/health" 30; then
            log_success "本地化AI服务启动成功 (PID: $ai_service_pid)"
        else
            log_warning "本地化AI服务启动失败，继续启动其他服务"
        fi
    fi
}

# 启动容器化AI服务
start_containerized_ai_services() {
    log_step "启动容器化AI服务..."
    
    # 检查Docker是否运行
    if ! docker info >/dev/null 2>&1; then
        log_warning "Docker未运行，跳过容器化AI服务启动"
        return 0
    fi
    
    # 启动AI服务容器
    cd "$PROJECT_ROOT/ai-services"
    
    # 启动AI基础服务
    if check_port_available 8208 "Containerized AI Service"; then
        log_info "启动容器化AI基础服务..."
        if docker-compose up -d ai-service; then
            if wait_for_service_health "Containerized AI Service" "http://localhost:8208/health" 60; then
                log_success "容器化AI基础服务启动成功"
            else
                log_warning "容器化AI基础服务健康检查失败"
            fi
        else
            log_warning "容器化AI基础服务启动失败"
        fi
    fi
    
    # 启动MinerU服务
    if check_port_available 8001 "MinerU Service"; then
        log_info "启动MinerU服务..."
        if docker-compose up -d mineru; then
            if wait_for_service_health "MinerU Service" "http://localhost:8001/health" 60; then
                log_success "MinerU服务启动成功"
            else
                log_warning "MinerU服务健康检查失败"
            fi
        else
            log_warning "MinerU服务启动失败"
        fi
    fi
    
    # 启动AI模型服务
    if check_port_available 8002 "AI Models Service"; then
        log_info "启动AI模型服务..."
        if docker-compose up -d ai-models; then
            if wait_for_service_health "AI Models Service" "http://localhost:8002/health" 60; then
                log_success "AI模型服务启动成功"
            else
                log_warning "AI模型服务健康检查失败"
            fi
        else
            log_warning "AI模型服务启动失败"
        fi
    fi
    
    # 启动AI监控服务
    if check_port_available 9090 "AI Monitor Service"; then
        log_info "启动AI监控服务..."
        if docker-compose up -d ai-monitor; then
            if wait_for_service_health "AI Monitor Service" "http://localhost:9090/-/healthy" 60; then
                log_success "AI监控服务启动成功"
            else
                log_warning "AI监控服务健康检查失败"
            fi
        else
            log_warning "AI监控服务启动失败"
        fi
    fi
}

# 启动AI服务（统一入口）
start_ai_services() {
    log_step "启动AI服务集群..."
    
    # 启动本地化AI服务
    start_local_ai_service
    
    # 启动容器化AI服务
    start_containerized_ai_services
}

# 验证服务状态
verify_services() {
    log_step "验证服务状态..."
    
    local running_services=()
    local failed_services=()
    
    for service_info in "${ALL_SERVICES[@]}"; do
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
    
    # 检查数据库服务
    if brew services list | grep mysql | grep started &> /dev/null; then
        log_success "✅ MySQL 正在运行"
    else
        log_warning "❌ MySQL 未运行"
    fi
    
    if brew services list | grep redis | grep started &> /dev/null; then
        log_success "✅ Redis 正在运行"
    else
        log_warning "❌ Redis 未运行"
    fi
    
    if brew services list | grep postgresql@14 | grep started &> /dev/null; then
        log_success "✅ PostgreSQL@14 正在运行"
    else
        log_warning "❌ PostgreSQL@14 未运行"
    fi
    
    if brew services list | grep neo4j | grep started &> /dev/null; then
        log_success "✅ Neo4j 正在运行"
    else
        log_warning "❌ Neo4j 未运行"
    fi
    
    # 检查Consul
    if check_consul_availability; then
        log_success "✅ Consul 正在运行"
    else
        log_info "ℹ️ Consul 未运行 (独立模式)"
    fi
    
    echo "运行中的服务: ${#running_services[@]}"
    echo "失败的服务: ${#failed_services[@]}"
}

# 生成启动报告
generate_startup_report() {
    log_step "生成启动报告..."
    
    local report_file="$LOG_DIR/startup_report_$(date +%Y%m%d_%H%M%S).txt"
    
    cat > "$report_file" << EOF
==========================================
JobFirst 智能启动报告
==========================================
启动时间: $(date)
启动模式: $STARTUP_MODE
启动脚本: $0
启动日志: $STARTUP_LOG

启动步骤:
✅ 基础设施服务启动
✅ 服务发现服务启动 (可选)
✅ 统一认证服务启动
✅ Basic-Server启动
✅ 已验证核心微服务启动
✅ 业务微服务启动
✅ AI服务启动

服务状态:
$(verify_services)

启动模式说明:
- standalone: 独立模式，快速启动，适合开发调试
- hybrid: 混合模式，优先使用服务发现，容错降级
- service-discovery: 服务发现模式，完整微服务架构

==========================================
EOF
    
    log_success "启动报告已生成: $report_file"
}

# 显示帮助信息
show_help() {
    cat << EOF
JobFirst 智能启动脚本 - 混合启动模式

用法: $0 [选项]

选项:
  --mode MODE         指定启动模式 (standalone|hybrid|service-discovery)
  --environment ENV   指定环境 (development|testing|production)
  --help             显示此帮助信息

环境变量:
  BASIC_SERVER_MODE   启动模式 (standalone|hybrid|service-discovery)
  ENVIRONMENT         环境类型 (development|testing|production)
  CONSUL_ENABLED      Consul启用状态 (true|false)

启动模式:
  standalone          独立模式 - 快速启动，无需Consul，适合开发调试
  hybrid             混合模式 - 优先使用Consul，不可用时降级，适合测试
  service-discovery  服务发现模式 - 完整微服务架构，适合生产

启动顺序:
  1. 基础设施服务 (MySQL, Redis, PostgreSQL@14, Neo4j)
  2. 服务发现服务 (Consul - 可选)
  3. 统一认证服务 (Unified Auth Service)
  4. Basic-Server (根据模式启动)
  5. 已验证核心微服务 (User Service, Resume Service)
  6. 业务微服务 (Company, Job, Notification, Template, Statistics, Banner, Dev-Team)
  7. AI服务集群 (本地化AI服务, 容器化AI服务, MinerU, AI模型, AI监控)

示例:
  $0                                    # 自动检测模式
  $0 --mode standalone                  # 独立模式启动
  $0 --mode hybrid                      # 混合模式启动
  $0 --environment development          # 开发环境启动
  $0 --environment production           # 生产环境启动

EOF
}

# 主函数
main() {
    # 解析命令行参数
    local startup_mode=""
    local environment=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --mode)
                startup_mode="$2"
                shift 2
                ;;
            --environment)
                environment="$2"
                shift 2
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
    
    # 设置环境变量
    if [[ -n "$startup_mode" ]]; then
        export BASIC_SERVER_MODE="$startup_mode"
    fi
    if [[ -n "$environment" ]]; then
        export ENVIRONMENT="$environment"
    fi
    
    # 初始化
    create_directories
    init_startup_log
    
    echo "=========================================="
    echo "🚀 JobFirst 智能启动工具 - 混合启动模式"
    echo "=========================================="
    echo
    
    # 检测启动模式
    STARTUP_MODE=$(detect_startup_mode)
    log_mode "最终启动模式: $STARTUP_MODE"
    
    log_info "开始智能启动流程..."
    
    # 执行启动步骤
    start_infrastructure_services
    start_consul_service "$STARTUP_MODE"
    start_unified_auth_service
    start_basic_server "$STARTUP_MODE"
    start_verified_core_microservices "$STARTUP_MODE"
    
    # 启动所有已验证的业务微服务
    start_company_service
    start_job_service
    start_notification_service
    start_template_service
    start_statistics_service
    start_banner_service
    start_dev_team_service
    
    start_ai_services
    
    # 验证和报告
    verify_services
    generate_startup_report
    
    echo
    echo "=========================================="
    echo "✅ JobFirst 智能启动完成"
    echo "=========================================="
    echo
    log_success "系统已智能启动，模式: $STARTUP_MODE"
    log_info "启动日志: $STARTUP_LOG"
    echo
}

# 错误处理
trap 'log_error "启动过程中发生错误"; exit 1' ERR

# 信号处理
trap 'log_warning "收到中断信号，继续启动流程..."' INT TERM

# 执行主函数
main "$@"
