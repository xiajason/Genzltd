#!/usr/bin/env python3
"""
统一动态测试套件
集成连接测试、数据一致性测试、端口检查、IP检测等功能
解决Docker容器IP地址变化问题，提供完整的自动化测试解决方案
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
import socket
from datetime import datetime, timedelta
from typing import Dict, Any, List, Optional
from decimal import Decimal

class UnifiedDynamicTestSuite:
    """统一动态测试套件"""
    
    def __init__(self, version: str):
        self.version = version
        self.docker_client = docker.from_env()
        self.container_ips = {}
        self.port_checks = {}
        self.connectivity_results = {}
        self.consistency_results = {}
        
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
        
        self.port_checks = port_checks
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
                auth=("neo4j", self.config['neo4j_password'])
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
        
        self.connectivity_results = results
        return results
    
    def generate_test_data(self) -> Dict[str, Any]:
        """生成测试数据"""
        test_data = {
            'user_id': f"{self.version}_test_user_{random.randint(1000, 9999)}",
            'transaction_id': f"tx_{self.version}_test_{random.randint(1000, 9999)}",
            'amount': round(random.uniform(10.0, 1000.0), 2),
            'currency': random.choice(['USD', 'EUR', 'BTC', 'ETH']),
            'timestamp': datetime.now().isoformat(),
            'status': random.choice(['pending', 'completed', 'failed']),
            'description': f"{self.version.upper()}版测试数据"
        }
        return test_data
    
    async def test_mysql_data_consistency(self, ip: str, test_data: Dict[str, Any]) -> Dict[str, Any]:
        """测试MySQL数据一致性"""
        try:
            conn = await aiomysql.connect(
                host=ip,
                port=self.config['mysql_port'],
                user=self.config['mysql_user'],
                password=self.config['mysql_password'],
                db=self.config['mysql_db']
            )
            
            async with conn.cursor() as cursor:
                # 创建测试表
                await cursor.execute("""
                    CREATE TABLE IF NOT EXISTS test_consistency (
                        id INT AUTO_INCREMENT PRIMARY KEY,
                        user_id VARCHAR(255),
                        transaction_id VARCHAR(255),
                        amount DECIMAL(10,2),
                        currency VARCHAR(10),
                        timestamp VARCHAR(255),
                        status VARCHAR(50),
                        description TEXT
                    )
                """)
                
                # 插入测试数据
                await cursor.execute("""
                    INSERT INTO test_consistency 
                    (user_id, transaction_id, amount, currency, timestamp, status, description)
                    VALUES (%s, %s, %s, %s, %s, %s, %s)
                """, (
                    test_data['user_id'],
                    test_data['transaction_id'],
                    test_data['amount'],
                    test_data['currency'],
                    test_data['timestamp'],
                    test_data['status'],
                    test_data['description']
                ))
                
                # 验证数据
                await cursor.execute("""
                    SELECT * FROM test_consistency 
                    WHERE user_id = %s AND transaction_id = %s
                """, (test_data['user_id'], test_data['transaction_id']))
                
                result = await cursor.fetchone()
                
                # 清理测试数据
                await cursor.execute("""
                    DELETE FROM test_consistency 
                    WHERE user_id = %s AND transaction_id = %s
                """, (test_data['user_id'], test_data['transaction_id']))
            
            await conn.ensure_closed()
            
            return {
                'status': 'success',
                'message': f'{self.version.upper()}版MySQL数据一致性测试成功',
                'data': dict(zip(['id', 'user_id', 'transaction_id', 'amount', 'currency', 'timestamp', 'status', 'description'], result)) if result else None
            }
        except Exception as e:
            return {
                'status': 'error',
                'message': f'{self.version.upper()}版MySQL数据一致性测试失败: {e}'
            }
    
    async def test_postgres_data_consistency(self, ip: str, test_data: Dict[str, Any]) -> Dict[str, Any]:
        """测试PostgreSQL数据一致性"""
        try:
            conn = await asyncpg.connect(
                host=ip,
                port=self.config['postgres_port'],
                user=self.config['postgres_user'],
                password=self.config['postgres_password'],
                database=self.config['postgres_db']
            )
            
            # 创建测试表
            await conn.execute("""
                CREATE TABLE IF NOT EXISTS test_consistency (
                    id SERIAL PRIMARY KEY,
                    user_id VARCHAR(255),
                    transaction_id VARCHAR(255),
                    amount DECIMAL(10,2),
                    currency VARCHAR(10),
                    timestamp VARCHAR(255),
                    status VARCHAR(50),
                    description TEXT
                )
            """)
            
            # 插入测试数据
            await conn.execute("""
                INSERT INTO test_consistency 
                (user_id, transaction_id, amount, currency, timestamp, status, description)
                VALUES ($1, $2, $3, $4, $5, $6, $7)
            """, 
                test_data['user_id'],
                test_data['transaction_id'],
                test_data['amount'],
                test_data['currency'],
                test_data['timestamp'],
                test_data['status'],
                test_data['description']
            )
            
            # 验证数据
            result = await conn.fetchrow("""
                SELECT * FROM test_consistency 
                WHERE user_id = $1 AND transaction_id = $2
            """, test_data['user_id'], test_data['transaction_id'])
            
            # 清理测试数据
            await conn.execute("""
                DELETE FROM test_consistency 
                WHERE user_id = $1 AND transaction_id = $2
            """, test_data['user_id'], test_data['transaction_id'])
            
            await conn.close()
            
            return {
                'status': 'success',
                'message': f'{self.version.upper()}版PostgreSQL数据一致性测试成功',
                'data': dict(result) if result else None
            }
        except Exception as e:
            return {
                'status': 'error',
                'message': f'{self.version.upper()}版PostgreSQL数据一致性测试失败: {e}'
            }
    
    async def test_redis_data_consistency(self, ip: str, test_data: Dict[str, Any]) -> Dict[str, Any]:
        """测试Redis数据一致性"""
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
            
            # 存储测试数据
            test_key = f"test_consistency:{test_data['user_id']}:{test_data['transaction_id']}"
            redis_client.set(test_key, json.dumps(test_data))
            
            # 验证数据
            result = redis_client.get(test_key)
            parsed_result = json.loads(result) if result else None
            
            # 清理测试数据
            redis_client.delete(test_key)
            redis_client.close()
            
            return {
                'status': 'success',
                'message': f'{self.version.upper()}版Redis数据一致性测试成功',
                'data': parsed_result
            }
        except Exception as e:
            return {
                'status': 'error',
                'message': f'{self.version.upper()}版Redis数据一致性测试失败: {e}'
            }
    
    async def test_neo4j_data_consistency(self, ip: str, test_data: Dict[str, Any]) -> Dict[str, Any]:
        """测试Neo4j数据一致性"""
        try:
            driver = neo4j.AsyncGraphDatabase.driver(
                f"bolt://{ip}:{self.config['neo4j_bolt_port']}",
                auth=("neo4j", self.config['neo4j_password'])
            )
            
            async with driver.session() as session:
                # 创建测试节点
                await session.run("""
                    CREATE (n:TestConsistency {
                        user_id: $user_id,
                        transaction_id: $transaction_id,
                        amount: $amount,
                        currency: $currency,
                        timestamp: $timestamp,
                        status: $status,
                        description: $description
                    })
                """, **test_data)
                
                # 验证数据
                result = await session.run("""
                    MATCH (n:TestConsistency)
                    WHERE n.user_id = $user_id AND n.transaction_id = $transaction_id
                    RETURN n
                """, user_id=test_data['user_id'], transaction_id=test_data['transaction_id'])
                
                record = await result.single()
                
                # 清理测试数据
                await session.run("""
                    MATCH (n:TestConsistency)
                    WHERE n.user_id = $user_id AND n.transaction_id = $transaction_id
                    DELETE n
                """, user_id=test_data['user_id'], transaction_id=test_data['transaction_id'])
            
            await driver.close()
            
            return {
                'status': 'success',
                'message': f'{self.version.upper()}版Neo4j数据一致性测试成功',
                'data': dict(record['n']) if record else None
            }
        except Exception as e:
            return {
                'status': 'error',
                'message': f'{self.version.upper()}版Neo4j数据一致性测试失败: {e}'
            }
    
    async def test_cross_database_consistency(self, test_data: Dict[str, Any]) -> Dict[str, Any]:
        """测试跨数据库数据一致性"""
        try:
            # 在MySQL中存储数据
            mysql_ip = self.container_ips.get(f"{self.config['prefix']}mysql")
            if not mysql_ip:
                return {'status': 'error', 'message': 'MySQL容器IP地址未检测到'}
            
            mysql_result = await self.test_mysql_data_consistency(mysql_ip, test_data)
            if mysql_result['status'] != 'success':
                return mysql_result
            
            # 在Redis中存储数据
            redis_ip = self.container_ips.get(f"{self.config['prefix']}redis")
            if not redis_ip:
                return {'status': 'error', 'message': 'Redis容器IP地址未检测到'}
            
            redis_result = await self.test_redis_data_consistency(redis_ip, test_data)
            if redis_result['status'] != 'success':
                return redis_result
            
            # 验证数据一致性
            mysql_data = mysql_result.get('data', {})
            redis_data = redis_result.get('data', {})
            
            # 比较关键字段
            consistency_checks = {
                'user_id': mysql_data.get('user_id') == redis_data.get('user_id'),
                'transaction_id': mysql_data.get('transaction_id') == redis_data.get('transaction_id'),
                'amount': str(mysql_data.get('amount')) == str(redis_data.get('amount')),
                'currency': mysql_data.get('currency') == redis_data.get('currency'),
                'status': mysql_data.get('status') == redis_data.get('status')
            }
            
            all_consistent = all(consistency_checks.values())
            
            return {
                'status': 'success' if all_consistent else 'error',
                'message': f'{self.version.upper()}版跨数据库数据一致性测试{"成功" if all_consistent else "失败"}',
                'data': {
                    'consistency_checks': consistency_checks,
                    'mysql_data': mysql_data,
                    'redis_data': redis_data
                }
            }
        except Exception as e:
            return {
                'status': 'error',
                'message': f'{self.version.upper()}版跨数据库数据一致性测试失败: {e}'
            }
    
    async def run_data_consistency_tests(self) -> Dict[str, Any]:
        """运行数据一致性测试"""
        print(f"\n🧪 运行 {self.version.upper()}版数据一致性测试...")
        print("=" * 50)
        
        # 生成测试数据
        test_data = self.generate_test_data()
        print(f"📊 测试数据: {test_data['user_id']} - {test_data['transaction_id']}")
        
        results = {}
        
        # MySQL数据一致性测试
        mysql_ip = self.container_ips.get(f"{self.config['prefix']}mysql")
        if mysql_ip:
            print(f"🔍 测试MySQL数据一致性: {mysql_ip}")
            results['mysql'] = await self.test_mysql_data_consistency(mysql_ip, test_data)
        else:
            results['mysql'] = {'status': 'error', 'message': 'MySQL容器IP地址未检测到'}
        
        # PostgreSQL数据一致性测试
        postgres_ip = self.container_ips.get(f"{self.config['prefix']}postgres")
        if postgres_ip:
            print(f"🔍 测试PostgreSQL数据一致性: {postgres_ip}")
            results['postgres'] = await self.test_postgres_data_consistency(postgres_ip, test_data)
        else:
            results['postgres'] = {'status': 'error', 'message': 'PostgreSQL容器IP地址未检测到'}
        
        # Redis数据一致性测试
        redis_ip = self.container_ips.get(f"{self.config['prefix']}redis")
        if redis_ip:
            print(f"🔍 测试Redis数据一致性: {redis_ip}")
            results['redis'] = await self.test_redis_data_consistency(redis_ip, test_data)
        else:
            results['redis'] = {'status': 'error', 'message': 'Redis容器IP地址未检测到'}
        
        # Neo4j数据一致性测试
        neo4j_ip = self.container_ips.get(f"{self.config['prefix']}neo4j")
        if neo4j_ip:
            print(f"🔍 测试Neo4j数据一致性: {neo4j_ip}")
            results['neo4j'] = await self.test_neo4j_data_consistency(neo4j_ip, test_data)
        else:
            results['neo4j'] = {'status': 'error', 'message': 'Neo4j容器IP地址未检测到'}
        
        # 跨数据库数据一致性测试
        print(f"🔍 测试跨数据库数据一致性")
        results['cross_database'] = await self.test_cross_database_consistency(test_data)
        
        self.consistency_results = results
        return results
    
    def generate_comprehensive_report(self) -> Dict[str, Any]:
        """生成综合测试报告"""
        connectivity_success = sum(1 for result in self.connectivity_results.values() if result.get('status') == 'success')
        connectivity_total = len(self.connectivity_results)
        connectivity_rate = (connectivity_success / connectivity_total * 100) if connectivity_total > 0 else 0
        
        consistency_success = sum(1 for result in self.consistency_results.values() if result.get('status') == 'success')
        consistency_total = len(self.consistency_results)
        consistency_rate = (consistency_success / consistency_total * 100) if consistency_total > 0 else 0
        
        port_success = sum(1 for result in self.port_checks.values() if result)
        port_total = len(self.port_checks)
        port_rate = (port_success / port_total * 100) if port_total > 0 else 0
        
        report = {
            'test_time': datetime.now().isoformat(),
            'version': self.version,
            'test_type': 'unified_dynamic_test',
            'container_ips': self.container_ips,
            'port_checks': self.port_checks,
            'connectivity_tests': {
                'total': connectivity_total,
                'success': connectivity_success,
                'error': connectivity_total - connectivity_success,
                'success_rate': f"{connectivity_rate:.1f}%",
                'results': self.connectivity_results
            },
            'consistency_tests': {
                'total': consistency_total,
                'success': consistency_success,
                'error': consistency_total - consistency_success,
                'success_rate': f"{consistency_rate:.1f}%",
                'results': self.consistency_results
            },
            'port_checks': {
                'total': port_total,
                'success': port_success,
                'error': port_total - port_success,
                'success_rate': f"{port_rate:.1f}%",
                'results': self.port_checks
            },
            'overall_summary': {
                'connectivity_success': connectivity_success == connectivity_total,
                'consistency_success': consistency_success == consistency_total,
                'port_success': port_success == port_total,
                'overall_success': (connectivity_success == connectivity_total and 
                                  consistency_success == consistency_total and 
                                  port_success == port_total)
            }
        }
        
        return report
    
    def save_report(self, report: Dict[str, Any], filename: str = None):
        """保存测试报告"""
        if filename is None:
            filename = f"{self.version}_unified_dynamic_test_report.json"
        
        # 处理Decimal类型
        class CustomJsonEncoder(json.JSONEncoder):
            def default(self, obj):
                if isinstance(obj, Decimal):
                    return str(obj)
                return json.JSONEncoder.default(self, obj)
        
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(report, f, indent=2, ensure_ascii=False, cls=CustomJsonEncoder)
        
        print(f"\n📄 综合测试报告已保存到: {filename}")
        return filename
    
    async def run_full_test_suite(self):
        """运行完整测试套件"""
        print(f"🚀 开始 {self.version.upper()}版统一动态测试套件...")
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
        
        # 4. 运行数据一致性测试
        consistency_results = await self.run_data_consistency_tests()
        
        # 5. 生成综合测试报告
        report = self.generate_comprehensive_report()
        
        # 6. 保存报告
        self.save_report(report)
        
        # 7. 显示结果摘要
        end_time = time.time()
        duration = end_time - start_time
        
        print(f"\n📊 {self.version.upper()}版统一动态测试套件结果统计:")
        print("=" * 60)
        print(f"🔌 端口检查: {report['port_checks']['success']}/{report['port_checks']['total']} ({report['port_checks']['success_rate']})")
        print(f"🔗 连接测试: {report['connectivity_tests']['success']}/{report['connectivity_tests']['total']} ({report['connectivity_tests']['success_rate']})")
        print(f"📊 数据一致性: {report['consistency_tests']['success']}/{report['consistency_tests']['total']} ({report['consistency_tests']['success_rate']})")
        print(f"⏱️  总耗时: {duration:.2f}秒")
        
        # 显示详细结果
        print(f"\n📋 详细结果:")
        print("🔌 端口检查:")
        for service, result in port_checks.items():
            status_icon = "✅" if result else "❌"
            print(f"  {status_icon} {service}")
        
        print("🔗 连接测试:")
        for service, result in connectivity_results.items():
            status_icon = "✅" if result.get('status') == 'success' else "❌"
            print(f"  {status_icon} {service}: {result.get('message', '未知状态')}")
        
        print("📊 数据一致性测试:")
        for service, result in consistency_results.items():
            status_icon = "✅" if result.get('status') == 'success' else "❌"
            print(f"  {status_icon} {service}: {result.get('message', '未知状态')}")
        
        # 显示整体结果
        overall_success = report['overall_summary']['overall_success']
        print(f"\n🎯 整体测试结果: {'✅ 全部通过' if overall_success else '❌ 存在问题'}")
        
        return overall_success

async def main():
    """主函数"""
    import sys
    
    if len(sys.argv) != 2:
        print("用法: python3 unified_dynamic_test_suite.py <future|dao|blockchain>")
        sys.exit(1)
    
    version = sys.argv[1].lower()
    if version not in ['future', 'dao', 'blockchain']:
        print("错误: 版本必须是 future、dao 或 blockchain")
        sys.exit(1)
    
    tester = UnifiedDynamicTestSuite(version)
    success = await tester.run_full_test_suite()
    
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    asyncio.run(main())
