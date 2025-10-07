"""
服务注册表 - 用于AI服务的注册和发现
基于Consul实现服务发现和注册
"""

import asyncio
import logging
import json
from typing import Dict, Any, List, Optional
from datetime import datetime
import aiohttp
try:
    import consul
    CONSUL_AVAILABLE = True
except ImportError:
    CONSUL_AVAILABLE = False
    consul = None

logger = logging.getLogger(__name__)


class ServiceRegistry:
    """服务注册表"""
    
    def __init__(self, consul_host: str = 'localhost', consul_port: int = 8500):
        """初始化服务注册表"""
        self.consul_host = consul_host
        self.consul_port = consul_port
        self.consul_client = None
        self.registered_services = {}
        
    async def initialize(self):
        """初始化服务注册表"""
        try:
            if CONSUL_AVAILABLE:
                # 创建Consul客户端
                self.consul_client = consul.Consul(
                    host=self.consul_host,
                    port=self.consul_port
                )
                
                # 测试连接
                if await self.health_check():
                    logger.info("服务注册表初始化成功")
                else:
                    raise Exception("Consul连接测试失败")
            else:
                raise Exception("Consul模块不可用")
            
        except Exception as e:
            logger.error(f"服务注册表初始化失败: {e}")
            # 如果Consul不可用，使用内存注册表
            self.consul_client = None
            logger.warning("使用内存服务注册表")
    
    async def register_service(self, service_info: Dict[str, Any]):
        """注册服务"""
        try:
            service_name = service_info['name']
            service_id = f"{service_name}-{service_info.get('host', 'localhost')}-{service_info.get('port', 8080)}"
            
            # 准备注册信息
            registration_data = {
                'ID': service_id,
                'Name': service_name,
                'Tags': service_info.get('tags', []),
                'Address': service_info.get('host', 'localhost'),
                'Port': service_info.get('port', 8080),
                'Check': {
                    'HTTP': f"http://{service_info.get('host', 'localhost')}:{service_info.get('port', 8080)}/health",
                    'Interval': '10s',
                    'Timeout': '3s'
                }
            }
            
            if self.consul_client:
                # 使用Consul注册
                self.consul_client.agent.service.register(
                    service_id,
                    service_name,
                    address=service_info.get('host', 'localhost'),
                    port=service_info.get('port', 8080),
                    tags=service_info.get('tags', []),
                    check=registration_data['Check']
                )
                logger.info(f"服务注册到Consul成功: {service_name}")
            else:
                # 使用内存注册表
                self.registered_services[service_id] = {
                    'service_info': service_info,
                    'registration_data': registration_data,
                    'registered_at': datetime.now(),
                    'status': 'healthy'
                }
                logger.info(f"服务注册到内存成功: {service_name}")
                
        except Exception as e:
            logger.error(f"服务注册失败: {e}")
            raise
    
    async def unregister_service(self, service_name: str):
        """注销服务"""
        try:
            if self.consul_client:
                # 从Consul注销
                services = self.consul_client.agent.services()
                for service_id, service_data in services.items():
                    if service_data['Service'] == service_name:
                        self.consul_client.agent.service.deregister(service_id)
                        logger.info(f"服务从Consul注销成功: {service_name}")
                        break
            else:
                # 从内存注册表注销
                services_to_remove = []
                for service_id, service_data in self.registered_services.items():
                    if service_data['service_info']['name'] == service_name:
                        services_to_remove.append(service_id)
                
                for service_id in services_to_remove:
                    del self.registered_services[service_id]
                
                logger.info(f"服务从内存注销成功: {service_name}")
                
        except Exception as e:
            logger.error(f"服务注销失败: {e}")
            raise
    
    async def get_service_instances(self, service_name: str) -> List[Dict[str, Any]]:
        """获取服务实例列表"""
        try:
            instances = []
            
            if self.consul_client:
                # 从Consul获取服务实例
                services = self.consul_client.health.service(service_name, passing=True)
                for service_data in services[1]:
                    service = service_data['Service']
                    instances.append({
                        'id': service['ID'],
                        'name': service['Service'],
                        'host': service['Address'],
                        'port': service['Port'],
                        'tags': service.get('Tags', []),
                        'status': 'healthy'
                    })
            else:
                # 从内存注册表获取服务实例
                for service_id, service_data in self.registered_services.items():
                    if service_data['service_info']['name'] == service_name:
                        service_info = service_data['service_info']
                        instances.append({
                            'id': service_id,
                            'name': service_name,
                            'host': service_info.get('host', 'localhost'),
                            'port': service_info.get('port', 8080),
                            'tags': service_info.get('tags', []),
                            'status': service_data['status']
                        })
            
            return instances
            
        except Exception as e:
            logger.error(f"获取服务实例失败: {e}")
            return []
    
    async def discover_service(self, service_name: str) -> Optional[Dict[str, Any]]:
        """发现服务"""
        try:
            instances = await self.get_service_instances(service_name)
            if instances:
                # 返回第一个健康实例
                return instances[0]
            return None
            
        except Exception as e:
            logger.error(f"服务发现失败: {e}")
            return None
    
    async def health_check(self) -> bool:
        """健康检查"""
        try:
            if self.consul_client:
                # 检查Consul连接
                leader = self.consul_client.status.leader()
                return leader is not None
            else:
                # 内存注册表总是健康的
                return True
                
        except Exception as e:
            logger.error(f"健康检查失败: {e}")
            return False
    
    async def get_all_services(self) -> Dict[str, List[Dict[str, Any]]]:
        """获取所有服务"""
        try:
            all_services = {}
            
            if self.consul_client:
                # 从Consul获取所有服务
                services = self.consul_client.catalog.services()
                for service_name in services[1].keys():
                    instances = await self.get_service_instances(service_name)
                    if instances:
                        all_services[service_name] = instances
            else:
                # 从内存注册表获取所有服务
                service_groups = {}
                for service_id, service_data in self.registered_services.items():
                    service_name = service_data['service_info']['name']
                    if service_name not in service_groups:
                        service_groups[service_name] = []
                    
                    service_info = service_data['service_info']
                    service_groups[service_name].append({
                        'id': service_id,
                        'name': service_name,
                        'host': service_info.get('host', 'localhost'),
                        'port': service_info.get('port', 8080),
                        'tags': service_info.get('tags', []),
                        'status': service_data['status']
                    })
                
                all_services = service_groups
            
            return all_services
            
        except Exception as e:
            logger.error(f"获取所有服务失败: {e}")
            return {}
    
    async def cleanup(self):
        """清理资源"""
        try:
            if self.consul_client:
                # 清理Consul连接 (python-consul没有close方法)
                pass
            
            self.registered_services.clear()
            logger.info("服务注册表资源清理完成")
            
        except Exception as e:
            logger.error(f"清理资源失败: {e}")


class MemoryServiceRegistry:
    """内存服务注册表 - 当Consul不可用时的备用方案"""
    
    def __init__(self):
        self.services = {}
        self.health_checks = {}
    
    async def register_service(self, service_info: Dict[str, Any]):
        """注册服务到内存"""
        service_name = service_info['name']
        service_id = f"{service_name}-{service_info.get('host', 'localhost')}-{service_info.get('port', 8080)}"
        
        self.services[service_id] = {
            'service_info': service_info,
            'registered_at': datetime.now(),
            'status': 'healthy'
        }
        
        logger.info(f"服务注册到内存成功: {service_name}")
    
    async def get_service_instances(self, service_name: str) -> List[Dict[str, Any]]:
        """获取服务实例"""
        instances = []
        for service_id, service_data in self.services.items():
            if service_data['service_info']['name'] == service_name:
                service_info = service_data['service_info']
                instances.append({
                    'id': service_id,
                    'name': service_name,
                    'host': service_info.get('host', 'localhost'),
                    'port': service_info.get('port', 8080),
                    'tags': service_info.get('tags', []),
                    'status': service_data['status']
                })
        
        return instances
    
    async def unregister_service(self, service_name: str):
        """注销服务"""
        services_to_remove = []
        for service_id, service_data in self.services.items():
            if service_data['service_info']['name'] == service_name:
                services_to_remove.append(service_id)
        
        for service_id in services_to_remove:
            del self.services[service_id]
        
        logger.info(f"服务从内存注销成功: {service_name}")
