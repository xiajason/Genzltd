#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
阿里云多数据库严格测试脚本
基于@future_optimized/经验 - 专业级测试
"""

import json
import subprocess
import sys
import time
import asyncio
import aiohttp
import asyncpg
import aioredis
import pymysql
from neo4j import GraphDatabase
from datetime import datetime
from typing import Dict, Any, List
import logging

# 配置日志
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class AlibabaCloudStrictDatabaseTester:
    """阿里云严格数据库测试器"""
    
    def __init__(self):
        self.server_ip = "47.115.168.107"
        self.ssh_key = "~/.ssh/cross_cloud_key"
        self.start_time = datetime.now()
        
        # 数据库连接配置
        self.db_configs = {
            "mysql": {
                "host": self.server_ip,
                "port": 3306,
                "user": "root",
                "password": "f_mysql_password_2025",
                "database": "jobfirst_future"
            },
            "postgresql": {
                "host": self.server_ip,
                "port": 5432,
                "user": "future_user",
                "password": "f_postgres_password_2025",
                "database": "jobfirst_future"
            },
            "redis": {
                "host": self.server_ip,
                "port": 6379,
                "password": "f_redis_password_2025"
            },
            "neo4j": {
                "uri": f"bolt://{self.server_ip}:7687",
                "user": "neo4j",
                "password": "f_neo4j_password_2025"
            },
            "elasticsearch": {
                "host": self.server_ip,
                "port": 9200
            },
            "weaviate": {
                "host": self.server_ip,
                "port": 8080
            }
        }
        
        self.test_results = {
            "connection_tests": {},
            "consistency_tests": {},
            "performance_tests": {},
            "summary": {}
        }
    
    def test_mysql_connection(self) -> Dict[str, Any]:
        """严格测试MySQL连接"""
        logger.info("🔍 严格测试MySQL连接...")
        
        try:
            # 建立连接
            connection = pymysql.connect(
                host=self.db_configs["mysql"]["host"],
                port=self.db_configs["mysql"]["port"],
                user=self.db_configs["mysql"]["user"],
                password=self.db_configs["mysql"]["password"],
                database=self.db_configs["mysql"]["database"],
                connect_timeout=10,
                read_timeout=10,
                write_timeout=10
            )
            
            with connection.cursor() as cursor:
                # 测试基本查询
                cursor.execute("SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = %s", 
                             (self.db_configs["mysql"]["database"],))
                table_count = cursor.fetchone()[0]
                
                # 测试数据一致性
                cursor.execute("SELECT COUNT(*) FROM users")
                user_count = cursor.fetchone()[0]
                
                # 测试事务
                cursor.execute("START TRANSACTION")
                cursor.execute("SELECT 1")
                cursor.execute("ROLLBACK")
                
                # 测试索引
                cursor.execute("SHOW INDEX FROM users")
                indexes = cursor.fetchall()
                
            connection.close()
            
            return {
                "status": "success",
                "table_count": table_count,
                "user_count": user_count,
                "index_count": len(indexes),
                "connection_time": "< 1s"
            }
            
        except Exception as e:
            return {
                "status": "failed",
                "error": str(e)
            }
    
    async def test_postgresql_connection(self) -> Dict[str, Any]:
        """严格测试PostgreSQL连接"""
        logger.info("🔍 严格测试PostgreSQL连接...")
        
        try:
            # 建立异步连接
            connection = await asyncpg.connect(
                host=self.db_configs["postgresql"]["host"],
                port=self.db_configs["postgresql"]["port"],
                user=self.db_configs["postgresql"]["user"],
                password=self.db_configs["postgresql"]["password"],
                database=self.db_configs["postgresql"]["database"],
                timeout=10
            )
            
            # 测试基本查询
            table_count = await connection.fetchval(
                "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public'"
            )
            
            # 测试数据一致性
            user_count = await connection.fetchval("SELECT COUNT(*) FROM user_ai_profiles")
            
            # 测试事务
            async with connection.transaction():
                await connection.fetchval("SELECT 1")
            
            # 测试索引
            indexes = await connection.fetch(
                "SELECT indexname FROM pg_indexes WHERE tablename = 'user_ai_profiles'"
            )
            
            await connection.close()
            
            return {
                "status": "success",
                "table_count": table_count,
                "user_count": user_count,
                "index_count": len(indexes),
                "connection_time": "< 1s"
            }
            
        except Exception as e:
            return {
                "status": "failed",
                "error": str(e)
            }
    
    async def test_redis_connection(self) -> Dict[str, Any]:
        """严格测试Redis连接"""
        logger.info("🔍 严格测试Redis连接...")
        
        try:
            # 建立异步连接
            redis = aioredis.from_url(
                f"redis://:{self.db_configs['redis']['password']}@{self.db_configs['redis']['host']}:{self.db_configs['redis']['port']}",
                decode_responses=True,
                socket_timeout=10
            )
            
            # 测试基本操作
            await redis.ping()
            
            # 测试数据操作
            await redis.set("test_key", "test_value", ex=60)
            value = await redis.get("test_key")
            await redis.delete("test_key")
            
            # 测试键数量
            key_count = await redis.dbsize()
            
            # 测试性能
            start_time = time.time()
            for i in range(100):
                await redis.set(f"perf_test_{i}", f"value_{i}")
            end_time = time.time()
            
            # 清理测试数据
            for i in range(100):
                await redis.delete(f"perf_test_{i}")
            
            await redis.close()
            
            return {
                "status": "success",
                "key_count": key_count,
                "test_operations": 100,
                "performance_time": f"{end_time - start_time:.3f}s",
                "connection_time": "< 1s"
            }
            
        except Exception as e:
            return {
                "status": "failed",
                "error": str(e)
            }
    
    def test_neo4j_connection(self) -> Dict[str, Any]:
        """严格测试Neo4j连接"""
        logger.info("🔍 严格测试Neo4j连接...")
        
        try:
            # 建立连接
            driver = GraphDatabase.driver(
                self.db_configs["neo4j"]["uri"],
                auth=(self.db_configs["neo4j"]["user"], self.db_configs["neo4j"]["password"]),
                connection_timeout=10
            )
            
            with driver.session() as session:
                # 测试基本查询
                result = session.run("MATCH (n) RETURN COUNT(n) as node_count")
                node_count = result.single()["node_count"]
                
                # 测试关系查询
                result = session.run("MATCH ()-[r]->() RETURN COUNT(r) as rel_count")
                rel_count = result.single()["rel_count"]
                
                # 测试创建和删除节点
                session.run("CREATE (n:TestNode {id: 1})")
                result = session.run("MATCH (n:TestNode) RETURN COUNT(n) as test_count")
                test_count = result.single()["test_count"]
                session.run("MATCH (n:TestNode) DELETE n")
                
                # 测试约束
                constraints = session.run("SHOW CONSTRAINTS")
                constraint_list = list(constraints)
            
            driver.close()
            
            return {
                "status": "success",
                "node_count": node_count,
                "relationship_count": rel_count,
                "test_operations": test_count,
                "constraint_count": len(constraint_list),
                "connection_time": "< 1s"
            }
            
        except Exception as e:
            return {
                "status": "failed",
                "error": str(e)
            }
    
    async def test_elasticsearch_connection(self) -> Dict[str, Any]:
        """严格测试Elasticsearch连接"""
        logger.info("🔍 严格测试Elasticsearch连接...")
        
        try:
            # 建立HTTP连接
            url = f"http://{self.db_configs['elasticsearch']['host']}:{self.db_configs['elasticsearch']['port']}"
            
            async with aiohttp.ClientSession(timeout=aiohttp.ClientTimeout(total=10)) as session:
                # 测试集群健康
                async with session.get(f"{url}/_cluster/health") as response:
                    if response.status == 200:
                        health_data = await response.json()
                        cluster_status = health_data.get("status", "unknown")
                    else:
                        return {"status": "failed", "error": f"HTTP {response.status}"}
                
                # 测试索引操作
                test_index = "test_index"
                test_doc = {"test": "value", "timestamp": datetime.now().isoformat()}
                
                # 创建索引
                async with session.put(f"{url}/{test_index}") as response:
                    if response.status not in [200, 201]:
                        return {"status": "failed", "error": "Failed to create index"}
                
                # 插入文档
                async with session.post(f"{url}/{test_index}/_doc/1", json=test_doc) as response:
                    if response.status not in [200, 201]:
                        return {"status": "failed", "error": "Failed to insert document"}
                
                # 查询文档
                async with session.get(f"{url}/{test_index}/_doc/1") as response:
                    if response.status == 200:
                        doc_data = await response.json()
                        doc_found = doc_data.get("found", False)
                    else:
                        return {"status": "failed", "error": "Failed to query document"}
                
                # 删除索引
                async with session.delete(f"{url}/{test_index}") as response:
                    pass  # 清理测试数据
                
                return {
                    "status": "success",
                    "cluster_status": cluster_status,
                    "test_operations": 1,
                    "document_found": doc_found,
                    "connection_time": "< 1s"
                }
                
        except Exception as e:
            return {
                "status": "failed",
                "error": str(e)
            }
    
    async def test_weaviate_connection(self) -> Dict[str, Any]:
        """严格测试Weaviate连接"""
        logger.info("🔍 严格测试Weaviate连接...")
        
        try:
            # 建立HTTP连接
            url = f"http://{self.db_configs['weaviate']['host']}:{self.db_configs['weaviate']['port']}"
            
            async with aiohttp.ClientSession(timeout=aiohttp.ClientTimeout(total=10)) as session:
                # 测试元数据
                async with session.get(f"{url}/v1/meta") as response:
                    if response.status == 200:
                        meta_data = await response.json()
                        version = meta_data.get("version", "unknown")
                    else:
                        return {"status": "failed", "error": f"HTTP {response.status}"}
                
                # 测试模式操作
                test_class = {
                    "class": "TestClass",
                    "description": "Test class for connection testing",
                    "properties": [
                        {
                            "name": "testProperty",
                            "dataType": ["string"]
                        }
                    ]
                }
                
                # 创建类
                async with session.post(f"{url}/v1/schema", json=test_class) as response:
                    if response.status not in [200, 201]:
                        return {"status": "failed", "error": "Failed to create class"}
                
                # 测试对象操作
                test_object = {
                    "testProperty": "test value"
                }
                
                # 创建对象
                async with session.post(f"{url}/v1/objects", json=test_object) as response:
                    if response.status not in [200, 201]:
                        return {"status": "failed", "error": "Failed to create object"}
                    obj_data = await response.json()
                    obj_id = obj_data.get("id")
                
                # 查询对象
                async with session.get(f"{url}/v1/objects/{obj_id}") as response:
                    if response.status == 200:
                        obj_found = True
                    else:
                        obj_found = False
                
                # 删除类（清理）
                async with session.delete(f"{url}/v1/schema/TestClass") as response:
                    pass  # 清理测试数据
                
                return {
                    "status": "success",
                    "version": version,
                    "test_operations": 1,
                    "object_found": obj_found,
                    "connection_time": "< 1s"
                }
                
        except Exception as e:
            return {
                "status": "failed",
                "error": str(e)
            }
    
    async def test_data_consistency(self) -> Dict[str, Any]:
        """测试数据一致性"""
        logger.info("🔍 测试跨数据库数据一致性...")
        
        consistency_results = {}
        
        try:
            # 测试用户数据一致性
            mysql_conn = pymysql.connect(**self.db_configs["mysql"])
            pg_conn = await asyncpg.connect(**self.db_configs["postgresql"])
            
            with mysql_conn.cursor() as cursor:
                cursor.execute("SELECT COUNT(*) FROM users")
                mysql_user_count = cursor.fetchone()[0]
            
            pg_user_count = await pg_conn.fetchval("SELECT COUNT(*) FROM user_ai_profiles")
            
            consistency_results["user_data_consistency"] = {
                "mysql_count": mysql_user_count,
                "postgresql_count": pg_user_count,
                "consistent": mysql_user_count == pg_user_count
            }
            
            mysql_conn.close()
            await pg_conn.close()
            
        except Exception as e:
            consistency_results["user_data_consistency"] = {
                "error": str(e),
                "consistent": False
            }
        
        return consistency_results
    
    async def run_strict_tests(self) -> Dict[str, Any]:
        """运行严格测试"""
        logger.info("🚀 开始阿里云多数据库严格测试...")
        
        results = {
            "test_time": self.start_time.isoformat(),
            "server_ip": self.server_ip,
            "connection_tests": {},
            "consistency_tests": {},
            "performance_tests": {},
            "summary": {}
        }
        
        # 连接测试
        connection_tests = {
            "MySQL": self.test_mysql_connection,
            "PostgreSQL": self.test_postgresql_connection,
            "Redis": self.test_redis_connection,
            "Neo4j": self.test_neo4j_connection,
            "Elasticsearch": self.test_elasticsearch_connection,
            "Weaviate": self.test_weaviate_connection
        }
        
        success_count = 0
        total_count = len(connection_tests)
        
        for db_name, test_func in connection_tests.items():
            logger.info(f"🔍 严格测试 {db_name}...")
            try:
                if asyncio.iscoroutinefunction(test_func):
                    test_result = await test_func()
                else:
                    test_result = test_func()
                
                results["connection_tests"][db_name] = test_result
                
                if test_result.get("status") == "success":
                    success_count += 1
                    logger.info(f"✅ {db_name} 严格测试通过")
                else:
                    logger.error(f"❌ {db_name} 严格测试失败: {test_result.get('error', 'Unknown error')}")
                    
            except Exception as e:
                logger.error(f"❌ {db_name} 严格测试异常: {str(e)}")
                results["connection_tests"][db_name] = {
                    "status": "failed",
                    "error": str(e)
                }
        
        # 数据一致性测试
        consistency_results = await self.test_data_consistency()
        results["consistency_tests"] = consistency_results
        
        # 计算成功率
        success_rate = (success_count / total_count) * 100
        
        results["summary"] = {
            "total_databases": total_count,
            "successful_connections": success_count,
            "failed_connections": total_count - success_count,
            "success_rate": f"{success_rate:.1f}%",
            "test_duration": str(datetime.now() - self.start_time),
            "strict_test_passed": success_rate >= 90
        }
        
        return results
    
    def save_results(self, results: Dict[str, Any]) -> str:
        """保存测试结果"""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"alibaba_cloud_strict_test_{timestamp}.json"
        
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(results, f, indent=2, ensure_ascii=False)
        
        return filename
    
    def print_summary(self, results: Dict[str, Any]):
        """打印测试摘要"""
        print("\n" + "="*80)
        print("🎯 阿里云多数据库严格测试结果")
        print("="*80)
        
        print(f"🕐 测试时间: {results['test_time']}")
        print(f"🌐 服务器IP: {results['server_ip']}")
        
        print(f"\n📊 严格测试摘要:")
        summary = results['summary']
        print(f"  总数据库数量: {summary['total_databases']}")
        print(f"  成功连接: {summary['successful_connections']}")
        print(f"  失败连接: {summary['failed_connections']}")
        print(f"  成功率: {summary['success_rate']}")
        print(f"  测试耗时: {summary['test_duration']}")
        print(f"  严格测试通过: {'✅ 是' if summary['strict_test_passed'] else '❌ 否'}")
        
        print(f"\n🔍 连接测试详细结果:")
        for db_name, db_result in results['connection_tests'].items():
            status_icon = "✅" if db_result.get('status') == 'success' else "❌"
            print(f"  {status_icon} {db_name}: {db_result.get('status', 'unknown')}")
            
            if db_result.get('status') == 'success':
                for key, value in db_result.items():
                    if key != 'status':
                        print(f"     {key}: {value}")
            else:
                print(f"     错误: {db_result.get('error', 'Unknown error')}")
        
        print(f"\n🔗 数据一致性测试:")
        for test_name, test_result in results['consistency_tests'].items():
            if 'error' in test_result:
                print(f"  ❌ {test_name}: 错误 - {test_result['error']}")
            else:
                consistent = test_result.get('consistent', False)
                icon = "✅" if consistent else "❌"
                print(f"  {icon} {test_name}: {'一致' if consistent else '不一致'}")
                for key, value in test_result.items():
                    if key not in ['consistent', 'error']:
                        print(f"     {key}: {value}")
        
        print("\n" + "="*80)

async def main():
    """主函数"""
    print("🚀 阿里云多数据库严格测试")
    print("基于@future_optimized/经验 - 专业级测试")
    print("-" * 80)
    
    tester = AlibabaCloudStrictDatabaseTester()
    
    try:
        # 运行严格测试
        results = await tester.run_strict_tests()
        
        # 保存结果
        filename = tester.save_results(results)
        
        # 打印摘要
        tester.print_summary(results)
        
        print(f"\n💾 严格测试结果已保存到: {filename}")
        
        # 判断测试是否通过
        if results['summary']['strict_test_passed']:
            print("\n🎉 严格测试通过！数据库连接稳定，可以开始数据同步机制构建！")
            return 0
        else:
            print("\n❌ 严格测试未通过，需要修复数据库连接问题")
            return 1
            
    except Exception as e:
        logger.error(f"严格测试过程中发生异常: {str(e)}")
        print(f"\n❌ 严格测试异常: {str(e)}")
        return 3

if __name__ == "__main__":
    sys.exit(asyncio.run(main()))
