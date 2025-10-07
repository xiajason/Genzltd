#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
数据库结构一致性检查脚本
基于 DAO_DATABASE_VERIFICATION_REPORT.md 的数据库配置
"""

import mysql.connector
import json
import sys
from datetime import datetime
from typing import Dict, List, Any, Optional

class DatabaseSchemaChecker:
    def __init__(self):
        self.environments = {
            'local': {
                'host': 'localhost',
                'port': 3306,
                'user': 'root',
                'password': '123456',
                'dao_port': 9506,
                'dao_user': 'dao_user',
                'dao_password': 'dao_password_2024'
            },
            'tencent': {
                'host': '101.33.251.158',
                'port': 3306,
                'user': 'root',
                'password': '123456',
                'dao_port': 9506,
                'dao_user': 'dao_user',
                'dao_password': 'dao_password_2024'
            },
            'alibaba': {
                'host': '47.115.168.107',
                'port': 3306,
                'user': 'root',
                'password': '123456',
                'dao_port': 9507,
                'dao_user': 'dao_user',
                'dao_password': 'dao_password_2024'
            }
        }
        
        self.results = {
            'timestamp': datetime.now().isoformat(),
            'environments': {},
            'comparisons': {},
            'summary': {}
        }

    def connect_database(self, env: str, db_type: str = 'main') -> Optional[mysql.connector.connection.MySQLConnection]:
        """连接数据库"""
        try:
            config = self.environments[env].copy()
            
            if db_type == 'dao':
                config['port'] = config['dao_port']
                config['user'] = config['dao_user']
                config['password'] = config['dao_password']
            
            connection = mysql.connector.connect(**config)
            return connection
        except mysql.connector.Error as e:
            print(f"❌ 连接 {env} {db_type} 数据库失败: {e}")
            return None

    def get_database_schema(self, env: str, db_type: str = 'main') -> Dict[str, Any]:
        """获取数据库结构"""
        connection = self.connect_database(env, db_type)
        if not connection:
            return {}
        
        try:
            cursor = connection.cursor()
            schema = {
                'databases': {},
                'tables': {},
                'indexes': {},
                'constraints': {}
            }
            
            # 获取数据库列表
            cursor.execute("SHOW DATABASES")
            databases = [row[0] for row in cursor.fetchall()]
            schema['databases'] = databases
            
            # 获取每个数据库的表结构
            for database in databases:
                if database in ['information_schema', 'mysql', 'performance_schema', 'sys']:
                    continue
                    
                cursor.execute(f"USE `{database}`")
                cursor.execute("SHOW TABLES")
                tables = [row[0] for row in cursor.fetchall()]
                
                schema['tables'][database] = {}
                
                for table in tables:
                    # 获取表结构
                    cursor.execute(f"DESCRIBE `{table}`")
                    columns = cursor.fetchall()
                    
                    # 获取表创建语句
                    cursor.execute(f"SHOW CREATE TABLE `{table}`")
                    create_statement = cursor.fetchone()[1]
                    
                    # 获取索引信息
                    cursor.execute(f"SHOW INDEX FROM `{table}`")
                    indexes = cursor.fetchall()
                    
                    schema['tables'][database][table] = {
                        'columns': columns,
                        'create_statement': create_statement,
                        'indexes': indexes
                    }
            
            return schema
            
        except mysql.connector.Error as e:
            print(f"❌ 获取 {env} {db_type} 数据库结构失败: {e}")
            return {}
        finally:
            connection.close()

    def compare_schemas(self, schema1: Dict, schema2: Dict, env1: str, env2: str) -> Dict[str, Any]:
        """比较两个数据库结构"""
        comparison = {
            'databases': {'match': False, 'details': []},
            'tables': {'match': False, 'details': []},
            'columns': {'match': False, 'details': []},
            'indexes': {'match': False, 'details': []}
        }
        
        # 比较数据库列表
        dbs1 = set(schema1.get('databases', []))
        dbs2 = set(schema2.get('databases', []))
        
        if dbs1 == dbs2:
            comparison['databases']['match'] = True
            comparison['databases']['details'] = [f"数据库列表一致: {sorted(dbs1)}"]
        else:
            comparison['databases']['details'] = [
                f"数据库差异:",
                f"  {env1} 独有: {sorted(dbs1 - dbs2)}",
                f"  {env2} 独有: {sorted(dbs2 - dbs1)}",
                f"  共同数据库: {sorted(dbs1 & dbs2)}"
            ]
        
        # 比较表结构
        tables1 = schema1.get('tables', {})
        tables2 = schema2.get('tables', {})
        
        all_tables = set(tables1.keys()) | set(tables2.keys())
        table_matches = []
        
        for db in all_tables:
            if db not in tables1:
                table_matches.append(f"数据库 {db} 在 {env1} 中不存在")
                continue
            if db not in tables2:
                table_matches.append(f"数据库 {db} 在 {env2} 中不存在")
                continue
            
            tables1_db = set(tables1[db].keys())
            tables2_db = set(tables2[db].keys())
            
            if tables1_db == tables2_db:
                table_matches.append(f"数据库 {db} 表结构一致: {sorted(tables1_db)}")
            else:
                table_matches.extend([
                    f"数据库 {db} 表结构差异:",
                    f"  {env1} 独有表: {sorted(tables1_db - tables2_db)}",
                    f"  {env2} 独有表: {sorted(tables2_db - tables1_db)}"
                ])
        
        comparison['tables']['details'] = table_matches
        comparison['tables']['match'] = all("一致" in match for match in table_matches)
        
        return comparison

    def check_environment_consistency(self, env: str) -> Dict[str, Any]:
        """检查单个环境的数据库一致性"""
        print(f"🔍 检查 {env} 环境数据库结构...")
        
        # 检查主数据库
        main_schema = self.get_database_schema(env, 'main')
        
        # 检查DAO数据库
        dao_schema = self.get_database_schema(env, 'dao')
        
        return {
            'main_database': main_schema,
            'dao_database': dao_schema,
            'timestamp': datetime.now().isoformat()
        }

    def run_comprehensive_check(self):
        """运行全面的数据库结构检查"""
        print("🚀 开始三环境数据库结构一致性检查...")
        
        # 检查每个环境
        for env in self.environments.keys():
            self.results['environments'][env] = self.check_environment_consistency(env)
        
        # 进行环境间比较
        print("\n🔄 进行环境间结构比较...")
        
        envs = list(self.environments.keys())
        for i in range(len(envs)):
            for j in range(i + 1, len(envs)):
                env1, env2 = envs[i], envs[j]
                
                print(f"📊 比较 {env1} 和 {env2} 环境...")
                
                # 比较主数据库
                main_schema1 = self.results['environments'][env1]['main_database']
                main_schema2 = self.results['environments'][env2]['main_database']
                main_comparison = self.compare_schemas(main_schema1, main_schema2, env1, env2)
                
                # 比较DAO数据库
                dao_schema1 = self.results['environments'][env1]['dao_database']
                dao_schema2 = self.results['environments'][env2]['dao_database']
                dao_comparison = self.compare_schemas(dao_schema1, dao_schema2, env1, env2)
                
                self.results['comparisons'][f"{env1}_vs_{env2}"] = {
                    'main_database': main_comparison,
                    'dao_database': dao_comparison,
                    'timestamp': datetime.now().isoformat()
                }
        
        # 生成总结
        self.generate_summary()
        
        # 保存结果
        self.save_results()

    def generate_summary(self):
        """生成检查总结"""
        print("\n📊 生成检查总结...")
        
        summary = {
            'total_environments': len(self.environments),
            'total_comparisons': len(self.results['comparisons']),
            'consistency_score': 0,
            'issues': [],
            'recommendations': []
        }
        
        total_checks = 0
        passed_checks = 0
        
        # 分析比较结果
        for comparison_name, comparison in self.results['comparisons'].items():
            for db_type, db_comparison in comparison.items():
                if db_type == 'timestamp':
                    continue
                
                for check_type, check_result in db_comparison.items():
                    total_checks += 1
                    if check_result.get('match', False):
                        passed_checks += 1
                    else:
                        summary['issues'].extend(check_result.get('details', []))
        
        if total_checks > 0:
            summary['consistency_score'] = (passed_checks / total_checks) * 100
        
        # 生成建议
        if summary['consistency_score'] >= 90:
            summary['recommendations'].append("✅ 数据库结构一致性良好，可以继续后续测试")
        elif summary['consistency_score'] >= 70:
            summary['recommendations'].append("⚠️ 存在少量结构不一致，建议修复后继续")
        else:
            summary['recommendations'].append("❌ 存在严重结构不一致，需要全面检查和修复")
        
        self.results['summary'] = summary

    def save_results(self):
        """保存检查结果"""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"database-schema-check-{timestamp}.json"
        
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(self.results, f, indent=2, ensure_ascii=False)
        
        print(f"📁 检查结果已保存到: {filename}")
        
        # 生成Markdown报告
        self.generate_markdown_report(filename)

    def generate_markdown_report(self, json_filename: str):
        """生成Markdown格式的报告"""
        md_filename = json_filename.replace('.json', '.md')
        
        with open(md_filename, 'w', encoding='utf-8') as f:
            f.write(f"# 数据库结构一致性检查报告\n\n")
            f.write(f"**检查时间**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
            f.write(f"**检查版本**: v1.0\n")
            f.write(f"**数据源**: {json_filename}\n\n")
            
            # 添加总结
            summary = self.results['summary']
            f.write(f"## 📊 检查总结\n\n")
            f.write(f"- **检查环境数**: {summary['total_environments']}\n")
            f.write(f"- **比较次数**: {summary['total_comparisons']}\n")
            f.write(f"- **一致性得分**: {summary['consistency_score']:.1f}%\n\n")
            
            # 添加问题列表
            if summary['issues']:
                f.write(f"## ⚠️ 发现的问题\n\n")
                for issue in summary['issues']:
                    f.write(f"- {issue}\n")
                f.write("\n")
            
            # 添加建议
            f.write(f"## 💡 建议\n\n")
            for recommendation in summary['recommendations']:
                f.write(f"- {recommendation}\n")
            f.write("\n")
            
            # 添加详细比较结果
            f.write(f"## 🔍 详细比较结果\n\n")
            for comparison_name, comparison in self.results['comparisons'].items():
                f.write(f"### {comparison_name}\n\n")
                
                for db_type, db_comparison in comparison.items():
                    if db_type == 'timestamp':
                        continue
                    
                    f.write(f"#### {db_type}\n\n")
                    
                    for check_type, check_result in db_comparison.items():
                        status = "✅" if check_result.get('match', False) else "❌"
                        f.write(f"**{check_type}**: {status}\n\n")
                        
                        for detail in check_result.get('details', []):
                            f.write(f"- {detail}\n")
                        f.write("\n")
            
            f.write(f"---\n\n")
            f.write(f"**报告生成时间**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        
        print(f"📄 Markdown报告已保存到: {md_filename}")

def main():
    checker = DatabaseSchemaChecker()
    checker.run_comprehensive_check()
    
    # 显示总结
    summary = checker.results['summary']
    print(f"\n🎯 检查完成!")
    print(f"📊 一致性得分: {summary['consistency_score']:.1f}%")
    print(f"📋 发现问题: {len(summary['issues'])} 个")
    
    for recommendation in summary['recommendations']:
        print(f"💡 {recommendation}")

if __name__ == "__main__":
    main()
