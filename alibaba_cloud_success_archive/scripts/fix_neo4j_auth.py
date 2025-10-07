#!/usr/bin/env python3
"""
Neo4j认证修复脚本
"""

import sys
from neo4j import GraphDatabase

def test_neo4j_passwords():
    """测试不同的Neo4j密码"""
    print("=" * 60)
    print("🔐 Neo4j认证修复工具")
    print("=" * 60)
    
    # Neo4j配置
    host = "localhost"
    bolt_port = 7687
    user = "neo4j"
    
    # 可能的密码列表
    possible_passwords = [
        "neo4j",           # 默认密码
        "password",         # 常见密码
        "looma_password",   # 项目密码
        "admin",           # 管理员密码
        "123456",          # 简单密码
        "",                # 空密码
    ]
    
    print(f"测试Neo4j连接: bolt://{host}:{bolt_port}")
    print(f"用户: {user}")
    print("尝试不同的密码...")
    print()
    
    for password in possible_passwords:
        try:
            print(f"尝试密码: '{password}'" if password else "尝试空密码")
            
            driver = GraphDatabase.driver(
                f"bolt://{host}:{bolt_port}",
                auth=(user, password)
            )
            
            with driver.session() as session:
                result = session.run("RETURN 1 as test")
                record = result.single()
                if record and record["test"] == 1:
                    print(f"✅ 成功！当前密码是: '{password}'")
                    driver.close()
                    return password
                    
            driver.close()
            print(f"❌ 密码 '{password}' 不正确")
            
        except Exception as e:
            print(f"❌ 密码 '{password}' 失败: {str(e)[:50]}...")
            continue
    
    print("\n❌ 所有密码都失败了")
    return None

def reset_neo4j_password(current_password, new_password="looma_password"):
    """重置Neo4j密码"""
    print(f"\n正在将密码从 '{current_password}' 重置为 '{new_password}'...")
    
    host = "localhost"
    bolt_port = 7687
    user = "neo4j"
    
    try:
        driver = GraphDatabase.driver(
            f"bolt://{host}:{bolt_port}",
            auth=(user, current_password)
        )
        
        # 修改密码 - 连接到系统数据库
        with driver.session(database="system") as session:
            print("正在修改密码...")
            session.run(f"ALTER CURRENT USER SET PASSWORD FROM '{current_password}' TO '{new_password}'")
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

def test_neo4j_node_creation(password):
    """测试Neo4j节点创建功能"""
    print(f"\n测试Neo4j节点创建功能...")
    
    host = "localhost"
    bolt_port = 7687
    user = "neo4j"
    
    try:
        driver = GraphDatabase.driver(
            f"bolt://{host}:{bolt_port}",
            auth=(user, password)
        )
        
        with driver.session() as session:
            # 创建测试节点
            print("创建测试节点...")
            result = session.run("CREATE (n:TestNode {name: 'consistency_test'}) RETURN n")
            record = result.single()
            
            if record:
                print("✅ 节点创建成功")
                
                # 查询节点
                print("查询测试节点...")
                query_result = session.run("MATCH (n:TestNode) WHERE n.name = 'consistency_test' RETURN n")
                query_record = query_result.single()
                
                if query_record:
                    print("✅ 节点查询成功")
                    
                    # 删除测试节点
                    print("清理测试节点...")
                    session.run("MATCH (n:TestNode) WHERE n.name = 'consistency_test' DELETE n")
                    print("✅ 节点清理完成")
                    
                    driver.close()
                    return True
                else:
                    print("❌ 节点查询失败")
            else:
                print("❌ 节点创建失败")
        
        driver.close()
        return False
                
    except Exception as e:
        print(f"❌ 节点创建测试失败: {e}")
        return False

def main():
    """主函数"""
    # 1. 测试当前密码
    current_password = test_neo4j_passwords()
    
    if not current_password:
        print("\n❌ 无法找到正确的Neo4j密码")
        sys.exit(1)
    
    # 2. 重置密码为标准密码
    if current_password != "looma_password":
        success = reset_neo4j_password(current_password, "looma_password")
        if not success:
            print("\n❌ 密码重置失败")
            sys.exit(1)
        password_to_use = "looma_password"
    else:
        print("\n✅ 密码已经是标准密码")
        password_to_use = current_password
    
    # 3. 测试节点创建功能
    node_creation_success = test_neo4j_node_creation(password_to_use)
    
    if node_creation_success:
        print("\n🎉 Neo4j认证修复完成！")
        print("Neo4j节点创建功能正常，可以重新运行数据一致性测试。")
    else:
        print("\n⚠️ Neo4j认证修复完成，但节点创建功能仍有问题")
        print("建议检查Neo4j配置和权限设置。")

if __name__ == "__main__":
    main()
