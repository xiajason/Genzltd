#!/usr/bin/env python3
"""
测试所有可能的Neo4j密码
"""

import sys
from neo4j import GraphDatabase

def test_neo4j_passwords():
    """测试所有可能的Neo4j密码"""
    print("=" * 60)
    print("🔐 Neo4j密码测试工具")
    print("=" * 60)
    
    # Neo4j配置
    host = "localhost"
    bolt_port = 7687
    user = "neo4j"
    
    # 从文档中找到的所有可能密码
    possible_passwords = [
        "jobfirst_password_2024",      # 从zervigo_future配置
        "future_neo4j_password_2025",  # 从DATABASE_CONNECTION_INFO.md
        "looma_password",              # 从DATABASE_AUTHENTICATION_COMPLETION_REPORT.md
        "neo4j",                       # 默认密码
        "password",                    # 常见密码
        "looma_password_2025",         # 从UNIFIED_LOOMACRM_LOCAL_DEVELOPMENT_ARCHITECTURE.md
        "dao_password_2024",           # 从deploy-dao-tencent.sh
    ]
    
    print(f"测试Neo4j连接: bolt://{host}:{bolt_port}")
    print(f"用户: {user}")
    print("测试所有可能的密码...")
    print()
    
    for password in possible_passwords:
        try:
            print(f"尝试密码: '{password}'")
            
            driver = GraphDatabase.driver(
                f"bolt://{host}:{bolt_port}",
                auth=(user, password)
            )
            
            with driver.session() as session:
                result = session.run("RETURN 1 as test")
                record = result.single()
                if record and record["test"] == 1:
                    print(f"✅ 成功！密码是: '{password}'")
                    
                    # 测试节点创建功能
                    print("测试节点创建功能...")
                    create_result = session.run("CREATE (n:TestNode {name: 'consistency_test'}) RETURN n")
                    create_record = create_result.single()
                    
                    if create_record:
                        print("✅ 节点创建成功")
                        
                        # 查询节点
                        query_result = session.run("MATCH (n:TestNode) WHERE n.name = 'consistency_test' RETURN n")
                        query_record = query_result.single()
                        
                        if query_record:
                            print("✅ 节点查询成功")
                            
                            # 删除测试节点
                            session.run("MATCH (n:TestNode) WHERE n.name = 'consistency_test' DELETE n")
                            print("✅ 节点清理完成")
                            
                            driver.close()
                            return password
                        else:
                            print("❌ 节点查询失败")
                    else:
                        print("❌ 节点创建失败")
                    
                    driver.close()
                    return password
                    
            driver.close()
            print(f"❌ 密码 '{password}' 不正确")
            
        except Exception as e:
            print(f"❌ 密码 '{password}' 失败: {str(e)[:50]}...")
            continue
    
    print("\n❌ 所有密码都失败了")
    return None

def main():
    """主函数"""
    correct_password = test_neo4j_passwords()
    
    if correct_password:
        print(f"\n🎉 找到正确的Neo4j密码: {correct_password}")
        print("现在可以重新运行数据一致性测试。")
        return True
    else:
        print("\n❌ 所有密码都失败了")
        print("Neo4j可能没有运行或者配置有问题。")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
