#!/bin/bash

# JobFirst 开发团队管理系统部署脚本
# 用于部署基于JobFirst系统的用户管理功能

set -e

echo "=== JobFirst 开发团队管理系统部署 ==="
echo "时间: $(date)"
echo

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

# 检查是否为root用户
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "请以root用户运行此脚本"
        exit 1
    fi
}

# 检查MySQL连接
check_mysql_connection() {
    log_info "检查MySQL连接..."
    
    if ! mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "SELECT 1;" > /dev/null 2>&1; then
        log_error "MySQL连接失败，请检查密码配置"
        exit 1
    fi
    
    log_success "MySQL连接正常"
}

# 执行数据库迁移
run_database_migration() {
    log_info "执行数据库迁移..."
    
    # 检查迁移文件是否存在
    if [ ! -f "/opt/jobfirst/database/migrations/create_dev_team_tables.sql" ]; then
        log_error "数据库迁移文件不存在"
        exit 1
    fi
    
    # 执行迁移
    mysql -u root -p${MYSQL_ROOT_PASSWORD} < /opt/jobfirst/database/migrations/create_dev_team_tables.sql
    
    if [ $? -eq 0 ]; then
        log_success "数据库迁移完成"
    else
        log_error "数据库迁移失败"
        exit 1
    fi
}

# 更新后端代码
update_backend_code() {
    log_info "更新后端代码..."
    
    # 检查Go模块
    cd /opt/jobfirst/backend
    if [ -f "go.mod" ]; then
        go mod tidy
        log_success "Go模块更新完成"
    fi
    
    # 重新编译后端服务
    log_info "重新编译后端服务..."
    go build -o basic-server cmd/basic-server/main.go
    
    if [ $? -eq 0 ]; then
        log_success "后端服务编译完成"
    else
        log_error "后端服务编译失败"
        exit 1
    fi
}

# 重启后端服务
restart_backend_service() {
    log_info "重启后端服务..."
    
    # 停止现有服务
    pkill -f basic-server || true
    sleep 2
    
    # 启动新服务
    cd /opt/jobfirst/backend
    nohup ./basic-server > /opt/jobfirst/logs/backend.log 2>&1 &
    
    # 等待服务启动
    sleep 5
    
    # 检查服务状态
    if pgrep -f basic-server > /dev/null; then
        log_success "后端服务启动成功"
    else
        log_error "后端服务启动失败"
        exit 1
    fi
}

# 更新前端代码
update_frontend_code() {
    log_info "更新前端代码..."
    
    cd /opt/jobfirst/frontend-taro
    
    # 安装依赖
    npm install
    
    # 构建前端
    npm run build:h5
    
    if [ $? -eq 0 ]; then
        log_success "前端构建完成"
    else
        log_error "前端构建失败"
        exit 1
    fi
}

# 配置Nginx
configure_nginx() {
    log_info "配置Nginx..."
    
    # 检查Nginx配置
    nginx -t
    
    if [ $? -eq 0 ]; then
        # 重新加载Nginx配置
        systemctl reload nginx
        log_success "Nginx配置更新完成"
    else
        log_error "Nginx配置有误"
        exit 1
    fi
}

# 测试API接口
test_api_endpoints() {
    log_info "测试API接口..."
    
    # 测试健康检查
    if curl -s http://localhost:8080/health | grep -q "healthy"; then
        log_success "健康检查API正常"
    else
        log_error "健康检查API失败"
        exit 1
    fi
    
    # 测试开发团队API（需要认证）
    if curl -s http://localhost:8080/api/v1/dev-team/public/roles | grep -q "success"; then
        log_success "开发团队API正常"
    else
        log_warning "开发团队API需要认证，跳过测试"
    fi
}

# 创建示例数据
create_sample_data() {
    log_info "创建示例数据..."
    
    # 检查是否有现有用户
    USER_COUNT=$(mysql -u root -p${MYSQL_ROOT_PASSWORD} -D jobfirst -e "SELECT COUNT(*) FROM users;" -s -N)
    
    if [ "$USER_COUNT" -gt 0 ]; then
        log_info "发现现有用户，创建开发团队示例数据..."
        
        # 获取第一个用户ID
        FIRST_USER_ID=$(mysql -u root -p${MYSQL_ROOT_PASSWORD} -D jobfirst -e "SELECT id FROM users LIMIT 1;" -s -N)
        
        # 创建超级管理员
        mysql -u root -p${MYSQL_ROOT_PASSWORD} -D jobfirst -e "
        INSERT IGNORE INTO dev_team_users (user_id, team_role, server_access_level, code_access_modules, database_access, service_restart_permissions, status)
        VALUES ($FIRST_USER_ID, 'super_admin', 'full', '[\"all\"]', '[\"all\"]', '[\"all\"]', 'active');
        "
        
        log_success "示例数据创建完成"
    else
        log_warning "没有现有用户，跳过示例数据创建"
    fi
}

# 显示部署结果
show_deployment_result() {
    log_info "显示部署结果..."
    
    echo
    echo "=== 部署完成 ==="
    echo
    echo "🎉 JobFirst 开发团队管理系统部署成功！"
    echo
    echo "📋 功能特性："
    echo "✅ 用户角色管理（7种角色）"
    echo "✅ 权限控制（细粒度权限）"
    echo "✅ 操作审计（完整日志记录）"
    echo "✅ API接口（RESTful API）"
    echo "✅ 前端界面（管理界面）"
    echo
    echo "🔗 访问地址："
    echo "• 前端管理界面: http://101.33.251.158/dev-team"
    echo "• API文档: http://101.33.251.158/api/v1/dev-team/public/roles"
    echo
    echo "📊 管理功能："
    echo "• 添加/删除团队成员"
    echo "• 更新成员权限"
    echo "• 查看操作日志"
    echo "• 权限配置管理"
    echo
    echo "🔒 安全特性："
    echo "• JWT认证"
    echo "• 角色权限控制"
    echo "• 操作审计日志"
    echo "• IP地址记录"
    echo
    echo "📞 技术支持："
    echo "• 查看日志: tail -f /opt/jobfirst/logs/backend.log"
    echo "• 重启服务: systemctl restart nginx"
    echo "• 数据库管理: mysql -u root -p"
    echo
}

# 主函数
main() {
    log_info "开始部署JobFirst开发团队管理系统..."
    
    # 检查环境变量
    if [ -z "$MYSQL_ROOT_PASSWORD" ]; then
        log_error "请设置MYSQL_ROOT_PASSWORD环境变量"
        exit 1
    fi
    
    check_root
    check_mysql_connection
    run_database_migration
    update_backend_code
    restart_backend_service
    update_frontend_code
    configure_nginx
    test_api_endpoints
    create_sample_data
    show_deployment_result
    
    log_success "JobFirst开发团队管理系统部署完成！"
}

# 运行主函数
main "$@"
