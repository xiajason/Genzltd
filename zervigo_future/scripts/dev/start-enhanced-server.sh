#!/bin/bash

# 启动增强的JobFirst服务器
# 包含完整的权限管理系统和Consul注册功能

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 项目配置
PROJECT_ROOT="/opt/jobfirst"
BACKEND_DIR="$PROJECT_ROOT/backend"
ENHANCED_SERVER_DIR="$BACKEND_DIR/cmd/enhanced-basic-server"
CONFIG_FILE="$BACKEND_DIR/configs/config.yaml"
LOG_FILE="$PROJECT_ROOT/logs/enhanced-server.log"
PID_FILE="$PROJECT_ROOT/enhanced-server.pid"

# 日志函数
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}" | tee -a "$LOG_FILE"
    exit 1
}

info() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1${NC}" | tee -a "$LOG_FILE"
}

# 检查环境
check_environment() {
    log "检查环境..."
    
    # 检查项目目录
    if [[ ! -d "$PROJECT_ROOT" ]]; then
        error "项目目录不存在: $PROJECT_ROOT"
    fi
    
    # 检查增强服务器目录
    if [[ ! -d "$ENHANCED_SERVER_DIR" ]]; then
        error "增强服务器目录不存在: $ENHANCED_SERVER_DIR"
    fi
    
    # 检查配置文件
    if [[ ! -f "$CONFIG_FILE" ]]; then
        error "配置文件不存在: $CONFIG_FILE"
    fi
    
    # 检查Go环境
    if ! command -v go &> /dev/null; then
        error "Go环境未安装"
    fi
    
    # 检查Go版本
    local go_version=$(go version | awk '{print $3}' | sed 's/go//')
    info "Go版本: $go_version"
    
    log "环境检查完成"
}

# 检查依赖服务
check_dependencies() {
    log "检查依赖服务..."
    
    # 检查MySQL
    if ! command -v mysql &> /dev/null; then
        error "MySQL客户端未安装"
    fi
    
    # 检查Redis
    if ! command -v redis-cli &> /dev/null; then
        error "Redis客户端未安装"
    fi
    
    # 检查Consul
    if ! command -v consul &> /dev/null; then
        warn "Consul未安装，服务发现功能将被禁用"
    fi
    
    log "依赖服务检查完成"
}

# 检查服务状态
check_service_status() {
    log "检查服务状态..."
    
    # 检查MySQL服务
    if ! systemctl is-active --quiet mysql; then
        error "MySQL服务未运行"
    fi
    info "MySQL服务状态: 运行中"
    
    # 检查Redis服务
    if ! systemctl is-active --quiet redis; then
        error "Redis服务未运行"
    fi
    info "Redis服务状态: 运行中"
    
    # 检查Consul服务
    if systemctl is-active --quiet consul; then
        info "Consul服务状态: 运行中"
    else
        warn "Consul服务未运行，服务发现功能将被禁用"
    fi
    
    log "服务状态检查完成"
}

# 检查端口占用
check_ports() {
    log "检查端口占用..."
    
    # 从配置文件读取端口
    local server_port=$(grep -A 5 "server:" "$CONFIG_FILE" | grep "port:" | awk '{print $2}' | tr -d '"')
    if [[ -z "$server_port" ]]; then
        server_port=8600
    fi
    
    # 检查端口是否被占用
    if lsof -i ":$server_port" &> /dev/null; then
        error "端口 $server_port 已被占用"
    fi
    info "端口 $server_port 可用"
    
    log "端口检查完成"
}

# 构建项目
build_project() {
    log "构建项目..."
    
    # 进入项目目录
    cd "$PROJECT_ROOT"
    
    # 下载依赖
    info "下载Go依赖..."
    if ! go mod tidy; then
        error "下载依赖失败"
    fi
    
    # 构建增强服务器
    info "构建增强服务器..."
    if ! go build -o "$PROJECT_ROOT/bin/enhanced-basic-server" "$ENHANCED_SERVER_DIR/main.go"; then
        error "构建增强服务器失败"
    fi
    
    # 设置执行权限
    chmod +x "$PROJECT_ROOT/bin/enhanced-basic-server"
    
    log "项目构建完成"
}

# 启动服务器
start_server() {
    log "启动增强服务器..."
    
    # 创建日志目录
    mkdir -p "$(dirname "$LOG_FILE")"
    
    # 启动服务器
    info "启动增强服务器..."
    nohup "$PROJECT_ROOT/bin/enhanced-basic-server" > "$LOG_FILE" 2>&1 &
    local server_pid=$!
    
    # 保存PID
    echo "$server_pid" > "$PID_FILE"
    
    # 等待服务器启动
    info "等待服务器启动..."
    sleep 5
    
    # 检查服务器是否启动成功
    if ! kill -0 "$server_pid" 2>/dev/null; then
        error "服务器启动失败，请检查日志: $LOG_FILE"
    fi
    
    info "服务器PID: $server_pid"
    log "增强服务器启动成功"
}

# 验证服务器
verify_server() {
    log "验证服务器..."
    
    # 从配置文件读取端口
    local server_port=$(grep -A 5 "server:" "$CONFIG_FILE" | grep "port:" | awk '{print $2}' | tr -d '"')
    if [[ -z "$server_port" ]]; then
        server_port=8600
    fi
    
    local server_url="http://localhost:$server_port"
    
    # 等待服务器完全启动
    info "等待服务器完全启动..."
    sleep 10
    
    # 检查健康检查端点
    info "检查健康检查端点..."
    local max_attempts=30
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        if curl -s "$server_url/health" > /dev/null; then
            break
        fi
        
        if [[ $attempt -eq $max_attempts ]]; then
            error "服务器健康检查失败"
        fi
        
        info "等待服务器启动... ($attempt/$max_attempts)"
        sleep 2
        ((attempt++))
    done
    
    # 获取健康检查信息
    local health_response=$(curl -s "$server_url/health")
    local health_status=$(echo "$health_response" | jq -r '.status // "unknown"')
    
    if [[ "$health_status" == "healthy" ]]; then
        info "✅ 服务器健康状态: $health_status"
    else
        error "❌ 服务器健康状态异常: $health_status"
    fi
    
    # 检查超级管理员状态
    info "检查超级管理员状态..."
    local super_admin_response=$(curl -s "$server_url/api/v1/super-admin/public/status")
    local super_admin_exists=$(echo "$super_admin_response" | jq -r '.exists // false')
    
    if [[ "$super_admin_exists" == "true" ]]; then
        info "✅ 超级管理员已存在"
    else
        info "ℹ️  超级管理员未初始化"
    fi
    
    log "服务器验证完成"
}

# 检查Consul注册
check_consul_registration() {
    log "检查Consul注册..."
    
    # 检查Consul是否运行
    if ! systemctl is-active --quiet consul; then
        warn "Consul服务未运行，跳过注册检查"
        return 0
    fi
    
    # 等待服务注册
    info "等待服务注册到Consul..."
    sleep 5
    
    # 检查服务是否注册成功
    local consul_address="localhost:8650"
    local services_response=$(curl -s "http://$consul_address/v1/agent/services")
    local jobfirst_services=$(echo "$services_response" | jq -r 'to_entries[] | select(.key | startswith("jobfirst")) | .key')
    
    if [[ -n "$jobfirst_services" ]]; then
        info "✅ 服务已成功注册到Consul:"
        echo "$jobfirst_services" | while read -r service; do
            if [[ -n "$service" ]]; then
                info "  - $service"
            fi
        done
    else
        warn "⚠️  服务未注册到Consul"
    fi
    
    log "Consul注册检查完成"
}

# 显示启动信息
show_startup_info() {
    log "显示启动信息..."
    
    # 从配置文件读取端口
    local server_port=$(grep -A 5 "server:" "$CONFIG_FILE" | grep "port:" | awk '{print $2}' | tr -d '"')
    if [[ -z "$server_port" ]]; then
        server_port=8600
    fi
    
    local server_pid=$(cat "$PID_FILE" 2>/dev/null || echo "unknown")
    
    echo
    echo "=========================================="
    echo "🎉 增强服务器启动成功！"
    echo "=========================================="
    echo
    echo "📋 服务信息:"
    echo "  服务器PID: $server_pid"
    echo "  服务端口: $server_port"
    echo "  服务地址: http://localhost:$server_port"
    echo
    echo "🌐 主要端点:"
    echo "  健康检查: http://localhost:$server_port/health"
    echo "  API文档: http://localhost:$server_port/api-docs"
    echo "  超级管理员: http://localhost:$server_port/api/v1/super-admin/public/status"
    echo
    echo "🔧 管理工具:"
    echo "  查看日志: tail -f $LOG_FILE"
    echo "  停止服务: $PROJECT_ROOT/scripts/stop-enhanced-server.sh"
    echo "  重启服务: $PROJECT_ROOT/scripts/restart-enhanced-server.sh"
    echo
    echo "📝 日志文件: $LOG_FILE"
    echo "📊 PID文件: $PID_FILE"
    echo
    echo "🚀 新增功能:"
    echo "  ✅ 完整RBAC权限系统"
    echo "  ✅ 超级管理员管理"
    echo "  ✅ Consul服务注册"
    echo "  ✅ 增强的API端点"
    echo "  ✅ 自动健康检查"
    echo
    echo "=========================================="
}

# 主函数
main() {
    echo "=========================================="
    echo "🚀 JobFirst增强服务器启动工具"
    echo "=========================================="
    echo
    
    # 创建日志目录
    mkdir -p "$(dirname "$LOG_FILE")"
    
    # 执行启动步骤
    check_environment
    check_dependencies
    check_service_status
    check_ports
    build_project
    start_server
    verify_server
    check_consul_registration
    show_startup_info
    
    log "增强服务器启动完成"
}

# 错误处理
trap 'error "启动失败，请检查日志: $LOG_FILE"' ERR

# 执行主函数
main "$@"
