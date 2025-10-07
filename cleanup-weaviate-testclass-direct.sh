#!/bin/bash

# Weaviate TestClass直接清理脚本
# 直接清理所有环境中的TestClass，解决Schema一致性问题

echo "🔧 Weaviate TestClass直接清理脚本 - $(date)"
echo "======================================================"

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

# 清理本地环境TestClass
cleanup_local_testclass() {
    log_info "清理本地环境TestClass..."
    
    # 1. 删除TestClass
    curl -s -X DELETE http://localhost:8082/v1/schema/TestClass > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        log_success "本地TestClass删除成功"
    else
        log_warning "本地TestClass删除失败或不存在"
    fi
    
    # 2. 删除可能存在的测试数据对象
    curl -s -X POST http://localhost:8082/v1/graphql \
        -H 'Content-Type: application/json' \
        -d '{"query": "{ Get { TestClass { _additional { id } } } }"}' 2>/dev/null | \
        python3 -c "
import json, sys, subprocess
try:
    data = json.load(sys.stdin)
    if 'data' in data and 'Get' in data['data'] and 'TestClass' in data['data']['Get']:
        for obj in data['data']['Get']['TestClass']:
            if '_additional' in obj and 'id' in obj['_additional']:
                obj_id = obj['_additional']['id']
                print(f'删除测试对象: {obj_id}')
                subprocess.run(['curl', '-s', '-X', 'DELETE', f'http://localhost:8082/v1/objects/{obj_id}'], check=False)
except:
    pass
" 2>/dev/null
}

# 清理阿里云环境TestClass
cleanup_alibaba_testclass() {
    log_info "清理阿里云环境TestClass..."
    
    # 1. 删除TestClass
    ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "curl -s -X DELETE http://localhost:8082/v1/schema/TestClass" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        log_success "阿里云TestClass删除成功"
    else
        log_warning "阿里云TestClass删除失败或不存在"
    fi
    
    # 2. 删除可能存在的测试数据对象
    ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "curl -s -X POST http://localhost:8082/v1/graphql \
        -H 'Content-Type: application/json' \
        -d '{\"query\": \"{ Get { TestClass { _additional { id } } } }\"}'" 2>/dev/null | \
        python3 -c "
import json, sys, subprocess
try:
    data = json.load(sys.stdin)
    if 'data' in data and 'Get' in data['data'] and 'TestClass' in data['data']['Get']:
        for obj in data['data']['Get']['TestClass']:
            if '_additional' in obj and 'id' in obj['_additional']:
                obj_id = obj['_additional']['id']
                print(f'删除测试对象: {obj_id}')
                subprocess.run(['curl', '-s', '-X', 'DELETE', f'http://localhost:8082/v1/objects/{obj_id}'], check=False)
except:
    pass
" 2>/dev/null
}

# 清理腾讯云环境TestClass
cleanup_tencent_testclass() {
    log_info "清理腾讯云环境TestClass..."
    
    # 1. 删除TestClass
    ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158 "curl -s -X DELETE http://localhost:8082/v1/schema/TestClass" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        log_success "腾讯云TestClass删除成功"
    else
        log_warning "腾讯云TestClass删除失败或不存在"
    fi
    
    # 2. 删除可能存在的测试数据对象
    ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158 "curl -s -X POST http://localhost:8082/v1/graphql \
        -H 'Content-Type: application/json' \
        -d '{\"query\": \"{ Get { TestClass { _additional { id } } } }\"}'" 2>/dev/null | \
        python3 -c "
import json, sys, subprocess
try:
    data = json.load(sys.stdin)
    if 'data' in data and 'Get' in data['data'] and 'TestClass' in data['data']['Get']:
        for obj in data['data']['Get']['TestClass']:
            if '_additional' in obj and 'id' in obj['_additional']:
                obj_id = obj['_additional']['id']
                print(f'删除测试对象: {obj_id}')
                subprocess.run(['curl', '-s', '-X', 'DELETE', f'http://localhost:8082/v1/objects/{obj_id}'], check=False)
except:
    pass
" 2>/dev/null
}

# 验证三环境Schema一致性
verify_schema_consistency() {
    log_info "验证三环境Schema一致性..."
    
    # 获取各环境Schema
    local local_schema=$(curl -s http://localhost:8082/v1/schema 2>/dev/null)
    local alibaba_schema=$(ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "curl -s http://localhost:8082/v1/schema" 2>/dev/null)
    local tencent_schema=$(ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158 "curl -s http://localhost:8082/v1/schema" 2>/dev/null)
    
    # 提取类名列表
    local local_classes=$(echo "$local_schema" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    classes = [c.get('class', '') for c in data.get('classes', [])]
    print('|'.join(sorted(classes)))
except:
    print('')
" 2>/dev/null)
    
    local alibaba_classes=$(echo "$alibaba_schema" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    classes = [c.get('class', '') for c in data.get('classes', [])]
    print('|'.join(sorted(classes)))
except:
    print('')
" 2>/dev/null)
    
    local tencent_classes=$(echo "$tencent_schema" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    classes = [c.get('class', '') for c in data.get('classes', [])]
    print('|'.join(sorted(classes)))
except:
    print('')
" 2>/dev/null)
    
    echo ""
    log_info "Schema类名对比:"
    echo "  本地环境: $local_classes"
    echo "  阿里云环境: $alibaba_classes"
    echo "  腾讯云环境: $tencent_classes"
    
    if [ "$local_classes" = "$alibaba_classes" ] && [ "$alibaba_classes" = "$tencent_classes" ]; then
        log_success "🎉 三环境Schema完全一致！"
        return 0
    else
        log_warning "三环境Schema仍存在差异"
        return 1
    fi
}

# 主执行函数
main() {
    echo -e "${BLUE}🚀 开始Weaviate TestClass直接清理...${NC}"
    
    # 清理各环境TestClass
    cleanup_local_testclass
    echo ""
    
    cleanup_alibaba_testclass
    echo ""
    
    cleanup_tencent_testclass
    echo ""
    
    # 等待清理完成
    log_info "等待清理完成..."
    sleep 3
    
    # 验证Schema一致性
    if verify_schema_consistency; then
        log_success "🎉 Weaviate TestClass清理成功！Schema一致性已恢复！"
    else
        log_warning "Weaviate Schema仍存在差异，需要进一步检查"
    fi
    
    echo ""
    echo -e "${GREEN}🎉 Weaviate TestClass直接清理完成 - $(date)${NC}"
}

# 执行主函数
main
