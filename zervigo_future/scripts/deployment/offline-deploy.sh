#!/bin/bash

# JobFirst 离线部署脚本
# 解决网络连接问题，使用预构建镜像和本地资源

set -e

# 配置
DEPLOY_PATH="/opt/jobfirst"
BACKUP_PATH="$DEPLOY_PATH/backup"
LOG_FILE="$DEPLOY_PATH/logs/deploy.log"

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a $LOG_FILE
}

log_success() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ $1" | tee -a $LOG_FILE
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ❌ $1" | tee -a $LOG_FILE
}

log_warning() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ⚠️  $1" | tee -a $LOG_FILE
}

# 检查Docker环境
check_docker() {
    log "检查Docker环境..."
    if ! command -v docker &> /dev/null; then
        log_error "Docker未安装"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        log_error "Docker服务未运行"
        exit 1
    fi
    
    log_success "Docker环境检查通过"
}

# 创建必要目录
create_directories() {
    log "创建必要目录..."
    mkdir -p $DEPLOY_PATH/{logs,backup,data,configs}
    mkdir -p $BACKUP_PATH
    log_success "目录创建完成"
}

# 智能备份现有部署
backup_current() {
    log "备份现有部署..."
    
    if [ -d "$DEPLOY_PATH" ] && [ -f "$DEPLOY_PATH/docker-compose.yml" ]; then
        BACKUP_NAME="backup_$(date +%Y%m%d_%H%M%S)"
        BACKUP_TARGET="$BACKUP_PATH/$BACKUP_NAME"
        
        # 避免循环复制
        if [ "$DEPLOY_PATH" != "$BACKUP_TARGET" ] && [ ! "$DEPLOY_PATH" -ef "$BACKUP_TARGET" ]; then
            # 只备份关键配置文件，不备份数据卷
            mkdir -p "$BACKUP_TARGET"
            cp -r $DEPLOY_PATH/docker-compose.yml "$BACKUP_TARGET/" 2>/dev/null || true
            cp -r $DEPLOY_PATH/nginx "$BACKUP_TARGET/" 2>/dev/null || true
            cp -r $DEPLOY_PATH/scripts "$BACKUP_TARGET/" 2>/dev/null || true
            cp -r $DEPLOY_PATH/database "$BACKUP_TARGET/" 2>/dev/null || true
            log_success "备份完成: $BACKUP_NAME"
        else
            log_warning "跳过备份，避免循环复制"
        fi
    else
        log "无需备份，首次部署"
    fi
}

# 停止现有服务（保留前端服务）
stop_services() {
    log "停止现有后端服务（保留前端服务）..."
    cd $DEPLOY_PATH
    if [ -f "docker-compose.yml" ]; then
        # 只停止后端相关服务，保留前端服务
        docker-compose stop basic-server ai-service consul mysql redis postgres neo4j nginx || true
    fi
    log_success "后端服务已停止"
}

# 清理Docker资源
cleanup_docker() {
    log "清理Docker资源..."
    
    # 清理未使用的镜像
    docker image prune -f || true
    
    # 清理未使用的容器
    docker container prune -f || true
    
    # 清理未使用的网络
    docker network prune -f || true
    
    log_success "Docker资源清理完成"
}

# 加载预构建镜像
load_images() {
    log "加载预构建的Docker镜像..."
    
    # 加载后端服务镜像
    if [ -f "$DEPLOY_PATH/jobfirst-backend.tar.gz" ]; then
        log "加载后端服务镜像..."
        docker load < "$DEPLOY_PATH/jobfirst-backend.tar.gz"
        log_success "后端服务镜像加载完成"
    else
        log_warning "后端服务镜像文件不存在"
    fi
    
    # 加载AI服务镜像
    if [ -f "$DEPLOY_PATH/jobfirst-ai-service.tar.gz" ]; then
        log "加载AI服务镜像..."
        docker load < "$DEPLOY_PATH/jobfirst-ai-service.tar.gz"
        log_success "AI服务镜像加载完成"
    else
        log_warning "AI服务镜像文件不存在"
    fi
}

# 验证基础镜像（离线方案）
verify_base_images() {
    log "验证基础镜像..."
    
    # 检查必需的基础镜像是否存在
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
    
    for image in "${required_images[@]}"; do
        if docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^${image}$"; then
            log_success "镜像 ${image} 已存在"
        else
            log_error "镜像 ${image} 不存在，请先拉取该镜像"
            return 1
        fi
    done
    
    log_success "所有必需镜像验证通过"
}

# 分阶段启动服务
start_services_staged() {
    log "开始分阶段启动服务..."
    cd $DEPLOY_PATH
    
    # 阶段1: 启动基础设施
    log "=== 阶段1: 启动基础设施服务 ==="
    docker-compose up -d mysql redis postgres neo4j
    log "等待基础设施服务启动..."
    sleep 30
    
    # 检查基础设施健康状态
    check_infrastructure_health
    
    # 阶段2: 启动服务发现
    log "=== 阶段2: 启动服务发现 ==="
    docker-compose up -d consul
    log "等待Consul服务启动..."
    sleep 15
    
    # 阶段3: 启动核心服务
    log "=== 阶段3: 启动核心服务 ==="
    docker-compose up -d basic-server
    log "等待核心服务启动..."
    sleep 20
    
    # 阶段4: 启动AI服务
    log "=== 阶段4: 启动AI服务 ==="
    docker-compose up -d ai-service
    log "等待AI服务启动..."
    sleep 15
    
    # 阶段5: 启动前端和网关
    log "=== 阶段5: 启动前端和网关 ==="
    docker-compose up -d nginx frontend
    log "等待前端和网关启动..."
    sleep 10
    
    log_success "所有服务分阶段启动完成"
}

# 检查基础设施健康状态
check_infrastructure_health() {
    log "检查基础设施健康状态..."
    
    # 检查MySQL
    if docker-compose exec -T mysql mysqladmin ping -h localhost > /dev/null 2>&1; then
        log_success "MySQL数据库健康"
    else
        log_warning "MySQL数据库未就绪"
    fi
    
    # 检查Redis
    if docker-compose exec -T redis redis-cli ping > /dev/null 2>&1; then
        log_success "Redis缓存健康"
    else
        log_warning "Redis缓存未就绪"
    fi
    
    # 检查PostgreSQL
    if docker-compose exec -T postgres pg_isready -U postgres > /dev/null 2>&1; then
        log_success "PostgreSQL数据库健康"
    else
        log_warning "PostgreSQL数据库未就绪"
    fi
    
    # 检查Neo4j
    if docker-compose exec -T neo4j cypher-shell -u neo4j -p jobfirst_password_2024 "RETURN 1" > /dev/null 2>&1; then
        log_success "Neo4j图数据库健康"
    else
        log_warning "Neo4j图数据库未就绪"
    fi
}

# 验证部署
verify_deployment() {
    log "验证部署状态..."
    cd $DEPLOY_PATH
    
    echo "=== Docker容器状态 ==="
    docker-compose ps
    
    echo "=== 服务日志摘要 ==="
    docker-compose logs --tail=5
    
    # 检查关键服务端口
    if netstat -tlnp | grep -q ":8080"; then
        log_success "后端服务端口8080已监听"
    else
        log_warning "后端服务端口8080未监听"
    fi
    
    if netstat -tlnp | grep -q ":8000"; then
        log_success "AI服务端口8000已监听"
    else
        log_warning "AI服务端口8000未监听"
    fi
    
    if netstat -tlnp | grep -q ":80"; then
        log_success "Nginx端口80已监听"
    else
        log_warning "Nginx端口80未监听"
    fi
}

# 主函数
main() {
    log "开始JobFirst离线部署流程..."
    
    check_docker
    create_directories
    backup_current
    stop_services
    cleanup_docker
    load_images
    verify_base_images
    start_services_staged
    verify_deployment
    
    log_success "🎉 离线部署完成！"
    log "服务地址: http://$(hostname -I | awk '{print $1}')"
    log "API地址: http://$(hostname -I | awk '{print $1}')/api/"
    log "AI服务地址: http://$(hostname -I | awk '{print $1}')/ai/"
    log "Neo4j浏览器: http://$(hostname -I | awk '{print $1}'):7474"
    log "Consul UI: http://$(hostname -I | awk '{print $1}'):8500"
}

# 执行主函数
main "$@"
