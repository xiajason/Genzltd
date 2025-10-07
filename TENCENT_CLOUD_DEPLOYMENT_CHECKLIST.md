# 腾讯云应用服务部署条件检查清单

**检查时间**: 2025年10月7日  
**目标**: 在腾讯云部署5个应用服务（双AI服务、LoomaCRM、Zervigo、共享服务）

---

## 📋 部署服务清单

### **需要部署的5个服务**
1. ✅ **AI服务1** (端口8100) - 智能推荐、数据分析
2. ✅ **AI服务2** (端口8110) - 自然语言处理、智能问答
3. ⚠️ **共享服务** (端口8120) - 用户认证、数据同步
4. ⚠️ **LoomaCRM** - 客户关系管理系统
5. ⚠️ **Zervigo** - 权限管理系统

---

## ✅ 已具备的条件

### **1. AI服务代码和配置** ✅ 完整
```yaml
位置: zervigo_future/ai-services/

AI服务代码:
  - ai-service/ai_service_with_zervigo.py ✅ 主服务文件
  - ai-service/requirements.txt ✅ 依赖文件
  - ai-service/Dockerfile ✅ 容器化配置
  - ai-service/job_matching_engine.py ✅ 职位匹配引擎
  - ai-service/enhanced_job_matching_engine.py ✅ 增强匹配引擎

AI模型服务:
  - ai-models/ai_models_service.py ✅ 模型服务
  - ai-models/Dockerfile ✅ 容器化配置
  - ai-models/requirements.txt ✅ 依赖文件

Future版AI服务:
  - future-ai-gateway/future_ai_gateway.py ✅ AI网关
  - future-resume-ai/future_resume_ai.py ✅ 简历AI服务

启动脚本:
  - start-future-ai-services.sh ✅ 启动脚本
  - stop-future-ai-services.sh ✅ 停止脚本

配置文件:
  - docker-compose.yml ✅ Docker编排配置
  - .env (需要根据腾讯云环境配置)
```

### **2. LoomaCRM代码和配置** ✅ 完整
```yaml
位置: looma_crm_future/

主服务:
  - looma_crm/app.py ✅ 主应用
  - ai_services_independent/ ✅ 独立AI服务
  - requirements.txt ✅ 依赖文件

AI服务子系统:
  - ai_services_independent/ai_gateway_future/ ✅ AI网关
  - ai_services_independent/resume_ai_future/ ✅ 简历AI
  - ai_services_independent/looma_crm_future/ ✅ LoomaCRM服务

配置文件:
  - config/env.example ✅ 环境配置模板
  - docker-compose-future.yml ✅ Docker编排

启动脚本:
  - start-looma-future.sh ✅ 启动脚本
  - stop-looma-future.sh ✅ 停止脚本
  - activate_venv.sh ✅ 虚拟环境激活
```

### **3. Zervigo代码和配置** ✅ 完整
```yaml
位置: zervigo_future/backend/

认证服务:
  - cmd/unified-auth/main.go ✅ 统一认证服务 (端口8207)
  - Dockerfile ✅ 容器化配置

核心服务:
  - cmd/basic-server/ ✅ API Gateway
  - cmd/user-service/ ✅ 用户服务
  - cmd/resume-service/ ✅ 简历服务
  - cmd/company-service/ ✅ 公司服务
  - cmd/job-service/ ✅ 职位服务

配置文件:
  - docker-compose.yml ✅ Docker编排
  - configs/ ✅ 配置文件目录
```

### **4. 腾讯云基础设施** ✅ 已部署
```yaml
服务器资源:
  - CPU: 4核 ✅
  - 内存: 3.6GB ✅
  - 磁盘: 59GB (可用46GB) ✅
  - 操作系统: Ubuntu 22.04.5 LTS ✅

已部署数据库:
  - MySQL 8.0.43 ✅ (端口3306)
  - PostgreSQL 14.18 ✅ (端口5432)
  - Redis 6.0.16 ✅ (端口6379)

已部署服务:
  - Nginx ✅ (端口80)
  - Node.js服务 ✅ (端口10086)
  - Statistics Service ✅ (端口8086)
  - Template Service ✅ (端口8087)

系统工具:
  - Docker: ❌ 未安装或未启动
  - Python 3.x: 待确认
  - Go: 待确认
  - Git: 待确认
```

---

## ⚠️ 缺失或需要准备的条件

### **1. 共享服务** ⚠️ 缺失独立服务代码
```yaml
状态: ⚠️ 没有独立的共享服务代码

现状:
  - 共享服务功能分散在各个服务中
  - 没有独立的8120端口服务
  - 统一认证服务在8207端口 (Zervigo的一部分)

需要做的工作:
  1. 明确共享服务的具体功能范围
  2. 决定是否需要独立部署，还是复用现有服务
  3. 如果独立部署，需要：
     - 创建共享服务代码
     - 配置端口8120
     - 定义服务接口和功能

建议方案:
  方案A: 复用Zervigo统一认证服务 (端口8207)
    - 优点: 代码已存在，功能完整
    - 缺点: 端口不是8120
  
  方案B: 创建新的共享服务 (端口8120)
    - 优点: 符合架构规划
    - 缺点: 需要额外开发

推荐: 方案A，复用现有统一认证服务 ✅
```

### **2. Docker环境** ⚠️ 需要确认
```yaml
状态: ❌ Docker未安装或未启动

检查项:
  - Docker是否已安装: 待确认
  - Docker是否正在运行: 待确认
  - Docker Compose是否已安装: 待确认

需要做的工作:
  如果Docker未安装:
    1. 安装Docker Engine
    2. 安装Docker Compose
    3. 启动Docker服务
    4. 配置Docker用户权限

  如果Docker已安装但未启动:
    1. 启动Docker服务: sudo systemctl start docker
    2. 设置开机自启: sudo systemctl enable docker

建议: 使用原生部署，避免Docker额外资源消耗 ✅
```

### **3. Python环境** ⚠️ 需要确认
```yaml
状态: 待确认Python版本和虚拟环境

检查项:
  - Python版本: 需要Python 3.11+ (AI服务要求)
  - pip版本: 最新版本
  - 虚拟环境工具: venv或virtualenv

需要安装的Python包:
  AI服务依赖:
    - sanic==23.12.1
    - psycopg2-binary==2.9.9
    - transformers>=4.30.2
    - torch==2.0.1
    - sentence-transformers==2.2.2
    - 等 (见requirements.txt)

  LoomaCRM依赖:
    - sanic
    - psycopg2
    - 等 (见requirements.txt)

需要做的工作:
  1. 检查Python版本: python3 --version
  2. 如果版本<3.11，安装Python 3.11+
  3. 为每个服务创建虚拟环境
  4. 安装依赖包
```

### **4. Go环境** ⚠️ 需要确认 (Zervigo需要)
```yaml
状态: 待确认Go版本

检查项:
  - Go版本: 需要Go 1.23+ (Zervigo要求)
  - Go环境变量: GOPATH, GOROOT
  - Go模块: go mod

需要做的工作:
  1. 检查Go版本: go version
  2. 如果未安装，安装Go 1.23+
  3. 配置Go环境变量
  4. 下载Zervigo依赖: go mod download
```

### **5. 环境配置文件** ⚠️ 需要创建
```yaml
状态: 需要根据腾讯云环境创建配置文件

需要创建的配置:
  AI服务配置 (.env):
    - DB_HOST=localhost (腾讯云本地)
    - DB_PORT=5432
    - DB_USER=postgres
    - DB_PASSWORD=<腾讯云数据库密码>
    - DB_NAME=jobfirst_vector
    - MYSQL_HOST=localhost
    - MYSQL_PORT=3306
    - MYSQL_USER=root
    - MYSQL_PASSWORD=<腾讯云数据库密码>
    - REDIS_HOST=localhost
    - REDIS_PORT=6379
    - JWT_SECRET=<设置密钥>
    - ZERVIGO_AUTH_URL=http://localhost:8207

  LoomaCRM配置 (.env):
    - APP_HOST=0.0.0.0
    - APP_PORT=8700
    - ZERVIGO_AUTH_URL=http://localhost:8207
    - 数据库连接配置 (同上)

  Zervigo配置:
    - DATABASE_URL=<MySQL连接字符串>
    - JWT_SECRET=<设置密钥>
    - AUTH_SERVICE_PORT=8207
```

### **6. AI模型文件** ⚠️ 需要下载
```yaml
状态: AI模型文件可能需要下载

AI模型需求:
  - sentence-transformers模型
  - transformers模型
  - 中文NLP模型

模型存储:
  - 模型缓存目录: /app/cache 或 ~/.cache/huggingface
  - 预计大小: 2-5GB

需要做的工作:
  方案A: 使用轻量模型
    - 选择小型模型 (100-500MB)
    - 减少内存占用
    - 首次启动时自动下载

  方案B: 使用外部AI服务
    - 集成DeepSeek API
    - 无需本地模型
    - 成本可控

推荐: 方案A，使用轻量模型 ✅
```

### **7. 数据库初始化** ⚠️ 需要执行
```yaml
状态: 需要初始化数据库表结构和数据

数据库初始化任务:
  MySQL (jobfirst数据库):
    - 用户表
    - 角色表
    - 权限表
    - 业务数据表

  PostgreSQL (jobfirst_vector数据库):
    - 向量表
    - pgvector扩展

需要做的工作:
  1. 检查数据库是否已初始化
  2. 如果未初始化，运行初始化脚本
  3. 创建必要的数据库用户和权限
  4. 插入初始数据
```

### **8. 端口开放** ⚠️ 需要配置
```yaml
状态: 需要确认端口是否开放

需要开放的端口:
  应用服务端口:
    - 8100 (AI服务1)
    - 8110 (AI服务2)
    - 8120 (共享服务) 或 8207 (统一认证)
    - 8700 (LoomaCRM)
    - 8207 (Zervigo统一认证)
    - 8080 (Zervigo基础服务)

  数据库端口 (已开放):
    - 3306 (MySQL) ✅
    - 5432 (PostgreSQL) ✅
    - 6379 (Redis) ✅

需要做的工作:
  1. 检查腾讯云安全组规则
  2. 开放应用服务端口
  3. 配置本地防火墙规则
```

---

## 📊 缺失条件总结

### **严重缺失** ❌
1. **共享服务独立代码** - 没有独立的8120端口服务
   - 建议: 复用Zervigo统一认证服务 (8207端口)

### **需要确认** ⚠️
1. **Docker环境** - 需要确认是否安装和启动
   - 建议: 使用原生部署，避免Docker资源消耗

2. **Python环境** - 需要确认版本和依赖
   - 需要: Python 3.11+, pip, 虚拟环境

3. **Go环境** - Zervigo需要
   - 需要: Go 1.23+

4. **AI模型文件** - 可能需要下载
   - 建议: 使用轻量模型或外部API

5. **环境配置文件** - 需要创建
   - 需要: .env文件，配置数据库连接等

6. **数据库初始化** - 需要确认和执行
   - 需要: 初始化表结构和数据

7. **端口开放** - 需要配置安全组
   - 需要: 开放8100, 8110, 8120/8207等端口

---

## 🚀 推荐部署方案

### **方案一: 原生部署** ✅ 推荐
```yaml
优点:
  - 无需Docker，资源利用率高
  - 启动速度快
  - 配置简单
  - 内存占用低

部署步骤:
  1. 确认Python和Go环境
  2. 创建虚拟环境
  3. 安装依赖
  4. 配置环境变量
  5. 初始化数据库
  6. 启动服务

预计时间: 2-3天
```

### **方案二: Docker部署**
```yaml
优点:
  - 环境隔离
  - 易于管理
  - 可移植性强

缺点:
  - 需要安装Docker
  - 资源占用较高
  - 配置相对复杂

部署步骤:
  1. 安装Docker和Docker Compose
  2. 构建镜像
  3. 配置docker-compose.yml
  4. 启动容器

预计时间: 3-4天
```

---

## 🎯 下一步行动计划

### **立即执行** (SSH连接腾讯云)
1. ✅ 连接腾讯云服务器
2. ⚠️ 检查Python版本和环境
3. ⚠️ 检查Go版本和环境
4. ⚠️ 检查Docker状态
5. ⚠️ 检查数据库状态和初始化情况
6. ⚠️ 检查已开放的端口

### **准备阶段** (1天)
1. 创建虚拟环境
2. 安装Python依赖
3. 安装Go依赖 (如需Zervigo)
4. 准备环境配置文件
5. 初始化数据库
6. 下载AI模型 (如需要)

### **部署阶段** (2-3天)
1. 第一批: Zervigo统一认证服务 (8207)
2. 第二批: AI服务1和AI服务2 (8100, 8110)
3. 第三批: LoomaCRM (8700)

### **测试和优化** (1天)
1. 服务健康检查
2. 接口测试
3. 性能测试
4. 资源监控

---

**🎯 结论**: 代码和配置基本完整，主要需要确认和准备Python/Go环境、数据库初始化和环境配置文件。共享服务建议复用Zervigo统一认证服务。推荐使用原生部署方式，预计2-3天可完成部署！

---
*检查时间: 2025年10月7日*  
*检查结果: 代码完整 ✅，环境需确认 ⚠️*  
*推荐方案: 原生部署 ✅*  
*预计时间: 2-3天*
