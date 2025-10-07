#!/usr/bin/env python3
"""
使用正确密码测试Neo4j连接
"""

import sys
from neo4j import GraphDatabase

def test_neo4j_correct_password():
    """使用正确密码测试Neo4j连接"""
    print("=" * 60)
    print("🔐 Neo4j正确密码连接测试")
    print("=" * 60)
    
    # Neo4j配置 - 根据文档记录的密码
    host = "localhost"
    bolt_port = 7687
    user = "neo4j"
    password = "jobfirst_password_2024"  # 从配置文件找到的正确密码
    
    try:
        print(f"连接到Neo4j: bolt://{host}:{bolt_port}")
        print(f"用户: {user}")
        print(f"密码: {password}")
        print()
        
        # 连接到Neo4j
        driver = GraphDatabase.driver(
            f"bolt://{host}:{bolt_port}",
            auth=(user, password)
        )
        
        with driver.session() as session:
            # 测试基本查询
            result = session.run("RETURN 1 as test")
            record = result.single()
            if record and record["test"] == 1:
                print("✅ 密码连接成功")
                
                # 测试节点创建
                print("测试节点创建...")
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
                        return True
                    else:
                        print("❌ 节点查询失败")
                else:
                    print("❌ 节点创建失败")
            else:
                print("❌ 基本查询失败")
        
        driver.close()
        return False
                
    except Exception as e:
        print(f"❌ 连接失败: {e}")
        return False

def main():
    """主函数"""
    success = test_neo4j_correct_password()
    
    if success:
        print("\n🎉 Neo4j连接测试成功！")
        print("找到了正确的密码: jobfirst_password_2024")
        print("现在可以重新运行数据一致性测试。")
        return True
    else:
        print("\n❌ Neo4j连接测试失败")
        print("密码可能不正确或Neo4j配置有问题。")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
