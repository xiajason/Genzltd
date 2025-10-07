#!/usr/bin/env python3
"""
测试无认证Neo4j连接
"""

import sys
from neo4j import GraphDatabase

def test_neo4j_no_auth():
    """测试无认证Neo4j连接"""
    print("=" * 60)
    print("🔐 Neo4j无认证连接测试")
    print("=" * 60)
    
    # Neo4j配置
    host = "localhost"
    bolt_port = 7687
    
    try:
        print(f"连接到Neo4j: bolt://{host}:{bolt_port}")
        print("尝试无认证连接...")
        
        # 无认证连接
        driver = GraphDatabase.driver(
            f"bolt://{host}:{bolt_port}",
            auth=None  # 无认证
        )
        
        with driver.session() as session:
            # 测试基本查询
            result = session.run("RETURN 1 as test")
            record = result.single()
            if record and record["test"] == 1:
                print("✅ 无认证连接成功")
                
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
        print(f"❌ 无认证连接失败: {e}")
        return False

def main():
    """主函数"""
    success = test_neo4j_no_auth()
    
    if success:
        print("\n🎉 Neo4j无认证连接测试成功！")
        print("Neo4j节点创建功能正常，可以重新运行数据一致性测试。")
        return True
    else:
        print("\n❌ Neo4j无认证连接测试失败")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
