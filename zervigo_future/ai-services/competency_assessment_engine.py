#!/usr/bin/env python3
"""
能力评估框架引擎
基于HireVue能力评估模型，实现技术能力和业务能力的综合评估
"""

import asyncio
import json
import os
import re
import structlog
from datetime import datetime, timedelta
from typing import Dict, List, Any, Optional, Tuple
from dataclasses import dataclass
from enum import Enum

logger = structlog.get_logger()

class CompetencyLevel(Enum):
    """能力等级枚举"""
    BEGINNER = 1
    INTERMEDIATE = 2
    ADVANCED = 3
    EXPERT = 4
    MASTER = 5

class TechnicalCompetencyType(Enum):
    """技术能力类型枚举"""
    PROGRAMMING = "programming"           # 编程能力
    ALGORITHM_DESIGN = "algorithm_design" # 算法设计
    SYSTEM_ARCHITECTURE = "system_architecture" # 系统架构
    DATABASE_DESIGN = "database_design"   # 数据库设计
    TESTING = "testing"                   # 测试能力
    DEVOPS = "devops"                     # DevOps能力
    SECURITY = "security"                 # 安全能力
    PERFORMANCE = "performance"           # 性能优化

class BusinessCompetencyType(Enum):
    """业务能力类型枚举"""
    REQUIREMENTS_ANALYSIS = "requirements_analysis" # 需求分析
    PROJECT_MANAGEMENT = "project_management"       # 项目管理
    COMMUNICATION = "communication"                 # 沟通能力
    PROBLEM_SOLVING = "problem_solving"             # 问题解决
    TEAMWORK = "teamwork"                           # 团队协作
    LEADERSHIP = "leadership"                       # 领导力
    INNOVATION = "innovation"                       # 创新能力
    BUSINESS_ACUMEN = "business_acumen"             # 商业洞察

@dataclass
class TechnicalCompetency:
    """技术能力评估结果"""
    competency_type: TechnicalCompetencyType
    level: CompetencyLevel
    score: float
    confidence: float
    evidence: List[str]
    keywords_matched: List[str]
    assessment_details: Dict[str, Any]

@dataclass
class BusinessCompetency:
    """业务能力评估结果"""
    competency_type: BusinessCompetencyType
    level: CompetencyLevel
    score: float
    confidence: float
    evidence: List[str]
    keywords_matched: List[str]
    assessment_details: Dict[str, Any]

@dataclass
class CompetencyAssessment:
    """综合能力评估结果"""
    technical_competencies: List[TechnicalCompetency]
    business_competencies: List[BusinessCompetency]
    overall_technical_score: float
    overall_business_score: float
    overall_score: float
    competency_profile: Dict[str, Any]
    growth_recommendations: List[str]

class CompetencyAssessmentEngine:
    """能力评估框架引擎"""
    
    def __init__(self):
        self.technical_keywords = {
            TechnicalCompetencyType.PROGRAMMING: {
                "beginner": ["basic", "simple", "hello world", "tutorial", "学习", "基础", "简单", "入门"],
                "intermediate": ["function", "class", "object", "api", "library", "函数", "类", "对象", "接口"],
                "advanced": ["design pattern", "refactoring", "optimization", "framework", "设计模式", "重构", "优化", "框架"],
                "expert": ["architecture", "scalability", "performance", "microservices", "架构", "可扩展性", "性能", "微服务"],
                "master": ["enterprise", "distributed", "cloud-native", "advanced patterns", "企业级", "分布式", "云原生", "高级模式"]
            },
            TechnicalCompetencyType.ALGORITHM_DESIGN: {
                "beginner": ["sort", "search", "basic algorithm", "排序", "搜索", "基础算法"],
                "intermediate": ["data structure", "tree", "graph", "dynamic programming", "数据结构", "树", "图", "动态规划"],
                "advanced": ["complexity", "optimization", "advanced algorithms", "复杂度", "优化", "高级算法"],
                "expert": ["algorithm design", "advanced data structures", "算法设计", "高级数据结构"],
                "master": ["research", "novel algorithms", "algorithm theory", "研究", "新算法", "算法理论"]
            },
            TechnicalCompetencyType.SYSTEM_ARCHITECTURE: {
                "beginner": ["basic design", "simple architecture", "基础设计", "简单架构"],
                "intermediate": ["layered", "modular", "分层", "模块化"],
                "advanced": ["distributed", "scalable", "分布式", "可扩展"],
                "expert": ["microservices", "cloud", "container", "微服务", "云", "容器"],
                "master": ["enterprise", "advanced patterns", "企业级", "高级模式"]
            },
            TechnicalCompetencyType.DATABASE_DESIGN: {
                "beginner": ["table", "query", "basic sql", "表", "查询", "基础sql"],
                "intermediate": ["index", "relationship", "normalization", "索引", "关系", "规范化"],
                "advanced": ["optimization", "performance", "优化", "性能"],
                "expert": ["advanced features", "sharding", "高级特性", "分片"],
                "master": ["enterprise", "advanced patterns", "企业级", "高级模式"]
            },
            TechnicalCompetencyType.TESTING: {
                "beginner": ["unit test", "manual test", "单元测试", "手工测试"],
                "intermediate": ["integration test", "automated test", "集成测试", "自动化测试"],
                "advanced": ["test strategy", "coverage", "测试策略", "覆盖率"],
                "expert": ["advanced testing", "performance test", "高级测试", "性能测试"],
                "master": ["test automation", "advanced patterns", "测试自动化", "高级模式"]
            },
            TechnicalCompetencyType.DEVOPS: {
                "beginner": ["deployment", "basic ci/cd", "部署", "基础ci/cd"],
                "intermediate": ["automation", "monitoring", "自动化", "监控"],
                "advanced": ["container", "orchestration", "容器", "编排"],
                "expert": ["cloud", "advanced patterns", "云", "高级模式"],
                "master": ["enterprise", "advanced automation", "企业级", "高级自动化"]
            },
            TechnicalCompetencyType.SECURITY: {
                "beginner": ["basic security", "authentication", "基础安全", "认证"],
                "intermediate": ["authorization", "encryption", "授权", "加密"],
                "advanced": ["security design", "vulnerability", "安全设计", "漏洞"],
                "expert": ["advanced security", "security architecture", "高级安全", "安全架构"],
                "master": ["enterprise security", "advanced patterns", "企业安全", "高级模式"]
            },
            TechnicalCompetencyType.PERFORMANCE: {
                "beginner": ["basic optimization", "基础优化"],
                "intermediate": ["profiling", "monitoring", "性能分析", "监控"],
                "advanced": ["advanced optimization", "高级优化"],
                "expert": ["performance architecture", "性能架构"],
                "master": ["enterprise performance", "企业级性能"]
            }
        }
        
        self.business_keywords = {
            BusinessCompetencyType.REQUIREMENTS_ANALYSIS: {
                "beginner": ["gather requirements", "basic analysis", "收集需求", "基础分析"],
                "intermediate": ["analyze requirements", "documentation", "分析需求", "文档"],
                "advanced": ["requirements design", "advanced analysis", "需求设计", "高级分析"],
                "expert": ["requirements architecture", "advanced design", "需求架构", "高级设计"],
                "master": ["enterprise requirements", "advanced patterns", "企业需求", "高级模式"]
            },
            BusinessCompetencyType.PROJECT_MANAGEMENT: {
                "beginner": ["basic planning", "simple project", "基础规划", "简单项目"],
                "intermediate": ["project coordination", "timeline", "项目协调", "时间线"],
                "advanced": ["project management", "advanced planning", "项目管理", "高级规划"],
                "expert": ["program management", "advanced coordination", "项目群管理", "高级协调"],
                "master": ["enterprise management", "advanced patterns", "企业管理", "高级模式"]
            },
            BusinessCompetencyType.COMMUNICATION: {
                "beginner": ["basic communication", "简单沟通"],
                "intermediate": ["presentation", "documentation", "演示", "文档"],
                "advanced": ["advanced communication", "高级沟通"],
                "expert": ["stakeholder management", "利益相关者管理"],
                "master": ["enterprise communication", "企业沟通"]
            },
            BusinessCompetencyType.PROBLEM_SOLVING: {
                "beginner": ["basic problem solving", "基础问题解决"],
                "intermediate": ["analyze problems", "分析问题"],
                "advanced": ["advanced problem solving", "高级问题解决"],
                "expert": ["complex problem solving", "复杂问题解决"],
                "master": ["enterprise problem solving", "企业问题解决"]
            },
            BusinessCompetencyType.TEAMWORK: {
                "beginner": ["basic teamwork", "基础团队合作"],
                "intermediate": ["collaboration", "协作"],
                "advanced": ["advanced teamwork", "高级团队合作"],
                "expert": ["team leadership", "团队领导"],
                "master": ["enterprise teamwork", "企业团队合作"]
            },
            BusinessCompetencyType.LEADERSHIP: {
                "beginner": ["basic leadership", "基础领导力"],
                "intermediate": ["team leadership", "团队领导"],
                "advanced": ["advanced leadership", "高级领导力"],
                "expert": ["strategic leadership", "战略领导"],
                "master": ["enterprise leadership", "企业领导"]
            },
            BusinessCompetencyType.INNOVATION: {
                "beginner": ["basic innovation", "基础创新"],
                "intermediate": ["creative thinking", "创造性思维"],
                "advanced": ["advanced innovation", "高级创新"],
                "expert": ["strategic innovation", "战略创新"],
                "master": ["enterprise innovation", "企业创新"]
            },
            BusinessCompetencyType.BUSINESS_ACUMEN: {
                "beginner": ["basic business", "基础商业"],
                "intermediate": ["business understanding", "商业理解"],
                "advanced": ["advanced business", "高级商业"],
                "expert": ["strategic business", "战略商业"],
                "master": ["enterprise business", "企业商业"]
            }
        }
        
        self.assessment_weights = {
            "technical": {
                TechnicalCompetencyType.PROGRAMMING: 0.25,
                TechnicalCompetencyType.ALGORITHM_DESIGN: 0.20,
                TechnicalCompetencyType.SYSTEM_ARCHITECTURE: 0.20,
                TechnicalCompetencyType.DATABASE_DESIGN: 0.15,
                TechnicalCompetencyType.TESTING: 0.10,
                TechnicalCompetencyType.DEVOPS: 0.05,
                TechnicalCompetencyType.SECURITY: 0.03,
                TechnicalCompetencyType.PERFORMANCE: 0.02
            },
            "business": {
                BusinessCompetencyType.REQUIREMENTS_ANALYSIS: 0.20,
                BusinessCompetencyType.PROJECT_MANAGEMENT: 0.20,
                BusinessCompetencyType.COMMUNICATION: 0.15,
                BusinessCompetencyType.PROBLEM_SOLVING: 0.15,
                BusinessCompetencyType.TEAMWORK: 0.10,
                BusinessCompetencyType.LEADERSHIP: 0.10,
                BusinessCompetencyType.INNOVATION: 0.05,
                BusinessCompetencyType.BUSINESS_ACUMEN: 0.05
            }
        }
    
    async def assess_technical_competency(self, text: str) -> List[TechnicalCompetency]:
        """评估技术能力"""
        logger.info("开始技术能力评估", text_length=len(text))
        
        competencies = []
        text_lower = text.lower()
        
        for competency_type, keywords_by_level in self.technical_keywords.items():
            competency = await self._assess_single_technical_competency(
                competency_type, text_lower, keywords_by_level
            )
            if competency:
                competencies.append(competency)
        
        # 按分数排序
        competencies.sort(key=lambda x: x.score, reverse=True)
        
        logger.info("技术能力评估完成", competencies_count=len(competencies))
        return competencies
    
    async def _assess_single_technical_competency(self, competency_type: TechnicalCompetencyType, 
                                                text_lower: str, keywords_by_level: Dict[str, List[str]]) -> Optional[TechnicalCompetency]:
        """评估单个技术能力"""
        total_score = 0.0
        total_matches = 0
        evidence = []
        keywords_matched = []
        
        for level, keywords in keywords_by_level.items():
            level_weight = {
                "beginner": 1.0,
                "intermediate": 2.0,
                "advanced": 3.0,
                "expert": 4.0,
                "master": 5.0
            }.get(level, 1.0)
            
            for keyword in keywords:
                matches = text_lower.count(keyword.lower())
                if matches > 0:
                    score = level_weight * matches
                    total_score += score
                    total_matches += matches
                    evidence.append(f"{keyword}: {matches}次")
                    keywords_matched.append(keyword)
        
        if total_matches == 0:
            return None
        
        # 计算平均分数和等级
        avg_score = total_score / total_matches
        level = self._determine_competency_level(avg_score)
        confidence = min(1.0, total_matches / 10.0)  # 基于匹配数量计算置信度
        
        assessment_details = {
            "total_matches": total_matches,
            "avg_score": avg_score,
            "evidence_count": len(evidence),
            "keyword_count": len(keywords_matched)
        }
        
        return TechnicalCompetency(
            competency_type=competency_type,
            level=level,
            score=avg_score,
            confidence=confidence,
            evidence=evidence,
            keywords_matched=keywords_matched,
            assessment_details=assessment_details
        )
    
    async def assess_business_competency(self, text: str) -> List[BusinessCompetency]:
        """评估业务能力"""
        logger.info("开始业务能力评估", text_length=len(text))
        
        competencies = []
        text_lower = text.lower()
        
        for competency_type, keywords_by_level in self.business_keywords.items():
            competency = await self._assess_single_business_competency(
                competency_type, text_lower, keywords_by_level
            )
            if competency:
                competencies.append(competency)
        
        # 按分数排序
        competencies.sort(key=lambda x: x.score, reverse=True)
        
        logger.info("业务能力评估完成", competencies_count=len(competencies))
        return competencies
    
    async def _assess_single_business_competency(self, competency_type: BusinessCompetencyType, 
                                               text_lower: str, keywords_by_level: Dict[str, List[str]]) -> Optional[BusinessCompetency]:
        """评估单个业务能力"""
        total_score = 0.0
        total_matches = 0
        evidence = []
        keywords_matched = []
        
        for level, keywords in keywords_by_level.items():
            level_weight = {
                "beginner": 1.0,
                "intermediate": 2.0,
                "advanced": 3.0,
                "expert": 4.0,
                "master": 5.0
            }.get(level, 1.0)
            
            for keyword in keywords:
                matches = text_lower.count(keyword.lower())
                if matches > 0:
                    score = level_weight * matches
                    total_score += score
                    total_matches += matches
                    evidence.append(f"{keyword}: {matches}次")
                    keywords_matched.append(keyword)
        
        if total_matches == 0:
            return None
        
        # 计算平均分数和等级
        avg_score = total_score / total_matches
        level = self._determine_competency_level(avg_score)
        confidence = min(1.0, total_matches / 10.0)  # 基于匹配数量计算置信度
        
        assessment_details = {
            "total_matches": total_matches,
            "avg_score": avg_score,
            "evidence_count": len(evidence),
            "keyword_count": len(keywords_matched)
        }
        
        return BusinessCompetency(
            competency_type=competency_type,
            level=level,
            score=avg_score,
            confidence=confidence,
            evidence=evidence,
            keywords_matched=keywords_matched,
            assessment_details=assessment_details
        )
    
    def _determine_competency_level(self, score: float) -> CompetencyLevel:
        """确定能力等级"""
        if score <= 1.0:
            return CompetencyLevel.BEGINNER
        elif score <= 2.0:
            return CompetencyLevel.INTERMEDIATE
        elif score <= 3.0:
            return CompetencyLevel.ADVANCED
        elif score <= 4.0:
            return CompetencyLevel.EXPERT
        else:
            return CompetencyLevel.MASTER
    
    async def calculate_overall_scores(self, technical_competencies: List[TechnicalCompetency], 
                                     business_competencies: List[BusinessCompetency]) -> Tuple[float, float, float]:
        """计算综合评分"""
        logger.info("开始计算综合评分")
        
        # 计算技术能力综合评分
        technical_score = 0.0
        technical_weight_sum = 0.0
        
        for competency in technical_competencies:
            weight = self.assessment_weights["technical"].get(competency.competency_type, 0.0)
            technical_score += competency.score * weight * competency.confidence
            technical_weight_sum += weight
        
        if technical_weight_sum > 0:
            technical_score = technical_score / technical_weight_sum
        
        # 计算业务能力综合评分
        business_score = 0.0
        business_weight_sum = 0.0
        
        for competency in business_competencies:
            weight = self.assessment_weights["business"].get(competency.competency_type, 0.0)
            business_score += competency.score * weight * competency.confidence
            business_weight_sum += weight
        
        if business_weight_sum > 0:
            business_score = business_score / business_weight_sum
        
        # 计算总体评分 (技术60% + 业务40%)
        overall_score = technical_score * 0.6 + business_score * 0.4
        
        logger.info("综合评分计算完成", 
                   technical_score=technical_score,
                   business_score=business_score,
                   overall_score=overall_score)
        
        return technical_score, business_score, overall_score
    
    async def generate_competency_profile(self, technical_competencies: List[TechnicalCompetency], 
                                        business_competencies: List[BusinessCompetency]) -> Dict[str, Any]:
        """生成能力画像"""
        logger.info("开始生成能力画像")
        
        profile = {
            "technical_strengths": [],
            "technical_weaknesses": [],
            "business_strengths": [],
            "business_weaknesses": [],
            "top_competencies": [],
            "development_areas": [],
            "competency_distribution": {
                "technical": {},
                "business": {}
            }
        }
        
        # 分析技术能力
        for competency in technical_competencies:
            if competency.level.value >= 4:  # Expert或Master
                profile["technical_strengths"].append({
                    "type": competency.competency_type.value,
                    "level": competency.level.value,
                    "score": competency.score
                })
            elif competency.level.value <= 2:  # Beginner或Intermediate
                profile["technical_weaknesses"].append({
                    "type": competency.competency_type.value,
                    "level": competency.level.value,
                    "score": competency.score
                })
            
            profile["competency_distribution"]["technical"][competency.competency_type.value] = {
                "level": competency.level.value,
                "score": competency.score
            }
        
        # 分析业务能力
        for competency in business_competencies:
            if competency.level.value >= 4:  # Expert或Master
                profile["business_strengths"].append({
                    "type": competency.competency_type.value,
                    "level": competency.level.value,
                    "score": competency.score
                })
            elif competency.level.value <= 2:  # Beginner或Intermediate
                profile["business_weaknesses"].append({
                    "type": competency.competency_type.value,
                    "level": competency.level.value,
                    "score": competency.score
                })
            
            profile["competency_distribution"]["business"][competency.competency_type.value] = {
                "level": competency.level.value,
                "score": competency.score
            }
        
        # 生成顶级能力
        all_competencies = []
        for competency in technical_competencies:
            all_competencies.append({
                "type": competency.competency_type.value,
                "category": "technical",
                "score": competency.score,
                "level": competency.level.value
            })
        for competency in business_competencies:
            all_competencies.append({
                "type": competency.competency_type.value,
                "category": "business",
                "score": competency.score,
                "level": competency.level.value
            })
        
        all_competencies.sort(key=lambda x: x["score"], reverse=True)
        profile["top_competencies"] = all_competencies[:5]
        
        # 生成发展建议
        profile["development_areas"] = profile["technical_weaknesses"] + profile["business_weaknesses"]
        
        logger.info("能力画像生成完成")
        return profile
    
    async def generate_growth_recommendations(self, technical_competencies: List[TechnicalCompetency], 
                                            business_competencies: List[BusinessCompetency]) -> List[str]:
        """生成成长建议"""
        logger.info("开始生成成长建议")
        
        recommendations = []
        
        # 基于技术能力生成建议
        for competency in technical_competencies:
            if competency.level.value <= 2:  # 需要提升的技术能力
                if competency.competency_type == TechnicalCompetencyType.PROGRAMMING:
                    recommendations.append("建议深入学习编程语言和设计模式，参与开源项目提升编程实践能力")
                elif competency.competency_type == TechnicalCompetencyType.ALGORITHM_DESIGN:
                    recommendations.append("建议系统学习数据结构和算法，通过刷题和算法竞赛提升算法设计能力")
                elif competency.competency_type == TechnicalCompetencyType.SYSTEM_ARCHITECTURE:
                    recommendations.append("建议学习系统设计原理，了解微服务和分布式架构设计")
                elif competency.competency_type == TechnicalCompetencyType.DATABASE_DESIGN:
                    recommendations.append("建议深入学习数据库原理和优化技术，掌握高级数据库特性")
                elif competency.competency_type == TechnicalCompetencyType.TESTING:
                    recommendations.append("建议学习自动化测试框架和测试策略，提升测试覆盖率")
                elif competency.competency_type == TechnicalCompetencyType.DEVOPS:
                    recommendations.append("建议学习容器技术和CI/CD流水线，掌握DevOps最佳实践")
                elif competency.competency_type == TechnicalCompetencyType.SECURITY:
                    recommendations.append("建议学习安全开发实践和安全架构设计")
                elif competency.competency_type == TechnicalCompetencyType.PERFORMANCE:
                    recommendations.append("建议学习性能优化技术和性能监控工具")
        
        # 基于业务能力生成建议
        for competency in business_competencies:
            if competency.level.value <= 2:  # 需要提升的业务能力
                if competency.competency_type == BusinessCompetencyType.REQUIREMENTS_ANALYSIS:
                    recommendations.append("建议学习需求分析方法论，提升业务需求理解和分析能力")
                elif competency.competency_type == BusinessCompetencyType.PROJECT_MANAGEMENT:
                    recommendations.append("建议学习项目管理知识体系，掌握项目规划和执行技能")
                elif competency.competency_type == BusinessCompetencyType.COMMUNICATION:
                    recommendations.append("建议提升沟通表达能力，学习技术文档编写和演示技巧")
                elif competency.competency_type == BusinessCompetencyType.PROBLEM_SOLVING:
                    recommendations.append("建议学习问题解决方法论，提升分析和解决复杂问题的能力")
                elif competency.competency_type == BusinessCompetencyType.TEAMWORK:
                    recommendations.append("建议提升团队协作能力，学习跨部门合作和冲突解决")
                elif competency.competency_type == BusinessCompetencyType.LEADERSHIP:
                    recommendations.append("建议学习领导力理论，提升团队管理和决策能力")
                elif competency.competency_type == BusinessCompetencyType.INNOVATION:
                    recommendations.append("建议培养创新思维，学习设计思维和创新方法")
                elif competency.competency_type == BusinessCompetencyType.BUSINESS_ACUMEN:
                    recommendations.append("建议学习商业知识，提升商业洞察和战略思维")
        
        # 去重并限制数量
        recommendations = list(set(recommendations))[:10]
        
        logger.info("成长建议生成完成", recommendations_count=len(recommendations))
        return recommendations
    
    async def assess_competency(self, text: str) -> CompetencyAssessment:
        """综合能力评估"""
        logger.info("开始综合能力评估", text_length=len(text))
        
        # 评估技术能力
        technical_competencies = await self.assess_technical_competency(text)
        
        # 评估业务能力
        business_competencies = await self.assess_business_competency(text)
        
        # 计算综合评分
        technical_score, business_score, overall_score = await self.calculate_overall_scores(
            technical_competencies, business_competencies
        )
        
        # 生成能力画像
        competency_profile = await self.generate_competency_profile(
            technical_competencies, business_competencies
        )
        
        # 生成成长建议
        growth_recommendations = await self.generate_growth_recommendations(
            technical_competencies, business_competencies
        )
        
        result = CompetencyAssessment(
            technical_competencies=technical_competencies,
            business_competencies=business_competencies,
            overall_technical_score=technical_score,
            overall_business_score=business_score,
            overall_score=overall_score,
            competency_profile=competency_profile,
            growth_recommendations=growth_recommendations
        )
        
        logger.info("综合能力评估完成", 
                   technical_competencies_count=len(technical_competencies),
                   business_competencies_count=len(business_competencies),
                   overall_score=overall_score)
        
        return result

# 创建全局实例
competency_engine = CompetencyAssessmentEngine()

async def main():
    """测试函数"""
    engine = CompetencyAssessmentEngine()
    
    # 测试技术能力评估
    test_text = """
    我是一名高级软件工程师，拥有8年的Java开发经验。
    精通Spring Boot、MyBatis、Redis等技术栈，熟悉微服务架构设计。
    具备丰富的系统架构经验，设计过大型分布式系统。
    熟练掌握MySQL数据库设计和优化，了解分库分表技术。
    具备完整的测试经验，包括单元测试、集成测试和性能测试。
    熟悉Docker容器技术和Kubernetes编排。
    了解安全开发实践，具备基础的性能优化经验。
    
    在业务方面，我具备良好的需求分析能力，能够准确理解业务需求。
    有项目管理经验，能够协调团队完成复杂项目。
    沟通能力强，能够与技术团队和业务团队有效协作。
    具备问题解决能力，能够快速定位和解决技术问题。
    有团队协作经验，能够带领团队完成项目目标。
    具备一定的领导力，能够指导初级开发人员。
    有创新思维，能够提出技术改进建议。
    了解商业知识，能够从商业角度思考技术方案。
    """
    
    # 综合能力评估
    assessment = await engine.assess_competency(test_text)
    
    print(f"综合能力评估结果:")
    print(f"  总体评分: {assessment.overall_score:.2f}")
    print(f"  技术能力评分: {assessment.overall_technical_score:.2f}")
    print(f"  业务能力评分: {assessment.overall_business_score:.2f}")
    
    print(f"\n技术能力评估:")
    for competency in assessment.technical_competencies:
        print(f"  {competency.competency_type.value}: {competency.level.value}级 (分数: {competency.score:.2f})")
    
    print(f"\n业务能力评估:")
    for competency in assessment.business_competencies:
        print(f"  {competency.competency_type.value}: {competency.level.value}级 (分数: {competency.score:.2f})")
    
    print(f"\n能力画像:")
    print(f"  技术优势: {len(assessment.competency_profile['technical_strengths'])}项")
    print(f"  业务优势: {len(assessment.competency_profile['business_strengths'])}项")
    print(f"  发展领域: {len(assessment.competency_profile['development_areas'])}项")
    
    print(f"\n成长建议:")
    for i, recommendation in enumerate(assessment.growth_recommendations, 1):
        print(f"  {i}. {recommendation}")

if __name__ == "__main__":
    asyncio.run(main())
