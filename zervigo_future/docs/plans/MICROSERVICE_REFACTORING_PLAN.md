# 微服务重构实施计划

## 📋 项目概述

基于业务需求分析，对三个微服务进行重构，明确业务边界，避免功能重复。

### 重构目标
1. **Template Service** - 保留并优化模板管理功能
2. **Statistics Service** - 重构为真正的数据统计服务
3. **Banner Service** - 重构为内容管理服务，支持评论和Markdown组件

---

## 🎯 第一阶段：Template Service 优化 (1-2天)

### 1.1 当前状态分析
- ✅ 已集成jobfirst-core
- ✅ 业务逻辑正确
- 🔧 需要优化API设计和数据结构

### 1.2 优化内容

#### 数据结构优化
```go
type Template struct {
    ID          uint      `json:"id" gorm:"primaryKey"`
    Name        string    `json:"name" gorm:"size:200;not null"`
    Category    string    `json:"category" gorm:"size:100;not null"`
    Description string    `json:"description" gorm:"type:text"`
    Content     string    `json:"content" gorm:"type:text"`
    Variables   []string  `json:"variables" gorm:"type:json"`
    Preview     string    `json:"preview" gorm:"type:text"`        // 新增：预览内容
    Usage       int       `json:"usage" gorm:"default:0"`          // 新增：使用次数
    Rating      float64   `json:"rating" gorm:"default:0"`         // 新增：评分
    IsActive    bool      `json:"is_active" gorm:"default:true"`
    CreatedBy   uint      `json:"created_by" gorm:"not null"`
    CreatedAt   time.Time `json:"created_at"`
    UpdatedAt   time.Time `json:"updated_at"`
}
```

#### API优化
- 添加模板评分功能
- 添加使用统计功能
- 优化分类管理
- 添加模板搜索功能

### 1.3 实施步骤
1. 备份当前代码
2. 更新数据结构
3. 优化API接口
4. 添加新功能
5. 测试验证

---

## 📊 第二阶段：Statistics Service 重构 (2-3天)

### 2.1 业务重新定位
- **目标**: 数据统计和分析服务
- **功能**: 用户行为统计、系统使用统计、报表生成
- **与前端关系**: 低耦合，前端只需展示统计结果

### 2.2 新的数据结构设计

#### 统计指标模型
```go
type StatisticsMetric struct {
    ID          uint      `json:"id" gorm:"primaryKey"`
    Name        string    `json:"name" gorm:"size:100;not null;uniqueIndex"`
    DisplayName string    `json:"display_name" gorm:"size:200;not null"`
    Description string    `json:"description" gorm:"type:text"`
    Category    string    `json:"category" gorm:"size:50;not null"`
    Unit        string    `json:"unit" gorm:"size:20"`
    IsActive    bool      `json:"is_active" gorm:"default:true"`
    CreatedAt   time.Time `json:"created_at"`
    UpdatedAt   time.Time `json:"updated_at"`
}

// 统计数据记录
type StatisticsRecord struct {
    ID        uint      `json:"id" gorm:"primaryKey"`
    MetricID  uint      `json:"metric_id" gorm:"not null"`
    Metric    StatisticsMetric `json:"metric" gorm:"foreignKey:MetricID"`
    Value     float64   `json:"value" gorm:"not null"`
    Period    string    `json:"period" gorm:"size:20;not null"` // daily, weekly, monthly
    Date      time.Time `json:"date" gorm:"not null"`
    Metadata  string    `json:"metadata" gorm:"type:json"`
    CreatedAt time.Time `json:"created_at"`
}

// 用户行为统计
type UserBehavior struct {
    ID        uint      `json:"id" gorm:"primaryKey"`
    UserID    uint      `json:"user_id" gorm:"not null"`
    Action    string    `json:"action" gorm:"size:100;not null"`
    Resource  string    `json:"resource" gorm:"size:100"`
    Duration  int       `json:"duration"` // 停留时间(秒)
    IP        string    `json:"ip" gorm:"size:45"`
    UserAgent string    `json:"user_agent" gorm:"size:500"`
    CreatedAt time.Time `json:"created_at"`
}
```

### 2.3 新的API设计

#### 公开API (无需认证)
```go
// 获取统计概览
GET /api/v1/statistics/public/overview

// 获取特定指标统计
GET /api/v1/statistics/public/metrics/:metric_name

// 获取时间范围统计
GET /api/v1/statistics/public/metrics/:metric_name/trend?start_date=&end_date=

// 获取分类统计
GET /api/v1/statistics/public/categories/:category
```

#### 管理API (需要认证)
```go
// 创建统计指标
POST /api/v1/statistics/metrics

// 记录统计数据
POST /api/v1/statistics/records

// 记录用户行为
POST /api/v1/statistics/behaviors

// 生成报表
GET /api/v1/statistics/reports/:type
```

### 2.4 实施步骤
1. 备份当前代码
2. 重新设计数据结构
3. 重写业务逻辑
4. 实现统计功能
5. 添加报表生成
6. 测试验证

---

## 📝 第三阶段：Banner Service 重构为内容管理服务 (3-4天)

### 3.1 业务重新定位
- **目标**: 内容管理服务，支持评论和Markdown组件
- **功能**: 横幅管理、内容发布、评论系统、Markdown渲染
- **与前端关系**: 中等耦合，前端需要内容进行展示

### 3.2 新的数据结构设计

#### 内容模型
```go
type Content struct {
    ID          uint      `json:"id" gorm:"primaryKey"`
    Title       string    `json:"title" gorm:"size:200;not null"`
    Slug        string    `json:"slug" gorm:"size:200;uniqueIndex;not null"`
    Content     string    `json:"content" gorm:"type:text;not null"`
    ContentType string    `json:"content_type" gorm:"size:50;not null"` // banner, article, page
    Status      string    `json:"status" gorm:"size:20;default:'draft'"` // draft, published, archived
    Category    string    `json:"category" gorm:"size:100"`
    Tags        []string  `json:"tags" gorm:"type:json"`
    ImageURL    string    `json:"image_url" gorm:"size:500"`
    LinkURL     string    `json:"link_url" gorm:"size:500"`
    Position    string    `json:"position" gorm:"size:50"` // top, middle, bottom
    Priority    int       `json:"priority" gorm:"default:0"`
    ViewCount   int       `json:"view_count" gorm:"default:0"`
    LikeCount   int       `json:"like_count" gorm:"default:0"`
    CommentCount int      `json:"comment_count" gorm:"default:0"`
    IsActive    bool      `json:"is_active" gorm:"default:true"`
    PublishedAt *time.Time `json:"published_at"`
    CreatedBy   uint      `json:"created_by" gorm:"not null"`
    CreatedAt   time.Time `json:"created_at"`
    UpdatedAt   time.Time `json:"updated_at"`
}

// 评论模型
type Comment struct {
    ID        uint      `json:"id" gorm:"primaryKey"`
    ContentID uint      `json:"content_id" gorm:"not null"`
    Content   Content   `json:"content" gorm:"foreignKey:ContentID"`
    ParentID  *uint     `json:"parent_id"` // 支持回复
    Parent    *Comment  `json:"parent" gorm:"foreignKey:ParentID"`
    UserID    uint      `json:"user_id" gorm:"not null"`
    Content   string    `json:"content" gorm:"type:text;not null"`
    Status    string    `json:"status" gorm:"size:20;default:'approved'"` // pending, approved, rejected
    LikeCount int       `json:"like_count" gorm:"default:0"`
    IsActive  bool      `json:"is_active" gorm:"default:true"`
    CreatedAt time.Time `json:"created_at"`
    UpdatedAt time.Time `json:"updated_at"`
}

// Markdown组件模型
type MarkdownComponent struct {
    ID          uint      `json:"id" gorm:"primaryKey"`
    Name        string    `json:"name" gorm:"size:100;not null;uniqueIndex"`
    DisplayName string    `json:"display_name" gorm:"size:200;not null"`
    Description string    `json:"description" gorm:"type:text"`
    Content     string    `json:"content" gorm:"type:text;not null"`
    Variables   []string  `json:"variables" gorm:"type:json"`
    Category    string    `json:"category" gorm:"size:100"`
    Version     string    `json:"version" gorm:"size:20;default:'1.0.0'"`
    IsActive    bool      `json:"is_active" gorm:"default:true"`
    CreatedBy   uint      `json:"created_by" gorm:"not null"`
    CreatedAt   time.Time `json:"created_at"`
    UpdatedAt   time.Time `json:"updated_at"`
}
```

### 3.3 新的API设计

#### 公开API (无需认证)
```go
// 获取横幅列表
GET /api/v1/content/public/banners

// 获取内容列表
GET /api/v1/content/public/contents?type=&category=&page=&size=

// 获取单个内容
GET /api/v1/content/public/contents/:slug

// 获取评论列表
GET /api/v1/content/public/contents/:id/comments

// 获取Markdown组件
GET /api/v1/content/public/markdown-components
GET /api/v1/content/public/markdown-components/:name
```

#### 用户API (需要认证)
```go
// 发布评论
POST /api/v1/content/comments

// 点赞内容
POST /api/v1/content/contents/:id/like

// 点赞评论
POST /api/v1/content/comments/:id/like
```

#### 管理API (需要认证)
```go
// 内容管理
POST /api/v1/content/contents
PUT /api/v1/content/contents/:id
DELETE /api/v1/content/contents/:id

// 评论管理
PUT /api/v1/content/comments/:id
DELETE /api/v1/content/comments/:id

// Markdown组件管理
POST /api/v1/content/markdown-components
PUT /api/v1/content/markdown-components/:id
DELETE /api/v1/content/markdown-components/:id
```

### 3.4 功能特性
1. **Markdown渲染**: 支持Markdown格式的内容渲染
2. **评论系统**: 支持嵌套回复的评论功能
3. **内容管理**: 支持草稿、发布、归档等状态管理
4. **SEO友好**: 支持slug、meta信息等SEO优化
5. **统计分析**: 内容浏览量、点赞数等统计

### 3.5 实施步骤
1. 备份当前代码
2. 重新设计数据结构
3. 实现内容管理功能
4. 实现评论系统
5. 实现Markdown组件
6. 添加统计分析
7. 测试验证

---

## 🔧 第四阶段：集成测试和优化 (1-2天)

### 4.1 服务间集成测试
- 测试三个服务的API接口
- 验证jobfirst-core集成
- 测试认证和权限控制

### 4.2 前端集成测试
- 测试Taro前端调用新API
- 验证Markdown组件渲染
- 测试评论功能

### 4.3 性能优化
- 数据库查询优化
- API响应时间优化
- 缓存策略实施

---

## 📅 时间安排

| 阶段 | 任务 | 预计时间 | 负责人 |
|------|------|----------|--------|
| 第1阶段 | Template Service优化 | 1-2天 | 开发团队 |
| 第2阶段 | Statistics Service重构 | 2-3天 | 开发团队 |
| 第3阶段 | Banner Service重构 | 3-4天 | 开发团队 |
| 第4阶段 | 集成测试和优化 | 1-2天 | 开发团队 |
| **总计** | **完整重构** | **7-11天** | **开发团队** |

---

## 🎯 成功标准

### 功能标准
- [ ] Template Service功能完整，支持评分和使用统计
- [ ] Statistics Service提供准确的数据统计和报表
- [ ] Content Service支持内容管理、评论和Markdown
- [ ] 所有服务与jobfirst-core完全集成

### 技术标准
- [ ] API响应时间 < 200ms
- [ ] 数据库查询优化完成
- [ ] 错误处理机制完善
- [ ] 日志记录完整

### 集成标准
- [ ] 前端可以正常调用所有API
- [ ] 认证和权限控制正常
- [ ] 服务间通信正常
- [ ] 部署脚本更新完成

---

## 🚨 风险控制

### 高风险
- **数据结构变更**: 可能影响现有数据
- **API接口变更**: 可能影响前端调用

### 缓解措施
- 完整的数据备份
- 渐进式部署
- 回滚方案准备
- 充分的测试验证

---

**最后更新**: 2025-01-11
**状态**: 准备开始实施
