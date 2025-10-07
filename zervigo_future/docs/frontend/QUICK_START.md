# 腾讯云Web端联调数据库开发环境快速入门

## 🚀 5分钟快速启动

### 1. 腾讯云服务器环境
```bash
# 服务器地址: 101.33.251.158
# 使用SSH密钥连接
ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158
```

### 2. 访问应用
- **🌐 前端应用**: http://101.33.251.158/
- **🛠️ 开发工具**: http://101.33.251.158/pages/dev-tools/index
- **🔗 API Gateway**: http://101.33.251.158/api/api/v1/
- **🤖 AI Service**: http://101.33.251.158/ai/

### 3. 验证环境
```bash
# 检查服务状态
ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158 "ps aux | grep -E '(main|service|air)' | grep -v grep"

# 健康检查
ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158 "curl -s http://localhost:8080/health"

# 测试登录API
ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158 "curl -s -X POST http://localhost:8080/api/v1/auth/login -H 'Content-Type: application/json' -d '{\"email\":\"jobfirst@jobfirst.com\",\"password\":\"password\"}'"
```

## 🛠️ 开发工具使用

### 内置开发工具页面
访问 `http://101.33.251.158/pages/dev-tools/index` 进行：

1. **环境检查** - 查看当前环境配置
2. **服务测试** - 测试所有微服务状态
3. **API测试** - 测试用户登录、简历列表、AI聊天
4. **数据库测试** - 测试数据库连接
5. **模拟数据** - 生成测试数据

### 浏览器控制台工具
打开浏览器开发者工具，在控制台中使用：

```javascript
// 环境检查
devTools.checkEnvironment()

// API连接测试
devTools.testApiConnection()

// 用户登录测试
devTools.testUserLogin('admin', 'password')

// 简历列表测试
devTools.testResumeList()

// AI聊天测试
devTools.testAIChat('你好')

// 数据库连接测试
devTools.testDatabaseConnection()

// 显示调试信息
devTools.showDebugInfo()

// 生成模拟数据
devTools.generateMockData('user')
```

## 🔥 热加载开发体验

### 前端热加载
- 修改 `src/pages/` 下的React组件 → 自动刷新页面
- 修改 `src/components/` 下的组件 → 自动刷新页面
- 修改 `src/styles/` 下的样式 → 自动更新样式

### 后端热加载
- 修改Go代码 → air自动重启服务 (API Gateway已配置)
- 修改Python AI服务代码 → 自动重启服务
- 修改配置文件 → 需要手动重启

### 实时调试
- 修改代码后立即在浏览器中查看效果
- 使用开发工具页面实时测试API
- 查看浏览器控制台获取详细日志

## 📊 服务架构

```
┌─────────────────────────────────────────────────────────────┐
│                腾讯云Web端开发环境架构                      │
├─────────────────────────────────────────────────────────────┤
│  前端 (Taro H5) - http://101.33.251.158/                  │
│  ├── 热重载: Taro HMR                                    │
│  ├── 开发工具: /pages/dev-tools/index                    │
│  └── 调试工具: 浏览器控制台 devTools                     │
├─────────────────────────────────────────────────────────────┤
│  微服务 (腾讯云服务器)                                     │
│  ├── API Gateway (8080) - air热加载 ✅                   │
│  ├── User Service (8081) - 直接运行                      │
│  ├── Resume Service (8082) - 直接运行                    │
│  ├── AI Service (8206) - Python Sanic                    │
│  ├── Company Service - 直接运行                          │
│  ├── Banner Service - 直接运行                           │
│  ├── Notification Service - 直接运行                     │
│  ├── Statistics Service - 直接运行                       │
│  └── Template Service - 直接运行                         │
├─────────────────────────────────────────────────────────────┤
│  数据库服务 (腾讯云)                                       │
│  ├── MySQL (3306) - 主数据库                             │
│  ├── PostgreSQL (5432) - 向量数据库                      │
│  ├── Redis (6379) - 缓存                                 │
│  └── Neo4j (7474) - 图数据库                             │
├─────────────────────────────────────────────────────────────┤
│  反向代理 (Nginx)                                          │
│  ├── /api/ → localhost:8080                              │
│  ├── /ai/ → localhost:8206                               │
│  └── / → /var/www/html/                                  │
└─────────────────────────────────────────────────────────────┘
```

## 🎯 开发流程

### 1. 连接腾讯云服务器
```bash
ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158
```

### 2. 访问开发工具
打开 http://101.33.251.158/pages/dev-tools/index

### 3. 运行健康检查
点击"运行所有测试"按钮，确保所有服务正常

### 4. 开始开发
- 修改前端代码 → 自动刷新
- 修改后端代码 → 自动重启
- 使用开发工具测试功能

### 5. 实时调试
- 查看浏览器控制台日志
- 使用开发工具页面测试API
- 实时查看数据库变化

## 🔧 常用命令

### 服务管理
```bash
# 连接服务器
ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158

# 查看服务状态
ps aux | grep -E '(main|service|air)' | grep -v grep

# 健康检查
curl -s http://localhost:8080/health

# 重启API Gateway (air热加载)
cd /opt/jobfirst/basic-server && pkill -f air && air &

# 重启User Service
cd /opt/jobfirst/user-service && pkill -f main && nohup ./main > user-service.log 2>&1 &

# 重启AI Service
cd /opt/jobfirst/ai-service && pkill -f ai_service.py && nohup python3 ai_service.py > ai-service.log 2>&1 &
```

### 测试命令
```bash
# 测试登录API
curl -s -X POST http://101.33.251.158/api/api/v1/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"jobfirst@jobfirst.com","password":"password"}'

# 测试前端页面
curl -s http://101.33.251.158/ | head -5

# 测试AI服务
curl -s http://101.33.251.158/ai/health
```

## 🐛 常见问题

### 1. 服务连接问题
```bash
# 检查服务状态
ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158 "ps aux | grep -E '(main|service|air)' | grep -v grep"

# 检查端口占用
ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158 "netstat -tlnp | grep -E ':(8080|8081|8082|8206)'"

# 重启服务
ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158 "pkill -f air && cd /opt/jobfirst/basic-server && air &"
```

### 2. 数据库连接失败
```bash
# 检查数据库服务状态
ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158 "sudo systemctl status mysql postgresql redis"

# 重启数据库服务
ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158 "sudo systemctl restart mysql postgresql redis"
```

### 3. API Gateway热加载问题
```bash
# 检查air进程
ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158 "ps aux | grep air | grep -v grep"

# 重启air热加载
ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158 "cd /opt/jobfirst/basic-server && pkill -f air && export PATH=/usr/local/go/bin:$PATH && air &"

# 查看air日志
ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158 "tail -20 /opt/jobfirst/basic-server/air.log"
```

### 4. 登录API问题
```bash
# 测试登录API
ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158 "curl -s -X POST http://localhost:8080/api/v1/auth/login -H 'Content-Type: application/json' -d '{\"email\":\"jobfirst@jobfirst.com\",\"password\":\"password\"}'"

# 检查用户数据
ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158 "mysql -u jobfirst -p'jobfirst_prod_2024' -e 'SELECT username, email FROM users;'"
```

## 📚 更多资源

- **腾讯云部署指南**: `TENCENT_CLOUD_WEB_DEV_GUIDE.md`
- **超级管理员工具**: `SUPER_ADMIN_CONTROL_GUIDE.md`
- **项目README**: `README.md`
- **zervigo工具**: 本地Go工具，用于远程管理腾讯云服务器

## 🎉 开始开发

现在你已经了解了腾讯云Web端联调数据库开发环境的基本使用方法，可以开始高效的开发了！

1. 连接腾讯云服务器
2. 访问前端应用页面
3. 运行健康检查
4. 开始编码和测试

### 🔑 重要信息
- **服务器地址**: 101.33.251.158
- **SSH密钥**: ~/.ssh/basic.pem
- **API Gateway**: 已配置air热加载
- **统一登录端点**: `/api/api/v1/auth/login`

祝你开发愉快！🚀
