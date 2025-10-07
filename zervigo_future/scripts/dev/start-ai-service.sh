#!/bin/bash

# AI服务启动脚本
# 启动AI服务来处理文件上传后的内容解析和向量生成

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

# 检查AI服务是否已运行
check_ai_service() {
    if lsof -i :8620 > /dev/null 2>&1; then
        log_warning "AI服务已在端口8620上运行"
        return 0
    fi
    return 1
}

# 启动AI服务
start_ai_service() {
    log_info "启动AI服务 (容器化部署)..."
    
    # 进入AI服务目录
    cd ai-services
    
    # 检查Docker是否运行
    if ! docker info > /dev/null 2>&1; then
        log_error "Docker 未运行，请先启动Docker Desktop"
        exit 1
    fi
    
    # 检查Docker Compose文件
    if [ ! -f "docker-compose.yml" ]; then
        log_error "未找到 docker-compose.yml 文件"
        exit 1
    fi
    
    # 启动AI服务容器
    log_info "启动AI服务容器..."
    docker-compose up -d ai-service
    
    # 等待服务启动
    log_info "等待AI服务启动..."
    sleep 10
    
    # 检查服务状态
    if check_ai_service; then
        log_success "AI服务启动成功 (容器化部署)"
        log_info "AI服务地址: http://localhost:8620"
    else
        log_error "AI服务启动失败"
        log_info "检查容器日志: docker-compose logs ai-service"
        exit 1
    fi
}

# 测试AI服务
test_ai_service() {
    log_info "测试AI服务..."
    
    # 测试健康检查
    if curl -s http://localhost:8620/health > /dev/null; then
        log_success "AI服务健康检查通过"
    else
        log_error "AI服务健康检查失败"
        return 1
    fi
    
    # 测试简历分析API
    test_data='{
        "resume_id": "test-001",
        "content": "前端开发工程师，擅长React和Node.js",
        "file_type": "text",
        "file_name": "test.txt"
    }'
    
    if curl -s -X POST http://localhost:8620/api/v1/analyze/resume \
        -H "Content-Type: application/json" \
        -d "$test_data" > /dev/null; then
        log_success "AI服务简历分析API测试通过"
    else
        log_error "AI服务简历分析API测试失败"
        return 1
    fi
}

# 主函数
main() {
    log_info "=== AI服务启动脚本 ==="
    
    # 检查AI服务状态
    if check_ai_service; then
        log_warning "AI服务已在运行，跳过启动"
    else
        # 启动AI服务
        start_ai_service
    fi
    
    # 测试AI服务
    if test_ai_service; then
        log_success "AI服务启动和测试完成"
        log_info "AI服务地址: http://localhost:8620"
        log_info "API文档:"
        log_info "  - POST /api/v1/analyze/resume - 分析简历"
        log_info "  - GET  /api/v1/vectors/:id - 获取简历向量"
        log_info "  - POST /api/v1/vectors/search - 搜索相似简历"
    else
        log_error "AI服务测试失败"
        exit 1
    fi
}

# 执行主函数
main "$@"
