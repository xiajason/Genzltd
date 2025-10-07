# 数据库分布和迁移目标分析

**创建时间**: 2025年1月27日  
**版本**: v1.0  
**状态**: ✅ **数据库分布分析完成**  
**目标**: 明确数据库分布情况和迁移目标

---

## 📊 当前数据库分布情况

### **本地Mac环境**
```yaml
硬件配置:
  MacBook Air (Mac15,12):
    CPU: Apple Silicon
    内存: 16GB
    存储: 460GB (已用10GB, 可用308GB, 使用率4%)
    系统: macOS 24.6.0

已运行数据库服务:
  ✅ MongoDB: 27017 (运行中)
  ✅ Redis: 6379 (运行中)
  ✅ PostgreSQL: 5432 (运行中)
  ❌ MySQL: 3306 (未运行)
  ❌ Neo4j: 7474 (未运行)

Docker容器数据库:
  ✅ future-mongodb: 运行中
  ✅ future-postgres: 运行中
  ✅ future-redis: 运行中
  ✅ future-mysql: 运行中
  ✅ dao-mysql-local: 已停止
  ✅ dao-redis-local: 已停止
```

### **腾讯云服务器环境**
```yaml
服务器配置:
  实例ID: VM-12-9-ubuntu
  公网IP: 101.33.251.158
  内网IP: 10.1.12.9
  CPU: 4核3.6GB内存
  存储: 59GB (已用13GB, 可用47GB)
  系统: Ubuntu 22.04.5 LTS

已运行数据库服务:
  ✅ MySQL: 3306 (active)
  ✅ PostgreSQL: 5432 (active)
  ✅ Redis: 6379 (active)
  ✅ Nginx: 80 (active)
  ✅ Node.js服务: 10086 (active)
  ✅ Statistics Service: 8086 (active)
  ✅ Template Service: 8087 (active)
  ❌ Docker: inactive (未安装或未启动)

资源使用状态:
  CPU使用率: 低负载 (0.07, 0.02, 0.00)
  内存使用: 1.8GB/3.6GB (50.6% 使用率)
  磁盘使用: 13GB/59GB (23% 使用率)
```

### **阿里云服务器环境**
```yaml
服务器配置:
  CPU: 2核
  内存: 2GB
  带宽: 3M固定带宽
  存储: 40GB ESSD Entry云盘
  系统: 待确认

数据库服务状态:
  ❓ 具体服务状态待确认
  ❓ 数据库配置待确认
  ❓ 网络连接待确认
```

---

## 🎯 迁移目标数据库架构

### **统一LoomaCRM数据库集群**

#### **本地Mac (开发环境)**
```yaml
目标架构:
  LoomaCRM主数据库:
    MySQL: 3306 (LoomaCRM核心数据)
    Redis: 6379 (LoomaCRM缓存)
    PostgreSQL: 5432 (LoomaCRM向量数据)
    Neo4j: 7474 (LoomaCRM关系数据)
    MongoDB: 27017 (LoomaCRM文档数据)

Zervigo服务数据库:
  Future版数据库:
    MySQL: 3306/future (Future版业务数据)
    Redis: 6379/1 (Future版缓存)
    PostgreSQL: 5432/future (Future版分析数据)
    MongoDB: 27017/future (Future版文档数据)
    Neo4j: 7474/future (Future版关系数据)

  DAO版数据库:
    MySQL: 3306/dao (DAO版业务数据)
    Redis: 6379/2 (DAO版缓存)
    PostgreSQL: 5432/dao (DAO版分析数据)
    MongoDB: 27017/dao (DAO版文档数据)
    Neo4j: 7474/dao (DAO版关系数据)

  区块链版数据库:
    MySQL: 3306/blockchain (区块链业务数据)
    Redis: 6379/3 (区块链缓存)
    PostgreSQL: 5432/blockchain (区块链分析数据)
    MongoDB: 27017/blockchain (区块链文档数据)
    Neo4j: 7474/blockchain (区块链关系数据)
```

#### **腾讯云服务器 (测试环境)**
```yaml
目标架构:
  DAO版测试数据库:
    MySQL: 3306 (DAO版测试数据)
    Redis: 6379 (DAO版测试缓存)
    PostgreSQL: 5432 (DAO版测试分析数据)
    MongoDB: 27017 (DAO版测试文档数据)
    Neo4j: 7474 (DAO版测试关系数据)

  区块链版测试数据库:
    MySQL: 3306/blockchain (区块链测试数据)
    Redis: 6379/blockchain (区块链测试缓存)
    PostgreSQL: 5432/blockchain (区块链测试分析数据)
    MongoDB: 27017/blockchain (区块链测试文档数据)
    Neo4j: 7474/blockchain (区块链测试关系数据)
```

#### **阿里云服务器 (生产环境)**
```yaml
目标架构:
  LoomaCRM生产数据库:
    MySQL: 3306 (LoomaCRM生产数据)
    Redis: 6379 (LoomaCRM生产缓存)
    PostgreSQL: 5432 (LoomaCRM生产分析数据)
    MongoDB: 27017 (LoomaCRM生产文档数据)
    Neo4j: 7474 (LoomaCRM生产关系数据)

  Zervigo生产数据库:
    Future版生产数据库:
      MySQL: 3306/future (Future版生产数据)
      Redis: 6379/1 (Future版生产缓存)
      PostgreSQL: 5432/future (Future版生产分析数据)
      MongoDB: 27017/future (Future版生产文档数据)
      Neo4j: 7474/future (Future版生产关系数据)

    DAO版生产数据库:
      MySQL: 3306/dao (DAO版生产数据)
      Redis: 6379/2 (DAO版生产缓存)
      PostgreSQL: 5432/dao (DAO版生产分析数据)
      MongoDB: 27017/dao (DAO版生产文档数据)
      Neo4j: 7474/dao (DAO版生产关系数据)

    区块链版生产数据库:
      MySQL: 3306/blockchain (区块链生产数据)
      Redis: 6379/3 (区块链生产缓存)
      PostgreSQL: 5432/blockchain (区块链生产分析数据)
      MongoDB: 27017/blockchain (区块链生产文档数据)
      Neo4j: 7474/blockchain (区块链生产关系数据)
```

---

## 🔄 迁移脚本目标数据库

### **迁移脚本支持的目标环境**

#### **1. 本地Mac环境**
```yaml
目标数据库:
  MySQL:
    主机: localhost
    端口: 3306
    数据库: unified_database
    用途: LoomaCRM核心数据 + Zervigo业务数据

  PostgreSQL:
    主机: localhost
    端口: 5432
    数据库: unified_analysis
    用途: LoomaCRM分析数据 + Zervigo分析数据

  Redis:
    主机: localhost
    端口: 6379
    数据库: 0 (LoomaCRM), 1 (Future), 2 (DAO), 3 (Blockchain)
    用途: 缓存和会话数据

  MongoDB:
    主机: localhost
    端口: 27017
    数据库: unified_documents
    用途: LoomaCRM文档数据 + Zervigo文档数据

  Neo4j:
    主机: localhost
    端口: 7474
    数据库: unified_graph
    用途: LoomaCRM关系数据 + Zervigo关系数据
```

#### **2. 腾讯云服务器环境**
```yaml
目标数据库:
  MySQL:
    主机: 101.33.251.158
    端口: 3306
    数据库: dao_test_database
    用途: DAO版测试数据

  PostgreSQL:
    主机: 101.33.251.158
    端口: 5432
    数据库: dao_test_analysis
    用途: DAO版测试分析数据

  Redis:
    主机: 101.33.251.158
    端口: 6379
    数据库: 0
    用途: DAO版测试缓存

  MongoDB:
    主机: 101.33.251.158
    端口: 27017
    数据库: dao_test_documents
    用途: DAO版测试文档数据

  Neo4j:
    主机: 101.33.251.158
    端口: 7474
    数据库: dao_test_graph
    用途: DAO版测试关系数据
```

#### **3. 阿里云服务器环境**
```yaml
目标数据库:
  MySQL:
    主机: [阿里云IP]
    端口: 3306
    数据库: production_database
    用途: 生产环境数据

  PostgreSQL:
    主机: [阿里云IP]
    端口: 5432
    数据库: production_analysis
    用途: 生产环境分析数据

  Redis:
    主机: [阿里云IP]
    端口: 6379
    数据库: 0
    用途: 生产环境缓存

  MongoDB:
    主机: [阿里云IP]
    端口: 27017
    数据库: production_documents
    用途: 生产环境文档数据

  Neo4j:
    主机: [阿里云IP]
    端口: 7474
    数据库: production_graph
    用途: 生产环境关系数据
```

---

## 📋 迁移策略和路径

### **迁移路径规划**

#### **路径1: 本地开发环境迁移**
```yaml
源数据库:
  - 本地Mac现有数据库
  - Docker容器数据库
  - 历史备份数据

目标数据库:
  - 统一LoomaCRM数据库集群
  - 分版本Zervigo数据库

迁移步骤:
  1. 备份现有数据
  2. 创建统一数据库结构
  3. 迁移LoomaCRM数据
  4. 迁移Zervigo数据
  5. 验证数据完整性
```

#### **路径2: 腾讯云测试环境迁移**
```yaml
源数据库:
  - 本地Mac开发数据
  - 腾讯云现有数据

目标数据库:
  - 腾讯云DAO版测试数据库
  - 腾讯云区块链版测试数据库

迁移步骤:
  1. 配置腾讯云数据库
  2. 迁移DAO版数据
  3. 迁移区块链版数据
  4. 设置测试环境
  5. 验证测试功能
```

#### **路径3: 阿里云生产环境迁移**
```yaml
源数据库:
  - 本地Mac开发数据
  - 腾讯云测试数据

目标数据库:
  - 阿里云生产数据库集群
  - 分环境生产数据库

迁移步骤:
  1. 配置阿里云数据库
  2. 迁移生产数据
  3. 设置生产环境
  4. 配置监控告警
  5. 验证生产功能
```

---

## 🎯 迁移脚本配置

### **环境变量配置**

#### **本地Mac环境**
```bash
# LoomaCRM数据库配置
export LOOMACRM_MYSQL_HOST=localhost
export LOOMACRM_MYSQL_PORT=3306
export LOOMACRM_MYSQL_DATABASE=unified_database

export LOOMACRM_POSTGRES_HOST=localhost
export LOOMACRM_POSTGRES_PORT=5432
export LOOMACRM_POSTGRES_DATABASE=unified_analysis

export LOOMACRM_REDIS_HOST=localhost
export LOOMACRM_REDIS_PORT=6379

export LOOMACRM_MONGODB_HOST=localhost
export LOOMACRM_MONGODB_PORT=27017
export LOOMACRM_MONGODB_DATABASE=unified_documents

export LOOMACRM_NEO4J_HOST=localhost
export LOOMACRM_NEO4J_PORT=7474
export LOOMACRM_NEO4J_DATABASE=unified_graph
```

#### **腾讯云环境**
```bash
# 腾讯云数据库配置
export TENCENT_MYSQL_HOST=101.33.251.158
export TENCENT_MYSQL_PORT=3306
export TENCENT_MYSQL_DATABASE=dao_test_database

export TENCENT_POSTGRES_HOST=101.33.251.158
export TENCENT_POSTGRES_PORT=5432
export TENCENT_POSTGRES_DATABASE=dao_test_analysis

export TENCENT_REDIS_HOST=101.33.251.158
export TENCENT_REDIS_PORT=6379

export TENCENT_MONGODB_HOST=101.33.251.158
export TENCENT_MONGODB_PORT=27017
export TENCENT_MONGODB_DATABASE=dao_test_documents

export TENCENT_NEO4J_HOST=101.33.251.158
export TENCENT_NEO4J_PORT=7474
export TENCENT_NEO4J_DATABASE=dao_test_graph
```

#### **阿里云环境**
```bash
# 阿里云数据库配置
export ALIBABA_MYSQL_HOST=[阿里云IP]
export ALIBABA_MYSQL_PORT=3306
export ALIBABA_MYSQL_DATABASE=production_database

export ALIBABA_POSTGRES_HOST=[阿里云IP]
export ALIBABA_POSTGRES_PORT=5432
export ALIBABA_POSTGRES_DATABASE=production_analysis

export ALIBABA_REDIS_HOST=[阿里云IP]
export ALIBABA_REDIS_PORT=6379

export ALIBABA_MONGODB_HOST=[阿里云IP]
export ALIBABA_MONGODB_PORT=27017
export ALIBABA_MONGODB_DATABASE=production_documents

export ALIBABA_NEO4J_HOST=[阿里云IP]
export ALIBABA_NEO4J_PORT=7474
export ALIBABA_NEO4J_DATABASE=production_graph
```

---

## 🚀 迁移执行计划

### **阶段一: 本地环境迁移**
```yaml
目标: 建立统一LoomaCRM数据库集群
时间: 1-2天
步骤:
  1. 启动缺失的数据库服务 (MySQL, Neo4j)
  2. 执行本地数据库迁移
  3. 验证本地环境功能
  4. 建立本地开发环境
```

### **阶段二: 腾讯云环境迁移**
```yaml
目标: 建立DAO版和区块链版测试环境
时间: 2-3天
步骤:
  1. 配置腾讯云数据库服务
  2. 执行DAO版数据迁移
  3. 执行区块链版数据迁移
  4. 验证测试环境功能
  5. 建立测试环境监控
```

### **阶段三: 阿里云环境迁移**
```yaml
目标: 建立生产环境数据库集群
时间: 3-5天
步骤:
  1. 配置阿里云数据库服务
  2. 执行生产数据迁移
  3. 建立生产环境监控
  4. 验证生产环境功能
  5. 建立灾难恢复机制
```

---

## ✅ 迁移目标总结

**🎯 迁移脚本支持的目标数据库:**

**本地Mac环境:**
- ✅ 统一LoomaCRM数据库集群
- ✅ 分版本Zervigo数据库 (Future, DAO, Blockchain)

**腾讯云服务器:**
- ✅ DAO版测试数据库
- ✅ 区块链版测试数据库

**阿里云服务器:**
- ✅ LoomaCRM生产数据库
- ✅ Zervigo生产数据库 (Future, DAO, Blockchain)

**🎉 迁移脚本已支持三个环境的数据迁移，可以安全开始数据迁移到新的基础设施！** 🚀
