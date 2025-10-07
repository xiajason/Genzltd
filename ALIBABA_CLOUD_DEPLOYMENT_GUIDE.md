# 阿里云生产环境部署指南

**创建时间**: 2025年1月27日  
**版本**: v1.0  
**状态**: 🚀 **准备部署**  
**目标**: 完成阿里云生产环境部署

---

## 🎯 部署准备

### **前置条件检查**
- ✅ 阿里云账号已注册
- ✅ 阿里云ECS实例已创建
- ✅ 阿里云RDS数据库已创建
- ✅ 阿里云SLB负载均衡已创建
- ✅ 域名已解析到阿里云IP
- ✅ SSL证书已配置

### **服务器信息**
```yaml
ECS实例:
  IP地址: [待确认]
  操作系统: Ubuntu 20.04 LTS
  CPU: 2核
  内存: 4GB
  存储: 40GB

RDS数据库:
  类型: MySQL 8.0
  规格: rds.mysql.s2.large
  存储: 20GB SSD

SLB负载均衡:
  类型: 应用型负载均衡ALB
  规格: 标准版
```

---

## 🚀 部署步骤

### **第一步：连接阿里云服务器**
```bash
# SSH连接到阿里云服务器
ssh -i ~/.ssh/alibaba-key.pem ubuntu@[阿里云IP]

# 检查服务器状态
sudo systemctl status docker
sudo systemctl status nginx
```

### **第二步：配置服务器环境**
```bash
# 安装Docker和Docker Compose
sudo apt update
sudo apt install -y docker.io docker-compose

# 配置用户权限
sudo usermod -aG docker ubuntu
sudo systemctl start docker
sudo systemctl enable docker

# 安装Nginx
sudo apt install -y nginx
sudo systemctl start nginx
sudo systemctl enable nginx
```

### **第三步：创建部署目录**
```bash
# 创建生产环境目录
sudo mkdir -p /opt/production
sudo chown ubuntu:ubuntu /opt/production
cd /opt/production

# 创建子目录
mkdir -p monitoring config data logs
```

### **第四步：配置Docker Compose**
```bash
# 创建生产环境Docker Compose配置
cat > docker-compose.yml << 'EOF'
version: '3.8'
services:
  looma-crm:
    image: loomacrm-production:latest
    ports:
      - "8800:8800"
    environment:
      - DATABASE_URL=mysql://user:pass@rds-host:3306/loomacrm
      - REDIS_URL=redis://localhost:6379
    volumes:
      - ./data:/app/data
      - ./logs:/app/logs
    restart: unless-stopped

  zervigo-future:
    image: zervigo-future-production:latest
    ports:
      - "8200:8200"
    environment:
      - API_GATEWAY_URL=http://localhost:8200
      - LOOMACRM_URL=http://localhost:8800
    depends_on:
      - looma-crm
    restart: unless-stopped

  zervigo-dao:
    image: zervigo-dao-production:latest
    ports:
      - "9200:9200"
    environment:
      - API_GATEWAY_URL=http://localhost:9200
      - LOOMACRM_URL=http://localhost:8800
    depends_on:
      - looma-crm
    restart: unless-stopped

  zervigo-blockchain:
    image: zervigo-blockchain-production:latest
    ports:
      - "8300:8300"
    environment:
      - API_GATEWAY_URL=http://localhost:8300
      - LOOMACRM_URL=http://localhost:8800
    depends_on:
      - looma-crm
    restart: unless-stopped

  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./monitoring/prometheus.yml:/etc/prometheus/prometheus.yml
    restart: unless-stopped

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin123
    volumes:
      - ./monitoring/grafana:/var/lib/grafana
    restart: unless-stopped

  node-exporter:
    image: prom/node-exporter:latest
    ports:
      - "9100:9100"
    restart: unless-stopped
EOF
```

### **第五步：配置监控系统**
```bash
# 创建Prometheus配置
mkdir -p monitoring
cat > monitoring/prometheus.yml << 'EOF'
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'looma-crm'
    static_configs:
      - targets: ['localhost:8800']
  
  - job_name: 'zervigo-future'
    static_configs:
      - targets: ['localhost:8200']
  
  - job_name: 'zervigo-dao'
    static_configs:
      - targets: ['localhost:9200']
  
  - job_name: 'zervigo-blockchain'
    static_configs:
      - targets: ['localhost:8300']
  
  - job_name: 'node-exporter'
    static_configs:
      - targets: ['localhost:9100']
EOF
```

### **第六步：配置Nginx反向代理**
```bash
# 创建Nginx配置
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
    server_name your-domain.com;

    # LoomaCRM主服务
    location / {
        proxy_pass http://looma_crm;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Zervigo Future版
    location /api/future/ {
        proxy_pass http://zervigo_future/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Zervigo DAO版
    location /api/dao/ {
        proxy_pass http://zervigo_dao/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Zervigo 区块链版
    location /api/blockchain/ {
        proxy_pass http://zervigo_blockchain/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # 监控系统
    location /monitoring/ {
        proxy_pass http://localhost:3000/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
EOF

# 启用站点配置
sudo ln -s /etc/nginx/sites-available/production /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### **第七步：配置SSL证书**
```bash
# 安装Certbot
sudo apt install -y certbot python3-certbot-nginx

# 获取SSL证书
sudo certbot --nginx -d your-domain.com

# 设置自动续期
sudo crontab -e
# 添加以下行：
# 0 12 * * * /usr/bin/certbot renew --quiet
```

### **第八步：配置防火墙**
```bash
# 配置UFW防火墙
sudo ufw allow 22    # SSH
sudo ufw allow 80    # HTTP
sudo ufw allow 443   # HTTPS
sudo ufw allow 9090  # Prometheus
sudo ufw allow 3000  # Grafana
sudo ufw enable
```

---

## 🚀 部署执行

### **部署脚本执行**
```bash
# 1. 部署生产环境
./deploy-alibaba-production.sh

# 2. 设置监控系统
./setup-production-monitoring.sh

# 3. 验证部署
./verify-production-deployment.sh
```

### **健康检查**
```bash
# 检查所有服务状态
curl http://your-domain.com/health
curl http://your-domain.com/api/future/health
curl http://your-domain.com/api/dao/health
curl http://your-domain.com/api/blockchain/health

# 检查监控系统
curl http://your-domain.com:9090/api/v1/query?query=up
curl http://your-domain.com:3000/api/health
```

---

## 📊 监控配置

### **Grafana仪表板配置**
```bash
# 访问Grafana
http://your-domain.com:3000
用户名: admin
密码: admin123

# 配置数据源
数据源类型: Prometheus
URL: http://localhost:9090

# 导入仪表板
- 系统监控仪表板
- 应用监控仪表板
- 数据库监控仪表板
- 业务指标监控仪表板
```

### **告警规则配置**
```yaml
# Prometheus告警规则
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
      
      - alert: HighCPUUsage
        expr: 100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage on {{ $labels.instance }}"
```

---

## 🔒 安全配置

### **数据库安全**
```bash
# 配置数据库访问控制
# 只允许ECS实例访问RDS
# 启用SSL连接
# 定期备份数据

# 创建数据库备份脚本
cat > backup-database.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
mysqldump -h rds-host -u user -p database > backup_${DATE}.sql
gzip backup_${DATE}.sql
aws s3 cp backup_${DATE}.sql.gz s3://your-backup-bucket/
EOF

chmod +x backup-database.sh
```

### **应用安全**
```bash
# 配置应用安全
# 启用HTTPS
# 配置CORS
# 设置访问控制
# 定期更新依赖
```

---

## 📈 性能优化

### **资源优化**
```yaml
ECS实例优化:
  CPU: 2核 (可扩展到4核)
  内存: 4GB (可扩展到8GB)
  存储: 40GB (可扩展到100GB)

RDS数据库优化:
  CPU: 1核 (可扩展到2核)
  内存: 2GB (可扩展到4GB)
  存储: 20GB (可扩展到100GB)
```

### **缓存策略**
```yaml
Redis缓存:
  - 用户会话缓存
  - API响应缓存
  - 数据库查询缓存

CDN加速:
  - 静态资源CDN
  - 图片CDN
  - API CDN
```

---

## 🔄 备份策略

### **数据备份**
```bash
# 数据库备份
mysqldump -h rds-host -u user -p database > backup.sql

# 应用数据备份
tar -czf app-data-backup.tar.gz /opt/production/data/

# 配置文件备份
tar -czf config-backup.tar.gz /opt/production/config/
```

### **恢复策略**
```bash
# 数据库恢复
mysql -h rds-host -u user -p database < backup.sql

# 应用数据恢复
tar -xzf app-data-backup.tar.gz -C /opt/production/

# 配置文件恢复
tar -xzf config-backup.tar.gz -C /opt/production/
```

---

## ✅ 部署检查清单

### **部署前检查**
- [ ] 阿里云资源已创建
- [ ] 服务器环境已配置
- [ ] 数据库已创建
- [ ] 域名已解析
- [ ] SSL证书已配置

### **部署后检查**
- [ ] 所有服务健康检查通过
- [ ] 数据库连接正常
- [ ] 监控系统正常
- [ ] 备份策略已配置
- [ ] 安全配置已生效

### **功能验证**
- [ ] 用户认证功能正常
- [ ] 简历管理功能正常
- [ ] 公司管理功能正常
- [ ] AI服务功能正常
- [ ] 监控告警正常

---

## 🎯 总结

**阿里云生产环境部署指南已完成！**

1. **资源配置**: ECS、RDS、SLB配置完成
2. **服务架构**: 多版本Zervigo服务架构设计完成
3. **监控系统**: Prometheus + Grafana监控配置完成
4. **安全配置**: SSL证书、防火墙、数据库安全配置完成
5. **部署脚本**: 自动化部署脚本和验证脚本完成

**下一步**: 可以开始实际部署到阿里云生产环境！ 🚀
