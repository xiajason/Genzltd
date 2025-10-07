#!/bin/bash

# 集群状态检查脚本

echo "🔍 集群状态检查"
echo "=========================================="

# 检查服务健康状态
check_service_health() {
    local service_name=$1
    local nodes=("${@:2}")
    
    echo "📊 $service_name 集群状态:"
    
    local healthy_nodes=0
    local total_nodes=${#nodes[@]}
    
    for node in "${nodes[@]}"; do
        if curl -s "http://$node/health" > /dev/null 2>&1; then
            # 获取详细健康信息
            health_info=$(curl -s "http://$node/health" 2>/dev/null | jq -r '.status // "unknown"' 2>/dev/null || echo "healthy")
            echo "  ✅ $node - $health_info"
            ((healthy_nodes++))
        else
            echo "  ❌ $node - 异常"
        fi
    done
    
    local health_percentage=$((healthy_nodes * 100 / total_nodes))
    echo "  健康率: $healthy_nodes/$total_nodes ($health_percentage%)"
    
    return $health_percentage
}

# 检查负载均衡分布
check_load_balance_distribution() {
    local service_name=$1
    local nodes=("${@:2}")
    local test_requests=50
    
    echo ""
    echo "⚖️ $service_name 负载均衡测试:"
    
    # 使用普通变量而不是关联数组 (兼容性修复)
    node_count=0
    for node in "${nodes[@]}"; do
        eval "node_requests_${node_count}=0"
        ((node_count++))
    done
    
    # 发送测试请求
    for ((i=1; i<=test_requests; i++)); do
        node_index=$((i % ${#nodes[@]}))
        selected_node=${nodes[$node_index]}
        
        if curl -s "http://$selected_node/health" > /dev/null 2>&1; then
            ((node_requests[$selected_node]++))
        fi
        
        sleep 0.1
    done
    
    # 计算分布
    echo "  负载分布:"
    for node in "${nodes[@]}"; do
        requests=${node_requests[$node]}
        percentage=$((requests * 100 / test_requests))
        echo "    $node: $requests 请求 ($percentage%)"
    done
}

# 检查集群配置
check_cluster_configuration() {
    echo ""
    echo "⚙️ 集群配置检查:"
    
    # 检查Consul服务发现
    if curl -s "http://localhost:8500/v1/status/leader" > /dev/null 2>&1; then
        consul_leader=$(curl -s "http://localhost:8500/v1/status/leader" 2>/dev/null | tr -d '"')
        echo "  ✅ Consul服务发现: 正常 (Leader: $consul_leader)"
    else
        echo "  ❌ Consul服务发现: 异常"
    fi
    
    # 检查集群管理服务
    if curl -s "http://localhost:9091/health" > /dev/null 2>&1; then
        echo "  ✅ 集群管理服务: 正常"
    else
        echo "  ❌ 集群管理服务: 异常"
    fi
}

# 检查资源使用情况
check_resource_usage() {
    echo ""
    echo "💻 资源使用情况:"
    
    # CPU使用率
    cpu_usage=$(top -l 1 | grep "CPU usage" | awk '{print $3}' | sed 's/%//')
    echo "  CPU使用率: ${cpu_usage}%"
    
    # 内存使用情况
    memory_info=$(vm_stat | grep -E "(free|active|inactive|wired)" | awk '{print $3}' | sed 's/\.//')
    echo "  内存使用情况: $memory_info"
    
    # 磁盘使用情况
    disk_usage=$(df -h / | awk 'NR==2 {print $5}')
    echo "  磁盘使用率: $disk_usage"
    
    # 网络连接数
    network_connections=$(netstat -an | grep ESTABLISHED | wc -l)
    echo "  网络连接数: $network_connections"
}

# 检查Docker容器状态
check_docker_status() {
    echo ""
    echo "🐳 Docker容器状态:"
    
    # 检查相关容器
    containers=("mysql" "redis" "postgresql" "neo4j" "consul")
    
    for container in "${containers[@]}"; do
        if docker ps --filter "name=$container" --format "{{.Names}}" | grep -q "$container"; then
            status=$(docker ps --filter "name=$container" --format "{{.Status}}")
            echo "  ✅ $container: $status"
        else
            echo "  ❌ $container: 未运行"
        fi
    done
}

# 检查端口占用
check_port_usage() {
    echo ""
    echo "🔌 端口占用情况:"
    
    # 检查集群相关端口 (基于实际Future版端口配置)
    ports=(7500 7510 7511 8000 8002 7540 8301 8302 8303 8304 9091 8500 3306 6379 5432 7474)
    
    for port in "${ports[@]}"; do
        if lsof -ti:$port >/dev/null 2>&1; then
            process=$(lsof -ti:$port | xargs ps -p | tail -1 | awk '{print $NF}')
            echo "  ✅ 端口 $port: 被 $process 占用"
        else
            echo "  ❌ 端口 $port: 空闲"
        fi
    done
}

# 生成性能报告
generate_performance_report() {
    echo ""
    echo "📈 性能报告生成中..."
    
    # 收集性能数据
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local report_file="cluster_performance_report_$timestamp.json"
    
    cat > "$report_file" << EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "cluster_status": {
    "api_gateway": {
      "nodes": ["localhost:8080", "localhost:8081", "localhost:8082"],
      "healthy_nodes": 0,
      "total_nodes": 3
    },
    "user_service": {
      "nodes": ["localhost:8083", "localhost:8084", "localhost:8085"],
      "healthy_nodes": 0,
      "total_nodes": 3
    },
    "blockchain_service": {
      "nodes": ["localhost:8091", "localhost:8092", "localhost:8093"],
      "healthy_nodes": 0,
      "total_nodes": 3
    }
  },
  "infrastructure": {
    "consul": "unknown",
    "cluster_manager": "unknown",
    "docker_containers": []
  },
  "resources": {
    "cpu_usage": "$(top -l 1 | grep "CPU usage" | awk '{print $3}')",
    "memory_usage": "unknown",
    "disk_usage": "$(df -h / | awk 'NR==2 {print $5}')",
    "network_connections": $(netstat -an | grep ESTABLISHED | wc -l)
  }
}
EOF

    echo "  📄 性能报告已保存: $report_file"
}

# 主函数
main() {
    echo "🎯 集群状态全面检查"
    echo ""
    
    # 定义集群节点 (基于实际Future版端口配置)
    FUTURE_AI_NODES=("localhost:7510" "localhost:7511" "localhost:8002")
    LOOMA_CRM_NODES=("localhost:7500" "localhost:8000" "localhost:7540")
    BLOCKCHAIN_NODES=("localhost:8301" "localhost:8302" "localhost:8303" "localhost:8304")
    
    # 检查各服务集群
    check_service_health "Future版AI服务" "${FUTURE_AI_NODES[@]}"
    check_load_balance_distribution "Future版AI服务" "${FUTURE_AI_NODES[@]}"
    
    check_service_health "LoomaCRM服务" "${LOOMA_CRM_NODES[@]}"
    check_load_balance_distribution "LoomaCRM服务" "${LOOMA_CRM_NODES[@]}"
    
    check_service_health "区块链服务" "${BLOCKCHAIN_NODES[@]}"
    check_load_balance_distribution "区块链服务" "${BLOCKCHAIN_NODES[@]}"
    
    # 检查基础设施
    check_cluster_configuration
    check_docker_status
    check_port_usage
    check_resource_usage
    
    # 生成报告
    generate_performance_report
    
    echo ""
    echo "✅ 集群状态检查完成！"
    echo ""
    echo "📊 快速访问:"
    echo "  🤖 Future版AI网关: http://localhost:7510"
    echo "  🏢 LoomaCRM主服务: http://localhost:7500"
    echo "  ⛓️ 区块链主服务: http://localhost:8301"
    echo "  🎛️ 集群管理: http://localhost:9091"
    echo "  🔍 Consul: http://localhost:8500"
}

# 执行主函数
main "$@"
