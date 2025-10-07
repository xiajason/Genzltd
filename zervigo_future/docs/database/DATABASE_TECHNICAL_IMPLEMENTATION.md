# JobFirst 数据库技术实施细节 - 新架构版本

## 🔧 技术实施指南

### 🆕 新架构实施细节

#### 1. 数据分离存储实施

**MySQL数据库实施**：
```sql
-- 创建简历元数据表
CREATE TABLE resume_metadata (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT UNSIGNED NOT NULL,
    file_id INT,
    title VARCHAR(255) NOT NULL,
    creation_mode VARCHAR(20) DEFAULT 'markdown',
    template_id INT,
    status VARCHAR(20) DEFAULT 'draft',
    is_public BOOLEAN DEFAULT FALSE,
    view_count INT DEFAULT 0,
    parsing_status VARCHAR(20) DEFAULT 'pending',
    parsing_error TEXT,
    sqlite_db_path VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (file_id) REFERENCES resume_files(id) ON DELETE SET NULL,
    FOREIGN KEY (template_id) REFERENCES resume_templates(id) ON DELETE SET NULL,
    
    INDEX idx_user_id (user_id),
    INDEX idx_status (status),
    INDEX idx_parsing_status (parsing_status),
    INDEX idx_is_public (is_public),
    INDEX idx_view_count (view_count),
    INDEX idx_created_at (created_at)
);
```

**SQLite数据库实施**：
```sql
-- 创建简历内容表
CREATE TABLE resume_content (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    resume_metadata_id INTEGER NOT NULL,
    title TEXT NOT NULL,
    content TEXT,
    raw_content TEXT,
    content_hash TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(resume_metadata_id)
);

-- 创建解析结果表
CREATE TABLE parsed_resume_data (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    resume_content_id INTEGER NOT NULL,
    personal_info TEXT,
    work_experience TEXT,
    education TEXT,
    skills TEXT,
    projects TEXT,
    certifications TEXT,
    keywords TEXT,
    confidence REAL,
    parsing_version TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (resume_content_id) REFERENCES resume_content(id) ON DELETE CASCADE
);

-- 创建用户隐私设置表
CREATE TABLE user_privacy_settings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    resume_content_id INTEGER NOT NULL,
    is_public BOOLEAN DEFAULT FALSE,
    share_with_companies BOOLEAN DEFAULT FALSE,
    allow_search BOOLEAN DEFAULT TRUE,
    allow_download BOOLEAN DEFAULT FALSE,
    view_permissions TEXT,
    download_permissions TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (resume_content_id) REFERENCES resume_content(id) ON DELETE CASCADE,
    UNIQUE(resume_content_id)
);

-- 创建版本历史表
CREATE TABLE resume_versions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    resume_content_id INTEGER NOT NULL,
    version_number INTEGER NOT NULL,
    content_snapshot TEXT,
    change_description TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (resume_content_id) REFERENCES resume_content(id) ON DELETE CASCADE,
    UNIQUE(resume_content_id, version_number)
);

-- 创建自定义字段表
CREATE TABLE user_custom_fields (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    resume_content_id INTEGER NOT NULL,
    field_name TEXT NOT NULL,
    field_value TEXT,
    field_type TEXT DEFAULT 'text',
    is_public BOOLEAN DEFAULT FALSE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (resume_content_id) REFERENCES resume_content(id) ON DELETE CASCADE,
    UNIQUE(resume_content_id, field_name)
);

-- 创建访问日志表
CREATE TABLE resume_access_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    resume_content_id INTEGER NOT NULL,
    access_type TEXT NOT NULL,
    access_source TEXT,
    user_agent TEXT,
    ip_address TEXT,
    access_time DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (resume_content_id) REFERENCES resume_content(id) ON DELETE CASCADE
);
```

#### 2. 多创建方式实施

**Markdown编辑模式**：
```go
func handleMarkdownMode(c *gin.Context, core *jobfirst.Core, userID uint) {
    var req CreateResumeRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": "请求参数错误: " + err.Error()})
        return
    }

    // 1. 在MySQL中创建元数据记录
    resumeMetadata, err := createResumeMetadata(core, userID, nil, req.Title, "markdown")
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "创建简历元数据失败: " + err.Error()})
        return
    }

    // 2. 在用户SQLite中创建内容记录
    contentID, err := createResumeContent(userID, int(resumeMetadata.ID), req.Title, req.Content)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "创建简历内容失败: " + err.Error()})
        return
    }

    // 3. 创建版本历史
    err = createVersionHistory(userID, contentID, req.Content, "创建简历")
    if err != nil {
        log.Printf("创建版本历史失败: %v", err)
    }

    c.JSON(http.StatusCreated, gin.H{
        "resume_id": resumeMetadata.ID,
        "message":   "简历创建成功",
        "status":    "created",
    })
}
```

**文件上传模式**：
```go
func handleFileUploadMode(c *gin.Context, core *jobfirst.Core, userID uint) {
    // 1. 获取上传的文件
    file, header, err := c.Request.FormFile("file")
    if err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": "文件上传失败: " + err.Error()})
        return
    }
    defer file.Close()

    // 2. 保存文件到磁盘
    filePath, err := saveUploadedFile(file, header, userID)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "文件保存失败: " + err.Error()})
        return
    }

    // 3. 在MySQL中创建元数据记录
    resumeFile, err := createResumeFileMetadata(core, userID, header, filePath)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "创建文件元数据失败: " + err.Error()})
        return
    }

    resumeMetadata, err := createResumeMetadata(core, userID, &resumeFile.ID, header.Filename, "upload")
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "创建简历元数据失败: " + err.Error()})
        return
    }

    // 4. 在用户SQLite中创建内容记录
    contentID, err := createResumeContent(userID, int(resumeMetadata.ID), header.Filename, "")
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "创建简历内容失败: " + err.Error()})
        return
    }

    // 5. 启动异步解析任务
    go startParsingTask(core, resumeMetadata.ID, contentID, filePath)

    c.JSON(http.StatusCreated, gin.H{
        "resume_id": resumeMetadata.ID,
        "message":   "文件上传成功，正在解析中...",
        "status":    "parsing",
    })
}
```

#### 3. 数据迁移实施

**MySQL数据迁移**：
```sql
-- 迁移resumes表数据到resume_metadata表
INSERT INTO resume_metadata (
    id, user_id, file_id, title, creation_mode, template_id, status, 
    is_public, view_count, parsing_status, parsing_error, created_at, updated_at
)
SELECT 
    id, user_id, file_id, title, 
    COALESCE(creation_mode, 'markdown') as creation_mode,
    template_id,
    COALESCE(status, 'draft') as status,
    COALESCE(is_public, FALSE) as is_public,
    COALESCE(view_count, 0) as view_count,
    COALESCE(parsing_status, 'pending') as parsing_status,
    parsing_error,
    created_at,
    updated_at
FROM resumes_backup
WHERE id IS NOT NULL;

-- 更新SQLite数据库路径
UPDATE resume_metadata 
SET sqlite_db_path = CONCAT('./data/users/', user_id, '/resume.db')
WHERE sqlite_db_path IS NULL;
```

**Go语言数据迁移工具**：
```go
func (m *ResumeDataMigrator) MigrateResumeToSQLite(resume *ResumeMetadata) error {
    // 获取用户SQLite数据库路径
    sqlitePath := m.getUserSQLiteDBPath(resume.UserID)

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

    // 提交事务
    if err := tx.Commit(); err != nil {
        return fmt.Errorf("提交事务失败: %v", err)
    }

    return nil
}
```

#### 4. 测试验证实施

**架构测试脚本**：
```bash
#!/bin/bash
# 简历存储架构测试脚本

echo "🚀 开始测试简历存储架构..."

# 验证MySQL元数据存储
echo "🔍 第一步：验证MySQL元数据存储"
mysql -u root jobfirst -e "DESCRIBE resume_metadata;" > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ resume_metadata表存在"
else
    echo "❌ resume_metadata表不存在"
    exit 1
fi

# 验证SQLite内容存储
echo "🔍 第二步：验证SQLite内容存储"
SQLITE_DB="data/users/4/resume.db"
if [ -f "$SQLITE_DB" ]; then
    echo "✅ 用户SQLite数据库存在: $SQLITE_DB"
else
    echo "❌ 用户SQLite数据库不存在: $SQLITE_DB"
    exit 1
fi

# 验证数据分离存储
echo "🔍 第三步：验证数据分离存储"
CONTENT_FIELD=$(mysql -u root jobfirst -e "SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'resume_metadata' AND COLUMN_NAME = 'content' AND TABLE_SCHEMA = 'jobfirst';" -s -N)
if [ "$CONTENT_FIELD" -eq 0 ]; then
    echo "✅ MySQL中没有content字段（符合设计原则）"
else
    echo "❌ MySQL中存在content字段（违反设计原则）"
    exit 1
fi

echo "🎉 简历存储架构测试完成！"
```

### 🆕 新架构概述

JobFirst V3.0 实施了全新的简历存储架构，采用**数据分离存储**的设计原则：
- **MySQL数据库**: 只存储元数据（用户ID、标题、状态、统计等）
- **SQLite数据库**: 只存储用户专属内容（简历内容、解析结果、隐私设置等）
- **用户数据隔离**: 每个用户有独立的SQLite数据库，确保数据安全

### 1. 新架构数据库配置

#### 配置文件结构 - 新架构
```
basic/
├── configs/
│   ├── database/
│   │   ├── mysql-config.yaml          # MySQL元数据存储配置
│   │   ├── sqlite-config.yaml         # SQLite内容存储配置
│   │   ├── redis-config.yaml          # 缓存配置
│   │   ├── postgresql-config.yaml     # AI服务数据库配置
│   │   └── neo4j-config.yaml          # 图谱数据库配置
│   └── services/
│       ├── basic-server-config.yaml   # 基础服务配置
│       ├── user-service-config.yaml   # 用户服务配置
│       ├── resume-service-config.yaml # 简历服务配置（新架构）
│       └── ai-service-config.yaml     # AI服务配置
├── data/
│   └── users/
│       ├── 1/
│       │   └── resume.db              # 用户1的SQLite数据库
│       ├── 2/
│       │   └── resume.db              # 用户2的SQLite数据库
│       └── {user_id}/
│           └── resume.db              # 用户专属SQLite数据库
```

#### 统一配置模板
```yaml
# mysql-config.yaml
mysql:
  host: "localhost"
  port: 3306
  database: "jobfirst"
  username: "jobfirst"
  password: "jobfirst123"
  charset: "utf8mb4"
  max_open_conns: 100
  max_idle_conns: 10
  conn_max_lifetime: "1h"
  ssl_mode: "disable"

# redis-config.yaml
redis:
  host: "localhost"
  port: 6379
  password: ""
  db: 0
  pool_size: 10
  min_idle_conns: 5
  max_retries: 3
  dial_timeout: "5s"
  read_timeout: "3s"
  write_timeout: "3s"

# sqlite-config.yaml - 新架构SQLite配置
sqlite:
  base_path: "./data/users"
  database_name: "resume.db"
  max_open_conns: 25
  max_idle_conns: 5
  conn_max_lifetime: "30m"
  journal_mode: "WAL"
  synchronous: "NORMAL"
  cache_size: 1000
  temp_store: "memory"
  mmap_size: 268435456  # 256MB

# postgresql-config.yaml
postgresql:
  host: "localhost"
  port: 5432
  database: "jobfirst_vector"
  username: "szjason72"
  password: ""
  ssl_mode: "disable"
  max_open_conns: 100
  max_idle_conns: 10
  conn_max_lifetime: "1h"
  
# PostgreSQL权限配置
postgresql_permissions:
  super_admin: "szjason72"  # 系统超级管理员
  team_role: "jobfirst_team"  # 项目团队成员角色
  rls_enabled: true  # 启用行级安全策略
  user_session_var: "app.current_user_id"  # 用户会话变量

# neo4j-config.yaml
neo4j:
  host: "localhost"
  port: 7687
  username: "neo4j"
  password: "jobfirst123"
  database: "neo4j"
  max_conn_lifetime: "1h"
  max_conn_pool_size: 100
```

### 2. 数据库连接管理

#### Go语言数据库连接池
```go
// pkg/database/manager.go
package database

import (
    "fmt"
    "time"
    "gorm.io/driver/mysql"
    "gorm.io/driver/postgres"
    "gorm.io/gorm"
    "github.com/go-redis/redis/v8"
    "github.com/neo4j/neo4j-go-driver/v4/neo4j"
)

type DatabaseManager struct {
    MySQL      *gorm.DB
    PostgreSQL *gorm.DB
    Redis      *redis.Client
    Neo4j      neo4j.Driver
}

func NewDatabaseManager(config *Config) (*DatabaseManager, error) {
    manager := &DatabaseManager{}
    
    // 初始化MySQL
    if err := manager.initMySQL(config.MySQL); err != nil {
        return nil, fmt.Errorf("failed to init MySQL: %v", err)
    }
    
    // 初始化PostgreSQL
    if err := manager.initPostgreSQL(config.PostgreSQL); err != nil {
        return nil, fmt.Errorf("failed to init PostgreSQL: %v", err)
    }
    
    // 初始化Redis
    if err := manager.initRedis(config.Redis); err != nil {
        return nil, fmt.Errorf("failed to init Redis: %v", err)
    }
    
    // 初始化Neo4j
    if err := manager.initNeo4j(config.Neo4j); err != nil {
        return nil, fmt.Errorf("failed to init Neo4j: %v", err)
    }
    
    return manager, nil
}

func (dm *DatabaseManager) initMySQL(config MySQLConfig) error {
    dsn := fmt.Sprintf("%s:%s@tcp(%s:%d)/%s?charset=%s&parseTime=True&loc=Local",
        config.Username, config.Password, config.Host, config.Port, config.Database, config.Charset)
    
    db, err := gorm.Open(mysql.Open(dsn), &gorm.Config{})
    if err != nil {
        return err
    }
    
    sqlDB, err := db.DB()
    if err != nil {
        return err
    }
    
    sqlDB.SetMaxOpenConns(config.MaxOpenConns)
    sqlDB.SetMaxIdleConns(config.MaxIdleConns)
    sqlDB.SetConnMaxLifetime(time.Duration(config.ConnMaxLifetime))
    
    dm.MySQL = db
    return nil
}

func (dm *DatabaseManager) initPostgreSQL(config PostgreSQLConfig) error {
    dsn := fmt.Sprintf("host=%s port=%d user=%s password=%s dbname=%s sslmode=%s",
        config.Host, config.Port, config.Username, config.Password, config.Database, config.SSLMode)
    
    db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
    if err != nil {
        return err
    }
    
    sqlDB, err := db.DB()
    if err != nil {
        return err
    }
    
    sqlDB.SetMaxOpenConns(config.MaxOpenConns)
    sqlDB.SetMaxIdleConns(config.MaxIdleConns)
    sqlDB.SetConnMaxLifetime(time.Duration(config.ConnMaxLifetime))
    
    dm.PostgreSQL = db
    return nil
}

func (dm *DatabaseManager) initRedis(config RedisConfig) error {
    rdb := redis.NewClient(&redis.Options{
        Addr:         fmt.Sprintf("%s:%d", config.Host, config.Port),
        Password:     config.Password,
        DB:           config.DB,
        PoolSize:     config.PoolSize,
        MinIdleConns: config.MinIdleConns,
        MaxRetries:   config.MaxRetries,
        DialTimeout:  time.Duration(config.DialTimeout),
        ReadTimeout:  time.Duration(config.ReadTimeout),
        WriteTimeout: time.Duration(config.WriteTimeout),
    })
    
    // 测试连接
    ctx := context.Background()
    if err := rdb.Ping(ctx).Err(); err != nil {
        return err
    }
    
    dm.Redis = rdb
    return nil
}

func (dm *DatabaseManager) initNeo4j(config Neo4jConfig) error {
    uri := fmt.Sprintf("neo4j://%s:%d", config.Host, config.Port)
    
    driver, err := neo4j.NewDriver(uri, neo4j.BasicAuth(config.Username, config.Password, ""))
    if err != nil {
        return err
    }
    
    // 测试连接
    ctx := context.Background()
    if err := driver.VerifyConnectivity(ctx); err != nil {
        return err
    }
    
    dm.Neo4j = driver
    return nil
}
```

### 3. 数据模型定义

#### MySQL数据模型
```go
// models/user.go
package models

import (
    "time"
    "gorm.io/gorm"
)

type User struct {
    ID        uint           `json:"id" gorm:"primaryKey"`
    Username  string         `json:"username" gorm:"uniqueIndex;size:50;not null"`
    Email     string         `json:"email" gorm:"uniqueIndex;size:100;not null"`
    Password  string         `json:"-" gorm:"size:255;not null"`
    Role      string         `json:"role" gorm:"size:20;default:'user'"`
    Status    string         `json:"status" gorm:"size:20;default:'active'"`
    CreatedAt time.Time      `json:"created_at"`
    UpdatedAt time.Time      `json:"updated_at"`
    DeletedAt gorm.DeletedAt `json:"deleted_at" gorm:"index"`
    
    // 地理位置字段
    Location      string  `json:"location" gorm:"size:255"`
    Latitude      float64 `json:"latitude" gorm:"type:decimal(10,8)"`
    Longitude     float64 `json:"longitude" gorm:"type:decimal(11,8)"`
    AddressDetail string  `json:"address_detail" gorm:"type:text"`
    CityCode      string  `json:"city_code" gorm:"size:20"`
    DistrictCode  string  `json:"district_code" gorm:"size:20"`
    
    // 关联关系
    Resumes []Resume `json:"resumes" gorm:"foreignKey:UserID"`
}

type Resume struct {
    ID          uint           `json:"id" gorm:"primaryKey"`
    UserID      uint           `json:"user_id" gorm:"not null;index"`
    Title       string         `json:"title" gorm:"size:200;not null"`
    Content     string         `json:"content" gorm:"type:longtext"`
    Status      string         `json:"status" gorm:"size:20;default:'draft'"`
    CreatedAt   time.Time      `json:"created_at"`
    UpdatedAt   time.Time      `json:"updated_at"`
    DeletedAt   gorm.DeletedAt `json:"deleted_at" gorm:"index"`
    
    // 关联关系
    User User `json:"user" gorm:"foreignKey:UserID"`
}

type Company struct {
    ID          uint           `json:"id" gorm:"primaryKey"`
    Name        string         `json:"name" gorm:"size:200;not null"`
    Location    string         `json:"location" gorm:"size:255"`
    Industry    string         `json:"industry" gorm:"size:100"`
    Status      string         `json:"status" gorm:"size:20;default:'active'"`
    CreatedAt   time.Time      `json:"created_at"`
    UpdatedAt   time.Time      `json:"updated_at"`
    DeletedAt   gorm.DeletedAt `json:"deleted_at" gorm:"index"`
    
    // 地理位置字段
    Latitude      float64 `json:"latitude" gorm:"type:decimal(10,8)"`
    Longitude     float64 `json:"longitude" gorm:"type:decimal(11,8)"`
    AddressDetail string  `json:"address_detail" gorm:"type:text"`
    CityCode      string  `json:"city_code" gorm:"size:20"`
    DistrictCode  string  `json:"district_code" gorm:"size:20"`
}
```

#### PostgreSQL向量模型
```go
// models/vector.go
package models

import (
    "time"
    "gorm.io/gorm"
)

type ResumeVector struct {
    ID            uint           `json:"id" gorm:"primaryKey"`
    ResumeID      uint           `json:"resume_id" gorm:"not null;index"`
    ContentVector []float64      `json:"content_vector" gorm:"type:vector(1536)"`
    CreatedAt     time.Time      `json:"created_at"`
    UpdatedAt     time.Time      `json:"updated_at"`
    DeletedAt     gorm.DeletedAt `json:"deleted_at" gorm:"index"`
}
```

### 4. Neo4j图数据模型

#### 地理位置节点模型
```cypher
// 创建地理位置节点
CREATE CONSTRAINT location_id_unique FOR (l:Location) REQUIRE l.id IS UNIQUE;
CREATE CONSTRAINT user_id_unique FOR (u:User) REQUIRE u.id IS UNIQUE;
CREATE CONSTRAINT company_id_unique FOR (c:Company) REQUIRE c.id IS UNIQUE;

// 创建地理位置节点
CREATE (l:Location {
    id: 'loc_001',
    name: '北京市朝阳区',
    latitude: 39.9042,
    longitude: 116.4074,
    city_code: '110100',
    district_code: '110105',
    level: 'district',
    created_at: datetime()
});

// 创建用户节点
CREATE (u:User {
    id: 'user_001',
    username: 'testuser',
    email: 'test@example.com',
    latitude: 39.9042,
    longitude: 116.4074,
    created_at: datetime()
});

// 创建公司节点
CREATE (c:Company {
    id: 'company_001',
    name: '测试公司',
    latitude: 39.9042,
    longitude: 116.4074,
    created_at: datetime()
});

// 创建关系
CREATE (u:User)-[:LIVES_IN]->(l:Location);
CREATE (c:Company)-[:LOCATED_IN]->(l:Location);
CREATE (city:Location)-[:CONTAINS]->(district:Location);
```

#### 智能匹配查询
```cypher
// 查找用户附近的公司
MATCH (u:User {id: 'user_001'})-[:LIVES_IN]->(ul:Location)
MATCH (c:Company)-[:LOCATED_IN]->(cl:Location)
WHERE ul.city_code = cl.city_code
WITH u, c, ul, cl,
     distance(point({latitude: ul.latitude, longitude: ul.longitude}),
              point({latitude: cl.latitude, longitude: cl.longitude})) as dist
WHERE dist < 10000  // 10公里内
RETURN c.name, c.industry, dist
ORDER BY dist
LIMIT 10;

// 查找同城用户
MATCH (u1:User {id: 'user_001'})-[:LIVES_IN]->(l:Location)
MATCH (u2:User)-[:LIVES_IN]->(l)
WHERE u1.id <> u2.id
RETURN u2.username, u2.email, l.name
LIMIT 20;
```

### 5. 缓存策略实现

#### Redis缓存管理
```go
// pkg/cache/manager.go
package cache

import (
    "context"
    "encoding/json"
    "fmt"
    "time"
    "github.com/go-redis/redis/v8"
)

type CacheManager struct {
    client *redis.Client
}

func NewCacheManager(client *redis.Client) *CacheManager {
    return &CacheManager{client: client}
}

// 用户会话缓存
func (cm *CacheManager) SetUserSession(ctx context.Context, userID uint, sessionData interface{}, ttl time.Duration) error {
    key := fmt.Sprintf("user:session:%d", userID)
    data, err := json.Marshal(sessionData)
    if err != nil {
        return err
    }
    return cm.client.Set(ctx, key, data, ttl).Err()
}

func (cm *CacheManager) GetUserSession(ctx context.Context, userID uint, dest interface{}) error {
    key := fmt.Sprintf("user:session:%d", userID)
    data, err := cm.client.Get(ctx, key).Result()
    if err != nil {
        return err
    }
    return json.Unmarshal([]byte(data), dest)
}

// 简历数据缓存
func (cm *CacheManager) SetResumeData(ctx context.Context, resumeID uint, resumeData interface{}, ttl time.Duration) error {
    key := fmt.Sprintf("resume:data:%d", resumeID)
    data, err := json.Marshal(resumeData)
    if err != nil {
        return err
    }
    return cm.client.Set(ctx, key, data, ttl).Err()
}

func (cm *CacheManager) GetResumeData(ctx context.Context, resumeID uint, dest interface{}) error {
    key := fmt.Sprintf("resume:data:%d", resumeID)
    data, err := cm.client.Get(ctx, key).Result()
    if err != nil {
        return err
    }
    return json.Unmarshal([]byte(data), dest)
}

// 地理位置缓存
func (cm *CacheManager) SetLocationData(ctx context.Context, address string, locationData interface{}, ttl time.Duration) error {
    key := fmt.Sprintf("location:geo:%s", address)
    data, err := json.Marshal(locationData)
    if err != nil {
        return err
    }
    return cm.client.Set(ctx, key, data, ttl).Err()
}

func (cm *CacheManager) GetLocationData(ctx context.Context, address string, dest interface{}) error {
    key := fmt.Sprintf("location:geo:%s", address)
    data, err := cm.client.Get(ctx, key).Result()
    if err != nil {
        return err
    }
    return json.Unmarshal([]byte(data), dest)
}
```

### 6. 北斗服务集成

#### 北斗服务客户端
```go
// pkg/geo/beidou_client.go
package geo

import (
    "bytes"
    "encoding/json"
    "fmt"
    "io"
    "net/http"
    "time"
)

type BeidouClient struct {
    APIKey    string
    BaseURL   string
    RateLimit int
    client    *http.Client
}

type GeoResult struct {
    Latitude  float64 `json:"latitude"`
    Longitude float64 `json:"longitude"`
    Address   string  `json:"address"`
    CityCode  string  `json:"city_code"`
    DistrictCode string `json:"district_code"`
}

type AddressResult struct {
    Address      string `json:"address"`
    CityCode     string `json:"city_code"`
    DistrictCode string `json:"district_code"`
    Province     string `json:"province"`
    City         string `json:"city"`
    District     string `json:"district"`
}

func NewBeidouClient(apiKey, baseURL string) *BeidouClient {
    return &BeidouClient{
        APIKey:    apiKey,
        BaseURL:   baseURL,
        RateLimit: 1000,
        client: &http.Client{
            Timeout: 30 * time.Second,
        },
    }
}

// 地理编码
func (bc *BeidouClient) Geocode(address string) (*GeoResult, error) {
    url := fmt.Sprintf("%s/geocode", bc.BaseURL)
    
    payload := map[string]string{
        "address": address,
        "key":     bc.APIKey,
    }
    
    jsonData, err := json.Marshal(payload)
    if err != nil {
        return nil, err
    }
    
    req, err := http.NewRequest("POST", url, bytes.NewBuffer(jsonData))
    if err != nil {
        return nil, err
    }
    
    req.Header.Set("Content-Type", "application/json")
    
    resp, err := bc.client.Do(req)
    if err != nil {
        return nil, err
    }
    defer resp.Body.Close()
    
    body, err := io.ReadAll(resp.Body)
    if err != nil {
        return nil, err
    }
    
    var result GeoResult
    if err := json.Unmarshal(body, &result); err != nil {
        return nil, err
    }
    
    return &result, nil
}

// 逆地理编码
func (bc *BeidouClient) ReverseGeocode(latitude, longitude float64) (*AddressResult, error) {
    url := fmt.Sprintf("%s/reverse-geocode", bc.BaseURL)
    
    payload := map[string]interface{}{
        "latitude":  latitude,
        "longitude": longitude,
        "key":       bc.APIKey,
    }
    
    jsonData, err := json.Marshal(payload)
    if err != nil {
        return nil, err
    }
    
    req, err := http.NewRequest("POST", url, bytes.NewBuffer(jsonData))
    if err != nil {
        return nil, err
    }
    
    req.Header.Set("Content-Type", "application/json")
    
    resp, err := bc.client.Do(req)
    if err != nil {
        return nil, err
    }
    defer resp.Body.Close()
    
    body, err := io.ReadAll(resp.Body)
    if err != nil {
        return nil, err
    }
    
    var result AddressResult
    if err := json.Unmarshal(body, &result); err != nil {
        return nil, err
    }
    
    return &result, nil
}
```

### 7. 监控和告警

#### 健康检查服务
```go
// pkg/health/checker.go
package health

import (
    "context"
    "fmt"
    "time"
    "github.com/gin-gonic/gin"
)

type HealthChecker struct {
    dbManager *database.DatabaseManager
    cacheManager *cache.CacheManager
}

func NewHealthChecker(dbManager *database.DatabaseManager, cacheManager *cache.CacheManager) *HealthChecker {
    return &HealthChecker{
        dbManager: dbManager,
        cacheManager: cacheManager,
    }
}

func (hc *HealthChecker) CheckHealth(c *gin.Context) {
    ctx := context.Background()
    
    health := map[string]interface{}{
        "status":    "healthy",
        "timestamp": time.Now().Unix(),
        "services":  make(map[string]interface{}),
    }
    
    // 检查MySQL
    if err := hc.checkMySQL(ctx); err != nil {
        health["services"].(map[string]interface{})["mysql"] = map[string]interface{}{
            "status": "unhealthy",
            "error":  err.Error(),
        }
        health["status"] = "unhealthy"
    } else {
        health["services"].(map[string]interface{})["mysql"] = map[string]interface{}{
            "status": "healthy",
        }
    }
    
    // 检查Redis
    if err := hc.checkRedis(ctx); err != nil {
        health["services"].(map[string]interface{})["redis"] = map[string]interface{}{
            "status": "unhealthy",
            "error":  err.Error(),
        }
        health["status"] = "unhealthy"
    } else {
        health["services"].(map[string]interface{})["redis"] = map[string]interface{}{
            "status": "healthy",
        }
    }
    
    // 检查PostgreSQL
    if err := hc.checkPostgreSQL(ctx); err != nil {
        health["services"].(map[string]interface{})["postgresql"] = map[string]interface{}{
            "status": "unhealthy",
            "error":  err.Error(),
        }
        health["status"] = "unhealthy"
    } else {
        health["services"].(map[string]interface{})["postgresql"] = map[string]interface{}{
            "status": "healthy",
        }
    }
    
    // 检查Neo4j
    if err := hc.checkNeo4j(ctx); err != nil {
        health["services"].(map[string]interface{})["neo4j"] = map[string]interface{}{
            "status": "unhealthy",
            "error":  err.Error(),
        }
        health["status"] = "unhealthy"
    } else {
        health["services"].(map[string]interface{})["neo4j"] = map[string]interface{}{
            "status": "healthy",
        }
    }
    
    statusCode := 200
    if health["status"] == "unhealthy" {
        statusCode = 503
    }
    
    c.JSON(statusCode, health)
}

func (hc *HealthChecker) checkMySQL(ctx context.Context) error {
    sqlDB, err := hc.dbManager.MySQL.DB()
    if err != nil {
        return err
    }
    return sqlDB.PingContext(ctx)
}

func (hc *HealthChecker) checkRedis(ctx context.Context) error {
    return hc.cacheManager.client.Ping(ctx).Err()
}

func (hc *HealthChecker) checkPostgreSQL(ctx context.Context) error {
    sqlDB, err := hc.dbManager.PostgreSQL.DB()
    if err != nil {
        return err
    }
    return sqlDB.PingContext(ctx)
}

func (hc *HealthChecker) checkNeo4j(ctx context.Context) error {
    return hc.dbManager.Neo4j.VerifyConnectivity(ctx)
}
```

### 8. PostgreSQL权限管理实施

#### 8.1 权限配置脚本
```sql
-- PostgreSQL权限配置脚本
-- 按照项目权限分配方案设置：
-- 1. 系统超级管理员（szjason72）可以访问所有数据
-- 2. 项目团队成员可以访问
-- 3. 用户只能访问自己的向量数据

-- 创建项目团队成员角色
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'jobfirst_team') THEN
        CREATE ROLE jobfirst_team;
    END IF;
END
$$;

-- 设置jobfirst_team角色权限
GRANT CONNECT ON DATABASE jobfirst_vector TO jobfirst_team;
GRANT USAGE ON SCHEMA public TO jobfirst_team;

-- 为所有表设置权限
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO jobfirst_team;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO jobfirst_team;

-- 设置默认权限，确保新创建的表也有相应权限
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO jobfirst_team;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO jobfirst_team;

-- 为特定用户数据表设置行级安全策略（RLS）
ALTER TABLE resume_vectors ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_embeddings ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_ai_profiles ENABLE ROW LEVEL SECURITY;

-- 创建策略：用户只能访问自己的数据
DO $$
BEGIN
    -- 检查user_ai_profiles表是否有user_id字段
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'user_ai_profiles' AND column_name = 'user_id') THEN
        CREATE POLICY user_ai_profiles_policy ON user_ai_profiles
            FOR ALL TO PUBLIC
            USING (user_id = current_setting('app.current_user_id', true)::bigint);
    END IF;
END
$$;

-- 超级管理员可以绕过所有RLS策略
ALTER ROLE szjason72 BYPASSRLS;
ALTER ROLE jobfirst_team BYPASSRLS;
```

#### 8.2 权限验证脚本
```sql
-- 验证权限配置
SELECT 
    t.schemaname,
    t.tablename,
    t.rowsecurity as rls_enabled
FROM pg_tables t
WHERE t.schemaname = 'public' 
  AND t.rowsecurity = true
ORDER BY t.tablename;

-- 验证角色权限
SELECT 
    r.rolname as role_name,
    r.rolsuper as is_superuser,
    r.rolbypassrls as can_bypass_rls,
    r.rolcanlogin as can_login
FROM pg_roles r
WHERE r.rolname IN ('szjason72', 'jobfirst_team');
```

#### 8.3 Go语言权限管理
```go
// pkg/database/postgresql_permissions.go
package database

import (
    "context"
    "fmt"
    "gorm.io/gorm"
)

type PostgreSQLPermissionManager struct {
    db *gorm.DB
}

func NewPostgreSQLPermissionManager(db *gorm.DB) *PostgreSQLPermissionManager {
    return &PostgreSQLPermissionManager{db: db}
}

// 设置用户会话变量
func (ppm *PostgreSQLPermissionManager) SetUserSession(ctx context.Context, userID uint) error {
    return ppm.db.WithContext(ctx).Exec(
        "SET app.current_user_id = ?", userID,
    ).Error
}

// 验证用户数据访问权限
func (ppm *PostgreSQLPermissionManager) ValidateUserAccess(ctx context.Context, userID uint, tableName string) error {
    var count int64
    query := fmt.Sprintf(`
        SELECT COUNT(*) FROM %s 
        WHERE user_id = current_setting('app.current_user_id', true)::bigint
    `, tableName)
    
    if err := ppm.db.WithContext(ctx).Raw(query).Scan(&count).Error; err != nil {
        return fmt.Errorf("权限验证失败: %v", err)
    }
    
    if count == 0 {
        return fmt.Errorf("用户 %d 无权访问表 %s", userID, tableName)
    }
    
    return nil
}

// 获取用户专属数据
func (ppm *PostgreSQLPermissionManager) GetUserData(ctx context.Context, userID uint, tableName string, dest interface{}) error {
    // 设置会话变量
    if err := ppm.SetUserSession(ctx, userID); err != nil {
        return err
    }
    
    // 查询用户数据
    query := fmt.Sprintf("SELECT * FROM %s", tableName)
    return ppm.db.WithContext(ctx).Raw(query).Scan(dest).Error
}
```

### 9. 部署脚本

#### 数据库初始化脚本
```bash
#!/bin/bash
# scripts/init-databases.sh

set -e

echo "开始初始化数据库..."

# 初始化MySQL
echo "初始化MySQL数据库..."
mysql -u root -p < database/mysql/init.sql
mysql -u root -p < database/mysql/init_v3.sql
mysql -u root -p < database/mysql/seed_v3.sql

# 初始化PostgreSQL
echo "初始化PostgreSQL数据库..."
sudo -u postgres psql -c "CREATE DATABASE jobfirst_vector;"
sudo -u postgres psql -d jobfirst_vector < database/postgresql/init.sql

# 初始化Neo4j
echo "初始化Neo4j数据库..."
cypher-shell -u neo4j -p jobfirst123 < database/neo4j/init.cypher

# 配置Redis
echo "配置Redis..."
sudo cp database/redis/redis.conf /etc/redis/redis.conf
sudo systemctl restart redis

echo "数据库初始化完成！"
```

#### 服务启动脚本
```bash
#!/bin/bash
# scripts/start-services.sh

set -e

echo "开始启动服务..."

# 启动Consul
echo "启动Consul服务发现..."
consul agent -dev -ui -client=0.0.0.0 &

# 等待Consul启动
sleep 5

# 启动Basic-Server
echo "启动Basic-Server..."
cd /opt/jobfirst/basic-server
nohup ./main > basic-server.log 2>&1 &

# 等待Basic-Server启动
sleep 3

# 启动User-Service
echo "启动User-Service..."
cd /opt/jobfirst/user-service
nohup ./user-service > user-service.log 2>&1 &

# 等待User-Service启动
sleep 3

# 启动Resume-Service
echo "启动Resume-Service..."
cd /opt/jobfirst/resume-service
nohup ./resume-service > resume-service.log 2>&1 &

echo "所有服务启动完成！"
```

---

## 📋 实施检查清单

### 数据库配置检查
- [ ] MySQL连接配置正确
- [ ] Redis连接配置正确
- [ ] PostgreSQL连接配置正确
- [ ] Neo4j连接配置正确
- [ ] 所有服务使用统一配置

### 数据一致性检查
- [ ] 用户表数据完整
- [ ] 简历表数据完整
- [ ] 外键约束正确
- [ ] 索引优化完成
- [ ] 孤立数据清理完成

### 服务启动检查
- [ ] Consul服务发现正常
- [ ] Basic-Server启动正常
- [ ] User-Service启动正常
- [ ] Resume-Service启动正常
- [ ] AI-Service待命状态正常

### 监控告警检查
- [ ] 健康检查接口正常
- [ ] 性能监控配置完成
- [ ] 告警规则设置完成
- [ ] 日志收集配置完成

### 安全加固检查
- [ ] 数据库访问权限正确
- [ ] API安全中间件配置
- [ ] 数据传输加密配置
- [ ] 敏感数据加密配置

---

**文档版本**: v1.0  
**最后更新**: 2024年9月  
**维护人员**: 技术团队
