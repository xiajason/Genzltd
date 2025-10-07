#!/usr/bin/env python3
"""
Future版多数据库结构验证脚本
版本: V1.0
日期: 2025年10月5日
描述: 验证Future版所有数据库结构的创建结果和完整性
"""

import mysql.connector
import psycopg2
import sqlite3
import redis
import requests
from neo4j import GraphDatabase
from elasticsearch import Elasticsearch
import weaviate
import json
from datetime import datetime
from typing import Dict, List, Any, Tuple

class FutureDatabaseVerifier:
    """Future版多数据库结构验证器"""
    
    def __init__(self):
        """初始化数据库连接配置"""
        self.mysql_config = {
            'host': 'localhost',
            'user': 'root',
            'password': 'your_password',
            'database': 'jobfirst_future'
        }
        
        self.postgresql_config = {
            'host': 'localhost',
            'port': 5432,
            'user': 'postgres',
            'password': 'your_password',
            'database': 'jobfirst_future'
        }
        
        self.redis_config = {
            'host': 'localhost',
            'port': 6379,
            'password': None,
            'db': 0
        }
        
        self.neo4j_config = {
            'uri': 'bolt://localhost:7687',
            'username': 'neo4j',
            'password': 'jobfirst_password_2024'
        }
        
        self.elasticsearch_config = {
            'host': 'localhost',
            'port': 9200
        }
        
        self.weaviate_config = {
            'url': 'http://localhost:8080'
        }
        
        self.verification_results = {}
    
    def verify_all_databases(self):
        """验证所有数据库结构"""
        print("🚀 开始验证Future版多数据库结构...")
        print("=" * 60)
        
        # 1. 验证MySQL数据库
        self._verify_mysql_database()
        
        # 2. 验证PostgreSQL数据库
        self._verify_postgresql_database()
        
        # 3. 验证SQLite数据库
        self._verify_sqlite_database()
        
        # 4. 验证Redis数据库
        self._verify_redis_database()
        
        # 5. 验证Neo4j数据库
        self._verify_neo4j_database()
        
        # 6. 验证Elasticsearch数据库
        self._verify_elasticsearch_database()
        
        # 7. 验证Weaviate数据库
        self._verify_weaviate_database()
        
        # 8. 生成验证报告
        self._generate_verification_report()
        
        print("✅ Future版多数据库结构验证完成！")
    
    def _verify_mysql_database(self):
        """验证MySQL数据库结构"""
        print("📝 验证MySQL数据库结构...")
        
        try:
            # 连接MySQL
            conn = mysql.connector.connect(**self.mysql_config)
            cursor = conn.cursor()
            
            # 检查数据库是否存在
            cursor.execute("SHOW DATABASES LIKE 'jobfirst_future'")
            db_exists = cursor.fetchone() is not None
            
            if not db_exists:
                self.verification_results['mysql'] = {
                    'status': 'failed',
                    'error': '数据库不存在',
                    'tables': 0,
                    'total_records': 0
                }
                print("❌ MySQL数据库不存在")
                return
            
            # 切换到目标数据库
            cursor.execute("USE jobfirst_future")
            
            # 获取所有表
            cursor.execute("SHOW TABLES")
            tables = [row[0] for row in cursor.fetchall()]
            
            # 统计记录数
            total_records = 0
            for table in tables:
                cursor.execute(f"SELECT COUNT(*) FROM {table}")
                count = cursor.fetchone()[0]
                total_records += count
            
            # 检查关键表
            expected_tables = [
                'users', 'user_profiles', 'user_sessions', 'resume_metadata',
                'resume_files', 'resume_templates', 'resume_analyses',
                'skills', 'companies', 'positions', 'resume_skills',
                'work_experiences', 'projects', 'educations', 'certifications',
                'resume_comments', 'resume_likes', 'resume_shares',
                'points', 'point_history', 'system_configs', 'operation_logs'
            ]
            
            missing_tables = set(expected_tables) - set(tables)
            
            self.verification_results['mysql'] = {
                'status': 'success' if not missing_tables else 'partial',
                'database_exists': True,
                'tables': len(tables),
                'expected_tables': len(expected_tables),
                'missing_tables': list(missing_tables),
                'total_records': total_records,
                'tables_list': tables
            }
            
            status = "✅" if not missing_tables else "⚠️"
            print(f"{status} MySQL: {len(tables)}/{len(expected_tables)} 表, {total_records} 记录")
            if missing_tables:
                print(f"    缺少表: {missing_tables}")
            
            conn.close()
            
        except Exception as e:
            self.verification_results['mysql'] = {
                'status': 'failed',
                'error': str(e),
                'tables': 0,
                'total_records': 0
            }
            print(f"❌ MySQL验证失败: {e}")
    
    def _verify_postgresql_database(self):
        """验证PostgreSQL数据库结构"""
        print("📝 验证PostgreSQL数据库结构...")
        
        try:
            # 连接PostgreSQL
            conn = psycopg2.connect(**self.postgresql_config)
            cursor = conn.cursor()
            
            # 获取所有表
            cursor.execute("""
                SELECT table_name 
                FROM information_schema.tables 
                WHERE table_schema = 'public'
            """)
            tables = [row[0] for row in cursor.fetchall()]
            
            # 统计记录数
            total_records = 0
            for table in tables:
                cursor.execute(f"SELECT COUNT(*) FROM {table}")
                count = cursor.fetchone()[0]
                total_records += count
            
            # 检查关键表
            expected_tables = [
                'ai_models', 'model_versions', 'company_ai_profiles',
                'company_embeddings', 'job_ai_analysis', 'job_embeddings',
                'resume_ai_analysis', 'resume_embeddings', 'user_ai_profiles',
                'user_embeddings', 'job_matches', 'resume_matches',
                'ai_service_calls', 'ai_service_stats', 'vector_search_history',
                'vector_similarity_cache'
            ]
            
            missing_tables = set(expected_tables) - set(tables)
            
            self.verification_results['postgresql'] = {
                'status': 'success' if not missing_tables else 'partial',
                'tables': len(tables),
                'expected_tables': len(expected_tables),
                'missing_tables': list(missing_tables),
                'total_records': total_records,
                'tables_list': tables
            }
            
            status = "✅" if not missing_tables else "⚠️"
            print(f"{status} PostgreSQL: {len(tables)}/{len(expected_tables)} 表, {total_records} 记录")
            if missing_tables:
                print(f"    缺少表: {missing_tables}")
            
            conn.close()
            
        except Exception as e:
            self.verification_results['postgresql'] = {
                'status': 'failed',
                'error': str(e),
                'tables': 0,
                'total_records': 0
            }
            print(f"❌ PostgreSQL验证失败: {e}")
    
    def _verify_sqlite_database(self):
        """验证SQLite数据库结构"""
        print("📝 验证SQLite数据库结构...")
        
        try:
            # 检查用户数据库目录
            import os
            user_db_path = "./data/users"
            
            if not os.path.exists(user_db_path):
                self.verification_results['sqlite'] = {
                    'status': 'failed',
                    'error': '用户数据库目录不存在',
                    'user_databases': 0,
                    'total_tables': 0
                }
                print("❌ SQLite用户数据库目录不存在")
                return
            
            # 统计用户数据库
            user_dirs = [d for d in os.listdir(user_db_path) if os.path.isdir(os.path.join(user_db_path, d))]
            user_databases = 0
            total_tables = 0
            
            for user_dir in user_dirs:
                db_path = os.path.join(user_db_path, user_dir, "resume.db")
                if os.path.exists(db_path):
                    user_databases += 1
                    # 检查表结构
                    conn = sqlite3.connect(db_path)
                    cursor = conn.cursor()
                    cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
                    tables = [row[0] for row in cursor.fetchall()]
                    total_tables += len(tables)
                    conn.close()
            
            # 检查关键表
            expected_tables = [
                'resume_content', 'parsed_resume_data', 'user_privacy_settings',
                'resume_versions', 'user_custom_fields', 'resume_access_logs', 'user_preferences'
            ]
            
            self.verification_results['sqlite'] = {
                'status': 'success' if user_databases > 0 else 'failed',
                'user_databases': user_databases,
                'expected_tables_per_user': len(expected_tables),
                'total_tables': total_tables,
                'expected_tables': expected_tables
            }
            
            status = "✅" if user_databases > 0 else "❌"
            print(f"{status} SQLite: {user_databases} 用户数据库, {total_tables} 总表数")
            
        except Exception as e:
            self.verification_results['sqlite'] = {
                'status': 'failed',
                'error': str(e),
                'user_databases': 0,
                'total_tables': 0
            }
            print(f"❌ SQLite验证失败: {e}")
    
    def _verify_redis_database(self):
        """验证Redis数据库结构"""
        print("📝 验证Redis数据库结构...")
        
        try:
            # 连接Redis
            r = redis.Redis(**self.redis_config)
            
            # 测试连接
            r.ping()
            
            # 获取所有键
            keys = r.keys('*')
            
            # 统计不同类型的键
            key_types = {}
            for key in keys:
                key_type = r.type(key).decode('utf-8')
                key_types[key_type] = key_types.get(key_type, 0) + 1
            
            # 检查关键模式
            expected_patterns = [
                'session:*', 'cache:*', 'queue:*', 'rate_limit:*'
            ]
            
            pattern_counts = {}
            for pattern in expected_patterns:
                pattern_keys = r.keys(pattern)
                pattern_counts[pattern] = len(pattern_keys)
            
            self.verification_results['redis'] = {
                'status': 'success',
                'total_keys': len(keys),
                'key_types': key_types,
                'pattern_counts': pattern_counts
            }
            
            print(f"✅ Redis: {len(keys)} 键, 类型分布: {key_types}")
            
        except Exception as e:
            self.verification_results['redis'] = {
                'status': 'failed',
                'error': str(e),
                'total_keys': 0
            }
            print(f"❌ Redis验证失败: {e}")
    
    def _verify_neo4j_database(self):
        """验证Neo4j数据库结构"""
        print("📝 验证Neo4j数据库结构...")
        
        try:
            # 连接Neo4j
            driver = GraphDatabase.driver(
                self.neo4j_config['uri'],
                auth=(self.neo4j_config['username'], self.neo4j_config['password'])
            )
            
            with driver.session() as session:
                # 获取节点标签
                result = session.run("CALL db.labels()")
                labels = [record['label'] for record in result]
                
                # 获取关系类型
                result = session.run("CALL db.relationshipTypes()")
                relationship_types = [record['relationshipType'] for record in result]
                
                # 统计节点数量
                node_counts = {}
                for label in labels:
                    result = session.run(f"MATCH (n:{label}) RETURN count(n) as count")
                    count = result.single()['count']
                    node_counts[label] = count
                
                # 统计关系数量
                rel_counts = {}
                for rel_type in relationship_types:
                    result = session.run(f"MATCH ()-[r:{rel_type}]->() RETURN count(r) as count")
                    count = result.single()['count']
                    rel_counts[rel_type] = count
                
                self.verification_results['neo4j'] = {
                    'status': 'success',
                    'labels': labels,
                    'relationship_types': relationship_types,
                    'node_counts': node_counts,
                    'rel_counts': rel_counts
                }
                
                total_nodes = sum(node_counts.values())
                total_rels = sum(rel_counts.values())
                print(f"✅ Neo4j: {len(labels)} 标签, {len(relationship_types)} 关系类型")
                print(f"    节点: {total_nodes}, 关系: {total_rels}")
            
            driver.close()
            
        except Exception as e:
            self.verification_results['neo4j'] = {
                'status': 'failed',
                'error': str(e),
                'labels': [],
                'relationship_types': []
            }
            print(f"❌ Neo4j验证失败: {e}")
    
    def _verify_elasticsearch_database(self):
        """验证Elasticsearch数据库结构"""
        print("📝 验证Elasticsearch数据库结构...")
        
        try:
            # 连接Elasticsearch
            es = Elasticsearch([{'host': self.elasticsearch_config['host'], 'port': self.elasticsearch_config['port']}])
            
            # 获取所有索引
            indices = es.indices.get('*')
            
            # 过滤Future版索引
            future_indices = {name: info for name, info in indices.items() if 'jobfirst_future' in name}
            
            # 统计文档数量
            total_docs = 0
            index_docs = {}
            for index_name in future_indices.keys():
                count_result = es.count(index=index_name)
                doc_count = count_result['count']
                index_docs[index_name] = doc_count
                total_docs += doc_count
            
            self.verification_results['elasticsearch'] = {
                'status': 'success',
                'indices': list(future_indices.keys()),
                'total_docs': total_docs,
                'index_docs': index_docs
            }
            
            print(f"✅ Elasticsearch: {len(future_indices)} 索引, {total_docs} 文档")
            
        except Exception as e:
            self.verification_results['elasticsearch'] = {
                'status': 'failed',
                'error': str(e),
                'indices': [],
                'total_docs': 0
            }
            print(f"❌ Elasticsearch验证失败: {e}")
    
    def _verify_weaviate_database(self):
        """验证Weaviate数据库结构"""
        print("📝 验证Weaviate数据库结构...")
        
        try:
            # 连接Weaviate
            client = weaviate.Client(self.weaviate_config['url'])
            
            # 获取所有类
            schema = client.schema.get()
            classes = [cls['class'] for cls in schema['classes']]
            
            # 统计对象数量
            total_objects = 0
            class_objects = {}
            for class_name in classes:
                result = client.query.get(class_name).with_meta_count().do()
                object_count = result.get('data', {}).get('Get', {}).get(class_name, [])
                count = len(object_count) if isinstance(object_count, list) else 0
                class_objects[class_name] = count
                total_objects += count
            
            self.verification_results['weaviate'] = {
                'status': 'success',
                'classes': classes,
                'total_objects': total_objects,
                'class_objects': class_objects
            }
            
            print(f"✅ Weaviate: {len(classes)} 类, {total_objects} 对象")
            
        except Exception as e:
            self.verification_results['weaviate'] = {
                'status': 'failed',
                'error': str(e),
                'classes': [],
                'total_objects': 0
            }
            print(f"❌ Weaviate验证失败: {e}")
    
    def _generate_verification_report(self):
        """生成验证报告"""
        print("\n" + "=" * 60)
        print("📊 Future版多数据库结构验证报告")
        print("=" * 60)
        
        # 统计总体结果
        total_databases = len(self.verification_results)
        successful_databases = len([r for r in self.verification_results.values() if r.get('status') == 'success'])
        partial_databases = len([r for r in self.verification_results.values() if r.get('status') == 'partial'])
        failed_databases = len([r for r in self.verification_results.values() if r.get('status') == 'failed'])
        
        print(f"📈 总体统计:")
        print(f"  总数据库数: {total_databases}")
        print(f"  完全成功: {successful_databases}")
        print(f"  部分成功: {partial_databases}")
        print(f"  失败: {failed_databases}")
        print(f"  成功率: {(successful_databases + partial_databases) / total_databases * 100:.1f}%")
        
        print(f"\n📋 详细结果:")
        for db_name, result in self.verification_results.items():
            status_icon = {
                'success': '✅',
                'partial': '⚠️',
                'failed': '❌'
            }.get(result.get('status', 'unknown'), '❓')
            
            print(f"  {status_icon} {db_name.upper()}: {result.get('status', 'unknown')}")
            
            # 显示具体信息
            if db_name == 'mysql':
                tables = result.get('tables', 0)
                records = result.get('total_records', 0)
                print(f"    表数: {tables}, 记录数: {records}")
            elif db_name == 'postgresql':
                tables = result.get('tables', 0)
                records = result.get('total_records', 0)
                print(f"    表数: {tables}, 记录数: {records}")
            elif db_name == 'sqlite':
                user_dbs = result.get('user_databases', 0)
                tables = result.get('total_tables', 0)
                print(f"    用户数据库: {user_dbs}, 总表数: {tables}")
            elif db_name == 'redis':
                keys = result.get('total_keys', 0)
                print(f"    键数: {keys}")
            elif db_name == 'neo4j':
                labels = len(result.get('labels', []))
                rels = len(result.get('relationship_types', []))
                print(f"    标签: {labels}, 关系类型: {rels}")
            elif db_name == 'elasticsearch':
                indices = len(result.get('indices', []))
                docs = result.get('total_docs', 0)
                print(f"    索引: {indices}, 文档: {docs}")
            elif db_name == 'weaviate':
                classes = len(result.get('classes', []))
                objects = result.get('total_objects', 0)
                print(f"    类: {classes}, 对象: {objects}")
            
            # 显示错误信息
            if 'error' in result:
                print(f"    错误: {result['error']}")
        
        # 保存报告到文件
        report_data = {
            'verification_time': datetime.now().isoformat(),
            'total_databases': total_databases,
            'successful_databases': successful_databases,
            'partial_databases': partial_databases,
            'failed_databases': failed_databases,
            'success_rate': (successful_databases + partial_databases) / total_databases * 100,
            'detailed_results': self.verification_results
        }
        
        with open('future_database_verification_report.json', 'w', encoding='utf-8') as f:
            json.dump(report_data, f, indent=2, ensure_ascii=False)
        
        print(f"\n💾 详细报告已保存到: future_database_verification_report.json")
        print(f"🎉 Future版多数据库结构验证完成！")

def main():
    """主函数"""
    print("🎯 Future版多数据库结构验证脚本")
    print("=" * 50)
    
    # 创建验证器
    verifier = FutureDatabaseVerifier()
    
    # 执行验证
    verifier.verify_all_databases()

if __name__ == "__main__":
    main()
