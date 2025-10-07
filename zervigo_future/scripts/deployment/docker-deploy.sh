#!/bin/bash

# JobFirst Docker部署脚本
# 使用Docker Compose进行一键部署

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 获取脚本所在目录的绝对路径
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

# 检查Docker环境
check_docker() {
    log_info "检查Docker环境..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose is not installed"
        exit 1
    fi
    
    # 检查Docker是否运行
    if ! docker info &> /dev/null; then
        log_error "Docker is not running"
        exit 1
    fi
    
    log_success "Docker环境检查通过"
}

# 构建前端
build_frontend() {
    log_info "构建前端应用..."
    
    cd "$PROJECT_ROOT/frontend-taro"
    
    # 检查是否存在node_modules
    if [ ! -d "node_modules" ]; then
        log_info "安装前端依赖..."
        npm install
    fi
    
    # 构建H5版本
    log_info "构建H5版本..."
    NODE_ENV=production npm run build:h5
    
    if [ ! -d "dist/build/h5" ]; then
        log_error "前端构建失败"
        exit 1
    fi
    
    log_success "前端构建完成"
}

# 创建环境变量文件
create_env_file() {
    log_info "创建环境变量文件..."
    
    cd "$PROJECT_ROOT"
    
    if [ ! -f ".env" ]; then
        cat > .env << EOF
# 数据库配置
MYSQL_ROOT_PASSWORD=rootpassword
MYSQL_DATABASE=jobfirst
MYSQL_USER=jobfirst
MYSQL_PASSWORD=jobfirst123

# Redis配置
REDIS_PASSWORD=

# 应用配置
JWT_SECRET=your-very-secure-jwt-secret-key-2024
AI_API_KEY=your-ai-api-key

# 域名配置
DOMAIN=localhost
EOF
        log_success "环境变量文件已创建"
    else
        log_info "环境变量文件已存在"
    fi
}

# 启动服务
start_services() {
    log_info "启动Docker服务..."
    
    cd "$PROJECT_ROOT"
    
    # 停止现有服务
    docker-compose down
    
    # 构建并启动服务
    docker-compose up -d --build
    
    log_success "服务启动完成"
}

# 等待服务就绪
wait_for_services() {
    log_info "等待服务就绪..."
    
    # 等待数据库
    log_info "等待MySQL启动..."
    timeout 60 bash -c 'until docker-compose exec mysql mysqladmin ping -h localhost --silent; do sleep 2; done'
    
    # 等待Redis
    log_info "等待Redis启动..."
    timeout 30 bash -c 'until docker-compose exec redis redis-cli ping; do sleep 2; done'
    
    # 等待Consul
    log_info "等待Consul启动..."
    timeout 30 bash -c 'until curl -f http://localhost:8500/v1/status/leader; do sleep 2; done'
    
    # 等待AI服务
    log_info "等待AI服务启动..."
    timeout 60 bash -c 'until curl -f http://localhost:8206/health; do sleep 2; done'
    
    # 等待后端服务
    log_info "等待后端服务启动..."
    timeout 60 bash -c 'until curl -f http://localhost:8080/api/v1/consul/status; do sleep 2; done'
    
    log_success "所有服务已就绪"
}

# 检查服务状态
check_services() {
    log_info "检查服务状态..."
    
    cd "$PROJECT_ROOT"
    
    # 显示容器状态
    docker-compose ps
    
    # 检查各个服务
    services=("mysql:3306" "redis:6379" "consul:8500" "ai-service:8206" "backend:8080" "nginx:80")
    
    for service in "${services[@]}"; do
        name=$(echo $service | cut -d: -f1)
        port=$(echo $service | cut -d: -f2)
        
        if curl -f "http://localhost:$port" &> /dev/null || \
           docker-compose exec $name mysqladmin ping -h localhost &> /dev/null || \
           docker-compose exec $name redis-cli ping &> /dev/null; then
            log_success "$name 服务正常"
        else
            log_warning "$name 服务可能未就绪"
        fi
    done
}

# 显示访问信息
show_access_info() {
    log_success "部署完成！"
    echo ""
    echo "访问地址："
    echo "  - 前端应用: http://localhost"
    echo "  - API接口: http://localhost/api/v1"
    echo "  - Consul UI: http://localhost:8500"
    echo "  - AI服务: http://localhost:8206"
    echo ""
    echo "管理命令："
    echo "  - 查看日志: docker-compose logs -f"
    echo "  - 停止服务: docker-compose down"
    echo "  - 重启服务: docker-compose restart"
    echo "  - 查看状态: docker-compose ps"
    echo ""
    echo "数据库连接："
    echo "  - 主机: localhost:3306"
    echo "  - 数据库: jobfirst"
    echo "  - 用户: jobfirst"
    echo "  - 密码: jobfirst123"
}

# 清理函数
cleanup() {
    log_info "清理Docker资源..."
    
    cd "$PROJECT_ROOT"
    
    # 停止并删除容器
    docker-compose down
    
    # 删除未使用的镜像
    docker image prune -f
    
    log_success "清理完成"
}

# 主函数
main() {
    case "${1:-deploy}" in
        "deploy")
            log_info "开始Docker部署..."
            check_docker
            build_frontend
            create_env_file
            start_services
            wait_for_services
            check_services
            show_access_info
            ;;
        "stop")
            log_info "停止服务..."
            cd "$PROJECT_ROOT"
            docker-compose down
            log_success "服务已停止"
            ;;
        "restart")
            log_info "重启服务..."
            cd "$PROJECT_ROOT"
            docker-compose restart
            log_success "服务已重启"
            ;;
        "logs")
            log_info "查看服务日志..."
            cd "$PROJECT_ROOT"
            docker-compose logs -f
            ;;
        "status")
            log_info "查看服务状态..."
            cd "$PROJECT_ROOT"
            docker-compose ps
            check_services
            ;;
        "cleanup")
            cleanup
            ;;
        *)
            echo "用法: $0 {deploy|stop|restart|logs|status|cleanup}"
            echo ""
            echo "命令说明："
            echo "  deploy  - 部署服务 (默认)"
            echo "  stop    - 停止服务"
            echo "  restart - 重启服务"
            echo "  logs    - 查看日志"
            echo "  status  - 查看状态"
            echo "  cleanup - 清理资源"
            exit 1
            ;;
    esac
}

# 运行主函数
main "$@"
