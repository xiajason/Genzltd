#!/usr/bin/env python3
"""
Zervigo集成测试
测试Looma CRM与Zervigo子系统的集成功能
"""

import asyncio
import pytest
import aiohttp
from unittest.mock import Mock, AsyncMock, patch
from typing import Dict, Any

from shared.integration import ZervigoClient
from shared.middleware import ZervigoAuthMiddleware
from looma_crm.services import ZervigoIntegrationService
from shared.database.unified_data_access import UnifiedDataAccess

class TestZervigoClient:
    """测试Zervigo客户端"""
    
    @pytest.fixture
    def zervigo_config(self):
        """Zervigo配置"""
        return {
            'auth_service_url': 'http://localhost:8207',
            'ai_service_url': 'http://localhost:8000',
            'resume_service_url': 'http://localhost:8082',
            'job_service_url': 'http://localhost:8089',
            'company_service_url': 'http://localhost:8083',
            'user_service_url': 'http://localhost:8081'
        }
    
    @pytest.fixture
    def zervigo_client(self, zervigo_config):
        """Zervigo客户端实例"""
        return ZervigoClient(zervigo_config)
    
    @pytest.mark.asyncio
    async def test_verify_token_success(self, zervigo_client):
        """测试token验证成功"""
        # Mock响应
        mock_response = {
            'user_id': 123,
            'username': 'test_user',
            'permissions': ['talent:read', 'talent:write']
        }
        
        with patch('aiohttp.ClientSession.request') as mock_request:
            mock_request.return_value.__aenter__.return_value.json = AsyncMock(return_value=mock_response)
            mock_request.return_value.__aenter__.return_value.status = 200
            
            async with zervigo_client as client:
                result = await client.verify_token('valid_token')
                
                assert result['valid'] is True
                assert result['user_id'] == 123
                assert result['username'] == 'test_user'
                assert 'talent:read' in result['permissions']
    
    @pytest.mark.asyncio
    async def test_verify_token_failure(self, zervigo_client):
        """测试token验证失败"""
        with patch('aiohttp.ClientSession.request') as mock_request:
            mock_request.return_value.__aenter__.return_value.json = AsyncMock(return_value={'error': 'Invalid token'})
            mock_request.return_value.__aenter__.return_value.status = 401
            
            async with zervigo_client as client:
                result = await client.verify_token('invalid_token')
                
                assert result['valid'] is False
                assert 'error' in result
    
    @pytest.mark.asyncio
    async def test_process_resume_success(self, zervigo_client):
        """测试简历处理成功"""
        resume_data = {
            'name': 'John Doe',
            'experience': '5 years software development',
            'skills': ['Python', 'JavaScript', 'React']
        }
        
        mock_response = {
            'processed_data': {
                'extracted_skills': ['Python', 'JavaScript', 'React'],
                'experience_level': 'Senior',
                'summary': 'Experienced software developer'
            }
        }
        
        with patch('aiohttp.ClientSession.request') as mock_request:
            mock_request.return_value.__aenter__.return_value.json = AsyncMock(return_value=mock_response)
            mock_request.return_value.__aenter__.return_value.status = 200
            
            async with zervigo_client as client:
                result = await client.process_resume(resume_data, 'valid_token')
                
                assert result['success'] is True
                assert 'processed_data' in result
                assert 'extracted_skills' in result['processed_data']
    
    @pytest.mark.asyncio
    async def test_check_service_health(self, zervigo_client):
        """测试服务健康检查"""
        mock_response = {'status': 'healthy'}
        
        with patch('aiohttp.ClientSession.request') as mock_request:
            mock_request.return_value.__aenter__.return_value.json = AsyncMock(return_value=mock_response)
            mock_request.return_value.__aenter__.return_value.status = 200
            
            async with zervigo_client as client:
                result = await client.check_service_health('auth')
                
                assert result['success'] is True
                assert result['healthy'] is True
                assert result['status'] == 'healthy'

class TestZervigoAuthMiddleware:
    """测试Zervigo认证中间件"""
    
    @pytest.fixture
    def zervigo_config(self):
        """Zervigo配置"""
        return {
            'auth_service_url': 'http://localhost:8207',
            'ai_service_url': 'http://localhost:8000',
            'resume_service_url': 'http://localhost:8082',
            'job_service_url': 'http://localhost:8089',
            'company_service_url': 'http://localhost:8083',
            'user_service_url': 'http://localhost:8081'
        }
    
    @pytest.fixture
    def auth_middleware(self, zervigo_config):
        """认证中间件实例"""
        return ZervigoAuthMiddleware(zervigo_config)
    
    @pytest.mark.asyncio
    async def test_authenticate_request_success(self, auth_middleware):
        """测试请求认证成功"""
        # Mock请求
        mock_request = Mock()
        mock_request.headers = {'Authorization': 'Bearer valid_token'}
        mock_request.ctx = Mock()
        
        # Mock Zervigo客户端
        mock_client = Mock()
        mock_client.verify_token = AsyncMock(return_value={
            'valid': True,
            'user_id': 123,
            'username': 'test_user',
            'permissions': ['talent:read']
        })
        
        with patch.object(auth_middleware, 'zervigo_client', mock_client):
            result = await auth_middleware.authenticate_request(mock_request)
            
            assert result is None  # 认证成功返回None
            assert mock_request.ctx.user_id == 123
            assert mock_request.ctx.username == 'test_user'
    
    @pytest.mark.asyncio
    async def test_authenticate_request_failure(self, auth_middleware):
        """测试请求认证失败"""
        # Mock请求
        mock_request = Mock()
        mock_request.headers = {'Authorization': 'Bearer invalid_token'}
        
        # Mock Zervigo客户端
        mock_client = Mock()
        mock_client.verify_token = AsyncMock(return_value={
            'valid': False,
            'error': 'Invalid token'
        })
        
        with patch.object(auth_middleware, 'zervigo_client', mock_client):
            result = await auth_middleware.authenticate_request(mock_request)
            
            assert result is not None  # 认证失败返回错误响应
            assert result.status == 401

class TestZervigoIntegrationService:
    """测试Zervigo集成服务"""
    
    @pytest.fixture
    def zervigo_config(self):
        """Zervigo配置"""
        return {
            'auth_service_url': 'http://localhost:8207',
            'ai_service_url': 'http://localhost:8000',
            'resume_service_url': 'http://localhost:8082',
            'job_service_url': 'http://localhost:8089',
            'company_service_url': 'http://localhost:8083',
            'user_service_url': 'http://localhost:8081'
        }
    
    @pytest.fixture
    def mock_data_access(self):
        """Mock数据访问层"""
        mock_data_access = Mock(spec=UnifiedDataAccess)
        mock_data_access.get_talent_data = AsyncMock(return_value={
            'basic': {
                'name': 'John Doe',
                'email': 'john@example.com',
                'experience': '5 years software development',
                'skills': ['Python', 'JavaScript']
            },
            'relationships': {},
            'vectors': {}
        })
        return mock_data_access
    
    @pytest.fixture
    def integration_service(self, zervigo_config, mock_data_access):
        """集成服务实例"""
        return ZervigoIntegrationService(zervigo_config, mock_data_access)
    
    @pytest.mark.asyncio
    async def test_sync_talent_with_zervigo_success(self, integration_service):
        """测试人才同步成功"""
        # Mock Zervigo客户端
        mock_client = Mock()
        mock_client.create_resume = AsyncMock(return_value={
            'success': True,
            'resume_id': 456
        })
        
        with patch.object(integration_service, 'zervigo_client', mock_client):
            result = await integration_service.sync_talent_with_zervigo('talent_123', 'valid_token')
            
            assert result['success'] is True
            assert result['zervigo_resume_id'] == 456
            assert 'message' in result
    
    @pytest.mark.asyncio
    async def test_process_talent_with_ai_success(self, integration_service):
        """测试AI处理人才数据成功"""
        # Mock Zervigo客户端
        mock_client = Mock()
        mock_client.process_resume = AsyncMock(return_value={
            'success': True,
            'processed_data': {
                'extracted_skills': ['Python', 'JavaScript'],
                'experience_level': 'Senior'
            }
        })
        mock_client.generate_vectors = AsyncMock(return_value={
            'success': True,
            'vectors': [0.1, 0.2, 0.3, 0.4, 0.5]
        })
        
        with patch.object(integration_service, 'zervigo_client', mock_client):
            result = await integration_service.process_talent_with_ai('talent_123', 'valid_token')
            
            assert result['success'] is True
            assert 'processed_data' in result
            assert 'vectors' in result
            assert 'message' in result
    
    @pytest.mark.asyncio
    async def test_ai_chat_about_talent_success(self, integration_service):
        """测试AI聊天成功"""
        # Mock Zervigo客户端
        mock_client = Mock()
        mock_client.ai_chat = AsyncMock(return_value={
            'success': True,
            'response': 'John Doe is an experienced software developer with 5 years of experience.',
            'context': {'talent_id': 'talent_123'}
        })
        
        with patch.object(integration_service, 'zervigo_client', mock_client):
            result = await integration_service.ai_chat_about_talent(
                'talent_123', 
                'Tell me about this talent', 
                'valid_token'
            )
            
            assert result['success'] is True
            assert 'response' in result
            assert 'John Doe' in result['response']

class TestIntegrationEndToEnd:
    """端到端集成测试"""
    
    @pytest.mark.asyncio
    async def test_full_integration_flow(self):
        """测试完整集成流程"""
        # 这个测试需要实际的Zervigo服务运行
        # 在CI/CD环境中可以跳过或使用测试容器
        
        zervigo_config = {
            'auth_service_url': 'http://localhost:8207',
            'ai_service_url': 'http://localhost:8000',
            'resume_service_url': 'http://localhost:8082',
            'job_service_url': 'http://localhost:8089',
            'company_service_url': 'http://localhost:8083',
            'user_service_url': 'http://localhost:8081'
        }
        
        # 测试服务健康检查
        async with ZervigoClient(zervigo_config) as client:
            health_result = await client.check_all_services_health()
            
            # 这里应该根据实际服务状态进行断言
            # 在测试环境中，某些服务可能不可用
            assert 'services' in health_result
            assert 'timestamp' in health_result

if __name__ == '__main__':
    # 运行测试
    pytest.main([__file__, '-v'])
