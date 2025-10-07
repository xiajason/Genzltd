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

