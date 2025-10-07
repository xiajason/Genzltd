# 三环境端口配置文档

## 🎯 概述
本文档详细说明JobFirst系统的三环境端口配置，确保开发、测试、生产环境完全隔离，避免端口冲突。

## 📊 三环境端口分配

### 1. 本地开发环境 (Local Development)
```yaml
数据库端口:
  - MySQL: 3306 (标准端口)
  - PostgreSQL: 5434 (自定义端口)
  - Redis: 6382 (自定义端口)
  - Neo4j: 7475 (自定义端口)
  - Elasticsearch: 9202 (自定义端口)
  - Weaviate: 8091 (自定义端口)

服务端口:
  - API Gateway: 8601
  - User Service: 8602
  - Resume Service: 8603
  - Company Service: 8604
  - AI Service: 8620

网络配置:
  - 网络名称: dev-network
  - 驱动: bridge
  - 隔离: 本地开发环境
```

### 2. 腾讯云测试环境 (Tencent Cloud Testing)
```yaml
数据库端口:
  - MySQL: 3306 (标准端口)
  - PostgreSQL: 5432 (标准端口)
  - Redis: 6379 (标准端口)
  - Neo4j: 7474 (标准端口)
  - Elasticsearch: 9200 (标准端口)
  - Weaviate: 8080 (标准端口)

服务端口:
  - 测试服务: 8000-8099 范围
  - 监控服务: 9000-9099 范围

网络配置:
  - 网络名称: test-network
  - 驱动: bridge
  - 隔离: 腾讯云测试环境
```

### 3. 阿里云生产环境 (Alibaba Cloud Production)
```yaml
数据库端口:
  - MySQL: 3306 (标准端口)
  - PostgreSQL: 5432 (标准端口)
  - Redis: 6379 (标准端口)
  - Neo4j: 7474 (标准端口)
  - Elasticsearch: 9200 (标准端口)
  - Weaviate: 8080 (标准端口)

服务端口:
  - 生产服务: 80, 443 (标准HTTP/HTTPS)
  - AI服务: 8100, 8110, 8120
  - 监控服务: 3000, 9090

网络配置:
  - 网络名称: production-network
  - 驱动: bridge
  - 隔离: 阿里云生产环境
```

## 🔧 环境隔离机制

### Docker网络隔离
```yaml
本地开发环境:
  - 网络: dev-network
  - 端口: 自定义端口避免冲突
  - 隔离: 完全独立

腾讯云测试环境:
  - 网络: test-network
  - 端口: 标准端口
  - 隔离: 测试环境独立

阿里云生产环境:
  - 网络: production-network
  - 端口: 标准端口
  - 隔离: 生产环境独立
```

### 端口映射隔离
```yaml
方案: 使用Docker端口映射
  - 容器内: 使用标准端口
  - 宿主机: 使用不同端口
  - 隔离: 通过端口映射实现
```

### 环境变量配置
```yaml
方案: 不同环境使用不同配置
  - 本地: 使用自定义端口
  - 测试: 使用标准端口
  - 生产: 使用标准端口
  - 隔离: 通过环境变量实现
```

## 🚨 端口冲突解决

### 问题分析
```yaml
严重端口冲突:
  - MySQL: 本地(3306) vs 腾讯云(3306) vs 阿里云(3306)
  - PostgreSQL: 腾讯云(5432) vs 阿里云(5432)
  - Redis: 腾讯云(6379) vs 阿里云(6379)
  - Elasticsearch: 腾讯云(9200) vs 阿里云(9200)
  - Weaviate: 腾讯云(8080) vs 阿里云(8080)
```

### 解决方案
```yaml
1. 本地开发环境: 使用自定义端口避免冲突
2. 腾讯云测试环境: 使用标准端口
3. 阿里云生产环境: 使用标准端口
4. 通过Docker网络隔离实现环境分离
```

## 📋 实施步骤

### 1. 创建环境隔离网络
```bash
# 本地开发环境
docker network create --driver bridge dev-network

# 腾讯云测试环境
docker network create --driver bridge test-network

# 阿里云生产环境
docker network create --driver bridge production-network
```

### 2. 配置环境变量
```bash
# 本地开发环境
export ENV=development
export MYSQL_PORT=3306
export POSTGRES_PORT=5434
export REDIS_PORT=6382

# 腾讯云测试环境
export ENV=testing
export MYSQL_PORT=3306
export POSTGRES_PORT=5432
export REDIS_PORT=6379

# 阿里云生产环境
export ENV=production
export MYSQL_PORT=3306
export POSTGRES_PORT=5432
export REDIS_PORT=6379
```

### 3. 部署数据库服务
```bash
# 本地开发环境
docker run -d --name dev-mysql --network dev-network -p 3306:3306 mysql:8.0
docker run -d --name dev-postgres --network dev-network -p 5434:5432 postgres:14
docker run -d --name dev-redis --network dev-network -p 6382:6379 redis:7-alpine

# 腾讯云测试环境
docker run -d --name test-mysql --network test-network -p 3306:3306 mysql:8.0
docker run -d --name test-postgres --network test-network -p 5432:5432 postgres:14
docker run -d --name test-redis --network test-network -p 6379:6379 redis:7-alpine

# 阿里云生产环境
docker run -d --name prod-mysql --network production-network -p 3306:3306 mysql:8.0
docker run -d --name prod-postgres --network production-network -p 5432:5432 postgres:14
docker run -d --name prod-redis --network production-network -p 6379:6379 redis:7-alpine
```

## ✅ 验证步骤

### 1. 检查网络隔离
```bash
# 检查本地网络
docker network ls | grep dev

# 检查腾讯云网络
ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158 "docker network ls | grep test"

# 检查阿里云网络
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker network ls | grep production"
```

### 2. 检查端口隔离
```bash
# 检查本地端口
lsof -i :3306,5434,6382,7475,9202,8091

# 检查腾讯云端口
ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158 "netstat -tlnp | grep -E ':(3306|5432|6379|7474|9200|8080)'"

# 检查阿里云端口
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "netstat -tlnp | grep -E ':(3306|5432|6379|7474|9200|8080)'"
```

### 3. 测试数据同步
```bash
# 本地到阿里云数据同步
./sync_local_to_alibaba.sh

# 腾讯云到阿里云数据同步
./sync_tencent_to_alibaba.sh
```

---
*创建时间: 2025年10月6日*  
*版本: v1.0*  
*状态: 实施中*  
*下一步: 完善MySQL和Elasticsearch Docker部署*
