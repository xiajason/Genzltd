#!/bin/bash
# 本地开发环境停止脚本

echo "🛑 停止本地开发环境"
echo "=================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 停止Docker服务
stop_docker_services() {
    echo -e "${BLUE}停止Docker服务...${NC}"
    
    # 停止LoomaCRM Future服务
    if [ -d "looma_crm_future" ]; then
        echo -e "${BLUE}停止LoomaCRM Future服务...${NC}"
        cd looma_crm_future
        if [ -f "docker-compose-future-optimized.yml" ]; then
            docker-compose -f docker-compose-future-optimized.yml down
        else
            docker-compose down
        fi
        cd ..
    fi
    
    # 停止Zervigo Future服务
    if [ -d "zervigo_future" ]; then
        echo -e "${BLUE}停止Zervigo Future服务...${NC}"
        cd zervigo_future
        if [ -f "docker-compose.yml" ]; then
            docker-compose down
        fi
        cd ..
    fi
    
    # 停止所有相关容器
    echo -e "${BLUE}停止所有相关容器...${NC}"
    docker stop $(docker ps -q --filter "name=future-") 2>/dev/null || true
    docker stop $(docker ps -q --filter "name=looma-") 2>/dev/null || true
    docker stop $(docker ps -q --filter "name=zervigo-") 2>/dev/null || true
    docker stop $(docker ps -q --filter "name=jobfirst-") 2>/dev/null || true
    
    echo -e "${GREEN}✅ 所有服务已停止${NC}"
}

# 清理资源
cleanup_resources() {
    echo -e "${BLUE}清理Docker资源...${NC}"
    
    # 删除停止的容器
    docker rm $(docker ps -aq --filter "name=future-") 2>/dev/null || true
    docker rm $(docker ps -aq --filter "name=looma-") 2>/dev/null || true
    docker rm $(docker ps -aq --filter "name=zervigo-") 2>/dev/null || true
    docker rm $(docker ps -aq --filter "name=jobfirst-") 2>/dev/null || true
    
    # 清理未使用的网络
    docker network prune -f
    
    # 清理未使用的卷
    docker volume prune -f
    
    echo -e "${GREEN}✅ 资源清理完成${NC}"
}

# 显示停止状态
show_stop_status() {
    echo -e "${BLUE}显示停止状态...${NC}"
    
    # 检查容器状态
    local running_containers=$(docker ps --filter "name=future-" --filter "name=looma-" --filter "name=zervigo-" --filter "name=jobfirst-" --format "{{.Names}}")
    
    if [ -z "$running_containers" ]; then
        echo -e "${GREEN}✅ 所有开发环境容器已停止${NC}"
    else
        echo -e "${YELLOW}⚠️  以下容器仍在运行：${NC}"
        echo "$running_containers"
    fi
}

# 显示资源使用情况
show_resource_usage() {
    echo -e "${BLUE}显示资源使用情况...${NC}"
    
    # 显示Docker系统信息
    echo -e "${BLUE}Docker系统信息：${NC}"
    docker system df
    
    # 显示内存使用情况
    if command -v vm_stat >/dev/null 2>&1; then
        echo -e "${BLUE}内存使用情况：${NC}"
        vm_stat | grep -E "(Pages free|Pages active|Pages inactive|Pages speculative)"
    fi
    
    # 显示磁盘使用情况
    echo -e "${BLUE}磁盘使用情况：${NC}"
    df -h / | awk 'NR==2{printf "💿 磁盘使用率: %s (%s/%s)\n", $5, $3, $2}'
}

# 主函数
main() {
    echo -e "${BLUE}开始停止本地开发环境...${NC}"
    
    # 停止Docker服务
    stop_docker_services
    
    # 清理资源
    cleanup_resources
    
    # 显示停止状态
    show_stop_status
    
    # 显示资源使用情况
    show_resource_usage
    
    echo ""
    echo -e "${GREEN}🎉 本地开发环境已停止！${NC}"
    echo "=================="
    echo -e "${YELLOW}💡 提示：${NC}"
    echo "  - 使用 ./start-local-development.sh 重新启动服务"
    echo "  - 使用 docker system prune -a 清理所有未使用的资源"
    echo "  - 使用 docker volume ls 查看剩余的卷"
}

# 运行主函数
main "$@"
