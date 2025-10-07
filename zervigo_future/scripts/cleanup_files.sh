#!/bin/bash
# 文件系统清理脚本
# 用于清理项目中的备份文件、临时文件、日志文件等

set -e  # 遇到错误立即退出

echo "🧹 开始文件系统清理..."
echo "=================================="

# 项目根目录
PROJECT_ROOT="/Users/szjason72/zervi-basic/basic"

# 1. 清理备份文件
echo "📁 清理备份文件..."
BACKUP_COUNT=$(find "$PROJECT_ROOT" -name "*.bak" -o -name "*.backup" -o -name "*.tmp" -o -name "*.old" | wc -l)
if [ $BACKUP_COUNT -gt 0 ]; then
    echo "发现 $BACKUP_COUNT 个备份文件，正在删除..."
    find "$PROJECT_ROOT" -name "*.bak" -delete
    find "$PROJECT_ROOT" -name "*.backup" -delete
    find "$PROJECT_ROOT" -name "*.tmp" -delete
    find "$PROJECT_ROOT" -name "*.old" -delete
    echo "✅ 备份文件清理完成"
else
    echo "✅ 没有发现备份文件"
fi

# 2. 清理日志文件（保留最近7天）
echo "📝 清理日志文件..."
LOG_COUNT=$(find "$PROJECT_ROOT" -name "*.log" -mtime +7 | wc -l)
if [ $LOG_COUNT -gt 0 ]; then
    echo "发现 $LOG_COUNT 个7天前的日志文件，正在删除..."
    find "$PROJECT_ROOT" -name "*.log" -mtime +7 -delete
    echo "✅ 日志文件清理完成"
else
    echo "✅ 没有发现需要清理的日志文件"
fi

# 3. 清理SQLite临时文件
echo "🗄️ 清理SQLite临时文件..."
SHM_COUNT=$(find "$PROJECT_ROOT" -name "*.db-shm" | wc -l)
WAL_COUNT=$(find "$PROJECT_ROOT" -name "*.db-wal" | wc -l)
if [ $SHM_COUNT -gt 0 ] || [ $WAL_COUNT -gt 0 ]; then
    echo "发现 $SHM_COUNT 个 .db-shm 文件和 $WAL_COUNT 个 .db-wal 文件，正在删除..."
    find "$PROJECT_ROOT" -name "*.db-shm" -delete
    find "$PROJECT_ROOT" -name "*.db-wal" -delete
    echo "✅ SQLite临时文件清理完成"
else
    echo "✅ 没有发现SQLite临时文件"
fi

# 4. 清理重复的数据库文件
echo "🗃️ 清理重复的数据库文件..."
OLD_DB_PATH="$PROJECT_ROOT/backend/internal/resume/data/users/user_4"
if [ -d "$OLD_DB_PATH" ]; then
    echo "发现旧的数据库路径，正在删除..."
    rm -rf "$OLD_DB_PATH"
    echo "✅ 重复数据库文件清理完成"
else
    echo "✅ 没有发现重复的数据库文件"
fi

# 5. 清理测试残留文件
echo "🧪 清理测试残留文件..."
TEST_FILES=(
    "$PROJECT_ROOT/backend/internal/resume/test_*.go.bak"
    "$PROJECT_ROOT/backend/internal/resume/test_parser"
    "$PROJECT_ROOT/backend/internal/resume/resume-service"
)

for pattern in "${TEST_FILES[@]}"; do
    if ls $pattern 1> /dev/null 2>&1; then
        echo "删除测试文件: $pattern"
        rm -f $pattern
    fi
done
echo "✅ 测试残留文件清理完成"

# 6. 清理构建产物
echo "🔨 清理构建产物..."
BUILD_DIRS=(
    "$PROJECT_ROOT/backend/internal/resume/tmp"
    "$PROJECT_ROOT/frontend-taro/dist"
    "$PROJECT_ROOT/frontend-taro/node_modules/.cache"
)

for dir in "${BUILD_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        echo "清理构建目录: $dir"
        rm -rf "$dir"/*
    fi
done
echo "✅ 构建产物清理完成"

# 7. 统计清理结果
echo "📊 清理统计..."
TOTAL_FILES=$(find "$PROJECT_ROOT" -type f | wc -l)
echo "清理后项目总文件数: $TOTAL_FILES"

# 8. 计算释放的存储空间
echo "💾 计算存储空间..."
PROJECT_SIZE=$(du -sh "$PROJECT_ROOT" | cut -f1)
echo "项目总大小: $PROJECT_SIZE"

echo "=================================="
echo "🎉 文件系统清理完成！"
echo "建议运行 'git status' 检查清理结果"
