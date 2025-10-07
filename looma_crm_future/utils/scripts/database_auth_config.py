#!/usr/bin/env python3
"""
数据库认证配置管理器
Database Authentication Configuration Manager

用于配置独立数据库实例的认证信息
"""

import asyncio
import sys
import os
import subprocess
import time
from pathlib import Path
from typing import Dict, Any, Optional
import json

# 添加项目根目录到Python路径
project_root = Path(__file__).parent.parent
sys.path.append(str(project_root))

class DatabaseAuthConfigManager:
    """数据库认证配置管理器"""
    
    def __init__(self):
        self.project_root = project_root
        self.config = {
            "mongodb": {
                "host": "localhost",
                "port": 27018,
                "database": "looma_independent",
                "admin_user": "looma_admin",
                "admin_password": "looma_admin_password",
                "app_user": "looma_user",
                "app_password": "looma_password"
            },
            "redis": {
                "host": "localhost",
                "port": 6382,
                "password": "looma_independent_password"
            },
            "neo4j": {
                "host": "localhost",
                "port": 7475,
                "bolt_port": 7688,
                "user": "neo4j",
                "password": "looma_password",
                "database": "looma-independent"
            }
        }
    
    def log(self, message: str, level: str = "INFO"):
        """日志输出"""
        timestamp = time.strftime("%Y-%m-%d %H:%M:%S")
        print(f"[{timestamp}] [{level}] {message}")
    
    def check_database_connection(self, db_type: str) -> bool:
        """检查数据库连接"""
        try:
            if db_type == "mongodb":
                return self._check_mongodb_connection()
            elif db_type == "redis":
                return self._check_redis_connection()
            elif db_type == "neo4j":
                return self._check_neo4j_connection()
            else:
                self.log(f"未知数据库类型: {db_type}", "ERROR")
                return False
        except Exception as e:
            self.log(f"检查{db_type}连接失败: {e}", "ERROR")
            return False
    
    def _check_mongodb_connection(self) -> bool:
        """检查MongoDB连接"""
        try:
            import pymongo
            client = pymongo.MongoClient(
                host=self.config["mongodb"]["host"],
                port=self.config["mongodb"]["port"],
                serverSelectionTimeoutMS=5000
            )
            client.admin.command('ping')
            client.close()
            return True
        except Exception as e:
            self.log(f"MongoDB连接检查失败: {e}", "ERROR")
            return False
    
    def _check_redis_connection(self) -> bool:
        """检查Redis连接"""
        try:
            import redis
            r = redis.Redis(
                host=self.config["redis"]["host"],
                port=self.config["redis"]["port"],
                password=self.config["redis"]["password"],
                decode_responses=True,
                socket_connect_timeout=5
            )
            r.ping()
            return True
        except Exception as e:
            self.log(f"Redis连接检查失败: {e}", "ERROR")
            return False
    
    def _check_neo4j_connection(self) -> bool:
        """检查Neo4j连接"""
        try:
            from neo4j import GraphDatabase
            driver = GraphDatabase.driver(
                f"bolt://{self.config['neo4j']['host']}:{self.config['neo4j']['bolt_port']}",
                auth=(self.config["neo4j"]["user"], self.config["neo4j"]["password"])
            )
            with driver.session() as session:
                session.run("RETURN 1")
            driver.close()
            return True
        except Exception as e:
            self.log(f"Neo4j连接检查失败: {e}", "ERROR")
            return False
    
    def configure_mongodb_auth(self) -> bool:
        """配置MongoDB认证"""
        self.log("开始配置MongoDB认证...")
        
        try:
            import pymongo
            from pymongo.errors import OperationFailure
            
            # 连接到MongoDB (无认证模式)
            client = pymongo.MongoClient(
                host=self.config["mongodb"]["host"],
                port=self.config["mongodb"]["port"],
                serverSelectionTimeoutMS=10000
            )
            
            # 检查是否已有管理员用户
            admin_db = client.admin
            try:
                # 检查用户是否存在
                users = admin_db.command("usersInfo")
                admin_user_exists = any(
                    user["user"] == self.config["mongodb"]["admin_user"] 
                    for user in users["users"]
                )
                
                if not admin_user_exists:
                    # 创建管理员用户
                    self.log("创建MongoDB管理员用户...")
                    admin_db.command("createUser", 
                        self.config["mongodb"]["admin_user"],
                        pwd=self.config["mongodb"]["admin_password"],
                        roles=["userAdminAnyDatabase", "dbAdminAnyDatabase", "readWriteAnyDatabase"]
                    )
                    self.log("MongoDB管理员用户创建成功")
                else:
                    self.log("MongoDB管理员用户已存在")
                    
            except Exception as e:
                self.log(f"检查/创建管理员用户失败: {e}", "ERROR")
                # 继续尝试创建应用用户
            
            # 切换到应用数据库
            app_db = client[self.config["mongodb"]["database"]]
            
            # 创建应用用户
            try:
                app_db.command("createUser",
                    self.config["mongodb"]["app_user"],
                    pwd=self.config["mongodb"]["app_password"],
                    roles=["readWrite"]
                )
                self.log("MongoDB应用用户创建成功")
            except OperationFailure as e:
                if "already exists" in str(e):
                    self.log("MongoDB应用用户已存在")
                else:
                    self.log(f"创建应用用户失败: {e}", "WARNING")
            
            client.close()
            self.log("MongoDB认证配置完成")
            return True
            
        except Exception as e:
            self.log(f"MongoDB认证配置失败: {e}", "ERROR")
            return False
    
    def configure_redis_auth(self) -> bool:
        """配置Redis认证"""
        self.log("开始配置Redis认证...")
        
        try:
            import redis
            
            # 测试Redis连接
            r = redis.Redis(
                host=self.config["redis"]["host"],
                port=self.config["redis"]["port"],
                password=self.config["redis"]["password"],
                decode_responses=True
            )
            
            # 测试认证
            r.ping()
            self.log("Redis认证配置验证成功")
            return True
            
        except Exception as e:
            self.log(f"Redis认证配置失败: {e}", "ERROR")
            return False
    
    def configure_neo4j_auth(self) -> bool:
        """配置Neo4j认证"""
        self.log("开始配置Neo4j认证...")
        
        try:
            from neo4j import GraphDatabase
            
            # 首先尝试使用默认密码连接
            default_passwords = ["neo4j", "looma_password", "password"]
            
            for password in default_passwords:
                try:
                    self.log(f"尝试使用密码: {password}")
                    driver = GraphDatabase.driver(
                        f"bolt://{self.config['neo4j']['host']}:{self.config['neo4j']['bolt_port']}",
                        auth=(self.config["neo4j"]["user"], password)
                    )
                    
                    with driver.session() as session:
                        # 测试基本查询
                        result = session.run("RETURN 1 as test")
                        record = result.single()
                        if record and record["test"] == 1:
                            self.log(f"Neo4j认证成功，当前密码: {password}")
                            
                            # 如果密码不是我们想要的，尝试修改密码
                            if password != self.config["neo4j"]["password"]:
                                try:
                                    session.run(f"ALTER CURRENT USER SET PASSWORD FROM '{password}' TO '{self.config['neo4j']['password']}'")
                                    self.log("Neo4j密码已更新")
                                except Exception as e:
                                    self.log(f"更新Neo4j密码失败: {e}", "WARNING")
                            
                            driver.close()
                            return True
                            
                except Exception as e:
                    self.log(f"使用密码 {password} 连接失败: {e}")
                    continue
            
            self.log("所有密码尝试失败，Neo4j认证配置失败", "ERROR")
            return False
            
        except Exception as e:
            self.log(f"Neo4j认证配置失败: {e}", "ERROR")
            return False
    
    def update_api_service_configs(self) -> bool:
        """更新API服务配置"""
        self.log("开始更新API服务配置...")
        
        try:
            # 更新用户API服务配置
            user_api_config = self.project_root / "api-services" / "looma-user-api" / "config" / "settings.py"
            if user_api_config.exists():
                self._update_user_api_config(user_api_config)
                self.log("用户API服务配置已更新")
            
            # 更新API网关配置
            gateway_config = self.project_root / "api-services" / "looma-api-gateway" / "config" / "settings.py"
            if gateway_config.exists():
                self._update_gateway_config(gateway_config)
                self.log("API网关配置已更新")
            
            return True
            
        except Exception as e:
            self.log(f"更新API服务配置失败: {e}", "ERROR")
            return False
    
    def _update_user_api_config(self, config_file: Path):
        """更新用户API服务配置"""
        content = config_file.read_text(encoding='utf-8')
        
        # 更新MongoDB URL
        mongodb_url = f"mongodb://{self.config['mongodb']['app_user']}:{self.config['mongodb']['app_password']}@{self.config['mongodb']['host']}:{self.config['mongodb']['port']}/{self.config['mongodb']['database']}"
        content = content.replace(
            'mongodb_url: str = "mongodb://localhost:27018"',
            f'mongodb_url: str = "{mongodb_url}"'
        )
        
        # 更新Redis URL
        redis_url = f"redis://:{self.config['redis']['password']}@{self.config['redis']['host']}:{self.config['redis']['port']}/0"
        content = content.replace(
            'redis_url: str = "redis://localhost:6382/0"',
            f'redis_url: str = "{redis_url}"'
        )
        
        # 更新Neo4j配置
        content = content.replace(
            'neo4j_password: str = "looma_password"',
            f'neo4j_password: str = "{self.config["neo4j"]["password"]}"'
        )
        
        config_file.write_text(content, encoding='utf-8')
    
    def _update_gateway_config(self, config_file: Path):
        """更新API网关配置"""
        content = config_file.read_text(encoding='utf-8')
        
        # 更新MongoDB URL
        mongodb_url = f"mongodb://{self.config['mongodb']['app_user']}:{self.config['mongodb']['app_password']}@{self.config['mongodb']['host']}:{self.config['mongodb']['port']}/{self.config['mongodb']['database']}"
        content = content.replace(
            'mongodb_url: str = "mongodb://localhost:27018"',
            f'mongodb_url: str = "{mongodb_url}"'
        )
        
        # 更新Redis URL
        redis_url = f"redis://:{self.config['redis']['password']}@{self.config['redis']['host']}:{self.config['redis']['port']}/0"
        content = content.replace(
            'redis_url: str = "redis://localhost:6382/0"',
            f'redis_url: str = "{redis_url}"'
        )
        
        # 更新Neo4j配置
        content = content.replace(
            'neo4j_password: str = "looma_password"',
            f'neo4j_password: str = "{self.config["neo4j"]["password"]}"'
        )
        
        config_file.write_text(content, encoding='utf-8')
    
    def test_all_connections(self) -> Dict[str, bool]:
        """测试所有数据库连接"""
        self.log("开始测试所有数据库连接...")
        
        results = {}
        
        # 测试MongoDB
        self.log("测试MongoDB连接...")
        results["mongodb"] = self.check_database_connection("mongodb")
        
        # 测试Redis
        self.log("测试Redis连接...")
        results["redis"] = self.check_database_connection("redis")
        
        # 测试Neo4j
        self.log("测试Neo4j连接...")
        results["neo4j"] = self.check_database_connection("neo4j")
        
        # 输出结果
        self.log("数据库连接测试结果:")
        for db_type, success in results.items():
            status = "✅ 成功" if success else "❌ 失败"
            self.log(f"  {db_type.upper()}: {status}")
        
        return results
    
    def run_full_configuration(self) -> bool:
        """运行完整的数据库认证配置"""
        self.log("开始数据库认证配置流程...")
        
        success_count = 0
        total_count = 3
        
        # 配置MongoDB认证
        if self.configure_mongodb_auth():
            success_count += 1
        
        # 配置Redis认证
        if self.configure_redis_auth():
            success_count += 1
        
        # 配置Neo4j认证
        if self.configure_neo4j_auth():
            success_count += 1
        
        # 更新API服务配置
        if self.update_api_service_configs():
            self.log("API服务配置更新完成")
        
        # 测试所有连接
        test_results = self.test_all_connections()
        
        # 输出总结
        self.log(f"数据库认证配置完成: {success_count}/{total_count} 成功")
        
        if success_count == total_count:
            self.log("🎉 所有数据库认证配置成功！", "SUCCESS")
            return True
        else:
            self.log("⚠️ 部分数据库认证配置失败，请检查日志", "WARNING")
            return False


def main():
    """主函数"""
    print("=" * 60)
    print("🔐 数据库认证配置管理器")
    print("=" * 60)
    
    manager = DatabaseAuthConfigManager()
    
    try:
        success = manager.run_full_configuration()
        
        if success:
            print("\n✅ 数据库认证配置完成！")
            print("现在可以重新启动API服务进行测试。")
        else:
            print("\n❌ 数据库认证配置失败！")
            print("请检查错误日志并重试。")
            sys.exit(1)
            
    except KeyboardInterrupt:
        print("\n⚠️ 用户中断操作")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ 配置过程中发生错误: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
