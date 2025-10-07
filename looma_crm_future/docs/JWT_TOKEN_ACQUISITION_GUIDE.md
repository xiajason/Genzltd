# JWT Token获取指南

**创建日期**: 2025年9月23日  
**版本**: v1.0  
**目标**: 指导如何获取有效的JWT token进行Looma CRM与Zervigo的集成测试

---

## 🎯 概述

本指南详细说明如何通过Zervigo的统一认证服务获取有效的JWT token，用于Looma CRM AI重构项目的集成测试。

## 📋 认证服务信息

### 统一认证服务 (Unified Auth Service)
- **服务地址**: `http://localhost:8207`
- **服务名称**: `unified-auth-service`
- **版本**: `2.0.0`
- **JWT密钥**: `jobfirst-unified-auth-secret-key-2024`

### 支持的API端点
- `POST /api/v1/auth/login` - 用户登录
- `POST /api/v1/auth/validate` - JWT验证
- `GET /api/v1/auth/permission` - 权限检查
- `GET /api/v1/auth/user` - 获取用户信息
- `POST /api/v1/auth/access` - 访问验证
- `POST /api/v1/auth/log` - 访问日志
- `GET /api/v1/auth/roles` - 获取角色列表
- `GET /api/v1/auth/permissions` - 获取权限列表
- `GET /health` - 健康检查

---

## 🔐 可用测试用户

基于AI服务认证验证报告，以下用户可用于测试：

### 1. 管理员用户
```json
{
  "username": "admin",
  "password": "password",
  "role": "super_admin",
  "permissions": ["*"],
  "user_id": 1
}
```

### 2. 普通用户
```json
{
  "username": "szjason72",
  "password": "@SZxym2006",
  "role": "guest",
  "permissions": ["read:public"],
  "user_id": 4
}
```

### 3. 测试用户
```json
{
  "username": "testuser",
  "password": "testuser123",
  "role": "guest",
  "permissions": ["read:public"],
  "user_id": 2
}
```

### 4. 系统管理员
```json
{
  "username": "testuser2",
  "password": "testuser123",
  "role": "system_admin",
  "permissions": null,
  "user_id": 3
}
```

---

## 🚀 获取JWT Token步骤

### 步骤1: 检查认证服务状态

```bash
# 检查统一认证服务健康状态
curl http://localhost:8207/health
```

**预期响应**:
```json
{
  "status": "healthy",
  "service": "unified-auth-service",
  "timestamp": "2025-09-23T15:45:00.000Z",
  "version": "2.0.0",
  "features": [
    "unified_role_system",
    "complete_jwt_validation",
    "permission_management",
    "access_logging",
    "database_optimization"
  ]
}
```

### 步骤2: 用户登录获取Token

#### 使用admin用户登录
```bash
curl -X POST http://localhost:8207/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "admin",
    "password": "password"
  }'
```

**预期响应**:
```json
{
  "success": true,
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "username": "admin",
    "email": "admin@jobfirst.com",
    "role": "super_admin",
    "status": "active",
    "subscription_type": null,
    "subscription_expiry": null,
    "last_login": null,
    "created_at": "2025-09-11T00:36:04+08:00",
    "updated_at": "2025-09-19T00:45:58.584+08:00"
  },
  "permissions": ["*"]
}
```

#### 使用szjason72用户登录
```bash
curl -X POST http://localhost:8207/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "szjason72",
    "password": "@SZxym2006"
  }'
```

**预期响应**:
```json
{
  "success": true,
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 4,
    "username": "szjason72",
    "email": "347399@qq.com",
    "role": "guest",
    "status": "active",
    "subscription_type": "monthly",
    "subscription_expiry": "2025-10-13T07:53:56+08:00",
    "last_login": null,
    "created_at": "2025-09-17T14:45:08+08:00",
    "updated_at": "2025-09-19T00:46:07.29+08:00"
  },
  "permissions": ["read:public"]
}
```

### 步骤3: 验证Token有效性

```bash
# 使用获取到的token进行验证
curl -X POST http://localhost:8207/api/v1/auth/validate \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{
    "token": "YOUR_TOKEN_HERE"
  }'
```

**预期响应**:
```json
{
  "success": true,
  "valid": true,
  "user": {
    "user_id": 1,
    "username": "admin",
    "email": "admin@jobfirst.com",
    "role": "super_admin",
    "level": 4,
    "permissions": ["*"]
  },
  "expires_at": "2025-09-24T15:45:00.000Z"
}
```

---

## 🧪 使用Token进行集成测试

### 测试Looma CRM认证集成

#### 1. 测试Zervigo健康检查
```bash
curl http://localhost:8888/api/zervigo/health
```

#### 2. 测试认证保护的API
```bash
# 使用有效token测试人才同步API
curl -X POST http://localhost:8888/api/zervigo/talents/test123/sync \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{}'
```

#### 3. 测试AI聊天API
```bash
curl -X POST http://localhost:8888/api/zervigo/talents/test123/chat \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{
    "message": "Tell me about this talent"
  }'
```

#### 4. 测试职位匹配API
```bash
curl -X GET http://localhost:8888/api/zervigo/talents/test123/matches \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

---

## 🔧 自动化Token获取脚本

### 创建token获取脚本

```bash
#!/bin/bash
# get_jwt_token.sh

# 配置
AUTH_URL="http://localhost:8207"
USERNAME="admin"
PASSWORD="password"

# 获取token
echo "正在获取JWT token..."
RESPONSE=$(curl -s -X POST "$AUTH_URL/api/v1/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"$USERNAME\",\"password\":\"$PASSWORD\"}")

# 检查响应
if echo "$RESPONSE" | jq -e '.success' > /dev/null 2>&1; then
    TOKEN=$(echo "$RESPONSE" | jq -r '.token')
    echo "✅ Token获取成功:"
    echo "$TOKEN"
    echo ""
    echo "使用方法:"
    echo "curl -H \"Authorization: Bearer $TOKEN\" http://localhost:8888/api/zervigo/health"
else
    echo "❌ Token获取失败:"
    echo "$RESPONSE" | jq -r '.error // .message'
    exit 1
fi
```

### 使用脚本
```bash
chmod +x get_jwt_token.sh
./get_jwt_token.sh
```

---

## 📊 角色权限说明

### 角色层级
1. **guest** (Level 1) - 访客用户
   - 权限: `["read:public"]`
   - 描述: 只能访问公开内容

2. **user** (Level 2) - 普通用户
   - 权限: `["read:public", "read:own", "write:own"]`
   - 描述: 可以读取公开内容和自己的数据

3. **admin** (Level 3) - 管理员
   - 权限: `["read:public", "read:own", "write:own", "read:all", "write:all", "delete:own"]`
   - 描述: 可以管理所有数据

4. **super_admin** (Level 4) - 超级管理员
   - 权限: `["*"]`
   - 描述: 拥有所有权限

### 权限格式
- `read:public` - 读取公开内容
- `read:own` - 读取自己的数据
- `write:own` - 写入自己的数据
- `read:all` - 读取所有数据
- `write:all` - 写入所有数据
- `delete:own` - 删除自己的数据
- `*` - 所有权限

---

## 🐛 常见问题排查

### 问题1: 认证服务无法访问
```bash
# 检查服务状态
curl http://localhost:8207/health

# 如果无法访问，检查Zervigo服务是否启动
cd /Users/szjason72/zervi-basic/basic
./scripts/maintenance/smart-startup-enhanced.sh
```

### 问题2: 登录失败
```bash
# 检查用户名和密码是否正确
# 确认用户存在于数据库中
curl -X POST http://localhost:8207/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"password"}'
```

### 问题3: Token验证失败
```bash
# 检查token格式是否正确
# 确认token未过期
curl -X POST http://localhost:8207/api/v1/auth/validate \
  -H "Content-Type: application/json" \
  -d '{"token":"YOUR_TOKEN_HERE"}'
```

### 问题4: 权限不足
```bash
# 检查用户角色和权限
curl -X GET "http://localhost:8207/api/v1/auth/permission?user_id=1&permission=read:public" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

---

## 📝 测试用例示例

### 完整集成测试流程

```bash
#!/bin/bash
# complete_integration_test.sh

echo "🚀 开始完整集成测试..."

# 1. 获取token
echo "1. 获取JWT token..."
TOKEN_RESPONSE=$(curl -s -X POST "http://localhost:8207/api/v1/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"password"}')

if echo "$TOKEN_RESPONSE" | jq -e '.success' > /dev/null 2>&1; then
    TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.token')
    echo "✅ Token获取成功"
else
    echo "❌ Token获取失败"
    exit 1
fi

# 2. 测试Looma CRM健康检查
echo "2. 测试Looma CRM健康检查..."
HEALTH_RESPONSE=$(curl -s http://localhost:8888/health)
if echo "$HEALTH_RESPONSE" | jq -e '.status' > /dev/null 2>&1; then
    echo "✅ Looma CRM健康检查通过"
else
    echo "❌ Looma CRM健康检查失败"
fi

# 3. 测试Zervigo集成健康检查
echo "3. 测试Zervigo集成健康检查..."
ZERVIGO_HEALTH=$(curl -s http://localhost:8888/api/zervigo/health)
if echo "$ZERVIGO_HEALTH" | jq -e '.success' > /dev/null 2>&1; then
    echo "✅ Zervigo集成健康检查通过"
else
    echo "❌ Zervigo集成健康检查失败"
fi

# 4. 测试认证保护的API
echo "4. 测试认证保护的API..."
AUTH_TEST=$(curl -s -X POST "http://localhost:8888/api/zervigo/talents/test123/sync" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{}')

if echo "$AUTH_TEST" | jq -e '.success' > /dev/null 2>&1; then
    echo "✅ 认证保护API测试通过"
else
    echo "⚠️ 认证保护API测试: $(echo "$AUTH_TEST" | jq -r '.message // .error')"
fi

echo "🎉 集成测试完成！"
```

---

## 📚 相关文档

- [集成测试指南](./INTEGRATION_TESTING_GUIDE.md)
- [AI服务认证验证报告](../../basic/docs/reports/AI_SERVICE_AUTH_VERIFICATION_REPORT.md)
- [认证系统测试脚本](../../basic/scripts/test_auth_systems.sh)
- [统一认证服务API文档](../../basic/backend/pkg/jobfirst-core/auth/unified_auth_api.go)

---

## 🎯 总结

通过本指南，您可以：

1. **获取有效的JWT token** - 使用统一认证服务登录
2. **验证token有效性** - 确保token未过期且有效
3. **进行集成测试** - 使用token测试Looma CRM的认证保护API
4. **排查问题** - 解决常见的认证相关问题

**下一步**: 使用获取到的JWT token进行Looma CRM与Zervigo的完整业务功能集成测试。

---

**文档版本**: v1.0  
**最后更新**: 2025年9月23日  
**维护者**: AI Assistant
