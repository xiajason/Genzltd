package main

import (
	"database/sql"
	"fmt"
	"log"
	"os"

	_ "github.com/go-sql-driver/mysql"
	_ "github.com/mattn/go-sqlite3"
)

// 数据库连接配置
type DBConfig struct {
	MySQLHost     string
	MySQLPort     string
	MySQLUser     string
	MySQLPassword string
	MySQLDatabase string
}

// 简历数据迁移器
type ResumeDataMigrator struct {
	mysqlDB *sql.DB
	config  *DBConfig
}

// 简历元数据记录
type ResumeMetadata struct {
	ID            int    `json:"id"`
	UserID        int    `json:"user_id"`
	FileID        *int   `json:"file_id"`
	Title         string `json:"title"`
	Content       string `json:"content"`
	CreationMode  string `json:"creation_mode"`
	Status        string `json:"status"`
	IsPublic      bool   `json:"is_public"`
	ViewCount     int    `json:"view_count"`
	ParsingStatus string `json:"parsing_status"`
	ParsingError  string `json:"parsing_error"`
	CreatedAt     string `json:"created_at"`
	UpdatedAt     string `json:"updated_at"`
}

// 初始化数据库连接
func (m *ResumeDataMigrator) InitDB() error {
	// 从配置文件或环境变量读取配置
	m.config = &DBConfig{
		MySQLHost:     getEnv("MYSQL_HOST", "localhost"),
		MySQLPort:     getEnv("MYSQL_PORT", "3306"),
		MySQLUser:     getEnv("MYSQL_USER", "root"),
		MySQLPassword: getEnv("MYSQL_PASSWORD", ""),
		MySQLDatabase: getEnv("MYSQL_DATABASE", "jobfirst"),
	}

	// 连接MySQL数据库
	mysqlDSN := fmt.Sprintf("%s:%s@tcp(%s:%s)/%s?charset=utf8mb4&parseTime=True&loc=Local",
		m.config.MySQLUser, m.config.MySQLPassword, m.config.MySQLHost, m.config.MySQLPort, m.config.MySQLDatabase)

	var err error
	m.mysqlDB, err = sql.Open("mysql", mysqlDSN)
	if err != nil {
		return fmt.Errorf("连接MySQL数据库失败: %v", err)
	}

	// 测试连接
	if err := m.mysqlDB.Ping(); err != nil {
		return fmt.Errorf("MySQL数据库连接测试失败: %v", err)
	}

	fmt.Println("✅ MySQL数据库连接成功")
	return nil
}

// 获取用户SQLite数据库路径
func (m *ResumeDataMigrator) getUserSQLiteDBPath(userID int) string {
	return fmt.Sprintf("./data/users/%d/resume.db", userID)
}

// 迁移简历数据到SQLite
func (m *ResumeDataMigrator) MigrateResumeToSQLite(resume *ResumeMetadata) error {
	// 获取用户SQLite数据库路径
	sqlitePath := m.getUserSQLiteDBPath(resume.UserID)

	// 检查SQLite数据库是否存在
	if _, err := os.Stat(sqlitePath); os.IsNotExist(err) {
		return fmt.Errorf("用户SQLite数据库不存在: %s", sqlitePath)
	}

	// 连接SQLite数据库
	sqliteDB, err := sql.Open("sqlite3", sqlitePath)
	if err != nil {
		return fmt.Errorf("连接SQLite数据库失败: %v", err)
	}
	defer sqliteDB.Close()

	// 开始事务
	tx, err := sqliteDB.Begin()
	if err != nil {
		return fmt.Errorf("开始事务失败: %v", err)
	}
	defer tx.Rollback()

	// 插入简历内容
	contentQuery := `
		INSERT INTO resume_content (
			resume_metadata_id, title, content, content_hash, created_at, updated_at
		) VALUES (?, ?, ?, ?, ?, ?)
		ON CONFLICT(resume_metadata_id) DO UPDATE SET
			title = excluded.title,
			content = excluded.content,
			content_hash = excluded.content_hash,
			updated_at = excluded.updated_at
	`

	contentHash := generateContentHash(resume.Content)
	_, err = tx.Exec(contentQuery, resume.ID, resume.Title, resume.Content, contentHash, resume.CreatedAt, resume.UpdatedAt)
	if err != nil {
		return fmt.Errorf("插入简历内容失败: %v", err)
	}

	// 获取插入的内容ID
	var contentID int
	err = tx.QueryRow("SELECT id FROM resume_content WHERE resume_metadata_id = ?", resume.ID).Scan(&contentID)
	if err != nil {
		return fmt.Errorf("获取内容ID失败: %v", err)
	}

	// 插入默认隐私设置
	privacyQuery := `
		INSERT INTO user_privacy_settings (
			resume_content_id, is_public, allow_search, allow_download,
			view_permissions, download_permissions, created_at, updated_at
		) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
		ON CONFLICT(resume_content_id) DO UPDATE SET
			is_public = excluded.is_public,
			updated_at = excluded.updated_at
	`

	_, err = tx.Exec(privacyQuery, contentID, resume.IsPublic, true, false,
		`{"default": "private"}`, `{"default": "denied"}`, resume.CreatedAt, resume.UpdatedAt)
	if err != nil {
		return fmt.Errorf("插入隐私设置失败: %v", err)
	}

	// 创建版本历史
	versionQuery := `
		INSERT INTO resume_versions (
			resume_content_id, version_number, content_snapshot, change_description, created_at
		) VALUES (?, ?, ?, ?, ?)
	`

	_, err = tx.Exec(versionQuery, contentID, 1, resume.Content, "数据迁移", resume.CreatedAt)
	if err != nil {
		return fmt.Errorf("创建版本历史失败: %v", err)
	}

	// 提交事务
	if err := tx.Commit(); err != nil {
		return fmt.Errorf("提交事务失败: %v", err)
	}

	fmt.Printf("✅ 用户%d的简历%d迁移成功\n", resume.UserID, resume.ID)
	return nil
}

// 执行数据迁移
func (m *ResumeDataMigrator) MigrateAllResumes() error {
	fmt.Println("🔄 开始迁移所有简历数据...")

	// 查询所有简历数据
	query := `
		SELECT id, user_id, file_id, title, content, creation_mode, status,
			   is_public, view_count, parsing_status, parsing_error, created_at, updated_at
		FROM resumes_backup
		ORDER BY id
	`

	rows, err := m.mysqlDB.Query(query)
	if err != nil {
		return fmt.Errorf("查询简历数据失败: %v", err)
	}
	defer rows.Close()

	migratedCount := 0
	failedCount := 0

	for rows.Next() {
		var resume ResumeMetadata
		err := rows.Scan(
			&resume.ID, &resume.UserID, &resume.FileID, &resume.Title, &resume.Content,
			&resume.CreationMode, &resume.Status, &resume.IsPublic, &resume.ViewCount,
			&resume.ParsingStatus, &resume.ParsingError, &resume.CreatedAt, &resume.UpdatedAt,
		)
		if err != nil {
			fmt.Printf("❌ 扫描简历数据失败: %v\n", err)
			failedCount++
			continue
		}

		// 迁移到SQLite
		if err := m.MigrateResumeToSQLite(&resume); err != nil {
			fmt.Printf("❌ 迁移简历%d失败: %v\n", resume.ID, err)
			failedCount++
			continue
		}

		migratedCount++
	}

	if err := rows.Err(); err != nil {
		return fmt.Errorf("遍历简历数据失败: %v", err)
	}

	fmt.Printf("✅ 数据迁移完成！成功: %d, 失败: %d\n", migratedCount, failedCount)
	return nil
}

// 生成内容哈希
func generateContentHash(content string) string {
	// 简单的哈希实现，实际项目中应使用更安全的哈希算法
	return fmt.Sprintf("%x", len(content))
}

// 获取环境变量
func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

// 主函数
func main() {
	fmt.Println("🚀 简历数据迁移工具启动")

	// 创建迁移器
	migrator := &ResumeDataMigrator{}

	// 初始化数据库连接
	if err := migrator.InitDB(); err != nil {
		log.Fatalf("初始化数据库连接失败: %v", err)
	}
	defer migrator.mysqlDB.Close()

	// 执行数据迁移
	if err := migrator.MigrateAllResumes(); err != nil {
		log.Fatalf("数据迁移失败: %v", err)
	}

	fmt.Println("🎉 数据迁移完成！")
}
