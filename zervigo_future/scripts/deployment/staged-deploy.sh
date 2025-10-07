#!/bin/bash

# JobFirst 分阶段部署脚本
set -e

# 配置变量
PROJECT_NAME="jobfirst"
DEPLOY_PATH="/opt/jobfirst"
BACKUP_PATH="/opt/jobfirst/backup"
LOG_FILE="/var/log/jobfirst-staged-deploy.log"
DOCKER_COMPOSE_FILE="docker-compose.yml"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a $LOG_FILE
}

log_success() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] ✅ $1${NC}" | tee -a $LOG_FILE
}

log_warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] ⚠️  $1${NC}" | tee -a $LOG_FILE
}

log_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ❌ $1${NC}" | tee -a $LOG_FILE
}

# 等待服务健康检查
wait_for_service() {
    local service_name=$1
    local health_url=$2
    local max_attempts=30
    local attempt=1
    
    log "等待 $service_name 服务启动..."
    
    while [ $attempt -le $max_attempts ]; do
        if curl -f $health_url > /dev/null 2>&1; then
            log_success "$service_name 服务启动成功"
            return 0
        fi
        
        log "等待 $service_name 服务启动... ($attempt/$max_attempts)"
        sleep 10
        ((attempt++))
    done
    
    log_error "$service_name 服务启动超时"
    return 1
}

# 检查Docker环境
check_docker() {
    log "检查Docker环境..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker未安装"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose未安装"
        exit 1
    fi
    
    # 检查Docker服务状态
    if ! systemctl is-active --quiet docker; then
        log "启动Docker服务..."
        systemctl start docker
    fi
    
    log_success "Docker环境检查通过"
}

# 创建必要目录
create_directories() {
    log "创建必要目录..."
    
    mkdir -p $DEPLOY_PATH/{logs,uploads,temp,backup}
    mkdir -p $DEPLOY_PATH/nginx/{conf.d,ssl}
    mkdir -p $DEPLOY_PATH/database/{mysql/conf.d,postgresql,redis}
    mkdir -p $DEPLOY_PATH/consul/{config,data}
    
    log_success "目录创建完成"
}

# 备份现有部署
backup_current() {
    if [ -d "$DEPLOY_PATH" ] && [ -f "$DEPLOY_PATH/$DOCKER_COMPOSE_FILE" ]; then
        log "备份现有部署..."
        BACKUP_NAME="backup_$(date +%Y%m%d_%H%M%S)"
        # 避免将目录复制到自身
        if [ "$DEPLOY_PATH" != "$BACKUP_PATH/$BACKUP_NAME" ]; then
            if cp -r $DEPLOY_PATH $BACKUP_PATH/$BACKUP_NAME; then
                log_success "备份完成: $BACKUP_NAME"
            else
                log_warning "备份失败，继续部署流程"
            fi
        else
            log_warning "跳过备份，避免循环复制"
        fi
    else
        log "无需备份，首次部署"
    fi
}

# 停止现有服务
stop_services() {
    log "停止现有服务..."
    cd $DEPLOY_PATH
    
    if [ -f "$DOCKER_COMPOSE_FILE" ]; then
        docker-compose down --remove-orphans || true
        log_success "服务已停止"
    else
        log_warning "未找到docker-compose.yml文件"
    fi
}

# 清理Docker资源
cleanup_docker() {
    log "清理Docker资源..."
    
    # 清理未使用的镜像
    docker image prune -f
    
    # 清理未使用的容器
    docker container prune -f
    
    # 清理未使用的网络
    docker network prune -f
    
    # 清理未使用的卷
    docker volume prune -f
    
    log_success "Docker资源清理完成"
}

# 加载预构建的Docker镜像
load_images() {
    log "加载预构建的Docker镜像..."
    cd $DEPLOY_PATH
    
    if [ -f "jobfirst-backend.tar.gz" ]; then
        log "加载后端服务镜像..."
        docker load < jobfirst-backend.tar.gz
    fi
    
    if [ -f "jobfirst-user-service.tar.gz" ]; then
        log "加载用户服务镜像..."
        docker load < jobfirst-user-service.tar.gz
    fi
    
    if [ -f "jobfirst-resume-service.tar.gz" ]; then
        log "加载简历服务镜像..."
        docker load < jobfirst-resume-service.tar.gz
    fi
    
    if [ -f "jobfirst-ai-service.tar.gz" ]; then
        log "加载AI服务镜像..."
        docker load < jobfirst-ai-service.tar.gz
    fi
    
    log_success "Docker镜像加载完成"
}

# 阶段1: 启动基础设施服务
deploy_infrastructure() {
    log "=== 阶段1: 启动基础设施服务 ==="
    cd $DEPLOY_PATH
    
    # 启动数据库和缓存服务
    docker-compose up -d mysql redis postgres neo4j
    
    # 等待数据库服务启动
    log "等待数据库服务启动..."
    sleep 30
    
    # 检查数据库健康状态
    if docker-compose exec -T mysql mysqladmin ping -h localhost > /dev/null 2>&1; then
        log_success "MySQL数据库启动成功"
    else
        log_error "MySQL数据库启动失败"
        return 1
    fi
    
    if docker-compose exec -T redis redis-cli ping > /dev/null 2>&1; then
        log_success "Redis缓存启动成功"
    else
        log_error "Redis缓存启动失败"
        return 1
    fi
    
    if docker-compose exec -T postgres pg_isready -U postgres > /dev/null 2>&1; then
        log_success "PostgreSQL数据库启动成功"
    else
        log_error "PostgreSQL数据库启动失败"
        return 1
    fi
    
    # 检查Neo4j图数据库健康状态
    if docker-compose exec -T neo4j cypher-shell -u neo4j -p jobfirst_password_2024 "RETURN 1" > /dev/null 2>&1; then
        log_success "Neo4j图数据库启动成功"
    else
        log_error "Neo4j图数据库启动失败"
        return 1
    fi
}

# 阶段2: 启动服务发现
deploy_service_discovery() {
    log "=== 阶段2: 启动服务发现 ==="
    cd $DEPLOY_PATH
    
    # 启动Consul服务
    docker-compose up -d consul
    
    # 等待Consul服务启动
    log "等待Consul服务启动..."
    sleep 20
    
    # 检查Consul健康状态
    if curl -f http://localhost:8500/v1/status/leader > /dev/null 2>&1; then
        log_success "Consul服务发现启动成功"
    else
        log_error "Consul服务发现启动失败"
        return 1
    fi
}

# 阶段3: 启动核心服务
deploy_core_services() {
    log "=== 阶段3: 启动核心服务 ==="
    cd $DEPLOY_PATH
    
    # 启动API Gateway
    docker-compose up -d basic-server
    
    # 等待API Gateway启动
    wait_for_service "API Gateway" "http://localhost:8080/health"
    
    # 验证API Gateway注册到Consul
    log "验证API Gateway注册到Consul..."
    sleep 10
    if curl -f http://localhost:8500/v1/agent/services | grep -q "basic-server"; then
        log_success "API Gateway已注册到Consul"
    else
        log_warning "API Gateway未注册到Consul，继续部署"
    fi
}

# 阶段4: 启动业务服务
deploy_business_services() {
    log "=== 阶段4: 启动业务服务 ==="
    cd $DEPLOY_PATH
    
    # 启动用户服务
    docker-compose up -d user-service
    wait_for_service "用户服务" "http://localhost:8081/health"
    
    # 启动简历服务
    docker-compose up -d resume-service
    wait_for_service "简历服务" "http://localhost:8082/health"
    
    # 验证业务服务注册到Consul
    log "验证业务服务注册到Consul..."
    sleep 10
    if curl -f http://localhost:8500/v1/agent/services | grep -q "user-service"; then
        log_success "用户服务已注册到Consul"
    else
        log_warning "用户服务未注册到Consul"
    fi
    
    if curl -f http://localhost:8500/v1/agent/services | grep -q "resume-service"; then
        log_success "简历服务已注册到Consul"
    else
        log_warning "简历服务未注册到Consul"
    fi
}

# 阶段5: 启动AI服务
deploy_ai_services() {
    log "=== 阶段5: 启动AI服务 ==="
    cd $DEPLOY_PATH
    
    # 启动AI服务
    docker-compose up -d ai-service
    wait_for_service "AI服务" "http://localhost:8000/health"
    
    # 验证AI服务注册到Consul
    log "验证AI服务注册到Consul..."
    sleep 10
    if curl -f http://localhost:8500/v1/agent/services | grep -q "ai-service"; then
        log_success "AI服务已注册到Consul"
    else
        log_warning "AI服务未注册到Consul"
    fi
}

# 阶段6: 启动前端服务
deploy_frontend_services() {
    log "=== 阶段6: 启动前端服务 ==="
    cd $DEPLOY_PATH
    
    # 启动Nginx和前端服务
    docker-compose up -d nginx frontend
    
    # 等待前端服务启动
    log "等待前端服务启动..."
    sleep 20
    
    # 检查Nginx状态
    if curl -f http://localhost:80 > /dev/null 2>&1; then
        log_success "Nginx反向代理启动成功"
    else
        log_warning "Nginx反向代理启动失败"
    fi
    
    if curl -f http://localhost:3000 > /dev/null 2>&1; then
        log_success "前端服务启动成功"
    else
        log_warning "前端服务启动失败"
    fi
}

# 显示服务状态
show_status() {
    log "显示服务状态..."
    cd $DEPLOY_PATH
    
    echo -e "\n${BLUE}=== 容器状态 ===${NC}"
    docker-compose ps
    
    echo -e "\n${BLUE}=== Consul服务注册状态 ===${NC}"
    curl -s http://localhost:8500/v1/agent/services | jq '.' || echo "无法获取Consul服务状态"
    
    echo -e "\n${BLUE}=== 系统资源 ===${NC}"
    echo "内存使用:"
    free -h
    echo ""
    echo "磁盘使用:"
    df -h
    echo ""
    echo "Docker资源使用:"
    docker system df
}

# 主部署流程
main() {
    log "开始JobFirst分阶段部署流程..."
    
    check_docker
    create_directories
    backup_current
    stop_services
    cleanup_docker
    load_images
    
    # 分阶段部署
    deploy_infrastructure || { log_error "基础设施部署失败"; exit 1; }
    deploy_service_discovery || { log_error "服务发现部署失败"; exit 1; }
    deploy_core_services || { log_error "核心服务部署失败"; exit 1; }
    deploy_business_services || { log_error "业务服务部署失败"; exit 1; }
    deploy_ai_services || { log_error "AI服务部署失败"; exit 1; }
    deploy_frontend_services || { log_error "前端服务部署失败"; exit 1; }
    
    log_success "🎉 分阶段部署成功完成！"
    show_status
    exit 0
}

# 显示帮助信息
show_help() {
    echo "JobFirst 分阶段部署脚本"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help     显示帮助信息"
    echo "  -s, --status   显示服务状态"
    echo "  -l, --logs     显示服务日志"
    echo "  -r, --restart  重启服务"
    echo "  -c, --cleanup  清理Docker资源"
    echo ""
    echo "示例:"
    echo "  $0              # 执行完整分阶段部署"
    echo "  $0 --status     # 显示服务状态"
    echo "  $0 --logs       # 显示服务日志"
    echo "  $0 --restart    # 重启服务"
}

# 处理命令行参数
case "${1:-}" in
    -h|--help)
        show_help
        exit 0
        ;;
    -s|--status)
        show_status
        exit 0
        ;;
    -l|--logs)
        cd $DEPLOY_PATH
        docker-compose logs -f
        exit 0
        ;;
    -r|--restart)
        log "重启服务..."
        cd $DEPLOY_PATH
        docker-compose restart
        log_success "服务重启完成"
        exit 0
        ;;
    -c|--cleanup)
        cleanup_docker
        exit 0
        ;;
    "")
        main
        ;;
    *)
        log_error "未知选项: $1"
        show_help
        exit 1
        ;;
esac
