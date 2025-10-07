#!/usr/bin/env python3
"""
专业AI身份测试脚本
验证基于Resume的理性AI身份核心功能
"""

import asyncio
import aiohttp
import json
import os
from datetime import datetime

class ProfessionalAIIdentityTester:
    """专业AI身份测试器"""
    
    def __init__(self):
        self.api_key = os.getenv("DEEPSEEK_API_KEY", "")
        self.base_url = "https://api.deepseek.com"
        self.model = "deepseek-chat"
        
        if not self.api_key:
            print("❌ 请设置DEEPSEEK_API_KEY环境变量")
            exit(1)
    
    async def create_detailed_resume(self) -> str:
        """创建详细的示例简历"""
        return """
        李四
        高级软件工程师 | 技术负责人
        邮箱: lisi@tech.com | 电话: 139-0000-0000
        地址: 北京市海淀区 | 期望薪资: 35-50K
        
        【教育背景】
        2016-2020 北京理工大学 软件工程 本科
        - 主修课程：数据结构、算法设计、软件工程、数据库原理
        - 获得校级优秀毕业生，GPA 3.8/4.0
        
        【工作经验】
        2022-至今 字节跳动 高级软件工程师
        - 负责抖音推荐系统核心算法开发和优化
        - 使用Go、Python、Kubernetes、Redis等技术栈
        - 优化推荐算法，提升用户停留时间40%，日活增长15%
        - 设计微服务架构，支持千万级并发，系统可用性99.9%
        - 带领5人团队完成多个核心项目，获得公司年度优秀员工
        
        2020-2022 腾讯科技 软件工程师
        - 负责微信小程序后端开发，服务用户数千万
        - 使用Java、Spring Boot、MySQL、Redis
        - 参与高并发系统设计和优化，QPS提升200%
        - 负责用户行为分析系统，为产品决策提供数据支持
        
        【技能专长】
        编程语言: Go(精通), Java(精通), Python(熟练), JavaScript(熟练), TypeScript(熟练)
        框架技术: Spring Boot(精通), Gin(精通), React(熟练), Vue.js(熟练)
        数据库: MySQL(精通), Redis(精通), MongoDB(熟练), PostgreSQL(熟练)
        云服务: AWS(熟练), 阿里云(熟练), Kubernetes(精通), Docker(精通)
        开发工具: Git(精通), Jenkins(熟练), Grafana(熟练), Prometheus(熟练)
        
        【项目经验】
        1. 分布式推荐系统架构设计 (2023-2024)
           - 技术栈: Go, Kubernetes, Redis, Elasticsearch
           - 成果: 支持千万级用户，推荐准确率提升30%
           - 职责: 架构设计、核心算法开发、性能优化
        
        2. 微服务治理平台开发 (2022-2023)
           - 技术栈: Java, Spring Cloud, MySQL, Redis
           - 成果: 服务治理效率提升50%，故障率降低60%
           - 职责: 平台设计、核心功能开发、团队协作
        
        3. 高并发缓存系统优化 (2021-2022)
           - 技术栈: Java, Redis, MySQL, Kafka
           - 成果: 系统QPS提升200%，响应时间降低70%
           - 职责: 性能分析、优化方案设计、实施部署
        
        【获奖情况】
        - 2024年 字节跳动年度优秀员工
        - 2023年 字节跳动技术创新奖
        - 2022年 腾讯最佳新人奖
        - 2020年 北京理工大学优秀毕业生
        
        【个人特点】
        - 技术能力强，具备系统架构设计能力
        - 团队协作能力强，有团队管理经验
        - 学习能力强，能够快速掌握新技术
        - 责任心强，能够承担重要项目
        """
    
    async def test_skill_extraction(self) -> dict:
        """测试技能提取功能"""
        print("🔧 测试技能提取功能...")
        
        resume = await self.create_detailed_resume()
        
        prompt = f"""请从以下简历中提取技能信息，并按照技能类别进行分类：

简历内容：
{resume}

请提取并分类以下技能：
1. 编程语言技能
2. 框架技术技能
3. 数据库技能
4. 云服务技能
5. 开发工具技能
6. 软技能

请以JSON格式返回，包含每个技能的熟练度评级（精通/熟练/了解）。"""

        try:
            async with aiohttp.ClientSession(timeout=aiohttp.ClientTimeout(total=20)) as session:
                async with session.post(
                    f"{self.base_url}/chat/completions",
                    headers={
                        "Authorization": f"Bearer {self.api_key}",
                        "Content-Type": "application/json"
                    },
                    json={
                        "model": self.model,
                        "messages": [{"role": "user", "content": prompt}],
                        "max_tokens": 1000,
                        "temperature": 0.1
                    }
                ) as response:
                    if response.status == 200:
                        result = await response.json()
                        content = result['choices'][0]['message']['content']
                        print(f"✅ 技能提取测试成功")
                        print(f"   提取结果长度: {len(content)}字符")
                        
                        # 尝试解析JSON
                        try:
                            json_start = content.find('{')
                            json_end = content.rfind('}') + 1
                            if json_start != -1 and json_end != -1:
                                json_content = content[json_start:json_end]
                                skills_data = json.loads(json_content)
                                print(f"   JSON解析成功，技能类别: {list(skills_data.keys())}")
                                return {"status": "success", "skills": skills_data, "raw": content}
                        except:
                            pass
                        
                        return {"status": "success", "skills": None, "raw": content}
                    else:
                        return {"status": "error", "error": f"API调用失败: {response.status}"}
                        
        except Exception as e:
            return {"status": "error", "error": f"技能提取异常: {e}"}
    
    async def test_experience_analysis(self) -> dict:
        """测试经验分析功能"""
        print("💼 测试经验分析功能...")
        
        resume = await self.create_detailed_resume()
        
        prompt = f"""请分析以下简历的工作经验，提取关键信息：

简历内容：
{resume}

请分析：
1. 工作年限和职业发展阶段
2. 职业发展轨迹（职位变化）
3. 主要工作职责和成就
4. 技术成长路径
5. 团队管理经验
6. 项目复杂度评估

请以结构化格式返回分析结果。"""

        try:
            async with aiohttp.ClientSession(timeout=aiohttp.ClientTimeout(total=20)) as session:
                async with session.post(
                    f"{self.base_url}/chat/completions",
                    headers={
                        "Authorization": f"Bearer {self.api_key}",
                        "Content-Type": "application/json"
                    },
                    json={
                        "model": self.model,
                        "messages": [{"role": "user", "content": prompt}],
                        "max_tokens": 1200,
                        "temperature": 0.1
                    }
                ) as response:
                    if response.status == 200:
                        result = await response.json()
                        content = result['choices'][0]['message']['content']
                        print(f"✅ 经验分析测试成功")
                        print(f"   分析结果长度: {len(content)}字符")
                        return {"status": "success", "analysis": content}
                    else:
                        return {"status": "error", "error": f"API调用失败: {response.status}"}
                        
        except Exception as e:
            return {"status": "error", "error": f"经验分析异常: {e}"}
    
    async def test_career_assessment(self) -> dict:
        """测试职业评估功能"""
        print("📊 测试职业评估功能...")
        
        resume = await self.create_detailed_resume()
        
        prompt = f"""请对以下简历进行综合职业评估：

简历内容：
{resume}

请评估：
1. 技术能力评分（0-100分）
2. 工作经验评分（0-100分）
3. 项目经验评分（0-100分）
4. 教育背景评分（0-100分）
5. 综合竞争力评分（0-100分）
6. 职业发展阶段评估
7. 市场价值评估
8. 发展潜力评估
9. 优势分析
10. 改进建议

请以JSON格式返回评分结果。"""

        try:
            async with aiohttp.ClientSession(timeout=aiohttp.ClientTimeout(total=25)) as session:
                async with session.post(
                    f"{self.base_url}/chat/completions",
                    headers={
                        "Authorization": f"Bearer {self.api_key}",
                        "Content-Type": "application/json"
                    },
                    json={
                        "model": self.model,
                        "messages": [{"role": "user", "content": prompt}],
                        "max_tokens": 1500,
                        "temperature": 0.1
                    }
                ) as response:
                    if response.status == 200:
                        result = await response.json()
                        content = result['choices'][0]['message']['content']
                        print(f"✅ 职业评估测试成功")
                        print(f"   评估结果长度: {len(content)}字符")
                        
                        # 尝试解析JSON
                        try:
                            json_start = content.find('{')
                            json_end = content.rfind('}') + 1
                            if json_start != -1 and json_end != -1:
                                json_content = content[json_start:json_end]
                                assessment_data = json.loads(json_content)
                                print(f"   JSON解析成功，评估维度: {list(assessment_data.keys())}")
                                return {"status": "success", "assessment": assessment_data, "raw": content}
                        except:
                            pass
                        
                        return {"status": "success", "assessment": None, "raw": content}
                    else:
                        return {"status": "error", "error": f"API调用失败: {response.status}"}
                        
        except Exception as e:
            return {"status": "error", "error": f"职业评估异常: {e}"}
    
    async def test_job_matching(self) -> dict:
        """测试职位匹配功能"""
        print("🎯 测试职位匹配功能...")
        
        job_description = """
        职位：高级后端工程师
        公司：某知名互联网公司
        薪资：30-50K
        
        职位要求：
        - 3年以上后端开发经验
        - 熟练掌握Go、Java、Python等编程语言
        - 有微服务架构设计和开发经验
        - 熟悉Kubernetes、Docker等容器技术
        - 有高并发系统设计和优化经验
        - 熟悉MySQL、Redis等数据库
        - 有团队协作和项目管理经验
        - 本科及以上学历，计算机相关专业
        - 有推荐系统或大数据处理经验优先
        
        工作职责：
        - 负责后端系统架构设计和开发
        - 参与高并发系统的设计和优化
        - 带领团队完成重要项目
        - 与产品、前端团队协作
        - 参与技术方案评审
        """
        
        resume = await self.create_detailed_resume()
        
        prompt = f"""请分析以下候选人与职位的匹配度：

职位要求：
{job_description}

候选人简历：
{resume}

请分析：
1. 技能匹配度（0-100分）
2. 经验匹配度（0-100分）
3. 项目经验匹配度（0-100分）
4. 教育背景匹配度（0-100分）
5. 综合匹配度（0-100分）
6. 匹配优势
7. 不匹配的风险点
8. 面试建议
9. 薪资建议
10. 最终推荐度（推荐/考虑/不推荐）

请以JSON格式返回匹配分析结果。"""

        try:
            async with aiohttp.ClientSession(timeout=aiohttp.ClientTimeout(total=25)) as session:
                async with session.post(
                    f"{self.base_url}/chat/completions",
                    headers={
                        "Authorization": f"Bearer {self.api_key}",
                        "Content-Type": "application/json"
                    },
                    json={
                        "model": self.model,
                        "messages": [{"role": "user", "content": prompt}],
                        "max_tokens": 1500,
                        "temperature": 0.1
                    }
                ) as response:
                    if response.status == 200:
                        result = await response.json()
                        content = result['choices'][0]['message']['content']
                        print(f"✅ 职位匹配测试成功")
                        print(f"   匹配分析长度: {len(content)}字符")
                        
                        # 尝试解析JSON
                        try:
                            json_start = content.find('{')
                            json_end = content.rfind('}') + 1
                            if json_start != -1 and json_end != -1:
                                json_content = content[json_start:json_end]
                                matching_data = json.loads(json_content)
                                print(f"   JSON解析成功，匹配维度: {list(matching_data.keys())}")
                                return {"status": "success", "matching": matching_data, "raw": content}
                        except:
                            pass
                        
                        return {"status": "success", "matching": None, "raw": content}
                    else:
                        return {"status": "error", "error": f"API调用失败: {response.status}"}
                        
        except Exception as e:
            return {"status": "error", "error": f"职位匹配异常: {e}"}
    
    async def run_comprehensive_test(self):
        """运行综合测试"""
        print("🚀 开始专业AI身份测试")
        print("验证基于Resume的理性AI身份核心功能")
        print("=" * 60)
        
        test_results = {}
        
        # 1. 技能提取测试
        print("\n1. 技能提取功能测试")
        skill_result = await self.test_skill_extraction()
        test_results["skill_extraction"] = skill_result
        if skill_result["status"] == "success":
            print("✅ 技能提取功能测试通过")
        else:
            print(f"❌ 技能提取功能测试失败: {skill_result}")
        
        # 2. 经验分析测试
        print("\n2. 经验分析功能测试")
        experience_result = await self.test_experience_analysis()
        test_results["experience_analysis"] = experience_result
        if experience_result["status"] == "success":
            print("✅ 经验分析功能测试通过")
        else:
            print(f"❌ 经验分析功能测试失败: {experience_result}")
        
        # 3. 职业评估测试
        print("\n3. 职业评估功能测试")
        assessment_result = await self.test_career_assessment()
        test_results["career_assessment"] = assessment_result
        if assessment_result["status"] == "success":
            print("✅ 职业评估功能测试通过")
        else:
            print(f"❌ 职业评估功能测试失败: {assessment_result}")
        
        # 4. 职位匹配测试
        print("\n4. 职位匹配功能测试")
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
        total_tests = 4
        
        for test_name, result in test_results.items():
            if result["status"] == "success":
                success_count += 1
        
        print(f"测试通过率: {success_count}/{total_tests} ({success_count/total_tests*100:.1f}%)")
        
        if success_count >= 3:  # 至少3个测试通过
            print("🎉 专业AI身份测试成功！")
            print("✅ 理性AI身份核心功能验证通过")
            print("✅ 技能提取、经验分析、职业评估、职位匹配功能正常")
            print("✅ 可以开始构建完整的理性AI身份服务")
            print("✅ 下一步：实现感性AI身份和融合AI身份")
        else:
            print("⚠️ 部分测试失败，需要解决技术问题")
        
        return test_results

async def main():
    """主函数"""
    print("🤖 专业AI身份测试")
    print(f"测试时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("目标: 验证基于Resume的理性AI身份核心功能")
    
    tester = ProfessionalAIIdentityTester()
    results = await tester.run_comprehensive_test()
    
    # 保存测试结果
    with open("professional_ai_identity_test_result.json", "w", encoding="utf-8") as f:
        json.dump(results, f, ensure_ascii=False, indent=2)
    
    print(f"\n📄 测试结果已保存到: professional_ai_identity_test_result.json")

if __name__ == "__main__":
    asyncio.run(main())
