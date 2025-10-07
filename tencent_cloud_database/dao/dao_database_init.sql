-- DAO版数据库初始化脚本
-- 用途: 为DAO版创建完整的数据库表结构
-- 创建时间: 2025-10-05
-- 版本: v1.0
-- 数据库: jobfirst_dao

-- 创建数据库
CREATE DATABASE IF NOT EXISTS jobfirst_dao CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE jobfirst_dao;

-- ==================== 用户管理模块 ====================

-- 1. DAO用户表
CREATE TABLE IF NOT EXISTS dao_users (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    uuid VARCHAR(36) NOT NULL UNIQUE,
    username VARCHAR(100) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    phone VARCHAR(20),
    avatar_url VARCHAR(500),
    status ENUM('active', 'inactive', 'suspended', 'pending') DEFAULT 'pending',
    role ENUM('admin', 'member', 'moderator', 'guest') DEFAULT 'member',
    email_verified BOOLEAN DEFAULT FALSE,
    phone_verified BOOLEAN DEFAULT FALSE,
    last_login_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    
    INDEX idx_uuid (uuid),
    INDEX idx_username (username),
    INDEX idx_email (email),
    INDEX idx_status (status),
    INDEX idx_role (role),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. DAO用户资料表
CREATE TABLE IF NOT EXISTS dao_user_profiles (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    bio TEXT,
    location VARCHAR(255),
    website VARCHAR(500),
    linkedin_url VARCHAR(500),
    github_url VARCHAR(500),
    twitter_url VARCHAR(500),
    date_of_birth DATE,
    gender ENUM('male', 'female', 'other', 'prefer_not_to_say'),
    nationality VARCHAR(100),
    languages JSON,
    skills JSON,
    interests JSON,
    dao_contribution_score DECIMAL(10,2) DEFAULT 0.00,
    reputation_score DECIMAL(10,2) DEFAULT 0.00,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES dao_users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_contribution_score (dao_contribution_score),
    INDEX idx_reputation_score (reputation_score)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==================== DAO治理系统模块 ====================

-- 3. DAO组织表
CREATE TABLE IF NOT EXISTS dao_organizations (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    uuid VARCHAR(36) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    logo_url VARCHAR(500),
    website VARCHAR(500),
    status ENUM('active', 'inactive', 'pending', 'suspended') DEFAULT 'pending',
    governance_model ENUM('direct', 'representative', 'hybrid') DEFAULT 'direct',
    token_symbol VARCHAR(20),
    token_name VARCHAR(100),
    total_supply DECIMAL(20,8) DEFAULT 0.00000000,
    treasury_address VARCHAR(100),
    created_by BIGINT UNSIGNED NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (created_by) REFERENCES dao_users(id) ON DELETE RESTRICT,
    INDEX idx_uuid (uuid),
    INDEX idx_name (name),
    INDEX idx_status (status),
    INDEX idx_governance_model (governance_model),
    INDEX idx_token_symbol (token_symbol),
    INDEX idx_created_by (created_by)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. DAO成员关系表
CREATE TABLE IF NOT EXISTS dao_memberships (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    dao_id BIGINT UNSIGNED NOT NULL,
    user_id BIGINT UNSIGNED NOT NULL,
    role ENUM('founder', 'admin', 'member', 'moderator') DEFAULT 'member',
    status ENUM('active', 'inactive', 'pending', 'suspended') DEFAULT 'pending',
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    left_at TIMESTAMP NULL,
    voting_power DECIMAL(10,2) DEFAULT 1.00,
    contribution_score DECIMAL(10,2) DEFAULT 0.00,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (dao_id) REFERENCES dao_organizations(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES dao_users(id) ON DELETE CASCADE,
    UNIQUE KEY unique_dao_user (dao_id, user_id),
    INDEX idx_dao_id (dao_id),
    INDEX idx_user_id (user_id),
    INDEX idx_role (role),
    INDEX idx_status (status),
    INDEX idx_voting_power (voting_power),
    INDEX idx_contribution_score (contribution_score)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. DAO提案表
CREATE TABLE IF NOT EXISTS dao_proposals (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    uuid VARCHAR(36) NOT NULL UNIQUE,
    dao_id BIGINT UNSIGNED NOT NULL,
    proposer_id BIGINT UNSIGNED NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    proposal_type ENUM('governance', 'treasury', 'technical', 'social') DEFAULT 'governance',
    status ENUM('draft', 'active', 'passed', 'rejected', 'expired') DEFAULT 'draft',
    voting_start TIMESTAMP NULL,
    voting_end TIMESTAMP NULL,
    execution_deadline TIMESTAMP NULL,
    quorum_threshold DECIMAL(5,2) DEFAULT 10.00,
    approval_threshold DECIMAL(5,2) DEFAULT 50.00,
    total_votes INT DEFAULT 0,
    yes_votes INT DEFAULT 0,
    no_votes INT DEFAULT 0,
    abstain_votes INT DEFAULT 0,
    execution_status ENUM('pending', 'executed', 'failed') DEFAULT 'pending',
    execution_result TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (dao_id) REFERENCES dao_organizations(id) ON DELETE CASCADE,
    FOREIGN KEY (proposer_id) REFERENCES dao_users(id) ON DELETE CASCADE,
    INDEX idx_uuid (uuid),
    INDEX idx_dao_id (dao_id),
    INDEX idx_proposer_id (proposer_id),
    INDEX idx_status (status),
    INDEX idx_proposal_type (proposal_type),
    INDEX idx_voting_start (voting_start),
    INDEX idx_voting_end (voting_end),
    INDEX idx_execution_status (execution_status),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 6. DAO投票记录表
CREATE TABLE IF NOT EXISTS dao_votes (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    proposal_id BIGINT UNSIGNED NOT NULL,
    voter_id BIGINT UNSIGNED NOT NULL,
    vote_type ENUM('yes', 'no', 'abstain') NOT NULL,
    voting_power DECIMAL(10,2) NOT NULL,
    reason TEXT,
    tx_hash VARCHAR(100),
    block_number BIGINT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (proposal_id) REFERENCES dao_proposals(id) ON DELETE CASCADE,
    FOREIGN KEY (voter_id) REFERENCES dao_users(id) ON DELETE CASCADE,
    UNIQUE KEY unique_proposal_voter (proposal_id, voter_id),
    INDEX idx_proposal_id (proposal_id),
    INDEX idx_voter_id (voter_id),
    INDEX idx_vote_type (vote_type),
    INDEX idx_tx_hash (tx_hash),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==================== 代币经济系统模块 ====================

-- 7. DAO代币表
CREATE TABLE IF NOT EXISTS dao_tokens (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    dao_id BIGINT UNSIGNED NOT NULL,
    symbol VARCHAR(20) NOT NULL,
    name VARCHAR(100) NOT NULL,
    decimals TINYINT DEFAULT 18,
    total_supply DECIMAL(20,8) DEFAULT 0.00000000,
    circulating_supply DECIMAL(20,8) DEFAULT 0.00000000,
    contract_address VARCHAR(100),
    network ENUM('ethereum', 'polygon', 'bsc', 'arbitrum') DEFAULT 'ethereum',
    status ENUM('active', 'inactive', 'paused') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (dao_id) REFERENCES dao_organizations(id) ON DELETE CASCADE,
    UNIQUE KEY unique_dao_symbol (dao_id, symbol),
    INDEX idx_dao_id (dao_id),
    INDEX idx_symbol (symbol),
    INDEX idx_contract_address (contract_address),
    INDEX idx_network (network),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 8. DAO钱包表
CREATE TABLE IF NOT EXISTS dao_wallets (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    wallet_address VARCHAR(100) NOT NULL UNIQUE,
    wallet_type ENUM('metamask', 'walletconnect', 'coinbase', 'ledger') DEFAULT 'metamask',
    network ENUM('ethereum', 'polygon', 'bsc', 'arbitrum') DEFAULT 'ethereum',
    is_primary BOOLEAN DEFAULT FALSE,
    is_verified BOOLEAN DEFAULT FALSE,
    balance DECIMAL(20,8) DEFAULT 0.00000000,
    last_sync_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES dao_users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_wallet_address (wallet_address),
    INDEX idx_wallet_type (wallet_type),
    INDEX idx_network (network),
    INDEX idx_is_primary (is_primary),
    INDEX idx_is_verified (is_verified)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 9. DAO代币余额表
CREATE TABLE IF NOT EXISTS dao_token_balances (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    token_id BIGINT UNSIGNED NOT NULL,
    wallet_id BIGINT UNSIGNED NOT NULL,
    balance DECIMAL(20,8) DEFAULT 0.00000000,
    locked_balance DECIMAL(20,8) DEFAULT 0.00000000,
    staked_balance DECIMAL(20,8) DEFAULT 0.00000000,
    last_sync_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES dao_users(id) ON DELETE CASCADE,
    FOREIGN KEY (token_id) REFERENCES dao_tokens(id) ON DELETE CASCADE,
    FOREIGN KEY (wallet_id) REFERENCES dao_wallets(id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_token_wallet (user_id, token_id, wallet_id),
    INDEX idx_user_id (user_id),
    INDEX idx_token_id (token_id),
    INDEX idx_wallet_id (wallet_id),
    INDEX idx_balance (balance),
    INDEX idx_last_sync_at (last_sync_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==================== 社区管理模块 ====================

-- 10. DAO积分系统表
CREATE TABLE IF NOT EXISTS dao_points (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    dao_id BIGINT UNSIGNED NOT NULL,
    total_points DECIMAL(10,2) DEFAULT 0.00,
    available_points DECIMAL(10,2) DEFAULT 0.00,
    locked_points DECIMAL(10,2) DEFAULT 0.00,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES dao_users(id) ON DELETE CASCADE,
    FOREIGN KEY (dao_id) REFERENCES dao_organizations(id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_dao (user_id, dao_id),
    INDEX idx_user_id (user_id),
    INDEX idx_dao_id (dao_id),
    INDEX idx_total_points (total_points),
    INDEX idx_available_points (available_points)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 11. DAO积分历史表
CREATE TABLE IF NOT EXISTS dao_point_history (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    dao_id BIGINT UNSIGNED NOT NULL,
    points_change DECIMAL(10,2) NOT NULL,
    change_type ENUM('earn', 'spend', 'lock', 'unlock', 'transfer') NOT NULL,
    reason VARCHAR(255),
    reference_id BIGINT UNSIGNED,
    reference_type VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES dao_users(id) ON DELETE CASCADE,
    FOREIGN KEY (dao_id) REFERENCES dao_organizations(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_dao_id (dao_id),
    INDEX idx_change_type (change_type),
    INDEX idx_reference (reference_id, reference_type),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 12. DAO奖励表
CREATE TABLE IF NOT EXISTS dao_rewards (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    dao_id BIGINT UNSIGNED NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    reward_type ENUM('token', 'nft', 'points', 'badge') DEFAULT 'points',
    reward_value DECIMAL(20,8) DEFAULT 0.00000000,
    max_recipients INT,
    criteria JSON,
    status ENUM('active', 'inactive', 'completed') DEFAULT 'active',
    start_date TIMESTAMP NULL,
    end_date TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (dao_id) REFERENCES dao_organizations(id) ON DELETE CASCADE,
    INDEX idx_dao_id (dao_id),
    INDEX idx_name (name),
    INDEX idx_reward_type (reward_type),
    INDEX idx_status (status),
    INDEX idx_start_date (start_date),
    INDEX idx_end_date (end_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==================== 系统管理模块 ====================

-- 13. DAO会话表
CREATE TABLE IF NOT EXISTS dao_sessions (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    session_token VARCHAR(255) NOT NULL UNIQUE,
    refresh_token VARCHAR(255) NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    ip_address VARCHAR(45),
    user_agent TEXT,
    device_info JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES dao_users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_session_token (session_token),
    INDEX idx_refresh_token (refresh_token),
    INDEX idx_expires_at (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 14. DAO通知表
CREATE TABLE IF NOT EXISTS dao_notifications (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    dao_id BIGINT UNSIGNED,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    type ENUM('proposal', 'vote', 'reward', 'system') DEFAULT 'system',
    status ENUM('unread', 'read', 'archived') DEFAULT 'unread',
    reference_id BIGINT UNSIGNED,
    reference_type VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES dao_users(id) ON DELETE CASCADE,
    FOREIGN KEY (dao_id) REFERENCES dao_organizations(id) ON DELETE SET NULL,
    INDEX idx_user_id (user_id),
    INDEX idx_dao_id (dao_id),
    INDEX idx_type (type),
    INDEX idx_status (status),
    INDEX idx_reference (reference_id, reference_type),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 15. DAO审计日志表
CREATE TABLE IF NOT EXISTS dao_audit_logs (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED,
    dao_id BIGINT UNSIGNED,
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(50) NOT NULL,
    resource_id BIGINT UNSIGNED,
    old_values JSON,
    new_values JSON,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES dao_users(id) ON DELETE SET NULL,
    FOREIGN KEY (dao_id) REFERENCES dao_organizations(id) ON DELETE SET NULL,
    INDEX idx_user_id (user_id),
    INDEX idx_dao_id (dao_id),
    INDEX idx_action (action),
    INDEX idx_resource (resource_type, resource_id),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==================== 初始化数据 ====================

-- 插入默认DAO组织（示例）
INSERT INTO dao_organizations (
    uuid, name, description, status, governance_model, 
    token_symbol, token_name, created_by
) VALUES (
    'dao-org-001', 
    'JobFirst DAO', 
    'JobFirst去中心化自治组织，专注于职业发展和人才管理',
    'active',
    'direct',
    'JFD',
    'JobFirst DAO Token',
    1
) ON DUPLICATE KEY UPDATE name = VALUES(name);

-- 创建默认管理员用户（示例）
INSERT INTO dao_users (
    uuid, username, email, password_hash, first_name, last_name,
    status, role, email_verified
) VALUES (
    'dao-user-001',
    'dao_admin',
    'admin@jobfirst-dao.com',
    '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', -- password
    'DAO',
    'Administrator',
    'active',
    'admin',
    TRUE
) ON DUPLICATE KEY UPDATE username = VALUES(username);

-- 创建默认DAO成员关系
INSERT INTO dao_memberships (
    dao_id, user_id, role, status, voting_power
) VALUES (
    1, 1, 'founder', 'active', 100.00
) ON DUPLICATE KEY UPDATE role = VALUES(role);

-- ==================== 创建视图 ====================

-- 创建DAO成员视图
CREATE OR REPLACE VIEW v_dao_members AS
SELECT 
    m.id,
    m.dao_id,
    o.name as dao_name,
    m.user_id,
    u.username,
    u.email,
    u.first_name,
    u.last_name,
    m.role,
    m.status,
    m.voting_power,
    m.contribution_score,
    m.joined_at
FROM dao_memberships m
JOIN dao_organizations o ON m.dao_id = o.id
JOIN dao_users u ON m.user_id = u.id
WHERE m.status = 'active';

-- 创建活跃提案视图
CREATE OR REPLACE VIEW v_active_proposals AS
SELECT 
    p.id,
    p.uuid,
    p.dao_id,
    o.name as dao_name,
    p.proposer_id,
    u.username as proposer_name,
    p.title,
    p.description,
    p.proposal_type,
    p.status,
    p.voting_start,
    p.voting_end,
    p.total_votes,
    p.yes_votes,
    p.no_votes,
    p.abstain_votes,
    p.created_at
FROM dao_proposals p
JOIN dao_organizations o ON p.dao_id = o.id
JOIN dao_users u ON p.proposer_id = u.id
WHERE p.status IN ('active', 'draft');

-- ==================== 创建存储过程 ====================

DELIMITER //

-- 创建更新提案投票统计的存储过程
CREATE PROCEDURE UpdateProposalVoteStats(IN proposal_id BIGINT)
BEGIN
    DECLARE total_count INT DEFAULT 0;
    DECLARE yes_count INT DEFAULT 0;
    DECLARE no_count INT DEFAULT 0;
    DECLARE abstain_count INT DEFAULT 0;
    
    -- 计算投票统计
    SELECT 
        COUNT(*) as total,
        SUM(CASE WHEN vote_type = 'yes' THEN 1 ELSE 0 END) as yes_votes,
        SUM(CASE WHEN vote_type = 'no' THEN 1 ELSE 0 END) as no_votes,
        SUM(CASE WHEN vote_type = 'abstain' THEN 1 ELSE 0 END) as abstain_votes
    INTO total_count, yes_count, no_count, abstain_count
    FROM dao_votes 
    WHERE proposal_id = proposal_id;
    
    -- 更新提案表
    UPDATE dao_proposals 
    SET 
        total_votes = total_count,
        yes_votes = yes_count,
        no_votes = no_count,
        abstain_votes = abstain_count,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = proposal_id;
END //

-- 创建计算用户投票权重的存储过程
CREATE PROCEDURE CalculateVotingPower(IN user_id BIGINT, IN dao_id BIGINT, OUT voting_power DECIMAL(10,2))
BEGIN
    DECLARE token_balance DECIMAL(20,8) DEFAULT 0;
    DECLARE contribution_score DECIMAL(10,2) DEFAULT 0;
    
    -- 获取用户代币余额
    SELECT COALESCE(SUM(tb.balance), 0)
    INTO token_balance
    FROM dao_token_balances tb
    JOIN dao_tokens t ON tb.token_id = t.id
    WHERE tb.user_id = user_id AND t.dao_id = dao_id;
    
    -- 获取用户贡献分数
    SELECT COALESCE(dao_contribution_score, 0)
    INTO contribution_score
    FROM dao_user_profiles
    WHERE user_id = user_id;
    
    -- 计算投票权重（代币余额 + 贡献分数）
    SET voting_power = token_balance + contribution_score;
    
    -- 更新成员关系表
    UPDATE dao_memberships 
    SET voting_power = voting_power
    WHERE user_id = user_id AND dao_id = dao_id;
END //

DELIMITER ;

-- ==================== 创建触发器 ====================

-- 创建投票后自动更新提案统计的触发器
DELIMITER //
CREATE TRIGGER tr_update_proposal_stats_after_vote
AFTER INSERT ON dao_votes
FOR EACH ROW
BEGIN
    CALL UpdateProposalVoteStats(NEW.proposal_id);
END //
DELIMITER ;

-- 创建用户注册后自动创建积分记录的触发器
DELIMITER //
CREATE TRIGGER tr_create_user_points_after_registration
AFTER INSERT ON dao_users
FOR EACH ROW
BEGIN
    INSERT INTO dao_points (user_id, dao_id, total_points, available_points)
    SELECT NEW.id, id, 0.00, 0.00
    FROM dao_organizations
    WHERE status = 'active';
END //
DELIMITER ;

-- ==================== 完成信息 ====================

-- 显示创建完成的表信息
SELECT 
    TABLE_NAME as '表名',
    TABLE_ROWS as '预估行数',
    DATA_LENGTH as '数据大小(字节)',
    INDEX_LENGTH as '索引大小(字节)',
    (DATA_LENGTH + INDEX_LENGTH) as '总大小(字节)'
FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = 'jobfirst_dao'
ORDER BY TABLE_NAME;

-- 显示外键约束信息
SELECT 
    CONSTRAINT_NAME as '约束名',
    TABLE_NAME as '表名',
    COLUMN_NAME as '字段名',
    REFERENCED_TABLE_NAME as '引用表名',
    REFERENCED_COLUMN_NAME as '引用字段名'
FROM information_schema.KEY_COLUMN_USAGE 
WHERE TABLE_SCHEMA = 'jobfirst_dao' 
    AND REFERENCED_TABLE_NAME IS NOT NULL
ORDER BY TABLE_NAME, CONSTRAINT_NAME;

-- 显示索引信息
SELECT 
    TABLE_NAME as '表名',
    INDEX_NAME as '索引名',
    COLUMN_NAME as '字段名',
    NON_UNIQUE as '是否唯一'
FROM information_schema.STATISTICS 
WHERE TABLE_SCHEMA = 'jobfirst_dao'
ORDER BY TABLE_NAME, INDEX_NAME, SEQ_IN_INDEX;

-- 完成提示
SELECT 'DAO版数据库初始化完成！' as '状态';
SELECT '总共创建了 18 个表，包含完整的DAO治理、代币经济、社区管理功能' as '总结';
