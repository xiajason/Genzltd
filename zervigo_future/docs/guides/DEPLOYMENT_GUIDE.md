# JobFirst 生产环境部署指南

## 📋 部署概述

JobFirst项目采用微服务架构，包含以下组件：
- **后端服务**: Go微服务 (API网关、用户服务、简历服务)
- **AI服务**: Python Sanic服务
- **前端**: Taro统一开发 (微信小程序 + H5)
- **数据库**: MySQL + Redis
- **服务发现**: Consul

## 🚀 快速部署

### 1. 环境要求

#### 服务器配置
- **CPU**: 2核心以上
- **内存**: 4GB以上
- **存储**: 20GB以上
- **操作系统**: Ubuntu 20.04+ / CentOS 8+ / macOS

#### 软件依赖
- **Go**: 1.21+
- **Python**: 3.9+
- **Node.js**: 18+
- **MySQL**: 8.0+
- **Redis**: 6.0+
- **Nginx**: 1.18+ (可选，用于反向代理)

### 2. 一键部署脚本

```bash
# 克隆项目
git clone <repository-url>
cd zervi-basic/basic

# 运行部署脚本
chmod +x scripts/deploy.sh
./scripts/deploy.sh
```

## 🔧 详细部署步骤

### 1. 数据库部署

#### MySQL配置
```bash
# 安装MySQL
sudo apt update
sudo apt install mysql-server

# 创建数据库和用户
mysql -u root -p
```

```sql
CREATE DATABASE jobfirst CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'jobfirst'@'localhost' IDENTIFIED BY 'your_password';
GRANT ALL PRIVILEGES ON jobfirst.* TO 'jobfirst'@'localhost';
FLUSH PRIVILEGES;
```

#### 初始化数据库
```bash
# 导入数据库结构
mysql -u jobfirst -p jobfirst < database/mysql/init.sql

# 导入测试数据
mysql -u jobfirst -p jobfirst < database/mysql/seed_v3.sql
```

#### Redis配置
```bash
# 安装Redis
sudo apt install redis-server

# 启动Redis
sudo systemctl start redis-server
sudo systemctl enable redis-server
```

### 2. 后端服务部署

#### 构建Go服务
```bash
cd backend

# 安装依赖
go mod tidy

# 构建生产版本
CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o basic-server cmd/basic-server/main.go

# 创建systemd服务文件
sudo tee /etc/systemd/system/jobfirst-backend.service > /dev/null <<EOF
[Unit]
Description=JobFirst Backend Service
After=network.target mysql.service redis.service

[Service]
Type=simple
User=www-data
WorkingDirectory=/opt/jobfirst/backend
ExecStart=/opt/jobfirst/backend/basic-server
Restart=always
RestartSec=5
Environment=GIN_MODE=release

[Install]
WantedBy=multi-user.target
EOF

# 启动服务
sudo systemctl daemon-reload
sudo systemctl enable jobfirst-backend
sudo systemctl start jobfirst-backend
```

#### AI服务部署
```bash
cd internal/ai-service

# 创建虚拟环境
python3 -m venv venv
source venv/bin/activate

# 安装依赖
pip install -r requirements.txt

# 创建systemd服务文件
sudo tee /etc/systemd/system/jobfirst-ai.service > /dev/null <<EOF
[Unit]
Description=JobFirst AI Service
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/opt/jobfirst/internal/ai-service
ExecStart=/opt/jobfirst/internal/ai-service/venv/bin/python app.py
Restart=always
RestartSec=5
Environment=PYTHONPATH=/opt/jobfirst/internal/ai-service

[Install]
WantedBy=multi-user.target
EOF

# 启动服务
sudo systemctl daemon-reload
sudo systemctl enable jobfirst-ai
sudo systemctl start jobfirst-ai
```

### 3. 前端部署

#### 微信小程序部署
```bash
cd frontend-taro

# 安装依赖
npm install

# 构建生产版本
NODE_ENV=production npm run build:weapp

# 上传到微信开发者工具
# 1. 打开微信开发者工具
# 2. 导入项目: dist/ 目录
# 3. 配置AppID
# 4. 上传代码
```

#### H5部署
```bash
# 构建H5版本
NODE_ENV=production npm run build:h5

# 部署到Nginx
sudo cp -r dist/build/h5/* /var/www/html/jobfirst/

# 配置Nginx
sudo tee /etc/nginx/sites-available/jobfirst > /dev/null <<EOF
server {
    listen 80;
    server_name your-domain.com;
    root /var/www/html/jobfirst;
    index index.html;

    location / {
        try_files \$uri \$uri/ /index.html;
    }

    location /api/ {
        proxy_pass http://localhost:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

sudo ln -s /etc/nginx/sites-available/jobfirst /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### 4. 服务发现部署

#### Consul部署
```bash
# 下载Consul
wget https://releases.hashicorp.com/consul/1.16.0/consul_1.16.0_linux_amd64.zip
unzip consul_1.16.0_linux_amd64.zip
sudo mv consul /usr/local/bin/

# 创建配置目录
sudo mkdir -p /etc/consul.d
sudo mkdir -p /opt/consul/data

# 创建配置文件
sudo tee /etc/consul.d/consul.json > /dev/null <<EOF
{
  "datacenter": "dc1",
  "data_dir": "/opt/consul/data",
  "log_level": "INFO",
  "node_name": "consul-server-1",
  "server": true,
  "bootstrap_expect": 1,
  "bind_addr": "0.0.0.0",
  "client_addr": "0.0.0.0",
  "ui_config": {
    "enabled": true
  }
}
EOF

# 创建systemd服务
sudo tee /etc/systemd/system/consul.service > /dev/null <<EOF
[Unit]
Description=Consul Service Discovery
After=network.target

[Service]
Type=simple
User=consul
Group=consul
ExecStart=/usr/local/bin/consul agent -config-dir=/etc/consul.d
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# 创建用户
sudo useradd -r -s /bin/false consul
sudo chown -R consul:consul /opt/consul

# 启动服务
sudo systemctl daemon-reload
sudo systemctl enable consul
sudo systemctl start consul
```

## 🔒 安全配置

### 1. 防火墙配置
```bash
# 开放必要端口
sudo ufw allow 22      # SSH
sudo ufw allow 80      # HTTP
sudo ufw allow 443     # HTTPS
sudo ufw allow 8080    # API Gateway
sudo ufw allow 8206    # AI Service
sudo ufw allow 8500    # Consul UI
sudo ufw enable
```

### 2. SSL证书配置
```bash
# 使用Let's Encrypt
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d your-domain.com
```

### 3. 环境变量配置
```bash
# 创建环境变量文件
sudo tee /opt/jobfirst/.env > /dev/null <<EOF
# 数据库配置
DB_HOST=localhost
DB_PORT=3306
DB_NAME=jobfirst
DB_USER=jobfirst
DB_PASSWORD=your_secure_password

# Redis配置
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=your_redis_password

# JWT配置
JWT_SECRET=your_very_secure_jwt_secret_key

# AI服务配置
AI_SERVICE_URL=http://localhost:8206
AI_API_KEY=your_ai_api_key
EOF

sudo chmod 600 /opt/jobfirst/.env
```

## 📊 监控和日志

### 1. 日志配置
```bash
# 创建日志目录
sudo mkdir -p /var/log/jobfirst
sudo chown www-data:www-data /var/log/jobfirst

# 配置日志轮转
sudo tee /etc/logrotate.d/jobfirst > /dev/null <<EOF
/var/log/jobfirst/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 www-data www-data
    postrotate
        systemctl reload jobfirst-backend
        systemctl reload jobfirst-ai
    endscript
}
EOF
```

### 2. 健康检查
```bash
# 创建健康检查脚本
sudo tee /opt/jobfirst/health-check.sh > /dev/null <<EOF
#!/bin/bash

# 检查后端服务
if ! curl -f http://localhost:8080/api/v1/consul/status > /dev/null 2>&1; then
    echo "Backend service is down"
    systemctl restart jobfirst-backend
fi

# 检查AI服务
if ! curl -f http://localhost:8206/health > /dev/null 2>&1; then
    echo "AI service is down"
    systemctl restart jobfirst-ai
fi

# 检查数据库
if ! mysql -u jobfirst -p'your_password' -e "SELECT 1" > /dev/null 2>&1; then
    echo "Database is down"
fi
EOF

sudo chmod +x /opt/jobfirst/health-check.sh

# 添加到crontab
echo "*/5 * * * * /opt/jobfirst/health-check.sh" | sudo crontab -
```

## 🚀 性能优化

### 1. 数据库优化
```sql
-- 创建索引
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_resumes_user_id ON resumes(user_id);
CREATE INDEX idx_jobs_status ON jobs(status);

-- 配置MySQL
[mysqld]
innodb_buffer_pool_size = 1G
innodb_log_file_size = 256M
max_connections = 200
```

### 2. Redis优化
```bash
# 配置Redis
sudo tee -a /etc/redis/redis.conf > /dev/null <<EOF
maxmemory 512mb
maxmemory-policy allkeys-lru
save 900 1
save 300 10
save 60 10000
EOF
```

### 3. 前端优化
```bash
# 启用Gzip压缩
sudo tee -a /etc/nginx/nginx.conf > /dev/null <<EOF
gzip on;
gzip_vary on;
gzip_min_length 1024;
gzip_types text/plain text/css application/json application/javascript text/xml application/xml;
EOF
```

## 🔄 更新部署

### 1. 后端更新
```bash
# 停止服务
sudo systemctl stop jobfirst-backend

# 备份当前版本
sudo cp /opt/jobfirst/backend/basic-server /opt/jobfirst/backend/basic-server.backup

# 更新代码
cd /opt/jobfirst
git pull origin main

# 重新构建
cd backend
go build -o basic-server cmd/basic-server/main.go

# 启动服务
sudo systemctl start jobfirst-backend
```

### 2. 前端更新
```bash
# 更新前端
cd /opt/jobfirst/frontend-taro
git pull origin main
npm install
NODE_ENV=production npm run build:h5

# 更新Nginx
sudo cp -r dist/build/h5/* /var/www/html/jobfirst/
```

## 📋 部署检查清单

- [ ] 数据库连接正常
- [ ] Redis连接正常
- [ ] 后端服务启动成功
- [ ] AI服务启动成功
- [ ] Consul服务发现正常
- [ ] 前端构建成功
- [ ] Nginx配置正确
- [ ] SSL证书配置
- [ ] 防火墙规则设置
- [ ] 日志配置正确
- [ ] 监控脚本运行
- [ ] 健康检查通过

## 🆘 故障排除

### 常见问题

1. **服务启动失败**
   ```bash
   # 查看日志
   sudo journalctl -u jobfirst-backend -f
   sudo journalctl -u jobfirst-ai -f
   ```

2. **数据库连接失败**
   ```bash
   # 检查MySQL状态
   sudo systemctl status mysql
   # 检查连接
   mysql -u jobfirst -p -e "SELECT 1"
   ```

3. **端口占用**
   ```bash
   # 查看端口占用
   sudo netstat -tlnp | grep :8080
   # 杀死进程
   sudo kill -9 <PID>
   ```

4. **前端构建失败**
   ```bash
   # 清理缓存
   rm -rf node_modules package-lock.json
   npm install
   npm run build:h5
   ```

## 📞 技术支持

如有部署问题，请检查：
1. 系统日志: `/var/log/syslog`
2. 应用日志: `/var/log/jobfirst/`
3. 服务状态: `systemctl status <service-name>`
4. 网络连接: `netstat -tlnp`

---

**部署完成后，请确保所有服务正常运行，并进行完整的功能测试。**
