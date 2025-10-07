#!/usr/bin/env python3
"""
MySQL数据库连接测试
测试Looma CRM与MySQL数据库的实际连接
"""

import asyncio
import mysql.connector
from mysql.connector import Error
import json
from datetime import datetime
from typing import Dict, Any, List

class MySQLConnectionTester:
    """MySQL连接测试器"""
    
    def __init__(self):
        self.connection = None
        self.test_results = []
    
    async def connect_to_mysql(self):
        """连接到MySQL数据库"""
        try:
            self.connection = mysql.connector.connect(
                host='localhost',
                port=3306,
                user='root',
                password='',  # 无密码
                database='jobfirst',
                charset='utf8mb4'
            )
            
            if self.connection.is_connected():
                print("✅ MySQL数据库连接成功")
                return True
            else:
                print("❌ MySQL数据库连接失败")
                return False
                
        except Error as e:
            print(f"❌ MySQL连接错误: {e}")
            return False
    
    async def test_user_creation(self, user_data: Dict[str, Any]) -> bool:
        """测试用户创建"""
        try:
            cursor = self.connection.cursor()
            
            # 检查用户是否已存在
            cursor.execute("SELECT id FROM users WHERE username = %s", (user_data['username'],))
            existing_user = cursor.fetchone()
            
            if existing_user:
                print(f"⚠️ 用户 {user_data['username']} 已存在，ID: {existing_user[0]}")
                return True
            
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
            
            self.connection.commit()
            user_id = cursor.lastrowid
            
            print(f"✅ 用户创建成功: {user_data['username']}, ID: {user_id}")
            
            # 记录测试结果
            self.test_results.append({
                "test_type": "user_creation",
                "user_id": user_id,
                "username": user_data['username'],
                "success": True,
                "timestamp": datetime.now().isoformat()
            })
            
            cursor.close()
            return True
            
        except Error as e:
            print(f"❌ 用户创建失败: {e}")
            self.test_results.append({
                "test_type": "user_creation",
                "username": user_data['username'],
                "success": False,
                "error": str(e),
                "timestamp": datetime.now().isoformat()
            })
            return False
    
    async def test_user_retrieval(self, username: str) -> Dict[str, Any]:
        """测试用户检索"""
        try:
            cursor = self.connection.cursor(dictionary=True)
            
            cursor.execute("SELECT * FROM users WHERE username = %s", (username,))
            user = cursor.fetchone()
            
            if user:
                print(f"✅ 用户检索成功: {username}")
                self.test_results.append({
                    "test_type": "user_retrieval",
                    "username": username,
                    "success": True,
                    "user_data": user,
                    "timestamp": datetime.now().isoformat()
                })
                return user
            else:
                print(f"❌ 用户不存在: {username}")
                return {}
                
        except Error as e:
            print(f"❌ 用户检索失败: {e}")
            return {}
        finally:
            cursor.close()
    
    async def test_user_update(self, username: str, update_data: Dict[str, Any]) -> bool:
        """测试用户更新"""
        try:
            cursor = self.connection.cursor()
            
            update_query = "UPDATE users SET updated_at = NOW()"
            params = []
            
            for key, value in update_data.items():
                if key in ['email', 'role', 'status']:
                    update_query += f", {key} = %s"
                    params.append(value)
            
            update_query += " WHERE username = %s"
            params.append(username)
            
            cursor.execute(update_query, params)
            self.connection.commit()
            
            if cursor.rowcount > 0:
                print(f"✅ 用户更新成功: {username}")
                self.test_results.append({
                    "test_type": "user_update",
                    "username": username,
                    "success": True,
                    "update_data": update_data,
                    "timestamp": datetime.now().isoformat()
                })
                return True
            else:
                print(f"❌ 用户更新失败: {username}")
                return False
                
        except Error as e:
            print(f"❌ 用户更新失败: {e}")
            return False
        finally:
            cursor.close()
    
    async def generate_test_report(self):
        """生成测试报告"""
        report = {
            "test_time": datetime.now().isoformat(),
            "total_tests": len(self.test_results),
            "successful_tests": len([r for r in self.test_results if r.get("success", False)]),
            "failed_tests": len([r for r in self.test_results if not r.get("success", True)]),
            "test_results": self.test_results
        }
        
        with open("docs/mysql_connection_test_report.json", "w", encoding="utf-8") as f:
            json.dump(report, f, indent=2, ensure_ascii=False)
        
        return report
    
    async def cleanup(self):
        """清理连接"""
        if self.connection and self.connection.is_connected():
            self.connection.close()
            print("✅ MySQL连接已关闭")

async def main():
    """主函数"""
    print("🚀 开始MySQL连接测试...")
    
    tester = MySQLConnectionTester()
    
    try:
        # 连接数据库
        if not await tester.connect_to_mysql():
            return
        
        # 测试用户数据
        test_user = {
            "username": "mysql_test_user",
            "email": "mysql_test@example.com",
            "password": "test123456",
            "role": "guest",
            "status": "active"
        }
        
        # 测试用户创建
        await tester.test_user_creation(test_user)
        
        # 测试用户检索
        await tester.test_user_retrieval(test_user["username"])
        
        # 测试用户更新
        await tester.test_user_update(test_user["username"], {
            "email": "mysql_test_updated@example.com",
            "status": "inactive"
        })
        
        # 生成测试报告
        report = await tester.generate_test_report()
        
        print("\n🎉 MySQL连接测试完成！")
        print(f"总测试数: {report['total_tests']}")
        print(f"成功测试: {report['successful_tests']}")
        print(f"失败测试: {report['failed_tests']}")
        print(f"测试报告已保存到: docs/mysql_connection_test_report.json")
        
    except Exception as e:
        print(f"❌ 测试失败: {e}")
    finally:
        await tester.cleanup()

if __name__ == "__main__":
    asyncio.run(main())
