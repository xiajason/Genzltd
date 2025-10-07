-- 区块链版数据库初始化脚本
-- 用途: 为区块链版创建完整的数据库表结构
-- 创建时间: 2025-10-05
-- 版本: v1.0
-- 数据库: jobfirst_blockchain

-- 创建数据库
CREATE DATABASE IF NOT EXISTS jobfirst_blockchain CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE jobfirst_blockchain;

-- ==================== 用户管理模块 ====================

-- 1. 区块链用户表
CREATE TABLE IF NOT EXISTS blockchain_users (
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
    role ENUM('admin', 'trader', 'investor', 'guest') DEFAULT 'trader',
    email_verified BOOLEAN DEFAULT FALSE,
    phone_verified BOOLEAN DEFAULT FALSE,
    kyc_status ENUM('pending', 'verified', 'rejected') DEFAULT 'pending',
    kyc_level TINYINT DEFAULT 0,
    last_login_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    
    INDEX idx_uuid (uuid),
    INDEX idx_username (username),
    INDEX idx_email (email),
    INDEX idx_status (status),
    INDEX idx_role (role),
    INDEX idx_kyc_status (kyc_status),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. 区块链用户资料表
CREATE TABLE IF NOT EXISTS blockchain_user_profiles (
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
    trading_experience ENUM('beginner', 'intermediate', 'advanced', 'expert') DEFAULT 'beginner',
    risk_tolerance ENUM('conservative', 'moderate', 'aggressive') DEFAULT 'moderate',
    investment_goals JSON,
    trading_score DECIMAL(10,2) DEFAULT 0.00,
    portfolio_value DECIMAL(20,8) DEFAULT 0.00000000,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES blockchain_users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_trading_experience (trading_experience),
    INDEX idx_risk_tolerance (risk_tolerance),
    INDEX idx_trading_score (trading_score),
    INDEX idx_portfolio_value (portfolio_value)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==================== 钱包管理模块 ====================

-- 3. 数字钱包表
CREATE TABLE IF NOT EXISTS blockchain_wallets (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    wallet_address VARCHAR(100) NOT NULL UNIQUE,
    wallet_name VARCHAR(100),
    wallet_type ENUM('hd', 'single', 'multi_sig', 'contract') DEFAULT 'hd',
    network ENUM('ethereum', 'bitcoin', 'polygon', 'bsc', 'arbitrum', 'solana') DEFAULT 'ethereum',
    derivation_path VARCHAR(200),
    public_key VARCHAR(200),
    encrypted_private_key TEXT,
    is_primary BOOLEAN DEFAULT FALSE,
    is_hot_wallet BOOLEAN DEFAULT TRUE,
    balance_usd DECIMAL(20,2) DEFAULT 0.00,
    last_sync_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES blockchain_users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_wallet_address (wallet_address),
    INDEX idx_wallet_type (wallet_type),
    INDEX idx_network (network),
    INDEX idx_is_primary (is_primary),
    INDEX idx_is_hot_wallet (is_hot_wallet)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. 代币信息表
CREATE TABLE IF NOT EXISTS blockchain_tokens (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    symbol VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    contract_address VARCHAR(100),
    network ENUM('ethereum', 'bitcoin', 'polygon', 'bsc', 'arbitrum', 'solana') DEFAULT 'ethereum',
    decimals TINYINT DEFAULT 18,
    token_type ENUM('native', 'erc20', 'erc721', 'erc1155', 'bep20') DEFAULT 'erc20',
    is_native BOOLEAN DEFAULT FALSE,
    logo_url VARCHAR(500),
    description TEXT,
    website VARCHAR(500),
    whitepaper_url VARCHAR(500),
    total_supply DECIMAL(30,18) DEFAULT 0.000000000000000000,
    circulating_supply DECIMAL(30,18) DEFAULT 0.000000000000000000,
    market_cap DECIMAL(20,2) DEFAULT 0.00,
    price_usd DECIMAL(20,8) DEFAULT 0.00000000,
    price_change_24h DECIMAL(8,4) DEFAULT 0.0000,
    volume_24h DECIMAL(20,2) DEFAULT 0.00,
    status ENUM('active', 'inactive', 'delisted') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_symbol (symbol),
    INDEX idx_contract_address (contract_address),
    INDEX idx_network (network),
    INDEX idx_token_type (token_type),
    INDEX idx_is_native (is_native),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. 钱包余额表
CREATE TABLE IF NOT EXISTS blockchain_wallet_balances (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    wallet_id BIGINT UNSIGNED NOT NULL,
    token_id BIGINT UNSIGNED NOT NULL,
    balance DECIMAL(30,18) DEFAULT 0.000000000000000000,
    locked_balance DECIMAL(30,18) DEFAULT 0.000000000000000000,
    pending_balance DECIMAL(30,18) DEFAULT 0.000000000000000000,
    balance_usd DECIMAL(20,2) DEFAULT 0.00,
    last_price DECIMAL(20,8) DEFAULT 0.00000000,
    last_sync_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (wallet_id) REFERENCES blockchain_wallets(id) ON DELETE CASCADE,
    FOREIGN KEY (token_id) REFERENCES blockchain_tokens(id) ON DELETE CASCADE,
    UNIQUE KEY unique_wallet_token (wallet_id, token_id),
    INDEX idx_wallet_id (wallet_id),
    INDEX idx_token_id (token_id),
    INDEX idx_balance (balance),
    INDEX idx_balance_usd (balance_usd),
    INDEX idx_last_sync_at (last_sync_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==================== 交易管理模块 ====================

-- 6. 交易记录表
CREATE TABLE IF NOT EXISTS blockchain_transactions (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    uuid VARCHAR(36) NOT NULL UNIQUE,
    user_id BIGINT UNSIGNED NOT NULL,
    wallet_id BIGINT UNSIGNED NOT NULL,
    tx_hash VARCHAR(100) NOT NULL UNIQUE,
    block_number BIGINT,
    block_hash VARCHAR(100),
    from_address VARCHAR(100),
    to_address VARCHAR(100),
    token_id BIGINT UNSIGNED,
    amount DECIMAL(30,18) NOT NULL,
    amount_usd DECIMAL(20,2) DEFAULT 0.00,
    gas_price DECIMAL(20,8) DEFAULT 0.00000000,
    gas_used BIGINT DEFAULT 0,
    gas_fee DECIMAL(20,8) DEFAULT 0.00000000,
    network_fee DECIMAL(20,8) DEFAULT 0.00000000,
    transaction_type ENUM('send', 'receive', 'swap', 'stake', 'unstake', 'contract') DEFAULT 'send',
    status ENUM('pending', 'confirmed', 'failed', 'cancelled') DEFAULT 'pending',
    confirmation_count INT DEFAULT 0,
    network ENUM('ethereum', 'bitcoin', 'polygon', 'bsc', 'arbitrum', 'solana') DEFAULT 'ethereum',
    memo TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES blockchain_users(id) ON DELETE CASCADE,
    FOREIGN KEY (wallet_id) REFERENCES blockchain_wallets(id) ON DELETE CASCADE,
    FOREIGN KEY (token_id) REFERENCES blockchain_tokens(id) ON DELETE SET NULL,
    INDEX idx_uuid (uuid),
    INDEX idx_user_id (user_id),
    INDEX idx_wallet_id (wallet_id),
    INDEX idx_tx_hash (tx_hash),
    INDEX idx_block_number (block_number),
    INDEX idx_from_address (from_address),
    INDEX idx_to_address (to_address),
    INDEX idx_token_id (token_id),
    INDEX idx_transaction_type (transaction_type),
    INDEX idx_status (status),
    INDEX idx_network (network),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 7. 交易状态历史表
CREATE TABLE IF NOT EXISTS blockchain_transaction_status_history (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    transaction_id BIGINT UNSIGNED NOT NULL,
    old_status ENUM('pending', 'confirmed', 'failed', 'cancelled'),
    new_status ENUM('pending', 'confirmed', 'failed', 'cancelled') NOT NULL,
    confirmation_count INT DEFAULT 0,
    block_number BIGINT,
    tx_hash VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (transaction_id) REFERENCES blockchain_transactions(id) ON DELETE CASCADE,
    INDEX idx_transaction_id (transaction_id),
    INDEX idx_new_status (new_status),
    INDEX idx_block_number (block_number),
    INDEX idx_tx_hash (tx_hash),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 8. 交易对表
CREATE TABLE IF NOT EXISTS blockchain_trading_pairs (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    base_token_id BIGINT UNSIGNED NOT NULL,
    quote_token_id BIGINT UNSIGNED NOT NULL,
    symbol VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    network ENUM('ethereum', 'bitcoin', 'polygon', 'bsc', 'arbitrum', 'solana') DEFAULT 'ethereum',
    price DECIMAL(20,8) DEFAULT 0.00000000,
    price_change_24h DECIMAL(8,4) DEFAULT 0.0000,
    volume_24h DECIMAL(20,2) DEFAULT 0.00,
    high_24h DECIMAL(20,8) DEFAULT 0.00000000,
    low_24h DECIMAL(20,8) DEFAULT 0.00000000,
    market_cap DECIMAL(20,2) DEFAULT 0.00,
    liquidity DECIMAL(20,2) DEFAULT 0.00,
    status ENUM('active', 'inactive', 'suspended') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (base_token_id) REFERENCES blockchain_tokens(id) ON DELETE CASCADE,
    FOREIGN KEY (quote_token_id) REFERENCES blockchain_tokens(id) ON DELETE CASCADE,
    INDEX idx_symbol (symbol),
    INDEX idx_base_token_id (base_token_id),
    INDEX idx_quote_token_id (quote_token_id),
    INDEX idx_network (network),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==================== 智能合约模块 ====================

-- 9. 智能合约表
CREATE TABLE IF NOT EXISTS blockchain_smart_contracts (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    uuid VARCHAR(36) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    contract_address VARCHAR(100) NOT NULL UNIQUE,
    network ENUM('ethereum', 'bitcoin', 'polygon', 'bsc', 'arbitrum', 'solana') DEFAULT 'ethereum',
    contract_type ENUM('token', 'dex', 'defi', 'nft', 'game', 'other') DEFAULT 'other',
    abi JSON,
    bytecode TEXT,
    source_code TEXT,
    compiler_version VARCHAR(50),
    deployment_tx_hash VARCHAR(100),
    deployment_block BIGINT,
    creator_id BIGINT UNSIGNED NOT NULL,
    is_verified BOOLEAN DEFAULT FALSE,
    verification_status ENUM('pending', 'verified', 'failed') DEFAULT 'pending',
    status ENUM('active', 'inactive', 'paused') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (creator_id) REFERENCES blockchain_users(id) ON DELETE CASCADE,
    INDEX idx_uuid (uuid),
    INDEX idx_contract_address (contract_address),
    INDEX idx_network (network),
    INDEX idx_contract_type (contract_type),
    INDEX idx_creator_id (creator_id),
    INDEX idx_verification_status (verification_status),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 10. 合约调用记录表
CREATE TABLE IF NOT EXISTS blockchain_contract_calls (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    contract_id BIGINT UNSIGNED NOT NULL,
    user_id BIGINT UNSIGNED NOT NULL,
    tx_hash VARCHAR(100) NOT NULL,
    function_name VARCHAR(100) NOT NULL,
    function_params JSON,
    return_value JSON,
    gas_used BIGINT DEFAULT 0,
    gas_price DECIMAL(20,8) DEFAULT 0.00000000,
    gas_fee DECIMAL(20,8) DEFAULT 0.00000000,
    block_number BIGINT,
    status ENUM('pending', 'success', 'failed') DEFAULT 'pending',
    error_message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (contract_id) REFERENCES blockchain_smart_contracts(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES blockchain_users(id) ON DELETE CASCADE,
    INDEX idx_contract_id (contract_id),
    INDEX idx_user_id (user_id),
    INDEX idx_tx_hash (tx_hash),
    INDEX idx_function_name (function_name),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 11. DeFi协议表
CREATE TABLE IF NOT EXISTS blockchain_defi_protocols (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    website VARCHAR(500),
    logo_url VARCHAR(500),
    protocol_type ENUM('dex', 'lending', 'staking', 'yield_farming', 'derivatives') DEFAULT 'dex',
    network ENUM('ethereum', 'bitcoin', 'polygon', 'bsc', 'arbitrum', 'solana') DEFAULT 'ethereum',
    contract_address VARCHAR(100),
    tvl DECIMAL(20,2) DEFAULT 0.00,
    apy DECIMAL(8,4) DEFAULT 0.0000,
    risk_level ENUM('low', 'medium', 'high', 'very_high') DEFAULT 'medium',
    audit_status ENUM('unaudited', 'auditing', 'audited') DEFAULT 'unaudited',
    status ENUM('active', 'inactive', 'suspended') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_name (name),
    INDEX idx_protocol_type (protocol_type),
    INDEX idx_network (network),
    INDEX idx_contract_address (contract_address),
    INDEX idx_risk_level (risk_level),
    INDEX idx_audit_status (audit_status),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==================== DeFi集成模块 ====================

-- 12. 流动性挖矿表
CREATE TABLE IF NOT EXISTS blockchain_liquidity_mining (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    protocol_id BIGINT UNSIGNED NOT NULL,
    pool_id VARCHAR(100) NOT NULL,
    token_pair VARCHAR(50) NOT NULL,
    lp_token_amount DECIMAL(30,18) DEFAULT 0.000000000000000000,
    staked_amount DECIMAL(30,18) DEFAULT 0.000000000000000000,
    reward_token_id BIGINT UNSIGNED,
    pending_rewards DECIMAL(30,18) DEFAULT 0.000000000000000000,
    claimed_rewards DECIMAL(30,18) DEFAULT 0.000000000000000000,
    apy DECIMAL(8,4) DEFAULT 0.0000,
    start_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    end_date TIMESTAMP NULL,
    status ENUM('active', 'completed', 'cancelled') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES blockchain_users(id) ON DELETE CASCADE,
    FOREIGN KEY (protocol_id) REFERENCES blockchain_defi_protocols(id) ON DELETE CASCADE,
    FOREIGN KEY (reward_token_id) REFERENCES blockchain_tokens(id) ON DELETE SET NULL,
    INDEX idx_user_id (user_id),
    INDEX idx_protocol_id (protocol_id),
    INDEX idx_pool_id (pool_id),
    INDEX idx_token_pair (token_pair),
    INDEX idx_status (status),
    INDEX idx_start_date (start_date),
    INDEX idx_end_date (end_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 13. 质押记录表
CREATE TABLE IF NOT EXISTS blockchain_staking_records (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    token_id BIGINT UNSIGNED NOT NULL,
    staking_pool_id VARCHAR(100) NOT NULL,
    staked_amount DECIMAL(30,18) NOT NULL,
    reward_token_id BIGINT UNSIGNED,
    pending_rewards DECIMAL(30,18) DEFAULT 0.000000000000000000,
    claimed_rewards DECIMAL(30,18) DEFAULT 0.000000000000000000,
    apy DECIMAL(8,4) DEFAULT 0.0000,
    lock_period INT DEFAULT 0,
    unlock_date TIMESTAMP NULL,
    auto_compound BOOLEAN DEFAULT FALSE,
    status ENUM('active', 'unlocked', 'claimed') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES blockchain_users(id) ON DELETE CASCADE,
    FOREIGN KEY (token_id) REFERENCES blockchain_tokens(id) ON DELETE CASCADE,
    FOREIGN KEY (reward_token_id) REFERENCES blockchain_tokens(id) ON DELETE SET NULL,
    INDEX idx_user_id (user_id),
    INDEX idx_token_id (token_id),
    INDEX idx_staking_pool_id (staking_pool_id),
    INDEX idx_status (status),
    INDEX idx_unlock_date (unlock_date),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==================== 系统管理模块 ====================

-- 14. 区块链会话表
CREATE TABLE IF NOT EXISTS blockchain_sessions (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    session_token VARCHAR(255) NOT NULL UNIQUE,
    refresh_token VARCHAR(255) NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    ip_address VARCHAR(45),
    user_agent TEXT,
    device_info JSON,
    wallet_connected BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES blockchain_users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_session_token (session_token),
    INDEX idx_refresh_token (refresh_token),
    INDEX idx_expires_at (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 15. 区块链通知表
CREATE TABLE IF NOT EXISTS blockchain_notifications (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    type ENUM('transaction', 'price_alert', 'defi_reward', 'security', 'system') DEFAULT 'system',
    status ENUM('unread', 'read', 'archived') DEFAULT 'unread',
    reference_id BIGINT UNSIGNED,
    reference_type VARCHAR(50),
    priority ENUM('low', 'medium', 'high', 'urgent') DEFAULT 'medium',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES blockchain_users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_type (type),
    INDEX idx_status (status),
    INDEX idx_priority (priority),
    INDEX idx_reference (reference_id, reference_type),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 16. 区块链审计日志表
CREATE TABLE IF NOT EXISTS blockchain_audit_logs (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED,
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(50) NOT NULL,
    resource_id BIGINT UNSIGNED,
    old_values JSON,
    new_values JSON,
    tx_hash VARCHAR(100),
    block_number BIGINT,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES blockchain_users(id) ON DELETE SET NULL,
    INDEX idx_user_id (user_id),
    INDEX idx_action (action),
    INDEX idx_resource (resource_type, resource_id),
    INDEX idx_tx_hash (tx_hash),
    INDEX idx_block_number (block_number),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 17. 区块链同步状态表
CREATE TABLE IF NOT EXISTS blockchain_sync_status (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    network ENUM('ethereum', 'bitcoin', 'polygon', 'bsc', 'arbitrum', 'solana') NOT NULL UNIQUE,
    last_sync_block BIGINT DEFAULT 0,
    current_block BIGINT DEFAULT 0,
    sync_status ENUM('syncing', 'completed', 'error', 'paused') DEFAULT 'syncing',
    error_message TEXT,
    last_sync_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_network (network),
    INDEX idx_sync_status (sync_status),
    INDEX idx_last_sync_at (last_sync_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==================== 初始化数据 ====================

-- 插入主要加密货币代币
INSERT INTO blockchain_tokens (symbol, name, network, token_type, is_native, decimals, status) VALUES
('ETH', 'Ethereum', 'ethereum', 'native', TRUE, 18, 'active'),
('BTC', 'Bitcoin', 'bitcoin', 'native', TRUE, 8, 'active'),
('MATIC', 'Polygon', 'polygon', 'native', TRUE, 18, 'active'),
('BNB', 'Binance Coin', 'bsc', 'native', TRUE, 18, 'active'),
('ARB', 'Arbitrum', 'arbitrum', 'native', TRUE, 18, 'active'),
('SOL', 'Solana', 'solana', 'native', TRUE, 9, 'active'),
('USDT', 'Tether USD', 'ethereum', 'erc20', FALSE, 6, 'active'),
('USDC', 'USD Coin', 'ethereum', 'erc20', FALSE, 6, 'active'),
('DAI', 'Dai Stablecoin', 'ethereum', 'erc20', FALSE, 18, 'active'),
('UNI', 'Uniswap', 'ethereum', 'erc20', FALSE, 18, 'active')
ON DUPLICATE KEY UPDATE name = VALUES(name);

-- 插入主要交易对
INSERT INTO blockchain_trading_pairs (base_token_id, quote_token_id, symbol, name, network) 
SELECT 
    bt.id, qt.id, 
    CONCAT(bt.symbol, '/', qt.symbol),
    CONCAT(bt.name, '/', qt.name),
    'ethereum'
FROM blockchain_tokens bt, blockchain_tokens qt 
WHERE bt.symbol IN ('ETH', 'UNI') AND qt.symbol IN ('USDT', 'USDC', 'DAI')
ON DUPLICATE KEY UPDATE name = VALUES(name);

-- 插入主要DeFi协议
INSERT INTO blockchain_defi_protocols (name, description, protocol_type, network, risk_level, audit_status, status) VALUES
('Uniswap V3', '去中心化交易协议', 'dex', 'ethereum', 'medium', 'audited', 'active'),
('Compound', '去中心化借贷协议', 'lending', 'ethereum', 'medium', 'audited', 'active'),
('Aave', '去中心化借贷协议', 'lending', 'ethereum', 'medium', 'audited', 'active'),
('Curve', '稳定币交易协议', 'dex', 'ethereum', 'low', 'audited', 'active'),
('Yearn Finance', '收益聚合协议', 'yield_farming', 'ethereum', 'high', 'audited', 'active'),
('PancakeSwap', 'BSC去中心化交易协议', 'dex', 'bsc', 'medium', 'audited', 'active'),
('QuickSwap', 'Polygon去中心化交易协议', 'dex', 'polygon', 'medium', 'audited', 'active')
ON DUPLICATE KEY UPDATE description = VALUES(description);

-- 初始化区块链同步状态
INSERT INTO blockchain_sync_status (network, sync_status, last_sync_block, current_block) VALUES
('ethereum', 'syncing', 0, 0),
('bitcoin', 'syncing', 0, 0),
('polygon', 'syncing', 0, 0),
('bsc', 'syncing', 0, 0),
('arbitrum', 'syncing', 0, 0),
('solana', 'syncing', 0, 0)
ON DUPLICATE KEY UPDATE sync_status = VALUES(sync_status);

-- 创建默认管理员用户
INSERT INTO blockchain_users (
    uuid, username, email, password_hash, first_name, last_name,
    status, role, email_verified, kyc_status, kyc_level
) VALUES (
    'blockchain-user-001',
    'blockchain_admin',
    'admin@jobfirst-blockchain.com',
    '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', -- password
    'Blockchain',
    'Administrator',
    'active',
    'admin',
    TRUE,
    'verified',
    3
) ON DUPLICATE KEY UPDATE username = VALUES(username);

-- ==================== 创建视图 ====================

-- 创建用户钱包视图
CREATE OR REPLACE VIEW v_user_wallets AS
SELECT 
    w.id,
    w.user_id,
    u.username,
    w.wallet_address,
    w.wallet_name,
    w.wallet_type,
    w.network,
    w.is_primary,
    w.is_hot_wallet,
    w.balance_usd,
    w.last_sync_at,
    w.created_at
FROM blockchain_wallets w
JOIN blockchain_users u ON w.user_id = u.id
WHERE w.id IS NOT NULL;

-- 创建用户交易视图
CREATE OR REPLACE VIEW v_user_transactions AS
SELECT 
    t.id,
    t.uuid,
    t.user_id,
    u.username,
    t.wallet_id,
    w.wallet_address,
    t.tx_hash,
    t.amount,
    t.amount_usd,
    t.transaction_type,
    t.status,
    t.network,
    tk.symbol as token_symbol,
    t.created_at
FROM blockchain_transactions t
JOIN blockchain_users u ON t.user_id = u.id
JOIN blockchain_wallets w ON t.wallet_id = w.id
LEFT JOIN blockchain_tokens tk ON t.token_id = tk.id;

-- 创建活跃质押视图
CREATE OR REPLACE VIEW v_active_staking AS
SELECT 
    s.id,
    s.user_id,
    u.username,
    s.token_id,
    t.symbol as token_symbol,
    s.staked_amount,
    s.pending_rewards,
    s.apy,
    s.unlock_date,
    s.auto_compound,
    s.created_at
FROM blockchain_staking_records s
JOIN blockchain_users u ON s.user_id = u.id
JOIN blockchain_tokens t ON s.token_id = t.id
WHERE s.status = 'active';

-- ==================== 创建存储过程 ====================

DELIMITER //

-- 创建更新交易状态的存储过程
CREATE PROCEDURE UpdateTransactionStatus(
    IN transaction_uuid VARCHAR(36),
    IN new_status VARCHAR(20),
    IN confirmation_count INT,
    IN block_number BIGINT
)
BEGIN
    DECLARE transaction_id BIGINT;
    DECLARE old_status VARCHAR(20);
    
    -- 获取交易ID和原状态
    SELECT id, status INTO transaction_id, old_status
    FROM blockchain_transactions
    WHERE uuid = transaction_uuid;
    
    -- 更新交易状态
    UPDATE blockchain_transactions
    SET 
        status = new_status,
        confirmation_count = confirmation_count,
        block_number = block_number,
        updated_at = CURRENT_TIMESTAMP
    WHERE uuid = transaction_uuid;
    
    -- 插入状态历史记录
    INSERT INTO blockchain_transaction_status_history 
    (transaction_id, old_status, new_status, confirmation_count, block_number, tx_hash)
    SELECT 
        transaction_id, 
        old_status, 
        new_status, 
        confirmation_count, 
        block_number,
        tx_hash
    FROM blockchain_transactions
    WHERE id = transaction_id;
END //

-- 创建计算钱包总价值的存储过程
CREATE PROCEDURE CalculateWalletValue(IN wallet_id BIGINT, OUT total_value_usd DECIMAL(20,2))
BEGIN
    DECLARE wallet_value DECIMAL(20,2) DEFAULT 0.00;
    
    -- 计算钱包总价值
    SELECT COALESCE(SUM(balance_usd), 0)
    INTO wallet_value
    FROM blockchain_wallet_balances
    WHERE wallet_id = wallet_id;
    
    -- 更新钱包表
    UPDATE blockchain_wallets 
    SET 
        balance_usd = wallet_value,
        last_sync_at = CURRENT_TIMESTAMP,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = wallet_id;
    
    SET total_value_usd = wallet_value;
END //

-- 创建同步代币价格的存储过程
CREATE PROCEDURE SyncTokenPrice(
    IN token_symbol VARCHAR(20),
    IN new_price_usd DECIMAL(20,8),
    IN price_change_24h DECIMAL(8,4),
    IN volume_24h DECIMAL(20,2),
    IN market_cap DECIMAL(20,2)
)
BEGIN
    -- 更新代币价格信息
    UPDATE blockchain_tokens
    SET 
        price_usd = new_price_usd,
        price_change_24h = price_change_24h,
        volume_24h = volume_24h,
        market_cap = market_cap,
        updated_at = CURRENT_TIMESTAMP
    WHERE symbol = token_symbol;
    
    -- 更新所有相关钱包余额的USD价值
    UPDATE blockchain_wallet_balances wb
    JOIN blockchain_tokens t ON wb.token_id = t.id
    SET 
        wb.balance_usd = wb.balance * new_price_usd,
        wb.last_price = new_price_usd,
        wb.updated_at = CURRENT_TIMESTAMP
    WHERE t.symbol = token_symbol;
END //

DELIMITER ;

-- ==================== 创建触发器 ====================

-- 创建交易后自动更新钱包余额的触发器
DELIMITER //
CREATE TRIGGER tr_update_wallet_balance_after_transaction
AFTER INSERT ON blockchain_transactions
FOR EACH ROW
BEGIN
    -- 更新相关钱包余额
    IF NEW.transaction_type = 'send' THEN
        UPDATE blockchain_wallet_balances 
        SET balance = balance - NEW.amount,
            balance_usd = balance_usd - NEW.amount_usd,
            updated_at = CURRENT_TIMESTAMP
        WHERE wallet_id = NEW.wallet_id AND token_id = NEW.token_id;
    ELSEIF NEW.transaction_type = 'receive' THEN
        INSERT INTO blockchain_wallet_balances (wallet_id, token_id, balance, balance_usd, last_price)
        VALUES (NEW.wallet_id, NEW.token_id, NEW.amount, NEW.amount_usd, NEW.amount_usd / NEW.amount)
        ON DUPLICATE KEY UPDATE 
            balance = balance + NEW.amount,
            balance_usd = balance_usd + NEW.amount_usd,
            updated_at = CURRENT_TIMESTAMP;
    END IF;
END //
DELIMITER ;

-- 创建用户注册后自动创建默认钱包的触发器
DELIMITER //
CREATE TRIGGER tr_create_default_wallet_after_registration
AFTER INSERT ON blockchain_users
FOR EACH ROW
BEGIN
    -- 为每个网络创建默认钱包（仅创建记录，实际钱包地址需要用户生成）
    INSERT INTO blockchain_wallets (user_id, wallet_address, wallet_name, wallet_type, network, is_primary)
    SELECT 
        NEW.id,
        CONCAT('pending_', NEW.id, '_', network),
        CONCAT('Default ', network, ' Wallet'),
        'hd',
        network,
        CASE WHEN network = 'ethereum' THEN TRUE ELSE FALSE END
    FROM (
        SELECT 'ethereum' as network
        UNION SELECT 'bitcoin'
        UNION SELECT 'polygon'
        UNION SELECT 'bsc'
        UNION SELECT 'arbitrum'
        UNION SELECT 'solana'
    ) networks;
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
WHERE TABLE_SCHEMA = 'jobfirst_blockchain'
ORDER BY TABLE_NAME;

-- 显示外键约束信息
SELECT 
    CONSTRAINT_NAME as '约束名',
    TABLE_NAME as '表名',
    COLUMN_NAME as '字段名',
    REFERENCED_TABLE_NAME as '引用表名',
    REFERENCED_COLUMN_NAME as '引用字段名'
FROM information_schema.KEY_COLUMN_USAGE 
WHERE TABLE_SCHEMA = 'jobfirst_blockchain' 
    AND REFERENCED_TABLE_NAME IS NOT NULL
ORDER BY TABLE_NAME, CONSTRAINT_NAME;

-- 显示索引信息
SELECT 
    TABLE_NAME as '表名',
    INDEX_NAME as '索引名',
    COLUMN_NAME as '字段名',
    NON_UNIQUE as '是否唯一'
FROM information_schema.STATISTICS 
WHERE TABLE_SCHEMA = 'jobfirst_blockchain'
ORDER BY TABLE_NAME, INDEX_NAME, SEQ_IN_INDEX;

-- 完成提示
SELECT '区块链版数据库初始化完成！' as '状态';
SELECT '总共创建了 20 个表，包含完整的钱包管理、交易记录、智能合约、DeFi集成功能' as '总结';
