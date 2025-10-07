package templates

// JobServiceRefactoredExample Job服务重构示例
// 这个文件展示了如何使用统一模板重构Job服务

/*
重构后的Job服务示例：

package main

import (
	"fmt"
	"log"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/hashicorp/consul/api"
	"github.com/jobfirst/jobfirst-core"
)

// Job 职位模型 - 移除Company字段，完全依赖Company服务
type Job struct {
	ID          uint      `json:"id" gorm:"primaryKey"`
	Title       string    `json:"title" gorm:"not null"`
	Description string    `json:"description"`
	CompanyID   uint      `json:"company_id" gorm:"not null"` // 只存储Company ID
	Location    string    `json:"location"`
	Salary      string    `json:"salary"`
	Status      string    `json:"status" gorm:"default:'active'"`
	CreatedBy   uint      `json:"created_by" gorm:"not null"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

// JobWithCompany 包含公司信息的职位结构
type JobWithCompany struct {
	Job
	Company CompanyInfo `json:"company"`
}

// CompanyInfo 公司信息结构
type CompanyInfo struct {
	ID          uint   `json:"id"`
	Name        string `json:"name"`
	Industry    string `json:"industry"`
	Size        string `json:"size"`
	Location    string `json:"location"`
	Description string `json:"description"`
}

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
	registerToConsul("job-service", "127.0.0.1", 8089)

	// 7. 启动服务器
	log.Println("Starting Job Service with jobfirst-core on 0.0.0.0:8089")
	if err := r.Run(":8089"); err != nil {
		log.Fatalf("启动服务器失败: %v", err)
	}
}

// setupStandardRoutes 设置标准路由
func setupStandardRoutes(r *gin.Engine, core *jobfirst.Core) {
	// 健康检查
	r.GET("/health", func(c *gin.Context) {
		health := core.Health()
		c.JSON(http.StatusOK, gin.H{
			"service":     "job-service",
			"status":      "healthy",
			"timestamp":   time.Now().Format(time.RFC3339),
			"version":     "3.0.0",
			"core_health": health,
		})
	})

	// 版本信息
	r.GET("/version", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"service": "job-service",
			"version": "3.0.0",
			"build":   time.Now().Format("2006-01-02 15:04:05"),
		})
	})

	// 服务信息
	r.GET("/info", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"service":    "job-service",
			"version":    "3.0.0",
			"port":       8089,
			"status":     "running",
			"started_at": time.Now().Format(time.RFC3339),
		})
	})
}

// setupBusinessRoutes 设置业务路由
func setupBusinessRoutes(r *gin.Engine, core *jobfirst.Core) {
	// 公开API路由（不需要认证）
	public := r.Group("/api/v1/job/public")
	{
		// 公开的职位列表
		public.GET("/jobs", getPublicJobs)
		public.GET("/jobs/:id", getPublicJob)
	}

	// 需要认证的API路由
	api := r.Group("/api/v1/job")
	api.Use(core.AuthMiddleware.RequireAuth())
	{
		// 职位管理
		api.GET("/jobs", getJobs)
		api.POST("/jobs",
			validateRequired("title", "description", "company_id", "location"),
			validateStringLength("title", 1, 100),
			validateStringLength("description", 1, 1000),
			validateEnum("status", "draft", "active", "paused", "closed"),
			createJob)
		api.GET("/jobs/:id", getJob)
		api.PUT("/jobs/:id",
			validateRequired("title", "description", "company_id", "location"),
			validateStringLength("title", 1, 100),
			validateStringLength("description", 1, 1000),
			validateEnum("status", "draft", "active", "paused", "closed"),
			updateJob)
		api.DELETE("/jobs/:id", deleteJob)

		// 公司相关职位
		api.GET("/companies/:company_id/jobs", getJobsByCompany)

		// 管理员功能
		admin := api.Group("/admin")
		admin.Use(requireRole("admin", "super_admin"))
		{
			admin.GET("/jobs", getAllJobs)
			admin.PUT("/jobs/:id/status", updateJobStatus)
		}
	}
}

// 公开API处理器
func getPublicJobs(c *gin.Context) {
	// 获取查询参数
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))
	location := c.Query("location")
	industry := c.Query("industry")

	// 构建查询
	db := core.GetDB()
	query := db.Model(&Job{}).Where("status = ?", "active")

	// 添加筛选条件
	if location != "" {
		query = query.Where("location LIKE ?", "%"+location+"%")
	}

	// 分页
	offset := (page - 1) * limit
	var jobs []Job
	var total int64

	query.Count(&total)
	if err := query.Offset(offset).Limit(limit).Find(&jobs).Error; err != nil {
		standardErrorResponse(c, http.StatusInternalServerError, "获取职位列表失败", err.Error())
		return
	}

	// 获取公司信息
	jobsWithCompany := make([]JobWithCompany, len(jobs))
	for i, job := range jobs {
		companyInfo, err := getCompanyInfo(job.CompanyID)
		if err != nil {
			log.Printf("获取公司信息失败: %v", err)
			companyInfo = CompanyInfo{ID: job.CompanyID, Name: "未知公司"}
		}

		jobsWithCompany[i] = JobWithCompany{
			Job:     job,
			Company: companyInfo,
		}
	}

	standardSuccessResponse(c, gin.H{
		"jobs": jobsWithCompany,
		"pagination": gin.H{
			"page":  page,
			"limit": limit,
			"total": total,
			"pages": (total + int64(limit) - 1) / int64(limit),
		},
	}, "获取公开职位列表成功")
}

func getPublicJob(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		standardErrorResponse(c, http.StatusBadRequest, "无效的职位ID")
		return
	}

	db := core.GetDB()
	var job Job

	if err := db.Where("id = ? AND status = ?", id, "active").First(&job).Error; err != nil {
		standardErrorResponse(c, http.StatusNotFound, "职位不存在")
		return
	}

	// 获取公司信息
	companyInfo, err := getCompanyInfo(job.CompanyID)
	if err != nil {
		log.Printf("获取公司信息失败: %v", err)
		companyInfo = CompanyInfo{ID: job.CompanyID, Name: "未知公司"}
	}

	jobWithCompany := JobWithCompany{
		Job:     job,
		Company: companyInfo,
	}

	standardSuccessResponse(c, jobWithCompany)
}

// 认证API处理器
func getJobs(c *gin.Context) {
	userID := getUserIDFromContext(c)
	if userID == 0 {
		standardErrorResponse(c, http.StatusUnauthorized, "用户未认证")
		return
	}

	// 获取查询参数
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))
	status := c.Query("status")

	// 构建查询
	db := core.GetDB()
	query := db.Model(&Job{}).Where("created_by = ?", userID)

	// 添加状态筛选
	if status != "" {
		query = query.Where("status = ?", status)
	}

	// 分页
	offset := (page - 1) * limit
	var jobs []Job
	var total int64

	query.Count(&total)
	if err := query.Offset(offset).Limit(limit).Find(&jobs).Error; err != nil {
		standardErrorResponse(c, http.StatusInternalServerError, "获取职位列表失败", err.Error())
		return
	}

	// 获取公司信息
	jobsWithCompany := make([]JobWithCompany, len(jobs))
	for i, job := range jobs {
		companyInfo, err := getCompanyInfo(job.CompanyID)
		if err != nil {
			log.Printf("获取公司信息失败: %v", err)
			companyInfo = CompanyInfo{ID: job.CompanyID, Name: "未知公司"}
		}

		jobsWithCompany[i] = JobWithCompany{
			Job:     job,
			Company: companyInfo,
		}
	}

	standardSuccessResponse(c, gin.H{
		"jobs": jobsWithCompany,
		"pagination": gin.H{
			"page":  page,
			"limit": limit,
			"total": total,
			"pages": (total + int64(limit) - 1) / int64(limit),
		},
	}, "获取职位列表成功")
}

func createJob(c *gin.Context) {
	userID := getUserIDFromContext(c)
	if userID == 0 {
		standardErrorResponse(c, http.StatusUnauthorized, "用户未认证")
		return
	}

	validatedData := getValidatedData(c)
	if validatedData == nil {
		standardErrorResponse(c, http.StatusBadRequest, "数据验证失败")
		return
	}

	// 验证公司是否存在
	companyID := uint(validatedData["company_id"].(float64))
	if !validateCompanyExists(companyID) {
		standardErrorResponse(c, http.StatusBadRequest, "公司不存在")
		return
	}

	job := Job{
		Title:       validatedData["title"].(string),
		Description: validatedData["description"].(string),
		CompanyID:   companyID,
		Location:    validatedData["location"].(string),
		Salary:      getValidatedString(c, "salary"),
		Status:      getValidatedString(c, "status"),
		CreatedBy:   userID,
	}

	if job.Status == "" {
		job.Status = "active"
	}

	db := core.GetDB()
	if err := db.Create(&job).Error; err != nil {
		standardErrorResponse(c, http.StatusInternalServerError, "创建职位失败", err.Error())
		return
	}

	// 获取公司信息
	companyInfo, _ := getCompanyInfo(job.CompanyID)
	jobWithCompany := JobWithCompany{
		Job:     job,
		Company: companyInfo,
	}

	standardSuccessResponse(c, jobWithCompany, "创建职位成功")
}

func getJob(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		standardErrorResponse(c, http.StatusBadRequest, "无效的职位ID")
		return
	}

	userID := getUserIDFromContext(c)
	if userID == 0 {
		standardErrorResponse(c, http.StatusUnauthorized, "用户未认证")
		return
	}

	db := core.GetDB()
	var job Job

	if err := db.Where("id = ? AND created_by = ?", id, userID).First(&job).Error; err != nil {
		standardErrorResponse(c, http.StatusNotFound, "职位不存在")
		return
	}

	// 获取公司信息
	companyInfo, _ := getCompanyInfo(job.CompanyID)
	jobWithCompany := JobWithCompany{
		Job:     job,
		Company: companyInfo,
	}

	standardSuccessResponse(c, jobWithCompany)
}

func updateJob(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		standardErrorResponse(c, http.StatusBadRequest, "无效的职位ID")
		return
	}

	userID := getUserIDFromContext(c)
	if userID == 0 {
		standardErrorResponse(c, http.StatusUnauthorized, "用户未认证")
		return
	}

	validatedData := getValidatedData(c)
	if validatedData == nil {
		standardErrorResponse(c, http.StatusBadRequest, "数据验证失败")
		return
	}

	db := core.GetDB()
	var job Job

	// 检查职位是否存在且属于当前用户
	if err := db.Where("id = ? AND created_by = ?", id, userID).First(&job).Error; err != nil {
		standardErrorResponse(c, http.StatusNotFound, "职位不存在")
		return
	}

	// 验证公司是否存在
	companyID := uint(validatedData["company_id"].(float64))
	if !validateCompanyExists(companyID) {
		standardErrorResponse(c, http.StatusBadRequest, "公司不存在")
		return
	}

	// 更新职位
	job.Title = validatedData["title"].(string)
	job.Description = validatedData["description"].(string)
	job.CompanyID = companyID
	job.Location = validatedData["location"].(string)
	job.Salary = getValidatedString(c, "salary")
	job.Status = getValidatedString(c, "status")

	if err := db.Save(&job).Error; err != nil {
		standardErrorResponse(c, http.StatusInternalServerError, "更新职位失败", err.Error())
		return
	}

	// 获取公司信息
	companyInfo, _ := getCompanyInfo(job.CompanyID)
	jobWithCompany := JobWithCompany{
		Job:     job,
		Company: companyInfo,
	}

	standardSuccessResponse(c, jobWithCompany, "更新职位成功")
}

func deleteJob(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		standardErrorResponse(c, http.StatusBadRequest, "无效的职位ID")
		return
	}

	userID := getUserIDFromContext(c)
	if userID == 0 {
		standardErrorResponse(c, http.StatusUnauthorized, "用户未认证")
		return
	}

	db := core.GetDB()

	// 检查职位是否存在且属于当前用户
	var job Job
	if err := db.Where("id = ? AND created_by = ?", id, userID).First(&job).Error; err != nil {
		standardErrorResponse(c, http.StatusNotFound, "职位不存在")
		return
	}

	// 删除职位
	if err := db.Delete(&job).Error; err != nil {
		standardErrorResponse(c, http.StatusInternalServerError, "删除职位失败", err.Error())
		return
	}

	standardSuccessResponse(c, gin.H{"id": id}, "删除职位成功")
}

func getJobsByCompany(c *gin.Context) {
	companyID, err := strconv.Atoi(c.Param("company_id"))
	if err != nil {
		standardErrorResponse(c, http.StatusBadRequest, "无效的公司ID")
		return
	}

	// 验证公司是否存在
	if !validateCompanyExists(uint(companyID)) {
		standardErrorResponse(c, http.StatusNotFound, "公司不存在")
		return
	}

	// 获取查询参数
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))
	status := c.Query("status")

	// 构建查询
	db := core.GetDB()
	query := db.Model(&Job{}).Where("company_id = ?", companyID)

	// 添加状态筛选
	if status != "" {
		query = query.Where("status = ?", status)
	}

	// 分页
	offset := (page - 1) * limit
	var jobs []Job
	var total int64

	query.Count(&total)
	if err := query.Offset(offset).Limit(limit).Find(&jobs).Error; err != nil {
		standardErrorResponse(c, http.StatusInternalServerError, "获取职位列表失败", err.Error())
		return
	}

	// 获取公司信息
	companyInfo, _ := getCompanyInfo(uint(companyID))
	jobsWithCompany := make([]JobWithCompany, len(jobs))
	for i, job := range jobs {
		jobsWithCompany[i] = JobWithCompany{
			Job:     job,
			Company: companyInfo,
		}
	}

	standardSuccessResponse(c, gin.H{
		"jobs": jobsWithCompany,
		"pagination": gin.H{
			"page":  page,
			"limit": limit,
			"total": total,
			"pages": (total + int64(limit) - 1) / int64(limit),
		},
	}, "获取公司职位列表成功")
}

// 管理员功能
func getAllJobs(c *gin.Context) {
	// 获取查询参数
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))
	status := c.Query("status")
	companyID := c.Query("company_id")

	// 构建查询
	db := core.GetDB()
	query := db.Model(&Job{})

	// 添加筛选条件
	if status != "" {
		query = query.Where("status = ?", status)
	}
	if companyID != "" {
		query = query.Where("company_id = ?", companyID)
	}

	// 分页
	offset := (page - 1) * limit
	var jobs []Job
	var total int64

	query.Count(&total)
	if err := query.Offset(offset).Limit(limit).Find(&jobs).Error; err != nil {
		standardErrorResponse(c, http.StatusInternalServerError, "获取职位列表失败", err.Error())
		return
	}

	standardSuccessResponse(c, gin.H{
		"jobs": jobs,
		"pagination": gin.H{
			"page":  page,
			"limit": limit,
			"total": total,
			"pages": (total + int64(limit) - 1) / int64(limit),
		},
	}, "获取所有职位成功")
}

func updateJobStatus(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		standardErrorResponse(c, http.StatusBadRequest, "无效的职位ID")
		return
	}

	var req struct {
		Status string `json:"status" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		standardErrorResponse(c, http.StatusBadRequest, "无效的请求数据", err.Error())
		return
	}

	// 验证状态值
	validStatuses := []string{"draft", "active", "paused", "closed"}
	if !contains(validStatuses, req.Status) {
		standardErrorResponse(c, http.StatusBadRequest, "无效的状态值")
		return
	}

	db := core.GetDB()
	var job Job

	if err := db.First(&job, id).Error; err != nil {
		standardErrorResponse(c, http.StatusNotFound, "职位不存在")
		return
	}

	job.Status = req.Status
	if err := db.Save(&job).Error; err != nil {
		standardErrorResponse(c, http.StatusInternalServerError, "更新职位状态失败", err.Error())
		return
	}

	standardSuccessResponse(c, job, "更新职位状态成功")
}

// 辅助函数
func getCompanyInfo(companyID uint) (CompanyInfo, error) {
	// 调用Company服务获取公司信息
	// 这里应该使用HTTP客户端调用Company服务的API
	// 为了示例，我们返回模拟数据
	return CompanyInfo{
		ID:          companyID,
		Name:        "示例公司",
		Industry:    "互联网",
		Size:        "100-500人",
		Location:    "北京",
		Description: "这是一家示例公司",
	}, nil
}

func validateCompanyExists(companyID uint) bool {
	// 调用Company服务验证公司是否存在
	// 这里应该使用HTTP客户端调用Company服务的API
	// 为了示例，我们返回true
	return true
}

func contains(slice []string, item string) bool {
	for _, s := range slice {
		if s == item {
			return true
		}
	}
	return false
}

// 标准响应函数
func standardSuccessResponse(c *gin.Context, data interface{}, message ...string) {
	response := gin.H{
		"success": true,
		"data":    data,
		"service": "job-service",
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
		"service": "job-service",
		"time":    time.Now().Format(time.RFC3339),
	}
	if len(details) > 0 {
		response["details"] = details[0]
	}
	c.JSON(statusCode, response)
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

// 权限控制中间件
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

// 数据验证中间件
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
