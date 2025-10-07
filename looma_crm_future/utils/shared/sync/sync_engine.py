#!/usr/bin/env python3
"""
数据同步引擎
实现Looma CRM与Zervigo子系统之间的数据同步
"""

import asyncio
import json
import logging
from typing import Dict, Any, List, Optional, Callable
from datetime import datetime, timedelta
from enum import Enum
from dataclasses import dataclass

logger = logging.getLogger(__name__)

class SyncEventType(Enum):
    """同步事件类型"""
    CREATE = "create"
    UPDATE = "update"
    DELETE = "delete"
    SYNC = "sync"

class SyncStatus(Enum):
    """同步状态"""
    PENDING = "pending"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    FAILED = "failed"
    RETRYING = "retrying"

@dataclass
class SyncEvent:
    """同步事件"""
    id: str
    type: SyncEventType
    source: str
    target: str
    data: Dict[str, Any]
    timestamp: datetime
    priority: int = 0
    retry_count: int = 0
    max_retries: int = 3
    status: SyncStatus = SyncStatus.PENDING
    metadata: Dict[str, Any] = None

@dataclass
class SyncResult:
    """同步结果"""
    event_id: str
    success: bool
    timestamp: datetime
    duration_ms: int
    error_message: Optional[str] = None
    conflict_resolved: bool = False
    data_changed: bool = False

class SyncEngine:
    """数据同步引擎"""
    
    def __init__(self, config: Dict[str, Any] = None):
        self.config = config or self._default_config()
        self.sync_strategies = {}
        self.conflict_resolver = None
        self.event_queue = None
        self.change_log = None
        self.sync_workers = []
        self.is_running = False
        self.sync_metrics = {
            "total_syncs": 0,
            "successful_syncs": 0,
            "failed_syncs": 0,
            "conflicts_resolved": 0,
            "avg_sync_time_ms": 0
        }
        
        # 初始化组件
        self._initialize_components()
    
    def _default_config(self) -> Dict[str, Any]:
        """默认配置"""
        return {
            "batch_size": 100,
            "max_retries": 3,
            "retry_delay_ms": 1000,
            "sync_timeout_ms": 30000,
            "worker_count": 4,
            "enable_real_time_sync": True,
            "enable_incremental_sync": True,
            "enable_batch_sync": True,
            "sync_interval_seconds": 300
        }
    
    def _initialize_components(self):
        """初始化组件"""
        try:
            # 延迟导入避免循环依赖
            from .event_queue import EventQueue
            from .change_log import ChangeLog
            from .conflict_resolver import ConflictResolver
            from .sync_strategies import SyncStrategyManager, SyncStrategyType
            
            self.event_queue = EventQueue(self.config)
            self.change_log = ChangeLog(self.config)
            self.conflict_resolver = ConflictResolver(self.config)
            self.strategy_manager = SyncStrategyManager(self.config)
            
            # 注册默认同步策略
            self._register_default_strategies()
            
            logger.info("同步引擎组件初始化成功")
        except Exception as e:
            logger.error(f"同步引擎组件初始化失败: {e}")
            raise
    
    def _register_default_strategies(self):
        """注册默认同步策略"""
        try:
            # 注册looma_crm到zervigo的同步策略
            default_strategy = self.strategy_manager.get_default_strategy()
            if default_strategy:
                self.register_sync_strategy("looma_crm", "zervigo", default_strategy)
                self.register_sync_strategy("zervigo", "looma_crm", default_strategy)
                logger.info("默认同步策略注册成功")
        except Exception as e:
            logger.error(f"默认同步策略注册失败: {e}")
    
    async def start(self):
        """启动同步引擎"""
        if self.is_running:
            logger.warning("同步引擎已经在运行")
            return
        
        try:
            self.is_running = True
            
            # 启动工作器
            for i in range(self.config["worker_count"]):
                worker = asyncio.create_task(self._sync_worker(f"worker-{i}"))
                self.sync_workers.append(worker)
            
            # 启动增量同步定时器
            if self.config.get("enable_incremental_sync", True):
                asyncio.create_task(self._incremental_sync_scheduler())
            
            logger.info(f"同步引擎启动成功，工作器数量: {self.config['worker_count']}")
            
        except Exception as e:
            logger.error(f"同步引擎启动失败: {e}")
            await self.stop()
            raise
    
    async def stop(self):
        """停止同步引擎"""
        if not self.is_running:
            return
        
        self.is_running = False
        
        # 停止所有工作器
        for worker in self.sync_workers:
            worker.cancel()
        
        # 等待工作器完成
        if self.sync_workers:
            await asyncio.gather(*self.sync_workers, return_exceptions=True)
        
        self.sync_workers.clear()
        logger.info("同步引擎已停止")
    
    async def sync_data(self, source: str, target: str, data: Dict[str, Any], 
                       event_type: SyncEventType = SyncEventType.SYNC,
                       priority: int = 0) -> SyncResult:
        """同步数据"""
        try:
            # 创建同步事件
            event = SyncEvent(
                id=f"{source}_{target}_{datetime.now().timestamp()}",
                type=event_type,
                source=source,
                target=target,
                data=data,
                timestamp=datetime.now(),
                priority=priority
            )
            
            # 记录变更日志
            await self.change_log.log_change(event)
            
            # 发布同步事件
            await self.event_queue.publish_event(event)
            
            # 如果是实时同步，立即处理
            if self.config.get("enable_real_time_sync", True) and priority > 0:
                return await self._process_sync_event(event)
            
            return SyncResult(
                event_id=event.id,
                success=True,
                timestamp=datetime.now(),
                duration_ms=0
            )
            
        except Exception as e:
            logger.error(f"数据同步失败: {e}")
            return SyncResult(
                event_id="",
                success=False,
                timestamp=datetime.now(),
                duration_ms=0,
                error_message=str(e)
            )
    
    async def real_time_sync(self, event: SyncEvent) -> SyncResult:
        """实时同步"""
        start_time = datetime.now()
        
        try:
            # 更新事件状态
            event.status = SyncStatus.IN_PROGRESS
            
            # 执行同步
            result = await self._execute_sync(event)
            
            # 更新指标
            duration_ms = int((datetime.now() - start_time).total_seconds() * 1000)
            self._update_metrics(result.success, duration_ms, result.conflict_resolved)
            
            return result
            
        except Exception as e:
            logger.error(f"实时同步失败: {e}")
            return SyncResult(
                event_id=event.id,
                success=False,
                timestamp=datetime.now(),
                duration_ms=int((datetime.now() - start_time).total_seconds() * 1000),
                error_message=str(e)
            )
    
    async def incremental_sync(self, last_sync_time: datetime) -> List[SyncResult]:
        """增量同步"""
        try:
            # 获取变更数据
            changes = await self.change_log.get_changes_since(last_sync_time)
            
            results = []
            for change in changes:
                # 创建同步事件
                event = SyncEvent(
                    id=f"incr_{change.id}",
                    type=SyncEventType.SYNC,
                    source=change.source,
                    target=change.target,
                    data=change.data,
                    timestamp=datetime.now(),
                    priority=0
                )
                
                # 执行同步
                result = await self._execute_sync(event)
                results.append(result)
            
            logger.info(f"增量同步完成，处理了 {len(changes)} 个变更")
            return results
            
        except Exception as e:
            logger.error(f"增量同步失败: {e}")
            return []
    
    async def batch_sync(self, sync_tasks: List[Dict[str, Any]]) -> List[SyncResult]:
        """批量同步"""
        try:
            results = []
            batch_size = self.config["batch_size"]
            
            # 分批处理
            for i in range(0, len(sync_tasks), batch_size):
                batch = sync_tasks[i:i + batch_size]
                
                # 并行处理批次
                batch_results = await asyncio.gather(*[
                    self.sync_data(
                        task["source"],
                        task["target"],
                        task["data"],
                        SyncEventType(task.get("type", "sync")),
                        task.get("priority", 0)
                    ) for task in batch
                ])
                
                results.extend(batch_results)
            
            logger.info(f"批量同步完成，处理了 {len(sync_tasks)} 个任务")
            return results
            
        except Exception as e:
            logger.error(f"批量同步失败: {e}")
            return []
    
    async def _sync_worker(self, worker_name: str):
        """同步工作器"""
        logger.info(f"同步工作器 {worker_name} 启动")
        
        while self.is_running:
            try:
                # 从事件队列获取事件
                event = await self.event_queue.consume_event(worker_name)
                
                if event:
                    # 处理同步事件
                    result = await self._process_sync_event(event)
                    logger.debug(f"工作器 {worker_name} 处理事件 {event.id}: {result.success}")
                
                # 短暂休眠避免CPU占用过高
                await asyncio.sleep(0.1)
                
            except asyncio.CancelledError:
                logger.info(f"同步工作器 {worker_name} 被取消")
                break
            except Exception as e:
                logger.error(f"同步工作器 {worker_name} 错误: {e}")
                await asyncio.sleep(1)
        
        logger.info(f"同步工作器 {worker_name} 停止")
    
    async def _process_sync_event(self, event: SyncEvent) -> SyncResult:
        """处理同步事件"""
        start_time = datetime.now()
        
        try:
            # 检查重试次数
            if event.retry_count >= event.max_retries:
                logger.error(f"事件 {event.id} 超过最大重试次数")
                return SyncResult(
                    event_id=event.id,
                    success=False,
                    timestamp=datetime.now(),
                    duration_ms=int((datetime.now() - start_time).total_seconds() * 1000),
                    error_message="超过最大重试次数"
                )
            
            # 执行同步
            result = await self._execute_sync(event)
            
            # 如果失败且可以重试
            if not result.success and event.retry_count < event.max_retries:
                event.retry_count += 1
                event.status = SyncStatus.RETRYING
                
                # 延迟重试
                await asyncio.sleep(self.config.get("retry_delay_ms", 1000) / 1000)
                await self.event_queue.publish_event(event)
            
            return result
            
        except Exception as e:
            logger.error(f"处理同步事件失败: {e}")
            return SyncResult(
                event_id=event.id,
                success=False,
                timestamp=datetime.now(),
                duration_ms=int((datetime.now() - start_time).total_seconds() * 1000),
                error_message=str(e)
            )
    
    async def _execute_sync(self, event: SyncEvent) -> SyncResult:
        """执行同步"""
        start_time = datetime.now()
        
        try:
            # 获取同步策略
            strategy = self._get_sync_strategy(event.source, event.target)
            
            if not strategy:
                raise ValueError(f"未找到同步策略: {event.source} -> {event.target}")
            
            # 执行同步
            success = await strategy.sync(event.data, event.type)
            
            # 更新事件状态
            event.status = SyncStatus.COMPLETED if success else SyncStatus.FAILED
            
            duration_ms = int((datetime.now() - start_time).total_seconds() * 1000)
            
            return SyncResult(
                event_id=event.id,
                success=success,
                timestamp=datetime.now(),
                duration_ms=duration_ms
            )
            
        except Exception as e:
            logger.error(f"执行同步失败: {e}")
            event.status = SyncStatus.FAILED
            
            return SyncResult(
                event_id=event.id,
                success=False,
                timestamp=datetime.now(),
                duration_ms=int((datetime.now() - start_time).total_seconds() * 1000),
                error_message=str(e)
            )
    
    def _get_sync_strategy(self, source: str, target: str) -> Optional[Callable]:
        """获取同步策略"""
        strategy_key = f"{source}_to_{target}"
        return self.sync_strategies.get(strategy_key)
    
    def register_sync_strategy(self, source: str, target: str, strategy: Callable):
        """注册同步策略"""
        strategy_key = f"{source}_to_{target}"
        self.sync_strategies[strategy_key] = strategy
        logger.info(f"注册同步策略: {strategy_key}")
    
    async def _incremental_sync_scheduler(self):
        """增量同步调度器"""
        while self.is_running:
            try:
                # 获取上次同步时间
                last_sync_time = await self.change_log.get_last_sync_time()
                
                # 执行增量同步
                await self.incremental_sync(last_sync_time)
                
                # 等待下次调度
                await asyncio.sleep(self.config.get("sync_interval_seconds", 300))
                
            except Exception as e:
                logger.error(f"增量同步调度器错误: {e}")
                await asyncio.sleep(60)  # 错误时等待1分钟
    
    def _update_metrics(self, success: bool, duration_ms: int, conflict_resolved: bool):
        """更新同步指标"""
        self.sync_metrics["total_syncs"] += 1
        
        if success:
            self.sync_metrics["successful_syncs"] += 1
        else:
            self.sync_metrics["failed_syncs"] += 1
        
        if conflict_resolved:
            self.sync_metrics["conflicts_resolved"] += 1
        
        # 更新平均同步时间
        total_syncs = self.sync_metrics["total_syncs"]
        current_avg = self.sync_metrics["avg_sync_time_ms"]
        self.sync_metrics["avg_sync_time_ms"] = (current_avg * (total_syncs - 1) + duration_ms) / total_syncs
    
    def get_sync_metrics(self) -> Dict[str, Any]:
        """获取同步指标"""
        metrics = self.sync_metrics.copy()
        
        # 计算成功率
        if metrics["total_syncs"] > 0:
            metrics["success_rate"] = metrics["successful_syncs"] / metrics["total_syncs"]
        else:
            metrics["success_rate"] = 0
        
        # 计算冲突解决率
        if metrics["total_syncs"] > 0:
            metrics["conflict_resolution_rate"] = metrics["conflicts_resolved"] / metrics["total_syncs"]
        else:
            metrics["conflict_resolution_rate"] = 0
        
        return metrics
    
    async def health_check(self) -> Dict[str, Any]:
        """健康检查"""
        try:
            # 检查组件状态
            components_status = {
                "event_queue": await self.event_queue.health_check() if self.event_queue else False,
                "change_log": await self.change_log.health_check() if self.change_log else False,
                "conflict_resolver": await self.conflict_resolver.health_check() if self.conflict_resolver else False
            }
            
            # 检查工作器状态
            workers_status = {
                "total_workers": len(self.sync_workers),
                "active_workers": sum(1 for worker in self.sync_workers if not worker.done())
            }
            
            # 获取指标
            metrics = self.get_sync_metrics()
            
            return {
                "status": "healthy" if all(components_status.values()) else "unhealthy",
                "is_running": self.is_running,
                "components": components_status,
                "workers": workers_status,
                "metrics": metrics,
                "timestamp": datetime.now().isoformat()
            }
            
        except Exception as e:
            logger.error(f"健康检查失败: {e}")
            return {
                "status": "error",
                "error": str(e),
                "timestamp": datetime.now().isoformat()
            }
