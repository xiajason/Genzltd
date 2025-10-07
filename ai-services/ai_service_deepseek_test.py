#!/usr/bin/env python3
"""
DeepSeek API调用测试脚本
验证外部AI服务的实际可用性
"""

import asyncio
import aiohttp
import json
import os
import time
from datetime import datetime
from typing import Dict, List, Any, Optional

class DeepSeekAPITester:
    """DeepSeek API测试器"""
    
    def __init__(self):
        self.api_key = os.getenv("DEEPSEEK_API_KEY", "")
        self.base_url = "https://api.deepseek.com"  # 使用官方推荐的base_url
        self.model = "deepseek-chat"  # V3.2-Exp版本
        self.reasoner_model = "deepseek-reasoner"  # 思考模式
        self.timeout = aiohttp.ClientTimeout(total=30)
        
        if not self.api_key:
            print("❌ 请设置DEEPSEEK_API_KEY环境变量")
            exit(1)
    
    async def test_basic_api_call(self) -> Dict[str, Any]:
        """测试基础API调用"""
        print("🔍 测试基础API调用...")
        
        try:
            async with aiohttp.ClientSession(timeout=self.timeout) as session:
                async with session.post(
                    f"{self.base_url}/chat/completions",
                    headers={
                        "Authorization": f"Bearer {self.api_key}",
                        "Content-Type": "application/json"
                    },
                    json={
                        "model": self.model,
                        "messages": [
                            {"role": "user", "content": "你好，请简单介绍一下你自己"}
                        ],
                        "max_tokens": 100,
                        "temperature": 0.7
                    }
                ) as response:
                    start_time = time.time()
                    
                    if response.status == 200:
                        result = await response.json()
                        response_time = time.time() - start_time
                        
                        return {
                            "status": "success",
                            "response_time": response_time,
                            "content": result['choices'][0]['message']['content'],
                            "usage": result.get('usage', {}),
                            "model": result.get('model', self.model)
                        }
                    else:
                        error_text = await response.text()
                        return {
                            "status": "error",
                            "status_code": response.status,
                            "error": error_text
                        }
                        
        except Exception as e:
            return {
                "status": "error",
                "error": str(e)
            }
    
    async def test_resume_analysis(self, resume_content: str) -> Dict[str, Any]:
        """测试简历分析功能"""
        print("🔍 测试简历分析功能...")
        
        prompt = f"""请分析以下简历内容，提取关键信息并以JSON格式返回：

简历内容：
{resume_content}

请提取以下信息：
{{
    "personal_info": {{
        "name": "姓名",
        "email": "邮箱",
        "phone": "电话"
    }},
    "skills": ["技能1", "技能2"],
    "experience": ["工作经验1", "工作经验2"],
    "education": ["教育背景1", "教育背景2"],
    "summary": "个人总结",
    "strengths": ["优势1", "优势2"],
    "improvements": ["改进建议1", "改进建议2"]
}}"""

        try:
            async with aiohttp.ClientSession(timeout=self.timeout) as session:
                async with session.post(
                    f"{self.base_url}/chat/completions",
                    headers={
                        "Authorization": f"Bearer {self.api_key}",
                        "Content-Type": "application/json"
                    },
                    json={
                        "model": self.model,
                        "messages": [
                            {"role": "user", "content": prompt}
                        ],
                        "max_tokens": 1000,
                        "temperature": 0.3
                    }
                ) as response:
                    start_time = time.time()
                    
                    if response.status == 200:
                        result = await response.json()
                        response_time = time.time() - start_time
                        
                        # 尝试解析JSON响应
                        try:
                            content = result['choices'][0]['message']['content']
                            # 提取JSON部分
                            json_start = content.find('{')
                            json_end = content.rfind('}') + 1
                            if json_start != -1 and json_end != -1:
                                json_content = content[json_start:json_end]
                                parsed_result = json.loads(json_content)
                            else:
                                parsed_result = {"raw_content": content}
                        except:
                            parsed_result = {"raw_content": result['choices'][0]['message']['content']}
                        
                        return {
                            "status": "success",
                            "response_time": response_time,
                            "analysis": parsed_result,
                            "usage": result.get('usage', {}),
                            "model": result.get('model', self.model)
                        }
                    else:
                        error_text = await response.text()
                        return {
                            "status": "error",
                            "status_code": response.status,
                            "error": error_text
                        }
                        
        except Exception as e:
            return {
                "status": "error",
                "error": str(e)
            }
    
    async def test_job_matching(self, resume_content: str, job_description: str) -> Dict[str, Any]:
        """测试职位匹配功能"""
        print("🔍 测试职位匹配功能...")
        
        prompt = f"""请分析以下简历和职位描述，评估匹配度并给出建议：

简历内容：
{resume_content}

职位描述：
{job_description}

请以JSON格式返回分析结果：
{{
    "match_score": 85,
    "match_analysis": {{
        "skills_match": "技能匹配度分析",
        "experience_match": "经验匹配度分析",
        "education_match": "教育背景匹配度分析",
        "culture_match": "文化适配度分析"
    }},
    "strengths": ["匹配优势1", "匹配优势2"],
    "gaps": ["匹配差距1", "匹配差距2"],
    "recommendations": ["改进建议1", "改进建议2"],
    "overall_assessment": "整体评估和建议"
}}"""

        try:
            async with aiohttp.ClientSession(timeout=self.timeout) as session:
                async with session.post(
                    f"{self.base_url}/chat/completions",
                    headers={
                        "Authorization": f"Bearer {self.api_key}",
                        "Content-Type": "application/json"
                    },
                    json={
                        "model": self.model,
                        "messages": [
                            {"role": "user", "content": prompt}
                        ],
                        "max_tokens": 1500,
                        "temperature": 0.3
                    }
                ) as response:
                    start_time = time.time()
                    
                    if response.status == 200:
                        result = await response.json()
                        response_time = time.time() - start_time
                        
                        # 尝试解析JSON响应
                        try:
                            content = result['choices'][0]['message']['content']
                            json_start = content.find('{')
                            json_end = content.rfind('}') + 1
                            if json_start != -1 and json_end != -1:
                                json_content = content[json_start:json_end]
                                parsed_result = json.loads(json_content)
                            else:
                                parsed_result = {"raw_content": content}
                        except:
                            parsed_result = {"raw_content": result['choices'][0]['message']['content']}
                        
                        return {
                            "status": "success",
                            "response_time": response_time,
                            "matching": parsed_result,
                            "usage": result.get('usage', {}),
                            "model": result.get('model', self.model)
                        }
                    else:
                        error_text = await response.text()
                        return {
                            "status": "error",
                            "status_code": response.status,
                            "error": error_text
                        }
                        
        except Exception as e:
            return {
                "status": "error",
                "error": str(e)
            }
    
    async def run_comprehensive_test(self):
        """运行综合测试"""
        print("🚀 开始DeepSeek API综合测试")
        print("=" * 50)
        
        # 测试数据
        sample_resume = """
        张三
        软件工程师
        邮箱: zhangsan@email.com
        电话: 138-0000-0000
        
        教育背景:
        - 2018-2022 北京理工大学 计算机科学与技术 本科
        
        工作经验:
        - 2022-至今 腾讯科技 后端开发工程师
          * 负责微信支付系统开发
          * 使用Java、Spring Boot、MySQL
          * 优化系统性能，提升30%响应速度
        
        技能:
        - 编程语言: Java, Python, JavaScript
        - 框架: Spring Boot, React, Vue.js
        - 数据库: MySQL, Redis, MongoDB
        - 工具: Git, Docker, Kubernetes
        
        项目经验:
        - 电商平台后端开发
        - 微服务架构设计
        - 高并发系统优化
        """
        
        sample_job = """
        职位: 高级后端开发工程师
        公司: 阿里巴巴
        
        职位要求:
        - 3年以上Java开发经验
        - 熟悉Spring Boot、MyBatis等框架
        - 有微服务架构经验
        - 熟悉MySQL、Redis等数据库
        - 有高并发系统开发经验
        - 熟悉分布式系统设计
        
        工作内容:
        - 负责电商平台后端开发
        - 参与系统架构设计
        - 优化系统性能和稳定性
        - 与前端团队协作开发
        
        薪资: 25-35K
        地点: 杭州
        """
        
        # 1. 基础API调用测试
        print("\n1. 基础API调用测试")
        basic_result = await self.test_basic_api_call()
        if basic_result["status"] == "success":
            print(f"✅ 基础API调用成功")
            print(f"   响应时间: {basic_result['response_time']:.2f}秒")
            print(f"   模型: {basic_result['model']}")
            print(f"   内容: {basic_result['content'][:100]}...")
        else:
            print(f"❌ 基础API调用失败: {basic_result}")
            return
        
        # 2. 简历分析测试
        print("\n2. 简历分析测试")
        resume_result = await self.test_resume_analysis(sample_resume)
        if resume_result["status"] == "success":
            print(f"✅ 简历分析成功")
            print(f"   响应时间: {resume_result['response_time']:.2f}秒")
            print(f"   分析结果: {json.dumps(resume_result['analysis'], ensure_ascii=False, indent=2)}")
        else:
            print(f"❌ 简历分析失败: {resume_result}")
        
        # 3. 职位匹配测试
        print("\n3. 职位匹配测试")
        matching_result = await self.test_job_matching(sample_resume, sample_job)
        if matching_result["status"] == "success":
            print(f"✅ 职位匹配成功")
            print(f"   响应时间: {matching_result['response_time']:.2f}秒")
            print(f"   匹配结果: {json.dumps(matching_result['matching'], ensure_ascii=False, indent=2)}")
        else:
            print(f"❌ 职位匹配失败: {matching_result}")
        
        # 总结
        print("\n" + "=" * 50)
        print("🎯 测试总结")
        
        success_count = 0
        total_tests = 3
        
        if basic_result["status"] == "success":
            success_count += 1
        if resume_result["status"] == "success":
            success_count += 1
        if matching_result["status"] == "success":
            success_count += 1
        
        print(f"测试通过率: {success_count}/{total_tests} ({success_count/total_tests*100:.1f}%)")
        
        if success_count == total_tests:
            print("🎉 所有测试通过！DeepSeek API集成成功！")
            print("✅ 可以开始下一步的MinerU-AI集成开发")
        else:
            print("⚠️ 部分测试失败，需要解决API集成问题")
        
        return {
            "basic_test": basic_result,
            "resume_analysis": resume_result,
            "job_matching": matching_result,
            "success_rate": success_count/total_tests
        }

async def main():
    """主函数"""
    print("🤖 DeepSeek API集成测试")
    print(f"测试时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    tester = DeepSeekAPITester()
    result = await tester.run_comprehensive_test()
    
    # 保存测试结果
    with open("deepseek_api_test_result.json", "w", encoding="utf-8") as f:
        json.dump(result, f, ensure_ascii=False, indent=2)
    
    print(f"\n📄 测试结果已保存到: deepseek_api_test_result.json")

if __name__ == "__main__":
    asyncio.run(main())
