#!/bin/bash
# 腾讯云测试环境完整部署脚本

echo "🚀 腾讯云测试环境部署脚本"
echo "=========================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 服务器信息
TENCENT_IP="101.33.251.158"
TENCENT_USER="ubuntu"
SSH_KEY="~/.ssh/basic.pem"

echo -e "${BLUE}目标服务器: $TENCENT_USER@$TENCENT_IP${NC}"
echo -e "${BLUE}SSH密钥: $SSH_KEY${NC}"
echo ""

# 检查SSH连接
check_ssh_connection() {
    echo -e "${BLUE}检查SSH连接...${NC}"
    if ssh -i $SSH_KEY -o ConnectTimeout=10 $TENCENT_USER@$TENCENT_IP "echo 'SSH连接成功'" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ SSH连接正常${NC}"
        return 0
    else
        echo -e "${RED}❌ SSH连接失败${NC}"
        return 1
    fi
}

# 更新系统
update_system() {
    echo -e "${BLUE}更新系统...${NC}"
    ssh -i $SSH_KEY $TENCENT_USER@$TENCENT_IP "
        sudo apt update && sudo apt upgrade -y
        echo '系统更新完成'
    "
}

# 安装基础软件
install_basic_software() {
    echo -e "${BLUE}安装基础软件...${NC}"
    ssh -i $SSH_KEY $TENCENT_USER@$TENCENT_IP "
        sudo apt install -y curl wget git vim htop tree unzip
        echo '基础软件安装完成'
    "
}

# 安装Docker
install_docker() {
    echo -e "${BLUE}安装Docker...${NC}"
    ssh -i $SSH_KEY $TENCENT_USER@$TENCENT_IP "
        # 移除旧版本Docker
        sudo apt remove -y docker docker-engine docker.io containerd runc
        
        # 安装Docker
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        
        # 添加用户到docker组
        sudo usermod -aG docker $TENCENT_USER
        
        # 启动Docker服务
        sudo systemctl start docker
        sudo systemctl enable docker
        
        # 安装Docker Compose
        sudo curl -L \"https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-\$(uname -s)-\$(uname -m)\" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        
        # 验证安装
        docker --version
        docker-compose --version
        
        echo 'Docker安装完成'
    "
}

# 配置Docker镜像源
configure_docker_registry() {
    echo -e "${BLUE}配置Docker镜像源...${NC}"
    ssh -i $SSH_KEY $TENCENT_USER@$TENCENT_IP "
        sudo mkdir -p /etc/docker
        sudo tee /etc/docker/daemon.json << 'EOF'
{
  \"registry-mirrors\": [
    \"https://docker.mirrors.ustc.edu.cn\",
    \"https://hub-mirror.c.163.com\",
    \"https://mirror.baidubce.com\"
  ],
  \"log-driver\": \"json-file\",
  \"log-opts\": {
    \"max-size\": \"10m\",
    \"max-file\": \"3\"
  }
}
EOF
        sudo systemctl restart docker
        echo 'Docker镜像源配置完成'
    "
}

# 安装MySQL
install_mysql() {
    echo -e "${BLUE}安装MySQL...${NC}"
    ssh -i $SSH_KEY $TENCENT_USER@$TENCENT_IP "
        sudo apt install -y mysql-server mysql-client
        
        # 启动MySQL服务
        sudo systemctl start mysql
        sudo systemctl enable mysql
        
        # 安全配置
        sudo mysql -e \"ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'root123456';\"
        sudo mysql -e \"CREATE USER 'testuser'@'%' IDENTIFIED BY 'testpass123';\"
        sudo mysql -e \"GRANT ALL PRIVILEGES ON *.* TO 'testuser'@'%';\"
        sudo mysql -e \"FLUSH PRIVILEGES;\"
        
        echo 'MySQL安装完成'
    "
}

# 安装PostgreSQL
install_postgresql() {
    echo -e "${BLUE}安装PostgreSQL...${NC}"
    ssh -i $SSH_KEY $TENCENT_USER@$TENCENT_IP "
        sudo apt install -y postgresql postgresql-contrib
        
        # 启动PostgreSQL服务
        sudo systemctl start postgresql
        sudo systemctl enable postgresql
        
        # 创建测试用户和数据库
        sudo -u postgres psql -c \"CREATE USER testuser WITH PASSWORD 'testpass123';\"
        sudo -u postgres psql -c \"CREATE DATABASE testdb OWNER testuser;\"
        sudo -u postgres psql -c \"GRANT ALL PRIVILEGES ON DATABASE testdb TO testuser;\"
        
        echo 'PostgreSQL安装完成'
    "
}

# 安装Redis
install_redis() {
    echo -e "${BLUE}安装Redis...${NC}"
    ssh -i $SSH_KEY $TENCENT_USER@$TENCENT_IP "
        sudo apt install -y redis-server
        
        # 配置Redis
        sudo sed -i 's/supervised no/supervised systemd/' /etc/redis/redis.conf
        sudo sed -i 's/# requirepass foobared/requirepass redis123456/' /etc/redis/redis.conf
        
        # 启动Redis服务
        sudo systemctl start redis-server
        sudo systemctl enable redis-server
        
        echo 'Redis安装完成'
    "
}

# 安装Nginx
install_nginx() {
    echo -e "${BLUE}安装Nginx...${NC}"
    ssh -i $SSH_KEY $TENCENT_USER@$TENCENT_IP "
        sudo apt install -y nginx
        
        # 启动Nginx服务
        sudo systemctl start nginx
        sudo systemctl enable nginx
        
        # 配置防火墙
        sudo ufw allow 'Nginx Full'
        sudo ufw allow 22
        sudo ufw --force enable
        
        echo 'Nginx安装完成'
    "
}

# 配置防火墙
configure_firewall() {
    echo -e "${BLUE}配置防火墙...${NC}"
    ssh -i $SSH_KEY $TENCENT_USER@$TENCENT_IP "
        sudo ufw allow 22
        sudo ufw allow 80
        sudo ufw allow 443
        sudo ufw allow 3306
        sudo ufw allow 5432
        sudo ufw allow 6379
        sudo ufw allow 9200:9299
        sudo ufw allow 8300:8599
        sudo ufw --force enable
        
        echo '防火墙配置完成'
    "
}

# 创建部署目录
create_deployment_directories() {
    echo -e "${BLUE}创建部署目录...${NC}"
    ssh -i $SSH_KEY $TENCENT_USER@$TENCENT_IP "
        mkdir -p /home/ubuntu/dao-services
        mkdir -p /home/ubuntu/blockchain-services
        mkdir -p /home/ubuntu/logs
        mkdir -p /home/ubuntu/backups
        
        echo '部署目录创建完成'
    "
}

# 验证服务状态
verify_services() {
    echo -e "${BLUE}验证服务状态...${NC}"
    ssh -i $SSH_KEY $TENCENT_USER@$TENCENT_IP "
        echo '=== 系统信息 ==='
        uname -a
        uptime
        
        echo '=== 服务状态 ==='
        systemctl status docker --no-pager
        systemctl status mysql --no-pager
        systemctl status postgresql --no-pager
        systemctl status redis-server --no-pager
        systemctl status nginx --no-pager
        
        echo '=== 端口监听 ==='
        netstat -tlnp | grep -E ':(22|80|3306|5432|6379)'
        
        echo '=== 磁盘使用 ==='
        df -h
        
        echo '=== 内存使用 ==='
        free -h
    "
}

# 主函数
main() {
    echo -e "${BLUE}开始部署腾讯云测试环境...${NC}"
    
    # 检查SSH连接
    if ! check_ssh_connection; then
        echo -e "${RED}SSH连接失败，请检查网络和密钥配置${NC}"
        exit 1
    fi
    
    # 更新系统
    update_system
    
    # 安装基础软件
    install_basic_software
    
    # 安装Docker
    install_docker
    
    # 配置Docker镜像源
    configure_docker_registry
    
    # 安装数据库服务
    install_mysql
    install_postgresql
    install_redis
    
    # 安装Web服务
    install_nginx
    
    # 配置防火墙
    configure_firewall
    
    # 创建部署目录
    create_deployment_directories
    
    # 验证服务状态
    verify_services
    
    echo ""
    echo -e "${GREEN}🎉 腾讯云测试环境部署完成！${NC}"
    echo "=========================="
    echo -e "${BLUE}服务器信息：${NC}"
    echo "  IP地址: $TENCENT_IP"
    echo "  用户: $TENCENT_USER"
    echo "  SSH密钥: $SSH_KEY"
    echo ""
    echo -e "${BLUE}已安装服务：${NC}"
    echo "  ✅ Docker + Docker Compose"
    echo "  ✅ MySQL (端口3306)"
    echo "  ✅ PostgreSQL (端口5432)"
    echo "  ✅ Redis (端口6379)"
    echo "  ✅ Nginx (端口80/443)"
    echo ""
    echo -e "${BLUE}部署目录：${NC}"
    echo "  📁 /home/ubuntu/dao-services"
    echo "  📁 /home/ubuntu/blockchain-services"
    echo "  📁 /home/ubuntu/logs"
    echo "  📁 /home/ubuntu/backups"
    echo ""
    echo -e "${YELLOW}下一步：可以开始部署DAO版和区块链版服务${NC}"
}

# 运行主函数
main "$@"
