# 用户数据同步机制设计文档

## 📊 当前系统分析

### 现有架构
1. **统一认证服务** (端口8207) - 基于 `jobfirst-core` 认证系统
2. **多数据库服务** (端口8090) - 已有同步服务框架
3. **用户服务** (端口8081) - 用户管理功能
4. **基础服务** (端口8080) - 用户注册和登录

### 现有同步机制
- **多数据库同步服务** - 已有 `SyncService` 框架，支持MySQL、PostgreSQL、Neo4j、Redis
- **一致性检查器** - 已有 `ConsistencyChecker` 框架
- **同步任务队列** - 支持异步同步任务处理

### 问题分析
1. **用户创建不同步** - 在basic-server创建的用户不会自动同步到统一认证服务
2. **用户更新不同步** - 用户信息变更不会实时同步
3. **数据一致性** - 不同服务间的用户数据可能不一致
4. **同步机制未激活** - 现有的同步服务框架未完全实现

## 🎯 设计目标

### 核心目标
1. **实时同步** - 用户创建和更新时自动同步到所有相关服务
2. **数据一致性** - 确保所有服务间的用户数据保持一致
3. **可靠性** - 同步失败时支持重试和错误处理
4. **可扩展性** - 支持新增服务和数据库的同步

### 技术目标
1. **异步处理** - 不阻塞用户操作的主流程
2. **事务安全** - 确保数据同步的原子性
3. **监控告警** - 同步状态监控和异常告警
4. **性能优化** - 批量同步和缓存机制

## 🏗️ 架构设计

### 1. 同步架构图
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Basic Server  │    │  User Service   │    │ Unified Auth    │
│   (Port 8080)   │    │  (Port 8081)    │    │ (Port 8207)     │
└─────────┬───────┘    └─────────┬───────┘    └─────────┬───────┘
          │                      │                      │
          │ 用户创建/更新事件      │ 用户管理事件          │ 认证事件
          ▼                      ▼                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                用户数据同步服务 (User Data Sync Service)          │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │ 事件监听器   │  │ 同步任务队列 │  │ 同步执行器   │              │
│  └─────────────┘  └─────────────┘  └─────────────┘              │
└─────────────────────────────────────────────────────────────────┘
          │                      │                      │
          ▼                      ▼                      ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│     MySQL       │    │   PostgreSQL    │    │     Redis       │
│   (主数据库)     │    │  (向量数据库)    │    │    (缓存)       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### 2. 同步流程设计

#### 用户创建同步流程
```
1. 用户在Basic Server注册
   ↓
2. 创建用户到MySQL主数据库
   ↓
3. 发送用户创建事件到同步服务
   ↓
4. 同步服务创建同步任务
   ↓
5. 异步同步到统一认证服务
   ↓
6. 同步到其他相关服务
   ↓
7. 记录同步结果和状态
```

#### 用户更新同步流程
```
1. 用户信息在任意服务更新
   ↓
2. 更新本地数据库
   ↓
3. 发送用户更新事件到同步服务
   ↓
4. 同步服务创建更新任务
   ↓
5. 异步同步到所有相关服务
   ↓
6. 验证同步结果
   ↓
7. 更新同步状态
```

## 🔧 技术实现方案

### 1. 事件驱动架构

#### 用户事件定义
```go
type UserEvent struct {
    ID        string      `json:"id"`
    Type      EventType   `json:"type"`
    UserID    uint        `json:"user_id"`
    Username  string      `json:"username"`
    Email     string      `json:"email"`
    Data      interface{} `json:"data"`
    Timestamp time.Time   `json:"timestamp"`
    Source    string      `json:"source"`
}

type EventType string

const (
    EventTypeUserCreated EventType = "user.created"
    EventTypeUserUpdated EventType = "user.updated"
    EventTypeUserDeleted EventType = "user.deleted"
    EventTypeUserStatusChanged EventType = "user.status_changed"
)
```

#### 事件发布器
```go
type UserEventPublisher struct {
    redisClient *redis.Client
    topic       string
}

func (p *UserEventPublisher) PublishUserCreated(user *User) error {
    event := UserEvent{
        ID:        generateEventID(),
        Type:      EventTypeUserCreated,
        UserID:    user.ID,
        Username:  user.Username,
        Email:     user.Email,
        Data:      user,
        Timestamp: time.Now(),
        Source:    "basic-server",
    }
    
    return p.publishEvent(event)
}
```

### 2. 同步任务管理

#### 用户同步任务
```go
type UserSyncTask struct {
    ID          string                 `json:"id"`
    UserID      uint                   `json:"user_id"`
    Username    string                 `json:"username"`
    EventType   EventType              `json:"event_type"`
    Targets     []SyncTarget           `json:"targets"`
    Data        map[string]interface{} `json:"data"`
    Priority    int                    `json:"priority"`
    Status      SyncTaskStatus         `json:"status"`
    RetryCount  int                    `json:"retry_count"`
    MaxRetries  int                    `json:"max_retries"`
    CreatedAt   time.Time              `json:"created_at"`
    UpdatedAt   time.Time              `json:"updated_at"`
    Error       string                 `json:"error,omitempty"`
}

type SyncTarget struct {
    Service string `json:"service"`
    URL     string `json:"url"`
    Method  string `json:"method"`
    Enabled bool   `json:"enabled"`
}
```

#### 同步目标配置
```go
var UserSyncTargets = []SyncTarget{
    {
        Service: "unified-auth",
        URL:     "http://localhost:8207/api/v1/auth/sync/user",
        Method:  "POST",
        Enabled: true,
    },
    {
        Service: "user-service",
        URL:     "http://localhost:8081/api/v1/users/sync",
        Method:  "POST",
        Enabled: true,
    },
    {
        Service: "redis-cache",
        URL:     "redis://localhost:6379",
        Method:  "SET",
        Enabled: true,
    },
}
```

### 3. 同步执行器

#### HTTP同步执行器
```go
type HTTPSyncExecutor struct {
    client *http.Client
    timeout time.Duration
}

func (e *HTTPSyncExecutor) ExecuteSync(task UserSyncTask, target SyncTarget) error {
    ctx, cancel := context.WithTimeout(context.Background(), e.timeout)
    defer cancel()
    
    req, err := http.NewRequestWithContext(ctx, target.Method, target.URL, nil)
    if err != nil {
        return fmt.Errorf("创建请求失败: %w", err)
    }
    
    // 设置请求头和请求体
    req.Header.Set("Content-Type", "application/json")
    req.Header.Set("X-Sync-Source", "user-sync-service")
    req.Header.Set("X-Sync-Task-ID", task.ID)
    
    resp, err := e.client.Do(req)
    if err != nil {
        return fmt.Errorf("请求执行失败: %w", err)
    }
    defer resp.Body.Close()
    
    if resp.StatusCode >= 400 {
        return fmt.Errorf("同步失败，状态码: %d", resp.StatusCode)
    }
    
    return nil
}
```

#### Redis同步执行器
```go
type RedisSyncExecutor struct {
    client *redis.Client
}

func (e *RedisSyncExecutor) ExecuteSync(task UserSyncTask, target SyncTarget) error {
    ctx := context.Background()
    
    key := fmt.Sprintf("user:%d", task.UserID)
    data, err := json.Marshal(task.Data)
    if err != nil {
        return fmt.Errorf("序列化数据失败: %w", err)
    }
    
    return e.client.Set(ctx, key, data, 24*time.Hour).Err()
}
```

### 4. 一致性检查机制

#### 用户数据一致性检查器
```go
type UserConsistencyChecker struct {
    syncService *UserSyncService
    interval    time.Duration
    enabled     bool
}

func (c *UserConsistencyChecker) CheckUserConsistency() error {
    // 1. 从主数据库获取所有用户
    users, err := c.getUsersFromMainDB()
    if err != nil {
        return fmt.Errorf("获取主数据库用户失败: %w", err)
    }
    
    // 2. 检查统一认证服务中的用户
    for _, user := range users {
        if err := c.checkUserInUnifiedAuth(user); err != nil {
            log.Printf("用户 %s 在统一认证服务中不一致: %v", user.Username, err)
            // 创建修复任务
            c.createRepairTask(user)
        }
    }
    
    return nil
}

func (c *UserConsistencyChecker) createRepairTask(user *User) {
    task := UserSyncTask{
        ID:        generateTaskID(),
        UserID:    user.ID,
        Username:  user.Username,
        EventType: EventTypeUserCreated, // 重新同步
        Targets:   UserSyncTargets,
        Data:      user,
        Priority:  1, // 高优先级
        Status:    SyncTaskStatusPending,
        CreatedAt: time.Now(),
    }
    
    c.syncService.AddTask(task)
}
```

## 📋 实施计划

### 阶段一：基础同步服务实现（1-2天）

#### 1.1 创建用户数据同步服务
- [ ] 创建 `UserSyncService` 结构体
- [ ] 实现事件监听器
- [ ] 实现同步任务队列
- [ ] 实现同步执行器

#### 1.2 集成到现有服务
- [ ] 在Basic Server中集成事件发布
- [ ] 在User Service中集成事件发布
- [ ] 在统一认证服务中添加同步接收端点

#### 1.3 基础测试
- [ ] 测试用户创建同步
- [ ] 测试用户更新同步
- [ ] 验证同步结果

### 阶段二：高级功能实现（2-3天）

#### 2.1 一致性检查
- [ ] 实现用户数据一致性检查器
- [ ] 实现自动修复机制
- [ ] 添加检查调度器

#### 2.2 监控和告警
- [ ] 实现同步状态监控
- [ ] 添加同步失败告警
- [ ] 实现同步性能指标

#### 2.3 错误处理和重试
- [ ] 实现智能重试机制
- [ ] 添加错误分类和处理
- [ ] 实现死信队列

### 阶段三：优化和扩展（1-2天）

#### 3.1 性能优化
- [ ] 实现批量同步
- [ ] 添加同步缓存
- [ ] 优化同步频率

#### 3.2 扩展性
- [ ] 支持动态添加同步目标
- [ ] 实现同步规则配置
- [ ] 添加同步过滤器

## 🧪 测试策略

### 单元测试
- [ ] 事件发布器测试
- [ ] 同步执行器测试
- [ ] 一致性检查器测试

### 集成测试
- [ ] 端到端同步测试
- [ ] 多服务协调测试
- [ ] 故障恢复测试

### 性能测试
- [ ] 并发同步测试
- [ ] 大量用户同步测试
- [ ] 同步延迟测试

## 📊 监控指标

### 同步指标
- 同步任务总数
- 同步成功率
- 同步平均延迟
- 同步失败率

### 一致性指标
- 数据一致性检查通过率
- 自动修复任务数
- 数据不一致发现数

### 性能指标
- 同步队列长度
- 同步处理时间
- 内存使用情况
- CPU使用情况

## 🔒 安全考虑

### 数据安全
- 同步数据加密传输
- 敏感信息脱敏
- 访问权限控制

### 服务安全
- 同步服务认证
- 请求签名验证
- 频率限制

## 📝 总结

这个用户数据同步机制设计基于现有的多数据库同步服务框架，通过事件驱动架构实现用户数据的实时同步。主要特点包括：

1. **事件驱动** - 基于用户操作事件触发同步
2. **异步处理** - 不阻塞用户操作主流程
3. **可靠性** - 支持重试和错误处理
4. **一致性** - 定期检查和自动修复
5. **可扩展** - 支持动态添加同步目标
6. **可监控** - 完整的监控和告警机制

通过这个机制，可以确保所有服务间的用户数据保持一致，为用户提供统一的认证体验。
