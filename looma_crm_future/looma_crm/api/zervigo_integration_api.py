#!/usr/bin/env python3
"""
Looma CRM Zervigo集成API
提供Looma CRM与Zervigo子系统集成的API接口
"""

import logging
from typing import Dict, Any
from sanic import Blueprint, Request
from sanic.response import json as sanic_json

import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

from looma_crm.services.zervigo_integration_service import ZervigoIntegrationService
from shared.middleware.zervigo_auth_middleware import require_auth

logger = logging.getLogger(__name__)

# 创建蓝图
zervigo_integration_bp = Blueprint('zervigo_integration', url_prefix='/api/zervigo')

@zervigo_integration_bp.route('/health', methods=['GET'])
async def check_zervigo_health(request: Request):
    """
    检查Zervigo服务健康状态
    
    Returns:
        Zervigo服务健康状态
    """
    try:
        # 获取集成服务
        integration_service = getattr(request.app.ctx, 'zervigo_integration_service', None)
        if not integration_service:
            return sanic_json({
                'error': 'Zervigo集成服务未配置',
                'code': 'INTEGRATION_SERVICE_NOT_CONFIGURED'
            }, status=500)
        
        # 检查健康状态
        health_result = await integration_service.check_zervigo_services_health()
        
        if health_result['success']:
            return sanic_json({
                'success': True,
                'health_status': health_result['health_status']
            })
        else:
            return sanic_json({
                'success': False,
                'error': health_result['error']
            }, status=500)
            
    except Exception as e:
        logger.error(f"健康检查异常: {e}")
        return sanic_json({
            'error': '健康检查异常',
            'message': str(e)
        }, status=500)

@zervigo_integration_bp.route('/talents/<talent_id>/sync', methods=['POST'], name='sync_talent')
@require_auth('talent:sync')
async def sync_talent_to_zervigo(request: Request, talent_id: str):
    """
    同步人才数据到Zervigo
    
    Args:
        talent_id: 人才ID
        
    Returns:
        同步结果
    """
    try:
        # 获取认证token
        auth_header = request.headers.get('Authorization', '')
        token = auth_header.replace('Bearer ', '') if auth_header.startswith('Bearer ') else ''
        
        if not token:
            return sanic_json({
                'error': '认证token缺失',
                'code': 'TOKEN_REQUIRED'
            }, status=401)
        
        # 获取集成服务
        integration_service = getattr(request.app.ctx, 'zervigo_integration_service', None)
        if not integration_service:
            return sanic_json({
                'error': 'Zervigo集成服务未配置',
                'code': 'INTEGRATION_SERVICE_NOT_CONFIGURED'
            }, status=500)
        
        # 执行同步
        sync_result = await integration_service.sync_talent_with_zervigo(talent_id, token)
        
        if sync_result['success']:
            return sanic_json({
                'success': True,
                'message': sync_result['message'],
                'zervigo_resume_id': sync_result.get('zervigo_resume_id')
            })
        else:
            return sanic_json({
                'success': False,
                'error': sync_result['error']
            }, status=400)
            
    except Exception as e:
        logger.error(f"同步人才数据异常: {e}")
        return sanic_json({
            'error': '同步异常',
            'message': str(e)
        }, status=500)

@zervigo_integration_bp.route('/talents/<talent_id>/matches', methods=['GET'], name='get_talent_matches')
@require_auth('talent:read')
async def get_talent_job_matches(request: Request, talent_id: str):
    """
    获取人才职位匹配结果
    
    Args:
        talent_id: 人才ID
        
    Returns:
        匹配结果
    """
    try:
        # 获取认证token
        auth_header = request.headers.get('Authorization', '')
        token = auth_header.replace('Bearer ', '') if auth_header.startswith('Bearer ') else ''
        
        if not token:
            return sanic_json({
                'error': '认证token缺失',
                'code': 'TOKEN_REQUIRED'
            }, status=401)
        
        # 获取集成服务
        integration_service = getattr(request.app.ctx, 'zervigo_integration_service', None)
        if not integration_service:
            return sanic_json({
                'error': 'Zervigo集成服务未配置',
                'code': 'INTEGRATION_SERVICE_NOT_CONFIGURED'
            }, status=500)
        
        # 获取匹配结果
        match_result = await integration_service.get_talent_job_matches(talent_id, token)
        
        if match_result['success']:
            return sanic_json({
                'success': True,
                'matches': match_result['matches'],
                'talent_id': match_result['talent_id']
            })
        else:
            return sanic_json({
                'success': False,
                'error': match_result['error']
            }, status=400)
            
    except Exception as e:
        logger.error(f"获取职位匹配结果异常: {e}")
        return sanic_json({
            'error': '获取匹配结果异常',
            'message': str(e)
        }, status=500)

@zervigo_integration_bp.route('/talents/<talent_id>/ai-process', methods=['POST'], name='ai_process_talent')
@require_auth('talent:ai_process')
async def process_talent_with_ai(request: Request, talent_id: str):
    """
    使用AI处理人才数据
    
    Args:
        talent_id: 人才ID
        
    Returns:
        处理结果
    """
    try:
        # 获取认证token
        auth_header = request.headers.get('Authorization', '')
        token = auth_header.replace('Bearer ', '') if auth_header.startswith('Bearer ') else ''
        
        if not token:
            return sanic_json({
                'error': '认证token缺失',
                'code': 'TOKEN_REQUIRED'
            }, status=401)
        
        # 获取集成服务
        integration_service = getattr(request.app.ctx, 'zervigo_integration_service', None)
        if not integration_service:
            return sanic_json({
                'error': 'Zervigo集成服务未配置',
                'code': 'INTEGRATION_SERVICE_NOT_CONFIGURED'
            }, status=500)
        
        # 执行AI处理
        process_result = await integration_service.process_talent_with_ai(talent_id, token)
        
        if process_result['success']:
            return sanic_json({
                'success': True,
                'message': process_result['message'],
                'processed_data': process_result.get('processed_data'),
                'vectors': process_result.get('vectors')
            })
        else:
            return sanic_json({
                'success': False,
                'error': process_result['error']
            }, status=400)
            
    except Exception as e:
        logger.error(f"AI处理人才数据异常: {e}")
        return sanic_json({
            'error': 'AI处理异常',
            'message': str(e)
        }, status=500)

@zervigo_integration_bp.route('/talents/<talent_id>/chat', methods=['POST'], name='ai_chat_talent')
@require_auth('talent:chat')
async def ai_chat_about_talent(request: Request, talent_id: str):
    """
    关于人才的AI聊天
    
    Args:
        talent_id: 人才ID
        
    Returns:
        聊天响应
    """
    try:
        # 获取请求数据
        request_data = request.json
        if not request_data or 'message' not in request_data:
            return sanic_json({
                'error': '消息内容缺失',
                'code': 'MESSAGE_REQUIRED'
            }, status=400)
        
        message = request_data['message']
        
        # 获取认证token
        auth_header = request.headers.get('Authorization', '')
        token = auth_header.replace('Bearer ', '') if auth_header.startswith('Bearer ') else ''
        
        if not token:
            return sanic_json({
                'error': '认证token缺失',
                'code': 'TOKEN_REQUIRED'
            }, status=401)
        
        # 获取集成服务
        integration_service = getattr(request.app.ctx, 'zervigo_integration_service', None)
        if not integration_service:
            return sanic_json({
                'error': 'Zervigo集成服务未配置',
                'code': 'INTEGRATION_SERVICE_NOT_CONFIGURED'
            }, status=500)
        
        # 执行AI聊天
        chat_result = await integration_service.ai_chat_about_talent(talent_id, message, token)
        
        if chat_result['success']:
            return sanic_json({
                'success': True,
                'response': chat_result['response'],
                'context': chat_result.get('context', {})
            })
        else:
            return sanic_json({
                'success': False,
                'error': chat_result['error']
            }, status=400)
            
    except Exception as e:
        logger.error(f"AI聊天异常: {e}")
        return sanic_json({
            'error': 'AI聊天异常',
            'message': str(e)
        }, status=500)

@zervigo_integration_bp.route('/sync-all', methods=['POST'], name='sync_all_talents')
@require_auth('admin:sync_all')
async def sync_all_talents_to_zervigo(request: Request):
    """
    同步所有人才数据到Zervigo
    
    Returns:
        同步结果
    """
    try:
        # 获取认证token
        auth_header = request.headers.get('Authorization', '')
        token = auth_header.replace('Bearer ', '') if auth_header.startswith('Bearer ') else ''
        
        if not token:
            return sanic_json({
                'error': '认证token缺失',
                'code': 'TOKEN_REQUIRED'
            }, status=401)
        
        # 获取集成服务
        integration_service = getattr(request.app.ctx, 'zervigo_integration_service', None)
        if not integration_service:
            return sanic_json({
                'error': 'Zervigo集成服务未配置',
                'code': 'INTEGRATION_SERVICE_NOT_CONFIGURED'
            }, status=500)
        
        # 执行批量同步
        sync_result = await integration_service.sync_all_talents_to_zervigo(token)
        
        if sync_result['success']:
            return sanic_json({
                'success': True,
                'results': sync_result['results']
            })
        else:
            return sanic_json({
                'success': False,
                'error': sync_result['error']
            }, status=400)
            
    except Exception as e:
        logger.error(f"批量同步异常: {e}")
        return sanic_json({
            'error': '批量同步异常',
            'message': str(e)
        }, status=500)
