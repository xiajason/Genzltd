#!/bin/bash

# 区块链微服务在DAO版三环境中的部署脚本
# 支持本地开发、腾讯云集成、阿里云生产三环境部署

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 区块链微服务DAO版三环境部署${NC}"
echo -e "${CYAN}支持本地开发、腾讯云集成、阿里云生产环境${NC}"

# 环境配置
LOCAL_ENV="local"
TENCENT_ENV="tencent"
ALIBABA_ENV="alibaba"

# 本地开发环境配置
LOCAL_CONFIG="
# 本地开发环境 - 轻量级区块链服务
BLOCKCHAIN_SERVICE_PORT=8301
IDENTITY_SERVICE_PORT=8302
GOVERNANCE_SERVICE_PORT=8303
CROSSCHAIN_SERVICE_PORT=8304
BLOCKCHAIN_MYSQL_PORT=9506
BLOCKCHAIN_REDIS_PORT=9507
BLOCKCHAIN_MODE=development
BLOCKCHAIN_CHAIN=simulation
"

# 腾讯云集成环境配置
TENCENT_CONFIG="
# 腾讯云集成环境 - 完整区块链服务测试
BLOCKCHAIN_SERVICE_PORT=8401
IDENTITY_SERVICE_PORT=8402
GOVERNANCE_SERVICE_PORT=8403
CROSSCHAIN_SERVICE_PORT=8404
BLOCKCHAIN_GATEWAY_PORT=8405
BLOCKCHAIN_MONITOR_PORT=8406
BLOCKCHAIN_CONFIG_PORT=8407
BLOCKCHAIN_MYSQL_PORT=3306
BLOCKCHAIN_REDIS_PORT=6379
BLOCKCHAIN_POSTGRES_PORT=5432
BLOCKCHAIN_MODE=integration
BLOCKCHAIN_CHAIN=huawei,ethereum
TENCENT_SERVER=101.33.251.158
"

# 阿里云生产环境配置
ALIBABA_CONFIG="
# 阿里云生产环境 - 生产级区块链服务
BLOCKCHAIN_SERVICE_PORT=8501
IDENTITY_SERVICE_PORT=8502
GOVERNANCE_SERVICE_PORT=8503
CROSSCHAIN_SERVICE_PORT=8504
BLOCKCHAIN_STORAGE_PORT=8505
BLOCKCHAIN_CACHE_PORT=8506
BLOCKCHAIN_SECURITY_PORT=8507
BLOCKCHAIN_AUDIT_PORT=8508
BLOCKCHAIN_MYSQL_PORT=9507
BLOCKCHAIN_REDIS_PORT=6379
BLOCKCHAIN_POSTGRES_PORT=5432
BLOCKCHAIN_MODE=production
BLOCKCHAIN_CHAIN=huawei
ALIBABA_SERVER=47.115.168.107
"

# 显示环境选择菜单
show_menu() {
    echo -e "${BLUE}请选择部署环境:${NC}"
    echo -e "${GREEN}1. 本地开发环境 (MacBook Pro M3)${NC}"
    echo -e "   - 轻量级区块链服务开发"
    echo -e "   - 端口: 8300-8399"
    echo -e "   - 成本: 0元/月"
    echo ""
    echo -e "${YELLOW}2. 腾讯云集成环境 (4核8GB 100GB SSD)${NC}"
    echo -e "   - 完整区块链服务测试"
    echo -e "   - 端口: 8400-8499"
    echo -e "   - 成本: 约50元/月"
    echo ""
    echo -e "${PURPLE}3. 阿里云生产环境 (2核1.8GB 40GB SSD)${NC}"
    echo -e "   - 生产级区块链服务"
    echo -e "   - 端口: 8500-8599"
    echo -e "   - 成本: 约100元/月"
    echo ""
    echo -e "${CYAN}4. 三环境同时部署${NC}"
    echo -e "   - 完整三环境部署"
    echo -e "   - 总成本: 约150元/月"
    echo ""
    echo -e "${RED}5. 退出${NC}"
}

# 部署本地开发环境
deploy_local() {
    echo -e "${BLUE}[INFO] 部署本地开发环境...${NC}"
    
    # 检查本地环境
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}[ERROR] Docker未安装，请先安装Docker Desktop${NC}"
        return 1
    fi
    
    # 创建本地区块链服务配置
    cat > blockchain-local.env << EOF
# 本地开发环境配置
BLOCKCHAIN_SERVICE_PORT=8301
IDENTITY_SERVICE_PORT=8302
GOVERNANCE_SERVICE_PORT=8303
CROSSCHAIN_SERVICE_PORT=8304
BLOCKCHAIN_MYSQL_PORT=9506
BLOCKCHAIN_REDIS_PORT=9507
BLOCKCHAIN_MODE=development
BLOCKCHAIN_CHAIN=simulation
EOF
    
    # 创建本地Docker Compose配置
    cat > docker-compose-blockchain-local.yml << EOF
version: '3.8'
services:
  blockchain-mysql:
    image: mysql:8.0
    container_name: blockchain-mysql-local
    ports:
      - "9506:3306"
    environment:
      MYSQL_ROOT_PASSWORD: blockchain_password_2024
      MYSQL_DATABASE: blockchain_governance
      MYSQL_USER: blockchain_user
      MYSQL_PASSWORD: blockchain_user_password
    volumes:
      - blockchain_mysql_data:/var/lib/mysql
    networks:
      - blockchain-network

  blockchain-redis:
    image: redis:7-alpine
    container_name: blockchain-redis-local
    ports:
      - "9507:6379"
    volumes:
      - blockchain_redis_data:/data
    networks:
      - blockchain-network

  blockchain-service:
    build: ./blockchain-service
    container_name: blockchain-service-local
    ports:
      - "8301:8301"
    environment:
      - BLOCKCHAIN_MODE=development
      - BLOCKCHAIN_CHAIN=simulation
      - MYSQL_HOST=blockchain-mysql
      - MYSQL_PORT=3306
      - REDIS_HOST=blockchain-redis
      - REDIS_PORT=6379
    depends_on:
      - blockchain-mysql
      - blockchain-redis
    networks:
      - blockchain-network

volumes:
  blockchain_mysql_data:
  blockchain_redis_data:

networks:
  blockchain-network:
    driver: bridge
EOF
    
    echo -e "${GREEN}[SUCCESS] 本地开发环境配置完成${NC}"
    echo -e "${CYAN}启动命令: docker-compose -f docker-compose-blockchain-local.yml up -d${NC}"
}

# 部署腾讯云集成环境
deploy_tencent() {
    echo -e "${BLUE}[INFO] 部署腾讯云集成环境...${NC}"
    
    # 检查腾讯云连接
    if ! ping -c 1 101.33.251.158 &> /dev/null; then
        echo -e "${RED}[ERROR] 无法连接到腾讯云服务器${NC}"
        return 1
    fi
    
    # 创建腾讯云部署脚本
    cat > deploy-blockchain-tencent.sh << 'EOF'
#!/bin/bash

# 腾讯云区块链服务部署脚本
echo "🚀 部署腾讯云区块链服务..."

# 更新系统
sudo apt update && sudo apt upgrade -y

# 安装Docker (如果未安装)
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
fi

# 创建区块链服务目录
sudo mkdir -p /opt/blockchain-services
sudo chown $USER:$USER /opt/blockchain-services
cd /opt/blockchain-services

# 创建区块链服务配置
cat > blockchain-tencent.env << 'ENV_EOF'
# 腾讯云集成环境配置
BLOCKCHAIN_SERVICE_PORT=8401
IDENTITY_SERVICE_PORT=8402
GOVERNANCE_SERVICE_PORT=8403
CROSSCHAIN_SERVICE_PORT=8404
BLOCKCHAIN_GATEWAY_PORT=8405
BLOCKCHAIN_MONITOR_PORT=8406
BLOCKCHAIN_CONFIG_PORT=8407
BLOCKCHAIN_MYSQL_PORT=3306
BLOCKCHAIN_REDIS_PORT=6379
BLOCKCHAIN_POSTGRES_PORT=5432
BLOCKCHAIN_MODE=integration
BLOCKCHAIN_CHAIN=huawei,ethereum
ENV_EOF

# 创建Docker Compose配置
cat > docker-compose-blockchain-tencent.yml << 'COMPOSE_EOF'
version: '3.8'
services:
  blockchain-gateway:
    image: nginx:alpine
    container_name: blockchain-gateway
    ports:
      - "8405:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
    networks:
      - blockchain-network

  blockchain-service:
    build: ./blockchain-service
    container_name: blockchain-service
    ports:
      - "8401:8401"
    environment:
      - BLOCKCHAIN_MODE=integration
      - BLOCKCHAIN_CHAIN=huawei,ethereum
    networks:
      - blockchain-network

  blockchain-monitor:
    image: prom/prometheus
    container_name: blockchain-monitor
    ports:
      - "8406:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
    networks:
      - blockchain-network

networks:
  blockchain-network:
    driver: bridge
COMPOSE_EOF

echo "✅ 腾讯云区块链服务配置完成"
echo "启动命令: docker-compose -f docker-compose-blockchain-tencent.yml up -d"
EOF
    
    chmod +x deploy-blockchain-tencent.sh
    
    echo -e "${GREEN}[SUCCESS] 腾讯云部署脚本创建完成${NC}"
    echo -e "${CYAN}执行命令: scp deploy-blockchain-tencent.sh root@101.33.251.158:/opt/ && ssh root@101.33.251.158 'cd /opt && ./deploy-blockchain-tencent.sh'${NC}"
}

# 部署阿里云生产环境
deploy_alibaba() {
    echo -e "${BLUE}[INFO] 部署阿里云生产环境...${NC}"
    
    # 检查阿里云连接
    if ! ping -c 1 47.115.168.107 &> /dev/null; then
        echo -e "${RED}[ERROR] 无法连接到阿里云服务器${NC}"
        return 1
    fi
    
    # 创建阿里云部署脚本
    cat > deploy-blockchain-alibaba.sh << 'EOF'
#!/bin/bash

# 阿里云区块链服务部署脚本
echo "🚀 部署阿里云区块链服务..."

# 检查现有服务
echo "检查现有服务状态..."
docker ps | grep -E "(redis|ai|consul|zervigo)"

# 创建区块链服务目录
mkdir -p /opt/blockchain-services
cd /opt/blockchain-services

# 创建区块链服务配置
cat > blockchain-alibaba.env << 'ENV_EOF'
# 阿里云生产环境配置
BLOCKCHAIN_SERVICE_PORT=8501
IDENTITY_SERVICE_PORT=8502
GOVERNANCE_SERVICE_PORT=8503
CROSSCHAIN_SERVICE_PORT=8504
BLOCKCHAIN_STORAGE_PORT=8505
BLOCKCHAIN_CACHE_PORT=8506
BLOCKCHAIN_SECURITY_PORT=8507
BLOCKCHAIN_AUDIT_PORT=8508
BLOCKCHAIN_MYSQL_PORT=9507
BLOCKCHAIN_REDIS_PORT=6379
BLOCKCHAIN_POSTGRES_PORT=5432
BLOCKCHAIN_MODE=production
BLOCKCHAIN_CHAIN=huawei
ENV_EOF

# 创建Docker Compose配置
cat > docker-compose-blockchain-alibaba.yml << 'COMPOSE_EOF'
version: '3.8'
services:
  blockchain-service:
    build: ./blockchain-service
    container_name: blockchain-service
    ports:
      - "8501:8501"
    environment:
      - BLOCKCHAIN_MODE=production
      - BLOCKCHAIN_CHAIN=huawei
      - MYSQL_HOST=mysql
      - MYSQL_PORT=9507
      - REDIS_HOST=redis
      - REDIS_PORT=6379
    depends_on:
      - mysql
      - redis
    networks:
      - blockchain-network

  blockchain-storage:
    image: mysql:8.0
    container_name: blockchain-storage
    ports:
      - "9507:3306"
    environment:
      MYSQL_ROOT_PASSWORD: blockchain_prod_password_2024
      MYSQL_DATABASE: blockchain_production
    volumes:
      - blockchain_storage_data:/var/lib/mysql
    networks:
      - blockchain-network

  blockchain-cache:
    image: redis:7-alpine
    container_name: blockchain-cache
    ports:
      - "8506:6379"
    volumes:
      - blockchain_cache_data:/data
    networks:
      - blockchain-network

volumes:
  blockchain_storage_data:
  blockchain_cache_data:

networks:
  blockchain-network:
    driver: bridge
COMPOSE_EOF

echo "✅ 阿里云区块链服务配置完成"
echo "启动命令: docker-compose -f docker-compose-blockchain-alibaba.yml up -d"
EOF
    
    chmod +x deploy-blockchain-alibaba.sh
    
    echo -e "${GREEN}[SUCCESS] 阿里云部署脚本创建完成${NC}"
    echo -e "${CYAN}执行命令: scp deploy-blockchain-alibaba.sh root@47.115.168.107:/opt/ && ssh root@47.115.168.107 'cd /opt && ./deploy-blockchain-alibaba.sh'${NC}"
}

# 部署三环境
deploy_all() {
    echo -e "${BLUE}[INFO] 部署三环境区块链服务...${NC}"
    
    deploy_local
    deploy_tencent
    deploy_alibaba
    
    echo -e "${GREEN}[SUCCESS] 三环境部署脚本创建完成${NC}"
    echo -e "${CYAN}总成本: 约150元/月${NC}"
    echo -e "${CYAN}本地: 0元/月 | 腾讯云: 50元/月 | 阿里云: 100元/月${NC}"
}

# 主菜单循环
while true; do
    show_menu
    read -p "请选择 (1-5): " choice
    
    case $choice in
        1)
            deploy_local
            break
            ;;
        2)
            deploy_tencent
            break
            ;;
        3)
            deploy_alibaba
            break
            ;;
        4)
            deploy_all
            break
            ;;
        5)
            echo -e "${RED}退出部署${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}无效选择，请重新输入${NC}"
            ;;
    esac
done

echo -e "${GREEN}🎉 区块链微服务部署配置完成！${NC}"
