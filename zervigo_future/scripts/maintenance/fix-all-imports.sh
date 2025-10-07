#!/bin/bash

# 全面修复Go import路径脚本
# 将错误的jobfirst-basic路径替换为正确的模块路径

set -e

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== 全面修复Go import路径 ===${NC}"

# 进入backend目录
cd backend

# 更新go.mod模块名
echo -e "${YELLOW}🔧 更新go.mod模块名...${NC}"
sed -i '' 's|module jobfirst-basic|module github.com/xiajason/zervi-basic/basic/backend|g' go.mod

# 查找所有需要修复的Go文件
echo -e "${YELLOW}🔍 查找需要修复的Go文件...${NC}"
FILES_TO_FIX=$(find . -name "*.go" -type f -exec grep -l "jobfirst-basic/" {} \;)

if [ -z "$FILES_TO_FIX" ]; then
    echo -e "${GREEN}✅ 没有找到需要修复的文件${NC}"
else
    echo -e "${YELLOW}📋 找到需要修复的文件:${NC}"
    echo "$FILES_TO_FIX"
    echo ""

    # 修复每个文件
    FIXED_COUNT=0
    for file in $FILES_TO_FIX; do
        echo -e "${BLUE}🔧 修复文件: $file${NC}"
        
        # 备份原文件
        cp "$file" "$file.backup"
        
        # 替换import路径
        sed -i '' 's|"jobfirst-basic/|"github.com/xiajason/zervi-basic/basic/backend/|g' "$file"
        
        # 检查是否修复成功
        if ! grep -q "jobfirst-basic/" "$file"; then
            echo -e "${GREEN}  ✅ 修复成功${NC}"
            FIXED_COUNT=$((FIXED_COUNT + 1))
            # 删除备份文件
            rm "$file.backup"
        else
            echo -e "${RED}  ❌ 修复失败${NC}"
            # 恢复备份文件
            mv "$file.backup" "$file"
        fi
    done

    echo ""
    echo -e "${GREEN}🎉 修复完成！${NC}"
    echo -e "${GREEN}✅ 成功修复 $FIXED_COUNT 个文件${NC}"
fi

# 清理go.mod中的replace指令
echo -e "${YELLOW}🧹 清理go.mod...${NC}"
sed -i '' '/^replace /d' go.mod

# 运行go mod tidy
echo -e "${YELLOW}🔄 运行go mod tidy...${NC}"
go mod tidy

# 验证修复结果
echo ""
echo -e "${BLUE}🔍 验证修复结果...${NC}"
REMAINING_FILES=$(find . -name "*.go" -type f -exec grep -l "jobfirst-basic/" {} \; 2>/dev/null || true)

if [ -z "$REMAINING_FILES" ]; then
    echo -e "${GREEN}✅ 所有import路径已修复${NC}"
else
    echo -e "${RED}❌ 以下文件仍有问题:${NC}"
    echo "$REMAINING_FILES"
fi

# 测试编译
echo ""
echo -e "${BLUE}🧪 测试编译...${NC}"
if go build ./cmd/basic-server/main.go; then
    echo -e "${GREEN}✅ 编译成功${NC}"
    rm -f basic-server
else
    echo -e "${RED}❌ 编译失败${NC}"
fi

echo ""
echo -e "${BLUE}📊 修复完成时间: $(date)${NC}"
