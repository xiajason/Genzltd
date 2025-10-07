#!/bin/bash

# 数据库容器化停止脚本
# 用于停止所有数据库容器和监控服务

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
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

# 获取脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo -e "${BLUE}🛑 停止LoomaCRM数据库容器化服务${NC}"
echo "=================================="

# 1. 检查Docker Compose文件
log_info "检查Docker Compose配置文件..."
if [ ! -f "$PROJECT_ROOT/docker-compose.database.yml" ]; then
    log_error "Docker Compose配置文件不存在: docker-compose.database.yml"
    exit 1
fi

# 2. 停止所有容器
log_info "停止数据库容器..."
cd "$PROJECT_ROOT"

docker-compose -f docker-compose.database.yml down

if [ $? -eq 0 ]; then
    log_success "数据库容器已停止"
else
    log_warning "停止容器时出现警告"
fi

# 3. 清理未使用的容器
log_info "清理未使用的容器..."
docker container prune -f

# 4. 显示清理结果
echo ""
echo -e "${GREEN}✅ 数据库容器化服务已停止${NC}"
echo "=================================="
echo ""
echo -e "${BLUE}清理完成:${NC}"
echo "- 所有数据库容器已停止"
echo "- 未使用的容器已清理"
echo "- 数据卷已保留（数据不会丢失）"
echo ""
echo -e "${BLUE}重新启动命令:${NC}"
echo "./scripts/start_database_containers.sh"
echo ""
echo -e "${GREEN}数据库容器化服务停止完成！${NC}"
