# JobFirst 微服务架构启动指南

**更新时间**: 2025年1月6日 15:30  
**架构版本**: V4.0 多数据库协同架构  

## 📋 架构概述

JobFirst采用微服务架构，包含以下核心组件：

### 数据库层
- **MySQL (3306)**: 核心业务数据存储
- **PostgreSQL (5432)**: AI服务和向量数据存储
- **Redis (6379)**: 缓存和会话管理
- **Neo4j (7474/7687)**: 关系网络分析

### 微服务层
- **API Gateway (8080)**: 统一API入口
- **User Service (8081)**: 业务用户认证和权限管理服务
- **Dev Team Service (8088)**: 开发团队协作管理服务
- **Resume Service (8082)**: 简历管理服务
- **AI Service (8206)**: Python AI服务
- **Company Service (8083)**: 企业管理服务

## 🚀 快速启动

### 微服务启动时序依赖关系

微服务架构的启动必须遵循严格的时序依赖关系，确保服务间的正确通信和功能完整性：

#### 启动顺序和依赖关系
```
1. 基础设施层 (Infrastructure Layer)
   ├── 数据库服务 (MySQL, PostgreSQL, Redis, Neo4j)
   └── 服务发现 (Consul)

2. 网关层 (Gateway Layer)
   └── API Gateway (统一入口，服务注册)

3. 认证授权层 (Authentication Layer)
   └── User Service (用户认证、角色识别、权限验证)

4. 业务服务层 (Business Service Layer)
   └── Resume Service (简历管理，依赖用户认证)

5. AI服务层 (AI Service Layer)
   └── AI Service (智能分析，依赖用户登录状态)
```

#### 关键时序要求
- **API Gateway** 必须在所有业务服务之前启动，作为统一入口
- **Consul** 必须在API Gateway启动前运行，提供服务发现
- **User Service** 必须在Resume Service之前启动，提供认证基础
- **AI Service** 必须在用户成功登录后才可访问，确保安全性和资源控制

### 开发环境启动（热加载模式）

#### 使用开发环境启动脚本（推荐）

```bash
# 启动完整开发环境 (数据库 + 后端 + 前端，支持热加载)
./scripts/start-dev-environment.sh start

# 仅启动后端服务 (数据库 + 微服务，支持热加载)
./scripts/start-dev-environment.sh backend

# 仅启动前端开发服务器
./scripts/start-dev-environment.sh frontend

# 查看服务状态
./scripts/start-dev-environment.sh status

# 健康检查
./scripts/start-dev-environment.sh health

# 停止所有开发服务
./scripts/start-dev-environment.sh stop

# 重启所有开发服务
./scripts/start-dev-environment.sh restart
```

#### 热加载特性
- **API Gateway**: air热加载 (Go代码修改自动重启)
- **User Service**: air热加载 (Go代码修改自动重启)
- **Resume Service**: air热加载 (Go代码修改自动重启)
- **AI Service**: Sanic热加载 (Python代码修改自动重启)
- **前端**: Taro HMR (前端代码修改自动刷新)

### 生产环境启动

#### 使用生产环境启动脚本

```bash
# 启动所有服务（按正确时序）
./scripts/start-microservices.sh start

# 查看服务状态
./scripts/start-microservices.sh status

# 健康检查
./scripts/start-microservices.sh health

# 停止所有服务
./scripts/start-microservices.sh stop

# 重启所有服务
./scripts/start-microservices.sh restart
```

### 手动启动步骤（按正确时序）

#### 1. 启动基础设施层
```bash
# 启动数据库服务
brew services start mysql
brew services start postgresql@14
brew services start redis
brew services start neo4j

# 启动服务发现 (Consul)
brew services start consul
# 或者使用本地Consul
consul agent -dev -data-dir=./consul/data -config-dir=./consul/config &
```

#### 2. 启动网关层
```bash
# 启动API Gateway (必须在其他服务之前)
cd backend
go run cmd/basic-server/main.go &
# 等待API Gateway完全启动
sleep 5
```

#### 3. 启动认证授权层
```bash
# 启动User Service (提供认证基础)
cd backend/internal/user
go run main.go &
# 等待User Service注册到Consul
sleep 3
```

#### 4. 启动业务服务层
```bash
# 启动Resume Service (依赖用户认证)
cd backend/internal/resume
go run main.go &
# 等待Resume Service注册到Consul
sleep 3
```

#### 5. 启动AI服务层
```bash
# 启动AI Service (依赖用户登录状态)
cd backend/internal/ai-service
source venv/bin/activate
python ai_service.py &
# 等待AI Service完全启动
sleep 8
```

#### 启动时序验证
```bash
# 验证服务启动顺序
echo "1. 检查基础设施层..."
brew services list | grep -E "(mysql|postgresql|redis|neo4j|consul)"

echo "2. 检查API Gateway..."
curl -s http://localhost:8080/health | jq '.status'

echo "3. 检查User Service..."
curl -s http://localhost:8081/health

echo "4. 检查Resume Service..."
curl -s http://localhost:8082/health

echo "5. 检查Company Service..."
curl -s http://localhost:8083/health

echo "6. 检查AI Service..."
curl -s http://localhost:8206/health
```

## 🔧 服务配置

### 热加载配置

#### Air热加载配置 (Go服务)

**API Gateway配置** (`backend/.air.toml`):
```toml
[build]
  cmd = "go build -o ./tmp/main ./cmd/basic-server/main.go"
  exclude_dir = ["assets", "tmp", "vendor", "testdata", "logs", "uploads", "temp", "node_modules", "venv", "internal/ai-service/venv"]
  include_ext = ["go", "tpl", "tmpl", "html", "yaml", "yml"]
  delay = 1000
```

**User Service配置** (`backend/internal/user/.air.toml`):
```toml
[build]
  cmd = "go build -o ./tmp/main ./main.go"
  exclude_dir = ["assets", "tmp", "vendor", "testdata", "logs", "uploads", "temp", "node_modules", "venv"]
  include_ext = ["go", "tpl", "tmpl", "html", "yaml", "yml"]
  delay = 1000
```

**Resume Service配置** (`backend/internal/resume/.air.toml`):
```toml
[build]
  cmd = "go build -o ./tmp/main ./main.go"
  exclude_dir = ["assets", "tmp", "vendor", "testdata", "logs", "uploads", "temp", "node_modules", "venv"]
  include_ext = ["go", "tpl", "tmpl", "html", "yaml", "yml"]
  delay = 1000
```

#### Sanic热加载配置 (Python AI服务)

**AI Service配置** (`backend/internal/ai-service/ai_service.py`):
```python
if __name__ == "__main__":
    app.run(
        host="0.0.0.0",
        port=Config.PORT,
        debug=True,      # 启用调试模式
        reload=True,     # 启用热重载
        auto_reload=True # 自动重载
    )
```

#### 热加载优势

1. **开发效率提升**: 代码修改后自动重启，无需手动重启服务
2. **实时反馈**: 修改立即生效，快速验证功能
3. **减少错误**: 避免忘记重启服务导致的调试困惑
4. **团队协作**: 统一的开发环境，提高团队开发效率

### 服务依赖关系图
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   数据库层      │    │   服务发现      │    │   网关层        │
│ MySQL/PostgreSQL│    │    Consul       │    │  API Gateway    │
│ Redis/Neo4j     │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │   认证授权层    │
                    │  User Service   │
                    │ (JWT/角色/权限) │
                    └─────────────────┘
                                 │
                    ┌─────────────────┐
                    │   业务服务层    │
                    │ Resume Service  │
                    │ (依赖用户认证)  │
                    └─────────────────┘
                                 │
                    ┌─────────────────┐
                    │   AI服务层      │
                    │  AI Service     │
                    │ (依赖登录状态)  │
                    └─────────────────┘
```

### API Gateway配置
- **配置文件**: `backend/configs/config.yaml`
- **端口**: 8080
- **健康检查**: `http://localhost:8080/health`
- **依赖**: Consul服务发现
- **职责**: 统一API入口、路由转发、服务注册

### User Service配置
- **端口**: 8081
- **健康检查**: `http://localhost:8081/health`
- **依赖**: MySQL、Redis
- **职责**: 用户认证、JWT令牌管理、角色识别、权限验证、用户管理
- **API端点**: 
  - `/api/v1/auth/login` - 用户登录
  - `/api/v1/auth/register` - 用户注册
  - `/api/v1/users/` - 用户管理
  - `/api/v1/roles/` - 角色管理
  - `/api/v1/permissions/` - 权限管理

### Resume Service配置
- **端口**: 8082
- **健康检查**: `http://localhost:8082/health`
- **依赖**: User Service认证、MySQL
- **职责**: 简历管理、依赖用户认证状态

### AI服务配置
- **配置文件**: `backend/internal/ai-service/ai_service.py`
- **端口**: 8206
- **虚拟环境**: `backend/internal/ai-service/venv/`
- **健康检查**: `http://localhost:8206/health`
- **依赖**: 用户登录状态、PostgreSQL向量存储
- **职责**: 智能分析、向量计算、仅在用户认证后提供服务

### Company Service配置
- **端口**: 8083
- **健康检查**: `http://localhost:8083/health`
- **依赖**: MySQL
- **职责**: 企业管理、企业信息维护、企业认证
- **API端点**:
  - `/api/v1/companies/` - 企业列表和搜索
  - `/api/v1/companies/:id` - 企业详情
  - `/api/v1/companies/` (POST) - 创建企业
  - `/api/v1/companies/:id` (PUT) - 更新企业信息

### 数据库配置
- **MySQL**: `localhost:3306/jobfirst` (核心业务数据)
- **PostgreSQL**: `localhost:5432/jobfirst_vector` (AI向量存储)
- **Redis**: `localhost:6379` (缓存、会话、JWT令牌)
- **Neo4j**: `http://localhost:7474` (关系网络分析)
- **Consul**: `localhost:8500` (服务发现、健康检查)

## 📊 服务监控

### 端口检查
```bash
# 检查所有服务端口
lsof -i :8080  # API Gateway
lsof -i :8081  # User Service
lsof -i :8082  # Resume Service
lsof -i :8083  # Company Service
lsof -i :8206  # AI Service
lsof -i :3306  # MySQL
lsof -i :5432  # PostgreSQL
lsof -i :6379  # Redis
lsof -i :7474  # Neo4j
```

### Consul健康管理

#### Consul UI访问
- **URL**: http://localhost:8500/ui/
- **功能**: 图形化界面查看服务状态、健康检查、服务发现
- **状态**: ✅ 已启用并正常运行

#### Consul健康监控脚本
使用专门的健康监控脚本进行全面的Consul状态检查：

```bash
# 运行Consul健康监控
./scripts/consul-health-monitor.sh
```

**监控内容包括**:
- ✅ Consul服务状态和集群Leader
- ✅ Consul UI可访问性
- ✅ 集群成员状态
- ✅ 已注册服务列表 (当前9个服务)
- ✅ 健康检查状态统计 (通过/警告/严重)
- ✅ 服务健康详情
- ✅ Consul端口占用检查
- ✅ 数据目录状态

#### Consul端口配置
```bash
# Consul相关端口
8500  # HTTP API和UI
8501  # HTTPS API
8502  # gRPC
8600  # DNS
8300  # Server RPC
8301  # Serf LAN
8302  # Serf WAN
```

### 微服务健康检查
```bash
# API Gateway健康检查
curl http://localhost:8080/health

# User Service健康检查
curl http://localhost:8081/health

# Resume Service健康检查
curl http://localhost:8082/health

# Company Service健康检查
curl http://localhost:8083/health

# Notification Service健康检查
curl http://localhost:8084/health

# Template Service健康检查
curl http://localhost:8085/health

# Statistics Service健康检查
curl http://localhost:8086/health

# Banner Service健康检查
curl http://localhost:8087/health

# AI服务健康检查
curl http://localhost:8206/health

# 数据库连接检查
mysql -u root -e "SELECT 1;"
psql -d jobfirst_vector -c "SELECT 1;"
redis-cli ping
curl http://localhost:7474
```

### Consul服务发现检查
```bash
# 检查已注册服务
curl -s http://localhost:8500/v1/agent/services | jq 'keys'

# 检查健康检查状态
curl -s http://localhost:8500/v1/health/state/any | jq '.[] | {Service: .ServiceName, Status: .Status}'

# 检查集群状态
curl -s http://localhost:8500/v1/status/leader
```

### AI服务特殊管理

#### AI服务认证和成本控制
AI服务是一个特殊服务，需要经过认证后才能使用，因为它会消耗经费：

**特殊标签**:
- `authenticated` - 需要认证
- `cost-controlled` - 成本控制
- `external-api` - 使用外部API
- `deepseek` - DeepSeek集成
- `ollama` - Ollama集成

**元数据信息**:
```json
{
  "service_type": "ai",
  "framework": "sanic", 
  "language": "python",
  "requires_auth": "true",
  "cost_controlled": "true",
  "external_apis": "deepseek,ollama",
  "database": "postgresql",
  "usage_limits": "daily,monthly",
  "billing_enabled": "true"
}
```

#### AI服务健康监控脚本
使用专门的AI服务健康监控脚本：

```bash
# 运行AI服务健康监控
./scripts/ai-service-health-monitor.sh
```

**监控内容包括**:
- ✅ AI服务基础健康检查
- 🔐 JWT认证机制验证
- 💰 用户使用限制检查
- 💸 成本控制机制验证
- 🤖 Ollama服务状态
- 🌐 DeepSeek API配置
- 🗄️ PostgreSQL连接状态
- ⚡ 性能指标监控
- 📊 Consul注册状态
- 📝 日志错误检查

#### AI服务Consul注册管理
使用专门的Python脚本管理AI服务注册：

```bash
# 注册AI服务到Consul（包含认证和成本控制信息）
python3 scripts/ai-service-consul-register.py
```

**注册功能**:
- 自动健康检查验证
- 添加认证元数据
- 添加成本控制元数据
- 设置特殊服务标签
- 配置外部API依赖信息

#### AI服务使用限制
```bash
# 检查AI服务使用限制
curl -X POST http://localhost:8081/api/v1/usage/check \
  -H "Content-Type: application/json" \
  -d '{"user_id": 1, "service_type": "ai_analysis"}'

# 记录AI服务使用
curl -X POST http://localhost:8081/api/v1/usage/record \
  -H "Content-Type: application/json" \
  -d '{"user_id": 1, "service_type": "ai_analysis", "cost": 0.01}'
```

#### AI服务认证流程
1. **用户认证**: 验证JWT Token
2. **权限检查**: 确认用户有AI服务访问权限
3. **使用限制**: 检查每日/每月使用限制
4. **成本控制**: 验证用户账户余额
5. **服务调用**: 执行AI分析任务
6. **使用记录**: 记录使用情况和成本

## 🐛 故障排除

### 常见问题

#### 0. User Service架构说明
**问题**: User Service和Company Service的职责分工
**说明**: 
- **User Service (8081)**: 专门负责用户认证、权限管理、角色管理
- **Company Service (8083)**: 专门负责企业管理、企业信息维护
- 两个服务职责明确分离，User Service不再承担企业管理功能

**解决方案**: 确保User Service和Company Service分别启动，各自处理对应的业务逻辑

#### 1. 端口冲突
```bash
# 查看端口占用
lsof -i :端口号

# 停止占用进程
kill -9 PID
```

#### 2. AI服务启动失败
```bash
# 检查虚拟环境
cd backend/internal/ai-service
source venv/bin/activate
python --version

# 检查依赖
pip list

# 重新安装依赖
pip install -r requirements.txt
```

#### 3. 数据库连接失败
```bash
# 检查数据库服务状态
brew services list | grep -E "(mysql|postgresql|redis|neo4j)"

# 重启数据库服务
brew services restart mysql
brew services restart postgresql@14
brew services restart redis
brew services restart neo4j
```

#### 4. PostgreSQL触发器错误
```bash
# 修复resume_vectors表
psql -d jobfirst_vector -c "
ALTER TABLE resume_vectors ADD COLUMN IF NOT EXISTS updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP;
UPDATE resume_vectors SET updated_at = CURRENT_TIMESTAMP WHERE updated_at IS NULL;
"
```

## 📝 日志管理

### 日志文件位置
- **API Gateway**: `logs/api-gateway.log`
- **AI Service**: `logs/ai-service.log`
- **User Service**: `logs/user-service.log`
- **Resume Service**: `logs/resume-service.log`

### 查看日志
```bash
# 实时查看日志
tail -f logs/api-gateway.log
tail -f logs/ai-service.log

# 查看错误日志
grep -i error logs/*.log
```

## 🔄 服务重启

### 单个服务重启
```bash
# 重启API Gateway
pkill -f "basic-server"
cd backend && go run cmd/basic-server/main.go &

# 重启AI服务
pkill -f "ai_service.py"
cd backend/internal/ai-service && source venv/bin/activate && python ai_service.py &
```

### 全部服务重启
```bash
./scripts/start-microservices.sh restart
```

## 🚀 生产环境部署

### Docker部署
```bash
# 构建镜像
docker-compose build

# 启动服务
docker-compose up -d

# 查看状态
docker-compose ps
```

### 环境变量配置
```bash
# AI服务环境变量
export AI_SERVICE_PORT=8206
export POSTGRES_HOST=localhost
export POSTGRES_USER=szjason72
export POSTGRES_DB=jobfirst_vector
export OLLAMA_HOST=http://127.0.0.1:11434
```

## 📈 性能优化

### 数据库优化
- **MySQL**: 配置连接池，添加索引
- **PostgreSQL**: 启用向量扩展，优化查询
- **Redis**: 配置内存策略，启用持久化
- **Neo4j**: 优化Cypher查询，配置缓存

### 服务优化
- **API Gateway**: 启用负载均衡，配置缓存
- **AI Service**: 优化模型加载，启用批处理
- **微服务**: 配置健康检查，启用熔断器

## 🔐 安全配置

### 数据库安全
- 配置强密码
- 限制网络访问
- 启用SSL连接
- 定期备份数据

### 服务安全
- 配置JWT认证
- 启用HTTPS
- 配置防火墙
- 监控异常访问

## 📚 开发指南

### 添加新服务
1. 在`backend/internal/`下创建服务目录
2. 实现服务逻辑
3. 配置服务发现
4. 更新启动脚本
5. 添加健康检查

### API开发规范
- 使用RESTful API设计
- 统一错误处理
- 添加API文档
- 实现版本控制

### 数据库开发规范
- 使用迁移脚本
- 添加数据验证
- 实现软删除
- 配置审计日志

## 🎯 最佳实践

### 微服务时序控制
- **严格依赖关系**: 确保服务按正确顺序启动
- **健康检查**: 每个服务启动后必须通过健康检查
- **依赖等待**: 启动服务前检查依赖服务状态
- **超时控制**: 设置合理的启动超时时间
- **回滚机制**: 启动失败时能够回滚到安全状态

### 服务设计
- 单一职责原则
- 无状态设计
- 异步通信
- 容错处理

### 认证授权设计
- **JWT令牌管理**: 统一令牌生成和验证
- **角色权限控制**: 基于RBAC的权限管理
- **服务间认证**: 确保服务间通信安全
- **会话管理**: 合理的会话超时和刷新机制

### 数据管理
- 数据一致性
- 事务处理
- 缓存策略
- 备份恢复

### 监控告警
- 健康检查
- 性能监控
- 错误追踪
- 日志分析

### 安全最佳实践
- **最小权限原则**: 服务只获得必要的权限
- **网络隔离**: 服务间通信使用内网
- **数据加密**: 敏感数据加密存储和传输
- **审计日志**: 记录所有关键操作

## 🔧 开发团队服务详细说明

### Dev Team Service (8088) - 开发团队协作管理服务

**功能职责**:
- 开发团队成员管理
- 团队角色权限控制
- SSH密钥管理
- 操作审计和日志记录
- 服务器访问级别管理
- 代码模块访问控制
- 数据库访问权限管理
- 服务重启权限控制

**API端点**:
```
# 管理员权限
GET  /api/v1/dev-team/admin/members         # 获取团队成员列表
POST /api/v1/dev-team/admin/members         # 添加团队成员
PUT  /api/v1/dev-team/admin/members/:id     # 更新团队成员
DELETE /api/v1/dev-team/admin/members/:id   # 删除团队成员
GET  /api/v1/dev-team/admin/logs            # 获取操作日志
GET  /api/v1/dev-team/admin/stats           # 获取团队统计
GET  /api/v1/dev-team/admin/permissions     # 获取权限配置

# 开发团队权限
GET  /api/v1/dev-team/dev/profile           # 获取个人资料
PUT  /api/v1/dev-team/dev/profile           # 更新个人资料
GET  /api/v1/dev-team/dev/my-logs           # 获取个人日志
GET  /api/v1/dev-team/dev/status            # 获取团队状态

# 公开接口
GET  /api/v1/dev-team/public/check-membership/:user_id  # 检查成员身份
GET  /api/v1/dev-team/public/roles          # 获取角色列表
```

**团队角色权限矩阵**:
- `super_admin`: 超级管理员 - 拥有所有权限
- `system_admin`: 系统管理员 - 系统管理权限
- `dev_lead`: 开发负责人 - 项目管理和部署权限
- `frontend_dev`: 前端开发 - 前端代码访问权限
- `backend_dev`: 后端开发 - 后端代码和数据库访问权限
- `qa_engineer`: 测试工程师 - 测试执行和日志查看权限
- `guest`: 访客用户 - 无特殊权限

**健康检查**: `GET /health`

### 用户服务分离说明

**业务用户服务 (User Service - 8081)**:
- 用途: 业务系统的用户管理
- 功能: 简历权限、利益相关方管理、评论分享、积分系统
- 用户类型: 最终业务用户（求职者、企业等）

**开发团队服务 (Dev Team Service - 8088)**:
- 用途: 开发调试和远程协同开发
- 功能: 开发团队权限管理、SSH密钥管理、操作审计
- 用户类型: 开发团队成员（super_admin, system_admin, dev_lead, frontend_dev, backend_dev, qa_engineer, guest）

**启动命令**:
```bash
# 启动开发团队服务
cd backend/internal/dev-team-service
go run main.go
```

---

**维护人员**: AI Assistant  
**联系方式**: 通过项目文档  
**更新频率**: 随架构变更更新
