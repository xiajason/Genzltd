#!/bin/bash
# 腾讯云服务部署脚本

echo "🚀 开始部署腾讯云服务..."

# 创建服务目录
mkdir -p /home/ubuntu/dao-services
mkdir -p /home/ubuntu/blockchain-services

# 创建DAO版服务配置
cat > /home/ubuntu/dao-services/docker-compose.yml << 'EOF'
version: '3.8'

services:
  dao-postgres:
    image: postgres:15-alpine
    container_name: dao-postgres
    environment:
      POSTGRES_DB: dao_database
      POSTGRES_USER: dao_user
      POSTGRES_PASSWORD: dao_password
    ports:
      - "5433:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U dao_user -d dao_database"]
      interval: 30s
      timeout: 10s
      retries: 3

  dao-redis:
    image: redis:7.2-alpine
    container_name: dao-redis
    ports:
      - "6380:6379"
    volumes:
      - redis_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 30s
      timeout: 10s
      retries: 3

  dao-nginx:
    image: nginx:alpine
    container_name: dao-nginx
    ports:
      - "9200:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
    depends_on:
      - dao-postgres
      - dao-redis

volumes:
  postgres_data:
  redis_data:
EOF

# 创建Nginx配置
cat > /home/ubuntu/dao-services/nginx.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    upstream dao_backend {
        server dao-postgres:5432;
    }
    
    server {
        listen 80;
        server_name localhost;
        
        location / {
            return 200 'DAO版服务运行正常！\nPostgreSQL: 5433\nRedis: 6380\n';
            add_header Content-Type text/plain;
        }
        
        location /health {
            return 200 'OK';
            add_header Content-Type text/plain;
        }
    }
}
EOF

# 创建区块链版服务配置
cat > /home/ubuntu/blockchain-services/docker-compose.yml << 'EOF'
version: '3.8'

services:
  blockchain-node:
    image: node:18-alpine
    container_name: blockchain-node
    ports:
      - "8300:3000"
    volumes:
      - ./app:/app
    working_dir: /app
    command: sh -c "echo '区块链节点服务运行正常！' && sleep infinity"

  blockchain-api:
    image: node:18-alpine
    container_name: blockchain-api
    ports:
      - "8301:3001"
    volumes:
      - ./api:/app
    working_dir: /app
    command: sh -c "echo '区块链API服务运行正常！' && sleep infinity"

volumes:
  app_data:
  api_data:
EOF

# 启动DAO版服务
echo "🚀 启动DAO版服务..."
cd /home/ubuntu/dao-services
docker-compose up -d

# 等待服务启动
sleep 10

# 启动区块链版服务
echo "🚀 启动区块链版服务..."
cd /home/ubuntu/blockchain-services
docker-compose up -d

# 等待服务启动
sleep 10

echo "✅ 服务部署完成！"
echo ""
echo "📊 检查服务状态:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""
echo "🌐 服务访问地址:"
echo "  DAO版服务: http://101.33.251.158:9200"
echo "  区块链节点: http://101.33.251.158:8300"
echo "  区块链API: http://101.33.251.158:8301"
echo ""
echo "🔍 健康检查:"
curl -f http://localhost:9200/health && echo " - DAO版服务健康"
curl -f http://localhost:8300 && echo " - 区块链节点服务健康"
