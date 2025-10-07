# JobFirst 数据库统一 - 阶段四：微服务适配计划

## 📋 执行摘要

**执行阶段**: 阶段四 - 微服务适配  
**预计时间**: 4小时  
**执行人**: AI Assistant  
**目标**: 更新所有微服务和基础设施组件的数据库配置，适配统一的jobfirst数据库

## 🎯 适配范围

### 1. 微服务组件 (9个)
- [ ] **API Gateway** - 网关服务
- [ ] **User Service** - 用户服务
- [ ] **Resume Service** - 简历服务
- [ ] **Company Service** - 公司服务
- [ ] **Banner Service** - 轮播图服务
- [ ] **Template Service** - 模板服务
- [ ] **Notification Service** - 通知服务
- [ ] **Statistics Service** - 统计服务
- [ ] **AI Service** - AI服务

### 2. 基础设施组件 (4个)
- [ ] **Basic Server** - 基础服务器
- [ ] **Consul** - 服务发现
- [ ] **Redis** - 缓存服务
- [ ] **Database Connections** - 数据库连接

## 🔧 适配内容

### 2.1 数据库配置更新
- [ ] 更新数据库连接字符串
- [ ] 统一数据库名称为 `jobfirst`
- [ ] 更新表结构引用
- [ ] 调整连接池配置

### 2.2 模型定义更新
- [ ] 更新GORM模型定义
- [ ] 调整字段映射
- [ ] 更新索引定义
- [ ] 修正外键关系

### 2.3 查询语句更新
- [ ] 更新SQL查询语句
- [ ] 调整表名引用
- [ ] 更新JOIN语句
- [ ] 修正字段引用

### 2.4 事务处理更新
- [ ] 更新事务边界
- [ ] 调整锁机制
- [ ] 更新回滚逻辑
- [ ] 优化并发控制

## 📁 需要更新的文件

### 微服务配置文件
- [ ] `internal/resume/config.yaml`
- [ ] `internal/banner-service/main.go`
- [ ] `internal/company-service/main.go`
- [ ] `internal/template-service/main.go`
- [ ] `internal/notification-service/main.go`
- [ ] `internal/statistics-service/main.go`
- [ ] `internal/ai-service/` (Python服务)

### 基础设施配置文件
- [ ] `configs/config.yaml` (Basic Server)
- [ ] `pkg/config/config.go`
- [ ] `pkg/common/database/config.go`
- [ ] `pkg/shared/infrastructure/database_manager.go`
- [ ] `pkg/shared/infrastructure/init.go`

### 模型和仓库文件
- [ ] `internal/infrastructure/database/auth_repository.go`
- [ ] `internal/infrastructure/database/user_repository.go`
- [ ] `internal/domain/user/entity.go`
- [ ] `internal/domain/auth/entity.go`

## 🚀 执行步骤

### 步骤1: 基础设施组件适配 (1小时)
1. **更新Basic Server配置**
   - 修改 `configs/config.yaml`
   - 更新数据库连接配置
   - 调整连接池参数

2. **更新共享数据库配置**
   - 修改 `pkg/common/database/config.go`
   - 更新 `pkg/shared/infrastructure/database_manager.go`
   - 调整默认配置

3. **更新配置管理器**
   - 修改 `pkg/config/config.go`
   - 更新环境变量处理
   - 调整默认值

### 步骤2: 微服务适配 (2小时)
1. **Resume Service适配**
   - 更新 `internal/resume/config.yaml`
   - 修改数据库连接配置
   - 调整模型定义

2. **其他Go微服务适配**
   - Banner Service
   - Company Service
   - Template Service
   - Notification Service
   - Statistics Service

3. **AI Service适配**
   - 更新Python服务配置
   - 调整数据库连接
   - 修改API接口

### 步骤3: 模型和仓库更新 (1小时)
1. **更新实体模型**
   - 调整字段定义
   - 更新索引配置
   - 修正外键关系

2. **更新仓库实现**
   - 修改查询语句
   - 调整事务处理
   - 更新错误处理

3. **更新服务层**
   - 调整业务逻辑
   - 更新数据验证
   - 优化性能

## 🔍 验证检查点

### 配置验证
- [ ] 所有配置文件语法正确
- [ ] 数据库连接字符串有效
- [ ] 环境变量配置正确
- [ ] 连接池参数合理

### 代码验证
- [ ] 所有Go代码编译通过
- [ ] Python服务启动正常
- [ ] 模型定义正确
- [ ] 查询语句有效

### 功能验证
- [ ] 数据库连接成功
- [ ] 表结构访问正常
- [ ] 数据读写功能正常
- [ ] 事务处理正确

## 📊 预期结果

### 配置统一
- ✅ 所有服务使用统一的jobfirst数据库
- ✅ 数据库连接配置标准化
- ✅ 环境变量配置一致

### 功能保持
- ✅ 所有微服务功能正常
- ✅ 数据访问性能稳定
- ✅ 事务处理正确

### 系统稳定
- ✅ 服务启动正常
- ✅ 健康检查通过
- ✅ 监控指标正常

## 🚨 风险控制

### 回滚准备
- [ ] 备份所有配置文件
- [ ] 记录原始配置
- [ ] 准备回滚脚本
- [ ] 测试回滚流程

### 测试验证
- [ ] 单元测试通过
- [ ] 集成测试通过
- [ ] 端到端测试通过
- [ ] 性能测试通过

### 监控观察
- [ ] 服务启动监控
- [ ] 数据库连接监控
- [ ] 错误日志监控
- [ ] 性能指标监控

## 📝 执行记录

### 开始时间
- **计划开始**: 2025-09-10 21:30
- **实际开始**: ___

### 完成时间
- **预计完成**: ___
- **实际完成**: ___

### 问题记录
- **问题1**: ___
- **解决方案**: ___
- **问题2**: ___
- **解决方案**: ___

## 🎉 完成标准

- [ ] 所有微服务配置更新完成
- [ ] 所有基础设施组件配置更新完成
- [ ] 所有代码编译通过
- [ ] 所有服务启动正常
- [ ] 数据库连接测试通过
- [ ] 功能测试验证通过

---

**下一步**: 开始阶段五 - 测试验证
