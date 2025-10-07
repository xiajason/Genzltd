#!/usr/bin/env python3
"""
MBTI Neo4j集成模块
创建时间: 2025年10月4日
版本: v1.0 (Neo4j集成版)
目标: 实现Neo4j图结构、关系网络、推荐算法
基于: MBTI_MULTI_DATABASE_ARCHITECTURE_ANALYSIS.md
"""

import json
from typing import Dict, List, Optional, Any, Tuple
from dataclasses import dataclass, asdict
from datetime import datetime
import logging
import uuid
from neo4j import GraphDatabase
from neo4j.exceptions import ServiceUnavailable, AuthError


# ==================== 数据模型 ====================

@dataclass
class MBTITypeNode:
    """MBTI类型节点"""
    code: str
    name: str
    characteristics: str
    dimension_E_I: str
    dimension_S_N: str
    dimension_T_F: str
    dimension_J_P: str
    emotional_profile: str  # 感性AI
    
    def to_dict(self) -> Dict[str, Any]:
        return asdict(self)


@dataclass
class UserNode:
    """用户节点"""
    user_id: str
    mbti_type: str
    confidence: float
    test_date: datetime
    emotional_profile: str  # 感性AI
    personality_traits: List[str]
    
    def to_dict(self) -> Dict[str, Any]:
        result = asdict(self)
        result['test_date'] = self.test_date.isoformat()
        return result


@dataclass
class FlowerNode:
    """花卉节点"""
    name: str
    color: str
    season: str
    personality: str
    emotional_resonance: str  # 感性AI
    meaning: str
    care_instructions: List[str]
    
    def to_dict(self) -> Dict[str, Any]:
        return asdict(self)


@dataclass
class CareerNode:
    """职业节点"""
    name: str
    category: str
    required_skills: List[str]
    salary_range: str
    growth_potential: str
    work_environment: str
    
    def to_dict(self) -> Dict[str, Any]:
        return asdict(self)


@dataclass
class CompatibilityRelationship:
    """兼容性关系"""
    from_type: str
    to_type: str
    score: float
    relationship_type: str
    communication_style: str
    emotional_compatibility: float  # 感性AI
    
    def to_dict(self) -> Dict[str, Any]:
        return asdict(self)


@dataclass
class UserRelationship:
    """用户关系"""
    from_user: str
    to_user: str
    relationship_type: str
    interaction_frequency: str
    emotional_bond_strength: float  # 感性AI
    communication_quality: str
    created_at: datetime
    
    def to_dict(self) -> Dict[str, Any]:
        result = asdict(self)
        result['created_at'] = self.created_at.isoformat()
        return result


# ==================== Neo4j集成管理器 ====================

class MBTINeo4jManager:
    """MBTI Neo4j集成管理器"""
    
    def __init__(self, uri: str = "bolt://localhost:7687", username: str = "neo4j", password: str = "mbti_neo4j_2025"):
        self.uri = uri
        self.username = username
        self.password = password
        self.driver = None
        self.logger = logging.getLogger(__name__)
        self.setup_logging()
    
    def setup_logging(self):
        """设置日志"""
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
    
    def connect(self) -> bool:
        """连接Neo4j"""
        try:
            self.driver = GraphDatabase.driver(self.uri, auth=(self.username, self.password))
            # 测试连接
            with self.driver.session() as session:
                session.run("RETURN 1")
            self.logger.info("✅ Neo4j连接成功")
            return True
        except (ServiceUnavailable, AuthError) as e:
            self.logger.error(f"❌ Neo4j连接失败: {str(e)}")
            return False
        except Exception as e:
            self.logger.error(f"❌ Neo4j连接失败: {str(e)}")
            return False
    
    def disconnect(self):
        """断开Neo4j连接"""
        if self.driver:
            try:
                self.driver.close()
                self.logger.info("✅ Neo4j连接已关闭")
            except Exception as e:
                self.logger.error(f"❌ Neo4j断开连接失败: {str(e)}")
    
    # ==================== MBTI类型节点管理 ====================
    
    def create_mbti_type_node(self, mbti_type: MBTITypeNode) -> bool:
        """创建MBTI类型节点"""
        try:
            with self.driver.session() as session:
                query = """
                CREATE (m:MBTIType {
                    code: $code,
                    name: $name,
                    characteristics: $characteristics,
                    dimension_E_I: $dimension_E_I,
                    dimension_S_N: $dimension_S_N,
                    dimension_T_F: $dimension_T_F,
                    dimension_J_P: $dimension_J_P,
                    emotional_profile: $emotional_profile
                })
                """
                session.run(query, **mbti_type.to_dict())
                self.logger.info(f"✅ 创建MBTI类型节点: {mbti_type.code}")
                return True
        except Exception as e:
            self.logger.error(f"❌ 创建MBTI类型节点失败: {str(e)}")
            return False
    
    def get_mbti_type_node(self, code: str) -> Optional[MBTITypeNode]:
        """获取MBTI类型节点"""
        try:
            with self.driver.session() as session:
                query = "MATCH (m:MBTIType {code: $code}) RETURN m"
                result = session.run(query, code=code)
                record = result.single()
                
                if record:
                    node_data = dict(record["m"])
                    return MBTITypeNode(**node_data)
                return None
        except Exception as e:
            self.logger.error(f"❌ 获取MBTI类型节点失败: {str(e)}")
            return None
    
    def create_all_mbti_types(self) -> bool:
        """创建所有MBTI类型节点"""
        mbti_types = [
            MBTITypeNode("INTJ", "建筑师", "理性、独立、战略思维", "I", "N", "T", "J", "rational_dominant"),
            MBTITypeNode("INTP", "思想家", "分析、好奇、逻辑、创新", "I", "N", "T", "P", "analytical_creative"),
            MBTITypeNode("ENTJ", "指挥官", "领导、果断、目标导向", "E", "N", "T", "J", "leadership_focused"),
            MBTITypeNode("ENTP", "辩论家", "创新、灵活、辩论、冒险", "E", "N", "T", "P", "innovative_energetic"),
            MBTITypeNode("INFJ", "提倡者", "洞察、理想主义、同理心", "I", "N", "F", "J", "empathetic_visionary"),
            MBTITypeNode("INFP", "调停者", "价值观、创造力、敏感", "I", "N", "F", "P", "creative_idealist"),
            MBTITypeNode("ENFJ", "主人公", "激励、社交、同理心", "E", "N", "F", "J", "inspiring_leader"),
            MBTITypeNode("ENFP", "竞选者", "热情、创意、社交", "E", "N", "F", "P", "enthusiastic_creative"),
            MBTITypeNode("ISTJ", "物流师", "可靠、传统、实用", "I", "S", "T", "J", "reliable_practical"),
            MBTITypeNode("ISFJ", "守护者", "关怀、忠诚、实用", "I", "S", "F", "J", "caring_protector"),
            MBTITypeNode("ESTJ", "总经理", "组织、传统、实用", "E", "S", "T", "J", "organized_leader"),
            MBTITypeNode("ESFJ", "执政官", "社交、关怀、传统", "E", "S", "F", "J", "social_caregiver"),
            MBTITypeNode("ISTP", "鉴赏家", "灵活、实用、独立", "I", "S", "T", "P", "practical_adaptable"),
            MBTITypeNode("ISFP", "探险家", "艺术、敏感、灵活", "I", "S", "F", "P", "artistic_sensitive"),
            MBTITypeNode("ESTP", "企业家", "行动、社交、灵活", "E", "S", "T", "P", "action_oriented"),
            MBTITypeNode("ESFP", "表演者", "热情、社交、灵活", "E", "S", "F", "P", "enthusiastic_performer")
        ]
        
        success_count = 0
        for mbti_type in mbti_types:
            if self.create_mbti_type_node(mbti_type):
                success_count += 1
        
        self.logger.info(f"✅ 创建MBTI类型节点: {success_count}/16")
        return success_count == 16
    
    # ==================== 用户节点管理 ====================
    
    def create_user_node(self, user: UserNode) -> bool:
        """创建用户节点"""
        try:
            with self.driver.session() as session:
                query = """
                CREATE (u:User {
                    user_id: $user_id,
                    mbti_type: $mbti_type,
                    confidence: $confidence,
                    test_date: $test_date,
                    emotional_profile: $emotional_profile,
                    personality_traits: $personality_traits
                })
                """
                session.run(query, **user.to_dict())
                self.logger.info(f"✅ 创建用户节点: {user.user_id}")
                return True
        except Exception as e:
            self.logger.error(f"❌ 创建用户节点失败: {str(e)}")
            return False
    
    def get_user_node(self, user_id: str) -> Optional[UserNode]:
        """获取用户节点"""
        try:
            with self.driver.session() as session:
                query = "MATCH (u:User {user_id: $user_id}) RETURN u"
                result = session.run(query, user_id=user_id)
                record = result.single()
                
                if record:
                    node_data = dict(record["u"])
                    node_data['test_date'] = datetime.fromisoformat(node_data['test_date'])
                    return UserNode(**node_data)
                return None
        except Exception as e:
            self.logger.error(f"❌ 获取用户节点失败: {str(e)}")
            return None
    
    def connect_user_to_mbti_type(self, user_id: str, mbti_code: str) -> bool:
        """连接用户到MBTI类型"""
        try:
            with self.driver.session() as session:
                query = """
                MATCH (u:User {user_id: $user_id})
                MATCH (m:MBTIType {code: $mbti_code})
                CREATE (u)-[:HAS_MBTI_TYPE]->(m)
                """
                session.run(query, user_id=user_id, mbti_code=mbti_code)
                self.logger.info(f"✅ 连接用户到MBTI类型: {user_id} -> {mbti_code}")
                return True
        except Exception as e:
            self.logger.error(f"❌ 连接用户到MBTI类型失败: {str(e)}")
            return False
    
    # ==================== 花卉节点管理 ====================
    
    def create_flower_node(self, flower: FlowerNode) -> bool:
        """创建花卉节点"""
        try:
            with self.driver.session() as session:
                query = """
                CREATE (f:Flower {
                    name: $name,
                    color: $color,
                    season: $season,
                    personality: $personality,
                    emotional_resonance: $emotional_resonance,
                    meaning: $meaning,
                    care_instructions: $care_instructions
                })
                """
                session.run(query, **flower.to_dict())
                self.logger.info(f"✅ 创建花卉节点: {flower.name}")
                return True
        except Exception as e:
            self.logger.error(f"❌ 创建花卉节点失败: {str(e)}")
            return False
    
    def create_flower_mbti_relationship(self, mbti_code: str, flower_name: str, match_score: float) -> bool:
        """创建花卉-MBTI关系"""
        try:
            with self.driver.session() as session:
                query = """
                MATCH (m:MBTIType {code: $mbti_code})
                MATCH (f:Flower {name: $flower_name})
                CREATE (m)-[:REPRESENTED_BY {
                    match_score: $match_score,
                    personality_alignment: 'high',
                    emotional_resonance: $match_score
                }]->(f)
                """
                session.run(query, mbti_code=mbti_code, flower_name=flower_name, match_score=match_score)
                self.logger.info(f"✅ 创建花卉-MBTI关系: {mbti_code} -> {flower_name}")
                return True
        except Exception as e:
            self.logger.error(f"❌ 创建花卉-MBTI关系失败: {str(e)}")
            return False
    
    # ==================== 职业节点管理 ====================
    
    def create_career_node(self, career: CareerNode) -> bool:
        """创建职业节点"""
        try:
            with self.driver.session() as session:
                query = """
                CREATE (c:Career {
                    name: $name,
                    category: $category,
                    required_skills: $required_skills,
                    salary_range: $salary_range,
                    growth_potential: $growth_potential,
                    work_environment: $work_environment
                })
                """
                session.run(query, **career.to_dict())
                self.logger.info(f"✅ 创建职业节点: {career.name}")
                return True
        except Exception as e:
            self.logger.error(f"❌ 创建职业节点失败: {str(e)}")
            return False
    
    def create_career_mbti_relationship(self, mbti_code: str, career_name: str, match_score: float, reasoning: str) -> bool:
        """创建职业-MBTI关系"""
        try:
            with self.driver.session() as session:
                query = """
                MATCH (m:MBTIType {code: $mbti_code})
                MATCH (c:Career {name: $career_name})
                CREATE (m)-[:SUITABLE_FOR {
                    match_score: $match_score,
                    reasoning: $reasoning,
                    growth_potential: 'high'
                }]->(c)
                """
                session.run(query, mbti_code=mbti_code, career_name=career_name, match_score=match_score, reasoning=reasoning)
                self.logger.info(f"✅ 创建职业-MBTI关系: {mbti_code} -> {career_name}")
                return True
        except Exception as e:
            self.logger.error(f"❌ 创建职业-MBTI关系失败: {str(e)}")
            return False
    
    # ==================== 兼容性关系管理 ====================
    
    def create_compatibility_relationship(self, compatibility: CompatibilityRelationship) -> bool:
        """创建兼容性关系"""
        try:
            with self.driver.session() as session:
                query = """
                MATCH (m1:MBTIType {code: $from_type})
                MATCH (m2:MBTIType {code: $to_type})
                CREATE (m1)-[:COMPATIBLE_WITH {
                    score: $score,
                    relationship_type: $relationship_type,
                    communication_style: $communication_style,
                    emotional_compatibility: $emotional_compatibility
                }]->(m2)
                """
                session.run(query, **compatibility.to_dict())
                self.logger.info(f"✅ 创建兼容性关系: {compatibility.from_type} -> {compatibility.to_type}")
                return True
        except Exception as e:
            self.logger.error(f"❌ 创建兼容性关系失败: {str(e)}")
            return False
    
    def create_all_compatibility_relationships(self) -> bool:
        """创建所有兼容性关系"""
        compatibilities = [
            CompatibilityRelationship("INTJ", "ENFP", 0.85, "理想伴侣", "直接、深度", 0.88),
            CompatibilityRelationship("INTJ", "ENTP", 0.80, "智力伙伴", "逻辑、创新", 0.75),
            CompatibilityRelationship("INTP", "ENTJ", 0.80, "智力伙伴", "分析、规划", 0.70),
            CompatibilityRelationship("INTP", "ENFP", 0.75, "互补关系", "创新、灵活", 0.80),
            CompatibilityRelationship("ENTJ", "INFP", 0.75, "互补关系", "目标、价值观", 0.70),
            CompatibilityRelationship("ENTJ", "INTP", 0.80, "智力伙伴", "战略、分析", 0.75),
            CompatibilityRelationship("ENTP", "INFJ", 0.90, "深度连接", "创新、洞察", 0.85),
            CompatibilityRelationship("ENTP", "INTJ", 0.80, "智力伙伴", "创新、逻辑", 0.75),
            CompatibilityRelationship("INFJ", "ENTP", 0.90, "深度连接", "洞察、创新", 0.85),
            CompatibilityRelationship("INFJ", "ENFP", 0.85, "理想伴侣", "同理心、热情", 0.90),
            CompatibilityRelationship("INFP", "ENTJ", 0.70, "挑战关系", "价值观、目标", 0.65),
            CompatibilityRelationship("INFP", "ENFJ", 0.80, "互补关系", "价值观、同理心", 0.85),
            CompatibilityRelationship("ENFJ", "INFP", 0.80, "互补关系", "同理心、价值观", 0.85),
            CompatibilityRelationship("ENFJ", "INTP", 0.75, "互补关系", "激励、分析", 0.70),
            CompatibilityRelationship("ENFP", "INTJ", 0.85, "理想伴侣", "热情、逻辑", 0.80),
            CompatibilityRelationship("ENFP", "INFJ", 0.85, "理想伴侣", "热情、洞察", 0.90)
        ]
        
        success_count = 0
        for compatibility in compatibilities:
            if self.create_compatibility_relationship(compatibility):
                success_count += 1
        
        self.logger.info(f"✅ 创建兼容性关系: {success_count}/{len(compatibilities)}")
        return success_count == len(compatibilities)
    
    # ==================== 用户关系管理 ====================
    
    def create_user_relationship(self, relationship: UserRelationship) -> bool:
        """创建用户关系"""
        try:
            with self.driver.session() as session:
                query = """
                MATCH (u1:User {user_id: $from_user})
                MATCH (u2:User {user_id: $to_user})
                CREATE (u1)-[:KNOWS {
                    relationship_type: $relationship_type,
                    interaction_frequency: $interaction_frequency,
                    emotional_bond_strength: $emotional_bond_strength,
                    communication_quality: $communication_quality,
                    created_at: $created_at
                }]->(u2)
                """
                session.run(query, **relationship.to_dict())
                self.logger.info(f"✅ 创建用户关系: {relationship.from_user} -> {relationship.to_user}")
                return True
        except Exception as e:
            self.logger.error(f"❌ 创建用户关系失败: {str(e)}")
            return False
    
    # ==================== 图查询和分析 ====================
    
    def find_compatible_types(self, mbti_code: str, min_score: float = 0.8) -> List[Dict[str, Any]]:
        """查找兼容的MBTI类型"""
        try:
            with self.driver.session() as session:
                query = """
                MATCH (m1:MBTIType {code: $mbti_code})-[r:COMPATIBLE_WITH]->(m2:MBTIType)
                WHERE r.score >= $min_score
                RETURN m2.code, m2.name, r.score, r.relationship_type, r.emotional_compatibility
                ORDER BY r.score DESC
                """
                result = session.run(query, mbti_code=mbti_code, min_score=min_score)
                
                compatible_types = []
                for record in result:
                    compatible_types.append({
                        "code": record["m2.code"],
                        "name": record["m2.name"],
                        "score": record["r.score"],
                        "relationship_type": record["r.relationship_type"],
                        "emotional_compatibility": record["r.emotional_compatibility"]
                    })
                
                return compatible_types
        except Exception as e:
            self.logger.error(f"❌ 查找兼容类型失败: {str(e)}")
            return []
    
    def find_suitable_careers(self, mbti_code: str, min_score: float = 0.8) -> List[Dict[str, Any]]:
        """查找适合的职业"""
        try:
            with self.driver.session() as session:
                query = """
                MATCH (m:MBTIType {code: $mbti_code})-[r:SUITABLE_FOR]->(c:Career)
                WHERE r.match_score >= $min_score
                RETURN c.name, c.category, r.match_score, r.reasoning
                ORDER BY r.match_score DESC
                """
                result = session.run(query, mbti_code=mbti_code, min_score=min_score)
                
                careers = []
                for record in result:
                    careers.append({
                        "name": record["c.name"],
                        "category": record["c.category"],
                        "match_score": record["r.match_score"],
                        "reasoning": record["r.reasoning"]
                    })
                
                return careers
        except Exception as e:
            self.logger.error(f"❌ 查找适合职业失败: {str(e)}")
            return []
    
    def find_flower_matches(self, mbti_code: str, min_score: float = 0.8) -> List[Dict[str, Any]]:
        """查找花卉匹配"""
        try:
            with self.driver.session() as session:
                query = """
                MATCH (m:MBTIType {code: $mbti_code})-[r:REPRESENTED_BY]->(f:Flower)
                WHERE r.match_score >= $min_score
                RETURN f.name, f.color, f.season, r.match_score, r.emotional_resonance
                ORDER BY r.match_score DESC
                """
                result = session.run(query, mbti_code=mbti_code, min_score=min_score)
                
                flowers = []
                for record in result:
                    flowers.append({
                        "name": record["f.name"],
                        "color": record["f.color"],
                        "season": record["f.season"],
                        "match_score": record["r.match_score"],
                        "emotional_resonance": record["r.emotional_resonance"]
                    })
                
                return flowers
        except Exception as e:
            self.logger.error(f"❌ 查找花卉匹配失败: {str(e)}")
            return []
    
    def analyze_user_network(self, user_id: str) -> Dict[str, Any]:
        """分析用户网络"""
        try:
            with self.driver.session() as session:
                # 获取用户连接
                query = """
                MATCH (u:User {user_id: $user_id})-[r:KNOWS]->(friend:User)
                RETURN friend.user_id, friend.mbti_type, r.relationship_type, r.emotional_bond_strength
                """
                result = session.run(query, user_id=user_id)
                
                connections = []
                mbti_distribution = {}
                emotional_bonds = []
                
                for record in result:
                    friend_id = record["friend.user_id"]
                    friend_mbti = record["friend.mbti_type"]
                    relationship_type = record["r.relationship_type"]
                    emotional_bond = record["r.emotional_bond_strength"]
                    
                    connections.append({
                        "friend_id": friend_id,
                        "friend_mbti": friend_mbti,
                        "relationship_type": relationship_type,
                        "emotional_bond": emotional_bond
                    })
                    
                    mbti_distribution[friend_mbti] = mbti_distribution.get(friend_mbti, 0) + 1
                    emotional_bonds.append(emotional_bond)
                
                # 分析网络特征
                total_connections = len(connections)
                avg_emotional_bond = sum(emotional_bonds) / len(emotional_bonds) if emotional_bonds else 0
                most_common_mbti = max(mbti_distribution, key=mbti_distribution.get) if mbti_distribution else None
                
                return {
                    "total_connections": total_connections,
                    "mbti_distribution": mbti_distribution,
                    "avg_emotional_bond": avg_emotional_bond,
                    "most_common_mbti": most_common_mbti,
                    "network_density": total_connections / 100,  # 假设最大100个连接
                    "connections": connections
                }
        except Exception as e:
            self.logger.error(f"❌ 分析用户网络失败: {str(e)}")
            return {}
    
    def recommend_friends(self, user_id: str, limit: int = 5) -> List[Dict[str, Any]]:
        """推荐朋友"""
        try:
            with self.driver.session() as session:
                # 获取用户MBTI类型
                user_query = "MATCH (u:User {user_id: $user_id}) RETURN u.mbti_type"
                user_result = session.run(user_query, user_id=user_id)
                user_record = user_result.single()
                
                if not user_record:
                    return []
                
                user_mbti = user_record["u.mbti_type"]
                
                # 查找兼容的用户
                query = """
                MATCH (u:User {user_id: $user_id})-[:HAS_MBTI_TYPE]->(m1:MBTIType)
                MATCH (m1)-[r:COMPATIBLE_WITH]->(m2:MBTIType)
                MATCH (m2)<-[:HAS_MBTI_TYPE]-(friend:User)
                WHERE friend.user_id <> $user_id
                AND NOT (u)-[:KNOWS]-(friend)
                RETURN friend.user_id, friend.mbti_type, r.score, r.relationship_type
                ORDER BY r.score DESC
                LIMIT $limit
                """
                result = session.run(query, user_id=user_id, limit=limit)
                
                recommendations = []
                for record in result:
                    recommendations.append({
                        "friend_id": record["friend.user_id"],
                        "friend_mbti": record["friend.mbti_type"],
                        "compatibility_score": record["r.score"],
                        "relationship_type": record["r.relationship_type"]
                    })
                
                return recommendations
        except Exception as e:
            self.logger.error(f"❌ 推荐朋友失败: {str(e)}")
            return []
    
    # ==================== 辅助方法 ====================
    
    def create_sample_data(self) -> bool:
        """创建示例数据"""
        try:
            # 创建MBTI类型节点
            self.create_all_mbti_types()
            
            # 创建花卉节点
            flowers = [
                FlowerNode("白色菊花", "white", "autumn", "ISTJ", "calm and reliable", "坚韧、可靠", ["定期浇水", "充足阳光"]),
                FlowerNode("紫色菊花", "purple", "autumn", "INTP", "wise and independent", "智慧、独立", ["适度浇水", "避免强光"]),
                FlowerNode("红色玫瑰", "red", "summer", "ENTJ", "passionate and confident", "热情、自信", ["充足水分", "定期修剪"])
            ]
            
            for flower in flowers:
                self.create_flower_node(flower)
            
            # 创建花卉-MBTI关系
            flower_relationships = [
                ("INTJ", "白色菊花", 0.95),
                ("INTP", "紫色菊花", 0.90),
                ("ENTJ", "红色玫瑰", 0.88)
            ]
            
            for mbti_code, flower_name, score in flower_relationships:
                self.create_flower_mbti_relationship(mbti_code, flower_name, score)
            
            # 创建职业节点
            careers = [
                CareerNode("软件工程师", "技术", ["编程", "逻辑思维"], "高", "优秀", "办公室"),
                CareerNode("产品经理", "管理", ["沟通", "分析"], "高", "优秀", "办公室"),
                CareerNode("数据分析师", "技术", ["数学", "统计"], "中", "良好", "办公室")
            ]
            
            for career in careers:
                self.create_career_node(career)
            
            # 创建职业-MBTI关系
            career_relationships = [
                ("INTJ", "软件工程师", 0.92, "逻辑思维强、独立工作能力优秀"),
                ("INTJ", "产品经理", 0.88, "战略思维、系统规划能力"),
                ("INTP", "数据分析师", 0.90, "分析能力强、喜欢深度思考")
            ]
            
            for mbti_code, career_name, score, reasoning in career_relationships:
                self.create_career_mbti_relationship(mbti_code, career_name, score, reasoning)
            
            # 创建兼容性关系
            self.create_all_compatibility_relationships()
            
            self.logger.info("✅ 创建示例数据完成")
            return True
        except Exception as e:
            self.logger.error(f"❌ 创建示例数据失败: {str(e)}")
            return False


# ==================== 主函数和示例 ====================

def main():
    """主函数"""
    print("🕸️ MBTI Neo4j集成模块")
    print("版本: v1.0 (Neo4j集成版)")
    print("目标: 实现Neo4j图结构、关系网络、推荐算法")
    print("=" * 60)
    
    # 初始化Neo4j管理器
    neo4j_manager = MBTINeo4jManager()
    
    try:
        # 连接Neo4j
        if not neo4j_manager.connect():
            print("❌ Neo4j连接失败")
            return
        
        # 创建示例数据
        print("\n🏗️ 创建示例数据...")
        neo4j_manager.create_sample_data()
        print("✅ 示例数据创建完成")
        
        # 测试用户节点
        print("\n👤 测试用户节点...")
        user = UserNode(
            user_id="user_123",
            mbti_type="INTJ",
            confidence=0.95,
            test_date=datetime.now(),
            emotional_profile="rational_dominant",
            personality_traits=["战略思维", "独立性", "逻辑分析"]
        )
        neo4j_manager.create_user_node(user)
        neo4j_manager.connect_user_to_mbti_type("user_123", "INTJ")
        print("✅ 用户节点创建完成")
        
        # 测试兼容性查询
        print("\n🔍 测试兼容性查询...")
        compatible_types = neo4j_manager.find_compatible_types("INTJ", 0.8)
        print(f"✅ 找到兼容类型: {len(compatible_types)}个")
        for compat in compatible_types:
            print(f"  - {compat['name']} ({compat['code']}): {compat['score']:.2f}")
        
        # 测试职业推荐
        print("\n💼 测试职业推荐...")
        careers = neo4j_manager.find_suitable_careers("INTJ", 0.8)
        print(f"✅ 找到适合职业: {len(careers)}个")
        for career in careers:
            print(f"  - {career['name']}: {career['match_score']:.2f}")
        
        # 测试花卉匹配
        print("\n🌸 测试花卉匹配...")
        flowers = neo4j_manager.find_flower_matches("INTJ", 0.8)
        print(f"✅ 找到花卉匹配: {len(flowers)}个")
        for flower in flowers:
            print(f"  - {flower['name']}: {flower['match_score']:.2f}")
        
        # 测试朋友推荐
        print("\n👥 测试朋友推荐...")
        recommendations = neo4j_manager.recommend_friends("user_123", 3)
        print(f"✅ 推荐朋友: {len(recommendations)}个")
        for rec in recommendations:
            print(f"  - {rec['friend_mbti']}: {rec['compatibility_score']:.2f}")
        
        print("\n🎉 MBTI Neo4j集成测试完成！")
        
    except Exception as e:
        print(f"❌ 测试失败: {str(e)}")
    finally:
        # 断开连接
        neo4j_manager.disconnect()
    
    print("\n📋 支持的功能:")
    print("  - 图结构管理")
    print("  - 关系网络分析")
    print("  - 推荐算法")
    print("  - 兼容性分析")
    print("  - 网络分析")


if __name__ == "__main__":
    main()
