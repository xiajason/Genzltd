#!/usr/bin/env python3
"""
双AI服务协作管理器
"""

import asyncio
import json
import logging
from datetime import datetime
from typing import Dict, List, Optional
import aiomysql
import aiohttp

# 配置日志
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class DualAICollaborationManager:
    def __init__(self, db_config: Dict):
        self.db_config = db_config
        self.pool = None
        
        # AI服务配置
        self.personalized_ai_url = "http://localhost:8206"
        self.saas_ai_url = "http://localhost:8700"
        
    async def init_db_pool(self):
        """初始化数据库连接池"""
        self.pool = await aiomysql.create_pool(
            host=self.db_config['host'],
            port=self.db_config['port'],
            user=self.db_config['user'],
            password=self.db_config['password'],
            db=self.db_config['database'],
            minsize=5,
            maxsize=20
        )
    
    async def register_dual_ai_services(self):
        """注册双AI服务到联邦架构"""
        try:
            async with self.pool.acquire() as conn:
                async with conn.cursor() as cursor:
                    # 注册个性化AI服务
                    personalized_ai_info = {
                        'service_id': 'personalized-ai-service',
                        'ai_type': 'personalized',
                        'service_name': 'Personalized AI Service',
                        'service_url': self.personalized_ai_url,
                        'ai_capabilities': {
                            'personalization': True,
                            'user_behavior_analysis': True,
                            'recommendation_engine': True,
                            'content_generation': True
                        },
                        'collaboration_status': 'active',
                        'last_collaboration': datetime.now()
                    }
                    
                    sql = """
                    INSERT INTO dual_ai_services 
                    (service_id, ai_type, service_name, service_url, ai_capabilities, collaboration_status, last_collaboration)
                    VALUES (%s, %s, %s, %s, %s, %s, %s)
                    ON DUPLICATE KEY UPDATE
                    service_name = VALUES(service_name),
                    service_url = VALUES(service_url),
                    ai_capabilities = VALUES(ai_capabilities),
                    collaboration_status = VALUES(collaboration_status),
                    last_collaboration = VALUES(last_collaboration),
                    updated_at = CURRENT_TIMESTAMP
                    """
                    
                    await cursor.execute(sql, (
                        personalized_ai_info['service_id'],
                        personalized_ai_info['ai_type'],
                        personalized_ai_info['service_name'],
                        personalized_ai_info['service_url'],
                        json.dumps(personalized_ai_info['ai_capabilities']),
                        personalized_ai_info['collaboration_status'],
                        personalized_ai_info['last_collaboration']
                    ))
                    
                    # 注册SaaS AI服务
                    saas_ai_info = {
                        'service_id': 'saas-ai-service',
                        'ai_type': 'saas',
                        'service_name': 'SaaS AI Service',
                        'service_url': self.saas_ai_url,
                        'ai_capabilities': {
                            'standardization': True,
                            'multi_tenant': True,
                            'enterprise_features': True,
                            'scalability': True
                        },
                        'collaboration_status': 'active',
                        'last_collaboration': datetime.now()
                    }
                    
                    await cursor.execute(sql, (
                        saas_ai_info['service_id'],
                        saas_ai_info['ai_type'],
                        saas_ai_info['service_name'],
                        saas_ai_info['service_url'],
                        json.dumps(saas_ai_info['ai_capabilities']),
                        saas_ai_info['collaboration_status'],
                        saas_ai_info['last_collaboration']
                    ))
                    
                    await conn.commit()
                    logger.info("双AI服务注册成功")
                    return True
                    
        except Exception as e:
            logger.error(f"双AI服务注册失败: {e}")
            return False
    
    async def check_ai_service_health(self) -> Dict:
        """检查AI服务健康状态"""
        try:
            health_status = {}
            
            # 检查个性化AI服务
            try:
                async with aiohttp.ClientSession() as session:
                    start_time = datetime.now()
                    async with session.get(f"{self.personalized_ai_url}/health", timeout=5) as response:
                        response_time = (datetime.now() - start_time).total_seconds()
                        health_status['personalized_ai'] = {
                            'status_code': response.status,
                            'response_time': response_time,
                            'healthy': response.status == 200
                        }
            except Exception as e:
                health_status['personalized_ai'] = {
                    'status_code': 0,
                    'response_time': 0,
                    'healthy': False,
                    'error': str(e)
                }
            
            # 检查SaaS AI服务
            try:
                async with aiohttp.ClientSession() as session:
                    start_time = datetime.now()
                    async with session.get(f"{self.saas_ai_url}/health", timeout=5) as response:
                        response_time = (datetime.now() - start_time).total_seconds()
                        health_status['saas_ai'] = {
                            'status_code': response.status,
                            'response_time': response_time,
                            'healthy': response.status == 200
                        }
            except Exception as e:
                health_status['saas_ai'] = {
                    'status_code': 0,
                    'response_time': 0,
                    'healthy': False,
                    'error': str(e)
                }
            
            return health_status
            
        except Exception as e:
            logger.error(f"检查AI服务健康状态失败: {e}")
            return {}
    
    async def enable_ai_collaboration(self, user_id: str, task_type: str) -> Dict:
        """启用AI服务协作"""
        try:
            collaboration_result = {
                'user_id': user_id,
                'task_type': task_type,
                'collaboration_enabled': False,
                'ai_services': [],
                'collaboration_plan': {},
                'timestamp': datetime.now()
            }
            
            # 检查AI服务健康状态
            health_status = await self.check_ai_service_health()
            
            if health_status.get('personalized_ai', {}).get('healthy', False):
                collaboration_result['ai_services'].append('personalized_ai')
                collaboration_result['collaboration_plan']['personalized_ai'] = {
                    'role': 'user_specific_analysis',
                    'capabilities': ['personalization', 'user_behavior_analysis']
                }
            
            if health_status.get('saas_ai', {}).get('healthy', False):
                collaboration_result['ai_services'].append('saas_ai')
                collaboration_result['collaboration_plan']['saas_ai'] = {
                    'role': 'standardized_processing',
                    'capabilities': ['standardization', 'multi_tenant']
                }
            
            # 如果两个AI服务都健康，启用协作
            if len(collaboration_result['ai_services']) >= 2:
                collaboration_result['collaboration_enabled'] = True
                collaboration_result['collaboration_plan']['workflow'] = [
                    'personalized_ai_analysis',
                    'saas_ai_standardization',
                    'result_synthesis'
                ]
            
            # 记录协作状态
            await self._record_collaboration_status(collaboration_result)
            
            return collaboration_result
            
        except Exception as e:
            logger.error(f"启用AI服务协作失败: {e}")
            return {'collaboration_enabled': False, 'error': str(e)}
    
    async def _record_collaboration_status(self, collaboration_result: Dict):
        """记录协作状态"""
        try:
            async with self.pool.acquire() as conn:
                async with conn.cursor() as cursor:
                    sql = """
                    INSERT INTO cross_system_sync 
                    (source_system, target_system, sync_type, sync_status, last_sync, sync_count)
                    VALUES (%s, %s, %s, %s, %s, %s)
                    ON DUPLICATE KEY UPDATE
                    sync_status = VALUES(sync_status),
                    last_sync = VALUES(last_sync),
                    sync_count = sync_count + 1,
                    updated_at = CURRENT_TIMESTAMP
                    """
                    
                    await cursor.execute(sql, (
                        'personalized_ai',
                        'saas_ai',
                        'ai_collaboration',
                        'success' if collaboration_result['collaboration_enabled'] else 'failed',
                        collaboration_result['timestamp'],
                        1
                    ))
                    
                    await conn.commit()
                    
        except Exception as e:
            logger.error(f"记录协作状态失败: {e}")
    
    async def monitor_ai_collaboration(self) -> Dict:
        """监控AI服务协作"""
        try:
            # 检查AI服务健康状态
            health_status = await self.check_ai_service_health()
            
            # 获取协作统计
            async with self.pool.acquire() as conn:
                async with conn.cursor(aiomysql.DictCursor) as cursor:
                    sql = """
                    SELECT sync_status, COUNT(*) as count, SUM(sync_count) as total_syncs
                    FROM cross_system_sync 
                    WHERE sync_type = 'ai_collaboration'
                    GROUP BY sync_status
                    """
                    await cursor.execute(sql)
                    collaboration_stats = await cursor.fetchall()
            
            return {
                'health_status': health_status,
                'collaboration_stats': [dict(row) for row in collaboration_stats],
                'monitoring_timestamp': datetime.now()
            }
            
        except Exception as e:
            logger.error(f"监控AI服务协作失败: {e}")
            return {}
    
    async def close(self):
        """关闭数据库连接池"""
        if self.pool:
            self.pool.close()
            await self.pool.wait_closed()

# 数据库配置
DB_CONFIG = {
    'host': 'localhost',
    'port': 3306,
    'user': 'root',
    'password': '',
    'database': 'federated_cluster_management'
}

async def main():
    """主函数"""
    collaboration_manager = DualAICollaborationManager(DB_CONFIG)
    await collaboration_manager.init_db_pool()
    
    # 注册双AI服务
    await collaboration_manager.register_dual_ai_services()
    
    # 持续运行双AI服务协作管理
    try:
        while True:
            # 监控AI服务协作
            monitoring_result = await collaboration_manager.monitor_ai_collaboration()
            if monitoring_result:
                print(f"双AI服务协作监控: {json.dumps(monitoring_result, indent=2, default=str)}")
            
            # 测试AI服务协作
            test_collaboration = await collaboration_manager.enable_ai_collaboration(
                user_id="test_user_001",
                task_type="content_generation"
            )
            if test_collaboration.get('collaboration_enabled'):
                print(f"双AI服务协作测试: 成功启用协作")
            else:
                print(f"双AI服务协作测试: 协作未启用")
            
            # 等待300秒 (5分钟)
            await asyncio.sleep(300)
    except KeyboardInterrupt:
        print("双AI服务协作管理器停止")
    finally:
        await collaboration_manager.close()

if __name__ == "__main__":
    asyncio.run(main())
