-- 区块链版 PostgreSQL 数据库结构
-- 创建时间: 2025-10-05
-- 版本: Blockchain Version
-- 数据库: b_pg

-- 创建数据库
CREATE DATABASE b_pg;

-- 连接到区块链版数据库
\c b_pg;

-- 启用必要的扩展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
CREATE EXTENSION IF NOT EXISTS "btree_gin";

-- 1. AI模型管理表
CREATE TABLE IF NOT EXISTS blockchain_ai_models (
    id BIGSERIAL PRIMARY KEY,
    model_name VARCHAR(100) NOT NULL UNIQUE,
    model_type VARCHAR(50) NOT NULL,
    version VARCHAR(20) NOT NULL,
    model_path TEXT,
    accuracy DECIMAL(5,4),
    training_data_size BIGINT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. 智能合约分析表
CREATE TABLE IF NOT EXISTS contract_ai_analysis (
    id BIGSERIAL PRIMARY KEY,
    contract_address VARCHAR(42) NOT NULL,
    analysis_type VARCHAR(50) NOT NULL,
    risk_score DECIMAL(5,2),
    security_rating VARCHAR(10),
    vulnerability_count INTEGER DEFAULT 0,
    gas_optimization_score DECIMAL(5,2),
    analysis_data JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_contract_address (contract_address),
    INDEX idx_analysis_type (analysis_type),
    INDEX idx_risk_score (risk_score)
);

-- 3. 代币价格预测表
CREATE TABLE IF NOT EXISTS token_price_predictions (
    id BIGSERIAL PRIMARY KEY,
    token_address VARCHAR(42) NOT NULL,
    prediction_date DATE NOT NULL,
    current_price DECIMAL(20,8),
    predicted_price DECIMAL(20,8),
    confidence_score DECIMAL(5,4),
    prediction_model VARCHAR(50),
    market_sentiment DECIMAL(5,4),
    volume_prediction DECIMAL(20,8),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_token_address (token_address),
    INDEX idx_prediction_date (prediction_date),
    INDEX idx_confidence (confidence_score)
);

-- 4. 交易模式识别表
CREATE TABLE IF NOT EXISTS transaction_patterns (
    id BIGSERIAL PRIMARY KEY,
    pattern_type VARCHAR(50) NOT NULL,
    from_address VARCHAR(42),
    to_address VARCHAR(42),
    amount_range_min DECIMAL(20,8),
    amount_range_max DECIMAL(20,8),
    frequency INTEGER,
    risk_level VARCHAR(20),
    pattern_data JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_pattern_type (pattern_type),
    INDEX idx_from_address (from_address),
    INDEX idx_risk_level (risk_level)
);

-- 5. 去中心化身份验证表
CREATE TABLE IF NOT EXISTS decentralized_identity_verification (
    id BIGSERIAL PRIMARY KEY,
    did VARCHAR(100) NOT NULL,
    verification_type VARCHAR(50) NOT NULL,
    verification_status VARCHAR(20) NOT NULL,
    verification_score DECIMAL(5,2),
    verification_data JSONB,
    verifier_address VARCHAR(42),
    verification_date TIMESTAMP,
    expires_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_did (did),
    INDEX idx_verification_type (verification_type),
    INDEX idx_status (verification_status)
);

-- 6. NFT元数据分析表
CREATE TABLE IF NOT EXISTS nft_metadata_analysis (
    id BIGSERIAL PRIMARY KEY,
    token_id BIGINT NOT NULL,
    contract_address VARCHAR(42) NOT NULL,
    metadata_hash VARCHAR(64),
    rarity_score DECIMAL(5,2),
    authenticity_score DECIMAL(5,2),
    market_value_estimate DECIMAL(20,8),
    attributes_analysis JSONB,
    image_analysis JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_token_contract (token_id, contract_address),
    INDEX idx_rarity_score (rarity_score),
    INDEX idx_authenticity (authenticity_score)
);

-- 7. 流动性分析表
CREATE TABLE IF NOT EXISTS liquidity_analysis (
    id BIGSERIAL PRIMARY KEY,
    pool_address VARCHAR(42) NOT NULL,
    token_a_address VARCHAR(42) NOT NULL,
    token_b_address VARCHAR(42) NOT NULL,
    liquidity_score DECIMAL(5,2),
    impermanent_loss_risk DECIMAL(5,2),
    apy_prediction DECIMAL(5,2),
    volume_analysis JSONB,
    price_impact_analysis JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_pool_address (pool_address),
    INDEX idx_tokens (token_a_address, token_b_address),
    INDEX idx_liquidity_score (liquidity_score)
);

-- 8. 治理提案分析表
CREATE TABLE IF NOT EXISTS governance_proposal_analysis (
    id BIGSERIAL PRIMARY KEY,
    proposal_id BIGINT NOT NULL,
    sentiment_analysis DECIMAL(5,4),
    community_support_score DECIMAL(5,2),
    risk_assessment VARCHAR(20),
    impact_analysis JSONB,
    voting_prediction JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_proposal_id (proposal_id),
    INDEX idx_sentiment (sentiment_analysis),
    INDEX idx_support_score (community_support_score)
);

-- 9. 跨链桥接分析表
CREATE TABLE IF NOT EXISTS cross_chain_analysis (
    id BIGSERIAL PRIMARY KEY,
    bridge_id BIGINT NOT NULL,
    source_chain VARCHAR(50) NOT NULL,
    target_chain VARCHAR(50) NOT NULL,
    security_score DECIMAL(5,2),
    efficiency_score DECIMAL(5,2),
    cost_analysis JSONB,
    risk_factors JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_bridge_id (bridge_id),
    INDEX idx_chains (source_chain, target_chain),
    INDEX idx_security (security_score)
);

-- 10. 质押收益预测表
CREATE TABLE IF NOT EXISTS staking_reward_predictions (
    id BIGSERIAL PRIMARY KEY,
    staking_pool_id BIGINT NOT NULL,
    predicted_apy DECIMAL(5,2),
    risk_score DECIMAL(5,2),
    reward_distribution JSONB,
    market_conditions JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_pool_id (staking_pool_id),
    INDEX idx_predicted_apy (predicted_apy),
    INDEX idx_risk_score (risk_score)
);

-- 11. 智能合约安全审计表
CREATE TABLE IF NOT EXISTS smart_contract_audits (
    id BIGSERIAL PRIMARY KEY,
    contract_address VARCHAR(42) NOT NULL,
    audit_type VARCHAR(50) NOT NULL,
    security_score DECIMAL(5,2),
    vulnerability_count INTEGER DEFAULT 0,
    audit_findings JSONB,
    recommendations JSONB,
    auditor_address VARCHAR(42),
    audit_date TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_contract_address (contract_address),
    INDEX idx_audit_type (audit_type),
    INDEX idx_security_score (security_score)
);

-- 12. 区块链网络分析表
CREATE TABLE IF NOT EXISTS blockchain_network_analysis (
    id BIGSERIAL PRIMARY KEY,
    network_name VARCHAR(50) NOT NULL,
    analysis_date DATE NOT NULL,
    transaction_count BIGINT,
    active_addresses BIGINT,
    network_hashrate DECIMAL(20,2),
    difficulty_level DECIMAL(20,2),
    network_health_score DECIMAL(5,2),
    congestion_analysis JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_network_date (network_name, analysis_date),
    INDEX idx_health_score (network_health_score)
);

-- 13. 代币经济模型分析表
CREATE TABLE IF NOT EXISTS tokenomics_analysis (
    id BIGSERIAL PRIMARY KEY,
    token_address VARCHAR(42) NOT NULL,
    analysis_date DATE NOT NULL,
    total_supply DECIMAL(20,8),
    circulating_supply DECIMAL(20,8),
    inflation_rate DECIMAL(5,4),
    deflation_mechanisms JSONB,
    token_distribution JSONB,
    economic_health_score DECIMAL(5,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_token_date (token_address, analysis_date),
    INDEX idx_health_score (economic_health_score)
);

-- 14. 去中心化应用分析表
CREATE TABLE IF NOT EXISTS dapp_analysis (
    id BIGSERIAL PRIMARY KEY,
    dapp_address VARCHAR(42) NOT NULL,
    dapp_name VARCHAR(100) NOT NULL,
    user_activity_score DECIMAL(5,2),
    transaction_volume DECIMAL(20,8),
    unique_users BIGINT,
    retention_rate DECIMAL(5,4),
    performance_metrics JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_dapp_address (dapp_address),
    INDEX idx_activity_score (user_activity_score),
    INDEX idx_volume (transaction_volume)
);

-- 15. 区块链事件分析表
CREATE TABLE IF NOT EXISTS blockchain_event_analysis (
    id BIGSERIAL PRIMARY KEY,
    event_hash VARCHAR(66) NOT NULL,
    event_type VARCHAR(50) NOT NULL,
    impact_score DECIMAL(5,2),
    market_reaction JSONB,
    sentiment_analysis JSONB,
    correlation_analysis JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_event_hash (event_hash),
    INDEX idx_event_type (event_type),
    INDEX idx_impact_score (impact_score)
);

-- 创建复合索引
CREATE INDEX IF NOT EXISTS idx_contract_analysis_composite ON contract_ai_analysis (contract_address, analysis_type, risk_score);
CREATE INDEX IF NOT EXISTS idx_token_predictions_composite ON token_price_predictions (token_address, prediction_date, confidence_score);
CREATE INDEX IF NOT EXISTS idx_governance_analysis_composite ON governance_proposal_analysis (proposal_id, sentiment_analysis, community_support_score);

-- 创建全文搜索索引
CREATE INDEX IF NOT EXISTS idx_contract_analysis_gin ON contract_ai_analysis USING gin (analysis_data);
CREATE INDEX IF NOT EXISTS idx_nft_metadata_gin ON nft_metadata_analysis USING gin (attributes_analysis);
CREATE INDEX IF NOT EXISTS idx_governance_analysis_gin ON governance_proposal_analysis USING gin (impact_analysis);

-- 插入初始AI模型数据
INSERT INTO blockchain_ai_models (model_name, model_type, version, model_path, accuracy, training_data_size) VALUES
('contract_security_analyzer', 'security', '1.0.0', '/models/security/v1', 0.9234, 100000),
('token_price_predictor', 'prediction', '2.1.0', '/models/prediction/v2', 0.8756, 500000),
('nft_rarity_calculator', 'analysis', '1.5.0', '/models/rarity/v1', 0.9123, 200000),
('governance_sentiment', 'nlp', '1.2.0', '/models/sentiment/v1', 0.8891, 300000),
('liquidity_optimizer', 'optimization', '1.0.0', '/models/liquidity/v1', 0.9012, 150000);

-- 创建视图：AI模型统计
CREATE VIEW ai_model_statistics AS
SELECT 
    model_type,
    COUNT(*) as model_count,
    AVG(accuracy) as avg_accuracy,
    SUM(training_data_size) as total_training_data
FROM blockchain_ai_models
WHERE is_active = TRUE
GROUP BY model_type;

-- 创建视图：智能合约安全统计
CREATE VIEW contract_security_stats AS
SELECT 
    security_rating,
    COUNT(*) as contract_count,
    AVG(risk_score) as avg_risk_score,
    AVG(vulnerability_count) as avg_vulnerabilities
FROM contract_ai_analysis
GROUP BY security_rating;

-- 创建视图：代币预测统计
CREATE VIEW token_prediction_stats AS
SELECT 
    token_address,
    COUNT(*) as prediction_count,
    AVG(confidence_score) as avg_confidence,
    AVG(predicted_price) as avg_predicted_price
FROM token_price_predictions
GROUP BY token_address;
