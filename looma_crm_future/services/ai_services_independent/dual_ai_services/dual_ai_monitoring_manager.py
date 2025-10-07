#!/usr/bin/env python3
"""
双AI服务监控管理器
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

class DualAIMonitoringManager:
    def __init__(self, db_config: Dict):
        self.db_config = db_config
        self.pool = None
        
        # 监控配置
        self.monitoring_interval = 60  # 监控间隔（秒）
        self.alert_thresholds = {
            'response_time': 2.0,  # 响应时间阈值
            'error_rate': 0.05,    # 错误率阈值
            'cpu_usage': 80.0,     # CPU使用率阈值
            'memory_usage': 85.0   # 内存使用率阈值
        }
        
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
    
    async def collect_dual_ai_metrics(self) -> Dict:
        """收集双AI服务指标"""
        try:
            metrics = {
                'personalized_ai': {},
                'saas_ai': {},
                'collaboration': {},
                'cluster': {},
                'timestamp': datetime.now()
            }
            
            # 收集个性化AI服务指标
            personalized_ai_metrics = await self._collect_personalized_ai_metrics()
            metrics['personalized_ai'] = personalized_ai_metrics
            
            # 收集SaaS AI服务指标
            saas_ai_metrics = await self._collect_saas_ai_metrics()
            metrics['saas_ai'] = saas_ai_metrics
            
            # 收集协作指标
            collaboration_metrics = await self._collect_collaboration_metrics()
            metrics['collaboration'] = collaboration_metrics
            
            # 收集集群指标
            cluster_metrics = await self._collect_cluster_metrics()
            metrics['cluster'] = cluster_metrics
            
            # 存储指标到数据库
            await self._store_metrics(metrics)
            
            return metrics
            
        except Exception as e:
            logger.error(f"收集双AI服务指标失败: {e}")
            return {}
    
    async def _collect_personalized_ai_metrics(self) -> Dict:
        """收集个性化AI服务指标"""
        try:
            async with aiohttp.ClientSession() as session:
                start_time = datetime.now()
                async with session.get("http://localhost:8206/health", timeout=5) as response:
                    response_time = (datetime.now() - start_time).total_seconds()
                    
                    return {
                        'status_code': response.status,
                        'response_time': response_time,
                        'healthy': response.status == 200,
                        'ai_type': 'personalized',
                        'capabilities': ['personalization', 'user_behavior_analysis']
                    }
        except Exception as e:
            logger.error(f"收集个性化AI指标失败: {e}")
            return {
                'status_code': 0,
                'response_time': 0,
                'healthy': False,
                'ai_type': 'personalized',
                'error': str(e)
            }
    
    async def _collect_saas_ai_metrics(self) -> Dict:
        """收集SaaS AI服务指标"""
        try:
            async with aiohttp.ClientSession() as session:
                start_time = datetime.now()
                async with session.get("http://localhost:8700/health", timeout=5) as response:
                    response_time = (datetime.now() - start_time).total_seconds()
                    
                    return {
                        'status_code': response.status,
                        'response_time': response_time,
                        'healthy': response.status == 200,
                        'ai_type': 'saas',
                        'capabilities': ['standardization', 'multi_tenant']
                    }
        except Exception as e:
            logger.error(f"收集SaaS AI指标失败: {e}")
            return {
                'status_code': 0,
                'response_time': 0,
                'healthy': False,
                'ai_type': 'saas',
                'error': str(e)
            }
    
    async def _collect_collaboration_metrics(self) -> Dict:
        """收集协作指标"""
        try:
            async with self.pool.acquire() as conn:
                async with conn.cursor(aiomysql.DictCursor) as cursor:
                    # 获取协作统计
                    sql = """
                    SELECT 
                        COUNT(*) as total_collaborations,
                        SUM(CASE WHEN sync_status = 'success' THEN 1 ELSE 0 END) as successful_collaborations,
                        SUM(CASE WHEN sync_status = 'failed' THEN 1 ELSE 0 END) as failed_collaborations,
                        AVG(sync_count) as avg_sync_count
                    FROM cross_system_sync 
                    WHERE sync_type = 'ai_collaboration'
                    """
                    await cursor.execute(sql)
                    collaboration_stats = await cursor.fetchone()
                    
                    return {
                        'total_collaborations': collaboration_stats['total_collaborations'] or 0,
                        'successful_collaborations': collaboration_stats['successful_collaborations'] or 0,
                        'failed_collaborations': collaboration_stats['failed_collaborations'] or 0,
                        'success_rate': (collaboration_stats['successful_collaborations'] or 0) / max(collaboration_stats['total_collaborations'] or 1, 1),
                        'avg_sync_count': collaboration_stats['avg_sync_count'] or 0
                    }
        except Exception as e:
            logger.error(f"收集协作指标失败: {e}")
            return {}
    
    async def _collect_cluster_metrics(self) -> Dict:
        """收集集群指标"""
        try:
            async with self.pool.acquire() as conn:
                async with conn.cursor(aiomysql.DictCursor) as cursor:
                    # 获取集群服务统计
                    sql = """
                    SELECT 
                        COUNT(*) as total_services,
                        SUM(CASE WHEN health_status = 'healthy' THEN 1 ELSE 0 END) as healthy_services,
                        SUM(CASE WHEN health_status = 'unhealthy' THEN 1 ELSE 0 END) as unhealthy_services
                    FROM service_registry 
                    WHERE cluster_id = 'dual-ai-cluster'
                    """
                    await cursor.execute(sql)
                    cluster_stats = await cursor.fetchone()
                    
                    return {
                        'total_services': cluster_stats['total_services'] or 0,
                        'healthy_services': cluster_stats['healthy_services'] or 0,
                        'unhealthy_services': cluster_stats['unhealthy_services'] or 0,
                        'health_rate': (cluster_stats['healthy_services'] or 0) / max(cluster_stats['total_services'] or 1, 1)
                    }
        except Exception as e:
            logger.error(f"收集集群指标失败: {e}")
            return {}
    
    async def _store_metrics(self, metrics: Dict):
        """存储指标到数据库"""
        try:
            async with self.pool.acquire() as conn:
                async with conn.cursor() as cursor:
                    # 存储个性化AI指标
                    if metrics.get('personalized_ai'):
                        ai_metrics = metrics['personalized_ai']
                        sql = """
                        INSERT INTO service_metrics 
                        (service_id, metric_name, metric_value, metric_unit, tags, timestamp)
                        VALUES (%s, %s, %s, %s, %s, %s)
                        """
                        
                        await cursor.execute(sql, (
                            'personalized-ai-service',
                            'response_time',
                            ai_metrics.get('response_time', 0),
                            'seconds',
                            json.dumps({'ai_type': 'personalized'}),
                            metrics['timestamp']
                        ))
                        
                        await cursor.execute(sql, (
                            'personalized-ai-service',
                            'status_code',
                            ai_metrics.get('status_code', 0),
                            'count',
                            json.dumps({'ai_type': 'personalized'}),
                            metrics['timestamp']
                        ))
                    
                    # 存储SaaS AI指标
                    if metrics.get('saas_ai'):
                        ai_metrics = metrics['saas_ai']
                        await cursor.execute(sql, (
                            'saas-ai-service',
                            'response_time',
                            ai_metrics.get('response_time', 0),
                            'seconds',
                            json.dumps({'ai_type': 'saas'}),
                            metrics['timestamp']
                        ))
                        
                        await cursor.execute(sql, (
                            'saas-ai-service',
                            'status_code',
                            ai_metrics.get('status_code', 0),
                            'count',
                            json.dumps({'ai_type': 'saas'}),
                            metrics['timestamp']
                        ))
                    
                    # 存储协作指标
                    if metrics.get('collaboration'):
                        collab_metrics = metrics['collaboration']
                        await cursor.execute(sql, (
                            'dual-ai-collaboration',
                            'success_rate',
                            collab_metrics.get('success_rate', 0),
                            'percentage',
                            json.dumps({'metric_type': 'collaboration'}),
                            metrics['timestamp']
                        ))
                    
                    # 存储集群指标
                    if metrics.get('cluster'):
                        cluster_metrics = metrics['cluster']
                        await cursor.execute(sql, (
                            'dual-ai-cluster',
                            'health_rate',
                            cluster_metrics.get('health_rate', 0),
                            'percentage',
                            json.dumps({'metric_type': 'cluster'}),
                            metrics['timestamp']
                        ))
                    
                    await conn.commit()
                    
        except Exception as e:
            logger.error(f"存储指标失败: {e}")
    
    async def check_dual_ai_alerts(self) -> List[Dict]:
        """检查双AI服务告警"""
        try:
            alerts = []
            
            # 收集当前指标
            metrics = await self.collect_dual_ai_metrics()
            
            # 检查个性化AI服务告警
            if metrics.get('personalized_ai'):
                ai_metrics = metrics['personalized_ai']
                if ai_metrics.get('response_time', 0) > self.alert_thresholds['response_time']:
                    alerts.append({
                        'type': 'personalized_ai_response_time',
                        'severity': 'warning',
                        'message': f'个性化AI服务响应时间过长: {ai_metrics["response_time"]:.2f}秒'
                    })
                
                if not ai_metrics.get('healthy', False):
                    alerts.append({
                        'type': 'personalized_ai_health',
                        'severity': 'critical',
                        'message': '个性化AI服务健康检查失败'
                    })
            
            # 检查SaaS AI服务告警
            if metrics.get('saas_ai'):
                ai_metrics = metrics['saas_ai']
                if ai_metrics.get('response_time', 0) > self.alert_thresholds['response_time']:
                    alerts.append({
                        'type': 'saas_ai_response_time',
                        'severity': 'warning',
                        'message': f'SaaS AI服务响应时间过长: {ai_metrics["response_time"]:.2f}秒'
                    })
                
                if not ai_metrics.get('healthy', False):
                    alerts.append({
                        'type': 'saas_ai_health',
                        'severity': 'critical',
                        'message': 'SaaS AI服务健康检查失败'
                    })
            
            # 检查协作告警
            if metrics.get('collaboration'):
                collab_metrics = metrics['collaboration']
                success_rate = collab_metrics.get('success_rate', 0)
                if success_rate < 0.8:  # 成功率低于80%
                    alerts.append({
                        'type': 'collaboration_success_rate',
                        'severity': 'warning',
                        'message': f'双AI服务协作成功率过低: {success_rate:.2%}'
                    })
            
            # 检查集群告警
            if metrics.get('cluster'):
                cluster_metrics = metrics['cluster']
                health_rate = cluster_metrics.get('health_rate', 0)
                if health_rate < 0.9:  # 健康率低于90%
                    alerts.append({
                        'type': 'cluster_health_rate',
                        'severity': 'warning',
                        'message': f'双AI服务集群健康率过低: {health_rate:.2%}'
                    })
            
            return alerts
            
        except Exception as e:
            logger.error(f"检查双AI服务告警失败: {e}")
            return []
    
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
    monitoring_manager = DualAIMonitoringManager(DB_CONFIG)
    await monitoring_manager.init_db_pool()
    
    # 持续运行双AI服务监控
    try:
        while True:
            # 收集双AI服务指标
            metrics = await monitoring_manager.collect_dual_ai_metrics()
            if metrics:
                print(f"双AI服务指标: {json.dumps(metrics, indent=2, default=str)}")
            
            # 检查双AI服务告警
            alerts = await monitoring_manager.check_dual_ai_alerts()
            if alerts:
                print(f"双AI服务告警: {len(alerts)}个")
                for alert in alerts:
                    print(f"  - {alert['message']}")
            else:
                print("双AI服务告警: 无")
            
            # 等待60秒
            await asyncio.sleep(60)
    except KeyboardInterrupt:
        print("双AI服务监控管理器停止")
    finally:
        await monitoring_manager.close()

if __name__ == "__main__":
    asyncio.run(main())
