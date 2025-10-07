#!/usr/bin/env python3
"""
MBTI SQLite数据迁移脚本
创建时间: 2025年10月4日
版本: v1.0 (SQLite迁移版)
基于: 006_create_mbti_open_tables.sql
目标: 执行SQLite数据库的实际数据迁移
"""

import json
import sqlite3
from typing import Dict, List, Optional, Any
from dataclasses import dataclass, asdict
from datetime import datetime
import logging
import os


# ==================== 数据模型 ====================

@dataclass
class MigrationStep:
    """迁移步骤"""
    step_id: str
    description: str
    sql: str
    status: str  # pending, running, completed, failed
    execution_time: float
    
    def to_dict(self) -> Dict[str, Any]:
        return asdict(self)


# ==================== SQLite数据迁移脚本 ====================

class MBTISQLiteMigration:
    """MBTI SQLite数据迁移脚本"""
    
    def __init__(self, database_path: str = "mbti.db"):
        self.database_path = database_path
        self.logger = logging.getLogger(__name__)
        self.setup_logging()
        
        # 迁移步骤定义
        self.migration_steps = []
        self.define_migration_steps()
    
    def setup_logging(self):
        """设置日志"""
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
    
    def define_migration_steps(self):
        """定义迁移步骤"""
        self.migration_steps = [
            MigrationStep(
                step_id="create_mbti_types",
                description="创建MBTI类型表",
                sql="""
                CREATE TABLE IF NOT EXISTS mbti_types (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    type_code VARCHAR(4) NOT NULL UNIQUE,
                    type_name VARCHAR(50) NOT NULL,
                    description TEXT,
                    characteristics TEXT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                );
                """,
                status="pending",
                execution_time=0.0
            ),
            MigrationStep(
                step_id="create_flowers",
                description="创建花卉信息表",
                sql="""
                CREATE TABLE IF NOT EXISTS flowers (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    name VARCHAR(100) NOT NULL,
                    scientific_name VARCHAR(100),
                    color VARCHAR(50),
                    season VARCHAR(20),
                    meaning TEXT,
                    personality_traits TEXT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                );
                """,
                status="pending",
                execution_time=0.0
            ),
            MigrationStep(
                step_id="create_mbti_flower_mappings",
                description="创建MBTI-花卉映射表",
                sql="""
                CREATE TABLE IF NOT EXISTS mbti_flower_mappings (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    mbti_type_id INTEGER NOT NULL,
                    flower_id INTEGER NOT NULL,
                    match_score DECIMAL(3,2) DEFAULT 0.00,
                    description TEXT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (mbti_type_id) REFERENCES mbti_types(id),
                    FOREIGN KEY (flower_id) REFERENCES flowers(id),
                    UNIQUE (mbti_type_id, flower_id)
                );
                """,
                status="pending",
                execution_time=0.0
            ),
            MigrationStep(
                step_id="create_compatibility_matrix",
                description="创建兼容性矩阵表",
                sql="""
                CREATE TABLE IF NOT EXISTS mbti_compatibility_matrix (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    type_a_id INTEGER NOT NULL,
                    type_b_id INTEGER NOT NULL,
                    compatibility_score DECIMAL(3,2) DEFAULT 0.00,
                    relationship_type VARCHAR(50),
                    description TEXT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (type_a_id) REFERENCES mbti_types(id),
                    FOREIGN KEY (type_b_id) REFERENCES mbti_types(id),
                    UNIQUE (type_a_id, type_b_id)
                );
                """,
                status="pending",
                execution_time=0.0
            ),
            MigrationStep(
                step_id="create_careers",
                description="创建职业信息表",
                sql="""
                CREATE TABLE IF NOT EXISTS careers (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    name VARCHAR(100) NOT NULL,
                    category VARCHAR(50),
                    description TEXT,
                    required_skills TEXT,
                    salary_range VARCHAR(50),
                    growth_prospect VARCHAR(20),
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                );
                """,
                status="pending",
                execution_time=0.0
            ),
            MigrationStep(
                step_id="create_mbti_career_matches",
                description="创建MBTI-职业匹配表",
                sql="""
                CREATE TABLE IF NOT EXISTS mbti_career_matches (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    mbti_type_id INTEGER NOT NULL,
                    career_id INTEGER NOT NULL,
                    match_score DECIMAL(3,2) DEFAULT 0.00,
                    description TEXT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (mbti_type_id) REFERENCES mbti_types(id),
                    FOREIGN KEY (career_id) REFERENCES careers(id),
                    UNIQUE (mbti_type_id, career_id)
                );
                """,
                status="pending",
                execution_time=0.0
            ),
            MigrationStep(
                step_id="create_user_mbti_reports",
                description="创建用户MBTI报告表",
                sql="""
                CREATE TABLE IF NOT EXISTS user_mbti_reports (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    user_id VARCHAR(100) NOT NULL,
                    mbti_type_id INTEGER NOT NULL,
                    test_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    confidence_score DECIMAL(3,2) DEFAULT 0.00,
                    report_data TEXT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (mbti_type_id) REFERENCES mbti_types(id)
                );
                """,
                status="pending",
                execution_time=0.0
            ),
            MigrationStep(
                step_id="create_api_service_configs",
                description="创建API服务配置表",
                sql="""
                CREATE TABLE IF NOT EXISTS api_service_configs (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    service_name VARCHAR(100) NOT NULL UNIQUE,
                    api_url VARCHAR(500),
                    api_key VARCHAR(500),
                    rate_limit INTEGER DEFAULT 1000,
                    status VARCHAR(20) DEFAULT 'active',
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                );
                """,
                status="pending",
                execution_time=0.0
            ),
            MigrationStep(
                step_id="create_api_call_logs",
                description="创建API调用日志表",
                sql="""
                CREATE TABLE IF NOT EXISTS api_call_logs (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    service_id INTEGER NOT NULL,
                    request_data TEXT,
                    response_data TEXT,
                    status_code INTEGER,
                    execution_time DECIMAL(10,3),
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (service_id) REFERENCES api_service_configs(id)
                );
                """,
                status="pending",
                execution_time=0.0
            ),
            MigrationStep(
                step_id="create_mbti_dimension_scores",
                description="创建MBTI维度分数表",
                sql="""
                CREATE TABLE IF NOT EXISTS mbti_dimension_scores (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    user_id VARCHAR(100) NOT NULL,
                    dimension VARCHAR(2) NOT NULL,
                    score DECIMAL(5,2) NOT NULL,
                    test_session_id VARCHAR(100),
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                );
                """,
                status="pending",
                execution_time=0.0
            ),
            MigrationStep(
                step_id="create_mbti_question_banks",
                description="创建MBTI题库表",
                sql="""
                CREATE TABLE IF NOT EXISTS mbti_question_banks (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    bank_name VARCHAR(100) NOT NULL,
                    version VARCHAR(20) NOT NULL,
                    total_questions INTEGER NOT NULL,
                    description TEXT,
                    is_active BOOLEAN DEFAULT 1,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                );
                """,
                status="pending",
                execution_time=0.0
            ),
            MigrationStep(
                step_id="create_mbti_questions",
                description="创建MBTI题目表",
                sql="""
                CREATE TABLE IF NOT EXISTS mbti_questions (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    question_bank_id INTEGER NOT NULL,
                    question_text TEXT NOT NULL,
                    dimension VARCHAR(2) NOT NULL,
                    question_type VARCHAR(20) DEFAULT 'standard',
                    options TEXT,
                    difficulty VARCHAR(10) DEFAULT 'medium',
                    category VARCHAR(50),
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (question_bank_id) REFERENCES mbti_question_banks(id)
                );
                """,
                status="pending",
                execution_time=0.0
            ),
            MigrationStep(
                step_id="create_mbti_question_categories",
                description="创建MBTI题目分类表",
                sql="""
                CREATE TABLE IF NOT EXISTS mbti_question_categories (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    category_name VARCHAR(50) NOT NULL UNIQUE,
                    description TEXT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                );
                """,
                status="pending",
                execution_time=0.0
            ),
            MigrationStep(
                step_id="create_mbti_test_sessions",
                description="创建MBTI测试会话表",
                sql="""
                CREATE TABLE IF NOT EXISTS mbti_test_sessions (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    session_id VARCHAR(100) NOT NULL UNIQUE,
                    user_id VARCHAR(100) NOT NULL,
                    question_bank_id INTEGER NOT NULL,
                    status VARCHAR(20) DEFAULT 'active',
                    start_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    end_time TIMESTAMP NULL,
                    total_questions INTEGER DEFAULT 0,
                    answered_questions INTEGER DEFAULT 0,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (question_bank_id) REFERENCES mbti_question_banks(id)
                );
                """,
                status="pending",
                execution_time=0.0
            ),
            MigrationStep(
                step_id="create_user_mbti_responses",
                description="创建用户MBTI回答表",
                sql="""
                CREATE TABLE IF NOT EXISTS user_mbti_responses (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    session_id VARCHAR(100) NOT NULL,
                    question_id INTEGER NOT NULL,
                    answer VARCHAR(10) NOT NULL,
                    response_time DECIMAL(10,3),
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (session_id) REFERENCES mbti_test_sessions(session_id),
                    FOREIGN KEY (question_id) REFERENCES mbti_questions(id)
                );
                """,
                status="pending",
                execution_time=0.0
            )
        ]
    
    def execute_migration(self):
        """执行数据迁移"""
        self.logger.info("🚀 开始执行SQLite数据迁移")
        
        # 连接SQLite数据库
        connection = sqlite3.connect(self.database_path)
        cursor = connection.cursor()
        
        try:
            # 执行迁移步骤
            for step in self.migration_steps:
                self.logger.info(f"🔄 执行迁移步骤: {step.step_id} - {step.description}")
                
                start_time = datetime.now()
                step.status = "running"
                
                try:
                    cursor.execute(step.sql)
                    connection.commit()
                    step.status = "completed"
                    self.logger.info(f"✅ 迁移步骤 {step.step_id} 完成")
                except Exception as e:
                    step.status = "failed"
                    self.logger.error(f"❌ 迁移步骤 {step.step_id} 失败: {str(e)}")
                
                step.execution_time = (datetime.now() - start_time).total_seconds()
            
            # 插入初始数据
            self.logger.info("📊 插入初始数据")
            self.insert_initial_data(cursor, connection)
            
        except Exception as e:
            self.logger.error(f"❌ 迁移执行失败: {str(e)}")
        finally:
            connection.close()
    
    def insert_initial_data(self, cursor, connection):
        """插入初始数据"""
        # 插入MBTI类型数据
        self.insert_mbti_types(cursor, connection)
        
        # 插入花卉数据
        self.insert_flowers(cursor, connection)
        
        # 插入MBTI-花卉映射数据
        self.insert_mbti_flower_mappings(cursor, connection)
        
        # 插入兼容性矩阵数据
        self.insert_compatibility_matrix(cursor, connection)
        
        # 插入职业数据
        self.insert_careers(cursor, connection)
        
        # 插入API配置数据
        self.insert_api_configs(cursor, connection)
    
    def insert_mbti_types(self, cursor, connection):
        """插入MBTI类型数据"""
        mbti_types = [
            ("INTJ", "建筑师", "理性、独立、战略思维、完美主义"),
            ("INTP", "思想家", "分析、好奇、逻辑、创新"),
            ("ENTJ", "指挥官", "领导、果断、目标导向、自信"),
            ("ENTP", "辩论家", "创新、灵活、辩论、冒险"),
            ("INFJ", "提倡者", "洞察、理想主义、同理心、直觉"),
            ("INFP", "调停者", "价值观、创造力、敏感、真实"),
            ("ENFJ", "主人公", "激励、社交、同理心、组织"),
            ("ENFP", "竞选者", "热情、创意、社交、灵活"),
            ("ISTJ", "物流师", "可靠、传统、实用、责任"),
            ("ISFJ", "守护者", "关怀、忠诚、实用、和谐"),
            ("ESTJ", "总经理", "组织、传统、实用、领导"),
            ("ESFJ", "执政官", "社交、关怀、传统、和谐"),
            ("ISTP", "鉴赏家", "灵活、实用、独立、冷静"),
            ("ISFP", "探险家", "艺术、敏感、灵活、真实"),
            ("ESTP", "企业家", "行动、社交、灵活、现实"),
            ("ESFP", "表演者", "热情、社交、灵活、关怀")
        ]
        
        try:
            for type_code, type_name, characteristics in mbti_types:
                cursor.execute("""
                    INSERT OR REPLACE INTO mbti_types (type_code, type_name, characteristics)
                    VALUES (?, ?, ?)
                """, (type_code, type_name, characteristics))
            connection.commit()
            self.logger.info("✅ MBTI类型数据插入成功")
        except Exception as e:
            self.logger.error(f"❌ MBTI类型数据插入失败: {str(e)}")
    
    def insert_flowers(self, cursor, connection):
        """插入花卉数据"""
        flowers = [
            ("白色菊花", "Chrysanthemum morifolium", "白色", "秋季", "坚韧、可靠、务实", "ISTJ型人格特征"),
            ("紫色菊花", "Chrysanthemum morifolium", "紫色", "秋季", "智慧、独立、创新", "INTP型人格特征"),
            ("红色玫瑰", "Rosa rubiginosa", "红色", "全年", "领导、自信、目标导向", "ENTJ型人格特征"),
            ("橙色向日葵", "Helianthus annuus", "橙色", "夏季", "创新、灵活、冒险", "ENTP型人格特征"),
            ("蓝色风信子", "Hyacinthus orientalis", "蓝色", "春季", "洞察、理想主义、同理心", "INFJ型人格特征"),
            ("粉色樱花", "Prunus serrulata", "粉色", "春季", "价值观、创造力、敏感", "INFP型人格特征"),
            ("黄色郁金香", "Tulipa gesneriana", "黄色", "春季", "激励、社交、同理心", "ENFJ型人格特征"),
            ("彩虹花", "混合品种", "多彩", "全年", "热情、创意、社交", "ENFP型人格特征")
        ]
        
        try:
            for name, scientific_name, color, season, meaning, personality_traits in flowers:
                cursor.execute("""
                    INSERT OR REPLACE INTO flowers (name, scientific_name, color, season, meaning, personality_traits)
                    VALUES (?, ?, ?, ?, ?, ?)
                """, (name, scientific_name, color, season, meaning, personality_traits))
            connection.commit()
            self.logger.info("✅ 花卉数据插入成功")
        except Exception as e:
            self.logger.error(f"❌ 花卉数据插入失败: {str(e)}")
    
    def insert_mbti_flower_mappings(self, cursor, connection):
        """插入MBTI-花卉映射数据"""
        mappings = [
            ("INTJ", "白色菊花", 0.95),
            ("INTP", "紫色菊花", 0.90),
            ("ENTJ", "红色玫瑰", 0.88),
            ("ENTP", "橙色向日葵", 0.92),
            ("INFJ", "蓝色风信子", 0.94),
            ("INFP", "粉色樱花", 0.96),
            ("ENFJ", "黄色郁金香", 0.89),
            ("ENFP", "彩虹花", 0.93)
        ]
        
        try:
            for mbti_type, flower_name, match_score in mappings:
                cursor.execute("""
                    INSERT OR REPLACE INTO mbti_flower_mappings (mbti_type_id, flower_id, match_score)
                    SELECT mt.id, f.id, ?
                    FROM mbti_types mt, flowers f
                    WHERE mt.type_code = ? AND f.name = ?
                """, (match_score, mbti_type, flower_name))
            connection.commit()
            self.logger.info("✅ MBTI-花卉映射数据插入成功")
        except Exception as e:
            self.logger.error(f"❌ MBTI-花卉映射数据插入失败: {str(e)}")
    
    def insert_compatibility_matrix(self, cursor, connection):
        """插入兼容性矩阵数据"""
        compatibility_data = [
            ("INTJ", "ENFP", 0.85, "理想伴侣"),
            ("INTP", "ENTJ", 0.80, "智力伙伴"),
            ("ENTJ", "INFP", 0.75, "互补关系"),
            ("ENTP", "INFJ", 0.90, "深度连接"),
            ("INFJ", "ENTP", 0.90, "深度连接"),
            ("INFP", "ENTJ", 0.70, "挑战关系"),
            ("ENFJ", "INTP", 0.75, "互补关系"),
            ("ENFP", "INTJ", 0.85, "理想伴侣")
        ]
        
        try:
            for type_a, type_b, score, relationship_type in compatibility_data:
                cursor.execute("""
                    INSERT OR REPLACE INTO mbti_compatibility_matrix (type_a_id, type_b_id, compatibility_score, relationship_type)
                    SELECT mt1.id, mt2.id, ?, ?
                    FROM mbti_types mt1, mbti_types mt2
                    WHERE mt1.type_code = ? AND mt2.type_code = ?
                """, (score, relationship_type, type_a, type_b))
            connection.commit()
            self.logger.info("✅ 兼容性矩阵数据插入成功")
        except Exception as e:
            self.logger.error(f"❌ 兼容性矩阵数据插入失败: {str(e)}")
    
    def insert_careers(self, cursor, connection):
        """插入职业数据"""
        careers = [
            ("软件工程师", "技术", "开发软件应用程序", "编程、逻辑思维", "高", "优秀"),
            ("产品经理", "管理", "产品规划和开发", "沟通、分析", "高", "优秀"),
            ("数据分析师", "技术", "数据分析和挖掘", "数学、统计", "中", "良好"),
            ("项目经理", "管理", "项目管理和协调", "组织、沟通", "中", "良好"),
            ("心理咨询师", "服务", "心理健康咨询", "同理心、沟通", "中", "良好"),
            ("市场营销", "销售", "市场推广和销售", "创意、沟通", "中", "良好"),
            ("教师", "教育", "教育教学工作", "耐心、知识", "中", "稳定"),
            ("医生", "医疗", "医疗诊断和治疗", "专业、责任", "高", "优秀")
        ]
        
        try:
            for name, category, description, required_skills, salary_range, growth_prospect in careers:
                cursor.execute("""
                    INSERT OR REPLACE INTO careers (name, category, description, required_skills, salary_range, growth_prospect)
                    VALUES (?, ?, ?, ?, ?, ?)
                """, (name, category, description, required_skills, salary_range, growth_prospect))
            connection.commit()
            self.logger.info("✅ 职业数据插入成功")
        except Exception as e:
            self.logger.error(f"❌ 职业数据插入失败: {str(e)}")
    
    def insert_api_configs(self, cursor, connection):
        """插入API配置数据"""
        api_configs = [
            ("极速数据MBTI", "https://api.jisuapi.com/mbti", "demo_key", 1000, "active"),
            ("挖数据MBTI", "https://api.washdata.com/mbti", "demo_key", 500, "active"),
            ("阿里云MBTI", "https://api.aliyun.com/mbti", "demo_key", 2000, "active")
        ]
        
        try:
            for service_name, api_url, api_key, rate_limit, status in api_configs:
                cursor.execute("""
                    INSERT OR REPLACE INTO api_service_configs (service_name, api_url, api_key, rate_limit, status)
                    VALUES (?, ?, ?, ?, ?)
                """, (service_name, api_url, api_key, rate_limit, status))
            connection.commit()
            self.logger.info("✅ API配置数据插入成功")
        except Exception as e:
            self.logger.error(f"❌ API配置数据插入失败: {str(e)}")
    
    def generate_migration_report(self) -> Dict[str, Any]:
        """生成迁移报告"""
        total_steps = len(self.migration_steps)
        completed_steps = len([s for s in self.migration_steps if s.status == "completed"])
        failed_steps = len([s for s in self.migration_steps if s.status == "failed"])
        pending_steps = len([s for s in self.migration_steps if s.status == "pending"])
        
        success_rate = (completed_steps / total_steps * 100) if total_steps > 0 else 0
        
        report = {
            "migration_summary": {
                "total_steps": total_steps,
                "completed_steps": completed_steps,
                "failed_steps": failed_steps,
                "pending_steps": pending_steps,
                "success_rate": success_rate,
                "timestamp": datetime.now().isoformat()
            },
            "migration_steps": [step.to_dict() for step in self.migration_steps],
            "recommendations": self.generate_recommendations(),
            "next_steps": self.generate_next_steps()
        }
        
        return report
    
    def generate_recommendations(self) -> List[str]:
        """生成改进建议"""
        recommendations = []
        
        failed_steps = [s for s in self.migration_steps if s.status == "failed"]
        pending_steps = [s for s in self.migration_steps if s.status == "pending"]
        
        if failed_steps:
            recommendations.append("🔧 修复失败的迁移步骤")
            recommendations.append("📊 检查数据库连接")
            recommendations.append("🔍 检查SQL语法")
            recommendations.append("📈 重新执行迁移")
        elif pending_steps:
            recommendations.append("⏳ 完成待执行的迁移步骤")
            recommendations.append("🔍 检查依赖关系")
            recommendations.append("📈 按顺序执行迁移")
        else:
            recommendations.append("✅ 数据迁移完成")
            recommendations.append("🚀 可以开始数据一致性检查")
            recommendations.append("📈 考虑性能优化")
            recommendations.append("🔍 定期进行数据备份")
        
        return recommendations
    
    def generate_next_steps(self) -> List[str]:
        """生成下一步行动"""
        next_steps = []
        
        failed_steps = [s for s in self.migration_steps if s.status == "failed"]
        pending_steps = [s for s in self.migration_steps if s.status == "pending"]
        
        if failed_steps:
            next_steps.append("1. 修复失败的迁移步骤")
            next_steps.append("2. 重新执行迁移")
            next_steps.append("3. 验证迁移结果")
        elif pending_steps:
            next_steps.append("1. 完成待执行的迁移步骤")
            next_steps.append("2. 检查依赖关系")
            next_steps.append("3. 按顺序执行迁移")
        else:
            next_steps.append("1. 开始数据一致性检查")
            next_steps.append("2. 验证数据完整性")
            next_steps.append("3. 开始Week 2: API网关和认证系统建设")
            next_steps.append("4. 进行集成测试")
        
        return next_steps


# ==================== 主函数和示例 ====================

def main():
    """主函数"""
    print("🔄 MBTI SQLite数据迁移脚本")
    print("版本: v1.0 (SQLite迁移版)")
    print("基于: 006_create_mbti_open_tables.sql")
    print("=" * 60)
    
    # 初始化迁移脚本
    migration_script = MBTISQLiteMigration("mbti.db")
    
    try:
        # 执行数据迁移
        print("\n🚀 开始执行SQLite数据迁移...")
        migration_script.execute_migration()
        
        # 生成迁移报告
        print("\n📊 生成迁移报告...")
        migration_report = migration_script.generate_migration_report()
        
        # 输出迁移结果
        print("\n📋 迁移结果汇总")
        print(f"总步骤数: {migration_report['migration_summary']['total_steps']}")
        print(f"完成步骤: {migration_report['migration_summary']['completed_steps']}")
        print(f"失败步骤: {migration_report['migration_summary']['failed_steps']}")
        print(f"待执行步骤: {migration_report['migration_summary']['pending_steps']}")
        print(f"成功率: {migration_report['migration_summary']['success_rate']:.1f}%")
        
        # 输出详细结果
        print("\n📋 详细迁移结果")
        for step in migration_report['migration_steps']:
            status_icon = "✅" if step['status'] == 'completed' else "❌" if step['status'] == 'failed' else "⏳"
            print(f"{status_icon} {step['step_id']}: {step['description']} ({step['status']})")
        
        # 输出建议
        print("\n💡 改进建议")
        for recommendation in migration_report['recommendations']:
            print(f"  {recommendation}")
        
        # 输出下一步行动
        print("\n🚀 下一步行动")
        for step in migration_report['next_steps']:
            print(f"  {step}")
        
        # 保存迁移报告
        with open('mbti_sqlite_migration_report.json', 'w', encoding='utf-8') as f:
            json.dump(migration_report, f, ensure_ascii=False, indent=2)
        
        print(f"\n📄 迁移报告已保存到: mbti_sqlite_migration_report.json")
        
    except Exception as e:
        print(f"❌ 迁移脚本执行失败: {str(e)}")
    
    print("\n🎉 MBTI SQLite数据迁移脚本执行完成！")
    print("📋 支持的功能:")
    print("  - SQLite数据库表结构创建")
    print("  - 初始数据插入")
    print("  - 迁移步骤管理")
    print("  - 迁移报告生成")


if __name__ == "__main__":
    main()
