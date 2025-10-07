#!/usr/bin/env python3
"""
数据修复服务
自动检测和修复数据一致性问题
"""

import asyncio
import logging
from typing import Dict, Any, List, Optional
from datetime import datetime
import json

from .data_mappers import DataMappingService
from .data_validators import ValidationService

logger = logging.getLogger(__name__)

class DataRepairService:
    """数据修复服务"""
    
    def __init__(self):
        self.mapping_service = DataMappingService()
        self.validation_service = ValidationService()
        self.repair_log = []
        self.auto_repair_enabled = True
    
    async def detect_and_repair_inconsistencies(self, talent_id: str) -> Dict[str, Any]:
        """检测并修复数据不一致问题"""
        try:
            logger.info(f"开始检测和修复数据不一致: {talent_id}")
            
            repair_result = {
                "talent_id": talent_id,
                "repair_time": datetime.now().isoformat(),
                "issues_detected": [],
                "repairs_applied": [],
                "repair_success": False
            }
            
            # 获取Looma CRM数据
            looma_data = await self._get_looma_talent_data(talent_id)
            if not looma_data:
                repair_result["issues_detected"].append("Looma CRM数据不存在")
                return repair_result
            
            # 获取Zervigo数据
            zervigo_user_id = looma_data.get('zervigo_user_id')
            if not zervigo_user_id:
                repair_result["issues_detected"].append("缺少Zervigo用户ID")
                return repair_result
            
            zervigo_data = await self._get_zervigo_user_data(str(zervigo_user_id))
            if not zervigo_data:
                repair_result["issues_detected"].append("Zervigo用户数据不存在")
                return repair_result
            
            # 检测不一致问题
            inconsistencies = await self._detect_inconsistencies(looma_data, zervigo_data)
            repair_result["issues_detected"] = inconsistencies
            
            # 应用修复
            if inconsistencies and self.auto_repair_enabled:
                repairs = await self._apply_repairs(looma_data, zervigo_data, inconsistencies)
                repair_result["repairs_applied"] = repairs
                repair_result["repair_success"] = len(repairs) > 0
            
            # 记录修复日志
            self._log_repair_activity(repair_result)
            
            return repair_result
            
        except Exception as e:
            logger.error(f"数据修复失败: {e}")
            return {
                "talent_id": talent_id,
                "repair_time": datetime.now().isoformat(),
                "error": str(e),
                "repair_success": False
            }
    
    async def _detect_inconsistencies(self, looma_data: Dict[str, Any], zervigo_data: Dict[str, Any]) -> List[Dict[str, Any]]:
        """检测数据不一致问题"""
        inconsistencies = []
        
        # 检测邮箱不一致
        looma_email = looma_data.get('email')
        zervigo_email = zervigo_data.get('email')
        
        if looma_email != zervigo_email:
            inconsistencies.append({
                "type": "email_inconsistency",
                "description": f"邮箱不一致: Looma CRM '{looma_email}' vs Zervigo '{zervigo_email}'",
                "looma_value": looma_email,
                "zervigo_value": zervigo_email,
                "severity": "high"
            })
        
        # 检测状态不一致
        looma_status = looma_data.get('status')
        zervigo_status = zervigo_data.get('status')
        
        status_mapping = {
            'active': 'active',
            'inactive': 'inactive',
            'archived': 'inactive'
        }
        
        expected_zervigo_status = status_mapping.get(looma_status)
        if expected_zervigo_status and zervigo_status != expected_zervigo_status:
            inconsistencies.append({
                "type": "status_inconsistency",
                "description": f"状态映射不一致: Looma CRM '{looma_status}' 期望 Zervigo '{expected_zervigo_status}', 实际 '{zervigo_status}'",
                "looma_value": looma_status,
                "zervigo_value": zervigo_status,
                "expected_zervigo_value": expected_zervigo_status,
                "severity": "medium"
            })
        
        # 检测时间戳差异
        looma_updated = looma_data.get('updated_at')
        zervigo_updated = zervigo_data.get('updated_at')
        
        if looma_updated and zervigo_updated:
            try:
                looma_time = datetime.fromisoformat(looma_updated.replace('Z', '+00:00'))
                zervigo_time = datetime.fromisoformat(zervigo_updated.replace('Z', '+00:00'))
                
                time_diff = abs((looma_time - zervigo_time).total_seconds())
                if time_diff > 300:  # 5分钟
                    inconsistencies.append({
                        "type": "timestamp_inconsistency",
                        "description": f"更新时间差异较大: {time_diff}秒",
                        "looma_value": looma_updated,
                        "zervigo_value": zervigo_updated,
                        "time_diff_seconds": time_diff,
                        "severity": "low"
                    })
            except:
                inconsistencies.append({
                    "type": "timestamp_format_error",
                    "description": "时间戳格式解析失败",
                    "looma_value": looma_updated,
                    "zervigo_value": zervigo_updated,
                    "severity": "low"
                })
        
        return inconsistencies
    
    async def _apply_repairs(self, looma_data: Dict[str, Any], zervigo_data: Dict[str, Any], 
                           inconsistencies: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """应用数据修复"""
        repairs_applied = []
        
        for inconsistency in inconsistencies:
            try:
                if inconsistency["type"] == "email_inconsistency":
                    repair = await self._repair_email_inconsistency(looma_data, zervigo_data, inconsistency)
                    if repair:
                        repairs_applied.append(repair)
                
                elif inconsistency["type"] == "status_inconsistency":
                    repair = await self._repair_status_inconsistency(looma_data, zervigo_data, inconsistency)
                    if repair:
                        repairs_applied.append(repair)
                
                elif inconsistency["type"] == "timestamp_inconsistency":
                    repair = await self._repair_timestamp_inconsistency(looma_data, zervigo_data, inconsistency)
                    if repair:
                        repairs_applied.append(repair)
                
            except Exception as e:
                logger.error(f"修复失败 {inconsistency['type']}: {e}")
                repairs_applied.append({
                    "type": inconsistency["type"],
                    "status": "failed",
                    "error": str(e)
                })
        
        return repairs_applied
    
    async def _repair_email_inconsistency(self, looma_data: Dict[str, Any], zervigo_data: Dict[str, Any], 
                                        inconsistency: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """修复邮箱不一致问题"""
        # 优先使用Zervigo的邮箱（作为权威数据源）
        zervigo_email = inconsistency["zervigo_value"]
        
        if zervigo_email and self._is_valid_email(zervigo_email):
            # 更新Looma CRM数据
            looma_data["email"] = zervigo_email
            looma_data["updated_at"] = datetime.now().isoformat()
            
            success = await self._save_looma_talent_data(looma_data)
            
            if success:
                logger.info(f"邮箱不一致修复成功: {looma_data['id']} -> {zervigo_email}")
                return {
                    "type": "email_inconsistency",
                    "status": "repaired",
                    "action": "updated_looma_email",
                    "old_value": inconsistency["looma_value"],
                    "new_value": zervigo_email
                }
        
        return None
    
    async def _repair_status_inconsistency(self, looma_data: Dict[str, Any], zervigo_data: Dict[str, Any], 
                                         inconsistency: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """修复状态不一致问题"""
        expected_zervigo_status = inconsistency["expected_zervigo_value"]
        
        # 更新Zervigo数据
        zervigo_data["status"] = expected_zervigo_status
        zervigo_data["updated_at"] = datetime.now().isoformat()
        
        success = await self._update_zervigo_user_data(zervigo_data)
        
        if success:
            logger.info(f"状态不一致修复成功: {zervigo_data['id']} -> {expected_zervigo_status}")
            return {
                "type": "status_inconsistency",
                "status": "repaired",
                "action": "updated_zervigo_status",
                "old_value": inconsistency["zervigo_value"],
                "new_value": expected_zervigo_status
            }
        
        return None
    
    async def _repair_timestamp_inconsistency(self, looma_data: Dict[str, Any], zervigo_data: Dict[str, Any], 
                                            inconsistency: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """修复时间戳不一致问题"""
        # 使用较新的时间戳作为权威时间
        looma_time = datetime.fromisoformat(looma_data["updated_at"].replace('Z', '+00:00'))
        zervigo_time = datetime.fromisoformat(zervigo_data["updated_at"].replace('Z', '+00:00'))
        
        if looma_time > zervigo_time:
            # Looma CRM时间更新，同步到Zervigo
            zervigo_data["updated_at"] = looma_data["updated_at"]
            success = await self._update_zervigo_user_data(zervigo_data)
            action = "updated_zervigo_timestamp"
        else:
            # Zervigo时间更新，同步到Looma CRM
            looma_data["updated_at"] = zervigo_data["updated_at"]
            success = await self._save_looma_talent_data(looma_data)
            action = "updated_looma_timestamp"
        
        if success:
            logger.info(f"时间戳不一致修复成功: {action}")
            return {
                "type": "timestamp_inconsistency",
                "status": "repaired",
                "action": action,
                "time_diff_seconds": inconsistency["time_diff_seconds"]
            }
        
        return None
    
    def _is_valid_email(self, email: str) -> bool:
        """验证邮箱格式"""
        import re
        pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
        return re.match(pattern, email) is not None
    
    def _log_repair_activity(self, repair_result: Dict[str, Any]):
        """记录修复活动日志"""
        log_entry = {
            "timestamp": datetime.now().isoformat(),
            "talent_id": repair_result["talent_id"],
            "issues_count": len(repair_result["issues_detected"]),
            "repairs_count": len(repair_result["repairs_applied"]),
            "success": repair_result["repair_success"]
        }
        
        self.repair_log.append(log_entry)
        
        # 保持日志大小在合理范围内
        if len(self.repair_log) > 1000:
            self.repair_log = self.repair_log[-500:]
    
    async def get_repair_statistics(self) -> Dict[str, Any]:
        """获取修复统计信息"""
        if not self.repair_log:
            return {
                "total_repairs": 0,
                "successful_repairs": 0,
                "failed_repairs": 0,
                "success_rate": 0.0
            }
        
        total_repairs = len(self.repair_log)
        successful_repairs = sum(1 for log in self.repair_log if log["success"])
        failed_repairs = total_repairs - successful_repairs
        success_rate = (successful_repairs / total_repairs) * 100 if total_repairs > 0 else 0.0
        
        return {
            "total_repairs": total_repairs,
            "successful_repairs": successful_repairs,
            "failed_repairs": failed_repairs,
            "success_rate": success_rate,
            "recent_repairs": self.repair_log[-10:]  # 最近10次修复记录
        }
    
    async def enable_auto_repair(self, enabled: bool = True):
        """启用/禁用自动修复"""
        self.auto_repair_enabled = enabled
        logger.info(f"自动修复已{'启用' if enabled else '禁用'}")
    
    # 以下是模拟的数据库操作方法
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
            "updated_at": datetime.now().isoformat(),
            "zervigo_user_id": int(talent_id.replace('talent_', ''))
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
            "created_at": datetime.now().isoformat(),
            "updated_at": datetime.now().isoformat()
        }
    
    async def _save_looma_talent_data(self, talent_data: Dict[str, Any]) -> bool:
        """保存人才数据到Looma CRM数据库"""
        # 这里实现具体的数据库保存逻辑
        logger.info(f"保存人才数据到Looma CRM: {talent_data.get('id')}")
        return True
    
    async def _update_zervigo_user_data(self, user_data: Dict[str, Any]) -> bool:
        """更新Zervigo用户数据"""
        # 这里实现具体的Zervigo API调用逻辑
        logger.info(f"更新Zervigo用户数据: {user_data.get('username')}")
        return True
