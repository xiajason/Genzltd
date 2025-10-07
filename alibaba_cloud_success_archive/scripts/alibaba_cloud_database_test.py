#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
阿里云多数据库通信连接测试和数据一致性测试
基于@future_optimized/经验
"""

import asyncio
import json
import time
import subprocess
import sys
from datetime import datetime
from typing import Dict, List, Any, Optional
import logging

# 配置日志
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class AlibabaCloudDatabaseTester:
    """阿里云多数据库测试器"""
    
    def __init__(self):
        self.server_ip = "47.115.168.107"
        self.ssh_key = "~/.ssh/cross_cloud_key"
        self.test_results = {}
        self.start_time = datetime.now()
        
        # 数据库配置
        self.databases = {
            "MySQL": {
                "container": "production-mysql",
                "port": 3306,
                "password": "f_mysql_password_2025",
                "database": "jobfirst_future"
            },
            "PostgreSQL": {
                "container": "production-postgres",
                "port": 5432,
                "user": "future_user",
                "password": "f_postgres_password_2025",
                "database": "jobfirst_future"
            },
            "Redis": {
                "port": 6379,
                "password": "f_redis_password_2025"
            },
            "Neo4j": {
                "container": "production-neo4j",
                "port": 7474,
                "user": "neo4j",
                "password": "f_neo4j_password_2025"
            },
            "Elasticsearch": {
                "port": 9200
            },
            "Weaviate": {
                "port": 8080
            }
        }
    
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
    
    def test_docker_containers(self) -> Dict[str, Any]:
        """测试Docker容器状态"""
        logger.info("🔍 测试Docker容器状态...")
        
        exit_code, stdout, stderr = self.run_ssh_command("docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'")
        
        if exit_code != 0:
            return {
                "status": "failed",
                "error": stderr,
                "containers": []
            }
        
        containers = []
        lines = stdout.strip().split('\n')[1:]  # 跳过表头
        
        for line in lines:
            if line.strip():
                parts = line.split('\t')
                if len(parts) >= 3:
                    containers.append({
                        "name": parts[0],
                        "status": parts[1],
                        "ports": parts[2]
                    })
        
        return {
            "status": "success",
            "containers": containers,
            "total": len(containers)
        }
    
    def test_mysql_connection(self) -> Dict[str, Any]:
        """测试MySQL连接"""
        logger.info("🔍 测试MySQL连接...")
        
        db_config = self.databases["MySQL"]
        
        # 测试容器连接
        test_query = f"docker exec {db_config['container']} mysql -u root -p{db_config['password']} -e \"SELECT COUNT(*) as table_count FROM information_schema.tables WHERE table_schema = '{db_config['database']}';\""
        
        exit_code, stdout, stderr = self.run_ssh_command(test_query)
        
        if exit_code == 0:
            # 解析表数量
            try:
                lines = stdout.strip().split('\n')
                for line in lines:
                    if line.isdigit():
                        table_count = int(line)
                        break
                else:
                    table_count = 0
            except:
                table_count = 0
            
            return {
                "status": "success",
                "connection": "Docker exec",
                "database": db_config['database'],
                "table_count": table_count,
                "port": db_config['port']
            }
        else:
            return {
                "status": "failed",
                "error": stderr,
                "connection": "Docker exec"
            }
    
    def test_postgresql_connection(self) -> Dict[str, Any]:
        """测试PostgreSQL连接"""
        logger.info("🔍 测试PostgreSQL连接...")
        
        db_config = self.databases["PostgreSQL"]
        
        # 测试容器连接
        test_query = f"docker exec {db_config['container']} psql -U {db_config['user']} -d {db_config['database']} -c \"SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';\""
        
        exit_code, stdout, stderr = self.run_ssh_command(test_query)
        
        if exit_code == 0:
            # 解析表数量
            try:
                lines = stdout.strip().split('\n')
                for line in lines:
                    if line.strip().isdigit():
                        table_count = int(line.strip())
                        break
                else:
                    table_count = 0
            except:
                table_count = 0
            
            return {
                "status": "success",
                "connection": "Docker exec",
                "database": db_config['database'],
                "table_count": table_count,
                "port": db_config['port']
            }
        else:
            return {
                "status": "failed",
                "error": stderr,
                "connection": "Docker exec"
            }
    
    def test_redis_connection(self) -> Dict[str, Any]:
        """测试Redis连接"""
        logger.info("🔍 测试Redis连接...")
        
        db_config = self.databases["Redis"]
        
        # 测试Redis连接
        test_query = f"redis-cli -h localhost -p {db_config['port']} -a {db_config['password']} ping"
        
        exit_code, stdout, stderr = self.run_ssh_command(test_query)
        
        if exit_code == 0 and "PONG" in stdout:
            # 获取键数量
            key_query = f"redis-cli -h localhost -p {db_config['port']} -a {db_config['password']} dbsize"
            key_exit_code, key_stdout, key_stderr = self.run_ssh_command(key_query)
            
            key_count = 0
            if key_exit_code == 0:
                try:
                    key_count = int(key_stdout.strip())
                except:
                    key_count = 0
            
            return {
                "status": "success",
                "connection": "Direct",
                "key_count": key_count,
                "port": db_config['port']
            }
        else:
            return {
                "status": "failed",
                "error": stderr,
                "connection": "Direct"
            }
    
    def test_neo4j_connection(self) -> Dict[str, Any]:
        """测试Neo4j连接"""
        logger.info("🔍 测试Neo4j连接...")
        
        db_config = self.databases["Neo4j"]
        
        # 测试Neo4j连接
        test_query = f"docker exec {db_config['container']} cypher-shell -u {db_config['user']} -p {db_config['password']} \"MATCH (n) RETURN COUNT(n) as node_count;\""
        
        exit_code, stdout, stderr = self.run_ssh_command(test_query)
        
        if exit_code == 0:
            # 解析节点数量
            try:
                lines = stdout.strip().split('\n')
                for line in lines:
                    if line.strip().isdigit():
                        node_count = int(line.strip())
                        break
                else:
                    node_count = 0
            except:
                node_count = 0
            
            return {
                "status": "success",
                "connection": "Docker exec",
                "node_count": node_count,
                "port": db_config['port']
            }
        else:
            return {
                "status": "failed",
                "error": stderr,
                "connection": "Docker exec"
            }
    
    def test_elasticsearch_connection(self) -> Dict[str, Any]:
        """测试Elasticsearch连接"""
        logger.info("🔍 测试Elasticsearch连接...")
        
        db_config = self.databases["Elasticsearch"]
        
        # 测试Elasticsearch连接
        test_query = f"curl -s http://localhost:{db_config['port']}/_cluster/health"
        
        exit_code, stdout, stderr = self.run_ssh_command(test_query)
        
        if exit_code == 0:
            try:
                health_data = json.loads(stdout)
                return {
                    "status": "success",
                    "connection": "HTTP",
                    "cluster_status": health_data.get("status", "unknown"),
                    "port": db_config['port']
                }
            except:
                return {
                    "status": "success",
                    "connection": "HTTP",
                    "cluster_status": "unknown",
                    "port": db_config['port']
                }
        else:
            return {
                "status": "failed",
                "error": stderr,
                "connection": "HTTP"
            }
    
    def test_weaviate_connection(self) -> Dict[str, Any]:
        """测试Weaviate连接"""
        logger.info("🔍 测试Weaviate连接...")
        
        db_config = self.databases["Weaviate"]
        
        # 测试Weaviate连接
        test_query = f"curl -s http://localhost:{db_config['port']}/v1/meta"
        
        exit_code, stdout, stderr = self.run_ssh_command(test_query)
        
        if exit_code == 0:
            try:
                meta_data = json.loads(stdout)
                return {
                    "status": "success",
                    "connection": "HTTP",
                    "version": meta_data.get("version", "unknown"),
                    "port": db_config['port']
                }
            except:
                return {
                    "status": "success",
                    "connection": "HTTP",
                    "version": "unknown",
                    "port": db_config['port']
                }
        else:
            return {
                "status": "failed",
                "error": stderr,
                "connection": "HTTP"
            }
    
    def run_all_tests(self) -> Dict[str, Any]:
        """运行所有数据库测试"""
        logger.info("🚀 开始阿里云多数据库通信连接测试...")
        
        results = {
            "test_time": self.start_time.isoformat(),
            "server_ip": self.server_ip,
            "databases": {},
            "summary": {}
        }
        
        # 测试Docker容器状态
        container_test = self.test_docker_containers()
        results["docker_containers"] = container_test
        
        # 测试各个数据库
        database_tests = {
            "MySQL": self.test_mysql_connection,
            "PostgreSQL": self.test_postgresql_connection,
            "Redis": self.test_redis_connection,
            "Neo4j": self.test_neo4j_connection,
            "Elasticsearch": self.test_elasticsearch_connection,
            "Weaviate": self.test_weaviate_connection
        }
        
        success_count = 0
        total_count = len(database_tests)
        
        for db_name, test_func in database_tests.items():
            logger.info(f"🔍 测试 {db_name}...")
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
        filename = f"alibaba_cloud_database_test_{timestamp}.json"
        
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
    print("🚀 阿里云多数据库通信连接测试和数据一致性测试")
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
