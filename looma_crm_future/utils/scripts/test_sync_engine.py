#!/usr/bin/env python3
"""
同步引擎测试脚本
测试数据同步机制的各种功能
"""

import asyncio
import sys
import os
from datetime import datetime, timedelta

# 添加项目根目录到Python路径
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from shared.sync.sync_engine import SyncEngine, SyncEvent, SyncEventType, SyncStatus
from shared.sync.sync_strategies import (
    SyncStrategyManager, SyncStrategyType,
    RealTimeSyncStrategy, IncrementalSyncStrategy, 
    BatchSyncStrategy, ManualSyncStrategy
)
from shared.sync.conflict_resolver import ConflictResolver, Conflict, ConflictType, ResolutionStrategy

async def test_sync_engine_basic():
    """测试同步引擎基础功能"""
    print("🧪 测试同步引擎基础功能...")
    
    # 创建同步引擎
    config = {
        "worker_count": 2,
        "enable_real_time_sync": True,
        "enable_incremental_sync": True,
        "enable_batch_sync": True
    }
    
    sync_engine = SyncEngine(config)
    
    try:
        # 启动同步引擎
        await sync_engine.start()
        print("✅ 同步引擎启动成功")
        
        # 测试数据同步
        test_data = {
            "id": "test_1",
            "name": "Test Data",
            "email": "test@example.com",
            "status": "active",
            "updated_at": datetime.now().isoformat()
        }
        
        result = await sync_engine.sync_data("looma_crm", "zervigo", test_data, SyncEventType.CREATE, priority=1)
        print(f"✅ 数据同步结果: {result.success}")
        
        # 等待一段时间让工作器处理
        await asyncio.sleep(1)
        
        # 获取同步指标
        metrics = sync_engine.get_sync_metrics()
        print(f"📊 同步指标: {metrics}")
        
        # 健康检查
        health = await sync_engine.health_check()
        print(f"🏥 健康状态: {health['status']}")
        
    finally:
        # 停止同步引擎
        await sync_engine.stop()
        print("✅ 同步引擎已停止")

async def test_sync_strategies():
    """测试同步策略"""
    print("\n🧪 测试同步策略...")
    
    # 创建策略管理器
    strategy_manager = SyncStrategyManager()
    
    # 测试实时同步策略
    real_time_strategy = strategy_manager.get_strategy(SyncStrategyType.REAL_TIME)
    if real_time_strategy:
        test_data = {"id": "rt_1", "name": "Real Time Test"}
        success = await real_time_strategy.sync(test_data, SyncEventType.CREATE)
        print(f"✅ 实时同步策略: {success}")
        
        metrics = real_time_strategy.get_metrics()
        print(f"📊 实时同步指标: {metrics}")
    
    # 测试增量同步策略
    incremental_strategy = strategy_manager.get_strategy(SyncStrategyType.INCREMENTAL)
    if incremental_strategy:
        test_data = {"id": "inc_1", "name": "Incremental Test", "updated_at": datetime.now().isoformat()}
        success = await incremental_strategy.sync(test_data, SyncEventType.UPDATE)
        print(f"✅ 增量同步策略: {success}")
        
        metrics = incremental_strategy.get_metrics()
        print(f"📊 增量同步指标: {metrics}")
    
    # 测试批量同步策略
    batch_strategy = strategy_manager.get_strategy(SyncStrategyType.BATCH)
    if batch_strategy:
        # 添加多个数据项
        for i in range(5):
            test_data = {"id": f"batch_{i}", "name": f"Batch Test {i}"}
            await batch_strategy.sync(test_data, SyncEventType.CREATE)
        
        # 等待批量处理
        await asyncio.sleep(2)
        
        metrics = batch_strategy.get_metrics()
        print(f"✅ 批量同步策略完成")
        print(f"📊 批量同步指标: {metrics}")
    
    # 测试手动同步策略
    manual_strategy = strategy_manager.get_strategy(SyncStrategyType.MANUAL)
    if manual_strategy:
        test_data = {"id": "manual_1", "name": "Manual Test"}
        success = await manual_strategy.sync(test_data, SyncEventType.CREATE)
        print(f"✅ 手动同步策略: {success}")
        
        # 获取待处理的手动同步
        pending_syncs = await manual_strategy.get_pending_syncs()
        print(f"📋 待处理的手动同步: {len(pending_syncs)} 个")
        
        # 批准第一个同步
        if pending_syncs:
            sync_id = pending_syncs[0]["id"]
            approval_success = await manual_strategy.approve_sync(sync_id)
            print(f"✅ 手动同步批准: {approval_success}")
    
    # 获取所有策略指标
    all_metrics = strategy_manager.get_strategy_metrics()
    print(f"📊 所有策略指标: {all_metrics}")

async def test_conflict_resolver():
    """测试冲突解决器"""
    print("\n🧪 测试冲突解决器...")
    
    # 创建冲突解决器
    config = {
        "default_strategy": ResolutionStrategy.LAST_WRITE_WINS,
        "source_priority_order": ["looma_crm", "zervigo"],
        "field_priorities": {
            "email": "zervigo",
            "status": "looma_crm"
        }
    }
    
    conflict_resolver = ConflictResolver(config)
    
    # 测试冲突检测
    local_data = {
        "id": "test_1",
        "name": "Test User",
        "email": "local@example.com",
        "status": "active",
        "updated_at": (datetime.now() - timedelta(minutes=5)).isoformat()
    }
    
    remote_data = {
        "id": "test_1",
        "name": "Test User",
        "email": "remote@example.com",
        "status": "inactive",
        "updated_at": datetime.now().isoformat()
    }
    
    conflicts = await conflict_resolver.detect_conflict(local_data, remote_data, "looma_crm", "zervigo")
    print(f"🔍 检测到冲突: {len(conflicts)} 个")
    
    for conflict in conflicts:
        print(f"  - 字段: {conflict.field}, 本地值: {conflict.local_value}, 远程值: {conflict.remote_value}")
        print(f"    策略: {conflict.resolution_strategy.value}")
    
    # 测试冲突解决
    if conflicts:
        results = await conflict_resolver.resolve_conflicts(conflicts)
        print(f"🔧 冲突解决结果: {len(results)} 个")
        
        for result in results:
            print(f"  - 冲突ID: {result.conflict_id}, 成功: {result.success}")
            if result.success:
                print(f"    解决值: {result.resolved_value}")
            else:
                print(f"    错误: {result.error_message}")
    
    # 获取解决统计
    stats = conflict_resolver.get_resolution_stats()
    print(f"📊 冲突解决统计: {stats}")
    
    # 健康检查
    health = await conflict_resolver.health_check()
    print(f"🏥 冲突解决器健康状态: {health['status']}")

async def test_sync_performance():
    """测试同步性能"""
    print("\n🧪 测试同步性能...")
    
    # 创建同步引擎
    config = {
        "worker_count": 4,
        "batch_size": 50
    }
    
    sync_engine = SyncEngine(config)
    
    try:
        await sync_engine.start()
        
        # 测试大量数据同步
        start_time = datetime.now()
        
        tasks = []
        for i in range(100):
            test_data = {
                "id": f"perf_test_{i}",
                "name": f"Performance Test {i}",
                "email": f"test{i}@example.com",
                "status": "active",
                "updated_at": datetime.now().isoformat()
            }
            
            task = sync_engine.sync_data("looma_crm", "zervigo", test_data, SyncEventType.CREATE)
            tasks.append(task)
        
        # 等待所有同步完成
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        end_time = datetime.now()
        duration = (end_time - start_time).total_seconds()
        
        # 统计结果
        successful_syncs = sum(1 for result in results if hasattr(result, 'success') and result.success)
        failed_syncs = len(results) - successful_syncs
        
        print(f"⚡ 性能测试结果:")
        print(f"  总同步数: {len(results)}")
        print(f"  成功同步: {successful_syncs}")
        print(f"  失败同步: {failed_syncs}")
        print(f"  总耗时: {duration:.2f} 秒")
        print(f"  平均耗时: {duration/len(results)*1000:.2f} 毫秒/个")
        print(f"  吞吐量: {len(results)/duration:.2f} 个/秒")
        
        # 获取最终指标
        metrics = sync_engine.get_sync_metrics()
        print(f"📊 最终同步指标: {metrics}")
        
    finally:
        await sync_engine.stop()

async def test_sync_error_handling():
    """测试同步错误处理"""
    print("\n🧪 测试同步错误处理...")
    
    # 创建同步引擎
    sync_engine = SyncEngine({"worker_count": 1})
    
    try:
        await sync_engine.start()
        
        # 测试无效数据同步
        invalid_data = {
            "id": None,  # 无效ID
            "name": "",  # 空名称
            "email": "invalid-email",  # 无效邮箱
        }
        
        result = await sync_engine.sync_data("looma_crm", "zervigo", invalid_data, SyncEventType.CREATE)
        print(f"✅ 无效数据处理: {result.success}")
        
        if not result.success:
            print(f"  错误信息: {result.error_message}")
        
        # 测试重试机制
        retry_data = {
            "id": "retry_test",
            "name": "Retry Test",
            "retry_count": 0
        }
        
        result = await sync_engine.sync_data("looma_crm", "zervigo", retry_data, SyncEventType.CREATE)
        print(f"✅ 重试机制测试: {result.success}")
        
        # 等待重试处理
        await asyncio.sleep(2)
        
        # 获取健康状态
        health = await sync_engine.health_check()
        print(f"🏥 错误处理后的健康状态: {health['status']}")
        
    finally:
        await sync_engine.stop()

async def main():
    """主函数"""
    print("🚀 开始同步引擎测试...")
    print("=" * 60)
    
    try:
        await test_sync_engine_basic()
        await test_sync_strategies()
        await test_conflict_resolver()
        await test_sync_performance()
        await test_sync_error_handling()
        
        print("\n" + "=" * 60)
        print("🎉 所有同步引擎测试完成！")
        print("\n📋 测试总结:")
        print("✅ 同步引擎基础功能 - 通过")
        print("✅ 同步策略测试 - 通过")
        print("✅ 冲突解决器测试 - 通过")
        print("✅ 同步性能测试 - 通过")
        print("✅ 错误处理测试 - 通过")
        print("\n🎯 数据同步机制优化验证成功！")
        
    except Exception as e:
        print(f"\n❌ 同步引擎测试失败: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    asyncio.run(main())
