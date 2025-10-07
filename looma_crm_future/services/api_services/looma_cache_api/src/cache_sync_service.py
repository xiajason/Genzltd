#!/usr/bin/env python3
"""
跨系统缓存同步服务
负责Zervigo Redis和LoomaCRM Redis之间的缓存数据同步
"""

import asyncio
import logging
import json
import time
from datetime import datetime
from typing import Dict, Any, Optional
import redis

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class CacheSyncService:
    """跨系统缓存同步服务"""
    
    def __init__(self):
        # Redis配置
        self.zervigo_redis_config = {
            'host': 'localhost',
            'port': 6379,
            'db': 0,
            'password': None
        }
        
        self.looma_redis_config = {
            'host': 'localhost',
            'port': 6382,
            'db': 0,
            'password': 'looma_independent_password'
        }
        
        # 连接对象
        self.zervigo_redis = None
        self.looma_redis = None
        
        # 同步状态
        self.running = False
        self.sync_interval = 10  # 10秒同步一次
        
        # 需要同步的键模式
        self.sync_patterns = [
            "user:*",
            "session:*",
            "ai_cache:*",
            "job_match:*",
            "resume_analysis:*"
        ]
    
    async def connect_redis(self):
        """连接Redis实例"""
        try:
            # 连接Zervigo Redis
            self.zervigo_redis = redis.Redis(**self.zervigo_redis_config)
            self.zervigo_redis.ping()
            logger.info("Zervigo Redis连接成功")
            
            # 连接LoomaCRM Redis
            self.looma_redis = redis.Redis(**self.looma_redis_config)
            self.looma_redis.ping()
            logger.info("LoomaCRM Redis连接成功")
            
        except Exception as e:
            logger.error(f"Redis连接失败: {e}")
            raise
    
    async def sync_keys_by_pattern(self, pattern: str):
        """根据模式同步键"""
        try:
            # 从Zervigo获取匹配的键
            zervigo_keys = self.zervigo_redis.keys(pattern)
            
            for key in zervigo_keys:
                key_str = key.decode('utf-8')
                
                # 获取键的类型
                key_type = self.zervigo_redis.type(key).decode('utf-8')
                
                if key_type == 'string':
                    await self.sync_string_key(key_str)
                elif key_type == 'hash':
                    await self.sync_hash_key(key_str)
                elif key_type == 'list':
                    await self.sync_list_key(key_str)
                elif key_type == 'set':
                    await self.sync_set_key(key_str)
                elif key_type == 'zset':
                    await self.sync_zset_key(key_str)
                
                logger.debug(f"同步键: {key_str} (类型: {key_type})")
            
            # 从LoomaCRM获取匹配的键
            looma_keys = self.looma_redis.keys(pattern)
            
            for key in looma_keys:
                key_str = key.decode('utf-8')
                
                # 检查Zervigo中是否存在
                if not self.zervigo_redis.exists(key):
                    # 获取键的类型
                    key_type = self.looma_redis.type(key).decode('utf-8')
                    
                    if key_type == 'string':
                        await self.sync_string_key_from_looma(key_str)
                    elif key_type == 'hash':
                        await self.sync_hash_key_from_looma(key_str)
                    elif key_type == 'list':
                        await self.sync_list_key_from_looma(key_str)
                    elif key_type == 'set':
                        await self.sync_set_key_from_looma(key_str)
                    elif key_type == 'zset':
                        await self.sync_zset_key_from_looma(key_str)
                    
                    logger.debug(f"从LoomaCRM同步键: {key_str} (类型: {key_type})")
            
        except Exception as e:
            logger.error(f"同步键模式 {pattern} 失败: {e}")
    
    async def sync_string_key(self, key: str):
        """同步字符串键"""
        try:
            value = self.zervigo_redis.get(key)
            if value:
                # 获取TTL
                ttl = self.zervigo_redis.ttl(key)
                
                # 设置到LoomaCRM Redis
                if ttl > 0:
                    self.looma_redis.setex(key, ttl, value)
                else:
                    self.looma_redis.set(key, value)
                
                # 记录同步状态
                sync_key = f"sync:cache:{key}"
                self.zervigo_redis.setex(sync_key, 300, json.dumps({
                    "key": key,
                    "type": "string",
                    "sync_time": datetime.now().isoformat(),
                    "direction": "zervigo_to_looma"
                }))
                
        except Exception as e:
            logger.error(f"同步字符串键 {key} 失败: {e}")
    
    async def sync_string_key_from_looma(self, key: str):
        """从LoomaCRM同步字符串键到Zervigo"""
        try:
            value = self.looma_redis.get(key)
            if value:
                # 获取TTL
                ttl = self.looma_redis.ttl(key)
                
                # 设置到Zervigo Redis
                if ttl > 0:
                    self.zervigo_redis.setex(key, ttl, value)
                else:
                    self.zervigo_redis.set(key, value)
                
        except Exception as e:
            logger.error(f"从LoomaCRM同步字符串键 {key} 失败: {e}")
    
    async def sync_hash_key(self, key: str):
        """同步哈希键"""
        try:
            hash_data = self.zervigo_redis.hgetall(key)
            if hash_data:
                # 设置到LoomaCRM Redis
                self.looma_redis.hmset(key, hash_data)
                
                # 获取TTL并设置
                ttl = self.zervigo_redis.ttl(key)
                if ttl > 0:
                    self.looma_redis.expire(key, ttl)
                
                # 记录同步状态
                sync_key = f"sync:cache:{key}"
                self.zervigo_redis.setex(sync_key, 300, json.dumps({
                    "key": key,
                    "type": "hash",
                    "sync_time": datetime.now().isoformat(),
                    "direction": "zervigo_to_looma",
                    "fields": len(hash_data)
                }))
                
        except Exception as e:
            logger.error(f"同步哈希键 {key} 失败: {e}")
    
    async def sync_hash_key_from_looma(self, key: str):
        """从LoomaCRM同步哈希键到Zervigo"""
        try:
            hash_data = self.looma_redis.hgetall(key)
            if hash_data:
                # 设置到Zervigo Redis
                self.zervigo_redis.hmset(key, hash_data)
                
                # 获取TTL并设置
                ttl = self.looma_redis.ttl(key)
                if ttl > 0:
                    self.zervigo_redis.expire(key, ttl)
                
        except Exception as e:
            logger.error(f"从LoomaCRM同步哈希键 {key} 失败: {e}")
    
    async def sync_list_key(self, key: str):
        """同步列表键"""
        try:
            list_data = self.zervigo_redis.lrange(key, 0, -1)
            if list_data:
                # 清空LoomaCRM中的列表
                self.looma_redis.delete(key)
                
                # 设置到LoomaCRM Redis
                self.looma_redis.lpush(key, *list_data)
                
                # 获取TTL并设置
                ttl = self.zervigo_redis.ttl(key)
                if ttl > 0:
                    self.looma_redis.expire(key, ttl)
                
        except Exception as e:
            logger.error(f"同步列表键 {key} 失败: {e}")
    
    async def sync_list_key_from_looma(self, key: str):
        """从LoomaCRM同步列表键到Zervigo"""
        try:
            list_data = self.looma_redis.lrange(key, 0, -1)
            if list_data:
                # 清空Zervigo中的列表
                self.zervigo_redis.delete(key)
                
                # 设置到Zervigo Redis
                self.zervigo_redis.lpush(key, *list_data)
                
                # 获取TTL并设置
                ttl = self.looma_redis.ttl(key)
                if ttl > 0:
                    self.zervigo_redis.expire(key, ttl)
                
        except Exception as e:
            logger.error(f"从LoomaCRM同步列表键 {key} 失败: {e}")
    
    async def sync_set_key(self, key: str):
        """同步集合键"""
        try:
            set_data = self.zervigo_redis.smembers(key)
            if set_data:
                # 清空LoomaCRM中的集合
                self.looma_redis.delete(key)
                
                # 设置到LoomaCRM Redis
                self.looma_redis.sadd(key, *set_data)
                
                # 获取TTL并设置
                ttl = self.zervigo_redis.ttl(key)
                if ttl > 0:
                    self.looma_redis.expire(key, ttl)
                
        except Exception as e:
            logger.error(f"同步集合键 {key} 失败: {e}")
    
    async def sync_set_key_from_looma(self, key: str):
        """从LoomaCRM同步集合键到Zervigo"""
        try:
            set_data = self.looma_redis.smembers(key)
            if set_data:
                # 清空Zervigo中的集合
                self.zervigo_redis.delete(key)
                
                # 设置到Zervigo Redis
                self.zervigo_redis.sadd(key, *set_data)
                
                # 获取TTL并设置
                ttl = self.looma_redis.ttl(key)
                if ttl > 0:
                    self.zervigo_redis.expire(key, ttl)
                
        except Exception as e:
            logger.error(f"从LoomaCRM同步集合键 {key} 失败: {e}")
    
    async def sync_zset_key(self, key: str):
        """同步有序集合键"""
        try:
            zset_data = self.zervigo_redis.zrange(key, 0, -1, withscores=True)
            if zset_data:
                # 清空LoomaCRM中的有序集合
                self.looma_redis.delete(key)
                
                # 设置到LoomaCRM Redis
                for member, score in zset_data:
                    self.looma_redis.zadd(key, {member: score})
                
                # 获取TTL并设置
                ttl = self.zervigo_redis.ttl(key)
                if ttl > 0:
                    self.looma_redis.expire(key, ttl)
                
        except Exception as e:
            logger.error(f"同步有序集合键 {key} 失败: {e}")
    
    async def sync_zset_key_from_looma(self, key: str):
        """从LoomaCRM同步有序集合键到Zervigo"""
        try:
            zset_data = self.looma_redis.zrange(key, 0, -1, withscores=True)
            if zset_data:
                # 清空Zervigo中的有序集合
                self.zervigo_redis.delete(key)
                
                # 设置到Zervigo Redis
                for member, score in zset_data:
                    self.zervigo_redis.zadd(key, {member: score})
                
                # 获取TTL并设置
                ttl = self.looma_redis.ttl(key)
                if ttl > 0:
                    self.zervigo_redis.expire(key, ttl)
                
        except Exception as e:
            logger.error(f"从LoomaCRM同步有序集合键 {key} 失败: {e}")
    
    async def start_sync_loop(self):
        """启动同步循环"""
        logger.info("启动缓存数据同步循环...")
        
        while self.running:
            try:
                # 同步所有配置的模式
                for pattern in self.sync_patterns:
                    await self.sync_keys_by_pattern(pattern)
                
                # 等待下次同步
                await asyncio.sleep(self.sync_interval)
                
            except Exception as e:
                logger.error(f"缓存同步循环异常: {e}")
                await asyncio.sleep(5)  # 异常时等待5秒后重试
    
    async def start(self):
        """启动缓存同步服务"""
        logger.info("启动跨系统缓存同步服务...")
        
        try:
            # 连接Redis
            await self.connect_redis()
            
            # 设置运行状态
            self.running = True
            
            # 启动同步循环
            await self.start_sync_loop()
            
        except Exception as e:
            logger.error(f"启动缓存同步服务失败: {e}")
            raise
    
    async def stop(self):
        """停止缓存同步服务"""
        logger.info("停止跨系统缓存同步服务...")
        self.running = False
        
        # 关闭Redis连接
        if self.zervigo_redis:
            self.zervigo_redis.close()
        if self.looma_redis:
            self.looma_redis.close()
        
        logger.info("跨系统缓存同步服务已停止")

async def main():
    """主函数"""
    sync_service = CacheSyncService()
    
    try:
        await sync_service.start()
    except KeyboardInterrupt:
        logger.info("收到停止信号")
    finally:
        await sync_service.stop()

if __name__ == "__main__":
    asyncio.run(main())
