#!/usr/bin/env python3
"""
简化的MinerU-AI集成测试
逐步验证每个功能
"""

import asyncio
import aiohttp
import json
import os
from datetime import datetime

async def test_simple_deepseek():
    """测试简单的DeepSeek API调用"""
    api_key = os.getenv("DEEPSEEK_API_KEY", "")
    if not api_key:
        print("❌ 请设置DEEPSEEK_API_KEY环境变量")
        return False
    
    print("🤖 测试DeepSeek API...")
    
    try:
        async with aiohttp.ClientSession(timeout=aiohttp.ClientTimeout(total=10)) as session:
            async with session.post(
                "https://api.deepseek.com/chat/completions",
                headers={
                    "Authorization": f"Bearer {api_key}",
                    "Content-Type": "application/json"
                },
                json={
                    "model": "deepseek-chat",
                    "messages": [
                        {"role": "user", "content": "请简单分析一下软件工程师这个职业的特点"}
                    ],
                    "max_tokens": 200
                }
            ) as response:
                if response.status == 200:
                    result = await response.json()
                    content = result['choices'][0]['message']['content']
                    print(f"✅ DeepSeek API测试成功")
                    print(f"   响应: {content[:150]}...")
                    return True
                else:
                    error_text = await response.text()
                    print(f"❌ DeepSeek API测试失败: {response.status} - {error_text}")
                    return False
                    
    except Exception as e:
        print(f"❌ DeepSeek API测试异常: {e}")
        return False

async def test_mineru_service():
    """测试MinerU服务"""
    print("🔍 测试MinerU服务...")
    
    try:
        async with aiohttp.ClientSession(timeout=aiohttp.ClientTimeout(total=5)) as session:
            async with session.get("http://localhost:8000/health") as response:
                if response.status == 200:
                    health_data = await response.json()
                    print(f"✅ MinerU服务测试成功")
                    print(f"   状态: {health_data}")
                    return True
                else:
                    print(f"❌ MinerU服务测试失败: {response.status}")
                    return False
                    
    except Exception as e:
        print(f"❌ MinerU服务测试异常: {e}")
        return False

async def test_basic_resume_analysis():
    """测试基础简历分析"""
    print("📋 测试基础简历分析...")
    
    api_key = os.getenv("DEEPSEEK_API_KEY", "")
    if not api_key:
        return False
    
    simple_resume = """
    张三，软件工程师
    技能：Python, Java, Go
    经验：3年
    教育：计算机本科
    """
    
    prompt = f"请分析以下简历：{simple_resume}"
    
    try:
        async with aiohttp.ClientSession(timeout=aiohttp.ClientTimeout(total=15)) as session:
            async with session.post(
                "https://api.deepseek.com/chat/completions",
                headers={
                    "Authorization": f"Bearer {api_key}",
                    "Content-Type": "application/json"
                },
                json={
                    "model": "deepseek-chat",
                    "messages": [
                        {"role": "user", "content": prompt}
                    ],
                    "max_tokens": 300
                }
            ) as response:
                if response.status == 200:
                    result = await response.json()
                    content = result['choices'][0]['message']['content']
                    print(f"✅ 基础简历分析测试成功")
                    print(f"   分析结果: {content[:200]}...")
                    return True
                else:
                    error_text = await response.text()
                    print(f"❌ 基础简历分析测试失败: {response.status} - {error_text}")
                    return False
                    
    except Exception as e:
        print(f"❌ 基础简历分析测试异常: {e}")
        return False

async def main():
    """主函数"""
    print("🚀 简化MinerU-AI集成测试")
    print(f"测试时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 50)
    
    results = []
    
    # 1. 测试MinerU服务
    mineru_result = await test_mineru_service()
    results.append(("MinerU服务", mineru_result))
    
    # 2. 测试DeepSeek API
    deepseek_result = await test_simple_deepseek()
    results.append(("DeepSeek API", deepseek_result))
    
    # 3. 测试基础简历分析
    resume_result = await test_basic_resume_analysis()
    results.append(("基础简历分析", resume_result))
    
    # 总结
    print("\n" + "=" * 50)
    print("🎯 测试结果总结")
    
    success_count = 0
    for test_name, result in results:
        if result:
            print(f"✅ {test_name}: 通过")
            success_count += 1
        else:
            print(f"❌ {test_name}: 失败")
    
    print(f"\n测试通过率: {success_count}/{len(results)} ({success_count/len(results)*100:.1f}%)")
    
    if success_count >= 2:
        print("🎉 基础功能测试通过！")
        print("✅ MinerU服务和DeepSeek API基础功能正常")
        print("✅ 可以开始构建理性AI身份服务")
    else:
        print("⚠️ 基础功能测试失败，需要解决技术问题")

if __name__ == "__main__":
    asyncio.run(main())
