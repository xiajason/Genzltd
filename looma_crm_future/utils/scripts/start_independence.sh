#!/bin/bash

# Looma CRM重构项目独立化启动脚本
# 创建日期: 2025年9月24日
# 版本: v1.0
# 目标: 立即启动独立化工作

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
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

log_independence() {
    echo -e "${PURPLE}[INDEPENDENCE]${NC} $1"
}

# 检查是否在正确的目录
check_directory() {
    log_info "检查工作目录..."
    if [[ ! -f "looma_crm_ai_refactoring/requirements.txt" ]]; then
        log_error "请在项目根目录下运行此脚本"
        exit 1
    fi
    log_success "工作目录检查通过"
}

# 检查第三阶段成果
check_phase3_results() {
    log_info "检查第三阶段成果..."
    
    # 检查测试报告
    if [[ -f "looma_crm_ai_refactoring/docs/data_isolation_permission_test_report.json" ]]; then
        log_success "数据隔离权限测试报告存在"
    else
        log_warning "数据隔离权限测试报告不存在，将运行测试验证"
        cd looma_crm_ai_refactoring
        python scripts/test_data_isolation_permissions.py
        cd ..
    fi
    
    # 检查MongoDB集成
    if [[ -f "looma_crm_ai_refactoring/shared/database/unified_data_access.py" ]]; then
        if grep -q "mongodb_client" looma_crm_ai_refactoring/shared/database/unified_data_access.py; then
            log_success "MongoDB集成已实现"
        else
            log_error "MongoDB集成未实现"
            exit 1
        fi
    else
        log_error "统一数据访问层不存在"
        exit 1
    fi
    
    log_success "第三阶段成果检查通过"
}

# 创建独立化工作目录
create_independence_directories() {
    log_info "创建独立化工作目录..."
    
    cd looma_crm_ai_refactoring
    
    # 创建独立化目录结构
    mkdir -p independence/{database,code,scripts,config,monitoring}
    mkdir -p independence/database/{neo4j,weaviate,postgresql,redis,elasticsearch,mongodb}
    mkdir -p independence/code/{models,services,api,utils}
    mkdir -p independence/scripts/{deployment,management,monitoring}
    mkdir -p independence/config/{environment,system,security}
    mkdir -p independence/monitoring/{logs,metrics,alerts}
    
    log_success "独立化工作目录创建完成"
    cd ..
}

# 初始化独立化跟踪系统
init_independence_tracking() {
    log_info "初始化独立化跟踪系统..."
    
    cd looma_crm_ai_refactoring
    
    # 创建独立化状态文件
    cat > docs/INDEPENDENCE_STATUS.json << 'EOF'
{
  "independence": {
    "start_date": "2025-09-24",
    "current_phase": "1.1",
    "current_milestone": "数据库独立化",
    "overall_progress": 0,
    "phases": {
      "1": {
        "name": "基础独立化",
        "start_date": "2025-09-24",
        "end_date": "2025-10-20",
        "progress": 0,
        "milestones": {
          "1.1": {"name": "数据库独立化", "status": "ready", "progress": 0, "start_date": null, "end_date": null},
          "1.2": {"name": "代码独立化", "status": "pending", "progress": 0, "start_date": null, "end_date": null},
          "1.3": {"name": "配置独立化", "status": "pending", "progress": 0, "start_date": null, "end_date": null},
          "1.4": {"name": "脚本独立化", "status": "pending", "progress": 0, "start_date": null, "end_date": null}
        }
      },
      "2": {
        "name": "功能独立化",
        "start_date": "2025-10-21",
        "end_date": "2025-11-03",
        "progress": 0,
        "milestones": {
          "2.1": {"name": "AI服务独立化", "status": "pending", "progress": 0, "start_date": null, "end_date": null},
          "2.2": {"name": "监控系统独立化", "status": "pending", "progress": 0, "start_date": null, "end_date": null},
          "2.3": {"name": "前端系统独立化", "status": "pending", "progress": 0, "start_date": null, "end_date": null},
          "2.4": {"name": "集成测试独立化", "status": "pending", "progress": 0, "start_date": null, "end_date": null}
        }
      },
      "3": {
        "name": "生产独立化",
        "start_date": "2025-11-04",
        "end_date": "2025-11-17",
        "progress": 0,
        "milestones": {
          "3.1": {"name": "生产环境准备", "status": "pending", "progress": 0, "start_date": null, "end_date": null},
          "3.2": {"name": "数据迁移生产化", "status": "pending", "progress": 0, "start_date": null, "end_date": null},
          "3.3": {"name": "服务切换生产化", "status": "pending", "progress": 0, "start_date": null, "end_date": null},
          "3.4": {"name": "生产环境验证", "status": "pending", "progress": 0, "start_date": null, "end_date": null}
        }
      }
    }
  }
}
EOF
    
    # 创建独立化进度日志
    cat > docs/INDEPENDENCE_PROGRESS_LOG.md << 'EOF'
# 独立化进度日志

## 启动日志
- 2025-09-24: 独立化工作启动
- 2025-09-24: 独立化跟踪系统初始化完成
- 2025-09-24: 第一个里程碑1.1准备开始

## 里程碑完成日志
EOF
    
    # 创建独立化状态更新脚本
    cat > scripts/independence/update_independence_status.py << 'EOF'
#!/usr/bin/env python3
import json
import sys
from datetime import datetime

def update_independence_status(phase, milestone, status, progress=0):
    """更新独立化状态"""
    try:
        with open('docs/INDEPENDENCE_STATUS.json', 'r') as f:
            data = json.load(f)
        
        if phase in data['independence']['phases'] and milestone in data['independence']['phases'][phase]['milestones']:
            data['independence']['phases'][phase]['milestones'][milestone]['status'] = status
            data['independence']['phases'][phase]['milestones'][milestone]['progress'] = progress
            
            if status == 'in_progress' and not data['independence']['phases'][phase]['milestones'][milestone]['start_date']:
                data['independence']['phases'][phase]['milestones'][milestone]['start_date'] = datetime.now().isoformat()
            elif status == 'completed':
                data['independence']['phases'][phase]['milestones'][milestone]['end_date'] = datetime.now().isoformat()
            
            with open('docs/INDEPENDENCE_STATUS.json', 'w') as f:
                json.dump(data, f, indent=2)
            
            print(f"里程碑 {phase}.{milestone} 状态已更新为: {status} ({progress}%)")
        else:
            print(f"里程碑 {phase}.{milestone} 不存在")
    except Exception as e:
        print(f"更新独立化状态失败: {e}")

if __name__ == "__main__":
    if len(sys.argv) >= 4:
        update_independence_status(sys.argv[1], sys.argv[2], sys.argv[3], int(sys.argv[4]) if len(sys.argv) > 4 else 0)
    else:
        print("用法: python update_independence_status.py <phase> <milestone> <status> [progress]")
EOF
    
    chmod +x scripts/independence/update_independence_status.py
    
    log_success "独立化跟踪系统初始化完成"
    cd ..
}

# 启动第一个里程碑：数据库独立化
start_database_independence() {
    log_info "启动第一个里程碑: 1.1 数据库独立化..."
    
    cd looma_crm_ai_refactoring
    
    # 更新里程碑状态为进行中
    python scripts/independence/update_independence_status.py "1" "1.1" "in_progress" 0
    
    # 创建数据库独立化工作文件
    touch independence/database/neo4j/independent_neo4j.py
    touch independence/database/weaviate/independent_weaviate.py
    touch independence/database/postgresql/independent_postgresql.py
    touch independence/database/redis/independent_redis.py
    touch independence/database/elasticsearch/independent_elasticsearch.py
    touch independence/database/mongodb/independent_mongodb.py
    
    # 记录启动日志
    echo "- $(date): 里程碑1.1开始实施 - 数据库独立化" >> docs/INDEPENDENCE_PROGRESS_LOG.md
    
    log_success "第一个里程碑已启动"
    cd ..
}

# 显示启动总结
show_startup_summary() {
    log_independence "独立化工作启动完成！"
    echo ""
    echo -e "${CYAN}📋 当前状态:${NC}"
    echo "  ✅ 第三阶段成果验证: 通过"
    echo "  ✅ 独立化工作目录: 创建完成"
    echo "  ✅ 独立化跟踪系统: 就绪"
    echo "  ✅ 第一个里程碑: 已启动"
    echo ""
    echo -e "${CYAN}🎯 当前里程碑:${NC}"
    echo "  里程碑ID: 1.1"
    echo "  里程碑名称: 数据库独立化"
    echo "  状态: 进行中"
    echo "  进度: 0%"
    echo ""
    echo -e "${CYAN}📅 今日计划:${NC}"
    echo "  上午: 创建独立数据库实例"
    echo "  下午: 数据库结构迁移"
    echo "  验收: 独立数据库实例正常运行"
    echo ""
    echo -e "${CYAN}📁 重要文件:${NC}"
    echo "  独立化状态: docs/INDEPENDENCE_STATUS.json"
    echo "  进度日志: docs/INDEPENDENCE_PROGRESS_LOG.md"
    echo "  独立化计划: INDEPENDENCE_MILESTONE_PLAN.md"
    echo "  分析报告: docs/INDEPENDENCE_ANALYSIS_REPORT.md"
    echo ""
    echo -e "${GREEN}🚀 独立化工作正式启动！开始实施...${NC}"
}

# 主函数
main() {
    echo -e "${PURPLE}🚀 Looma CRM重构项目独立化启动脚本${NC}"
    echo "=============================================="
    echo ""
    
    check_directory
    check_phase3_results
    create_independence_directories
    init_independence_tracking
    start_database_independence
    show_startup_summary
    
    echo ""
    echo -e "${GREEN}✅ 独立化工作启动完成！${NC}"
    echo -e "${YELLOW}💡 提示: 使用 'python scripts/independence/update_independence_status.py <phase> <milestone> <status> [progress]' 更新里程碑状态${NC}"
}

# 运行主函数
main "$@"
