# JobFirst SSH访问配置快速部署指南

## 🚀 一键部署命令

### 前提条件
- 已获得腾讯云轻量服务器root权限
- 服务器IP: `101.33.251.158`
- 已安装MySQL、Nginx等基础服务

### 第一步：上传脚本到服务器

```bash
# 上传SSH访问配置脚本
scp basic/scripts/setup-ssh-access.sh root@101.33.251.158:/opt/jobfirst/scripts/
scp basic/scripts/role-based-access-control.sh root@101.33.251.158:/opt/jobfirst/scripts/
scp basic/scripts/user-distribution-workflow.sh root@101.33.251.158:/opt/jobfirst/scripts/

# 上传部署指南
scp basic/SSH_ACCESS_CONFIGURATION_GUIDE.md root@101.33.251.158:/opt/jobfirst/docs/
```

### 第二步：在服务器上执行配置

```bash
# 连接到服务器
ssh root@101.33.251.158

# 进入项目目录
cd /opt/jobfirst

# 设置脚本执行权限
chmod +x scripts/setup-ssh-access.sh
chmod +x scripts/role-based-access-control.sh
chmod +x scripts/user-distribution-workflow.sh

# 执行SSH访问控制配置
sudo ./scripts/setup-ssh-access.sh

# 执行基于角色的访问控制配置
sudo ./scripts/role-based-access-control.sh
```

### 第三步：创建团队成员账号

```bash
# 使用交互式用户分发工作流程
sudo ./scripts/user-distribution-workflow.sh

# 或者直接使用命令创建用户（示例）
sudo jobfirst-add-user zhangsan frontend_dev "ssh-rsa AAAAB3NzaC1yc2E... zhangsan@example.com"
```

## 📋 部署检查清单

### ✅ 系统配置检查

```bash
# 检查SSH服务状态
sudo systemctl status sshd

# 检查用户组
getent group | grep jobfirst

# 检查sudoers配置
sudo cat /etc/sudoers.d/jobfirst-dev-team

# 检查防火墙状态
sudo ufw status
```

### ✅ 用户管理检查

```bash
# 列出所有团队成员
sudo jobfirst-list-users

# 测试用户权限
sudo jobfirst-test-permissions <username>

# 查看系统状态
sudo jobfirst-status
```

### ✅ 监控系统检查

```bash
# 查看访问监控
sudo jobfirst-monitor-access

# 生成审计报告
sudo jobfirst-audit-report

# 启动实时监控
sudo jobfirst-realtime-monitor
```

## 👥 团队成员接入流程

### 1. 团队成员准备SSH密钥

```bash
# 生成SSH密钥对
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"

# 查看公钥内容
cat ~/.ssh/id_rsa.pub
```

### 2. 管理员创建用户账号

```bash
# 使用用户分发工作流程
sudo ./scripts/user-distribution-workflow.sh
```

### 3. 团队成员配置SSH客户端

```bash
# 配置SSH客户端
mkdir -p ~/.ssh
cat >> ~/.ssh/config << 'EOF'
Host jobfirst-server
    HostName 101.33.251.158
    Port 22
    User jobfirst-<username>
    IdentityFile ~/.ssh/id_rsa
    ServerAliveInterval 60
    ServerAliveCountMax 3
EOF

# 设置正确的权限
chmod 600 ~/.ssh/config
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub
```

### 4. 测试SSH连接

```bash
# 测试连接
ssh jobfirst-server
```

## 🔧 常用管理命令

### 用户管理

```bash
# 列出所有用户
sudo jobfirst-list-users

# 添加用户
sudo jobfirst-add-user <username> <role> "<ssh_public_key>"

# 删除用户
sudo jobfirst-remove-user <username>

# 测试用户权限
sudo jobfirst-test-permissions <username>
```

### 权限管理

```bash
# 权限管理界面
sudo jobfirst-permission-manager

# 授予权限
sudo jobfirst-manage-permissions grant <username> <permission>

# 撤销权限
sudo jobfirst-manage-permissions revoke <username> <permission>

# 查看用户权限
sudo jobfirst-manage-permissions list <username>
```

### 监控和审计

```bash
# 查看系统状态
sudo jobfirst-status

# 查看访问监控
sudo jobfirst-monitor-access

# 生成审计报告
sudo jobfirst-audit-report

# 实时监控
sudo jobfirst-realtime-monitor
```

## 🛡️ 安全配置验证

### SSH安全配置

```bash
# 检查SSH配置
sudo sshd -T | grep -E "(PermitRootLogin|PasswordAuthentication|PubkeyAuthentication)"

# 应该显示：
# PermitRootLogin no
# PasswordAuthentication no
# PubkeyAuthentication yes
```

### 用户权限验证

```bash
# 检查用户组权限
groups jobfirst-<username>

# 检查sudo权限
sudo -l -U jobfirst-<username>

# 检查目录权限
ls -la /home/jobfirst-<username>/
ls -la /opt/jobfirst/
```

### 防火墙配置

```bash
# 检查防火墙状态
sudo ufw status

# 应该显示开放的端口：
# 22/tcp (SSH)
# 80/tcp (HTTP)
# 443/tcp (HTTPS)
# 8080/tcp (API)
```

## 🚨 故障排除

### SSH连接问题

```bash
# 检查SSH服务
sudo systemctl status sshd
sudo systemctl restart sshd

# 检查SSH日志
sudo tail -f /var/log/auth.log

# 检查用户是否存在
sudo jobfirst-list-users

# 检查SSH公钥
sudo cat /home/jobfirst-<username>/.ssh/authorized_keys
```

### 权限问题

```bash
# 检查用户组
groups jobfirst-<username>

# 检查sudoers配置
sudo cat /etc/sudoers.d/jobfirst-dev-team

# 测试权限
sudo jobfirst-test-permissions <username>
```

### 监控问题

```bash
# 检查日志文件
sudo ls -la /var/log/jobfirst-*

# 检查监控脚本
sudo which jobfirst-status
sudo which jobfirst-monitor-access

# 重启监控服务
sudo systemctl restart sshd
```

## 📞 技术支持

### 联系方式

- **系统管理员**: admin@jobfirst.com
- **技术支持**: support@jobfirst.com
- **紧急联系**: +86-xxx-xxxx-xxxx

### 文档资源

- **完整指南**: /opt/jobfirst/docs/SSH_ACCESS_CONFIGURATION_GUIDE.md
- **部署总结**: /opt/jobfirst/DEV_TEAM_MANAGEMENT_DEPLOYMENT_SUMMARY.md
- **实施指南**: /opt/jobfirst/DEV_TEAM_MANAGEMENT_IMPLEMENTATION_GUIDE.md

## 🎉 部署完成

**恭喜！JobFirst开发团队SSH访问配置已成功部署！**

### 下一步：

1. **创建团队成员账号** - 使用 `user-distribution-workflow.sh` 脚本
2. **配置团队成员SSH客户端** - 按照接入流程配置
3. **测试SSH连接** - 验证远程访问功能
4. **开始协作开发** - 团队成员可以安全地远程访问服务器

### 系统特性：

- ✅ **安全的SSH访问控制**
- ✅ **基于角色的权限管理**
- ✅ **完整的监控和审计**
- ✅ **用户友好的管理界面**
- ✅ **自动化用户分发流程**

**现在您的团队成员可以安全、可控地远程访问腾讯云轻量服务器进行二次开发了！**

---

**注意**: 请确保在生产环境中进行充分测试后再使用。如有问题，请参考完整的技术文档或联系技术支持。
