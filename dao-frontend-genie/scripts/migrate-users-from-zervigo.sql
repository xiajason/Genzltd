-- DAO Genie 用户数据迁移脚本
-- 从 Zervigo 项目迁移用户数据到 DAO 系统
-- 执行前请确保两个数据库都可用

-- 使用 DAO 数据库
USE dao_dev;

-- 临时表：从 zervigo 数据库获取用户数据
-- 注意：这里假设能访问 jobfirst_v3 数据库
-- 如果不能直接访问，需要先导出数据到 CSV 或 JSON 文件

-- 方案1：直接跨数据库查询（如果数据库在同一服务器上）
INSERT INTO dao_members (
    user_id, 
    username, 
    email, 
    first_name, 
    last_name, 
    avatar_url, 
    phone,
    bio, 
    location, 
    website, 
    github_url, 
    linkedin_url, 
    skills, 
    interests, 
    languages,
    reputation_score, 
    contribution_points, 
    status, 
    created_at
) 
SELECT 
    u.uuid as user_id,
    u.username,
    u.email,
    u.first_name,
    u.last_name,
    u.avatar_url,
    u.phone,
    up.bio,
    up.location,
    up.website,
    up.github_url,
    up.linkedin_url,
    up.skills,
    up.interests,
    up.languages,
    -- 根据技能和经验生成初始声誉积分
    CASE 
        WHEN JSON_CONTAINS(up.skills, '"React"') OR JSON_CONTAINS(up.skills, '"Vue.js"') THEN 80
        WHEN JSON_CONTAINS(up.skills, '"Go"') OR JSON_CONTAINS(up.skills, '"Golang"') THEN 90
        WHEN JSON_CONTAINS(up.skills, '"Java"') OR JSON_CONTAINS(up.skills, '"Python"') THEN 85
        WHEN JSON_CONTAINS(up.skills, '"Node.js"') THEN 75
        WHEN JSON_CONTAINS(up.skills, '"UI设计"') OR JSON_CONTAINS(up.skills, '"UX设计"') THEN 70
        ELSE 50
    END as reputation_score,
    -- 根据兴趣和活跃度生成初始贡献积分
    CASE 
        WHEN JSON_CONTAINS(up.interests, '"开源"') THEN 65
        WHEN JSON_CONTAINS(up.interests, '"技术分享"') THEN 60
        WHEN JSON_CONTAINS(up.interests, '"创业"') THEN 55
        WHEN JSON_CONTAINS(up.interests, '"设计"') THEN 50
        ELSE 40
    END as contribution_points,
    'ACTIVE' as status,
    u.created_at
FROM jobfirst_v3.users u
LEFT JOIN jobfirst_v3.user_profiles up ON u.id = up.user_id
WHERE u.status = 'active' 
  AND u.deleted_at IS NULL
  AND u.uuid NOT IN (SELECT user_id FROM dao_members); -- 避免重复插入

-- 方案2：如果无法直接跨数据库查询，使用手动插入
-- 取消注释下面的代码，注释上面的代码

/*
-- 手动插入 zervigo 用户数据
INSERT INTO dao_members (
    user_id, username, email, first_name, last_name, avatar_url, phone,
    bio, location, website, github_url, linkedin_url, skills, interests, languages,
    reputation_score, contribution_points, status, created_at
) VALUES 
-- 张三 - 前端开发
('user-uuid-001', 'zhangsan', 'zhangsan@jobfirst.com', '张三', '张', 'https://example.com/avatar1.jpg', '13800138001',
'5年前端开发经验，精通React、Vue等现代前端技术栈，热爱开源项目', '北京', 'https://zhangsan.dev', 
'https://github.com/zhangsan', 'https://linkedin.com/in/zhangsan', 
'["React", "Vue", "JavaScript", "TypeScript"]', '["编程", "开源", "技术分享"]', '["中文", "英文"]',
80, 65, 'ACTIVE', '2024-01-01 10:00:00'),

-- 李四 - 产品管理
('user-uuid-002', 'lisi', 'lisi@jobfirst.com', '李四', '李', 'https://example.com/avatar2.jpg', '13800138002',
'3年产品管理经验，擅长用户研究和产品设计，有丰富的B端产品经验', '上海', 'https://lisi.design', 
'https://github.com/lisi', 'https://linkedin.com/in/lisi', 
'["产品设计", "用户研究", "数据分析"]', '["设计", "心理学", "商业分析"]', '["中文", "英文", "日文"]',
70, 60, 'ACTIVE', '2024-01-02 10:00:00'),

-- 王五 - 后端开发
('user-uuid-003', 'wangwu', 'wangwu@jobfirst.com', '王五', '王', 'https://example.com/avatar3.jpg', '13800138003',
'7年后端开发经验，专注于分布式系统和微服务架构', '深圳', 'https://wangwu.tech', 
'https://github.com/wangwu', 'https://linkedin.com/in/wangwu', 
'["Go", "Java", "Python", "Docker", "Kubernetes"]', '["系统架构", "开源", "技术管理"]', '["中文", "英文"]',
90, 70, 'ACTIVE', '2024-01-03 10:00:00'),

-- 赵六 - 全栈开发
('user-uuid-004', 'zhaoliu', 'zhaoliu@jobfirst.com', '赵六', '赵', 'https://example.com/avatar4.jpg', '13800138004',
'4年全栈开发经验，熟悉前后端技术栈，有丰富的项目经验', '杭州', 'https://zhaoliu.dev', 
'https://github.com/zhaoliu', 'https://linkedin.com/in/zhaoliu', 
'["React", "Node.js", "Python", "MySQL", "Redis"]', '["全栈开发", "技术分享", "创业"]', '["中文", "英文"]',
85, 55, 'ACTIVE', '2024-01-04 10:00:00'),

-- 钱七 - UI/UX设计
('user-uuid-005', 'qianqi', 'qianqi@jobfirst.com', '钱七', '钱', 'https://example.com/avatar5.jpg', '13800138005',
'2年UI/UX设计经验，专注于移动端和Web端界面设计', '广州', 'https://qianqi.design', 
'https://github.com/qianqi', 'https://linkedin.com/in/qianqi', 
'["UI设计", "UX设计", "Figma", "Sketch", "Photoshop"]', '["设计", "艺术", "摄影"]', '["中文", "英文", "韩文"]',
70, 50, 'ACTIVE', '2024-01-05 10:00:00');
*/

-- 验证迁移结果
SELECT 
    user_id,
    username,
    email,
    first_name,
    last_name,
    reputation_score,
    contribution_points,
    status,
    created_at
FROM dao_members 
WHERE user_id LIKE 'user-uuid-%'
ORDER BY reputation_score DESC;

-- 显示迁移统计
SELECT 
    COUNT(*) as total_members,
    AVG(reputation_score) as avg_reputation,
    AVG(contribution_points) as avg_contribution,
    COUNT(CASE WHEN status = 'ACTIVE' THEN 1 END) as active_members
FROM dao_members;
