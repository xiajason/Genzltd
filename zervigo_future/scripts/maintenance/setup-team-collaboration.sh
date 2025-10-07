#!/bin/bash

# JobFirst 团队协作开发环境设置脚本
# 用于在腾讯云轻量服务器上配置多用户协作开发环境

set -e

echo "=== JobFirst 团队协作开发环境设置 ==="
echo "时间: $(date)"
echo

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

# 检查是否为root用户
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "请以root用户运行此脚本"
        exit 1
    fi
}

# 创建开发用户组
create_dev_group() {
    log_info "创建开发用户组..."
    
    if ! getent group developers > /dev/null 2>&1; then
        groupadd developers
        log_success "开发用户组创建成功"
    else
        log_warning "开发用户组已存在"
    fi
}

# 配置SSH安全设置
configure_ssh_security() {
    log_info "配置SSH安全设置..."
    
    # 备份原配置
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.$(date +%Y%m%d_%H%M%S)
    
    # 更新SSH配置
    cat > /etc/ssh/sshd_config << 'EOF'
# JobFirst SSH安全配置
Port 22
Protocol 2
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2
LoginGraceTime 60
StrictModes yes
RSAAuthentication yes
PubkeyAuthentication yes
IgnoreRhosts yes
RhostsRSAAuthentication no
HostbasedAuthentication no
PermitEmptyPasswords no
ChallengeResponseAuthentication no
KerberosAuthentication no
GSSAPIAuthentication no
UsePAM yes
X11Forwarding no
PrintMotd no
PrintLastLog yes
TCPKeepAlive yes
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server
EOF

    # 重启SSH服务
    systemctl restart sshd
    log_success "SSH安全配置完成"
}

# 配置防火墙
configure_firewall() {
    log_info "配置防火墙..."
    
    # 安装ufw（如果未安装）
    if ! command -v ufw > /dev/null 2>&1; then
        apt update && apt install -y ufw
    fi
    
    # 重置防火墙规则
    ufw --force reset
    
    # 默认策略
    ufw default deny incoming
    ufw default allow outgoing
    
    # 允许SSH
    ufw allow 22/tcp
    
    # 允许HTTP和HTTPS
    ufw allow 80/tcp
    ufw allow 443/tcp
    
    # 允许JobFirst服务端口
    ufw allow 8080/tcp  # API Gateway
    ufw allow 8206/tcp  # AI Service
    ufw allow 8500/tcp  # Consul
    
    # 启用防火墙
    ufw --force enable
    
    log_success "防火墙配置完成"
}

# 创建用户管理脚本
create_user_management_scripts() {
    log_info "创建用户管理脚本..."
    
    # 创建用户脚本
    cat > /opt/jobfirst/scripts/create-dev-user.sh << 'EOF'
#!/bin/bash

# 创建开发用户脚本
# 用法: ./create-dev-user.sh <username> <role> <ssh_public_key>

if [ $# -ne 3 ]; then
    echo "用法: $0 <username> <role> <ssh_public_key>"
    echo "角色: admin, developer, frontend, backend, qa, guest"
    exit 1
fi

USERNAME=$1
ROLE=$2
SSH_KEY=$3

# 检查用户是否已存在
if id "$USERNAME" &>/dev/null; then
    echo "用户 $USERNAME 已存在"
    exit 1
fi

# 创建用户
useradd -m -s /bin/bash -G developers $USERNAME

# 配置SSH密钥
mkdir -p /home/$USERNAME/.ssh
echo "$SSH_KEY" > /home/$USERNAME/.ssh/authorized_keys
chmod 700 /home/$USERNAME/.ssh
chmod 600 /home/$USERNAME/.ssh/authorized_keys
chown -R $USERNAME:$USERNAME /home/$USERNAME/.ssh

# 设置sudo权限
case $ROLE in
    "admin")
        echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/dev-users
        ;;
    "developer")
        echo "$USERNAME ALL=(ALL) NOPASSWD:/opt/jobfirst/scripts/restart-services.sh,/opt/jobfirst/scripts/deploy.sh" >> /etc/sudoers.d/dev-users
        ;;
    "frontend")
        echo "$USERNAME ALL=(ALL) NOPASSWD:/opt/jobfirst/scripts/restart-frontend.sh" >> /etc/sudoers.d/dev-users
        ;;
    "backend")
        echo "$USERNAME ALL=(ALL) NOPASSWD:/opt/jobfirst/scripts/restart-backend.sh" >> /etc/sudoers.d/dev-users
        ;;
    "qa")
        echo "$USERNAME ALL=(ALL) NOPASSWD:/opt/jobfirst/scripts/restart-test-services.sh" >> /etc/sudoers.d/dev-users
        ;;
    "guest")
        echo "# 访客用户无sudo权限" >> /etc/sudoers.d/dev-users
        ;;
esac

# 设置项目目录权限
chown -R $USERNAME:developers /opt/jobfirst
chmod -R 775 /opt/jobfirst

echo "用户 $USERNAME 创建成功，角色：$ROLE"
EOF

    chmod +x /opt/jobfirst/scripts/create-dev-user.sh
    
    # 删除用户脚本
    cat > /opt/jobfirst/scripts/remove-dev-user.sh << 'EOF'
#!/bin/bash

# 删除开发用户脚本
# 用法: ./remove-dev-user.sh <username>

if [ $# -ne 1 ]; then
    echo "用法: $0 <username>"
    exit 1
fi

USERNAME=$1

# 检查用户是否存在
if ! id "$USERNAME" &>/dev/null; then
    echo "用户 $USERNAME 不存在"
    exit 1
fi

# 删除sudo权限
sed -i "/^$USERNAME/d" /etc/sudoers.d/dev-users

# 删除用户
userdel -r $USERNAME

echo "用户 $USERNAME 删除成功"
EOF

    chmod +x /opt/jobfirst/scripts/remove-dev-user.sh
    
    log_success "用户管理脚本创建完成"
}

# 配置项目目录权限
configure_project_permissions() {
    log_info "配置项目目录权限..."
    
    # 设置项目目录所有者
    chown -R root:developers /opt/jobfirst
    
    # 设置目录权限
    find /opt/jobfirst -type d -exec chmod 775 {} \;
    find /opt/jobfirst -type f -exec chmod 664 {} \;
    
    # 设置脚本执行权限
    find /opt/jobfirst/scripts -type f -name "*.sh" -exec chmod 755 {} \;
    
    # 设置日志目录权限
    chmod 755 /opt/jobfirst/logs
    chown root:developers /opt/jobfirst/logs
    
    log_success "项目目录权限配置完成"
}

# 配置操作审计
configure_audit() {
    log_info "配置操作审计..."
    
    # 安装auditd
    if ! command -v auditctl > /dev/null 2>&1; then
        apt update && apt install -y auditd audispd-plugins
    fi
    
    # 启动auditd服务
    systemctl enable auditd
    systemctl start auditd
    
    # 配置审计规则
    cat > /etc/audit/rules.d/jobfirst.rules << 'EOF'
# JobFirst 操作审计规则

# 监控项目目录访问
-w /opt/jobfirst/ -p rwxa -k jobfirst_access

# 监控配置文件修改
-w /etc/nginx/ -p rwxa -k nginx_config
-w /etc/mysql/ -p rwxa -k mysql_config
-w /etc/redis/ -p rwxa -k redis_config

# 监控系统关键文件
-w /etc/passwd -p wa -k user_modification
-w /etc/group -p wa -k group_modification
-w /etc/sudoers -p wa -k sudo_modification

# 监控SSH配置
-w /etc/ssh/sshd_config -p wa -k ssh_config

# 监控服务启动停止
-w /usr/bin/systemctl -p x -k systemctl_usage
EOF

    # 重新加载审计规则
    auditctl -R /etc/audit/rules.d/jobfirst.rules
    
    log_success "操作审计配置完成"
}

# 创建监控脚本
create_monitoring_scripts() {
    log_info "创建监控脚本..."
    
    # 团队协作监控脚本
    cat > /opt/jobfirst/scripts/monitor-team-collaboration.sh << 'EOF'
#!/bin/bash

# 团队协作监控脚本

echo "=== JobFirst 团队协作监控 ==="
echo "时间: $(date)"
echo

# 当前登录用户
echo "1. 当前登录用户:"
who
echo

# SSH连接状态
echo "2. SSH连接状态:"
ss -tuln | grep :22
echo

# 系统资源使用
echo "3. 系统资源使用:"
free -h
echo
top -bn1 | head -5
echo

# 最近SSH登录记录
echo "4. 最近SSH登录记录:"
tail -10 /var/log/auth.log | grep ssh
echo

# 项目文件修改记录
echo "5. 项目文件修改记录:"
find /opt/jobfirst -type f -mtime -1 -ls | head -10
echo

# 审计日志
echo "6. 最近审计日志:"
ausearch -k jobfirst_access -ts today | tail -5
echo

# 服务状态
echo "7. 服务状态:"
systemctl status nginx --no-pager -l
systemctl status mysql --no-pager -l
systemctl status redis --no-pager -l
echo
EOF

    chmod +x /opt/jobfirst/scripts/monitor-team-collaboration.sh
    
    log_success "监控脚本创建完成"
}

# 创建sudoers配置
configure_sudoers() {
    log_info "配置sudoers..."
    
    # 创建sudoers配置目录
    mkdir -p /etc/sudoers.d
    
    # 创建开发用户sudoers配置
    cat > /etc/sudoers.d/dev-users << 'EOF'
# JobFirst 开发团队用户权限配置
# 此文件由脚本自动管理，请勿手动修改

# 开发用户组权限
%developers ALL=(ALL) NOPASSWD: /opt/jobfirst/scripts/monitor-*.sh
%developers ALL=(ALL) NOPASSWD: /opt/jobfirst/scripts/check-*.sh

# 默认拒绝所有其他权限
Defaults:%developers !requiretty
EOF

    # 设置正确的权限
    chmod 440 /etc/sudoers.d/dev-users
    
    log_success "sudoers配置完成"
}

# 创建示例用户
create_example_users() {
    log_info "创建示例用户..."
    
    # 创建示例SSH密钥（仅用于演示）
    EXAMPLE_SSH_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC7vbqajDhA..."
    
    # 创建示例用户（可选）
    read -p "是否创建示例用户？(y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        /opt/jobfirst/scripts/create-dev-user.sh "demo_frontend" "frontend" "$EXAMPLE_SSH_KEY"
        /opt/jobfirst/scripts/create-dev-user.sh "demo_backend" "backend" "$EXAMPLE_SSH_KEY"
        /opt/jobfirst/scripts/create-dev-user.sh "demo_qa" "qa" "$EXAMPLE_SSH_KEY"
        log_success "示例用户创建完成"
    fi
}

# 显示使用说明
show_usage_instructions() {
    log_info "显示使用说明..."
    
    cat << 'EOF'

=== JobFirst 团队协作开发环境设置完成 ===

📋 使用说明：

1. 添加团队成员：
   sudo /opt/jobfirst/scripts/create-dev-user.sh <username> <role> <ssh_public_key>
   
   角色选项：
   - admin: 完全管理员权限
   - developer: 开发权限
   - frontend: 前端开发权限
   - backend: 后端开发权限
   - qa: 测试权限
   - guest: 访客权限

2. 删除团队成员：
   sudo /opt/jobfirst/scripts/remove-dev-user.sh <username>

3. 监控团队协作：
   sudo /opt/jobfirst/scripts/monitor-team-collaboration.sh

4. 查看审计日志：
   sudo ausearch -k jobfirst_access

5. 查看SSH登录记录：
   sudo tail -f /var/log/auth.log

🔒 安全提醒：
- 请确保每个团队成员使用独立的SSH密钥
- 定期审查用户权限和访问日志
- 及时删除不再需要的用户账号
- 保持系统和软件更新

📞 技术支持：
如有问题，请联系系统管理员。

EOF
}

# 主函数
main() {
    log_info "开始设置JobFirst团队协作开发环境..."
    
    check_root
    create_dev_group
    configure_ssh_security
    configure_firewall
    create_user_management_scripts
    configure_project_permissions
    configure_audit
    create_monitoring_scripts
    configure_sudoers
    create_example_users
    show_usage_instructions
    
    log_success "JobFirst团队协作开发环境设置完成！"
}

# 运行主函数
main "$@"
