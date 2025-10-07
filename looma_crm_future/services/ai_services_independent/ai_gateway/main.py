#!/usr/bin/env python3
"""
AI网关服务启动文件
"""

import asyncio
import logging
import os
import sys
from pathlib import Path

# 添加项目根目录到Python路径
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from ai_services.ai_gateway.ai_gateway import AIGateway

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


async def main():
    """主函数"""
    try:
        # 获取端口配置
        port = int(os.getenv('AI_GATEWAY_PORT', 8206))
        
        # 创建AI网关实例
        ai_gateway = AIGateway(port=port)
        
        logger.info(f"启动AI网关服务，端口: {port}")
        
        # 启动服务
        await ai_gateway.start()
        
    except KeyboardInterrupt:
        logger.info("收到中断信号，正在停止AI网关服务...")
    except Exception as e:
        logger.error(f"AI网关服务启动失败: {e}")
        sys.exit(1)


if __name__ == "__main__":
    asyncio.run(main())
