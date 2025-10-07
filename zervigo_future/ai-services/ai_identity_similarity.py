#!/usr/bin/env python3
"""
AI身份相似度计算引擎
实现多种相似度计算算法，支持向量相似度、内容相似度和综合相似度计算
基于余弦相似度、欧几里得距离、皮尔逊相关系数等多种算法
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
import math

# 相似度计算相关依赖
try:
    from scipy.spatial.distance import cosine, euclidean, cityblock
    from scipy.stats import pearsonr
    from sklearn.metrics.pairwise import cosine_similarity, euclidean_distances, manhattan_distances
    from sklearn.preprocessing import normalize
    HAS_SIMILARITY_DEPS = True
except ImportError:
    HAS_SIMILARITY_DEPS = False
    logger = structlog.get_logger()
    logger.warning("相似度计算依赖包未安装，请安装: pip install scipy scikit-learn")

logger = structlog.get_logger()

class SimilarityType(Enum):
    """相似度类型枚举"""
    COMPREHENSIVE = "comprehensive"  # 综合相似度
    SKILL = "skill"  # 技能相似度
    EXPERIENCE = "experience"  # 经验相似度
    COMPETENCY = "competency"  # 能力相似度
    CUSTOM = "custom"  # 自定义相似度

class SimilarityAlgorithm(Enum):
    """相似度算法枚举"""
    COSINE = "cosine"  # 余弦相似度
    EUCLIDEAN = "euclidean"  # 欧几里得距离
    MANHATTAN = "manhattan"  # 曼哈顿距离
    PEARSON = "pearson"  # 皮尔逊相关系数
    JACCARD = "jaccard"  # Jaccard相似度
    WEIGHTED = "weighted"  # 加权相似度

@dataclass
class SimilarityConfig:
    """相似度计算配置"""
    primary_algorithm: SimilarityAlgorithm = SimilarityAlgorithm.COSINE
    secondary_algorithms: List[SimilarityAlgorithm] = None
    use_weighted_similarity: bool = True
    skill_weight: float = 0.4
    experience_weight: float = 0.3
    competency_weight: float = 0.3
    normalize_vectors: bool = True
    cache_results: bool = True
    cache_ttl: int = 3600  # 缓存TTL(秒)
    batch_size: int = 100  # 批处理大小
    similarity_threshold: float = 0.1  # 相似度阈值

@dataclass
class SimilarityResult:
    """相似度计算结果"""
    similarity_id: str
    source_profile_id: str
    target_profile_id: str
    similarity_type: SimilarityType
    cosine_similarity: float
    euclidean_distance: float
    manhattan_distance: float
    pearson_correlation: Optional[float]
    overall_similarity_score: float
    similarity_rank: Optional[int]
    similarity_components: Dict[str, float]
    matching_features: Dict[str, Any]
    similarity_explanation: str
    calculation_algorithm: str
    calculation_parameters: Dict[str, Any]
    calculation_time_ms: int
    confidence_score: float
    metadata: Dict[str, Any]
    created_at: datetime

class AIIdentitySimilarity:
    """AI身份相似度计算引擎"""
    
    def __init__(self, config: SimilarityConfig = None):
        self.config = config or SimilarityConfig()
        if self.config.secondary_algorithms is None:
            self.config.secondary_algorithms = [
                SimilarityAlgorithm.EUCLIDEAN,
                SimilarityAlgorithm.MANHATTAN,
                SimilarityAlgorithm.PEARSON
            ]
        
        self.executor = ThreadPoolExecutor(max_workers=4)
        
        # 结果缓存
        self._similarity_cache = {}
        self._vector_cache = {}
        
        # 性能统计
        self._performance_stats = {
            "total_calculations": 0,
            "total_time_ms": 0,
            "average_time_ms": 0,
            "cache_hits": 0,
            "cache_misses": 0,
            "algorithm_usage": {alg.value: 0 for alg in SimilarityAlgorithm}
        }
        
        logger.info("AI身份相似度计算引擎初始化完成", config=asdict(self.config))
    
    async def initialize(self):
        """初始化相似度计算引擎"""
        try:
            if not HAS_SIMILARITY_DEPS:
                raise ImportError("相似度计算依赖包未安装")
            
            logger.info("AI身份相似度计算引擎初始化成功")
            return True
            
        except Exception as e:
            logger.error("AI身份相似度计算引擎初始化失败", error=str(e))
            return False
    
    async def calculate_similarity(self, source_vector: np.ndarray, 
                                 target_vector: np.ndarray,
                                 source_profile_id: str,
                                 target_profile_id: str,
                                 similarity_type: SimilarityType = SimilarityType.COMPREHENSIVE,
                                 custom_weights: Optional[Dict[str, float]] = None) -> SimilarityResult:
        """计算两个向量的相似度"""
        try:
            start_time = time.time()
            
            logger.info("开始计算相似度", 
                       source_profile_id=source_profile_id,
                       target_profile_id=target_profile_id,
                       similarity_type=similarity_type.value)
            
            # 生成相似度ID
            similarity_id = f"sim_{source_profile_id}_{target_profile_id}_{similarity_type.value}_{int(datetime.now().timestamp())}"
            
            # 检查缓存
            cache_key = f"{source_profile_id}_{target_profile_id}_{similarity_type.value}"
            if self.config.cache_results and cache_key in self._similarity_cache:
                cached_result = self._similarity_cache[cache_key]
                if time.time() - cached_result["timestamp"] < self.config.cache_ttl:
                    self._performance_stats["cache_hits"] += 1
                    logger.info("使用缓存的相似度结果", cache_key=cache_key)
                    return self._deserialize_similarity_result(cached_result["result"])
            
            self._performance_stats["cache_misses"] += 1
            
            # 标准化向量
            if self.config.normalize_vectors:
                source_vector = self._normalize_vector(source_vector)
                target_vector = self._normalize_vector(target_vector)
            
            # 计算各种相似度指标
            similarity_metrics = await self._calculate_all_similarities(source_vector, target_vector)
            
            # 计算综合相似度评分
            overall_score = await self._calculate_overall_similarity(
                similarity_metrics, similarity_type, custom_weights
            )
            
            # 生成匹配特征
            matching_features = await self._extract_matching_features(
                source_vector, target_vector, similarity_metrics
            )
            
            # 生成相似度解释
            similarity_explanation = await self._generate_similarity_explanation(
                similarity_metrics, overall_score, similarity_type
            )
            
            # 计算置信度
            confidence_score = await self._calculate_confidence_score(
                similarity_metrics, overall_score
            )
            
            # 创建相似度结果
            result = SimilarityResult(
                similarity_id=similarity_id,
                source_profile_id=source_profile_id,
                target_profile_id=target_profile_id,
                similarity_type=similarity_type,
                cosine_similarity=similarity_metrics["cosine_similarity"],
                euclidean_distance=similarity_metrics["euclidean_distance"],
                manhattan_distance=similarity_metrics["manhattan_distance"],
                pearson_correlation=similarity_metrics["pearson_correlation"],
                overall_similarity_score=overall_score,
                similarity_rank=None,  # 将在批量计算中设置
                similarity_components=similarity_metrics["components"],
                matching_features=matching_features,
                similarity_explanation=similarity_explanation,
                calculation_algorithm=self.config.primary_algorithm.value,
                calculation_parameters=asdict(self.config),
                calculation_time_ms=int((time.time() - start_time) * 1000),
                confidence_score=confidence_score,
                metadata={
                    "vector_dimensions": {
                        "source": len(source_vector),
                        "target": len(target_vector)
                    },
                    "normalized": self.config.normalize_vectors,
                    "weights": custom_weights or {}
                },
                created_at=datetime.now()
            )
            
            # 更新性能统计
            self._update_performance_stats(result.calculation_time_ms)
            
            # 缓存结果
            if self.config.cache_results:
                await self._cache_similarity_result(result)
            
            logger.info("相似度计算完成", 
                       similarity_id=similarity_id,
                       overall_score=overall_score,
                       calculation_time_ms=result.calculation_time_ms)
            
            return result
            
        except Exception as e:
            logger.error("计算相似度失败", 
                        source_profile_id=source_profile_id,
                        target_profile_id=target_profile_id,
                        error=str(e))
            raise
    
    async def _calculate_all_similarities(self, source_vector: np.ndarray, 
                                        target_vector: np.ndarray) -> Dict[str, Any]:
        """计算所有相似度指标"""
        try:
            metrics = {}
            
            # 余弦相似度
            cosine_sim = cosine_similarity(source_vector.reshape(1, -1), target_vector.reshape(1, -1))[0][0]
            metrics["cosine_similarity"] = float(cosine_sim)
            
            # 欧几里得距离
            euclidean_dist = euclidean_distances(source_vector.reshape(1, -1), target_vector.reshape(1, -1))[0][0]
            metrics["euclidean_distance"] = float(euclidean_dist)
            
            # 曼哈顿距离
            manhattan_dist = manhattan_distances(source_vector.reshape(1, -1), target_vector.reshape(1, -1))[0][0]
            metrics["manhattan_distance"] = float(manhattan_dist)
            
            # 皮尔逊相关系数
            try:
                if len(source_vector) == len(target_vector) and len(source_vector) > 1:
                    pearson_corr, _ = pearsonr(source_vector, target_vector)
                    metrics["pearson_correlation"] = float(pearson_corr) if not np.isnan(pearson_corr) else None
                else:
                    metrics["pearson_correlation"] = None
            except Exception:
                metrics["pearson_correlation"] = None
            
            # 计算组件相似度
            components = {
                "cosine_component": metrics["cosine_similarity"],
                "euclidean_component": 1.0 / (1.0 + metrics["euclidean_distance"]),  # 转换为相似度
                "manhattan_component": 1.0 / (1.0 + metrics["manhattan_distance"]),  # 转换为相似度
                "pearson_component": abs(metrics["pearson_correlation"]) if metrics["pearson_correlation"] is not None else 0.0
            }
            
            metrics["components"] = components
            
            return metrics
            
        except Exception as e:
            logger.error("计算相似度指标失败", error=str(e))
            return {
                "cosine_similarity": 0.0,
                "euclidean_distance": float('inf'),
                "manhattan_distance": float('inf'),
                "pearson_correlation": None,
                "components": {
                    "cosine_component": 0.0,
                    "euclidean_component": 0.0,
                    "manhattan_component": 0.0,
                    "pearson_component": 0.0
                }
            }
    
    async def _calculate_overall_similarity(self, similarity_metrics: Dict[str, Any], 
                                          similarity_type: SimilarityType,
                                          custom_weights: Optional[Dict[str, float]] = None) -> float:
        """计算综合相似度评分"""
        try:
            components = similarity_metrics["components"]
            
            # 根据相似度类型设置权重
            if similarity_type == SimilarityType.SKILL:
                weights = {"cosine_component": 0.5, "euclidean_component": 0.3, "manhattan_component": 0.2}
            elif similarity_type == SimilarityType.EXPERIENCE:
                weights = {"cosine_component": 0.4, "euclidean_component": 0.4, "manhattan_component": 0.2}
            elif similarity_type == SimilarityType.COMPETENCY:
                weights = {"cosine_component": 0.6, "euclidean_component": 0.2, "manhattan_component": 0.2}
            else:  # COMPREHENSIVE
                weights = {"cosine_component": 0.5, "euclidean_component": 0.3, "manhattan_component": 0.2}
            
            # 使用自定义权重
            if custom_weights:
                weights.update(custom_weights)
            
            # 计算加权平均
            weighted_sum = 0.0
            total_weight = 0.0
            
            for component, weight in weights.items():
                if component in components:
                    weighted_sum += components[component] * weight
                    total_weight += weight
            
            # 添加皮尔逊相关系数权重
            if "pearson_component" in components and components["pearson_component"] is not None:
                pearson_weight = 0.1
                weighted_sum += components["pearson_component"] * pearson_weight
                total_weight += pearson_weight
            
            overall_score = weighted_sum / total_weight if total_weight > 0 else 0.0
            
            # 确保分数在0-1范围内
            return max(0.0, min(1.0, overall_score))
            
        except Exception as e:
            logger.error("计算综合相似度评分失败", error=str(e))
            return 0.0
    
    async def _extract_matching_features(self, source_vector: np.ndarray, 
                                       target_vector: np.ndarray,
                                       similarity_metrics: Dict[str, Any]) -> Dict[str, Any]:
        """提取匹配特征"""
        try:
            features = {
                "vector_similarity": {
                    "cosine": similarity_metrics["cosine_similarity"],
                    "euclidean_inverse": 1.0 / (1.0 + similarity_metrics["euclidean_distance"]),
                    "manhattan_inverse": 1.0 / (1.0 + similarity_metrics["manhattan_distance"])
                },
                "vector_properties": {
                    "source_norm": float(np.linalg.norm(source_vector)),
                    "target_norm": float(np.linalg.norm(target_vector)),
                    "source_mean": float(np.mean(source_vector)),
                    "target_mean": float(np.mean(target_vector)),
                    "source_std": float(np.std(source_vector)),
                    "target_std": float(np.std(target_vector))
                },
                "dimension_analysis": {
                    "source_dimensions": len(source_vector),
                    "target_dimensions": len(target_vector),
                    "dimension_match": len(source_vector) == len(target_vector)
                },
                "high_impact_features": []
            }
            
            # 找出高影响特征（向量值差异较大的维度）
            if len(source_vector) == len(target_vector):
                diff_vector = np.abs(source_vector - target_vector)
                top_diff_indices = np.argsort(diff_vector)[-5:]  # 前5个差异最大的维度
                
                for idx in top_diff_indices:
                    features["high_impact_features"].append({
                        "dimension": int(idx),
                        "source_value": float(source_vector[idx]),
                        "target_value": float(target_vector[idx]),
                        "difference": float(diff_vector[idx])
                    })
            
            return features
            
        except Exception as e:
            logger.error("提取匹配特征失败", error=str(e))
            return {}
    
    async def _generate_similarity_explanation(self, similarity_metrics: Dict[str, Any], 
                                             overall_score: float,
                                             similarity_type: SimilarityType) -> str:
        """生成相似度解释"""
        try:
            explanations = []
            
            # 总体相似度解释
            if overall_score >= 0.8:
                explanations.append("高度相似")
            elif overall_score >= 0.6:
                explanations.append("中等相似")
            elif overall_score >= 0.4:
                explanations.append("轻度相似")
            else:
                explanations.append("相似度较低")
            
            # 具体指标解释
            cosine_sim = similarity_metrics["cosine_similarity"]
            if cosine_sim >= 0.9:
                explanations.append("方向高度一致")
            elif cosine_sim >= 0.7:
                explanations.append("方向基本一致")
            elif cosine_sim >= 0.5:
                explanations.append("方向部分一致")
            else:
                explanations.append("方向差异较大")
            
            # 距离解释
            euclidean_dist = similarity_metrics["euclidean_distance"]
            if euclidean_dist <= 0.5:
                explanations.append("向量距离较近")
            elif euclidean_dist <= 1.0:
                explanations.append("向量距离适中")
            else:
                explanations.append("向量距离较远")
            
            # 皮尔逊相关系数解释
            pearson_corr = similarity_metrics["pearson_correlation"]
            if pearson_corr is not None:
                if pearson_corr >= 0.8:
                    explanations.append("线性关系强")
                elif pearson_corr >= 0.5:
                    explanations.append("线性关系中等")
                elif pearson_corr >= 0.3:
                    explanations.append("线性关系弱")
                else:
                    explanations.append("线性关系很弱")
            
            # 相似度类型特定解释
            if similarity_type == SimilarityType.SKILL:
                explanations.append("技能匹配度分析")
            elif similarity_type == SimilarityType.EXPERIENCE:
                explanations.append("经验匹配度分析")
            elif similarity_type == SimilarityType.COMPETENCY:
                explanations.append("能力匹配度分析")
            else:
                explanations.append("综合匹配度分析")
            
            return "；".join(explanations)
            
        except Exception as e:
            logger.error("生成相似度解释失败", error=str(e))
            return "相似度计算完成"
    
    async def _calculate_confidence_score(self, similarity_metrics: Dict[str, Any], 
                                        overall_score: float) -> float:
        """计算置信度评分"""
        try:
            confidence_factors = []
            
            # 基于综合评分的置信度
            if overall_score >= 0.8 or overall_score <= 0.2:
                confidence_factors.append(0.9)  # 极端值置信度高
            elif overall_score >= 0.6 or overall_score <= 0.4:
                confidence_factors.append(0.7)  # 中等值置信度中等
            else:
                confidence_factors.append(0.5)  # 中间值置信度低
            
            # 基于指标一致性的置信度
            components = similarity_metrics["components"]
            component_values = [v for v in components.values() if v is not None]
            
            if component_values:
                component_std = np.std(component_values)
                if component_std <= 0.1:
                    confidence_factors.append(0.9)  # 指标一致
                elif component_std <= 0.2:
                    confidence_factors.append(0.7)  # 指标基本一致
                else:
                    confidence_factors.append(0.5)  # 指标不一致
            
            # 基于皮尔逊相关系数的置信度
            pearson_corr = similarity_metrics["pearson_correlation"]
            if pearson_corr is not None:
                if abs(pearson_corr) >= 0.7:
                    confidence_factors.append(0.8)
                elif abs(pearson_corr) >= 0.5:
                    confidence_factors.append(0.6)
                else:
                    confidence_factors.append(0.4)
            
            # 计算综合置信度
            if confidence_factors:
                confidence_score = sum(confidence_factors) / len(confidence_factors)
            else:
                confidence_score = 0.5
            
            return max(0.0, min(1.0, confidence_score))
            
        except Exception as e:
            logger.error("计算置信度评分失败", error=str(e))
            return 0.5
    
    def _normalize_vector(self, vector: np.ndarray) -> np.ndarray:
        """标准化向量"""
        try:
            norm = np.linalg.norm(vector)
            if norm == 0:
                return vector
            return vector / norm
        except Exception as e:
            logger.error("标准化向量失败", error=str(e))
            return vector
    
    async def _cache_similarity_result(self, result: SimilarityResult):
        """缓存相似度结果"""
        try:
            cache_key = f"{result.source_profile_id}_{result.target_profile_id}_{result.similarity_type.value}"
            
            cache_data = {
                "result": self._serialize_similarity_result(result),
                "timestamp": time.time()
            }
            
            self._similarity_cache[cache_key] = cache_data
            
        except Exception as e:
            logger.error("缓存相似度结果失败", error=str(e))
    
    def _serialize_similarity_result(self, result: SimilarityResult) -> Dict[str, Any]:
        """序列化相似度结果"""
        try:
            return {
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
                "calculation_algorithm": result.calculation_algorithm,
                "calculation_parameters": result.calculation_parameters,
                "calculation_time_ms": result.calculation_time_ms,
                "confidence_score": result.confidence_score,
                "metadata": result.metadata,
                "created_at": result.created_at.isoformat()
            }
        except Exception as e:
            logger.error("序列化相似度结果失败", error=str(e))
            return {}
    
    def _deserialize_similarity_result(self, data: Dict[str, Any]) -> SimilarityResult:
        """反序列化相似度结果"""
        try:
            data["similarity_type"] = SimilarityType(data["similarity_type"])
            data["created_at"] = datetime.fromisoformat(data["created_at"])
            
            return SimilarityResult(**data)
        except Exception as e:
            logger.error("反序列化相似度结果失败", error=str(e))
            raise
    
    async def batch_calculate_similarity(self, vector_pairs: List[Tuple[np.ndarray, np.ndarray, str, str]], 
                                       similarity_type: SimilarityType = SimilarityType.COMPREHENSIVE) -> List[SimilarityResult]:
        """批量计算相似度"""
        try:
            logger.info("开始批量计算相似度", 
                       pair_count=len(vector_pairs),
                       similarity_type=similarity_type.value)
            
            results = []
            
            # 分批处理
            for i in range(0, len(vector_pairs), self.config.batch_size):
                batch = vector_pairs[i:i + self.config.batch_size]
                
                # 并行处理批次
                tasks = [
                    self.calculate_similarity(source_vector, target_vector, source_id, target_id, similarity_type)
                    for source_vector, target_vector, source_id, target_id in batch
                ]
                
                batch_results = await asyncio.gather(*tasks, return_exceptions=True)
                
                # 处理结果
                for j, result in enumerate(batch_results):
                    if isinstance(result, Exception):
                        logger.error("批量相似度计算失败", 
                                   pair_index=i + j, 
                                   error=str(result))
                    else:
                        results.append(result)
                
                logger.info("批次相似度计算完成", 
                           batch_index=i // self.config.batch_size + 1,
                           batch_size=len(batch),
                           total_results=len(results))
            
            # 设置排名
            results.sort(key=lambda x: x.overall_similarity_score, reverse=True)
            for i, result in enumerate(results):
                result.similarity_rank = i + 1
            
            logger.info("批量相似度计算完成", 
                       total_pairs=len(vector_pairs),
                       successful_results=len(results))
            
            return results
            
        except Exception as e:
            logger.error("批量计算相似度失败", error=str(e))
            return []
    
    def _update_performance_stats(self, execution_time_ms: int):
        """更新性能统计"""
        self._performance_stats["total_calculations"] += 1
        self._performance_stats["total_time_ms"] += execution_time_ms
        self._performance_stats["average_time_ms"] = (
            self._performance_stats["total_time_ms"] / 
            self._performance_stats["total_calculations"]
        )
        self._performance_stats["algorithm_usage"][self.config.primary_algorithm.value] += 1
    
    async def get_performance_stats(self) -> Dict[str, Any]:
        """获取性能统计"""
        return {
            **self._performance_stats,
            "cache_hit_rate": (
                self._performance_stats["cache_hits"] / 
                max(self._performance_stats["cache_hits"] + self._performance_stats["cache_misses"], 1)
            ),
            "cache_size": len(self._similarity_cache),
            "vector_cache_size": len(self._vector_cache)
        }
    
    async def cleanup(self):
        """清理资源"""
        try:
            # 关闭线程池
            self.executor.shutdown(wait=True)
            
            # 清理缓存
            self._similarity_cache.clear()
            self._vector_cache.clear()
            
            logger.info("AI身份相似度计算引擎清理完成")
            
        except Exception as e:
            logger.error("清理AI身份相似度计算引擎失败", error=str(e))

# 使用示例
async def main():
    """主函数示例"""
    # 创建相似度计算配置
    config = SimilarityConfig(
        primary_algorithm=SimilarityAlgorithm.COSINE,
        use_weighted_similarity=True,
        skill_weight=0.4,
        experience_weight=0.3,
        competency_weight=0.3,
        normalize_vectors=True,
        cache_results=True
    )
    
    # 创建相似度计算引擎
    similarity_engine = AIIdentitySimilarity(config)
    
    # 初始化
    if await similarity_engine.initialize():
        logger.info("AI身份相似度计算引擎初始化成功")
        
        # 模拟向量数据
        source_vector = np.random.randn(384).astype(np.float32)
        target_vector = np.random.randn(384).astype(np.float32)
        
        # 计算相似度
        result = await similarity_engine.calculate_similarity(
            source_vector=source_vector,
            target_vector=target_vector,
            source_profile_id="profile_001",
            target_profile_id="profile_002",
            similarity_type=SimilarityType.COMPREHENSIVE
        )
        
        logger.info("相似度计算结果", 
                   similarity_id=result.similarity_id,
                   overall_score=result.overall_similarity_score,
                   confidence_score=result.confidence_score)
        
        # 批量计算相似度
        vector_pairs = [
            (source_vector, target_vector, "profile_001", "profile_002"),
            (target_vector, source_vector, "profile_002", "profile_001")
        ]
        
        batch_results = await similarity_engine.batch_calculate_similarity(vector_pairs)
        
        logger.info("批量相似度计算完成", results_count=len(batch_results))
        
        # 获取性能统计
        stats = await similarity_engine.get_performance_stats()
        logger.info("性能统计", stats=stats)
        
        # 清理
        await similarity_engine.cleanup()
        
    else:
        logger.error("AI身份相似度计算引擎初始化失败")

if __name__ == "__main__":
    asyncio.run(main())
