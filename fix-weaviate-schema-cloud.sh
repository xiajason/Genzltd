#!/bin/bash

# 云端环境Weaviate Schema修复脚本

echo "🔧 云端环境Weaviate Schema修复脚本 - $(date)"
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

# 修复阿里云环境
fix_alibaba_weaviate() {
    log_info "修复阿里云环境Weaviate Schema..."
    
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
    
    # 创建标准Schema - 分步创建
    log_info "创建阿里云标准Schema..."
    
    # 创建Resume类
    ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "curl -s -X POST http://localhost:8082/v1/schema -H 'Content-Type: application/json' -d '{
        \"class\": \"Resume\",
        \"description\": \"简历向量数据\",
        \"vectorizer\": \"none\",
        \"properties\": [
            {\"name\": \"resume_id\", \"dataType\": [\"string\"], \"description\": \"简历ID\"},
            {\"name\": \"user_id\", \"dataType\": [\"string\"], \"description\": \"用户ID\"},
            {\"name\": \"content\", \"dataType\": [\"text\"], \"description\": \"简历内容\"},
            {\"name\": \"skills\", \"dataType\": [\"string[]\"], \"description\": \"技能列表\"},
            {\"name\": \"created_at\", \"dataType\": [\"date\"], \"description\": \"创建时间\"}
        ]
    }'"
    
    # 创建Job类
    ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "curl -s -X POST http://localhost:8082/v1/schema -H 'Content-Type: application/json' -d '{
        \"class\": \"Job\",
        \"description\": \"职位向量数据\",
        \"vectorizer\": \"none\",
        \"properties\": [
            {\"name\": \"job_id\", \"dataType\": [\"string\"], \"description\": \"职位ID\"},
            {\"name\": \"company_id\", \"dataType\": [\"string\"], \"description\": \"公司ID\"},
            {\"name\": \"title\", \"dataType\": [\"text\"], \"description\": \"职位标题\"},
            {\"name\": \"description\", \"dataType\": [\"text\"], \"description\": \"职位描述\"},
            {\"name\": \"created_at\", \"dataType\": [\"date\"], \"description\": \"创建时间\"}
        ]
    }'"
    
    # 创建Company类
    ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "curl -s -X POST http://localhost:8082/v1/schema -H 'Content-Type: application/json' -d '{
        \"class\": \"Company\",
        \"description\": \"公司向量数据\",
        \"vectorizer\": \"none\",
        \"properties\": [
            {\"name\": \"company_id\", \"dataType\": [\"string\"], \"description\": \"公司ID\"},
            {\"name\": \"name\", \"dataType\": [\"text\"], \"description\": \"公司名称\"},
            {\"name\": \"description\", \"dataType\": [\"text\"], \"description\": \"公司描述\"},
            {\"name\": \"industry\", \"dataType\": [\"string\"], \"description\": \"所属行业\"},
            {\"name\": \"created_at\", \"dataType\": [\"date\"], \"description\": \"创建时间\"}
        ]
    }'"
    
    # 创建Skill类
    ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "curl -s -X POST http://localhost:8082/v1/schema -H 'Content-Type: application/json' -d '{
        \"class\": \"Skill\",
        \"description\": \"技能向量数据\",
        \"vectorizer\": \"none\",
        \"properties\": [
            {\"name\": \"skill_id\", \"dataType\": [\"string\"], \"description\": \"技能ID\"},
            {\"name\": \"name\", \"dataType\": [\"text\"], \"description\": \"技能名称\"},
            {\"name\": \"category\", \"dataType\": [\"string\"], \"description\": \"技能分类\"},
            {\"name\": \"created_at\", \"dataType\": [\"date\"], \"description\": \"创建时间\"}
        ]
    }'"
    
    log_success "阿里云环境Schema修复完成"
}

# 修复腾讯云环境
fix_tencent_weaviate() {
    log_info "修复腾讯云环境Weaviate Schema..."
    
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
    
    # 创建标准Schema - 分步创建
    log_info "创建腾讯云标准Schema..."
    
    # 创建Resume类
    ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158 "curl -s -X POST http://localhost:8082/v1/schema -H 'Content-Type: application/json' -d '{
        \"class\": \"Resume\",
        \"description\": \"简历向量数据\",
        \"vectorizer\": \"none\",
        \"properties\": [
            {\"name\": \"resume_id\", \"dataType\": [\"string\"], \"description\": \"简历ID\"},
            {\"name\": \"user_id\", \"dataType\": [\"string\"], \"description\": \"用户ID\"},
            {\"name\": \"content\", \"dataType\": [\"text\"], \"description\": \"简历内容\"},
            {\"name\": \"skills\", \"dataType\": [\"string[]\"], \"description\": \"技能列表\"},
            {\"name\": \"created_at\", \"dataType\": [\"date\"], \"description\": \"创建时间\"}
        ]
    }'"
    
    # 创建Job类
    ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158 "curl -s -X POST http://localhost:8082/v1/schema -H 'Content-Type: application/json' -d '{
        \"class\": \"Job\",
        \"description\": \"职位向量数据\",
        \"vectorizer\": \"none\",
        \"properties\": [
            {\"name\": \"job_id\", \"dataType\": [\"string\"], \"description\": \"职位ID\"},
            {\"name\": \"company_id\", \"dataType\": [\"string\"], \"description\": \"公司ID\"},
            {\"name\": \"title\", \"dataType\": [\"text\"], \"description\": \"职位标题\"},
            {\"name\": \"description\", \"dataType\": [\"text\"], \"description\": \"职位描述\"},
            {\"name\": \"created_at\", \"dataType\": [\"date\"], \"description\": \"创建时间\"}
        ]
    }'"
    
    # 创建Company类
    ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158 "curl -s -X POST http://localhost:8082/v1/schema -H 'Content-Type: application/json' -d '{
        \"class\": \"Company\",
        \"description\": \"公司向量数据\",
        \"vectorizer\": \"none\",
        \"properties\": [
            {\"name\": \"company_id\", \"dataType\": [\"string\"], \"description\": \"公司ID\"},
            {\"name\": \"name\", \"dataType\": [\"text\"], \"description\": \"公司名称\"},
            {\"name\": \"description\", \"dataType\": [\"text\"], \"description\": \"公司描述\"},
            {\"name\": \"industry\", \"dataType\": [\"string\"], \"description\": \"所属行业\"},
            {\"name\": \"created_at\", \"dataType\": [\"date\"], \"description\": \"创建时间\"}
        ]
    }'"
    
    # 创建Skill类
    ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158 "curl -s -X POST http://localhost:8082/v1/schema -H 'Content-Type: application/json' -d '{
        \"class\": \"Skill\",
        \"description\": \"技能向量数据\",
        \"vectorizer\": \"none\",
        \"properties\": [
            {\"name\": \"skill_id\", \"dataType\": [\"string\"], \"description\": \"技能ID\"},
            {\"name\": \"name\", \"dataType\": [\"text\"], \"description\": \"技能名称\"},
            {\"name\": \"category\", \"dataType\": [\"string\"], \"description\": \"技能分类\"},
            {\"name\": \"created_at\", \"dataType\": [\"date\"], \"description\": \"创建时间\"}
        ]
    }'"
    
    log_success "腾讯云环境Schema修复完成"
}

# 验证三环境Schema一致性
verify_schema_consistency() {
    log_info "验证三环境Schema一致性..."
    
    # 获取本地Schema
    local local_schema=$(curl -s http://localhost:8082/v1/schema 2>/dev/null)
    local local_classes=$(echo "$local_schema" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    classes = [c.get('class', '') for c in data.get('classes', [])]
    print('|'.join(sorted(classes)))
except:
    print('')
" 2>/dev/null)
    
    # 获取阿里云Schema
    local alibaba_schema=$(ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "curl -s http://localhost:8082/v1/schema" 2>/dev/null)
    local alibaba_classes=$(echo "$alibaba_schema" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    classes = [c.get('class', '') for c in data.get('classes', [])]
    print('|'.join(sorted(classes)))
except:
    print('')
" 2>/dev/null)
    
    # 获取腾讯云Schema
    local tencent_schema=$(ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158 "curl -s http://localhost:8082/v1/schema" 2>/dev/null)
    local tencent_classes=$(echo "$tencent_schema" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    classes = [c.get('class', '') for c in data.get('classes', [])]
    print('|'.join(sorted(classes)))
except:
    print('')
" 2>/dev/null)
    
    echo "本地环境类: $local_classes"
    echo "阿里云环境类: $alibaba_classes"
    echo "腾讯云环境类: $tencent_classes"
    
    if [ "$local_classes" = "$alibaba_classes" ] && [ "$alibaba_classes" = "$tencent_classes" ]; then
        log_success "三环境Schema完全一致"
        return 0
    else
        log_warning "三环境Schema仍存在差异"
        return 1
    fi
}

# 主执行函数
main() {
    echo -e "${BLUE}🚀 开始云端环境Weaviate Schema修复...${NC}"
    
    # 修复阿里云环境
    fix_alibaba_weaviate
    
    echo ""
    
    # 修复腾讯云环境
    fix_tencent_weaviate
    
    echo ""
    log_info "等待Schema同步..."
    sleep 3
    
    # 验证Schema一致性
    verify_schema_consistency
    
    echo ""
    echo -e "${GREEN}🎉 云端环境Weaviate Schema修复脚本执行完成 - $(date)${NC}"
}

# 执行主函数
main
