#!/usr/bin/env python3
"""
技能标准化API服务
提供技能标准化、匹配、评估等REST API接口
"""

import asyncio
import json
import structlog
from datetime import datetime
from typing import Dict, List, Any, Optional
from sanic import Sanic, Request, response
from sanic.response import json as sanic_json
from skill_standardization_engine import SkillStandardizationEngine, SkillCategory, SkillLevel

logger = structlog.get_logger()

app = Sanic("SkillStandardizationAPI")

# 全局技能引擎实例
skill_engine = SkillStandardizationEngine()

@app.before_server_start
async def setup_db(app, loop):
    """服务启动前初始化"""
    logger.info("初始化技能标准化API服务")
    await skill_engine.initialize()
    logger.info("技能标准化API服务初始化完成")

@app.route("/health", methods=["GET"])
async def health_check(request: Request):
    """健康检查"""
    return sanic_json({
        "status": "healthy",
        "service": "skill_standardization_api",
        "timestamp": datetime.now().isoformat(),
        "initialized": skill_engine.initialized
    })

@app.route("/api/v1/skills/standardize", methods=["POST"])
async def standardize_skill(request: Request):
    """技能标准化接口"""
    try:
        data = request.json
        raw_skill = data.get("skill", "").strip()
        
        if not raw_skill:
            return sanic_json({
                "error": "技能名称不能为空"
            }, status=400)
        
        standardized_skill = await skill_engine.standardize_skill(raw_skill)
        
        if standardized_skill:
            return sanic_json({
                "status": "success",
                "original_skill": raw_skill,
                "standardized_skill": {
                    "name": standardized_skill.name,
                    "category": standardized_skill.category.value,
                    "description": standardized_skill.description,
                    "level": standardized_skill.level.value,
                    "aliases": standardized_skill.aliases,
                    "related_skills": standardized_skill.related_skills,
                    "industry_relevance": standardized_skill.industry_relevance
                },
                "timestamp": datetime.now().isoformat()
            })
        else:
            return sanic_json({
                "status": "not_found",
                "original_skill": raw_skill,
                "message": "未找到匹配的标准化技能",
                "timestamp": datetime.now().isoformat()
            })
            
    except Exception as e:
        logger.error("技能标准化失败", error=str(e))
        return sanic_json({
            "error": f"技能标准化失败: {str(e)}"
        }, status=500)

@app.route("/api/v1/skills/batch_standardize", methods=["POST"])
async def batch_standardize_skills(request: Request):
    """批量技能标准化接口"""
    try:
        data = request.json
        raw_skills = data.get("skills", [])
        
        if not raw_skills or not isinstance(raw_skills, list):
            return sanic_json({
                "error": "技能列表不能为空"
            }, status=400)
        
        results = []
        for raw_skill in raw_skills:
            standardized_skill = await skill_engine.standardize_skill(raw_skill)
            
            if standardized_skill:
                results.append({
                    "original_skill": raw_skill,
                    "standardized_skill": {
                        "name": standardized_skill.name,
                        "category": standardized_skill.category.value,
                        "description": standardized_skill.description,
                        "level": standardized_skill.level.value,
                        "aliases": standardized_skill.aliases,
                        "related_skills": standardized_skill.related_skills,
                        "industry_relevance": standardized_skill.industry_relevance
                    },
                    "status": "success"
                })
            else:
                results.append({
                    "original_skill": raw_skill,
                    "standardized_skill": None,
                    "status": "not_found"
                })
        
        success_count = sum(1 for r in results if r["status"] == "success")
        
        return sanic_json({
            "status": "success",
            "total_skills": len(raw_skills),
            "successful_standardizations": success_count,
            "success_rate": success_count / len(raw_skills) * 100,
            "results": results,
            "timestamp": datetime.now().isoformat()
        })
        
    except Exception as e:
        logger.error("批量技能标准化失败", error=str(e))
        return sanic_json({
            "error": f"批量技能标准化失败: {str(e)}"
        }, status=500)

@app.route("/api/v1/skills/calculate_level", methods=["POST"])
async def calculate_skill_level(request: Request):
    """计算技能等级接口"""
    try:
        data = request.json
        skill_name = data.get("skill", "").strip()
        experience = data.get("experience", "").strip()
        
        if not skill_name or not experience:
            return sanic_json({
                "error": "技能名称和经验描述不能为空"
            }, status=400)
        
        skill_level = await skill_engine.calculate_skill_level(skill_name, experience)
        
        return sanic_json({
            "status": "success",
            "skill": skill_name,
            "experience": experience,
            "calculated_level": skill_level.value,
            "level_numeric": skill_level.value,
            "timestamp": datetime.now().isoformat()
        })
        
    except Exception as e:
        logger.error("技能等级计算失败", error=str(e))
        return sanic_json({
            "error": f"技能等级计算失败: {str(e)}"
        }, status=500)

@app.route("/api/v1/skills/match", methods=["POST"])
async def match_skills(request: Request):
    """技能匹配接口"""
    try:
        data = request.json
        user_skills = data.get("user_skills", {})
        job_requirements = data.get("job_requirements", {})
        
        if not user_skills or not job_requirements:
            return sanic_json({
                "error": "用户技能和职位要求不能为空"
            }, status=400)
        
        match_result = await skill_engine.match_skill_requirements(user_skills, job_requirements)
        
        # 转换匹配结果格式
        formatted_matches = []
        for match in match_result["matches"]:
            formatted_matches.append({
                "user_skill": match.user_skill,
                "standard_skill": {
                    "name": match.standard_skill.name,
                    "category": match.standard_skill.category.value,
                    "description": match.standard_skill.description
                },
                "match_score": match.match_score,
                "match_type": match.match_type
            })
        
        return sanic_json({
            "status": "success",
            "overall_score": match_result["overall_score"],
            "match_percentage": match_result["match_percentage"],
            "total_requirements": match_result["total_requirements"],
            "matched_requirements": match_result["matched_requirements"],
            "matches": formatted_matches,
            "timestamp": datetime.now().isoformat()
        })
        
    except Exception as e:
        logger.error("技能匹配失败", error=str(e))
        return sanic_json({
            "error": f"技能匹配失败: {str(e)}"
        }, status=500)

@app.route("/api/v1/skills/search", methods=["GET"])
async def search_skills(request: Request):
    """搜索技能接口"""
    try:
        query = request.args.get("q", "").strip()
        limit = int(request.args.get("limit", 10))
        
        if not query:
            return sanic_json({
                "error": "搜索关键词不能为空"
            }, status=400)
        
        results = await skill_engine.search_skills(query, limit)
        
        formatted_results = []
        for skill in results:
            formatted_results.append({
                "name": skill.name,
                "category": skill.category.value,
                "description": skill.description,
                "level": skill.level.value,
                "aliases": skill.aliases,
                "related_skills": skill.related_skills,
                "industry_relevance": skill.industry_relevance
            })
        
        return sanic_json({
            "status": "success",
            "query": query,
            "total_results": len(formatted_results),
            "results": formatted_results,
            "timestamp": datetime.now().isoformat()
        })
        
    except Exception as e:
        logger.error("技能搜索失败", error=str(e))
        return sanic_json({
            "error": f"技能搜索失败: {str(e)}"
        }, status=500)

@app.route("/api/v1/skills/categories", methods=["GET"])
async def get_categories(request: Request):
    """获取技能分类接口"""
    try:
        categories = []
        for category in SkillCategory:
            skills = await skill_engine.get_skills_by_category(category)
            categories.append({
                "name": category.value,
                "display_name": category.value.replace("_", " ").title(),
                "skill_count": len(skills),
                "skills": [skill.name for skill in skills[:5]]  # 只返回前5个技能作为示例
            })
        
        return sanic_json({
            "status": "success",
            "categories": categories,
            "total_categories": len(categories),
            "timestamp": datetime.now().isoformat()
        })
        
    except Exception as e:
        logger.error("获取技能分类失败", error=str(e))
        return sanic_json({
            "error": f"获取技能分类失败: {str(e)}"
        }, status=500)

@app.route("/api/v1/skills/categories/<category_name>", methods=["GET"])
async def get_skills_by_category(request: Request, category_name: str):
    """根据分类获取技能接口"""
    try:
        try:
            category = SkillCategory(category_name)
        except ValueError:
            return sanic_json({
                "error": f"无效的技能分类: {category_name}"
            }, status=400)
        
        skills = await skill_engine.get_skills_by_category(category)
        
        formatted_skills = []
        for skill in skills:
            formatted_skills.append({
                "name": skill.name,
                "category": skill.category.value,
                "description": skill.description,
                "level": skill.level.value,
                "aliases": skill.aliases,
                "related_skills": skill.related_skills,
                "industry_relevance": skill.industry_relevance
            })
        
        return sanic_json({
            "status": "success",
            "category": category_name,
            "skills": formatted_skills,
            "total_skills": len(formatted_skills),
            "timestamp": datetime.now().isoformat()
        })
        
    except Exception as e:
        logger.error("获取分类技能失败", error=str(e))
        return sanic_json({
            "error": f"获取分类技能失败: {str(e)}"
        }, status=500)

@app.route("/api/v1/skills/stats", methods=["GET"])
async def get_skill_stats(request: Request):
    """获取技能统计信息接口"""
    try:
        stats = {
            "total_skills": len(skill_engine.skills_database),
            "categories": {
                category.value: len(skill_engine.category_index.get(category, []))
                for category in SkillCategory
            },
            "total_aliases": sum(len(skill.aliases) for skill in skill_engine.skills_database.values()),
            "popular_skills": [],
            "recent_searches": []  # 这里可以添加搜索历史统计
        }
        
        # 计算流行技能（基于行业相关性）
        skill_popularity = []
        for skill_name, skill in skill_engine.skills_database.items():
            avg_relevance = sum(skill.industry_relevance.values()) / len(skill.industry_relevance)
            skill_popularity.append((skill_name, avg_relevance))
        
        skill_popularity.sort(key=lambda x: x[1], reverse=True)
        stats["popular_skills"] = [skill_name for skill_name, _ in skill_popularity[:10]]
        
        return sanic_json({
            "status": "success",
            "stats": stats,
            "timestamp": datetime.now().isoformat()
        })
        
    except Exception as e:
        logger.error("获取技能统计失败", error=str(e))
        return sanic_json({
            "error": f"获取技能统计失败: {str(e)}"
        }, status=500)

@app.route("/api/v1/skills/recommend", methods=["POST"])
async def recommend_skills(request: Request):
    """技能推荐接口"""
    try:
        data = request.json
        user_skills = data.get("user_skills", [])
        target_role = data.get("target_role", "")
        industry = data.get("industry", "")
        
        if not user_skills:
            return sanic_json({
                "error": "用户技能列表不能为空"
            }, status=400)
        
        # 获取用户技能的标准化版本
        standardized_user_skills = []
        for skill in user_skills:
            standardized = await skill_engine.standardize_skill(skill)
            if standardized:
                standardized_user_skills.append(standardized)
        
        # 基于相关技能推荐
        recommendations = []
        seen_skills = set(skill.name for skill in standardized_user_skills)
        
        for user_skill in standardized_user_skills:
            for related_skill_name in user_skill.related_skills:
                if related_skill_name not in seen_skills:
                    related_skill = skill_engine.skills_database.get(related_skill_name.lower())
                    if related_skill:
                        recommendations.append({
                            "skill": related_skill.name,
                            "category": related_skill.category.value,
                            "description": related_skill.description,
                            "reason": f"与您的{user_skill.name}技能相关",
                            "relevance_score": 0.8
                        })
                        seen_skills.add(related_skill.name)
        
        # 基于行业推荐
        if industry:
            industry_recommendations = []
            for skill_name, skill in skill_engine.skills_database.items():
                if (skill_name not in seen_skills and 
                    industry in skill.industry_relevance and 
                    skill.industry_relevance[industry] > 0.7):
                    industry_recommendations.append({
                        "skill": skill.name,
                        "category": skill.category.value,
                        "description": skill.description,
                        "reason": f"在{industry}行业中很重要",
                        "relevance_score": skill.industry_relevance[industry]
                    })
            
            recommendations.extend(industry_recommendations)
        
        # 按相关性排序
        recommendations.sort(key=lambda x: x["relevance_score"], reverse=True)
        
        return sanic_json({
            "status": "success",
            "user_skills": [skill.name for skill in standardized_user_skills],
            "target_role": target_role,
            "industry": industry,
            "recommendations": recommendations[:10],  # 返回前10个推荐
            "total_recommendations": len(recommendations),
            "timestamp": datetime.now().isoformat()
        })
        
    except Exception as e:
        logger.error("技能推荐失败", error=str(e))
        return sanic_json({
            "error": f"技能推荐失败: {str(e)}"
        }, status=500)

if __name__ == "__main__":
    app.run(
        host="0.0.0.0",
        port=8209,
        debug=True,
        access_log=True
    )
