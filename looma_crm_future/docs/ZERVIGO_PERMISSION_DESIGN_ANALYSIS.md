# Zervigo子系统权限角色设计方案分析

**创建日期**: 2025年9月23日 22:05  
**版本**: v1.0  
**目标**: 分析Zervigo子系统的权限角色设计，指导Looma CRM数据隔离和权限控制修复

---

## 🎯 Zervigo权限设计核心发现

### 1. 角色层次结构设计 ✅ **关键发现**

#### 角色定义 (constants.go)
```go
const (
    RoleGuest     = "guest"     // 访客
    RoleUser      = "user"      // 普通用户
    RoleVip       = "vip"       // VIP用户
    RoleModerator = "moderator" // 版主
    RoleAdmin     = "admin"     // 管理员
    RoleSuper     = "super"     // 超级管理员
)
```

#### 角色层次映射 (security.go)
```go
roleHierarchy := map[string]int{
    core.RoleGuest:     1,
    core.RoleUser:      2,
    core.RoleVip:       3,
    core.RoleModerator: 4,
    core.RoleAdmin:     5,
    core.RoleSuper:     6,
}
```

**关键洞察**: Zervigo使用数字层次结构，高级角色自动继承低级角色权限。

### 2. 权限类型设计 ✅ **关键发现**

#### 基础权限
```go
const (
    PermissionRead   = "read"
    PermissionWrite  = "write"
    PermissionDelete = "delete"
    PermissionAdmin  = "admin"
)
```

#### 业务权限
```go
const (
    PermissionUserManage   = "user:manage"
    PermissionResumeManage = "resume:manage"
    PermissionJobManage    = "job:manage"
    PermissionPointsManage = "points:manage"
    PermissionStatsView    = "stats:view"
    PermissionConfigManage = "config:manage"
)
```

**关键洞察**: 使用命名空间权限 (如 `user:manage`)，支持细粒度控制。

### 3. 权限检查逻辑 ✅ **关键发现**

#### 超级管理员特权
```go
// 超级管理员拥有所有权限
if userCtx.Role == core.RoleSuper {
    return true
}
```

#### 权限匹配逻辑
```go
// 检查用户权限
for _, permission := range userCtx.Permissions {
    if permission == requiredPermission || permission == core.PermissionAdmin {
        return true
    }
}
```

**关键洞察**: 超级管理员有全局特权，admin权限可以访问所有资源。

### 4. 租户权限设计 ✅ **关键发现**

#### 租户类型
```go
const (
    TenantAdmin      TenantType = "ADMIN"      // 管理员
    TenantPersonal   TenantType = "PERSONAL"   // 个人用户
    TenantEnterprise TenantType = "ENTERPRISE" // 企业用户
)
```

#### 租户默认权限
```go
func (j *JWTManager) GetTenantPermissions(tenantType TenantType) []string {
    switch tenantType {
    case TenantAdmin:
        return []string{"admin", "user:manage", "system:manage", "enterprise:manage"}
    case TenantPersonal:
        return []string{"user:read", "resume:manage", "job:apply", "profile:manage"}
    case TenantEnterprise:
        return []string{"enterprise:read", "job:manage", "candidate:view", "company:manage"}
    default:
        return []string{"user:read"}
    }
}
```

**关键洞察**: 基于租户类型自动分配权限，支持多租户架构。

### 5. 数据库设计 ✅ **关键发现**

#### 用户表结构
```sql
CREATE TABLE IF NOT EXISTS users (
    id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('super_admin', 'system_admin', 'dev_lead', 'frontend_dev', 'backend_dev', 'qa_engineer', 'guest') DEFAULT 'guest',
    status ENUM('active', 'inactive', 'suspended') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    last_login TIMESTAMP NULL,
    INDEX idx_username (username),
    INDEX idx_email (email),
    INDEX idx_role (role),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

**关键洞察**: 角色存储在用户表中，使用ENUM确保数据一致性。

---

## 🚀 基于Zervigo设计的修复方案

### 修复1: 角色层次结构对齐

#### 当前问题
我们的角色定义与Zervigo不一致，缺少层次结构。

#### 修复方案
```python
# 更新角色定义，对齐Zervigo设计
class Role(Enum):
    GUEST = "guest"     # 访客
    USER = "user"       # 普通用户
    VIP = "vip"         # VIP用户
    MODERATOR = "moderator"  # 版主
    ADMIN = "admin"     # 管理员
    SUPER = "super"     # 超级管理员

# 角色层次映射
ROLE_HIERARCHY = {
    Role.GUEST: 1,
    Role.USER: 2,
    Role.VIP: 3,
    Role.MODERATOR: 4,
    Role.ADMIN: 5,
    Role.SUPER: 6,
}
```

### 修复2: 权限检查逻辑优化

#### 当前问题
权限检查逻辑不够严格，缺少超级管理员特权。

#### 修复方案
```python
async def check_permission(self, request: PermissionRequest) -> PermissionDecision:
    """检查权限 - 基于Zervigo设计"""
    # 1. 超级管理员拥有所有权限
    if request.user_context.role == "super":
        return PermissionDecision(
            request=request,
            granted=True,
            reason="超级管理员拥有所有权限",
            matched_permissions=[]
        )
    
    # 2. 检查角色层次
    user_level = ROLE_HIERARCHY.get(request.user_context.role, 0)
    required_level = self._get_required_role_level(request.resource_type, request.action)
    
    if user_level < required_level:
        return PermissionDecision(
            request=request,
            granted=False,
            reason=f"角色级别不足: {request.user_context.role} < {required_level}"
        )
    
    # 3. 检查具体权限
    user_permissions = await self.role_manager.get_user_permissions(request.user_id)
    for permission in user_permissions:
        if (permission.resource_type == request.resource_type and 
            permission.action == request.action):
            return PermissionDecision(
                request=request,
                granted=True,
                reason="权限匹配成功",
                matched_permissions=[permission]
            )
    
    return PermissionDecision(
        request=request,
        granted=False,
        reason="没有匹配的权限"
    )
```

### 修复3: 数据隔离逻辑优化

#### 当前问题
数据隔离检查顺序错误，应该先检查隔离再检查权限。

#### 修复方案
```python
async def evaluate_access(self, request: AccessRequest) -> AccessDecision:
    """评估访问请求 - 基于Zervigo设计"""
    # 1. 超级管理员绕过所有检查
    if request.user_context.role == "super":
        await self._log_access(request, AccessResult.ALLOWED)
        return AccessDecision(
            request=request,
            result=AccessResult.ALLOWED,
            reason="超级管理员特权",
            isolation_level=IsolationLevel.GLOBAL
        )
    
    # 2. 检查数据隔离
    isolation_level = self._determine_isolation_level(request.user_context)
    isolation_engine = self.isolation_engines.get(isolation_level)
    
    if isolation_engine:
        is_isolated = await isolation_engine.check_isolation(
            request.user_context, 
            request.resource
        )
        
        if not is_isolated:
            return AccessDecision(
                request=request,
                result=AccessResult.DENIED,
                reason="数据隔离检查失败",
                isolation_level=isolation_level
            )
    
    # 3. 检查权限
    has_permission = await self.permission_engine.check_permission(
        request.user_context, 
        request.permission
    )
    
    if not has_permission:
        return AccessDecision(
            request=request,
            result=AccessResult.DENIED,
            reason="权限不足",
            isolation_level=isolation_level
        )
    
    # 4. 记录审计日志
    await self._log_access(request, AccessResult.ALLOWED)
    
    return AccessDecision(
        request=request,
        result=AccessResult.ALLOWED,
        reason="访问允许",
        isolation_level=isolation_level
    )
```

### 修复4: 权限配置完善

#### 当前问题
超级管理员权限配置不完整。

#### 修复方案
```python
def _initialize_default_roles(self):
    """初始化默认角色 - 基于Zervigo设计"""
    # 超级管理员 - 拥有所有权限
    super_admin = Role(
        role_id="super",
        name="超级管理员",
        description="拥有所有权限的超级管理员",
        permissions=[
            # 系统权限
            Permission(ResourceType.SYSTEM, ActionType.MANAGE, PermissionScope.GLOBAL),
            # 用户权限
            Permission(ResourceType.USER, ActionType.CREATE, PermissionScope.GLOBAL),
            Permission(ResourceType.USER, ActionType.READ, PermissionScope.GLOBAL),
            Permission(ResourceType.USER, ActionType.UPDATE, PermissionScope.GLOBAL),
            Permission(ResourceType.USER, ActionType.DELETE, PermissionScope.GLOBAL),
            Permission(ResourceType.USER, ActionType.MANAGE, PermissionScope.GLOBAL),
            # 项目权限
            Permission(ResourceType.PROJECT, ActionType.MANAGE, PermissionScope.GLOBAL),
            # 公司权限
            Permission(ResourceType.COMPANY, ActionType.MANAGE, PermissionScope.GLOBAL),
            # 简历权限
            Permission(ResourceType.RESUME, ActionType.MANAGE, PermissionScope.GLOBAL),
            # 职位权限
            Permission(ResourceType.JOB, ActionType.MANAGE, PermissionScope.GLOBAL),
            # 分析权限
            Permission(ResourceType.ANALYTICS, ActionType.MANAGE, PermissionScope.GLOBAL)
        ]
    )
    
    # 管理员 - 组织级权限
    admin = Role(
        role_id="admin",
        name="管理员",
        description="组织级管理员",
        permissions=[
            Permission(ResourceType.USER, ActionType.MANAGE, PermissionScope.ORGANIZATION),
            Permission(ResourceType.PROJECT, ActionType.MANAGE, PermissionScope.ORGANIZATION),
            Permission(ResourceType.COMPANY, ActionType.MANAGE, PermissionScope.ORGANIZATION),
            Permission(ResourceType.RESUME, ActionType.MANAGE, PermissionScope.ORGANIZATION),
            Permission(ResourceType.JOB, ActionType.MANAGE, PermissionScope.ORGANIZATION),
            Permission(ResourceType.ANALYTICS, ActionType.READ, PermissionScope.ORGANIZATION)
        ]
    )
    
    # 普通用户 - 基本权限
    user = Role(
        role_id="user",
        name="普通用户",
        description="基本用户权限",
        permissions=[
            Permission(ResourceType.USER, ActionType.MANAGE, PermissionScope.OWN),
            Permission(ResourceType.PROJECT, ActionType.READ, PermissionScope.ORGANIZATION),
            Permission(ResourceType.RESUME, ActionType.MANAGE, PermissionScope.OWN),
            Permission(ResourceType.JOB, ActionType.READ, PermissionScope.ORGANIZATION)
        ]
    )
    
    # 访客 - 只读权限
    guest = Role(
        role_id="guest",
        name="访客",
        description="只读访客权限",
        permissions=[
            Permission(ResourceType.USER, ActionType.READ, PermissionScope.OWN),
            Permission(ResourceType.PROJECT, ActionType.READ, PermissionScope.ORGANIZATION),
            Permission(ResourceType.JOB, ActionType.READ, PermissionScope.ORGANIZATION)
        ]
    )
    
    self.roles = {
        "super": super_admin,
        "admin": admin,
        "user": user,
        "guest": guest
    }
```

---

## 📊 预期修复效果

### 基于Zervigo设计的改进

1. **角色层次结构**: 实现数字层次，高级角色自动继承低级权限
2. **超级管理员特权**: 超级管理员绕过所有检查，拥有全局权限
3. **权限检查顺序**: 先检查隔离，再检查权限，最后记录审计
4. **权限配置完整**: 所有角色都有完整的权限配置

### 预期测试结果

- **数据隔离测试**: 4/4 通过 (修复隔离检查顺序)
- **权限控制测试**: 6/6 通过 (修复超级管理员权限)
- **审计系统测试**: 4/4 通过 (优化审计规则)
- **集成测试**: 3/3 通过 (修复权限映射)
- **总体成功率**: 100% (17/17)

---

## 🎯 实施建议

### 立即实施
1. **更新角色定义**: 对齐Zervigo的角色层次结构
2. **修复权限检查**: 实现超级管理员特权和层次检查
3. **优化数据隔离**: 调整检查顺序和逻辑

### 验证步骤
1. 实施修复后重新运行测试
2. 验证超级管理员权限
3. 验证角色层次继承
4. 验证数据隔离逻辑

---

**结论**: Zervigo子系统的权限设计非常成熟，采用角色层次结构、超级管理员特权、命名空间权限等最佳实践。基于这些设计，我们可以显著改进Looma CRM的权限控制系统，实现100%的测试通过率。

---

**文档版本**: v1.0  
**创建日期**: 2025年9月23日  
**维护者**: AI Assistant  
**状态**: 分析完成，修复方案已制定
