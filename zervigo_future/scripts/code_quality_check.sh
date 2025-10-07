#!/bin/bash
# 代码质量检查脚本
# 用于检查Go代码质量，清理未使用的导入，检测死代码等

set -e  # 遇到错误立即退出

echo "🔍 开始代码质量检查..."
echo "=================================="

# 项目根目录
PROJECT_ROOT="/Users/szjason72/zervi-basic/basic"
BACKEND_ROOT="$PROJECT_ROOT/backend"

# 检查Go环境
if ! command -v go &> /dev/null; then
    echo "❌ Go环境未安装或未配置"
    exit 1
fi

# 1. 检查Go版本
echo "📋 Go环境信息..."
go version

# 2. 检查未使用的导入
echo "📦 检查未使用的导入..."
SERVICES=(
    "internal/resume"
    "internal/company-service"
    "internal/job-service"
    "internal/user-service"
    "internal/ai-service"
    "internal/statistics-service"
    "internal/notification-service"
    "internal/template-service"
    "internal/banner-service"
)

for service in "${SERVICES[@]}"; do
    SERVICE_PATH="$BACKEND_ROOT/$service"
    if [ -d "$SERVICE_PATH" ]; then
        echo "检查服务: $service"
        cd "$SERVICE_PATH"
        
        # 检查是否有Go文件
        if ls *.go 1> /dev/null 2>&1; then
            # 使用goimports整理导入
            if command -v goimports &> /dev/null; then
                echo "  整理导入..."
                goimports -w .
            else
                echo "  安装goimports: go install golang.org/x/tools/cmd/goimports@latest"
            fi
            
            # 检查未使用的导入
            echo "  检查未使用的导入..."
            go vet ./... 2>&1 | grep -i "imported and not used" || echo "  ✅ 没有发现未使用的导入"
        fi
    fi
done

# 3. 运行Go linter检查
echo "🔧 运行Go linter检查..."
if command -v golangci-lint &> /dev/null; then
    cd "$BACKEND_ROOT"
    echo "运行golangci-lint..."
    golangci-lint run --enable=deadcode,unused,gosimple,ineffassign,misspell \
        --timeout=5m \
        --skip-dirs="vendor,node_modules" \
        ./... || echo "⚠️ 发现一些代码质量问题，请查看上述输出"
else
    echo "⚠️ golangci-lint未安装，跳过linter检查"
    echo "安装命令: go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest"
fi

# 4. 检查TODO标记
echo "📝 检查TODO标记..."
TODO_COUNT=$(grep -r "TODO\|FIXME\|XXX\|HACK" "$BACKEND_ROOT" --include="*.go" | wc -l)
echo "发现 $TODO_COUNT 个TODO/FIXME/XXX/HACK标记"

if [ $TODO_COUNT -gt 0 ]; then
    echo "前10个TODO标记:"
    grep -r "TODO\|FIXME\|XXX\|HACK" "$BACKEND_ROOT" --include="*.go" | head -10
fi

# 5. 检查重复代码
echo "🔄 检查重复代码..."
if command -v gocyclo &> /dev/null; then
    echo "检查函数复杂度..."
    gocyclo -over 10 "$BACKEND_ROOT" || echo "⚠️ 发现高复杂度函数"
else
    echo "⚠️ gocyclo未安装，跳过复杂度检查"
    echo "安装命令: go install github.com/fzipp/gocyclo/cmd/gocyclo@latest"
fi

# 6. 检查代码格式
echo "🎨 检查代码格式..."
cd "$BACKEND_ROOT"
if command -v gofmt &> /dev/null; then
    UNFORMATTED=$(gofmt -l .)
    if [ -n "$UNFORMATTED" ]; then
        echo "⚠️ 发现未格式化的文件:"
        echo "$UNFORMATTED"
        echo "运行 'gofmt -w .' 格式化代码"
    else
        echo "✅ 所有Go文件格式正确"
    fi
fi

# 7. 检查依赖关系
echo "📚 检查依赖关系..."
for service in "${SERVICES[@]}"; do
    SERVICE_PATH="$BACKEND_ROOT/$service"
    if [ -d "$SERVICE_PATH" ] && [ -f "$SERVICE_PATH/go.mod" ]; then
        echo "检查服务依赖: $service"
        cd "$SERVICE_PATH"
        
        # 检查未使用的依赖
        if command -v go mod tidy &> /dev/null; then
            echo "  整理依赖..."
            go mod tidy
        fi
        
        # 检查依赖版本
        echo "  检查依赖版本..."
        go list -u -m all 2>/dev/null | grep "\[" || echo "  ✅ 所有依赖都是最新版本"
    fi
done

# 8. 生成代码质量报告
echo "📊 生成代码质量报告..."
REPORT_FILE="$PROJECT_ROOT/code_quality_report.txt"
cat > "$REPORT_FILE" << EOF
代码质量检查报告
生成时间: $(date)
项目路径: $PROJECT_ROOT

=== 检查结果 ===
TODO标记数量: $TODO_COUNT
Go版本: $(go version)

=== 建议改进 ===
1. 清理未使用的导入
2. 处理TODO标记
3. 优化高复杂度函数
4. 统一代码格式
5. 更新过时依赖

=== 下一步行动 ===
1. 运行代码格式化: gofmt -w .
2. 整理依赖: go mod tidy
3. 处理TODO标记
4. 优化代码结构
EOF

echo "📄 代码质量报告已生成: $REPORT_FILE"

echo "=================================="
echo "🎉 代码质量检查完成！"
echo "请查看报告文件了解详细结果"
