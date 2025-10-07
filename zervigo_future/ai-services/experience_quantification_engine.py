#!/usr/bin/env python3
"""
经验量化分析引擎
基于Workday经验量化模型，实现项目复杂度评估和成果量化提取
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

class ComplexityLevel(Enum):
    """复杂度等级枚举"""
    LOW = 1
    MEDIUM = 2
    HIGH = 3
    VERY_HIGH = 4
    EXTREME = 5

class AchievementType(Enum):
    """成果类型枚举"""
    PERFORMANCE = "performance"  # 性能提升
    EFFICIENCY = "efficiency"    # 效率提升
    COST_SAVING = "cost_saving"  # 成本节约
    REVENUE = "revenue"          # 收入增长
    USER_GROWTH = "user_growth"  # 用户增长
    QUALITY = "quality"          # 质量提升
    INNOVATION = "innovation"    # 创新成果
    TEAM = "team"               # 团队建设

@dataclass
class ProjectComplexity:
    """项目复杂度评估结果"""
    technical_complexity: float
    business_complexity: float
    team_complexity: float
    overall_complexity: float
    complexity_level: ComplexityLevel
    complexity_factors: Dict[str, float]

@dataclass
class QuantifiedAchievement:
    """量化成果"""
    achievement_type: AchievementType
    description: str
    metric: str
    value: float
    unit: str
    impact_score: float
    confidence: float

@dataclass
class ExperienceAnalysis:
    """经验分析结果"""
    project_complexity: ProjectComplexity
    achievements: List[QuantifiedAchievement]
    experience_score: float
    growth_trajectory: float
    leadership_indicators: Dict[str, float]

class ExperienceQuantificationEngine:
    """经验量化分析引擎"""
    
    def __init__(self):
        self.complexity_keywords = {
            "technical": {
                "low": ["simple", "basic", "straightforward", "routine", "standard"],
                "medium": ["moderate", "typical", "conventional", "established", "common"],
                "high": ["complex", "challenging", "advanced", "sophisticated", "intricate"],
                "very_high": ["highly complex", "cutting-edge", "innovative", "groundbreaking", "revolutionary"],
                "extreme": ["mission-critical", "enterprise-scale", "architectural", "system-wide", "transformational"]
            },
            "business": {
                "low": ["local", "department", "single team", "small scale", "internal"],
                "medium": ["cross-team", "multi-department", "regional", "medium scale", "business unit"],
                "high": ["company-wide", "strategic", "large scale", "multi-region", "organizational"],
                "very_high": ["global", "enterprise", "mission-critical", "transformational", "industry-leading"],
                "extreme": ["ecosystem", "paradigm-shifting", "market-defining", "industry-changing", "world-class"]
            },
            "team": {
                "low": ["individual", "solo", "single person", "independent", "self-contained"],
                "medium": ["small team", "2-5 people", "collaborative", "cooperative", "team-based"],
                "high": ["large team", "6-15 people", "multi-disciplinary", "cross-functional", "integrated"],
                "very_high": ["multiple teams", "16+ people", "distributed", "global team", "enterprise team"],
                "extreme": ["organization-wide", "hundreds of people", "ecosystem", "industry consortium", "global network"]
            }
        }
        
        self.achievement_patterns = {
            AchievementType.PERFORMANCE: [
                r"(\d+(?:\.\d+)?)\s*(?:x|倍|times|fold)",
                r"(\d+(?:\.\d+)?)\s*%?\s*(?:improvement|提升|improve|increase|增长)",
                r"(\d+(?:\.\d+)?)\s*%?\s*(?:faster|更快|speed up|加速)",
                r"(\d+(?:\.\d+)?)\s*%?\s*(?:reduction|减少|reduce|decrease|降低)"
            ],
            AchievementType.EFFICIENCY: [
                r"(\d+(?:\.\d+)?)\s*(?:hours?|小时|h|分钟|minutes?|min)",
                r"(\d+(?:\.\d+)?)\s*%?\s*(?:efficiency|效率|productivity|生产力)",
                r"(\d+(?:\.\d+)?)\s*(?:days?|天|weeks?|周|months?|月)",
                r"(\d+(?:\.\d+)?)\s*%?\s*(?:time|时间|duration|周期)"
            ],
            AchievementType.COST_SAVING: [
                r"(\d+(?:\.\d+)?)\s*(?:yuan|元|dollars?|\$|USD|CNY)",
                r"(\d+(?:\.\d+)?)\s*(?:million|万|billion|亿|thousand|千)",
                r"(\d+(?:\.\d+)?)\s*%?\s*(?:cost|成本|budget|预算|expense|费用)",
                r"(\d+(?:\.\d+)?)\s*%?\s*(?:saving|节约|save|reduction|减少)"
            ],
            AchievementType.REVENUE: [
                r"(\d+(?:\.\d+)?)\s*(?:million|万|billion|亿|thousand|千)",
                r"(\d+(?:\.\d+)?)\s*%?\s*(?:revenue|收入|sales|销售|growth|增长)",
                r"(\d+(?:\.\d+)?)\s*(?:yuan|元|dollars?|\$|USD|CNY)",
                r"(\d+(?:\.\d+)?)\s*%?\s*(?:increase|增加|rise|上升|boost|提升)"
            ],
            AchievementType.USER_GROWTH: [
                r"(\d+(?:\.\d+)?)\s*(?:users?|用户|customers?|客户|visitors?|访问者)",
                r"(\d+(?:\.\d+)?)\s*(?:million|万|billion|亿|thousand|千)",
                r"(\d+(?:\.\d+)?)\s*%?\s*(?:growth|增长|increase|增加|rise|上升)",
                r"(\d+(?:\.\d+)?)\s*%?\s*(?:adoption|采用|usage|使用|engagement|参与)"
            ],
            AchievementType.QUALITY: [
                r"(\d+(?:\.\d+)?)\s*%?\s*(?:quality|质量|reliability|可靠性|stability|稳定性)",
                r"(\d+(?:\.\d+)?)\s*(?:bugs?|缺陷|issues?|问题|errors?|错误)",
                r"(\d+(?:\.\d+)?)\s*%?\s*(?:defect|缺陷|bug|bug rate|缺陷率)",
                r"(\d+(?:\.\d+)?)\s*%?\s*(?:satisfaction|满意度|NPS|CSAT)"
            ],
            AchievementType.INNOVATION: [
                r"(\d+(?:\.\d+)?)\s*(?:patents?|专利|innovations?|创新|inventions?|发明)",
                r"(\d+(?:\.\d+)?)\s*(?:awards?|奖项|recognition|认可|achievements?|成就)",
                r"(\d+(?:\.\d+)?)\s*(?:publications?|论文|papers?|articles?|文章)",
                r"(\d+(?:\.\d+)?)\s*(?:features?|功能|capabilities?|能力|solutions?|解决方案)"
            ],
            AchievementType.TEAM: [
                r"(\d+(?:\.\d+)?)\s*(?:people|人|members?|成员|employees?|员工)",
                r"(\d+(?:\.\d+)?)\s*(?:teams?|团队|departments?|部门|groups?|组)",
                r"(\d+(?:\.\d+)?)\s*%?\s*(?:retention| retention|留存|retention rate|留存率)",
                r"(\d+(?:\.\d+)?)\s*(?:promotions?|晋升|promotions?|advancements?|提升)"
            ]
        }
        
        self.leadership_indicators = {
            "team_management": ["led", "managed", "supervised", "directed", "coordinated", "带领", "管理", "指导", "协调"],
            "project_leadership": ["project lead", "technical lead", "team lead", "项目负责人", "技术负责人", "团队负责人"],
            "mentoring": ["mentored", "trained", "coached", "guided", "指导", "培训", "教练", "引导"],
            "decision_making": ["decided", "determined", "chose", "selected", "决定", "确定", "选择", "决策"],
            "strategic_thinking": ["strategy", "strategic", "planning", "vision", "战略", "策略", "规划", "愿景"],
            "innovation": ["innovated", "created", "designed", "developed", "创新", "创造", "设计", "开发"]
        }
    
    async def analyze_project_complexity(self, project_description: str) -> ProjectComplexity:
        """分析项目复杂度"""
        logger.info("开始分析项目复杂度", project_length=len(project_description))
        
        # 技术复杂度评估
        technical_complexity = await self._assess_technical_complexity(project_description)
        
        # 业务复杂度评估
        business_complexity = await self._assess_business_complexity(project_description)
        
        # 团队复杂度评估
        team_complexity = await self._assess_team_complexity(project_description)
        
        # 综合复杂度计算
        overall_complexity = (technical_complexity * 0.4 + 
                             business_complexity * 0.35 + 
                             team_complexity * 0.25)
        
        # 确定复杂度等级
        complexity_level = self._determine_complexity_level(overall_complexity)
        
        # 提取复杂度因子
        complexity_factors = {
            "technical": technical_complexity,
            "business": business_complexity,
            "team": team_complexity,
            "overall": overall_complexity
        }
        
        result = ProjectComplexity(
            technical_complexity=technical_complexity,
            business_complexity=business_complexity,
            team_complexity=team_complexity,
            overall_complexity=overall_complexity,
            complexity_level=complexity_level,
            complexity_factors=complexity_factors
        )
        
        logger.info("项目复杂度分析完成", 
                   overall_complexity=overall_complexity,
                   complexity_level=complexity_level.value)
        
        return result
    
    async def _assess_technical_complexity(self, description: str) -> float:
        """评估技术复杂度"""
        description_lower = description.lower()
        complexity_score = 0.0
        total_matches = 0
        
        for level, keywords in self.complexity_keywords["technical"].items():
            level_weight = {
                "low": 1.0,
                "medium": 2.0,
                "high": 3.0,
                "very_high": 4.0,
                "extreme": 5.0
            }[level]
            
            for keyword in keywords:
                matches = description_lower.count(keyword.lower())
                if matches > 0:
                    complexity_score += level_weight * matches
                    total_matches += matches
        
        # 技术关键词权重调整
        tech_keywords = [
            "algorithm", "architecture", "scalability", "performance", "optimization",
            "distributed", "microservices", "machine learning", "ai", "blockchain",
            "algorithm", "架构", "可扩展性", "性能", "优化", "分布式", "微服务", "机器学习", "人工智能", "区块链"
        ]
        
        tech_keyword_matches = sum(1 for keyword in tech_keywords 
                                 if keyword.lower() in description_lower)
        complexity_score += tech_keyword_matches * 0.5
        
        # 技术栈复杂度评估
        advanced_tech = [
            "kubernetes", "docker", "aws", "azure", "gcp", "spark", "kafka",
            "elasticsearch", "redis", "mongodb", "postgresql", "mysql",
            "kubernetes", "docker", "云服务", "大数据", "消息队列", "搜索引擎", "缓存", "数据库"
        ]
        
        advanced_tech_matches = sum(1 for tech in advanced_tech 
                                  if tech.lower() in description_lower)
        complexity_score += advanced_tech_matches * 0.3
        
        # 归一化到0-5范围
        if total_matches > 0:
            complexity_score = min(5.0, complexity_score / total_matches)
        
        return round(complexity_score, 2)
    
    async def _assess_business_complexity(self, description: str) -> float:
        """评估业务复杂度"""
        description_lower = description.lower()
        complexity_score = 0.0
        total_matches = 0
        
        for level, keywords in self.complexity_keywords["business"].items():
            level_weight = {
                "low": 1.0,
                "medium": 2.0,
                "high": 3.0,
                "very_high": 4.0,
                "extreme": 5.0
            }[level]
            
            for keyword in keywords:
                matches = description_lower.count(keyword.lower())
                if matches > 0:
                    complexity_score += level_weight * matches
                    total_matches += matches
        
        # 业务关键词权重调整
        business_keywords = [
            "stakeholder", "requirements", "compliance", "regulation", "governance",
            "integration", "migration", "transformation", "digitalization",
            "利益相关者", "需求", "合规", "监管", "治理", "集成", "迁移", "转型", "数字化"
        ]
        
        business_keyword_matches = sum(1 for keyword in business_keywords 
                                     if keyword.lower() in description_lower)
        complexity_score += business_keyword_matches * 0.4
        
        # 归一化到0-5范围
        if total_matches > 0:
            complexity_score = min(5.0, complexity_score / total_matches)
        
        return round(complexity_score, 2)
    
    async def _assess_team_complexity(self, description: str) -> float:
        """评估团队复杂度"""
        description_lower = description.lower()
        complexity_score = 0.0
        total_matches = 0
        
        for level, keywords in self.complexity_keywords["team"].items():
            level_weight = {
                "low": 1.0,
                "medium": 2.0,
                "high": 3.0,
                "very_high": 4.0,
                "extreme": 5.0
            }[level]
            
            for keyword in keywords:
                matches = description_lower.count(keyword.lower())
                if matches > 0:
                    complexity_score += level_weight * matches
                    total_matches += matches
        
        # 团队关键词权重调整
        team_keywords = [
            "collaboration", "coordination", "communication", "cross-functional",
            "multi-disciplinary", "distributed", "remote", "agile", "scrum",
            "协作", "协调", "沟通", "跨职能", "多学科", "分布式", "远程", "敏捷", "scrum"
        ]
        
        team_keyword_matches = sum(1 for keyword in team_keywords 
                                 if keyword.lower() in description_lower)
        complexity_score += team_keyword_matches * 0.3
        
        # 归一化到0-5范围
        if total_matches > 0:
            complexity_score = min(5.0, complexity_score / total_matches)
        
        return round(complexity_score, 2)
    
    def _determine_complexity_level(self, complexity_score: float) -> ComplexityLevel:
        """确定复杂度等级"""
        if complexity_score <= 1.0:
            return ComplexityLevel.LOW
        elif complexity_score <= 2.0:
            return ComplexityLevel.MEDIUM
        elif complexity_score <= 3.0:
            return ComplexityLevel.HIGH
        elif complexity_score <= 4.0:
            return ComplexityLevel.VERY_HIGH
        else:
            return ComplexityLevel.EXTREME
    
    async def extract_quantified_achievements(self, experience_text: str) -> List[QuantifiedAchievement]:
        """提取量化成果"""
        logger.info("开始提取量化成果", text_length=len(experience_text))
        
        achievements = []
        
        for achievement_type, patterns in self.achievement_patterns.items():
            for pattern in patterns:
                matches = re.finditer(pattern, experience_text, re.IGNORECASE)
                for match in matches:
                    try:
                        value = float(match.group(1))
                        achievement = await self._create_achievement(
                            achievement_type, experience_text, match, value
                        )
                        if achievement:
                            achievements.append(achievement)
                    except (ValueError, IndexError):
                        continue
        
        # 去重和排序
        achievements = self._deduplicate_achievements(achievements)
        achievements.sort(key=lambda x: x.impact_score, reverse=True)
        
        logger.info("量化成果提取完成", achievements_count=len(achievements))
        return achievements
    
    async def _create_achievement(self, achievement_type: AchievementType, 
                                text: str, match, value: float) -> Optional[QuantifiedAchievement]:
        """创建成果对象"""
        # 获取匹配的上下文
        start = max(0, match.start() - 50)
        end = min(len(text), match.end() + 50)
        context = text[start:end]
        
        # 确定单位和描述
        unit, description = self._determine_unit_and_description(
            achievement_type, context, value
        )
        
        # 计算影响力评分
        impact_score = self._calculate_impact_score(achievement_type, value, unit)
        
        # 计算置信度
        confidence = self._calculate_confidence(context, achievement_type)
        
        if confidence < 0.3:  # 置信度太低，跳过
            return None
        
        return QuantifiedAchievement(
            achievement_type=achievement_type,
            description=description,
            metric=match.group(0),
            value=value,
            unit=unit,
            impact_score=impact_score,
            confidence=confidence
        )
    
    def _determine_unit_and_description(self, achievement_type: AchievementType, 
                                      context: str, value: float) -> Tuple[str, str]:
        """确定单位和描述"""
        context_lower = context.lower()
        
        if achievement_type == AchievementType.PERFORMANCE:
            if "%" in context:
                unit = "%"
                description = f"性能提升{value}%"
            elif any(word in context_lower for word in ["x", "倍", "times", "fold"]):
                unit = "倍"
                description = f"性能提升{value}倍"
            else:
                unit = "单位"
                description = f"性能提升{value}单位"
        
        elif achievement_type == AchievementType.EFFICIENCY:
            if any(word in context_lower for word in ["hour", "小时", "h"]):
                unit = "小时"
                description = f"效率提升{value}小时"
            elif any(word in context_lower for word in ["day", "天"]):
                unit = "天"
                description = f"效率提升{value}天"
            elif "%" in context:
                unit = "%"
                description = f"效率提升{value}%"
            else:
                unit = "单位"
                description = f"效率提升{value}单位"
        
        elif achievement_type == AchievementType.COST_SAVING:
            if any(word in context_lower for word in ["yuan", "元", "rmb"]):
                unit = "元"
                description = f"成本节约{value}元"
            elif any(word in context_lower for word in ["dollar", "美元", "$"]):
                unit = "美元"
                description = f"成本节约{value}美元"
            elif any(word in context_lower for word in ["million", "万", "million"]):
                unit = "万元"
                description = f"成本节约{value}万元"
            else:
                unit = "单位"
                description = f"成本节约{value}单位"
        
        elif achievement_type == AchievementType.REVENUE:
            if any(word in context_lower for word in ["million", "万", "million"]):
                unit = "万元"
                description = f"收入增长{value}万元"
            elif "%" in context:
                unit = "%"
                description = f"收入增长{value}%"
            else:
                unit = "单位"
                description = f"收入增长{value}单位"
        
        elif achievement_type == AchievementType.USER_GROWTH:
            if any(word in context_lower for word in ["million", "万", "million"]):
                unit = "万用户"
                description = f"用户增长{value}万"
            elif "%" in context:
                unit = "%"
                description = f"用户增长{value}%"
            else:
                unit = "用户"
                description = f"用户增长{value}人"
        
        elif achievement_type == AchievementType.QUALITY:
            if "%" in context:
                unit = "%"
                description = f"质量提升{value}%"
            else:
                unit = "单位"
                description = f"质量提升{value}单位"
        
        elif achievement_type == AchievementType.INNOVATION:
            unit = "项"
            description = f"创新成果{value}项"
        
        elif achievement_type == AchievementType.TEAM:
            unit = "人"
            description = f"团队规模{value}人"
        
        else:
            unit = "单位"
            description = f"成果{value}单位"
        
        return unit, description
    
    def _calculate_impact_score(self, achievement_type: AchievementType, 
                               value: float, unit: str) -> float:
        """计算影响力评分"""
        base_score = value
        
        # 根据成果类型调整权重
        type_weights = {
            AchievementType.PERFORMANCE: 1.0,
            AchievementType.EFFICIENCY: 0.9,
            AchievementType.COST_SAVING: 1.2,
            AchievementType.REVENUE: 1.3,
            AchievementType.USER_GROWTH: 1.1,
            AchievementType.QUALITY: 0.8,
            AchievementType.INNOVATION: 1.4,
            AchievementType.TEAM: 0.7
        }
        
        # 根据单位调整权重
        unit_weights = {
            "%": 0.1,
            "倍": 2.0,
            "万": 10.0,
            "万用户": 15.0,
            "万元": 12.0,
            "亿美元": 100.0,
            "小时": 0.01,
            "天": 0.1,
            "人": 1.0,
            "项": 2.0
        }
        
        weight = type_weights.get(achievement_type, 1.0) * unit_weights.get(unit, 1.0)
        impact_score = base_score * weight
        
        # 归一化到0-100范围
        return min(100.0, max(0.0, impact_score))
    
    def _calculate_confidence(self, context: str, achievement_type: AchievementType) -> float:
        """计算置信度"""
        context_lower = context.lower()
        confidence = 0.5  # 基础置信度
        
        # 正相关词汇增加置信度
        positive_words = [
            "achieved", "accomplished", "delivered", "completed", "successfully",
            "实现", "完成", "达成", "成功", "交付"
        ]
        
        for word in positive_words:
            if word in context_lower:
                confidence += 0.1
        
        # 具体数据增加置信度
        if any(char.isdigit() for char in context):
            confidence += 0.2
        
        # 时间范围增加置信度
        time_words = ["year", "month", "quarter", "年", "月", "季度", "期间"]
        for word in time_words:
            if word in context_lower:
                confidence += 0.1
        
        return min(1.0, confidence)
    
    def _deduplicate_achievements(self, achievements: List[QuantifiedAchievement]) -> List[QuantifiedAchievement]:
        """去重成果"""
        seen = set()
        unique_achievements = []
        
        for achievement in achievements:
            key = (achievement.achievement_type, achievement.metric)
            if key not in seen:
                seen.add(key)
                unique_achievements.append(achievement)
        
        return unique_achievements
    
    async def analyze_leadership_indicators(self, experience_text: str) -> Dict[str, float]:
        """分析领导力指标"""
        logger.info("开始分析领导力指标")
        
        indicators = {}
        text_lower = experience_text.lower()
        
        for indicator_type, keywords in self.leadership_indicators.items():
            score = 0.0
            for keyword in keywords:
                score += text_lower.count(keyword.lower())
            
            # 归一化到0-1范围
            indicators[indicator_type] = min(1.0, score / 10.0)
        
        logger.info("领导力指标分析完成", indicators_count=len(indicators))
        return indicators
    
    async def calculate_experience_score(self, complexity: ProjectComplexity, 
                                       achievements: List[QuantifiedAchievement],
                                       leadership: Dict[str, float]) -> float:
        """计算经验评分"""
        logger.info("开始计算经验评分")
        
        # 复杂度评分 (0-50分)
        complexity_score = complexity.overall_complexity * 10
        
        # 成果评分 (0-30分)
        achievement_score = 0.0
        if achievements:
            total_impact = sum(achievement.impact_score for achievement in achievements)
            achievement_score = min(30.0, total_impact / len(achievements))
        
        # 领导力评分 (0-20分)
        leadership_score = sum(leadership.values()) * 20 / len(leadership)
        
        # 综合评分
        experience_score = complexity_score + achievement_score + leadership_score
        
        logger.info("经验评分计算完成", 
                   complexity_score=complexity_score,
                   achievement_score=achievement_score,
                   leadership_score=leadership_score,
                   total_score=experience_score)
        
        return round(experience_score, 2)
    
    async def analyze_growth_trajectory(self, experiences: List[str]) -> float:
        """分析成长轨迹"""
        if len(experiences) < 2:
            return 0.5
        
        scores = []
        for experience in experiences:
            complexity = await self.analyze_project_complexity(experience)
            achievements = await self.extract_quantified_achievements(experience)
            leadership = await self.analyze_leadership_indicators(experience)
            score = await self.calculate_experience_score(complexity, achievements, leadership)
            scores.append(score)
        
        # 计算成长趋势
        if len(scores) >= 2:
            growth_rate = (scores[-1] - scores[0]) / len(scores)
            return min(1.0, max(0.0, (growth_rate + 50) / 100))
        
        return 0.5
    
    async def analyze_experience(self, experience_text: str) -> ExperienceAnalysis:
        """综合分析经验"""
        logger.info("开始综合分析经验", text_length=len(experience_text))
        
        # 项目复杂度分析
        complexity = await self.analyze_project_complexity(experience_text)
        
        # 量化成果提取
        achievements = await self.extract_quantified_achievements(experience_text)
        
        # 领导力指标分析
        leadership = await self.analyze_leadership_indicators(experience_text)
        
        # 经验评分计算
        experience_score = await self.calculate_experience_score(complexity, achievements, leadership)
        
        # 成长轨迹分析 (单次经验设为中等)
        growth_trajectory = 0.5
        
        result = ExperienceAnalysis(
            project_complexity=complexity,
            achievements=achievements,
            experience_score=experience_score,
            growth_trajectory=growth_trajectory,
            leadership_indicators=leadership
        )
        
        logger.info("经验分析完成", 
                   experience_score=experience_score,
                   achievements_count=len(achievements),
                   complexity_level=complexity.complexity_level.value)
        
        return result

# 创建全局实例
experience_engine = ExperienceQuantificationEngine()

async def main():
    """测试函数"""
    engine = ExperienceQuantificationEngine()
    
    # 测试项目复杂度分析
    test_project = """
    负责设计并实现了一个大规模分布式推荐系统，使用Go语言和Kubernetes进行开发。
    该项目涉及多个团队协作，包括算法团队、后端团队、前端团队和数据团队。
    系统需要处理千万级用户的实时推荐请求，支持多种推荐算法，
    并实现了A/B测试框架。项目采用了微服务架构，使用了Redis、MongoDB、Elasticsearch等技术栈。
    通过优化算法和架构，系统性能提升了3倍，用户点击率增长了25%，
    为公司带来了500万元的收入增长。团队规模从5人扩展到15人，
    我负责技术架构设计和团队管理。
    """
    
    # 分析项目复杂度
    complexity = await engine.analyze_project_complexity(test_project)
    print(f"项目复杂度分析:")
    print(f"  技术复杂度: {complexity.technical_complexity}")
    print(f"  业务复杂度: {complexity.business_complexity}")
    print(f"  团队复杂度: {complexity.team_complexity}")
    print(f"  整体复杂度: {complexity.overall_complexity}")
    print(f"  复杂度等级: {complexity.complexity_level.value}")
    
    # 提取量化成果
    achievements = await engine.extract_quantified_achievements(test_project)
    print(f"\n量化成果提取:")
    for achievement in achievements:
        print(f"  {achievement.achievement_type.value}: {achievement.description} "
              f"(影响力: {achievement.impact_score:.1f}, 置信度: {achievement.confidence:.2f})")
    
    # 分析领导力指标
    leadership = await engine.analyze_leadership_indicators(test_project)
    print(f"\n领导力指标:")
    for indicator, score in leadership.items():
        print(f"  {indicator}: {score:.2f}")
    
    # 综合分析
    analysis = await engine.analyze_experience(test_project)
    print(f"\n综合分析结果:")
    print(f"  经验评分: {analysis.experience_score}")
    print(f"  成长轨迹: {analysis.growth_trajectory}")

if __name__ == "__main__":
    asyncio.run(main())
