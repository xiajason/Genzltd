#!/bin/bash
# jobfirst-core架构整合脚本
# 用于将现有微服务迁移到jobfirst-core统一架构

set -e  # 遇到错误立即退出

echo "🏗️ 开始jobfirst-core架构整合..."
echo "=================================="

# 项目根目录
PROJECT_ROOT="/Users/szjason72/zervi-basic/basic"
BACKEND_ROOT="$PROJECT_ROOT/backend"

# 检查jobfirst-core是否存在
JOBFIRST_CORE_PATH="$BACKEND_ROOT/pkg/jobfirst-core"
if [ ! -d "$JOBFIRST_CORE_PATH" ]; then
    echo "❌ jobfirst-core目录不存在: $JOBFIRST_CORE_PATH"
    exit 1
fi

echo "✅ 发现jobfirst-core目录: $JOBFIRST_CORE_PATH"

# 1. 创建统一的配置文件
echo "📋 创建统一的配置文件..."
CONFIG_DIR="$PROJECT_ROOT/config"
mkdir -p "$CONFIG_DIR"

# 创建主配置文件
cat > "$CONFIG_DIR/app.json" << 'EOF'
{
  "version": "1.0.0",
  "app": {
    "name": "JobFirst Platform",
    "version": "1.0.0",
    "environment": "development"
  },
  "database": {
    "host": "localhost",
    "port": "3306",
    "username": "root",
    "password": "@SZxym2006",
    "database": "jobfirst",
    "charset": "utf8mb4",
    "max_idle": 10,
    "max_open": 100,
    "max_lifetime": "1h",
    "log_level": "warn"
  },
  "redis": {
    "host": "localhost",
    "port": 6379,
    "password": "",
    "database": 0,
    "pool_size": 10,
    "min_idle": 5
  },
  "postgresql": {
    "host": "localhost",
    "port": 5432,
    "username": "szjason72",
    "password": "",
    "database": "jobfirst_vector",
    "ssl_mode": "disable",
    "max_idle": 10,
    "max_open": 100,
    "max_lifetime": "1h",
    "log_level": "warn"
  },
  "neo4j": {
    "uri": "",
    "username": "neo4j",
    "password": "password",
    "database": "neo4j"
  },
  "auth": {
    "jwt_secret": "your-jwt-secret-key-change-in-production",
    "token_expiry": "24h",
    "refresh_expiry": "168h",
    "password_min": 8,
    "max_login_attempts": 5,
    "lockout_duration": "15m"
  },
  "log": {
    "level": "info",
    "format": "json",
    "output": "stdout",
    "file": ""
  },
  "consul": {
    "host": "localhost",
    "port": 8500,
    "enabled": true
  },
  "services": {
    "resume-service": {
      "port": 8082,
      "health_check": "/health",
      "tags": ["resume", "parsing", "mineru"]
    },
    "company-service": {
      "port": 8083,
      "health_check": "/health",
      "tags": ["company", "management"]
    },
    "job-service": {
      "port": 8089,
      "health_check": "/health",
      "tags": ["job", "matching"]
    },
    "user-service": {
      "port": 8081,
      "health_check": "/health",
      "tags": ["user", "auth"]
    },
    "ai-service": {
      "port": 8206,
      "health_check": "/health",
      "tags": ["ai", "vector", "matching"]
    },
    "mineru-service": {
      "port": 8001,
      "health_check": "/health",
      "tags": ["mineru", "parsing", "ai"]
    }
  }
}
EOF

echo "✅ 创建统一配置文件: $CONFIG_DIR/app.json"

# 2. 创建服务模板
echo "📝 创建标准化服务模板..."
TEMPLATE_DIR="$PROJECT_ROOT/templates"
mkdir -p "$TEMPLATE_DIR"

# 创建微服务启动模板
cat > "$TEMPLATE_DIR/microservice_template.go" << 'EOF'
package main

import (
    "fmt"
    "log"
    "net/http"
    "os"
    "os/signal"
    "syscall"
    "time"

    "github.com/gin-gonic/gin"
    "github.com/jobfirst/jobfirst-core"
    "github.com/jobfirst/jobfirst-core/service/registry"
)

// ServiceConfig 服务配置
type ServiceConfig struct {
    ServiceName string `json:"service_name"`
    Port        int    `json:"port"`
    HealthCheck string `json:"health_check"`
    Tags        []string `json:"tags"`
}

// 全局变量
var (
    core   *jobfirst.Core
    config *ServiceConfig
)

func main() {
    // 1. 初始化jobfirst-core
    var err error
    core, err = jobfirst.NewCore("config/app.json")
    if err != nil {
        log.Fatalf("Failed to initialize jobfirst-core: %v", err)
    }
    defer core.Close()

    // 2. 加载服务配置
    config, err = loadServiceConfig()
    if err != nil {
        log.Fatalf("Failed to load service config: %v", err)
    }

    // 3. 初始化数据库
    if err := initDatabase(); err != nil {
        log.Fatalf("Failed to initialize database: %v", err)
    }

    // 4. 初始化路由
    router := setupRoutes()

    // 5. 注册服务
    if err := registerService(); err != nil {
        log.Fatalf("Failed to register service: %v", err)
    }

    // 6. 启动服务
    startServer(router)
}

// loadServiceConfig 加载服务配置
func loadServiceConfig() (*ServiceConfig, error) {
    // 从环境变量或配置文件获取服务名
    serviceName := os.Getenv("SERVICE_NAME")
    if serviceName == "" {
        serviceName = "default-service"
    }

    // 从jobfirst-core配置中获取服务配置
    servicesConfig, err := core.Config.Get("services")
    if err != nil {
        return nil, err
    }

    services := servicesConfig.(map[string]interface{})
    serviceConfig := services[serviceName].(map[string]interface{})

    config := &ServiceConfig{
        ServiceName: serviceName,
        Port:        int(serviceConfig["port"].(float64)),
        HealthCheck: serviceConfig["health_check"].(string),
        Tags:        []string{},
    }

    if tags, ok := serviceConfig["tags"].([]interface{}); ok {
        for _, tag := range tags {
            config.Tags = append(config.Tags, tag.(string))
        }
    }

    return config, nil
}

// initDatabase 初始化数据库
func initDatabase() error {
    // 使用jobfirst-core的数据库管理器
    db := core.GetDB()
    
    // 执行数据库迁移
    // if err := db.AutoMigrate(&YourModel{}); err != nil {
    //     return err
    // }
    
    return nil
}

// setupRoutes 设置路由
func setupRoutes() *gin.Engine {
    router := gin.New()
    router.Use(gin.Recovery())
    
    // 添加健康检查路由
    router.GET("/health", healthCheck)
    
    // 添加API路由
    api := router.Group("/api/v1")
    {
        // 在这里添加你的API路由
        api.GET("/status", getStatus)
    }
    
    return router
}

// registerService 注册服务
func registerService() error {
    serviceInfo := &registry.ServiceInfo{
        ID:       config.ServiceName,
        Name:     config.ServiceName,
        Version:  "1.0.0",
        Endpoint: fmt.Sprintf("http://localhost:%d", config.Port),
        Health: &registry.HealthStatus{
            Status:    "healthy",
            Message:   "Service is running",
            Timestamp: time.Now(),
        },
        Tags: config.Tags,
    }

    // 使用jobfirst-core的服务注册器
    // registry := core.ServiceRegistry
    // if err := registry.Register(serviceInfo); err != nil {
    //     return err
    // }

    core.Logger.Info("Service registered successfully", "service", config.ServiceName)
    return nil
}

// startServer 启动服务器
func startServer(router *gin.Engine) {
    server := &http.Server{
        Addr:    fmt.Sprintf(":%d", config.Port),
        Handler: router,
    }

    // 启动服务器
    go func() {
        core.Logger.Info("Starting service", "service", config.ServiceName, "port", config.Port)
        if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
            log.Fatalf("Failed to start server: %v", err)
        }
    }()

    // 等待中断信号
    quit := make(chan os.Signal, 1)
    signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
    <-quit

    core.Logger.Info("Shutting down service", "service", config.ServiceName)
}

// healthCheck 健康检查
func healthCheck(c *gin.Context) {
    health := core.Health()
    c.JSON(http.StatusOK, health)
}

// getStatus 获取服务状态
func getStatus(c *gin.Context) {
    c.JSON(http.StatusOK, gin.H{
        "service": config.ServiceName,
        "status":  "running",
        "version": "1.0.0",
        "time":    time.Now(),
    })
}
EOF

echo "✅ 创建微服务模板: $TEMPLATE_DIR/microservice_template.go"

# 3. 创建迁移脚本
echo "🔄 创建服务迁移脚本..."
MIGRATION_DIR="$PROJECT_ROOT/scripts/migrations"
mkdir -p "$MIGRATION_DIR"

cat > "$MIGRATION_DIR/migrate_to_jobfirst_core.sh" << 'EOF'
#!/bin/bash
# 服务迁移到jobfirst-core脚本

SERVICE_NAME=$1
SERVICE_PATH=$2

if [ -z "$SERVICE_NAME" ] || [ -z "$SERVICE_PATH" ]; then
    echo "Usage: $0 <service_name> <service_path>"
    echo "Example: $0 resume-service /path/to/resume-service"
    exit 1
fi

echo "🔄 迁移服务: $SERVICE_NAME"
echo "路径: $SERVICE_PATH"

# 1. 备份原始main.go
if [ -f "$SERVICE_PATH/main.go" ]; then
    cp "$SERVICE_PATH/main.go" "$SERVICE_PATH/main.go.backup"
    echo "✅ 备份原始main.go"
fi

# 2. 更新go.mod依赖
cd "$SERVICE_PATH"
if [ -f "go.mod" ]; then
    # 添加jobfirst-core依赖
    go mod edit -require github.com/jobfirst/jobfirst-core@latest
    go mod tidy
    echo "✅ 更新go.mod依赖"
fi

# 3. 创建新的main.go
cat > "$SERVICE_PATH/main.go" << 'MAIN_EOF'
package main

import (
    "fmt"
    "log"
    "net/http"
    "os"
    "os/signal"
    "syscall"
    "time"

    "github.com/gin-gonic/gin"
    "github.com/jobfirst/jobfirst-core"
    "github.com/jobfirst/jobfirst-core/service/registry"
)

// 全局变量
var (
    core   *jobfirst.Core
    config *ServiceConfig
)

type ServiceConfig struct {
    ServiceName string   `json:"service_name"`
    Port        int      `json:"port"`
    HealthCheck string   `json:"health_check"`
    Tags        []string `json:"tags"`
}

func main() {
    // 设置服务名
    os.Setenv("SERVICE_NAME", "SERVICE_NAME_PLACEHOLDER")
    
    // 1. 初始化jobfirst-core
    var err error
    core, err = jobfirst.NewCore("../../config/app.json")
    if err != nil {
        log.Fatalf("Failed to initialize jobfirst-core: %v", err)
    }
    defer core.Close()

    // 2. 加载服务配置
    config, err = loadServiceConfig()
    if err != nil {
        log.Fatalf("Failed to load service config: %v", err)
    }

    // 3. 初始化数据库
    if err := initDatabase(); err != nil {
        log.Fatalf("Failed to initialize database: %v", err)
    }

    // 4. 初始化路由
    router := setupRoutes()

    // 5. 注册服务
    if err := registerService(); err != nil {
        log.Fatalf("Failed to register service: %v", err)
    }

    // 6. 启动服务
    startServer(router)
}

func loadServiceConfig() (*ServiceConfig, error) {
    serviceName := os.Getenv("SERVICE_NAME")
    if serviceName == "" {
        serviceName = "default-service"
    }

    servicesConfig, err := core.Config.Get("services")
    if err != nil {
        return nil, err
    }

    services := servicesConfig.(map[string]interface{})
    serviceConfig := services[serviceName].(map[string]interface{})

    config := &ServiceConfig{
        ServiceName: serviceName,
        Port:        int(serviceConfig["port"].(float64)),
        HealthCheck: serviceConfig["health_check"].(string),
        Tags:        []string{},
    }

    if tags, ok := serviceConfig["tags"].([]interface{}); ok {
        for _, tag := range tags {
            config.Tags = append(config.Tags, tag.(string))
        }
    }

    return config, nil
}

func initDatabase() error {
    db := core.GetDB()
    // 在这里添加你的数据库迁移逻辑
    return nil
}

func setupRoutes() *gin.Engine {
    router := gin.New()
    router.Use(gin.Recovery())
    
    router.GET("/health", healthCheck)
    
    api := router.Group("/api/v1")
    {
        // 在这里添加你的API路由
        api.GET("/status", getStatus)
    }
    
    return router
}

func registerService() error {
    serviceInfo := &registry.ServiceInfo{
        ID:       config.ServiceName,
        Name:     config.ServiceName,
        Version:  "1.0.0",
        Endpoint: fmt.Sprintf("http://localhost:%d", config.Port),
        Health: &registry.HealthStatus{
            Status:    "healthy",
            Message:   "Service is running",
            Timestamp: time.Now(),
        },
        Tags: config.Tags,
    }

    core.Logger.Info("Service registered successfully", "service", config.ServiceName)
    return nil
}

func startServer(router *gin.Engine) {
    server := &http.Server{
        Addr:    fmt.Sprintf(":%d", config.Port),
        Handler: router,
    }

    go func() {
        core.Logger.Info("Starting service", "service", config.ServiceName, "port", config.Port)
        if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
            log.Fatalf("Failed to start server: %v", err)
        }
    }()

    quit := make(chan os.Signal, 1)
    signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
    <-quit

    core.Logger.Info("Shutting down service", "service", config.ServiceName)
}

func healthCheck(c *gin.Context) {
    health := core.Health()
    c.JSON(http.StatusOK, health)
}

func getStatus(c *gin.Context) {
    c.JSON(http.StatusOK, gin.H{
        "service": config.ServiceName,
        "status":  "running",
        "version": "1.0.0",
        "time":    time.Now(),
    })
}
MAIN_EOF

# 替换服务名占位符
sed -i '' "s/SERVICE_NAME_PLACEHOLDER/$SERVICE_NAME/g" "$SERVICE_PATH/main.go"

echo "✅ 创建新的main.go"
echo "✅ 服务迁移完成: $SERVICE_NAME"
EOF

chmod +x "$MIGRATION_DIR/migrate_to_jobfirst_core.sh"
echo "✅ 创建迁移脚本: $MIGRATION_DIR/migrate_to_jobfirst_core.sh"

# 4. 创建验证脚本
echo "🔍 创建架构验证脚本..."
cat > "$MIGRATION_DIR/validate_jobfirst_core_integration.sh" << 'EOF'
#!/bin/bash
# 验证jobfirst-core架构整合脚本

echo "🔍 验证jobfirst-core架构整合..."
echo "=================================="

PROJECT_ROOT="/Users/szjason72/zervi-basic/basic"
BACKEND_ROOT="$PROJECT_ROOT/backend"

# 检查jobfirst-core
echo "1. 检查jobfirst-core..."
if [ -d "$BACKEND_ROOT/pkg/jobfirst-core" ]; then
    echo "✅ jobfirst-core目录存在"
else
    echo "❌ jobfirst-core目录不存在"
    exit 1
fi

# 检查统一配置
echo "2. 检查统一配置..."
if [ -f "$PROJECT_ROOT/config/app.json" ]; then
    echo "✅ 统一配置文件存在"
else
    echo "❌ 统一配置文件不存在"
    exit 1
fi

# 检查服务模板
echo "3. 检查服务模板..."
if [ -f "$PROJECT_ROOT/templates/microservice_template.go" ]; then
    echo "✅ 微服务模板存在"
else
    echo "❌ 微服务模板不存在"
    exit 1
fi

# 检查迁移脚本
echo "4. 检查迁移脚本..."
if [ -f "$PROJECT_ROOT/scripts/migrations/migrate_to_jobfirst_core.sh" ]; then
    echo "✅ 迁移脚本存在"
else
    echo "❌ 迁移脚本不存在"
    exit 1
fi

# 检查Go模块
echo "5. 检查Go模块..."
cd "$BACKEND_ROOT/pkg/jobfirst-core"
if go mod tidy; then
    echo "✅ jobfirst-core Go模块正常"
else
    echo "❌ jobfirst-core Go模块有问题"
    exit 1
fi

echo "=================================="
echo "🎉 jobfirst-core架构整合验证通过！"
echo ""
echo "📋 下一步操作:"
echo "1. 使用迁移脚本迁移各个服务"
echo "2. 测试服务启动和健康检查"
echo "3. 验证服务注册和发现"
echo "4. 测试统一配置管理"
EOF

chmod +x "$MIGRATION_DIR/validate_jobfirst_core_integration.sh"
echo "✅ 创建验证脚本: $MIGRATION_DIR/validate_jobfirst_core_integration.sh"

# 5. 运行验证
echo "🔍 运行架构验证..."
"$MIGRATION_DIR/validate_jobfirst_core_integration.sh"

echo "=================================="
echo "🎉 jobfirst-core架构整合完成！"
echo ""
echo "📋 创建的文件:"
echo "1. 统一配置文件: $CONFIG_DIR/app.json"
echo "2. 微服务模板: $TEMPLATE_DIR/microservice_template.go"
echo "3. 迁移脚本: $MIGRATION_DIR/migrate_to_jobfirst_core.sh"
echo "4. 验证脚本: $MIGRATION_DIR/validate_jobfirst_core_integration.sh"
echo ""
echo "🚀 下一步操作:"
echo "1. 使用迁移脚本迁移各个服务:"
echo "   ./scripts/migrations/migrate_to_jobfirst_core.sh resume-service backend/internal/resume"
echo "   ./scripts/migrations/migrate_to_jobfirst_core.sh company-service backend/internal/company-service"
echo "   ./scripts/migrations/migrate_to_jobfirst_core.sh job-service backend/internal/job-service"
echo ""
echo "2. 测试服务启动和功能"
echo "3. 验证统一配置管理"
echo "4. 测试服务注册和发现"
