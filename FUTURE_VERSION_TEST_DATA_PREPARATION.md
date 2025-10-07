# Future版测试数据准备文档

## 🎯 项目概述
为腾讯云服务Future版各类型数据库写入测试数据，基于现有的数据库架构和用户权限系统，准备完整的测试数据集。

## 📊 数据库架构分析

### 🏗️ Future版数据库结构
基于 `tencent_cloud_database/future_mysql_database_structure.sql` 分析：

#### 1. 用户管理模块 (3个表)
- **users**: 用户基础信息表
- **user_profiles**: 用户详细资料表  
- **user_sessions**: 用户会话表

#### 2. 简历管理模块 (4个表)
- **resume_metadata**: 简历元数据表
- **resume_files**: 简历文件表
- **resume_templates**: 简历模板表
- **resume_analyses**: 简历分析表

#### 3. 技能和职位模块 (4个表)
- **skills**: 技能表
- **companies**: 公司表
- **positions**: 职位表
- **resume_skills**: 简历技能关联表

#### 4. 工作经历模块 (4个表)
- **work_experiences**: 工作经历表
- **projects**: 项目经验表
- **educations**: 教育背景表
- **certifications**: 证书认证表

#### 5. 社交互动模块 (3个表)
- **resume_comments**: 简历评论表
- **resume_likes**: 简历点赞表
- **resume_shares**: 简历分享表

#### 6. 积分系统模块 (2个表)
- **points**: 积分表
- **point_history**: 积分历史表

#### 7. 系统配置模块 (2个表)
- **system_configs**: 系统配置表
- **operation_logs**: 操作日志表

## 👥 用户权限系统分析

### 🔐 基于Zervigo的用户权限系统
基于 `zervigo_future/backend/internal/user/` 分析：

#### 1. 用户角色系统
- **admin**: 管理员角色
- **user**: 普通用户角色
- **guest**: 访客角色

#### 2. 权限管理功能
- **认证管理**: 注册、登录、登出、刷新Token
- **用户管理**: 用户资料、密码修改、用户列表
- **角色管理**: 角色创建、角色列表
- **权限管理**: 权限创建、权限列表
- **简历权限管理**: 简历权限配置
- **利益相关方管理**: 利益相关方列表
- **评论管理**: 简历评论
- **分享管理**: 简历分享
- **积分管理**: 用户积分、积分奖励

## 📋 测试数据准备计划

### 🎯 测试数据分类

#### 1. 用户测试数据
```sql
-- 管理员用户
INSERT INTO users (uuid, username, email, password_hash, role, status) VALUES
('admin-uuid-001', 'admin', 'admin@jobfirst.com', 'hashed_password', 'admin', 'active');

-- 普通用户
INSERT INTO users (uuid, username, email, password_hash, role, status) VALUES
('user-uuid-001', 'john_doe', 'john@example.com', 'hashed_password', 'user', 'active'),
('user-uuid-002', 'jane_smith', 'jane@example.com', 'hashed_password', 'user', 'active'),
('user-uuid-003', 'bob_wilson', 'bob@example.com', 'hashed_password', 'user', 'active');

-- 访客用户
INSERT INTO users (uuid, username, email, password_hash, role, status) VALUES
('guest-uuid-001', 'guest_user', 'guest@example.com', 'hashed_password', 'guest', 'active');
```

#### 2. 技能测试数据
```sql
-- 技术技能
INSERT INTO skills (name, category, description, skill_level) VALUES
('Python', 'Programming', 'Python programming language', 'advanced'),
('JavaScript', 'Programming', 'JavaScript programming language', 'intermediate'),
('React', 'Frontend', 'React.js frontend framework', 'advanced'),
('Node.js', 'Backend', 'Node.js backend framework', 'intermediate'),
('MySQL', 'Database', 'MySQL database management', 'advanced'),
('Docker', 'DevOps', 'Docker containerization', 'intermediate');

-- 软技能
INSERT INTO skills (name, category, description, skill_level) VALUES
('Leadership', 'Soft Skills', 'Team leadership and management', 'advanced'),
('Communication', 'Soft Skills', 'Effective communication skills', 'advanced'),
('Problem Solving', 'Soft Skills', 'Analytical problem solving', 'advanced');
```

#### 3. 公司测试数据
```sql
INSERT INTO companies (name, industry, size, location, website, description) VALUES
('TechCorp Inc', 'Technology', 'large', 'San Francisco, CA', 'https://techcorp.com', 'Leading technology company'),
('StartupXYZ', 'Technology', 'startup', 'Austin, TX', 'https://startupxyz.com', 'Innovative startup company'),
('FinanceFirst', 'Finance', 'medium', 'New York, NY', 'https://financefirst.com', 'Financial services company'),
('HealthTech', 'Healthcare', 'medium', 'Boston, MA', 'https://healthtech.com', 'Healthcare technology company');
```

#### 4. 职位测试数据
```sql
INSERT INTO positions (name, category, description) VALUES
('Software Engineer', 'Engineering', 'Full-stack software development'),
('Product Manager', 'Management', 'Product strategy and management'),
('Data Scientist', 'Analytics', 'Data analysis and machine learning'),
('UX Designer', 'Design', 'User experience design'),
('DevOps Engineer', 'Engineering', 'Infrastructure and deployment'),
('Marketing Manager', 'Marketing', 'Digital marketing and growth');
```

#### 5. 简历模板测试数据
```sql
INSERT INTO resume_templates (name, description, template_data, category, is_premium) VALUES
('Professional Classic', 'Clean and professional resume template', '{"sections": ["header", "experience", "education", "skills"]}', 'Professional', 0),
('Creative Modern', 'Modern and creative resume template', '{"sections": ["header", "summary", "experience", "projects", "skills"]}', 'Creative', 1),
('Technical Focus', 'Technical resume template for developers', '{"sections": ["header", "skills", "experience", "projects", "certifications"]}', 'Technical', 0);
```

#### 6. 积分系统测试数据
```sql
-- 用户积分
INSERT INTO points (user_id, total_points, available_points, used_points) VALUES
(1, 1000, 800, 200),
(2, 500, 500, 0),
(3, 750, 600, 150);

-- 积分历史
INSERT INTO point_history (user_id, points_change, action_type, description, reference_type, reference_id) VALUES
(1, 100, 'earn', '注册奖励', 'registration', 1),
(1, 50, 'earn', '完善资料奖励', 'profile_completion', 1),
(2, 100, 'earn', '注册奖励', 'registration', 2),
(3, 100, 'earn', '注册奖励', 'registration', 3),
(3, 25, 'earn', '首次登录奖励', 'first_login', 3);
```

### 🎯 多数据库测试数据

#### 1. MySQL测试数据
- 完整的用户、简历、技能、公司数据
- 关系型数据完整性测试
- 复杂查询性能测试

#### 2. PostgreSQL测试数据
- 与MySQL相同的结构化数据
- JSON字段测试数据
- 高级查询功能测试

#### 3. Redis测试数据
- 用户会话数据
- 缓存数据
- 实时数据

#### 4. Neo4j测试数据
- 用户关系图
- 技能关联图
- 职业发展路径图

#### 5. Elasticsearch测试数据
- 简历全文搜索数据
- 技能匹配数据
- 职位推荐数据

#### 6. Weaviate测试数据
- 向量化简历数据
- 语义搜索数据
- AI推荐数据

## 🚀 实施计划

### 📋 第一阶段：基础数据准备
1. **用户数据**: 创建不同角色的测试用户
2. **技能数据**: 创建技术技能和软技能数据
3. **公司数据**: 创建不同类型和规模的公司数据
4. **职位数据**: 创建各种职位类别数据

### 📋 第二阶段：业务数据准备
1. **简历数据**: 创建完整的简历元数据和文件数据
2. **工作经历数据**: 创建丰富的工作经历数据
3. **教育背景数据**: 创建教育背景数据
4. **项目经验数据**: 创建项目经验数据

### 📋 第三阶段：社交数据准备
1. **评论数据**: 创建简历评论数据
2. **点赞数据**: 创建简历点赞数据
3. **分享数据**: 创建简历分享数据
4. **积分数据**: 创建积分系统和历史数据

### 📋 第四阶段：多数据库数据准备
1. **MySQL数据**: 完整的关系型数据
2. **PostgreSQL数据**: 包含JSON字段的数据
3. **Redis数据**: 会话和缓存数据
4. **Neo4j数据**: 图关系数据
5. **Elasticsearch数据**: 搜索索引数据
6. **Weaviate数据**: 向量化数据

## 🔧 技术实现

### 📝 数据生成脚本
1. **SQL脚本**: 生成标准SQL插入语句
2. **Python脚本**: 生成JSON格式数据
3. **批量导入脚本**: 支持多数据库批量导入
4. **数据验证脚本**: 验证数据完整性和一致性

### 🎯 数据质量保证
1. **数据完整性**: 确保外键关系正确
2. **数据一致性**: 确保多数据库数据一致
3. **数据真实性**: 使用真实的测试数据
4. **数据覆盖性**: 覆盖所有业务场景

## �� 预期成果

### 🎯 测试数据规模
- **用户数据**: 100+ 测试用户
- **简历数据**: 200+ 测试简历
- **技能数据**: 500+ 技能条目
- **公司数据**: 100+ 公司信息
- **职位数据**: 200+ 职位信息

### 🎯 测试场景覆盖
- **用户注册登录**: 完整的用户生命周期
- **简历管理**: 简历创建、编辑、分享
- **技能匹配**: 技能搜索和匹配
- **社交互动**: 评论、点赞、分享
- **积分系统**: 积分获取和使用
- **多数据库**: 所有6个数据库的完整测试

## 📚 文档输出

### 📋 生成文档
1. **测试数据SQL脚本**: 完整的SQL插入脚本
2. **测试数据JSON文件**: 结构化的JSON数据文件
3. **数据导入脚本**: 自动化数据导入脚本
4. **数据验证报告**: 数据完整性和一致性验证报告

### 📋 使用指南
1. **数据导入指南**: 详细的数据导入步骤
2. **数据验证指南**: 数据验证和测试方法
3. **故障排除指南**: 常见问题和解决方案
4. **维护指南**: 数据维护和更新方法

## 🎉 项目价值

### 💪 技术价值
- **完整测试环境**: 提供完整的测试数据环境
- **多数据库支持**: 支持所有6个数据库的测试
- **真实业务场景**: 基于真实业务场景的测试数据
- **自动化测试**: 支持自动化测试和验证

### 💼 业务价值
- **功能验证**: 验证所有业务功能
- **性能测试**: 支持性能测试和优化
- **用户体验**: 提供真实的用户体验测试
- **系统稳定性**: 验证系统稳定性和可靠性

---
*文档创建时间: 2025年10月6日*  
*项目: JobFirst Future版测试数据准备*  
*状态: 准备阶段*
