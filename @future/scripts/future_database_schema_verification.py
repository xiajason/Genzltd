#!/usr/bin/env python3
"""
Future版数据库表单和字段验证脚本
实地考察数据库表单和字段完整性
"""

import subprocess
import json
from datetime import datetime

def check_mysql_tables():
    """检查MySQL数据库表"""
    try:
        result = subprocess.run(['mysql', '-h', '127.0.0.1', '-P', '3306', '-u', 'root', '-pf_mysql_root_2025', '-e', 'USE future_users; SHOW TABLES;'], 
                               capture_output=True, text=True, timeout=10)
        if result.returncode == 0:
            tables = [line.strip() for line in result.stdout.split('\n') if line.strip() and not line.startswith('Tables_in_future_users')]
            return {'status': 'success', 'tables': tables}
        else:
            return {'status': 'failed', 'error': result.stderr.strip()}
    except Exception as e:
        return {'status': 'failed', 'error': str(e)}

def check_mysql_table_structure(table_name):
    """检查MySQL表结构"""
    try:
        result = subprocess.run(['mysql', '-h', '127.0.0.1', '-P', '3306', '-u', 'root', '-pf_mysql_root_2025', '-e', f'USE future_users; DESCRIBE {table_name};'], 
                               capture_output=True, text=True, timeout=10)
        if result.returncode == 0:
            lines = [line.strip() for line in result.stdout.split('\n') if line.strip() and not line.startswith('Field')]
            fields = []
            for line in lines:
                if line:
                    parts = line.split()
                    if len(parts) >= 2:
                        fields.append({'name': parts[0], 'type': parts[1]})
            return {'status': 'success', 'fields': fields}
        else:
            return {'status': 'failed', 'error': result.stderr.strip()}
    except Exception as e:
        return {'status': 'failed', 'error': str(e)}

def check_postgresql_tables():
    """检查PostgreSQL数据库表"""
    try:
        result = subprocess.run(['PGPASSWORD=f_postgres_password_2025', 'psql', '-h', '127.0.0.1', '-p', '5432', '-U', 'future_user', '-d', 'f_pg', '-c', '\\dt'], 
                               capture_output=True, text=True, timeout=10, shell=True)
        if result.returncode == 0:
            lines = [line.strip() for line in result.stdout.split('\n') if line.strip() and not line.startswith('List of relations') and not line.startswith('Schema') and not line.startswith('Name') and not line.startswith('----')]
            tables = []
            for line in lines:
                if line and not line.startswith('('):
                    parts = line.split()
                    if len(parts) >= 1:
                        tables.append(parts[0])
            return {'status': 'success', 'tables': tables}
        else:
            return {'status': 'failed', 'error': result.stderr.strip()}
    except Exception as e:
        return {'status': 'failed', 'error': str(e)}

def check_redis_keys():
    """检查Redis键"""
    try:
        result = subprocess.run(['redis-cli', '-h', '127.0.0.1', '-p', '6379', 'keys', '*'], 
                               capture_output=True, text=True, timeout=10)
        if result.returncode == 0:
            keys = [line.strip() for line in result.stdout.split('\n') if line.strip()]
            return {'status': 'success', 'keys': keys}
        else:
            return {'status': 'failed', 'error': result.stderr.strip()}
    except Exception as e:
        return {'status': 'failed', 'error': str(e)}

def check_elasticsearch_indices():
    """检查Elasticsearch索引"""
    try:
        result = subprocess.run(['curl', '-s', 'http://127.0.0.1:9200/_cat/indices'], 
                               capture_output=True, text=True, timeout=10)
        if result.returncode == 0:
            lines = [line.strip() for line in result.stdout.split('\n') if line.strip()]
            indices = []
            for line in lines:
                if line and not line.startswith('green') and not line.startswith('yellow') and not line.startswith('red'):
                    parts = line.split()
                    if len(parts) >= 1:
                        indices.append(parts[0])
            return {'status': 'success', 'indices': indices}
        else:
            return {'status': 'failed', 'error': result.stderr.strip()}
    except Exception as e:
        return {'status': 'failed', 'error': str(e)}

def check_weaviate_schema():
    """检查Weaviate模式"""
    try:
        result = subprocess.run(['curl', '-s', 'http://127.0.0.1:8080/v1/schema'], 
                               capture_output=True, text=True, timeout=10)
        if result.returncode == 0:
            schema = json.loads(result.stdout)
            classes = schema.get('classes', [])
            return {'status': 'success', 'classes': classes}
        else:
            return {'status': 'failed', 'error': result.stderr.strip()}
    except Exception as e:
        return {'status': 'failed', 'error': str(e)}

def main():
    """主函数"""
    print('🔍 Future版数据库表单和字段考察结论报告')
    print('=' * 70)
    
    # 检查MySQL
    print('\n📊 MySQL数据库检查:')
    mysql_tables = check_mysql_tables()
    if mysql_tables['status'] == 'success':
        print(f'   表数量: {len(mysql_tables["tables"])}')
        print(f'   表名: {mysql_tables["tables"]}')
        
        for table in mysql_tables['tables']:
            structure = check_mysql_table_structure(table)
            if structure['status'] == 'success':
                print(f'   {table}表字段: {len(structure["fields"])}个')
                for field in structure['fields']:
                    print(f'     - {field["name"]}: {field["type"]}')
            else:
                print(f'   {table}表结构检查失败: {structure["error"]}')
    else:
        print(f'   MySQL检查失败: {mysql_tables["error"]}')
    
    # 检查PostgreSQL
    print('\n📊 PostgreSQL数据库检查:')
    postgresql_tables = check_postgresql_tables()
    if postgresql_tables['status'] == 'success':
        print(f'   表数量: {len(postgresql_tables["tables"])}')
        print(f'   表名: {postgresql_tables["tables"]}')
    else:
        print(f'   PostgreSQL检查失败: {postgresql_tables["error"]}')
    
    # 检查Redis
    print('\n�� Redis数据库检查:')
    redis_keys = check_redis_keys()
    if redis_keys['status'] == 'success':
        print(f'   键数量: {len(redis_keys["keys"])}')
        print(f'   键名: {redis_keys["keys"]}')
    else:
        print(f'   Redis检查失败: {redis_keys["error"]}')
    
    # 检查Elasticsearch
    print('\n📊 Elasticsearch数据库检查:')
    es_indices = check_elasticsearch_indices()
    if es_indices['status'] == 'success':
        print(f'   索引数量: {len(es_indices["indices"])}')
        print(f'   索引名: {es_indices["indices"]}')
    else:
        print(f'   Elasticsearch检查失败: {es_indices["error"]}')
    
    # 检查Weaviate
    print('\n📊 Weaviate数据库检查:')
    weaviate_schema = check_weaviate_schema()
    if weaviate_schema['status'] == 'success':
        print(f'   类数量: {len(weaviate_schema["classes"])}')
        print(f'   类名: {weaviate_schema["classes"]}')
    else:
        print(f'   Weaviate检查失败: {weaviate_schema["error"]}')
    
    # 生成报告
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    report = {
        'timestamp': timestamp,
        'version': 'future',
        'mysql': mysql_tables,
        'postgresql': postgresql_tables,
        'redis': redis_keys,
        'elasticsearch': es_indices,
        'weaviate': weaviate_schema
    }
    
    report_file = f'future_database_schema_verification_report_{timestamp}.json'
    with open(report_file, 'w', encoding='utf-8') as f:
        json.dump(report, f, indent=2, ensure_ascii=False)
    
    print(f'\n✅ 考察报告已保存到: {report_file}')
    
    # 总结
    print('\n📋 考察结论:')
    print('=' * 50)
    
    if mysql_tables['status'] == 'success' and len(mysql_tables['tables']) > 0:
        print('✅ MySQL: 数据库和表已创建，结构正常')
    else:
        print('❌ MySQL: 数据库或表创建不完整')
    
    if postgresql_tables['status'] == 'success' and len(postgresql_tables['tables']) > 0:
        print('✅ PostgreSQL: 数据库和表已创建，结构正常')
    else:
        print('❌ PostgreSQL: 数据库或表创建不完整')
    
    if redis_keys['status'] == 'success':
        print('✅ Redis: 数据库连接正常')
    else:
        print('❌ Redis: 数据库连接异常')
    
    if es_indices['status'] == 'success':
        print('✅ Elasticsearch: 数据库连接正常')
    else:
        print('❌ Elasticsearch: 数据库连接异常')
    
    if weaviate_schema['status'] == 'success':
        print('✅ Weaviate: 数据库连接正常')
    else:
        print('❌ Weaviate: 数据库连接异常')
    
    return report

if __name__ == '__main__':
    main()
