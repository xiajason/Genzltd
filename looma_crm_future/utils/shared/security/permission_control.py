#!/usr/bin/env python3
"""
细粒度权限控制模块
实现基于角色的访问控制(RBAC)和资源级权限管理
"""

import asyncio
import logging
import json
from typing import Dict, Any, List, Optional, Set, Union
from datetime import datetime, timedelta
from enum import Enum
from dataclasses import dataclass, field
from abc import ABC, abstractmethod

logger = logging.getLogger(__name__)

# 角色层次映射 - 基于Zervigo设计
ROLE_HIERARCHY = {
    "guest": 1,
    "user": 2,
    "vip": 3,
    "moderator": 4,
    "admin": 5,
    "super": 6,
    # Zervigo子系统角色
    "regular_user": 1,
    "company_admin": 2,
    "data_admin": 3,
    "hr_admin": 3,
    "system_admin": 4,
    "super_admin": 5,
}

class ResourceType(Enum):
    """资源类型"""
    USER = "user"
    PROJECT = "project"
    COMPANY = "company"
    RESUME = "resume"
    JOB = "job"
    ANALYTICS = "analytics"
    SYSTEM = "system"
    AI_SERVICE = "ai_service"

class ActionType(Enum):
    """操作类型"""
    CREATE = "create"
    READ = "read"
    UPDATE = "update"
    DELETE = "delete"
    LIST = "list"
    EXPORT = "export"
    IMPORT = "import"
    EXECUTE = "execute"
    MANAGE = "manage"

class PermissionScope(Enum):
    """权限范围"""
    OWN = "own"  # 只能访问自己的资源
    ORGANIZATION = "organization"  # 可以访问组织内的资源
    TENANT = "tenant"  # 可以访问租户内的资源
    GLOBAL = "global"  # 可以访问所有资源

@dataclass
class Permission:
    """权限定义"""
    resource_type: ResourceType
    action: ActionType
    scope: PermissionScope
    conditions: Dict[str, Any] = field(default_factory=dict)
    expires_at: Optional[datetime] = None
    
    def is_valid(self) -> bool:
        """检查权限是否有效"""
        if self.expires_at and datetime.now() > self.expires_at:
            return False
        return True

@dataclass
class Role:
    """角色定义"""
    role_id: str
    name: str
    description: str
    permissions: List[Permission] = field(default_factory=list)
    inherits_from: List[str] = field(default_factory=list)
    is_active: bool = True
    created_at: datetime = field(default_factory=datetime.now)
    updated_at: datetime = field(default_factory=datetime.now)

@dataclass
class UserRole:
    """用户角色关联"""
    user_id: str
    role_id: str
    assigned_by: str
    assigned_at: datetime = field(default_factory=datetime.now)
    expires_at: Optional[datetime] = None
    is_active: bool = True

@dataclass
class PermissionRequest:
    """权限请求"""
    user_id: str
    resource_type: ResourceType
    action: ActionType
    resource_id: Optional[str] = None
    context: Dict[str, Any] = field(default_factory=dict)
    timestamp: datetime = field(default_factory=datetime.now)

@dataclass
class PermissionDecision:
    """权限决策"""
    request: PermissionRequest
    granted: bool
    reason: str
    matched_permissions: List[Permission] = field(default_factory=list)
    timestamp: datetime = field(default_factory=datetime.now)

class PermissionEvaluator(ABC):
    """权限评估器抽象基类"""
    
    @abstractmethod
    async def evaluate(self, request: PermissionRequest, permission: Permission) -> bool:
        """评估权限"""
        pass

class OwnResourceEvaluator(PermissionEvaluator):
    """自有资源权限评估器"""
    
    async def evaluate(self, request: PermissionRequest, permission: Permission) -> bool:
        """评估自有资源权限"""
        if permission.scope != PermissionScope.OWN:
            return False
        
        # 检查资源是否属于用户
        if request.resource_id:
            # 从上下文中获取资源所有者ID
            resource_owner_id = request.context.get('resource_owner_id')
            user_id = request.context.get('user_id')
            
            # 检查资源是否属于用户
            if resource_owner_id and user_id:
                return resource_owner_id == user_id
            
            # 如果没有上下文信息，返回False（安全起见）
            return False
        
        return True

class OrganizationResourceEvaluator(PermissionEvaluator):
    """组织资源权限评估器"""
    
    async def evaluate(self, request: PermissionRequest, permission: Permission) -> bool:
        """评估组织资源权限"""
        if permission.scope != PermissionScope.ORGANIZATION:
            return False
        
        # 检查用户是否在同一个组织
        user_org = request.context.get('user_organization_id')
        resource_org = request.context.get('resource_organization_id')
        
        if user_org and resource_org:
            return user_org == resource_org
        
        return True

class TenantResourceEvaluator(PermissionEvaluator):
    """租户资源权限评估器"""
    
    async def evaluate(self, request: PermissionRequest, permission: Permission) -> bool:
        """评估租户资源权限"""
        if permission.scope != PermissionScope.TENANT:
            return False
        
        # 检查用户是否在同一个租户
        user_tenant = request.context.get('user_tenant_id')
        resource_tenant = request.context.get('resource_tenant_id')
        
        if user_tenant and resource_tenant:
            return user_tenant == resource_tenant
        
        return True

class GlobalResourceEvaluator(PermissionEvaluator):
    """全局资源权限评估器"""
    
    async def evaluate(self, request: PermissionRequest, permission: Permission) -> bool:
        """评估全局资源权限"""
        return permission.scope == PermissionScope.GLOBAL

class RoleManager:
    """角色管理器"""
    
    def __init__(self):
        self.roles: Dict[str, Role] = {}
        self.user_roles: Dict[str, List[UserRole]] = {}
        self._initialize_default_roles()
    
    def _initialize_default_roles(self):
        """初始化默认角色"""
        # 超级管理员
        super_admin = Role(
            role_id="super",
            name="超级管理员",
            description="拥有所有权限的超级管理员",
            permissions=[
                Permission(ResourceType.SYSTEM, ActionType.MANAGE, PermissionScope.GLOBAL),
                Permission(ResourceType.USER, ActionType.MANAGE, PermissionScope.GLOBAL),
                Permission(ResourceType.USER, ActionType.CREATE, PermissionScope.GLOBAL),  # 修复：添加CREATE权限
                Permission(ResourceType.USER, ActionType.READ, PermissionScope.GLOBAL),    # 修复：添加READ权限
                Permission(ResourceType.USER, ActionType.UPDATE, PermissionScope.GLOBAL),  # 修复：添加UPDATE权限
                Permission(ResourceType.USER, ActionType.DELETE, PermissionScope.GLOBAL),  # 修复：添加DELETE权限
                Permission(ResourceType.PROJECT, ActionType.MANAGE, PermissionScope.GLOBAL),
                Permission(ResourceType.COMPANY, ActionType.MANAGE, PermissionScope.GLOBAL),
                Permission(ResourceType.RESUME, ActionType.MANAGE, PermissionScope.GLOBAL),
                Permission(ResourceType.JOB, ActionType.MANAGE, PermissionScope.GLOBAL),
                Permission(ResourceType.ANALYTICS, ActionType.MANAGE, PermissionScope.GLOBAL)
            ]
        )
        
        # 组织管理员 - 细化权限设计
        org_admin = Role(
            role_id="admin",
            name="组织管理员",
            description="组织级别的管理员，拥有组织内所有资源的完整管理权限",
            permissions=[
                # 用户权限 - 组织级管理
                Permission(ResourceType.USER, ActionType.READ, PermissionScope.ORGANIZATION),
                Permission(ResourceType.USER, ActionType.CREATE, PermissionScope.ORGANIZATION),
                Permission(ResourceType.USER, ActionType.UPDATE, PermissionScope.ORGANIZATION),
                Permission(ResourceType.USER, ActionType.DELETE, PermissionScope.ORGANIZATION),
                # 项目权限 - 组织级管理
                Permission(ResourceType.PROJECT, ActionType.READ, PermissionScope.ORGANIZATION),
                Permission(ResourceType.PROJECT, ActionType.CREATE, PermissionScope.ORGANIZATION),
                Permission(ResourceType.PROJECT, ActionType.UPDATE, PermissionScope.ORGANIZATION),
                Permission(ResourceType.PROJECT, ActionType.DELETE, PermissionScope.ORGANIZATION),
                # 公司权限 - 组织级管理
                Permission(ResourceType.COMPANY, ActionType.READ, PermissionScope.ORGANIZATION),
                Permission(ResourceType.COMPANY, ActionType.CREATE, PermissionScope.ORGANIZATION),
                Permission(ResourceType.COMPANY, ActionType.UPDATE, PermissionScope.ORGANIZATION),
                Permission(ResourceType.COMPANY, ActionType.DELETE, PermissionScope.ORGANIZATION),
                # 简历权限 - 组织级管理
                Permission(ResourceType.RESUME, ActionType.READ, PermissionScope.ORGANIZATION),
                Permission(ResourceType.RESUME, ActionType.CREATE, PermissionScope.ORGANIZATION),
                Permission(ResourceType.RESUME, ActionType.UPDATE, PermissionScope.ORGANIZATION),
                Permission(ResourceType.RESUME, ActionType.DELETE, PermissionScope.ORGANIZATION),
                # 职位权限 - 组织级管理
                Permission(ResourceType.JOB, ActionType.READ, PermissionScope.ORGANIZATION),
                Permission(ResourceType.JOB, ActionType.CREATE, PermissionScope.ORGANIZATION),
                Permission(ResourceType.JOB, ActionType.UPDATE, PermissionScope.ORGANIZATION),
                Permission(ResourceType.JOB, ActionType.DELETE, PermissionScope.ORGANIZATION),
                # 分析权限 - 只读
                Permission(ResourceType.ANALYTICS, ActionType.READ, PermissionScope.ORGANIZATION)
            ]
        )
        
        # 项目经理
        project_manager = Role(
            role_id="project_manager",
            name="项目经理",
            description="项目管理权限",
            permissions=[
                Permission(ResourceType.PROJECT, ActionType.MANAGE, PermissionScope.ORGANIZATION),
                Permission(ResourceType.USER, ActionType.READ, PermissionScope.ORGANIZATION),
                Permission(ResourceType.RESUME, ActionType.READ, PermissionScope.ORGANIZATION),
                Permission(ResourceType.JOB, ActionType.READ, PermissionScope.ORGANIZATION)
            ]
        )
        
        # 普通用户 - 细化权限设计
        user = Role(
            role_id="user",
            name="普通用户",
            description="基本用户权限，resume所有者可创建利益相关方用户",
            permissions=[
                # 用户权限 - 细化管理权限
                Permission(ResourceType.USER, ActionType.READ, PermissionScope.OWN),      # 读取自己的用户数据
                Permission(ResourceType.USER, ActionType.UPDATE, PermissionScope.OWN),    # 更新自己的用户数据
                Permission(ResourceType.USER, ActionType.CREATE, PermissionScope.OWN),    # 创建利益相关方用户（resume所有者权限）
                # 项目权限
                Permission(ResourceType.PROJECT, ActionType.READ, PermissionScope.ORGANIZATION),
                # 简历权限 - 细化管理权限
                Permission(ResourceType.RESUME, ActionType.READ, PermissionScope.OWN),     # 读取自己的简历
                Permission(ResourceType.RESUME, ActionType.CREATE, PermissionScope.OWN),   # 创建简历
                Permission(ResourceType.RESUME, ActionType.UPDATE, PermissionScope.OWN),   # 更新简历
                Permission(ResourceType.RESUME, ActionType.DELETE, PermissionScope.OWN),   # 删除简历
                # 职位权限
                Permission(ResourceType.JOB, ActionType.READ, PermissionScope.ORGANIZATION)
            ]
        )
        
        # 访客 - 细化权限设计
        guest = Role(
            role_id="guest",
            name="访客",
            description="只读访客权限，无创建权限",
            permissions=[
                # 只读权限
                Permission(ResourceType.USER, ActionType.READ, PermissionScope.OWN),           # 读取自己的用户数据
                Permission(ResourceType.PROJECT, ActionType.READ, PermissionScope.ORGANIZATION), # 读取项目信息
                Permission(ResourceType.JOB, ActionType.READ, PermissionScope.ORGANIZATION)      # 读取职位信息
                # 注意：访客没有CREATE、UPDATE、DELETE权限
            ]
        )
        
        # Zervigo子系统角色 - 基于实际数据库配置
        super_admin = Role(
            role_id="super_admin",
            name="超级管理员",
            description="拥有所有权限的超级管理员",
            permissions=[
                # 系统级权限
                Permission(ResourceType.USER, ActionType.MANAGE, PermissionScope.GLOBAL),
                Permission(ResourceType.USER, ActionType.CREATE, PermissionScope.GLOBAL),  # 修复：添加CREATE权限
                Permission(ResourceType.SYSTEM, ActionType.MANAGE, PermissionScope.GLOBAL),
                Permission(ResourceType.AI_SERVICE, ActionType.MANAGE, PermissionScope.GLOBAL),
                # 业务数据权限
                Permission(ResourceType.COMPANY, ActionType.MANAGE, PermissionScope.GLOBAL),
                Permission(ResourceType.JOB, ActionType.MANAGE, PermissionScope.GLOBAL),
                Permission(ResourceType.RESUME, ActionType.MANAGE, PermissionScope.GLOBAL),
                Permission(ResourceType.ANALYTICS, ActionType.MANAGE, PermissionScope.GLOBAL),
                # 基础权限
                Permission(ResourceType.USER, ActionType.READ, PermissionScope.GLOBAL),
                Permission(ResourceType.USER, ActionType.UPDATE, PermissionScope.GLOBAL),
                Permission(ResourceType.USER, ActionType.DELETE, PermissionScope.GLOBAL)
            ]
        )
        
        system_admin = Role(
            role_id="system_admin",
            name="系统管理员",
            description="系统级别的管理员",
            permissions=[
                # 系统级权限
                Permission(ResourceType.USER, ActionType.MANAGE, PermissionScope.ORGANIZATION),
                Permission(ResourceType.AI_SERVICE, ActionType.MANAGE, PermissionScope.ORGANIZATION),
                # 业务数据权限
                Permission(ResourceType.COMPANY, ActionType.MANAGE, PermissionScope.ORGANIZATION),
                Permission(ResourceType.JOB, ActionType.MANAGE, PermissionScope.ORGANIZATION),
                Permission(ResourceType.RESUME, ActionType.MANAGE, PermissionScope.ORGANIZATION),
                Permission(ResourceType.ANALYTICS, ActionType.READ, PermissionScope.ORGANIZATION),
                # 基础权限
                Permission(ResourceType.USER, ActionType.READ, PermissionScope.ORGANIZATION),
                Permission(ResourceType.USER, ActionType.UPDATE, PermissionScope.ORGANIZATION)
            ]
        )
        
        data_admin = Role(
            role_id="data_admin",
            name="数据管理员",
            description="数据级别的管理员",
            permissions=[
                # 数据权限
                Permission(ResourceType.USER, ActionType.READ, PermissionScope.ORGANIZATION),
                Permission(ResourceType.USER, ActionType.UPDATE, PermissionScope.ORGANIZATION),
                Permission(ResourceType.COMPANY, ActionType.MANAGE, PermissionScope.ORGANIZATION),
                Permission(ResourceType.JOB, ActionType.MANAGE, PermissionScope.ORGANIZATION),
                Permission(ResourceType.RESUME, ActionType.MANAGE, PermissionScope.ORGANIZATION),
                Permission(ResourceType.ANALYTICS, ActionType.READ, PermissionScope.ORGANIZATION),
                # 基础权限
                Permission(ResourceType.USER, ActionType.READ, PermissionScope.OWN),
                Permission(ResourceType.USER, ActionType.UPDATE, PermissionScope.OWN)
            ]
        )
        
        hr_admin = Role(
            role_id="hr_admin",
            name="HR管理员",
            description="人力资源管理员",
            permissions=[
                # HR权限
                Permission(ResourceType.USER, ActionType.READ, PermissionScope.ORGANIZATION),
                Permission(ResourceType.RESUME, ActionType.MANAGE, PermissionScope.ORGANIZATION),
                Permission(ResourceType.JOB, ActionType.MANAGE, PermissionScope.ORGANIZATION),
                Permission(ResourceType.COMPANY, ActionType.READ, PermissionScope.ORGANIZATION),
                Permission(ResourceType.ANALYTICS, ActionType.READ, PermissionScope.ORGANIZATION),
                # 基础权限
                Permission(ResourceType.USER, ActionType.READ, PermissionScope.OWN),
                Permission(ResourceType.USER, ActionType.UPDATE, PermissionScope.OWN)
            ]
        )
        
        company_admin = Role(
            role_id="company_admin",
            name="公司管理员",
            description="公司级别的管理员",
            permissions=[
                # 公司权限
                Permission(ResourceType.COMPANY, ActionType.MANAGE, PermissionScope.ORGANIZATION),
                Permission(ResourceType.JOB, ActionType.MANAGE, PermissionScope.ORGANIZATION),
                Permission(ResourceType.RESUME, ActionType.READ, PermissionScope.ORGANIZATION),
                Permission(ResourceType.ANALYTICS, ActionType.READ, PermissionScope.ORGANIZATION),
                # 基础权限
                Permission(ResourceType.USER, ActionType.READ, PermissionScope.OWN),
                Permission(ResourceType.USER, ActionType.UPDATE, PermissionScope.OWN)
            ]
        )
        
        regular_user = Role(
            role_id="regular_user",
            name="普通用户",
            description="基本的用户权限",
            permissions=[
                # 基础权限
                Permission(ResourceType.USER, ActionType.READ, PermissionScope.OWN),
                Permission(ResourceType.USER, ActionType.UPDATE, PermissionScope.OWN),
                Permission(ResourceType.RESUME, ActionType.MANAGE, PermissionScope.OWN),
                Permission(ResourceType.JOB, ActionType.READ, PermissionScope.ORGANIZATION),
                Permission(ResourceType.COMPANY, ActionType.READ, PermissionScope.ORGANIZATION)
            ]
        )
        
        # 审计员
        auditor = Role(
            role_id="auditor",
            name="审计员",
            description="审计和监控权限",
            permissions=[
                Permission(ResourceType.SYSTEM, ActionType.READ, PermissionScope.GLOBAL),
                Permission(ResourceType.USER, ActionType.READ, PermissionScope.GLOBAL),
                Permission(ResourceType.PROJECT, ActionType.READ, PermissionScope.GLOBAL),
                Permission(ResourceType.COMPANY, ActionType.READ, PermissionScope.GLOBAL),
                Permission(ResourceType.RESUME, ActionType.READ, PermissionScope.GLOBAL),
                Permission(ResourceType.JOB, ActionType.READ, PermissionScope.GLOBAL),
                Permission(ResourceType.ANALYTICS, ActionType.READ, PermissionScope.GLOBAL)
            ]
        )
        
        self.roles = {
            "super": super_admin,
            "admin": org_admin,
            "project_manager": project_manager,
            "user": user,
            "guest": guest,
            "auditor": auditor,
            # Zervigo子系统角色
            "super_admin": super_admin,
            "system_admin": system_admin,
            "data_admin": data_admin,
            "hr_admin": hr_admin,
            "company_admin": company_admin,
            "regular_user": regular_user
        }
    
    async def assign_role(self, user_id: str, role_id: str, assigned_by: str, expires_at: Optional[datetime] = None) -> bool:
        """分配角色给用户"""
        if role_id not in self.roles:
            logger.error(f"角色不存在: {role_id}")
            return False
        
        if user_id not in self.user_roles:
            self.user_roles[user_id] = []
        
        user_role = UserRole(
            user_id=user_id,
            role_id=role_id,
            assigned_by=assigned_by,
            expires_at=expires_at
        )
        
        self.user_roles[user_id].append(user_role)
        logger.info(f"角色分配成功: 用户 {user_id} -> 角色 {role_id}")
        return True
    
    async def revoke_role(self, user_id: str, role_id: str) -> bool:
        """撤销用户角色"""
        if user_id not in self.user_roles:
            return False
        
        self.user_roles[user_id] = [
            ur for ur in self.user_roles[user_id] 
            if not (ur.role_id == role_id and ur.is_active)
        ]
        
        logger.info(f"角色撤销成功: 用户 {user_id} -> 角色 {role_id}")
        return True
    
    async def get_user_roles(self, user_id: str) -> List[Role]:
        """获取用户角色"""
        if user_id not in self.user_roles:
            return []
        
        active_roles = []
        for user_role in self.user_roles[user_id]:
            if user_role.is_active and (not user_role.expires_at or user_role.expires_at > datetime.now()):
                if user_role.role_id in self.roles:
                    active_roles.append(self.roles[user_role.role_id])
        
        return active_roles
    
    async def get_user_permissions(self, user_id: str) -> List[Permission]:
        """获取用户权限"""
        roles = await self.get_user_roles(user_id)
        permissions = []
        
        for role in roles:
            permissions.extend(role.permissions)
        
        # 去重
        unique_permissions = []
        seen = set()
        for perm in permissions:
            key = (perm.resource_type, perm.action, perm.scope)
            if key not in seen and perm.is_valid():
                seen.add(key)
                unique_permissions.append(perm)
        
        return unique_permissions

class PermissionEngine:
    """权限引擎"""
    
    def __init__(self):
        self.role_manager = RoleManager()
        self.evaluators = {
            PermissionScope.OWN: OwnResourceEvaluator(),
            PermissionScope.ORGANIZATION: OrganizationResourceEvaluator(),
            PermissionScope.TENANT: TenantResourceEvaluator(),
            PermissionScope.GLOBAL: GlobalResourceEvaluator()
        }
    
    async def check_permission(self, request: PermissionRequest) -> PermissionDecision:
        """检查权限 - 基于Zervigo设计"""
        # 1. 超级管理员拥有所有权限
        user_roles = await self.role_manager.get_user_roles(request.user_id)
        if any(role.role_id == "super" for role in user_roles):
            return PermissionDecision(
                request=request,
                granted=True,
                reason="超级管理员拥有所有权限",
                matched_permissions=[]
            )
        
        # 2. 检查角色层次
        user_role_level = 0
        for role in user_roles:
            role_level = ROLE_HIERARCHY.get(role.role_id, 0)
            user_role_level = max(user_role_level, role_level)
        
        required_level = self._get_required_role_level(request.resource_type, request.action)
        if user_role_level < required_level:
            return PermissionDecision(
                request=request,
                granted=False,
                reason=f"角色级别不足: {user_role_level} < {required_level}"
            )
        
        # 3. 获取用户权限
        user_permissions = await self.role_manager.get_user_permissions(request.user_id)
        matched_permissions = []
        
        # 4. 检查每个权限
        for permission in user_permissions:
            if (permission.resource_type == request.resource_type and 
                self._check_action_permission(permission.action, request.action)):
                
                # 使用相应的评估器评估权限
                evaluator = self.evaluators.get(permission.scope)
                if evaluator and await evaluator.evaluate(request, permission):
                    matched_permissions.append(permission)
        
        if matched_permissions:
            return PermissionDecision(
                request=request,
                granted=True,
                reason="权限匹配成功",
                matched_permissions=matched_permissions
            )
        else:
            return PermissionDecision(
                request=request,
                granted=False,
                reason="没有匹配的权限"
            )
    
    async def assign_role(self, user_id: str, role_id: str, assigned_by: str, expires_at: Optional[datetime] = None) -> bool:
        """分配角色"""
        return await self.role_manager.assign_role(user_id, role_id, assigned_by, expires_at)
    
    async def revoke_role(self, user_id: str, role_id: str) -> bool:
        """撤销角色"""
        return await self.role_manager.revoke_role(user_id, role_id)
    
    async def get_user_roles(self, user_id: str) -> List[Role]:
        """获取用户角色"""
        return await self.role_manager.get_user_roles(user_id)
    
    async def get_user_permissions(self, user_id: str) -> List[Permission]:
        """获取用户权限"""
        return await self.role_manager.get_user_permissions(user_id)
    
    def _check_action_permission(self, permission_action: ActionType, requested_action: ActionType) -> bool:
        """检查操作权限 - 支持权限继承"""
        # 精确匹配
        if permission_action == requested_action:
            return True
        
        # MANAGE权限包含所有其他权限
        if permission_action == ActionType.MANAGE:
            return True
        
        # CREATE权限包含READ权限
        if permission_action == ActionType.CREATE and requested_action == ActionType.READ:
            return True
        
        # UPDATE权限包含READ权限
        if permission_action == ActionType.UPDATE and requested_action == ActionType.READ:
            return True
        
        # DELETE权限包含READ权限
        if permission_action == ActionType.DELETE and requested_action == ActionType.READ:
            return True
        
        return False
    
    def _get_required_role_level(self, resource_type: ResourceType, action: ActionType) -> int:
        """获取所需角色级别 - 基于Zervigo设计"""
        # 基于Zervigo角色层次结构的权限级别映射
        if action == ActionType.READ:
            return 1  # guest级别
        elif action == ActionType.CREATE:
            return 2  # user级别
        elif action == ActionType.UPDATE:
            return 2  # user级别
        elif action == ActionType.DELETE:
            # 删除权限根据资源类型确定级别
            if resource_type == ResourceType.USER:
                return 3  # 删除用户需要data_admin级别
            elif resource_type == ResourceType.RESUME:
                return 2  # 删除简历只需要user级别（resume所有者可以删除自己的简历）
            else:
                return 3  # 其他资源删除需要data_admin级别
        elif action == ActionType.MANAGE:
            # MANAGE权限需要根据资源类型确定级别
            if resource_type == ResourceType.SYSTEM:
                return 5  # super_admin级别
            elif resource_type == ResourceType.USER:
                return 4  # system_admin级别
            elif resource_type in [ResourceType.COMPANY, ResourceType.JOB, ResourceType.RESUME]:
                return 3  # data_admin/hr_admin级别
            else:
                return 3  # 默认data_admin级别
        else:
            return 2  # 默认user级别

class PermissionControlService:
    """权限控制服务"""
    
    def __init__(self):
        self.permission_engine = PermissionEngine()
    
    async def check_access(self, user_id: str, resource_type: ResourceType, action: ActionType, 
                          resource_id: Optional[str] = None, context: Optional[Dict[str, Any]] = None) -> PermissionDecision:
        """检查访问权限"""
        request = PermissionRequest(
            user_id=user_id,
            resource_type=resource_type,
            action=action,
            resource_id=resource_id,
            context=context or {}
        )
        
        return await self.permission_engine.check_permission(request)
    
    async def assign_user_role(self, user_id: str, role_id: str, assigned_by: str, expires_at: Optional[datetime] = None) -> bool:
        """分配用户角色"""
        return await self.permission_engine.assign_role(user_id, role_id, assigned_by, expires_at)
    
    async def revoke_user_role(self, user_id: str, role_id: str) -> bool:
        """撤销用户角色"""
        return await self.permission_engine.revoke_role(user_id, role_id)
    
    async def get_user_roles(self, user_id: str) -> List[Role]:
        """获取用户角色"""
        return await self.permission_engine.get_user_roles(user_id)
    
    async def get_user_permissions(self, user_id: str) -> List[Permission]:
        """获取用户权限"""
        return await self.permission_engine.get_user_permissions(user_id)
    
    async def list_available_roles(self) -> List[Role]:
        """列出可用角色"""
        return list(self.permission_engine.role_manager.roles.values())

# 全局权限控制服务实例
permission_control_service = PermissionControlService()

async def main():
    """测试权限控制服务"""
    logger.info("🚀 开始权限控制服务测试...")
    
    # 测试角色分配
    logger.info("📋 测试角色分配...")
    await permission_control_service.assign_user_role("user_1", "admin", "system")
    await permission_control_service.assign_user_role("user_2", "guest", "system")
    
    # 测试权限检查
    logger.info("📋 测试权限检查...")
    
    # 管理员权限检查
    admin_decision = await permission_control_service.check_access(
        "user_1", ResourceType.USER, ActionType.CREATE
    )
    logger.info(f"✅ 管理员创建用户权限: {admin_decision.granted} - {admin_decision.reason}")
    
    # 访客权限检查
    guest_decision = await permission_control_service.check_access(
        "user_2", ResourceType.USER, ActionType.CREATE
    )
    logger.info(f"✅ 访客创建用户权限: {guest_decision.granted} - {guest_decision.reason}")
    
    # 获取用户角色
    logger.info("📋 获取用户角色...")
    user_roles = await permission_control_service.get_user_roles("user_1")
    logger.info(f"✅ 用户1角色: {[role.name for role in user_roles]}")
    
    # 获取用户权限
    logger.info("📋 获取用户权限...")
    user_permissions = await permission_control_service.get_user_permissions("user_1")
    logger.info(f"✅ 用户1权限数量: {len(user_permissions)}")
    
    # 列出可用角色
    logger.info("📋 列出可用角色...")
    available_roles = await permission_control_service.list_available_roles()
    logger.info(f"✅ 可用角色: {[role.name for role in available_roles]}")
    
    logger.info("🎉 权限控制服务测试完成！")

if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    asyncio.run(main())
