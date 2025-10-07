#!/usr/bin/env python3
"""
数据验证器
实现数据验证和约束机制
确保数据一致性
"""

import re
import json
from typing import Dict, Any, List, Optional, Union
from datetime import datetime
import logging

logger = logging.getLogger(__name__)

class ValidationResult:
    """验证结果"""
    
    def __init__(self, is_valid: bool, errors: List[str] = None, warnings: List[str] = None):
        self.is_valid = is_valid
        self.errors = errors or []
        self.warnings = warnings or []
    
    def add_error(self, error: str):
        """添加错误"""
        self.errors.append(error)
        self.is_valid = False
    
    def add_warning(self, warning: str):
        """添加警告"""
        self.warnings.append(warning)
    
    def to_dict(self) -> Dict[str, Any]:
        """转换为字典"""
        return {
            "is_valid": self.is_valid,
            "errors": self.errors,
            "warnings": self.warnings,
            "error_count": len(self.errors),
            "warning_count": len(self.warnings)
        }

class DataValidator:
    """数据验证器基类"""
    
    def __init__(self, validation_rules: Dict[str, Any]):
        self.validation_rules = validation_rules
    
    async def validate(self, data: Dict[str, Any]) -> ValidationResult:
        """验证数据"""
        result = ValidationResult(is_valid=True)
        
        for field, rules in self.validation_rules.items():
            if field in data:
                field_result = await self._validate_field(field, data[field], rules)
                if not field_result.is_valid:
                    result.errors.extend(field_result.errors)
                    result.is_valid = False
                result.warnings.extend(field_result.warnings)
            elif rules.get('required', False):
                result.add_error(f"字段 {field} 是必需的")
        
        return result
    
    async def _validate_field(self, field: str, value: Any, rules: Dict[str, Any]) -> ValidationResult:
        """验证字段"""
        result = ValidationResult(is_valid=True)
        
        # 类型验证
        if 'type' in rules:
            if not self._validate_type(value, rules['type']):
                result.add_error(f"字段 {field} 类型错误，期望 {rules['type']}")
        
        # 格式验证
        if 'format' in rules:
            if not self._validate_format(value, rules['format']):
                result.add_error(f"字段 {field} 格式错误")
        
        # 范围验证
        if 'range' in rules:
            if not self._validate_range(value, rules['range']):
                result.add_error(f"字段 {field} 超出范围 {rules['range']}")
        
        # 枚举验证
        if 'enum' in rules:
            if value not in rules['enum']:
                result.add_error(f"字段 {field} 值不在允许的枚举中")
        
        # 长度验证
        if 'max_length' in rules:
            if isinstance(value, str) and len(value) > rules['max_length']:
                result.add_error(f"字段 {field} 长度超过限制 {rules['max_length']}")
        
        if 'min_length' in rules:
            if isinstance(value, str) and len(value) < rules['min_length']:
                result.add_error(f"字段 {field} 长度不足 {rules['min_length']}")
        
        # 正则表达式验证
        if 'pattern' in rules:
            if not re.match(rules['pattern'], str(value)):
                result.add_error(f"字段 {field} 不符合正则表达式模式")
        
        # 自定义验证
        if 'custom_validator' in rules:
            custom_result = await rules['custom_validator'](value)
            if not custom_result:
                result.add_error(f"字段 {field} 自定义验证失败")
        
        return result
    
    def _validate_type(self, value: Any, expected_type: str) -> bool:
        """验证类型"""
        type_mapping = {
            'string': str,
            'integer': int,
            'float': float,
            'boolean': bool,
            'datetime': (str, datetime),
            'array': list,
            'object': dict,
            'text': str
        }
        
        if expected_type in type_mapping:
            return isinstance(value, type_mapping[expected_type])
        
        return True
    
    def _validate_format(self, value: Any, format_type: str) -> bool:
        """验证格式"""
        if not value:  # 空值跳过格式验证
            return True
            
        if format_type == 'email':
            return re.match(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$', str(value)) is not None
        elif format_type == 'phone':
            return re.match(r'^\+?1?\d{9,15}$', str(value)) is not None
        elif format_type == 'url':
            return re.match(r'^https?://[^\s/$.?#].[^\s]*$', str(value)) is not None
        elif format_type == 'uuid':
            return re.match(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', str(value)) is not None
        
        return True
    
    def _validate_range(self, value: Any, range_str: str) -> bool:
        """验证范围"""
        # 添加None值检查
        if value is None:
            return True  # 允许None值通过验证
        
        try:
            if ' <= ' in range_str:
                parts = range_str.split(' <= ')
                min_val = float(parts[0])
                max_val = float(parts[1])
                return min_val <= float(value) <= max_val
            elif '-' in range_str:
                parts = range_str.split('-')
                min_val = float(parts[0])
                max_val = float(parts[1])
                return min_val <= float(value) <= max_val
        except (ValueError, IndexError):
            pass
        
        return True

class LoomaDataValidator(DataValidator):
    """Looma CRM数据验证器"""
    
    def __init__(self):
        validation_rules = {
            "id": {
                "type": "string", 
                "required": True,
                "pattern": r'^[a-zA-Z_][a-zA-Z0-9_]*$',
                "max_length": 100
            },
            "name": {
                "type": "string", 
                "required": True,
                "max_length": 100,
                "min_length": 1
            },
            "email": {
                "type": "string", 
                "format": "email", 
                "required": True,
                "max_length": 255
            },
            "phone": {
                "type": "string", 
                "format": "phone",
                "max_length": 20
            },
            "skills": {
                "type": "array",
                "custom_validator": self._validate_skills_array
            },
            "experience": {
                "type": "integer", 
                "range": "0-50"
            },
            "education": {
                "type": "object",
                "custom_validator": self._validate_education_object
            },
            "projects": {
                "type": "array",
                "custom_validator": self._validate_projects_array
            },
            "relationships": {
                "type": "array",
                "custom_validator": self._validate_relationships_array
            },
            "status": {
                "type": "string", 
                "enum": ["active", "inactive", "archived"]
            },
            "created_at": {
                "type": "datetime",
                "format": "iso_datetime"
            },
            "updated_at": {
                "type": "datetime",
                "format": "iso_datetime"
            },
            "zervigo_user_id": {
                "type": "integer",
                "required": True,
                "range": "1-999999999"
            }
        }
        super().__init__(validation_rules)
    
    async def _validate_skills_array(self, value: Any) -> bool:
        """验证技能数组"""
        if not isinstance(value, list):
            return False
        
        for skill in value:
            if not isinstance(skill, str) or len(skill.strip()) == 0:
                return False
        
        return True
    
    async def _validate_education_object(self, value: Any) -> bool:
        """验证教育背景对象"""
        if not isinstance(value, dict):
            return False
        
        # 检查必需字段
        required_fields = ['degree', 'school']
        for field in required_fields:
            if field not in value or not isinstance(value[field], str):
                return False
        
        # 检查毕业年份
        if 'graduation_year' in value:
            year = value['graduation_year']
            if not isinstance(year, int) or year < 1900 or year > datetime.now().year + 10:
                return False
        
        return True
    
    async def _validate_projects_array(self, value: Any) -> bool:
        """验证项目数组"""
        if not isinstance(value, list):
            return False
        
        for project in value:
            if not isinstance(project, dict):
                return False
            
            # 检查必需字段
            if 'name' not in project or not isinstance(project['name'], str):
                return False
        
        return True
    
    async def _validate_relationships_array(self, value: Any) -> bool:
        """验证关系数组"""
        if not isinstance(value, list):
            return False
        
        for relationship in value:
            if not isinstance(relationship, dict):
                return False
            
            # 检查必需字段
            required_fields = ['target_talent_id', 'relationship_type']
            for field in required_fields:
                if field not in relationship:
                    return False
        
        return True

class ZervigoDataValidator(DataValidator):
    """Zervigo数据验证器"""
    
    def __init__(self):
        validation_rules = {
            "id": {
                "type": "integer",
                "required": True,
                "range": "1-999999999"
            },
            "username": {
                "type": "string",
                "required": True,
                "max_length": 50,
                "min_length": 3,
                "pattern": r'^[a-zA-Z0-9_]+$'
            },
            "email": {
                "type": "string",
                "format": "email",
                "required": True,
                "max_length": 255
            },
            "role": {
                "type": "string",
                "enum": ["admin", "user", "manager", "hr"]
            },
            "status": {
                "type": "string",
                "enum": ["active", "inactive", "pending", "suspended"]
            },
            "created_at": {
                "type": "datetime",
                "format": "iso_datetime"
            },
            "updated_at": {
                "type": "datetime",
                "format": "iso_datetime"
            }
        }
        super().__init__(validation_rules)

class DataConsistencyValidator:
    """数据一致性验证器"""
    
    def __init__(self):
        self.looma_validator = LoomaDataValidator()
        self.zervigo_validator = ZervigoDataValidator()
    
    async def validate_cross_service_consistency(self, looma_data: Dict[str, Any], zervigo_data: Dict[str, Any]) -> ValidationResult:
        """验证跨服务数据一致性"""
        result = ValidationResult(is_valid=True)
        
        # 验证用户ID一致性
        looma_user_id = looma_data.get('zervigo_user_id')
        zervigo_user_id = zervigo_data.get('id')
        
        if looma_user_id != zervigo_user_id:
            result.add_error(f"用户ID不一致: Looma CRM {looma_user_id} vs Zervigo {zervigo_user_id}")
        
        # 验证邮箱一致性
        looma_email = looma_data.get('email')
        zervigo_email = zervigo_data.get('email')
        
        if looma_email != zervigo_email:
            result.add_error(f"邮箱不一致: Looma CRM {looma_email} vs Zervigo {zervigo_email}")
        
        # 验证状态一致性
        looma_status = looma_data.get('status')
        zervigo_status = zervigo_data.get('status')
        
        status_mapping = {
            'active': 'active',
            'inactive': 'inactive',
            'archived': 'inactive'
        }
        
        expected_zervigo_status = status_mapping.get(looma_status)
        if expected_zervigo_status and zervigo_status != expected_zervigo_status:
            result.add_warning(f"状态映射不一致: Looma CRM {looma_status} 期望 Zervigo {expected_zervigo_status}, 实际 {zervigo_status}")
        
        # 验证时间戳一致性
        looma_updated = looma_data.get('updated_at')
        zervigo_updated = zervigo_data.get('updated_at')
        
        if looma_updated and zervigo_updated:
            try:
                looma_time = datetime.fromisoformat(looma_updated.replace('Z', '+00:00'))
                zervigo_time = datetime.fromisoformat(zervigo_updated.replace('Z', '+00:00'))
                
                # 允许5分钟的时间差
                time_diff = abs((looma_time - zervigo_time).total_seconds())
                if time_diff > 300:  # 5分钟
                    result.add_warning(f"更新时间差异较大: {time_diff}秒")
            except:
                result.add_warning("时间戳格式解析失败")
        
        return result
    
    async def validate_data_integrity(self, data: Dict[str, Any], model_type: str) -> ValidationResult:
        """验证数据完整性"""
        if model_type == "looma_talent":
            return await self.looma_validator.validate(data)
        elif model_type == "zervigo_user":
            return await self.zervigo_validator.validate(data)
        else:
            result = ValidationResult(is_valid=False)
            result.add_error(f"未知的模型类型: {model_type}")
            return result
    
    async def validate_business_rules(self, data: Dict[str, Any]) -> ValidationResult:
        """验证业务规则"""
        result = ValidationResult(is_valid=True)
        
        # 业务规则1: 活跃用户必须有邮箱
        if data.get('status') == 'active' and not data.get('email'):
            result.add_error("活跃用户必须提供邮箱地址")
        
        # 业务规则2: 经验年数不能超过年龄
        experience = data.get('experience', 0)
        if experience > 50:
            result.add_warning("工作经验年数超过50年，请确认数据准确性")
        
        # 业务规则3: 技能数量限制
        skills = data.get('skills', [])
        if len(skills) > 50:
            result.add_warning("技能数量超过50个，建议精简")
        
        return result

class ValidationService:
    """验证服务"""
    
    def __init__(self):
        self.consistency_validator = DataConsistencyValidator()
        self.validation_cache = {}
    
    async def validate_data(self, data: Dict[str, Any], model_type: str, validate_consistency: bool = True) -> ValidationResult:
        """验证数据"""
        # 检查缓存
        cache_key = self._generate_cache_key(data, model_type)
        if cache_key in self.validation_cache:
            logger.info(f"使用缓存验证结果: {cache_key}")
            return self.validation_cache[cache_key]
        
        # 执行验证
        result = await self.consistency_validator.validate_data_integrity(data, model_type)
        
        # 验证业务规则
        business_result = await self.consistency_validator.validate_business_rules(data)
        result.errors.extend(business_result.errors)
        result.warnings.extend(business_result.warnings)
        if not business_result.is_valid:
            result.is_valid = False
        
        # 缓存结果
        self.validation_cache[cache_key] = result
        
        return result
    
    async def validate_consistency(self, looma_data: Dict[str, Any], zervigo_data: Dict[str, Any]) -> ValidationResult:
        """验证数据一致性"""
        return await self.consistency_validator.validate_cross_service_consistency(looma_data, zervigo_data)
    
    def _generate_cache_key(self, data: Dict[str, Any], model_type: str) -> str:
        """生成缓存键"""
        import hashlib
        data_str = json.dumps(data, sort_keys=True)
        return hashlib.md5(f"{model_type}_{data_str}".encode()).hexdigest()
    
    async def clear_cache(self):
        """清空验证缓存"""
        self.validation_cache.clear()
        logger.info("验证缓存已清空")
