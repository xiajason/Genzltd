-- 统一积分系统数据库架构
-- 创建时间: 2025年10月1日
-- 版本: v1.0
-- 目标: 实现Zervigo与DAO积分的统一管理

USE dao_dev;

-- 统一积分表
CREATE TABLE IF NOT EXISTS unified_points (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id VARCHAR(191) NOT NULL,
    
    -- 基础积分
    total_points INT NOT NULL DEFAULT 0 COMMENT '总积分',
    available_points INT NOT NULL DEFAULT 0 COMMENT '可用积分',
    
    -- 分类积分
    reputation_points INT NOT NULL DEFAULT 80 COMMENT '声誉积分',
    contribution_points INT NOT NULL DEFAULT 0 COMMENT '贡献积分',
    activity_points INT NOT NULL DEFAULT 0 COMMENT '活动积分',
    
    -- DAO相关
    voting_power INT NOT NULL DEFAULT 8 COMMENT '投票权重',
    governance_level INT NOT NULL DEFAULT 1 COMMENT '治理等级',
    
    -- 时间戳
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    
    -- 外键约束
    FOREIGN KEY (user_id) REFERENCES dao_members(user_id) ON DELETE CASCADE,
    
    -- 索引
    INDEX idx_user_id (user_id),
    INDEX idx_voting_power (voting_power),
    INDEX idx_governance_level (governance_level),
    INDEX idx_total_points (total_points),
    INDEX idx_updated_at (updated_at),
    
    -- 唯一约束
    UNIQUE KEY uk_user_id (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='统一积分表';

-- 积分历史表
CREATE TABLE IF NOT EXISTS points_history (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id VARCHAR(191) NOT NULL,
    
    -- 积分变动
    points_change INT NOT NULL COMMENT '积分变动数量',
    change_type ENUM('earn', 'spend', 'transfer', 'adjust') NOT NULL COMMENT '变动类型',
    
    -- 分类变动
    reputation_change INT DEFAULT 0 COMMENT '声誉积分变动',
    contribution_change INT DEFAULT 0 COMMENT '贡献积分变动',
    activity_change INT DEFAULT 0 COMMENT '活动积分变动',
    
    -- 变动原因
    reason VARCHAR(255) NOT NULL COMMENT '变动原因',
    description TEXT COMMENT '详细描述',
    source_system ENUM('zervigo', 'dao', 'system') NOT NULL COMMENT '来源系统',
    
    -- 引用信息
    reference_type VARCHAR(50) COMMENT '引用类型',
    reference_id BIGINT UNSIGNED COMMENT '引用ID',
    
    -- 余额快照
    balance_before INT NOT NULL COMMENT '变动前余额',
    balance_after INT NOT NULL COMMENT '变动后余额',
    voting_power_before INT NOT NULL COMMENT '变动前投票权重',
    voting_power_after INT NOT NULL COMMENT '变动后投票权重',
    
    -- 时间戳
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    
    -- 外键约束
    FOREIGN KEY (user_id) REFERENCES dao_members(user_id) ON DELETE CASCADE,
    
    -- 索引
    INDEX idx_user_id (user_id),
    INDEX idx_source_system (source_system),
    INDEX idx_change_type (change_type),
    INDEX idx_reference (reference_type, reference_id),
    INDEX idx_created_at (created_at),
    INDEX idx_user_created (user_id, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='积分历史表';

-- 积分奖励规则表
CREATE TABLE IF NOT EXISTS points_reward_rules (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    rule_id VARCHAR(50) NOT NULL UNIQUE COMMENT '规则ID',
    name VARCHAR(100) NOT NULL COMMENT '规则名称',
    description TEXT COMMENT '规则描述',
    source_system ENUM('zervigo', 'dao', 'system') NOT NULL COMMENT '来源系统',
    trigger_event VARCHAR(100) NOT NULL COMMENT '触发事件',
    points_change INT NOT NULL COMMENT '积分变动',
    points_type ENUM('total', 'reputation', 'contribution', 'activity') NOT NULL COMMENT '积分类型',
    conditions JSON COMMENT '触发条件',
    is_active BOOLEAN NOT NULL DEFAULT TRUE COMMENT '是否激活',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    
    -- 索引
    INDEX idx_rule_id (rule_id),
    INDEX idx_source_system (source_system),
    INDEX idx_trigger_event (trigger_event),
    INDEX idx_is_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='积分奖励规则表';

-- 积分同步日志表
CREATE TABLE IF NOT EXISTS points_sync_logs (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id VARCHAR(191) NOT NULL,
    sync_type ENUM('zervigo_to_dao', 'dao_to_zervigo', 'bidirectional') NOT NULL COMMENT '同步类型',
    sync_status ENUM('pending', 'success', 'failed', 'partial') NOT NULL DEFAULT 'pending' COMMENT '同步状态',
    sync_data JSON COMMENT '同步数据',
    error_message TEXT COMMENT '错误信息',
    retry_count INT DEFAULT 0 COMMENT '重试次数',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    completed_at TIMESTAMP NULL COMMENT '完成时间',
    
    -- 外键约束
    FOREIGN KEY (user_id) REFERENCES dao_members(user_id) ON DELETE CASCADE,
    
    -- 索引
    INDEX idx_user_id (user_id),
    INDEX idx_sync_type (sync_type),
    INDEX idx_sync_status (sync_status),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='积分同步日志表';

-- 插入默认奖励规则
INSERT INTO points_reward_rules (rule_id, name, description, source_system, trigger_event, points_change, points_type, conditions) VALUES
-- Zervigo业务积分规则
('resume_create', '创建简历', '用户创建简历获得积分奖励', 'zervigo', 'resume.create', 30, 'contribution', '{"max_per_day": 3}'),
('resume_like', '简历被点赞', '简历获得点赞获得积分奖励', 'zervigo', 'resume.like', 20, 'reputation', '{"max_per_day": 10}'),
('resume_share', '简历分享', '用户分享简历获得积分奖励', 'zervigo', 'resume.share', 15, 'activity', '{"max_per_day": 5}'),
('resume_comment', '简历评论', '用户评论简历获得积分奖励', 'zervigo', 'resume.comment', 10, 'activity', '{"max_per_day": 10}'),

-- DAO治理积分规则
('proposal_create', '创建提案', '用户创建DAO提案获得积分奖励', 'dao', 'proposal.create', 50, 'contribution', '{"max_per_day": 2}'),
('proposal_vote', '参与投票', '用户参与DAO投票获得积分奖励', 'dao', 'proposal.vote', 10, 'activity', '{"max_per_day": 20}'),
('proposal_execute', '执行提案', '用户执行DAO提案获得积分奖励', 'dao', 'proposal.execute', 100, 'contribution', '{"max_per_day": 1}'),
('governance_participate', '参与治理', '用户参与治理讨论获得积分奖励', 'dao', 'governance.discuss', 5, 'activity', '{"max_per_day": 10}'),

-- 系统奖励积分规则
('daily_login', '每日登录', '用户每日登录获得积分奖励', 'system', 'user.login', 5, 'activity', '{"daily": true}'),
('achievement_unlock', '成就解锁', '用户解锁成就获得积分奖励', 'system', 'achievement.unlock', 25, 'reputation', '{}'),
('milestone_reach', '里程碑达成', '用户达成里程碑获得积分奖励', 'system', 'milestone.reach', 50, 'contribution', '{}');

-- 创建视图：用户积分概览
CREATE OR REPLACE VIEW user_points_overview AS
SELECT 
    up.user_id,
    dm.username,
    dm.email,
    up.total_points,
    up.available_points,
    up.reputation_points,
    up.contribution_points,
    up.activity_points,
    up.voting_power,
    up.governance_level,
    up.updated_at,
    -- 计算积分排名
    RANK() OVER (ORDER BY up.total_points DESC) as total_points_rank,
    RANK() OVER (ORDER BY up.voting_power DESC) as voting_power_rank
FROM unified_points up
JOIN dao_members dm ON up.user_id = dm.user_id;

-- 创建视图：积分统计
CREATE OR REPLACE VIEW points_statistics AS
SELECT 
    source_system,
    change_type,
    COUNT(*) as transaction_count,
    SUM(points_change) as total_points_change,
    AVG(points_change) as avg_points_change,
    DATE(created_at) as transaction_date
FROM points_history
GROUP BY source_system, change_type, DATE(created_at)
ORDER BY transaction_date DESC;

-- 初始化现有用户的统一积分
INSERT INTO unified_points (user_id, total_points, available_points, reputation_points, contribution_points, activity_points, voting_power, governance_level)
SELECT 
    user_id,
    100 as total_points,  -- 初始总积分
    100 as available_points,  -- 初始可用积分
    80 as reputation_points,  -- 初始声誉积分
    20 as contribution_points,  -- 初始贡献积分
    0 as activity_points,  -- 初始活动积分
    8 as voting_power,  -- 初始投票权重
    1 as governance_level  -- 初始治理等级
FROM dao_members
WHERE user_id NOT IN (SELECT user_id FROM unified_points);

-- 创建积分触发器：自动更新投票权重
DELIMITER $$
CREATE TRIGGER update_voting_power_trigger
AFTER UPDATE ON unified_points
FOR EACH ROW
BEGIN
    -- 计算新的投票权重
    DECLARE new_voting_power INT;
    
    SET new_voting_power = LEAST(
        FLOOR(
            (LEAST(NEW.total_points / 1000, 1) * 40) +  -- 积分权重最多40分
            (LEAST(NEW.reputation_points / 200, 1) * 30) +  -- 声誉权重最多30分
            (LEAST(NEW.contribution_points / 500, 1) * 20) +  -- 贡献权重最多20分
            (LEAST(NEW.activity_points / 100, 1) * 10)  -- 活跃度权重最多10分
        ),
        100  -- 最大投票权重100分
    );
    
    -- 更新投票权重
    UPDATE unified_points 
    SET voting_power = GREATEST(new_voting_power, 1)  -- 最少1分投票权重
    WHERE id = NEW.id;
END$$
DELIMITER ;

COMMIT;