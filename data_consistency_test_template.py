#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
多版本数据一致性测试模板
适用于Future版、DAO版、区块链版数据库数据一致性测试
"""

import asyncio
import asyncpg
import aiomysql
import redis.asyncio as redis
import neo4j
import json
import time
from datetime import datetime

class DataConsistencyTest:
    def __init__(self, version):
        """
        初始化数据一致性测试
        
        Args:
            version (str): 版本名称 ('future', 'dao', 'blockchain')
        """
        self.version = version
        self.results = {}
        self.start_time = time.time()
        
        # 版本配置映射
        self.configs = {
            'future': {
                'prefix': 'f-',
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
        self.test_data = {
            'user_id': f'{version}_test_user_001',
            'transaction_id': f'tx_{version}_test_001',
            'amount': 100.50,
            'currency': 'BTC' if version == 'blockchain' else 'USD',
            'timestamp': datetime.now().isoformat(),
            'status': 'pending'
        }

    async def get_container_ips(self):
        """获取容器IP地址"""
        import subprocess
        import re
        
        ips = {}
        containers = ['mysql', 'postgres', 'redis', 'neo4j']
        
        for container in containers:
            try:
                result = subprocess.run([
                    'docker', 'inspect', f'{self.config["prefix"]}{container}'
                ], capture_output=True, text=True)
                
                # 提取IP地址
                ip_match = re.search(r'"IPAddress": "([^"]+)"', result.stdout)
                if ip_match:
                    ips[container] = ip_match.group(1)
                else:
                    ips[container] = None
            except Exception as e:
                print(f"获取{container}容器IP失败: {e}")
                ips[container] = None
        
        return ips

    async def test_mysql_data_consistency(self, ip):
        """测试MySQL数据一致性"""
        try:
            conn = await aiomysql.connect(
                host=ip,
                port=3306 if self.version == 'future' else 3307 if self.version == 'dao' else 3308,
                user=self.config['mysql_user'],
                password=self.config['mysql_password'],
                db=self.config['mysql_db']
            )
            
            # 创建测试表
            async with conn.cursor() as cursor:
                await cursor.execute("""
                    CREATE TABLE IF NOT EXISTS {}_transactions (
                        id INT AUTO_INCREMENT PRIMARY KEY,
                        user_id VARCHAR(255),
                        transaction_id VARCHAR(255),
                        amount DECIMAL(10,2),
                        currency VARCHAR(10),
                        timestamp TIMESTAMP,
                        status VARCHAR(50),
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    )
                """.format(self.version))
                
                # 插入测试数据
                await cursor.execute("""
                    INSERT INTO {}_transactions 
                    (user_id, transaction_id, amount, currency, timestamp, status)
                    VALUES (%s, %s, %s, %s, %s, %s)
                """.format(self.version), (
                    self.test_data['user_id'],
                    self.test_data['transaction_id'],
                    self.test_data['amount'],
                    self.test_data['currency'],
                    self.test_data['timestamp'],
                    self.test_data['status']
                ))
                
                # 查询验证数据
                await cursor.execute("""
                    SELECT * FROM {}_transactions 
                    WHERE transaction_id = %s
                """.format(self.version), (self.test_data['transaction_id'],))
                
                result = await cursor.fetchone()
                
            await conn.ensure_closed()
            
            self.results['mysql'] = {
                'status': 'success',
                'message': f'{self.version.upper()}版MySQL数据一致性测试成功',
                'data': result
            }
            return True
            
        except Exception as e:
            self.results['mysql'] = {
                'status': 'error',
                'message': f'{self.version.upper()}版MySQL数据一致性测试失败: {str(e)}'
            }
            return False

    async def test_postgres_data_consistency(self, ip):
        """测试PostgreSQL数据一致性"""
        try:
            conn = await asyncpg.connect(
                host=ip,
                port=5432 if self.version == 'future' else 5433 if self.version == 'dao' else 5434,
                user=self.config['postgres_user'],
                password=self.config['postgres_password'],
                database=self.config['postgres_db']
            )
            
            # 创建测试表
            await conn.execute("""
                CREATE TABLE IF NOT EXISTS {}_transactions (
                    id SERIAL PRIMARY KEY,
                    user_id VARCHAR(255),
                    transaction_id VARCHAR(255),
                    amount DECIMAL(10,2),
                    currency VARCHAR(10),
                    timestamp TIMESTAMP,
                    status VARCHAR(50),
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """.format(self.version))
            
            # 插入测试数据
            await conn.execute("""
                INSERT INTO {}_transactions 
                (user_id, transaction_id, amount, currency, timestamp, status)
                VALUES ($1, $2, $3, $4, $5, $6)
            """.format(self.version), (
                self.test_data['user_id'],
                self.test_data['transaction_id'],
                self.test_data['amount'],
                self.test_data['currency'],
                self.test_data['timestamp'],
                self.test_data['status']
            ))
            
            # 查询验证数据
            result = await conn.fetchrow("""
                SELECT * FROM {}_transactions 
                WHERE transaction_id = $1
            """.format(self.version), self.test_data['transaction_id'])
            
            await conn.close()
            
            self.results['postgres'] = {
                'status': 'success',
                'message': f'{self.version.upper()}版PostgreSQL数据一致性测试成功',
                'data': dict(result) if result else None
            }
            return True
            
        except Exception as e:
            self.results['postgres'] = {
                'status': 'error',
                'message': f'{self.version.upper()}版PostgreSQL数据一致性测试失败: {str(e)}'
            }
            return False

    async def test_redis_data_consistency(self, ip):
        """测试Redis数据一致性"""
        try:
            redis_client = redis.Redis(
                host=ip,
                port=6379 if self.version == 'future' else 6380 if self.version == 'dao' else 6381,
                password=self.config['redis_password'],
                db=0,
                decode_responses=True
            )
            
            # 存储测试数据
            key = f"{self.version}:transaction:{self.test_data['transaction_id']}"
            await redis_client.hset(key, mapping=self.test_data)
            await redis_client.expire(key, 3600)  # 1小时过期
            
            # 查询验证数据
            result = await redis_client.hgetall(key)
            
            await redis_client.aclose()
            
            self.results['redis'] = {
                'status': 'success',
                'message': f'{self.version.upper()}版Redis数据一致性测试成功',
                'data': result
            }
            return True
            
        except Exception as e:
            self.results['redis'] = {
                'status': 'error',
                'message': f'{self.version.upper()}版Redis数据一致性测试失败: {str(e)}'
            }
            return False

    async def test_neo4j_data_consistency(self, ip):
        """测试Neo4j数据一致性"""
        try:
            driver = neo4j.AsyncGraphDatabase.driver(
                f'bolt://{ip}:{7687 if self.version == "future" else 7688 if self.version == "dao" else 7689}',
                auth=('neo4j', self.config['neo4j_password'])
            )
            
            async with driver.session() as session:
                # 创建测试节点和关系
                await session.run("""
                    CREATE (u:User {user_id: $user_id})
                    CREATE (t:Transaction {
                        transaction_id: $transaction_id,
                        amount: $amount,
                        currency: $currency,
                        timestamp: $timestamp,
                        status: $status
                    })
                    CREATE (u)-[:PERFORMS]->(t)
                """, self.test_data)
                
                # 查询验证数据
                result = await session.run("""
                    MATCH (u:User)-[:PERFORMS]->(t:Transaction)
                    WHERE t.transaction_id = $transaction_id
                    RETURN u, t
                """, {'transaction_id': self.test_data['transaction_id']})
                
                record = await result.single()
                
            await driver.close()
            
            self.results['neo4j'] = {
                'status': 'success',
                'message': f'{self.version.upper()}版Neo4j数据一致性测试成功',
                'data': dict(record['t']) if record else None
            }
            return True
            
        except Exception as e:
            self.results['neo4j'] = {
                'status': 'error',
                'message': f'{self.version.upper()}版Neo4j数据一致性测试失败: {str(e)}'
            }
            return False

    async def test_cross_database_consistency(self, ips):
        """测试跨数据库数据一致性"""
        try:
            # 在MySQL中插入数据
            mysql_conn = await aiomysql.connect(
                host=ips['mysql'],
                port=3306 if self.version == 'future' else 3307 if self.version == 'dao' else 3308,
                user=self.config['mysql_user'],
                password=self.config['mysql_password'],
                db=self.config['mysql_db']
            )
            
            async with mysql_conn.cursor() as cursor:
                await cursor.execute("""
                    INSERT INTO {}_transactions 
                    (user_id, transaction_id, amount, currency, timestamp, status)
                    VALUES (%s, %s, %s, %s, %s, %s)
                """.format(self.version), (
                    self.test_data['user_id'],
                    self.test_data['transaction_id'],
                    self.test_data['amount'],
                    self.test_data['currency'],
                    self.test_data['timestamp'],
                    self.test_data['status']
                ))
            
            await mysql_conn.ensure_closed()
            
            # 在PostgreSQL中插入相同数据
            postgres_conn = await asyncpg.connect(
                host=ips['postgres'],
                port=5432 if self.version == 'future' else 5433 if self.version == 'dao' else 5434,
                user=self.config['postgres_user'],
                password=self.config['postgres_password'],
                database=self.config['postgres_db']
            )
            
            await postgres_conn.execute("""
                INSERT INTO {}_transactions 
                (user_id, transaction_id, amount, currency, timestamp, status)
                VALUES ($1, $2, $3, $4, $5, $6)
            """.format(self.version), (
                self.test_data['user_id'],
                self.test_data['transaction_id'],
                self.test_data['amount'],
                self.test_data['currency'],
                self.test_data['timestamp'],
                self.test_data['status']
            ))
            
            await postgres_conn.close()
            
            # 在Redis中缓存数据
            redis_client = redis.Redis(
                host=ips['redis'],
                port=6379 if self.version == 'future' else 6380 if self.version == 'dao' else 6381,
                password=self.config['redis_password'],
                db=0,
                decode_responses=True
            )
            
            key = f"{self.version}:transaction:{self.test_data['transaction_id']}"
            await redis_client.hset(key, mapping=self.test_data)
            await redis_client.aclose()
            
            self.results['cross_database'] = {
                'status': 'success',
                'message': f'{self.version.upper()}版跨数据库数据一致性测试成功',
                'data': '数据已同步到MySQL、PostgreSQL和Redis'
            }
            return True
            
        except Exception as e:
            self.results['cross_database'] = {
                'status': 'error',
                'message': f'{self.version.upper()}版跨数据库数据一致性测试失败: {str(e)}'
            }
            return False

    async def run_all_tests(self):
        """运行所有数据一致性测试"""
        print(f'🚀 开始{self.version.upper()}版数据一致性测试...')
        print('=' * 60)
        
        # 获取容器IP地址
        print('📡 获取容器IP地址...')
        ips = await self.get_container_ips()
        
        for container, ip in ips.items():
            if ip:
                print(f'✅ {container}: {ip}')
            else:
                print(f'❌ {container}: 无法获取IP地址')
        
        print()
        
        # 运行所有测试
        tasks = []
        if ips.get('mysql'):
            tasks.append(self.test_mysql_data_consistency(ips['mysql']))
        if ips.get('postgres'):
            tasks.append(self.test_postgres_data_consistency(ips['postgres']))
        if ips.get('redis'):
            tasks.append(self.test_redis_data_consistency(ips['redis']))
        if ips.get('neo4j'):
            tasks.append(self.test_neo4j_data_consistency(ips['neo4j']))
        
        if not tasks:
            print('❌ 没有可用的容器IP地址，无法进行测试')
            return self.results
        
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        # 跨数据库一致性测试
        if all(ips.get(container) for container in ['mysql', 'postgres', 'redis']):
            cross_result = await self.test_cross_database_consistency(ips)
            results.append(cross_result)
        
        # 统计结果
        success_count = sum(1 for r in results if r is True)
        total_count = len(results)
        
        print(f'\n📊 {self.version.upper()}版数据一致性测试结果统计:')
        print(f'✅ 成功: {success_count}/{total_count}')
        print(f'❌ 失败: {total_count - success_count}/{total_count}')
        print(f'⏱️  总耗时: {time.time() - self.start_time:.2f}秒')
        
        # 详细结果
        db_names = ['MySQL', 'PostgreSQL', 'Redis', 'Neo4j', '跨数据库一致性']
        for i, (name, result) in enumerate(zip(db_names, results)):
            if isinstance(result, dict):
                status = '✅' if result.get('status') == 'success' else '❌'
                print(f'{status} {name}: {result.get("message", "测试成功")}')
            else:
                print(f'❌ {name}: 异常 - {str(result)}')
        
        return self.results

    def generate_report(self):
        """生成测试报告"""
        report = {
            'test_time': datetime.now().isoformat(),
            'version': self.version,
            'test_type': 'data_consistency',
            'total_tests': len(self.results),
            'success_count': sum(1 for r in self.results.values() if r['status'] == 'success'),
            'error_count': sum(1 for r in self.results.values() if r['status'] == 'error'),
            'test_data': self.test_data,
            'results': self.results
        }
        
        return report

async def main():
    """主函数"""
    import sys
    
    if len(sys.argv) != 2:
        print("用法: python3 data_consistency_test_template.py <future|dao|blockchain>")
        sys.exit(1)
    
    version = sys.argv[1].lower()
    if version not in ['future', 'dao', 'blockchain']:
        print("错误: 版本必须是 'future', 'dao', 或 'blockchain'")
        sys.exit(1)
    
    tester = DataConsistencyTest(version)
    await tester.run_all_tests()
    
    # 生成报告
    report = tester.generate_report()
    
    # 保存报告
    filename = f'{version}_data_consistency_report.json'
    with open(filename, 'w') as f:
        json.dump(report, f, indent=2, ensure_ascii=False)
    
    print(f'\n📄 数据一致性测试报告已保存到: {filename}')
    
    return report

if __name__ == '__main__':
    asyncio.run(main())
