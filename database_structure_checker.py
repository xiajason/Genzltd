#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Future版多数据库结构检查脚本
直接使用Docker命令连接各个数据库，检查表结构、字段定义、索引等
"""

import subprocess
import json
import sys
from datetime import datetime

class DatabaseStructureChecker:
    def __init__(self):
        self.results = {}
        self.check_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        
    def run_docker_command(self, container_name, command):
        """在Docker容器中执行命令"""
        try:
            full_command = f"docker exec {container_name} {command}"
            result = subprocess.run(full_command, shell=True, capture_output=True, text=True, timeout=30)
            return result.returncode == 0, result.stdout, result.stderr
        except subprocess.TimeoutExpired:
            return False, "", "Command timeout"
        except Exception as e:
            return False, "", str(e)
    
    def check_mysql_structure(self):
        """检查MySQL数据库结构"""
        print("🔍 检查MySQL数据库结构...")
        
        # 检查数据库列表
        success, stdout, stderr = self.run_docker_command(
            "f-mysql", 
            "mysql -u root -pf_mysql_root_2025 -e 'SHOW DATABASES;'"
        )
        
        if not success:
            self.results['mysql'] = {"status": "failed", "error": stderr}
            return
        
        # 检查表结构
        success, stdout, stderr = self.run_docker_command(
            "f-mysql",
            "mysql -u root -pf_mysql_root_2025 -e 'USE jobfirst_future; SHOW TABLES;'"
        )
        
        if success:
            tables = [line.strip() for line in stdout.split('\n') if line.strip() and not line.startswith('Tables_in')]
            print(f"✅ MySQL: 找到 {len(tables)} 个表")
            
            # 检查每个表的结构
            table_details = {}
            for table in tables:
                success, stdout, stderr = self.run_docker_command(
                    "f-mysql",
                    f"mysql -u root -pf_mysql_root_2025 -e 'USE jobfirst_future; DESCRIBE {table};'"
                )
                if success:
                    table_details[table] = stdout
                    
            self.results['mysql'] = {
                "status": "success",
                "database": "jobfirst_future",
                "table_count": len(tables),
                "tables": tables,
                "table_details": table_details
            }
        else:
            self.results['mysql'] = {"status": "failed", "error": stderr}
    
    def check_postgresql_structure(self):
        """检查PostgreSQL数据库结构"""
        print("🔍 检查PostgreSQL数据库结构...")
        
        # 检查数据库列表
        success, stdout, stderr = self.run_docker_command(
            "f-postgres",
            "PGPASSWORD=f_pg_password_2025 psql -h localhost -U f_pg_user -d f_pg -c '\\l'"
        )
        
        if not success:
            self.results['postgresql'] = {"status": "failed", "error": stderr}
            return
        
        # 检查表结构
        success, stdout, stderr = self.run_docker_command(
            "f-postgres",
            "PGPASSWORD=f_pg_password_2025 psql -h localhost -U f_pg_user -d f_pg -c '\\dt'"
        )
        
        if success:
            lines = [line.strip() for line in stdout.split('\n') if line.strip() and '|' in line and not line.startswith('List of relations')]
            tables = [line.split('|')[0].strip() for line in lines if line.split('|')[0].strip()]
            print(f"✅ PostgreSQL: 找到 {len(tables)} 个表")
            
            # 检查每个表的结构
            table_details = {}
            for table in tables:
                success, stdout, stderr = self.run_docker_command(
                    "f-postgres",
                    f"PGPASSWORD=f_pg_password_2025 psql -h localhost -U f_pg_user -d f_pg -c '\\d {table}'"
                )
                if success:
                    table_details[table] = stdout
                    
            self.results['postgresql'] = {
                "status": "success",
                "database": "f_pg",
                "table_count": len(tables),
                "tables": tables,
                "table_details": table_details
            }
        else:
            self.results['postgresql'] = {"status": "failed", "error": stderr}
    
    def check_redis_structure(self):
        """检查Redis数据库结构"""
        print("🔍 检查Redis数据库结构...")
        
        # 检查Redis连接 (先尝试无密码)
        success, stdout, stderr = self.run_docker_command(
            "f-redis",
            "redis-cli ping"
        )
        
        if not success or "PONG" not in stdout:
            # 尝试带密码连接
            success, stdout, stderr = self.run_docker_command(
                "f-redis",
                "redis-cli -a f_redis_password_2025 ping"
            )
        
        if success and "PONG" in stdout:
            # 检查键的数量
            success, stdout, stderr = self.run_docker_command(
                "f-redis",
                "redis-cli -a f_redis_password_2025 dbsize"
            )
            
            if success:
                key_count = stdout.strip()
                print(f"✅ Redis: 连接成功，键数量: {key_count}")
                
                # 检查键的类型
                success, stdout, stderr = self.run_docker_command(
                    "f-redis",
                    "redis-cli -a f_redis_password_2025 keys '*'"
                )
                
                keys = [line.strip() for line in stdout.split('\n') if line.strip()]
                
                self.results['redis'] = {
                    "status": "success",
                    "key_count": int(key_count),
                    "keys": keys[:10]  # 只显示前10个键
                }
            else:
                self.results['redis'] = {"status": "failed", "error": stderr}
        else:
            self.results['redis'] = {"status": "failed", "error": stderr}
    
    def check_neo4j_structure(self):
        """检查Neo4j数据库结构"""
        print("🔍 检查Neo4j数据库结构...")
        
        # 先尝试无认证连接
        success, stdout, stderr = self.run_docker_command(
            "f-neo4j",
            "cypher-shell 'CALL db.labels();'"
        )
        
        if not success:
            # 尝试带认证连接
            success, stdout, stderr = self.run_docker_command(
                "f-neo4j",
                "cypher-shell -u neo4j -p f_neo4j_password_2025 'CALL db.labels();'"
            )
        
        if success:
            labels = [line.strip() for line in stdout.split('\n') if line.strip() and not line.startswith('label')]
            print(f"✅ Neo4j: 找到 {len(labels)} 个节点标签")
            
            # 检查关系类型
            success, stdout, stderr = self.run_docker_command(
                "f-neo4j",
                "cypher-shell -u neo4j -p f_neo4j_password_2025 'CALL db.relationshipTypes();'"
            )
            
            if success:
                rel_types = [line.strip() for line in stdout.split('\n') if line.strip() and not line.startswith('relationshipType')]
                
                self.results['neo4j'] = {
                    "status": "success",
                    "label_count": len(labels),
                    "labels": labels,
                    "relationship_count": len(rel_types),
                    "relationship_types": rel_types
                }
            else:
                self.results['neo4j'] = {"status": "failed", "error": stderr}
        else:
            self.results['neo4j'] = {"status": "failed", "error": stderr}
    
    def check_elasticsearch_structure(self):
        """检查Elasticsearch数据库结构"""
        print("🔍 检查Elasticsearch数据库结构...")
        
        # 检查索引列表
        success, stdout, stderr = self.run_docker_command(
            "f-elasticsearch",
            "curl -s http://localhost:9200/_cat/indices?v"
        )
        
        if success:
            lines = [line.strip() for line in stdout.split('\n') if line.strip() and not line.startswith('health')]
            indices = []
            for line in lines:
                if line and '|' in line:
                    parts = line.split()
                    if len(parts) > 0:
                        indices.append(parts[2])  # 索引名在第3列
            
            print(f"✅ Elasticsearch: 找到 {len(indices)} 个索引")
            
            # 检查每个索引的映射
            index_details = {}
            for index in indices:
                success, stdout, stderr = self.run_docker_command(
                    "f-elasticsearch",
                    f"curl -s http://localhost:9200/{index}/_mapping"
                )
                if success:
                    index_details[index] = stdout
                    
            self.results['elasticsearch'] = {
                "status": "success",
                "index_count": len(indices),
                "indices": indices,
                "index_details": index_details
            }
        else:
            self.results['elasticsearch'] = {"status": "failed", "error": stderr}
    
    def check_weaviate_structure(self):
        """检查Weaviate数据库结构"""
        print("🔍 检查Weaviate数据库结构...")
        
        # 检查Schema类 (使用wget替代curl)
        success, stdout, stderr = self.run_docker_command(
            "f-weaviate",
            "wget -qO- http://localhost:8082/v1/schema"
        )
        
        if not success:
            # 尝试使用curl
            success, stdout, stderr = self.run_docker_command(
                "f-weaviate",
                "curl -s http://localhost:8082/v1/schema"
            )
        
        if success:
            import json
            try:
                schema_data = json.loads(stdout)
                classes = schema_data.get('classes', [])
                class_names = [cls.get('class', '') for cls in classes]
                
                print(f"✅ Weaviate: 找到 {len(class_names)} 个Schema类")
                
                self.results['weaviate'] = {
                    "status": "success",
                    "class_count": len(class_names),
                    "classes": class_names,
                    "schema_details": schema_data
                }
            except json.JSONDecodeError:
                self.results['weaviate'] = {"status": "failed", "error": "Invalid JSON response"}
        else:
            self.results['weaviate'] = {"status": "failed", "error": stderr}
    
    def check_sqlite_structure(self):
        """检查SQLite数据库结构"""
        print("🔍 检查SQLite数据库结构...")
        
        # 检查用户数据库目录
        success, stdout, stderr = self.run_docker_command(
            "f-mysql",  # 使用MySQL容器来检查文件系统
            "find /data -name '*.db' -type f 2>/dev/null || echo 'No SQLite files found'"
        )
        
        if success:
            db_files = [line.strip() for line in stdout.split('\n') if line.strip() and line.endswith('.db')]
            print(f"✅ SQLite: 找到 {len(db_files)} 个数据库文件")
            
            # 检查每个数据库的表结构
            db_details = {}
            for db_file in db_files:
                success, stdout, stderr = self.run_docker_command(
                    "f-mysql",
                    f"sqlite3 {db_file} '.tables'"
                )
                if success:
                    tables = [line.strip() for line in stdout.split('\n') if line.strip()]
                    db_details[db_file] = tables
                    
            self.results['sqlite'] = {
                "status": "success",
                "database_count": len(db_files),
                "database_files": db_files,
                "database_details": db_details
            }
        else:
            self.results['sqlite'] = {"status": "failed", "error": stderr}
    
    def run_all_checks(self):
        """运行所有数据库结构检查"""
        print("🎯 Future版多数据库结构检查脚本")
        print("=" * 50)
        print(f"🕐 检查时间: {self.check_time}")
        print("=" * 50)
        
        # 检查各个数据库
        self.check_mysql_structure()
        self.check_postgresql_structure()
        self.check_redis_structure()
        self.check_neo4j_structure()
        self.check_elasticsearch_structure()
        self.check_weaviate_structure()
        self.check_sqlite_structure()
        
        # 生成报告
        self.generate_report()
    
    def generate_report(self):
        """生成检查报告"""
        print("\n" + "=" * 50)
        print("📊 Future版多数据库结构检查报告")
        print("=" * 50)
        
        success_count = sum(1 for result in self.results.values() if result.get('status') == 'success')
        total_count = len(self.results)
        success_rate = (success_count / total_count) * 100 if total_count > 0 else 0
        
        print(f"📈 检查统计:")
        print(f"  总数据库数: {total_count}")
        print(f"  检查成功: {success_count}")
        print(f"  检查失败: {total_count - success_count}")
        print(f"  成功率: {success_rate:.1f}%")
        
        print(f"\n📋 详细结果:")
        for db_name, result in self.results.items():
            status_icon = "✅" if result.get('status') == 'success' else "❌"
            print(f"  {status_icon} {db_name.upper()}: {result.get('status', 'unknown')}")
            
            if result.get('status') == 'success':
                if 'table_count' in result:
                    print(f"    表数量: {result['table_count']}")
                if 'key_count' in result:
                    print(f"    键数量: {result['key_count']}")
                if 'label_count' in result:
                    print(f"    标签数量: {result['label_count']}")
                if 'index_count' in result:
                    print(f"    索引数量: {result['index_count']}")
                if 'class_count' in result:
                    print(f"    类数量: {result['class_count']}")
                if 'database_count' in result:
                    print(f"    数据库数量: {result['database_count']}")
            else:
                print(f"    错误: {result.get('error', 'Unknown error')}")
        
        # 保存报告到文件
        report_filename = f"database_structure_check_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        with open(report_filename, 'w', encoding='utf-8') as f:
            json.dump({
                "check_time": self.check_time,
                "total_databases": total_count,
                "successful_checks": success_count,
                "failed_checks": total_count - success_count,
                "success_rate": success_rate,
                "results": self.results
            }, f, ensure_ascii=False, indent=2)
        
        print(f"\n💾 详细报告已保存到: {report_filename}")
        print("🎉 Future版多数据库结构检查完成！")

if __name__ == "__main__":
    checker = DatabaseStructureChecker()
    checker.run_all_checks()
