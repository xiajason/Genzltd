#!/usr/bin/env python3
"""
DeepSeek API优化测试脚本
基于官方文档的最新API规范
"""

import asyncio
import aiohttp
import json
import os
import time
from datetime import datetime
from typing import Dict, List, Any, Optional

class DeepSeekAPIOptimized:
    """DeepSeek API优化测试器"""
    
    def __init__(self):
        self.api_key = os.getenv("DEEPSEEK_API_KEY", "")
        self.base_url = "https://api.deepseek.com"  # 官方推荐base_url
        self.model = "deepseek-chat"  # V3.2-Exp非思考模式
        self.reasoner_model = "deepseek-reasoner"  # V3.2-Exp思考模式
        self.timeout = aiohttp.ClientTimeout(total=30)
        
        if not self.api_key:
            print("❌ 请设置DEEPSEEK_API_KEY环境变量")
            print("📝 获取API密钥: https://platform.deepseek.com/api_keys")
            exit(1)
    
    async def test_basic_api_call(self) -> Dict[str, Any]:
        """测试基础API调用 - 使用官方示例"""
        print("🔍 测试基础API调用 (官方示例)...")
        
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
                            {"role": "system", "content": "You are a helpful assistant."},
                            {"role": "user", "content": "Hello!"}
                        ],
                        "stream": False
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
    
    async def test_reasoner_mode(self, complex_prompt: str) -> Dict[str, Any]:
        """测试思考模式 - deepseek-reasoner"""
        print("🧠 测试思考模式 (deepseek-reasoner)...")
        
        try:
            async with aiohttp.ClientSession(timeout=self.timeout) as session:
                async with session.post(
                    f"{self.base_url}/chat/completions",
                    headers={
                        "Authorization": f"Bearer {self.api_key}",
                        "Content-Type": "application/json"
                    },
                    json={
                        "model": self.reasoner_model,  # 使用思考模式
                        "messages": [
                            {"role": "user", "content": complex_prompt}
                        ],
                        "max_tokens": 2000,
                        "temperature": 0.3,
                        "stream": False
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
                            "model": result.get('model', self.reasoner_model)
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
    
    async def test_resume_analysis_advanced(self, resume_content: str) -> Dict[str, Any]:
        """测试高级简历分析 - 使用思考模式"""
        print("📋 测试高级简历分析...")
        
        prompt = f"""请深入分析以下简历内容，进行多维度评估：

简历内容：
{resume_content}

请进行以下分析：
1. 个人基本信息提取
2. 技能体系分析（技术栈、熟练度、发展趋势）
3. 工作经验评估（职业发展路径、成就量化）
4. 教育背景分析（专业匹配度、学习能力）
5. 项目经验评估（技术深度、业务理解）
6. 整体竞争力分析
7. 改进建议和职业发展方向

请以结构化的JSON格式返回分析结果。"""

        try:
            async with aiohttp.ClientSession(timeout=self.timeout) as session:
                async with session.post(
                    f"{self.base_url}/chat/completions",
                    headers={
                        "Authorization": f"Bearer {self.api_key}",
                        "Content-Type": "application/json"
                    },
                    json={
                        "model": self.reasoner_model,  # 使用思考模式进行复杂分析
                        "messages": [
                            {"role": "user", "content": prompt}
                        ],
                        "max_tokens": 3000,
                        "temperature": 0.2,
                        "stream": False
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
                            "model": result.get('model', self.reasoner_model)
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
    
    async def test_streaming_response(self) -> Dict[str, Any]:
        """测试流式响应"""
        print("🌊 测试流式响应...")
        
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
                            {"role": "user", "content": "请写一首关于AI的诗"}
                        ],
                        "max_tokens": 200,
                        "temperature": 0.8,
                        "stream": True
                    }
                ) as response:
                    start_time = time.time()
                    
                    if response.status == 200:
                        full_content = ""
                        chunk_count = 0
                        
                        async for line in response.content:
                            if line:
                                line_str = line.decode('utf-8').strip()
                                if line_str.startswith('data: '):
                                    data_str = line_str[6:]
                                    if data_str == '[DONE]':
                                        break
                                    try:
                                        data = json.loads(data_str)
                                        if 'choices' in data and len(data['choices']) > 0:
                                            delta = data['choices'][0].get('delta', {})
                                            if 'content' in delta:
                                                full_content += delta['content']
                                                chunk_count += 1
                                    except:
                                        continue
                        
                        response_time = time.time() - start_time
                        
                        return {
                            "status": "success",
                            "response_time": response_time,
                            "content": full_content,
                            "chunk_count": chunk_count,
                            "streaming": True
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
        print("🚀 开始DeepSeek API优化测试")
        print("基于官方文档: https://api-docs.deepseek.com/zh-cn/")
        print("=" * 60)
        
        # 测试数据
        sample_resume = """
        李四
        高级软件工程师
        邮箱: lisi@email.com
        电话: 139-0000-0000
        
        教育背景:
        - 2016-2020 清华大学 软件工程 本科
        - 2020-2023 清华大学 计算机科学与技术 硕士
        
        工作经验:
        - 2023-至今 字节跳动 高级后端工程师
          * 负责抖音推荐系统核心算法开发
          * 使用Go、Python、Kubernetes、Redis
          * 优化推荐算法，提升用户停留时间40%
          * 设计微服务架构，支持千万级并发
        
        - 2020-2023 腾讯科技 后端工程师
          * 负责微信小程序后端开发
          * 使用Java、Spring Boot、MySQL
          * 参与高并发系统设计和优化
        
        技能:
        - 编程语言: Go, Java, Python, JavaScript, TypeScript
        - 框架: Spring Boot, Gin, React, Vue.js
        - 数据库: MySQL, Redis, MongoDB, PostgreSQL
        - 云服务: AWS, 阿里云, Kubernetes, Docker
        - 工具: Git, Jenkins, Grafana, Prometheus
        
        项目经验:
        - 分布式推荐系统架构设计
        - 微服务治理平台开发
        - 高并发缓存系统优化
        - AI模型部署和推理优化
        
        获奖情况:
        - 2023年 字节跳动年度优秀员工
        - 2022年 腾讯技术创新奖
        - 2020年 清华大学优秀毕业生
        """
        
        complex_analysis_prompt = """
        请分析以下技术问题并给出解决方案：
        
        问题：在微服务架构中，如何处理分布式事务的一致性？
        要求：考虑CAP定理、不同的一致性级别、实际应用场景，并给出具体的实现方案。
        """
        
        # 1. 基础API调用测试
        print("\n1. 基础API调用测试 (官方示例)")
        basic_result = await self.test_basic_api_call()
        if basic_result["status"] == "success":
            print(f"✅ 基础API调用成功")
            print(f"   响应时间: {basic_result['response_time']:.2f}秒")
            print(f"   模型: {basic_result['model']}")
            print(f"   内容: {basic_result['content'][:100]}...")
        else:
            print(f"❌ 基础API调用失败: {basic_result}")
            return
        
        # 2. 思考模式测试
        print("\n2. 思考模式测试 (deepseek-reasoner)")
        reasoner_result = await self.test_reasoner_mode(complex_analysis_prompt)
        if reasoner_result["status"] == "success":
            print(f"✅ 思考模式测试成功")
            print(f"   响应时间: {reasoner_result['response_time']:.2f}秒")
            print(f"   模型: {reasoner_result['model']}")
            print(f"   内容长度: {len(reasoner_result['content'])}字符")
        else:
            print(f"❌ 思考模式测试失败: {reasoner_result}")
        
        # 3. 高级简历分析测试
        print("\n3. 高级简历分析测试")
        resume_result = await self.test_resume_analysis_advanced(sample_resume)
        if resume_result["status"] == "success":
            print(f"✅ 高级简历分析成功")
            print(f"   响应时间: {resume_result['response_time']:.2f}秒")
            print(f"   模型: {resume_result['model']}")
            print(f"   分析结果: {json.dumps(resume_result['analysis'], ensure_ascii=False, indent=2)[:200]}...")
        else:
            print(f"❌ 高级简历分析失败: {resume_result}")
        
        # 4. 流式响应测试
        print("\n4. 流式响应测试")
        stream_result = await self.test_streaming_response()
        if stream_result["status"] == "success":
            print(f"✅ 流式响应测试成功")
            print(f"   响应时间: {stream_result['response_time']:.2f}秒")
            print(f"   数据块数量: {stream_result['chunk_count']}")
            print(f"   内容: {stream_result['content'][:100]}...")
        else:
            print(f"❌ 流式响应测试失败: {stream_result}")
        
        # 总结
        print("\n" + "=" * 60)
        print("🎯 优化测试总结")
        
        success_count = 0
        total_tests = 4
        
        if basic_result["status"] == "success":
            success_count += 1
        if reasoner_result["status"] == "success":
            success_count += 1
        if resume_result["status"] == "success":
            success_count += 1
        if stream_result["status"] == "success":
            success_count += 1
        
        print(f"测试通过率: {success_count}/{total_tests} ({success_count/total_tests*100:.1f}%)")
        
        if success_count == total_tests:
            print("🎉 所有测试通过！DeepSeek API V3.2-Exp集成成功！")
            print("✅ 支持的功能:")
            print("   - 基础对话API")
            print("   - 思考模式 (deepseek-reasoner)")
            print("   - 流式响应")
            print("   - 复杂分析任务")
            print("✅ 可以开始MinerU-AI集成开发")
        else:
            print("⚠️ 部分测试失败，需要解决API集成问题")
        
        return {
            "basic_test": basic_result,
            "reasoner_test": reasoner_result,
            "resume_analysis": resume_result,
            "streaming_test": stream_result,
            "success_rate": success_count/total_tests
        }

async def main():
    """主函数"""
    print("🤖 DeepSeek API优化测试")
    print(f"测试时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("基于官方文档: https://api-docs.deepseek.com/zh-cn/")
    
    tester = DeepSeekAPIOptimized()
    result = await tester.run_comprehensive_test()
    
    # 保存测试结果
    with open("deepseek_api_optimized_test_result.json", "w", encoding="utf-8") as f:
        json.dump(result, f, ensure_ascii=False, indent=2)
    
    print(f"\n📄 测试结果已保存到: deepseek_api_optimized_test_result.json")

if __name__ == "__main__":
    asyncio.run(main())
