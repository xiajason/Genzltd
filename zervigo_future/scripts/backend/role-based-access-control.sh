#!/bin/bash

# JobFirst 基于角色的服务器访问控制脚本
# 实现细粒度的权限控制和访问管理

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
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

log_step() {
    echo -e "${PURPLE}[STEP]${NC} $1"
}

# 配置变量
JOBFIRST_ROOT="/opt/jobfirst"
LOG_FILE="/var/log/jobfirst-access-control.log"
AUDIT_LOG="/var/log/jobfirst-audit.log"

# 检查是否为root用户
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "此脚本需要root权限运行"
        log_info "请使用: sudo $0"
        exit 1
    fi
}

# 记录审计日志
audit_log() {
    local action="$1"
    local user="$2"
    local target="$3"
    local result="$4"
    local details="$5"
    
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $action | $user | $target | $result | $details" >> "$AUDIT_LOG"
}

# 创建目录权限控制
create_directory_permissions() {
    log_step "创建目录权限控制"
    
    # 创建目录结构
    mkdir -p "$JOBFIRST_ROOT"/{shared,logs,uploads,temp,backup}
    mkdir -p "$JOBFIRST_ROOT"/shared/{frontend,backend,database,config}
    mkdir -p "$JOBFIRST_ROOT"/logs/{backend,frontend,database,access}
    mkdir -p "$JOBFIRST_ROOT"/uploads/{images,documents,temp}
    
    # 设置基础权限
    chown -R root:jobfirst-dev "$JOBFIRST_ROOT"
    chmod 755 "$JOBFIRST_ROOT"
    
    # 共享目录权限
    chown -R root:jobfirst-dev "$JOBFIRST_ROOT/shared"
    chmod 755 "$JOBFIRST_ROOT/shared"
    
    # 日志目录权限
    chown -R root:jobfirst-dev "$JOBFIRST_ROOT/logs"
    chmod 755 "$JOBFIRST_ROOT/logs"
    
    # 上传目录权限
    chown -R root:jobfirst-dev "$JOBFIRST_ROOT/uploads"
    chmod 755 "$JOBFIRST_ROOT/uploads"
    
    # 临时目录权限
    chown -R root:jobfirst-dev "$JOBFIRST_ROOT/temp"
    chmod 777 "$JOBFIRST_ROOT/temp"
    
    # 备份目录权限
    chown -R root:jobfirst-dev "$JOBFIRST_ROOT/backup"
    chmod 700 "$JOBFIRST_ROOT/backup"
    
    log_success "目录权限控制创建完成"
}

# 创建文件权限控制
create_file_permissions() {
    log_step "创建文件权限控制"
    
    # 配置文件权限
    chown root:jobfirst-dev "$JOBFIRST_ROOT/backend/configs/config.yaml"
    chmod 640 "$JOBFIRST_ROOT/backend/configs/config.yaml"
    
    # 数据库文件权限
    chown root:jobfirst-dev "$JOBFIRST_ROOT/database" -R
    chmod 750 "$JOBFIRST_ROOT/database"
    
    # 脚本文件权限
    chown root:jobfirst-dev "$JOBFIRST_ROOT/scripts" -R
    chmod 750 "$JOBFIRST_ROOT/scripts"
    
    # 前端构建文件权限
    chown root:jobfirst-dev "$JOBFIRST_ROOT/frontend-taro/dist" -R
    chmod 755 "$JOBFIRST_ROOT/frontend-taro/dist"
    
    log_success "文件权限控制创建完成"
}

# 创建角色权限脚本
create_role_permission_scripts() {
    log_step "创建角色权限脚本"
    
    # 创建权限检查脚本
    cat > /usr/local/bin/jobfirst-check-permission << 'EOF'
#!/bin/bash

# JobFirst 权限检查脚本

USERNAME="$1"
ACTION="$2"
TARGET="$3"

if [[ -z "$USERNAME" || -z "$ACTION" || -z "$TARGET" ]]; then
    echo "用法: $0 <username> <action> <target>"
    echo "示例: $0 zhangsan read /opt/jobfirst/backend"
    exit 1
fi

# 获取用户角色
USER_ROLE=$(groups "jobfirst-$USERNAME" 2>/dev/null | grep -o "jobfirst-[a-zA-Z_-]*" | head -1)

if [[ -z "$USER_ROLE" ]]; then
    echo "错误: 用户 jobfirst-$USERNAME 不存在"
    exit 1
fi

# 权限检查逻辑
case "$USER_ROLE" in
    "jobfirst-super-admin")
        echo "允许: 超级管理员拥有完全权限"
        exit 0
        ;;
    "jobfirst-system-admin")
        case "$ACTION" in
            "read"|"write"|"execute")
                if [[ "$TARGET" =~ ^/opt/jobfirst/(shared|logs|uploads|temp) ]]; then
                    echo "允许: 系统管理员可以访问共享目录"
                    exit 0
                fi
                ;;
        esac
        ;;
    "jobfirst-dev-lead")
        case "$ACTION" in
            "read"|"write"|"execute")
                if [[ "$TARGET" =~ ^/opt/jobfirst/(shared|logs|uploads|temp|backend|frontend-taro) ]]; then
                    echo "允许: 开发负责人可以访问项目目录"
                    exit 0
                fi
                ;;
        esac
        ;;
    "jobfirst-frontend-dev")
        case "$ACTION" in
            "read"|"write"|"execute")
                if [[ "$TARGET" =~ ^/opt/jobfirst/(shared/frontend|logs|uploads|temp|frontend-taro) ]]; then
                    echo "允许: 前端开发可以访问前端目录"
                    exit 0
                fi
                ;;
        esac
        ;;
    "jobfirst-backend-dev")
        case "$ACTION" in
            "read"|"write"|"execute")
                if [[ "$TARGET" =~ ^/opt/jobfirst/(shared/backend|logs|uploads|temp|backend|database) ]]; then
                    echo "允许: 后端开发可以访问后端目录"
                    exit 0
                fi
                ;;
        esac
        ;;
    "jobfirst-qa-engineer")
        case "$ACTION" in
            "read"|"execute")
                if [[ "$TARGET" =~ ^/opt/jobfirst/(shared|logs|uploads|temp) ]]; then
                    echo "允许: 测试工程师可以读取测试相关目录"
                    exit 0
                fi
                ;;
        esac
        ;;
    "jobfirst-guest")
        case "$ACTION" in
            "read")
                if [[ "$TARGET" =~ ^/opt/jobfirst/(shared|logs) ]]; then
                    echo "允许: 访客用户可以读取共享目录"
                    exit 0
                fi
                ;;
        esac
        ;;
esac

echo "拒绝: 用户 $USERNAME ($USER_ROLE) 没有权限执行 $ACTION 操作在 $TARGET"
exit 1
EOF

    # 创建权限管理脚本
    cat > /usr/local/bin/jobfirst-manage-permissions << 'EOF'
#!/bin/bash

# JobFirst 权限管理脚本

ACTION="$1"
USERNAME="$2"
PERMISSION="$3"

if [[ -z "$ACTION" || -z "$USERNAME" ]]; then
    echo "用法: $0 <action> <username> [permission]"
    echo "操作: grant, revoke, list, check"
    echo "示例: $0 grant zhangsan frontend_access"
    exit 1
fi

case "$ACTION" in
    "grant")
        if [[ -z "$PERMISSION" ]]; then
            echo "错误: 请指定权限"
            exit 1
        fi
        usermod -aG "jobfirst-$PERMISSION" "jobfirst-$USERNAME"
        echo "权限已授予: $PERMISSION -> $USERNAME"
        ;;
    "revoke")
        if [[ -z "$PERMISSION" ]]; then
            echo "错误: 请指定权限"
            exit 1
        fi
        gpasswd -d "jobfirst-$USERNAME" "jobfirst-$PERMISSION"
        echo "权限已撤销: $PERMISSION -> $USERNAME"
        ;;
    "list")
        echo "用户 $USERNAME 的权限:"
        groups "jobfirst-$USERNAME" | grep -o "jobfirst-[a-zA-Z_-]*"
        ;;
    "check")
        echo "检查用户 $USERNAME 的权限:"
        jobfirst-check-permission "$USERNAME" "read" "/opt/jobfirst/shared"
        ;;
    *)
        echo "错误: 未知操作 $ACTION"
        exit 1
        ;;
esac
EOF

    # 设置脚本权限
    chmod +x /usr/local/bin/jobfirst-check-permission
    chmod +x /usr/local/bin/jobfirst-manage-permissions
    
    log_success "角色权限脚本创建完成"
}

# 创建访问控制中间件
create_access_control_middleware() {
    log_step "创建访问控制中间件"
    
    # 创建SSH访问控制脚本
    cat > /usr/local/bin/jobfirst-ssh-access-control << 'EOF'
#!/bin/bash

# JobFirst SSH访问控制脚本

USERNAME="$1"
COMMAND="$2"

# 记录访问日志
echo "$(date '+%Y-%m-%d %H:%M:%S') | SSH_ACCESS | $USERNAME | $COMMAND" >> /var/log/jobfirst-access-control.log

# 获取用户角色
USER_ROLE=$(groups "jobfirst-$USERNAME" 2>/dev/null | grep -o "jobfirst-[a-zA-Z_-]*" | head -1)

# 根据角色限制命令
case "$USER_ROLE" in
    "jobfirst-super-admin")
        # 超级管理员 - 无限制
        exec "$COMMAND"
        ;;
    "jobfirst-system-admin")
        # 系统管理员 - 系统管理命令
        if [[ "$COMMAND" =~ ^(systemctl|mysql|mysqldump|cp|mv|rm|tail|grep|curl)$ ]]; then
            exec "$COMMAND"
        else
            echo "错误: 系统管理员只能执行系统管理命令"
            exit 1
        fi
        ;;
    "jobfirst-dev-lead")
        # 开发负责人 - 项目管理命令
        if [[ "$COMMAND" =~ ^(systemctl|mysql|mysqldump|cp|mv|npm|yarn|pnpm|git)$ ]]; then
            exec "$COMMAND"
        else
            echo "错误: 开发负责人只能执行项目管理命令"
            exit 1
        fi
        ;;
    "jobfirst-frontend-dev")
        # 前端开发 - 前端开发命令
        if [[ "$COMMAND" =~ ^(npm|yarn|pnpm|git|ls|cat|tail|grep)$ ]]; then
            exec "$COMMAND"
        else
            echo "错误: 前端开发只能执行前端开发命令"
            exit 1
        fi
        ;;
    "jobfirst-backend-dev")
        # 后端开发 - 后端开发命令
        if [[ "$COMMAND" =~ ^(systemctl|mysql|mysqldump|git|ls|cat|tail|grep|curl)$ ]]; then
            exec "$COMMAND"
        else
            echo "错误: 后端开发只能执行后端开发命令"
            exit 1
        fi
        ;;
    "jobfirst-qa-engineer")
        # 测试工程师 - 测试命令
        if [[ "$COMMAND" =~ ^(mysql|tail|grep|curl|ls|cat)$ ]]; then
            exec "$COMMAND"
        else
            echo "错误: 测试工程师只能执行测试命令"
            exit 1
        fi
        ;;
    "jobfirst-guest")
        # 访客用户 - 只读命令
        if [[ "$COMMAND" =~ ^(ls|cat|tail|grep)$ ]]; then
            exec "$COMMAND"
        else
            echo "错误: 访客用户只能执行只读命令"
            exit 1
        fi
        ;;
    *)
        echo "错误: 未知用户角色"
        exit 1
        ;;
esac
EOF

    # 创建文件访问控制脚本
    cat > /usr/local/bin/jobfirst-file-access-control << 'EOF'
#!/bin/bash

# JobFirst 文件访问控制脚本

USERNAME="$1"
ACTION="$2"
FILE_PATH="$3"

# 记录访问日志
echo "$(date '+%Y-%m-%d %H:%M:%S') | FILE_ACCESS | $USERNAME | $ACTION | $FILE_PATH" >> /var/log/jobfirst-access-control.log

# 获取用户角色
USER_ROLE=$(groups "jobfirst-$USERNAME" 2>/dev/null | grep -o "jobfirst-[a-zA-Z_-]*" | head -1)

# 根据角色和路径检查权限
case "$USER_ROLE" in
    "jobfirst-super-admin")
        # 超级管理员 - 无限制
        exit 0
        ;;
    "jobfirst-system-admin")
        # 系统管理员 - 系统文件访问
        if [[ "$FILE_PATH" =~ ^/opt/jobfirst/(shared|logs|uploads|temp|configs) ]]; then
            exit 0
        fi
        ;;
    "jobfirst-dev-lead")
        # 开发负责人 - 项目文件访问
        if [[ "$FILE_PATH" =~ ^/opt/jobfirst/(shared|logs|uploads|temp|backend|frontend-taro|database) ]]; then
            exit 0
        fi
        ;;
    "jobfirst-frontend-dev")
        # 前端开发 - 前端文件访问
        if [[ "$FILE_PATH" =~ ^/opt/jobfirst/(shared/frontend|logs|uploads|temp|frontend-taro) ]]; then
            exit 0
        fi
        ;;
    "jobfirst-backend-dev")
        # 后端开发 - 后端文件访问
        if [[ "$FILE_PATH" =~ ^/opt/jobfirst/(shared/backend|logs|uploads|temp|backend|database) ]]; then
            exit 0
        fi
        ;;
    "jobfirst-qa-engineer")
        # 测试工程师 - 测试文件访问
        if [[ "$ACTION" == "read" && "$FILE_PATH" =~ ^/opt/jobfirst/(shared|logs|uploads|temp) ]]; then
            exit 0
        fi
        ;;
    "jobfirst-guest")
        # 访客用户 - 只读访问
        if [[ "$ACTION" == "read" && "$FILE_PATH" =~ ^/opt/jobfirst/(shared|logs) ]]; then
            exit 0
        fi
        ;;
esac

echo "错误: 用户 $USERNAME ($USER_ROLE) 没有权限执行 $ACTION 操作在 $FILE_PATH"
exit 1
EOF

    # 设置脚本权限
    chmod +x /usr/local/bin/jobfirst-ssh-access-control
    chmod +x /usr/local/bin/jobfirst-file-access-control
    
    log_success "访问控制中间件创建完成"
}

# 创建监控和审计系统
create_monitoring_audit_system() {
    log_step "创建监控和审计系统"
    
    # 创建访问监控脚本
    cat > /usr/local/bin/jobfirst-monitor-access << 'EOF'
#!/bin/bash

# JobFirst 访问监控脚本

LOG_FILE="/var/log/jobfirst-access-control.log"
AUDIT_LOG="/var/log/jobfirst-audit.log"

echo "JobFirst 访问监控报告"
echo "====================="
echo "时间: $(date)"
echo ""

echo "1. 最近SSH访问:"
echo "--------------"
tail -20 "$LOG_FILE" | grep "SSH_ACCESS" | while read line; do
    echo "$line"
done
echo ""

echo "2. 最近文件访问:"
echo "---------------"
tail -20 "$LOG_FILE" | grep "FILE_ACCESS" | while read line; do
    echo "$line"
done
echo ""

echo "3. 权限检查统计:"
echo "---------------"
grep "权限检查" "$AUDIT_LOG" | tail -10 | while read line; do
    echo "$line"
done
echo ""

echo "4. 异常访问尝试:"
echo "---------------"
grep "拒绝\|错误" "$LOG_FILE" | tail -10 | while read line; do
    echo "$line"
done
EOF

    # 创建审计报告脚本
    cat > /usr/local/bin/jobfirst-audit-report << 'EOF'
#!/bin/bash

# JobFirst 审计报告脚本

REPORT_DATE=$(date '+%Y-%m-%d')
REPORT_FILE="/tmp/jobfirst-audit-report-$REPORT_DATE.txt"

echo "JobFirst 审计报告" > "$REPORT_FILE"
echo "生成时间: $(date)" >> "$REPORT_FILE"
echo "=================" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "1. 用户活动统计:" >> "$REPORT_FILE"
echo "---------------" >> "$REPORT_FILE"
cut -d'|' -f3 /var/log/jobfirst-access-control.log | sort | uniq -c | sort -nr >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "2. 操作类型统计:" >> "$REPORT_FILE"
echo "---------------" >> "$REPORT_FILE"
cut -d'|' -f2 /var/log/jobfirst-access-control.log | sort | uniq -c | sort -nr >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "3. 权限拒绝统计:" >> "$REPORT_FILE"
echo "---------------" >> "$REPORT_FILE"
grep "拒绝\|错误" /var/log/jobfirst-access-control.log | wc -l >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "4. 最近异常活动:" >> "$REPORT_FILE"
echo "---------------" >> "$REPORT_FILE"
grep "拒绝\|错误" /var/log/jobfirst-access-control.log | tail -20 >> "$REPORT_FILE"

echo "审计报告已生成: $REPORT_FILE"
cat "$REPORT_FILE"
EOF

    # 创建实时监控脚本
    cat > /usr/local/bin/jobfirst-realtime-monitor << 'EOF'
#!/bin/bash

# JobFirst 实时监控脚本

echo "JobFirst 实时访问监控"
echo "按 Ctrl+C 退出"
echo "=================="

tail -f /var/log/jobfirst-access-control.log | while read line; do
    if echo "$line" | grep -q "拒绝\|错误"; then
        echo -e "\033[31m[ALERT] $line\033[0m"
    elif echo "$line" | grep -q "SSH_ACCESS"; then
        echo -e "\033[32m[SSH] $line\033[0m"
    elif echo "$line" | grep -q "FILE_ACCESS"; then
        echo -e "\033[33m[FILE] $line\033[0m"
    else
        echo "[INFO] $line"
    fi
done
EOF

    # 设置脚本权限
    chmod +x /usr/local/bin/jobfirst-monitor-access
    chmod +x /usr/local/bin/jobfirst-audit-report
    chmod +x /usr/local/bin/jobfirst-realtime-monitor
    
    log_success "监控和审计系统创建完成"
}

# 创建权限测试脚本
create_permission_test_script() {
    log_step "创建权限测试脚本"
    
    cat > /usr/local/bin/jobfirst-test-permissions << 'EOF'
#!/bin/bash

# JobFirst 权限测试脚本

if [[ $# -lt 1 ]]; then
    echo "用法: $0 <username>"
    echo "示例: $0 zhangsan"
    exit 1
fi

USERNAME="$1"

echo "测试用户 $USERNAME 的权限..."
echo "=========================="

# 测试目录访问权限
echo "1. 目录访问权限测试:"
echo "-------------------"

directories=(
    "/opt/jobfirst/shared"
    "/opt/jobfirst/logs"
    "/opt/jobfirst/uploads"
    "/opt/jobfirst/backend"
    "/opt/jobfirst/frontend-taro"
    "/opt/jobfirst/database"
    "/opt/jobfirst/configs"
)

for dir in "${directories[@]}"; do
    if jobfirst-check-permission "$USERNAME" "read" "$dir"; then
        echo "✅ 可以访问: $dir"
    else
        echo "❌ 无法访问: $dir"
    fi
done

echo ""

# 测试命令执行权限
echo "2. 命令执行权限测试:"
echo "-------------------"

commands=(
    "systemctl status basic-server"
    "mysql --version"
    "npm --version"
    "git --version"
    "ls -la /opt/jobfirst"
    "cat /opt/jobfirst/backend/configs/config.yaml"
)

for cmd in "${commands[@]}"; do
    if jobfirst-ssh-access-control "$USERNAME" "$(echo $cmd | cut -d' ' -f1)"; then
        echo "✅ 可以执行: $cmd"
    else
        echo "❌ 无法执行: $cmd"
    fi
done

echo ""

# 测试文件访问权限
echo "3. 文件访问权限测试:"
echo "-------------------"

files=(
    "/opt/jobfirst/backend/configs/config.yaml"
    "/opt/jobfirst/logs/backend.log"
    "/opt/jobfirst/shared/frontend"
    "/opt/jobfirst/shared/backend"
    "/opt/jobfirst/database/migrations"
)

for file in "${files[@]}"; do
    if jobfirst-file-access-control "$USERNAME" "read" "$file"; then
        echo "✅ 可以读取: $file"
    else
        echo "❌ 无法读取: $file"
    fi
done

echo ""
echo "权限测试完成！"
EOF

    chmod +x /usr/local/bin/jobfirst-test-permissions
    
    log_success "权限测试脚本创建完成"
}

# 创建权限管理界面
create_permission_management_interface() {
    log_step "创建权限管理界面"
    
    cat > /usr/local/bin/jobfirst-permission-manager << 'EOF'
#!/bin/bash

# JobFirst 权限管理界面

show_menu() {
    clear
    echo "=================================================="
    echo "    JobFirst 权限管理系统"
    echo "=================================================="
    echo ""
    echo "1. 查看所有用户权限"
    echo "2. 测试用户权限"
    echo "3. 授予用户权限"
    echo "4. 撤销用户权限"
    echo "5. 查看访问日志"
    echo "6. 生成审计报告"
    echo "7. 实时监控"
    echo "8. 退出"
    echo ""
}

while true; do
    show_menu
    read -p "请选择操作 (1-8): " choice
    
    case $choice in
        1)
            echo "所有用户权限:"
            echo "============="
            for user in $(getent passwd | grep "^jobfirst-" | cut -d: -f1); do
                username=$(echo $user | sed 's/jobfirst-//')
                echo "用户: $username"
                groups $user | grep -o "jobfirst-[a-zA-Z_-]*" | sed 's/^/  权限: /'
                echo ""
            done
            read -p "按回车键继续..."
            ;;
        2)
            read -p "请输入用户名: " username
            jobfirst-test-permissions "$username"
            read -p "按回车键继续..."
            ;;
        3)
            read -p "请输入用户名: " username
            read -p "请输入权限: " permission
            jobfirst-manage-permissions grant "$username" "$permission"
            read -p "按回车键继续..."
            ;;
        4)
            read -p "请输入用户名: " username
            read -p "请输入权限: " permission
            jobfirst-manage-permissions revoke "$username" "$permission"
            read -p "按回车键继续..."
            ;;
        5)
            jobfirst-monitor-access
            read -p "按回车键继续..."
            ;;
        6)
            jobfirst-audit-report
            read -p "按回车键继续..."
            ;;
        7)
            jobfirst-realtime-monitor
            ;;
        8)
            echo "退出权限管理系统"
            exit 0
            ;;
        *)
            echo "无效选择，请重新输入"
            sleep 2
            ;;
    esac
done
EOF

    chmod +x /usr/local/bin/jobfirst-permission-manager
    
    log_success "权限管理界面创建完成"
}

# 主函数
main() {
    log_info "开始配置JobFirst基于角色的访问控制..."
    
    check_root
    create_directory_permissions
    create_file_permissions
    create_role_permission_scripts
    create_access_control_middleware
    create_monitoring_audit_system
    create_permission_test_script
    create_permission_management_interface
    
    log_success "JobFirst基于角色的访问控制配置完成！"
    log_info "使用 'jobfirst-permission-manager' 命令管理权限"
    log_info "使用 'jobfirst-test-permissions <username>' 测试用户权限"
    log_info "使用 'jobfirst-monitor-access' 查看访问监控"
    log_info "使用 'jobfirst-realtime-monitor' 实时监控访问"
}

# 执行主函数
main "$@"
