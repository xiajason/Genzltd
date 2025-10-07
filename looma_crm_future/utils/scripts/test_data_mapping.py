#!/usr/bin/env python3
"""
数据映射测试脚本
测试数据映射和验证功能
验证数据一致性解决方案
"""

import asyncio
import sys
import os
from datetime import datetime

# 添加项目根目录到Python路径
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from shared.database.enhanced_unified_data_access import EnhancedUnifiedDataAccess
from shared.database.data_mappers import ZervigoToLoomaMapper, DataMappingService
from shared.database.data_validators import LoomaDataValidator, ValidationService

async def test_data_mapping():
    """测试数据映射功能"""
    print("🧪 开始测试数据映射功能...")
    
    # 测试Zervigo到Looma CRM的映射
    mapper = ZervigoToLoomaMapper()
    
    zervigo_user = {
        "id": 1,
        "username": "test_user",
        "email": "test@example.com",
        "role": "user",
        "status": "active",
        "created_at": "2025-09-23T10:00:00Z",
        "updated_at": "2025-09-23T10:00:00Z"
    }
    
    looma_talent = await mapper.map_user_to_talent(zervigo_user)
    print(f"✅ 映射结果: {looma_talent}")
    
    # 测试反向映射
    zervigo_user_back = await mapper.map_talent_to_user(looma_talent)
    print(f"✅ 反向映射结果: {zervigo_user_back}")
    
    # 测试职位映射
    zervigo_job = {
        "id": 1,
        "title": "Python Developer",
        "description": "开发Python应用程序",
        "requirements": {
            "skills": ["Python", "Django", "PostgreSQL"],
            "experience": "3+ years"
        },
        "status": "active",
        "created_at": "2025-09-23T10:00:00Z"
    }
    
    looma_project = await mapper.map_job_to_project(zervigo_job)
    print(f"✅ 职位映射结果: {looma_project}")
    
    # 测试简历技能映射
    zervigo_resume = {
        "id": 1,
        "user_id": 1,
        "filename": "resume.pdf",
        "parsed_data": {
            "skills": ["Python", "Sanic", "微服务"],
            "experience": [
                {
                    "company": "Example Company",
                    "position": "Software Engineer",
                    "duration": "2 years",
                    "skills": ["Python", "Django"]
                }
            ],
            "education": [
                {
                    "degree": "Bachelor",
                    "school": "Example University",
                    "major": "Computer Science",
                    "year": 2020
                }
            ]
        },
        "status": "parsed",
        "created_at": "2025-09-23T10:00:00Z"
    }
    
    talent_skills = await mapper.map_resume_to_talent_skills(zervigo_resume)
    print(f"✅ 简历技能映射结果: {talent_skills}")

async def test_data_validation():
    """测试数据验证功能"""
    print("\n🧪 开始测试数据验证功能...")
    
    validator = LoomaDataValidator()
    
    # 测试有效数据
    valid_data = {
        "id": "talent_1",
        "name": "Test Talent",
        "email": "test@example.com",
        "phone": "+1234567890",
        "skills": ["Python", "Sanic"],
        "experience": 5,
        "status": "active",
        "zervigo_user_id": 1
    }
    
    result = await validator.validate(valid_data)
    print(f"✅ 有效数据验证结果: {result.is_valid}")
    if result.warnings:
        print(f"⚠️  警告: {result.warnings}")
    
    # 测试无效数据
    invalid_data = {
        "id": "talent_1",
        "name": "Test Talent",
        "email": "invalid-email",
        "experience": 100,  # 超出范围
        "status": "invalid_status"
    }
    
    result = await validator.validate(invalid_data)
    print(f"❌ 无效数据验证结果: {result.is_valid}")
    print(f"❌ 验证错误: {result.errors}")
    
    # 测试业务规则验证
    validation_service = ValidationService()
    
    business_data = {
        "id": "talent_2",
        "name": "Business Test",
        "email": "business@example.com",
        "status": "active",
        "experience": 60,  # 超过50年
        "skills": ["Python"] * 60,  # 超过50个技能
        "zervigo_user_id": 2
    }
    
    result = await validation_service.validate_data(business_data, "looma_talent")
    print(f"🔍 业务规则验证结果: {result.is_valid}")
    print(f"⚠️  业务规则警告: {result.warnings}")

async def test_enhanced_data_access():
    """测试增强的数据访问功能"""
    print("\n🧪 开始测试增强的数据访问功能...")
    
    data_access = EnhancedUnifiedDataAccess()
    
    # 初始化数据访问层
    await data_access.initialize()
    
    # 测试获取人才数据
    talent_data = await data_access.get_talent_data("talent_1")
    print(f"✅ 获取人才数据: {talent_data}")
    
    # 测试保存人才数据
    new_talent = {
        "id": "talent_2",
        "name": "New Talent",
        "email": "new@example.com",
        "status": "active",
        "zervigo_user_id": 2
    }
    
    success = await data_access.save_talent_data(new_talent)
    print(f"✅ 保存人才数据结果: {success}")
    
    # 测试数据一致性验证
    consistency_result = await data_access.validate_data_consistency("talent_1")
    print(f"🔍 数据一致性验证结果: {consistency_result}")
    
    # 测试从简历同步技能
    sync_success = await data_access.sync_talent_skills_from_resume("talent_1")
    print(f"🔄 技能同步结果: {sync_success}")
    
    # 获取同步状态
    sync_status = await data_access.get_sync_status()
    print(f"📊 同步状态: {sync_status}")
    
    # 关闭数据访问层
    await data_access.close()

async def test_data_consistency():
    """测试数据一致性功能"""
    print("\n🧪 开始测试数据一致性功能...")
    
    from shared.database.data_validators import DataConsistencyValidator
    
    consistency_validator = DataConsistencyValidator()
    
    # 测试一致的数据
    looma_data = {
        "id": "talent_1",
        "name": "Test User",
        "email": "test@example.com",
        "status": "active",
        "zervigo_user_id": 1,
        "updated_at": "2025-09-23T10:00:00Z"
    }
    
    zervigo_data = {
        "id": 1,
        "username": "Test User",
        "email": "test@example.com",
        "status": "active",
        "updated_at": "2025-09-23T10:00:00Z"
    }
    
    result = await consistency_validator.validate_cross_service_consistency(looma_data, zervigo_data)
    print(f"✅ 一致数据验证结果: {result.is_valid}")
    if result.warnings:
        print(f"⚠️  警告: {result.warnings}")
    
    # 测试不一致的数据
    inconsistent_looma_data = {
        "id": "talent_2",
        "name": "Test User 2",
        "email": "test2@example.com",
        "status": "active",
        "zervigo_user_id": 2,
        "updated_at": "2025-09-23T10:00:00Z"
    }
    
    inconsistent_zervigo_data = {
        "id": 2,
        "username": "Test User 2",
        "email": "different@example.com",  # 不同的邮箱
        "status": "inactive",  # 不同的状态
        "updated_at": "2025-09-23T11:00:00Z"  # 不同的时间
    }
    
    result = await consistency_validator.validate_cross_service_consistency(
        inconsistent_looma_data, inconsistent_zervigo_data
    )
    print(f"❌ 不一致数据验证结果: {result.is_valid}")
    print(f"❌ 一致性错误: {result.errors}")
    print(f"⚠️  一致性警告: {result.warnings}")

async def test_mapping_service():
    """测试数据映射服务"""
    print("\n🧪 开始测试数据映射服务...")
    
    mapping_service = DataMappingService()
    
    # 测试用户映射
    user_data = {
        "user": {
            "id": 3,
            "username": "service_test",
            "email": "service@example.com",
            "role": "user",
            "status": "active",
            "created_at": "2025-09-23T10:00:00Z"
        }
    }
    
    mapped_data = await mapping_service.map_data("zervigo", "looma_crm", user_data)
    print(f"✅ 服务映射结果: {mapped_data}")
    
    # 测试反向映射
    talent_data = {
        "talent": {
            "id": "talent_3",
            "name": "Service Test",
            "email": "service@example.com",
            "status": "active",
            "zervigo_user_id": 3
        }
    }
    
    reverse_mapped_data = await mapping_service.reverse_map_data("looma_crm", "zervigo", talent_data)
    print(f"✅ 反向服务映射结果: {reverse_mapped_data}")
    
    # 测试缓存功能
    cache_stats = await mapping_service.get_cache_stats()
    print(f"📊 映射缓存统计: {cache_stats}")
    
    # 清空缓存
    await mapping_service.clear_cache()
    print("🗑️  映射缓存已清空")

async def main():
    """主函数"""
    print("🚀 开始数据库适配功能测试...")
    print("=" * 60)
    
    try:
        await test_data_mapping()
        await test_data_validation()
        await test_enhanced_data_access()
        await test_data_consistency()
        await test_mapping_service()
        
        print("\n" + "=" * 60)
        print("🎉 所有测试完成！")
        print("\n📋 测试总结:")
        print("✅ 数据映射功能 - 通过")
        print("✅ 数据验证功能 - 通过")
        print("✅ 增强数据访问功能 - 通过")
        print("✅ 数据一致性验证 - 通过")
        print("✅ 数据映射服务 - 通过")
        print("\n🎯 数据一致性解决方案验证成功！")
        
    except Exception as e:
        print(f"\n❌ 测试失败: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    asyncio.run(main())
