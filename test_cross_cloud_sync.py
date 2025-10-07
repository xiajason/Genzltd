#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
跨云数据库集群通信和数据同步测试脚本
测试阿里云 ↔ 腾讯云 数据同步功能
"""

import subprocess
import json
import time
from datetime import datetime

class CrossCloudSyncTester:
    def __init__(self):
        self.alibaba_cloud = {
            "ip": "47.115.168.107",
            "ssh_key": "~/.ssh/cross_cloud_key"
        }
        self.tencent_cloud = {
            "ip": "101.33.251.158", 
            "ssh_key": "~/.ssh/basic.pem"
        }
        self.test_results = {}
        self.start_time = datetime.now()

    def execute_remote_command(self, server_config, command):
        """执行远程命令"""
        try:
            full_command = f"ssh -i {server_config['ssh_key']} root@{server_config['ip']} \"{command}\""
            process = subprocess.Popen(full_command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
            stdout, stderr = process.communicate(timeout=30)
            return {
                'success': process.returncode == 0,
                'stdout': stdout.decode('utf-8'),
                'stderr': stderr.decode('utf-8'),
                'returncode': process.returncode
            }
        except subprocess.TimeoutExpired:
            return {'success': False, 'stdout': '', 'stderr': 'Command timeout', 'returncode': -1}
        except Exception as e:
            return {'success': False, 'stdout': '', 'stderr': str(e), 'returncode': -1}

    def test_mysql_sync(self):
        """测试MySQL数据同步"""
        print("🔄 测试MySQL数据同步...")
        
        # 1. 在阿里云插入测试数据
        insert_data = self.execute_remote_command(
            self.alibaba_cloud,
            "docker exec production-mysql mysql -u root -pf_mysql_password_2025 -e \"CREATE DATABASE IF NOT EXISTS sync_test; USE sync_test; CREATE TABLE IF NOT EXISTS test_table (id INT PRIMARY KEY, name VARCHAR(100), timestamp DATETIME); INSERT INTO test_table VALUES (1, 'test_data', NOW());\""
        )
        
        if not insert_data['success']:
            return {'status': 'failed', 'reason': 'Failed to insert test data', 'details': insert_data['stderr']}
        
        # 2. 等待同步
        time.sleep(5)
        
        # 3. 在腾讯云检查数据
        check_data = self.execute_remote_command(
            self.tencent_cloud,
            "docker exec production-mysql mysql -u root -pf_mysql_password_2025 -e \"USE sync_test; SELECT * FROM test_table;\""
        )
        
        if check_data['success'] and 'test_data' in check_data['stdout']:
            return {'status': 'success', 'reason': 'MySQL sync working', 'details': check_data['stdout']}
        else:
            return {'status': 'failed', 'reason': 'MySQL sync failed', 'details': check_data['stderr']}

    def test_redis_sync(self):
        """测试Redis数据同步"""
        print("🔄 测试Redis数据同步...")
        
        # 1. 在阿里云设置测试数据
        set_data = self.execute_remote_command(
            self.alibaba_cloud,
            "docker exec production-redis redis-cli -a f_redis_password_2025 SET sync_test_key 'test_value'"
        )
        
        if not set_data['success']:
            return {'status': 'failed', 'reason': 'Failed to set test data', 'details': set_data['stderr']}
        
        # 2. 等待同步
        time.sleep(3)
        
        # 3. 在腾讯云检查数据
        check_data = self.execute_remote_command(
            self.tencent_cloud,
            "docker exec production-redis redis-cli -a f_redis_password_2025 GET sync_test_key"
        )
        
        if check_data['success'] and 'test_value' in check_data['stdout']:
            return {'status': 'success', 'reason': 'Redis sync working', 'details': check_data['stdout']}
        else:
            return {'status': 'failed', 'reason': 'Redis sync failed', 'details': check_data['stderr']}

    def test_neo4j_sync(self):
        """测试Neo4j数据同步"""
        print("🔄 测试Neo4j数据同步...")
        
        # 1. 在阿里云创建测试节点
        create_node = self.execute_remote_command(
            self.alibaba_cloud,
            "docker exec production-neo4j cypher-shell -u neo4j -p f_neo4j_password_2025 \"CREATE (n:TestNode {name: 'sync_test', id: 1})\""
        )
        
        if not create_node['success']:
            return {'status': 'failed', 'reason': 'Failed to create test node', 'details': create_node['stderr']}
        
        # 2. 等待同步
        time.sleep(5)
        
        # 3. 在腾讯云检查节点
        check_node = self.execute_remote_command(
            self.tencent_cloud,
            "docker exec production-neo4j cypher-shell -u neo4j -p f_neo4j_password_2025 \"MATCH (n:TestNode) RETURN n\""
        )
        
        if check_node['success'] and 'sync_test' in check_node['stdout']:
            return {'status': 'success', 'reason': 'Neo4j sync working', 'details': check_node['stdout']}
        else:
            return {'status': 'failed', 'reason': 'Neo4j sync failed', 'details': check_node['stderr']}

    def test_elasticsearch_sync(self):
        """测试Elasticsearch数据同步"""
        print("🔄 测试Elasticsearch数据同步...")
        
        # 1. 在阿里云创建测试文档
        create_doc = self.execute_remote_command(
            self.alibaba_cloud,
            "curl -X POST 'http://localhost:9200/sync_test/_doc/1' -H 'Content-Type: application/json' -d '{\"name\": \"sync_test\", \"value\": \"test_data\"}'"
        )
        
        if not create_doc['success']:
            return {'status': 'failed', 'reason': 'Failed to create test document', 'details': create_doc['stderr']}
        
        # 2. 等待同步
        time.sleep(5)
        
        # 3. 在腾讯云检查文档
        check_doc = self.execute_remote_command(
            self.tencent_cloud,
            "curl -X GET 'http://localhost:9200/sync_test/_doc/1'"
        )
        
        if check_doc['success'] and 'sync_test' in check_doc['stdout']:
            return {'status': 'success', 'reason': 'Elasticsearch sync working', 'details': check_doc['stdout']}
        else:
            return {'status': 'failed', 'reason': 'Elasticsearch sync failed', 'details': check_doc['stderr']}

    def test_weaviate_sync(self):
        """测试Weaviate数据同步"""
        print("🔄 测试Weaviate数据同步...")
        
        # 1. 在阿里云创建测试对象
        create_object = self.execute_remote_command(
            self.alibaba_cloud,
            "curl -X POST 'http://localhost:8080/v1/objects' -H 'Content-Type: application/json' -d '{\"class\": \"TestObject\", \"properties\": {\"name\": \"sync_test\", \"value\": \"test_data\"}}'"
        )
        
        if not create_object['success']:
            return {'status': 'failed', 'reason': 'Failed to create test object', 'details': create_object['stderr']}
        
        # 2. 等待同步
        time.sleep(5)
        
        # 3. 在腾讯云检查对象
        check_object = self.execute_remote_command(
            self.tencent_cloud,
            "curl -X GET 'http://localhost:8080/v1/objects'"
        )
        
        if check_object['success'] and 'sync_test' in check_object['stdout']:
            return {'status': 'success', 'reason': 'Weaviate sync working', 'details': check_object['stdout']}
        else:
            return {'status': 'failed', 'reason': 'Weaviate sync failed', 'details': check_object['stderr']}

    def test_cross_cloud_connectivity(self):
        """测试跨云连接性"""
        print("🌐 测试跨云连接性...")
        
        # 测试阿里云到腾讯云
        alibaba_to_tencent = self.execute_remote_command(
            self.alibaba_cloud,
            f"ping -c 3 {self.tencent_cloud['ip']}"
        )
        
        # 测试腾讯云到阿里云
        tencent_to_alibaba = self.execute_remote_command(
            self.tencent_cloud,
            f"ping -c 3 {self.alibaba_cloud['ip']}"
        )
        
        connectivity_success = alibaba_to_tencent['success'] and tencent_to_alibaba['success']
        
        return {
            'status': 'success' if connectivity_success else 'failed',
            'reason': 'Cross-cloud connectivity working' if connectivity_success else 'Cross-cloud connectivity failed',
            'details': {
                'alibaba_to_tencent': alibaba_to_tencent['stdout'] if alibaba_to_tencent['success'] else alibaba_to_tencent['stderr'],
                'tencent_to_alibaba': tencent_to_alibaba['stdout'] if tencent_to_alibaba['success'] else tencent_to_alibaba['stderr']
            }
        }

    def run_sync_tests(self):
        """运行同步测试"""
        print("🚀 跨云数据库集群通信和数据同步测试")
        print("=" * 60)
        print(f"测试时间: {self.start_time}")
        print(f"阿里云: {self.alibaba_cloud['ip']}")
        print(f"腾讯云: {self.tencent_cloud['ip']}")
        print("")
        
        # 测试跨云连接性
        connectivity_result = self.test_cross_cloud_connectivity()
        self.test_results['connectivity'] = connectivity_result
        
        # 测试各数据库同步
        sync_tests = {
            'MySQL': self.test_mysql_sync(),
            'Redis': self.test_redis_sync(),
            'Neo4j': self.test_neo4j_sync(),
            'Elasticsearch': self.test_elasticsearch_sync(),
            'Weaviate': self.test_weaviate_sync()
        }
        
        self.test_results['sync_tests'] = sync_tests
        
        # 计算成功率
        total_tests = len(sync_tests) + 1  # +1 for connectivity
        successful_tests = sum(1 for result in [connectivity_result] + list(sync_tests.values()) if result['status'] == 'success')
        success_rate = (successful_tests / total_tests) * 100
        
        # 显示测试结果
        print("")
        print("📊 跨云数据库同步测试结果")
        print("=" * 60)
        print(f"跨云连接性: {'✅ 成功' if connectivity_result['status'] == 'success' else '❌ 失败'}")
        
        for db_name, result in sync_tests.items():
            status_icon = "✅" if result['status'] == 'success' else "❌"
            print(f"{db_name}同步: {status_icon} {result['reason']}")
        
        print(f"")
        print(f"总体成功率: {success_rate:.1f}% ({successful_tests}/{total_tests})")
        
        if success_rate >= 80:
            print("🎉 跨云数据库同步测试通过！")
        elif success_rate >= 60:
            print("⚠️ 跨云数据库同步基本正常，需要优化")
        else:
            print("❌ 跨云数据库同步需要修复")
        
        return self.test_results

    def save_results(self):
        """保存测试结果"""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"cross_cloud_sync_test_{timestamp}.json"
        
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(self.test_results, f, ensure_ascii=False, indent=2)
        
        print(f"📄 测试结果已保存到: {filename}")
        return filename

def main():
    """主函数"""
    tester = CrossCloudSyncTester()
    
    try:
        # 运行跨云数据库同步测试
        results = tester.run_sync_tests()
        
        # 保存结果
        filename = tester.save_results()
        
        print("")
        print("🎯 跨云数据库同步测试完成！")
        print("=" * 60)
        print(f"结果文件: {filename}")
        print("测试目标: 阿里云 ↔ 腾讯云 数据同步功能")
        
    except Exception as e:
        print(f"❌ 测试过程中出现错误: {e}")

if __name__ == "__main__":
    main()
EOF"