#!/usr/bin/env python3
"""
技能标准化引擎
基于LinkedIn技能分类标准，实现技能标准化和匹配功能
"""

import asyncio
import json
import os
import structlog
from datetime import datetime
from typing import Dict, List, Any, Optional, Tuple
from dataclasses import dataclass
from enum import Enum

logger = structlog.get_logger()

class SkillCategory(Enum):
    """技能分类枚举"""
    PROGRAMMING_LANGUAGE = "programming_language"
    FRAMEWORK = "framework"
    DATABASE = "database"
    CLOUD_SERVICE = "cloud_service"
    DEVELOPMENT_TOOL = "development_tool"
    SOFT_SKILL = "soft_skill"
    BUSINESS_SKILL = "business_skill"
    INDUSTRY_SKILL = "industry_skill"

class SkillLevel(Enum):
    """技能等级枚举"""
    BEGINNER = 1
    INTERMEDIATE = 2
    ADVANCED = 3
    EXPERT = 4
    MASTER = 5

@dataclass
class StandardizedSkill:
    """标准化技能数据模型"""
    name: str
    category: SkillCategory
    aliases: List[str]
    description: str
    level: SkillLevel
    related_skills: List[str]
    industry_relevance: Dict[str, float]  # 行业相关性评分

@dataclass
class SkillMatch:
    """技能匹配结果"""
    user_skill: str
    standard_skill: StandardizedSkill
    match_score: float
    match_type: str  # "exact", "alias", "similar", "related"

class SkillStandardizationEngine:
    """技能标准化引擎"""
    
    def __init__(self):
        self.skills_database: Dict[str, StandardizedSkill] = {}
        self.skill_index: Dict[str, List[str]] = {}  # 技能名称索引
        self.category_index: Dict[SkillCategory, List[str]] = {}  # 分类索引
        self.initialized = False
        
    async def initialize(self):
        """初始化技能数据库"""
        if self.initialized:
            return
            
        logger.info("开始初始化技能标准化引擎")
        
        # 加载技能分类数据
        await self._load_skill_categories()
        
        # 建立索引
        await self._build_indexes()
        
        self.initialized = True
        logger.info("技能标准化引擎初始化完成", 
                   total_skills=len(self.skills_database),
                   categories=len(self.category_index))
    
    async def _load_skill_categories(self):
        """加载技能分类数据"""
        # 编程语言技能
        programming_languages = [
            StandardizedSkill(
                name="Python",
                category=SkillCategory.PROGRAMMING_LANGUAGE,
                aliases=["python", "py", "python3"],
                description="Python编程语言",
                level=SkillLevel.INTERMEDIATE,
                related_skills=["Django", "Flask", "Pandas", "NumPy", "TensorFlow"],
                industry_relevance={"tech": 0.9, "finance": 0.8, "data": 0.95}
            ),
            StandardizedSkill(
                name="Java",
                category=SkillCategory.PROGRAMMING_LANGUAGE,
                aliases=["java", "jdk", "jvm"],
                description="Java编程语言",
                level=SkillLevel.INTERMEDIATE,
                related_skills=["Spring Boot", "Hibernate", "Maven", "Gradle"],
                industry_relevance={"tech": 0.9, "finance": 0.85, "enterprise": 0.95}
            ),
            StandardizedSkill(
                name="Go",
                category=SkillCategory.PROGRAMMING_LANGUAGE,
                aliases=["go", "golang", "go lang"],
                description="Go编程语言",
                level=SkillLevel.INTERMEDIATE,
                related_skills=["Gin", "Echo", "Docker", "Kubernetes"],
                industry_relevance={"tech": 0.8, "cloud": 0.9, "microservices": 0.85}
            ),
            StandardizedSkill(
                name="JavaScript",
                category=SkillCategory.PROGRAMMING_LANGUAGE,
                aliases=["javascript", "js", "ecmascript"],
                description="JavaScript编程语言",
                level=SkillLevel.INTERMEDIATE,
                related_skills=["Node.js", "React", "Vue.js", "TypeScript"],
                industry_relevance={"tech": 0.95, "web": 0.98, "frontend": 0.95}
            ),
            StandardizedSkill(
                name="TypeScript",
                category=SkillCategory.PROGRAMMING_LANGUAGE,
                aliases=["typescript", "ts", "tsx"],
                description="TypeScript编程语言",
                level=SkillLevel.INTERMEDIATE,
                related_skills=["JavaScript", "React", "Angular", "Node.js"],
                industry_relevance={"tech": 0.85, "web": 0.9, "frontend": 0.9}
            ),
            StandardizedSkill(
                name="C++",
                category=SkillCategory.PROGRAMMING_LANGUAGE,
                aliases=["c++", "cpp", "c plus plus"],
                description="C++编程语言",
                level=SkillLevel.ADVANCED,
                related_skills=["STL", "Boost", "CMake", "Qt"],
                industry_relevance={"tech": 0.8, "gaming": 0.9, "system": 0.95}
            ),
            StandardizedSkill(
                name="C#",
                category=SkillCategory.PROGRAMMING_LANGUAGE,
                aliases=["c#", "csharp", "c sharp"],
                description="C#编程语言",
                level=SkillLevel.INTERMEDIATE,
                related_skills=[".NET", "ASP.NET", "Entity Framework", "Xamarin"],
                industry_relevance={"tech": 0.8, "enterprise": 0.9, "microsoft": 0.95}
            ),
            StandardizedSkill(
                name="Rust",
                category=SkillCategory.PROGRAMMING_LANGUAGE,
                aliases=["rust", "rust lang"],
                description="Rust编程语言",
                level=SkillLevel.ADVANCED,
                related_skills=["Cargo", "Tokio", "Actix", "Serde"],
                industry_relevance={"tech": 0.7, "system": 0.8, "blockchain": 0.6}
            ),
            StandardizedSkill(
                name="Swift",
                category=SkillCategory.PROGRAMMING_LANGUAGE,
                aliases=["swift", "swift lang"],
                description="Swift编程语言",
                level=SkillLevel.INTERMEDIATE,
                related_skills=["iOS", "macOS", "Xcode", "UIKit"],
                industry_relevance={"tech": 0.8, "mobile": 0.9, "apple": 0.95}
            ),
            StandardizedSkill(
                name="Kotlin",
                category=SkillCategory.PROGRAMMING_LANGUAGE,
                aliases=["kotlin", "kt"],
                description="Kotlin编程语言",
                level=SkillLevel.INTERMEDIATE,
                related_skills=["Android", "Spring Boot", "Gradle", "Coroutines"],
                industry_relevance={"tech": 0.8, "mobile": 0.9, "android": 0.95}
            )
        ]
        
        # 框架技能
        frameworks = [
            StandardizedSkill(
                name="React",
                category=SkillCategory.FRAMEWORK,
                aliases=["react", "reactjs", "react.js"],
                description="React前端框架",
                level=SkillLevel.INTERMEDIATE,
                related_skills=["JavaScript", "TypeScript", "Redux", "Next.js"],
                industry_relevance={"tech": 0.9, "frontend": 0.95, "web": 0.9}
            ),
            StandardizedSkill(
                name="Vue.js",
                category=SkillCategory.FRAMEWORK,
                aliases=["vue", "vuejs", "vue.js"],
                description="Vue.js前端框架",
                level=SkillLevel.INTERMEDIATE,
                related_skills=["JavaScript", "TypeScript", "Vuex", "Nuxt.js"],
                industry_relevance={"tech": 0.8, "frontend": 0.85, "web": 0.8}
            ),
            StandardizedSkill(
                name="Angular",
                category=SkillCategory.FRAMEWORK,
                aliases=["angular", "angularjs", "angular.js"],
                description="Angular前端框架",
                level=SkillLevel.ADVANCED,
                related_skills=["TypeScript", "RxJS", "Angular CLI", "Material Design"],
                industry_relevance={"tech": 0.8, "frontend": 0.85, "enterprise": 0.9}
            ),
            StandardizedSkill(
                name="Spring Boot",
                category=SkillCategory.FRAMEWORK,
                aliases=["springboot", "spring boot", "springboot framework"],
                description="Spring Boot后端框架",
                level=SkillLevel.INTERMEDIATE,
                related_skills=["Java", "Maven", "Hibernate", "REST API"],
                industry_relevance={"tech": 0.9, "backend": 0.95, "enterprise": 0.9}
            ),
            StandardizedSkill(
                name="Django",
                category=SkillCategory.FRAMEWORK,
                aliases=["django", "django framework"],
                description="Django Python后端框架",
                level=SkillLevel.INTERMEDIATE,
                related_skills=["Python", "PostgreSQL", "Redis", "Celery"],
                industry_relevance={"tech": 0.8, "backend": 0.85, "python": 0.9}
            ),
            StandardizedSkill(
                name="Flask",
                category=SkillCategory.FRAMEWORK,
                aliases=["flask", "flask framework"],
                description="Flask Python轻量级框架",
                level=SkillLevel.INTERMEDIATE,
                related_skills=["Python", "SQLAlchemy", "Jinja2", "Werkzeug"],
                industry_relevance={"tech": 0.7, "backend": 0.8, "python": 0.85}
            ),
            StandardizedSkill(
                name="Gin",
                category=SkillCategory.FRAMEWORK,
                aliases=["gin", "gin framework", "gin golang"],
                description="Gin Go语言Web框架",
                level=SkillLevel.INTERMEDIATE,
                related_skills=["Go", "GORM", "JWT", "Middleware"],
                industry_relevance={"tech": 0.7, "backend": 0.8, "go": 0.9}
            ),
            StandardizedSkill(
                name="Express.js",
                category=SkillCategory.FRAMEWORK,
                aliases=["express", "expressjs", "express.js"],
                description="Express.js Node.js框架",
                level=SkillLevel.INTERMEDIATE,
                related_skills=["Node.js", "JavaScript", "MongoDB", "Mongoose"],
                industry_relevance={"tech": 0.8, "backend": 0.85, "nodejs": 0.9}
            )
        ]
        
        # 数据库技能
        databases = [
            StandardizedSkill(
                name="MySQL",
                category=SkillCategory.DATABASE,
                aliases=["mysql", "mysql database"],
                description="MySQL关系型数据库",
                level=SkillLevel.INTERMEDIATE,
                related_skills=["SQL", "InnoDB", "MySQL Workbench", "phpMyAdmin"],
                industry_relevance={"tech": 0.9, "database": 0.95, "web": 0.85}
            ),
            StandardizedSkill(
                name="PostgreSQL",
                category=SkillCategory.DATABASE,
                aliases=["postgresql", "postgres", "pg"],
                description="PostgreSQL关系型数据库",
                level=SkillLevel.INTERMEDIATE,
                related_skills=["SQL", "pgvector", "PostGIS", "pgAdmin"],
                industry_relevance={"tech": 0.8, "database": 0.9, "enterprise": 0.85}
            ),
            StandardizedSkill(
                name="MongoDB",
                category=SkillCategory.DATABASE,
                aliases=["mongodb", "mongo", "nosql"],
                description="MongoDB文档数据库",
                level=SkillLevel.INTERMEDIATE,
                related_skills=["NoSQL", "Mongoose", "Atlas", "Compass"],
                industry_relevance={"tech": 0.8, "database": 0.85, "nosql": 0.9}
            ),
            StandardizedSkill(
                name="Redis",
                category=SkillCategory.DATABASE,
                aliases=["redis", "redis cache"],
                description="Redis内存数据库",
                level=SkillLevel.INTERMEDIATE,
                related_skills=["Cache", "Pub/Sub", "Lua", "Cluster"],
                industry_relevance={"tech": 0.8, "database": 0.85, "cache": 0.95}
            ),
            StandardizedSkill(
                name="Elasticsearch",
                category=SkillCategory.DATABASE,
                aliases=["elasticsearch", "elastic", "es"],
                description="Elasticsearch搜索引擎",
                level=SkillLevel.ADVANCED,
                related_skills=["Logstash", "Kibana", "ELK", "Lucene"],
                industry_relevance={"tech": 0.7, "search": 0.9, "analytics": 0.8}
            ),
            StandardizedSkill(
                name="Neo4j",
                category=SkillCategory.DATABASE,
                aliases=["neo4j", "neo 4j", "graph database"],
                description="Neo4j图数据库",
                level=SkillLevel.ADVANCED,
                related_skills=["Cypher", "GraphQL", "Gremlin", "Graph Analytics"],
                industry_relevance={"tech": 0.6, "database": 0.7, "graph": 0.9}
            )
        ]
        
        # 云服务技能
        cloud_services = [
            StandardizedSkill(
                name="AWS",
                category=SkillCategory.CLOUD_SERVICE,
                aliases=["amazon web services", "amazon aws", "aws cloud"],
                description="Amazon Web Services云服务",
                level=SkillLevel.ADVANCED,
                related_skills=["EC2", "S3", "Lambda", "RDS", "CloudFormation"],
                industry_relevance={"tech": 0.9, "cloud": 0.95, "enterprise": 0.9}
            ),
            StandardizedSkill(
                name="Azure",
                category=SkillCategory.CLOUD_SERVICE,
                aliases=["microsoft azure", "azure cloud", "azure platform"],
                description="Microsoft Azure云服务",
                level=SkillLevel.ADVANCED,
                related_skills=["Azure DevOps", "Azure Functions", "Cosmos DB", "ARM Templates"],
                industry_relevance={"tech": 0.8, "cloud": 0.9, "microsoft": 0.95}
            ),
            StandardizedSkill(
                name="Google Cloud",
                category=SkillCategory.CLOUD_SERVICE,
                aliases=["gcp", "google cloud platform", "google cloud"],
                description="Google Cloud Platform云服务",
                level=SkillLevel.ADVANCED,
                related_skills=["GKE", "BigQuery", "Cloud Functions", "Firebase"],
                industry_relevance={"tech": 0.7, "cloud": 0.85, "google": 0.9}
            ),
            StandardizedSkill(
                name="Kubernetes",
                category=SkillCategory.CLOUD_SERVICE,
                aliases=["k8s", "kubernetes", "kube"],
                description="Kubernetes容器编排平台",
                level=SkillLevel.ADVANCED,
                related_skills=["Docker", "Helm", "Istio", "Prometheus"],
                industry_relevance={"tech": 0.9, "cloud": 0.95, "devops": 0.9}
            ),
            StandardizedSkill(
                name="Docker",
                category=SkillCategory.CLOUD_SERVICE,
                aliases=["docker", "docker container", "containerization"],
                description="Docker容器化技术",
                level=SkillLevel.INTERMEDIATE,
                related_skills=["Kubernetes", "Docker Compose", "Dockerfile", "Registry"],
                industry_relevance={"tech": 0.9, "cloud": 0.9, "devops": 0.95}
            )
        ]
        
        # 开发工具技能
        development_tools = [
            StandardizedSkill(
                name="Git",
                category=SkillCategory.DEVELOPMENT_TOOL,
                aliases=["git", "git version control", "git scm"],
                description="Git版本控制系统",
                level=SkillLevel.INTERMEDIATE,
                related_skills=["GitHub", "GitLab", "Bitbucket", "Git Flow"],
                industry_relevance={"tech": 0.95, "development": 0.98, "collaboration": 0.9}
            ),
            StandardizedSkill(
                name="Jenkins",
                category=SkillCategory.DEVELOPMENT_TOOL,
                aliases=["jenkins", "jenkins ci", "jenkins pipeline"],
                description="Jenkins持续集成工具",
                level=SkillLevel.ADVANCED,
                related_skills=["CI/CD", "Pipeline", "Docker", "Kubernetes"],
                industry_relevance={"tech": 0.8, "devops": 0.9, "automation": 0.85}
            ),
            StandardizedSkill(
                name="Grafana",
                category=SkillCategory.DEVELOPMENT_TOOL,
                aliases=["grafana", "grafana monitoring"],
                description="Grafana监控和可视化工具",
                level=SkillLevel.ADVANCED,
                related_skills=["Prometheus", "InfluxDB", "Dashboards", "Alerting"],
                industry_relevance={"tech": 0.7, "monitoring": 0.9, "devops": 0.8}
            ),
            StandardizedSkill(
                name="Prometheus",
                category=SkillCategory.DEVELOPMENT_TOOL,
                aliases=["prometheus", "prometheus monitoring"],
                description="Prometheus监控系统",
                level=SkillLevel.ADVANCED,
                related_skills=["Grafana", "Alertmanager", "Metrics", "Service Discovery"],
                industry_relevance={"tech": 0.7, "monitoring": 0.9, "devops": 0.8}
            )
        ]
        
        # 软技能
        soft_skills = [
            StandardizedSkill(
                name="Leadership",
                category=SkillCategory.SOFT_SKILL,
                aliases=["leadership", "team leadership", "leadership skills"],
                description="领导力和团队管理",
                level=SkillLevel.ADVANCED,
                related_skills=["Team Management", "Project Management", "Communication", "Decision Making"],
                industry_relevance={"management": 0.95, "business": 0.9, "tech": 0.7}
            ),
            StandardizedSkill(
                name="Communication",
                category=SkillCategory.SOFT_SKILL,
                aliases=["communication", "communication skills", "verbal communication"],
                description="沟通和表达能力",
                level=SkillLevel.INTERMEDIATE,
                related_skills=["Presentation", "Writing", "Public Speaking", "Interpersonal Skills"],
                industry_relevance={"business": 0.95, "management": 0.9, "tech": 0.8}
            ),
            StandardizedSkill(
                name="Problem Solving",
                category=SkillCategory.SOFT_SKILL,
                aliases=["problem solving", "analytical thinking", "critical thinking"],
                description="问题解决和分析思维",
                level=SkillLevel.INTERMEDIATE,
                related_skills=["Analytical Thinking", "Critical Thinking", "Innovation", "Creativity"],
                industry_relevance={"tech": 0.9, "business": 0.9, "management": 0.85}
            ),
            StandardizedSkill(
                name="Project Management",
                category=SkillCategory.SOFT_SKILL,
                aliases=["project management", "pm", "project coordination"],
                description="项目管理和协调",
                level=SkillLevel.ADVANCED,
                related_skills=["Agile", "Scrum", "Kanban", "Risk Management"],
                industry_relevance={"management": 0.95, "business": 0.9, "tech": 0.8}
            )
        ]
        
        # 将所有技能添加到数据库
        all_skills = (programming_languages + frameworks + databases + 
                     cloud_services + development_tools + soft_skills)
        
        for skill in all_skills:
            self.skills_database[skill.name.lower()] = skill
    
    async def _build_indexes(self):
        """建立索引"""
        for skill_name, skill in self.skills_database.items():
            # 技能名称索引
            self.skill_index[skill_name] = [skill_name]
            
            # 别名索引
            for alias in skill.aliases:
                if alias not in self.skill_index:
                    self.skill_index[alias] = []
                self.skill_index[alias].append(skill_name)
            
            # 分类索引
            if skill.category not in self.category_index:
                self.category_index[skill.category] = []
            self.category_index[skill.category].append(skill_name)
    
    async def standardize_skill(self, raw_skill: str) -> Optional[StandardizedSkill]:
        """技能标准化"""
        if not self.initialized:
            await self.initialize()
        
        raw_skill = raw_skill.strip().lower()
        
        # 精确匹配
        if raw_skill in self.skill_index:
            skill_names = self.skill_index[raw_skill]
            if skill_names:
                return self.skills_database[skill_names[0]]
        
        # 模糊匹配
        for skill_name, skill in self.skills_database.items():
            # 检查别名匹配
            for alias in skill.aliases:
                if raw_skill in alias or alias in raw_skill:
                    return skill
            
            # 检查名称相似度
            if self._calculate_similarity(raw_skill, skill_name) > 0.8:
                return skill
        
        logger.warning("未找到匹配的技能", raw_skill=raw_skill)
        return None
    
    async def calculate_skill_level(self, skill_name: str, experience: str) -> SkillLevel:
        """基于经验描述计算技能等级"""
        if not self.initialized:
            await self.initialize()
        
        # 关键词匹配算法
        experience_lower = experience.lower()
        
        # 高级关键词
        advanced_keywords = [
            "expert", "senior", "lead", "architect", "principal", "master",
            "advanced", "complex", "optimize", "design", "implement", "mentor"
        ]
        
        # 中级关键词
        intermediate_keywords = [
            "experienced", "proficient", "familiar", "comfortable", "working",
            "develop", "build", "create", "manage", "maintain"
        ]
        
        # 初级关键词
        beginner_keywords = [
            "basic", "beginner", "learning", "junior", "entry", "start",
            "simple", "understand", "know", "aware"
        ]
        
        advanced_score = sum(1 for keyword in advanced_keywords if keyword in experience_lower)
        intermediate_score = sum(1 for keyword in intermediate_keywords if keyword in experience_lower)
        beginner_score = sum(1 for keyword in beginner_keywords if keyword in experience_lower)
        
        if advanced_score > intermediate_score and advanced_score > beginner_score:
            return SkillLevel.EXPERT
        elif intermediate_score > beginner_score:
            return SkillLevel.ADVANCED
        else:
            return SkillLevel.INTERMEDIATE
    
    async def match_skill_requirements(self, user_skills: Dict[str, str], 
                                     job_requirements: Dict[str, str]) -> Dict[str, Any]:
        """技能匹配度计算"""
        if not self.initialized:
            await self.initialize()
        
        matches = []
        total_score = 0.0
        max_possible_score = 0.0
        
        for req_skill, req_description in job_requirements.items():
            max_possible_score += 1.0
            
            best_match = None
            best_score = 0.0
            
            for user_skill, user_experience in user_skills.items():
                match = await self._calculate_skill_match(req_skill, user_skill, 
                                                        req_description, user_experience)
                if match.match_score > best_score:
                    best_score = match.match_score
                    best_match = match
            
            if best_match:
                matches.append(best_match)
                total_score += best_match.match_score
        
        overall_match_score = total_score / max_possible_score if max_possible_score > 0 else 0.0
        
        return {
            "overall_score": overall_match_score,
            "matches": matches,
            "total_requirements": len(job_requirements),
            "matched_requirements": len(matches),
            "match_percentage": len(matches) / len(job_requirements) * 100 if job_requirements else 0
        }
    
    async def _calculate_skill_match(self, req_skill: str, user_skill: str, 
                                   req_description: str, user_experience: str) -> SkillMatch:
        """计算技能匹配度"""
        # 标准化技能名称
        req_standard = await self.standardize_skill(req_skill)
        user_standard = await self.standardize_skill(user_skill)
        
        if not req_standard or not user_standard:
            return SkillMatch(
                user_skill=user_skill,
                standard_skill=req_standard or StandardizedSkill("", SkillCategory.PROGRAMMING_LANGUAGE, [], "", SkillLevel.BEGINNER, [], {}),
                match_score=0.0,
                match_type="no_match"
            )
        
        # 精确匹配
        if req_standard.name == user_standard.name:
            return SkillMatch(
                user_skill=user_skill,
                standard_skill=req_standard,
                match_score=1.0,
                match_type="exact"
            )
        
        # 别名匹配
        if req_standard.name in user_standard.aliases or user_standard.name in req_standard.aliases:
            return SkillMatch(
                user_skill=user_skill,
                standard_skill=req_standard,
                match_score=0.9,
                match_type="alias"
            )
        
        # 相关技能匹配
        if req_standard.name in user_standard.related_skills or user_standard.name in req_standard.related_skills:
            return SkillMatch(
                user_skill=user_skill,
                standard_skill=req_standard,
                match_score=0.7,
                match_type="related"
            )
        
        # 分类匹配
        if req_standard.category == user_standard.category:
            return SkillMatch(
                user_skill=user_skill,
                standard_skill=req_standard,
                match_score=0.5,
                match_type="similar"
            )
        
        # 无匹配
        return SkillMatch(
            user_skill=user_skill,
            standard_skill=req_standard,
            match_score=0.0,
            match_type="no_match"
        )
    
    def _calculate_similarity(self, str1: str, str2: str) -> float:
        """计算字符串相似度"""
        # 简单的Jaccard相似度
        set1 = set(str1)
        set2 = set(str2)
        intersection = len(set1.intersection(set2))
        union = len(set1.union(set2))
        return intersection / union if union > 0 else 0.0
    
    async def get_skills_by_category(self, category: SkillCategory) -> List[StandardizedSkill]:
        """根据分类获取技能"""
        if not self.initialized:
            await self.initialize()
        
        skill_names = self.category_index.get(category, [])
        return [self.skills_database[name] for name in skill_names]
    
    async def search_skills(self, query: str, limit: int = 10) -> List[StandardizedSkill]:
        """搜索技能"""
        if not self.initialized:
            await self.initialize()
        
        query = query.lower()
        results = []
        
        for skill_name, skill in self.skills_database.items():
            # 名称匹配
            if query in skill_name:
                results.append((skill, 1.0))
                continue
            
            # 别名匹配
            for alias in skill.aliases:
                if query in alias:
                    results.append((skill, 0.8))
                    break
            
            # 描述匹配
            if query in skill.description.lower():
                results.append((skill, 0.6))
        
        # 按匹配度排序并返回前limit个结果
        results.sort(key=lambda x: x[1], reverse=True)
        return [skill for skill, score in results[:limit]]

# 创建全局实例
skill_engine = SkillStandardizationEngine()

async def main():
    """测试函数"""
    engine = SkillStandardizationEngine()
    await engine.initialize()
    
    # 测试技能标准化
    test_skills = ["python", "java", "react", "mysql", "aws", "unknown_skill"]
    for skill in test_skills:
        standardized = await engine.standardize_skill(skill)
        if standardized:
            print(f"'{skill}' -> '{standardized.name}' ({standardized.category.value})")
        else:
            print(f"'{skill}' -> 未找到匹配")
    
    # 测试技能匹配
    user_skills = {
        "python": "3 years of Python development experience",
        "react": "2 years of React frontend development",
        "mysql": "Database design and optimization experience"
    }
    
    job_requirements = {
        "python": "Python backend development",
        "javascript": "Frontend JavaScript development",
        "postgresql": "Database management"
    }
    
    match_result = await engine.match_skill_requirements(user_skills, job_requirements)
    print(f"\n匹配结果: {match_result['overall_score']:.2f}")
    print(f"匹配率: {match_result['match_percentage']:.1f}%")

if __name__ == "__main__":
    asyncio.run(main())
