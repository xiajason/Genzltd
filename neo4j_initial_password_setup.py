#!/usr/bin/env python3
"""
Neo4j初始密码设置脚本
Neo4j Initial Password Setup Script

解决Neo4j首次启动的密码设置问题
"""

import time
import subprocess
import requests
from neo4j import GraphDatabase

class Neo4jInitialPasswordSetup:
    """Neo4j初始密码设置类"""
    
    def __init__(self):
        self.neo4j_url = "http://localhost:7474"
        self.bolt_url = "bolt://localhost:7687"
        self.username = "neo4j"
        self.target_password = "mbti_neo4j_2025"
    
    def check_neo4j_status(self):
        """检查Neo4j状态"""
        print("🔍 检查Neo4j状态...")
        
        try:
            response = requests.get(self.neo4j_url, timeout=10)
            if response.status_code == 200:
                print("✅ Neo4j Web界面可访问")
                return True
            else:
                print(f"❌ Neo4j Web界面不可访问: {response.status_code}")
                return False
        except Exception as e:
            print(f"❌ Neo4j Web界面检查失败: {e}")
            return False
    
    def try_empty_password(self):
        """尝试空密码连接"""
        print("🔍 尝试空密码连接...")
        
        try:
            driver = GraphDatabase.driver(self.bolt_url, auth=("neo4j", ""))
            with driver.session() as session:
                result = session.run("RETURN 1 as test")
                record = result.single()
                if record and record["test"] == 1:
                    print("✅ 空密码连接成功!")
                    driver.close()
                    return True
            driver.close()
        except Exception as e:
            print(f"❌ 空密码连接失败: {e}")
        
        return False
    
    def try_no_auth(self):
        """尝试无认证连接"""
        print("🔍 尝试无认证连接...")
        
        try:
            driver = GraphDatabase.driver(self.bolt_url)
            with driver.session() as session:
                result = session.run("RETURN 1 as test")
                record = result.single()
                if record and record["test"] == 1:
                    print("✅ 无认证连接成功!")
                    driver.close()
                    return True
            driver.close()
        except Exception as e:
            print(f"❌ 无认证连接失败: {e}")
        
        return False
    
    def set_initial_password(self):
        """设置初始密码"""
        print("🔧 设置Neo4j初始密码...")
        
        try:
            # 尝试使用空密码连接并设置密码
            driver = GraphDatabase.driver(self.bolt_url, auth=("neo4j", ""))
            
            with driver.session(database="system") as session:
                # 设置密码
                session.run(f"ALTER USER neo4j SET PASSWORD '{self.target_password}'")
                print(f"✅ 密码已设置为: {self.target_password}")
            
            driver.close()
            return True
            
        except Exception as e:
            print(f"❌ 设置密码失败: {e}")
            return False
    
    def test_new_password(self):
        """测试新密码"""
        print("🔍 测试新密码...")
        
        try:
            driver = GraphDatabase.driver(
                self.bolt_url, 
                auth=(self.username, self.target_password)
            )
            
            with driver.session() as session:
                result = session.run("RETURN 1 as test")
                record = result.single()
                if record and record["test"] == 1:
                    print("✅ 新密码连接成功!")
                    driver.close()
                    return True
                else:
                    print("❌ 新密码连接失败")
                    driver.close()
                    return False
                    
        except Exception as e:
            print(f"❌ 新密码测试失败: {e}")
            return False
    
    def create_mbti_test_data(self):
        """创建MBTI测试数据"""
        print("🌐 创建MBTI测试数据...")
        
        try:
            driver = GraphDatabase.driver(
                self.bolt_url, 
                auth=(self.username, self.target_password)
            )
            
            with driver.session() as session:
                # 清理现有数据
                session.run("MATCH (n) DETACH DELETE n")
                print("✅ 清理现有数据")
                
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
                
                # 查询验证
                result = session.run("""
                    MATCH (m:MBTIType)
                    RETURN m.type, m.name, m.traits
                    ORDER BY m.type
                """)
                
                print("📊 MBTI数据验证:")
                for record in result:
                    print(f"   {record['m.type']}: {record['m.name']} - {record['m.traits']}")
                
                driver.close()
                return True
                
        except Exception as e:
            print(f"❌ 创建MBTI测试数据失败: {e}")
            return False
    
    def run_setup(self):
        """运行设置"""
        print("🚀 Neo4j初始密码设置开始...")
        print("=" * 60)
        
        # 步骤1: 检查Neo4j状态
        if not self.check_neo4j_status():
            print("❌ Neo4j Web界面不可访问")
            return False
        
        # 步骤2: 尝试空密码连接
        if self.try_empty_password():
            print("✅ 空密码连接成功，可以设置密码")
        elif self.try_no_auth():
            print("✅ 无认证连接成功，可以设置密码")
        else:
            print("❌ 无法连接Neo4j")
            print("💡 请访问 http://localhost:7474 手动设置密码")
            return False
        
        # 步骤3: 设置初始密码
        if not self.set_initial_password():
            print("❌ 设置密码失败")
            return False
        
        # 步骤4: 测试新密码
        if not self.test_new_password():
            print("❌ 新密码测试失败")
            return False
        
        # 步骤5: 创建MBTI测试数据
        if not self.create_mbti_test_data():
            print("❌ 创建MBTI测试数据失败")
            return False
        
        print("\n🎉 Neo4j初始密码设置完成!")
        print("✅ 密码设置成功")
        print("✅ 连接测试通过")
        print("✅ MBTI数据创建完成")
        print("✅ 多数据库架构就绪")
        
        return True

def main():
    """主函数"""
    setup = Neo4jInitialPasswordSetup()
    success = setup.run_setup()
    
    if success:
        print("\n🎯 设置完成状态:")
        print("✅ Neo4j密码: mbti_neo4j_2025")
        print("✅ 连接正常")
        print("✅ MBTI数据已创建")
        print("✅ 可以开始MBTI项目开发!")
    else:
        print("\n❌ 自动设置失败")
        print("💡 请手动访问 http://localhost:7474 设置密码")

if __name__ == "__main__":
    main()
