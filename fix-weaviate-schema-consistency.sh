#!/bin/bash

# Weaviate Schema一致性修复脚本
# 解决三环境Weaviate Schema差异问题

echo "🔧 Weaviate Schema一致性修复脚本 - $(date)"
echo "======================================================"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 环境配置
LOCAL_WEAVIATE="http://localhost:8082"
ALIBABA_WEAVIATE="http://47.115.168.107:8082"  # 阿里云Weaviate映射到8082端口
TENCENT_WEAVIATE="http://101.33.251.158:8082"  # 腾讯云Weaviate映射到8082端口

# 标准Schema定义
STANDARD_SCHEMA='{
  "classes": [
    {
      "class": "Resume",
      "description": "简历向量数据",
      "vectorizer": "none",
      "properties": [
        {
          "name": "resume_id",
          "dataType": ["string"],
          "description": "简历ID"
        },
        {
          "name": "user_id",
          "dataType": ["string"],
          "description": "用户ID"
        },
        {
          "name": "content",
          "dataType": ["text"],
          "description": "简历内容"
        },
        {
          "name": "skills",
          "dataType": ["string[]"],
          "description": "技能列表"
        },
        {
          "name": "experience",
          "dataType": ["text"],
          "description": "工作经验"
        },
        {
          "name": "education",
          "dataType": ["text"],
          "description": "教育背景"
        },
        {
          "name": "created_at",
          "dataType": ["date"],
          "description": "创建时间"
        },
        {
          "name": "updated_at",
          "dataType": ["date"],
          "description": "更新时间"
        }
      ]
    },
    {
      "class": "Job",
      "description": "职位向量数据",
      "vectorizer": "none",
      "properties": [
        {
          "name": "job_id",
          "dataType": ["string"],
          "description": "职位ID"
        },
        {
          "name": "company_id",
          "dataType": ["string"],
          "description": "公司ID"
        },
        {
          "name": "title",
          "dataType": ["text"],
          "description": "职位标题"
        },
        {
          "name": "description",
          "dataType": ["text"],
          "description": "职位描述"
        },
        {
          "name": "requirements",
          "dataType": ["text"],
          "description": "职位要求"
        },
        {
          "name": "skills_required",
          "dataType": ["string[]"],
          "description": "所需技能"
        },
        {
          "name": "location",
          "dataType": ["string"],
          "description": "工作地点"
        },
        {
          "name": "salary_range",
          "dataType": ["string"],
          "description": "薪资范围"
        },
        {
          "name": "created_at",
          "dataType": ["date"],
          "description": "创建时间"
        }
      ]
    },
    {
      "class": "Company",
      "description": "公司向量数据",
      "vectorizer": "none",
      "properties": [
        {
          "name": "company_id",
          "dataType": ["string"],
          "description": "公司ID"
        },
        {
          "name": "name",
          "dataType": ["text"],
          "description": "公司名称"
        },
        {
          "name": "description",
          "dataType": ["text"],
          "description": "公司描述"
        },
        {
          "name": "industry",
          "dataType": ["string"],
          "description": "所属行业"
        },
        {
          "name": "size",
          "dataType": ["string"],
          "description": "公司规模"
        },
        {
          "name": "location",
          "dataType": ["string"],
          "description": "公司地点"
        },
        {
          "name": "website",
          "dataType": ["string"],
          "description": "公司网站"
        },
        {
          "name": "created_at",
          "dataType": ["date"],
          "description": "创建时间"
        }
      ]
    },
    {
      "class": "Skill",
      "description": "技能向量数据",
      "vectorizer": "none",
      "properties": [
        {
          "name": "skill_id",
          "dataType": ["string"],
          "description": "技能ID"
        },
        {
          "name": "name",
          "dataType": ["text"],
          "description": "技能名称"
        },
        {
          "name": "category",
          "dataType": ["string"],
          "description": "技能分类"
        },
        {
          "name": "description",
          "dataType": ["text"],
          "description": "技能描述"
        },
        {
          "name": "level",
          "dataType": ["string"],
          "description": "技能等级"
        },
        {
          "name": "created_at",
          "dataType": ["date"],
          "description": "创建时间"
        }
      ]
    }
  ]
}'

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

# 检查Weaviate连接
check_weaviate_connection() {
    local url=$1
    local env_name=$2
    
    log_info "检查 $env_name Weaviate连接: $url"
    
    if curl -s -f "$url/v1/meta" > /dev/null 2>&1; then
        log_success "$env_name Weaviate连接正常"
        return 0
    else
        log_error "$env_name Weaviate连接失败"
        return 1
    fi
}

# 获取当前Schema
get_current_schema() {
    local url=$1
    local env_name=$2
    
    log_info "获取 $env_name 当前Schema..."
    
    local schema_response=$(curl -s "$url/v1/schema" 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$schema_response" ]; then
        log_success "$env_name Schema获取成功"
        echo "$schema_response"
        return 0
    else
        log_error "$env_name Schema获取失败"
        return 1
    fi
}

# 清理现有Schema
clean_existing_schema() {
    local url=$1
    local env_name=$2
    
    log_info "清理 $env_name 现有Schema..."
    
    # 获取现有类列表
    local classes_response=$(curl -s "$url/v1/schema" 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$classes_response" ]; then
        # 解析并删除现有类
        local classes=$(echo "$classes_response" | python3 -c "
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

# 验证Schema一致性
verify_schema_consistency() {
    log_info "验证三环境Schema一致性..."
    
    local local_schema=$(get_current_schema "$LOCAL_WEAVIATE" "本地环境")
    local alibaba_schema=$(get_current_schema "$ALIBABA_WEAVIATE" "阿里云环境")
    local tencent_schema=$(get_current_schema "$TENCENT_WEAVIATE" "腾讯云环境")
    
    if [ "$local_schema" = "$alibaba_schema" ] && [ "$alibaba_schema" = "$tencent_schema" ]; then
        log_success "三环境Schema完全一致"
        return 0
    else
        log_warning "三环境Schema仍存在差异"
        return 1
    fi
}

# 主执行函数
main() {
    echo -e "${BLUE}🚀 开始Weaviate Schema一致性修复...${NC}"
    
    # 检查所有环境连接
    local all_connected=true
    
    if ! check_weaviate_connection "$LOCAL_WEAVIATE" "本地环境"; then
        all_connected=false
    fi
    
    if ! check_weaviate_connection "$ALIBABA_WEAVIATE" "阿里云环境"; then
        all_connected=false
    fi
    
    if ! check_weaviate_connection "$TENCENT_WEAVIATE" "腾讯云环境"; then
        all_connected=false
    fi
    
    if [ "$all_connected" = false ]; then
        log_error "部分环境连接失败，无法继续修复"
        exit 1
    fi
    
    echo ""
    log_info "所有环境连接正常，开始Schema修复..."
    
    # 为每个环境执行Schema修复
    local environments=("本地环境:$LOCAL_WEAVIATE" "阿里云环境:$ALIBABA_WEAVIATE" "腾讯云环境:$TENCENT_WEAVIATE")
    
    for env_info in "${environments[@]}"; do
        IFS=':' read -r env_name env_url <<< "$env_info"
        
        echo ""
        log_info "处理 $env_name..."
        
        # 清理现有Schema
        clean_existing_schema "$env_url" "$env_name"
        
        # 创建标准Schema
        if create_standard_schema "$env_url" "$env_name"; then
            log_success "$env_name Schema修复成功"
        else
            log_error "$env_name Schema修复失败"
        fi
    done
    
    echo ""
    log_info "等待Schema同步..."
    sleep 5
    
    # 验证Schema一致性
    echo ""
    if verify_schema_consistency; then
        log_success "🎉 Weaviate Schema一致性修复完成！"
        echo ""
        log_info "修复结果："
        echo "  ✅ 本地环境Schema已标准化"
        echo "  ✅ 阿里云环境Schema已标准化"
        echo "  ✅ 腾讯云环境Schema已标准化"
        echo "  ✅ 三环境Schema完全一致"
    else
        log_warning "Schema一致性验证失败，请手动检查"
    fi
    
    echo ""
    echo -e "${GREEN}🎉 Weaviate Schema一致性修复脚本执行完成 - $(date)${NC}"
}

# 执行主函数
main
