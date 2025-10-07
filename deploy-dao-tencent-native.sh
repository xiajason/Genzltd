#!/bin/bash
# 腾讯云DAO服务原生部署脚本 (避免Docker容器额外费用)

echo "🚀 部署DAO服务到腾讯云集成环境 (原生部署，避免Docker费用)..."

# 连接到腾讯云服务器
ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158 << 'REMOTE_SCRIPT'
echo "📦 在腾讯云服务器上原生部署DAO集成环境..."

# 检查当前服务器状态
echo "🔍 检查当前服务器状态..."
echo "CPU信息:"
lscpu | grep -E "(CPU\(s\)|Model name|Architecture)"
echo "内存信息:"
free -h
echo "磁盘信息:"
df -h

# 更新系统
echo "📦 更新系统包..."
sudo apt update && sudo apt upgrade -y

# 安装Go 1.21 (DAO服务开发语言)
if ! command -v go &> /dev/null; then
    echo "🔧 安装Go 1.21..."
    wget https://go.dev/dl/go1.21.5.linux-amd64.tar.gz
    sudo tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
    echo 'export GOPATH=$HOME/go' >> ~/.bashrc
    echo 'export GOBIN=$GOPATH/bin' >> ~/.bashrc
    source ~/.bashrc
fi

# 安装Python 3.10 (AI服务开发语言) - Ubuntu 22.04默认版本
if ! command -v python3 &> /dev/null; then
    echo "🐍 安装Python 3.10..."
    sudo apt install -y python3 python3-pip python3-venv python3-dev
fi

# 安装AI服务依赖
echo "📦 安装AI服务依赖..."
python3 -m pip install --user fastapi uvicorn sanic redis pymysql psycopg2-binary

# 安装Node.js 18 (前端管理界面)
if ! command -v node &> /dev/null; then
    echo "📦 安装Node.js 18..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt install -y nodejs
# 安装前端依赖 (使用sudo)
echo "📦 安装前端开发工具..."
sudo npm install -g @vue/cli @angular/cli
fi

# 安装原生数据库服务
echo "🗄️ 安装原生数据库服务..."

# 安装MySQL 8.0
if ! command -v mysql &> /dev/null; then
    echo "📦 安装MySQL 8.0..."
    sudo apt install -y mysql-server-8.0
    sudo systemctl enable mysql
    sudo systemctl start mysql
    
    # 配置MySQL
    sudo mysql -e "CREATE DATABASE dao_integration CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
    sudo mysql -e "CREATE USER 'dao_user'@'localhost' IDENTIFIED BY 'dao_password_2024';"
    sudo mysql -e "GRANT ALL PRIVILEGES ON dao_integration.* TO 'dao_user'@'localhost';"
    sudo mysql -e "FLUSH PRIVILEGES;"
fi

# 安装Redis
if ! command -v redis-server &> /dev/null; then
    echo "📦 安装Redis..."
    sudo apt install -y redis-server
    sudo systemctl enable redis-server
    sudo systemctl start redis-server
fi

# 安装PostgreSQL
if ! command -v psql &> /dev/null; then
    echo "📦 安装PostgreSQL..."
    sudo apt install -y postgresql-14 postgresql-client-14
    sudo systemctl enable postgresql
    sudo systemctl start postgresql
    
    # 配置PostgreSQL
    sudo -u postgres createdb dao_vector
    sudo -u postgres psql -c "CREATE USER dao_user WITH PASSWORD 'dao_password_2024';"
    sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE dao_vector TO dao_user;"
fi

# 创建DAO服务目录结构
echo "📁 创建DAO服务目录结构..."
sudo mkdir -p /opt/dao-services/{resume,job,dao-governance,ai,logs,config,database}
sudo chown -R ubuntu:ubuntu /opt/dao-services

# 创建DAO服务启动脚本
echo "📝 创建DAO服务启动脚本..."

# Resume服务启动脚本
cat > /opt/dao-services/resume/start-resume.sh << 'EOF'
#!/bin/bash
echo "🚀 启动DAO Resume服务..."
cd /opt/dao-services/resume
export DB_HOST=localhost
export DB_PORT=3306
export DB_NAME=dao_integration
export DB_USER=dao_user
export DB_PASSWORD=dao_password_2024
export REDIS_HOST=localhost
export REDIS_PORT=6379
export SERVICE_PORT=9502
go run main.go
EOF

# Job服务启动脚本
cat > /opt/dao-services/job/start-job.sh << 'EOF'
#!/bin/bash
echo "🚀 启动DAO Job服务..."
cd /opt/dao-services/job
export DB_HOST=localhost
export DB_PORT=3306
export DB_NAME=dao_integration
export DB_USER=dao_user
export DB_PASSWORD=dao_password_2024
export REDIS_HOST=localhost
export REDIS_PORT=6379
export SERVICE_PORT=7531
go run main.go
EOF

# DAO治理服务启动脚本
cat > /opt/dao-services/dao-governance/start-governance.sh << 'EOF'
#!/bin/bash
echo "🚀 启动DAO治理服务..."
cd /opt/dao-services/dao-governance
export DB_HOST=localhost
export DB_PORT=3306
export DB_NAME=dao_integration
export DB_USER=dao_user
export DB_PASSWORD=dao_password_2024
export REDIS_HOST=localhost
export REDIS_PORT=6379
export SERVICE_PORT=9503
go run main.go
EOF

# AI服务启动脚本
cat > /opt/dao-services/ai/start-ai.sh << 'EOF'
#!/bin/bash
echo "🚀 启动DAO AI服务..."
cd /opt/dao-services/ai
export DB_HOST=localhost
export DB_PORT=5432
export DB_NAME=dao_vector
export DB_USER=dao_user
export DB_PASSWORD=dao_password_2024
export REDIS_HOST=localhost
export REDIS_PORT=6379
export SERVICE_PORT=8206
python3 main.py
EOF

# 设置执行权限
chmod +x /opt/dao-services/*/start-*.sh

# 创建数据库初始化脚本
echo "📝 创建数据库初始化脚本..."
cat > /opt/dao-services/database/init-dao.sql << 'INIT_SQL'
-- DAO集成环境数据库初始化脚本
USE dao_integration;

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

# 执行数据库初始化
echo "🗄️ 初始化数据库..."
mysql -u dao_user -pdao_password_2024 dao_integration < /opt/dao-services/database/init-dao.sql

# 创建系统服务配置
echo "📝 创建系统服务配置..."

# 创建DAO服务systemd服务文件
cat > /tmp/dao-resume.service << 'EOF'
[Unit]
Description=DAO Resume Service
After=network.target mysql.service redis.service

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/opt/dao-services/resume
ExecStart=/opt/dao-services/resume/start-resume.sh
Restart=always
RestartSec=10
Environment=GIN_MODE=release

[Install]
WantedBy=multi-user.target
EOF

cat > /tmp/dao-job.service << 'EOF'
[Unit]
Description=DAO Job Service
After=network.target mysql.service redis.service

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/opt/dao-services/job
ExecStart=/opt/dao-services/job/start-job.sh
Restart=always
RestartSec=10
Environment=GIN_MODE=release

[Install]
WantedBy=multi-user.target
EOF

cat > /tmp/dao-governance.service << 'EOF'
[Unit]
Description=DAO Governance Service
After=network.target mysql.service redis.service

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/opt/dao-services/dao-governance
ExecStart=/opt/dao-services/dao-governance/start-governance.sh
Restart=always
RestartSec=10
Environment=GIN_MODE=release

[Install]
WantedBy=multi-user.target
EOF

cat > /tmp/dao-ai.service << 'EOF'
[Unit]
Description=DAO AI Service
After=network.target postgresql.service redis.service

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/opt/dao-services/ai
ExecStart=/opt/dao-services/ai/start-ai.sh
Restart=always
RestartSec=10
Environment=PYTHON_ENV=production

[Install]
WantedBy=multi-user.target
EOF

# 安装系统服务
sudo cp /tmp/dao-*.service /etc/systemd/system/
sudo systemctl daemon-reload

# 创建健康检查脚本
cat > /opt/dao-services/health-check.sh << 'EOF'
#!/bin/bash
echo "🔍 检查DAO服务状态..."

services=("9502:Resume服务" "7531:Job服务" "9503:DAO治理服务" "8206:AI服务")

for service in "${services[@]}"; do
    port=$(echo $service | cut -d: -f1)
    name=$(echo $service | cut -d: -f2)
    
    if curl -s http://localhost:$port/health > /dev/null; then
        echo "✅ $name (端口$port): 运行正常"
    else
        echo "❌ $name (端口$port): 运行异常"
    fi
done

echo "🗄️ 检查数据库状态..."
if mysql -u dao_user -pdao_password_2024 -e "SELECT 1;" > /dev/null 2>&1; then
    echo "✅ MySQL数据库: 连接正常"
else
    echo "❌ MySQL数据库: 连接异常"
fi

if redis-cli ping > /dev/null 2>&1; then
    echo "✅ Redis缓存: 连接正常"
else
    echo "❌ Redis缓存: 连接异常"
fi

if pg_isready -h localhost -p 5432 > /dev/null 2>&1; then
    echo "✅ PostgreSQL数据库: 连接正常"
else
    echo "❌ PostgreSQL数据库: 连接异常"
fi
EOF

chmod +x /opt/dao-services/health-check.sh

echo "✅ 腾讯云DAO原生部署环境准备完成！"
echo "📋 部署摘要:"
echo "  - 开发环境: Go 1.21, Python 3.11, Node.js 18"
echo "  - 数据库: MySQL 8.0, Redis, PostgreSQL 14"
echo "  - 服务端口: 9502(Resume), 7531(Job), 9503(Governance), 8206(AI)"
echo "  - 系统服务: systemd服务已配置"
echo "  - 成本优化: 无Docker容器费用 ✅"
echo ""
echo "🎯 下一步: 上传DAO服务代码并启动服务"
REMOTE_SCRIPT

echo "🌐 腾讯云原生部署完成！"
echo "💰 成本优化: 避免了Docker容器额外费用"
echo "🚀 下一步: 上传DAO服务代码到 /opt/dao-services/ 目录"
