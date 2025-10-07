#!/usr/bin/env python3
"""
经验量化分析API服务
提供经验量化分析、项目复杂度评估、成果提取等REST API接口
"""

import asyncio
import json
import structlog
from datetime import datetime
from typing import Dict, List, Any, Optional
from sanic import Sanic, Request, response
from sanic.response import json as sanic_json
from experience_quantification_engine import (
    ExperienceQuantificationEngine, ComplexityLevel, AchievementType
)

logger = structlog.get_logger()

app = Sanic("ExperienceQuantificationAPI")

# 全局经验量化引擎实例
experience_engine = ExperienceQuantificationEngine()

@app.before_server_start
async def setup_db(app, loop):
    """服务启动前初始化"""
    logger.info("初始化经验量化分析API服务")
    # 这里可以添加数据库连接初始化
    logger.info("经验量化分析API服务初始化完成")

@app.route("/health", methods=["GET"])
async def health_check(request: Request):
    """健康检查"""
    return sanic_json({
        "status": "healthy",
        "service": "experience_quantification_api",
        "timestamp": datetime.now().isoformat()
    })

@app.route("/api/v1/experience/analyze_complexity", methods=["POST"])
async def analyze_project_complexity(request: Request):
    """项目复杂度分析接口"""
    try:
        data = request.json
        project_description = data.get("project_description", "").strip()
        
        if not project_description:
            return sanic_json({
                "error": "项目描述不能为空"
            }, status=400)
        
        complexity = await experience_engine.analyze_project_complexity(project_description)
        
        return sanic_json({
            "status": "success",
            "project_description": project_description,
            "complexity_analysis": {
                "technical_complexity": complexity.technical_complexity,
                "business_complexity": complexity.business_complexity,
                "team_complexity": complexity.team_complexity,
                "overall_complexity": complexity.overall_complexity,
                "complexity_level": complexity.complexity_level.value,
                "complexity_factors": complexity.complexity_factors
            },
            "timestamp": datetime.now().isoformat()
        })
        
    except Exception as e:
        logger.error("项目复杂度分析失败", error=str(e))
        return sanic_json({
            "error": f"项目复杂度分析失败: {str(e)}"
        }, status=500)

@app.route("/api/v1/experience/extract_achievements", methods=["POST"])
async def extract_quantified_achievements(request: Request):
    """量化成果提取接口"""
    try:
        data = request.json
        experience_text = data.get("experience_text", "").strip()
        
        if not experience_text:
            return sanic_json({
                "error": "经验文本不能为空"
            }, status=400)
        
        achievements = await experience_engine.extract_quantified_achievements(experience_text)
        
        formatted_achievements = []
        for achievement in achievements:
            formatted_achievements.append({
                "achievement_type": achievement.achievement_type.value,
                "description": achievement.description,
                "metric": achievement.metric,
                "value": achievement.value,
                "unit": achievement.unit,
                "impact_score": achievement.impact_score,
                "confidence": achievement.confidence
            })
        
        return sanic_json({
            "status": "success",
            "experience_text": experience_text,
            "achievements": formatted_achievements,
            "achievements_count": len(formatted_achievements),
            "timestamp": datetime.now().isoformat()
        })
        
    except Exception as e:
        logger.error("量化成果提取失败", error=str(e))
        return sanic_json({
            "error": f"量化成果提取失败: {str(e)}"
        }, status=500)

@app.route("/api/v1/experience/analyze_leadership", methods=["POST"])
async def analyze_leadership_indicators(request: Request):
    """领导力指标分析接口"""
    try:
        data = request.json
        experience_text = data.get("experience_text", "").strip()
        
        if not experience_text:
            return sanic_json({
                "error": "经验文本不能为空"
            }, status=400)
        
        leadership = await experience_engine.analyze_leadership_indicators(experience_text)
        
        return sanic_json({
            "status": "success",
            "experience_text": experience_text,
            "leadership_indicators": leadership,
            "leadership_score": sum(leadership.values()) / len(leadership) if leadership else 0.0,
            "timestamp": datetime.now().isoformat()
        })
        
    except Exception as e:
        logger.error("领导力指标分析失败", error=str(e))
        return sanic_json({
            "error": f"领导力指标分析失败: {str(e)}"
        }, status=500)

@app.route("/api/v1/experience/calculate_score", methods=["POST"])
async def calculate_experience_score(request: Request):
    """经验评分计算接口"""
    try:
        data = request.json
        experience_text = data.get("experience_text", "").strip()
        
        if not experience_text:
            return sanic_json({
                "error": "经验文本不能为空"
            }, status=400)
        
        # 综合分析
        analysis = await experience_engine.analyze_experience(experience_text)
        
        return sanic_json({
            "status": "success",
            "experience_text": experience_text,
            "experience_score": analysis.experience_score,
            "growth_trajectory": analysis.growth_trajectory,
            "complexity_analysis": {
                "technical_complexity": analysis.project_complexity.technical_complexity,
                "business_complexity": analysis.project_complexity.business_complexity,
                "team_complexity": analysis.project_complexity.team_complexity,
                "overall_complexity": analysis.project_complexity.overall_complexity,
                "complexity_level": analysis.project_complexity.complexity_level.value
            },
            "achievements_count": len(analysis.achievements),
            "leadership_score": sum(analysis.leadership_indicators.values()) / len(analysis.leadership_indicators) if analysis.leadership_indicators else 0.0,
            "timestamp": datetime.now().isoformat()
        })
        
    except Exception as e:
        logger.error("经验评分计算失败", error=str(e))
        return sanic_json({
            "error": f"经验评分计算失败: {str(e)}"
        }, status=500)

@app.route("/api/v1/experience/comprehensive_analysis", methods=["POST"])
async def comprehensive_experience_analysis(request: Request):
    """综合经验分析接口"""
    try:
        data = request.json
        experience_text = data.get("experience_text", "").strip()
        
        if not experience_text:
            return sanic_json({
                "error": "经验文本不能为空"
            }, status=400)
        
        # 综合分析
        analysis = await experience_engine.analyze_experience(experience_text)
        
        # 格式化成果
        formatted_achievements = []
        for achievement in analysis.achievements:
            formatted_achievements.append({
                "achievement_type": achievement.achievement_type.value,
                "description": achievement.description,
                "metric": achievement.metric,
                "value": achievement.value,
                "unit": achievement.unit,
                "impact_score": achievement.impact_score,
                "confidence": achievement.confidence
            })
        
        return sanic_json({
            "status": "success",
            "experience_text": experience_text,
            "analysis": {
                "experience_score": analysis.experience_score,
                "growth_trajectory": analysis.growth_trajectory,
                "project_complexity": {
                    "technical_complexity": analysis.project_complexity.technical_complexity,
                    "business_complexity": analysis.project_complexity.business_complexity,
                    "team_complexity": analysis.project_complexity.team_complexity,
                    "overall_complexity": analysis.project_complexity.overall_complexity,
                    "complexity_level": analysis.project_complexity.complexity_level.value,
                    "complexity_factors": analysis.project_complexity.complexity_factors
                },
                "achievements": formatted_achievements,
                "leadership_indicators": analysis.leadership_indicators
            },
            "summary": {
                "total_achievements": len(formatted_achievements),
                "leadership_score": sum(analysis.leadership_indicators.values()) / len(analysis.leadership_indicators) if analysis.leadership_indicators else 0.0,
                "complexity_level": analysis.project_complexity.complexity_level.value,
                "overall_score": analysis.experience_score
            },
            "timestamp": datetime.now().isoformat()
        })
        
    except Exception as e:
        logger.error("综合经验分析失败", error=str(e))
        return sanic_json({
            "error": f"综合经验分析失败: {str(e)}"
        }, status=500)

@app.route("/api/v1/experience/batch_analysis", methods=["POST"])
async def batch_experience_analysis(request: Request):
    """批量经验分析接口"""
    try:
        data = request.json
        experiences = data.get("experiences", [])
        
        if not experiences or not isinstance(experiences, list):
            return sanic_json({
                "error": "经验列表不能为空"
            }, status=400)
        
        results = []
        total_score = 0.0
        
        for i, experience_text in enumerate(experiences):
            try:
                analysis = await experience_engine.analyze_experience(experience_text)
                
                formatted_achievements = []
                for achievement in analysis.achievements:
                    formatted_achievements.append({
                        "achievement_type": achievement.achievement_type.value,
                        "description": achievement.description,
                        "metric": achievement.metric,
                        "value": achievement.value,
                        "unit": achievement.unit,
                        "impact_score": achievement.impact_score,
                        "confidence": achievement.confidence
                    })
                
                results.append({
                    "index": i,
                    "experience_text": experience_text[:100] + "..." if len(experience_text) > 100 else experience_text,
                    "experience_score": analysis.experience_score,
                    "complexity_level": analysis.project_complexity.complexity_level.value,
                    "achievements_count": len(formatted_achievements),
                    "leadership_score": sum(analysis.leadership_indicators.values()) / len(analysis.leadership_indicators) if analysis.leadership_indicators else 0.0,
                    "analysis": {
                        "project_complexity": {
                            "overall_complexity": analysis.project_complexity.overall_complexity,
                            "complexity_level": analysis.project_complexity.complexity_level.value
                        },
                        "achievements": formatted_achievements,
                        "leadership_indicators": analysis.leadership_indicators
                    }
                })
                
                total_score += analysis.experience_score
                
            except Exception as e:
                results.append({
                    "index": i,
                    "experience_text": experience_text[:100] + "..." if len(experience_text) > 100 else experience_text,
                    "error": str(e)
                })
        
        avg_score = total_score / len(results) if results else 0.0
        success_count = sum(1 for r in results if "error" not in r)
        
        return sanic_json({
            "status": "success",
            "total_experiences": len(experiences),
            "successful_analyses": success_count,
            "success_rate": success_count / len(experiences) * 100,
            "average_score": avg_score,
            "results": results,
            "timestamp": datetime.now().isoformat()
        })
        
    except Exception as e:
        logger.error("批量经验分析失败", error=str(e))
        return sanic_json({
            "error": f"批量经验分析失败: {str(e)}"
        }, status=500)

@app.route("/api/v1/experience/analyze_trajectory", methods=["POST"])
async def analyze_growth_trajectory(request: Request):
    """成长轨迹分析接口"""
    try:
        data = request.json
        experiences = data.get("experiences", [])
        
        if not experiences or not isinstance(experiences, list):
            return sanic_json({
                "error": "经验列表不能为空"
            }, status=400)
        
        if len(experiences) < 2:
            return sanic_json({
                "error": "至少需要2个经验才能分析成长轨迹"
            }, status=400)
        
        # 分析成长轨迹
        growth_trajectory = await experience_engine.analyze_growth_trajectory(experiences)
        
        # 分析每个经验
        experience_analyses = []
        for i, experience_text in enumerate(experiences):
            analysis = await experience_engine.analyze_experience(experience_text)
            experience_analyses.append({
                "index": i,
                "experience_score": analysis.experience_score,
                "complexity_level": analysis.project_complexity.complexity_level.value,
                "achievements_count": len(analysis.achievements),
                "leadership_score": sum(analysis.leadership_indicators.values()) / len(analysis.leadership_indicators) if analysis.leadership_indicators else 0.0
            })
        
        return sanic_json({
            "status": "success",
            "total_experiences": len(experiences),
            "growth_trajectory": growth_trajectory,
            "experience_analyses": experience_analyses,
            "trajectory_analysis": {
                "growth_rate": growth_trajectory,
                "trend": "increasing" if growth_trajectory > 0.6 else "stable" if growth_trajectory > 0.4 else "decreasing",
                "recommendation": "持续发展" if growth_trajectory > 0.6 else "保持稳定" if growth_trajectory > 0.4 else "需要改进"
            },
            "timestamp": datetime.now().isoformat()
        })
        
    except Exception as e:
        logger.error("成长轨迹分析失败", error=str(e))
        return sanic_json({
            "error": f"成长轨迹分析失败: {str(e)}"
        }, status=500)

@app.route("/api/v1/experience/achievement_types", methods=["GET"])
async def get_achievement_types(request: Request):
    """获取成果类型列表接口"""
    try:
        achievement_types = []
        for achievement_type in AchievementType:
            achievement_types.append({
                "type": achievement_type.value,
                "display_name": achievement_type.value.replace("_", " ").title(),
                "description": self._get_achievement_type_description(achievement_type)
            })
        
        return sanic_json({
            "status": "success",
            "achievement_types": achievement_types,
            "total_types": len(achievement_types),
            "timestamp": datetime.now().isoformat()
        })
        
    except Exception as e:
        logger.error("获取成果类型失败", error=str(e))
        return sanic_json({
            "error": f"获取成果类型失败: {str(e)}"
        }, status=500)

def _get_achievement_type_description(achievement_type: AchievementType) -> str:
    """获取成果类型描述"""
    descriptions = {
        AchievementType.PERFORMANCE: "性能提升相关成果",
        AchievementType.EFFICIENCY: "效率提升相关成果",
        AchievementType.COST_SAVING: "成本节约相关成果",
        AchievementType.REVENUE: "收入增长相关成果",
        AchievementType.USER_GROWTH: "用户增长相关成果",
        AchievementType.QUALITY: "质量提升相关成果",
        AchievementType.INNOVATION: "创新成果",
        AchievementType.TEAM: "团队建设相关成果"
    }
    return descriptions.get(achievement_type, "未知类型")

@app.route("/api/v1/experience/complexity_levels", methods=["GET"])
async def get_complexity_levels(request: Request):
    """获取复杂度等级列表接口"""
    try:
        complexity_levels = []
        for level in ComplexityLevel:
            complexity_levels.append({
                "level": level.value,
                "numeric_value": level.value,
                "display_name": level.value.replace("_", " ").title(),
                "description": self._get_complexity_level_description(level)
            })
        
        return sanic_json({
            "status": "success",
            "complexity_levels": complexity_levels,
            "total_levels": len(complexity_levels),
            "timestamp": datetime.now().isoformat()
        })
        
    except Exception as e:
        logger.error("获取复杂度等级失败", error=str(e))
        return sanic_json({
            "error": f"获取复杂度等级失败: {str(e)}"
        }, status=500)

def _get_complexity_level_description(level: ComplexityLevel) -> str:
    """获取复杂度等级描述"""
    descriptions = {
        ComplexityLevel.LOW: "低复杂度项目",
        ComplexityLevel.MEDIUM: "中等复杂度项目",
        ComplexityLevel.HIGH: "高复杂度项目",
        ComplexityLevel.VERY_HIGH: "非常高复杂度项目",
        ComplexityLevel.EXTREME: "极高复杂度项目"
    }
    return descriptions.get(level, "未知等级")

if __name__ == "__main__":
    app.run(
        host="0.0.0.0",
        port=8210,
        debug=True,
        access_log=True
    )
