package templates

// PermissionTemplate 权限控制模板
// 这个文件提供了标准化的权限控制模板

/*
标准权限控制模板：

// 1. 角色权限中间件
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

// 2. 权限检查中间件
func requirePermission(permissions ...string) gin.HandlerFunc {
	return func(c *gin.Context) {
		userPermissions := c.GetStringSlice("permissions")
		if len(userPermissions) == 0 {
			standardErrorResponse(c, http.StatusUnauthorized, "用户权限未设置")
			c.Abort()
			return
		}

		for _, permission := range permissions {
			for _, userPerm := range userPermissions {
				if userPerm == permission {
					c.Next()
					return
				}
			}
		}

		standardErrorResponse(c, http.StatusForbidden, "权限不足")
		c.Abort()
	}
}

// 3. 资源所有权检查中间件
func requireOwnership(resourceType string) gin.HandlerFunc {
	return func(c *gin.Context) {
		userID := getUserIDFromContext(c)
		if userID == 0 {
			standardErrorResponse(c, http.StatusUnauthorized, "用户未认证")
			c.Abort()
			return
		}

		resourceID := c.Param("id")
		if resourceID == "" {
			standardErrorResponse(c, http.StatusBadRequest, "资源ID不能为空")
			c.Abort()
			return
		}

		// 检查资源所有权
		if !checkResourceOwnership(resourceType, resourceID, userID) {
			standardErrorResponse(c, http.StatusForbidden, "无权访问此资源")
			c.Abort()
			return
		}

		c.Next()
	}
}

// 4. 资源所有权检查函数
func checkResourceOwnership(resourceType, resourceID string, userID uint) bool {
	db := core.GetDB()

	switch resourceType {
	case "item":
		var item Item
		if err := db.Where("id = ? AND user_id = ?", resourceID, userID).First(&item).Error; err != nil {
			return false
		}
		return true
	case "company":
		var company Company
		if err := db.Where("id = ? AND owner_id = ?", resourceID, userID).First(&company).Error; err != nil {
			return false
		}
		return true
	default:
		return false
	}
}

// 5. 管理员权限检查
func requireAdmin() gin.HandlerFunc {
	return requireRole("admin", "super_admin")
}

// 6. 超级管理员权限检查
func requireSuperAdmin() gin.HandlerFunc {
	return requireRole("super_admin")
}

// 7. 权限路由设置示例
func setupPermissionRoutes(r *gin.Engine, core *jobfirst.Core) {
	// 公开路由
	public := r.Group("/api/v1/public")
	{
		public.GET("/info", getPublicInfo)
	}

	// 需要认证的路由
	api := r.Group("/api/v1")
	api.Use(core.AuthMiddleware.RequireAuth())
	{
		// 用户自己的资源
		api.GET("/items", getItems)
		api.POST("/items", createItem)
		api.GET("/items/:id", requireOwnership("item"), getItem)
		api.PUT("/items/:id", requireOwnership("item"), updateItem)
		api.DELETE("/items/:id", requireOwnership("item"), deleteItem)

		// 管理员功能
		admin := api.Group("/admin")
		admin.Use(requireAdmin())
		{
			admin.GET("/users", getAllUsers)
			admin.POST("/users", createUser)
			admin.PUT("/users/:id", updateUser)
			admin.DELETE("/users/:id", deleteUser)
		}

		// 超级管理员功能
		superAdmin := api.Group("/super-admin")
		superAdmin.Use(requireSuperAdmin())
		{
			superAdmin.GET("/system/stats", getSystemStats)
			superAdmin.POST("/system/config", updateSystemConfig)
		}

		// 基于权限的功能
		permissionAPI := api.Group("/permission")
		permissionAPI.Use(requirePermission("user:read"))
		{
			permissionAPI.GET("/users", getUsersWithPermission)
		}
	}
}

// 8. 权限检查辅助函数
func getUserRoleFromContext(c *gin.Context) string {
	if role, exists := c.Get("role"); exists {
		if r, ok := role.(string); ok {
			return r
		}
	}
	return ""
}

func getUserPermissionsFromContext(c *gin.Context) []string {
	if permissions, exists := c.Get("permissions"); exists {
		if perms, ok := permissions.([]string); ok {
			return perms
		}
	}
	return []string{}
}

// 9. 权限验证函数
func hasRole(c *gin.Context, role string) bool {
	userRole := getUserRoleFromContext(c)
	return userRole == role
}

func hasPermission(c *gin.Context, permission string) bool {
	userPermissions := getUserPermissionsFromContext(c)
	for _, perm := range userPermissions {
		if perm == permission {
			return true
		}
	}
	return false
}

func isOwner(c *gin.Context, resourceType, resourceID string) bool {
	userID := getUserIDFromContext(c)
	return checkResourceOwnership(resourceType, resourceID, userID)
}

// 10. 权限装饰器
func withPermission(permission string, handler gin.HandlerFunc) gin.HandlerFunc {
	return func(c *gin.Context) {
		if !hasPermission(c, permission) {
			standardErrorResponse(c, http.StatusForbidden, "权限不足")
			c.Abort()
			return
		}
		handler(c)
	}
}

func withRole(role string, handler gin.HandlerFunc) gin.HandlerFunc {
	return func(c *gin.Context) {
		if !hasRole(c, role) {
			standardErrorResponse(c, http.StatusForbidden, "权限不足")
			c.Abort()
			return
		}
		handler(c)
	}
}

// 11. 权限日志记录
func logPermissionCheck(c *gin.Context, action, resource string, allowed bool) {
	userID := getUserIDFromContext(c)
	userRole := getUserRoleFromContext(c)

	log.Printf("权限检查 - 用户ID: %d, 角色: %s, 操作: %s, 资源: %s, 结果: %t",
		userID, userRole, action, resource, allowed)
}
*/
