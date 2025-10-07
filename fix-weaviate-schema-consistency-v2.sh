#!/bin/bash

# Weaviate Schema一致性修复脚本 v2.0
# 基于之前成功经验，修复三环境Weaviate Schema差异

echo "🔧 Weaviate Schema一致性修复脚本 v2.0 - $(date)"
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

# 标准Schema定义 - 基于成功经验
STANDARD_SCHEMA='{
  "classes": [
    {
      "class": "Resume",
      "description": "简历向量数据",
      "vectorizer": "none",
      "properties": [
        {"name": "resume_id", "dataType": ["string"], "description": "简历ID"},
        {"name": "user_id", "dataType": ["string"], "description": "用户ID"},
        {"name": "content", "dataType": ["text"], "description": "简历内容"},
        {"name": "skills", "dataType": ["string[]"], "description": "技能列表"},
        {"name": "experience", "dataType": ["text"], "description": "工作经验"},
        {"name": "education", "dataType": ["text"], "description": "教育背景"},
        {"name": "created_at", "dataType": ["date"], "description": "创建时间"},
        {"name": "updated_at", "dataType": ["date"], "description": "更新时间"}
      ]
    },
    {
      "class": "Job",
      "description": "职位向量数据",
      "vectorizer": "none",
      "properties": [
        {"name": "job_id", "dataType": ["string"], "description": "职位ID"},
        {"name": "company_id", "dataType": ["string"], "description": "公司ID"},
        {"name": "title", "dataType": ["text"], "description": "职位标题"},
        {"name": "description", "dataType": ["text"], "description": "职位描述"},
        {"name": "requirements", "dataType": ["text"], "description": "职位要求"},
        {"name": "skills_required", "dataType": ["string[]"], "description": "所需技能"},
        {"name": "location", "dataType": ["string"], "description": "工作地点"},
        {"name": "salary_range", "dataType": ["string"], "description": "薪资范围"},
        {"name": "created_at", "dataType": ["date"], "description": "创建时间"}
      ]
    },
    {
      "class": "Company",
      "description": "公司向量数据",
      "vectorizer": "none",
      "properties": [
        {"name": "company_id", "dataType": ["string"], "description": "公司ID"},
        {"name": "name", "dataType": ["text"], "description": "公司名称"},
        {"name": "description", "dataType": ["text"], "description": "公司描述"},
        {"name": "industry", "dataType": ["string"], "description": "所属行业"},
        {"name": "size", "dataType": ["string"], "description": "公司规模"},
        {"name": "location", "dataType": ["string"], "description": "公司地点"},
        {"name": "website", "dataType": ["string"], "description": "公司网站"},
        {"name": "created_at", "dataType": ["date"], "description": "创建时间"}
      ]
    },
    {
      "class": "Skill",
      "description": "技能向量数据",
      "vectorizer": "none",
      "properties": [
        {"name": "skill_id", "dataType": ["string"], "description": "技能ID"},
        {"name": "name", "dataType": ["text"], "description": "技能名称"},
        {"name": "category", "dataType": ["string"], "description": "技能分类"},
        {"name": "description", "dataType": ["text"], "description": "技能描述"},
        {"name": "level", "dataType": ["string"], "description": "技能等级"},
        {"name": "created_at", "dataType": ["date"], "description": "创建时间"}
      ]
    }
  ]
}'

# 获取当前Schema类名列表
get_schema_classes() {
    local url=$1
    local env_name=$2
    
    log_info "获取 $env_name Schema类名列表..."
    
    local schema_response=$(curl -s "$url/v1/schema" 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$schema_response" ]; then
        local classes=$(echo "$schema_response" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    classes = [c.get('class', '') for c in data.get('classes', [])]
    print('|'.join(sorted(classes)))
except:
    print('')
" 2>/dev/null)
        echo "$classes"
        return 0
    else
        log_error "$env_name Schema获取失败"
        echo ""
        return 1
    fi
}

# 清理指定环境的Schema
clean_environment_schema() {
    local url=$1
    local env_name=$2
    
    log_info "清理 $env_name 现有Schema..."
    
    # 获取现有类列表
    local schema_response=$(curl -s "$url/v1/schema" 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$schema_response" ]; then
        # 解析并删除现有类
        local classes=$(echo "$schema_response" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    for class_info in data.get('classes', []):
        print(class_info.get('class', ''))
except:
    pass
" 2>/dev/null)
        
        for class_name in $classes; do
            if [ -n "$class_name" ]; then
                log_info "删除类: $class_name"
                curl -s -X DELETE "$url/v1/schema/$class_name" > /dev/null 2>&1
                if [ $? -eq 0 ]; then
                    log_success "成功删除类: $class_name"
                else
                    log_warning "删除类失败: $class_name"
                fi
            fi
        done
        
        log_success "$env_name Schema清理完成"
    else
        log_warning "$env_name 无法获取现有Schema，跳过清理"
    fi
}

# 创建标准Schema
create_standard_schema() {
    local url=$1
    local env_name=$2
    
    log_info "创建 $env_name 标准Schema..."
    
    local response=$(curl -s -X POST "$url/v1/schema" \
        -H "Content-Type: application/json" \
        -d "$STANDARD_SCHEMA" 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        log_success "$env_name 标准Schema创建成功"
        return 0
    else
        log_error "$env_name 标准Schema创建失败"
        return 1
    fi
}

# 修复本地环境
fix_local_weaviate() {
    log_info "修复本地环境Weaviate Schema..."
    
    local LOCAL_WEAVIATE="http://localhost:8082"
    
    # 检查连接
    if ! curl -s -f "$LOCAL_WEAVIATE/v1/meta" > /dev/null 2>&1; then
        log_error "本地Weaviate连接失败，跳过修复"
        return 1
    fi
    
    # 清理现有Schema
    clean_environment_schema "$LOCAL_WEAVIATE" "本地环境"
    
    # 创建标准Schema
    if create_standard_schema "$LOCAL_WEAVIATE" "本地环境"; then
        log_success "本地环境Schema修复成功"
        return 0
    else
        log_error "本地环境Schema修复失败"
        return 1
    fi
}

# 修复阿里云环境
fix_alibaba_weaviate() {
    log_info "修复阿里云环境Weaviate Schema..."
    
    # 检查SSH连接
    if ! ssh -i ~/.ssh/cross_cloud_key -o ConnectTimeout=10 root@47.115.168.107 "echo 'SSH连接正常'" > /dev/null 2>&1; then
        log_error "阿里云SSH连接失败，跳过修复"
        return 1
    fi
    
    # 清理现有Schema
    log_info "清理阿里云现有Schema..."
    ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "curl -s http://localhost:8082/v1/schema | python3 -c \"
import json, sys, subprocess
try:
    data = json.load(sys.stdin)
    for class_info in data.get('classes', []):
        class_name = class_info.get('class', '')
        if class_name:
            print(f'删除类: {class_name}')
            subprocess.run(['curl', '-s', '-X', 'DELETE', f'http://localhost:8082/v1/schema/{class_name}'], check=False)
except Exception as e:
    print(f'清理失败: {e}')
\""
    
    # 创建标准Schema
    log_info "创建阿里云标准Schema..."
    ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "curl -s -X POST http://localhost:8082/v1/schema -H 'Content-Type: application/json' -d '$STANDARD_SCHEMA'" > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        log_success "阿里云环境Schema修复成功"
        return 0
    else
        log_error "阿里云环境Schema修复失败"
        return 1
    fi
}

# 修复腾讯云环境
fix_tencent_weaviate() {
    log_info "修复腾讯云环境Weaviate Schema..."
    
    # 检查SSH连接
    if ! ssh -i ~/.ssh/basic.pem -o ConnectTimeout=10 ubuntu@101.33.251.158 "echo 'SSH连接正常'" > /dev/null 2>&1; then
        log_error "腾讯云SSH连接失败，跳过修复"
        return 1
    fi
    
    # 清理现有Schema
    log_info "清理腾讯云现有Schema..."
    ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158 "curl -s http://localhost:8082/v1/schema | python3 -c \"
import json, sys, subprocess
try:
    data = json.load(sys.stdin)
    for class_info in data.get('classes', []):
        class_name = class_info.get('class', '')
        if class_name:
            print(f'删除类: {class_name}')
            subprocess.run(['curl', '-s', '-X', 'DELETE', f'http://localhost:8082/v1/schema/{class_name}'], check=False)
except Exception as e:
    print(f'清理失败: {e}')
\""
    
    # 创建标准Schema
    log_info "创建腾讯云标准Schema..."
    ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158 "curl -s -X POST http://localhost:8082/v1/schema -H 'Content-Type: application/json' -d '$STANDARD_SCHEMA'" > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        log_success "腾讯云环境Schema修复成功"
        return 0
    else
        log_error "腾讯云环境Schema修复失败"
        return 1
    fi
}

# 验证三环境Schema一致性
verify_schema_consistency() {
    log_info "验证三环境Schema一致性..."
    
    # 获取各环境Schema
    local local_classes=$(get_schema_classes "http://localhost:8082" "本地环境")
    local alibaba_classes=$(ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "curl -s http://localhost:8082/v1/schema" 2>/dev/null | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    classes = [c.get('class', '') for c in data.get('classes', [])]
    print('|'.join(sorted(classes)))
except:
    print('')
" 2>/dev/null)
    local tencent_classes=$(ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158 "curl -s http://localhost:8082/v1/schema" 2>/dev/null | python3 -c "
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
    echo -e "${BLUE}🚀 开始Weaviate Schema一致性修复...${NC}"
    
    local success_count=0
    local total_count=3
    
    # 修复本地环境
    echo ""
    if fix_local_weaviate; then
        ((success_count++))
    fi
    
    # 修复阿里云环境
    echo ""
    if fix_alibaba_weaviate; then
        ((success_count++))
    fi
    
    # 修复腾讯云环境
    echo ""
    if fix_tencent_weaviate; then
        ((success_count++))
    fi
    
    echo ""
    log_info "等待Schema同步..."
    sleep 5
    
    # 验证Schema一致性
    echo ""
    verify_schema_consistency
    
    echo ""
    echo -e "${BLUE}📊 修复结果统计:${NC}"
    echo "  成功修复: $success_count/$total_count 个环境"
    
    if [ $success_count -eq $total_count ]; then
        echo -e "${GREEN}🎉 Weaviate Schema一致性修复完成！${NC}"
        echo -e "${GREEN}✅ 所有三环境Schema已统一${NC}"
    else
        echo -e "${YELLOW}⚠️ 部分环境修复失败，请检查网络连接和服务状态${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}💡 建议:${NC}"
    echo "  1. 运行数据一致性测试验证修复效果"
    echo "  2. 定期检查Schema一致性"
    echo "  3. 建立自动化Schema同步机制"
    
    echo ""
    echo -e "${GREEN}🎉 Weaviate Schema一致性修复脚本执行完成 - $(date)${NC}"
}

# 执行主函数
main
