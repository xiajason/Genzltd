#!/usr/bin/env python3
"""
Future版多数据库结构创建执行脚本
版本: V1.0
日期: 2025年10月5日
描述: 一键执行Future版所有数据库结构的创建和配置
"""

import subprocess
import sys
import os
import time
from datetime import datetime
from typing import List, Dict, Any

class FutureDatabaseStructureExecutor:
    """Future版多数据库结构创建执行器"""
    
    def __init__(self):
        """初始化执行器"""
        self.scripts = {
            'mysql': 'future_mysql_database_structure.sql',
            'postgresql': 'future_postgresql_database_structure.sql',
            'sqlite': 'future_sqlite_database_structure.py',
            'redis': 'future_redis_database_structure.py',
            'neo4j': 'future_neo4j_database_structure.py',
            'elasticsearch': 'future_elasticsearch_database_structure.py',
            'weaviate': 'future_weaviate_database_structure.py'
        }
        
        self.execution_results = {}
    
    def execute_all_structures(self):
        """执行所有数据库结构创建"""
        print("🚀 开始执行Future版多数据库结构创建...")
        print("=" * 60)
        
        # 1. 执行MySQL数据库结构创建
        self._execute_mysql_structure()
        
        # 2. 执行PostgreSQL数据库结构创建
        self._execute_postgresql_structure()
        
        # 3. 执行SQLite数据库结构创建
        self._execute_sqlite_structure()
        
        # 4. 执行Redis数据库结构配置
        self._execute_redis_structure()
        
        # 5. 执行Neo4j数据库结构创建
        self._execute_neo4j_structure()
        
        # 6. 执行Elasticsearch索引结构创建
        self._execute_elasticsearch_structure()
        
        # 7. 执行Weaviate向量数据库结构创建
        self._execute_weaviate_structure()
        
        # 8. 执行验证
        self._execute_verification()
        
        # 9. 生成执行报告
        self._generate_execution_report()
        
        print("✅ Future版多数据库结构创建执行完成！")
    
    def _execute_mysql_structure(self):
        """执行MySQL数据库结构创建"""
        print("📝 执行MySQL数据库结构创建...")
        
        try:
            # 检查SQL文件是否存在
            sql_file = self.scripts['mysql']
            if not os.path.exists(sql_file):
                self.execution_results['mysql'] = {
                    'status': 'failed',
                    'error': f'SQL文件不存在: {sql_file}'
                }
                print(f"❌ MySQL: SQL文件不存在 - {sql_file}")
                return
            
            # 执行MySQL脚本
            cmd = f"mysql -u root -p < {sql_file}"
            result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
            
            if result.returncode == 0:
                self.execution_results['mysql'] = {
                    'status': 'success',
                    'output': result.stdout,
                    'error': result.stderr
                }
                print("✅ MySQL: 数据库结构创建成功")
            else:
                self.execution_results['mysql'] = {
                    'status': 'failed',
                    'error': result.stderr,
                    'output': result.stdout
                }
                print(f"❌ MySQL: 执行失败 - {result.stderr}")
                
        except Exception as e:
            self.execution_results['mysql'] = {
                'status': 'failed',
                'error': str(e)
            }
            print(f"❌ MySQL: 执行异常 - {e}")
    
    def _execute_postgresql_structure(self):
        """执行PostgreSQL数据库结构创建"""
        print("📝 执行PostgreSQL数据库结构创建...")
        
        try:
            # 检查SQL文件是否存在
            sql_file = self.scripts['postgresql']
            if not os.path.exists(sql_file):
                self.execution_results['postgresql'] = {
                    'status': 'failed',
                    'error': f'SQL文件不存在: {sql_file}'
                }
                print(f"❌ PostgreSQL: SQL文件不存在 - {sql_file}")
                return
            
            # 执行PostgreSQL脚本
            cmd = f"psql -h localhost -U postgres -d jobfirst_future -f {sql_file}"
            result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
            
            if result.returncode == 0:
                self.execution_results['postgresql'] = {
                    'status': 'success',
                    'output': result.stdout,
                    'error': result.stderr
                }
                print("✅ PostgreSQL: 数据库结构创建成功")
            else:
                self.execution_results['postgresql'] = {
                    'status': 'failed',
                    'error': result.stderr,
                    'output': result.stdout
                }
                print(f"❌ PostgreSQL: 执行失败 - {result.stderr}")
                
        except Exception as e:
            self.execution_results['postgresql'] = {
                'status': 'failed',
                'error': str(e)
            }
            print(f"❌ PostgreSQL: 执行异常 - {e}")
    
    def _execute_sqlite_structure(self):
        """执行SQLite数据库结构创建"""
        print("📝 执行SQLite数据库结构创建...")
        
        try:
            # 检查Python脚本是否存在
            python_file = self.scripts['sqlite']
            if not os.path.exists(python_file):
                self.execution_results['sqlite'] = {
                    'status': 'failed',
                    'error': f'Python脚本不存在: {python_file}'
                }
                print(f"❌ SQLite: Python脚本不存在 - {python_file}")
                return
            
            # 执行Python脚本
            cmd = f"python3 {python_file}"
            result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
            
            if result.returncode == 0:
                self.execution_results['sqlite'] = {
                    'status': 'success',
                    'output': result.stdout,
                    'error': result.stderr
                }
                print("✅ SQLite: 数据库结构创建成功")
            else:
                self.execution_results['sqlite'] = {
                    'status': 'failed',
                    'error': result.stderr,
                    'output': result.stdout
                }
                print(f"❌ SQLite: 执行失败 - {result.stderr}")
                
        except Exception as e:
            self.execution_results['sqlite'] = {
                'status': 'failed',
                'error': str(e)
            }
            print(f"❌ SQLite: 执行异常 - {e}")
    
    def _execute_redis_structure(self):
        """执行Redis数据库结构配置"""
        print("📝 执行Redis数据库结构配置...")
        
        try:
            # 检查Python脚本是否存在
            python_file = self.scripts['redis']
            if not os.path.exists(python_file):
                self.execution_results['redis'] = {
                    'status': 'failed',
                    'error': f'Python脚本不存在: {python_file}'
                }
                print(f"❌ Redis: Python脚本不存在 - {python_file}")
                return
            
            # 执行Python脚本
            cmd = f"python3 {python_file}"
            result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
            
            if result.returncode == 0:
                self.execution_results['redis'] = {
                    'status': 'success',
                    'output': result.stdout,
                    'error': result.stderr
                }
                print("✅ Redis: 数据库结构配置成功")
            else:
                self.execution_results['redis'] = {
                    'status': 'failed',
                    'error': result.stderr,
                    'output': result.stdout
                }
                print(f"❌ Redis: 执行失败 - {result.stderr}")
                
        except Exception as e:
            self.execution_results['redis'] = {
                'status': 'failed',
                'error': str(e)
            }
            print(f"❌ Redis: 执行异常 - {e}")
    
    def _execute_neo4j_structure(self):
        """执行Neo4j数据库结构创建"""
        print("📝 执行Neo4j数据库结构创建...")
        
        try:
            # 检查Python脚本是否存在
            python_file = self.scripts['neo4j']
            if not os.path.exists(python_file):
                self.execution_results['neo4j'] = {
                    'status': 'failed',
                    'error': f'Python脚本不存在: {python_file}'
                }
                print(f"❌ Neo4j: Python脚本不存在 - {python_file}")
                return
            
            # 执行Python脚本
            cmd = f"python3 {python_file}"
            result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
            
            if result.returncode == 0:
                self.execution_results['neo4j'] = {
                    'status': 'success',
                    'output': result.stdout,
                    'error': result.stderr
                }
                print("✅ Neo4j: 数据库结构创建成功")
            else:
                self.execution_results['neo4j'] = {
                    'status': 'failed',
                    'error': result.stderr,
                    'output': result.stdout
                }
                print(f"❌ Neo4j: 执行失败 - {result.stderr}")
                
        except Exception as e:
            self.execution_results['neo4j'] = {
                'status': 'failed',
                'error': str(e)
            }
            print(f"❌ Neo4j: 执行异常 - {e}")
    
    def _execute_elasticsearch_structure(self):
        """执行Elasticsearch索引结构创建"""
        print("📝 执行Elasticsearch索引结构创建...")
        
        try:
            # 检查Python脚本是否存在
            python_file = self.scripts['elasticsearch']
            if not os.path.exists(python_file):
                self.execution_results['elasticsearch'] = {
                    'status': 'failed',
                    'error': f'Python脚本不存在: {python_file}'
                }
                print(f"❌ Elasticsearch: Python脚本不存在 - {python_file}")
                return
            
            # 执行Python脚本
            cmd = f"python3 {python_file}"
            result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
            
            if result.returncode == 0:
                self.execution_results['elasticsearch'] = {
                    'status': 'success',
                    'output': result.stdout,
                    'error': result.stderr
                }
                print("✅ Elasticsearch: 索引结构创建成功")
            else:
                self.execution_results['elasticsearch'] = {
                    'status': 'failed',
                    'error': result.stderr,
                    'output': result.stdout
                }
                print(f"❌ Elasticsearch: 执行失败 - {result.stderr}")
                
        except Exception as e:
            self.execution_results['elasticsearch'] = {
                'status': 'failed',
                'error': str(e)
            }
            print(f"❌ Elasticsearch: 执行异常 - {e}")
    
    def _execute_weaviate_structure(self):
        """执行Weaviate向量数据库结构创建"""
        print("📝 执行Weaviate向量数据库结构创建...")
        
        try:
            # 检查Python脚本是否存在
            python_file = self.scripts['weaviate']
            if not os.path.exists(python_file):
                self.execution_results['weaviate'] = {
                    'status': 'failed',
                    'error': f'Python脚本不存在: {python_file}'
                }
                print(f"❌ Weaviate: Python脚本不存在 - {python_file}")
                return
            
            # 执行Python脚本
            cmd = f"python3 {python_file}"
            result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
            
            if result.returncode == 0:
                self.execution_results['weaviate'] = {
                    'status': 'success',
                    'output': result.stdout,
                    'error': result.stderr
                }
                print("✅ Weaviate: 向量数据库结构创建成功")
            else:
                self.execution_results['weaviate'] = {
                    'status': 'failed',
                    'error': result.stderr,
                    'output': result.stdout
                }
                print(f"❌ Weaviate: 执行失败 - {result.stderr}")
                
        except Exception as e:
            self.execution_results['weaviate'] = {
                'status': 'failed',
                'error': str(e)
            }
            print(f"❌ Weaviate: 执行异常 - {e}")
    
    def _execute_verification(self):
        """执行验证"""
        print("📝 执行数据库结构验证...")
        
        try:
            # 检查验证脚本是否存在
            verification_file = 'future_database_verification_script.py'
            if not os.path.exists(verification_file):
                self.execution_results['verification'] = {
                    'status': 'failed',
                    'error': f'验证脚本不存在: {verification_file}'
                }
                print(f"❌ 验证: 验证脚本不存在 - {verification_file}")
                return
            
            # 执行验证脚本
            cmd = f"python3 {verification_file}"
            result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
            
            if result.returncode == 0:
                self.execution_results['verification'] = {
                    'status': 'success',
                    'output': result.stdout,
                    'error': result.stderr
                }
                print("✅ 验证: 数据库结构验证成功")
            else:
                self.execution_results['verification'] = {
                    'status': 'failed',
                    'error': result.stderr,
                    'output': result.stdout
                }
                print(f"❌ 验证: 执行失败 - {result.stderr}")
                
        except Exception as e:
            self.execution_results['verification'] = {
                'status': 'failed',
                'error': str(e)
            }
            print(f"❌ 验证: 执行异常 - {e}")
    
    def _generate_execution_report(self):
        """生成执行报告"""
        print("\n" + "=" * 60)
        print("📊 Future版多数据库结构创建执行报告")
        print("=" * 60)
        
        # 统计执行结果
        total_scripts = len(self.execution_results)
        successful_scripts = len([r for r in self.execution_results.values() if r.get('status') == 'success'])
        failed_scripts = len([r for r in self.execution_results.values() if r.get('status') == 'failed'])
        
        print(f"📈 执行统计:")
        print(f"  总脚本数: {total_scripts}")
        print(f"  成功执行: {successful_scripts}")
        print(f"  执行失败: {failed_scripts}")
        print(f"  成功率: {successful_scripts / total_scripts * 100:.1f}%")
        
        print(f"\n📋 详细结果:")
        for script_name, result in self.execution_results.items():
            status_icon = "✅" if result.get('status') == 'success' else "❌"
            print(f"  {status_icon} {script_name.upper()}: {result.get('status', 'unknown')}")
            
            if result.get('status') == 'failed' and 'error' in result:
                print(f"    错误: {result['error']}")
        
        # 保存执行报告
        report_data = {
            'execution_time': datetime.now().isoformat(),
            'total_scripts': total_scripts,
            'successful_scripts': successful_scripts,
            'failed_scripts': failed_scripts,
            'success_rate': successful_scripts / total_scripts * 100,
            'detailed_results': self.execution_results
        }
        
        import json
        with open('future_database_execution_report.json', 'w', encoding='utf-8') as f:
            json.dump(report_data, f, indent=2, ensure_ascii=False)
        
        print(f"\n💾 执行报告已保存到: future_database_execution_report.json")
        print(f"🎉 Future版多数据库结构创建执行完成！")

def main():
    """主函数"""
    print("🎯 Future版多数据库结构创建执行脚本")
    print("=" * 50)
    
    # 创建执行器
    executor = FutureDatabaseStructureExecutor()
    
    # 执行所有结构创建
    executor.execute_all_structures()

if __name__ == "__main__":
    main()
