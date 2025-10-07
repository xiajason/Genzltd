#!/usr/bin/env python3
"""
区块链版 Neo4j 图数据库结构
创建时间: 2025-10-05
版本: Blockchain Version
功能: 关系网络、图数据库
"""

from neo4j import GraphDatabase
import json
from datetime import datetime

class BlockchainNeo4jManager:
    def __init__(self):
        """初始化区块链版Neo4j连接"""
        self.driver = GraphDatabase.driver(
            "bolt://localhost:7682",  # 区块链版Neo4j端口
            auth=("neo4j", "b_neo4j_password_2025")
        )
        
    def close(self):
        """关闭连接"""
        self.driver.close()
    
    def test_connection(self):
        """测试Neo4j连接"""
        try:
            with self.driver.session() as session:
                result = session.run("RETURN 1 as test")
                record = result.single()
                print(f"✅ Neo4j连接成功: {record['test']}")
                return True
        except Exception as e:
            print(f"❌ Neo4j连接失败: {e}")
            return False
    
    def setup_blockchain_graph_structure(self):
        """设置区块链版图数据库结构"""
        try:
            print("🚀 开始设置区块链版Neo4j图数据库结构...")
            
            # 1. 创建节点标签和索引
            self.create_node_labels_and_indexes()
            
            # 2. 创建用户节点
            self.create_user_nodes()
            
            # 3. 创建智能合约节点
            self.create_smart_contract_nodes()
            
            # 4. 创建代币节点
            self.create_token_nodes()
            
            # 5. 创建NFT节点
            self.create_nft_nodes()
            
            # 6. 创建DAO节点
            self.create_dao_nodes()
            
            # 7. 创建关系
            self.create_relationships()
            
            print("✅ 区块链版Neo4j图数据库结构设置完成!")
            return True
            
        except Exception as e:
            print(f"❌ 设置区块链版Neo4j图数据库结构失败: {e}")
            return False
    
    def create_node_labels_and_indexes(self):
        """创建节点标签和索引"""
        print("📋 创建节点标签和索引...")
        
        with self.driver.session() as session:
            # 创建节点标签
            labels = [
                "User", "SmartContract", "Token", "NFT", "DAO", "Proposal", 
                "Transaction", "StakingPool", "LiquidityPool", "Bridge"
            ]
            
            for label in labels:
                session.run(f"CREATE CONSTRAINT {label.lower()}_id_unique IF NOT EXISTS FOR (n:{label}) REQUIRE n.id IS UNIQUE")
                session.run(f"CREATE INDEX {label.lower()}_address_index IF NOT EXISTS FOR (n:{label}) ON (n.address)")
                session.run(f"CREATE INDEX {label.lower()}_created_at_index IF NOT EXISTS FOR (n:{label}) ON (n.created_at)")
            
            print(f"✅ 节点标签和索引创建完成: {len(labels)}个标签")
    
    def create_user_nodes(self):
        """创建用户节点"""
        print("👤 创建用户节点...")
        
        users = [
            {
                "id": "user_1",
                "address": "0x1234567890abcdef1234567890abcdef12345678",
                "username": "blockchain_user_1",
                "reputation_score": 85,
                "total_tokens": 10000.0,
                "staked_tokens": 5000.0,
                "voting_power": 100,
                "is_verified": True,
                "created_at": datetime.now().isoformat()
            },
            {
                "id": "user_2", 
                "address": "0xabcdef1234567890abcdef1234567890abcdef12",
                "username": "blockchain_user_2",
                "reputation_score": 72,
                "total_tokens": 8000.0,
                "staked_tokens": 3000.0,
                "voting_power": 80,
                "is_verified": True,
                "created_at": datetime.now().isoformat()
            },
            {
                "id": "user_3",
                "address": "0x9876543210fedcba9876543210fedcba98765432",
                "username": "blockchain_user_3",
                "reputation_score": 95,
                "total_tokens": 15000.0,
                "staked_tokens": 8000.0,
                "voting_power": 150,
                "is_verified": True,
                "created_at": datetime.now().isoformat()
            }
        ]
        
        with self.driver.session() as session:
            for user in users:
                session.run("""
                    CREATE (u:User {
                        id: $id,
                        address: $address,
                        username: $username,
                        reputation_score: $reputation_score,
                        total_tokens: $total_tokens,
                        staked_tokens: $staked_tokens,
                        voting_power: $voting_power,
                        is_verified: $is_verified,
                        created_at: $created_at
                    })
                """, **user)
        
        print(f"✅ 用户节点创建完成: {len(users)}个用户")
    
    def create_smart_contract_nodes(self):
        """创建智能合约节点"""
        print("📜 创建智能合约节点...")
        
        contracts = [
            {
                "id": "contract_1",
                "address": "0xcontract1234567890abcdef1234567890abcdef12",
                "name": "BFTToken",
                "type": "ERC20",
                "version": "1.0.0",
                "creator": "0x1234567890abcdef1234567890abcdef12345678",
                "total_supply": 1000000000.0,
                "is_verified": True,
                "created_at": datetime.now().isoformat()
            },
            {
                "id": "contract_2",
                "address": "0xcontractabcdef1234567890abcdef1234567890ab",
                "name": "BFTGovernance",
                "type": "Governance",
                "version": "2.1.0",
                "creator": "0xabcdef1234567890abcdef1234567890abcdef12",
                "total_supply": None,
                "is_verified": True,
                "created_at": datetime.now().isoformat()
            },
            {
                "id": "contract_3",
                "address": "0xcontract5678901234cdef5678901234cdef5678",
                "name": "BFTNFT",
                "type": "ERC721",
                "version": "1.5.0",
                "creator": "0x9876543210fedcba9876543210fedcba98765432",
                "total_supply": None,
                "is_verified": True,
                "created_at": datetime.now().isoformat()
            }
        ]
        
        with self.driver.session() as session:
            for contract in contracts:
                session.run("""
                    CREATE (c:SmartContract {
                        id: $id,
                        address: $address,
                        name: $name,
                        type: $type,
                        version: $version,
                        creator: $creator,
                        total_supply: $total_supply,
                        is_verified: $is_verified,
                        created_at: $created_at
                    })
                """, **contract)
        
        print(f"✅ 智能合约节点创建完成: {len(contracts)}个合约")
    
    def create_token_nodes(self):
        """创建代币节点"""
        print("🪙 创建代币节点...")
        
        tokens = [
            {
                "id": "token_1",
                "address": "0xtoken1234567890abcdef1234567890abcdef12",
                "name": "BFT Token",
                "symbol": "BFT",
                "decimals": 18,
                "total_supply": 1000000000.0,
                "current_supply": 500000000.0,
                "price": 0.5,
                "market_cap": 250000000.0,
                "created_at": datetime.now().isoformat()
            },
            {
                "id": "token_2",
                "address": "0xtokenabcdef1234567890abcdef1234567890ab",
                "name": "BFT Governance Token",
                "symbol": "BFTG",
                "decimals": 18,
                "total_supply": 100000000.0,
                "current_supply": 80000000.0,
                "price": 1.2,
                "market_cap": 96000000.0,
                "created_at": datetime.now().isoformat()
            }
        ]
        
        with self.driver.session() as session:
            for token in tokens:
                session.run("""
                    CREATE (t:Token {
                        id: $id,
                        address: $address,
                        name: $name,
                        symbol: $symbol,
                        decimals: $decimals,
                        total_supply: $total_supply,
                        current_supply: $current_supply,
                        price: $price,
                        market_cap: $market_cap,
                        created_at: $created_at
                    })
                """, **token)
        
        print(f"✅ 代币节点创建完成: {len(tokens)}个代币")
    
    def create_nft_nodes(self):
        """创建NFT节点"""
        print("🎨 创建NFT节点...")
        
        nfts = [
            {
                "id": "nft_1",
                "token_id": "1",
                "contract_address": "0xcontract5678901234cdef5678901234cdef5678",
                "owner": "0x1234567890abcdef1234567890abcdef12345678",
                "name": "Blockchain Art #1",
                "description": "First blockchain artwork",
                "image_url": "https://example.com/nft1.jpg",
                "rarity_score": 85.5,
                "floor_price": 1.5,
                "is_listed": True,
                "created_at": datetime.now().isoformat()
            },
            {
                "id": "nft_2",
                "token_id": "2",
                "contract_address": "0xcontract5678901234cdef5678901234cdef5678",
                "owner": "0xabcdef1234567890abcdef1234567890abcdef12",
                "name": "Blockchain Art #2",
                "description": "Second blockchain artwork",
                "image_url": "https://example.com/nft2.jpg",
                "rarity_score": 92.3,
                "floor_price": 2.8,
                "is_listed": False,
                "created_at": datetime.now().isoformat()
            }
        ]
        
        with self.driver.session() as session:
            for nft in nfts:
                session.run("""
                    CREATE (n:NFT {
                        id: $id,
                        token_id: $token_id,
                        contract_address: $contract_address,
                        owner: $owner,
                        name: $name,
                        description: $description,
                        image_url: $image_url,
                        rarity_score: $rarity_score,
                        floor_price: $floor_price,
                        is_listed: $is_listed,
                        created_at: $created_at
                    })
                """, **nft)
        
        print(f"✅ NFT节点创建完成: {len(nfts)}个NFT")
    
    def create_dao_nodes(self):
        """创建DAO节点"""
        print("🏛️ 创建DAO节点...")
        
        daos = [
            {
                "id": "dao_1",
                "name": "BFT Governance DAO",
                "description": "Main governance DAO for BFT ecosystem",
                "token_address": "0xtokenabcdef1234567890abcdef1234567890ab",
                "voting_threshold": 10.0,
                "proposal_threshold": 1000.0,
                "quorum_required": 10.0,
                "total_members": 150,
                "active_proposals": 3,
                "created_at": datetime.now().isoformat()
            }
        ]
        
        with self.driver.session() as session:
            for dao in daos:
                session.run("""
                    CREATE (d:DAO {
                        id: $id,
                        name: $name,
                        description: $description,
                        token_address: $token_address,
                        voting_threshold: $voting_threshold,
                        proposal_threshold: $proposal_threshold,
                        quorum_required: $quorum_required,
                        total_members: $total_members,
                        active_proposals: $active_proposals,
                        created_at: $created_at
                    })
                """, **dao)
        
        print(f"✅ DAO节点创建完成: {len(daos)}个DAO")
    
    def create_relationships(self):
        """创建关系"""
        print("🔗 创建关系...")
        
        with self.driver.session() as session:
            # 用户拥有代币关系
            session.run("""
                MATCH (u:User {id: 'user_1'}), (t:Token {id: 'token_1'})
                CREATE (u)-[:OWNS {amount: 10000.0, staked: 5000.0}]->(t)
            """)
            
            session.run("""
                MATCH (u:User {id: 'user_2'}), (t:Token {id: 'token_1'})
                CREATE (u)-[:OWNS {amount: 8000.0, staked: 3000.0}]->(t)
            """)
            
            # 用户拥有NFT关系
            session.run("""
                MATCH (u:User {id: 'user_1'}), (n:NFT {id: 'nft_1'})
                CREATE (u)-[:OWNS_NFT {acquired_at: $acquired_at}]->(n)
            """, acquired_at=datetime.now().isoformat())
            
            session.run("""
                MATCH (u:User {id: 'user_2'}), (n:NFT {id: 'nft_2'})
                CREATE (u)-[:OWNS_NFT {acquired_at: $acquired_at}]->(n)
            """, acquired_at=datetime.now().isoformat())
            
            # 用户参与DAO关系
            session.run("""
                MATCH (u:User {id: 'user_1'}), (d:DAO {id: 'dao_1'})
                CREATE (u)-[:MEMBER_OF {joined_at: $joined_at, voting_power: 100}]->(d)
            """, joined_at=datetime.now().isoformat())
            
            session.run("""
                MATCH (u:User {id: 'user_2'}), (d:DAO {id: 'dao_1'})
                CREATE (u)-[:MEMBER_OF {joined_at: $joined_at, voting_power: 80}]->(d)
            """, joined_at=datetime.now().isoformat())
            
            session.run("""
                MATCH (u:User {id: 'user_3'}), (d:DAO {id: 'dao_1'})
                CREATE (u)-[:MEMBER_OF {joined_at: $joined_at, voting_power: 150}]->(d)
            """, joined_at=datetime.now().isoformat())
            
            # 智能合约关联关系
            session.run("""
                MATCH (c:SmartContract {id: 'contract_1'}), (t:Token {id: 'token_1'})
                CREATE (c)-[:IMPLEMENTS]->(t)
            """)
            
            session.run("""
                MATCH (c:SmartContract {id: 'contract_3'}), (n:NFT {id: 'nft_1'})
                CREATE (c)-[:IMPLEMENTS]->(n)
            """)
            
            session.run("""
                MATCH (c:SmartContract {id: 'contract_3'}), (n:NFT {id: 'nft_2'})
                CREATE (c)-[:IMPLEMENTS]->(n)
            """)
            
            # 用户创建智能合约关系
            session.run("""
                MATCH (u:User {id: 'user_1'}), (c:SmartContract {id: 'contract_1'})
                CREATE (u)-[:CREATED]->(c)
            """)
            
            session.run("""
                MATCH (u:User {id: 'user_2'}), (c:SmartContract {id: 'contract_2'})
                CREATE (u)-[:CREATED]->(c)
            """)
            
            session.run("""
                MATCH (u:User {id: 'user_3'}), (c:SmartContract {id: 'contract_3'})
                CREATE (u)-[:CREATED]->(c)
            """)
            
            # DAO使用代币关系
            session.run("""
                MATCH (d:DAO {id: 'dao_1'}), (t:Token {id: 'token_2'})
                CREATE (d)-[:USES_TOKEN]->(t)
            """)
            
            # 代币之间的关联关系
            session.run("""
                MATCH (t1:Token {id: 'token_1'}), (t2:Token {id: 'token_2'})
                CREATE (t1)-[:RELATED_TO {relationship: 'governance'}]->(t2)
            """)
            
            # NFT之间的关联关系
            session.run("""
                MATCH (n1:NFT {id: 'nft_1'}), (n2:NFT {id: 'nft_2'})
                CREATE (n1)-[:RELATED_TO {relationship: 'collection'}]->(n2)
            """)
            
            # 用户之间的信任关系
            session.run("""
                MATCH (u1:User {id: 'user_1'}), (u2:User {id: 'user_2'})
                CREATE (u1)-[:TRUSTS {trust_score: 0.8, created_at: $created_at}]->(u2)
            """, created_at=datetime.now().isoformat())
            
            session.run("""
                MATCH (u2:User {id: 'user_2'}), (u3:User {id: 'user_3'})
                CREATE (u2)-[:TRUSTS {trust_score: 0.9, created_at: $created_at}]->(u3)
            """, created_at=datetime.now().isoformat())
        
        print("✅ 关系创建完成")
    
    def verify_graph_structure(self):
        """验证图数据库结构"""
        try:
            print("🔍 验证区块链版Neo4j图数据库结构...")
            
            with self.driver.session() as session:
                # 统计节点数量
                node_counts = {}
                labels = ["User", "SmartContract", "Token", "NFT", "DAO"]
                
                for label in labels:
                    result = session.run(f"MATCH (n:{label}) RETURN count(n) as count")
                    count = result.single()["count"]
                    node_counts[label] = count
                    print(f"📊 {label}节点数量: {count}")
                
                # 统计关系数量
                relationship_counts = {}
                relationships = ["OWNS", "OWNS_NFT", "MEMBER_OF", "IMPLEMENTS", "CREATED", "USES_TOKEN", "RELATED_TO", "TRUSTS"]
                
                for rel in relationships:
                    result = session.run(f"MATCH ()-[r:{rel}]->() RETURN count(r) as count")
                    count = result.single()["count"]
                    relationship_counts[rel] = count
                    print(f"🔗 {rel}关系数量: {count}")
                
                # 统计总节点和关系数
                total_nodes = sum(node_counts.values())
                total_relationships = sum(relationship_counts.values())
                
                print(f"✅ 图数据库结构验证完成")
                print(f"📊 总节点数: {total_nodes}")
                print(f"🔗 总关系数: {total_relationships}")
                
                return True
                
        except Exception as e:
            print(f"❌ 验证区块链版Neo4j图数据库结构失败: {e}")
            return False

def main():
    """主函数"""
    print("🚀 开始区块链版Neo4j图数据库结构配置...")
    
    # 创建Neo4j管理器
    neo4j_manager = BlockchainNeo4jManager()
    
    try:
        # 测试连接
        if not neo4j_manager.test_connection():
            print("❌ Neo4j连接失败，退出程序")
            return False
        
        # 设置图数据库结构
        if not neo4j_manager.setup_blockchain_graph_structure():
            print("❌ 设置图数据库结构失败")
            return False
        
        # 验证图数据库结构
        if not neo4j_manager.verify_graph_structure():
            print("❌ 验证图数据库结构失败")
            return False
        
        print("🎉 区块链版Neo4j图数据库结构配置完成!")
        return True
        
    finally:
        neo4j_manager.close()

if __name__ == "__main__":
    main()
