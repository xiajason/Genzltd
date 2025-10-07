#!/bin/bash

# =============================================================================
# 部署管理脚本
# 用于管理腾讯云服务器的部署和版本控制
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
BACKUP_DIR="$PROJECT_DIR/backups"
DEPLOY_DIR="$PROJECT_DIR/deployments"

# 部署配置
DEPLOYMENT_SERVICES=(
    "basic-server:Basic Server:Go"
    "user-service:User Service:Go"
    "ai-service:AI Service:Python"
    "consul:Consul:Binary"
)

# 显示帮助信息
show_help() {
    echo -e "${CYAN}=============================================================================${NC}"
    echo -e "${CYAN}                        部署管理脚本${NC}"
    echo -e "${CYAN}=============================================================================${NC}"
    echo ""
    echo -e "${YELLOW}用法:${NC}"
    echo "  $0 [命令] [选项]"
    echo ""
    echo -e "${YELLOW}命令:${NC}"
    echo "  deploy          - 部署新版本"
    echo "  rollback        - 回滚到上一个版本"
    echo "  backup          - 创建系统备份"
    echo "  restore         - 恢复系统备份"
    echo "  list            - 列出所有版本"
    echo "  status          - 显示部署状态"
    echo "  build           - 构建所有服务"
    echo "  test            - 执行部署测试"
    echo "  clean           - 清理旧版本"
    echo ""
    echo -e "${YELLOW}选项:${NC}"
    echo "  -s, --service   指定服务名称"
    echo "  -v, --version   指定版本号"
    echo "  -f, --force     强制操作"
    echo "  -t, --test      部署后执行测试"
    echo "  -h, --help      显示帮助信息"
    echo ""
    echo -e "${YELLOW}示例:${NC}"
    echo "  $0 deploy -v v1.2.0        # 部署版本v1.2.0"
    echo "  $0 rollback -s basic-server # 回滚Basic Server"
    echo "  $0 backup                  # 创建系统备份"
    echo "  $0 list                    # 列出所有版本"
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

# 获取当前版本
get_current_version() {
    local service_name="$1"
    local version_file="$PROJECT_DIR/$service_name/version.txt"
    execute_remote "cat $version_file 2>/dev/null || echo 'unknown'"
}

# 设置版本
set_version() {
    local service_name="$1"
    local version="$2"
    local version_file="$PROJECT_DIR/$service_name/version.txt"
    execute_remote "echo '$version' > $version_file"
}

# 创建部署目录
create_deploy_dirs() {
    execute_remote "mkdir -p $BACKUP_DIR $DEPLOY_DIR"
}

# 部署新版本
deploy_version() {
    local version="$1"
    local service_name="$2"
    local force="$3"
    local run_tests="$4"
    
    echo -e "${CYAN}=============================================================================${NC}"
    echo -e "${CYAN}                        部署新版本${NC}"
    echo -e "${CYAN}=============================================================================${NC}"
    
    if [ -z "$version" ]; then
        version="v$(date +%Y%m%d-%H%M%S)"
    fi
    
    echo -e "${YELLOW}部署版本: $version${NC}"
    if [ -n "$service_name" ]; then
        echo -e "${YELLOW}目标服务: $service_name${NC}"
    else
        echo -e "${YELLOW}目标服务: 所有服务${NC}"
    fi
    
    if [ "$force" != "true" ]; then
        echo -e "${YELLOW}警告: 这将停止服务并部署新版本，是否继续? (y/N)${NC}"
        read -r response
        if [ "$response" != "y" ] && [ "$response" != "Y" ]; then
            echo -e "${RED}部署已取消${NC}"
            exit 0
        fi
    fi
    
    # 创建部署目录
    create_deploy_dirs
    
    # 创建备份
    echo -e "${YELLOW}创建备份...${NC}"
    backup_system "pre-deploy-$version"
    
    # 停止服务
    echo -e "${YELLOW}停止服务...${NC}"
    if [ -n "$service_name" ]; then
        stop_service "$service_name"
    else
        stop_all_services
    fi
    
    # 构建服务
    echo -e "${YELLOW}构建服务...${NC}"
    if [ -n "$service_name" ]; then
        build_service "$service_name"
    else
        build_all_services
    fi
    
    # 启动服务
    echo -e "${YELLOW}启动服务...${NC}"
    if [ -n "$service_name" ]; then
        start_service "$service_name"
        set_version "$service_name" "$version"
    else
        start_all_services
        for service in "${DEPLOYMENT_SERVICES[@]}"; do
            IFS=':' read -r name desc type <<< "$service"
            set_version "$name" "$version"
        done
    fi
    
    # 执行测试
    if [ "$run_tests" = "true" ]; then
        echo -e "${YELLOW}执行部署测试...${NC}"
        run_deployment_tests
    fi
    
    echo -e "${GREEN}✓ 部署完成: $version${NC}"
}

# 回滚版本
rollback_version() {
    local service_name="$1"
    local force="$2"
    
    echo -e "${CYAN}=============================================================================${NC}"
    echo -e "${CYAN}                        回滚版本${NC}"
    echo -e "${CYAN}=============================================================================${NC}"
    
    if [ "$force" != "true" ]; then
        echo -e "${YELLOW}警告: 这将回滚到上一个版本，是否继续? (y/N)${NC}"
        read -r response
        if [ "$response" != "y" ] && [ "$response" != "Y" ]; then
            echo -e "${RED}回滚已取消${NC}"
            exit 0
        fi
    fi
    
    # 创建回滚备份
    echo -e "${YELLOW}创建回滚备份...${NC}"
    backup_system "pre-rollback-$(date +%Y%m%d-%H%M%S)"
    
    # 停止服务
    echo -e "${YELLOW}停止服务...${NC}"
    if [ -n "$service_name" ]; then
        stop_service "$service_name"
    else
        stop_all_services
    fi
    
    # 恢复备份
    echo -e "${YELLOW}恢复备份...${NC}"
    local latest_backup=$(execute_remote "ls -t $BACKUP_DIR/*.tar.gz | head -1")
    if [ -n "$latest_backup" ]; then
        execute_remote "cd $PROJECT_DIR && tar -xzf $latest_backup"
    else
        echo -e "${RED}错误: 未找到备份文件${NC}"
        exit 1
    fi
    
    # 启动服务
    echo -e "${YELLOW}启动服务...${NC}"
    if [ -n "$service_name" ]; then
        start_service "$service_name"
    else
        start_all_services
    fi
    
    echo -e "${GREEN}✓ 回滚完成${NC}"
}

# 创建系统备份
backup_system() {
    local backup_name="$1"
    
    if [ -z "$backup_name" ]; then
        backup_name="backup-$(date +%Y%m%d-%H%M%S)"
    fi
    
    echo -e "${CYAN}=============================================================================${NC}"
    echo -e "${CYAN}                        创建系统备份${NC}"
    echo -e "${CYAN}=============================================================================${NC}"
    
    echo -e "${YELLOW}备份名称: $backup_name${NC}"
    
    # 创建备份目录
    create_deploy_dirs
    
    # 备份项目文件
    echo -e "${YELLOW}备份项目文件...${NC}"
    execute_remote "cd $PROJECT_DIR && tar -czf $BACKUP_DIR/$backup_name.tar.gz --exclude='*.log' --exclude='backups' --exclude='venv' --exclude='deployments' ."
    
    # 备份数据库
    echo -e "${YELLOW}备份数据库...${NC}"
    execute_remote "mysqldump -u jobfirst -p'jobfirst_prod_2024' jobfirst > $BACKUP_DIR/$backup_name-db.sql"
    
    # 备份配置文件
    echo -e "${YELLOW}备份配置文件...${NC}"
    execute_remote "tar -czf $BACKUP_DIR/$backup_name-config.tar.gz /etc/nginx /etc/mysql /etc/redis /etc/postgresql"
    
    echo -e "${GREEN}✓ 备份完成: $backup_name${NC}"
}

# 恢复系统备份
restore_system() {
    local backup_name="$1"
    
    echo -e "${CYAN}=============================================================================${NC}"
    echo -e "${CYAN}                        恢复系统备份${NC}"
    echo -e "${CYAN}=============================================================================${NC}"
    
    if [ -z "$backup_name" ]; then
        echo -e "${YELLOW}可用备份:${NC}"
        list_backups
        echo -e "${YELLOW}请输入备份名称:${NC}"
        read -r backup_name
    fi
    
    echo -e "${YELLOW}恢复备份: $backup_name${NC}"
    
    # 停止所有服务
    echo -e "${YELLOW}停止所有服务...${NC}"
    stop_all_services
    
    # 恢复项目文件
    echo -e "${YELLOW}恢复项目文件...${NC}"
    execute_remote "cd $PROJECT_DIR && tar -xzf $BACKUP_DIR/$backup_name.tar.gz"
    
    # 恢复数据库
    echo -e "${YELLOW}恢复数据库...${NC}"
    execute_remote "mysql -u jobfirst -p'jobfirst_prod_2024' jobfirst < $BACKUP_DIR/$backup_name-db.sql"
    
    # 启动服务
    echo -e "${YELLOW}启动服务...${NC}"
    start_all_services
    
    echo -e "${GREEN}✓ 恢复完成: $backup_name${NC}"
}

# 列出所有版本
list_versions() {
    echo -e "${CYAN}=============================================================================${NC}"
    echo -e "${CYAN}                        版本列表${NC}"
    echo -e "${CYAN}=============================================================================${NC}"
    
    echo -e "${YELLOW}当前版本:${NC}"
    for service in "${DEPLOYMENT_SERVICES[@]}"; do
        IFS=':' read -r name desc type <<< "$service"
        local version=$(get_current_version "$name")
        echo -e "  $name: $version"
    done
    
    echo -e "\n${YELLOW}备份列表:${NC}"
    execute_remote "ls -la $BACKUP_DIR/*.tar.gz 2>/dev/null || echo '无备份文件'"
}

# 显示部署状态
show_deployment_status() {
    echo -e "${CYAN}=============================================================================${NC}"
    echo -e "${CYAN}                        部署状态${NC}"
    echo -e "${CYAN}=============================================================================${NC}"
    
    # 服务状态
    echo -e "${YELLOW}服务状态:${NC}"
    for service in "${DEPLOYMENT_SERVICES[@]}"; do
        IFS=':' read -r name desc type <<< "$service"
        local version=$(get_current_version "$name")
        local is_running=$(execute_remote "ps aux | grep $name | grep -v grep" 2>/dev/null || echo "")
        if [ -n "$is_running" ]; then
            echo -e "  ${GREEN}✓${NC} $name ($version) - ${GREEN}运行中${NC}"
        else
            echo -e "  ${RED}✗${NC} $name ($version) - ${RED}未运行${NC}"
        fi
    done
    
    # 部署信息
    echo -e "\n${YELLOW}部署信息:${NC}"
    execute_remote "echo '部署目录:' && ls -la $DEPLOY_DIR 2>/dev/null || echo '无部署文件'"
    execute_remote "echo '备份目录:' && ls -la $BACKUP_DIR 2>/dev/null || echo '无备份文件'"
}

# 构建所有服务
build_all_services() {
    echo -e "${YELLOW}构建所有服务...${NC}"
    for service in "${DEPLOYMENT_SERVICES[@]}"; do
        IFS=':' read -r name desc type <<< "$service"
        build_service "$name"
    done
}

# 构建单个服务
build_service() {
    local service_name="$1"
    
    echo -e "${YELLOW}构建 $service_name...${NC}"
    
    case "$service_name" in
        "basic-server")
            execute_remote "cd $PROJECT_DIR/$service_name && export PATH=\$PATH:/usr/local/go/bin && export GOPROXY=https://goproxy.cn,direct && go build -o main main.go rbac_apis.go"
            ;;
        "user-service")
            execute_remote "cd $PROJECT_DIR/$service_name && export PATH=\$PATH:/usr/local/go/bin && export GOPROXY=https://goproxy.cn,direct && go build -o user-service main.go"
            ;;
        "ai-service")
            execute_remote "cd $PROJECT_DIR/$service_name && source venv/bin/activate && pip install -r requirements.txt"
            ;;
        "consul")
            echo -e "${YELLOW}Consul 无需构建${NC}"
            ;;
    esac
}

# 停止所有服务
stop_all_services() {
    echo -e "${YELLOW}停止所有服务...${NC}"
    for service in "${DEPLOYMENT_SERVICES[@]}"; do
        IFS=':' read -r name desc type <<< "$service"
        stop_service "$name"
    done
}

# 停止单个服务
stop_service() {
    local service_name="$1"
    
    echo -e "${YELLOW}停止 $service_name...${NC}"
    
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
    esac
    
    sleep 2
}

# 启动所有服务
start_all_services() {
    echo -e "${YELLOW}启动所有服务...${NC}"
    for service in "${DEPLOYMENT_SERVICES[@]}"; do
        IFS=':' read -r name desc type <<< "$service"
        start_service "$name"
    done
}

# 启动单个服务
start_service() {
    local service_name="$1"
    
    echo -e "${YELLOW}启动 $service_name...${NC}"
    
    case "$service_name" in
        "basic-server")
            execute_remote "cd $PROJECT_DIR/$service_name && export PATH=\$PATH:/usr/local/go/bin && ./main > $service_name.log 2>&1 &"
            ;;
        "user-service")
            execute_remote "cd $PROJECT_DIR/$service_name && export PATH=\$PATH:/usr/local/go/bin && ./user-service > $service_name.log 2>&1 &"
            ;;
        "ai-service")
            execute_remote "cd $PROJECT_DIR/$service_name && source venv/bin/activate && python3 ai_service.py > $service_name.log 2>&1 &"
            ;;
        "consul")
            execute_remote "cd $PROJECT_DIR/$service_name && consul agent -config-dir=config/ > $service_name.log 2>&1 &"
            ;;
    esac
    
    sleep 3
}

# 执行部署测试
run_deployment_tests() {
    echo -e "${YELLOW}执行部署测试...${NC}"
    
    # 健康检查
    local health_ports=("8080" "8081" "8206" "8500")
    for port in "${health_ports[@]}"; do
        if [ "$port" != "8500" ]; then
            local health_url="http://localhost:$port/health"
            local health_status=$(execute_remote "curl -s -w '%{http_code}' $health_url" 2>/dev/null || echo "000")
            if [ "$health_status" = "200" ]; then
                echo -e "  ${GREEN}✓${NC} 端口 $port 健康检查通过"
            else
                echo -e "  ${RED}✗${NC} 端口 $port 健康检查失败"
                return 1
            fi
        fi
    done
    
    # API测试
    echo -e "${YELLOW}API功能测试...${NC}"
    local api_tests=(
        "http://localhost:8080/api/v1/rbac/check:RBAC权限检查API"
        "http://localhost:8080/api/v1/super-admin/public/status:超级管理员状态API"
    )
    
    for test in "${api_tests[@]}"; do
        IFS=':' read -r url desc <<< "$test"
        local response=$(execute_remote "curl -s $url" 2>/dev/null || echo "")
        if [ -n "$response" ]; then
            echo -e "  ${GREEN}✓${NC} $desc 测试通过"
        else
            echo -e "  ${RED}✗${NC} $desc 测试失败"
            return 1
        fi
    done
    
    echo -e "${GREEN}✓ 部署测试通过${NC}"
}

# 列出备份
list_backups() {
    execute_remote "ls -la $BACKUP_DIR/*.tar.gz 2>/dev/null || echo '无备份文件'"
}

# 清理旧版本
clean_old_versions() {
    local keep_count="${1:-5}"
    
    echo -e "${CYAN}=============================================================================${NC}"
    echo -e "${CYAN}                        清理旧版本${NC}"
    echo -e "${CYAN}=============================================================================${NC}"
    
    echo -e "${YELLOW}保留最近 $keep_count 个备份，删除其他备份...${NC}"
    
    # 清理备份文件
    execute_remote "cd $BACKUP_DIR && ls -t *.tar.gz | tail -n +$((keep_count + 1)) | xargs rm -f"
    execute_remote "cd $BACKUP_DIR && ls -t *.sql | tail -n +$((keep_count + 1)) | xargs rm -f"
    
    # 清理日志文件
    execute_remote "find $PROJECT_DIR -name '*.log' -mtime +7 -delete"
    
    echo -e "${GREEN}✓ 清理完成${NC}"
}

# 主函数
main() {
    local command="$1"
    local service_name=""
    local version=""
    local force="false"
    local run_tests="false"
    
    # 解析参数
    shift
    while [[ $# -gt 0 ]]; do
        case $1 in
            -s|--service)
                service_name="$2"
                shift 2
                ;;
            -v|--version)
                version="$2"
                shift 2
                ;;
            -f|--force)
                force="true"
                shift
                ;;
            -t|--test)
                run_tests="true"
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
        "deploy")
            deploy_version "$version" "$service_name" "$force" "$run_tests"
            ;;
        "rollback")
            rollback_version "$service_name" "$force"
            ;;
        "backup")
            backup_system
            ;;
        "restore")
            restore_system
            ;;
        "list")
            list_versions
            ;;
        "status")
            show_deployment_status
            ;;
        "build")
            if [ -n "$service_name" ]; then
                build_service "$service_name"
            else
                build_all_services
            fi
            ;;
        "test")
            run_deployment_tests
            ;;
        "clean")
            clean_old_versions
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
