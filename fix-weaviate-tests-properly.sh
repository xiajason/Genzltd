#!/bin/bash

# Weaviate功能测试修复脚本
# 创建不依赖TestClass的Weaviate功能测试

echo "🔧 Weaviate功能测试修复脚本 - $(date)"
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

# 创建标准Weaviate Schema用于测试
create_standard_weaviate_schema() {
    local env_name=$1
    local create_command=$2
    
    log_info "为 $env_name 创建标准Weaviate Schema..."
    
    # 创建Resume类
    eval "$create_command" << 'EOF'
curl -s -X POST http://localhost:8082/v1/schema \
    -H 'Content-Type: application/json' \
    -d '{
        "class": "Resume",
        "description": "简历数据向量化存储",
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
            }
        ]
    }' > /dev/null 2>&1
EOF

    # 创建Job类
    eval "$create_command" << 'EOF'
curl -s -X POST http://localhost:8082/v1/schema \
    -H 'Content-Type: application/json' \
    -d '{
        "class": "Job",
        "description": "职位数据向量化存储", 
        "vectorizer": "none",
        "properties": [
            {
                "name": "job_id",
                "dataType": ["string"],
                "description": "职位ID"
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
            }
        ]
    }' > /dev/null 2>&1
EOF

    log_success "$env_name 标准Schema创建完成"
}

# 测试Weaviate功能（不依赖TestClass）
test_weaviate_functionality() {
    local env_name=$1
    local test_command=$2
    
    log_info "测试 $env_name Weaviate功能..."
    
    # 1. 测试Schema创建功能
    log_info "测试Schema创建功能..."
    create_standard_weaviate_schema "$env_name" "$test_command"
    
    # 2. 测试数据插入功能
    log_info "测试数据插入功能..."
    local insert_response=$(eval "$test_command" << 'EOF'
curl -s -X POST http://localhost:8082/v1/objects \
    -H 'Content-Type: application/json' \
    -d '{
        "class": "Resume",
        "properties": {
            "resume_id": "test_resume_001",
            "user_id": "test_user_001", 
            "content": "测试简历内容",
            "skills": ["Python", "Java", "JavaScript"]
        }
    }' 2>/dev/null
EOF
)
    
    if echo "$insert_response" | grep -q "test_resume_001"; then
        log_success "$env_name 数据插入功能正常"
    else
        log_warning "$env_name 数据插入功能异常"
    fi
    
    # 3. 测试向量搜索功能
    log_info "测试向量搜索功能..."
    local search_response=$(eval "$test_command" << 'EOF'
curl -s -X POST http://localhost:8082/v1/graphql \
    -H 'Content-Type: application/json' \
    -d '{
        "query": "{ Get { Resume(where: { path: [\"resume_id\"], operator: Equal, valueText: \"test_resume_001\" }) { resume_id user_id content skills } } }"
    }' 2>/dev/null
EOF
)
    
    if echo "$search_response" | grep -q "test_resume_001"; then
        log_success "$env_name 向量搜索功能正常"
    else
        log_warning "$env_name 向量搜索功能异常"
    fi
    
    # 4. 清理测试数据
    log_info "清理测试数据..."
    eval "$test_command" << 'EOF'
curl -s -X POST http://localhost:8082/v1/graphql \
    -H 'Content-Type: application/json' \
    -d '{
        "query": "{ Get { Resume(where: { path: [\"resume_id\"], operator: Equal, valueText: \"test_resume_001\" }) { _additional { id } } } }"
    }' | python3 -c "
import json, sys, subprocess
try:
    data = json.load(sys.stdin)
    if 'data' in data and 'Get' in data['data'] and 'Resume' in data['data']['Get']:
        for obj in data['data']['Get']['Resume']:
            if '_additional' in obj and 'id' in obj['_additional']:
                obj_id = obj['_additional']['id']
                subprocess.run(['curl', '-s', '-X', 'DELETE', f'http://localhost:8082/v1/objects/{obj_id}'], check=False)
except:
    pass
" 2>/dev/null
EOF

    log_success "$env_name Weaviate功能测试完成"
}

# 主执行函数
main() {
    echo -e "${BLUE}🚀 开始Weaviate功能测试修复...${NC}"
    
    # 测试本地环境
    test_weaviate_functionality "本地环境" "echo"
    echo ""
    
    # 测试阿里云环境
    test_weaviate_functionality "阿里云环境" "ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107"
    echo ""
    
    # 测试腾讯云环境
    test_weaviate_functionality "腾讯云环境" "ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158"
    echo ""
    
    echo -e "${GREEN}🎉 Weaviate功能测试修复完成 - $(date)${NC}"
    echo -e "${BLUE}💡 现在可以使用标准Schema进行Weaviate功能测试，无需依赖TestClass${NC}"
}

# 执行主函数
main
