#!/bin/bash

# 集群状态检查脚本 (修正版)

echo "🔍 集群状态检查"
echo "=========================================="

# 检查服务健康状态
check_service_health() {
    local service_name=$1
    shift
    local nodes=("$@")
    
    echo "📊 $service_name 集群状态:"
    
    local healthy_nodes=0
    local total_nodes=${#nodes[@]}
    
    for node in "${nodes[@]}"; do
        if curl -s "http://$node/" > /dev/null 2>&1; then
            echo "  ✅ $node - 健康"
            ((healthy_nodes++))
        else
            echo "  ❌ $node - 异常"
        fi
    done
    
    local health_percentage=$((healthy_nodes * 100 / total_nodes))
    echo "  健康率: $healthy_nodes/$total_nodes ($health_percentage%)"
    
    return $health_percentage
}

# 检查Docker容器状态
check_docker_status() {
    echo ""
    echo "🐳 Docker容器状态:"
    
    # 检查相关容器
    containers=("future-ai-gateway" "future-resume-ai" "future-ai-models" "looma-crm-future" "future-mineru" "jobfirst-ai-service")
    
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
    ports=(7500 7510 7511 8000 8002 7540 8301 8302 8303 8304)
    
    for port in "${ports[@]}"; do
        if lsof -ti:$port >/dev/null 2>&1; then
            echo "  ✅ 端口 $port: 被占用"
        else
            echo "  ❌ 端口 $port: 空闲"
        fi
    done
}

# 主函数
main() {
    echo "🎯 集群状态全面检查 (基于实际Future版端口配置)"
    echo ""
    
    # 定义集群节点 (基于实际Future版端口配置)
    FUTURE_AI_NODES=("localhost:7510" "localhost:7511" "localhost:8002")
    LOOMA_CRM_NODES=("localhost:7500" "localhost:8000" "localhost:7540")
    BLOCKCHAIN_NODES=("localhost:8301" "localhost:8302" "localhost:8303" "localhost:8304")
    
    # 检查各服务集群
    check_service_health "Future版AI服务" "${FUTURE_AI_NODES[@]}"
    check_service_health "LoomaCRM服务" "${LOOMA_CRM_NODES[@]}"
    check_service_health "区块链服务" "${BLOCKCHAIN_NODES[@]}"
    
    # 检查基础设施
    check_docker_status
    check_port_usage
    
    echo ""
    echo "✅ 集群状态检查完成！"
    echo ""
    echo "📊 快速访问:"
    echo "  🤖 Future版AI网关: http://localhost:7510"
    echo "  🏢 LoomaCRM主服务: http://localhost:7500"
    echo "  ⛓️ 区块链主服务: http://localhost:8301"
    echo "  🔍 Consul: http://localhost:8500"
}

# 执行主函数
main "$@"
