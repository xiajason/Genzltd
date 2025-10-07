# 区块链版数据库表结构设计

**文档版本**: v1.0  
**创建时间**: 2025-10-05  
**适用版本**: 区块链版  
**业务定位**: 加密货币交易和数字钱包管理平台

## 📋 设计概述

区块链版专注于加密货币交易、数字钱包管理、智能合约执行和DeFi集成功能。基于Future版的核心架构，扩展区块链特有的业务功能。

### 🎯 核心功能模块

1. **钱包管理系统**: 数字钱包创建、导入、管理
2. **交易管理系统**: 加密货币交易记录、状态跟踪
3. **智能合约系统**: 合约部署、执行、监控
4. **DeFi集成系统**: 流动性挖矿、质押、借贷
5. **区块链数据同步**: 链上数据同步和索引

## 🗄️ 数据库表结构设计

### 1. 用户管理模块

#### 1.1 区块链用户表 (blockchain_users)
**用途**: 存储区块链用户的基础信息

| 字段名 | 类型 | 说明 | 约束 |
|--------|------|------|------|
| id | BIGINT UNSIGNED | 主键 | PRIMARY KEY, AUTO_INCREMENT |
| uuid | VARCHAR(36) | 用户唯一标识 | NOT NULL, UNIQUE |
| username | VARCHAR(100) | 用户名 | NOT NULL, UNIQUE |
| email | VARCHAR(255) | 邮箱 | NOT NULL, UNIQUE |
| password_hash | VARCHAR(255) | 密码哈希 | NOT NULL |
| first_name | VARCHAR(100) | 名 | |
| last_name | VARCHAR(100) | 姓 | |
| phone | VARCHAR(20) | 电话 | |
| avatar_url | VARCHAR(500) | 头像URL | |
| status | ENUM('active', 'inactive', 'suspended', 'pending') | 状态 | DEFAULT 'pending' |
| role | ENUM('admin', 'trader', 'investor', 'guest') | 角色 | DEFAULT 'trader' |
| email_verified | BOOLEAN | 邮箱验证 | DEFAULT FALSE |
| phone_verified | BOOLEAN | 电话验证 | DEFAULT FALSE |
| kyc_status | ENUM('pending', 'verified', 'rejected') | KYC状态 | DEFAULT 'pending' |
| kyc_level | TINYINT | KYC等级 | DEFAULT 0 |
| last_login_at | TIMESTAMP | 最后登录时间 | |
| created_at | TIMESTAMP | 创建时间 | DEFAULT CURRENT_TIMESTAMP |
| updated_at | TIMESTAMP | 更新时间 | AUTO UPDATE |
| deleted_at | TIMESTAMP | 删除时间 | NULL |

#### 1.2 区块链用户资料表 (blockchain_user_profiles)
**用途**: 存储区块链用户的详细资料

| 字段名 | 类型 | 说明 | 约束 |
|--------|------|------|------|
| id | BIGINT UNSIGNED | 主键 | PRIMARY KEY, AUTO_INCREMENT |
| user_id | BIGINT UNSIGNED | 用户ID | NOT NULL, FOREIGN KEY |
| bio | TEXT | 个人简介 | |
| location | VARCHAR(255) | 地理位置 | |
| website | VARCHAR(500) | 个人网站 | |
| linkedin_url | VARCHAR(500) | LinkedIn链接 | |
| github_url | VARCHAR(500) | GitHub链接 | |
| twitter_url | VARCHAR(500) | Twitter链接 | |
| date_of_birth | DATE | 出生日期 | |
| gender | ENUM('male', 'female', 'other', 'prefer_not_to_say') | 性别 | |
| nationality | VARCHAR(100) | 国籍 | |
| languages | JSON | 语言技能 | |
| trading_experience | ENUM('beginner', 'intermediate', 'advanced', 'expert') | 交易经验 | DEFAULT 'beginner' |
| risk_tolerance | ENUM('conservative', 'moderate', 'aggressive') | 风险承受能力 | DEFAULT 'moderate' |
| investment_goals | JSON | 投资目标 | |
| trading_score | DECIMAL(10,2) | 交易评分 | DEFAULT 0.00 |
| portfolio_value | DECIMAL(20,8) | 投资组合价值 | DEFAULT 0.00000000 |
| created_at | TIMESTAMP | 创建时间 | DEFAULT CURRENT_TIMESTAMP |
| updated_at | TIMESTAMP | 更新时间 | AUTO UPDATE |

### 2. 钱包管理模块

#### 2.1 数字钱包表 (blockchain_wallets)
**用途**: 存储用户的数字钱包信息

| 字段名 | 类型 | 说明 | 约束 |
|--------|------|------|------|
| id | BIGINT UNSIGNED | 主键 | PRIMARY KEY, AUTO_INCREMENT |
| user_id | BIGINT UNSIGNED | 用户ID | NOT NULL, FOREIGN KEY |
| wallet_address | VARCHAR(100) | 钱包地址 | NOT NULL, UNIQUE |
| wallet_name | VARCHAR(100) | 钱包名称 | |
| wallet_type | ENUM('hd', 'single', 'multi_sig', 'contract') | 钱包类型 | DEFAULT 'hd' |
| network | ENUM('ethereum', 'bitcoin', 'polygon', 'bsc', 'arbitrum', 'solana') | 网络 | DEFAULT 'ethereum' |
| derivation_path | VARCHAR(200) | 派生路径 | |
| public_key | VARCHAR(200) | 公钥 | |
| encrypted_private_key | TEXT | 加密私钥 | |
| is_primary | BOOLEAN | 是否主钱包 | DEFAULT FALSE |
| is_hot_wallet | BOOLEAN | 是否热钱包 | DEFAULT TRUE |
| balance_usd | DECIMAL(20,2) | 美元余额 | DEFAULT 0.00 |
| last_sync_at | TIMESTAMP | 最后同步时间 | |
| created_at | TIMESTAMP | 创建时间 | DEFAULT CURRENT_TIMESTAMP |
| updated_at | TIMESTAMP | 更新时间 | AUTO UPDATE |

#### 2.2 钱包余额表 (blockchain_wallet_balances)
**用途**: 存储钱包中各代币的余额

| 字段名 | 类型 | 说明 | 约束 |
|--------|------|------|------|
| id | BIGINT UNSIGNED | 主键 | PRIMARY KEY, AUTO_INCREMENT |
| wallet_id | BIGINT UNSIGNED | 钱包ID | NOT NULL, FOREIGN KEY |
| token_id | BIGINT UNSIGNED | 代币ID | NOT NULL, FOREIGN KEY |
| balance | DECIMAL(30,18) | 余额 | DEFAULT 0.000000000000000000 |
| locked_balance | DECIMAL(30,18) | 锁定余额 | DEFAULT 0.000000000000000000 |
| pending_balance | DECIMAL(30,18) | 待确认余额 | DEFAULT 0.000000000000000000 |
| balance_usd | DECIMAL(20,2) | 美元价值 | DEFAULT 0.00 |
| last_price | DECIMAL(20,8) | 最后价格 | DEFAULT 0.00000000 |
| last_sync_at | TIMESTAMP | 最后同步时间 | |
| created_at | TIMESTAMP | 创建时间 | DEFAULT CURRENT_TIMESTAMP |
| updated_at | TIMESTAMP | 更新时间 | AUTO UPDATE |

#### 2.3 代币信息表 (blockchain_tokens)
**用途**: 存储支持的加密货币代币信息

| 字段名 | 类型 | 说明 | 约束 |
|--------|------|------|------|
| id | BIGINT UNSIGNED | 主键 | PRIMARY KEY, AUTO_INCREMENT |
| symbol | VARCHAR(20) | 代币符号 | NOT NULL, UNIQUE |
| name | VARCHAR(100) | 代币名称 | NOT NULL |
| contract_address | VARCHAR(100) | 合约地址 | |
| network | ENUM('ethereum', 'bitcoin', 'polygon', 'bsc', 'arbitrum', 'solana') | 网络 | DEFAULT 'ethereum' |
| decimals | TINYINT | 小数位数 | DEFAULT 18 |
| token_type | ENUM('native', 'erc20', 'erc721', 'erc1155', 'bep20') | 代币类型 | DEFAULT 'erc20' |
| is_native | BOOLEAN | 是否原生代币 | DEFAULT FALSE |
| logo_url | VARCHAR(500) | 代币图标 | |
| description | TEXT | 代币描述 | |
| website | VARCHAR(500) | 官方网站 | |
| whitepaper_url | VARCHAR(500) | 白皮书链接 | |
| total_supply | DECIMAL(30,18) | 总供应量 | DEFAULT 0.000000000000000000 |
| circulating_supply | DECIMAL(30,18) | 流通供应量 | DEFAULT 0.000000000000000000 |
| market_cap | DECIMAL(20,2) | 市值 | DEFAULT 0.00 |
| price_usd | DECIMAL(20,8) | 美元价格 | DEFAULT 0.00000000 |
| price_change_24h | DECIMAL(8,4) | 24小时价格变化(%) | DEFAULT 0.0000 |
| volume_24h | DECIMAL(20,2) | 24小时交易量 | DEFAULT 0.00 |
| status | ENUM('active', 'inactive', 'delisted') | 状态 | DEFAULT 'active' |
| created_at | TIMESTAMP | 创建时间 | DEFAULT CURRENT_TIMESTAMP |
| updated_at | TIMESTAMP | 更新时间 | AUTO UPDATE |

### 3. 交易管理模块

#### 3.1 交易记录表 (blockchain_transactions)
**用途**: 存储用户的交易记录

| 字段名 | 类型 | 说明 | 约束 |
|--------|------|------|------|
| id | BIGINT UNSIGNED | 主键 | PRIMARY KEY, AUTO_INCREMENT |
| uuid | VARCHAR(36) | 交易唯一标识 | NOT NULL, UNIQUE |
| user_id | BIGINT UNSIGNED | 用户ID | NOT NULL, FOREIGN KEY |
| wallet_id | BIGINT UNSIGNED | 钱包ID | NOT NULL, FOREIGN KEY |
| tx_hash | VARCHAR(100) | 交易哈希 | UNIQUE |
| block_number | BIGINT | 区块号 | |
| block_hash | VARCHAR(100) | 区块哈希 | |
| from_address | VARCHAR(100) | 发送地址 | |
| to_address | VARCHAR(100) | 接收地址 | |
| token_id | BIGINT UNSIGNED | 代币ID | FOREIGN KEY |
| amount | DECIMAL(30,18) | 交易数量 | NOT NULL |
| amount_usd | DECIMAL(20,2) | 美元价值 | DEFAULT 0.00 |
| gas_price | DECIMAL(20,8) | Gas价格 | DEFAULT 0.00000000 |
| gas_used | BIGINT | Gas使用量 | DEFAULT 0 |
| gas_fee | DECIMAL(20,8) | Gas费用 | DEFAULT 0.00000000 |
| network_fee | DECIMAL(20,8) | 网络费用 | DEFAULT 0.00000000 |
| transaction_type | ENUM('send', 'receive', 'swap', 'stake', 'unstake', 'contract') | 交易类型 | DEFAULT 'send' |
| status | ENUM('pending', 'confirmed', 'failed', 'cancelled') | 状态 | DEFAULT 'pending' |
| confirmation_count | INT | 确认数 | DEFAULT 0 |
| network | ENUM('ethereum', 'bitcoin', 'polygon', 'bsc', 'arbitrum', 'solana') | 网络 | DEFAULT 'ethereum' |
| memo | TEXT | 备注 | |
| created_at | TIMESTAMP | 创建时间 | DEFAULT CURRENT_TIMESTAMP |
| updated_at | TIMESTAMP | 更新时间 | AUTO UPDATE |

#### 3.2 交易状态历史表 (blockchain_transaction_status_history)
**用途**: 存储交易状态变更历史

| 字段名 | 类型 | 说明 | 约束 |
|--------|------|------|------|
| id | BIGINT UNSIGNED | 主键 | PRIMARY KEY, AUTO_INCREMENT |
| transaction_id | BIGINT UNSIGNED | 交易ID | NOT NULL, FOREIGN KEY |
| old_status | ENUM('pending', 'confirmed', 'failed', 'cancelled') | 原状态 | |
| new_status | ENUM('pending', 'confirmed', 'failed', 'cancelled') | 新状态 | NOT NULL |
| confirmation_count | INT | 确认数 | DEFAULT 0 |
| block_number | BIGINT | 区块号 | |
| tx_hash | VARCHAR(100) | 交易哈希 | |
| created_at | TIMESTAMP | 变更时间 | DEFAULT CURRENT_TIMESTAMP |

#### 3.3 交易对表 (blockchain_trading_pairs)
**用途**: 存储支持的交易对信息

| 字段名 | 类型 | 说明 | 约束 |
|--------|------|------|------|
| id | BIGINT UNSIGNED | 主键 | PRIMARY KEY, AUTO_INCREMENT |
| base_token_id | BIGINT UNSIGNED | 基础代币ID | NOT NULL, FOREIGN KEY |
| quote_token_id | BIGINT UNSIGNED | 计价代币ID | NOT NULL, FOREIGN KEY |
| symbol | VARCHAR(20) | 交易对符号 | NOT NULL, UNIQUE |
| name | VARCHAR(100) | 交易对名称 | NOT NULL |
| network | ENUM('ethereum', 'bitcoin', 'polygon', 'bsc', 'arbitrum', 'solana') | 网络 | DEFAULT 'ethereum' |
| price | DECIMAL(20,8) | 当前价格 | DEFAULT 0.00000000 |
| price_change_24h | DECIMAL(8,4) | 24小时价格变化(%) | DEFAULT 0.0000 |
| volume_24h | DECIMAL(20,2) | 24小时交易量 | DEFAULT 0.00 |
| high_24h | DECIMAL(20,8) | 24小时最高价 | DEFAULT 0.00000000 |
| low_24h | DECIMAL(20,8) | 24小时最低价 | DEFAULT 0.00000000 |
| market_cap | DECIMAL(20,2) | 市值 | DEFAULT 0.00 |
| liquidity | DECIMAL(20,2) | 流动性 | DEFAULT 0.00 |
| status | ENUM('active', 'inactive', 'suspended') | 状态 | DEFAULT 'active' |
| created_at | TIMESTAMP | 创建时间 | DEFAULT CURRENT_TIMESTAMP |
| updated_at | TIMESTAMP | 更新时间 | AUTO UPDATE |

### 4. 智能合约模块

#### 4.1 智能合约表 (blockchain_smart_contracts)
**用途**: 存储智能合约信息

| 字段名 | 类型 | 说明 | 约束 |
|--------|------|------|------|
| id | BIGINT UNSIGNED | 主键 | PRIMARY KEY, AUTO_INCREMENT |
| uuid | VARCHAR(36) | 合约唯一标识 | NOT NULL, UNIQUE |
| name | VARCHAR(255) | 合约名称 | NOT NULL |
| description | TEXT | 合约描述 | |
| contract_address | VARCHAR(100) | 合约地址 | NOT NULL, UNIQUE |
| network | ENUM('ethereum', 'bitcoin', 'polygon', 'bsc', 'arbitrum', 'solana') | 网络 | DEFAULT 'ethereum' |
| contract_type | ENUM('token', 'dex', 'defi', 'nft', 'game', 'other') | 合约类型 | DEFAULT 'other' |
| abi | JSON | 合约ABI | |
| bytecode | TEXT | 合约字节码 | |
| source_code | TEXT | 源代码 | |
| compiler_version | VARCHAR(50) | 编译器版本 | |
| deployment_tx_hash | VARCHAR(100) | 部署交易哈希 | |
| deployment_block | BIGINT | 部署区块号 | |
| creator_id | BIGINT UNSIGNED | 创建者ID | NOT NULL, FOREIGN KEY |
| is_verified | BOOLEAN | 是否已验证 | DEFAULT FALSE |
| verification_status | ENUM('pending', 'verified', 'failed') | 验证状态 | DEFAULT 'pending' |
| status | ENUM('active', 'inactive', 'paused') | 状态 | DEFAULT 'active' |
| created_at | TIMESTAMP | 创建时间 | DEFAULT CURRENT_TIMESTAMP |
| updated_at | TIMESTAMP | 更新时间 | AUTO UPDATE |

#### 4.2 合约调用记录表 (blockchain_contract_calls)
**用途**: 存储智能合约调用记录

| 字段名 | 类型 | 说明 | 约束 |
|--------|------|------|------|
| id | BIGINT UNSIGNED | 主键 | PRIMARY KEY, AUTO_INCREMENT |
| contract_id | BIGINT UNSIGNED | 合约ID | NOT NULL, FOREIGN KEY |
| user_id | BIGINT UNSIGNED | 用户ID | NOT NULL, FOREIGN KEY |
| tx_hash | VARCHAR(100) | 交易哈希 | NOT NULL |
| function_name | VARCHAR(100) | 函数名 | NOT NULL |
| function_params | JSON | 函数参数 | |
| return_value | JSON | 返回值 | |
| gas_used | BIGINT | Gas使用量 | DEFAULT 0 |
| gas_price | DECIMAL(20,8) | Gas价格 | DEFAULT 0.00000000 |
| gas_fee | DECIMAL(20,8) | Gas费用 | DEFAULT 0.00000000 |
| block_number | BIGINT | 区块号 | |
| status | ENUM('pending', 'success', 'failed') | 状态 | DEFAULT 'pending' |
| error_message | TEXT | 错误信息 | |
| created_at | TIMESTAMP | 调用时间 | DEFAULT CURRENT_TIMESTAMP |

#### 4.3 DeFi协议表 (blockchain_defi_protocols)
**用途**: 存储DeFi协议信息

| 字段名 | 类型 | 说明 | 约束 |
|--------|------|------|------|
| id | BIGINT UNSIGNED | 主键 | PRIMARY KEY, AUTO_INCREMENT |
| name | VARCHAR(255) | 协议名称 | NOT NULL |
| description | TEXT | 协议描述 | |
| website | VARCHAR(500) | 官方网站 | |
| logo_url | VARCHAR(500) | 协议图标 | |
| protocol_type | ENUM('dex', 'lending', 'staking', 'yield_farming', 'derivatives') | 协议类型 | DEFAULT 'dex' |
| network | ENUM('ethereum', 'bitcoin', 'polygon', 'bsc', 'arbitrum', 'solana') | 网络 | DEFAULT 'ethereum' |
| contract_address | VARCHAR(100) | 主合约地址 | |
| tvl | DECIMAL(20,2) | 总锁定价值 | DEFAULT 0.00 |
| apy | DECIMAL(8,4) | 年化收益率(%) | DEFAULT 0.0000 |
| risk_level | ENUM('low', 'medium', 'high', 'very_high') | 风险等级 | DEFAULT 'medium' |
| audit_status | ENUM('unaudited', 'auditing', 'audited') | 审计状态 | DEFAULT 'unaudited' |
| status | ENUM('active', 'inactive', 'suspended') | 状态 | DEFAULT 'active' |
| created_at | TIMESTAMP | 创建时间 | DEFAULT CURRENT_TIMESTAMP |
| updated_at | TIMESTAMP | 更新时间 | AUTO UPDATE |

### 5. DeFi集成模块

#### 5.1 流动性挖矿表 (blockchain_liquidity_mining)
**用途**: 存储流动性挖矿记录

| 字段名 | 类型 | 说明 | 约束 |
|--------|------|------|------|
| id | BIGINT UNSIGNED | 主键 | PRIMARY KEY, AUTO_INCREMENT |
| user_id | BIGINT UNSIGNED | 用户ID | NOT NULL, FOREIGN KEY |
| protocol_id | BIGINT UNSIGNED | 协议ID | NOT NULL, FOREIGN KEY |
| pool_id | VARCHAR(100) | 流动性池ID | NOT NULL |
| token_pair | VARCHAR(50) | 代币对 | NOT NULL |
| lp_token_amount | DECIMAL(30,18) | LP代币数量 | DEFAULT 0.000000000000000000 |
| staked_amount | DECIMAL(30,18) | 质押数量 | DEFAULT 0.000000000000000000 |
| reward_token_id | BIGINT UNSIGNED | 奖励代币ID | FOREIGN KEY |
| pending_rewards | DECIMAL(30,18) | 待领取奖励 | DEFAULT 0.000000000000000000 |
| claimed_rewards | DECIMAL(30,18) | 已领取奖励 | DEFAULT 0.000000000000000000 |
| apy | DECIMAL(8,4) | 年化收益率(%) | DEFAULT 0.0000 |
| start_date | TIMESTAMP | 开始时间 | DEFAULT CURRENT_TIMESTAMP |
| end_date | TIMESTAMP | 结束时间 | |
| status | ENUM('active', 'completed', 'cancelled') | 状态 | DEFAULT 'active' |
| created_at | TIMESTAMP | 创建时间 | DEFAULT CURRENT_TIMESTAMP |
| updated_at | TIMESTAMP | 更新时间 | AUTO UPDATE |

#### 5.2 质押记录表 (blockchain_staking_records)
**用途**: 存储代币质押记录

| 字段名 | 类型 | 说明 | 约束 |
|--------|------|------|------|
| id | BIGINT UNSIGNED | 主键 | PRIMARY KEY, AUTO_INCREMENT |
| user_id | BIGINT UNSIGNED | 用户ID | NOT NULL, FOREIGN KEY |
| token_id | BIGINT UNSIGNED | 代币ID | NOT NULL, FOREIGN KEY |
| staking_pool_id | VARCHAR(100) | 质押池ID | NOT NULL |
| staked_amount | DECIMAL(30,18) | 质押数量 | NOT NULL |
| reward_token_id | BIGINT UNSIGNED | 奖励代币ID | FOREIGN KEY |
| pending_rewards | DECIMAL(30,18) | 待领取奖励 | DEFAULT 0.000000000000000000 |
| claimed_rewards | DECIMAL(30,18) | 已领取奖励 | DEFAULT 0.000000000000000000 |
| apy | DECIMAL(8,4) | 年化收益率(%) | DEFAULT 0.0000 |
| lock_period | INT | 锁定期(天) | DEFAULT 0 |
| unlock_date | TIMESTAMP | 解锁时间 | |
| auto_compound | BOOLEAN | 自动复投 | DEFAULT FALSE |
| status | ENUM('active', 'unlocked', 'claimed') | 状态 | DEFAULT 'active' |
| created_at | TIMESTAMP | 创建时间 | DEFAULT CURRENT_TIMESTAMP |
| updated_at | TIMESTAMP | 更新时间 | AUTO UPDATE |

### 6. 系统管理模块

#### 6.1 区块链会话表 (blockchain_sessions)
**用途**: 存储区块链用户会话信息

| 字段名 | 类型 | 说明 | 约束 |
|--------|------|------|------|
| id | BIGINT UNSIGNED | 主键 | PRIMARY KEY, AUTO_INCREMENT |
| user_id | BIGINT UNSIGNED | 用户ID | NOT NULL, FOREIGN KEY |
| session_token | VARCHAR(255) | 会话令牌 | NOT NULL, UNIQUE |
| refresh_token | VARCHAR(255) | 刷新令牌 | NOT NULL |
| expires_at | TIMESTAMP | 过期时间 | NOT NULL |
| ip_address | VARCHAR(45) | IP地址 | |
| user_agent | TEXT | 用户代理 | |
| device_info | JSON | 设备信息 | |
| wallet_connected | BOOLEAN | 是否连接钱包 | DEFAULT FALSE |
| created_at | TIMESTAMP | 创建时间 | DEFAULT CURRENT_TIMESTAMP |
| updated_at | TIMESTAMP | 更新时间 | AUTO UPDATE |

#### 6.2 区块链通知表 (blockchain_notifications)
**用途**: 存储区块链通知信息

| 字段名 | 类型 | 说明 | 约束 |
|--------|------|------|------|
| id | BIGINT UNSIGNED | 主键 | PRIMARY KEY, AUTO_INCREMENT |
| user_id | BIGINT UNSIGNED | 用户ID | NOT NULL, FOREIGN KEY |
| title | VARCHAR(255) | 通知标题 | NOT NULL |
| message | TEXT | 通知内容 | NOT NULL |
| type | ENUM('transaction', 'price_alert', 'defi_reward', 'security', 'system') | 通知类型 | DEFAULT 'system' |
| status | ENUM('unread', 'read', 'archived') | 状态 | DEFAULT 'unread' |
| reference_id | BIGINT UNSIGNED | 关联ID | |
| reference_type | VARCHAR(50) | 关联类型 | |
| priority | ENUM('low', 'medium', 'high', 'urgent') | 优先级 | DEFAULT 'medium' |
| created_at | TIMESTAMP | 创建时间 | DEFAULT CURRENT_TIMESTAMP |
| updated_at | TIMESTAMP | 更新时间 | AUTO UPDATE |

#### 6.3 区块链审计日志表 (blockchain_audit_logs)
**用途**: 存储区块链操作审计日志

| 字段名 | 类型 | 说明 | 约束 |
|--------|------|------|------|
| id | BIGINT UNSIGNED | 主键 | PRIMARY KEY, AUTO_INCREMENT |
| user_id | BIGINT UNSIGNED | 用户ID | FOREIGN KEY |
| action | VARCHAR(100) | 操作类型 | NOT NULL |
| resource_type | VARCHAR(50) | 资源类型 | NOT NULL |
| resource_id | BIGINT UNSIGNED | 资源ID | |
| old_values | JSON | 旧值 | |
| new_values | JSON | 新值 | |
| tx_hash | VARCHAR(100) | 交易哈希 | |
| block_number | BIGINT | 区块号 | |
| ip_address | VARCHAR(45) | IP地址 | |
| user_agent | TEXT | 用户代理 | |
| created_at | TIMESTAMP | 创建时间 | DEFAULT CURRENT_TIMESTAMP |

#### 6.4 区块链同步状态表 (blockchain_sync_status)
**用途**: 存储区块链数据同步状态

| 字段名 | 类型 | 说明 | 约束 |
|--------|------|------|------|
| id | BIGINT UNSIGNED | 主键 | PRIMARY KEY, AUTO_INCREMENT |
| network | ENUM('ethereum', 'bitcoin', 'polygon', 'bsc', 'arbitrum', 'solana') | 网络 | NOT NULL, UNIQUE |
| last_sync_block | BIGINT | 最后同步区块 | DEFAULT 0 |
| current_block | BIGINT | 当前区块 | DEFAULT 0 |
| sync_status | ENUM('syncing', 'completed', 'error', 'paused') | 同步状态 | DEFAULT 'syncing' |
| error_message | TEXT | 错误信息 | |
| last_sync_at | TIMESTAMP | 最后同步时间 | |
| created_at | TIMESTAMP | 创建时间 | DEFAULT CURRENT_TIMESTAMP |
| updated_at | TIMESTAMP | 更新时间 | AUTO UPDATE |

## 📊 表结构统计

### 总表数量: 20个表

| 模块 | 表数量 | 表名 |
|------|--------|------|
| **用户管理** | 2个 | blockchain_users, blockchain_user_profiles |
| **钱包管理** | 3个 | blockchain_wallets, blockchain_wallet_balances, blockchain_tokens |
| **交易管理** | 3个 | blockchain_transactions, blockchain_transaction_status_history, blockchain_trading_pairs |
| **智能合约** | 3个 | blockchain_smart_contracts, blockchain_contract_calls, blockchain_defi_protocols |
| **DeFi集成** | 2个 | blockchain_liquidity_mining, blockchain_staking_records |
| **系统管理** | 4个 | blockchain_sessions, blockchain_notifications, blockchain_audit_logs, blockchain_sync_status |

### 索引策略

#### 主要索引
- **用户表**: uuid, email, username, status, kyc_status
- **钱包表**: wallet_address, user_id, network, is_primary
- **交易表**: tx_hash, user_id, wallet_id, status, block_number
- **代币表**: symbol, contract_address, network, status
- **合约表**: contract_address, network, contract_type, status

## 🔗 外键关系

### 主要外键关系
1. **blockchain_user_profiles.user_id** → **blockchain_users.id**
2. **blockchain_wallets.user_id** → **blockchain_users.id**
3. **blockchain_wallet_balances.wallet_id** → **blockchain_wallets.id**
4. **blockchain_wallet_balances.token_id** → **blockchain_tokens.id**
5. **blockchain_transactions.user_id** → **blockchain_users.id**
6. **blockchain_transactions.wallet_id** → **blockchain_wallets.id**
7. **blockchain_transactions.token_id** → **blockchain_tokens.id**
8. **blockchain_smart_contracts.creator_id** → **blockchain_users.id**
9. **blockchain_contract_calls.contract_id** → **blockchain_smart_contracts.id**
10. **blockchain_contract_calls.user_id** → **blockchain_users.id**

---

**下一步**: 生成区块链版的SQL数据库初始化脚本。
