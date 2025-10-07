# 阿里云ECS远程登录配置指南

## 🎯 为什么需要远程登录？

### 1. **部署JobFirst系统**
- 上传代码和配置文件
- 安装系统依赖（MySQL、Redis、Nginx等）
- 配置服务环境
- 启动和监控服务

### 2. **系统管理**
- 查看服务状态和日志
- 更新系统配置
- 监控资源使用情况
- 故障排除和问题修复

### 3. **GitHub Actions自动部署**
- SSH密钥认证
- 自动化部署脚本执行
- 服务重启和配置更新

## 🔐 远程登录配置方法

### 方法1: 密码登录（简单但不够安全）

#### 1.1 重置实例密码
```bash
# 在阿里云ECS控制台操作
1. 进入ECS控制台
2. 选择您的实例
3. 点击"更多" -> "密码/密钥" -> "重置实例密码"
4. 设置新密码（8-30位，包含大小写字母、数字、特殊字符）
5. 重启实例使密码生效
```

#### 1.2 使用密码登录
```bash
# 使用SSH客户端登录
ssh root@your-alibaba-cloud-ip

# 输入密码后即可登录
```

### 方法2: SSH密钥登录（推荐，更安全）

#### 2.1 生成SSH密钥对
```bash
# 在本地生成SSH密钥对
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"

# 查看公钥内容
cat ~/.ssh/id_rsa.pub
```

#### 2.2 配置阿里云SSH密钥
```bash
# 在阿里云ECS控制台操作
1. 进入ECS控制台
2. 选择"密钥对" -> "创建密钥对"
3. 输入密钥对名称
4. 选择"自动创建"或"导入已有密钥对"
5. 绑定到您的ECS实例
```

#### 2.3 使用SSH密钥登录
```bash
# 配置SSH客户端
cat >> ~/.ssh/config << 'EOF'
Host alibaba-cloud
    HostName your-alibaba-cloud-ip
    User root
    IdentityFile ~/.ssh/id_rsa
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
EOF

# 登录
ssh alibaba-cloud
```

## 🚀 GitHub Actions SSH配置

### 1. 为GitHub Actions配置SSH访问

#### 1.1 创建专用SSH密钥
```bash
# 为GitHub Actions创建专用密钥
ssh-keygen -t rsa -b 4096 -C "github-actions@jobfirst.com" -f ~/.ssh/github_actions_key

# 查看公钥
cat ~/.ssh/github_actions_key.pub
```

#### 1.2 配置阿里云SSH密钥
```bash
# 将公钥添加到阿里云ECS
1. 复制公钥内容
2. 在ECS控制台添加SSH密钥
3. 绑定到ECS实例
```

#### 1.3 配置GitHub Secrets
```bash
# 在GitHub仓库中配置Secrets
1. 进入仓库 Settings -> Secrets and variables -> Actions
2. 添加以下Secrets:

ALIBABA_CLOUD_SSH_PRIVATE_KEY: # 私钥内容
ALIBABA_CLOUD_SERVER_IP: # 阿里云ECS公网IP
ALIBABA_CLOUD_SERVER_USER: root
```

### 2. 测试SSH连接
```bash
# 在GitHub Actions中测试连接
- name: Test SSH Connection
  run: |
    echo "$SSH_PRIVATE_KEY" > ~/.ssh/id_rsa
    chmod 600 ~/.ssh/id_rsa
    ssh -o StrictHostKeyChecking=no root@$SERVER_IP "echo 'SSH连接成功'"
```

## 🛠️ 系统初始化配置

### 1. 首次登录后的系统配置

#### 1.1 更新系统
```bash
# 更新系统包
apt update && apt upgrade -y

# 安装基础工具
apt install -y curl wget vim git htop tree
```

#### 1.2 配置防火墙
```bash
# 安装和配置UFW防火墙
apt install -y ufw

# 开放必要端口
ufw allow 22/tcp    # SSH
ufw allow 80/tcp    # HTTP
ufw allow 443/tcp   # HTTPS
ufw allow 8080/tcp  # JobFirst API

# 启用防火墙
ufw --force enable
```

#### 1.3 创建部署目录
```bash
# 创建JobFirst部署目录
mkdir -p /opt/jobfirst/{logs,uploads,temp,backup}
chmod 755 /opt/jobfirst
```

### 2. 安装系统依赖

#### 2.1 安装MySQL
```bash
# 安装MySQL
apt install -y mysql-server

# 启动MySQL服务
systemctl start mysql
systemctl enable mysql

# 配置MySQL
mysql_secure_installation
```

#### 2.2 安装Redis
```bash
# 安装Redis
apt install -y redis-server

# 启动Redis服务
systemctl start redis-server
systemctl enable redis-server
```

#### 2.3 安装Nginx
```bash
# 安装Nginx
apt install -y nginx

# 启动Nginx服务
systemctl start nginx
systemctl enable nginx
```

## 📊 安全配置建议

### 1. SSH安全配置

#### 1.1 修改SSH配置
```bash
# 编辑SSH配置文件
vim /etc/ssh/sshd_config

# 推荐配置
Port 22
Protocol 2
PermitRootLogin yes
PubkeyAuthentication yes
PasswordAuthentication no  # 如果使用密钥登录，可以禁用密码
MaxAuthTries 3
MaxSessions 10
ClientAliveInterval 300
ClientAliveCountMax 2
```

#### 1.2 重启SSH服务
```bash
# 重启SSH服务
systemctl restart sshd
```

### 2. 系统安全配置

#### 2.1 创建非root用户
```bash
# 创建部署用户
useradd -m -s /bin/bash jobfirst
usermod -aG sudo jobfirst

# 配置SSH密钥
mkdir -p /home/jobfirst/.ssh
cp ~/.ssh/authorized_keys /home/jobfirst/.ssh/
chown -R jobfirst:jobfirst /home/jobfirst/.ssh
chmod 700 /home/jobfirst/.ssh
chmod 600 /home/jobfirst/.ssh/authorized_keys
```

#### 2.2 配置sudo权限
```bash
# 编辑sudoers文件
visudo

# 添加以下配置
jobfirst ALL=(ALL) NOPASSWD: /bin/systemctl restart basic-server
jobfirst ALL=(ALL) NOPASSWD: /bin/systemctl start basic-server
jobfirst ALL=(ALL) NOPASSWD: /bin/systemctl stop basic-server
jobfirst ALL=(ALL) NOPASSWD: /bin/systemctl status basic-server
```

## 🔧 部署脚本配置

### 1. 创建部署脚本
```bash
# 创建部署脚本
cat > /opt/jobfirst/deploy.sh << 'EOF'
#!/bin/bash

# JobFirst部署脚本
set -e

echo "开始部署JobFirst系统..."

# 停止现有服务
systemctl stop basic-server || true

# 备份现有版本
if [ -d "/opt/jobfirst/current" ]; then
    mv /opt/jobfirst/current /opt/jobfirst/backup/$(date +%Y%m%d_%H%M%S)
fi

# 解压新版本
tar -xzf /tmp/jobfirst-deployment.tar.gz -C /opt/jobfirst/
mv /opt/jobfirst/dist /opt/jobfirst/current

# 设置权限
chmod +x /opt/jobfirst/current/basic-server
chown -R jobfirst:jobfirst /opt/jobfirst/current

# 启动服务
systemctl start basic-server
systemctl enable basic-server

echo "部署完成！"
EOF

chmod +x /opt/jobfirst/deploy.sh
```

### 2. 配置系统服务
```bash
# 创建systemd服务文件
cat > /etc/systemd/system/basic-server.service << 'EOF'
[Unit]
Description=JobFirst Basic Server
After=network.target mysql.service redis.service

[Service]
Type=simple
User=jobfirst
WorkingDirectory=/opt/jobfirst/current
ExecStart=/opt/jobfirst/current/basic-server
Restart=always
RestartSec=5
Environment=GIN_MODE=release

[Install]
WantedBy=multi-user.target
EOF

# 重新加载systemd
systemctl daemon-reload
```

## 📱 监控和日志

### 1. 配置日志轮转
```bash
# 配置logrotate
cat > /etc/logrotate.d/jobfirst << 'EOF'
/opt/jobfirst/logs/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 jobfirst jobfirst
    postrotate
        systemctl reload basic-server
    endscript
}
EOF
```

### 2. 配置监控脚本
```bash
# 创建监控脚本
cat > /opt/jobfirst/monitor.sh << 'EOF'
#!/bin/bash

# 系统监控脚本
echo "=== JobFirst系统状态 ==="
echo "时间: $(date)"
echo ""

echo "=== 服务状态 ==="
systemctl status basic-server --no-pager -l
echo ""

echo "=== 系统资源 ==="
echo "内存使用:"
free -h
echo ""
echo "磁盘使用:"
df -h
echo ""
echo "CPU使用:"
top -bn1 | grep "Cpu(s)"
echo ""

echo "=== 网络连接 ==="
netstat -tlnp | grep :8080
EOF

chmod +x /opt/jobfirst/monitor.sh
```

## 🎯 总结

### 远程登录的必要性
1. **系统部署**: 上传代码、安装依赖、配置服务
2. **系统管理**: 监控状态、查看日志、故障排除
3. **自动化部署**: GitHub Actions通过SSH执行部署脚本
4. **日常维护**: 更新配置、重启服务、备份数据

### 推荐配置
1. **使用SSH密钥登录**（更安全）
2. **配置专用部署用户**
3. **设置适当的权限**
4. **配置防火墙规则**
5. **启用日志轮转**

### 下一步操作
1. **重置实例密码**或**配置SSH密钥**
2. **首次登录并配置系统**
3. **安装必要依赖**
4. **配置GitHub Actions SSH访问**
5. **测试自动部署**

**是的，您绝对需要远程登录实例！这是部署和管理JobFirst系统的必要步骤。**
