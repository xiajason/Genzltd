# 阿里云生产环境部署执行指南

**创建时间**: 2025年1月27日  
**版本**: v1.0  
**状态**: 🚀 **开始执行**  
**目标**: 实际部署到阿里云生产环境

---

## 🎯 部署执行步骤

### **第一步：阿里云服务器准备**

#### **1.1 创建阿里云ECS实例**
```bash
# 阿里云控制台操作步骤：
# 1. 登录阿里云控制台
# 2. 进入ECS实例管理
# 3. 创建ECS实例
# 4. 选择配置：
#    - 实例规格: ecs.c6.large (2核4GB)
#    - 操作系统: Ubuntu 20.04 LTS
#    - 网络: 专有网络VPC
#    - 安全组: 开放22, 80, 443, 8080, 9090, 3000端口
#    - 存储: 40GB ESSD Entry云盘
```

#### **1.2 创建阿里云RDS数据库**
```bash
# 阿里云控制台操作步骤：
# 1. 进入RDS实例管理
# 2. 创建RDS实例
# 3. 选择配置：
#    - 数据库类型: MySQL 8.0
#    - 规格: rds.mysql.s2.large (1核2GB)
#    - 存储: 20GB SSD
#    - 网络: 与ECS同VPC
#    - 备份: 自动备份7天
```

#### **1.3 创建阿里云SLB负载均衡**
```bash
# 阿里云控制台操作步骤：
# 1. 进入SLB实例管理
# 2. 创建SLB实例
# 3. 选择配置：
#    - 类型: 应用型负载均衡ALB
#    - 规格: 标准版
#    - 监听端口: 80, 443
#    - 后端服务器: ECS实例
```

---

## 🚀 部署执行脚本

### **第二步：服务器环境配置**

#### **2.1 连接阿里云服务器**
```bash
# 使用SSH连接阿里云服务器
# 替换 [阿里云IP] 为实际的阿里云ECS公网IP
ssh -i ~/.ssh/alibaba-key.pem ubuntu@[阿里云IP]

# 检查服务器状态
sudo systemctl status
df -h
free -h
```

#### **2.2 安装基础软件**
```bash
# 更新系统包
sudo apt update && sudo apt upgrade -y

# 安装Docker和Docker Compose
sudo apt install -y docker.io docker-compose
sudo systemctl start docker
sudo systemctl enable docker

# 配置用户权限
sudo usermod -aG docker ubuntu
sudo systemctl restart docker

# 安装Nginx
sudo apt install -y nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# 安装其他必要软件
sudo apt install -y curl wget git unzip
```

#### **2.3 创建部署目录结构**
```bash
# 创建生产环境目录
sudo mkdir -p /opt/production
sudo chown ubuntu:ubuntu /opt/production
cd /opt/production

# 创建子目录
mkdir -p {monitoring,config,data,logs,scripts,backup}
```

---

## 📦 服务部署配置

### **第三步：Docker Compose配置**

#### **3.1 创建生产环境Docker Compose文件**
```bash
# 创建docker-compose.yml
cat > docker-compose.yml << 'EOF'
version: '3.8'
services:
  # LoomaCRM主服务
  looma-crm:
    image: loomacrm-production:latest
    container_name: looma-crm-prod
    ports:
      - "8800:8800"
    environment:
      - DATABASE_URL=mysql://user:pass@rds-host:3306/loomacrm
      - REDIS_URL=redis://localhost:6379
      - NODE_ENV=production
    volumes:
      - ./data:/app/data
      - ./logs:/app/logs
    restart: unless-stopped
    networks:
      - production-network

  # Zervigo Future版
  zervigo-future:
    image: zervigo-future-production:latest
    container_name: zervigo-future-prod
    ports:
      - "8200:8200"
    environment:
      - API_GATEWAY_URL=http://localhost:8200
      - LOOMACRM_URL=http://looma-crm:8800
      - NODE_ENV=production
    depends_on:
      - looma-crm
    restart: unless-stopped
    networks:
      - production-network

  # Zervigo DAO版
  zervigo-dao:
    image: zervigo-dao-production:latest
    container_name: zervigo-dao-prod
    ports:
      - "9200:9200"
    environment:
      - API_GATEWAY_URL=http://localhost:9200
      - LOOMACRM_URL=http://looma-crm:8800
      - NODE_ENV=production
    depends_on:
      - looma-crm
    restart: unless-stopped
    networks:
      - production-network

  # Zervigo 区块链版
  zervigo-blockchain:
    image: zervigo-blockchain-production:latest
    container_name: zervigo-blockchain-prod
    ports:
      - "8300:8300"
    environment:
      - API_GATEWAY_URL=http://localhost:8300
      - LOOMACRM_URL=http://looma-crm:8800
      - NODE_ENV=production
    depends_on:
      - looma-crm
    restart: unless-stopped
    networks:
      - production-network

  # Prometheus监控
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus-prod
    ports:
      - "9090:9090"
    volumes:
      - ./monitoring/prometheus.yml:/etc/prometheus/prometheus.yml
      - ./monitoring/data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--storage.tsdb.retention.time=200h'
      - '--web.enable-lifecycle'
    restart: unless-stopped
    networks:
      - production-network

  # Grafana监控面板
  grafana:
    image: grafana/grafana:latest
    container_name: grafana-prod
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin123
      - GF_USERS_ALLOW_SIGN_UP=false
    volumes:
      - ./monitoring/grafana:/var/lib/grafana
    restart: unless-stopped
    networks:
      - production-network

  # Node Exporter系统监控
  node-exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter-prod
    ports:
      - "9100:9100"
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.rootfs=/rootfs'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'
    restart: unless-stopped
    networks:
      - production-network

networks:
  production-network:
    driver: bridge
EOF
```

#### **3.2 创建Prometheus配置文件**
```bash
# 创建Prometheus配置目录
mkdir -p monitoring

# 创建prometheus.yml配置文件
cat > monitoring/prometheus.yml << 'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "alert_rules.yml"

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'looma-crm'
    static_configs:
      - targets: ['looma-crm:8800']
    metrics_path: '/metrics'
    scrape_interval: 30s

  - job_name: 'zervigo-future'
    static_configs:
      - targets: ['zervigo-future:8200']
    metrics_path: '/metrics'
    scrape_interval: 30s

  - job_name: 'zervigo-dao'
    static_configs:
      - targets: ['zervigo-dao:9200']
    metrics_path: '/metrics'
    scrape_interval: 30s

  - job_name: 'zervigo-blockchain'
    static_configs:
      - targets: ['zervigo-blockchain:8300']
    metrics_path: '/metrics'
    scrape_interval: 30s

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']
    scrape_interval: 30s
EOF
```

#### **3.3 创建告警规则文件**
```bash
# 创建告警规则文件
cat > monitoring/alert_rules.yml << 'EOF'
groups:
  - name: production-alerts
    rules:
      - alert: ServiceDown
        expr: up == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Service {{ $labels.instance }} is down"
          description: "Service {{ $labels.instance }} has been down for more than 1 minute."

      - alert: HighCPUUsage
        expr: 100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage on {{ $labels.instance }}"
          description: "CPU usage is above 80% for more than 5 minutes."

      - alert: HighMemoryUsage
        expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100 > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage on {{ $labels.instance }}"
          description: "Memory usage is above 80% for more than 5 minutes."

      - alert: DiskSpaceLow
        expr: (node_filesystem_avail_bytes / node_filesystem_size_bytes) * 100 < 20
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Low disk space on {{ $labels.instance }}"
          description: "Disk space is below 20% for more than 5 minutes."
EOF
```

---

## 🌐 Nginx反向代理配置

### **第四步：Nginx配置**

#### **4.1 创建Nginx配置文件**
```bash
# 创建Nginx站点配置
sudo tee /etc/nginx/sites-available/production << 'EOF'
upstream looma_crm {
    server localhost:8800;
}

upstream zervigo_future {
    server localhost:8200;
}

upstream zervigo_dao {
    server localhost:9200;
}

upstream zervigo_blockchain {
    server localhost:8300;
}

server {
    listen 80;
    server_name your-domain.com www.your-domain.com;

    # 安全头设置
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;

    # LoomaCRM主服务
    location / {
        proxy_pass http://looma_crm;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }

    # Zervigo Future版
    location /api/future/ {
        proxy_pass http://zervigo_future/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }

    # Zervigo DAO版
    location /api/dao/ {
        proxy_pass http://zervigo_dao/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }

    # Zervigo 区块链版
    location /api/blockchain/ {
        proxy_pass http://zervigo_blockchain/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }

    # 监控系统
    location /monitoring/ {
        proxy_pass http://localhost:3000/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # 健康检查端点
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
EOF
```

#### **4.2 启用Nginx站点配置**
```bash
# 启用站点配置
sudo ln -s /etc/nginx/sites-available/production /etc/nginx/sites-enabled/

# 删除默认站点
sudo rm -f /etc/nginx/sites-enabled/default

# 测试Nginx配置
sudo nginx -t

# 重启Nginx
sudo systemctl reload nginx
```

---

## 🔒 SSL证书配置

### **第五步：SSL证书配置**

#### **5.1 安装Certbot**
```bash
# 安装Certbot
sudo apt install -y certbot python3-certbot-nginx

# 获取SSL证书
sudo certbot --nginx -d your-domain.com -d www.your-domain.com

# 设置自动续期
echo "0 12 * * * /usr/bin/certbot renew --quiet" | sudo crontab -
```

#### **5.2 配置防火墙**
```bash
# 配置UFW防火墙
sudo ufw allow 22    # SSH
sudo ufw allow 80    # HTTP
sudo ufw allow 443   # HTTPS
sudo ufw allow 9090  # Prometheus
sudo ufw allow 3000  # Grafana
sudo ufw --force enable
```

---

## 🚀 部署执行

### **第六步：启动服务**

#### **6.1 启动Docker服务**
```bash
# 进入生产环境目录
cd /opt/production

# 启动所有服务
docker-compose up -d

# 检查服务状态
docker-compose ps

# 查看服务日志
docker-compose logs -f
```

#### **6.2 验证服务状态**
```bash
# 等待服务启动
sleep 30

# 检查服务健康状态
curl -f http://localhost:8800/health
curl -f http://localhost:8200/health
curl -f http://localhost:9200/health
curl -f http://localhost:8300/health

# 检查监控服务
curl -f http://localhost:9090/api/v1/query?query=up
curl -f http://localhost:3000/api/health
```

---

## 📊 监控配置

### **第七步：配置Grafana监控面板**

#### **7.1 访问Grafana**
```bash
# 访问Grafana
# URL: http://your-domain.com:3000
# 用户名: admin
# 密码: admin123
```

#### **7.2 配置数据源**
```bash
# 在Grafana中添加Prometheus数据源
# 数据源类型: Prometheus
# URL: http://prometheus:9090
# 访问: Server (默认)
```

#### **7.3 导入监控面板**
```bash
# 导入系统监控面板
# 面板ID: 1860 (Node Exporter Full)
# 面板ID: 11074 (Node Exporter for Prometheus Dashboard)
# 面板ID: 6417 (Kubernetes cluster monitoring)
```

---

## 🔄 备份配置

### **第八步：配置自动备份**

#### **8.1 创建备份脚本**
```bash
# 创建备份脚本
cat > scripts/backup.sh << 'EOF'
#!/bin/bash

# 备份脚本
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/opt/production/backup"
LOG_FILE="/opt/production/logs/backup.log"

echo "$(date): 开始备份..." >> $LOG_FILE

# 创建备份目录
mkdir -p $BACKUP_DIR/$DATE

# 备份数据库
mysqldump -h rds-host -u user -p database > $BACKUP_DIR/$DATE/database.sql

# 备份应用数据
tar -czf $BACKUP_DIR/$DATE/app-data.tar.gz /opt/production/data/

# 备份配置文件
tar -czf $BACKUP_DIR/$DATE/config.tar.gz /opt/production/config/

# 清理旧备份（保留7天）
find $BACKUP_DIR -type d -mtime +7 -exec rm -rf {} \;

echo "$(date): 备份完成" >> $LOG_FILE
EOF

chmod +x scripts/backup.sh
```

#### **8.2 设置定时备份**
```bash
# 设置每日备份
echo "0 2 * * * /opt/production/scripts/backup.sh" | crontab -
```

---

## ✅ 部署验证

### **第九步：功能测试**

#### **9.1 健康检查测试**
```bash
# 测试所有服务健康状态
curl -f http://your-domain.com/health
curl -f http://your-domain.com/api/future/health
curl -f http://your-domain.com/api/dao/health
curl -f http://your-domain.com/api/blockchain/health
```

#### **9.2 API功能测试**
```bash
# 测试用户认证
curl -X POST http://your-domain.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"test","password":"test"}'

# 测试简历管理
curl http://your-domain.com/api/resumes

# 测试公司管理
curl http://your-domain.com/api/companies
```

#### **9.3 监控系统测试**
```bash
# 测试Prometheus
curl http://your-domain.com:9090/api/v1/query?query=up

# 测试Grafana
curl http://your-domain.com:3000/api/health
```

---

## 🎯 部署完成检查清单

### **部署前检查**
- [ ] 阿里云ECS实例已创建
- [ ] 阿里云RDS数据库已创建
- [ ] 阿里云SLB负载均衡已创建
- [ ] 域名已解析到阿里云IP
- [ ] SSH密钥已配置

### **部署后检查**
- [ ] 所有Docker容器运行正常
- [ ] 所有服务健康检查通过
- [ ] 数据库连接正常
- [ ] 监控系统正常
- [ ] SSL证书配置正常
- [ ] 防火墙配置正常

### **功能验证**
- [ ] 用户认证功能正常
- [ ] 简历管理功能正常
- [ ] 公司管理功能正常
- [ ] AI服务功能正常
- [ ] 监控告警正常
- [ ] 备份恢复正常

---

## 🎉 部署完成

**阿里云生产环境部署完成！**

### **访问地址**
- **主服务**: https://your-domain.com
- **Future版**: https://your-domain.com/api/future/
- **DAO版**: https://your-domain.com/api/dao/
- **区块链版**: https://your-domain.com/api/blockchain/
- **监控面板**: https://your-domain.com:3000
- **Prometheus**: https://your-domain.com:9090

### **管理命令**
```bash
# 查看服务状态
docker-compose ps

# 查看服务日志
docker-compose logs -f [service-name]

# 重启服务
docker-compose restart [service-name]

# 停止服务
docker-compose down

# 启动服务
docker-compose up -d
```

**🎯 下一步**: 进行性能测试、安全测试和用户培训！ 🚀
