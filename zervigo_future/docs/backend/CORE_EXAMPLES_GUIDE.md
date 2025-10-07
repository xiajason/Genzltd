# JobFirst Core Package Examples

这个目录包含了 `JobFirst Core Package` 的核心功能演示和使用示例。

## 示例说明

### 1. `refactored_main.go` - 完整应用示例
**用途**: 展示如何使用重构后的 JobFirst Core Package 构建完整的应用程序

**功能演示**:
- 核心包初始化
- 路由设置和中间件配置
- 认证和授权
- 数据库连接管理
- 错误处理

**使用场景**: 新项目启动的参考模板

### 2. `config-logging-integration/` - 配置和日志集成测试
**用途**: 验证动态配置管理和统一日志系统的集成功能

**功能演示**:
- 配置热更新
- 配置版本管理和回滚
- 结构化日志记录
- 多级别日志输出
- 配置验证

**使用场景**: 验证配置和日志系统的稳定性

### 3. `microservices-integration/` - 微服务集成测试
**用途**: 验证服务注册中心在实际微服务环境中的工作效果

**功能演示**:
- 服务注册和发现
- 健康检查机制
- 负载均衡
- 服务状态监控
- 故障恢复

**使用场景**: 微服务架构的集成测试

### 4. `service-registry/` - 服务注册中心基础示例
**用途**: 展示服务注册中心的基本用法

**功能演示**:
- 服务注册
- 服务发现
- 健康检查
- 服务选择

**使用场景**: 学习服务管理的基础功能

## 运行示例

```bash
# 运行完整应用示例
go run examples/refactored_main.go

# 运行配置和日志集成测试
go run examples/config-logging-integration/main.go

# 运行微服务集成测试
go run examples/microservices-integration/main.go

# 运行服务注册中心示例
go run examples/service-registry/main.go
```

## 注意事项

1. 运行前确保已安装所有依赖
2. 某些示例需要特定的配置文件
3. 微服务集成测试会启动多个模拟服务
4. 测试完成后会自动清理资源

## 开发指南

这些示例不仅用于演示，也是开发新功能时的测试工具。每个示例都包含了详细的注释和错误处理，可以作为开发参考。
