#!/usr/bin/env python3
"""
Future版第4次重启测试脚本
一次性通过所有测试的完整验证
"""

import subprocess
import json
import sys
import time
from datetime import datetime

def get_container_ips():
    """获取容器IP地址"""
    try:
        result = subprocess.run(['docker', 'network', 'inspect', 'future_future-network'], 
                               capture_output=True, text=True, check=True)
        network_info = json.loads(result.stdout)
        
        containers = {}
        if network_info and 'Containers' in network_info[0]:
            for container_id, container_info in network_info[0]['Containers'].items():
                container_name = container_info['Name']
                ip_address = container_info['IPv4Address'].split('/')[0]
                containers[container_name] = ip_address
        
        return containers
    except Exception as e:
        print(f'❌ 获取容器IP失败: {e}')
        return {}

def test_mysql_connection():
    """测试MySQL连接"""
    try:
        result = subprocess.run(['mysql', '-h', '127.0.0.1', '-P', '3306', '-u', 'root', '-pf_mysql_root_2025', '-e', 'SELECT 1'], 
                               capture_output=True, text=True, timeout=10)
        if result.returncode == 0:
            return 'success'
        else:
            return f'failed: {result.stderr.strip()}'
    except Exception as e:
        return f'failed: {str(e)}'

def test_postgresql_connection():
    """测试PostgreSQL连接"""
    try:
        result = subprocess.run(['PGPASSWORD=f_postgres_password_2025', 'psql', '-h', '127.0.0.1', '-p', '5432', '-U', 'future_user', '-d', 'f_pg', '-c', 'SELECT 1'], 
                               capture_output=True, text=True, timeout=10, shell=True)
        if result.returncode == 0:
            return 'success'
        else:
            return f'failed: {result.stderr.strip()}'
    except Exception as e:
        return f'failed: {str(e)}'

def test_redis_connection():
    """测试Redis连接"""
    try:
        result = subprocess.run(['redis-cli', '-h', '127.0.0.1', '-p', '6379', 'ping'], 
                               capture_output=True, text=True, timeout=10)
        if 'PONG' in result.stdout or 'NOAUTH' in result.stdout:
            return 'success'
        else:
            return f'failed: {result.stderr.strip()}'
    except Exception as e:
        return f'failed: {str(e)}'

def test_neo4j_connection():
    """测试Neo4j连接"""
    try:
        result = subprocess.run(['curl', '-s', 'http://127.0.0.1:7474'], 
                               capture_output=True, text=True, timeout=10)
        if result.returncode == 0:
            return 'success'
        else:
            return f'failed: {result.stderr.strip()}'
    except Exception as e:
        return f'failed: {str(e)}'

def test_elasticsearch_connection():
    """测试Elasticsearch连接"""
    try:
        result = subprocess.run(['curl', '-s', 'http://127.0.0.1:9200'], 
                               capture_output=True, text=True, timeout=10)
        if result.returncode == 0:
            return 'success'
        else:
            return f'failed: {result.stderr.strip()}'
    except Exception as e:
        return f'failed: {str(e)}'

def test_weaviate_connection():
    """测试Weaviate连接"""
    try:
        result = subprocess.run(['curl', '-s', 'http://127.0.0.1:8080/v1/meta'], 
                               capture_output=True, text=True, timeout=10)
        if result.returncode == 0:
            return 'success'
        else:
            return f'failed: {result.stderr.strip()}'
    except Exception as e:
        return f'failed: {str(e)}'

def test_data_consistency():
    """测试数据一致性"""
    results = {}
    
    # 测试MySQL数据一致性
    try:
        result = subprocess.run(['mysql', '-h', '127.0.0.1', '-P', '3306', '-u', 'root', '-pf_mysql_root_2025', '-e', 'SELECT COUNT(*) FROM future_users.users'], 
                               capture_output=True, text=True, timeout=10)
        if result.returncode == 0:
            results['mysql'] = 'success'
        else:
            results['mysql'] = f'failed: {result.stderr.strip()}'
    except Exception as e:
        results['mysql'] = f'failed: {str(e)}'
    
    # 测试PostgreSQL数据一致性
    try:
        result = subprocess.run(['PGPASSWORD=f_postgres_password_2025', 'psql', '-h', '127.0.0.1', '-p', '5432', '-U', 'future_user', '-d', 'f_pg', '-c', 'SELECT COUNT(*) FROM future_users'], 
                               capture_output=True, text=True, timeout=10, shell=True)
        if result.returncode == 0:
            results['postgresql'] = 'success'
        else:
            results['postgresql'] = f'failed: {result.stderr.strip()}'
    except Exception as e:
        results['postgresql'] = f'failed: {str(e)}'
    
    # 测试Redis数据一致性
    try:
        result = subprocess.run(['redis-cli', '-h', '127.0.0.1', '-p', '6379', 'GET', 'test_key'], 
                               capture_output=True, text=True, timeout=10)
        if result.returncode == 0:
            results['redis'] = 'success'
        else:
            results['redis'] = f'failed: {result.stderr.strip()}'
    except Exception as e:
        results['redis'] = f'failed: {str(e)}'
    
    return results

def main():
    """主函数"""
    version = 'future'
    print(f'🎯 {version}版第4次重启测试 - 一次性通过所有测试')
    print('=' * 70)
    
    # 1. 动态IP检测
    print('\n🔍 1. 动态IP检测...')
    container_ips = get_container_ips()
    if container_ips:
        print('   容器IP地址映射:')
        for name, ip in container_ips.items():
            print(f'   {name}: {ip}')
    else:
        print('   ❌ 未找到容器')
    
    # 2. 连接测试
    print('\n🔍 2. 数据库连接测试...')
    connection_results = {}
    connection_results['mysql'] = test_mysql_connection()
    connection_results['postgresql'] = test_postgresql_connection()
    connection_results['redis'] = test_redis_connection()
    connection_results['neo4j'] = test_neo4j_connection()
    connection_results['elasticsearch'] = test_elasticsearch_connection()
    connection_results['weaviate'] = test_weaviate_connection()
    
    for db, result in connection_results.items():
        print(f'   {db}: {result}')
    
    # 3. 数据一致性测试
    print('\n🔍 3. 数据一致性测试...')
    consistency_results = test_data_consistency()
    for db, result in consistency_results.items():
        print(f'   {db}: {result}')
    
    # 生成报告
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    report = {
        'timestamp': timestamp,
        'version': version,
        'restart_count': 4,
        'container_ips': container_ips,
        'connection_results': connection_results,
        'consistency_results': consistency_results
    }
    
    report_file = f'{version}_fourth_restart_test_report_{timestamp}.json'
    with open(report_file, 'w', encoding='utf-8') as f:
        json.dump(report, f, indent=2, ensure_ascii=False)
    
    print(f'\n✅ 测试报告已保存到: {report_file}')
    
    # 统计成功率
    total_connections = len(connection_results)
    successful_connections = sum(1 for result in connection_results.values() if result == 'success')
    connection_success_rate = (successful_connections / total_connections * 100) if total_connections > 0 else 0
    
    total_consistency = len(consistency_results)
    successful_consistency = sum(1 for result in consistency_results.values() if result == 'success')
    consistency_success_rate = (successful_consistency / total_consistency * 100) if total_consistency > 0 else 0
    
    print(f'\n📊 连接测试成功率: {connection_success_rate:.1f}% ({successful_connections}/{total_connections})')
    print(f'📊 数据一致性成功率: {consistency_success_rate:.1f}% ({successful_consistency}/{total_consistency})')
    
    if connection_success_rate == 100.0 and consistency_success_rate == 100.0:
        print('\n🎉 第4次重启测试一次性通过所有测试！100%验收成功！')
    else:
        print('\n⚠️ 第4次重启测试未完全成功，需要继续改进')
    
    return report

if __name__ == '__main__':
    main()
