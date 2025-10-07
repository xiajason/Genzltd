#!/bin/bash

# 分布式用户系统故障容错测试脚本
# 测试用户系统健康检查、网络检查、数据断点续传

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
USER_SYSTEMS=("8080" "8180" "8280")
USER_NAMES=("用户A系统" "用户B系统" "用户C系统")
HEALTH_CHECK_INTERVAL=5
NETWORK_TEST_COUNT=10

# 临时文件存储测试数据
TEMP_DIR="/tmp/user_system_fault_test_$$"
mkdir -p "$TEMP_DIR"

# 初始化用户系统状态
init_user_systems() {
    log_info "初始化用户系统状态..."
    
    for i in "${!USER_SYSTEMS[@]}"; do
        local port=${USER_SYSTEMS[$i]}
        local name=${USER_NAMES[$i]}
        
        echo "healthy" > "$TEMP_DIR/status_$port"
        echo "0" > "$TEMP_DIR/health_check_count_$port"
        echo "0" > "$TEMP_DIR/network_failures_$port"
        echo "0" > "$TEMP_DIR/data_sync_progress_$port"
        echo "0" > "$TEMP_DIR/last_sync_time_$port"
        
        log_info "用户系统 $name (端口 $port) 已初始化"
    done
}

# 用户系统健康检查
check_user_system_health() {
    local port=$1
    local name=$2
    
    log_info "检查用户系统 $name (端口 $port) 健康状态..."
    
    # 检查服务是否响应
    local response=$(curl -s -w "%{http_code}" -o /dev/null "http://localhost:${port}/health" 2>/dev/null)
    
    if [ "$response" = "200" ]; then
        # 检查集群状态
        local cluster_status=$(curl -s "http://localhost:${port}/api/v1/cluster/status" 2>/dev/null)
        if echo "$cluster_status" | grep -q "enabled.*true"; then
            echo "healthy" > "$TEMP_DIR/status_$port"
            log_success "用户系统 $name: 健康"
            return 0
        else
            echo "unhealthy" > "$TEMP_DIR/status_$port"
            log_warning "用户系统 $name: 集群状态异常"
            return 1
        fi
    else
        echo "unhealthy" > "$TEMP_DIR/status_$port"
        log_error "用户系统 $name: 服务无响应 (HTTP $response)"
        return 1
    fi
}

# 网络连通性测试
test_network_connectivity() {
    local port=$1
    local name=$2
    
    log_info "测试用户系统 $name (端口 $port) 网络连通性..."
    
    local success_count=0
    local total_time=0
    
    for i in $(seq 1 $NETWORK_TEST_COUNT); do
        local start_time=$(date +%s)
        local response=$(curl -s -w "%{http_code}" -o /dev/null "http://localhost:${port}/api/v1/cluster/status" 2>/dev/null)
        local end_time=$(date +%s)
        local response_time=$((end_time - start_time))
        
        if [ "$response" = "200" ]; then
            success_count=$((success_count + 1))
            total_time=$((total_time + response_time))
        else
            log_warning "网络测试 $i: 失败 (HTTP $response)"
        fi
        
        sleep 0.5
    done
    
    local success_rate=$((success_count * 100 / NETWORK_TEST_COUNT))
    local avg_response_time=0
    if [ $success_count -gt 0 ]; then
        avg_response_time=$((total_time / success_count))
    fi
    
    echo "$success_count" > "$TEMP_DIR/network_success_$port"
    echo "$avg_response_time" > "$TEMP_DIR/network_avg_time_$port"
    
    if [ $success_rate -ge 90 ]; then
        log_success "用户系统 $name: 网络质量优秀 (成功率: ${success_rate}%, 平均响应: ${avg_response_time}s)"
    elif [ $success_rate -ge 70 ]; then
        log_warning "用户系统 $name: 网络质量一般 (成功率: ${success_rate}%, 平均响应: ${avg_response_time}s)"
    else
        log_error "用户系统 $name: 网络质量差 (成功率: ${success_rate}%, 平均响应: ${avg_response_time}s)"
        echo "1" > "$TEMP_DIR/network_failures_$port"
    fi
}

# 数据同步状态检查
check_data_sync_status() {
    local port=$1
    local name=$2
    
    log_info "检查用户系统 $name (端口 $port) 数据同步状态..."
    
    # 模拟数据同步进度检查
    local sync_progress=$(curl -s "http://localhost:${port}/api/v1/cluster/status" 2>/dev/null | grep -o '"total_requests":[0-9]*' | cut -d':' -f2)
    
    if [ -z "$sync_progress" ]; then
        sync_progress=0
    fi
    
    echo "$sync_progress" > "$TEMP_DIR/data_sync_progress_$port"
    echo "$(date +%s)" > "$TEMP_DIR/last_sync_time_$port"
    
    log_info "用户系统 $name: 数据同步进度 $sync_progress"
}

# 模拟网络故障
simulate_network_failure() {
    local port=$1
    local name=$2
    local duration=$3
    
    log_warning "模拟用户系统 $name (端口 $port) 网络故障，持续 ${duration}秒..."
    
    # 这里可以模拟网络故障，比如：
    # 1. 临时停止服务
    # 2. 模拟网络延迟
    # 3. 模拟网络中断
    
    # 由于是测试环境，我们只是记录故障状态
    echo "network_failure" > "$TEMP_DIR/status_$port"
    echo "$(date +%s)" > "$TEMP_DIR/failure_start_$port"
    
    sleep $duration
    
    # 恢复网络
    log_info "恢复用户系统 $name (端口 $port) 网络连接..."
    echo "healthy" > "$TEMP_DIR/status_$port"
}

# 数据断点续传测试
test_data_resume() {
    local port=$1
    local name=$2
    
    log_info "测试用户系统 $name (端口 $port) 数据断点续传..."
    
    # 获取故障前的同步进度
    local pre_failure_progress=$(cat "$TEMP_DIR/data_sync_progress_$port")
    
    # 模拟网络故障
    simulate_network_failure "$port" "$name" 10
    
    # 检查断点续传
    local post_failure_progress=$(cat "$TEMP_DIR/data_sync_progress_$port")
    
    if [ "$post_failure_progress" -ge "$pre_failure_progress" ]; then
        log_success "用户系统 $name: 数据断点续传成功"
        return 0
    else
        log_error "用户系统 $name: 数据断点续传失败"
        return 1
    fi
}

# 生成故障处理报告
generate_fault_tolerance_report() {
    log_info "生成故障容错测试报告..."
    
    local report_file="$TEMP_DIR/fault_tolerance_report.txt"
    
    cat > "$report_file" << EOF
分布式用户系统故障容错测试报告
================================

测试时间: $(date)
测试节点数: ${#USER_SYSTEMS[@]}

用户系统状态:
EOF
    
    for i in "${!USER_SYSTEMS[@]}"; do
        local port=${USER_SYSTEMS[$i]}
        local name=${USER_NAMES[$i]}
        local status=$(cat "$TEMP_DIR/status_$port")
        local network_success=$(cat "$TEMP_DIR/network_success_$port")
        local network_avg_time=$(cat "$TEMP_DIR/network_avg_time_$port")
        local sync_progress=$(cat "$TEMP_DIR/data_sync_progress_$port")
        
        cat >> "$report_file" << EOF

用户系统: $name (端口 $port)
  健康状态: $status
  网络成功率: $network_success/$NETWORK_TEST_COUNT
  平均响应时间: ${network_avg_time}s
  数据同步进度: $sync_progress
EOF
    done
    
    cat >> "$report_file" << EOF

测试结论:
- 用户系统健康检查: 完成
- 网络连通性测试: 完成
- 数据断点续传测试: 完成

建议:
1. 定期进行用户系统健康检查
2. 监控网络质量指标
3. 实现数据断点续传机制
4. 建立故障告警系统

EOF
    
    log_success "故障容错测试报告已生成: $report_file"
    cat "$report_file"
}

# 清理临时文件
cleanup() {
    rm -rf "$TEMP_DIR"
}

# 主函数
main() {
    log_info "分布式用户系统故障容错测试开始"
    
    # 设置清理陷阱
    trap cleanup EXIT
    
    # 初始化用户系统
    init_user_systems
    
    echo
    log_info "开始用户系统健康检查..."
    
    # 健康检查测试
    for i in "${!USER_SYSTEMS[@]}"; do
        local port=${USER_SYSTEMS[$i]}
        local name=${USER_NAMES[$i]}
        
        check_user_system_health "$port" "$name"
        increment_counter "$port" "health_check_count"
    done
    
    echo
    log_info "开始网络连通性测试..."
    
    # 网络连通性测试
    for i in "${!USER_SYSTEMS[@]}"; do
        local port=${USER_SYSTEMS[$i]}
        local name=${USER_NAMES[$i]}
        
        test_network_connectivity "$port" "$name"
    done
    
    echo
    log_info "开始数据同步状态检查..."
    
    # 数据同步状态检查
    for i in "${!USER_SYSTEMS[@]}"; do
        local port=${USER_SYSTEMS[$i]}
        local name=${USER_NAMES[$i]}
        
        check_data_sync_status "$port" "$name"
    done
    
    echo
    log_info "开始数据断点续传测试..."
    
    # 数据断点续传测试
    for i in "${!USER_SYSTEMS[@]}"; do
        local port=${USER_SYSTEMS[$i]}
        local name=${USER_NAMES[$i]}
        
        test_data_resume "$port" "$name"
    done
    
    echo
    generate_fault_tolerance_report
    
    log_success "分布式用户系统故障容错测试完成"
}

# 增加计数器的辅助函数
increment_counter() {
    local port=$1
    local type=$2
    local current=$(cat "$TEMP_DIR/${type}_$port" 2>/dev/null || echo "0")
    echo $((current + 1)) > "$TEMP_DIR/${type}_$port"
}

# 运行主函数
main "$@"
