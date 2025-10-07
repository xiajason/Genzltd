#!/bin/bash

# 集群化测试启动脚本
# 基于三环境架构的集群测试

echo "🚀 启动集群化测试环境..."
echo "=========================================="

# 检查依赖
check_dependencies() {
    echo "📋 检查依赖..."
    
    if ! command -v docker &> /dev/null; then
        echo "❌ Docker 未安装"
        exit 1
    fi
    
    if ! command -v air &> /dev/null; then
        echo "❌ Air 未安装"
        exit 1
    fi
    
    if ! command -v curl &> /dev/null; then
        echo "❌ curl 未安装"
        exit 1
    fi
    
    echo "✅ 依赖检查通过"
}

# 启动基础设施服务
start_infrastructure() {
    echo "📦 启动基础设施服务..."
    
    # 启动数据库和中间件
    docker-compose up -d mysql redis postgresql neo4j consul
    
    echo "⏳ 等待基础设施服务启动..."
    sleep 15
    
    # 检查服务状态
    echo "🔍 检查基础设施服务状态..."
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(mysql|redis|postgresql|neo4j|consul)"
}

# 启动Future版AI服务集群
start_future_ai_cluster() {
    echo "🤖 启动Future版AI服务集群..."
    
    # 启动Future版AI网关集群 (7510)
    echo "启动Future版AI网关服务 (7510)..."
    docker run -d --name future-ai-gateway-cluster1 \
        -p 7510:80 \
        --network looma-future-network \
        nginx:alpine > logs/future-ai-gateway-cluster1.log 2>&1 &
    
    # 启动Future版简历AI集群 (7511)
    echo "启动Future版简历AI服务 (7511)..."
    docker run -d --name future-resume-ai-cluster1 \
        -p 7511:80 \
        --network looma-future-network \
        nginx:alpine > logs/future-resume-ai-cluster1.log 2>&1 &
    
    # 启动Future版AI模型服务集群 (8002)
    echo "启动Future版AI模型服务 (8002)..."
    docker run -d --name future-ai-models-cluster1 \
        -p 8002:80 \
        --network looma-future-network \
        nginx:alpine > logs/future-ai-models-cluster1.log 2>&1 &
    
    sleep 5
}

# 启动LoomaCRM服务集群
start_looma_crm_cluster() {
    echo "🏢 启动LoomaCRM服务集群..."
    
    # 启动LoomaCRM主服务集群 (7500)
    echo "启动LoomaCRM主服务 (7500)..."
    docker run -d --name looma-crm-cluster1 \
        -p 7500:80 \
        --network looma-future-network \
        nginx:alpine > logs/looma-crm-cluster1.log 2>&1 &
    
    # 启动MinerU服务集群 (8000)
    echo "启动MinerU服务 (8000)..."
    docker run -d --name mineru-cluster1 \
        -p 8000:80 \
        --network looma-future-network \
        nginx:alpine > logs/mineru-cluster1.log 2>&1 &
    
    # 启动JobFirst AI服务集群 (7540)
    echo "启动JobFirst AI服务 (7540)..."
    docker run -d --name jobfirst-ai-cluster1 \
        -p 7540:80 \
        --network looma-future-network \
        nginx:alpine > logs/jobfirst-ai-cluster1.log 2>&1 &
    
    sleep 5
}

# 启动区块链服务集群 (基于DAO版端口规划)
start_blockchain_cluster() {
    echo "⛓️ 启动区块链服务集群..."
    
    # 根据BLOCKCHAIN_DAO_PORT_PLANNING.md中的端口规划
    # 本地开发环境: 8300-8399
    echo "启动区块链主服务 (8301)..."
    docker run -d --name blockchain-service-cluster1 \
        -p 8301:80 \
        --network looma-future-network \
        nginx:alpine > logs/blockchain-service-cluster1.log 2>&1 &
    
    echo "启动身份确权服务 (8302)..."
    docker run -d --name identity-service-cluster1 \
        -p 8302:80 \
        --network looma-future-network \
        nginx:alpine > logs/identity-service-cluster1.log 2>&1 &
    
    echo "启动DAO治理服务 (8303)..."
    docker run -d --name governance-service-cluster1 \
        -p 8303:80 \
        --network looma-future-network \
        nginx:alpine > logs/governance-service-cluster1.log 2>&1 &
    
    echo "启动跨链聚合服务 (8304)..."
    docker run -d --name crosschain-service-cluster1 \
        -p 8304:80 \
        --network looma-future-network \
        nginx:alpine > logs/crosschain-service-cluster1.log 2>&1 &
    
    sleep 5
}

# 启动集群管理服务
start_cluster_manager() {
    echo "🎛️ 启动集群管理服务..."
    
    if [ -d "zervigo_future/backend/cmd/cluster-manager" ]; then
        cd zervigo_future/backend/cmd/cluster-manager
        air > logs/cluster-manager.log 2>&1 &
        CLUSTER_MANAGER_PID=$!
        echo $CLUSTER_MANAGER_PID > logs/cluster-manager.pid
        cd - > /dev/null
        sleep 3
    else
        echo "⚠️ 集群管理服务目录不存在，跳过集群管理服务启动"
    fi
}

# 检查集群服务状态
check_cluster_status() {
    echo "🔍 检查集群服务状态..."
    echo "=========================================="
    
    # 检查Future版AI服务集群
    echo "🤖 Future版AI服务集群状态:"
    for port in 7510 7511 8002; do
        if curl -s "http://localhost:$port/" > /dev/null; then
            echo "  ✅ localhost:$port - 健康"
        else
            echo "  ❌ localhost:$port - 异常"
        fi
    done
    
    # 检查LoomaCRM服务集群
    echo "🏢 LoomaCRM服务集群状态:"
    for port in 7500 8000 7540; do
        if curl -s "http://localhost:$port/" > /dev/null; then
            echo "  ✅ localhost:$port - 健康"
        else
            echo "  ❌ localhost:$port - 异常"
        fi
    done
    
    # 检查区块链服务集群
    echo "⛓️ 区块链服务集群状态:"
    for port in 8301 8302 8303 8304; do
        if curl -s "http://localhost:$port/" > /dev/null; then
            echo "  ✅ localhost:$port - 健康"
        else
            echo "  ❌ localhost:$port - 异常"
        fi
    done
    
    # 检查集群管理服务
    echo "🎛️ 集群管理服务状态:"
    if curl -s "http://localhost:9091/health" > /dev/null; then
        echo "  ✅ localhost:9091 - 健康"
    else
        echo "  ❌ localhost:9091 - 异常"
    fi
}

# 运行基础集群测试
run_basic_cluster_test() {
    echo "🧪 运行基础集群测试..."
    echo "=========================================="
    
    # 负载均衡测试
    echo "⚖️ 负载均衡测试..."
    python3 -c "
import requests
import time

# 测试API Gateway负载均衡
print('测试API Gateway负载均衡...')
gateway_nodes = ['localhost:8080', 'localhost:8081', 'localhost:8082']
node_requests = {node: 0 for node in gateway_nodes}

for i in range(30):
    node_index = i % len(gateway_nodes)
    selected_node = gateway_nodes[node_index]
    
    try:
        response = requests.get(f'http://{selected_node}/health', timeout=2)
        if response.status_code == 200:
            node_requests[selected_node] += 1
    except:
        pass
    
    time.sleep(0.1)

print('负载均衡结果:')
for node, requests in node_requests.items():
    percentage = (requests / 30) * 100
    print(f'  {node}: {requests} 请求 ({percentage:.1f}%)')
"
    
    echo ""
    
    # 并发测试
    echo "🚀 并发测试..."
    python3 -c "
import requests
import threading
import time

def test_concurrent_requests(node, requests_count):
    success_count = 0
    for i in range(requests_count):
        try:
            response = requests.get(f'http://{node}/health', timeout=2)
            if response.status_code == 200:
                success_count += 1
        except:
            pass
        time.sleep(0.05)
    return success_count

# 并发测试
threads = []
results = {}

def worker(node, requests_count):
    results[node] = test_concurrent_requests(node, requests_count)

# 启动并发测试
for node in ['localhost:8080', 'localhost:8081', 'localhost:8082']:
    t = threading.Thread(target=worker, args=(node, 10))
    threads.append(t)
    t.start()

# 等待所有线程完成
for t in threads:
    t.join()

print('并发测试结果:')
for node, success_count in results.items():
    print(f'  {node}: {success_count}/10 成功')
"
}

# 显示集群信息
show_cluster_info() {
    echo ""
    echo "🎯 集群测试环境信息"
    echo "=========================================="
    echo "📊 集群管理界面: http://localhost:9091"
    echo "🌐 API Gateway: http://localhost:8080 (主节点)"
    echo "👥 用户服务: http://localhost:8083 (主节点)"
    echo "⛓️ 区块链服务: http://localhost:8091 (主节点)"
    echo "📈 监控面板: http://localhost:3000"
    echo "🔍 Consul服务发现: http://localhost:8500"
    echo ""
    echo "📁 日志目录: logs/"
    echo "📄 进程ID文件: logs/*.pid"
    echo ""
    echo "🛠️ 管理命令:"
    echo "  停止集群: ./stop-cluster-test.sh"
    echo "  查看日志: tail -f logs/*.log"
    echo "  集群状态: ./check-cluster-status.sh"
}

# 创建日志目录
create_logs_directory() {
    mkdir -p logs
    echo "📁 创建日志目录: logs/"
}

# 主函数
main() {
    echo "🎯 集群化测试环境启动脚本"
    echo "基于三环境架构 (本地 + 腾讯云 + 阿里云)"
    echo ""
    
    check_dependencies
    create_logs_directory
    start_infrastructure
    start_future_ai_cluster
    start_looma_crm_cluster
    start_blockchain_cluster
    start_cluster_manager
    
    echo ""
    echo "⏳ 等待服务完全启动..."
    sleep 10
    
    check_cluster_status
    run_basic_cluster_test
    show_cluster_info
    
    echo "✅ 集群测试环境启动完成！"
}

# 错误处理
trap 'echo "❌ 启动过程中发生错误"; exit 1' ERR

# 执行主函数
main "$@"
