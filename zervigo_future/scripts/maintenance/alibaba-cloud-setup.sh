#!/bin/bash

# 阿里云ECS环境初始化脚本
set -e

# 配置变量
DEPLOY_PATH="/opt/jobfirst"
LOG_FILE="/var/log/jobfirst-setup.log"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a $LOG_FILE
}

log_success() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] ✅ $1${NC}" | tee -a $LOG_FILE
}

log_warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] ⚠️  $1${NC}" | tee -a $LOG_FILE
}

log_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ❌ $1${NC}" | tee -a $LOG_FILE
}

# 更新系统
update_system() {
    log "更新系统包..."
    dnf update -y
    log_success "系统更新完成"
}

# 安装基础工具
install_basic_tools() {
    log "安装基础工具..."
    dnf install -y curl wget vim git htop tree unzip
    log_success "基础工具安装完成"
}

# 配置防火墙
configure_firewall() {
    log "配置防火墙..."
    
    # 安装firewalld
    dnf install -y firewalld
    systemctl enable firewalld
    systemctl start firewalld
    
    # 开放必要端口
    firewall-cmd --permanent --add-port=22/tcp    # SSH
    firewall-cmd --permanent --add-port=80/tcp    # HTTP
    firewall-cmd --permanent --add-port=443/tcp   # HTTPS
    firewall-cmd --permanent --add-port=8080/tcp  # JobFirst API
    firewall-cmd --permanent --add-port=8000/tcp  # AI Service
    firewall-cmd --permanent --add-port=3306/tcp  # MySQL
    firewall-cmd --permanent --add-port=6379/tcp  # Redis
    firewall-cmd --permanent --add-port=5432/tcp  # PostgreSQL
    
    # 重新加载防火墙规则
    firewall-cmd --reload
    
    log_success "防火墙配置完成"
}

# 优化系统参数
optimize_system() {
    log "优化系统参数..."
    
    # 内核参数优化
    cat >> /etc/sysctl.conf << 'EOF'
# JobFirst系统优化
net.core.somaxconn = 65535
net.core.netdev_max_backlog = 5000
net.ipv4.tcp_max_syn_backlog = 65535
net.ipv4.tcp_fin_timeout = 10
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.tcp_max_tw_buckets = 5000
vm.swappiness = 10
vm.max_map_count = 262144
EOF
    
    # 应用内核参数
    sysctl -p
    
    log_success "系统参数优化完成"
}

# 配置Docker
configure_docker() {
    log "配置Docker..."
    
    # 检查Docker是否已安装
    if ! command -v docker &> /dev/null; then
        log_error "Docker未安装，请先安装Docker"
        exit 1
    fi
    
    # 优化Docker配置
    mkdir -p /etc/docker
    cat > /etc/docker/daemon.json << 'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ],
  "live-restore": true,
  "userland-proxy": false,
  "experimental": false,
  "metrics-addr": "0.0.0.0:9323",
  "default-address-pools": [
    {
      "base": "172.17.0.0/12",
      "size": 24
    }
  ]
}
EOF
    
    # 重启Docker服务
    systemctl restart docker
    
    log_success "Docker配置完成"
}

# 创建部署用户
create_deploy_user() {
    log "创建部署用户..."
    
    # 创建jobfirst用户
    if ! id "jobfirst" &>/dev/null; then
        useradd -m -s /bin/bash jobfirst
        usermod -aG docker jobfirst
        log_success "用户jobfirst创建完成"
    else
        log_warning "用户jobfirst已存在"
    fi
    
    # 配置sudo权限
    cat > /etc/sudoers.d/jobfirst << 'EOF'
jobfirst ALL=(ALL) NOPASSWD: /bin/systemctl restart basic-server
jobfirst ALL=(ALL) NOPASSWD: /bin/systemctl start basic-server
jobfirst ALL=(ALL) NOPASSWD: /bin/systemctl stop basic-server
jobfirst ALL=(ALL) NOPASSWD: /bin/systemctl status basic-server
jobfirst ALL=(ALL) NOPASSWD: /usr/bin/docker-compose
jobfirst ALL=(ALL) NOPASSWD: /usr/local/bin/docker-compose
EOF
    
    log_success "部署用户配置完成"
}

# 创建部署目录
create_deploy_directories() {
    log "创建部署目录..."
    
    mkdir -p $DEPLOY_PATH/{logs,uploads,temp,backup}
    mkdir -p $DEPLOY_PATH/nginx/{conf.d,ssl}
    mkdir -p $DEPLOY_PATH/database/{mysql/conf.d,postgresql,redis}
    
    # 设置权限
    chown -R jobfirst:jobfirst $DEPLOY_PATH
    chmod 755 $DEPLOY_PATH
    
    log_success "部署目录创建完成"
}

# 配置日志轮转
configure_log_rotation() {
    log "配置日志轮转..."
    
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
    
    log_success "日志轮转配置完成"
}

# 配置监控脚本
configure_monitoring() {
    log "配置监控脚本..."
    
    cat > $DEPLOY_PATH/monitor.sh << 'EOF'
#!/bin/bash

# JobFirst系统监控脚本
echo "=== JobFirst系统监控报告 ==="
echo "时间: $(date)"
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

echo "=== Docker服务状态 ==="
cd /opt/jobfirst
docker-compose ps
echo ""

echo "=== 服务日志 ==="
docker-compose logs --tail=10
echo ""

echo "=== 网络连接 ==="
netstat -tlnp | grep -E ":(80|443|8080|8000|3306|6379|5432)"
echo ""

echo "=== Docker资源使用 ==="
docker system df
echo ""

echo "=== 容器资源使用 ==="
docker stats --no-stream
EOF
    
    chmod +x $DEPLOY_PATH/monitor.sh
    chown jobfirst:jobfirst $DEPLOY_PATH/monitor.sh
    
    log_success "监控脚本配置完成"
}

# 配置定时任务
configure_cron() {
    log "配置定时任务..."
    
    # 创建定时任务
    cat > /etc/cron.d/jobfirst << 'EOF'
# JobFirst定时任务
# 每天凌晨2点执行系统监控
0 2 * * * root /opt/jobfirst/monitor.sh >> /var/log/jobfirst-monitor.log 2>&1

# 每周日凌晨3点清理Docker资源
0 3 * * 0 root docker system prune -f >> /var/log/jobfirst-cleanup.log 2>&1

# 每天凌晨4点备份数据库
0 4 * * * jobfirst cd /opt/jobfirst && docker-compose exec -T mysql mysqldump -u root -pjobfirst_password_2024 jobfirst > backup/mysql_backup_$(date +\%Y\%m\%d).sql
EOF
    
    log_success "定时任务配置完成"
}

# 配置系统服务
configure_systemd_services() {
    log "配置系统服务..."
    
    # 创建JobFirst服务文件
    cat > /etc/systemd/system/jobfirst.service << 'EOF'
[Unit]
Description=JobFirst Application
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/jobfirst
ExecStart=/usr/bin/docker-compose up -d
ExecStop=/usr/bin/docker-compose down
TimeoutStartSec=0
User=jobfirst
Group=jobfirst

[Install]
WantedBy=multi-user.target
EOF
    
    # 重新加载systemd
    systemctl daemon-reload
    systemctl enable jobfirst.service
    
    log_success "系统服务配置完成"
}

# 主函数
main() {
    log "开始阿里云ECS环境初始化..."
    
    update_system
    install_basic_tools
    configure_firewall
    optimize_system
    configure_docker
    create_deploy_user
    create_deploy_directories
    configure_log_rotation
    configure_monitoring
    configure_cron
    configure_systemd_services
    
    log_success "🎉 阿里云ECS环境初始化完成！"
    
    echo ""
    echo "=== 环境信息 ==="
    echo "部署路径: $DEPLOY_PATH"
    echo "部署用户: jobfirst"
    echo "Docker版本: $(docker --version)"
    echo "Docker Compose版本: $(docker-compose --version)"
    echo "系统版本: $(cat /etc/os-release | grep PRETTY_NAME)"
    echo ""
    echo "=== 下一步操作 ==="
    echo "1. 上传部署文件到 $DEPLOY_PATH"
    echo "2. 执行部署脚本: cd $DEPLOY_PATH && ./scripts/deploy.sh"
    echo "3. 检查服务状态: systemctl status jobfirst"
    echo "4. 查看服务日志: docker-compose logs -f"
    echo ""
}

# 执行主函数
main "$@"
