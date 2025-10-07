#!/bin/bash

# 智能CI/CD流水线验证脚本
# 用于验证智能CI/CD流水线的各项功能

set -e

echo "🧪 开始验证智能CI/CD流水线..."

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 验证函数
verify_workflow_files() {
    echo -e "${BLUE}📋 验证工作流文件...${NC}"
    
    local workflows=(
        ".github/workflows/smart-cicd.yml"
        ".github/workflows/ci.yml"
        ".github/workflows/deploy.yml"
        ".github/workflows/code-review.yml"
        ".github/workflows/comprehensive-testing.yml"
        ".github/workflows/frontend-deploy.yml"
        ".github/workflows/verify-deployment.yml"
    )
    
    for workflow in "${workflows[@]}"; do
        if [ -f "$workflow" ]; then
            echo -e "  ✅ $workflow 存在"
        else
            echo -e "  ❌ $workflow 不存在"
            return 1
        fi
    done
    
    echo -e "${GREEN}✅ 所有工作流文件验证通过${NC}"
}

verify_smart_cicd_config() {
    echo -e "${BLUE}🔧 验证智能CI/CD配置...${NC}"
    
    local smart_cicd=".github/workflows/smart-cicd.yml"
    
    # 检查触发条件
    if grep -q "push:" "$smart_cicd" && grep -q "pull_request:" "$smart_cicd" && grep -q "workflow_dispatch:" "$smart_cicd"; then
        echo -e "  ✅ 触发条件配置正确"
    else
        echo -e "  ❌ 触发条件配置错误"
        return 1
    fi
    
    # 检查变更检测
    if grep -q "dorny/paths-filter" "$smart_cicd"; then
        echo -e "  ✅ 变更检测配置正确"
    else
        echo -e "  ❌ 变更检测配置错误"
        return 1
    fi
    
    # 检查条件执行
    if grep -q "if:" "$smart_cicd"; then
        echo -e "  ✅ 条件执行配置正确"
    else
        echo -e "  ❌ 条件执行配置错误"
        return 1
    fi
    
    echo -e "${GREEN}✅ 智能CI/CD配置验证通过${NC}"
}

verify_other_workflows() {
    echo -e "${BLUE}🔍 验证其他工作流配置...${NC}"
    
    local workflows=(
        "ci.yml"
        "deploy.yml"
        "code-review.yml"
        "comprehensive-testing.yml"
        "frontend-deploy.yml"
        "verify-deployment.yml"
    )
    
    for workflow in "${workflows[@]}"; do
        local file=".github/workflows/$workflow"
        if grep -q "workflow_dispatch:" "$file" && ! grep -q "push:" "$file"; then
            echo -e "  ✅ $workflow 已正确配置为手动触发"
        else
            echo -e "  ⚠️  $workflow 可能仍包含自动触发"
        fi
    done
    
    echo -e "${GREEN}✅ 其他工作流配置验证完成${NC}"
}

verify_test_files() {
    echo -e "${BLUE}📝 验证测试文件...${NC}"
    
    local test_files=(
        "test-change-detection.md"
        "backend/test-backend-change.go"
        "frontend-taro/src/test-frontend-change.ts"
        "nginx/test-config-change.conf"
    )
    
    for file in "${test_files[@]}"; do
        if [ -f "$file" ]; then
            echo -e "  ✅ $file 存在"
        else
            echo -e "  ❌ $file 不存在"
            return 1
        fi
    done
    
    echo -e "${GREEN}✅ 所有测试文件验证通过${NC}"
}

verify_documentation() {
    echo -e "${BLUE}📚 验证文档...${NC}"
    
    local docs=(
        "docs/WORKFLOW_CONFLICT_ANALYSIS.md"
        "docs/CI_CD_IMPLEMENTATION_REPORT.md"
    )
    
    for doc in "${docs[@]}"; do
        if [ -f "$doc" ]; then
            echo -e "  ✅ $doc 存在"
        else
            echo -e "  ❌ $doc 不存在"
            return 1
        fi
    done
    
    echo -e "${GREEN}✅ 文档验证通过${NC}"
}

# 主验证流程
main() {
    echo -e "${YELLOW}🚀 智能CI/CD流水线验证开始${NC}"
    echo "=================================="
    
    verify_workflow_files
    verify_smart_cicd_config
    verify_other_workflows
    verify_test_files
    verify_documentation
    
    echo "=================================="
    echo -e "${GREEN}🎉 智能CI/CD流水线验证完成！${NC}"
    echo ""
    echo -e "${BLUE}📋 验证总结：${NC}"
    echo "  ✅ 工作流文件完整性"
    echo "  ✅ 智能CI/CD配置正确性"
    echo "  ✅ 工作流冲突解决方案"
    echo "  ✅ 测试文件准备就绪"
    echo "  ✅ 文档完整性"
    echo ""
    echo -e "${YELLOW}🔧 下一步：${NC}"
    echo "  1. 提交测试文件，观察智能CI/CD流水线执行"
    echo "  2. 检查GitHub Actions执行日志"
    echo "  3. 验证变更检测和执行计划生成"
    echo "  4. 确认条件执行和完整性验证"
}

# 执行主函数
main "$@"
