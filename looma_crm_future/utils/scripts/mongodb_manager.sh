#!/bin/bash

# MongoDB管理脚本
# 创建时间: 2025年9月24日
# 版本: v1.0

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
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

log_header() {
    echo -e "${CYAN}$1${NC}"
}

# 获取脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# 显示帮助信息
show_help() {
    echo "MongoDB管理脚本"
    echo "用法: $0 [命令]"
    echo ""
    echo "命令:"
    echo "  start     启动MongoDB服务"
    echo "  stop      停止MongoDB服务"
    echo "  restart   重启MongoDB服务"
    echo "  status    检查MongoDB服务状态"
    echo "  install   安装MongoDB"
    echo "  test      测试MongoDB连接"
    echo "  backup    备份MongoDB数据"
    echo "  restore   恢复MongoDB数据"
    echo "  help      显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 start"
    echo "  $0 status"
    echo "  $0 test"
}

# 检查MongoDB是否安装
check_mongodb_installed() {
    if command -v mongod >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# 安装MongoDB
install_mongodb() {
    log_step "安装MongoDB..."
    
    if check_mongodb_installed; then
        log_info "MongoDB已安装"
        return 0
    fi
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command -v brew >/dev/null 2>&1; then
            log_info "使用Homebrew安装MongoDB..."
            brew tap mongodb/brew
            brew install mongodb-community
            log_success "MongoDB安装完成"
        else
            log_error "请先安装Homebrew"
            return 1
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        log_info "使用apt安装MongoDB..."
        wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | sudo apt-key add -
        echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list
        sudo apt-get update
        sudo apt-get install -y mongodb-org
        log_success "MongoDB安装完成"
    else
        log_error "不支持的操作系统: $OSTYPE"
        return 1
    fi
}

# 启动MongoDB服务
start_mongodb() {
    log_step "启动MongoDB服务..."
    
    if ! check_mongodb_installed; then
        log_error "MongoDB未安装，请先运行: $0 install"
        return 1
    fi
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if brew services list | grep -q "mongodb.*started"; then
            log_info "MongoDB服务已在运行"
        else
            brew services start mongodb/brew/mongodb-community
            sleep 3
            
            if brew services list | grep -q "mongodb.*started"; then
                log_success "MongoDB服务启动成功"
            else
                log_error "MongoDB服务启动失败"
                return 1
            fi
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        if systemctl is-active --quiet mongod; then
            log_info "MongoDB服务已在运行"
        else
            sudo systemctl start mongod
            sleep 3
            
            if systemctl is-active --quiet mongod; then
                log_success "MongoDB服务启动成功"
            else
                log_error "MongoDB服务启动失败"
                return 1
            fi
        fi
    fi
}

# 停止MongoDB服务
stop_mongodb() {
    log_step "停止MongoDB服务..."
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if brew services list | grep -q "mongodb.*started"; then
            brew services stop mongodb/brew/mongodb-community
            sleep 2
            
            if ! brew services list | grep -q "mongodb.*started"; then
                log_success "MongoDB服务已停止"
            else
                log_error "MongoDB服务停止失败"
                return 1
            fi
        else
            log_info "MongoDB服务未运行"
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        if systemctl is-active --quiet mongod; then
            sudo systemctl stop mongod
            sleep 2
            
            if ! systemctl is-active --quiet mongod; then
                log_success "MongoDB服务已停止"
            else
                log_error "MongoDB服务停止失败"
                return 1
            fi
        else
            log_info "MongoDB服务未运行"
        fi
    fi
}

# 重启MongoDB服务
restart_mongodb() {
    log_step "重启MongoDB服务..."
    stop_mongodb
    sleep 2
    start_mongodb
}

# 检查MongoDB服务状态
check_mongodb_status() {
    log_step "检查MongoDB服务状态..."
    
    if ! check_mongodb_installed; then
        log_error "MongoDB未安装"
        return 1
    fi
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if brew services list | grep -q "mongodb.*started"; then
            log_success "MongoDB服务正在运行"
            
            # 获取MongoDB版本信息
            if command -v mongosh >/dev/null 2>&1; then
                local version=$(mongosh --version | head -n1)
                log_info "MongoDB版本: $version"
            fi
            
            # 检查端口
            if lsof -i :27017 >/dev/null 2>&1; then
                log_success "MongoDB端口27017正在监听"
            else
                log_warning "MongoDB端口27017未监听"
            fi
        else
            log_warning "MongoDB服务未运行"
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        if systemctl is-active --quiet mongod; then
            log_success "MongoDB服务正在运行"
            
            # 获取MongoDB版本信息
            if command -v mongosh >/dev/null 2>&1; then
                local version=$(mongosh --version | head -n1)
                log_info "MongoDB版本: $version"
            fi
            
            # 检查端口
            if netstat -tlnp 2>/dev/null | grep -q ":27017"; then
                log_success "MongoDB端口27017正在监听"
            else
                log_warning "MongoDB端口27017未监听"
            fi
        else
            log_warning "MongoDB服务未运行"
        fi
    fi
}

# 测试MongoDB连接
test_mongodb_connection() {
    log_step "测试MongoDB连接..."
    
    if ! check_mongodb_installed; then
        log_error "MongoDB未安装"
        return 1
    fi
    
    if command -v mongosh >/dev/null 2>&1; then
        if mongosh --eval "db.runCommand('ping')" --quiet >/dev/null 2>&1; then
            log_success "MongoDB连接测试成功"
            
            # 测试基本操作
            log_info "测试基本操作..."
            if mongosh --eval "db.adminCommand('listCollections')" --quiet >/dev/null 2>&1; then
                log_success "MongoDB基本操作测试成功"
            else
                log_warning "MongoDB基本操作测试失败"
            fi
        else
            log_error "MongoDB连接测试失败"
            return 1
        fi
    else
        log_error "mongosh命令不可用"
        return 1
    fi
}

# 备份MongoDB数据
backup_mongodb() {
    log_step "备份MongoDB数据..."
    
    if ! check_mongodb_installed; then
        log_error "MongoDB未安装"
        return 1
    fi
    
    local backup_dir="$PROJECT_DIR/backups/mongodb"
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_path="$backup_dir/mongodb_backup_$timestamp"
    
    mkdir -p "$backup_dir"
    
    if command -v mongodump >/dev/null 2>&1; then
        log_info "开始备份MongoDB数据到: $backup_path"
        mongodump --out "$backup_path"
        
        if [ $? -eq 0 ]; then
            log_success "MongoDB数据备份成功"
            log_info "备份路径: $backup_path"
        else
            log_error "MongoDB数据备份失败"
            return 1
        fi
    else
        log_error "mongodump命令不可用"
        return 1
    fi
}

# 恢复MongoDB数据
restore_mongodb() {
    log_step "恢复MongoDB数据..."
    
    if ! check_mongodb_installed; then
        log_error "MongoDB未安装"
        return 1
    fi
    
    local backup_dir="$PROJECT_DIR/backups/mongodb"
    
    if [ ! -d "$backup_dir" ]; then
        log_error "备份目录不存在: $backup_dir"
        return 1
    fi
    
    # 列出可用的备份
    local backups=($(ls -1 "$backup_dir" 2>/dev/null | grep "mongodb_backup_" | sort -r))
    
    if [ ${#backups[@]} -eq 0 ]; then
        log_error "未找到可用的备份"
        return 1
    fi
    
    log_info "可用的备份:"
    for i in "${!backups[@]}"; do
        echo "  $((i+1)). ${backups[$i]}"
    done
    
    log_info "请选择要恢复的备份 (1-${#backups[@]}):"
    read -r choice
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#backups[@]} ]; then
        local selected_backup="${backups[$((choice-1))]}"
        local backup_path="$backup_dir/$selected_backup"
        
        log_info "开始恢复MongoDB数据从: $backup_path"
        
        if command -v mongorestore >/dev/null 2>&1; then
            mongorestore "$backup_path"
            
            if [ $? -eq 0 ]; then
                log_success "MongoDB数据恢复成功"
            else
                log_error "MongoDB数据恢复失败"
                return 1
            fi
        else
            log_error "mongorestore命令不可用"
            return 1
        fi
    else
        log_error "无效的选择"
        return 1
    fi
}

# 主函数
main() {
    case "${1:-help}" in
        start)
            start_mongodb
            ;;
        stop)
            stop_mongodb
            ;;
        restart)
            restart_mongodb
            ;;
        status)
            check_mongodb_status
            ;;
        install)
            install_mongodb
            ;;
        test)
            test_mongodb_connection
            ;;
        backup)
            backup_mongodb
            ;;
        restore)
            restore_mongodb
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "未知命令: $1"
            show_help
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"
