#!/usr/bin/env python3
"""
区块链版 Weaviate 向量数据库结构
创建时间: 2025-10-05
版本: Blockchain Version
功能: 向量搜索、AI嵌入
"""

import weaviate
import json
from datetime import datetime
import numpy as np

class BlockchainWeaviateManager:
    def __init__(self):
        """初始化区块链版Weaviate连接"""
        self.client = weaviate.Client(
            url="http://localhost:8082",  # 区块链版Weaviate端口
            additional_headers={
                "X-OpenAI-Api-Key": "your-openai-api-key"  # 如果需要OpenAI集成
            }
        )
        
    def test_connection(self):
        """测试Weaviate连接"""
        try:
            # 检查Weaviate是否运行
            if self.client.is_ready():
                print("✅ Weaviate连接成功")
                return True
            else:
                print("❌ Weaviate未就绪")
                return False
        except Exception as e:
            print(f"❌ Weaviate连接失败: {e}")
            return False
    
    def setup_blockchain_vector_structure(self):
        """设置区块链版向量数据库结构"""
        try:
            print("🚀 开始设置区块链版Weaviate向量数据库结构...")
            
            # 1. 创建用户向量类
            self.create_user_vector_class()
            
            # 2. 创建智能合约向量类
            self.create_smart_contract_vector_class()
            
            # 3. 创建代币向量类
            self.create_token_vector_class()
            
            # 4. 创建NFT向量类
            self.create_nft_vector_class()
            
            # 5. 创建DAO向量类
            self.create_dao_vector_class()
            
            # 6. 创建交易向量类
            self.create_transaction_vector_class()
            
            # 7. 创建提案向量类
            self.create_proposal_vector_class()
            
            # 8. 创建质押向量类
            self.create_staking_vector_class()
            
            # 9. 创建流动性向量类
            self.create_liquidity_vector_class()
            
            # 10. 创建跨链向量类
            self.create_cross_chain_vector_class()
            
            print("✅ 区块链版Weaviate向量数据库结构设置完成!")
            return True
            
        except Exception as e:
            print(f"❌ 设置区块链版Weaviate向量数据库结构失败: {e}")
            return False
    
    def create_user_vector_class(self):
        """创建用户向量类"""
        print("👤 创建用户向量类...")
        
        class_name = "BlockchainUser"
        
        # 删除已存在的类
        if self.client.schema.exists(class_name):
            self.client.schema.delete_class(class_name)
        
        # 创建用户向量类
        user_class = {
            "class": class_name,
            "description": "Blockchain user vector representation",
            "vectorizer": "text2vec-openai",  # 使用OpenAI向量化
            "properties": [
                {
                    "name": "user_id",
                    "dataType": ["string"],
                    "description": "Unique user identifier"
                },
                {
                    "name": "wallet_address",
                    "dataType": ["string"],
                    "description": "User wallet address"
                },
                {
                    "name": "username",
                    "dataType": ["string"],
                    "description": "User username"
                },
                {
                    "name": "reputation_score",
                    "dataType": ["number"],
                    "description": "User reputation score"
                },
                {
                    "name": "total_tokens",
                    "dataType": ["number"],
                    "description": "Total tokens owned"
                },
                {
                    "name": "staked_tokens",
                    "dataType": ["number"],
                    "description": "Staked tokens amount"
                },
                {
                    "name": "voting_power",
                    "dataType": ["number"],
                    "description": "User voting power"
                },
                {
                    "name": "is_verified",
                    "dataType": ["boolean"],
                    "description": "Whether user is verified"
                },
                {
                    "name": "created_at",
                    "dataType": ["date"],
                    "description": "User creation timestamp"
                }
            ]
        }
        
        self.client.schema.create_class(user_class)
        
        # 插入示例数据
        sample_users = [
            {
                "user_id": "user_1",
                "wallet_address": "0x1234567890abcdef1234567890abcdef12345678",
                "username": "blockchain_user_1",
                "reputation_score": 85,
                "total_tokens": 10000.0,
                "staked_tokens": 5000.0,
                "voting_power": 100,
                "is_verified": True,
                "created_at": datetime.now().isoformat()
            },
            {
                "user_id": "user_2",
                "wallet_address": "0xabcdef1234567890abcdef1234567890abcdef12",
                "username": "blockchain_user_2",
                "reputation_score": 72,
                "total_tokens": 8000.0,
                "staked_tokens": 3000.0,
                "voting_power": 80,
                "is_verified": True,
                "created_at": datetime.now().isoformat()
            }
        ]
        
        for user in sample_users:
            self.client.data_object.create(
                data_object=user,
                class_name=class_name
            )
        
        print(f"✅ 用户向量类创建完成: {len(sample_users)}个用户")
    
    def create_smart_contract_vector_class(self):
        """创建智能合约向量类"""
        print("📜 创建智能合约向量类...")
        
        class_name = "BlockchainSmartContract"
        
        if self.client.schema.exists(class_name):
            self.client.schema.delete_class(class_name)
        
        contract_class = {
            "class": class_name,
            "description": "Smart contract vector representation",
            "vectorizer": "text2vec-openai",
            "properties": [
                {
                    "name": "contract_id",
                    "dataType": ["string"],
                    "description": "Unique contract identifier"
                },
                {
                    "name": "contract_address",
                    "dataType": ["string"],
                    "description": "Contract address"
                },
                {
                    "name": "contract_name",
                    "dataType": ["string"],
                    "description": "Contract name"
                },
                {
                    "name": "contract_type",
                    "dataType": ["string"],
                    "description": "Contract type (ERC20, ERC721, etc.)"
                },
                {
                    "name": "version",
                    "dataType": ["string"],
                    "description": "Contract version"
                },
                {
                    "name": "creator_address",
                    "dataType": ["string"],
                    "description": "Contract creator address"
                },
                {
                    "name": "is_verified",
                    "dataType": ["boolean"],
                    "description": "Whether contract is verified"
                },
                {
                    "name": "security_score",
                    "dataType": ["number"],
                    "description": "Contract security score"
                },
                {
                    "name": "created_at",
                    "dataType": ["date"],
                    "description": "Contract creation timestamp"
                }
            ]
        }
        
        self.client.schema.create_class(contract_class)
        
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
                "security_score": 88.2,
                "created_at": datetime.now().isoformat()
            }
        ]
        
        for contract in sample_contracts:
            self.client.data_object.create(
                data_object=contract,
                class_name=class_name
            )
        
        print(f"✅ 智能合约向量类创建完成: {len(sample_contracts)}个合约")
    
    def create_token_vector_class(self):
        """创建代币向量类"""
        print("🪙 创建代币向量类...")
        
        class_name = "BlockchainToken"
        
        if self.client.schema.exists(class_name):
            self.client.schema.delete_class(class_name)
        
        token_class = {
            "class": class_name,
            "description": "Token vector representation",
            "vectorizer": "text2vec-openai",
            "properties": [
                {
                    "name": "token_id",
                    "dataType": ["string"],
                    "description": "Unique token identifier"
                },
                {
                    "name": "token_address",
                    "dataType": ["string"],
                    "description": "Token contract address"
                },
                {
                    "name": "token_name",
                    "dataType": ["string"],
                    "description": "Token name"
                },
                {
                    "name": "symbol",
                    "dataType": ["string"],
                    "description": "Token symbol"
                },
                {
                    "name": "decimals",
                    "dataType": ["number"],
                    "description": "Token decimals"
                },
                {
                    "name": "total_supply",
                    "dataType": ["number"],
                    "description": "Total token supply"
                },
                {
                    "name": "current_supply",
                    "dataType": ["number"],
                    "description": "Current token supply"
                },
                {
                    "name": "price",
                    "dataType": ["number"],
                    "description": "Token price"
                },
                {
                    "name": "market_cap",
                    "dataType": ["number"],
                    "description": "Token market capitalization"
                },
                {
                    "name": "volume_24h",
                    "dataType": ["number"],
                    "description": "24-hour trading volume"
                },
                {
                    "name": "created_at",
                    "dataType": ["date"],
                    "description": "Token creation timestamp"
                }
            ]
        }
        
        self.client.schema.create_class(token_class)
        
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
        
        for token in sample_tokens:
            self.client.data_object.create(
                data_object=token,
                class_name=class_name
            )
        
        print(f"✅ 代币向量类创建完成: {len(sample_tokens)}个代币")
    
    def create_nft_vector_class(self):
        """创建NFT向量类"""
        print("🎨 创建NFT向量类...")
        
        class_name = "BlockchainNFT"
        
        if self.client.schema.exists(class_name):
            self.client.schema.delete_class(class_name)
        
        nft_class = {
            "class": class_name,
            "description": "NFT vector representation",
            "vectorizer": "text2vec-openai",
            "properties": [
                {
                    "name": "nft_id",
                    "dataType": ["string"],
                    "description": "Unique NFT identifier"
                },
                {
                    "name": "token_id",
                    "dataType": ["string"],
                    "description": "NFT token ID"
                },
                {
                    "name": "contract_address",
                    "dataType": ["string"],
                    "description": "NFT contract address"
                },
                {
                    "name": "owner_address",
                    "dataType": ["string"],
                    "description": "NFT owner address"
                },
                {
                    "name": "name",
                    "dataType": ["string"],
                    "description": "NFT name"
                },
                {
                    "name": "description",
                    "dataType": ["string"],
                    "description": "NFT description"
                },
                {
                    "name": "image_url",
                    "dataType": ["string"],
                    "description": "NFT image URL"
                },
                {
                    "name": "rarity_score",
                    "dataType": ["number"],
                    "description": "NFT rarity score"
                },
                {
                    "name": "floor_price",
                    "dataType": ["number"],
                    "description": "NFT floor price"
                },
                {
                    "name": "is_listed",
                    "dataType": ["boolean"],
                    "description": "Whether NFT is listed for sale"
                },
                {
                    "name": "attributes",
                    "dataType": ["object"],
                    "description": "NFT attributes"
                },
                {
                    "name": "created_at",
                    "dataType": ["date"],
                    "description": "NFT creation timestamp"
                }
            ]
        }
        
        self.client.schema.create_class(nft_class)
        
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
        
        for nft in sample_nfts:
            self.client.data_object.create(
                data_object=nft,
                class_name=class_name
            )
        
        print(f"✅ NFT向量类创建完成: {len(sample_nfts)}个NFT")
    
    def create_dao_vector_class(self):
        """创建DAO向量类"""
        print("🏛️ 创建DAO向量类...")
        
        class_name = "BlockchainDAO"
        
        if self.client.schema.exists(class_name):
            self.client.schema.delete_class(class_name)
        
        dao_class = {
            "class": class_name,
            "description": "DAO vector representation",
            "vectorizer": "text2vec-openai",
            "properties": [
                {
                    "name": "dao_id",
                    "dataType": ["string"],
                    "description": "Unique DAO identifier"
                },
                {
                    "name": "dao_name",
                    "dataType": ["string"],
                    "description": "DAO name"
                },
                {
                    "name": "description",
                    "dataType": ["string"],
                    "description": "DAO description"
                },
                {
                    "name": "token_address",
                    "dataType": ["string"],
                    "description": "DAO token address"
                },
                {
                    "name": "voting_threshold",
                    "dataType": ["number"],
                    "description": "DAO voting threshold"
                },
                {
                    "name": "proposal_threshold",
                    "dataType": ["number"],
                    "description": "DAO proposal threshold"
                },
                {
                    "name": "quorum_required",
                    "dataType": ["number"],
                    "description": "DAO quorum requirement"
                },
                {
                    "name": "total_members",
                    "dataType": ["number"],
                    "description": "Total DAO members"
                },
                {
                    "name": "active_proposals",
                    "dataType": ["number"],
                    "description": "Active proposals count"
                },
                {
                    "name": "created_at",
                    "dataType": ["date"],
                    "description": "DAO creation timestamp"
                }
            ]
        }
        
        self.client.schema.create_class(dao_class)
        
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
        
        for dao in sample_daos:
            self.client.data_object.create(
                data_object=dao,
                class_name=class_name
            )
        
        print(f"✅ DAO向量类创建完成: {len(sample_daos)}个DAO")
    
    def create_transaction_vector_class(self):
        """创建交易向量类"""
        print("💸 创建交易向量类...")
        
        class_name = "BlockchainTransaction"
        
        if self.client.schema.exists(class_name):
            self.client.schema.delete_class(class_name)
        
        transaction_class = {
            "class": class_name,
            "description": "Transaction vector representation",
            "vectorizer": "text2vec-openai",
            "properties": [
                {
                    "name": "transaction_id",
                    "dataType": ["string"],
                    "description": "Unique transaction identifier"
                },
                {
                    "name": "transaction_hash",
                    "dataType": ["string"],
                    "description": "Transaction hash"
                },
                {
                    "name": "from_address",
                    "dataType": ["string"],
                    "description": "Sender address"
                },
                {
                    "name": "to_address",
                    "dataType": ["string"],
                    "description": "Receiver address"
                },
                {
                    "name": "amount",
                    "dataType": ["number"],
                    "description": "Transaction amount"
                },
                {
                    "name": "token",
                    "dataType": ["string"],
                    "description": "Token symbol"
                },
                {
                    "name": "status",
                    "dataType": ["string"],
                    "description": "Transaction status"
                },
                {
                    "name": "block_number",
                    "dataType": ["number"],
                    "description": "Block number"
                },
                {
                    "name": "gas_used",
                    "dataType": ["number"],
                    "description": "Gas used"
                },
                {
                    "name": "gas_price",
                    "dataType": ["number"],
                    "description": "Gas price"
                },
                {
                    "name": "transaction_fee",
                    "dataType": ["number"],
                    "description": "Transaction fee"
                },
                {
                    "name": "created_at",
                    "dataType": ["date"],
                    "description": "Transaction timestamp"
                }
            ]
        }
        
        self.client.schema.create_class(transaction_class)
        
        print("✅ 交易向量类创建完成")
    
    def create_proposal_vector_class(self):
        """创建提案向量类"""
        print("🗳️ 创建提案向量类...")
        
        class_name = "BlockchainProposal"
        
        if self.client.schema.exists(class_name):
            self.client.schema.delete_class(class_name)
        
        proposal_class = {
            "class": class_name,
            "description": "Proposal vector representation",
            "vectorizer": "text2vec-openai",
            "properties": [
                {
                    "name": "proposal_id",
                    "dataType": ["string"],
                    "description": "Unique proposal identifier"
                },
                {
                    "name": "dao_id",
                    "dataType": ["string"],
                    "description": "DAO identifier"
                },
                {
                    "name": "proposer_address",
                    "dataType": ["string"],
                    "description": "Proposer address"
                },
                {
                    "name": "title",
                    "dataType": ["string"],
                    "description": "Proposal title"
                },
                {
                    "name": "description",
                    "dataType": ["string"],
                    "description": "Proposal description"
                },
                {
                    "name": "proposal_type",
                    "dataType": ["string"],
                    "description": "Proposal type"
                },
                {
                    "name": "amount",
                    "dataType": ["number"],
                    "description": "Proposal amount"
                },
                {
                    "name": "status",
                    "dataType": ["string"],
                    "description": "Proposal status"
                },
                {
                    "name": "total_votes",
                    "dataType": ["number"],
                    "description": "Total votes"
                },
                {
                    "name": "yes_votes",
                    "dataType": ["number"],
                    "description": "Yes votes"
                },
                {
                    "name": "no_votes",
                    "dataType": ["number"],
                    "description": "No votes"
                },
                {
                    "name": "voting_start",
                    "dataType": ["date"],
                    "description": "Voting start time"
                },
                {
                    "name": "voting_end",
                    "dataType": ["date"],
                    "description": "Voting end time"
                },
                {
                    "name": "created_at",
                    "dataType": ["date"],
                    "description": "Proposal creation timestamp"
                }
            ]
        }
        
        self.client.schema.create_class(proposal_class)
        
        print("✅ 提案向量类创建完成")
    
    def create_staking_vector_class(self):
        """创建质押向量类"""
        print("💰 创建质押向量类...")
        
        class_name = "BlockchainStaking"
        
        if self.client.schema.exists(class_name):
            self.client.schema.delete_class(class_name)
        
        staking_class = {
            "class": class_name,
            "description": "Staking vector representation",
            "vectorizer": "text2vec-openai",
            "properties": [
                {
                    "name": "staking_id",
                    "dataType": ["string"],
                    "description": "Unique staking identifier"
                },
                {
                    "name": "staker_address",
                    "dataType": ["string"],
                    "description": "Staker address"
                },
                {
                    "name": "pool_id",
                    "dataType": ["string"],
                    "description": "Staking pool identifier"
                },
                {
                    "name": "amount",
                    "dataType": ["number"],
                    "description": "Staked amount"
                },
                {
                    "name": "staking_period",
                    "dataType": ["number"],
                    "description": "Staking period in days"
                },
                {
                    "name": "apy",
                    "dataType": ["number"],
                    "description": "Annual percentage yield"
                },
                {
                    "name": "rewards",
                    "dataType": ["number"],
                    "description": "Staking rewards"
                },
                {
                    "name": "status",
                    "dataType": ["string"],
                    "description": "Staking status"
                },
                {
                    "name": "start_time",
                    "dataType": ["date"],
                    "description": "Staking start time"
                },
                {
                    "name": "end_time",
                    "dataType": ["date"],
                    "description": "Staking end time"
                },
                {
                    "name": "created_at",
                    "dataType": ["date"],
                    "description": "Staking creation timestamp"
                }
            ]
        }
        
        self.client.schema.create_class(staking_class)
        
        print("✅ 质押向量类创建完成")
    
    def create_liquidity_vector_class(self):
        """创建流动性向量类"""
        print("🌾 创建流动性向量类...")
        
        class_name = "BlockchainLiquidity"
        
        if self.client.schema.exists(class_name):
            self.client.schema.delete_class(class_name)
        
        liquidity_class = {
            "class": class_name,
            "description": "Liquidity vector representation",
            "vectorizer": "text2vec-openai",
            "properties": [
                {
                    "name": "liquidity_id",
                    "dataType": ["string"],
                    "description": "Unique liquidity identifier"
                },
                {
                    "name": "provider_address",
                    "dataType": ["string"],
                    "description": "Liquidity provider address"
                },
                {
                    "name": "pool_address",
                    "dataType": ["string"],
                    "description": "Liquidity pool address"
                },
                {
                    "name": "token_a_address",
                    "dataType": ["string"],
                    "description": "Token A address"
                },
                {
                    "name": "token_b_address",
                    "dataType": ["string"],
                    "description": "Token B address"
                },
                {
                    "name": "liquidity_amount",
                    "dataType": ["number"],
                    "description": "Liquidity amount"
                },
                {
                    "name": "lp_tokens",
                    "dataType": ["number"],
                    "description": "LP tokens amount"
                },
                {
                    "name": "farming_rewards",
                    "dataType": ["number"],
                    "description": "Farming rewards"
                },
                {
                    "name": "apy",
                    "dataType": ["number"],
                    "description": "Annual percentage yield"
                },
                {
                    "name": "is_active",
                    "dataType": ["boolean"],
                    "description": "Whether liquidity is active"
                },
                {
                    "name": "created_at",
                    "dataType": ["date"],
                    "description": "Liquidity creation timestamp"
                }
            ]
        }
        
        self.client.schema.create_class(liquidity_class)
        
        print("✅ 流动性向量类创建完成")
    
    def create_cross_chain_vector_class(self):
        """创建跨链向量类"""
        print("🌉 创建跨链向量类...")
        
        class_name = "BlockchainCrossChain"
        
        if self.client.schema.exists(class_name):
            self.client.schema.delete_class(class_name)
        
        cross_chain_class = {
            "class": class_name,
            "description": "Cross-chain vector representation",
            "vectorizer": "text2vec-openai",
            "properties": [
                {
                    "name": "bridge_id",
                    "dataType": ["string"],
                    "description": "Unique bridge identifier"
                },
                {
                    "name": "source_chain",
                    "dataType": ["string"],
                    "description": "Source blockchain"
                },
                {
                    "name": "target_chain",
                    "dataType": ["string"],
                    "description": "Target blockchain"
                },
                {
                    "name": "bridge_contract",
                    "dataType": ["string"],
                    "description": "Bridge contract address"
                },
                {
                    "name": "token_address",
                    "dataType": ["string"],
                    "description": "Token contract address"
                },
                {
                    "name": "amount",
                    "dataType": ["number"],
                    "description": "Bridge amount"
                },
                {
                    "name": "transaction_hash",
                    "dataType": ["string"],
                    "description": "Bridge transaction hash"
                },
                {
                    "name": "bridge_fee",
                    "dataType": ["number"],
                    "description": "Bridge fee"
                },
                {
                    "name": "status",
                    "dataType": ["string"],
                    "description": "Bridge status"
                },
                {
                    "name": "created_at",
                    "dataType": ["date"],
                    "description": "Bridge creation timestamp"
                },
                {
                    "name": "completed_at",
                    "dataType": ["date"],
                    "description": "Bridge completion timestamp"
                }
            ]
        }
        
        self.client.schema.create_class(cross_chain_class)
        
        print("✅ 跨链向量类创建完成")
    
    def verify_vector_structure(self):
        """验证向量数据库结构"""
        try:
            print("🔍 验证区块链版Weaviate向量数据库结构...")
            
            # 获取所有类
            schema = self.client.schema.get()
            classes = schema.get('classes', [])
            blockchain_classes = [cls for cls in classes if cls['class'].startswith('Blockchain')]
            
            print(f"📊 区块链版向量类数量: {len(blockchain_classes)}")
            
            for cls in blockchain_classes:
                class_name = cls['class']
                # 获取类的对象数量
                result = self.client.query.get(class_name, ["_additional { id }"]).with_limit(1000).do()
                object_count = len(result.get('data', {}).get('Get', {}).get(class_name, []))
                print(f"📄 {class_name}: {object_count}个对象")
            
            print("✅ 区块链版Weaviate向量数据库结构验证完成")
            return True
            
        except Exception as e:
            print(f"❌ 验证区块链版Weaviate向量数据库结构失败: {e}")
            return False

def main():
    """主函数"""
    print("🚀 开始区块链版Weaviate数据库结构配置...")
    
    # 创建Weaviate管理器
    weaviate_manager = BlockchainWeaviateManager()
    
    # 测试连接
    if not weaviate_manager.test_connection():
        print("❌ Weaviate连接失败，退出程序")
        return False
    
    # 设置向量数据库结构
    if not weaviate_manager.setup_blockchain_vector_structure():
        print("❌ 设置向量数据库结构失败")
        return False
    
    # 验证向量数据库结构
    if not weaviate_manager.verify_vector_structure():
        print("❌ 验证向量数据库结构失败")
        return False
    
    print("🎉 区块链版Weaviate数据库结构配置完成!")
    return True

if __name__ == "__main__":
    main()
