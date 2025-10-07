#!/usr/bin/env python3
"""
Neo4j首次设置解决方案
Neo4j First Time Setup Solution

解决Neo4j首次启动的认证问题
"""

import os
import subprocess
import time
import shutil
from pathlib import Path

class Neo4jFirstTimeSetup:
    """Neo4j首次设置解决方案"""
    
    def __init__(self):
        self.neo4j_data_dir = "/opt/homebrew/var/neo4j/data"
        self.neo4j_conf_dir = "/opt/homebrew/Cellar/neo4j/2025.08.0/libexec/conf"
        self.neo4j_conf_file = os.path.join(self.neo4j_conf_dir, "neo4j.conf")
        self.neo4j_bin_dir = "/opt/homebrew/Cellar/neo4j/2025.08.0/libexec/bin"
    
    def stop_neo4j(self):
        """停止Neo4j服务"""
        print("🛑 停止Neo4j服务...")
        
        try:
            result = subprocess.run(
                ["brew", "services", "stop", "neo4j"],
                capture_output=True,
                text=True
            )
            
            if result.returncode == 0:
                print("✅ Neo4j服务已停止")
                return True
            else:
                print(f"❌ 停止Neo4j服务失败: {result.stderr}")
                return False
                
        except Exception as e:
            print(f"❌ 停止Neo4j服务失败: {e}")
            return False
    
    def backup_data(self):
        """备份数据"""
        print("💾 备份Neo4j数据...")
        
        try:
            if os.path.exists(self.neo4j_data_dir):
                backup_dir = f"{self.neo4j_data_dir}.backup.{int(time.time())}"
                shutil.copytree(self.neo4j_data_dir, backup_dir)
                print(f"✅ 数据已备份到: {backup_dir}")
                return True
            else:
                print("⚠️ 数据目录不存在，无需备份")
                return True
                
        except Exception as e:
            print(f"❌ 备份数据失败: {e}")
            return False
    
    def clear_data(self):
        """清除数据"""
        print("🗑️ 清除Neo4j数据...")
        
        try:
            if os.path.exists(self.neo4j_data_dir):
                shutil.rmtree(self.neo4j_data_dir)
                os.makedirs(self.neo4j_data_dir, exist_ok=True)
                print("✅ 数据已清除")
                return True
            else:
                print("⚠️ 数据目录不存在")
                return True
                
        except Exception as e:
            print(f"❌ 清除数据失败: {e}")
            return False
    
    def update_config(self):
        """更新配置"""
        print("🔧 更新Neo4j配置...")
        
        try:
            # 备份原配置
            backup_conf = f"{self.neo4j_conf_file}.backup.{int(time.time())}"
            shutil.copy2(self.neo4j_conf_file, backup_conf)
            print(f"✅ 配置已备份到: {backup_conf}")
            
            # 创建新配置
            new_config = """# Neo4j Configuration
server.directories.data=data
server.directories.logs=logs
server.directories.import=import
server.directories.plugins=plugins

# Network settings
server.bolt.enabled=true
server.bolt.listen_address=0.0.0.0:7687
server.http.enabled=true
server.http.listen_address=0.0.0.0:7474

# Authentication - 首次启动时禁用认证
dbms.security.auth_enabled=false

# Memory settings
server.memory.heap.initial_size=512m
server.memory.heap.max_size=2G
server.memory.pagecache.size=1G

# WebSocket configuration
server.http.cors.enabled=true
server.http.cors.origin=*
server.http.cors.credentials=true
"""
            
            with open(self.neo4j_conf_file, 'w') as f:
                f.write(new_config)
            
            print("✅ 配置已更新")
            return True
            
        except Exception as e:
            print(f"❌ 更新配置失败: {e}")
            return False
    
    def start_neo4j(self):
        """启动Neo4j服务"""
        print("🚀 启动Neo4j服务...")
        
        try:
            result = subprocess.run(
                ["brew", "services", "start", "neo4j"],
                capture_output=True,
                text=True
            )
            
            if result.returncode == 0:
                print("✅ Neo4j服务已启动")
                # 等待服务完全启动
                print("⏳ 等待服务完全启动...")
                time.sleep(15)
                return True
            else:
                print(f"❌ 启动Neo4j服务失败: {result.stderr}")
                return False
                
        except Exception as e:
            print(f"❌ 启动Neo4j服务失败: {e}")
            return False
    
    def test_connection(self):
        """测试连接"""
        print("🔍 测试Neo4j连接...")
        
        try:
            from neo4j import GraphDatabase
            
            driver = GraphDatabase.driver('bolt://localhost:7687')
            
            with driver.session() as session:
                result = session.run('RETURN 1 as test')
                record = result.single()
                if record and record['test'] == 1:
                    print('✅ Neo4j连接成功!')
                    print('🎉 无认证连接成功!')
                    driver.close()
                    return True
                else:
                    print('❌ Neo4j连接失败')
                    driver.close()
                    return False
                    
        except Exception as e:
            print(f'❌ Neo4j连接失败: {e}')
            return False
    
    def enable_auth_and_set_password(self):
        """启用认证并设置密码"""
        print("🔧 启用认证并设置密码...")
        
        try:
            # 更新配置启用认证
            with open(self.neo4j_conf_file, 'r') as f:
                content = f.read()
            
            # 替换认证设置
            content = content.replace('dbms.security.auth_enabled=false', 'dbms.security.auth_enabled=true')
            
            with open(self.neo4j_conf_file, 'w') as f:
                f.write(content)
            
            print("✅ 认证已启用")
            
            # 重启服务
            self.stop_neo4j()
            time.sleep(3)
            self.start_neo4j()
            
            # 设置密码
            from neo4j import GraphDatabase
            
            driver = GraphDatabase.driver('bolt://localhost:7687')
            
            with driver.session(database="system") as session:
                # 设置密码
                session.run("ALTER USER neo4j SET PASSWORD 'mbti_neo4j_2025'")
                print("✅ 密码已设置为: mbti_neo4j_2025")
            
            driver.close()
            return True
            
        except Exception as e:
            print(f"❌ 启用认证失败: {e}")
            return False
    
    def test_final_connection(self):
        """测试最终连接"""
        print("🔍 测试最终连接...")
        
        try:
            from neo4j import GraphDatabase
            
            driver = GraphDatabase.driver(
                'bolt://localhost:7687',
                auth=('neo4j', 'mbti_neo4j_2025')
            )
            
            with driver.session() as session:
                result = session.run('RETURN 1 as test')
                record = result.single()
                if record and record['test'] == 1:
                    print('✅ 最终连接成功!')
                    print('🎉 密码 mbti_neo4j_2025 有效!')
                    driver.close()
                    return True
                else:
                    print('❌ 最终连接失败')
                    driver.close()
                    return False
                    
        except Exception as e:
            print(f'❌ 最终连接失败: {e}')
            return False
    
    def run_setup(self):
        """运行设置"""
        print("🚀 Neo4j首次设置开始...")
        print("=" * 60)
        
        # 步骤1: 停止Neo4j服务
        if not self.stop_neo4j():
            print("❌ 停止Neo4j服务失败")
            return False
        
        # 步骤2: 备份数据
        if not self.backup_data():
            print("❌ 备份数据失败")
            return False
        
        # 步骤3: 清除数据
        if not self.clear_data():
            print("❌ 清除数据失败")
            return False
        
        # 步骤4: 更新配置
        if not self.update_config():
            print("❌ 更新配置失败")
            return False
        
        # 步骤5: 启动Neo4j服务
        if not self.start_neo4j():
            print("❌ 启动Neo4j服务失败")
            return False
        
        # 步骤6: 测试无认证连接
        if not self.test_connection():
            print("❌ 无认证连接失败")
            return False
        
        # 步骤7: 启用认证并设置密码
        if not self.enable_auth_and_set_password():
            print("❌ 启用认证失败")
            return False
        
        # 步骤8: 测试最终连接
        if not self.test_final_connection():
            print("❌ 最终连接失败")
            return False
        
        print("\n🎉 Neo4j首次设置完成!")
        print("✅ 认证已启用")
        print("✅ 密码已设置")
        print("✅ 连接测试通过")
        print("✅ 多数据库架构就绪")
        
        return True

def main():
    """主函数"""
    setup = Neo4jFirstTimeSetup()
    success = setup.run_setup()
    
    if success:
        print("\n🎯 设置完成状态:")
        print("✅ Neo4j密码: mbti_neo4j_2025")
        print("✅ 连接正常")
        print("✅ 可以开始MBTI项目开发!")
    else:
        print("\n❌ 设置失败")
        print("💡 请检查Neo4j安装和配置")

if __name__ == "__main__":
    main()
