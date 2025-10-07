#!/usr/bin/env python3
"""
更新zervitest用户信息脚本
完善用户认证所需的字段信息
"""

import mysql.connector
from mysql.connector import Error
import json
from datetime import datetime

class ZervitestUserUpdater:
    """zervitest用户信息更新器"""
    
    def __init__(self):
        self.connection = None
    
    def connect_to_mysql(self):
        """连接到MySQL数据库"""
        try:
            self.connection = mysql.connector.connect(
                host='localhost',
                port=3306,
                user='root',
                password='',
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
    
    def update_zervitest_user(self):
        """更新zervitest用户信息"""
        try:
            cursor = self.connection.cursor()
            
            # 检查用户是否存在
            cursor.execute("SELECT id FROM users WHERE username = 'zervitest'")
            user = cursor.fetchone()
            
            if not user:
                print("❌ zervitest用户不存在")
                return False
            
            user_id = user[0]
            print(f"✅ 找到zervitest用户，ID: {user_id}")
            
            # 更新用户信息
            update_query = """
            UPDATE users SET 
                phone = %s,
                phone_verified = %s,
                email_verified = %s,
                first_name = %s,
                last_name = %s,
                updated_at = NOW()
            WHERE username = 'zervitest'
            """
            
            update_data = (
                '+12345678999',  # phone
                1,               # phone_verified
                1,               # email_verified
                'Zervi',         # first_name
                'Test'           # last_name
            )
            
            cursor.execute(update_query, update_data)
            self.connection.commit()
            
            if cursor.rowcount > 0:
                print("✅ zervitest用户信息更新成功")
                
                # 验证更新结果
                cursor.execute("""
                    SELECT id, username, email, phone, phone_verified, email_verified, 
                           role, status, first_name, last_name, created_at, updated_at 
                    FROM users WHERE username = 'zervitest'
                """)
                
                user_data = cursor.fetchone()
                if user_data:
                    print("\n📋 更新后的用户信息:")
                    print(f"  ID: {user_data[0]}")
                    print(f"  用户名: {user_data[1]}")
                    print(f"  邮箱: {user_data[2]}")
                    print(f"  手机: {user_data[3]}")
                    print(f"  手机验证: {'是' if user_data[4] else '否'}")
                    print(f"  邮箱验证: {'是' if user_data[5] else '否'}")
                    print(f"  角色: {user_data[6]}")
                    print(f"  状态: {user_data[7]}")
                    print(f"  名字: {user_data[8]}")
                    print(f"  姓氏: {user_data[9]}")
                    print(f"  创建时间: {user_data[10]}")
                    print(f"  更新时间: {user_data[11]}")
                
                cursor.close()
                return True
            else:
                print("❌ 用户信息更新失败")
                cursor.close()
                return False
                
        except Error as e:
            print(f"❌ 更新用户信息失败: {e}")
            return False
    
    def test_authentication_parameters(self):
        """测试认证服务参数"""
        try:
            cursor = self.connection.cursor(dictionary=True)
            
            # 获取完整的用户信息
            cursor.execute("""
                SELECT * FROM users WHERE username = 'zervitest'
            """)
            
            user_data = cursor.fetchone()
            if user_data:
                print("\n🔐 认证服务参数分析:")
                
                # 分析认证所需的关键字段
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
                
                print("  认证参数:")
                for key, value in auth_params.items():
                    print(f"    {key}: {value}")
                
                # 检查认证完整性
                print("\n  📊 认证完整性检查:")
                checks = [
                    ("用户名", bool(user_data['username'])),
                    ("邮箱", bool(user_data['email'])),
                    ("手机号", bool(user_data['phone'])),
                    ("角色", bool(user_data['role'])),
                    ("状态", user_data['status'] == 'active'),
                    ("邮箱验证", bool(user_data['email_verified'])),
                    ("手机验证", bool(user_data['phone_verified'])),
                    ("姓名", bool(user_data['first_name'] and user_data['last_name']))
                ]
                
                for check_name, check_result in checks:
                    status = "✅" if check_result else "❌"
                    print(f"    {status} {check_name}: {'通过' if check_result else '缺失'}")
                
                # 计算完整性得分
                passed_checks = sum(1 for _, result in checks if result)
                total_checks = len(checks)
                completeness_score = (passed_checks / total_checks) * 100
                
                print(f"\n  🎯 认证完整性得分: {completeness_score:.1f}% ({passed_checks}/{total_checks})")
                
                if completeness_score >= 90:
                    print("  🎉 认证参数完整，适合认证服务使用")
                elif completeness_score >= 70:
                    print("  ⚠️ 认证参数基本完整，建议补充缺失字段")
                else:
                    print("  ❌ 认证参数不完整，需要补充关键字段")
                
                cursor.close()
                return auth_params
            else:
                print("❌ 无法获取用户数据")
                cursor.close()
                return None
                
        except Error as e:
            print(f"❌ 测试认证参数失败: {e}")
            return None
    
    def generate_auth_test_report(self, auth_params):
        """生成认证测试报告"""
        if not auth_params:
            return
        
        report = {
            "test_time": datetime.now().isoformat(),
            "user_id": auth_params['user_id'],
            "username": auth_params['username'],
            "authentication_parameters": auth_params,
            "completeness_analysis": {
                "has_username": bool(auth_params['username']),
                "has_email": bool(auth_params['email']),
                "has_phone": bool(auth_params['phone']),
                "has_role": bool(auth_params['role']),
                "is_active": auth_params['status'] == 'active',
                "email_verified": auth_params['email_verified'],
                "phone_verified": auth_params['phone_verified'],
                "has_full_name": bool(auth_params['first_name'] and auth_params['last_name'])
            },
            "recommendations": []
        }
        
        # 添加建议
        if not auth_params['phone']:
            report["recommendations"].append("建议添加手机号码")
        if not auth_params['email_verified']:
            report["recommendations"].append("建议验证邮箱")
        if not auth_params['phone_verified']:
            report["recommendations"].append("建议验证手机号码")
        if not auth_params['first_name'] or not auth_params['last_name']:
            report["recommendations"].append("建议添加完整姓名")
        
        # 保存报告
        with open("docs/zervitest_auth_parameters_report.json", "w", encoding="utf-8") as f:
            json.dump(report, f, indent=2, ensure_ascii=False)
        
        print(f"\n📄 认证测试报告已保存到: docs/zervitest_auth_parameters_report.json")
        return report
    
    def cleanup(self):
        """清理连接"""
        if self.connection and self.connection.is_connected():
            self.connection.close()
            print("✅ MySQL连接已关闭")

def main():
    """主函数"""
    print("🚀 开始更新zervitest用户信息...")
    
    updater = ZervitestUserUpdater()
    
    try:
        # 连接数据库
        if not updater.connect_to_mysql():
            return
        
        # 更新用户信息
        if updater.update_zervitest_user():
            # 测试认证参数
            auth_params = updater.test_authentication_parameters()
            
            # 生成认证测试报告
            updater.generate_auth_test_report(auth_params)
            
            print("\n🎉 zervitest用户信息更新完成！")
        else:
            print("\n❌ 用户信息更新失败")
        
    except Exception as e:
        print(f"❌ 操作失败: {e}")
    finally:
        updater.cleanup()

if __name__ == "__main__":
    main()
