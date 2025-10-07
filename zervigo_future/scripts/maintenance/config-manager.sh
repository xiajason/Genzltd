#!/bin/bash

# 腾讯云微服务配置管理脚本
# 用于统一管理所有服务的配置文件

set -e

# 配置
DEPLOY_DIR="/opt/jobfirst"
CONFIG_DIR="$DEPLOY_DIR/configs"
BACKUP_DIR="$DEPLOY_DIR/backups"
LOG_FILE="$DEPLOY_DIR/logs/config-manager.log"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# 信息输出
info() {
    echo -e "${BLUE}信息: $1${NC}"
    log "INFO: $1"
}

# 创建配置目录结构
create_config_structure() {
    log "创建配置目录结构"
    
    mkdir -p "$CONFIG_DIR"/{dev,prod,test}
    mkdir -p "$CONFIG_DIR"/{dev,prod,test}/{basic-server,user-service,ai-service,resume,company-service,notification-service,banner-service,statistics-service,template-service}
    mkdir -p "$(dirname "$LOG_FILE")"
    
    success "配置目录结构创建完成"
}

# 收集当前配置
collect_configs() {
    local env=${1:-"current"}
    
    log "收集当前配置到环境: $env"
    
    local target_dir="$CONFIG_DIR/$env"
    
    # 收集各服务配置
    for service in basic-server user-service ai-service resume company-service notification-service banner-service statistics-service template-service; do
        local service_dir="$DEPLOY_DIR/$service"
        local config_dir="$target_dir/$service"
        
        if [ -d "$service_dir" ]; then
            mkdir -p "$config_dir"
            
            # 复制配置文件
            cp "$service_dir"/*.env "$config_dir/" 2>/dev/null || true
            cp "$service_dir"/*.yaml "$config_dir/" 2>/dev/null || true
            cp "$service_dir"/*.json "$config_dir/" 2>/dev/null || true
            cp "$service_dir"/*.toml "$config_dir/" 2>/dev/null || true
            
            log "收集服务配置: $service"
        fi
    done
    
    # 收集全局配置
    cp "$DEPLOY_DIR"/*.yaml "$target_dir/" 2>/dev/null || true
    cp "$DEPLOY_DIR"/*.env "$target_dir/" 2>/dev/null || true
    
    # 创建配置信息文件
    cat > "$target_dir/config.info" << EOF
环境: $env
收集时间: $(date)
Git提交: $(cd "$DEPLOY_DIR" && git rev-parse HEAD 2>/dev/null || echo "N/A")
服务数量: $(ls -1 "$target_dir" | grep -v "config.info" | wc -l)
EOF
    
    success "配置收集完成: $env"
}

# 部署配置到服务
deploy_configs() {
    local env=$1
    local service=${2:-"all"}
    
    if [ -z "$env" ]; then
        error_exit "请指定环境 (dev/prod/test)"
    fi
    
    local source_dir="$CONFIG_DIR/$env"
    if [ ! -d "$source_dir" ]; then
        error_exit "环境 $env 的配置不存在"
    fi
    
    log "部署配置: $env 到服务: $service"
    
    if [ "$service" = "all" ]; then
        # 部署所有服务配置
        for svc in basic-server user-service ai-service resume company-service notification-service banner-service statistics-service template-service; do
            deploy_service_config "$env" "$svc"
        done
    else
        deploy_service_config "$env" "$service"
    fi
    
    success "配置部署完成: $env -> $service"
}

# 部署单个服务配置
deploy_service_config() {
    local env=$1
    local service=$2
    
    local source_dir="$CONFIG_DIR/$env/$service"
    local target_dir="$DEPLOY_DIR/$service"
    
    if [ ! -d "$source_dir" ]; then
        warning "服务 $service 在环境 $env 中没有配置"
        return 0
    fi
    
    if [ ! -d "$target_dir" ]; then
        warning "目标服务目录不存在: $target_dir"
        return 0
    fi
    
    # 备份当前配置
    mkdir -p "$target_dir/.config-backup"
    cp "$target_dir"/*.env "$target_dir/.config-backup/" 2>/dev/null || true
    cp "$target_dir"/*.yaml "$target_dir/.config-backup/" 2>/dev/null || true
    cp "$target_dir"/*.json "$target_dir/.config-backup/" 2>/dev/null || true
    cp "$target_dir"/*.toml "$target_dir/.config-backup/" 2>/dev/null || true
    
    # 部署新配置
    cp "$source_dir"/*.env "$target_dir/" 2>/dev/null || true
    cp "$source_dir"/*.yaml "$target_dir/" 2>/dev/null || true
    cp "$source_dir"/*.json "$target_dir/" 2>/dev/null || true
    cp "$source_dir"/*.toml "$target_dir/" 2>/dev/null || true
    
    log "部署服务配置: $service"
}

# 比较配置差异
compare_configs() {
    local env1=$1
    local env2=$2
    local service=${3:-"all"}
    
    if [ -z "$env1" ] || [ -z "$env2" ]; then
        error_exit "请指定两个环境进行比较"
    fi
    
    log "比较配置差异: $env1 vs $env2"
    
    if [ "$service" = "all" ]; then
        for svc in basic-server user-service ai-service resume company-service notification-service banner-service statistics-service template-service; do
            compare_service_configs "$env1" "$env2" "$svc"
        done
    else
        compare_service_configs "$env1" "$env2" "$service"
    fi
}

# 比较单个服务配置
compare_service_configs() {
    local env1=$1
    local env2=$2
    local service=$3
    
    local config1="$CONFIG_DIR/$env1/$service"
    local config2="$CONFIG_DIR/$env2/$service"
    
    if [ ! -d "$config1" ] || [ ! -d "$config2" ]; then
        warning "服务 $service 在某个环境中没有配置"
        return 0
    fi
    
    echo "=== $service 配置差异 ==="
    diff -r "$config1" "$config2" || true
    echo ""
}

# 列出所有环境
list_environments() {
    log "列出所有环境"
    echo "可用环境:"
    ls -la "$CONFIG_DIR" | grep "^d" | awk '{print $9}' | grep -v "^\.$" | grep -v "^\.\.$"
}

# 显示环境信息
show_environment_info() {
    local env=$1
    
    if [ -z "$env" ]; then
        error_exit "请指定环境"
    fi
    
    local env_dir="$CONFIG_DIR/$env"
    if [ ! -d "$env_dir" ]; then
        error_exit "环境 $env 不存在"
    fi
    
    echo "环境信息: $env"
    echo "================"
    
    if [ -f "$env_dir/config.info" ]; then
        cat "$env_dir/config.info"
    fi
    
    echo ""
    echo "服务配置:"
    ls -la "$env_dir" | grep "^d" | awk '{print $9}' | grep -v "config.info"
}

# 清理旧配置
cleanup_old_configs() {
    local keep_count=${1:-3}
    
    log "清理旧配置，保留最新 $keep_count 个环境"
    
    # 这里可以实现更复杂的清理逻辑
    # 目前只是显示信息
    info "配置清理功能待实现"
}

# 主函数
main() {
    create_config_structure
    
    case "$1" in
        "collect")
            collect_configs "$2"
            ;;
        "deploy")
            deploy_configs "$2" "$3"
            ;;
        "compare")
            compare_configs "$2" "$3" "$4"
            ;;
        "list")
            list_environments
            ;;
        "info")
            show_environment_info "$2"
            ;;
        "cleanup")
            cleanup_old_configs "$2"
            ;;
        *)
            echo "用法: $0 {collect|deploy|compare|list|info|cleanup} [options]"
            echo ""
            echo "命令说明:"
            echo "  collect <env>              - 收集当前配置到指定环境"
            echo "  deploy <env> [service]     - 部署指定环境的配置"
            echo "  compare <env1> <env2> [service] - 比较两个环境的配置差异"
            echo "  list                       - 列出所有环境"
            echo "  info <env>                 - 显示环境信息"
            echo "  cleanup [count]            - 清理旧配置"
            echo ""
            echo "示例:"
            echo "  $0 collect prod            # 收集当前配置到生产环境"
            echo "  $0 deploy dev basic-server # 部署开发环境配置到API Gateway"
            echo "  $0 compare dev prod        # 比较开发和生产环境配置"
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"
