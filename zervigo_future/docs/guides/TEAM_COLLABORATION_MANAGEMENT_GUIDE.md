# JobFirst 团队协作开发管理指南

## 📋 概述

本指南详细说明如何在腾讯云轻量应用服务器上实现安全的团队协作开发，包括用户账号管理、权限控制、安全策略等。

## 🎯 管理目标

- **安全性**：确保服务器和代码安全
- **可控性**：精确控制每个成员的访问权限
- **可追溯性**：记录所有操作日志
- **高效性**：支持多人同时协作开发

## 🏗️ 架构设计

### 1. 用户角色体系

```
超级管理员 (Super Admin)
├── 系统管理员 (System Admin)
├── 开发负责人 (Dev Lead)
├── 前端开发 (Frontend Dev)
├── 后端开发 (Backend Dev)
├── 测试工程师 (QA Engineer)
└── 访客用户 (Guest)
```

### 2. 权限矩阵

| 角色 | 服务器访问 | 代码修改 | 数据库操作 | 服务重启 | 配置修改 | 日志查看 |
|------|------------|----------|------------|----------|----------|----------|
| 超级管理员 | ✅ 完全访问 | ✅ 所有模块 | ✅ 所有数据库 | ✅ 所有服务 | ✅ 所有配置 | ✅ 所有日志 |
| 系统管理员 | ✅ 完全访问 | ✅ 所有模块 | ✅ 所有数据库 | ✅ 所有服务 | ✅ 系统配置 | ✅ 所有日志 |
| 开发负责人 | ✅ 完全访问 | ✅ 所有模块 | ✅ 业务数据库 | ✅ 业务服务 | ✅ 业务配置 | ✅ 业务日志 |
| 前端开发 | ✅ SSH访问 | ✅ 前端代码 | ❌ 数据库 | ❌ 服务重启 | ✅ 前端配置 | ✅ 前端日志 |
| 后端开发 | ✅ SSH访问 | ✅ 后端代码 | ✅ 业务数据库 | ✅ 业务服务 | ✅ 后端配置 | ✅ 后端日志 |
| 测试工程师 | ✅ SSH访问 | ✅ 测试代码 | ✅ 测试数据库 | ✅ 测试服务 | ✅ 测试配置 | ✅ 测试日志 |
| 访客用户 | ❌ 无访问 | ❌ 无权限 | ❌ 无权限 | ❌ 无权限 | ❌ 无权限 | ❌ 无权限 |

## 🔧 实施方案

### 方案一：腾讯云CAM + SSH密钥管理（推荐）

#### 1. 腾讯云CAM配置

**步骤1：创建子账号**
```bash
# 在腾讯云控制台创建子账号
# 访问：https://console.cloud.tencent.com/cam
# 为每个团队成员创建独立子账号
```

**步骤2：配置权限策略**
```json
{
    "version": "2.0",
    "statement": [
        {
            "effect": "allow",
            "action": [
                "lighthouse:DescribeInstances",
                "lighthouse:DescribeInstanceLoginKeyPair",
                "lighthouse:CreateInstanceLoginKeyPair"
            ],
            "resource": "qcs::lighthouse:*:*:instance/jobfirst-*"
        }
    ]
}
```

#### 2. SSH用户管理

**创建用户管理脚本**
```bash
#!/bin/bash
# 用户管理脚本

# 添加开发用户
add_dev_user() {
    local username=$1
    local role=$2
    local ssh_key=$3
    
    # 创建用户
    useradd -m -s /bin/bash $username
    
    # 设置用户组
    usermod -aG developers $username
    
    # 配置SSH密钥
    mkdir -p /home/$username/.ssh
    echo "$ssh_key" > /home/$username/.ssh/authorized_keys
    chmod 700 /home/$username/.ssh
    chmod 600 /home/$username/.ssh/authorized_keys
    chown -R $username:$username /home/$username/.ssh
    
    # 设置sudo权限
    case $role in
        "admin")
            echo "$username ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/dev-users
            ;;
        "developer")
            echo "$username ALL=(ALL) NOPASSWD:/opt/jobfirst/scripts/restart-services.sh,/opt/jobfirst/scripts/deploy.sh" >> /etc/sudoers.d/dev-users
            ;;
        "frontend")
            echo "$username ALL=(ALL) NOPASSWD:/opt/jobfirst/scripts/restart-frontend.sh" >> /etc/sudoers.d/dev-users
            ;;
    esac
    
    echo "用户 $username 创建成功，角色：$role"
}
```

### 方案二：基于JobFirst系统的用户管理

#### 1. 扩展用户表结构

```sql
-- 开发团队用户表
CREATE TABLE IF NOT EXISTS dev_team_users (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    team_role ENUM('super_admin', 'system_admin', 'dev_lead', 'frontend_dev', 'backend_dev', 'qa_engineer', 'guest') NOT NULL,
    ssh_public_key TEXT,
    server_access_level ENUM('full', 'limited', 'readonly', 'none') DEFAULT 'limited',
    code_access_modules JSON, -- 可访问的代码模块
    database_access JSON, -- 可访问的数据库
    service_restart_permissions JSON, -- 可重启的服务
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_team_role (team_role)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 操作日志表
CREATE TABLE IF NOT EXISTS dev_operation_logs (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    operation_type VARCHAR(100) NOT NULL,
    operation_target VARCHAR(255),
    operation_details JSON,
    ip_address VARCHAR(45),
    user_agent TEXT,
    status ENUM('success', 'failed', 'blocked') DEFAULT 'success',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_operation_type (operation_type),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

#### 2. 权限控制中间件

```go
// 开发团队权限中间件
func DevTeamAuthMiddleware(requiredRole string, requiredPermissions []string) gin.HandlerFunc {
    return func(c *gin.Context) {
        // 获取用户信息
        userID := c.GetInt("user_id")
        
        // 查询开发团队权限
        var devUser DevTeamUser
        if err := db.Where("user_id = ?", userID).First(&devUser).Error; err != nil {
            c.JSON(http.StatusForbidden, gin.H{"error": "Not a team member"})
            c.Abort()
            return
        }
        
        // 检查角色权限
        if !hasRolePermission(devUser.TeamRole, requiredRole) {
            c.JSON(http.StatusForbidden, gin.H{"error": "Insufficient role"})
            c.Abort()
            return
        }
        
        // 检查具体权限
        for _, permission := range requiredPermissions {
            if !hasPermission(devUser, permission) {
                c.JSON(http.StatusForbidden, gin.H{"error": "Insufficient permissions"})
                c.Abort()
                return
            }
        }
        
        // 记录操作日志
        logOperation(userID, c.Request.Method, c.Request.URL.Path, c.ClientIP())
        
        c.Set("dev_user", devUser)
        c.Next()
    }
}
```

## 🛡️ 安全策略

### 1. SSH安全配置

```bash
# /etc/ssh/sshd_config
Port 22
Protocol 2
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2
AllowUsers dev_user1 dev_user2 dev_user3
DenyUsers guest
```

### 2. 防火墙配置

```bash
# 只允许特定IP访问
ufw allow from 192.168.1.0/24 to any port 22
ufw allow from 10.0.0.0/8 to any port 22
ufw deny 22
```

### 3. 操作审计

```bash
# 启用auditd
systemctl enable auditd
systemctl start auditd

# 监控关键操作
auditctl -w /opt/jobfirst/ -p rwxa -k jobfirst_access
auditctl -w /etc/nginx/ -p rwxa -k nginx_config
auditctl -w /etc/mysql/ -p rwxa -k mysql_config
```

## 📊 监控和日志

### 1. 实时监控脚本

```bash
#!/bin/bash
# 团队协作监控脚本

echo "=== 团队协作监控 ==="
echo "时间: $(date)"
echo

# 当前登录用户
echo "1. 当前登录用户:"
who
echo

# SSH连接状态
echo "2. SSH连接状态:"
ss -tuln | grep :22
echo

# 系统资源使用
echo "3. 系统资源使用:"
top -bn1 | head -5
echo

# 最近操作日志
echo "4. 最近操作日志:"
tail -10 /var/log/auth.log | grep ssh
echo

# 项目文件修改记录
echo "5. 项目文件修改记录:"
find /opt/jobfirst -type f -mtime -1 -ls | head -10
echo
```

### 2. 操作日志记录

```go
// 操作日志记录函数
func logOperation(userID int, method, path, ip string) {
    log := DevOperationLog{
        UserID:          userID,
        OperationType:   method,
        OperationTarget: path,
        IPAddress:       ip,
        UserAgent:       c.GetHeader("User-Agent"),
        Status:          "success",
    }
    
    db.Create(&log)
}
```

## 🚀 部署步骤

### 1. 环境准备

```bash
# 创建开发用户组
groupadd developers

# 创建sudoers配置目录
mkdir -p /etc/sudoers.d
```

### 2. 用户创建

```bash
# 为每个团队成员创建账号
./scripts/create-dev-user.sh frontend_dev1 "frontend" "ssh-rsa AAAAB3NzaC1yc2E..."
./scripts/create-dev-user.sh backend_dev1 "backend" "ssh-rsa AAAAB3NzaC1yc2E..."
./scripts/create-dev-user.sh qa_engineer1 "qa" "ssh-rsa AAAAB3NzaC1yc2E..."
```

### 3. 权限配置

```bash
# 配置项目目录权限
chown -R root:developers /opt/jobfirst
chmod -R 775 /opt/jobfirst

# 配置日志目录权限
chown -R root:developers /opt/jobfirst/logs
chmod -R 755 /opt/jobfirst/logs
```

## 📋 管理工具

### 1. 用户管理界面

```typescript
// 开发团队管理页面
interface DevTeamUser {
  id: number;
  username: string;
  email: string;
  teamRole: 'super_admin' | 'system_admin' | 'dev_lead' | 'frontend_dev' | 'backend_dev' | 'qa_engineer' | 'guest';
  serverAccessLevel: 'full' | 'limited' | 'readonly' | 'none';
  codeAccessModules: string[];
  databaseAccess: string[];
  serviceRestartPermissions: string[];
  lastLoginAt: string;
  status: 'active' | 'inactive' | 'suspended';
}
```

### 2. 权限管理API

```go
// 开发团队管理API
type DevTeamController struct {
    db *gorm.DB
}

// 获取团队成员列表
func (dtc *DevTeamController) GetTeamMembers(c *gin.Context) {
    // 实现获取团队成员列表
}

// 添加团队成员
func (dtc *DevTeamController) AddTeamMember(c *gin.Context) {
    // 实现添加团队成员
}

// 更新成员权限
func (dtc *DevTeamController) UpdateMemberPermissions(c *gin.Context) {
    // 实现更新成员权限
}

// 获取操作日志
func (dtc *DevTeamController) GetOperationLogs(c *gin.Context) {
    // 实现获取操作日志
}
```

## 🔍 最佳实践

### 1. 安全最佳实践

- **最小权限原则**：只授予必要的权限
- **定期权限审查**：每月审查一次权限配置
- **强密码策略**：要求复杂密码和定期更换
- **双因素认证**：对管理员账号启用2FA
- **操作审计**：记录所有关键操作

### 2. 协作最佳实践

- **代码审查**：所有代码修改都需要审查
- **分支管理**：使用Git分支进行功能开发
- **环境隔离**：开发、测试、生产环境分离
- **文档更新**：及时更新技术文档
- **定期同步**：定期同步代码和配置

### 3. 监控最佳实践

- **实时监控**：监控系统状态和用户活动
- **异常告警**：设置异常操作告警
- **性能监控**：监控系统性能指标
- **日志分析**：定期分析操作日志
- **备份策略**：定期备份重要数据

## 📞 支持联系

如有问题，请联系：
- 系统管理员：admin@jobfirst.com
- 技术支持：support@jobfirst.com
- 紧急联系：+86-xxx-xxxx-xxxx

---

**注意**：本指南基于JobFirst系统的实际需求设计，请根据团队具体情况调整配置。
