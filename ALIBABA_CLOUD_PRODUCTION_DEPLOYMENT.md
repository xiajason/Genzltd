# 阿里云生产环境部署配置

**创建时间**: 2025年1月27日  
**版本**: v1.0  
**状态**: ✅ **配置完成**  
**目标**: 阿里云生产环境部署配置

---

## 🏗️ 阿里云资源配置

### **ECS实例配置**
```yaml
实例规格: ecs.c6.large
CPU: 2核
内存: 4GB
操作系统: Ubuntu 20.04 LTS
网络: 专有网络VPC
安全组: 开放22, 80, 443, 8080端口
存储: 40GB ESSD Entry云盘
```

### **RDS数据库配置**
```yaml
数据库类型: MySQL 8.0
规格: rds.mysql.s2.large
CPU: 1核
内存: 2GB
存储: 20GB SSD
网络: 与ECS同VPC
备份: 自动备份7天
```

### **SLB负载均衡配置**
```yaml
类型: 应用型负载均衡ALB
规格: 标准版
监听端口: 80, 443
后端服务器: ECS实例
健康检查: HTTP检查
```

---

## 🚀 部署架构

### **服务端口分配**
```yaml
LoomaCRM服务:
  8800: looma-crm-main
  8801: service-registry
  8802: service-config
  8803: service-monitor

Zervigo Future版:
  8200: api-gateway
  8201: user-service
  8202: resume-service
  8203: company-service

Zervigo DAO版:
  9200: dao-resume-service
  9201: dao-job-service
  9202: dao-governance-service

Zervigo 区块链版:
  8300: blockchain-node-service
  8301: smart-contract-service
  8302: wallet-service
  8303: cross-chain-service
```

### **监控系统配置**
```yaml
Prometheus: 端口9090
Grafana: 端口3000
Node Exporter: 端口9100
Alertmanager: 端口9093
```

---

## 📋 部署步骤

### **第一步：创建阿里云资源**
1. 创建ECS实例
2. 创建RDS数据库
3. 创建SLB负载均衡
4. 配置安全组和网络

### **第二步：配置服务器环境**
1. 安装Docker和Docker Compose
2. 配置Nginx反向代理
3. 设置SSL证书
4. 配置防火墙

### **第三步：部署应用服务**
1. 部署LoomaCRM服务
2. 部署Zervigo各版本服务
3. 配置数据库连接
4. 设置服务发现

### **第四步：配置监控系统**
1. 部署Prometheus
2. 部署Grafana
3. 配置告警规则
4. 设置监控面板

### **第五步：验证部署**
1. 健康检查
2. 功能测试
3. 性能测试
4. 安全测试

---

## 🔧 配置文件

### **Docker Compose配置**
```yaml
version: '3.8'
services:
  looma-crm:
    image: loomacrm-production:latest
    ports:
      - "8800:8800"
    environment:
      - DATABASE_URL=mysql://user:pass@rds-host:3306/loomacrm
    depends_on:
      - mysql
      - redis

  zervigo-future:
    image: zervigo-future-production:latest
    ports:
      - "8200:8200"
    environment:
      - API_GATEWAY_URL=http://localhost:8200
    depends_on:
      - looma-crm

  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
```

### **Nginx配置**
```nginx
upstream looma_crm {
    server localhost:8800;
}

upstream zervigo_future {
    server localhost:8200;
}

server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://looma_crm;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location /api/future/ {
        proxy_pass http://zervigo_future;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

---

## 🎯 部署验证

### **健康检查端点**
```bash
# LoomaCRM主服务
curl http://your-domain.com/health

# Zervigo Future版
curl http://your-domain.com/api/future/health

# 监控系统
curl http://your-domain.com:9090/api/v1/query?query=up
curl http://your-domain.com:3000/api/health
```

### **功能测试**
```bash
# 用户认证测试
curl -X POST http://your-domain.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"test","password":"test"}'

# 简历管理测试
curl http://your-domain.com/api/resumes

# 公司管理测试
curl http://your-domain.com/api/companies
```

---

## 🔒 安全配置

### **SSL证书配置**
```bash
# 使用Let's Encrypt免费SSL证书
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d your-domain.com
```

### **防火墙配置**
```bash
# 开放必要端口
sudo ufw allow 22    # SSH
sudo ufw allow 80    # HTTP
sudo ufw allow 443   # HTTPS
sudo ufw allow 9090 # Prometheus
sudo ufw allow 3000 # Grafana
sudo ufw enable
```

### **数据库安全**
```bash
# 配置数据库访问控制
# 只允许ECS实例访问RDS
# 启用SSL连接
# 定期备份数据
```

---

## 📊 监控配置

### **Prometheus配置**
```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'looma-crm'
    static_configs:
      - targets: ['localhost:8800']
  
  - job_name: 'zervigo-future'
    static_configs:
      - targets: ['localhost:8200']
  
  - job_name: 'node-exporter'
    static_configs:
      - targets: ['localhost:9100']
```

### **Grafana仪表板**
```yaml
数据源: Prometheus
仪表板: 
  - 系统监控
  - 应用监控
  - 数据库监控
  - 业务指标监控
```

---

## 🚀 部署脚本

### **自动部署脚本**
```bash
#!/bin/bash
# deploy-alibaba-production.sh

echo "🚀 开始部署阿里云生产环境"

# 1. 检查环境
echo "📋 检查部署环境..."
docker --version
docker-compose --version

# 2. 停止旧服务
echo "🛑 停止旧服务..."
docker-compose down

# 3. 拉取最新镜像
echo "⬇️ 拉取最新镜像..."
docker-compose pull

# 4. 启动服务
echo "🚀 启动服务..."
docker-compose up -d

# 5. 等待服务启动
echo "⏳ 等待服务启动..."
sleep 30

# 6. 健康检查
echo "🔍 健康检查..."
curl -f http://localhost:8800/health || exit 1
curl -f http://localhost:8200/health || exit 1

echo "✅ 阿里云生产环境部署完成！"
```

---

## 📈 性能优化

### **资源优化**
```yaml
ECS实例:
  CPU: 2核 (可扩展到4核)
  内存: 4GB (可扩展到8GB)
  存储: 40GB (可扩展到100GB)

RDS数据库:
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

**阿里云生产环境部署配置已完成！**

1. **资源配置**: ECS、RDS、SLB配置完成
2. **服务架构**: 多版本Zervigo服务架构设计完成
3. **监控系统**: Prometheus + Grafana监控配置完成
4. **安全配置**: SSL证书、防火墙、数据库安全配置完成
5. **部署脚本**: 自动化部署脚本和验证脚本完成

**下一步**: 可以开始实际部署到阿里云生产环境！ 🚀