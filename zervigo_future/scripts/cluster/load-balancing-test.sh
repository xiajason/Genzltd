#!/bin/bash

# Basic Server集群负载均衡测试脚本
# 用于测试集群节点的负载均衡功能

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
NODES=("8080" "8180" "8280")
NODE_NAMES=("主系统" "集群节点1" "集群节点2")
TEST_REQUESTS=50
CONCURRENT_REQUESTS=10

# 临时文件存储测试数据
TEMP_DIR="/tmp/load_balance_test_$$"
mkdir -p "$TEMP_DIR"

# 初始化计数器文件
init_counters() {
    for node in "${NODES[@]}"; do
        echo "0" > "$TEMP_DIR/requests_$node"
        echo "0" > "$TEMP_DIR/success_$node"
        echo "0" > "$TEMP_DIR/errors_$node"
        echo "0" > "$TEMP_DIR/response_time_$node"
    done
}

# 获取计数器值
get_counter() {
    local node=$1
    local type=$2
    cat "$TEMP_DIR/${type}_$node"
}

# 增加计数器值
increment_counter() {
    local node=$1
    local type=$2
    local current=$(get_counter "$node" "$type")
    echo $((current + 1)) > "$TEMP_DIR/${type}_$node"
}

# 增加响应时间
add_response_time() {
    local node=$1
    local time=$2
    local current=$(get_counter "$node" "response_time")
    echo $((current + time)) > "$TEMP_DIR/response_time_$node"
}

# 检查节点健康状态
check_node_health() {
    local port=$1
    local response=$(curl -s -w "%{http_code}" -o /dev/null "http://localhost:${port}/health" 2>/dev/null)
    
    if [ "$response" = "200" ]; then
        return 0
    else
        return 1
    fi
}

# 发送请求到指定节点
send_request() {
    local port=$1
    local request_id=$2
    
    local start_time=$(date +%s)
    local response=$(curl -s -w "%{http_code}" -o /dev/null "http://localhost:${port}/api/v1/cluster/status" 2>/dev/null)
    local end_time=$(date +%s)
    local response_time=$((end_time - start_time))
    
    increment_counter "$port" "requests"
    
    if [ "$response" = "200" ]; then
        increment_counter "$port" "success"
        add_response_time "$port" "$response_time"
        echo "✅ 请求 $request_id -> 端口 $port: 成功 (${response_time}ms)"
    else
        increment_counter "$port" "errors"
        echo "❌ 请求 $request_id -> 端口 $port: 失败 (HTTP $response)"
    fi
}

# 轮询负载均衡测试
test_round_robin() {
    log_info "开始轮询负载均衡测试..."
    
    local node_index=0
    for i in $(seq 1 $TEST_REQUESTS); do
        local port=${NODES[$node_index]}
        send_request "$port" "$i"
        
        # 轮询到下一个节点
        node_index=$(((node_index + 1) % ${#NODES[@]}))
        
        # 每10个请求显示进度
        if [ $((i % 10)) -eq 0 ]; then
            log_info "已完成 $i/$TEST_REQUESTS 个请求"
        fi
        
        # 短暂延迟
        sleep 0.1
    done
}

# 随机负载均衡测试
test_random() {
    log_info "开始随机负载均衡测试..."
    
    for i in $(seq 1 $TEST_REQUESTS); do
        local random_index=$((RANDOM % ${#NODES[@]}))
        local port=${NODES[$random_index]}
        send_request "$port" "$i"
        
        # 每10个请求显示进度
        if [ $((i % 10)) -eq 0 ]; then
            log_info "已完成 $i/$TEST_REQUESTS 个请求"
        fi
        
        # 短暂延迟
        sleep 0.1
    done
}

# 并发负载均衡测试
test_concurrent() {
    log_info "开始并发负载均衡测试..."
    
    local pids=()
    
    for i in $(seq 1 $CONCURRENT_REQUESTS); do
        local random_index=$((RANDOM % ${#NODES[@]}))
        local port=${NODES[$random_index]}
        
        # 后台发送请求
        send_request "$port" "$i" &
        pids+=($!)
        
        # 短暂延迟
        sleep 0.05
    done
    
    # 等待所有请求完成
    for pid in "${pids[@]}"; do
        wait $pid
    done
}

# 计算负载均衡效果
calculate_load_balance() {
    log_info "计算负载均衡效果..."
    
    echo
    echo "=== 负载均衡测试结果 ==="
    echo "总请求数: $TEST_REQUESTS"
    echo
    
    local total_requests=0
    local total_successes=0
    local total_errors=0
    
    for i in "${!NODES[@]}"; do
        local port=${NODES[$i]}
        local name=${NODE_NAMES[$i]}
        local requests=$(get_counter "$port" "requests")
        local successes=$(get_counter "$port" "success")
        local errors=$(get_counter "$port" "errors")
        local total_time=$(get_counter "$port" "response_time")
        
        total_requests=$((total_requests + requests))
        total_successes=$((total_successes + successes))
        total_errors=$((total_errors + errors))
        
        local success_rate=0
        local avg_response_time=0
        
        if [ $requests -gt 0 ]; then
            success_rate=$((successes * 100 / requests))
        fi
        
        if [ $successes -gt 0 ]; then
            avg_response_time=$((total_time / successes))
        fi
        
        echo "节点: $name (端口 $port)"
        echo "  请求数: $requests"
        echo "  成功数: $successes"
        echo "  失败数: $errors"
        echo "  成功率: ${success_rate}%"
        echo "  平均响应时间: ${avg_response_time}ms"
        echo
    done
    
    # 计算负载均衡偏差
    local expected_per_node=$((total_requests / ${#NODES[@]}))
    local max_deviation=0
    
    for port in "${NODES[@]}"; do
        local requests=$(get_counter "$port" "requests")
        local deviation=$(((requests - expected_per_node) * 100 / expected_per_node))
        local abs_deviation=${deviation#-}
        if [ $abs_deviation -gt $max_deviation ]; then
            max_deviation=$abs_deviation
        fi
    done
    
    echo "=== 负载均衡分析 ==="
    echo "总请求数: $total_requests"
    echo "总成功数: $total_successes"
    echo "总失败数: $total_errors"
    echo "期望每节点请求数: $expected_per_node"
    echo "最大偏差: ${max_deviation}%"
    
    if [ $max_deviation -lt 10 ]; then
        log_success "负载均衡效果: 优秀 (偏差 < 10%)"
    elif [ $max_deviation -lt 20 ]; then
        log_warning "负载均衡效果: 良好 (偏差 < 20%)"
    else
        log_error "负载均衡效果: 需要优化 (偏差 >= 20%)"
    fi
}

# 性能压力测试
performance_test() {
    log_info "开始性能压力测试..."
    
    local start_time=$(date +%s)
    
    # 发送大量并发请求
    for i in $(seq 1 30); do
        local random_index=$((RANDOM % ${#NODES[@]}))
        local port=${NODES[$random_index]}
        
        curl -s "http://localhost:${port}/api/v1/cluster/status" > /dev/null &
        
        if [ $((i % 10)) -eq 0 ]; then
            wait  # 等待一批请求完成
        fi
    done
    
    wait  # 等待所有请求完成
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    log_info "性能测试完成，耗时: ${duration}秒"
}

# 清理临时文件
cleanup() {
    rm -rf "$TEMP_DIR"
}

# 主函数
main() {
    log_info "Basic Server集群负载均衡测试开始"
    
    # 设置清理陷阱
    trap cleanup EXIT
    
    # 初始化计数器
    init_counters
    
    # 检查所有节点健康状态
    log_info "检查节点健康状态..."
    for i in "${!NODES[@]}"; do
        local port=${NODES[$i]}
        local name=${NODE_NAMES[$i]}
        
        if check_node_health "$port"; then
            log_success "$name (端口 $port): 健康"
        else
            log_error "$name (端口 $port): 不健康"
            exit 1
        fi
    done
    
    echo
    log_info "开始负载均衡测试..."
    echo "测试配置:"
    echo "  节点数量: ${#NODES[@]}"
    echo "  测试请求数: $TEST_REQUESTS"
    echo "  并发请求数: $CONCURRENT_REQUESTS"
    echo
    
    # 执行测试
    test_round_robin
    echo
    
    # 计算和分析结果
    calculate_load_balance
    
    # 性能测试
    echo
    performance_test
    
    log_success "负载均衡测试完成"
}

# 运行主函数
main "$@"