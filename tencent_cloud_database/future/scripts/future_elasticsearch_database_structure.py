#!/usr/bin/env python3
"""
Future版Elasticsearch索引结构创建脚本
版本: V1.0
日期: 2025年10月5日
描述: 创建Future版完整的Elasticsearch索引结构和映射 (全文搜索)
"""

from elasticsearch import Elasticsearch
import json
from datetime import datetime
from typing import Dict, List, Any

class FutureElasticsearchDatabaseCreator:
    """Future版Elasticsearch索引结构创建器"""
    
    def __init__(self, host='localhost', port=9200, username=None, password=None):
        """初始化Elasticsearch连接"""
        if username and password:
            self.es = Elasticsearch(
                [{'host': host, 'port': port}],
                http_auth=(username, password),
                verify_certs=False
            )
        else:
            self.es = Elasticsearch([{'host': host, 'port': port}])
        
        self.index_prefix = "jobfirst_future"
    
    def test_connection(self):
        """测试Elasticsearch连接"""
        try:
            info = self.es.info()
            print("✅ Elasticsearch连接测试成功")
            print(f"  版本: {info['version']['number']}")
            print(f"  集群名称: {info['cluster_name']}")
            return True
        except Exception as e:
            print(f"❌ Elasticsearch连接测试失败: {e}")
            return False
    
    def create_index_structures(self):
        """创建Elasticsearch索引结构"""
        print("🚀 开始创建Future版Elasticsearch索引结构...")
        
        # 1. 创建用户索引
        self._create_users_index()
        
        # 2. 创建简历索引
        self._create_resumes_index()
        
        # 3. 创建职位索引
        self._create_jobs_index()
        
        # 4. 创建公司索引
        self._create_companies_index()
        
        # 5. 创建技能索引
        self._create_skills_index()
        
        # 6. 创建搜索索引
        self._create_search_index()
        
        print("✅ Elasticsearch索引结构创建完成")
    
    def _create_users_index(self):
        """创建用户索引"""
        print("📝 创建用户索引...")
        
        index_name = f"{self.index_prefix}_users"
        
        # 用户索引映射
        mapping = {
            "mappings": {
                "properties": {
                    "id": {"type": "long"},
                    "username": {
                        "type": "text",
                        "analyzer": "standard",
                        "fields": {
                            "keyword": {"type": "keyword"}
                        }
                    },
                    "email": {
                        "type": "text",
                        "analyzer": "standard",
                        "fields": {
                            "keyword": {"type": "keyword"}
                        }
                    },
                    "first_name": {
                        "type": "text",
                        "analyzer": "standard",
                        "fields": {
                            "keyword": {"type": "keyword"}
                        }
                    },
                    "last_name": {
                        "type": "text",
                        "analyzer": "standard",
                        "fields": {
                            "keyword": {"type": "keyword"}
                        }
                    },
                    "full_name": {
                        "type": "text",
                        "analyzer": "standard"
                    },
                    "bio": {
                        "type": "text",
                        "analyzer": "standard"
                    },
                    "location": {
                        "type": "text",
                        "analyzer": "standard",
                        "fields": {
                            "keyword": {"type": "keyword"}
                        }
                    },
                    "skills": {
                        "type": "text",
                        "analyzer": "standard",
                        "fields": {
                            "keyword": {"type": "keyword"}
                        }
                    },
                    "experience_years": {"type": "integer"},
                    "role": {
                        "type": "keyword"
                    },
                    "status": {
                        "type": "keyword"
                    },
                    "created_at": {"type": "date"},
                    "updated_at": {"type": "date"}
                }
            },
            "settings": {
                "number_of_shards": 1,
                "number_of_replicas": 0,
                "analysis": {
                    "analyzer": {
                        "custom_analyzer": {
                            "type": "custom",
                            "tokenizer": "standard",
                            "filter": ["lowercase", "stop"]
                        }
                    }
                }
            }
        }
        
        # 创建索引
        if not self.es.indices.exists(index=index_name):
            self.es.indices.create(index=index_name, body=mapping)
            print(f"✅ 用户索引创建完成: {index_name}")
        else:
            print(f"ℹ️ 用户索引已存在: {index_name}")
        
        # 插入示例数据
        self._insert_sample_users(index_name)
    
    def _create_resumes_index(self):
        """创建简历索引"""
        print("📝 创建简历索引...")
        
        index_name = f"{self.index_prefix}_resumes"
        
        # 简历索引映射
        mapping = {
            "mappings": {
                "properties": {
                    "id": {"type": "long"},
                    "user_id": {"type": "long"},
                    "title": {
                        "type": "text",
                        "analyzer": "standard"
                    },
                    "summary": {
                        "type": "text",
                        "analyzer": "standard"
                    },
                    "content": {
                        "type": "text",
                        "analyzer": "standard"
                    },
                    "skills": {
                        "type": "text",
                        "analyzer": "standard",
                        "fields": {
                            "keyword": {"type": "keyword"}
                        }
                    },
                    "experience": {
                        "type": "nested",
                        "properties": {
                            "company": {"type": "text"},
                            "position": {"type": "text"},
                            "duration": {"type": "text"},
                            "description": {"type": "text"}
                        }
                    },
                    "education": {
                        "type": "nested",
                        "properties": {
                            "institution": {"type": "text"},
                            "degree": {"type": "text"},
                            "field": {"type": "text"},
                            "year": {"type": "integer"}
                        }
                    },
                    "projects": {
                        "type": "nested",
                        "properties": {
                            "name": {"type": "text"},
                            "description": {"type": "text"},
                            "technologies": {"type": "keyword"}
                        }
                    },
                    "experience_years": {"type": "integer"},
                    "is_public": {"type": "boolean"},
                    "view_count": {"type": "integer"},
                    "created_at": {"type": "date"},
                    "updated_at": {"type": "date"}
                }
            },
            "settings": {
                "number_of_shards": 1,
                "number_of_replicas": 0
            }
        }
        
        # 创建索引
        if not self.es.indices.exists(index=index_name):
            self.es.indices.create(index=index_name, body=mapping)
            print(f"✅ 简历索引创建完成: {index_name}")
        else:
            print(f"ℹ️ 简历索引已存在: {index_name}")
        
        # 插入示例数据
        self._insert_sample_resumes(index_name)
    
    def _create_jobs_index(self):
        """创建职位索引"""
        print("📝 创建职位索引...")
        
        index_name = f"{self.index_prefix}_jobs"
        
        # 职位索引映射
        mapping = {
            "mappings": {
                "properties": {
                    "id": {"type": "long"},
                    "company_id": {"type": "long"},
                    "title": {
                        "type": "text",
                        "analyzer": "standard"
                    },
                    "description": {
                        "type": "text",
                        "analyzer": "standard"
                    },
                    "requirements": {
                        "type": "text",
                        "analyzer": "standard"
                    },
                    "skills_required": {
                        "type": "text",
                        "analyzer": "standard",
                        "fields": {
                            "keyword": {"type": "keyword"}
                        }
                    },
                    "location": {
                        "type": "text",
                        "analyzer": "standard",
                        "fields": {
                            "keyword": {"type": "keyword"}
                        }
                    },
                    "employment_type": {
                        "type": "keyword"
                    },
                    "salary_range": {
                        "type": "text"
                    },
                    "experience_level": {
                        "type": "keyword"
                    },
                    "remote_allowed": {"type": "boolean"},
                    "company_name": {
                        "type": "text",
                        "analyzer": "standard"
                    },
                    "industry": {
                        "type": "keyword"
                    },
                    "status": {
                        "type": "keyword"
                    },
                    "created_at": {"type": "date"},
                    "updated_at": {"type": "date"}
                }
            },
            "settings": {
                "number_of_shards": 1,
                "number_of_replicas": 0
            }
        }
        
        # 创建索引
        if not self.es.indices.exists(index=index_name):
            self.es.indices.create(index=index_name, body=mapping)
            print(f"✅ 职位索引创建完成: {index_name}")
        else:
            print(f"ℹ️ 职位索引已存在: {index_name}")
        
        # 插入示例数据
        self._insert_sample_jobs(index_name)
    
    def _create_companies_index(self):
        """创建公司索引"""
        print("📝 创建公司索引...")
        
        index_name = f"{self.index_prefix}_companies"
        
        # 公司索引映射
        mapping = {
            "mappings": {
                "properties": {
                    "id": {"type": "long"},
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
                    "industry": {
                        "type": "keyword"
                    },
                    "size": {
                        "type": "keyword"
                    },
                    "location": {
                        "type": "text",
                        "analyzer": "standard",
                        "fields": {
                            "keyword": {"type": "keyword"}
                        }
                    },
                    "website": {
                        "type": "keyword"
                    },
                    "founded_year": {"type": "integer"},
                    "employee_count": {"type": "integer"},
                    "is_verified": {"type": "boolean"},
                    "created_at": {"type": "date"},
                    "updated_at": {"type": "date"}
                }
            },
            "settings": {
                "number_of_shards": 1,
                "number_of_replicas": 0
            }
        }
        
        # 创建索引
        if not self.es.indices.exists(index=index_name):
            self.es.indices.create(index=index_name, body=mapping)
            print(f"✅ 公司索引创建完成: {index_name}")
        else:
            print(f"ℹ️ 公司索引已存在: {index_name}")
        
        # 插入示例数据
        self._insert_sample_companies(index_name)
    
    def _create_skills_index(self):
        """创建技能索引"""
        print("📝 创建技能索引...")
        
        index_name = f"{self.index_prefix}_skills"
        
        # 技能索引映射
        mapping = {
            "mappings": {
                "properties": {
                    "id": {"type": "long"},
                    "name": {
                        "type": "text",
                        "analyzer": "standard",
                        "fields": {
                            "keyword": {"type": "keyword"}
                        }
                    },
                    "category": {
                        "type": "keyword"
                    },
                    "description": {
                        "type": "text",
                        "analyzer": "standard"
                    },
                    "level": {
                        "type": "keyword"
                    },
                    "related_skills": {
                        "type": "keyword"
                    },
                    "popularity_score": {"type": "float"},
                    "created_at": {"type": "date"},
                    "updated_at": {"type": "date"}
                }
            },
            "settings": {
                "number_of_shards": 1,
                "number_of_replicas": 0
            }
        }
        
        # 创建索引
        if not self.es.indices.exists(index=index_name):
            self.es.indices.create(index=index_name, body=mapping)
            print(f"✅ 技能索引创建完成: {index_name}")
        else:
            print(f"ℹ️ 技能索引已存在: {index_name}")
        
        # 插入示例数据
        self._insert_sample_skills(index_name)
    
    def _create_search_index(self):
        """创建搜索索引"""
        print("📝 创建搜索索引...")
        
        index_name = f"{self.index_prefix}_search"
        
        # 搜索索引映射
        mapping = {
            "mappings": {
                "properties": {
                    "id": {"type": "long"},
                    "type": {
                        "type": "keyword"
                    },
                    "title": {
                        "type": "text",
                        "analyzer": "standard"
                    },
                    "content": {
                        "type": "text",
                        "analyzer": "standard"
                    },
                    "tags": {
                        "type": "keyword"
                    },
                    "category": {
                        "type": "keyword"
                    },
                    "user_id": {"type": "long"},
                    "created_at": {"type": "date"},
                    "updated_at": {"type": "date"}
                }
            },
            "settings": {
                "number_of_shards": 1,
                "number_of_replicas": 0
            }
        }
        
        # 创建索引
        if not self.es.indices.exists(index=index_name):
            self.es.indices.create(index=index_name, body=mapping)
            print(f"✅ 搜索索引创建完成: {index_name}")
        else:
            print(f"ℹ️ 搜索索引已存在: {index_name}")
    
    def _insert_sample_users(self, index_name):
        """插入示例用户数据"""
        users_data = [
            {
                "id": 1,
                "username": "testuser",
                "email": "test@example.com",
                "first_name": "Test",
                "last_name": "User",
                "full_name": "Test User",
                "bio": "Software developer with 5+ years of experience",
                "location": "San Francisco, CA",
                "skills": ["Python", "JavaScript", "React", "Node.js"],
                "experience_years": 5,
                "role": "user",
                "status": "active",
                "created_at": datetime.now().isoformat(),
                "updated_at": datetime.now().isoformat()
            },
            {
                "id": 2,
                "username": "admin",
                "email": "admin@example.com",
                "first_name": "Admin",
                "last_name": "User",
                "full_name": "Admin User",
                "bio": "System administrator",
                "location": "New York, NY",
                "skills": ["System Administration", "Security", "Networking"],
                "experience_years": 8,
                "role": "admin",
                "status": "active",
                "created_at": datetime.now().isoformat(),
                "updated_at": datetime.now().isoformat()
            }
        ]
        
        for user in users_data:
            self.es.index(index=index_name, id=user["id"], body=user)
    
    def _insert_sample_resumes(self, index_name):
        """插入示例简历数据"""
        resumes_data = [
            {
                "id": 1,
                "user_id": 1,
                "title": "Senior Software Engineer Resume",
                "summary": "Experienced software engineer with expertise in Python, JavaScript, and React",
                "content": "Full resume content here...",
                "skills": ["Python", "JavaScript", "React", "Node.js", "PostgreSQL"],
                "experience": [
                    {
                        "company": "TechCorp Inc.",
                        "position": "Senior Software Engineer",
                        "duration": "2020-2023",
                        "description": "Led development of microservices architecture"
                    }
                ],
                "education": [
                    {
                        "institution": "University of California",
                        "degree": "Bachelor of Computer Science",
                        "field": "Computer Science",
                        "year": 2018
                    }
                ],
                "projects": [
                    {
                        "name": "E-commerce Platform",
                        "description": "Built a full-stack e-commerce platform",
                        "technologies": ["React", "Node.js", "PostgreSQL"]
                    }
                ],
                "experience_years": 5,
                "is_public": True,
                "view_count": 25,
                "created_at": datetime.now().isoformat(),
                "updated_at": datetime.now().isoformat()
            }
        ]
        
        for resume in resumes_data:
            self.es.index(index=index_name, id=resume["id"], body=resume)
    
    def _insert_sample_jobs(self, index_name):
        """插入示例职位数据"""
        jobs_data = [
            {
                "id": 1,
                "company_id": 1,
                "title": "Senior Software Engineer",
                "description": "We are looking for a senior software engineer to join our team...",
                "requirements": "5+ years of experience with Python and JavaScript",
                "skills_required": ["Python", "JavaScript", "React", "Node.js"],
                "location": "San Francisco, CA",
                "employment_type": "full-time",
                "salary_range": "$120,000 - $180,000",
                "experience_level": "senior",
                "remote_allowed": True,
                "company_name": "TechCorp Inc.",
                "industry": "Technology",
                "status": "active",
                "created_at": datetime.now().isoformat(),
                "updated_at": datetime.now().isoformat()
            }
        ]
        
        for job in jobs_data:
            self.es.index(index=index_name, id=job["id"], body=job)
    
    def _insert_sample_companies(self, index_name):
        """插入示例公司数据"""
        companies_data = [
            {
                "id": 1,
                "name": "TechCorp Inc.",
                "description": "Leading technology company specializing in software development",
                "industry": "Technology",
                "size": "large",
                "location": "San Francisco, CA",
                "website": "https://techcorp.com",
                "founded_year": 2010,
                "employee_count": 1000,
                "is_verified": True,
                "created_at": datetime.now().isoformat(),
                "updated_at": datetime.now().isoformat()
            }
        ]
        
        for company in companies_data:
            self.es.index(index=index_name, id=company["id"], body=company)
    
    def _insert_sample_skills(self, index_name):
        """插入示例技能数据"""
        skills_data = [
            {
                "id": 1,
                "name": "Python",
                "category": "Programming Language",
                "description": "High-level programming language",
                "level": "expert",
                "related_skills": ["Django", "Flask", "Pandas", "NumPy"],
                "popularity_score": 0.95,
                "created_at": datetime.now().isoformat(),
                "updated_at": datetime.now().isoformat()
            },
            {
                "id": 2,
                "name": "JavaScript",
                "category": "Programming Language",
                "description": "Dynamic programming language for web development",
                "level": "advanced",
                "related_skills": ["React", "Node.js", "Vue.js", "Angular"],
                "popularity_score": 0.90,
                "created_at": datetime.now().isoformat(),
                "updated_at": datetime.now().isoformat()
            }
        ]
        
        for skill in skills_data:
            self.es.index(index=index_name, id=skill["id"], body=skill)
    
    def verify_structures(self):
        """验证Elasticsearch结构"""
        print("🔍 验证Elasticsearch索引结构...")
        
        verification_results = {}
        
        # 检查所有索引
        indices = [
            f"{self.index_prefix}_users",
            f"{self.index_prefix}_resumes",
            f"{self.index_prefix}_jobs",
            f"{self.index_prefix}_companies",
            f"{self.index_prefix}_skills",
            f"{self.index_prefix}_search"
        ]
        
        for index_name in indices:
            if self.es.indices.exists(index=index_name):
                # 获取文档数量
                count_result = self.es.count(index=index_name)
                doc_count = count_result['count']
                
                # 获取索引信息
                index_info = self.es.indices.get(index=index_name)
                mapping = index_info[index_name]['mappings']
                
                verification_results[index_name] = {
                    'exists': True,
                    'doc_count': doc_count,
                    'mapping_fields': len(mapping.get('properties', {}))
                }
            else:
                verification_results[index_name] = {
                    'exists': False,
                    'doc_count': 0,
                    'mapping_fields': 0
                }
        
        print("📊 Elasticsearch结构验证结果:")
        for index_name, results in verification_results.items():
            status = "✅" if results['exists'] else "❌"
            print(f"  {status} {index_name}: {results['doc_count']} 文档, {results['mapping_fields']} 字段")
        
        return verification_results

def main():
    """主函数"""
    print("🎯 Future版Elasticsearch索引结构创建脚本")
    print("=" * 50)
    
    # 创建Elasticsearch数据库创建器
    creator = FutureElasticsearchDatabaseCreator()
    
    # 测试连接
    if not creator.test_connection():
        print("❌ 无法连接到Elasticsearch服务器，请检查Elasticsearch是否运行")
        return
    
    # 创建索引结构
    creator.create_index_structures()
    
    # 验证结构
    verification_results = creator.verify_structures()
    
    print(f"\n🎉 Future版Elasticsearch索引结构创建完成！")
    print(f"📊 创建统计:")
    total_docs = sum(results['doc_count'] for results in verification_results.values())
    total_indices = len([name for name, results in verification_results.items() if results['exists']])
    print(f"  - 索引数量: {total_indices} 个")
    print(f"  - 总文档数: {total_docs} 个")

if __name__ == "__main__":
    main()
