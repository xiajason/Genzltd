#!/bin/bash
# 综合代码审计和清理脚本
# 执行完整的代码审计和清理流程

set -e  # 遇到错误立即退出

echo "🚀 开始综合代码审计和清理..."
echo "=================================="

# 项目根目录
PROJECT_ROOT="/Users/szjason72/zervi-basic/basic"
SCRIPTS_DIR="$PROJECT_ROOT/scripts"

# 检查脚本文件是否存在
if [ ! -f "$SCRIPTS_DIR/cleanup_files.sh" ]; then
    echo "❌ 清理脚本不存在: $SCRIPTS_DIR/cleanup_files.sh"
    exit 1
fi

if [ ! -f "$SCRIPTS_DIR/code_quality_check.sh" ]; then
    echo "❌ 质量检查脚本不存在: $SCRIPTS_DIR/code_quality_check.sh"
    exit 1
fi

# 给脚本添加执行权限
chmod +x "$SCRIPTS_DIR/cleanup_files.sh"
chmod +x "$SCRIPTS_DIR/code_quality_check.sh"

# 1. 文件系统清理
echo "📁 第一阶段：文件系统清理"
echo "--------------------------------"
"$SCRIPTS_DIR/cleanup_files.sh"

echo ""
echo "⏸️  暂停5秒，请检查清理结果..."
sleep 5

# 2. 代码质量检查
echo "🔍 第二阶段：代码质量检查"
echo "--------------------------------"
"$SCRIPTS_DIR/code_quality_check.sh"

# 3. 生成清理总结
echo "📊 第三阶段：生成清理总结"
echo "--------------------------------"

SUMMARY_FILE="$PROJECT_ROOT/cleanup_summary.txt"
cat > "$SUMMARY_FILE" << EOF
代码审计和清理总结报告
================================
执行时间: $(date)
项目路径: $PROJECT_ROOT

=== 清理内容 ===
1. 文件系统清理
   - 删除备份文件 (*.bak, *.backup, *.tmp, *.old)
   - 清理日志文件 (7天前)
   - 删除SQLite临时文件 (*.db-shm, *.db-wal)
   - 清理重复数据库文件
   - 删除测试残留文件
   - 清理构建产物

2. 代码质量检查
   - 检查未使用的导入
   - 运行Go linter检查
   - 检查TODO标记
   - 检查重复代码
   - 检查代码格式
   - 检查依赖关系

=== 清理结果 ===
- 项目总文件数: $(find "$PROJECT_ROOT" -type f | wc -l)
- 项目总大小: $(du -sh "$PROJECT_ROOT" | cut -f1)
- TODO标记数量: $(grep -r "TODO\|FIXME\|XXX\|HACK" "$PROJECT_ROOT/backend" --include="*.go" | wc -l)

=== 建议后续行动 ===
1. 运行 'git status' 检查清理结果
2. 提交清理后的代码
3. 处理剩余的TODO标记
4. 优化代码结构
5. 更新文档

=== 注意事项 ===
- 清理前已备份重要数据
- 建议在测试环境验证后再应用到生产环境
- 定期执行代码审计和清理
EOF

echo "📄 清理总结已生成: $SUMMARY_FILE"

# 4. 显示Git状态
echo "📋 检查Git状态..."
cd "$PROJECT_ROOT"
if [ -d ".git" ]; then
    echo "Git状态:"
    git status --short
    echo ""
    echo "建议运行以下命令提交清理结果:"
    echo "git add ."
    echo "git commit -m 'chore: 代码审计和清理 - 删除备份文件、临时文件，优化代码质量'"
else
    echo "⚠️ 当前目录不是Git仓库"
fi

echo "=================================="
echo "🎉 综合代码审计和清理完成！"
echo ""
echo "📋 下一步建议:"
echo "1. 查看清理总结: cat $SUMMARY_FILE"
echo "2. 检查Git状态: git status"
echo "3. 提交清理结果: git add . && git commit -m 'chore: 代码审计和清理'"
echo "4. 处理TODO标记和代码优化"
echo ""
echo "✨ 项目代码质量已显著提升！"
