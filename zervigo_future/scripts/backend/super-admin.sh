#!/bin/bash

# =============================================================================
# 超级管理员控制工具
# 专注于基础设施管理和权限角色分配
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

# 显示帮助信息
show_help() {
    echo -e "${CYAN}=============================================================================${NC}"
    echo -e "${CYAN}                    超级管理员控制工具${NC}"
    echo -e "${CYAN}=============================================================================${NC}"
    echo ""
    echo -e "${YELLOW}核心职责: 基础设施管理 + 权限角色分配${NC}"
    echo ""
    echo -e "${YELLOW}用法:${NC}"
    echo "  $0 [命令] [选项]"
    echo ""
    echo -e "${YELLOW}基础设施管理:${NC}"
    echo "  status          - 查看系统整体状态"
    echo "  infrastructure  - 管理基础设施服务"
    echo "  backup          - 系统备份管理"
    echo "  deploy          - 全局部署管理"
    echo ""
    echo -e "${YELLOW}权限角色管理:${NC}"
    echo "  users           - 用户管理"
    echo "  roles           - 角色管理"
    echo "  permissions     - 权限管理"
    echo "  access          - 访问控制"
    echo ""
    echo -e "${YELLOW}系统监控:${NC}"
    echo "  monitor         - 实时监控"
    echo "  alerts          - 告警管理"
    echo "  logs            - 系统日志"
    echo ""
    echo -e "${YELLOW}选项:${NC}"
    echo "  -f, --force     强制操作"
    echo "  -v, --verbose   详细输出"
    echo "  -h, --help      显示帮助信息"
    echo ""
    echo -e "${YELLOW}示例:${NC}"
    echo "  $0 status                    # 查看系统整体状态"
    echo "  $0 infrastructure restart    # 重启基础设施服务"
    echo "  $0 users list                # 列出所有用户"
    echo "  $0 roles assign              # 分配用户角色"
    echo "  $0 monitor                   # 实时监控系统"
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

# 查看系统整体状态
show_status() {
    echo -e "${CYAN}=============================================================================${NC}"
    echo -e "${CYAN}                        系统整体状态${NC}"
    echo -e "${CYAN}=============================================================================${NC}"
    
    # 基础设施状态
    echo -e "\n${YELLOW}基础设施服务:${NC}"
    local infra_services=("mysql" "redis-server" "postgresql" "nginx" "consul")
    for service in "${infra_services[@]}"; do
        local status=$(execute_remote "sudo systemctl is-active $service" 2>/dev/null || echo "inactive")
        if [ "$status" = "active" ]; then
            echo -e "  ${GREEN}✓${NC} $service - ${GREEN}运行中${NC}"
        else
            echo -e "  ${RED}✗${NC} $service - ${RED}未运行${NC}"
        fi
    done
    
    # 微服务集群状态
    echo -e "\n${YELLOW}微服务集群:${NC}"
    local app_ports=("8080:Basic Server" "8081:User Service" "8082:Resume Service" "8083:Company Service" "8084:Notification Service" "8085:Banner Service" "8086:Statistics Service" "8087:Template Service" "8206:AI Service")
    local running_count=0
    local total_count=${#app_ports[@]}
    
    for port_info in "${app_ports[@]}"; do
        IFS=':' read -r port name <<< "$port_info"
        local is_running=$(execute_remote "sudo netstat -tlnp | grep :$port" 2>/dev/null || echo "")
        if [ -n "$is_running" ]; then
            echo -e "  ${GREEN}✓${NC} $name (端口:$port)"
            running_count=$((running_count + 1))
        else
            echo -e "  ${RED}✗${NC} $name (端口:$port)"
        fi
    done
    
    # 集群健康度
    local health_percentage=$((running_count * 100 / total_count))
    echo -e "\n${YELLOW}集群健康度: $health_percentage% ($running_count/$total_count)${NC}"
    
    if [ "$health_percentage" -ge 90 ]; then
        echo -e "  ${GREEN}✓ 集群状态: 优秀${NC}"
    elif [ "$health_percentage" -ge 70 ]; then
        echo -e "  ${YELLOW}⚠ 集群状态: 良好${NC}"
    else
        echo -e "  ${RED}✗ 集群状态: 需要关注${NC}"
    fi
    
    # 系统资源
    echo -e "\n${YELLOW}系统资源:${NC}"
    execute_remote "echo '内存使用:' && free -h | grep Mem && echo '磁盘使用:' && df -h | grep -E '^/dev/' | head -1"
}

# 基础设施管理
manage_infrastructure() {
    local action="$1"
    
    echo -e "${CYAN}=============================================================================${NC}"
    echo -e "${CYAN}                        基础设施管理${NC}"
    echo -e "${CYAN}=============================================================================${NC}"
    
    case "$action" in
        "restart")
            echo -e "${YELLOW}重启基础设施服务...${NC}"
            local infra_services=("mysql" "redis-server" "postgresql" "nginx")
            for service in "${infra_services[@]}"; do
                echo -e "重启 $service..."
                execute_remote "sudo systemctl restart $service"
            done
            echo -e "${GREEN}✓ 基础设施服务重启完成${NC}"
            ;;
        "status")
            echo -e "${YELLOW}基础设施服务状态:${NC}"
            local infra_services=("mysql" "redis-server" "postgresql" "nginx" "consul")
            for service in "${infra_services[@]}"; do
                local status=$(execute_remote "sudo systemctl is-active $service" 2>/dev/null || echo "inactive")
                local memory=$(execute_remote "ps aux | grep $service | grep -v grep | awk '{sum+=\$6} END {print sum/1024 \"MB\"}'" 2>/dev/null || echo "0MB")
                if [ "$status" = "active" ]; then
                    echo -e "  ${GREEN}✓${NC} $service - ${GREEN}运行中${NC} (内存: $memory)"
                else
                    echo -e "  ${RED}✗${NC} $service - ${RED}未运行${NC}"
                fi
            done
            ;;
        *)
            echo -e "${YELLOW}可用操作:${NC}"
            echo "  restart - 重启基础设施服务"
            echo "  status  - 查看基础设施状态"
            ;;
    esac
}

# 用户管理
manage_users() {
    local action="$1"
    
    echo -e "${CYAN}=============================================================================${NC}"
    echo -e "${CYAN}                        用户管理${NC}"
    echo -e "${CYAN}=============================================================================${NC}"
    
    case "$action" in
        "list")
            echo -e "${YELLOW}系统用户列表:${NC}"
            execute_remote "cat /etc/passwd | grep -E '^(ubuntu|root|jobfirst)' | cut -d: -f1,3,4,5"
            echo -e "\n${YELLOW}项目用户列表:${NC}"
            execute_remote "ls -la $PROJECT_DIR/ | grep '^d' | grep -v '^\.'"
            ;;
        "create")
            echo -e "${YELLOW}创建新用户功能待实现${NC}"
            ;;
        "delete")
            echo -e "${YELLOW}删除用户功能待实现${NC}"
            ;;
        *)
            echo -e "${YELLOW}可用操作:${NC}"
            echo "  list    - 列出所有用户"
            echo "  create  - 创建新用户"
            echo "  delete  - 删除用户"
            ;;
    esac
}

# 角色管理
manage_roles() {
    local action="$1"
    
    echo -e "${CYAN}=============================================================================${NC}"
    echo -e "${CYAN}                        角色管理${NC}"
    echo -e "${CYAN}=============================================================================${NC}"
    
    case "$action" in
        "list")
            echo -e "${YELLOW}系统角色定义:${NC}"
            echo "  ${GREEN}超级管理员${NC} - 完全系统访问权限"
            echo "  ${BLUE}系统管理员${NC} - 基础设施管理权限"
            echo "  ${YELLOW}开发负责人${NC} - 项目开发管理权限"
            echo "  ${PURPLE}前端开发${NC} - 前端开发权限"
            echo "  ${PURPLE}后端开发${NC} - 后端开发权限"
            echo "  ${CYAN}测试工程师${NC} - 测试环境权限"
            echo "  ${RED}访客用户${NC} - 只读访问权限"
            ;;
        "assign")
            echo -e "${YELLOW}角色分配功能待实现${NC}"
            ;;
        "permissions")
            echo -e "${YELLOW}权限查看功能待实现${NC}"
            ;;
        *)
            echo -e "${YELLOW}可用操作:${NC}"
            echo "  list        - 列出所有角色"
            echo "  assign      - 分配用户角色"
            echo "  permissions - 查看角色权限"
            ;;
    esac
}

# 权限管理
manage_permissions() {
    local action="$1"
    
    echo -e "${CYAN}=============================================================================${NC}"
    echo -e "${CYAN}                        权限管理${NC}"
    echo -e "${CYAN}=============================================================================${NC}"
    
    case "$action" in
        "check")
            echo -e "${YELLOW}权限检查:${NC}"
            execute_remote "echo 'SSH访问权限:' && ls -la ~/.ssh/ && echo '项目目录权限:' && ls -la $PROJECT_DIR/ | head -5"
            ;;
        "rbac")
            echo -e "${YELLOW}RBAC权限系统状态:${NC}"
            local rbac_status=$(execute_remote "curl -s http://localhost:8080/api/v1/rbac/check" 2>/dev/null || echo "")
            if [ -n "$rbac_status" ]; then
                echo -e "  ${GREEN}✓${NC} RBAC系统正常运行"
                echo -e "  ${BLUE}响应: $rbac_status${NC}"
            else
                echo -e "  ${RED}✗${NC} RBAC系统异常"
            fi
            ;;
        *)
            echo -e "${YELLOW}可用操作:${NC}"
            echo "  check - 检查系统权限"
            echo "  rbac  - 检查RBAC权限系统"
            ;;
    esac
}

# 访问控制
manage_access() {
    local action="$1"
    
    echo -e "${CYAN}=============================================================================${NC}"
    echo -e "${CYAN}                        访问控制${NC}"
    echo -e "${CYAN}=============================================================================${NC}"
    
    case "$action" in
        "ssh")
            echo -e "${YELLOW}SSH访问控制:${NC}"
            execute_remote "echo 'SSH配置:' && sudo grep -E '^(Port|PermitRootLogin|PasswordAuthentication)' /etc/ssh/sshd_config"
            execute_remote "echo 'SSH连接数:' && who | wc -l"
            ;;
        "ports")
            echo -e "${YELLOW}端口访问控制:${NC}"
            execute_remote "sudo netstat -tlnp | grep -E ':(22|80|443|808[0-9]|820[0-9]|850[0-9])'"
            ;;
        "firewall")
            echo -e "${YELLOW}防火墙状态:${NC}"
            execute_remote "sudo ufw status || echo '防火墙未启用'"
            ;;
        *)
            echo -e "${YELLOW}可用操作:${NC}"
            echo "  ssh      - SSH访问控制"
            echo "  ports    - 端口访问控制"
            echo "  firewall - 防火墙状态"
            ;;
    esac
}

# 系统备份管理
manage_backup() {
    local action="$1"
    
    echo -e "${CYAN}=============================================================================${NC}"
    echo -e "${CYAN}                        系统备份管理${NC}"
    echo -e "${CYAN}=============================================================================${NC}"
    
    case "$action" in
        "create")
            local backup_name="backup-$(date +%Y%m%d-%H%M%S)"
            echo -e "${YELLOW}创建系统备份: $backup_name${NC}"
            execute_remote "mkdir -p $PROJECT_DIR/backups"
            execute_remote "cd $PROJECT_DIR && tar -czf backups/$backup_name.tar.gz --exclude='*.log' --exclude='backups' --exclude='venv' ."
            execute_remote "mysqldump -u jobfirst -p'jobfirst_prod_2024' jobfirst > $PROJECT_DIR/backups/$backup_name-db.sql"
            echo -e "${GREEN}✓ 备份创建完成: $backup_name${NC}"
            ;;
        "list")
            echo -e "${YELLOW}备份列表:${NC}"
            execute_remote "ls -la $PROJECT_DIR/backups/ 2>/dev/null || echo '无备份文件'"
            ;;
        "restore")
            echo -e "${YELLOW}恢复备份功能待实现${NC}"
            ;;
        *)
            echo -e "${YELLOW}可用操作:${NC}"
            echo "  create - 创建系统备份"
            echo "  list   - 列出所有备份"
            echo "  restore - 恢复备份"
            ;;
    esac
}

# 全局部署管理
manage_deploy() {
    local action="$1"
    
    echo -e "${CYAN}=============================================================================${NC}"
    echo -e "${CYAN}                        全局部署管理${NC}"
    echo -e "${CYAN}=============================================================================${NC}"
    
    case "$action" in
        "status")
            echo -e "${YELLOW}部署状态:${NC}"
            execute_remote "echo '当前版本:' && find $PROJECT_DIR -name 'version.txt' -exec cat {} \\; 2>/dev/null || echo '无版本信息'"
            ;;
        "restart")
            echo -e "${YELLOW}重启所有服务...${NC}"
            execute_remote "cd $PROJECT_DIR && ./start-services.sh"
            echo -e "${GREEN}✓ 所有服务重启完成${NC}"
            ;;
        *)
            echo -e "${YELLOW}可用操作:${NC}"
            echo "  status  - 查看部署状态"
            echo "  restart - 重启所有服务"
            ;;
    esac
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
        
        # 系统资源
        echo -e "${YELLOW}系统资源:${NC}"
        execute_remote "echo 'CPU:' && top -bn1 | grep 'Cpu(s)' | awk '{print \$2}' && echo '内存:' && free | grep Mem | awk '{printf \"%.1f%%\", \$3/\$2 * 100.0}' && echo '磁盘:' && df -h | grep -E '^/dev/' | awk '{print \$5}' | head -1"
        
        # 服务状态
        echo -e "\n${YELLOW}关键服务:${NC}"
        local key_services=("8080:Basic Server" "8081:User Service" "8206:AI Service" "8500:Consul")
        for service in "${key_services[@]}"; do
            IFS=':' read -r port name <<< "$service"
            local is_running=$(execute_remote "sudo netstat -tlnp | grep :$port" 2>/dev/null || echo "")
            if [ -n "$is_running" ]; then
                echo -e "  ${GREEN}✓${NC} $name"
            else
                echo -e "  ${RED}✗${NC} $name"
            fi
        done
        
        sleep 5
    done
}

# 告警管理
manage_alerts() {
    echo -e "${CYAN}=============================================================================${NC}"
    echo -e "${CYAN}                        告警管理${NC}"
    echo -e "${CYAN}=============================================================================${NC}"
    
    local alerts=()
    
    # CPU使用率检查
    local cpu_usage=$(execute_remote "top -bn1 | grep 'Cpu(s)' | awk '{print \$2}' | cut -d'%' -f1" 2>/dev/null || echo "0")
    if (( $(echo "$cpu_usage > 80" | bc -l) )); then
        alerts+=("CPU使用率过高: ${cpu_usage}%")
    fi
    
    # 内存使用率检查
    local memory_usage=$(execute_remote "free | grep Mem | awk '{printf \"%.1f\", \$3/\$2 * 100.0}'" 2>/dev/null || echo "0")
    if (( $(echo "$memory_usage > 80" | bc -l) )); then
        alerts+=("内存使用率过高: ${memory_usage}%")
    fi
    
    # 磁盘使用率检查
    local disk_usage=$(execute_remote "df -h | grep -E '^/dev/' | awk '{print \$5}' | sed 's/%//' | sort -nr | head -1" 2>/dev/null || echo "0")
    if [ "$disk_usage" -gt 85 ]; then
        alerts+=("磁盘使用率过高: ${disk_usage}%")
    fi
    
    # 显示告警
    if [ ${#alerts[@]} -eq 0 ]; then
        echo -e "${GREEN}✓ 无告警信息${NC}"
    else
        echo -e "${RED}发现 ${#alerts[@]} 个告警:${NC}"
        for alert in "${alerts[@]}"; do
            echo -e "  ${RED}⚠${NC} $alert"
        done
    fi
}

# 系统日志
show_logs() {
    echo -e "${CYAN}=============================================================================${NC}"
    echo -e "${CYAN}                        系统日志${NC}"
    echo -e "${CYAN}=============================================================================${NC}"
    
    echo -e "${YELLOW}系统日志 (最近10条):${NC}"
    execute_remote "sudo journalctl -n 10 --no-pager"
    
    echo -e "\n${YELLOW}错误日志:${NC}"
    execute_remote "sudo journalctl -p err -n 5 --no-pager"
}

# 主函数
main() {
    local command="$1"
    local subcommand="$2"
    local force="false"
    local verbose="false"
    
    # 解析参数
    shift
    while [[ $# -gt 0 ]]; do
        case $1 in
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
                if [ -z "$subcommand" ]; then
                    subcommand="$1"
                fi
                shift
                ;;
        esac
    done
    
    # 执行命令
    case "$command" in
        "status")
            show_status
            ;;
        "infrastructure")
            manage_infrastructure "$subcommand"
            ;;
        "users")
            manage_users "$subcommand"
            ;;
        "roles")
            manage_roles "$subcommand"
            ;;
        "permissions")
            manage_permissions "$subcommand"
            ;;
        "access")
            manage_access "$subcommand"
            ;;
        "backup")
            manage_backup "$subcommand"
            ;;
        "deploy")
            manage_deploy "$subcommand"
            ;;
        "monitor")
            monitor_system
            ;;
        "alerts")
            manage_alerts
            ;;
        "logs")
            show_logs
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
