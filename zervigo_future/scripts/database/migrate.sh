#!/bin/bash

# 数据迁移脚本 - 从 V1.0 迁移到 V3.0
# 使用方法: ./migrate.sh [选项]

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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
    echo "数据迁移工具 - 从 V1.0 迁移到 V3.0"
    echo ""
    echo "使用方法:"
    echo "  $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help              显示帮助信息"
    echo "  -c, --config FILE       指定配置文件 (默认: config.yaml)"
    echo "  -s, --source DB         源数据库名称 (默认: jobfirst)"
    echo "  -t, --target DB         目标数据库名称 (默认: jobfirst_v3)"
    echo "  -b, --backup            备份源数据库"
    echo "  -v, --validate          验证迁移结果"
    echo "  -d, --dry-run           试运行模式，不执行实际迁移"
    echo "  --skip-skills           跳过技能迁移"
    echo "  --skip-resumes          跳过简历迁移"
    echo "  --force                 强制迁移，覆盖已存在的数据"
    echo ""
    echo "示例:"
    echo "  $0                      # 使用默认配置执行完整迁移"
    echo "  $0 -b -v                # 备份源数据库并验证迁移结果"
    echo "  $0 -d                   # 试运行模式"
    echo "  $0 --skip-skills        # 跳过技能迁移，只迁移简历"
}

# 默认配置
CONFIG_FILE="config.yaml"
SOURCE_DB="jobfirst"
TARGET_DB="jobfirst_v3"
BACKUP_SOURCE=false
VALIDATE_RESULT=false
DRY_RUN=false
SKIP_SKILLS=false
SKIP_RESUMES=false
FORCE=false

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -c|--config)
            CONFIG_FILE="$2"
            shift 2
            ;;
        -s|--source)
            SOURCE_DB="$2"
            shift 2
            ;;
        -t|--target)
            TARGET_DB="$2"
            shift 2
            ;;
        -b|--backup)
            BACKUP_SOURCE=true
            shift
            ;;
        -v|--validate)
            VALIDATE_RESULT=true
            shift
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        --skip-skills)
            SKIP_SKILLS=true
            shift
            ;;
        --skip-resumes)
            SKIP_RESUMES=true
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        *)
            log_error "未知选项: $1"
            show_help
            exit 1
            ;;
    esac
done

# 检查配置文件
if [[ ! -f "$CONFIG_FILE" ]]; then
    log_error "配置文件不存在: $CONFIG_FILE"
    exit 1
fi

# 检查 Go 环境
if ! command -v go &> /dev/null; then
    log_error "Go 未安装或不在 PATH 中"
    exit 1
fi

# 检查 MySQL 客户端
if ! command -v mysql &> /dev/null; then
    log_warning "MySQL 客户端未安装，某些功能可能不可用"
fi

# 显示配置信息
log_info "数据迁移配置:"
echo "  配置文件: $CONFIG_FILE"
echo "  源数据库: $SOURCE_DB"
echo "  目标数据库: $TARGET_DB"
echo "  备份源数据库: $BACKUP_SOURCE"
echo "  验证迁移结果: $VALIDATE_RESULT"
echo "  试运行模式: $DRY_RUN"
echo "  跳过技能迁移: $SKIP_SKILLS"
echo "  跳过简历迁移: $SKIP_RESUMES"
echo "  强制迁移: $FORCE"
echo ""

# 确认执行
if [[ "$DRY_RUN" == false ]]; then
    read -p "确认执行数据迁移? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "迁移已取消"
        exit 0
    fi
fi

# 创建备份
if [[ "$BACKUP_SOURCE" == true && "$DRY_RUN" == false ]]; then
    log_info "创建源数据库备份..."
    BACKUP_FILE="backup_${SOURCE_DB}_$(date +%Y%m%d_%H%M%S).sql"
    
    if command -v mysqldump &> /dev/null; then
        mysqldump -u root -p "$SOURCE_DB" > "$BACKUP_FILE"
        log_success "备份已创建: $BACKUP_FILE"
    else
        log_warning "mysqldump 未安装，跳过备份"
    fi
fi

# 检查目标数据库是否存在
log_info "检查目标数据库..."
if mysql -u root -p -e "USE $TARGET_DB;" 2>/dev/null; then
    if [[ "$FORCE" == false ]]; then
        log_warning "目标数据库 $TARGET_DB 已存在"
        read -p "是否继续? 这可能会覆盖现有数据 (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "迁移已取消"
            exit 0
        fi
    fi
else
    log_info "目标数据库 $TARGET_DB 不存在，将创建新数据库"
    if [[ "$DRY_RUN" == false ]]; then
        mysql -u root -p -e "CREATE DATABASE $TARGET_DB CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
        log_success "目标数据库已创建"
    fi
fi

# 编译迁移工具
log_info "编译迁移工具..."
if [[ "$DRY_RUN" == false ]]; then
    go build -o migrate main.go
    if [[ $? -ne 0 ]]; then
        log_error "编译失败"
        exit 1
    fi
    log_success "迁移工具编译完成"
fi

# 执行迁移
if [[ "$DRY_RUN" == false ]]; then
    log_info "开始执行数据迁移..."
    
    # 设置环境变量
    export SOURCE_DB="$SOURCE_DB"
    export TARGET_DB="$TARGET_DB"
    export SKIP_SKILLS="$SKIP_SKILLS"
    export SKIP_RESUMES="$SKIP_RESUMES"
    
    # 运行迁移工具
    ./migrate
    MIGRATION_EXIT_CODE=$?
    
    if [[ $MIGRATION_EXIT_CODE -eq 0 ]]; then
        log_success "数据迁移完成"
    else
        log_error "数据迁移失败，退出代码: $MIGRATION_EXIT_CODE"
        exit $MIGRATION_EXIT_CODE
    fi
else
    log_info "试运行模式 - 跳过实际迁移"
fi

# 验证迁移结果
if [[ "$VALIDATE_RESULT" == true && "$DRY_RUN" == false ]]; then
    log_info "验证迁移结果..."
    
    # 检查技能数量
    if [[ "$SKIP_SKILLS" == false ]]; then
        SKILL_COUNT=$(mysql -u root -p -D "$TARGET_DB" -e "SELECT COUNT(*) FROM skills;" -s -N 2>/dev/null || echo "0")
        log_info "迁移的技能数量: $SKILL_COUNT"
    fi
    
    # 检查简历数量
    if [[ "$SKIP_RESUMES" == false ]]; then
        RESUME_COUNT=$(mysql -u root -p -D "$TARGET_DB" -e "SELECT COUNT(*) FROM resumes;" -s -N 2>/dev/null || echo "0")
        log_info "迁移的简历数量: $RESUME_COUNT"
        
        # 检查简历技能关联
        RESUME_SKILL_COUNT=$(mysql -u root -p -D "$TARGET_DB" -e "SELECT COUNT(*) FROM resume_skills;" -s -N 2>/dev/null || echo "0")
        log_info "简历技能关联数量: $RESUME_SKILL_COUNT"
        
        # 检查工作经历
        WORK_EXP_COUNT=$(mysql -u root -p -D "$TARGET_DB" -e "SELECT COUNT(*) FROM work_experiences;" -s -N 2>/dev/null || echo "0")
        log_info "工作经历数量: $WORK_EXP_COUNT"
        
        # 检查教育背景
        EDUCATION_COUNT=$(mysql -u root -p -D "$TARGET_DB" -e "SELECT COUNT(*) FROM educations;" -s -N 2>/dev/null || echo "0")
        log_info "教育背景数量: $EDUCATION_COUNT"
    fi
    
    log_success "验证完成"
fi

# 清理临时文件
if [[ "$DRY_RUN" == false ]]; then
    log_info "清理临时文件..."
    rm -f migrate
    log_success "清理完成"
fi

log_success "数据迁移流程完成！"

# 显示后续步骤
echo ""
log_info "后续步骤:"
echo "1. 检查迁移结果是否正确"
echo "2. 更新应用程序配置以使用新的数据库"
echo "3. 测试应用程序功能"
echo "4. 如果一切正常，可以删除源数据库备份"
echo ""
log_info "目标数据库: $TARGET_DB"
if [[ "$BACKUP_SOURCE" == true ]]; then
    log_info "备份文件: $BACKUP_FILE"
fi
