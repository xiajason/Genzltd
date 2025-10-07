#!/bin/bash
# 阿里云DAO服务部署脚本 (基于实际配置)

echo "🚀 部署DAO服务到阿里云生产环境..."

# 连接到阿里云ECS (实际IP: 47.115.168.107)
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 << 'REMOTE_SCRIPT'
echo "📦 在阿里云ECS上部署DAO生产环境..."

# 检查现有服务状态
echo "🔍 检查现有服务状态..."
echo "现有运行服务:"
netstat -tuln | grep -E ":(6379|8206|8080|8300)"

# 检查Docker状态
echo "🐳 检查Docker状态..."
docker --version
docker-compose --version

# 检查现有Docker镜像
echo "📦 检查现有Docker镜像..."
docker images | grep -E "(jobfirst|mysql|redis|postgres|neo4j|consul)"

# 创建DAO服务目录
echo "📁 创建DAO服务目录..."
mkdir -p /opt/dao-services/{resume,job,dao-governance,ai}
mkdir -p /opt/dao-services/{logs,config,database,prometheus}

# 创建阿里云生产环境Docker Compose配置
echo "📝 创建阿里云DAO服务配置..."
cat > /opt/dao-services/docker-compose.alibaba.yml << 'DOCKER_COMPOSE'
version: '3.8'

services:
  # DAO治理服务
  dao-governance:
    image: jobfirst-backend:latest
    container_name: dao-governance-service
    ports:
      - "9503:8080"
    environment:
      - GIN_MODE=release
      - SERVICE_NAME=dao-governance
      - REDIS_HOST=localhost
      - REDIS_PORT=6379
      - DB_HOST=dao-mysql
      - DB_PORT=3306
    depends_on:
      - dao-mysql
    volumes:
      - ./logs:/app/logs
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  # DAO投票服务
  dao-voting:
    image: jobfirst-backend:latest
    container_name: dao-voting-service
    ports:
      - "9504:8080"
    environment:
      - GIN_MODE=release
      - SERVICE_NAME=dao-voting
      - REDIS_HOST=localhost
      - REDIS_PORT=6379
      - DB_HOST=dao-mysql
      - DB_PORT=3306
    depends_on:
      - dao-mysql
    volumes:
      - ./logs:/app/logs
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  # DAO提案服务
  dao-proposal:
    image: jobfirst-backend:latest
    container_name: dao-proposal-service
    ports:
      - "9505:8080"
    environment:
      - GIN_MODE=release
      - SERVICE_NAME=dao-proposal
      - REDIS_HOST=localhost
      - REDIS_PORT=6379
      - DB_HOST=dao-mysql
      - DB_PORT=3306
    depends_on:
      - dao-mysql
    volumes:
      - ./logs:/app/logs
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  # DAO奖励服务
  dao-reward:
    image: jobfirst-backend:latest
    container_name: dao-reward-service
    ports:
      - "9506:8080"
    environment:
      - GIN_MODE=release
      - SERVICE_NAME=dao-reward
      - REDIS_HOST=localhost
      - REDIS_PORT=6379
      - DB_HOST=dao-mysql
      - DB_PORT=3306
    depends_on:
      - dao-mysql
    volumes:
      - ./logs:/app/logs
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  # DAO MySQL数据库
  dao-mysql:
    image: mysql:8.0
    container_name: dao-mysql
    environment:
      - MYSQL_ROOT_PASSWORD=dao_password_2024
      - MYSQL_DATABASE=dao_production
      - MYSQL_USER=dao_user
      - MYSQL_PASSWORD=dao_password_2024
    ports:
      - "9507:3306"  # 避免与现有MySQL冲突
    volumes:
      - mysql_data:/var/lib/mysql
      - ./database/init.sql:/docker-entrypoint-initdb.d/init.sql
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-u", "root", "-pdao_password_2024"]
      interval: 30s
      timeout: 10s
      retries: 5

  # DAO PostgreSQL数据库
  dao-postgres:
    image: postgres:14-alpine
    container_name: dao-postgres
    environment:
      - POSTGRES_DB=dao_analysis
      - POSTGRES_USER=dao_user
      - POSTGRES_PASSWORD=dao_password_2024
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U dao_user -d dao_analysis"]
      interval: 30s
      timeout: 10s
      retries: 5

  # Prometheus监控
  dao-prometheus:
    image: prom/prometheus:latest
    container_name: dao-prometheus
    ports:
      - "9514:9090"
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--storage.tsdb.retention.time=200h'
      - '--web.enable-lifecycle'
    restart: unless-stopped

  # Grafana可视化
  dao-grafana:
    image: grafana/grafana:latest
    container_name: dao-grafana
    ports:
      - "9515:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=dao_admin_2024
      - GF_USERS_ALLOW_SIGN_UP=false
    volumes:
      - grafana_data:/var/lib/grafana
      - ./grafana/provisioning:/etc/grafana/provisioning
    restart: unless-stopped

volumes:
  mysql_data:
  postgres_data:
  prometheus_data:
  grafana_data:
DOCKER_COMPOSE

# 创建数据库初始化脚本
echo "📝 创建数据库初始化脚本..."
cat > /opt/dao-services/database/init.sql << 'INIT_SQL'
-- DAO生产环境数据库初始化脚本
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
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_user_id (user_id),
    INDEX idx_wallet_address (wallet_address),
    INDEX idx_reputation_score (reputation_score)
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
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_proposal_id (proposal_id),
    INDEX idx_proposer_id (proposer_id),
    INDEX idx_status (status),
    INDEX idx_start_time (start_time),
    INDEX idx_end_time (end_time)
);

-- 创建DAO投票表
CREATE TABLE IF NOT EXISTS dao_votes (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    proposal_id VARCHAR(255) NOT NULL,
    voter_id VARCHAR(255) NOT NULL,
    vote_choice ENUM('for', 'against', 'abstain') NOT NULL,
    voting_power INT NOT NULL,
    vote_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_vote (proposal_id, voter_id),
    INDEX idx_proposal_id (proposal_id),
    INDEX idx_voter_id (voter_id),
    INDEX idx_vote_timestamp (vote_timestamp)
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
    distributed_at TIMESTAMP NULL,
    INDEX idx_recipient_id (recipient_id),
    INDEX idx_reward_type (reward_type),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at)
);

-- 创建DAO活动日志表
CREATE TABLE IF NOT EXISTS dao_activity_log (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL,
    activity_type VARCHAR(100) NOT NULL,
    activity_description TEXT,
    metadata JSON,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user_id (user_id),
    INDEX idx_activity_type (activity_type),
    INDEX idx_timestamp (timestamp)
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
cat > /opt/dao-services/prometheus/prometheus.yml << 'PROMETHEUS_CONFIG'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  # - "first_rules.yml"
  # - "second_rules.yml"

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'dao-services'
    static_configs:
      - targets: 
        - 'dao-governance:8080'
        - 'dao-voting:8080'
        - 'dao-proposal:8080'
        - 'dao-reward:8080'
    metrics_path: /metrics
    scrape_interval: 30s

  - job_name: 'dao-databases'
    static_configs:
      - targets: 
        - 'dao-mysql:3306'
        - 'dao-postgres:5432'
    scrape_interval: 60s

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['localhost:9100']
    scrape_interval: 30s
PROMETHEUS_CONFIG

# 启动DAO服务
echo "🚀 启动DAO服务..."
cd /opt/dao-services
docker-compose -f docker-compose.alibaba.yml up -d

# 等待服务启动
echo "⏳ 等待服务启动..."
sleep 45

# 检查服务状态
echo "🔍 检查服务状态..."
docker-compose -f docker-compose.alibaba.yml ps

# 健康检查
echo "🏥 执行健康检查..."
curl -f http://localhost:9503/health || echo "DAO治理服务健康检查失败"
curl -f http://localhost:9504/health || echo "DAO投票服务健康检查失败"
curl -f http://localhost:9505/health || echo "DAO提案服务健康检查失败"
curl -f http://localhost:9506/health || echo "DAO奖励服务健康检查失败"

# 检查数据库状态
echo "🗄️ 检查数据库状态..."
docker-compose -f docker-compose.alibaba.yml exec dao-mysql mysqladmin ping -h localhost -u root -pdao_password_2024
docker-compose -f docker-compose.alibaba.yml exec dao-postgres pg_isready -U dao_user -d dao_analysis

# 检查监控服务
echo "📈 检查监控服务..."
curl -f http://localhost:9514/-/healthy || echo "Prometheus健康检查失败"
curl -f http://localhost:9515/api/health || echo "Grafana健康检查失败"

# 检查现有服务状态
echo "🔍 检查现有服务状态..."
if redis-cli ping > /dev/null 2>&1; then
    echo "✅ Redis服务: 运行正常"
else
    echo "❌ Redis服务: 运行异常"
fi

if curl -s http://localhost:8206/health > /dev/null; then
    echo "✅ AI服务: 运行正常"
else
    echo "❌ AI服务: 运行异常"
fi

if curl -s http://localhost:8300/v1/status/leader > /dev/null; then
    echo "✅ Consul服务: 运行正常"
else
    echo "❌ Consul服务: 运行异常"
fi

echo "✅ 阿里云DAO生产环境部署完成！"
REMOTE_SCRIPT

echo "🌐 阿里云生产环境访问地址:"
echo "  - DAO治理服务: http://47.115.168.107:9503"
echo "  - DAO投票服务: http://47.115.168.107:9504"
echo "  - DAO提案服务: http://47.115.168.107:9505"
echo "  - DAO奖励服务: http://47.115.168.107:9506"
echo "  - 监控面板: http://47.115.168.107:9515"
echo "  - 指标收集: http://47.115.168.107:9514"
echo "  - 现有AI服务: http://47.115.168.107:8206"
echo "  - 现有Redis服务: 47.115.168.107:6379"
echo "  - 现有Consul服务: http://47.115.168.107:8300"
