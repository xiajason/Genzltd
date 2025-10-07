#!/bin/bash

# JobFirst Web端联调数据库开发环境启动脚本
# 专门为Web端开发优化的微服务启动方案

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 服务端口定义
API_GATEWAY_PORT=8080
USER_SERVICE_PORT=8081
RESUME_SERVICE_PORT=8082
BANNER_SERVICE_PORT=8083
TEMPLATE_SERVICE_PORT=8084
NOTIFICATION_SERVICE_PORT=8085
STATISTICS_SERVICE_PORT=8086
AI_SERVICE_PORT=8206
FRONTEND_PORT=10086

MYSQL_PORT=3306
POSTGRES_PORT=5432
REDIS_PORT=6379
NEO4J_PORT=7474

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

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

# 检查端口是否被占用
check_port() {
    lsof -i :$1 >/dev/null 2>&1
    return $?
}

# 检查服务是否运行
check_service() {
    local service_name=$1
    local port=$2
    if check_port $port; then
        echo -e "${GREEN}[SUCCESS] $service_name 已在端口 $port 运行${NC}"
        return 0
    else
        echo -e "${RED}[ERROR] $service_name 未在端口 $port 运行${NC}"
        return 1
    fi
}

# 等待服务启动
wait_for_service() {
    local service_name=$1
    local port=$2
    local max_attempts=30
    local attempt=1
    
    log_info "等待 $service_name 启动..."
    
    while [ $attempt -le $max_attempts ]; do
        if check_port $port; then
            log_success "$service_name 启动成功"
            return 0
        fi
        
        echo -n "."
        sleep 1
        attempt=$((attempt + 1))
    done
    
    echo ""
    log_error "$service_name 启动超时"
    return 1
}

# 启动数据库服务
start_databases() {
    log_info "=== 启动数据库服务 ==="
    
    # MySQL
    if check_port $MYSQL_PORT; then
        log_warning "MySQL 已在端口 $MYSQL_PORT 运行"
    else
        log_info "启动 MySQL..."
        brew services start mysql > /dev/null 2>&1
        wait_for_service "MySQL" $MYSQL_PORT
    fi

    # PostgreSQL
    if check_port $POSTGRES_PORT; then
        log_warning "PostgreSQL 已在端口 $POSTGRES_PORT 运行"
    else
        log_info "启动 PostgreSQL..."
        brew services start postgresql@14 > /dev/null 2>&1
        wait_for_service "PostgreSQL" $POSTGRES_PORT
    fi

    # Redis
    if check_port $REDIS_PORT; then
        log_warning "Redis 已在端口 $REDIS_PORT 运行"
    else
        log_info "启动 Redis..."
        brew services start redis > /dev/null 2>&1
        wait_for_service "Redis" $REDIS_PORT
    fi

    # Neo4j
    if check_port $NEO4J_PORT; then
        log_warning "Neo4j 已在端口 $NEO4J_PORT 运行"
    else
        log_info "启动 Neo4j..."
        brew services start neo4j > /dev/null 2>&1
        wait_for_service "Neo4j" $NEO4J_PORT
    fi
}

# 初始化数据库
init_databases() {
    log_info "=== 初始化数据库 ==="
    
    # 初始化MySQL数据库
    log_info "初始化MySQL数据库..."
    mysql -u root -e "CREATE DATABASE IF NOT EXISTS jobfirst CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null || true
    mysql -u root -e "CREATE USER IF NOT EXISTS 'jobfirst'@'localhost' IDENTIFIED BY 'jobfirst123';" 2>/dev/null || true
    mysql -u root -e "GRANT ALL PRIVILEGES ON jobfirst.* TO 'jobfirst'@'localhost';" 2>/dev/null || true
    mysql -u root -e "FLUSH PRIVILEGES;" 2>/dev/null || true
    
    # 执行数据库初始化脚本
    if [ -f "$PROJECT_ROOT/database/mysql/init.sql" ]; then
        mysql -u root jobfirst < "$PROJECT_ROOT/database/mysql/init.sql"
        log_success "MySQL数据库初始化完成"
    fi
    
    # 初始化PostgreSQL数据库
    log_info "初始化PostgreSQL数据库..."
    createdb -U szjason72 jobfirst_vector 2>/dev/null || true
    if [ -f "$PROJECT_ROOT/database/postgresql/init.sql" ]; then
        psql -U szjason72 -d jobfirst_vector -f "$PROJECT_ROOT/database/postgresql/init.sql" > /dev/null 2>&1
        log_success "PostgreSQL数据库初始化完成"
    fi
}

# 启动API Gateway
start_api_gateway() {
    log_info "=== 启动API Gateway (热加载模式) ==="
    if check_port $API_GATEWAY_PORT; then
        log_warning "API Gateway 已在端口 $API_GATEWAY_PORT 运行"
    else
        log_info "启动API Gateway服务 (air热加载)..."
        cd "$PROJECT_ROOT/backend"
        
        # 检查air是否安装
        if ! command -v air &> /dev/null; then
            log_info "安装air热加载工具..."
            go install github.com/cosmtrek/air@latest
        fi
        
        # 启动服务
        air &
        API_GATEWAY_PID=$!
        echo $API_GATEWAY_PID > /tmp/jobfirst_api_gateway.pid
        
        wait_for_service "API Gateway" $API_GATEWAY_PORT
        cd "$PROJECT_ROOT"
    fi
}

# 启动User Service (使用Company Service作为用户相关服务)
start_user_service() {
    log_info "=== 启动User Service (热加载模式) ==="
    if check_port $USER_SERVICE_PORT; then
        log_warning "User Service 已在端口 $USER_SERVICE_PORT 运行"
    else
        log_info "启动User Service (air热加载)..."
        cd "$PROJECT_ROOT/backend/internal/company-service"
        
        # 启动服务
        air &
        USER_SERVICE_PID=$!
        echo $USER_SERVICE_PID > /tmp/jobfirst_user_service.pid
        
        wait_for_service "User Service" $USER_SERVICE_PORT
        cd "$PROJECT_ROOT"
    fi
}

# 启动Resume Service
start_resume_service() {
    log_info "=== 启动Resume Service (热加载模式) ==="
    if check_port $RESUME_SERVICE_PORT; then
        log_warning "Resume Service 已在端口 $RESUME_SERVICE_PORT 运行"
    else
        log_info "启动Resume Service (air热加载)..."
        cd "$PROJECT_ROOT/backend/internal/resume"
        
        # 启动服务
        air &
        RESUME_SERVICE_PID=$!
        echo $RESUME_SERVICE_PID > /tmp/jobfirst_resume_service.pid
        
        wait_for_service "Resume Service" $RESUME_SERVICE_PORT
        cd "$PROJECT_ROOT"
    fi
}

# 启动Banner Service
start_banner_service() {
    log_info "=== 启动Banner Service (热加载模式) ==="
    if check_port $BANNER_SERVICE_PORT; then
        log_warning "Banner Service 已在端口 $BANNER_SERVICE_PORT 运行"
    else
        log_info "启动Banner Service (air热加载)..."
        cd "$PROJECT_ROOT/backend/internal/banner-service"
        
        # 启动服务
        air &
        BANNER_SERVICE_PID=$!
        echo $BANNER_SERVICE_PID > /tmp/jobfirst_banner_service.pid
        
        wait_for_service "Banner Service" $BANNER_SERVICE_PORT
        cd "$PROJECT_ROOT"
    fi
}

# 启动Template Service
start_template_service() {
    log_info "=== 启动Template Service (热加载模式) ==="
    if check_port $TEMPLATE_SERVICE_PORT; then
        log_warning "Template Service 已在端口 $TEMPLATE_SERVICE_PORT 运行"
    else
        log_info "启动Template Service (air热加载)..."
        cd "$PROJECT_ROOT/backend/internal/template-service"
        
        # 启动服务
        air &
        TEMPLATE_SERVICE_PID=$!
        echo $TEMPLATE_SERVICE_PID > /tmp/jobfirst_template_service.pid
        
        wait_for_service "Template Service" $TEMPLATE_SERVICE_PORT
        cd "$PROJECT_ROOT"
    fi
}

# 启动Notification Service
start_notification_service() {
    log_info "=== 启动Notification Service (热加载模式) ==="
    if check_port $NOTIFICATION_SERVICE_PORT; then
        log_warning "Notification Service 已在端口 $NOTIFICATION_SERVICE_PORT 运行"
    else
        log_info "启动Notification Service (air热加载)..."
        cd "$PROJECT_ROOT/backend/internal/notification-service"
        
        # 启动服务
        air &
        NOTIFICATION_SERVICE_PID=$!
        echo $NOTIFICATION_SERVICE_PID > /tmp/jobfirst_notification_service.pid
        
        wait_for_service "Notification Service" $NOTIFICATION_SERVICE_PORT
        cd "$PROJECT_ROOT"
    fi
}

# 启动Statistics Service
start_statistics_service() {
    log_info "=== 启动Statistics Service (热加载模式) ==="
    if check_port $STATISTICS_SERVICE_PORT; then
        log_warning "Statistics Service 已在端口 $STATISTICS_SERVICE_PORT 运行"
    else
        log_info "启动Statistics Service (air热加载)..."
        cd "$PROJECT_ROOT/backend/internal/statistics-service"
        
        # 启动服务
        air &
        STATISTICS_SERVICE_PID=$!
        echo $STATISTICS_SERVICE_PID > /tmp/jobfirst_statistics_service.pid
        
        wait_for_service "Statistics Service" $STATISTICS_SERVICE_PORT
        cd "$PROJECT_ROOT"
    fi
}

# 启动AI Service
start_ai_service() {
    log_info "=== 启动AI Service (热加载模式) ==="
    
    # 检查依赖服务
    if ! check_port $USER_SERVICE_PORT; then
        log_error "AI Service 需要 User Service 先启动 (端口 $USER_SERVICE_PORT)"
        return 1
    fi
    
    if ! check_port $API_GATEWAY_PORT; then
        log_error "AI Service 需要 API Gateway 先启动 (端口 $API_GATEWAY_PORT)"
        return 1
    fi
    
    if check_port $AI_SERVICE_PORT; then
        log_warning "AI Service 已在端口 $AI_SERVICE_PORT 运行"
    else
        log_info "启动AI Service (Sanic热加载)..."
        cd "$PROJECT_ROOT/backend/internal/ai-service"
        
        # 检查虚拟环境
        if [ ! -d "venv" ]; then
            log_info "创建Python虚拟环境..."
            python3 -m venv venv
        fi
        
        source venv/bin/activate
        
        # 检查依赖
        if ! python -c "import sanic, psycopg2" 2>/dev/null; then
            log_info "安装Python依赖..."
            pip install -r requirements.txt
        fi
        
        # 启动AI服务
        python ai_service.py &
        AI_SERVICE_PID=$!
        echo $AI_SERVICE_PID > /tmp/jobfirst_ai_service.pid
        
        wait_for_service "AI Service" $AI_SERVICE_PORT
        cd "$PROJECT_ROOT"
    fi
}

# 启动前端开发服务器
start_frontend() {
    log_info "=== 启动前端开发服务器 ==="
    if check_port $FRONTEND_PORT; then
        log_warning "前端开发服务器已在端口 $FRONTEND_PORT 运行"
    else
        log_info "启动Taro前端开发服务器..."
        cd "$PROJECT_ROOT/frontend-taro"
        
        # 检查依赖
        if [ ! -d "node_modules" ]; then
            log_info "安装前端依赖..."
            npm install
        fi
        
        # 启动开发服务器
        npm run dev:h5 &
        FRONTEND_PID=$!
        echo $FRONTEND_PID > /tmp/jobfirst_frontend.pid
        
        wait_for_service "前端开发服务器" $FRONTEND_PORT
        cd "$PROJECT_ROOT"
    fi
}

# 健康检查
health_check() {
    log_info "=== 开发环境健康检查 ==="
    
    # 检查数据库连接
    log_info "检查数据库连接..."
    mysql -u root -e "SELECT 1;" > /dev/null 2>&1
    if [ $? -eq 0 ]; then 
        log_success "MySQL 连接正常"
    else 
        log_error "MySQL 连接失败"
    fi
    
    psql -U szjason72 -d jobfirst_vector -c "SELECT 1;" > /dev/null 2>&1
    if [ $? -eq 0 ]; then 
        log_success "PostgreSQL 连接正常"
    else 
        log_error "PostgreSQL 连接失败"
    fi
    
    redis-cli ping > /dev/null 2>&1
    if [ $? -eq 0 ]; then 
        log_success "Redis 连接正常"
    else 
        log_error "Redis 连接失败"
    fi
    
    # 检查微服务
    log_info "检查微服务..."
    curl -s http://localhost:$API_GATEWAY_PORT/health | grep -q '"status":"healthy"'
    if [ $? -eq 0 ]; then 
        log_success "API Gateway 健康检查通过"
    else 
        log_error "API Gateway 健康检查失败"
    fi
    
    curl -s http://localhost:$USER_SERVICE_PORT/health | grep -q '"status":"healthy"'
    if [ $? -eq 0 ]; then 
        log_success "User Service 健康检查通过"
    else 
        log_error "User Service 健康检查失败"
    fi
    
    curl -s http://localhost:$RESUME_SERVICE_PORT/health | grep -q '"status":"healthy"'
    if [ $? -eq 0 ]; then 
        log_success "Resume Service 健康检查通过"
    else 
        log_error "Resume Service 健康检查失败"
    fi
    
    curl -s http://localhost:$BANNER_SERVICE_PORT/health | grep -q '"status":"healthy"'
    if [ $? -eq 0 ]; then 
        log_success "Banner Service 健康检查通过"
    else 
        log_error "Banner Service 健康检查失败"
    fi
    
    curl -s http://localhost:$TEMPLATE_SERVICE_PORT/health | grep -q '"status":"healthy"'
    if [ $? -eq 0 ]; then 
        log_success "Template Service 健康检查通过"
    else 
        log_error "Template Service 健康检查失败"
    fi
    
    curl -s http://localhost:$NOTIFICATION_SERVICE_PORT/health | grep -q '"status":"healthy"'
    if [ $? -eq 0 ]; then 
        log_success "Notification Service 健康检查通过"
    else 
        log_error "Notification Service 健康检查失败"
    fi
    
    curl -s http://localhost:$STATISTICS_SERVICE_PORT/health | grep -q '"status":"healthy"'
    if [ $? -eq 0 ]; then 
        log_success "Statistics Service 健康检查通过"
    else 
        log_error "Statistics Service 健康检查失败"
    fi
    
    curl -s http://localhost:$AI_SERVICE_PORT/health | grep -q '"status":"healthy"'
    if [ $? -eq 0 ]; then 
        log_success "AI Service 健康检查通过"
    else 
        log_error "AI Service 健康检查失败"
    fi
    
    # 检查前端
    curl -s http://localhost:$FRONTEND_PORT > /dev/null 2>&1
    if [ $? -eq 0 ]; then 
        log_success "前端服务运行正常"
    else 
        log_error "前端服务运行异常"
    fi
}

# 显示服务状态
show_status() {
    log_info "=== Web端开发环境服务状态 ==="
    echo ""
    echo -e "${CYAN}数据库服务:${NC}"
    echo "  MySQL ($MYSQL_PORT): $(if check_port $MYSQL_PORT; then echo -e "${GREEN}运行中${NC}"; else echo -e "${RED}未运行${NC}"; fi)"
    echo "  PostgreSQL ($POSTGRES_PORT): $(if check_port $POSTGRES_PORT; then echo -e "${GREEN}运行中${NC}"; else echo -e "${RED}未运行${NC}"; fi)"
    echo "  Redis ($REDIS_PORT): $(if check_port $REDIS_PORT; then echo -e "${GREEN}运行中${NC}"; else echo -e "${RED}未运行${NC}"; fi)"
    echo "  Neo4j ($NEO4J_PORT): $(if check_port $NEO4J_PORT; then echo -e "${GREEN}运行中${NC}"; else echo -e "${RED}未运行${NC}"; fi)"
    echo ""
    echo -e "${CYAN}微服务 (热加载模式):${NC}"
    echo "  API Gateway ($API_GATEWAY_PORT): $(if check_port $API_GATEWAY_PORT; then echo -e "${GREEN}运行中 (air)${NC}"; else echo -e "${RED}未运行${NC}"; fi)"
    echo "  User Service ($USER_SERVICE_PORT): $(if check_port $USER_SERVICE_PORT; then echo -e "${GREEN}运行中 (air)${NC}"; else echo -e "${RED}未运行${NC}"; fi)"
    echo "  Resume Service ($RESUME_SERVICE_PORT): $(if check_port $RESUME_SERVICE_PORT; then echo -e "${GREEN}运行中 (air)${NC}"; else echo -e "${RED}未运行${NC}"; fi)"
    echo "  Banner Service ($BANNER_SERVICE_PORT): $(if check_port $BANNER_SERVICE_PORT; then echo -e "${GREEN}运行中 (air)${NC}"; else echo -e "${RED}未运行${NC}"; fi)"
    echo "  Template Service ($TEMPLATE_SERVICE_PORT): $(if check_port $TEMPLATE_SERVICE_PORT; then echo -e "${GREEN}运行中 (air)${NC}"; else echo -e "${RED}未运行${NC}"; fi)"
    echo "  Notification Service ($NOTIFICATION_SERVICE_PORT): $(if check_port $NOTIFICATION_SERVICE_PORT; then echo -e "${GREEN}运行中 (air)${NC}"; else echo -e "${RED}未运行${NC}"; fi)"
    echo "  Statistics Service ($STATISTICS_SERVICE_PORT): $(if check_port $STATISTICS_SERVICE_PORT; then echo -e "${GREEN}运行中 (air)${NC}"; else echo -e "${RED}未运行${NC}"; fi)"
    echo "  AI Service ($AI_SERVICE_PORT): $(if check_port $AI_SERVICE_PORT; then echo -e "${GREEN}运行中 (Sanic reload)${NC}"; else echo -e "${RED}未运行${NC}"; fi)"
    echo ""
    echo -e "${CYAN}前端服务:${NC}"
    echo "  Taro H5 ($FRONTEND_PORT): $(if check_port $FRONTEND_PORT; then echo -e "${GREEN}运行中${NC}"; else echo -e "${RED}未运行${NC}"; fi)"
    echo ""
    echo -e "${PURPLE}访问地址:${NC}"
    echo "  🌐 前端应用: http://localhost:$FRONTEND_PORT"
    echo "  🔗 API Gateway: http://localhost:$API_GATEWAY_PORT"
    echo "  🤖 AI Service: http://localhost:$AI_SERVICE_PORT"
    echo "  📊 Neo4j Browser: http://localhost:$NEO4J_PORT"
    echo ""
    echo -e "${PURPLE}开发工具:${NC}"
    echo "  📝 前端开发: 修改代码自动热重载"
    echo "  🔧 后端开发: 修改Go代码自动重启"
    echo "  🐍 AI服务: 修改Python代码自动重启"
    echo "  💾 数据库: 支持实时数据操作"
}

# 停止所有服务
stop_all_services() {
    log_info "=== 停止所有开发服务 ==="
    
    # 停止前端
    if [ -f /tmp/jobfirst_frontend.pid ]; then
        FRONTEND_PID=$(cat /tmp/jobfirst_frontend.pid)
        kill $FRONTEND_PID 2>/dev/null
        rm -f /tmp/jobfirst_frontend.pid
        log_success "前端服务已停止"
    fi
    
    # 停止AI服务
    if [ -f /tmp/jobfirst_ai_service.pid ]; then
        AI_SERVICE_PID=$(cat /tmp/jobfirst_ai_service.pid)
        kill $AI_SERVICE_PID 2>/dev/null
        rm -f /tmp/jobfirst_ai_service.pid
        log_success "AI服务已停止"
    fi
    
    # 停止Resume服务
    if [ -f /tmp/jobfirst_resume_service.pid ]; then
        RESUME_SERVICE_PID=$(cat /tmp/jobfirst_resume_service.pid)
        kill $RESUME_SERVICE_PID 2>/dev/null
        rm -f /tmp/jobfirst_resume_service.pid
        log_success "Resume服务已停止"
    fi
    
    # 停止User服务
    if [ -f /tmp/jobfirst_user_service.pid ]; then
        USER_SERVICE_PID=$(cat /tmp/jobfirst_user_service.pid)
        kill $USER_SERVICE_PID 2>/dev/null
        rm -f /tmp/jobfirst_user_service.pid
        log_success "User服务已停止"
    fi
    
    # 停止API Gateway
    if [ -f /tmp/jobfirst_api_gateway.pid ]; then
        API_GATEWAY_PID=$(cat /tmp/jobfirst_api_gateway.pid)
        kill $API_GATEWAY_PID 2>/dev/null
        rm -f /tmp/jobfirst_api_gateway.pid
        log_success "API Gateway已停止"
    fi
    
    # 停止所有air进程
    pkill -f "air" 2>/dev/null
    log_success "所有air热加载进程已停止"
}

# 显示帮助信息
show_help() {
    echo -e "${BLUE}JobFirst Web端联调数据库开发环境管理脚本${NC}"
    echo ""
    echo -e "${CYAN}用法:${NC}"
    echo "  $0 {start|stop|restart|status|health|frontend|backend|help}"
    echo ""
    echo -e "${CYAN}命令说明:${NC}"
    echo "  start     - 启动完整的Web端开发环境 (数据库 + 后端 + 前端)"
    echo "  stop      - 停止所有开发服务"
    echo "  restart   - 重启所有开发服务"
    echo "  status    - 显示服务状态"
    echo "  health    - 执行健康检查"
    echo "  frontend  - 仅启动前端开发服务器"
    echo "  backend   - 仅启动后端服务 (数据库 + 微服务)"
    echo "  help      - 显示此帮助信息"
    echo ""
    echo -e "${CYAN}Web端开发特性:${NC}"
    echo "  - 前端: Taro HMR (代码修改自动刷新)"
    echo "  - API Gateway: air热加载 (Go代码修改自动重启)"
    echo "  - User Service: air热加载 (Go代码修改自动重启)"
    echo "  - Resume Service: air热加载 (Go代码修改自动重启)"
    echo "  - AI Service: Sanic热加载 (Python代码修改自动重启)"
    echo ""
    echo -e "${PURPLE}开发建议:${NC}"
    echo "  1. 首次启动使用: $0 start"
    echo "  2. 开发过程中修改代码会自动热加载"
    echo "  3. 使用 $0 status 查看服务状态"
    echo "  4. 使用 $0 health 检查服务健康状态"
    echo "  5. 开发完成后使用: $0 stop"
    echo ""
    echo -e "${PURPLE}Web端开发流程:${NC}"
    echo "  1. 启动开发环境: $0 start"
    echo "  2. 访问前端: http://localhost:10086"
    echo "  3. 修改前端代码自动刷新"
    echo "  4. 修改后端代码自动重启"
    echo "  5. 实时查看数据库变化"
}

# 主逻辑
case "$1" in
    start)
        echo -e "${GREEN}[INFO] 启动JobFirst Web端联调数据库开发环境...${NC}"
        start_databases
        init_databases
        start_api_gateway
        start_user_service
        start_resume_service
        start_banner_service
        start_template_service
        start_notification_service
        start_statistics_service
        start_ai_service
        start_frontend
        sleep 3
        health_check
        show_status
        echo -e "${GREEN}[SUCCESS] Web端开发环境启动完成！${NC}"
        echo -e "${CYAN}[INFO] 前端访问地址: http://localhost:$FRONTEND_PORT${NC}"
        ;;
    stop)
        stop_all_services
        echo -e "${GREEN}[SUCCESS] 所有开发服务已停止！${NC}"
        ;;
    restart)
        stop_all_services
        sleep 2
        echo -e "${GREEN}[INFO] 重启JobFirst Web端开发环境...${NC}"
        start_databases
        init_databases
        start_api_gateway
        start_user_service
        start_resume_service
        start_ai_service
        start_frontend
        sleep 3
        health_check
        show_status
        echo -e "${GREEN}[SUCCESS] Web端开发环境重启完成！${NC}"
        ;;
    status)
        show_status
        ;;
    health)
        health_check
        ;;
    frontend)
        echo -e "${GREEN}[INFO] 启动前端开发服务器...${NC}"
        start_frontend
        ;;
    backend)
        echo -e "${GREEN}[INFO] 启动后端服务 (热加载模式)...${NC}"
        start_databases
        init_databases
        start_api_gateway
        start_user_service
        start_resume_service
        start_ai_service
        sleep 3
        health_check
        show_status
        echo -e "${GREEN}[SUCCESS] 后端服务启动完成！${NC}"
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo -e "${RED}[ERROR] 未知命令: $1${NC}"
        echo ""
        show_help
        exit 1
        ;;
esac
