# 环境隔离配置指南

## 🎯 概述

本文档详细说明了JobFirst系统的环境隔离配置，确保开发、测试、生产环境完全分离，提高系统安全性和稳定性。

## 🏗️ 环境架构

### 环境层次结构
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   开发环境       │    │   测试环境       │    │   生产环境       │
│  (Development)  │    │   (Testing)     │    │  (Production)   │
├─────────────────┤    ├─────────────────┤    ├─────────────────┤
│ 本地开发机器     │    │ 阿里云测试实例   │    │ 阿里云生产实例   │
│ localhost       │    │ test-server     │    │ prod-server     │
│ 端口: 8080      │    │ 端口: 8080      │    │ 端口: 80/443    │
│ 数据库: dev     │    │ 数据库: test    │    │ 数据库: prod    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🔧 环境配置

### 1. 开发环境 (Development)

#### 1.1 本地配置
```yaml
# config/development.yaml
environment: development
debug: true
log_level: debug

server:
  port: "8080"
  host: "localhost"

database:
  driver: "mysql"
  host: "localhost"
  port: "3306"
  name: "jobfirst_dev"
  user: "root"
  password: "dev_password"
  charset: "utf8mb4"
  max_open_conns: 10
  max_idle_conns: 5

redis:
  host: "localhost"
  port: "6379"
  password: ""
  db: 0

ai:
  enabled: true
  service_url: "http://localhost:8206"
  timeout: 30s

# 开发环境监控配置 - 最小化监控
monitoring:
  enabled: false
  metrics: false
  alerts: false
  prometheus: false
  grafana: false

logging:
  level: "debug"
  format: "text"
  output: "console"
  file: ""
```

#### 1.2 启动脚本
```bash
#!/bin/bash
# scripts/start-dev.sh
echo "启动开发环境..."

# 启动数据库服务
brew services start mysql
brew services start redis

# 启动后端服务
cd backend
go run cmd/basic-server/main.go --config=../config/development.yaml

# 启动前端服务
cd ../frontend-taro
npm run dev:h5
```

### 2. 测试环境 (Testing)

#### 2.1 阿里云测试实例配置
```yaml
# config/testing.yaml
environment: testing
debug: false
log_level: info

server:
  port: "8080"
  host: "0.0.0.0"

database:
  driver: "mysql"
  host: "test-db-server"
  port: "3306"
  name: "jobfirst_test"
  user: "test_user"
  password: "test_password_2024"
  charset: "utf8mb4"
  max_open_conns: 20
  max_idle_conns: 10

redis:
  host: "test-redis-server"
  port: "6379"
  password: "test_redis_2024"
  db: 0

ai:
  enabled: true
  service_url: "http://test-ai-server:8206"
  timeout: 30s

# 测试环境监控配置 - 基础监控
monitoring:
  enabled: true
  metrics: true
  alerts: true
  prometheus: false  # 测试环境不使用Prometheus
  grafana: false     # 测试环境不使用Grafana

logging:
  level: "info"
  format: "json"
  output: "file"
  file: "/opt/jobfirst/logs/test.log"
  max_size: 50
  max_age: 7
```

#### 2.2 测试环境部署
```bash
#!/bin/bash
# scripts/deploy-test.sh
echo "部署到测试环境..."

# 构建测试版本
docker build -t jobfirst:test .

# 部署到测试服务器
docker-compose -f docker-compose.testing.yml up -d

# 运行测试
npm run test:integration
```

### 3. 生产环境 (Production)

#### 3.1 阿里云生产实例配置
```yaml
# config/production.yaml
environment: production
debug: false
log_level: warn

server:
  port: "8080"
  host: "0.0.0.0"
  read_timeout: 30s
  write_timeout: 30s

database:
  driver: "mysql"
  host: "prod-db-server"
  port: "3306"
  name: "jobfirst_prod"
  user: "prod_user"
  password: "prod_password_2024"
  charset: "utf8mb4"
  max_open_conns: 100
  max_idle_conns: 20
  conn_max_lifetime: 3600s

redis:
  host: "prod-redis-server"
  port: "6379"
  password: "prod_redis_2024"
  db: 0
  pool_size: 20

ai:
  enabled: true
  service_url: "http://prod-ai-server:8206"
  timeout: 30s
  max_retries: 3

# 生产环境监控配置 - 完整监控栈
monitoring:
  enabled: true
  metrics: true
  alerts: true
  prometheus: true
  grafana: true
  elk: true

logging:
  level: "warn"
  format: "json"
  output: "file"
  file: "/opt/jobfirst/logs/prod.log"
  max_size: 100
  max_age: 30
  max_backups: 10
```

#### 3.2 生产环境部署
```bash
#!/bin/bash
# scripts/deploy-prod.sh
echo "部署到生产环境..."

# 构建生产版本
docker build -t jobfirst:prod .

# 部署到生产服务器
docker-compose -f docker-compose.production.yml up -d

# 健康检查
curl -f http://localhost/health
```

## 🔐 安全隔离

### 1. 网络隔离
```yaml
# 开发环境
network:
  type: "bridge"
  subnet: "172.17.0.0/16"

# 测试环境
network:
  type: "vpc"
  subnet: "10.0.1.0/24"
  security_groups: ["test-sg"]

# 生产环境
network:
  type: "vpc"
  subnet: "10.0.0.0/24"
  security_groups: ["prod-sg"]
  load_balancer: true
```

### 2. 数据库隔离
```sql
-- 开发环境数据库
CREATE DATABASE jobfirst_dev CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'dev_user'@'%' IDENTIFIED BY 'dev_password';
GRANT ALL PRIVILEGES ON jobfirst_dev.* TO 'dev_user'@'%';

-- 测试环境数据库
CREATE DATABASE jobfirst_test CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'test_user'@'%' IDENTIFIED BY 'test_password';
GRANT ALL PRIVILEGES ON jobfirst_test.* TO 'test_user'@'%';

-- 生产环境数据库
CREATE DATABASE jobfirst_prod CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'prod_user'@'%' IDENTIFIED BY 'prod_password';
GRANT ALL PRIVILEGES ON jobfirst_prod.* TO 'prod_user'@'%';
```

### 3. 密钥管理
```bash
# 开发环境 - 使用简单密钥
JWT_SECRET="dev-secret-key"
DB_PASSWORD="dev_password"

# 测试环境 - 使用中等强度密钥
JWT_SECRET="test-secret-key-2024"
DB_PASSWORD="test_password_2024"

# 生产环境 - 使用高强度密钥
JWT_SECRET="prod-secret-key-2024-very-long-and-secure"
DB_PASSWORD="prod_password_2024_very_secure"
```

## 🚀 CI/CD集成

### 1. 分支策略
```yaml
# .github/workflows/smart-cicd.yml
branches:
  main:      # 生产环境
    environment: production
    auto_deploy: true
    health_check: true
  
  develop:   # 测试环境
    environment: testing
    auto_deploy: true
    health_check: true
  
  feature/*: # 开发环境
    environment: development
    auto_deploy: false
    health_check: false
```

### 2. 环境变量配置
```bash
# GitHub Secrets配置
# 开发环境
DEV_DB_HOST=localhost
DEV_DB_PASSWORD=dev_password

# 测试环境
TEST_SERVER_IP=test-server-ip
TEST_DB_PASSWORD=test_password_2024
TEST_SSH_KEY=test-ssh-private-key

# 生产环境
PROD_SERVER_IP=prod-server-ip
PROD_DB_PASSWORD=prod_password_2024
PROD_SSH_KEY=prod-ssh-private-key
```

## 📊 监控和日志

### 1. 环境特定监控
```yaml
# 开发环境监控
monitoring:
  enabled: false
  log_level: debug
  metrics: false

# 测试环境监控
monitoring:
  enabled: true
  log_level: info
  metrics: true
  alerts: false

# 生产环境监控
monitoring:
  enabled: true
  log_level: warn
  metrics: true
  alerts: true
  prometheus: true
  grafana: true
```

### 2. 日志配置
```yaml
# 开发环境日志
logging:
  level: "debug"
  format: "text"
  output: "console"
  file: ""

# 测试环境日志
logging:
  level: "info"
  format: "json"
  output: "file"
  file: "/opt/jobfirst/logs/test.log"
  max_size: 50
  max_age: 7

# 生产环境日志
logging:
  level: "warn"
  format: "json"
  output: "file"
  file: "/opt/jobfirst/logs/prod.log"
  max_size: 100
  max_age: 30
  max_backups: 10
```

## 🔄 部署流程

### 1. 开发到测试
```bash
# 1. 开发完成，推送到develop分支
git checkout develop
git merge feature/new-feature
git push origin develop

# 2. 自动触发测试环境部署
# GitHub Actions自动执行测试环境部署

# 3. 测试验证
curl -f http://test-server/health
npm run test:integration
```

### 2. 测试到生产
```bash
# 1. 测试通过，合并到main分支
git checkout main
git merge develop
git push origin main

# 2. 自动触发生产环境部署
# GitHub Actions自动执行生产环境部署

# 3. 生产验证
curl -f http://prod-server/health
curl -f https://your-domain.com/health
```

## 🛡️ 安全最佳实践

### 1. 访问控制
- 开发环境: 仅开发人员访问
- 测试环境: 开发人员和测试人员访问
- 生产环境: 仅运维人员访问

### 2. 数据隔离
- 开发环境: 使用模拟数据
- 测试环境: 使用脱敏数据
- 生产环境: 使用真实数据

### 3. 备份策略
- 开发环境: 无需备份
- 测试环境: 每日备份
- 生产环境: 实时备份 + 每日备份

## 📋 检查清单

### 环境隔离验证
- [ ] 开发环境独立运行
- [ ] 测试环境独立运行
- [ ] 生产环境独立运行
- [ ] 数据库完全隔离
- [ ] 网络访问控制
- [ ] 密钥管理分离
- [ ] 监控系统独立
- [ ] 日志系统独立

### 部署验证
- [ ] 开发环境部署成功
- [ ] 测试环境部署成功
- [ ] 生产环境部署成功
- [ ] 健康检查通过
- [ ] 功能测试通过
- [ ] 性能测试通过
- [ ] 安全测试通过

---

**配置完成时间**: 2024年9月10日  
**配置状态**: ✅ 完成  
**下一步**: 配置GitHub Secrets并触发CI/CD部署
