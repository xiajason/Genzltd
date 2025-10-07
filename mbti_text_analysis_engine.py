#!/usr/bin/env python3
"""
MBTI文本分析引擎
创建时间: 2025年10月4日
版本: v1.6 (学习成果整合版)
基于: 微博用户MBTI类型识别技术 + 华中师范大学创新元素
目标: 基于正则表达式的MBTI类型识别和用户语言分析
"""

import re
from typing import Dict, List, Optional, Any, Tuple
from dataclasses import dataclass, asdict
from datetime import datetime
import json


# ==================== 数据模型 ====================

@dataclass
class MBTITextAnalysisResult:
    """MBTI文本分析结果"""
    mbti_types_found: List[str]
    contexts: List[str]
    confidence: float
    user_language_style: str
    expression_patterns: List[str]
    analysis_timestamp: datetime
    text_length: int
    mbti_mentions_count: int
    
    def to_dict(self) -> Dict[str, Any]:
        result = asdict(self)
        result['analysis_timestamp'] = self.analysis_timestamp.isoformat()
        return result


@dataclass
class UserLanguageProfile:
    """用户语言画像"""
    language_style: str  # detailed, expressive, analytical, concise
    expression_patterns: List[str]
    mbti_awareness_level: str  # high, medium, low
    social_context: str  # personal, social, academic, professional
    confidence_level: float
    
    def to_dict(self) -> Dict[str, Any]:
        return asdict(self)


# ==================== MBTI文本分析引擎 ====================

class MBTITextAnalysisEngine:
    """MBTI文本分析引擎 - 基于微博用户MBTI类型识别技术"""
    
    def __init__(self):
        # 基于学习成果的正则表达式模式
        self.mbti_pattern = r'(?:infj|entp|intp|intj|entj|enfj|infp|enfp|isfp|istp|isfj|istj|estp|esfp|estj|esfj)'
        self.context_pattern = r"(.{0,10}(?:infj|entp|intp|intj|entj|enfj|infp|enfp|isfp|istp|isfj|istj|estp|esfp|estj|esfj).{0,10})"
        
        # 用户语言风格分析模式
        self.expression_patterns = {
            "direct_self_identification": [r"我是\s*\w+", r"我属于\s*\w+", r"我的类型是\s*\w+"],
            "subjective_expression": [r"我觉得\s*\w+", r"我感觉\s*\w+", r"我认为\s*\w+"],
            "test_result_reference": [r"测试\s*\w+", r"结果\s*\w+", r"评估\s*\w+"],
            "social_reference": [r"朋友\s*\w+", r"同学\s*\w+", r"同事\s*\w+"],
            "comparison": [r"比较\s*\w+", r"类似\s*\w+", r"相似\s*\w+"],
            "uncertainty": [r"可能\s*\w+", r"也许\s*\w+", r"大概\s*\w+"]
        }
        
        # 华中师范大学创新元素 - 植物拟人化表达模式
        self.flower_expression_patterns = {
            "flower_metaphor": [r"像\s*\w+花", r"如\s*\w+花", r"似\s*\w+花"],
            "personality_flower": [r"花语\s*\w+", r"花卉\s*\w+", r"植物\s*\w+"],
            "seasonal_expression": [r"春天\s*\w+", r"夏天\s*\w+", r"秋天\s*\w+", r"冬天\s*\w+"]
        }
    
    def analyze_text(self, text: str) -> MBTITextAnalysisResult:
        """分析文本中的MBTI相关信息"""
        # 提取MBTI类型
        mbti_matches = re.findall(self.mbti_pattern, text.lower())
        
        # 提取上下文
        context_matches = re.findall(self.context_pattern, text.lower())
        
        # 分析用户语言风格
        language_style = self._classify_language_style(text)
        
        # 分析表达模式
        expression_patterns = self._analyze_expression_patterns(text)
        
        # 计算置信度
        confidence = self._calculate_confidence(mbti_matches, context_matches, text)
        
        return MBTITextAnalysisResult(
            mbti_types_found=list(set(mbti_matches)),
            contexts=context_matches,
            confidence=confidence,
            user_language_style=language_style,
            expression_patterns=expression_patterns,
            analysis_timestamp=datetime.now(),
            text_length=len(text),
            mbti_mentions_count=len(mbti_matches)
        )
    
    def _classify_language_style(self, text: str) -> str:
        """分类用户语言风格"""
        # 基于文本特征分析
        if len(text) > 200:
            return "detailed"
        elif "！" in text or "？" in text or "..." in text:
            return "expressive"
        elif "。" in text and len(text.split("。")) > 4:
            return "analytical"
        elif "，" in text and len(text.split("，")) > 3:
            return "structured"
        else:
            return "concise"
    
    def _analyze_expression_patterns(self, text: str) -> List[str]:
        """分析表达模式"""
        patterns = []
        
        for pattern_name, pattern_list in self.expression_patterns.items():
            for pattern in pattern_list:
                if re.search(pattern, text):
                    patterns.append(pattern_name)
                    break
        
        # 检查华中师范大学创新元素 - 植物拟人化表达
        for pattern_name, pattern_list in self.flower_expression_patterns.items():
            for pattern in pattern_list:
                if re.search(pattern, text):
                    patterns.append(f"flower_{pattern_name}")
                    break
        
        return list(set(patterns))
    
    def _calculate_confidence(self, mbti_matches: List[str], contexts: List[str], text: str) -> float:
        """计算分析置信度"""
        base_confidence = min(len(mbti_matches) / 3.0, 1.0)
        
        # 基于上下文数量调整
        context_factor = min(len(contexts) / 5.0, 1.0)
        
        # 基于文本长度调整
        length_factor = min(len(text) / 100.0, 1.0)
        
        # 基于表达模式丰富度调整
        pattern_richness = len(self._analyze_expression_patterns(text)) / 6.0
        
        return min((base_confidence + context_factor + length_factor + pattern_richness) / 4.0, 1.0)
    
    def extract_user_language_profile(self, text: str) -> UserLanguageProfile:
        """提取用户语言画像"""
        analysis_result = self.analyze_text(text)
        
        # 分析MBTI认知水平
        mbti_awareness = self._assess_mbti_awareness(analysis_result)
        
        # 分析社交语境
        social_context = self._assess_social_context(text)
        
        return UserLanguageProfile(
            language_style=analysis_result.user_language_style,
            expression_patterns=analysis_result.expression_patterns,
            mbti_awareness_level=mbti_awareness,
            social_context=social_context,
            confidence_level=analysis_result.confidence
        )
    
    def _assess_mbti_awareness(self, analysis_result: MBTITextAnalysisResult) -> str:
        """评估MBTI认知水平"""
        if analysis_result.mbti_mentions_count > 3:
            return "high"
        elif analysis_result.mbti_mentions_count > 1:
            return "medium"
        else:
            return "low"
    
    def _assess_social_context(self, text: str) -> str:
        """评估社交语境"""
        if any(word in text for word in ["朋友", "同学", "同事", "家人"]):
            return "social"
        elif any(word in text for word in ["学习", "课程", "老师", "学校"]):
            return "academic"
        elif any(word in text for word in ["工作", "职业", "公司", "项目"]):
            return "professional"
        else:
            return "personal"
    
    def generate_personalized_flower_description(self, mbti_type: str, user_text: str) -> Dict[str, Any]:
        """基于用户语言生成个性化花卉描述"""
        analysis_result = self.analyze_text(user_text)
        user_profile = self.extract_user_language_profile(user_text)
        
        # 基于用户语言风格调整描述
        if user_profile.language_style == "detailed":
            description_style = "详细描述"
        elif user_profile.language_style == "expressive":
            description_style = "情感表达"
        elif user_profile.language_style == "analytical":
            description_style = "分析性描述"
        else:
            description_style = "简洁描述"
        
        # 基于表达模式调整内容
        if "flower_metaphor" in analysis_result.expression_patterns:
            flower_integration = "融入花卉比喻"
        else:
            flower_integration = "标准花卉描述"
        
        return {
            "mbti_type": mbti_type,
            "personalized_description": f"基于您的表达风格，{mbti_type}型人格的{description_style}...",
            "flower_integration": flower_integration,
            "user_language_style": user_profile.language_style,
            "expression_patterns": analysis_result.expression_patterns,
            "confidence": analysis_result.confidence,
            "recommendations": self._generate_language_recommendations(user_profile)
        }
    
    def _generate_language_recommendations(self, user_profile: UserLanguageProfile) -> List[str]:
        """生成语言建议"""
        recommendations = []
        
        if user_profile.mbti_awareness_level == "low":
            recommendations.append("建议了解更多MBTI基础知识")
        
        if user_profile.language_style == "concise":
            recommendations.append("可以尝试更详细的自我描述")
        
        if "uncertainty" in user_profile.expression_patterns:
            recommendations.append("可以更自信地表达自己的观点")
        
        if user_profile.social_context == "personal":
            recommendations.append("可以分享更多社交经历")
        
        return recommendations


# ==================== 华中师范大学创新元素整合 ====================

class HZUNInnovationIntegrator:
    """华中师范大学创新元素整合器"""
    
    def __init__(self):
        self.text_analysis_engine = MBTITextAnalysisEngine()
        self.flower_personality_mapping = {
            "ISTJ": {"flower": "白色菊花", "traits": ["务实", "坚韧", "可靠"]},
            "INTP": {"flower": "紫色菊花", "traits": ["智慧", "独立", "创新"]},
            "ENFP": {"flower": "红色菊花", "traits": ["热情", "创造力", "活力"]},
            "ESFP": {"flower": "黄色菊花", "traits": ["外向", "热情", "社交"]}
        }
    
    def integrate_campus_innovation(self, user_text: str, mbti_type: str) -> Dict[str, Any]:
        """整合校园创新元素"""
        analysis_result = self.text_analysis_engine.analyze_text(user_text)
        
        # 基于华中师范大学植物拟人化设计
        flower_info = self.flower_personality_mapping.get(mbti_type, {})
        
        # 生成校园文化相关的个性化描述
        campus_description = self._generate_campus_description(mbti_type, flower_info, analysis_result)
        
        return {
            "mbti_type": mbti_type,
            "flower_info": flower_info,
            "campus_description": campus_description,
            "academic_integration": self._generate_academic_integration(analysis_result),
            "innovation_elements": self._extract_innovation_elements(analysis_result)
        }
    
    def _generate_campus_description(self, mbti_type: str, flower_info: Dict, analysis_result: MBTITextAnalysisResult) -> str:
        """生成校园文化描述"""
        flower_name = flower_info.get("flower", "未知花卉")
        traits = flower_info.get("traits", [])
        
        if analysis_result.user_language_style == "expressive":
            return f"在华中师范大学的校园里，{mbti_type}型人格就像{flower_name}一样，{', '.join(traits)}，为校园文化增添独特魅力！"
        else:
            return f"基于华中师范大学的植物拟人化设计，{mbti_type}型人格对应{flower_name}，体现了{', '.join(traits)}的特质。"
    
    def _generate_academic_integration(self, analysis_result: MBTITextAnalysisResult) -> Dict[str, Any]:
        """生成学术整合建议"""
        return {
            "cross_disciplinary": "建议参与法学院与心理学院联合的'知心懂法'分享会",
            "campus_application": "可以参与校园植物拟人化设计活动",
            "career_guidance": "结合MBTI+霍兰德+卡特尔16PF进行职业规划"
        }
    
    def _extract_innovation_elements(self, analysis_result: MBTITextAnalysisResult) -> List[str]:
        """提取创新元素"""
        elements = []
        
        if "flower_metaphor" in analysis_result.expression_patterns:
            elements.append("植物拟人化表达")
        
        if analysis_result.user_language_style == "analytical":
            elements.append("学术分析思维")
        
        if "social_reference" in analysis_result.expression_patterns:
            elements.append("校园社交文化")
        
        return elements


# ==================== 主函数和示例 ====================

def main():
    """主函数"""
    print("🔍 MBTI文本分析引擎")
    print("版本: v1.6 (学习成果整合版)")
    print("基于: 微博用户MBTI类型识别技术 + 华中师范大学创新元素")
    print("=" * 60)
    
    # 初始化分析引擎
    text_engine = MBTITextAnalysisEngine()
    hzun_integrator = HZUNInnovationIntegrator()
    
    # 示例文本分析
    sample_texts = [
        "我是INTJ型人格，像紫罗兰一样独立而神秘",
        "测试结果显示我是ENFP，感觉像红色菊花一样热情",
        "朋友说我是ISTJ，比较务实可靠",
        "我觉得我可能是INTP，喜欢独立思考"
    ]
    
    for i, text in enumerate(sample_texts, 1):
        print(f"\n📝 示例 {i}: {text}")
        
        # 文本分析
        analysis_result = text_engine.analyze_text(text)
        print(f"✅ MBTI类型: {analysis_result.mbti_types_found}")
        print(f"   置信度: {analysis_result.confidence:.2f}")
        print(f"   语言风格: {analysis_result.user_language_style}")
        print(f"   表达模式: {analysis_result.expression_patterns}")
        
        # 用户语言画像
        user_profile = text_engine.extract_user_language_profile(text)
        print(f"   MBTI认知水平: {user_profile.mbti_awareness_level}")
        print(f"   社交语境: {user_profile.social_context}")
        
        # 华中师范大学创新元素整合
        if analysis_result.mbti_types_found:
            mbti_type = analysis_result.mbti_types_found[0].upper()
            innovation_result = hzun_integrator.integrate_campus_innovation(text, mbti_type)
            print(f"   🌸 校园创新: {innovation_result['campus_description']}")
    
    print("\n🎉 MBTI文本分析引擎完成！")
    print("📋 支持的功能:")
    print("  - 正则表达式MBTI类型识别")
    print("  - 用户语言风格分析")
    print("  - 表达模式识别")
    print("  - 华中师范大学创新元素整合")
    print("  - 个性化花卉描述生成")


if __name__ == "__main__":
    main()
