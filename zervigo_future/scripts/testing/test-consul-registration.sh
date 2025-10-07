#!/bin/bash

# Consul服务注册测试脚本
# 用于验证新增的权限管理系统是否能在Consul中成功注册

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置
CONSUL_ADDRESS="localhost:8500"
SERVER_ADDRESS="localhost:8080"
LOG_FILE="/tmp/consul-test.log"

# 日志函数
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}" | tee -a "$LOG_FILE"
    exit 1
}

info() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1${NC}" | tee -a "$LOG_FILE"
}

# 检查依赖
check_dependencies() {
    log "检查依赖工具..."
    
    local tools=("curl" "jq")
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            error "缺少必要工具: $tool"
        fi
    done
    
    log "依赖检查完成"
}

# 检查Consul服务状态
check_consul_status() {
    log "检查Consul服务状态..."
    
    # 检查Consul是否运行
    if ! curl -s "http://$CONSUL_ADDRESS/v1/status/leader" > /dev/null; then
        error "Consul服务未运行或无法访问: $CONSUL_ADDRESS"
    fi
    
    # 获取Consul集群信息
    local leader=$(curl -s "http://$CONSUL_ADDRESS/v1/status/leader" | tr -d '"')
    local peers=$(curl -s "http://$CONSUL_ADDRESS/v1/status/peers" | jq -r '.[]' | tr '\n' ' ')
    
    info "Consul集群信息:"
    info "  领导者: $leader"
    info "  节点: $peers"
    
    log "Consul服务状态正常"
}

# 检查服务器状态
check_server_status() {
    log "检查服务器状态..."
    
    # 检查服务器是否运行
    if ! curl -s "http://$SERVER_ADDRESS/health" > /dev/null; then
        error "服务器未运行或无法访问: $SERVER_ADDRESS"
    fi
    
    # 获取健康检查信息
    local health_response=$(curl -s "http://$SERVER_ADDRESS/health")
    local status=$(echo "$health_response" | jq -r '.status // "unknown"')
    
    if [[ "$status" != "healthy" ]]; then
        error "服务器健康检查失败: $status"
    fi
    
    info "服务器健康状态: $status"
    log "服务器状态正常"
}

# 检查服务注册状态
check_service_registration() {
    log "检查服务注册状态..."
    
    # 获取所有注册的服务
    local services_response=$(curl -s "http://$CONSUL_ADDRESS/v1/agent/services")
    local service_count=$(echo "$services_response" | jq 'length')
    
    info "已注册服务数量: $service_count"
    
    # 检查JobFirst相关服务
    local jobfirst_services=$(echo "$services_response" | jq -r 'to_entries[] | select(.key | startswith("jobfirst")) | .key')
    
    if [[ -z "$jobfirst_services" ]]; then
        warn "未找到JobFirst相关服务"
        return 1
    fi
    
    info "JobFirst相关服务:"
    echo "$jobfirst_services" | while read -r service; do
        if [[ -n "$service" ]]; then
            local service_info=$(echo "$services_response" | jq -r ".[\"$service\"]")
            local service_name=$(echo "$service_info" | jq -r '.Service')
            local service_address=$(echo "$service_info" | jq -r '.Address')
            local service_port=$(echo "$service_info" | jq -r '.Port')
            local service_tags=$(echo "$service_info" | jq -r '.Tags[]' | tr '\n' ',' | sed 's/,$//')
            
            info "  服务ID: $service"
            info "  服务名: $service_name"
            info "  地址: $service_address:$service_port"
            info "  标签: $service_tags"
            echo
        fi
    done
    
    log "服务注册检查完成"
}

# 检查服务健康状态
check_service_health() {
    log "检查服务健康状态..."
    
    # 获取所有服务的健康检查状态
    local health_response=$(curl -s "http://$CONSUL_ADDRESS/v1/health/state/any")
    local jobfirst_health=$(echo "$health_response" | jq -r '.[] | select(.ServiceName | startswith("jobfirst")) | "\(.ServiceName): \(.Status)"')
    
    if [[ -z "$jobfirst_health" ]]; then
        warn "未找到JobFirst服务的健康检查信息"
        return 1
    fi
    
    info "JobFirst服务健康状态:"
    echo "$jobfirst_health" | while read -r health; do
        if [[ -n "$health" ]]; then
            local service_name=$(echo "$health" | cut -d':' -f1)
            local status=$(echo "$health" | cut -d':' -f2 | tr -d ' ')
            
            if [[ "$status" == "passing" ]]; then
                info "  ✅ $service_name: $status"
            elif [[ "$status" == "warning" ]]; then
                warn "  ⚠️  $service_name: $status"
            else
                error "  ❌ $service_name: $status"
            fi
        fi
    done
    
    log "服务健康检查完成"
}

# 测试API端点
test_api_endpoints() {
    log "测试API端点..."
    
    # 测试健康检查端点
    info "测试健康检查端点..."
    local health_response=$(curl -s "http://$SERVER_ADDRESS/health")
    local health_status=$(echo "$health_response" | jq -r '.status // "unknown"')
    
    if [[ "$health_status" == "healthy" ]]; then
        info "  ✅ 健康检查端点正常"
    else
        error "  ❌ 健康检查端点异常: $health_status"
    fi
    
    # 测试超级管理员状态端点
    info "测试超级管理员状态端点..."
    local super_admin_response=$(curl -s "http://$SERVER_ADDRESS/api/v1/super-admin/public/status")
    local super_admin_exists=$(echo "$super_admin_response" | jq -r '.exists // false')
    
    if [[ "$super_admin_exists" == "true" ]]; then
        info "  ✅ 超级管理员已存在"
    else
        info "  ℹ️  超级管理员未初始化"
    fi
    
    # 测试RBAC检查端点（需要认证）
    info "测试RBAC检查端点..."
    local rbac_response=$(curl -s "http://$SERVER_ADDRESS/api/v1/rbac/check?user=test&resource=user&action=read")
    local rbac_status=$(echo "$rbac_response" | jq -r '.success // false')
    
    if [[ "$rbac_status" == "false" ]]; then
        info "  ✅ RBAC端点正常（未认证访问被拒绝）"
    else
        warn "  ⚠️  RBAC端点可能配置异常"
    fi
    
    log "API端点测试完成"
}

# 检查服务发现
test_service_discovery() {
    log "测试服务发现..."
    
    # 通过服务发现获取服务信息
    local discovery_response=$(curl -s "http://$CONSUL_ADDRESS/v1/catalog/services")
    local jobfirst_services=$(echo "$discovery_response" | jq -r 'to_entries[] | select(.key | startswith("jobfirst")) | .key')
    
    if [[ -z "$jobfirst_services" ]]; then
        warn "服务发现中未找到JobFirst服务"
        return 1
    fi
    
    info "通过服务发现找到的JobFirst服务:"
    echo "$jobfirst_services" | while read -r service; do
        if [[ -n "$service" ]]; then
            # 获取服务实例
            local instances_response=$(curl -s "http://$CONSUL_ADDRESS/v1/health/service/$service")
            local instance_count=$(echo "$instances_response" | jq 'length')
            
            info "  $service: $instance_count 个实例"
            
            # 获取每个实例的详细信息
            echo "$instances_response" | jq -r '.[] | "    - \(.Service.Address):\(.Service.Port) (\(.Checks[0].Status))"' | while read -r instance; do
                info "$instance"
            done
        fi
    done
    
    log "服务发现测试完成"
}

# 生成测试报告
generate_report() {
    log "生成测试报告..."
    
    local report_file="/tmp/consul-registration-report.txt"
    
    cat > "$report_file" << EOF
==========================================
Consul服务注册测试报告
==========================================
测试时间: $(date)
测试目标: $CONSUL_ADDRESS
服务器地址: $SERVER_ADDRESS

1. Consul服务状态:
$(curl -s "http://$CONSUL_ADDRESS/v1/status/leader" | jq -r '"领导者: " + .')

2. 注册的服务:
$(curl -s "http://$CONSUL_ADDRESS/v1/agent/services" | jq -r 'to_entries[] | "\(.key): \(.value.Service) (\(.value.Address):\(.value.Port))"')

3. 服务健康状态:
$(curl -s "http://$CONSUL_ADDRESS/v1/health/state/any" | jq -r '.[] | select(.ServiceName | startswith("jobfirst")) | "\(.ServiceName): \(.Status)"')

4. 服务器健康检查:
$(curl -s "http://$SERVER_ADDRESS/health" | jq .)

5. 超级管理员状态:
$(curl -s "http://$SERVER_ADDRESS/api/v1/super-admin/public/status" | jq .)

==========================================
EOF

    info "测试报告已生成: $report_file"
    log "测试报告生成完成"
}

# 主函数
main() {
    echo "=========================================="
    echo "🔍 Consul服务注册测试工具"
    echo "=========================================="
    echo
    
    # 创建日志文件
    mkdir -p "$(dirname "$LOG_FILE")"
    
    # 执行测试步骤
    check_dependencies
    check_consul_status
    check_server_status
    check_service_registration
    check_service_health
    test_api_endpoints
    test_service_discovery
    generate_report
    
    echo
    echo "=========================================="
    echo "🎉 测试完成！"
    echo "=========================================="
    echo
    echo "📋 测试结果:"
    echo "  ✅ Consul服务状态正常"
    echo "  ✅ 服务器健康检查通过"
    echo "  ✅ 服务注册成功"
    echo "  ✅ 服务发现正常"
    echo "  ✅ API端点可访问"
    echo
    echo "📝 详细日志: $LOG_FILE"
    echo "📊 测试报告: /tmp/consul-registration-report.txt"
    echo
    echo "🚀 新增的权限管理系统已成功在Consul中注册！"
    echo "=========================================="
}

# 错误处理
trap 'error "测试执行失败，请检查日志: $LOG_FILE"' ERR

# 执行主函数
main "$@"
