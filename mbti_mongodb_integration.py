#!/usr/bin/env python3
"""
MBTI MongoDB集成模块
创建时间: 2025年10月4日
版本: v1.0 (MongoDB集成版)
目标: 实现MongoDB文档存储、完整报告、历史数据
基于: MBTI_MULTI_DATABASE_ARCHITECTURE_ANALYSIS.md
"""

import json
from typing import Dict, List, Optional, Any, Dict as TypedDict
from dataclasses import dataclass, asdict
from datetime import datetime
import logging
import uuid
from pymongo import MongoClient
from pymongo.collection import Collection
from pymongo.database import Database
from bson import ObjectId


# ==================== 数据模型 ====================

@dataclass
class MBTIReport:
    """MBTI完整报告"""
    user_id: str
    mbti_type: str
    test_date: datetime
    confidence_score: float
    dimensions: Dict[str, Any]
    flower_personality: Dict[str, Any]
    career_recommendations: List[Dict[str, Any]]
    relationship_advice: Dict[str, Any]
    personality_insights: Dict[str, Any]
    ai_analysis: Dict[str, Any]
    
    def to_dict(self) -> Dict[str, Any]:
        result = asdict(self)
        result['test_date'] = self.test_date.isoformat()
        return result
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'MBTIReport':
        data['test_date'] = datetime.fromisoformat(data['test_date'])
        return cls(**data)


@dataclass
class MBTITestHistory:
    """MBTI测试历史"""
    user_id: str
    test_id: str
    test_type: str
    test_date: datetime
    result: str
    confidence: float
    emotional_state_at_test: str
    completion_time_seconds: int
    answers: List[Dict[str, Any]]
    session_data: Dict[str, Any]
    
    def to_dict(self) -> Dict[str, Any]:
        result = asdict(self)
        result['test_date'] = self.test_date.isoformat()
        return result
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'MBTITestHistory':
        data['test_date'] = datetime.fromisoformat(data['test_date'])
        return cls(**data)


@dataclass
class MBTISocialConnection:
    """MBTI社交连接"""
    user_id: str
    mbti_type: str
    connections: List[Dict[str, Any]]
    social_preferences: Dict[str, Any]
    network_analysis: Dict[str, Any]
    
    def to_dict(self) -> Dict[str, Any]:
        return asdict(self)
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'MBTISocialConnection':
        return cls(**data)


@dataclass
class MBTIEmotionalPattern:
    """MBTI情感模式"""
    user_id: str
    mbti_type: str
    emotional_patterns: Dict[str, Any]
    stress_responses: Dict[str, Any]
    emotional_triggers: List[str]
    coping_strategies: List[str]
    emotional_development: Dict[str, Any]
    
    def to_dict(self) -> Dict[str, Any]:
        return asdict(self)
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'MBTIEmotionalPattern':
        return cls(**data)


# ==================== MongoDB集成管理器 ====================

class MBTIMongoDBManager:
    """MBTI MongoDB集成管理器"""
    
    def __init__(self, host: str = 'localhost', port: int = 27017, database: str = 'mbti_db', username: Optional[str] = None, password: Optional[str] = None):
        self.host = host
        self.port = port
        self.database_name = database
        self.username = username
        self.password = password
        self.client: Optional[MongoClient] = None
        self.database: Optional[Database] = None
        self.logger = logging.getLogger(__name__)
        self.setup_logging()
    
    def setup_logging(self):
        """设置日志"""
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
    
    def connect(self) -> bool:
        """连接MongoDB"""
        try:
            # 构建连接字符串
            if self.username and self.password:
                connection_string = f"mongodb://{self.username}:{self.password}@{self.host}:{self.port}/{self.database_name}"
            else:
                connection_string = f"mongodb://{self.host}:{self.port}/{self.database_name}"
            
            self.client = MongoClient(connection_string)
            self.database = self.client[self.database_name]
            
            # 测试连接
            self.client.admin.command('ping')
            self.logger.info("✅ MongoDB连接成功")
            return True
        except Exception as e:
            self.logger.error(f"❌ MongoDB连接失败: {str(e)}")
            return False
    
    def disconnect(self):
        """断开MongoDB连接"""
        if self.client:
            try:
                self.client.close()
                self.logger.info("✅ MongoDB连接已关闭")
            except Exception as e:
                self.logger.error(f"❌ MongoDB断开连接失败: {str(e)}")
    
    # ==================== 用户MBTI报告管理 ====================
    
    def create_mbti_report(self, report: MBTIReport) -> str:
        """创建MBTI完整报告"""
        try:
            collection = self.database['user_mbti_reports']
            report_data = report.to_dict()
            report_data['_id'] = str(uuid.uuid4())
            report_data['created_at'] = datetime.now().isoformat()
            
            result = collection.insert_one(report_data)
            self.logger.info(f"✅ 创建MBTI报告: {result.inserted_id}")
            return str(result.inserted_id)
        except Exception as e:
            self.logger.error(f"❌ 创建MBTI报告失败: {str(e)}")
            return None
    
    def get_mbti_report(self, user_id: str) -> Optional[MBTIReport]:
        """获取用户最新MBTI报告"""
        try:
            collection = self.database['user_mbti_reports']
            report_data = collection.find_one(
                {"user_id": user_id},
                sort=[("created_at", -1)]
            )
            
            if report_data:
                # 移除MongoDB的_id字段
                report_data.pop('_id', None)
                report_data.pop('created_at', None)
                return MBTIReport.from_dict(report_data)
            return None
        except Exception as e:
            self.logger.error(f"❌ 获取MBTI报告失败: {str(e)}")
            return None
    
    def get_mbti_reports_by_type(self, mbti_type: str) -> List[MBTIReport]:
        """根据MBTI类型获取报告"""
        try:
            collection = self.database['user_mbti_reports']
            reports_data = collection.find({"mbti_type": mbti_type})
            
            reports = []
            for report_data in reports_data:
                report_data.pop('_id', None)
                report_data.pop('created_at', None)
                reports.append(MBTIReport.from_dict(report_data))
            
            return reports
        except Exception as e:
            self.logger.error(f"❌ 获取MBTI报告失败: {str(e)}")
            return []
    
    def update_mbti_report(self, user_id: str, updates: Dict[str, Any]) -> bool:
        """更新MBTI报告"""
        try:
            collection = self.database['user_mbti_reports']
            updates['updated_at'] = datetime.now().isoformat()
            
            result = collection.update_one(
                {"user_id": user_id},
                {"$set": updates}
            )
            
            if result.modified_count > 0:
                self.logger.info(f"✅ 更新MBTI报告: {user_id}")
                return True
            return False
        except Exception as e:
            self.logger.error(f"❌ 更新MBTI报告失败: {str(e)}")
            return False
    
    # ==================== 测试历史管理 ====================
    
    def create_test_history(self, history: MBTITestHistory) -> str:
        """创建测试历史记录"""
        try:
            collection = self.database['user_mbti_test_history']
            history_data = history.to_dict()
            history_data['_id'] = str(uuid.uuid4())
            history_data['created_at'] = datetime.now().isoformat()
            
            result = collection.insert_one(history_data)
            self.logger.info(f"✅ 创建测试历史: {result.inserted_id}")
            return str(result.inserted_id)
        except Exception as e:
            self.logger.error(f"❌ 创建测试历史失败: {str(e)}")
            return None
    
    def get_user_test_history(self, user_id: str, limit: int = 10) -> List[MBTITestHistory]:
        """获取用户测试历史"""
        try:
            collection = self.database['user_mbti_test_history']
            history_data = collection.find(
                {"user_id": user_id},
                sort=[("test_date", -1)]
            ).limit(limit)
            
            histories = []
            for history in history_data:
                history.pop('_id', None)
                history.pop('created_at', None)
                histories.append(MBTITestHistory.from_dict(history))
            
            return histories
        except Exception as e:
            self.logger.error(f"❌ 获取测试历史失败: {str(e)}")
            return []
    
    def get_test_statistics(self, user_id: str) -> Dict[str, Any]:
        """获取测试统计信息"""
        try:
            collection = self.database['user_mbti_test_history']
            
            # 总测试次数
            total_tests = collection.count_documents({"user_id": user_id})
            
            # 测试类型分布
            test_type_pipeline = [
                {"$match": {"user_id": user_id}},
                {"$group": {"_id": "$test_type", "count": {"$sum": 1}}}
            ]
            test_type_distribution = list(collection.aggregate(test_type_pipeline))
            
            # 平均完成时间
            avg_completion_pipeline = [
                {"$match": {"user_id": user_id}},
                {"$group": {"_id": None, "avg_completion_time": {"$avg": "$completion_time_seconds"}}}
            ]
            avg_completion_result = list(collection.aggregate(avg_completion_pipeline))
            avg_completion_time = avg_completion_result[0]['avg_completion_time'] if avg_completion_result else 0
            
            # 情感状态分布
            emotional_state_pipeline = [
                {"$match": {"user_id": user_id}},
                {"$group": {"_id": "$emotional_state_at_test", "count": {"$sum": 1}}}
            ]
            emotional_state_distribution = list(collection.aggregate(emotional_state_pipeline))
            
            return {
                "total_tests": total_tests,
                "test_type_distribution": test_type_distribution,
                "avg_completion_time": avg_completion_time,
                "emotional_state_distribution": emotional_state_distribution
            }
        except Exception as e:
            self.logger.error(f"❌ 获取测试统计失败: {str(e)}")
            return {}
    
    # ==================== 社交连接管理 ====================
    
    def create_social_connection(self, connection: MBTISocialConnection) -> str:
        """创建社交连接"""
        try:
            collection = self.database['mbti_social_connections']
            connection_data = connection.to_dict()
            connection_data['_id'] = str(uuid.uuid4())
            connection_data['created_at'] = datetime.now().isoformat()
            
            result = collection.insert_one(connection_data)
            self.logger.info(f"✅ 创建社交连接: {result.inserted_id}")
            return str(result.inserted_id)
        except Exception as e:
            self.logger.error(f"❌ 创建社交连接失败: {str(e)}")
            return None
    
    def get_social_connections(self, user_id: str) -> Optional[MBTISocialConnection]:
        """获取用户社交连接"""
        try:
            collection = self.database['mbti_social_connections']
            connection_data = collection.find_one({"user_id": user_id})
            
            if connection_data:
                connection_data.pop('_id', None)
                connection_data.pop('created_at', None)
                return MBTISocialConnection.from_dict(connection_data)
            return None
        except Exception as e:
            self.logger.error(f"❌ 获取社交连接失败: {str(e)}")
            return None
    
    def add_connection(self, user_id: str, friend_id: str, friend_mbti: str, relationship_type: str = "friend") -> bool:
        """添加连接"""
        try:
            collection = self.database['mbti_social_connections']
            
            # 获取用户社交连接
            user_connections = collection.find_one({"user_id": user_id})
            
            if user_connections:
                # 更新现有连接
                new_connection = {
                    "friend_id": friend_id,
                    "friend_mbti": friend_mbti,
                    "relationship_type": relationship_type,
                    "interaction_frequency": "weekly",
                    "emotional_bond_strength": 0.5,  # 默认值
                    "created_at": datetime.now().isoformat()
                }
                
                result = collection.update_one(
                    {"user_id": user_id},
                    {"$push": {"connections": new_connection}}
                )
                
                if result.modified_count > 0:
                    self.logger.info(f"✅ 添加连接: {user_id} -> {friend_id}")
                    return True
            else:
                # 创建新的社交连接
                connection = MBTISocialConnection(
                    user_id=user_id,
                    mbti_type="",  # 需要从其他地方获取
                    connections=[{
                        "friend_id": friend_id,
                        "friend_mbti": friend_mbti,
                        "relationship_type": relationship_type,
                        "interaction_frequency": "weekly",
                        "emotional_bond_strength": 0.5,
                        "created_at": datetime.now().isoformat()
                    }],
                    social_preferences={},
                    network_analysis={}
                )
                
                return self.create_social_connection(connection) is not None
            
            return False
        except Exception as e:
            self.logger.error(f"❌ 添加连接失败: {str(e)}")
            return False
    
    def get_network_analysis(self, user_id: str) -> Dict[str, Any]:
        """获取网络分析"""
        try:
            collection = self.database['mbti_social_connections']
            connection_data = collection.find_one({"user_id": user_id})
            
            if not connection_data:
                return {}
            
            connections = connection_data.get('connections', [])
            
            # 分析网络特征
            total_connections = len(connections)
            mbti_distribution = {}
            relationship_types = {}
            emotional_bonds = []
            
            for connection in connections:
                friend_mbti = connection.get('friend_mbti', '')
                relationship_type = connection.get('relationship_type', '')
                emotional_bond = connection.get('emotional_bond_strength', 0)
                
                mbti_distribution[friend_mbti] = mbti_distribution.get(friend_mbti, 0) + 1
                relationship_types[relationship_type] = relationship_types.get(relationship_type, 0) + 1
                emotional_bonds.append(emotional_bond)
            
            avg_emotional_bond = sum(emotional_bonds) / len(emotional_bonds) if emotional_bonds else 0
            
            return {
                "total_connections": total_connections,
                "mbti_distribution": mbti_distribution,
                "relationship_types": relationship_types,
                "avg_emotional_bond": avg_emotional_bond,
                "network_density": total_connections / 100,  # 假设最大100个连接
                "most_common_mbti": max(mbti_distribution, key=mbti_distribution.get) if mbti_distribution else None
            }
        except Exception as e:
            self.logger.error(f"❌ 获取网络分析失败: {str(e)}")
            return {}
    
    # ==================== 情感模式管理 ====================
    
    def create_emotional_pattern(self, pattern: MBTIEmotionalPattern) -> str:
        """创建情感模式"""
        try:
            collection = self.database['mbti_emotional_patterns']
            pattern_data = pattern.to_dict()
            pattern_data['_id'] = str(uuid.uuid4())
            pattern_data['created_at'] = datetime.now().isoformat()
            
            result = collection.insert_one(pattern_data)
            self.logger.info(f"✅ 创建情感模式: {result.inserted_id}")
            return str(result.inserted_id)
        except Exception as e:
            self.logger.error(f"❌ 创建情感模式失败: {str(e)}")
            return None
    
    def get_emotional_pattern(self, user_id: str) -> Optional[MBTIEmotionalPattern]:
        """获取用户情感模式"""
        try:
            collection = self.database['mbti_emotional_patterns']
            pattern_data = collection.find_one({"user_id": user_id})
            
            if pattern_data:
                pattern_data.pop('_id', None)
                pattern_data.pop('created_at', None)
                return MBTIEmotionalPattern.from_dict(pattern_data)
            return None
        except Exception as e:
            self.logger.error(f"❌ 获取情感模式失败: {str(e)}")
            return None
    
    def update_emotional_pattern(self, user_id: str, updates: Dict[str, Any]) -> bool:
        """更新情感模式"""
        try:
            collection = self.database['mbti_emotional_patterns']
            updates['updated_at'] = datetime.now().isoformat()
            
            result = collection.update_one(
                {"user_id": user_id},
                {"$set": updates}
            )
            
            if result.modified_count > 0:
                self.logger.info(f"✅ 更新情感模式: {user_id}")
                return True
            return False
        except Exception as e:
            self.logger.error(f"❌ 更新情感模式失败: {str(e)}")
            return False
    
    # ==================== 辅助方法 ====================
    
    def create_sample_mbti_report(self, user_id: str, mbti_type: str = "INTJ") -> MBTIReport:
        """创建示例MBTI报告"""
        return MBTIReport(
            user_id=user_id,
            mbti_type=mbti_type,
            test_date=datetime.now(),
            confidence_score=0.95,
            dimensions={
                "E_I": {"score": -15, "preference": "I", "confidence": 0.92},
                "S_N": {"score": 18, "preference": "N", "confidence": 0.95},
                "T_F": {"score": 20, "preference": "T", "confidence": 0.97},
                "J_P": {"score": 16, "preference": "J", "confidence": 0.93}
            },
            flower_personality={
                "name": "白色菊花",
                "match_score": 0.95,
                "personality_description": "坚韧、可靠、务实",
                "seasonal_recommendations": {
                    "spring": ["种植指南", "花语故事"],
                    "autumn": ["赏花活动", "菊花茶配方"]
                },
                "emotional_connection": 0.88
            },
            career_recommendations=[
                {
                    "career": "软件工程师",
                    "match_score": 0.92,
                    "reasoning": "逻辑思维强、独立工作能力优秀"
                },
                {
                    "career": "产品经理",
                    "match_score": 0.88,
                    "reasoning": "战略思维、系统规划能力"
                }
            ],
            relationship_advice={
                "compatible_types": ["ENFP", "ENTP"],
                "communication_style": "直接、逻辑",
                "emotional_needs": "独处时间、深度对话",
                "conflict_resolution": "理性分析、系统解决"
            },
            personality_insights={
                "strengths": ["战略思维", "独立性", "逻辑分析"],
                "growth_areas": ["情感表达", "社交互动", "灵活性"],
                "life_advice": "平衡理性与感性，拓展社交圈"
            },
            ai_analysis={
                "model_version": "v2.0",
                "analysis_date": datetime.now().isoformat(),
                "confidence_level": 0.96,
                "behavioral_patterns": {
                    "decision_making": "理性分析为主",
                    "emotional_expression": "内敛、克制",
                    "social_interaction": "选择性社交",
                    "stress_response": "独处、深度思考"
                }
            }
        )
    
    def create_sample_test_history(self, user_id: str, test_type: str = "quick") -> MBTITestHistory:
        """创建示例测试历史"""
        return MBTITestHistory(
            user_id=user_id,
            test_id=str(uuid.uuid4()),
            test_type=test_type,
            test_date=datetime.now(),
            result="INTJ",
            confidence=0.95,
            emotional_state_at_test="calm",
            completion_time_seconds=280,
            answers=[
                {"question_id": 1, "answer": "A", "response_time": 2.5},
                {"question_id": 2, "answer": "B", "response_time": 3.0}
            ],
            session_data={
                "session_id": str(uuid.uuid4()),
                "start_time": datetime.now().isoformat(),
                "end_time": datetime.now().isoformat()
            }
        )


# ==================== 主函数和示例 ====================

def main():
    """主函数"""
    print("🗄️ MBTI MongoDB集成模块")
    print("版本: v1.0 (MongoDB集成版)")
    print("目标: 实现MongoDB文档存储、完整报告、历史数据")
    print("=" * 60)
    
    # 初始化MongoDB管理器
    mongo_manager = MBTIMongoDBManager()
    
    try:
        # 连接MongoDB
        if not mongo_manager.connect():
            print("❌ MongoDB连接失败")
            return
        
        # 测试MBTI报告
        print("\n📊 测试MBTI报告...")
        report = mongo_manager.create_sample_mbti_report("user_123", "INTJ")
        report_id = mongo_manager.create_mbti_report(report)
        print(f"✅ 创建MBTI报告: {report_id}")
        
        # 测试获取报告
        retrieved_report = mongo_manager.get_mbti_report("user_123")
        if retrieved_report:
            print(f"✅ 获取MBTI报告: {retrieved_report.mbti_type}")
        
        # 测试测试历史
        print("\n📝 测试测试历史...")
        history = mongo_manager.create_sample_test_history("user_123", "quick")
        history_id = mongo_manager.create_test_history(history)
        print(f"✅ 创建测试历史: {history_id}")
        
        # 测试获取历史
        histories = mongo_manager.get_user_test_history("user_123", 5)
        print(f"✅ 获取测试历史: {len(histories)}条记录")
        
        # 测试统计信息
        stats = mongo_manager.get_test_statistics("user_123")
        print(f"✅ 获取测试统计: {stats.get('total_tests', 0)}次测试")
        
        # 测试社交连接
        print("\n👥 测试社交连接...")
        connection = MBTISocialConnection(
            user_id="user_123",
            mbti_type="INTJ",
            connections=[],
            social_preferences={
                "group_size": "small",
                "interaction_style": "deep conversations",
                "social_energy_level": "low to moderate",
                "emotional_openness": 0.45
            },
            network_analysis={}
        )
        connection_id = mongo_manager.create_social_connection(connection)
        print(f"✅ 创建社交连接: {connection_id}")
        
        # 测试添加连接
        mongo_manager.add_connection("user_123", "user_456", "ENFP", "friend")
        print("✅ 添加连接成功")
        
        # 测试网络分析
        network_analysis = mongo_manager.get_network_analysis("user_123")
        print(f"✅ 网络分析: {network_analysis.get('total_connections', 0)}个连接")
        
        # 测试情感模式
        print("\n💭 测试情感模式...")
        emotional_pattern = MBTIEmotionalPattern(
            user_id="user_123",
            mbti_type="INTJ",
            emotional_patterns={
                "dominant_emotions": ["理性", "独立", "专注"],
                "emotional_triggers": ["混乱", "无效沟通", "缺乏逻辑"],
                "emotional_responses": ["内化", "分析", "规划"]
            },
            stress_responses={
                "primary": "独处思考",
                "secondary": "系统分析",
                "tertiary": "制定计划"
            },
            emotional_triggers=["混乱", "无效沟通", "缺乏逻辑"],
            coping_strategies=["独处", "分析问题", "制定计划"],
            emotional_development={
                "current_level": "成熟",
                "growth_areas": ["情感表达", "社交互动"],
                "development_goals": ["平衡理性与感性"]
            }
        )
        pattern_id = mongo_manager.create_emotional_pattern(emotional_pattern)
        print(f"✅ 创建情感模式: {pattern_id}")
        
        print("\n🎉 MBTI MongoDB集成测试完成！")
        
    except Exception as e:
        print(f"❌ 测试失败: {str(e)}")
    finally:
        # 断开连接
        mongo_manager.disconnect()
    
    print("\n📋 支持的功能:")
    print("  - 文档存储")
    print("  - 完整报告")
    print("  - 历史数据")
    print("  - 社交连接")
    print("  - 情感模式")


if __name__ == "__main__":
    main()
