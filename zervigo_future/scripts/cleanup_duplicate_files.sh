#!/bin/bash
set -e

echo "🔧 重复文件清理脚本"
echo "=================="
echo ""

# 设置工作目录
UPLOAD_DIR="backend/internal/resume/uploads/resumes/4"
CLEANUP_BACKUP_DIR="backend/internal/resume/uploads/resumes/4/cleanup_backup_$(date +%Y%m%d_%H%M%S)"

echo "📁 处理目录: $UPLOAD_DIR"
echo "📁 清理备份目录: $CLEANUP_BACKUP_DIR"
echo ""

# 创建备份目录
mkdir -p "$CLEANUP_BACKUP_DIR"

# 统计变量
total_files=0
duplicate_files=0
space_saved=0

echo "🔍 查找重复文件..."
echo "=================="

# 按文件大小分组，查找重复文件
find "$UPLOAD_DIR" -maxdepth 1 -type f -exec ls -la {} \; | awk '{print $5, $9}' | sort -n | awk '
{
    if ($1 == prev_size && prev_size != "") {
        if (!seen[$1]) {
            print "重复大小:", $1, "字节"
            seen[$1] = 1
        }
        print "  -", $2
    }
    prev_size = $1
}' | while read -r line; do
    if [[ $line == "重复大小:"* ]]; then
        echo "$line"
        size=$(echo "$line" | awk '{print $3}')
        space_saved=$((space_saved + size))
    elif [[ $line == "  -"* ]]; then
        file=$(echo "$line" | sed 's/  - //')
        if [ -f "$file" ]; then
            echo "$line"
            # 备份文件
            cp "$file" "$CLEANUP_BACKUP_DIR/"
            # 删除重复文件
            rm "$file"
            duplicate_files=$((duplicate_files + 1))
            echo "    ✅ 已删除并备份: $(basename "$file")"
        fi
    fi
done

echo ""
echo "✅ 重复文件清理完成！"
echo "📁 清理备份位置: $CLEANUP_BACKUP_DIR"
echo ""
echo "📊 清理统计:"
echo "删除重复文件数: $duplicate_files"
echo "节省空间: $(du -sh "$CLEANUP_BACKUP_DIR" | cut -f1)"
echo ""
echo "📊 当前目录状态:"
echo "剩余文件数: $(find "$UPLOAD_DIR" -maxdepth 1 -type f | wc -l)"
echo "当前目录大小: $(du -sh "$UPLOAD_DIR" | cut -f1)"
