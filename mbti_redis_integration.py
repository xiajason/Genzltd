#!/usr/bin/env python3
"""
MBTI Redis集成模块
创建时间: 2025年10月4日
版本: v1.0 (Redis集成版)
目标: 实现Redis会话管理、推荐缓存、行为数据缓存
基于: MBTI_MULTI_DATABASE_ARCHITECTURE_ANALYSIS.md
"""

import json
import redis
from typing import Dict, List, Optional, Any, Union
from dataclasses import dataclass, asdict
from datetime import datetime, timedelta
import logging
import hashlib
import uuid


# ==================== 数据模型 ====================

@dataclass
class MBTISession:
    """MBTI测试会话"""
    session_id: str
    user_id: str
    test_type: str  # quick, standard, comprehensive
    current_question: int
    answers: List[Dict[str, Any]]
    start_time: datetime
    response_patterns: Dict[str, Any]
    emotional_state: str  # 感性AI
    confidence_level: float
    flower_preference: Optional[str] = None
    emotional_resonance: Optional[float] = None
    
    def to_dict(self) -> Dict[str, Any]:
        result = asdict(self)
        result['start_time'] = self.start_time.isoformat()
        return result
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'MBTISession':
        data['start_time'] = datetime.fromisoformat(data['start_time'])
        return cls(**data)


@dataclass
class MBTIBehavior:
    """MBTI用户行为数据"""
    user_id: str
    recent_tests: List[Dict[str, Any]]
    mbti_type: Optional[str]
    confidence_level: Optional[float]
    flower_preference: Optional[str]
    emotional_resonance: Optional[float]
    last_activity: datetime
    behavior_patterns: Dict[str, Any]
    
    def to_dict(self) -> Dict[str, Any]:
        result = asdict(self)
        result['last_activity'] = self.last_activity.isoformat()
        return result
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'MBTIBehavior':
        data['last_activity'] = datetime.fromisoformat(data['last_activity'])
        return cls(**data)


@dataclass
class MBTIRecommendation:
    """MBTI推荐数据"""
    user_id: str
    career_matches: List[Dict[str, Any]]
    compatible_types: List[Dict[str, Any]]
    flower_suggestions: List[Dict[str, Any]]
    relationship_advice: List[Dict[str, Any]]
    generated_at: datetime
    cache_ttl: int = 3600  # 1小时
    
    def to_dict(self) -> Dict[str, Any]:
        result = asdict(self)
        result['generated_at'] = self.generated_at.isoformat()
        return result
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'MBTIRecommendation':
        data['generated_at'] = datetime.fromisoformat(data['generated_at'])
        return cls(**data)


@dataclass
class MBTIAITask:
    """MBTI AI分析任务"""
    task_id: str
    user_id: str
    task_type: str  # personality_analysis, flower_matching, career_recommendation
    status: str  # pending, running, completed, failed
    created_at: datetime
    parameters: Dict[str, Any]
    result: Optional[Dict[str, Any]] = None
    error_message: Optional[str] = None
    
    def to_dict(self) -> Dict[str, Any]:
        result = asdict(self)
        result['created_at'] = self.created_at.isoformat()
        return result
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'MBTIAITask':
        data['created_at'] = datetime.fromisoformat(data['created_at'])
        return cls(**data)


# ==================== Redis集成管理器 ====================

class MBTIRedisManager:
    """MBTI Redis集成管理器"""
    
    def __init__(self, host: str = 'localhost', port: int = 6379, db: int = 0, password: Optional[str] = None):
        self.host = host
        self.port = port
        self.db = db
        self.password = password
        self.redis_client = None
        self.logger = logging.getLogger(__name__)
        self.setup_logging()
    
    def setup_logging(self):
        """设置日志"""
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
    
    def connect(self) -> bool:
        """连接Redis"""
        try:
            self.redis_client = redis.Redis(
                host=self.host,
                port=self.port,
                db=self.db,
                password=self.password,
                decode_responses=True
            )
            # 测试连接
            self.redis_client.ping()
            self.logger.info("✅ Redis连接成功")
            return True
        except Exception as e:
            self.logger.error(f"❌ Redis连接失败: {str(e)}")
            return False
    
    def disconnect(self):
        """断开Redis连接"""
        if self.redis_client:
            try:
                self.redis_client.close()
                self.logger.info("✅ Redis连接已关闭")
            except Exception as e:
                self.logger.error(f"❌ Redis断开连接失败: {str(e)}")
    
    # ==================== 会话管理 ====================
    
    def create_mbti_session(self, user_id: str, test_type: str = "quick") -> MBTISession:
        """创建MBTI测试会话"""
        session_id = str(uuid.uuid4())
        session = MBTISession(
            session_id=session_id,
            user_id=user_id,
            test_type=test_type,
            current_question=0,
            answers=[],
            start_time=datetime.now(),
            response_patterns={},
            emotional_state="neutral",
            confidence_level=0.0
        )
        
        # 保存到Redis
        key = f"user:mbti:session:{session_id}"
        self.redis_client.setex(
            key,
            3600,  # 1小时过期
            json.dumps(session.to_dict())
        )
        
        # 更新用户当前会话
        user_session_key = f"user:mbti:current_session:{user_id}"
        self.redis_client.setex(user_session_key, 3600, session_id)
        
        self.logger.info(f"✅ 创建MBTI会话: {session_id} for user: {user_id}")
        return session
    
    def get_mbti_session(self, session_id: str) -> Optional[MBTISession]:
        """获取MBTI测试会话"""
        key = f"user:mbti:session:{session_id}"
        data = self.redis_client.get(key)
        
        if data:
            try:
                session_data = json.loads(data)
                return MBTISession.from_dict(session_data)
            except Exception as e:
                self.logger.error(f"❌ 解析会话数据失败: {str(e)}")
                return None
        return None
    
    def update_mbti_session(self, session: MBTISession) -> bool:
        """更新MBTI测试会话"""
        try:
            key = f"user:mbti:session:{session.session_id}"
            self.redis_client.setex(
                key,
                3600,  # 1小时过期
                json.dumps(session.to_dict())
            )
            self.logger.info(f"✅ 更新MBTI会话: {session.session_id}")
            return True
        except Exception as e:
            self.logger.error(f"❌ 更新会话失败: {str(e)}")
            return False
    
    def submit_answer(self, session_id: str, question_id: int, answer: str, response_time: float) -> bool:
        """提交答案"""
        session = self.get_mbti_session(session_id)
        if not session:
            return False
        
        # 更新答案
        session.answers.append({
            "question_id": question_id,
            "answer": answer,
            "response_time": response_time,
            "timestamp": datetime.now().isoformat()
        })
        
        # 更新当前问题
        session.current_question = question_id + 1
        
        # 分析响应模式
        session.response_patterns = self._analyze_response_patterns(session.answers)
        
        # 更新情感状态
        session.emotional_state = self._analyze_emotional_state(session.answers)
        
        return self.update_mbti_session(session)
    
    def complete_mbti_session(self, session_id: str, mbti_result: str, confidence: float, flower_preference: str = None) -> bool:
        """完成MBTI测试会话"""
        session = self.get_mbti_session(session_id)
        if not session:
            return False
        
        # 更新会话结果
        session.mbti_type = mbti_result
        session.confidence_level = confidence
        session.flower_preference = flower_preference
        session.emotional_resonance = self._calculate_emotional_resonance(session.answers, mbti_result)
        
        # 保存到Redis
        self.update_mbti_session(session)
        
        # 更新用户行为数据
        self._update_user_behavior(session.user_id, session)
        
        self.logger.info(f"✅ 完成MBTI会话: {session_id}, 结果: {mbti_result}")
        return True
    
    # ==================== 行为数据管理 ====================
    
    def get_user_behavior(self, user_id: str) -> Optional[MBTIBehavior]:
        """获取用户行为数据"""
        key = f"user:mbti:behavior:{user_id}"
        data = self.redis_client.get(key)
        
        if data:
            try:
                behavior_data = json.loads(data)
                return MBTIBehavior.from_dict(behavior_data)
            except Exception as e:
                self.logger.error(f"❌ 解析行为数据失败: {str(e)}")
                return None
        return None
    
    def update_user_behavior(self, user_id: str, behavior: MBTIBehavior) -> bool:
        """更新用户行为数据"""
        try:
            key = f"user:mbti:behavior:{user_id}"
            self.redis_client.setex(
                key,
                86400,  # 24小时过期
                json.dumps(behavior.to_dict())
            )
            self.logger.info(f"✅ 更新用户行为数据: {user_id}")
            return True
        except Exception as e:
            self.logger.error(f"❌ 更新行为数据失败: {str(e)}")
            return False
    
    def _update_user_behavior(self, user_id: str, session: MBTISession):
        """更新用户行为数据"""
        behavior = self.get_user_behavior(user_id)
        if not behavior:
            behavior = MBTIBehavior(
                user_id=user_id,
                recent_tests=[],
                mbti_type=None,
                confidence_level=None,
                flower_preference=None,
                emotional_resonance=None,
                last_activity=datetime.now(),
                behavior_patterns={}
            )
        
        # 更新测试历史
        behavior.recent_tests.append({
            "session_id": session.session_id,
            "test_type": session.test_type,
            "mbti_result": session.mbti_type,
            "confidence": session.confidence_level,
            "completion_time": (datetime.now() - session.start_time).total_seconds(),
            "emotional_state": session.emotional_state
        })
        
        # 保持最近10次测试
        if len(behavior.recent_tests) > 10:
            behavior.recent_tests = behavior.recent_tests[-10:]
        
        # 更新MBTI类型
        if session.mbti_type:
            behavior.mbti_type = session.mbti_type
            behavior.confidence_level = session.confidence_level
            behavior.flower_preference = session.flower_preference
            behavior.emotional_resonance = session.emotional_resonance
        
        # 更新行为模式
        behavior.behavior_patterns = self._analyze_behavior_patterns(behavior.recent_tests)
        behavior.last_activity = datetime.now()
        
        self.update_user_behavior(user_id, behavior)
    
    # ==================== 推荐缓存管理 ====================
    
    def get_recommendations(self, user_id: str) -> Optional[MBTIRecommendation]:
        """获取用户推荐数据"""
        key = f"mbti:recommendations:{user_id}"
        data = self.redis_client.get(key)
        
        if data:
            try:
                rec_data = json.loads(data)
                return MBTIRecommendation.from_dict(rec_data)
            except Exception as e:
                self.logger.error(f"❌ 解析推荐数据失败: {str(e)}")
                return None
        return None
    
    def cache_recommendations(self, user_id: str, recommendations: MBTIRecommendation) -> bool:
        """缓存推荐数据"""
        try:
            key = f"mbti:recommendations:{user_id}"
            self.redis_client.setex(
                key,
                recommendations.cache_ttl,
                json.dumps(recommendations.to_dict())
            )
            self.logger.info(f"✅ 缓存推荐数据: {user_id}")
            return True
        except Exception as e:
            self.logger.error(f"❌ 缓存推荐数据失败: {str(e)}")
            return False
    
    def generate_recommendations(self, user_id: str, mbti_type: str) -> MBTIRecommendation:
        """生成推荐数据"""
        # 职业匹配推荐
        career_matches = self._get_career_matches(mbti_type)
        
        # 兼容类型推荐
        compatible_types = self._get_compatible_types(mbti_type)
        
        # 花卉建议
        flower_suggestions = self._get_flower_suggestions(mbti_type)
        
        # 关系建议
        relationship_advice = self._get_relationship_advice(mbti_type)
        
        recommendations = MBTIRecommendation(
            user_id=user_id,
            career_matches=career_matches,
            compatible_types=compatible_types,
            flower_suggestions=flower_suggestions,
            relationship_advice=relationship_advice,
            generated_at=datetime.now()
        )
        
        # 缓存推荐数据
        self.cache_recommendations(user_id, recommendations)
        
        return recommendations
    
    # ==================== AI任务管理 ====================
    
    def create_ai_task(self, user_id: str, task_type: str, parameters: Dict[str, Any]) -> MBTIAITask:
        """创建AI分析任务"""
        task_id = str(uuid.uuid4())
        task = MBTIAITask(
            task_id=task_id,
            user_id=user_id,
            task_type=task_type,
            status="pending",
            created_at=datetime.now(),
            parameters=parameters
        )
        
        # 保存到Redis
        key = f"mbti:ai_tasks:{task_id}"
        self.redis_client.setex(
            key,
            3600,  # 1小时过期
            json.dumps(task.to_dict())
        )
        
        # 添加到任务队列
        queue_key = "mbti:ai_tasks"
        self.redis_client.lpush(queue_key, task_id)
        
        self.logger.info(f"✅ 创建AI任务: {task_id} for user: {user_id}")
        return task
    
    def get_ai_task(self, task_id: str) -> Optional[MBTIAITask]:
        """获取AI任务"""
        key = f"mbti:ai_tasks:{task_id}"
        data = self.redis_client.get(key)
        
        if data:
            try:
                task_data = json.loads(data)
                return MBTIAITask.from_dict(task_data)
            except Exception as e:
                self.logger.error(f"❌ 解析任务数据失败: {str(e)}")
                return None
        return None
    
    def update_ai_task(self, task: MBTIAITask) -> bool:
        """更新AI任务"""
        try:
            key = f"mbti:ai_tasks:{task.task_id}"
            self.redis_client.setex(
                key,
                3600,  # 1小时过期
                json.dumps(task.to_dict())
            )
            self.logger.info(f"✅ 更新AI任务: {task.task_id}")
            return True
        except Exception as e:
            self.logger.error(f"❌ 更新任务失败: {str(e)}")
            return False
    
    def get_next_ai_task(self) -> Optional[MBTIAITask]:
        """获取下一个AI任务"""
        queue_key = "mbti:ai_tasks"
        task_id = self.redis_client.rpop(queue_key)
        
        if task_id:
            return self.get_ai_task(task_id)
        return None
    
    # ==================== 辅助方法 ====================
    
    def _analyze_response_patterns(self, answers: List[Dict[str, Any]]) -> Dict[str, Any]:
        """分析响应模式"""
        if not answers:
            return {}
        
        response_times = [answer.get('response_time', 0) for answer in answers]
        avg_response_time = sum(response_times) / len(response_times) if response_times else 0
        
        # 分析答案分布
        answer_distribution = {}
        for answer in answers:
            ans = answer.get('answer', '')
            answer_distribution[ans] = answer_distribution.get(ans, 0) + 1
        
        return {
            "total_answers": len(answers),
            "avg_response_time": avg_response_time,
            "answer_distribution": answer_distribution,
            "consistency_score": self._calculate_consistency_score(answers)
        }
    
    def _analyze_emotional_state(self, answers: List[Dict[str, Any]]) -> str:
        """分析情感状态"""
        if not answers:
            return "neutral"
        
        # 基于答案内容分析情感状态
        emotional_indicators = {
            "positive": ["A", "B", "C", "D"],  # 示例
            "negative": ["E", "F", "G", "H"],  # 示例
            "neutral": ["I", "J", "K", "L"]   # 示例
        }
        
        positive_count = 0
        negative_count = 0
        
        for answer in answers:
            ans = answer.get('answer', '')
            if ans in emotional_indicators["positive"]:
                positive_count += 1
            elif ans in emotional_indicators["negative"]:
                negative_count += 1
        
        if positive_count > negative_count:
            return "positive"
        elif negative_count > positive_count:
            return "negative"
        else:
            return "neutral"
    
    def _calculate_emotional_resonance(self, answers: List[Dict[str, Any]], mbti_type: str) -> float:
        """计算情感共鸣度"""
        # 基于答案和MBTI类型计算情感共鸣度
        base_resonance = 0.5
        
        # 根据答案一致性调整
        consistency_score = self._calculate_consistency_score(answers)
        
        # 根据MBTI类型调整
        type_resonance = {
            "INTJ": 0.8, "INTP": 0.7, "ENTJ": 0.9, "ENTP": 0.6,
            "INFJ": 0.85, "INFP": 0.75, "ENFJ": 0.9, "ENFP": 0.7,
            "ISTJ": 0.8, "ISFJ": 0.85, "ESTJ": 0.9, "ESFJ": 0.85,
            "ISTP": 0.7, "ISFP": 0.75, "ESTP": 0.8, "ESFP": 0.7
        }
        
        type_factor = type_resonance.get(mbti_type, 0.5)
        
        return min(base_resonance + (consistency_score * 0.3) + (type_factor * 0.2), 1.0)
    
    def _calculate_consistency_score(self, answers: List[Dict[str, Any]]) -> float:
        """计算一致性分数"""
        if len(answers) < 2:
            return 1.0
        
        # 计算答案的一致性
        answer_values = [answer.get('answer', '') for answer in answers]
        unique_answers = len(set(answer_values))
        total_answers = len(answer_values)
        
        consistency = 1.0 - (unique_answers / total_answers)
        return max(consistency, 0.0)
    
    def _analyze_behavior_patterns(self, recent_tests: List[Dict[str, Any]]) -> Dict[str, Any]:
        """分析行为模式"""
        if not recent_tests:
            return {}
        
        # 分析测试频率
        test_frequency = len(recent_tests)
        
        # 分析完成时间
        completion_times = [test.get('completion_time', 0) for test in recent_tests]
        avg_completion_time = sum(completion_times) / len(completion_times) if completion_times else 0
        
        # 分析情感状态分布
        emotional_states = [test.get('emotional_state', 'neutral') for test in recent_tests]
        emotional_distribution = {}
        for state in emotional_states:
            emotional_distribution[state] = emotional_distribution.get(state, 0) + 1
        
        return {
            "test_frequency": test_frequency,
            "avg_completion_time": avg_completion_time,
            "emotional_distribution": emotional_distribution,
            "preferred_test_type": self._get_preferred_test_type(recent_tests)
        }
    
    def _get_preferred_test_type(self, recent_tests: List[Dict[str, Any]]) -> str:
        """获取偏好的测试类型"""
        if not recent_tests:
            return "quick"
        
        test_types = [test.get('test_type', 'quick') for test in recent_tests]
        type_counts = {}
        for test_type in test_types:
            type_counts[test_type] = type_counts.get(test_type, 0) + 1
        
        return max(type_counts, key=type_counts.get)
    
    def _get_career_matches(self, mbti_type: str) -> List[Dict[str, Any]]:
        """获取职业匹配推荐"""
        # 基于MBTI类型的职业匹配
        career_matches = {
            "INTJ": [
                {"career": "软件工程师", "match_score": 0.92, "reasoning": "逻辑思维强、独立工作能力优秀"},
                {"career": "产品经理", "match_score": 0.88, "reasoning": "战略思维、系统规划能力"},
                {"career": "数据分析师", "match_score": 0.85, "reasoning": "分析能力强、喜欢深度思考"}
            ],
            "INTP": [
                {"career": "研究员", "match_score": 0.95, "reasoning": "好奇心强、喜欢探索未知"},
                {"career": "系统架构师", "match_score": 0.90, "reasoning": "逻辑思维、创新设计能力"},
                {"career": "咨询师", "match_score": 0.80, "reasoning": "分析问题、提供解决方案"}
            ]
        }
        
        return career_matches.get(mbti_type, [])
    
    def _get_compatible_types(self, mbti_type: str) -> List[Dict[str, Any]]:
        """获取兼容类型推荐"""
        # 基于MBTI类型的兼容性
        compatible_types = {
            "INTJ": [
                {"type": "ENFP", "compatibility": 0.85, "relationship": "理想伴侣"},
                {"type": "ENTP", "compatibility": 0.80, "relationship": "智力伙伴"},
                {"type": "INFJ", "compatibility": 0.75, "relationship": "深度连接"}
            ],
            "INTP": [
                {"type": "ENTJ", "compatibility": 0.80, "relationship": "智力伙伴"},
                {"type": "ENFP", "compatibility": 0.75, "relationship": "互补关系"},
                {"type": "INFP", "compatibility": 0.70, "relationship": "深度理解"}
            ]
        }
        
        return compatible_types.get(mbti_type, [])
    
    def _get_flower_suggestions(self, mbti_type: str) -> List[Dict[str, Any]]:
        """获取花卉建议"""
        # 基于MBTI类型的花卉建议
        flower_suggestions = {
            "INTJ": [
                {"flower": "白色菊花", "match_score": 0.95, "personality": "坚韧、可靠、务实"},
                {"flower": "紫色菊花", "match_score": 0.90, "personality": "智慧、独立、创新"}
            ],
            "INTP": [
                {"flower": "紫色菊花", "match_score": 0.95, "personality": "智慧、独立、创新"},
                {"flower": "蓝色风信子", "match_score": 0.88, "personality": "洞察、理想主义、同理心"}
            ]
        }
        
        return flower_suggestions.get(mbti_type, [])
    
    def _get_relationship_advice(self, mbti_type: str) -> List[Dict[str, Any]]:
        """获取关系建议"""
        # 基于MBTI类型的关系建议
        relationship_advice = {
            "INTJ": [
                {"advice": "直接、逻辑的沟通方式", "type": "communication"},
                {"advice": "需要独处时间进行深度思考", "type": "emotional_needs"},
                {"advice": "理性分析、系统解决冲突", "type": "conflict_resolution"}
            ],
            "INTP": [
                {"advice": "深度对话、知识分享", "type": "communication"},
                {"advice": "需要独立思考空间", "type": "emotional_needs"},
                {"advice": "逻辑分析、客观讨论", "type": "conflict_resolution"}
            ]
        }
        
        return relationship_advice.get(mbti_type, [])


# ==================== 主函数和示例 ====================

def main():
    """主函数"""
    print("🔌 MBTI Redis集成模块")
    print("版本: v1.0 (Redis集成版)")
    print("目标: 实现Redis会话管理、推荐缓存、行为数据缓存")
    print("=" * 60)
    
    # 初始化Redis管理器
    redis_manager = MBTIRedisManager()
    
    try:
        # 连接Redis
        if not redis_manager.connect():
            print("❌ Redis连接失败")
            return
        
        # 测试会话管理
        print("\n🧪 测试会话管理...")
        session = redis_manager.create_mbti_session("user_123", "quick")
        print(f"✅ 创建会话: {session.session_id}")
        
        # 测试答案提交
        print("\n📝 测试答案提交...")
        redis_manager.submit_answer(session.session_id, 1, "A", 2.5)
        redis_manager.submit_answer(session.session_id, 2, "B", 3.0)
        print("✅ 答案提交成功")
        
        # 测试会话完成
        print("\n🎯 测试会话完成...")
        redis_manager.complete_mbti_session(session.session_id, "INTJ", 0.95, "白色菊花")
        print("✅ 会话完成")
        
        # 测试推荐生成
        print("\n💡 测试推荐生成...")
        recommendations = redis_manager.generate_recommendations("user_123", "INTJ")
        print(f"✅ 生成推荐: {len(recommendations.career_matches)}个职业匹配")
        
        # 测试AI任务
        print("\n🤖 测试AI任务...")
        task = redis_manager.create_ai_task("user_123", "personality_analysis", {"mbti_type": "INTJ"})
        print(f"✅ 创建AI任务: {task.task_id}")
        
        # 测试行为数据
        print("\n📊 测试行为数据...")
        behavior = redis_manager.get_user_behavior("user_123")
        if behavior:
            print(f"✅ 获取行为数据: {behavior.mbti_type}")
        
        print("\n🎉 MBTI Redis集成测试完成！")
        
    except Exception as e:
        print(f"❌ 测试失败: {str(e)}")
    finally:
        # 断开连接
        redis_manager.disconnect()
    
    print("\n📋 支持的功能:")
    print("  - 会话管理")
    print("  - 行为数据缓存")
    print("  - 推荐缓存")
    print("  - AI任务队列")
    print("  - 实时数据存储")


if __name__ == "__main__":
    main()
