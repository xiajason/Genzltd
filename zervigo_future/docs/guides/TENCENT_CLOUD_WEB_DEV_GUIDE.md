# 腾讯云Web端联调数据库开发环境入门指南

## 🚀 5分钟快速启动

### 1. 一键启动完整开发环境
```bash
# 使用zervigo工具检查系统状态
zervigo status

# 启动所有服务 (数据库 + 后端 + 前端)
zervigo deploy restart
```

### 2. 访问应用
- **🌐 前端应用**: http://101.33.251.158/
- **🛠️ API Gateway**: http://101.33.251.158/api/
- **🤖 AI Service**: http://101.33.251.158/ai/
- **📊 服务状态**: http://101.33.251.158/api/health

### 3. 验证环境
```bash
# 查看服务状态
zervigo status

# 健康检查
zervigo infrastructure status

# 测试AI服务
zervigo ai test

# 检查数据库状态
zervigo database status
```

## 🛠️ 开发工具使用

### 内置开发工具页面
访问 `http://101.33.251.158/` 进行：

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
- 修改Go代码 → 自动重启服务
- 修改Python AI服务代码 → 自动重启服务
- 修改配置文件 → 需要手动重启

### 实时调试
- 修改代码后立即在浏览器中查看效果
- 使用开发工具页面实时测试API
- 查看浏览器控制台获取详细日志

## 📊 服务架构

```
┌─────────────────────────────────────────────────────────────┐
│                   腾讯云Web端开发环境架构                    │
├─────────────────────────────────────────────────────────────┤
│  前端 (Taro H5) - 端口 80 (Nginx)                        │
│  ├── 静态文件: /var/www/html/                             │
│  ├── 应用入口: index.html                                 │
│  └── 调试工具: 浏览器控制台 devTools                     │
├─────────────────────────────────────────────────────────────┤
│  Nginx反向代理                                             │
│  ├── /api/ → API Gateway (8080)                          │
│  ├── /ai/ → AI Service (8206)                            │
│  └── / → 静态文件服务                                     │
├─────────────────────────────────────────────────────────────┤
│  微服务集群 (热加载模式)                                    │
│  ├── API Gateway (8080) - air热加载                      │
│  ├── User Service (8081) - air热加载                     │
│  ├── Resume Service (8082) - air热加载                   │
│  ├── Company Service (8083) - air热加载                  │
│  ├── Notification Service (8084) - air热加载             │
│  ├── Banner Service (8085) - air热加载                   │
│  ├── Statistics Service (8086) - air热加载               │
│  ├── Template Service (8087) - air热加载                 │
│  └── AI Service (8206) - Sanic热加载                     │
├─────────────────────────────────────────────────────────────┤
│  数据库服务                                                │
│  ├── MySQL (3306) - 主数据库                             │
│  ├── PostgreSQL (5432) - 向量数据库                      │
│  ├── Redis (6379) - 缓存                                 │
│  └── Neo4j (7474) - 图数据库                             │
├─────────────────────────────────────────────────────────────┤
│  基础设施服务                                              │
│  ├── Consul (8500) - 服务发现                            │
│  └── Nginx (80) - Web服务器                              │
└─────────────────────────────────────────────────────────────┘
```

## 🎯 开发流程

### 1. 启动开发环境
```bash
# 检查系统状态
zervigo status

# 启动所有服务
zervigo deploy restart
```

### 2. 访问开发工具
打开 http://101.33.251.158/

### 3. 运行健康检查
```bash
# 检查所有服务状态
zervigo infrastructure status

# 测试API连接
curl http://101.33.251.158/api/health

# 测试AI服务
curl http://101.33.251.158/ai/health
```

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
# 查看系统整体状态
zervigo status

# 启动完整环境
zervigo deploy restart

# 仅启动基础设施
zervigo infrastructure restart

# 查看服务状态
zervigo infrastructure status

# 健康检查
zervigo infrastructure status

# 停止所有服务
zervigo deploy stop

# 重启所有服务
zervigo deploy restart
```

### AI服务管理
```bash
# 查看AI服务状态
zervigo ai status

# 测试AI服务功能
zervigo ai test

# 配置AI服务
zervigo ai configure openai sk-your-api-key https://api.openai.com/v1 gpt-3.5-turbo

# 重启AI服务
zervigo ai restart
```

### 数据库管理
```bash
# 查看数据库状态
zervigo database status

# 初始化所有数据库
zervigo database init-all

# 初始化MySQL数据库
zervigo database init-mysql

# 初始化PostgreSQL数据库
zervigo database init-postgresql

# 初始化Redis数据库
zervigo database init-redis
```

### 用户和权限管理
```bash
# 查看用户列表
zervigo users list

# 查看角色列表
zervigo roles list

# 查看项目成员
zervigo members list

# 检查系统权限
zervigo permissions check
```

### 测试命令
```bash
# 运行完整测试
zervigo monitor

# 查看帮助
zervigo --help
```

## 🐛 常见问题

### 1. 端口冲突
```bash
# 检查端口占用
ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158 "netstat -tlnp | grep -E ':80|:8080|:8206'"

# 停止占用端口的进程
ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158 "sudo pkill -f 'nginx'"
```

### 2. 数据库连接失败
```bash
# 检查数据库服务状态
zervigo database status

# 重启数据库服务
zervigo infrastructure restart

# 初始化数据库
zervigo database init-all
```

### 3. 前端页面无法访问
```bash
# 检查Nginx状态
ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158 "sudo systemctl status nginx"

# 重启Nginx
ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158 "sudo systemctl restart nginx"

# 检查前端文件
ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158 "ls -la /var/www/html/"
```

### 4. API代理失败
```bash
# 检查Nginx配置
ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158 "sudo nginx -t"

# 重新加载Nginx配置
ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158 "sudo systemctl reload nginx"

# 测试API连接
curl http://101.33.251.158/api/health
```

### 5. 后端服务启动失败
```bash
# 检查Go环境
ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158 "go version"

# 检查Python环境
ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158 "python3 --version"

# 重启所有服务
zervigo deploy restart
```

### 6. AI服务问题
```bash
# 检查AI服务状态
zervigo ai status

# 测试AI服务功能
zervigo ai test

# 重启AI服务
zervigo ai restart

# 检查AI服务配置
ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158 "cat /opt/jobfirst/ai-service/.env"
```

## 📚 API接口文档

### 基础API
```bash
# 健康检查
GET http://101.33.251.158/api/health

# 服务状态
GET http://101.33.251.158/api/api/v1/status

# 用户服务健康检查
GET http://101.33.251.158/api/api/v1/users/health

# 简历服务健康检查
GET http://101.33.251.158/api/api/v1/resumes/health
```

### AI服务API
```bash
# AI服务健康检查
GET http://101.33.251.158/ai/health

# AI聊天功能
POST http://101.33.251.158/ai/api/v1/ai/chat

# 简历分析
POST http://101.33.251.158/ai/api/v1/analyze/resume

# 向量搜索
POST http://101.33.251.158/ai/api/v1/vectors/search
```

### 数据库API
```bash
# 简历列表
GET http://101.33.251.158/api/api/v2/resumes

# 创建简历
POST http://101.33.251.158/api/api/v2/resumes

# 获取简历详情
GET http://101.33.251.158/api/api/v2/resumes/:id

# 获取技能列表
GET http://101.33.251.158/api/api/v2/standard/skills

# 获取公司列表
GET http://101.33.251.158/api/api/v2/standard/companies
```

## 🔐 安全配置

### SSH访问
```bash
# SSH密钥文件
~/.ssh/basic.pem

# 服务器信息
SERVER_IP="101.33.251.158"
SERVER_USER="ubuntu"
```

### 权限管理
```bash
# 查看用户权限
zervigo permissions check

# 检查SSH访问控制
zervigo access ssh

# 验证访问权限
zervigo permissions validate <用户名> <资源> <操作>
```

## 📈 监控和日志

### 系统监控
```bash
# 实时监控
zervigo monitor

# 查看告警信息
zervigo alerts

# 查看系统日志
zervigo logs
```

### 服务日志
```bash
# 查看API Gateway日志
ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158 "tail -f /opt/jobfirst/logs/basic-server.log"

# 查看AI服务日志
ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158 "tail -f /opt/jobfirst/ai-service/ai-service.log"

# 查看Nginx日志
ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158 "sudo tail -f /var/log/nginx/access.log"
```

## 🚀 部署和更新

### 前端部署
```bash
# 构建前端应用
cd /path/to/frontend
npm run build:h5

# 部署到服务器
scp -i ~/.ssh/basic.pem -r dist/* ubuntu@101.33.251.158:/var/www/html/
```

### 后端部署
```bash
# 使用zervigo工具部署
zervigo deploy restart

# 手动部署
ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158 "cd /opt/jobfirst && ./start-services.sh"
```

### 数据库更新
```bash
# 创建备份
zervigo backup create

# 更新数据库
zervigo database init-all

# 恢复备份
zervigo backup restore
```

## 📞 技术支持

### 联系方式
- **技术支持**: admin@jobfirst.com
- **紧急联系**: 24/7 技术支持热线
- **文档更新**: 定期更新使用指南

### 相关文档
- [超级管理员控制指南](./SUPER_ADMIN_CONTROL_GUIDE.md)
- [腾讯云验证最终报告](./TENCENT_CLOUD_VERIFICATION_FINAL_REPORT.md)
- [系统架构文档](./PRODUCTION_ARCHITECTURE.md)

## 🔄 更新日志

### v1.0.0 (2025-09-09) - 腾讯云适配版本
- **新增**: 腾讯云服务器环境配置
- **新增**: Nginx反向代理配置
- **新增**: 完整的API代理设置
- **新增**: AI服务代理配置
- **优化**: 前端静态文件部署
- **优化**: 服务健康检查
- **完善**: 完整的开发环境文档

---

**文档版本**: v1.0.0  
**最后更新**: 2025年9月9日  
**维护人员**: AI Assistant  
**适用环境**: 腾讯云轻量应用服务器 (101.33.251.158)
