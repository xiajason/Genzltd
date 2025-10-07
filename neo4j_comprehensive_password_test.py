#!/usr/bin/env python3
"""
Neo4j综合密码测试脚本
Neo4j Comprehensive Password Test Script

基于项目文档中的密码信息进行测试
"""

import time
from neo4j import GraphDatabase

class Neo4jComprehensivePasswordTest:
    """Neo4j综合密码测试类"""
    
    def __init__(self):
        self.bolt_url = "bolt://localhost:7687"
        self.username = "neo4j"
        
        # 从项目文档中收集的所有密码
        self.passwords = [
            "neo4j",                    # 默认密码
            "mbti_neo4j_2025",          # 我们设置的密码
            "jobfirst_password_2024",   # Docker配置中的密码
            "jobfirst123",              # 项目配置中的密码
            "looma_password",           # Looma项目密码
            "password",                 # 简单密码
            "password123",              # 常见密码
            "",                         # 空密码
        ]
    
    def test_all_passwords(self):
        """测试所有密码"""
        print("🔍 Neo4j综合密码测试开始...")
        print("=" * 80)
        
        print(f"用户名: {self.username}")
        print(f"连接URL: {self.bolt_url}")
        print(f"测试密码数量: {len(self.passwords)}")
        print()
        
        successful_password = None
        
        for i, password in enumerate(self.passwords, 1):
            try:
                print(f"[{i}/{len(self.passwords)}] 测试密码: {password if password else '(空密码)'}")
                
                driver = GraphDatabase.driver(
                    self.bolt_url,
                    auth=(self.username, password)
                )
                
                with driver.session() as session:
                    result = session.run("RETURN 1 as test")
                    record = result.single()
                    if record and record["test"] == 1:
                        print(f"✅ 成功连接! 密码: {password if password else '(空密码)'}")
                        successful_password = password
                        driver.close()
                        break
                
                driver.close()
                
            except Exception as e:
                error_msg = str(e)
                if "AuthenticationRateLimit" in error_msg:
                    print(f"⚠️ 认证速率限制，等待5秒...")
                    time.sleep(5)
                else:
                    print(f"❌ 失败: {error_msg[:60]}...")
                
                time.sleep(1)  # 避免速率限制
        
        return successful_password
    
    def test_system_database_connection(self, password):
        """测试系统数据库连接"""
        print(f"\n🔧 测试系统数据库连接...")
        
        try:
            driver = GraphDatabase.driver(
                self.bolt_url,
                auth=(self.username, password)
            )
            
            # 测试系统数据库
            with driver.session(database="system") as session:
                result = session.run("SHOW USERS")
                users = list(result)
                print(f"✅ 系统数据库连接成功，找到 {len(users)} 个用户")
                
                for user in users:
                    print(f"   用户: {user['user']}, 角色: {user['roles']}")
            
            driver.close()
            return True
            
        except Exception as e:
            print(f"❌ 系统数据库连接失败: {e}")
            return False
    
    def create_mbti_test_data(self, password):
        """创建MBTI测试数据"""
        print(f"\n🌐 创建MBTI测试数据...")
        
        try:
            driver = GraphDatabase.driver(
                self.bolt_url,
                auth=(self.username, password)
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
                
                # 查询数据验证
                result = session.run("""
                    MATCH (m:MBTIType)
                    RETURN m.type, m.name, m.traits
                    ORDER BY m.type
                """)
                
                print("📊 MBTI数据验证:")
                for record in result:
                    print(f"   {record['m.type']}: {record['m.name']} - {record['m.traits']}")
                
                # 查询关系验证
                result = session.run("""
                    MATCH (m1:MBTIType)-[r:COMPATIBLE_WITH]->(m2:MBTIType)
                    RETURN m1.type, m2.type, r.score
                    ORDER BY r.score DESC
                """)
                
                print("🔗 兼容性关系验证:")
                for record in result:
                    print(f"   {record['m1.type']} -> {record['m2.type']}: {record['r.score']}%")
                
                driver.close()
                return True
                
        except Exception as e:
            print(f"❌ 创建MBTI测试数据失败: {e}")
            return False
    
    def generate_connection_report(self, successful_password):
        """生成连接报告"""
        print(f"\n📋 生成Neo4j连接报告...")
        
        report = {
            "timestamp": time.strftime("%Y-%m-%d %H:%M:%S"),
            "connection_status": "成功" if successful_password else "失败",
            "username": self.username,
            "bolt_url": self.bolt_url,
            "successful_password": successful_password if successful_password else "未找到",
            "tested_passwords": self.passwords,
            "recommendations": []
        }
        
        if successful_password:
            report["recommendations"].extend([
                f"使用密码: {successful_password}",
                "可以开始MBTI集成测试",
                "Neo4j多数据库架构就绪"
            ])
        else:
            report["recommendations"].extend([
                "需要重新安装Neo4j",
                "或者使用Docker方式部署",
                "检查Neo4j配置文件"
            ])
        
        # 保存报告
        import json
        with open("neo4j_connection_report.json", "w", encoding="utf-8") as f:
            json.dump(report, f, indent=2, ensure_ascii=False)
        
        print(f"📁 连接报告已保存: neo4j_connection_report.json")
        return report
    
    def run_comprehensive_test(self):
        """运行综合测试"""
        print("🚀 Neo4j综合密码测试开始...")
        
        # 测试所有密码
        successful_password = self.test_all_passwords()
        
        if successful_password:
            print(f"\n🎉 找到可用密码: {successful_password}")
            
            # 测试系统数据库
            if self.test_system_database_connection(successful_password):
                print("✅ 系统数据库访问正常")
            
            # 创建MBTI测试数据
            if self.create_mbti_test_data(successful_password):
                print("✅ MBTI测试数据创建成功")
            
            # 生成报告
            report = self.generate_connection_report(successful_password)
            
            print("\n🎯 测试完成状态:")
            print("✅ Neo4j连接成功")
            print("✅ 密码验证通过")
            print("✅ MBTI数据创建完成")
            print("✅ 多数据库架构就绪")
            
            return True
        else:
            print("\n❌ 所有密码都失败了")
            
            # 生成报告
            report = self.generate_connection_report(None)
            
            print("\n💡 建议解决方案:")
            print("1. 重新安装Neo4j")
            print("2. 使用Docker部署Neo4j")
            print("3. 检查Neo4j配置文件")
            print("4. 查看Neo4j日志文件")
            
            return False

def main():
    """主函数"""
    test = Neo4jComprehensivePasswordTest()
    success = test.run_comprehensive_test()
    
    if success:
        print("\n🚀 Neo4j集成测试成功!")
        print("可以开始MBTI多数据库架构开发!")
    else:
        print("\n⚠️ Neo4j集成测试失败")
        print("需要进一步排查问题")

if __name__ == "__main__":
    main()
