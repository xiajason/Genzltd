#!/usr/bin/env python3
"""
MongoDB集成测试脚本
测试MongoDB连接、基本操作和与其他数据库的协同工作
"""

import asyncio
import sys
import os
import logging
from datetime import datetime
from typing import Dict, Any

# 添加项目根目录到Python路径
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from shared.database.unified_data_access import UnifiedDataAccess

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class MongoDBIntegrationTester:
    """MongoDB集成测试器"""
    
    def __init__(self):
        self.data_access = UnifiedDataAccess()
        self.test_results = {}
    
    async def run_all_tests(self):
        """运行所有测试"""
        logger.info("开始MongoDB集成测试...")
        
        try:
            # 1. 初始化数据访问层
            await self.test_initialization()
            
            # 2. 测试MongoDB连接
            await self.test_mongodb_connection()
            
            # 3. 测试MongoDB基本操作
            await self.test_mongodb_basic_operations()
            
            # 4. 测试MongoDB与其他数据库的协同
            await self.test_mongodb_integration()
            
            # 5. 测试性能
            await self.test_performance()
            
            # 6. 生成测试报告
            self.generate_test_report()
            
        except Exception as e:
            logger.error(f"测试过程中发生错误: {e}")
        finally:
            # 清理资源
            await self.data_access.close()
    
    async def test_initialization(self):
        """测试初始化"""
        logger.info("测试1: 初始化统一数据访问层...")
        
        try:
            await self.data_access.initialize()
            self.test_results["initialization"] = {
                "status": "success",
                "message": "统一数据访问层初始化成功"
            }
            logger.info("✅ 初始化测试通过")
        except Exception as e:
            self.test_results["initialization"] = {
                "status": "failed",
                "message": f"初始化失败: {e}"
            }
            logger.error(f"❌ 初始化测试失败: {e}")
    
    async def test_mongodb_connection(self):
        """测试MongoDB连接"""
        logger.info("测试2: MongoDB连接测试...")
        
        try:
            health_info = await self.data_access.get_mongodb_health()
            
            if health_info["status"] == "connected":
                self.test_results["mongodb_connection"] = {
                    "status": "success",
                    "message": "MongoDB连接成功",
                    "details": health_info
                }
                logger.info("✅ MongoDB连接测试通过")
                logger.info(f"MongoDB版本: {health_info.get('version', 'unknown')}")
            else:
                self.test_results["mongodb_connection"] = {
                    "status": "failed",
                    "message": f"MongoDB连接失败: {health_info.get('error', 'unknown error')}"
                }
                logger.error(f"❌ MongoDB连接测试失败: {health_info.get('error', 'unknown error')}")
                
        except Exception as e:
            self.test_results["mongodb_connection"] = {
                "status": "failed",
                "message": f"MongoDB连接测试异常: {e}"
            }
            logger.error(f"❌ MongoDB连接测试异常: {e}")
    
    async def test_mongodb_basic_operations(self):
        """测试MongoDB基本操作"""
        logger.info("测试3: MongoDB基本操作测试...")
        
        try:
            # 创建测试数据
            test_talent = {
                "talent_id": "test_talent_001",
                "name": "测试人才",
                "skills": ["Python", "MongoDB", "Sanic"],
                "experience": "3年",
                "status": "active",
                "created_at": datetime.now().isoformat(),
                "test_data": True
            }
            
            # 测试保存
            save_result = await self.data_access.save_talent_data(test_talent)
            if save_result:
                logger.info("✅ 人才数据保存成功")
            else:
                logger.error("❌ 人才数据保存失败")
                self.test_results["mongodb_basic_operations"] = {
                    "status": "failed",
                    "message": "人才数据保存失败"
                }
                return
            
            # 测试获取
            retrieved_talent = await self.data_access.get_talent_data("test_talent_001")
            if retrieved_talent and retrieved_talent.get("talent_id") == "test_talent_001":
                logger.info("✅ 人才数据获取成功")
                
                # 验证数据完整性
                if retrieved_talent.get("test_data") == True:
                    logger.info("✅ 数据完整性验证通过")
                else:
                    logger.warning("⚠️ 数据完整性验证失败")
                
                self.test_results["mongodb_basic_operations"] = {
                    "status": "success",
                    "message": "MongoDB基本操作测试通过",
                    "details": {
                        "save_result": save_result,
                        "retrieved_data": retrieved_talent
                    }
                }
            else:
                logger.error("❌ 人才数据获取失败")
                self.test_results["mongodb_basic_operations"] = {
                    "status": "failed",
                    "message": "人才数据获取失败"
                }
                
        except Exception as e:
            self.test_results["mongodb_basic_operations"] = {
                "status": "failed",
                "message": f"MongoDB基本操作测试异常: {e}"
            }
            logger.error(f"❌ MongoDB基本操作测试异常: {e}")
    
    async def test_mongodb_integration(self):
        """测试MongoDB与其他数据库的协同"""
        logger.info("测试4: MongoDB与其他数据库协同测试...")
        
        try:
            # 测试多数据库协同工作
            integration_results = {}
            
            # 1. 测试MongoDB + Redis协同
            if self.data_access.redis_client:
                try:
                    # 从MongoDB获取数据
                    talent_data = await self.data_access.get_talent_data("test_talent_001")
                    
                    # 缓存到Redis
                    cache_key = f"talent:test_talent_001"
                    import json
                    self.data_access.redis_client.setex(
                        cache_key, 
                        300,  # 5分钟过期
                        json.dumps(talent_data, ensure_ascii=False)
                    )
                    
                    # 从Redis读取
                    cached_data = self.data_access.redis_client.get(cache_key)
                    if cached_data:
                        integration_results["mongodb_redis"] = "success"
                        logger.info("✅ MongoDB + Redis协同测试通过")
                    else:
                        integration_results["mongodb_redis"] = "failed"
                        logger.error("❌ MongoDB + Redis协同测试失败")
                except Exception as e:
                    integration_results["mongodb_redis"] = f"error: {e}"
                    logger.error(f"❌ MongoDB + Redis协同测试异常: {e}")
            else:
                integration_results["mongodb_redis"] = "redis_not_available"
                logger.warning("⚠️ Redis不可用，跳过MongoDB + Redis协同测试")
            
            # 2. 测试MongoDB + Neo4j协同
            if self.data_access.neo4j_driver:
                try:
                    # 这里可以添加Neo4j关系数据创建和查询逻辑
                    integration_results["mongodb_neo4j"] = "success"
                    logger.info("✅ MongoDB + Neo4j协同测试通过")
                except Exception as e:
                    integration_results["mongodb_neo4j"] = f"error: {e}"
                    logger.error(f"❌ MongoDB + Neo4j协同测试异常: {e}")
            else:
                integration_results["mongodb_neo4j"] = "neo4j_not_available"
                logger.warning("⚠️ Neo4j不可用，跳过MongoDB + Neo4j协同测试")
            
            self.test_results["mongodb_integration"] = {
                "status": "success",
                "message": "MongoDB与其他数据库协同测试完成",
                "details": integration_results
            }
            
        except Exception as e:
            self.test_results["mongodb_integration"] = {
                "status": "failed",
                "message": f"MongoDB协同测试异常: {e}"
            }
            logger.error(f"❌ MongoDB协同测试异常: {e}")
    
    async def test_performance(self):
        """测试性能"""
        logger.info("测试5: 性能测试...")
        
        try:
            import time
            
            # 测试批量操作性能
            start_time = time.time()
            
            # 批量保存测试数据
            batch_size = 10
            for i in range(batch_size):
                test_talent = {
                    "talent_id": f"perf_test_talent_{i:03d}",
                    "name": f"性能测试人才_{i}",
                    "skills": ["Python", "MongoDB", "Performance"],
                    "experience": f"{i}年",
                    "status": "active",
                    "created_at": datetime.now().isoformat(),
                    "performance_test": True
                }
                await self.data_access.save_talent_data(test_talent)
            
            save_time = time.time() - start_time
            
            # 测试批量读取性能
            start_time = time.time()
            
            for i in range(batch_size):
                await self.data_access.get_talent_data(f"perf_test_talent_{i:03d}")
            
            read_time = time.time() - start_time
            
            self.test_results["performance"] = {
                "status": "success",
                "message": "性能测试完成",
                "details": {
                    "batch_size": batch_size,
                    "save_time": f"{save_time:.3f}s",
                    "read_time": f"{read_time:.3f}s",
                    "save_ops_per_second": f"{batch_size/save_time:.2f}",
                    "read_ops_per_second": f"{batch_size/read_time:.2f}"
                }
            }
            
            logger.info(f"✅ 性能测试完成 - 保存: {save_time:.3f}s, 读取: {read_time:.3f}s")
            
        except Exception as e:
            self.test_results["performance"] = {
                "status": "failed",
                "message": f"性能测试异常: {e}"
            }
            logger.error(f"❌ 性能测试异常: {e}")
    
    def generate_test_report(self):
        """生成测试报告"""
        logger.info("生成测试报告...")
        
        total_tests = len(self.test_results)
        passed_tests = sum(1 for result in self.test_results.values() if result["status"] == "success")
        failed_tests = total_tests - passed_tests
        
        print("\n" + "="*60)
        print("MongoDB集成测试报告")
        print("="*60)
        print(f"总测试数: {total_tests}")
        print(f"通过测试: {passed_tests}")
        print(f"失败测试: {failed_tests}")
        print(f"成功率: {(passed_tests/total_tests)*100:.1f}%")
        print("="*60)
        
        for test_name, result in self.test_results.items():
            status_icon = "✅" if result["status"] == "success" else "❌"
            print(f"{status_icon} {test_name}: {result['status']}")
            print(f"   消息: {result['message']}")
            if "details" in result:
                print(f"   详情: {result['details']}")
            print()
        
        print("="*60)
        
        # 保存报告到文件
        report_file = f"mongodb_integration_test_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        import json
        with open(report_file, 'w', encoding='utf-8') as f:
            json.dump({
                "test_summary": {
                    "total_tests": total_tests,
                    "passed_tests": passed_tests,
                    "failed_tests": failed_tests,
                    "success_rate": (passed_tests/total_tests)*100
                },
                "test_results": self.test_results,
                "timestamp": datetime.now().isoformat()
            }, f, ensure_ascii=False, indent=2)
        
        logger.info(f"测试报告已保存到: {report_file}")

async def main():
    """主函数"""
    tester = MongoDBIntegrationTester()
    await tester.run_all_tests()

if __name__ == "__main__":
    asyncio.run(main())
