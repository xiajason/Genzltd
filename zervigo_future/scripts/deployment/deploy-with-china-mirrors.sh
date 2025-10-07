#!/bin/bash

# 使用国内镜像源快速部署脚本
# 针对腾讯云轻量应用服务器优化

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置变量
PROJECT_NAME="jobfirst"
DOCKER_REGISTRY="registry.cn-hangzhou.aliyuncs.com/library"
COMPOSE_FILE="docker-compose.yml"
PRODUCTION_COMPOSE_FILE="docker-compose.production.yml"

# 显示帮助信息
show_help() {
    echo -e "${BLUE}使用国内镜像源快速部署脚本${NC}"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -d, --dev         开发环境部署"
    echo "  -p, --prod        生产环境部署"
    echo "  -b, --build       构建镜像"
    echo "  -u, --up          启动服务"
    echo "  -s, --stop        停止服务"
    echo "  -r, --restart     重启服务"
    echo "  -l, --logs        查看日志"
    echo "  -c, --clean       清理未使用的镜像和容器"
    echo "  -f, --force       强制重新构建"
    echo "  -h, --help        显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 --dev --build --up    # 开发环境构建并启动"
    echo "  $0 --prod --up           # 生产环境启动"
    echo "  $0 --clean               # 清理资源"
}

# 检查Docker是否运行
check_docker() {
    if ! docker info >/dev/null 2>&1; then
        echo -e "${RED}错误: Docker未运行或无法访问${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ Docker运行正常${NC}"
}

# 检查docker-compose文件
check_compose_file() {
    local env=$1
    local compose_file=""
    
    if [[ "$env" == "prod" ]]; then
        compose_file="$PRODUCTION_COMPOSE_FILE"
    else
        compose_file="$COMPOSE_FILE"
    fi
    
    if [[ ! -f "$compose_file" ]]; then
        echo -e "${RED}错误: docker-compose文件不存在: $compose_file${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ 使用compose文件: $compose_file${NC}"
    echo "$compose_file"
}

# 预拉取镜像
pre_pull_images() {
    local compose_file=$1
    echo -e "${YELLOW}正在预拉取镜像...${NC}"
    
    # 从compose文件中提取镜像名称
    local images=$(grep -E "^\s*image:" "$compose_file" | sed 's/.*image:\s*//' | sort -u)
    
    for image in $images; do
        echo -e "${BLUE}拉取镜像: $image${NC}"
        if docker pull "$image"; then
            echo -e "${GREEN}✓ $image 拉取成功${NC}"
        else
            echo -e "${RED}✗ $image 拉取失败${NC}"
        fi
    done
}

# 构建镜像
build_images() {
    local compose_file=$1
    local force=$2
    
    echo -e "${YELLOW}正在构建镜像...${NC}"
    
    local build_args=""
    if [[ "$force" == "true" ]]; then
        build_args="--no-cache --pull"
    fi
    
    if docker-compose -f "$compose_file" build $build_args; then
        echo -e "${GREEN}✓ 镜像构建成功${NC}"
    else
        echo -e "${RED}✗ 镜像构建失败${NC}"
        exit 1
    fi
}

# 启动服务
start_services() {
    local compose_file=$1
    echo -e "${YELLOW}正在启动服务...${NC}"
    
    if docker-compose -f "$compose_file" up -d; then
        echo -e "${GREEN}✓ 服务启动成功${NC}"
    else
        echo -e "${RED}✗ 服务启动失败${NC}"
        exit 1
    fi
}

# 停止服务
stop_services() {
    local compose_file=$1
    echo -e "${YELLOW}正在停止服务...${NC}"
    
    if docker-compose -f "$compose_file" down; then
        echo -e "${GREEN}✓ 服务停止成功${NC}"
    else
        echo -e "${RED}✗ 服务停止失败${NC}"
        exit 1
    fi
}

# 重启服务
restart_services() {
    local compose_file=$1
    echo -e "${YELLOW}正在重启服务...${NC}"
    
    if docker-compose -f "$compose_file" restart; then
        echo -e "${GREEN}✓ 服务重启成功${NC}"
    else
        echo -e "${RED}✗ 服务重启失败${NC}"
        exit 1
    fi
}

# 查看日志
show_logs() {
    local compose_file=$1
    echo -e "${YELLOW}正在查看服务日志...${NC}"
    
    docker-compose -f "$compose_file" logs -f --tail=100
}

# 清理资源
clean_resources() {
    echo -e "${YELLOW}正在清理未使用的资源...${NC}"
    
    # 清理停止的容器
    echo -e "${BLUE}清理停止的容器...${NC}"
    docker container prune -f
    
    # 清理未使用的镜像
    echo -e "${BLUE}清理未使用的镜像...${NC}"
    docker image prune -f
    
    # 清理未使用的网络
    echo -e "${BLUE}清理未使用的网络...${NC}"
    docker network prune -f
    
    # 清理未使用的卷
    echo -e "${BLUE}清理未使用的卷...${NC}"
    docker volume prune -f
    
    echo -e "${GREEN}✓ 资源清理完成${NC}"
}

# 检查服务状态
check_services() {
    local compose_file=$1
    echo -e "${YELLOW}检查服务状态...${NC}"
    
    docker-compose -f "$compose_file" ps
}

# 显示服务信息
show_service_info() {
    echo -e "${BLUE}服务访问信息:${NC}"
    echo ""
    echo "Web界面:"
    echo "  - 前端: http://localhost:3000"
    echo "  - API: http://localhost:8080"
    echo "  - Nginx: http://localhost:80"
    echo ""
    echo "管理界面:"
    echo "  - Consul: http://localhost:8500"
    echo "  - Neo4j: http://localhost:7474"
    echo ""
    echo "数据库:"
    echo "  - MySQL: localhost:3306"
    echo "  - Redis: localhost:6379"
    echo "  - PostgreSQL: localhost:5432"
    echo ""
    echo "微服务:"
    echo "  - 用户服务: localhost:8081"
    echo "  - 简历服务: localhost:8082"
    echo "  - AI服务: localhost:8000"
}

# 主函数
main() {
    local env="dev"
    local action=""
    local force="false"
    
    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--dev)
                env="dev"
                shift
                ;;
            -p|--prod)
                env="prod"
                shift
                ;;
            -b|--build)
                action="build"
                shift
                ;;
            -u|--up)
                action="up"
                shift
                ;;
            -s|--stop)
                action="stop"
                shift
                ;;
            -r|--restart)
                action="restart"
                shift
                ;;
            -l|--logs)
                action="logs"
                shift
                ;;
            -c|--clean)
                action="clean"
                shift
                ;;
            -f|--force)
                force="true"
                shift
                ;;
            -h|--help)
                action="help"
                shift
                ;;
            *)
                echo -e "${RED}未知选项: $1${NC}"
                show_help
                exit 1
                ;;
        esac
    done
    
    # 显示帮助信息
    if [[ "$action" == "help" ]]; then
        show_help
        exit 0
    fi
    
    # 检查Docker
    check_docker
    
    # 获取compose文件
    local compose_file=$(check_compose_file "$env")
    
    echo -e "${BLUE}部署环境: $env${NC}"
    echo -e "${BLUE}Compose文件: $compose_file${NC}"
    
    # 执行相应操作
    case $action in
        build)
            pre_pull_images "$compose_file"
            build_images "$compose_file" "$force"
            ;;
        up)
            pre_pull_images "$compose_file"
            start_services "$compose_file"
            check_services "$compose_file"
            show_service_info
            ;;
        stop)
            stop_services "$compose_file"
            ;;
        restart)
            restart_services "$compose_file"
            check_services "$compose_file"
            ;;
        logs)
            show_logs "$compose_file"
            ;;
        clean)
            clean_resources
            ;;
        "")
            # 默认操作：构建并启动
            pre_pull_images "$compose_file"
            build_images "$compose_file" "$force"
            start_services "$compose_file"
            check_services "$compose_file"
            show_service_info
            ;;
    esac
}

# 运行主函数
main "$@"
