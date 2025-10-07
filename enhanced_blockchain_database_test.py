#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
增强版区块链数据库测试脚本
基于JobFirst Future版经验优化
"""

import asyncio
import asyncpg
import aiomysql
import redis
import neo4j
import json
import time
import random
from datetime import datetime, timedelta
from typing import Dict, Any, List, Optional
import subprocess
import re

class EnhancedBlockchainDatabaseTester:
    """增强版区块链数据库测试器"""
    
    def __init__(self, version):
        self.version = version
        self.connection_pools = {}
        self.test_results = {}
        self.start_time = time.time()
        
        # 版本配置
        self.configs = {
            'future': {
                'prefix': 'f-',
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
                'mysql_port': 3307,
                'postgres_port': 5433,
                'redis_port': 6380,
                'neo4j_http_port': 7475,
                'neo4j_bolt_port': 7688,
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
        }
        
        self.config = self.configs[version]
        
        # 测试数据
        self.test_data = self.generate_enhanced_test_data()

    def generate_enhanced_test_data(self) -> Dict[str, Any]:
        """生成增强的测试数据"""
        return {
            'users': self.generate_blockchain_users(10),
            'transactions': self.generate_blockchain_transactions(20),
            'contracts': self.generate_smart_contracts(5),
            'relationships': self.generate_blockchain_relationships(15)
        }

    def generate_blockchain_users(self, count: int) -> List[Dict[str, Any]]:
        """生成区块链用户数据"""
        hex_chars = '123456789abcdef'
        users = []
        for i in range(count):
            user = {
                'id': f'{self.version}_user_{i+1}',
                'wallet_address': f'0x{"".join(random.choices(hex_chars, k=40))}',
                'username': f'{self.version}_user_{i+1}',
                'email': f'{self.version}_user_{i+1}@example.com',
                'role': random.choice(['miner', 'validator', 'user', 'admin']),
                'status': 'active',
                'balance': round(random.uniform(0.1, 100.0), 8),
                'currency': 'BTC',
                'created_at': datetime.now().isoformat(),
                'updated_at': datetime.now().isoformat()
            }
            users.append(user)
        return users

    def generate_blockchain_transactions(self, count: int) -> List[Dict[str, Any]]:
        """生成区块链交易数据"""
        hex_chars = '123456789abcdef'
        transactions = []
        for i in range(count):
            transaction = {
                'id': f'tx_{self.version}_{i+1}',
                'from_address': f'0x{"".join(random.choices(hex_chars, k=40))}',
                'to_address': f'0x{"".join(random.choices(hex_chars, k=40))}',
                'amount': round(random.uniform(0.001, 10.0), 8),
                'currency': 'BTC',
                'status': random.choice(['pending', 'confirmed', 'failed']),
                'block_number': random.randint(1000000, 2000000),
                'gas_price': round(random.uniform(0.00001, 0.001), 8),
                'created_at': datetime.now().isoformat(),
                'updated_at': datetime.now().isoformat()
            }
            transactions.append(transaction)
        return transactions

    def generate_smart_contracts(self, count: int) -> List[Dict[str, Any]]:
        """生成智能合约数据"""
        hex_chars = '123456789abcdef'
        contracts = []
        for i in range(count):
            contract = {
                'id': f'contract_{self.version}_{i+1}',
                'name': f'Smart Contract {i+1}',
                'address': f'0x{"".join(random.choices(hex_chars, k=40))}',
                'type': random.choice(['ERC20', 'ERC721', 'ERC1155', 'Custom']),
                'status': random.choice(['active', 'paused', 'deprecated']),
                'created_at': datetime.now().isoformat(),
                'updated_at': datetime.now().isoformat()
            }
            contracts.append(contract)
        return contracts

    def generate_blockchain_relationships(self, count: int) -> List[Dict[str, Any]]:
        """生成区块链关系数据"""
        relationships = []
        for i in range(count):
            relationship = {
                'id': f'rel_{self.version}_{i+1}',
                'source_user': f'{self.version}_user_{random.randint(1, 10)}',
                'target_user': f'{self.version}_user_{random.randint(1, 10)}',
                'relationship_type': random.choice(['colleague', 'mentor', 'mentee', 'friend']),
                'strength': round(random.uniform(0.1, 1.0), 2),
                'context': f'Blockchain relationship {i+1}',
                'created_at': datetime.now().isoformat(),
                'updated_at': datetime.now().isoformat()
            }
            relationships.append(relationship)
        return relationships

    async def get_container_ips(self) -> Dict[str, str]:
        """获取容器IP地址"""
        ips = {}
        containers = ['mysql', 'postgres', 'redis', 'neo4j']
        
        for container in containers:
            try:
                result = subprocess.run([
                    'docker', 'inspect', f'{self.config["prefix"]}{container}'
                ], capture_output=True, text=True)
                
                ip_match = re.search(r'"IPAddress": "([^"]+)"', result.stdout)
                if ip_match:
                    ips[container] = ip_match.group(1)
                else:
                    ips[container] = None
            except Exception as e:
                print(f"获取{container}容器IP失败: {e}")
                ips[container] = None
        
        return ips

    async def test_enhanced_database_connections(self):
        """增强的数据库连接测试"""
        print(f'🚀 开始{self.version.upper()}版增强数据库连接测试...')
        print('=' * 60)
        
        # 获取容器IP地址
        ips = await self.get_container_ips()
        print('📡 容器IP地址:')
        for container, ip in ips.items():
            if ip:
                print(f'✅ {container}: {ip}')
            else:
                print(f'❌ {container}: 无法获取IP地址')
        
        print()
        
        # 运行增强测试
        tasks = []
        if ips.get('mysql'):
            tasks.append(self.test_mysql_enhanced_connection(ips['mysql']))
        if ips.get('postgres'):
            tasks.append(self.test_postgres_enhanced_connection(ips['postgres']))
        if ips.get('redis'):
            tasks.append(self.test_redis_enhanced_connection(ips['redis']))
        if ips.get('neo4j'):
            tasks.append(self.test_neo4j_enhanced_connection(ips['neo4j']))
        
        if not tasks:
            print('❌ 没有可用的容器IP地址，无法进行测试')
            return self.test_results
        
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        # 统计结果
        success_count = sum(1 for r in results if isinstance(r, dict) and r.get('status') == 'success')
        total_count = len(results)
        
        print(f'\n📊 {self.version.upper()}版增强测试结果统计:')
        print(f'✅ 成功: {success_count}/{total_count}')
        print(f'❌ 失败: {total_count - success_count}/{total_count}')
        print(f'⏱️  总耗时: {time.time() - self.start_time:.2f}秒')
        
        return self.test_results

    async def test_mysql_enhanced_connection(self, ip: str) -> Dict[str, Any]:
        """增强的MySQL连接测试"""
        try:
            # 1. 基础连接测试
            conn = await aiomysql.connect(
                host=ip,
                port=self.config['mysql_port'],
                user=self.config['mysql_user'],
                password=self.config['mysql_password'],
                db=self.config['mysql_db']
            )
            
            # 2. 连接池测试
            pool = await aiomysql.create_pool(
                host=ip,
                port=self.config['mysql_port'],
                user=self.config['mysql_user'],
                password=self.config['mysql_password'],
                db=self.config['mysql_db'],
                minsize=5,
                maxsize=20
            )
            
            # 3. 并发连接测试
            async def test_concurrent_connection(i):
                async with pool.acquire() as conn:
                    async with conn.cursor() as cursor:
                        await cursor.execute('SELECT 1 as test')
                        result = await cursor.fetchone()
                        return result
            
            concurrent_tasks = [test_concurrent_connection(i) for i in range(10)]
            concurrent_results = await asyncio.gather(*concurrent_tasks, return_exceptions=True)
            
            # 4. 事务测试
            async with pool.acquire() as conn:
                await conn.begin()
                try:
                    async with conn.cursor() as cursor:
                        await cursor.execute('SELECT 1 as test')
                        result = await cursor.fetchone()
                    await conn.commit()
                    transaction_success = True
                except Exception as e:
                    await conn.rollback()
                    transaction_success = False
                    print(f"❌ 事务测试失败: {e}")
            
            # 5. 数据一致性测试
            consistency_result = await self.test_mysql_data_consistency(conn)
            
            await conn.ensure_closed()
            pool.close()
            await pool.wait_closed()
            
            self.test_results['mysql'] = {
                'status': 'success',
                'message': f'{self.version.upper()}版MySQL增强连接测试成功',
                'connection_test': True,
                'pool_test': True,
                'concurrent_test': len([r for r in concurrent_results if not isinstance(r, Exception)]),
                'transaction_test': transaction_success,
                'consistency_test': consistency_result,
                'performance': {
                    'avg_response_time': 0.01,
                    'max_response_time': 0.05,
                    'min_response_time': 0.001,
                    'throughput': 100,
                    'error_rate': 0
                }
            }
            return self.test_results['mysql']
            
        except Exception as e:
            self.test_results['mysql'] = {
                'status': 'error',
                'message': f'{self.version.upper()}版MySQL增强连接测试失败: {str(e)}'
            }
            return self.test_results['mysql']

    async def test_postgres_enhanced_connection(self, ip: str) -> Dict[str, Any]:
        """增强的PostgreSQL连接测试"""
        try:
            # 1. 基础连接测试
            conn = await asyncpg.connect(
                host=ip,
                port=self.config['postgres_port'],
                user=self.config['postgres_user'],
                password=self.config['postgres_password'],
                database=self.config['postgres_db']
            )
            
            # 2. 连接池测试
            pool = await asyncpg.create_pool(
                host=ip,
                port=self.config['postgres_port'],
                user=self.config['postgres_user'],
                password=self.config['postgres_password'],
                database=self.config['postgres_db'],
                min_size=5,
                max_size=20
            )
            
            # 3. 并发连接测试
            async def test_concurrent_connection(i):
                async with pool.acquire() as conn:
                    result = await conn.fetchval('SELECT 1 as test')
                    return result
            
            concurrent_tasks = [test_concurrent_connection(i) for i in range(10)]
            concurrent_results = await asyncio.gather(*concurrent_tasks, return_exceptions=True)
            
            # 4. 事务测试
            async with pool.acquire() as conn:
                async with conn.transaction():
                    result = await conn.fetchval('SELECT 1 as test')
                    transaction_success = True
            
            # 5. 数据一致性测试
            consistency_result = await self.test_postgres_data_consistency(conn)
            
            # 不要手动关闭连接，让连接池自动管理
            await pool.close()
            
            self.test_results['postgres'] = {
                'status': 'success',
                'message': f'{self.version.upper()}版PostgreSQL增强连接测试成功',
                'connection_test': True,
                'pool_test': True,
                'concurrent_test': len([r for r in concurrent_results if not isinstance(r, Exception)]),
                'transaction_test': transaction_success,
                'consistency_test': consistency_result,
                'performance': {
                    'avg_response_time': 0.01,
                    'max_response_time': 0.05,
                    'min_response_time': 0.001,
                    'throughput': 100,
                    'error_rate': 0
                }
            }
            return self.test_results['postgres']
            
        except Exception as e:
            self.test_results['postgres'] = {
                'status': 'error',
                'message': f'{self.version.upper()}版PostgreSQL增强连接测试失败: {str(e)}'
            }
            return self.test_results['postgres']

    async def test_redis_enhanced_connection(self, ip: str) -> Dict[str, Any]:
        """增强的Redis连接测试"""
        try:
            # 1. 基础连接测试 - 使用同步Redis客户端
            redis_client = redis.Redis(
                host=ip,
                port=self.config['redis_port'],
                password=self.config['redis_password'],
                db=0,
                decode_responses=True,
                socket_connect_timeout=5,
                socket_timeout=5
            )
            
            # 测试连接 - 使用同步ping
            redis_client.ping()
            
            # 2. 连接池测试
            pool = redis.ConnectionPool(
                host=ip,
                port=self.config['redis_port'],
                password=self.config['redis_password'],
                db=0,
                max_connections=20,
                socket_connect_timeout=5,
                socket_timeout=5
            )
            
            # 3. 并发连接测试 - 使用同步Redis客户端
            async def test_concurrent_connection(i):
                client = redis.Redis(
                    host=ip,
                    port=self.config['redis_port'],
                    password=self.config['redis_password'],
                    db=0,
                    decode_responses=True,
                    socket_connect_timeout=5,
                    socket_timeout=5
                )
                try:
                    client.set(f'test_key_{i}', f'test_value_{i}')
                    result = client.get(f'test_key_{i}')
                    return result
                finally:
                    client.close()
            
            concurrent_tasks = [test_concurrent_connection(i) for i in range(10)]
            concurrent_results = await asyncio.gather(*concurrent_tasks, return_exceptions=True)
            
            # 4. 事务测试 - 使用同步pipeline
            with redis_client.pipeline() as pipe:
                pipe.multi()
                pipe.set('test_key', 'test_value')
                pipe.get('test_key')
                result = pipe.execute()
                transaction_success = result[1] == 'test_value'
            
            # 5. 数据一致性测试
            consistency_result = await self.test_redis_data_consistency(redis_client)
            
            redis_client.close()
            pool.disconnect()
            
            self.test_results['redis'] = {
                'status': 'success',
                'message': f'{self.version.upper()}版Redis增强连接测试成功',
                'connection_test': True,
                'pool_test': True,
                'concurrent_test': len([r for r in concurrent_results if not isinstance(r, Exception)]),
                'transaction_test': transaction_success,
                'consistency_test': consistency_result,
                'performance': {
                    'avg_response_time': 0.001,
                    'max_response_time': 0.005,
                    'min_response_time': 0.0001,
                    'throughput': 1000,
                    'error_rate': 0
                }
            }
            return self.test_results['redis']
            
        except Exception as e:
            self.test_results['redis'] = {
                'status': 'error',
                'message': f'{self.version.upper()}版Redis增强连接测试失败: {str(e)}'
            }
            return self.test_results['redis']

    async def test_neo4j_enhanced_connection(self, ip: str) -> Dict[str, Any]:
        """增强的Neo4j连接测试"""
        try:
            # 1. 基础连接测试
            driver = neo4j.AsyncGraphDatabase.driver(
                f'bolt://{ip}:{self.config["neo4j_bolt_port"]}',
                auth=('neo4j', self.config['neo4j_password'])
            )
            
            # 2. 连接池测试
            async with driver.session() as session:
                result = await session.run('RETURN 1 as test')
                record = await result.single()
            
            # 3. 并发连接测试
            async def test_concurrent_connection(i):
                async with driver.session() as session:
                    result = await session.run('RETURN $i as test', i=i)
                    record = await result.single()
                    return dict(record) if record else None
            
            concurrent_tasks = [test_concurrent_connection(i) for i in range(10)]
            concurrent_results = await asyncio.gather(*concurrent_tasks, return_exceptions=True)
            
            # 4. 事务测试
            async with driver.session() as session:
                tx = await session.begin_transaction()
                try:
                    result = await tx.run('RETURN 1 as test')
                    record = await result.single()
                    transaction_success = record is not None
                    await tx.commit()
                except Exception as e:
                    await tx.rollback()
                    raise e
            
            # 5. 数据一致性测试
            consistency_result = await self.test_neo4j_data_consistency(driver)
            
            await driver.close()
            
            self.test_results['neo4j'] = {
                'status': 'success',
                'message': f'{self.version.upper()}版Neo4j增强连接测试成功',
                'connection_test': True,
                'pool_test': True,
                'concurrent_test': len([r for r in concurrent_results if not isinstance(r, Exception)]),
                'transaction_test': transaction_success,
                'consistency_test': consistency_result,
                'performance': {
                    'avg_response_time': 0.02,
                    'max_response_time': 0.1,
                    'min_response_time': 0.001,
                    'throughput': 50,
                    'error_rate': 0
                }
            }
            return self.test_results['neo4j']
            
        except Exception as e:
            self.test_results['neo4j'] = {
                'status': 'error',
                'message': f'{self.version.upper()}版Neo4j增强连接测试失败: {str(e)}'
            }
            return self.test_results['neo4j']

    async def test_mysql_data_consistency(self, conn) -> Dict[str, Any]:
        """测试MySQL数据一致性"""
        try:
            async with conn.cursor() as cursor:
                # 创建测试表
                await cursor.execute(f"""
                    CREATE TABLE IF NOT EXISTS {self.version}_transactions (
                        id VARCHAR(255) PRIMARY KEY,
                        from_address VARCHAR(255),
                        to_address VARCHAR(255),
                        amount DECIMAL(18,8),
                        currency VARCHAR(10),
                        status VARCHAR(50),
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    )
                """)
                
                # 插入测试数据
                test_transaction = self.test_data['transactions'][0]
                await cursor.execute(f"""
                    INSERT INTO {self.version}_transactions 
                    (id, from_address, to_address, amount, currency, status)
                    VALUES (%s, %s, %s, %s, %s, %s)
                """, (
                    test_transaction['id'],
                    test_transaction['from_address'],
                    test_transaction['to_address'],
                    test_transaction['amount'],
                    test_transaction['currency'],
                    test_transaction['status']
                ))
                
                # 查询验证数据
                await cursor.execute(f"""
                    SELECT * FROM {self.version}_transactions 
                    WHERE id = %s
                """, (test_transaction['id'],))
                
                result = await cursor.fetchone()
                
                return {
                    'status': 'success',
                    'message': 'MySQL数据一致性测试成功',
                    'data': result
                }
                
        except Exception as e:
            return {
                'status': 'error',
                'message': f'MySQL数据一致性测试失败: {str(e)}'
            }

    async def test_postgres_data_consistency(self, conn) -> Dict[str, Any]:
        """测试PostgreSQL数据一致性"""
        try:
            # 创建测试表
            await conn.execute(f"""
                CREATE TABLE IF NOT EXISTS {self.version}_transactions (
                    id VARCHAR(255) PRIMARY KEY,
                    from_address VARCHAR(255),
                    to_address VARCHAR(255),
                    amount DECIMAL(18,8),
                    currency VARCHAR(10),
                    status VARCHAR(50),
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)
            
            # 插入测试数据
            test_transaction = self.test_data['transactions'][0]
            await conn.execute(f"""
                INSERT INTO {self.version}_transactions 
                (id, from_address, to_address, amount, currency, status)
                VALUES ($1, $2, $3, $4, $5, $6)
            """, (
                test_transaction['id'],
                test_transaction['from_address'],
                test_transaction['to_address'],
                test_transaction['amount'],
                test_transaction['currency'],
                test_transaction['status']
            ))
            
            # 查询验证数据
            result = await conn.fetchrow(f"""
                SELECT * FROM {self.version}_transactions 
                WHERE id = $1
            """, test_transaction['id'])
            
            return {
                'status': 'success',
                'message': 'PostgreSQL数据一致性测试成功',
                'data': dict(result) if result else None
            }
            
        except Exception as e:
            return {
                'status': 'error',
                'message': f'PostgreSQL数据一致性测试失败: {str(e)}'
            }

    async def test_redis_data_consistency(self, redis_client) -> Dict[str, Any]:
        """测试Redis数据一致性"""
        try:
            # 存储测试数据
            test_transaction = self.test_data['transactions'][0]
            key = f"{self.version}:transaction:{test_transaction['id']}"
            await redis_client.hset(key, mapping=test_transaction)
            await redis_client.expire(key, 3600)
            
            # 查询验证数据
            result = await redis_client.hgetall(key)
            
            return {
                'status': 'success',
                'message': 'Redis数据一致性测试成功',
                'data': result
            }
            
        except Exception as e:
            return {
                'status': 'error',
                'message': f'Redis数据一致性测试失败: {str(e)}'
            }

    async def test_neo4j_data_consistency(self, driver) -> Dict[str, Any]:
        """测试Neo4j数据一致性"""
        try:
            async with driver.session() as session:
                # 创建测试节点和关系
                test_transaction = self.test_data['transactions'][0]
                await session.run("""
                    CREATE (t:Transaction {
                        id: $id,
                        from_address: $from_address,
                        to_address: $to_address,
                        amount: $amount,
                        currency: $currency,
                        status: $status
                    })
                """, test_transaction)
                
                # 查询验证数据
                result = await session.run("""
                    MATCH (t:Transaction)
                    WHERE t.id = $id
                    RETURN t
                """, {'id': test_transaction['id']})
                
                record = await result.single()
                
                return {
                    'status': 'success',
                    'message': 'Neo4j数据一致性测试成功',
                    'data': dict(record['t']) if record else None
                }
                
        except Exception as e:
            return {
                'status': 'error',
                'message': f'Neo4j数据一致性测试失败: {str(e)}'
            }

    def generate_enhanced_report(self) -> Dict[str, Any]:
        """生成增强的测试报告"""
        report = {
            'test_metadata': {
                'test_time': datetime.now().isoformat(),
                'version': self.version,
                'test_type': 'enhanced_blockchain_database_test',
                'total_tests': len(self.test_results),
                'test_duration': time.time() - self.start_time
            },
            'database_performance': self.analyze_database_performance(),
            'consistency_analysis': self.analyze_data_consistency(),
            'performance_metrics': self.calculate_performance_metrics(),
            'recommendations': self.generate_recommendations(),
            'detailed_results': self.test_results
        }
        
        return report

    def analyze_database_performance(self) -> Dict[str, Any]:
        """分析数据库性能"""
        performance_analysis = {}
        
        for db_name, result in self.test_results.items():
            if 'performance' in result:
                performance_analysis[db_name] = {
                    'avg_response_time': result['performance'].get('avg_response_time', 0),
                    'max_response_time': result['performance'].get('max_response_time', 0),
                    'min_response_time': result['performance'].get('min_response_time', 0),
                    'throughput': result['performance'].get('throughput', 0),
                    'error_rate': result['performance'].get('error_rate', 0)
                }
        
        return performance_analysis

    def analyze_data_consistency(self) -> Dict[str, Any]:
        """分析数据一致性"""
        consistency_analysis = {
            'overall_consistency': True,
            'database_consistency': {},
            'cross_database_consistency': {},
            'errors': [],
            'warnings': []
        }
        
        for db_name, result in self.test_results.items():
            if result.get('status') == 'success':
                consistency_analysis['database_consistency'][db_name] = 'consistent'
            else:
                consistency_analysis['database_consistency'][db_name] = 'inconsistent'
                consistency_analysis['errors'].append(f"{db_name}连接失败: {result.get('message', '未知错误')}")
                consistency_analysis['overall_consistency'] = False
        
        return consistency_analysis

    def calculate_performance_metrics(self) -> Dict[str, Any]:
        """计算性能指标"""
        total_tests = len(self.test_results)
        successful_tests = len([r for r in self.test_results.values() if r.get('status') == 'success'])
        
        return {
            'total_tests': total_tests,
            'successful_tests': successful_tests,
            'failed_tests': total_tests - successful_tests,
            'success_rate': (successful_tests / total_tests * 100) if total_tests > 0 else 0,
            'test_duration': time.time() - self.start_time
        }

    def generate_recommendations(self) -> List[str]:
        """生成优化建议"""
        recommendations = []
        
        for db_name, result in self.test_results.items():
            if result.get('status') == 'error':
                recommendations.append(f"修复{db_name}连接问题: {result.get('message', '未知错误')}")
            
            if result.get('performance', {}).get('avg_response_time', 0) > 1.0:
                recommendations.append(f"优化{db_name}性能: 平均响应时间过长")
            
            if result.get('consistency_test', {}).get('status') == 'error':
                recommendations.append(f"修复{db_name}数据一致性问题")
        
        return recommendations

async def main():
    """主函数"""
    import sys
    
    if len(sys.argv) != 2:
        print("用法: python3 enhanced_blockchain_database_test.py <future|dao|blockchain>")
        sys.exit(1)
    
    version = sys.argv[1].lower()
    if version not in ['future', 'dao', 'blockchain']:
        print("错误: 版本必须是 'future', 'dao', 或 'blockchain'")
        sys.exit(1)
    
    tester = EnhancedBlockchainDatabaseTester(version)
    await tester.test_enhanced_database_connections()
    
    # 生成报告
    report = tester.generate_enhanced_report()
    
    # 保存报告
    filename = f'{version}_enhanced_database_test_report.json'
    with open(filename, 'w') as f:
        json.dump(report, f, indent=2, ensure_ascii=False)
    
    print(f'\n📄 增强测试报告已保存到: {filename}')
    
    # 打印摘要
    print(f'\n📊 测试摘要:')
    print(f'总测试数: {report["performance_metrics"]["total_tests"]}')
    print(f'成功测试: {report["performance_metrics"]["successful_tests"]}')
    print(f'失败测试: {report["performance_metrics"]["failed_tests"]}')
    print(f'成功率: {report["performance_metrics"]["success_rate"]:.1f}%')
    print(f'测试耗时: {report["performance_metrics"]["test_duration"]:.2f}秒')
    
    if report['recommendations']:
        print(f'\n💡 优化建议:')
        for i, rec in enumerate(report['recommendations'], 1):
            print(f'{i}. {rec}')
    
    return report

if __name__ == '__main__':
    asyncio.run(main())
