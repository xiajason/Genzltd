#!/bin/bash

# CI/CD状态检查脚本
# 用于检查GitHub Actions的执行状态

set -e

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置
REPO="xiajason/zervi-basic"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"

echo -e "${BLUE}=== GitHub Actions CI/CD 状态检查 ===${NC}"
echo "仓库: $REPO"
echo "时间: $(date)"
echo ""

# 检查GitHub Token
if [ -z "$GITHUB_TOKEN" ]; then
    echo -e "${YELLOW}⚠️  GITHUB_TOKEN 未设置，使用公开API（可能有限制）${NC}"
    echo ""
fi

# 检查最近的workflow runs
echo -e "${BLUE}📋 检查最近的workflow执行情况...${NC}"

if [ -n "$GITHUB_TOKEN" ]; then
    # 使用token的API调用
    RESPONSE=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/repos/$REPO/actions/runs?per_page=5")
else
    # 不使用token的API调用
    RESPONSE=$(curl -s -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/repos/$REPO/actions/runs?per_page=5")
fi

# 检查API响应
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ GitHub API调用失败${NC}"
    echo "请检查网络连接或GitHub Token配置"
    exit 1
fi

# 解析响应
echo "$RESPONSE" | jq -r '.workflow_runs[]? | "\(.id) | \(.name) | \(.status) | \(.conclusion // "running") | \(.created_at)"' 2>/dev/null || {
    echo -e "${RED}❌ 无法解析GitHub API响应${NC}"
    echo "响应内容:"
    echo "$RESPONSE"
    exit 1
}

echo ""
echo -e "${BLUE}🔍 详细信息:${NC}"

# 显示详细信息
echo "$RESPONSE" | jq -r '.workflow_runs[]? | "ID: \(.id)\n名称: \(.name)\n状态: \(.status)\n结论: \(.conclusion // "进行中")\n创建时间: \(.created_at)\nURL: \(.html_url)\n---"' 2>/dev/null || {
    echo -e "${RED}❌ 无法解析详细信息${NC}"
}

echo ""
echo -e "${BLUE}🌐 访问GitHub Actions页面:${NC}"
echo "https://github.com/$REPO/actions"

echo ""
echo -e "${BLUE}📊 检查完成时间: $(date)${NC}"

# 检查是否有正在运行的workflow
RUNNING_COUNT=$(echo "$RESPONSE" | jq -r '.workflow_runs[]? | select(.status == "in_progress") | .id' 2>/dev/null | wc -l)

if [ "$RUNNING_COUNT" -gt 0 ]; then
    echo -e "${YELLOW}🔄 发现 $RUNNING_COUNT 个正在运行的workflow${NC}"
else
    echo -e "${GREEN}✅ 当前没有正在运行的workflow${NC}"
fi

# 检查最近的结论
LATEST_CONCLUSION=$(echo "$RESPONSE" | jq -r '.workflow_runs[0].conclusion // "unknown"' 2>/dev/null)

case "$LATEST_CONCLUSION" in
    "success")
        echo -e "${GREEN}✅ 最新的workflow执行成功${NC}"
        ;;
    "failure")
        echo -e "${RED}❌ 最新的workflow执行失败${NC}"
        ;;
    "cancelled")
        echo -e "${YELLOW}⚠️  最新的workflow被取消${NC}"
        ;;
    "running"|"in_progress")
        echo -e "${BLUE}🔄 最新的workflow正在运行中${NC}"
        ;;
    *)
        echo -e "${YELLOW}❓ 最新的workflow状态未知: $LATEST_CONCLUSION${NC}"
        ;;
esac
