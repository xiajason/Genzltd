#!/bin/bash

# JobFirst系统回滚点管理脚本
# 用于创建、列出、删除回滚点

set -e

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
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

# 显示帮助信息
show_help() {
    echo -e "${CYAN}JobFirst系统回滚点管理脚本${NC}"
    echo ""
    echo "用法: $0 <命令> [选项]"
    echo ""
    echo "命令:"
    echo "  create [名称]     创建新的回滚点"
    echo "  list             列出所有回滚点"
    echo "  info <回滚点ID>   显示回滚点详细信息"
    echo "  delete <回滚点ID> 删除指定的回滚点"
    echo "  cleanup          清理过期的回滚点"
    echo "  help             显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 create"
    echo "  $0 create \"AI服务集成完成\""
    echo "  $0 list"
    echo "  $0 info rollback_point_20250906_131058"
    echo "  $0 delete rollback_point_20250906_131058"
    echo "  $0 cleanup"
}

# 创建回滚点
create_rollback_point() {
    local name="$1"
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local rollback_id="rollback_point_${timestamp}"
    local rollback_path="backup/$rollback_id"
    
    log_info "创建回滚点: $rollback_id"
    if [ -n "$name" ]; then
        log_info "回滚点描述: $name"
    fi
    
    # 创建回滚点目录
    mkdir -p "$rollback_path"
    mkdir -p "$rollback_path/database_backup"
    mkdir -p "$rollback_path/config_backup"
    
    # 备份代码
    log_info "备份代码文件..."
    cp -r backend "$rollback_path/" 2>/dev/null || log_warning "backend目录不存在"
    cp -r frontend-taro "$rollback_path/" 2>/dev/null || log_warning "frontend-taro目录不存在"
    cp -r scripts "$rollback_path/" 2>/dev/null || log_warning "scripts目录不存在"
    cp -r nginx "$rollback_path/" 2>/dev/null || log_warning "nginx目录不存在"
    
    # 备份配置
    log_info "备份配置文件..."
    cp docker-compose.yml "$rollback_path/" 2>/dev/null || log_warning "docker-compose.yml不存在"
    cp -r consul "$rollback_path/" 2>/dev/null || log_warning "consul目录不存在"
    
    # 备份数据库
    log_info "备份数据库..."
    
    # MySQL备份
    if brew services list | grep mysql | grep started > /dev/null; then
        mysqldump -u root --ignore-table=jobfirst.user_resume_stats --ignore-table=jobfirst.invalid_view jobfirst > "$rollback_path/database_backup/mysql_jobfirst_${timestamp}.sql" 2>/dev/null || log_warning "MySQL备份失败"
    else
        log_warning "MySQL服务未运行，跳过备份"
    fi
    
    # PostgreSQL备份
    if brew services list | grep postgresql | grep started > /dev/null; then
        pg_dump -U szjason72 jobfirst_vector > "$rollback_path/database_backup/postgres_jobfirst_vector_${timestamp}.sql" 2>/dev/null || log_warning "PostgreSQL备份失败"
    else
        log_warning "PostgreSQL服务未运行，跳过备份"
    fi
    
    # Redis备份
    if brew services list | grep redis | grep started > /dev/null; then
        redis-cli --rdb "$rollback_path/database_backup/redis_jobfirst_${timestamp}.rdb" 2>/dev/null || log_warning "Redis备份失败"
    else
        log_warning "Redis服务未运行，跳过备份"
    fi
    
    # 备份系统配置
    log_info "备份系统配置..."
    env > "$rollback_path/config_backup/environment_variables_${timestamp}.txt"
    brew services list > "$rollback_path/config_backup/brew_services_${timestamp}.txt"
    lsof -i -P | grep LISTEN > "$rollback_path/config_backup/port_usage_${timestamp}.txt"
    
    # 创建元数据文件
    cat > "$rollback_path/ROLLBACK_METADATA.md" << EOF
# JobFirst系统回滚点元数据

**回滚点ID**: $rollback_id  
**创建时间**: $(date)  
**创建人员**: $(whoami)  
**系统状态**: ✅ 稳定运行状态  

## 📋 回滚点描述

${name:-"系统回滚点"}

## 📁 备份内容清单

### 1. 代码快照
- \`backend/\` - 后端微服务代码
- \`frontend-taro/\` - Taro前端代码
- \`scripts/\` - 启动和管理脚本
- \`nginx/\` - Nginx配置

### 2. 配置文件
- \`docker-compose.yml\` - Docker编排配置
- \`consul/\` - Consul服务发现配置

### 3. 数据库备份
- \`mysql_jobfirst_${timestamp}.sql\` - MySQL业务数据
- \`postgres_jobfirst_vector_${timestamp}.sql\` - PostgreSQL向量数据
- \`redis_jobfirst_${timestamp}.rdb\` - Redis缓存数据

### 4. 系统配置
- \`environment_variables_${timestamp}.txt\` - 环境变量
- \`brew_services_${timestamp}.txt\` - 服务状态
- \`port_usage_${timestamp}.txt\` - 端口占用情况

## 🔄 回滚操作

使用回滚脚本进行回滚：

\`\`\`bash
# 执行回滚
./scripts/rollback-to-point.sh $rollback_id

# 验证回滚结果
./scripts/start-dev-environment.sh health
\`\`\`

---

**回滚点创建完成时间**: $(date)  
**系统状态**: ✅ 稳定运行，可安全回滚  
EOF
    
    log_success "回滚点创建完成: $rollback_id"
    log_info "回滚点路径: $rollback_path"
    log_info "使用以下命令回滚到此点:"
    log_info "  ./scripts/rollback-to-point.sh $rollback_id"
}

# 列出所有回滚点
list_rollback_points() {
    log_info "可用的回滚点:"
    echo ""
    
    if [ ! -d "backup" ]; then
        log_warning "backup目录不存在"
        return 0
    fi
    
    local count=0
    for rollback_dir in backup/rollback_point_*; do
        if [ -d "$rollback_dir" ]; then
            local rollback_id=$(basename "$rollback_dir")
            local metadata_file="$rollback_dir/ROLLBACK_METADATA.md"
            
            if [ -f "$metadata_file" ]; then
                local created_time=$(grep "创建时间" "$metadata_file" | cut -d':' -f2- | sed 's/^ *//')
                local description=$(grep -A1 "回滚点描述" "$metadata_file" | tail -1 | sed 's/^ *//')
                
                echo -e "  ${CYAN}$rollback_id${NC}"
                echo -e "    创建时间: $created_time"
                echo -e "    描述: $description"
                echo ""
                ((count++))
            fi
        fi
    done
    
    if [ $count -eq 0 ]; then
        log_warning "没有找到回滚点"
    else
        log_info "共找到 $count 个回滚点"
    fi
}

# 显示回滚点详细信息
show_rollback_info() {
    local rollback_id="$1"
    local rollback_path="backup/$rollback_id"
    
    if [ ! -d "$rollback_path" ]; then
        log_error "回滚点不存在: $rollback_id"
        return 1
    fi
    
    if [ ! -f "$rollback_path/ROLLBACK_METADATA.md" ]; then
        log_error "回滚点元数据文件不存在"
        return 1
    fi
    
    log_info "回滚点详细信息: $rollback_id"
    echo ""
    cat "$rollback_path/ROLLBACK_METADATA.md"
}

# 删除回滚点
delete_rollback_point() {
    local rollback_id="$1"
    local rollback_path="backup/$rollback_id"
    
    if [ ! -d "$rollback_path" ]; then
        log_error "回滚点不存在: $rollback_id"
        return 1
    fi
    
    log_warning "⚠️  即将删除回滚点: $rollback_id"
    log_warning "⚠️  此操作不可撤销"
    echo ""
    read -p "确认删除? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "删除已取消"
        return 0
    fi
    
    rm -rf "$rollback_path"
    log_success "回滚点已删除: $rollback_id"
}

# 清理过期的回滚点
cleanup_rollback_points() {
    log_info "清理过期的回滚点..."
    
    local days_to_keep=7
    local current_time=$(date +%s)
    local cutoff_time=$((current_time - days_to_keep * 24 * 60 * 60))
    
    local count=0
    for rollback_dir in backup/rollback_point_*; do
        if [ -d "$rollback_dir" ]; then
            local rollback_id=$(basename "$rollback_dir")
            local dir_time=$(stat -f %m "$rollback_dir" 2>/dev/null || echo "0")
            
            if [ "$dir_time" -lt "$cutoff_time" ]; then
                log_info "删除过期回滚点: $rollback_id"
                rm -rf "$rollback_dir"
                ((count++))
            fi
        fi
    done
    
    if [ $count -eq 0 ]; then
        log_info "没有找到过期的回滚点"
    else
        log_success "已删除 $count 个过期的回滚点"
    fi
}

# 主函数
main() {
    local command="$1"
    shift
    
    case "$command" in
        create)
            create_rollback_point "$@"
            ;;
        list)
            list_rollback_points
            ;;
        info)
            if [ -z "$1" ]; then
                log_error "请指定回滚点ID"
                show_help
                exit 1
            fi
            show_rollback_info "$1"
            ;;
        delete)
            if [ -z "$1" ]; then
                log_error "请指定回滚点ID"
                show_help
                exit 1
            fi
            delete_rollback_point "$1"
            ;;
        cleanup)
            cleanup_rollback_points
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "未知命令: $command"
            show_help
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"
