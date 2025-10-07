#!/bin/bash

# JobFirst 开发团队SSH访问配置脚本
# 用于配置团队成员远程访问腾讯云轻量服务器

set -e

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
    if [[ $EUID -ne 0 ]]; then
        log_error "此脚本需要root权限运行"
        log_info "请使用: sudo $0"
        exit 1
    fi
}

# 检查系统环境
check_environment() {
    log_info "检查系统环境..."
    
    # 检查操作系统
    if [[ ! -f /etc/os-release ]]; then
        log_error "无法识别操作系统"
        exit 1
    fi
    
    source /etc/os-release
    log_info "操作系统: $NAME $VERSION"
    
    # 检查必要的包
    local packages=("openssh-server" "sudo" "curl" "jq")
    for package in "${packages[@]}"; do
        if ! command -v $package &> /dev/null; then
            log_warning "缺少包: $package，正在安装..."
            if [[ "$ID" == "ubuntu" ]] || [[ "$ID" == "debian" ]]; then
                apt-get update && apt-get install -y $package
            elif [[ "$ID" == "centos" ]] || [[ "$ID" == "rhel" ]]; then
                yum install -y $package
            fi
        fi
    done
    
    log_success "系统环境检查完成"
}

# 配置SSH服务
configure_ssh() {
    log_info "配置SSH服务..."
    
    # 备份原始配置
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.$(date +%Y%m%d_%H%M%S)
    
    # 创建SSH配置
    cat > /etc/ssh/sshd_config << 'EOF'
# JobFirst 开发团队SSH配置

# 基本配置
Port 22
Protocol 2
AddressFamily any
ListenAddress 0.0.0.0

# 认证配置
PermitRootLogin no
PubkeyAuthentication yes
PasswordAuthentication no
PermitEmptyPasswords no
ChallengeResponseAuthentication no
UsePAM yes

# 安全配置
MaxAuthTries 3
MaxSessions 10
ClientAliveInterval 300
ClientAliveCountMax 2
LoginGraceTime 60

# 日志配置
SyslogFacility AUTH
LogLevel INFO

# 用户配置
AllowUsers jobfirst-*
DenyUsers root

# 其他配置
X11Forwarding no
PrintMotd no
PrintLastLog yes
TCPKeepAlive yes
UsePrivilegeSeparation yes
StrictModes yes
Compression delayed
EOF

    # 重启SSH服务
    systemctl restart sshd
    systemctl enable sshd
    
    log_success "SSH服务配置完成"
}

# 创建开发团队用户组
create_dev_groups() {
    log_info "创建开发团队用户组..."
    
    # 创建主要用户组
    groupadd -f jobfirst-dev
    
    # 创建角色用户组
    local groups=("jobfirst-super-admin" "jobfirst-system-admin" "jobfirst-dev-lead" 
                  "jobfirst-frontend-dev" "jobfirst-backend-dev" "jobfirst-qa-engineer" "jobfirst-guest")
    
    for group in "${groups[@]}"; do
        groupadd -f $group
        log_info "创建用户组: $group"
    done
    
    log_success "开发团队用户组创建完成"
}

# 创建用户主目录结构
create_user_directories() {
    log_info "创建用户主目录结构..."
    
    # 创建共享目录
    mkdir -p /opt/jobfirst/shared/{logs,uploads,temp}
    chmod 755 /opt/jobfirst/shared
    
    # 创建用户工作目录
    mkdir -p /home/jobfirst-users/{.ssh,workspace,logs}
    chmod 700 /home/jobfirst-users/.ssh
    chmod 755 /home/jobfirst-users/workspace
    
    log_success "用户主目录结构创建完成"
}

# 创建sudoers配置
create_sudoers_config() {
    log_info "创建sudoers配置..."
    
    # 备份原始sudoers
    cp /etc/sudoers /etc/sudoers.backup.$(date +%Y%m%d_%H%M%S)
    
    # 创建开发团队sudoers配置
    cat > /etc/sudoers.d/jobfirst-dev-team << 'EOF'
# JobFirst 开发团队sudoers配置

# 超级管理员 - 完全权限
%jobfirst-super-admin ALL=(ALL) NOPASSWD:ALL

# 系统管理员 - 系统管理权限
%jobfirst-system-admin ALL=(ALL) NOPASSWD:/bin/systemctl restart basic-server,/bin/systemctl restart nginx,/bin/systemctl restart mysql,/bin/systemctl status basic-server,/bin/systemctl status nginx,/bin/systemctl status mysql,/usr/bin/mysql,/usr/bin/mysqldump,/bin/cp,/bin/mv,/bin/rm

# 开发负责人 - 项目管理和部署权限
%jobfirst-dev-lead ALL=(ALL) NOPASSWD:/bin/systemctl restart basic-server,/bin/systemctl restart nginx,/usr/bin/mysql,/usr/bin/mysqldump,/bin/cp,/bin/mv

# 后端开发 - 后端服务权限
%jobfirst-backend-dev ALL=(ALL) NOPASSWD:/bin/systemctl restart basic-server,/usr/bin/mysql,/usr/bin/mysqldump

# 前端开发 - 前端构建权限
%jobfirst-frontend-dev ALL=(ALL) NOPASSWD:/bin/npm,/bin/yarn,/bin/pnpm

# 测试工程师 - 测试执行权限
%jobfirst-qa-engineer ALL=(ALL) NOPASSWD:/usr/bin/mysql,/bin/tail,/bin/grep,/bin/curl

# 访客用户 - 只读权限
%jobfirst-guest ALL=(ALL) NOPASSWD:/bin/ls,/bin/cat,/bin/tail,/bin/grep
EOF

    # 设置正确的权限
    chmod 440 /etc/sudoers.d/jobfirst-dev-team
    
    log_success "sudoers配置创建完成"
}

# 创建用户管理脚本
create_user_management_scripts() {
    log_info "创建用户管理脚本..."
    
    # 创建添加用户脚本
    cat > /usr/local/bin/jobfirst-add-user << 'EOF'
#!/bin/bash

# JobFirst 添加开发团队成员脚本

if [[ $# -lt 3 ]]; then
    echo "用法: $0 <username> <role> <ssh_public_key>"
    echo "角色: super_admin, system_admin, dev_lead, frontend_dev, backend_dev, qa_engineer, guest"
    exit 1
fi

USERNAME=$1
ROLE=$2
SSH_PUBLIC_KEY=$3

# 验证角色
case $ROLE in
    super_admin|system_admin|dev_lead|frontend_dev|backend_dev|qa_engineer|guest)
        ;;
    *)
        echo "错误: 无效的角色 '$ROLE'"
        exit 1
        ;;
esac

# 创建用户
useradd -m -s /bin/bash -g jobfirst-dev -G jobfirst-$ROLE jobfirst-$USERNAME

# 设置用户主目录权限
chmod 755 /home/jobfirst-$USERNAME
mkdir -p /home/jobfirst-$USERNAME/.ssh
chmod 700 /home/jobfirst-$USERNAME/.ssh

# 添加SSH公钥
echo "$SSH_PUBLIC_KEY" > /home/jobfirst-$USERNAME/.ssh/authorized_keys
chmod 600 /home/jobfirst-$USERNAME/.ssh/authorized_keys
chown -R jobfirst-$USERNAME:jobfirst-dev /home/jobfirst-$USERNAME

# 创建用户工作目录
mkdir -p /home/jobfirst-$USERNAME/workspace
chown -R jobfirst-$USERNAME:jobfirst-dev /home/jobfirst-$USERNAME/workspace

echo "用户 jobfirst-$USERNAME 创建成功，角色: $ROLE"
EOF

    # 创建删除用户脚本
    cat > /usr/local/bin/jobfirst-remove-user << 'EOF'
#!/bin/bash

# JobFirst 删除开发团队成员脚本

if [[ $# -lt 1 ]]; then
    echo "用法: $0 <username>"
    exit 1
fi

USERNAME=$1

# 删除用户
userdel -r jobfirst-$USERNAME 2>/dev/null || echo "用户 jobfirst-$USERNAME 不存在或已删除"

echo "用户 jobfirst-$USERNAME 删除完成"
EOF

    # 创建列出用户脚本
    cat > /usr/local/bin/jobfirst-list-users << 'EOF'
#!/bin/bash

# JobFirst 列出开发团队成员脚本

echo "JobFirst 开发团队成员列表:"
echo "=========================="

for user in $(getent passwd | grep "^jobfirst-" | cut -d: -f1); do
    groups=$(groups $user | cut -d: -f2 | tr ' ' '\n' | grep "jobfirst-" | tr '\n' ' ')
    echo "用户: $user"
    echo "  组: $groups"
    echo "  主目录: $(getent passwd $user | cut -d: -f6)"
    echo "  最后登录: $(last -1 $user 2>/dev/null | head -1 | awk '{print $4, $5, $6, $7}' || echo '从未登录')"
    echo ""
done
EOF

    # 设置脚本权限
    chmod +x /usr/local/bin/jobfirst-*
    
    log_success "用户管理脚本创建完成"
}

# 创建防火墙配置
configure_firewall() {
    log_info "配置防火墙..."
    
    # 检查防火墙状态
    if systemctl is-active --quiet ufw; then
        # Ubuntu/Debian UFW
        ufw allow 22/tcp
        ufw allow 80/tcp
        ufw allow 443/tcp
        ufw allow 8080/tcp
        log_success "UFW防火墙配置完成"
    elif systemctl is-active --quiet firewalld; then
        # CentOS/RHEL Firewalld
        firewall-cmd --permanent --add-service=ssh
        firewall-cmd --permanent --add-service=http
        firewall-cmd --permanent --add-service=https
        firewall-cmd --permanent --add-port=8080/tcp
        firewall-cmd --reload
        log_success "Firewalld防火墙配置完成"
    else
        log_warning "未检测到防火墙服务，请手动配置"
    fi
}

# 创建监控脚本
create_monitoring_scripts() {
    log_info "创建监控脚本..."
    
    # 创建SSH登录监控脚本
    cat > /usr/local/bin/jobfirst-monitor-ssh << 'EOF'
#!/bin/bash

# JobFirst SSH登录监控脚本

LOG_FILE="/var/log/jobfirst-ssh.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

# 监控SSH登录
tail -f /var/log/auth.log | while read line; do
    if echo "$line" | grep -q "Accepted publickey for jobfirst-"; then
        USER=$(echo "$line" | grep -o "jobfirst-[a-zA-Z0-9_-]*")
        IP=$(echo "$line" | grep -o "[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+")
        echo "[$DATE] SSH登录: $USER from $IP" >> $LOG_FILE
        
        # 发送通知（可选）
        # echo "SSH登录: $USER from $IP" | mail -s "JobFirst SSH Login" admin@jobfirst.com
    fi
done
EOF

    # 创建系统状态检查脚本
    cat > /usr/local/bin/jobfirst-status << 'EOF'
#!/bin/bash

# JobFirst 系统状态检查脚本

echo "JobFirst 系统状态报告"
echo "====================="
echo "时间: $(date)"
echo ""

echo "1. 服务状态:"
echo "-----------"
systemctl is-active basic-server && echo "✅ basic-server: 运行中" || echo "❌ basic-server: 未运行"
systemctl is-active nginx && echo "✅ nginx: 运行中" || echo "❌ nginx: 未运行"
systemctl is-active mysql && echo "✅ mysql: 运行中" || echo "❌ mysql: 未运行"
systemctl is-active sshd && echo "✅ sshd: 运行中" || echo "❌ sshd: 未运行"
echo ""

echo "2. 开发团队成员:"
echo "---------------"
jobfirst-list-users
echo ""

echo "3. 系统资源:"
echo "-----------"
echo "CPU使用率: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)%"
echo "内存使用率: $(free | grep Mem | awk '{printf("%.1f%%", $3/$2 * 100.0)}')"
echo "磁盘使用率: $(df -h / | awk 'NR==2{printf "%s", $5}')"
echo ""

echo "4. 网络连接:"
echo "-----------"
echo "SSH连接数: $(ss -tn | grep :22 | wc -l)"
echo "HTTP连接数: $(ss -tn | grep :80 | wc -l)"
echo "HTTPS连接数: $(ss -tn | grep :443 | wc -l)"
EOF

    # 设置脚本权限
    chmod +x /usr/local/bin/jobfirst-monitor-ssh
    chmod +x /usr/local/bin/jobfirst-status
    
    log_success "监控脚本创建完成"
}

# 创建用户分发指南
create_user_distribution_guide() {
    log_info "创建用户分发指南..."
    
    cat > /opt/jobfirst/USER_DISTRIBUTION_GUIDE.md << 'EOF'
# JobFirst 开发团队成员分发指南

## 📋 概述

本指南说明如何为团队成员创建账号并配置远程访问权限。

## 🔐 账号创建流程

### 1. 收集团队成员信息

在创建账号前，需要收集以下信息：
- 用户名（建议使用真实姓名拼音）
- 角色（super_admin, system_admin, dev_lead, frontend_dev, backend_dev, qa_engineer, guest）
- SSH公钥（团队成员需要提供）

### 2. 生成SSH密钥对

团队成员需要在本地生成SSH密钥对：

```bash
# 生成SSH密钥对
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"

# 查看公钥内容
cat ~/.ssh/id_rsa.pub
```

### 3. 创建用户账号

管理员在服务器上执行：

```bash
# 添加团队成员
sudo jobfirst-add-user <username> <role> "<ssh_public_key>"

# 示例
sudo jobfirst-add-user zhangsan frontend_dev "ssh-rsa AAAAB3NzaC1yc2E... zhangsan@example.com"
```

### 4. 验证账号创建

```bash
# 列出所有团队成员
sudo jobfirst-list-users

# 检查用户组
groups jobfirst-zhangsan
```

## 🚀 远程访问配置

### 1. 团队成员本地配置

团队成员需要在本地配置SSH客户端：

```bash
# 创建SSH配置文件
mkdir -p ~/.ssh
cat >> ~/.ssh/config << 'EOF'
Host jobfirst-server
    HostName 101.33.251.158
    Port 22
    User jobfirst-zhangsan
    IdentityFile ~/.ssh/id_rsa
    ServerAliveInterval 60
    ServerAliveCountMax 3
EOF

# 设置正确的权限
chmod 600 ~/.ssh/config
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub
```

### 2. 测试连接

```bash
# 测试SSH连接
ssh jobfirst-server

# 如果连接成功，应该看到类似输出：
# Welcome to JobFirst Development Server!
# Last login: Mon Sep  6 14:30:00 2025 from 192.168.1.100
```

## 🔧 权限管理

### 角色权限说明

| 角色 | 服务器访问 | 代码修改 | 数据库操作 | 服务重启 | 配置修改 |
|------|------------|----------|------------|----------|----------|
| super_admin | ✅ 完全访问 | ✅ 所有模块 | ✅ 所有数据库 | ✅ 所有服务 | ✅ 所有配置 |
| system_admin | ✅ 系统管理 | ✅ 系统模块 | ✅ 系统数据库 | ✅ 系统服务 | ✅ 系统配置 |
| dev_lead | ✅ 项目访问 | ✅ 项目代码 | ✅ 项目数据库 | ✅ 项目服务 | ✅ 项目配置 |
| frontend_dev | ✅ SSH访问 | ✅ 前端代码 | ❌ 数据库 | ❌ 服务重启 | ✅ 前端配置 |
| backend_dev | ✅ SSH访问 | ✅ 后端代码 | ✅ 业务数据库 | ✅ 业务服务 | ✅ 后端配置 |
| qa_engineer | ✅ SSH访问 | ✅ 测试代码 | ✅ 测试数据库 | ❌ 服务重启 | ✅ 测试配置 |
| guest | ✅ SSH访问 | ❌ 代码修改 | ❌ 数据库 | ❌ 服务重启 | ❌ 配置修改 |

### 常用命令

```bash
# 查看个人权限
sudo -l

# 重启服务（需要相应权限）
sudo systemctl restart basic-server

# 访问数据库（需要相应权限）
sudo mysql -u root -p

# 查看日志
sudo tail -f /opt/jobfirst/logs/backend.log
```

## 📊 监控和维护

### 1. 查看系统状态

```bash
# 运行系统状态检查
sudo jobfirst-status
```

### 2. 监控SSH登录

```bash
# 查看SSH登录日志
sudo tail -f /var/log/jobfirst-ssh.log

# 查看最近登录
sudo last | grep jobfirst-
```

### 3. 用户管理

```bash
# 列出所有用户
sudo jobfirst-list-users

# 删除用户
sudo jobfirst-remove-user <username>

# 修改用户组
sudo usermod -G jobfirst-<new_role> jobfirst-<username>
```

## 🚨 安全注意事项

### 1. SSH密钥管理

- 每个团队成员必须使用唯一的SSH密钥
- 定期轮换SSH密钥（建议每6个月）
- 不要共享SSH私钥

### 2. 权限最小化原则

- 只授予必要的权限
- 定期审查用户权限
- 及时撤销离职人员权限

### 3. 监控和审计

- 定期检查SSH登录日志
- 监控异常登录行为
- 记录所有敏感操作

## 📞 技术支持

### 常见问题

#### 1. SSH连接被拒绝

```bash
# 检查SSH服务状态
sudo systemctl status sshd

# 检查防火墙设置
sudo ufw status

# 检查用户是否存在
sudo jobfirst-list-users
```

#### 2. 权限不足

```bash
# 检查用户组
groups jobfirst-<username>

# 检查sudoers配置
sudo cat /etc/sudoers.d/jobfirst-dev-team
```

#### 3. 无法访问特定目录

```bash
# 检查目录权限
ls -la /opt/jobfirst/

# 修改目录权限（需要管理员权限）
sudo chown -R jobfirst-<username>:jobfirst-dev /opt/jobfirst/
```

### 联系方式

- **系统管理员**: admin@jobfirst.com
- **技术支持**: support@jobfirst.com
- **紧急联系**: +86-xxx-xxxx-xxxx

---

**注意**: 本指南基于JobFirst开发团队管理系统，请确保在生产环境中进行充分测试后再使用。
EOF

    log_success "用户分发指南创建完成"
}

# 主函数
main() {
    log_info "开始配置JobFirst开发团队SSH访问..."
    
    check_root
    check_environment
    configure_ssh
    create_dev_groups
    create_user_directories
    create_sudoers_config
    create_user_management_scripts
    configure_firewall
    create_monitoring_scripts
    create_user_distribution_guide
    
    log_success "JobFirst开发团队SSH访问配置完成！"
    log_info "请查看 /opt/jobfirst/USER_DISTRIBUTION_GUIDE.md 了解详细使用说明"
    log_info "使用 'jobfirst-status' 命令检查系统状态"
    log_info "使用 'jobfirst-list-users' 命令查看团队成员"
}

# 执行主函数
main "$@"
