#!/usr/bin/env python3
"""
智能文档分类器
基于文档内容自动识别文档类型（简历 vs 企业画像）
"""

import re
import logging
from typing import Dict, List, Optional
import structlog

logger = structlog.get_logger()

class DocumentClassifier:
    """智能文档分类器"""
    
    def __init__(self):
        # 简历关键词
        self.resume_keywords = [
            # 个人信息
            "个人简历", "简历", "个人简介", "求职简历", "应聘简历",
            "姓名", "性别", "年龄", "出生日期", "籍贯", "民族",
            "联系电话", "手机号码", "邮箱", "电子邮箱", "地址",
            
            # 教育背景
            "教育背景", "教育经历", "学历", "毕业院校", "专业",
            "学士", "硕士", "博士", "本科", "研究生", "大学",
            
            # 工作经历
            "工作经历", "工作经验", "职业经历", "工作履历",
            "公司", "职位", "岗位", "职责", "工作内容",
            
            # 技能专长
            "技能", "专长", "能力", "技术", "编程语言",
            "项目经验", "项目经历", "项目", "作品",
            
            # 其他
            "自我评价", "个人评价", "兴趣爱好", "获奖情况"
        ]
        
        # 企业画像关键词
        self.company_keywords = [
            # 企业基本信息
            "企业画像", "公司画像", "企业简介", "公司简介",
            "企业名称", "公司名称", "企业性质", "公司性质",
            "成立时间", "注册时间", "注册资本", "注册地址",
            
            # 经营信息
            "主营业务", "经营范围", "产品", "服务", "业务范围",
            "目标客户", "客户群体", "市场定位", "竞争优势",
            
            # 组织架构
            "组织架构", "部门设置", "人员规模", "员工数量",
            "管理层", "高管", "董事会", "监事会",
            
            # 财务信息
            "营业收入", "年收入", "利润", "财务状况",
            "融资情况", "投资", "上市", "股权结构",
            
            # 发展状况
            "发展历程", "里程碑", "重大事件", "荣誉资质",
            "合作伙伴", "供应商", "客户", "市场地位"
        ]
        
        # 权重配置
        self.resume_weight = 1.0
        self.company_weight = 1.0
        self.threshold = 0.6  # 分类阈值
    
    def classify_document(self, content: str, filename: str = "") -> Dict:
        """
        分类文档类型
        
        Args:
            content: 文档内容
            filename: 文件名（可选）
            
        Returns:
            Dict: 分类结果
        """
        try:
            # 基于文件名的初步判断
            filename_hint = self._analyze_filename(filename)
            
            # 基于内容的详细分析
            content_analysis = self._analyze_content(content)
            
            # 综合判断
            final_result = self._combine_analysis(filename_hint, content_analysis)
            
            logger.info("文档分类完成", 
                       filename=filename,
                       filename_hint=filename_hint,
                       content_analysis=content_analysis,
                       final_result=final_result)
            
            return final_result
            
        except Exception as e:
            logger.error("文档分类失败", error=str(e))
            return {
                "type": "unknown",
                "confidence": 0.0,
                "reason": f"分类失败: {str(e)}"
            }
    
    def _analyze_filename(self, filename: str) -> Dict:
        """分析文件名"""
        if not filename:
            return {"type": "unknown", "confidence": 0.0}
        
        filename_lower = filename.lower()
        
        # 简历文件名特征
        resume_patterns = [
            r"简历", r"resume", r"个人简介", r"求职", r"应聘",
            r"cv", r"curriculum", r"vitae"
        ]
        
        # 企业画像文件名特征
        company_patterns = [
            r"企业画像", r"公司画像", r"企业简介", r"公司简介",
            r"company", r"profile", r"企业", r"公司"
        ]
        
        resume_score = sum(1 for pattern in resume_patterns if re.search(pattern, filename_lower))
        company_score = sum(1 for pattern in company_patterns if re.search(pattern, filename_lower))
        
        if resume_score > company_score:
            return {"type": "resume", "confidence": min(0.8, resume_score * 0.2)}
        elif company_score > resume_score:
            return {"type": "company", "confidence": min(0.8, company_score * 0.2)}
        else:
            return {"type": "unknown", "confidence": 0.0}
    
    def _analyze_content(self, content: str) -> Dict:
        """分析文档内容"""
        if not content:
            return {"type": "unknown", "confidence": 0.0}
        
        content_lower = content.lower()
        
        # 计算关键词匹配度
        resume_matches = sum(1 for keyword in self.resume_keywords if keyword in content_lower)
        company_matches = sum(1 for keyword in self.company_keywords if keyword in content_lower)
        
        # 计算置信度
        total_keywords = len(self.resume_keywords) + len(self.company_keywords)
        resume_confidence = resume_matches / len(self.resume_keywords)
        company_confidence = company_matches / len(self.company_keywords)
        
        # 判断类型
        if resume_confidence > company_confidence and resume_confidence > self.threshold:
            return {
                "type": "resume",
                "confidence": resume_confidence,
                "matches": resume_matches,
                "total_keywords": len(self.resume_keywords)
            }
        elif company_confidence > resume_confidence and company_confidence > self.threshold:
            return {
                "type": "company", 
                "confidence": company_confidence,
                "matches": company_matches,
                "total_keywords": len(self.company_keywords)
            }
        else:
            return {
                "type": "unknown",
                "confidence": max(resume_confidence, company_confidence),
                "resume_matches": resume_matches,
                "company_matches": company_matches
            }
    
    def _combine_analysis(self, filename_hint: Dict, content_analysis: Dict) -> Dict:
        """综合文件名和内容分析"""
        # 权重分配：文件名30%，内容70%
        filename_weight = 0.3
        content_weight = 0.7
        
        # 如果文件名和内容分析结果一致
        if filename_hint["type"] == content_analysis["type"] and filename_hint["type"] != "unknown":
            combined_confidence = (
                filename_hint["confidence"] * filename_weight + 
                content_analysis["confidence"] * content_weight
            )
            return {
                "type": filename_hint["type"],
                "confidence": combined_confidence,
                "method": "combined",
                "filename_hint": filename_hint,
                "content_analysis": content_analysis
            }
        
        # 如果结果不一致，优先使用内容分析
        if content_analysis["confidence"] > filename_hint["confidence"]:
            return {
                "type": content_analysis["type"],
                "confidence": content_analysis["confidence"],
                "method": "content_priority",
                "filename_hint": filename_hint,
                "content_analysis": content_analysis
            }
        else:
            return {
                "type": filename_hint["type"],
                "confidence": filename_hint["confidence"],
                "method": "filename_priority",
                "filename_hint": filename_hint,
                "content_analysis": content_analysis
            }
    
    def validate_business_type(self, content: str, filename: str, requested_type: str) -> Dict:
        """
        验证请求的业务类型是否与文档内容匹配
        
        Args:
            content: 文档内容
            filename: 文件名
            requested_type: 请求的业务类型
            
        Returns:
            Dict: 验证结果
        """
        try:
            # 自动分类
            auto_classification = self.classify_document(content, filename)
            
            # 验证匹配度
            is_match = auto_classification["type"] == requested_type
            confidence_diff = abs(auto_classification["confidence"] - 0.5)
            
            result = {
                "requested_type": requested_type,
                "detected_type": auto_classification["type"],
                "is_match": is_match,
                "confidence": auto_classification["confidence"],
                "validation_result": "pass" if is_match else "fail",
                "auto_classification": auto_classification,
                "recommendation": auto_classification["type"] if not is_match else None
            }
            
            logger.info("业务类型验证完成", 
                       requested_type=requested_type,
                       detected_type=auto_classification["type"],
                       is_match=is_match,
                       confidence=auto_classification["confidence"])
            
            return result
            
        except Exception as e:
            logger.error("业务类型验证失败", error=str(e))
            return {
                "requested_type": requested_type,
                "detected_type": "unknown",
                "is_match": False,
                "confidence": 0.0,
                "validation_result": "error",
                "error": str(e)
            }

# 创建全局分类器实例
document_classifier = DocumentClassifier()
