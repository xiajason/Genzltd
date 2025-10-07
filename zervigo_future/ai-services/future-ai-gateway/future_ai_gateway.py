#!/usr/bin/env python3
"""
JobFirst Future版 AI Gateway服务
适配Future版端口配置 (7510)
"""

import logging
from datetime import datetime
from sanic import Sanic
from sanic.response import json as sanic_response

# 配置日志
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Future版配置
FUTURE_CONFIG = {
    "service_name": "future-ai-gateway",
    "version": "1.0.0",
    "port": 7510,
    "host": "0.0.0.0",
    "environment": "future"
}

# 创建Sanic应用
app = Sanic("future_ai_gateway")

@app.route("/health", methods=["GET"])
async def health_check(request):
    """健康检查端点"""
    return sanic_response({
        "service": "future-ai-gateway",
        "version": FUTURE_CONFIG["version"],
        "environment": FUTURE_CONFIG["environment"],
        "status": "healthy",
        "timestamp": datetime.now().isoformat()
    })

@app.route("/api/v1/info", methods=["GET"])
async def service_info(request):
    """服务信息端点"""
    return sanic_response({
        "service": "future-ai-gateway",
        "description": "JobFirst Future版 AI Gateway服务",
        "version": FUTURE_CONFIG["version"],
        "environment": FUTURE_CONFIG["environment"]
    })

if __name__ == "__main__":
    logger.info(f"启动Future AI Gateway服务...")
    app.run(
        host=FUTURE_CONFIG["host"],
        port=FUTURE_CONFIG["port"],
        debug=True,
        workers=1
    )
