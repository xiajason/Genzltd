#!/usr/bin/env python3
"""
MBTI API模拟器
创建时间: 2025年10月4日
版本: v1.0 (API模拟版)
基于: 奥思MBTI API设计思路
目标: 模拟奥思MBTI的API接口，提供合法的题库访问
"""

import json
import asyncio
import aiohttp
from typing import Dict, List, Optional, Any
from dataclasses import dataclass, asdict
from datetime import datetime
import random


# ==================== 数据模型 ====================

@dataclass
class APIResponse:
    """API响应模型"""
    success: bool
    data: Any
    message: str
    timestamp: datetime
    request_id: str
    
    def to_dict(self) -> Dict[str, Any]:
        result = asdict(self)
        result['timestamp'] = self.timestamp.isoformat()
        return result


@dataclass
class TestSession:
    """测试会话模型"""
    session_id: str
    user_id: str
    test_type: str
    questions: List[Dict[str, Any]]
    current_question: int
    responses: List[Dict[str, Any]]
    start_time: datetime
    status: str  # active, completed, abandoned
    
    def to_dict(self) -> Dict[str, Any]:
        result = asdict(self)
        result['start_time'] = self.start_time.isoformat()
        return result


# ==================== MBTI API模拟器 ====================

class MBTIAPISimulator:
    """MBTI API模拟器 - 模拟奥思MBTI的API接口"""
    
    def __init__(self):
        self.base_url = "https://api.mbti-simulator.com"
        self.api_key = "demo_key_12345"
        self.question_banks = self._load_question_banks()
        
    def _load_question_banks(self) -> Dict[str, Any]:
        """加载题库数据"""
        try:
            # 尝试加载生成的题库
            with open('mbti_question_bank_quick.json', 'r', encoding='utf-8') as f:
                quick_bank = json.load(f)
            with open('mbti_question_bank_standard.json', 'r', encoding='utf-8') as f:
                standard_bank = json.load(f)
            with open('mbti_question_bank_comprehensive.json', 'r', encoding='utf-8') as f:
                comprehensive_bank = json.load(f)
            
            return {
                "quick": quick_bank,
                "standard": standard_bank,
                "comprehensive": comprehensive_bank
            }
        except FileNotFoundError:
            # 如果文件不存在，返回空数据
            return {
                "quick": {"questions": []},
                "standard": {"questions": []},
                "comprehensive": {"questions": []}
            }
    
    async def start_test(self, user_id: str, test_type: str = "quick") -> APIResponse:
        """开始测试 - 模拟奥思MBTI的测试开始接口"""
        try:
            # 获取题库
            question_bank = self.question_banks.get(test_type, self.question_banks["quick"])
            questions = question_bank.get("questions", [])
            
            if not questions:
                return APIResponse(
                    success=False,
                    data=None,
                    message="题库未找到",
                    timestamp=datetime.now(),
                    request_id=self._generate_request_id()
                )
            
            # 创建测试会话
            session = TestSession(
                session_id=self._generate_session_id(),
                user_id=user_id,
                test_type=test_type,
                questions=questions,
                current_question=0,
                responses=[],
                start_time=datetime.now(),
                status="active"
            )
            
            # 返回第一题
            first_question = questions[0] if questions else None
            
            return APIResponse(
                success=True,
                data={
                    "session": session.to_dict(),
                    "question": first_question,
                    "total_questions": len(questions),
                    "estimated_duration": self._get_estimated_duration(test_type)
                },
                message="测试开始成功",
                timestamp=datetime.now(),
                request_id=self._generate_request_id()
            )
            
        except Exception as e:
            return APIResponse(
                success=False,
                data=None,
                message=f"测试开始失败: {str(e)}",
                timestamp=datetime.now(),
                request_id=self._generate_request_id()
            )
    
    async def submit_answer(self, session_id: str, question_id: int, answer: str) -> APIResponse:
        """提交答案 - 模拟奥思MBTI的答案提交接口"""
        try:
            # 模拟API调用延迟
            await asyncio.sleep(0.1)
            
            # 记录答案
            response_data = {
                "session_id": session_id,
                "question_id": question_id,
                "answer": answer,
                "timestamp": datetime.now().isoformat()
            }
            
            # 模拟AI分析
            ai_analysis = self._simulate_ai_analysis(question_id, answer)
            
            return APIResponse(
                success=True,
                data={
                    "response": response_data,
                    "ai_analysis": ai_analysis,
                    "next_question": self._get_next_question(session_id, question_id),
                    "progress": self._calculate_progress(session_id, question_id)
                },
                message="答案提交成功",
                timestamp=datetime.now(),
                request_id=self._generate_request_id()
            )
            
        except Exception as e:
            return APIResponse(
                success=False,
                data=None,
                message=f"答案提交失败: {str(e)}",
                timestamp=datetime.now(),
                request_id=self._generate_request_id()
            )
    
    async def get_test_result(self, session_id: str) -> APIResponse:
        """获取测试结果 - 模拟奥思MBTI的结果获取接口"""
        try:
            # 模拟AI分析结果
            result_data = {
                "mbti_type": self._generate_mbti_type(),
                "confidence_level": random.uniform(0.8, 0.98),
                "dimension_scores": {
                    "EI": random.uniform(-1, 1),
                    "SN": random.uniform(-1, 1),
                    "TF": random.uniform(-1, 1),
                    "JP": random.uniform(-1, 1)
                },
                "personality_analysis": self._generate_personality_analysis(),
                "career_suggestions": self._generate_career_suggestions(),
                "relationship_advice": self._generate_relationship_advice(),
                "growth_recommendations": self._generate_growth_recommendations()
            }
            
            return APIResponse(
                success=True,
                data=result_data,
                message="测试结果生成成功",
                timestamp=datetime.now(),
                request_id=self._generate_request_id()
            )
            
        except Exception as e:
            return APIResponse(
                success=False,
                data=None,
                message=f"结果获取失败: {str(e)}",
                timestamp=datetime.now(),
                request_id=self._generate_request_id()
            )
    
    def _simulate_ai_analysis(self, question_id: int, answer: str) -> Dict[str, Any]:
        """模拟AI分析"""
        return {
            "response_pattern": random.choice(["intuitive", "analytical", "balanced"]),
            "confidence": random.uniform(0.6, 0.9),
            "behavioral_insights": {
                "decision_style": random.choice(["quick", "deliberate", "flexible"]),
                "thinking_pattern": random.choice(["logical", "emotional", "mixed"]),
                "communication_style": random.choice(["direct", "diplomatic", "adaptive"])
            },
            "ai_recommendations": [
                "建议在重要决定前多考虑细节",
                "可以尝试更开放地接受新想法",
                "建议在团队中发挥领导作用"
            ]
        }
    
    def _get_next_question(self, session_id: str, current_question_id: int) -> Optional[Dict[str, Any]]:
        """获取下一题"""
        # 简化处理，实际应该从会话中获取
        return {
            "question_id": current_question_id + 1,
            "question_text": "下一个问题...",
            "options": [
                {"value": "A", "text": "选项A"},
                {"value": "B", "text": "选项B"}
            ]
        }
    
    def _calculate_progress(self, session_id: str, current_question_id: int) -> Dict[str, Any]:
        """计算进度"""
        return {
            "current": current_question_id,
            "total": 48,  # 假设总题数
            "percentage": (current_question_id / 48) * 100,
            "estimated_remaining": (48 - current_question_id) * 30  # 假设每题30秒
        }
    
    def _generate_mbti_type(self) -> str:
        """生成MBTI类型"""
        types = ["INTJ", "INTP", "ENTJ", "ENTP", "INFJ", "INFP", "ENFJ", "ENFP",
                "ISTJ", "ISFJ", "ESTJ", "ESFJ", "ISTP", "ISFP", "ESTP", "ESFP"]
        return random.choice(types)
    
    def _generate_personality_analysis(self) -> Dict[str, Any]:
        """生成人格分析"""
        return {
            "strengths": ["逻辑思维", "创新能力", "领导力", "同理心"],
            "challenges": ["过于完美主义", "缺乏耐心", "难以做决定", "过于敏感"],
            "work_style": "喜欢独立工作，善于分析问题，具有创新思维",
            "communication_style": "直接而有效，喜欢深度交流",
            "motivation_factors": ["挑战性任务", "学习机会", "团队合作", "个人成长"]
        }
    
    def _generate_career_suggestions(self) -> List[Dict[str, Any]]:
        """生成职业建议"""
        careers = [
            {"name": "软件工程师", "match_score": 0.95, "reason": "逻辑思维强，适合编程"},
            {"name": "产品经理", "match_score": 0.88, "reason": "创新思维，善于规划"},
            {"name": "数据分析师", "match_score": 0.92, "reason": "分析能力强，喜欢数据"},
            {"name": "项目经理", "match_score": 0.85, "reason": "组织能力强，善于协调"}
        ]
        return random.sample(careers, 3)
    
    def _generate_relationship_advice(self) -> List[str]:
        """生成关系建议"""
        advice = [
            "在关系中保持开放和诚实",
            "学会倾听他人的观点",
            "表达自己的需求和感受",
            "给予对方足够的空间",
            "共同制定目标和计划"
        ]
        return random.sample(advice, 3)
    
    def _generate_growth_recommendations(self) -> List[str]:
        """生成成长建议"""
        recommendations = [
            "培养更好的时间管理技能",
            "学习接受不确定性",
            "提高沟通技巧",
            "发展领导能力",
            "保持学习新技能的习惯"
        ]
        return random.sample(recommendations, 3)
    
    def _get_estimated_duration(self, test_type: str) -> int:
        """获取预计时长"""
        durations = {
            "quick": 300,      # 5分钟
            "standard": 600,   # 10分钟
            "comprehensive": 1200  # 20分钟
        }
        return durations.get(test_type, 600)
    
    def _generate_session_id(self) -> str:
        """生成会话ID"""
        return f"session_{random.randint(100000, 999999)}"
    
    def _generate_request_id(self) -> str:
        """生成请求ID"""
        return f"req_{random.randint(100000, 999999)}"


# ==================== 主函数和示例 ====================

async def main():
    """主函数"""
    print("🔌 MBTI API模拟器")
    print("版本: v1.0 (API模拟版)")
    print("基于: 奥思MBTI API设计思路")
    print("=" * 60)
    
    # 初始化API模拟器
    api_simulator = MBTIAPISimulator()
    
    # 示例：开始测试
    print("\n📊 开始测试示例")
    start_response = await api_simulator.start_test("user_123", "quick")
    
    if start_response.success:
        print(f"✅ 测试开始成功")
        print(f"   会话ID: {start_response.data['session']['session_id']}")
        print(f"   总题数: {start_response.data['total_questions']}")
        print(f"   预计时长: {start_response.data['estimated_duration']}秒")
        
        # 示例：提交答案
        print("\n📝 提交答案示例")
        session_id = start_response.data['session']['session_id']
        
        for i in range(3):  # 模拟提交3个答案
            answer_response = await api_simulator.submit_answer(
                session_id, i + 1, random.choice(["A", "B", "C", "D"])
            )
            
            if answer_response.success:
                print(f"✅ 第{i+1}题答案提交成功")
                print(f"   AI分析: {answer_response.data['ai_analysis']['response_pattern']}")
                print(f"   置信度: {answer_response.data['ai_analysis']['confidence']:.2f}")
        
        # 示例：获取测试结果
        print("\n🎯 获取测试结果示例")
        result_response = await api_simulator.get_test_result(session_id)
        
        if result_response.success:
            result = result_response.data
            print(f"✅ 测试结果生成成功")
            print(f"   MBTI类型: {result['mbti_type']}")
            print(f"   置信度: {result['confidence_level']:.2f}")
            print(f"   人格分析: {result['personality_analysis']['work_style']}")
            print(f"   职业建议: {result['career_suggestions'][0]['name']}")
    
    print("\n🎉 MBTI API模拟器完成！")
    print("📋 支持的功能:")
    print("  - 测试开始接口")
    print("  - 答案提交接口")
    print("  - 结果获取接口")
    print("  - AI分析模拟")
    print("  - 个性化建议生成")
    print("  - 基于奥思MBTI设计思路")


if __name__ == "__main__":
    asyncio.run(main())
