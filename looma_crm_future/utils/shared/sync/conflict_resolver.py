#!/usr/bin/env python3
"""
冲突解决器
处理数据同步过程中的冲突问题
"""

import asyncio
import logging
from typing import Dict, Any, List, Optional, Tuple
from datetime import datetime
from enum import Enum
from dataclasses import dataclass

logger = logging.getLogger(__name__)

class ConflictType(Enum):
    """冲突类型"""
    VALUE_CONFLICT = "value_conflict"  # 值冲突
    TIMESTAMP_CONFLICT = "timestamp_conflict"  # 时间戳冲突
    VERSION_CONFLICT = "version_conflict"  # 版本冲突
    CONSTRAINT_CONFLICT = "constraint_conflict"  # 约束冲突

class ResolutionStrategy(Enum):
    """解决策略"""
    LAST_WRITE_WINS = "last_write_wins"  # 最后写入获胜
    SOURCE_PRIORITY = "source_priority"  # 源优先级
    FIELD_PRIORITY = "field_priority"  # 字段优先级
    MANUAL_RESOLUTION = "manual_resolution"  # 人工解决
    MERGE_VALUES = "merge_values"  # 合并值
    REJECT_CHANGE = "reject_change"  # 拒绝变更

@dataclass
class Conflict:
    """冲突信息"""
    id: str
    type: ConflictType
    source: str
    target: str
    field: str
    local_value: Any
    remote_value: Any
    local_timestamp: datetime
    remote_timestamp: datetime
    resolution_strategy: ResolutionStrategy
    resolved: bool = False
    resolved_value: Any = None
    resolved_timestamp: datetime = None

@dataclass
class ResolutionResult:
    """解决结果"""
    conflict_id: str
    success: bool
    resolved_value: Any
    resolution_strategy: ResolutionStrategy
    error_message: Optional[str] = None
    requires_manual_intervention: bool = False

class ConflictResolver:
    """冲突解决器"""
    
    def __init__(self, config: Dict[str, Any] = None):
        self.config = config or self._default_config()
        self.resolution_strategies = {
            ResolutionStrategy.LAST_WRITE_WINS: self._last_write_wins,
            ResolutionStrategy.SOURCE_PRIORITY: self._source_priority,
            ResolutionStrategy.FIELD_PRIORITY: self._field_priority,
            ResolutionStrategy.MERGE_VALUES: self._merge_values,
            ResolutionStrategy.REJECT_CHANGE: self._reject_change
        }
        self.conflict_history = []
        self.resolution_stats = {
            "total_conflicts": 0,
            "resolved_conflicts": 0,
            "manual_interventions": 0,
            "strategy_usage": {}
        }
    
    def _default_config(self) -> Dict[str, Any]:
        """默认配置"""
        return {
            "default_strategy": ResolutionStrategy.LAST_WRITE_WINS,
            "source_priority_order": ["looma_crm", "zervigo"],
            "field_priorities": {
                "email": "zervigo",
                "status": "looma_crm",
                "updated_at": "looma_crm",
                "created_at": "looma_crm"
            },
            "merge_strategies": {
                "array": "union",  # 数组合并策略
                "object": "deep_merge",  # 对象合并策略
                "string": "concatenate"  # 字符串合并策略
            },
            "conflict_threshold": 0.1,  # 冲突阈值
            "auto_resolution_enabled": True
        }
    
    async def detect_conflict(self, local_data: Dict[str, Any], 
                            remote_data: Dict[str, Any],
                            source: str, target: str) -> List[Conflict]:
        """检测数据冲突"""
        try:
            conflicts = []
            
            # 获取所有字段
            all_fields = set(local_data.keys()) | set(remote_data.keys())
            
            for field in all_fields:
                local_value = local_data.get(field)
                remote_value = remote_data.get(field)
                
                # 检查值冲突
                if local_value != remote_value:
                    conflict = await self._create_conflict(
                        field, local_value, remote_value,
                        local_data.get("updated_at"), remote_data.get("updated_at"),
                        source, target
                    )
                    
                    if conflict:
                        conflicts.append(conflict)
            
            # 更新统计
            self.resolution_stats["total_conflicts"] += len(conflicts)
            
            logger.debug(f"检测到 {len(conflicts)} 个冲突")
            return conflicts
            
        except Exception as e:
            logger.error(f"冲突检测失败: {e}")
            return []
    
    async def _create_conflict(self, field: str, local_value: Any, remote_value: Any,
                             local_timestamp: Any, remote_timestamp: Any,
                             source: str, target: str) -> Optional[Conflict]:
        """创建冲突对象"""
        try:
            # 确定冲突类型
            conflict_type = self._determine_conflict_type(field, local_value, remote_value)
            
            # 确定解决策略
            resolution_strategy = self._determine_resolution_strategy(field, source, target)
            
            # 解析时间戳
            local_ts = self._parse_timestamp(local_timestamp)
            remote_ts = self._parse_timestamp(remote_timestamp)
            
            conflict = Conflict(
                id=f"{source}_{target}_{field}_{datetime.now().timestamp()}",
                type=conflict_type,
                source=source,
                target=target,
                field=field,
                local_value=local_value,
                remote_value=remote_value,
                local_timestamp=local_ts,
                remote_timestamp=remote_ts,
                resolution_strategy=resolution_strategy
            )
            
            return conflict
            
        except Exception as e:
            logger.error(f"创建冲突对象失败: {e}")
            return None
    
    def _determine_conflict_type(self, field: str, local_value: Any, remote_value: Any) -> ConflictType:
        """确定冲突类型"""
        # 简单值冲突
        if local_value != remote_value:
            return ConflictType.VALUE_CONFLICT
        
        # 可以根据字段类型和值进一步分类
        return ConflictType.VALUE_CONFLICT
    
    def _determine_resolution_strategy(self, field: str, source: str, target: str) -> ResolutionStrategy:
        """确定解决策略"""
        # 检查字段优先级配置
        field_priorities = self.config.get("field_priorities", {})
        if field in field_priorities:
            priority_source = field_priorities[field]
            if source == priority_source:
                return ResolutionStrategy.SOURCE_PRIORITY
            elif target == priority_source:
                return ResolutionStrategy.SOURCE_PRIORITY
        
        # 检查源优先级配置
        source_priority_order = self.config.get("source_priority_order", [])
        if source in source_priority_order and target in source_priority_order:
            source_index = source_priority_order.index(source)
            target_index = source_priority_order.index(target)
            if source_index < target_index:
                return ResolutionStrategy.SOURCE_PRIORITY
        
        # 默认策略
        return self.config.get("default_strategy", ResolutionStrategy.LAST_WRITE_WINS)
    
    def _parse_timestamp(self, timestamp: Any) -> datetime:
        """解析时间戳"""
        if timestamp is None:
            return datetime.now()
        
        if isinstance(timestamp, datetime):
            return timestamp
        
        if isinstance(timestamp, str):
            try:
                return datetime.fromisoformat(timestamp.replace('Z', '+00:00'))
            except:
                return datetime.now()
        
        return datetime.now()
    
    async def resolve_conflict(self, conflict: Conflict) -> ResolutionResult:
        """解决冲突"""
        try:
            if not self.config.get("auto_resolution_enabled", True):
                return ResolutionResult(
                    conflict_id=conflict.id,
                    success=False,
                    resolved_value=None,
                    resolution_strategy=conflict.resolution_strategy,
                    requires_manual_intervention=True
                )
            
            # 获取解决策略函数
            strategy_func = self.resolution_strategies.get(conflict.resolution_strategy)
            
            if not strategy_func:
                logger.error(f"未找到解决策略: {conflict.resolution_strategy}")
                return ResolutionResult(
                    conflict_id=conflict.id,
                    success=False,
                    resolved_value=None,
                    resolution_strategy=conflict.resolution_strategy,
                    error_message=f"未找到解决策略: {conflict.resolution_strategy}"
                )
            
            # 执行解决策略
            resolved_value = await strategy_func(conflict)
            
            # 更新冲突状态
            conflict.resolved = True
            conflict.resolved_value = resolved_value
            conflict.resolved_timestamp = datetime.now()
            
            # 更新统计
            self.resolution_stats["resolved_conflicts"] += 1
            strategy_name = conflict.resolution_strategy.value
            self.resolution_stats["strategy_usage"][strategy_name] = \
                self.resolution_stats["strategy_usage"].get(strategy_name, 0) + 1
            
            # 记录冲突历史
            self.conflict_history.append(conflict)
            
            logger.info(f"冲突解决成功: {conflict.id} -> {resolved_value}")
            
            return ResolutionResult(
                conflict_id=conflict.id,
                success=True,
                resolved_value=resolved_value,
                resolution_strategy=conflict.resolution_strategy
            )
            
        except Exception as e:
            logger.error(f"冲突解决失败: {e}")
            return ResolutionResult(
                conflict_id=conflict.id,
                success=False,
                resolved_value=None,
                resolution_strategy=conflict.resolution_strategy,
                error_message=str(e)
            )
    
    async def _last_write_wins(self, conflict: Conflict) -> Any:
        """最后写入获胜策略"""
        if conflict.local_timestamp > conflict.remote_timestamp:
            return conflict.local_value
        else:
            return conflict.remote_value
    
    async def _source_priority(self, conflict: Conflict) -> Any:
        """源优先级策略"""
        source_priority_order = self.config.get("source_priority_order", [])
        
        if conflict.source in source_priority_order and conflict.target in source_priority_order:
            source_index = source_priority_order.index(conflict.source)
            target_index = source_priority_order.index(conflict.target)
            
            if source_index < target_index:
                return conflict.local_value
            else:
                return conflict.remote_value
        
        # 如果不在优先级列表中，使用最后写入获胜
        return await self._last_write_wins(conflict)
    
    async def _field_priority(self, conflict: Conflict) -> Any:
        """字段优先级策略"""
        field_priorities = self.config.get("field_priorities", {})
        priority_source = field_priorities.get(conflict.field)
        
        if priority_source == conflict.source:
            return conflict.local_value
        elif priority_source == conflict.target:
            return conflict.remote_value
        else:
            # 如果没有字段优先级配置，使用最后写入获胜
            return await self._last_write_wins(conflict)
    
    async def _merge_values(self, conflict: Conflict) -> Any:
        """合并值策略"""
        merge_strategies = self.config.get("merge_strategies", {})
        
        # 根据数据类型选择合并策略
        if isinstance(conflict.local_value, list) and isinstance(conflict.remote_value, list):
            strategy = merge_strategies.get("array", "union")
            if strategy == "union":
                # 数组合并（去重）
                return list(set(conflict.local_value + conflict.remote_value))
            elif strategy == "intersection":
                # 数组交集
                return list(set(conflict.local_value) & set(conflict.remote_value))
            else:
                return conflict.local_value + conflict.remote_value
        
        elif isinstance(conflict.local_value, dict) and isinstance(conflict.remote_value, dict):
            strategy = merge_strategies.get("object", "deep_merge")
            if strategy == "deep_merge":
                # 深度合并字典
                return self._deep_merge_dicts(conflict.local_value, conflict.remote_value)
            else:
                return {**conflict.local_value, **conflict.remote_value}
        
        elif isinstance(conflict.local_value, str) and isinstance(conflict.remote_value, str):
            strategy = merge_strategies.get("string", "concatenate")
            if strategy == "concatenate":
                return f"{conflict.local_value}, {conflict.remote_value}"
            else:
                return conflict.local_value
        
        else:
            # 默认使用最后写入获胜
            return await self._last_write_wins(conflict)
    
    def _deep_merge_dicts(self, dict1: Dict[str, Any], dict2: Dict[str, Any]) -> Dict[str, Any]:
        """深度合并字典"""
        result = dict1.copy()
        
        for key, value in dict2.items():
            if key in result and isinstance(result[key], dict) and isinstance(value, dict):
                result[key] = self._deep_merge_dicts(result[key], value)
            else:
                result[key] = value
        
        return result
    
    async def _reject_change(self, conflict: Conflict) -> Any:
        """拒绝变更策略"""
        # 拒绝变更，保持原值
        return conflict.local_value
    
    async def resolve_conflicts(self, conflicts: List[Conflict]) -> List[ResolutionResult]:
        """批量解决冲突"""
        try:
            results = []
            
            for conflict in conflicts:
                result = await self.resolve_conflict(conflict)
                results.append(result)
            
            logger.info(f"批量冲突解决完成: {len(conflicts)} 个冲突")
            return results
            
        except Exception as e:
            logger.error(f"批量冲突解决失败: {e}")
            return []
    
    async def get_conflict_history(self, limit: int = 100) -> List[Conflict]:
        """获取冲突历史"""
        return self.conflict_history[-limit:]
    
    def get_resolution_stats(self) -> Dict[str, Any]:
        """获取解决统计信息"""
        stats = self.resolution_stats.copy()
        
        # 计算解决率
        if stats["total_conflicts"] > 0:
            stats["resolution_rate"] = stats["resolved_conflicts"] / stats["total_conflicts"]
        else:
            stats["resolution_rate"] = 0
        
        # 计算人工干预率
        if stats["total_conflicts"] > 0:
            stats["manual_intervention_rate"] = stats["manual_interventions"] / stats["total_conflicts"]
        else:
            stats["manual_intervention_rate"] = 0
        
        return stats
    
    async def health_check(self) -> Dict[str, Any]:
        """健康检查"""
        try:
            stats = self.get_resolution_stats()
            
            return {
                "status": "healthy",
                "total_conflicts": stats["total_conflicts"],
                "resolved_conflicts": stats["resolved_conflicts"],
                "resolution_rate": stats["resolution_rate"],
                "strategy_usage": stats["strategy_usage"],
                "auto_resolution_enabled": self.config.get("auto_resolution_enabled", True)
            }
            
        except Exception as e:
            logger.error(f"冲突解决器健康检查失败: {e}")
            return {
                "status": "unhealthy",
                "error": str(e)
            }
    
    def update_config(self, new_config: Dict[str, Any]):
        """更新配置"""
        try:
            self.config.update(new_config)
            logger.info("冲突解决器配置更新成功")
        except Exception as e:
            logger.error(f"冲突解决器配置更新失败: {e}")
    
    def add_custom_strategy(self, strategy_name: str, strategy_func: callable):
        """添加自定义解决策略"""
        try:
            self.resolution_strategies[strategy_name] = strategy_func
            logger.info(f"添加自定义解决策略: {strategy_name}")
        except Exception as e:
            logger.error(f"添加自定义解决策略失败: {e}")
