# Redis配置修复指南

## 问题分析

根据您的观察，问题确实是：

1. **MySQL**: 用于用户认证和业务数据存储
2. **Redis**: 用于缓存简历访问数据，提升性能
3. **两者关系**: 独立的服务，不应该相互依赖

## 当前状态

- **Redis服务器**: 无密码运行 ✅
- **user-service配置**: 密码配置混乱 ❌

## 解决方案

### 步骤1: 修改配置文件

请修改 `user-service-config.yaml` 文件中的密码配置：

```yaml
redis:
  address: "localhost:6379"
  password: ""  # 留空，因为Redis无密码
  db: 0

database:
  host: "localhost"
  port: 3306
  name: "jobfirst"
  user: "jobfirst"
  password: "jobfirst123"  # 保持MySQL密码
```

### 步骤2: 上传配置文件

将修改后的配置文件上传到服务器：

```bash
scp -i ~/.ssh/basic.pem user-service-config.yaml ubuntu@101.33.251.158:/opt/jobfirst/user-service/config.yaml
```

### 步骤3: 重启user-service

```bash
ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158 "cd /opt/jobfirst/user-service && nohup ./user-service > user-service.log 2>&1 &"
```

## 验证

检查服务状态：

```bash
ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158 "ps aux | grep user-service | grep -v grep"
```

检查8081端口：

```bash
ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158 "curl -s http://localhost:8081/health"
```

## 架构说明

- **basic-server**: 管理员系统，不依赖consul，独立运行
- **user-service**: 客户系统，依赖consul注册，用于简历缓存
- **Redis**: 缓存服务，无密码，用于提升简历访问性能
- **MySQL**: 数据库服务，有密码，用于用户认证和业务数据
