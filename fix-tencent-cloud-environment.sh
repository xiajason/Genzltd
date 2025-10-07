#!/bin/bash

# 腾讯云环境修复脚本
# 基于之前的成功部署经验修复腾讯云环境

echo "🔧 腾讯云环境修复脚本 - $(date)"
echo "=================================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 腾讯云服务器配置
TENCENT_SERVER="101.33.251.158"
TENCENT_USER="ubuntu"
SSH_KEY="~/.ssh/basic.pem"

# 腾讯云服务配置（基于之前的成功部署）
TENCENT_SERVICES=(
    "9200:DAO版Web服务"
    "8300:区块链Web服务"
    "5433:DAO PostgreSQL数据库"
    "6380:DAO Redis缓存"
)

echo -e "${BLUE}🎯 目标服务器: $TENCENT_USER@$TENCENT_SERVER${NC}"
echo -e "${BLUE}🔑 SSH密钥: $SSH_KEY${NC}"

# 检查服务器状态
check_server_status() {
    echo -e "${BLUE}📡 检查腾讯云服务器状态...${NC}"
    
    # 检查网络连通性
    if ping -c 3 -W 5 $TENCENT_SERVER > /dev/null 2>&1; then
        echo -e "${GREEN}  ✅ 网络连通正常${NC}"
        NETWORK_OK=true
    else
        echo -e "${RED}  ❌ 网络不通，服务器可能已关机${NC}"
        NETWORK_OK=false
        return 1
    fi
    
    # 检查SSH连接
    if ssh -i $SSH_KEY -o ConnectTimeout=10 -o BatchMode=yes $TENCENT_USER@$TENCENT_SERVER "echo 'SSH连接成功'" > /dev/null 2>&1; then
        echo -e "${GREEN}  ✅ SSH连接正常${NC}"
        SSH_OK=true
    else
        echo -e "${RED}  ❌ SSH连接失败${NC}"
        SSH_OK=false
        return 1
    fi
    
    return 0
}

# 检查服务状态
check_services_status() {
    echo -e "${BLUE}📊 检查腾讯云服务状态...${NC}"
    
    for service in "${TENCENT_SERVICES[@]}"; do
        port=$(echo $service | cut -d: -f1)
        name=$(echo $service | cut -d: -f2)
        
        echo -e "${BLUE}  检查 $name (端口 $port)...${NC}"
        
        # 检查端口是否开放
        if ssh -i $SSH_KEY $TENCENT_USER@$TENCENT_SERVER "netstat -tlnp | grep :$port" > /dev/null 2>&1; then
            echo -e "${GREEN}    ✅ 端口 $port 开放${NC}"
        else
            echo -e "${RED}    ❌ 端口 $port 未开放${NC}"
        fi
        
        # 检查服务响应
        if [ "$port" = "9200" ] || [ "$port" = "8300" ]; then
            response=$(curl -s -w "%{http_code}" -o /dev/null http://$TENCENT_SERVER:$port --connect-timeout 5 2>/dev/null)
            if [ "$response" = "200" ]; then
                echo -e "${GREEN}    ✅ HTTP响应正常 (200)${NC}"
            else
                echo -e "${RED}    ❌ HTTP响应异常 ($response)${NC}"
            fi
        fi
    done
}

# 检查Docker容器状态
check_docker_status() {
    echo -e "${BLUE}🐳 检查Docker容器状态...${NC}"
    
    ssh -i $SSH_KEY $TENCENT_USER@$TENCENT_SERVER "
        echo 'Docker容器状态:'
        docker ps -a 2>/dev/null || echo 'Docker未运行'
        
        echo ''
        echo 'Docker服务状态:'
        systemctl status docker --no-pager 2>/dev/null || echo 'Docker服务未安装'
        
        echo ''
        echo '磁盘使用情况:'
        df -h
        
        echo ''
        echo '内存使用情况:'
        free -h
    "
}

# 重启腾讯云服务
restart_tencent_services() {
    echo -e "${BLUE}🔄 重启腾讯云服务...${NC}"
    
    ssh -i $SSH_KEY $TENCENT_USER@$TENCENT_SERVER "
        echo '检查并重启Docker服务...'
        
        # 重启Docker服务
        sudo systemctl restart docker
        
        # 等待Docker启动
        sleep 10
        
        # 检查是否有现有的Docker Compose配置
        if [ -f '/opt/dao-services/docker-compose.tencent.yml' ]; then
            echo '发现现有Docker Compose配置，重启服务...'
            cd /opt/dao-services
            docker-compose -f docker-compose.tencent.yml down
            docker-compose -f docker-compose.tencent.yml up -d
        else
            echo '未发现现有Docker Compose配置'
        fi
        
        # 等待服务启动
        echo '等待服务启动...'
        sleep 30
        
        # 检查服务状态
        echo '检查服务状态...'
        docker ps
    "
}

# 部署简化版腾讯云服务
deploy_simple_services() {
    echo -e "${BLUE}🚀 部署简化版腾讯云服务...${NC}"
    
    ssh -i $SSH_KEY $TENCENT_USER@$TENCENT_SERVER "
        echo '创建服务目录...'
        mkdir -p /opt/tencent-services
        cd /opt/tencent-services
        
        echo '创建简化版Docker Compose配置...'
        cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  # DAO版Web服务 (Nginx)
  dao-web:
    image: nginx:alpine
    container_name: dao-web
    ports:
      - '9200:80'
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
    restart: unless-stopped

  # 区块链Web服务 (Node.js)
  blockchain-web:
    image: node:18-alpine
    container_name: blockchain-web
    ports:
      - '8300:8080'
    working_dir: /app
    command: >
      sh -c 'echo \"const http = require('http');
      const server = http.createServer((req, res) => {
        res.writeHead(200, {'Content-Type': 'text/plain'});
        res.end('区块链服务运行正常！时间: ' + new Date().toString());
      });
      server.listen(8080, '0.0.0.0', () => {
        console.log('区块链服务启动在端口8080');
      });\" > server.js && node server.js'
    restart: unless-stopped

  # DAO PostgreSQL数据库
  dao-postgres:
    image: postgres:14-alpine
    container_name: dao-postgres
    ports:
      - '5433:5432'
    environment:
      - POSTGRES_DB=dao_dev
      - POSTGRES_USER=dao_user
      - POSTGRES_PASSWORD=dao_password_2024
    restart: unless-stopped

  # DAO Redis缓存
  dao-redis:
    image: redis:7-alpine
    container_name: dao-redis
    ports:
      - '6380:6379'
    restart: unless-stopped
EOF

        echo '创建Nginx配置...'
        cat > nginx.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    server {
        listen 80;
        location / {
            return 200 '<!DOCTYPE html>
<html>
<head>
    <title>DAO版Web服务</title>
</head>
<body>
    <h1>DAO版Web服务运行正常</h1>
    <p>时间: $date</p>
    <p>服务状态: 健康</p>
</body>
</html>';
            add_header Content-Type text/html;
        }
    }
}
EOF

        echo '启动服务...'
        docker-compose up -d
        
        echo '等待服务启动...'
        sleep 30
        
        echo '检查服务状态...'
        docker ps
    "
}

# 验证服务功能
verify_services() {
    echo -e "${BLUE}✅ 验证服务功能...${NC}"
    
    # 测试DAO Web服务
    echo -e "${BLUE}  测试DAO Web服务 (端口9200)...${NC}"
    response=$(curl -s -w "%{http_code}" -o /dev/null http://$TENCENT_SERVER:9200 --connect-timeout 10 2>/dev/null)
    if [ "$response" = "200" ]; then
        echo -e "${GREEN}    ✅ DAO Web服务正常 (HTTP $response)${NC}"
    else
        echo -e "${RED}    ❌ DAO Web服务异常 (HTTP $response)${NC}"
    fi
    
    # 测试区块链服务
    echo -e "${BLUE}  测试区块链服务 (端口8300)...${NC}"
    response=$(curl -s -w "%{http_code}" -o /dev/null http://$TENCENT_SERVER:8300 --connect-timeout 10 2>/dev/null)
    if [ "$response" = "200" ]; then
        echo -e "${GREEN}    ✅ 区块链服务正常 (HTTP $response)${NC}"
    else
        echo -e "${RED}    ❌ 区块链服务异常 (HTTP $response)${NC}"
    fi
    
    # 测试数据库连接
    echo -e "${BLUE}  测试数据库连接...${NC}"
    if ssh -i $SSH_KEY $TENCENT_USER@$TENCENT_SERVER "docker exec dao-postgres pg_isready -h localhost -p 5432" > /dev/null 2>&1; then
        echo -e "${GREEN}    ✅ PostgreSQL数据库连接正常${NC}"
    else
        echo -e "${RED}    ❌ PostgreSQL数据库连接失败${NC}"
    fi
    
    if ssh -i $SSH_KEY $TENCENT_USER@$TENCENT_SERVER "docker exec dao-redis redis-cli ping" > /dev/null 2>&1; then
        echo -e "${GREEN}    ✅ Redis数据库连接正常${NC}"
    else
        echo -e "${RED}    ❌ Redis数据库连接失败${NC}"
    fi
}

# 主执行函数
main() {
    echo -e "${BLUE}🚀 开始腾讯云环境修复...${NC}"
    
    # 检查服务器状态
    if check_server_status; then
        echo -e "${GREEN}✅ 服务器连接正常，继续检查服务状态${NC}"
        
        # 检查服务状态
        check_services_status
        
        # 检查Docker状态
        check_docker_status
        
        # 尝试重启服务
        echo -e "${YELLOW}🔄 尝试重启现有服务...${NC}"
        restart_tencent_services
        
        # 等待服务启动
        sleep 30
        
        # 验证服务功能
        verify_services
        
    else
        echo -e "${RED}❌ 服务器连接失败，请检查以下项目：${NC}"
        echo -e "${YELLOW}  1. 登录腾讯云控制台检查服务器状态${NC}"
        echo -e "${YELLOW}  2. 确认服务器是否已启动${NC}"
        echo -e "${YELLOW}  3. 检查安全组配置是否正确${NC}"
        echo -e "${YELLOW}  4. 确认SSH密钥是否正确${NC}"
        echo -e "${YELLOW}  5. 检查服务器网络配置${NC}"
        
        echo ""
        echo -e "${BLUE}💡 修复建议：${NC}"
        echo -e "  1. 登录腾讯云控制台"
        echo -e "  2. 找到轻量应用服务器实例"
        echo -e "  3. 检查实例状态，如已停止则启动"
        echo -e "  4. 检查安全组规则，确保以下端口开放："
        echo -e "     - 22 (SSH)"
        echo -e "     - 9200 (DAO Web服务)"
        echo -e "     - 8300 (区块链服务)"
        echo -e "     - 5433 (PostgreSQL)"
        echo -e "     - 6380 (Redis)"
    fi
    
    echo -e "\n${GREEN}🎉 腾讯云环境修复完成 - $(date)${NC}"
}

# 执行主函数
main
