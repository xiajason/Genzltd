# 微服务认证统一计划

## 🎯 目标

统一微服务之间的认证机制，保持basic-server独立，专注于微服务集群的认证一致性。

## 📋 当前架构分析

### 现有服务分类
```
┌─────────────────────────────────────────────────────────────┐
│                    JobFirst 系统架构                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────┐    ┌─────────────────────────────────┐ │
│  │   basic-server  │    │        微服务集群                │ │
│  │   (单体应用)     │    │                                 │ │
│  │                 │    │  ┌─────────┐  ┌─────────┐      │ │
│  │  - 独立认证      │    │  │user-svc │  │job-svc  │      │ │
│  │  - 独立路由      │    │  └─────────┘  └─────────┘      │ │
│  │  - 独立业务逻辑  │    │  ┌─────────┐  ┌─────────┐      │ │
│  └─────────────────┘    │  │resume-  │  │company- │      │ │
│                         │  │svc      │  │svc      │      │ │
│                         │  └─────────┘  └─────────┘      │ │
│                         │  ┌─────────┐  ┌─────────┐      │ │
│                         │  │template │  │banner-  │      │ │
│                         │  │svc      │  │svc      │      │ │
│                         │  └─────────┘  └─────────┘      │ │
│                         │  ┌─────────┐  ┌─────────┐      │ │
│                         │  │stats-   │  │dev-team │      │ │
│                         │  │svc      │  │svc      │      │ │
│                         │  └─────────┘  └─────────┘      │ │
│                         │  ┌─────────┐  ┌─────────┐      │ │
│                         │  │notify-  │  │multi-db │      │ │
│                         │  │svc      │  │svc      │      │ │
│                         │  └─────────┘  └─────────┘      │ │
│                         │                                 │ │
│                         │  ┌─────────────────────────────┐ │ │
│                         │  │    统一认证服务              │ │ │
│                         │  │  (unified-auth-service)     │ │ │
│                         │  │                             │ │ │
│                         │  │  - JWT 验证                 │ │ │
│                         │  │  - 角色管理                 │ │ │
│                         │  │  - 权限控制                 │ │ │
│                         │  │  - 用户管理                 │ │ │
│                         │  └─────────────────────────────┘ │ │
│                         └─────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## 🔄 统一策略

### 原则
1. **保持basic-server独立** - 不修改basic-server的任何代码
2. **统一微服务认证** - 所有微服务使用相同的认证机制
3. **渐进式实施** - 分阶段实施，确保系统稳定性
4. **向后兼容** - 保持现有API的兼容性

### 实施计划

#### 第一阶段：认证中间件统一
**目标**：统一所有微服务的认证中间件

**具体任务**：
1. **创建统一认证中间件**
   ```go
   // 位置：basic/backend/pkg/middleware/unified_auth.go
   package middleware
   
   type UnifiedAuthMiddleware struct {
       authServiceURL string
       jwtSecret      string
   }
   
   func (m *UnifiedAuthMiddleware) ValidateToken(token string) (*UserInfo, error)
   func (m *UnifiedAuthMiddleware) CheckPermission(userID uint, resource string, action string) (bool, error)
   ```

2. **统一JWT格式**
   ```go
   type UnifiedJWTClaims struct {
       UserID   uint     `json:"user_id"`
       Username string   `json:"username"`
       Role     string   `json:"role"`
       Permissions []string `json:"permissions"`
       Exp      int64    `json:"exp"`
       Iat      int64    `json:"iat"`
       jwt.RegisteredClaims
   }
   ```

3. **更新所有微服务**
   - user-service
   - job-service
   - resume-service
   - company-service
   - template-service
   - banner-service
   - statistics-service
   - dev-team-service
   - notification-service
   - multi-database-service

#### 第二阶段：数据模型统一
**目标**：统一用户、角色、权限的数据模型

**具体任务**：
1. **统一用户模型**
   ```go
   type UnifiedUser struct {
       ID           uint      `json:"id"`
       Username     string    `json:"username"`
       Email        string    `json:"email"`
       Role         string    `json:"role"`
       Permissions  []string  `json:"permissions"`
       Status       string    `json:"status"`
       CreatedAt    time.Time `json:"created_at"`
       UpdatedAt    time.Time `json:"updated_at"`
   }
   ```

2. **统一角色定义**
   ```go
   const (
       RoleGuest      = "guest"
       RoleUser       = "user"
       RoleVip        = "vip"
       RoleModerator  = "moderator"
       RoleAdmin      = "admin"
       RoleSuperAdmin = "super_admin"
   )
   ```

3. **统一权限定义**
   ```go
   const (
       PermissionRead   = "read"
       PermissionWrite  = "write"
       PermissionDelete = "delete"
       PermissionAdmin  = "admin"
   )
   ```

#### 第三阶段：API接口统一
**目标**：统一认证相关的API接口

**具体任务**：
1. **统一认证API**
   - `/api/v1/auth/login`
   - `/api/v1/auth/logout`
   - `/api/v1/auth/validate`
   - `/api/v1/auth/refresh`

2. **统一用户管理API**
   - `/api/v1/users/profile`
   - `/api/v1/users/permissions`
   - `/api/v1/users/roles`

3. **统一错误响应格式**
   ```go
   type UnifiedErrorResponse struct {
       Success   bool   `json:"success"`
       Error     string `json:"error"`
       Code      string `json:"code"`
       Message   string `json:"message"`
       Timestamp string `json:"timestamp"`
   }
   ```

## 🛠️ 技术实现

### 1. 统一认证中间件
```go
// basic/backend/pkg/middleware/unified_auth.go
package middleware

import (
    "context"
    "net/http"
    "strings"
    
    "github.com/gin-gonic/gin"
    "github.com/golang-jwt/jwt/v5"
)

type UnifiedAuthMiddleware struct {
    authServiceURL string
    jwtSecret      string
}

func NewUnifiedAuthMiddleware(authServiceURL, jwtSecret string) *UnifiedAuthMiddleware {
    return &UnifiedAuthMiddleware{
        authServiceURL: authServiceURL,
        jwtSecret:      jwtSecret,
    }
}

func (m *UnifiedAuthMiddleware) AuthRequired() gin.HandlerFunc {
    return func(c *gin.Context) {
        token := m.extractToken(c)
        if token == "" {
            c.JSON(http.StatusUnauthorized, gin.H{
                "success": false,
                "error":   "Token required",
                "code":    "TOKEN_REQUIRED",
            })
            c.Abort()
            return
        }

        userInfo, err := m.validateToken(token)
        if err != nil {
            c.JSON(http.StatusUnauthorized, gin.H{
                "success": false,
                "error":   "Invalid token",
                "code":    "INVALID_TOKEN",
            })
            c.Abort()
            return
        }

        c.Set("user", userInfo)
        c.Next()
    }
}

func (m *UnifiedAuthMiddleware) extractToken(c *gin.Context) string {
    authHeader := c.GetHeader("Authorization")
    if authHeader == "" {
        return ""
    }
    
    parts := strings.Split(authHeader, " ")
    if len(parts) != 2 || parts[0] != "Bearer" {
        return ""
    }
    
    return parts[1]
}

func (m *UnifiedAuthMiddleware) validateToken(tokenString string) (*UnifiedUser, error) {
    // 实现JWT验证逻辑
    // 可以调用unified-auth-service进行验证
    // 或者直接验证JWT签名
}
```

### 2. 微服务集成示例
```go
// basic/backend/internal/user/main.go
package main

import (
    "github.com/gin-gonic/gin"
    "github.com/xiajason/zervi-basic/basic/backend/pkg/middleware"
)

func main() {
    r := gin.Default()
    
    // 初始化统一认证中间件
    authMiddleware := middleware.NewUnifiedAuthMiddleware(
        "http://localhost:8207",
        "jobfirst-unified-auth-secret-key-2024",
    )
    
    // 应用认证中间件
    api := r.Group("/api/v1")
    api.Use(authMiddleware.AuthRequired())
    
    // 业务路由
    api.GET("/users/profile", getUserProfile)
    api.PUT("/users/profile", updateUserProfile)
    
    r.Run(":8081")
}
```

## 📊 实施时间表

### 第1周：认证中间件开发
- [ ] 创建统一认证中间件
- [ ] 实现JWT验证逻辑
- [ ] 编写单元测试

### 第2周：微服务集成
- [ ] 更新user-service
- [ ] 更新job-service
- [ ] 更新resume-service
- [ ] 更新company-service

### 第3周：剩余微服务集成
- [ ] 更新template-service
- [ ] 更新banner-service
- [ ] 更新statistics-service
- [ ] 更新dev-team-service
- [ ] 更新notification-service
- [ ] 更新multi-database-service

### 第4周：测试和优化
- [ ] 集成测试
- [ ] 性能测试
- [ ] 文档更新
- [ ] 部署验证

## 🎯 成功标准

1. **功能标准**
   - 所有微服务使用统一的认证机制
   - JWT格式一致
   - 错误响应格式统一
   - 权限检查正常工作

2. **性能标准**
   - 认证响应时间 < 100ms
   - 系统整体性能不下降
   - 内存使用合理

3. **稳定性标准**
   - 所有微服务正常启动
   - 认证失败时优雅降级
   - 向后兼容性保持

## 🔍 风险评估

### 高风险
- **认证服务故障**：unified-auth-service不可用时的影响
- **JWT密钥泄露**：安全风险

### 中风险
- **性能影响**：额外的网络调用
- **兼容性问题**：现有客户端可能受影响

### 低风险
- **开发复杂度**：需要修改多个服务
- **测试复杂度**：需要测试所有微服务

## 🛡️ 风险缓解

1. **认证服务故障**
   - 实现本地JWT验证作为备选方案
   - 添加健康检查和自动重试

2. **性能影响**
   - 实现JWT缓存机制
   - 优化网络调用

3. **兼容性问题**
   - 保持API向后兼容
   - 提供迁移指南

## 📝 总结

这个计划专注于微服务认证统一，保持了basic-server的独立性，采用了渐进式实施策略，确保系统稳定性和向后兼容性。通过统一的认证中间件、数据模型和API接口，我们可以实现微服务集群的认证一致性，同时保持架构的清晰和灵活性。
