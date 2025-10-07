#!/usr/bin/env python3
"""
Neo4j简单连接测试
Neo4j Simple Connection Test

测试Neo4j连接并创建MBTI数据
"""

from neo4j import GraphDatabase
import time

def test_neo4j_connection():
    """测试Neo4j连接"""
    print("🔍 测试Neo4j连接...")
    
    # 尝试不同的密码
    passwords = ["mbti_neo4j_2025", "neo4j", "password", ""]
    
    for password in passwords:
        try:
            print(f"尝试密码: {password if password else '(空密码)'}")
            
            driver = GraphDatabase.driver(
                "bolt://localhost:7687",
                auth=("neo4j", password)
            )
            
            with driver.session() as session:
                result = session.run("RETURN 1 as test")
                record = result.single()
                if record and record["test"] == 1:
                    print(f"✅ Neo4j连接成功! 密码: {password if password else '(空密码)'}")
                    driver.close()
                    return True
            
            driver.close()
            
        except Exception as e:
            print(f"❌ 密码 {password if password else '(空密码)'} 失败: {e}")
            continue
    
    print("❌ 所有密码都失败了")
    print("💡 请访问 http://localhost:7474 设置密码")
    return False

def create_mbti_data():
    """创建MBTI数据"""
    print("🌐 创建MBTI数据...")
    
    try:
        driver = GraphDatabase.driver(
            "bolt://localhost:7687",
            auth=("neo4j", "mbti_neo4j_2025")
        )
        
        with driver.session() as session:
            # 创建MBTI类型节点
            mbti_types = [
                {"type": "INTJ", "name": "建筑师", "traits": ["独立", "理性", "创新"]},
                {"type": "ENFP", "name": "竞选者", "traits": ["热情", "创意", "社交"]},
                {"type": "ISFJ", "name": "守护者", "traits": ["忠诚", "负责", "细心"]},
                {"type": "ESTP", "name": "企业家", "traits": ["行动", "实用", "灵活"]}
            ]
            
            for mbti in mbti_types:
                session.run("""
                    CREATE (m:MBTIType {
                        type: $type,
                        name: $name,
                        traits: $traits,
                        created_at: datetime()
                    })
                """, type=mbti["type"], name=mbti["name"], traits=mbti["traits"])
            
            print("✅ MBTI类型节点创建完成")
            
            # 创建兼容性关系
            compatibility = [
                ("INTJ", "ENFP", 85),
                ("ISFJ", "ESTP", 78),
                ("INTJ", "ISFJ", 65)
            ]
            
            for type1, type2, score in compatibility:
                session.run("""
                    MATCH (m1:MBTIType {type: $type1})
                    MATCH (m2:MBTIType {type: $type2})
                    CREATE (m1)-[r:COMPATIBLE_WITH {
                        score: $score,
                        created_at: datetime()
                    }]->(m2)
                """, type1=type1, type2=type2, score=score)
            
            print("✅ 兼容性关系创建完成")
            
            # 查询数据
            result = session.run("""
                MATCH (m:MBTIType)
                RETURN m.type, m.name, m.traits
                ORDER BY m.type
            """)
            
            print("📊 MBTI数据:")
            for record in result:
                print(f"   {record['m.type']}: {record['m.name']} - {record['m.traits']}")
            
            driver.close()
            return True
            
    except Exception as e:
        print(f"❌ 创建MBTI数据失败: {e}")
        return False

def main():
    """主函数"""
    print("🚀 Neo4j简单连接测试开始...")
    print("=" * 60)
    
    # 测试连接
    if test_neo4j_connection():
        print("\n🎉 Neo4j连接成功!")
        
        # 创建MBTI数据
        if create_mbti_data():
            print("\n✅ MBTI数据创建成功!")
            print("🎯 Neo4j集成完成!")
        else:
            print("\n❌ MBTI数据创建失败")
    else:
        print("\n⚠️ Neo4j连接失败")
        print("请访问 http://localhost:7474 设置密码")

if __name__ == "__main__":
    main()
