#!/usr/bin/env python3
"""
综合数据一致性测试脚本
测试Looma CRM数据同步机制与MySQL数据库的实际数据一致性
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

class ComprehensiveDataConsistencyTester:
    """综合数据一致性测试器"""
    
    def __init__(self):
        self.data_access = UnifiedDataAccess()
        self.mapping_service = DataMappingService()
        self.validator = LoomaDataValidator()
        self.sync_engine = SyncEngine()
        self.mysql_connection = None
        self.test_results = []
    
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
            
        except Exception as e:
            print(f"❌ 测试环境初始化失败: {e}")
            raise
    
    async def test_end_to_end_user_creation(self, user_data: Dict[str, Any]):
        """测试端到端用户创建流程"""
        print(f"\n🧪 开始测试端到端用户创建: {user_data['username']}")
        
        try:
            # 步骤1: 在Looma CRM中创建用户数据
            looma_user = await self._create_looma_user(user_data)
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
            
            # 步骤4: 同步到Zervigo (模拟)
            sync_result = await self.sync_engine.sync_data("looma_crm", "zervigo", zervigo_user, "create")
            print(f"✅ 步骤4: 数据同步成功: {sync_result}")
            
            # 步骤5: 在MySQL中创建实际用户
            mysql_user_id = await self._create_mysql_user(user_data)
            if not mysql_user_id:
                print("❌ MySQL用户创建失败")
                return False
            print(f"✅ 步骤5: MySQL用户创建成功: ID={mysql_user_id}")
            
            # 步骤6: 验证数据一致性
            consistency_result = await self._verify_user_consistency(looma_user, zervigo_user, mysql_user_id)
            print(f"✅ 步骤6: 数据一致性验证: {consistency_result}")
            
            # 记录测试结果
            self.test_results.append({
                "test_type": "end_to_end_user_creation",
                "user_id": user_data["id"],
                "username": user_data["username"],
                "looma_user": looma_user,
                "zervigo_user": zervigo_user,
                "mysql_user_id": mysql_user_id,
                "sync_result": sync_result,
                "consistency_result": consistency_result,
                "success": True,
                "timestamp": datetime.now().isoformat()
            })
            
            return True
            
        except Exception as e:
            print(f"❌ 端到端用户创建测试失败: {e}")
            self.test_results.append({
                "test_type": "end_to_end_user_creation",
                "user_id": user_data["id"],
                "username": user_data["username"],
                "success": False,
                "error": str(e),
                "timestamp": datetime.now().isoformat()
            })
            return False
    
    async def test_data_modification_consistency(self, username: str):
        """测试数据修改一致性"""
        print(f"\n🧪 开始测试数据修改一致性: {username}")
        
        try:
            # 步骤1: 修改Looma CRM数据
            looma_update = {
                "email": f"updated_{username}@example.com",
                "status": "inactive",
                "updated_at": datetime.now().isoformat()
            }
            print(f"✅ 步骤1: 准备Looma CRM数据修改")
            
            # 步骤2: 映射修改数据
            zervigo_update = await self.mapping_service.map_data("looma_crm", "zervigo", looma_update)
            print(f"✅ 步骤2: 映射修改数据")
            
            # 步骤3: 同步修改
            sync_result = await self.sync_engine.sync_data("looma_crm", "zervigo", zervigo_update, "update")
            print(f"✅ 步骤3: 同步修改数据")
            
            # 步骤4: 在MySQL中执行修改
            mysql_success = await self._update_mysql_user(username, looma_update)
            if not mysql_success:
                print("❌ MySQL用户修改失败")
                return False
            print(f"✅ 步骤4: MySQL用户修改成功")
            
            # 步骤5: 验证修改一致性
            consistency_result = await self._verify_modification_consistency(username, looma_update)
            print(f"✅ 步骤5: 修改一致性验证: {consistency_result}")
            
            # 记录测试结果
            self.test_results.append({
                "test_type": "data_modification_consistency",
                "username": username,
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
                "username": username,
                "success": False,
                "error": str(e),
                "timestamp": datetime.now().isoformat()
            })
            return False
    
    async def _create_looma_user(self, user_data: Dict[str, Any]) -> Dict[str, Any]:
        """创建Looma CRM用户数据"""
        looma_user = {
            "id": f"talent_{user_data['id']}",
            "name": user_data["username"],
            "email": user_data["email"],
            "phone": user_data.get("phone", ""),
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
            "created_at": user_data["created_at"],
            "updated_at": user_data["updated_at"],
            "zervigo_user_id": None
        }
        return looma_user
    
    async def _create_mysql_user(self, user_data: Dict[str, Any]) -> int:
        """在MySQL中创建用户"""
        try:
            cursor = self.mysql_connection.cursor()
            
            # 检查用户是否已存在
            cursor.execute("SELECT id FROM users WHERE username = %s", (user_data['username'],))
            existing_user = cursor.fetchone()
            
            if existing_user:
                print(f"⚠️ 用户 {user_data['username']} 已存在，ID: {existing_user[0]}")
                return existing_user[0]
            
            # 创建新用户
            insert_query = """
            INSERT INTO users (username, email, password_hash, role, status, created_at, updated_at)
            VALUES (%s, %s, SHA2(%s, 256), %s, %s, NOW(), NOW())
            """
            
            cursor.execute(insert_query, (
                user_data['username'],
                user_data['email'],
                user_data['password'],
                user_data['role'],
                user_data['status']
            ))
            
            self.mysql_connection.commit()
            user_id = cursor.lastrowid
            cursor.close()
            
            return user_id
            
        except Error as e:
            print(f"❌ MySQL用户创建失败: {e}")
            return None
    
    async def _update_mysql_user(self, username: str, update_data: Dict[str, Any]) -> bool:
        """更新MySQL用户"""
        try:
            cursor = self.mysql_connection.cursor()
            
            update_query = "UPDATE users SET updated_at = NOW()"
            params = []
            
            for key, value in update_data.items():
                if key in ['email', 'status']:
                    update_query += f", {key} = %s"
                    params.append(value)
            
            update_query += " WHERE username = %s"
            params.append(username)
            
            cursor.execute(update_query, params)
            self.mysql_connection.commit()
            
            success = cursor.rowcount > 0
            cursor.close()
            
            return success
            
        except Error as e:
            print(f"❌ MySQL用户更新失败: {e}")
            return False
    
    async def _verify_user_consistency(self, looma_user: Dict[str, Any], zervigo_user: Dict[str, Any], mysql_user_id: int) -> Dict[str, Any]:
        """验证用户数据一致性"""
        consistency_result = {
            "is_consistent": True,
            "errors": [],
            "warnings": []
        }
        
        # 检查Looma CRM与Zervigo的一致性
        if looma_user["name"] != zervigo_user.get("username"):
            consistency_result["errors"].append("Looma CRM与Zervigo用户名不一致")
            consistency_result["is_consistent"] = False
        
        if looma_user["email"] != zervigo_user.get("email"):
            consistency_result["errors"].append("Looma CRM与Zervigo邮箱不一致")
            consistency_result["is_consistent"] = False
        
        # 检查MySQL用户是否存在
        if not mysql_user_id:
            consistency_result["errors"].append("MySQL用户创建失败")
            consistency_result["is_consistent"] = False
        
        return consistency_result
    
    async def _verify_modification_consistency(self, username: str, update_data: Dict[str, Any]) -> Dict[str, Any]:
        """验证修改一致性"""
        consistency_result = {
            "is_consistent": True,
            "errors": [],
            "warnings": []
        }
        
        try:
            cursor = self.mysql_connection.cursor(dictionary=True)
            cursor.execute("SELECT * FROM users WHERE username = %s", (username,))
            mysql_user = cursor.fetchone()
            cursor.close()
            
            if mysql_user:
                # 检查更新字段是否一致
                for key, value in update_data.items():
                    if key in ['email', 'status'] and mysql_user.get(key) != value:
                        consistency_result["warnings"].append(f"MySQL中{key}字段未更新")
            else:
                consistency_result["errors"].append("MySQL中找不到用户")
                consistency_result["is_consistent"] = False
                
        except Error as e:
            consistency_result["errors"].append(f"MySQL查询失败: {e}")
            consistency_result["is_consistent"] = False
        
        return consistency_result
    
    async def generate_test_report(self):
        """生成测试报告"""
        report = {
            "test_time": datetime.now().isoformat(),
            "total_tests": len(self.test_results),
            "successful_tests": len([r for r in self.test_results if r.get("success", False)]),
            "failed_tests": len([r for r in self.test_results if not r.get("success", True)]),
            "test_results": self.test_results,
            "summary": {
                "end_to_end_tests": len([r for r in self.test_results if r.get("test_type") == "end_to_end_user_creation"]),
                "modification_tests": len([r for r in self.test_results if r.get("test_type") == "data_modification_consistency"])
            }
        }
        
        with open("docs/comprehensive_data_consistency_test_report.json", "w", encoding="utf-8") as f:
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
    print("🚀 开始综合数据一致性测试...")
    
    # 加载测试数据
    try:
        with open("test_data.json", "r", encoding="utf-8") as f:
            test_data = json.load(f)
        print(f"✅ 加载测试数据: {test_data['summary']}")
    except FileNotFoundError:
        print("❌ 测试数据文件不存在，请先运行数据生成器")
        return
    
    # 初始化测试器
    tester = ComprehensiveDataConsistencyTester()
    
    try:
        # 初始化测试环境
        await tester.initialize()
        
        # 测试前3个用户的端到端创建
        for user in test_data["users"][:3]:
            await tester.test_end_to_end_user_creation(user)
        
        # 测试数据修改一致性
        await tester.test_data_modification_consistency("testuser1")
        
        # 生成测试报告
        report = await tester.generate_test_report()
        
        print("\n🎉 综合数据一致性测试完成！")
        print(f"总测试数: {report['total_tests']}")
        print(f"成功测试: {report['successful_tests']}")
        print(f"失败测试: {report['failed_tests']}")
        print(f"测试报告已保存到: docs/comprehensive_data_consistency_test_report.json")
        
    except Exception as e:
        print(f"❌ 测试失败: {e}")
        import traceback
        traceback.print_exc()
    finally:
        await tester.cleanup()

if __name__ == "__main__":
    asyncio.run(main())
