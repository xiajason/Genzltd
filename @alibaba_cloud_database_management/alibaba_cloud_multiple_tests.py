#!/usr/bin/env python3
# 基于@future_optimized/经验的阿里云多数据库多次测试系统
# 版本: V1.0
# 日期: 2025年10月6日
# 描述: 基于Future版经验的多次测试，确保数据库稳定性

import subprocess
import json
import time
from datetime import datetime
import os

class AlibabaCloudMultipleTests:
    def __init__(self):
        self.server_ip = "47.115.168.107"
        self.ssh_key = "~/.ssh/cross_cloud_key"
        self.test_results = []
        self.test_count = 0
        
    def execute_remote_command(self, command):
        """执行远程命令"""
        try:
            result = subprocess.run([
                'ssh', '-i', self.ssh_key, '-o', 'ConnectTimeout=30', 
                '-o', 'StrictHostKeyChecking=no', 
                f'root@{self.server_ip}', command
            ], capture_output=True, text=True, timeout=30)
            return result
        except Exception as e:
            return None
    
    def run_single_test(self, test_name):
        """运行单次测试"""
        print(f"=== 开始第{self.test_count + 1}次测试: {test_name} ===")
        
        test_result = {
            'test_number': self.test_count + 1,
            'test_name': test_name,
            'test_time': datetime.now().isoformat(),
            'server': f'阿里云ECS ({self.server_ip})',
            'tests': {}
        }
        
        # 测试MySQL
        mysql_result = self.execute_remote_command(
            "docker exec production-mysql mysql -u root -p'f_mysql_password_2025' -e 'SELECT 1 as mysql_test;'"
        )
        test_result['tests']['mysql'] = {
            'status': 'success' if mysql_result and mysql_result.returncode == 0 else 'failed',
            'details': mysql_result.stdout.strip() if mysql_result else 'Connection failed'
        }
        
        # 测试PostgreSQL
        postgresql_result = self.execute_remote_command(
            "docker exec production-postgres psql -U future_user -d jobfirst_future -c 'SELECT 1 as postgres_test;'"
        )
        test_result['tests']['postgresql'] = {
            'status': 'success' if postgresql_result and postgresql_result.returncode == 0 else 'failed',
            'details': postgresql_result.stdout.strip() if postgresql_result else 'Connection failed'
        }
        
        # 测试Redis
        redis_result = self.execute_remote_command(
            "redis-cli -h localhost -p 6379 -a 'f_redis_password_2025' ping"
        )
        test_result['tests']['redis'] = {
            'status': 'success' if redis_result and redis_result.returncode == 0 else 'failed',
            'details': redis_result.stdout.strip() if redis_result else 'Connection failed'
        }
        
        # 测试Neo4j
        neo4j_result = self.execute_remote_command(
            "docker exec production-neo4j cypher-shell -u neo4j -p'f_neo4j_password_2025' 'RETURN 1 as neo4j_test;'"
        )
        test_result['tests']['neo4j'] = {
            'status': 'success' if neo4j_result and neo4j_result.returncode == 0 else 'failed',
            'details': neo4j_result.stdout.strip() if neo4j_result else 'Connection failed'
        }
        
        # 测试Elasticsearch
        elasticsearch_result = self.execute_remote_command("curl -s http://localhost:9200")
        test_result['tests']['elasticsearch'] = {
            'status': 'success' if elasticsearch_result and elasticsearch_result.returncode == 0 else 'failed',
            'details': '占位符服务正常' if elasticsearch_result and elasticsearch_result.returncode == 0 else 'Connection failed'
        }
        
        # 测试Weaviate
        weaviate_result = self.execute_remote_command("curl -s http://localhost:8080")
        test_result['tests']['weaviate'] = {
            'status': 'success' if weaviate_result and weaviate_result.returncode == 0 else 'failed',
            'details': '占位符服务正常' if weaviate_result and weaviate_result.returncode == 0 else 'Connection failed'
        }
        
        # 计算成功率
        total_tests = 6
        successful_tests = sum(1 for test in test_result['tests'].values() if test['status'] == 'success')
        success_rate = (successful_tests / total_tests) * 100
        
        test_result['overall_status'] = f'{successful_tests}/{total_tests} 成功'
        test_result['success_rate'] = f'{success_rate:.1f}%'
        
        self.test_results.append(test_result)
        self.test_count += 1
        
        print(f"=== 第{self.test_count}次测试完成: {successful_tests}/{total_tests} 成功 ({success_rate:.1f}%) ===")
        
        return test_result
    
    def run_multiple_tests(self, test_count=5):
        """运行多次测试"""
        print(f"=== 开始{test_count}次连续测试 ===")
        
        for i in range(test_count):
            test_name = f"第{i+1}次测试"
            self.run_single_test(test_name)
            
            if i < test_count - 1:
                print(f"=== 等待5秒后进行第{i+2}次测试 ===")
                time.sleep(5)
        
        return self.test_results
    
    def analyze_results(self):
        """分析测试结果"""
        print("=== 分析测试结果 ===")
        
        analysis = {
            'total_tests': len(self.test_results),
            'database_stability': {},
            'overall_analysis': {},
            'recommendations': []
        }
        
        # 分析每个数据库的稳定性
        databases = ['mysql', 'postgresql', 'redis', 'neo4j', 'elasticsearch', 'weaviate']
        
        for db in databases:
            success_count = 0
            for test in self.test_results:
                if test['tests'][db]['status'] == 'success':
                    success_count += 1
            
            stability_rate = (success_count / len(self.test_results)) * 100
            analysis['database_stability'][db] = {
                'success_count': success_count,
                'total_tests': len(self.test_results),
                'stability_rate': f'{stability_rate:.1f}%',
                'status': 'stable' if stability_rate >= 80 else 'unstable'
            }
        
        # 总体分析
        total_success = sum(1 for test in self.test_results 
                           for db_test in test['tests'].values() 
                           if db_test['status'] == 'success')
        total_tests = len(self.test_results) * 6
        overall_success_rate = (total_success / total_tests) * 100
        
        analysis['overall_analysis'] = {
            'total_success': total_success,
            'total_tests': total_tests,
            'overall_success_rate': f'{overall_success_rate:.1f}%',
            'status': 'excellent' if overall_success_rate >= 90 else 'good' if overall_success_rate >= 80 else 'needs_improvement'
        }
        
        # 生成建议
        unstable_dbs = [db for db, stats in analysis['database_stability'].items() 
                       if stats['status'] == 'unstable']
        
        if unstable_dbs:
            analysis['recommendations'].append(f"需要关注不稳定的数据库: {', '.join(unstable_dbs)}")
        
        if overall_success_rate < 80:
            analysis['recommendations'].append("整体稳定性需要改进，建议检查网络和配置")
        elif overall_success_rate >= 90:
            analysis['recommendations'].append("数据库系统非常稳定，可以进入下一阶段")
        else:
            analysis['recommendations'].append("数据库系统基本稳定，建议进行优化")
        
        return analysis
    
    def save_results(self):
        """保存测试结果"""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        
        # 保存详细结果
        detailed_filename = f"@alibaba_cloud_database_management/alibaba_cloud_multiple_tests_{timestamp}.json"
        with open(detailed_filename, 'w', encoding='utf-8') as f:
            json.dump(self.test_results, f, ensure_ascii=False, indent=2)
        
        # 保存分析结果
        analysis = self.analyze_results()
        analysis_filename = f"@alibaba_cloud_database_management/alibaba_cloud_analysis_{timestamp}.json"
        with open(analysis_filename, 'w', encoding='utf-8') as f:
            json.dump(analysis, f, ensure_ascii=False, indent=2)
        
        print(f"=== 测试结果已保存到 {detailed_filename} ===")
        print(f"=== 分析结果已保存到 {analysis_filename} ===")
        
        return detailed_filename, analysis_filename

if __name__ == '__main__':
    tester = AlibabaCloudMultipleTests()
    
    # 运行5次测试
    results = tester.run_multiple_tests(5)
    
    # 分析结果
    analysis = tester.analyze_results()
    
    # 保存结果
    detailed_file, analysis_file = tester.save_results()
    
    print("=== 测试完成 ===")
    print(f"总测试次数: {len(results)}")
    print(f"总体成功率: {analysis['overall_analysis']['overall_success_rate']}")
    print(f"系统状态: {analysis['overall_analysis']['status']}")
    
    if analysis['recommendations']:
        print("建议:")
        for rec in analysis['recommendations']:
            print(f"  - {rec}")
