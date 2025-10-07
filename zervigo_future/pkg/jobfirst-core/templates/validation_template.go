package templates

// ValidationTemplate 数据验证模板
// 这个文件提供了标准化的数据验证模板

/*
标准数据验证模板：

// 1. 必填字段验证中间件
func validateRequired(fields ...string) gin.HandlerFunc {
	return func(c *gin.Context) {
		var data map[string]interface{}
		if err := c.ShouldBindJSON(&data); err != nil {
			standardErrorResponse(c, http.StatusBadRequest, "无效的请求数据", err.Error())
			c.Abort()
			return
		}

		for _, field := range fields {
			if _, exists := data[field]; !exists || data[field] == "" {
				standardErrorResponse(c, http.StatusBadRequest, "缺少必填字段: "+field)
				c.Abort()
				return
			}
		}

		c.Set("validated_data", data)
		c.Next()
	}
}

// 2. 数据类型验证
func validateType(field string, expectedType string) gin.HandlerFunc {
	return func(c *gin.Context) {
		validatedData, exists := c.Get("validated_data")
		if !exists {
			standardErrorResponse(c, http.StatusBadRequest, "数据验证失败")
			c.Abort()
			return
		}

		data := validatedData.(map[string]interface{})
		value := data[field]

		switch expectedType {
		case "string":
			if _, ok := value.(string); !ok {
				standardErrorResponse(c, http.StatusBadRequest, "字段 "+field+" 必须是字符串类型")
				c.Abort()
				return
			}
		case "int":
			if _, ok := value.(float64); !ok {
				standardErrorResponse(c, http.StatusBadRequest, "字段 "+field+" 必须是整数类型")
				c.Abort()
				return
			}
		case "bool":
			if _, ok := value.(bool); !ok {
				standardErrorResponse(c, http.StatusBadRequest, "字段 "+field+" 必须是布尔类型")
				c.Abort()
				return
			}
		}

		c.Next()
	}
}

// 3. 字符串长度验证
func validateStringLength(field string, min, max int) gin.HandlerFunc {
	return func(c *gin.Context) {
		validatedData, exists := c.Get("validated_data")
		if !exists {
			standardErrorResponse(c, http.StatusBadRequest, "数据验证失败")
			c.Abort()
			return
		}

		data := validatedData.(map[string]interface{})
		value, ok := data[field].(string)
		if !ok {
			standardErrorResponse(c, http.StatusBadRequest, "字段 "+field+" 必须是字符串类型")
			c.Abort()
			return
		}

		if len(value) < min || len(value) > max {
			standardErrorResponse(c, http.StatusBadRequest,
				fmt.Sprintf("字段 %s 长度必须在 %d 到 %d 之间", field, min, max))
			c.Abort()
			return
		}

		c.Next()
	}
}

// 4. 邮箱格式验证
func validateEmail(field string) gin.HandlerFunc {
	return func(c *gin.Context) {
		validatedData, exists := c.Get("validated_data")
		if !exists {
			standardErrorResponse(c, http.StatusBadRequest, "数据验证失败")
			c.Abort()
			return
		}

		data := validatedData.(map[string]interface{})
		email, ok := data[field].(string)
		if !ok {
			standardErrorResponse(c, http.StatusBadRequest, "字段 "+field+" 必须是字符串类型")
			c.Abort()
			return
		}

		emailRegex := regexp.MustCompile(`^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`)
		if !emailRegex.MatchString(email) {
			standardErrorResponse(c, http.StatusBadRequest, "邮箱格式不正确")
			c.Abort()
			return
		}

		c.Next()
	}
}

// 5. 手机号格式验证
func validatePhone(field string) gin.HandlerFunc {
	return func(c *gin.Context) {
		validatedData, exists := c.Get("validated_data")
		if !exists {
			standardErrorResponse(c, http.StatusBadRequest, "数据验证失败")
			c.Abort()
			return
		}

		data := validatedData.(map[string]interface{})
		phone, ok := data[field].(string)
		if !ok {
			standardErrorResponse(c, http.StatusBadRequest, "字段 "+field+" 必须是字符串类型")
			c.Abort()
			return
		}

		phoneRegex := regexp.MustCompile(`^1[3-9]\d{9}$`)
		if !phoneRegex.MatchString(phone) {
			standardErrorResponse(c, http.StatusBadRequest, "手机号格式不正确")
			c.Abort()
			return
		}

		c.Next()
	}
}

// 6. 数值范围验证
func validateRange(field string, min, max float64) gin.HandlerFunc {
	return func(c *gin.Context) {
		validatedData, exists := c.Get("validated_data")
		if !exists {
			standardErrorResponse(c, http.StatusBadRequest, "数据验证失败")
			c.Abort()
			return
		}

		data := validatedData.(map[string]interface{})
		value, ok := data[field].(float64)
		if !ok {
			standardErrorResponse(c, http.StatusBadRequest, "字段 "+field+" 必须是数值类型")
			c.Abort()
			return
		}

		if value < min || value > max {
			standardErrorResponse(c, http.StatusBadRequest,
				fmt.Sprintf("字段 %s 值必须在 %.2f 到 %.2f 之间", field, min, max))
			c.Abort()
			return
		}

		c.Next()
	}
}

// 7. 枚举值验证
func validateEnum(field string, allowedValues ...string) gin.HandlerFunc {
	return func(c *gin.Context) {
		validatedData, exists := c.Get("validated_data")
		if !exists {
			standardErrorResponse(c, http.StatusBadRequest, "数据验证失败")
			c.Abort()
			return
		}

		data := validatedData.(map[string]interface{})
		value, ok := data[field].(string)
		if !ok {
			standardErrorResponse(c, http.StatusBadRequest, "字段 "+field+" 必须是字符串类型")
			c.Abort()
			return
		}

		for _, allowed := range allowedValues {
			if value == allowed {
				c.Next()
				return
			}
		}

		standardErrorResponse(c, http.StatusBadRequest,
			fmt.Sprintf("字段 %s 值必须是以下之一: %v", field, allowedValues))
		c.Abort()
	}
}

// 8. 自定义验证函数
func validateCustom(field string, validator func(interface{}) error) gin.HandlerFunc {
	return func(c *gin.Context) {
		validatedData, exists := c.Get("validated_data")
		if !exists {
			standardErrorResponse(c, http.StatusBadRequest, "数据验证失败")
			c.Abort()
			return
		}

		data := validatedData.(map[string]interface{})
		value := data[field]

		if err := validator(value); err != nil {
			standardErrorResponse(c, http.StatusBadRequest, "字段 "+field+" 验证失败: "+err.Error())
			c.Abort()
			return
		}

		c.Next()
	}
}

// 9. 验证路由设置示例
func setupValidationRoutes(r *gin.Engine, core *jobfirst.Core) {
	api := r.Group("/api/v1")
	api.Use(core.AuthMiddleware.RequireAuth())
	{
		// 用户注册验证
		api.POST("/register",
			validateRequired("username", "email", "password"),
			validateStringLength("username", 3, 20),
			validateEmail("email"),
			validateStringLength("password", 6, 50),
			registerUser)

		// 用户更新验证
		api.PUT("/profile",
			validateRequired("name", "email"),
			validateStringLength("name", 1, 50),
			validateEmail("email"),
			validatePhone("phone"), // 可选字段
			updateProfile)

		// 创建项目验证
		api.POST("/projects",
			validateRequired("name", "description", "status"),
			validateStringLength("name", 1, 100),
			validateStringLength("description", 1, 500),
			validateEnum("status", "draft", "active", "completed", "cancelled"),
			createProject)

		// 自定义验证示例
		api.POST("/custom",
			validateRequired("data"),
			validateCustom("data", func(value interface{}) error {
				// 自定义验证逻辑
				if value == nil {
					return fmt.Errorf("数据不能为空")
				}
				return nil
			}),
			handleCustom)
	}
}

// 10. 验证辅助函数
func getValidatedData(c *gin.Context) map[string]interface{} {
	if data, exists := c.Get("validated_data"); exists {
		if validatedData, ok := data.(map[string]interface{}); ok {
			return validatedData
		}
	}
	return nil
}

func getValidatedString(c *gin.Context, field string) string {
	data := getValidatedData(c)
	if data != nil {
		if value, ok := data[field].(string); ok {
			return value
		}
	}
	return ""
}

func getValidatedInt(c *gin.Context, field string) int {
	data := getValidatedData(c)
	if data != nil {
		if value, ok := data[field].(float64); ok {
			return int(value)
		}
	}
	return 0
}

func getValidatedBool(c *gin.Context, field string) bool {
	data := getValidatedData(c)
	if data != nil {
		if value, ok := data[field].(bool); ok {
			return value
		}
	}
	return false
}
*/
