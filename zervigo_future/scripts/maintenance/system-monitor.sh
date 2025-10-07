#!/bin/bash

# =============================================================================
# 系统监控脚本
# 用于监控腾讯云服务器的系统状态和性能
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

# 监控配置
CPU_THRESHOLD=80
MEMORY_THRESHOLD=80
DISK_THRESHOLD=85
ALERT_EMAIL="admin@jobfirst.com"

# 显示帮助信息
show_help() {
    echo -e "${CYAN}=============================================================================${NC}"
    echo -e "${CYAN}                        系统监控脚本${NC}"
    echo -e "${CYAN}=============================================================================${NC}"
    echo ""
    echo -e "${YELLOW}用法:${NC}"
    echo "  $0 [命令] [选项]"
    echo ""
    echo -e "${YELLOW}命令:${NC}"
    echo "  status          - 显示系统状态概览"
    echo "  resources       - 显示系统资源使用情况"
    echo "  services        - 显示服务状态"
    echo "  logs            - 显示系统日志"
    echo "  alerts          - 显示告警信息"
    echo "  performance     - 显示性能指标"
    echo "  realtime        - 实时监控"
    echo "  report          - 生成监控报告"
    echo "  check           - 执行健康检查"
    echo ""
    echo -e "${YELLOW}选项:${NC}"
    echo "  -i, --interval  监控间隔(秒)"
    echo "  -t, --threshold 设置阈值"
    echo "  -f, --format    输出格式(json/text)"
    echo "  -h, --help      显示帮助信息"
    echo ""
    echo -e "${YELLOW}示例:${NC}"
    echo "  $0 status                    # 显示系统状态"
    echo "  $0 realtime -i 5             # 每5秒实时监控"
    echo "  $0 performance -f json       # JSON格式性能数据"
    echo "  $0 report                    # 生成监控报告"
    echo ""
}

# 执行远程命令
execute_remote() {
    local cmd="$1"
    local format="${2:-text}"
    
    if [ "$format" = "json" ]; then
        ssh -i "$SSH_KEY" "$SERVER_USER@$SERVER_IP" "$cmd" | jq . 2>/dev/null || ssh -i "$SSH_KEY" "$SERVER_USER@$SERVER_IP" "$cmd"
    else
        ssh -i "$SSH_KEY" "$SERVER_USER@$SERVER_IP" "$cmd"
    fi
}

# 显示系统状态概览
show_status() {
    echo -e "${CYAN}=============================================================================${NC}"
    echo -e "${CYAN}                        系统状态概览${NC}"
    echo -e "${CYAN}=============================================================================${NC}"
    
    # 系统信息
    echo -e "\n${YELLOW}系统信息:${NC}"
    execute_remote "echo '主机名:' && hostname && echo '操作系统:' && uname -a && echo '运行时间:' && uptime"
    
    # 系统资源
    echo -e "\n${YELLOW}系统资源:${NC}"
    execute_remote "echo '内存使用:' && free -h && echo '磁盘使用:' && df -h | grep -E '^/dev/'"
    
    # 网络状态
    echo -e "\n${YELLOW}网络状态:${NC}"
    execute_remote "echo '网络接口:' && ip addr show | grep -E '^[0-9]+:|inet ' && echo '监听端口:' && sudo netstat -tlnp | grep -E ':(8080|8081|8206|8500|22|80|443)'"
    
    # 服务状态
    echo -e "\n${YELLOW}服务状态:${NC}"
    execute_remote "echo '基础设施服务:' && sudo systemctl is-active mysql redis-server postgresql nginx && echo '应用服务:' && ps aux | grep -E '(basic-server|user-service|ai-service|consul)' | grep -v grep | wc -l && echo '个服务运行中'"
}

# 显示系统资源使用情况
show_resources() {
    echo -e "${CYAN}=============================================================================${NC}"
    echo -e "${CYAN}                        系统资源使用情况${NC}"
    echo -e "${CYAN}=============================================================================${NC}"
    
    # CPU使用率
    echo -e "\n${YELLOW}CPU使用率:${NC}"
    execute_remote "top -bn1 | grep 'Cpu(s)' | awk '{print \$2}' | cut -d'%' -f1"
    
    # 内存使用情况
    echo -e "\n${YELLOW}内存使用情况:${NC}"
    execute_remote "free -h && echo '内存使用率:' && free | grep Mem | awk '{printf \"%.1f%%\", \$3/\$2 * 100.0}'"
    
    # 磁盘使用情况
    echo -e "\n${YELLOW}磁盘使用情况:${NC}"
    execute_remote "df -h | grep -E '^/dev/' && echo '磁盘使用率:' && df -h | grep -E '^/dev/' | awk '{print \$5}' | sed 's/%//' | sort -nr | head -1"
    
    # 网络流量
    echo -e "\n${YELLOW}网络流量:${NC}"
    execute_remote "cat /proc/net/dev | grep -E '(eth0|ens)' | awk '{print \"接收:\", \$2/1024/1024 \"MB, 发送:\", \$10/1024/1024 \"MB\"}'"
    
    # 进程资源使用
    echo -e "\n${YELLOW}进程资源使用 (Top 10):${NC}"
    execute_remote "ps aux --sort=-%cpu | head -11"
}

# 显示服务状态
show_services() {
    echo -e "${CYAN}=============================================================================${NC}"
    echo -e "${CYAN}                        服务状态监控${NC}"
    echo -e "${CYAN}=============================================================================${NC}"
    
    # 基础设施服务
    echo -e "\n${YELLOW}基础设施服务:${NC}"
    local infra_services=("mysql" "redis-server" "postgresql" "nginx")
    for service in "${infra_services[@]}"; do
        local status=$(execute_remote "sudo systemctl is-active $service" 2>/dev/null || echo "inactive")
        local memory=$(execute_remote "ps aux | grep $service | grep -v grep | awk '{sum+=\$6} END {print sum/1024 \"MB\"}'" 2>/dev/null || echo "0MB")
        if [ "$status" = "active" ]; then
            echo -e "  ${GREEN}✓${NC} $service - ${GREEN}运行中${NC} (内存: $memory)"
        else
            echo -e "  ${RED}✗${NC} $service - ${RED}未运行${NC}"
        fi
    done
    
    # 应用服务
    echo -e "\n${YELLOW}应用服务:${NC}"
    local app_services=("basic-server:8080" "user-service:8081" "ai-service:8206" "consul:8500")
    for service in "${app_services[@]}"; do
        IFS=':' read -r name port <<< "$service"
        local is_running=$(execute_remote "sudo netstat -tlnp | grep :$port" 2>/dev/null || echo "")
        local memory=$(execute_remote "ps aux | grep $name | grep -v grep | awk '{sum+=\$6} END {print sum/1024 \"MB\"}'" 2>/dev/null || echo "0MB")
        if [ -n "$is_running" ]; then
            echo -e "  ${GREEN}✓${NC} $name - ${GREEN}运行中${NC} (端口:$port, 内存: $memory)"
        else
            echo -e "  ${RED}✗${NC} $name - ${RED}未运行${NC} (端口:$port)"
        fi
    done
    
    # 健康检查
    echo -e "\n${YELLOW}健康检查:${NC}"
    local health_ports=("8080" "8081" "8206")
    for port in "${health_ports[@]}"; do
        local health_url="http://localhost:$port/health"
        local health_status=$(execute_remote "curl -s -w '%{http_code}' $health_url" 2>/dev/null || echo "000")
        if [ "$health_status" = "200" ]; then
            echo -e "  ${GREEN}✓${NC} 端口 $port - ${GREEN}健康${NC}"
        else
            echo -e "  ${RED}✗${NC} 端口 $port - ${RED}不健康${NC}"
        fi
    done
}

# 显示系统日志
show_logs() {
    echo -e "${CYAN}=============================================================================${NC}"
    echo -e "${CYAN}                        系统日志监控${NC}"
    echo -e "${CYAN}=============================================================================${NC}"
    
    # 系统日志
    echo -e "\n${YELLOW}系统日志 (最近10条):${NC}"
    execute_remote "sudo journalctl -n 10 --no-pager"
    
    # 应用日志
    echo -e "\n${YELLOW}应用日志:${NC}"
    local app_services=("basic-server" "user-service" "ai-service" "consul")
    for service in "${app_services[@]}"; do
        echo -e "\n${BLUE}=== $service 日志 ===${NC}"
        execute_remote "cd $PROJECT_DIR/$service && tail -5 $service.log 2>/dev/null || echo '日志文件不存在'"
    done
    
    # 错误日志
    echo -e "\n${YELLOW}错误日志:${NC}"
    execute_remote "sudo journalctl -p err -n 5 --no-pager"
}

# 显示告警信息
show_alerts() {
    echo -e "${CYAN}=============================================================================${NC}"
    echo -e "${CYAN}                        告警信息${NC}"
    echo -e "${CYAN}=============================================================================${NC}"
    
    local alerts=()
    
    # CPU使用率检查
    local cpu_usage=$(execute_remote "top -bn1 | grep 'Cpu(s)' | awk '{print \$2}' | cut -d'%' -f1" 2>/dev/null || echo "0")
    if (( $(echo "$cpu_usage > $CPU_THRESHOLD" | bc -l) )); then
        alerts+=("CPU使用率过高: ${cpu_usage}% (阈值: ${CPU_THRESHOLD}%)")
    fi
    
    # 内存使用率检查
    local memory_usage=$(execute_remote "free | grep Mem | awk '{printf \"%.1f\", \$3/\$2 * 100.0}'" 2>/dev/null || echo "0")
    if (( $(echo "$memory_usage > $MEMORY_THRESHOLD" | bc -l) )); then
        alerts+=("内存使用率过高: ${memory_usage}% (阈值: ${MEMORY_THRESHOLD}%)")
    fi
    
    # 磁盘使用率检查
    local disk_usage=$(execute_remote "df -h | grep -E '^/dev/' | awk '{print \$5}' | sed 's/%//' | sort -nr | head -1" 2>/dev/null || echo "0")
    if [ "$disk_usage" -gt "$DISK_THRESHOLD" ]; then
        alerts+=("磁盘使用率过高: ${disk_usage}% (阈值: ${DISK_THRESHOLD}%)")
    fi
    
    # 服务状态检查
    local app_services=("basic-server:8080" "user-service:8081" "ai-service:8206" "consul:8500")
    for service in "${app_services[@]}"; do
        IFS=':' read -r name port <<< "$service"
        local is_running=$(execute_remote "sudo netstat -tlnp | grep :$port" 2>/dev/null || echo "")
        if [ -z "$is_running" ]; then
            alerts+=("服务 $name 未运行 (端口: $port)")
        fi
    done
    
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

# 显示性能指标
show_performance() {
    echo -e "${CYAN}=============================================================================${NC}"
    echo -e "${CYAN}                        性能指标${NC}"
    echo -e "${CYAN}=============================================================================${NC}"
    
    # 系统负载
    echo -e "\n${YELLOW}系统负载:${NC}"
    execute_remote "uptime && echo '负载平均值:' && cat /proc/loadavg"
    
    # 进程统计
    echo -e "\n${YELLOW}进程统计:${NC}"
    execute_remote "echo '总进程数:' && ps aux | wc -l && echo '运行中进程:' && ps aux | grep -v '\[.*\]' | wc -l"
    
    # 网络连接
    echo -e "\n${YELLOW}网络连接:${NC}"
    execute_remote "echo 'TCP连接数:' && ss -t | wc -l && echo 'UDP连接数:' && ss -u | wc -l"
    
    # 文件描述符
    echo -e "\n${YELLOW}文件描述符:${NC}"
    execute_remote "echo '已使用:' && cat /proc/sys/fs/file-nr | awk '{print \$1}' && echo '最大限制:' && cat /proc/sys/fs/file-max"
    
    # 内存统计
    echo -e "\n${YELLOW}内存统计:${NC}"
    execute_remote "cat /proc/meminfo | grep -E '(MemTotal|MemFree|MemAvailable|Buffers|Cached)'"
}

# 实时监控
realtime_monitor() {
    local interval="${1:-5}"
    
    echo -e "${CYAN}=============================================================================${NC}"
    echo -e "${CYAN}                        实时监控${NC}"
    echo -e "${CYAN}=============================================================================${NC}"
    echo -e "${YELLOW}监控间隔: ${interval}秒${NC}"
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
        echo -e "\n${YELLOW}服务状态:${NC}"
        local app_services=("basic-server:8080" "user-service:8081" "ai-service:8206" "consul:8500")
        for service in "${app_services[@]}"; do
            IFS=':' read -r name port <<< "$service"
            local is_running=$(execute_remote "sudo netstat -tlnp | grep :$port" 2>/dev/null || echo "")
            if [ -n "$is_running" ]; then
                echo -e "  ${GREEN}✓${NC} $name (端口:$port)"
            else
                echo -e "  ${RED}✗${NC} $name (端口:$port)"
            fi
        done
        
        # 告警信息
        echo -e "\n${YELLOW}告警信息:${NC}"
        local alerts=()
        local cpu_usage=$(execute_remote "top -bn1 | grep 'Cpu(s)' | awk '{print \$2}' | cut -d'%' -f1" 2>/dev/null || echo "0")
        if (( $(echo "$cpu_usage > $CPU_THRESHOLD" | bc -l) )); then
            alerts+=("CPU: ${cpu_usage}%")
        fi
        local memory_usage=$(execute_remote "free | grep Mem | awk '{printf \"%.1f\", \$3/\$2 * 100.0}'" 2>/dev/null || echo "0")
        if (( $(echo "$memory_usage > $MEMORY_THRESHOLD" | bc -l) )); then
            alerts+=("内存: ${memory_usage}%")
        fi
        
        if [ ${#alerts[@]} -eq 0 ]; then
            echo -e "  ${GREEN}✓ 无告警${NC}"
        else
            for alert in "${alerts[@]}"; do
                echo -e "  ${RED}⚠ $alert${NC}"
            done
        fi
        
        sleep "$interval"
    done
}

# 生成监控报告
generate_report() {
    echo -e "${CYAN}=============================================================================${NC}"
    echo -e "${CYAN}                        监控报告${NC}"
    echo -e "${CYAN}=============================================================================${NC}"
    
    local report_file="monitor-report-$(date +%Y%m%d-%H%M%S).txt"
    
    {
        echo "监控报告生成时间: $(date)"
        echo "服务器: $SERVER_USER@$SERVER_IP"
        echo "========================================"
        echo ""
        
        echo "系统信息:"
        execute_remote "hostname && uname -a && uptime"
        echo ""
        
        echo "系统资源:"
        execute_remote "free -h && df -h | grep -E '^/dev/'"
        echo ""
        
        echo "服务状态:"
        execute_remote "sudo systemctl is-active mysql redis-server postgresql nginx"
        execute_remote "sudo netstat -tlnp | grep -E ':(8080|8081|8206|8500)'"
        echo ""
        
        echo "性能指标:"
        execute_remote "top -bn1 | grep 'Cpu(s)' && free | grep Mem | awk '{printf \"内存使用率: %.1f%%\", \$3/\$2 * 100.0}'"
        echo ""
        
        echo "告警信息:"
        show_alerts
        echo ""
        
    } > "$report_file"
    
    echo -e "${GREEN}监控报告已生成: $report_file${NC}"
}

# 执行健康检查
health_check() {
    echo -e "${CYAN}=============================================================================${NC}"
    echo -e "${CYAN}                        健康检查${NC}"
    echo -e "${CYAN}=============================================================================${NC}"
    
    local health_score=0
    local total_checks=0
    
    # 系统资源检查
    echo -e "\n${YELLOW}系统资源检查:${NC}"
    total_checks=$((total_checks + 3))
    
    local cpu_usage=$(execute_remote "top -bn1 | grep 'Cpu(s)' | awk '{print \$2}' | cut -d'%' -f1" 2>/dev/null || echo "0")
    if (( $(echo "$cpu_usage < $CPU_THRESHOLD" | bc -l) )); then
        echo -e "  ${GREEN}✓${NC} CPU使用率正常: ${cpu_usage}%"
        health_score=$((health_score + 1))
    else
        echo -e "  ${RED}✗${NC} CPU使用率过高: ${cpu_usage}%"
    fi
    
    local memory_usage=$(execute_remote "free | grep Mem | awk '{printf \"%.1f\", \$3/\$2 * 100.0}'" 2>/dev/null || echo "0")
    if (( $(echo "$memory_usage < $MEMORY_THRESHOLD" | bc -l) )); then
        echo -e "  ${GREEN}✓${NC} 内存使用率正常: ${memory_usage}%"
        health_score=$((health_score + 1))
    else
        echo -e "  ${RED}✗${NC} 内存使用率过高: ${memory_usage}%"
    fi
    
    local disk_usage=$(execute_remote "df -h | grep -E '^/dev/' | awk '{print \$5}' | sed 's/%//' | sort -nr | head -1" 2>/dev/null || echo "0")
    if [ "$disk_usage" -lt "$DISK_THRESHOLD" ]; then
        echo -e "  ${GREEN}✓${NC} 磁盘使用率正常: ${disk_usage}%"
        health_score=$((health_score + 1))
    else
        echo -e "  ${RED}✗${NC} 磁盘使用率过高: ${disk_usage}%"
    fi
    
    # 服务状态检查
    echo -e "\n${YELLOW}服务状态检查:${NC}"
    local app_services=("basic-server:8080" "user-service:8081" "ai-service:8206" "consul:8500")
    for service in "${app_services[@]}"; do
        IFS=':' read -r name port <<< "$service"
        total_checks=$((total_checks + 1))
        local is_running=$(execute_remote "sudo netstat -tlnp | grep :$port" 2>/dev/null || echo "")
        if [ -n "$is_running" ]; then
            echo -e "  ${GREEN}✓${NC} $name 运行正常 (端口:$port)"
            health_score=$((health_score + 1))
        else
            echo -e "  ${RED}✗${NC} $name 未运行 (端口:$port)"
        fi
    done
    
    # 健康评分
    local health_percentage=$((health_score * 100 / total_checks))
    echo -e "\n${YELLOW}健康评分:${NC}"
    echo -e "  检查项目: $total_checks"
    echo -e "  通过项目: $health_score"
    echo -e "  健康评分: $health_percentage%"
    
    if [ "$health_percentage" -ge 90 ]; then
        echo -e "  ${GREEN}✓ 系统健康状态: 优秀${NC}"
    elif [ "$health_percentage" -ge 70 ]; then
        echo -e "  ${YELLOW}⚠ 系统健康状态: 良好${NC}"
    else
        echo -e "  ${RED}✗ 系统健康状态: 需要关注${NC}"
    fi
}

# 主函数
main() {
    local command="$1"
    local interval="5"
    local format="text"
    
    # 解析参数
    shift
    while [[ $# -gt 0 ]]; do
        case $1 in
            -i|--interval)
                interval="$2"
                shift 2
                ;;
            -f|--format)
                format="$2"
                shift 2
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
        "resources")
            show_resources
            ;;
        "services")
            show_services
            ;;
        "logs")
            show_logs
            ;;
        "alerts")
            show_alerts
            ;;
        "performance")
            show_performance
            ;;
        "realtime")
            realtime_monitor "$interval"
            ;;
        "report")
            generate_report
            ;;
        "check")
            health_check
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
