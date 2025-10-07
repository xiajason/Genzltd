#!/usr/bin/env python3
"""
变更日志
记录和追踪数据变更
"""

import asyncio
import json
import logging
from typing import Dict, Any, List, Optional
from datetime import datetime, timedelta
from dataclasses import dataclass, asdict

from .sync_engine import SyncEvent, SyncEventType

logger = logging.getLogger(__name__)

@dataclass
class DataChange:
    """数据变更记录"""
    id: str
    source: str
    target: str
    event_type: SyncEventType
    data: Dict[str, Any]
    timestamp: datetime
    sync_status: str = "pending"
    retry_count: int = 0
    error_message: Optional[str] = None
    metadata: Dict[str, Any] = None

class ChangeLog:
    """变更日志"""
    
    def __init__(self, config: Dict[str, Any] = None):
        self.config = config or {}
        self.storage_type = self.config.get("storage_type", "memory")  # memory, redis, postgres
        self.retention_days = self.config.get("retention_days", 30)
        self.max_entries = self.config.get("max_entries", 100000)
        
        # 存储后端
        self.storage = None
        self._initialize_storage()
    
    def _initialize_storage(self):
        """初始化存储后端"""
        try:
            if self.storage_type == "memory":
                self.storage = MemoryChangeLogStorage(self.max_entries)
            elif self.storage_type == "redis":
                self.storage = RedisChangeLogStorage(self.config)
            elif self.storage_type == "postgres":
                self.storage = PostgresChangeLogStorage(self.config)
            else:
                raise ValueError(f"不支持的存储类型: {self.storage_type}")
            
            logger.info(f"变更日志存储初始化成功: {self.storage_type}")
            
        except Exception as e:
            logger.error(f"变更日志存储初始化失败: {e}")
            # 回退到内存存储
            self.storage = MemoryChangeLogStorage(self.max_entries)
            logger.info("回退到内存存储")
    
    async def log_change(self, event: SyncEvent) -> bool:
        """记录数据变更"""
        try:
            # 创建变更记录
            change = DataChange(
                id=event.id,
                source=event.source,
                target=event.target,
                event_type=event.type,
                data=event.data,
                timestamp=event.timestamp,
                sync_status=event.status.value,
                retry_count=event.retry_count,
                metadata=event.metadata
            )
            
            # 保存到存储
            success = await self.storage.save_change(change)
            
            if success:
                logger.debug(f"变更记录保存成功: {change.id}")
            else:
                logger.error(f"变更记录保存失败: {change.id}")
            
            return success
            
        except Exception as e:
            logger.error(f"记录数据变更失败: {e}")
            return False
    
    async def get_changes_since(self, timestamp: datetime) -> List[DataChange]:
        """获取指定时间后的变更"""
        try:
            changes = await self.storage.get_changes_since(timestamp)
            logger.debug(f"获取到 {len(changes)} 个变更记录")
            return changes
            
        except Exception as e:
            logger.error(f"获取变更记录失败: {e}")
            return []
    
    async def get_changes_by_source(self, source: str, limit: int = 100) -> List[DataChange]:
        """获取指定源的变更记录"""
        try:
            changes = await self.storage.get_changes_by_source(source, limit)
            logger.debug(f"获取到 {len(changes)} 个 {source} 的变更记录")
            return changes
            
        except Exception as e:
            logger.error(f"获取源变更记录失败: {e}")
            return []
    
    async def get_changes_by_target(self, target: str, limit: int = 100) -> List[DataChange]:
        """获取指定目标的变更记录"""
        try:
            changes = await self.storage.get_changes_by_target(target, limit)
            logger.debug(f"获取到 {len(changes)} 个到 {target} 的变更记录")
            return changes
            
        except Exception as e:
            logger.error(f"获取目标变更记录失败: {e}")
            return []
    
    async def get_last_sync_time(self) -> datetime:
        """获取上次同步时间"""
        try:
            last_sync_time = await self.storage.get_last_sync_time()
            return last_sync_time or (datetime.now() - timedelta(days=1))
            
        except Exception as e:
            logger.error(f"获取上次同步时间失败: {e}")
            return datetime.now() - timedelta(days=1)
    
    async def update_sync_status(self, change_id: str, status: str, error_message: str = None) -> bool:
        """更新同步状态"""
        try:
            success = await self.storage.update_sync_status(change_id, status, error_message)
            
            if success:
                logger.debug(f"同步状态更新成功: {change_id} -> {status}")
            else:
                logger.error(f"同步状态更新失败: {change_id}")
            
            return success
            
        except Exception as e:
            logger.error(f"更新同步状态失败: {e}")
            return False
    
    async def cleanup_old_changes(self) -> int:
        """清理旧的变更记录"""
        try:
            cutoff_time = datetime.now() - timedelta(days=self.retention_days)
            deleted_count = await self.storage.cleanup_old_changes(cutoff_time)
            
            logger.info(f"清理了 {deleted_count} 个旧的变更记录")
            return deleted_count
            
        except Exception as e:
            logger.error(f"清理旧变更记录失败: {e}")
            return 0
    
    async def get_change_stats(self) -> Dict[str, Any]:
        """获取变更统计信息"""
        try:
            stats = await self.storage.get_change_stats()
            return stats
            
        except Exception as e:
            logger.error(f"获取变更统计失败: {e}")
            return {}
    
    async def health_check(self) -> Dict[str, Any]:
        """健康检查"""
        try:
            health = await self.storage.health_check()
            health["storage_type"] = self.storage_type
            health["retention_days"] = self.retention_days
            return health
            
        except Exception as e:
            logger.error(f"变更日志健康检查失败: {e}")
            return {
                "status": "unhealthy",
                "error": str(e)
            }

class MemoryChangeLogStorage:
    """内存变更日志存储"""
    
    def __init__(self, max_entries: int = 100000):
        self.max_entries = max_entries
        self.changes = {}
        self.changes_by_source = {}
        self.changes_by_target = {}
        self.changes_by_time = []
    
    async def save_change(self, change: DataChange) -> bool:
        """保存变更记录"""
        try:
            # 保存到主存储
            self.changes[change.id] = change
            
            # 保存到索引
            if change.source not in self.changes_by_source:
                self.changes_by_source[change.source] = []
            self.changes_by_source[change.source].append(change)
            
            if change.target not in self.changes_by_target:
                self.changes_by_target[change.target] = []
            self.changes_by_target[change.target].append(change)
            
            # 保存到时间索引
            self.changes_by_time.append(change)
            
            # 限制存储大小
            if len(self.changes) > self.max_entries:
                await self._cleanup_oldest()
            
            return True
            
        except Exception as e:
            logger.error(f"内存存储保存变更失败: {e}")
            return False
    
    async def get_changes_since(self, timestamp: datetime) -> List[DataChange]:
        """获取指定时间后的变更"""
        try:
            changes = [
                change for change in self.changes_by_time
                if change.timestamp >= timestamp
            ]
            return sorted(changes, key=lambda x: x.timestamp)
            
        except Exception as e:
            logger.error(f"内存存储获取变更失败: {e}")
            return []
    
    async def get_changes_by_source(self, source: str, limit: int = 100) -> List[DataChange]:
        """获取指定源的变更记录"""
        try:
            changes = self.changes_by_source.get(source, [])
            return sorted(changes, key=lambda x: x.timestamp, reverse=True)[:limit]
            
        except Exception as e:
            logger.error(f"内存存储获取源变更失败: {e}")
            return []
    
    async def get_changes_by_target(self, target: str, limit: int = 100) -> List[DataChange]:
        """获取指定目标的变更记录"""
        try:
            changes = self.changes_by_target.get(target, [])
            return sorted(changes, key=lambda x: x.timestamp, reverse=True)[:limit]
            
        except Exception as e:
            logger.error(f"内存存储获取目标变更失败: {e}")
            return []
    
    async def get_last_sync_time(self) -> Optional[datetime]:
        """获取上次同步时间"""
        try:
            if not self.changes_by_time:
                return None
            
            # 找到最近的成功同步
            successful_changes = [
                change for change in self.changes_by_time
                if change.sync_status == "completed"
            ]
            
            if successful_changes:
                return max(change.timestamp for change in successful_changes)
            
            return None
            
        except Exception as e:
            logger.error(f"内存存储获取上次同步时间失败: {e}")
            return None
    
    async def update_sync_status(self, change_id: str, status: str, error_message: str = None) -> bool:
        """更新同步状态"""
        try:
            if change_id in self.changes:
                change = self.changes[change_id]
                change.sync_status = status
                change.error_message = error_message
                return True
            
            return False
            
        except Exception as e:
            logger.error(f"内存存储更新同步状态失败: {e}")
            return False
    
    async def cleanup_old_changes(self, cutoff_time: datetime) -> int:
        """清理旧的变更记录"""
        try:
            deleted_count = 0
            
            # 清理时间索引
            old_changes = [
                change for change in self.changes_by_time
                if change.timestamp < cutoff_time
            ]
            
            for change in old_changes:
                # 从主存储删除
                if change.id in self.changes:
                    del self.changes[change.id]
                    deleted_count += 1
                
                # 从源索引删除
                if change.source in self.changes_by_source:
                    self.changes_by_source[change.source] = [
                        c for c in self.changes_by_source[change.source]
                        if c.id != change.id
                    ]
                
                # 从目标索引删除
                if change.target in self.changes_by_target:
                    self.changes_by_target[change.target] = [
                        c for c in self.changes_by_target[change.target]
                        if c.id != change.id
                    ]
            
            # 更新时间索引
            self.changes_by_time = [
                change for change in self.changes_by_time
                if change.timestamp >= cutoff_time
            ]
            
            return deleted_count
            
        except Exception as e:
            logger.error(f"内存存储清理旧变更失败: {e}")
            return 0
    
    async def get_change_stats(self) -> Dict[str, Any]:
        """获取变更统计信息"""
        try:
            total_changes = len(self.changes)
            
            # 按状态统计
            status_counts = {}
            for change in self.changes.values():
                status = change.sync_status
                status_counts[status] = status_counts.get(status, 0) + 1
            
            # 按源统计
            source_counts = {}
            for source, changes in self.changes_by_source.items():
                source_counts[source] = len(changes)
            
            # 按目标统计
            target_counts = {}
            for target, changes in self.changes_by_target.items():
                target_counts[target] = len(changes)
            
            return {
                "total_changes": total_changes,
                "status_counts": status_counts,
                "source_counts": source_counts,
                "target_counts": target_counts,
                "storage_type": "memory"
            }
            
        except Exception as e:
            logger.error(f"内存存储获取统计失败: {e}")
            return {}
    
    async def health_check(self) -> Dict[str, Any]:
        """健康检查"""
        try:
            return {
                "status": "healthy",
                "total_changes": len(self.changes),
                "max_entries": self.max_entries,
                "storage_type": "memory"
            }
            
        except Exception as e:
            logger.error(f"内存存储健康检查失败: {e}")
            return {
                "status": "unhealthy",
                "error": str(e)
            }
    
    async def _cleanup_oldest(self):
        """清理最旧的记录"""
        try:
            # 按时间排序，删除最旧的记录
            sorted_changes = sorted(self.changes_by_time, key=lambda x: x.timestamp)
            
            # 删除最旧的10%
            delete_count = max(1, len(sorted_changes) // 10)
            
            for change in sorted_changes[:delete_count]:
                if change.id in self.changes:
                    del self.changes[change.id]
                
                # 从索引中删除
                if change.source in self.changes_by_source:
                    self.changes_by_source[change.source] = [
                        c for c in self.changes_by_source[change.source]
                        if c.id != change.id
                    ]
                
                if change.target in self.changes_by_target:
                    self.changes_by_target[change.target] = [
                        c for c in self.changes_by_target[change.target]
                        if c.id != change.id
                    ]
            
            # 更新时间索引
            self.changes_by_time = sorted_changes[delete_count:]
            
            logger.info(f"清理了 {delete_count} 个最旧的变更记录")
            
        except Exception as e:
            logger.error(f"清理最旧记录失败: {e}")

class RedisChangeLogStorage:
    """Redis变更日志存储"""
    
    def __init__(self, config: Dict[str, Any]):
        self.config = config
        self.redis_client = None
        self.key_prefix = config.get("key_prefix", "change_log")
        self._initialize_redis()
    
    def _initialize_redis(self):
        """初始化Redis连接"""
        try:
            import redis
            redis_config = self.config.get("redis", {})
            self.redis_client = redis.Redis(
                host=redis_config.get("host", "localhost"),
                port=redis_config.get("port", 6379),
                db=redis_config.get("db", 0),
                decode_responses=True
            )
            self.redis_client.ping()
            logger.info("Redis变更日志存储连接成功")
        except Exception as e:
            logger.error(f"Redis变更日志存储连接失败: {e}")
            raise
    
    async def save_change(self, change: DataChange) -> bool:
        """保存变更记录"""
        try:
            # 使用Hash存储变更记录
            key = f"{self.key_prefix}:change:{change.id}"
            change_data = {
                "id": change.id,
                "source": change.source,
                "target": change.target,
                "event_type": change.event_type.value,
                "data": json.dumps(change.data, ensure_ascii=False),
                "timestamp": change.timestamp.isoformat(),
                "sync_status": change.sync_status,
                "retry_count": str(change.retry_count),
                "error_message": change.error_message or "",
                "metadata": json.dumps(change.metadata or {}, ensure_ascii=False)
            }
            
            self.redis_client.hset(key, mapping=change_data)
            
            # 设置过期时间
            self.redis_client.expire(key, 86400 * 30)  # 30天
            
            # 添加到索引
            self.redis_client.zadd(f"{self.key_prefix}:by_time", {change.id: change.timestamp.timestamp()})
            self.redis_client.zadd(f"{self.key_prefix}:by_source:{change.source}", {change.id: change.timestamp.timestamp()})
            self.redis_client.zadd(f"{self.key_prefix}:by_target:{change.target}", {change.id: change.timestamp.timestamp()})
            
            return True
            
        except Exception as e:
            logger.error(f"Redis存储保存变更失败: {e}")
            return False
    
    async def get_changes_since(self, timestamp: datetime) -> List[DataChange]:
        """获取指定时间后的变更"""
        try:
            # 从时间索引获取
            change_ids = self.redis_client.zrangebyscore(
                f"{self.key_prefix}:by_time",
                timestamp.timestamp(),
                "+inf"
            )
            
            changes = []
            for change_id in change_ids:
                change = await self._get_change_by_id(change_id)
                if change:
                    changes.append(change)
            
            return sorted(changes, key=lambda x: x.timestamp)
            
        except Exception as e:
            logger.error(f"Redis存储获取变更失败: {e}")
            return []
    
    async def _get_change_by_id(self, change_id: str) -> Optional[DataChange]:
        """根据ID获取变更记录"""
        try:
            key = f"{self.key_prefix}:change:{change_id}"
            change_data = self.redis_client.hgetall(key)
            
            if not change_data:
                return None
            
            return DataChange(
                id=change_data["id"],
                source=change_data["source"],
                target=change_data["target"],
                event_type=SyncEventType(change_data["event_type"]),
                data=json.loads(change_data["data"]),
                timestamp=datetime.fromisoformat(change_data["timestamp"]),
                sync_status=change_data["sync_status"],
                retry_count=int(change_data["retry_count"]),
                error_message=change_data["error_message"] or None,
                metadata=json.loads(change_data["metadata"]) if change_data["metadata"] else {}
            )
            
        except Exception as e:
            logger.error(f"Redis存储获取变更记录失败: {e}")
            return None
    
    async def get_changes_by_source(self, source: str, limit: int = 100) -> List[DataChange]:
        """获取指定源的变更记录"""
        try:
            change_ids = self.redis_client.zrevrange(
                f"{self.key_prefix}:by_source:{source}",
                0, limit - 1
            )
            
            changes = []
            for change_id in change_ids:
                change = await self._get_change_by_id(change_id)
                if change:
                    changes.append(change)
            
            return changes
            
        except Exception as e:
            logger.error(f"Redis存储获取源变更失败: {e}")
            return []
    
    async def get_changes_by_target(self, target: str, limit: int = 100) -> List[DataChange]:
        """获取指定目标的变更记录"""
        try:
            change_ids = self.redis_client.zrevrange(
                f"{self.key_prefix}:by_target:{target}",
                0, limit - 1
            )
            
            changes = []
            for change_id in change_ids:
                change = await self._get_change_by_id(change_id)
                if change:
                    changes.append(change)
            
            return changes
            
        except Exception as e:
            logger.error(f"Redis存储获取目标变更失败: {e}")
            return []
    
    async def get_last_sync_time(self) -> Optional[datetime]:
        """获取上次同步时间"""
        try:
            # 获取最近的成功同步记录
            change_ids = self.redis_client.zrevrange(f"{self.key_prefix}:by_time", 0, 100)
            
            for change_id in change_ids:
                change = await self._get_change_by_id(change_id)
                if change and change.sync_status == "completed":
                    return change.timestamp
            
            return None
            
        except Exception as e:
            logger.error(f"Redis存储获取上次同步时间失败: {e}")
            return None
    
    async def update_sync_status(self, change_id: str, status: str, error_message: str = None) -> bool:
        """更新同步状态"""
        try:
            key = f"{self.key_prefix}:change:{change_id}"
            
            if self.redis_client.exists(key):
                self.redis_client.hset(key, "sync_status", status)
                if error_message:
                    self.redis_client.hset(key, "error_message", error_message)
                return True
            
            return False
            
        except Exception as e:
            logger.error(f"Redis存储更新同步状态失败: {e}")
            return False
    
    async def cleanup_old_changes(self, cutoff_time: datetime) -> int:
        """清理旧的变更记录"""
        try:
            # 获取需要删除的变更ID
            change_ids = self.redis_client.zrangebyscore(
                f"{self.key_prefix}:by_time",
                "-inf",
                cutoff_time.timestamp()
            )
            
            deleted_count = 0
            for change_id in change_ids:
                # 删除主记录
                key = f"{self.key_prefix}:change:{change_id}"
                if self.redis_client.delete(key):
                    deleted_count += 1
                
                # 从索引中删除
                self.redis_client.zrem(f"{self.key_prefix}:by_time", change_id)
                # 注意：这里需要知道source和target才能从对应索引中删除
                # 简化处理，只从时间索引删除
            
            return deleted_count
            
        except Exception as e:
            logger.error(f"Redis存储清理旧变更失败: {e}")
            return 0
    
    async def get_change_stats(self) -> Dict[str, Any]:
        """获取变更统计信息"""
        try:
            total_changes = self.redis_client.zcard(f"{self.key_prefix}:by_time")
            
            return {
                "total_changes": total_changes,
                "storage_type": "redis"
            }
            
        except Exception as e:
            logger.error(f"Redis存储获取统计失败: {e}")
            return {}
    
    async def health_check(self) -> Dict[str, Any]:
        """健康检查"""
        try:
            self.redis_client.ping()
            return {
                "status": "healthy",
                "storage_type": "redis"
            }
            
        except Exception as e:
            logger.error(f"Redis存储健康检查失败: {e}")
            return {
                "status": "unhealthy",
                "error": str(e)
            }

class PostgresChangeLogStorage:
    """PostgreSQL变更日志存储"""
    
    def __init__(self, config: Dict[str, Any]):
        self.config = config
        # 这里可以实现PostgreSQL存储
        # 暂时抛出未实现错误
        raise NotImplementedError("PostgreSQL存储暂未实现")
