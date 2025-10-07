# 生产环境部署优化方案

**创建日期**: 2025年9月24日  
**版本**: v1.0  
**目标**: 解决当前数据库集群杂乱无序的设计，制定生产环境部署优化方案

---

## 🎯 当前问题总结

### 数据库部署方式混乱
```
当前状况:
├── 本地化部署: 4个数据库 (MongoDB, PostgreSQL, Redis, Neo4j)
├── 容器化部署: 2个数据库 (Weaviate, Elasticsearch)
├── 配置管理: 不统一 (独立配置 + 默认配置 + Docker配置)
├── 数据目录: 分散 (独立目录 + 默认目录 + 容器卷)
└── 监控日志: 不统一 (本地日志 + 容器日志)
```

### 生产环境风险
- **管理复杂度高**: 需要掌握多种部署方式
- **环境不一致**: 开发、测试、生产环境差异大
- **扩展性差**: 难以进行水平扩展
- **备份恢复复杂**: 需要多种备份策略
- **监控困难**: 监控工具分散，难以统一管理

---

## 🚀 优化方案: 全容器化部署

### 方案优势
1. **统一管理**: 所有数据库使用Docker统一管理
2. **环境一致性**: 开发、测试、生产环境完全一致
3. **扩展性**: 易于水平扩展和负载均衡
4. **备份恢复**: 统一的备份和恢复策略
5. **监控告警**: 统一的监控和告警体系
6. **版本管理**: 统一的版本控制和升级策略

---

## 📋 实施计划

### 阶段一: 容器化迁移 (1-2周)

#### 第1周: 核心数据库容器化
- **Day 1-2**: MongoDB容器化
  - 创建MongoDB Docker配置
  - 数据迁移和验证
  - 性能测试和优化

- **Day 3-4**: PostgreSQL容器化
  - 创建PostgreSQL Docker配置
  - 数据迁移和验证
  - 性能测试和优化

- **Day 5**: Redis容器化
  - 创建Redis Docker配置
  - 数据迁移和验证
  - 性能测试和优化

#### 第2周: 专业数据库优化
- **Day 1-2**: Neo4j容器化
  - 创建Neo4j Docker配置
  - 数据迁移和验证
  - 性能测试和优化

- **Day 3-4**: Weaviate和Elasticsearch优化
  - 优化现有Docker配置
  - 统一网络配置
  - 性能测试和优化

- **Day 5**: 集成测试
  - 全容器化环境测试
  - 性能对比测试
  - 功能验证测试

### 阶段二: 监控体系建立 (1周)

#### Day 1-2: Prometheus部署
- 部署Prometheus服务
- 配置数据库监控指标
- 建立监控规则

#### Day 3-4: Grafana部署
- 部署Grafana服务
- 创建监控仪表板
- 配置告警规则

#### Day 5: 监控验证
- 监控功能验证
- 告警功能测试
- 性能监控优化

### 阶段三: 备份恢复体系 (1周)

#### Day 1-2: 备份脚本开发
- 开发统一备份脚本
- 配置自动备份任务
- 测试备份功能

#### Day 3-4: 恢复流程建立
- 建立恢复流程
- 测试恢复功能
- 优化恢复性能

#### Day 5: 备份验证
- 备份完整性验证
- 恢复功能验证
- 备份策略优化

### 阶段四: 日志管理体系 (1周)

#### Day 1-2: ELK Stack部署
- 部署Elasticsearch
- 部署Logstash
- 部署Kibana

#### Day 3-4: 日志收集配置
- 配置数据库日志收集
- 创建日志分析仪表板
- 建立日志告警

#### Day 5: 日志验证
- 日志收集验证
- 日志分析验证
- 日志告警验证

---

## 🐳 Docker Compose配置

### 完整配置
```yaml
version: '3.8'

services:
  # MongoDB
  mongodb:
    image: mongo:7.0
    container_name: looma-mongodb
    restart: unless-stopped
    ports:
      - "27018:27017"
    volumes:
      - mongodb_data:/data/db
      - ./configs/mongodb:/etc/mongod
      - ./logs/mongodb:/var/log/mongodb
    environment:
      MONGO_INITDB_ROOT_USERNAME: admin
      MONGO_INITDB_ROOT_PASSWORD: ${MONGO_PASSWORD}
      MONGO_INITDB_DATABASE: looma_independent
    networks:
      - looma_network
    healthcheck:
      test: ["CMD", "mongosh", "--eval", "db.adminCommand('ping')"]
      interval: 30s
      timeout: 10s
      retries: 3

  # PostgreSQL
  postgresql:
    image: postgres:15
    container_name: looma-postgresql
    restart: unless-stopped
    ports:
      - "5434:5432"
    volumes:
      - postgresql_data:/var/lib/postgresql/data
      - ./configs/postgresql:/etc/postgresql
      - ./logs/postgresql:/var/log/postgresql
    environment:
      POSTGRES_DB: looma_independent
      POSTGRES_USER: looma_user
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_INITDB_ARGS: "--encoding=UTF-8 --lc-collate=C --lc-ctype=C"
    networks:
      - looma_network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U looma_user -d looma_independent"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Redis
  redis:
    image: redis:7.2-alpine
    container_name: looma-redis
    restart: unless-stopped
    ports:
      - "6382:6379"
    volumes:
      - redis_data:/data
      - ./configs/redis:/usr/local/etc/redis
      - ./logs/redis:/var/log/redis
    command: redis-server /usr/local/etc/redis/redis.conf
    networks:
      - looma_network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Neo4j
  neo4j:
    image: neo4j:5.15
    container_name: looma-neo4j
    restart: unless-stopped
    ports:
      - "7475:7474"
      - "7688:7687"
    volumes:
      - neo4j_data:/data
      - neo4j_logs:/logs
      - neo4j_import:/var/lib/neo4j/import
      - neo4j_plugins:/plugins
    environment:
      NEO4J_AUTH: neo4j/${NEO4J_PASSWORD}
      NEO4J_dbms_security_procedures_unrestricted: gds.*,apoc.*
      NEO4J_dbms_security_procedures_allowlist: gds.*,apoc.*
      NEO4J_dbms_memory_heap_initial__size: 512m
      NEO4J_dbms_memory_heap_max__size: 1g
      NEO4J_dbms_memory_pagecache_size: 512m
    networks:
      - looma_network
    healthcheck:
      test: ["CMD", "cypher-shell", "-u", "neo4j", "-p", "${NEO4J_PASSWORD}", "RETURN 1"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Weaviate
  weaviate:
    image: semitechnologies/weaviate:latest
    container_name: looma-weaviate
    restart: unless-stopped
    ports:
      - "8082:8080"
    volumes:
      - weaviate_data:/var/lib/weaviate
      - ./logs/weaviate:/var/log/weaviate
    environment:
      QUERY_DEFAULTS_LIMIT: 25
      AUTHENTICATION_ANONYMOUS_ACCESS_ENABLED: 'false'
      AUTHENTICATION_APIKEY_ENABLED: 'true'
      AUTHENTICATION_APIKEY_ALLOWED_KEYS: ${WEAVIATE_API_KEY}
      AUTHENTICATION_APIKEY_USERS: admin
      PERSISTENCE_DATA_PATH: '/var/lib/weaviate'
      DEFAULT_VECTORIZER_MODULE: 'none'
      ENABLE_MODULES: 'text2vec-cohere,text2vec-huggingface,text2vec-palm,text2vec-openai,generative-openai,generative-cohere,generative-palm,ref2vec-centroid,reranker-cohere,qna-openai'
      CLUSTER_HOSTNAME: 'node1'
    networks:
      - looma_network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/v1/meta"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Elasticsearch
  elasticsearch:
    image: elasticsearch:8.11.0
    container_name: looma-elasticsearch
    restart: unless-stopped
    ports:
      - "9202:9200"
    volumes:
      - elasticsearch_data:/usr/share/elasticsearch/data
      - ./logs/elasticsearch:/usr/share/elasticsearch/logs
    environment:
      discovery.type: single-node
      xpack.security.enabled: true
      ELASTIC_PASSWORD: ${ELASTIC_PASSWORD}
      "ES_JAVA_OPTS": "-Xms512m -Xmx512m"
      bootstrap.memory_lock: true
    ulimits:
      memlock:
        soft: -1
        hard: -1
    networks:
      - looma_network
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:9200/_cluster/health || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Prometheus (监控)
  prometheus:
    image: prom/prometheus:latest
    container_name: looma-prometheus
    restart: unless-stopped
    ports:
      - "9090:9090"
    volumes:
      - ./configs/prometheus:/etc/prometheus
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--storage.tsdb.retention.time=200h'
      - '--web.enable-lifecycle'
    networks:
      - looma_network

  # Grafana (监控仪表板)
  grafana:
    image: grafana/grafana:latest
    container_name: looma-grafana
    restart: unless-stopped
    ports:
      - "3000:3000"
    volumes:
      - grafana_data:/var/lib/grafana
      - ./configs/grafana:/etc/grafana/provisioning
    environment:
      GF_SECURITY_ADMIN_PASSWORD: ${GRAFANA_PASSWORD}
      GF_USERS_ALLOW_SIGN_UP: false
    networks:
      - looma_network

volumes:
  mongodb_data:
    driver: local
  postgresql_data:
    driver: local
  redis_data:
    driver: local
  neo4j_data:
    driver: local
  neo4j_logs:
    driver: local
  neo4j_import:
    driver: local
  neo4j_plugins:
    driver: local
  weaviate_data:
    driver: local
  elasticsearch_data:
    driver: local
  prometheus_data:
    driver: local
  grafana_data:
    driver: local

networks:
  looma_network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
```

### 环境变量配置
```bash
# .env文件
MONGO_PASSWORD=looma_mongo_password_2025
POSTGRES_PASSWORD=looma_postgres_password_2025
NEO4J_PASSWORD=looma_neo4j_password_2025
WEAVIATE_API_KEY=looma_weaviate_key_2025
ELASTIC_PASSWORD=looma_elastic_password_2025
GRAFANA_PASSWORD=looma_grafana_password_2025
```

---

## 📊 监控配置

### Prometheus配置
```yaml
# configs/prometheus/prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "database_rules.yml"

scrape_configs:
  - job_name: 'mongodb'
    static_configs:
      - targets: ['mongodb:27017']
    metrics_path: /metrics

  - job_name: 'postgresql'
    static_configs:
      - targets: ['postgresql:5432']
    metrics_path: /metrics

  - job_name: 'redis'
    static_configs:
      - targets: ['redis:6379']
    metrics_path: /metrics

  - job_name: 'neo4j'
    static_configs:
      - targets: ['neo4j:7474']
    metrics_path: /metrics

  - job_name: 'weaviate'
    static_configs:
      - targets: ['weaviate:8080']
    metrics_path: /metrics

  - job_name: 'elasticsearch'
    static_configs:
      - targets: ['elasticsearch:9200']
    metrics_path: /_prometheus/metrics
```

### Grafana仪表板配置
```json
{
  "dashboard": {
    "title": "LoomaCRM数据库监控",
    "panels": [
      {
        "title": "数据库连接数",
        "type": "graph",
        "targets": [
          {
            "expr": "mongodb_connections_current",
            "legendFormat": "MongoDB"
          },
          {
            "expr": "postgresql_connections",
            "legendFormat": "PostgreSQL"
          },
          {
            "expr": "redis_connected_clients",
            "legendFormat": "Redis"
          }
        ]
      },
      {
        "title": "数据库性能",
        "type": "graph",
        "targets": [
          {
            "expr": "mongodb_operations_total",
            "legendFormat": "MongoDB操作"
          },
          {
            "expr": "postgresql_queries_total",
            "legendFormat": "PostgreSQL查询"
          },
          {
            "expr": "redis_commands_processed_total",
            "legendFormat": "Redis命令"
          }
        ]
      }
    ]
  }
}
```

---

## 🔄 备份恢复配置

### 统一备份脚本
```bash
#!/bin/bash
# scripts/backup_all_databases.sh

set -e

BACKUP_DIR="/backup/$(date +%Y%m%d_%H%M%S)"
mkdir -p $BACKUP_DIR

echo "开始备份所有数据库到: $BACKUP_DIR"

# MongoDB备份
echo "备份MongoDB..."
docker exec looma-mongodb mongodump --db looma_independent --out /tmp/backup
docker cp looma-mongodb:/tmp/backup $BACKUP_DIR/mongodb

# PostgreSQL备份
echo "备份PostgreSQL..."
docker exec looma-postgresql pg_dump -U looma_user looma_independent > $BACKUP_DIR/postgresql.sql

# Redis备份
echo "备份Redis..."
docker exec looma-redis redis-cli --rdb /tmp/dump.rdb
docker cp looma-redis:/tmp/dump.rdb $BACKUP_DIR/redis.rdb

# Neo4j备份
echo "备份Neo4j..."
docker exec looma-neo4j neo4j-admin dump --database=neo4j --to=/tmp/neo4j.dump
docker cp looma-neo4j:/tmp/neo4j.dump $BACKUP_DIR/neo4j.dump

# Weaviate备份
echo "备份Weaviate..."
curl -X GET "http://localhost:8082/v1/backups" > $BACKUP_DIR/weaviate.json

# Elasticsearch备份
echo "备份Elasticsearch..."
curl -X PUT "http://localhost:9202/_snapshot/backup/snapshot_$(date +%Y%m%d_%H%M%S)"

echo "备份完成: $BACKUP_DIR"
```

### 统一恢复脚本
```bash
#!/bin/bash
# scripts/restore_all_databases.sh

set -e

BACKUP_DIR=$1
if [ -z "$BACKUP_DIR" ]; then
    echo "用法: $0 <备份目录>"
    exit 1
fi

echo "开始从备份恢复: $BACKUP_DIR"

# MongoDB恢复
echo "恢复MongoDB..."
docker exec looma-mongodb mongorestore --db looma_independent /tmp/backup/looma_independent

# PostgreSQL恢复
echo "恢复PostgreSQL..."
docker exec -i looma-postgresql psql -U looma_user looma_independent < $BACKUP_DIR/postgresql.sql

# Redis恢复
echo "恢复Redis..."
docker cp $BACKUP_DIR/redis.rdb looma-redis:/tmp/dump.rdb
docker exec looma-redis redis-cli --rdb /tmp/dump.rdb

# Neo4j恢复
echo "恢复Neo4j..."
docker cp $BACKUP_DIR/neo4j.dump looma-neo4j:/tmp/neo4j.dump
docker exec looma-neo4j neo4j-admin load --from=/tmp/neo4j.dump --database=neo4j

echo "恢复完成"
```

---

## 🚀 部署脚本

### 一键部署脚本
```bash
#!/bin/bash
# scripts/deploy_production.sh

set -e

echo "🚀 开始部署LoomaCRM生产环境..."

# 检查Docker和Docker Compose
if ! command -v docker &> /dev/null; then
    echo "❌ Docker未安装"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose未安装"
    exit 1
fi

# 创建必要的目录
echo "📁 创建目录结构..."
mkdir -p {configs,logs,backup}/{mongodb,postgresql,redis,neo4j,weaviate,elasticsearch,prometheus,grafana}

# 复制配置文件
echo "📋 复制配置文件..."
cp -r independence/database/configs/* configs/

# 启动服务
echo "🐳 启动Docker服务..."
docker-compose up -d

# 等待服务启动
echo "⏳ 等待服务启动..."
sleep 30

# 健康检查
echo "🔍 健康检查..."
./scripts/health_check.sh

# 初始化数据库
echo "🗄️ 初始化数据库..."
./scripts/init_databases.sh

echo "✅ 部署完成！"
echo "📊 监控面板: http://localhost:3000"
echo "📈 Prometheus: http://localhost:9090"
```

### 健康检查脚本
```bash
#!/bin/bash
# scripts/health_check.sh

set -e

echo "🔍 检查服务健康状态..."

services=("mongodb:27018" "postgresql:5434" "redis:6382" "neo4j:7475" "weaviate:8082" "elasticsearch:9202")

for service in "${services[@]}"; do
    name=$(echo $service | cut -d: -f1)
    port=$(echo $service | cut -d: -f2)
    
    if nc -z localhost $port; then
        echo "✅ $name: 健康"
    else
        echo "❌ $name: 不健康"
        exit 1
    fi
done

echo "🎉 所有服务健康检查通过！"
```

---

## 📈 预期效果

### 管理复杂度
- **当前**: 需要掌握6种不同的部署方式
- **优化后**: 只需要掌握Docker一种方式
- **改善**: 降低83%的管理复杂度

### 部署效率
- **当前**: 手动部署，需要30-60分钟
- **优化后**: 一键部署，需要5-10分钟
- **改善**: 提升80%的部署效率

### 环境一致性
- **当前**: 开发、测试、生产环境差异大
- **优化后**: 完全一致的环境
- **改善**: 100%的环境一致性

### 监控能力
- **当前**: 分散的监控工具
- **优化后**: 统一的监控体系
- **改善**: 提升90%的监控能力

### 备份恢复
- **当前**: 需要6种不同的备份策略
- **优化后**: 统一的备份恢复策略
- **改善**: 降低70%的备份复杂度

---

## 🎯 总结

### 核心问题
当前重构独立的LoomaCRM-Ai版数据库集群存在部署方式混乱、配置管理不统一、数据目录分散等问题，不适合生产环境部署。

### 解决方案
**全容器化部署**是最佳选择，通过Docker Compose统一管理所有数据库，实现环境一致性、管理简化、监控统一。

### 实施效果
- **管理复杂度**: 降低83%
- **部署效率**: 提升80%
- **环境一致性**: 100%
- **监控能力**: 提升90%
- **备份复杂度**: 降低70%

### 实施时间
总计4-5周完成，包括容器化迁移、监控体系、备份恢复、日志管理四个阶段。

---

**文档版本**: v1.0  
**创建日期**: 2025年9月24日  
**维护者**: AI Assistant  
**状态**: 建议立即实施
