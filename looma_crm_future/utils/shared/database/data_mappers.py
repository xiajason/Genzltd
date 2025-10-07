#!/usr/bin/env python3
"""
数据映射器
实现Zervigo到Looma CRM的数据映射
解决数据一致性问题
"""

from typing import Dict, Any, Optional, List
from datetime import datetime
import json
import logging
import re

logger = logging.getLogger(__name__)

class DataMapper:
    """数据映射器基类"""
    
    def __init__(self, source_model: str, target_model: str):
        self.source_model = source_model
        self.target_model = target_model
    
    async def map_to_target(self, source_data: Dict[str, Any]) -> Dict[str, Any]:
        """将源数据映射到目标模型"""
        raise NotImplementedError
    
    async def map_to_source(self, target_data: Dict[str, Any]) -> Dict[str, Any]:
        """将目标数据映射到源模型"""
        raise NotImplementedError

class ZervigoToLoomaMapper(DataMapper):
    """Zervigo到Looma CRM数据映射器"""
    
    def __init__(self):
        super().__init__("zervigo", "looma_crm")
    
    async def map_user_to_talent(self, zervigo_user: Dict[str, Any]) -> Dict[str, Any]:
        """将Zervigo用户映射到Looma CRM人才"""
        try:
            # 数据一致性验证
            if not self._validate_zervigo_user_data(zervigo_user):
                logger.error("Zervigo用户数据验证失败")
                return {}
            
            looma_talent = {
                "id": f"talent_{zervigo_user.get('id')}",
                "name": zervigo_user.get('username', ''),
                "email": zervigo_user.get('email', ''),
                "phone": "",  # Zervigo用户数据中没有电话，需要从其他服务获取
                "skills": [],  # 需要从简历服务获取
                "experience": 0,  # 需要从简历服务获取
                "education": {},  # 需要从简历服务获取
                "projects": [],  # 需要从项目服务获取
                "relationships": [],  # 需要从图数据库获取
                "status": self._map_status(zervigo_user.get('status', 'inactive')),
                "created_at": self._normalize_datetime(zervigo_user.get('created_at')),
                "updated_at": self._normalize_datetime(zervigo_user.get('updated_at')),
                "zervigo_user_id": zervigo_user.get('id')
            }
            
            logger.info(f"用户映射成功: {zervigo_user.get('username')} -> {looma_talent['id']}")
            return looma_talent
            
        except Exception as e:
            logger.error(f"用户映射失败: {e}")
            return {}
    
    async def map_talent_to_user(self, looma_talent: Dict[str, Any]) -> Dict[str, Any]:
        """将Looma CRM人才映射到Zervigo用户"""
        try:
            # 数据一致性验证
            if not self._validate_looma_talent_data(looma_talent):
                logger.error("Looma CRM人才数据验证失败")
                return {}
            
            zervigo_user = {
                "id": looma_talent.get('zervigo_user_id'),
                "username": looma_talent.get('name', ''),
                "email": looma_talent.get('email', ''),
                "phone": looma_talent.get('phone', ''),
                "role": looma_talent.get('role', 'user'),  # 使用实际角色
                "status": self._map_status_to_zervigo(looma_talent.get('status', 'inactive')),
                "first_name": looma_talent.get('first_name', ''),
                "last_name": looma_talent.get('last_name', ''),
                "email_verified": looma_talent.get('email_verified', False),
                "phone_verified": looma_talent.get('phone_verified', False),
                "created_at": self._normalize_datetime(looma_talent.get('created_at')),
                "updated_at": self._normalize_datetime(looma_talent.get('updated_at'))
            }
            
            logger.info(f"人才映射成功: {looma_talent.get('name')} -> {zervigo_user['username']}")
            return zervigo_user
            
        except Exception as e:
            logger.error(f"人才映射失败: {e}")
            return {}
    
    async def map_job_to_project(self, zervigo_job: Dict[str, Any]) -> Dict[str, Any]:
        """将Zervigo职位映射到Looma CRM项目"""
        try:
            # 数据一致性验证
            if not self._validate_zervigo_job_data(zervigo_job):
                logger.error("Zervigo职位数据验证失败")
                return {}
            
            looma_project = {
                "id": f"project_{zervigo_job.get('id')}",
                "name": zervigo_job.get('title', ''),
                "description": zervigo_job.get('description', ''),
                "requirements": self._extract_requirements(zervigo_job.get('requirements', {})),
                "skills_needed": self._extract_skills(zervigo_job.get('requirements', {})),
                "team_size": 1,  # 默认值，需要从其他信息推断
                "duration": 6,  # 默认值，需要从其他信息推断
                "budget": None,  # Zervigo职位数据中没有预算信息
                "status": self._map_job_status(zervigo_job.get('status', 'inactive')),
                "created_at": self._normalize_datetime(zervigo_job.get('created_at')),
                "updated_at": self._normalize_datetime(zervigo_job.get('created_at')),
                "zervigo_job_id": zervigo_job.get('id')
            }
            
            logger.info(f"职位映射成功: {zervigo_job.get('title')} -> {looma_project['id']}")
            return looma_project
            
        except Exception as e:
            logger.error(f"职位映射失败: {e}")
            return {}
    
    async def map_resume_to_talent_skills(self, zervigo_resume: Dict[str, Any]) -> Dict[str, Any]:
        """将Zervigo简历数据映射到Looma CRM人才技能"""
        try:
            # 数据一致性验证
            if not self._validate_zervigo_resume_data(zervigo_resume):
                logger.error("Zervigo简历数据验证失败")
                return {}
            
            parsed_data = zervigo_resume.get('parsed_data', {})
            
            talent_skills = {
                "skills": self._extract_skills_from_resume(parsed_data),
                "experience": self._calculate_experience(parsed_data),
                "education": self._extract_education(parsed_data),
                "projects": self._extract_projects(parsed_data)
            }
            
            logger.info(f"简历技能映射成功: 用户 {zervigo_resume.get('user_id')}")
            return talent_skills
            
        except Exception as e:
            logger.error(f"简历技能映射失败: {e}")
            return {}
    
    def _validate_zervigo_user_data(self, user_data: Dict[str, Any]) -> bool:
        """验证Zervigo用户数据"""
        required_fields = ['id', 'username', 'email']
        return all(field in user_data for field in required_fields)
    
    def _validate_looma_talent_data(self, talent_data: Dict[str, Any]) -> bool:
        """验证Looma CRM人才数据"""
        if not talent_data:
            return False
        
        # 基本必需字段
        required_fields = ['id', 'name', 'email']
        if not all(field in talent_data for field in required_fields):
            return False
        
        # zervigo_user_id 是可选的，如果没有则使用默认值
        return True
    
    def _validate_zervigo_job_data(self, job_data: Dict[str, Any]) -> bool:
        """验证Zervigo职位数据"""
        required_fields = ['id', 'title']
        return all(field in job_data for field in required_fields)
    
    def _validate_zervigo_resume_data(self, resume_data: Dict[str, Any]) -> bool:
        """验证Zervigo简历数据"""
        required_fields = ['id', 'user_id', 'parsed_data']
        return all(field in resume_data for field in required_fields)
    
    def _map_status(self, zervigo_status: str) -> str:
        """映射状态字段"""
        status_mapping = {
            'active': 'active',
            'inactive': 'inactive',
            'pending': 'active',
            'suspended': 'inactive'
        }
        return status_mapping.get(zervigo_status, 'inactive')
    
    def _map_status_to_zervigo(self, looma_status: str) -> str:
        """映射状态字段到Zervigo"""
        status_mapping = {
            'active': 'active',
            'inactive': 'inactive',
            'archived': 'inactive'
        }
        return status_mapping.get(looma_status, 'inactive')
    
    def _map_job_status(self, zervigo_status: str) -> str:
        """映射职位状态"""
        status_mapping = {
            'active': 'active',
            'inactive': 'cancelled',
            'pending': 'planning',
            'completed': 'completed'
        }
        return status_mapping.get(zervigo_status, 'planning')
    
    def _normalize_datetime(self, datetime_str: str) -> str:
        """标准化日期时间格式"""
        if not datetime_str:
            return datetime.now().isoformat()
        
        try:
            # 尝试解析ISO格式
            if 'T' in datetime_str:
                dt = datetime.fromisoformat(datetime_str.replace('Z', '+00:00'))
                return dt.isoformat()
            else:
                # 其他格式的处理
                return datetime.now().isoformat()
        except:
            return datetime.now().isoformat()
    
    def _extract_requirements(self, requirements: Dict[str, Any]) -> List[str]:
        """从职位需求中提取需求列表"""
        if isinstance(requirements, dict):
            return list(requirements.keys())
        elif isinstance(requirements, list):
            return requirements
        else:
            return []
    
    def _extract_skills(self, requirements: Dict[str, Any]) -> List[str]:
        """从职位需求中提取技能列表"""
        skills = []
        if isinstance(requirements, dict):
            for key, value in requirements.items():
                if 'skill' in key.lower() or 'technology' in key.lower():
                    if isinstance(value, list):
                        skills.extend(value)
                    else:
                        skills.append(str(value))
        return list(set(skills))  # 去重
    
    def _extract_skills_from_resume(self, parsed_data: Dict[str, Any]) -> List[str]:
        """从简历解析数据中提取技能"""
        skills = []
        
        # 从技能字段提取
        if 'skills' in parsed_data:
            skills_data = parsed_data['skills']
            if isinstance(skills_data, list):
                skills.extend(skills_data)
            elif isinstance(skills_data, dict):
                skills.extend(skills_data.keys())
        
        # 从工作经验中提取技能
        if 'experience' in parsed_data:
            exp_data = parsed_data['experience']
            if isinstance(exp_data, list):
                for exp in exp_data:
                    if isinstance(exp, dict) and 'skills' in exp:
                        if isinstance(exp['skills'], list):
                            skills.extend(exp['skills'])
        
        return list(set(skills))  # 去重
    
    def _calculate_experience(self, parsed_data: Dict[str, Any]) -> int:
        """计算工作经验年数"""
        if 'experience' not in parsed_data:
            return 0
        
        exp_data = parsed_data['experience']
        if not isinstance(exp_data, list):
            return 0
        
        total_years = 0
        for exp in exp_data:
            if isinstance(exp, dict) and 'duration' in exp:
                duration = exp['duration']
                if isinstance(duration, str) and 'year' in duration.lower():
                    # 提取年数
                    years = re.findall(r'\d+', duration)
                    if years:
                        total_years += int(years[0])
        
        return min(total_years, 50)  # 限制最大50年
    
    def _extract_education(self, parsed_data: Dict[str, Any]) -> Dict[str, Any]:
        """从简历解析数据中提取教育背景"""
        education = {}
        
        if 'education' in parsed_data:
            edu_data = parsed_data['education']
            if isinstance(edu_data, list) and edu_data:
                # 取最高学历
                highest_edu = edu_data[0]
                if isinstance(highest_edu, dict):
                    education = {
                        'degree': highest_edu.get('degree', ''),
                        'school': highest_edu.get('school', ''),
                        'major': highest_edu.get('major', ''),
                        'graduation_year': highest_edu.get('year', None)
                    }
        
        return education
    
    def _extract_projects(self, parsed_data: Dict[str, Any]) -> List[Dict[str, Any]]:
        """从简历解析数据中提取项目经历"""
        projects = []
        
        if 'projects' in parsed_data:
            projects_data = parsed_data['projects']
            if isinstance(projects_data, list):
                for project in projects_data:
                    if isinstance(project, dict):
                        projects.append({
                            'name': project.get('name', ''),
                            'description': project.get('description', ''),
                            'technologies': project.get('technologies', []),
                            'duration': project.get('duration', ''),
                            'role': project.get('role', '')
                        })
        
        return projects
    
    async def map_project_to_job(self, looma_project: Dict[str, Any]) -> Dict[str, Any]:
        """将Looma CRM项目映射到Zervigo职位"""
        try:
            # 数据一致性验证
            if not self._validate_looma_project_data(looma_project):
                logger.error("Looma CRM项目数据验证失败")
                return {}
            
            zervigo_job = {
                "id": looma_project.get('zervigo_job_id'),
                "title": looma_project.get('name', ''),
                "description": looma_project.get('description', ''),
                "requirements": looma_project.get('requirements', []),
                "skills_needed": looma_project.get('skills_needed', []),
                "team_size": looma_project.get('team_size', 1),
                "duration": looma_project.get('duration', 1),
                "budget": looma_project.get('budget', 0),
                "status": self._map_status_to_zervigo(looma_project.get('status', 'inactive')),
                "created_at": self._normalize_datetime(looma_project.get('created_at')),
                "updated_at": self._normalize_datetime(looma_project.get('updated_at'))
            }
            
            logger.info(f"项目映射成功: {looma_project.get('name')} -> {zervigo_job['title']}")
            return zervigo_job
            
        except Exception as e:
            logger.error(f"项目映射失败: {e}")
            return {}
    
    def _validate_looma_project_data(self, project_data: Dict[str, Any]) -> bool:
        """验证Looma CRM项目数据"""
        if not project_data:
            return False
        
        required_fields = ['id', 'name']
        return all(field in project_data for field in required_fields)
    
    async def map_auth_fields(self, source_data: Dict[str, Any]) -> Dict[str, Any]:
        """映射认证相关字段"""
        auth_fields = {
            'first_name': 'first_name',
            'last_name': 'last_name',
            'email_verified': 'email_verified',
            'phone_verified': 'phone_verified',
            'role': 'role'
        }
        
        result = {}
        for source_field, target_field in auth_fields.items():
            if source_field in source_data and source_data[source_field] is not None:
                result[target_field] = source_data[source_field]
        
        return result

class DataMappingService:
    """数据映射服务"""
    
    def __init__(self):
        self.mappers = {
            "zervigo_to_looma": ZervigoToLoomaMapper(),
            "zervigo_to_looma_crm": ZervigoToLoomaMapper(),  # 添加兼容性键名
            "looma_crm_to_zervigo": ZervigoToLoomaMapper()   # 添加反向映射键名
        }
        self.mapping_cache = {}
    
    async def map_data(self, source: str, target: str, data: Dict[str, Any]) -> Dict[str, Any]:
        """映射数据"""
        mapper_key = f"{source}_to_{target}"
        
        # 尝试自动注册映射器
        if mapper_key not in self.mappers:
            await self._auto_register_mapper(source, target)
        
        if mapper_key not in self.mappers:
            logger.error(f"未找到映射器: {mapper_key}")
            logger.info(f"可用映射器: {list(self.mappers.keys())}")
            return {}
        
        mapper = self.mappers[mapper_key]
        
        # 检查缓存
        cache_key = self._generate_cache_key(source, target, data)
        if cache_key in self.mapping_cache:
            logger.info(f"使用缓存映射结果: {cache_key}")
            return self.mapping_cache[cache_key]
        
        # 执行映射
        result = {}
        try:
            if source == "zervigo" and target == "looma_crm":
                if "user" in data:
                    result = await mapper.map_user_to_talent(data["user"])
                elif "job" in data:
                    result = await mapper.map_job_to_project(data["job"])
                elif "resume" in data:
                    result = await mapper.map_resume_to_talent_skills(data["resume"])
                else:
                    # 直接映射用户数据
                    result = await mapper.map_user_to_talent(data)
            elif source == "looma_crm" and target == "zervigo":
                # 处理从Looma CRM到Zervigo的映射
                if "id" in data and data["id"].startswith("talent_"):
                    result = await mapper.map_talent_to_user(data)
                elif "id" in data and data["id"].startswith("project_"):
                    result = await mapper.map_project_to_job(data)
                else:
                    # 默认映射逻辑
                    result = await self._default_looma_to_zervigo_mapping(data)
            else:
                # 通用映射逻辑
                result = await self._generic_mapping(data, source, target)
        except Exception as e:
            logger.error(f"映射执行失败: {e}")
            result = {}
        
        # 缓存结果
        if result:
            self.mapping_cache[cache_key] = result
        
        return result
    
    async def _auto_register_mapper(self, source: str, target: str):
        """自动注册映射器"""
        mapper_key = f"{source}_to_{target}"
        
        # 根据源和目标类型自动创建映射器
        if source == "zervigo" and target in ["looma_crm", "looma"]:
            self.mappers[mapper_key] = ZervigoToLoomaMapper()
            logger.info(f"自动注册映射器: {mapper_key}")
        elif source in ["looma_crm", "looma"] and target == "zervigo":
            self.mappers[mapper_key] = ZervigoToLoomaMapper()
            logger.info(f"自动注册反向映射器: {mapper_key}")
        else:
            logger.warning(f"无法自动注册映射器: {mapper_key}")
    
    async def reverse_map_data(self, source: str, target: str, data: Dict[str, Any]) -> Dict[str, Any]:
        """反向映射数据"""
        mapper_key = f"{target}_to_{source}"
        
        # 尝试自动注册映射器
        if mapper_key not in self.mappers:
            await self._auto_register_mapper(target, source)
        
        if mapper_key not in self.mappers:
            logger.error(f"未找到反向映射器: {mapper_key}")
            logger.info(f"可用映射器: {list(self.mappers.keys())}")
            return {}
        
        mapper = self.mappers[mapper_key]
        
        # 执行反向映射
        result = {}
        if source == "looma_crm" and target == "zervigo":
            if "talent" in data:
                result = await mapper.map_talent_to_user(data["talent"])
        
        return result
    
    def _generate_cache_key(self, source: str, target: str, data: Dict[str, Any]) -> str:
        """生成缓存键"""
        import hashlib
        data_str = json.dumps(data, sort_keys=True)
        return hashlib.md5(f"{source}_{target}_{data_str}".encode()).hexdigest()
    
    async def clear_cache(self):
        """清空映射缓存"""
        self.mapping_cache.clear()
        logger.info("映射缓存已清空")
    
    async def get_cache_stats(self) -> Dict[str, Any]:
        """获取缓存统计信息"""
        return {
            "cache_size": len(self.mapping_cache),
            "cache_keys": list(self.mapping_cache.keys())
        }
    
    async def _default_looma_to_zervigo_mapping(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """默认的Looma CRM到Zervigo映射逻辑"""
        if not data:
            return {}
        
        # 基础字段映射
        result = {}
        
        # 字段映射规则
        field_mappings = {
            'id': 'id',
            'name': 'username',
            'email': 'email',
            'phone': 'phone',
            'status': 'status',
            'first_name': 'first_name',
            'last_name': 'last_name',
            'email_verified': 'email_verified',
            'phone_verified': 'phone_verified',
            'role': 'role'
        }
        
        for source_field, target_field in field_mappings.items():
            if source_field in data and data[source_field] is not None:
                result[target_field] = data[source_field]
        
        # 特殊处理ID字段
        if 'id' in data and data['id'].startswith('talent_'):
            result['id'] = data['id'].replace('talent_', '')
        
        return result
    
    async def _generic_mapping(self, data: Dict[str, Any], source: str, target: str) -> Dict[str, Any]:
        """通用映射逻辑"""
        if not data:
            return {}
        
        # 简单的字段复制映射
        result = {}
        for key, value in data.items():
            if value is not None:
                result[key] = value
        
        return result
