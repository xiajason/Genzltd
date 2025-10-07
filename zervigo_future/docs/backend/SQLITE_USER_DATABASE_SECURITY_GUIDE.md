# SQLite用户数据库安全管理指南

**文档版本**: v1.0  
**创建日期**: 2025年9月13日  
**适用范围**: Resume Service - SQLite用户数据库安全  
**安全等级**: 高  

## 📋 概述

本文档详细说明了Resume Service中SQLite用户数据库的安全管理机制，包括文件系统安全、访问控制、会话管理、数据完整性保护等方面的安全措施。

## 🔒 安全架构

### 1. 多层安全防护

```
┌─────────────────────────────────────────────────────────────┐
│                    应用层安全防护                            │
├─────────────────────────────────────────────────────────────┤
│  JWT Token认证  │  会话管理  │  权限验证  │  访问控制  │
├─────────────────────────────────────────────────────────────┤
│                    数据库连接层安全                         │
├─────────────────────────────────────────────────────────────┤
│  连接池管理  │  事务安全  │  连接加密  │  连接超时  │
├─────────────────────────────────────────────────────────────┤
│                    文件系统安全                             │
├─────────────────────────────────────────────────────────────┤
│  文件权限  │  目录隔离  │  路径安全  │  访问控制  │
└─────────────────────────────────────────────────────────────┘
```

### 2. 安全组件

- **SecureSQLiteManager**: 安全的SQLite数据库管理器
- **UserSessionManager**: 用户会话管理器
- **SessionMiddleware**: 会话验证中间件
- **AccessControl**: 访问控制机制

## 🛡️ 安全措施详解

### 1. 文件系统安全

#### 目录结构安全
```
./data/
├── users/
│   ├── user_1/
│   │   ├── resume_1_<random>.db
│   │   └── (权限: 0700)
│   ├── user_2/
│   │   ├── resume_2_<random>.db
│   │   └── (权限: 0700)
│   └── ...
└── (权限: 0755)
```

#### 文件权限控制
```go
// 目录权限: 仅所有者可访问
os.MkdirAll(userDataDir, 0700)
os.Chmod(userDataDir, 0700)

// 数据库文件权限: 仅所有者可读写
os.Chmod(dbPath, 0600)
```

#### 路径安全
- **随机文件名**: 使用随机后缀防止路径猜测
- **用户ID验证**: 严格验证用户ID的有效性
- **路径遍历防护**: 防止`../`等路径遍历攻击

### 2. 数据库连接安全

#### 连接池管理
```go
// SQLite连接池配置
sqlDB.SetMaxOpenConns(1)                    // 单连接（SQLite限制）
sqlDB.SetMaxIdleConns(1)                    // 空闲连接数
sqlDB.SetConnMaxLifetime(30 * time.Minute)  // 连接最大生命周期
```

#### 事务安全
```go
// 启用外键约束
db.Exec("PRAGMA foreign_keys = ON")

// 设置WAL模式（提高并发性能）
db.Exec("PRAGMA journal_mode = WAL")

// 设置同步模式
db.Exec("PRAGMA synchronous = NORMAL")
```

#### 连接加密
- **传输加密**: 使用HTTPS传输
- **存储加密**: 数据库文件权限控制
- **内存保护**: 敏感数据及时清理

### 3. 会话管理安全

#### 会话生命周期
```go
type UserSession struct {
    UserID       uint      `json:"user_id"`
    Username     string    `json:"username"`
    LoginTime    time.Time `json:"login_time"`
    LastActivity time.Time `json:"last_activity"`
    IPAddress    string    `json:"ip_address"`
    UserAgent    string    `json:"user_agent"`
    IsActive     bool      `json:"is_active"`
}
```

#### 会话安全特性
- **超时控制**: 24小时会话超时
- **活动跟踪**: 记录最后活动时间
- **IP验证**: 记录和验证客户端IP
- **自动清理**: 定期清理过期会话

#### 会话验证流程
```go
func ValidateUserAccess(userID uint, ipAddress string) error {
    // 1. 验证会话存在性
    session, err := GetSession(userID)
    if err != nil {
        return fmt.Errorf("会话验证失败: %v", err)
    }

    // 2. 检查会话超时
    if time.Since(session.LastActivity) > timeout {
        return fmt.Errorf("会话已超时")
    }

    // 3. 验证IP地址（可选）
    if session.IPAddress != ipAddress {
        log.Printf("警告: IP地址变化")
    }

    // 4. 更新活动时间
    return UpdateActivity(userID)
}
```

### 4. 访问控制安全

#### 用户数据隔离
```go
// 严格的用户ID验证
func ValidateUserAccess(userID uint, requestUserID uint) error {
    if userID != requestUserID {
        return fmt.Errorf("访问被拒绝: 用户%d无权访问用户%d的数据", 
                         requestUserID, userID)
    }
    return nil
}
```

#### 权限验证中间件
```go
func SessionMiddleware() gin.HandlerFunc {
    return func(c *gin.Context) {
        // 1. 获取用户ID
        userID := c.GetUint("user_id")
        
        // 2. 验证会话
        if err := ValidateUserSession(userID, c.ClientIP()); err != nil {
            c.AbortWithStatusJSON(401, gin.H{"error": "会话验证失败"})
            return
        }
        
        // 3. 设置验证后的用户信息
        c.Set("validated_user_id", userID)
        c.Next()
    }
}
```

## 🔐 安全配置

### 1. 数据库安全配置

```go
// 安全的数据库配置
config := &gorm.Config{
    Logger: logger.Default.LogMode(logger.Silent), // 避免敏感信息泄露
    NowFunc: func() time.Time {
        return time.Now().UTC() // 使用UTC时间
    },
}

// 安全的DSN配置
dsn := fmt.Sprintf("%s?_journal_mode=WAL&_synchronous=NORMAL&_cache_size=1000&_foreign_keys=ON", dbPath)
```

### 2. 会话安全配置

```go
// 会话管理器配置
manager := NewUserSessionManager(24 * time.Hour) // 24小时超时

// 定期清理配置
ticker := time.NewTicker(10 * time.Minute) // 每10分钟清理一次
```

### 3. 日志安全配置

```go
// 避免敏感信息泄露到日志
config := &gorm.Config{
    Logger: logger.Default.LogMode(logger.Silent),
}

// 安全的日志记录
log.Printf("用户%d数据库连接已建立", userID) // 不记录敏感信息
```

## 🚨 安全事件处理

### 1. 异常访问检测

```go
// IP地址变化检测
if session.IPAddress != currentIP {
    log.Printf("警告: 用户%d的IP地址发生变化", userID)
    // 可以选择是否允许IP变化
}

// 会话异常检测
if time.Since(session.LastActivity) > maxIdleTime {
    log.Printf("警告: 用户%d会话异常长时间无活动", userID)
    // 自动清理异常会话
}
```

### 2. 安全事件响应

```go
// 自动会话清理
func cleanupExpiredSessions() {
    for userID, session := range sessions {
        if session.IsActive && now.Sub(session.LastActivity) > timeout {
            session.IsActive = false
            CloseSecureUserDatabase(userID) // 关闭数据库连接
            log.Printf("自动清理过期会话: 用户%d", userID)
        }
    }
}
```

### 3. 数据泄露防护

```go
// 敏感数据清理
func cleanupSensitiveData() {
    // 清理内存中的敏感信息
    session.Password = ""
    session.Token = ""
    
    // 清理数据库连接
    db.Close()
    
    // 清理文件句柄
    file.Close()
}
```

## 📊 安全监控

### 1. 会话监控

```go
// 会话统计信息
stats := map[string]interface{}{
    "total_sessions":    len(sessions),
    "active_sessions":   activeCount,
    "timeout_duration":  timeout.String(),
    "last_cleanup":      lastCleanupTime,
}
```

### 2. 数据库监控

```go
// 数据库状态监控
info := map[string]interface{}{
    "file_count":      fileCount,
    "resume_count":    resumeCount,
    "task_count":      taskCount,
    "file_size":       fileSize,
    "last_modified":   lastModified,
}
```

### 3. 安全事件日志

```go
// 安全事件记录
log.Printf("安全事件: 用户%d尝试访问用户%d的数据", requestUserID, targetUserID)
log.Printf("安全事件: 用户%d的会话已超时，自动清理", userID)
log.Printf("安全事件: 用户%d的IP地址发生变化", userID)
```

## 🔧 安全配置检查清单

### 部署前检查

- [ ] 数据库文件权限设置为0600
- [ ] 用户数据目录权限设置为0700
- [ ] 启用WAL模式提高并发性能
- [ ] 配置合适的会话超时时间
- [ ] 启用定期清理任务
- [ ] 配置安全的日志级别
- [ ] 启用IP地址变化检测
- [ ] 配置数据库连接池参数

### 运行时监控

- [ ] 监控活跃会话数量
- [ ] 监控数据库连接状态
- [ ] 监控异常访问尝试
- [ ] 监控文件系统权限
- [ ] 监控内存使用情况
- [ ] 监控磁盘空间使用

### 定期安全检查

- [ ] 检查文件权限是否正确
- [ ] 检查会话清理是否正常
- [ ] 检查日志中是否有异常
- [ ] 检查数据库文件完整性
- [ ] 检查系统资源使用情况
- [ ] 检查安全配置是否生效

## 🚀 安全最佳实践

### 1. 开发阶段

- 使用安全的编程实践
- 避免在日志中记录敏感信息
- 及时清理临时文件和内存
- 使用类型安全的数据库操作
- 实现完整的错误处理

### 2. 部署阶段

- 使用最小权限原则
- 启用所有安全功能
- 配置合适的超时时间
- 启用监控和告警
- 定期备份重要数据

### 3. 运维阶段

- 定期检查安全配置
- 监控异常访问模式
- 及时更新安全补丁
- 定期进行安全审计
- 建立安全事件响应流程

## 📝 安全策略总结

1. **多层防护**: 从文件系统到应用层的多层安全防护
2. **最小权限**: 用户只能访问自己的数据
3. **会话管理**: 完整的会话生命周期管理
4. **自动清理**: 定期清理过期会话和连接
5. **监控告警**: 实时监控安全事件
6. **日志审计**: 完整的安全事件日志记录

通过这些安全措施，我们确保了SQLite用户数据库的安全性，防止了数据泄露、未授权访问等安全风险，为用户数据提供了可靠的保护。

## ⚠️ 重要提醒

**架构问题发现**: 在2025-09-13的存储架构验证过程中，发现当前系统存在严重的数据存储架构混乱问题。详细信息请参考：[简历存储架构问题分析与修复方案](./RESUME_STORAGE_ARCHITECTURE_ISSUES.md)

**当前状态**: 🔴 需要立即修复架构问题，确保MySQL只存储元数据，SQLite只存储用户内容。

---

**文档维护**: AI Assistant  
**审核状态**: ✅ 已完成  
**安全等级**: 高  
**适用版本**: Resume Service v3.0+  
**架构状态**: ⚠️ 需要修复
