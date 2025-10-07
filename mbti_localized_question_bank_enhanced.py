#!/usr/bin/env python3
"""
MBTI本地化题库增强版
MBTI Localized Question Bank Enhanced

基于外部MBTI测试网站分析，增强本地化题库功能
"""

import json
import random
from datetime import datetime
from typing import Dict, List, Any, Optional

class MBTILocalizedQuestionBankEnhanced:
    """MBTI本地化题库增强版"""
    
    def __init__(self):
        self.version = "v2.0 (本地化增强版)"
        self.created_at = datetime.now().isoformat()
        self.question_bank = {}
        self.cultural_questions = {}
        self.emoji_enhanced_questions = {}
        self.campus_culture_questions = {}
        self.flower_personality_questions = {}
        
        # 初始化题库
        self.initialize_question_bank()
    
    def initialize_question_bank(self):
        """初始化题库"""
        print("🌸 初始化MBTI本地化题库增强版...")
        
        # 基础MBTI题库
        self.question_bank = {
            "basic_questions": self.create_basic_questions(),
            "cultural_questions": self.create_cultural_questions(),
            "emoji_enhanced_questions": self.create_emoji_enhanced_questions(),
            "campus_culture_questions": self.create_campus_culture_questions(),
            "flower_personality_questions": self.create_flower_personality_questions()
        }
        
        print(f"✅ 题库初始化完成，包含 {len(self.question_bank)} 个分类")
    
    def create_basic_questions(self) -> List[Dict]:
        """创建基础MBTI题目"""
        return [
            {
                "id": 1,
                "question_text": "在团队合作中，你更倾向于：",
                "dimension": "EI",
                "options": [
                    {"value": "E", "text": "主动发言，积极参与讨论", "score": 1},
                    {"value": "I", "text": "仔细思考后再表达观点", "score": -1}
                ],
                "category": "basic",
                "difficulty": "easy"
            },
            {
                "id": 2,
                "question_text": "面对新信息时，你更倾向于：",
                "dimension": "SN",
                "options": [
                    {"value": "S", "text": "关注具体的事实和细节", "score": 1},
                    {"value": "N", "text": "关注可能性和潜在含义", "score": -1}
                ],
                "category": "basic",
                "difficulty": "easy"
            }
        ]
    
    def create_cultural_questions(self) -> List[Dict]:
        """创建中国文化元素题目"""
        return [
            {
                "id": 101,
                "question_text": "在春节聚会中，你更倾向于：",
                "dimension": "EI",
                "options": [
                    {"value": "E", "text": "主动与亲戚朋友聊天，活跃气氛", "score": 1},
                    {"value": "I", "text": "安静地观察，偶尔参与对话", "score": -1}
                ],
                "category": "cultural",
                "difficulty": "medium",
                "cultural_context": "春节传统"
            },
            {
                "id": 102,
                "question_text": "面对长辈的建议时，你的态度是：",
                "dimension": "TF",
                "options": [
                    {"value": "T", "text": "理性分析建议的可行性", "score": 1},
                    {"value": "F", "text": "理解长辈的关心和好意", "score": -1}
                ],
                "category": "cultural",
                "difficulty": "medium",
                "cultural_context": "孝道文化"
            },
            {
                "id": 103,
                "question_text": "在家庭聚餐时，你通常：",
                "dimension": "JP",
                "options": [
                    {"value": "J", "text": "提前规划聚餐安排", "score": 1},
                    {"value": "P", "text": "灵活应对，随性而为", "score": -1}
                ],
                "category": "cultural",
                "difficulty": "easy",
                "cultural_context": "家庭观念"
            }
        ]
    
    def create_emoji_enhanced_questions(self) -> List[Dict]:
        """创建Emoji增强题目"""
        return [
            {
                "id": 201,
                "question_text": "面对压力时，你更倾向于 😤 还是 😌？",
                "dimension": "TF",
                "options": [
                    {"value": "T", "text": "😤 理性分析问题，寻找解决方案", "score": 1},
                    {"value": "F", "text": "😌 寻求情感支持和理解", "score": -1}
                ],
                "category": "emoji_enhanced",
                "difficulty": "easy",
                "emoji_enhanced": True
            },
            {
                "id": 202,
                "question_text": "在团队合作中，你更喜欢 🎯 还是 🤝？",
                "dimension": "TF",
                "options": [
                    {"value": "T", "text": "🎯 专注于目标和效率", "score": 1},
                    {"value": "F", "text": "🤝 注重团队和谐和人际关系", "score": -1}
                ],
                "category": "emoji_enhanced",
                "difficulty": "easy",
                "emoji_enhanced": True
            },
            {
                "id": 203,
                "question_text": "面对新挑战，你的反应是 🚀 还是 🛡️？",
                "dimension": "EI",
                "options": [
                    {"value": "E", "text": "🚀 立即行动，充满激情", "score": 1},
                    {"value": "I", "text": "🛡️ 谨慎思考，做好准备", "score": -1}
                ],
                "category": "emoji_enhanced",
                "difficulty": "easy",
                "emoji_enhanced": True
            }
        ]
    
    def create_campus_culture_questions(self) -> List[Dict]:
        """创建校园文化题目"""
        return [
            {
                "id": 301,
                "question_text": "在校园活动中，你更愿意：",
                "dimension": "EI",
                "options": [
                    {"value": "E", "text": "组织活动，担任领导角色", "score": 1},
                    {"value": "I", "text": "参与活动，支持他人", "score": -1}
                ],
                "category": "campus_culture",
                "difficulty": "medium",
                "campus_context": "校园活动"
            },
            {
                "id": 302,
                "question_text": "面对学术讨论，你的风格是：",
                "dimension": "SN",
                "options": [
                    {"value": "S", "text": "基于具体案例和实证研究", "score": 1},
                    {"value": "N", "text": "探索理论可能性和创新思路", "score": -1}
                ],
                "category": "campus_culture",
                "difficulty": "medium",
                "campus_context": "学术讨论"
            },
            {
                "id": 303,
                "question_text": "在宿舍生活中，你通常：",
                "dimension": "JP",
                "options": [
                    {"value": "J", "text": "保持整洁有序的生活环境", "score": 1},
                    {"value": "P", "text": "灵活适应，随性而居", "score": -1}
                ],
                "category": "campus_culture",
                "difficulty": "easy",
                "campus_context": "宿舍生活"
            }
        ]
    
    def create_flower_personality_questions(self) -> List[Dict]:
        """创建花语花卉人格化题目"""
        return [
            {
                "id": 401,
                "question_text": "如果让你选择一种花代表自己，你会选择：",
                "dimension": "SN",
                "options": [
                    {"value": "S", "text": "🌹 玫瑰 - 经典美丽，稳定可靠", "score": 1},
                    {"value": "N", "text": "🌸 樱花 - 短暂绚烂，充满诗意", "score": -1}
                ],
                "category": "flower_personality",
                "difficulty": "easy",
                "flower_context": "花语人格化"
            },
            {
                "id": 402,
                "question_text": "在花园中，你更愿意：",
                "dimension": "EI",
                "options": [
                    {"value": "E", "text": "🌻 向日葵 - 面向阳光，积极向上", "score": 1},
                    {"value": "I", "text": "🌙 夜来香 - 静静绽放，内敛优雅", "score": -1}
                ],
                "category": "flower_personality",
                "difficulty": "easy",
                "flower_context": "花语人格化"
            },
            {
                "id": 403,
                "question_text": "面对植物，你的感受是：",
                "dimension": "TF",
                "options": [
                    {"value": "T", "text": "🌿 理性分析植物的生长规律", "score": 1},
                    {"value": "F", "text": "💚 感受植物的生命力和美好", "score": -1}
                ],
                "category": "flower_personality",
                "difficulty": "easy",
                "flower_context": "花语人格化"
            }
        ]
    
    def get_questions_by_category(self, category: str) -> List[Dict]:
        """根据分类获取题目"""
        if category in self.question_bank:
            return self.question_bank[category]
        return []
    
    def get_random_questions(self, count: int = 10, categories: List[str] = None) -> List[Dict]:
        """获取随机题目"""
        if categories is None:
            categories = ["basic_questions", "cultural_questions", "emoji_enhanced_questions"]
        
        all_questions = []
        for category in categories:
            all_questions.extend(self.get_questions_by_category(category))
        
        return random.sample(all_questions, min(count, len(all_questions)))
    
    def get_cultural_questions(self, count: int = 5) -> List[Dict]:
        """获取中国文化题目"""
        return self.get_random_questions(count, ["cultural_questions"])
    
    def get_emoji_enhanced_questions(self, count: int = 5) -> List[Dict]:
        """获取Emoji增强题目"""
        return self.get_random_questions(count, ["emoji_enhanced_questions"])
    
    def get_campus_culture_questions(self, count: int = 5) -> List[Dict]:
        """获取校园文化题目"""
        return self.get_random_questions(count, ["campus_culture_questions"])
    
    def get_flower_personality_questions(self, count: int = 5) -> List[Dict]:
        """获取花语花卉人格化题目"""
        return self.get_random_questions(count, ["flower_personality_questions"])
    
    def generate_test_session(self, test_type: str = "comprehensive") -> Dict[str, Any]:
        """生成测试会话"""
        test_configs = {
            "quick": {"questions": 20, "duration": 300, "categories": ["basic_questions", "emoji_enhanced_questions"]},
            "cultural": {"questions": 30, "duration": 450, "categories": ["cultural_questions", "campus_culture_questions"]},
            "comprehensive": {"questions": 50, "duration": 600, "categories": ["basic_questions", "cultural_questions", "emoji_enhanced_questions", "campus_culture_questions", "flower_personality_questions"]}
        }
        
        config = test_configs.get(test_type, test_configs["comprehensive"])
        questions = self.get_random_questions(config["questions"], config["categories"])
        
        return {
            "session_id": f"mbti_localized_{datetime.now().strftime('%Y%m%d_%H%M%S')}",
            "test_type": test_type,
            "total_questions": len(questions),
            "estimated_duration": config["duration"],
            "questions": questions,
            "features": {
                "cultural_adaptation": True,
                "emoji_enhanced": True,
                "campus_culture": True,
                "flower_personality": True,
                "ai_driven": True
            }
        }
    
    def export_question_bank(self, format: str = "json") -> str:
        """导出题库"""
        if format == "json":
            return json.dumps(self.question_bank, ensure_ascii=False, indent=2)
        elif format == "csv":
            # 这里可以实现CSV导出
            return "CSV export not implemented yet"
        else:
            return "Unsupported format"
    
    def get_statistics(self) -> Dict[str, Any]:
        """获取题库统计信息"""
        stats = {
            "total_questions": sum(len(questions) for questions in self.question_bank.values()),
            "categories": {
                "basic_questions": len(self.question_bank.get("basic_questions", [])),
                "cultural_questions": len(self.question_bank.get("cultural_questions", [])),
                "emoji_enhanced_questions": len(self.question_bank.get("emoji_enhanced_questions", [])),
                "campus_culture_questions": len(self.question_bank.get("campus_culture_questions", [])),
                "flower_personality_questions": len(self.question_bank.get("flower_personality_questions", []))
            },
            "dimensions": {
                "EI": len([q for questions in self.question_bank.values() for q in questions if q.get("dimension") == "EI"]),
                "SN": len([q for questions in self.question_bank.values() for q in questions if q.get("dimension") == "SN"]),
                "TF": len([q for questions in self.question_bank.values() for q in questions if q.get("dimension") == "TF"]),
                "JP": len([q for questions in self.question_bank.values() for q in questions if q.get("dimension") == "JP"])
            },
            "features": {
                "cultural_adaptation": True,
                "emoji_enhanced": True,
                "campus_culture": True,
                "flower_personality": True,
                "ai_driven": True
            }
        }
        
        return stats

def main():
    """主函数"""
    print("🌸 MBTI本地化题库增强版")
    print("=" * 50)
    
    # 创建题库实例
    question_bank = MBTILocalizedQuestionBankEnhanced()
    
    # 显示统计信息
    stats = question_bank.get_statistics()
    print(f"📊 题库统计信息:")
    print(f"   总题目数: {stats['total_questions']}")
    print(f"   分类统计: {stats['categories']}")
    print(f"   维度统计: {stats['dimensions']}")
    print(f"   特色功能: {stats['features']}")
    
    # 生成测试会话示例
    print(f"\n🧪 生成测试会话示例:")
    session = question_bank.generate_test_session("comprehensive")
    print(f"   会话ID: {session['session_id']}")
    print(f"   测试类型: {session['test_type']}")
    print(f"   题目数量: {session['total_questions']}")
    print(f"   预计时长: {session['estimated_duration']}秒")
    print(f"   特色功能: {session['features']}")
    
    # 显示题目示例
    print(f"\n📝 题目示例:")
    cultural_questions = question_bank.get_cultural_questions(2)
    for i, q in enumerate(cultural_questions, 1):
        print(f"   {i}. {q['question_text']}")
        for option in q['options']:
            print(f"      {option['value']}: {option['text']}")
        print()
    
    print("🎉 MBTI本地化题库增强版演示完成!")

if __name__ == "__main__":
    main()
