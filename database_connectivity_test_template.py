#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
多版本数据库连接测试模板
适用于Future版、DAO版、区块链版数据库测试
"""

import asyncio
import asyncpg
import aiomysql
import redis.asyncio as redis
import neo4j
import json
import time
from datetime import datetime

class DatabaseConnectivityTest:
    def __init__(self, version):
        """
        初始化数据库连接测试
        
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
                'mysql_port': 3308,
                'postgres_port': 5434,
                'redis_port': 6381,
                'neo4j_http_port': 7476,
                'neo4j_bolt_port': 7689,
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

    async def test_mysql_connection(self, ip):
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
                await cursor.execute('SELECT 1 as test')
                result = await cursor.fetchone()
            
            await conn.ensure_closed()
            
            self.results['mysql'] = {
                'status': 'success',
                'message': f'{self.version.upper()}版MySQL连接成功',
                'data': result
            }
            return True
            
        except Exception as e:
            self.results['mysql'] = {
                'status': 'error',
                'message': f'{self.version.upper()}版MySQL连接失败: {str(e)}'
            }
            return False

    async def test_postgres_connection(self, ip):
        """测试PostgreSQL连接"""
        try:
            conn = await asyncpg.connect(
                host=ip,
                port=self.config['postgres_port'],
                user=self.config['postgres_user'],
                password=self.config['postgres_password'],
                database=self.config['postgres_db']
            )
            
            result = await conn.fetchval('SELECT 1 as test')
            await conn.close()
            
            self.results['postgres'] = {
                'status': 'success',
                'message': f'{self.version.upper()}版PostgreSQL连接成功',
                'data': result
            }
            return True
            
        except Exception as e:
            self.results['postgres'] = {
                'status': 'error',
                'message': f'{self.version.upper()}版PostgreSQL连接失败: {str(e)}'
            }
            return False

    async def test_redis_connection(self, ip):
        """测试Redis连接"""
        try:
            redis_client = redis.Redis(
                host=ip,
                port=self.config['redis_port'],
                password=self.config['redis_password'],
                db=0,
                decode_responses=True
            )
            
            await redis_client.set('test_key', f'{self.version}_test_value')
            result = await redis_client.get('test_key')
            await redis_client.aclose()
            
            self.results['redis'] = {
                'status': 'success',
                'message': f'{self.version.upper()}版Redis连接成功',
                'data': result
            }
            return True
            
        except Exception as e:
            self.results['redis'] = {
                'status': 'error',
                'message': f'{self.version.upper()}版Redis连接失败: {str(e)}'
            }
            return False

    async def test_neo4j_connection(self, ip):
        """测试Neo4j连接"""
        try:
            driver = neo4j.AsyncGraphDatabase.driver(
                f'bolt://{ip}:{self.config["neo4j_bolt_port"]}',
                auth=('neo4j', self.config['neo4j_password'])
            )
            
            async with driver.session() as session:
                result = await session.run('RETURN 1 as test')
                record = await result.single()
            
            await driver.close()
            
            self.results['neo4j'] = {
                'status': 'success',
                'message': f'{self.version.upper()}版Neo4j连接成功',
                'data': dict(record) if record else None
            }
            return True
            
        except Exception as e:
            self.results['neo4j'] = {
                'status': 'error',
                'message': f'{self.version.upper()}版Neo4j连接失败: {str(e)}'
            }
            return False

    async def run_all_tests(self):
        """运行所有数据库连接测试"""
        print(f'🚀 开始{self.version.upper()}版多数据库连接测试...')
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
            tasks.append(self.test_mysql_connection(ips['mysql']))
        if ips.get('postgres'):
            tasks.append(self.test_postgres_connection(ips['postgres']))
        if ips.get('redis'):
            tasks.append(self.test_redis_connection(ips['redis']))
        if ips.get('neo4j'):
            tasks.append(self.test_neo4j_connection(ips['neo4j']))
        
        if not tasks:
            print('❌ 没有可用的容器IP地址，无法进行测试')
            return self.results
        
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        # 统计结果
        success_count = sum(1 for r in results if r is True)
        total_count = len(results)
        
        print(f'\n📊 {self.version.upper()}版测试结果统计:')
        print(f'✅ 成功: {success_count}/{total_count}')
        print(f'❌ 失败: {total_count - success_count}/{total_count}')
        print(f'⏱️  总耗时: {time.time() - self.start_time:.2f}秒')
        
        # 详细结果
        db_names = ['MySQL', 'PostgreSQL', 'Redis', 'Neo4j']
        for i, (name, result) in enumerate(zip(db_names, results)):
            if isinstance(result, dict):
                status = '✅' if result.get('status') == 'success' else '❌'
                print(f'{status} {name}: {result.get("message", "连接成功")}')
            else:
                print(f'❌ {name}: 异常 - {str(result)}')
        
        return self.results

    def generate_report(self):
        """生成测试报告"""
        report = {
            'test_time': datetime.now().isoformat(),
            'version': self.version,
            'total_databases': len(self.results),
            'success_count': sum(1 for r in self.results.values() if r['status'] == 'success'),
            'error_count': sum(1 for r in self.results.values() if r['status'] == 'error'),
            'results': self.results
        }
        
        return report

async def main():
    """主函数"""
    import sys
    
    if len(sys.argv) != 2:
        print("用法: python3 database_connectivity_test_template.py <future|dao|blockchain>")
        sys.exit(1)
    
    version = sys.argv[1].lower()
    if version not in ['future', 'dao', 'blockchain']:
        print("错误: 版本必须是 'future', 'dao', 或 'blockchain'")
        sys.exit(1)
    
    tester = DatabaseConnectivityTest(version)
    await tester.run_all_tests()
    
    # 生成报告
    report = tester.generate_report()
    
    # 保存报告
    filename = f'{version}_connectivity_test_report.json'
    with open(filename, 'w') as f:
        json.dump(report, f, indent=2, ensure_ascii=False)
    
    print(f'\n📄 测试报告已保存到: {filename}')
    
    return report

if __name__ == '__main__':
    asyncio.run(main())
