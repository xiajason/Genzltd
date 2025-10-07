#!/usr/bin/env python3
"""
Future版Neo4j图数据库结构创建脚本
版本: V1.0
日期: 2025年10月5日
描述: 创建Future版完整的Neo4j图数据库结构和关系网络
"""

from neo4j import GraphDatabase
import json
from datetime import datetime
from typing import Dict, List, Any

class FutureNeo4jDatabaseCreator:
    """Future版Neo4j图数据库结构创建器"""
    
    def __init__(self, uri="bolt://localhost:7687", username="neo4j", password="jobfirst_password_2024"):
        """初始化Neo4j连接"""
        self.driver = GraphDatabase.driver(uri, auth=(username, password))
        self.database_name = "jobfirst_future"
    
    def close(self):
        """关闭数据库连接"""
        self.driver.close()
    
    def test_connection(self):
        """测试Neo4j连接"""
        try:
            with self.driver.session() as session:
                result = session.run("RETURN 1 as test")
                record = result.single()
                if record and record["test"] == 1:
                    print("✅ Neo4j连接测试成功")
                    return True
        except Exception as e:
            print(f"❌ Neo4j连接测试失败: {e}")
            return False
        return False
    
    def create_database_structure(self):
        """创建Neo4j数据库结构"""
        print("🚀 开始创建Future版Neo4j图数据库结构...")
        
        with self.driver.session(database=self.database_name) as session:
            # 1. 创建节点标签和属性
            self._create_node_labels(session)
            
            # 2. 创建关系类型
            self._create_relationship_types(session)
            
            # 3. 创建示例数据
            self._create_sample_data(session)
            
            # 4. 创建索引
            self._create_indexes(session)
            
            # 5. 创建约束
            self._create_constraints(session)
        
        print("✅ Neo4j数据库结构创建完成")
    
    def _create_node_labels(self, session):
        """创建节点标签和属性"""
        print("📝 创建节点标签和属性...")
        
        # 用户节点
        session.run("""
            CREATE (u:User {
                id: $id,
                username: $username,
                email: $email,
                first_name: $first_name,
                last_name: $last_name,
                role: $role,
                created_at: datetime(),
                updated_at: datetime()
            })
        """, {
            "id": 1,
            "username": "testuser",
            "email": "test@example.com",
            "first_name": "Test",
            "last_name": "User",
            "role": "user"
        })
        
        # 公司节点
        session.run("""
            CREATE (c:Company {
                id: $id,
                name: $name,
                industry: $industry,
                size: $size,
                location: $location,
                website: $website,
                created_at: datetime(),
                updated_at: datetime()
            })
        """, {
            "id": 1,
            "name": "TechCorp Inc.",
            "industry": "Technology",
            "size": "large",
            "location": "San Francisco, CA",
            "website": "https://techcorp.com"
        })
        
        # 职位节点
        session.run("""
            CREATE (j:Job {
                id: $id,
                title: $title,
                description: $description,
                location: $location,
                salary_range: $salary_range,
                employment_type: $employment_type,
                created_at: datetime(),
                updated_at: datetime()
            })
        """, {
            "id": 1,
            "title": "Senior Software Engineer",
            "description": "We are looking for a senior software engineer...",
            "location": "San Francisco, CA",
            "salary_range": "$120,000 - $180,000",
            "employment_type": "full-time"
        })
        
        # 技能节点
        session.run("""
            CREATE (s:Skill {
                id: $id,
                name: $name,
                category: $category,
                level: $level,
                created_at: datetime(),
                updated_at: datetime()
            })
        """, {
            "id": 1,
            "name": "Python",
            "category": "Programming Language",
            "level": "expert"
        })
        
        # 简历节点
        session.run("""
            CREATE (r:Resume {
                id: $id,
                title: $title,
                summary: $summary,
                experience_years: $experience_years,
                is_public: $is_public,
                created_at: datetime(),
                updated_at: datetime()
            })
        """, {
            "id": 1,
            "title": "Software Engineer Resume",
            "summary": "Experienced software engineer with 5+ years of experience",
            "experience_years": 5,
            "is_public": True
        })
        
        print("✅ 节点标签和属性创建完成")
    
    def _create_relationship_types(self, session):
        """创建关系类型"""
        print("📝 创建关系类型...")
        
        # 用户-简历关系
        session.run("""
            MATCH (u:User {id: 1}), (r:Resume {id: 1})
            CREATE (u)-[:OWNS]->(r)
        """)
        
        # 用户-技能关系
        session.run("""
            MATCH (u:User {id: 1}), (s:Skill {id: 1})
            CREATE (u)-[:HAS_SKILL {proficiency: 'expert', years_experience: 5}]->(s)
        """)
        
        # 简历-技能关系
        session.run("""
            MATCH (r:Resume {id: 1}), (s:Skill {id: 1})
            CREATE (r)-[:REQUIRES_SKILL {importance: 'high'}]->(s)
        """)
        
        # 公司-职位关系
        session.run("""
            MATCH (c:Company {id: 1}), (j:Job {id: 1})
            CREATE (c)-[:POSTS]->(j)
        """)
        
        # 职位-技能关系
        session.run("""
            MATCH (j:Job {id: 1}), (s:Skill {id: 1})
            CREATE (j)-[:REQUIRES_SKILL {importance: 'high', required: true}]->(s)
        """)
        
        # 用户-职位申请关系
        session.run("""
            MATCH (u:User {id: 1}), (j:Job {id: 1})
            CREATE (u)-[:APPLIED_TO {applied_at: datetime(), status: 'pending'}]->(j)
        """)
        
        # 用户-公司工作关系
        session.run("""
            MATCH (u:User {id: 1}), (c:Company {id: 1})
            CREATE (u)-[:WORKS_AT {position: 'Software Engineer', start_date: date('2020-01-01'), current: true}]->(c)
        """)
        
        # 技能-技能关系（相关技能）
        session.run("""
            MATCH (s1:Skill {id: 1}), (s2:Skill)
            WHERE s2.name = 'JavaScript' AND s2.id <> 1
            CREATE (s1)-[:RELATED_TO {similarity: 0.8}]->(s2)
        """)
        
        print("✅ 关系类型创建完成")
    
    def _create_sample_data(self, session):
        """创建示例数据"""
        print("📝 创建示例数据...")
        
        # 创建更多用户
        users_data = [
            {"id": 2, "username": "admin", "email": "admin@example.com", "first_name": "Admin", "last_name": "User", "role": "admin"},
            {"id": 3, "username": "recruiter", "email": "recruiter@example.com", "first_name": "Jane", "last_name": "Smith", "role": "recruiter"},
            {"id": 4, "username": "developer", "email": "dev@example.com", "first_name": "John", "last_name": "Doe", "role": "user"}
        ]
        
        for user_data in users_data:
            session.run("""
                CREATE (u:User {
                    id: $id,
                    username: $username,
                    email: $email,
                    first_name: $first_name,
                    last_name: $last_name,
                    role: $role,
                    created_at: datetime(),
                    updated_at: datetime()
                })
            """, user_data)
        
        # 创建更多公司
        companies_data = [
            {"id": 2, "name": "StartupXYZ", "industry": "Technology", "size": "startup", "location": "Austin, TX", "website": "https://startupxyz.com"},
            {"id": 3, "name": "Enterprise Corp", "industry": "Finance", "size": "enterprise", "location": "New York, NY", "website": "https://enterprise.com"}
        ]
        
        for company_data in companies_data:
            session.run("""
                CREATE (c:Company {
                    id: $id,
                    name: $name,
                    industry: $industry,
                    size: $size,
                    location: $location,
                    website: $website,
                    created_at: datetime(),
                    updated_at: datetime()
                })
            """, company_data)
        
        # 创建更多技能
        skills_data = [
            {"id": 2, "name": "JavaScript", "category": "Programming Language", "level": "advanced"},
            {"id": 3, "name": "React", "category": "Framework", "level": "expert"},
            {"id": 4, "name": "Node.js", "category": "Runtime", "level": "advanced"},
            {"id": 5, "name": "Machine Learning", "category": "AI/ML", "level": "intermediate"}
        ]
        
        for skill_data in skills_data:
            session.run("""
                CREATE (s:Skill {
                    id: $id,
                    name: $name,
                    category: $category,
                    level: $level,
                    created_at: datetime(),
                    updated_at: datetime()
                })
            """, skill_data)
        
        # 创建更多职位
        jobs_data = [
            {"id": 2, "title": "Frontend Developer", "description": "Looking for a frontend developer...", "location": "Remote", "salary_range": "$80,000 - $120,000", "employment_type": "full-time"},
            {"id": 3, "title": "Data Scientist", "description": "Seeking a data scientist...", "location": "San Francisco, CA", "salary_range": "$100,000 - $150,000", "employment_type": "full-time"}
        ]
        
        for job_data in jobs_data:
            session.run("""
                CREATE (j:Job {
                    id: $id,
                    title: $title,
                    description: $description,
                    location: $location,
                    salary_range: $salary_range,
                    employment_type: $employment_type,
                    created_at: datetime(),
                    updated_at: datetime()
                })
            """, job_data)
        
        print("✅ 示例数据创建完成")
    
    def _create_indexes(self, session):
        """创建索引"""
        print("📝 创建索引...")
        
        # 为用户节点创建索引
        session.run("CREATE INDEX user_id_index IF NOT EXISTS FOR (u:User) ON (u.id)")
        session.run("CREATE INDEX user_username_index IF NOT EXISTS FOR (u:User) ON (u.username)")
        session.run("CREATE INDEX user_email_index IF NOT EXISTS FOR (u:User) ON (u.email)")
        
        # 为公司节点创建索引
        session.run("CREATE INDEX company_id_index IF NOT EXISTS FOR (c:Company) ON (c.id)")
        session.run("CREATE INDEX company_name_index IF NOT EXISTS FOR (c:Company) ON (c.name)")
        session.run("CREATE INDEX company_industry_index IF NOT EXISTS FOR (c:Company) ON (c.industry)")
        
        # 为职位节点创建索引
        session.run("CREATE INDEX job_id_index IF NOT EXISTS FOR (j:Job) ON (j.id)")
        session.run("CREATE INDEX job_title_index IF NOT EXISTS FOR (j:Job) ON (j.title)")
        session.run("CREATE INDEX job_location_index IF NOT EXISTS FOR (j:Job) ON (j.location)")
        
        # 为技能节点创建索引
        session.run("CREATE INDEX skill_id_index IF NOT EXISTS FOR (s:Skill) ON (s.id)")
        session.run("CREATE INDEX skill_name_index IF NOT EXISTS FOR (s:Skill) ON (s.name)")
        session.run("CREATE INDEX skill_category_index IF NOT EXISTS FOR (s:Skill) ON (s.category)")
        
        # 为简历节点创建索引
        session.run("CREATE INDEX resume_id_index IF NOT EXISTS FOR (r:Resume) ON (r.id)")
        session.run("CREATE INDEX resume_title_index IF NOT EXISTS FOR (r:Resume) ON (r.title)")
        
        print("✅ 索引创建完成")
    
    def _create_constraints(self, session):
        """创建约束"""
        print("📝 创建约束...")
        
        # 为用户节点创建唯一约束
        session.run("CREATE CONSTRAINT user_id_unique IF NOT EXISTS FOR (u:User) REQUIRE u.id IS UNIQUE")
        session.run("CREATE CONSTRAINT user_username_unique IF NOT EXISTS FOR (u:User) REQUIRE u.username IS UNIQUE")
        session.run("CREATE CONSTRAINT user_email_unique IF NOT EXISTS FOR (u:User) REQUIRE u.email IS UNIQUE")
        
        # 为公司节点创建唯一约束
        session.run("CREATE CONSTRAINT company_id_unique IF NOT EXISTS FOR (c:Company) REQUIRE c.id IS UNIQUE")
        
        # 为职位节点创建唯一约束
        session.run("CREATE CONSTRAINT job_id_unique IF NOT EXISTS FOR (j:Job) REQUIRE j.id IS UNIQUE")
        
        # 为技能节点创建唯一约束
        session.run("CREATE CONSTRAINT skill_id_unique IF NOT EXISTS FOR (s:Skill) REQUIRE s.id IS UNIQUE")
        session.run("CREATE CONSTRAINT skill_name_unique IF NOT EXISTS FOR (s:Skill) REQUIRE s.name IS UNIQUE")
        
        # 为简历节点创建唯一约束
        session.run("CREATE CONSTRAINT resume_id_unique IF NOT EXISTS FOR (r:Resume) REQUIRE r.id IS UNIQUE")
        
        print("✅ 约束创建完成")
    
    def verify_structure(self):
        """验证数据库结构"""
        print("🔍 验证Neo4j数据库结构...")
        
        with self.driver.session(database=self.database_name) as session:
            # 统计节点数量
            node_counts = {}
            node_labels = ["User", "Company", "Job", "Skill", "Resume"]
            
            for label in node_labels:
                result = session.run(f"MATCH (n:{label}) RETURN count(n) as count")
                count = result.single()["count"]
                node_counts[label] = count
            
            # 统计关系数量
            relationship_counts = {}
            relationship_types = ["OWNS", "HAS_SKILL", "REQUIRES_SKILL", "POSTS", "APPLIED_TO", "WORKS_AT", "RELATED_TO"]
            
            for rel_type in relationship_types:
                result = session.run(f"MATCH ()-[r:{rel_type}]->() RETURN count(r) as count")
                count = result.single()["count"]
                relationship_counts[rel_type] = count
            
            # 统计索引数量
            index_result = session.run("SHOW INDEXES")
            indexes = list(index_result)
            
            # 统计约束数量
            constraint_result = session.run("SHOW CONSTRAINTS")
            constraints = list(constraint_result)
            
            print("📊 Neo4j结构验证结果:")
            print("  节点统计:")
            for label, count in node_counts.items():
                print(f"    {label}: {count} 个")
            
            print("  关系统计:")
            for rel_type, count in relationship_counts.items():
                print(f"    {rel_type}: {count} 个")
            
            print(f"  索引数量: {len(indexes)} 个")
            print(f"  约束数量: {len(constraints)} 个")
            
            return {
                'node_counts': node_counts,
                'relationship_counts': relationship_counts,
                'indexes_count': len(indexes),
                'constraints_count': len(constraints)
            }
    
    def get_database_info(self):
        """获取数据库信息"""
        with self.driver.session() as session:
            # 获取数据库版本
            version_result = session.run("CALL dbms.components() YIELD name, versions, edition RETURN name, versions[0] as version, edition")
            version_info = list(version_result)
            
            # 获取数据库统计
            stats_result = session.run("CALL apoc.meta.stats() YIELD nodeCount, relCount")
            stats = list(stats_result)
            
            return {
                'version_info': version_info,
                'stats': stats
            }

def main():
    """主函数"""
    print("🎯 Future版Neo4j图数据库结构创建脚本")
    print("=" * 50)
    
    # 创建Neo4j数据库创建器
    creator = FutureNeo4jDatabaseCreator()
    
    try:
        # 测试连接
        if not creator.test_connection():
            print("❌ 无法连接到Neo4j服务器，请检查Neo4j是否运行")
            return
        
        # 获取数据库信息
        db_info = creator.get_database_info()
        if db_info['version_info']:
            print(f"📊 Neo4j服务器信息:")
            for info in db_info['version_info']:
                print(f"  {info['name']}: {info['version']} ({info['edition']})")
        
        # 创建数据库结构
        creator.create_database_structure()
        
        # 验证结构
        verification_results = creator.verify_structure()
        
        print(f"\n🎉 Future版Neo4j图数据库结构创建完成！")
        print(f"📊 创建统计:")
        total_nodes = sum(verification_results['node_counts'].values())
        total_relationships = sum(verification_results['relationship_counts'].values())
        print(f"  - 总节点数: {total_nodes} 个")
        print(f"  - 总关系数: {total_relationships} 个")
        print(f"  - 索引数: {verification_results['indexes_count']} 个")
        print(f"  - 约束数: {verification_results['constraints_count']} 个")
        
    finally:
        creator.close()

if __name__ == "__main__":
    main()
