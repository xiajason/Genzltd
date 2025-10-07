#!/usr/bin/env python3
"""
数据隔离和安全模块
实现多租户数据隔离、细粒度权限控制和数据访问审计
"""

import asyncio
import logging
import json
from typing import Dict, Any, List, Optional, Set
from datetime import datetime, timedelta
from enum import Enum
from dataclasses import dataclass
from abc import ABC, abstractmethod

logger = logging.getLogger(__name__)

class IsolationLevel(Enum):
    """数据隔离级别"""
    NONE = "none"  # 无隔离
    USER = "user"  # 用户级隔离
    ORGANIZATION = "organization"  # 组织级隔离
    TENANT = "tenant"  # 租户级隔离
    FULL = "full"  # 完全隔离

class PermissionType(Enum):
    """权限类型"""
    READ = "read"
    WRITE = "write"
    DELETE = "delete"
    ADMIN = "admin"
    AUDIT = "audit"

class AccessResult(Enum):
    """访问结果"""
    ALLOWED = "allowed"
    DENIED = "denied"
    AUDIT_REQUIRED = "audit_required"

@dataclass
class UserContext:
    """用户上下文"""
    user_id: str
    username: str
    role: str
    organization_id: Optional[str] = None
    tenant_id: Optional[str] = None
    permissions: Set[PermissionType] = None
    session_id: Optional[str] = None
    ip_address: Optional[str] = None
    user_agent: Optional[str] = None
    
    def __post_init__(self):
        if self.permissions is None:
            self.permissions = set()

@dataclass
class DataResource:
    """数据资源"""
    resource_id: str
    resource_type: str
    owner_id: str
    organization_id: Optional[str] = None
    tenant_id: Optional[str] = None
    metadata: Dict[str, Any] = None
    
    def __post_init__(self):
        if self.metadata is None:
            self.metadata = {}

@dataclass
class AccessRequest:
    """访问请求"""
    user_context: UserContext
    resource: DataResource
    permission: PermissionType
    operation: str
    timestamp: datetime = None
    
    def __post_init__(self):
        if self.timestamp is None:
            self.timestamp = datetime.now()

@dataclass
class AccessDecision:
    """访问决策"""
    request: AccessRequest
    result: AccessResult
    reason: str
    isolation_level: IsolationLevel
    timestamp: datetime = None
    
    def __post_init__(self):
        if self.timestamp is None:
            self.timestamp = datetime.now()

@dataclass
class AuditLog:
    """审计日志"""
    log_id: str
    user_context: UserContext
    resource: DataResource
    operation: str
    result: AccessResult
    timestamp: datetime
    details: Dict[str, Any] = None
    
    def __post_init__(self):
        if self.details is None:
            self.details = {}

class DataIsolationEngine(ABC):
    """数据隔离引擎抽象基类"""
    
    @abstractmethod
    async def isolate_data(self, user_context: UserContext, data: Dict[str, Any]) -> Dict[str, Any]:
        """隔离数据"""
        pass
    
    @abstractmethod
    async def check_isolation(self, user_context: UserContext, resource: DataResource) -> bool:
        """检查数据隔离"""
        pass

class UserLevelIsolation(DataIsolationEngine):
    """用户级数据隔离"""
    
    async def isolate_data(self, user_context: UserContext, data: Dict[str, Any]) -> Dict[str, Any]:
        """用户级数据隔离"""
        isolated_data = data.copy()
        
        # 只返回属于当前用户的数据
        if 'owner_id' in isolated_data:
            if isolated_data['owner_id'] != user_context.user_id:
                return {}
        
        # 过滤用户相关字段
        user_fields = ['user_id', 'owner_id', 'created_by', 'updated_by']
        for field in user_fields:
            if field in isolated_data and isolated_data[field] != user_context.user_id:
                isolated_data.pop(field, None)
        
        return isolated_data
    
    async def check_isolation(self, user_context: UserContext, resource: DataResource) -> bool:
        """检查用户级隔离"""
        # 严格检查资源所有权
        return resource.owner_id == user_context.user_id

class OrganizationLevelIsolation(DataIsolationEngine):
    """组织级数据隔离"""
    
    async def isolate_data(self, user_context: UserContext, data: Dict[str, Any]) -> Dict[str, Any]:
        """组织级数据隔离"""
        isolated_data = data.copy()
        
        # 检查组织权限
        if user_context.organization_id:
            if 'organization_id' in isolated_data:
                if isolated_data['organization_id'] != user_context.organization_id:
                    return {}
        
        return isolated_data
    
    async def check_isolation(self, user_context: UserContext, resource: DataResource) -> bool:
        """检查组织级隔离"""
        if not user_context.organization_id:
            return False
        return resource.organization_id == user_context.organization_id

class TenantLevelIsolation(DataIsolationEngine):
    """租户级数据隔离"""
    
    async def isolate_data(self, user_context: UserContext, data: Dict[str, Any]) -> Dict[str, Any]:
        """租户级数据隔离"""
        isolated_data = data.copy()
        
        # 检查租户权限
        if user_context.tenant_id:
            if 'tenant_id' in isolated_data:
                if isolated_data['tenant_id'] != user_context.tenant_id:
                    return {}
        
        return isolated_data
    
    async def check_isolation(self, user_context: UserContext, resource: DataResource) -> bool:
        """检查租户级隔离"""
        if not user_context.tenant_id:
            return False
        return resource.tenant_id == user_context.tenant_id

class PermissionEngine:
    """权限引擎"""
    
    def __init__(self):
        self.role_permissions = {
            'admin': {PermissionType.READ, PermissionType.WRITE, PermissionType.DELETE, PermissionType.ADMIN, PermissionType.AUDIT},
            'manager': {PermissionType.READ, PermissionType.WRITE, PermissionType.AUDIT},
            'user': {PermissionType.READ, PermissionType.WRITE},
            'guest': {PermissionType.READ},
            'auditor': {PermissionType.READ, PermissionType.AUDIT}
        }
    
    async def check_permission(self, user_context: UserContext, permission: PermissionType) -> bool:
        """检查用户权限"""
        user_permissions = self.role_permissions.get(user_context.role, set())
        return permission in user_permissions
    
    async def get_user_permissions(self, user_context: UserContext) -> Set[PermissionType]:
        """获取用户权限"""
        return self.role_permissions.get(user_context.role, set())

class AccessControlEngine:
    """访问控制引擎"""
    
    def __init__(self):
        self.isolation_engines = {
            IsolationLevel.USER: UserLevelIsolation(),
            IsolationLevel.ORGANIZATION: OrganizationLevelIsolation(),
            IsolationLevel.TENANT: TenantLevelIsolation()
        }
        self.permission_engine = PermissionEngine()
        self.audit_logs = []
    
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
    
    def _determine_isolation_level(self, user_context: UserContext) -> IsolationLevel:
        """确定隔离级别 - 基于Zervigo设计，优先考虑更严格的隔离"""
        # 根据Zervigo设计，应该优先考虑更严格的隔离级别
        # 对于用户数据访问，应该使用用户级隔离
        if user_context.role in ["user", "guest"]:
            return IsolationLevel.USER
        elif user_context.role in ["admin", "moderator"]:
            return IsolationLevel.ORGANIZATION
        elif user_context.role == "super":
            return IsolationLevel.GLOBAL
        else:
            return IsolationLevel.USER
    
    async def _log_access(self, request: AccessRequest, result: AccessResult):
        """记录访问日志"""
        log = AuditLog(
            log_id=f"audit_{datetime.now().timestamp()}",
            user_context=request.user_context,
            resource=request.resource,
            operation=request.operation,
            result=result,
            timestamp=request.timestamp,
            details={
                "permission": request.permission.value,
                "isolation_level": self._determine_isolation_level(request.user_context).value
            }
        )
        self.audit_logs.append(log)
        logger.info(f"访问审计: {log.log_id} - {result.value}")

class DataIsolationService:
    """数据隔离服务"""
    
    def __init__(self):
        self.access_control = AccessControlEngine()
        self.isolation_engines = {
            IsolationLevel.USER: UserLevelIsolation(),
            IsolationLevel.ORGANIZATION: OrganizationLevelIsolation(),
            IsolationLevel.TENANT: TenantLevelIsolation()
        }
    
    async def isolate_user_data(self, user_context: UserContext, data: Dict[str, Any]) -> Dict[str, Any]:
        """隔离用户数据"""
        isolation_level = self.access_control._determine_isolation_level(user_context)
        isolation_engine = self.isolation_engines.get(isolation_level)
        
        if isolation_engine:
            return await isolation_engine.isolate_data(user_context, data)
        
        return data
    
    async def check_data_access(self, user_context: UserContext, resource: DataResource, permission: PermissionType) -> AccessDecision:
        """检查数据访问权限"""
        request = AccessRequest(
            user_context=user_context,
            resource=resource,
            permission=permission,
            operation="data_access"
        )
        
        return await self.access_control.evaluate_access(request)
    
    async def get_audit_logs(self, user_context: UserContext, limit: int = 100) -> List[AuditLog]:
        """获取审计日志"""
        # 只返回当前用户相关的审计日志
        user_logs = []
        for log in self.access_control.audit_logs[-limit:]:
            if log.user_context.user_id == user_context.user_id:
                user_logs.append(log)
        
        return user_logs
    
    async def get_user_permissions(self, user_context: UserContext) -> Set[PermissionType]:
        """获取用户权限"""
        return await self.access_control.permission_engine.get_user_permissions(user_context)

# 全局数据隔离服务实例
data_isolation_service = DataIsolationService()

async def main():
    """测试数据隔离服务"""
    logger.info("🚀 开始数据隔离服务测试...")
    
    # 创建测试用户上下文
    admin_user = UserContext(
        user_id="admin_1",
        username="admin",
        role="admin",
        organization_id="org_1",
        tenant_id="tenant_1"
    )
    
    guest_user = UserContext(
        user_id="guest_1",
        username="guest",
        role="guest",
        organization_id="org_1",
        tenant_id="tenant_1"
    )
    
    # 创建测试数据资源
    resource = DataResource(
        resource_id="data_1",
        resource_type="user_data",
        owner_id="admin_1",
        organization_id="org_1",
        tenant_id="tenant_1"
    )
    
    # 测试权限检查
    logger.info("📋 测试权限检查...")
    admin_permissions = await data_isolation_service.get_user_permissions(admin_user)
    guest_permissions = await data_isolation_service.get_user_permissions(guest_user)
    
    logger.info(f"✅ 管理员权限: {[p.value for p in admin_permissions]}")
    logger.info(f"✅ 访客权限: {[p.value for p in guest_permissions]}")
    
    # 测试数据访问控制
    logger.info("📋 测试数据访问控制...")
    
    # 管理员访问
    admin_decision = await data_isolation_service.check_data_access(
        admin_user, resource, PermissionType.READ
    )
    logger.info(f"✅ 管理员访问结果: {admin_decision.result.value} - {admin_decision.reason}")
    
    # 访客访问
    guest_decision = await data_isolation_service.check_data_access(
        guest_user, resource, PermissionType.WRITE
    )
    logger.info(f"✅ 访客访问结果: {guest_decision.result.value} - {guest_decision.reason}")
    
    # 测试数据隔离
    logger.info("📋 测试数据隔离...")
    test_data = {
        "id": "data_1",
        "owner_id": "admin_1",
        "organization_id": "org_1",
        "tenant_id": "tenant_1",
        "content": "sensitive_data"
    }
    
    isolated_data = await data_isolation_service.isolate_user_data(admin_user, test_data)
    logger.info(f"✅ 管理员隔离数据: {isolated_data}")
    
    # 获取审计日志
    logger.info("📋 获取审计日志...")
    audit_logs = await data_isolation_service.get_audit_logs(admin_user)
    logger.info(f"✅ 审计日志数量: {len(audit_logs)}")
    
    logger.info("🎉 数据隔离服务测试完成！")

if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    asyncio.run(main())
