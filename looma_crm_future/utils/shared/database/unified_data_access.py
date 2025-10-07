"""
统一数据访问层 - 集成所有数据库访问
基于Looma CRM现有数据库架构扩展
"""

import asyncio
import logging
from typing import Dict, Any, Optional, List
from datetime import datetime

# 直接导入数据库客户端库
import neo4j
import weaviate
import asyncpg
import redis
import elasticsearch
from motor.motor_asyncio import AsyncIOMotorClient

logger = logging.getLogger(__name__)


class UnifiedDataAccess:
    """统一数据访问层"""
    
    def __init__(self):
        """初始化统一数据访问层"""
        self.neo4j_driver = None
        self.weaviate_client = None
        self.postgres_pool = None
        self.redis_client = None
        self.elasticsearch_client = None
        self.mongodb_client = None  # 新增MongoDB客户端
        self.initialized = False
    
    async def initialize(self):
        """初始化所有数据库连接"""
        try:
            logger.info("正在初始化统一数据访问层...")
            
            # 初始化Neo4j连接
            await self._init_neo4j()
            
            # 初始化Weaviate连接
            await self._init_weaviate()
            
            # 初始化PostgreSQL连接
            await self._init_postgres()
            
            # 初始化Redis连接
            await self._init_redis()
            
            # 初始化Elasticsearch连接
            await self._init_elasticsearch()
            
            # 初始化MongoDB连接
            await self._init_mongodb()
            
            self.initialized = True
            logger.info("统一数据访问层初始化完成")
            
        except Exception as e:
            logger.error(f"统一数据访问层初始化失败: {e}")
            raise
    
    async def _init_neo4j(self):
        """初始化Neo4j连接"""
        try:
            uri = "bolt://localhost:7687"
            username = "neo4j"
            password = "jobfirst_password_2024"
            
            self.neo4j_driver = neo4j.AsyncGraphDatabase.driver(
                uri, auth=(username, password)
            )
            logger.info("Neo4j连接初始化成功")
        except Exception as e:
            logger.warning(f"Neo4j连接初始化失败: {e}")
    
    async def _init_weaviate(self):
        """初始化Weaviate连接"""
        try:
            self.weaviate_client = weaviate.Client(
                url="http://localhost:8083"
            )
            logger.info("Weaviate连接初始化成功")
        except Exception as e:
            logger.warning(f"Weaviate连接初始化失败: {e}")
    
    async def _init_postgres(self):
        """初始化PostgreSQL连接池"""
        try:
            self.postgres_pool = await asyncpg.create_pool(
                host="localhost",
                port=5432,
                user="postgres",
                password="jobfirst_password_2024",
                database="looma_crm",
                min_size=1,
                max_size=10
            )
            logger.info("PostgreSQL连接池初始化成功")
        except Exception as e:
            logger.warning(f"PostgreSQL连接池初始化失败: {e}")
    
    async def _init_redis(self):
        """初始化Redis连接"""
        try:
            self.redis_client = redis.Redis(
                host="localhost",
                port=6379,
                db=0,
                decode_responses=True
            )
            logger.info("Redis连接初始化成功")
        except Exception as e:
            logger.warning(f"Redis连接初始化失败: {e}")
    
    async def _init_elasticsearch(self):
        """初始化Elasticsearch连接"""
        try:
            self.elasticsearch_client = elasticsearch.Elasticsearch(
                hosts=["http://localhost:9200"]
            )
            logger.info("Elasticsearch连接初始化成功")
        except Exception as e:
            logger.warning(f"Elasticsearch连接初始化失败: {e}")
    
    async def _init_mongodb(self):
        """初始化MongoDB连接"""
        try:
            self.mongodb_client = AsyncIOMotorClient(
                host="localhost",
                port=27017,
                maxPoolSize=100,
                minPoolSize=10,
                serverSelectionTimeoutMS=5000,
                connectTimeoutMS=10000
            )
            
            # 测试连接
            await self.mongodb_client.admin.command('ping')
            logger.info("MongoDB连接初始化成功")
        except Exception as e:
            logger.warning(f"MongoDB连接初始化失败: {e}")
            # 如果连接失败，尝试无认证连接
            try:
                self.mongodb_client = AsyncIOMotorClient(
                    host="localhost",
                    port=27017,
                    maxPoolSize=100,
                    minPoolSize=10,
                    serverSelectionTimeoutMS=5000,
                    connectTimeoutMS=10000
                )
                await self.mongodb_client.admin.command('ping')
                logger.info("MongoDB连接初始化成功 (无认证模式)")
            except Exception as e2:
                logger.warning(f"MongoDB连接初始化失败 (无认证模式): {e2}")
                self.mongodb_client = None
    
    async def get_talent_data(self, talent_id: str) -> Dict[str, Any]:
        """获取人才数据"""
        try:
            # 首先尝试从MongoDB获取人才数据
            if self.mongodb_client:
                try:
                    db = self.mongodb_client.looma_crm
                    collection = db.talents
                    talent_doc = await collection.find_one({"talent_id": talent_id})
                    if talent_doc:
                        # 转换MongoDB文档为字典
                        talent_data = dict(talent_doc)
                        talent_data.pop('_id', None)  # 移除MongoDB的_id字段
                        logger.info(f"从MongoDB获取人才数据: {talent_id}")
                        return talent_data
                except Exception as e:
                    logger.warning(f"从MongoDB获取人才数据失败: {e}")
            
            # 如果MongoDB中没有数据，返回默认数据
            talent_data = {
                "talent_id": talent_id,
                "name": f"Talent_{talent_id}",
                "skills": ["Python", "Sanic", "微服务"],
                "experience": "5年",
                "status": "active",
                "created_at": datetime.now().isoformat(),
                "source": "default"
            }
            
            logger.info(f"获取人才数据 (默认): {talent_id}")
            return talent_data
            
        except Exception as e:
            logger.error(f"获取人才数据失败: {e}")
            return {}
    
    async def save_talent_data(self, talent_data: Dict[str, Any]) -> bool:
        """保存人才数据"""
        try:
            # 保存到MongoDB
            if self.mongodb_client:
                try:
                    db = self.mongodb_client.looma_crm
                    collection = db.talents
                    
                    # 添加时间戳
                    talent_data["updated_at"] = datetime.now().isoformat()
                    
                    # 使用upsert操作，如果存在则更新，不存在则插入
                    result = await collection.replace_one(
                        {"talent_id": talent_data.get("talent_id")},
                        talent_data,
                        upsert=True
                    )
                    
                    if result.upserted_id or result.modified_count > 0:
                        logger.info(f"成功保存人才数据到MongoDB: {talent_data.get('talent_id', 'unknown')}")
                        return True
                    else:
                        logger.warning(f"保存人才数据到MongoDB无变化: {talent_data.get('talent_id', 'unknown')}")
                        return True
                        
                except Exception as e:
                    logger.error(f"保存人才数据到MongoDB失败: {e}")
                    return False
            else:
                logger.warning("MongoDB客户端未初始化，无法保存人才数据")
                return False
            
        except Exception as e:
            logger.error(f"保存人才数据失败: {e}")
            return False
    
    async def close(self):
        """关闭所有数据库连接"""
        try:
            if self.neo4j_driver:
                await self.neo4j_driver.close()
            
            if self.postgres_pool:
                await self.postgres_pool.close()
            
            if self.redis_client:
                self.redis_client.close()
            
            if self.mongodb_client:
                self.mongodb_client.close()
            
            logger.info("所有数据库连接已关闭")
            
        except Exception as e:
            logger.error(f"关闭数据库连接失败: {e}")
    
    # 新增MongoDB专用方法
    async def get_mongodb_health(self) -> Dict[str, Any]:
        """获取MongoDB健康状态"""
        try:
            if not self.mongodb_client:
                return {"status": "disconnected", "error": "MongoDB客户端未初始化"}
            
            # 测试连接
            await self.mongodb_client.admin.command('ping')
            
            # 获取服务器信息
            server_info = await self.mongodb_client.server_info()
            
            return {
                "status": "connected",
                "version": server_info.get("version", "unknown"),
                "uptime": server_info.get("uptime", 0),
                "connections": server_info.get("connections", {}),
                "timestamp": datetime.now().isoformat()
            }
            
        except Exception as e:
            return {"status": "error", "error": str(e)}
    
    async def create_talent_collection_indexes(self):
        """为人才集合创建索引"""
        try:
            if not self.mongodb_client:
                logger.warning("MongoDB客户端未初始化，无法创建索引")
                return False
            
            db = self.mongodb_client.looma_crm
            collection = db.talents
            
            # 创建索引
            indexes = [
                ("talent_id", 1),  # 唯一索引
                ("name", 1),       # 文本索引
                ("skills", 1),     # 数组索引
                ("status", 1),     # 状态索引
                ("created_at", -1) # 时间索引
            ]
            
            for index_spec in indexes:
                try:
                    if index_spec[0] == "talent_id":
                        await collection.create_index([(index_spec[0], index_spec[1])], unique=True)
                    else:
                        await collection.create_index([(index_spec[0], index_spec[1])])
                    logger.info(f"创建索引成功: {index_spec[0]}")
                except Exception as e:
                    logger.warning(f"创建索引失败 {index_spec[0]}: {e}")
            
            return True
            
        except Exception as e:
            logger.error(f"创建人才集合索引失败: {e}")
            return False