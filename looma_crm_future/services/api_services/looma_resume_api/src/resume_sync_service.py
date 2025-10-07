#!/usr/bin/env python3
"""
简历数据同步服务
负责Zervigo MySQL和LoomaCRM MongoDB之间的简历数据同步
"""

import asyncio
import logging
import json
import time
from datetime import datetime
from typing import Dict, Any, Optional
import pymongo
import mysql.connector
from mysql.connector import Error
import redis

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class ResumeSyncService:
    """简历数据同步服务"""
    
    def __init__(self):
        # 数据库配置
        self.zervigo_mysql_config = {
            'host': 'localhost',
            'port': 3306,
            'database': 'jobfirst',
            'user': 'root',
            'password': ''
        }
        
        self.looma_mongodb_config = {
            'host': 'localhost',
            'port': 27018,
            'database': 'looma_independent',
            'username': 'looma_admin',
            'password': 'looma_admin_password'
        }
        
        self.redis_config = {
            'host': 'localhost',
            'port': 6379,
            'db': 0,
            'password': None
        }
        
        # 连接对象
        self.mysql_conn = None
        self.mongodb_client = None
        self.mongodb_db = None
        self.redis_client = None
        
        # 同步状态
        self.running = False
        self.sync_interval = 30  # 30秒同步一次
        
    async def connect_databases(self):
        """连接所有数据库"""
        try:
            # 连接MySQL (Zervigo)
            self.mysql_conn = mysql.connector.connect(**self.zervigo_mysql_config)
            logger.info("MySQL数据库连接成功")
            
            # 连接MongoDB (LoomaCRM)
            self.mongodb_client = pymongo.MongoClient(
                f"mongodb://{self.looma_mongodb_config['username']}:{self.looma_mongodb_config['password']}@{self.looma_mongodb_config['host']}:{self.looma_mongodb_config['port']}/{self.looma_mongodb_config['database']}"
            )
            self.mongodb_db = self.mongodb_client[self.looma_mongodb_config['database']]
            logger.info("MongoDB数据库连接成功")
            
            # 连接Redis
            self.redis_client = redis.Redis(**self.redis_config)
            self.redis_client.ping()
            logger.info("Redis连接成功")
            
        except Exception as e:
            logger.error(f"数据库连接失败: {e}")
            raise
    
    async def sync_resume_from_zervigo_to_looma(self):
        """从Zervigo MySQL同步简历数据到LoomaCRM MongoDB"""
        try:
            cursor = self.mysql_conn.cursor(dictionary=True)
            
            # 查询最新的简历数据
            query = """
            SELECT id, user_id, title, content, created_at, updated_at, status
            FROM resumes 
            WHERE updated_at > DATE_SUB(NOW(), INTERVAL 1 HOUR)
            ORDER BY updated_at DESC
            """
            
            cursor.execute(query)
            resumes = cursor.fetchall()
            
            for resume in resumes:
                # 检查是否已存在
                existing = self.mongodb_db.resumes.find_one({"zervigo_id": resume['id']})
                
                resume_doc = {
                    "zervigo_id": resume['id'],
                    "user_id": resume['user_id'],
                    "title": resume['title'],
                    "content": resume['content'],
                    "created_at": resume['created_at'],
                    "updated_at": resume['updated_at'],
                    "status": resume['status'],
                    "sync_source": "zervigo",
                    "last_sync": datetime.now()
                }
                
                if existing:
                    # 更新现有文档
                    self.mongodb_db.resumes.update_one(
                        {"zervigo_id": resume['id']},
                        {"$set": resume_doc}
                    )
                    logger.info(f"更新简历数据: {resume['id']}")
                else:
                    # 插入新文档
                    self.mongodb_db.resumes.insert_one(resume_doc)
                    logger.info(f"新增简历数据: {resume['id']}")
                
                # 记录同步状态到Redis
                sync_key = f"resume_sync:zervigo_to_looma:{resume['id']}"
                self.redis_client.set(sync_key, json.dumps({
                    "resume_id": resume['id'],
                    "sync_time": datetime.now().isoformat(),
                    "status": "success"
                }), ex=3600)  # 1小时过期
            
            cursor.close()
            logger.info(f"从Zervigo同步了 {len(resumes)} 条简历数据到LoomaCRM")
            
        except Exception as e:
            logger.error(f"从Zervigo同步简历数据失败: {e}")
    
    async def sync_resume_from_looma_to_zervigo(self):
        """从LoomaCRM MongoDB同步简历数据到Zervigo MySQL"""
        try:
            # 查询LoomaCRM中标记为需要同步的简历数据
            looma_resumes = self.mongodb_db.resumes.find({
                "sync_source": "looma",
                "last_sync": {"$lt": datetime.now()}
            })
            
            cursor = self.mysql_conn.cursor()
            
            for resume in looma_resumes:
                # 检查Zervigo中是否存在
                check_query = "SELECT id FROM resumes WHERE id = %s"
                cursor.execute(check_query, (resume['zervigo_id'],))
                exists = cursor.fetchone()
                
                if exists:
                    # 更新现有记录
                    update_query = """
                    UPDATE resumes 
                    SET title = %s, content = %s, updated_at = NOW()
                    WHERE id = %s
                    """
                    cursor.execute(update_query, (
                        resume['title'],
                        resume['content'],
                        resume['zervigo_id']
                    ))
                else:
                    # 插入新记录
                    insert_query = """
                    INSERT INTO resumes (id, user_id, title, content, created_at, updated_at, status)
                    VALUES (%s, %s, %s, %s, %s, NOW(), %s)
                    """
                    cursor.execute(insert_query, (
                        resume['zervigo_id'],
                        resume['user_id'],
                        resume['title'],
                        resume['content'],
                        resume['created_at'],
                        resume.get('status', 'active')
                    ))
                
                # 更新同步状态
                self.mongodb_db.resumes.update_one(
                    {"_id": resume['_id']},
                    {"$set": {"last_sync": datetime.now()}}
                )
                
                logger.info(f"同步简历数据到Zervigo: {resume['zervigo_id']}")
            
            self.mysql_conn.commit()
            cursor.close()
            
        except Exception as e:
            logger.error(f"同步简历数据到Zervigo失败: {e}")
            if self.mysql_conn:
                self.mysql_conn.rollback()
    
    async def sync_resume_analysis_data(self):
        """同步简历分析数据"""
        try:
            # 从LoomaCRM MongoDB获取简历分析数据
            analysis_data = self.mongodb_db.resume_analysis.find({
                "sync_status": "pending"
            })
            
            for analysis in analysis_data:
                # 同步到Zervigo PostgreSQL
                # 这里需要根据实际的AI分析数据结构来实现
                logger.info(f"同步简历分析数据: {analysis.get('resume_id')}")
                
                # 更新同步状态
                self.mongodb_db.resume_analysis.update_one(
                    {"_id": analysis['_id']},
                    {"$set": {"sync_status": "synced", "sync_time": datetime.now()}}
                )
            
        except Exception as e:
            logger.error(f"同步简历分析数据失败: {e}")
    
    async def start_sync_loop(self):
        """启动同步循环"""
        logger.info("启动简历数据同步循环...")
        
        while self.running:
            try:
                # 从Zervigo同步到LoomaCRM
                await self.sync_resume_from_zervigo_to_looma()
                
                # 从LoomaCRM同步到Zervigo
                await self.sync_resume_from_looma_to_zervigo()
                
                # 同步分析数据
                await self.sync_resume_analysis_data()
                
                # 等待下次同步
                await asyncio.sleep(self.sync_interval)
                
            except Exception as e:
                logger.error(f"同步循环异常: {e}")
                await asyncio.sleep(10)  # 异常时等待10秒后重试
    
    async def start(self):
        """启动简历同步服务"""
        logger.info("启动简历数据同步服务...")
        
        try:
            # 连接数据库
            await self.connect_databases()
            
            # 设置运行状态
            self.running = True
            
            # 启动同步循环
            await self.start_sync_loop()
            
        except Exception as e:
            logger.error(f"启动简历同步服务失败: {e}")
            raise
    
    async def stop(self):
        """停止简历同步服务"""
        logger.info("停止简历数据同步服务...")
        self.running = False
        
        # 关闭数据库连接
        if self.mysql_conn:
            self.mysql_conn.close()
        if self.mongodb_client:
            self.mongodb_client.close()
        if self.redis_client:
            self.redis_client.close()
        
        logger.info("简历数据同步服务已停止")

async def main():
    """主函数"""
    sync_service = ResumeSyncService()
    
    try:
        await sync_service.start()
    except KeyboardInterrupt:
        logger.info("收到停止信号")
    finally:
        await sync_service.stop()

if __name__ == "__main__":
    asyncio.run(main())
