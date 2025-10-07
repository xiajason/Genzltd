#!/bin/bash

# JobFirst 系统集成测试脚本
# 基于智能微服务生态系统构建完成后的集成测试

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
TEST_LOG="$LOG_DIR/integration-test.log"

# 服务配置
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
    "unified-auth-service:8207"
    "containerized-ai-service:8208"
    "mineru-service:8001"
    "ai-models-service:8002"
    "ai-monitor-service:9090"
)

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$TEST_LOG"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$TEST_LOG"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$TEST_LOG"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$TEST_LOG"
}

log_step() {
    echo -e "${PURPLE}[STEP]${NC} $1" | tee -a "$TEST_LOG"
}

# 创建必要的目录
create_directories() {
    mkdir -p "$LOG_DIR"
    log_info "创建测试日志目录: $LOG_DIR"
}

# 检查服务健康状态
check_service_health() {
    local service_name=$1
    local port=$2
    local health_url="http://localhost:$port/health"
    
    log_info "检查 $service_name 健康状态 (端口: $port)..."
    
    if curl -s "$health_url" >/dev/null 2>&1; then
        local response=$(curl -s "$health_url")
        local status=$(echo "$response" | grep -o '"status":"[^"]*"' | cut -d'"' -f4 || echo "unknown")
        log_success "$service_name 健康检查通过 - 状态: $status"
        return 0
    else
        log_error "$service_name 健康检查失败 - 端口 $port 无响应"
        return 1
    fi
}

# 检查所有服务状态
check_all_services() {
    log_step "检查所有服务健康状态..."
    
    local healthy_count=0
    local total_count=${#ALL_SERVICES[@]}
    local failed_services=()
    
    for service_entry in "${ALL_SERVICES[@]}"; do
        local service_name=$(echo "$service_entry" | cut -d':' -f1)
        local service_port=$(echo "$service_entry" | cut -d':' -f2)
        
        if check_service_health "$service_name" "$service_port"; then
            ((healthy_count++))
        else
            failed_services+=("$service_name:$service_port")
        fi
    done
    
    echo
    log_info "服务健康状态总结:"
    log_info "  总服务数: $total_count"
    log_success "  健康服务: $healthy_count"
    log_error "  失败服务: $((total_count - healthy_count))"
    
    if [[ ${#failed_services[@]} -gt 0 ]]; then
        log_warning "失败的服务:"
        for service in "${failed_services[@]}"; do
            log_warning "  - $service"
        done
        return 1
    else
        log_success "所有服务健康检查通过！"
        return 0
    fi
}

# 测试服务间通信
test_service_communication() {
    log_step "测试服务间通信..."
    
    # 测试Company服务
    log_info "测试Company服务API..."
    if curl -s http://localhost:8083/api/v1/companies >/dev/null 2>&1; then
        log_success "Company服务API响应正常"
    else
        log_warning "Company服务API无响应"
    fi
    
    # 测试Job服务
    log_info "测试Job服务API..."
    if curl -s http://localhost:8089/api/v1/jobs >/dev/null 2>&1; then
        log_success "Job服务API响应正常"
    else
        log_warning "Job服务API无响应"
    fi
    
    # 测试User服务
    log_info "测试User服务API..."
    if curl -s http://localhost:8081/api/v1/users >/dev/null 2>&1; then
        log_success "User服务API响应正常"
    else
        log_warning "User服务API无响应"
    fi
    
    # 测试Resume服务
    log_info "测试Resume服务API..."
    if curl -s http://localhost:8082/api/v1/resumes >/dev/null 2>&1; then
        log_success "Resume服务API响应正常"
    else
        log_warning "Resume服务API无响应"
    fi
    
    # 测试AI服务
    log_info "测试AI服务API..."
    if curl -s http://localhost:8206/health >/dev/null 2>&1; then
        log_success "本地化AI服务响应正常"
    else
        log_warning "本地化AI服务无响应"
    fi
    
    if curl -s http://localhost:8208/health >/dev/null 2>&1; then
        log_success "容器化AI服务响应正常"
    else
        log_warning "容器化AI服务无响应"
    fi
    
    # 测试统一认证服务
    log_info "测试统一认证服务API..."
    if curl -s http://localhost:8207/health >/dev/null 2>&1; then
        log_success "统一认证服务响应正常"
    else
        log_warning "统一认证服务无响应"
    fi
}

# 测试服务发现
test_service_discovery() {
    log_step "测试服务发现..."
    
    # 检查Consul服务
    if curl -s http://localhost:8500/v1/agent/services >/dev/null 2>&1; then
        log_info "Consul服务发现正常"
        local services=$(curl -s http://localhost:8500/v1/agent/services | jq -r 'keys[]' 2>/dev/null || echo "无法解析服务列表")
        log_info "注册的服务: $services"
    else
        log_warning "Consul服务发现无响应"
    fi
}

# 测试数据库连接
test_database_connections() {
    log_step "测试数据库连接..."
    
    # 检查MySQL
    if brew services list | grep mysql | grep started &> /dev/null; then
        log_success "MySQL服务运行正常"
    else
        log_warning "MySQL服务未运行"
    fi
    
    # 检查Redis
    if brew services list | grep redis | grep started &> /dev/null; then
        log_success "Redis服务运行正常"
    else
        log_warning "Redis服务未运行"
    fi
    
    # 检查PostgreSQL
    if brew services list | grep postgresql@14 | grep started &> /dev/null; then
        log_success "PostgreSQL服务运行正常"
    else
        log_warning "PostgreSQL服务未运行"
    fi
    
    # 检查Neo4j
    if brew services list | grep neo4j | grep started &> /dev/null; then
        log_success "Neo4j服务运行正常"
    else
        log_warning "Neo4j服务未运行"
    fi
}

# 性能基准测试
performance_benchmark() {
    log_step "性能基准测试..."
    
    # 测试API响应时间
    log_info "测试API响应时间..."
    
    local endpoints=(
        "http://localhost:8080/health:Basic-Server"
        "http://localhost:8081/health:User-Service"
        "http://localhost:8082/health:Resume-Service"
        "http://localhost:8083/health:Company-Service"
        "http://localhost:8206/health:Local-AI-Service"
    )
    
    for endpoint in "${endpoints[@]}"; do
        local url=$(echo "$endpoint" | cut -d':' -f1-2)
        local name=$(echo "$endpoint" | cut -d':' -f3)
        
        local start_time=$(date +%s%N)
        if curl -s "$url" >/dev/null 2>&1; then
            local end_time=$(date +%s%N)
            local response_time=$(( (end_time - start_time) / 1000000 ))
            log_info "$name 响应时间: ${response_time}ms"
        else
            log_warning "$name 无响应"
        fi
    done
}

# 生成测试报告
generate_test_report() {
    log_step "生成测试报告..."
    
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local report_file="$LOG_DIR/integration_test_report_$timestamp.txt"
    
    {
        echo "=========================================="
        echo "JobFirst 系统集成测试报告"
        echo "=========================================="
        echo "测试时间: $(date)"
        echo "测试环境: 本地开发环境"
        echo ""
        echo "服务配置:"
        echo "  总服务数: ${#ALL_SERVICES[@]}"
        echo "  服务列表:"
        for service_entry in "${ALL_SERVICES[@]}"; do
            echo "    - $service_entry"
        done
        echo ""
        echo "测试结果:"
        echo "  健康检查: $(check_all_services && echo "通过" || echo "失败")"
        echo "  服务通信: 已测试"
        echo "  服务发现: 已测试"
        echo "  数据库连接: 已测试"
        echo "  性能基准: 已测试"
        echo ""
        echo "详细日志: $TEST_LOG"
        echo "=========================================="
    } > "$report_file"
    
    log_success "测试报告已生成: $report_file"
}

# 主函数
main() {
    echo "=========================================="
    echo "🧪 JobFirst 系统集成测试"
    echo "=========================================="
    echo
    
    create_directories
    log_info "开始系统集成测试..."
    
    # 执行测试
    check_all_services
    test_service_communication
    test_service_discovery
    test_database_connections
    performance_benchmark
    generate_test_report
    
    echo
    echo "=========================================="
    echo "✅ 系统集成测试完成"
    echo "=========================================="
    echo
    log_success "集成测试完成，详细结果请查看测试报告"
    log_info "测试日志: $TEST_LOG"
    echo
}

# 错误处理
trap 'log_error "测试过程中发生错误"; exit 1' ERR

# 执行主函数
main "$@"
