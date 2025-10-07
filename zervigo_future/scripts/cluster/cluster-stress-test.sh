#!/bin/bash

# Basic Server集群压力测试脚本
# 用于测试集群通讯的极限

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# 配置
BASE_PORT=9000
MAX_NODES=50  # 从50个节点开始测试
LOG_DIR="/Users/szjason72/zervi-basic/basic/logs/stress-test"
BACKEND_DIR="/Users/szjason72/zervi-basic/basic/backend"

# 创建日志目录
mkdir -p "$LOG_DIR"

# 检查系统资源
check_system_resources() {
    log_info "检查系统资源..."
    
    # 检查内存
    local free_memory=$(vm_stat | grep "Pages free" | awk '{print $3}' | sed 's/\.//')
    local page_size=16384
    local free_mb=$((free_memory * page_size / 1024 / 1024))
    
    log_info "可用内存: ${free_mb}MB"
    
    # 检查网络连接
    local max_connections=$(ulimit -n)
    log_info "最大网络连接数: ${max_connections}"
    
    # 检查CPU核心数
    local cpu_cores=$(sysctl -n hw.ncpu)
    log_info "CPU核心数: ${cpu_cores}"
    
    # 估算安全节点数
    local safe_nodes=$((free_mb / 20))  # 每个节点约20MB
    log_info "估算安全节点数: ${safe_nodes}"
    
    if [ $safe_nodes -lt $MAX_NODES ]; then
        log_warning "建议最大节点数调整为: ${safe_nodes}"
        MAX_NODES=$safe_nodes
    fi
}

# 启动单个节点
start_node() {
    local node_id=$1
    local port=$2
    
    log_info "启动节点 ${node_id} (端口 ${port})..."
    
    cd "$BACKEND_DIR/cmd/basic-server"
    
    SERVER_PORT="$port" \
    NODE_ID="stress-test-node-${node_id}" \
    CLUSTER_MANAGER_URL="http://localhost:9091" \
    ./basic-server > "$LOG_DIR/basic-server-${node_id}.log" 2>&1 &
    
    local pid=$!
    echo $pid > "$LOG_DIR/basic-server-${node_id}.pid"
    
    # 等待启动
    sleep 2
    
    # 检查是否启动成功
    if lsof -i :$port > /dev/null 2>&1; then
        log_success "节点 ${node_id} 启动成功 (PID: $pid, 端口: $port)"
        return 0
    else
        log_error "节点 ${node_id} 启动失败"
        return 1
    fi
}

# 检查节点健康状态
check_node_health() {
    local node_id=$1
    local port=$2
    
    local response=$(curl -s -w "%{http_code}" -o /dev/null "http://localhost:${port}/health" 2>/dev/null)
    
    if [ "$response" = "200" ]; then
        return 0
    else
        return 1
    fi
}

# 停止单个节点
stop_node() {
    local node_id=$1
    
    local pid_file="$LOG_DIR/basic-server-${node_id}.pid"
    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid"
            log_info "节点 ${node_id} 已停止 (PID: $pid)"
        fi
        rm -f "$pid_file"
    fi
}

# 清理所有节点
cleanup_all_nodes() {
    log_info "清理所有测试节点..."
    
    for pid_file in "$LOG_DIR"/*.pid; do
        if [ -f "$pid_file" ]; then
            local pid=$(cat "$pid_file")
            if kill -0 "$pid" 2>/dev/null; then
                kill "$pid" 2>/dev/null || true
            fi
            rm -f "$pid_file"
        fi
    done
    
    # 清理日志文件
    rm -f "$LOG_DIR"/*.log
    
    log_success "所有测试节点已清理"
}

# 压力测试
stress_test() {
    log_info "开始集群压力测试..."
    log_info "目标节点数: ${MAX_NODES}"
    
    local success_count=0
    local failed_count=0
    local start_time=$(date +%s)
    
    for i in $(seq 1 $MAX_NODES); do
        local port=$((BASE_PORT + i))
        
        if start_node "$i" "$port"; then
            success_count=$((success_count + 1))
            
            # 每10个节点检查一次系统状态
            if [ $((i % 10)) -eq 0 ]; then
                log_info "已启动 ${i} 个节点，成功: ${success_count}, 失败: ${failed_count}"
                
                # 检查系统资源使用
                local memory_usage=$(ps aux | grep basic-server | grep -v grep | awk '{sum+=$6} END {print sum/1024}')
                log_info "当前内存使用: ${memory_usage}MB"
            fi
        else
            failed_count=$((failed_count + 1))
            log_error "节点 ${i} 启动失败，停止测试"
            break
        fi
        
        # 短暂延迟
        sleep 0.5
    done
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    log_info "压力测试完成"
    log_info "总耗时: ${duration}秒"
    log_info "成功启动: ${success_count} 个节点"
    log_info "启动失败: ${failed_count} 个节点"
    
    # 健康检查
    log_info "进行健康检查..."
    local healthy_count=0
    for i in $(seq 1 $success_count); do
        local port=$((BASE_PORT + i))
        if check_node_health "$i" "$port"; then
            healthy_count=$((healthy_count + 1))
        fi
    done
    
    log_info "健康节点数: ${healthy_count}/${success_count}"
    
    # 生成测试报告
    generate_report "$success_count" "$failed_count" "$healthy_count" "$duration"
}

# 生成测试报告
generate_report() {
    local success_count=$1
    local failed_count=$2
    local healthy_count=$3
    local duration=$4
    
    local report_file="$LOG_DIR/stress-test-report-$(date +%Y%m%d-%H%M%S).txt"
    
    cat > "$report_file" << EOF
Basic Server集群压力测试报告
============================

测试时间: $(date)
测试目标: ${MAX_NODES} 个节点
实际启动: ${success_count} 个节点
启动失败: ${failed_count} 个节点
健康节点: ${healthy_count} 个节点
测试耗时: ${duration} 秒

系统资源:
- 可用内存: $(vm_stat | grep "Pages free" | awk '{print $3}' | sed 's/\.//') * 16KB
- 最大连接数: $(ulimit -n)
- CPU核心数: $(sysctl -n hw.ncpu)

结论:
- 集群通讯极限: ${success_count} 个节点
- 健康率: $((healthy_count * 100 / success_count))%
- 建议生产环境节点数: $((success_count / 2))

EOF
    
    log_success "测试报告已生成: $report_file"
}

# 主函数
main() {
    log_info "Basic Server集群压力测试开始"
    
    # 检查系统资源
    check_system_resources
    
    # 清理之前的测试
    cleanup_all_nodes
    
    # 开始压力测试
    stress_test
    
    # 等待用户确认是否清理
    echo
    read -p "是否清理所有测试节点? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cleanup_all_nodes
    else
        log_info "测试节点保持运行，可手动清理"
    fi
    
    log_success "压力测试完成"
}

# 信号处理
trap cleanup_all_nodes EXIT INT TERM

# 运行主函数
main "$@"
