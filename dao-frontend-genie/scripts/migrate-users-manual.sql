USE dao_dev;

-- 手动插入 zervigo 用户数据
INSERT INTO dao_members (
    user_id, username, email, first_name, last_name, avatar_url, phone,
    bio, location, website, github_url, linkedin_url, skills, interests, languages,
    reputation_score, contribution_points, status, created_at, updated_at
) VALUES 
-- 张三 - 前端开发
('user-uuid-001', 'zhangsan', 'zhangsan@jobfirst.com', '张三', '张', 'https://example.com/avatar1.jpg', '13800138001',
'5年前端开发经验，精通React、Vue等现代前端技术栈，热爱开源项目', '北京', 'https://zhangsan.dev', 
'https://github.com/zhangsan', 'https://linkedin.com/in/zhangsan', 
'["React", "Vue", "JavaScript", "TypeScript"]', '["编程", "开源", "技术分享"]', '["中文", "英文"]',
80, 65, 'ACTIVE', '2024-01-01 10:00:00', '2024-01-01 10:00:00'),

-- 李四 - 产品管理
('user-uuid-002', 'lisi', 'lisi@jobfirst.com', '李四', '李', 'https://example.com/avatar2.jpg', '13800138002',
'3年产品管理经验，擅长用户研究和产品设计，有丰富的B端产品经验', '上海', 'https://lisi.design', 
'https://github.com/lisi', 'https://linkedin.com/in/lisi', 
'["产品设计", "用户研究", "数据分析"]', '["设计", "心理学", "商业分析"]', '["中文", "英文", "日文"]',
70, 60, 'ACTIVE', '2024-01-02 10:00:00', '2024-01-02 10:00:00'),

-- 王五 - 后端开发
('user-uuid-003', 'wangwu', 'wangwu@jobfirst.com', '王五', '王', 'https://example.com/avatar3.jpg', '13800138003',
'7年后端开发经验，专注于分布式系统和微服务架构', '深圳', 'https://wangwu.tech', 
'https://github.com/wangwu', 'https://linkedin.com/in/wangwu', 
'["Go", "Java", "Python", "Docker", "Kubernetes"]', '["系统架构", "开源", "技术管理"]', '["中文", "英文"]',
90, 70, 'ACTIVE', '2024-01-03 10:00:00', '2024-01-03 10:00:00'),

-- 赵六 - 全栈开发
('user-uuid-004', 'zhaoliu', 'zhaoliu@jobfirst.com', '赵六', '赵', 'https://example.com/avatar4.jpg', '13800138004',
'4年全栈开发经验，熟悉前后端技术栈，有丰富的项目经验', '杭州', 'https://zhaoliu.dev', 
'https://github.com/zhaoliu', 'https://linkedin.com/in/zhaoliu', 
'["React", "Node.js", "Python", "MySQL", "Redis"]', '["全栈开发", "技术分享", "创业"]', '["中文", "英文"]',
85, 55, 'ACTIVE', '2024-01-04 10:00:00', '2024-01-04 10:00:00'),

-- 钱七 - UI/UX设计
('user-uuid-005', 'qianqi', 'qianqi@jobfirst.com', '钱七', '钱', 'https://example.com/avatar5.jpg', '13800138005',
'2年UI/UX设计经验，专注于移动端和Web端界面设计', '广州', 'https://qianqi.design', 
'https://github.com/qianqi', 'https://linkedin.com/in/qianqi', 
'["UI设计", "UX设计", "Figma", "Sketch", "Photoshop"]', '["设计", "艺术", "摄影"]', '["中文", "英文", "韩文"]',
70, 50, 'ACTIVE', '2024-01-05 10:00:00', '2024-01-05 10:00:00');

-- 验证迁移结果
SELECT 
    user_id,
    username,
    email,
    first_name,
    last_name,
    reputation_score,
    contribution_points,
    status
FROM dao_members 
WHERE user_id LIKE 'user-uuid-%'
ORDER BY reputation_score DESC;
