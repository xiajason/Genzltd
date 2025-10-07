package templates

// StandardServiceTemplate 标准服务模板
// 这个文件提供了标准化的服务实现模板，用于重构现有服务

/*
标准服务结构模板：

package main

import (
	"fmt"
	"log"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/hashicorp/consul/api"
	"github.com/jobfirst/jobfirst-core"
)

func main() {
	// 1. 初始化JobFirst核心包
	core, err := jobfirst.NewCore("../../configs/jobfirst-core-config.yaml")
	if err != nil {
		log.Fatalf("初始化JobFirst核心包失败: %v", err)
	}
	defer core.Close()

	// 2. 设置Gin模式
	gin.SetMode(gin.ReleaseMode)

	// 3. 创建Gin引擎
	r := gin.Default()

	// 4. 设置标准路由
	setupStandardRoutes(r, core)

	// 5. 设置业务路由
	setupBusinessRoutes(r, core)

	// 6. 注册到Consul
	registerToConsul("service-name", "127.0.0.1", 8080)

	// 7. 启动服务器
	log.Println("Starting Service with jobfirst-core on 0.0.0.0:8080")
	if err := r.Run(":8080"); err != nil {
		log.Fatalf("启动服务器失败: %v", err)
	}
}

// setupStandardRoutes 设置标准路由
func setupStandardRoutes(r *gin.Engine, core *jobfirst.Core) {
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

	// 服务信息
	r.GET("/info", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"service":    "service-name",
			"version":    "3.0.0",
			"port":       8080,
			"status":     "running",
			"started_at": time.Now().Format(time.RFC3339),
		})
	})
}

// setupBusinessRoutes 设置业务路由
func setupBusinessRoutes(r *gin.Engine, core *jobfirst.Core) {
	// 公开API路由（不需要认证）
	public := r.Group("/api/v1/public")
	{
		// 公开的业务API
		public.GET("/status", func(c *gin.Context) {
			standardSuccessResponse(c, gin.H{"status": "ok"}, "服务正常")
		})
	}

	// 需要认证的API路由
	api := r.Group("/api/v1")
	api.Use(core.AuthMiddleware.RequireAuth())
	{
		// 业务API
		api.GET("/items", getItems)
		api.POST("/items", createItem)
		api.GET("/items/:id", getItem)
		api.PUT("/items/:id", updateItem)
		api.DELETE("/items/:id", deleteItem)
	}
}

// 标准响应函数
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

// 业务处理函数
func getItems(c *gin.Context) {
	// 获取用户ID
	userID := getUserIDFromContext(c)
	if userID == 0 {
		standardErrorResponse(c, http.StatusUnauthorized, "用户未认证")
		return
	}

	// 业务逻辑
	items := []gin.H{
		{"id": 1, "name": "项目A", "user_id": userID},
		{"id": 2, "name": "项目B", "user_id": userID},
	}

	standardSuccessResponse(c, gin.H{
		"items": items,
		"total": len(items),
	}, "获取列表成功")
}

func createItem(c *gin.Context) {
	userID := getUserIDFromContext(c)
	if userID == 0 {
		standardErrorResponse(c, http.StatusUnauthorized, "用户未认证")
		return
	}

	var req struct {
		Name string `json:"name" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		standardErrorResponse(c, http.StatusBadRequest, "无效的请求数据", err.Error())
		return
	}

	// 业务逻辑
	item := gin.H{
		"id":      1,
		"name":    req.Name,
		"user_id": userID,
	}

	standardSuccessResponse(c, item, "创建成功")
}

func getItem(c *gin.Context) {
	// 实现获取单个项目的逻辑
	standardSuccessResponse(c, gin.H{"id": 1, "name": "项目A"})
}

func updateItem(c *gin.Context) {
	// 实现更新项目的逻辑
	standardSuccessResponse(c, gin.H{"id": 1, "name": "更新后的项目"})
}

func deleteItem(c *gin.Context) {
	// 实现删除项目的逻辑
	standardSuccessResponse(c, gin.H{"id": 1}, "删除成功")
}

// 辅助函数
func getUserIDFromContext(c *gin.Context) uint {
	if userID, exists := c.Get("user_id"); exists {
		if id, ok := userID.(uint); ok {
			return id
		}
	}
	return 0
}

// registerToConsul 注册服务到Consul
func registerToConsul(serviceName string, host string, port int) {
	config := api.DefaultConfig()
	config.Address = "127.0.0.1:8500"

	client, err := api.NewClient(config)
	if err != nil {
		log.Printf("创建Consul客户端失败: %v", err)
		return
	}

	registration := &api.AgentServiceRegistration{
		ID:      fmt.Sprintf("%s-%d", serviceName, port),
		Name:    serviceName,
		Port:    port,
		Address: host,
		Check: &api.AgentServiceCheck{
			HTTP:                           fmt.Sprintf("http://%s:%d/health", host, port),
			Timeout:                        "3s",
			Interval:                       "10s",
			DeregisterCriticalServiceAfter: "30s",
		},
		Tags: []string{
			"jobfirst",
			"microservice",
			"version:3.0.0",
		},
	}

	err = client.Agent().ServiceRegister(registration)
	if err != nil {
		log.Printf("注册服务到Consul失败: %v", err)
	} else {
		log.Printf("服务 %s 已注册到Consul (端口: %d)", serviceName, port)
	}
}
*/
