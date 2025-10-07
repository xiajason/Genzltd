#!/bin/bash
# AI身份社交网络健康检查脚本

echo "🔍 AI身份社交网络健康检查"
echo "=========================="

# 检查函数
check_service() {
    local name=$1
    local url=$2
    local expected_status=$3
    
    if curl -f -s "$url" > /dev/null 2>&1; then
        echo "✅ $name: 健康"
        return 0
    else
        echo "❌ $name: 异常"
        return 1
    fi
}

# 检查数据库连接
check_database() {
    local name=$1
    local host=$2
    local port=$3
    
    if nc -z "$host" "$port" 2>/dev/null; then
        echo "✅ $name: 连接正常"
        return 0
    else
        echo "❌ $name: 连接异常"
        return 1
    fi
}

# 检查进程
check_process() {
    local name=$1
    local pid_file=$2
    
    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            echo "✅ $name: 运行中 (PID: $pid)"
            return 0
        else
            echo "❌ $name: 进程异常"
            return 1
        fi
    else
        echo "❌ $name: 进程文件不存在"
        return 1
    fi
}

echo "📊 检查数据库服务..."
echo "-------------------"
check_database "PostgreSQL" "localhost" "5434"
check_database "MongoDB" "localhost" "27018"
check_database "Redis" "localhost" "6382"
check_database "Neo4j" "localhost" "7687"
check_database "Weaviate" "localhost" "8082"
check_database "Elasticsearch" "localhost" "9202"

echo ""
echo "🤖 检查AI服务..."
echo "-------------------"
check_service "LoomaCRM Future" "http://localhost:7500/health"
check_service "AI网关服务" "http://localhost:7510/health"
check_service "简历AI服务" "http://localhost:7511/health"
check_service "MinerU服务" "http://localhost:8000/health"
check_service "AI模型服务" "http://localhost:8002/health"
# check_service "Zervigo Future" "http://localhost:8080/health"  # 服务不存在，已注释

echo ""
echo "🔄 检查容器状态..."
echo "-------------------"
# 这些是Docker容器，不是进程，所以不需要检查PID文件
echo "ℹ️  所有服务都以Docker容器形式运行，请查看下方Docker容器状态"

echo ""
echo "📈 检查系统资源..."
echo "-------------------"

# 检查内存使用 (macOS兼容)
if command -v vm_stat >/dev/null 2>&1; then
    # macOS方式
    MEMORY_USAGE=$(vm_stat | grep "Pages active" | awk '{print $3}' | sed 's/\.//')
    echo "💾 内存使用率: ${MEMORY_USAGE}%"
else
    # Linux方式 (如果free命令存在)
    if command -v free >/dev/null 2>&1; then
        MEMORY_USAGE=$(free -m | awk 'NR==2{printf "%.1f%%", $3*100/$2}')
        echo "💾 内存使用率: $MEMORY_USAGE"
    else
        echo "💾 内存使用率: 无法检测"
    fi
fi

# 检查磁盘使用
DISK_USAGE=$(df -h / | awk 'NR==2{print $5}')
echo "💿 磁盘使用率: $DISK_USAGE"

# 检查CPU使用
CPU_USAGE=$(top -l 1 | grep "CPU usage" | awk '{print $3}' | sed 's/%//')
echo "🖥️  CPU使用率: ${CPU_USAGE}%"

echo ""
echo "🔍 检查Docker容器..."
echo "-------------------"
if command -v docker &> /dev/null; then
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(future|looma|zervigo)"
else
    echo "❌ Docker未安装或未运行"
fi

echo ""
echo "📊 健康检查完成！"
echo "=========================="

# 生成健康报告
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
echo "检查时间: $TIMESTAMP" > /tmp/ai-identity-network-health-report.txt
echo "==========================" >> /tmp/ai-identity-network-health-report.txt

echo ""
echo "📄 健康报告已保存到: /tmp/ai-identity-network-health-report.txt"
echo "🔧 如需详细日志，请运行: ./view-ai-identity-network-logs.sh"
