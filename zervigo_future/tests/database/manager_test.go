package database

import (
	"context"
	"testing"
	"time"

	"gorm.io/gorm/logger"
)

func TestNewManager(t *testing.T) {
	config := Config{
		MySQL: MySQLConfig{
			Host:        "localhost",
			Port:        3306,
			Username:    "root",
			Password:    "",
			Database:    "test",
			Charset:     "utf8mb4",
			MaxIdle:     10,
			MaxOpen:     100,
			MaxLifetime: time.Hour,
			LogLevel:    logger.Silent,
		},
		Redis: RedisConfig{
			Host:     "localhost",
			Port:     6379,
			Password: "",
			Database: 0,
			PoolSize: 10,
			MinIdle:  5,
		},
		PostgreSQL: PostgreSQLConfig{
			Host:        "localhost",
			Port:        5432,
			Username:    "postgres",
			Password:    "",
			Database:    "test",
			SSLMode:     "disable",
			MaxIdle:     10,
			MaxOpen:     100,
			MaxLifetime: time.Hour,
			LogLevel:    logger.Silent,
		},
		Neo4j: Neo4jConfig{
			URI:      "bolt://localhost:7687",
			Username: "neo4j",
			Password: "password",
			Database: "neo4j",
		},
	}

	// 测试创建管理器（可能会失败，因为数据库可能未运行）
	manager, err := NewManager(config)
	if err != nil {
		t.Logf("创建数据库管理器失败（预期，因为数据库可能未运行）: %v", err)
		return
	}

	// 测试健康检查
	health := manager.Health()
	t.Logf("数据库健康状态: %+v", health)

	// 测试关闭
	if err := manager.Close(); err != nil {
		t.Errorf("关闭数据库管理器失败: %v", err)
	}
}

func TestMySQLManager(t *testing.T) {
	config := MySQLConfig{
		Host:        "localhost",
		Port:        3306,
		Username:    "root",
		Password:    "",
		Database:    "test",
		Charset:     "utf8mb4",
		MaxIdle:     10,
		MaxOpen:     100,
		MaxLifetime: time.Hour,
		LogLevel:    logger.Silent,
	}

	manager, err := NewMySQLManager(config)
	if err != nil {
		t.Logf("创建MySQL管理器失败（预期，因为MySQL可能未运行）: %v", err)
		return
	}

	// 测试健康检查
	health := manager.Health()
	t.Logf("MySQL健康状态: %+v", health)

	// 测试关闭
	if err := manager.Close(); err != nil {
		t.Errorf("关闭MySQL管理器失败: %v", err)
	}
}

func TestRedisManager(t *testing.T) {
	config := RedisConfig{
		Host:     "localhost",
		Port:     6379,
		Password: "",
		Database: 0,
		PoolSize: 10,
		MinIdle:  5,
	}

	manager, err := NewRedisManager(config)
	if err != nil {
		t.Logf("创建Redis管理器失败（预期，因为Redis可能未运行）: %v", err)
		return
	}

	ctx := context.Background()

	// 测试基本操作
	if err := manager.Set(ctx, "test_key", "test_value", time.Minute); err != nil {
		t.Errorf("设置Redis键失败: %v", err)
	}

	value, err := manager.Get(ctx, "test_key")
	if err != nil {
		t.Errorf("获取Redis键失败: %v", err)
	}
	if value != "test_value" {
		t.Errorf("Redis键值不匹配，期望: test_value, 实际: %s", value)
	}

	// 测试健康检查
	health := manager.Health()
	t.Logf("Redis健康状态: %+v", health)

	// 测试关闭
	if err := manager.Close(); err != nil {
		t.Errorf("关闭Redis管理器失败: %v", err)
	}
}

func TestPostgreSQLManager(t *testing.T) {
	config := PostgreSQLConfig{
		Host:        "localhost",
		Port:        5432,
		Username:    "postgres",
		Password:    "",
		Database:    "test",
		SSLMode:     "disable",
		MaxIdle:     10,
		MaxOpen:     100,
		MaxLifetime: time.Hour,
		LogLevel:    logger.Silent,
	}

	manager, err := NewPostgreSQLManager(config)
	if err != nil {
		t.Logf("创建PostgreSQL管理器失败（预期，因为PostgreSQL可能未运行）: %v", err)
		return
	}

	// 测试健康检查
	health := manager.Health()
	t.Logf("PostgreSQL健康状态: %+v", health)

	// 测试关闭
	if err := manager.Close(); err != nil {
		t.Errorf("关闭PostgreSQL管理器失败: %v", err)
	}
}

func TestNeo4jManager(t *testing.T) {
	config := Neo4jConfig{
		URI:      "bolt://localhost:7687",
		Username: "neo4j",
		Password: "password",
		Database: "neo4j",
	}

	manager, err := NewNeo4jManager(config)
	if err != nil {
		t.Logf("创建Neo4j管理器失败（预期，因为Neo4j可能未运行）: %v", err)
		return
	}

	ctx := context.Background()

	// 测试基本查询
	records, err := manager.ExecuteQuery(ctx, "RETURN 1 as test", nil)
	if err != nil {
		t.Errorf("执行Neo4j查询失败: %v", err)
	}
	if len(records) == 0 {
		t.Error("Neo4j查询结果为空")
	}

	// 测试健康检查
	health := manager.Health()
	t.Logf("Neo4j健康状态: %+v", health)

	// 测试关闭
	if err := manager.Close(ctx); err != nil {
		t.Errorf("关闭Neo4j管理器失败: %v", err)
	}
}

func TestMultiDBTransaction(t *testing.T) {
	config := Config{
		MySQL: MySQLConfig{
			Host:        "localhost",
			Port:        3306,
			Username:    "root",
			Password:    "",
			Database:    "test",
			Charset:     "utf8mb4",
			MaxIdle:     10,
			MaxOpen:     100,
			MaxLifetime: time.Hour,
			LogLevel:    logger.Silent,
		},
		Redis: RedisConfig{
			Host:     "localhost",
			Port:     6379,
			Password: "",
			Database: 0,
			PoolSize: 10,
			MinIdle:  5,
		},
	}

	manager, err := NewManager(config)
	if err != nil {
		t.Logf("创建数据库管理器失败（预期，因为数据库可能未运行）: %v", err)
		return
	}

	// 测试多数据库事务
	err = manager.MultiDBTransaction(func(tx *MultiDBTransaction) error {
		// 这里可以执行跨数据库的操作
		// 例如：在MySQL中插入数据，在Redis中设置缓存
		return nil
	})

	if err != nil {
		t.Logf("多数据库事务失败（预期，因为数据库可能未运行）: %v", err)
	}

	// 测试关闭
	if err := manager.Close(); err != nil {
		t.Errorf("关闭数据库管理器失败: %v", err)
	}
}

// 基准测试
func BenchmarkMySQLManager(b *testing.B) {
	config := MySQLConfig{
		Host:        "localhost",
		Port:        3306,
		Username:    "root",
		Password:    "",
		Database:    "test",
		Charset:     "utf8mb4",
		MaxIdle:     10,
		MaxOpen:     100,
		MaxLifetime: time.Hour,
		LogLevel:    logger.Silent,
	}

	manager, err := NewMySQLManager(config)
	if err != nil {
		b.Skip("MySQL未运行，跳过基准测试")
	}
	defer manager.Close()

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		manager.Ping()
	}
}

func BenchmarkRedisManager(b *testing.B) {
	config := RedisConfig{
		Host:     "localhost",
		Port:     6379,
		Password: "",
		Database: 0,
		PoolSize: 10,
		MinIdle:  5,
	}

	manager, err := NewRedisManager(config)
	if err != nil {
		b.Skip("Redis未运行，跳过基准测试")
	}
	defer manager.Close()

	ctx := context.Background()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		manager.Ping(ctx)
	}
}
