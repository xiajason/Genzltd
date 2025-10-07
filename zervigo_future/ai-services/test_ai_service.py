#!/usr/bin/env python3
"""
AI服务功能测试脚本
测试容器化AI服务的各项功能
"""

import requests
import json
import time
from typing import Dict, Any

class AIServiceTester:
    """AI服务测试器"""
    
    def __init__(self, base_url: str = "http://localhost:8208"):
        self.base_url = base_url
        self.test_token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoxLCJ1c2VybmFtZSI6InRlc3RfdXNlciIsImVtYWlsIjoidGVzdEBleGFtcGxlLmNvbSIsInJvbGVzIjpbInVzZXIiXSwiaWF0IjoxNzU3ODUzMzYyLCJleHAiOjE3NTc4NTY5NjIsImlzcyI6ImFpLXNlcnZpY2UtdGVzdCJ9.E-GnxBe9YptNYvbsJxuOXxy_A7vVVNxUBY0q0uK1I34"  # 测试用的JWT token
    
    def test_health_check(self) -> bool:
        """测试健康检查"""
        try:
            response = requests.get(f"{self.base_url}/health")
            if response.status_code == 200:
                data = response.json()
                print("✅ 健康检查通过")
                print(f"   服务状态: {data.get('status')}")
                print(f"   服务版本: {data.get('version')}")
                print(f"   数据库状态: {data.get('database_status')}")
                print(f"   AI模型状态: {data.get('ai_model_status')}")
                return True
            else:
                print(f"❌ 健康检查失败: {response.status_code}")
                return False
        except Exception as e:
            print(f"❌ 健康检查异常: {e}")
            return False
    
    def test_service_status(self) -> bool:
        """测试服务状态"""
        try:
            response = requests.get(f"{self.base_url}/api/v1/status")
            if response.status_code == 200:
                data = response.json()
                print("✅ 服务状态检查通过")
                print(f"   服务名称: {data.get('service')}")
                print(f"   功能特性: {', '.join(data.get('features', []))}")
                print(f"   数据库连接: {data.get('database_connected')}")
                print(f"   AI模型加载: {data.get('ai_model_loaded')}")
                return True
            else:
                print(f"❌ 服务状态检查失败: {response.status_code}")
                return False
        except Exception as e:
            print(f"❌ 服务状态检查异常: {e}")
            return False
    
    def test_embedding_generation(self) -> bool:
        """测试嵌入向量生成"""
        try:
            headers = {"Authorization": f"Bearer {self.test_token}"}
            data = {"text": "这是一个测试文本，用于生成嵌入向量"}
            
            response = requests.post(
                f"{self.base_url}/api/v1/ai/embedding",
                headers=headers,
                json=data
            )
            
            if response.status_code == 200:
                result = response.json()
                print("✅ 嵌入向量生成测试通过")
                print(f"   向量维度: {result.get('dimension')}")
                print(f"   向量前5个值: {result.get('embedding', [])[:5]}")
                return True
            else:
                print(f"❌ 嵌入向量生成测试失败: {response.status_code}")
                print(f"   响应内容: {response.text}")
                return False
        except Exception as e:
            print(f"❌ 嵌入向量生成测试异常: {e}")
            return False
    
    def test_resume_analysis(self) -> bool:
        """测试简历分析"""
        try:
            headers = {"Authorization": f"Bearer {self.test_token}"}
            resume_data = {
                "name": "张三",
                "email": "zhangsan@example.com",
                "phone": "13800138000",
                "summary": "具有5年软件开发经验，熟悉Python、Java等编程语言",
                "experience": [
                    {
                        "title": "高级软件工程师",
                        "company": "ABC科技有限公司",
                        "description": "负责后端系统开发和维护"
                    }
                ],
                "education": [
                    {
                        "degree": "计算机科学与技术学士",
                        "school": "某某大学"
                    }
                ],
                "skills": ["Python", "Java", "MySQL", "Docker", "团队协作"]
            }
            
            response = requests.post(
                f"{self.base_url}/api/v1/ai/resume-analysis",
                headers=headers,
                json=resume_data
            )
            
            if response.status_code == 200:
                result = response.json()
                print("✅ 简历分析测试通过")
                analysis = result.get("result", {})
                print(f"   用户ID: {analysis.get('user_id')}")
                print(f"   置信度: {analysis.get('confidence_score')}")
                print(f"   技能总数: {analysis.get('skills_analysis', {}).get('total_skills')}")
                print(f"   技术技能: {analysis.get('skills_analysis', {}).get('technical_skills')}")
                return True
            else:
                print(f"❌ 简历分析测试失败: {response.status_code}")
                print(f"   响应内容: {response.text}")
                return False
        except Exception as e:
            print(f"❌ 简历分析测试异常: {e}")
            return False
    
    def test_job_matching(self) -> bool:
        """测试职位匹配"""
        try:
            headers = {"Authorization": f"Bearer {self.test_token}"}
            data = {"limit": 5}
            
            response = requests.post(
                f"{self.base_url}/api/v1/ai/job-matching",
                headers=headers,
                json=data
            )
            
            if response.status_code == 200:
                result = response.json()
                print("✅ 职位匹配测试通过")
                matches = result.get("matches", [])
                print(f"   匹配职位数量: {len(matches)}")
                if matches:
                    first_match = matches[0]
                    print(f"   第一个职位: {first_match.get('title')}")
                    print(f"   相似度分数: {first_match.get('similarity_score')}")
                return True
            else:
                print(f"❌ 职位匹配测试失败: {response.status_code}")
                print(f"   响应内容: {response.text}")
                return False
        except Exception as e:
            print(f"❌ 职位匹配测试异常: {e}")
            return False
    
    def test_ai_chat(self) -> bool:
        """测试AI聊天"""
        try:
            headers = {"Authorization": f"Bearer {self.test_token}"}
            data = {"message": "你好，请介绍一下你的功能"}
            
            response = requests.post(
                f"{self.base_url}/api/v1/ai/chat",
                headers=headers,
                json=data
            )
            
            if response.status_code == 200:
                result = response.json()
                print("✅ AI聊天测试通过")
                print(f"   回复内容: {result.get('response')}")
                print(f"   用户ID: {result.get('user_id')}")
                return True
            else:
                print(f"❌ AI聊天测试失败: {response.status_code}")
                print(f"   响应内容: {response.text}")
                return False
        except Exception as e:
            print(f"❌ AI聊天测试异常: {e}")
            return False
    
    def run_all_tests(self) -> Dict[str, bool]:
        """运行所有测试"""
        print("🚀 开始AI服务功能测试")
        print("=" * 50)
        
        tests = [
            ("健康检查", self.test_health_check),
            ("服务状态", self.test_service_status),
            ("嵌入向量生成", self.test_embedding_generation),
            ("简历分析", self.test_resume_analysis),
            ("职位匹配", self.test_job_matching),
            ("AI聊天", self.test_ai_chat),
        ]
        
        results = {}
        for test_name, test_func in tests:
            print(f"\n📋 测试: {test_name}")
            print("-" * 30)
            try:
                results[test_name] = test_func()
            except Exception as e:
                print(f"❌ 测试异常: {e}")
                results[test_name] = False
            time.sleep(1)  # 避免请求过快
        
        print("\n" + "=" * 50)
        print("📊 测试结果汇总")
        print("=" * 50)
        
        passed = 0
        total = len(results)
        
        for test_name, result in results.items():
            status = "✅ 通过" if result else "❌ 失败"
            print(f"{test_name}: {status}")
            if result:
                passed += 1
        
        print(f"\n总计: {passed}/{total} 个测试通过")
        print(f"成功率: {passed/total*100:.1f}%")
        
        return results

def main():
    """主函数"""
    print("AI服务容器化功能测试")
    print("测试目标: http://localhost:8208")
    print()
    
    tester = AIServiceTester()
    results = tester.run_all_tests()
    
    # 判断整体测试结果
    all_passed = all(results.values())
    if all_passed:
        print("\n🎉 所有测试通过！AI服务运行正常。")
        exit(0)
    else:
        print("\n⚠️  部分测试失败，请检查AI服务配置。")
        exit(1)

if __name__ == "__main__":
    main()
