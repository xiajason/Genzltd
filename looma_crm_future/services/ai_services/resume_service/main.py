#!/usr/bin/env python3
"""
简历AI服务启动文件
"""

import asyncio
import logging
import os
import sys
from pathlib import Path

# 添加项目根目录到Python路径
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from ai_services.resume_service.resume_ai_service import ResumeAIService

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# 创建简历AI服务实例 - 用于Sanic命令行启动
resume_ai_service = ResumeAIService(port=int(os.getenv('RESUME_AI_SERVICE_PORT', 7511)))


async def main():
    """主函数"""
    try:
        # 获取端口配置 - Future版本使用7511端口
        port = int(os.getenv('RESUME_AI_SERVICE_PORT', 7511))
        
        logger.info(f"启动简历AI服务，端口: {port}")
        
        # 启动服务
        await resume_ai_service.start()
        
    except KeyboardInterrupt:
        logger.info("收到中断信号，正在停止简历AI服务...")
    except Exception as e:
        logger.error(f"简历AI服务启动失败: {e}")
        sys.exit(1)


if __name__ == "__main__":
    asyncio.run(main())
