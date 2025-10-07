#!/usr/bin/env python3
"""
Neo4j连接修复脚本
Neo4j Connection Fix Script

修复Neo4j连接问题，解决网络错误
"""

import time
import subprocess
import requests
from neo4j import GraphDatabase

class Neo4jConnectionFix:
    """Neo4j连接修复类"""
    
    def __init__(self):
        self.neo4j_http_url = "http://localhost:7474"
        self.neo4j_bolt_url = "bolt://localhost:7687"
        self.username = "neo4j"
        self.password = "mbti_neo4j_2025"
    
    def check_neo4j_status(self):
        """检查Neo4j状态"""
        print("🔍 检查Neo4j状态...")
        
        try:
            # 检查进程
            result = subprocess.run(['ps', 'aux'], capture_output=True, text=True)
            if 'neo4j' not in result.stdout.lower():
                print("❌ Neo4j服务未运行")
                return False
            
            print("✅ Neo4j服务正在运行")
            
            # 检查端口
            result = subprocess.run(['netstat', '-an'], capture_output=True, text=True)
            if '7474' not in result.stdout and '7687' not in result.stdout:
                print("❌ Neo4j端口未监听")
                return False
            
            print("✅ Neo4j端口正常监听")
            return True
            
        except Exception as e:
            print(f"❌ 检查Neo4j状态失败: {e}")
            return False
    
    def test_http_connection(self):
        """测试HTTP连接"""
        print("🌐 测试Neo4j HTTP连接...")
        
        try:
            response = requests.get(self.neo4j_http_url, timeout=10)
            if response.status_code == 200:
                print("✅ Neo4j HTTP连接正常")
                return True
            else:
                print(f"❌ Neo4j HTTP连接异常: {response.status_code}")
                return False
                
        except Exception as e:
            print(f"❌ Neo4j HTTP连接失败: {e}")
            return False
    
    def test_bolt_connection(self):
        """测试Bolt连接"""
        print("🔗 测试Neo4j Bolt连接...")
        
        try:
            driver = GraphDatabase.driver(
                self.neo4j_bolt_url,
                auth=(self.username, self.password)
            )
            
            with driver.session() as session:
                result = session.run("RETURN 1 as test")
                record = result.single()
                if record and record["test"] == 1:
                    print("✅ Neo4j Bolt连接成功")
                    driver.close()
                    return True
                else:
                    print("❌ Neo4j Bolt连接失败")
                    driver.close()
                    return False
                    
        except Exception as e:
            print(f"❌ Neo4j Bolt连接失败: {e}")
            return False
    
    def restart_neo4j_service(self):
        """重启Neo4j服务"""
        print("🔄 重启Neo4j服务...")
        
        try:
            # 停止Neo4j服务
            print("停止Neo4j服务...")
            subprocess.run(['brew', 'services', 'stop', 'neo4j'], check=True)
            time.sleep(3)
            
            # 启动Neo4j服务
            print("启动Neo4j服务...")
            subprocess.run(['brew', 'services', 'start', 'neo4j'], check=True)
            time.sleep(10)
            
            print("✅ Neo4j服务重启完成")
            return True
            
        except Exception as e:
            print(f"❌ 重启Neo4j服务失败: {e}")
            return False
    
    def fix_neo4j_connection(self):
        """修复Neo4j连接"""
        print("🔧 开始修复Neo4j连接...")
        print("=" * 60)
        
        # 步骤1: 检查Neo4j状态
        if not self.check_neo4j_status():
            print("❌ Neo4j状态检查失败")
            return False
        
        # 步骤2: 测试HTTP连接
        if not self.test_http_connection():
            print("⚠️ HTTP连接异常，尝试重启服务...")
            if not self.restart_neo4j_service():
                print("❌ 重启Neo4j服务失败")
                return False
            
            # 重新测试HTTP连接
            if not self.test_http_connection():
                print("❌ HTTP连接仍然异常")
                return False
        
        # 步骤3: 测试Bolt连接
        if not self.test_bolt_connection():
            print("⚠️ Bolt连接异常")
            print("💡 请访问 http://localhost:7474 设置密码")
            print(f"   用户名: {self.username}")
            print(f"   密码: {self.password}")
            return False
        
        print("✅ Neo4j连接修复完成!")
        return True
    
    def create_connection_test_script(self):
        """创建连接测试脚本"""
        print("📝 创建Neo4j连接测试脚本...")
        
        script_content = '''#!/usr/bin/env python3
"""
Neo4j连接测试脚本
"""

from neo4j import GraphDatabase

def test_neo4j_connection():
    """测试Neo4j连接"""
    try:
        driver = GraphDatabase.driver(
            "bolt://localhost:7687",
            auth=("neo4j", "mbti_neo4j_2025")
        )
        
        with driver.session() as session:
            result = session.run("RETURN 1 as test")
            record = result.single()
            if record and record["test"] == 1:
                print("✅ Neo4j连接成功!")
                return True
            else:
                print("❌ Neo4j连接失败")
                return False
        
        driver.close()
        
    except Exception as e:
        print(f"❌ Neo4j连接失败: {e}")
        return False

if __name__ == "__main__":
    test_neo4j_connection()
'''
        
        with open("neo4j_connection_test.py", "w", encoding="utf-8") as f:
            f.write(script_content)
        
        print("✅ 连接测试脚本已创建: neo4j_connection_test.py")
        return True
    
    def run_fix(self):
        """运行修复"""
        print("🚀 Neo4j连接修复开始...")
        
        # 修复连接
        if self.fix_neo4j_connection():
            print("🎉 Neo4j连接修复成功!")
            
            # 创建测试脚本
            self.create_connection_test_script()
            
            print("\n📋 修复完成状态:")
            print("✅ Neo4j服务: 正常运行")
            print("✅ HTTP连接: 正常")
            print("✅ Bolt连接: 正常")
            print("✅ 连接测试脚本: 已创建")
            
            return True
        else:
            print("❌ Neo4j连接修复失败")
            print("\n💡 手动修复步骤:")
            print("1. 访问 http://localhost:7474")
            print("2. 设置用户名: neo4j")
            print("3. 设置密码: mbti_neo4j_2025")
            print("4. 重新运行连接测试")
            
            return False

def main():
    """主函数"""
    fix = Neo4jConnectionFix()
    success = fix.run_fix()
    
    if success:
        print("\n🎯 下一步:")
        print("1. Neo4j连接已修复")
        print("2. 可以开始MBTI集成测试")
        print("3. 运行: python neo4j_connection_test.py")
    else:
        print("\n⚠️ 需要手动设置Neo4j密码")

if __name__ == "__main__":
    main()
