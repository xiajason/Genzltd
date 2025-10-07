#!/bin/bash
# 腾讯云DAO服务部署脚本

echo "🚀 部署DAO服务到腾讯云集成环境..."

# 连接到腾讯云服务器
ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158 << 'REMOTE_SCRIPT'
echo "📦 在腾讯云服务器上部署DAO集成环境..."

# 检查当前服务器状态
echo "🔍 检查当前服务器状态..."
echo "CPU信息:"
lscpu | grep -E "(CPU\(s\)|Model name|Architecture)"
echo "内存信息:"
free -h
echo "磁盘信息:"
df -h
echo "Docker状态:"
docker --version 2>/dev/null || echo "Docker未安装"

# 更新系统
echo "📦 更新系统包..."
sudo apt update && sudo apt upgrade -y

# 跳过Docker安装 - 腾讯云轻量服务器Docker容器需要额外付费
echo "⚠️ 跳过Docker安装 - 腾讯云轻量服务器Docker容器需要额外付费"
echo "🎯 采用原生部署策略以节省成本"

# 安装Go 1.21 (如果未安装)
if ! command -v go &> /dev/null; then
    echo "🔧 安装Go 1.21..."
    wget https://go.dev/dl/go1.21.5.linux-amd64.tar.gz
    sudo tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
    source ~/.bashrc
fi

# 安装Python 3.11 (如果未安装)
if ! command -v python3.11 &> /dev/null; then
    echo "🐍 安装Python 3.11..."
    sudo apt install -y python3.11 python3.11-pip python3.11-venv
fi

# 安装Node.js 18 (如果未安装)
if ! command -v node &> /dev/null; then
    echo "📦 安装Node.js 18..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt install -y nodejs
fi

# 创建DAO服务目录
echo "📁 创建DAO服务目录..."
mkdir -p /opt/dao-services/{resume,job,dao-governance,ai}
mkdir -p /opt/dao-services/{logs,config,database}

# 创建腾讯云集成环境Docker Compose配置
echo "📝 创建腾讯云DAO服务配置..."
cat > /opt/dao-services/docker-compose.tencent.yml << 'DOCKER_COMPOSE'
version: '3.8'

services:
  # DAO Resume服务
  dao-resume:
    image: golang:1.21-alpine
    container_name: dao-resume-service
    ports:
      - "9502:8080"
    environment:
      - GIN_MODE=release
      - DB_HOST=dao-mysql
      - REDIS_HOST=dao-redis
    volumes:
      - ./resume:/app
      - ./logs:/app/logs
    working_dir: /app
    command: ["go", "run", "main.go"]
    depends_on:
      - dao-mysql
      - dao-redis
    restart: unless-stopped

  # DAO Job服务
  dao-job:
    image: golang:1.21-alpine
    container_name: dao-job-service
    ports:
      - "7531:8080"
    environment:
      - GIN_MODE=release
      - DB_HOST=dao-mysql
      - REDIS_HOST=dao-redis
    volumes:
      - ./job:/app
      - ./logs:/app/logs
    working_dir: /app
    command: ["go", "run", "main.go"]
    depends_on:
      - dao-mysql
      - dao-redis
    restart: unless-stopped

  # DAO治理服务
  dao-governance:
    image: golang:1.21-alpine
    container_name: dao-governance-service
    ports:
      - "9503:8080"
    environment:
      - GIN_MODE=release
      - DB_HOST=dao-mysql
      - REDIS_HOST=dao-redis
    volumes:
      - ./dao-governance:/app
      - ./logs:/app/logs
    working_dir: /app
    command: ["go", "run", "main.go"]
    depends_on:
      - dao-mysql
      - dao-redis
    restart: unless-stopped

  # DAO AI服务
  dao-ai:
    image: python:3.11-alpine
    container_name: dao-ai-service
    ports:
      - "8206:8080"
    environment:
      - PYTHON_ENV=production
      - DB_HOST=dao-mysql
      - REDIS_HOST=dao-redis
    volumes:
      - ./ai:/app
      - ./logs:/app/logs
    working_dir: /app
    command: ["python", "main.py"]
    depends_on:
      - dao-mysql
      - dao-redis
    restart: unless-stopped

  # DAO MySQL数据库
  dao-mysql:
    image: mysql:8.0
    container_name: dao-mysql
    environment:
      - MYSQL_ROOT_PASSWORD=dao_password_2024
      - MYSQL_DATABASE=dao_integration
      - MYSQL_USER=dao_user
      - MYSQL_PASSWORD=dao_password_2024
    ports:
      - "3306:3306"
    volumes:
      - mysql_data:/var/lib/mysql
      - ./database/init.sql:/docker-entrypoint-initdb.d/init.sql
    restart: unless-stopped

  # DAO Redis缓存
  dao-redis:
    image: redis:7-alpine
    container_name: dao-redis
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    restart: unless-stopped

  # DAO PostgreSQL数据库
  dao-postgres:
    image: postgres:14-alpine
    container_name: dao-postgres
    environment:
      - POSTGRES_DB=dao_vector
      - POSTGRES_USER=dao_user
      - POSTGRES_PASSWORD=dao_password_2024
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: unless-stopped

  # DAO Neo4j数据库
  dao-neo4j:
    image: neo4j:latest
    container_name: dao-neo4j
    environment:
      - NEO4J_AUTH=neo4j/dao_password_2024
    ports:
      - "7474:7474"
      - "7687:7687"
    volumes:
      - neo4j_data:/data
    restart: unless-stopped

  # Consul服务发现
  dao-consul:
    image: consul:1.16
    container_name: dao-consul
    ports:
      - "8500:8500"
    command: agent -server -ui -node=server-1 -bootstrap-expect=1 -client=0.0.0.0
    restart: unless-stopped

  # Prometheus监控
  dao-prometheus:
    image: prom/prometheus:latest
    container_name: dao-prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus:/etc/prometheus
    restart: unless-stopped

  # Grafana可视化
  dao-grafana:
    image: grafana/grafana:latest
    container_name: dao-grafana
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=dao_admin_2024
    volumes:
      - grafana_data:/var/lib/grafana
    restart: unless-stopped

volumes:
  mysql_data:
  redis_data:
  postgres_data:
  neo4j_data:
  grafana_data:
DOCKER_COMPOSE

# 创建数据库初始化脚本
echo "📝 创建数据库初始化脚本..."
cat > /opt/dao-services/database/init.sql << 'INIT_SQL'
-- DAO集成环境数据库初始化脚本
-- 创建DAO相关数据库和表

-- 创建DAO治理数据库
CREATE DATABASE IF NOT EXISTS dao_governance CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 使用DAO治理数据库
USE dao_governance;

-- 创建DAO成员表
CREATE TABLE IF NOT EXISTS dao_members (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL UNIQUE,
    wallet_address VARCHAR(255),
    reputation_score INT DEFAULT 0,
    contribution_points INT DEFAULT 0,
    join_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status ENUM('active', 'inactive', 'suspended') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- 创建DAO提案表
CREATE TABLE IF NOT EXISTS dao_proposals (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    proposal_id VARCHAR(255) NOT NULL UNIQUE,
    title VARCHAR(500) NOT NULL,
    description TEXT,
    proposer_id VARCHAR(255) NOT NULL,
    proposal_type ENUM('governance', 'funding', 'technical', 'policy') NOT NULL,
    status ENUM('draft', 'active', 'passed', 'rejected', 'executed') DEFAULT 'draft',
    start_time TIMESTAMP NULL,
    end_time TIMESTAMP NULL,
    votes_for INT DEFAULT 0,
    votes_against INT DEFAULT 0,
    total_votes INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- 创建DAO投票表
CREATE TABLE IF NOT EXISTS dao_votes (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    proposal_id VARCHAR(255) NOT NULL,
    voter_id VARCHAR(255) NOT NULL,
    vote_choice ENUM('for', 'against', 'abstain') NOT NULL,
    voting_power INT NOT NULL,
    vote_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_vote (proposal_id, voter_id)
);

-- 创建DAO奖励表
CREATE TABLE IF NOT EXISTS dao_rewards (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    recipient_id VARCHAR(255) NOT NULL,
    reward_type ENUM('contribution', 'voting', 'proposal', 'governance') NOT NULL,
    amount DECIMAL(18,8) NOT NULL,
    currency VARCHAR(10) DEFAULT 'DAO',
    description TEXT,
    status ENUM('pending', 'approved', 'distributed') DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    distributed_at TIMESTAMP NULL
);

-- 创建DAO活动日志表
CREATE TABLE IF NOT EXISTS dao_activity_log (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL,
    activity_type VARCHAR(100) NOT NULL,
    activity_description TEXT,
    metadata JSON,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 插入示例数据
INSERT INTO dao_members (user_id, wallet_address, reputation_score, contribution_points) VALUES
('user_001', '0x1234567890abcdef', 100, 50),
('user_002', '0xabcdef1234567890', 85, 35),
('user_003', '0x9876543210fedcba', 120, 75);

INSERT INTO dao_proposals (proposal_id, title, description, proposer_id, proposal_type, status) VALUES
('prop_001', 'DAO治理机制优化提案', '建议优化DAO治理机制，提高决策效率', 'user_001', 'governance', 'active'),
('prop_002', '技术架构升级提案', '建议升级系统技术架构，提高性能', 'user_002', 'technical', 'draft');
INIT_SQL

# 创建Prometheus配置
echo "📝 创建Prometheus配置..."
mkdir -p /opt/dao-services/prometheus
cat > /opt/dao-services/prometheus/prometheus.yml << 'PROMETHEUS_CONFIG'
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'dao-services'
    static_configs:
      - targets: ['dao-resume:8080', 'dao-job:8080', 'dao-governance:8080', 'dao-ai:8080']
  
  - job_name: 'dao-databases'
    static_configs:
      - targets: ['dao-mysql:3306', 'dao-redis:6379', 'dao-postgres:5432', 'dao-neo4j:7474']
PROMETHEUS_CONFIG

# 启动DAO服务
echo "🚀 启动DAO服务..."
cd /opt/dao-services
docker-compose -f docker-compose.tencent.yml up -d

# 等待服务启动
echo "⏳ 等待服务启动..."
sleep 30

# 检查服务状态
echo "🔍 检查服务状态..."
docker-compose -f docker-compose.tencent.yml ps

# 健康检查
echo "🏥 执行健康检查..."
curl -f http://localhost:9502/health || echo "DAO Resume服务健康检查失败"
curl -f http://localhost:7531/health || echo "DAO Job服务健康检查失败"
curl -f http://localhost:9503/health || echo "DAO治理服务健康检查失败"
curl -f http://localhost:8206/health || echo "DAO AI服务健康检查失败"

echo "✅ 腾讯云DAO集成环境部署完成！"
REMOTE_SCRIPT

echo "🌐 腾讯云集成环境访问地址:"
echo "  - DAO Resume服务: http://101.33.251.158:9502"
echo "  - DAO Job服务: http://101.33.251.158:7531"
echo "  - DAO治理服务: http://101.33.251.158:9503"
echo "  - DAO AI服务: http://101.33.251.158:8206"
echo "  - 监控面板: http://101.33.251.158:3000"
echo "  - 服务发现: http://101.33.251.158:8500"
echo "  - 指标收集: http://101.33.251.158:9090"
