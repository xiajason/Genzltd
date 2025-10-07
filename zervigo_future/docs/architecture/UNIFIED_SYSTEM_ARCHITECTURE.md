# 统一系统架构设计文档

## 📋 概述

本文档基于Company服务和Resume服务的相互借鉴学习，设计出统一的系统架构，实现取长补短、事半功倍的效果。

## 🏗️ 统一架构设计原则

### 1. **数据边界清晰化**
- **MySQL**: 核心业务数据、权限管理、元数据存储
- **PostgreSQL**: 向量数据、AI分析结果、语义搜索
- **Neo4j**: 地理位置关系、复杂关系网络、图分析
- **Redis**: 缓存、会话管理、临时数据
- **SQLite**: 用户私有数据、敏感信息、本地缓存

### 2. **服务职责明确化**
- **Company Service**: 企业管理、认证授权、地理位置
- **Resume Service**: 简历管理、向量搜索、用户隐私
- **Job Service**: 职位管理、匹配算法、AI分析
- **Location Service**: 地理位置管理、关系分析、匹配推荐

### 3. **数据同步统一化**
- 统一的数据同步服务
- 一致性检查机制
- 冲突解决策略
- 性能优化方案

## 🔄 统一数据同步架构

### 核心同步服务
```go
// 统一数据同步服务
type UnifiedDataSyncService struct {
    mysqlDB      *gorm.DB
    postgresDB   *gorm.DB
    neo4jDriver  neo4j.Driver
    redisClient  *redis.Client
    sqliteManager *SecureSQLiteManager
    
    // 同步队列
    syncQueue    chan SyncTask
    // 一致性检查器
    consistencyChecker *ConsistencyChecker
    // 性能监控
    performanceMonitor *PerformanceMonitor
}

// 同步任务
type SyncTask struct {
    ID          string                 `json:"id"`
    Type        string                 `json:"type"`        // company, resume, job, location
    Action      string                 `json:"action"`      // create, update, delete
    EntityID    uint                   `json:"entity_id"`
    Data        map[string]interface{} `json:"data"`
    Priority    int                    `json:"priority"`    // 1-10, 10最高
    RetryCount  int                    `json:"retry_count"`
    CreatedAt   time.Time              `json:"created_at"`
    UpdatedAt   time.Time              `json:"updated_at"`
}

// 执行同步任务
func (uds *UnifiedDataSyncService) ExecuteSyncTask(task SyncTask) error {
    // 1. 验证任务数据
    if err := uds.validateTask(task); err != nil {
        return err
    }
    
    // 2. 根据类型执行同步
    switch task.Type {
    case "company":
        return uds.syncCompanyData(task)
    case "resume":
        return uds.syncResumeData(task)
    case "job":
        return uds.syncJobData(task)
    case "location":
        return uds.syncLocationData(task)
    default:
        return fmt.Errorf("未知的同步类型: %s", task.Type)
    }
}

// 企业数据同步
func (uds *UnifiedDataSyncService) syncCompanyData(task SyncTask) error {
    companyID := task.EntityID
    
    // 1. 从MySQL获取核心数据
    var company Company
    if err := uds.mysqlDB.First(&company, companyID).Error; err != nil {
        return err
    }
    
    // 2. 同步到PostgreSQL（职位相关数据）
    if err := uds.syncCompanyToPostgreSQL(company); err != nil {
        return err
    }
    
    // 3. 同步到Neo4j（地理位置和关系数据）
    if err := uds.syncCompanyToNeo4j(company); err != nil {
        return err
    }
    
    // 4. 更新缓存
    if err := uds.updateCompanyCache(company); err != nil {
        return err
    }
    
    return nil
}

// 简历数据同步
func (uds *UnifiedDataSyncService) syncResumeData(task SyncTask) error {
    resumeID := task.EntityID
    userID := task.Data["user_id"].(uint)
    
    // 1. 从MySQL获取元数据
    var resume Resume
    if err := uds.mysqlDB.First(&resume, resumeID).Error; err != nil {
        return err
    }
    
    // 2. 从SQLite获取内容
    sqliteDB, err := uds.sqliteManager.GetUserDatabase(userID)
    if err != nil {
        return err
    }
    
    var content ResumeContent
    if err := sqliteDB.Where("resume_metadata_id = ?", resumeID).First(&content).Error; err != nil {
        return err
    }
    
    // 3. 同步到PostgreSQL（向量数据）
    if err := uds.syncResumeToPostgreSQL(resume, content); err != nil {
        return err
    }
    
    // 4. 同步到Neo4j（地理位置和关系数据）
    if err := uds.syncResumeToNeo4j(resume, userID); err != nil {
        return err
    }
    
    return nil
}
```

### 一致性检查机制
```go
// 一致性检查器
type ConsistencyChecker struct {
    mysqlDB      *gorm.DB
    postgresDB   *gorm.DB
    neo4jDriver  neo4j.Driver
    redisClient  *redis.Client
    sqliteManager *SecureSQLiteManager
}

// 检查企业数据一致性
func (cc *ConsistencyChecker) CheckCompanyConsistency(companyID uint) error {
    // 1. 检查MySQL核心数据
    var company Company
    if err := cc.mysqlDB.First(&company, companyID).Error; err != nil {
        return fmt.Errorf("MySQL数据缺失: %v", err)
    }
    
    // 2. 检查PostgreSQL向量数据
    var jobCount int64
    cc.postgresDB.Model(&JobDescription{}).Where("company_id = ?", companyID).Count(&jobCount)
    
    // 3. 检查Neo4j地理位置数据
    session := cc.neo4jDriver.NewSession(neo4j.SessionConfig{})
    defer session.Close()
    
    result, err := session.Run("MATCH (c:Company {id: $id}) RETURN c", map[string]interface{}{"id": companyID})
    if err != nil {
        return fmt.Errorf("Neo4j数据检查失败: %v", err)
    }
    
    if !result.Next() {
        return fmt.Errorf("Neo4j数据缺失")
    }
    
    // 4. 检查缓存数据
    cacheKey := fmt.Sprintf("company:%d", companyID)
    if _, err := cc.redisClient.Get(cacheKey).Result(); err != nil {
        return fmt.Errorf("缓存数据缺失")
    }
    
    return nil
}

// 检查简历数据一致性
func (cc *ConsistencyChecker) CheckResumeConsistency(resumeID uint, userID uint) error {
    // 1. 检查MySQL元数据
    var resume Resume
    if err := cc.mysqlDB.First(&resume, resumeID).Error; err != nil {
        return fmt.Errorf("MySQL数据缺失: %v", err)
    }
    
    // 2. 检查SQLite内容数据
    sqliteDB, err := cc.sqliteManager.GetUserDatabase(userID)
    if err != nil {
        return fmt.Errorf("SQLite连接失败: %v", err)
    }
    
    var content ResumeContent
    if err := sqliteDB.Where("resume_metadata_id = ?", resumeID).First(&content).Error; err != nil {
        return fmt.Errorf("SQLite数据缺失: %v", err)
    }
    
    // 3. 检查PostgreSQL向量数据
    var vectorCount int64
    cc.postgresDB.Model(&ResumeVector{}).Where("resume_id = ?", resumeID).Count(&vectorCount)
    
    // 4. 检查Neo4j关系数据
    session := cc.neo4jDriver.NewSession(neo4j.SessionConfig{})
    defer session.Close()
    
    result, err := session.Run("MATCH (r:Resume {id: $id}) RETURN r", map[string]interface{}{"id": resumeID})
    if err != nil {
        return fmt.Errorf("Neo4j数据检查失败: %v", err)
    }
    
    if !result.Next() {
        return fmt.Errorf("Neo4j数据缺失")
    }
    
    return nil
}
```

## 🚀 统一性能优化架构

### 缓存管理
```go
// 统一缓存管理器
type UnifiedCacheManager struct {
    redisClient *redis.Client
    mysqlDB     *gorm.DB
    postgresDB  *gorm.DB
    neo4jDriver neo4j.Driver
}

// 获取企业数据（带缓存）
func (ucm *UnifiedCacheManager) GetCompanyWithCache(companyID uint) (*Company, error) {
    // 1. 尝试从缓存获取
    cacheKey := fmt.Sprintf("company:%d", companyID)
    if cached, err := ucm.redisClient.Get(cacheKey).Result(); err == nil {
        var company Company
        if err := json.Unmarshal([]byte(cached), &company); err == nil {
            return &company, nil
        }
    }
    
    // 2. 从数据库获取
    var company Company
    if err := ucm.mysqlDB.Preload("CompanyUsers").First(&company, companyID).Error; err != nil {
        return nil, err
    }
    
    // 3. 缓存结果
    companyJSON, _ := json.Marshal(company)
    ucm.redisClient.Set(cacheKey, companyJSON, time.Hour)
    
    return &company, nil
}

// 获取简历数据（带缓存）
func (ucm *UnifiedCacheManager) GetResumeWithCache(resumeID uint, userID uint) (*Resume, error) {
    // 1. 尝试从缓存获取
    cacheKey := fmt.Sprintf("resume:%d:%d", resumeID, userID)
    if cached, err := ucm.redisClient.Get(cacheKey).Result(); err == nil {
        var resume Resume
        if err := json.Unmarshal([]byte(cached), &resume); err == nil {
            return &resume, nil
        }
    }
    
    // 2. 从MySQL获取元数据
    var resume Resume
    if err := ucm.mysqlDB.First(&resume, resumeID).Error; err != nil {
        return nil, err
    }
    
    // 3. 从SQLite获取内容
    sqliteDB, err := GetSecureUserDatabase(userID)
    if err != nil {
        return nil, err
    }
    
    var content ResumeContent
    if err := sqliteDB.Where("resume_metadata_id = ?", resumeID).First(&content).Error; err == nil {
        resume.Content = content.Content
        resume.ParsingStatus = content.ParsingStatus
    }
    
    // 4. 缓存结果
    resumeJSON, _ := json.Marshal(resume)
    ucm.redisClient.Set(cacheKey, resumeJSON, time.Hour)
    
    return &resume, nil
}

// 批量获取数据（避免N+1查询）
func (ucm *UnifiedCacheManager) GetCompaniesBatch(companyIDs []uint) ([]Company, error) {
    var companies []Company
    if err := ucm.mysqlDB.Where("id IN ?", companyIDs).Find(&companies).Error; err != nil {
        return nil, err
    }
    
    // 批量缓存
    for _, company := range companies {
        cacheKey := fmt.Sprintf("company:%d", company.ID)
        companyJSON, _ := json.Marshal(company)
        ucm.redisClient.Set(cacheKey, companyJSON, time.Hour)
    }
    
    return companies, nil
}
```

### 权限管理
```go
// 统一权限管理器
type UnifiedPermissionManager struct {
    mysqlDB    *gorm.DB
    redisClient *redis.Client
    cacheTTL   time.Duration
}

// 检查企业权限
func (upm *UnifiedPermissionManager) CheckCompanyAccess(userID uint, companyID uint, action string) error {
    // 1. 尝试从缓存获取权限
    cacheKey := fmt.Sprintf("company_permission:%d:%d:%s", userID, companyID, action)
    if cached, err := upm.redisClient.Get(cacheKey).Result(); err == nil {
        if cached == "true" {
            return nil
        }
        return fmt.Errorf("权限不足")
    }
    
    // 2. 检查系统管理员权限
    var user User
    if err := upm.mysqlDB.First(&user, userID).Error; err == nil {
        if user.Role == "admin" || user.Role == "super_admin" {
            upm.redisClient.Set(cacheKey, "true", upm.cacheTTL)
            return nil
        }
    }
    
    // 3. 检查企业权限
    var companyUser CompanyUser
    if err := upm.mysqlDB.Where("company_id = ? AND user_id = ? AND status = ?", 
        companyID, userID, "active").First(&companyUser).Error; err == nil {
        upm.redisClient.Set(cacheKey, "true", upm.cacheTTL)
        return nil
    }
    
    upm.redisClient.Set(cacheKey, "false", upm.cacheTTL)
    return fmt.Errorf("权限不足")
}

// 检查简历权限
func (upm *UnifiedPermissionManager) CheckResumeAccess(userID uint, resumeID uint, action string) error {
    // 1. 尝试从缓存获取权限
    cacheKey := fmt.Sprintf("resume_permission:%d:%d:%s", userID, resumeID, action)
    if cached, err := upm.redisClient.Get(cacheKey).Result(); err == nil {
        if cached == "true" {
            return nil
        }
        return fmt.Errorf("权限不足")
    }
    
    // 2. 检查系统管理员权限
    var user User
    if err := upm.mysqlDB.First(&user, userID).Error; err == nil {
        if user.Role == "admin" || user.Role == "super_admin" {
            upm.redisClient.Set(cacheKey, "true", upm.cacheTTL)
            return nil
        }
    }
    
    // 3. 检查简历所有者权限
    var resume Resume
    if err := upm.mysqlDB.First(&resume, resumeID).Error; err == nil {
        if resume.UserID == userID {
            upm.redisClient.Set(cacheKey, "true", upm.cacheTTL)
            return nil
        }
    }
    
    upm.redisClient.Set(cacheKey, "false", upm.cacheTTL)
    return fmt.Errorf("权限不足")
}
```

## 📊 统一监控架构

### 性能监控
```go
// 统一性能监控器
type UnifiedPerformanceMonitor struct {
    redisClient *redis.Client
    metrics     map[string]interface{}
}

// 记录数据库查询性能
func (upm *UnifiedPerformanceMonitor) RecordDatabaseQuery(dbType string, query string, duration time.Duration) {
    metric := DatabaseQueryMetric{
        DBType:   dbType,
        Query:    query,
        Duration: duration,
        Timestamp: time.Now(),
    }
    
    // 存储到Redis
    metricJSON, _ := json.Marshal(metric)
    upm.redisClient.LPush("db_query_metrics", metricJSON)
    
    // 更新统计信息
    upm.updateQueryStats(dbType, duration)
}

// 记录缓存命中率
func (upm *UnifiedPerformanceMonitor) RecordCacheHit(cacheKey string, hit bool) {
    metric := CacheHitMetric{
        CacheKey: cacheKey,
        Hit:      hit,
        Timestamp: time.Now(),
    }
    
    // 存储到Redis
    metricJSON, _ := json.Marshal(metric)
    upm.redisClient.LPush("cache_hit_metrics", metricJSON)
    
    // 更新统计信息
    upm.updateCacheStats(hit)
}

// 记录同步任务性能
func (upm *UnifiedPerformanceMonitor) RecordSyncTask(taskType string, duration time.Duration, success bool) {
    metric := SyncTaskMetric{
        TaskType:  taskType,
        Duration:  duration,
        Success:   success,
        Timestamp: time.Now(),
    }
    
    // 存储到Redis
    metricJSON, _ := json.Marshal(metric)
    upm.redisClient.LPush("sync_task_metrics", metricJSON)
    
    // 更新统计信息
    upm.updateSyncStats(taskType, success)
}
```

## 🎯 统一实施计划

### 第一阶段：基础架构建设 (3-4天)
- **Day 1**: 统一数据同步服务设计
- **Day 2**: 一致性检查机制实现
- **Day 3**: 缓存管理架构实现
- **Day 4**: 权限管理统一化

### 第二阶段：服务集成优化 (4-5天)
- **Day 5**: Company服务集成
- **Day 6**: Resume服务集成
- **Day 7**: Job服务集成
- **Day 8**: Location服务集成
- **Day 9**: 服务间通信优化

### 第三阶段：监控和优化 (2-3天)
- **Day 10**: 性能监控实现
- **Day 11**: 日志系统统一
- **Day 12**: 告警机制实现

## 📝 总结

### 统一架构的优势
1. **数据一致性**: 统一的数据同步和一致性检查
2. **性能优化**: 统一的缓存管理和查询优化
3. **权限管理**: 统一的权限检查和缓存机制
4. **监控完善**: 统一的性能监控和告警系统
5. **维护简单**: 统一的架构设计，降低维护成本

### 实施建议
1. **渐进式迁移**: 逐步将现有服务迁移到统一架构
2. **性能测试**: 每个阶段都要进行性能测试
3. **监控完善**: 建立完善的监控和告警机制
4. **文档更新**: 及时更新技术文档和部署文档

---

**文档版本**: v1.0  
**创建时间**: 2025-01-16  
**最后更新**: 2025-01-16  
**状态**: 设计完成  
**维护人员**: AI Assistant
