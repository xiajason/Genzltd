#!/usr/bin/env python3
"""
能力评估框架API服务
提供技术能力和业务能力的综合评估REST API接口
"""

import asyncio
import json
import structlog
from datetime import datetime
from typing import Dict, List, Any, Optional
from sanic import Sanic, Request, response
from sanic.response import json as sanic_json
from competency_assessment_engine import (
    CompetencyAssessmentEngine, CompetencyLevel, 
    TechnicalCompetencyType, BusinessCompetencyType
)

logger = structlog.get_logger()

app = Sanic("CompetencyAssessmentAPI")

# 全局能力评估引擎实例
competency_engine = CompetencyAssessmentEngine()

@app.before_server_start
async def setup_db(app, loop):
    """服务启动前初始化"""
    logger.info("初始化能力评估框架API服务")
    # 这里可以添加数据库连接初始化
    logger.info("能力评估框架API服务初始化完成")

@app.route("/health", methods=["GET"])
async def health_check(request: Request):
    """健康检查"""
    return sanic_json({
        "status": "healthy",
        "service": "competency_assessment_api",
        "timestamp": datetime.now().isoformat()
    })

@app.route("/api/v1/competency/assess_technical", methods=["POST"])
async def assess_technical_competency(request: Request):
    """技术能力评估接口"""
    try:
        data = request.json
        text = data.get("text", "").strip()
        
        if not text:
            return sanic_json({
                "error": "评估文本不能为空"
            }, status=400)
        
        competencies = await competency_engine.assess_technical_competency(text)
        
        formatted_competencies = []
        for competency in competencies:
            formatted_competencies.append({
                "competency_type": competency.competency_type.value,
                "level": competency.level.value,
                "level_name": competency.level.name,
                "score": competency.score,
                "confidence": competency.confidence,
                "evidence": competency.evidence,
                "keywords_matched": competency.keywords_matched,
                "assessment_details": competency.assessment_details
            })
        
        return sanic_json({
            "status": "success",
            "text": text,
            "technical_competencies": formatted_competencies,
            "competencies_count": len(formatted_competencies),
            "timestamp": datetime.now().isoformat()
        })
        
    except Exception as e:
        logger.error("技术能力评估失败", error=str(e))
        return sanic_json({
            "error": f"技术能力评估失败: {str(e)}"
        }, status=500)

@app.route("/api/v1/competency/assess_business", methods=["POST"])
async def assess_business_competency(request: Request):
    """业务能力评估接口"""
    try:
        data = request.json
        text = data.get("text", "").strip()
        
        if not text:
            return sanic_json({
                "error": "评估文本不能为空"
            }, status=400)
        
        competencies = await competency_engine.assess_business_competency(text)
        
        formatted_competencies = []
        for competency in competencies:
            formatted_competencies.append({
                "competency_type": competency.competency_type.value,
                "level": competency.level.value,
                "level_name": competency.level.name,
                "score": competency.score,
                "confidence": competency.confidence,
                "evidence": competency.evidence,
                "keywords_matched": competency.keywords_matched,
                "assessment_details": competency.assessment_details
            })
        
        return sanic_json({
            "status": "success",
            "text": text,
            "business_competencies": formatted_competencies,
            "competencies_count": len(formatted_competencies),
            "timestamp": datetime.now().isoformat()
        })
        
    except Exception as e:
        logger.error("业务能力评估失败", error=str(e))
        return sanic_json({
            "error": f"业务能力评估失败: {str(e)}"
        }, status=500)

@app.route("/api/v1/competency/assess_comprehensive", methods=["POST"])
async def assess_comprehensive_competency(request: Request):
    """综合能力评估接口"""
    try:
        data = request.json
        text = data.get("text", "").strip()
        
        if not text:
            return sanic_json({
                "error": "评估文本不能为空"
            }, status=400)
        
        assessment = await competency_engine.assess_competency(text)
        
        # 格式化技术能力
        formatted_technical = []
        for competency in assessment.technical_competencies:
            formatted_technical.append({
                "competency_type": competency.competency_type.value,
                "level": competency.level.value,
                "level_name": competency.level.name,
                "score": competency.score,
                "confidence": competency.confidence,
                "evidence": competency.evidence,
                "keywords_matched": competency.keywords_matched
            })
        
        # 格式化业务能力
        formatted_business = []
        for competency in assessment.business_competencies:
            formatted_business.append({
                "competency_type": competency.competency_type.value,
                "level": competency.level.value,
                "level_name": competency.level.name,
                "score": competency.score,
                "confidence": competency.confidence,
                "evidence": competency.evidence,
                "keywords_matched": competency.keywords_matched
            })
        
        return sanic_json({
            "status": "success",
            "text": text,
            "assessment": {
                "technical_competencies": formatted_technical,
                "business_competencies": formatted_business,
                "overall_technical_score": assessment.overall_technical_score,
                "overall_business_score": assessment.overall_business_score,
                "overall_score": assessment.overall_score,
                "competency_profile": assessment.competency_profile,
                "growth_recommendations": assessment.growth_recommendations
            },
            "summary": {
                "total_technical_competencies": len(formatted_technical),
                "total_business_competencies": len(formatted_business),
                "overall_score": assessment.overall_score,
                "technical_score": assessment.overall_technical_score,
                "business_score": assessment.overall_business_score
            },
            "timestamp": datetime.now().isoformat()
        })
        
    except Exception as e:
        logger.error("综合能力评估失败", error=str(e))
        return sanic_json({
            "error": f"综合能力评估失败: {str(e)}"
        }, status=500)

@app.route("/api/v1/competency/batch_assessment", methods=["POST"])
async def batch_competency_assessment(request: Request):
    """批量能力评估接口"""
    try:
        data = request.json
        texts = data.get("texts", [])
        
        if not texts or not isinstance(texts, list):
            return sanic_json({
                "error": "评估文本列表不能为空"
            }, status=400)
        
        results = []
        total_technical_score = 0.0
        total_business_score = 0.0
        total_overall_score = 0.0
        
        for i, text in enumerate(texts):
            try:
                assessment = await competency_engine.assess_competency(text)
                
                results.append({
                    "index": i,
                    "text": text[:100] + "..." if len(text) > 100 else text,
                    "overall_score": assessment.overall_score,
                    "technical_score": assessment.overall_technical_score,
                    "business_score": assessment.overall_business_score,
                    "technical_competencies_count": len(assessment.technical_competencies),
                    "business_competencies_count": len(assessment.business_competencies),
                    "assessment": {
                        "technical_competencies": [
                            {
                                "type": c.competency_type.value,
                                "level": c.level.value,
                                "score": c.score
                            } for c in assessment.technical_competencies
                        ],
                        "business_competencies": [
                            {
                                "type": c.competency_type.value,
                                "level": c.level.value,
                                "score": c.score
                            } for c in assessment.business_competencies
                        ]
                    }
                })
                
                total_technical_score += assessment.overall_technical_score
                total_business_score += assessment.overall_business_score
                total_overall_score += assessment.overall_score
                
            except Exception as e:
                results.append({
                    "index": i,
                    "text": text[:100] + "..." if len(text) > 100 else text,
                    "error": str(e)
                })
        
        success_count = sum(1 for r in results if "error" not in r)
        avg_technical_score = total_technical_score / success_count if success_count > 0 else 0.0
        avg_business_score = total_business_score / success_count if success_count > 0 else 0.0
        avg_overall_score = total_overall_score / success_count if success_count > 0 else 0.0
        
        return sanic_json({
            "status": "success",
            "total_texts": len(texts),
            "successful_assessments": success_count,
            "success_rate": success_count / len(texts) * 100,
            "average_scores": {
                "technical": avg_technical_score,
                "business": avg_business_score,
                "overall": avg_overall_score
            },
            "results": results,
            "timestamp": datetime.now().isoformat()
        })
        
    except Exception as e:
        logger.error("批量能力评估失败", error=str(e))
        return sanic_json({
            "error": f"批量能力评估失败: {str(e)}"
        }, status=500)

@app.route("/api/v1/competency/competency_levels", methods=["GET"])
async def get_competency_levels(request: Request):
    """获取能力等级列表接口"""
    try:
        levels = []
        for level in CompetencyLevel:
            levels.append({
                "level": level.value,
                "name": level.name,
                "description": self._get_competency_level_description(level)
            })
        
        return sanic_json({
            "status": "success",
            "competency_levels": levels,
            "total_levels": len(levels),
            "timestamp": datetime.now().isoformat()
        })
        
    except Exception as e:
        logger.error("获取能力等级失败", error=str(e))
        return sanic_json({
            "error": f"获取能力等级失败: {str(e)}"
        }, status=500)

def _get_competency_level_description(level: CompetencyLevel) -> str:
    """获取能力等级描述"""
    descriptions = {
        CompetencyLevel.BEGINNER: "初级水平",
        CompetencyLevel.INTERMEDIATE: "中级水平",
        CompetencyLevel.ADVANCED: "高级水平",
        CompetencyLevel.EXPERT: "专家水平",
        CompetencyLevel.MASTER: "大师水平"
    }
    return descriptions.get(level, "未知等级")

@app.route("/api/v1/competency/technical_competency_types", methods=["GET"])
async def get_technical_competency_types(request: Request):
    """获取技术能力类型列表接口"""
    try:
        types = []
        for competency_type in TechnicalCompetencyType:
            types.append({
                "type": competency_type.value,
                "display_name": competency_type.value.replace("_", " ").title(),
                "description": self._get_technical_competency_description(competency_type)
            })
        
        return sanic_json({
            "status": "success",
            "technical_competency_types": types,
            "total_types": len(types),
            "timestamp": datetime.now().isoformat()
        })
        
    except Exception as e:
        logger.error("获取技术能力类型失败", error=str(e))
        return sanic_json({
            "error": f"获取技术能力类型失败: {str(e)}"
        }, status=500)

def _get_technical_competency_description(competency_type: TechnicalCompetencyType) -> str:
    """获取技术能力类型描述"""
    descriptions = {
        TechnicalCompetencyType.PROGRAMMING: "编程能力",
        TechnicalCompetencyType.ALGORITHM_DESIGN: "算法设计能力",
        TechnicalCompetencyType.SYSTEM_ARCHITECTURE: "系统架构能力",
        TechnicalCompetencyType.DATABASE_DESIGN: "数据库设计能力",
        TechnicalCompetencyType.TESTING: "测试能力",
        TechnicalCompetencyType.DEVOPS: "DevOps能力",
        TechnicalCompetencyType.SECURITY: "安全能力",
        TechnicalCompetencyType.PERFORMANCE: "性能优化能力"
    }
    return descriptions.get(competency_type, "未知类型")

@app.route("/api/v1/competency/business_competency_types", methods=["GET"])
async def get_business_competency_types(request: Request):
    """获取业务能力类型列表接口"""
    try:
        types = []
        for competency_type in BusinessCompetencyType:
            types.append({
                "type": competency_type.value,
                "display_name": competency_type.value.replace("_", " ").title(),
                "description": self._get_business_competency_description(competency_type)
            })
        
        return sanic_json({
            "status": "success",
            "business_competency_types": types,
            "total_types": len(types),
            "timestamp": datetime.now().isoformat()
        })
        
    except Exception as e:
        logger.error("获取业务能力类型失败", error=str(e))
        return sanic_json({
            "error": f"获取业务能力类型失败: {str(e)}"
        }, status=500)

def _get_business_competency_description(competency_type: BusinessCompetencyType) -> str:
    """获取业务能力类型描述"""
    descriptions = {
        BusinessCompetencyType.REQUIREMENTS_ANALYSIS: "需求分析能力",
        BusinessCompetencyType.PROJECT_MANAGEMENT: "项目管理能力",
        BusinessCompetencyType.COMMUNICATION: "沟通能力",
        BusinessCompetencyType.PROBLEM_SOLVING: "问题解决能力",
        BusinessCompetencyType.TEAMWORK: "团队协作能力",
        BusinessCompetencyType.LEADERSHIP: "领导力",
        BusinessCompetencyType.INNOVATION: "创新能力",
        BusinessCompetencyType.BUSINESS_ACUMEN: "商业洞察能力"
    }
    return descriptions.get(competency_type, "未知类型")

@app.route("/api/v1/competency/benchmark", methods=["POST"])
async def get_competency_benchmark(request: Request):
    """获取能力基准对比接口"""
    try:
        data = request.json
        technical_score = data.get("technical_score", 0.0)
        business_score = data.get("business_score", 0.0)
        overall_score = data.get("overall_score", 0.0)
        industry = data.get("industry", "tech")
        role_level = data.get("role_level", "MIDDLE")
        
        # 模拟基准数据查询 (实际应用中从数据库查询)
        benchmarks = {
            "tech": {
                "JUNIOR": {"technical": 2.1, "business": 1.8, "overall": 2.0},
                "MIDDLE": {"technical": 3.2, "business": 2.8, "overall": 3.0},
                "SENIOR": {"technical": 4.1, "business": 3.6, "overall": 3.9},
                "LEAD": {"technical": 4.5, "business": 4.2, "overall": 4.4},
                "PRINCIPAL": {"technical": 4.8, "business": 4.6, "overall": 4.7},
                "EXPERT": {"technical": 5.0, "business": 4.8, "overall": 4.9}
            }
        }
        
        industry_benchmarks = benchmarks.get(industry, benchmarks["tech"])
        role_benchmark = industry_benchmarks.get(role_level, industry_benchmarks["MIDDLE"])
        
        # 计算对比结果
        comparison = {
            "technical": {
                "user_score": technical_score,
                "benchmark_score": role_benchmark["technical"],
                "difference": technical_score - role_benchmark["technical"],
                "percentile": min(100, max(0, (technical_score / 5.0) * 100))
            },
            "business": {
                "user_score": business_score,
                "benchmark_score": role_benchmark["business"],
                "difference": business_score - role_benchmark["business"],
                "percentile": min(100, max(0, (business_score / 5.0) * 100))
            },
            "overall": {
                "user_score": overall_score,
                "benchmark_score": role_benchmark["overall"],
                "difference": overall_score - role_benchmark["overall"],
                "percentile": min(100, max(0, (overall_score / 5.0) * 100))
            }
        }
        
        return sanic_json({
            "status": "success",
            "comparison": comparison,
            "benchmark_info": {
                "industry": industry,
                "role_level": role_level,
                "benchmark_scores": role_benchmark
            },
            "timestamp": datetime.now().isoformat()
        })
        
    except Exception as e:
        logger.error("获取能力基准失败", error=str(e))
        return sanic_json({
            "error": f"获取能力基准失败: {str(e)}"
        }, status=500)

if __name__ == "__main__":
    app.run(
        host="0.0.0.0",
        port=8211,
        debug=True,
        access_log=True
    )
