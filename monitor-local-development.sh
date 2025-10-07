#!/bin/bash
# 本地开发环境监控脚本

echo "📊 本地开发环境监控"
echo "=================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 检查服务状态
check_service_status() {
    local name=$1
    local url=$2
    
    if curl -f -s "$url" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ $name${NC}"
        return 0
    else
        echo -e "${RED}❌ $name${NC}"
        return 1
    fi
}

# 检查容器状态
check_container_status() {
    local container_name=$1
    local status=$(docker ps --filter "name=$container_name" --format "{{.Status}}" 2>/dev/null)
    
    if [ -n "$status" ]; then
        if [[ "$status" == *"Up"* ]]; then
            echo -e "${GREEN}✅ $container_name: $status${NC}"
        else
            echo -e "${RED}❌ $container_name: $status${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  $container_name: 未运行${NC}"
    fi
}

# 显示系统资源
show_system_resources() {
    echo -e "${BLUE}📈 系统资源使用情况${NC}"
    echo "=================="
    
    # 内存使用情况 (macOS)
    if command -v vm_stat >/dev/null 2>&1; then
        echo -e "${CYAN}💾 内存使用情况：${NC}"
        vm_stat | grep -E "(Pages free|Pages active|Pages inactive)" | while read line; do
            echo "  $line"
        done
    fi
    
    # 磁盘使用情况
    echo -e "${CYAN}💿 磁盘使用情况：${NC}"
    df -h / | awk 'NR==2{printf "  使用率: %s (%s/%s)\n", $5, $3, $2}'
    
    # CPU使用情况
    echo -e "${CYAN}🖥️  CPU使用情况：${NC}"
    top -l 1 | grep "CPU usage" | awk '{printf "  用户: %s, 系统: %s, 空闲: %s\n", $3, $5, $7}'
}

# 显示Docker容器状态
show_docker_status() {
    echo -e "${BLUE}🐳 Docker容器状态${NC}"
    echo "=================="
    
    # 显示相关容器
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(future|looma|zervigo|jobfirst)" | while read line; do
        echo "  $line"
    done
    
    # 显示容器数量
    local container_count=$(docker ps --filter "name=future-" --filter "name=looma-" --filter "name=zervigo-" --filter "name=jobfirst-" --format "{{.Names}}" | wc -l)
    echo -e "${CYAN}容器总数: $container_count${NC}"
}

# 显示服务健康状态
show_service_health() {
    echo -e "${BLUE}🏥 服务健康状态${NC}"
    echo "=================="
    
    echo -e "${CYAN}核心服务：${NC}"
    check_service_status "LoomaCRM Future" "http://localhost:7500/health"
    check_service_status "AI网关服务" "http://localhost:7510/health"
    check_service_status "简历AI服务" "http://localhost:7511/health"
    check_service_status "MinerU服务" "http://localhost:8000/health"
    check_service_status "AI模型服务" "http://localhost:8002/health"
    check_service_status "JobFirst AI服务" "http://localhost:7540/health"
    
    echo -e "${CYAN}数据库服务：${NC}"
    check_container_status "future-postgres"
    check_container_status "future-mongodb"
    check_container_status "future-redis"
    check_container_status "future-neo4j"
    check_container_status "future-elasticsearch"
    
    echo -e "${CYAN}监控服务：${NC}"
    check_container_status "future-prometheus"
    check_container_status "future-grafana"
}

# 显示网络连接
show_network_status() {
    echo -e "${BLUE}🌐 网络连接状态${NC}"
    echo "=================="
    
    # 检查端口监听
    echo -e "${CYAN}端口监听情况：${NC}"
    local ports=("7500" "7510" "7511" "8000" "8002" "7540" "9091" "3001")
    
    for port in "${ports[@]}"; do
        if lsof -i ":$port" >/dev/null 2>&1; then
            echo -e "${GREEN}  ✅ 端口 $port: 正在监听${NC}"
        else
            echo -e "${RED}  ❌ 端口 $port: 未监听${NC}"
        fi
    done
}

# 显示访问地址
show_access_urls() {
    echo -e "${BLUE}🔗 服务访问地址${NC}"
    echo "=================="
    
    echo -e "${CYAN}应用服务：${NC}"
    echo "  📊 LoomaCRM Future: http://localhost:7500"
    echo "  🤖 AI网关服务: http://localhost:7510"
    echo "  📄 简历AI服务: http://localhost:7511"
    echo "  🔍 MinerU服务: http://localhost:8000"
    echo "  🧠 AI模型服务: http://localhost:8002"
    echo "  💼 JobFirst AI服务: http://localhost:7540"
    
    echo -e "${CYAN}监控服务：${NC}"
    echo "  📈 Prometheus: http://localhost:9091"
    echo "  📊 Grafana: http://localhost:3001"
    
    echo -e "${CYAN}数据库服务：${NC}"
    echo "  🐘 PostgreSQL: localhost:5434"
    echo "  🍃 MongoDB: localhost:27018"
    echo "  🔴 Redis: localhost:6382"
    echo "  🔗 Neo4j: http://localhost:7474"
    echo "  🔍 Elasticsearch: http://localhost:9202"
}

# 实时监控模式
real_time_monitor() {
    echo -e "${BLUE}🔄 实时监控模式 (按 Ctrl+C 退出)${NC}"
    echo "=================="
    
    while true; do
        clear
        echo -e "${BLUE}📊 本地开发环境实时监控${NC}"
        echo "=================="
        echo "时间: $(date '+%Y-%m-%d %H:%M:%S')"
        echo ""
        
        show_docker_status
        echo ""
        show_service_health
        echo ""
        show_system_resources
        echo ""
        
        echo -e "${YELLOW}按 Ctrl+C 退出监控${NC}"
        sleep 5
    done
}

# 生成监控报告
generate_report() {
    local report_file="/tmp/local-development-monitor-report-$(date +%Y%m%d_%H%M%S).txt"
    
    echo "本地开发环境监控报告" > "$report_file"
    echo "生成时间: $(date '+%Y-%m-%d %H:%M:%S')" >> "$report_file"
    echo "==================" >> "$report_file"
    echo "" >> "$report_file"
    
    echo "Docker容器状态:" >> "$report_file"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(future|looma|zervigo|jobfirst)" >> "$report_file"
    echo "" >> "$report_file"
    
    echo "系统资源使用:" >> "$report_file"
    if command -v vm_stat >/dev/null 2>&1; then
        vm_stat >> "$report_file"
    fi
    df -h / >> "$report_file"
    echo "" >> "$report_file"
    
    echo "网络连接状态:" >> "$report_file"
    lsof -i :7500 >> "$report_file" 2>/dev/null || echo "端口 7500: 未监听" >> "$report_file"
    lsof -i :7510 >> "$report_file" 2>/dev/null || echo "端口 7510: 未监听" >> "$report_file"
    lsof -i :7511 >> "$report_file" 2>/dev/null || echo "端口 7511: 未监听" >> "$report_file"
    
    echo -e "${GREEN}📄 监控报告已保存到: $report_file${NC}"
}

# 主函数
main() {
    case "${1:-status}" in
        "status")
            show_docker_status
            echo ""
            show_service_health
            echo ""
            show_network_status
            echo ""
            show_access_urls
            ;;
        "real-time"|"rt")
            real_time_monitor
            ;;
        "report")
            generate_report
            ;;
        "resources")
            show_system_resources
            ;;
        "containers")
            show_docker_status
            ;;
        "services")
            show_service_health
            ;;
        "network")
            show_network_status
            ;;
        "urls")
            show_access_urls
            ;;
        "help"|"-h"|"--help")
            echo "用法: $0 [选项]"
            echo ""
            echo "选项:"
            echo "  status     显示完整状态 (默认)"
            echo "  real-time  实时监控模式"
            echo "  rt         实时监控模式 (简写)"
            echo "  report     生成监控报告"
            echo "  resources  显示系统资源"
            echo "  containers 显示容器状态"
            echo "  services   显示服务健康状态"
            echo "  network    显示网络状态"
            echo "  urls       显示访问地址"
            echo "  help       显示帮助信息"
            ;;
        *)
            echo -e "${RED}❌ 未知选项: $1${NC}"
            echo "使用 '$0 help' 查看帮助信息"
            exit 1
            ;;
    esac
}

# 运行主函数
main "$@"
