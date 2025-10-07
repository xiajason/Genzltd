#!/usr/bin/env python3
"""
数据库连接修复脚本
修复Weaviate和PostgreSQL连接问题
"""

import asyncio
import sys
import os
from typing import Dict, Any, Optional

# 添加项目根目录到Python路径
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import redis
import neo4j
import asyncpg
import weaviate
import elasticsearch
from datetime import datetime

class DatabaseConnectionFixer:
    """数据库连接修复器"""
    
    def __init__(self):
        self.connection_configs = {
            'redis': {
                'host': 'localhost',
                'port': 6379,
                'db': 0,
                'decode_responses': True
            },
            'neo4j': {
                'uri': 'bolt://localhost:7687',
                'username': 'neo4j',
                'password': 'jobfirst_password_2024'
            },
            'postgres': {
                'host': 'localhost',
                'port': 5432,
                'user': 'postgres',
                'password': 'jobfirst_password_2024',
                'database': 'looma_crm'
            },
            'weaviate': {
                'url': 'http://localhost:8091'
            },
            'elasticsearch': {
                'hosts': ['http://localhost:9200']
            }
        }
        self.connection_status = {}
    
    async def test_redis_connection(self) -> bool:
        """测试Redis连接"""
        try:
            r = redis.Redis(**self.connection_configs['redis'])
            r.ping()
            self.connection_status['redis'] = 'connected'
            print("✅ Redis连接正常")
            return True
        except Exception as e:
            self.connection_status['redis'] = f'failed: {e}'
            print(f"❌ Redis连接失败: {e}")
            return False
    
    async def test_neo4j_connection(self) -> bool:
        """测试Neo4j连接"""
        try:
            driver = neo4j.AsyncGraphDatabase.driver(
                self.connection_configs['neo4j']['uri'],
                auth=(self.connection_configs['neo4j']['username'], 
                      self.connection_configs['neo4j']['password'])
            )
            # 测试连接
            async with driver.session() as session:
                result = await session.run("RETURN 1 as test")
                await result.consume()
            
            await driver.close()
            self.connection_status['neo4j'] = 'connected'
            print("✅ Neo4j连接正常")
            return True
        except Exception as e:
            self.connection_status['neo4j'] = f'failed: {e}'
            print(f"❌ Neo4j连接失败: {e}")
            return False
    
    async def test_postgres_connection(self) -> bool:
        """测试PostgreSQL连接"""
        try:
            # 首先尝试连接默认数据库
            config = self.connection_configs['postgres'].copy()
            config['database'] = 'postgres'  # 连接到默认数据库
            
            conn = await asyncpg.connect(**config)
            await conn.close()
            
            # 然后尝试连接目标数据库
            config['database'] = 'looma_crm'
            try:
                conn = await asyncpg.connect(**config)
                await conn.close()
                self.connection_status['postgres'] = 'connected'
                print("✅ PostgreSQL连接正常")
                return True
            except Exception as e:
                if "database \"looma_crm\" does not exist" in str(e):
                    print("⚠️  PostgreSQL数据库looma_crm不存在，尝试创建...")
                    return await self.create_postgres_database()
                else:
                    raise e
                    
        except Exception as e:
            self.connection_status['postgres'] = f'failed: {e}'
            print(f"❌ PostgreSQL连接失败: {e}")
            return False
    
    async def create_postgres_database(self) -> bool:
        """创建PostgreSQL数据库"""
        try:
            # 连接到默认数据库
            config = self.connection_configs['postgres'].copy()
            config['database'] = 'postgres'
            
            conn = await asyncpg.connect(**config)
            
            # 创建数据库
            await conn.execute('CREATE DATABASE looma_crm')
            await conn.close()
            
            # 测试新创建的数据库
            config['database'] = 'looma_crm'
            conn = await asyncpg.connect(**config)
            await conn.close()
            
            self.connection_status['postgres'] = 'connected (created)'
            print("✅ PostgreSQL数据库looma_crm创建成功")
            return True
            
        except Exception as e:
            self.connection_status['postgres'] = f'failed: {e}'
            print(f"❌ 创建PostgreSQL数据库失败: {e}")
            return False
    
    async def test_weaviate_connection(self) -> bool:
        """测试Weaviate连接"""
        try:
            client = weaviate.Client(
                url=self.connection_configs['weaviate']['url'],
                startup_period=10  # 增加启动等待时间
            )
            
            # 测试连接
            client.schema.get()
            
            self.connection_status['weaviate'] = 'connected'
            print("✅ Weaviate连接正常")
            return True
        except Exception as e:
            self.connection_status['weaviate'] = f'failed: {e}'
            print(f"❌ Weaviate连接失败: {e}")
            print("💡 建议: 启动Weaviate服务或检查端口8080是否可用")
            return False
    
    async def test_elasticsearch_connection(self) -> bool:
        """测试Elasticsearch连接"""
        try:
            es = elasticsearch.Elasticsearch(**self.connection_configs['elasticsearch'])
            es.ping()
            
            self.connection_status['elasticsearch'] = 'connected'
            print("✅ Elasticsearch连接正常")
            return True
        except Exception as e:
            self.connection_status['elasticsearch'] = f'failed: {e}'
            print(f"❌ Elasticsearch连接失败: {e}")
            return False
    
    async def test_all_connections(self) -> Dict[str, bool]:
        """测试所有数据库连接"""
        print("🔍 开始测试数据库连接...")
        
        results = {
            'redis': await self.test_redis_connection(),
            'neo4j': await self.test_neo4j_connection(),
            'postgres': await self.test_postgres_connection(),
            'weaviate': await self.test_weaviate_connection(),
            'elasticsearch': await self.test_elasticsearch_connection()
        }
        
        return results
    
    def generate_connection_report(self) -> Dict[str, Any]:
        """生成连接报告"""
        report = {
            'test_time': datetime.now().isoformat(),
            'connection_status': self.connection_status,
            'summary': {
                'total_databases': len(self.connection_status),
                'connected': sum(1 for status in self.connection_status.values() 
                               if status == 'connected' or 'created' in status),
                'failed': sum(1 for status in self.connection_status.values() 
                            if 'failed' in status)
            },
            'recommendations': []
        }
        
        # 生成建议
        if 'failed' in self.connection_status.get('weaviate', ''):
            report['recommendations'].append({
                'database': 'weaviate',
                'action': '启动Weaviate服务',
                'command': 'docker run -p 8080:8080 semitechnologies/weaviate:latest'
            })
        
        if 'failed' in self.connection_status.get('postgres', ''):
            report['recommendations'].append({
                'database': 'postgres',
                'action': '检查PostgreSQL服务状态',
                'command': 'sudo systemctl status postgresql'
            })
        
        if 'failed' in self.connection_status.get('elasticsearch', ''):
            report['recommendations'].append({
                'database': 'elasticsearch',
                'action': '启动Elasticsearch服务',
                'command': 'docker run -p 9200:9200 elasticsearch:7.17.0'
            })
        
        return report

async def main():
    """主函数"""
    print("🚀 开始数据库连接修复...")
    
    fixer = DatabaseConnectionFixer()
    
    # 测试所有连接
    results = await fixer.test_all_connections()
    
    # 生成报告
    report = fixer.generate_connection_report()
    
    print("\n📊 连接测试结果:")
    for db, status in fixer.connection_status.items():
        status_icon = "✅" if "connected" in status else "❌"
        print(f"  {status_icon} {db}: {status}")
    
    print(f"\n📈 总结:")
    print(f"  总数据库数: {report['summary']['total_databases']}")
    print(f"  连接成功: {report['summary']['connected']}")
    print(f"  连接失败: {report['summary']['failed']}")
    
    if report['recommendations']:
        print(f"\n💡 修复建议:")
        for rec in report['recommendations']:
            print(f"  - {rec['database']}: {rec['action']}")
            print(f"    命令: {rec['command']}")
    
    # 保存报告
    import json
    report_path = "docs/database_connection_fix_report.json"
    os.makedirs(os.path.dirname(report_path), exist_ok=True)
    
    with open(report_path, "w", encoding="utf-8") as f:
        json.dump(report, f, indent=2, ensure_ascii=False)
    
    print(f"\n📝 详细报告已保存到: {report_path}")
    
    if report['summary']['failed'] == 0:
        print("\n🎉 所有数据库连接正常！")
    else:
        print(f"\n⚠️  有 {report['summary']['failed']} 个数据库连接需要修复")

if __name__ == "__main__":
    asyncio.run(main())
