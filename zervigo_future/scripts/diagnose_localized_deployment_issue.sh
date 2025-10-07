#!/bin/bash
set -e

echo "🔍 诊断本地化部署包创建问题"
echo "=============================="

# 检查环境
echo "📋 环境检查:"
echo "当前工作目录: $(pwd)"
echo "当前用户: $(whoami)"
echo "环境变量:"
echo "  - PWD: $PWD"
echo "  - HOME: $HOME"
echo "  - PATH: $PATH"

# 检查脚本文件
echo ""
echo "📁 脚本文件检查:"
if [ -f "scripts/create_localized_deployment.sh" ]; then
    echo "✅ 脚本文件存在"
    echo "文件权限: $(ls -la scripts/create_localized_deployment.sh)"
    echo "文件大小: $(wc -l < scripts/create_localized_deployment.sh) 行"
else
    echo "❌ 脚本文件不存在"
    echo "当前目录内容:"
    ls -la
    echo "scripts目录内容:"
    ls -la scripts/ || echo "scripts目录不存在"
fi

# 检查测试脚本
echo ""
echo "🧪 测试脚本检查:"
if [ -f "scripts/test_localized_deployment.sh" ]; then
    echo "✅ 测试脚本存在"
    echo "文件权限: $(ls -la scripts/test_localized_deployment.sh)"
else
    echo "❌ 测试脚本不存在"
fi

# 尝试执行测试脚本
echo ""
echo "🚀 执行测试脚本:"
if [ -f "scripts/test_localized_deployment.sh" ]; then
    chmod +x scripts/test_localized_deployment.sh
    echo "执行测试脚本..."
    if ./scripts/test_localized_deployment.sh; then
        echo "✅ 测试脚本执行成功"
    else
        echo "❌ 测试脚本执行失败，退出码: $?"
    fi
else
    echo "⚠️ 测试脚本不存在，跳过执行"
fi

# 检查目录权限
echo ""
echo "🔐 目录权限检查:"
echo "当前目录权限: $(ls -ld .)"
echo "scripts目录权限: $(ls -ld scripts/ 2>/dev/null || echo 'scripts目录不存在')"

# 检查磁盘空间
echo ""
echo "💾 磁盘空间检查:"
df -h . || echo "无法检查磁盘空间"

# 尝试手动创建目录
echo ""
echo "🛠️ 手动创建测试目录:"
TEST_DIR="test-manual-creation"
echo "尝试创建测试目录: $TEST_DIR"
if mkdir -p "$TEST_DIR"; then
    echo "✅ 目录创建成功"
    echo "目录权限: $(ls -ld $TEST_DIR)"
    echo "清理测试目录..."
    rm -rf "$TEST_DIR"
    echo "✅ 测试目录清理完成"
else
    echo "❌ 目录创建失败"
fi

# 检查Python环境
echo ""
echo "🐍 Python环境检查:"
if command -v python3 &> /dev/null; then
    echo "✅ Python3 可用: $(python3 --version)"
else
    echo "❌ Python3 不可用"
fi

if command -v pip3 &> /dev/null; then
    echo "✅ pip3 可用: $(pip3 --version)"
else
    echo "❌ pip3 不可用"
fi

# 检查GitHub Actions环境
echo ""
echo "🔧 GitHub Actions环境检查:"
if [ -n "$GITHUB_ACTIONS" ]; then
    echo "✅ 运行在GitHub Actions环境中"
    echo "  - GITHUB_WORKSPACE: $GITHUB_WORKSPACE"
    echo "  - GITHUB_RUN_ID: $GITHUB_RUN_ID"
    echo "  - RUNNER_OS: $RUNNER_OS"
    echo "  - RUNNER_ARCH: $RUNNER_ARCH"
else
    echo "⚠️ 不在GitHub Actions环境中"
fi

echo ""
echo "🎯 诊断完成"
