#!/usr/bin/env python3
"""
MBTI花语花卉人格映射系统
创建时间: 2025年10月4日
版本: v1.5 (华中师范大学创新版)
基于: 华中师范大学植物拟人化设计 + 花语花卉知识
目标: 实现MBTI类型与花卉的智能映射，适应新生代个性化需求
"""

from typing import Dict, List, Optional, Any, Tuple
from dataclasses import dataclass, asdict
from enum import Enum
import json
import re
from datetime import datetime


# ==================== 花卉分类枚举 ====================

class FlowerCategory(str, Enum):
    """花卉分类枚举"""
    ROSE = "rose"           # 玫瑰类
    CHRYSANTHEMUM = "chrysanthemum"  # 菊花类
    LILY = "lily"           # 百合类
    TULIP = "tulip"         # 郁金香类
    SUNFLOWER = "sunflower" # 向日葵类
    LAVENDER = "lavender"   # 薰衣草类
    POPPY = "poppy"         # 罂粟类
    VIOLET = "violet"       # 紫罗兰类
    CARNATION = "carnation" # 康乃馨类
    CHERRY_BLOSSOM = "cherry_blossom"  # 樱花类


class FlowerColor(str, Enum):
    """花卉颜色枚举"""
    RED = "red"         # 红色
    PINK = "pink"       # 粉色
    YELLOW = "yellow"   # 黄色
    ORANGE = "orange"   # 橙色
    PURPLE = "purple"   # 紫色
    BLUE = "blue"       # 蓝色
    WHITE = "white"     # 白色
    MIXED = "mixed"     # 混合色


class PersonalityTrait(str, Enum):
    """人格特征枚举"""
    # 外向相关
    OUTGOING = "outgoing"           # 外向
    ENTHUSIASTIC = "enthusiastic"   # 热情
    SOCIAL = "social"              # 社交
    ENERGETIC = "energetic"        # 活力
    
    # 内向相关
    INTROSPECTIVE = "introspective" # 内省
    THOUGHTFUL = "thoughtful"       # 深思
    INDEPENDENT = "independent"     # 独立
    CALM = "calm"                  # 冷静
    
    # 感觉相关
    PRACTICAL = "practical"        # 务实
    DETAILED = "detailed"          # 细致
    REALISTIC = "realistic"       # 现实
    RELIABLE = "reliable"         # 可靠
    
    # 直觉相关
    CREATIVE = "creative"          # 创新
    VISIONARY = "visionary"       # 远见
    ABSTRACT = "abstract"         # 抽象
    INSPIRATIONAL = "inspirational" # 启发
    
    # 思考相关
    LOGICAL = "logical"           # 逻辑
    ANALYTICAL = "analytical"     # 分析
    OBJECTIVE = "objective"       # 客观
    DECISIVE = "decisive"         # 决断
    
    # 情感相关
    EMPATHETIC = "empathetic"     # 同理
    COMPASSIONATE = "compassionate" # 同情
    WARM = "warm"                 # 温暖
    CARING = "caring"             # 关爱
    
    # 判断相关
    ORGANIZED = "organized"       # 有序
    PLANNED = "planned"          # 计划
    STRUCTURED = "structured"    # 结构化
    DISCIPLINED = "disciplined"  # 自律
    
    # 感知相关
    FLEXIBLE = "flexible"        # 灵活
    ADAPTIVE = "adaptive"        # 适应
    SPONTANEOUS = "spontaneous"  # 自发
    OPEN = "open"                # 开放


# ==================== 数据模型 ====================

@dataclass
class FlowerInfo:
    """花卉信息"""
    flower_id: int
    flower_name: str
    flower_scientific_name: str
    flower_category: FlowerCategory
    flower_color: FlowerColor
    flower_season: str
    flower_origin: str
    flower_meaning: str
    flower_description: str
    personality_traits: List[PersonalityTrait]
    cultural_significance: str
    care_requirements: str
    blooming_period: str
    
    def to_dict(self) -> Dict[str, Any]:
        result = asdict(self)
        result['personality_traits'] = [trait.value for trait in self.personality_traits]
        return result


@dataclass
class MBTIFlowerMapping:
    """MBTI类型与花卉映射"""
    mbti_type: str
    flower_info: FlowerInfo
    mapping_strength: float  # 映射强度 (0-1)
    mapping_reason: str
    personality_alignment: Dict[str, float]  # 人格特征对齐度
    cultural_relevance: float  # 文化相关性
    seasonal_relevance: float  # 季节相关性
    color_psychology: float   # 色彩心理学相关性
    is_primary: bool
    alternative_flowers: List[str]  # 替代花卉
    
    def to_dict(self) -> Dict[str, Any]:
        result = asdict(self)
        result['flower_info'] = self.flower_info.to_dict()
        return result


@dataclass
class FlowerPersonalityAnalysis:
    """花卉人格分析"""
    mbti_type: str
    primary_flower: MBTIFlowerMapping
    secondary_flowers: List[MBTIFlowerMapping]
    personality_insights: Dict[str, Any]
    growth_suggestions: List[str]
    career_implications: List[str]
    relationship_advice: List[str]
    seasonal_recommendations: Dict[str, str]
    
    def to_dict(self) -> Dict[str, Any]:
        result = asdict(self)
        result['primary_flower'] = self.primary_flower.to_dict()
        result['secondary_flowers'] = [flower.to_dict() for flower in self.secondary_flowers]
        return result


# ==================== 华中师范大学创新元素 ====================

class HZUNFlowerPersonalitySystem:
    """华中师范大学花卉人格化系统"""
    
    def __init__(self):
        self.flower_database = self._initialize_flower_database()
        self.mbti_flower_mappings = self._initialize_mbti_flower_mappings()
        self.hzun_innovation_elements = self._initialize_hzun_elements()
    
    def _initialize_flower_database(self) -> Dict[int, FlowerInfo]:
        """初始化花卉数据库"""
        flowers = {}
        
        # 基于华中师范大学植物拟人化设计的核心花卉
        flowers[1] = FlowerInfo(
            flower_id=1,
            flower_name="白色菊花",
            flower_scientific_name="Chrysanthemum morifolium",
            flower_category=FlowerCategory.CHRYSANTHEMUM,
            flower_color=FlowerColor.WHITE,
            flower_season="秋季",
            flower_origin="中国",
            flower_meaning="务实、坚韧、可靠",
            flower_description="白色菊花象征着务实和可靠，如同ISTJ型人格的稳重特质",
            personality_traits=[
                PersonalityTrait.PRACTICAL,
                PersonalityTrait.RELIABLE,
                PersonalityTrait.ORGANIZED,
                PersonalityTrait.DISCIPLINED
            ],
            cultural_significance="在中国文化中，白色菊花代表纯洁和坚韧，象征不屈不挠的精神",
            care_requirements="需要充足的阳光和排水良好的土壤",
            blooming_period="9-11月"
        )
        
        flowers[2] = FlowerInfo(
            flower_id=2,
            flower_name="紫色菊花",
            flower_scientific_name="Chrysanthemum indicum",
            flower_category=FlowerCategory.CHRYSANTHEMUM,
            flower_color=FlowerColor.PURPLE,
            flower_season="秋季",
            flower_origin="中国",
            flower_meaning="智慧、独立、创新",
            flower_description="紫色菊花代表智慧和创新，如同INTP型人格的独立思考",
            personality_traits=[
                PersonalityTrait.INTROSPECTIVE,
                PersonalityTrait.CREATIVE,
                PersonalityTrait.INDEPENDENT,
                PersonalityTrait.ANALYTICAL
            ],
            cultural_significance="紫色在东方文化中象征智慧和神秘，代表深度的思考",
            care_requirements="需要适中的光照和湿润的土壤",
            blooming_period="9-11月"
        )
        
        flowers[3] = FlowerInfo(
            flower_id=3,
            flower_name="红色菊花",
            flower_scientific_name="Chrysanthemum morifolium",
            flower_category=FlowerCategory.CHRYSANTHEMUM,
            flower_color=FlowerColor.RED,
            flower_season="秋季",
            flower_origin="中国",
            flower_meaning="热情、创造力、活力",
            flower_description="红色菊花代表热情和活力，如同ENFP型人格的创造力",
            personality_traits=[
                PersonalityTrait.ENTHUSIASTIC,
                PersonalityTrait.CREATIVE,
                PersonalityTrait.ENERGETIC,
                PersonalityTrait.INSPIRATIONAL
            ],
            cultural_significance="红色在中国文化中象征热情和活力，代表积极向上的精神",
            care_requirements="需要充足的阳光和肥沃的土壤",
            blooming_period="9-11月"
        )
        
        flowers[4] = FlowerInfo(
            flower_id=4,
            flower_name="黄色菊花",
            flower_scientific_name="Chrysanthemum morifolium",
            flower_category=FlowerCategory.CHRYSANTHEMUM,
            flower_color=FlowerColor.YELLOW,
            flower_season="秋季",
            flower_origin="中国",
            flower_meaning="外向、热情、社交",
            flower_description="黄色菊花代表外向和社交，如同ESFP型人格的社交能力",
            personality_traits=[
                PersonalityTrait.OUTGOING,
                PersonalityTrait.SOCIAL,
                PersonalityTrait.ENERGETIC,
                PersonalityTrait.WARM
            ],
            cultural_significance="黄色象征阳光和快乐，代表积极乐观的人生态度",
            care_requirements="需要充足的阳光和排水良好的土壤",
            blooming_period="9-11月"
        )
        
        # 扩展花卉数据库
        flowers[5] = FlowerInfo(
            flower_id=5,
            flower_name="红玫瑰",
            flower_scientific_name="Rosa rubiginosa",
            flower_category=FlowerCategory.ROSE,
            flower_color=FlowerColor.RED,
            flower_season="全年",
            flower_origin="亚洲",
            flower_meaning="领导力、热情、决心",
            flower_description="红玫瑰象征着领导力和决心，如同ENTJ型人格的强势领导",
            personality_traits=[
                PersonalityTrait.DECISIVE,
                PersonalityTrait.ENTHUSIASTIC,
                PersonalityTrait.ORGANIZED,
                PersonalityTrait.INSPIRATIONAL
            ],
            cultural_significance="玫瑰在西方文化中象征爱情和美丽，代表强烈的感情和决心",
            care_requirements="需要充足的阳光和排水良好的土壤",
            blooming_period="5-10月"
        )
        
        flowers[6] = FlowerInfo(
            flower_id=6,
            flower_name="向日葵",
            flower_scientific_name="Helianthus annuus",
            flower_category=FlowerCategory.SUNFLOWER,
            flower_color=FlowerColor.YELLOW,
            flower_season="夏季",
            flower_origin="北美",
            flower_meaning="乐观、创新、活力",
            flower_description="向日葵代表乐观和活力，如同ENTP型人格的创新精神",
            personality_traits=[
                PersonalityTrait.ENTHUSIASTIC,
                PersonalityTrait.CREATIVE,
                PersonalityTrait.ENERGETIC,
                PersonalityTrait.INSPIRATIONAL
            ],
            cultural_significance="向日葵象征阳光和希望，代表积极向上的生活态度",
            care_requirements="需要充足的阳光和肥沃的土壤",
            blooming_period="7-9月"
        )
        
        return flowers
    
    def _initialize_mbti_flower_mappings(self) -> Dict[str, MBTIFlowerMapping]:
        """初始化MBTI类型与花卉映射"""
        mappings = {}
        
        # ISTJ - 白色菊花
        mappings["ISTJ"] = MBTIFlowerMapping(
            mbti_type="ISTJ",
            flower_info=self.flower_database[1],
            mapping_strength=1.00,
            mapping_reason="ISTJ型人格的务实、坚韧、可靠特质与白色菊花的象征意义完美匹配",
            personality_alignment={
                "practical": 0.95,
                "reliable": 0.98,
                "organized": 0.92,
                "disciplined": 0.90
            },
            cultural_relevance=0.95,
            seasonal_relevance=0.90,
            color_psychology=0.88,
            is_primary=True,
            alternative_flowers=["白色百合", "白色康乃馨"]
        )
        
        # INTP - 紫色菊花
        mappings["INTP"] = MBTIFlowerMapping(
            mbti_type="INTP",
            flower_info=self.flower_database[2],
            mapping_strength=1.00,
            mapping_reason="INTP型人格的智慧、独立、创新特质与紫色菊花的象征意义完美匹配",
            personality_alignment={
                "introspective": 0.95,
                "creative": 0.92,
                "independent": 0.98,
                "analytical": 0.94
            },
            cultural_relevance=0.93,
            seasonal_relevance=0.88,
            color_psychology=0.91,
            is_primary=True,
            alternative_flowers=["紫色薰衣草", "紫罗兰"]
        )
        
        # ENFP - 红色菊花
        mappings["ENFP"] = MBTIFlowerMapping(
            mbti_type="ENFP",
            flower_info=self.flower_database[3],
            mapping_strength=1.00,
            mapping_reason="ENFP型人格的热情、创造力、活力特质与红色菊花的象征意义完美匹配",
            personality_alignment={
                "enthusiastic": 0.96,
                "creative": 0.94,
                "energetic": 0.97,
                "inspirational": 0.93
            },
            cultural_relevance=0.94,
            seasonal_relevance=0.89,
            color_psychology=0.92,
            is_primary=True,
            alternative_flowers=["红玫瑰", "红色郁金香"]
        )
        
        # ESFP - 黄色菊花
        mappings["ESFP"] = MBTIFlowerMapping(
            mbti_type="ESFP",
            flower_info=self.flower_database[4],
            mapping_strength=1.00,
            mapping_reason="ESFP型人格的外向、热情、社交特质与黄色菊花的象征意义完美匹配",
            personality_alignment={
                "outgoing": 0.95,
                "social": 0.97,
                "energetic": 0.94,
                "warm": 0.92
            },
            cultural_relevance=0.91,
            seasonal_relevance=0.87,
            color_psychology=0.89,
            is_primary=True,
            alternative_flowers=["向日葵", "黄色郁金香"]
        )
        
        # ENTJ - 红玫瑰
        mappings["ENTJ"] = MBTIFlowerMapping(
            mbti_type="ENTJ",
            flower_info=self.flower_database[5],
            mapping_strength=0.98,
            mapping_reason="ENTJ型人格的领导力、热情、决心特质与红玫瑰的象征意义高度匹配",
            personality_alignment={
                "decisive": 0.96,
                "enthusiastic": 0.93,
                "organized": 0.91,
                "inspirational": 0.95
            },
            cultural_relevance=0.97,
            seasonal_relevance=0.85,
            color_psychology=0.94,
            is_primary=True,
            alternative_flowers=["红色菊花", "红色郁金香"]
        )
        
        # ENTP - 向日葵
        mappings["ENTP"] = MBTIFlowerMapping(
            mbti_type="ENTP",
            flower_info=self.flower_database[6],
            mapping_strength=0.97,
            mapping_reason="ENTP型人格的乐观、创新、活力特质与向日葵的象征意义高度匹配",
            personality_alignment={
                "enthusiastic": 0.94,
                "creative": 0.96,
                "energetic": 0.95,
                "inspirational": 0.92
            },
            cultural_relevance=0.89,
            seasonal_relevance=0.92,
            color_psychology=0.90,
            is_primary=True,
            alternative_flowers=["黄色菊花", "黄色郁金香"]
        )
        
        return mappings
    
    def _initialize_hzun_elements(self) -> Dict[str, Any]:
        """初始化华中师范大学创新元素"""
        return {
            "plant_personification": {
                "白色菊花": {"personality": "ISTJ", "traits": ["务实", "坚韧", "可靠"]},
                "紫色菊花": {"personality": "INTP", "traits": ["智慧", "独立", "创新"]},
                "红色菊花": {"personality": "ENFP", "traits": ["热情", "创造力", "活力"]},
                "黄色菊花": {"personality": "ESFP", "traits": ["外向", "热情", "社交"]}
            },
            "academic_integration": {
                "psychology_department": "心理学院MBTI十六型人格科普教育",
                "law_department": "法学院与心理学院联合'知心懂法'分享会",
                "campus_application": "校园植物拟人化设计应用"
            },
            "career_assessment": {
                "mbti_test": "MBTI职业性格测试(93题)",
                "holland_test": "霍兰德职业兴趣测试",
                "cattell_test": "卡特尔16PF人格测试(187题)"
            }
        }
    
    def get_flower_personality_analysis(self, mbti_type: str) -> Optional[FlowerPersonalityAnalysis]:
        """获取花卉人格分析"""
        if mbti_type not in self.mbti_flower_mappings:
            return None
        
        primary_mapping = self.mbti_flower_mappings[mbti_type]
        
        # 获取次要花卉映射
        secondary_flowers = []
        for alt_flower in primary_mapping.alternative_flowers:
            # 这里可以扩展查找替代花卉的逻辑
            pass
        
        # 生成人格洞察
        personality_insights = self._generate_personality_insights(mbti_type, primary_mapping)
        
        # 生成成长建议
        growth_suggestions = self._generate_growth_suggestions(mbti_type, primary_mapping)
        
        # 生成职业建议
        career_implications = self._generate_career_implications(mbti_type, primary_mapping)
        
        # 生成关系建议
        relationship_advice = self._generate_relationship_advice(mbti_type, primary_mapping)
        
        # 生成季节建议
        seasonal_recommendations = self._generate_seasonal_recommendations(primary_mapping)
        
        return FlowerPersonalityAnalysis(
            mbti_type=mbti_type,
            primary_flower=primary_mapping,
            secondary_flowers=secondary_flowers,
            personality_insights=personality_insights,
            growth_suggestions=growth_suggestions,
            career_implications=career_implications,
            relationship_advice=relationship_advice,
            seasonal_recommendations=seasonal_recommendations
        )
    
    def _generate_personality_insights(self, mbti_type: str, mapping: MBTIFlowerMapping) -> Dict[str, Any]:
        """生成人格洞察"""
        return {
            "core_traits": list(mapping.personality_alignment.keys()),
            "strength_analysis": {
                "strongest_trait": max(mapping.personality_alignment.items(), key=lambda x: x[1]),
                "balanced_traits": [k for k, v in mapping.personality_alignment.items() if v > 0.9]
            },
            "flower_symbolism": {
                "meaning": mapping.flower_info.flower_meaning,
                "cultural_significance": mapping.flower_info.cultural_significance,
                "color_psychology": f"{mapping.flower_info.flower_color.value}色代表{mapping.flower_info.flower_meaning}"
            },
            "personality_metaphor": f"您就像{mapping.flower_info.flower_name}一样，{mapping.flower_info.flower_description}"
        }
    
    def _generate_growth_suggestions(self, mbti_type: str, mapping: MBTIFlowerMapping) -> List[str]:
        """生成成长建议"""
        suggestions = []
        
        # 基于花卉特性的成长建议
        if mapping.flower_info.flower_category == FlowerCategory.CHRYSANTHEMUM:
            suggestions.extend([
                "学习菊花的坚韧品质，在困难面前保持不屈不挠的精神",
                "培养菊花的务实特质，注重实际效果和长期规划",
                "学习菊花的适应能力，在不同季节都能绽放美丽"
            ])
        
        # 基于MBTI类型的成长建议
        if mbti_type.startswith("I"):
            suggestions.append("学习外向型花卉的社交技巧，适当增加人际交往")
        elif mbti_type.startswith("E"):
            suggestions.append("学习内向型花卉的深度思考，适当增加独处时间")
        
        return suggestions
    
    def _generate_career_implications(self, mbti_type: str, mapping: MBTIFlowerMapping) -> List[str]:
        """生成职业建议"""
        career_suggestions = []
        
        # 基于花卉特性的职业建议
        if "菊花" in mapping.flower_info.flower_name:
            career_suggestions.extend([
                "适合需要耐心和毅力的职业，如教育、医疗、科研",
                "可以考虑与植物、园艺相关的职业",
                "适合需要务实态度的管理岗位"
            ])
        
        return career_suggestions
    
    def _generate_relationship_advice(self, mbti_type: str, mapping: MBTIFlowerMapping) -> List[str]:
        """生成关系建议"""
        relationship_advice = []
        
        # 基于花卉特性的关系建议
        if mapping.flower_info.flower_color == FlowerColor.WHITE:
            relationship_advice.append("在关系中保持纯洁和真诚，建立信任基础")
        elif mapping.flower_info.flower_color == FlowerColor.RED:
            relationship_advice.append("在关系中保持热情和活力，营造积极氛围")
        
        return relationship_advice
    
    def _generate_seasonal_recommendations(self, mapping: MBTIFlowerMapping) -> Dict[str, str]:
        """生成季节建议"""
        return {
            "spring": f"春季是{mapping.flower_info.flower_name}的生长季节，适合新的开始",
            "summer": f"夏季是{mapping.flower_info.flower_name}的旺盛期，适合积极行动",
            "autumn": f"秋季是{mapping.flower_info.flower_name}的收获期，适合总结反思",
            "winter": f"冬季是{mapping.flower_info.flower_name}的休眠期，适合内省规划"
        }
    
    def analyze_user_text(self, user_text: str) -> Dict[str, Any]:
        """分析用户文本中的MBTI表达 - 基于微博用户MBTI类型识别技术"""
        # 基于学习成果的正则表达式方法
        mbti_pattern = r'(?:infj|entp|intp|intj|entj|enfj|infp|enfp|isfp|istp|isfj|istj|estp|esfp|estj|esfj)'
        mbti_matches = re.findall(mbti_pattern, user_text.lower())
        
        # 提取上下文 - 基于学习成果的上下文窗口提取
        context_pattern = r"(.{0,10}(?:infj|entp|intp|intj|entj|enfj|infp|enfp|isfp|istp|isfj|istj|estp|esfp|estj|esfj).{0,10})"
        context_matches = re.findall(context_pattern, user_text.lower())
        
        # 分析用户表达习惯
        expression_analysis = self._analyze_expression_patterns(context_matches)
        
        return {
            "mbti_types_found": list(set(mbti_matches)),
            "contexts": context_matches,
            "expression_analysis": expression_analysis,
            "analysis": {
                "total_mbti_mentions": len(mbti_matches),
                "unique_types": len(set(mbti_matches)),
                "confidence": min(len(mbti_matches) / 3.0, 1.0),  # 基于提及次数计算置信度
                "user_language_style": self._classify_user_language_style(user_text)
            }
        }
    
    def _analyze_expression_patterns(self, contexts: List[str]) -> Dict[str, Any]:
        """分析用户表达模式"""
        if not contexts:
            return {"patterns": [], "style": "neutral"}
        
        # 分析表达风格
        patterns = []
        for context in contexts:
            if "我是" in context or "我是" in context:
                patterns.append("direct_self_identification")
            elif "觉得" in context or "感觉" in context:
                patterns.append("subjective_expression")
            elif "测试" in context or "结果" in context:
                patterns.append("test_result_reference")
            elif "朋友" in context or "同学" in context:
                patterns.append("social_reference")
        
        return {
            "patterns": list(set(patterns)),
            "style": "expressive" if len(patterns) > 2 else "reserved" if len(patterns) == 0 else "balanced"
        }
    
    def _classify_user_language_style(self, text: str) -> str:
        """分类用户语言风格"""
        # 基于文本特征分析用户语言风格
        if len(text) > 100:
            return "detailed"
        elif "！" in text or "？" in text:
            return "expressive"
        elif "。" in text and len(text.split("。")) > 3:
            return "analytical"
        else:
            return "concise"
    
    def enhance_flower_descriptions_with_user_language(self, mbti_type: str, user_text: str) -> Dict[str, Any]:
        """基于用户语言增强花卉描述"""
        text_analysis = self.analyze_user_text(user_text)
        
        if mbti_type.lower() in text_analysis["mbti_types_found"]:
            # 找到用户表达习惯，增强花卉描述
            user_contexts = [ctx for ctx in text_analysis["contexts"] if mbti_type.lower() in ctx]
            
            return {
                "enhanced_description": f"基于您的表达习惯，{mbti_type}型人格就像您描述的那样...",
                "user_language_patterns": user_contexts,
                "personalized_flower_meaning": f"根据您的表达方式，您的花卉人格特征更加...",
                "confidence_boost": text_analysis["analysis"]["confidence"]
            }
        
        return {
            "enhanced_description": f"作为{mbti_type}型人格，您具有...",
            "user_language_patterns": [],
            "personalized_flower_meaning": "基于标准特征...",
            "confidence_boost": 0.5
        }


# ==================== 华中师范大学创新元素整合 ====================

class HZUNInnovationIntegrator:
    """华中师范大学创新元素整合器"""
    
    def __init__(self):
        self.flower_system = HZUNFlowerPersonalitySystem()
        self.academic_elements = self._load_academic_elements()
    
    def _load_academic_elements(self) -> Dict[str, Any]:
        """加载学术元素"""
        return {
            "psychology_education": {
                "title": "MBTI十六型人格科普教育",
                "description": "基于华中师范大学心理学院的MBTI科普教育模式",
                "target_audience": "大学生、职场人士",
                "educational_approach": "理论与实践结合"
            },
            "interdisciplinary_integration": {
                "title": "法学院与心理学院联合'知心懂法'分享会",
                "description": "跨学科整合，将MBTI应用于法律职业发展",
                "collaboration_model": "学院间合作",
                "application_field": "法律职业规划"
            },
            "campus_application": {
                "title": "校园植物拟人化设计",
                "description": "将MBTI人格类型与校园植物结合，创造个性化校园文化",
                "implementation": "植物标识系统",
                "cultural_impact": "增强校园文化认同感"
            }
        }
    
    def create_personalized_output(self, mbti_type: str) -> Dict[str, Any]:
        """创建个性化输出"""
        flower_analysis = self.flower_system.get_flower_personality_analysis(mbti_type)
        
        if not flower_analysis:
            return {"error": "无法找到对应的花卉人格分析"}
        
        # 整合华中师范大学创新元素
        personalized_output = {
            "mbti_type": mbti_type,
            "flower_personality": flower_analysis.to_dict(),
            "hzun_innovation": {
                "academic_integration": self.academic_elements,
                "campus_application": self._create_campus_application(mbti_type, flower_analysis),
                "career_guidance": self._create_career_guidance(mbti_type, flower_analysis)
            },
            "personalized_recommendations": {
                "study_environment": self._recommend_study_environment(mbti_type),
                "social_activities": self._recommend_social_activities(mbti_type),
                "personal_growth": self._recommend_personal_growth(mbti_type)
            }
        }
        
        return personalized_output
    
    def _create_campus_application(self, mbti_type: str, flower_analysis: FlowerPersonalityAnalysis) -> Dict[str, Any]:
        """创建校园应用"""
        primary_flower = flower_analysis.primary_flower.flower_info
        
        return {
            "campus_plant": {
                "name": primary_flower.flower_name,
                "location": "校园MBTI人格花园",
                "significance": primary_flower.flower_meaning,
                "maintenance": primary_flower.care_requirements
            },
            "cultural_activities": [
                f"参与{primary_flower.flower_name}主题的校园活动",
                f"学习{primary_flower.flower_name}的养护知识",
                f"分享{primary_flower.flower_name}的人格象征意义"
            ],
            "community_building": [
                f"与同类型人格的同学建立{primary_flower.flower_name}主题小组",
                f"组织{primary_flower.flower_name}相关的学术讨论",
                f"参与校园植物人格化设计项目"
            ]
        }
    
    def _create_career_guidance(self, mbti_type: str, flower_analysis: FlowerPersonalityAnalysis) -> Dict[str, Any]:
        """创建职业指导"""
        return {
            "career_assessment_tools": [
                "MBTI职业性格测试(93题)",
                "霍兰德职业兴趣测试",
                "卡特尔16PF人格测试(187题)"
            ],
            "career_suggestions": flower_analysis.career_implications,
            "professional_development": [
                f"基于{flower_analysis.primary_flower.flower_info.flower_name}特质的职业发展路径",
                "结合MBTI类型和花卉人格的职业规划",
                "利用植物人格化设计提升职业形象"
            ]
        }
    
    def _recommend_study_environment(self, mbti_type: str) -> List[str]:
        """推荐学习环境"""
        if mbti_type.startswith("I"):
            return ["安静的自习室", "图书馆独立座位", "个人学习空间"]
        else:
            return ["小组讨论室", "开放学习空间", "协作学习环境"]
    
    def _recommend_social_activities(self, mbti_type: str) -> List[str]:
        """推荐社交活动"""
        if mbti_type.startswith("E"):
            return ["社团活动", "校园活动", "社交聚会"]
        else:
            return ["学术讨论", "深度交流", "小团体活动"]
    
    def _recommend_personal_growth(self, mbti_type: str) -> List[str]:
        """推荐个人成长"""
        return [
            "参与MBTI人格发展工作坊",
            "学习花卉养护和园艺技能",
            "参与跨学科学术交流",
            "实践植物人格化设计项目"
        ]


# ==================== 主函数和示例 ====================

def main():
    """主函数"""
    print("🌸 MBTI花语花卉人格映射系统")
    print("版本: v1.5 (华中师范大学创新版)")
    print("基于: 华中师范大学植物拟人化设计 + 花语花卉知识")
    print("=" * 60)
    
    # 初始化系统
    flower_system = HZUNFlowerPersonalitySystem()
    innovation_integrator = HZUNInnovationIntegrator()
    
    # 示例：分析ISTJ类型
    print("\n📊 示例分析: ISTJ类型")
    istj_analysis = flower_system.get_flower_personality_analysis("ISTJ")
    if istj_analysis:
        print("✅ 花卉人格分析:")
        print(json.dumps(istj_analysis.to_dict(), indent=2, ensure_ascii=False))
    
    # 示例：创建个性化输出
    print("\n🎨 示例个性化输出: ISTJ类型")
    personalized_output = innovation_integrator.create_personalized_output("ISTJ")
    print("✅ 个性化输出:")
    print(json.dumps(personalized_output, indent=2, ensure_ascii=False))
    
    print("\n🎉 花语花卉人格映射系统完成！")
    print("📋 支持的功能:")
    print("  - 华中师范大学植物拟人化设计")
    print("  - 花语花卉人格智能映射")
    print("  - 个性化输出生成")
    print("  - 校园文化应用")
    print("  - 职业发展指导")


if __name__ == "__main__":
    main()
