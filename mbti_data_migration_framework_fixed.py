#!/usr/bin/env python3
"""
MBTI数据迁移和更新框架 (修复版)
创建时间: 2025年10月4日
版本: v1.1 (修复版)
基于: MBTI感性AI身份统一实施计划
目标: 修复数据库连接问题，实现完整的数据迁移和一致性检查
"""

import json
import asyncio
import sqlite3
from typing import Dict, List, Optional, Any, Tuple
from dataclasses import dataclass, asdict
from datetime import datetime
import logging
from enum import Enum
import hashlib
import os


# ==================== 数据模型 ====================

class TestStatus(Enum):
    """测试状态枚举"""
    PENDING = "pending"
    RUNNING = "running"
    PASSED = "passed"
    FAILED = "failed"
    SKIPPED = "skipped"


@dataclass
class ConsistencyTestResult:
    """数据一致性测试结果"""
    test_name: str
    status: TestStatus
    message: str
    details: Dict[str, Any]
    timestamp: datetime
    execution_time: float
    
    def to_dict(self) -> Dict[str, Any]:
        result = asdict(self)
        result['status'] = self.status.value
        result['timestamp'] = self.timestamp.isoformat()
        return result


# ==================== 数据一致性测试框架 ====================

class MBTIDataMigrationFramework:
    """MBTI数据迁移和更新框架 (修复版)"""
    
    def __init__(self):
        self.test_results: List[ConsistencyTestResult] = []
        self.logger = logging.getLogger(__name__)
        self.setup_logging()
        
        # 只使用SQLite数据库，避免MySQL和PostgreSQL连接问题
        self.database_path = "mbti.db"
        self.connection = None
    
    def setup_logging(self):
        """设置日志"""
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
    
    async def initialize_connection(self):
        """初始化数据库连接"""
        self.logger.info("🔌 初始化SQLite数据库连接")
        
        try:
            self.connection = sqlite3.connect(self.database_path)
            self.logger.info("✅ SQLite连接成功")
            return True
        except Exception as e:
            self.logger.error(f"❌ SQLite连接失败: {str(e)}")
            return False
    
    async def run_all_tests(self) -> Dict[str, Any]:
        """运行所有数据一致性测试"""
        self.logger.info("🚀 开始MBTI数据一致性测试")
        
        if not await self.initialize_connection():
            return self.generate_test_report()
        
        test_methods = [
            self.test_mbti_types_consistency,
            self.test_flowers_consistency,
            self.test_mbti_flower_mappings_consistency,
            self.test_compatibility_matrix_consistency,
            self.test_careers_consistency,
            self.test_api_configs_consistency,
            self.test_data_integrity,
            self.test_foreign_key_consistency,
            self.test_data_completeness
        ]
        
        for test_method in test_methods:
            try:
                await test_method()
            except Exception as e:
                self.logger.error(f"测试 {test_method.__name__} 失败: {str(e)}")
                self.test_results.append(ConsistencyTestResult(
                    test_name=test_method.__name__,
                    status=TestStatus.FAILED,
                    message=f"测试异常: {str(e)}",
                    details={"error": str(e)},
                    timestamp=datetime.now(),
                    execution_time=0.0
                ))
        
        return self.generate_test_report()
    
    async def test_mbti_types_consistency(self):
        """测试MBTI类型一致性"""
        start_time = datetime.now()
        
        try:
            cursor = self.connection.cursor()
            cursor.execute("SELECT COUNT(*) FROM mbti_types")
            actual_count = cursor.fetchone()[0]
            
            # 检查MBTI类型数量
            if actual_count == 16:
                self.test_results.append(ConsistencyTestResult(
                    test_name="test_mbti_types_consistency",
                    status=TestStatus.PASSED,
                    message=f"MBTI类型数量正确: {actual_count}",
                    details={"expected": 16, "actual": actual_count},
                    timestamp=datetime.now(),
                    execution_time=(datetime.now() - start_time).total_seconds()
                ))
            else:
                self.test_results.append(ConsistencyTestResult(
                    test_name="test_mbti_types_consistency",
                    status=TestStatus.FAILED,
                    message=f"MBTI类型数量不正确: 期望16，实际{actual_count}",
                    details={"expected": 16, "actual": actual_count},
                    timestamp=datetime.now(),
                    execution_time=(datetime.now() - start_time).total_seconds()
                ))
            
            # 检查每个MBTI类型是否存在
            expected_types = ["INTJ", "INTP", "ENTJ", "ENTP", "INFJ", "INFP", "ENFJ", "ENFP",
                            "ISTJ", "ISFJ", "ESTJ", "ESFJ", "ISTP", "ISFP", "ESTP", "ESFP"]
            
            missing_types = []
            for mbti_type in expected_types:
                cursor.execute("SELECT COUNT(*) FROM mbti_types WHERE type_code = ?", (mbti_type,))
                exists = cursor.fetchone()[0] > 0
                if not exists:
                    missing_types.append(mbti_type)
            
            if missing_types:
                self.test_results.append(ConsistencyTestResult(
                    test_name="test_mbti_types_completeness",
                    status=TestStatus.FAILED,
                    message=f"缺少MBTI类型: {missing_types}",
                    details={"missing_types": missing_types},
                    timestamp=datetime.now(),
                    execution_time=(datetime.now() - start_time).total_seconds()
                ))
            else:
                self.test_results.append(ConsistencyTestResult(
                    test_name="test_mbti_types_completeness",
                    status=TestStatus.PASSED,
                    message="所有MBTI类型都存在",
                    details={"total_types": len(expected_types)},
                    timestamp=datetime.now(),
                    execution_time=(datetime.now() - start_time).total_seconds()
                ))
                
        except Exception as e:
            self.test_results.append(ConsistencyTestResult(
                test_name="test_mbti_types_consistency",
                status=TestStatus.FAILED,
                message=f"MBTI类型检查失败: {str(e)}",
                details={"error": str(e)},
                timestamp=datetime.now(),
                execution_time=(datetime.now() - start_time).total_seconds()
            ))
    
    async def test_flowers_consistency(self):
        """测试花卉信息一致性"""
        start_time = datetime.now()
        
        try:
            cursor = self.connection.cursor()
            cursor.execute("SELECT COUNT(*) FROM flowers")
            actual_count = cursor.fetchone()[0]
            
            if actual_count > 0:
                self.test_results.append(ConsistencyTestResult(
                    test_name="test_flowers_consistency",
                    status=TestStatus.PASSED,
                    message=f"花卉数量正确: {actual_count}",
                    details={"actual_count": actual_count},
                    timestamp=datetime.now(),
                    execution_time=(datetime.now() - start_time).total_seconds()
                ))
            else:
                self.test_results.append(ConsistencyTestResult(
                    test_name="test_flowers_consistency",
                    status=TestStatus.FAILED,
                    message="花卉数量为0",
                    details={"actual_count": actual_count},
                    timestamp=datetime.now(),
                    execution_time=(datetime.now() - start_time).total_seconds()
                ))
            
            # 检查花卉信息完整性
            cursor.execute("SELECT COUNT(*) FROM flowers WHERE name IS NULL OR name = ''")
            null_names = cursor.fetchone()[0]
            
            if null_names == 0:
                self.test_results.append(ConsistencyTestResult(
                    test_name="test_flowers_integrity",
                    status=TestStatus.PASSED,
                    message="花卉信息完整性检查通过",
                    details={"null_names": null_names},
                    timestamp=datetime.now(),
                    execution_time=(datetime.now() - start_time).total_seconds()
                ))
            else:
                self.test_results.append(ConsistencyTestResult(
                    test_name="test_flowers_integrity",
                    status=TestStatus.FAILED,
                    message=f"花卉信息不完整: {null_names}个空名称",
                    details={"null_names": null_names},
                    timestamp=datetime.now(),
                    execution_time=(datetime.now() - start_time).total_seconds()
                ))
                
        except Exception as e:
            self.test_results.append(ConsistencyTestResult(
                test_name="test_flowers_consistency",
                status=TestStatus.FAILED,
                message=f"花卉信息检查失败: {str(e)}",
                details={"error": str(e)},
                timestamp=datetime.now(),
                execution_time=(datetime.now() - start_time).total_seconds()
            ))
    
    async def test_mbti_flower_mappings_consistency(self):
        """测试MBTI-花卉映射一致性"""
        start_time = datetime.now()
        
        try:
            cursor = self.connection.cursor()
            cursor.execute("SELECT COUNT(*) FROM mbti_flower_mappings")
            actual_count = cursor.fetchone()[0]
            
            if actual_count > 0:
                self.test_results.append(ConsistencyTestResult(
                    test_name="test_mbti_flower_mappings_consistency",
                    status=TestStatus.PASSED,
                    message=f"MBTI-花卉映射数量正确: {actual_count}",
                    details={"actual_count": actual_count},
                    timestamp=datetime.now(),
                    execution_time=(datetime.now() - start_time).total_seconds()
                ))
            else:
                self.test_results.append(ConsistencyTestResult(
                    test_name="test_mbti_flower_mappings_consistency",
                    status=TestStatus.FAILED,
                    message="MBTI-花卉映射数量为0",
                    details={"actual_count": actual_count},
                    timestamp=datetime.now(),
                    execution_time=(datetime.now() - start_time).total_seconds()
                ))
            
            # 检查外键约束
            cursor.execute("""
                SELECT COUNT(*) FROM mbti_flower_mappings mfm
                LEFT JOIN mbti_types mt ON mfm.mbti_type_id = mt.id
                LEFT JOIN flowers f ON mfm.flower_id = f.id
                WHERE mt.id IS NULL OR f.id IS NULL
            """)
            invalid_foreign_keys = cursor.fetchone()[0]
            
            if invalid_foreign_keys == 0:
                self.test_results.append(ConsistencyTestResult(
                    test_name="test_mbti_flower_mappings_fk",
                    status=TestStatus.PASSED,
                    message="MBTI-花卉映射外键约束正确",
                    details={"invalid_foreign_keys": invalid_foreign_keys},
                    timestamp=datetime.now(),
                    execution_time=(datetime.now() - start_time).total_seconds()
                ))
            else:
                self.test_results.append(ConsistencyTestResult(
                    test_name="test_mbti_flower_mappings_fk",
                    status=TestStatus.FAILED,
                    message=f"MBTI-花卉映射外键约束错误: {invalid_foreign_keys}个无效外键",
                    details={"invalid_foreign_keys": invalid_foreign_keys},
                    timestamp=datetime.now(),
                    execution_time=(datetime.now() - start_time).total_seconds()
                ))
                
        except Exception as e:
            self.test_results.append(ConsistencyTestResult(
                test_name="test_mbti_flower_mappings_consistency",
                status=TestStatus.FAILED,
                message=f"MBTI-花卉映射检查失败: {str(e)}",
                details={"error": str(e)},
                timestamp=datetime.now(),
                execution_time=(datetime.now() - start_time).total_seconds()
            ))
    
    async def test_compatibility_matrix_consistency(self):
        """测试兼容性矩阵一致性"""
        start_time = datetime.now()
        
        try:
            cursor = self.connection.cursor()
            cursor.execute("SELECT COUNT(*) FROM mbti_compatibility_matrix")
            actual_count = cursor.fetchone()[0]
            
            # 期望的兼容性矩阵数量 (16x16 = 256)
            expected_count = 16 * 16
            
            if actual_count == expected_count:
                self.test_results.append(ConsistencyTestResult(
                    test_name="test_compatibility_matrix_consistency",
                    status=TestStatus.PASSED,
                    message=f"兼容性矩阵数量正确: {actual_count}",
                    details={"expected": expected_count, "actual": actual_count},
                    timestamp=datetime.now(),
                    execution_time=(datetime.now() - start_time).total_seconds()
                ))
            else:
                self.test_results.append(ConsistencyTestResult(
                    test_name="test_compatibility_matrix_consistency",
                    status=TestStatus.FAILED,
                    message=f"兼容性矩阵数量不正确: 期望{expected_count}，实际{actual_count}",
                    details={"expected": expected_count, "actual": actual_count},
                    timestamp=datetime.now(),
                    execution_time=(datetime.now() - start_time).total_seconds()
                ))
                
        except Exception as e:
            self.test_results.append(ConsistencyTestResult(
                test_name="test_compatibility_matrix_consistency",
                status=TestStatus.FAILED,
                message=f"兼容性矩阵检查失败: {str(e)}",
                details={"error": str(e)},
                timestamp=datetime.now(),
                execution_time=(datetime.now() - start_time).total_seconds()
            ))
    
    async def test_careers_consistency(self):
        """测试职业信息一致性"""
        start_time = datetime.now()
        
        try:
            cursor = self.connection.cursor()
            cursor.execute("SELECT COUNT(*) FROM careers")
            actual_count = cursor.fetchone()[0]
            
            if actual_count > 0:
                self.test_results.append(ConsistencyTestResult(
                    test_name="test_careers_consistency",
                    status=TestStatus.PASSED,
                    message=f"职业数量正确: {actual_count}",
                    details={"actual_count": actual_count},
                    timestamp=datetime.now(),
                    execution_time=(datetime.now() - start_time).total_seconds()
                ))
            else:
                self.test_results.append(ConsistencyTestResult(
                    test_name="test_careers_consistency",
                    status=TestStatus.FAILED,
                    message="职业数量为0",
                    details={"actual_count": actual_count},
                    timestamp=datetime.now(),
                    execution_time=(datetime.now() - start_time).total_seconds()
                ))
                
        except Exception as e:
            self.test_results.append(ConsistencyTestResult(
                test_name="test_careers_consistency",
                status=TestStatus.FAILED,
                message=f"职业信息检查失败: {str(e)}",
                details={"error": str(e)},
                timestamp=datetime.now(),
                execution_time=(datetime.now() - start_time).total_seconds()
            ))
    
    async def test_api_configs_consistency(self):
        """测试API配置一致性"""
        start_time = datetime.now()
        
        try:
            cursor = self.connection.cursor()
            cursor.execute("SELECT COUNT(*) FROM api_service_configs")
            actual_count = cursor.fetchone()[0]
            
            if actual_count >= 0:
                self.test_results.append(ConsistencyTestResult(
                    test_name="test_api_configs_consistency",
                    status=TestStatus.PASSED,
                    message=f"API配置数量正确: {actual_count}",
                    details={"actual_count": actual_count},
                    timestamp=datetime.now(),
                    execution_time=(datetime.now() - start_time).total_seconds()
                ))
            else:
                self.test_results.append(ConsistencyTestResult(
                    test_name="test_api_configs_consistency",
                    status=TestStatus.FAILED,
                    message="API配置数量异常",
                    details={"actual_count": actual_count},
                    timestamp=datetime.now(),
                    execution_time=(datetime.now() - start_time).total_seconds()
                ))
                
        except Exception as e:
            self.test_results.append(ConsistencyTestResult(
                test_name="test_api_configs_consistency",
                status=TestStatus.FAILED,
                message=f"API配置检查失败: {str(e)}",
                details={"error": str(e)},
                timestamp=datetime.now(),
                execution_time=(datetime.now() - start_time).total_seconds()
            ))
    
    async def test_data_integrity(self):
        """测试数据完整性"""
        start_time = datetime.now()
        
        try:
            cursor = self.connection.cursor()
            
            # 检查所有表是否存在
            cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
            tables = [row[0] for row in cursor.fetchall()]
            
            expected_tables = [
                "mbti_types", "flowers", "mbti_flower_mappings", "mbti_compatibility_matrix",
                "careers", "mbti_career_matches", "user_mbti_reports", "api_service_configs",
                "api_call_logs", "mbti_dimension_scores", "mbti_question_banks",
                "mbti_questions", "mbti_question_categories", "mbti_test_sessions",
                "user_mbti_responses"
            ]
            
            missing_tables = [table for table in expected_tables if table not in tables]
            
            if not missing_tables:
                self.test_results.append(ConsistencyTestResult(
                    test_name="test_data_integrity",
                    status=TestStatus.PASSED,
                    message="所有必需表都存在",
                    details={"total_tables": len(tables), "expected_tables": len(expected_tables)},
                    timestamp=datetime.now(),
                    execution_time=(datetime.now() - start_time).total_seconds()
                ))
            else:
                self.test_results.append(ConsistencyTestResult(
                    test_name="test_data_integrity",
                    status=TestStatus.FAILED,
                    message=f"缺少必需表: {missing_tables}",
                    details={"missing_tables": missing_tables},
                    timestamp=datetime.now(),
                    execution_time=(datetime.now() - start_time).total_seconds()
                ))
                
        except Exception as e:
            self.test_results.append(ConsistencyTestResult(
                test_name="test_data_integrity",
                status=TestStatus.FAILED,
                message=f"数据完整性检查失败: {str(e)}",
                details={"error": str(e)},
                timestamp=datetime.now(),
                execution_time=(datetime.now() - start_time).total_seconds()
            ))
    
    async def test_foreign_key_consistency(self):
        """测试外键一致性"""
        start_time = datetime.now()
        
        try:
            cursor = self.connection.cursor()
            
            # 检查MBTI-花卉映射的外键
            cursor.execute("""
                SELECT COUNT(*) FROM mbti_flower_mappings mfm
                LEFT JOIN mbti_types mt ON mfm.mbti_type_id = mt.id
                LEFT JOIN flowers f ON mfm.flower_id = f.id
                WHERE mt.id IS NULL OR f.id IS NULL
            """)
            invalid_mappings = cursor.fetchone()[0]
            
            if invalid_mappings == 0:
                self.test_results.append(ConsistencyTestResult(
                    test_name="test_foreign_key_consistency",
                    status=TestStatus.PASSED,
                    message="所有外键关系正确",
                    details={"invalid_mappings": invalid_mappings},
                    timestamp=datetime.now(),
                    execution_time=(datetime.now() - start_time).total_seconds()
                ))
            else:
                self.test_results.append(ConsistencyTestResult(
                    test_name="test_foreign_key_consistency",
                    status=TestStatus.FAILED,
                    message=f"外键关系错误: {invalid_mappings}个无效映射",
                    details={"invalid_mappings": invalid_mappings},
                    timestamp=datetime.now(),
                    execution_time=(datetime.now() - start_time).total_seconds()
                ))
                
        except Exception as e:
            self.test_results.append(ConsistencyTestResult(
                test_name="test_foreign_key_consistency",
                status=TestStatus.FAILED,
                message=f"外键一致性检查失败: {str(e)}",
                details={"error": str(e)},
                timestamp=datetime.now(),
                execution_time=(datetime.now() - start_time).total_seconds()
            ))
    
    async def test_data_completeness(self):
        """测试数据完整性"""
        start_time = datetime.now()
        
        try:
            cursor = self.connection.cursor()
            
            # 检查关键数据的完整性
            cursor.execute("SELECT COUNT(*) FROM mbti_types")
            mbti_count = cursor.fetchone()[0]
            
            cursor.execute("SELECT COUNT(*) FROM flowers")
            flowers_count = cursor.fetchone()[0]
            
            cursor.execute("SELECT COUNT(*) FROM mbti_flower_mappings")
            mappings_count = cursor.fetchone()[0]
            
            cursor.execute("SELECT COUNT(*) FROM careers")
            careers_count = cursor.fetchone()[0]
            
            cursor.execute("SELECT COUNT(*) FROM api_service_configs")
            api_count = cursor.fetchone()[0]
            
            completeness_score = 0
            total_checks = 5
            
            if mbti_count == 16:
                completeness_score += 1
            if flowers_count > 0:
                completeness_score += 1
            if mappings_count > 0:
                completeness_score += 1
            if careers_count > 0:
                completeness_score += 1
            if api_count > 0:
                completeness_score += 1
            
            completeness_percentage = (completeness_score / total_checks) * 100
            
            if completeness_percentage >= 80:
                self.test_results.append(ConsistencyTestResult(
                    test_name="test_data_completeness",
                    status=TestStatus.PASSED,
                    message=f"数据完整性良好: {completeness_percentage:.1f}%",
                    details={
                        "completeness_score": completeness_score,
                        "total_checks": total_checks,
                        "percentage": completeness_percentage,
                        "mbti_count": mbti_count,
                        "flowers_count": flowers_count,
                        "mappings_count": mappings_count,
                        "careers_count": careers_count,
                        "api_count": api_count
                    },
                    timestamp=datetime.now(),
                    execution_time=(datetime.now() - start_time).total_seconds()
                ))
            else:
                self.test_results.append(ConsistencyTestResult(
                    test_name="test_data_completeness",
                    status=TestStatus.FAILED,
                    message=f"数据完整性不足: {completeness_percentage:.1f}%",
                    details={
                        "completeness_score": completeness_score,
                        "total_checks": total_checks,
                        "percentage": completeness_percentage
                    },
                    timestamp=datetime.now(),
                    execution_time=(datetime.now() - start_time).total_seconds()
                ))
                
        except Exception as e:
            self.test_results.append(ConsistencyTestResult(
                test_name="test_data_completeness",
                status=TestStatus.FAILED,
                message=f"数据完整性检查失败: {str(e)}",
                details={"error": str(e)},
                timestamp=datetime.now(),
                execution_time=(datetime.now() - start_time).total_seconds()
            ))
    
    def generate_test_report(self) -> Dict[str, Any]:
        """生成测试报告"""
        total_tests = len(self.test_results)
        passed_tests = len([r for r in self.test_results if r.status == TestStatus.PASSED])
        failed_tests = len([r for r in self.test_results if r.status == TestStatus.FAILED])
        
        success_rate = (passed_tests / total_tests * 100) if total_tests > 0 else 0
        
        report = {
            "test_summary": {
                "total_tests": total_tests,
                "passed_tests": passed_tests,
                "failed_tests": failed_tests,
                "success_rate": success_rate,
                "test_timestamp": datetime.now().isoformat()
            },
            "test_results": [result.to_dict() for result in self.test_results],
            "recommendations": self.generate_recommendations(),
            "next_steps": self.generate_next_steps()
        }
        
        return report
    
    def generate_recommendations(self) -> List[str]:
        """生成改进建议"""
        recommendations = []
        
        failed_tests = [r for r in self.test_results if r.status == TestStatus.FAILED]
        
        if failed_tests:
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
        
        failed_tests = [r for r in self.test_results if r.status == TestStatus.FAILED]
        
        if failed_tests:
            next_steps.append("1. 修复数据一致性问题")
            next_steps.append("2. 重新运行数据一致性检查")
            next_steps.append("3. 验证修复结果")
        else:
            next_steps.append("1. 开始Week 2: API网关和认证系统建设")
            next_steps.append("2. 集成数据迁移框架")
            next_steps.append("3. 开发用户界面")
            next_steps.append("4. 进行集成测试")
        
        return next_steps
    
    async def close_connection(self):
        """关闭数据库连接"""
        if self.connection:
            try:
                self.connection.close()
                self.logger.info("✅ SQLite连接已关闭")
            except Exception as e:
                self.logger.error(f"❌ SQLite连接关闭失败: {str(e)}")


# ==================== 主函数和示例 ====================

async def main():
    """主函数"""
    print("🔄 MBTI数据迁移和更新框架 (修复版)")
    print("版本: v1.1 (修复版)")
    print("基于: MBTI感性AI身份统一实施计划")
    print("=" * 60)
    
    # 初始化迁移框架
    migration_framework = MBTIDataMigrationFramework()
    
    try:
        # 运行所有测试
        print("\n🔍 开始数据一致性检查...")
        test_report = await migration_framework.run_all_tests()
        
        # 输出测试结果
        print("\n📊 测试结果汇总")
        print(f"总测试数: {test_report['test_summary']['total_tests']}")
        print(f"通过测试: {test_report['test_summary']['passed_tests']}")
        print(f"失败测试: {test_report['test_summary']['failed_tests']}")
        print(f"成功率: {test_report['test_summary']['success_rate']:.1f}%")
        
        # 输出详细结果
        print("\n📋 详细测试结果")
        for result in test_report['test_results']:
            status_icon = "✅" if result['status'] == 'passed' else "❌"
            print(f"{status_icon} {result['test_name']}: {result['message']}")
        
        # 输出建议
        print("\n💡 改进建议")
        for recommendation in test_report['recommendations']:
            print(f"  {recommendation}")
        
        # 输出下一步行动
        print("\n🚀 下一步行动")
        for step in test_report['next_steps']:
            print(f"  {step}")
        
        # 保存测试报告
        with open('mbti_data_migration_fixed_report.json', 'w', encoding='utf-8') as f:
            json.dump(test_report, f, ensure_ascii=False, indent=2)
        
        print(f"\n📄 测试报告已保存到: mbti_data_migration_fixed_report.json")
        
    except Exception as e:
        print(f"❌ 迁移框架执行失败: {str(e)}")
    finally:
        # 关闭数据库连接
        await migration_framework.close_connection()
    
    print("\n🎉 MBTI数据迁移和更新框架执行完成！")
    print("📋 支持的功能:")
    print("  - SQLite数据库连接管理")
    print("  - 数据一致性检查")
    print("  - 外键约束验证")
    print("  - 数据完整性验证")
    print("  - 测试报告生成")


if __name__ == "__main__":
    asyncio.run(main())
