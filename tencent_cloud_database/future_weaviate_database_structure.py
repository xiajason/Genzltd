#!/usr/bin/env python3
"""
Future版Weaviate向量数据库结构创建脚本
版本: V1.0
日期: 2025年10月5日
描述: 创建Future版完整的Weaviate向量数据库结构和类 (向量搜索)
"""

import weaviate
import json
import numpy as np
from datetime import datetime
from typing import Dict, List, Any

class FutureWeaviateDatabaseCreator:
    """Future版Weaviate向量数据库结构创建器"""
    
    def __init__(self, url="http://localhost:8080", api_key=None):
        """初始化Weaviate连接"""
        if api_key:
            self.client = weaviate.Client(
                url=url,
                auth_client_secret=weaviate.AuthApiKey(api_key=api_key)
            )
        else:
            self.client = weaviate.Client(url=url)
        
        self.schema_name = "JobFirstFuture"
    
    def test_connection(self):
        """测试Weaviate连接"""
        try:
            # 获取集群信息
            cluster_info = self.client.cluster.get_nodes_status()
            print("✅ Weaviate连接测试成功")
            print(f"  节点数量: {len(cluster_info)}")
            return True
        except Exception as e:
            print(f"❌ Weaviate连接测试失败: {e}")
            return False
    
    def create_database_structure(self):
        """创建Weaviate数据库结构"""
        print("🚀 开始创建Future版Weaviate向量数据库结构...")
        
        # 1. 创建用户类
        self._create_user_class()
        
        # 2. 创建简历类
        self._create_resume_class()
        
        # 3. 创建职位类
        self._create_job_class()
        
        # 4. 创建公司类
        self._create_company_class()
        
        # 5. 创建技能类
        self._create_skill_class()
        
        # 6. 创建项目类
        self._create_project_class()
        
        # 7. 插入示例数据
        self._insert_sample_data()
        
        print("✅ Weaviate数据库结构创建完成")
    
    def _create_user_class(self):
        """创建用户类"""
        print("📝 创建用户类...")
        
        user_schema = {
            "class": "User",
            "description": "User profiles with vector embeddings",
            "vectorizer": "text2vec-openai",
            "moduleConfig": {
                "text2vec-openai": {
                    "model": "ada",
                    "modelVersion": "002",
                    "type": "text"
                }
            },
            "properties": [
                {
                    "name": "user_id",
                    "dataType": ["int"],
                    "description": "Unique user identifier"
                },
                {
                    "name": "username",
                    "dataType": ["string"],
                    "description": "Username"
                },
                {
                    "name": "email",
                    "dataType": ["string"],
                    "description": "Email address"
                },
                {
                    "name": "first_name",
                    "dataType": ["string"],
                    "description": "First name"
                },
                {
                    "name": "last_name",
                    "dataType": ["string"],
                    "description": "Last name"
                },
                {
                    "name": "bio",
                    "dataType": ["text"],
                    "description": "User biography"
                },
                {
                    "name": "location",
                    "dataType": ["string"],
                    "description": "User location"
                },
                {
                    "name": "skills",
                    "dataType": ["string[]"],
                    "description": "User skills"
                },
                {
                    "name": "experience_years",
                    "dataType": ["int"],
                    "description": "Years of experience"
                },
                {
                    "name": "role",
                    "dataType": ["string"],
                    "description": "User role"
                },
                {
                    "name": "created_at",
                    "dataType": ["date"],
                    "description": "Creation timestamp"
                }
            ]
        }
        
        # 删除已存在的类
        if self.client.schema.exists("User"):
            self.client.schema.delete_class("User")
        
        # 创建类
        self.client.schema.create_class(user_schema)
        print("✅ 用户类创建完成")
    
    def _create_resume_class(self):
        """创建简历类"""
        print("📝 创建简历类...")
        
        resume_schema = {
            "class": "Resume",
            "description": "Resume documents with vector embeddings",
            "vectorizer": "text2vec-openai",
            "moduleConfig": {
                "text2vec-openai": {
                    "model": "ada",
                    "modelVersion": "002",
                    "type": "text"
                }
            },
            "properties": [
                {
                    "name": "resume_id",
                    "dataType": ["int"],
                    "description": "Unique resume identifier"
                },
                {
                    "name": "user_id",
                    "dataType": ["int"],
                    "description": "Owner user ID"
                },
                {
                    "name": "title",
                    "dataType": ["string"],
                    "description": "Resume title"
                },
                {
                    "name": "summary",
                    "dataType": ["text"],
                    "description": "Resume summary"
                },
                {
                    "name": "content",
                    "dataType": ["text"],
                    "description": "Full resume content"
                },
                {
                    "name": "skills",
                    "dataType": ["string[]"],
                    "description": "Required skills"
                },
                {
                    "name": "experience_years",
                    "dataType": ["int"],
                    "description": "Years of experience"
                },
                {
                    "name": "education",
                    "dataType": ["text"],
                    "description": "Education background"
                },
                {
                    "name": "projects",
                    "dataType": ["text"],
                    "description": "Project experience"
                },
                {
                    "name": "is_public",
                    "dataType": ["boolean"],
                    "description": "Public visibility"
                },
                {
                    "name": "created_at",
                    "dataType": ["date"],
                    "description": "Creation timestamp"
                }
            ]
        }
        
        # 删除已存在的类
        if self.client.schema.exists("Resume"):
            self.client.schema.delete_class("Resume")
        
        # 创建类
        self.client.schema.create_class(resume_schema)
        print("✅ 简历类创建完成")
    
    def _create_job_class(self):
        """创建职位类"""
        print("📝 创建职位类...")
        
        job_schema = {
            "class": "Job",
            "description": "Job postings with vector embeddings",
            "vectorizer": "text2vec-openai",
            "moduleConfig": {
                "text2vec-openai": {
                    "model": "ada",
                    "modelVersion": "002",
                    "type": "text"
                }
            },
            "properties": [
                {
                    "name": "job_id",
                    "dataType": ["int"],
                    "description": "Unique job identifier"
                },
                {
                    "name": "company_id",
                    "dataType": ["int"],
                    "description": "Company ID"
                },
                {
                    "name": "title",
                    "dataType": ["string"],
                    "description": "Job title"
                },
                {
                    "name": "description",
                    "dataType": ["text"],
                    "description": "Job description"
                },
                {
                    "name": "requirements",
                    "dataType": ["text"],
                    "description": "Job requirements"
                },
                {
                    "name": "skills_required",
                    "dataType": ["string[]"],
                    "description": "Required skills"
                },
                {
                    "name": "location",
                    "dataType": ["string"],
                    "description": "Job location"
                },
                {
                    "name": "employment_type",
                    "dataType": ["string"],
                    "description": "Employment type"
                },
                {
                    "name": "salary_range",
                    "dataType": ["string"],
                    "description": "Salary range"
                },
                {
                    "name": "experience_level",
                    "dataType": ["string"],
                    "description": "Experience level required"
                },
                {
                    "name": "remote_allowed",
                    "dataType": ["boolean"],
                    "description": "Remote work allowed"
                },
                {
                    "name": "company_name",
                    "dataType": ["string"],
                    "description": "Company name"
                },
                {
                    "name": "industry",
                    "dataType": ["string"],
                    "description": "Industry"
                },
                {
                    "name": "created_at",
                    "dataType": ["date"],
                    "description": "Creation timestamp"
                }
            ]
        }
        
        # 删除已存在的类
        if self.client.schema.exists("Job"):
            self.client.schema.delete_class("Job")
        
        # 创建类
        self.client.schema.create_class(job_schema)
        print("✅ 职位类创建完成")
    
    def _create_company_class(self):
        """创建公司类"""
        print("📝 创建公司类...")
        
        company_schema = {
            "class": "Company",
            "description": "Company profiles with vector embeddings",
            "vectorizer": "text2vec-openai",
            "moduleConfig": {
                "text2vec-openai": {
                    "model": "ada",
                    "modelVersion": "002",
                    "type": "text"
                }
            },
            "properties": [
                {
                    "name": "company_id",
                    "dataType": ["int"],
                    "description": "Unique company identifier"
                },
                {
                    "name": "name",
                    "dataType": ["string"],
                    "description": "Company name"
                },
                {
                    "name": "description",
                    "dataType": ["text"],
                    "description": "Company description"
                },
                {
                    "name": "industry",
                    "dataType": ["string"],
                    "description": "Industry"
                },
                {
                    "name": "size",
                    "dataType": ["string"],
                    "description": "Company size"
                },
                {
                    "name": "location",
                    "dataType": ["string"],
                    "description": "Company location"
                },
                {
                    "name": "website",
                    "dataType": ["string"],
                    "description": "Company website"
                },
                {
                    "name": "founded_year",
                    "dataType": ["int"],
                    "description": "Founded year"
                },
                {
                    "name": "employee_count",
                    "dataType": ["int"],
                    "description": "Employee count"
                },
                {
                    "name": "is_verified",
                    "dataType": ["boolean"],
                    "description": "Verification status"
                },
                {
                    "name": "created_at",
                    "dataType": ["date"],
                    "description": "Creation timestamp"
                }
            ]
        }
        
        # 删除已存在的类
        if self.client.schema.exists("Company"):
            self.client.schema.delete_class("Company")
        
        # 创建类
        self.client.schema.create_class(company_schema)
        print("✅ 公司类创建完成")
    
    def _create_skill_class(self):
        """创建技能类"""
        print("📝 创建技能类...")
        
        skill_schema = {
            "class": "Skill",
            "description": "Skills with vector embeddings",
            "vectorizer": "text2vec-openai",
            "moduleConfig": {
                "text2vec-openai": {
                    "model": "ada",
                    "modelVersion": "002",
                    "type": "text"
                }
            },
            "properties": [
                {
                    "name": "skill_id",
                    "dataType": ["int"],
                    "description": "Unique skill identifier"
                },
                {
                    "name": "name",
                    "dataType": ["string"],
                    "description": "Skill name"
                },
                {
                    "name": "category",
                    "dataType": ["string"],
                    "description": "Skill category"
                },
                {
                    "name": "description",
                    "dataType": ["text"],
                    "description": "Skill description"
                },
                {
                    "name": "level",
                    "dataType": ["string"],
                    "description": "Skill level"
                },
                {
                    "name": "related_skills",
                    "dataType": ["string[]"],
                    "description": "Related skills"
                },
                {
                    "name": "popularity_score",
                    "dataType": ["number"],
                    "description": "Popularity score"
                },
                {
                    "name": "created_at",
                    "dataType": ["date"],
                    "description": "Creation timestamp"
                }
            ]
        }
        
        # 删除已存在的类
        if self.client.schema.exists("Skill"):
            self.client.schema.delete_class("Skill")
        
        # 创建类
        self.client.schema.create_class(skill_schema)
        print("✅ 技能类创建完成")
    
    def _create_project_class(self):
        """创建项目类"""
        print("📝 创建项目类...")
        
        project_schema = {
            "class": "Project",
            "description": "Projects with vector embeddings",
            "vectorizer": "text2vec-openai",
            "moduleConfig": {
                "text2vec-openai": {
                    "model": "ada",
                    "modelVersion": "002",
                    "type": "text"
                }
            },
            "properties": [
                {
                    "name": "project_id",
                    "dataType": ["int"],
                    "description": "Unique project identifier"
                },
                {
                    "name": "user_id",
                    "dataType": ["int"],
                    "description": "Owner user ID"
                },
                {
                    "name": "name",
                    "dataType": ["string"],
                    "description": "Project name"
                },
                {
                    "name": "description",
                    "dataType": ["text"],
                    "description": "Project description"
                },
                {
                    "name": "technologies",
                    "dataType": ["string[]"],
                    "description": "Technologies used"
                },
                {
                    "name": "github_url",
                    "dataType": ["string"],
                    "description": "GitHub repository URL"
                },
                {
                    "name": "project_url",
                    "dataType": ["string"],
                    "description": "Project URL"
                },
                {
                    "name": "start_date",
                    "dataType": ["date"],
                    "description": "Project start date"
                },
                {
                    "name": "end_date",
                    "dataType": ["date"],
                    "description": "Project end date"
                },
                {
                    "name": "is_public",
                    "dataType": ["boolean"],
                    "description": "Public visibility"
                },
                {
                    "name": "created_at",
                    "dataType": ["date"],
                    "description": "Creation timestamp"
                }
            ]
        }
        
        # 删除已存在的类
        if self.client.schema.exists("Project"):
            self.client.schema.delete_class("Project")
        
        # 创建类
        self.client.schema.create_class(project_schema)
        print("✅ 项目类创建完成")
    
    def _insert_sample_data(self):
        """插入示例数据"""
        print("📝 插入示例数据...")
        
        # 插入用户数据
        user_data = {
            "user_id": 1,
            "username": "testuser",
            "email": "test@example.com",
            "first_name": "Test",
            "last_name": "User",
            "bio": "Software developer with 5+ years of experience in Python and JavaScript",
            "location": "San Francisco, CA",
            "skills": ["Python", "JavaScript", "React", "Node.js"],
            "experience_years": 5,
            "role": "user",
            "created_at": datetime.now().isoformat()
        }
        
        self.client.data_object.create(
            data_object=user_data,
            class_name="User"
        )
        
        # 插入简历数据
        resume_data = {
            "resume_id": 1,
            "user_id": 1,
            "title": "Senior Software Engineer Resume",
            "summary": "Experienced software engineer with expertise in Python, JavaScript, and React",
            "content": "Full resume content with detailed experience and skills...",
            "skills": ["Python", "JavaScript", "React", "Node.js", "PostgreSQL"],
            "experience_years": 5,
            "education": "Bachelor of Computer Science from UC Berkeley",
            "projects": "Built multiple web applications using React and Node.js",
            "is_public": True,
            "created_at": datetime.now().isoformat()
        }
        
        self.client.data_object.create(
            data_object=resume_data,
            class_name="Resume"
        )
        
        # 插入职位数据
        job_data = {
            "job_id": 1,
            "company_id": 1,
            "title": "Senior Software Engineer",
            "description": "We are looking for a senior software engineer to join our team. The ideal candidate will have experience with Python, JavaScript, and React.",
            "requirements": "5+ years of experience with Python and JavaScript, experience with React and Node.js",
            "skills_required": ["Python", "JavaScript", "React", "Node.js"],
            "location": "San Francisco, CA",
            "employment_type": "full-time",
            "salary_range": "$120,000 - $180,000",
            "experience_level": "senior",
            "remote_allowed": True,
            "company_name": "TechCorp Inc.",
            "industry": "Technology",
            "created_at": datetime.now().isoformat()
        }
        
        self.client.data_object.create(
            data_object=job_data,
            class_name="Job"
        )
        
        # 插入公司数据
        company_data = {
            "company_id": 1,
            "name": "TechCorp Inc.",
            "description": "Leading technology company specializing in software development and AI solutions",
            "industry": "Technology",
            "size": "large",
            "location": "San Francisco, CA",
            "website": "https://techcorp.com",
            "founded_year": 2010,
            "employee_count": 1000,
            "is_verified": True,
            "created_at": datetime.now().isoformat()
        }
        
        self.client.data_object.create(
            data_object=company_data,
            class_name="Company"
        )
        
        # 插入技能数据
        skills_data = [
            {
                "skill_id": 1,
                "name": "Python",
                "category": "Programming Language",
                "description": "High-level programming language for general-purpose programming",
                "level": "expert",
                "related_skills": ["Django", "Flask", "Pandas", "NumPy"],
                "popularity_score": 0.95,
                "created_at": datetime.now().isoformat()
            },
            {
                "skill_id": 2,
                "name": "JavaScript",
                "category": "Programming Language",
                "description": "Dynamic programming language for web development",
                "level": "advanced",
                "related_skills": ["React", "Node.js", "Vue.js", "Angular"],
                "popularity_score": 0.90,
                "created_at": datetime.now().isoformat()
            }
        ]
        
        for skill in skills_data:
            self.client.data_object.create(
                data_object=skill,
                class_name="Skill"
            )
        
        print("✅ 示例数据插入完成")
    
    def verify_structure(self):
        """验证Weaviate结构"""
        print("🔍 验证Weaviate数据库结构...")
        
        verification_results = {}
        
        # 检查所有类
        classes = ["User", "Resume", "Job", "Company", "Skill", "Project"]
        
        for class_name in classes:
            try:
                # 获取类信息
                class_info = self.client.schema.get(class_name)
                
                # 获取对象数量
                result = self.client.query.get(class_name).with_meta_count().do()
                object_count = result.get('data', {}).get('Get', {}).get(class_name, [])
                count = len(object_count) if isinstance(object_count, list) else 0
                
                # 获取属性数量
                properties = class_info.get('properties', [])
                property_count = len(properties)
                
                verification_results[class_name] = {
                    'exists': True,
                    'object_count': count,
                    'property_count': property_count
                }
                
            except Exception as e:
                verification_results[class_name] = {
                    'exists': False,
                    'object_count': 0,
                    'property_count': 0,
                    'error': str(e)
                }
        
        print("📊 Weaviate结构验证结果:")
        for class_name, results in verification_results.items():
            status = "✅" if results['exists'] else "❌"
            print(f"  {status} {class_name}: {results['object_count']} 对象, {results['property_count']} 属性")
            if 'error' in results:
                print(f"    错误: {results['error']}")
        
        return verification_results

def main():
    """主函数"""
    print("🎯 Future版Weaviate向量数据库结构创建脚本")
    print("=" * 50)
    
    # 创建Weaviate数据库创建器
    creator = FutureWeaviateDatabaseCreator()
    
    # 测试连接
    if not creator.test_connection():
        print("❌ 无法连接到Weaviate服务器，请检查Weaviate是否运行")
        return
    
    # 创建数据库结构
    creator.create_database_structure()
    
    # 验证结构
    verification_results = creator.verify_structure()
    
    print(f"\n🎉 Future版Weaviate向量数据库结构创建完成！")
    print(f"📊 创建统计:")
    total_objects = sum(results['object_count'] for results in verification_results.values())
    total_classes = len([name for name, results in verification_results.items() if results['exists']])
    print(f"  - 类数量: {total_classes} 个")
    print(f"  - 总对象数: {total_objects} 个")

if __name__ == "__main__":
    main()
