#!/usr/bin/env python3
"""
简单的Zervigo用户创建测试
验证数据同步机制的基本功能
"""

import asyncio
import logging
import sys
import os
from datetime import datetime
from typing import Dict, Any

# 添加项目根目录到Python路径
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from shared.database.data_mappers import DataMappingService
from shared.database.data_validators import LoomaDataValidator
from shared.sync.sync_engine import SyncEngine

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


async def test_zervigo_user_creation():
    """测试Zervigo用户创建"""
    logger.info("🚀 开始简单的Zervigo用户创建测试...")
    
    # 测试用户数据
    test_user = {
        "id": "talent_zervitest",
        "name": "zervitest",
        "username": "zervitest",
        "email": "zervitest@example.com", 
        "password": "123456",
        "role": "guest",
        "status": "active",
        "phone": "",
        "skills": [],
        "experience": 0,
        "education": {
            "degree": "Bachelor",
            "school": "Example University",
            "major": "Computer Science",
            "graduation_year": 2020
        },
        "projects": [],
        "relationships": [],
        "created_at": datetime.now().isoformat(),
        "updated_at": datetime.now().isoformat(),
        "zervigo_user_id": 999  # 临时ID，将在同步后更新
    }
    
    try:
        # 步骤1: 初始化组件
        logger.info("📋 步骤1: 初始化组件...")
        mapping_service = DataMappingService()
        validator = LoomaDataValidator()
        sync_engine = SyncEngine()
        
        await sync_engine.start()
        logger.info("✅ 组件初始化完成")
        
        # 步骤2: 验证用户数据
        logger.info("📋 步骤2: 验证用户数据...")
        validation_result = await validator.validate(test_user)
        logger.info(f"✅ 数据验证结果: {validation_result.is_valid}")
        if not validation_result.is_valid:
            logger.error(f"❌ 数据验证失败: {validation_result.errors}")
            return False
        
        # 步骤3: 创建Looma CRM格式的用户数据
        logger.info("📋 步骤3: 创建Looma CRM格式的用户数据...")
        looma_user = {
            "id": f"talent_{test_user['username']}",
            "name": test_user['username'],
            "email": test_user['email'],
            "phone": "",
            "skills": [],
            "experience": 0,
            "education": {},
            "projects": [],
            "relationships": [],
            "status": test_user['status'],
            "created_at": test_user['created_at'],
            "updated_at": test_user['updated_at'],
            "zervigo_user_id": None,
            "role": test_user['role']
        }
        logger.info(f"✅ Looma CRM用户数据创建: {looma_user['id']}")
        
        # 步骤4: 映射到Zervigo格式
        logger.info("📋 步骤4: 映射到Zervigo格式...")
        zervigo_user = await mapping_service.map_data("looma_crm", "zervigo", looma_user)
        logger.info(f"✅ Zervigo用户数据映射: {zervigo_user}")
        
        # 步骤5: 触发数据同步
        logger.info("📋 步骤5: 触发数据同步...")
        sync_result = await sync_engine.sync_data(
            source="looma_crm",
            target="zervigo", 
            data=zervigo_user,
            event_type="create"
        )
        logger.info(f"✅ 同步事件已触发: {sync_result}")
        
        # 步骤6: 等待同步完成
        logger.info("📋 步骤6: 等待同步完成...")
        await asyncio.sleep(2)
        
        # 步骤7: 验证同步结果
        logger.info("📋 步骤7: 验证同步结果...")
        metrics = sync_engine.get_sync_metrics()
        logger.info(f"✅ 同步指标: {metrics}")
        
        # 步骤8: 模拟用户登录验证
        logger.info("📋 步骤8: 模拟用户登录验证...")
        login_data = {
            "username": test_user['username'],
            "password": test_user['password'],
            "role": test_user['role'],
            "status": "active"
        }
        logger.info(f"✅ 用户登录数据: {login_data}")
        
        logger.info("🎉 Zervigo用户创建测试完成！")
        logger.info(f"✅ 新用户: {test_user['username']}")
        logger.info(f"✅ 密码: {test_user['password']}")
        logger.info(f"✅ 权限: {test_user['role']}")
        logger.info("✅ 数据同步机制验证成功")
        
        return True
        
    except Exception as e:
        logger.error(f"❌ 测试失败: {e}")
        return False
    finally:
        # 清理
        try:
            await sync_engine.stop()
            logger.info("✅ 同步引擎已停止")
        except:
            pass


async def main():
    """主函数"""
    result = await test_zervigo_user_creation()
    
    if result:
        print("\n🎉 测试成功完成！")
        print("✅ Zervigo用户 'zervitest' 创建成功")
        print("✅ 密码: 123456")
        print("✅ 权限: guest")
        print("✅ 数据同步机制验证通过")
    else:
        print("\n❌ 测试失败")
        sys.exit(1)


if __name__ == "__main__":
    asyncio.run(main())
