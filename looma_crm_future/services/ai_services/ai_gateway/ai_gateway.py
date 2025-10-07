"""
AI网关服务 - 统一AI服务入口
基于Python Sanic实现
"""

import asyncio
import logging
from typing import Dict, Any, Optional, List
from datetime import datetime

from sanic import Request
from sanic.response import json as sanic_json

from shared.utils.base_service import BaseAIService
from shared.utils.service_registry import ServiceRegistry
from shared.utils.load_balancer import LoadBalancer
from shared.utils.circuit_breaker import CircuitBreaker
from shared.utils.rate_limiter import RateLimiter

logger = logging.getLogger(__name__)


class AIGateway(BaseAIService):
    """AI网关服务 - 统一AI服务入口"""
    
    def __init__(self, port: int = 7510):
        """初始化AI网关"""
        super().__init__("ai-gateway", port)
        
        # 服务注册表
        self.service_registry = ServiceRegistry()
        
        # 负载均衡器
        self.load_balancer = LoadBalancer()
        
        # 熔断器
        self.circuit_breaker = CircuitBreaker()
        
        # 限流器
        self.rate_limiter = RateLimiter()
        
        # AI服务配置 - Future版本端口配置 (7510-7519)
        self.ai_services = {
            "resume": {
                "name": "resume-service",
                "port": 7511,  # Future版本简历AI服务端口
                "endpoints": ["/process", "/parse", "/vectorize", "/analyze", "/optimize"]
            },
            "matching": {
                "name": "matching-service", 
                "port": 7512,  # Future版本匹配服务端口
                "endpoints": ["/match", "/find_jobs", "/calculate_score"]
            },
            "chat": {
                "name": "chat-service",
                "port": 7513,  # Future版本聊天服务端口
                "endpoints": ["/chat", "/conversation", "/context"]
            },
            "vector": {
                "name": "vector-service",
                "port": 7514,  # Future版本向量服务端口
                "endpoints": ["/search", "/similarity", "/index"]
            },
            "auth": {
                "name": "auth-service",
                "port": 7515,  # Future版本认证服务端口
                "endpoints": ["/verify", "/token", "/permissions"]
            },
            "monitor": {
                "name": "monitor-service",
                "port": 7516,  # Future版本监控服务端口
                "endpoints": ["/metrics", "/health", "/alerts"]
            },
            "config": {
                "name": "config-service",
                "port": 7517,  # Future版本配置服务端口
                "endpoints": ["/config", "/parameters", "/settings"]
            }
        }
    
    def setup_routes(self):
        """设置AI网关路由"""
        super().setup_routes()
        
        # AI服务路由
        @self.app.post('/api/ai/<service_type>/<action>')
        async def route_ai_request(request: Request, service_type: str, action: str):
            """路由AI请求"""
            return await self.handle_ai_request(request, service_type, action)
        
        @self.app.get('/api/ai/services')
        async def list_ai_services(request: Request):
            """列出所有AI服务"""
            return await self.list_services(request)
        
        @self.app.get('/api/ai/services/<service_name>/health')
        async def check_service_health(request: Request, service_name: str):
            """检查服务健康状态"""
            return await self.check_service_health_status(request, service_name)
        
        # 服务管理路由
        @self.app.post('/api/ai/register')
        async def register_service(request: Request):
            """注册AI服务"""
            return await self.register_ai_service(request)
        
        @self.app.delete('/api/ai/unregister/<service_name>')
        async def unregister_service(request: Request, service_name: str):
            """注销AI服务"""
            return await self.unregister_ai_service(request, service_name)
        
        # 批量请求路由
        @self.app.post('/api/ai/batch')
        async def batch_ai_requests(request: Request):
            """批量AI请求"""
            return await self.handle_batch_requests(request)
    
    async def handle_ai_request(self, request: Request, service_type: str, action: str):
        """处理AI请求"""
        try:
            # 1. 请求验证
            validation_result = await self.validate_request(request, service_type, action)
            if not validation_result['valid']:
                return sanic_json(validation_result, status=400)
            
            # 2. 限流检查
            rate_limit_result = await self.rate_limiter.check_rate_limit(
                request.ctx.request_id, service_type
            )
            if not rate_limit_result['allowed']:
                return sanic_json(rate_limit_result, status=429)
            
            # 3. 服务发现
            service_info = await self.discover_service(service_type)
            if not service_info:
                return sanic_json({
                    'error': 'Service not found',
                    'service_type': service_type
                }, status=404)
            
            # 4. 负载均衡选择实例
            service_instance = await self.load_balancer.select_instance(service_info)
            if not service_instance:
                return sanic_json({
                    'error': 'No available service instances',
                    'service_type': service_type
                }, status=503)
            
            # 5. 熔断器检查
            circuit_result = await self.circuit_breaker.check_circuit(service_instance)
            if not circuit_result['allowed']:
                return sanic_json(circuit_result, status=503)
            
            # 6. 转发请求
            response = await self.forward_request(service_instance, action, request)
            
            # 7. 记录指标
            await self.record_request_metrics(service_type, action, response)
            
            return response
            
        except Exception as e:
            logger.error(f"处理AI请求失败: {e}")
            return await self.handle_error(request, e)
    
    async def validate_request(self, request: Request, service_type: str, action: str) -> Dict[str, Any]:
        """验证请求"""
        # 检查服务类型是否支持
        if service_type not in self.ai_services:
            return {
                'valid': False,
                'error': f'Unsupported service type: {service_type}',
                'supported_types': list(self.ai_services.keys())
            }
        
        # 检查动作是否支持
        service_config = self.ai_services[service_type]
        if f"/{action}" not in service_config['endpoints']:
            return {
                'valid': False,
                'error': f'Unsupported action: {action}',
                'supported_actions': [ep.lstrip('/') for ep in service_config['endpoints']]
            }
        
        # 检查请求数据
        try:
            request_data = request.json
            if not request_data:
                return {
                    'valid': False,
                    'error': 'Request data is required'
                }
        except Exception as e:
            return {
                'valid': False,
                'error': f'Invalid request data: {e}'
            }
        
        return {'valid': True}
    
    async def discover_service(self, service_type: str) -> Optional[Dict[str, Any]]:
        """服务发现"""
        service_config = self.ai_services.get(service_type)
        if not service_config:
            return None
        
        # 从服务注册表获取服务实例
        service_instances = await self.service_registry.get_service_instances(
            service_config['name']
        )
        
        if not service_instances:
            return None
        
        return {
            'name': service_config['name'],
            'type': service_type,
            'instances': service_instances,
            'endpoints': service_config['endpoints']
        }
    
    async def forward_request(self, service_instance: Dict[str, Any], action: str, request: Request):
        """转发请求到目标服务"""
        try:
            # 构建目标URL
            target_url = f"http://{service_instance['host']}:{service_instance['port']}/{action}"
            
            # 获取请求数据
            request_data = request.json
            
            # 添加网关上下文
            request_data['gateway_context'] = {
                'request_id': request.ctx.request_id,
                'service_name': self.service_name,
                'timestamp': datetime.now().isoformat(),
                'source_ip': request.ip
            }
            
            # 发送请求
            import aiohttp
            async with aiohttp.ClientSession() as session:
                async with session.post(target_url, json=request_data) as response:
                    response_data = await response.json()
                    
                    return sanic_json(response_data, status=response.status)
                    
        except Exception as e:
            logger.error(f"转发请求失败: {e}")
            raise
    
    async def list_services(self, request: Request):
        """列出所有AI服务"""
        services_info = []
        
        for service_type, config in self.ai_services.items():
            service_instances = await self.service_registry.get_service_instances(config['name'])
            
            services_info.append({
                'type': service_type,
                'name': config['name'],
                'port': config['port'],
                'endpoints': config['endpoints'],
                'instances': len(service_instances),
                'status': 'healthy' if service_instances else 'unhealthy'
            })
        
        return sanic_json({
            'services': services_info,
            'total': len(services_info),
            'timestamp': datetime.now().isoformat()
        })
    
    async def check_service_health_status(self, request: Request, service_name: str):
        """检查服务健康状态"""
        service_instances = await self.service_registry.get_service_instances(service_name)
        
        if not service_instances:
            return sanic_json({
                'service': service_name,
                'status': 'unhealthy',
                'reason': 'No instances found'
            }, status=503)
        
        # 检查每个实例的健康状态
        health_checks = []
        for instance in service_instances:
            try:
                import aiohttp
                async with aiohttp.ClientSession() as session:
                    health_url = f"http://{instance['host']}:{instance['port']}/health"
                    async with session.get(health_url, timeout=5) as response:
                        health_data = await response.json()
                        health_checks.append({
                            'instance': instance,
                            'status': health_data.get('status', 'unknown'),
                            'response_time': response.headers.get('X-Response-Time', 'unknown')
                        })
            except Exception as e:
                health_checks.append({
                    'instance': instance,
                    'status': 'unhealthy',
                    'error': str(e)
                })
        
        # 计算整体健康状态
        healthy_instances = [h for h in health_checks if h['status'] == 'healthy']
        overall_status = 'healthy' if healthy_instances else 'unhealthy'
        
        return sanic_json({
            'service': service_name,
            'status': overall_status,
            'total_instances': len(service_instances),
            'healthy_instances': len(healthy_instances),
            'health_checks': health_checks,
            'timestamp': datetime.now().isoformat()
        })
    
    async def register_ai_service(self, request: Request):
        """注册AI服务"""
        try:
            service_info = request.json
            
            # 验证服务信息
            required_fields = ['name', 'type', 'host', 'port', 'endpoints']
            for field in required_fields:
                if field not in service_info:
                    return sanic_json({
                        'error': f'Missing required field: {field}'
                    }, status=400)
            
            # 注册服务
            await self.service_registry.register_service(service_info)
            
            return sanic_json({
                'message': 'Service registered successfully',
                'service': service_info['name'],
                'timestamp': datetime.now().isoformat()
            })
            
        except Exception as e:
            logger.error(f"注册AI服务失败: {e}")
            return sanic_json({
                'error': 'Failed to register service',
                'message': str(e)
            }, status=500)
    
    async def unregister_ai_service(self, request: Request, service_name: str):
        """注销AI服务"""
        try:
            await self.service_registry.unregister_service(service_name)
            
            return sanic_json({
                'message': 'Service unregistered successfully',
                'service': service_name,
                'timestamp': datetime.now().isoformat()
            })
            
        except Exception as e:
            logger.error(f"注销AI服务失败: {e}")
            return sanic_json({
                'error': 'Failed to unregister service',
                'message': str(e)
            }, status=500)
    
    async def handle_batch_requests(self, request: Request):
        """处理批量AI请求"""
        try:
            batch_data = request.json
            requests = batch_data.get('requests', [])
            
            if not requests:
                return sanic_json({
                    'error': 'No requests provided'
                }, status=400)
            
            # 并行处理所有请求
            results = await asyncio.gather(
                *[self.process_batch_request(req) for req in requests],
                return_exceptions=True
            )
            
            return sanic_json({
                'results': results,
                'total': len(requests),
                'timestamp': datetime.now().isoformat()
            })
            
        except Exception as e:
            logger.error(f"处理批量请求失败: {e}")
            return sanic_json({
                'error': 'Failed to process batch requests',
                'message': str(e)
            }, status=500)
    
    async def process_batch_request(self, request_data: Dict[str, Any]):
        """处理单个批量请求"""
        try:
            service_type = request_data.get('service_type')
            action = request_data.get('action')
            data = request_data.get('data', {})
            
            # 创建模拟请求对象
            class MockRequest:
                def __init__(self, data):
                    self.json = data
                    self.ctx = type('Context', (), {'request_id': str(uuid.uuid4())})()
                    self.ip = '127.0.0.1'
            
            mock_request = MockRequest(data)
            
            # 处理请求
            response = await self.handle_ai_request(mock_request, service_type, action)
            
            return {
                'service_type': service_type,
                'action': action,
                'status': 'success',
                'data': response.json if hasattr(response, 'json') else response
            }
            
        except Exception as e:
            return {
                'service_type': request_data.get('service_type'),
                'action': request_data.get('action'),
                'status': 'error',
                'error': str(e)
            }
    
    async def record_request_metrics(self, service_type: str, action: str, response):
        """记录请求指标"""
        # 这里可以记录更详细的指标
        logger.info(f"AI请求指标: {service_type}/{action} - {response.status}")
    
    async def check_dependencies(self) -> Dict[str, bool]:
        """检查依赖服务"""
        dependencies = {}
        
        # 检查服务注册表
        try:
            await self.service_registry.health_check()
            dependencies['service_registry'] = True
        except:
            dependencies['service_registry'] = False
        
        # 检查各个AI服务
        for service_type, config in self.ai_services.items():
            try:
                service_instances = await self.service_registry.get_service_instances(config['name'])
                dependencies[f'ai_service_{service_type}'] = len(service_instances) > 0
            except:
                dependencies[f'ai_service_{service_type}'] = False
        
        return dependencies
    
    async def initialize(self):
        """初始化AI网关"""
        await super().initialize()
        
        # 初始化服务注册表
        await self.service_registry.initialize()
        
        # 初始化负载均衡器
        await self.load_balancer.initialize()
        
        # 初始化熔断器
        await self.circuit_breaker.initialize()
        
        # 初始化限流器
        await self.rate_limiter.initialize()
        
        logger.info("AI网关服务初始化完成")
    
    async def cleanup(self):
        """清理AI网关资源"""
        await super().cleanup()
        
        # 清理各个组件
        await self.service_registry.cleanup()
        await self.load_balancer.cleanup()
        await self.circuit_breaker.cleanup()
        await self.rate_limiter.cleanup()
        
        logger.info("AI网关服务资源清理完成")
