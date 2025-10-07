#!/usr/bin/env python3
"""
AI身份数据模型API服务
提供AI身份数据模型管理的REST API接口
支持档案创建、向量化、相似度计算等功能
"""

import asyncio
import json
import os
import structlog
import time
from datetime import datetime
from typing import Dict, List, Any, Optional
from dataclasses import asdict

from sanic import Sanic, Request, response
from sanic.response import json as sanic_json
from sanic.exceptions import BadRequest, NotFound, ServerError

# 导入自定义模块
from ai_identity_data_model import AIIdentityDataModel, AIIdentityType
from ai_identity_vectorization import AIIdentityVectorization, VectorizationConfig, VectorType
from ai_identity_similarity import AIIdentitySimilarity, SimilarityConfig, SimilarityType

logger = structlog.get_logger()

class AIIdentityDataModelAPI:
    """AI身份数据模型API服务"""
    
    def __init__(self, db_config: Dict[str, Any]):
        self.db_config = db_config
        self.app = Sanic("AIIdentityDataModelAPI")
        
        # 初始化核心组件
        self.data_model = AIIdentityDataModel(db_config)
        self.vectorizer = AIIdentityVectorization()
        self.similarity_engine = AIIdentitySimilarity()
        
        # API配置
        self.api_config = {
            "version": "1.0.0",
            "title": "AI Identity Data Model API",
            "description": "AI身份数据模型管理API服务",
            "host": "0.0.0.0",
            "port": 8207,
            "debug": False
        }
        
        # 设置路由
        self._setup_routes()
        
        # 设置中间件
        self._setup_middleware()
        
        logger.info("AI身份数据模型API服务初始化完成")
    
    def _setup_routes(self):
        """设置API路由"""
        
        # 健康检查
        @self.app.route("/health", methods=["GET"])
        async def health_check(request: Request):
            return sanic_json({
                "status": "healthy",
                "timestamp": datetime.now().isoformat(),
                "version": self.api_config["version"]
            })
        
        # API信息
        @self.app.route("/", methods=["GET"])
        async def api_info(request: Request):
            return sanic_json({
                "title": self.api_config["title"],
                "description": self.api_config["description"],
                "version": self.api_config["version"],
                "endpoints": [
                    "/health - 健康检查",
                    "/api/v1/profiles - AI身份档案管理",
                    "/api/v1/vectorization - 向量化处理",
                    "/api/v1/similarity - 相似度计算",
                    "/api/v1/statistics - 统计信息"
                ]
            })
        
        # AI身份档案管理
        @self.app.route("/api/v1/profiles", methods=["POST"])
        async def create_profile(request: Request):
            """创建AI身份档案"""
            try:
                data = request.json
                if not data:
                    raise BadRequest("请求体不能为空")
                
                user_id = data.get("user_id")
                if not user_id:
                    raise BadRequest("user_id是必需的")
                
                identity_type_str = data.get("identity_type", "rational")
                try:
                    identity_type = AIIdentityType(identity_type_str)
                except ValueError:
                    raise BadRequest(f"无效的identity_type: {identity_type_str}")
                
                # 创建AI身份档案
                profile = await self.data_model.create_ai_identity_profile(
                    user_id=user_id,
                    identity_type=identity_type
                )
                
                # 序列化档案
                profile_dict = await self.data_model.serialize_profile(profile)
                
                return sanic_json({
                    "success": True,
                    "message": "AI身份档案创建成功",
                    "data": profile_dict
                }, status=201)
                
            except Exception as e:
                logger.error("创建AI身份档案失败", error=str(e))
                raise ServerError(f"创建AI身份档案失败: {str(e)}")
        
        @self.app.route("/api/v1/profiles/<profile_id>", methods=["GET"])
        async def get_profile(request: Request, profile_id: str):
            """获取AI身份档案"""
            try:
                profile = await self.data_model.get_ai_identity_profile(profile_id)
                if not profile:
                    raise NotFound(f"档案不存在: {profile_id}")
                
                profile_dict = await self.data_model.serialize_profile(profile)
                
                return sanic_json({
                    "success": True,
                    "data": profile_dict
                })
                
            except Exception as e:
                logger.error("获取AI身份档案失败", profile_id=profile_id, error=str(e))
                if isinstance(e, NotFound):
                    raise
                raise ServerError(f"获取AI身份档案失败: {str(e)}")
        
        @self.app.route("/api/v1/profiles/<profile_id>", methods=["PUT"])
        async def update_profile(request: Request, profile_id: str):
            """更新AI身份档案"""
            try:
                data = request.json
                if not data:
                    raise BadRequest("请求体不能为空")
                
                # 获取现有档案
                profile = await self.data_model.get_ai_identity_profile(profile_id)
                if not profile:
                    raise NotFound(f"档案不存在: {profile_id}")
                
                # 更新档案（这里简化处理，实际应该根据data更新具体字段）
                success = await self.data_model.update_ai_identity_profile(profile)
                
                if success:
                    return sanic_json({
                        "success": True,
                        "message": "AI身份档案更新成功"
                    })
                else:
                    raise ServerError("更新AI身份档案失败")
                
            except Exception as e:
                logger.error("更新AI身份档案失败", profile_id=profile_id, error=str(e))
                if isinstance(e, (BadRequest, NotFound)):
                    raise
                raise ServerError(f"更新AI身份档案失败: {str(e)}")
        
        # 向量化处理
        @self.app.route("/api/v1/vectorization", methods=["POST"])
        async def vectorize_profile(request: Request):
            """向量化AI身份档案"""
            try:
                data = request.json
                if not data:
                    raise BadRequest("请求体不能为空")
                
                profile_data = data.get("profile_data")
                if not profile_data:
                    raise BadRequest("profile_data是必需的")
                
                vector_type_str = data.get("vector_type", "comprehensive")
                try:
                    vector_type = VectorType(vector_type_str)
                except ValueError:
                    raise BadRequest(f"无效的vector_type: {vector_type_str}")
                
                # 向量化档案
                result = await self.vectorizer.vectorize_ai_identity_profile(
                    profile_data=profile_data,
                    vector_type=vector_type
                )
                
                # 序列化结果
                result_dict = {
                    "vector_id": result.vector_id,
                    "profile_id": result.profile_id,
                    "vector_type": result.vector_type.value,
                    "vector_dimension": result.vector_dimension,
                    "vector_model": result.vector_model,
                    "embedding_time_ms": result.embedding_time_ms,
                    "vector_norm": result.vector_norm,
                    "vector_magnitude": result.vector_magnitude,
                    "confidence_score": result.confidence_score,
                    "metadata": result.metadata,
                    "created_at": result.created_at.isoformat()
                }
                
                return sanic_json({
                    "success": True,
                    "message": "向量化处理成功",
                    "data": result_dict
                })
                
            except Exception as e:
                logger.error("向量化处理失败", error=str(e))
                raise ServerError(f"向量化处理失败: {str(e)}")
        
        @self.app.route("/api/v1/vectorization/batch", methods=["POST"])
        async def batch_vectorize(request: Request):
            """批量向量化处理"""
            try:
                data = request.json
                if not data:
                    raise BadRequest("请求体不能为空")
                
                profiles_data = data.get("profiles_data", [])
                if not profiles_data:
                    raise BadRequest("profiles_data是必需的且不能为空")
                
                vector_type_str = data.get("vector_type", "comprehensive")
                try:
                    vector_type = VectorType(vector_type_str)
                except ValueError:
                    raise BadRequest(f"无效的vector_type: {vector_type_str}")
                
                # 批量向量化
                results = await self.vectorizer.batch_vectorize(
                    profiles_data=profiles_data,
                    vector_type=vector_type
                )
                
                # 序列化结果
                results_dict = []
                for result in results:
                    results_dict.append({
                        "vector_id": result.vector_id,
                        "profile_id": result.profile_id,
                        "vector_type": result.vector_type.value,
                        "vector_dimension": result.vector_dimension,
                        "confidence_score": result.confidence_score,
                        "embedding_time_ms": result.embedding_time_ms
                    })
                
                return sanic_json({
                    "success": True,
                    "message": "批量向量化处理成功",
                    "data": {
                        "total_count": len(profiles_data),
                        "successful_count": len(results),
                        "results": results_dict
                    }
                })
                
            except Exception as e:
                logger.error("批量向量化处理失败", error=str(e))
                raise ServerError(f"批量向量化处理失败: {str(e)}")
        
        # 相似度计算
        @self.app.route("/api/v1/similarity", methods=["POST"])
        async def calculate_similarity(request: Request):
            """计算相似度"""
            try:
                data = request.json
                if not data:
                    raise BadRequest("请求体不能为空")
                
                source_vector = data.get("source_vector")
                target_vector = data.get("target_vector")
                source_profile_id = data.get("source_profile_id")
                target_profile_id = data.get("target_profile_id")
                
                if not all([source_vector, target_vector, source_profile_id, target_profile_id]):
                    raise BadRequest("source_vector, target_vector, source_profile_id, target_profile_id都是必需的")
                
                # 转换为numpy数组
                import numpy as np
                source_vector = np.array(source_vector, dtype=np.float32)
                target_vector = np.array(target_vector, dtype=np.float32)
                
                similarity_type_str = data.get("similarity_type", "comprehensive")
                try:
                    similarity_type = SimilarityType(similarity_type_str)
                except ValueError:
                    raise BadRequest(f"无效的similarity_type: {similarity_type_str}")
                
                # 计算相似度
                result = await self.similarity_engine.calculate_similarity(
                    source_vector=source_vector,
                    target_vector=target_vector,
                    source_profile_id=source_profile_id,
                    target_profile_id=target_profile_id,
                    similarity_type=similarity_type
                )
                
                # 序列化结果
                result_dict = {
                    "similarity_id": result.similarity_id,
                    "source_profile_id": result.source_profile_id,
                    "target_profile_id": result.target_profile_id,
                    "similarity_type": result.similarity_type.value,
                    "cosine_similarity": result.cosine_similarity,
                    "euclidean_distance": result.euclidean_distance,
                    "manhattan_distance": result.manhattan_distance,
                    "pearson_correlation": result.pearson_correlation,
                    "overall_similarity_score": result.overall_similarity_score,
                    "similarity_components": result.similarity_components,
                    "matching_features": result.matching_features,
                    "similarity_explanation": result.similarity_explanation,
                    "confidence_score": result.confidence_score,
                    "calculation_time_ms": result.calculation_time_ms,
                    "created_at": result.created_at.isoformat()
                }
                
                return sanic_json({
                    "success": True,
                    "message": "相似度计算成功",
                    "data": result_dict
                })
                
            except Exception as e:
                logger.error("相似度计算失败", error=str(e))
                raise ServerError(f"相似度计算失败: {str(e)}")
        
        @self.app.route("/api/v1/similarity/batch", methods=["POST"])
        async def batch_calculate_similarity(request: Request):
            """批量计算相似度"""
            try:
                data = request.json
                if not data:
                    raise BadRequest("请求体不能为空")
                
                vector_pairs = data.get("vector_pairs", [])
                if not vector_pairs:
                    raise BadRequest("vector_pairs是必需的且不能为空")
                
                similarity_type_str = data.get("similarity_type", "comprehensive")
                try:
                    similarity_type = SimilarityType(similarity_type_str)
                except ValueError:
                    raise BadRequest(f"无效的similarity_type: {similarity_type_str}")
                
                # 转换向量对
                import numpy as np
                converted_pairs = []
                for pair in vector_pairs:
                    if len(pair) != 4:
                        raise BadRequest("每个vector_pair必须包含4个元素: [source_vector, target_vector, source_id, target_id]")
                    
                    source_vector, target_vector, source_id, target_id = pair
                    converted_pairs.append((
                        np.array(source_vector, dtype=np.float32),
                        np.array(target_vector, dtype=np.float32),
                        source_id,
                        target_id
                    ))
                
                # 批量计算相似度
                results = await self.similarity_engine.batch_calculate_similarity(
                    vector_pairs=converted_pairs,
                    similarity_type=similarity_type
                )
                
                # 序列化结果
                results_dict = []
                for result in results:
                    results_dict.append({
                        "similarity_id": result.similarity_id,
                        "source_profile_id": result.source_profile_id,
                        "target_profile_id": result.target_profile_id,
                        "overall_similarity_score": result.overall_similarity_score,
                        "similarity_rank": result.similarity_rank,
                        "confidence_score": result.confidence_score,
                        "calculation_time_ms": result.calculation_time_ms
                    })
                
                return sanic_json({
                    "success": True,
                    "message": "批量相似度计算成功",
                    "data": {
                        "total_pairs": len(vector_pairs),
                        "successful_results": len(results),
                        "results": results_dict
                    }
                })
                
            except Exception as e:
                logger.error("批量相似度计算失败", error=str(e))
                raise ServerError(f"批量相似度计算失败: {str(e)}")
        
        # 统计信息
        @self.app.route("/api/v1/statistics", methods=["GET"])
        async def get_statistics(request: Request):
            """获取统计信息"""
            try:
                # 获取各组件统计信息
                profile_stats = await self.data_model.get_profile_statistics()
                vectorization_stats = await self.vectorizer.get_performance_stats()
                similarity_stats = await self.similarity_engine.get_performance_stats()
                
                return sanic_json({
                    "success": True,
                    "data": {
                        "profiles": profile_stats,
                        "vectorization": vectorization_stats,
                        "similarity": similarity_stats,
                        "api_info": {
                            "version": self.api_config["version"],
                            "uptime": time.time(),
                            "timestamp": datetime.now().isoformat()
                        }
                    }
                })
                
            except Exception as e:
                logger.error("获取统计信息失败", error=str(e))
                raise ServerError(f"获取统计信息失败: {str(e)}")
        
        # 配置管理
        @self.app.route("/api/v1/config/vectorization", methods=["GET"])
        async def get_vectorization_config(request: Request):
            """获取向量化配置"""
            try:
                config_dict = asdict(self.vectorizer.config)
                return sanic_json({
                    "success": True,
                    "data": config_dict
                })
                
            except Exception as e:
                logger.error("获取向量化配置失败", error=str(e))
                raise ServerError(f"获取向量化配置失败: {str(e)}")
        
        @self.app.route("/api/v1/config/similarity", methods=["GET"])
        async def get_similarity_config(request: Request):
            """获取相似度计算配置"""
            try:
                config_dict = asdict(self.similarity_engine.config)
                return sanic_json({
                    "success": True,
                    "data": config_dict
                })
                
            except Exception as e:
                logger.error("获取相似度计算配置失败", error=str(e))
                raise ServerError(f"获取相似度计算配置失败: {str(e)}")
    
    def _setup_middleware(self):
        """设置中间件"""
        
        @self.app.middleware("request")
        async def log_request(request: Request):
            """记录请求日志"""
            logger.info("API请求", 
                       method=request.method,
                       path=request.path,
                       ip=request.ip)
        
        @self.app.middleware("response")
        async def log_response(request: Request, response):
            """记录响应日志"""
            logger.info("API响应", 
                       method=request.method,
                       path=request.path,
                       status=response.status)
    
    async def initialize(self):
        """初始化API服务"""
        try:
            # 初始化核心组件
            await self.data_model.initialize()
            await self.vectorizer.initialize()
            await self.similarity_engine.initialize()
            
            logger.info("AI身份数据模型API服务初始化成功")
            return True
            
        except Exception as e:
            logger.error("AI身份数据模型API服务初始化失败", error=str(e))
            return False
    
    async def run(self):
        """运行API服务"""
        try:
            logger.info("启动AI身份数据模型API服务", 
                       host=self.api_config["host"],
                       port=self.api_config["port"])
            
            await self.app.create_server(
                host=self.api_config["host"],
                port=self.api_config["port"],
                debug=self.api_config["debug"]
            )
            
        except Exception as e:
            logger.error("启动AI身份数据模型API服务失败", error=str(e))
            raise
    
    async def cleanup(self):
        """清理资源"""
        try:
            await self.data_model.cleanup()
            await self.vectorizer.cleanup()
            await self.similarity_engine.cleanup()
            
            logger.info("AI身份数据模型API服务清理完成")
            
        except Exception as e:
            logger.error("清理AI身份数据模型API服务失败", error=str(e))

# 使用示例
async def main():
    """主函数"""
    # 数据库配置
    db_config = {
        "mysql": {"host": "localhost", "port": 3306, "user": "root", "password": "password"},
        "postgresql": {"host": "localhost", "port": 5434, "user": "postgres", "password": "password"},
        "redis": {"host": "localhost", "port": 6382, "password": ""},
        "neo4j": {"uri": "bolt://localhost:7688", "user": "neo4j", "password": "password"},
        "mongodb": {"host": "localhost", "port": 27018, "user": "admin", "password": "password"},
        "elasticsearch": {"host": "localhost", "port": 9202},
        "weaviate": {"host": "localhost", "port": 8091}
    }
    
    # 创建API服务
    api = AIIdentityDataModelAPI(db_config)
    
    # 初始化
    if await api.initialize():
        logger.info("AI身份数据模型API服务初始化成功")
        
        # 运行服务
        await api.run()
        
    else:
        logger.error("AI身份数据模型API服务初始化失败")

if __name__ == "__main__":
    asyncio.run(main())
