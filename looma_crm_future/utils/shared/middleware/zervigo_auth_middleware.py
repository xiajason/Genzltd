#!/usr/bin/env python3
"""
Zervigo认证中间件
用于Looma CRM与Zervigo认证服务的集成
"""

import logging
from typing import Optional, Dict, Any
from sanic import Request, HTTPResponse
from sanic.response import json as sanic_json

from ..integration import ZervigoClient

logger = logging.getLogger(__name__)

class ZervigoAuthMiddleware:
    """Zervigo认证中间件"""
    
    def __init__(self, zervigo_config: Dict[str, str]):
        """
        初始化认证中间件
        
        Args:
            zervigo_config: Zervigo服务配置
        """
        self.zervigo_config = zervigo_config
        self.zervigo_client: Optional[ZervigoClient] = None
    
    async def setup(self):
        """设置中间件"""
        self.zervigo_client = ZervigoClient(self.zervigo_config)
        logger.info("Zervigo认证中间件初始化完成")
    
    async def authenticate_request(self, request: Request) -> Optional[HTTPResponse]:
        """
        认证请求
        
        Args:
            request: Sanic请求对象
            
        Returns:
            如果认证失败返回错误响应，成功返回None
        """
        try:
            # 获取Authorization头
            auth_header = request.headers.get('Authorization')
            if not auth_header:
                return sanic_json({
                    "error": "认证失败",
                    "code": "AUTH_REQUIRED",
                    "message": "请提供有效的认证信息"
                }, status=401)
            
            # 检查Bearer token格式
            if not auth_header.startswith('Bearer '):
                return sanic_json({
                    "error": "认证失败",
                    "code": "INVALID_AUTH_FORMAT",
                    "message": "认证格式无效，请使用Bearer token"
                }, status=401)
            
            # 提取token
            token = auth_header.replace('Bearer ', '')
            
            # 使用Zervigo客户端验证token
            if not self.zervigo_client:
                await self.setup()
            
            async with self.zervigo_client as client:
                auth_result = await client.verify_token(token)
                
                if not auth_result['valid']:
                    logger.warning(f"Token验证失败: {auth_result.get('error', 'Unknown error')}")
                    return sanic_json({
                        "error": "认证失败",
                        "code": "INVALID_TOKEN",
                        "message": "认证token无效或已过期"
                    }, status=401)
                
                # 将用户信息存储到请求上下文
                request.ctx.user_id = auth_result['user_id']
                request.ctx.username = auth_result['username']
                request.ctx.permissions = auth_result['permissions']
                request.ctx.user_info = auth_result['user_info']
                
                logger.info(f"用户认证成功: {auth_result['username']} (ID: {auth_result['user_id']})")
                return None  # 认证成功，继续处理
                
        except Exception as e:
            logger.error(f"认证过程发生异常: {e}")
            return sanic_json({
                "error": "认证异常",
                "code": "AUTH_ERROR",
                "message": "认证过程发生错误"
            }, status=500)
    
    async def check_permission(self, request: Request, required_permission: str) -> bool:
        """
        检查用户权限
        
        Args:
            request: Sanic请求对象
            required_permission: 需要的权限
            
        Returns:
            是否有权限
        """
        try:
            user_id = getattr(request.ctx, 'user_id', None)
            if not user_id:
                return False
            
            if not self.zervigo_client:
                await self.setup()
            
            async with self.zervigo_client as client:
                has_permission = await client.check_permission(user_id, required_permission)
                return has_permission
                
        except Exception as e:
            logger.error(f"权限检查异常: {e}")
            return False
    
    async def get_user_permissions(self, request: Request) -> list:
        """
        获取用户权限列表
        
        Args:
            request: Sanic请求对象
            
        Returns:
            权限列表
        """
        try:
            user_id = getattr(request.ctx, 'user_id', None)
            if not user_id:
                return []
            
            if not self.zervigo_client:
                await self.setup()
            
            async with self.zervigo_client as client:
                permissions_result = await client.get_user_permissions(user_id)
                
                if permissions_result['success']:
                    return permissions_result['permissions']
                else:
                    logger.warning(f"获取用户权限失败: {permissions_result['error']}")
                    return []
                    
        except Exception as e:
            logger.error(f"获取用户权限异常: {e}")
            return []

def create_auth_middleware(zervigo_config: Dict[str, str]):
    """
    创建认证中间件工厂函数
    
    Args:
        zervigo_config: Zervigo服务配置
        
    Returns:
        认证中间件实例
    """
    middleware = ZervigoAuthMiddleware(zervigo_config)
    return middleware

def require_auth(required_permission: Optional[str] = None):
    """
    认证装饰器
    
    Args:
        required_permission: 需要的权限（可选）
        
    Returns:
        装饰器函数
    """
    def decorator(func):
        async def wrapper(request: Request, *args, **kwargs):
            # 获取认证中间件
            auth_middleware = getattr(request.app.ctx, 'zervigo_auth_middleware', None)
            if not auth_middleware:
                return sanic_json({
                    "error": "认证中间件未配置",
                    "code": "AUTH_MIDDLEWARE_NOT_CONFIGURED"
                }, status=500)
            
            # 执行认证
            auth_response = await auth_middleware.authenticate_request(request)
            if auth_response:
                return auth_response
            
            # 检查权限（如果指定了权限要求）
            if required_permission:
                has_permission = await auth_middleware.check_permission(request, required_permission)
                if not has_permission:
                    return sanic_json({
                        "error": "权限不足",
                        "code": "INSUFFICIENT_PERMISSIONS",
                        "message": f"需要权限: {required_permission}"
                    }, status=403)
            
            # 执行原函数
            return await func(request, *args, **kwargs)
        
        return wrapper
    return decorator
