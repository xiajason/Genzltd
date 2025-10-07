# 多版本数据库命名规范计划

**创建时间**: 2025年1月28日  
**版本**: v1.0  
**目标**: 制定清晰、一致的数据库命名规范，支持多版本完全隔离架构  
**状态**: 📋 命名规范制定完成

---

## 🎯 命名规范设计原则

### **核心原则**
1. **版本隔离**: 每个版本有独立的命名空间
2. **功能清晰**: 数据库名称体现其功能用途
3. **层次分明**: 主数据库、功能数据库、专项数据库分层
4. **易于管理**: 运维人员能够快速识别和管理
5. **扩展友好**: 支持未来版本和数据库的扩展

---

## 📊 完整数据库命名规范

### **1. 版本前缀规范**
```yaml
版本标识:
  future: "f" (Future版)
  dao: "d" (DAO版)
  blockchain: "b" (区块链版)
  
示例:
  - future_mysql → f_mysql
  - dao_postgres → d_postgres
  - blockchain_redis → b_redis
```

### **2. 数据库类型标识**
```yaml
数据库类型标识:
  mysql: "mysql" (主数据库)
  postgres: "pg" (PostgreSQL)
  redis: "redis" (缓存)
  neo4j: "neo4j" (图数据库)
  mongodb: "mongo" (文档数据库)
  elasticsearch: "es" (搜索引擎)
  weaviate: "weaviate" (向量数据库)
  sqlite: "sqlite" (本地数据库)
  ai_service: "ai" (AI服务数据库)
  dao_system: "dao" (DAO系统数据库)
  enterprise_credit: "credit" (企业信用数据库)
```

### **3. 完整命名规范表**

| 数据库类型 | Future版 | DAO版 | 区块链版 | 容器名称 | 端口 | 用途 |
|------------|----------|-------|----------|----------|------|------|
| **MySQL** | `f_mysql` | `d_mysql` | `b_mysql` | `f-mysql` | 3306/3307/3308 | 主数据库 |
| **PostgreSQL** | `f_pg` | `d_pg` | `b_pg` | `f-postgres` | 5432/5433/5434 | 向量数据库 |
| **Redis** | `f_redis` | `d_redis` | `b_redis` | `f-redis` | 6379/6380/6381 | 缓存数据库 |
| **Neo4j** | `f_neo4j` | `d_neo4j` | `b_neo4j` | `f-neo4j` | 7474/7475/7476 | 图数据库 |
| **MongoDB** | `f_mongo` | `d_mongo` | `b_mongo` | `f-mongodb` | 27017/27018/27019 | 文档数据库 |
| **Elasticsearch** | `f_es` | `d_es` | `b_es` | `f-elasticsearch` | 9200/9201/9202 | 搜索引擎 |
| **Weaviate** | `f_weaviate` | `d_weaviate` | `b_weaviate` | `f-weaviate` | 8082/8083/8084 | 向量数据库 |
| **SQLite** | `f_sqlite` | `d_sqlite` | `b_sqlite` | 本地文件 | 本地存储 | 用户专属数据库 |
| **AI服务数据库** | `f_ai` | `d_ai` | `b_ai` | `f-ai-service-db` | 5435/5436/5437 | AI身份网络 |
| **DAO系统数据库** | `f_dao` | `d_dao` | `b_dao` | `f-dao-system-db` | 9506/9507/9508 | DAO治理 |
| **企业信用数据库** | `f_credit` | `d_credit` | `b_credit` | `f-enterprise-credit-db` | 7534/7535/7536 | 企业信用 |

---

## 🔌 端口分配规范

### **端口分配原则**
1. **版本隔离**: 每个版本使用独立的端口段
2. **功能分组**: 相同功能的数据库使用连续端口
3. **避免冲突**: 与系统常用端口保持距离
4. **易于记忆**: 端口号有规律可循
5. **扩展预留**: 为未来扩展预留端口空间

### **端口段分配**

#### **Future版端口段 (3000-3999)**
```yaml
Future版端口分配:
  主数据库端口段:
    MySQL: 3306 (主数据库)
    PostgreSQL: 5432 (向量数据库)
    Redis: 6379 (缓存数据库)
    Neo4j: 7474/7687 (图数据库)
    MongoDB: 27017 (文档数据库)
    Elasticsearch: 9200 (搜索引擎)
    Weaviate: 8082 (向量数据库)
    AI服务数据库: 5435 (AI身份网络)
    DAO系统数据库: 9506 (DAO治理)
    企业信用数据库: 7534 (企业信用)
  
  微服务端口段:
    API Gateway: 3001
    User Service: 3002
    Resume Service: 3003
    AI Service: 3004
    Data Sync Service: 3005
    MBTI Service: 3006
    Career Service: 3007
    Company Service: 3008
    Job Service: 3009
    Notification Service: 3010
```

#### **DAO版端口段 (4000-4999)**
```yaml
DAO版端口分配:
  主数据库端口段:
    MySQL: 3307 (主数据库)
    PostgreSQL: 5433 (向量数据库)
    Redis: 6380 (缓存数据库)
    Neo4j: 7475/7688 (图数据库)
    MongoDB: 27018 (文档数据库)
    Elasticsearch: 9201 (搜索引擎)
    Weaviate: 8083 (向量数据库)
    AI服务数据库: 5436 (AI身份网络)
    DAO系统数据库: 9507 (DAO治理)
    企业信用数据库: 7535 (企业信用)
  
  微服务端口段:
    API Gateway: 4001
    User Service: 4002
    DAO Service: 4003
    Governance Service: 4004
    Data Sync Service: 4005
    Voting Service: 4006
    Proposal Service: 4007
    Treasury Service: 4008
    Member Service: 4009
    Notification Service: 4010
```

#### **区块链版端口段 (5000-5999)**
```yaml
区块链版端口分配:
  主数据库端口段:
    MySQL: 3308 (主数据库)
    PostgreSQL: 5434 (向量数据库)
    Redis: 6381 (缓存数据库)
    Neo4j: 7476/7689 (图数据库)
    MongoDB: 27019 (文档数据库)
    Elasticsearch: 9202 (搜索引擎)
    Weaviate: 8084 (向量数据库)
    AI服务数据库: 5437 (AI身份网络)
    DAO系统数据库: 9508 (DAO治理)
    企业信用数据库: 7536 (企业信用)
  
  微服务端口段:
    API Gateway: 5001
    User Service: 5002
    Blockchain Service: 5003
    Smart Contract Service: 5004
    Data Sync Service: 5005
    Token Service: 5006
    Wallet Service: 5007
    Transaction Service: 5008
    Mining Service: 5009
    Notification Service: 5010
```

### **端口冲突检查表**

#### **系统保留端口 (0-1023)**
```yaml
系统保留端口:
  SSH: 22
  HTTP: 80
  HTTPS: 443
  MySQL: 3306 (系统默认)
  PostgreSQL: 5432 (系统默认)
  Redis: 6379 (系统默认)
  MongoDB: 27017 (系统默认)
  Elasticsearch: 9200 (系统默认)
  Neo4j: 7474/7687 (系统默认)
```

#### **应用端口段 (1024-65535)**
```yaml
应用端口段分配:
  开发环境: 3000-3999 (Future版)
  测试环境: 4000-4999 (DAO版)
  生产环境: 5000-5999 (区块链版)
  共享服务: 6000-6999 (监控、日志、配置)
  预留端口: 7000-7999 (未来扩展)
  特殊服务: 8000-8999 (AI服务、大模型)
  管理端口: 9000-9999 (管理界面、工具)
```

### **端口管理策略**

#### **端口分配策略**
```yaml
端口分配策略:
  1. 版本隔离: 每个版本使用独立端口段
  2. 功能分组: 相同功能使用连续端口
  3. 避免冲突: 与系统端口保持距离
  4. 易于记忆: 端口号有规律可循
  5. 扩展预留: 为未来扩展预留空间
```

#### **端口冲突解决方案**
```yaml
端口冲突解决方案:
  1. 端口检测: 部署前检测端口占用
  2. 端口映射: 使用Docker端口映射
  3. 端口转发: 使用Nginx反向代理
  4. 端口隔离: 使用Docker网络隔离
  5. 端口管理: 使用端口管理工具
```

### **端口监控和管理**

#### **端口监控**
```yaml
端口监控:
  1. 端口状态监控: 实时监控端口状态
  2. 端口使用统计: 统计端口使用情况
  3. 端口性能监控: 监控端口性能指标
  4. 端口告警: 端口异常告警
  5. 端口日志: 记录端口使用日志
```

#### **端口管理工具**
```yaml
端口管理工具:
  1. netstat: 查看端口占用
  2. lsof: 查看端口使用情况
  3. ss: 查看端口状态
  4. nmap: 端口扫描
  5. Docker: 容器端口管理
```

---

## 🏗️ 详细命名规范

### **1. 数据库名称规范**

#### **Future版数据库命名**
```yaml
Future版数据库:
  主数据库: f_mysql
  向量数据库: f_pg
  缓存数据库: f_redis
  图数据库: f_neo4j
  文档数据库: f_mongo
  搜索引擎: f_es
  向量数据库: f_weaviate
  用户专属数据库: f_sqlite
  AI服务数据库: f_ai
  DAO系统数据库: f_dao
  企业信用数据库: f_credit
```

#### **DAO版数据库命名**
```yaml
DAO版数据库:
  主数据库: d_mysql
  向量数据库: d_pg
  缓存数据库: d_redis
  图数据库: d_neo4j
  文档数据库: d_mongo
  搜索引擎: d_es
  向量数据库: d_weaviate
  用户专属数据库: d_sqlite
  AI服务数据库: d_ai
  DAO系统数据库: d_dao
  企业信用数据库: d_credit
```

#### **区块链版数据库命名**
```yaml
区块链版数据库:
  主数据库: b_mysql
  向量数据库: b_pg
  缓存数据库: b_redis
  图数据库: b_neo4j
  文档数据库: b_mongo
  搜索引擎: b_es
  向量数据库: b_weaviate
  用户专属数据库: b_sqlite
  AI服务数据库: b_ai
  DAO系统数据库: b_dao
  企业信用数据库: b_credit
```

### **2. 容器命名规范**

#### **Docker容器命名**
```yaml
容器命名规范:
  格式: {版本前缀}-{数据库类型}
  
Future版容器:
  - f-mysql
  - f-postgres
  - f-redis
  - f-neo4j
  - f-mongodb
  - f-elasticsearch
  - f-weaviate
  - f-ai-service-db
  - f-dao-system-db
  - f-enterprise-credit-db

DAO版容器:
  - d-mysql
  - d-postgres
  - d-redis
  - d-neo4j
  - d-mongodb
  - d-elasticsearch
  - d-weaviate
  - d-ai-service-db
  - d-dao-system-db
  - d-enterprise-credit-db

区块链版容器:
  - b-mysql
  - b-postgres
  - b-redis
  - b-neo4j
  - b-mongodb
  - b-elasticsearch
  - b-weaviate
  - b-ai-service-db
  - b-dao-system-db
  - b-enterprise-credit-db
```

### **3. 网络命名规范**

#### **Docker网络命名**
```yaml
网络命名规范:
  Future版网络: f-network
  DAO版网络: d-network
  区块链版网络: b-network
  共享网络: shared-network
```

### **4. 数据卷命名规范**

#### **Docker数据卷命名**
```yaml
数据卷命名规范:
  格式: {版本前缀}_{数据库类型}_data
  
Future版数据卷:
  - f_mysql_data
  - f_postgres_data
  - f_redis_data
  - f_neo4j_data
  - f_mongodb_data
  - f_elasticsearch_data
  - f_weaviate_data
  - f_ai_service_data
  - f_dao_system_data
  - f_enterprise_credit_data

DAO版数据卷:
  - d_mysql_data
  - d_postgres_data
  - d_redis_data
  - d_neo4j_data
  - d_mongodb_data
  - d_elasticsearch_data
  - d_weaviate_data
  - d_ai_service_data
  - d_dao_system_data
  - d_enterprise_credit_data

区块链版数据卷:
  - b_mysql_data
  - b_postgres_data
  - b_redis_data
  - b_neo4j_data
  - b_mongodb_data
  - b_elasticsearch_data
  - b_weaviate_data
  - b_ai_service_data
  - b_dao_system_data
  - b_enterprise_credit_data
```

---

## 🔧 实施规范

### **1. 配置文件命名**

#### **Docker Compose文件命名**
```yaml
Docker Compose文件:
  - docker-compose-future.yml (Future版)
  - docker-compose-dao.yml (DAO版)
  - docker-compose-blockchain.yml (区块链版)
  - docker-compose-shared.yml (共享服务)
```

#### **环境变量文件命名**
```yaml
环境变量文件:
  - .env.future (Future版环境变量)
  - .env.dao (DAO版环境变量)
  - .env.blockchain (区块链版环境变量)
  - .env.shared (共享服务环境变量)
```

### **2. 目录结构命名**

#### **项目目录结构**
```yaml
项目目录结构:
  /opt/jobfirst-multi-version/
  ├── future/                    # Future版目录
  │   ├── docker-compose.yml
  │   ├── .env
  │   ├── config/
  │   ├── scripts/
  │   └── data/
  ├── dao/                       # DAO版目录
  │   ├── docker-compose.yml
  │   ├── .env
  │   ├── config/
  │   ├── scripts/
  │   └── data/
  ├── blockchain/                # 区块链版目录
  │   ├── docker-compose.yml
  │   ├── .env
  │   ├── config/
  │   ├── scripts/
  │   └── data/
  └── shared/                    # 共享服务目录
      ├── docker-compose.yml
      ├── .env
      ├── monitoring/
      ├── logging/
      └── config/
```

### **3. 服务命名规范**

#### **微服务命名**
```yaml
微服务命名规范:
  Future版服务:
    - f-api-gateway
    - f-user-service
    - f-resume-service
    - f-ai-service
    - f-data-sync-service
  
  DAO版服务:
    - d-api-gateway
    - d-user-service
    - d-dao-service
    - d-governance-service
    - d-data-sync-service
  
  区块链版服务:
    - b-api-gateway
    - b-user-service
    - b-blockchain-service
    - b-smart-contract-service
    - b-data-sync-service
```

---

## 📋 命名规范实施计划

### **第一阶段：基础命名规范 (1天)**
```yaml
目标: 建立基础命名规范
行动:
  - 制定数据库命名规范
  - 制定容器命名规范
  - 制定网络命名规范
  - 制定数据卷命名规范
```

### **第二阶段：配置文件更新 (1天)**
```yaml
目标: 更新所有配置文件
行动:
  - 更新Docker Compose文件
  - 更新环境变量文件
  - 更新配置文件
  - 更新脚本文件
```

### **第三阶段：部署验证 (1天)**
```yaml
目标: 验证命名规范实施
行动:
  - 部署测试环境
  - 验证命名规范
  - 测试服务连接
  - 验证数据隔离
```

---

## 🎯 命名规范优势

### **✅ 管理优势**
1. **清晰识别**: 通过命名快速识别版本和功能
2. **易于运维**: 运维人员能够快速定位和管理
3. **扩展友好**: 支持未来版本和数据库的扩展
4. **一致性**: 统一的命名规范，减少混乱

### **✅ 技术优势**
1. **版本隔离**: 每个版本有独立的命名空间
2. **功能清晰**: 数据库名称体现其功能用途
3. **层次分明**: 主数据库、功能数据库、专项数据库分层
4. **自动化友好**: 支持自动化部署和管理

### **✅ 运维优势**
1. **快速定位**: 通过命名快速定位问题
2. **批量操作**: 支持批量管理和操作
3. **监控友好**: 支持监控和告警系统
4. **备份恢复**: 支持数据备份和恢复

---

## 📊 命名规范总结

### **核心命名规则**
```yaml
命名规则:
  版本前缀: f/d/b (future/dao/blockchain)
  数据库类型: mysql/pg/redis/neo4j/mongo/es/weaviate/sqlite/ai/dao/credit
  容器命名: {版本前缀}-{数据库类型}
  网络命名: {版本前缀}-network
  数据卷命名: {版本前缀}_{数据库类型}_data
```

### **总计命名数量**
- **数据库名称**: 33个 (11个类型 × 3个版本)
- **容器名称**: 30个 (10个容器 × 3个版本)
- **网络名称**: 4个 (3个版本网络 + 1个共享网络)
- **数据卷名称**: 30个 (10个数据卷 × 3个版本)
- **端口数量**: 93个 (31个端口 × 3个版本)

### **端口分配总结**
```yaml
端口分配总结:
  Future版: 3000-3999 (31个端口)
  DAO版: 4000-4999 (31个端口)
  区块链版: 5000-5999 (31个端口)
  共享服务: 6000-6999 (监控、日志、配置)
  预留端口: 7000-7999 (未来扩展)
  特殊服务: 8000-8999 (AI服务、大模型)
  管理端口: 9000-9999 (管理界面、工具)
```

**这套命名规范将确保多版本数据库架构的清晰管理和高效运维！** 🚀
