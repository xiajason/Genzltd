#!/bin/bash
# 统一数据库备份脚本
# 备份所有本地化和容器化数据库

set -e

# 配置
BACKUP_ROOT="/Users/szjason72/genzltd/database-backups"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
LOG_FILE="/Users/szjason72/genzltd/logs/backup-all-databases.log"

# 创建备份目录
mkdir -p "$BACKUP_ROOT"
mkdir -p "$(dirname "$LOG_FILE")"

# 日志函数
log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS: $1" | tee -a "$LOG_FILE"
}

echo "🗄️  开始完整数据库备份..."
echo "备份根目录: $BACKUP_ROOT"
echo "时间戳: $TIMESTAMP"
echo "=================================="

# 创建备份报告
BACKUP_REPORT="$BACKUP_ROOT/backup_report_${TIMESTAMP}.md"
cat > "$BACKUP_REPORT" << EOF
# 数据库备份报告

**备份时间**: $(date)  
**备份类型**: 完整备份（本地化 + 容器化）  
**备份目录**: $BACKUP_ROOT  

## 📊 备份概览

### 本地化数据库备份
EOF

# 1. 备份本地化数据库
log_info "开始备份本地化数据库..."
if ./backup-local-databases.sh; then
    log_success "本地化数据库备份完成"
    echo "- ✅ 本地化数据库备份成功" >> "$BACKUP_REPORT"
else
    log_error "本地化数据库备份失败"
    echo "- ❌ 本地化数据库备份失败" >> "$BACKUP_REPORT"
fi

echo "" >> "$BACKUP_REPORT"
echo "### 容器化数据库备份" >> "$BACKUP_REPORT"

# 2. 备份容器化数据库
log_info "开始备份容器化数据库..."
if ./backup-containerized-databases.sh; then
    log_success "容器化数据库备份完成"
    echo "- ✅ 容器化数据库备份成功" >> "$BACKUP_REPORT"
else
    log_error "容器化数据库备份失败"
    echo "- ❌ 容器化数据库备份失败" >> "$BACKUP_REPORT"
fi

# 3. 生成备份统计
echo "" >> "$BACKUP_REPORT"
echo "## 📈 备份统计" >> "$BACKUP_REPORT"
echo "" >> "$BACKUP_REPORT"

# 统计本地化数据库备份
LOCAL_BACKUP_COUNT=$(find "$BACKUP_ROOT/local" -name "*${TIMESTAMP}*" 2>/dev/null | wc -l)
echo "### 本地化数据库备份文件数: $LOCAL_BACKUP_COUNT" >> "$BACKUP_REPORT"

# 统计容器化数据库备份
CONTAINER_BACKUP_COUNT=$(find "$BACKUP_ROOT/containerized" -name "*${TIMESTAMP}*" 2>/dev/null | wc -l)
echo "### 容器化数据库备份文件数: $CONTAINER_BACKUP_COUNT" >> "$BACKUP_REPORT"

# 统计总大小
TOTAL_SIZE=$(du -sh "$BACKUP_ROOT" 2>/dev/null | cut -f1)
echo "### 总备份大小: $TOTAL_SIZE" >> "$BACKUP_REPORT"

echo "" >> "$BACKUP_REPORT"
echo "## 📁 备份文件列表" >> "$BACKUP_REPORT"
echo "" >> "$BACKUP_REPORT"

# 列出所有备份文件
echo "### 本地化数据库备份文件:" >> "$BACKUP_REPORT"
find "$BACKUP_ROOT/local" -name "*${TIMESTAMP}*" 2>/dev/null | while read file; do
    echo "- $(basename "$file") ($(du -h "$file" | cut -f1))" >> "$BACKUP_REPORT"
done

echo "" >> "$BACKUP_REPORT"
echo "### 容器化数据库备份文件:" >> "$BACKUP_REPORT"
find "$BACKUP_ROOT/containerized" -name "*${TIMESTAMP}*" 2>/dev/null | while read file; do
    echo "- $(basename "$file") ($(du -h "$file" | cut -f1))" >> "$BACKUP_REPORT"
done

echo "" >> "$BACKUP_REPORT"
echo "## 🔧 恢复说明" >> "$BACKUP_REPORT"
echo "" >> "$BACKUP_REPORT"
echo "### 本地化数据库恢复" >> "$BACKUP_REPORT"
echo "1. 停止相关服务" >> "$BACKUP_REPORT"
echo "2. 恢复数据目录或导入SQL文件" >> "$BACKUP_REPORT"
echo "3. 重启服务" >> "$BACKUP_REPORT"
echo "" >> "$BACKUP_REPORT"
echo "### 容器化数据库恢复" >> "$BACKUP_REPORT"
echo "1. 停止相关容器" >> "$BACKUP_REPORT"
echo "2. 恢复数据目录或导入备份文件" >> "$BACKUP_REPORT"
echo "3. 重启容器" >> "$BACKUP_REPORT"

# 4. 创建备份验证脚本
VERIFY_SCRIPT="$BACKUP_ROOT/verify_backup_${TIMESTAMP}.sh"
cat > "$VERIFY_SCRIPT" << 'EOF'
#!/bin/bash
# 备份验证脚本

echo "🔍 验证数据库备份完整性..."
echo "=================================="

# 检查备份目录
BACKUP_ROOT="/Users/szjason72/genzltd/database-backups"
TIMESTAMP="$1"

if [ -z "$TIMESTAMP" ]; then
    echo "❌ 请提供时间戳参数"
    echo "用法: $0 <timestamp>"
    exit 1
fi

echo "验证时间戳: $TIMESTAMP"
echo "备份目录: $BACKUP_ROOT"
echo ""

# 验证本地化数据库备份
echo "📊 验证本地化数据库备份..."
LOCAL_FILES=$(find "$BACKUP_ROOT/local" -name "*${TIMESTAMP}*" 2>/dev/null | wc -l)
echo "本地化数据库备份文件数: $LOCAL_FILES"

# 验证容器化数据库备份
echo "📊 验证容器化数据库备份..."
CONTAINER_FILES=$(find "$BACKUP_ROOT/containerized" -name "*${TIMESTAMP}*" 2>/dev/null | wc -l)
echo "容器化数据库备份文件数: $CONTAINER_FILES"

# 检查关键备份文件
echo ""
echo "🔍 检查关键备份文件..."

# 检查MySQL备份
if find "$BACKUP_ROOT" -name "*mysql*${TIMESTAMP}*" | grep -q .; then
    echo "✅ MySQL备份存在"
else
    echo "❌ MySQL备份缺失"
fi

# 检查PostgreSQL备份
if find "$BACKUP_ROOT" -name "*postgresql*${TIMESTAMP}*" | grep -q .; then
    echo "✅ PostgreSQL备份存在"
else
    echo "❌ PostgreSQL备份缺失"
fi

# 检查Redis备份
if find "$BACKUP_ROOT" -name "*redis*${TIMESTAMP}*" | grep -q .; then
    echo "✅ Redis备份存在"
else
    echo "❌ Redis备份缺失"
fi

# 检查MongoDB备份
if find "$BACKUP_ROOT" -name "*mongodb*${TIMESTAMP}*" | grep -q .; then
    echo "✅ MongoDB备份存在"
else
    echo "❌ MongoDB备份缺失"
fi

# 检查Neo4j备份
if find "$BACKUP_ROOT" -name "*neo4j*${TIMESTAMP}*" | grep -q .; then
    echo "✅ Neo4j备份存在"
else
    echo "❌ Neo4j备份缺失"
fi

echo ""
echo "📊 备份验证完成！"
EOF

chmod +x "$VERIFY_SCRIPT"

# 5. 生成最终报告
echo ""
echo "📊 完整数据库备份完成报告"
echo "=================================="
echo "备份根目录: $BACKUP_ROOT"
echo "备份时间: $(date)"
echo "本地化数据库备份文件数: $LOCAL_BACKUP_COUNT"
echo "容器化数据库备份文件数: $CONTAINER_BACKUP_COUNT"
echo "总备份大小: $TOTAL_SIZE"
echo "备份报告: $BACKUP_REPORT"
echo "验证脚本: $VERIFY_SCRIPT"
echo "=================================="

log_success "完整数据库备份完成！"
echo "备份日志: $LOG_FILE"
echo "备份报告: $BACKUP_REPORT"
echo "验证命令: $VERIFY_SCRIPT $TIMESTAMP"
