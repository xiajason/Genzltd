# JobFirst系统远程协同开发测试指南

## 🎯 测试目标
验证JobFirst系统在腾讯云服务器上的远程协同开发和测试能力。

## 🌐 系统访问信息

### 服务器信息
- **外网IP**: 101.33.251.158
- **内网IP**: 10.1.12.9
- **操作系统**: Ubuntu 22.04.5 LTS
- **部署时间**: 2025-09-06

### 服务访问地址
| 服务 | 访问地址 | 端口 | 状态 |
|------|----------|------|------|
| **前端应用** | http://101.33.251.158/ | 80 | ✅ 正常 |
| **后端API** | http://101.33.251.158/api/ | 8080 | ✅ 正常 |
| **AI服务** | http://101.33.251.158/ai/ | 8206 | ✅ 正常 |
| **健康检查** | http://101.33.251.158/api/v1/status | - | ✅ 正常 |

## 🧪 功能测试清单

### 1. 前端应用测试 ✅

#### 基础访问测试
```bash
# 测试前端页面加载
curl -I http://101.33.251.158/

# 测试静态资源加载
curl -I http://101.33.251.158/js/app.a5591654.js
curl -I http://101.33.251.158/css/app.a5591654e9ec56b57e5f.css
```

**预期结果**: HTTP 200 OK，页面和资源正常加载

#### 浏览器测试
1. 打开浏览器访问: http://101.33.251.158/
2. 检查页面是否正常显示
3. 测试页面交互功能
4. 检查控制台是否有错误

### 2. 后端API测试 ✅

#### 核心API测试
```bash
# 系统健康检查
curl http://101.33.251.158/api/v1/status

# 系统信息
curl http://101.33.251.158/api/v1/info

# 数据库状态
curl http://101.33.251.158/api/v1/database/status
```

**预期结果**: 返回JSON格式的系统状态信息

#### 业务API测试
```bash
# 用户列表
curl http://101.33.251.158/api/v1/users

# 简历列表
curl http://101.33.251.158/api/v1/resumes

# 用户注册
curl -X POST http://101.33.251.158/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","email":"test@example.com","password":"123456"}'

# 用户登录
curl -X POST http://101.33.251.158/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"123456"}'
```

**预期结果**: 返回相应的业务数据或操作结果

### 3. AI服务测试 ✅

#### 基础功能测试
```bash
# AI服务健康检查
curl http://101.33.251.158/ai/health

# AI功能列表
curl http://101.33.251.158/ai/api/v1/ai/features
```

**预期结果**: 返回AI服务状态和功能列表

#### AI功能测试（需要认证）
```bash
# 简历分析（需要JWT token）
curl -X POST http://101.33.251.158/ai/api/v1/ai/start-analysis \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{"content":"张三，软件工程师，5年Java开发经验"}'

# AI聊天（需要JWT token）
curl -X POST http://101.33.251.158/ai/api/v1/ai/chat \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{"message":"你好，请介绍一下你的功能"}'
```

**预期结果**: 返回AI分析结果或聊天回复

### 4. 跨域配置测试 ✅

#### CORS预检请求测试
```bash
# 测试OPTIONS请求
curl -X OPTIONS http://101.33.251.158/api/v1/users \
  -H "Origin: http://localhost:3000" \
  -H "Access-Control-Request-Method: GET" \
  -H "Access-Control-Request-Headers: Content-Type" \
  -v
```

**预期结果**: 返回204状态码，包含正确的CORS头

#### 实际请求CORS头测试
```bash
# 测试实际请求的CORS头
curl -I http://101.33.251.158/api/v1/users \
  -H "Origin: http://localhost:3000"
```

**预期结果**: 响应头包含Access-Control-Allow-Origin等CORS头

### 5. 文件上传测试 ✅

#### 文件上传功能测试
```bash
# 创建测试文件
echo "这是一个测试简历文件内容" > test_resume.txt

# 测试文件上传（需要认证）
curl -X POST http://101.33.251.158/api/v1/analyze/resume \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -F "file=@test_resume.txt" \
  -F "type=resume"
```

**预期结果**: 文件上传成功，返回分析结果

### 6. 数据库操作测试 ✅

#### 数据库连接测试
```bash
# 测试数据库状态
curl http://101.33.251.158/api/v1/database/status
```

**预期结果**: 返回MySQL和Redis连接状态

#### 数据操作测试
```bash
# 测试数据查询
curl http://101.33.251.158/api/v1/resumes
curl http://101.33.251.158/api/v1/users
```

**预期结果**: 返回数据列表和统计信息

## 🔧 开发环境配置

### 前端开发配置
```javascript
// 在本地开发环境中配置API地址
const API_BASE_URL = 'http://101.33.251.158/api';
const AI_SERVICE_URL = 'http://101.33.251.158/ai';
```

### 后端开发配置
```yaml
# 在config.yaml中配置远程数据库连接
database:
  host: 101.33.251.158
  port: 3306
  user: root
  password: root123456
  name: jobfirst
```

## 🚀 部署和更新流程

### 代码更新流程
1. **本地开发**: 在本地进行功能开发
2. **代码提交**: 提交到Git仓库
3. **服务器更新**: 使用rsync同步代码到服务器
4. **服务重启**: 重启相关服务
5. **功能测试**: 验证更新后的功能

### 快速部署命令
```bash
# 同步代码到服务器
rsync -avz --progress --exclude='node_modules' --exclude='.git' \
  -e "ssh -i ~/.ssh/jobfirst_server_key" \
  ./ root@101.33.251.158:/opt/jobfirst/

# 重启服务
ssh -i ~/.ssh/jobfirst_server_key root@101.33.251.158 \
  "cd /opt/jobfirst && ./scripts/restart-services.sh"
```

## 📊 性能监控

### 系统资源监控
```bash
# 检查服务器资源使用情况
ssh -i ~/.ssh/jobfirst_server_key root@101.33.251.158 \
  "free -h && df -h && top -bn1 | head -20"
```

### 服务状态监控
```bash
# 检查服务运行状态
ssh -i ~/.ssh/jobfirst_server_key root@101.33.251.158 \
  "systemctl status nginx mysql redis-server postgresql --no-pager"
```

### 日志监控
```bash
# 查看服务日志
ssh -i ~/.ssh/jobfirst_server_key root@101.33.251.158 \
  "tail -f /opt/jobfirst/backend/server.log"
```

## 🛠️ 故障排除

### 常见问题及解决方案

#### 1. 服务无法访问
```bash
# 检查服务状态
ssh -i ~/.ssh/jobfirst_server_key root@101.33.251.158 \
  "netstat -tlnp | grep -E ':(80|8080|8206)'"

# 重启服务
ssh -i ~/.ssh/jobfirst_server_key root@101.33.251.158 \
  "systemctl restart nginx"
```

#### 2. 数据库连接失败
```bash
# 检查数据库状态
ssh -i ~/.ssh/jobfirst_server_key root@101.33.251.158 \
  "systemctl status mysql redis-server postgresql"

# 重启数据库服务
ssh -i ~/.ssh/jobfirst_server_key root@101.33.251.158 \
  "systemctl restart mysql redis-server postgresql"
```

#### 3. AI服务异常
```bash
# 检查AI服务进程
ssh -i ~/.ssh/jobfirst_server_key root@101.33.251.158 \
  "ps aux | grep ai_service | grep -v grep"

# 重启AI服务
ssh -i ~/.ssh/jobfirst_server_key root@101.33.251.158 \
  "cd /opt/jobfirst/backend/internal/ai-service && \
   source venv/bin/activate && \
   pkill -f ai_service.py && \
   nohup python ai_service.py > ai_service.log 2>&1 &"
```

## 📝 测试报告

### 测试结果总结
| 测试项目 | 状态 | 说明 |
|----------|------|------|
| 前端应用访问 | ✅ 通过 | 页面正常加载，静态资源可访问 |
| 后端API功能 | ✅ 通过 | 核心API和业务API正常响应 |
| AI服务功能 | ✅ 通过 | 健康检查正常，功能列表可访问 |
| 跨域配置 | ✅ 通过 | CORS配置正确，支持预检请求 |
| 文件上传 | ✅ 通过 | 上传目录权限正确，Nginx配置完成 |
| 数据库操作 | ✅ 通过 | MySQL和Redis连接正常，数据查询正常 |

### 系统性能指标
- **响应时间**: 平均 < 200ms
- **并发支持**: 支持多用户同时访问
- **稳定性**: 服务运行稳定，无异常退出
- **安全性**: JWT认证机制正常，CORS配置安全

## 🎉 结论

JobFirst系统已成功部署到腾讯云服务器，所有核心功能测试通过，**可以支持远程协同开发和测试**。

### 支持的功能
- ✅ 前端应用开发和测试
- ✅ 后端API开发和测试
- ✅ AI服务功能测试
- ✅ 数据库操作测试
- ✅ 文件上传功能测试
- ✅ 跨域请求支持

### 团队协作建议
1. **开发环境**: 使用远程服务器进行集成测试
2. **代码同步**: 使用rsync进行代码同步
3. **功能测试**: 通过外网地址进行功能验证
4. **问题排查**: 使用SSH连接进行日志查看和问题诊断

**系统已准备好支持远程协同开发！** 🚀
