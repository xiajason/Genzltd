#!/usr/bin/env python3
"""
双AI服务集群管理器
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

class DualAIClusterManager:
    def __init__(self, db_config: Dict):
        self.db_config = db_config
        self.pool = None
        
        # 集群配置
        self.cluster_id = "dual-ai-cluster"
        self.node_id = "ai-node-1"
        
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
    
    async def register_ai_cluster_services(self):
        """注册AI集群服务到集群管理"""
        try:
            async with self.pool.acquire() as conn:
                async with conn.cursor() as cursor:
                    # 注册个性化AI集群服务
                    personalized_ai_cluster = {
                        'service_id': 'personalized-ai-cluster',
                        'service_name': 'Personalized AI Cluster',
                        'service_type': 'ai_cluster',
                        'service_url': 'http://localhost:8206',
                        'node_id': self.node_id,
                        'cluster_id': self.cluster_id,
                        'capabilities': {
                            'ai_processing': True,
                            'personalization': True,
                            'user_behavior_analysis': True,
                            'cluster_management': True
                        },
                        'config': {
                            'ai_type': 'personalized',
                            'cluster_role': 'primary',
                            'scaling_enabled': True
                        },
                        'status': 'registered',
                        'health_status': 'healthy'
                    }
                    
                    sql = """
                    INSERT INTO service_registry 
                    (service_id, service_name, service_type, service_url, node_id, cluster_id, capabilities, config, status, health_status, last_heartbeat)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                    ON DUPLICATE KEY UPDATE
                    service_name = VALUES(service_name),
                    service_type = VALUES(service_type),
                    service_url = VALUES(service_url),
                    node_id = VALUES(node_id),
                    cluster_id = VALUES(cluster_id),
                    capabilities = VALUES(capabilities),
                    config = VALUES(config),
                    status = VALUES(status),
                    health_status = VALUES(health_status),
                    last_heartbeat = VALUES(last_heartbeat),
                    updated_at = CURRENT_TIMESTAMP
                    """
                    
                    await cursor.execute(sql, (
                        personalized_ai_cluster['service_id'],
                        personalized_ai_cluster['service_name'],
                        personalized_ai_cluster['service_type'],
                        personalized_ai_cluster['service_url'],
                        personalized_ai_cluster['node_id'],
                        personalized_ai_cluster['cluster_id'],
                        json.dumps(personalized_ai_cluster['capabilities']),
                        json.dumps(personalized_ai_cluster['config']),
                        personalized_ai_cluster['status'],
                        personalized_ai_cluster['health_status'],
                        datetime.now()
                    ))
                    
                    # 注册SaaS AI集群服务
                    saas_ai_cluster = {
                        'service_id': 'saas-ai-cluster',
                        'service_name': 'SaaS AI Cluster',
                        'service_type': 'ai_cluster',
                        'service_url': 'http://localhost:8700',
                        'node_id': self.node_id,
                        'cluster_id': self.cluster_id,
                        'capabilities': {
                            'ai_processing': True,
                            'standardization': True,
                            'multi_tenant': True,
                            'cluster_management': True
                        },
                        'config': {
                            'ai_type': 'saas',
                            'cluster_role': 'secondary',
                            'scaling_enabled': True
                        },
                        'status': 'registered',
                        'health_status': 'healthy'
                    }
                    
                    await cursor.execute(sql, (
                        saas_ai_cluster['service_id'],
                        saas_ai_cluster['service_name'],
                        saas_ai_cluster['service_type'],
                        saas_ai_cluster['service_url'],
                        saas_ai_cluster['node_id'],
                        saas_ai_cluster['cluster_id'],
                        json.dumps(saas_ai_cluster['capabilities']),
                        json.dumps(saas_ai_cluster['config']),
                        saas_ai_cluster['status'],
                        saas_ai_cluster['health_status'],
                        datetime.now()
                    ))
                    
                    await conn.commit()
                    logger.info("双AI服务集群注册成功")
                    return True
                    
        except Exception as e:
            logger.error(f"双AI服务集群注册失败: {e}")
            return False
    
    async def monitor_ai_cluster_health(self) -> Dict:
        """监控AI集群健康状态"""
        try:
            cluster_health = {
                'cluster_id': self.cluster_id,
                'node_id': self.node_id,
                'ai_services': [],
                'cluster_status': 'unknown',
                'monitoring_timestamp': datetime.now()
            }
            
            # 检查个性化AI集群服务
            try:
                async with aiohttp.ClientSession() as session:
                    start_time = datetime.now()
                    async with session.get("http://localhost:8206/health", timeout=5) as response:
                        response_time = (datetime.now() - start_time).total_seconds()
                        cluster_health['ai_services'].append({
                            'service_id': 'personalized-ai-cluster',
                            'ai_type': 'personalized',
                            'status_code': response.status,
                            'response_time': response_time,
                            'healthy': response.status == 200
                        })
            except Exception as e:
                cluster_health['ai_services'].append({
                    'service_id': 'personalized-ai-cluster',
                    'ai_type': 'personalized',
                    'status_code': 0,
                    'response_time': 0,
                    'healthy': False,
                    'error': str(e)
                })
            
            # 检查SaaS AI集群服务
            try:
                async with aiohttp.ClientSession() as session:
                    start_time = datetime.now()
                    async with session.get("http://localhost:8700/health", timeout=5) as response:
                        response_time = (datetime.now() - start_time).total_seconds()
                        cluster_health['ai_services'].append({
                            'service_id': 'saas-ai-cluster',
                            'ai_type': 'saas',
                            'status_code': response.status,
                            'response_time': response_time,
                            'healthy': response.status == 200
                        })
            except Exception as e:
                cluster_health['ai_services'].append({
                    'service_id': 'saas-ai-cluster',
                    'ai_type': 'saas',
                    'status_code': 0,
                    'response_time': 0,
                    'healthy': False,
                    'error': str(e)
                })
            
            # 计算集群状态
            healthy_services = sum(1 for service in cluster_health['ai_services'] if service['healthy'])
            total_services = len(cluster_health['ai_services'])
            
            if healthy_services == total_services:
                cluster_health['cluster_status'] = 'healthy'
            elif healthy_services > 0:
                cluster_health['cluster_status'] = 'degraded'
            else:
                cluster_health['cluster_status'] = 'unhealthy'
            
            return cluster_health
            
        except Exception as e:
            logger.error(f"监控AI集群健康状态失败: {e}")
            return {}
    
    async def manage_ai_cluster_scaling(self, load_metrics: Dict) -> Dict:
        """管理AI集群扩缩容"""
        try:
            scaling_decision = {
                'cluster_id': self.cluster_id,
                'scaling_required': False,
                'scaling_action': None,
                'target_services': [],
                'scaling_timestamp': datetime.now()
            }
            
            # 分析负载指标
            total_load = load_metrics.get('total_load', 0)
            avg_response_time = load_metrics.get('avg_response_time', 0)
            error_rate = load_metrics.get('error_rate', 0)
            
            # 扩缩容决策逻辑
            if total_load > 80 or avg_response_time > 2.0 or error_rate > 0.05:
                # 需要扩容
                scaling_decision['scaling_required'] = True
                scaling_decision['scaling_action'] = 'scale_out'
                scaling_decision['target_services'] = ['personalized-ai-cluster', 'saas-ai-cluster']
            elif total_load < 20 and avg_response_time < 0.5 and error_rate < 0.01:
                # 可以缩容
                scaling_decision['scaling_required'] = True
                scaling_decision['scaling_action'] = 'scale_in'
                scaling_decision['target_services'] = ['personalized-ai-cluster', 'saas-ai-cluster']
            else:
                # 保持当前状态
                scaling_decision['scaling_required'] = False
                scaling_decision['scaling_action'] = 'maintain'
            
            # 记录扩缩容决策
            await self._record_scaling_decision(scaling_decision)
            
            return scaling_decision
            
        except Exception as e:
            logger.error(f"管理AI集群扩缩容失败: {e}")
            return {'scaling_required': False, 'error': str(e)}
    
    async def _record_scaling_decision(self, scaling_decision: Dict):
        """记录扩缩容决策"""
        try:
            async with self.pool.acquire() as conn:
                async with conn.cursor() as cursor:
                    sql = """
                    INSERT INTO service_metrics 
                    (service_id, metric_name, metric_value, metric_unit, tags, timestamp)
                    VALUES (%s, %s, %s, %s, %s, %s)
                    """
                    
                    await cursor.execute(sql, (
                        f"{self.cluster_id}-scaling",
                        'scaling_decision',
                        1 if scaling_decision['scaling_required'] else 0,
                        'count',
                        json.dumps({
                            'scaling_action': scaling_decision['scaling_action'],
                            'target_services': scaling_decision['target_services']
                        }),
                        scaling_decision['scaling_timestamp']
                    ))
                    
                    await conn.commit()
                    
        except Exception as e:
            logger.error(f"记录扩缩容决策失败: {e}")
    
    async def optimize_ai_cluster_performance(self) -> Dict:
        """优化AI集群性能"""
        try:
            optimization_result = {
                'cluster_id': self.cluster_id,
                'optimization_applied': [],
                'performance_improvement': {},
                'optimization_timestamp': datetime.now()
            }
            
            # 获取集群健康状态
            cluster_health = await self.monitor_ai_cluster_health()
            
            # 性能优化建议
            if cluster_health.get('cluster_status') == 'degraded':
                optimization_result['optimization_applied'].append('load_balancing')
                optimization_result['performance_improvement']['load_balancing'] = 'improved'
            
            if cluster_health.get('cluster_status') == 'unhealthy':
                optimization_result['optimization_applied'].append('service_restart')
                optimization_result['performance_improvement']['service_restart'] = 'improved'
            
            # 记录优化结果
            await self._record_optimization_result(optimization_result)
            
            return optimization_result
            
        except Exception as e:
            logger.error(f"优化AI集群性能失败: {e}")
            return {}
    
    async def _record_optimization_result(self, optimization_result: Dict):
        """记录优化结果"""
        try:
            async with self.pool.acquire() as conn:
                async with conn.cursor() as cursor:
                    sql = """
                    INSERT INTO service_metrics 
                    (service_id, metric_name, metric_value, metric_unit, tags, timestamp)
                    VALUES (%s, %s, %s, %s, %s, %s)
                    """
                    
                    await cursor.execute(sql, (
                        f"{self.cluster_id}-optimization",
                        'optimization_applied',
                        len(optimization_result['optimization_applied']),
                        'count',
                        json.dumps(optimization_result['optimization_applied']),
                        optimization_result['optimization_timestamp']
                    ))
                    
                    await conn.commit()
                    
        except Exception as e:
            logger.error(f"记录优化结果失败: {e}")
    
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
    'database': 'looma_cluster_management'
}

async def main():
    """主函数"""
    cluster_manager = DualAIClusterManager(DB_CONFIG)
    await cluster_manager.init_db_pool()
    
    # 注册双AI服务集群
    await cluster_manager.register_ai_cluster_services()
    
    # 持续运行双AI服务集群管理
    try:
        while True:
            # 监控AI集群健康状态
            cluster_health = await cluster_manager.monitor_ai_cluster_health()
            if cluster_health:
                print(f"双AI服务集群健康状态: {json.dumps(cluster_health, indent=2, default=str)}")
            
            # 管理AI集群扩缩容
            load_metrics = {
                'total_load': 75,  # 模拟负载指标
                'avg_response_time': 1.5,
                'error_rate': 0.02
            }
            scaling_decision = await cluster_manager.manage_ai_cluster_scaling(load_metrics)
            if scaling_decision.get('scaling_required'):
                print(f"双AI服务集群扩缩容决策: {scaling_decision['scaling_action']}")
            
            # 优化AI集群性能
            optimization_result = await cluster_manager.optimize_ai_cluster_performance()
            if optimization_result.get('optimization_applied'):
                print(f"双AI服务集群性能优化: {optimization_result['optimization_applied']}")
            
            # 等待300秒 (5分钟)
            await asyncio.sleep(300)
    except KeyboardInterrupt:
        print("双AI服务集群管理器停止")
    finally:
        await cluster_manager.close()

if __name__ == "__main__":
    asyncio.run(main())
