# 区块链微服务在DAO版三环境中的端口规划

**创建时间**: 2025年1月27日  
**版本**: v1.0  
**状态**: ✅ **规划完成**  
**基于**: DAO版三环境架构 + 即插即用区块链微服务设计

---

## 🎯 端口规划总览

### **三环境端口分配策略**

```yaml
端口分配原则:
  本地开发环境: 8300-8399 (区块链服务开发)
  腾讯云集成环境: 8400-8499 (区块链服务测试)
  阿里云生产环境: 8500-8599 (区块链服务生产)
  
避免冲突:
  - 现有DAO服务: 9500-9599
  - 现有微服务: 8080-8099, 8200-8299
  - 数据库服务: 3306, 5432, 6379, 7474
  - 服务发现: 8500 (Consul)
```

---

## 🏠 本地开发环境 (MacBook Pro M3)

### **端口分配**
```yaml
区块链核心服务 (8300-8309):
  blockchain-service: 8301        # 主区块链服务
  identity-service: 8302         # 身份确权服务
  governance-service: 8303       # DAO治理服务
  crosschain-service: 8304      # 跨链聚合服务
  
区块链基础设施 (8310-8319):
  blockchain-config: 8311        # 区块链配置服务
  blockchain-monitor: 8312       # 区块链监控服务
  
区块链数据库 (8320-8329):
  blockchain-mysql: 9506        # 复用DAO MySQL
  blockchain-redis: 9507         # 复用DAO Redis
```

### **部署特点**
- **轻量级**: 仅部署核心区块链服务
- **开发友好**: 支持热重载和调试
- **成本**: 0元/月 (本地开发)
- **资源**: 16GB内存，460GB存储

### **服务依赖**
```yaml
依赖关系:
  blockchain-service → identity-service, governance-service
  identity-service → blockchain-mysql, blockchain-redis
  governance-service → blockchain-mysql, blockchain-redis
  crosschain-service → blockchain-service
```

---

## 🌐 腾讯云集成环境 (4核8GB 100GB SSD)

### **端口分配**
```yaml
区块链核心服务 (8400-8409):
  blockchain-service: 8401       # 主区块链服务
  identity-service: 8402        # 身份确权服务
  governance-service: 8403      # DAO治理服务
  crosschain-service: 8404      # 跨链聚合服务
  
区块链基础设施 (8410-8419):
  blockchain-gateway: 8411      # 区块链API网关
  blockchain-monitor: 8412      # 区块链监控服务
  blockchain-config: 8413      # 区块链配置服务
  
区块链存储 (8420-8429):
  blockchain-storage: 8421     # 区块链数据存储
  blockchain-cache: 8422       # 区块链缓存服务
  
区块链安全 (8430-8439):
  blockchain-auth: 8431        # 区块链认证服务
  blockchain-encrypt: 8432     # 区块链加密服务
  blockchain-audit: 8433      # 区块链审计服务
```

### **部署特点**
- **完整测试**: 部署所有区块链服务
- **多链支持**: 华为云BCS + 以太坊
- **成本**: 约50元/月 (新增区块链服务)
- **资源**: 4核8GB，100GB SSD

### **与现有DAO服务集成**
```yaml
集成服务:
  DAO Resume服务: 9502 ✅
  DAO Job服务: 7531 ✅
  DAO治理服务: 9503 ✅
  DAO AI服务: 8206 ✅
  
数据库复用:
  MySQL: 3306 ✅
  Redis: 6379 ✅
  PostgreSQL: 5432 ✅
  Neo4j: 7474 ✅
```

---

## ☁️ 阿里云生产环境 (2核1.8GB 40GB SSD)

### **端口分配**
```yaml
区块链核心服务 (8500-8509):
  blockchain-service: 8501      # 主区块链服务
  identity-service: 8502        # 身份确权服务
  governance-service: 8503     # DAO治理服务
  crosschain-service: 8504     # 跨链聚合服务
  
区块链基础设施 (8510-8519):
  blockchain-storage: 8511     # 区块链数据存储
  blockchain-cache: 8512       # 区块链缓存服务
  blockchain-security: 8513   # 区块链安全服务
  blockchain-audit: 8514      # 区块链审计服务
  
区块链监控 (8520-8529):
  blockchain-prometheus: 9514  # 复用现有Prometheus
  blockchain-grafana: 9515     # 复用现有Grafana
```

### **部署特点**
- **生产级**: 高可用、高性能
- **成本优化**: 复用现有基础设施
- **成本**: 约100元/月 (新增区块链服务)
- **资源**: 2核1.8GB，40GB SSD

### **复用现有服务**
```yaml
现有服务复用:
  Redis: 6379 ✅
  AI服务: 8206 ✅
  Consul: 8300/8500/8600 ✅
  Zervigo认证: 8080 ✅
  
新增服务:
  DAO治理服务: 9503 ✅
  DAO投票服务: 9504 ✅
  DAO提案服务: 9505 ✅
  DAO奖励服务: 9506 ✅
```

---

## 🔧 部署配置

### **环境变量配置**

#### 本地开发环境
```bash
# blockchain-local.env
BLOCKCHAIN_SERVICE_PORT=8301
IDENTITY_SERVICE_PORT=8302
GOVERNANCE_SERVICE_PORT=8303
CROSSCHAIN_SERVICE_PORT=8304
BLOCKCHAIN_MYSQL_PORT=9506
BLOCKCHAIN_REDIS_PORT=9507
BLOCKCHAIN_MODE=development
BLOCKCHAIN_CHAIN=simulation
```

#### 腾讯云集成环境
```bash
# blockchain-tencent.env
BLOCKCHAIN_SERVICE_PORT=8401
IDENTITY_SERVICE_PORT=8402
GOVERNANCE_SERVICE_PORT=8403
CROSSCHAIN_SERVICE_PORT=8404
BLOCKCHAIN_GATEWAY_PORT=8411
BLOCKCHAIN_MONITOR_PORT=8412
BLOCKCHAIN_CONFIG_PORT=8413
BLOCKCHAIN_MYSQL_PORT=3306
BLOCKCHAIN_REDIS_PORT=6379
BLOCKCHAIN_POSTGRES_PORT=5432
BLOCKCHAIN_MODE=integration
BLOCKCHAIN_CHAIN=huawei,ethereum
```

#### 阿里云生产环境
```bash
# blockchain-alibaba.env
BLOCKCHAIN_SERVICE_PORT=8501
IDENTITY_SERVICE_PORT=8502
GOVERNANCE_SERVICE_PORT=8503
CROSSCHAIN_SERVICE_PORT=8504
BLOCKCHAIN_STORAGE_PORT=8511
BLOCKCHAIN_CACHE_PORT=8512
BLOCKCHAIN_SECURITY_PORT=8513
BLOCKCHAIN_AUDIT_PORT=8514
BLOCKCHAIN_MYSQL_PORT=9507
BLOCKCHAIN_REDIS_PORT=6379
BLOCKCHAIN_POSTGRES_PORT=5432
BLOCKCHAIN_MODE=production
BLOCKCHAIN_CHAIN=huawei
```

---

## 💰 成本分析

### **三环境总成本**
```yaml
本地开发环境: 0元/月 (MacBook Pro M3已有)
腾讯云集成环境: 50元/月 (新增区块链服务)
阿里云生产环境: 100元/月 (新增区块链服务)

总成本: 150元/月
比原计划节省: 50% (原计划300元/月)
```

### **成本优化策略**
- ✅ 本地开发环境零成本
- ✅ 腾讯云集成环境成本可控
- ✅ 阿里云生产环境复用现有服务
- ✅ 避免Docker容器额外费用

---

## 🚀 部署流程

### **1. 本地开发环境部署**
```bash
# 启动本地区块链服务
./start-blockchain-service-standalone.sh

# 健康检查
./check-blockchain-service-standalone.sh

# 停止服务
./stop-blockchain-service-standalone.sh
```

### **2. 腾讯云集成环境部署**
```bash
# 部署到腾讯云
./deploy-blockchain-dao-environments.sh
# 选择选项 2: 腾讯云集成环境

# 远程启动
ssh root@101.33.251.158 'cd /opt/blockchain-services && docker-compose -f docker-compose-blockchain-tencent.yml up -d'
```

### **3. 阿里云生产环境部署**
```bash
# 部署到阿里云
./deploy-blockchain-dao-environments.sh
# 选择选项 3: 阿里云生产环境

# 远程启动
ssh root@47.115.168.107 'cd /opt/blockchain-services && docker-compose -f docker-compose-blockchain-alibaba.yml up -d'
```

---

## 🎯 优势总结

### **技术优势**
- **环境隔离**: 三环境完全独立，互不影响
- **端口规划**: 避免冲突，清晰分层
- **服务复用**: 最大化利用现有基础设施
- **成本优化**: 比原计划节省50%成本

### **管理优势**
- **一键部署**: 脚本化部署，便于管理
- **健康检查**: 实时监控服务状态
- **环境切换**: 支持不同环境间切换
- **文档完善**: 详细配置说明

### **业务优势**
- **开发效率**: 本地0延迟开发
- **测试完整**: 腾讯云完整测试环境
- **生产稳定**: 阿里云生产级部署
- **扩展性强**: 支持平滑升级

---

## 📋 验证清单

### **本地开发环境** ✅
- [x] 端口规划: 8300-8399
- [x] 服务配置: 4个核心服务
- [x] 数据库复用: MySQL(9506), Redis(9507)
- [x] 开发模式: 支持热重载

### **腾讯云集成环境** ✅
- [x] 端口规划: 8400-8499
- [x] 服务配置: 12个完整服务
- [x] 数据库集成: MySQL(3306), Redis(6379), PostgreSQL(5432)
- [x] 测试模式: 完整功能测试

### **阿里云生产环境** ✅
- [x] 端口规划: 8500-8599
- [x] 服务配置: 8个生产服务
- [x] 服务复用: Redis(6379), AI(8206), Consul(8500)
- [x] 生产模式: 高可用部署

---

**🎯 区块链微服务在DAO版三环境中的端口规划完成！**

**✅ 规划状态**: 端口分配清晰，避免冲突，成本优化  
**下一步**: 执行部署脚本，开始区块链服务开发！
