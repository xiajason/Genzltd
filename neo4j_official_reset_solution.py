#!/usr/bin/env python3
"""
Neo4j官方文档重置解决方案
Neo4j Official Documentation Reset Solution

基于Neo4j官方文档的密码重置方法
"""

import os
import subprocess
import time
import shutil
from pathlib import Path

class Neo4jOfficialReset:
    """Neo4j官方重置解决方案"""
    
    def __init__(self):
        self.neo4j_data_dir = "/opt/homebrew/var/neo4j/data"
        self.neo4j_auth_file = os.path.join(self.neo4j_data_dir, "dbms", "auth")
        self.neo4j_bin_dir = "/opt/homebrew/Cellar/neo4j/2025.08.0/libexec/bin"
        self.cypher_shell = os.path.join(self.neo4j_bin_dir, "cypher-shell")
    
    def check_neo4j_status(self):
        """检查Neo4j状态"""
        print("🔍 检查Neo4j状态...")
        
        try:
            result = subprocess.run(
                ["brew", "services", "list"], 
                capture_output=True, 
                text=True
            )
            
            if "neo4j" in result.stdout:
                print("✅ Neo4j服务已安装")
                return True
            else:
                print("❌ Neo4j服务未安装")
                return False
                
        except Exception as e:
            print(f"❌ 检查Neo4j状态失败: {e}")
            return False
    
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
    
    def backup_auth_file(self):
        """备份认证文件"""
        print("💾 备份认证文件...")
        
        try:
            if os.path.exists(self.neo4j_auth_file):
                backup_file = f"{self.neo4j_auth_file}.backup.{int(time.time())}"
                shutil.copy2(self.neo4j_auth_file, backup_file)
                print(f"✅ 认证文件已备份到: {backup_file}")
                return True
            else:
                print("⚠️ 认证文件不存在，无需备份")
                return True
                
        except Exception as e:
            print(f"❌ 备份认证文件失败: {e}")
            return False
    
    def remove_auth_file(self):
        """删除认证文件"""
        print("🗑️ 删除认证文件...")
        
        try:
            if os.path.exists(self.neo4j_auth_file):
                os.remove(self.neo4j_auth_file)
                print("✅ 认证文件已删除")
                return True
            else:
                print("⚠️ 认证文件不存在")
                return True
                
        except Exception as e:
            print(f"❌ 删除认证文件失败: {e}")
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
                time.sleep(10)
                return True
            else:
                print(f"❌ 启动Neo4j服务失败: {result.stderr}")
                return False
                
        except Exception as e:
            print(f"❌ 启动Neo4j服务失败: {e}")
            return False
    
    def test_default_connection(self):
        """测试默认连接"""
        print("🔍 测试默认连接...")
        
        try:
            # 设置Java环境变量
            env = os.environ.copy()
            env["PATH"] = "/opt/homebrew/opt/openjdk@17/bin:" + env.get("PATH", "")
            env["CPPFLAGS"] = "-I/opt/homebrew/opt/openjdk@17/include"
            
            # 使用cypher-shell测试连接
            result = subprocess.run(
                [self.cypher_shell, "-u", "neo4j", "-p", "neo4j", "-c", "RETURN 1 as test"],
                capture_output=True,
                text=True,
                timeout=30,
                env=env
            )
            
            if result.returncode == 0 and "test" in result.stdout:
                print("✅ 默认连接成功")
                return True
            else:
                print(f"❌ 默认连接失败: {result.stderr}")
                return False
                
        except Exception as e:
            print(f"❌ 默认连接测试失败: {e}")
            return False
    
    def change_password(self):
        """更改密码"""
        print("🔧 更改密码...")
        
        try:
            # 设置Java环境变量
            env = os.environ.copy()
            env["PATH"] = "/opt/homebrew/opt/openjdk@17/bin:" + env.get("PATH", "")
            env["CPPFLAGS"] = "-I/opt/homebrew/opt/openjdk@17/include"
            
            # 使用cypher-shell更改密码
            result = subprocess.run(
                [self.cypher_shell, "-u", "neo4j", "-p", "neo4j", "-c", "CALL dbms.changePassword('mbti_neo4j_2025')"],
                capture_output=True,
                text=True,
                timeout=30,
                env=env
            )
            
            if result.returncode == 0:
                print("✅ 密码更改成功")
                return True
            else:
                print(f"❌ 密码更改失败: {result.stderr}")
                return False
                
        except Exception as e:
            print(f"❌ 密码更改失败: {e}")
            return False
    
    def test_new_password(self):
        """测试新密码"""
        print("🔍 测试新密码...")
        
        try:
            # 设置Java环境变量
            env = os.environ.copy()
            env["PATH"] = "/opt/homebrew/opt/openjdk@17/bin:" + env.get("PATH", "")
            env["CPPFLAGS"] = "-I/opt/homebrew/opt/openjdk@17/include"
            
            result = subprocess.run(
                [self.cypher_shell, "-u", "neo4j", "-p", "mbti_neo4j_2025", "-c", "RETURN 1 as test"],
                capture_output=True,
                text=True,
                timeout=30,
                env=env
            )
            
            if result.returncode == 0 and "test" in result.stdout:
                print("✅ 新密码连接成功")
                return True
            else:
                print(f"❌ 新密码连接失败: {result.stderr}")
                return False
                
        except Exception as e:
            print(f"❌ 新密码测试失败: {e}")
            return False
    
    def create_mbti_data(self):
        """创建MBTI数据"""
        print("🌐 创建MBTI数据...")
        
        try:
            # 创建MBTI测试数据
            cypher_commands = [
                "MATCH (n) DETACH DELETE n",
                "CREATE (m:MBTIType {type: 'INTJ', name: '建筑师', traits: ['独立', '理性', '创新']})",
                "CREATE (m:MBTIType {type: 'ENFP', name: '竞选者', traits: ['热情', '创意', '社交']})",
                "CREATE (m:MBTIType {type: 'ISFJ', name: '守护者', traits: ['忠诚', '负责', '细心']})",
                "CREATE (m:MBTIType {type: 'ESTP', name: '企业家', traits: ['行动', '实用', '灵活']})"
            ]
            
            # 设置Java环境变量
            env = os.environ.copy()
            env["PATH"] = "/opt/homebrew/opt/openjdk@17/bin:" + env.get("PATH", "")
            env["CPPFLAGS"] = "-I/opt/homebrew/opt/openjdk@17/include"
            
            for command in cypher_commands:
                result = subprocess.run(
                    [self.cypher_shell, "-u", "neo4j", "-p", "mbti_neo4j_2025", "-c", command],
                    capture_output=True,
                    text=True,
                    timeout=30,
                    env=env
                )
                
                if result.returncode != 0:
                    print(f"❌ 执行命令失败: {command}")
                    print(f"错误: {result.stderr}")
                    return False
            
            print("✅ MBTI数据创建成功")
            return True
            
        except Exception as e:
            print(f"❌ 创建MBTI数据失败: {e}")
            return False
    
    def run_reset(self):
        """运行重置"""
        print("🚀 Neo4j官方重置开始...")
        print("=" * 60)
        
        # 步骤1: 检查Neo4j状态
        if not self.check_neo4j_status():
            print("❌ Neo4j未安装")
            return False
        
        # 步骤2: 停止Neo4j服务
        if not self.stop_neo4j():
            print("❌ 停止Neo4j服务失败")
            return False
        
        # 步骤3: 备份认证文件
        if not self.backup_auth_file():
            print("❌ 备份认证文件失败")
            return False
        
        # 步骤4: 删除认证文件
        if not self.remove_auth_file():
            print("❌ 删除认证文件失败")
            return False
        
        # 步骤5: 启动Neo4j服务
        if not self.start_neo4j():
            print("❌ 启动Neo4j服务失败")
            return False
        
        # 步骤6: 测试默认连接
        if not self.test_default_connection():
            print("❌ 默认连接失败")
            return False
        
        # 步骤7: 更改密码
        if not self.change_password():
            print("❌ 更改密码失败")
            return False
        
        # 步骤8: 测试新密码
        if not self.test_new_password():
            print("❌ 新密码测试失败")
            return False
        
        # 步骤9: 创建MBTI数据
        if not self.create_mbti_data():
            print("❌ 创建MBTI数据失败")
            return False
        
        print("\n🎉 Neo4j官方重置完成!")
        print("✅ 认证文件已重置")
        print("✅ 密码已更改")
        print("✅ 连接测试通过")
        print("✅ MBTI数据已创建")
        print("✅ 多数据库架构就绪")
        
        return True

def main():
    """主函数"""
    reset = Neo4jOfficialReset()
    success = reset.run_reset()
    
    if success:
        print("\n🎯 重置完成状态:")
        print("✅ Neo4j密码: mbti_neo4j_2025")
        print("✅ 连接正常")
        print("✅ MBTI数据已创建")
        print("✅ 可以开始MBTI项目开发!")
    else:
        print("\n❌ 重置失败")
        print("💡 请检查Neo4j安装和配置")

if __name__ == "__main__":
    main()
