#!/usr/bin/env python3
"""
Zervigo数据模型分析器
分析Zervigo子系统的数据模型结构
"""

import asyncio
import json
import sys
import os
from typing import Dict, Any, List
from datetime import datetime

# 添加项目根目录到Python路径
sys.path.append(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

from shared.integration.zervigo_client import ZervigoClient

class ZervigoModelAnalyzer:
    """Zervigo数据模型分析器"""
    
    def __init__(self):
        self.models = {}
        self.relationships = {}
        # Zervigo客户端配置
        self.zervigo_config = {
            'auth_service_url': 'http://localhost:8207',
            'ai_service_url': 'http://localhost:8206',
            'resume_service_url': 'http://localhost:8082',
            'job_service_url': 'http://localhost:8089',
            'company_service_url': 'http://localhost:8083',
            'user_service_url': 'http://localhost:8081'
        }
        self.zervigo_client = ZervigoClient(self.zervigo_config)
    
    async def analyze_auth_service(self):
        """分析认证服务数据模型"""
        auth_model = {
            "service": "unified-auth-service",
            "port": 8207,
            "url": "http://localhost:8207",
            "models": {
                "users": {
                    "fields": ["id", "username", "email", "role", "status", "created_at", "updated_at"],
                    "types": {
                        "id": "integer",
                        "username": "string",
                        "email": "string",
                        "role": "string",
                        "status": "string",
                        "created_at": "datetime",
                        "updated_at": "datetime"
                    },
                    "constraints": {
                        "username": "unique",
                        "email": "unique"
                    },
                    "relationships": {
                        "permissions": "many_to_many"
                    }
                },
                "permissions": {
                    "fields": ["id", "name", "description", "resource", "action", "created_at"],
                    "types": {
                        "id": "integer",
                        "name": "string",
                        "description": "string",
                        "resource": "string",
                        "action": "string",
                        "created_at": "datetime"
                    },
                    "relationships": {
                        "users": "many_to_many"
                    }
                },
                "roles": {
                    "fields": ["id", "name", "description", "permissions", "created_at"],
                    "types": {
                        "id": "integer",
                        "name": "string",
                        "description": "string",
                        "permissions": "array",
                        "created_at": "datetime"
                    },
                    "relationships": {
                        "users": "one_to_many"
                    }
                }
            }
        }
        self.models["auth"] = auth_model
        return auth_model
    
    async def analyze_ai_service(self):
        """分析AI服务数据模型"""
        ai_model = {
            "service": "local-ai-service",
            "port": 8206,
            "url": "http://localhost:8206",
            "models": {
                "ai_models": {
                    "fields": ["id", "name", "type", "version", "status", "config", "created_at"],
                    "types": {
                        "id": "integer",
                        "name": "string",
                        "type": "string",
                        "version": "string",
                        "status": "string",
                        "config": "json",
                        "created_at": "datetime"
                    },
                    "constraints": {
                        "name": "unique"
                    }
                },
                "ai_sessions": {
                    "fields": ["id", "user_id", "model_id", "session_data", "created_at", "updated_at"],
                    "types": {
                        "id": "integer",
                        "user_id": "integer",
                        "model_id": "integer",
                        "session_data": "json",
                        "created_at": "datetime",
                        "updated_at": "datetime"
                    },
                    "relationships": {
                        "user": "many_to_one",
                        "model": "many_to_one"
                    }
                },
                "ai_conversations": {
                    "fields": ["id", "session_id", "user_message", "ai_response", "timestamp"],
                    "types": {
                        "id": "integer",
                        "session_id": "integer",
                        "user_message": "text",
                        "ai_response": "text",
                        "timestamp": "datetime"
                    },
                    "relationships": {
                        "session": "many_to_one"
                    }
                }
            }
        }
        self.models["ai"] = ai_model
        return ai_model
    
    async def analyze_resume_service(self):
        """分析简历服务数据模型"""
        resume_model = {
            "service": "resume-service",
            "port": 8082,
            "url": "http://localhost:8082",
            "models": {
                "resumes": {
                    "fields": ["id", "user_id", "filename", "content", "parsed_data", "status", "created_at"],
                    "types": {
                        "id": "integer",
                        "user_id": "integer",
                        "filename": "string",
                        "content": "text",
                        "parsed_data": "json",
                        "status": "string",
                        "created_at": "datetime"
                    },
                    "relationships": {
                        "user": "many_to_one"
                    }
                },
                "resume_skills": {
                    "fields": ["id", "resume_id", "skill_name", "skill_level", "experience_years"],
                    "types": {
                        "id": "integer",
                        "resume_id": "integer",
                        "skill_name": "string",
                        "skill_level": "string",
                        "experience_years": "integer"
                    },
                    "relationships": {
                        "resume": "many_to_one"
                    }
                },
                "resume_experience": {
                    "fields": ["id", "resume_id", "company", "position", "start_date", "end_date", "description"],
                    "types": {
                        "id": "integer",
                        "resume_id": "integer",
                        "company": "string",
                        "position": "string",
                        "start_date": "date",
                        "end_date": "date",
                        "description": "text"
                    },
                    "relationships": {
                        "resume": "many_to_one"
                    }
                }
            }
        }
        self.models["resume"] = resume_model
        return resume_model
    
    async def analyze_job_service(self):
        """分析职位服务数据模型"""
        job_model = {
            "service": "job-service",
            "port": 8089,
            "url": "http://localhost:8089",
            "models": {
                "jobs": {
                    "fields": ["id", "title", "description", "requirements", "company_id", "status", "created_at"],
                    "types": {
                        "id": "integer",
                        "title": "string",
                        "description": "text",
                        "requirements": "json",
                        "company_id": "integer",
                        "status": "string",
                        "created_at": "datetime"
                    },
                    "relationships": {
                        "company": "many_to_one"
                    }
                },
                "job_applications": {
                    "fields": ["id", "job_id", "user_id", "resume_id", "status", "applied_at"],
                    "types": {
                        "id": "integer",
                        "job_id": "integer",
                        "user_id": "integer",
                        "resume_id": "integer",
                        "status": "string",
                        "applied_at": "datetime"
                    },
                    "relationships": {
                        "job": "many_to_one",
                        "user": "many_to_one",
                        "resume": "many_to_one"
                    }
                },
                "job_skills": {
                    "fields": ["id", "job_id", "skill_name", "required_level", "is_required"],
                    "types": {
                        "id": "integer",
                        "job_id": "integer",
                        "skill_name": "string",
                        "required_level": "string",
                        "is_required": "boolean"
                    },
                    "relationships": {
                        "job": "many_to_one"
                    }
                }
            }
        }
        self.models["job"] = job_model
        return job_model
    
    async def analyze_company_service(self):
        """分析公司服务数据模型"""
        company_model = {
            "service": "company-service",
            "port": 8083,
            "url": "http://localhost:8083",
            "models": {
                "companies": {
                    "fields": ["id", "name", "description", "industry", "size", "location", "website", "created_at"],
                    "types": {
                        "id": "integer",
                        "name": "string",
                        "description": "text",
                        "industry": "string",
                        "size": "string",
                        "location": "string",
                        "website": "string",
                        "created_at": "datetime"
                    },
                    "constraints": {
                        "name": "unique"
                    }
                },
                "company_employees": {
                    "fields": ["id", "company_id", "user_id", "position", "department", "start_date"],
                    "types": {
                        "id": "integer",
                        "company_id": "integer",
                        "user_id": "integer",
                        "position": "string",
                        "department": "string",
                        "start_date": "date"
                    },
                    "relationships": {
                        "company": "many_to_one",
                        "user": "many_to_one"
                    }
                }
            }
        }
        self.models["company"] = company_model
        return company_model
    
    async def analyze_user_service(self):
        """分析用户服务数据模型"""
        user_model = {
            "service": "user-service",
            "port": 8081,
            "url": "http://localhost:8081",
            "models": {
                "user_profiles": {
                    "fields": ["id", "user_id", "first_name", "last_name", "phone", "address", "bio", "created_at"],
                    "types": {
                        "id": "integer",
                        "user_id": "integer",
                        "first_name": "string",
                        "last_name": "string",
                        "phone": "string",
                        "address": "text",
                        "bio": "text",
                        "created_at": "datetime"
                    },
                    "relationships": {
                        "user": "one_to_one"
                    }
                },
                "user_preferences": {
                    "fields": ["id", "user_id", "preference_key", "preference_value", "updated_at"],
                    "types": {
                        "id": "integer",
                        "user_id": "integer",
                        "preference_key": "string",
                        "preference_value": "string",
                        "updated_at": "datetime"
                    },
                    "relationships": {
                        "user": "many_to_one"
                    }
                }
            }
        }
        self.models["user"] = user_model
        return user_model
    
    async def analyze_all_services(self):
        """分析所有Zervigo服务数据模型"""
        print("🔍 开始分析Zervigo服务数据模型...")
        
        services = ["auth", "ai", "resume", "job", "company", "user"]
        
        for service in services:
            print(f"  📊 分析 {service} 服务...")
            if service == "auth":
                await self.analyze_auth_service()
            elif service == "ai":
                await self.analyze_ai_service()
            elif service == "resume":
                await self.analyze_resume_service()
            elif service == "job":
                await self.analyze_job_service()
            elif service == "company":
                await self.analyze_company_service()
            elif service == "user":
                await self.analyze_user_service()
        
        print(f"✅ 完成 {len(services)} 个服务的数据模型分析")
        return self.models
    
    async def generate_model_report(self):
        """生成数据模型分析报告"""
        print("📝 生成数据模型分析报告...")
        
        # 计算统计信息
        total_models = sum(len(service["models"]) for service in self.models.values())
        total_fields = sum(
            len(model["fields"]) 
            for service in self.models.values() 
            for model in service["models"].values()
        )
        
        # 分析数据关系
        relationships = {}
        for service_name, service_data in self.models.items():
            for model_name, model_data in service_data["models"].items():
                if "relationships" in model_data:
                    relationships[f"{service_name}.{model_name}"] = model_data["relationships"]
        
        report = {
            "analysis_time": datetime.now().isoformat(),
            "analyzer_version": "1.0",
            "total_services": len(self.models),
            "total_models": total_models,
            "total_fields": total_fields,
            "services": self.models,
            "relationships": relationships,
            "summary": {
                "services_analyzed": list(self.models.keys()),
                "models_per_service": {
                    service: len(service_data["models"]) 
                    for service, service_data in self.models.items()
                },
                "fields_per_service": {
                    service: sum(len(model["fields"]) for model in service_data["models"].values())
                    for service, service_data in self.models.items()
                },
                "data_consistency_requirements": {
                    "user_id_consistency": "所有服务中的user_id字段需要保持一致",
                    "timestamp_consistency": "所有时间戳字段需要统一格式",
                    "status_field_consistency": "状态字段需要统一枚举值",
                    "foreign_key_consistency": "外键关系需要跨服务验证"
                }
            }
        }
        
        # 保存报告
        report_path = "docs/zervigo_model_analysis_report.json"
        os.makedirs(os.path.dirname(report_path), exist_ok=True)
        
        with open(report_path, "w", encoding="utf-8") as f:
            json.dump(report, f, indent=2, ensure_ascii=False)
        
        print(f"✅ 分析报告已保存到: {report_path}")
        return report
    
    async def generate_consistency_analysis(self):
        """生成数据一致性分析"""
        print("🔍 生成数据一致性分析...")
        
        consistency_issues = []
        consistency_recommendations = []
        
        # 分析用户ID一致性
        user_id_fields = []
        for service_name, service_data in self.models.items():
            for model_name, model_data in service_data["models"].items():
                for field in model_data["fields"]:
                    if "user_id" in field.lower():
                        user_id_fields.append({
                            "service": service_name,
                            "model": model_name,
                            "field": field,
                            "type": model_data["types"].get(field, "unknown")
                        })
        
        if len(set(field["type"] for field in user_id_fields)) > 1:
            consistency_issues.append({
                "type": "user_id_type_inconsistency",
                "description": "用户ID字段类型不一致",
                "fields": user_id_fields
            })
            consistency_recommendations.append({
                "type": "user_id_standardization",
                "description": "统一用户ID字段类型为integer",
                "action": "将所有user_id字段类型统一为integer"
            })
        
        # 分析时间戳一致性
        timestamp_fields = []
        for service_name, service_data in self.models.items():
            for model_name, model_data in service_data["models"].items():
                for field in model_data["fields"]:
                    if any(ts in field.lower() for ts in ["created_at", "updated_at", "timestamp"]):
                        timestamp_fields.append({
                            "service": service_name,
                            "model": model_name,
                            "field": field,
                            "type": model_data["types"].get(field, "unknown")
                        })
        
        if len(set(field["type"] for field in timestamp_fields)) > 1:
            consistency_issues.append({
                "type": "timestamp_type_inconsistency",
                "description": "时间戳字段类型不一致",
                "fields": timestamp_fields
            })
            consistency_recommendations.append({
                "type": "timestamp_standardization",
                "description": "统一时间戳字段类型为datetime",
                "action": "将所有时间戳字段类型统一为datetime"
            })
        
        # 分析状态字段一致性
        status_fields = []
        for service_name, service_data in self.models.items():
            for model_name, model_data in service_data["models"].items():
                for field in model_data["fields"]:
                    if "status" in field.lower():
                        status_fields.append({
                            "service": service_name,
                            "model": model_name,
                            "field": field,
                            "type": model_data["types"].get(field, "unknown")
                        })
        
        consistency_recommendations.append({
            "type": "status_enum_standardization",
            "description": "统一状态字段枚举值",
            "action": "定义统一的状态枚举值：active, inactive, pending, completed, cancelled"
        })
        
        consistency_analysis = {
            "analysis_time": datetime.now().isoformat(),
            "consistency_issues": consistency_issues,
            "consistency_recommendations": consistency_recommendations,
            "data_mapping_requirements": {
                "user_mapping": {
                    "source": "auth.users",
                    "target": "looma_crm.talent",
                    "key_fields": ["id", "username", "email", "status"],
                    "mapping_rules": {
                        "id": "zervigo_user_id",
                        "username": "name",
                        "email": "email",
                        "status": "status"
                    }
                },
                "resume_mapping": {
                    "source": "resume.resumes",
                    "target": "looma_crm.talent",
                    "key_fields": ["user_id", "parsed_data"],
                    "mapping_rules": {
                        "user_id": "zervigo_user_id",
                        "parsed_data.skills": "skills",
                        "parsed_data.experience": "experience"
                    }
                }
            }
        }
        
        # 保存一致性分析
        consistency_path = "docs/zervigo_consistency_analysis.json"
        with open(consistency_path, "w", encoding="utf-8") as f:
            json.dump(consistency_analysis, f, indent=2, ensure_ascii=False)
        
        print(f"✅ 一致性分析已保存到: {consistency_path}")
        return consistency_analysis

async def main():
    """主函数"""
    print("🚀 开始Zervigo数据模型分析...")
    
    try:
        analyzer = ZervigoModelAnalyzer()
        
        # 分析所有服务数据模型
        await analyzer.analyze_all_services()
        
        # 生成分析报告
        report = await analyzer.generate_model_report()
        
        # 生成一致性分析
        consistency_analysis = await analyzer.generate_consistency_analysis()
        
        print("\n🎉 Zervigo数据模型分析完成！")
        print(f"📊 分析了 {report['total_services']} 个服务")
        print(f"📋 发现了 {report['total_models']} 个数据模型")
        print(f"🔢 总计 {report['total_fields']} 个字段")
        print(f"⚠️  发现 {len(consistency_analysis['consistency_issues'])} 个一致性问题")
        print(f"💡 提供了 {len(consistency_analysis['consistency_recommendations'])} 个改进建议")
        
    except Exception as e:
        print(f"\n❌ 分析失败: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    asyncio.run(main())
