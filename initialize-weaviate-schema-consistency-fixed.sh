#!/bin/bash

# Weaviate Schema一致性初始化脚本 (修复版)
# 解决三环境Weaviate Schema差异问题
# 创建时间: 2025年10月4日

# 定义颜色
GREEN='\033[0;32m'
RED='\033[0;31m'
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

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# 环境配置
LOCAL_WEAVIATE_URL="http://localhost:8082"
ALIBABA_CLOUD_IP="47.115.168.107"
TENCENT_CLOUD_IP="101.33.251.158"
ALIBABA_SSH_KEY="~/.ssh/cross_cloud_key"
TENCENT_SSH_KEY="~/.ssh/basic.pem"
ALIBABA_SSH_USER="root"
TENCENT_SSH_USER="ubuntu"

# 标准Resume Schema定义
RESUME_SCHEMA='{
  "class": "Resume",
  "description": "简历数据向量化存储",
  "vectorizer": "none",
  "properties": [
    {
      "name": "resume_id",
      "dataType": ["string"],
      "description": "简历ID",
      "indexFilterable": true,
      "indexSearchable": true
    },
    {
      "name": "content",
      "dataType": ["text"],
      "description": "简历内容",
      "indexFilterable": true,
      "indexSearchable": true
    }
  ]
}'

# 执行SSH命令的通用函数
execute_ssh_command() {
    local ssh_cmd="$1"
    local weaviate_url="$2"
    local command="$3"
    
    if [[ "$ssh_cmd" == *"basic.pem"* ]]; then
        # 腾讯云环境
        ssh -i "$ssh_cmd" "$TENCENT_SSH_USER@$weaviate_url" "$command" 2>/dev/null
    else
        # 阿里云环境
        ssh -i "$ssh_cmd" "$ALIBABA_SSH_USER@$weaviate_url" "$command" 2>/dev/null
    fi
}

# 检查Weaviate Schema状态
check_schema_status() {
    local env_name="$1"
    local weaviate_url="$2"
    local ssh_cmd="$3"
    
    log_info "检查${env_name}环境Weaviate Schema状态..."
    
    local schema_response
    if [ -n "$ssh_cmd" ]; then
        schema_response=$(execute_ssh_command "$ssh_cmd" "$weaviate_url" "curl -s ${LOCAL_WEAVIATE_URL}/v1/schema")
    else
        schema_response=$(curl -s "${weaviate_url}/v1/schema" 2>/dev/null)
    fi
    
    if [ -n "$schema_response" ]; then
        # 检查是否有Resume类
        if echo "$schema_response" | grep -q '"class":"Resume"'; then
            log_success "${env_name}环境: Resume类存在"
            return 0
        else
            log_warn "${env_name}环境: Resume类不存在"
            return 1
        fi
    else
        log_error "${env_name}环境: 无法获取Schema信息"
        return 2
    fi
}

# 清理现有Schema
cleanup_existing_schema() {
    local env_name="$1"
    local weaviate_url="$2"
    local ssh_cmd="$3"
    
    log_info "清理${env_name}环境现有Schema..."
    
    local delete_response
    if [ -n "$ssh_cmd" ]; then
        delete_response=$(execute_ssh_command "$ssh_cmd" "$weaviate_url" "curl -s -X DELETE ${LOCAL_WEAVIATE_URL}/v1/schema/Resume")
    else
        delete_response=$(curl -s -X DELETE "${weaviate_url}/v1/schema/Resume" 2>/dev/null)
    fi
    
    if echo "$delete_response" | grep -q "200\|204"; then
        log_success "${env_name}环境: 现有Resume类删除成功"
    elif echo "$delete_response" | grep -q "404"; then
        log_info "${env_name}环境: Resume类不存在，无需删除"
    else
        log_warn "${env_name}环境: Resume类删除失败，继续执行"
    fi
}

# 创建标准Schema
create_standard_schema() {
    local env_name="$1"
    local weaviate_url="$2"
    local ssh_cmd="$3"
    
    log_info "在${env_name}环境创建标准Resume Schema..."
    
    local schema_response
    if [ -n "$ssh_cmd" ]; then
        schema_response=$(execute_ssh_command "$ssh_cmd" "$weaviate_url" "curl -s -X POST ${LOCAL_WEAVIATE_URL}/v1/schema -H 'Content-Type: application/json' -d '$RESUME_SCHEMA'")
    else
        schema_response=$(curl -s -X POST "${weaviate_url}/v1/schema" -H 'Content-Type: application/json' -d "$RESUME_SCHEMA" 2>/dev/null)
    fi
    
    if echo "$schema_response" | grep -q '"class":"Resume"'; then
        log_success "${env_name}环境: 标准Resume Schema创建成功"
        return 0
    else
        log_error "${env_name}环境: 标准Resume Schema创建失败"
        log_error "响应内容: $schema_response"
        return 1
    fi
}

# 验证Schema一致性
verify_schema_consistency() {
    local env_name="$1"
    local weaviate_url="$2"
    local ssh_cmd="$3"
    
    log_info "验证${env_name}环境Schema一致性..."
    
    local schema_response
    if [ -n "$ssh_cmd" ]; then
        schema_response=$(execute_ssh_command "$ssh_cmd" "$weaviate_url" "curl -s ${LOCAL_WEAVIATE_URL}/v1/schema")
    else
        schema_response=$(curl -s "${weaviate_url}/v1/schema" 2>/dev/null)
    fi
    
    if [ -n "$schema_response" ]; then
        # 检查Schema结构
        local has_resume_class=$(echo "$schema_response" | grep -c '"class":"Resume"')
        local has_standard_description=$(echo "$schema_response" | grep -c '"description":"简历数据向量化存储"')
        
        if [ "$has_resume_class" -eq 1 ] && [ "$has_standard_description" -eq 1 ]; then
            log_success "${env_name}环境: Schema一致性验证通过"
            return 0
        else
            log_error "${env_name}环境: Schema一致性验证失败"
            log_error "Resume类数量: $has_resume_class"
            log_error "标准描述数量: $has_standard_description"
            return 1
        fi
    else
        log_error "${env_name}环境: 无法获取Schema进行验证"
        return 2
    fi
}

# 初始化单个环境
initialize_environment() {
    local env_name="$1"
    local weaviate_url="$2"
    local ssh_cmd="$3"
    
    log_info "开始初始化${env_name}环境..."
    
    # 1. 检查当前状态
    check_schema_status "$env_name" "$weaviate_url" "$ssh_cmd"
    local status_check_result=$?
    
    # 2. 清理现有Schema
    if [ $status_check_result -eq 0 ]; then
        cleanup_existing_schema "$env_name" "$weaviate_url" "$ssh_cmd"
        sleep 2  # 等待清理完成
    fi
    
    # 3. 创建标准Schema
    create_standard_schema "$env_name" "$weaviate_url" "$ssh_cmd"
    local create_result=$?
    
    if [ $create_result -eq 0 ]; then
        # 4. 验证Schema一致性
        sleep 2  # 等待创建完成
        verify_schema_consistency "$env_name" "$weaviate_url" "$ssh_cmd"
        local verify_result=$?
        
        if [ $verify_result -eq 0 ]; then
            log_success "${env_name}环境初始化完成"
            return 0
        else
            log_error "${env_name}环境Schema验证失败"
            return 1
        fi
    else
        log_error "${env_name}环境Schema创建失败"
        return 1
    fi
}

# 获取所有环境的Schema状态
get_all_schema_status() {
    log_info "获取三环境Schema状态..."
    
    local local_schema=$(curl -s "${LOCAL_WEAVIATE_URL}/v1/schema" 2>/dev/null)
    local alibaba_schema=$(execute_ssh_command "$ALIBABA_SSH_KEY" "$ALIBABA_CLOUD_IP" "curl -s ${LOCAL_WEAVIATE_URL}/v1/schema")
    local tencent_schema=$(execute_ssh_command "$TENCENT_SSH_KEY" "$TENCENT_CLOUD_IP" "curl -s ${LOCAL_WEAVIATE_URL}/v1/schema")
    
    echo "本地环境Schema:"
    echo "$local_schema" | jq '.classes[].class' 2>/dev/null || echo "无法解析"
    
    echo "阿里云环境Schema:"
    echo "$alibaba_schema" | jq '.classes[].class' 2>/dev/null || echo "无法解析"
    
    echo "腾讯云环境Schema:"
    echo "$tencent_schema" | jq '.classes[].class' 2>/dev/null || echo "无法解析"
}

# 主执行逻辑
main() {
    echo -e "${BLUE}🔧 Weaviate Schema一致性初始化脚本 (修复版) - $(date)${NC}"
    echo "======================================================"
    
    # 显示当前Schema状态
    get_all_schema_status
    echo ""
    
    # 初始化所有环境
    local total_environments=3
    local successful_environments=0
    
    # 1. 本地环境
    if initialize_environment "本地" "$LOCAL_WEAVIATE_URL" ""; then
        successful_environments=$((successful_environments + 1))
    fi
    echo ""
    
    # 2. 阿里云环境
    if initialize_environment "阿里云" "$ALIBABA_CLOUD_IP" "$ALIBABA_SSH_KEY"; then
        successful_environments=$((successful_environments + 1))
    fi
    echo ""
    
    # 3. 腾讯云环境
    if initialize_environment "腾讯云" "$TENCENT_CLOUD_IP" "$TENCENT_SSH_KEY"; then
        successful_environments=$((successful_environments + 1))
    fi
    echo ""
    
    # 显示最终状态
    echo "======================================================"
    if [ $successful_environments -eq $total_environments ]; then
        log_success "🎉 所有环境Schema初始化成功！"
        log_success "✅ 三环境Weaviate Schema一致性已恢复"
        
        echo ""
        log_info "最终Schema状态:"
        get_all_schema_status
        
        echo ""
        log_info "建议执行数据一致性测试验证:"
        echo "  ./comprehensive-data-consistency-test-fixed.sh"
        
    else
        log_error "❌ Schema初始化失败"
        log_error "成功环境: $successful_environments/$total_environments"
        exit 1
    fi
    
    echo ""
    echo -e "${GREEN}🎉 Weaviate Schema一致性初始化完成 - $(date)${NC}"
}

# 执行主函数
main "$@"
