#!/usr/bin/env python3
"""
事件队列
实现同步事件的发布和消费
"""

import asyncio
import json
import logging
import redis
from typing import Dict, Any, List, Optional
from datetime import datetime
from dataclasses import asdict

from .sync_engine import SyncEvent, SyncEventType, SyncStatus

logger = logging.getLogger(__name__)

class EventQueue:
    """事件队列"""
    
    def __init__(self, config: Dict[str, Any] = None):
        self.config = config or {}
        self.redis_client = None
        self.stream_name = self.config.get("stream_name", "sync_events")
        self.consumer_group = self.config.get("consumer_group", "sync_workers")
        self.max_stream_length = self.config.get("max_stream_length", 10000)
        self.block_time_ms = self.config.get("block_time_ms", 1000)
        self.is_connected = False
        
        # 初始化Redis连接
        self._initialize_redis()
    
    def _initialize_redis(self):
        """初始化Redis连接"""
        try:
            redis_config = self.config.get("redis", {})
            self.redis_client = redis.Redis(
                host=redis_config.get("host", "localhost"),
                port=redis_config.get("port", 6379),
                db=redis_config.get("db", 0),
                decode_responses=True
            )
            
            # 测试连接
            self.redis_client.ping()
            self.is_connected = True
            
            # 创建消费者组
            self._create_consumer_group()
            
            logger.info("事件队列Redis连接成功")
            
        except Exception as e:
            logger.error(f"事件队列Redis连接失败: {e}")
            self.is_connected = False
    
    def _create_consumer_group(self):
        """创建消费者组"""
        try:
            # 尝试创建消费者组
            self.redis_client.xgroup_create(
                self.stream_name,
                self.consumer_group,
                id="0",
                mkstream=True
            )
            logger.info(f"创建消费者组成功: {self.consumer_group}")
        except redis.exceptions.ResponseError as e:
            if "BUSYGROUP" in str(e):
                logger.info(f"消费者组已存在: {self.consumer_group}")
            else:
                logger.error(f"创建消费者组失败: {e}")
                raise
    
    async def publish_event(self, event: SyncEvent) -> bool:
        """发布同步事件"""
        if not self.is_connected:
            logger.error("Redis连接未建立，无法发布事件")
            return False
        
        try:
            # 准备事件数据
            event_data = {
                "id": event.id,
                "type": event.type.value,
                "source": event.source,
                "target": event.target,
                "data": json.dumps(event.data, ensure_ascii=False),
                "timestamp": event.timestamp.isoformat(),
                "priority": str(event.priority),
                "retry_count": str(event.retry_count),
                "max_retries": str(event.max_retries),
                "status": event.status.value,
                "metadata": json.dumps(event.metadata or {}, ensure_ascii=False)
            }
            
            # 发布到Redis Stream
            message_id = self.redis_client.xadd(
                self.stream_name,
                event_data,
                maxlen=self.max_stream_length
            )
            
            logger.debug(f"事件发布成功: {event.id} -> {message_id}")
            return True
            
        except Exception as e:
            logger.error(f"发布事件失败: {e}")
            return False
    
    async def consume_event(self, consumer_name: str) -> Optional[SyncEvent]:
        """消费同步事件"""
        if not self.is_connected:
            logger.error("Redis连接未建立，无法消费事件")
            return None
        
        try:
            # 从消费者组读取事件
            messages = self.redis_client.xreadgroup(
                self.consumer_group,
                consumer_name,
                {self.stream_name: ">"},
                count=1,
                block=self.block_time_ms
            )
            
            if not messages:
                return None
            
            # 解析消息
            for stream, msgs in messages:
                for message_id, fields in msgs:
                    try:
                        # 解析事件数据
                        event = self._parse_event_from_fields(fields)
                        if event:
                            # 确认消息处理
                            self.redis_client.xack(
                                self.stream_name,
                                self.consumer_group,
                                message_id
                            )
                            
                            logger.debug(f"事件消费成功: {event.id}")
                            return event
                            
                    except Exception as e:
                        logger.error(f"解析事件失败: {e}")
                        # 确认消息处理（避免重复处理）
                        self.redis_client.xack(
                            self.stream_name,
                            self.consumer_group,
                            message_id
                        )
            
            return None
            
        except Exception as e:
            logger.error(f"消费事件失败: {e}")
            return None
    
    def _parse_event_from_fields(self, fields: Dict[str, str]) -> Optional[SyncEvent]:
        """从字段解析事件"""
        try:
            # 解析基本字段
            event_id = fields.get("id")
            event_type = SyncEventType(fields.get("type", "sync"))
            source = fields.get("source")
            target = fields.get("target")
            timestamp_str = fields.get("timestamp")
            priority = int(fields.get("priority", "0"))
            retry_count = int(fields.get("retry_count", "0"))
            max_retries = int(fields.get("max_retries", "3"))
            status = SyncStatus(fields.get("status", "pending"))
            
            # 解析复杂字段
            data = json.loads(fields.get("data", "{}"))
            metadata = json.loads(fields.get("metadata", "{}"))
            timestamp = datetime.fromisoformat(timestamp_str)
            
            return SyncEvent(
                id=event_id,
                type=event_type,
                source=source,
                target=target,
                data=data,
                timestamp=timestamp,
                priority=priority,
                retry_count=retry_count,
                max_retries=max_retries,
                status=status,
                metadata=metadata
            )
            
        except Exception as e:
            logger.error(f"解析事件字段失败: {e}")
            return None
    
    async def get_pending_events(self, consumer_name: str) -> List[SyncEvent]:
        """获取待处理事件"""
        if not self.is_connected:
            return []
        
        try:
            # 获取待处理事件
            pending = self.redis_client.xpending_range(
                self.stream_name,
                self.consumer_group,
                min="-",
                max="+",
                count=100,
                idle=0
            )
            
            events = []
            for pending_info in pending:
                message_id = pending_info["message_id"]
                
                # 获取事件详情
                messages = self.redis_client.xrange(
                    self.stream_name,
                    min=message_id,
                    max=message_id
                )
                
                if messages:
                    _, fields = messages[0]
                    event = self._parse_event_from_fields(fields)
                    if event:
                        events.append(event)
            
            return events
            
        except Exception as e:
            logger.error(f"获取待处理事件失败: {e}")
            return []
    
    async def get_queue_stats(self) -> Dict[str, Any]:
        """获取队列统计信息"""
        if not self.is_connected:
            return {"error": "Redis连接未建立"}
        
        try:
            # 获取流信息
            stream_info = self.redis_client.xinfo_stream(self.stream_name)
            
            # 获取消费者组信息
            group_info = self.redis_client.xinfo_groups(self.stream_name)
            
            # 获取消费者信息
            consumers_info = self.redis_client.xinfo_consumers(
                self.stream_name,
                self.consumer_group
            )
            
            return {
                "stream": {
                    "length": stream_info.get("length", 0),
                    "first_entry": stream_info.get("first-entry"),
                    "last_entry": stream_info.get("last-entry")
                },
                "consumer_group": {
                    "name": self.consumer_group,
                    "consumers": len(consumers_info),
                    "pending": sum(consumer.get("pending", 0) for consumer in consumers_info)
                },
                "consumers": [
                    {
                        "name": consumer.get("name"),
                        "pending": consumer.get("pending", 0),
                        "idle": consumer.get("idle", 0)
                    }
                    for consumer in consumers_info
                ]
            }
            
        except Exception as e:
            logger.error(f"获取队列统计失败: {e}")
            return {"error": str(e)}
    
    async def clear_queue(self) -> bool:
        """清空队列"""
        if not self.is_connected:
            return False
        
        try:
            # 删除流
            self.redis_client.delete(self.stream_name)
            
            # 重新创建消费者组
            self._create_consumer_group()
            
            logger.info("队列清空成功")
            return True
            
        except Exception as e:
            logger.error(f"清空队列失败: {e}")
            return False
    
    async def health_check(self) -> Dict[str, Any]:
        """健康检查"""
        try:
            if not self.is_connected:
                return {
                    "status": "unhealthy",
                    "error": "Redis连接未建立"
                }
            
            # 测试Redis连接
            self.redis_client.ping()
            
            # 获取队列统计
            stats = await self.get_queue_stats()
            
            return {
                "status": "healthy",
                "redis_connected": True,
                "stream_name": self.stream_name,
                "consumer_group": self.consumer_group,
                "stats": stats
            }
            
        except Exception as e:
            logger.error(f"事件队列健康检查失败: {e}")
            return {
                "status": "unhealthy",
                "error": str(e)
            }
    
    async def reconnect(self) -> bool:
        """重新连接"""
        try:
            self._initialize_redis()
            return self.is_connected
        except Exception as e:
            logger.error(f"重新连接失败: {e}")
            return False
