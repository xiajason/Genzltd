#!/usr/bin/env python3
"""
MBTI本地题库框架
创建时间: 2025年10月4日
版本: v1.5 (华中师范大学创新版)
基于: 本地题库+外部API混合架构
目标: 为MBTI测试提供本地题库管理框架，支持93题/28题/简化版测试
"""

from typing import Dict, List, Optional, Any, Tuple
from dataclasses import dataclass, asdict
from enum import Enum
import json
import re
from datetime import datetime
import random


# ==================== 题库类型枚举 ====================

class QuestionBankType(str, Enum):
    """题库类型枚举"""
    STANDARD = "standard"      # 标准版 (93题)
    SIMPLIFIED = "simplified"  # 简化版 (28题)
    ADVANCED = "advanced"      # 高级版 (定制)
    QUICK = "quick"           # 快速版 (16题)


class QuestionCategory(str, Enum):
    """题目分类枚举"""
    PERSONALITY = "personality"    # 人格特征
    BEHAVIOR = "behavior"         # 行为模式
    PREFERENCE = "preference"     # 偏好选择
    SITUATION = "situation"       # 情境反应
    VALUE = "value"              # 价值观


class DifficultyLevel(str, Enum):
    """难度等级枚举"""
    EASY = "easy"        # 简单
    MEDIUM = "medium"    # 中等
    HARD = "hard"        # 困难
    EXPERT = "expert"    # 专家


# ==================== 数据模型 ====================

@dataclass
class MBTIQuestion:
    """MBTI题目"""
    question_id: int
    question_text: str
    question_type: QuestionBankType
    category: QuestionCategory
    dimension: str  # EI, SN, TF, JP
    difficulty: DifficultyLevel
    options: List[str]
    correct_answers: List[str]
    explanation: str
    weight: float = 1.0
    is_active: bool = True
    created_at: datetime = None
    
    def __post_init__(self):
        if self.created_at is None:
            self.created_at = datetime.now()
    
    def to_dict(self) -> Dict[str, Any]:
        result = asdict(self)
        result['created_at'] = self.created_at.isoformat()
        return result


@dataclass
class QuestionBank:
    """题库"""
    bank_id: str
    bank_name: str
    bank_type: QuestionBankType
    description: str
    total_questions: int
    questions: List[MBTIQuestion]
    target_audience: str
    estimated_time: int  # 预计完成时间(分钟)
    difficulty_distribution: Dict[str, int]
    dimension_coverage: Dict[str, int]
    
    def to_dict(self) -> Dict[str, Any]:
        result = asdict(self)
        result['questions'] = [q.to_dict() for q in self.questions]
        return result


@dataclass
class TestSession:
    """测试会话"""
    session_id: str
    user_id: int
    bank_type: QuestionBankType
    questions: List[MBTIQuestion]
    current_question_index: int = 0
    answers: Dict[int, str] = None
    start_time: datetime = None
    end_time: Optional[datetime] = None
    is_completed: bool = False
    
    def __post_init__(self):
        if self.start_time is None:
            self.start_time = datetime.now()
        if self.answers is None:
            self.answers = {}
    
    def to_dict(self) -> Dict[str, Any]:
        result = asdict(self)
        result['questions'] = [q.to_dict() for q in self.questions]
        result['start_time'] = self.start_time.isoformat()
        if self.end_time:
            result['end_time'] = self.end_time.isoformat()
        return result


# ==================== 本地题库管理器 ====================

class LocalMBTIQuestionBankManager:
    """本地MBTI题库管理器"""
    
    def __init__(self):
        self.question_banks = self._initialize_question_banks()
        self.active_sessions = {}
        self.question_templates = self._initialize_question_templates()
    
    def _initialize_question_banks(self) -> Dict[str, QuestionBank]:
        """初始化题库"""
        banks = {}
        
        # 标准版题库 (93题)
        banks["standard_93"] = QuestionBank(
            bank_id="standard_93",
            bank_name="MBTI标准版题库",
            bank_type=QuestionBankType.STANDARD,
            description="完整的MBTI人格测试题库，包含93道精心设计的题目",
            total_questions=93,
            questions=[],  # 等待题库上传后填充
            target_audience="成年人、职场人士",
            estimated_time=30,
            difficulty_distribution={"easy": 30, "medium": 45, "hard": 18},
            dimension_coverage={"EI": 23, "SN": 23, "TF": 23, "JP": 24}
        )
        
        # 简化版题库 (28题)
        banks["simplified_28"] = QuestionBank(
            bank_id="simplified_28",
            bank_name="MBTI简化版题库",
            bank_type=QuestionBankType.SIMPLIFIED,
            description="简化的MBTI人格测试题库，包含28道核心题目",
            total_questions=28,
            questions=[],  # 等待题库上传后填充
            target_audience="学生、快速测试",
            estimated_time=10,
            difficulty_distribution={"easy": 15, "medium": 10, "hard": 3},
            dimension_coverage={"EI": 7, "SN": 7, "TF": 7, "JP": 7}
        )
        
        # 快速版题库 (16题)
        banks["quick_16"] = QuestionBank(
            bank_id="quick_16",
            bank_name="MBTI快速版题库",
            bank_type=QuestionBankType.QUICK,
            description="快速MBTI人格测试题库，包含16道精选题目",
            total_questions=16,
            questions=[],  # 等待题库上传后填充
            target_audience="初次测试、快速了解",
            estimated_time=5,
            difficulty_distribution={"easy": 12, "medium": 4, "hard": 0},
            dimension_coverage={"EI": 4, "SN": 4, "TF": 4, "JP": 4}
        )
        
        return banks
    
    def _initialize_question_templates(self) -> Dict[str, List[str]]:
        """初始化题目模板"""
        return {
            "EI": [
                "在社交场合中，你更倾向于：",
                "当你需要思考问题时，你更喜欢：",
                "在团队合作中，你更愿意：",
                "面对新环境时，你的第一反应是："
            ],
            "SN": [
                "在做决定时，你更依赖：",
                "学习新知识时，你更喜欢：",
                "面对问题时，你的解决方式是：",
                "在规划未来时，你更关注："
            ],
            "TF": [
                "在做重要决定时，你更重视：",
                "面对冲突时，你的处理方式是：",
                "评价他人时，你更看重：",
                "在团队中，你更愿意："
            ],
            "JP": [
                "面对任务时，你的工作方式是：",
                "在时间管理上，你更倾向于：",
                "面对变化时，你的反应是：",
                "在制定计划时，你更喜欢："
            ]
        }
    
    def create_test_session(self, user_id: int, bank_type: QuestionBankType) -> TestSession:
        """创建测试会话"""
        bank_key = f"{bank_type.value}_{self._get_bank_suffix(bank_type)}"
        
        if bank_key not in self.question_banks:
            raise ValueError(f"不支持的题库类型: {bank_type}")
        
        bank = self.question_banks[bank_key]
        
        # 如果题库为空，使用模板生成题目
        if not bank.questions:
            questions = self._generate_questions_from_template(bank_type)
        else:
            questions = bank.questions.copy()
        
        # 随机打乱题目顺序
        random.shuffle(questions)
        
        session_id = f"session_{user_id}_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        
        session = TestSession(
            session_id=session_id,
            user_id=user_id,
            bank_type=bank_type,
            questions=questions
        )
        
        self.active_sessions[session_id] = session
        return session
    
    def _get_bank_suffix(self, bank_type: QuestionBankType) -> str:
        """获取题库后缀"""
        suffix_mapping = {
            QuestionBankType.STANDARD: "93",
            QuestionBankType.SIMPLIFIED: "28",
            QuestionBankType.QUICK: "16"
        }
        return suffix_mapping.get(bank_type, "custom")
    
    def _generate_questions_from_template(self, bank_type: QuestionBankType) -> List[MBTIQuestion]:
        """从模板生成题目"""
        questions = []
        question_id = 1
        
        # 根据题库类型确定题目数量
        question_counts = {
            QuestionBankType.STANDARD: 93,
            QuestionBankType.SIMPLIFIED: 28,
            QuestionBankType.QUICK: 16
        }
        
        total_questions = question_counts.get(bank_type, 28)
        questions_per_dimension = total_questions // 4
        
        for dimension in ["EI", "SN", "TF", "JP"]:
            for i in range(questions_per_dimension):
                question = MBTIQuestion(
                    question_id=question_id,
                    question_text=self._generate_question_text(dimension, i),
                    question_type=bank_type,
                    category=QuestionCategory.PERSONALITY,
                    dimension=dimension,
                    difficulty=DifficultyLevel.MEDIUM,
                    options=["A. 选项A", "B. 选项B", "C. 选项C", "D. 选项D"],
                    correct_answers=["A", "B"],  # 示例答案
                    explanation=f"这是{dimension}维度的第{i+1}题，用于评估相关人格特征",
                    weight=1.0
                )
                questions.append(question)
                question_id += 1
        
        return questions
    
    def _generate_question_text(self, dimension: str, index: int) -> str:
        """生成题目文本"""
        templates = self.question_templates.get(dimension, ["请选择最符合你的选项："])
        template = templates[index % len(templates)]
        return f"{template} (第{index+1}题)"
    
    def get_current_question(self, session_id: str) -> Optional[MBTIQuestion]:
        """获取当前题目"""
        if session_id not in self.active_sessions:
            return None
        
        session = self.active_sessions[session_id]
        if session.current_question_index >= len(session.questions):
            return None
        
        return session.questions[session.current_question_index]
    
    def submit_answer(self, session_id: str, answer: str) -> bool:
        """提交答案"""
        if session_id not in self.active_sessions:
            return False
        
        session = self.active_sessions[session_id]
        current_question = self.get_current_question(session_id)
        
        if not current_question:
            return False
        
        # 记录答案
        session.answers[current_question.question_id] = answer
        
        # 移动到下一题
        session.current_question_index += 1
        
        # 检查是否完成
        if session.current_question_index >= len(session.questions):
            session.is_completed = True
            session.end_time = datetime.now()
        
        return True
    
    def get_session_progress(self, session_id: str) -> Dict[str, Any]:
        """获取会话进度"""
        if session_id not in self.active_sessions:
            return {"error": "会话不存在"}
        
        session = self.active_sessions[session_id]
        
        return {
            "session_id": session_id,
            "user_id": session.user_id,
            "bank_type": session.bank_type.value,
            "total_questions": len(session.questions),
            "current_question": session.current_question_index + 1,
            "answered_questions": len(session.answers),
            "progress_percentage": (len(session.answers) / len(session.questions)) * 100,
            "is_completed": session.is_completed,
            "start_time": session.start_time.isoformat(),
            "elapsed_time": (datetime.now() - session.start_time).total_seconds()
        }
    
    def get_session_results(self, session_id: str) -> Optional[Dict[str, Any]]:
        """获取会话结果"""
        if session_id not in self.active_sessions:
            return None
        
        session = self.active_sessions[session_id]
        
        if not session.is_completed:
            return {"error": "测试未完成"}
        
        # 计算各维度分数
        dimension_scores = self._calculate_dimension_scores(session)
        
        # 确定MBTI类型
        mbti_type = self._determine_mbti_type(dimension_scores)
        
        # 计算置信度
        confidence = self._calculate_confidence(dimension_scores)
        
        return {
            "session_id": session_id,
            "user_id": session.user_id,
            "mbti_type": mbti_type,
            "confidence_level": confidence,
            "dimension_scores": dimension_scores,
            "total_questions": len(session.questions),
            "answered_questions": len(session.answers),
            "completion_time": (session.end_time - session.start_time).total_seconds(),
            "test_date": session.start_time.isoformat()
        }
    
    def _calculate_dimension_scores(self, session: TestSession) -> Dict[str, float]:
        """计算维度分数"""
        dimension_scores = {"EI": 0, "SN": 0, "TF": 0, "JP": 0}
        
        for question in session.questions:
            if question.question_id in session.answers:
                answer = session.answers[question.question_id]
                dimension = question.dimension
                
                # 简化的评分逻辑
                score_mapping = {"A": 1, "B": 0.5, "C": 0, "D": -0.5}
                score = score_mapping.get(answer, 0)
                
                dimension_scores[dimension] += score
        
        return dimension_scores
    
    def _determine_mbti_type(self, dimension_scores: Dict[str, float]) -> str:
        """确定MBTI类型"""
        mbti_type = ""
        
        # EI维度
        mbti_type += "E" if dimension_scores["EI"] > 0 else "I"
        
        # SN维度
        mbti_type += "S" if dimension_scores["SN"] > 0 else "N"
        
        # TF维度
        mbti_type += "T" if dimension_scores["TF"] > 0 else "F"
        
        # JP维度
        mbti_type += "J" if dimension_scores["JP"] > 0 else "P"
        
        return mbti_type
    
    def _calculate_confidence(self, dimension_scores: Dict[str, float]) -> float:
        """计算置信度"""
        total_confidence = 0.0
        
        for dimension, score in dimension_scores.items():
            confidence = abs(score) / 10.0  # 假设最大分数为10
            total_confidence += confidence
        
        return min(total_confidence / 4.0, 1.0)
    
    def validate_mbti_type(self, mbti_type: str) -> bool:
        """验证MBTI类型格式 - 基于微博用户MBTI类型识别技术"""
        # 基于学习成果的正则表达式模式，支持大小写不敏感
        mbti_pattern = r'^(infj|entp|intp|intj|entj|enfj|infp|enfp|isfp|istp|isfj|istj|estp|esfp|estj|esfj)$'
        return bool(re.match(mbti_pattern, mbti_type.lower()))
    
    def validate_mbti_type_with_context(self, text: str) -> Dict[str, Any]:
        """验证MBTI类型并提取上下文信息"""
        # 基于学习成果的上下文窗口提取
        mbti_pattern = r'(?:infj|entp|intp|intj|entj|enfj|infp|enfp|isfp|istp|isfj|istj|estp|esfp|estj|esfj)'
        matches = re.findall(mbti_pattern, text.lower())
        
        if matches:
            # 提取上下文
            context_pattern = r"(.{0,10}(?:infj|entp|intp|intj|entj|enfj|infp|enfp|isfp|istp|isfj|istj|estp|esfp|estj|esfj).{0,10})"
            context_matches = re.findall(context_pattern, text.lower())
            
            return {
                "is_valid": True,
                "mbti_types": list(set(matches)),
                "contexts": context_matches,
                "confidence": min(len(matches) / 3.0, 1.0)
            }
        
        return {
            "is_valid": False,
            "mbti_types": [],
            "contexts": [],
            "confidence": 0.0
        }
    
    def extract_mbti_from_text(self, text: str) -> List[str]:
        """从文本中提取MBTI类型"""
        # 基于文章中的正则表达式模式
        mbti_pattern = r'(?:infj|entp|intp|intj|entj|enfj|infp|enfp|isfp|istp|isfj|istj|estp|esfp|estj|esfj)'
        matches = re.findall(mbti_pattern, text.lower())
        return list(set(matches))  # 去重
    
    def extract_mbti_context(self, text: str, context_length: int = 5) -> List[Dict[str, str]]:
        """提取MBTI类型及其上下文"""
        # 基于文章中的上下文窗口提取方法
        mbti_context_pattern = f"(.{{0,{context_length}}}(?:infj|entp|intp|intj|entj|enfj|infp|enfp|isfp|istp|isfj|istj|estp|esfp|estj|esfj).{{0,{context_length}}})"
        
        matches = re.findall(mbti_context_pattern, text.lower())
        contexts = []
        
        for match in matches:
            # 提取MBTI类型
            mbti_types = self.extract_mbti_from_text(match)
            for mbti_type in mbti_types:
                contexts.append({
                    "mbti_type": mbti_type.upper(),
                    "context": match,
                    "context_length": len(match)
                })
        
        return contexts
    
    def load_questions_from_file(self, bank_type: QuestionBankType, file_path: str) -> bool:
        """从文件加载题目"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                questions_data = json.load(f)
            
            questions = []
            for q_data in questions_data:
                question = MBTIQuestion(
                    question_id=q_data['question_id'],
                    question_text=q_data['question_text'],
                    question_type=QuestionBankType(q_data['question_type']),
                    category=QuestionCategory(q_data['category']),
                    dimension=q_data['dimension'],
                    difficulty=DifficultyLevel(q_data['difficulty']),
                    options=q_data['options'],
                    correct_answers=q_data['correct_answers'],
                    explanation=q_data['explanation'],
                    weight=q_data.get('weight', 1.0),
                    is_active=q_data.get('is_active', True)
                )
                questions.append(question)
            
            # 更新题库
            bank_key = f"{bank_type.value}_{self._get_bank_suffix(bank_type)}"
            if bank_key in self.question_banks:
                self.question_banks[bank_key].questions = questions
                return True
            
            return False
            
        except Exception as e:
            print(f"加载题目失败: {str(e)}")
            return False
    
    def export_questions_to_file(self, bank_type: QuestionBankType, file_path: str) -> bool:
        """导出题目到文件"""
        try:
            bank_key = f"{bank_type.value}_{self._get_bank_suffix(bank_type)}"
            if bank_key not in self.question_banks:
                return False
            
            bank = self.question_banks[bank_key]
            questions_data = [q.to_dict() for q in bank.questions]
            
            with open(file_path, 'w', encoding='utf-8') as f:
                json.dump(questions_data, f, ensure_ascii=False, indent=2)
            
            return True
            
        except Exception as e:
            print(f"导出题目失败: {str(e)}")
            return False
    
    def get_question_bank_info(self, bank_type: QuestionBankType) -> Optional[Dict[str, Any]]:
        """获取题库信息"""
        bank_key = f"{bank_type.value}_{self._get_bank_suffix(bank_type)}"
        if bank_key not in self.question_banks:
            return None
        
        bank = self.question_banks[bank_key]
        return bank.to_dict()
    
    def get_available_banks(self) -> List[Dict[str, Any]]:
        """获取可用题库列表"""
        banks_info = []
        for bank in self.question_banks.values():
            banks_info.append({
                "bank_id": bank.bank_id,
                "bank_name": bank.bank_name,
                "bank_type": bank.bank_type.value,
                "total_questions": bank.total_questions,
                "estimated_time": bank.estimated_time,
                "target_audience": bank.target_audience,
                "has_questions": len(bank.questions) > 0
            })
        
        return banks_info


# ==================== 主函数和示例 ====================

def main():
    """主函数"""
    print("📚 MBTI本地题库框架")
    print("版本: v1.5 (华中师范大学创新版)")
    print("基于: 本地题库+外部API混合架构")
    print("=" * 60)
    
    # 初始化题库管理器
    bank_manager = LocalMBTIQuestionBankManager()
    
    # 显示可用题库
    print("\n📋 可用题库:")
    available_banks = bank_manager.get_available_banks()
    for bank in available_banks:
        print(f"  - {bank['bank_name']} ({bank['bank_type']})")
        print(f"    题目数量: {bank['total_questions']}")
        print(f"    预计时间: {bank['estimated_time']}分钟")
        print(f"    目标受众: {bank['target_audience']}")
        print(f"    题目状态: {'已加载' if bank['has_questions'] else '等待上传'}")
        print()
    
    # 示例：创建测试会话
    print("🧪 示例: 创建简化版测试会话")
    session = bank_manager.create_test_session(1, QuestionBankType.SIMPLIFIED)
    print(f"✅ 测试会话创建成功: {session.session_id}")
    print(f"   题库类型: {session.bank_type.value}")
    print(f"   题目数量: {len(session.questions)}")
    
    # 示例：获取当前题目
    current_question = bank_manager.get_current_question(session.session_id)
    if current_question:
        print(f"\n📝 当前题目: {current_question.question_text}")
        print(f"   维度: {current_question.dimension}")
        print(f"   选项: {current_question.options}")
    
    # 示例：获取会话进度
    progress = bank_manager.get_session_progress(session.session_id)
    print(f"\n📊 会话进度:")
    print(f"   当前题目: {progress['current_question']}/{progress['total_questions']}")
    print(f"   已完成: {progress['answered_questions']}题")
    print(f"   进度: {progress['progress_percentage']:.1f}%")
    
    print("\n🎉 本地题库框架完成！")
    print("📋 支持的功能:")
    print("  - 多版本题库管理 (93题/28题/16题)")
    print("  - 测试会话管理")
    print("  - 题目随机化")
    print("  - 进度跟踪")
    print("  - 结果计算")
    print("  - 题库导入导出")
    print("\n⏳ 等待题库上传后即可开始完整测试！")


if __name__ == "__main__":
    main()
