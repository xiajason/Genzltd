# JobFirst V3.0 数据库关联关系图

## 核心实体关系

### 1. 用户中心 (User Center)
```
users (用户基础表)
├── user_profiles (用户详细资料) [1:1]
├── user_settings (用户设置) [1:1]
├── user_sessions (用户会话) [1:N]
├── points (积分账户) [1:1]
├── point_history (积分历史) [1:N]
└── resumes (简历) [1:N]
```

### 2. 简历中心 (Resume Center) - 新架构
```
📊 MySQL数据库 (元数据存储)
resume_metadata (简历元数据表) - 主表
├── resume_files (简历文件元数据) [1:N] → files (文件管理)
├── resume_parsing_tasks (解析任务元数据) [1:N] → parsing_tasks
├── resume_templates (简历模板) [N:1] → template_id
├── resume_analyses (简历分析) [1:N] → analyses
├── resume_comments (简历评论) [1:N] → users (评论者)
├── resume_likes (简历点赞) [1:N] → users (点赞者)
├── resume_shares (简历分享) [1:N] → users (分享者)
└── resume_skills (简历技能关联) [1:N] → skills (技能表)

📁 SQLite数据库 (用户专属内容存储)
resume_content (简历内容表) - 主表
├── parsed_resume_data (解析结果) [1:N] → parsed_data
├── user_privacy_settings (隐私设置) [1:1] → privacy
├── resume_versions (版本历史) [1:N] → versions
├── user_custom_fields (自定义字段) [1:N] → custom_fields
└── resume_access_logs (访问日志) [1:N] → access_logs

🔄 数据关联关系
resume_metadata.id ↔ resume_content.resume_metadata_id (跨数据库关联)
```

### 3. 标准化数据中心 (Standard Data Center)
```
skills (技能表) [标准化]
├── resume_skills (简历技能关联) [N:1] → resumes
└── 技能分类: 前端框架、编程语言、数据库、容器化、设计工具等

companies (公司表) [标准化]
├── work_experiences (工作经历) [N:1] → resumes
└── projects (项目经验) [N:1] → resumes

positions (职位表) [标准化]
└── work_experiences (工作经历) [N:1] → resumes
```

### 4. 模板和文件中心 (Template & File Center)
```
resume_templates (简历模板)
└── resumes (简历) [N:1] → template_id

files (文件表)
└── users (用户) [N:1] → user_id
```

## 详细关联关系

### 用户相关关联
| 主表 | 关联表 | 关系类型 | 外键 | 说明 |
|------|--------|----------|------|------|
| users | user_profiles | 1:1 | user_id | 用户详细资料 |
| users | user_settings | 1:1 | user_id | 用户个性化设置 |
| users | user_sessions | 1:N | user_id | 用户登录会话 |
| users | points | 1:1 | user_id | 用户积分账户 |
| users | point_history | 1:N | user_id | 积分变动历史 |
| users | resumes | 1:N | user_id | 用户创建的简历 |
| users | files | 1:N | user_id | 用户上传的文件 |

### 简历相关关联 - 新架构
| 主表 | 关联表 | 关系类型 | 外键 | 说明 | 存储位置 |
|------|--------|----------|------|------|----------|
| resume_metadata | resume_files | 1:N | file_id | 简历文件元数据 | MySQL |
| resume_metadata | resume_parsing_tasks | 1:N | resume_id | 解析任务元数据 | MySQL |
| resume_metadata | resume_templates | N:1 | template_id | 使用的模板 | MySQL |
| resume_metadata | resume_analyses | 1:N | resume_id | 简历分析结果 | MySQL |
| resume_metadata | resume_comments | 1:N | resume_id | 简历评论 | MySQL |
| resume_metadata | resume_likes | 1:N | resume_id | 简历点赞 | MySQL |
| resume_metadata | resume_shares | 1:N | resume_id | 简历分享 | MySQL |
| resume_metadata | resume_skills | 1:N | resume_id | 简历技能关联 | MySQL |
| resume_content | parsed_resume_data | 1:N | resume_content_id | 解析结果 | SQLite |
| resume_content | user_privacy_settings | 1:1 | resume_content_id | 隐私设置 | SQLite |
| resume_content | resume_versions | 1:N | resume_content_id | 版本历史 | SQLite |
| resume_content | user_custom_fields | 1:N | resume_content_id | 自定义字段 | SQLite |
| resume_content | resume_access_logs | 1:N | resume_content_id | 访问日志 | SQLite |
| resume_metadata | resume_content | 1:1 | id ↔ resume_metadata_id | 跨数据库关联 | MySQL ↔ SQLite |

### 标准化数据关联
| 主表 | 关联表 | 关系类型 | 外键 | 说明 |
|------|--------|----------|------|------|
| skills | resume_skills | 1:N | skill_id | 技能被简历使用 |
| companies | work_experiences | 1:N | company_id | 公司的工作经历 |
| companies | projects | 1:N | company_id | 公司的项目经验 |
| positions | work_experiences | 1:N | position_id | 职位的工作经历 |

### 社交功能关联
| 主表 | 关联表 | 关系类型 | 外键 | 说明 |
|------|--------|----------|------|------|
| users | resume_comments | 1:N | user_id | 用户发表的评论 |
| users | resume_likes | 1:N | user_id | 用户的点赞记录 |
| users | resume_shares | 1:N | user_id | 用户的分享记录 |
| resume_comments | resume_comments | 1:N | parent_id | 评论回复关系 |

## 数据流向分析

### 1. 用户注册流程
```
用户注册 → users表 → user_profiles表 → user_settings表 → points表(初始积分)
```

### 2. 简历创建流程 - 新架构
```
📝 Markdown编辑模式：
用户输入 → 创建resume_metadata (MySQL) → 创建resume_content (SQLite) → 创建版本历史 → 设置隐私

📁 文件上传模式：
文件上传 → 保存文件 → 创建resume_files (MySQL) → 创建resume_metadata (MySQL) → 创建resume_content (SQLite) → 启动解析任务 → 更新解析结果

🎨 模板创建模式：
选择模板 → 获取模板内容 → 创建resume_metadata (MySQL) → 创建resume_content (SQLite) → 设置模板关联 → 创建版本历史

🔍 解析流程：
文件上传 → 创建parsing_task (MySQL) → 异步解析 → 更新parsed_resume_data (SQLite) → 更新parsing_status (MySQL)
```

### 3. 社交互动流程 - 新架构
```
👀 浏览简历：
用户浏览 → 记录access_log (SQLite) → 更新view_count (MySQL) → 积分奖励

👍 点赞简历：
用户点赞 → 创建resume_likes (MySQL) → 更新view_count (MySQL) → 积分奖励 → point_history (MySQL)

💬 评论简历：
用户评论 → 创建resume_comments (MySQL) → 积分奖励 → point_history (MySQL)

📤 分享简历：
用户分享 → 创建resume_shares (MySQL) → 积分奖励 → point_history (MySQL)
```

### 4. 积分系统流程
```
用户操作 → 触发积分规则 → point_history表 → 更新points表 → 用户积分变化
```

## 关键设计模式

### 1. 数据分离存储模式 - 新架构核心
- **MySQL元数据存储**: 只存储元数据（用户ID、标题、状态、统计等）
- **SQLite内容存储**: 只存储实际内容（简历内容、解析结果、隐私设置等）
- **用户数据隔离**: 每个用户有独立的SQLite数据库，确保数据安全
- **跨数据库关联**: 通过ID关联实现MySQL和SQLite的数据一致性

### 2. 多创建方式设计模式
- **Markdown编辑**: 直接编辑Markdown格式的简历内容
- **文件上传**: 支持PDF、DOCX等文件格式的上传和解析
- **模板创建**: 基于预定义模板快速创建简历
- **统一处理**: 不同创建方式最终都遵循相同的数据存储架构

### 3. 隐私控制设计模式
- **细粒度权限**: 支持公开、私有、朋友等多种隐私级别
- **访问控制**: 详细的查看、下载、搜索权限控制
- **审计追踪**: 完整的访问日志和操作记录
- **用户自主**: 用户完全控制自己的数据隐私设置

### 4. 版本管理设计模式
- **内容版本**: 支持简历内容的版本历史管理
- **变更追踪**: 记录每次变更的描述和时间
- **快照存储**: 保存每个版本的完整内容快照
- **回滚支持**: 支持回滚到任意历史版本

### 5. 标准化设计模式
- **技能标准化**: 所有技能统一管理，避免重复和拼写错误
- **公司标准化**: 公司信息统一，支持公司认证和验证
- **职位标准化**: 职位分类和级别标准化，便于搜索和匹配

### 6. 关联表设计模式
- **多对多关系**: 简历-技能、简历-公司等通过关联表管理
- **软删除**: 使用deleted_at字段实现软删除
- **审计字段**: created_at, updated_at, deleted_at统一管理

### 7. 社交功能设计模式
- **评论系统**: 支持多级回复，审核机制
- **点赞系统**: 防重复点赞，计数统计
- **分享系统**: 多平台分享，链接记录

### 8. 积分系统设计模式
- **积分账户**: 用户积分余额管理
- **积分历史**: 完整的积分变动记录
- **积分规则**: 可配置的积分获得和消费规则

## 性能优化策略

### 1. 索引优化
- **主键索引**: 所有表的主键自动索引
- **外键索引**: 所有外键字段建立索引
- **查询索引**: 常用查询字段建立复合索引
- **唯一索引**: 邮箱、用户名等唯一字段建立唯一索引

### 2. 查询优化
- **分页查询**: 大数据量查询使用分页
- **缓存策略**: 热点数据使用Redis缓存
- **读写分离**: 读操作使用从库，写操作使用主库

### 3. 数据分区
- **时间分区**: 按时间分区历史数据
- **业务分区**: 按业务类型分区数据

## 扩展性设计

### 1. 水平扩展
- **分库分表**: 支持按用户ID分库分表
- **读写分离**: 支持主从复制和读写分离
- **负载均衡**: 支持多实例负载均衡

### 2. 功能扩展
- **插件化**: 支持功能模块插件化
- **配置化**: 支持业务规则配置化
- **API化**: 支持微服务API化

### 3. 数据扩展
- **JSON字段**: 支持灵活的JSON数据存储
- **版本控制**: 支持数据版本控制
- **数据迁移**: 支持平滑的数据迁移

## 安全设计

### 1. 数据安全
- **加密存储**: 敏感数据加密存储
- **访问控制**: 基于角色的访问控制
- **审计日志**: 完整的操作审计日志
- **数据库权限分离**: PostgreSQL权限分级管理

### 2. 接口安全
- **认证授权**: JWT token认证
- **API限流**: 接口访问频率限制
- **参数验证**: 严格的参数验证

### 3. 系统安全
- **SQL注入防护**: 参数化查询
- **XSS防护**: 输入输出过滤
- **CSRF防护**: CSRF token验证

### 4. PostgreSQL权限管理 - 新架构
- **系统超级管理员**: 拥有所有权限，包括BYPASS RLS
- **项目团队成员**: 拥有数据库连接和表操作权限，可绕过RLS
- **普通用户**: 只能访问自己的向量数据，通过RLS策略限制
- **行级安全策略**: 启用RLS保护用户数据隔离
- **会话变量控制**: 使用`app.current_user_id`进行权限控制

---

**设计原则**: 标准化、模块化、关联化、可扩展、高性能、安全可靠
