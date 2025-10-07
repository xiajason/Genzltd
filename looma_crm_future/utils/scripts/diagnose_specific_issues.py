#!/usr/bin/env python3
"""
具体问题诊断脚本
重现和诊断数据一致性测试中的具体问题
"""

import asyncio
import json
import sys
import os
import traceback
from datetime import datetime
from typing import Dict, Any, List

# 添加项目根目录到Python路径
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from shared.database.unified_data_access import UnifiedDataAccess
from shared.database.data_mappers import DataMappingService
from shared.database.data_validators import LoomaDataValidator
from shared.sync.sync_engine import SyncEngine

class SpecificIssuesDiagnostic:
    """具体问题诊断器"""
    
    def __init__(self):
        self.data_access = UnifiedDataAccess()
        self.mapping_service = DataMappingService()
        self.validator = LoomaDataValidator()
        self.sync_engine = SyncEngine()
        self.diagnostic_results = []
    
    async def initialize(self):
        """初始化诊断环境"""
        try:
            await self.data_access.initialize()
            await self.sync_engine.start()
            print("✅ 诊断环境初始化成功")
        except Exception as e:
            print(f"❌ 诊断环境初始化失败: {e}")
            raise
    
    async def diagnose_float_none_error(self):
        """诊断 float() argument must be a string or a real number, not 'NoneType' 错误"""
        print("\n🔍 诊断问题1: float() argument must be a string or a real number, not 'NoneType'")
        
        try:
            # 重现测试数据
            test_user = {
                "id": "test_user_1",
                "username": "testuser1",
                "email": "testuser1@example.com",
                "password": "test123456",
                "role": "guest",
                "status": "active",
                "first_name": "Test1",
                "last_name": "User",
                "phone": "+12345678900",
                "created_at": "2025-08-27T21:02:52.001381",
                "updated_at": "2025-09-23T21:02:52.001389"
            }
            
            print(f"📋 测试用户数据: {test_user}")
            
            # 步骤1: 创建Looma CRM用户数据
            print("📋 步骤1: 创建Looma CRM用户数据...")
            looma_user = {
                "id": f"talent_{test_user['id']}",
                "name": test_user["username"],
                "email": test_user["email"],
                "phone": test_user.get("phone", ""),
                "skills": [],
                "experience": 0,
                "education": {
                    "degree": "Bachelor",
                    "school": "Test University",
                    "major": "Computer Science",
                    "graduation_year": 2020
                },
                "projects": [],
                "relationships": [],
                "status": test_user["status"],
                "created_at": test_user["created_at"],
                "updated_at": test_user["updated_at"],
                "zervigo_user_id": None
            }
            print(f"✅ Looma CRM用户数据创建: {looma_user['id']}")
            
            # 步骤2: 数据验证 - 这里可能出现float()错误
            print("📋 步骤2: 数据验证...")
            try:
                validation_result = await self.validator.validate(looma_user)
                print(f"✅ 数据验证结果: {validation_result.is_valid}")
                if not validation_result.is_valid:
                    print(f"❌ 数据验证失败: {validation_result.errors}")
            except Exception as e:
                print(f"❌ 数据验证异常: {e}")
                print(f"📋 异常类型: {type(e).__name__}")
                print(f"📋 异常详情: {str(e)}")
                print(f"📋 异常追踪:")
                traceback.print_exc()
                
                # 记录诊断结果
                self.diagnostic_results.append({
                    "issue": "float_none_error",
                    "step": "data_validation",
                    "error_type": type(e).__name__,
                    "error_message": str(e),
                    "test_data": test_user,
                    "looma_data": looma_user,
                    "timestamp": datetime.now().isoformat()
                })
                return False
            
            # 步骤3: 数据映射
            print("📋 步骤3: 数据映射...")
            try:
                zervigo_user = await self.mapping_service.map_data("looma_crm", "zervigo", looma_user)
                print(f"✅ 数据映射成功: {zervigo_user}")
            except Exception as e:
                print(f"❌ 数据映射异常: {e}")
                print(f"📋 异常类型: {type(e).__name__}")
                print(f"📋 异常详情: {str(e)}")
                print(f"📋 异常追踪:")
                traceback.print_exc()
                
                # 记录诊断结果
                self.diagnostic_results.append({
                    "issue": "mapping_error",
                    "step": "data_mapping",
                    "error_type": type(e).__name__,
                    "error_message": str(e),
                    "test_data": test_user,
                    "looma_data": looma_user,
                    "timestamp": datetime.now().isoformat()
                })
                return False
            
            return True
            
        except Exception as e:
            print(f"❌ 诊断过程异常: {e}")
            print(f"📋 异常追踪:")
            traceback.print_exc()
            return False
    
    async def diagnose_mapping_failure(self):
        """诊断认证参数映射失败问题"""
        print("\n🔍 诊断问题2: 认证参数映射失败")
        
        try:
            # 重现认证参数数据
            auth_params = {
                "user_id": 17,
                "username": "zervitest",
                "email": "zervitest@example.com",
                "phone": "+12345678999",
                "role": "guest",
                "status": "active",
                "email_verified": True,
                "phone_verified": True,
                "first_name": "Zervi",
                "last_name": "Test"
            }
            
            print(f"📋 认证参数数据: {auth_params}")
            
            # 创建Looma CRM格式的认证数据
            looma_auth_data = {
                "id": f"talent_{auth_params['user_id']}",
                "name": auth_params["username"],
                "email": auth_params["email"],
                "phone": auth_params["phone"],
                "first_name": auth_params["first_name"],
                "last_name": auth_params["last_name"],
                "email_verified": auth_params["email_verified"],
                "phone_verified": auth_params["phone_verified"],
                "status": auth_params["status"]
            }
            
            print(f"📋 Looma CRM认证数据: {looma_auth_data}")
            
            # 尝试映射到Zervigo格式
            print("📋 尝试映射到Zervigo格式...")
            try:
                zervigo_auth_data = await self.mapping_service.map_data("looma_crm", "zervigo", looma_auth_data)
                print(f"✅ 映射成功: {zervigo_auth_data}")
                
                if not zervigo_auth_data:
                    print("❌ 映射结果为空")
                    self.diagnostic_results.append({
                        "issue": "mapping_empty_result",
                        "step": "auth_parameters_mapping",
                        "error_type": "EmptyResult",
                        "error_message": "映射结果为空",
                        "input_data": looma_auth_data,
                        "output_data": zervigo_auth_data,
                        "timestamp": datetime.now().isoformat()
                    })
                    return False
                else:
                    print("✅ 认证参数映射成功")
                    return True
                    
            except Exception as e:
                print(f"❌ 认证参数映射异常: {e}")
                print(f"📋 异常类型: {type(e).__name__}")
                print(f"📋 异常详情: {str(e)}")
                print(f"📋 异常追踪:")
                traceback.print_exc()
                
                # 记录诊断结果
                self.diagnostic_results.append({
                    "issue": "auth_mapping_error",
                    "step": "auth_parameters_mapping",
                    "error_type": type(e).__name__,
                    "error_message": str(e),
                    "input_data": looma_auth_data,
                    "timestamp": datetime.now().isoformat()
                })
                return False
            
        except Exception as e:
            print(f"❌ 诊断过程异常: {e}")
            print(f"📋 异常追踪:")
            traceback.print_exc()
            return False
    
    async def diagnose_data_mapping_issues(self):
        """诊断数据映射问题"""
        print("\n🔍 诊断问题3: 数据映射问题")
        
        try:
            # 测试不同的数据映射场景
            test_scenarios = [
                {
                    "name": "完整用户数据",
                    "data": {
                        "id": "talent_1",
                        "name": "testuser1",
                        "email": "testuser1@example.com",
                        "phone": "+12345678900",
                        "status": "active",
                        "experience": 0,
                        "education": {
                            "degree": "Bachelor",
                            "school": "Test University",
                            "major": "Computer Science",
                            "graduation_year": 2020
                        }
                    }
                },
                {
                    "name": "缺少某些字段",
                    "data": {
                        "id": "talent_2",
                        "name": "testuser2",
                        "email": "testuser2@example.com",
                        "status": "active"
                    }
                },
                {
                    "name": "包含None值",
                    "data": {
                        "id": "talent_3",
                        "name": "testuser3",
                        "email": "testuser3@example.com",
                        "phone": None,
                        "status": "active",
                        "experience": None
                    }
                }
            ]
            
            for scenario in test_scenarios:
                print(f"\n📋 测试场景: {scenario['name']}")
                print(f"📋 测试数据: {scenario['data']}")
                
                try:
                    result = await self.mapping_service.map_data("looma_crm", "zervigo", scenario['data'])
                    print(f"✅ 映射成功: {result}")
                    
                    if not result:
                        print("❌ 映射结果为空")
                        self.diagnostic_results.append({
                            "issue": "mapping_empty_result",
                            "scenario": scenario['name'],
                            "input_data": scenario['data'],
                            "output_data": result,
                            "timestamp": datetime.now().isoformat()
                        })
                    
                except Exception as e:
                    print(f"❌ 映射失败: {e}")
                    print(f"📋 异常类型: {type(e).__name__}")
                    print(f"📋 异常详情: {str(e)}")
                    
                    self.diagnostic_results.append({
                        "issue": "mapping_error",
                        "scenario": scenario['name'],
                        "error_type": type(e).__name__,
                        "error_message": str(e),
                        "input_data": scenario['data'],
                        "timestamp": datetime.now().isoformat()
                    })
            
            return True
            
        except Exception as e:
            print(f"❌ 诊断过程异常: {e}")
            print(f"📋 异常追踪:")
            traceback.print_exc()
            return False
    
    async def generate_diagnostic_report(self):
        """生成诊断报告"""
        report = {
            "diagnostic_time": datetime.now().isoformat(),
            "total_issues": len(self.diagnostic_results),
            "issues_by_type": {},
            "detailed_issues": self.diagnostic_results,
            "recommendations": []
        }
        
        # 统计问题类型
        for issue in self.diagnostic_results:
            issue_type = issue.get("issue", "unknown")
            if issue_type not in report["issues_by_type"]:
                report["issues_by_type"][issue_type] = 0
            report["issues_by_type"][issue_type] += 1
        
        # 生成建议
        if "float_none_error" in report["issues_by_type"]:
            report["recommendations"].append({
                "issue": "float_none_error",
                "recommendation": "在数据验证器中添加None值检查，确保数值字段不为None",
                "priority": "高",
                "solution": "修改LoomaDataValidator，在验证数值字段前检查是否为None"
            })
        
        if "mapping_error" in report["issues_by_type"]:
            report["recommendations"].append({
                "issue": "mapping_error",
                "recommendation": "完善数据映射器，处理各种边界情况",
                "priority": "中",
                "solution": "修改DataMappingService，添加更完善的错误处理和字段映射逻辑"
            })
        
        if "mapping_empty_result" in report["issues_by_type"]:
            report["recommendations"].append({
                "issue": "mapping_empty_result",
                "recommendation": "检查映射器配置，确保映射规则正确",
                "priority": "中",
                "solution": "检查映射器配置文件和映射规则定义"
            })
        
        # 保存报告
        with open("docs/specific_issues_diagnostic_report.json", "w", encoding="utf-8") as f:
            json.dump(report, f, indent=2, ensure_ascii=False, default=str)
        
        return report
    
    async def cleanup(self):
        """清理诊断环境"""
        try:
            await self.sync_engine.stop()
            await self.data_access.close()
            print("✅ 诊断环境清理完成")
        except Exception as e:
            print(f"❌ 诊断环境清理失败: {e}")

async def main():
    """主函数"""
    print("🚀 开始具体问题诊断...")
    
    diagnostic = SpecificIssuesDiagnostic()
    
    try:
        # 初始化诊断环境
        await diagnostic.initialize()
        
        # 诊断各种问题
        await diagnostic.diagnose_float_none_error()
        await diagnostic.diagnose_mapping_failure()
        await diagnostic.diagnose_data_mapping_issues()
        
        # 生成诊断报告
        report = await diagnostic.generate_diagnostic_report()
        
        print("\n🎉 具体问题诊断完成！")
        print(f"发现问题总数: {report['total_issues']}")
        print(f"问题类型统计: {report['issues_by_type']}")
        print(f"诊断报告已保存到: docs/specific_issues_diagnostic_report.json")
        
        # 显示建议
        if report["recommendations"]:
            print("\n📋 改进建议:")
            for rec in report["recommendations"]:
                print(f"  - {rec['issue']}: {rec['recommendation']} (优先级: {rec['priority']})")
        
    except Exception as e:
        print(f"❌ 诊断失败: {e}")
        import traceback
        traceback.print_exc()
    finally:
        await diagnostic.cleanup()

if __name__ == "__main__":
    asyncio.run(main())
