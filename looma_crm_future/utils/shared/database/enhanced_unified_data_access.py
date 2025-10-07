#!/usr/bin/env python3
"""
增强的统一数据访问层
集成数据映射和验证功能
解决数据一致性问题
"""

import asyncio
import logging
from typing import Dict, Any, Optional, List
from datetime import datetime

from .unified_data_access import UnifiedDataAccess
from .data_mappers import DataMappingService
from .data_validators import ValidationService

logger = logging.getLogger(__name__)

class EnhancedUnifiedDataAccess(UnifiedDataAccess):
    """增强的统一数据访问层"""
    
    def __init__(self):
        super().__init__()
        self.mapping_service = DataMappingService()
        self.validation_service = ValidationService()
        self.sync_queue = asyncio.Queue()
        self.sync_worker_running = False
    
    async def initialize(self):
        """初始化增强的数据访问层"""
        await super().initialize()
        
        # 启动数据同步工作器
        if not self.sync_worker_running:
            asyncio.create_task(self._sync_worker())
            self.sync_worker_running = True
        
        logger.info("增强的统一数据访问层初始化完成")
    
    async def get_talent_data(self, talent_id: str) -> Dict[str, Any]:
        """获取人才数据（增强版）"""
        try:
            logger.info(f"获取人才数据: {talent_id}")
            
            # 从Looma CRM数据库获取数据
            looma_data = await self._get_looma_talent_data(talent_id)
            
            if not looma_data:
                # 如果Looma CRM中没有数据，尝试从Zervigo获取并映射
                zervigo_user_id = talent_id.replace('talent_', '')
                zervigo_data = await self._get_zervigo_user_data(zervigo_user_id)
                
                if zervigo_data:
                    # 映射数据
                    looma_data = await self.mapping_service.map_data(
                        "zervigo", "looma_crm", {"user": zervigo_data}
                    )
                    
                    # 验证映射后的数据
                    if looma_data:
                        validation_result = await self.validation_service.validate_data(
                            looma_data, "looma_talent"
                        )
                        
                        if validation_result.is_valid:
                            # 保存映射后的数据
                            await self._save_looma_talent_data(looma_data)
                            logger.info(f"从Zervigo映射并保存人才数据: {talent_id}")
                        else:
                            logger.error(f"映射后数据验证失败: {validation_result.errors}")
                            return {}
            
            # 验证最终数据
            if looma_data:
                validation_result = await self.validation_service.validate_data(
                    looma_data, "looma_talent"
                )
                
                if not validation_result.is_valid:
                    logger.warning(f"人才数据验证失败: {validation_result.errors}")
                
                # 添加验证信息到返回数据
                looma_data['_validation'] = validation_result.to_dict()
            
            return looma_data or {}
            
        except Exception as e:
            logger.error(f"获取人才数据失败: {e}")
            return {}
    
    async def save_talent_data(self, talent_data: Dict[str, Any]) -> bool:
        """保存人才数据（增强版）"""
        try:
            logger.info(f"保存人才数据: {talent_data.get('id', 'unknown')}")
            
            # 验证数据
            validation_result = await self.validation_service.validate_data(
                talent_data, "looma_talent"
            )
            
            if not validation_result.is_valid:
                logger.error(f"人才数据验证失败: {validation_result.errors}")
                return False
            
            # 保存到Looma CRM数据库
            success = await self._save_looma_talent_data(talent_data)
            
            if success and talent_data.get('zervigo_user_id'):
                # 准备同步到Zervigo
                sync_data = {
                    "type": "talent_update",
                    "looma_data": talent_data,
                    "timestamp": datetime.now().isoformat()
                }
                
                # 添加到同步队列
                await self.sync_queue.put(sync_data)
                logger.info(f"人才数据已添加到同步队列: {talent_data.get('id')}")
            
            return success
            
        except Exception as e:
            logger.error(f"保存人才数据失败: {e}")
            return False
    
    async def get_project_data(self, project_id: str) -> Dict[str, Any]:
        """获取项目数据（增强版）"""
        try:
            logger.info(f"获取项目数据: {project_id}")
            
            # 从Looma CRM数据库获取数据
            looma_data = await self._get_looma_project_data(project_id)
            
            if not looma_data:
                # 如果Looma CRM中没有数据，尝试从Zervigo获取并映射
                zervigo_job_id = project_id.replace('project_', '')
                zervigo_data = await self._get_zervigo_job_data(zervigo_job_id)
                
                if zervigo_data:
                    # 映射数据
                    looma_data = await self.mapping_service.map_data(
                        "zervigo", "looma_crm", {"job": zervigo_data}
                    )
                    
                    # 验证映射后的数据
                    if looma_data:
                        validation_result = await self.validation_service.validate_data(
                            looma_data, "looma_project"
                        )
                        
                        if validation_result.is_valid:
                            # 保存映射后的数据
                            await self._save_looma_project_data(looma_data)
                            logger.info(f"从Zervigo映射并保存项目数据: {project_id}")
                        else:
                            logger.error(f"映射后数据验证失败: {validation_result.errors}")
                            return {}
            
            return looma_data or {}
            
        except Exception as e:
            logger.error(f"获取项目数据失败: {e}")
            return {}
    
    async def save_project_data(self, project_data: Dict[str, Any]) -> bool:
        """保存项目数据（增强版）"""
        try:
            logger.info(f"保存项目数据: {project_data.get('id', 'unknown')}")
            
            # 验证数据
            validation_result = await self.validation_service.validate_data(
                project_data, "looma_project"
            )
            
            if not validation_result.is_valid:
                logger.error(f"项目数据验证失败: {validation_result.errors}")
                return False
            
            # 保存到Looma CRM数据库
            success = await self._save_looma_project_data(project_data)
            
            if success and project_data.get('zervigo_job_id'):
                # 准备同步到Zervigo
                sync_data = {
                    "type": "project_update",
                    "looma_data": project_data,
                    "timestamp": datetime.now().isoformat()
                }
                
                # 添加到同步队列
                await self.sync_queue.put(sync_data)
                logger.info(f"项目数据已添加到同步队列: {project_data.get('id')}")
            
            return success
            
        except Exception as e:
            logger.error(f"保存项目数据失败: {e}")
            return False
    
    async def sync_talent_skills_from_resume(self, talent_id: str) -> bool:
        """从简历同步人才技能数据"""
        try:
            logger.info(f"从简历同步人才技能: {talent_id}")
            
            # 获取Zervigo用户ID
            zervigo_user_id = talent_id.replace('talent_', '')
            
            # 从Zervigo简历服务获取数据
            resume_data = await self._get_zervigo_resume_data(zervigo_user_id)
            
            if resume_data:
                # 映射技能数据
                skills_data = await self.mapping_service.map_data(
                    "zervigo", "looma_crm", {"resume": resume_data}
                )
                
                if skills_data:
                    # 获取现有人才数据
                    talent_data = await self._get_looma_talent_data(talent_id)
                    
                    if talent_data:
                        # 更新技能相关字段
                        talent_data.update(skills_data)
                        talent_data['updated_at'] = datetime.now().isoformat()
                        
                        # 验证更新后的数据
                        validation_result = await self.validation_service.validate_data(
                            talent_data, "looma_talent"
                        )
                        
                        if validation_result.is_valid:
                            # 保存更新后的数据
                            success = await self._save_looma_talent_data(talent_data)
                            logger.info(f"人才技能同步成功: {talent_id}")
                            return success
                        else:
                            logger.error(f"技能同步后数据验证失败: {validation_result.errors}")
            
            return False
            
        except Exception as e:
            logger.error(f"从简历同步人才技能失败: {e}")
            return False
    
    async def validate_data_consistency(self, talent_id: str) -> Dict[str, Any]:
        """验证数据一致性"""
        try:
            logger.info(f"验证数据一致性: {talent_id}")
            
            # 获取Looma CRM数据
            looma_data = await self._get_looma_talent_data(talent_id)
            
            if not looma_data:
                return {"error": "未找到Looma CRM数据"}
            
            # 获取Zervigo数据
            zervigo_user_id = looma_data.get('zervigo_user_id')
            if not zervigo_user_id:
                return {"error": "未找到Zervigo用户ID"}
            
            zervigo_data = await self._get_zervigo_user_data(str(zervigo_user_id))
            
            if not zervigo_data:
                return {"error": "未找到Zervigo数据"}
            
            # 验证一致性
            consistency_result = await self.validation_service.validate_consistency(
                looma_data, zervigo_data
            )
            
            return {
                "talent_id": talent_id,
                "zervigo_user_id": zervigo_user_id,
                "consistency_result": consistency_result.to_dict(),
                "looma_data": looma_data,
                "zervigo_data": zervigo_data
            }
            
        except Exception as e:
            logger.error(f"验证数据一致性失败: {e}")
            return {"error": str(e)}
    
    async def _sync_worker(self):
        """数据同步工作器"""
        logger.info("数据同步工作器启动")
        
        while True:
            try:
                # 从队列获取同步任务
                sync_data = await self.sync_queue.get()
                
                if sync_data["type"] == "talent_update":
                    await self._sync_talent_to_zervigo(sync_data["looma_data"])
                elif sync_data["type"] == "project_update":
                    await self._sync_project_to_zervigo(sync_data["looma_data"])
                
                # 标记任务完成
                self.sync_queue.task_done()
                
            except Exception as e:
                logger.error(f"数据同步工作器错误: {e}")
                await asyncio.sleep(5)  # 错误后等待5秒
    
    async def _sync_talent_to_zervigo(self, looma_data: Dict[str, Any]):
        """同步人才数据到Zervigo"""
        try:
            # 反向映射数据
            zervigo_data = await self.mapping_service.reverse_map_data(
                "looma_crm", "zervigo", {"talent": looma_data}
            )
            
            if zervigo_data:
                # 同步到Zervigo
                success = await self._update_zervigo_user_data(zervigo_data)
                if success:
                    logger.info(f"人才数据同步到Zervigo成功: {looma_data.get('id')}")
                else:
                    logger.error(f"人才数据同步到Zervigo失败: {looma_data.get('id')}")
            
        except Exception as e:
            logger.error(f"同步人才数据到Zervigo失败: {e}")
    
    async def _sync_project_to_zervigo(self, looma_data: Dict[str, Any]):
        """同步项目数据到Zervigo"""
        try:
            # 这里可以实现项目数据到Zervigo的同步逻辑
            logger.info(f"项目数据同步到Zervigo: {looma_data.get('id')}")
            
        except Exception as e:
            logger.error(f"同步项目数据到Zervigo失败: {e}")
    
    # 以下是具体的数据库操作方法（模拟实现）
    
    async def _get_looma_talent_data(self, talent_id: str) -> Optional[Dict[str, Any]]:
        """从Looma CRM数据库获取人才数据"""
        # 这里实现具体的数据库查询逻辑
        # 暂时返回模拟数据
        return {
            "id": talent_id,
            "name": f"Talent_{talent_id}",
            "email": f"{talent_id}@example.com",
            "status": "active",
            "created_at": datetime.now().isoformat(),
            "zervigo_user_id": int(talent_id.replace('talent_', ''))
        }
    
    async def _get_looma_project_data(self, project_id: str) -> Optional[Dict[str, Any]]:
        """从Looma CRM数据库获取项目数据"""
        # 这里实现具体的数据库查询逻辑
        # 暂时返回模拟数据
        return {
            "id": project_id,
            "name": f"Project_{project_id}",
            "description": f"Description for {project_id}",
            "status": "active",
            "created_at": datetime.now().isoformat(),
            "zervigo_job_id": int(project_id.replace('project_', ''))
        }
    
    async def _get_zervigo_user_data(self, user_id: str) -> Optional[Dict[str, Any]]:
        """从Zervigo获取用户数据"""
        # 这里实现具体的Zervigo API调用逻辑
        # 暂时返回模拟数据
        return {
            "id": int(user_id),
            "username": f"user_{user_id}",
            "email": f"user_{user_id}@example.com",
            "role": "user",
            "status": "active",
            "created_at": datetime.now().isoformat()
        }
    
    async def _get_zervigo_job_data(self, job_id: str) -> Optional[Dict[str, Any]]:
        """从Zervigo获取职位数据"""
        # 这里实现具体的Zervigo API调用逻辑
        # 暂时返回模拟数据
        return {
            "id": int(job_id),
            "title": f"Job_{job_id}",
            "description": f"Description for job {job_id}",
            "status": "active",
            "created_at": datetime.now().isoformat()
        }
    
    async def _get_zervigo_resume_data(self, user_id: str) -> Optional[Dict[str, Any]]:
        """从Zervigo获取简历数据"""
        # 这里实现具体的Zervigo API调用逻辑
        # 暂时返回模拟数据
        return {
            "id": 1,
            "user_id": int(user_id),
            "filename": f"resume_{user_id}.pdf",
            "parsed_data": {
                "skills": ["Python", "Sanic", "微服务"],
                "experience": [
                    {
                        "company": "Example Company",
                        "position": "Software Engineer",
                        "duration": "2 years",
                        "skills": ["Python", "Django"]
                    }
                ],
                "education": [
                    {
                        "degree": "Bachelor",
                        "school": "Example University",
                        "major": "Computer Science",
                        "year": 2020
                    }
                ]
            },
            "status": "parsed",
            "created_at": datetime.now().isoformat()
        }
    
    async def _save_looma_talent_data(self, talent_data: Dict[str, Any]) -> bool:
        """保存人才数据到Looma CRM数据库"""
        # 这里实现具体的数据库保存逻辑
        logger.info(f"保存人才数据到Looma CRM: {talent_data.get('id')}")
        return True
    
    async def _save_looma_project_data(self, project_data: Dict[str, Any]) -> bool:
        """保存项目数据到Looma CRM数据库"""
        # 这里实现具体的数据库保存逻辑
        logger.info(f"保存项目数据到Looma CRM: {project_data.get('id')}")
        return True
    
    async def _update_zervigo_user_data(self, user_data: Dict[str, Any]) -> bool:
        """更新Zervigo用户数据"""
        # 这里实现具体的Zervigo API调用逻辑
        logger.info(f"更新Zervigo用户数据: {user_data.get('username')}")
        return True
    
    async def get_sync_status(self) -> Dict[str, Any]:
        """获取同步状态"""
        return {
            "sync_queue_size": self.sync_queue.qsize(),
            "sync_worker_running": self.sync_worker_running,
            "mapping_cache_stats": await self.mapping_service.get_cache_stats(),
            "validation_cache_stats": {
                "cache_size": len(self.validation_service.validation_cache)
            }
        }
    
    async def close(self):
        """关闭增强的数据访问层"""
        await super().close()
        
        # 等待同步队列清空
        await self.sync_queue.join()
        
        # 清空缓存
        await self.mapping_service.clear_cache()
        await self.validation_service.clear_cache()
        
        logger.info("增强的统一数据访问层已关闭")
