#!/bin/bash
set -e

echo "🔧 重复文件清理脚本 (修复版)"
echo "============================"
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
duplicate_count=0
total_space_saved=0

echo "🔍 查找重复文件..."
echo "=================="

# 使用更简单的方法查找重复文件
find "$UPLOAD_DIR" -maxdepth 1 -type f -exec ls -la {} \; | awk '{print $5, $9}' | sort -n | awk '
{
    if ($1 == prev_size && prev_size != "") {
        if (!seen[$1]) {
            print "重复大小:", $1
            seen[$1] = 1
        }
        print "  -", $2
    }
    prev_size = $1
}' > /tmp/duplicate_files.txt

# 处理重复文件
while IFS= read -r line; do
    if [[ $line == "重复大小:"* ]]; then
        size=$(echo "$line" | awk '{print $3}')
        echo "$line 字节"
    elif [[ $line == "  -"* ]]; then
        file=$(echo "$line" | sed 's/  - //')
        if [ -f "$file" ]; then
            echo "$line"
            # 备份文件
            cp "$file" "$CLEANUP_BACKUP_DIR/"
            # 删除重复文件
            rm "$file"
            duplicate_count=$((duplicate_count + 1))
            echo "    ✅ 已删除并备份: $(basename "$file")"
        fi
    fi
done < /tmp/duplicate_files.txt

# 清理临时文件
rm -f /tmp/duplicate_files.txt

echo ""
echo "✅ 重复文件清理完成！"
echo "📁 清理备份位置: $CLEANUP_BACKUP_DIR"
echo ""
echo "📊 清理统计:"
echo "删除重复文件数: $duplicate_count"
echo "备份文件大小: $(du -sh "$CLEANUP_BACKUP_DIR" 2>/dev/null | cut -f1 || echo "0")"
echo ""
echo "📊 当前目录状态:"
echo "剩余文件数: $(find "$UPLOAD_DIR" -maxdepth 1 -type f | wc -l)"
echo "当前目录大小: $(du -sh "$UPLOAD_DIR" | cut -f1)"
