#!/usr/bin/env python3
"""
MBTI开放数据模型定义
创建时间: 2025年10月4日
版本: v1.5 (华中师范大学创新版)
基于: 开放生态系统理念 + 花语花卉人格化设计
目标: 定义标准化的MBTI数据模型和开放API数据格式
"""

from typing import Dict, List, Optional, Any, Union
from datetime import datetime
from enum import Enum
from dataclasses import dataclass, asdict
import json
from pydantic import BaseModel, Field, validator


# ==================== 枚举定义 ====================

class MBTIType(str, Enum):
    """MBTI类型枚举"""
    INTJ = "INTJ"
    INTP = "INTP"
    ENTJ = "ENTJ"
    ENTP = "ENTP"
    INFJ = "INFJ"
    INFP = "INFP"
    ENFJ = "ENFJ"
    ENFP = "ENFP"
    ISTJ = "ISTJ"
    ISFJ = "ISFJ"
    ESTJ = "ESTJ"
    ESFJ = "ESFJ"
    ISTP = "ISTP"
    ISFP = "ISFP"
    ESTP = "ESTP"
    ESFP = "ESFP"


class MBTIDimension(str, Enum):
    """MBTI维度枚举"""
    EI = "EI"  # 外向/内向
    SN = "SN"  # 感觉/直觉
    TF = "TF"  # 思考/情感
    JP = "JP"  # 判断/感知


class TestType(str, Enum):
    """测试类型枚举"""
    STANDARD = "standard"      # 标准版 (93题)
    SIMPLIFIED = "simplified"  # 简化版 (28题)
    ADVANCED = "advanced"      # 高级版 (定制)


class TestStatus(str, Enum):
    """测试状态枚举"""
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    ABANDONED = "abandoned"


class AssessmentMethod(str, Enum):
    """评估方法枚举"""
    LOCAL = "local"      # 本地评估
    API = "api"          # 外部API评估
    HYBRID = "hybrid"    # 混合评估


class ReportType(str, Enum):
    """报告类型枚举"""
    PERSONAL = "personal"  # 个人报告
    TEAM = "team"         # 团队报告
    CAREER = "career"     # 职业报告


# ==================== 基础数据模型 ====================

@dataclass
class MBTIDimensionScore:
    """MBTI维度分数"""
    dimension: MBTIDimension
    left_score: int      # 左极分数 (如E分数)
    right_score: int     # 右极分数 (如I分数)
    dominant: str        # 主导维度 (如E或I)
    strength: float      # 维度强度 (0-1)
    
    def to_dict(self) -> Dict[str, Any]:
        return asdict(self)


@dataclass
class MBTIResult:
    """MBTI评估结果"""
    mbti_type: MBTIType
    ei_score: MBTIDimensionScore
    sn_score: MBTIDimensionScore
    tf_score: MBTIDimensionScore
    jp_score: MBTIDimensionScore
    confidence_level: float  # 置信度 (0-1)
    assessment_method: AssessmentMethod
    created_at: datetime
    
    def to_dict(self) -> Dict[str, Any]:
        result = asdict(self)
        # 转换datetime为字符串
        result['created_at'] = self.created_at.isoformat()
        return result


@dataclass
class FlowerInfo:
    """花卉信息"""
    flower_name: str
    flower_scientific_name: str
    flower_color: str
    flower_season: str
    flower_meaning: str
    flower_description: str
    personality_associations: List[str]
    
    def to_dict(self) -> Dict[str, Any]:
        return asdict(self)


@dataclass
class MBTIFlowerMapping:
    """MBTI类型与花卉映射"""
    mbti_type: MBTIType
    flower_info: FlowerInfo
    mapping_strength: float
    mapping_reason: str
    is_primary: bool
    
    def to_dict(self) -> Dict[str, Any]:
        result = asdict(self)
        result['flower_info'] = self.flower_info.to_dict()
        return result


# ==================== Pydantic模型定义 ====================

class MBTIQuestion(BaseModel):
    """MBTI题目模型"""
    id: Optional[int] = None
    question_text: str = Field(..., description="题目内容")
    question_type: TestType = Field(default=TestType.STANDARD, description="题目类型")
    dimension_code: MBTIDimension = Field(..., description="测试维度")
    question_order: Optional[int] = Field(None, description="题目顺序")
    is_active: bool = Field(default=True, description="是否启用")
    
    class Config:
        use_enum_values = True


class MBTITest(BaseModel):
    """MBTI测试模型"""
    id: Optional[int] = None
    user_id: int = Field(..., description="用户ID")
    test_type: TestType = Field(default=TestType.STANDARD, description="测试类型")
    test_status: TestStatus = Field(default=TestStatus.IN_PROGRESS, description="测试状态")
    start_time: Optional[datetime] = Field(default_factory=datetime.now, description="开始时间")
    end_time: Optional[datetime] = Field(None, description="结束时间")
    total_questions: int = Field(default=0, description="总题数")
    answered_questions: int = Field(default=0, description="已回答题数")
    test_duration: Optional[int] = Field(None, description="测试时长(秒)")
    
    class Config:
        use_enum_values = True


class MBTIAnswer(BaseModel):
    """MBTI答案模型"""
    id: Optional[int] = None
    test_id: int = Field(..., description="测试记录ID")
    question_id: int = Field(..., description="题目ID")
    user_id: int = Field(..., description="用户ID")
    answer_value: str = Field(..., description="答案选项 (A/B/C/D/E)")
    answer_score: Optional[int] = Field(None, description="答案分数")
    answered_at: Optional[datetime] = Field(default_factory=datetime.now, description="答题时间")
    
    @validator('answer_value')
    def validate_answer_value(cls, v):
        if v not in ['A', 'B', 'C', 'D', 'E']:
            raise ValueError('答案选项必须是A、B、C、D、E中的一个')
        return v


class MBTIAssessmentRequest(BaseModel):
    """MBTI评估请求模型"""
    user_id: int = Field(..., description="用户ID")
    test_id: int = Field(..., description="测试记录ID")
    answers: List[MBTIAnswer] = Field(..., description="答案列表")
    assessment_method: AssessmentMethod = Field(default=AssessmentMethod.LOCAL, description="评估方法")
    include_flower_analysis: bool = Field(default=True, description="是否包含花卉分析")
    include_career_analysis: bool = Field(default=True, description="是否包含职业分析")


class MBTIAssessmentResponse(BaseModel):
    """MBTI评估响应模型"""
    user_id: int = Field(..., description="用户ID")
    test_id: int = Field(..., description="测试记录ID")
    mbti_result: MBTIResult = Field(..., description="MBTI评估结果")
    flower_mapping: Optional[MBTIFlowerMapping] = Field(None, description="花卉映射")
    career_suggestions: Optional[List[Dict[str, Any]]] = Field(None, description="职业建议")
    compatibility_analysis: Optional[Dict[str, Any]] = Field(None, description="兼容性分析")
    assessment_metadata: Dict[str, Any] = Field(default_factory=dict, description="评估元数据")
    
    def to_dict(self) -> Dict[str, Any]:
        result = self.dict()
        # 转换MBTI结果
        result['mbti_result'] = self.mbti_result.to_dict()
        # 转换花卉映射
        if self.flower_mapping:
            result['flower_mapping'] = self.flower_mapping.to_dict()
        return result


class MBTIReport(BaseModel):
    """MBTI报告模型"""
    id: Optional[int] = None
    user_id: int = Field(..., description="用户ID")
    result_id: int = Field(..., description="评估结果ID")
    report_type: ReportType = Field(default=ReportType.PERSONAL, description="报告类型")
    report_title: str = Field(..., description="报告标题")
    report_content: Dict[str, Any] = Field(..., description="报告内容")
    report_summary: str = Field(..., description="报告摘要")
    flower_analysis: Optional[Dict[str, Any]] = Field(None, description="花卉人格分析")
    career_analysis: Optional[Dict[str, Any]] = Field(None, description="职业分析")
    growth_suggestions: Optional[Dict[str, Any]] = Field(None, description="成长建议")
    generated_at: Optional[datetime] = Field(default_factory=datetime.now, description="生成时间")
    
    class Config:
        use_enum_values = True


# ==================== 开放API数据格式 ====================

class MBTIOpenAPIResponse(BaseModel):
    """MBTI开放API响应格式"""
    success: bool = Field(..., description="请求是否成功")
    message: str = Field(..., description="响应消息")
    data: Optional[Dict[str, Any]] = Field(None, description="响应数据")
    timestamp: datetime = Field(default_factory=datetime.now, description="响应时间戳")
    api_version: str = Field(default="v1.5", description="API版本")
    
    def to_dict(self) -> Dict[str, Any]:
        result = self.dict()
        result['timestamp'] = self.timestamp.isoformat()
        return result


class MBTIOpenAPIError(BaseModel):
    """MBTI开放API错误格式"""
    error_code: str = Field(..., description="错误代码")
    error_message: str = Field(..., description="错误消息")
    error_details: Optional[Dict[str, Any]] = Field(None, description="错误详情")
    timestamp: datetime = Field(default_factory=datetime.now, description="错误时间戳")
    api_version: str = Field(default="v1.5", description="API版本")
    
    def to_dict(self) -> Dict[str, Any]:
        result = self.dict()
        result['timestamp'] = self.timestamp.isoformat()
        return result


# ==================== 华中师范大学创新元素 ====================

class HZUNInnovationElement(BaseModel):
    """华中师范大学创新元素"""
    element_type: str = Field(..., description="创新元素类型")
    element_name: str = Field(..., description="创新元素名称")
    element_description: str = Field(..., description="创新元素描述")
    implementation_method: str = Field(..., description="实现方法")
    target_audience: str = Field(..., description="目标受众")
    
    # 植物拟人化设计元素
    plant_name: Optional[str] = Field(None, description="植物名称")
    plant_personality: Optional[str] = Field(None, description="植物人格特征")
    plant_meaning: Optional[str] = Field(None, description="植物寓意")
    
    # 花语花卉结合元素
    flower_integration: Optional[Dict[str, Any]] = Field(None, description="花卉整合信息")
    personality_mapping: Optional[Dict[str, Any]] = Field(None, description="人格映射信息")


class MBTIWithHZUNInnovation(BaseModel):
    """融入华中师范大学创新元素的MBTI模型"""
    mbti_result: MBTIResult = Field(..., description="MBTI评估结果")
    hzun_innovation: HZUNInnovationElement = Field(..., description="华中师范大学创新元素")
    flower_personality: MBTIFlowerMapping = Field(..., description="花卉人格映射")
    personalized_output: Dict[str, Any] = Field(..., description="个性化输出")
    
    def to_dict(self) -> Dict[str, Any]:
        result = self.dict()
        result['mbti_result'] = self.mbti_result.to_dict()
        result['flower_personality'] = self.flower_personality.to_dict()
        return result


# ==================== 数据验证和转换工具 ====================

class MBTIDataValidator:
    """MBTI数据验证器"""
    
    @staticmethod
    def validate_mbti_type(mbti_type: str) -> bool:
        """验证MBTI类型是否有效"""
        return mbti_type in [t.value for t in MBTIType]
    
    @staticmethod
    def validate_dimension_scores(scores: Dict[str, int]) -> bool:
        """验证维度分数是否有效"""
        required_dimensions = ['EI', 'SN', 'TF', 'JP']
        return all(dim in scores for dim in required_dimensions)
    
    @staticmethod
    def validate_test_answers(answers: List[MBTIAnswer]) -> bool:
        """验证测试答案是否有效"""
        if not answers:
            return False
        
        # 检查答案选项是否有效
        for answer in answers:
            if answer.answer_value not in ['A', 'B', 'C', 'D', 'E']:
                return False
        
        return True


class MBTIDataConverter:
    """MBTI数据转换器"""
    
    @staticmethod
    def convert_to_open_api_format(data: Dict[str, Any]) -> Dict[str, Any]:
        """转换为开放API格式"""
        return {
            "success": True,
            "message": "请求成功",
            "data": data,
            "timestamp": datetime.now().isoformat(),
            "api_version": "v1.5"
        }
    
    @staticmethod
    def convert_flower_mapping_to_dict(flower_mapping: MBTIFlowerMapping) -> Dict[str, Any]:
        """转换花卉映射为字典格式"""
        return {
            "mbti_type": flower_mapping.mbti_type.value,
            "flower_name": flower_mapping.flower_info.flower_name,
            "flower_color": flower_mapping.flower_info.flower_color,
            "flower_meaning": flower_mapping.flower_info.flower_meaning,
            "personality_associations": flower_mapping.flower_info.personality_associations,
            "mapping_strength": flower_mapping.mapping_strength,
            "mapping_reason": flower_mapping.mapping_reason,
            "is_primary": flower_mapping.is_primary
        }


# ==================== 配置和常量 ====================

class MBTIConfig:
    """MBTI配置常量"""
    
    # 测试配置
    STANDARD_QUESTIONS = 93
    SIMPLIFIED_QUESTIONS = 28
    TEST_TIME_LIMIT = 1800  # 30分钟
    
    # 评估配置
    MIN_CONFIDENCE_LEVEL = 0.6
    MAX_CONFIDENCE_LEVEL = 1.0
    
    # 花卉人格化配置
    FLOWER_PERSONALITY_ENABLED = True
    HZUN_INTEGRATION_ENABLED = True
    
    # API配置
    LOCAL_ASSESSMENT_PRIORITY = True
    API_ENHANCEMENT_ENABLED = False
    
    # 华中师范大学创新元素配置
    HZUN_PLANT_PERSONIFICATION = {
        "白色菊花": {"personality": "ISTJ", "traits": ["务实", "坚韧", "可靠"]},
        "紫色菊花": {"personality": "INTP", "traits": ["智慧", "独立", "创新"]},
        "红色菊花": {"personality": "ENFP", "traits": ["热情", "创造力", "活力"]},
        "黄色菊花": {"personality": "ESFP", "traits": ["外向", "热情", "社交"]}
    }


# ==================== 示例数据 ====================

def get_sample_mbti_result() -> MBTIResult:
    """获取示例MBTI结果"""
    ei_score = MBTIDimensionScore(
        dimension=MBTIDimension.EI,
        left_score=75,
        right_score=25,
        dominant="E",
        strength=0.75
    )
    
    sn_score = MBTIDimensionScore(
        dimension=MBTIDimension.SN,
        left_score=30,
        right_score=70,
        dominant="N",
        strength=0.70
    )
    
    tf_score = MBTIDimensionScore(
        dimension=MBTIDimension.TF,
        left_score=60,
        right_score=40,
        dominant="T",
        strength=0.60
    )
    
    jp_score = MBTIDimensionScore(
        dimension=MBTIDimension.JP,
        left_score=80,
        right_score=20,
        dominant="J",
        strength=0.80
    )
    
    return MBTIResult(
        mbti_type=MBTIType.ENTJ,
        ei_score=ei_score,
        sn_score=sn_score,
        tf_score=tf_score,
        jp_score=jp_score,
        confidence_level=0.85,
        assessment_method=AssessmentMethod.LOCAL,
        created_at=datetime.now()
    )


def get_sample_flower_mapping() -> MBTIFlowerMapping:
    """获取示例花卉映射"""
    flower_info = FlowerInfo(
        flower_name="红玫瑰",
        flower_scientific_name="Rosa rubiginosa",
        flower_color="红色",
        flower_season="全年",
        flower_meaning="领导力、热情、决心",
        flower_description="红玫瑰象征着领导力和决心，如同ENTJ型人格的强势领导",
        personality_associations=["领导力", "热情", "决心", "强势"]
    )
    
    return MBTIFlowerMapping(
        mbti_type=MBTIType.ENTJ,
        flower_info=flower_info,
        mapping_strength=1.00,
        mapping_reason="MBTI类型 ENTJ 与 红玫瑰 的完美匹配",
        is_primary=True
    )


# ==================== 主函数 ====================

if __name__ == "__main__":
    print("🌸 MBTI开放数据模型定义")
    print("版本: v1.5 (华中师范大学创新版)")
    print("特色: 花语花卉人格化设计 + 开放生态系统架构")
    print("=" * 60)
    
    # 示例数据验证
    sample_result = get_sample_mbti_result()
    sample_flower = get_sample_flower_mapping()
    
    print("✅ 示例MBTI结果:")
    print(json.dumps(sample_result.to_dict(), indent=2, ensure_ascii=False))
    
    print("\n✅ 示例花卉映射:")
    print(json.dumps(sample_flower.to_dict(), indent=2, ensure_ascii=False))
    
    # 数据验证测试
    validator = MBTIDataValidator()
    print(f"\n✅ MBTI类型验证 (ENTJ): {validator.validate_mbti_type('ENTJ')}")
    print(f"✅ MBTI类型验证 (INVALID): {validator.validate_mbti_type('INVALID')}")
    
    print("\n🎉 MBTI开放数据模型定义完成！")
    print("📋 支持的功能:")
    print("  - 标准化MBTI数据模型")
    print("  - 花语花卉人格化设计")
    print("  - 华中师范大学创新元素")
    print("  - 开放API数据格式")
    print("  - 数据验证和转换工具")
