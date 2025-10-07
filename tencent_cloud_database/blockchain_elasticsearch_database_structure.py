#!/usr/bin/env python3
"""
区块链版 Elasticsearch 数据库结构
创建时间: 2025-10-05
版本: Blockchain Version
功能: 全文搜索、索引映射
"""

from elasticsearch import Elasticsearch
import json
from datetime import datetime

class BlockchainElasticsearchManager:
    def __init__(self):
        """初始化区块链版Elasticsearch连接"""
        self.es_client = Elasticsearch(
            hosts=[{'host': 'localhost', 'port': 9202, 'scheme': 'http'}],  # 区块链版Elasticsearch端口
            basic_auth=('elastic', 'b_elastic_password_2025'),
            verify_certs=False,
            request_timeout=30
        )
        
    def test_connection(self):
        """测试Elasticsearch连接"""
        try:
            info = self.es_client.info()
            print(f"✅ Elasticsearch连接成功: {info['version']['number']}")
            return True
        except Exception as e:
            print(f"❌ Elasticsearch连接失败: {e}")
            return False
    
    def setup_blockchain_search_structure(self):
        """设置区块链版搜索结构"""
        try:
            print("🚀 开始设置区块链版Elasticsearch搜索结构...")
            
            # 1. 创建用户搜索索引
            self.create_users_index()
            
            # 2. 创建智能合约搜索索引
            self.create_smart_contracts_index()
            
            # 3. 创建代币搜索索引
            self.create_tokens_index()
            
            # 4. 创建NFT搜索索引
            self.create_nfts_index()
            
            # 5. 创建DAO搜索索引
            self.create_daos_index()
            
            # 6. 创建交易搜索索引
            self.create_transactions_index()
            
            # 7. 创建提案搜索索引
            self.create_proposals_index()
            
            # 8. 创建质押搜索索引
            self.create_staking_index()
            
            # 9. 创建流动性搜索索引
            self.create_liquidity_index()
            
            # 10. 创建跨链搜索索引
            self.create_cross_chain_index()
            
            print("✅ 区块链版Elasticsearch搜索结构设置完成!")
            return True
            
        except Exception as e:
            print(f"❌ 设置区块链版Elasticsearch搜索结构失败: {e}")
            return False
    
    def create_users_index(self):
        """创建用户搜索索引"""
        print("👤 创建用户搜索索引...")
        
        index_name = "blockchain_users"
        mapping = {
            "mappings": {
                "properties": {
                    "user_id": {"type": "keyword"},
                    "wallet_address": {"type": "keyword"},
                    "username": {
                        "type": "text",
                        "analyzer": "standard",
                        "fields": {
                            "keyword": {"type": "keyword"}
                        }
                    },
                    "email": {"type": "keyword"},
                    "reputation_score": {"type": "integer"},
                    "total_tokens": {"type": "float"},
                    "staked_tokens": {"type": "float"},
                    "voting_power": {"type": "integer"},
                    "is_verified": {"type": "boolean"},
                    "created_at": {"type": "date"},
                    "updated_at": {"type": "date"}
                }
            }
        }
        
        # 删除已存在的索引
        if self.es_client.indices.exists(index=index_name):
            self.es_client.indices.delete(index=index_name)
        
        # 创建索引
        self.es_client.indices.create(index=index_name, body=mapping)
        
        # 插入示例数据
        sample_users = [
            {
                "user_id": "user_1",
                "wallet_address": "0x1234567890abcdef1234567890abcdef12345678",
                "username": "blockchain_user_1",
                "email": "user1@example.com",
                "reputation_score": 85,
                "total_tokens": 10000.0,
                "staked_tokens": 5000.0,
                "voting_power": 100,
                "is_verified": True,
                "created_at": datetime.now().isoformat(),
                "updated_at": datetime.now().isoformat()
            },
            {
                "user_id": "user_2",
                "wallet_address": "0xabcdef1234567890abcdef1234567890abcdef12",
                "username": "blockchain_user_2",
                "email": "user2@example.com",
                "reputation_score": 72,
                "total_tokens": 8000.0,
                "staked_tokens": 3000.0,
                "voting_power": 80,
                "is_verified": True,
                "created_at": datetime.now().isoformat(),
                "updated_at": datetime.now().isoformat()
            }
        ]
        
        for i, user in enumerate(sample_users):
            self.es_client.index(index=index_name, id=i+1, body=user)
        
        print(f"✅ 用户搜索索引创建完成: {len(sample_users)}个用户")
    
    def create_smart_contracts_index(self):
        """创建智能合约搜索索引"""
        print("📜 创建智能合约搜索索引...")
        
        index_name = "blockchain_smart_contracts"
        mapping = {
            "mappings": {
                "properties": {
                    "contract_id": {"type": "keyword"},
                    "contract_address": {"type": "keyword"},
                    "contract_name": {
                        "type": "text",
                        "analyzer": "standard",
                        "fields": {
                            "keyword": {"type": "keyword"}
                        }
                    },
                    "contract_type": {"type": "keyword"},
                    "version": {"type": "keyword"},
                    "creator_address": {"type": "keyword"},
                    "is_verified": {"type": "boolean"},
                    "total_supply": {"type": "float"},
                    "security_score": {"type": "float"},
                    "created_at": {"type": "date"}
                }
            }
        }
        
        if self.es_client.indices.exists(index=index_name):
            self.es_client.indices.delete(index=index_name)
        
        self.es_client.indices.create(index=index_name, body=mapping)
        
        # 插入示例数据
        sample_contracts = [
            {
                "contract_id": "contract_1",
                "contract_address": "0xcontract1234567890abcdef1234567890abcdef12",
                "contract_name": "BFTToken",
                "contract_type": "ERC20",
                "version": "1.0.0",
                "creator_address": "0x1234567890abcdef1234567890abcdef12345678",
                "is_verified": True,
                "total_supply": 1000000000.0,
                "security_score": 95.5,
                "created_at": datetime.now().isoformat()
            },
            {
                "contract_id": "contract_2",
                "contract_address": "0xcontractabcdef1234567890abcdef1234567890ab",
                "contract_name": "BFTGovernance",
                "contract_type": "Governance",
                "version": "2.1.0",
                "creator_address": "0xabcdef1234567890abcdef1234567890abcdef12",
                "is_verified": True,
                "total_supply": None,
                "security_score": 88.2,
                "created_at": datetime.now().isoformat()
            }
        ]
        
        for i, contract in enumerate(sample_contracts):
            self.es_client.index(index=index_name, id=i+1, body=contract)
        
        print(f"✅ 智能合约搜索索引创建完成: {len(sample_contracts)}个合约")
    
    def create_tokens_index(self):
        """创建代币搜索索引"""
        print("🪙 创建代币搜索索引...")
        
        index_name = "blockchain_tokens"
        mapping = {
            "mappings": {
                "properties": {
                    "token_id": {"type": "keyword"},
                    "token_address": {"type": "keyword"},
                    "token_name": {
                        "type": "text",
                        "analyzer": "standard",
                        "fields": {
                            "keyword": {"type": "keyword"}
                        }
                    },
                    "symbol": {"type": "keyword"},
                    "decimals": {"type": "integer"},
                    "total_supply": {"type": "float"},
                    "current_supply": {"type": "float"},
                    "price": {"type": "float"},
                    "market_cap": {"type": "float"},
                    "volume_24h": {"type": "float"},
                    "created_at": {"type": "date"}
                }
            }
        }
        
        if self.es_client.indices.exists(index=index_name):
            self.es_client.indices.delete(index=index_name)
        
        self.es_client.indices.create(index=index_name, body=mapping)
        
        # 插入示例数据
        sample_tokens = [
            {
                "token_id": "token_1",
                "token_address": "0xtoken1234567890abcdef1234567890abcdef12",
                "token_name": "BFT Token",
                "symbol": "BFT",
                "decimals": 18,
                "total_supply": 1000000000.0,
                "current_supply": 500000000.0,
                "price": 0.5,
                "market_cap": 250000000.0,
                "volume_24h": 1000000.0,
                "created_at": datetime.now().isoformat()
            }
        ]
        
        for i, token in enumerate(sample_tokens):
            self.es_client.index(index=index_name, id=i+1, body=token)
        
        print(f"✅ 代币搜索索引创建完成: {len(sample_tokens)}个代币")
    
    def create_nfts_index(self):
        """创建NFT搜索索引"""
        print("🎨 创建NFT搜索索引...")
        
        index_name = "blockchain_nfts"
        mapping = {
            "mappings": {
                "properties": {
                    "nft_id": {"type": "keyword"},
                    "token_id": {"type": "keyword"},
                    "contract_address": {"type": "keyword"},
                    "owner_address": {"type": "keyword"},
                    "name": {
                        "type": "text",
                        "analyzer": "standard",
                        "fields": {
                            "keyword": {"type": "keyword"}
                        }
                    },
                    "description": {
                        "type": "text",
                        "analyzer": "standard"
                    },
                    "image_url": {"type": "keyword"},
                    "rarity_score": {"type": "float"},
                    "floor_price": {"type": "float"},
                    "is_listed": {"type": "boolean"},
                    "attributes": {"type": "object"},
                    "created_at": {"type": "date"}
                }
            }
        }
        
        if self.es_client.indices.exists(index=index_name):
            self.es_client.indices.delete(index=index_name)
        
        self.es_client.indices.create(index=index_name, body=mapping)
        
        # 插入示例数据
        sample_nfts = [
            {
                "nft_id": "nft_1",
                "token_id": "1",
                "contract_address": "0xcontract5678901234cdef5678901234cdef5678",
                "owner_address": "0x1234567890abcdef1234567890abcdef12345678",
                "name": "Blockchain Art #1",
                "description": "First blockchain artwork with unique characteristics",
                "image_url": "https://example.com/nft1.jpg",
                "rarity_score": 85.5,
                "floor_price": 1.5,
                "is_listed": True,
                "attributes": {
                    "color": "blue",
                    "style": "abstract",
                    "artist": "blockchain_artist_1"
                },
                "created_at": datetime.now().isoformat()
            }
        ]
        
        for i, nft in enumerate(sample_nfts):
            self.es_client.index(index=index_name, id=i+1, body=nft)
        
        print(f"✅ NFT搜索索引创建完成: {len(sample_nfts)}个NFT")
    
    def create_daos_index(self):
        """创建DAO搜索索引"""
        print("🏛️ 创建DAO搜索索引...")
        
        index_name = "blockchain_daos"
        mapping = {
            "mappings": {
                "properties": {
                    "dao_id": {"type": "keyword"},
                    "dao_name": {
                        "type": "text",
                        "analyzer": "standard",
                        "fields": {
                            "keyword": {"type": "keyword"}
                        }
                    },
                    "description": {
                        "type": "text",
                        "analyzer": "standard"
                    },
                    "token_address": {"type": "keyword"},
                    "voting_threshold": {"type": "float"},
                    "proposal_threshold": {"type": "float"},
                    "quorum_required": {"type": "float"},
                    "total_members": {"type": "integer"},
                    "active_proposals": {"type": "integer"},
                    "created_at": {"type": "date"}
                }
            }
        }
        
        if self.es_client.indices.exists(index=index_name):
            self.es_client.indices.delete(index=index_name)
        
        self.es_client.indices.create(index=index_name, body=mapping)
        
        # 插入示例数据
        sample_daos = [
            {
                "dao_id": "dao_1",
                "dao_name": "BFT Governance DAO",
                "description": "Main governance DAO for BFT ecosystem with decentralized decision making",
                "token_address": "0xtokenabcdef1234567890abcdef1234567890ab",
                "voting_threshold": 10.0,
                "proposal_threshold": 1000.0,
                "quorum_required": 10.0,
                "total_members": 150,
                "active_proposals": 3,
                "created_at": datetime.now().isoformat()
            }
        ]
        
        for i, dao in enumerate(sample_daos):
            self.es_client.index(index=index_name, id=i+1, body=dao)
        
        print(f"✅ DAO搜索索引创建完成: {len(sample_daos)}个DAO")
    
    def create_transactions_index(self):
        """创建交易搜索索引"""
        print("💸 创建交易搜索索引...")
        
        index_name = "blockchain_transactions"
        mapping = {
            "mappings": {
                "properties": {
                    "transaction_id": {"type": "keyword"},
                    "transaction_hash": {"type": "keyword"},
                    "from_address": {"type": "keyword"},
                    "to_address": {"type": "keyword"},
                    "amount": {"type": "float"},
                    "token": {"type": "keyword"},
                    "status": {"type": "keyword"},
                    "block_number": {"type": "long"},
                    "gas_used": {"type": "long"},
                    "gas_price": {"type": "float"},
                    "transaction_fee": {"type": "float"},
                    "created_at": {"type": "date"}
                }
            }
        }
        
        if self.es_client.indices.exists(index=index_name):
            self.es_client.indices.delete(index=index_name)
        
        self.es_client.indices.create(index=index_name, body=mapping)
        
        print("✅ 交易搜索索引创建完成")
    
    def create_proposals_index(self):
        """创建提案搜索索引"""
        print("🗳️ 创建提案搜索索引...")
        
        index_name = "blockchain_proposals"
        mapping = {
            "mappings": {
                "properties": {
                    "proposal_id": {"type": "keyword"},
                    "dao_id": {"type": "keyword"},
                    "proposer_address": {"type": "keyword"},
                    "title": {
                        "type": "text",
                        "analyzer": "standard",
                        "fields": {
                            "keyword": {"type": "keyword"}
                        }
                    },
                    "description": {
                        "type": "text",
                        "analyzer": "standard"
                    },
                    "proposal_type": {"type": "keyword"},
                    "amount": {"type": "float"},
                    "status": {"type": "keyword"},
                    "total_votes": {"type": "integer"},
                    "yes_votes": {"type": "integer"},
                    "no_votes": {"type": "integer"},
                    "voting_start": {"type": "date"},
                    "voting_end": {"type": "date"},
                    "created_at": {"type": "date"}
                }
            }
        }
        
        if self.es_client.indices.exists(index=index_name):
            self.es_client.indices.delete(index=index_name)
        
        self.es_client.indices.create(index=index_name, body=mapping)
        
        print("✅ 提案搜索索引创建完成")
    
    def create_staking_index(self):
        """创建质押搜索索引"""
        print("💰 创建质押搜索索引...")
        
        index_name = "blockchain_staking"
        mapping = {
            "mappings": {
                "properties": {
                    "staking_id": {"type": "keyword"},
                    "staker_address": {"type": "keyword"},
                    "pool_id": {"type": "keyword"},
                    "amount": {"type": "float"},
                    "staking_period": {"type": "integer"},
                    "apy": {"type": "float"},
                    "rewards": {"type": "float"},
                    "status": {"type": "keyword"},
                    "start_time": {"type": "date"},
                    "end_time": {"type": "date"},
                    "created_at": {"type": "date"}
                }
            }
        }
        
        if self.es_client.indices.exists(index=index_name):
            self.es_client.indices.delete(index=index_name)
        
        self.es_client.indices.create(index=index_name, body=mapping)
        
        print("✅ 质押搜索索引创建完成")
    
    def create_liquidity_index(self):
        """创建流动性搜索索引"""
        print("🌾 创建流动性搜索索引...")
        
        index_name = "blockchain_liquidity"
        mapping = {
            "mappings": {
                "properties": {
                    "liquidity_id": {"type": "keyword"},
                    "provider_address": {"type": "keyword"},
                    "pool_address": {"type": "keyword"},
                    "token_a_address": {"type": "keyword"},
                    "token_b_address": {"type": "keyword"},
                    "liquidity_amount": {"type": "float"},
                    "lp_tokens": {"type": "float"},
                    "farming_rewards": {"type": "float"},
                    "apy": {"type": "float"},
                    "is_active": {"type": "boolean"},
                    "created_at": {"type": "date"}
                }
            }
        }
        
        if self.es_client.indices.exists(index=index_name):
            self.es_client.indices.delete(index=index_name)
        
        self.es_client.indices.create(index=index_name, body=mapping)
        
        print("✅ 流动性搜索索引创建完成")
    
    def create_cross_chain_index(self):
        """创建跨链搜索索引"""
        print("🌉 创建跨链搜索索引...")
        
        index_name = "blockchain_cross_chain"
        mapping = {
            "mappings": {
                "properties": {
                    "bridge_id": {"type": "keyword"},
                    "source_chain": {"type": "keyword"},
                    "target_chain": {"type": "keyword"},
                    "bridge_contract": {"type": "keyword"},
                    "token_address": {"type": "keyword"},
                    "amount": {"type": "float"},
                    "transaction_hash": {"type": "keyword"},
                    "bridge_fee": {"type": "float"},
                    "status": {"type": "keyword"},
                    "created_at": {"type": "date"},
                    "completed_at": {"type": "date"}
                }
            }
        }
        
        if self.es_client.indices.exists(index=index_name):
            self.es_client.indices.delete(index=index_name)
        
        self.es_client.indices.create(index=index_name, body=mapping)
        
        print("✅ 跨链搜索索引创建完成")
    
    def verify_search_structure(self):
        """验证搜索结构"""
        try:
            print("🔍 验证区块链版Elasticsearch搜索结构...")
            
            # 获取所有索引
            indices = self.es_client.indices.get_alias()
            blockchain_indices = [idx for idx in indices.keys() if idx.startswith('blockchain_')]
            
            print(f"📊 区块链版索引数量: {len(blockchain_indices)}")
            
            for index_name in blockchain_indices:
                # 获取索引统计
                stats = self.es_client.indices.stats(index=index_name)
                doc_count = stats['indices'][index_name]['total']['docs']['count']
                print(f"📄 {index_name}: {doc_count}个文档")
            
            print("✅ 区块链版Elasticsearch搜索结构验证完成")
            return True
            
        except Exception as e:
            print(f"❌ 验证区块链版Elasticsearch搜索结构失败: {e}")
            return False

def main():
    """主函数"""
    print("🚀 开始区块链版Elasticsearch数据库结构配置...")
    
    # 创建Elasticsearch管理器
    es_manager = BlockchainElasticsearchManager()
    
    # 测试连接
    if not es_manager.test_connection():
        print("❌ Elasticsearch连接失败，退出程序")
        return False
    
    # 设置搜索结构
    if not es_manager.setup_blockchain_search_structure():
        print("❌ 设置搜索结构失败")
        return False
    
    # 验证搜索结构
    if not es_manager.verify_search_structure():
        print("❌ 验证搜索结构失败")
        return False
    
    print("🎉 区块链版Elasticsearch数据库结构配置完成!")
    return True

if __name__ == "__main__":
    main()
