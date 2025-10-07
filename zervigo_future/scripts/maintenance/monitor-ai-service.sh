#!/bin/bash

# JobFirst AI服务监控脚本

echo "=== JobFirst AI服务监控 ==="
echo "时间: $(date)"
echo

# 检查AI服务进程
echo "1. 检查AI服务进程:"
AI_PID=$(ps aux | grep ai_service_deepseek.py | grep -v grep | awk '{print $2}')
if [ -n "$AI_PID" ]; then
    echo "✅ AI服务正在运行 (PID: $AI_PID)"
else
    echo "❌ AI服务未运行"
fi
echo

# 检查端口监听
echo "2. 检查端口监听:"
if netstat -tlnp | grep -q ":8206"; then
    echo "✅ 端口8206正在监听"
else
    echo "❌ 端口8206未监听"
fi
echo

# 测试健康检查
echo "3. 测试健康检查:"
HEALTH_RESPONSE=$(curl -s http://localhost:8206/health)
if echo "$HEALTH_RESPONSE" | grep -q "healthy"; then
    echo "✅ 健康检查正常"
    echo "响应: $HEALTH_RESPONSE"
else
    echo "❌ 健康检查失败"
    echo "响应: $HEALTH_RESPONSE"
fi
echo

# 测试功能列表
echo "4. 测试功能列表:"
FEATURES_RESPONSE=$(curl -s http://localhost:8206/api/v1/ai/features)
if echo "$FEATURES_RESPONSE" | grep -q "success"; then
    echo "✅ 功能列表正常"
    echo "功能数量: $(echo "$FEATURES_RESPONSE" | jq '.data | length' 2>/dev/null || echo '无法解析')"
else
    echo "❌ 功能列表失败"
fi
echo

# 检查系统资源
echo "5. 系统资源使用:"
echo "内存使用:"
free -h | grep -E "(Mem|Swap)"
echo
echo "CPU使用:"
top -bn1 | grep "Cpu(s)" | head -1
echo

# 检查网络连接
echo "6. 网络连接测试:"
if curl -s --connect-timeout 5 https://api.deepseek.com/health > /dev/null; then
    echo "✅ DeepSeek API连接正常"
else
    echo "❌ DeepSeek API连接失败"
fi
echo

# 检查日志文件
echo "7. 检查日志文件:"
LOG_FILE="/opt/jobfirst/backend/internal/ai-service/ai_service_deepseek.log"
if [ -f "$LOG_FILE" ]; then
    echo "✅ 日志文件存在"
    echo "日志大小: $(du -h "$LOG_FILE" | cut -f1)"
    echo "最后10行日志:"
    tail -5 "$LOG_FILE" 2>/dev/null || echo "无法读取日志"
else
    echo "⚠️ 日志文件不存在"
fi
echo

echo "=== 监控完成 ==="
