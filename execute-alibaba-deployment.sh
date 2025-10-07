#!/bin/bash

# 阿里云生产环境部署执行脚本

echo "🚀 开始阿里云生产环境部署"
echo "=========================="

# 检查部署环境
echo "📋 检查部署环境..."
echo "当前目录: $(pwd)"
echo "当前用户: $(whoami)"
echo "系统信息: $(uname -a)"

# 检查Docker环境
echo "🔍 检查Docker环境..."
if command -v docker &> /dev/null; then
    echo "✅ Docker已安装: $(docker --version)"
else
    echo "❌ Docker未安装，请先安装Docker"
    exit 1
fi

if command -v docker-compose &> /dev/null; then
    echo "✅ Docker Compose已安装: $(docker-compose --version)"
else
    echo "❌ Docker Compose未安装，请先安装Docker Compose"
    exit 1
fi

# 创建生产环境目录结构
echo "📁 创建生产环境目录结构..."
mkdir -p production/{monitoring,config,data,logs,scripts,backup}
cd production

echo "✅ 生产环境目录结构创建完成"
echo "目录结构:"
tree -L 2 . || ls -la

# 创建Docker Compose配置文件
echo "📝 创建Docker Compose配置文件..."
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

echo "✅ Docker Compose配置文件创建完成"

# 创建Prometheus配置文件
echo "📝 创建Prometheus配置文件..."
mkdir -p monitoring

cat > monitoring/prometheus.yml << 'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

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

echo "✅ Prometheus配置文件创建完成"

# 创建告警规则文件
echo "📝 创建告警规则文件..."
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

echo "✅ 告警规则文件创建完成"

# 创建备份脚本
echo "📝 创建备份脚本..."
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
echo "✅ 备份脚本创建完成"

# 创建健康检查脚本
echo "📝 创建健康检查脚本..."
cat > scripts/health-check.sh << 'EOF'
#!/bin/bash

# 健康检查脚本
echo "🔍 开始健康检查..."

# 检查Docker容器状态
echo "📦 检查Docker容器状态..."
docker-compose ps

# 检查服务健康状态
echo "🏥 检查服务健康状态..."
curl -f http://localhost:8800/health && echo "✅ LoomaCRM健康" || echo "❌ LoomaCRM不健康"
curl -f http://localhost:8200/health && echo "✅ Zervigo Future健康" || echo "❌ Zervigo Future不健康"
curl -f http://localhost:9200/health && echo "✅ Zervigo DAO健康" || echo "❌ Zervigo DAO不健康"
curl -f http://localhost:8300/health && echo "✅ Zervigo 区块链健康" || echo "❌ Zervigo 区块链不健康"

# 检查监控服务
echo "📊 检查监控服务..."
curl -f http://localhost:9090/api/v1/query?query=up && echo "✅ Prometheus健康" || echo "❌ Prometheus不健康"
curl -f http://localhost:3000/api/health && echo "✅ Grafana健康" || echo "❌ Grafana不健康"

echo "🎉 健康检查完成！"
EOF

chmod +x scripts/health-check.sh
echo "✅ 健康检查脚本创建完成"

# 模拟部署过程（由于没有实际的阿里云服务器，我们模拟部署过程）
echo "🚀 开始模拟部署过程..."

# 检查配置文件
echo "📋 检查配置文件..."
if [ -f "docker-compose.yml" ]; then
    echo "✅ docker-compose.yml 存在"
else
    echo "❌ docker-compose.yml 不存在"
    exit 1
fi

if [ -f "monitoring/prometheus.yml" ]; then
    echo "✅ prometheus.yml 存在"
else
    echo "❌ prometheus.yml 不存在"
    exit 1
fi

# 模拟Docker Compose配置验证
echo "🔍 验证Docker Compose配置..."
docker-compose config > /dev/null
if [ $? -eq 0 ]; then
    echo "✅ Docker Compose配置验证通过"
else
    echo "❌ Docker Compose配置验证失败"
    exit 1
fi

# 模拟服务启动（由于没有实际的镜像，我们只显示启动命令）
echo "🚀 模拟启动服务..."
echo "执行命令: docker-compose up -d"
echo "注意: 由于没有实际的Docker镜像，此步骤需要在实际的阿里云服务器上执行"

# 模拟健康检查
echo "🔍 模拟健康检查..."
echo "执行命令: ./scripts/health-check.sh"
echo "注意: 此步骤需要在实际的阿里云服务器上执行"

# 显示部署完成信息
echo "🎉 阿里云生产环境部署配置完成！"
echo "================================"
echo "📋 部署配置总结:"
echo "  - Docker Compose配置: ✅ 完成"
echo "  - Prometheus配置: ✅ 完成"
echo "  - 告警规则配置: ✅ 完成"
echo "  - 备份脚本: ✅ 完成"
echo "  - 健康检查脚本: ✅ 完成"
echo ""
echo "🚀 下一步操作:"
echo "  1. 将配置上传到阿里云服务器"
echo "  2. 在阿里云服务器上执行: docker-compose up -d"
echo "  3. 执行健康检查: ./scripts/health-check.sh"
echo "  4. 配置Nginx反向代理"
echo "  5. 配置SSL证书"
echo ""
echo "📁 配置文件位置:"
echo "  - 主配置: $(pwd)/docker-compose.yml"
echo "  - 监控配置: $(pwd)/monitoring/"
echo "  - 脚本文件: $(pwd)/scripts/"
echo ""
echo "🎯 部署完成！准备上传到阿里云服务器！"
