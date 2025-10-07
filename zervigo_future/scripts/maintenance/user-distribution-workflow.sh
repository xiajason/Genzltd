#!/bin/bash

# JobFirst 开发团队成员分发和初始化工作流程脚本
# 用于自动化团队成员账号创建、权限配置和访问设置

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
SERVER_IP="101.33.251.158"
SERVER_PORT="22"
ADMIN_EMAIL="admin@jobfirst.com"
SUPPORT_EMAIL="support@jobfirst.com"

# 检查是否为root用户
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "此脚本需要root权限运行"
        log_info "请使用: sudo $0"
        exit 1
    fi
}

# 显示欢迎信息
show_welcome() {
    clear
    echo "=================================================="
    echo "    JobFirst 开发团队成员分发工作流程"
    echo "=================================================="
    echo ""
    echo "本脚本将帮助您："
    echo "1. 创建团队成员账号"
    echo "2. 配置SSH访问权限"
    echo "3. 设置角色权限"
    echo "4. 生成访问凭证"
    echo "5. 发送欢迎邮件"
    echo ""
    echo "服务器信息："
    echo "- IP地址: $SERVER_IP"
    echo "- SSH端口: $SERVER_PORT"
    echo "- 管理员邮箱: $ADMIN_EMAIL"
    echo ""
}

# 收集团队成员信息
collect_team_member_info() {
    log_step "收集团队成员信息"
    
    echo ""
    echo "请输入团队成员信息："
    echo ""
    
    # 用户名
    while true; do
        read -p "用户名 (建议使用姓名拼音): " USERNAME
        if [[ -n "$USERNAME" && "$USERNAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
            break
        else
            log_error "用户名只能包含字母、数字、下划线和连字符"
        fi
    done
    
    # 真实姓名
    read -p "真实姓名: " REAL_NAME
    
    # 邮箱
    while true; do
        read -p "邮箱地址: " EMAIL
        if [[ "$EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
            break
        else
            log_error "请输入有效的邮箱地址"
        fi
    done
    
    # 角色选择
    echo ""
    echo "请选择角色："
    echo "1) super_admin - 超级管理员 (完全权限)"
    echo "2) system_admin - 系统管理员 (系统管理权限)"
    echo "3) dev_lead - 开发负责人 (项目管理权限)"
    echo "4) frontend_dev - 前端开发 (前端代码权限)"
    echo "5) backend_dev - 后端开发 (后端代码权限)"
    echo "6) qa_engineer - 测试工程师 (测试执行权限)"
    echo "7) guest - 访客用户 (只读权限)"
    echo ""
    
    while true; do
        read -p "请选择角色 (1-7): " ROLE_CHOICE
        case $ROLE_CHOICE in
            1) ROLE="super_admin"; break ;;
            2) ROLE="system_admin"; break ;;
            3) ROLE="dev_lead"; break ;;
            4) ROLE="frontend_dev"; break ;;
            5) ROLE="backend_dev"; break ;;
            6) ROLE="qa_engineer"; break ;;
            7) ROLE="guest"; break ;;
            *) log_error "请输入1-7之间的数字" ;;
        esac
    done
    
    # SSH公钥
    echo ""
    echo "请提供SSH公钥内容："
    echo "（团队成员需要在本地运行: cat ~/.ssh/id_rsa.pub）"
    echo ""
    read -p "SSH公钥: " SSH_PUBLIC_KEY
    
    if [[ -z "$SSH_PUBLIC_KEY" ]]; then
        log_error "SSH公钥不能为空"
        exit 1
    fi
    
    # 确认信息
    echo ""
    echo "请确认信息："
    echo "用户名: $USERNAME"
    echo "真实姓名: $REAL_NAME"
    echo "邮箱: $EMAIL"
    echo "角色: $ROLE"
    echo "SSH公钥: ${SSH_PUBLIC_KEY:0:50}..."
    echo ""
    
    read -p "确认创建此用户？(y/N): " CONFIRM
    if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
        log_info "用户创建已取消"
        exit 0
    fi
}

# 创建用户账号
create_user_account() {
    log_step "创建用户账号"
    
    # 检查用户是否已存在
    if id "jobfirst-$USERNAME" &>/dev/null; then
        log_warning "用户 jobfirst-$USERNAME 已存在"
        read -p "是否删除现有用户并重新创建？(y/N): " RECREATE
        if [[ "$RECREATE" == "y" || "$RECREATE" == "Y" ]]; then
            userdel -r "jobfirst-$USERNAME" 2>/dev/null || true
        else
            log_error "用户创建已取消"
            exit 1
        fi
    fi
    
    # 创建用户
    useradd -m -s /bin/bash -g jobfirst-dev -G "jobfirst-$ROLE" "jobfirst-$USERNAME"
    
    # 设置用户主目录权限
    chmod 755 "/home/jobfirst-$USERNAME"
    mkdir -p "/home/jobfirst-$USERNAME/.ssh"
    chmod 700 "/home/jobfirst-$USERNAME/.ssh"
    
    # 添加SSH公钥
    echo "$SSH_PUBLIC_KEY" > "/home/jobfirst-$USERNAME/.ssh/authorized_keys"
    chmod 600 "/home/jobfirst-$USERNAME/.ssh/authorized_keys"
    chown -R "jobfirst-$USERNAME:jobfirst-dev" "/home/jobfirst-$USERNAME"
    
    # 创建用户工作目录
    mkdir -p "/home/jobfirst-$USERNAME/workspace"
    chown -R "jobfirst-$USERNAME:jobfirst-dev" "/home/jobfirst-$USERNAME/workspace"
    
    # 创建用户配置文件
    cat > "/home/jobfirst-$USERNAME/.bashrc" << EOF
# JobFirst 开发环境配置
export PS1='\[\033[01;32m\]\u@jobfirst-server\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin"

# 别名
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# JobFirst 特定别名
alias jobfirst-status='sudo jobfirst-status'
alias jobfirst-logs='sudo tail -f /opt/jobfirst/logs/backend.log'
alias jobfirst-restart='sudo systemctl restart basic-server'

# 欢迎信息
echo "欢迎使用 JobFirst 开发服务器！"
echo "用户: $REAL_NAME ($USERNAME)"
echo "角色: $ROLE"
echo "服务器: $SERVER_IP"
echo ""
echo "常用命令："
echo "  jobfirst-status  - 查看系统状态"
echo "  jobfirst-logs    - 查看系统日志"
echo "  sudo -l          - 查看个人权限"
echo ""
EOF

    chown "jobfirst-$USERNAME:jobfirst-dev" "/home/jobfirst-$USERNAME/.bashrc"
    
    log_success "用户账号创建完成: jobfirst-$USERNAME"
}

# 配置用户权限
configure_user_permissions() {
    log_step "配置用户权限"
    
    # 根据角色设置特定权限
    case $ROLE in
        "super_admin")
            # 超级管理员 - 完全权限
            usermod -aG sudo "jobfirst-$USERNAME"
            ;;
        "system_admin")
            # 系统管理员 - 系统管理权限
            usermod -aG jobfirst-system-admin "jobfirst-$USERNAME"
            ;;
        "dev_lead")
            # 开发负责人 - 项目管理权限
            usermod -aG jobfirst-dev-lead "jobfirst-$USERNAME"
            ;;
        "frontend_dev")
            # 前端开发 - 前端代码权限
            usermod -aG jobfirst-frontend-dev "jobfirst-$USERNAME"
            ;;
        "backend_dev")
            # 后端开发 - 后端代码权限
            usermod -aG jobfirst-backend-dev "jobfirst-$USERNAME"
            ;;
        "qa_engineer")
            # 测试工程师 - 测试执行权限
            usermod -aG jobfirst-qa-engineer "jobfirst-$USERNAME"
            ;;
        "guest")
            # 访客用户 - 只读权限
            usermod -aG jobfirst-guest "jobfirst-$USERNAME"
            ;;
    esac
    
    log_success "用户权限配置完成"
}

# 生成访问凭证
generate_access_credentials() {
    log_step "生成访问凭证"
    
    # 创建访问凭证文件
    CREDENTIALS_FILE="/tmp/jobfirst-$USERNAME-credentials.txt"
    
    cat > "$CREDENTIALS_FILE" << EOF
==================================================
    JobFirst 开发服务器访问凭证
==================================================

用户信息：
---------
用户名: $USERNAME
真实姓名: $REAL_NAME
邮箱: $EMAIL
角色: $ROLE
创建时间: $(date)

服务器信息：
-----------
服务器IP: $SERVER_IP
SSH端口: $SERVER_PORT
SSH用户: jobfirst-$USERNAME

SSH连接命令：
-----------
ssh jobfirst-$USERNAME@$SERVER_IP

或者使用SSH配置文件：
Host jobfirst-server
    HostName $SERVER_IP
    Port $SERVER_PORT
    User jobfirst-$USERNAME
    IdentityFile ~/.ssh/id_rsa
    ServerAliveInterval 60
    ServerAliveCountMax 3

权限说明：
---------
EOF

    # 根据角色添加权限说明
    case $ROLE in
        "super_admin")
            cat >> "$CREDENTIALS_FILE" << EOF
- 完全服务器访问权限
- 所有代码模块修改权限
- 所有数据库访问权限
- 所有服务重启权限
- 所有配置修改权限
EOF
            ;;
        "system_admin")
            cat >> "$CREDENTIALS_FILE" << EOF
- 系统管理权限
- 系统模块修改权限
- 系统数据库访问权限
- 系统服务重启权限
- 系统配置修改权限
EOF
            ;;
        "dev_lead")
            cat >> "$CREDENTIALS_FILE" << EOF
- 项目管理权限
- 项目代码修改权限
- 项目数据库访问权限
- 项目服务重启权限
- 项目配置修改权限
EOF
            ;;
        "frontend_dev")
            cat >> "$CREDENTIALS_FILE" << EOF
- SSH访问权限
- 前端代码修改权限
- 前端配置修改权限
- 前端构建权限
EOF
            ;;
        "backend_dev")
            cat >> "$CREDENTIALS_FILE" << EOF
- SSH访问权限
- 后端代码修改权限
- 业务数据库访问权限
- 后端服务重启权限
- 后端配置修改权限
EOF
            ;;
        "qa_engineer")
            cat >> "$CREDENTIALS_FILE" << EOF
- SSH访问权限
- 测试代码修改权限
- 测试数据库访问权限
- 测试配置修改权限
- 测试执行权限
EOF
            ;;
        "guest")
            cat >> "$CREDENTIALS_FILE" << EOF
- SSH访问权限
- 只读权限
- 查看系统状态权限
EOF
            ;;
    esac

    cat >> "$CREDENTIALS_FILE" << EOF

常用命令：
---------
jobfirst-status    - 查看系统状态
jobfirst-logs      - 查看系统日志
sudo -l            - 查看个人权限
sudo systemctl restart basic-server  - 重启后端服务（需要权限）

技术支持：
---------
管理员邮箱: $ADMIN_EMAIL
技术支持: $SUPPORT_EMAIL
文档地址: http://$SERVER_IP/docs/

安全注意事项：
-------------
1. 请妥善保管SSH私钥，不要与他人共享
2. 定期更新SSH密钥（建议每6个月）
3. 如发现异常登录，请立即联系管理员
4. 遵守公司安全政策，不要进行未授权的操作

==================================================
EOF

    log_success "访问凭证已生成: $CREDENTIALS_FILE"
}

# 发送欢迎邮件
send_welcome_email() {
    log_step "发送欢迎邮件"
    
    # 检查邮件服务是否可用
    if ! command -v mail &> /dev/null; then
        log_warning "邮件服务不可用，跳过邮件发送"
        return 0
    fi
    
    # 创建邮件内容
    EMAIL_SUBJECT="欢迎加入JobFirst开发团队 - $REAL_NAME"
    EMAIL_BODY="/tmp/jobfirst-$USERNAME-welcome-email.txt"
    
    cat > "$EMAIL_BODY" << EOF
亲爱的 $REAL_NAME，

欢迎加入JobFirst开发团队！

您的账号信息：
- 用户名: $USERNAME
- 角色: $ROLE
- 服务器: $SERVER_IP

请查看附件中的访问凭证文件，了解详细的连接方式和权限说明。

如有任何问题，请联系：
- 管理员: $ADMIN_EMAIL
- 技术支持: $SUPPORT_EMAIL

祝您工作愉快！

JobFirst开发团队
$(date)
EOF

    # 发送邮件
    if mail -s "$EMAIL_SUBJECT" -a "$CREDENTIALS_FILE" "$EMAIL" < "$EMAIL_BODY"; then
        log_success "欢迎邮件已发送到: $EMAIL"
    else
        log_warning "邮件发送失败，请手动发送访问凭证"
    fi
    
    # 清理临时文件
    rm -f "$EMAIL_BODY"
}

# 验证用户创建
verify_user_creation() {
    log_step "验证用户创建"
    
    # 检查用户是否存在
    if id "jobfirst-$USERNAME" &>/dev/null; then
        log_success "用户存在: jobfirst-$USERNAME"
    else
        log_error "用户创建失败"
        exit 1
    fi
    
    # 检查用户组
    USER_GROUPS=$(groups "jobfirst-$USERNAME" | cut -d: -f2 | tr ' ' '\n' | grep "jobfirst-" | tr '\n' ' ')
    log_info "用户组: $USER_GROUPS"
    
    # 检查SSH公钥
    if [[ -f "/home/jobfirst-$USERNAME/.ssh/authorized_keys" ]]; then
        log_success "SSH公钥已配置"
    else
        log_error "SSH公钥配置失败"
        exit 1
    fi
    
    # 检查主目录权限
    if [[ -d "/home/jobfirst-$USERNAME/workspace" ]]; then
        log_success "工作目录已创建"
    else
        log_warning "工作目录创建失败"
    fi
    
    log_success "用户创建验证完成"
}

# 显示完成信息
show_completion_info() {
    log_step "完成信息"
    
    echo ""
    echo "=================================================="
    echo "    用户创建完成！"
    echo "=================================================="
    echo ""
    echo "用户信息："
    echo "  用户名: jobfirst-$USERNAME"
    echo "  真实姓名: $REAL_NAME"
    echo "  邮箱: $EMAIL"
    echo "  角色: $ROLE"
    echo ""
    echo "访问信息："
    echo "  服务器: $SERVER_IP"
    echo "  SSH命令: ssh jobfirst-$USERNAME@$SERVER_IP"
    echo ""
    echo "文件位置："
    echo "  访问凭证: $CREDENTIALS_FILE"
    echo "  用户主目录: /home/jobfirst-$USERNAME"
    echo ""
    echo "下一步："
    echo "1. 将访问凭证文件发送给用户"
    echo "2. 用户配置本地SSH客户端"
    echo "3. 用户测试SSH连接"
    echo "4. 用户开始开发工作"
    echo ""
    echo "管理命令："
    echo "  jobfirst-list-users    - 查看所有用户"
    echo "  jobfirst-status        - 查看系统状态"
    echo "  jobfirst-remove-user $USERNAME  - 删除用户"
    echo ""
}

# 主函数
main() {
    check_root
    show_welcome
    
    # 询问是否继续
    read -p "是否开始创建新用户？(y/N): " START
    if [[ "$START" != "y" && "$START" != "Y" ]]; then
        log_info "操作已取消"
        exit 0
    fi
    
    collect_team_member_info
    create_user_account
    configure_user_permissions
    generate_access_credentials
    send_welcome_email
    verify_user_creation
    show_completion_info
    
    log_success "JobFirst开发团队成员分发工作流程完成！"
}

# 执行主函数
main "$@"
