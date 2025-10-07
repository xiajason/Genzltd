#!/bin/bash

# Looma CRM AI重构项目智能关闭脚本
# 创建时间: 2025年9月23日
# 版本: v1.0

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
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

log_step() {
    echo -e "${PURPLE}[STEP]${NC} $1"
}

# 获取脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LOGS_DIR="$PROJECT_ROOT/logs"
BACKUPS_DIR="$PROJECT_ROOT/backups"

# 创建必要的目录
mkdir -p "$LOGS_DIR" "$BACKUPS_DIR"

# 生成时间戳
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="$LOGS_DIR/shutdown_$TIMESTAMP.log"
REPORT_FILE="$LOGS_DIR/shutdown_report_$TIMESTAMP.txt"

# 日志记录函数
log_to_file() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 检查端口是否被占用
check_port() {
    local port=$1
    local service_name=$2
    
    if lsof -i :$port > /dev/null 2>&1; then
        return 0  # 端口被占用
    else
        return 1  # 端口未被占用
    fi
}

# 获取端口上的进程PID
get_pid_by_port() {
    local port=$1
    lsof -ti :$port 2>/dev/null || echo ""
}

# 优雅关闭进程
graceful_shutdown() {
    local pid=$1
    local service_name=$2
    local port=$3
    
    if [ -z "$pid" ]; then
        log_warning "$service_name 未运行"
        return 0
    fi
    
    log_info "正在优雅关闭 $service_name (PID: $pid)..."
    log_to_file "正在优雅关闭 $service_name (PID: $pid)"
    
    # 发送SIGTERM信号
    if kill -TERM "$pid" 2>/dev/null; then
        # 等待进程优雅关闭
        local count=0
        while kill -0 "$pid" 2>/dev/null && [ $count -lt 10 ]; do
            sleep 1
            count=$((count + 1))
        done
        
        # 检查是否成功关闭
        if ! kill -0 "$pid" 2>/dev/null; then
            log_success "$service_name 已优雅关闭"
            log_to_file "$service_name 已优雅关闭"
            return 0
        else
            log_warning "$service_name 优雅关闭超时，将强制关闭"
            log_to_file "$service_name 优雅关闭超时，将强制关闭"
            return 1
        fi
    else
        log_error "无法发送SIGTERM信号给 $service_name (PID: $pid)"
        log_to_file "无法发送SIGTERM信号给 $service_name (PID: $pid)"
        return 1
    fi
}

# 强制关闭进程
force_shutdown() {
    local pid=$1
    local service_name=$2
    local port=$3
    
    log_info "正在强制关闭 $service_name (PID: $pid)..."
    log_to_file "正在强制关闭 $service_name (PID: $pid)"
    
    # 发送SIGKILL信号
    if kill -KILL "$pid" 2>/dev/null; then
        sleep 2
        if ! kill -0 "$pid" 2>/dev/null; then
            log_success "$service_name 已强制关闭"
            log_to_file "$service_name 已强制关闭"
            return 0
        else
            log_error "无法强制关闭 $service_name (PID: $pid)"
            log_to_file "无法强制关闭 $service_name (PID: $pid)"
            return 1
        fi
    else
        log_error "无法发送SIGKILL信号给 $service_name (PID: $pid)"
        log_to_file "无法发送SIGKILL信号给 $service_name (PID: $pid)"
        return 1
    fi
}

# 关闭服务
shutdown_service() {
    local service_name=$1
    local port=$2
    
    log_info "检查 $service_name (端口: $port)..."
    log_to_file "检查 $service_name (端口: $port)"
    
    if ! check_port "$port" "$service_name"; then
        log_info "$service_name 未运行，跳过"
        log_to_file "$service_name 未运行，跳过"
        return 0
    fi
    
    # 获取进程PID
    local pid=$(get_pid_by_port "$port")
    if [ -z "$pid" ]; then
        log_warning "$service_name 端口 $port 被占用但无法获取PID"
        log_to_file "$service_name 端口 $port 被占用但无法获取PID"
        return 1
    fi
    
    # 尝试优雅关闭
    if graceful_shutdown "$pid" "$service_name" "$port"; then
        # 等待端口释放
        local count=0
        while check_port "$port" "$service_name" && [ $count -lt 5 ]; do
            sleep 1
            count=$((count + 1))
        done
        
        if ! check_port "$port" "$service_name"; then
            log_success "$service_name 端口 $port 已释放"
            log_to_file "$service_name 端口 $port 已释放"
            return 0
        else
            log_warning "$service_name 端口 $port 未释放"
            log_to_file "$service_name 端口 $port 未释放"
            return 1
        fi
    else
        # 强制关闭
        if force_shutdown "$pid" "$service_name" "$port"; then
            # 等待端口释放
            local count=0
            while check_port "$port" "$service_name" && [ $count -lt 5 ]; do
                sleep 1
                count=$((count + 1))
            done
            
            if ! check_port "$port" "$service_name"; then
                log_success "$service_name 端口 $port 已释放"
                log_to_file "$service_name 端口 $port 已释放"
                return 0
            else
                log_error "$service_name 端口 $port 未释放"
                log_to_file "$service_name 端口 $port 未释放"
                return 1
            fi
        else
            return 1
        fi
    fi
}

# 关闭Docker服务
shutdown_docker_services() {
    log_step "关闭Docker服务..."
    log_to_file "开始关闭Docker服务"
    
    # 检查Docker是否运行
    if ! docker info > /dev/null 2>&1; then
        log_info "Docker未运行，跳过Docker服务关闭"
        log_to_file "Docker未运行，跳过Docker服务关闭"
        return 0
    fi
    
    # 关闭Looma CRM AI重构项目的Docker服务
    if [ -f "$PROJECT_ROOT/docker-compose.yml" ]; then
        log_info "关闭Looma CRM AI重构项目Docker服务..."
        log_to_file "关闭Looma CRM AI重构项目Docker服务"
        
        cd "$PROJECT_ROOT"
        if docker-compose down 2>/dev/null; then
            log_success "Docker服务已关闭"
            log_to_file "Docker服务已关闭"
        else
            log_warning "Docker服务关闭失败或未运行"
            log_to_file "Docker服务关闭失败或未运行"
        fi
    else
        log_info "未找到docker-compose.yml文件"
        log_to_file "未找到docker-compose.yml文件"
    fi
}

# 清理Python进程
cleanup_python_processes() {
    log_step "清理Python进程..."
    log_to_file "开始清理Python进程"
    
    # 查找Looma CRM相关的Python进程
    local looma_pids=$(pgrep -f "looma_crm/app.py" 2>/dev/null || echo "")
    
    if [ -n "$looma_pids" ]; then
        log_info "发现Looma CRM Python进程: $looma_pids"
        log_to_file "发现Looma CRM Python进程: $looma_pids"
        
        for pid in $looma_pids; do
            if graceful_shutdown "$pid" "Looma CRM Python进程" "N/A"; then
                log_success "Looma CRM Python进程 $pid 已关闭"
                log_to_file "Looma CRM Python进程 $pid 已关闭"
            else
                if force_shutdown "$pid" "Looma CRM Python进程" "N/A"; then
                    log_success "Looma CRM Python进程 $pid 已强制关闭"
                    log_to_file "Looma CRM Python进程 $pid 已强制关闭"
                else
                    log_error "无法关闭Looma CRM Python进程 $pid"
                    log_to_file "无法关闭Looma CRM Python进程 $pid"
                fi
            fi
        done
    else
        log_info "未发现Looma CRM Python进程"
        log_to_file "未发现Looma CRM Python进程"
    fi
}

# 日志管理
manage_logs() {
    log_step "智能日志管理..."
    log_to_file "开始智能日志管理"
    
    # 归档当前关闭日志
    if [ -f "$LOG_FILE" ]; then
        cp "$LOG_FILE" "$BACKUPS_DIR/"
        log_info "关闭日志已归档: $BACKUPS_DIR/shutdown_$TIMESTAMP.log"
        log_to_file "关闭日志已归档: $BACKUPS_DIR/shutdown_$TIMESTAMP.log"
    fi
    
    # 清理旧日志文件（保留最近7天）
    find "$LOGS_DIR" -name "shutdown_*.log" -mtime +7 -delete 2>/dev/null || true
    find "$BACKUPS_DIR" -name "shutdown_*.log" -mtime +7 -delete 2>/dev/null || true
    
    # 压缩大日志文件
    find "$LOGS_DIR" -name "*.log" -size +10M -exec gzip {} \; 2>/dev/null || true
    
    # 清理临时文件
    find "$PROJECT_ROOT" -name "*.pyc" -delete 2>/dev/null || true
    find "$PROJECT_ROOT" -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
    
    log_success "日志管理完成"
    log_to_file "日志管理完成"
}

# 验证关闭状态
verify_shutdown() {
    log_step "验证关闭状态..."
    log_to_file "开始验证关闭状态"
    
    local failed_services=()
    
    # 检查Looma CRM端口
    if check_port 8888 "Looma CRM"; then
        failed_services+=("Looma CRM (8888)")
    fi
    
    # 检查AI服务端口
    for port in 8206 8207 8208 8209 8210 8211 8212 8213; do
        if check_port "$port" "AI Service $port"; then
            failed_services+=("AI Service ($port)")
        fi
    done
    
    if [ ${#failed_services[@]} -eq 0 ]; then
        log_success "所有服务已成功关闭，所有端口已释放"
        log_to_file "所有服务已成功关闭，所有端口已释放"
        return 0
    else
        log_error "以下服务未能成功关闭:"
        log_to_file "以下服务未能成功关闭:"
        for service in "${failed_services[@]}"; do
            log_error "  - $service"
            log_to_file "  - $service"
        done
        return 1
    fi
}

# 生成关闭报告
generate_report() {
    log_step "生成关闭报告..."
    log_to_file "开始生成关闭报告"
    
    cat > "$REPORT_FILE" << EOF
Looma CRM AI重构项目关闭报告
=====================================

关闭时间: $(date '+%Y-%m-%d %H:%M:%S')
关闭模式: 智能优雅关闭
项目路径: $PROJECT_ROOT

关闭的服务:
- Looma CRM主服务 (8888)
- AI网关服务 (8206)
- 简历处理服务 (8207)
- 职位匹配服务 (8208)
- 智能对话服务 (8209)
- 向量搜索服务 (8210)
- 认证授权服务 (8211)
- 监控管理服务 (8212)
- 配置管理服务 (8213)

关闭状态: $(if verify_shutdown > /dev/null 2>&1; then echo "成功"; else echo "部分失败"; fi)

日志文件: $LOG_FILE
备份目录: $BACKUPS_DIR

EOF
    
    log_success "关闭报告已生成: $REPORT_FILE"
    log_to_file "关闭报告已生成: $REPORT_FILE"
}

# 主函数
main() {
    echo "=========================================="
    echo "🛑 Looma CRM AI重构项目智能关闭工具"
    echo "=========================================="
    echo ""
    
    log_info "开始智能关闭流程..."
    log_info "关闭模式: 优雅关闭"
    log_to_file "开始智能关闭流程"
    
    # 关闭Docker服务
    shutdown_docker_services
    
    # 关闭Looma CRM主服务
    log_step "关闭Looma CRM服务..."
    shutdown_service "Looma CRM" 8888
    
    # 关闭AI服务
    log_step "关闭AI服务..."
    shutdown_service "AI网关服务" 8206
    shutdown_service "简历处理服务" 8207
    shutdown_service "职位匹配服务" 8208
    shutdown_service "智能对话服务" 8209
    shutdown_service "向量搜索服务" 8210
    shutdown_service "认证授权服务" 8211
    shutdown_service "监控管理服务" 8212
    shutdown_service "配置管理服务" 8213
    
    # 清理Python进程
    cleanup_python_processes
    
    # 智能日志管理
    manage_logs
    
    # 验证关闭状态
    if verify_shutdown; then
        log_success "所有服务已成功关闭"
    else
        log_warning "部分服务未能成功关闭"
    fi
    
    # 生成关闭报告
    generate_report
    
    echo ""
    echo "=========================================="
    echo "✅ Looma CRM AI重构项目智能关闭完成"
    echo "=========================================="
    echo ""
    log_success "系统已安全关闭，端口已释放，日志已优化"
    log_info "关闭日志: $LOG_FILE"
    log_info "关闭报告: $REPORT_FILE"
}

# 信号处理
trap 'log_error "关闭过程被中断"; exit 1' INT TERM

# 执行主函数
main "$@"
