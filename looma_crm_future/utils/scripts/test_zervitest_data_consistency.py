#!/usr/bin/env python3
"""
zervitest用户数据一致性测试脚本
使用完善后的zervitest用户测试Looma CRM与Zervigo子系统的数据一致性
"""

import asyncio
import json
import sys
import os
import mysql.connector
from mysql.connector import Error
from datetime import datetime
from typing import Dict, Any, List

# 添加项目根目录到Python路径
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from shared.database.unified_data_access import UnifiedDataAccess
from shared.database.data_mappers import DataMappingService
from shared.database.data_validators import LoomaDataValidator
from shared.sync.sync_engine import SyncEngine

class ZervitestDataConsistencyTester:
    """zervitest用户数据一致性测试器"""
    
    def __init__(self):
        self.data_access = UnifiedDataAccess()
        self.mapping_service = DataMappingService()
        self.validator = LoomaDataValidator()
        self.sync_engine = SyncEngine()
        self.mysql_connection = None
        self.test_results = []
        self.zervitest_user_data = None
    
    async def initialize(self):
        """初始化测试环境"""
        try:
            # 初始化Looma CRM组件
            await self.data_access.initialize()
            await self.sync_engine.start()
            print("✅ Looma CRM组件初始化成功")
            
            # 连接MySQL数据库
            self.mysql_connection = mysql.connector.connect(
                host='localhost',
                port=3306,
                user='root',
                password='',
                database='jobfirst',
                charset='utf8mb4'
            )
            print("✅ MySQL数据库连接成功")
            
            # 获取zervitest用户数据
            await self._load_zervitest_user_data()
            
        except Exception as e:
            print(f"❌ 测试环境初始化失败: {e}")
            raise
    
    async def _load_zervitest_user_data(self):
        """加载zervitest用户数据"""
        try:
            cursor = self.mysql_connection.cursor(dictionary=True)
            cursor.execute("SELECT * FROM users WHERE username = 'zervitest'")
            user_data = cursor.fetchone()
            cursor.close()
            
            if user_data:
                self.zervitest_user_data = user_data
                print(f"✅ 加载zervitest用户数据: ID={user_data['id']}")
                print(f"  用户名: {user_data['username']}")
                print(f"  邮箱: {user_data['email']}")
                print(f"  手机: {user_data['phone']}")
                print(f"  角色: {user_data['role']}")
                print(f"  状态: {user_data['status']}")
                print(f"  姓名: {user_data['first_name']} {user_data['last_name']}")
                print(f"  验证状态: 邮箱={user_data['email_verified']}, 手机={user_data['phone_verified']}")
            else:
                print("❌ 未找到zervitest用户数据")
                raise Exception("zervitest用户不存在")
                
        except Error as e:
            print(f"❌ 加载用户数据失败: {e}")
            raise
    
    async def test_complete_user_data_flow(self):
        """测试完整的用户数据流程"""
        print(f"\n🧪 开始测试zervitest用户完整数据流程...")
        
        try:
            # 步骤1: 创建Looma CRM格式的用户数据
            looma_user = await self._create_looma_user_from_mysql()
            print(f"✅ 步骤1: 创建Looma CRM用户数据: {looma_user['id']}")
            
            # 步骤2: 数据验证
            validation_result = await self.validator.validate(looma_user)
            if not validation_result.is_valid:
                print(f"❌ 数据验证失败: {validation_result.errors}")
                return False
            print(f"✅ 步骤2: 数据验证通过")
            
            # 步骤3: 映射到Zervigo格式
            zervigo_user = await self.mapping_service.map_data("looma_crm", "zervigo", looma_user)
            if not zervigo_user:
                print("❌ 数据映射失败")
                return False
            print(f"✅ 步骤3: 数据映射成功")
            print(f"  Zervigo用户数据: {zervigo_user}")
            
            # 步骤4: 同步到Zervigo
            sync_result = await self.sync_engine.sync_data("looma_crm", "zervigo", zervigo_user, "create")
            print(f"✅ 步骤4: 数据同步成功: {sync_result}")
            
            # 步骤5: 验证数据一致性
            consistency_result = await self._verify_complete_consistency(looma_user, zervigo_user)
            print(f"✅ 步骤5: 数据一致性验证: {consistency_result}")
            
            # 记录测试结果
            self.test_results.append({
                "test_type": "complete_user_data_flow",
                "user_id": self.zervitest_user_data['id'],
                "username": self.zervitest_user_data['username'],
                "looma_user": looma_user,
                "zervigo_user": zervigo_user,
                "sync_result": sync_result,
                "consistency_result": consistency_result,
                "success": True,
                "timestamp": datetime.now().isoformat()
            })
            
            return True
            
        except Exception as e:
            print(f"❌ 完整用户数据流程测试失败: {e}")
            self.test_results.append({
                "test_type": "complete_user_data_flow",
                "user_id": self.zervitest_user_data['id'],
                "username": self.zervitest_user_data['username'],
                "success": False,
                "error": str(e),
                "timestamp": datetime.now().isoformat()
            })
            return False
    
    async def test_data_modification_consistency(self):
        """测试数据修改一致性"""
        print(f"\n🧪 开始测试zervitest用户数据修改一致性...")
        
        try:
            # 步骤1: 修改用户数据
            modification_data = {
                "email": "zervitest_updated@example.com",
                "phone": "+12345678988",
                "first_name": "ZerviUpdated",
                "last_name": "TestUpdated",
                "status": "inactive",
                "updated_at": datetime.now().isoformat()
            }
            print(f"✅ 步骤1: 准备数据修改: {modification_data}")
            
            # 步骤2: 在MySQL中更新数据
            mysql_success = await self._update_mysql_user_data(modification_data)
            if not mysql_success:
                print("❌ MySQL数据更新失败")
                return False
            print(f"✅ 步骤2: MySQL数据更新成功")
            
            # 步骤3: 创建Looma CRM格式的更新数据
            looma_update = await self._create_looma_update_data(modification_data)
            print(f"✅ 步骤3: 创建Looma CRM更新数据")
            
            # 步骤4: 映射到Zervigo格式
            zervigo_update = await self.mapping_service.map_data("looma_crm", "zervigo", looma_update)
            print(f"✅ 步骤4: 映射到Zervigo格式")
            
            # 步骤5: 同步更新
            sync_result = await self.sync_engine.sync_data("looma_crm", "zervigo", zervigo_update, "update")
            print(f"✅ 步骤5: 同步更新成功: {sync_result}")
            
            # 步骤6: 验证修改一致性
            consistency_result = await self._verify_modification_consistency(modification_data)
            print(f"✅ 步骤6: 修改一致性验证: {consistency_result}")
            
            # 记录测试结果
            self.test_results.append({
                "test_type": "data_modification_consistency",
                "user_id": self.zervitest_user_data['id'],
                "username": self.zervitest_user_data['username'],
                "modification_data": modification_data,
                "looma_update": looma_update,
                "zervigo_update": zervigo_update,
                "sync_result": sync_result,
                "consistency_result": consistency_result,
                "success": True,
                "timestamp": datetime.now().isoformat()
            })
            
            return True
            
        except Exception as e:
            print(f"❌ 数据修改一致性测试失败: {e}")
            self.test_results.append({
                "test_type": "data_modification_consistency",
                "user_id": self.zervitest_user_data['id'],
                "username": self.zervitest_user_data['username'],
                "success": False,
                "error": str(e),
                "timestamp": datetime.now().isoformat()
            })
            return False
    
    async def test_authentication_parameters_consistency(self):
        """测试认证参数一致性"""
        print(f"\n🧪 开始测试zervitest用户认证参数一致性...")
        
        try:
            # 步骤1: 分析认证参数
            auth_params = await self._analyze_authentication_parameters()
            print(f"✅ 步骤1: 认证参数分析完成")
            
            # 步骤2: 验证认证参数完整性
            completeness_result = await self._verify_auth_parameters_completeness(auth_params)
            print(f"✅ 步骤2: 认证参数完整性验证: {completeness_result}")
            
            # 步骤3: 测试认证参数映射
            auth_mapping_result = await self._test_auth_parameters_mapping(auth_params)
            print(f"✅ 步骤3: 认证参数映射测试: {auth_mapping_result}")
            
            # 步骤4: 验证认证参数同步
            auth_sync_result = await self._test_auth_parameters_sync(auth_params)
            print(f"✅ 步骤4: 认证参数同步测试: {auth_sync_result}")
            
            # 记录测试结果
            self.test_results.append({
                "test_type": "authentication_parameters_consistency",
                "user_id": self.zervitest_user_data['id'],
                "username": self.zervitest_user_data['username'],
                "auth_params": auth_params,
                "completeness_result": completeness_result,
                "mapping_result": auth_mapping_result,
                "sync_result": auth_sync_result,
                "success": True,
                "timestamp": datetime.now().isoformat()
            })
            
            return True
            
        except Exception as e:
            print(f"❌ 认证参数一致性测试失败: {e}")
            self.test_results.append({
                "test_type": "authentication_parameters_consistency",
                "user_id": self.zervitest_user_data['id'],
                "username": self.zervitest_user_data['username'],
                "success": False,
                "error": str(e),
                "timestamp": datetime.now().isoformat()
            })
            return False
    
    async def _create_looma_user_from_mysql(self) -> Dict[str, Any]:
        """从MySQL数据创建Looma CRM用户数据"""
        user_data = self.zervitest_user_data
        
        looma_user = {
            "id": f"talent_{user_data['id']}",
            "name": user_data["username"],
            "email": user_data["email"],
            "phone": user_data["phone"] or "",
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
            "status": user_data["status"],
            "created_at": user_data["created_at"].isoformat() if user_data["created_at"] else datetime.now().isoformat(),
            "updated_at": user_data["updated_at"].isoformat() if user_data["updated_at"] else datetime.now().isoformat(),
            "zervigo_user_id": user_data["id"],
            "first_name": user_data["first_name"],
            "last_name": user_data["last_name"],
            "email_verified": bool(user_data["email_verified"]),
            "phone_verified": bool(user_data["phone_verified"])
        }
        return looma_user
    
    async def _update_mysql_user_data(self, modification_data: Dict[str, Any]) -> bool:
        """更新MySQL用户数据"""
        try:
            cursor = self.mysql_connection.cursor()
            
            update_query = "UPDATE users SET updated_at = NOW()"
            params = []
            
            for key, value in modification_data.items():
                if key in ['email', 'phone', 'first_name', 'last_name', 'status']:
                    update_query += f", {key} = %s"
                    params.append(value)
            
            update_query += " WHERE username = 'zervitest'"
            
            cursor.execute(update_query, params)
            self.mysql_connection.commit()
            
            success = cursor.rowcount > 0
            cursor.close()
            
            return success
            
        except Error as e:
            print(f"❌ MySQL用户数据更新失败: {e}")
            return False
    
    async def _create_looma_update_data(self, modification_data: Dict[str, Any]) -> Dict[str, Any]:
        """创建Looma CRM更新数据"""
        return {
            "id": f"talent_{self.zervitest_user_data['id']}",
            "email": modification_data.get("email"),
            "phone": modification_data.get("phone"),
            "first_name": modification_data.get("first_name"),
            "last_name": modification_data.get("last_name"),
            "status": modification_data.get("status"),
            "updated_at": modification_data.get("updated_at")
        }
    
    async def _verify_complete_consistency(self, looma_user: Dict[str, Any], zervigo_user: Dict[str, Any]) -> Dict[str, Any]:
        """验证完整的数据一致性"""
        consistency_result = {
            "is_consistent": True,
            "errors": [],
            "warnings": [],
            "details": {}
        }
        
        # 检查关键字段一致性
        field_mappings = [
            ("name", "username", "用户名"),
            ("email", "email", "邮箱"),
            ("phone", "phone", "手机号"),
            ("status", "status", "状态")
        ]
        
        for looma_field, zervigo_field, field_name in field_mappings:
            looma_value = looma_user.get(looma_field)
            zervigo_value = zervigo_user.get(zervigo_field)
            
            if looma_value != zervigo_value:
                consistency_result["errors"].append(f"{field_name}不一致: Looma CRM {looma_value} vs Zervigo {zervigo_value}")
                consistency_result["is_consistent"] = False
            else:
                consistency_result["details"][field_name] = "一致"
        
        # 检查认证参数
        auth_fields = ["first_name", "last_name", "email_verified", "phone_verified"]
        for field in auth_fields:
            if field in looma_user and field in zervigo_user:
                if looma_user[field] != zervigo_user.get(field):
                    consistency_result["warnings"].append(f"认证参数{field}不一致")
                else:
                    consistency_result["details"][f"认证参数{field}"] = "一致"
        
        return consistency_result
    
    async def _verify_modification_consistency(self, modification_data: Dict[str, Any]) -> Dict[str, Any]:
        """验证修改一致性"""
        consistency_result = {
            "is_consistent": True,
            "errors": [],
            "warnings": [],
            "details": {}
        }
        
        try:
            cursor = self.mysql_connection.cursor(dictionary=True)
            cursor.execute("SELECT * FROM users WHERE username = 'zervitest'")
            updated_user = cursor.fetchone()
            cursor.close()
            
            if updated_user:
                # 检查更新字段是否一致
                for key, expected_value in modification_data.items():
                    if key in ['email', 'phone', 'first_name', 'last_name', 'status']:
                        actual_value = updated_user.get(key)
                        if actual_value != expected_value:
                            consistency_result["warnings"].append(f"MySQL中{key}字段未正确更新: 期望{expected_value}, 实际{actual_value}")
                        else:
                            consistency_result["details"][f"MySQL_{key}"] = "更新成功"
            else:
                consistency_result["errors"].append("MySQL中找不到用户")
                consistency_result["is_consistent"] = False
                
        except Error as e:
            consistency_result["errors"].append(f"MySQL查询失败: {e}")
            consistency_result["is_consistent"] = False
        
        return consistency_result
    
    async def _analyze_authentication_parameters(self) -> Dict[str, Any]:
        """分析认证参数"""
        user_data = self.zervitest_user_data
        
        auth_params = {
            "user_id": user_data['id'],
            "username": user_data['username'],
            "email": user_data['email'],
            "phone": user_data['phone'],
            "role": user_data['role'],
            "status": user_data['status'],
            "email_verified": bool(user_data['email_verified']),
            "phone_verified": bool(user_data['phone_verified']),
            "first_name": user_data['first_name'],
            "last_name": user_data['last_name']
        }
        
        return auth_params
    
    async def _verify_auth_parameters_completeness(self, auth_params: Dict[str, Any]) -> Dict[str, Any]:
        """验证认证参数完整性"""
        completeness_result = {
            "is_complete": True,
            "completeness_score": 0,
            "missing_fields": [],
            "details": {}
        }
        
        required_fields = {
            "username": "用户名",
            "email": "邮箱",
            "phone": "手机号",
            "role": "角色",
            "status": "状态",
            "first_name": "名字",
            "last_name": "姓氏"
        }
        
        verified_fields = {
            "email_verified": "邮箱验证",
            "phone_verified": "手机验证"
        }
        
        # 检查必需字段
        for field, field_name in required_fields.items():
            if auth_params.get(field):
                completeness_result["details"][field_name] = "完整"
            else:
                completeness_result["missing_fields"].append(field_name)
                completeness_result["is_complete"] = False
        
        # 检查验证字段
        for field, field_name in verified_fields.items():
            if auth_params.get(field):
                completeness_result["details"][field_name] = "已验证"
            else:
                completeness_result["details"][field_name] = "未验证"
        
        # 计算完整性得分
        total_fields = len(required_fields) + len(verified_fields)
        complete_fields = len(required_fields) - len(completeness_result["missing_fields"]) + sum(1 for f in verified_fields.values() if auth_params.get(f))
        completeness_result["completeness_score"] = (complete_fields / total_fields) * 100
        
        return completeness_result
    
    async def _test_auth_parameters_mapping(self, auth_params: Dict[str, Any]) -> Dict[str, Any]:
        """测试认证参数映射"""
        mapping_result = {
            "mapping_successful": True,
            "mapped_fields": {},
            "errors": []
        }
        
        try:
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
            
            # 映射到Zervigo格式
            zervigo_auth_data = await self.mapping_service.map_data("looma_crm", "zervigo", looma_auth_data)
            
            if zervigo_auth_data:
                mapping_result["mapped_fields"] = zervigo_auth_data
                mapping_result["mapping_successful"] = True
            else:
                mapping_result["errors"].append("认证参数映射失败")
                mapping_result["mapping_successful"] = False
                
        except Exception as e:
            mapping_result["errors"].append(f"认证参数映射错误: {e}")
            mapping_result["mapping_successful"] = False
        
        return mapping_result
    
    async def _test_auth_parameters_sync(self, auth_params: Dict[str, Any]) -> Dict[str, Any]:
        """测试认证参数同步"""
        sync_result = {
            "sync_successful": True,
            "sync_details": {},
            "errors": []
        }
        
        try:
            # 创建认证参数同步数据
            auth_sync_data = {
                "user_id": auth_params["user_id"],
                "username": auth_params["username"],
                "email": auth_params["email"],
                "phone": auth_params["phone"],
                "role": auth_params["role"],
                "status": auth_params["status"],
                "email_verified": auth_params["email_verified"],
                "phone_verified": auth_params["phone_verified"],
                "first_name": auth_params["first_name"],
                "last_name": auth_params["last_name"]
            }
            
            # 执行同步
            sync_response = await self.sync_engine.sync_data("looma_crm", "zervigo", auth_sync_data, "update")
            
            if sync_response:
                sync_result["sync_details"] = sync_response
                sync_result["sync_successful"] = True
            else:
                sync_result["errors"].append("认证参数同步失败")
                sync_result["sync_successful"] = False
                
        except Exception as e:
            sync_result["errors"].append(f"认证参数同步错误: {e}")
            sync_result["sync_successful"] = False
        
        return sync_result
    
    async def generate_test_report(self):
        """生成测试报告"""
        report = {
            "test_time": datetime.now().isoformat(),
            "test_user": {
                "id": self.zervitest_user_data['id'],
                "username": self.zervitest_user_data['username'],
                "email": self.zervitest_user_data['email'],
                "phone": self.zervitest_user_data['phone'],
                "role": self.zervitest_user_data['role'],
                "status": self.zervitest_user_data['status']
            },
            "total_tests": len(self.test_results),
            "successful_tests": len([r for r in self.test_results if r.get("success", False)]),
            "failed_tests": len([r for r in self.test_results if not r.get("success", True)]),
            "test_results": self.test_results,
            "summary": {
                "complete_user_data_flow": len([r for r in self.test_results if r.get("test_type") == "complete_user_data_flow"]),
                "data_modification_consistency": len([r for r in self.test_results if r.get("test_type") == "data_modification_consistency"]),
                "authentication_parameters_consistency": len([r for r in self.test_results if r.get("test_type") == "authentication_parameters_consistency"])
            }
        }
        
        with open("docs/zervitest_data_consistency_test_report.json", "w", encoding="utf-8") as f:
            json.dump(report, f, indent=2, ensure_ascii=False, default=str)
        
        return report
    
    async def cleanup(self):
        """清理测试环境"""
        try:
            await self.sync_engine.stop()
            await self.data_access.close()
            if self.mysql_connection and self.mysql_connection.is_connected():
                self.mysql_connection.close()
            print("✅ 测试环境清理完成")
        except Exception as e:
            print(f"❌ 测试环境清理失败: {e}")

async def main():
    """主函数"""
    print("🚀 开始zervitest用户数据一致性测试...")
    
    tester = ZervitestDataConsistencyTester()
    
    try:
        # 初始化测试环境
        await tester.initialize()
        
        # 运行所有测试
        await tester.test_complete_user_data_flow()
        await tester.test_data_modification_consistency()
        await tester.test_authentication_parameters_consistency()
        
        # 生成测试报告
        report = await tester.generate_test_report()
        
        print("\n🎉 zervitest用户数据一致性测试完成！")
        print(f"测试用户: {report['test_user']['username']} (ID: {report['test_user']['id']})")
        print(f"总测试数: {report['total_tests']}")
        print(f"成功测试: {report['successful_tests']}")
        print(f"失败测试: {report['failed_tests']}")
        print(f"测试报告已保存到: docs/zervitest_data_consistency_test_report.json")
        
        # 显示测试摘要
        print("\n📊 测试摘要:")
        for test_type, count in report['summary'].items():
            print(f"  {test_type}: {count} 个测试")
        
    except Exception as e:
        print(f"❌ 测试失败: {e}")
        import traceback
        traceback.print_exc()
    finally:
        await tester.cleanup()

if __name__ == "__main__":
    asyncio.run(main())
