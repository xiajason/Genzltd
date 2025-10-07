#!/usr/bin/env python3
"""
MBTI数据迁移和更新框架
创建时间: 2025年10月4日
版本: v1.0 (数据迁移版)
基于: MBTI感性AI身份统一实施计划
目标: 实现完整的数据迁移、更新和一致性检查
"""

import json
import asyncio
import sqlite3
import mysql.connector
import psycopg2
from typing import Dict, List, Optional, Any, Tuple
from dataclasses import dataclass, asdict
from datetime import datetime
import logging
from enum import Enum
import hashlib
import os


# ==================== 数据模型 ====================

class MigrationStatus(Enum):
    """迁移状态枚举"""
    PENDING = "pending"
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"
    ROLLED_BACK = "rolled_back"


@dataclass
class MigrationRecord:
    """迁移记录"""
    migration_id: str
    version: str
    description: str
    status: MigrationStatus
    created_at: datetime
    completed_at: Optional[datetime]
    rollback_at: Optional[datetime]
    checksum: str
    execution_time: float
    
    def to_dict(self) -> Dict[str, Any]:
        result = asdict(self)
        result['status'] = self.status.value
        result['created_at'] = self.created_at.isoformat()
        result['completed_at'] = self.completed_at.isoformat() if self.completed_at else None
        result['rollback_at'] = self.rollback_at.isoformat() if self.rollback_at else None
        return result


@dataclass
class DataConsistencyCheck:
    """数据一致性检查"""
    check_id: str
    check_name: str
    table_name: str
    check_type: str  # count, integrity, foreign_key, data_type
    expected_value: Any
    actual_value: Any
    status: str  # passed, failed, warning
    message: str
    timestamp: datetime
    
    def to_dict(self) -> Dict[str, Any]:
        result = asdict(self)
        result['timestamp'] = self.timestamp.isoformat()
        return result


# ==================== 数据迁移框架 ====================

class MBTIDataMigrationFramework:
    """MBTI数据迁移和更新框架"""
    
    def __init__(self, config: Dict[str, Any]):
        self.config = config
        self.logger = logging.getLogger(__name__)
        self.setup_logging()
        
        # 数据库连接
        self.connections = {}
        self.migration_history = []
        
        # 迁移版本管理
        self.current_version = "1.0.0"
        self.target_version = "1.1.0"
        
        # 数据一致性检查结果
        self.consistency_checks = []
    
    def setup_logging(self):
        """设置日志"""
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
    
    async def initialize_connections(self):
        """初始化数据库连接"""
        self.logger.info("🔌 初始化数据库连接")
        
        # MySQL连接
        if "mysql" in self.config:
            try:
                self.connections["mysql"] = mysql.connector.connect(
                    host=self.config["mysql"]["host"],
                    user=self.config["mysql"]["user"],
                    password=self.config["mysql"]["password"],
                    database=self.config["mysql"]["database"],
                    charset="utf8mb4"
                )
                self.logger.info("✅ MySQL连接成功")
            except Exception as e:
                self.logger.error(f"❌ MySQL连接失败: {str(e)}")
        
        # PostgreSQL连接
        if "postgresql" in self.config:
            try:
                self.connections["postgresql"] = psycopg2.connect(
                    host=self.config["postgresql"]["host"],
                    user=self.config["postgresql"]["user"],
                    password=self.config["postgresql"]["password"],
                    database=self.config["postgresql"]["database"]
                )
                self.logger.info("✅ PostgreSQL连接成功")
            except Exception as e:
                self.logger.error(f"❌ PostgreSQL连接失败: {str(e)}")
        
        # SQLite连接
        if "sqlite" in self.config:
            try:
                self.connections["sqlite"] = sqlite3.connect(
                    self.config["sqlite"]["database"]
                )
                self.logger.info("✅ SQLite连接成功")
            except Exception as e:
                self.logger.error(f"❌ SQLite连接失败: {str(e)}")
    
    async def create_migration_tables(self):
        """创建迁移管理表"""
        self.logger.info("📋 创建迁移管理表")
        
        migration_table_sql = """
        CREATE TABLE IF NOT EXISTS mbti_migrations (
            id VARCHAR(255) PRIMARY KEY,
            version VARCHAR(50) NOT NULL,
            description TEXT,
            status VARCHAR(20) NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            completed_at TIMESTAMP NULL,
            rollback_at TIMESTAMP NULL,
            checksum VARCHAR(64) NOT NULL,
            execution_time FLOAT DEFAULT 0.0
        );
        """
        
        for db_type, connection in self.connections.items():
            try:
                cursor = connection.cursor()
                cursor.execute(migration_table_sql)
                connection.commit()
                self.logger.info(f"✅ {db_type} 迁移管理表创建成功")
            except Exception as e:
                self.logger.error(f"❌ {db_type} 迁移管理表创建失败: {str(e)}")
    
    async def run_migration(self, migration_id: str, version: str, description: str, 
                          migration_sql: str, rollback_sql: str = None) -> MigrationRecord:
        """运行数据迁移"""
        start_time = datetime.now()
        
        self.logger.info(f"🚀 开始迁移: {migration_id} - {description}")
        
        # 计算迁移SQL的校验和
        checksum = hashlib.sha256(migration_sql.encode()).hexdigest()
        
        # 创建迁移记录
        migration_record = MigrationRecord(
            migration_id=migration_id,
            version=version,
            description=description,
            status=MigrationStatus.RUNNING,
            created_at=start_time,
            completed_at=None,
            rollback_at=None,
            checksum=checksum,
            execution_time=0.0
        )
        
        try:
            # 检查是否已经运行过此迁移
            if await self.is_migration_completed(migration_id):
                self.logger.warning(f"⚠️ 迁移 {migration_id} 已经完成，跳过")
                migration_record.status = MigrationStatus.COMPLETED
                migration_record.completed_at = datetime.now()
                return migration_record
            
            # 执行迁移SQL
            for db_type, connection in self.connections.items():
                try:
                    cursor = connection.cursor()
                    cursor.execute(migration_sql)
                    connection.commit()
                    self.logger.info(f"✅ {db_type} 迁移执行成功")
                except Exception as e:
                    self.logger.error(f"❌ {db_type} 迁移执行失败: {str(e)}")
                    # 如果支持回滚，执行回滚
                    if rollback_sql:
                        try:
                            cursor.execute(rollback_sql)
                            connection.commit()
                            self.logger.info(f"✅ {db_type} 回滚执行成功")
                        except Exception as rollback_error:
                            self.logger.error(f"❌ {db_type} 回滚执行失败: {str(rollback_error)}")
                    raise e
            
            # 记录迁移完成
            migration_record.status = MigrationStatus.COMPLETED
            migration_record.completed_at = datetime.now()
            migration_record.execution_time = (datetime.now() - start_time).total_seconds()
            
            # 保存迁移记录到数据库
            await self.save_migration_record(migration_record)
            
            self.logger.info(f"✅ 迁移 {migration_id} 完成，耗时 {migration_record.execution_time:.2f}秒")
            
        except Exception as e:
            migration_record.status = MigrationStatus.FAILED
            migration_record.execution_time = (datetime.now() - start_time).total_seconds()
            self.logger.error(f"❌ 迁移 {migration_id} 失败: {str(e)}")
            raise e
        
        return migration_record
    
    async def is_migration_completed(self, migration_id: str) -> bool:
        """检查迁移是否已完成"""
        for db_type, connection in self.connections.items():
            try:
                cursor = connection.cursor()
                cursor.execute(
                    "SELECT COUNT(*) FROM mbti_migrations WHERE id = %s AND status = 'completed'",
                    (migration_id,)
                )
                result = cursor.fetchone()
                if result and result[0] > 0:
                    return True
            except Exception as e:
                self.logger.error(f"❌ {db_type} 检查迁移状态失败: {str(e)}")
        return False
    
    async def save_migration_record(self, migration_record: MigrationRecord):
        """保存迁移记录"""
        for db_type, connection in self.connections.items():
            try:
                cursor = connection.cursor()
                cursor.execute("""
                    INSERT INTO mbti_migrations 
                    (id, version, description, status, created_at, completed_at, rollback_at, checksum, execution_time)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                    ON DUPLICATE KEY UPDATE
                    status = VALUES(status),
                    completed_at = VALUES(completed_at),
                    rollback_at = VALUES(rollback_at),
                    execution_time = VALUES(execution_time)
                """, (
                    migration_record.migration_id,
                    migration_record.version,
                    migration_record.description,
                    migration_record.status.value,
                    migration_record.created_at,
                    migration_record.completed_at,
                    migration_record.rollback_at,
                    migration_record.checksum,
                    migration_record.execution_time
                ))
                connection.commit()
                self.logger.info(f"✅ {db_type} 迁移记录保存成功")
            except Exception as e:
                self.logger.error(f"❌ {db_type} 迁移记录保存失败: {str(e)}")
    
    async def check_data_consistency(self) -> List[DataConsistencyCheck]:
        """检查数据一致性"""
        self.logger.info("🔍 开始数据一致性检查")
        
        consistency_checks = []
        
        # 检查MBTI类型表
        await self.check_mbti_types_consistency(consistency_checks)
        
        # 检查花卉信息表
        await self.check_flowers_consistency(consistency_checks)
        
        # 检查MBTI-花卉映射表
        await self.check_mbti_flower_mappings_consistency(consistency_checks)
        
        # 检查兼容性矩阵表
        await self.check_compatibility_matrix_consistency(consistency_checks)
        
        # 检查职业信息表
        await self.check_careers_consistency(consistency_checks)
        
        # 检查API配置表
        await self.check_api_configs_consistency(consistency_checks)
        
        self.consistency_checks = consistency_checks
        return consistency_checks
    
    async def check_mbti_types_consistency(self, checks: List[DataConsistencyCheck]):
        """检查MBTI类型表一致性"""
        expected_mbti_types = [
            "INTJ", "INTP", "ENTJ", "ENTP", "INFJ", "INFP", "ENFJ", "ENFP",
            "ISTJ", "ISFJ", "ESTJ", "ESFJ", "ISTP", "ISFP", "ESTP", "ESFP"
        ]
        
        for db_type, connection in self.connections.items():
            try:
                cursor = connection.cursor()
                cursor.execute("SELECT COUNT(*) FROM mbti_types")
                actual_count = cursor.fetchone()[0]
                
                check = DataConsistencyCheck(
                    check_id=f"mbti_types_count_{db_type}",
                    check_name="MBTI类型数量检查",
                    table_name="mbti_types",
                    check_type="count",
                    expected_value=16,
                    actual_value=actual_count,
                    status="passed" if actual_count == 16 else "failed",
                    message=f"MBTI类型数量: 期望16，实际{actual_count}",
                    timestamp=datetime.now()
                )
                checks.append(check)
                
                # 检查每个MBTI类型是否存在
                for mbti_type in expected_mbti_types:
                    cursor.execute("SELECT COUNT(*) FROM mbti_types WHERE type_code = %s", (mbti_type,))
                    exists = cursor.fetchone()[0] > 0
                    
                    check = DataConsistencyCheck(
                        check_id=f"mbti_type_exists_{mbti_type}_{db_type}",
                        check_name=f"MBTI类型 {mbti_type} 存在性检查",
                        table_name="mbti_types",
                        check_type="integrity",
                        expected_value=True,
                        actual_value=exists,
                        status="passed" if exists else "failed",
                        message=f"MBTI类型 {mbti_type}: {'存在' if exists else '不存在'}",
                        timestamp=datetime.now()
                    )
                    checks.append(check)
                    
            except Exception as e:
                check = DataConsistencyCheck(
                    check_id=f"mbti_types_error_{db_type}",
                    check_name="MBTI类型表检查错误",
                    table_name="mbti_types",
                    check_type="error",
                    expected_value=None,
                    actual_value=None,
                    status="failed",
                    message=f"检查失败: {str(e)}",
                    timestamp=datetime.now()
                )
                checks.append(check)
    
    async def check_flowers_consistency(self, checks: List[DataConsistencyCheck]):
        """检查花卉信息表一致性"""
        for db_type, connection in self.connections.items():
            try:
                cursor = connection.cursor()
                cursor.execute("SELECT COUNT(*) FROM flowers")
                actual_count = cursor.fetchone()[0]
                
                check = DataConsistencyCheck(
                    check_id=f"flowers_count_{db_type}",
                    check_name="花卉数量检查",
                    table_name="flowers",
                    check_type="count",
                    expected_value=">0",
                    actual_value=actual_count,
                    status="passed" if actual_count > 0 else "failed",
                    message=f"花卉数量: {actual_count}",
                    timestamp=datetime.now()
                )
                checks.append(check)
                
                # 检查花卉信息完整性
                cursor.execute("SELECT COUNT(*) FROM flowers WHERE name IS NULL OR name = ''")
                null_names = cursor.fetchone()[0]
                
                check = DataConsistencyCheck(
                    check_id=f"flowers_integrity_{db_type}",
                    check_name="花卉信息完整性检查",
                    table_name="flowers",
                    check_type="integrity",
                    expected_value=0,
                    actual_value=null_names,
                    status="passed" if null_names == 0 else "failed",
                    message=f"花卉名称完整性: {null_names}个空名称",
                    timestamp=datetime.now()
                )
                checks.append(check)
                
            except Exception as e:
                check = DataConsistencyCheck(
                    check_id=f"flowers_error_{db_type}",
                    check_name="花卉信息表检查错误",
                    table_name="flowers",
                    check_type="error",
                    expected_value=None,
                    actual_value=None,
                    status="failed",
                    message=f"检查失败: {str(e)}",
                    timestamp=datetime.now()
                )
                checks.append(check)
    
    async def check_mbti_flower_mappings_consistency(self, checks: List[DataConsistencyCheck]):
        """检查MBTI-花卉映射表一致性"""
        for db_type, connection in self.connections.items():
            try:
                cursor = connection.cursor()
                cursor.execute("SELECT COUNT(*) FROM mbti_flower_mappings")
                actual_count = cursor.fetchone()[0]
                
                check = DataConsistencyCheck(
                    check_id=f"mbti_flower_mappings_count_{db_type}",
                    check_name="MBTI-花卉映射数量检查",
                    table_name="mbti_flower_mappings",
                    check_type="count",
                    expected_value=">0",
                    actual_value=actual_count,
                    status="passed" if actual_count > 0 else "failed",
                    message=f"MBTI-花卉映射数量: {actual_count}",
                    timestamp=datetime.now()
                )
                checks.append(check)
                
                # 检查外键约束
                cursor.execute("""
                    SELECT COUNT(*) FROM mbti_flower_mappings mfm
                    LEFT JOIN mbti_types mt ON mfm.mbti_type_id = mt.id
                    LEFT JOIN flowers f ON mfm.flower_id = f.id
                    WHERE mt.id IS NULL OR f.id IS NULL
                """)
                invalid_foreign_keys = cursor.fetchone()[0]
                
                check = DataConsistencyCheck(
                    check_id=f"mbti_flower_mappings_fk_{db_type}",
                    check_name="MBTI-花卉映射外键检查",
                    table_name="mbti_flower_mappings",
                    check_type="foreign_key",
                    expected_value=0,
                    actual_value=invalid_foreign_keys,
                    status="passed" if invalid_foreign_keys == 0 else "failed",
                    message=f"无效外键: {invalid_foreign_keys}个",
                    timestamp=datetime.now()
                )
                checks.append(check)
                
            except Exception as e:
                check = DataConsistencyCheck(
                    check_id=f"mbti_flower_mappings_error_{db_type}",
                    check_name="MBTI-花卉映射表检查错误",
                    table_name="mbti_flower_mappings",
                    check_type="error",
                    expected_value=None,
                    actual_value=None,
                    status="failed",
                    message=f"检查失败: {str(e)}",
                    timestamp=datetime.now()
                )
                checks.append(check)
    
    async def check_compatibility_matrix_consistency(self, checks: List[DataConsistencyCheck]):
        """检查兼容性矩阵表一致性"""
        for db_type, connection in self.connections.items():
            try:
                cursor = connection.cursor()
                cursor.execute("SELECT COUNT(*) FROM mbti_compatibility_matrix")
                actual_count = cursor.fetchone()[0]
                
                # 期望的兼容性矩阵数量 (16x16 = 256)
                expected_count = 16 * 16
                
                check = DataConsistencyCheck(
                    check_id=f"compatibility_matrix_count_{db_type}",
                    check_name="兼容性矩阵数量检查",
                    table_name="mbti_compatibility_matrix",
                    check_type="count",
                    expected_value=expected_count,
                    actual_value=actual_count,
                    status="passed" if actual_count == expected_count else "failed",
                    message=f"兼容性矩阵数量: 期望{expected_count}，实际{actual_count}",
                    timestamp=datetime.now()
                )
                checks.append(check)
                
            except Exception as e:
                check = DataConsistencyCheck(
                    check_id=f"compatibility_matrix_error_{db_type}",
                    check_name="兼容性矩阵表检查错误",
                    table_name="mbti_compatibility_matrix",
                    check_type="error",
                    expected_value=None,
                    actual_value=None,
                    status="failed",
                    message=f"检查失败: {str(e)}",
                    timestamp=datetime.now()
                )
                checks.append(check)
    
    async def check_careers_consistency(self, checks: List[DataConsistencyCheck]):
        """检查职业信息表一致性"""
        for db_type, connection in self.connections.items():
            try:
                cursor = connection.cursor()
                cursor.execute("SELECT COUNT(*) FROM careers")
                actual_count = cursor.fetchone()[0]
                
                check = DataConsistencyCheck(
                    check_id=f"careers_count_{db_type}",
                    check_name="职业数量检查",
                    table_name="careers",
                    check_type="count",
                    expected_value=">0",
                    actual_value=actual_count,
                    status="passed" if actual_count > 0 else "failed",
                    message=f"职业数量: {actual_count}",
                    timestamp=datetime.now()
                )
                checks.append(check)
                
            except Exception as e:
                check = DataConsistencyCheck(
                    check_id=f"careers_error_{db_type}",
                    check_name="职业信息表检查错误",
                    table_name="careers",
                    check_type="error",
                    expected_value=None,
                    actual_value=None,
                    status="failed",
                    message=f"检查失败: {str(e)}",
                    timestamp=datetime.now()
                )
                checks.append(check)
    
    async def check_api_configs_consistency(self, checks: List[DataConsistencyCheck]):
        """检查API配置表一致性"""
        for db_type, connection in self.connections.items():
            try:
                cursor = connection.cursor()
                cursor.execute("SELECT COUNT(*) FROM api_service_configs")
                actual_count = cursor.fetchone()[0]
                
                check = DataConsistencyCheck(
                    check_id=f"api_configs_count_{db_type}",
                    check_name="API配置数量检查",
                    table_name="api_service_configs",
                    check_type="count",
                    expected_value=">=0",
                    actual_value=actual_count,
                    status="passed",
                    message=f"API配置数量: {actual_count}",
                    timestamp=datetime.now()
                )
                checks.append(check)
                
            except Exception as e:
                check = DataConsistencyCheck(
                    check_id=f"api_configs_error_{db_type}",
                    check_name="API配置表检查错误",
                    table_name="api_service_configs",
                    check_type="error",
                    expected_value=None,
                    actual_value=None,
                    status="failed",
                    message=f"检查失败: {str(e)}",
                    timestamp=datetime.now()
                )
                checks.append(check)
    
    async def generate_migration_report(self) -> Dict[str, Any]:
        """生成迁移报告"""
        total_checks = len(self.consistency_checks)
        passed_checks = len([c for c in self.consistency_checks if c.status == "passed"])
        failed_checks = len([c for c in self.consistency_checks if c.status == "failed"])
        
        success_rate = (passed_checks / total_checks * 100) if total_checks > 0 else 0
        
        report = {
            "migration_summary": {
                "total_checks": total_checks,
                "passed_checks": passed_checks,
                "failed_checks": failed_checks,
                "success_rate": success_rate,
                "timestamp": datetime.now().isoformat()
            },
            "consistency_checks": [check.to_dict() for check in self.consistency_checks],
            "recommendations": self.generate_recommendations(),
            "next_steps": self.generate_next_steps()
        }
        
        return report
    
    def generate_recommendations(self) -> List[str]:
        """生成改进建议"""
        recommendations = []
        
        failed_checks = [c for c in self.consistency_checks if c.status == "failed"]
        
        if failed_checks:
            recommendations.append("🔧 修复数据一致性问题")
            recommendations.append("📊 完善缺失的数据")
            recommendations.append("🔍 检查外键约束")
            recommendations.append("📈 优化数据质量")
        else:
            recommendations.append("✅ 数据一致性验证通过")
            recommendations.append("🚀 可以进入下一阶段开发")
            recommendations.append("📈 考虑性能优化")
            recommendations.append("🔍 定期进行数据一致性检查")
        
        return recommendations
    
    def generate_next_steps(self) -> List[str]:
        """生成下一步行动"""
        next_steps = []
        
        failed_checks = [c for c in self.consistency_checks if c.status == "failed"]
        
        if failed_checks:
            next_steps.append("1. 修复数据一致性问题")
            next_steps.append("2. 重新运行数据一致性检查")
            next_steps.append("3. 验证修复结果")
        else:
            next_steps.append("1. 开始Week 2: API网关和认证系统建设")
            next_steps.append("2. 集成数据迁移框架")
            next_steps.append("3. 开发用户界面")
            next_steps.append("4. 进行集成测试")
        
        return next_steps
    
    async def close_connections(self):
        """关闭数据库连接"""
        for db_type, connection in self.connections.items():
            try:
                connection.close()
                self.logger.info(f"✅ {db_type} 连接已关闭")
            except Exception as e:
                self.logger.error(f"❌ {db_type} 连接关闭失败: {str(e)}")


# ==================== 主函数和示例 ====================

async def main():
    """主函数"""
    print("🔄 MBTI数据迁移和更新框架")
    print("版本: v1.0 (数据迁移版)")
    print("基于: MBTI感性AI身份统一实施计划")
    print("=" * 60)
    
    # 数据库配置
    config = {
        "mysql": {
            "host": "localhost",
            "user": "root",
            "password": "password",
            "database": "mbti_db"
        },
        "postgresql": {
            "host": "localhost",
            "user": "postgres",
            "password": "password",
            "database": "mbti_db"
        },
        "sqlite": {
            "database": "mbti.db"
        }
    }
    
    # 初始化迁移框架
    migration_framework = MBTIDataMigrationFramework(config)
    
    try:
        # 初始化数据库连接
        await migration_framework.initialize_connections()
        
        # 创建迁移管理表
        await migration_framework.create_migration_tables()
        
        # 运行数据一致性检查
        print("\n🔍 开始数据一致性检查...")
        consistency_checks = await migration_framework.check_data_consistency()
        
        # 生成迁移报告
        print("\n📊 生成迁移报告...")
        migration_report = await migration_framework.generate_migration_report()
        
        # 输出检查结果
        print("\n📋 数据一致性检查结果")
        print(f"总检查数: {migration_report['migration_summary']['total_checks']}")
        print(f"通过检查: {migration_report['migration_summary']['passed_checks']}")
        print(f"失败检查: {migration_report['migration_summary']['failed_checks']}")
        print(f"成功率: {migration_report['migration_summary']['success_rate']:.1f}%")
        
        # 输出详细结果
        print("\n📋 详细检查结果")
        for check in migration_report['consistency_checks']:
            status_icon = "✅" if check['status'] == 'passed' else "❌"
            print(f"{status_icon} {check['check_name']}: {check['message']}")
        
        # 输出建议
        print("\n💡 改进建议")
        for recommendation in migration_report['recommendations']:
            print(f"  {recommendation}")
        
        # 输出下一步行动
        print("\n🚀 下一步行动")
        for step in migration_report['next_steps']:
            print(f"  {step}")
        
        # 保存迁移报告
        with open('mbti_data_migration_report.json', 'w', encoding='utf-8') as f:
            json.dump(migration_report, f, ensure_ascii=False, indent=2)
        
        print(f"\n📄 迁移报告已保存到: mbti_data_migration_report.json")
        
    except Exception as e:
        print(f"❌ 迁移框架执行失败: {str(e)}")
    finally:
        # 关闭数据库连接
        await migration_framework.close_connections()
    
    print("\n🎉 MBTI数据迁移和更新框架执行完成！")
    print("📋 支持的功能:")
    print("  - 数据库连接管理")
    print("  - 迁移版本管理")
    print("  - 数据一致性检查")
    print("  - 迁移记录管理")
    print("  - 回滚支持")
    print("  - 多数据库支持")


if __name__ == "__main__":
    asyncio.run(main())
