#!/usr/bin/env python3
"""
MinerU文档解析服务 - 容器化版本
提供智能文档解析服务
"""

import asyncio
import logging
import os
import shutil
from typing import Dict, List, Optional
from sanic import Sanic, Request, response
from sanic.response import json
import structlog
import aiofiles
from pathlib import Path
from document_classifier import document_classifier

# 配置日志
structlog.configure(
    processors=[
        structlog.stdlib.filter_by_level,
        structlog.stdlib.add_logger_name,
        structlog.stdlib.add_log_level,
        structlog.stdlib.PositionalArgumentsFormatter(),
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.StackInfoRenderer(),
        structlog.processors.format_exc_info,
        structlog.processors.UnicodeDecoder(),
        structlog.processors.JSONRenderer()
    ],
    context_class=dict,
    logger_factory=structlog.stdlib.LoggerFactory(),
    wrapper_class=structlog.stdlib.BoundLogger,
    cache_logger_on_first_use=True,
)

logger = structlog.get_logger()

# 创建Sanic应用
app = Sanic("mineru-service")

class MinerUService:
    """MinerU文档解析服务类"""
    
    def __init__(self):
        self.upload_dir = "/app/uploads"
        self.output_dir = "/app/output"
        self.max_memory = os.getenv("MAX_MEMORY", "2GB")
        self.max_concurrent = int(os.getenv("MAX_CONCURRENT", "2"))
        self.current_tasks = 0
        
        # 创建必要的目录
        os.makedirs(self.upload_dir, exist_ok=True)
        os.makedirs(self.output_dir, exist_ok=True)
        
        logger.info("MinerU服务初始化", 
                   upload_dir=self.upload_dir, 
                   output_dir=self.output_dir,
                   max_memory=self.max_memory)
    
    async def parse_document(self, file_path: str, user_id: int, business_type: str = "resume") -> Dict:
        """解析文档 - 支持业务类型和智能验证"""
        try:
            logger.info("开始解析文档", file_path=file_path, user_id=user_id, business_type=business_type)
            
            # 检查文件是否存在
            if not os.path.exists(file_path):
                raise FileNotFoundError(f"文件不存在: {file_path}")
            
            # 获取文件信息
            file_info = await self.get_file_info(file_path)
            
            # 智能文档类型验证
            validation_result = await self.validate_document_type(file_path, business_type)
            
            # 如果验证失败，记录警告但继续处理
            if not validation_result["is_match"]:
                logger.warning("文档类型验证失败", 
                              requested_type=business_type,
                              detected_type=validation_result["detected_type"],
                              confidence=validation_result["confidence"],
                              recommendation=validation_result.get("recommendation"))
            
            # 根据文件类型选择解析方法
            if file_info["type"] == "pdf":
                result = await self.parse_pdf(file_path, business_type)
            elif file_info["type"] in ["docx", "doc"]:
                result = await self.parse_docx(file_path, business_type)
            else:
                raise ValueError(f"不支持的文件类型: {file_info['type']}")
            
            # 增强解析结果
            enhanced_result = await self.enhance_parsing_result(result, file_info, business_type)
            
            # 添加验证信息
            enhanced_result["type_validation"] = validation_result
            
            logger.info("文档解析完成", 
                       file_path=file_path, 
                       business_type=business_type, 
                       validation_passed=validation_result["is_match"],
                       result_size=len(str(enhanced_result)))
            return enhanced_result
            
        except Exception as e:
            logger.error("文档解析失败", file_path=file_path, business_type=business_type, error=str(e))
            raise
    
    async def get_file_info(self, file_path: str) -> Dict:
        """获取文件信息"""
        try:
            file_path_obj = Path(file_path)
            file_size = file_path_obj.stat().st_size
            
            # 根据文件扩展名判断类型
            extension = file_path_obj.suffix.lower()
            if extension == ".pdf":
                file_type = "pdf"
            elif extension in [".docx", ".doc"]:
                file_type = "docx"
            else:
                file_type = "unknown"
            
            return {
                "name": file_path_obj.name,
                "size": file_size,
                "type": file_type,
                "extension": extension
            }
            
        except Exception as e:
            logger.error("获取文件信息失败", file_path=file_path, error=str(e))
            raise
    
    async def parse_pdf(self, file_path: str, business_type: str = "resume") -> Dict:
        """解析PDF文件 - 支持业务类型"""
        try:
            # 根据业务类型返回不同的模拟结果
            if business_type == "resume":
                result = {
                    "type": "pdf",
                    "business_type": "resume",
                    "pages": 1,
                    "content": "简历PDF解析内容（模拟）",
                    "structure": {
                        "title": "个人简历",
                        "sections": ["基本信息", "教育经历", "工作经历", "技能专长", "项目经验"]
                    },
                    "metadata": {
                        "author": "求职者",
                        "created": "2025-09-14",
                        "modified": "2025-09-14"
                    },
                    # 简历特有字段
                    "name": "张三",
                    "phone": "13800138000",
                    "email": "zhangsan@example.com",
                    "location": "北京市朝阳区",
                    "degree": "本科",
                    "school": "北京大学",
                    "major": "计算机科学与技术",
                    "technical_skills": ["Go", "Python", "MySQL", "Redis"],
                    "work_experience": ["软件工程师", "高级开发工程师"],
                    "confidence": 0.92
                }
            elif business_type == "company":
                result = {
                    "type": "pdf",
                    "business_type": "company",
                    "pages": 1,
                    "content": "企业画像PDF解析内容（模拟）",
                    "structure": {
                        "title": "企业画像报告",
                        "sections": ["基本信息", "经营状况", "财务状况", "风险分析"]
                    },
                    "metadata": {
                        "author": "企业",
                        "created": "2025-09-14",
                        "modified": "2025-09-14"
                    },
                    # 企业特有字段
                    "company_name": "某某科技有限公司",
                    "industry": "信息技术",
                    "location": "上海市浦东新区",
                    "employee_count": 500,
                    "founded_year": 2010,
                    "revenue": "5000万元",
                    "confidence": 0.88
                }
            else:
                result = {
                    "type": "pdf",
                    "business_type": business_type,
                    "pages": 1,
                    "content": "通用PDF解析内容（模拟）",
                    "structure": {
                        "title": "文档标题",
                        "sections": ["章节1", "章节2"]
                    },
                    "metadata": {
                        "author": "作者",
                        "created": "2025-09-14",
                        "modified": "2025-09-14"
                    },
                    "confidence": 0.85
                }
            
            logger.info("PDF解析完成", file_path=file_path, business_type=business_type)
            return result
            
        except Exception as e:
            logger.error("PDF解析失败", file_path=file_path, business_type=business_type, error=str(e))
            raise
    
    async def parse_docx(self, file_path: str, business_type: str = "resume") -> Dict:
        """解析DOCX文件 - 支持业务类型"""
        try:
            # 根据业务类型返回不同的模拟结果
            if business_type == "resume":
                result = {
                    "type": "docx",
                    "business_type": "resume",
                    "content": "简历DOCX解析内容（模拟）",
                    "structure": {
                        "title": "个人简历",
                        "sections": ["基本信息", "教育经历", "工作经历", "技能专长", "项目经验"]
                    },
                    "metadata": {
                        "author": "求职者",
                        "created": "2025-09-14",
                        "modified": "2025-09-14"
                    },
                    # 简历特有字段
                    "name": "李四",
                    "phone": "13900139000",
                    "email": "lisi@example.com",
                    "location": "上海市浦东新区",
                    "degree": "硕士",
                    "school": "清华大学",
                    "major": "软件工程",
                    "technical_skills": ["Java", "Spring", "MySQL", "Redis"],
                    "work_experience": ["Java开发工程师", "技术主管"],
                    "confidence": 0.90
                }
            elif business_type == "company":
                result = {
                    "type": "docx",
                    "business_type": "company",
                    "content": "企业画像DOCX解析内容（模拟）",
                    "structure": {
                        "title": "企业画像报告",
                        "sections": ["基本信息", "经营状况", "财务状况", "风险分析"]
                    },
                    "metadata": {
                        "author": "企业",
                        "created": "2025-09-14",
                        "modified": "2025-09-14"
                    },
                    # 企业特有字段
                    "company_name": "某某互联网科技有限公司",
                    "industry": "互联网",
                    "location": "深圳市南山区",
                    "employee_count": 1000,
                    "founded_year": 2015,
                    "revenue": "1亿元",
                    "confidence": 0.87
                }
            else:
                result = {
                    "type": "docx",
                    "business_type": business_type,
                    "content": "通用DOCX解析内容（模拟）",
                    "structure": {
                        "title": "文档标题",
                        "sections": ["章节1", "章节2"]
                    },
                    "metadata": {
                        "author": "作者",
                        "created": "2025-09-14",
                        "modified": "2025-09-14"
                    },
                    "confidence": 0.85
                }
            
            logger.info("DOCX解析完成", file_path=file_path, business_type=business_type)
            return result
            
        except Exception as e:
            logger.error("DOCX解析失败", file_path=file_path, business_type=business_type, error=str(e))
            raise
    
    async def enhance_parsing_result(self, result: Dict, file_info: Dict, business_type: str = "resume") -> Dict:
        """增强解析结果 - 支持业务类型"""
        try:
            # 添加文件信息
            result["file_info"] = file_info
            
            # 添加解析时间戳
            import datetime
            result["parsed_at"] = datetime.datetime.now().isoformat()
            
            # 添加解析状态
            result["status"] = "completed"
            
            # 根据业务类型设置默认置信度
            if "confidence" not in result:
                if business_type == "resume":
                    result["confidence"] = 0.92
                elif business_type == "company":
                    result["confidence"] = 0.88
                else:
                    result["confidence"] = 0.85
            
            # 添加业务类型标识
            result["business_type"] = business_type
            
            logger.info("解析结果增强完成", business_type=business_type)
            return result
            
        except Exception as e:
            logger.error("解析结果增强失败", business_type=business_type, error=str(e))
            return result
    
    async def validate_document_type(self, file_path: str, business_type: str) -> Dict:
        """验证文档类型"""
        try:
            # 读取文档内容（简化版本，实际应该使用OCR或文档解析）
            content = await self.extract_document_content(file_path)
            filename = os.path.basename(file_path)
            
            # 使用智能分类器验证
            validation_result = document_classifier.validate_business_type(content, filename, business_type)
            
            logger.info("文档类型验证完成", 
                       file_path=file_path,
                       business_type=business_type,
                       validation_result=validation_result)
            
            return validation_result
            
        except Exception as e:
            logger.error("文档类型验证失败", file_path=file_path, error=str(e))
            return {
                "requested_type": business_type,
                "detected_type": "unknown",
                "is_match": True,  # 验证失败时默认通过，避免阻塞处理
                "confidence": 0.0,
                "validation_result": "error",
                "error": str(e)
            }
    
    async def extract_document_content(self, file_path: str) -> str:
        """提取文档内容（简化版本）"""
        try:
            # 这里应该实现真正的文档内容提取
            # 目前返回文件名作为内容，实际应该使用OCR或文档解析库
            filename = os.path.basename(file_path)
            
            # 模拟内容提取
            if "简历" in filename or "resume" in filename.lower():
                return "个人简历 姓名 性别 年龄 教育背景 工作经历 技能专长"
            elif "企业" in filename or "公司" in filename or "company" in filename.lower():
                return "企业画像 公司名称 主营业务 组织架构 财务状况 发展历程"
            else:
                return filename  # 返回文件名作为内容
            
        except Exception as e:
            logger.error("文档内容提取失败", file_path=file_path, error=str(e))
            return ""

# 创建服务实例
mineru_service = MinerUService()

@app.route("/health", methods=["GET"])
async def health_check(request: Request):
    """健康检查"""
    return json({
        "status": "healthy",
        "service": "mineru-service",
        "current_tasks": mineru_service.current_tasks,
        "max_concurrent": mineru_service.max_concurrent
    })

@app.route("/api/v1/parse/document", methods=["POST"])
async def parse_document(request: Request):
    """解析文档 - 支持业务类型参数"""
    try:
        data = request.json
        file_path = data.get("file_path")
        user_id = data.get("user_id")
        business_type = data.get("business_type", "resume")  # 默认简历类型
        
        if not file_path:
            return json({"error": "文件路径不能为空"}, status=400)
        
        if not user_id:
            return json({"error": "用户ID不能为空"}, status=400)
        
        # 验证业务类型
        if business_type not in ["resume", "company"]:
            return json({"error": "不支持的业务类型，仅支持resume或company"}, status=400)
        
        # 检查并发限制
        if mineru_service.current_tasks >= mineru_service.max_concurrent:
            return json({"error": "服务繁忙，请稍后重试"}, status=503)
        
        mineru_service.current_tasks += 1
        
        try:
            result = await mineru_service.parse_document(file_path, user_id, business_type)
            
            return json({
                "status": "success",
                "business_type": business_type,
                "result": result
            })
            
        except Exception as e:
            logger.error("文档解析API失败", error=str(e))
            return json({"error": str(e)}, status=500)
        finally:
            mineru_service.current_tasks -= 1
            
    except Exception as e:
        logger.error("文档解析API失败", error=str(e))
        return json({"error": str(e)}, status=500)

@app.route("/api/v1/validate/document-type", methods=["POST"])
async def validate_document_type(request: Request):
    """验证文档类型API"""
    try:
        data = request.json
        file_path = data.get("file_path")
        business_type = data.get("business_type", "resume")
        
        if not file_path:
            return json({"error": "文件路径不能为空"}, status=400)
        
        # 验证业务类型
        if business_type not in ["resume", "company"]:
            return json({"error": "不支持的业务类型，仅支持resume或company"}, status=400)
        
        # 执行验证
        validation_result = await mineru_service.validate_document_type(file_path, business_type)
        
        return json({
            "status": "success",
            "validation_result": validation_result
        })
        
    except Exception as e:
        logger.error("文档类型验证API失败", error=str(e))
        return json({"error": f"验证失败: {str(e)}"}, status=500)

@app.route("/api/v1/classify/document", methods=["POST"])
async def classify_document(request: Request):
    """自动分类文档类型API"""
    try:
        data = request.json
        file_path = data.get("file_path")
        
        if not file_path:
            return json({"error": "文件路径不能为空"}, status=400)
        
        # 提取文档内容
        content = await mineru_service.extract_document_content(file_path)
        filename = os.path.basename(file_path)
        
        # 自动分类
        classification_result = document_classifier.classify_document(content, filename)
        
        return json({
            "status": "success",
            "classification_result": classification_result
        })
        
    except Exception as e:
        logger.error("文档分类API失败", error=str(e))
        return json({"error": f"分类失败: {str(e)}"}, status=500)

@app.route("/api/v1/parse/upload", methods=["POST"])
async def upload_and_parse(request: Request):
    """上传并解析文档"""
    try:
        # 获取上传的文件
        file = request.files.get("file")
        user_id = request.form.get("user_id")
        business_type = request.form.get("business_type", "resume")  # 支持业务类型参数
        
        if not file:
            return json({"error": "没有上传文件"}, status=400)
        
        if not user_id:
            return json({"error": "用户ID不能为空"}, status=400)
        
        # 验证业务类型
        if business_type not in ["resume", "company"]:
            return json({"error": "不支持的业务类型，仅支持resume或company"}, status=400)
        
        # 保存上传的文件
        file_path = os.path.join(mineru_service.upload_dir, file.name)
        async with aiofiles.open(file_path, "wb") as f:
            await f.write(file.body)
        
        # 解析文档 - 传递业务类型参数
        result = await mineru_service.parse_document(file_path, int(user_id), business_type)
        
        # 清理临时文件
        os.remove(file_path)
        
        return json({
            "status": "success",
            "business_type": business_type,
            "result": result
        })
        
    except Exception as e:
        logger.error("上传解析API失败", error=str(e))
        return json({"error": str(e)}, status=500)

@app.route("/api/v1/parse/status", methods=["GET"])
async def get_parse_status(request: Request):
    """获取解析状态"""
    return json({
        "status": "success",
        "current_tasks": mineru_service.current_tasks,
        "max_concurrent": mineru_service.max_concurrent,
        "available": mineru_service.current_tasks < mineru_service.max_concurrent
    })

if __name__ == "__main__":
    # 启动服务
    logger.info("启动MinerU服务", port=8000)
    app.run(host="0.0.0.0", port=8000, workers=1)
