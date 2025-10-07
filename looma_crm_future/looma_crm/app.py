#!/usr/bin/env python3
"""
Looma CRM主应用 - 集成Zervigo子系统
基于Python Sanic框架，集成Zervigo基础设施服务
"""

import os
import time
import uuid
import logging
from datetime import datetime
from typing import Dict, Any
from sanic import Sanic, Request
from sanic.response import json as sanic_json
from sanic.exceptions import NotFound
from prometheus_client import Counter, Histogram, Gauge, generate_latest, CONTENT_TYPE_LATEST

# 导入共享组件
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from shared.database.unified_data_access import UnifiedDataAccess
from shared.middleware.zervigo_auth_middleware import ZervigoAuthMiddleware
from shared.integration.zervigo_client import ZervigoClient

# 导入Looma CRM组件
from services.zervigo_integration_service import ZervigoIntegrationService
from api.zervigo_integration_api import zervigo_integration_bp
from tracing import init_tracing, get_tracer

# Prometheus指标定义
http_requests_total = Counter('http_requests_total', 'Total HTTP requests', ['method', 'endpoint', 'status'])
http_request_duration = Histogram('http_request_duration_seconds', 'HTTP request duration', ['method', 'endpoint'])
active_connections = Gauge('active_connections', 'Number of active connections')
looma_operations_total = Counter('looma_operations_total', 'Total Looma operations', ['operation', 'status'])

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def create_app() -> Sanic:
    """创建Looma CRM应用"""
    
    # 初始化链路追踪
    tracer = init_tracing()
    if tracer:
        logger.info("Jaeger tracing initialized successfully")
    else:
        logger.warning("Failed to initialize Jaeger tracing")
    
    # 创建Sanic应用
    app = Sanic("looma_crm")
    
    # 配置应用
    app.config.update({
        'HOST': os.getenv('HOST', '0.0.0.0'),
        'PORT': int(os.getenv('PORT', 7500)),
        'DEBUG': os.getenv('DEBUG', 'False').lower() == 'true',
        'AUTO_RELOAD': os.getenv('AUTO_RELOAD', 'False').lower() == 'true'
    })
    
    # ==================== 初始化服务 ====================
    
    @app.before_server_start
    async def setup_services(app: Sanic, loop):
        """设置服务"""
        logger.info("正在初始化Looma CRM服务...")
        
        # 初始化统一数据访问层
        app.ctx.data_access = UnifiedDataAccess()
        await app.ctx.data_access.initialize()
        logger.info("统一数据访问层初始化完成")
        
        # 初始化Zervigo配置 (更新为Future版端口规划 7500-7555)
        zervigo_config = {
            'auth_service_url': os.getenv('ZERVIGO_AUTH_URL', 'http://localhost:7520'),  # Basic Server 1
            'ai_service_url': os.getenv('ZERVIGO_AI_URL', 'http://localhost:7540'),      # AI Service (待启动)
            'resume_service_url': os.getenv('ZERVIGO_RESUME_URL', 'http://localhost:7532'),  # Resume Service
            'job_service_url': os.getenv('ZERVIGO_JOB_URL', 'http://localhost:7539'),    # Job Service
            'company_service_url': os.getenv('ZERVIGO_COMPANY_URL', 'http://localhost:7534'),  # Company Service
            'user_service_url': os.getenv('ZERVIGO_USER_URL', 'http://localhost:7530')  # User Service
        }
        
        # 初始化Zervigo认证中间件
        app.ctx.zervigo_auth_middleware = ZervigoAuthMiddleware(zervigo_config)
        await app.ctx.zervigo_auth_middleware.setup()
        logger.info("Zervigo认证中间件初始化完成")
        
        # 初始化Zervigo集成服务
        app.ctx.zervigo_integration_service = ZervigoIntegrationService(
            zervigo_config, 
            app.ctx.data_access
        )
        await app.ctx.zervigo_integration_service.setup()
        logger.info("Zervigo集成服务初始化完成")
        
        logger.info("Looma CRM服务初始化完成")
    
    # ==================== 中间件设置 ====================
    
    @app.middleware('request')
    async def add_request_context(request: Request):
        """添加请求上下文"""
        request.ctx.start_time = time.time()
        request.ctx.request_id = str(uuid.uuid4())
    
    @app.middleware('response')
    async def add_response_headers(request: Request, response):
        """添加响应头"""
        response.headers['X-Service-Name'] = 'looma-crm'
        response.headers['X-Request-ID'] = request.ctx.request_id
        response.headers['X-Response-Time'] = str(time.time() - request.ctx.start_time)
    
    # ==================== 路由设置 ====================
    
    # 注册Zervigo集成API蓝图
    app.blueprint(zervigo_integration_bp)
    
    # Prometheus指标端点
    @app.route('/metrics', methods=['GET'])
    async def metrics(request: Request):
        """Prometheus指标端点"""
        try:
            from sanic.response import text
            metrics_data = generate_latest()
            # 将bytes转换为字符串
            if isinstance(metrics_data, bytes):
                metrics_data = metrics_data.decode('utf-8')
            return text(
                metrics_data,
                headers={'Content-Type': CONTENT_TYPE_LATEST}
            )
        except Exception as e:
            logger.error(f"Metrics endpoint error: {e}")
            from sanic.response import text
            return text(
                "# Metrics endpoint error\n",
                headers={'Content-Type': CONTENT_TYPE_LATEST}
            )
    
    # 健康检查端点
    @app.route('/health', methods=['GET'])
    async def health_check(request: Request):
        """健康检查"""
        try:
            # 检查Zervigo服务健康状态
            health_result = await app.ctx.zervigo_integration_service.check_zervigo_services_health()
            
            return sanic_json({
                'status': 'healthy',
                'service': 'looma-crm',
                'version': '1.0.0',
                'timestamp': datetime.now().isoformat(),
                'zervigo_services': health_result.get('health_status', {})
            })
        except Exception as e:
            logger.error(f"健康检查异常: {e}")
            return sanic_json({
                'status': 'unhealthy',
                'service': 'looma-crm',
                'error': str(e)
            }, status=500)
    
    # 根路径
    @app.route('/', methods=['GET'])
    async def root(request: Request):
        """根路径"""
        return sanic_json({
            'service': 'Looma CRM',
            'version': '1.0.0',
            'description': 'AI增强的人才关系管理系统',
            'integrations': {
                'zervigo': 'Zervigo子系统集成',
                'ai_services': '统一AI服务平台'
            },
            'endpoints': {
                'health': '/health',
                'zervigo_integration': '/api/zervigo/*'
            }
        })
    
    # 人才管理API (示例)
    @app.route('/api/talents', methods=['GET'])
    async def get_talents(request: Request):
        """获取人才列表"""
        try:
            # 这里应该实现人才列表获取逻辑
            # 暂时返回示例数据
            return sanic_json({
                'success': True,
                'talents': [],
                'total': 0,
                'message': '人才列表获取成功'
            })
        except Exception as e:
            logger.error(f"获取人才列表异常: {e}")
            return sanic_json({
                'error': '获取人才列表异常',
                'message': str(e)
            }, status=500)
    
    @app.route('/api/talents/<talent_id>', methods=['GET'])
    async def get_talent(request: Request, talent_id: str):
        """获取人才详情"""
        try:
            # 获取人才数据
            talent_data = await app.ctx.data_access.get_talent_data(talent_id)
            
            if talent_data:
                return sanic_json({
                    'success': True,
                    'talent': talent_data
                })
            else:
                return sanic_json({
                    'success': False,
                    'error': '人才不存在'
                }, status=404)
                
        except Exception as e:
            logger.error(f"获取人才详情异常: {e}")
            return sanic_json({
                'error': '获取人才详情异常',
                'message': str(e)
            }, status=500)
    
    # ==================== 错误处理 ====================
    
    @app.exception(NotFound)
    async def not_found_handler(request: Request, exception):
        """404错误处理"""
        return sanic_json({
            'error': '接口不存在',
            'code': 'NOT_FOUND',
            'path': request.path
        }, status=404)
    
    @app.exception(Exception)
    async def general_exception_handler(request: Request, exception):
        """通用异常处理"""
        logger.error(f"未处理的异常: {exception}")
        return sanic_json({
            'error': '服务器内部错误',
            'code': 'INTERNAL_ERROR',
            'message': str(exception) if app.config.DEBUG else '请联系管理员'
        }, status=500)
    
    # ==================== 服务关闭处理 ====================
    
    @app.after_server_stop
    async def cleanup_services(app: Sanic, loop):
        """清理服务"""
        logger.info("正在清理Looma CRM服务...")
        
        # 清理数据访问层
        if hasattr(app.ctx, 'data_access'):
            await app.ctx.data_access.close()
        
        logger.info("Looma CRM服务清理完成")
    
    return app

# 创建应用实例
app = create_app()

if __name__ == '__main__':
    # 导入必要的模块
    import time
    import uuid
    from datetime import datetime
    
    # 启动应用
    app.run(
        host=app.config.HOST,
        port=app.config.PORT,
        debug=app.config.DEBUG,
        auto_reload=app.config.AUTO_RELOAD
    )
