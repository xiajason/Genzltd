#!/bin/bash

# =============================================================================
# 超级管理员远程控制脚本
# 用于管理腾讯云服务器上的所有服务
# =============================================================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 配置变量
SERVER_IP="101.33.251.158"
SERVER_USER="ubuntu"
SSH_KEY="~/.ssh/basic.pem"
PROJECT_DIR="/opt/jobfirst"
LOG_DIR="$PROJECT_DIR/logs"

# 服务配置
SERVICES=(
    "basic-server:8080:Basic Server"
    "user-service:8081:User Service"
    "ai-service:8206:AI Service"
    "consul:8500:Consul"
)

# 基础设施服务
INFRASTRUCTURE_SERVICES=(
    "mysql:MySQL Database"
    "redis-server:Redis Cache"
    "postgresql:PostgreSQL Database"
    "nginx:Nginx Web Server"
)

# 显示帮助信息
show_help() {
    echo -e "${CYAN}=============================================================================${NC}"
    echo -e "${CYAN}                    超级管理员远程控制脚本${NC}"
    echo -e "${CYAN}=============================================================================${NC}"
    echo ""
    echo -e "${YELLOW}用法:${NC}"
    echo "  $0 [命令] [选项]"
    echo ""
    echo -e "${YELLOW}命令:${NC}"
    echo "  status          - 显示所有服务状态"
    echo "  start           - 启动所有服务"
    echo "  stop            - 停止所有服务"
    echo "  restart         - 重启所有服务"
    echo "  logs            - 查看服务日志"
    echo "  health          - 健康检查"
    echo "  deploy          - 部署新版本"
    echo "  backup          - 备份系统"
    echo "  monitor         - 实时监控"
    echo "  shell           - 进入服务器Shell"
    echo "  update          - 更新系统"
    echo "  clean           - 清理系统"
    echo ""
    echo -e "${YELLOW}选项:${NC}"
    echo "  -s, --service   指定服务名称"
    echo "  -f, --force     强制操作"
    echo "  -v, --verbose   详细输出"
    echo "  -h, --help      显示帮助信息"
    echo ""
    echo -e "${YELLOW}示例:${NC}"
    echo "  $0 status                    # 查看所有服务状态"
    echo "  $0 restart -s basic-server   # 重启Basic Server"
    echo "  $0 logs -s user-service      # 查看User Service日志"
    echo "  $0 deploy -f                 # 强制部署新版本"
    echo ""
}

# 执行远程命令
execute_remote() {
    local cmd="$1"
    local verbose="${2:-false}"
    
    if [ "$verbose" = "true" ]; then
        echo -e "${BLUE}执行命令: $cmd${NC}"
    fi
    
    ssh -i "$SSH_KEY" "$SERVER_USER@$SERVER_IP" "$cmd"
}

# 显示服务状态
show_status() {
    echo -e "${CYAN}=============================================================================${NC}"
    echo -e "${CYAN}                        服务状态检查${NC}"
    echo -e "${CYAN}=============================================================================${NC}"
    
    # 检查基础设施服务
    echo -e "\n${YELLOW}基础设施服务:${NC}"
    for service in "${INFRASTRUCTURE_SERVICES[@]}"; do
        IFS=':' read -r service_name service_desc <<< "$service"
        status=$(execute_remote "sudo systemctl is-active $service_name" 2>/dev/null || echo "inactive")
        if [ "$status" = "active" ]; then
            echo -e "  ${GREEN}✓${NC} $service_desc ($service_name) - ${GREEN}运行中${NC}"
        else
            echo -e "  ${RED}✗${NC} $service_desc ($service_name) - ${RED}未运行${NC}"
        fi
    done
    
    # 检查应用服务
    echo -e "\n${YELLOW}应用服务:${NC}"
    for service in "${SERVICES[@]}"; do
        IFS=':' read -r service_name service_port service_desc <<< "$service"
        status=$(execute_remote "sudo netstat -tlnp | grep :$service_port" 2>/dev/null || echo "")
        if [ -n "$status" ]; then
            echo -e "  ${GREEN}✓${NC} $service_desc ($service_name) - ${GREEN}运行中${NC} (端口:$service_port)"
        else
            echo -e "  ${RED}✗${NC} $service_desc ($service_name) - ${RED}未运行${NC} (端口:$service_port)"
        fi
    done
    
    # 显示系统资源
    echo -e "\n${YELLOW}系统资源:${NC}"
    execute_remote "echo '内存使用:' && free -h | grep Mem && echo '磁盘使用:' && df -h | grep -E '^/dev/'"
}

# 启动服务
start_services() {
    local service_name="$1"
    
    echo -e "${CYAN}=============================================================================${NC}"
    echo -e "${CYAN}                        启动服务${NC}"
    echo -e "${CYAN}=============================================================================${NC}"
    
    if [ -n "$service_name" ]; then
        start_single_service "$service_name"
    else
        # 启动所有服务
        echo -e "${YELLOW}启动基础设施服务...${NC}"
        for service in "${INFRASTRUCTURE_SERVICES[@]}"; do
            IFS=':' read -r service_name service_desc <<< "$service"
            echo -e "启动 $service_desc..."
            execute_remote "sudo systemctl start $service_name"
        done
        
        echo -e "\n${YELLOW}启动应用服务...${NC}"
        execute_remote "cd $PROJECT_DIR && ./start-services.sh"
    fi
    
    echo -e "\n${GREEN}服务启动完成！${NC}"
    show_status
}

# 启动单个服务
start_single_service() {
    local service_name="$1"
    
    case "$service_name" in
        "basic-server")
            execute_remote "cd $PROJECT_DIR/basic-server && export PATH=\$PATH:/usr/local/go/bin && ./main > basic-server.log 2>&1 &"
            ;;
        "user-service")
            execute_remote "cd $PROJECT_DIR/user-service && export PATH=\$PATH:/usr/local/go/bin && ./user-service > user-service.log 2>&1 &"
            ;;
        "ai-service")
            execute_remote "cd $PROJECT_DIR/ai-service && source venv/bin/activate && python3 ai_service.py > ai-service.log 2>&1 &"
            ;;
        "consul")
            execute_remote "cd $PROJECT_DIR/consul && consul agent -config-dir=config/ > consul.log 2>&1 &"
            ;;
        *)
            execute_remote "sudo systemctl start $service_name"
            ;;
    esac
}

# 停止服务
stop_services() {
    local service_name="$1"
    
    echo -e "${CYAN}=============================================================================${NC}"
    echo -e "${CYAN}                        停止服务${NC}"
    echo -e "${CYAN}=============================================================================${NC}"
    
    if [ -n "$service_name" ]; then
        stop_single_service "$service_name"
    else
        # 停止所有应用服务
        echo -e "${YELLOW}停止应用服务...${NC}"
        execute_remote "pkill -f 'basic-server' || true"
        execute_remote "pkill -f 'user-service' || true"
        execute_remote "pkill -f 'ai_service' || true"
        execute_remote "pkill -f 'consul' || true"
        
        # 停止基础设施服务
        echo -e "${YELLOW}停止基础设施服务...${NC}"
        for service in "${INFRASTRUCTURE_SERVICES[@]}"; do
            IFS=':' read -r service_name service_desc <<< "$service"
            echo -e "停止 $service_desc..."
            execute_remote "sudo systemctl stop $service_name"
        done
    fi
    
    echo -e "\n${GREEN}服务停止完成！${NC}"
}

# 停止单个服务
stop_single_service() {
    local service_name="$1"
    
    case "$service_name" in
        "basic-server")
            execute_remote "pkill -f 'basic-server' || true"
            ;;
        "user-service")
            execute_remote "pkill -f 'user-service' || true"
            ;;
        "ai-service")
            execute_remote "pkill -f 'ai_service' || true"
            ;;
        "consul")
            execute_remote "pkill -f 'consul' || true"
            ;;
        *)
            execute_remote "sudo systemctl stop $service_name"
            ;;
    esac
}

# 重启服务
restart_services() {
    local service_name="$1"
    
    echo -e "${CYAN}=============================================================================${NC}"
    echo -e "${CYAN}                        重启服务${NC}"
    echo -e "${CYAN}=============================================================================${NC}"
    
    if [ -n "$service_name" ]; then
        echo -e "${YELLOW}重启 $service_name...${NC}"
        stop_single_service "$service_name"
        sleep 2
        start_single_service "$service_name"
    else
        echo -e "${YELLOW}重启所有服务...${NC}"
        stop_services
        sleep 3
        start_services
    fi
    
    echo -e "\n${GREEN}服务重启完成！${NC}"
    show_status
}

# 查看日志
show_logs() {
    local service_name="$1"
    
    echo -e "${CYAN}=============================================================================${NC}"
    echo -e "${CYAN}                        服务日志${NC}"
    echo -e "${CYAN}=============================================================================${NC}"
    
    if [ -n "$service_name" ]; then
        case "$service_name" in
            "basic-server")
                execute_remote "cd $PROJECT_DIR/basic-server && tail -50 basic-server.log"
                ;;
            "user-service")
                execute_remote "cd $PROJECT_DIR/user-service && tail -50 user-service.log"
                ;;
            "ai-service")
                execute_remote "cd $PROJECT_DIR/ai-service && tail -50 ai-service.log"
                ;;
            "consul")
                execute_remote "cd $PROJECT_DIR/consul && tail -50 consul.log"
                ;;
            *)
                execute_remote "sudo journalctl -u $service_name -n 50 --no-pager"
                ;;
        esac
    else
        echo -e "${YELLOW}所有服务日志:${NC}"
        for service in "${SERVICES[@]}"; do
            IFS=':' read -r service_name service_port service_desc <<< "$service"
            echo -e "\n${BLUE}=== $service_desc 日志 ===${NC}"
            show_logs "$service_name"
        done
    fi
}

# 健康检查
health_check() {
    echo -e "${CYAN}=============================================================================${NC}"
    echo -e "${CYAN}                        健康检查${NC}"
    echo -e "${CYAN}=============================================================================${NC}"
    
    # 检查端口连通性
    echo -e "${YELLOW}端口连通性检查:${NC}"
    for service in "${SERVICES[@]}"; do
        IFS=':' read -r service_name service_port service_desc <<< "$service"
        if execute_remote "nc -z localhost $service_port" 2>/dev/null; then
            echo -e "  ${GREEN}✓${NC} $service_desc (端口:$service_port) - ${GREEN}连通${NC}"
        else
            echo -e "  ${RED}✗${NC} $service_desc (端口:$service_port) - ${RED}不通${NC}"
        fi
    done
    
    # 检查HTTP健康端点
    echo -e "\n${YELLOW}HTTP健康检查:${NC}"
    for service in "${SERVICES[@]}"; do
        IFS=':' read -r service_name service_port service_desc <<< "$service"
        if [ "$service_name" != "consul" ]; then
            health_url="http://localhost:$service_port/health"
            if execute_remote "curl -s $health_url" >/dev/null 2>&1; then
                echo -e "  ${GREEN}✓${NC} $service_desc - ${GREEN}健康${NC}"
            else
                echo -e "  ${RED}✗${NC} $service_desc - ${RED}不健康${NC}"
            fi
        fi
    done
}

# 部署新版本
deploy_version() {
    local force="$1"
    
    echo -e "${CYAN}=============================================================================${NC}"
    echo -e "${CYAN}                        部署新版本${NC}"
    echo -e "${CYAN}=============================================================================${NC}"
    
    if [ "$force" != "true" ]; then
        echo -e "${YELLOW}警告: 这将停止所有服务并重新部署，是否继续? (y/N)${NC}"
        read -r response
        if [ "$response" != "y" ] && [ "$response" != "Y" ]; then
            echo -e "${RED}部署已取消${NC}"
            exit 0
        fi
    fi
    
    echo -e "${YELLOW}开始部署...${NC}"
    
    # 停止所有服务
    stop_services
    
    # 备份当前版本
    execute_remote "cd $PROJECT_DIR && tar -czf backup-$(date +%Y%m%d-%H%M%S).tar.gz --exclude='*.log' --exclude='backup-*' ."
    
    # 重新构建服务
    echo -e "${YELLOW}重新构建服务...${NC}"
    execute_remote "cd $PROJECT_DIR/basic-server && export PATH=\$PATH:/usr/local/go/bin && export GOPROXY=https://goproxy.cn,direct && go build -o main main.go rbac_apis.go"
    execute_remote "cd $PROJECT_DIR/user-service && export PATH=\$PATH:/usr/local/go/bin && export GOPROXY=https://goproxy.cn,direct && go build -o user-service main.go"
    
    # 启动服务
    start_services
    
    echo -e "\n${GREEN}部署完成！${NC}"
}

# 备份系统
backup_system() {
    echo -e "${CYAN}=============================================================================${NC}"
    echo -e "${CYAN}                        系统备份${NC}"
    echo -e "${CYAN}=============================================================================${NC}"
    
    local backup_name="backup-$(date +%Y%m%d-%H%M%S)"
    echo -e "${YELLOW}创建备份: $backup_name${NC}"
    
    # 创建备份目录
    execute_remote "mkdir -p $PROJECT_DIR/backups"
    
    # 备份项目文件
    execute_remote "cd $PROJECT_DIR && tar -czf backups/$backup_name.tar.gz --exclude='*.log' --exclude='backups' --exclude='venv' ."
    
    # 备份数据库
    execute_remote "mysqldump -u jobfirst -p'jobfirst_prod_2024' jobfirst > $PROJECT_DIR/backups/$backup_name-db.sql"
    
    echo -e "${GREEN}备份完成: $backup_name${NC}"
}

# 实时监控
monitor_system() {
    echo -e "${CYAN}=============================================================================${NC}"
    echo -e "${CYAN}                        实时监控${NC}"
    echo -e "${CYAN}=============================================================================${NC}"
    echo -e "${YELLOW}按 Ctrl+C 退出监控${NC}"
    echo ""
    
    while true; do
        clear
        echo -e "${CYAN}实时监控 - $(date)${NC}"
        echo ""
        
        # 显示系统资源
        execute_remote "echo '内存使用:' && free -h | grep Mem && echo '磁盘使用:' && df -h | grep -E '^/dev/'"
        echo ""
        
        # 显示服务状态
        for service in "${SERVICES[@]}"; do
            IFS=':' read -r service_name service_port service_desc <<< "$service"
            status=$(execute_remote "sudo netstat -tlnp | grep :$service_port" 2>/dev/null || echo "")
            if [ -n "$status" ]; then
                echo -e "  ${GREEN}✓${NC} $service_desc (端口:$service_port)"
            else
                echo -e "  ${RED}✗${NC} $service_desc (端口:$service_port)"
            fi
        done
        
        sleep 5
    done
}

# 进入服务器Shell
enter_shell() {
    echo -e "${CYAN}=============================================================================${NC}"
    echo -e "${CYAN}                        进入服务器Shell${NC}"
    echo -e "${CYAN}=============================================================================${NC}"
    echo -e "${YELLOW}连接到服务器: $SERVER_USER@$SERVER_IP${NC}"
    echo -e "${YELLOW}按 Ctrl+D 或输入 exit 退出${NC}"
    echo ""
    
    ssh -i "$SSH_KEY" "$SERVER_USER@$SERVER_IP"
}

# 更新系统
update_system() {
    echo -e "${CYAN}=============================================================================${NC}"
    echo -e "${CYAN}                        更新系统${NC}"
    echo -e "${CYAN}=============================================================================${NC}"
    
    echo -e "${YELLOW}更新系统包...${NC}"
    execute_remote "sudo apt update && sudo apt upgrade -y"
    
    echo -e "${YELLOW}清理系统...${NC}"
    execute_remote "sudo apt autoremove -y && sudo apt autoclean"
    
    echo -e "${GREEN}系统更新完成！${NC}"
}

# 清理系统
clean_system() {
    echo -e "${CYAN}=============================================================================${NC}"
    echo -e "${CYAN}                        清理系统${NC}"
    echo -e "${CYAN}=============================================================================${NC}"
    
    echo -e "${YELLOW}清理日志文件...${NC}"
    execute_remote "find $PROJECT_DIR -name '*.log' -mtime +7 -delete"
    
    echo -e "${YELLOW}清理临时文件...${NC}"
    execute_remote "sudo rm -rf /tmp/*"
    
    echo -e "${YELLOW}清理包缓存...${NC}"
    execute_remote "sudo apt clean"
    
    echo -e "${GREEN}系统清理完成！${NC}"
}

# 主函数
main() {
    local command="$1"
    local service_name=""
    local force="false"
    local verbose="false"
    
    # 解析参数
    shift
    while [[ $# -gt 0 ]]; do
        case $1 in
            -s|--service)
                service_name="$2"
                shift 2
                ;;
            -f|--force)
                force="true"
                shift
                ;;
            -v|--verbose)
                verbose="true"
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                echo -e "${RED}未知参数: $1${NC}"
                show_help
                exit 1
                ;;
        esac
    done
    
    # 执行命令
    case "$command" in
        "status")
            show_status
            ;;
        "start")
            start_services "$service_name"
            ;;
        "stop")
            stop_services "$service_name"
            ;;
        "restart")
            restart_services "$service_name"
            ;;
        "logs")
            show_logs "$service_name"
            ;;
        "health")
            health_check
            ;;
        "deploy")
            deploy_version "$force"
            ;;
        "backup")
            backup_system
            ;;
        "monitor")
            monitor_system
            ;;
        "shell")
            enter_shell
            ;;
        "update")
            update_system
            ;;
        "clean")
            clean_system
            ;;
        *)
            echo -e "${RED}未知命令: $command${NC}"
            show_help
            exit 1
            ;;
    esac
}

# 检查SSH连接
check_ssh_connection() {
    if ! ssh -i "$SSH_KEY" -o ConnectTimeout=5 "$SERVER_USER@$SERVER_IP" "echo 'SSH连接成功'" >/dev/null 2>&1; then
        echo -e "${RED}错误: 无法连接到服务器 $SERVER_USER@$SERVER_IP${NC}"
        echo -e "${YELLOW}请检查:${NC}"
        echo "  1. SSH密钥文件是否存在: $SSH_KEY"
        echo "  2. 服务器IP地址是否正确: $SERVER_IP"
        echo "  3. 网络连接是否正常"
        exit 1
    fi
}

# 脚本入口
if [ $# -eq 0 ]; then
    show_help
    exit 0
fi

# 检查SSH连接
check_ssh_connection

# 执行主函数
main "$@"
