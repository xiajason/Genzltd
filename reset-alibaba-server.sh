#!/bin/bash

# 阿里云服务器重置和重新配置脚本

echo "🔄 开始阿里云服务器重置和重新配置"
echo "=================================="

# 检查是否为root用户
if [ "$EUID" -ne 0 ]; then
    echo "❌ 请使用sudo运行此脚本"
    exit 1
fi

# 第一步：备份重要数据
echo "📦 第一步：备份重要数据..."
echo "=========================="

# 创建备份目录
mkdir -p /tmp/server-reset-backup
cd /tmp/server-reset-backup

# 备份系统配置
echo "📋 备份系统配置..."
tar -czf system-config-backup.tar.gz /etc/ 2>/dev/null || echo "⚠️ 系统配置备份失败"

# 备份用户数据
echo "👤 备份用户数据..."
tar -czf user-data-backup.tar.gz /home/ 2>/dev/null || echo "⚠️ 用户数据备份失败"

# 备份应用数据
echo "📱 备份应用数据..."
tar -czf app-data-backup.tar.gz /opt/ 2>/dev/null || echo "⚠️ 应用数据备份失败"

echo "✅ 数据备份完成"
echo "备份位置: /tmp/server-reset-backup/"
ls -la /tmp/server-reset-backup/

# 第二步：系统更新和优化
echo "🔄 第二步：系统更新和优化..."
echo "=============================="

# 更新系统包
echo "📦 更新系统包..."
apt update && apt upgrade -y

# 安装基础软件
echo "🛠️ 安装基础软件..."
apt install -y curl wget git unzip htop tree vim nano

# 配置时区
echo "🌍 配置时区..."
timedatectl set-timezone Asia/Shanghai

# 配置主机名
echo "🏷️ 配置主机名..."
hostnamectl set-hostname alibaba-production

# 第三步：系统优化配置
echo "⚙️ 第三步：系统优化配置..."
echo "=========================="

# 配置系统参数
echo "🔧 配置系统参数..."
tee -a /etc/sysctl.conf << 'EOF'
# 网络优化
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.tcp_congestion_control = bbr

# 文件描述符限制
fs.file-max = 65536
EOF

# 应用配置
sysctl -p

# 配置limits
echo "📊 配置limits..."
tee -a /etc/security/limits.conf << 'EOF'
* soft nofile 65536
* hard nofile 65536
* soft nproc 65536
* hard nproc 65536
EOF

# 第四步：安装Docker
echo "🐳 第四步：安装Docker..."
echo "========================"

# 卸载旧版本Docker
echo "🗑️ 卸载旧版本Docker..."
apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || echo "没有旧版本Docker需要卸载"

# 安装Docker
echo "📦 安装Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# 配置Docker用户组
echo "👥 配置Docker用户组..."
usermod -aG docker deploy 2>/dev/null || echo "用户deploy不存在，跳过"
usermod -aG docker ubuntu

# 启动Docker服务
echo "🚀 启动Docker服务..."
systemctl start docker
systemctl enable docker

# 验证Docker安装
echo "✅ 验证Docker安装..."
docker --version
docker run hello-world

# 第五步：安装Docker Compose
echo "🐙 第五步：安装Docker Compose..."
echo "==============================="

# 安装Docker Compose
echo "📦 安装Docker Compose..."
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# 设置执行权限
chmod +x /usr/local/bin/docker-compose

# 创建软链接
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

# 验证安装
echo "✅ 验证Docker Compose安装..."
docker-compose --version

# 第六步：配置Docker镜像源
echo "🌐 第六步：配置Docker镜像源..."
echo "============================="

# 创建Docker配置目录
mkdir -p /etc/docker

# 配置镜像源
echo "🔧 配置Docker镜像源..."
tee /etc/docker/daemon.json << 'EOF'
{
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com",
    "https://mirror.baidubce.com",
    "https://registry.docker-cn.com"
  ],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
EOF

# 重启Docker服务
echo "🔄 重启Docker服务..."
systemctl restart docker

# 第七步：安装Nginx
echo "🌐 第七步：安装Nginx..."
echo "======================"

# 安装Nginx
echo "📦 安装Nginx..."
apt install -y nginx

# 启动Nginx服务
echo "🚀 启动Nginx服务..."
systemctl start nginx
systemctl enable nginx

# 检查Nginx状态
echo "✅ 检查Nginx状态..."
systemctl status nginx --no-pager

# 第八步：配置防火墙
echo "🔥 第八步：配置防火墙..."
echo "======================="

# 安装UFW
echo "📦 安装UFW..."
apt install -y ufw

# 重置UFW规则
echo "🔄 重置UFW规则..."
ufw --force reset

# 设置默认策略
echo "⚙️ 设置默认策略..."
ufw default deny incoming
ufw default allow outgoing

# 开放必要端口
echo "🔓 开放必要端口..."
ufw allow 22/tcp    # SSH
ufw allow 80/tcp    # HTTP
ufw allow 443/tcp   # HTTPS
ufw allow 8080/tcp  # 应用端口
ufw allow 9090/tcp  # Prometheus
ufw allow 3000/tcp  # Grafana

# 启用防火墙
echo "🔥 启用防火墙..."
ufw --force enable

# 检查防火墙状态
echo "✅ 检查防火墙状态..."
ufw status verbose

# 第九步：配置SSH安全
echo "🔒 第九步：配置SSH安全..."
echo "======================="

# 备份SSH配置
echo "📋 备份SSH配置..."
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup

# 配置SSH安全
echo "🔧 配置SSH安全..."
tee -a /etc/ssh/sshd_config << 'EOF'
# 安全配置
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
Protocol 2
ClientAliveInterval 300
ClientAliveCountMax 2
MaxAuthTries 3
EOF

# 重启SSH服务
echo "🔄 重启SSH服务..."
systemctl restart ssh

# 第十步：安装监控工具
echo "📊 第十步：安装监控工具..."
echo "========================="

# 安装系统监控工具
echo "📦 安装系统监控工具..."
apt install -y htop iotop nethogs nload net-tools dnsutils logrotate

# 配置日志轮转
echo "📋 配置日志轮转..."
tee /etc/logrotate.d/docker << 'EOF'
/var/lib/docker/containers/*/*.log {
    daily
    rotate 7
    compress
    size=1M
    missingok
    delaycompress
    copytruncate
}
EOF

# 第十一步：安装SSL证书工具
echo "🔐 第十一步：安装SSL证书工具..."
echo "=============================="

# 安装Certbot
echo "📦 安装Certbot..."
apt install -y certbot python3-certbot-nginx

# 验证安装
echo "✅ 验证Certbot安装..."
certbot --version

# 配置自动续期
echo "⏰ 配置自动续期..."
echo "0 12 * * * /usr/bin/certbot renew --quiet" | crontab -

# 第十二步：创建生产环境目录
echo "📁 第十二步：创建生产环境目录..."
echo "==============================="

# 创建生产环境目录
echo "📂 创建生产环境目录..."
mkdir -p /opt/production
chown deploy:deploy /opt/production 2>/dev/null || chown ubuntu:ubuntu /opt/production

# 创建子目录
echo "📁 创建子目录..."
mkdir -p /opt/production/{monitoring,config,data,logs,scripts,backup,ssl}

# 设置权限
echo "🔐 设置权限..."
chmod 755 /opt/production
chmod 755 /opt/production/*

# 创建日志目录
echo "📝 创建日志目录..."
mkdir -p /var/log/production
chown deploy:deploy /var/log/production 2>/dev/null || chown ubuntu:ubuntu /var/log/production

# 第十三步：最终检查
echo "✅ 第十三步：最终检查..."
echo "======================="

# 检查系统信息
echo "🖥️ 系统信息:"
uname -a
lsb_release -a
free -h
df -h

# 检查网络
echo "🌐 网络信息:"
ip addr show
ping -c 3 8.8.8.8

# 检查服务状态
echo "🔧 服务状态:"
systemctl status docker --no-pager
systemctl status nginx --no-pager
systemctl status ssh --no-pager

# 验证Docker环境
echo "🐳 Docker环境:"
docker --version
docker-compose --version
docker run hello-world

# 验证网络连接
echo "🌐 网络连接:"
curl -I http://localhost
curl -I https://www.google.com

# 验证防火墙
echo "🔥 防火墙状态:"
ufw status

# 第十四步：重置完成
echo "🎉 阿里云服务器重置完成！"
echo "=========================="
echo "✅ 系统重置完成"
echo "✅ Docker环境配置完成"
echo "✅ Nginx配置完成"
echo "✅ 防火墙配置完成"
echo "✅ SSL证书工具安装完成"
echo "✅ 生产环境目录创建完成"
echo "✅ 安全配置完成"
echo ""
echo "📁 生产环境目录: /opt/production/"
echo "📋 备份文件位置: /tmp/server-reset-backup/"
echo ""
echo "🚀 准备迎接我们的服务部署！"
echo "=============================="
