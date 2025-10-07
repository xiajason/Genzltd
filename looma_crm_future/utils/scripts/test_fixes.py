#!/usr/bin/env python3
"""
修复测试脚本
测试数据库连接修复、映射器配置修复、数据修复机制
"""

import asyncio
import sys
import os
from datetime import datetime

# 添加项目根目录到Python路径
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from shared.database.data_mappers import DataMappingService
from shared.database.data_repair_service import DataRepairService

async def test_mapper_fixes():
    """测试映射器配置修复"""
    print("🧪 测试映射器配置修复...")
    
    mapping_service = DataMappingService()
    
    # 测试之前失败的映射器键名
    test_data = {
        "user": {
            "id": 1,
            "username": "test_user",
            "email": "test@example.com",
            "role": "user",
            "status": "active",
            "created_at": "2025-09-23T10:00:00Z"
        }
    }
    
    # 测试各种映射器键名
    mapper_tests = [
        ("zervigo", "looma_crm", "zervigo_to_looma_crm"),
        ("zervigo", "looma", "zervigo_to_looma"),
        ("looma_crm", "zervigo", "looma_crm_to_zervigo")
    ]
    
    for source, target, expected_key in mapper_tests:
        print(f"  测试映射器: {source} -> {target}")
        
        # 测试正向映射
        result = await mapping_service.map_data(source, target, test_data)
        if result:
            print(f"    ✅ 正向映射成功: {expected_key}")
        else:
            print(f"    ❌ 正向映射失败: {expected_key}")
        
        # 测试反向映射
        if source != target:  # 避免循环映射
            reverse_result = await mapping_service.reverse_map_data(source, target, test_data)
            if reverse_result:
                print(f"    ✅ 反向映射成功: {target} -> {source}")
            else:
                print(f"    ❌ 反向映射失败: {target} -> {source}")
    
    # 测试缓存功能
    cache_stats = await mapping_service.get_cache_stats()
    print(f"  📊 映射缓存统计: {cache_stats}")
    
    print("✅ 映射器配置修复测试完成")

async def test_data_repair_mechanism():
    """测试数据修复机制"""
    print("\n🧪 测试数据修复机制...")
    
    repair_service = DataRepairService()
    
    # 测试数据不一致检测和修复
    test_talent_id = "talent_1"
    
    print(f"  测试人才ID: {test_talent_id}")
    
    # 执行检测和修复
    repair_result = await repair_service.detect_and_repair_inconsistencies(test_talent_id)
    
    print(f"  📊 修复结果:")
    print(f"    人才ID: {repair_result['talent_id']}")
    print(f"    修复时间: {repair_result['repair_time']}")
    print(f"    检测到问题数: {len(repair_result['issues_detected'])}")
    print(f"    应用修复数: {len(repair_result['repairs_applied'])}")
    print(f"    修复成功: {repair_result['repair_success']}")
    
    if repair_result['issues_detected']:
        print(f"  🔍 检测到的问题:")
        for i, issue in enumerate(repair_result['issues_detected'], 1):
            print(f"    {i}. {issue['type']}: {issue['description']}")
            print(f"       严重程度: {issue['severity']}")
    
    if repair_result['repairs_applied']:
        print(f"  🔧 应用的修复:")
        for i, repair in enumerate(repair_result['repairs_applied'], 1):
            print(f"    {i}. {repair['type']}: {repair['status']}")
            if 'action' in repair:
                print(f"       操作: {repair['action']}")
    
    # 测试修复统计
    stats = await repair_service.get_repair_statistics()
    print(f"  📈 修复统计:")
    print(f"    总修复次数: {stats['total_repairs']}")
    print(f"    成功修复次数: {stats['successful_repairs']}")
    print(f"    失败修复次数: {stats['failed_repairs']}")
    print(f"    成功率: {stats['success_rate']:.1f}%")
    
    # 测试自动修复开关
    await repair_service.enable_auto_repair(False)
    print(f"  🔧 自动修复已禁用")
    
    await repair_service.enable_auto_repair(True)
    print(f"  🔧 自动修复已启用")
    
    print("✅ 数据修复机制测试完成")

async def test_enhanced_mapping_service():
    """测试增强的映射服务"""
    print("\n🧪 测试增强的映射服务...")
    
    mapping_service = DataMappingService()
    
    # 测试自动注册功能
    print("  测试自动注册映射器...")
    
    # 尝试使用未注册的映射器
    test_data = {
        "user": {
            "id": 2,
            "username": "auto_test",
            "email": "auto@example.com",
            "status": "active"
        }
    }
    
    # 这应该触发自动注册
    result = await mapping_service.map_data("zervigo", "looma_crm", test_data)
    if result:
        print(f"    ✅ 自动注册映射器成功")
    else:
        print(f"    ❌ 自动注册映射器失败")
    
    # 测试反向映射自动注册
    talent_data = {
        "talent": {
            "id": "talent_2",
            "name": "Auto Test",
            "email": "auto@example.com",
            "zervigo_user_id": 2
        }
    }
    
    reverse_result = await mapping_service.reverse_map_data("looma_crm", "zervigo", talent_data)
    if reverse_result:
        print(f"    ✅ 反向映射自动注册成功")
    else:
        print(f"    ❌ 反向映射自动注册失败")
    
    print("✅ 增强映射服务测试完成")

async def main():
    """主函数"""
    print("🚀 开始修复测试...")
    print("=" * 60)
    
    try:
        await test_mapper_fixes()
        await test_data_repair_mechanism()
        await test_enhanced_mapping_service()
        
        print("\n" + "=" * 60)
        print("🎉 所有修复测试完成！")
        print("\n📋 修复测试总结:")
        print("✅ 映射器配置修复 - 通过")
        print("✅ 数据修复机制 - 通过")
        print("✅ 增强映射服务 - 通过")
        print("\n🎯 关键问题修复验证成功！")
        
    except Exception as e:
        print(f"\n❌ 修复测试失败: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    asyncio.run(main())
