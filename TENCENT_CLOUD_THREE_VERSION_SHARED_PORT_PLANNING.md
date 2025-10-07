# 腾讯云服务器三个版本+shared对外端口规划文档

## 🎯 概述
本文档详细说明腾讯云服务器支持Future、DAO、Blockchain三个版本以及shared对外端口的完整规划，确保数据一致性和同步机制顺利实施。

## 🚨 前置约束条件

### **关键约束条件**
```yaml
腾讯云服务器需求:
  - 需要支持Future、DAO、Blockchain三个版本
  - 每个版本需要6个数据库端口
  - 需要确保数据一致性和同步机制
  - 外部访问端口必须统一
  - 数据同步机制必须基于统一端口
  - 必须包含shared对外端口规划

当前问题:
  - 三个版本无法同时运行
  - 端口冲突严重
  - 数据同步机制无法实施
  - 外部访问端口冲突
  - shared对外端口缺失
```

## 📊 腾讯云三个版本+shared对外端口规划

### **修正后的端口分配方案**

#### **Future版本外部访问端口**
```yaml
数据库端口:
  - MySQL: 3306 (标准端口)
  - PostgreSQL: 5432 (标准端口)
  - Redis: 6379 (标准端口)
  - Neo4j: 7474, 7687 (标准端口)
  - Elasticsearch: 9200 (标准端口)
  - Weaviate: 8080 (标准端口)

服务端口:
  - Future服务: 8000-8099 范围
  - 共享服务: 8100-8199 范围
  - 外部访问: 通过标准端口
```

#### **DAO版本外部访问端口**
```yaml
数据库端口:
  - MySQL: 3306 (标准端口) - 与Future版本相同
  - PostgreSQL: 5432 (标准端口) - 与Future版本相同
  - Redis: 6379 (标准端口) - 与Future版本相同
  - Neo4j: 7474, 7687 (标准端口) - 与Future版本相同
  - Elasticsearch: 9200 (标准端口) - 与Future版本相同
  - Weaviate: 8080 (标准端口) - 与Future版本相同

服务端口:
  - DAO服务: 8200-8299 范围 (修正，避免与Future冲突)
  - 治理服务: 8300-8399 范围
  - 共享服务: 8400-8499 范围
  - 外部访问: 通过标准端口
```

#### **Blockchain版本外部访问端口**
```yaml
数据库端口:
  - MySQL: 3306 (标准端口) - 与Future版本相同
  - PostgreSQL: 5432 (标准端口) - 与Future版本相同
  - Redis: 6379 (标准端口) - 与Future版本相同
  - Neo4j: 7474, 7687 (标准端口) - 与Future版本相同
  - Elasticsearch: 9200 (标准端口) - 与Future版本相同
  - Weaviate: 8080 (标准端口) - 与Future版本相同

服务端口:
  - 区块链服务: 9000-9099 范围
  - 智能合约: 9100-9199 范围
  - 共享服务: 9200-9299 范围
  - 外部访问: 通过标准端口
```

## 🔧 版本切换机制

### **版本切换脚本**
```bash
#!/bin/bash
# 腾讯云三个版本+shared切换脚本

case $1 in
  "future")
    echo "切换到Future版本"
    # 停止其他版本
    docker stop $(docker ps -q --filter "name=dao-") 2>/dev/null
    docker stop $(docker ps -q --filter "name=blockchain-") 2>/dev/null
    
    # 启动Future版本
    docker start test-mysql test-postgres test-redis test-neo4j test-elasticsearch test-weaviate
    docker start future-service-1 future-service-2 future-service-3
    docker start future-shared-service
    
    echo "Future版本已启动"
    ;;
    
  "dao")
    echo "切换到DAO版本"
    # 停止其他版本
    docker stop $(docker ps -q --filter "name=future-") 2>/dev/null
    docker stop $(docker ps -q --filter "name=blockchain-") 2>/dev/null
    
    # 启动DAO版本
    docker start test-mysql test-postgres test-redis test-neo4j test-elasticsearch test-weaviate
    docker start dao-service-1 dao-service-2 dao-service-3
    docker start dao-shared-service
    
    echo "DAO版本已启动"
    ;;
    
  "blockchain")
    echo "切换到Blockchain版本"
    # 停止其他版本
    docker stop $(docker ps -q --filter "name=future-") 2>/dev/null
    docker stop $(docker ps -q --filter "name=dao-") 2>/dev/null
    
    # 启动Blockchain版本
    docker start test-mysql test-postgres test-redis test-neo4j test-elasticsearch test-weaviate
    docker start blockchain-service-1 blockchain-service-2 blockchain-service-3
    docker start blockchain-shared-service
    
    echo "Blockchain版本已启动"
    ;;
    
  *)
    echo "用法: $0 {future|dao|blockchain}"
    ;;
esac
```

### **数据同步机制**
```yaml
数据同步策略:
  - 使用统一的数据库端口
  - 确保数据一致性
  - 支持版本间数据迁移
  - 实现数据备份和恢复
  - 包含shared服务数据同步

同步路径:
  - 本地 → 腾讯云 (开发 → 测试)
  - 腾讯云 → 阿里云 (测试 → 生产)
  - 版本间数据迁移 (Future → DAO → Blockchain)
  - shared服务数据同步
```

## 📋 实施步骤

### **1. 创建版本切换脚本**
```bash
# 创建版本切换脚本
cat > switch_tencent_version_with_shared.sh << 'EOF'
#!/bin/bash
# 腾讯云三个版本+shared切换脚本
# 使用方法: ./switch_tencent_version_with_shared.sh {future|dao|blockchain}

case $1 in
  "future")
    echo "切换到Future版本"
    # 停止其他版本
    docker stop $(docker ps -q --filter "name=dao-") 2>/dev/null
    docker stop $(docker ps -q --filter "name=blockchain-") 2>/dev/null
    
    # 启动Future版本
    docker start test-mysql test-postgres test-redis test-neo4j test-elasticsearch test-weaviate
    docker start future-service-1 future-service-2 future-service-3
    docker start future-shared-service
    
    echo "Future版本已启动"
    ;;
    
  "dao")
    echo "切换到DAO版本"
    # 停止其他版本
    docker stop $(docker ps -q --filter "name=future-") 2>/dev/null
    docker stop $(docker ps -q --filter "name=blockchain-") 2>/dev/null
    
    # 启动DAO版本
    docker start test-mysql test-postgres test-redis test-neo4j test-elasticsearch test-weaviate
    docker start dao-service-1 dao-service-2 dao-service-3
    docker start dao-shared-service
    
    echo "DAO版本已启动"
    ;;
    
  "blockchain")
    echo "切换到Blockchain版本"
    # 停止其他版本
    docker stop $(docker ps -q --filter "name=future-") 2>/dev/null
    docker stop $(docker ps -q --filter "name=dao-") 2>/dev/null
    
    # 启动Blockchain版本
    docker start test-mysql test-postgres test-redis test-neo4j test-elasticsearch test-weaviate
    docker start blockchain-service-1 blockchain-service-2 blockchain-service-3
    docker start blockchain-shared-service
    
    echo "Blockchain版本已启动"
    ;;
    
  *)
    echo "用法: $0 {future|dao|blockchain}"
    ;;
esac
EOF

chmod +x switch_tencent_version_with_shared.sh
```

### **2. 创建数据同步脚本**
```bash
# 创建数据同步脚本
cat > sync_tencent_versions_with_shared.sh << 'EOF'
#!/bin/bash
# 腾讯云三个版本+shared数据同步脚本

# 同步Future版本数据到DAO版本
sync_future_to_dao() {
    echo "同步Future版本数据到DAO版本..."
    # 数据库数据迁移
    docker exec test-mysql mysqldump -u root -p$MYSQL_PASSWORD future_users > future_data.sql
    docker exec test-mysql mysql -u root -p$MYSQL_PASSWORD dao_users < future_data.sql
    
    # shared服务数据迁移
    docker exec future-shared-service /app/export_data.sh > future_shared_data.json
    docker exec dao-shared-service /app/import_data.sh < future_shared_data.json
    
    echo "Future版本数据同步到DAO版本完成"
}

# 同步DAO版本数据到Blockchain版本
sync_dao_to_blockchain() {
    echo "同步DAO版本数据到Blockchain版本..."
    # 数据库数据迁移
    docker exec test-mysql mysqldump -u root -p$MYSQL_PASSWORD dao_users > dao_data.sql
    docker exec test-mysql mysql -u root -p$MYSQL_PASSWORD blockchain_users < dao_data.sql
    
    # shared服务数据迁移
    docker exec dao-shared-service /app/export_data.sh > dao_shared_data.json
    docker exec blockchain-shared-service /app/import_data.sh < dao_shared_data.json
    
    echo "DAO版本数据同步到Blockchain版本完成"
}

# 同步Blockchain版本数据到Future版本
sync_blockchain_to_future() {
    echo "同步Blockchain版本数据到Future版本..."
    # 数据库数据迁移
    docker exec test-mysql mysqldump -u root -p$MYSQL_PASSWORD blockchain_users > blockchain_data.sql
    docker exec test-mysql mysql -u root -p$MYSQL_PASSWORD future_users < blockchain_data.sql
    
    # shared服务数据迁移
    docker exec blockchain-shared-service /app/export_data.sh > blockchain_shared_data.json
    docker exec future-shared-service /app/import_data.sh < blockchain_shared_data.json
    
    echo "Blockchain版本数据同步到Future版本完成"
}

case $1 in
  "future-to-dao")
    sync_future_to_dao
    ;;
  "dao-to-blockchain")
    sync_dao_to_blockchain
    ;;
  "blockchain-to-future")
    sync_blockchain_to_future
    ;;
  *)
    echo "用法: $0 {future-to-dao|dao-to-blockchain|blockchain-to-future}"
    ;;
esac
EOF

chmod +x sync_tencent_versions_with_shared.sh
```

## ✅ 验证步骤

### **1. 检查版本切换**
```bash
# 检查当前版本
./switch_tencent_version_with_shared.sh future
docker ps --format "table {{.Names}}\t{{.Status}}"

# 切换到DAO版本
./switch_tencent_version_with_shared.sh dao
docker ps --format "table {{.Names}}\t{{.Status}}"

# 切换到Blockchain版本
./switch_tencent_version_with_shared.sh blockchain
docker ps --format "table {{.Names}}\t{{.Status}}"
```

### **2. 检查数据同步**
```bash
# 测试数据同步
./sync_tencent_versions_with_shared.sh future-to-dao
./sync_tencent_versions_with_shared.sh dao-to-blockchain
./sync_tencent_versions_with_shared.sh blockchain-to-future
```

### **3. 检查外部访问**
```bash
# 检查外部访问端口
netstat -tlnp | grep -E ':(3306|5432|6379|7474|9200|8080|8000|8100|8200|8300|8400|9000|9100|9200)'

# 测试外部访问
curl -s http://101.33.251.158:3306
curl -s http://101.33.251.158:5432
curl -s http://101.33.251.158:6379
```

## 🎯 关键优势

### **1. 端口统一性**
```yaml
优势:
  - 三个版本使用相同的数据库端口
  - 外部访问端口统一
  - 数据同步机制简单
  - 配置管理统一
  - 包含shared对外端口规划
```

### **2. 版本切换**
```yaml
优势:
  - 版本切换简单快速
  - 数据一致性保证
  - 资源使用优化
  - 维护成本降低
  - 包含shared服务切换
```

### **3. 数据同步机制**
```yaml
优势:
  - 数据同步路径清晰
  - 版本间数据迁移简单
  - 数据备份和恢复容易
  - 数据一致性保证
  - 包含shared服务数据同步
```

## 📊 总结

### **前置约束条件满足情况**
```yaml
✅ 腾讯云服务器支持三个版本: 通过版本切换实现
✅ 每个版本6个数据库端口: 使用标准端口
✅ 数据一致性和同步机制: 通过统一端口实现
✅ 外部访问端口统一: 使用标准端口
✅ 数据同步机制顺利实施: 通过版本切换和数据迁移实现
✅ 包含shared对外端口规划: 每个版本都有独立的shared服务端口
```

### **关键特点**
```yaml
1. 版本切换模式: 同一时间只运行一个版本
2. 标准端口使用: 确保兼容性和一致性
3. 数据同步机制: 支持版本间数据迁移
4. 外部访问统一: 使用标准端口确保访问一致性
5. 维护简单: 版本切换和数据同步自动化
6. 包含shared服务: 每个版本都有独立的shared服务端口规划
```

---
*创建时间: 2025年10月6日*  
*版本: v1.0*  
*状态: 实施中*  
*下一步: 实施版本切换脚本和数据同步机制*
