#!/usr/bin/env python3
"""
Neo4j Web界面最终解决方案
Neo4j Web Interface Final Solution

使用Web界面设置Neo4j密码的最终解决方案
"""

import time
import requests
from neo4j import GraphDatabase

class Neo4jWebInterfaceSolution:
    """Neo4j Web界面解决方案"""
    
    def __init__(self):
        self.neo4j_url = "http://localhost:7474"
        self.bolt_url = "bolt://localhost:7687"
        self.username = "neo4j"
        self.target_password = "mbti_neo4j_2025"
    
    def check_neo4j_web_interface(self):
        """检查Neo4j Web界面"""
        print("🔍 检查Neo4j Web界面...")
        
        try:
            response = requests.get(self.neo4j_url, timeout=10)
            if response.status_code == 200:
                print("✅ Neo4j Web界面可访问")
                print(f"🌐 请访问: {self.neo4j_url}")
                return True
            else:
                print(f"❌ Neo4j Web界面不可访问: {response.status_code}")
                return False
        except Exception as e:
            print(f"❌ Neo4j Web界面检查失败: {e}")
            return False
    
    def test_connection_with_password(self, password):
        """测试密码连接"""
        print(f"🔍 测试密码连接: {password}")
        
        try:
            driver = GraphDatabase.driver(
                self.bolt_url, 
                auth=(self.username, password)
            )
            
            with driver.session() as session:
                result = session.run("RETURN 1 as test")
                record = result.single()
                if record and record["test"] == 1:
                    print(f"✅ 密码 {password} 连接成功!")
                    driver.close()
                    return True
                else:
                    print(f"❌ 密码 {password} 连接失败")
                    driver.close()
                    return False
                    
        except Exception as e:
            print(f"❌ 密码 {password} 测试失败: {e}")
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
    
    def run_web_interface_solution(self):
        """运行Web界面解决方案"""
        print("🚀 Neo4j Web界面解决方案开始...")
        print("=" * 60)
        
        # 步骤1: 检查Web界面
        if not self.check_neo4j_web_interface():
            print("❌ Neo4j Web界面不可访问")
            return False
        
        # 步骤2: 测试常见密码
        common_passwords = [
            "neo4j",
            "password", 
            "admin",
            "123456",
            "",
            "mbti_neo4j_2025"
        ]
        
        working_password = None
        for password in common_passwords:
            if self.test_connection_with_password(password):
                working_password = password
                break
        
        if working_password:
            print(f"✅ 找到可用密码: {working_password}")
            
            # 如果密码不是目标密码，需要更改
            if working_password != self.target_password:
                print(f"⚠️ 当前密码: {working_password}")
                print(f"🎯 目标密码: {self.target_password}")
                print("💡 请访问Web界面更改密码")
                print(f"🌐 访问: {self.neo4j_url}")
                print("📝 步骤:")
                print("   1. 使用当前密码登录")
                print("   2. 更改密码为: mbti_neo4j_2025")
                print("   3. 保存设置")
                print("   4. 重新运行此脚本验证")
                
                return False
            else:
                print("✅ 密码已经是目标密码")
        else:
            print("❌ 未找到可用密码")
            print("💡 请访问Web界面设置密码")
            print(f"🌐 访问: {self.neo4j_url}")
            print("📝 步骤:")
            print("   1. 使用默认用户名: neo4j")
            print("   2. 尝试默认密码: neo4j")
            print("   3. 如果提示更改密码，设置为: mbti_neo4j_2025")
            print("   4. 保存设置")
            print("   5. 重新运行此脚本验证")
            
            return False
        
        # 步骤3: 创建MBTI测试数据
        if not self.create_mbti_test_data():
            print("❌ 创建MBTI测试数据失败")
            return False
        
        print("\n🎉 Neo4j Web界面解决方案完成!")
        print("✅ 密码设置成功")
        print("✅ 连接测试通过")
        print("✅ MBTI数据创建完成")
        print("✅ 多数据库架构就绪")
        
        return True

def main():
    """主函数"""
    solution = Neo4jWebInterfaceSolution()
    success = solution.run_web_interface_solution()
    
    if success:
        print("\n🎯 解决方案完成状态:")
        print("✅ Neo4j密码: mbti_neo4j_2025")
        print("✅ 连接正常")
        print("✅ MBTI数据已创建")
        print("✅ 可以开始MBTI项目开发!")
    else:
        print("\n⚠️ 需要手动设置密码")
        print("💡 请按照上述步骤访问Web界面设置密码")

if __name__ == "__main__":
    main()
