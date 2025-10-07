package templates

// CRUDTemplate CRUD操作模板
// 这个文件提供了标准化的CRUD操作模板

/*
标准CRUD操作模板：

// 1. 模型定义
type Item struct {
	ID        uint      `json:"id" gorm:"primaryKey"`
	Name      string    `json:"name" gorm:"not null"`
	UserID    uint      `json:"user_id" gorm:"not null"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

// 2. 获取列表
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

// 3. 获取单个
func getItem(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		standardErrorResponse(c, http.StatusBadRequest, "无效的ID")
		return
	}

	userID := getUserIDFromContext(c)
	if userID == 0 {
		standardErrorResponse(c, http.StatusUnauthorized, "用户未认证")
		return
	}

	db := core.GetDB()
	var item Item

	if err := db.Where("id = ? AND user_id = ?", id, userID).First(&item).Error; err != nil {
		standardErrorResponse(c, http.StatusNotFound, "记录不存在")
		return
	}

	standardSuccessResponse(c, item)
}

// 4. 创建
func createItem(c *gin.Context) {
	var req struct {
		Name string `json:"name" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		standardErrorResponse(c, http.StatusBadRequest, "无效的请求数据", err.Error())
		return
	}

	userID := getUserIDFromContext(c)
	if userID == 0 {
		standardErrorResponse(c, http.StatusUnauthorized, "用户未认证")
		return
	}

	item := Item{
		Name:   req.Name,
		UserID: userID,
	}

	db := core.GetDB()
	if err := db.Create(&item).Error; err != nil {
		standardErrorResponse(c, http.StatusInternalServerError, "创建失败", err.Error())
		return
	}

	standardSuccessResponse(c, item, "创建成功")
}

// 5. 更新
func updateItem(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		standardErrorResponse(c, http.StatusBadRequest, "无效的ID")
		return
	}

	var req struct {
		Name string `json:"name" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		standardErrorResponse(c, http.StatusBadRequest, "无效的请求数据", err.Error())
		return
	}

	userID := getUserIDFromContext(c)
	if userID == 0 {
		standardErrorResponse(c, http.StatusUnauthorized, "用户未认证")
		return
	}

	db := core.GetDB()
	var item Item

	// 检查记录是否存在且属于当前用户
	if err := db.Where("id = ? AND user_id = ?", id, userID).First(&item).Error; err != nil {
		standardErrorResponse(c, http.StatusNotFound, "记录不存在")
		return
	}

	// 更新记录
	item.Name = req.Name
	if err := db.Save(&item).Error; err != nil {
		standardErrorResponse(c, http.StatusInternalServerError, "更新失败", err.Error())
		return
	}

	standardSuccessResponse(c, item, "更新成功")
}

// 6. 删除
func deleteItem(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		standardErrorResponse(c, http.StatusBadRequest, "无效的ID")
		return
	}

	userID := getUserIDFromContext(c)
	if userID == 0 {
		standardErrorResponse(c, http.StatusUnauthorized, "用户未认证")
		return
	}

	db := core.GetDB()

	// 检查记录是否存在且属于当前用户
	var item Item
	if err := db.Where("id = ? AND user_id = ?", id, userID).First(&item).Error; err != nil {
		standardErrorResponse(c, http.StatusNotFound, "记录不存在")
		return
	}

	// 删除记录
	if err := db.Delete(&item).Error; err != nil {
		standardErrorResponse(c, http.StatusInternalServerError, "删除失败", err.Error())
		return
	}

	standardSuccessResponse(c, gin.H{"id": id}, "删除成功")
}

// 7. 批量操作
func batchDeleteItems(c *gin.Context) {
	var req struct {
		IDs []uint `json:"ids" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		standardErrorResponse(c, http.StatusBadRequest, "无效的请求数据", err.Error())
		return
	}

	userID := getUserIDFromContext(c)
	if userID == 0 {
		standardErrorResponse(c, http.StatusUnauthorized, "用户未认证")
		return
	}

	db := core.GetDB()

	// 批量删除
	if err := db.Where("id IN ? AND user_id = ?", req.IDs, userID).Delete(&Item{}).Error; err != nil {
		standardErrorResponse(c, http.StatusInternalServerError, "批量删除失败", err.Error())
		return
	}

	standardSuccessResponse(c, gin.H{"deleted_ids": req.IDs}, "批量删除成功")
}

// 8. 统计信息
func getItemStats(c *gin.Context) {
	userID := getUserIDFromContext(c)
	if userID == 0 {
		standardErrorResponse(c, http.StatusUnauthorized, "用户未认证")
		return
	}

	db := core.GetDB()

	var stats struct {
		Total    int64 `json:"total"`
		ThisWeek int64 `json:"this_week"`
		ThisMonth int64 `json:"this_month"`
	}

	// 总数
	db.Model(&Item{}).Where("user_id = ?", userID).Count(&stats.Total)

	// 本周
	weekStart := time.Now().Truncate(24 * time.Hour).AddDate(0, 0, -int(time.Now().Weekday()))
	db.Model(&Item{}).Where("user_id = ? AND created_at >= ?", userID, weekStart).Count(&stats.ThisWeek)

	// 本月
	monthStart := time.Now().Truncate(24 * time.Hour).AddDate(0, 0, -time.Now().Day()+1)
	db.Model(&Item{}).Where("user_id = ? AND created_at >= ?", userID, monthStart).Count(&stats.ThisMonth)

	standardSuccessResponse(c, stats, "获取统计信息成功")
}
*/
