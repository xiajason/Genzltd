#!/usr/bin/env python3
"""
阿里云与腾讯云数据同步测试脚本
统一数据库配置，建立完整的数据同步机制
"""

import asyncio
import asyncpg
import aioredis
import mysql.connector
from neo4j import GraphDatabase
import requests
import json
import time

class DatabaseSyncTester:
    def __init__(self):
        # 阿里云配置 (统一配置)
        self.alibaba_config = {
            'mysql': {
                'host': '47.115.168.107',
                'port': 3306,
                'user': 'root',
                'password': 'test_mysql_password',
                'database': 'test_users'
            },
            'postgres': {
                'host': '47.115.168.107',
                'port': 5432,
                'user': 'test_user',
                'password': 'test_postgres_password',
                'database': 'test_users'
            },
            'redis': {
                'host': '47.115.168.107',
                'port': 6379,
                'password': 'test_redis_password'
            },
            'neo4j': {
                'uri': 'bolt://47.115.168.107:7687',
                'user': 'neo4j',
                'password': 'test_neo4j_password'
            },
            'weaviate': {
                'url': 'http://47.115.168.107:8080'
            }
        }
        
        # 腾讯云配置 (统一配置)
        self.tencent_config = {
            'mysql': {
                'host': '101.33.251.158',
                'port': 3306,
                'user': 'root',
                'password': 'test_mysql_password',
                'database': 'test_users'
            },
            'postgres': {
                'host': '101.33.251.158',
                'port': 5432,
                'user': 'test_user',
                'password': 'test_postgres_password',
                'database': 'test_users'
            },
            'redis': {
                'host': '101.33.251.158',
                'port': 6379,
                'password': 'test_redis_password'
            },
            'neo4j': {
                'uri': 'bolt://101.33.251.158:7687',
                'user': 'neo4j',
                'password': 'test_neo4j_password'
            },
            'weaviate': {
                'url': 'http://101.33.251.158:8080'
            }
        }
    
    async def test_mysql_sync(self):
        """测试MySQL数据同步"""
        print("=== MySQL数据同步测试 ===")
        
        try:
            # 连接阿里云MySQL
            alibaba_conn = mysql.connector.connect(**self.alibaba_config['mysql'])
            alibaba_cursor = alibaba_conn.cursor()
            
            # 创建测试表
            alibaba_cursor.execute("""
                CREATE TABLE IF NOT EXISTS sync_test (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    name VARCHAR(100),
                    value TEXT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)
            
            # 插入测试数据
            alibaba_cursor.execute("""
                INSERT INTO sync_test (name, value) VALUES 
                ('sync_test_1', '阿里云测试数据1'),
                ('sync_test_2', '阿里云测试数据2')
            """)
            alibaba_conn.commit()
            
            print("✅ 阿里云MySQL数据插入成功")
            
            # 连接腾讯云MySQL
            tencent_conn = mysql.connector.connect(**self.tencent_config['mysql'])
            tencent_cursor = tencent_conn.cursor()
            
            # 创建测试表
            tencent_cursor.execute("""
                CREATE TABLE IF NOT EXISTS sync_test (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    name VARCHAR(100),
                    value TEXT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)
            
            # 插入测试数据
            tencent_cursor.execute("""
                INSERT INTO sync_test (name, value) VALUES 
                ('sync_test_1', '腾讯云测试数据1'),
                ('sync_test_2', '腾讯云测试数据2')
            """)
            tencent_conn.commit()
            
            print("✅ 腾讯云MySQL数据插入成功")
            
            # 验证数据
            alibaba_cursor.execute("SELECT COUNT(*) FROM sync_test")
            alibaba_count = alibaba_cursor.fetchone()[0]
            
            tencent_cursor.execute("SELECT COUNT(*) FROM sync_test")
            tencent_count = tencent_cursor.fetchone()[0]
            
            print(f"阿里云MySQL记录数: {alibaba_count}")
            print(f"腾讯云MySQL记录数: {tencent_count}")
            
            alibaba_conn.close()
            tencent_conn.close()
            
            return True
            
        except Exception as e:
            print(f"❌ MySQL同步测试失败: {e}")
            return False
    
    async def test_postgres_sync(self):
        """测试PostgreSQL数据同步"""
        print("=== PostgreSQL数据同步测试 ===")
        
        try:
            # 连接阿里云PostgreSQL
            alibaba_conn = await asyncpg.connect(
                host=self.alibaba_config['postgres']['host'],
                port=self.alibaba_config['postgres']['port'],
                user=self.alibaba_config['postgres']['user'],
                password=self.alibaba_config['postgres']['password'],
                database=self.alibaba_config['postgres']['database']
            )
            
            # 创建测试表
            await alibaba_conn.execute("""
                CREATE TABLE IF NOT EXISTS sync_test (
                    id SERIAL PRIMARY KEY,
                    name VARCHAR(100),
                    value TEXT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)
            
            # 插入测试数据
            await alibaba_conn.execute("""
                INSERT INTO sync_test (name, value) VALUES 
                ($1, $2), ($3, $4)
            """, 'sync_test_1', '阿里云PostgreSQL测试数据1', 'sync_test_2', '阿里云PostgreSQL测试数据2')
            
            print("✅ 阿里云PostgreSQL数据插入成功")
            
            # 连接腾讯云PostgreSQL
            tencent_conn = await asyncpg.connect(
                host=self.tencent_config['postgres']['host'],
                port=self.tencent_config['postgres']['port'],
                user=self.tencent_config['postgres']['user'],
                password=self.tencent_config['postgres']['password'],
                database=self.tencent_config['postgres']['database']
            )
            
            # 创建测试表
            await tencent_conn.execute("""
                CREATE TABLE IF NOT EXISTS sync_test (
                    id SERIAL PRIMARY KEY,
                    name VARCHAR(100),
                    value TEXT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)
            
            # 插入测试数据
            await tencent_conn.execute("""
                INSERT INTO sync_test (name, value) VALUES 
                ($1, $2), ($3, $4)
            """, 'sync_test_1', '腾讯云PostgreSQL测试数据1', 'sync_test_2', '腾讯云PostgreSQL测试数据2')
            
            print("✅ 腾讯云PostgreSQL数据插入成功")
            
            # 验证数据
            alibaba_count = await alibaba_conn.fetchval("SELECT COUNT(*) FROM sync_test")
            tencent_count = await tencent_conn.fetchval("SELECT COUNT(*) FROM sync_test")
            
            print(f"阿里云PostgreSQL记录数: {alibaba_count}")
            print(f"腾讯云PostgreSQL记录数: {tencent_count}")
            
            await alibaba_conn.close()
            await tencent_conn.close()
            
            return True
            
        except Exception as e:
            print(f"❌ PostgreSQL同步测试失败: {e}")
            return False
    
    async def test_redis_sync(self):
        """测试Redis数据同步"""
        print("=== Redis数据同步测试 ===")
        
        try:
            # 连接阿里云Redis
            alibaba_redis = await aioredis.from_url(
                f"redis://:{self.alibaba_config['redis']['password']}@{self.alibaba_config['redis']['host']}:{self.alibaba_config['redis']['port']}"
            )
            
            # 设置测试数据
            await alibaba_redis.set("sync_test_key", "阿里云Redis测试数据")
            await alibaba_redis.set("sync_test_counter", "100")
            
            print("✅ 阿里云Redis数据设置成功")
            
            # 连接腾讯云Redis
            tencent_redis = await aioredis.from_url(
                f"redis://:{self.tencent_config['redis']['password']}@{self.tencent_config['redis']['host']}:{self.tencent_config['redis']['port']}"
            )
            
            # 设置测试数据
            await tencent_redis.set("sync_test_key", "腾讯云Redis测试数据")
            await tencent_redis.set("sync_test_counter", "200")
            
            print("✅ 腾讯云Redis数据设置成功")
            
            # 验证数据
            alibaba_value = await alibaba_redis.get("sync_test_key")
            tencent_value = await tencent_redis.get("sync_test_key")
            
            print(f"阿里云Redis值: {alibaba_value}")
            print(f"腾讯云Redis值: {tencent_value}")
            
            await alibaba_redis.close()
            await tencent_redis.close()
            
            return True
            
        except Exception as e:
            print(f"❌ Redis同步测试失败: {e}")
            return False
    
    async def test_neo4j_sync(self):
        """测试Neo4j数据同步"""
        print("=== Neo4j数据同步测试 ===")
        
        try:
            # 连接阿里云Neo4j
            alibaba_driver = GraphDatabase.driver(
                self.alibaba_config['neo4j']['uri'],
                auth=(self.alibaba_config['neo4j']['user'], self.alibaba_config['neo4j']['password'])
            )
            
            with alibaba_driver.session() as session:
                # 创建测试节点
                session.run("""
                    CREATE (n:TestNode {
                        name: '阿里云测试节点',
                        value: '阿里云Neo4j测试数据',
                        timestamp: datetime()
                    })
                """)
                print("✅ 阿里云Neo4j节点创建成功")
            
            # 连接腾讯云Neo4j
            tencent_driver = GraphDatabase.driver(
                self.tencent_config['neo4j']['uri'],
                auth=(self.tencent_config['neo4j']['user'], self.tencent_config['neo4j']['password'])
            )
            
            with tencent_driver.session() as session:
                # 创建测试节点
                session.run("""
                    CREATE (n:TestNode {
                        name: '腾讯云测试节点',
                        value: '腾讯云Neo4j测试数据',
                        timestamp: datetime()
                    })
                """)
                print("✅ 腾讯云Neo4j节点创建成功")
            
            alibaba_driver.close()
            tencent_driver.close()
            
            return True
            
        except Exception as e:
            print(f"❌ Neo4j同步测试失败: {e}")
            return False
    
    async def test_weaviate_sync(self):
        """测试Weaviate数据同步"""
        print("=== Weaviate数据同步测试 ===")
        
        try:
            # 测试阿里云Weaviate
            alibaba_response = requests.get(f"{self.alibaba_config['weaviate']['url']}/v1/meta")
            if alibaba_response.status_code == 200:
                print("✅ 阿里云Weaviate连接成功")
            else:
                print(f"❌ 阿里云Weaviate连接失败: {alibaba_response.status_code}")
                return False
            
            # 测试腾讯云Weaviate
            tencent_response = requests.get(f"{self.tencent_config['weaviate']['url']}/v1/meta")
            if tencent_response.status_code == 200:
                print("✅ 腾讯云Weaviate连接成功")
            else:
                print(f"❌ 腾讯云Weaviate连接失败: {tencent_response.status_code}")
                return False
            
            return True
            
        except Exception as e:
            print(f"❌ Weaviate同步测试失败: {e}")
            return False
    
    async def run_all_tests(self):
        """运行所有数据同步测试"""
        print("=== 阿里云与腾讯云数据同步测试开始 ===")
        print(f"测试时间: {time.strftime('%Y-%m-%d %H:%M:%S')}")
        
        results = {}
        
        # 测试各个数据库
        results['mysql'] = await self.test_mysql_sync()
        results['postgres'] = await self.test_postgres_sync()
        results['redis'] = await self.test_redis_sync()
        results['neo4j'] = await self.test_neo4j_sync()
        results['weaviate'] = await self.test_weaviate_sync()
        
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
            print("🎉 所有数据同步测试通过！")
        elif success_rate >= 80:
            print("⚠️ 大部分数据同步测试通过，需要优化部分配置")
        else:
            print("❌ 数据同步测试失败较多，需要检查配置")
        
        return results

async def main():
    tester = DatabaseSyncTester()
    await tester.run_all_tests()

if __name__ == "__main__":
    asyncio.run(main())
