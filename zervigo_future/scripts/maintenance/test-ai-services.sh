#!/bin/bash

# 测试AI服务启动脚本

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

# 检查端口是否可用
check_port_available() {
    local port=$1
    local service_name=$2
    
    if lsof -i ":$port" >/dev/null 2>&1; then
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
    local timeout=${3:-30}
    
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
    
    echo
    log_warning "$service_name 健康检查超时"
    return 1
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
            log_warning "本地化AI服务启动失败"
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

# 主函数
main() {
    echo "=========================================="
    echo "🤖 AI服务测试启动脚本"
    echo "=========================================="
    echo
    
    # 创建日志目录
    mkdir -p "$LOG_DIR"
    
    # 启动AI服务
    start_local_ai_service
    start_containerized_ai_services
    
    echo
    echo "=========================================="
    echo "✅ AI服务测试完成"
    echo "=========================================="
    echo
    
    # 显示服务状态
    log_info "服务状态检查:"
    echo "本地化AI服务: $(curl -s http://localhost:8206/health 2>/dev/null | grep -o '"status":"[^"]*"' || echo '未运行')"
    echo "容器化AI服务: $(curl -s http://localhost:8208/health 2>/dev/null | grep -o '"status":"[^"]*"' || echo '未运行')"
    echo "MinerU服务: $(curl -s http://localhost:8001/health 2>/dev/null | grep -o '"status":"[^"]*"' || echo '未运行')"
    echo "AI模型服务: $(curl -s http://localhost:8002/health 2>/dev/null | grep -o '"status":"[^"]*"' || echo '未运行')"
    echo "AI监控服务: $(curl -s http://localhost:9090/-/healthy 2>/dev/null | grep -o 'Healthy' || echo '未运行')"
}

# 执行主函数
main "$@"
