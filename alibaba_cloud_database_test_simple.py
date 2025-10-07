#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
阿里云多数据库通信连接测试 - 简化版
基于@future_optimized/经验
"""

import json
import subprocess
import sys
from datetime import datetime
from typing import Dict, Any
import logging

# 配置日志
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class AlibabaCloudDatabaseTester:
    """阿里云多数据库测试器"""
    
    def __init__(self):
        self.server_ip = "47.115.168.107"
        self.ssh_key = "~/.ssh/cross_cloud_key"
        self.start_time = datetime.now()
    
    def run_ssh_command(self, command: str) -> tuple:
        """执行SSH命令"""
        try:
            full_command = f"ssh -i {self.ssh_key} root@{self.server_ip} '{command}'"
            result = subprocess.run(full_command, shell=True, capture_output=True, text=True, timeout=30)
            return result.returncode, result.stdout, result.stderr
        except subprocess.TimeoutExpired:
            return -1, "", "Command timeout"
        except Exception as e:
            return -1, "", str(e)
    
    def test_mysql(self) -> Dict[str, Any]:
        """测试MySQL"""
        logger.info("🔍 测试MySQL...")
        
        # 测试表数量
        query = "docker exec production-mysql mysql -u root -pf_mysql_password_2025 -e 'SELECT COUNT(*) as table_count FROM information_schema.tables WHERE table_schema = \"jobfirst_future\";'"
        exit_code, stdout, stderr = self.run_ssh_command(query)
        
        if exit_code == 0:
            # 解析表数量
            lines = stdout.split('\n')
            table_count = 0
            for line in lines:
                if line.strip().isdigit():
                    table_count = int(line.strip())
                    break
            
            return {
                "status": "success",
                "table_count": table_count,
                "port": 3306
            }
        else:
            return {
                "status": "failed",
                "error": stderr
            }
    
    def test_postgresql(self) -> Dict[str, Any]:
        """测试PostgreSQL"""
        logger.info("🔍 测试PostgreSQL...")
        
        # 测试表数量
        query = "docker exec production-postgres psql -U future_user -d jobfirst_future -c \"SELECT COUNT(*) as table_count FROM information_schema.tables WHERE table_schema = 'public';\""
        exit_code, stdout, stderr = self.run_ssh_command(query)
        
        if exit_code == 0:
            # 解析表数量
            lines = stdout.split('\n')
            table_count = 0
            for line in lines:
                if line.strip().isdigit():
                    table_count = int(line.strip())
                    break
            
            return {
                "status": "success",
                "table_count": table_count,
                "port": 5432
            }
        else:
            return {
                "status": "failed",
                "error": stderr
            }
    
    def test_redis(self) -> Dict[str, Any]:
        """测试Redis"""
        logger.info("🔍 测试Redis...")
        
        # 测试连接
        ping_query = "redis-cli -h localhost -p 6379 -a f_redis_password_2025 ping"
        exit_code, stdout, stderr = self.run_ssh_command(ping_query)
        
        if exit_code == 0 and "PONG" in stdout:
            # 获取键数量
            key_query = "redis-cli -h localhost -p 6379 -a f_redis_password_2025 dbsize"
            key_exit_code, key_stdout, key_stderr = self.run_ssh_command(key_query)
            
            key_count = 0
            if key_exit_code == 0:
                try:
                    key_count = int(key_stdout.strip())
                except:
                    key_count = 0
            
            return {
                "status": "success",
                "key_count": key_count,
                "port": 6379
            }
        else:
            return {
                "status": "failed",
                "error": stderr
            }
    
    def test_neo4j(self) -> Dict[str, Any]:
        """测试Neo4j"""
        logger.info("🔍 测试Neo4j...")
        
        # 测试连接
        test_query = "docker exec production-neo4j cypher-shell -u neo4j -p f_neo4j_password_2025 'RETURN 1 as test;'"
        exit_code, stdout, stderr = self.run_ssh_command(test_query)
        
        if exit_code == 0:
            # 获取节点数量
            node_query = "docker exec production-neo4j cypher-shell -u neo4j -p f_neo4j_password_2025 'MATCH (n) RETURN COUNT(n) as node_count;'"
            node_exit_code, node_stdout, node_stderr = self.run_ssh_command(node_query)
            
            node_count = 0
            if node_exit_code == 0:
                try:
                    lines = node_stdout.split('\n')
                    for line in lines:
                        if line.strip().isdigit():
                            node_count = int(line.strip())
                            break
                except:
                    node_count = 0
            
            return {
                "status": "success",
                "node_count": node_count,
                "port": 7474
            }
        else:
            return {
                "status": "failed",
                "error": stderr
            }
    
    def test_elasticsearch(self) -> Dict[str, Any]:
        """测试Elasticsearch"""
        logger.info("🔍 测试Elasticsearch...")
        
        # 测试连接
        query = "curl -s http://localhost:9200/_cluster/health"
        exit_code, stdout, stderr = self.run_ssh_command(query)
        
        if exit_code == 0 and stdout.strip():
            try:
                health_data = json.loads(stdout)
                return {
                    "status": "success",
                    "cluster_status": health_data.get("status", "unknown"),
                    "port": 9200
                }
            except:
                return {
                    "status": "success",
                    "cluster_status": "unknown",
                    "port": 9200
                }
        else:
            # 尝试基本连接
            basic_query = "curl -s http://localhost:9200/"
            basic_exit_code, basic_stdout, basic_stderr = self.run_ssh_command(basic_query)
            
            if basic_exit_code == 0 and basic_stdout.strip():
                return {
                    "status": "success",
                    "cluster_status": "initializing",
                    "port": 9200
                }
            else:
                return {
                    "status": "failed",
                    "error": "No response"
                }
    
    def test_weaviate(self) -> Dict[str, Any]:
        """测试Weaviate"""
        logger.info("🔍 测试Weaviate...")
        
        # 测试连接
        query = "curl -s http://localhost:8080/v1/meta"
        exit_code, stdout, stderr = self.run_ssh_command(query)
        
        if exit_code == 0 and stdout.strip():
            try:
                meta_data = json.loads(stdout)
                return {
                    "status": "success",
                    "version": meta_data.get("version", "unknown"),
                    "port": 8080
                }
            except:
                return {
                    "status": "success",
                    "version": "unknown",
                    "port": 8080
                }
        else:
            return {
                "status": "failed",
                "error": stderr or "No response"
            }
    
    def run_all_tests(self) -> Dict[str, Any]:
        """运行所有测试"""
        logger.info("🚀 开始阿里云多数据库通信连接测试...")
        
        results = {
            "test_time": self.start_time.isoformat(),
            "server_ip": self.server_ip,
            "databases": {},
            "summary": {}
        }
        
        # 测试各个数据库
        database_tests = {
            "MySQL": self.test_mysql,
            "PostgreSQL": self.test_postgresql,
            "Redis": self.test_redis,
            "Neo4j": self.test_neo4j,
            "Elasticsearch": self.test_elasticsearch,
            "Weaviate": self.test_weaviate
        }
        
        success_count = 0
        total_count = len(database_tests)
        
        for db_name, test_func in database_tests.items():
            try:
                test_result = test_func()
                results["databases"][db_name] = test_result
                
                if test_result.get("status") == "success":
                    success_count += 1
                    logger.info(f"✅ {db_name} 连接成功")
                else:
                    logger.error(f"❌ {db_name} 连接失败: {test_result.get('error', 'Unknown error')}")
                    
            except Exception as e:
                logger.error(f"❌ {db_name} 测试异常: {str(e)}")
                results["databases"][db_name] = {
                    "status": "failed",
                    "error": str(e)
                }
        
        # 计算成功率
        success_rate = (success_count / total_count) * 100
        
        results["summary"] = {
            "total_databases": total_count,
            "successful_connections": success_count,
            "failed_connections": total_count - success_count,
            "success_rate": f"{success_rate:.1f}%",
            "test_duration": str(datetime.now() - self.start_time)
        }
        
        return results
    
    def save_results(self, results: Dict[str, Any]) -> str:
        """保存测试结果"""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"alibaba_cloud_database_test_simple_{timestamp}.json"
        
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(results, f, indent=2, ensure_ascii=False)
        
        return filename
    
    def print_summary(self, results: Dict[str, Any]):
        """打印测试摘要"""
        print("\n" + "="*60)
        print("🎯 阿里云多数据库通信连接测试结果")
        print("="*60)
        
        print(f"🕐 测试时间: {results['test_time']}")
        print(f"🌐 服务器IP: {results['server_ip']}")
        
        print(f"\n📊 测试摘要:")
        summary = results['summary']
        print(f"  总数据库数量: {summary['total_databases']}")
        print(f"  成功连接: {summary['successful_connections']}")
        print(f"  失败连接: {summary['failed_connections']}")
        print(f"  成功率: {summary['success_rate']}")
        print(f"  测试耗时: {summary['test_duration']}")
        
        print(f"\n🔍 详细结果:")
        for db_name, db_result in results['databases'].items():
            status_icon = "✅" if db_result.get('status') == 'success' else "❌"
            print(f"  {status_icon} {db_name}: {db_result.get('status', 'unknown')}")
            
            if db_result.get('status') == 'success':
                if 'table_count' in db_result:
                    print(f"     表数量: {db_result['table_count']}")
                if 'key_count' in db_result:
                    print(f"     键数量: {db_result['key_count']}")
                if 'node_count' in db_result:
                    print(f"     节点数量: {db_result['node_count']}")
                if 'cluster_status' in db_result:
                    print(f"     集群状态: {db_result['cluster_status']}")
                if 'version' in db_result:
                    print(f"     版本: {db_result['version']}")
            else:
                print(f"     错误: {db_result.get('error', 'Unknown error')}")
        
        print("\n" + "="*60)

def main():
    """主函数"""
    print("🚀 阿里云多数据库通信连接测试 - 简化版")
    print("基于@future_optimized/经验")
    print("-" * 60)
    
    tester = AlibabaCloudDatabaseTester()
    
    try:
        # 运行所有测试
        results = tester.run_all_tests()
        
        # 保存结果
        filename = tester.save_results(results)
        
        # 打印摘要
        tester.print_summary(results)
        
        print(f"\n💾 测试结果已保存到: {filename}")
        
        # 判断测试是否成功
        success_rate = float(results['summary']['success_rate'].rstrip('%'))
        if success_rate >= 90:
            print("\n🎉 测试成功！数据库连接稳定性良好！")
            return 0
        elif success_rate >= 70:
            print("\n⚠️  测试部分成功，建议检查失败的数据库连接")
            return 1
        else:
            print("\n❌ 测试失败，需要检查数据库配置")
            return 2
            
    except Exception as e:
        logger.error(f"测试过程中发生异常: {str(e)}")
        print(f"\n❌ 测试异常: {str(e)}")
        return 3

if __name__ == "__main__":
    sys.exit(main())
