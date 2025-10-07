#!/bin/bash
# 本地DAO开发环境启动脚本

echo "🚀 启动本地DAO开发环境..."

# 创建DAO服务目录
echo "📁 创建DAO服务目录结构..."
mkdir -p looma_crm_future/services/dao_services/{resume,job,dao-governance,ai}
mkdir -p looma_crm_future/services/dao_services/{logs,config,database}

# 创建Docker Compose配置文件
echo "📝 创建Docker Compose配置文件..."
cat > looma_crm_future/services/dao_services/docker-compose.local.yml << 'EOF'
version: '3.8'

services:
  mysql:
    image: mysql:8.0
    container_name: dao-mysql-local
    environment:
      MYSQL_ROOT_PASSWORD: dao_password_2024
      MYSQL_DATABASE: dao_dev
      MYSQL_USER: dao_user
      MYSQL_PASSWORD: dao_password_2024
    ports:
      - "9506:3306"
    volumes:
      - mysql_data:/var/lib/mysql
      - ./database/init.sql:/docker-entrypoint-initdb.d/init.sql
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      timeout: 20s
      retries: 10

  redis:
    image: redis:7.0-alpine
    container_name: dao-redis-local
    ports:
      - "9507:6379"
    volumes:
      - redis_data:/data
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      timeout: 20s
      retries: 10

volumes:
  mysql_data:
  redis_data:
EOF

# 创建数据库初始化脚本
echo "📝 创建数据库初始化脚本..."
mkdir -p looma_crm_future/services/dao_services/database
cat > looma_crm_future/services/dao_services/database/init.sql << 'EOF'
-- DAO开发环境数据库初始化脚本
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

EOF

# 启动轻量级数据库
echo "📦 启动轻量级数据库..."
cd looma_crm_future/services/dao_services
docker-compose -f docker-compose.local.yml up -d

# 等待数据库启动
echo "⏳ 等待数据库启动..."
sleep 15

# 验证数据库连接
echo "🔍 验证数据库连接..."
if nc -z localhost 9506; then
    echo "✅ MySQL (9506): 连接正常"
else
    echo "❌ MySQL (9506): 连接异常"
fi

if nc -z localhost 9507; then
    echo "✅ Redis (9507): 连接正常"
else
    echo "❌ Redis (9507): 连接异常"
fi

# 检查Docker容器状态
echo "🐳 检查Docker容器状态..."
docker ps | grep -E "(dao-mysql-local|dao-redis-local)"

# 创建开发环境配置
echo "⚙️ 创建开发环境配置..."
cat > looma_crm_future/services/dao_services/config/development.env << 'EOF'
# DAO开发环境配置
ENV=development
DEBUG=true

# 数据库配置
DB_HOST=localhost
DB_PORT=9506
DB_NAME=dao_dev
DB_USER=dao_user
DB_PASSWORD=dao_password_2024

# Redis配置
REDIS_HOST=localhost
REDIS_PORT=9507
REDIS_DB=0

# 服务端口配置
RESUME_SERVICE_PORT=9502
JOB_SERVICE_PORT=7531
DAO_GOVERNANCE_PORT=9503
AI_SERVICE_PORT=8206

# 日志配置
LOG_LEVEL=debug
LOG_FILE=./logs/dao-dev.log
EOF

echo "✅ 本地DAO开发环境启动完成！"
echo "🌐 本地访问地址:"
echo "  - MySQL: localhost:9506"
echo "  - Redis: localhost:9507"
echo "  - 配置目录: ./config/"
echo "  - 日志目录: ./logs/"
echo "  - 数据库初始化脚本: ./database/init.sql"
echo ""
echo "🎯 下一步: 验证环境健康状态"
