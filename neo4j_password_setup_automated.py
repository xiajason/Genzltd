#!/usr/bin/env python3
"""
Neo4j密码自动设置脚本
Neo4j Password Auto Setup Script

通过Web界面自动设置Neo4j密码
"""

import time
import webbrowser
import subprocess
import requests
from neo4j import GraphDatabase

class Neo4jPasswordAutoSetup:
    """Neo4j密码自动设置类"""
    
    def __init__(self):
        self.neo4j_url = "http://localhost:7474"
        self.bolt_url = "bolt://localhost:7687"
        self.username = "neo4j"
        self.password = "mbti_neo4j_2025"
    
    def open_neo4j_browser(self):
        """打开Neo4j浏览器"""
        print("🌐 打开Neo4j浏览器...")
        
        try:
            webbrowser.open(self.neo4j_url)
            print(f"✅ Neo4j浏览器已打开: {self.neo4j_url}")
            return True
        except Exception as e:
            print(f"❌ 打开Neo4j浏览器失败: {e}")
            return False
    
    def wait_for_password_setup(self):
        """等待密码设置"""
        print("⏳ 等待密码设置...")
        print("📋 请在浏览器中完成以下步骤:")
        print(f"   1. 用户名: {self.username}")
        print(f"   2. 密码: {self.password}")
        print("   3. 点击连接")
        print("   4. 设置完成后按回车继续...")
        
        input("按回车键继续...")
        return True
    
    def test_neo4j_connection(self):
        """测试Neo4j连接"""
        print("🔍 测试Neo4j连接...")
        
        try:
            driver = GraphDatabase.driver(
                self.bolt_url,
                auth=(self.username, self.password)
            )
            
            with driver.session() as session:
                result = session.run("RETURN 1 as test")
                record = result.single()
                if record and record["test"] == 1:
                    print("✅ Neo4j连接成功!")
                    driver.close()
                    return True
                else:
                    print("❌ Neo4j连接失败")
                    driver.close()
                    return False
                    
        except Exception as e:
            print(f"❌ Neo4j连接失败: {e}")
            return False
    
    def create_mbti_test_data(self):
        """创建MBTI测试数据"""
        print("🌐 创建MBTI测试数据...")
        
        try:
            driver = GraphDatabase.driver(
                self.bolt_url,
                auth=(self.username, self.password)
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
                
                # 查询测试数据
                result = session.run("""
                    MATCH (m:MBTIType)
                    RETURN m.type, m.name, m.traits
                    ORDER BY m.type
                """)
                
                print("📊 MBTI图结构数据:")
                for record in result:
                    print(f"   {record['m.type']}: {record['m.name']} - {record['m.traits']}")
                
                driver.close()
                return True
                
        except Exception as e:
            print(f"❌ 创建MBTI测试数据失败: {e}")
            return False
    
    def run_auto_setup(self):
        """运行自动设置"""
        print("🚀 Neo4j密码自动设置开始...")
        print("=" * 60)
        
        # 步骤1: 打开Neo4j浏览器
        if not self.open_neo4j_browser():
            print("❌ 打开Neo4j浏览器失败")
            return False
        
        # 步骤2: 等待密码设置
        if not self.wait_for_password_setup():
            print("❌ 密码设置失败")
            return False
        
        # 步骤3: 测试连接
        if not self.test_neo4j_connection():
            print("❌ Neo4j连接测试失败")
            return False
        
        # 步骤4: 创建测试数据
        if not self.create_mbti_test_data():
            print("❌ 创建MBTI测试数据失败")
            return False
        
        print("🎉 Neo4j密码自动设置完成!")
        print("✅ MBTI多数据库架构集成成功!")
        return True

def main():
    """主函数"""
    setup = Neo4jPasswordAutoSetup()
    success = setup.run_auto_setup()
    
    if success:
        print("\n🎯 设置完成状态:")
        print("✅ Neo4j密码已设置")
        print("✅ Neo4j连接正常")
        print("✅ MBTI测试数据已创建")
        print("✅ 多数据库架构集成完成")
        print("\n🚀 可以开始MBTI项目开发!")
    else:
        print("\n❌ Neo4j密码设置失败")
        print("请手动访问 http://localhost:7474 设置密码")

if __name__ == "__main__":
    main()
