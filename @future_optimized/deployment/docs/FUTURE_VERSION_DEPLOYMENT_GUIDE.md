# Future版本部署指南

**创建时间**: 2025年10月5日  
**版本**: Future v1.0  
**目标**: 为Future版提供完整的部署指南和操作手册  

---

## 🎯 **部署概览**

### **Future版本架构**
- **7种数据库**: MySQL, PostgreSQL, SQLite, Redis, Neo4j, Elasticsearch, Weaviate
- **数据边界清晰**: 各数据库职责明确，边界清晰
- **AI集成完整**: 向量搜索、图数据库、全文搜索
- **高性能**: 缓存、索引、向量搜索优化

### **核心功能模块**
1. **用户管理模块** (MySQL + Redis)
2. **简历管理模块** (MySQL + SQLite + Elasticsearch)
3. **AI服务模块** (PostgreSQL + Weaviate)
4. **关系网络模块** (Neo4j)
5. **缓存和队列模块** (Redis)

---

## 🚀 **快速部署**

### **方式一：一键部署**
```bash
# 1. 进入Future版本目录
cd /opt/jobfirst-multi-version/future

# 2. 执行一键部署
chmod +x deploy_future.sh
./deploy_future.sh
```

### **方式二：分步部署**
```bash
# 1. 创建目录结构
mkdir -p data/{mysql,postgresql,redis,neo4j,elasticsearch,weaviate,sqlite}
mkdir -p logs/{mysql,postgresql,redis,neo4j,elasticsearch,weaviate,sqlite}
mkdir -p scripts

# 2. 设置权限
chmod -R 755 data/ logs/ scripts/

# 3. 启动服务
docker-compose up -d

# 4. 等待服务就绪
./start_future.sh

# 5. 创建数据库结构
docker exec future-sqlite-manager python3 /app/scripts/future_database_structure_executor.py

# 6. 验证部署
docker exec future-sqlite-manager python3 /app/scripts/future_database_verification_script.py
```

---

## 📋 **文件结构**

### **目录结构**
```
/opt/jobfirst-multi-version/future/
├── docker-compose.yml          # Docker配置
├── future.env                  # 环境变量
├── deploy_future.sh            # 部署脚本
├── start_future.sh             # 启动脚本
├── stop_future.sh              # 停止脚本
├── monitor_future.sh           # 监控脚本
├── data/                       # 数据目录
│   ├── mysql/                  # MySQL数据
│   ├── postgresql/             # PostgreSQL数据
│   ├── redis/                  # Redis数据
│   ├── neo4j/                  # Neo4j数据
│   ├── elasticsearch/          # Elasticsearch数据
│   ├── weaviate/               # Weaviate数据
│   └── sqlite/                 # SQLite数据
├── logs/                       # 日志目录
│   ├── mysql/                  # MySQL日志
│   ├── postgresql/             # PostgreSQL日志
│   ├── redis/                  # Redis日志
│   ├── neo4j/                  # Neo4j日志
│   ├── elasticsearch/          # Elasticsearch日志
│   ├── weaviate/               # Weaviate日志
│   └── sqlite/                 # SQLite日志
└── scripts/                    # 脚本目录
    ├── future_database_structure_executor.py
    ├── future_database_verification_script.py
    ├── future_mysql_database_structure.sql
    ├── future_postgresql_database_structure.sql
    ├── future_sqlite_database_structure.py
    ├── future_redis_database_structure.py
    ├── future_neo4j_database_structure.py
    ├── future_elasticsearch_database_structure.py
    └── future_weaviate_database_structure.py
```

---

## 🔧 **服务管理**

### **启动服务**
```bash
# 启动所有服务
./start_future.sh

# 或使用Docker Compose
docker-compose up -d
```

### **停止服务**
```bash
# 停止所有服务
./stop_future.sh

# 或使用Docker Compose
docker-compose down
```

### **查看服务状态**
```bash
# 查看服务状态
docker-compose ps

# 查看服务日志
docker-compose logs -f

# 查看特定服务日志
docker-compose logs -f future-mysql
```

### **监控服务**
```bash
# 执行完整监控
./monitor_future.sh

# 检查资源使用
docker stats

# 检查端口占用
netstat -tuln | grep -E "(3306|5432|6379|7474|7687|9200|8080|8082)"
```

---

## 🌐 **外部访问**

### **数据库连接信息**

| 数据库 | 主机 | 端口 | 用户名 | 密码 | 数据库名 |
|--------|------|------|--------|------|----------|
| **MySQL** | localhost | 3306 | future_user | f_mysql_password_2025 | jobfirst_future |
| **PostgreSQL** | localhost | 5432 | future_user | f_postgres_password_2025 | f_pg |
| **Redis** | localhost | 6379 | - | f_redis_password_2025 | - |
| **Neo4j** | localhost | 7474 | neo4j | f_neo4j_password_2025 | future_graph |
| **Elasticsearch** | localhost | 9200 | - | - | - |
| **Weaviate** | localhost | 8080 | - | - | - |

### **Web界面访问**
- **Neo4j Browser**: http://localhost:7474
- **Elasticsearch**: http://localhost:9200
- **Weaviate**: http://localhost:8080

---

## 🔍 **验证和测试**

### **数据库结构验证**
```bash
# 执行验证脚本
docker exec future-sqlite-manager python3 /app/scripts/future_database_verification_script.py
```

### **连接测试**
```bash
# MySQL连接测试
docker exec future-mysql mysql -u future_user -pf_mysql_password_2025 jobfirst_future -e "SHOW TABLES;"

# PostgreSQL连接测试
docker exec future-postgresql psql -U future_user -d f_pg -c "\dt"

# Redis连接测试
docker exec future-redis redis-cli -a f_redis_password_2025 ping

# Neo4j连接测试
curl -u neo4j:f_neo4j_password_2025 http://localhost:7474/db/data/

# Elasticsearch连接测试
curl http://localhost:9200/_cluster/health

# Weaviate连接测试
curl http://localhost:8080/v1/meta
```

---

## 🛠️ **故障排除**

### **常见问题**

#### **1. 服务启动失败**
```bash
# 检查Docker状态
docker ps -a

# 检查服务日志
docker-compose logs future-mysql
docker-compose logs future-postgresql
```

#### **2. 数据库连接失败**
```bash
# 检查端口占用
netstat -tuln | grep -E "(3306|5432|6379|7474|7687|9200|8080|8082)"

# 检查防火墙
sudo ufw status
```

#### **3. 权限问题**
```bash
# 设置目录权限
chmod -R 755 data/ logs/ scripts/

# 检查Docker权限
sudo usermod -aG docker $USER
```

### **日志位置**
- **MySQL日志**: `logs/mysql/`
- **PostgreSQL日志**: `logs/postgresql/`
- **Redis日志**: `logs/redis/`
- **Neo4j日志**: `logs/neo4j/`
- **Elasticsearch日志**: `logs/elasticsearch/`
- **Weaviate日志**: `logs/weaviate/`

---

## 📊 **性能优化**

### **资源分配**
- **MySQL**: 512MB内存
- **PostgreSQL**: 512MB内存
- **Redis**: 256MB内存
- **Neo4j**: 512MB内存
- **Elasticsearch**: 512MB内存
- **Weaviate**: 512MB内存

### **监控指标**
- **CPU使用率**: 实时监控
- **内存使用率**: 实时监控
- **磁盘I/O**: 实时监控
- **网络I/O**: 实时监控
- **数据库连接数**: 实时监控

---

## 🔄 **备份和恢复**

### **数据备份**
```bash
# MySQL备份
docker exec future-mysql mysqldump -u root -pf_mysql_root_2025 jobfirst_future > backup/mysql_backup.sql

# PostgreSQL备份
docker exec future-postgresql pg_dump -U future_user f_pg > backup/postgresql_backup.sql

# Redis备份
docker exec future-redis redis-cli -a f_redis_password_2025 BGSAVE
```

### **数据恢复**
```bash
# MySQL恢复
docker exec -i future-mysql mysql -u root -pf_mysql_root_2025 jobfirst_future < backup/mysql_backup.sql

# PostgreSQL恢复
docker exec -i future-postgresql psql -U future_user f_pg < backup/postgresql_backup.sql
```

---

## 🎉 **部署完成**

### **验证清单**
- ✅ 所有7个数据库服务正常运行
- ✅ 数据库结构创建完成
- ✅ 外部访问正常
- ✅ 监控功能正常
- ✅ 日志记录正常

### **下一步**
1. **功能测试**: 进行完整的功能测试
2. **性能测试**: 进行性能压力测试
3. **监控部署**: 部署监控和告警系统
4. **文档更新**: 更新操作文档

---

**Future版本部署指南完成！** 🚀

**所有数据库服务已就绪，可以开始使用Future版本的多数据库功能！** 🎯
