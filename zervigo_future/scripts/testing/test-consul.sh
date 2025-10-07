#!/bin/bash

# Consul服务发现功能测试脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 获取脚本所在目录的绝对路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

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
    log_info "Checking dependencies..."
    
    if ! command -v curl &> /dev/null; then
        log_error "curl is not installed"
        exit 1
    fi
    
    if ! command -v jq &> /dev/null; then
        log_warning "jq is not installed, some output may not be formatted"
    fi
    
    log_success "Dependencies check completed"
}

# 检查Consul状态
check_consul_status() {
    log_info "Checking Consul status..."
    
    if ! curl -s http://localhost:8500/v1/status/leader > /dev/null 2>&1; then
        log_error "Consul is not running. Please start Consul first:"
        log_info "  ./scripts/start-consul.sh start"
        exit 1
    fi
    
    log_success "Consul is running"
}

# 检查后端服务状态
check_backend_status() {
    log_info "Checking backend service status..."
    
    if ! curl -s http://localhost:8080/health > /dev/null 2>&1; then
        log_error "Backend service is not running. Please start it first:"
        log_info "  cd backend && go run cmd/basic-server/main.go"
        exit 1
    fi
    
    log_success "Backend service is running"
}

# 测试健康检查端点
test_health_endpoint() {
    log_info "Testing health check endpoint..."
    
    response=$(curl -s http://localhost:8080/health)
    
    if echo "$response" | jq -e '.status' > /dev/null 2>&1; then
        status=$(echo "$response" | jq -r '.status')
        log_success "Health check endpoint working, status: $status"
        
        # 显示详细信息
        echo "Health check details:"
        echo "$response" | jq '.'
    else
        log_error "Health check endpoint failed or returned invalid JSON"
        echo "Response: $response"
    fi
}

# 测试Consul状态端点
test_consul_status() {
    log_info "Testing Consul status endpoint..."
    
    response=$(curl -s http://localhost:8080/api/v1/consul/status)
    
    if echo "$response" | jq -e '.enabled' > /dev/null 2>&1; then
        enabled=$(echo "$response" | jq -r '.enabled')
        if [ "$enabled" = "true" ]; then
            log_success "Consul status endpoint working, Consul is enabled"
            echo "Consul status details:"
            echo "$response" | jq '.'
        else
            log_warning "Consul status endpoint working, but Consul is disabled"
        fi
    else
        log_error "Consul status endpoint failed or returned invalid JSON"
        echo "Response: $response"
    fi
}

# 测试微服务注册端点
test_microservices_endpoint() {
    log_info "Testing microservices endpoint..."
    
    response=$(curl -s http://localhost:8080/api/v1/consul/microservices)
    
    if echo "$response" | jq -e '.enabled' > /dev/null 2>&1; then
        enabled=$(echo "$response" | jq -r '.enabled')
        if [ "$enabled" = "true" ]; then
            log_success "Microservices endpoint working, registry is enabled"
            
            total_services=$(echo "$response" | jq -r '.total_services')
            log_info "Total registered microservices: $total_services"
            
            echo "Microservices details:"
            echo "$response" | jq '.'
        else
            log_warning "Microservices endpoint working, but registry is disabled"
        fi
    else
        log_error "Microservices endpoint failed or returned invalid JSON"
        echo "Response: $response"
    fi
}

# 测试健康检查端点
test_consul_health() {
    log_info "Testing Consul health endpoint..."
    
    response=$(curl -s http://localhost:8080/api/v1/consul/health)
    
    if echo "$response" | jq -e '.enabled' > /dev/null 2>&1; then
        enabled=$(echo "$response" | jq -r '.enabled')
        if [ "$enabled" = "true" ]; then
            log_success "Consul health endpoint working, health checks are enabled"
            
            echo "Health check results:"
            echo "$response" | jq '.'
        else
            log_warning "Consul health endpoint working, but health checks are disabled"
        fi
    else
        log_error "Consul health endpoint failed or returned invalid JSON"
        echo "Response: $response"
    fi
}

# 测试服务发现端点
test_services_discovery() {
    log_info "Testing services discovery endpoint..."
    
    response=$(curl -s http://localhost:8080/api/v1/consul/services)
    
    if echo "$response" | jq -e '.enabled' > /dev/null 2>&1; then
        enabled=$(echo "$response" | jq -r '.enabled')
        if [ "$enabled" = "true" ]; then
            log_success "Services discovery endpoint working, discovery is enabled"
            
            echo "Services discovery details:"
            echo "$response" | jq '.'
        else
            log_warning "Services discovery endpoint working, but discovery is disabled"
        fi
    else
        log_error "Services discovery endpoint failed or returned invalid JSON"
        echo "Response: $response"
    fi
}

# 测试Consul API
test_consul_api() {
    log_info "Testing Consul API directly..."
    
    # 测试Consul leader状态
    if leader=$(curl -s http://localhost:8500/v1/status/leader 2>/dev/null); then
        log_success "Consul leader: $leader"
    else
        log_error "Failed to get Consul leader status"
    fi
    
    # 测试Consul peers
    if peers=$(curl -s http://localhost:8500/v1/status/peers 2>/dev/null); then
        log_info "Consul peers: $peers"
    else
        log_error "Failed to get Consul peers"
    fi
    
    # 测试服务目录
    if services=$(curl -s http://localhost:8500/v1/catalog/services 2>/dev/null); then
        log_info "Consul services:"
        echo "$services" | jq . 2>/dev/null || echo "$services"
    else
        log_error "Failed to get Consul services"
    fi
}

# 运行所有测试
run_all_tests() {
    log_info "Starting Consul service discovery tests..."
    
    check_dependencies
    check_consul_status
    check_backend_status
    
    log_info "Running API tests..."
    
    test_health_endpoint
    test_consul_status
    test_microservices_endpoint
    test_consul_health
    test_services_discovery
    
    log_info "Testing Consul API directly..."
    test_consul_api
    
    log_success "All tests completed!"
}

# 显示帮助信息
show_help() {
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  all       Run all tests (default)"
    echo "  health    Test health check endpoint"
    echo "  consul    Test Consul-related endpoints"
    echo "  api       Test Consul API directly"
    echo "  help      Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 all        # Run all tests"
    echo "  $0 health     # Test health endpoint only"
    echo "  $0 consul     # Test Consul endpoints only"
}

# 主函数
main() {
    case "${1:-all}" in
        all)
            run_all_tests
            ;;
        health)
            check_dependencies
            check_backend_status
            test_health_endpoint
            ;;
        consul)
            check_dependencies
            check_consul_status
            check_backend_status
            test_consul_status
            test_microservices_endpoint
            test_consul_health
            test_services_discovery
            ;;
        api)
            check_dependencies
            check_consul_status
            test_consul_api
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "Unknown command: $1"
            show_help
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"
