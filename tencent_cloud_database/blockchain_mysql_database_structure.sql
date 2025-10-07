-- 区块链版 MySQL 数据库结构
-- 创建时间: 2025-10-05
-- 版本: Blockchain Version
-- 数据库: jobfirst_blockchain

-- 创建数据库
CREATE DATABASE IF NOT EXISTS jobfirst_blockchain CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE jobfirst_blockchain;

-- 1. 用户表 (区块链用户)
CREATE TABLE IF NOT EXISTS blockchain_users (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    wallet_address VARCHAR(42) NOT NULL UNIQUE COMMENT '钱包地址',
    username VARCHAR(50) NOT NULL UNIQUE COMMENT '用户名',
    email VARCHAR(100) UNIQUE COMMENT '邮箱',
    phone VARCHAR(20) COMMENT '手机号',
    avatar_url VARCHAR(255) COMMENT '头像URL',
    reputation_score INT DEFAULT 0 COMMENT '声誉分数',
    total_tokens DECIMAL(20,8) DEFAULT 0 COMMENT '总代币数量',
    staked_tokens DECIMAL(20,8) DEFAULT 0 COMMENT '质押代币数量',
    voting_power INT DEFAULT 0 COMMENT '投票权重',
    is_verified BOOLEAN DEFAULT FALSE COMMENT '是否验证',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_wallet_address (wallet_address),
    INDEX idx_username (username),
    INDEX idx_reputation (reputation_score),
    INDEX idx_tokens (total_tokens)
) ENGINE=InnoDB COMMENT='区块链用户表';

-- 2. 代币交易表
CREATE TABLE IF NOT EXISTS token_transactions (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    from_address VARCHAR(42) NOT NULL COMMENT '发送方地址',
    to_address VARCHAR(42) NOT NULL COMMENT '接收方地址',
    amount DECIMAL(20,8) NOT NULL COMMENT '交易数量',
    transaction_hash VARCHAR(66) NOT NULL UNIQUE COMMENT '交易哈希',
    block_number BIGINT COMMENT '区块号',
    gas_used BIGINT COMMENT '消耗的Gas',
    gas_price DECIMAL(20,8) COMMENT 'Gas价格',
    transaction_fee DECIMAL(20,8) COMMENT '交易费用',
    status ENUM('pending', 'confirmed', 'failed') DEFAULT 'pending' COMMENT '交易状态',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    confirmed_at TIMESTAMP NULL,
    INDEX idx_from_address (from_address),
    INDEX idx_to_address (to_address),
    INDEX idx_transaction_hash (transaction_hash),
    INDEX idx_block_number (block_number),
    INDEX idx_status (status)
) ENGINE=InnoDB COMMENT='代币交易表';

-- 3. 智能合约表
CREATE TABLE IF NOT EXISTS smart_contracts (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    contract_address VARCHAR(42) NOT NULL UNIQUE COMMENT '合约地址',
    contract_name VARCHAR(100) NOT NULL COMMENT '合约名称',
    contract_type ENUM('DAO', 'Token', 'NFT', 'Governance') NOT NULL COMMENT '合约类型',
    version VARCHAR(20) NOT NULL COMMENT '合约版本',
    abi TEXT COMMENT '合约ABI',
    bytecode TEXT COMMENT '合约字节码',
    creator_address VARCHAR(42) NOT NULL COMMENT '创建者地址',
    is_verified BOOLEAN DEFAULT FALSE COMMENT '是否验证',
    total_supply DECIMAL(20,8) COMMENT '总供应量',
    current_supply DECIMAL(20,8) COMMENT '当前供应量',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deployed_at TIMESTAMP NULL,
    INDEX idx_contract_address (contract_address),
    INDEX idx_contract_type (contract_type),
    INDEX idx_creator (creator_address),
    INDEX idx_verified (is_verified)
) ENGINE=InnoDB COMMENT='智能合约表';

-- 4. DAO治理表
CREATE TABLE IF NOT EXISTS dao_governance (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    dao_id BIGINT NOT NULL COMMENT 'DAO ID',
    proposal_id BIGINT NOT NULL COMMENT '提案ID',
    proposer_address VARCHAR(42) NOT NULL COMMENT '提案者地址',
    title VARCHAR(200) NOT NULL COMMENT '提案标题',
    description TEXT COMMENT '提案描述',
    proposal_type ENUM('funding', 'governance', 'technical', 'social') NOT NULL COMMENT '提案类型',
    amount DECIMAL(20,8) COMMENT '提案金额',
    voting_start_time TIMESTAMP NOT NULL COMMENT '投票开始时间',
    voting_end_time TIMESTAMP NOT NULL COMMENT '投票结束时间',
    status ENUM('draft', 'active', 'passed', 'rejected', 'executed') DEFAULT 'draft' COMMENT '提案状态',
    total_votes BIGINT DEFAULT 0 COMMENT '总投票数',
    yes_votes BIGINT DEFAULT 0 COMMENT '赞成票数',
    no_votes BIGINT DEFAULT 0 COMMENT '反对票数',
    quorum_required DECIMAL(5,2) DEFAULT 10.00 COMMENT '法定人数要求(%)',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_dao_id (dao_id),
    INDEX idx_proposal_id (proposal_id),
    INDEX idx_proposer (proposer_address),
    INDEX idx_status (status),
    INDEX idx_voting_time (voting_start_time, voting_end_time)
) ENGINE=InnoDB COMMENT='DAO治理表';

-- 5. 投票记录表
CREATE TABLE IF NOT EXISTS voting_records (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    proposal_id BIGINT NOT NULL COMMENT '提案ID',
    voter_address VARCHAR(42) NOT NULL COMMENT '投票者地址',
    vote_choice ENUM('yes', 'no', 'abstain') NOT NULL COMMENT '投票选择',
    voting_power INT NOT NULL COMMENT '投票权重',
    transaction_hash VARCHAR(66) COMMENT '交易哈希',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_proposal_voter (proposal_id, voter_address),
    INDEX idx_proposal_id (proposal_id),
    INDEX idx_voter (voter_address),
    INDEX idx_choice (vote_choice)
) ENGINE=InnoDB COMMENT='投票记录表';

-- 6. NFT资产表
CREATE TABLE IF NOT EXISTS nft_assets (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    token_id BIGINT NOT NULL COMMENT 'NFT Token ID',
    contract_address VARCHAR(42) NOT NULL COMMENT '合约地址',
    owner_address VARCHAR(42) NOT NULL COMMENT '拥有者地址',
    creator_address VARCHAR(42) NOT NULL COMMENT '创建者地址',
    name VARCHAR(200) NOT NULL COMMENT 'NFT名称',
    description TEXT COMMENT 'NFT描述',
    image_url VARCHAR(255) COMMENT '图片URL',
    metadata_url VARCHAR(255) COMMENT '元数据URL',
    attributes JSON COMMENT '属性数据',
    rarity_score DECIMAL(5,2) COMMENT '稀有度分数',
    floor_price DECIMAL(20,8) COMMENT '地板价',
    last_sale_price DECIMAL(20,8) COMMENT '最后销售价格',
    is_listed BOOLEAN DEFAULT FALSE COMMENT '是否上架',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_token_contract (token_id, contract_address),
    INDEX idx_owner (owner_address),
    INDEX idx_creator (creator_address),
    INDEX idx_contract (contract_address),
    INDEX idx_listed (is_listed),
    INDEX idx_rarity (rarity_score)
) ENGINE=InnoDB COMMENT='NFT资产表';

-- 7. 去中心化身份表
CREATE TABLE IF NOT EXISTS decentralized_identities (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    did VARCHAR(100) NOT NULL UNIQUE COMMENT '去中心化身份标识',
    wallet_address VARCHAR(42) NOT NULL COMMENT '关联钱包地址',
    public_key VARCHAR(130) NOT NULL COMMENT '公钥',
    credential_type ENUM('education', 'work', 'skill', 'achievement') NOT NULL COMMENT '凭证类型',
    credential_data JSON NOT NULL COMMENT '凭证数据',
    issuer_address VARCHAR(42) NOT NULL COMMENT '发行者地址',
    issuer_signature VARCHAR(130) NOT NULL COMMENT '发行者签名',
    is_verified BOOLEAN DEFAULT FALSE COMMENT '是否验证',
    verification_date TIMESTAMP NULL COMMENT '验证日期',
    expires_at TIMESTAMP NULL COMMENT '过期时间',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_did (did),
    INDEX idx_wallet (wallet_address),
    INDEX idx_credential_type (credential_type),
    INDEX idx_issuer (issuer_address),
    INDEX idx_verified (is_verified)
) ENGINE=InnoDB COMMENT='去中心化身份表';

-- 8. 跨链桥接表
CREATE TABLE IF NOT EXISTS cross_chain_bridges (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    source_chain VARCHAR(50) NOT NULL COMMENT '源链',
    target_chain VARCHAR(50) NOT NULL COMMENT '目标链',
    bridge_contract VARCHAR(42) NOT NULL COMMENT '桥接合约地址',
    token_address VARCHAR(42) NOT NULL COMMENT '代币合约地址',
    amount DECIMAL(20,8) NOT NULL COMMENT '桥接数量',
    transaction_hash VARCHAR(66) NOT NULL COMMENT '交易哈希',
    bridge_fee DECIMAL(20,8) COMMENT '桥接费用',
    status ENUM('pending', 'processing', 'completed', 'failed') DEFAULT 'pending' COMMENT '桥接状态',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP NULL,
    INDEX idx_source_chain (source_chain),
    INDEX idx_target_chain (target_chain),
    INDEX idx_transaction_hash (transaction_hash),
    INDEX idx_status (status)
) ENGINE=InnoDB COMMENT='跨链桥接表';

-- 9. 质押记录表
CREATE TABLE IF NOT EXISTS staking_records (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    staker_address VARCHAR(42) NOT NULL COMMENT '质押者地址',
    pool_id BIGINT NOT NULL COMMENT '质押池ID',
    amount DECIMAL(20,8) NOT NULL COMMENT '质押数量',
    staking_period INT NOT NULL COMMENT '质押期限(天)',
    apy DECIMAL(5,2) COMMENT '年化收益率(%)',
    rewards DECIMAL(20,8) DEFAULT 0 COMMENT '奖励数量',
    status ENUM('active', 'unstaking', 'completed') DEFAULT 'active' COMMENT '质押状态',
    start_time TIMESTAMP NOT NULL COMMENT '开始时间',
    end_time TIMESTAMP NOT NULL COMMENT '结束时间',
    transaction_hash VARCHAR(66) COMMENT '交易哈希',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_staker (staker_address),
    INDEX idx_pool_id (pool_id),
    INDEX idx_status (status),
    INDEX idx_time_range (start_time, end_time)
) ENGINE=InnoDB COMMENT='质押记录表';

-- 10. 流动性挖矿表
CREATE TABLE IF NOT EXISTS liquidity_mining (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    provider_address VARCHAR(42) NOT NULL COMMENT '流动性提供者地址',
    pool_address VARCHAR(42) NOT NULL COMMENT '流动性池地址',
    token_a_address VARCHAR(42) NOT NULL COMMENT '代币A地址',
    token_b_address VARCHAR(42) NOT NULL COMMENT '代币B地址',
    liquidity_amount DECIMAL(20,8) NOT NULL COMMENT '流动性数量',
    lp_tokens DECIMAL(20,8) NOT NULL COMMENT 'LP代币数量',
    farming_rewards DECIMAL(20,8) DEFAULT 0 COMMENT '挖矿奖励',
    apy DECIMAL(5,2) COMMENT '年化收益率(%)',
    is_active BOOLEAN DEFAULT TRUE COMMENT '是否活跃',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_provider (provider_address),
    INDEX idx_pool (pool_address),
    INDEX idx_tokens (token_a_address, token_b_address),
    INDEX idx_active (is_active)
) ENGINE=InnoDB COMMENT='流动性挖矿表';

-- 11. 链上事件表
CREATE TABLE IF NOT EXISTS blockchain_events (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    event_type VARCHAR(50) NOT NULL COMMENT '事件类型',
    contract_address VARCHAR(42) NOT NULL COMMENT '合约地址',
    transaction_hash VARCHAR(66) NOT NULL COMMENT '交易哈希',
    block_number BIGINT NOT NULL COMMENT '区块号',
    log_index INT NOT NULL COMMENT '日志索引',
    event_data JSON COMMENT '事件数据',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_event_type (event_type),
    INDEX idx_contract (contract_address),
    INDEX idx_transaction (transaction_hash),
    INDEX idx_block (block_number)
) ENGINE=InnoDB COMMENT='链上事件表';

-- 12. 系统配置表
CREATE TABLE IF NOT EXISTS blockchain_configs (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    config_key VARCHAR(100) NOT NULL UNIQUE COMMENT '配置键',
    config_value TEXT NOT NULL COMMENT '配置值',
    config_type ENUM('string', 'number', 'boolean', 'json') NOT NULL COMMENT '配置类型',
    description TEXT COMMENT '配置描述',
    is_active BOOLEAN DEFAULT TRUE COMMENT '是否激活',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_config_key (config_key),
    INDEX idx_active (is_active)
) ENGINE=InnoDB COMMENT='区块链系统配置表';

-- 插入初始配置数据
INSERT INTO blockchain_configs (config_key, config_value, config_type, description) VALUES
('blockchain_network', 'ethereum', 'string', '区块链网络类型'),
('gas_limit', '21000', 'number', 'Gas限制'),
('gas_price', '20000000000', 'number', 'Gas价格(wei)'),
('mining_reward', '2.0', 'number', '挖矿奖励'),
('dao_quorum', '10.0', 'number', 'DAO法定人数要求(%)'),
('nft_royalty', '2.5', 'number', 'NFT版税(%)'),
('bridge_fee_rate', '0.1', 'number', '桥接费用率(%)'),
('staking_min_amount', '100.0', 'number', '最小质押数量'),
('voting_period', '7', 'number', '投票期限(天)'),
('proposal_threshold', '1000.0', 'number', '提案门槛');

-- 创建视图：用户统计
CREATE VIEW user_statistics AS
SELECT 
    COUNT(*) as total_users,
    COUNT(CASE WHEN is_verified = TRUE THEN 1 END) as verified_users,
    AVG(reputation_score) as avg_reputation,
    SUM(total_tokens) as total_tokens_circulation,
    SUM(staked_tokens) as total_staked_tokens
FROM blockchain_users;

-- 创建视图：交易统计
CREATE VIEW transaction_statistics AS
SELECT 
    COUNT(*) as total_transactions,
    COUNT(CASE WHEN status = 'confirmed' THEN 1 END) as confirmed_transactions,
    SUM(amount) as total_volume,
    AVG(amount) as avg_transaction_amount,
    DATE(created_at) as transaction_date
FROM token_transactions
GROUP BY DATE(created_at);

-- 创建视图：DAO治理统计
CREATE VIEW dao_governance_stats AS
SELECT 
    COUNT(*) as total_proposals,
    COUNT(CASE WHEN status = 'passed' THEN 1 END) as passed_proposals,
    COUNT(CASE WHEN status = 'rejected' THEN 1 END) as rejected_proposals,
    AVG(total_votes) as avg_votes_per_proposal,
    SUM(amount) as total_proposal_amount
FROM dao_governance;
