#!/usr/bin/env python3
"""
数据隔离和权限控制集成测试脚本
验证多租户数据隔离、细粒度权限控制和数据访问审计功能
"""

import asyncio
import sys
import os
import logging
from typing import Dict, Any, List
from datetime import datetime, timedelta

# 添加项目根目录到Python路径
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from shared.security.data_isolation import (
    UserContext, DataResource, PermissionType, AccessResult,
    data_isolation_service, IsolationLevel
)
from shared.security.permission_control import (
    ResourceType, ActionType, PermissionScope,
    permission_control_service
)
from shared.security.audit_system import (
    AuditEventType, AuditStatus, AuditLevel,
    audit_system
)

# 配置日志
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class DataIsolationPermissionTester:
    """数据隔离和权限控制测试器"""
    
    def __init__(self):
        self.test_results = []
        self.test_users = {}
        self.test_resources = {}
    
    async def initialize_test_environment(self):
        """初始化测试环境"""
        logger.info("🚀 初始化数据隔离和权限控制测试环境...")
        
        # 创建测试用户
        self.test_users = {
            "super_admin": UserContext(
                user_id="super_admin_1",
                username="super_admin",
                role="super_admin",
                organization_id="org_1",
                tenant_id="tenant_1"
            ),
            "org_admin": UserContext(
                user_id="org_admin_1",
                username="org_admin",
                role="admin",  # 修复：使用正确的角色ID
                organization_id="org_1",
                tenant_id="tenant_1"
            ),
            "user_1": UserContext(
                user_id="user_1",
                username="user1",
                role="user",
                organization_id="org_1",
                tenant_id="tenant_1"
            ),
            "user_2": UserContext(
                user_id="user_2",
                username="user2",
                role="user",
                organization_id="org_2",
                tenant_id="tenant_1"
            ),
            "guest": UserContext(
                user_id="guest_1",
                username="guest",
                role="guest",
                organization_id="org_1",
                tenant_id="tenant_1"
            )
        }
        
        # 创建测试资源
        self.test_resources = {
            "user_data_1": DataResource(
                resource_id="user_data_1",
                resource_type="user_data",
                owner_id="user_1",
                organization_id="org_1",
                tenant_id="tenant_1"
            ),
            "user_data_2": DataResource(
                resource_id="user_data_2",
                resource_type="user_data",
                owner_id="user_2",
                organization_id="org_2",
                tenant_id="tenant_1"
            ),
            "project_data": DataResource(
                resource_id="project_1",
                resource_type="project",
                owner_id="org_admin_1",
                organization_id="org_1",
                tenant_id="tenant_1"
            )
        }
        
        logger.info("✅ 测试环境初始化完成")
    
    async def test_data_isolation(self):
        """测试数据隔离功能"""
        logger.info("🧪 开始测试数据隔离功能...")
        
        test_cases = [
            {
                "name": "用户级数据隔离 - 访问自己的数据",
                "user": "user_1",
                "resource": "user_data_1",
                "expected": AccessResult.ALLOWED
            },
            {
                "name": "用户级数据隔离 - 访问他人的数据",
                "user": "user_1",
                "resource": "user_data_2",
                "expected": AccessResult.DENIED
            },
            {
                "name": "组织级数据隔离 - 同组织访问",
                "user": "org_admin",
                "resource": "user_data_1",
                "expected": AccessResult.ALLOWED
            },
            {
                "name": "组织级数据隔离 - 跨组织访问",
                "user": "org_admin",
                "resource": "user_data_2",
                "expected": AccessResult.DENIED
            }
        ]
        
        for test_case in test_cases:
            try:
                user_context = self.test_users[test_case["user"]]
                resource = self.test_resources[test_case["resource"]]
                
                decision = await data_isolation_service.check_data_access(
                    user_context, resource, PermissionType.READ
                )
                
                success = decision.result == test_case["expected"]
                result = {
                    "test_name": test_case["name"],
                    "success": success,
                    "expected": test_case["expected"].value,
                    "actual": decision.result.value,
                    "reason": decision.reason
                }
                
                if success:
                    logger.info(f"✅ {test_case['name']}: {decision.result.value}")
                else:
                    logger.error(f"❌ {test_case['name']}: 期望 {test_case['expected'].value}, 实际 {decision.result.value}")
                
                self.test_results.append(result)
                
            except Exception as e:
                logger.error(f"❌ {test_case['name']}: 测试失败 - {e}")
                self.test_results.append({
                    "test_name": test_case["name"],
                    "success": False,
                    "error": str(e)
                })
    
    async def test_permission_control(self):
        """测试权限控制功能"""
        logger.info("🧪 开始测试权限控制功能...")
        
        # 分配角色 - 修复角色ID
        await permission_control_service.assign_user_role("super_admin_1", "super", "system")
        await permission_control_service.assign_user_role("org_admin_1", "admin", "system")
        await permission_control_service.assign_user_role("user_1", "user", "system")
        await permission_control_service.assign_user_role("guest_1", "guest", "system")
        
        test_cases = [
            {
                "name": "超级管理员权限 - 创建用户",
                "user_id": "super_admin_1",
                "resource_type": ResourceType.USER,
                "action": ActionType.CREATE,
                "expected": True
            },
            {
                "name": "组织管理员权限 - 创建项目",
                "user_id": "org_admin_1",
                "resource_type": ResourceType.PROJECT,
                "action": ActionType.CREATE,
                "expected": True
            },
            {
                "name": "普通用户权限 - 读取项目",
                "user_id": "user_1",
                "resource_type": ResourceType.PROJECT,
                "action": ActionType.READ,
                "expected": True
            },
            {
                "name": "普通用户权限 - 创建用户",
                "user_id": "user_1",
                "resource_type": ResourceType.USER,
                "action": ActionType.CREATE,
                "expected": True  # 修正：resume所有者可以创建利益相关方用户
            },
            {
                "name": "访客权限 - 读取用户",
                "user_id": "guest_1",
                "resource_type": ResourceType.USER,
                "action": ActionType.READ,
                "expected": True
            },
            {
                "name": "访客权限 - 创建用户",
                "user_id": "guest_1",
                "resource_type": ResourceType.USER,
                "action": ActionType.CREATE,
                "expected": False
            },
            # 新增：细化权限测试用例
            {
                "name": "普通用户权限 - 更新用户",
                "user_id": "user_1",
                "resource_type": ResourceType.USER,
                "action": ActionType.UPDATE,
                "expected": True  # 普通用户可以更新自己的用户数据
            },
            {
                "name": "普通用户权限 - 删除用户",
                "user_id": "user_1",
                "resource_type": ResourceType.USER,
                "action": ActionType.DELETE,
                "expected": False  # 普通用户不能删除用户（即使是自己的）
            },
            {
                "name": "普通用户权限 - 创建简历",
                "user_id": "user_1",
                "resource_type": ResourceType.RESUME,
                "action": ActionType.CREATE,
                "expected": True  # 普通用户可以创建简历
            },
            {
                "name": "普通用户权限 - 更新简历",
                "user_id": "user_1",
                "resource_type": ResourceType.RESUME,
                "action": ActionType.UPDATE,
                "expected": True  # 普通用户可以更新简历
            },
            {
                "name": "普通用户权限 - 删除简历",
                "user_id": "user_1",
                "resource_type": ResourceType.RESUME,
                "action": ActionType.DELETE,
                "expected": True  # 普通用户可以删除简历
            },
            {
                "name": "访客权限 - 创建简历",
                "user_id": "guest_1",
                "resource_type": ResourceType.RESUME,
                "action": ActionType.CREATE,
                "expected": False  # 访客不能创建简历
            },
            {
                "name": "访客权限 - 更新简历",
                "user_id": "guest_1",
                "resource_type": ResourceType.RESUME,
                "action": ActionType.UPDATE,
                "expected": False  # 访客不能更新简历
            }
        ]
        
        for test_case in test_cases:
            try:
                decision = await permission_control_service.check_access(
                    test_case["user_id"],
                    test_case["resource_type"],
                    test_case["action"]
                )
                
                success = decision.granted == test_case["expected"]
                result = {
                    "test_name": test_case["name"],
                    "success": success,
                    "expected": test_case["expected"],
                    "actual": decision.granted,
                    "reason": decision.reason
                }
                
                if success:
                    logger.info(f"✅ {test_case['name']}: {decision.granted}")
                else:
                    logger.error(f"❌ {test_case['name']}: 期望 {test_case['expected']}, 实际 {decision.granted}")
                
                self.test_results.append(result)
                
            except Exception as e:
                logger.error(f"❌ {test_case['name']}: 测试失败 - {e}")
                self.test_results.append({
                    "test_name": test_case["name"],
                    "success": False,
                    "error": str(e)
                })
    
    async def test_audit_system(self):
        """测试审计系统功能"""
        logger.info("🧪 开始测试审计系统功能...")
        
        test_cases = [
            {
                "name": "记录登录事件",
                "event_type": AuditEventType.LOGIN,
                "user_id": "user_1",
                "username": "user1",
                "status": AuditStatus.SUCCESS
            },
            {
                "name": "记录数据访问事件",
                "event_type": AuditEventType.DATA_ACCESS,
                "user_id": "user_1",
                "username": "user1",
                "resource_type": "user_data",
                "action": "read",
                "status": AuditStatus.SUCCESS
            },
            {
                "name": "记录权限变更事件",
                "event_type": AuditEventType.ROLE_ASSIGNMENT,
                "user_id": "super_admin_1",
                "username": "super_admin",
                "resource_type": "user",
                "action": "assign_role",
                "status": AuditStatus.SUCCESS,
                "level": AuditLevel.HIGH
            },
            {
                "name": "记录安全违规事件",
                "event_type": AuditEventType.SECURITY_VIOLATION,
                "user_id": "guest_1",
                "username": "guest",
                "status": AuditStatus.FAILURE,
                "level": AuditLevel.CRITICAL
            }
        ]
        
        for test_case in test_cases:
            try:
                event_id = await audit_system.log_event(
                    event_type=test_case["event_type"],
                    user_id=test_case["user_id"],
                    username=test_case["username"],
                    resource_type=test_case.get("resource_type"),
                    action=test_case.get("action"),
                    status=test_case["status"],
                    level=test_case.get("level", AuditLevel.LOW)
                )
                
                success = bool(event_id)
                result = {
                    "test_name": test_case["name"],
                    "success": success,
                    "event_id": event_id
                }
                
                if success:
                    logger.info(f"✅ {test_case['name']}: 事件ID {event_id}")
                else:
                    logger.error(f"❌ {test_case['name']}: 记录失败")
                
                self.test_results.append(result)
                
            except Exception as e:
                logger.error(f"❌ {test_case['name']}: 测试失败 - {e}")
                self.test_results.append({
                    "test_name": test_case["name"],
                    "success": False,
                    "error": str(e)
                })
    
    async def test_integrated_security(self):
        """测试集成安全功能"""
        logger.info("🧪 开始测试集成安全功能...")
        
        # 确保角色已分配
        await permission_control_service.assign_user_role("super_admin_1", "super", "system")
        await permission_control_service.assign_user_role("org_admin_1", "admin", "system")
        await permission_control_service.assign_user_role("user_1", "user", "system")
        await permission_control_service.assign_user_role("guest_1", "guest", "system")
        
        # 测试完整的访问控制流程
        test_cases = [
            {
                "name": "完整访问控制 - 用户访问自己的数据",
                "user": "user_1",
                "resource": "user_data_1",
                "permission": PermissionType.READ,
                "expected": AccessResult.ALLOWED
            },
            {
                "name": "完整访问控制 - 用户访问他人数据",
                "user": "user_1",
                "resource": "user_data_2",
                "permission": PermissionType.READ,
                "expected": AccessResult.DENIED
            },
            {
                "name": "完整访问控制 - 管理员访问组织数据",
                "user": "org_admin",
                "resource": "user_data_1",
                "permission": PermissionType.WRITE,
                "expected": AccessResult.ALLOWED
            }
        ]
        
        for test_case in test_cases:
            try:
                user_context = self.test_users[test_case["user"]]
                resource = self.test_resources[test_case["resource"]]
                
                # 1. 检查数据隔离
                isolation_decision = await data_isolation_service.check_data_access(
                    user_context, resource, test_case["permission"]
                )
                
                # 2. 检查权限控制
                # 修复权限检查的资源类型映射
                if resource.resource_type == "user_data":
                    resource_type = ResourceType.USER
                elif resource.resource_type == "project":
                    resource_type = ResourceType.PROJECT
                else:
                    resource_type = ResourceType.USER  # 默认
                
                action_type = ActionType.READ if test_case["permission"] == PermissionType.READ else ActionType.UPDATE
                
                # 构建权限检查的上下文
                permission_context = {
                    'user_organization_id': user_context.organization_id,
                    'user_tenant_id': user_context.tenant_id,
                    'resource_organization_id': resource.organization_id,
                    'resource_tenant_id': resource.tenant_id,
                    'resource_owner_id': resource.owner_id,
                    'user_id': user_context.user_id
                }
                
                permission_decision = await permission_control_service.check_access(
                    user_context.user_id,
                    resource_type,
                    action_type,
                    resource_id=resource.resource_id,
                    context=permission_context
                )
                
                # 3. 记录审计事件
                audit_event_id = await audit_system.log_event(
                    event_type=AuditEventType.DATA_ACCESS,
                    user_id=user_context.user_id,
                    username=user_context.username,
                    resource_type=resource.resource_type,
                    resource_id=resource.resource_id,
                    action="read" if test_case["permission"] == PermissionType.READ else "write",
                    status=AuditStatus.SUCCESS if isolation_decision.result == AccessResult.ALLOWED else AuditStatus.FAILURE
                )
                
                # 综合判断
                overall_success = (isolation_decision.result == test_case["expected"] and 
                                 permission_decision.granted == (test_case["expected"] == AccessResult.ALLOWED) and
                                 bool(audit_event_id))
                
                result = {
                    "test_name": test_case["name"],
                    "success": overall_success,
                    "isolation_result": isolation_decision.result.value,
                    "permission_result": permission_decision.granted,
                    "audit_event_id": audit_event_id,
                    "expected": test_case["expected"].value
                }
                
                if overall_success:
                    logger.info(f"✅ {test_case['name']}: 集成测试通过")
                else:
                    logger.error(f"❌ {test_case['name']}: 集成测试失败")
                
                self.test_results.append(result)
                
            except Exception as e:
                logger.error(f"❌ {test_case['name']}: 测试失败 - {e}")
                self.test_results.append({
                    "test_name": test_case["name"],
                    "success": False,
                    "error": str(e)
                })
    
    async def generate_test_report(self):
        """生成测试报告"""
        logger.info("📊 生成测试报告...")
        
        total_tests = len(self.test_results)
        successful_tests = sum(1 for result in self.test_results if result.get("success", False))
        failed_tests = total_tests - successful_tests
        
        success_rate = (successful_tests / total_tests * 100) if total_tests > 0 else 0
        
        report = {
            "test_summary": {
                "total_tests": total_tests,
                "successful_tests": successful_tests,
                "failed_tests": failed_tests,
                "success_rate": success_rate
            },
            "test_results": self.test_results,
            "timestamp": datetime.now().isoformat()
        }
        
        # 保存报告
        import json
        report_file = "docs/data_isolation_permission_test_report.json"
        with open(report_file, 'w', encoding='utf-8') as f:
            json.dump(report, f, indent=2, ensure_ascii=False)
        
        logger.info(f"📊 测试报告已保存到: {report_file}")
        logger.info(f"📊 测试摘要: 总计 {total_tests}, 成功 {successful_tests}, 失败 {failed_tests}, 成功率 {success_rate:.1f}%")
        
        return report

async def main():
    """主测试函数"""
    tester = DataIsolationPermissionTester()
    
    try:
        # 初始化测试环境
        await tester.initialize_test_environment()
        
        # 执行测试
        await tester.test_data_isolation()
        await tester.test_permission_control()
        await tester.test_audit_system()
        await tester.test_integrated_security()
        
        # 生成测试报告
        report = await tester.generate_test_report()
        
        # 输出最终结果
        if report["test_summary"]["success_rate"] >= 80:
            logger.info("🎉 数据隔离和权限控制测试完成！整体表现良好")
        else:
            logger.warning("⚠️ 数据隔离和权限控制测试完成，但需要改进")
        
    except Exception as e:
        logger.error(f"❌ 测试执行失败: {e}")
        return False
    
    return True

if __name__ == "__main__":
    asyncio.run(main())
