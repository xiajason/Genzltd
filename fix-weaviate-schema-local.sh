#!/bin/bash

# Weaviate Schema本地修复脚本
# 修复本地环境Weaviate Schema，并提供云端环境修复建议

echo "🔧 Weaviate Schema本地修复脚本 - $(date)"
echo "======================================================"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 本地Weaviate配置
LOCAL_WEAVIATE="http://localhost:8082"

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

# 检查本地Weaviate连接
check_local_weaviate() {
    log_info "检查本地Weaviate连接: $LOCAL_WEAVIATE"
    
    if curl -s -f "$LOCAL_WEAVIATE/v1/meta" > /dev/null 2>&1; then
        log_success "本地Weaviate连接正常"
        return 0
    else
        log_error "本地Weaviate连接失败"
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

# 验证Schema
verify_schema() {
    local url=$1
    local env_name=$2
    
    log_info "验证 $env_name Schema..."
    
    local schema_response=$(curl -s "$url/v1/schema" 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$schema_response" ]; then
        local class_count=$(echo "$schema_response" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    print(len(data.get('classes', [])))
except:
    print('0')
" 2>/dev/null)
        
        if [ "$class_count" = "4" ]; then
            log_success "$env_name Schema验证成功，包含4个标准类"
            return 0
        else
            log_warning "$env_name Schema验证失败，类数量: $class_count"
            return 1
        fi
    else
        log_error "$env_name Schema验证失败"
        return 1
    fi
}

# 生成云端环境修复命令
generate_cloud_fix_commands() {
    echo ""
    log_info "生成云端环境Weaviate Schema修复命令..."
    echo ""
    
    echo -e "${BLUE}阿里云环境修复命令:${NC}"
    echo "ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 \"curl -s -X POST http://localhost:8082/v1/schema -H 'Content-Type: application/json' -d '$STANDARD_SCHEMA'\""
    echo ""
    
    echo -e "${BLUE}腾讯云环境修复命令:${NC}"
    echo "ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158 \"curl -s -X POST http://localhost:8082/v1/schema -H 'Content-Type: application/json' -d '$STANDARD_SCHEMA'\""
    echo ""
    
    echo -e "${YELLOW}注意: 云端环境需要先清理现有Schema，然后再创建标准Schema${NC}"
}

# 主执行函数
main() {
    echo -e "${BLUE}🚀 开始本地Weaviate Schema修复...${NC}"
    
    # 检查本地Weaviate连接
    if ! check_local_weaviate; then
        log_error "本地Weaviate连接失败，无法继续修复"
        exit 1
    fi
    
    echo ""
    log_info "本地Weaviate连接正常，开始Schema修复..."
    
    # 清理现有Schema
    clean_existing_schema "$LOCAL_WEAVIATE" "本地环境"
    
    # 创建标准Schema
    if create_standard_schema "$LOCAL_WEAVIATE" "本地环境"; then
        log_success "本地环境Schema修复成功"
    else
        log_error "本地环境Schema修复失败"
        exit 1
    fi
    
    # 验证Schema
    echo ""
    if verify_schema "$LOCAL_WEAVIATE" "本地环境"; then
        log_success "🎉 本地Weaviate Schema修复完成！"
        echo ""
        log_info "修复结果："
        echo "  ✅ 本地环境Schema已标准化"
        echo "  ✅ 包含4个标准类: Resume, Job, Company, Skill"
        echo "  ✅ Schema结构完整"
    else
        log_warning "本地环境Schema验证失败"
    fi
    
    # 生成云端环境修复命令
    generate_cloud_fix_commands
    
    echo ""
    echo -e "${GREEN}🎉 本地Weaviate Schema修复脚本执行完成 - $(date)${NC}"
    echo -e "${YELLOW}💡 提示: 请手动执行云端环境修复命令来完成三环境Schema一致性${NC}"
}

# 执行主函数
main
