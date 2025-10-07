#!/bin/bash

# 移除所有GitHub Actions工作流文件中的子模块配置

set -e

echo "🔧 移除GitHub Actions工作流中的子模块配置..."

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 工作流文件目录
WORKFLOWS_DIR=".github/workflows"

# 检查目录是否存在
if [ ! -d "$WORKFLOWS_DIR" ]; then
    echo -e "${RED}❌ 工作流目录不存在: $WORKFLOWS_DIR${NC}"
    exit 1
fi

# 处理每个工作流文件
for workflow_file in "$WORKFLOWS_DIR"/*.yml; do
    if [ -f "$workflow_file" ]; then
        echo -e "${BLUE}📝 处理文件: $workflow_file${NC}"
        
        # 创建备份
        cp "$workflow_file" "$workflow_file.backup"
        
        # 移除子模块配置
        # 移除包含 submodules: recursive 的行
        sed -i.tmp '/submodules: recursive/d' "$workflow_file"
        
        # 移除包含 submodules: 的行
        sed -i.tmp '/submodules:/d' "$workflow_file"
        
        # 清理临时文件
        rm -f "$workflow_file.tmp"
        
        echo -e "  ✅ 已移除子模块配置"
    fi
done

echo -e "${GREEN}🎉 所有工作流文件已更新，子模块配置已移除${NC}"

# 显示修改摘要
echo -e "${YELLOW}📋 修改摘要:${NC}"
echo "  - 移除了所有 'submodules: recursive' 配置"
echo "  - 移除了所有 'submodules:' 配置"
echo "  - 保留了原有的 checkout 配置"
echo "  - 创建了备份文件 (.backup)"

echo -e "${BLUE}🔧 下一步:${NC}"
echo "  1. 检查修改结果"
echo "  2. 提交更改"
echo "  3. 测试GitHub Actions"
