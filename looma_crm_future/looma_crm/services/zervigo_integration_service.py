#!/usr/bin/env python3
"""
Looma CRM Zervigo集成服务
提供Looma CRM与Zervigo子系统的集成功能
"""

import logging
from typing import Dict, Any, List, Optional
from datetime import datetime

import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

from shared.integration.zervigo_client import ZervigoClient
from shared.database.unified_data_access import UnifiedDataAccess

logger = logging.getLogger(__name__)

class ZervigoIntegrationService:
    """Zervigo集成服务"""
    
    def __init__(self, zervigo_config: Dict[str, str], data_access: UnifiedDataAccess):
        """
        初始化集成服务
        
        Args:
            zervigo_config: Zervigo服务配置
            data_access: 统一数据访问层
        """
        self.zervigo_config = zervigo_config
        self.data_access = data_access
        self.zervigo_client: Optional[ZervigoClient] = None
    
    async def setup(self):
        """设置集成服务"""
        self.zervigo_client = ZervigoClient(self.zervigo_config)
        logger.info("Zervigo集成服务初始化完成")
    
    # ==================== 人才管理集成 ====================
    
    async def sync_talent_with_zervigo(self, talent_id: str, token: str) -> Dict[str, Any]:
        """
        同步人才数据到Zervigo系统
        
        Args:
            talent_id: 人才ID
            token: 认证token
            
        Returns:
            同步结果
        """
        try:
            # 从Looma CRM获取人才数据
            talent_data = await self.data_access.get_talent_data(talent_id)
            
            if not talent_data:
                return {
                    'success': False,
                    'error': f'Talent {talent_id} not found'
                }
            
            # 转换为Zervigo简历格式
            resume_data = self._convert_talent_to_resume(talent_data)
            
            # 调用Zervigo简历服务创建简历
            if not self.zervigo_client:
                await self.setup()
            
            async with self.zervigo_client as client:
                create_result = await client.create_resume(resume_data, token)
                
                if create_result['success']:
                    # 更新Looma CRM中的同步状态
                    await self._update_sync_status(talent_id, 'synced', create_result['resume_id'])
                    
                    logger.info(f"人才 {talent_id} 同步到Zervigo成功")
                    return {
                        'success': True,
                        'zervigo_resume_id': create_result['resume_id'],
                        'message': 'Talent synced to Zervigo successfully'
                    }
                else:
                    logger.error(f"人才 {talent_id} 同步到Zervigo失败: {create_result['error']}")
                    return {
                        'success': False,
                        'error': create_result['error']
                    }
                    
        except Exception as e:
            logger.error(f"同步人才数据异常: {e}")
            return {
                'success': False,
                'error': str(e)
            }
    
    async def get_talent_job_matches(self, talent_id: str, token: str) -> Dict[str, Any]:
        """
        获取人才职位匹配结果
        
        Args:
            talent_id: 人才ID
            token: 认证token
            
        Returns:
            匹配结果
        """
        try:
            # 获取Zervigo简历ID
            zervigo_resume_id = await self._get_zervigo_resume_id(talent_id)
            
            if not zervigo_resume_id:
                return {
                    'success': False,
                    'error': 'Talent not synced to Zervigo'
                }
            
            # 调用Zervigo职位匹配服务
            if not self.zervigo_client:
                await self.setup()
            
            async with self.zervigo_client as client:
                match_result = await client.match_jobs(zervigo_resume_id, token)
                
                if match_result['success']:
                    # 将匹配结果存储到Looma CRM
                    await self._store_match_results(talent_id, match_result['matches'])
                    
                    return {
                        'success': True,
                        'matches': match_result['matches'],
                        'talent_id': talent_id
                    }
                else:
                    return {
                        'success': False,
                        'error': match_result['error']
                    }
                    
        except Exception as e:
            logger.error(f"获取职位匹配结果异常: {e}")
            return {
                'success': False,
                'error': str(e)
            }
    
    # ==================== AI功能集成 ====================
    
    async def process_talent_with_ai(self, talent_id: str, token: str) -> Dict[str, Any]:
        """
        使用Zervigo AI服务处理人才数据
        
        Args:
            talent_id: 人才ID
            token: 认证token
            
        Returns:
            处理结果
        """
        try:
            # 获取人才数据
            talent_data = await self.data_access.get_talent_data(talent_id)
            
            if not talent_data:
                return {
                    'success': False,
                    'error': f'Talent {talent_id} not found'
                }
            
            # 准备AI处理数据
            ai_data = self._prepare_ai_data(talent_data)
            
            # 调用Zervigo AI服务
            if not self.zervigo_client:
                await self.setup()
            
            async with self.zervigo_client as client:
                # 处理简历
                process_result = await client.process_resume(ai_data, token)
                
                if process_result['success']:
                    # 生成向量
                    text_data = self._extract_text_from_talent(talent_data)
                    vector_result = await client.generate_vectors(text_data, token)
                    
                    if vector_result['success']:
                        # 更新人才数据
                        await self._update_talent_with_ai_results(
                            talent_id, 
                            process_result['processed_data'],
                            vector_result['vectors']
                        )
                        
                        return {
                            'success': True,
                            'processed_data': process_result['processed_data'],
                            'vectors': vector_result['vectors'],
                            'message': 'Talent processed with AI successfully'
                        }
                    else:
                        return {
                            'success': False,
                            'error': f'Vector generation failed: {vector_result["error"]}'
                        }
                else:
                    return {
                        'success': False,
                        'error': process_result['error']
                    }
                    
        except Exception as e:
            logger.error(f"AI处理人才数据异常: {e}")
            return {
                'success': False,
                'error': str(e)
            }
    
    async def ai_chat_about_talent(self, talent_id: str, message: str, token: str) -> Dict[str, Any]:
        """
        关于人才的AI聊天
        
        Args:
            talent_id: 人才ID
            message: 用户消息
            token: 认证token
            
        Returns:
            聊天响应
        """
        try:
            # 获取人才数据作为上下文
            talent_data = await self.data_access.get_talent_data(talent_id)
            
            if not talent_data:
                return {
                    'success': False,
                    'error': f'Talent {talent_id} not found'
                }
            
            # 准备聊天上下文
            context = {
                'talent_id': talent_id,
                'talent_data': talent_data,
                'timestamp': datetime.now().isoformat()
            }
            
            # 调用Zervigo AI聊天服务
            if not self.zervigo_client:
                await self.setup()
            
            async with self.zervigo_client as client:
                chat_result = await client.ai_chat(message, context, token)
                
                if chat_result['success']:
                    # 记录聊天历史
                    await self._record_chat_history(talent_id, message, chat_result['response'])
                    
                    return {
                        'success': True,
                        'response': chat_result['response'],
                        'context': chat_result['context']
                    }
                else:
                    return {
                        'success': False,
                        'error': chat_result['error']
                    }
                    
        except Exception as e:
            logger.error(f"AI聊天异常: {e}")
            return {
                'success': False,
                'error': str(e)
            }
    
    # ==================== 数据同步集成 ====================
    
    async def sync_all_talents_to_zervigo(self, token: str) -> Dict[str, Any]:
        """
        同步所有人才数据到Zervigo
        
        Args:
            token: 认证token
            
        Returns:
            同步结果
        """
        try:
            # 获取所有人才数据
            all_talents = await self.data_access.get_all_talents()
            
            sync_results = {
                'total': len(all_talents),
                'successful': 0,
                'failed': 0,
                'errors': []
            }
            
            for talent in all_talents:
                talent_id = talent.get('id')
                if talent_id:
                    result = await self.sync_talent_with_zervigo(talent_id, token)
                    
                    if result['success']:
                        sync_results['successful'] += 1
                    else:
                        sync_results['failed'] += 1
                        sync_results['errors'].append({
                            'talent_id': talent_id,
                            'error': result['error']
                        })
            
            logger.info(f"批量同步完成: 成功 {sync_results['successful']}, 失败 {sync_results['failed']}")
            
            return {
                'success': True,
                'results': sync_results
            }
            
        except Exception as e:
            logger.error(f"批量同步异常: {e}")
            return {
                'success': False,
                'error': str(e)
            }
    
    # ==================== 健康检查 ====================
    
    async def check_zervigo_services_health(self) -> Dict[str, Any]:
        """
        检查Zervigo服务健康状态
        
        Returns:
            健康状态
        """
        try:
            if not self.zervigo_client:
                await self.setup()
            
            async with self.zervigo_client as client:
                health_result = await client.check_all_services_health()
                
                return {
                    'success': True,
                    'health_status': health_result
                }
                
        except Exception as e:
            logger.error(f"健康检查异常: {e}")
            return {
                'success': False,
                'error': str(e)
            }
    
    # ==================== 私有辅助方法 ====================
    
    def _convert_talent_to_resume(self, talent_data: Dict[str, Any]) -> Dict[str, Any]:
        """将人才数据转换为简历格式"""
        return {
            'name': talent_data.get('basic', {}).get('name', ''),
            'email': talent_data.get('basic', {}).get('email', ''),
            'phone': talent_data.get('basic', {}).get('phone', ''),
            'experience': talent_data.get('basic', {}).get('experience', ''),
            'education': talent_data.get('basic', {}).get('education', ''),
            'skills': talent_data.get('basic', {}).get('skills', []),
            'summary': talent_data.get('basic', {}).get('summary', ''),
            'created_at': datetime.now().isoformat()
        }
    
    def _prepare_ai_data(self, talent_data: Dict[str, Any]) -> Dict[str, Any]:
        """准备AI处理数据"""
        return {
            'name': talent_data.get('basic', {}).get('name', ''),
            'experience': talent_data.get('basic', {}).get('experience', ''),
            'education': talent_data.get('basic', {}).get('education', ''),
            'skills': talent_data.get('basic', {}).get('skills', []),
            'summary': talent_data.get('basic', {}).get('summary', ''),
            'relationships': talent_data.get('relationships', {}),
            'vectors': talent_data.get('vectors', {})
        }
    
    def _extract_text_from_talent(self, talent_data: Dict[str, Any]) -> str:
        """从人才数据中提取文本"""
        basic = talent_data.get('basic', {})
        text_parts = [
            basic.get('name', ''),
            basic.get('summary', ''),
            basic.get('experience', ''),
            basic.get('education', ''),
            ' '.join(basic.get('skills', []))
        ]
        return ' '.join(filter(None, text_parts))
    
    async def _update_sync_status(self, talent_id: str, status: str, zervigo_id: Optional[str] = None):
        """更新同步状态"""
        # 这里应该更新数据库中的同步状态
        # 具体实现取决于数据库结构
        pass
    
    async def _get_zervigo_resume_id(self, talent_id: str) -> Optional[str]:
        """获取Zervigo简历ID"""
        # 这里应该从数据库查询Zervigo简历ID
        # 具体实现取决于数据库结构
        return None
    
    async def _store_match_results(self, talent_id: str, matches: List[Dict[str, Any]]):
        """存储匹配结果"""
        # 这里应该将匹配结果存储到数据库
        # 具体实现取决于数据库结构
        pass
    
    async def _update_talent_with_ai_results(self, talent_id: str, processed_data: Dict[str, Any], vectors: List[float]):
        """使用AI结果更新人才数据"""
        # 这里应该更新数据库中的AI处理结果
        # 具体实现取决于数据库结构
        pass
    
    async def _record_chat_history(self, talent_id: str, message: str, response: str):
        """记录聊天历史"""
        # 这里应该将聊天历史存储到数据库
        # 具体实现取决于数据库结构
        pass
