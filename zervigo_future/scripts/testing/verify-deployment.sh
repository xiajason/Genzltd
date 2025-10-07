#!/bin/bash

# JobFirst 阿里云部署验证脚本
# 用于全面验证部署是否成功

set -e

# 配置
DEPLOY_PATH="/opt/jobfirst"
LOG_FILE="/opt/jobfirst/logs/deployment-verification.log"
VERIFICATION_RESULTS="/opt/jobfirst/logs/verification-results.json"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a $LOG_FILE
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a $LOG_FILE
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a $LOG_FILE
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a $LOG_FILE
}

# 验证结果记录
VERIFICATION_RESULTS_JSON="{}"

add_result() {
    local test_name="$1"
    local status="$2"
    local message="$3"
    local details="$4"
    
    VERIFICATION_RESULTS_JSON=$(echo "$VERIFICATION_RESULTS_JSON" | jq --arg name "$test_name" --arg status "$status" --arg message "$message" --arg details "$details" '. + {($name): {"status": $status, "message": $message, "details": $details}}')
}

# 检查Docker环境
verify_docker_environment() {
    log_info "=== 验证Docker环境 ==="
    
    if command -v docker &> /dev/null; then
        log_success "Docker已安装: $(docker --version)"
        add_result "docker_installation" "success" "Docker已安装" "$(docker --version)"
    else
        log_error "Docker未安装"
        add_result "docker_installation" "failed" "Docker未安装" ""
        return 1
    fi
    
    if docker info &> /dev/null; then
        log_success "Docker服务运行正常"
        add_result "docker_service" "success" "Docker服务运行正常" ""
    else
        log_error "Docker服务未运行"
        add_result "docker_service" "failed" "Docker服务未运行" ""
        return 1
    fi
}

# 检查Docker镜像
verify_docker_images() {
    log_info "=== 验证Docker镜像 ==="
    
    local required_images=(
        "mysql:8.0"
        "redis:latest"
        "postgres:14-alpine"
        "neo4j:latest"
        "nginx:alpine"
        "consul:latest"
        "jobfirst-backend:latest"
        "jobfirst-ai-service:latest"
    )
    
    local missing_images=()
    
    for image in "${required_images[@]}"; do
        if docker images --format "table {{.Repository}}:{{.Tag}}" | grep -q "^$image$"; then
            log_success "镜像存在: $image"
        else
            log_warning "镜像缺失: $image"
            missing_images+=("$image")
        fi
    done
    
    if [ ${#missing_images[@]} -eq 0 ]; then
        add_result "docker_images" "success" "所有必需镜像都存在" ""
    else
        add_result "docker_images" "warning" "部分镜像缺失" "${missing_images[*]}"
    fi
}

# 检查Docker容器状态
verify_container_status() {
    log_info "=== 验证Docker容器状态 ==="
    
    cd $DEPLOY_PATH
    
    if [ -f "docker-compose.yml" ]; then
        log_info "检查容器状态..."
        docker-compose ps
        
        local running_containers=$(docker-compose ps --services --filter "status=running" | wc -l)
        local total_containers=$(docker-compose ps --services | wc -l)
        
        log_info "运行中的容器: $running_containers/$total_containers"
        
        if [ "$running_containers" -eq "$total_containers" ]; then
            add_result "container_status" "success" "所有容器都在运行" "$running_containers/$total_containers"
        else
            add_result "container_status" "warning" "部分容器未运行" "$running_containers/$total_containers"
        fi
    else
        log_error "未找到docker-compose.yml文件"
        add_result "container_status" "failed" "未找到docker-compose.yml文件" ""
    fi
}

# 检查基础设施服务
verify_infrastructure_services() {
    log_info "=== 验证基础设施服务 ==="
    
    # 检查MySQL
    if docker-compose exec -T mysql mysqladmin ping -h localhost > /dev/null 2>&1; then
        log_success "MySQL数据库连接正常"
        add_result "mysql_connection" "success" "MySQL数据库连接正常" ""
    else
        log_error "MySQL数据库连接失败"
        add_result "mysql_connection" "failed" "MySQL数据库连接失败" ""
    fi
    
    # 检查Redis
    if docker-compose exec -T redis redis-cli ping > /dev/null 2>&1; then
        log_success "Redis连接正常"
        add_result "redis_connection" "success" "Redis连接正常" ""
    else
        log_error "Redis连接失败"
        add_result "redis_connection" "failed" "Redis连接失败" ""
    fi
    
    # 检查PostgreSQL
    if docker-compose exec -T postgres pg_isready -U postgres > /dev/null 2>&1; then
        log_success "PostgreSQL数据库连接正常"
        add_result "postgres_connection" "success" "PostgreSQL数据库连接正常" ""
    else
        log_error "PostgreSQL数据库连接失败"
        add_result "postgres_connection" "failed" "PostgreSQL数据库连接失败" ""
    fi
    
    # 检查Neo4j
    if curl -f http://localhost:7474 > /dev/null 2>&1; then
        log_success "Neo4j数据库连接正常"
        add_result "neo4j_connection" "success" "Neo4j数据库连接正常" ""
    else
        log_error "Neo4j数据库连接失败"
        add_result "neo4j_connection" "failed" "Neo4j数据库连接失败" ""
    fi
}

# 检查微服务
verify_microservices() {
    log_info "=== 验证微服务 ==="
    
    # 检查Consul
    if curl -f http://localhost:8500/v1/status/leader > /dev/null 2>&1; then
        log_success "Consul服务发现正常"
        add_result "consul_service" "success" "Consul服务发现正常" ""
    else
        log_error "Consul服务发现失败"
        add_result "consul_service" "failed" "Consul服务发现失败" ""
    fi
    
    # 检查后端服务
    if curl -f http://localhost:8080/health > /dev/null 2>&1; then
        log_success "后端服务健康检查通过"
        add_result "backend_service" "success" "后端服务健康检查通过" ""
    else
        log_error "后端服务健康检查失败"
        add_result "backend_service" "failed" "后端服务健康检查失败" ""
    fi
    
    # 检查AI服务
    if curl -f http://localhost:8000/health > /dev/null 2>&1; then
        log_success "AI服务健康检查通过"
        add_result "ai_service" "success" "AI服务健康检查通过" ""
    else
        log_warning "AI服务健康检查失败"
        add_result "ai_service" "warning" "AI服务健康检查失败" ""
    fi
}

# 检查前端服务
verify_frontend_service() {
    log_info "=== 验证前端服务 ==="
    
    # 检查前端文件
    if [ -d "$DEPLOY_PATH/frontend-taro/dist" ] && [ -f "$DEPLOY_PATH/frontend-taro/dist/index.html" ]; then
        log_success "前端文件部署正确"
        add_result "frontend_files" "success" "前端文件部署正确" ""
    else
        log_error "前端文件部署异常"
        add_result "frontend_files" "failed" "前端文件部署异常" ""
    fi
    
    # 检查前端服务
    if curl -f http://localhost:3000 > /dev/null 2>&1; then
        log_success "前端服务HTTP访问正常"
        add_result "frontend_service" "success" "前端服务HTTP访问正常" ""
    else
        log_error "前端服务HTTP访问异常"
        add_result "frontend_service" "failed" "前端服务HTTP访问异常" ""
    fi
}

# 检查网络连接
verify_network_connectivity() {
    log_info "=== 验证网络连接 ==="
    
    local services=(
        "localhost:8080:后端服务"
        "localhost:8000:AI服务"
        "localhost:3000:前端服务"
        "localhost:8500:Consul服务"
        "localhost:7474:Neo4j服务"
    )
    
    for service in "${services[@]}"; do
        IFS=':' read -r host port name <<< "$service"
        if curl -f --connect-timeout 5 http://$host:$port > /dev/null 2>&1; then
            log_success "$name 网络连接正常"
        else
            log_warning "$name 网络连接异常"
        fi
    done
}

# 检查日志
verify_logs() {
    log_info "=== 检查服务日志 ==="
    
    cd $DEPLOY_PATH
    
    log_info "后端服务日志 (最近10行):"
    docker-compose logs --tail=10 basic-server
    
    log_info "AI服务日志 (最近10行):"
    docker-compose logs --tail=10 ai-service
    
    log_info "前端服务日志 (最近10行):"
    docker-compose logs --tail=10 frontend
}

# 生成验证报告
generate_report() {
    log_info "=== 生成验证报告 ==="
    
    echo "$VERIFICATION_RESULTS_JSON" > $VERIFICATION_RESULTS
    
    local total_tests=$(echo "$VERIFICATION_RESULTS_JSON" | jq 'length')
    local success_tests=$(echo "$VERIFICATION_RESULTS_JSON" | jq '[.[] | select(.status == "success")] | length')
    local failed_tests=$(echo "$VERIFICATION_RESULTS_JSON" | jq '[.[] | select(.status == "failed")] | length')
    local warning_tests=$(echo "$VERIFICATION_RESULTS_JSON" | jq '[.[] | select(.status == "warning")] | length')
    
    log_info "验证报告:"
    log_info "总测试数: $total_tests"
    log_success "成功: $success_tests"
    log_error "失败: $failed_tests"
    log_warning "警告: $warning_tests"
    
    if [ "$failed_tests" -eq 0 ]; then
        log_success "🎉 部署验证通过！"
        return 0
    else
        log_error "❌ 部署验证失败，请检查失败的测试项"
        return 1
    fi
}

# 主函数
main() {
    log_info "开始JobFirst阿里云部署验证..."
    
    # 创建日志目录
    mkdir -p $(dirname $LOG_FILE)
    
    verify_docker_environment
    verify_docker_images
    verify_container_status
    verify_infrastructure_services
    verify_microservices
    verify_frontend_service
    verify_network_connectivity
    verify_logs
    generate_report
}

# 错误处理
trap 'log_error "验证过程中发生错误，退出码: $?"' ERR

# 执行主函数
main "$@"
