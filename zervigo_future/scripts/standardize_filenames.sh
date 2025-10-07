#!/bin/bash
set -e

echo "🔧 文件名标准化脚本"
echo "=================="
echo ""

# 设置工作目录
UPLOAD_DIR="backend/internal/resume/uploads/resumes/4"
BACKUP_DIR="backend/internal/resume/uploads/resumes/4/backup_$(date +%Y%m%d_%H%M%S)"

echo "📁 处理目录: $UPLOAD_DIR"
echo "📁 备份目录: $BACKUP_DIR"
echo ""

# 创建备份目录
mkdir -p "$BACKUP_DIR"

# 函数：标准化文件名
standardize_filename() {
    local file="$1"
    local dir=$(dirname "$file")
    local filename=$(basename "$file")
    local extension="${filename##*.}"
    local name="${filename%.*}"
    
    # 替换特殊字符
    name=$(echo "$name" | sed 's/--/-/g' | sed 's/ /_/g' | sed 's/（/(/g' | sed 's/）/)/g')
    
    # 替换中文为拼音或英文
    name=$(echo "$name" | sed 's/简历/resume/g' | sed 's/工程师/engineer/g' | sed 's/测试/test/g' | sed 's/硬件/hardware/g' | sed 's/LCD_TV/LCD_TV/g')
    
    # 移除多余的下划线
    name=$(echo "$name" | sed 's/__*/_/g' | sed 's/^_//' | sed 's/_$//')
    
    echo "${dir}/${name}.${extension}"
}

# 处理上传目录中的文件
echo "🔍 查找需要标准化的文件..."
find "$UPLOAD_DIR" -maxdepth 1 -type f \( -name "* *" -o -name "*--*" -o -name "*简历*" -o -name "*工程师*" \) | while read -r file; do
    if [ -f "$file" ]; then
        echo "处理文件: $file"
        
        # 备份原文件
        cp "$file" "$BACKUP_DIR/"
        echo "  ✅ 已备份到: $BACKUP_DIR/$(basename "$file")"
        
        # 生成新文件名
        new_file=$(standardize_filename "$file")
        
        # 重命名文件
        if [ "$file" != "$new_file" ]; then
            mv "$file" "$new_file"
            echo "  ✅ 已重命名为: $new_file"
        else
            echo "  ℹ️  文件名无需修改"
        fi
        echo ""
    fi
done

echo "✅ 文件名标准化完成！"
echo "📁 备份文件位置: $BACKUP_DIR"
echo ""
echo "📊 处理结果:"
echo "原文件数: $(find "$BACKUP_DIR" -type f | wc -l)"
echo "当前文件数: $(find "$UPLOAD_DIR" -maxdepth 1 -type f | wc -l)"
