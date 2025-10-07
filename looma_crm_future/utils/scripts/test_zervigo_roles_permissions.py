#!/usr/bin/env python3
"""
Zervigo子系统角色权限全面测试脚本
基于实际MySQL数据库中的角色和权限配置进行测试
"""

import asyncio
import sys
import os
import json
import logging
from datetime import datetime
from typing import Dict, List, Any

# 添加项目路径
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from shared.security.permission_control import permission_control_service, ResourceType, ActionType, PermissionScope
from shared.security.data_isolation import data_isolation_service, IsolationLevel, UserContext, DataResource
from shared.security.audit_system import audit_system, AuditEventType, AuditStatus

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class ZervigoRolePermissionTester:
    """Zervigo角色权限测试器"""
    
    def __init__(self):
        self.test_results = []
        self.zervigo_roles = {
            "super_admin": {
                "level": 5,
                "display_name": "超级管理员",
                "description": "拥有所有权限的超级管理员",
                "permissions": [
                    # 系统级权限 (level 4)
                    "users.password.read", "users.password.write",
                    "sessions.token.read", "sessions.token.write",
                    "admin_ai_management", "manage_ai_config",
                    # 敏感数据权限 (level 3)
                    "users.personal.read", "users.personal.write", "users.personal.delete",
                    "files.sensitive.read", "files.sensitive.write",
                    "points.balance.read", "points.balance.write",
                    "premium_ai_features", "view_ai_logs", "unlimited_ai_requests",
                    # 业务数据权限 (level 2)
                    "companies.read", "companies.write", "companies.delete",
                    "jobs.read", "jobs.write", "jobs.delete",
                    "resumes.read", "resumes.write", "resumes.delete",
                    "skills.read", "skills.write",
                    "ai_job_matching", "ai_resume_analysis", "ai_chat",
                    # 基础权限 (level 1)
                    "read:all", "write:all", "delete:all",
                    "read:own", "write:own", "delete:own",
                    "read:public", "public.read",
                    "job.read", "job.create", "job.update", "job.delete",
                    "job.matching", "job.matching.admin", "job.apply",
                    "ai_service_access", "banners.read", "templates.read",
                    "statistics.read", "admin:users", "admin:system"
                ]
            },
            "system_admin": {
                "level": 4,
                "display_name": "系统管理员",
                "description": "系统级别的管理员",
                "permissions": [
                    # 系统级权限 (level 4)
                    "users.password.read", "users.password.write",
                    "sessions.token.read", "sessions.token.write",
                    "admin_ai_management", "manage_ai_config",
                    # 敏感数据权限 (level 3)
                    "users.personal.read", "users.personal.write",
                    "files.sensitive.read", "files.sensitive.write",
                    "points.balance.read", "points.balance.write",
                    "premium_ai_features", "view_ai_logs",
                    # 业务数据权限 (level 2)
                    "companies.read", "companies.write",
                    "jobs.read", "jobs.write",
                    "resumes.read", "resumes.write",
                    "skills.read", "skills.write",
                    "ai_job_matching", "ai_resume_analysis", "ai_chat",
                    # 基础权限 (level 1)
                    "read:all", "write:all",
                    "read:own", "write:own", "delete:own",
                    "read:public", "public.read",
                    "job.read", "job.create", "job.update",
                    "job.matching", "job.apply",
                    "ai_service_access", "banners.read", "templates.read",
                    "statistics.read", "admin:users"
                ]
            },
            "data_admin": {
                "level": 3,
                "display_name": "数据管理员",
                "description": "数据级别的管理员",
                "permissions": [
                    # 敏感数据权限 (level 3)
                    "users.personal.read", "users.personal.write",
                    "files.sensitive.read", "files.sensitive.write",
                    "points.balance.read", "points.balance.write",
                    "premium_ai_features", "view_ai_logs",
                    # 业务数据权限 (level 2)
                    "companies.read", "companies.write",
                    "jobs.read", "jobs.write",
                    "resumes.read", "resumes.write",
                    "skills.read", "skills.write",
                    "ai_job_matching", "ai_resume_analysis", "ai_chat",
                    # 基础权限 (level 1)
                    "read:all", "write:all",
                    "read:own", "write:own", "delete:own",
                    "read:public", "public.read",
                    "job.read", "job.create", "job.update",
                    "job.matching", "job.apply",
                    "ai_service_access", "banners.read", "templates.read",
                    "statistics.read"
                ]
            },
            "hr_admin": {
                "level": 3,
                "display_name": "HR管理员",
                "description": "人力资源管理员",
                "permissions": [
                    # 敏感数据权限 (level 3)
                    "users.personal.read", "users.personal.write",
                    "files.sensitive.read", "files.sensitive.write",
                    "points.balance.read", "points.balance.write",
                    "premium_ai_features", "view_ai_logs",
                    # 业务数据权限 (level 2)
                    "companies.read", "companies.write",
                    "jobs.read", "jobs.write",
                    "resumes.read", "resumes.write",
                    "skills.read", "skills.write",
                    "ai_job_matching", "ai_resume_analysis", "ai_chat",
                    # 基础权限 (level 1)
                    "read:all", "write:all",
                    "read:own", "write:own", "delete:own",
                    "read:public", "public.read",
                    "job.read", "job.create", "job.update",
                    "job.matching", "job.apply",
                    "ai_service_access", "banners.read", "templates.read",
                    "statistics.read"
                ]
            },
            "company_admin": {
                "level": 2,
                "display_name": "公司管理员",
                "description": "公司级别的管理员",
                "permissions": [
                    # 业务数据权限 (level 2)
                    "companies.read", "companies.write",
                    "jobs.read", "jobs.write",
                    "resumes.read", "resumes.write",
                    "skills.read", "skills.write",
                    "ai_job_matching", "ai_resume_analysis", "ai_chat",
                    # 基础权限 (level 1)
                    "read:all", "write:all",
                    "read:own", "write:own", "delete:own",
                    "read:public", "public.read",
                    "job.read", "job.create", "job.update",
                    "job.matching", "job.apply",
                    "ai_service_access", "banners.read", "templates.read",
                    "statistics.read"
                ]
            },
            "regular_user": {
                "level": 1,
                "display_name": "普通用户",
                "description": "基本的用户权限",
                "permissions": [
                    # 基础权限 (level 1)
                    "read:own", "write:own", "delete:own",
                    "read:public", "public.read",
                    "job.read", "job.apply",
                    "ai_service_access", "banners.read", "templates.read"
                ]
            }
        }
        
        # 测试用户上下文
        self.test_users = {
            "super_admin_user": {
                "user_id": "super_admin_1",
                "username": "super_admin_user",
                "role": "super_admin",
                "organization_id": "org_1",
                "tenant_id": "tenant_1"
            },
            "system_admin_user": {
                "user_id": "system_admin_1",
                "username": "system_admin_user",
                "role": "system_admin",
                "organization_id": "org_1",
                "tenant_id": "tenant_1"
            },
            "data_admin_user": {
                "user_id": "data_admin_1",
                "username": "data_admin_user",
                "role": "data_admin",
                "organization_id": "org_1",
                "tenant_id": "tenant_1"
            },
            "hr_admin_user": {
                "user_id": "hr_admin_1",
                "username": "hr_admin_user",
                "role": "hr_admin",
                "organization_id": "org_1",
                "tenant_id": "tenant_1"
            },
            "company_admin_user": {
                "user_id": "company_admin_1",
                "username": "company_admin_user",
                "role": "company_admin",
                "organization_id": "org_1",
                "tenant_id": "tenant_1"
            },
            "regular_user": {
                "user_id": "regular_user_1",
                "username": "regular_user",
                "role": "regular_user",
                "organization_id": "org_1",
                "tenant_id": "tenant_1"
            }
        }

    async def test_role_hierarchy(self):
        """测试角色层次结构"""
        logger.info("🧪 开始测试角色层次结构...")
        
        test_cases = [
            {
                "name": "超级管理员层次",
                "role": "super_admin",
                "expected_level": 5,
                "expected_permissions": 50  # 大约50个权限
            },
            {
                "name": "系统管理员层次",
                "role": "system_admin",
                "expected_level": 4,
                "expected_permissions": 40  # 大约40个权限
            },
            {
                "name": "数据管理员层次",
                "role": "data_admin",
                "expected_level": 3,
                "expected_permissions": 30  # 大约30个权限
            },
            {
                "name": "HR管理员层次",
                "role": "hr_admin",
                "expected_level": 3,
                "expected_permissions": 30  # 大约30个权限
            },
            {
                "name": "公司管理员层次",
                "role": "company_admin",
                "expected_level": 2,
                "expected_permissions": 20  # 大约20个权限
            },
            {
                "name": "普通用户层次",
                "role": "regular_user",
                "expected_level": 1,
                "expected_permissions": 8   # 大约8个权限
            }
        ]
        
        for test_case in test_cases:
            try:
                role_info = self.zervigo_roles[test_case["role"]]
                
                # 检查角色层次
                level_match = role_info["level"] == test_case["expected_level"]
                
                # 检查权限数量
                permission_count = len(role_info["permissions"])
                permission_match = permission_count >= test_case["expected_permissions"]
                
                success = level_match and permission_match
                
                result = {
                    "test_name": test_case["name"],
                    "success": success,
                    "role": test_case["role"],
                    "expected_level": test_case["expected_level"],
                    "actual_level": role_info["level"],
                    "expected_permissions": test_case["expected_permissions"],
                    "actual_permissions": permission_count,
                    "level_match": level_match,
                    "permission_match": permission_match
                }
                
                if success:
                    logger.info(f"✅ {test_case['name']}: 层次结构正确")
                else:
                    logger.error(f"❌ {test_case['name']}: 层次结构不正确")
                
                self.test_results.append(result)
                
            except Exception as e:
                logger.error(f"❌ {test_case['name']}: 测试失败 - {e}")
                self.test_results.append({
                    "test_name": test_case["name"],
                    "success": False,
                    "error": str(e)
                })

    async def test_permission_inheritance(self):
        """测试权限继承"""
        logger.info("🧪 开始测试权限继承...")
        
        # 测试高级角色是否包含低级角色的权限
        inheritance_tests = [
            {
                "name": "超级管理员包含系统管理员权限",
                "high_role": "super_admin",
                "low_role": "system_admin"
            },
            {
                "name": "系统管理员包含数据管理员权限",
                "high_role": "system_admin",
                "low_role": "data_admin"
            },
            {
                "name": "数据管理员包含公司管理员权限",
                "high_role": "data_admin",
                "low_role": "company_admin"
            },
            {
                "name": "公司管理员包含普通用户权限",
                "high_role": "company_admin",
                "low_role": "regular_user"
            }
        ]
        
        for test_case in inheritance_tests:
            try:
                high_role_permissions = set(self.zervigo_roles[test_case["high_role"]]["permissions"])
                low_role_permissions = set(self.zervigo_roles[test_case["low_role"]]["permissions"])
                
                # 检查高级角色是否包含低级角色的所有权限
                inheritance_success = low_role_permissions.issubset(high_role_permissions)
                
                # 计算继承率
                inherited_permissions = high_role_permissions.intersection(low_role_permissions)
                inheritance_rate = len(inherited_permissions) / len(low_role_permissions) if low_role_permissions else 0
                
                result = {
                    "test_name": test_case["name"],
                    "success": inheritance_success,
                    "high_role": test_case["high_role"],
                    "low_role": test_case["low_role"],
                    "high_role_permissions": len(high_role_permissions),
                    "low_role_permissions": len(low_role_permissions),
                    "inherited_permissions": len(inherited_permissions),
                    "inheritance_rate": inheritance_rate
                }
                
                if inheritance_success:
                    logger.info(f"✅ {test_case['name']}: 权限继承正确 ({inheritance_rate:.1%})")
                else:
                    logger.error(f"❌ {test_case['name']}: 权限继承不完整 ({inheritance_rate:.1%})")
                
                self.test_results.append(result)
                
            except Exception as e:
                logger.error(f"❌ {test_case['name']}: 测试失败 - {e}")
                self.test_results.append({
                    "test_name": test_case["name"],
                    "success": False,
                    "error": str(e)
                })

    async def test_permission_control_integration(self):
        """测试权限控制集成"""
        logger.info("🧪 开始测试权限控制集成...")
        
        # 为每个角色分配权限
        for role_name, role_info in self.zervigo_roles.items():
            await permission_control_service.assign_user_role(
                f"{role_name}_user", role_name, "system"
            )
        
        # 等待角色分配完成
        await asyncio.sleep(0.1)
        
        # 测试各种权限检查
        permission_tests = [
            {
                "name": "超级管理员 - 用户管理权限",
                "user": "super_admin_user",
                "resource_type": ResourceType.USER,
                "action_type": ActionType.MANAGE,
                "expected": True
            },
            {
                "name": "超级管理员 - 系统管理权限",
                "user": "super_admin_user",
                "resource_type": ResourceType.SYSTEM,
                "action_type": ActionType.MANAGE,
                "expected": True
            },
            {
                "name": "系统管理员 - 用户管理权限",
                "user": "system_admin_user",
                "resource_type": ResourceType.USER,
                "action_type": ActionType.MANAGE,
                "expected": True
            },
            {
                "name": "系统管理员 - 系统管理权限",
                "user": "system_admin_user",
                "resource_type": ResourceType.SYSTEM,
                "action_type": ActionType.MANAGE,
                "expected": False  # 系统管理员不能管理系统
            },
            {
                "name": "数据管理员 - 数据管理权限",
                "user": "data_admin_user",
                "resource_type": ResourceType.USER,
                "action_type": ActionType.READ,
                "expected": True
            },
            {
                "name": "HR管理员 - 简历管理权限",
                "user": "hr_admin_user",
                "resource_type": ResourceType.RESUME,
                "action_type": ActionType.MANAGE,
                "expected": True
            },
            {
                "name": "公司管理员 - 职位管理权限",
                "user": "company_admin_user",
                "resource_type": ResourceType.JOB,
                "action_type": ActionType.MANAGE,
                "expected": True
            },
            {
                "name": "普通用户 - 读取权限",
                "user": "regular_user",
                "resource_type": ResourceType.USER,
                "action_type": ActionType.READ,
                "expected": True
            },
            {
                "name": "普通用户 - 管理权限",
                "user": "regular_user",
                "resource_type": ResourceType.USER,
                "action_type": ActionType.MANAGE,
                "expected": False
            }
        ]
        
        for test_case in permission_tests:
            try:
                user_data = self.test_users[test_case["user"]]
                
                # 检查权限
                decision = await permission_control_service.check_access(
                    user_data["user_id"],
                    test_case["resource_type"],
                    test_case["action_type"]
                )
                
                success = decision.granted == test_case["expected"]
                
                result = {
                    "test_name": test_case["name"],
                    "success": success,
                    "user": test_case["user"],
                    "role": user_data["role"],
                    "resource_type": test_case["resource_type"].value,
                    "action_type": test_case["action_type"].value,
                    "expected": test_case["expected"],
                    "actual": decision.granted,
                    "reason": decision.reason
                }
                
                if success:
                    logger.info(f"✅ {test_case['name']}: 权限检查正确")
                else:
                    logger.error(f"❌ {test_case['name']}: 权限检查失败")
                
                self.test_results.append(result)
                
            except Exception as e:
                logger.error(f"❌ {test_case['name']}: 测试失败 - {e}")
                self.test_results.append({
                    "test_name": test_case["name"],
                    "success": False,
                    "error": str(e)
                })

    async def test_data_isolation_by_role(self):
        """测试基于角色的数据隔离"""
        logger.info("🧪 开始测试基于角色的数据隔离...")
        
        # 创建测试资源
        test_resources = {
            "user_data_1": {
                "resource_id": "user_data_1",
                "resource_type": "user_data",
                "owner_id": "regular_user_1",
                "organization_id": "org_1",
                "tenant_id": "tenant_1"
            },
            "company_data_1": {
                "resource_id": "company_data_1",
                "resource_type": "company_data",
                "owner_id": "company_admin_1",
                "organization_id": "org_1",
                "tenant_id": "tenant_1"
            }
        }
        
        isolation_tests = [
            {
                "name": "超级管理员 - 访问用户数据",
                "user": "super_admin_user",
                "resource": "user_data_1",
                "expected": True  # 超级管理员可以访问所有数据
            },
            {
                "name": "系统管理员 - 访问用户数据",
                "user": "system_admin_user",
                "resource": "user_data_1",
                "expected": True  # 系统管理员可以访问用户数据
            },
            {
                "name": "数据管理员 - 访问用户数据",
                "user": "data_admin_user",
                "resource": "user_data_1",
                "expected": True  # 数据管理员可以访问用户数据
            },
            {
                "name": "HR管理员 - 访问用户数据",
                "user": "hr_admin_user",
                "resource": "user_data_1",
                "expected": True  # HR管理员可以访问用户数据
            },
            {
                "name": "公司管理员 - 访问用户数据",
                "user": "company_admin_user",
                "resource": "user_data_1",
                "expected": False  # 公司管理员不能访问用户数据
            },
            {
                "name": "普通用户 - 访问自己的数据",
                "user": "regular_user",
                "resource": "user_data_1",
                "expected": True  # 用户可以访问自己的数据
            },
            {
                "name": "普通用户 - 访问他人数据",
                "user": "regular_user",
                "resource": "company_data_1",
                "expected": False  # 用户不能访问他人数据
            }
        ]
        
        for test_case in isolation_tests:
            try:
                user_data = self.test_users[test_case["user"]]
                user_context = UserContext(
                    user_id=user_data["user_id"],
                    username=user_data["username"],
                    role=user_data["role"],
                    organization_id=user_data["organization_id"],
                    tenant_id=user_data["tenant_id"]
                )
                
                resource_data = test_resources[test_case["resource"]]
                resource = DataResource(
                    resource_id=resource_data["resource_id"],
                    resource_type=resource_data["resource_type"],
                    owner_id=resource_data["owner_id"],
                    organization_id=resource_data["organization_id"],
                    tenant_id=resource_data["tenant_id"]
                )
                
                # 检查数据隔离
                isolation_decision = await data_isolation_service.check_data_access(
                    user_context, resource, "read"
                )
                
                success = (isolation_decision.result.value == "allowed") == test_case["expected"]
                
                result = {
                    "test_name": test_case["name"],
                    "success": success,
                    "user": test_case["user"],
                    "role": user_context.role,
                    "resource": test_case["resource"],
                    "expected": test_case["expected"],
                    "actual": isolation_decision.result.value == "allowed",
                    "isolation_level": isolation_decision.isolation_level.value if isolation_decision.isolation_level else None,
                    "reason": isolation_decision.reason
                }
                
                if success:
                    logger.info(f"✅ {test_case['name']}: 数据隔离正确")
                else:
                    logger.error(f"❌ {test_case['name']}: 数据隔离失败")
                
                self.test_results.append(result)
                
            except Exception as e:
                logger.error(f"❌ {test_case['name']}: 测试失败 - {e}")
                self.test_results.append({
                    "test_name": test_case["name"],
                    "success": False,
                    "error": str(e)
                })

    async def test_audit_system_integration(self):
        """测试审计系统集成"""
        logger.info("🧪 开始测试审计系统集成...")
        
        audit_tests = [
            {
                "name": "超级管理员操作审计",
                "user": "super_admin_user",
                "action": "admin_operation",
                "expected": True
            },
            {
                "name": "系统管理员操作审计",
                "user": "system_admin_user",
                "action": "system_operation",
                "expected": True
            },
            {
                "name": "数据管理员操作审计",
                "user": "data_admin_user",
                "action": "data_operation",
                "expected": True
            },
            {
                "name": "HR管理员操作审计",
                "user": "hr_admin_user",
                "action": "hr_operation",
                "expected": True
            },
            {
                "name": "公司管理员操作审计",
                "user": "company_admin_user",
                "action": "company_operation",
                "expected": True
            },
            {
                "name": "普通用户操作审计",
                "user": "regular_user",
                "action": "user_operation",
                "expected": True
            }
        ]
        
        for test_case in audit_tests:
            try:
                user_data = self.test_users[test_case["user"]]
                
                # 记录审计事件
                audit_event_id = await audit_system.log_event(
                    event_type=AuditEventType.DATA_ACCESS,
                    user_id=user_data["user_id"],
                    username=user_data["username"],
                    resource_type="test_resource",
                    resource_id="test_resource_1",
                    action=test_case["action"],
                    status=AuditStatus.SUCCESS
                )
                
                success = bool(audit_event_id)
                
                result = {
                    "test_name": test_case["name"],
                    "success": success,
                    "user": test_case["user"],
                    "role": user_data["role"],
                    "action": test_case["action"],
                    "audit_event_id": audit_event_id
                }
                
                if success:
                    logger.info(f"✅ {test_case['name']}: 审计记录成功")
                else:
                    logger.error(f"❌ {test_case['name']}: 审计记录失败")
                
                self.test_results.append(result)
                
            except Exception as e:
                logger.error(f"❌ {test_case['name']}: 测试失败 - {e}")
                self.test_results.append({
                    "test_name": test_case["name"],
                    "success": False,
                    "error": str(e)
                })

    async def run_all_tests(self):
        """运行所有测试"""
        logger.info("🚀 开始Zervigo角色权限全面测试...")
        
        # 运行各项测试
        await self.test_role_hierarchy()
        await self.test_permission_inheritance()
        await self.test_permission_control_integration()
        await self.test_data_isolation_by_role()
        await self.test_audit_system_integration()
        
        # 生成测试报告
        await self.generate_report()
        
        logger.info("🎉 Zervigo角色权限全面测试完成！")

    async def generate_report(self):
        """生成测试报告"""
        logger.info("📊 生成测试报告...")
        
        # 统计测试结果
        total_tests = len(self.test_results)
        successful_tests = sum(1 for result in self.test_results if result.get("success", False))
        failed_tests = total_tests - successful_tests
        success_rate = (successful_tests / total_tests * 100) if total_tests > 0 else 0
        
        # 按测试类型分组
        test_categories = {
            "角色层次结构": [],
            "权限继承": [],
            "权限控制集成": [],
            "数据隔离": [],
            "审计系统": []
        }
        
        for result in self.test_results:
            test_name = result.get("test_name", "")
            if "层次" in test_name:
                test_categories["角色层次结构"].append(result)
            elif "继承" in test_name:
                test_categories["权限继承"].append(result)
            elif "权限控制" in test_name or "权限检查" in test_name:
                test_categories["权限控制集成"].append(result)
            elif "数据隔离" in test_name:
                test_categories["数据隔离"].append(result)
            elif "审计" in test_name:
                test_categories["审计系统"].append(result)
        
        # 生成报告数据
        report_data = {
            "test_summary": {
                "total_tests": total_tests,
                "successful_tests": successful_tests,
                "failed_tests": failed_tests,
                "success_rate": success_rate,
                "timestamp": datetime.now().isoformat()
            },
            "test_categories": test_categories,
            "detailed_results": self.test_results
        }
        
        # 保存报告
        report_file = "docs/zervigo_roles_permissions_test_report.json"
        os.makedirs(os.path.dirname(report_file), exist_ok=True)
        
        with open(report_file, 'w', encoding='utf-8') as f:
            json.dump(report_data, f, ensure_ascii=False, indent=2)
        
        # 输出摘要
        logger.info(f"📊 测试摘要: 总计 {total_tests}, 成功 {successful_tests}, 失败 {failed_tests}, 成功率 {success_rate:.1f}%")
        
        for category, results in test_categories.items():
            if results:
                category_success = sum(1 for r in results if r.get("success", False))
                category_total = len(results)
                category_rate = (category_success / category_total * 100) if category_total > 0 else 0
                logger.info(f"  {category}: {category_success}/{category_total} 通过 ({category_rate:.1f}%)")
        
        logger.info(f"📊 测试报告已保存到: {report_file}")

async def main():
    """主函数"""
    tester = ZervigoRolePermissionTester()
    await tester.run_all_tests()

if __name__ == "__main__":
    asyncio.run(main())
