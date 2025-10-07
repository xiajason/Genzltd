#!/usr/bin/env python3
"""
Looma CRM数据模型设计器
设计Looma CRM专用数据模型
"""

import json
import sys
import os
from typing import Dict, Any, List
from datetime import datetime

# 添加项目根目录到Python路径
sys.path.append(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

class LoomaModelDesigner:
    """Looma CRM数据模型设计器"""
    
    def __init__(self):
        self.models = {}
        self.namespaces = {}
        self.relationships = {}
    
    def design_talent_model(self):
        """设计人才数据模型"""
        talent_model = {
            "namespace": "looma_crm",
            "model": "talent",
            "description": "人才核心数据模型，集成Zervigo用户数据",
            "fields": {
                "id": {
                    "type": "string", 
                    "primary_key": True,
                    "description": "人才唯一标识符",
                    "format": "talent_{zervigo_user_id}"
                },
                "name": {
                    "type": "string", 
                    "required": True,
                    "description": "人才姓名",
                    "max_length": 100
                },
                "email": {
                    "type": "string", 
                    "unique": True,
                    "required": True,
                    "description": "邮箱地址",
                    "format": "email"
                },
                "phone": {
                    "type": "string",
                    "description": "电话号码",
                    "format": "phone",
                    "nullable": True
                },
                "skills": {
                    "type": "array", 
                    "items": "string",
                    "description": "技能列表",
                    "default": []
                },
                "experience": {
                    "type": "integer", 
                    "description": "工作经验年数",
                    "range": "0-50",
                    "default": 0
                },
                "education": {
                    "type": "object",
                    "description": "教育背景信息",
                    "properties": {
                        "degree": {"type": "string"},
                        "school": {"type": "string"},
                        "major": {"type": "string"},
                        "graduation_year": {"type": "integer"}
                    },
                    "nullable": True
                },
                "projects": {
                    "type": "array", 
                    "items": "object",
                    "description": "项目经历",
                    "default": []
                },
                "relationships": {
                    "type": "array", 
                    "items": "object",
                    "description": "人际关系网络",
                    "default": []
                },
                "status": {
                    "type": "string", 
                    "enum": ["active", "inactive", "archived"],
                    "description": "人才状态",
                    "default": "active"
                },
                "created_at": {
                    "type": "datetime",
                    "description": "创建时间",
                    "auto_generate": True
                },
                "updated_at": {
                    "type": "datetime",
                    "description": "更新时间",
                    "auto_update": True
                },
                "zervigo_user_id": {
                    "type": "integer", 
                    "foreign_key": "zervigo.users.id",
                    "description": "关联的Zervigo用户ID",
                    "required": True
                }
            },
            "indexes": [
                {"fields": ["name"], "type": "btree", "description": "姓名索引"},
                {"fields": ["email"], "type": "unique", "description": "邮箱唯一索引"},
                {"fields": ["skills"], "type": "gin", "description": "技能GIN索引"},
                {"fields": ["status"], "type": "btree", "description": "状态索引"},
                {"fields": ["zervigo_user_id"], "type": "btree", "description": "Zervigo用户ID索引"}
            ],
            "constraints": {
                "email_format": "email",
                "phone_format": "phone",
                "experience_range": "0 <= experience <= 50",
                "name_length": "length(name) <= 100"
            },
            "validation_rules": {
                "email": "必须为有效的邮箱格式",
                "phone": "必须为有效的电话号码格式",
                "experience": "工作经验年数必须在0-50之间"
            }
        }
        self.models["talent"] = talent_model
        return talent_model
    
    def design_project_model(self):
        """设计项目数据模型"""
        project_model = {
            "namespace": "looma_crm",
            "model": "project",
            "description": "项目数据模型，集成Zervigo职位数据",
            "fields": {
                "id": {
                    "type": "string", 
                    "primary_key": True,
                    "description": "项目唯一标识符",
                    "format": "project_{zervigo_job_id}"
                },
                "name": {
                    "type": "string", 
                    "required": True,
                    "description": "项目名称",
                    "max_length": 200
                },
                "description": {
                    "type": "text",
                    "description": "项目描述",
                    "nullable": True
                },
                "requirements": {
                    "type": "array", 
                    "items": "string",
                    "description": "项目需求列表",
                    "default": []
                },
                "skills_needed": {
                    "type": "array", 
                    "items": "string",
                    "description": "所需技能列表",
                    "default": []
                },
                "team_size": {
                    "type": "integer",
                    "description": "团队规模",
                    "range": "1-100",
                    "default": 1
                },
                "duration": {
                    "type": "integer", 
                    "description": "项目周期(月)",
                    "range": "1-60",
                    "default": 1
                },
                "budget": {
                    "type": "decimal",
                    "description": "项目预算",
                    "precision": 10,
                    "scale": 2,
                    "nullable": True
                },
                "status": {
                    "type": "string", 
                    "enum": ["planning", "active", "completed", "cancelled"],
                    "description": "项目状态",
                    "default": "planning"
                },
                "created_at": {
                    "type": "datetime",
                    "description": "创建时间",
                    "auto_generate": True
                },
                "updated_at": {
                    "type": "datetime",
                    "description": "更新时间",
                    "auto_update": True
                },
                "zervigo_job_id": {
                    "type": "integer", 
                    "foreign_key": "zervigo.jobs.id",
                    "description": "关联的Zervigo职位ID",
                    "nullable": True
                }
            },
            "indexes": [
                {"fields": ["name"], "type": "btree", "description": "项目名称索引"},
                {"fields": ["status"], "type": "btree", "description": "项目状态索引"},
                {"fields": ["skills_needed"], "type": "gin", "description": "所需技能GIN索引"},
                {"fields": ["zervigo_job_id"], "type": "btree", "description": "Zervigo职位ID索引"}
            ],
            "constraints": {
                "team_size_range": "1 <= team_size <= 100",
                "duration_range": "1 <= duration <= 60",
                "name_length": "length(name) <= 200"
            }
        }
        self.models["project"] = project_model
        return project_model
    
    def design_relationship_model(self):
        """设计关系数据模型"""
        relationship_model = {
            "namespace": "looma_crm",
            "model": "relationship",
            "description": "人才关系网络数据模型",
            "fields": {
                "id": {
                    "type": "string", 
                    "primary_key": True,
                    "description": "关系唯一标识符",
                    "format": "rel_{source_id}_{target_id}"
                },
                "source_talent_id": {
                    "type": "string", 
                    "foreign_key": "looma_crm.talent.id",
                    "description": "源人才ID",
                    "required": True
                },
                "target_talent_id": {
                    "type": "string", 
                    "foreign_key": "looma_crm.talent.id",
                    "description": "目标人才ID",
                    "required": True
                },
                "relationship_type": {
                    "type": "string", 
                    "enum": ["colleague", "mentor", "mentee", "friend", "family", "business_partner"],
                    "description": "关系类型",
                    "required": True
                },
                "strength": {
                    "type": "float", 
                    "range": "0.0-1.0",
                    "description": "关系强度",
                    "default": 0.5
                },
                "context": {
                    "type": "string",
                    "description": "关系上下文",
                    "max_length": 500,
                    "nullable": True
                },
                "is_bidirectional": {
                    "type": "boolean",
                    "description": "是否为双向关系",
                    "default": False
                },
                "created_at": {
                    "type": "datetime",
                    "description": "创建时间",
                    "auto_generate": True
                },
                "updated_at": {
                    "type": "datetime",
                    "description": "更新时间",
                    "auto_update": True
                }
            },
            "indexes": [
                {"fields": ["source_talent_id"], "type": "btree", "description": "源人才ID索引"},
                {"fields": ["target_talent_id"], "type": "btree", "description": "目标人才ID索引"},
                {"fields": ["relationship_type"], "type": "btree", "description": "关系类型索引"},
                {"fields": ["source_talent_id", "target_talent_id"], "type": "unique", "description": "关系唯一索引"}
            ],
            "constraints": {
                "strength_range": "0.0 <= strength <= 1.0",
                "no_self_relationship": "source_talent_id != target_talent_id",
                "context_length": "length(context) <= 500"
            }
        }
        self.models["relationship"] = relationship_model
        return relationship_model
    
    def design_talent_project_participation_model(self):
        """设计人才项目参与模型"""
        participation_model = {
            "namespace": "looma_crm",
            "model": "talent_project_participation",
            "description": "人才项目参与关系模型",
            "fields": {
                "id": {
                    "type": "string", 
                    "primary_key": True,
                    "description": "参与关系唯一标识符",
                    "format": "part_{talent_id}_{project_id}"
                },
                "talent_id": {
                    "type": "string", 
                    "foreign_key": "looma_crm.talent.id",
                    "description": "人才ID",
                    "required": True
                },
                "project_id": {
                    "type": "string", 
                    "foreign_key": "looma_crm.project.id",
                    "description": "项目ID",
                    "required": True
                },
                "role": {
                    "type": "string",
                    "description": "在项目中的角色",
                    "max_length": 100,
                    "required": True
                },
                "contribution": {
                    "type": "text",
                    "description": "贡献描述",
                    "nullable": True
                },
                "start_date": {
                    "type": "date",
                    "description": "参与开始日期",
                    "required": True
                },
                "end_date": {
                    "type": "date",
                    "description": "参与结束日期",
                    "nullable": True
                },
                "status": {
                    "type": "string", 
                    "enum": ["active", "completed", "cancelled"],
                    "description": "参与状态",
                    "default": "active"
                },
                "created_at": {
                    "type": "datetime",
                    "description": "创建时间",
                    "auto_generate": True
                },
                "updated_at": {
                    "type": "datetime",
                    "description": "更新时间",
                    "auto_update": True
                }
            },
            "indexes": [
                {"fields": ["talent_id"], "type": "btree", "description": "人才ID索引"},
                {"fields": ["project_id"], "type": "btree", "description": "项目ID索引"},
                {"fields": ["status"], "type": "btree", "description": "参与状态索引"},
                {"fields": ["talent_id", "project_id"], "type": "unique", "description": "参与关系唯一索引"}
            ],
            "constraints": {
                "end_date_after_start_date": "end_date IS NULL OR end_date >= start_date",
                "role_length": "length(role) <= 100"
            }
        }
        self.models["talent_project_participation"] = participation_model
        return participation_model
    
    def design_skill_model(self):
        """设计技能数据模型"""
        skill_model = {
            "namespace": "looma_crm",
            "model": "skill",
            "description": "技能标准化数据模型",
            "fields": {
                "id": {
                    "type": "string", 
                    "primary_key": True,
                    "description": "技能唯一标识符",
                    "format": "skill_{normalized_name}"
                },
                "name": {
                    "type": "string", 
                    "required": True,
                    "description": "技能名称",
                    "max_length": 100,
                    "unique": True
                },
                "category": {
                    "type": "string",
                    "description": "技能分类",
                    "enum": ["programming", "design", "management", "marketing", "sales", "other"],
                    "required": True
                },
                "description": {
                    "type": "text",
                    "description": "技能描述",
                    "nullable": True
                },
                "aliases": {
                    "type": "array", 
                    "items": "string",
                    "description": "技能别名",
                    "default": []
                },
                "created_at": {
                    "type": "datetime",
                    "description": "创建时间",
                    "auto_generate": True
                },
                "updated_at": {
                    "type": "datetime",
                    "description": "更新时间",
                    "auto_update": True
                }
            },
            "indexes": [
                {"fields": ["name"], "type": "unique", "description": "技能名称唯一索引"},
                {"fields": ["category"], "type": "btree", "description": "技能分类索引"},
                {"fields": ["aliases"], "type": "gin", "description": "技能别名GIN索引"}
            ],
            "constraints": {
                "name_length": "length(name) <= 100"
            }
        }
        self.models["skill"] = skill_model
        return skill_model
    
    def design_all_models(self):
        """设计所有Looma CRM数据模型"""
        print("🎨 开始设计Looma CRM数据模型...")
        
        models = [
            ("talent", self.design_talent_model),
            ("project", self.design_project_model),
            ("relationship", self.design_relationship_model),
            ("talent_project_participation", self.design_talent_project_participation_model),
            ("skill", self.design_skill_model)
        ]
        
        for model_name, design_func in models:
            print(f"  📋 设计 {model_name} 模型...")
            design_func()
        
        print(f"✅ 完成 {len(models)} 个数据模型设计")
        return self.models
    
    def generate_model_documentation(self):
        """生成数据模型文档"""
        print("📝 生成数据模型设计文档...")
        
        # 计算统计信息
        total_models = len(self.models)
        total_fields = sum(len(model["fields"]) for model in self.models.values())
        total_indexes = sum(len(model["indexes"]) for model in self.models.values())
        total_constraints = sum(len(model["constraints"]) for model in self.models.values())
        
        # 分析模型关系
        relationships = {
            "talent_to_project": {
                "type": "many_to_many",
                "through": "talent_project_participation",
                "description": "人才与项目的多对多关系"
            },
            "talent_to_talent": {
                "type": "many_to_many",
                "through": "relationship",
                "description": "人才之间的人际关系网络"
            },
            "talent_to_skill": {
                "type": "many_to_many",
                "through": "talent.skills",
                "description": "人才与技能的多对多关系"
            },
            "project_to_skill": {
                "type": "many_to_many",
                "through": "project.skills_needed",
                "description": "项目与所需技能的多对多关系"
            }
        }
        
        # 分析数据一致性要求
        consistency_requirements = {
            "zervigo_integration": {
                "talent.zervigo_user_id": "必须与Zervigo用户服务中的用户ID保持一致",
                "project.zervigo_job_id": "必须与Zervigo职位服务中的职位ID保持一致"
            },
            "data_validation": {
                "email_format": "所有邮箱字段必须符合标准邮箱格式",
                "phone_format": "所有电话字段必须符合标准电话格式",
                "date_consistency": "所有日期字段必须符合ISO 8601格式",
                "enum_consistency": "所有枚举字段必须使用预定义的值"
            },
            "referential_integrity": {
                "foreign_keys": "所有外键必须引用有效的主键",
                "cascade_rules": "定义级联删除和更新规则",
                "orphan_prevention": "防止孤立记录的产生"
            }
        }
        
        documentation = {
            "design_time": datetime.now().isoformat(),
            "designer_version": "1.0",
            "namespace": "looma_crm",
            "models": self.models,
            "relationships": relationships,
            "consistency_requirements": consistency_requirements,
            "summary": {
                "total_models": total_models,
                "total_fields": total_fields,
                "total_indexes": total_indexes,
                "total_constraints": total_constraints,
                "models_per_category": {
                    "core_models": ["talent", "project"],
                    "relationship_models": ["relationship", "talent_project_participation"],
                    "reference_models": ["skill"]
                }
            },
            "integration_points": {
                "zervigo_auth_service": {
                    "target_model": "talent",
                    "mapping_fields": ["zervigo_user_id", "name", "email", "status"],
                    "sync_strategy": "real_time"
                },
                "zervigo_job_service": {
                    "target_model": "project",
                    "mapping_fields": ["zervigo_job_id", "name", "description", "status"],
                    "sync_strategy": "real_time"
                },
                "zervigo_resume_service": {
                    "target_model": "talent",
                    "mapping_fields": ["skills", "experience", "education"],
                    "sync_strategy": "batch"
                }
            }
        }
        
        # 保存文档
        doc_path = "docs/looma_model_design_documentation.json"
        os.makedirs(os.path.dirname(doc_path), exist_ok=True)
        
        with open(doc_path, "w", encoding="utf-8") as f:
            json.dump(documentation, f, indent=2, ensure_ascii=False)
        
        print(f"✅ 设计文档已保存到: {doc_path}")
        return documentation

def main():
    """主函数"""
    print("🚀 开始Looma CRM数据模型设计...")
    
    try:
        designer = LoomaModelDesigner()
        
        # 设计所有数据模型
        designer.design_all_models()
        
        # 生成设计文档
        documentation = designer.generate_model_documentation()
        
        print("\n🎉 Looma CRM数据模型设计完成！")
        print(f"📊 设计了 {documentation['summary']['total_models']} 个数据模型")
        print(f"🔢 总计 {documentation['summary']['total_fields']} 个字段")
        print(f"📇 总计 {documentation['summary']['total_indexes']} 个索引")
        print(f"🔒 总计 {documentation['summary']['total_constraints']} 个约束")
        print(f"🔗 定义了 {len(documentation['relationships'])} 个模型关系")
        print(f"🎯 识别了 {len(documentation['integration_points'])} 个集成点")
        
    except Exception as e:
        print(f"\n❌ 设计失败: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()
