#!/usr/bin/env python3
"""
MinerU-AI集成核心实现
实现文档解析与AI分析的完整集成
"""

import asyncio
import aiohttp
import json
import os
import structlog
from datetime import datetime
from typing import Dict, List, Any, Optional
from dataclasses import dataclass

logger = structlog.get_logger()

@dataclass
class AIAnalysisResult:
    """AI分析结果数据类"""
    status: str
    content: str
    analysis: Dict[str, Any]
    confidence: float
    processing_time: float
    timestamp: str
    error: Optional[str] = None

class MinerUAIIntegrationCore:
    """MinerU-AI集成核心类"""
    
    def __init__(self):
        # 服务配置
        self.mineru_url = os.getenv("MINERU_URL", "http://localhost:8001")
        self.deepseek_api_key = os.getenv("DEEPSEEK_API_KEY", "")
        self.deepseek_base_url = os.getenv("DEEPSEEK_BASE_URL", "https://api.deepseek.com")  # 官方推荐
        self.deepseek_model = os.getenv("DEEPSEEK_MODEL", "deepseek-chat")  # V3.2-Exp
        self.deepseek_reasoner_model = os.getenv("DEEPSEEK_REASONER_MODEL", "deepseek-reasoner")  # 思考模式
        
        # HTTP客户端配置
        self.timeout = aiohttp.ClientTimeout(total=30)
        
        # 验证配置
        if not self.deepseek_api_key:
            logger.warning("DeepSeek API密钥未设置，AI功能将不可用")
    
    async def parse_document_with_mineru(self, file_path: str, user_id: int, business_type: str = "resume") -> Dict[str, Any]:
        """使用MinerU解析文档"""
        logger.info("开始MinerU文档解析", file_path=file_path, user_id=user_id, business_type=business_type)
        
        try:
            async with aiohttp.ClientSession(timeout=self.timeout) as session:
                async with session.post(
                    f"{self.mineru_url}/api/v1/parse/document",
                    json={
                        "file_path": file_path,
                        "user_id": user_id,
                        "business_type": business_type
                    }
                ) as response:
                    if response.status == 200:
                        result = await response.json()
                        logger.info("MinerU解析成功", file_path=file_path, user_id=user_id)
                        return result.get("result", {})
                    else:
                        error_text = await response.text()
                        logger.error("MinerU解析失败", file_path=file_path, status=response.status, error=error_text)
                        raise Exception(f"MinerU解析失败: {response.status} - {error_text}")
        except Exception as e:
            logger.error("MinerU解析异常", file_path=file_path, error=str(e))
            raise
    
    async def analyze_content_with_ai(self, content: str, analysis_type: str = "resume") -> AIAnalysisResult:
        """使用AI分析内容"""
        if not self.deepseek_api_key:
            return AIAnalysisResult(
                status="error",
                content=content,
                analysis={},
                confidence=0.0,
                processing_time=0.0,
                timestamp=datetime.now().isoformat(),
                error="DeepSeek API密钥未设置"
            )
        
        logger.info("开始AI内容分析", analysis_type=analysis_type, content_length=len(content))
        
        start_time = datetime.now()
        
        try:
            # 根据分析类型选择不同的prompt
            prompt = self._get_analysis_prompt(content, analysis_type)
            
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
                            {"role": "user", "content": prompt}
                        ],
                        "max_tokens": 2000,
                        "temperature": 0.3
                    }
                ) as response:
                    processing_time = (datetime.now() - start_time).total_seconds()
                    
                    if response.status == 200:
                        result = await response.json()
                        ai_response = result['choices'][0]['message']['content']
                        
                        # 尝试解析AI响应为结构化数据
                        analysis = self._parse_ai_response(ai_response, analysis_type)
                        confidence = self._calculate_confidence(analysis)
                        
                        logger.info("AI分析成功", analysis_type=analysis_type, processing_time=processing_time)
                        
                        return AIAnalysisResult(
                            status="success",
                            content=content,
                            analysis=analysis,
                            confidence=confidence,
                            processing_time=processing_time,
                            timestamp=datetime.now().isoformat()
                        )
                    else:
                        error_text = await response.text()
                        logger.error("AI分析失败", analysis_type=analysis_type, status=response.status, error=error_text)
                        
                        return AIAnalysisResult(
                            status="error",
                            content=content,
                            analysis={},
                            confidence=0.0,
                            processing_time=processing_time,
                            timestamp=datetime.now().isoformat(),
                            error=f"AI分析失败: {response.status} - {error_text}"
                        )
                        
        except Exception as e:
            processing_time = (datetime.now() - start_time).total_seconds()
            logger.error("AI分析异常", analysis_type=analysis_type, error=str(e))
            
            return AIAnalysisResult(
                status="error",
                content=content,
                analysis={},
                confidence=0.0,
                processing_time=processing_time,
                timestamp=datetime.now().isoformat(),
                error=str(e)
            )
    
    def _get_analysis_prompt(self, content: str, analysis_type: str) -> str:
        """获取分析类型的prompt"""
        if analysis_type == "resume":
            return f"""请分析以下简历内容，提取关键信息并以JSON格式返回：

简历内容：
{content}

请提取以下信息：
{{
    "personal_info": {{
        "name": "姓名",
        "email": "邮箱",
        "phone": "电话",
        "location": "地点"
    }},
    "skills": ["技能1", "技能2"],
    "experience": [
        {{
            "company": "公司名称",
            "position": "职位",
            "duration": "工作时间",
            "description": "工作描述"
        }}
    ],
    "education": [
        {{
            "school": "学校名称",
            "degree": "学位",
            "major": "专业",
            "graduation_year": "毕业年份"
        }}
    ],
    "summary": "个人总结",
    "strengths": ["优势1", "优势2"],
    "improvements": ["改进建议1", "改进建议2"],
    "quality_score": 85,
    "analysis": "详细分析"
}}"""

        elif analysis_type == "job":
            return f"""请分析以下职位描述，提取关键信息并以JSON格式返回：

职位描述：
{content}

请提取以下信息：
{{
    "job_info": {{
        "title": "职位标题",
        "company": "公司名称",
        "location": "工作地点",
        "salary": "薪资范围"
    }},
    "requirements": {{
        "skills": ["技能要求1", "技能要求2"],
        "experience": "经验要求",
        "education": "学历要求",
        "certifications": ["证书要求1", "证书要求2"]
    }},
    "responsibilities": ["职责1", "职责2"],
    "benefits": ["福利1", "福利2"],
    "company_culture": "企业文化描述",
    "analysis": "职位分析",
    "difficulty_level": "难度等级"
}}"""

        elif analysis_type == "company":
            return f"""请分析以下企业信息，提取关键信息并以JSON格式返回：

企业信息：
{content}

请提取以下信息：
{{
    "basic_info": {{
        "name": "企业名称",
        "industry": "所属行业",
        "location": "总部地点",
        "founded_year": "成立年份",
        "employee_count": "员工规模"
    }},
    "business_info": {{
        "business_model": "商业模式",
        "main_products": ["主要产品1", "主要产品2"],
        "target_market": "目标市场",
        "revenue": "营收信息"
    }},
    "culture": {{
        "values": ["企业价值观1", "企业价值观2"],
        "culture_description": "企业文化描述",
        "work_environment": "工作环境"
    }},
    "analysis": "企业分析",
    "reputation_score": 85
}}"""

        else:
            return f"""请分析以下内容：

内容：
{content}

请提供详细的分析结果。"""
    
    def _parse_ai_response(self, response: str, analysis_type: str) -> Dict[str, Any]:
        """解析AI响应为结构化数据"""
        try:
            # 尝试提取JSON部分
            json_start = response.find('{')
            json_end = response.rfind('}') + 1
            
            if json_start != -1 and json_end != -1:
                json_content = response[json_start:json_end]
                parsed_result = json.loads(json_content)
                return parsed_result
            else:
                # 如果没有找到JSON，返回原始内容
                return {
                    "raw_response": response,
                    "parsing_status": "failed"
                }
        except json.JSONDecodeError as e:
            logger.warning("AI响应JSON解析失败", error=str(e))
            return {
                "raw_response": response,
                "parsing_status": "failed",
                "error": str(e)
            }
    
    def _calculate_confidence(self, analysis: Dict[str, Any]) -> float:
        """计算分析结果的置信度"""
        if not analysis or analysis.get("parsing_status") == "failed":
            return 0.0
        
        confidence = 0.0
        confidence_factors = []
        
        # 检查关键字段的完整性
        if "personal_info" in analysis and analysis["personal_info"]:
            confidence_factors.append(0.3)
        
        if "skills" in analysis and analysis["skills"]:
            confidence_factors.append(0.2)
        
        if "experience" in analysis and analysis["experience"]:
            confidence_factors.append(0.3)
        
        if "education" in analysis and analysis["education"]:
            confidence_factors.append(0.2)
        
        confidence = sum(confidence_factors)
        
        # 如果有质量评分，使用它
        if "quality_score" in analysis:
            confidence = max(confidence, analysis["quality_score"] / 100.0)
        
        return min(confidence, 1.0)
    
    async def parse_and_analyze_document(self, file_path: str, user_id: int, business_type: str = "resume") -> Dict[str, Any]:
        """解析文档并进行AI分析的完整流程"""
        logger.info("开始MinerU-AI集成解析", file_path=file_path, user_id=user_id, business_type=business_type)
        
        try:
            # Step 1: 使用MinerU解析文档
            parsing_result = await self.parse_document_with_mineru(file_path, user_id, business_type)
            
            # Step 2: 提取文本内容
            content = parsing_result.get("content", "")
            if not content:
                raise Exception("MinerU解析结果中没有找到内容")
            
            # Step 3: 使用AI分析内容
            ai_result = await self.analyze_content_with_ai(content, business_type)
            
            # Step 4: 综合结果
            integrated_result = {
                "mineru_parsing": parsing_result,
                "ai_analysis": ai_result.analysis,
                "ai_confidence": ai_result.confidence,
                "processing_time": ai_result.processing_time,
                "integration_timestamp": datetime.now().isoformat(),
                "status": "success" if ai_result.status == "success" else "partial_success"
            }
            
            if ai_result.error:
                integrated_result["ai_error"] = ai_result.error
                integrated_result["status"] = "partial_success"
            
            logger.info("MinerU-AI集成解析完成", file_path=file_path, user_id=user_id, status=integrated_result["status"])
            return integrated_result
            
        except Exception as e:
            logger.error("MinerU-AI集成解析失败", file_path=file_path, user_id=user_id, error=str(e))
            return {
                "status": "error",
                "error": str(e),
                "integration_timestamp": datetime.now().isoformat()
            }

# 使用示例
async def main():
    """使用示例"""
    integration = MinerUAIIntegrationCore()
    
    # 测试文档解析和AI分析
    result = await integration.parse_and_analyze_document(
        file_path="/path/to/resume.pdf",
        user_id=123,
        business_type="resume"
    )
    
    print("集成结果:", json.dumps(result, ensure_ascii=False, indent=2))

if __name__ == "__main__":
    asyncio.run(main())
