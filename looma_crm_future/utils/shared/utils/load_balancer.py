"""
负载均衡器 - 用于AI服务的负载均衡
支持轮询、随机、最少连接等多种策略
"""

import asyncio
import random
import logging
from typing import Dict, Any, List, Optional
from datetime import datetime

logger = logging.getLogger(__name__)


class LoadBalancer:
    """负载均衡器"""
    
    def __init__(self, strategy: str = 'round_robin'):
        """初始化负载均衡器"""
        self.strategy = strategy
        self.service_instances = {}
        self.instance_counters = {}
        self.instance_connections = {}
        
    async def initialize(self):
        """初始化负载均衡器"""
        logger.info(f"负载均衡器初始化成功，策略: {self.strategy}")
    
    async def select_instance(self, service_info: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """选择服务实例"""
        try:
            service_name = service_info.get('name', 'unknown')
            instances = service_info.get('instances', [])
            
            if not instances:
                logger.warning(f"没有可用的服务实例: {service_name}")
                return None
            
            # 过滤健康的实例
            healthy_instances = [inst for inst in instances if inst.get('status') == 'healthy']
            if not healthy_instances:
                logger.warning(f"没有健康的服务实例: {service_name}")
                return None
            
            # 根据策略选择实例
            if self.strategy == 'round_robin':
                selected_instance = await self._round_robin_selection(service_name, healthy_instances)
            elif self.strategy == 'random':
                selected_instance = await self._random_selection(healthy_instances)
            elif self.strategy == 'least_connections':
                selected_instance = await self._least_connections_selection(service_name, healthy_instances)
            elif self.strategy == 'weighted_round_robin':
                selected_instance = await self._weighted_round_robin_selection(service_name, healthy_instances)
            else:
                # 默认使用轮询
                selected_instance = await self._round_robin_selection(service_name, healthy_instances)
            
            logger.debug(f"选择服务实例: {service_name} -> {selected_instance.get('id', 'unknown')}")
            return selected_instance
            
        except Exception as e:
            logger.error(f"选择服务实例失败: {e}")
            return None
    
    async def _round_robin_selection(self, service_name: str, instances: List[Dict[str, Any]]) -> Dict[str, Any]:
        """轮询选择"""
        if service_name not in self.instance_counters:
            self.instance_counters[service_name] = 0
        
        index = self.instance_counters[service_name] % len(instances)
        self.instance_counters[service_name] += 1
        
        return instances[index]
    
    async def _random_selection(self, instances: List[Dict[str, Any]]) -> Dict[str, Any]:
        """随机选择"""
        return random.choice(instances)
    
    async def _least_connections_selection(self, service_name: str, instances: List[Dict[str, Any]]) -> Dict[str, Any]:
        """最少连接选择"""
        if service_name not in self.instance_connections:
            self.instance_connections[service_name] = {}
        
        # 计算每个实例的连接数
        instance_connections = self.instance_connections[service_name]
        min_connections = float('inf')
        selected_instance = instances[0]
        
        for instance in instances:
            instance_id = instance.get('id', 'unknown')
            connections = instance_connections.get(instance_id, 0)
            if connections < min_connections:
                min_connections = connections
                selected_instance = instance
        
        return selected_instance
    
    async def _weighted_round_robin_selection(self, service_name: str, instances: List[Dict[str, Any]]) -> Dict[str, Any]:
        """加权轮询选择"""
        if service_name not in self.instance_counters:
            self.instance_counters[service_name] = 0
        
        # 计算总权重
        total_weight = sum(inst.get('weight', 1) for inst in instances)
        if total_weight == 0:
            return instances[0]
        
        # 轮询选择
        counter = self.instance_counters[service_name]
        current_weight = 0
        
        for instance in instances:
            weight = instance.get('weight', 1)
            current_weight += weight
            if counter % total_weight < current_weight:
                self.instance_counters[service_name] += 1
                return instance
        
        return instances[0]
    
    async def update_instance_connections(self, service_name: str, instance_id: str, delta: int):
        """更新实例连接数"""
        if service_name not in self.instance_connections:
            self.instance_connections[service_name] = {}
        
        if instance_id not in self.instance_connections[service_name]:
            self.instance_connections[service_name][instance_id] = 0
        
        self.instance_connections[service_name][instance_id] += delta
        
        # 确保连接数不为负数
        if self.instance_connections[service_name][instance_id] < 0:
            self.instance_connections[service_name][instance_id] = 0
    
    async def get_instance_stats(self, service_name: str) -> Dict[str, Any]:
        """获取实例统计信息"""
        stats = {
            'service_name': service_name,
            'strategy': self.strategy,
            'instance_counters': self.instance_counters.get(service_name, 0),
            'instance_connections': self.instance_connections.get(service_name, {}),
            'timestamp': datetime.now().isoformat()
        }
        
        return stats
    
    async def cleanup(self):
        """清理资源"""
        self.service_instances.clear()
        self.instance_counters.clear()
        self.instance_connections.clear()
        logger.info("负载均衡器资源清理完成")


class HealthCheckLoadBalancer(LoadBalancer):
    """带健康检查的负载均衡器"""
    
    def __init__(self, strategy: str = 'round_robin', health_check_interval: int = 30):
        super().__init__(strategy)
        self.health_check_interval = health_check_interval
        self.unhealthy_instances = set()
        self.health_check_tasks = {}
    
    async def initialize(self):
        """初始化健康检查负载均衡器"""
        await super().initialize()
        logger.info(f"健康检查负载均衡器初始化成功，检查间隔: {self.health_check_interval}秒")
    
    async def start_health_checks(self, service_name: str, instances: List[Dict[str, Any]]):
        """开始健康检查"""
        if service_name not in self.health_check_tasks:
            task = asyncio.create_task(self._health_check_loop(service_name, instances))
            self.health_check_tasks[service_name] = task
            logger.info(f"开始健康检查: {service_name}")
    
    async def stop_health_checks(self, service_name: str):
        """停止健康检查"""
        if service_name in self.health_check_tasks:
            self.health_check_tasks[service_name].cancel()
            del self.health_check_tasks[service_name]
            logger.info(f"停止健康检查: {service_name}")
    
    async def _health_check_loop(self, service_name: str, instances: List[Dict[str, Any]]):
        """健康检查循环"""
        while True:
            try:
                await asyncio.sleep(self.health_check_interval)
                await self._check_instances_health(service_name, instances)
            except asyncio.CancelledError:
                break
            except Exception as e:
                logger.error(f"健康检查循环出错: {e}")
    
    async def _check_instances_health(self, service_name: str, instances: List[Dict[str, Any]]):
        """检查实例健康状态"""
        import aiohttp
        
        for instance in instances:
            instance_id = instance.get('id', 'unknown')
            host = instance.get('host', 'localhost')
            port = instance.get('port', 8080)
            
            try:
                async with aiohttp.ClientSession() as session:
                    async with session.get(
                        f"http://{host}:{port}/health",
                        timeout=aiohttp.ClientTimeout(total=5)
                    ) as response:
                        if response.status == 200:
                            # 实例健康
                            if instance_id in self.unhealthy_instances:
                                self.unhealthy_instances.remove(instance_id)
                                logger.info(f"实例恢复健康: {instance_id}")
                        else:
                            # 实例不健康
                            if instance_id not in self.unhealthy_instances:
                                self.unhealthy_instances.add(instance_id)
                                logger.warning(f"实例不健康: {instance_id}")
                            
            except Exception as e:
                # 实例不可达
                if instance_id not in self.unhealthy_instances:
                    self.unhealthy_instances.add(instance_id)
                    logger.warning(f"实例不可达: {instance_id}, 错误: {e}")
    
    async def select_instance(self, service_info: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """选择健康的服务实例"""
        # 过滤不健康的实例
        healthy_instances = []
        for instance in service_info.get('instances', []):
            instance_id = instance.get('id', 'unknown')
            if instance_id not in self.unhealthy_instances:
                healthy_instances.append(instance)
        
        if not healthy_instances:
            logger.warning(f"没有健康的服务实例: {service_info.get('name', 'unknown')}")
            return None
        
        # 使用父类的选择策略
        service_info_copy = service_info.copy()
        service_info_copy['instances'] = healthy_instances
        
        return await super().select_instance(service_info_copy)
    
    async def cleanup(self):
        """清理资源"""
        # 停止所有健康检查任务
        for service_name in list(self.health_check_tasks.keys()):
            await self.stop_health_checks(service_name)
        
        self.unhealthy_instances.clear()
        await super().cleanup()
        logger.info("健康检查负载均衡器资源清理完成")
