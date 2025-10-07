#!/usr/bin/env python3
"""
Neo4j完全重置脚本
Neo4j Complete Reset Script

完全重置Neo4j，解决认证问题
"""

import os
import subprocess
import time
import shutil
from pathlib import Path

class Neo4jCompleteReset:
    """Neo4j完全重置类"""
    
    def __init__(self):
        self.neo4j_config_path = "/opt/homebrew/Cellar/neo4j/2025.08.0/libexec/conf/neo4j.conf"
        self.neo4j_data_path = "/opt/homebrew/var/neo4j"
        self.neo4j_logs_path = "/opt/homebrew/Cellar/neo4j/2025.08.0/libexec/logs"
    
    def stop_neo4j_service(self):
        """停止Neo4j服务"""
        print("🛑 停止Neo4j服务...")
        
        try:
            subprocess.run(['brew', 'services', 'stop', 'neo4j'], check=True)
            time.sleep(3)
            print("✅ Neo4j服务已停止")
            return True
        except Exception as e:
            print(f"❌ 停止Neo4j服务失败: {e}")
            return False
    
    def backup_neo4j_data(self):
        """备份Neo4j数据"""
        print("💾 备份Neo4j数据...")
        
        try:
            backup_path = f"{self.neo4j_data_path}_backup_{int(time.time())}"
            if os.path.exists(self.neo4j_data_path):
                shutil.copytree(self.neo4j_data_path, backup_path)
                print(f"✅ Neo4j数据已备份到: {backup_path}")
                return backup_path
            else:
                print("⚠️ Neo4j数据目录不存在")
                return None
        except Exception as e:
            print(f"❌ 备份Neo4j数据失败: {e}")
            return None
    
    def clear_neo4j_data(self):
        """清除Neo4j数据"""
        print("🗑️ 清除Neo4j数据...")
        
        try:
            if os.path.exists(self.neo4j_data_path):
                shutil.rmtree(self.neo4j_data_path)
                print("✅ Neo4j数据已清除")
            
            # 重新创建数据目录
            os.makedirs(self.neo4j_data_path, exist_ok=True)
            print("✅ Neo4j数据目录已重新创建")
            return True
        except Exception as e:
            print(f"❌ 清除Neo4j数据失败: {e}")
            return False
    
    def reset_neo4j_config(self):
        """重置Neo4j配置"""
        print("🔧 重置Neo4j配置...")
        
        try:
            # 备份原配置
            if os.path.exists(self.neo4j_config_path):
                backup_config = f"{self.neo4j_config_path}.backup_{int(time.time())}"
                shutil.copy2(self.neo4j_config_path, backup_config)
                print(f"✅ 原配置已备份到: {backup_config}")
            
            # 创建新的干净配置
            clean_config = f"""
# Neo4j Configuration
# 基本设置
server.directories.data=data
server.directories.logs=logs
server.directories.import=import
server.directories.plugins=plugins

# 网络设置
server.bolt.enabled=true
server.bolt.listen_address=0.0.0.0:7687
server.http.enabled=true
server.http.listen_address=0.0.0.0:7474

# 认证设置
dbms.security.auth_enabled=true

# 内存设置
dbms.memory.heap.initial_size=512m
dbms.memory.heap.max_size=2G
dbms.memory.pagecache.size=1G

# 日志设置
dbms.logs.debug.level=INFO
dbms.logs.query.enabled=true
dbms.logs.query.threshold=0

# 性能设置
dbms.tx_log.rotation.retention_policy=100M size
dbms.checkpoint.interval.time=5m
dbms.checkpoint.interval.tx=100000
"""
            
            with open(self.neo4j_config_path, 'w') as f:
                f.write(clean_config.strip())
            
            print("✅ Neo4j配置已重置")
            return True
        except Exception as e:
            print(f"❌ 重置Neo4j配置失败: {e}")
            return False
    
    def clear_neo4j_logs(self):
        """清除Neo4j日志"""
        print("📝 清除Neo4j日志...")
        
        try:
            if os.path.exists(self.neo4j_logs_path):
                for log_file in os.listdir(self.neo4j_logs_path):
                    log_path = os.path.join(self.neo4j_logs_path, log_file)
                    if os.path.isfile(log_path):
                        with open(log_path, 'w') as f:
                            f.write('')
                print("✅ Neo4j日志已清除")
            return True
        except Exception as e:
            print(f"❌ 清除Neo4j日志失败: {e}")
            return False
    
    def start_neo4j_service(self):
        """启动Neo4j服务"""
        print("🚀 启动Neo4j服务...")
        
        try:
            subprocess.run(['brew', 'services', 'start', 'neo4j'], check=True)
            time.sleep(10)  # 等待服务启动
            print("✅ Neo4j服务已启动")
            return True
        except Exception as e:
            print(f"❌ 启动Neo4j服务失败: {e}")
            return False
    
    def test_neo4j_connection(self):
        """测试Neo4j连接"""
        print("🔍 测试Neo4j连接...")
        
        try:
            from neo4j import GraphDatabase
            
            # 等待服务完全启动
            time.sleep(5)
            
            # 尝试使用默认密码连接
            driver = GraphDatabase.driver(
                "bolt://localhost:7687",
                auth=("neo4j", "neo4j")
            )
            
            with driver.session() as session:
                result = session.run("RETURN 1 as test")
                record = result.single()
                if record and record["test"] == 1:
                    print("✅ Neo4j连接成功!")
                    print("💡 默认用户名: neo4j")
                    print("💡 默认密码: neo4j")
                    driver.close()
                    return True
                else:
                    print("❌ Neo4j连接失败")
                    driver.close()
                    return False
                    
        except Exception as e:
            print(f"❌ Neo4j连接测试失败: {e}")
            return False
    
    def run_complete_reset(self):
        """运行完全重置"""
        print("🚀 Neo4j完全重置开始...")
        print("=" * 80)
        
        # 步骤1: 停止服务
        if not self.stop_neo4j_service():
            print("❌ 停止服务失败")
            return False
        
        # 步骤2: 备份数据
        backup_path = self.backup_neo4j_data()
        
        # 步骤3: 清除数据
        if not self.clear_neo4j_data():
            print("❌ 清除数据失败")
            return False
        
        # 步骤4: 重置配置
        if not self.reset_neo4j_config():
            print("❌ 重置配置失败")
            return False
        
        # 步骤5: 清除日志
        if not self.clear_neo4j_logs():
            print("❌ 清除日志失败")
            return False
        
        # 步骤6: 启动服务
        if not self.start_neo4j_service():
            print("❌ 启动服务失败")
            return False
        
        # 步骤7: 测试连接
        if not self.test_neo4j_connection():
            print("❌ 连接测试失败")
            return False
        
        print("\n🎉 Neo4j完全重置完成!")
        print("✅ Neo4j服务已重置")
        print("✅ 默认密码: neo4j")
        print("✅ 可以访问: http://localhost:7474")
        
        return True

def main():
    """主函数"""
    print("⚠️ 警告: 此操作将完全重置Neo4j，清除所有数据!")
    confirm = input("确认继续? (y/N): ")
    
    if confirm.lower() != 'y':
        print("❌ 操作已取消")
        return
    
    reset = Neo4jCompleteReset()
    success = reset.run_complete_reset()
    
    if success:
        print("\n🎯 下一步:")
        print("1. 访问 http://localhost:7474")
        print("2. 用户名: neo4j")
        print("3. 密码: neo4j")
        print("4. 修改密码为: mbti_neo4j_2025")
        print("5. 开始MBTI集成测试")
    else:
        print("\n❌ Neo4j重置失败")
        print("请检查Neo4j安装")

if __name__ == "__main__":
    main()
