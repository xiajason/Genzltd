# JobFirst系统腾讯云轻量服务器部署指南

**创建时间**: 2025年9月6日 13:30  
**版本**: V1.0  
**维护人员**: AI Assistant  

## 📋 概述

本指南详细说明如何将JobFirst系统部署到腾讯云轻量应用服务器，实现远程协同开发和测试。使用轻量服务器可以避免Docker容器的额外费用，同时提供完整的开发环境。

## 🎯 部署架构

### 系统架构
```
腾讯云轻量应用服务器
├── 前端 (Taro H5 + 微信小程序)
├── 后端 (Go + Gin)
├── AI服务 (Python + Sanic)
├── 数据库 (MySQL + PostgreSQL + Redis)
└── Web服务器 (Nginx)
```

### 服务端口
- **80**: Nginx (前端 + API代理)
- **8080**: 后端API服务
- **8206**: AI服务
- **3306**: MySQL数据库
- **5432**: PostgreSQL数据库
- **6379**: Redis缓存

## 🚀 快速部署

### 1. 准备腾讯云轻量服务器

#### 服务器配置建议
- **CPU**: 2核以上
- **内存**: 4GB以上
- **硬盘**: 50GB以上
- **带宽**: 5Mbps以上
- **系统**: Ubuntu 20.04 LTS 或 CentOS 8

#### 购买和配置
1. 登录腾讯云控制台
2. 选择"轻量应用服务器"
3. 创建实例，选择Ubuntu 20.04 LTS
4. 配置安全组，开放端口：22, 80, 443, 8080, 8206
5. 设置root密码或配置SSH密钥

### 2. 服务器环境准备

#### 方法一：使用自动化脚本（推荐）
```bash
# 在服务器上执行
wget https://raw.githubusercontent.com/your-repo/jobfirst/main/scripts/setup-tencent-server.sh
chmod +x setup-tencent-server.sh
sudo ./setup-tencent-server.sh
```

#### 方法二：手动安装
```bash
# 更新系统
sudo apt update && sudo apt upgrade -y

# 安装基础工具
sudo apt install -y curl wget git vim unzip

# 安装Go 1.21
wget https://go.dev/dl/go1.21.5.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc

# 安装Python 3.11
sudo apt install -y python3.11 python3.11-pip python3.11-venv

# 安装Node.js 18
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# 安装MySQL 8.0
sudo apt install -y mysql-server
sudo mysql_secure_installation

# 安装PostgreSQL 14
sudo apt install -y postgresql postgresql-contrib

# 安装Redis 7.0
sudo apt install -y redis-server

# 安装Nginx
sudo apt install -y nginx
```

### 3. 配置SSH密钥认证

#### 在本地生成SSH密钥
```bash
# 生成SSH密钥对
ssh-keygen -t rsa -b 4096 -C "your-email@example.com"

# 复制公钥到服务器
ssh-copy-id root@your-server-ip
```

#### 测试SSH连接
```bash
ssh root@your-server-ip
```

### 4. 部署系统

#### 使用部署脚本
```bash
# 在本地执行
./scripts/deploy-to-tencent-cloud.sh your-server-ip

# 带备份的部署
./scripts/deploy-to-tencent-cloud.sh your-server-ip --backup

# 指定用户和端口
./scripts/deploy-to-tencent-cloud.sh your-server-ip --user ubuntu --port 2222
```

#### 手动部署步骤
```bash
# 1. 上传代码到服务器
scp -r . root@your-server-ip:/opt/jobfirst/

# 2. 在服务器上构建和配置
ssh root@your-server-ip
cd /opt/jobfirst

# 构建后端
cd backend
go mod download
go build -o basic-server ./cmd/basic-server/main.go

# 构建前端
cd ../frontend-taro
npm install
npm run build:h5

# 配置数据库
mysql -u root -p
CREATE DATABASE jobfirst;
CREATE USER 'jobfirst'@'localhost' IDENTIFIED BY 'jobfirst_prod_2024';
GRANT ALL PRIVILEGES ON jobfirst.* TO 'jobfirst'@'localhost';

# 启动服务
sudo systemctl start jobfirst-backend
sudo systemctl start jobfirst-ai
sudo systemctl restart nginx
```

## 🔧 配置说明

### 环境变量配置

#### 后端配置 (`/opt/jobfirst/configs/config.prod.yaml`)
```yaml
# 数据库配置
database:
  host: "localhost"
  port: "3306"
  name: "jobfirst"
  user: "jobfirst"
  password: "jobfirst_prod_2024"

# Redis配置
redis:
  host: "localhost"
  port: "6379"
  password: "redis_prod_2024"

# JWT配置
jwt:
  secret: "jobfirst-prod-secret-key-2024"
```

#### AI服务配置 (`/opt/jobfirst/configs/ai_service.env`)
```bash
AI_SERVICE_PORT=8206
POSTGRES_HOST=localhost
POSTGRES_USER=jobfirst
POSTGRES_DB=jobfirst_vector
POSTGRES_PASSWORD=postgres_prod_2024
```

### Nginx配置

#### 主配置文件 (`/etc/nginx/sites-available/jobfirst`)
```nginx
server {
    listen 80;
    server_name _;
    
    # 前端静态文件
    location / {
        root /opt/jobfirst/frontend/dist/build/h5;
        index index.html;
        try_files $uri $uri/ /index.html;
    }
    
    # API代理
    location /api/ {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
    
    # AI服务代理
    location /ai/ {
        proxy_pass http://localhost:8206/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### 系统服务配置

#### 后端服务 (`/etc/systemd/system/jobfirst-backend.service`)
```ini
[Unit]
Description=JobFirst Backend Service
After=network.target mysql.service redis.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/jobfirst/backend
ExecStart=/opt/jobfirst/backend/basic-server
Restart=always
RestartSec=5
Environment=GIN_MODE=release

[Install]
WantedBy=multi-user.target
```

#### AI服务 (`/etc/systemd/system/jobfirst-ai.service`)
```ini
[Unit]
Description=JobFirst AI Service
After=network.target postgresql.service redis.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/jobfirst/backend/internal/ai-service
ExecStart=/usr/bin/python3 ai_service.py
Restart=always
RestartSec=5
EnvironmentFile=/opt/jobfirst/configs/ai_service.env

[Install]
WantedBy=multi-user.target
```

## 🔄 CI/CD自动化部署

### GitHub Actions配置

#### 1. 设置仓库密钥
在GitHub仓库设置中添加以下密钥：
- `PRODUCTION_SERVER_IP`: 生产服务器IP
- `PRODUCTION_SERVER_USER`: 服务器用户名
- `PRODUCTION_SSH_PRIVATE_KEY`: SSH私钥
- `STAGING_SERVER_IP`: 测试服务器IP（可选）
- `STAGING_SERVER_USER`: 测试服务器用户名（可选）
- `STAGING_SSH_PRIVATE_KEY`: 测试服务器SSH私钥（可选）

#### 2. 触发部署
```bash
# 推送到main分支自动部署到生产环境
git push origin main

# 推送到develop分支自动部署到测试环境
git push origin develop

# 手动触发部署
# 在GitHub Actions页面点击"Run workflow"
```

#### 3. 部署流程
1. **测试阶段**: 运行单元测试和集成测试
2. **构建阶段**: 构建前端和后端应用
3. **部署阶段**: 上传到服务器并重启服务
4. **验证阶段**: 健康检查和功能验证

### 本地CI/CD脚本
```bash
# 使用CI/CD脚本部署
export DEPLOY_SERVER_IP="your-server-ip"
export SSH_PRIVATE_KEY="$(cat ~/.ssh/id_rsa)"
./scripts/ci-cd-deploy.sh
```

## 🔍 监控和维护

### 服务管理命令

#### 查看服务状态
```bash
# 查看所有服务状态
sudo systemctl status jobfirst-backend jobfirst-ai nginx mysql redis postgresql

# 查看服务日志
sudo journalctl -u jobfirst-backend -f
sudo journalctl -u jobfirst-ai -f
```

#### 重启服务
```bash
# 重启后端服务
sudo systemctl restart jobfirst-backend

# 重启AI服务
sudo systemctl restart jobfirst-ai

# 重启所有服务
sudo systemctl restart jobfirst-backend jobfirst-ai nginx
```

#### 查看应用日志
```bash
# 查看后端日志
tail -f /opt/jobfirst/logs/basic-server.log

# 查看AI服务日志
tail -f /opt/jobfirst/logs/ai-service.log

# 查看Nginx日志
tail -f /var/log/nginx/access.log
tail -f /var/log/nginx/error.log
```

### 健康检查

#### 手动健康检查
```bash
# 检查后端服务
curl -f http://localhost:8080/api/v1/consul/status

# 检查AI服务
curl -f http://localhost:8206/health

# 检查前端
curl -f http://localhost/

# 检查数据库连接
mysql -u jobfirst -p -e "SELECT 1"
redis-cli ping
psql -U jobfirst -d jobfirst_vector -c "SELECT 1"
```

#### 自动化健康检查脚本
```bash
#!/bin/bash
# health-check.sh

SERVER_IP="your-server-ip"
SERVICES=("backend" "ai" "frontend" "mysql" "redis" "postgresql")

for service in "${SERVICES[@]}"; do
    case $service in
        "backend")
            curl -f http://$SERVER_IP/api/v1/consul/status > /dev/null 2>&1
            ;;
        "ai")
            curl -f http://$SERVER_IP/ai/health > /dev/null 2>&1
            ;;
        "frontend")
            curl -f http://$SERVER_IP/ > /dev/null 2>&1
            ;;
        "mysql")
            mysql -u jobfirst -pjobfirst_prod_2024 -e "SELECT 1" > /dev/null 2>&1
            ;;
        "redis")
            redis-cli -a redis_prod_2024 ping > /dev/null 2>&1
            ;;
        "postgresql")
            psql -U jobfirst -d jobfirst_vector -c "SELECT 1" > /dev/null 2>&1
            ;;
    esac
    
    if [ $? -eq 0 ]; then
        echo "✅ $service 服务正常"
    else
        echo "❌ $service 服务异常"
    fi
done
```

## 🔐 安全配置

### 防火墙配置
```bash
# 配置UFW防火墙
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 8080/tcp
sudo ufw allow 8206/tcp
sudo ufw enable
```

### SSL证书配置
```bash
# 安装Certbot
sudo apt install -y certbot python3-certbot-nginx

# 申请SSL证书
sudo certbot --nginx -d your-domain.com

# 自动续期
sudo crontab -e
# 添加: 0 12 * * * /usr/bin/certbot renew --quiet
```

### 数据库安全
```bash
# MySQL安全配置
sudo mysql_secure_installation

# PostgreSQL安全配置
sudo -u postgres psql
ALTER USER postgres PASSWORD 'strong_password';
```

## 📊 性能优化

### 系统优化
```bash
# 优化系统参数
echo 'vm.swappiness=10' >> /etc/sysctl.conf
echo 'net.core.somaxconn=65535' >> /etc/sysctl.conf
sysctl -p
```

### 数据库优化
```bash
# MySQL优化
# 编辑 /etc/mysql/mysql.conf.d/mysqld.cnf
[mysqld]
innodb_buffer_pool_size = 1G
innodb_log_file_size = 256M
max_connections = 200
```

### Nginx优化
```bash
# 编辑 /etc/nginx/nginx.conf
worker_processes auto;
worker_connections 1024;
keepalive_timeout 65;
gzip on;
gzip_types text/plain application/json application/javascript text/css;
```

## 🚨 故障排除

### 常见问题

#### 1. 服务启动失败
```bash
# 检查服务状态
sudo systemctl status jobfirst-backend

# 查看详细错误
sudo journalctl -u jobfirst-backend -n 50

# 检查端口占用
netstat -tlnp | grep :8080
```

#### 2. 数据库连接失败
```bash
# 检查数据库服务
sudo systemctl status mysql

# 测试数据库连接
mysql -u jobfirst -p -h localhost

# 检查数据库配置
cat /opt/jobfirst/configs/config.prod.yaml
```

#### 3. 前端访问异常
```bash
# 检查Nginx配置
sudo nginx -t

# 检查前端文件
ls -la /opt/jobfirst/frontend/dist/build/h5/

# 检查Nginx日志
tail -f /var/log/nginx/error.log
```

#### 4. AI服务异常
```bash
# 检查Python环境
python3 --version
pip3 list

# 检查AI服务日志
tail -f /opt/jobfirst/logs/ai-service.log

# 检查PostgreSQL连接
psql -U jobfirst -d jobfirst_vector -c "SELECT 1"
```

### 日志分析
```bash
# 分析错误日志
grep -i error /opt/jobfirst/logs/basic-server.log
grep -i error /opt/jobfirst/logs/ai-service.log
grep -i error /var/log/nginx/error.log

# 分析访问日志
awk '{print $1}' /var/log/nginx/access.log | sort | uniq -c | sort -nr
```

## 📞 技术支持

### 获取帮助
- **部署脚本帮助**: `./scripts/deploy-to-tencent-cloud.sh --help`
- **CI/CD脚本帮助**: `./scripts/ci-cd-deploy.sh --help`
- **服务器环境脚本帮助**: `./scripts/setup-tencent-server.sh --help`

### 联系方式
- **技术支持**: 通过项目文档和GitHub Issues
- **紧急联系**: 查看系统日志和错误报告
- **部署问题**: 检查服务器状态和网络连接

---

**文档更新时间**: 2025年9月6日 13:30  
**文档版本**: V1.0  
**维护状态**: ✅ 活跃维护  
**下次更新**: 根据部署反馈更新
