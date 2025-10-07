# JobFirst Core 统一服务模板

## 概述

JobFirst Core 统一服务模板提供了一套标准化的微服务开发框架，旨在：

- **消除重复代码**：统一所有微服务的实现方式
- **提高开发效率**：提供标准化的API和功能模板
- **确保一致性**：所有服务遵循相同的架构和规范
- **简化维护**：统一的错误处理、日志记录和配置管理

## 核心模板

### 1. StandardServiceTemplate - 标准服务模板

提供统一的服务基础结构，包括：

- 统一的服务初始化
- 标准健康检查端点
- 自动Consul注册
- 统一错误处理
- 标准响应格式

**文件位置**: `standard_service_template.go`

### 2. CRUDTemplate - CRUD操作模板

提供标准化的数据库操作，包括：

- 标准CRUD操作
- 分页和搜索支持
- 批量操作
- 统计信息
- 数据验证

**文件位置**: `crud_template.go`

### 3. PermissionTemplate - 权限控制模板

提供统一的权限管理，包括：

- 角色权限控制
- 资源所有权检查
- 权限验证中间件
- 管理员权限控制
- 权限日志记录

**文件位置**: `permission_template.go`

### 4. ValidationTemplate - 数据验证模板

提供统一的数据验证，包括：

- 必填字段验证
- 数据类型验证
- 格式验证（邮箱、手机号）
- 数值范围验证
- 枚举值验证
- 自定义验证

**文件位置**: `validation_template.go`

## 使用指南

### 1. 服务初始化

```go
// 使用标准服务模板
core, err := jobfirst.NewCore("../../configs/jobfirst-core-config.yaml")
if err != nil {
    log.Fatalf("初始化JobFirst核心包失败: %v", err)
}
defer core.Close()

// 设置Gin模式
gin.SetMode(gin.ReleaseMode)

// 创建Gin引擎
r := gin.Default()
```

### 2. 标准路由设置

```go
// 健康检查
r.GET("/health", func(c *gin.Context) {
    health := core.Health()
    c.JSON(http.StatusOK, gin.H{
        "service":     "service-name",
        "status":      "healthy",
        "timestamp":   time.Now().Format(time.RFC3339),
        "version":     "3.0.0",
        "core_health": health,
    })
})

// 版本信息
r.GET("/version", func(c *gin.Context) {
    c.JSON(http.StatusOK, gin.H{
        "service": "service-name",
        "version": "3.0.0",
        "build":   time.Now().Format("2006-01-02 15:04:05"),
    })
})
```

### 3. 标准响应格式

```go
// 成功响应
func standardSuccessResponse(c *gin.Context, data interface{}, message ...string) {
    response := gin.H{
        "success": true,
        "data":    data,
        "service": "service-name",
        "time":    time.Now().Format(time.RFC3339),
    }
    if len(message) > 0 {
        response["message"] = message[0]
    }
    c.JSON(http.StatusOK, response)
}

// 错误响应
func standardErrorResponse(c *gin.Context, statusCode int, message string, details ...string) {
    response := gin.H{
        "success": false,
        "error":   message,
        "service": "service-name",
        "time":    time.Now().Format(time.RFC3339),
    }
    if len(details) > 0 {
        response["details"] = details[0]
    }
    c.JSON(statusCode, response)
}
```

### 4. CRUD操作示例

```go
// 获取列表
func getItems(c *gin.Context) {
    // 获取查询参数
    page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
    limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))
    search := c.Query("search")

    // 获取用户ID
    userID := getUserIDFromContext(c)
    if userID == 0 {
        standardErrorResponse(c, http.StatusUnauthorized, "用户未认证")
        return
    }

    // 构建查询
    db := core.GetDB()
    query := db.Model(&Item{}).Where("user_id = ?", userID)

    // 添加搜索条件
    if search != "" {
        query = query.Where("name LIKE ?", "%"+search+"%")
    }

    // 分页
    offset := (page - 1) * limit
    var items []Item
    var total int64

    // 获取总数
    query.Count(&total)

    // 获取数据
    if err := query.Offset(offset).Limit(limit).Find(&items).Error; err != nil {
        standardErrorResponse(c, http.StatusInternalServerError, "获取列表失败", err.Error())
        return
    }

    standardSuccessResponse(c, gin.H{
        "items": items,
        "pagination": gin.H{
            "page":  page,
            "limit": limit,
            "total": total,
            "pages": (total + int64(limit) - 1) / int64(limit),
        },
    }, "获取列表成功")
}
```

### 5. 权限控制示例

```go
// 角色权限中间件
func requireRole(roles ...string) gin.HandlerFunc {
    return func(c *gin.Context) {
        userRole := c.GetString("role")
        if userRole == "" {
            standardErrorResponse(c, http.StatusUnauthorized, "用户角色未设置")
            c.Abort()
            return
        }

        for _, role := range roles {
            if userRole == role {
                c.Next()
                return
            }
        }

        standardErrorResponse(c, http.StatusForbidden, "权限不足")
        c.Abort()
    }
}

// 使用权限控制
admin := api.Group("/admin")
admin.Use(requireRole("admin", "super_admin"))
{
    admin.GET("/users", getAllUsers)
    admin.POST("/users", createUser)
}
```

### 6. 数据验证示例

```go
// 必填字段验证
api.POST("/register", 
    validateRequired("username", "email", "password"),
    validateStringLength("username", 3, 20),
    validateEmail("email"),
    validateStringLength("password", 6, 50),
    registerUser)

// 枚举值验证
api.POST("/projects",
    validateRequired("name", "description", "status"),
    validateEnum("status", "draft", "active", "completed", "cancelled"),
    createProject)
```

## 迁移指南

### 从现有服务迁移

1. **替换服务初始化**：
   ```go
   // 旧方式
   core, err := jobfirst.NewCore("config.yaml")
   r := gin.Default()
   
   // 新方式 - 使用标准模板
   // 参考 standard_service_template.go
   ```

2. **替换路由设置**：
   ```go
   // 旧方式
   r.GET("/health", healthCheck)
   api := r.Group("/api/v1")
   api.Use(authMiddleware)
   
   // 新方式 - 使用标准模板
   // 参考 standard_service_template.go
   ```

3. **替换响应格式**：
   ```go
   // 旧方式
   c.JSON(200, gin.H{"data": result})
   
   // 新方式
   standardSuccessResponse(c, result, "操作成功")
   ```

4. **替换CRUD操作**：
   ```go
   // 旧方式 - 每个服务重复实现
   // 新方式 - 使用CRUD模板
   // 参考 crud_template.go
   ```

5. **替换权限控制**：
   ```go
   // 旧方式 - 每个服务重复实现
   // 新方式 - 使用权限模板
   // 参考 permission_template.go
   ```

6. **替换数据验证**：
   ```go
   // 旧方式 - 每个服务重复实现
   // 新方式 - 使用验证模板
   // 参考 validation_template.go
   ```

## 最佳实践

1. **统一命名**：所有服务使用统一的命名规范
2. **版本管理**：每个服务都有明确的版本号
3. **错误处理**：使用标准错误响应格式
4. **日志记录**：使用统一的日志格式
5. **测试覆盖**：为所有API编写测试用例
6. **文档更新**：及时更新API文档

## 扩展功能

模板支持以下扩展：

- **自定义中间件**：添加服务特定的中间件
- **自定义验证**：实现特定的数据验证逻辑
- **自定义权限**：实现复杂的权限控制逻辑
- **自定义响应**：扩展标准响应格式

## 贡献指南

1. 遵循Go代码规范
2. 添加完整的文档注释
3. 编写单元测试
4. 更新README文档
5. 提交Pull Request

## 许可证

MIT License