#!/usr/bin/env python3
"""
MBTI题库生成器
创建时间: 2025年10月4日
版本: v1.0 (开源题库版)
基于: 开源MBTI题库 + 奥思MBTI设计思路
目标: 生成符合奥思MBTI标准的MBTI测试题库
"""

import json
import random
from typing import Dict, List, Optional, Any
from dataclasses import dataclass, asdict
from datetime import datetime
import re


# ==================== 数据模型 ====================

@dataclass
class MBTIQuestion:
    """MBTI题目模型"""
    id: int
    question_text: str
    dimension: str  # EI, SN, TF, JP
    question_type: str  # standard, simplified, advanced
    options: List[Dict[str, Any]]
    difficulty: str  # easy, medium, hard
    category: str  # personality, behavior, preference
    created_at: datetime
    
    def to_dict(self) -> Dict[str, Any]:
        result = asdict(self)
        result['created_at'] = self.created_at.isoformat()
        return result


@dataclass
class QuestionBank:
    """题库模型"""
    name: str
    version: str
    total_questions: int
    questions: List[MBTIQuestion]
    dimensions: Dict[str, int]  # 各维度题目数量
    created_at: datetime
    
    def to_dict(self) -> Dict[str, Any]:
        result = asdict(self)
        result['created_at'] = self.created_at.isoformat()
        result['questions'] = [q.to_dict() for q in self.questions]
        return result


# ==================== MBTI题库生成器 ====================

class MBTIQuestionBankGenerator:
    """MBTI题库生成器 - 基于开源题库和奥思MBTI设计思路"""
    
    def __init__(self):
        self.dimensions = {
            "EI": "外向/内向",
            "SN": "感觉/直觉", 
            "TF": "思考/情感",
            "JP": "判断/感知"
        }
        
        self.question_templates = {
            "EI": {
                "easy": [
                    "在社交聚会中，你更倾向于：",
                    "当你需要充电时，你更喜欢：",
                    "在团队合作中，你更愿意："
                ],
                "medium": [
                    "面对新环境时，你的第一反应是：",
                    "在解决问题时，你更倾向于：",
                    "当你感到压力时，你更愿意："
                ],
                "hard": [
                    "在深度思考时，你更倾向于：",
                    "面对复杂的人际关系时，你更愿意：",
                    "在长期项目中，你更倾向于："
                ]
            },
            "SN": {
                "easy": [
                    "你更关注：",
                    "在获取信息时，你更倾向于：",
                    "面对新想法时，你更愿意："
                ],
                "medium": [
                    "在制定计划时，你更倾向于：",
                    "面对抽象概念时，你更愿意：",
                    "在解决问题时，你更关注："
                ],
                "hard": [
                    "在创新项目中，你更倾向于：",
                    "面对理论分析时，你更愿意：",
                    "在长期规划中，你更关注："
                ]
            },
            "TF": {
                "easy": [
                    "在做决定时，你更倾向于：",
                    "面对冲突时，你更愿意：",
                    "在评价他人时，你更关注："
                ],
                "medium": [
                    "在团队决策中，你更倾向于：",
                    "面对批评时，你更愿意：",
                    "在解决问题时，你更关注："
                ],
                "hard": [
                    "在复杂决策中，你更倾向于：",
                    "面对价值观冲突时，你更愿意：",
                    "在长期关系中，你更关注："
                ]
            },
            "JP": {
                "easy": [
                    "在安排时间时，你更倾向于：",
                    "面对变化时，你更愿意：",
                    "在完成任务时，你更倾向于："
                ],
                "medium": [
                    "在项目管理中，你更倾向于：",
                    "面对不确定性时，你更愿意：",
                    "在制定计划时，你更关注："
                ],
                "hard": [
                    "在复杂项目中，你更倾向于：",
                    "面对灵活需求时，你更愿意：",
                    "在长期目标中，你更关注："
                ]
            }
        }
        
        self.option_templates = {
            "EI": {
                "E": ["与很多人交流", "主动参与讨论", "寻求外部刺激", "快速做出决定"],
                "I": ["与少数人深入交流", "独立思考", "寻求内心平静", "仔细考虑后决定"]
            },
            "SN": {
                "S": ["具体的事实", "实际的经验", "细节和步骤", "现实的应用"],
                "N": ["抽象的概念", "可能的联系", "整体和模式", "未来的可能性"]
            },
            "TF": {
                "T": ["逻辑分析", "客观标准", "公平原则", "理性判断"],
                "F": ["个人感受", "主观价值", "和谐关系", "情感考虑"]
            },
            "JP": {
                "J": ["提前计划", "按计划执行", "确定的时间表", "结构化的方式"],
                "P": ["保持灵活", "适应变化", "开放的时间表", "灵活的方式"]
            }
        }
    
    def generate_question_bank(self, bank_type: str = "standard") -> QuestionBank:
        """生成MBTI题库"""
        configs = {
            "quick": {"total": 48, "type": "体验版"},
            "standard": {"total": 93, "type": "专业版"},
            "comprehensive": {"total": 200, "type": "完整版"}
        }
        
        config = configs.get(bank_type, configs["standard"])
        questions = []
        
        # 按维度分配题目数量
        questions_per_dimension = config["total"] // 4
        remaining_questions = config["total"] % 4
        
        dimension_counts = {
            "EI": questions_per_dimension + (1 if remaining_questions > 0 else 0),
            "SN": questions_per_dimension + (1 if remaining_questions > 1 else 0),
            "TF": questions_per_dimension + (1 if remaining_questions > 2 else 0),
            "JP": questions_per_dimension
        }
        
        question_id = 1
        
        for dimension, count in dimension_counts.items():
            for i in range(count):
                question = self._generate_question(question_id, dimension, bank_type)
                questions.append(question)
                question_id += 1
        
        # 随机打乱题目顺序
        random.shuffle(questions)
        
        # 重新分配ID
        for i, question in enumerate(questions, 1):
            question.id = i
        
        return QuestionBank(
            name=f"MBTI {config['type']}题库",
            version="v1.0",
            total_questions=len(questions),
            questions=questions,
            dimensions=dimension_counts,
            created_at=datetime.now()
        )
    
    def _generate_question(self, question_id: int, dimension: str, bank_type: str) -> MBTIQuestion:
        """生成单个题目"""
        # 选择难度级别
        difficulty = self._select_difficulty(bank_type)
        
        # 选择题目模板
        templates = self.question_templates[dimension][difficulty]
        question_text = random.choice(templates)
        
        # 生成选项
        options = self._generate_options(dimension)
        
        # 选择题目类型
        question_type = self._select_question_type(bank_type)
        
        # 选择分类
        category = self._select_category(dimension)
        
        return MBTIQuestion(
            id=question_id,
            question_text=question_text,
            dimension=dimension,
            question_type=question_type,
            options=options,
            difficulty=difficulty,
            category=category,
            created_at=datetime.now()
        )
    
    def _select_difficulty(self, bank_type: str) -> str:
        """选择难度级别"""
        if bank_type == "quick":
            return random.choice(["easy", "medium"])
        elif bank_type == "comprehensive":
            return random.choice(["easy", "medium", "hard"])
        else:  # standard
            return random.choice(["medium", "hard"])
    
    def _select_question_type(self, bank_type: str) -> str:
        """选择题目类型"""
        if bank_type == "quick":
            return "simplified"
        elif bank_type == "comprehensive":
            return "advanced"
        else:
            return "standard"
    
    def _select_category(self, dimension: str) -> str:
        """选择分类"""
        categories = {
            "EI": ["personality", "social", "energy"],
            "SN": ["information", "perception", "learning"],
            "TF": ["decision", "values", "judgment"],
            "JP": ["lifestyle", "planning", "structure"]
        }
        return random.choice(categories[dimension])
    
    def _generate_options(self, dimension: str) -> List[Dict[str, Any]]:
        """生成选项"""
        options = []
        
        # 获取该维度的选项模板
        dimension_options = self.option_templates[dimension]
        
        # 为每个维度生成选项
        for pole, option_texts in dimension_options.items():
            option_text = random.choice(option_texts)
            options.append({
                "value": pole,
                "text": option_text,
                "score": 1 if pole in ["E", "S", "T", "J"] else -1
            })
        
        return options
    
    def export_question_bank(self, question_bank: QuestionBank, format: str = "json") -> str:
        """导出题库"""
        if format == "json":
            return json.dumps(question_bank.to_dict(), ensure_ascii=False, indent=2)
        elif format == "csv":
            return self._export_to_csv(question_bank)
        else:
            raise ValueError(f"不支持的格式: {format}")
    
    def _export_to_csv(self, question_bank: QuestionBank) -> str:
        """导出为CSV格式"""
        csv_lines = ["ID,题目,维度,类型,难度,分类,选项A,选项B,选项C,选项D"]
        
        for question in question_bank.questions:
            options = question.options
            csv_line = f"{question.id},{question.question_text},{question.dimension},{question.question_type},{question.difficulty},{question.category}"
            
            for option in options:
                csv_line += f",{option['text']}"
            
            csv_lines.append(csv_line)
        
        return "\n".join(csv_lines)
    
    def generate_ai_adaptive_questions(self, user_responses: List[Dict], remaining_count: int) -> List[MBTIQuestion]:
        """生成AI自适应题目 - 基于奥思MBTI的智能选题"""
        # 分析用户回答模式
        analysis = self._analyze_user_responses(user_responses)
        
        # 识别需要更多题目的维度
        unclear_dimensions = self._identify_unclear_dimensions(analysis)
        
        # 生成针对性的题目
        questions = []
        questions_per_dimension = remaining_count // max(len(unclear_dimensions), 1)
        
        for dimension in unclear_dimensions:
            for i in range(questions_per_dimension):
                question = self._generate_adaptive_question(dimension, analysis)
                questions.append(question)
        
        return questions
    
    def _analyze_user_responses(self, responses: List[Dict]) -> Dict[str, Any]:
        """分析用户回答"""
        dimension_scores = {"EI": 0, "SN": 0, "TF": 0, "JP": 0}
        dimension_counts = {"EI": 0, "SN": 0, "TF": 0, "JP": 0}
        
        for response in responses:
            dimension = response.get("dimension")
            answer = response.get("answer")
            
            if dimension in dimension_scores:
                dimension_counts[dimension] += 1
                if answer in ["E", "S", "T", "J"]:
                    dimension_scores[dimension] += 1
                else:
                    dimension_scores[dimension] -= 1
        
        return {
            "dimension_scores": dimension_scores,
            "dimension_counts": dimension_counts,
            "confidence_levels": self._calculate_confidence_levels(dimension_scores, dimension_counts)
        }
    
    def _identify_unclear_dimensions(self, analysis: Dict[str, Any]) -> List[str]:
        """识别不清晰的维度"""
        unclear = []
        confidence_levels = analysis["confidence_levels"]
        
        for dimension, confidence in confidence_levels.items():
            if confidence < 0.7:  # 置信度阈值
                unclear.append(dimension)
        
        return unclear
    
    def _calculate_confidence_levels(self, scores: Dict[str, int], counts: Dict[str, int]) -> Dict[str, float]:
        """计算置信度"""
        confidence = {}
        
        for dimension in ["EI", "SN", "TF", "JP"]:
            if counts[dimension] > 0:
                # 基于回答数量和一致性计算置信度
                consistency = abs(scores[dimension]) / counts[dimension]
                confidence[dimension] = min(consistency * (counts[dimension] / 10), 1.0)
            else:
                confidence[dimension] = 0.0
        
        return confidence
    
    def _generate_adaptive_question(self, dimension: str, analysis: Dict[str, Any]) -> MBTIQuestion:
        """生成自适应题目"""
        # 基于分析结果选择题目难度
        confidence = analysis["confidence_levels"].get(dimension, 0)
        
        if confidence < 0.3:
            difficulty = "easy"
        elif confidence < 0.6:
            difficulty = "medium"
        else:
            difficulty = "hard"
        
        # 生成题目
        question = self._generate_question(1, dimension, "standard")
        question.difficulty = difficulty
        
        return question


# ==================== 主函数和示例 ====================

def main():
    """主函数"""
    print("📚 MBTI题库生成器")
    print("版本: v1.0 (开源题库版)")
    print("基于: 开源MBTI题库 + 奥思MBTI设计思路")
    print("=" * 60)
    
    # 初始化题库生成器
    generator = MBTIQuestionBankGenerator()
    
    # 生成不同版本的题库
    print("\n📊 生成MBTI题库")
    
    for bank_type in ["quick", "standard", "comprehensive"]:
        print(f"\n🔧 生成 {bank_type} 题库...")
        question_bank = generator.generate_question_bank(bank_type)
        
        print(f"✅ {question_bank.name} 生成完成")
        print(f"   总题数: {question_bank.total_questions}")
        print(f"   维度分布: {question_bank.dimensions}")
        
        # 导出题库
        json_data = generator.export_question_bank(question_bank, "json")
        
        # 保存到文件
        filename = f"mbti_question_bank_{bank_type}.json"
        with open(filename, 'w', encoding='utf-8') as f:
            f.write(json_data)
        
        print(f"   已保存到: {filename}")
    
    # 示例：AI自适应题目生成
    print("\n🤖 AI自适应题目生成示例")
    
    # 模拟用户回答
    sample_responses = [
        {"dimension": "EI", "answer": "E"},
        {"dimension": "EI", "answer": "I"},
        {"dimension": "SN", "answer": "S"},
        {"dimension": "TF", "answer": "T"}
    ]
    
    adaptive_questions = generator.generate_ai_adaptive_questions(sample_responses, 5)
    
    print(f"✅ 生成了 {len(adaptive_questions)} 个自适应题目")
    for i, question in enumerate(adaptive_questions, 1):
        print(f"   {i}. {question.question_text} ({question.dimension})")
    
    print("\n🎉 MBTI题库生成完成！")
    print("📋 支持的功能:")
    print("  - 多版本题库生成 (48题/93题/200题)")
    print("  - AI自适应题目生成")
    print("  - 多格式导出 (JSON/CSV)")
    print("  - 基于奥思MBTI设计思路")
    print("  - 开源题库，无版权风险")


if __name__ == "__main__":
    main()
