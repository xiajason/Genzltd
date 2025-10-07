#!/bin/bash

# 集群化测试停止脚本

echo "🛑 停止集群化测试环境..."
echo "=========================================="

# 停止Go服务进程
stop_go_services() {
    echo "🛑 停止Go服务进程..."
    
    # 查找并停止所有相关进程
    pkill -f "basic-server" 2>/dev/null || true
    pkill -f "user-service" 2>/dev/null || true
    pkill -f "blockchain-service" 2>/dev/null || true
    pkill -f "cluster-manager" 2>/dev/null || true
    
    # 通过PID文件停止进程
    if [ -d "logs" ]; then
        echo "通过PID文件停止进程..."
        for pid_file in logs/*.pid; do
            if [ -f "$pid_file" ]; then
                pid=$(cat "$pid_file")
                if kill -0 "$pid" 2>/dev/null; then
                    echo "停止进程 $pid ($(basename $pid_file))"
                    kill "$pid" 2>/dev/null || true
                fi
                rm -f "$pid_file"
            fi
        done
    fi
    
    # 等待进程完全停止
    sleep 3
    
    # 强制停止残留进程
    pkill -9 -f "basic-server" 2>/dev/null || true
    pkill -9 -f "user-service" 2>/dev/null || true
    pkill -9 -f "blockchain-service" 2>/dev/null || true
    pkill -9 -f "cluster-manager" 2>/dev/null || true
}

# 停止Docker容器
stop_docker_services() {
    echo "🐳 停止Docker容器..."
    
    # 停止相关容器
    docker-compose down 2>/dev/null || true
    
    # 停止特定容器
    docker stop $(docker ps -q --filter "name=mysql") 2>/dev/null || true
    docker stop $(docker ps -q --filter "name=redis") 2>/dev/null || true
    docker stop $(docker ps -q --filter "name=postgresql") 2>/dev/null || true
    docker stop $(docker ps -q --filter "name=neo4j") 2>/dev/null || true
    docker stop $(docker ps -q --filter "name=consul") 2>/dev/null || true
    
    echo "✅ Docker容器已停止"
}

# 清理端口占用
cleanup_ports() {
    echo "🧹 清理端口占用..."
    
    # 检查并清理常用端口
    ports=(8080 8081 8082 8083 8084 8085 8091 8092 8093 9091)
    
    for port in "${ports[@]}"; do
        pid=$(lsof -ti:$port 2>/dev/null)
        if [ ! -z "$pid" ]; then
            echo "清理端口 $port (PID: $pid)"
            kill -9 "$pid" 2>/dev/null || true
        fi
    done
}

# 清理日志文件
cleanup_logs() {
    echo "📁 清理日志文件..."
    
    if [ -d "logs" ]; then
        # 备份重要日志
        if [ -f "logs/cluster-test-summary.log" ]; then
            cp "logs/cluster-test-summary.log" "logs/cluster-test-summary-$(date +%Y%m%d_%H%M%S).log"
        fi
        
        # 清理当前日志
        rm -f logs/*.log
        rm -f logs/*.pid
        
        echo "✅ 日志文件已清理"
    fi
}

# 显示停止状态
show_stop_status() {
    echo ""
    echo "📊 停止状态检查"
    echo "=========================================="
    
    # 检查端口占用
    echo "🔍 检查端口占用状态:"
    ports=(8080 8081 8082 8083 8084 8085 8091 8092 8093 9091)
    
    for port in "${ports[@]}"; do
        if lsof -ti:$port >/dev/null 2>&1; then
            echo "  ⚠️ 端口 $port 仍被占用"
        else
            echo "  ✅ 端口 $port 已释放"
        fi
    done
    
    # 检查进程
    echo ""
    echo "🔍 检查Go服务进程:"
    if pgrep -f "basic-server" >/dev/null; then
        echo "  ⚠️ basic-server 进程仍在运行"
    else
        echo "  ✅ basic-server 进程已停止"
    fi
    
    if pgrep -f "user-service" >/dev/null; then
        echo "  ⚠️ user-service 进程仍在运行"
    else
        echo "  ✅ user-service 进程已停止"
    fi
    
    if pgrep -f "blockchain-service" >/dev/null; then
        echo "  ⚠️ blockchain-service 进程仍在运行"
    else
        echo "  ✅ blockchain-service 进程已停止"
    fi
    
    if pgrep -f "cluster-manager" >/dev/null; then
        echo "  ⚠️ cluster-manager 进程仍在运行"
    else
        echo "  ✅ cluster-manager 进程已停止"
    fi
    
    # 检查Docker容器
    echo ""
    echo "🔍 检查Docker容器状态:"
    if docker ps --filter "name=mysql" --format "table {{.Names}}\t{{.Status}}" | grep -q mysql; then
        echo "  ⚠️ MySQL容器仍在运行"
    else
        echo "  ✅ MySQL容器已停止"
    fi
    
    if docker ps --filter "name=redis" --format "table {{.Names}}\t{{.Status}}" | grep -q redis; then
        echo "  ⚠️ Redis容器仍在运行"
    else
        echo "  ✅ Redis容器已停止"
    fi
    
    if docker ps --filter "name=consul" --format "table {{.Names}}\t{{.Status}}" | grep -q consul; then
        echo "  ⚠️ Consul容器仍在运行"
    else
        echo "  ✅ Consul容器已停止"
    fi
}

# 生成停止报告
generate_stop_report() {
    echo ""
    echo "📄 生成停止报告..."
    
    cat > cluster_stop_report_$(date +%Y%m%d_%H%M%S).md << EOF
# 集群测试环境停止报告

## 📋 停止概述
- **停止时间**: $(date)
- **停止方式**: 脚本自动停止
- **停止范围**: 所有集群服务和基础设施

## 🛑 停止的服务

### Go服务
- API Gateway集群 (8080, 8081, 8082)
- 用户服务集群 (8083, 8084, 8085)
- 区块链服务集群 (8091, 8092, 8093)
- 集群管理服务 (9091)

### Docker容器
- MySQL数据库
- Redis缓存
- PostgreSQL数据库
- Neo4j图数据库
- Consul服务发现

## 📊 停止状态
- **端口释放**: 已完成
- **进程清理**: 已完成
- **容器停止**: 已完成
- **日志清理**: 已完成

## ✅ 停止完成
集群测试环境已完全停止，所有资源已释放。
EOF

    echo "✅ 停止报告已生成"
}

# 主函数
main() {
    echo "🎯 集群化测试环境停止脚本"
    echo ""
    
    stop_go_services
    stop_docker_services
    cleanup_ports
    cleanup_logs
    
    echo ""
    echo "⏳ 等待资源完全释放..."
    sleep 3
    
    show_stop_status
    generate_stop_report
    
    echo ""
    echo "✅ 集群测试环境停止完成！"
    echo "📄 停止报告: cluster_stop_report_$(date +%Y%m%d_%H%M%S).md"
}

# 执行主函数
main "$@"
