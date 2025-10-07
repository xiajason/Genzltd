watching# JobFirst Web端联调数据库开发环境指南

## 🎯 概述

本指南提供了完整的Web端联调数据库开发环境搭建和使用方案，支持热加载、实时调试和端到端测试。

## 🏗️ 架构概览

```
┌─────────────────────────────────────────────────────────────┐
│                    Web端开发环境架构                        │
├─────────────────────────────────────────────────────────────┤
│  前端 (Taro H5)                                           │
│  ├── 端口: 10086                                         │
│  ├── 热重载: Taro HMR                                    │
│  └── 调试工具: 内置开发工具页面                           │
├─────────────────────────────────────────────────────────────┤
│  微服务 (热加载模式)                                       │
│  ├── API Gateway (8080) - air热加载                      │
│  ├── User Service (8081) - air热加载                     │
│  ├── Resume Service (8082) - air热加载                   │
│  └── AI Service (8206) - Sanic热加载                     │
├─────────────────────────────────────────────────────────────┤
│  数据库服务                                                │
│  ├── MySQL (3306) - 主数据库                             │
│  ├── PostgreSQL (5432) - 向量数据库                      │
│  ├── Redis (6379) - 缓存                                 │
│  └── Neo4j (7474) - 图数据库                             │
└─────────────────────────────────────────────────────────────┘
```

## 🚀 快速开始

### 1. 启动完整开发环境

```bash
# 启动所有服务 (数据库 + 后端 + 前端)
./scripts/web-dev-environment.sh start
```

### 2. 访问应用

- **前端应用**: http://localhost:10086
- **开发工具页面**: http://localhost:10086/pages/dev-tools/index
- **API Gateway**: http://localhost:8080
- **Neo4j Browser**: http://localhost:7474

### 3. 开发流程

1. **修改前端代码** → 自动热重载
2. **修改后端Go代码** → 自动重启服务
3. **修改AI Python代码** → 自动重启服务
4. **实时查看数据库变化**

## 🛠️ 开发工具

### 内置开发工具页面

访问 `http://localhost:10086/pages/dev-tools/index` 使用内置开发工具：

#### 功能特性
- **环境检查**: 显示当前环境配置
- **服务健康检查**: 检查所有微服务状态
- **API测试**: 测试各种API接口
- **数据库测试**: 测试数据库连接
- **模拟数据**: 生成测试数据
- **性能监控**: 监控应用性能
- **调试日志**: 实时查看操作日志

#### 快速测试
```javascript
// 在浏览器控制台中使用
devTools.checkEnvironment()           // 环境检查
devTools.testApiConnection()          // API连接测试
devTools.testUserLogin('admin', 'password')  // 用户登录测试
devTools.testResumeList()             // 简历列表测试
devTools.testAIChat('你好')           // AI聊天测试
devTools.testDatabaseConnection()     // 数据库连接测试
```

## 📋 服务管理

### 启动服务

```bash
# 启动完整环境
./scripts/web-dev-environment.sh start

# 仅启动后端服务
./scripts/web-dev-environment.sh backend

# 仅启动前端服务
./scripts/web-dev-environment.sh frontend
```

### 停止服务

```bash
# 停止所有服务
./scripts/web-dev-environment.sh stop

# 重启所有服务
./scripts/web-dev-environment.sh restart
```

### 查看状态

```bash
# 查看服务状态
./scripts/web-dev-environment.sh status

# 健康检查
./scripts/web-dev-environment.sh health
```

## 🔧 配置说明

### 环境配置

前端环境配置位于 `src/config/environment.ts`：

```typescript
// 开发环境配置
development: {
  api: {
    baseUrl: 'http://localhost:8080',
    version: 'v1',
    timeout: 10000,
    retryCount: 3
  },
  services: {
    apiGateway: { port: 8080, host: 'localhost' },
    userService: { port: 8081, host: 'localhost' },
    resumeService: { port: 8082, host: 'localhost' },
    aiService: { port: 8206, host: 'localhost' }
  },
  features: {
    aiEnabled: true,
    fileUploadEnabled: true,
    realTimeChatEnabled: true,
    analyticsEnabled: true
  },
  debug: {
    enabled: true,
    logLevel: 'debug',
    showApiLogs: true,
    showPerformanceLogs: true
  }
}
```

### 数据库配置

数据库配置位于 `backend/configs/config.yaml`：

```yaml
database:
  driver: "mysql"
  host: "localhost"
  port: "3306"
  name: "jobfirst"
  user: "root"
  password: ""

redis:
  host: "localhost"
  port: "6379"
  password: ""
  db: 0
```

## 🧪 测试指南

### API测试

使用开发工具页面进行API测试：

1. **环境检查**: 确保所有服务正常运行
2. **API连接测试**: 验证API Gateway连接
3. **用户登录测试**: 测试用户认证功能
4. **简历列表测试**: 测试简历管理功能
5. **AI聊天测试**: 测试AI助手功能

### 数据库测试

```bash
# 测试MySQL连接
mysql -u root -e "SELECT 1;"

# 测试PostgreSQL连接
psql -U szjason72 -d jobfirst_vector -c "SELECT 1;"

# 测试Redis连接
redis-cli ping
```

### 端到端测试

1. **启动开发环境**
2. **访问前端应用**
3. **使用开发工具进行功能测试**
4. **查看数据库数据变化**
5. **验证API响应**

## 🐛 调试技巧

### 前端调试

1. **浏览器开发者工具**
   - 网络面板查看API请求
   - 控制台查看日志输出
   - 性能面板监控性能

2. **内置调试工具**
   - 使用 `devTools.showDebugInfo()` 查看环境信息
   - 使用 `devTools.startPerformanceMonitoring()` 启动性能监控

3. **日志调试**
   - 开发环境下自动输出详细日志
   - 使用 `devTools.clearDebugLogs()` 清除日志

### 后端调试

1. **服务日志**
   - API Gateway: `backend/logs/basic-server.log`
   - User Service: `backend/logs/user-service.log`
   - Resume Service: `backend/logs/resume-service.log`
   - AI Service: `backend/logs/ai-service.log`

2. **热加载调试**
   - Go服务使用air自动重启
   - Python服务使用Sanic自动重启
   - 修改代码后自动生效

### 数据库调试

1. **MySQL调试**
   ```sql
   -- 查看用户表
   SELECT * FROM users;
   
   -- 查看简历表
   SELECT * FROM resumes;
   ```

2. **Redis调试**
   ```bash
   # 查看所有键
   redis-cli keys "*"
   
   # 查看特定键值
   redis-cli get "user:session:1"
   ```

## 📊 性能监控

### 前端性能

- **页面加载时间**: 自动监控并输出到控制台
- **API请求时间**: 在开发工具中显示
- **内存使用**: 通过浏览器开发者工具查看

### 后端性能

- **服务响应时间**: 通过健康检查接口监控
- **数据库查询时间**: 在服务日志中查看
- **内存使用**: 通过系统监控工具查看

## 🔄 热加载特性

### 前端热加载 (Taro HMR)

- **组件修改**: 自动刷新页面
- **样式修改**: 自动更新样式
- **TypeScript修改**: 自动编译并刷新

### 后端热加载

- **Go服务 (air)**: 代码修改自动重启
- **Python服务 (Sanic)**: 代码修改自动重启
- **配置文件修改**: 需要手动重启

## 🚨 常见问题

### 1. 端口冲突

```bash
# 检查端口占用
lsof -i :8080
lsof -i :10086

# 停止占用端口的进程
kill -9 <PID>
```

### 2. 数据库连接失败

```bash
# 检查数据库服务状态
brew services list | grep mysql
brew services list | grep postgresql
brew services list | grep redis

# 重启数据库服务
brew services restart mysql
brew services restart postgresql@14
brew services restart redis
```

### 3. 前端构建失败

```bash
# 清理并重新安装依赖
cd frontend-taro
rm -rf node_modules package-lock.json
npm install
npm run dev:h5
```

### 4. 后端服务启动失败

```bash
# 检查Go环境
go version
go mod tidy

# 检查Python环境
python3 --version
pip3 install -r requirements.txt
```

## 📚 开发建议

### 1. 开发流程

1. **启动开发环境**: `./scripts/web-dev-environment.sh start`
2. **访问开发工具**: http://localhost:10086/pages/dev-tools/index
3. **运行健康检查**: 确保所有服务正常
4. **开始开发**: 修改代码自动热加载
5. **实时测试**: 使用开发工具进行功能测试

### 2. 代码规范

- **前端**: 使用TypeScript，遵循ESLint规则
- **后端**: 使用Go，遵循gofmt规范
- **AI服务**: 使用Python，遵循PEP8规范

### 3. 测试策略

- **单元测试**: 每个功能模块编写单元测试
- **集成测试**: 使用开发工具进行API测试
- **端到端测试**: 完整业务流程测试

## 🎉 总结

Web端联调数据库开发环境提供了：

- ✅ **完整的微服务架构**
- ✅ **热加载开发体验**
- ✅ **内置调试工具**
- ✅ **实时数据库操作**
- ✅ **性能监控**
- ✅ **自动化测试**

通过这个开发环境，你可以高效地进行Web端开发，实时调试和测试，大大提升开发效率。

## 📞 支持

如果遇到问题，请：

1. 查看本文档的常见问题部分
2. 使用开发工具进行健康检查
3. 查看服务日志文件
4. 联系开发团队
