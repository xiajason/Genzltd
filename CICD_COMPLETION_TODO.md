# CI/CD完成后的待办事项清单

**创建时间**: 2025-10-07  
**状态**: ⏳ 等待CI/CD完成  
**带宽限制**: 5Mbps - 避免在CI/CD运行时SSH操作

---

## 📊 当前CI/CD状态

```yaml
监控链接: https://github.com/xiajason/Genzltd/actions

预期结果:
  ⚠️ Zervigo可能失败 (数据库密码问题)
  ⚠️ AI服务会失败 (PostgreSQL配置错误)
  ⚠️ LoomaCRM会失败 (多数据库配置缺失)

已知问题清单:
  1. TENCENT_DB_PASSWORD需要更新
  2. PostgreSQL用户名错误
  3. Redis密码缺失
  4. Neo4j配置缺失
  5. Elasticsearch配置缺失
  6. Weaviate配置缺失
```

---

## ✅ 已掌握的数据库配置信息

### **完整的test-数据库集群配置**

```yaml
test-mysql (3306):
  Root密码: test_mysql_password
  数据库: jobfirst, jobfirst_future
  用户: root, future_user (f_mysql_password_2025)
  状态: ✅ 已配置完成

test-postgres (5432):
  用户: test_user
  密码: test_postgres_password
  现有数据库: test_users, postgres
  需要创建: jobfirst_vector, looma_independent
  状态: ⚠️ 需要创建数据库

test-redis (6379):
  密码: test_redis_password
  状态: ✅ 运行中

test-neo4j (7474/7687):
  用户: neo4j
  密码: test_neo4j_password
  状态: ✅ 运行中

test-elasticsearch (9200):
  认证: 无密码
  状态: ✅ 运行中

test-weaviate (8080):
  认证: 匿名访问
  状态: ✅ 运行中
```

---

## 📋 CI/CD完成后的操作清单

### **步骤1: 查看CI/CD结果** (5分钟)

```bash
# 访问GitHub Actions查看结果
https://github.com/xiajason/Genzltd/actions

# 预期:
# - Test阶段: ✅ 应该成功
# - Zervigo部署: ❌ 可能失败 (数据库密码)
# - AI服务部署: ❌ 会失败 (PostgreSQL配置)
# - LoomaCRM部署: ❌ 会失败 (多数据库配置)

# 记录失败的具体错误信息
```

---

### **步骤2: SSH配置PostgreSQL数据库** (10分钟)

⚠️ **注意**: 只在CI/CD完成后执行，避免带宽竞争

```bash
# SSH登录腾讯云
ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158

# 创建jobfirst_vector数据库
docker exec test-postgres psql -U test_user -d test_users -c "
CREATE DATABASE jobfirst_vector 
    WITH OWNER = test_user 
    ENCODING = 'UTF8';
"

# 创建looma_independent数据库
docker exec test-postgres psql -U test_user -d test_users -c "
CREATE DATABASE looma_independent 
    WITH OWNER = test_user 
    ENCODING = 'UTF8';
"

# 验证数据库创建
docker exec test-postgres psql -U test_user -d test_users -c "\l"

# 测试连接
docker exec test-postgres psql -U test_user -d jobfirst_vector -c "SELECT current_database();"
```

---

### **步骤3: 更新CI/CD脚本** (20分钟)

需要修改文件: `.github/workflows/deploy-tencent-cloud.yml`

#### **3.1 更新Zervigo配置**

```yaml
# 当前 (第162行):
export DATABASE_URL="future_user:${{ secrets.TENCENT_DB_PASSWORD }}@tcp(localhost:3306)/jobfirst_future?..."

# 保持不变，但需要更新Secret:
# TENCENT_DB_PASSWORD = f_mysql_password_2025
```

#### **3.2 更新AI服务配置**

修改AI服务1和AI服务2的环境变量配置 (第276-294行 和 第370-388行):

```yaml
# 当前配置 (错误):
cat > .env << 'ENVEOF'
# 数据库配置
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres                              # ❌ 错误
DB_PASSWORD=${{ secrets.TENCENT_DB_PASSWORD }}  # ❌ 错误
DB_NAME=jobfirst_vector

# MySQL配置
MYSQL_HOST=localhost
MYSQL_PORT=3306
MYSQL_USER=root
MYSQL_PASSWORD=${{ secrets.TENCENT_DB_PASSWORD }}  # ❌ 错误
MYSQL_DB=jobfirst                              # ❌ 错误

# Redis配置
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=                                # ❌ 缺失
ENVEOF

# 应该改为 (正确):
cat > .env << 'ENVEOF'
# PostgreSQL配置
DB_HOST=localhost
DB_PORT=5432
DB_USER=test_user                              # ✅ 正确
DB_PASSWORD=test_postgres_password             # ✅ 正确
DB_NAME=jobfirst_vector

# MySQL配置
MYSQL_HOST=localhost
MYSQL_PORT=3306
MYSQL_USER=root
MYSQL_PASSWORD=test_mysql_password             # ✅ 正确
MYSQL_DB=jobfirst

# Redis配置
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=test_redis_password             # ✅ 添加

# 认证配置
JWT_SECRET=${{ secrets.JWT_SECRET }}
ZERVIGO_AUTH_URL=http://localhost:8207
ENVEOF
```

#### **3.3 更新LoomaCRM配置**

修改LoomaCRM的环境变量配置 (第466-484行):

```yaml
# 需要添加完整的7个数据库配置:
cat > .env << 'ENVEOF'
# MySQL配置
MYSQL_HOST=localhost
MYSQL_PORT=3306
MYSQL_USER=root
MYSQL_PASSWORD=test_mysql_password
MYSQL_DB=jobfirst

# PostgreSQL配置
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_USER=test_user
POSTGRES_PASSWORD=test_postgres_password
POSTGRES_DB=looma_independent

# Redis配置
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=test_redis_password

# Neo4j配置
NEO4J_HOST=localhost
NEO4J_PORT=7687
NEO4J_HTTP_PORT=7474
NEO4J_USER=neo4j
NEO4J_PASSWORD=test_neo4j_password

# Elasticsearch配置
ELASTICSEARCH_HOST=localhost
ELASTICSEARCH_PORT=9200
ELASTICSEARCH_SCHEME=http

# Weaviate配置
WEAVIATE_HOST=localhost
WEAVIATE_PORT=8080
WEAVIATE_SCHEME=http

# 认证配置
JWT_SECRET=${{ secrets.JWT_SECRET }}
ZERVIGO_AUTH_URL=http://localhost:8207
ENVEOF
```

---

### **步骤4: 更新GitHub Secrets** (5分钟)

访问: https://github.com/xiajason/Genzltd/settings/secrets/actions

#### **方案A: 使用单一Secret (简化，推荐)**

因为所有密码都遵循 `test_<database>_password` 规则，可以统一管理：

```yaml
保留现有:
  TENCENT_CLOUD_USER=ubuntu
  TENCENT_CLOUD_SSH_KEY=(SSH私钥)
  JWT_SECRET=(JWT密钥)

修改:
  TENCENT_DB_PASSWORD=f_mysql_password_2025
  (用于Zervigo的future_user连接)

在CI/CD脚本中硬编码其他密码:
  - test_mysql_password (MySQL root)
  - test_postgres_password (PostgreSQL)
  - test_redis_password (Redis)
  - test_neo4j_password (Neo4j)
```

#### **方案B: 使用多个Secrets (规范，但复杂)**

```yaml
新增Secrets:
  TENCENT_MYSQL_PASSWORD=test_mysql_password
  TENCENT_POSTGRES_PASSWORD=test_postgres_password
  TENCENT_REDIS_PASSWORD=test_redis_password
  TENCENT_NEO4J_PASSWORD=test_neo4j_password
  TENCENT_MYSQL_FUTURE_PASSWORD=f_mysql_password_2025

优点: 安全性高
缺点: 管理复杂，需要更新多个地方
```

**推荐**: 方案A (硬编码test_*密码，只用Secret管理future_user密码)

---

### **步骤5: 提交并推送更新** (5分钟)

```bash
cd /Users/szjason72/genzltd

# 添加修改的文件
git add .github/workflows/deploy-tencent-cloud.yml

# 提交
git commit -m "fix: 完善多数据库配置

- 修正AI服务PostgreSQL用户为test_user
- 添加Redis密码配置
- 添加LoomaCRM的7个数据库配置
- 使用test-前缀容器集群
- 修正所有数据库密码配置"

# 推送到GitHub (会自动触发新的CI/CD)
git push origin main
```

---

### **步骤6: 重新触发CI/CD部署** (30-45分钟)

```yaml
触发方式:
  - 推送代码会自动触发
  - 或手动在GitHub Actions点击"Re-run all jobs"

监控:
  - https://github.com/xiajason/Genzltd/actions
  - 这次应该全部成功！

预期结果:
  ✅ Zervigo: 连接jobfirst_future成功
  ✅ AI服务1: 连接MySQL+PostgreSQL+Redis成功
  ✅ AI服务2: 连接MySQL+PostgreSQL+Redis成功
  ✅ LoomaCRM: 连接所有7个数据库成功
  ✅ Health Check: 所有服务健康
```

---

### **步骤7: 最终验证** (10分钟)

```bash
# 1. 测试所有服务健康检查
curl http://101.33.251.158:8207/health  # Zervigo
curl http://101.33.251.158:8100/health  # AI服务1
curl http://101.33.251.158:8110/health  # AI服务2
curl http://101.33.251.158:8700/health  # LoomaCRM

# 2. SSH登录查看服务状态
ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158

# 3. 查看运行的服务
ps aux | grep -E "unified-auth|ai_service|looma_crm"

# 4. 查看端口监听
netstat -tlnp | grep -E "8207|8100|8110|8700"

# 5. 查看服务日志
tail -50 /opt/services/zervigo/logs/zervigo.log
tail -50 /opt/services/ai-service-1/logs/service.log
tail -50 /opt/services/ai-service-2/logs/service.log
tail -50 /opt/services/looma-crm/logs/looma_crm.log

# 6. 测试数据库连接
docker exec test-mysql mysql -u future_user -pf_mysql_password_2025 jobfirst_future -e "SELECT DATABASE();"
docker exec test-postgres psql -U test_user -d jobfirst_vector -c "SELECT current_database();"
docker exec test-redis redis-cli -a test_redis_password PING
```

---

## 🎯 时间估算

```yaml
等待当前CI/CD: 30-45分钟 (当前运行中)
配置PostgreSQL: 10分钟 (CI/CD完成后)
更新CI/CD脚本: 20分钟
推送代码: 2分钟
重新部署: 30-45分钟
最终验证: 10分钟
---
总计: 约2-2.5小时
```

---

## ⚠️ 关键注意事项

### **5Mbps带宽限制**
```yaml
问题:
  - CI/CD运行时会占满带宽
  - SSH连接会频繁断开
  - 数据库操作可能超时

解决:
  ✅ 等待CI/CD完成后再SSH操作
  ✅ 一次性完成所有数据库配置
  ✅ 避免重复连接断开
```

### **数据库配置优先级**
```yaml
必须: MySQL, PostgreSQL, Redis
  - Zervigo和AI服务依赖

可选: Neo4j, Elasticsearch, Weaviate
  - LoomaCRM高级功能依赖
  - 初期可以跳过
```

---

## 📝 准备好的命令脚本

### **PostgreSQL数据库创建脚本**

```bash
#!/bin/bash
# create_postgres_databases.sh

echo "创建PostgreSQL数据库..."
ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158 << 'SSHEOF'
# 创建jobfirst_vector
docker exec test-postgres psql -U test_user -d test_users -c "
CREATE DATABASE jobfirst_vector WITH OWNER = test_user ENCODING = 'UTF8';
"

# 创建looma_independent
docker exec test-postgres psql -U test_user -d test_users -c "
CREATE DATABASE looma_independent WITH OWNER = test_user ENCODING = 'UTF8';
"

# 验证
docker exec test-postgres psql -U test_user -d test_users -c "\l" | grep -E "jobfirst|looma"

echo "✅ PostgreSQL数据库创建完成"
SSHEOF
```

### **所有数据库验证脚本**

```bash
#!/bin/bash
# verify_all_databases.sh

echo "验证所有数据库连接..."
ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158 << 'SSHEOF'
echo "1. MySQL:"
docker exec test-mysql mysql -u root -ptest_mysql_password -e "SHOW DATABASES;" 2>&1 | grep -v Warning

echo ""
echo "2. PostgreSQL:"
docker exec test-postgres psql -U test_user -d test_users -c "\l"

echo ""
echo "3. Redis:"
docker exec test-redis redis-cli -a test_redis_password PING 2>&1 | grep -v Warning

echo ""
echo "4. Neo4j:"
curl -s http://localhost:7474 | head -3

echo ""
echo "5. Elasticsearch:"
curl -s http://localhost:9200/_cluster/health?pretty

echo ""
echo "6. Weaviate:"
curl -s http://localhost:8080/v1/.well-known/ready

echo ""
echo "✅ 所有数据库验证完成"
SSHEOF
```

---

## 🎯 执行计划

```yaml
现在:
  ☕ 休息，等待CI/CD完成
  📊 监控: https://github.com/xiajason/Genzltd/actions
  ⏰ 设置提醒: 30-45分钟后查看

CI/CD完成后:
  1. 查看结果和错误日志
  2. SSH配置PostgreSQL数据库
  3. 更新CI/CD脚本环境变量
  4. 更新GitHub Secret (TENCENT_DB_PASSWORD)
  5. 推送代码重新部署
  6. 验证最终结果

预期最终成功:
  ✅ 所有10个问题解决
  ✅ 所有4个服务部署成功
  ✅ 所有数据库连接正常
  ✅ CI/CD自动化完全运行
```

---

**Created**: 2025-10-07  
**Next Action**: 等待CI/CD完成，查看结果

