#!/usr/bin/env python3
"""
MinerU与AI服务集成管理器
实现文档解析与AI分析的完整集成
"""

import asyncio
import aiohttp
import json
import os
import structlog
from datetime import datetime
from typing import Dict, List, Any, Optional

logger = structlog.get_logger()

class MinerUAIIntegration:
    """MinerU与AI服务集成管理器"""
    
    def __init__(self):
        self.mineru_url = "http://localhost:8001"
        self.ai_service_url = "http://localhost:8208"
        self.deepseek_url = "http://localhost:8206"
        self.ai_models_url = "http://localhost:8002"
        self.timeout = aiohttp.ClientTimeout(total=30)
    
    async def parse_and_analyze_document(self, file_path: str, user_id: int) -> Dict[str, Any]:
        """解析文档并进行AI分析"""
        try:
            logger.info("开始MinerU-AI集成解析", file_path=file_path, user_id=user_id)
            
            # Step 1: 使用MinerU解析文档
            parsing_result = await self.parse_document_with_mineru(file_path, user_id)
            
            # Step 2: 使用AI服务分析解析内容
            ai_analysis = await self.analyze_content_with_ai(parsing_result.get("content", ""))
            
            # Step 3: 使用DeepSeek增强内容
            enhanced_content = await self.enhance_content_with_deepseek(parsing_result.get("content", ""))
            
            # Step 4: 生成向量嵌入
            embeddings = await self.generate_embeddings(parsing_result.get("content", ""))
            
            # Step 5: 综合结果
            integrated_result = {
                "parsing": parsing_result,
                "ai_analysis": ai_analysis,
                "enhanced_content": enhanced_content,
                "embeddings": embeddings,
                "integration_timestamp": datetime.now().isoformat(),
                "status": "success"
            }
            
            logger.info("MinerU-AI集成解析完成", file_path=file_path, user_id=user_id)
            return integrated_result
            
        except Exception as e:
            logger.error("MinerU-AI集成失败", file_path=file_path, error=str(e))
            raise
    
    async def parse_document_with_mineru(self, file_path: str, user_id: int) -> Dict:
        """使用MinerU解析文档"""
        async with aiohttp.ClientSession(timeout=self.timeout) as session:
            async with session.post(
                f"{self.mineru_url}/api/v1/parse/document",
                json={"file_path": file_path, "user_id": user_id}
            ) as response:
                if response.status == 200:
                    result = await response.json()
                    return result.get("result", {})
                else:
                    raise Exception(f"MinerU解析失败: {response.status}")
    
    async def analyze_content_with_ai(self, content: str) -> Dict:
        """使用AI服务分析内容"""
        try:
            async with aiohttp.ClientSession(timeout=self.timeout) as session:
                async with session.post(
                    f"{self.ai_service_url}/api/v1/ai/analyze",
                    json={"content": content, "type": "resume"}
                ) as response:
                    if response.status == 200:
                        result = await response.json()
                        return result.get("analysis", {})
                    else:
                        logger.warning("AI分析服务不可用，跳过AI分析", status=response.status)
                        return {"status": "skipped", "reason": "service_unavailable"}
        except Exception as e:
            logger.warning("AI分析失败，跳过AI分析", error=str(e))
            return {"status": "skipped", "reason": str(e)}
    
    async def enhance_content_with_deepseek(self, content: str) -> str:
        """使用DeepSeek增强内容"""
        try:
            prompt = f"""请优化以下简历内容，使其更加专业和吸引人：

原始内容：
{content[:1000]}...

请提供优化建议和增强版本。"""
            
            async with aiohttp.ClientSession(timeout=self.timeout) as session:
                async with session.post(
                    f"{self.deepseek_url}/api/v1/ai/chat",
                    json={"message": prompt, "model": "deepseek-chat"}
                ) as response:
                    if response.status == 200:
                        result = await response.json()
                        return result.get("response", "内容增强服务暂时不可用")
                    else:
                        logger.warning("DeepSeek增强服务不可用", status=response.status)
                        return "内容增强服务暂时不可用"
        except Exception as e:
            logger.warning("DeepSeek增强失败", error=str(e))
            return "内容增强服务暂时不可用"
    
    async def generate_embeddings(self, content: str) -> List[float]:
        """生成内容向量嵌入"""
        try:
            async with aiohttp.ClientSession(timeout=self.timeout) as session:
                async with session.post(
                    f"{self.ai_models_url}/api/v1/models/embedding",
                    json={"text": content, "model_type": "fast"}
                ) as response:
                    if response.status == 200:
                        result = await response.json()
                        return result.get("embedding", [])
                    else:
                        logger.warning("向量生成服务不可用", status=response.status)
                        return []
        except Exception as e:
            logger.warning("向量生成失败", error=str(e))
            return []

# 全局实例
mineru_ai_integration = MinerUAIIntegration()

if __name__ == "__main__":
    # 测试集成功能
    async def test_integration():
        test_file = "/path/to/test/resume.pdf"
        test_user_id = 1
        
        try:
            result = await mineru_ai_integration.parse_and_analyze_document(test_file, test_user_id)
            print("集成测试成功:", json.dumps(result, indent=2, ensure_ascii=False))
        except Exception as e:
            print("集成测试失败:", str(e))
    
    asyncio.run(test_integration())
