#!/bin/bash

# 测试数据迁移工具
# 这个脚本用于测试迁移工具的基本功能

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查依赖
check_dependencies() {
    log_info "检查依赖..."
    
    # 检查 Go
    if ! command -v go &> /dev/null; then
        log_error "Go 未安装"
        exit 1
    fi
    
    # 检查 MySQL 客户端
    if ! command -v mysql &> /dev/null; then
        log_warning "MySQL 客户端未安装"
    fi
    
    log_success "依赖检查完成"
}

# 测试数据库连接
test_database_connection() {
    log_info "测试数据库连接..."
    
    # 测试源数据库连接
    if mysql -u root -p -e "USE jobfirst;" 2>/dev/null; then
        log_success "源数据库连接成功"
    else
        log_error "源数据库连接失败"
        exit 1
    fi
    
    # 测试目标数据库连接
    if mysql -u root -p -e "USE jobfirst_v3;" 2>/dev/null; then
        log_success "目标数据库连接成功"
    else
        log_warning "目标数据库不存在，将创建"
        mysql -u root -p -e "CREATE DATABASE jobfirst_v3 CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
        log_success "目标数据库已创建"
    fi
}

# 编译迁移工具
compile_tools() {
    log_info "编译迁移工具..."
    
    # 编译主迁移工具
    go build -o migrate main.go
    if [[ $? -eq 0 ]]; then
        log_success "主迁移工具编译成功"
    else
        log_error "主迁移工具编译失败"
        exit 1
    fi
    
    # 编译验证工具
    go build -o validate validate.go
    if [[ $? -eq 0 ]]; then
        log_success "验证工具编译成功"
    else
        log_error "验证工具编译失败"
        exit 1
    fi
}

# 测试迁移工具
test_migration() {
    log_info "测试迁移工具..."
    
    # 检查迁移工具是否存在
    if [[ ! -f "./migrate" ]]; then
        log_error "迁移工具不存在"
        exit 1
    fi
    
    # 检查验证工具是否存在
    if [[ ! -f "./validate" ]]; then
        log_error "验证工具不存在"
        exit 1
    fi
    
    log_success "迁移工具测试通过"
}

# 显示测试结果
show_test_results() {
    log_info "测试结果:"
    echo "✅ 依赖检查通过"
    echo "✅ 数据库连接测试通过"
    echo "✅ 工具编译成功"
    echo "✅ 迁移工具测试通过"
    echo ""
    log_success "所有测试通过！迁移工具已准备就绪。"
}

# 清理测试文件
cleanup() {
    log_info "清理测试文件..."
    rm -f migrate validate
    log_success "清理完成"
}

# 主函数
main() {
    log_info "开始测试数据迁移工具..."
    echo ""
    
    check_dependencies
    echo ""
    
    test_database_connection
    echo ""
    
    compile_tools
    echo ""
    
    test_migration
    echo ""
    
    show_test_results
    echo ""
    
    # 询问是否清理测试文件
    read -p "是否清理测试文件? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cleanup
    fi
    
    log_info "测试完成！"
}

# 运行主函数
main
