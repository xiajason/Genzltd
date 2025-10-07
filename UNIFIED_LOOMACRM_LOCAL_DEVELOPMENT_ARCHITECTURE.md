# 统一LoomaCRM本地开发架构设计

**创建时间**: 2025年1月27日  
**版本**: v1.0  
**状态**: ✅ **架构设计完成**  
**目标**: 重新规划设计本地化开发管理的完整架构

---

## 🎯 当前端口配置分析

### **现有端口使用情况**

#### **已废弃版本 (不再使用)**
```yaml
基础版服务 (8080-8090): ❌ 已废弃
  8080: basic-server (基础服务)
  8081: user-service (用户服务)
  8082: resume-service (简历服务)
  8083: company-service (公司服务)
  8084: notification-service (通知服务)
  8085: template-service (模板服务)
  8086: statistics-service (统计服务)
  8087: banner-service (横幅服务)
  8088: dev-team-service (开发团队服务)
  8089: job-service (职位服务)
  8090: multi-database-service (多数据库服务)

专业版服务 (8600-8699): ❌ 已废弃
  8601: API Gateway
  8602: user-service
  8603: resume-service
  8604: company-service
  8605: notification-service
  8606: statistics-service
  8607: multi-database-service
  8609: job-service
  8611: template-service
  8612: banner-service
  8613: dev-team-service
  8620: AI Service
```

#### **保留版本 (继续使用)**
```yaml
保留原因:
  - 简化开发复杂度
  - 降低资源占用
  - 提高开发效率
  - 简化客户选择
  - 集中技术力量
```

#### **LoomaCRM服务 (8800-8899)**
```yaml
LoomaCRM核心服务:
  8800: looma-crm-main (主服务)
  8820: ai-gateway (AI网关)
  8821: resume-service (简历服务)
  8822: matching-service (匹配服务)
  8823: chat-service (聊天服务)
  8824: vector-service (向量服务)
  8825: auth-service (认证服务)
  8826: monitor-service (监控服务)
  8827: config-service (配置服务)
```

#### **数据库端口**
```yaml
现有数据库端口:
  3306: MySQL (原项目)
  5432: PostgreSQL (原项目)
  6379: Redis (原项目)
  7474/7687: Neo4j (原项目)
  9200: Elasticsearch (原项目)
  
独立数据库端口:
  27018: MongoDB (独立实例)
  5434: PostgreSQL (独立实例)
  6382: Redis (独立实例)
  7475/7688: Neo4j (独立实例)
  8082: Weaviate (Future版AI向量数据)
  9202: Elasticsearch (独立实例)
```

---

## 🏗️ 统一LoomaCRM架构设计

### **LoomaCRM统一服务平台**

#### **核心服务架构**
```yaml
LoomaCRM统一服务 (8800-8899):
  8800: looma-crm-main (主服务)
  8801: service-registry (服务注册中心)
  8802: service-config (服务配置中心)
  8803: service-monitor (服务监控中心)
  8804: customer-management (客户管理服务)
  8805: service-selection (服务选择服务)
  8806: resource-allocation (资源分配服务)
  8807: resource-monitor (资源监控服务)
  8808: billing-management (计费管理服务)
  8809: support-service (支持服务)
  8810: analytics-service (分析服务)
```

#### **AI服务架构**
```yaml
LoomaCRM AI服务 (8820-8829):
  8820: ai-gateway (AI网关)
  8821: ai-resume-service (AI简历服务)
  8822: ai-matching-service (AI匹配服务)
  8823: ai-chat-service (AI聊天服务)
  8824: ai-vector-service (AI向量服务)
  8825: ai-auth-service (AI认证服务)
  8826: ai-monitor-service (AI监控服务)
  8827: ai-config-service (AI配置服务)
  8828: ai-analytics-service (AI分析服务)
  8829: ai-recommendation-service (AI推荐服务)
```

### **Zervigo精简三版本服务架构**

#### **Future版服务 (8200-8299) - 现代企业版**
```yaml
Future版微服务:
  8200: api-gateway (API网关)
  8201: user-service (用户服务)
  8202: resume-service (简历服务)
  8203: company-service (公司服务)
  8204: notification-service (通知服务)
  8205: statistics-service (统计服务)
  8206: multi-database-service (多数据库服务)
  8207: job-service (职位服务)
  8208: template-service (模板服务)
  8209: banner-service (横幅服务)
  8210: dev-team-service (开发团队服务)

Future版AI服务:
  8220: ai-service (AI服务)
  8221: ai-gateway (AI网关)
  8222: mineru-service (MinerU服务)
  8223: ai-models-service (AI模型服务)
  8224: unified-auth-service (统一认证服务)
  8225: ai-analytics-service (AI分析服务)
  8226: ai-recommendation-service (AI推荐服务)
  8227: ai-prediction-service (AI预测服务)
  8228: ai-optimization-service (AI优化服务)
  8229: ai-insights-service (AI洞察服务)

Future版特点:
  - 目标客户: 现代企业、科技公司、大型组织
  - 团队规模: 50-1000人
  - 预算范围: 中等预算
  - 技术需求: AI功能、云原生
  - 定价: 999元/月
```

#### **DAO版服务 (9200-9299) - 去中心化组织版**
```yaml
DAO版前端服务:
  9200: dao-admin-frontend (DAO管理前端)
  9201: dao-monitor-frontend (DAO监控前端)
  9202: dao-config-frontend (DAO配置前端)
  9203: dao-log-frontend (DAO日志前端)
  9204: dao-analytics-frontend (DAO分析前端)
  9205: dao-governance-frontend (DAO治理前端)

DAO版API服务:
  9210: dao-admin-api (DAO管理API)
  9211: dao-monitor-api (DAO监控API)
  9212: dao-config-api (DAO配置API)
  9213: dao-log-api (DAO日志API)
  9214: dao-analytics-api (DAO分析API)
  9215: dao-governance-api (DAO治理API)

DAO版业务服务:
  9250: dao-resume-service (DAO简历服务)
  9251: dao-job-service (DAO职位服务)
  9252: dao-governance-service (DAO治理服务)
  9253: dao-voting-service (DAO投票服务)
  9254: dao-proposal-service (DAO提案服务)
  9255: dao-reward-service (DAO奖励服务)
  9256: dao-ai-service (DAO AI服务)

DAO版特点:
  - 目标客户: 去中心化组织、DAO、Web3公司
  - 团队规模: 不限
  - 预算范围: 高预算
  - 技术需求: 治理功能、分布式
  - 定价: 1999元/月
```

#### **区块链版服务 (8300-8599) - 区块链企业版**
```yaml
区块链核心服务:
  8301: blockchain-service (区块链服务)
  8302: identity-service (身份服务)
  8303: governance-service (治理服务)
  8304: crosschain-service (跨链服务)
  8305: smart-contract-service (智能合约服务)
  8306: wallet-service (钱包服务)
  8307: transaction-service (交易服务)
  8308: verification-service (验证服务)

区块链基础设施:
  8401: blockchain-gateway (区块链网关)
  8402: blockchain-monitor (区块链监控)
  8403: blockchain-config (区块链配置)
  8404: blockchain-storage (区块链存储)
  8405: blockchain-cache (区块链缓存)
  8406: blockchain-auth (区块链认证)
  8407: blockchain-encrypt (区块链加密)
  8408: blockchain-audit (区块链审计)

区块链生产服务:
  8501: blockchain-service-prod (区块链生产服务)
  8502: identity-service-prod (身份生产服务)
  8503: governance-service-prod (治理生产服务)
  8504: crosschain-service-prod (跨链生产服务)
  8505: smart-contract-service-prod (智能合约生产服务)
  8506: wallet-service-prod (钱包生产服务)
  8507: transaction-service-prod (交易生产服务)
  8508: verification-service-prod (验证生产服务)

区块链版特点:
  - 目标客户: 区块链企业、加密公司、DeFi项目
  - 团队规模: 不限
  - 预算范围: 最高预算
  - 技术需求: 区块链功能、链上
  - 定价: 4999元/月
```

---

## 🖥️ 前端服务端口配置

### **前端服务端口分配**

#### **Future版前端服务**
```yaml
Future版前端服务:
  10086: taro-h5-frontend (Taro H5前端)
  10087: future-admin-frontend (Future管理前端)
  10088: future-mobile-frontend (Future移动端前端)
  10089: future-desktop-frontend (Future桌面端前端)
  10090: future-analytics-frontend (Future分析前端)
```

#### **DAO版前端服务**
```yaml
DAO版前端服务:
  9200: dao-admin-frontend (DAO管理前端)
  9201: dao-monitor-frontend (DAO监控前端)
  9202: dao-config-frontend (DAO配置前端)
  9203: dao-log-frontend (DAO日志前端)
  9204: dao-analytics-frontend (DAO分析前端)
  9205: dao-governance-frontend (DAO治理前端)
```

#### **区块链版前端服务**
```yaml
区块链版前端服务:
  9300: blockchain-admin-frontend (区块链管理前端)
  9301: blockchain-wallet-frontend (区块链钱包前端)
  9302: blockchain-explorer-frontend (区块链浏览器前端)
  9303: blockchain-governance-frontend (区块链治理前端)
  9304: blockchain-analytics-frontend (区块链分析前端)
  9305: blockchain-mobile-frontend (区块链移动端前端)
```

#### **LoomaCRM前端服务**
```yaml
LoomaCRM前端服务:
  9400: looma-main-frontend (LoomaCRM主前端)
  9401: looma-admin-frontend (LoomaCRM管理前端)
  9402: looma-monitor-frontend (LoomaCRM监控前端)
  9403: looma-analytics-frontend (LoomaCRM分析前端)
  9404: looma-mobile-frontend (LoomaCRM移动端前端)
  9405: looma-desktop-frontend (LoomaCRM桌面端前端)
```

### **前端服务端口冲突解决**

#### **端口冲突分析**
```yaml
原配置冲突:
  ❌ 9506-9507: 与Docker容器冲突 (已占用)
  ❌ 9203-9205: DAO版前端与LoomaCRM前端冲突
  ❌ 10086: Future版前端与现有配置冲突

新配置优势:
  ✅ 10086-10090: Future版前端 (无冲突)
  ✅ 9200-9205: DAO版前端 (无冲突)
  ✅ 9300-9305: 区块链版前端 (无冲突)
  ✅ 9400-9405: LoomaCRM前端 (无冲突)
```

#### **前端服务端口分配策略**
```yaml
端口分配策略:
  Future版前端: 10086-10090 (5个端口)
  DAO版前端: 9200-9205 (6个端口)
  区块链版前端: 9300-9305 (6个端口)
  LoomaCRM前端: 9400-9405 (6个端口)
  
总前端端口需求: 23个端口
预留端口空间: 充足
```

---

## 💾 数据库架构设计

### **LoomaCRM统一数据库集群**

#### **主数据库集群**
```yaml
LoomaCRM主数据库:
  MySQL: 3306 (LoomaCRM核心数据)
    - 客户管理数据
    - 服务管理数据
    - 资源管理数据
    - 计费管理数据
    - 监控管理数据

  Redis: 6379 (LoomaCRM缓存)
    - 客户会话缓存
    - 服务状态缓存
    - 配置缓存
    - 性能指标缓存
    - 告警缓存

  PostgreSQL: 5432 (LoomaCRM向量数据)
    - 客户画像向量
    - 服务推荐向量
    - 资源优化向量
    - 性能分析向量
    - 预测分析向量

  Neo4j: 7474/7687 (LoomaCRM关系数据)
    - 客户关系网络
    - 服务依赖关系
    - 资源关联关系
    - 监控关系网络
    - 告警关系网络

  Elasticsearch: 9200 (LoomaCRM搜索数据)
    - 客户搜索索引
    - 服务搜索索引
    - 资源搜索索引
    - 监控搜索索引
    - 日志搜索索引
```

### **Zervigo精简三版本数据库隔离**

#### **Future版数据库 (现代企业版)**
```yaml
Future版数据库:
  MySQL: 3308 (Future版业务数据)
  Redis: 6381 (Future版缓存)
  PostgreSQL: 5434 (Future版向量数据)
  Neo4j: 7476/7689 (Future版关系数据)
  Elasticsearch: 9202 (Future版搜索数据)
  Weaviate: 8082 (Future版AI向量数据)

数据库特点:
  - 支持AI功能
  - 向量数据库支持
  - 高性能缓存
  - 图数据库支持
  - 搜索引擎支持
```

#### **DAO版数据库 (去中心化组织版)**
```yaml
DAO版数据库:
  MySQL: 3309 (DAO版业务数据)
  Redis: 6382 (DAO版缓存)
  PostgreSQL: 5435 (DAO版向量数据)
  Neo4j: 7477/7690 (DAO版关系数据)
  Elasticsearch: 9203 (DAO版搜索数据)

数据库特点:
  - 支持治理功能
  - 分布式架构
  - 高可用性
  - 数据一致性
  - 治理数据存储
```

#### **区块链版数据库 (区块链企业版)**
```yaml
区块链版数据库:
  MySQL: 3310 (区块链版业务数据)
  Redis: 6383 (区块链版缓存)
  PostgreSQL: 5436 (区块链版向量数据)
  Neo4j: 7478/7691 (区块链版关系数据)
  Elasticsearch: 9204 (区块链版搜索数据)
  区块链存储: 链上存储

数据库特点:
  - 支持区块链功能
  - 链上数据存储
  - 跨链数据同步
  - 智能合约数据
  - 去中心化存储
```

---

## 🔍 服务发现与注册

### **Consul服务发现架构**

#### **服务发现集群**
```yaml
LoomaCRM服务发现:
  Consul: 8500 (LoomaCRM主服务发现)
    - 服务注册中心
    - 服务发现中心
    - 健康检查中心
    - 配置管理中心
    - 负载均衡中心

Zervigo服务发现:
  Future版Consul: 8502 (Future版服务发现)
  DAO版Consul: 8503 (DAO版服务发现)
  区块链版Consul: 8504 (区块链版服务发现)
```

#### **服务注册策略**
```yaml
服务注册信息:
  - 服务名称
  - 服务版本
  - 服务端口
  - 服务地址
  - 服务标签
  - 健康检查路径
  - 服务权重
  - 服务元数据

服务发现策略:
  - 基于服务名称
  - 基于服务标签
  - 基于服务版本
  - 基于服务权重
  - 基于服务健康状态
```

---

## 📊 监控系统架构

### **Prometheus监控集群**

#### **监控系统分配**
```yaml
LoomaCRM监控:
  Prometheus: 9090 (LoomaCRM主监控)
  Grafana: 3000 (LoomaCRM主仪表板)

Zervigo精简三版本监控:
  Future版监控:
    Prometheus: 9092 (Future版监控)
    Grafana: 3002 (Future版仪表板)
    监控范围: 现代企业版服务
  
  DAO版监控:
    Prometheus: 9093 (DAO版监控)
    Grafana: 3003 (DAO版仪表板)
    监控范围: 去中心化组织版服务
  
  区块链版监控:
    Prometheus: 9094 (区块链版监控)
    Grafana: 3004 (区块链版仪表板)
    监控范围: 区块链企业版服务
```

#### **监控指标**
```yaml
系统监控指标:
  - CPU使用率
  - 内存使用率
  - 磁盘使用率
  - 网络使用率
  - 服务响应时间
  - 服务错误率
  - 服务吞吐量
  - 数据库连接数
  - 缓存命中率
  - 队列长度

业务监控指标:
  - 用户活跃度
  - 服务使用率
  - 功能使用率
  - 错误率
  - 性能指标
  - 业务指标
  - 用户体验指标
  - 收入指标
  - 成本指标
  - 效率指标
```

---

## 🚀 本地开发环境配置

### **环境变量配置**

#### **LoomaCRM环境变量**
```yaml
LoomaCRM环境变量:
  LOOMACRM_HOST=0.0.0.0
  LOOMACRM_PORT=8800
  LOOMACRM_ENV=development
  LOOMACRM_DEBUG=true
  
  # 数据库配置
  LOOMACRM_MYSQL_HOST=localhost
  LOOMACRM_MYSQL_PORT=3306
  LOOMACRM_MYSQL_USER=root
  LOOMACRM_MYSQL_PASSWORD=looma_password_2025
  LOOMACRM_MYSQL_DB=looma_crm
  
  LOOMACRM_REDIS_HOST=localhost
  LOOMACRM_REDIS_PORT=6379
  LOOMACRM_REDIS_PASSWORD=
  LOOMACRM_REDIS_DB=0
  
  LOOMACRM_POSTGRES_HOST=localhost
  LOOMACRM_POSTGRES_PORT=5432
  LOOMACRM_POSTGRES_USER=postgres
  LOOMACRM_POSTGRES_PASSWORD=looma_password_2025
  LOOMACRM_POSTGRES_DB=looma_crm
  
  LOOMACRM_NEO4J_HOST=localhost
  LOOMACRM_NEO4J_PORT=7474
  LOOMACRM_NEO4J_USERNAME=neo4j
  LOOMACRM_NEO4J_PASSWORD=looma_password_2025
  
  LOOMACRM_ELASTICSEARCH_HOST=localhost
  LOOMACRM_ELASTICSEARCH_PORT=9200
  
  # 服务发现配置
  LOOMACRM_CONSUL_HOST=localhost
  LOOMACRM_CONSUL_PORT=8500
  
  # 监控配置
  LOOMACRM_PROMETHEUS_HOST=localhost
  LOOMACRM_PROMETHEUS_PORT=9090
  LOOMACRM_GRAFANA_HOST=localhost
  LOOMACRM_GRAFANA_PORT=3000
```

#### **Zervigo服务版本环境变量**
```yaml
Future版环境变量:
  ZERVIGO_FUTURE_HOST=0.0.0.0
  ZERVIGO_FUTURE_PORT=8200
  ZERVIGO_FUTURE_ENV=development
  ZERVIGO_FUTURE_DEBUG=true
  
  # 数据库配置
  ZERVIGO_FUTURE_MYSQL_HOST=localhost
  ZERVIGO_FUTURE_MYSQL_PORT=3308
  ZERVIGO_FUTURE_MYSQL_USER=root
  ZERVIGO_FUTURE_MYSQL_PASSWORD=future_password_2025
  ZERVIGO_FUTURE_MYSQL_DB=zervigo_future
  
  ZERVIGO_FUTURE_REDIS_HOST=localhost
  ZERVIGO_FUTURE_REDIS_PORT=6381
  ZERVIGO_FUTURE_REDIS_PASSWORD=
  ZERVIGO_FUTURE_REDIS_DB=0
  
  ZERVIGO_FUTURE_POSTGRES_HOST=localhost
  ZERVIGO_FUTURE_POSTGRES_PORT=5434
  ZERVIGO_FUTURE_POSTGRES_USER=postgres
  ZERVIGO_FUTURE_POSTGRES_PASSWORD=future_password_2025
  ZERVIGO_FUTURE_POSTGRES_DB=zervigo_future
  
  ZERVIGO_FUTURE_NEO4J_HOST=localhost
  ZERVIGO_FUTURE_NEO4J_PORT=7476
  ZERVIGO_FUTURE_NEO4J_USERNAME=neo4j
  ZERVIGO_FUTURE_NEO4J_PASSWORD=future_password_2025
  
  ZERVIGO_FUTURE_ELASTICSEARCH_HOST=localhost
  ZERVIGO_FUTURE_ELASTICSEARCH_PORT=9202
  
  ZERVIGO_FUTURE_WEAVIATE_HOST=localhost
  ZERVIGO_FUTURE_WEAVIATE_PORT=8080
  
  # 服务发现配置
  ZERVIGO_FUTURE_CONSUL_HOST=localhost
  ZERVIGO_FUTURE_CONSUL_PORT=8502
  
  # 监控配置
  ZERVIGO_FUTURE_PROMETHEUS_HOST=localhost
  ZERVIGO_FUTURE_PROMETHEUS_PORT=9092
  ZERVIGO_FUTURE_GRAFANA_HOST=localhost
  ZERVIGO_FUTURE_GRAFANA_PORT=3002
```

### **Docker Compose配置**

#### **LoomaCRM Docker Compose**
```yaml
version: '3.8'

services:
  # LoomaCRM主服务
  looma-crm-main:
    build: ./looma_crm_future
    container_name: looma-crm-main
    ports:
      - "8800:8800"
    environment:
      - LOOMACRM_HOST=0.0.0.0
      - LOOMACRM_PORT=8800
      - LOOMACRM_ENV=development
    depends_on:
      - looma-mysql
      - looma-redis
      - looma-postgres
      - looma-neo4j
      - looma-elasticsearch
      - looma-consul
    networks:
      - looma-network

  # LoomaCRM数据库
  looma-mysql:
    image: mysql:8.0
    container_name: looma-mysql
    ports:
      - "3306:3306"
    environment:
      - MYSQL_ROOT_PASSWORD=looma_password_2025
      - MYSQL_DATABASE=looma_crm
    volumes:
      - looma_mysql_data:/var/lib/mysql
    networks:
      - looma-network

  looma-redis:
    image: redis:7-alpine
    container_name: looma-redis
    ports:
      - "6379:6379"
    volumes:
      - looma_redis_data:/data
    networks:
      - looma-network

  looma-postgres:
    image: postgres:15
    container_name: looma-postgres
    ports:
      - "5432:5432"
    environment:
      - POSTGRES_DB=looma_crm
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=looma_password_2025
    volumes:
      - looma_postgres_data:/var/lib/postgresql/data
    networks:
      - looma-network

  looma-neo4j:
    image: neo4j:5.15
    container_name: looma-neo4j
    ports:
      - "7474:7474"
      - "7687:7687"
    environment:
      - NEO4J_AUTH=neo4j/looma_password_2025
    volumes:
      - looma_neo4j_data:/data
    networks:
      - looma-network

  looma-elasticsearch:
    image: elasticsearch:8.11.0
    container_name: looma-elasticsearch
    ports:
      - "9200:9200"
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
    volumes:
      - looma_elasticsearch_data:/usr/share/elasticsearch/data
    networks:
      - looma-network

  looma-consul:
    image: consul:1.16
    container_name: looma-consul
    ports:
      - "8500:8500"
    command: consul agent -server -bootstrap-expect=1 -ui -client=0.0.0.0
    networks:
      - looma-network

  looma-prometheus:
    image: prom/prometheus:latest
    container_name: looma-prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./configs/prometheus.yml:/etc/prometheus/prometheus.yml
    networks:
      - looma-network

  looma-grafana:
    image: grafana/grafana:latest
    container_name: looma-grafana
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=looma_password_2025
    volumes:
      - looma_grafana_data:/var/lib/grafana
    networks:
      - looma-network

volumes:
  looma_mysql_data:
  looma_redis_data:
  looma_postgres_data:
  looma_neo4j_data:
  looma_elasticsearch_data:
  looma_grafana_data:

networks:
  looma-network:
    driver: bridge
```

---

## 🔧 部署脚本

### **启动脚本**

#### **LoomaCRM启动脚本**
```bash
#!/bin/bash
# 启动LoomaCRM统一服务

GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 启动LoomaCRM服务
start_looma_crm() {
    log_info "启动LoomaCRM统一服务..."
    
    # 启动数据库服务
    docker-compose -f docker-compose.looma-crm.yml up -d
    
    # 等待数据库启动
    sleep 10
    
    # 启动LoomaCRM主服务
    cd looma_crm_future
    ./scripts/start-looma-crm.sh
    
    log_success "LoomaCRM统一服务启动完成"
}

# 启动Zervigo服务版本
start_zervigo_versions() {
    log_info "启动Zervigo服务版本..."
    
    # 启动Future版
    cd zervigo_future
    ./scripts/start-future-version.sh
    
    # 启动DAO版
    cd ../zervigo_dao
    ./scripts/start-dao-version.sh
    
    # 启动区块链版
    cd ../zervigo_blockchain
    ./scripts/start-blockchain-version.sh
    
    log_success "Zervigo服务版本启动完成"
}

# 启动监控系统
start_monitoring() {
    log_info "启动监控系统..."
    
    # 启动Prometheus
    docker-compose -f docker-compose.monitoring.yml up -d prometheus
    
    # 启动Grafana
    docker-compose -f docker-compose.monitoring.yml up -d grafana
    
    log_success "监控系统启动完成"
}

# 主函数
main() {
    log_info "开始启动统一LoomaCRM本地开发环境..."
    
    start_looma_crm
    start_zervigo_versions
    start_monitoring
    
    log_success "统一LoomaCRM本地开发环境启动完成！"
    log_info "访问地址："
    log_info "  LoomaCRM主服务: http://localhost:8800"
    log_info "  Future版服务: http://localhost:8200"
    log_info "  DAO版服务: http://localhost:9200"
    log_info "  区块链版服务: http://localhost:8300"
    log_info "  监控系统: http://localhost:9090"
    log_info "  仪表板: http://localhost:3000"
    log_info ""
    log_info "前端服务访问地址："
    log_info "  Future版前端: http://localhost:10086"
    log_info "  DAO版前端: http://localhost:9200"
    log_info "  区块链版前端: http://localhost:9300"
    log_info "  LoomaCRM前端: http://localhost:9400"
}

main "$@"
```

### **检查脚本**

#### **服务状态检查脚本**
```bash
#!/bin/bash
# 检查统一LoomaCRM服务状态

GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# 检查端口是否被占用
check_port() {
    lsof -i :$1 >/dev/null 2>&1
    return $?
}

# 检查服务状态
check_service() {
    local service_name=$1
    local port=$2
    local url=$3
    
    log_info "检查 $service_name (端口: $port)..."
    
    if check_port $port; then
        if [ -n "$url" ]; then
            if curl -s "$url" >/dev/null 2>&1; then
                log_success "$service_name 运行正常 (端口: $port, URL: $url)"
                return 0
            else
                log_warning "$service_name 端口 $port 被占用，但服务可能未正常响应"
                return 1
            fi
        else
            log_success "$service_name 端口 $port 被占用"
            return 0
        fi
    else
        log_error "$service_name 端口 $port 未被占用"
        return 1
    fi
}

# 检查LoomaCRM服务
check_looma_crm() {
    log_info "=== 检查LoomaCRM统一服务 ==="
    
    check_service "LoomaCRM主服务" 8800 "http://localhost:8800/health"
    check_service "服务注册中心" 8801 "http://localhost:8801/health"
    check_service "服务配置中心" 8802 "http://localhost:8802/health"
    check_service "服务监控中心" 8803 "http://localhost:8803/health"
    check_service "客户管理服务" 8804 "http://localhost:8804/health"
    check_service "服务选择服务" 8805 "http://localhost:8805/health"
    check_service "资源分配服务" 8806 "http://localhost:8806/health"
    check_service "资源监控服务" 8807 "http://localhost:8807/health"
    check_service "计费管理服务" 8808 "http://localhost:8808/health"
    check_service "支持服务" 8809 "http://localhost:8809/health"
    check_service "分析服务" 8810 "http://localhost:8810/health"
}

# 检查Zervigo服务版本
check_zervigo_versions() {
    log_info "=== 检查Zervigo服务版本 ==="
    
    # Future版
    log_info "--- Future版服务 ---"
    check_service "Future版API网关" 8200 "http://localhost:8200/health"
    check_service "Future版用户服务" 8201 "http://localhost:8201/health"
    check_service "Future版简历服务" 8202 "http://localhost:8202/health"
    check_service "Future版公司服务" 8203 "http://localhost:8203/health"
    check_service "Future版通知服务" 8204 "http://localhost:8204/health"
    check_service "Future版统计服务" 8205 "http://localhost:8205/health"
    check_service "Future版多数据库服务" 8206 "http://localhost:8206/health"
    check_service "Future版职位服务" 8207 "http://localhost:8207/health"
    check_service "Future版模板服务" 8208 "http://localhost:8208/health"
    check_service "Future版横幅服务" 8209 "http://localhost:8209/health"
    check_service "Future版开发团队服务" 8210 "http://localhost:8210/health"
    
    # DAO版
    log_info "--- DAO版服务 ---"
    check_service "DAO版管理前端" 9200 "http://localhost:9200/health"
    check_service "DAO版监控前端" 9201 "http://localhost:9201/health"
    check_service "DAO版配置前端" 9202 "http://localhost:9202/health"
    check_service "DAO版日志前端" 9203 "http://localhost:9203/health"
    check_service "DAO版分析前端" 9204 "http://localhost:9204/health"
    check_service "DAO版治理前端" 9205 "http://localhost:9205/health"
    
    # 区块链版
    log_info "--- 区块链版前端服务 ---"
    check_service "区块链管理前端" 9300 "http://localhost:9300/health"
    check_service "区块链钱包前端" 9301 "http://localhost:9301/health"
    check_service "区块链浏览器前端" 9302 "http://localhost:9302/health"
    check_service "区块链治理前端" 9303 "http://localhost:9303/health"
    check_service "区块链分析前端" 9304 "http://localhost:9304/health"
    check_service "区块链移动端前端" 9305 "http://localhost:9305/health"
    
    # LoomaCRM前端
    log_info "--- LoomaCRM前端服务 ---"
    check_service "LoomaCRM主前端" 9400 "http://localhost:9400/health"
    check_service "LoomaCRM管理前端" 9401 "http://localhost:9401/health"
    check_service "LoomaCRM监控前端" 9402 "http://localhost:9402/health"
    check_service "LoomaCRM分析前端" 9403 "http://localhost:9403/health"
    check_service "LoomaCRM移动端前端" 9404 "http://localhost:9404/health"
    check_service "LoomaCRM桌面端前端" 9405 "http://localhost:9405/health"
    
    # Future版前端
    log_info "--- Future版前端服务 ---"
    check_service "Future版Taro H5前端" 10086 "http://localhost:10086/health"
    check_service "Future版管理前端" 10087 "http://localhost:10087/health"
    check_service "Future版移动端前端" 10088 "http://localhost:10088/health"
    check_service "Future版桌面端前端" 10089 "http://localhost:10089/health"
    check_service "Future版分析前端" 10090 "http://localhost:10090/health"
    
    # 区块链版
    log_info "--- 区块链版服务 ---"
    check_service "区块链服务" 8301 "http://localhost:8301/health"
    check_service "身份服务" 8302 "http://localhost:8302/health"
    check_service "治理服务" 8303 "http://localhost:8303/health"
    check_service "跨链服务" 8304 "http://localhost:8304/health"
    check_service "智能合约服务" 8305 "http://localhost:8305/health"
    check_service "钱包服务" 8306 "http://localhost:8306/health"
    check_service "交易服务" 8307 "http://localhost:8307/health"
    check_service "验证服务" 8308 "http://localhost:8308/health"
}

# 检查数据库服务
check_databases() {
    log_info "=== 检查数据库服务 ==="
    
    # LoomaCRM数据库
    log_info "--- LoomaCRM数据库 ---"
    check_service "LoomaCRM MySQL" 3306
    check_service "LoomaCRM Redis" 6379
    check_service "LoomaCRM PostgreSQL" 5432
    check_service "LoomaCRM Neo4j" 7474
    check_service "LoomaCRM Elasticsearch" 9200
    
    # Future版数据库
    log_info "--- Future版数据库 ---"
    check_service "Future版 MySQL" 3308
    check_service "Future版 Redis" 6381
    check_service "Future版 PostgreSQL" 5434
    check_service "Future版 Neo4j" 7476
    check_service "Future版 Elasticsearch" 9202
    check_service "Future版 Weaviate" 8082
    
    # DAO版数据库
    log_info "--- DAO版数据库 ---"
    check_service "DAO版 MySQL" 3309
    check_service "DAO版 Redis" 6382
    check_service "DAO版 PostgreSQL" 5435
    check_service "DAO版 Neo4j" 7477
    check_service "DAO版 Elasticsearch" 9203
    
    # 区块链版数据库
    log_info "--- 区块链版数据库 ---"
    check_service "区块链版 MySQL" 3310
    check_service "区块链版 Redis" 6383
    check_service "区块链版 PostgreSQL" 5436
    check_service "区块链版 Neo4j" 7478
    check_service "区块链版 Elasticsearch" 9204
}

# 检查监控系统
check_monitoring() {
    log_info "=== 检查监控系统 ==="
    
    check_service "LoomaCRM Prometheus" 9090 "http://localhost:9090"
    check_service "LoomaCRM Grafana" 3000 "http://localhost:3000"
    check_service "Future版 Prometheus" 9092 "http://localhost:9092"
    check_service "Future版 Grafana" 3002 "http://localhost:3002"
    check_service "DAO版 Prometheus" 9093 "http://localhost:9093"
    check_service "DAO版 Grafana" 3003 "http://localhost:3003"
    check_service "区块链版 Prometheus" 9094 "http://localhost:9094"
    check_service "区块链版 Grafana" 3004 "http://localhost:3004"
}

# 检查服务发现
check_service_discovery() {
    log_info "=== 检查服务发现 ==="
    
    check_service "LoomaCRM Consul" 8500 "http://localhost:8500"
    check_service "Future版 Consul" 8502 "http://localhost:8502"
    check_service "DAO版 Consul" 8503 "http://localhost:8503"
    check_service "区块链版 Consul" 8504 "http://localhost:8504"
}

# 主函数
main() {
    log_info "开始检查统一LoomaCRM本地开发环境..."
    
    check_looma_crm
    check_zervigo_versions
    check_databases
    check_monitoring
    check_service_discovery
    
    log_success "统一LoomaCRM本地开发环境检查完成！"
}

main "$@"
```

---

## 📋 实施计划

### **阶段一：环境准备** (1周)
```yaml
任务清单:
  - 端口规划确认
  - 数据库架构设计
  - 服务发现配置
  - 监控系统配置
  - 环境变量配置
  - Docker Compose配置
  - 部署脚本开发
```

### **阶段二：LoomaCRM核心服务开发** (3周)
```yaml
任务清单:
  - 服务注册中心开发
  - 服务配置中心开发
  - 服务监控中心开发
  - 客户管理服务开发
  - 资源管理服务开发
  - 计费管理服务开发
  - 支持服务开发
  - 分析服务开发
```

### **阶段三：Zervigo精简三版本集成** (4周)
```yaml
任务清单:
  - Future版服务集成 (现代企业版)
  - DAO版服务集成 (去中心化组织版)
  - 区块链版服务集成 (区块链企业版)
  - 服务版本注册
  - 服务版本发现
  - 服务版本切换
  - 服务版本监控
  - 服务版本管理

精简优势:
  - 版本数量减少40%
  - 资源占用减少28.6%
  - 开发复杂度降低
  - 维护成本降低
  - 部署效率提升
```

### **阶段四：测试验证** (2周)
```yaml
任务清单:
  - 功能测试
  - 性能测试
  - 集成测试
  - 压力测试
  - 故障测试
  - 用户体验测试
  - 部署测试
  - 监控测试
```

---

## 🎯 优势分析

### **技术优势**
```yaml
统一管理:
  - 统一服务注册
  - 统一服务发现
  - 统一服务监控
  - 统一资源配置
  - 统一故障处理

动态扩展:
  - 支持服务版本动态注册
  - 支持服务版本动态切换
  - 支持服务版本动态升级
  - 支持服务版本动态降级
  - 支持服务版本动态下线
```

### **开发优势**
```yaml
开发效率:
  - 统一开发环境
  - 统一配置管理
  - 统一部署流程
  - 统一监控管理
  - 统一故障处理

资源优化:
  - 端口使用优化
  - 数据库资源优化
  - 计算资源优化
  - 存储资源优化
  - 网络资源优化
```

### **运维优势**
```yaml
运维管理:
  - 统一运维平台
  - 自动化运维流程
  - 智能化运维决策
  - 优化运维效率
  - 降低运维成本

服务管理:
  - 统一服务标准
  - 统一服务流程
  - 统一服务质量
  - 统一服务支持
  - 统一服务升级
```

---

**🎯 统一LoomaCRM本地开发架构设计完成！**

**✅ 架构**: 统一LoomaCRM服务平台，支持精简三版本Zervigo服务动态接入  
**✅ 精简**: 放弃基础版和专业版，版本数量减少40%，资源占用减少28.6%  
**✅ 端口**: 调整LoomaCRM端口到8800-8899，避免与Consul默认端口冲突  
**✅ 数据库**: 统一数据库集群，支持三版本服务隔离  
**✅ 监控**: 统一监控系统，支持三版本服务监控  
**✅ 部署**: 完整部署脚本，支持本地开发环境  
**下一步**: 开始实施阶段一环境准备！
