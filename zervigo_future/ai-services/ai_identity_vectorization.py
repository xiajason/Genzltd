#!/usr/bin/env python3
"""
AI身份向量化处理系统
将AI身份数据转换为向量表示，支持多维向量索引和向量存储优化
基于sentence-transformers和FAISS实现高效的向量化处理
"""

import asyncio
import json
import os
import structlog
import time
import numpy as np
from datetime import datetime
from typing import Dict, List, Any, Optional, Tuple, Union
from dataclasses import dataclass, asdict
from enum import Enum
from concurrent.futures import ThreadPoolExecutor
import aiofiles

# 向量化相关依赖
try:
    from sentence_transformers import SentenceTransformer
    import faiss
    from sklearn.preprocessing import normalize
    from sklearn.feature_extraction.text import TfidfVectorizer
    HAS_VECTOR_DEPS = True
except ImportError:
    HAS_VECTOR_DEPS = False
    logger = structlog.get_logger()
    logger.warning("向量化依赖包未安装，请安装: pip install sentence-transformers faiss-cpu scikit-learn")

logger = structlog.get_logger()

class VectorType(Enum):
    """向量类型枚举"""
    COMPREHENSIVE = "comprehensive"  # 综合向量
    SKILL = "skill"  # 技能向量
    EXPERIENCE = "experience"  # 经验向量
    COMPETENCY = "competency"  # 能力向量
    CUSTOM = "custom"  # 自定义向量

class VectorModel(Enum):
    """向量模型枚举"""
    SENTENCE_TRANSFORMERS = "sentence-transformers"
    TFIDF = "tfidf"
    CUSTOM = "custom"

@dataclass
class VectorizationConfig:
    """向量化配置"""
    model_name: str = "all-MiniLM-L6-v2"  # sentence-transformers模型名称
    vector_dimension: int = 384  # 向量维度
    max_sequence_length: int = 512  # 最大序列长度
    batch_size: int = 32  # 批处理大小
    normalize_vectors: bool = True  # 是否标准化向量
    use_faiss_index: bool = True  # 是否使用FAISS索引
    faiss_index_type: str = "IndexFlatIP"  # FAISS索引类型
    cache_embeddings: bool = True  # 是否缓存嵌入
    cache_ttl: int = 3600  # 缓存TTL(秒)

@dataclass
class VectorizationResult:
    """向量化结果"""
    vector_id: str
    profile_id: str
    vector_type: VectorType
    vector_embedding: np.ndarray
    vector_dimension: int
    vector_model: str
    embedding_source: str
    embedding_algorithm: str
    embedding_parameters: Dict[str, Any]
    embedding_time_ms: int
    vector_norm: float
    vector_magnitude: float
    confidence_score: float
    metadata: Dict[str, Any]
    created_at: datetime

class AIIdentityVectorization:
    """AI身份向量化处理器"""
    
    def __init__(self, config: VectorizationConfig = None):
        self.config = config or VectorizationConfig()
        self.executor = ThreadPoolExecutor(max_workers=4)
        
        # 模型缓存
        self._model_cache = {}
        self._vector_cache = {}
        self._faiss_indexes = {}
        
        # 性能统计
        self._performance_stats = {
            "total_vectorizations": 0,
            "total_time_ms": 0,
            "average_time_ms": 0,
            "cache_hits": 0,
            "cache_misses": 0
        }
        
        logger.info("AI身份向量化处理器初始化完成", config=asdict(self.config))
    
    async def initialize(self):
        """初始化向量化处理器"""
        try:
            if not HAS_VECTOR_DEPS:
                raise ImportError("向量化依赖包未安装")
            
            # 加载默认模型
            await self._load_default_models()
            
            # 初始化FAISS索引
            await self._initialize_faiss_indexes()
            
            logger.info("AI身份向量化处理器初始化成功")
            return True
            
        except Exception as e:
            logger.error("AI身份向量化处理器初始化失败", error=str(e))
            return False
    
    async def _load_default_models(self):
        """加载默认模型"""
        try:
            logger.info("开始加载向量化模型...")
            
            # 加载sentence-transformers模型
            model_name = self.config.model_name
            if model_name not in self._model_cache:
                logger.info("加载sentence-transformers模型", model_name=model_name)
                
                # 在线程池中加载模型
                loop = asyncio.get_event_loop()
                model = await loop.run_in_executor(
                    self.executor, 
                    SentenceTransformer, 
                    model_name
                )
                
                self._model_cache[model_name] = model
                logger.info("sentence-transformers模型加载完成", model_name=model_name)
            
            # 加载TF-IDF模型
            tfidf_model_name = "tfidf_vectorizer"
            if tfidf_model_name not in self._model_cache:
                logger.info("初始化TF-IDF向量化器")
                
                tfidf_vectorizer = TfidfVectorizer(
                    max_features=5000,
                    ngram_range=(1, 2),
                    stop_words='english',
                    lowercase=True,
                    strip_accents='unicode'
                )
                
                self._model_cache[tfidf_model_name] = tfidf_vectorizer
                logger.info("TF-IDF向量化器初始化完成")
            
            logger.info("所有向量化模型加载完成")
            
        except Exception as e:
            logger.error("加载向量化模型失败", error=str(e))
            raise
    
    async def _initialize_faiss_indexes(self):
        """初始化FAISS索引"""
        try:
            if not self.config.use_faiss_index:
                return
            
            logger.info("初始化FAISS索引...")
            
            # 为每种向量类型创建索引
            for vector_type in VectorType:
                if vector_type == VectorType.CUSTOM:
                    continue
                
                # 创建FAISS索引
                index = faiss.IndexFlatIP(self.config.vector_dimension)
                self._faiss_indexes[vector_type.value] = index
                
                logger.info("FAISS索引创建完成", vector_type=vector_type.value)
            
            logger.info("所有FAISS索引初始化完成")
            
        except Exception as e:
            logger.error("初始化FAISS索引失败", error=str(e))
            raise
    
    async def vectorize_ai_identity_profile(self, profile_data: Dict[str, Any], 
                                          vector_type: VectorType = VectorType.COMPREHENSIVE) -> VectorizationResult:
        """向量化AI身份档案"""
        try:
            start_time = time.time()
            
            logger.info("开始向量化AI身份档案", 
                       profile_id=profile_data.get("profile_id"),
                       vector_type=vector_type.value)
            
            # 生成向量ID
            vector_id = f"vector_{profile_data.get('profile_id', 'unknown')}_{vector_type.value}_{int(datetime.now().timestamp())}"
            
            # 提取文本数据
            text_data = await self._extract_text_data(profile_data, vector_type)
            
            # 生成向量嵌入
            vector_embedding = await self._generate_embedding(text_data, vector_type)
            
            # 计算向量属性
            vector_norm = float(np.linalg.norm(vector_embedding))
            vector_magnitude = float(np.sqrt(np.sum(vector_embedding ** 2)))
            
            # 计算置信度
            confidence_score = await self._calculate_confidence_score(profile_data, vector_type, vector_embedding)
            
            # 标准化向量
            if self.config.normalize_vectors:
                vector_embedding = normalize(vector_embedding.reshape(1, -1)).flatten()
            
            # 创建向量化结果
            result = VectorizationResult(
                vector_id=vector_id,
                profile_id=profile_data.get("profile_id", ""),
                vector_type=vector_type,
                vector_embedding=vector_embedding,
                vector_dimension=len(vector_embedding),
                vector_model=self.config.model_name,
                embedding_source=text_data,
                embedding_algorithm="sentence-transformers",
                embedding_parameters={
                    "model_name": self.config.model_name,
                    "max_sequence_length": self.config.max_sequence_length,
                    "normalize": self.config.normalize_vectors
                },
                embedding_time_ms=int((time.time() - start_time) * 1000),
                vector_norm=vector_norm,
                vector_magnitude=vector_magnitude,
                confidence_score=confidence_score,
                metadata={
                    "text_length": len(text_data),
                    "vector_type": vector_type.value,
                    "model_config": asdict(self.config)
                },
                created_at=datetime.now()
            )
            
            # 更新性能统计
            self._update_performance_stats(result.embedding_time_ms)
            
            # 缓存结果
            if self.config.cache_embeddings:
                await self._cache_vector_result(result)
            
            # 添加到FAISS索引
            if self.config.use_faiss_index:
                await self._add_to_faiss_index(result)
            
            logger.info("AI身份档案向量化完成", 
                       vector_id=vector_id,
                       embedding_time_ms=result.embedding_time_ms,
                       confidence_score=confidence_score)
            
            return result
            
        except Exception as e:
            logger.error("向量化AI身份档案失败", 
                        profile_id=profile_data.get("profile_id"),
                        vector_type=vector_type.value,
                        error=str(e))
            raise
    
    async def _extract_text_data(self, profile_data: Dict[str, Any], vector_type: VectorType) -> str:
        """提取文本数据"""
        try:
            text_parts = []
            
            if vector_type == VectorType.COMPREHENSIVE:
                # 提取所有文本数据
                text_parts.extend(await self._extract_personal_info_text(profile_data))
                text_parts.extend(await self._extract_skills_text(profile_data))
                text_parts.extend(await self._extract_experiences_text(profile_data))
                text_parts.extend(await self._extract_competencies_text(profile_data))
                
            elif vector_type == VectorType.SKILL:
                # 提取技能相关文本
                text_parts.extend(await self._extract_skills_text(profile_data))
                
            elif vector_type == VectorType.EXPERIENCE:
                # 提取经验相关文本
                text_parts.extend(await self._extract_experiences_text(profile_data))
                
            elif vector_type == VectorType.COMPETENCY:
                # 提取能力相关文本
                text_parts.extend(await self._extract_competencies_text(profile_data))
            
            # 合并文本
            combined_text = " ".join(filter(None, text_parts))
            
            # 限制文本长度
            if len(combined_text) > self.config.max_sequence_length * 4:  # 粗略估计
                combined_text = combined_text[:self.config.max_sequence_length * 4]
            
            return combined_text
            
        except Exception as e:
            logger.error("提取文本数据失败", vector_type=vector_type.value, error=str(e))
            return ""
    
    async def _extract_personal_info_text(self, profile_data: Dict[str, Any]) -> List[str]:
        """提取个人信息文本"""
        text_parts = []
        
        personal_info = profile_data.get("personal_info", {})
        if personal_info:
            text_parts.append(f"Name: {personal_info.get('name', '')}")
            text_parts.append(f"Industry: {personal_info.get('industry', '')}")
            text_parts.append(f"Experience: {personal_info.get('experience_years', 0)} years")
            text_parts.append(f"Location: {personal_info.get('location', '')}")
        
        education_background = profile_data.get("education_background", [])
        for education in education_background:
            text_parts.append(f"Education: {education.get('degree', '')} in {education.get('major', '')}")
            text_parts.append(f"School: {education.get('school', '')}")
        
        return text_parts
    
    async def _extract_skills_text(self, profile_data: Dict[str, Any]) -> List[str]:
        """提取技能文本"""
        text_parts = []
        
        skills = profile_data.get("skills", [])
        for skill in skills:
            if isinstance(skill, dict):
                text_parts.append(f"Skill: {skill.get('skill_name', '')}")
                text_parts.append(f"Level: {skill.get('level', '')}")
                text_parts.append(f"Category: {skill.get('category', '')}")
                
                # 添加相关技能
                related_skills = skill.get('related_skills', [])
                if related_skills:
                    text_parts.append(f"Related: {', '.join(related_skills)}")
                
                # 添加行业相关性
                industry_relevance = skill.get('industry_relevance', {})
                if industry_relevance:
                    industries = [f"{industry}({score:.2f})" for industry, score in industry_relevance.items()]
                    text_parts.append(f"Industries: {', '.join(industries)}")
        
        return text_parts
    
    async def _extract_experiences_text(self, profile_data: Dict[str, Any]) -> List[str]:
        """提取经验文本"""
        text_parts = []
        
        experiences = profile_data.get("experiences", [])
        for experience in experiences:
            if isinstance(experience, dict):
                text_parts.append(f"Project: {experience.get('project_title', '')}")
                text_parts.append(f"Description: {experience.get('project_description', '')}")
                text_parts.append(f"Complexity: {experience.get('complexity_level', '')}")
                
                # 添加成就
                achievements = experience.get('achievements', [])
                for achievement in achievements:
                    if isinstance(achievement, dict):
                        text_parts.append(f"Achievement: {achievement.get('type', '')} - {achievement.get('metric', '')}")
                
                # 添加领导力指标
                leadership_indicators = experience.get('leadership_indicators', [])
                for indicator in leadership_indicators:
                    if isinstance(indicator, dict):
                        text_parts.append(f"Leadership: {indicator.get('type', '')}")
        
        return text_parts
    
    async def _extract_competencies_text(self, profile_data: Dict[str, Any]) -> List[str]:
        """提取能力文本"""
        text_parts = []
        
        competencies = profile_data.get("competencies", [])
        for competency in competencies:
            if isinstance(competency, dict):
                text_parts.append(f"Competency: {competency.get('competency_name', '')}")
                text_parts.append(f"Type: {competency.get('competency_type', '')}")
                text_parts.append(f"Level: {competency.get('competency_level', '')}")
                text_parts.append(f"Evidence: {competency.get('evidence_text', '')}")
                
                # 添加匹配关键词
                keywords_matched = competency.get('keywords_matched', [])
                if keywords_matched:
                    text_parts.append(f"Keywords: {', '.join(keywords_matched)}")
        
        return text_parts
    
    async def _generate_embedding(self, text_data: str, vector_type: VectorType) -> np.ndarray:
        """生成向量嵌入"""
        try:
            if not text_data.strip():
                # 返回零向量
                return np.zeros(self.config.vector_dimension, dtype=np.float32)
            
            # 使用sentence-transformers模型
            model = self._model_cache.get(self.config.model_name)
            if not model:
                raise ValueError(f"模型未加载: {self.config.model_name}")
            
            # 在线程池中生成嵌入
            loop = asyncio.get_event_loop()
            embedding = await loop.run_in_executor(
                self.executor,
                model.encode,
                text_data,
                {
                    "batch_size": self.config.batch_size,
                    "show_progress_bar": False,
                    "convert_to_numpy": True
                }
            )
            
            # 确保是numpy数组
            if not isinstance(embedding, np.ndarray):
                embedding = np.array(embedding)
            
            # 确保维度正确
            if embedding.ndim > 1:
                embedding = embedding.flatten()
            
            return embedding.astype(np.float32)
            
        except Exception as e:
            logger.error("生成向量嵌入失败", error=str(e))
            # 返回随机向量作为fallback
            return np.random.randn(self.config.vector_dimension).astype(np.float32)
    
    async def _calculate_confidence_score(self, profile_data: Dict[str, Any], 
                                        vector_type: VectorType, 
                                        vector_embedding: np.ndarray) -> float:
        """计算置信度评分"""
        try:
            confidence_factors = []
            
            # 数据完整性因子
            data_completeness = profile_data.get("data_completeness", 0.0)
            confidence_factors.append(data_completeness)
            
            # 向量质量因子
            vector_norm = float(np.linalg.norm(vector_embedding))
            if vector_norm > 0:
                confidence_factors.append(min(vector_norm / np.sqrt(len(vector_embedding)), 1.0))
            
            # 数据量因子
            if vector_type == VectorType.COMPREHENSIVE:
                skills_count = len(profile_data.get("skills", []))
                experiences_count = len(profile_data.get("experiences", []))
                competencies_count = len(profile_data.get("competencies", []))
                
                total_data_count = skills_count + experiences_count + competencies_count
                data_abundance = min(total_data_count / 20.0, 1.0)  # 假设20为充足数据量
                confidence_factors.append(data_abundance)
            
            # 计算综合置信度
            if confidence_factors:
                confidence_score = sum(confidence_factors) / len(confidence_factors)
            else:
                confidence_score = 0.5
            
            return min(max(confidence_score, 0.0), 1.0)
            
        except Exception as e:
            logger.error("计算置信度评分失败", error=str(e))
            return 0.5
    
    async def _cache_vector_result(self, result: VectorizationResult):
        """缓存向量化结果"""
        try:
            cache_key = f"{result.profile_id}_{result.vector_type.value}"
            
            # 转换为可序列化格式
            cache_data = {
                "vector_id": result.vector_id,
                "profile_id": result.profile_id,
                "vector_type": result.vector_type.value,
                "vector_embedding": result.vector_embedding.tolist(),
                "vector_dimension": result.vector_dimension,
                "vector_model": result.vector_model,
                "confidence_score": result.confidence_score,
                "created_at": result.created_at.isoformat(),
                "ttl": int(time.time()) + self.config.cache_ttl
            }
            
            self._vector_cache[cache_key] = cache_data
            
        except Exception as e:
            logger.error("缓存向量化结果失败", error=str(e))
    
    async def _add_to_faiss_index(self, result: VectorizationResult):
        """添加到FAISS索引"""
        try:
            if not self.config.use_faiss_index:
                return
            
            index = self._faiss_indexes.get(result.vector_type.value)
            if not index:
                logger.warning("FAISS索引不存在", vector_type=result.vector_type.value)
                return
            
            # 准备向量数据
            vector = result.vector_embedding.reshape(1, -1).astype(np.float32)
            
            # 添加到索引
            index.add(vector)
            
            logger.debug("向量添加到FAISS索引", 
                        vector_type=result.vector_type.value,
                        index_size=index.ntotal)
            
        except Exception as e:
            logger.error("添加向量到FAISS索引失败", error=str(e))
    
    async def batch_vectorize(self, profiles_data: List[Dict[str, Any]], 
                            vector_type: VectorType = VectorType.COMPREHENSIVE) -> List[VectorizationResult]:
        """批量向量化"""
        try:
            logger.info("开始批量向量化", 
                       profile_count=len(profiles_data),
                       vector_type=vector_type.value)
            
            results = []
            
            # 分批处理
            for i in range(0, len(profiles_data), self.config.batch_size):
                batch = profiles_data[i:i + self.config.batch_size]
                
                # 并行处理批次
                tasks = [
                    self.vectorize_ai_identity_profile(profile, vector_type)
                    for profile in batch
                ]
                
                batch_results = await asyncio.gather(*tasks, return_exceptions=True)
                
                # 处理结果
                for result in batch_results:
                    if isinstance(result, Exception):
                        logger.error("批量向量化失败", error=str(result))
                    else:
                        results.append(result)
                
                logger.info("批次向量化完成", 
                           batch_index=i // self.config.batch_size + 1,
                           batch_size=len(batch),
                           total_results=len(results))
            
            logger.info("批量向量化完成", 
                       total_profiles=len(profiles_data),
                       successful_results=len(results))
            
            return results
            
        except Exception as e:
            logger.error("批量向量化失败", error=str(e))
            return []
    
    async def search_similar_vectors(self, query_vector: np.ndarray, 
                                   vector_type: VectorType = VectorType.COMPREHENSIVE,
                                   top_k: int = 10) -> List[Tuple[int, float]]:
        """搜索相似向量"""
        try:
            if not self.config.use_faiss_index:
                logger.warning("FAISS索引未启用，无法进行向量搜索")
                return []
            
            index = self._faiss_indexes.get(vector_type.value)
            if not index or index.ntotal == 0:
                logger.warning("FAISS索引为空或不存在", vector_type=vector_type.value)
                return []
            
            # 准备查询向量
            query_vector = query_vector.reshape(1, -1).astype(np.float32)
            
            # 搜索相似向量
            scores, indices = index.search(query_vector, min(top_k, index.ntotal))
            
            # 返回结果
            results = [(int(idx), float(score)) for idx, score in zip(indices[0], scores[0]) if idx >= 0]
            
            logger.info("向量搜索完成", 
                       vector_type=vector_type.value,
                       top_k=top_k,
                       results_count=len(results))
            
            return results
            
        except Exception as e:
            logger.error("搜索相似向量失败", error=str(e))
            return []
    
    def _update_performance_stats(self, execution_time_ms: int):
        """更新性能统计"""
        self._performance_stats["total_vectorizations"] += 1
        self._performance_stats["total_time_ms"] += execution_time_ms
        self._performance_stats["average_time_ms"] = (
            self._performance_stats["total_time_ms"] / 
            self._performance_stats["total_vectorizations"]
        )
    
    async def get_performance_stats(self) -> Dict[str, Any]:
        """获取性能统计"""
        return {
            **self._performance_stats,
            "cache_hit_rate": (
                self._performance_stats["cache_hits"] / 
                max(self._performance_stats["cache_hits"] + self._performance_stats["cache_misses"], 1)
            ),
            "faiss_indexes": {
                vector_type: index.ntotal 
                for vector_type, index in self._faiss_indexes.items()
            },
            "model_cache_size": len(self._model_cache),
            "vector_cache_size": len(self._vector_cache)
        }
    
    async def cleanup(self):
        """清理资源"""
        try:
            # 关闭线程池
            self.executor.shutdown(wait=True)
            
            # 清理缓存
            self._model_cache.clear()
            self._vector_cache.clear()
            self._faiss_indexes.clear()
            
            logger.info("AI身份向量化处理器清理完成")
            
        except Exception as e:
            logger.error("清理AI身份向量化处理器失败", error=str(e))

# 使用示例
async def main():
    """主函数示例"""
    # 创建向量化配置
    config = VectorizationConfig(
        model_name="all-MiniLM-L6-v2",
        vector_dimension=384,
        batch_size=16,
        normalize_vectors=True,
        use_faiss_index=True
    )
    
    # 创建向量化处理器
    vectorizer = AIIdentityVectorization(config)
    
    # 初始化
    if await vectorizer.initialize():
        logger.info("AI身份向量化处理器初始化成功")
        
        # 模拟AI身份档案数据
        profile_data = {
            "profile_id": "test_profile_001",
            "personal_info": {
                "name": "Test User",
                "industry": "Technology",
                "experience_years": 5
            },
            "skills": [
                {
                    "skill_name": "Python",
                    "level": "ADVANCED",
                    "category": "programming_language",
                    "related_skills": ["Django", "Flask"]
                }
            ],
            "experiences": [
                {
                    "project_title": "Web Application",
                    "project_description": "Built a web application using Python Django",
                    "complexity_level": "HIGH"
                }
            ],
            "competencies": [
                {
                    "competency_name": "PROGRAMMING",
                    "competency_type": "technical",
                    "competency_level": "ADVANCED",
                    "evidence_text": "5 years of Python development experience"
                }
            ],
            "data_completeness": 0.8
        }
        
        # 向量化AI身份档案
        result = await vectorizer.vectorize_ai_identity_profile(profile_data)
        
        logger.info("向量化结果", 
                   vector_id=result.vector_id,
                   vector_dimension=result.vector_dimension,
                   confidence_score=result.confidence_score)
        
        # 获取性能统计
        stats = await vectorizer.get_performance_stats()
        logger.info("性能统计", stats=stats)
        
        # 清理
        await vectorizer.cleanup()
        
    else:
        logger.error("AI身份向量化处理器初始化失败")

if __name__ == "__main__":
    asyncio.run(main())
