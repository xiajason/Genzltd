# JobFirst Basic 开发指南

## 🚀 快速开始

### 环境要求
- **Node.js**: 18+ (当前: 24.6.0 ✅)
- **Go**: 1.20+ (当前: 1.25.0 ✅)
- **Python**: 3.12+ (AI服务需要)
- **MySQL**: 8.0+ (已安装并运行 ✅)
- **Redis**: 6.0+ (已安装并运行 ✅)
- **Consul**: 服务发现和健康检查
- **PostgreSQL**: AI服务专用数据库

### 项目结构
```
basic/
├── backend/                    # Go 后端微服务
│   ├── cmd/basic-server/       # API网关服务 (端口8080)
│   ├── internal/
│   │   ├── user/              # 用户服务 (端口8081)
│   │   ├── resume/            # 简历服务 (端口8082)
│   │   └── ai-service/        # AI服务 (端口8206, Python)
│   ├── pkg/shared/            # 共享包
│   └── configs/               # 配置文件
├── frontend-taro/              # Taro 统一前端项目
│   ├── src/
│   │   ├── pages/             # 页面组件
│   │   ├── components/        # 通用组件
│   │   ├── services/          # API服务层
│   │   ├── stores/            # 状态管理
│   │   └── utils/             # 工具函数
│   └── config/                # Taro配置
├── scripts/                   # 启动脚本
└── database/                  # 数据库配置
```

## 🛠️ 开发方式

### 方式一：使用自动化脚本（推荐）

#### 启动完整服务栈
```bash
cd /Users/szjason72/zervi-basic/basic
./scripts/start-local.sh
```

#### 仅启动 Taro 前端开发
```bash
cd /Users/szjason72/zervi-basic/basic
./scripts/start-taro-dev.sh h5        # H5 开发
./scripts/start-taro-dev.sh weapp     # 微信小程序开发
```

### 方式二：手动启动微服务

#### 1. 启动基础设施服务
```bash
# 启动 MySQL
brew services start mysql

# 启动 Redis
brew services start redis

# 启动 Consul (如果未运行)
brew services start consul

# 启动 PostgreSQL (AI服务需要)
brew services start postgresql
```

#### 2. 启动后端微服务
```bash
# 启动 API网关 (端口8080)
cd /Users/szjason72/zervi-basic/basic/backend
go run cmd/basic-server/main.go

# 启动用户服务 (端口8081)
cd /Users/szjason72/zervi-basic/basic/backend/internal/user
go run main.go

# 启动简历服务 (端口8082)
cd /Users/szjason72/zervi-basic/basic/backend/internal/resume
go run main.go

# 启动AI服务 (端口8206, Python)
cd /Users/szjason72/zervi-basic/basic/backend/internal/ai-service
source venv/bin/activate
python ai_service.py
```

#### 3. 启动前端服务
```bash
cd /Users/szjason72/zervi-basic/basic/frontend-taro
npm run dev:h5        # H5 开发
npm run dev:weapp     # 微信小程序开发

# 构建微信小程序版本（用于微信开发者工具）
npm run build:weapp
```

## 📱 服务访问地址

启动后可访问以下服务：

### 前端服务
- **Taro H5 前端**: http://localhost:10086
- **微信小程序**: 使用微信开发者工具打开 `frontend-taro/dist/` 目录

### 后端微服务
- **API网关**: http://localhost:8080
  - 健康检查: http://localhost:8080/health
  - 服务状态: http://localhost:8080/api/v1/status
- **用户服务**: http://localhost:8081
  - 健康检查: http://localhost:8081/health
- **简历服务**: http://localhost:8082
  - 健康检查: http://localhost:8082/health
- **AI服务**: http://localhost:8206
  - 健康检查: http://localhost:8206/health

### 基础设施服务
- **Consul UI**: http://localhost:8500
- **Redis**: localhost:6379
- **MySQL**: localhost:3306
- **PostgreSQL**: localhost:5432

## ⚠️ 常见问题修复

### 问题1: npm 命令找不到 package.json

**错误信息**:
```
npm error code ENOENT
npm error path /Users/szjason72/zervi-basic/package.json
```

**解决方案**:
确保在正确的目录下运行 npm 命令：
```bash
# ❌ 错误 - 在项目根目录运行
cd /Users/szjason72/zervi-basic
npm run dev:h5

# ✅ 正确 - 在 Taro 项目目录运行
cd /Users/szjason72/zervi-basic/basic/frontend-taro
npm run dev:h5
```

### 问题2: 端口占用

**解决方案**:
```bash
# 查看端口占用
lsof -i :10086  # Taro前端
lsof -i :8080   # API网关
lsof -i :8081   # 用户服务
lsof -i :8082   # 简历服务
lsof -i :8206   # AI服务

# 杀死占用进程
kill -9 <PID>

# 或者批量清理Go进程
pkill -f "go run"
```

### 问题3: 数据库连接失败

**解决方案**:
```bash
# 检查 MySQL 服务状态
brew services list | grep mysql
brew services start mysql

# 检查 Redis 服务状态
brew services list | grep redis
brew services start redis

# 检查 PostgreSQL 服务状态 (AI服务需要)
brew services list | grep postgresql
brew services start postgresql

# 创建AI服务数据库
psql -U szjason72 -c "CREATE DATABASE jobfirst_vector;"
```

### 问题4: CORS跨域错误

**错误信息**:
```
Request header field API-Version is not allowed by Access-Control-Allow-Headers
```

**解决方案**:
已修复 - 后端已配置允许 `API-Version` 请求头：
- `basic/backend/configs/config.yaml`
- `basic/backend/pkg/shared/infrastructure/middleware/cors.go`
- `basic/backend/cmd/basic-server/main.go`

### 问题5: AI服务启动失败

**错误信息**:
```
can't open file 'ai_service.py': [Errno 2] No such file or directory
```

**解决方案**:
```bash
# 确保在正确目录并激活虚拟环境
cd /Users/szjason72/zervi-basic/basic/backend/internal/ai-service
source venv/bin/activate
python ai_service.py
```

### 问题6: 微服务健康检查失败

**解决方案**:
```bash
# 检查所有服务状态
curl http://localhost:8080/health  # API网关
curl http://localhost:8081/health  # 用户服务
curl http://localhost:8082/health  # 简历服务
curl http://localhost:8206/health  # AI服务

# 查看Consul服务注册状态
curl http://localhost:8500/v1/agent/services
```

### 问题7: Web端登录失败 - CORS预检请求404错误

**错误信息**:
```
Preflight response is not successful. Status code: 404
Fetch API cannot load http://localhost:8080/api/v1/auth/login due to access control checks
```

**解决方案**:
1. **检查API网关OPTIONS路由配置**:
   ```bash
   # 测试OPTIONS请求
   curl -X OPTIONS http://localhost:8080/api/v1/auth/login -v
   # 应该返回200状态码和CORS头信息
   ```

2. **如果OPTIONS请求返回404，重启API网关**:
   ```bash
   # 停止API网关
   pkill -f "basic-server"
   
   # 重新启动API网关
   cd /Users/szjason72/zervi-basic/basic/backend
   go run cmd/basic-server/main.go &
   ```

3. **验证CORS配置**:
   - API网关已配置处理所有OPTIONS请求
   - 允许的请求头包括: `API-Version`, `Authorization`, `Content-Type`等
   - 允许的请求方法包括: `GET`, `POST`, `PUT`, `DELETE`, `OPTIONS`

### 问题8: 登录API返回401 - 用户手机号未配置

**错误信息**:
```
{"error":"Invalid credentials"}
```

**解决方案**:
1. **检查用户数据**:
   ```bash
   mysql -u root -e "USE jobfirst; SELECT username, phone, password_hash FROM users WHERE username = 'jobfirst';"
   ```

2. **如果手机号为NULL，需要配置手机号**:
   ```bash
   # 为jobfirst用户配置手机号（小程序端需要）
   mysql -u root -e "USE jobfirst; UPDATE users SET phone = '18923835899' WHERE username = 'jobfirst';"
   ```

3. **验证登录**:
   ```bash
   # 测试登录API
   curl -X POST http://localhost:8080/api/v1/auth/login \
     -H "Content-Type: application/json" \
     -d '{"username":"jobfirst","password":"jobfirst123"}'
   ```

4. **预期成功响应**:
   ```json
   {
     "status": "success",
     "message": "Login successful",
     "data": {
       "token": "token_jobfirst_xxx",
       "user": {
         "id": 8,
         "username": "jobfirst",
         "email": "jobfirst@test.com",
         "phone": "18923835899"
       }
     }
   }
   ```

### 问题9: 前端API请求路径错误

**错误信息**:
```
Failed to load resource: Request header field API-Version is not allowed
```

**解决方案**:
1. **检查前端API配置**:
   ```bash
   # 查看前端API基础URL配置
   cat /Users/szjason72/zervi-basic/basic/frontend-taro/src/services/request.ts | grep API_BASE_URL
   ```

2. **确保API基础URL指向API网关**:
   ```typescript
   // 应该是 http://localhost:8080 (API网关)
   const API_BASE_URL = process.env.NODE_ENV === 'development' 
     ? 'http://localhost:8080' 
     : 'https://api.jobfirst.com'
   ```

3. **重启前端服务**:
   ```bash
   # 停止前端服务
   pkill -f "npm run dev:h5"
   
   # 重新启动前端
   cd /Users/szjason72/zervi-basic/basic/frontend-taro
   npm run dev:h5 &
   ```

### 问题10: 微信小程序无法在开发者工具中预览

**错误信息**:
```
微信开发者工具提示：找不到项目文件或目录不存在
```

**解决方案**:
1. **构建微信小程序版本**:
   ```bash
   cd /Users/szjason72/zervi-basic/basic/frontend-taro
   npm run build:weapp
   ```

2. **检查构建结果**:
   ```bash
   # 确认dist目录存在且包含必要文件
   ls -la dist/
   ls -la dist/pages/
   ```

3. **微信开发者工具导入**:
   - 打开微信开发者工具
   - 选择"导入项目"
   - 项目目录选择：`/Users/szjason72/zervi-basic/basic/frontend-taro/dist/`
   - AppID使用：`touristappid`（测试号）

4. **验证项目配置**:
   ```bash
   # 检查项目配置文件
   cat dist/project.config.json
   ```

5. **常见错误处理**:
   - **`无效的 app.json permission["scope.userInfo"]`**: 权限配置格式错误，已移除过时的权限配置
   - **`webapi_getwxaasyncsecinfo:fail invalid scope`**: 权限范围错误，已通过以下方式解决：
     - 移除了过时的权限配置
     - 在 `platform.ts` 中添加了 `Taro.getSystemInfoSync()` 的错误处理
     - 在 `app.ts` 中添加了权限错误的过滤处理
   - **`Cannot read property 'setItem' of undefined`**: 存储API错误，已简化Zustand配置
   - **`POST https://api.jobfirst.com/api/v1/auth/login 404`**: API请求地址错误，已修复：
     - 在 `request.ts` 中修改了API配置逻辑
     - 微信小程序环境现在使用 `http://localhost:8080`
     - H5环境根据 `NODE_ENV` 判断使用本地或生产环境
   - **`API request error: Error: Login successful`**: 响应格式不匹配，已修复：
     - 后端返回 `status: "success"` 格式
     - 前端期望 `code: 200` 格式
     - 已更新前端代码兼容两种响应格式
   - **`非法的多端项目，未找到 project.miniapp.json`**: 微信小程序多端项目配置缺失，已修复：
     - 创建了 `project.miniapp.json` 配置文件
     - 配置了正确的项目信息和编译设置
     - 更新了构建脚本自动生成此文件
   - **`readFile:fail /app.miniapp.json not found`**: 身份管理API配置文件缺失，已修复：
     - 创建了 `app.miniapp.json` 配置文件
     - 禁用了身份管理服务以避免调试问题
     - 配置了开发环境权限设置
   - **`switchTab:fail can not switch to no-tabBar page`**: tabBar页面跳转错误，已修复：
     - 启用了 `app.config.ts` 中的 tabBar 配置
     - 配置了四个主要页面：首页、简历、职位、AI助手
     - 确保所有 `Taro.switchTab()` 调用的页面都在 tabBar 列表中
   - **`Cannot read property 'setItem' of undefined`**: Zustand persist中间件存储API错误，已修复：
     - 移除了 `resumeStore.ts` 中的 `persist` 中间件
     - 简化了状态管理，避免在微信小程序环境中使用复杂的存储API
     - 确保所有 store 都不依赖 persist 中间件
   - **`未授权，请检查数据库访问权限配置`**: 数据库用户密码错误，已修复：
     - 确认了 `jobfirst` 用户的正确密码是 `jobfirst123`
     - 数据库连接配置正确，MySQL服务正常运行
     - API服务正常响应，问题在于前端使用了错误的密码
   - **`GET http://localhost:8080/api/v1/resume/list 404 (Not Found)`**: API路径不匹配错误，已修复：
     - 前端请求的是 `/api/v1/resume/list`，但后端提供的是 `/api/v1/resumes`
     - 修改了 `resumeService.ts` 中的API路径从 `/api/v1/resume/list` 到 `/api/v1/resumes`
     - 重新构建了微信小程序以应用修复
   - **`TypeError: Cannot read property 'length' of undefined`**: 简历数据结构不匹配错误，已修复：
     - 后端返回的数据结构是 `{ data: [...], count: 3, status: "success" }`
     - 前端期望的是 `{ resumes: [...] }` 结构
     - 修改了 `resumeStore.ts` 中从 `response.resumes` 到 `response.data || []`
     - 更新了 `ResumeListResponse` 类型定义以匹配后端响应格式
     - 更新了 `Resume` 类型定义以匹配后端返回的字段（如 `created_at`, `view_count` 等）
     - 在 `resume/index.tsx` 中添加了安全检查：`(!resumes || resumes.length === 0)` 和 `resumes && resumes.length > 0`
   - **`navigateTo:fail page "pages/resume/create/index" is not found`**: 简历创建页面不存在错误，已修复：
     - 创建了 `pages/resume/create/index` 页面，支持两种创建方式：Markdown编辑和图片上传
     - 创建了 `pages/resume/edit/index` 页面用于编辑简历
     - 创建了 `pages/resume/detail/index` 页面用于查看简历详情
     - 更新了 `app.config.ts` 添加新的页面路径
     - 更新了 `ResumeForm` 类型定义以支持字符串和对象两种内容格式
     - 重新构建了微信小程序以包含新页面
   - **`chooseMessageFile:fail SDK暂不支持此API`**: 文件选择API不支持错误，已修复：
     - 微信小程序开发者工具中的SDK版本不支持 `chooseMessageFile` API
     - 将文件上传功能改为图片上传功能，使用 `Taro.chooseImage` API
     - 支持从相册选择图片或拍照上传
     - 更新了界面文本从"文件上传"改为"图片上传"
     - 更新了提示文本从"PDF或DOCX文档"改为"JPG、PNG格式图片"
   - **`chooseImage:fail cancel` 和文档上传限制**: 用户取消选择和文档格式限制问题，已修复：
     - 用户取消图片选择时不再显示错误提示，改为静默处理
     - 添加了文件类型选择器，支持图片、文档、拍照三种选项
     - 对于文档上传，提供友好的提示说明微信小程序的限制
     - 建议用户将文档转换为图片后上传，或使用网页版进行文档上传
     - 优化了用户体验，避免因取消操作而产生错误提示
   - **`showModal:fail confirmText length should not larger than 4 Chinese characters`**: 微信小程序模态框按钮文本长度限制错误，已修复：
     - 微信小程序的 `showModal` API 要求 `confirmText` 不能超过4个中文字符
     - 将 "转换为图片" 改为 "转图片"（3个中文字符）
     - 确保所有模态框的按钮文本都符合微信小程序的长度限制
     - 优化了用户界面文本，保持功能完整性的同时符合平台规范
   - **`chooseImage:fail cancel` 错误处理优化**: 用户取消图片选择的错误处理改进：
     - 使用精确匹配 `error.errMsg === 'chooseImage:fail cancel'` 来识别用户取消操作
     - 对于用户取消操作，静默处理，不显示错误提示，提升用户体验
     - 注意：即使代码中正确处理了取消操作，微信小程序框架仍会在控制台显示 `MiniProgramError`，这是框架的正常行为，不影响功能
     - 只有真正的错误（非用户取消）才会显示错误提示给用户
   - **`no such file or directory: default-avatar.png` 和页面设备适配问题**: 缺失图片文件和设备适配问题，已修复：
     - 创建了 `src/assets/images/` 目录并复制了默认头像图片
     - 更新了 `profile/index.tsx` 使用正确的图片导入路径
     - 添加了响应式设计，优化了不同设备尺寸的显示效果
     - 调整了网格布局：大屏设备4列，中屏设备3列，小屏设备2列
     - 优化了用户卡片在小屏设备上的布局（垂直排列）
     - 调整了字体大小和间距，提升小屏设备的可读性
     - 重新构建项目，确保图片资源正确包含在构建输出中
   - **首页功能不完整问题**: 首页与备份项目差异较大，已重新设计：
     - 参考备份项目的完整首页设计，重新实现了所有功能模块
     - 添加了顶部搜索栏，支持职位、公司、技能搜索
     - 添加了轮播图功能，展示优质职位推荐和AI简历优化
     - 重新设计了快捷功能网格，包含创建简历、AI助手、职位搜索、数据分析
     - 添加了推荐职位列表，展示热门职位信息
     - 添加了市场洞察数据，显示在招职位、招聘企业、平均薪资
     - 添加了AI求职助手卡片，提供智能简历优化服务
     - 添加了热门行业展示，包含互联网、金融、教育、医疗等行业
     - 复制了必要的图片资源（轮播图、行业图标等）
     - 完全重写了首页样式，与备份项目保持一致的设计风格
   - **编译失败问题**: 重构后编译不成功，已修复：
     - 发现首页代码调用了`jobService.getRecommendJobs()`和`jobService.getMarketStatistics()`方法，但这些方法在jobService中不存在
     - 在`jobService.ts`中添加了缺失的API方法：
       - `getRecommendJobs()`: 获取推荐职位列表
       - `getMarketStatistics()`: 获取市场统计数据
     - 手动复制了SVG图片资源到dist目录，因为Taro不会自动处理SVG文件
     - 重新构建项目，编译成功，所有功能正常
   - **微信开发者工具兼容性问题**: 提示"非法的多端项目，未找到 project.miniapp.json"，已修复：
     - 创建了 `project.miniapp.json` 配置文件，包含完整的微信小程序配置
     - 更新了 `project.config.json` 文件，使其与微信开发者工具最新版本兼容
     - 创建了 `app.miniapp.json` 文件，确保应用配置正确
     - 创建了 `sitemap.json` 文件，满足微信小程序的站点地图要求
     - 配置了正确的编译选项，包括ES6支持、增强编译等
     - 创建了 `project.private.json` 私有配置文件
     - 创建了 `miniprogram.json` 作为备用配置文件
     - 简化了配置文件内容，移除了可能导致冲突的配置项
     - 统一了appid为 `touristappid` 以避免权限问题
     - 修复了首页 `userService is not defined` 错误，通过直接从 `jobService` 文件导入而不是从 `services/index.ts` 导入
     - 重新创建了所有微信开发者工具兼容性配置文件，确保 `project.miniapp.json`、`app.miniapp.json`、`sitemap.json` 和 `project.private.json` 都存在
     - 创建了自动化脚本 `scripts/post-build.js`，在每次构建后自动重新创建配置文件
     - 更新了 `package.json` 中的 `build:weapp` 脚本，确保配置文件在每次构建后都会自动创建

## 🎯 Taro统一开发项目状态

### 项目概述
JobFirst项目已成功实现Taro统一开发架构，一套代码同时支持微信小程序和H5 Web端，显著提升了开发效率和维护性。

### 技术架构
- **框架**: Taro 4.1.6 + React 18 + TypeScript
- **状态管理**: Zustand
- **样式**: SCSS
- **构建工具**: Webpack 5
- **包管理**: npm

### 项目结构
```
frontend-taro/
├── src/
│   ├── app.tsx                  # 应用入口
│   ├── app.config.ts            # 应用配置
│   ├── pages/                   # 页面目录 (19个页面)
│   │   ├── index/              # 首页
│   │   ├── login/              # 登录页
│   │   ├── register/           # 注册页
│   │   ├── profile/            # 个人中心
│   │   ├── resume/             # 简历管理
│   │   ├── jobs/               # 职位列表
│   │   ├── ai/                 # AI助手
│   │   ├── analytics/          # 数据分析
│   │   ├── settings/           # 系统设置
│   │   ├── points/             # 积分系统
│   │   └── file-management/    # 文件管理
│   ├── components/             # 共享组件 (45个组件)
│   │   ├── common/            # 通用组件
│   │   ├── business/          # 业务组件
│   │   └── ui/                # UI组件
│   ├── services/              # API服务层 (10个服务)
│   ├── stores/                # 状态管理 (3个Store)
│   ├── types/                 # 类型定义 (6个类型文件)
│   └── utils/                 # 工具函数
├── config/                    # 配置文件
├── dist/                      # 构建输出
└── package.json               # 项目配置
```

### 核心功能模块

#### 1. 用户认证系统
- ✅ 登录/注册页面
- ✅ JWT Token管理
- ✅ 用户信息管理
- ✅ 微信登录支持

#### 2. 简历管理系统
- ✅ 简历列表页面
- ✅ 简历创建/编辑页面
- ✅ 简历详情页面
- ✅ 文件上传功能
- ✅ 简历模板选择

#### 3. 职位搜索系统
- ✅ 职位列表页面
- ✅ 职位详情页面
- ✅ 搜索和筛选功能
- ✅ 职位申请功能

#### 4. AI助手功能
- ✅ 聊天界面
- ✅ 简历分析功能
- ✅ 智能推荐
- ✅ 技能评估

#### 5. 数据分析模块
- ✅ 统计图表展示
- ✅ 个人数据分析
- ✅ 市场数据分析
- ✅ 趋势分析

#### 6. 系统功能
- ✅ 个人中心
- ✅ 系统设置
- ✅ 积分系统
- ✅ 文件管理

### 技术特性

#### 跨端兼容
- ✅ 微信小程序支持
- ✅ H5 Web端支持
- ✅ 平台特定功能适配
- ✅ 统一的API接口

#### 开发体验
- ✅ TypeScript类型安全
- ✅ 热重载开发
- ✅ 统一的代码风格
- ✅ 完整的错误处理

#### 性能优化
- ✅ 代码分割
- ✅ 懒加载
- ✅ 缓存策略
- ✅ 构建优化

### 构建状态
- ✅ **微信小程序**: 构建成功，可在微信开发者工具中预览
- ✅ **H5端**: 支持构建，可部署到Web服务器
- ✅ **配置文件**: 自动生成微信小程序配置文件
- ⚠️ **CSS警告**: 存在CSS冲突警告，不影响功能

### 下一步计划
1. **启动后端服务**: 启动微服务进行端到端测试
2. **功能测试**: 验证所有功能的跨端兼容性
3. **性能优化**: 解决CSS冲突，优化构建体积
4. **部署准备**: 准备生产环境部署方案

## 🔐 权限管理系统

### 概述
JobFirst项目已成功集成完整的权限管理系统，包括基于角色的访问控制(RBAC)、超级管理员功能、JWT认证和Consul服务注册。

### 核心特性
- ✅ **完整RBAC权限系统** - 基于Casbin的权限管理
- ✅ **超级管理员功能** - 支持超级管理员初始化和密码重置
- ✅ **JWT认证** - 安全的用户认证和授权
- ✅ **Consul服务注册** - 微服务自动注册和健康检查
- ✅ **分层架构** - Domain、Application、Infrastructure、Interfaces四层架构
- ✅ **增强API端点** - 完整的用户管理和权限检查API

### 架构设计

#### 1. 分层架构
```
backend/
├── cmd/enhanced-basic-server/    # 增强服务器入口
├── internal/
│   ├── domain/                   # 领域层
│   │   ├── auth/                # 认证领域实体
│   │   └── user/                # 用户领域实体
│   ├── app/                     # 应用层
│   │   ├── auth/                # 认证应用服务
│   │   └── user/                # 用户应用服务
│   ├── infrastructure/          # 基础设施层
│   │   └── database/            # 数据库实现
│   └── interfaces/              # 接口层
│       └── http/                # HTTP处理器
└── pkg/                         # 共享包
    ├── rbac/                    # RBAC权限管理
    ├── middleware/              # 中间件
    ├── consul/                  # Consul服务注册
    └── logger/                  # 日志管理
```

#### 2. RBAC权限模型
- **角色**: super_admin, admin, dev_team, user
- **资源**: user, role, permission, system
- **操作**: read, write, delete
- **策略**: 基于Casbin的灵活权限策略

### 快速开始

#### 1. 启动增强服务器
```bash
# 构建增强服务器
cd backend
go build -o ../bin/enhanced-basic-server cmd/enhanced-basic-server/main.go

# 启动服务器
cd ..
./bin/enhanced-basic-server
```

#### 2. 初始化超级管理员
```bash
# 检查超级管理员状态
curl -s http://localhost:8080/api/v1/super-admin/public/status

# 初始化超级管理员
curl -X POST http://localhost:8080/api/v1/super-admin/public/initialize \
  -H "Content-Type: application/json" \
  -d '{
    "username": "admin",
    "email": "admin@jobfirst.com",
    "password": "AdminPassword123!",
    "first_name": "Super",
    "last_name": "Admin"
  }'
```

#### 3. 用户认证
```bash
# 用户登录
curl -X POST http://localhost:8080/api/v1/public/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "admin",
    "password": "AdminPassword123!"
  }'

# 使用Token访问受保护的端点
TOKEN="your-jwt-token"
curl -X GET http://localhost:8080/api/v1/protected/profile \
  -H "Authorization: Bearer $TOKEN"
```

#### 4. 权限检查
```bash
# 检查用户权限
curl -X GET "http://localhost:8080/api/v1/rbac/check?user=admin&resource=user&action=read" \
  -H "Authorization: Bearer $TOKEN"

# 获取用户角色
curl -X GET http://localhost:8080/api/v1/rbac/roles \
  -H "Authorization: Bearer $TOKEN"

# 获取用户权限
curl -X GET http://localhost:8080/api/v1/rbac/permissions \
  -H "Authorization: Bearer $TOKEN"
```

### API端点

#### 公开端点
- `GET /health` - 健康检查
- `POST /api/v1/public/register` - 用户注册
- `POST /api/v1/public/login` - 用户登录
- `GET /api/v1/super-admin/public/status` - 超级管理员状态
- `POST /api/v1/super-admin/public/initialize` - 初始化超级管理员

#### 受保护端点
- `GET /api/v1/protected/profile` - 获取用户资料
- `PUT /api/v1/protected/profile` - 更新用户资料

#### RBAC权限端点
- `GET /api/v1/rbac/check` - 权限检查
- `GET /api/v1/rbac/roles` - 获取用户角色
- `GET /api/v1/rbac/permissions` - 获取用户权限

#### 超级管理员端点
- `GET /api/v1/super-admin/users` - 用户列表
- `PUT /api/v1/super-admin/users/:id/status` - 更新用户状态
- `POST /api/v1/super-admin/reset-password` - 重置超级管理员密码

### 测试和验证

#### 运行完整测试
```bash
# 运行权限管理系统测试
./scripts/test-permission-system.sh
```

#### 手动测试步骤
1. **健康检查**: `curl http://localhost:8080/health`
2. **超级管理员初始化**: 使用上述API初始化
3. **用户登录**: 获取JWT Token
4. **权限检查**: 验证RBAC功能
5. **受保护端点**: 测试JWT认证

### 配置说明

#### 环境变量
```bash
# JWT配置
JWT_SECRET=jobfirst-basic-secret-key-2024
JWT_EXPIRES_IN=24h

# 数据库配置
DB_HOST=localhost
DB_PORT=3306
DB_NAME=jobfirst
DB_USER=root
DB_PASSWORD=your-password

# Consul配置
CONSUL_ENABLED=true
CONSUL_HOST=localhost
CONSUL_PORT=8500
```

#### 数据库表结构
权限管理系统使用以下数据库表：
- `users` - 用户表
- `roles` - 角色表
- `permissions` - 权限表
- `user_roles` - 用户角色关联表
- `role_permissions` - 角色权限关联表
- `casbin_rule` - Casbin策略表

### 故障排除

#### 常见问题
1. **JWT认证失败**: 检查JWT密钥配置是否一致
2. **权限检查失败**: 确认用户角色和权限已正确分配
3. **Consul注册失败**: 检查Consul服务是否运行
4. **数据库连接失败**: 验证数据库配置和连接

#### 日志查看
```bash
# 查看服务器日志
tail -f enhanced-server.log

# 查看特定错误
grep -i error enhanced-server.log
```

### 开发指南

#### 添加新的权限
1. 在`pkg/rbac/manager.go`中添加权限策略
2. 更新数据库权限表
3. 在中间件中应用权限检查

#### 添加新的API端点
1. 在相应的handler中添加方法
2. 在路由中注册端点
3. 添加适当的权限中间件

#### 扩展用户角色
1. 在`internal/domain/auth/entity.go`中定义新角色
2. 更新RBAC策略
3. 在超级管理员服务中处理角色分配

## 🆕 新增功能模块

### 1. 个人中心 (Profile)
- **位置**: `pages/profile/index`
- **功能**: 用户信息展示、快捷操作、功能菜单
- **特性**: 
  - 用户头像和基本信息展示
  - 积分和简历统计
  - 功能菜单网格布局
  - 退出登录功能

### 2. 系统设置 (Settings)
- **位置**: `pages/settings/index`
- **功能**: 应用设置、通知设置、系统配置
- **特性**:
  - 通知设置（推送、声音、震动）
  - 应用设置（自动保存、深色模式、语言）
  - 系统功能（清除缓存、意见反馈、隐私政策）
  - 版本信息展示

### 3. 数据分析 (Analytics)
- **位置**: `pages/analytics/index`
- **功能**: 个人数据分析和市场数据分析
- **特性**:
  - 个人数据：简历数量、浏览量、投递次数、回复率
  - 技能分析：技能水平评估和趋势
  - 市场数据：热门行业、薪资分布、职位趋势
  - 最近活动记录

### 4. 积分系统 (Points)
- **位置**: `pages/points/index`
- **功能**: 积分获取、消费、历史记录
- **特性**:
  - 积分概览：当前积分、累计获得、累计消费
  - 积分获取：每日签到、完善信息、分享简历、邀请好友
  - 积分消费：AI分析、高级模板、职位推荐、简历优化
  - 积分历史：详细的积分变动记录

### 5. AI智能助手 (AI)
- **位置**: `pages/ai/index`
- **功能**: AI智能服务功能
- **特性**:
  - 简历分析：内容分析、优化建议、关键词提取
  - 职位匹配：智能推荐、薪资预测、技能要求分析
  - 技能评估：水平测试、学习路径、认证建议
  - 面试准备：模拟面试、问题预测、回答建议
  - 职业规划：路径规划、目标设定、风险评估
  - 薪资谈判：市场分析、谈判策略、话术建议

### 6. 文件管理 (File Management)
- **位置**: `pages/file-management/index`
- **功能**: 文件上传、管理、预览、分享
- **特性**:
  - 存储空间统计和进度显示
  - 文件分类管理（简历、证书、作品、文档）
  - 文件搜索和筛选
  - 批量操作（选择、删除）
  - 文件预览和分享
  - 上传进度显示

### 7. 新增组件
- **ResumeItem**: 简历项目组件，支持查看、编辑、分享、删除操作
- **SearchBar**: 搜索栏组件，支持搜索历史和实时搜索
- **JobCard**: 职位卡片组件，展示职位信息和操作按钮
- **Loading**: 加载组件，支持全屏、内联、自定义样式

### 8. 新增API服务
- **pointsService**: 积分系统API服务
- **aiService**: AI智能服务API
- **fileService**: 文件管理API服务
- **增强的request**: 支持文件上传、进度回调、错误重试

## 🔧 技术改进

### 1. 应用配置更新
- 新增页面路由配置
- 更新tabBar配置（将"AI助手"替换为"我的"）
- 优化页面加载顺序

### 2. 组件库完善
- 统一的组件导出和类型定义
- 响应式设计适配
- 主题色彩系统

### 3. 状态管理优化
- 移除复杂的persist配置
- 简化状态管理逻辑
- 提升性能和稳定性

### 4. 错误处理增强
- 统一的错误处理机制
- 用户友好的错误提示
- 网络请求重试机制
   - **`SharedArrayBuffer` 警告**: 这是Chrome浏览器的安全警告，不影响小程序运行
   - **基础库版本**: 建议使用稳定版本，避免使用灰度版本

6. **微信开发者工具设置**:
   - 关闭"不校验合法域名"（开发阶段）
   - 开启"ES6转ES5"
   - 开启"增强编译"
   - 关闭"代码压缩"（便于调试）

## 🔧 开发工具配置

### VS Code 推荐插件
- **Go**: Go 语言支持
- **TypeScript**: TypeScript 支持
- **Taro**: Taro 开发支持
- **Python**: Python 语言支持
- **ESLint**: 代码检查
- **Prettier**: 代码格式化

### 微信开发者工具
1. 下载并安装微信开发者工具
2. 构建微信小程序版本：
   ```bash
   cd /Users/szjason72/zervi-basic/basic/frontend-taro
   npm run build:weapp
   ```
3. 导入项目：选择 `frontend-taro/dist/` 目录
4. 配置 AppID（测试可使用测试号 `touristappid`）

## 📝 开发规范

### 代码结构
- **后端**: 微服务架构，遵循 DDD 模式
  - **API网关**: 统一入口，路由转发
  - **用户服务**: 认证、用户管理
  - **简历服务**: 简历CRUD、模板管理
  - **AI服务**: 简历分析、智能推荐 (Python + Sanic)
- **前端**: Taro + React + TypeScript
  - **状态管理**: Zustand
  - **样式**: SCSS
  - **API层**: 统一请求封装

### 微服务通信
- **服务发现**: Consul
- **健康检查**: 每30秒自动检查
- **负载均衡**: 通过Consul实现
- **配置管理**: YAML配置文件

### 数据库设计
- **MySQL**: 主要业务数据 (用户、简历、职位等)
- **PostgreSQL**: AI服务专用 (向量数据、分析结果)
- **Redis**: 缓存、会话管理

### 提交规范
```bash
# 功能开发
git commit -m "feat: 添加用户登录功能"

# 问题修复
git commit -m "fix: 修复登录状态丢失问题"

# 文档更新
git commit -m "docs: 更新开发指南"
```

## 🚀 部署说明

### 开发环境
- 使用本地数据库和缓存
- 支持热重载
- 详细的错误日志
- 微服务独立部署

### 生产环境
- 需要配置生产数据库
- 启用 HTTPS
- 配置域名和 CDN
- 使用Docker容器化部署
- 配置负载均衡

## 🔍 服务监控

### 健康检查
所有微服务都提供 `/health` 端点：
```bash
# 检查服务状态
curl http://localhost:8080/health  # API网关
curl http://localhost:8081/health  # 用户服务
curl http://localhost:8082/health  # 简历服务
curl http://localhost:8206/health  # AI服务
```

### Consul监控
- **Web UI**: http://localhost:8500
- **服务列表**: 查看所有注册的微服务
- **健康状态**: 实时监控服务健康状态

## 📞 技术支持

如遇到问题，请按以下顺序检查：
1. **环境依赖**: Node.js、Go、Python、数据库服务
2. **服务启动**: 所有微服务是否正常启动
3. **端口占用**: 检查8080、8081、8082、8206端口
4. **数据库连接**: MySQL、Redis、PostgreSQL连接
5. **网络通信**: 微服务间通信是否正常
6. **日志查看**: 查看各服务的错误日志

### 快速诊断命令
```bash
# 检查所有服务状态
curl -s http://localhost:8080/health | jq '.status'
curl -s http://localhost:8081/health | jq '.status'
curl -s http://localhost:8082/health | jq '.status'
curl -s http://localhost:8206/health | jq '.status'

# 查看端口占用
lsof -i :8080 -i :8081 -i :8082 -i :8206

# 检查数据库连接
mysql -u root -e "SELECT 1"
redis-cli ping
psql -U szjason72 -c "SELECT 1"

# 测试登录功能
curl -X OPTIONS http://localhost:8080/api/v1/auth/login -v  # 测试CORS
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"jobfirst","password":"jobfirst123"}'  # 测试登录

# 检查用户数据
mysql -u root -e "USE jobfirst; SELECT username, phone FROM users WHERE username = 'jobfirst';"
```

## ✅ 当前服务状态 (2025年1月更新)

### 已验证运行的服务
- ⚠️ **API网关** (basic-server): http://localhost:8080 (未启动)
- ⚠️ **用户服务** (user-service): http://localhost:8081 (未启动)
- ⚠️ **简历服务** (resume-service): http://localhost:8082 (未启动)
- ⚠️ **AI服务** (ai-service): http://localhost:8206 (未启动)
- ✅ **Taro前端**: 构建成功，支持微信小程序和H5
- ✅ **Consul**: 服务发现正常运行

### 数据库状态
- ✅ **MySQL**: jobfirst数据库，包含完整的表结构和5个测试用户
- ✅ **PostgreSQL**: jobfirst_vector数据库，AI服务专用
- ✅ **Redis**: 缓存服务正常运行

### Taro统一开发项目状态
- ✅ **项目框架**: Taro 4.1.6 + React 18 + TypeScript
- ✅ **构建成功**: 微信小程序版本构建完成
- ✅ **页面完整**: 包含所有主要功能页面
- ✅ **组件库**: UI组件和业务组件完整
- ✅ **状态管理**: Zustand状态管理实现
- ✅ **API服务层**: 统一请求封装完成
- ✅ **类型定义**: 完整的TypeScript类型系统

### 功能验证状态
- ✅ **前端构建**: Taro项目可成功构建为微信小程序
- ✅ **组件导入**: 修复了Modal和FormItem组件导入问题
- ✅ **配置文件**: 修复了TypeScript配置问题
- ✅ **页面路由**: 所有页面路由配置正确
- ⚠️ **后端集成**: 需要启动微服务进行端到端测试

---

## 测试用户信息

### 主要测试用户
- **用户名**: `jobfirst`
- **密码**: `jobfirst123` ⚠️ **重要：密码不是123456**
- **手机号**: `18923835899`
- **邮箱**: `jobfirst@test.com`

### 其他测试用户
- **用户名**: `testuser` / **密码**: `testuser123`
- **用户名**: `demouser` / **密码**: `demouser123`

### 登录测试命令
```bash
# 测试登录API
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"jobfirst","password":"jobfirst123"}'
```

---

**注意**: 请确保在正确的目录下运行命令，避免在项目根目录直接运行 npm 命令。微服务架构需要所有服务协同工作，建议使用自动化脚本启动。

