#!/usr/bin/env python3
"""
简化的阿里云与腾讯云数据同步测试脚本
使用基础依赖，避免复杂的编译问题
"""

import subprocess
import time
import json

class SimpleSyncTester:
    def __init__(self):
        # 阿里云配置
        self.alibaba_host = "47.115.168.107"
        # 腾讯云配置  
        self.tencent_host = "101.33.251.158"
        
    def test_mysql_connection(self):
        """测试MySQL连接"""
        print("=== MySQL连接测试 ===")
        
        try:
            # 测试阿里云MySQL
            result = subprocess.run([
                "mysql", "-h", self.alibaba_host, "-P", "3306", 
                "-u", "root", "-ptest_mysql_password", "-e", "SHOW DATABASES;"
            ], capture_output=True, text=True, timeout=10)
            
            if result.returncode == 0:
                print("✅ 阿里云MySQL连接成功")
                print(f"数据库列表: {result.stdout}")
            else:
                print(f"❌ 阿里云MySQL连接失败: {result.stderr}")
                return False
                
        except Exception as e:
            print(f"❌ 阿里云MySQL连接异常: {e}")
            return False
            
        try:
            # 测试腾讯云MySQL
            result = subprocess.run([
                "mysql", "-h", self.tencent_host, "-P", "3306",
                "-u", "root", "-ptest_mysql_password", "-e", "SHOW DATABASES;"
            ], capture_output=True, text=True, timeout=10)
            
            if result.returncode == 0:
                print("✅ 腾讯云MySQL连接成功")
                print(f"数据库列表: {result.stdout}")
            else:
                print(f"❌ 腾讯云MySQL连接失败: {result.stderr}")
                return False
                
        except Exception as e:
            print(f"❌ 腾讯云MySQL连接异常: {e}")
            return False
            
        return True
    
    def test_postgres_connection(self):
        """测试PostgreSQL连接"""
        print("=== PostgreSQL连接测试 ===")
        
        try:
            # 测试阿里云PostgreSQL
            result = subprocess.run([
                "psql", "-h", self.alibaba_host, "-p", "5432",
                "-U", "test_user", "-d", "test_users", "-c", "\\l"
            ], capture_output=True, text=True, timeout=10, 
            env={"PGPASSWORD": "test_postgres_password"})
            
            if result.returncode == 0:
                print("✅ 阿里云PostgreSQL连接成功")
                print(f"数据库列表: {result.stdout}")
            else:
                print(f"❌ 阿里云PostgreSQL连接失败: {result.stderr}")
                return False
                
        except Exception as e:
            print(f"❌ 阿里云PostgreSQL连接异常: {e}")
            return False
            
        try:
            # 测试腾讯云PostgreSQL
            result = subprocess.run([
                "psql", "-h", self.tencent_host, "-p", "5432",
                "-U", "test_user", "-d", "test_users", "-c", "\\l"
            ], capture_output=True, text=True, timeout=10,
            env={"PGPASSWORD": "test_postgres_password"})
            
            if result.returncode == 0:
                print("✅ 腾讯云PostgreSQL连接成功")
                print(f"数据库列表: {result.stdout}")
            else:
                print(f"❌ 腾讯云PostgreSQL连接失败: {result.stderr}")
                return False
                
        except Exception as e:
            print(f"❌ 腾讯云PostgreSQL连接异常: {e}")
            return False
            
        return True
    
    def test_redis_connection(self):
        """测试Redis连接"""
        print("=== Redis连接测试 ===")
        
        try:
            # 测试阿里云Redis
            result = subprocess.run([
                "redis-cli", "-h", self.alibaba_host, "-p", "6379",
                "-a", "test_redis_password", "PING"
            ], capture_output=True, text=True, timeout=10)
            
            if result.returncode == 0 and "PONG" in result.stdout:
                print("✅ 阿里云Redis连接成功")
            else:
                print(f"❌ 阿里云Redis连接失败: {result.stderr}")
                return False
                
        except Exception as e:
            print(f"❌ 阿里云Redis连接异常: {e}")
            return False
            
        try:
            # 测试腾讯云Redis
            result = subprocess.run([
                "redis-cli", "-h", self.tencent_host, "-p", "6379",
                "-a", "test_redis_password", "PING"
            ], capture_output=True, text=True, timeout=10)
            
            if result.returncode == 0 and "PONG" in result.stdout:
                print("✅ 腾讯云Redis连接成功")
            else:
                print(f"❌ 腾讯云Redis连接失败: {result.stderr}")
                return False
                
        except Exception as e:
            print(f"❌ 腾讯云Redis连接异常: {e}")
            return False
            
        return True
    
    def test_neo4j_connection(self):
        """测试Neo4j连接"""
        print("=== Neo4j连接测试 ===")
        
        try:
            # 测试阿里云Neo4j
            result = subprocess.run([
                "curl", "-s", f"http://{self.alibaba_host}:7474"
            ], capture_output=True, text=True, timeout=10)
            
            if result.returncode == 0:
                print("✅ 阿里云Neo4j连接成功")
            else:
                print(f"❌ 阿里云Neo4j连接失败: {result.stderr}")
                return False
                
        except Exception as e:
            print(f"❌ 阿里云Neo4j连接异常: {e}")
            return False
            
        try:
            # 测试腾讯云Neo4j
            result = subprocess.run([
                "curl", "-s", f"http://{self.tencent_host}:7474"
            ], capture_output=True, text=True, timeout=10)
            
            if result.returncode == 0:
                print("✅ 腾讯云Neo4j连接成功")
            else:
                print(f"❌ 腾讯云Neo4j连接失败: {result.stderr}")
                return False
                
        except Exception as e:
            print(f"❌ 腾讯云Neo4j连接异常: {e}")
            return False
            
        return True
    
    def test_weaviate_connection(self):
        """测试Weaviate连接"""
        print("=== Weaviate连接测试 ===")
        
        try:
            # 测试阿里云Weaviate
            result = subprocess.run([
                "curl", "-s", f"http://{self.alibaba_host}:8080/v1/meta"
            ], capture_output=True, text=True, timeout=10)
            
            if result.returncode == 0:
                print("✅ 阿里云Weaviate连接成功")
            else:
                print(f"❌ 阿里云Weaviate连接失败: {result.stderr}")
                return False
                
        except Exception as e:
            print(f"❌ 阿里云Weaviate连接异常: {e}")
            return False
            
        try:
            # 测试腾讯云Weaviate
            result = subprocess.run([
                "curl", "-s", f"http://{self.tencent_host}:8080/v1/meta"
            ], capture_output=True, text=True, timeout=10)
            
            if result.returncode == 0:
                print("✅ 腾讯云Weaviate连接成功")
            else:
                print(f"❌ 腾讯云Weaviate连接失败: {result.stderr}")
                return False
                
        except Exception as e:
            print(f"❌ 腾讯云Weaviate连接异常: {e}")
            return False
            
        return True
    
    def run_all_tests(self):
        """运行所有连接测试"""
        print("=== 阿里云与腾讯云数据库连接测试开始 ===")
        print(f"测试时间: {time.strftime('%Y-%m-%d %H:%M:%S')}")
        
        results = {}
        
        # 测试各个数据库
        results['mysql'] = self.test_mysql_connection()
        results['postgres'] = self.test_postgres_connection()
        results['redis'] = self.test_redis_connection()
        results['neo4j'] = self.test_neo4j_connection()
        results['weaviate'] = self.test_weaviate_connection()
        
        # 统计结果
        total_tests = len(results)
        passed_tests = sum(1 for result in results.values() if result)
        success_rate = (passed_tests / total_tests) * 100
        
        print("\n=== 测试结果统计 ===")
        for db, result in results.items():
            status = "✅ 通过" if result else "❌ 失败"
            print(f"{db.upper()}: {status}")
        
        print(f"\n总测试数: {total_tests}")
        print(f"通过测试: {passed_tests}")
        print(f"成功率: {success_rate:.1f}%")
        
        if success_rate == 100:
            print("🎉 所有数据库连接测试通过！")
        elif success_rate >= 80:
            print("⚠️ 大部分数据库连接测试通过，需要优化部分配置")
        else:
            print("❌ 数据库连接测试失败较多，需要检查配置")
        
        return results

def main():
    tester = SimpleSyncTester()
    tester.run_all_tests()

if __name__ == "__main__":
    main()
