#!/usr/bin/env python3
"""
简单的DeepSeek API测试脚本
验证基础功能是否正常
"""

import asyncio
import aiohttp
import json
import os
import time
from datetime import datetime

async def test_simple_chat():
    """测试简单的聊天功能"""
    api_key = os.getenv("DEEPSEEK_API_KEY", "")
    if not api_key:
        print("❌ 请设置DEEPSEEK_API_KEY环境变量")
        return False
    
    print("🤖 测试DeepSeek API基础功能")
    print(f"API密钥: {api_key[:8]}...")
    
    try:
        async with aiohttp.ClientSession() as session:
            # 测试基础对话
            print("\n1. 测试基础对话...")
            async with session.post(
                "https://api.deepseek.com/chat/completions",
                headers={
                    "Authorization": f"Bearer {api_key}",
                    "Content-Type": "application/json"
                },
                json={
                    "model": "deepseek-chat",
                    "messages": [
                        {"role": "user", "content": "你好，请简单介绍一下你自己"}
                    ],
                    "max_tokens": 100
                }
            ) as response:
                if response.status == 200:
                    result = await response.json()
                    content = result['choices'][0]['message']['content']
                    print(f"✅ 基础对话成功")
                    print(f"   响应: {content[:100]}...")
                else:
                    error_text = await response.text()
                    print(f"❌ 基础对话失败: {response.status} - {error_text}")
                    return False
            
            # 测试简历分析
            print("\n2. 测试简历分析...")
            resume_prompt = """请分析以下简历信息：

姓名：张三
职位：软件工程师
技能：Python, Java, React
经验：3年

请用JSON格式返回分析结果，包含技能评估和职位匹配度。"""
            
            async with session.post(
                "https://api.deepseek.com/chat/completions",
                headers={
                    "Authorization": f"Bearer {api_key}",
                    "Content-Type": "application/json"
                },
                json={
                    "model": "deepseek-chat",
                    "messages": [
                        {"role": "user", "content": resume_prompt}
                    ],
                    "max_tokens": 500
                }
            ) as response:
                if response.status == 200:
                    result = await response.json()
                    content = result['choices'][0]['message']['content']
                    print(f"✅ 简历分析成功")
                    print(f"   分析结果: {content[:200]}...")
                    
                    # 尝试解析JSON
                    try:
                        # 查找JSON部分
                        json_start = content.find('{')
                        json_end = content.rfind('}') + 1
                        if json_start != -1 and json_end != -1:
                            json_content = content[json_start:json_end]
                            parsed = json.loads(json_content)
                            print(f"   JSON解析成功: {list(parsed.keys())}")
                    except:
                        print("   JSON解析失败，但文本分析成功")
                        
                else:
                    error_text = await response.text()
                    print(f"❌ 简历分析失败: {response.status} - {error_text}")
                    return False
            
            # 测试思考模式
            print("\n3. 测试思考模式...")
            async with session.post(
                "https://api.deepseek.com/chat/completions",
                headers={
                    "Authorization": f"Bearer {api_key}",
                    "Content-Type": "application/json"
                },
                json={
                    "model": "deepseek-reasoner",
                    "messages": [
                        {"role": "user", "content": "请分析：为什么Python在AI领域如此受欢迎？"}
                    ],
                    "max_tokens": 300
                }
            ) as response:
                if response.status == 200:
                    result = await response.json()
                    content = result['choices'][0]['message']['content']
                    print(f"✅ 思考模式成功")
                    print(f"   分析结果: {content[:200]}...")
                else:
                    error_text = await response.text()
                    print(f"❌ 思考模式失败: {response.status} - {error_text}")
                    # 思考模式失败不算致命错误
            
            print("\n🎉 DeepSeek API基础功能测试完成！")
            print("✅ 可以开始MinerU-AI集成开发")
            return True
            
    except Exception as e:
        print(f"❌ 测试过程中出现异常: {e}")
        return False

async def main():
    """主函数"""
    success = await test_simple_chat()
    if success:
        print("\n🚀 下一步：开始MinerU-AI集成实现")
    else:
        print("\n⚠️ 需要解决API集成问题")

if __name__ == "__main__":
    asyncio.run(main())
