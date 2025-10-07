#!/usr/bin/env python3
"""
Zervigo子系统集成客户端
用于Looma CRM与Zervigo子系统的集成
"""

import asyncio
import json
import logging
from typing import Dict, Any, Optional, List
import aiohttp
from datetime import datetime

logger = logging.getLogger(__name__)

class ZervigoClient:
    """Zervigo子系统集成客户端"""
    
    def __init__(self, config: Dict[str, str]):
        """
        初始化Zervigo客户端
        
        Args:
            config: 配置字典，包含各服务的URL
        """
        self.config = config
        self.session: Optional[aiohttp.ClientSession] = None
        
        # 服务URL配置 (更新为Future版端口规划 7500-7555)
        self.auth_service_url = config.get('auth_service_url', 'http://localhost:7520')  # Basic Server 1
        self.ai_service_url = config.get('ai_service_url', 'http://localhost:7540')      # AI Service (待启动)
        self.resume_service_url = config.get('resume_service_url', 'http://localhost:7532')  # Resume Service
        self.job_service_url = config.get('job_service_url', 'http://localhost:7539')    # Job Service
        self.company_service_url = config.get('company_service_url', 'http://localhost:7534')  # Company Service
        self.user_service_url = config.get('user_service_url', 'http://localhost:7530')  # User Service
        
        # 超时配置
        self.timeout = aiohttp.ClientTimeout(total=30)
        
    async def __aenter__(self):
        """异步上下文管理器入口"""
        self.session = aiohttp.ClientSession(timeout=self.timeout)
        return self
        
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        """异步上下文管理器出口"""
        if self.session:
            await self.session.close()
    
    async def _make_request(self, method: str, url: str, **kwargs) -> Dict[str, Any]:
        """
        发起HTTP请求的通用方法
        
        Args:
            method: HTTP方法
            url: 请求URL
            **kwargs: 其他请求参数
            
        Returns:
            响应数据字典
        """
        if not self.session:
            raise RuntimeError("Client session not initialized. Use async context manager.")
        
        try:
            async with self.session.request(method, url, **kwargs) as response:
                response_data = await response.json()
                
                if response.status >= 400:
                    logger.error(f"HTTP {response.status} error: {response_data}")
                    return {
                        'success': False,
                        'error': response_data.get('error', f'HTTP {response.status} error'),
                        'status_code': response.status
                    }
                
                return {
                    'success': True,
                    'data': response_data,
                    'status_code': response.status
                }
                
        except aiohttp.ClientError as e:
            logger.error(f"Request failed: {e}")
            return {
                'success': False,
                'error': str(e),
                'status_code': 0
            }
        except Exception as e:
            logger.error(f"Unexpected error: {e}")
            return {
                'success': False,
                'error': str(e),
                'status_code': 0
            }
    
    # ==================== 认证服务集成 ====================
    
    async def verify_token(self, token: str) -> Dict[str, Any]:
        """
        验证JWT token
        
        Args:
            token: JWT token
            
        Returns:
            验证结果
        """
        headers = {
            'Authorization': f'Bearer {token}',
            'Content-Type': 'application/json'
        }
        url = f"{self.auth_service_url}/api/v1/auth/validate"
        
        payload = {'token': token}
        result = await self._make_request('POST', url, headers=headers, json=payload)
        
        if result['success']:
            logger.info("Token verification successful")
            user_data = result['data'].get('user', {})
            return {
                'valid': True,
                'user_info': user_data,
                'user_id': user_data.get('user_id'),
                'username': user_data.get('username'),
                'permissions': result['data'].get('permissions', [])
            }
        else:
            logger.warning(f"Token verification failed: {result['error']}")
            return {
                'valid': False,
                'error': result['error']
            }
    
    async def get_user_permissions(self, user_id: int) -> Dict[str, Any]:
        """
        获取用户权限
        
        Args:
            user_id: 用户ID
            
        Returns:
            用户权限信息
        """
        url = f"{self.auth_service_url}/api/users/{user_id}/permissions"
        
        result = await self._make_request('GET', url)
        
        if result['success']:
            return {
                'success': True,
                'permissions': result['data'].get('permissions', [])
            }
        else:
            return {
                'success': False,
                'error': result['error']
            }
    
    async def check_permission(self, user_id: int, permission: str) -> bool:
        """
        检查用户是否有特定权限
        
        Args:
            user_id: 用户ID
            permission: 权限名称
            
        Returns:
            是否有权限
        """
        permissions_result = await self.get_user_permissions(user_id)
        
        if permissions_result['success']:
            permissions = permissions_result['permissions']
            return permission in permissions
        
        return False
    
    # ==================== AI服务集成 ====================
    
    async def process_resume(self, resume_data: Dict[str, Any], token: str) -> Dict[str, Any]:
        """
        处理简历数据
        
        Args:
            resume_data: 简历数据
            token: 认证token
            
        Returns:
            处理结果
        """
        headers = {
            'Authorization': f'Bearer {token}',
            'Content-Type': 'application/json'
        }
        url = f"{self.ai_service_url}/api/ai/process-resume"
        
        result = await self._make_request('POST', url, headers=headers, json=resume_data)
        
        if result['success']:
            logger.info("Resume processing successful")
            return {
                'success': True,
                'processed_data': result['data']
            }
        else:
            logger.error(f"Resume processing failed: {result['error']}")
            return {
                'success': False,
                'error': result['error']
            }
    
    async def generate_vectors(self, text_data: str, token: str) -> Dict[str, Any]:
        """
        生成文本向量
        
        Args:
            text_data: 文本数据
            token: 认证token
            
        Returns:
            向量生成结果
        """
        headers = {
            'Authorization': f'Bearer {token}',
            'Content-Type': 'application/json'
        }
        url = f"{self.ai_service_url}/api/ai/generate-vectors"
        
        payload = {'text': text_data}
        result = await self._make_request('POST', url, headers=headers, json=payload)
        
        if result['success']:
            return {
                'success': True,
                'vectors': result['data'].get('vectors')
            }
        else:
            return {
                'success': False,
                'error': result['error']
            }
    
    async def ai_chat(self, message: str, context: Dict[str, Any], token: str) -> Dict[str, Any]:
        """
        AI聊天功能
        
        Args:
            message: 用户消息
            context: 对话上下文
            token: 认证token
            
        Returns:
            聊天响应
        """
        headers = {
            'Authorization': f'Bearer {token}',
            'Content-Type': 'application/json'
        }
        url = f"{self.ai_service_url}/api/ai/chat"
        
        payload = {
            'message': message,
            'context': context
        }
        result = await self._make_request('POST', url, headers=headers, json=payload)
        
        if result['success']:
            return {
                'success': True,
                'response': result['data'].get('response'),
                'context': result['data'].get('context', {})
            }
        else:
            return {
                'success': False,
                'error': result['error']
            }
    
    # ==================== 简历服务集成 ====================
    
    async def get_resume(self, resume_id: int, token: str) -> Dict[str, Any]:
        """
        获取简历信息
        
        Args:
            resume_id: 简历ID
            token: 认证token
            
        Returns:
            简历信息
        """
        headers = {'Authorization': f'Bearer {token}'}
        url = f"{self.resume_service_url}/api/resumes/{resume_id}"
        
        result = await self._make_request('GET', url, headers=headers)
        
        if result['success']:
            return {
                'success': True,
                'resume': result['data']
            }
        else:
            return {
                'success': False,
                'error': result['error']
            }
    
    async def create_resume(self, resume_data: Dict[str, Any], token: str) -> Dict[str, Any]:
        """
        创建简历
        
        Args:
            resume_data: 简历数据
            token: 认证token
            
        Returns:
            创建结果
        """
        headers = {
            'Authorization': f'Bearer {token}',
            'Content-Type': 'application/json'
        }
        url = f"{self.resume_service_url}/api/resumes"
        
        result = await self._make_request('POST', url, headers=headers, json=resume_data)
        
        if result['success']:
            return {
                'success': True,
                'resume_id': result['data'].get('id')
            }
        else:
            return {
                'success': False,
                'error': result['error']
            }
    
    # ==================== 职位服务集成 ====================
    
    async def get_jobs(self, filters: Dict[str, Any], token: str) -> Dict[str, Any]:
        """
        获取职位列表
        
        Args:
            filters: 筛选条件
            token: 认证token
            
        Returns:
            职位列表
        """
        headers = {'Authorization': f'Bearer {token}'}
        url = f"{self.job_service_url}/api/jobs"
        
        result = await self._make_request('GET', url, headers=headers, params=filters)
        
        if result['success']:
            return {
                'success': True,
                'jobs': result['data'].get('jobs', []),
                'total': result['data'].get('total', 0)
            }
        else:
            return {
                'success': False,
                'error': result['error']
            }
    
    async def match_jobs(self, resume_id: int, token: str) -> Dict[str, Any]:
        """
        职位匹配
        
        Args:
            resume_id: 简历ID
            token: 认证token
            
        Returns:
            匹配结果
        """
        headers = {'Authorization': f'Bearer {token}'}
        url = f"{self.job_service_url}/api/jobs/match/{resume_id}"
        
        result = await self._make_request('GET', url, headers=headers)
        
        if result['success']:
            return {
                'success': True,
                'matches': result['data'].get('matches', [])
            }
        else:
            return {
                'success': False,
                'error': result['error']
            }
    
    # ==================== 公司服务集成 ====================
    
    async def get_companies(self, filters: Dict[str, Any], token: str) -> Dict[str, Any]:
        """
        获取公司列表
        
        Args:
            filters: 筛选条件
            token: 认证token
            
        Returns:
            公司列表
        """
        headers = {'Authorization': f'Bearer {token}'}
        url = f"{self.company_service_url}/api/companies"
        
        result = await self._make_request('GET', url, headers=headers, params=filters)
        
        if result['success']:
            return {
                'success': True,
                'companies': result['data'].get('companies', []),
                'total': result['data'].get('total', 0)
            }
        else:
            return {
                'success': False,
                'error': result['error']
            }
    
    # ==================== 用户服务集成 ====================
    
    async def get_user_profile(self, user_id: int, token: str) -> Dict[str, Any]:
        """
        获取用户资料
        
        Args:
            user_id: 用户ID
            token: 认证token
            
        Returns:
            用户资料
        """
        headers = {'Authorization': f'Bearer {token}'}
        url = f"{self.user_service_url}/api/users/{user_id}"
        
        result = await self._make_request('GET', url, headers=headers)
        
        if result['success']:
            return {
                'success': True,
                'user': result['data']
            }
        else:
            return {
                'success': False,
                'error': result['error']
            }
    
    # ==================== 健康检查 ====================
    
    async def check_service_health(self, service_name: str) -> Dict[str, Any]:
        """
        检查服务健康状态
        
        Args:
            service_name: 服务名称
            
        Returns:
            健康状态
        """
        service_urls = {
            'auth': self.auth_service_url,
            'ai': self.ai_service_url,
            'resume': self.resume_service_url,
            'job': self.job_service_url,
            'company': self.company_service_url,
            'user': self.user_service_url
        }
        
        if service_name not in service_urls:
            return {
                'success': False,
                'error': f'Unknown service: {service_name}'
            }
        
        url = f"{service_urls[service_name]}/health"
        
        result = await self._make_request('GET', url)
        
        if result['success']:
            return {
                'success': True,
                'healthy': True,
                'status': result['data'].get('status', 'unknown')
            }
        else:
            return {
                'success': False,
                'healthy': False,
                'error': result['error']
            }
    
    async def check_all_services_health(self) -> Dict[str, Any]:
        """
        检查所有服务健康状态
        
        Returns:
            所有服务健康状态
        """
        services = ['auth', 'ai', 'resume', 'job', 'company', 'user']
        health_status = {}
        
        for service in services:
            health_status[service] = await self.check_service_health(service)
        
        return {
            'success': True,
            'services': health_status,
            'timestamp': datetime.now().isoformat()
        }
