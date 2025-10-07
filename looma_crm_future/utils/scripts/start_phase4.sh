#!/bin/bash

# 第四阶段快速启动脚本
# 创建日期: 2025年9月24日
# 版本: v1.0
# 目标: 一键启动第四阶段实施

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

log_phase() {
    echo -e "${PURPLE}[PHASE4]${NC} $1"
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

# 检查环境准备
check_environment() {
    log_info "检查环境准备..."
    
    # 检查Python虚拟环境
    if [[ -n "$VIRTUAL_ENV" ]]; then
        log_success "Python虚拟环境已激活: $VIRTUAL_ENV"
    else
        log_warning "Python虚拟环境未激活，尝试激活..."
        if [[ -f "looma_crm_ai_refactoring/venv/bin/activate" ]]; then
            source looma_crm_ai_refactoring/venv/bin/activate
            log_success "Python虚拟环境已激活"
        else
            log_error "Python虚拟环境不存在"
            exit 1
        fi
    fi
    
    # 检查数据库服务
    log_info "检查数据库服务状态..."
    
    # 检查MongoDB
    if pgrep -f "mongod" > /dev/null; then
        log_success "MongoDB服务运行中"
    else
        log_warning "MongoDB服务未运行，尝试启动..."
        if command -v brew > /dev/null; then
            brew services start mongodb/brew/mongodb-community
            sleep 5
            if pgrep -f "mongod" > /dev/null; then
                log_success "MongoDB服务已启动"
            else
                log_error "MongoDB服务启动失败"
                exit 1
            fi
        else
            log_error "无法启动MongoDB服务"
            exit 1
        fi
    fi
    
    # 检查Redis
    if pgrep -f "redis-server" > /dev/null; then
        log_success "Redis服务运行中"
    else
        log_warning "Redis服务未运行"
    fi
    
    # 检查PostgreSQL
    if pgrep -f "postgres" > /dev/null; then
        log_success "PostgreSQL服务运行中"
    else
        log_warning "PostgreSQL服务未运行"
    fi
    
    log_success "环境准备检查完成"
}

# 检查Zervigo服务状态
check_zervigo_services() {
    log_info "检查Zervigo服务状态..."
    
    if [[ -f "basic/backend/cmd/basic-server/scripts/maintenance/smart-startup-enhanced.sh" ]]; then
        cd basic
        ./backend/cmd/basic-server/scripts/maintenance/smart-startup-enhanced.sh --status
        cd ..
        log_success "Zervigo服务状态检查完成"
    else
        log_warning "Zervigo启动脚本不存在，跳过检查"
    fi
}

# 创建第四阶段工作目录
create_phase4_directories() {
    log_info "创建第四阶段工作目录..."
    
    cd looma_crm_ai_refactoring
    
    # 创建服务目录
    mkdir -p looma_crm/services
    mkdir -p ai_services/{ai_gateway,resume_processing,job_matching,vector_search,model_manager,model_optimizer,chat_service}
    mkdir -p shared/{performance,concurrency,logging,monitoring,alerting}
    mkdir -p tests/ai_services_integration_test.py
    mkdir -p scripts/phase4
    
    log_success "第四阶段工作目录创建完成"
    cd ..
}

# 初始化任务跟踪系统
init_task_tracking() {
    log_info "初始化任务跟踪系统..."
    
    cd looma_crm_ai_refactoring
    
    # 创建任务状态文件
    cat > docs/PHASE4_TASK_STATUS.json << 'EOF'
{
  "phase4": {
    "start_date": "2025-09-24",
    "current_week": 1,
    "current_task": "4.1.1.1",
    "overall_progress": 0,
    "tasks": {
      "4.1.1.1": {"status": "ready", "progress": 0, "start_date": null, "end_date": null, "description": "人才数据同步完善"},
      "4.1.1.2": {"status": "pending", "progress": 0, "start_date": null, "end_date": null, "description": "AI聊天功能实现"},
      "4.1.1.3": {"status": "pending", "progress": 0, "start_date": null, "end_date": null, "description": "职位匹配功能优化"},
      "4.1.1.4": {"status": "pending", "progress": 0, "start_date": null, "end_date": null, "description": "AI处理功能增强"},
      "4.1.2.1": {"status": "pending", "progress": 0, "start_date": null, "end_date": null, "description": "数据模型完善"},
      "4.1.2.2": {"status": "pending", "progress": 0, "start_date": null, "end_date": null, "description": "数据验证机制"},
      "4.1.2.3": {"status": "pending", "progress": 0, "start_date": null, "end_date": null, "description": "API接口完善"}
    }
  }
}
EOF
    
    # 创建进度日志文件
    cat > docs/PHASE4_PROGRESS_LOG.md << 'EOF'
# 第四阶段进度日志

## 启动日志
- 2025-09-24: 第四阶段启动检查完成
- 2025-09-24: 任务跟踪系统初始化完成
- 2025-09-24: 第一个任务4.1.1.1准备开始

## 任务完成日志
EOF
    
    # 创建任务状态更新脚本
    cat > scripts/phase4/update_task_status.py << 'EOF'
#!/usr/bin/env python3
import json
import sys
from datetime import datetime

def update_task_status(task_id, status, progress=0):
    """更新任务状态"""
    try:
        with open('docs/PHASE4_TASK_STATUS.json', 'r') as f:
            data = json.load(f)
        
        if task_id in data['phase4']['tasks']:
            data['phase4']['tasks'][task_id]['status'] = status
            data['phase4']['tasks'][task_id]['progress'] = progress
            
            if status == 'in_progress' and not data['phase4']['tasks'][task_id]['start_date']:
                data['phase4']['tasks'][task_id]['start_date'] = datetime.now().isoformat()
            elif status == 'completed':
                data['phase4']['tasks'][task_id]['end_date'] = datetime.now().isoformat()
            
            with open('docs/PHASE4_TASK_STATUS.json', 'w') as f:
                json.dump(data, f, indent=2)
            
            print(f"任务 {task_id} 状态已更新为: {status} ({progress}%)")
        else:
            print(f"任务 {task_id} 不存在")
    except Exception as e:
        print(f"更新任务状态失败: {e}")

if __name__ == "__main__":
    if len(sys.argv) >= 3:
        update_task_status(sys.argv[1], sys.argv[2], int(sys.argv[3]) if len(sys.argv) > 3 else 0)
    else:
        print("用法: python update_task_status.py <task_id> <status> [progress]")
EOF
    
    chmod +x scripts/phase4/update_task_status.py
    
    log_success "任务跟踪系统初始化完成"
    cd ..
}

# 启动第一个任务
start_first_task() {
    log_info "启动第一个任务: 4.1.1.1 人才数据同步完善..."
    
    cd looma_crm_ai_refactoring
    
    # 更新任务状态为进行中
    python scripts/phase4/update_task_status.py "4.1.1.1" "in_progress" 0
    
    # 创建任务工作文件
    touch looma_crm/services/talent_sync_service.py
    touch tests/test_talent_sync_service.py
    
    # 记录启动日志
    echo "- $(date): 任务4.1.1.1开始实施 - 人才数据同步完善" >> docs/PHASE4_PROGRESS_LOG.md
    
    log_success "第一个任务已启动"
    cd ..
}

# 显示启动总结
show_startup_summary() {
    log_phase "第四阶段启动完成！"
    echo ""
    echo -e "${CYAN}📋 当前状态:${NC}"
    echo "  ✅ 第三阶段成果验证: 通过"
    echo "  ✅ 环境准备检查: 完成"
    echo "  ✅ 任务跟踪系统: 就绪"
    echo "  ✅ 工作目录结构: 创建完成"
    echo "  ✅ 第一个任务: 已启动"
    echo ""
    echo -e "${CYAN}🎯 当前任务:${NC}"
    echo "  任务ID: 4.1.1.1"
    echo "  任务名称: 人才数据同步完善"
    echo "  状态: 进行中"
    echo "  进度: 0%"
    echo ""
    echo -e "${CYAN}📅 今日计划:${NC}"
    echo "  上午: 创建人才数据同步服务基础框架"
    echo "  下午: 实现批量同步逻辑"
    echo "  验收: 批量同步1000条记录 < 30秒"
    echo ""
    echo -e "${CYAN}📁 重要文件:${NC}"
    echo "  任务状态: docs/PHASE4_TASK_STATUS.json"
    echo "  进度日志: docs/PHASE4_PROGRESS_LOG.md"
    echo "  实施计划: docs/PHASE4_IMPLEMENTATION_PLAN.md"
    echo "  任务分解: docs/PHASE4_TASK_BREAKDOWN.md"
    echo "  启动清单: docs/PHASE4_STARTUP_CHECKLIST.md"
    echo ""
    echo -e "${GREEN}🚀 第四阶段正式启动！开始实施...${NC}"
}

# 主函数
main() {
    echo -e "${PURPLE}🚀 第四阶段快速启动脚本${NC}"
    echo "=================================="
    echo ""
    
    check_directory
    check_phase3_results
    check_environment
    check_zervigo_services
    create_phase4_directories
    init_task_tracking
    start_first_task
    show_startup_summary
    
    echo ""
    echo -e "${GREEN}✅ 第四阶段启动完成！${NC}"
    echo -e "${YELLOW}💡 提示: 使用 'python scripts/phase4/update_task_status.py <task_id> <status> [progress]' 更新任务状态${NC}"
}

# 运行主函数
main "$@"
