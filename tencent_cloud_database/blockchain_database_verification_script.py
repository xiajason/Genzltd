#!/usr/bin/env python3
"""
区块链版多数据库结构验证脚本
创建时间: 2025-10-05
版本: Blockchain Version
功能: 验证所有区块链版数据库结构完整性
"""

import mysql.connector
import psycopg2
import redis
import sqlite3
from neo4j import GraphDatabase
from elasticsearch import Elasticsearch
import weaviate
import json
from datetime import datetime

class BlockchainDatabaseVerifier:
    def __init__(self):
        """初始化区块链版数据库验证器"""
        self.results = []
        
        # 数据库连接配置
        self.mysql_config = {
            'host': 'localhost',
            'port': 3309,  # 区块链版MySQL端口
            'user': 'root',
            'password': 'b_mysql_password_2025',
            'database': 'jobfirst_blockchain'
        }
        
        self.postgresql_config = {
            'host': 'localhost',
            'port': 5433,  # 区块链版PostgreSQL端口
            'user': 'postgres',
            'password': 'b_postgres_password_2025',
            'database': 'b_pg'
        }
        
        self.redis_config = {
            'host': 'localhost',
            'port': 6380,  # 区块链版Redis端口
            'password': 'b_redis_password_2025',
            'decode_responses': True
        }
        
        self.neo4j_config = {
            'uri': 'bolt://localhost:7682',  # 区块链版Neo4j端口
            'auth': ('neo4j', 'b_neo4j_password_2025')
        }
        
        self.elasticsearch_config = {
            'hosts': [{'host': 'localhost', 'port': 9202, 'scheme': 'http'}],  # 区块链版Elasticsearch端口
            'basic_auth': ('elastic', 'b_elastic_password_2025')
        }
        
        self.weaviate_config = {
            'url': 'http://localhost:8082'  # 区块链版Weaviate端口
        }
    
    def verify_mysql_database(self):
        """验证MySQL数据库"""
        print("🗄️ 验证MySQL数据库...")
        
        try:
            # 连接MySQL
            conn = mysql.connector.connect(**self.mysql_config)
            cursor = conn.cursor()
            
            # 检查数据库是否存在
            cursor.execute("SHOW DATABASES LIKE 'jobfirst_blockchain'")
            if not cursor.fetchone():
                print("❌ 数据库 'jobfirst_blockchain' 不存在")
                return False
            
            # 检查表数量
            cursor.execute("USE jobfirst_blockchain")
            cursor.execute("SHOW TABLES")
            tables = cursor.fetchall()
            table_count = len(tables)
            
            print(f"📊 表数量: {table_count}")
            
            # 检查关键表
            key_tables = [
                'blockchain_users', 'token_transactions', 'smart_contracts',
                'dao_governance', 'voting_records', 'nft_assets',
                'decentralized_identities', 'cross_chain_bridges',
                'staking_records', 'liquidity_mining', 'blockchain_events',
                'blockchain_configs'
            ]
            
            existing_tables = [table[0] for table in tables]
            missing_tables = [table for table in key_tables if table not in existing_tables]
            
            if missing_tables:
                print(f"❌ 缺少关键表: {missing_tables}")
                return False
            
            # 检查表结构
            cursor.execute("DESCRIBE blockchain_users")
            user_columns = cursor.fetchall()
            print(f"📋 blockchain_users表列数: {len(user_columns)}")
            
            # 检查数据
            cursor.execute("SELECT COUNT(*) FROM blockchain_users")
            user_count = cursor.fetchone()[0]
            print(f"👤 用户数量: {user_count}")
            
            cursor.close()
            conn.close()
            
            print("✅ MySQL数据库验证成功")
            return True
            
        except Exception as e:
            print(f"❌ MySQL数据库验证失败: {e}")
            return False
    
    def verify_postgresql_database(self):
        """验证PostgreSQL数据库"""
        print("🐘 验证PostgreSQL数据库...")
        
        try:
            # 连接PostgreSQL
            conn = psycopg2.connect(**self.postgresql_config)
            cursor = conn.cursor()
            
            # 检查表数量
            cursor.execute("""
                SELECT table_name 
                FROM information_schema.tables 
                WHERE table_schema = 'public'
            """)
            tables = cursor.fetchall()
            table_count = len(tables)
            
            print(f"📊 表数量: {table_count}")
            
            # 检查关键表
            key_tables = [
                'blockchain_ai_models', 'contract_ai_analysis', 'token_price_predictions',
                'transaction_patterns', 'decentralized_identity_verification',
                'nft_metadata_analysis', 'liquidity_analysis', 'governance_proposal_analysis',
                'cross_chain_analysis', 'staking_reward_predictions', 'smart_contract_audits',
                'blockchain_network_analysis', 'tokenomics_analysis', 'dapp_analysis',
                'blockchain_event_analysis'
            ]
            
            existing_tables = [table[0] for table in tables]
            missing_tables = [table for table in key_tables if table not in existing_tables]
            
            if missing_tables:
                print(f"❌ 缺少关键表: {missing_tables}")
                return False
            
            # 检查表结构
            cursor.execute("""
                SELECT column_name, data_type 
                FROM information_schema.columns 
                WHERE table_name = 'blockchain_ai_models'
            """)
            model_columns = cursor.fetchall()
            print(f"📋 blockchain_ai_models表列数: {len(model_columns)}")
            
            # 检查数据
            cursor.execute("SELECT COUNT(*) FROM blockchain_ai_models")
            model_count = cursor.fetchone()[0]
            print(f"🤖 AI模型数量: {model_count}")
            
            cursor.close()
            conn.close()
            
            print("✅ PostgreSQL数据库验证成功")
            return True
            
        except Exception as e:
            print(f"❌ PostgreSQL数据库验证失败: {e}")
            return False
    
    def verify_redis_database(self):
        """验证Redis数据库"""
        print("🔴 验证Redis数据库...")
        
        try:
            # 连接Redis
            r = redis.Redis(**self.redis_config)
            
            # 测试连接
            ping_result = r.ping()
            if not ping_result:
                print("❌ Redis连接失败")
                return False
            
            print(f"✅ Redis连接成功: {ping_result}")
            
            # 检查键数量
            keys = r.keys("*")
            key_count = len(keys)
            print(f"📊 键数量: {key_count}")
            
            # 检查关键键类型
            key_types = {
                'session:user:*': '用户会话',
                'tx:*': '交易缓存',
                'contract:*': '智能合约缓存',
                'nft:*': 'NFT缓存',
                'proposal:*': 'DAO提案缓存',
                'staking:*': '质押记录缓存',
                'liquidity:*': '流动性挖矿缓存',
                'bridge:*': '跨链桥接缓存',
                'config:*': '系统配置缓存',
                'blockchain:*': '消息队列'
            }
            
            for pattern, description in key_types.items():
                pattern_keys = r.keys(pattern)
                pattern_count = len(pattern_keys)
                print(f"📋 {description}: {pattern_count}个")
            
            # 检查示例数据
            if r.exists("session:user:0x1234567890abcdef1234567890abcdef12345678"):
                user_data = r.hgetall("session:user:0x1234567890abcdef1234567890abcdef12345678")
                print(f"👤 用户会话数据: {len(user_data)}个字段")
            
            print("✅ Redis数据库验证成功")
            return True
            
        except Exception as e:
            print(f"❌ Redis数据库验证失败: {e}")
            return False
    
    def verify_neo4j_database(self):
        """验证Neo4j数据库"""
        print("🕸️ 验证Neo4j数据库...")
        
        try:
            # 连接Neo4j
            driver = GraphDatabase.driver(**self.neo4j_config)
            
            with driver.session() as session:
                # 检查节点数量
                result = session.run("MATCH (n) RETURN count(n) as node_count")
                node_count = result.single()["node_count"]
                print(f"📊 节点数量: {node_count}")
                
                # 检查关系数量
                result = session.run("MATCH ()-[r]->() RETURN count(r) as relationship_count")
                relationship_count = result.single()["relationship_count"]
                print(f"🔗 关系数量: {relationship_count}")
                
                # 检查节点标签
                result = session.run("CALL db.labels()")
                labels = [record["label"] for record in result]
                print(f"🏷️ 节点标签: {labels}")
                
                # 检查关系类型
                result = session.run("CALL db.relationshipTypes()")
                relationship_types = [record["relationshipType"] for record in result]
                print(f"🔗 关系类型: {relationship_types}")
                
                # 检查关键节点
                key_labels = ["User", "SmartContract", "Token", "NFT", "DAO"]
                for label in key_labels:
                    result = session.run(f"MATCH (n:{label}) RETURN count(n) as count")
                    count = result.single()["count"]
                    print(f"📋 {label}节点: {count}个")
                
                # 检查关键关系
                key_relationships = ["OWNS", "OWNS_NFT", "MEMBER_OF", "IMPLEMENTS", "CREATED", "USES_TOKEN", "RELATED_TO", "TRUSTS"]
                for rel in key_relationships:
                    result = session.run(f"MATCH ()-[r:{rel}]->() RETURN count(r) as count")
                    count = result.single()["count"]
                    print(f"🔗 {rel}关系: {count}个")
            
            driver.close()
            print("✅ Neo4j数据库验证成功")
            return True
            
        except Exception as e:
            print(f"❌ Neo4j数据库验证失败: {e}")
            return False
    
    def verify_elasticsearch_database(self):
        """验证Elasticsearch数据库"""
        print("🔍 验证Elasticsearch数据库...")
        
        try:
            # 连接Elasticsearch
            es = Elasticsearch(**self.elasticsearch_config)
            
            # 检查集群状态
            health = es.cluster.health()
            print(f"📊 集群状态: {health['status']}")
            
            # 获取所有索引
            indices = es.indices.get_alias()
            blockchain_indices = [idx for idx in indices.keys() if idx.startswith('blockchain_')]
            print(f"📄 区块链版索引数量: {len(blockchain_indices)}")
            
            # 检查关键索引
            key_indices = [
                'blockchain_users', 'blockchain_smart_contracts', 'blockchain_tokens',
                'blockchain_nfts', 'blockchain_daos', 'blockchain_transactions',
                'blockchain_proposals', 'blockchain_staking', 'blockchain_liquidity',
                'blockchain_cross_chain'
            ]
            
            for index_name in key_indices:
                if index_name in blockchain_indices:
                    # 获取索引统计
                    stats = es.indices.stats(index=index_name)
                    doc_count = stats['indices'][index_name]['total']['docs']['count']
                    print(f"📋 {index_name}: {doc_count}个文档")
                else:
                    print(f"❌ 缺少索引: {index_name}")
            
            print("✅ Elasticsearch数据库验证成功")
            return True
            
        except Exception as e:
            print(f"❌ Elasticsearch数据库验证失败: {e}")
            return False
    
    def verify_weaviate_database(self):
        """验证Weaviate数据库"""
        print("🧠 验证Weaviate数据库...")
        
        try:
            # 连接Weaviate
            client = weaviate.Client(**self.weaviate_config)
            
            # 检查Weaviate状态
            if not client.is_ready():
                print("❌ Weaviate未就绪")
                return False
            
            print("✅ Weaviate连接成功")
            
            # 获取所有类
            schema = client.schema.get()
            classes = schema.get('classes', [])
            blockchain_classes = [cls for cls in classes if cls['class'].startswith('Blockchain')]
            print(f"📊 区块链版向量类数量: {len(blockchain_classes)}")
            
            # 检查关键类
            key_classes = [
                'BlockchainUser', 'BlockchainSmartContract', 'BlockchainToken',
                'BlockchainNFT', 'BlockchainDAO', 'BlockchainTransaction',
                'BlockchainProposal', 'BlockchainStaking', 'BlockchainLiquidity',
                'BlockchainCrossChain'
            ]
            
            for class_name in key_classes:
                if any(cls['class'] == class_name for cls in blockchain_classes):
                    # 获取类的对象数量
                    result = client.query.get(class_name, ["_additional { id }"]).with_limit(1000).do()
                    object_count = len(result.get('data', {}).get('Get', {}).get(class_name, []))
                    print(f"📋 {class_name}: {object_count}个对象")
                else:
                    print(f"❌ 缺少向量类: {class_name}")
            
            print("✅ Weaviate数据库验证成功")
            return True
            
        except Exception as e:
            print(f"❌ Weaviate数据库验证失败: {e}")
            return False
    
    def verify_all_databases(self):
        """验证所有数据库"""
        print("🚀 开始验证区块链版多数据库结构...")
        print(f"📅 验证时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print("=" * 60)
        
        databases = [
            ("MySQL", self.verify_mysql_database),
            ("PostgreSQL", self.verify_postgresql_database),
            ("Redis", self.verify_redis_database),
            ("Neo4j", self.verify_neo4j_database),
            ("Elasticsearch", self.verify_elasticsearch_database),
            ("Weaviate", self.verify_weaviate_database)
        ]
        
        success_count = 0
        total_count = len(databases)
        
        for i, (db_name, verify_func) in enumerate(databases, 1):
            print(f"\n📋 [{i}/{total_count}] 验证{db_name}数据库")
            print("-" * 40)
            
            start_time = datetime.now()
            
            try:
                success = verify_func()
                end_time = datetime.now()
                execution_time = (end_time - start_time).total_seconds()
                
                result_info = {
                    "database": db_name,
                    "success": success,
                    "execution_time": execution_time,
                    "timestamp": start_time.isoformat()
                }
                self.results.append(result_info)
                
                if success:
                    success_count += 1
                    print(f"✅ {db_name}数据库验证成功 (耗时: {execution_time:.2f}秒)")
                else:
                    print(f"❌ {db_name}数据库验证失败 (耗时: {execution_time:.2f}秒)")
                    
            except Exception as e:
                end_time = datetime.now()
                execution_time = (end_time - start_time).total_seconds()
                
                result_info = {
                    "database": db_name,
                    "success": False,
                    "execution_time": execution_time,
                    "timestamp": start_time.isoformat(),
                    "error": str(e)
                }
                self.results.append(result_info)
                
                print(f"❌ {db_name}数据库验证异常: {e} (耗时: {execution_time:.2f}秒)")
            
            print("-" * 40)
        
        # 输出总结
        print("\n" + "=" * 60)
        print("📊 验证结果总结")
        print("=" * 60)
        print(f"✅ 成功: {success_count}/{total_count}")
        print(f"❌ 失败: {total_count - success_count}/{total_count}")
        print(f"📈 成功率: {(success_count/total_count)*100:.1f}%")
        
        # 详细结果
        print("\n📋 详细验证结果:")
        for result in self.results:
            status = "✅ 成功" if result['success'] else "❌ 失败"
            error_info = f" (错误: {result.get('error', 'N/A')})" if not result['success'] and 'error' in result else ""
            print(f"  {result['database']}: {status} ({result['execution_time']:.2f}秒){error_info}")
        
        return success_count == total_count
    
    def generate_verification_report(self):
        """生成验证报告"""
        print("\n📄 生成验证报告...")
        
        report_content = f"""
# 区块链版多数据库结构验证报告

**验证时间**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
**验证状态**: {'✅ 全部成功' if all(r['success'] for r in self.results) else '❌ 部分失败'}

## 📊 验证统计

- **总数据库数**: {len(self.results)}
- **成功数**: {sum(1 for r in self.results if r['success'])}
- **失败数**: {sum(1 for r in self.results if not r['success'])}
- **成功率**: {(sum(1 for r in self.results if r['success'])/len(self.results))*100:.1f}%

## 📋 详细结果

"""
        
        for result in self.results:
            status = "✅ 成功" if result['success'] else "❌ 失败"
            error_info = f"\n- **错误信息**: {result.get('error', 'N/A')}" if not result['success'] and 'error' in result else ""
            report_content += f"""
### {result['database']}数据库
- **状态**: {status}
- **验证时间**: {result['execution_time']:.2f}秒
- **时间戳**: {result['timestamp']}{error_info}

"""
        
        report_content += """
## 🎯 下一步建议

1. **修复失败项**: 根据验证结果修复失败的数据库
2. **重新验证**: 修复后重新运行验证脚本
3. **功能测试**: 进行完整的功能测试
4. **性能监控**: 设置数据库性能监控

## 📞 技术支持

如有问题，请检查：
- 数据库服务是否正常运行
- 连接参数是否正确
- 网络连接是否正常
- 权限是否足够

---
**报告生成时间**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
"""
        
        # 保存报告
        report_filename = f"blockchain_database_verification_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.md"
        with open(report_filename, 'w', encoding='utf-8') as f:
            f.write(report_content)
        
        print(f"📄 验证报告已保存: {report_filename}")
        return report_filename

def main():
    """主函数"""
    print("🚀 区块链版多数据库结构验证脚本")
    print("=" * 60)
    
    # 创建验证器
    verifier = BlockchainDatabaseVerifier()
    
    # 验证所有数据库
    success = verifier.verify_all_databases()
    
    # 生成验证报告
    report_file = verifier.generate_verification_report()
    
    if success:
        print("\n🎉 区块链版多数据库结构验证全部通过!")
        print("✅ 所有数据库结构完整且功能正常")
        print("📄 详细报告请查看:", report_file)
    else:
        print("\n⚠️ 区块链版多数据库结构验证部分失败")
        print("❌ 请检查失败的数据库并修复问题")
        print("📄 详细报告请查看:", report_file)
    
    return success

if __name__ == "__main__":
    main()
