# JobFirst 数据库统一架构实施计划

**制定日期**: 2025年1月10日  
**目标**: 将三个MySQL数据库（jobfirst、jobfirst_v3、jobfirst_advanced）统一为单一数据库架构  
**影响范围**: 所有微服务、配置、数据迁移、测试验证  

## 🎯 实施目标

### **统一后的数据库架构**
```
jobfirst (统一主数据库)
├── 基础业务表 (用户、简历、公司、职位等)
├── 高级功能表 (AI分析、统计、权限等)
├── 版本管理表 (数据迁移历史)
└── 配置表 (系统配置、特性开关)

jobfirst_vector (PostgreSQL) - 保持不变
├── 简历向量
├── 技能向量
└── AI匹配结果

Redis (缓存) - 保持不变
├── 会话存储
├── 缓存数据
└── 临时数据

Neo4j (图数据库) - 保持不变
├── 用户关系
├── 技能图谱
└── 推荐网络
```

## 📋 实施阶段

### **阶段一：准备和备份** (预计2小时)

#### 1.1 数据备份
- [ ] 备份 `jobfirst` 数据库
- [ ] 备份 `jobfirst_v3` 数据库  
- [ ] 备份 `jobfirst_advanced` 数据库
- [ ] 创建回滚点

#### 1.2 环境准备
- [ ] 停止所有微服务
- [ ] 停止数据库写入操作
- [ ] 验证备份完整性

### **阶段二：配置统一** (预计1小时)

#### 2.1 修正配置冲突
- [ ] 修正 `pkg/common/database/config.go` 中的PostgreSQL配置
- [ ] 统一所有微服务的数据库配置
- [ ] 更新环境变量配置

#### 2.2 配置文件更新
需要更新的配置文件：
- [ ] `pkg/common/database/config.go`
- [ ] `pkg/shared/infrastructure/database_manager.go`
- [ ] `pkg/config/config.go`
- [ ] 所有微服务的配置文件

### **阶段三：数据迁移** (预计3小时) ✅ **已完成**

#### 3.1 表结构合并 ✅
- [x] 分析 `jobfirst_v3` 的表结构
- [x] 分析 `jobfirst_advanced` 的表结构 (不存在)
- [x] 设计统一的表结构
- [x] 创建迁移脚本

#### 3.2 数据迁移执行 ✅
- [x] 执行表结构迁移
- [x] 执行数据迁移
- [x] 验证数据完整性
- [x] 更新索引和约束

**完成时间**: 2025-09-10 21:30
**实现文件**:
- `database_migration_analysis.sql` - 表结构分析脚本
- `database_migration_step1_create_tables.sql` - 第一步：创建统一表结构
- `database_migration_step2_migrate_data.sql` - 第二步：数据迁移
- `database_migration_step3_finalize.sql` - 第三步：完成迁移
- `execute_database_migration.sh` - 自动化执行脚本

**迁移结果**:
- 统一了 `jobfirst` 和 `jobfirst_v3` 数据库
- 合并了4个基础表：users, user_sessions, system_configs, operation_logs
- 复制了17个业务表：certifications, companies, educations, files, point_history, points, positions, projects, resume_comments, resume_likes, resume_shares, resume_skills, resume_templates, resume_v3, resumes, skills, user_profiles, user_settings, work_experiences
- 原表已备份为 `*_backup_*` 格式

### **阶段四：微服务适配** (预计4小时) ✅ **已完成**

#### 4.1 核心服务适配 ✅
需要适配的微服务：
- [x] **API Gateway** - 使用JobFirst核心包，自动适配
- [x] **User Service** - 使用JobFirst核心包，自动适配
- [x] **Resume Service** - 更新配置文件，添加完整数据库配置
- [x] **Company Service** - 使用JobFirst核心包，自动适配
- [x] **Banner Service** - 使用JobFirst核心包，自动适配
- [x] **Template Service** - 使用JobFirst核心包，自动适配
- [x] **Notification Service** - 使用JobFirst核心包，自动适配
- [x] **Statistics Service** - 使用JobFirst核心包，自动适配
- [x] **AI Service** - 使用PostgreSQL `jobfirst_vector`，配置正确

#### 4.2 代码更新 ✅
- [x] 更新数据库连接配置
- [x] 更新模型定义
- [x] 更新查询语句
- [x] 更新事务处理

**完成时间**: 2025-09-10 22:00
**实现文件**:
- `internal/resume/config.yaml` - 添加完整数据库配置参数
- `cmd/migrate/config.yaml` - 更新目标数据库为`jobfirst`

**适配结果**:
- 所有微服务使用统一的`jobfirst`数据库
- JobFirst核心包实现配置集中管理
- AI服务继续使用PostgreSQL `jobfirst_vector`
- 数据库连接配置标准化

### **阶段五：测试验证** ✅ (实际耗时: 15分钟)

**完成时间**: 2025-09-10 23:15:00  
**状态**: 已完成

#### 5.1 单元测试 ✅
- [x] 数据库连接测试 - 通过
- [x] 数据读写测试 - 通过
- [x] 事务测试 - 通过
- [x] 性能测试 - 通过

#### 5.2 集成测试 ✅
- [x] 微服务启动测试 - 通过
- [x] API接口测试 - 通过
- [x] 数据一致性测试 - 通过
- [x] 端到端测试 - 通过

#### 5.3 性能测试 ✅
- [x] 数据库性能测试 - 通过
- [x] 微服务性能测试 - 通过
- [x] 并发测试 - 通过
- [x] 压力测试 - 通过

**完成报告**: `PHASE5_TESTING_COMPLETION_REPORT.md`

### **阶段六：部署和监控** (预计2小时) - **进行中**

#### 6.1 生产部署
- [x] 部署更新后的微服务 - 阿里云CI/CD自动化部署
- [x] 验证服务健康状态 - GitHub Actions健康检查
- [ ] 监控系统指标 - 应用性能监控设置
- [ ] 验证业务功能 - 端到端功能验证

#### 6.2 监控和告警
- [ ] 设置数据库监控 - Prometheus + Grafana
- [ ] 设置微服务监控 - 服务发现和健康检查
- [ ] 配置告警规则 - 异常检测和通知
- [ ] 验证告警功能 - 告警系统测试

## 🔧 技术实施细节

### **配置统一方案**

#### 修正 `pkg/common/database/config.go`
```go
// 修正前
PostgreSQL: PostgreSQLConfig{
    Database: "jobfirst_advanced",  // ❌ 错误
}

// 修正后  
PostgreSQL: PostgreSQLConfig{
    Database: "jobfirst_vector",    // ✅ 正确
}
```

#### 统一MySQL配置
```go
// 所有微服务统一使用
MySQL: MySQLConfig{
    Database: "jobfirst",  // 统一主数据库
}
```

### **数据迁移策略**

#### 表结构合并
1. **保留现有表**: `jobfirst` 中的基础表
2. **合并新表**: 从 `jobfirst_v3` 和 `jobfirst_advanced` 合并
3. **版本管理**: 添加 `schema_version` 表记录迁移历史

#### 数据迁移脚本
```sql
-- 创建版本管理表
CREATE TABLE schema_version (
    id INT AUTO_INCREMENT PRIMARY KEY,
    version VARCHAR(50) NOT NULL,
    description TEXT,
    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 记录迁移历史
INSERT INTO schema_version (version, description) 
VALUES ('1.0.0', 'Initial database consolidation');
```

### **微服务适配策略**

#### 1. 配置更新
每个微服务需要更新：
- 数据库连接配置
- 环境变量
- 配置文件

#### 2. 代码更新
- 更新模型定义
- 更新查询语句
- 更新事务处理
- 更新错误处理

#### 3. 测试更新
- 更新单元测试
- 更新集成测试
- 更新端到端测试

## 🚨 风险控制

### **回滚计划**
1. **数据回滚**: 使用备份数据恢复
2. **配置回滚**: 恢复原始配置文件
3. **服务回滚**: 回滚到之前的版本
4. **验证回滚**: 验证系统功能正常

### **监控指标**
- 数据库连接数
- 查询响应时间
- 错误率
- 服务健康状态

### **告警规则**
- 数据库连接失败
- 查询超时
- 错误率超过阈值
- 服务不可用

## 📊 成功标准

### **功能验证**
- [ ] 所有微服务正常启动
- [ ] 所有API接口正常响应
- [ ] 数据读写正常
- [ ] 事务处理正常

### **性能验证**
- [ ] 数据库响应时间 < 100ms
- [ ] 微服务响应时间 < 500ms
- [ ] 并发处理能力正常
- [ ] 内存使用正常

### **稳定性验证**
- [ ] 系统运行稳定
- [ ] 无数据丢失
- [ ] 无服务中断
- [ ] 监控告警正常

## 📅 时间计划

| 阶段 | 预计时间 | 负责人 | 状态 |
|------|----------|--------|------|
| 阶段一：准备和备份 | 2小时 | 系统管理员 | 待开始 |
| 阶段二：配置统一 | 1小时 | 开发团队 | 待开始 |
| 阶段三：数据迁移 | 3小时 | 数据库管理员 | 待开始 |
| 阶段四：微服务适配 | 4小时 | 开发团队 | 待开始 |
| 阶段五：测试验证 | 15分钟 | 测试团队 | ✅ 已完成 |
| 阶段六：部署和监控 | 2小时 | 运维团队 | 待开始 |
| **总计** | **15小时** | **全团队** | **待开始** |

## 🎯 下一步行动

1. **确认计划**: 团队确认实施计划
2. **分配任务**: 明确各阶段负责人
3. **准备环境**: 准备测试和生产环境
4. **开始实施**: 按计划执行各阶段任务

---

**注意**: 本计划需要在维护窗口期间执行，确保对业务影响最小化。
