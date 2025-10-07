#!/usr/bin/env python3
"""
同步策略
实现不同的数据同步策略
"""

import asyncio
import logging
from typing import Dict, Any, List, Optional, Callable
from datetime import datetime, timedelta
from abc import ABC, abstractmethod
from enum import Enum

from .sync_engine import SyncEvent, SyncEventType, SyncResult
from .conflict_resolver import ConflictResolver, Conflict

logger = logging.getLogger(__name__)

class SyncStrategyType(Enum):
    """同步策略类型"""
    REAL_TIME = "real_time"
    INCREMENTAL = "incremental"
    BATCH = "batch"
    MANUAL = "manual"

class SyncStrategy(ABC):
    """同步策略基类"""
    
    def __init__(self, config: Dict[str, Any] = None):
        self.config = config or {}
        self.conflict_resolver = ConflictResolver(config)
        self.sync_metrics = {
            "total_syncs": 0,
            "successful_syncs": 0,
            "failed_syncs": 0,
            "conflicts_resolved": 0,
            "avg_sync_time_ms": 0
        }
    
    @abstractmethod
    async def sync(self, data: Dict[str, Any], event_type: SyncEventType) -> bool:
        """执行同步"""
        pass
    
    @abstractmethod
    async def can_handle(self, event_type: SyncEventType) -> bool:
        """检查是否可以处理指定类型的事件"""
        pass
    
    def get_strategy_type(self) -> SyncStrategyType:
        """获取策略类型"""
        return SyncStrategyType.REAL_TIME
    
    def get_metrics(self) -> Dict[str, Any]:
        """获取同步指标"""
        metrics = self.sync_metrics.copy()
        
        if metrics["total_syncs"] > 0:
            metrics["success_rate"] = metrics["successful_syncs"] / metrics["total_syncs"]
        else:
            metrics["success_rate"] = 0
        
        return metrics
    
    def _update_metrics(self, success: bool, duration_ms: int, conflicts_resolved: int = 0):
        """更新指标"""
        self.sync_metrics["total_syncs"] += 1
        
        if success:
            self.sync_metrics["successful_syncs"] += 1
        else:
            self.sync_metrics["failed_syncs"] += 1
        
        self.sync_metrics["conflicts_resolved"] += conflicts_resolved
        
        # 更新平均同步时间
        total_syncs = self.sync_metrics["total_syncs"]
        current_avg = self.sync_metrics["avg_sync_time_ms"]
        self.sync_metrics["avg_sync_time_ms"] = (current_avg * (total_syncs - 1) + duration_ms) / total_syncs

class RealTimeSyncStrategy(SyncStrategy):
    """实时同步策略"""
    
    def __init__(self, config: Dict[str, Any] = None):
        super().__init__(config)
        self.sync_timeout = self.config.get("sync_timeout_ms", 5000)
        self.retry_attempts = self.config.get("retry_attempts", 3)
        self.retry_delay_ms = self.config.get("retry_delay_ms", 1000)
    
    async def sync(self, data: Dict[str, Any], event_type: SyncEventType) -> bool:
        """执行实时同步"""
        start_time = datetime.now()
        
        try:
            # 模拟实时同步逻辑
            await self._perform_real_time_sync(data, event_type)
            
            duration_ms = int((datetime.now() - start_time).total_seconds() * 1000)
            self._update_metrics(True, duration_ms)
            
            logger.debug(f"实时同步成功: {event_type.value}")
            return True
            
        except Exception as e:
            duration_ms = int((datetime.now() - start_time).total_seconds() * 1000)
            self._update_metrics(False, duration_ms)
            
            logger.error(f"实时同步失败: {e}")
            return False
    
    async def _perform_real_time_sync(self, data: Dict[str, Any], event_type: SyncEventType):
        """执行实时同步逻辑"""
        # 这里实现具体的实时同步逻辑
        # 例如：直接调用目标系统的API
        
        if event_type == SyncEventType.CREATE:
            await self._create_data(data)
        elif event_type == SyncEventType.UPDATE:
            await self._update_data(data)
        elif event_type == SyncEventType.DELETE:
            await self._delete_data(data)
        else:
            await self._sync_data(data)
    
    async def _create_data(self, data: Dict[str, Any]):
        """创建数据"""
        # 模拟API调用
        await asyncio.sleep(0.01)  # 模拟网络延迟
        logger.debug(f"创建数据: {data.get('id', 'unknown')}")
    
    async def _update_data(self, data: Dict[str, Any]):
        """更新数据"""
        # 模拟API调用
        await asyncio.sleep(0.01)  # 模拟网络延迟
        logger.debug(f"更新数据: {data.get('id', 'unknown')}")
    
    async def _delete_data(self, data: Dict[str, Any]):
        """删除数据"""
        # 模拟API调用
        await asyncio.sleep(0.01)  # 模拟网络延迟
        logger.debug(f"删除数据: {data.get('id', 'unknown')}")
    
    async def _sync_data(self, data: Dict[str, Any]):
        """同步数据"""
        # 模拟API调用
        await asyncio.sleep(0.01)  # 模拟网络延迟
        logger.debug(f"同步数据: {data.get('id', 'unknown')}")
    
    async def can_handle(self, event_type: SyncEventType) -> bool:
        """检查是否可以处理指定类型的事件"""
        # 实时同步可以处理所有类型的事件
        return True
    
    def get_strategy_type(self) -> SyncStrategyType:
        """获取策略类型"""
        return SyncStrategyType.REAL_TIME

class IncrementalSyncStrategy(SyncStrategy):
    """增量同步策略"""
    
    def __init__(self, config: Dict[str, Any] = None):
        super().__init__(config)
        self.batch_size = self.config.get("batch_size", 50)
        self.sync_interval = self.config.get("sync_interval_seconds", 300)
        self.last_sync_time = None
    
    async def sync(self, data: Dict[str, Any], event_type: SyncEventType) -> bool:
        """执行增量同步"""
        start_time = datetime.now()
        
        try:
            # 检查是否需要同步
            if not await self._should_sync(data, event_type):
                return True
            
            # 执行增量同步
            await self._perform_incremental_sync(data, event_type)
            
            # 更新最后同步时间
            self.last_sync_time = datetime.now()
            
            duration_ms = int((datetime.now() - start_time).total_seconds() * 1000)
            self._update_metrics(True, duration_ms)
            
            logger.debug(f"增量同步成功: {event_type.value}")
            return True
            
        except Exception as e:
            duration_ms = int((datetime.now() - start_time).total_seconds() * 1000)
            self._update_metrics(False, duration_ms)
            
            logger.error(f"增量同步失败: {e}")
            return False
    
    async def _should_sync(self, data: Dict[str, Any], event_type: SyncEventType) -> bool:
        """检查是否需要同步"""
        # 检查数据是否在同步间隔内更新
        if "updated_at" in data:
            try:
                updated_at = datetime.fromisoformat(data["updated_at"].replace('Z', '+00:00'))
                if self.last_sync_time and updated_at <= self.last_sync_time:
                    return False
            except:
                pass
        
        return True
    
    async def _perform_incremental_sync(self, data: Dict[str, Any], event_type: SyncEventType):
        """执行增量同步逻辑"""
        # 这里实现具体的增量同步逻辑
        # 例如：只同步变更的字段
        
        if event_type == SyncEventType.UPDATE:
            # 只同步变更的字段
            changed_fields = await self._get_changed_fields(data)
            if changed_fields:
                await self._sync_changed_fields(data, changed_fields)
        else:
            # 其他类型的事件直接同步
            await self._sync_data(data)
    
    async def _get_changed_fields(self, data: Dict[str, Any]) -> List[str]:
        """获取变更的字段"""
        # 这里实现变更字段检测逻辑
        # 简化实现，返回所有字段
        return list(data.keys())
    
    async def _sync_changed_fields(self, data: Dict[str, Any], changed_fields: List[str]):
        """同步变更的字段"""
        # 模拟API调用
        await asyncio.sleep(0.02)  # 模拟网络延迟
        logger.debug(f"同步变更字段: {changed_fields}")
    
    async def _sync_data(self, data: Dict[str, Any]):
        """同步数据"""
        # 模拟API调用
        await asyncio.sleep(0.02)  # 模拟网络延迟
        logger.debug(f"增量同步数据: {data.get('id', 'unknown')}")
    
    async def can_handle(self, event_type: SyncEventType) -> bool:
        """检查是否可以处理指定类型的事件"""
        # 增量同步主要处理更新事件
        return event_type in [SyncEventType.UPDATE, SyncEventType.SYNC]
    
    def get_strategy_type(self) -> SyncStrategyType:
        """获取策略类型"""
        return SyncStrategyType.INCREMENTAL

class BatchSyncStrategy(SyncStrategy):
    """批量同步策略"""
    
    def __init__(self, config: Dict[str, Any] = None):
        super().__init__(config)
        self.batch_size = self.config.get("batch_size", 100)
        self.batch_timeout = self.config.get("batch_timeout_seconds", 60)
        self.pending_data = []
        self.batch_timer = None
    
    async def sync(self, data: Dict[str, Any], event_type: SyncEventType) -> bool:
        """执行批量同步"""
        try:
            # 添加到待处理队列
            self.pending_data.append({
                "data": data,
                "event_type": event_type,
                "timestamp": datetime.now()
            })
            
            # 检查是否需要立即处理批次
            if len(self.pending_data) >= self.batch_size:
                return await self._process_batch()
            
            # 启动定时器（如果还没有启动）
            if not self.batch_timer:
                self.batch_timer = asyncio.create_task(self._batch_timer())
            
            return True
            
        except Exception as e:
            logger.error(f"批量同步失败: {e}")
            return False
    
    async def _process_batch(self) -> bool:
        """处理批次"""
        if not self.pending_data:
            return True
        
        start_time = datetime.now()
        
        try:
            # 获取批次数据
            batch_data = self.pending_data[:self.batch_size]
            self.pending_data = self.pending_data[self.batch_size:]
            
            # 按事件类型分组
            grouped_data = self._group_by_event_type(batch_data)
            
            # 并行处理不同事件类型
            tasks = []
            for event_type, data_list in grouped_data.items():
                task = asyncio.create_task(self._process_event_type_batch(event_type, data_list))
                tasks.append(task)
            
            # 等待所有任务完成
            results = await asyncio.gather(*tasks, return_exceptions=True)
            
            # 检查结果
            success = all(not isinstance(result, Exception) for result in results)
            
            duration_ms = int((datetime.now() - start_time).total_seconds() * 1000)
            self._update_metrics(success, duration_ms)
            
            logger.info(f"批量同步完成: {len(batch_data)} 个数据项")
            return success
            
        except Exception as e:
            duration_ms = int((datetime.now() - start_time).total_seconds() * 1000)
            self._update_metrics(False, duration_ms)
            
            logger.error(f"批量同步处理失败: {e}")
            return False
    
    def _group_by_event_type(self, batch_data: List[Dict[str, Any]]) -> Dict[SyncEventType, List[Dict[str, Any]]]:
        """按事件类型分组"""
        grouped = {}
        for item in batch_data:
            event_type = item["event_type"]
            if event_type not in grouped:
                grouped[event_type] = []
            grouped[event_type].append(item)
        return grouped
    
    async def _process_event_type_batch(self, event_type: SyncEventType, data_list: List[Dict[str, Any]]):
        """处理特定事件类型的批次"""
        # 模拟批量API调用
        await asyncio.sleep(0.05)  # 模拟网络延迟
        logger.debug(f"批量处理 {event_type.value}: {len(data_list)} 个数据项")
    
    async def _batch_timer(self):
        """批量定时器"""
        try:
            await asyncio.sleep(self.batch_timeout)
            
            # 处理剩余的待处理数据
            if self.pending_data:
                await self._process_batch()
            
            # 重置定时器
            self.batch_timer = None
            
        except asyncio.CancelledError:
            # 处理剩余的待处理数据
            if self.pending_data:
                await self._process_batch()
            raise
    
    async def can_handle(self, event_type: SyncEventType) -> bool:
        """检查是否可以处理指定类型的事件"""
        # 批量同步可以处理所有类型的事件
        return True
    
    def get_strategy_type(self) -> SyncStrategyType:
        """获取策略类型"""
        return SyncStrategyType.BATCH
    
    async def flush(self) -> bool:
        """刷新所有待处理数据"""
        try:
            if self.pending_data:
                return await self._process_batch()
            return True
        except Exception as e:
            logger.error(f"刷新批量同步失败: {e}")
            return False

class ManualSyncStrategy(SyncStrategy):
    """手动同步策略"""
    
    def __init__(self, config: Dict[str, Any] = None):
        super().__init__(config)
        self.pending_syncs = []
        self.manual_approval_required = True
    
    async def sync(self, data: Dict[str, Any], event_type: SyncEventType) -> bool:
        """执行手动同步"""
        try:
            # 添加到待处理队列
            sync_request = {
                "id": f"manual_{datetime.now().timestamp()}",
                "data": data,
                "event_type": event_type,
                "timestamp": datetime.now(),
                "status": "pending"
            }
            
            self.pending_syncs.append(sync_request)
            
            logger.info(f"手动同步请求已添加: {sync_request['id']}")
            return True
            
        except Exception as e:
            logger.error(f"手动同步失败: {e}")
            return False
    
    async def can_handle(self, event_type: SyncEventType) -> bool:
        """检查是否可以处理指定类型的事件"""
        # 手动同步可以处理所有类型的事件
        return True
    
    def get_strategy_type(self) -> SyncStrategyType:
        """获取策略类型"""
        return SyncStrategyType.MANUAL
    
    async def get_pending_syncs(self) -> List[Dict[str, Any]]:
        """获取待处理的手动同步"""
        return self.pending_syncs.copy()
    
    async def approve_sync(self, sync_id: str) -> bool:
        """批准同步"""
        try:
            # 查找同步请求
            sync_request = None
            for request in self.pending_syncs:
                if request["id"] == sync_id:
                    sync_request = request
                    break
            
            if not sync_request:
                logger.error(f"未找到同步请求: {sync_id}")
                return False
            
            # 执行同步
            start_time = datetime.now()
            
            # 模拟同步逻辑
            await asyncio.sleep(0.01)
            
            # 更新状态
            sync_request["status"] = "approved"
            sync_request["approved_at"] = datetime.now()
            
            # 从待处理队列移除
            self.pending_syncs = [req for req in self.pending_syncs if req["id"] != sync_id]
            
            duration_ms = int((datetime.now() - start_time).total_seconds() * 1000)
            self._update_metrics(True, duration_ms)
            
            logger.info(f"手动同步已批准: {sync_id}")
            return True
            
        except Exception as e:
            logger.error(f"批准同步失败: {e}")
            return False
    
    async def reject_sync(self, sync_id: str, reason: str = None) -> bool:
        """拒绝同步"""
        try:
            # 查找同步请求
            sync_request = None
            for request in self.pending_syncs:
                if request["id"] == sync_id:
                    sync_request = request
                    break
            
            if not sync_request:
                logger.error(f"未找到同步请求: {sync_id}")
                return False
            
            # 更新状态
            sync_request["status"] = "rejected"
            sync_request["rejected_at"] = datetime.now()
            sync_request["rejection_reason"] = reason
            
            # 从待处理队列移除
            self.pending_syncs = [req for req in self.pending_syncs if req["id"] != sync_id]
            
            logger.info(f"手动同步已拒绝: {sync_id}")
            return True
            
        except Exception as e:
            logger.error(f"拒绝同步失败: {e}")
            return False

class SyncStrategyManager:
    """同步策略管理器"""
    
    def __init__(self, config: Dict[str, Any] = None):
        self.config = config or {}
        self.strategies = {}
        self.default_strategy = None
        self._initialize_strategies()
    
    def _initialize_strategies(self):
        """初始化策略"""
        # 创建默认策略
        self.strategies[SyncStrategyType.REAL_TIME] = RealTimeSyncStrategy(self.config)
        self.strategies[SyncStrategyType.INCREMENTAL] = IncrementalSyncStrategy(self.config)
        self.strategies[SyncStrategyType.BATCH] = BatchSyncStrategy(self.config)
        self.strategies[SyncStrategyType.MANUAL] = ManualSyncStrategy(self.config)
        
        # 设置默认策略
        default_type = self.config.get("default_strategy", SyncStrategyType.REAL_TIME)
        self.default_strategy = self.strategies.get(default_type)
        
        logger.info(f"同步策略管理器初始化完成，默认策略: {default_type.value}")
    
    def get_strategy(self, strategy_type: SyncStrategyType) -> Optional[SyncStrategy]:
        """获取指定类型的策略"""
        return self.strategies.get(strategy_type)
    
    def get_default_strategy(self) -> Optional[SyncStrategy]:
        """获取默认策略"""
        return self.default_strategy
    
    def register_strategy(self, strategy_type: SyncStrategyType, strategy: SyncStrategy):
        """注册策略"""
        self.strategies[strategy_type] = strategy
        logger.info(f"注册同步策略: {strategy_type.value}")
    
    def get_all_strategies(self) -> Dict[SyncStrategyType, SyncStrategy]:
        """获取所有策略"""
        return self.strategies.copy()
    
    def get_strategy_metrics(self) -> Dict[str, Any]:
        """获取所有策略的指标"""
        metrics = {}
        for strategy_type, strategy in self.strategies.items():
            metrics[strategy_type.value] = strategy.get_metrics()
        return metrics
    
    async def health_check(self) -> Dict[str, Any]:
        """健康检查"""
        try:
            health_status = {}
            
            for strategy_type, strategy in self.strategies.items():
                try:
                    metrics = strategy.get_metrics()
                    health_status[strategy_type.value] = {
                        "status": "healthy",
                        "metrics": metrics
                    }
                except Exception as e:
                    health_status[strategy_type.value] = {
                        "status": "unhealthy",
                        "error": str(e)
                    }
            
            return {
                "status": "healthy",
                "strategies": health_status,
                "default_strategy": self.default_strategy.get_strategy_type().value if self.default_strategy else None
            }
            
        except Exception as e:
            logger.error(f"同步策略管理器健康检查失败: {e}")
            return {
                "status": "unhealthy",
                "error": str(e)
            }
