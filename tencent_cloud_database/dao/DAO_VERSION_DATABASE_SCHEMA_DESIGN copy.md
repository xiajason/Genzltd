# DAO版数据库表结构设计

**文档版本**: v1.0  
**创建时间**: 2025-10-05  
**适用版本**: DAO版  
**业务定位**: 去中心化自治组织管理平台

## 📋 设计概述

DAO版专注于去中心化自治组织的治理、代币经济和社区管理功能。基于Future版的核心架构，扩展DAO特有的业务功能。

### 🎯 核心功能模块

1. **DAO治理系统**: 提案管理、投票机制、治理决策
2. **代币经济系统**: 代币发行、分配、交易、质押
3. **社区管理系统**: 成员管理、权限控制、激励机制
4. **财务管理**: 资金管理、预算分配、财务审计

## 🗄️ 数据库表结构设计

### 1. 用户管理模块

#### 1.1 DAO用户表 (dao_users)
**用途**: 存储DAO成员的基础信息

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
| role | ENUM('admin', 'member', 'moderator', 'guest') | 角色 | DEFAULT 'member' |
| email_verified | BOOLEAN | 邮箱验证 | DEFAULT FALSE |
| phone_verified | BOOLEAN | 电话验证 | DEFAULT FALSE |
| last_login_at | TIMESTAMP | 最后登录时间 | |
| created_at | TIMESTAMP | 创建时间 | DEFAULT CURRENT_TIMESTAMP |
| updated_at | TIMESTAMP | 更新时间 | AUTO UPDATE |
| deleted_at | TIMESTAMP | 删除时间 | NULL |

#### 1.2 DAO用户资料表 (dao_user_profiles)
**用途**: 存储DAO成员的详细资料

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
| skills | JSON | 专业技能 | |
| interests | JSON | 兴趣爱好 | |
| dao_contribution_score | DECIMAL(10,2) | DAO贡献分数 | DEFAULT 0.00 |
| reputation_score | DECIMAL(10,2) | 声誉分数 | DEFAULT 0.00 |
| created_at | TIMESTAMP | 创建时间 | DEFAULT CURRENT_TIMESTAMP |
| updated_at | TIMESTAMP | 更新时间 | AUTO UPDATE |

### 2. DAO治理系统模块

#### 2.1 DAO组织表 (dao_organizations)
**用途**: 存储DAO组织的基本信息

| 字段名 | 类型 | 说明 | 约束 |
|--------|------|------|------|
| id | BIGINT UNSIGNED | 主键 | PRIMARY KEY, AUTO_INCREMENT |
| uuid | VARCHAR(36) | 组织唯一标识 | NOT NULL, UNIQUE |
| name | VARCHAR(255) | 组织名称 | NOT NULL |
| description | TEXT | 组织描述 | |
| logo_url | VARCHAR(500) | 组织Logo | |
| website | VARCHAR(500) | 官方网站 | |
| status | ENUM('active', 'inactive', 'pending', 'suspended') | 状态 | DEFAULT 'pending' |
| governance_model | ENUM('direct', 'representative', 'hybrid') | 治理模式 | DEFAULT 'direct' |
| token_symbol | VARCHAR(20) | 代币符号 | |
| token_name | VARCHAR(100) | 代币名称 | |
| total_supply | DECIMAL(20,8) | 代币总供应量 | DEFAULT 0.00000000 |
| treasury_address | VARCHAR(100) | 金库地址 | |
| created_by | BIGINT UNSIGNED | 创建者ID | NOT NULL, FOREIGN KEY |
| created_at | TIMESTAMP | 创建时间 | DEFAULT CURRENT_TIMESTAMP |
| updated_at | TIMESTAMP | 更新时间 | AUTO UPDATE |

#### 2.2 DAO成员关系表 (dao_memberships)
**用途**: 存储DAO成员与组织的关系

| 字段名 | 类型 | 说明 | 约束 |
|--------|------|------|------|
| id | BIGINT UNSIGNED | 主键 | PRIMARY KEY, AUTO_INCREMENT |
| dao_id | BIGINT UNSIGNED | DAO组织ID | NOT NULL, FOREIGN KEY |
| user_id | BIGINT UNSIGNED | 用户ID | NOT NULL, FOREIGN KEY |
| role | ENUM('founder', 'admin', 'member', 'moderator') | 角色 | DEFAULT 'member' |
| status | ENUM('active', 'inactive', 'pending', 'suspended') | 状态 | DEFAULT 'pending' |
| joined_at | TIMESTAMP | 加入时间 | DEFAULT CURRENT_TIMESTAMP |
| left_at | TIMESTAMP | 离开时间 | NULL |
| voting_power | DECIMAL(10,2) | 投票权重 | DEFAULT 1.00 |
| contribution_score | DECIMAL(10,2) | 贡献分数 | DEFAULT 0.00 |
| created_at | TIMESTAMP | 创建时间 | DEFAULT CURRENT_TIMESTAMP |
| updated_at | TIMESTAMP | 更新时间 | AUTO UPDATE |

#### 2.3 DAO提案表 (dao_proposals)
**用途**: 存储DAO治理提案

| 字段名 | 类型 | 说明 | 约束 |
|--------|------|------|------|
| id | BIGINT UNSIGNED | 主键 | PRIMARY KEY, AUTO_INCREMENT |
| uuid | VARCHAR(36) | 提案唯一标识 | NOT NULL, UNIQUE |
| dao_id | BIGINT UNSIGNED | DAO组织ID | NOT NULL, FOREIGN KEY |
| proposer_id | BIGINT UNSIGNED | 提案者ID | NOT NULL, FOREIGN KEY |
| title | VARCHAR(255) | 提案标题 | NOT NULL |
| description | TEXT | 提案描述 | NOT NULL |
| proposal_type | ENUM('governance', 'treasury', 'technical', 'social') | 提案类型 | DEFAULT 'governance' |
| status | ENUM('draft', 'active', 'passed', 'rejected', 'expired') | 状态 | DEFAULT 'draft' |
| voting_start | TIMESTAMP | 投票开始时间 | |
| voting_end | TIMESTAMP | 投票结束时间 | |
| execution_deadline | TIMESTAMP | 执行截止时间 | |
| quorum_threshold | DECIMAL(5,2) | 法定人数阈值(%) | DEFAULT 10.00 |
| approval_threshold | DECIMAL(5,2) | 通过阈值(%) | DEFAULT 50.00 |
| total_votes | INT | 总投票数 | DEFAULT 0 |
| yes_votes | INT | 赞成票数 | DEFAULT 0 |
| no_votes | INT | 反对票数 | DEFAULT 0 |
| abstain_votes | INT | 弃权票数 | DEFAULT 0 |
| execution_status | ENUM('pending', 'executed', 'failed') | 执行状态 | DEFAULT 'pending' |
| execution_result | TEXT | 执行结果 | |
| created_at | TIMESTAMP | 创建时间 | DEFAULT CURRENT_TIMESTAMP |
| updated_at | TIMESTAMP | 更新时间 | AUTO UPDATE |

#### 2.4 DAO投票记录表 (dao_votes)
**用途**: 存储DAO成员投票记录

| 字段名 | 类型 | 说明 | 约束 |
|--------|------|------|------|
| id | BIGINT UNSIGNED | 主键 | PRIMARY KEY, AUTO_INCREMENT |
| proposal_id | BIGINT UNSIGNED | 提案ID | NOT NULL, FOREIGN KEY |
| voter_id | BIGINT UNSIGNED | 投票者ID | NOT NULL, FOREIGN KEY |
| vote_type | ENUM('yes', 'no', 'abstain') | 投票类型 | NOT NULL |
| voting_power | DECIMAL(10,2) | 投票权重 | NOT NULL |
| reason | TEXT | 投票理由 | |
| tx_hash | VARCHAR(100) | 交易哈希 | |
| block_number | BIGINT | 区块号 | |
| created_at | TIMESTAMP | 投票时间 | DEFAULT CURRENT_TIMESTAMP |

### 3. 代币经济系统模块

#### 3.1 DAO代币表 (dao_tokens)
**用途**: 存储DAO代币信息

| 字段名 | 类型 | 说明 | 约束 |
|--------|------|------|------|
| id | BIGINT UNSIGNED | 主键 | PRIMARY KEY, AUTO_INCREMENT |
| dao_id | BIGINT UNSIGNED | DAO组织ID | NOT NULL, FOREIGN KEY |
| symbol | VARCHAR(20) | 代币符号 | NOT NULL |
| name | VARCHAR(100) | 代币名称 | NOT NULL |
| decimals | TINYINT | 小数位数 | DEFAULT 18 |
| total_supply | DECIMAL(20,8) | 总供应量 | DEFAULT 0.00000000 |
| circulating_supply | DECIMAL(20,8) | 流通供应量 | DEFAULT 0.00000000 |
| contract_address | VARCHAR(100) | 合约地址 | |
| network | ENUM('ethereum', 'polygon', 'bsc', 'arbitrum') | 网络 | DEFAULT 'ethereum' |
| status | ENUM('active', 'inactive', 'paused') | 状态 | DEFAULT 'active' |
| created_at | TIMESTAMP | 创建时间 | DEFAULT CURRENT_TIMESTAMP |
| updated_at | TIMESTAMP | 更新时间 | AUTO UPDATE |

#### 3.2 DAO钱包表 (dao_wallets)
**用途**: 存储DAO成员的钱包信息

| 字段名 | 类型 | 说明 | 约束 |
|--------|------|------|------|
| id | BIGINT UNSIGNED | 主键 | PRIMARY KEY, AUTO_INCREMENT |
| user_id | BIGINT UNSIGNED | 用户ID | NOT NULL, FOREIGN KEY |
| wallet_address | VARCHAR(100) | 钱包地址 | NOT NULL, UNIQUE |
| wallet_type | ENUM('metamask', 'walletconnect', 'coinbase', 'ledger') | 钱包类型 | DEFAULT 'metamask' |
| network | ENUM('ethereum', 'polygon', 'bsc', 'arbitrum') | 网络 | DEFAULT 'ethereum' |
| is_primary | BOOLEAN | 是否主钱包 | DEFAULT FALSE |
| is_verified | BOOLEAN | 是否已验证 | DEFAULT FALSE |
| balance | DECIMAL(20,8) | 余额 | DEFAULT 0.00000000 |
| last_sync_at | TIMESTAMP | 最后同步时间 | |
| created_at | TIMESTAMP | 创建时间 | DEFAULT CURRENT_TIMESTAMP |
| updated_at | TIMESTAMP | 更新时间 | AUTO UPDATE |

#### 3.3 DAO代币余额表 (dao_token_balances)
**用途**: 存储DAO成员代币余额

| 字段名 | 类型 | 说明 | 约束 |
|--------|------|------|------|
| id | BIGINT UNSIGNED | 主键 | PRIMARY KEY, AUTO_INCREMENT |
| user_id | BIGINT UNSIGNED | 用户ID | NOT NULL, FOREIGN KEY |
| token_id | BIGINT UNSIGNED | 代币ID | NOT NULL, FOREIGN KEY |
| wallet_id | BIGINT UNSIGNED | 钱包ID | NOT NULL, FOREIGN KEY |
| balance | DECIMAL(20,8) | 余额 | DEFAULT 0.00000000 |
| locked_balance | DECIMAL(20,8) | 锁定余额 | DEFAULT 0.00000000 |
| staked_balance | DECIMAL(20,8) | 质押余额 | DEFAULT 0.00000000 |
| last_sync_at | TIMESTAMP | 最后同步时间 | |
| created_at | TIMESTAMP | 创建时间 | DEFAULT CURRENT_TIMESTAMP |
| updated_at | TIMESTAMP | 更新时间 | AUTO UPDATE |

### 4. 社区管理模块

#### 4.1 DAO积分系统表 (dao_points)
**用途**: 存储DAO积分系统

| 字段名 | 类型 | 说明 | 约束 |
|--------|------|------|------|
| id | BIGINT UNSIGNED | 主键 | PRIMARY KEY, AUTO_INCREMENT |
| user_id | BIGINT UNSIGNED | 用户ID | NOT NULL, FOREIGN KEY |
| dao_id | BIGINT UNSIGNED | DAO组织ID | NOT NULL, FOREIGN KEY |
| total_points | DECIMAL(10,2) | 总积分 | DEFAULT 0.00 |
| available_points | DECIMAL(10,2) | 可用积分 | DEFAULT 0.00 |
| locked_points | DECIMAL(10,2) | 锁定积分 | DEFAULT 0.00 |
| created_at | TIMESTAMP | 创建时间 | DEFAULT CURRENT_TIMESTAMP |
| updated_at | TIMESTAMP | 更新时间 | AUTO UPDATE |

#### 4.2 DAO积分历史表 (dao_point_history)
**用途**: 存储DAO积分变动历史

| 字段名 | 类型 | 说明 | 约束 |
|--------|------|------|------|
| id | BIGINT UNSIGNED | 主键 | PRIMARY KEY, AUTO_INCREMENT |
| user_id | BIGINT UNSIGNED | 用户ID | NOT NULL, FOREIGN KEY |
| dao_id | BIGINT UNSIGNED | DAO组织ID | NOT NULL, FOREIGN KEY |
| points_change | DECIMAL(10,2) | 积分变动 | NOT NULL |
| change_type | ENUM('earn', 'spend', 'lock', 'unlock', 'transfer') | 变动类型 | NOT NULL |
| reason | VARCHAR(255) | 变动原因 | |
| reference_id | BIGINT UNSIGNED | 关联ID | |
| reference_type | VARCHAR(50) | 关联类型 | |
| created_at | TIMESTAMP | 创建时间 | DEFAULT CURRENT_TIMESTAMP |

#### 4.3 DAO奖励表 (dao_rewards)
**用途**: 存储DAO奖励信息

| 字段名 | 类型 | 说明 | 约束 |
|--------|------|------|------|
| id | BIGINT UNSIGNED | 主键 | PRIMARY KEY, AUTO_INCREMENT |
| dao_id | BIGINT UNSIGNED | DAO组织ID | NOT NULL, FOREIGN KEY |
| name | VARCHAR(255) | 奖励名称 | NOT NULL |
| description | TEXT | 奖励描述 | |
| reward_type | ENUM('token', 'nft', 'points', 'badge') | 奖励类型 | DEFAULT 'points' |
| reward_value | DECIMAL(20,8) | 奖励价值 | DEFAULT 0.00000000 |
| max_recipients | INT | 最大获奖人数 | |
| criteria | JSON | 获奖条件 | |
| status | ENUM('active', 'inactive', 'completed') | 状态 | DEFAULT 'active' |
| start_date | TIMESTAMP | 开始时间 | |
| end_date | TIMESTAMP | 结束时间 | |
| created_at | TIMESTAMP | 创建时间 | DEFAULT CURRENT_TIMESTAMP |
| updated_at | TIMESTAMP | 更新时间 | AUTO UPDATE |

### 5. 系统管理模块

#### 5.1 DAO会话表 (dao_sessions)
**用途**: 存储DAO用户会话信息

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
| created_at | TIMESTAMP | 创建时间 | DEFAULT CURRENT_TIMESTAMP |
| updated_at | TIMESTAMP | 更新时间 | AUTO UPDATE |

#### 5.2 DAO通知表 (dao_notifications)
**用途**: 存储DAO通知信息

| 字段名 | 类型 | 说明 | 约束 |
|--------|------|------|------|
| id | BIGINT UNSIGNED | 主键 | PRIMARY KEY, AUTO_INCREMENT |
| user_id | BIGINT UNSIGNED | 用户ID | NOT NULL, FOREIGN KEY |
| dao_id | BIGINT UNSIGNED | DAO组织ID | FOREIGN KEY |
| title | VARCHAR(255) | 通知标题 | NOT NULL |
| message | TEXT | 通知内容 | NOT NULL |
| type | ENUM('proposal', 'vote', 'reward', 'system') | 通知类型 | DEFAULT 'system' |
| status | ENUM('unread', 'read', 'archived') | 状态 | DEFAULT 'unread' |
| reference_id | BIGINT UNSIGNED | 关联ID | |
| reference_type | VARCHAR(50) | 关联类型 | |
| created_at | TIMESTAMP | 创建时间 | DEFAULT CURRENT_TIMESTAMP |
| updated_at | TIMESTAMP | 更新时间 | AUTO UPDATE |

#### 5.3 DAO审计日志表 (dao_audit_logs)
**用途**: 存储DAO操作审计日志

| 字段名 | 类型 | 说明 | 约束 |
|--------|------|------|------|
| id | BIGINT UNSIGNED | 主键 | PRIMARY KEY, AUTO_INCREMENT |
| user_id | BIGINT UNSIGNED | 用户ID | FOREIGN KEY |
| dao_id | BIGINT UNSIGNED | DAO组织ID | FOREIGN KEY |
| action | VARCHAR(100) | 操作类型 | NOT NULL |
| resource_type | VARCHAR(50) | 资源类型 | NOT NULL |
| resource_id | BIGINT UNSIGNED | 资源ID | |
| old_values | JSON | 旧值 | |
| new_values | JSON | 新值 | |
| ip_address | VARCHAR(45) | IP地址 | |
| user_agent | TEXT | 用户代理 | |
| created_at | TIMESTAMP | 创建时间 | DEFAULT CURRENT_TIMESTAMP |

## 📊 表结构统计

### 总表数量: 18个表

| 模块 | 表数量 | 表名 |
|------|--------|------|
| **用户管理** | 2个 | dao_users, dao_user_profiles |
| **DAO治理** | 4个 | dao_organizations, dao_memberships, dao_proposals, dao_votes |
| **代币经济** | 3个 | dao_tokens, dao_wallets, dao_token_balances |
| **社区管理** | 3个 | dao_points, dao_point_history, dao_rewards |
| **系统管理** | 3个 | dao_sessions, dao_notifications, dao_audit_logs |

### 索引策略

#### 主要索引
- **用户表**: uuid, email, username, status
- **DAO组织表**: uuid, name, status
- **提案表**: uuid, dao_id, status, voting_start, voting_end
- **投票表**: proposal_id, voter_id
- **代币表**: dao_id, symbol, contract_address
- **钱包表**: wallet_address, user_id, is_primary

## 🔗 外键关系

### 主要外键关系
1. **dao_user_profiles.user_id** → **dao_users.id**
2. **dao_memberships.dao_id** → **dao_organizations.id**
3. **dao_memberships.user_id** → **dao_users.id**
4. **dao_proposals.dao_id** → **dao_organizations.id**
5. **dao_proposals.proposer_id** → **dao_users.id**
6. **dao_votes.proposal_id** → **dao_proposals.id**
7. **dao_votes.voter_id** → **dao_users.id**
8. **dao_tokens.dao_id** → **dao_organizations.id**
9. **dao_wallets.user_id** → **dao_users.id**
10. **dao_token_balances.user_id** → **dao_users.id**
11. **dao_token_balances.token_id** → **dao_tokens.id**
12. **dao_token_balances.wallet_id** → **dao_wallets.id**

---

**下一步**: 生成DAO版的SQL数据库初始化脚本。
