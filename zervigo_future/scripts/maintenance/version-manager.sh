#!/bin/bash

# 腾讯云微服务版本管理脚本
# 用于版本跟踪、部署和回滚

set -e

# 配置
DEPLOY_DIR="/opt/jobfirst"
BACKUP_DIR="/opt/jobfirst/backups"
LOG_FILE="/opt/jobfirst/logs/version-manager.log"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 日志函数
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# 错误处理
error_exit() {
    echo -e "${RED}错误: $1${NC}" >&2
    log "ERROR: $1"
    exit 1
}

# 成功信息
success() {
    echo -e "${GREEN}成功: $1${NC}"
    log "SUCCESS: $1"
}

# 警告信息
warning() {
    echo -e "${YELLOW}警告: $1${NC}"
    log "WARNING: $1"
}

# 创建必要目录
create_directories() {
    mkdir -p "$BACKUP_DIR"
    mkdir -p "$(dirname "$LOG_FILE")"
    log "创建必要目录"
}

# 创建版本快照
create_snapshot() {
    local version=$1
    if [ -z "$version" ]; then
        version=$(date '+%Y%m%d_%H%M%S')
    fi
    
    log "创建版本快照: $version"
    
    # 创建备份目录
    local backup_path="$BACKUP_DIR/v$version"
    mkdir -p "$backup_path"
    
    # 备份服务文件
    for service in basic-server user-service ai-service resume company-service notification-service banner-service statistics-service template-service; do
        if [ -d "$DEPLOY_DIR/$service" ]; then
            cp -r "$DEPLOY_DIR/$service" "$backup_path/"
            log "备份服务: $service"
        fi
    done
    
    # 备份配置文件
    cp "$DEPLOY_DIR"/*.yaml "$backup_path/" 2>/dev/null || true
    cp "$DEPLOY_DIR"/*.env "$backup_path/" 2>/dev/null || true
    
    # 创建版本信息文件
    cat > "$backup_path/version.info" << EOF
版本: $version
创建时间: $(date)
Git提交: $(cd "$DEPLOY_DIR" && git rev-parse HEAD 2>/dev/null || echo "N/A")
服务状态: $(ps aux | grep -E '(main|user-service|ai-service)' | grep -v grep | wc -l) 个服务运行中
EOF
    
    success "版本快照创建完成: $version"
    echo "$version" > "$BACKUP_DIR/latest_version"
}

# 部署新版本
deploy_version() {
    local version=$1
    if [ -z "$version" ]; then
        error_exit "请指定版本号"
    fi
    
    local backup_path="$BACKUP_DIR/v$version"
    if [ ! -d "$backup_path" ]; then
        error_exit "版本 $version 不存在"
    fi
    
    log "部署版本: $version"
    
    # 停止所有服务
    stop_all_services
    
    # 恢复文件
    for service in basic-server user-service ai-service resume company-service notification-service banner-service statistics-service template-service; do
        if [ -d "$backup_path/$service" ]; then
            rm -rf "$DEPLOY_DIR/$service"
            cp -r "$backup_path/$service" "$DEPLOY_DIR/"
            log "恢复服务: $service"
        fi
    done
    
    # 恢复配置文件
    cp "$backup_path"/*.yaml "$DEPLOY_DIR/" 2>/dev/null || true
    cp "$backup_path"/*.env "$DEPLOY_DIR/" 2>/dev/null || true
    
    # 重新编译和启动服务
    build_and_start_services
    
    success "版本 $version 部署完成"
}

# 回滚到指定版本
rollback_to() {
    local version=$1
    if [ -z "$version" ]; then
        error_exit "请指定回滚版本号"
    fi
    
    log "回滚到版本: $version"
    deploy_version "$version"
    success "回滚到版本 $version 完成"
}

# 停止所有服务
stop_all_services() {
    log "停止所有服务"
    
    # 停止Go服务
    pkill -f "main" 2>/dev/null || true
    pkill -f "user-service" 2>/dev/null || true
    pkill -f "ai-service" 2>/dev/null || true
    
    # 等待服务停止
    sleep 3
    
    success "所有服务已停止"
}

# 构建和启动服务
build_and_start_services() {
    log "构建和启动服务"
    
    # 启动基础服务
    cd "$DEPLOY_DIR/basic-server"
    if [ -f "main.go" ]; then
        go build -o main main.go rbac_apis.go
        nohup ./main > basic-server.log 2>&1 &
        log "启动 basic-server"
    fi
    
    # 启动用户服务
    cd "$DEPLOY_DIR/user-service"
    if [ -f "main.go" ]; then
        go build -o user-service main.go
        nohup ./user-service > user-service.log 2>&1 &
        log "启动 user-service"
    fi
    
    # 启动AI服务
    cd "$DEPLOY_DIR/ai-service"
    if [ -f "ai_service.py" ]; then
        nohup python3 ai_service.py > ai-service.log 2>&1 &
        log "启动 ai-service"
    fi
    
    success "服务启动完成"
}

# 列出所有版本
list_versions() {
    log "列出所有版本"
    echo "可用版本:"
    ls -la "$BACKUP_DIR" | grep "^d" | grep "v" | awk '{print $9}' | sort -r
}

# 显示当前版本信息
show_current_version() {
    if [ -f "$BACKUP_DIR/latest_version" ]; then
        local version=$(cat "$BACKUP_DIR/latest_version")
        echo "当前版本: $version"
        if [ -f "$BACKUP_DIR/v$version/version.info" ]; then
            cat "$BACKUP_DIR/v$version/version.info"
        fi
    else
        echo "未找到版本信息"
    fi
}

# 清理旧版本
cleanup_old_versions() {
    local keep_count=${1:-5}
    log "清理旧版本，保留最新 $keep_count 个版本"
    
    local versions=($(ls -t "$BACKUP_DIR" | grep "^v" | tail -n +$((keep_count + 1))))
    
    for version in "${versions[@]}"; do
        rm -rf "$BACKUP_DIR/$version"
        log "删除旧版本: $version"
    done
    
    success "清理完成"
}

# 主函数
main() {
    create_directories
    
    case "$1" in
        "snapshot")
            create_snapshot "$2"
            ;;
        "deploy")
            deploy_version "$2"
            ;;
        "rollback")
            rollback_to "$2"
            ;;
        "list")
            list_versions
            ;;
        "current")
            show_current_version
            ;;
        "cleanup")
            cleanup_old_versions "$2"
            ;;
        "stop")
            stop_all_services
            ;;
        "start")
            build_and_start_services
            ;;
        "restart")
            stop_all_services
            build_and_start_services
            ;;
        *)
            echo "用法: $0 {snapshot|deploy|rollback|list|current|cleanup|stop|start|restart} [version]"
            echo ""
            echo "命令说明:"
            echo "  snapshot [version]  - 创建版本快照"
            echo "  deploy <version>    - 部署指定版本"
            echo "  rollback <version>  - 回滚到指定版本"
            echo "  list               - 列出所有版本"
            echo "  current            - 显示当前版本信息"
            echo "  cleanup [count]    - 清理旧版本(默认保留5个)"
            echo "  stop               - 停止所有服务"
            echo "  start              - 启动所有服务"
            echo "  restart            - 重启所有服务"
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"
