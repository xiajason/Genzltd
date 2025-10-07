"""
统一AI服务基类 - 基于Python Sanic
所有AI服务的基础框架
"""

import asyncio
import time
import uuid
import logging
from datetime import datetime
from typing import Dict, Any, Optional

from sanic import Sanic, Request
from sanic.response import json as sanic_json
from prometheus_client import Counter, Histogram, Gauge

logger = logging.getLogger(__name__)


class BaseAIService:
    """统一AI服务基类"""
    
    def __init__(self, service_name: str, port: int):
        """初始化AI服务"""
        self.service_name = service_name
        self.port = port
        self.app = Sanic(service_name)
        
        # 指标收集 - 修复Prometheus指标名称（不能包含连字符）
        safe_service_name = service_name.replace('-', '_').replace(' ', '_')
        self.request_count = Counter(
            f'{safe_service_name}_requests_total',
            'Total number of requests',
            ['method', 'endpoint', 'status']
        )
        self.request_duration = Histogram(
            f'{safe_service_name}_request_duration_seconds',
            'Request duration in seconds',
            ['method', 'endpoint']
        )
        self.active_connections = Gauge(
            f'{safe_service_name}_active_connections',
            'Number of active connections'
        )
        
        # 服务状态
        self.is_healthy = True
        self.start_time = datetime.now()
        
        # 设置中间件和路由
        self.setup_middleware()
        self.setup_health_check()
        self.setup_metrics()
        self.setup_routes()
    
    def setup_middleware(self):
        """设置中间件"""
        @self.app.middleware('request')
        async def add_request_context(request: Request):
            """添加请求上下文"""
            request.ctx.request_id = str(uuid.uuid4())
            request.ctx.start_time = time.time()
            request.ctx.service_name = self.service_name
            
            # 增加活跃连接数
            self.active_connections.inc()
            
            logger.info(f"[{self.service_name}] 请求开始: {request.method} {request.path} - {request.ctx.request_id}")
        
        @self.app.middleware('response')
        async def add_response_headers(request: Request, response):
            """添加响应头"""
            # 计算响应时间
            duration = time.time() - request.ctx.start_time
            
            # 添加响应头
            response.headers['X-Service-Name'] = self.service_name
            response.headers['X-Request-ID'] = request.ctx.request_id
            response.headers['X-Response-Time'] = f"{duration:.4f}"
            response.headers['X-Timestamp'] = datetime.now().isoformat()
            
            # 记录指标
            self.request_count.labels(
                method=request.method,
                endpoint=request.path,
                status=response.status
            ).inc()
            
            self.request_duration.labels(
                method=request.method,
                endpoint=request.path
            ).observe(duration)
            
            # 减少活跃连接数
            self.active_connections.dec()
            
            logger.info(f"[{self.service_name}] 请求完成: {request.method} {request.path} - {response.status} - {duration:.4f}s")
    
    def setup_health_check(self):
        """健康检查端点"""
        @self.app.get('/health')
        async def health_check(request: Request):
            """健康检查"""
            health_status = await self.get_health_status()
            status_code = 200 if health_status['status'] == 'healthy' else 503
            
            return sanic_json(health_status, status=status_code)
        
        @self.app.get('/ready')
        async def readiness_check(request: Request):
            """就绪检查"""
            ready_status = await self.get_readiness_status()
            status_code = 200 if ready_status['ready'] else 503
            
            return sanic_json(ready_status, status=status_code)
    
    def setup_metrics(self):
        """指标端点"""
        @self.app.get('/metrics')
        async def get_metrics(request: Request):
            """获取Prometheus指标"""
            from prometheus_client import generate_latest, CONTENT_TYPE_LATEST
            
            metrics_data = generate_latest()
            return sanic_json(
                {'metrics': metrics_data.decode('utf-8')},
                headers={'Content-Type': CONTENT_TYPE_LATEST}
            )
    
    def setup_routes(self):
        """设置路由 - 子类需要重写"""
        @self.app.get('/')
        async def root(request: Request):
            """根路径"""
            return sanic_json({
                'service': self.service_name,
                'version': '1.0.0',
                'status': 'running',
                'uptime': str(datetime.now() - self.start_time),
                'timestamp': datetime.now().isoformat()
            })
    
    async def get_health_status(self) -> Dict[str, Any]:
        """获取健康状态 - 子类可以重写"""
        return {
            'status': 'healthy' if self.is_healthy else 'unhealthy',
            'service': self.service_name,
            'version': '1.0.0',
            'uptime': str(datetime.now() - self.start_time),
            'timestamp': datetime.now().isoformat(),
            'checks': {
                'service': 'healthy',
                'dependencies': await self.check_dependencies()
            }
        }
    
    async def get_readiness_status(self) -> Dict[str, Any]:
        """获取就绪状态 - 子类可以重写"""
        dependencies_ready = await self.check_dependencies()
        
        return {
            'ready': all(dependencies_ready.values()),
            'service': self.service_name,
            'timestamp': datetime.now().isoformat(),
            'dependencies': dependencies_ready
        }
    
    async def check_dependencies(self) -> Dict[str, bool]:
        """检查依赖服务 - 子类需要重写"""
        return {
            'database': True,
            'cache': True,
            'external_apis': True
        }
    
    async def start(self):
        """启动服务"""
        try:
            logger.info(f"启动 {self.service_name} 服务，端口: {self.port}")
            
            # 初始化服务
            await self.initialize()
            
            # 启动Sanic应用
            await self.app.run(
                host="0.0.0.0",
                port=self.port,
                workers=1,
                access_log=True,
                debug=False
            )
        except Exception as e:
            logger.error(f"启动 {self.service_name} 服务失败: {e}")
            raise
    
    async def stop(self):
        """停止服务"""
        try:
            logger.info(f"停止 {self.service_name} 服务")
            
            # 清理资源
            await self.cleanup()
            
            # 停止Sanic应用
            self.app.stop()
        except Exception as e:
            logger.error(f"停止 {self.service_name} 服务失败: {e}")
    
    async def initialize(self):
        """初始化服务 - 子类需要重写"""
        logger.info(f"{self.service_name} 服务初始化完成")
    
    async def cleanup(self):
        """清理资源 - 子类需要重写"""
        logger.info(f"{self.service_name} 服务资源清理完成")
    
    def register_service(self, service_registry_url: str):
        """注册服务到服务注册中心"""
        # 这里实现服务注册逻辑
        pass
    
    def deregister_service(self, service_registry_url: str):
        """从服务注册中心注销服务"""
        # 这里实现服务注销逻辑
        pass
    
    async def handle_error(self, request: Request, exception: Exception):
        """错误处理"""
        logger.error(f"[{self.service_name}] 请求处理错误: {exception}")
        
        return sanic_json({
            'error': 'Internal Server Error',
            'message': str(exception),
            'request_id': getattr(request.ctx, 'request_id', 'unknown'),
            'timestamp': datetime.now().isoformat()
        }, status=500)
    
    def get_service_info(self) -> Dict[str, Any]:
        """获取服务信息"""
        return {
            'name': self.service_name,
            'port': self.port,
            'version': '1.0.0',
            'start_time': self.start_time.isoformat(),
            'uptime': str(datetime.now() - self.start_time),
            'status': 'healthy' if self.is_healthy else 'unhealthy'
        }
