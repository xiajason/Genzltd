# 超级管理员设置指南

## 🎯 概述

本指南详细说明如何为项目负责人设置超级管理员权限，实现直接管理团队成员而无需通过常规注册认证流程。

## 🚀 快速开始

### 1. 使用zervigo工具设置超级管理员

```bash
# 进入zervigo工具目录
cd /opt/jobfirst/backend/pkg/jobfirst-core/superadmin

# 构建zervigo工具
go build -o zervigo ./cmd/zervigo

# 设置超级管理员
./zervigo super-admin setup

# 查看超级管理员状态
./zervigo super-admin status
```

### 2. 传统方式：执行超级管理员初始化脚本

```bash
# 进入项目目录
cd /opt/jobfirst

# 给脚本执行权限
chmod +x scripts/setup-super-admin.sh

# 执行初始化脚本
sudo ./scripts/setup-super-admin.sh
```

### 3. 脚本执行过程

脚本将引导您完成以下步骤：

1. **输入您的信息**：
   - 用户名（默认：admin）
   - 邮箱地址
   - 真实姓名
   - 密码

2. **自动创建**：
   - 用户账号
   - 超级管理员权限
   - SSH密钥对
   - 管理脚本

3. **生成管理工具**：
   - 添加团队成员脚本
   - 查看团队成员脚本
   - 快速登录信息

## 🔐 超级管理员权限

### 权限矩阵

| 权限类型 | 超级管理员权限 |
|---------|---------------|
| 服务器访问 | ✅ 完全访问 |
| 代码修改 | ✅ 所有模块 |
| 数据库操作 | ✅ 所有数据库 |
| 服务重启 | ✅ 所有服务 |
| 配置修改 | ✅ 所有配置 |
| 用户管理 | ✅ 完全管理 |
| 权限分配 | ✅ 完全控制 |

### 可管理的角色

- **system_admin** - 系统管理员
- **dev_lead** - 开发负责人
- **frontend_dev** - 前端开发
- **backend_dev** - 后端开发
- **qa_engineer** - 测试工程师
- **guest** - 访客用户

## 📱 登录方式

### 1. Web界面登录

```
URL: http://101.33.251.158/login
用户名: [您设置的用户名]
密码: [您设置的密码]
```

### 2. API接口登录

```bash
curl -X POST http://101.33.251.158/api/v1/super-admin/public/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "您的用户名",
    "password": "您的密码"
  }'
```

### 3. SSH密钥登录

```bash
# 使用生成的SSH密钥登录服务器
ssh -i /opt/jobfirst/.ssh/id_rsa jobfirst-admin@101.33.251.158
```

## 👥 团队成员管理

### 添加团队成员

#### 方法1：使用脚本

```bash
# 使用管理脚本添加团队成员
./scripts/add-team-member.sh <username> <role> <email> <real_name>

# 示例
./scripts/add-team-member.sh john_doe frontend_dev john@example.com "John Doe"
```

#### 方法2：使用API接口

```bash
curl -X POST http://101.33.251.158/api/v1/dev-team/admin/members \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "john_doe",
    "email": "john@example.com",
    "password": "secure_password",
    "first_name": "John",
    "last_name": "Doe",
    "team_role": "frontend_dev",
    "phone": "+86-138-0000-0000"
  }'
```

### 查看团队成员

```bash
# 使用脚本查看
./scripts/list-team-members.sh

# 或使用API接口
curl -X GET http://101.33.251.158/api/v1/dev-team/admin/members \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### 更新成员权限

```bash
curl -X PUT http://101.33.251.158/api/v1/dev-team/admin/members/1 \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "team_role": "backend_dev",
    "server_access_level": "limited",
    "code_access_modules": "[\"backend\"]",
    "database_access": "[\"development\"]",
    "service_restart_permissions": "[\"backend\"]"
  }'
```

## 🔧 管理功能

### 1. 团队统计信息

```bash
curl -X GET http://101.33.251.158/api/v1/dev-team/admin/stats \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### 2. 操作日志查看

```bash
curl -X GET "http://101.33.251.158/api/v1/dev-team/admin/logs?page=1&page_size=20" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### 3. 权限配置管理

```bash
curl -X GET http://101.33.251.158/api/v1/dev-team/admin/permissions \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

## 🛠️ 系统维护

### 1. 检查超级管理员状态

```sql
-- 在MySQL中执行
CALL CheckSuperAdminStatus();
```

### 2. 重置超级管理员密码

```bash
# 使用脚本重置
./scripts/reset-super-admin-password.sh
```

### 3. 备份团队数据

```bash
# 备份团队成员数据
mysqldump -u root -p jobfirst dev_team_users dev_operation_logs > team_backup_$(date +%Y%m%d_%H%M%S).sql
```

## 🔒 安全建议

### 1. 密码安全

- 使用强密码（至少12位，包含大小写字母、数字和特殊字符）
- 定期更换密码
- 不要在公共场所输入密码

### 2. SSH密钥安全

- 妥善保管私钥文件
- 定期更换SSH密钥对
- 限制SSH访问IP地址

### 3. 访问控制

- 定期审查团队成员权限
- 及时移除不再需要的成员
- 监控异常登录行为

## 📊 监控和审计

### 1. 使用zervigo工具进行监控

```bash
# 查看系统整体状态
./zervigo status

# 查看超级管理员状态
./zervigo super-admin status

# 查看权限信息
./zervigo super-admin permissions

# 查看操作日志
./zervigo super-admin logs

# 执行数据库校验
./zervigo validate all

# 查看地理位置服务状态
./zervigo geo status

# 查看Neo4j状态
./zervigo neo4j status
```

### 2. 传统监控方式

```bash
# 查看登录日志
tail -f /opt/jobfirst/logs/auth.log

# 查看操作日志
mysql -u root -p -D jobfirst -e "SELECT * FROM dev_operation_logs ORDER BY created_at DESC LIMIT 10;"

# 检查服务状态
systemctl status basic-server
systemctl status mysql
systemctl status nginx

# 检查磁盘空间
df -h

# 检查内存使用
free -h
```

## 🚨 故障排除

### 常见问题

#### 1. 无法登录

**问题**：提示"用户不存在或已被禁用"

**解决方案**：
```bash
# 检查用户状态
mysql -u root -p -D jobfirst -e "SELECT username, status FROM users WHERE username='your_username';"

# 检查开发团队成员状态
mysql -u root -p -D jobfirst -e "SELECT * FROM dev_team_users WHERE user_id=(SELECT id FROM users WHERE username='your_username');"
```

#### 2. 权限不足

**问题**：提示"需要超级管理员权限"

**解决方案**：
```bash
# 检查角色权限
mysql -u root -p -D jobfirst -e "SELECT team_role, status FROM dev_team_users WHERE user_id=(SELECT id FROM users WHERE username='your_username');"
```

#### 3. 数据库连接失败

**问题**：脚本执行时数据库连接失败

**解决方案**：
```bash
# 检查MySQL服务
systemctl status mysql

# 检查配置文件
cat /opt/jobfirst/backend/configs/config.yaml

# 测试连接
mysql -u root -p -e "SELECT 1;"
```

## 📞 技术支持

### 联系方式

- **系统管理员**: admin@jobfirst.com
- **技术支持**: support@jobfirst.com
- **紧急联系**: +86-xxx-xxxx-xxxx

### 文档资源

- **API文档**: http://101.33.251.158/api-docs
- **用户手册**: /opt/jobfirst/docs/
- **部署指南**: /opt/jobfirst/scripts/

## 🎉 总结

通过本指南，您已经成功设置了超级管理员权限，可以：

1. ✅ **直接登录系统** - 无需注册认证流程
2. ✅ **完全管理权限** - 拥有所有系统权限
3. ✅ **团队成员管理** - 添加、修改、删除团队成员
4. ✅ **权限分配控制** - 为不同角色分配相应权限
5. ✅ **操作审计监控** - 完整的操作日志记录
6. ✅ **数据库校验** - 使用zervigo工具进行完整的数据库校验
7. ✅ **地理位置服务** - 管理地理位置数据和北斗服务集成
8. ✅ **Neo4j图数据库** - 管理图数据库和智能匹配功能
9. ✅ **系统监控** - 使用zervigo工具进行实时系统监控

现在您可以开始管理您的开发团队，实现高效的协同开发工作！

## 🆕 新增功能

### zervigo工具增强功能

- **数据库校验**: 支持MySQL、Redis、PostgreSQL、Neo4j的完整校验
- **地理位置服务**: 地理位置数据管理和北斗服务集成
- **Neo4j图数据库**: 图数据库管理和智能匹配功能
- **超级管理员管理**: 完整的超级管理员管理系统

### 使用建议

1. **定期校验**: 使用 `./zervigo validate all` 定期校验数据库状态
2. **监控系统**: 使用 `./zervigo status` 监控系统整体状态
3. **管理权限**: 使用 `./zervigo super-admin status` 查看超级管理员状态
4. **地理位置**: 使用 `./zervigo geo status` 管理地理位置服务

---

**注意**: 请妥善保管您的超级管理员账号信息，这是您管理整个系统的关键凭证。
