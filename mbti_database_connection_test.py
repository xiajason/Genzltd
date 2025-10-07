#!/usr/bin/env python3
"""
MBTI数据库连接测试脚本
创建时间: 2025年10月4日
版本: v1.0 (连接测试版)
目标: 实地测试MySQL、PostgreSQL和SQLite连接，检查迁移前后的表单和字段
"""

import json
import sqlite3
import pymysql
import psycopg2
from typing import Dict, List, Optional, Any
from dataclasses import dataclass, asdict
from datetime import datetime
import logging
import os


# ==================== 数据模型 ====================

@dataclass
class DatabaseConnectionResult:
    """数据库连接结果"""
    database_type: str
    connection_status: str
    error_message: Optional[str]
    tables_count: int
    tables_list: List[str]
    test_timestamp: datetime
    
    def to_dict(self) -> Dict[str, Any]:
        result = asdict(self)
        result['test_timestamp'] = self.test_timestamp.isoformat()
        return result


# ==================== 数据库连接测试 ====================

class MBTIDatabaseConnectionTest:
    """MBTI数据库连接测试"""
    
    def __init__(self):
        self.logger = logging.getLogger(__name__)
        self.setup_logging()
        self.test_results: List[DatabaseConnectionResult] = []
    
    def setup_logging(self):
        """设置日志"""
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
    
    def test_sqlite_connection(self) -> DatabaseConnectionResult:
        """测试SQLite连接"""
        self.logger.info("🔌 测试SQLite连接")
        
        try:
            connection = sqlite3.connect("mbti.db")
            cursor = connection.cursor()
            
            # 获取表列表
            cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
            tables = [row[0] for row in cursor.fetchall()]
            
            connection.close()
            
            return DatabaseConnectionResult(
                database_type="SQLite",
                connection_status="success",
                error_message=None,
                tables_count=len(tables),
                tables_list=tables,
                test_timestamp=datetime.now()
            )
            
        except Exception as e:
            self.logger.error(f"❌ SQLite连接失败: {str(e)}")
            return DatabaseConnectionResult(
                database_type="SQLite",
                connection_status="failed",
                error_message=str(e),
                tables_count=0,
                tables_list=[],
                test_timestamp=datetime.now()
            )
    
    def test_mysql_connection(self) -> DatabaseConnectionResult:
        """测试MySQL连接"""
        self.logger.info("🔌 测试MySQL连接")
        
        try:
            connection = pymysql.connect(
                host='localhost',
                user='root',
                password='',  # 空密码
                database='mysql',
                charset='utf8mb4'
            )
            cursor = connection.cursor()
            
            # 获取表列表
            cursor.execute("SHOW TABLES")
            tables = [row[0] for row in cursor.fetchall()]
            
            connection.close()
            
            return DatabaseConnectionResult(
                database_type="MySQL",
                connection_status="success",
                error_message=None,
                tables_count=len(tables),
                tables_list=tables,
                test_timestamp=datetime.now()
            )
            
        except Exception as e:
            self.logger.error(f"❌ MySQL连接失败: {str(e)}")
            return DatabaseConnectionResult(
                database_type="MySQL",
                connection_status="failed",
                error_message=str(e),
                tables_count=0,
                tables_list=[],
                test_timestamp=datetime.now()
            )
    
    def test_postgresql_connection(self) -> DatabaseConnectionResult:
        """测试PostgreSQL连接"""
        self.logger.info("🔌 测试PostgreSQL连接")
        
        try:
            connection = psycopg2.connect(
                host='localhost',
                user='postgres',
                password='',
                database='postgres',
                port=5432
            )
            cursor = connection.cursor()
            
            # 获取表列表
            cursor.execute("""
                SELECT table_name 
                FROM information_schema.tables 
                WHERE table_schema = 'public'
            """)
            tables = [row[0] for row in cursor.fetchall()]
            
            connection.close()
            
            return DatabaseConnectionResult(
                database_type="PostgreSQL",
                connection_status="success",
                error_message=None,
                tables_count=len(tables),
                tables_list=tables,
                test_timestamp=datetime.now()
            )
            
        except Exception as e:
            self.logger.error(f"❌ PostgreSQL连接失败: {str(e)}")
            return DatabaseConnectionResult(
                database_type="PostgreSQL",
                connection_status="failed",
                error_message=str(e),
                tables_count=0,
                tables_list=[],
                test_timestamp=datetime.now()
            )
    
    def check_mbti_tables_in_sqlite(self) -> Dict[str, Any]:
        """检查SQLite中的MBTI表结构"""
        self.logger.info("🔍 检查SQLite中的MBTI表结构")
        
        try:
            connection = sqlite3.connect("mbti.db")
            cursor = connection.cursor()
            
            # 检查MBTI相关表
            mbti_tables = [
                "mbti_types", "flowers", "mbti_flower_mappings", 
                "mbti_compatibility_matrix", "careers", "mbti_career_matches",
                "user_mbti_reports", "api_service_configs", "api_call_logs",
                "mbti_dimension_scores", "mbti_question_banks", "mbti_questions",
                "mbti_question_categories", "mbti_test_sessions", "user_mbti_responses"
            ]
            
            table_structures = {}
            
            for table_name in mbti_tables:
                try:
                    cursor.execute(f"PRAGMA table_info({table_name})")
                    columns = cursor.fetchall()
                    
                    cursor.execute(f"SELECT COUNT(*) FROM {table_name}")
                    row_count = cursor.fetchone()[0]
                    
                    table_structures[table_name] = {
                        "exists": True,
                        "columns": [{"name": col[1], "type": col[2], "not_null": col[3], "default": col[4]} for col in columns],
                        "row_count": row_count
                    }
                    
                except Exception as e:
                    table_structures[table_name] = {
                        "exists": False,
                        "error": str(e),
                        "columns": [],
                        "row_count": 0
                    }
            
            connection.close()
            
            return {
                "database_type": "SQLite",
                "mbti_tables": table_structures,
                "total_tables": len([t for t in table_structures.values() if t["exists"]]),
                "check_timestamp": datetime.now().isoformat()
            }
            
        except Exception as e:
            self.logger.error(f"❌ SQLite表结构检查失败: {str(e)}")
            return {
                "database_type": "SQLite",
                "error": str(e),
                "mbti_tables": {},
                "total_tables": 0,
                "check_timestamp": datetime.now().isoformat()
            }
    
    def run_all_tests(self) -> Dict[str, Any]:
        """运行所有数据库连接测试"""
        self.logger.info("🚀 开始数据库连接测试")
        
        # 测试各种数据库连接
        sqlite_result = self.test_sqlite_connection()
        mysql_result = self.test_mysql_connection()
        postgresql_result = self.test_postgresql_connection()
        
        self.test_results = [sqlite_result, mysql_result, postgresql_result]
        
        # 检查SQLite中的MBTI表结构
        mbti_table_check = self.check_mbti_tables_in_sqlite()
        
        return {
            "connection_tests": [result.to_dict() for result in self.test_results],
            "mbti_table_check": mbti_table_check,
            "test_summary": self.generate_test_summary(),
            "recommendations": self.generate_recommendations(),
            "next_steps": self.generate_next_steps()
        }
    
    def generate_test_summary(self) -> Dict[str, Any]:
        """生成测试摘要"""
        total_tests = len(self.test_results)
        successful_tests = len([r for r in self.test_results if r.connection_status == "success"])
        failed_tests = len([r for r in self.test_results if r.connection_status == "failed"])
        
        return {
            "total_tests": total_tests,
            "successful_tests": successful_tests,
            "failed_tests": failed_tests,
            "success_rate": (successful_tests / total_tests * 100) if total_tests > 0 else 0,
            "test_timestamp": datetime.now().isoformat()
        }
    
    def generate_recommendations(self) -> List[str]:
        """生成改进建议"""
        recommendations = []
        
        successful_connections = [r for r in self.test_results if r.connection_status == "success"]
        failed_connections = [r for r in self.test_results if r.connection_status == "failed"]
        
        if successful_connections:
            recommendations.append("✅ 数据库连接正常")
            recommendations.append("🚀 可以开始数据迁移")
            recommendations.append("📊 检查表结构完整性")
            recommendations.append("🔍 验证数据一致性")
        
        if failed_connections:
            recommendations.append("🔧 修复失败的数据库连接")
            recommendations.append("📊 检查数据库配置")
            recommendations.append("🔍 检查网络连接")
            recommendations.append("📈 优化数据库性能")
        
        return recommendations
    
    def generate_next_steps(self) -> List[str]:
        """生成下一步行动"""
        next_steps = []
        
        successful_connections = [r for r in self.test_results if r.connection_status == "success"]
        failed_connections = [r for r in self.test_results if r.connection_status == "failed"]
        
        if failed_connections:
            next_steps.append("1. 修复失败的数据库连接")
            next_steps.append("2. 重新运行连接测试")
            next_steps.append("3. 验证修复结果")
        else:
            next_steps.append("1. 开始数据迁移")
            next_steps.append("2. 验证表结构完整性")
            next_steps.append("3. 检查数据一致性")
            next_steps.append("4. 开始Week 2开发")
        
        return next_steps


# ==================== 主函数和示例 ====================

def main():
    """主函数"""
    print("🔌 MBTI数据库连接测试脚本")
    print("版本: v1.0 (连接测试版)")
    print("目标: 实地测试MySQL、PostgreSQL和SQLite连接")
    print("=" * 60)
    
    # 初始化测试脚本
    test_script = MBTIDatabaseConnectionTest()
    
    try:
        # 运行所有测试
        print("\n🚀 开始数据库连接测试...")
        test_results = test_script.run_all_tests()
        
        # 输出连接测试结果
        print("\n📊 数据库连接测试结果")
        for result in test_results['connection_tests']:
            status_icon = "✅" if result['connection_status'] == 'success' else "❌"
            print(f"{status_icon} {result['database_type']}: {result['connection_status']}")
            if result['error_message']:
                print(f"   错误: {result['error_message']}")
            print(f"   表数量: {result['tables_count']}")
        
        # 输出测试摘要
        print("\n📋 测试摘要")
        summary = test_results['test_summary']
        print(f"总测试数: {summary['total_tests']}")
        print(f"成功测试: {summary['successful_tests']}")
        print(f"失败测试: {summary['failed_tests']}")
        print(f"成功率: {summary['success_rate']:.1f}%")
        
        # 输出MBTI表结构检查结果
        print("\n🔍 MBTI表结构检查结果")
        mbti_check = test_results['mbti_table_check']
        if 'error' in mbti_check:
            print(f"❌ 检查失败: {mbti_check['error']}")
        else:
            print(f"✅ 数据库类型: {mbti_check['database_type']}")
            print(f"✅ 总表数: {mbti_check['total_tables']}")
            
            # 显示每个表的状态
            for table_name, table_info in mbti_check['mbti_tables'].items():
                if table_info['exists']:
                    print(f"  ✅ {table_name}: {table_info['row_count']}行")
                else:
                    print(f"  ❌ {table_name}: 不存在")
        
        # 输出建议
        print("\n💡 改进建议")
        for recommendation in test_results['recommendations']:
            print(f"  {recommendation}")
        
        # 输出下一步行动
        print("\n🚀 下一步行动")
        for step in test_results['next_steps']:
            print(f"  {step}")
        
        # 保存测试报告
        with open('mbti_database_connection_test_report.json', 'w', encoding='utf-8') as f:
            json.dump(test_results, f, ensure_ascii=False, indent=2)
        
        print(f"\n📄 测试报告已保存到: mbti_database_connection_test_report.json")
        
    except Exception as e:
        print(f"❌ 数据库连接测试失败: {str(e)}")
    
    print("\n🎉 MBTI数据库连接测试完成！")
    print("📋 支持的功能:")
    print("  - MySQL连接测试")
    print("  - PostgreSQL连接测试")
    print("  - SQLite连接测试")
    print("  - MBTI表结构检查")
    print("  - 测试报告生成")


if __name__ == "__main__":
    main()
