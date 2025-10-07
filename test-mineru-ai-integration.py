#!/usr/bin/env python3
"""
MinerU-AI集成测试脚本
验证理性AI身份的技术基础
"""

import asyncio
import aiohttp
import json
import os
import time
from datetime import datetime
from typing import Dict, List, Any, Optional

class MinerUAIIntegrationTester:
    """MinerU-AI集成测试器"""
    
    def __init__(self):
        # 服务配置
        self.mineru_url = "http://localhost:8000"
        self.deepseek_api_key = os.getenv("DEEPSEEK_API_KEY", "")
        self.deepseek_base_url = "https://api.deepseek.com"
        self.deepseek_model = "deepseek-chat"
        
        # HTTP客户端配置
        self.timeout = aiohttp.ClientTimeout(total=30)
        
        # 验证配置
        if not self.deepseek_api_key:
            print("❌ 请设置DEEPSEEK_API_KEY环境变量")
            exit(1)
    
    async def test_mineru_service(self) -> Dict[str, Any]:
        """测试MinerU服务"""
        print("🔍 测试MinerU服务...")
        
        try:
            async with aiohttp.ClientSession(timeout=self.timeout) as session:
                # 测试健康检查
                async with session.get(f"{self.mineru_url}/health") as response:
                    if response.status == 200:
                        health_data = await response.json()
                        print(f"✅ MinerU服务健康检查通过: {health_data}")
                        return {
                            "status": "success",
                            "health": health_data
                        }
                    else:
                        error_text = await response.text()
                        return {
                            "status": "error",
                            "error": f"MinerU健康检查失败: {response.status} - {error_text}"
                        }
                        
        except Exception as e:
            return {
                "status": "error",
                "error": f"MinerU服务连接异常: {e}"
            }
    
    async def test_deepseek_api(self) -> Dict[str, Any]:
        """测试DeepSeek API"""
        print("🤖 测试DeepSeek API...")
        
        try:
            async with aiohttp.ClientSession(timeout=self.timeout) as session:
                async with session.post(
                    f"{self.deepseek_base_url}/chat/completions",
                    headers={
                        "Authorization": f"Bearer {self.deepseek_api_key}",
                        "Content-Type": "application/json"
                    },
                    json={
                        "model": self.deepseek_model,
                        "messages": [
                            {"role": "user", "content": "请简单介绍一下你自己，并确认API连接正常"}
                        ],
                        "max_tokens": 100
                    }
                ) as response:
                    if response.status == 200:
                        result = await response.json()
                        content = result['choices'][0]['message']['content']
                        print(f"✅ DeepSeek API测试成功")
                        print(f"   响应: {content[:100]}...")
                        return {
                            "status": "success",
                            "content": content,
                            "usage": result.get('usage', {})
                        }
                    else:
                        error_text = await response.text()
                        return {
                            "status": "error",
                            "error": f"DeepSeek API调用失败: {response.status} - {error_text}"
                        }
                        
        except Exception as e:
            return {
                "status": "error",
                "error": f"DeepSeek API连接异常: {e}"
            }
    
    async def create_sample_resume(self) -> str:
        """创建示例简历内容"""
        sample_resume = """
        张三
        高级软件工程师
        邮箱: zhangsan@email.com
        电话: 138-0000-0000
        
        教育背景:
        - 2018-2022 清华大学 计算机科学与技术 本科
        - 2022-2025 清华大学 软件工程 硕士
        
        工作经验:
        - 2025-至今 字节跳动 高级后端工程师
          * 负责抖音推荐系统核心算法开发
          * 使用Go、Python、Kubernetes、Redis
          * 优化推荐算法，提升用户停留时间35%
          * 设计微服务架构，支持千万级并发
        
        - 2023-2025 腾讯科技 后端工程师
          * 负责微信小程序后端开发
          * 使用Java、Spring Boot、MySQL
          * 参与高并发系统设计和优化
          * 负责用户行为分析系统
        
        技能专长:
        - 编程语言: Go, Java, Python, JavaScript, TypeScript
        - 框架技术: Spring Boot, Gin, React, Vue.js
        - 数据库: MySQL, Redis, MongoDB, PostgreSQL
        - 云服务: AWS, 阿里云, Kubernetes, Docker
        - 工具: Git, Jenkins, Grafana, Prometheus
        
        项目经验:
        - 分布式推荐系统架构设计
        - 微服务治理平台开发
        - 高并发缓存系统优化
        - AI模型部署和推理优化
        
        获奖情况:
        - 2024年 字节跳动年度优秀员工
        - 2023年 腾讯技术创新奖
        - 2022年 清华大学优秀毕业生
        """
        return sample_resume.strip()
    
    async def test_resume_analysis(self) -> Dict[str, Any]:
        """测试简历分析功能"""
        print("📋 测试简历分析功能...")
        
        # 创建示例简历
        sample_resume = await self.create_sample_resume()
        
        # 构建分析提示词
        analysis_prompt = f"""请对以下简历进行深度分析，提取关键信息并生成结构化的分析结果：

简历内容：
{sample_resume}

请进行以下分析：
1. 基本信息提取（姓名、联系方式、教育背景）
2. 工作经验分析（职位、公司、职责、成就）
3. 技能体系分析（技术栈、熟练度、发展趋势）
4. 项目经验评估（技术深度、业务理解、创新性）
5. 职业发展评估（发展路径、优势、改进建议）
6. 综合评分（专业技能、经验丰富度、发展潜力）

请以JSON格式返回分析结果。"""

        try:
            async with aiohttp.ClientSession(timeout=self.timeout) as session:
                async with session.post(
                    f"{self.deepseek_base_url}/chat/completions",
                    headers={
                        "Authorization": f"Bearer {self.deepseek_api_key}",
                        "Content-Type": "application/json"
                    },
                    json={
                        "model": self.deepseek_model,
                        "messages": [
                            {"role": "user", "content": analysis_prompt}
                        ],
                        "max_tokens": 2000,
                        "temperature": 0.2
                    }
                ) as response:
                    if response.status == 200:
                        result = await response.json()
                        content = result['choices'][0]['message']['content']
                        print(f"✅ 简历分析完成")
                        print(f"   分析结果长度: {len(content)}字符")
                        
                        # 尝试解析JSON结果
                        try:
                            # 提取JSON部分
                            json_start = content.find('{')
                            json_end = content.rfind('}') + 1
                            if json_start != -1 and json_end != -1:
                                json_content = content[json_start:json_end]
                                parsed_result = json.loads(json_content)
                                print(f"   JSON解析成功，包含字段: {list(parsed_result.keys())}")
                                return {
                                    "status": "success",
                                    "analysis": parsed_result,
                                    "raw_content": content,
                                    "usage": result.get('usage', {})
                                }
                            else:
                                return {
                                    "status": "success",
                                    "analysis": None,
                                    "raw_content": content,
                                    "usage": result.get('usage', {})
                                }
                        except json.JSONDecodeError as e:
                            print(f"   JSON解析失败: {e}")
                            return {
                                "status": "success",
                                "analysis": None,
                                "raw_content": content,
                                "usage": result.get('usage', {})
                            }
                    else:
                        error_text = await response.text()
                        return {
                            "status": "error",
                            "error": f"简历分析失败: {response.status} - {error_text}"
                        }
                        
        except Exception as e:
            return {
                "status": "error",
                "error": f"简历分析异常: {e}"
            }
    
    async def test_career_prediction(self) -> Dict[str, Any]:
        """测试职业发展预测"""
        print("🔮 测试职业发展预测...")
        
        prediction_prompt = """基于以下简历信息，进行职业发展预测分析：

张三，高级软件工程师，有3年工作经验，主要技能包括Go、Python、Java、Kubernetes、微服务架构等。
当前在字节跳动担任高级后端工程师，负责推荐系统开发。

请分析：
1. 短期职业发展路径（1-2年）
2. 中期职业发展路径（3-5年）
3. 长期职业发展路径（5-10年）
4. 薪资水平预测
5. 技能发展方向建议
6. 行业趋势影响分析

请以结构化格式返回预测结果。"""

        try:
            async with aiohttp.ClientSession(timeout=self.timeout) as session:
                async with session.post(
                    f"{self.deepseek_base_url}/chat/completions",
                    headers={
                        "Authorization": f"Bearer {self.deepseek_api_key}",
                        "Content-Type": "application/json"
                    },
                    json={
                        "model": self.deepseek_model,
                        "messages": [
                            {"role": "user", "content": prediction_prompt}
                        ],
                        "max_tokens": 1500,
                        "temperature": 0.3
                    }
                ) as response:
                    if response.status == 200:
                        result = await response.json()
                        content = result['choices'][0]['message']['content']
                        print(f"✅ 职业发展预测完成")
                        print(f"   预测结果长度: {len(content)}字符")
                        return {
                            "status": "success",
                            "prediction": content,
                            "usage": result.get('usage', {})
                        }
                    else:
                        error_text = await response.text()
                        return {
                            "status": "error",
                            "error": f"职业预测失败: {response.status} - {error_text}"
                        }
                        
        except Exception as e:
            return {
                "status": "error",
                "error": f"职业预测异常: {e}"
            }
    
    async def test_job_matching(self) -> Dict[str, Any]:
        """测试职位匹配功能"""
        print("🎯 测试职位匹配功能...")
        
        job_requirements = """
        职位：高级后端工程师
        公司：某互联网公司
        要求：
        - 3年以上后端开发经验
        - 熟练掌握Go、Python、Java
        - 有微服务架构经验
        - 熟悉Kubernetes、Docker
        - 有高并发系统设计经验
        - 本科及以上学历
        - 有推荐系统经验优先
        """
        
        candidate_profile = """
        候选人：张三
        经验：3年工作经验
        技能：Go, Java, Python, JavaScript, TypeScript, Spring Boot, Gin, React, Vue.js
        数据库：MySQL, Redis, MongoDB, PostgreSQL
        云服务：AWS, 阿里云, Kubernetes, Docker
        项目经验：分布式推荐系统、微服务治理平台、高并发缓存系统
        教育：清华大学计算机科学与技术本科，软件工程硕士
        """
        
        matching_prompt = f"""请分析以下候选人是否匹配职位要求，并计算匹配度：

职位要求：
{job_requirements}

候选人信息：
{candidate_profile}

请分析：
1. 技能匹配度分析
2. 经验匹配度分析
3. 项目经验匹配度分析
4. 教育背景匹配度分析
5. 综合匹配度评分（0-100分）
6. 匹配优势分析
7. 不匹配的风险点
8. 改进建议

请以结构化格式返回匹配分析结果。"""

        try:
            async with aiohttp.ClientSession(timeout=self.timeout) as session:
                async with session.post(
                    f"{self.deepseek_base_url}/chat/completions",
                    headers={
                        "Authorization": f"Bearer {self.deepseek_api_key}",
                        "Content-Type": "application/json"
                    },
                    json={
                        "model": self.deepseek_model,
                        "messages": [
                            {"role": "user", "content": matching_prompt}
                        ],
                        "max_tokens": 1500,
                        "temperature": 0.2
                    }
                ) as response:
                    if response.status == 200:
                        result = await response.json()
                        content = result['choices'][0]['message']['content']
                        print(f"✅ 职位匹配分析完成")
                        print(f"   匹配分析长度: {len(content)}字符")
                        return {
                            "status": "success",
                            "matching": content,
                            "usage": result.get('usage', {})
                        }
                    else:
                        error_text = await response.text()
                        return {
                            "status": "error",
                            "error": f"职位匹配失败: {response.status} - {error_text}"
                        }
                        
        except Exception as e:
            return {
                "status": "error",
                "error": f"职位匹配异常: {e}"
            }
    
    async def run_comprehensive_test(self):
        """运行综合测试"""
        print("🚀 开始MinerU-AI集成测试")
        print("验证理性AI身份的技术基础")
        print("=" * 60)
        
        test_results = {}
        
        # 1. 测试MinerU服务
        print("\n1. MinerU服务测试")
        mineru_result = await self.test_mineru_service()
        test_results["mineru_service"] = mineru_result
        if mineru_result["status"] == "success":
            print("✅ MinerU服务测试通过")
        else:
            print(f"❌ MinerU服务测试失败: {mineru_result}")
            return test_results
        
        # 2. 测试DeepSeek API
        print("\n2. DeepSeek API测试")
        deepseek_result = await self.test_deepseek_api()
        test_results["deepseek_api"] = deepseek_result
        if deepseek_result["status"] == "success":
            print("✅ DeepSeek API测试通过")
        else:
            print(f"❌ DeepSeek API测试失败: {deepseek_result}")
            return test_results
        
        # 3. 测试简历分析
        print("\n3. 简历分析功能测试")
        resume_result = await self.test_resume_analysis()
        test_results["resume_analysis"] = resume_result
        if resume_result["status"] == "success":
            print("✅ 简历分析功能测试通过")
        else:
            print(f"❌ 简历分析功能测试失败: {resume_result}")
        
        # 4. 测试职业发展预测
        print("\n4. 职业发展预测测试")
        prediction_result = await self.test_career_prediction()
        test_results["career_prediction"] = prediction_result
        if prediction_result["status"] == "success":
            print("✅ 职业发展预测测试通过")
        else:
            print(f"❌ 职业发展预测测试失败: {prediction_result}")
        
        # 5. 测试职位匹配
        print("\n5. 职位匹配功能测试")
        matching_result = await self.test_job_matching()
        test_results["job_matching"] = matching_result
        if matching_result["status"] == "success":
            print("✅ 职位匹配功能测试通过")
        else:
            print(f"❌ 职位匹配功能测试失败: {matching_result}")
        
        # 总结
        print("\n" + "=" * 60)
        print("🎯 测试结果总结")
        
        success_count = 0
        total_tests = 5
        
        for test_name, result in test_results.items():
            if result["status"] == "success":
                success_count += 1
        
        print(f"测试通过率: {success_count}/{total_tests} ({success_count/total_tests*100:.1f}%)")
        
        if success_count >= 4:  # 至少4个测试通过
            print("🎉 MinerU-AI集成测试成功！")
            print("✅ 理性AI身份技术基础验证通过")
            print("✅ 可以开始构建基于Resume的理性AI身份服务")
            print("✅ 下一步：实现基础简历分析功能")
        else:
            print("⚠️ 部分测试失败，需要解决技术问题")
        
        return test_results

async def main():
    """主函数"""
    print("🤖 MinerU-AI集成测试")
    print(f"测试时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("目标: 验证理性AI身份的技术基础")
    
    tester = MinerUAIIntegrationTester()
    results = await tester.run_comprehensive_test()
    
    # 保存测试结果
    with open("mineru_ai_integration_test_result.json", "w", encoding="utf-8") as f:
        json.dump(results, f, ensure_ascii=False, indent=2)
    
    print(f"\n📄 测试结果已保存到: mineru_ai_integration_test_result.json")

if __name__ == "__main__":
    asyncio.run(main())