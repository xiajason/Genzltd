#!/usr/bin/env python3
"""
测试数据生成器
生成用于数据一致性测试的测试数据
"""

import asyncio
import json
import random
from datetime import datetime, timedelta
from typing import Dict, Any, List

class TestDataGenerator:
    """测试数据生成器"""
    
    def __init__(self):
        self.test_users = []
        self.test_projects = []
        self.test_relationships = []
    
    def generate_test_users(self, count: int = 10) -> List[Dict[str, Any]]:
        """生成测试用户数据"""
        users = []
        for i in range(count):
            user = {
                "id": f"test_user_{i+1}",
                "username": f"testuser{i+1}",
                "email": f"testuser{i+1}@example.com",
                "password": "test123456",
                "role": random.choice(["guest", "user", "admin"]),
                "status": "active",
                "first_name": f"Test{i+1}",
                "last_name": "User",
                "phone": f"+123456789{i:02d}",
                "created_at": (datetime.now() - timedelta(days=random.randint(1, 30))).isoformat(),
                "updated_at": datetime.now().isoformat()
            }
            users.append(user)
        return users
    
    def generate_test_projects(self, count: int = 5) -> List[Dict[str, Any]]:
        """生成测试项目数据"""
        projects = []
        for i in range(count):
            project = {
                "id": f"test_project_{i+1}",
                "name": f"Test Project {i+1}",
                "description": f"Description for test project {i+1}",
                "requirements": [f"requirement_{j+1}" for j in range(random.randint(2, 5))],
                "skills_needed": random.sample(["Python", "JavaScript", "React", "Node.js", "Docker", "Kubernetes"], random.randint(2, 4)),
                "team_size": random.randint(2, 10),
                "duration": random.randint(1, 12),
                "budget": random.randint(10000, 100000),
                "status": random.choice(["planning", "active", "completed"]),
                "created_at": (datetime.now() - timedelta(days=random.randint(1, 60))).isoformat(),
                "updated_at": datetime.now().isoformat()
            }
            projects.append(project)
        return projects
    
    def generate_test_relationships(self, users: List[Dict[str, Any]], count: int = 20) -> List[Dict[str, Any]]:
        """生成测试关系数据"""
        relationships = []
        for i in range(count):
            source_user = random.choice(users)
            target_user = random.choice([u for u in users if u["id"] != source_user["id"]])
            
            relationship = {
                "id": f"test_relationship_{i+1}",
                "source_talent_id": f"talent_{source_user['id']}",
                "target_talent_id": f"talent_{target_user['id']}",
                "relationship_type": random.choice(["colleague", "mentor", "mentee", "friend"]),
                "strength": round(random.uniform(0.1, 1.0), 2),
                "context": f"Test relationship context {i+1}",
                "created_at": (datetime.now() - timedelta(days=random.randint(1, 30))).isoformat(),
                "updated_at": datetime.now().isoformat()
            }
            relationships.append(relationship)
        return relationships
    
    def save_test_data(self, filename: str = "test_data.json"):
        """保存测试数据到文件"""
        test_data = {
            "generated_at": datetime.now().isoformat(),
            "users": self.test_users,
            "projects": self.test_projects,
            "relationships": self.test_relationships,
            "summary": {
                "user_count": len(self.test_users),
                "project_count": len(self.test_projects),
                "relationship_count": len(self.test_relationships)
            }
        }
        
        with open(filename, "w", encoding="utf-8") as f:
            json.dump(test_data, f, indent=2, ensure_ascii=False)
        
        return test_data

def main():
    """主函数"""
    generator = TestDataGenerator()
    
    # 生成测试数据
    users = generator.generate_test_users(10)
    projects = generator.generate_test_projects(5)
    relationships = generator.generate_test_relationships(users, 20)
    
    generator.test_users = users
    generator.test_projects = projects
    generator.test_relationships = relationships
    
    # 保存测试数据
    test_data = generator.save_test_data("test_data.json")
    
    print("测试数据生成完成！")
    print(f"用户数量: {test_data['summary']['user_count']}")
    print(f"项目数量: {test_data['summary']['project_count']}")
    print(f"关系数量: {test_data['summary']['relationship_count']}")
    print(f"数据已保存到: test_data.json")

if __name__ == "__main__":
    main()
