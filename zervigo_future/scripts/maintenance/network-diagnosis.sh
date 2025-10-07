#!/bin/bash

# 网络诊断脚本
# 用于诊断Docker镜像拉取和网络连接问题

set -e

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log_success() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ $1"
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ❌ $1"
}

log_warning() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ⚠️  $1"
}

# 检查基本网络连接
check_basic_connectivity() {
    log "=== 检查基本网络连接 ==="
    
    # 检查DNS解析
    if nslookup registry-1.docker.io > /dev/null 2>&1; then
        log_success "DNS解析正常"
    else
        log_error "DNS解析失败"
    fi
    
    # 检查HTTP连接
    if curl -s --connect-timeout 10 https://registry-1.docker.io/v2/ > /dev/null 2>&1; then
        log_success "Docker Hub连接正常"
    else
        log_error "Docker Hub连接失败"
    fi
    
    # 检查HTTPS连接
    if curl -s --connect-timeout 10 -k https://registry-1.docker.io/v2/ > /dev/null 2>&1; then
        log_success "Docker Hub HTTPS连接正常"
    else
        log_error "Docker Hub HTTPS连接失败"
    fi
}

# 检查Docker网络配置
check_docker_network() {
    log "=== 检查Docker网络配置 ==="
    
    # 检查Docker daemon状态
    if docker info > /dev/null 2>&1; then
        log_success "Docker daemon运行正常"
    else
        log_error "Docker daemon未运行"
        return 1
    fi
    
    # 检查Docker网络
    echo "Docker网络列表:"
    docker network ls
    
    # 检查Docker镜像
    echo "本地Docker镜像:"
    docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"
}

# 测试Docker镜像拉取
test_docker_pull() {
    log "=== 测试Docker镜像拉取 ==="
    
    # 测试拉取小镜像
    log "测试拉取alpine镜像..."
    if docker pull alpine:latest > /dev/null 2>&1; then
        log_success "Alpine镜像拉取成功"
        docker rmi alpine:latest > /dev/null 2>&1 || true
    else
        log_error "Alpine镜像拉取失败"
    fi
    
    # 测试拉取nginx镜像
    log "测试拉取nginx镜像..."
    if docker pull nginx:alpine > /dev/null 2>&1; then
        log_success "Nginx镜像拉取成功"
        docker rmi nginx:alpine > /dev/null 2>&1 || true
    else
        log_error "Nginx镜像拉取失败"
    fi
}

# 检查防火墙和代理设置
check_firewall_proxy() {
    log "=== 检查防火墙和代理设置 ==="
    
    # 检查防火墙状态
    if command -v ufw > /dev/null 2>&1; then
        echo "UFW防火墙状态:"
        ufw status
    fi
    
    if command -v iptables > /dev/null 2>&1; then
        echo "iptables规则数量: $(iptables -L | wc -l)"
    fi
    
    # 检查代理设置
    if [ -n "$HTTP_PROXY" ] || [ -n "$HTTPS_PROXY" ]; then
        log_warning "检测到代理设置:"
        echo "HTTP_PROXY: $HTTP_PROXY"
        echo "HTTPS_PROXY: $HTTPS_PROXY"
    else
        log "未检测到代理设置"
    fi
}

# 提供解决方案建议
provide_solutions() {
    log "=== 解决方案建议 ==="
    
    echo "如果遇到网络连接问题，可以尝试以下解决方案:"
    echo ""
    echo "1. 配置Docker镜像加速器:"
    echo "   sudo mkdir -p /etc/docker"
    echo "   sudo tee /etc/docker/daemon.json <<-'EOF'"
    echo "   {"
    echo "     \"registry-mirrors\": ["
    echo "       \"https://docker.mirrors.ustc.edu.cn\","
    echo "       \"https://hub-mirror.c.163.com\","
    echo "       \"https://mirror.baidubce.com\""
    echo "     ]"
    echo "   }"
    echo "   EOF"
    echo "   sudo systemctl daemon-reload"
    echo "   sudo systemctl restart docker"
    echo ""
    echo "2. 使用离线部署方案:"
    echo "   ./scripts/offline-deploy.sh"
    echo ""
    echo "3. 手动拉取基础镜像:"
    echo "   docker pull mysql:8.0"
    echo "   docker pull redis:7-alpine"
    echo "   docker pull postgres:15-alpine"
    echo "   docker pull neo4j:5.15-community"
    echo "   docker pull nginx:alpine"
    echo "   docker pull consul:1.18.0"
    echo ""
    echo "4. 检查网络连接:"
    echo "   ping registry-1.docker.io"
    echo "   curl -I https://registry-1.docker.io/v2/"
}

# 主函数
main() {
    log "开始网络诊断..."
    
    check_basic_connectivity
    check_docker_network
    test_docker_pull
    check_firewall_proxy
    provide_solutions
    
    log "网络诊断完成"
}

# 执行主函数
main "$@"
