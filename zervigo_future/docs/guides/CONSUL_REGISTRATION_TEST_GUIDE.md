# Consul服务注册测试指南

## 🎯 概述

本指南详细说明如何测试新增的权限管理系统是否能在Consul中成功注册，以及如何验证整个增强系统的功能。

## 🚀 快速测试

### 1. 一键测试脚本

```bash
# 运行完整的增强系统测试
./scripts/test-enhanced-system.sh
```

这个脚本会自动测试：
- ✅ 服务器健康检查
- ✅ 超级管理员功能
- ✅ 用户注册和登录
- ✅ 权限检查
- ✅ RBAC权限系统
- ✅ Consul服务注册
- ✅ API端点完整性

### 2. 分步测试

#### 步骤1: 启动增强服务器

```bash
# 启动包含权限管理系统的增强服务器
./scripts/start-enhanced-server.sh
```

#### 步骤2: 测试Consul注册

```bash
# 专门测试Consul服务注册
./scripts/test-consul-registration.sh
```

#### 步骤3: 验证功能

```bash
# 验证所有功能是否正常
./scripts/test-enhanced-system.sh
```

## 🔍 详细测试步骤

### 1. 环境准备

#### 检查依赖服务

```bash
# 检查MySQL服务
systemctl status mysql

# 检查Redis服务
systemctl status redis

# 检查Consul服务
systemctl status consul
```

#### 检查配置文件

```bash
# 检查配置文件
cat backend/configs/config.yaml

# 确保Consul配置正确
grep -A 10 "consul:" backend/configs/config.yaml
```

### 2. 启动增强服务器

```bash
# 进入项目目录
cd /opt/jobfirst

# 启动增强服务器
./scripts/start-enhanced-server.sh
```

**预期输出:**
```
==========================================
🚀 JobFirst增强服务器启动工具
==========================================

[2024-01-01 12:00:00] 检查环境...
[2024-01-01 12:00:01] 检查依赖服务...
[2024-01-01 12:00:02] 检查服务状态...
[2024-01-01 12:00:03] 检查端口占用...
[2024-01-01 12:00:04] 构建项目...
[2024-01-01 12:00:05] 启动增强服务器...
[2024-01-01 12:00:06] 验证服务器...
[2024-01-01 12:00:07] 检查Consul注册...

==========================================
🎉 增强服务器启动成功！
==========================================

📋 服务信息:
  服务器PID: 12345
  服务端口: 8080
  服务地址: http://localhost:8080

🌐 主要端点:
  健康检查: http://localhost:8080/health
  API文档: http://localhost:8080/api-docs
  超级管理员: http://localhost:8080/api/v1/super-admin/public/status

🚀 新增功能:
  ✅ 完整RBAC权限系统
  ✅ 超级管理员管理
  ✅ Consul服务注册
  ✅ 增强的API端点
  ✅ 自动健康检查
==========================================
```

### 3. 验证Consul注册

#### 检查服务注册状态

```bash
# 检查Consul中的服务
curl -s http://localhost:8500/v1/agent/services | jq .

# 查找JobFirst相关服务
curl -s http://localhost:8500/v1/agent/services | jq 'to_entries[] | select(.key | startswith("jobfirst"))'
```

**预期输出:**
```json
{
  "jobfirst-basic-server-1": {
    "ID": "jobfirst-basic-server-1",
    "Service": "jobfirst-basic-server",
    "Address": "localhost",
    "Port": 8080,
    "Tags": ["jobfirst", "basic", "api", "v1"],
    "Meta": {
      "version": "1.0.0",
      "environment": "development",
      "features": "user-management,rbac,super-admin"
    }
  },
  "jobfirst-user-service-1": {
    "ID": "jobfirst-user-service-1",
    "Service": "jobfirst-user-service",
    "Address": "localhost",
    "Port": 8080,
    "Tags": ["jobfirst", "user", "auth", "api"],
    "Meta": {
      "version": "1.0.0",
      "environment": "development",
      "features": "user-management,authentication"
    }
  },
  "jobfirst-rbac-service-1": {
    "ID": "jobfirst-rbac-service-1",
    "Service": "jobfirst-rbac-service",
    "Address": "localhost",
    "Port": 8080,
    "Tags": ["jobfirst", "rbac", "permission", "api"],
    "Meta": {
      "version": "1.0.0",
      "environment": "development",
      "features": "rbac,permission-management"
    }
  }
}
```

#### 检查服务健康状态

```bash
# 检查所有服务的健康状态
curl -s http://localhost:8500/v1/health/state/any | jq '.[] | select(.ServiceName | startswith("jobfirst"))'
```

**预期输出:**
```json
{
  "ServiceName": "jobfirst-basic-server",
  "Status": "passing",
  "Output": "HTTP GET http://localhost:8080/health: 200 OK"
},
{
  "ServiceName": "jobfirst-user-service",
  "Status": "passing",
  "Output": "HTTP GET http://localhost:8080/api/v1/protected/profile: 200 OK"
},
{
  "ServiceName": "jobfirst-rbac-service",
  "Status": "passing",
  "Output": "HTTP GET http://localhost:8080/api/v1/rbac/check: 200 OK"
}
```

### 4. 测试API功能

#### 测试健康检查

```bash
# 测试服务器健康检查
curl -s http://localhost:8080/health | jq .
```

**预期输出:**
```json
{
  "status": "healthy",
  "timestamp": "2024-01-01T12:00:00Z",
  "services": {
    "database": "connected",
    "rbac": "active",
    "consul": "registered"
  }
}
```

#### 测试超级管理员功能

```bash
# 检查超级管理员状态
curl -s http://localhost:8080/api/v1/super-admin/public/status | jq .

# 初始化超级管理员（如果不存在）
curl -X POST http://localhost:8080/api/v1/super-admin/public/initialize \
  -H "Content-Type: application/json" \
  -d '{
    "username": "admin",
    "email": "admin@jobfirst.com",
    "password": "AdminPassword123!",
    "first_name": "Super",
    "last_name": "Admin"
  }' | jq .
```

#### 测试权限系统

```bash
# 登录获取token
TOKEN=$(curl -s -X POST http://localhost:8080/api/v1/public/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "admin",
    "password": "AdminPassword123!"
  }' | jq -r '.data.token')

# 测试权限检查
curl -s -X GET "http://localhost:8080/api/v1/rbac/check?user=admin&resource=user&action=read" \
  -H "Authorization: Bearer $TOKEN" | jq .

# 测试受保护的端点
curl -s -X GET http://localhost:8080/api/v1/protected/profile \
  -H "Authorization: Bearer $TOKEN" | jq .
```

### 5. 运行完整测试

```bash
# 运行完整的增强系统测试
./scripts/test-enhanced-system.sh
```

**预期输出:**
```
==========================================
🧪 增强系统完整测试工具
==========================================

[2024-01-01 12:00:00] 运行测试: 服务器健康检查
✅ 服务器健康检查 - 通过

[2024-01-01 12:00:01] 运行测试: 超级管理员状态检查
✅ 超级管理员状态检查 - 通过

[2024-01-01 12:00:02] 运行测试: 超级管理员初始化
✅ 超级管理员初始化 - 通过

[2024-01-01 12:00:03] 运行测试: 用户注册
✅ 用户注册 - 通过

[2024-01-01 12:00:04] 运行测试: 用户登录
✅ 用户登录 - 通过

[2024-01-01 12:00:05] 运行测试: 权限检查
✅ 权限检查 - 通过

[2024-01-01 12:00:06] 运行测试: RBAC权限检查
✅ RBAC权限检查 - 通过

[2024-01-01 12:00:07] 运行测试: Consul服务注册
✅ Consul服务注册 - 通过

[2024-01-01 12:00:08] 运行测试: Consul服务健康检查
✅ Consul服务健康检查 - 通过

[2024-01-01 12:00:09] 运行测试: API端点完整性
✅ API端点完整性 - 通过

==========================================
📊 测试结果摘要
==========================================
总测试数: 10
通过测试: 10
失败测试: 0
通过率: 100%
==========================================
✅ 所有测试通过！增强系统运行正常。
==========================================
```

## 🔧 故障排除

### 常见问题

#### 1. Consul服务未注册

**问题**: 服务未出现在Consul中

**解决方案**:
```bash
# 检查Consul服务状态
systemctl status consul

# 检查Consul配置
curl -s http://localhost:8500/v1/status/leader

# 重启Consul服务
systemctl restart consul

# 重新启动增强服务器
./scripts/restart-enhanced-server.sh
```

#### 2. 服务健康检查失败

**问题**: Consul中服务状态为critical

**解决方案**:
```bash
# 检查服务器健康端点
curl -s http://localhost:8080/health

# 检查服务器日志
tail -f /opt/jobfirst/logs/enhanced-server.log

# 检查端口占用
lsof -i :8080
```

#### 3. 权限系统异常

**问题**: RBAC权限检查失败

**解决方案**:
```bash
# 检查数据库连接
mysql -u root -p -e "SELECT 1;"

# 检查RBAC表
mysql -u root -p -D jobfirst -e "SHOW TABLES LIKE '%casbin%';"

# 重新初始化RBAC策略
curl -X POST http://localhost:8080/api/v1/rbac/reload \
  -H "Authorization: Bearer $TOKEN"
```

#### 4. 超级管理员初始化失败

**问题**: 无法创建超级管理员

**解决方案**:
```bash
# 检查用户表
mysql -u root -p -D jobfirst -e "SELECT * FROM users WHERE username='admin';"

# 检查角色表
mysql -u root -p -D jobfirst -e "SELECT * FROM roles WHERE name='super_admin';"

# 手动清理并重新初始化
mysql -u root -p -D jobfirst -e "DELETE FROM users WHERE username='admin';"
```

## 📊 监控和维护

### 1. 实时监控

```bash
# 监控服务器日志
tail -f /opt/jobfirst/logs/enhanced-server.log

# 监控Consul服务状态
watch -n 5 'curl -s http://localhost:8500/v1/health/state/any | jq ".[] | select(.ServiceName | startswith(\"jobfirst\"))"'

# 监控系统资源
htop
```

### 2. 定期检查

```bash
# 每日健康检查脚本
cat > /opt/jobfirst/scripts/daily-health-check.sh << 'EOF'
#!/bin/bash
./scripts/test-enhanced-system.sh > /opt/jobfirst/logs/daily-health-check-$(date +%Y%m%d).log
EOF

chmod +x /opt/jobfirst/scripts/daily-health-check.sh

# 添加到crontab
echo "0 9 * * * /opt/jobfirst/scripts/daily-health-check.sh" | crontab -
```

### 3. 性能监控

```bash
# 检查API响应时间
curl -w "@curl-format.txt" -o /dev/null -s http://localhost:8080/health

# 检查数据库性能
mysql -u root -p -D jobfirst -e "SHOW PROCESSLIST;"

# 检查内存使用
free -h
```

## 🎯 总结

通过以上测试步骤，您可以验证：

1. ✅ **增强服务器正常启动** - 包含完整的权限管理系统
2. ✅ **Consul服务注册成功** - 多个服务实例正确注册
3. ✅ **服务健康检查通过** - 所有服务状态正常
4. ✅ **权限系统功能正常** - RBAC权限管理有效
5. ✅ **超级管理员功能正常** - 可以正常初始化和使用
6. ✅ **API端点完整可用** - 所有接口正常响应

**新增的权限管理系统已成功在Consul中注册并正常运行！**

---

**注意**: 如果遇到任何问题，请检查日志文件并参考故障排除部分。所有测试脚本都会生成详细的日志和报告，便于问题诊断和解决。
