#!/usr/bin/env python3
"""
增强版动态数据库测试脚本
自动检测容器IP地址，动态配置测试参数，解决Docker容器IP地址变化问题
"""

import asyncio
import asyncpg
import aiomysql
import redis
import neo4j
import json
import time
import random
import docker
from datetime import datetime, timedelta
from typing import Dict, Any, List, Optional

class DynamicDatabaseTester:
    """动态数据库测试器"""
    
    def __init__(self, version: str):
        self.version = version
        self.docker_client = docker.from_env()
        self.container_ips = {}
        self.test_results = {}
        
        # 版本配置
        self.config = {
            'future': {
                'prefix': 'f-',
                'network': 'future_f-network',
                'mysql_port': 3306,
                'postgres_port': 5432,
                'redis_port': 6379,
                'neo4j_http_port': 7474,
                'neo4j_bolt_port': 7687,
                'mysql_user': 'f_mysql_user',
                'mysql_password': 'f_mysql_password_2025',
                'mysql_db': 'f_mysql',
                'postgres_user': 'f_pg_user',
                'postgres_password': 'f_pg_password_2025',
                'postgres_db': 'f_pg',
                'redis_password': 'f_redis_password_2025',
                'neo4j_password': 'f_neo4j_password_2025'
            },
            'dao': {
                'prefix': 'd-',
                'network': 'dao_d-network',
                'mysql_port': 3306,
                'postgres_port': 5432,
                'redis_port': 6379,
                'neo4j_http_port': 7474,
                'neo4j_bolt_port': 7687,
                'mysql_user': 'd_mysql_user',
                'mysql_password': 'd_mysql_password_2025',
                'mysql_db': 'd_mysql',
                'postgres_user': 'd_pg_user',
                'postgres_password': 'd_pg_password_2025',
                'postgres_db': 'd_pg',
                'redis_password': 'd_redis_password_2025',
                'neo4j_password': 'd_neo4j_password_2025'
            },
            'blockchain': {
                'prefix': 'b-',
                'network': 'blockchain_b-network',
                'mysql_port': 3306,
                'postgres_port': 5432,
                'redis_port': 6379,
                'neo4j_http_port': 7474,
                'neo4j_bolt_port': 7687,
                'mysql_user': 'b_mysql_user',
                'mysql_password': 'b_mysql_password_2025',
                'mysql_db': 'b_mysql',
                'postgres_user': 'b_pg_user',
                'postgres_password': 'b_pg_password_2025',
                'postgres_db': 'b_pg',
                'redis_password': 'b_redis_password_2025',
                'neo4j_password': 'b_neo4j_password_2025'
            }
        }[version]
    
    def detect_container_ips(self) -> Dict[str, str]:
        """检测容器IP地址"""
        print(f"🔍 检测 {self.version.upper()}版容器IP地址...")
        print("=" * 50)
        
        network_name = self.config['network']
        prefix = self.config['prefix']
        
        # 主要数据库容器
        main_containers = [
            f"{prefix}mysql",
            f"{prefix}postgres", 
            f"{prefix}redis",
            f"{prefix}neo4j"
        ]
        
        ip_mapping = {}
        
        try:
            # 获取网络信息
            network = self.docker_client.networks.get(network_name)
            containers = network.attrs['Containers']
            
            for container_id, container_info in containers.items():
                container_name = container_info['Name']
                ip_address = container_info['IPv4Address'].split('/')[0]
                
                if container_name in main_containers:
                    ip_mapping[container_name] = ip_address
                    print(f"✅ {container_name}: {ip_address}")
                else:
                    print(f"ℹ️  {container_name}: {ip_address} (非主要数据库)")
            
            # 检查是否检测到所有主要容器
            missing_containers = [c for c in main_containers if c not in ip_mapping]
            if missing_containers:
                print(f"❌ 未检测到容器: {missing_containers}")
                return {}
            
            self.container_ips = ip_mapping
            return ip_mapping
            
        except Exception as e:
            print(f"❌ 检测容器IP地址失败: {e}")
            return {}
    
    def check_ports_availability(self) -> Dict[str, bool]:
        """检查端口可用性"""
        print(f"\n🔌 检查 {self.version.upper()}版端口可用性...")
        print("=" * 50)
        
        port_checks = {}
        
        # 检查外部端口
        external_ports = {
            'mysql': 3306 if self.version == 'future' else 3307 if self.version == 'dao' else 3308,
            'postgres': 5432 if self.version == 'future' else 5433 if self.version == 'dao' else 5434,
            'redis': 6379 if self.version == 'future' else 6380 if self.version == 'dao' else 6381,
            'neo4j_http': 7474 if self.version == 'future' else 7475 if self.version == 'dao' else 7476,
            'neo4j_bolt': 7687 if self.version == 'future' else 7688 if self.version == 'dao' else 7689
        }
        
        for service, port in external_ports.items():
            try:
                import socket
                sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                sock.settimeout(1)
                result = sock.connect_ex(('localhost', port))
                sock.close()
                
                if result == 0:
                    port_checks[service] = True
                    print(f"✅ {service}: 端口 {port} 可用")
                else:
                    port_checks[service] = False
                    print(f"❌ {service}: 端口 {port} 不可用")
            except Exception as e:
                port_checks[service] = False
                print(f"❌ {service}: 端口检查失败 - {e}")
        
        return port_checks
    
    async def test_mysql_connection(self, ip: str) -> Dict[str, Any]:
        """测试MySQL连接"""
        try:
            conn = await aiomysql.connect(
                host=ip,
                port=self.config['mysql_port'],
                user=self.config['mysql_user'],
                password=self.config['mysql_password'],
                db=self.config['mysql_db']
            )
            
            async with conn.cursor() as cursor:
                await cursor.execute("SELECT 1")
                result = await cursor.fetchone()
            
            await conn.ensure_closed()
            
            return {
                'status': 'success',
                'message': f'{self.version.upper()}版MySQL连接成功',
                'data': result[0] if result else None
            }
        except Exception as e:
            return {
                'status': 'error',
                'message': f'{self.version.upper()}版MySQL连接失败: {e}'
            }
    
    async def test_postgres_connection(self, ip: str) -> Dict[str, Any]:
        """测试PostgreSQL连接"""
        try:
            conn = await asyncpg.connect(
                host=ip,
                port=self.config['postgres_port'],
                user=self.config['postgres_user'],
                password=self.config['postgres_password'],
                database=self.config['postgres_db']
            )
            
            result = await conn.fetchval("SELECT 1")
            await conn.close()
            
            return {
                'status': 'success',
                'message': f'{self.version.upper()}版PostgreSQL连接成功',
                'data': result
            }
        except Exception as e:
            return {
                'status': 'error',
                'message': f'{self.version.upper()}版PostgreSQL连接失败: {e}'
            }
    
    async def test_redis_connection(self, ip: str) -> Dict[str, Any]:
        """测试Redis连接"""
        try:
            redis_client = redis.Redis(
                host=ip,
                port=self.config['redis_port'],
                password=self.config['redis_password'],
                db=0,
                decode_responses=True,
                socket_connect_timeout=5,
                socket_timeout=5
            )
            
            # 测试连接
            redis_client.ping()
            
            # 测试读写
            test_key = f"{self.version}_test_key"
            test_value = f"{self.version}_test_value"
            redis_client.set(test_key, test_value)
            result = redis_client.get(test_key)
            redis_client.delete(test_key)
            
            redis_client.close()
            
            return {
                'status': 'success',
                'message': f'{self.version.upper()}版Redis连接成功',
                'data': result
            }
        except Exception as e:
            return {
                'status': 'error',
                'message': f'{self.version.upper()}版Redis连接失败: {e}'
            }
    
    async def test_neo4j_connection(self, ip: str) -> Dict[str, Any]:
        """测试Neo4j连接"""
        try:
            driver = neo4j.AsyncGraphDatabase.driver(
                f"bolt://{ip}:{self.config['neo4j_bolt_port']}",
                auth=(f"{self.config['prefix']}neo4j", self.config['neo4j_password'])
            )
            
            async with driver.session() as session:
                result = await session.run("RETURN 1 as test")
                record = await result.single()
            
            await driver.close()
            
            return {
                'status': 'success',
                'message': f'{self.version.upper()}版Neo4j连接成功',
                'data': dict(record) if record else None
            }
        except Exception as e:
            return {
                'status': 'error',
                'message': f'{self.version.upper()}版Neo4j连接失败: {e}'
            }
    
    async def run_connectivity_tests(self) -> Dict[str, Any]:
        """运行连接测试"""
        print(f"\n🧪 运行 {self.version.upper()}版连接测试...")
        print("=" * 50)
        
        results = {}
        
        # MySQL测试
        mysql_ip = self.container_ips.get(f"{self.config['prefix']}mysql")
        if mysql_ip:
            print(f"🔍 测试MySQL连接: {mysql_ip}")
            results['mysql'] = await self.test_mysql_connection(mysql_ip)
        else:
            results['mysql'] = {'status': 'error', 'message': 'MySQL容器IP地址未检测到'}
        
        # PostgreSQL测试
        postgres_ip = self.container_ips.get(f"{self.config['prefix']}postgres")
        if postgres_ip:
            print(f"🔍 测试PostgreSQL连接: {postgres_ip}")
            results['postgres'] = await self.test_postgres_connection(postgres_ip)
        else:
            results['postgres'] = {'status': 'error', 'message': 'PostgreSQL容器IP地址未检测到'}
        
        # Redis测试
        redis_ip = self.container_ips.get(f"{self.config['prefix']}redis")
        if redis_ip:
            print(f"🔍 测试Redis连接: {redis_ip}")
            results['redis'] = await self.test_redis_connection(redis_ip)
        else:
            results['redis'] = {'status': 'error', 'message': 'Redis容器IP地址未检测到'}
        
        # Neo4j测试
        neo4j_ip = self.container_ips.get(f"{self.config['prefix']}neo4j")
        if neo4j_ip:
            print(f"🔍 测试Neo4j连接: {neo4j_ip}")
            results['neo4j'] = await self.test_neo4j_connection(neo4j_ip)
        else:
            results['neo4j'] = {'status': 'error', 'message': 'Neo4j容器IP地址未检测到'}
        
        return results
    
    def generate_test_report(self, connectivity_results: Dict[str, Any], port_checks: Dict[str, bool]) -> Dict[str, Any]:
        """生成测试报告"""
        success_count = sum(1 for result in connectivity_results.values() if result.get('status') == 'success')
        total_count = len(connectivity_results)
        
        report = {
            'test_time': datetime.now().isoformat(),
            'version': self.version,
            'test_type': 'dynamic_connectivity',
            'container_ips': self.container_ips,
            'port_checks': port_checks,
            'total_tests': total_count,
            'success_count': success_count,
            'error_count': total_count - success_count,
            'success_rate': f"{(success_count / total_count * 100):.1f}%",
            'results': connectivity_results
        }
        
        return report
    
    def save_report(self, report: Dict[str, Any], filename: str = None):
        """保存测试报告"""
        if filename is None:
            filename = f"{self.version}_dynamic_test_report.json"
        
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(report, f, indent=2, ensure_ascii=False)
        
        print(f"\n📄 测试报告已保存到: {filename}")
        return filename
    
    async def run_full_test(self):
        """运行完整测试"""
        print(f"🚀 开始 {self.version.upper()}版动态数据库测试...")
        print("=" * 60)
        
        start_time = time.time()
        
        # 1. 检测容器IP地址
        ip_mapping = self.detect_container_ips()
        if not ip_mapping:
            print("❌ 容器IP地址检测失败，无法继续测试")
            return False
        
        # 2. 检查端口可用性
        port_checks = self.check_ports_availability()
        
        # 3. 运行连接测试
        connectivity_results = await self.run_connectivity_tests()
        
        # 4. 生成测试报告
        report = self.generate_test_report(connectivity_results, port_checks)
        
        # 5. 保存报告
        self.save_report(report)
        
        # 6. 显示结果摘要
        end_time = time.time()
        duration = end_time - start_time
        
        print(f"\n📊 {self.version.upper()}版动态测试结果统计:")
        print("=" * 50)
        print(f"✅ 成功: {report['success_count']}/{report['total_tests']}")
        print(f"❌ 失败: {report['error_count']}/{report['total_tests']}")
        print(f"📈 成功率: {report['success_rate']}")
        print(f"⏱️  总耗时: {duration:.2f}秒")
        
        # 显示详细结果
        print(f"\n📋 详细结果:")
        for service, result in connectivity_results.items():
            status_icon = "✅" if result.get('status') == 'success' else "❌"
            print(f"{status_icon} {service}: {result.get('message', '未知状态')}")
        
        return report['success_count'] == report['total_tests']

async def main():
    """主函数"""
    import sys
    
    if len(sys.argv) != 2:
        print("用法: python3 enhanced_dynamic_database_test.py <future|dao|blockchain>")
        sys.exit(1)
    
    version = sys.argv[1].lower()
    if version not in ['future', 'dao', 'blockchain']:
        print("错误: 版本必须是 future、dao 或 blockchain")
        sys.exit(1)
    
    tester = DynamicDatabaseTester(version)
    success = await tester.run_full_test()
    
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    asyncio.run(main())
