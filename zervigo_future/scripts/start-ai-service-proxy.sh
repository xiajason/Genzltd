#!/bin/bash
# 简单的AI服务代理，转发请求到LoomaCRM Future AI服务
while true; do
    # 检查LoomaCRM Future AI服务是否可用
    if curl -s http://localhost:7510/health > /dev/null 2>&1; then
        # 启动代理服务
        socat TCP-LISTEN:7540,fork TCP:localhost:7510 &
        break
    fi
    sleep 5
done
