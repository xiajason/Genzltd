#!/usr/bin/env python3
"""
Neo4j密码重置脚本
Neo4j Password Reset Script

用于重置Neo4j的默认密码
"""

import sys
import time
from neo4j import GraphDatabase

def reset_neo4j_password():
    """重置Neo4j密码"""
    print("=" * 60)
    print("🔐 Neo4j密码重置工具")
    print("=" * 60)
    
    # Neo4j配置
    host = "localhost"
    bolt_port = 7687  # 修正端口号
    user = "neo4j"
    old_password = "neo4j"  # 默认密码
    new_password = "looma_password"  # 新密码
    
    try:
        print(f"连接到Neo4j: bolt://{host}:{bolt_port}")
        print(f"用户: {user}")
        print(f"当前密码: {old_password}")
        print(f"新密码: {new_password}")
        print()
        
        # 连接到Neo4j
        driver = GraphDatabase.driver(
            f"bolt://{host}:{bolt_port}",
            auth=(user, old_password)
        )
        
        print("✅ 成功连接到Neo4j")
        
        # 修改密码 - 连接到系统数据库
        with driver.session(database="system") as session:
            print("正在修改密码...")
            session.run(f"ALTER CURRENT USER SET PASSWORD FROM '{old_password}' TO '{new_password}'")
            print("✅ 密码修改成功")
        
        driver.close()
        
        # 测试新密码
        print("测试新密码...")
        test_driver = GraphDatabase.driver(
            f"bolt://{host}:{bolt_port}",
            auth=(user, new_password)
        )
        
        with test_driver.session() as session:
            result = session.run("RETURN 1 as test")
            record = result.single()
            if record and record["test"] == 1:
                print("✅ 新密码验证成功")
                test_driver.close()
                return True
            else:
                print("❌ 新密码验证失败")
                test_driver.close()
                return False
                
    except Exception as e:
        print(f"❌ 密码重置失败: {e}")
        return False

def main():
    """主函数"""
    success = reset_neo4j_password()
    
    if success:
        print("\n🎉 Neo4j密码重置完成！")
        print("现在可以重新运行数据库认证配置脚本。")
    else:
        print("\n❌ Neo4j密码重置失败！")
        print("请检查Neo4j服务状态和配置。")
        sys.exit(1)

if __name__ == "__main__":
    main()
