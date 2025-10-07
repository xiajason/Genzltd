#!/bin/bash

# AI服务健康管理和认证监控脚本
# 专门用于监控AI服务的认证状态、使用限制、成本控制等

set -e

AI_SERVICE_HOST="localhost"
AI_SERVICE_PORT="8206"
AI_SERVICE_URL="http://${AI_SERVICE_HOST}:${AI_SERVICE_PORT}"

echo "=== AI服务健康管理和认证监控 ==="
echo "时间: $(date)"
echo "AI服务地址: ${AI_SERVICE_URL}"
echo ""

# 1. 检查AI服务基础健康状态
echo "1. AI服务基础健康检查:"
if curl -s ${AI_SERVICE_URL}/health > /dev/null; then
    HEALTH_RESPONSE=$(curl -s ${AI_SERVICE_URL}/health)
    echo "   ✅ AI服务运行正常"
    echo "   📊 健康状态: $(echo $HEALTH_RESPONSE | jq -r '.status')"
    echo "   🕐 时间戳: $(echo $HEALTH_RESPONSE | jq -r '.timestamp')"
else
    echo "   ❌ AI服务无法访问"
    exit 1
fi

# 2. 检查AI服务认证机制
echo -e "\n2. AI服务认证机制检查:"
echo "   🔐 检查JWT认证中间件..."
# 测试未认证请求
UNAUTH_RESPONSE=$(curl -s -w "%{http_code}" -o /dev/null ${AI_SERVICE_URL}/api/v1/analyze/resume -X POST -H "Content-Type: application/json" -d '{"test": "data"}')
if [ "$UNAUTH_RESPONSE" = "401" ] || [ "$UNAUTH_RESPONSE" = "403" ]; then
    echo "   ✅ 认证机制正常工作 (HTTP $UNAUTH_RESPONSE)"
else
    echo "   ⚠️  认证机制可能存在问题 (HTTP $UNAUTH_RESPONSE)"
fi

# 3. 检查AI服务使用限制
echo -e "\n3. AI服务使用限制检查:"
echo "   💰 检查用户使用限制..."
# 这里需要调用User Service检查使用限制
USER_SERVICE_URL="http://localhost:8081"
if curl -s ${USER_SERVICE_URL}/health > /dev/null; then
    echo "   ✅ User Service可访问，可以检查使用限制"
    # 检查使用限制API
    USAGE_CHECK_RESPONSE=$(curl -s -w "%{http_code}" -o /dev/null ${USER_SERVICE_URL}/api/v1/usage/check -X POST -H "Content-Type: application/json" -d '{"user_id": 1, "service_type": "ai_analysis"}')
    if [ "$USAGE_CHECK_RESPONSE" = "200" ]; then
        echo "   ✅ 使用限制检查API正常"
    else
        echo "   ⚠️  使用限制检查API异常 (HTTP $USAGE_CHECK_RESPONSE)"
    fi
else
    echo "   ❌ User Service不可访问，无法检查使用限制"
fi

# 4. 检查AI服务成本控制
echo -e "\n4. AI服务成本控制检查:"
echo "   💸 检查成本控制机制..."
# 检查AI服务是否有成本控制中间件
COST_CONTROL_RESPONSE=$(curl -s -w "%{http_code}" -o /dev/null ${AI_SERVICE_URL}/api/v1/usage/check -X POST -H "Content-Type: application/json" -d '{"user_id": 1, "service_type": "ai_analysis"}')
if [ "$COST_CONTROL_RESPONSE" = "200" ] || [ "$COST_CONTROL_RESPONSE" = "429" ]; then
    echo "   ✅ 成本控制机制正常"
else
    echo "   ⚠️  成本控制机制可能存在问题 (HTTP $COST_CONTROL_RESPONSE)"
fi

# 5. 检查AI服务外部依赖
echo -e "\n5. AI服务外部依赖检查:"
echo "   🤖 检查Ollama服务..."
OLLAMA_HOST="http://127.0.0.1:11434"
if curl -s ${OLLAMA_HOST}/api/tags > /dev/null; then
    echo "   ✅ Ollama服务正常"
    # 检查模型状态
    MODELS=$(curl -s ${OLLAMA_HOST}/api/tags | jq -r '.models[].name' | head -3)
    echo "   📋 可用模型: $MODELS"
else
    echo "   ❌ Ollama服务不可访问"
fi

echo "   🌐 检查DeepSeek API..."
# 检查DeepSeek API配置（不实际调用，避免费用）
DEEPSEEK_CONFIG=$(curl -s ${AI_SERVICE_URL}/health | jq -r '.deepseek_configured // "unknown"')
if [ "$DEEPSEEK_CONFIG" != "unknown" ]; then
    echo "   ✅ DeepSeek API配置正常"
else
    echo "   ⚠️  DeepSeek API配置状态未知"
fi

# 6. 检查AI服务数据库连接
echo -e "\n6. AI服务数据库连接检查:"
echo "   🗄️  检查PostgreSQL连接..."
# 通过AI服务健康检查间接验证数据库连接
DB_STATUS=$(curl -s ${AI_SERVICE_URL}/health | jq -r '.database_status // "unknown"')
if [ "$DB_STATUS" = "connected" ] || [ "$DB_STATUS" = "healthy" ]; then
    echo "   ✅ PostgreSQL连接正常"
else
    echo "   ⚠️  PostgreSQL连接状态: $DB_STATUS"
fi

# 7. 检查AI服务性能指标
echo -e "\n7. AI服务性能指标检查:"
echo "   ⚡ 检查响应时间..."
RESPONSE_TIME=$(curl -s -w "%{time_total}" -o /dev/null ${AI_SERVICE_URL}/health)
echo "   📊 健康检查响应时间: ${RESPONSE_TIME}s"

# 检查AI服务进程资源使用
AI_PROCESS=$(ps aux | grep "python.*ai_service" | grep -v grep | head -1)
if [ -n "$AI_PROCESS" ]; then
    CPU_USAGE=$(echo $AI_PROCESS | awk '{print $3}')
    MEMORY_USAGE=$(echo $AI_PROCESS | awk '{print $4}')
    echo "   💻 CPU使用率: ${CPU_USAGE}%"
    echo "   🧠 内存使用率: ${MEMORY_USAGE}%"
else
    echo "   ❌ 未找到AI服务进程"
fi

# 8. 检查AI服务Consul注册状态
echo -e "\n8. AI服务Consul注册状态:"
CONSUL_URL="http://localhost:8500"
if curl -s ${CONSUL_URL}/v1/status/leader > /dev/null; then
    AI_SERVICE_INFO=$(curl -s ${CONSUL_URL}/v1/agent/services | jq '.["ai-service-1"]')
    if [ "$AI_SERVICE_INFO" != "null" ]; then
        echo "   ✅ AI服务已注册到Consul"
        echo "   🏷️  服务标签: $(echo $AI_SERVICE_INFO | jq -r '.Tags | join(", ")')"
        echo "   🔌 服务端口: $(echo $AI_SERVICE_INFO | jq -r '.Port')"
    else
        echo "   ❌ AI服务未注册到Consul"
    fi
else
    echo "   ❌ Consul服务不可访问"
fi

# 9. 检查AI服务日志
echo -e "\n9. AI服务日志检查:"
AI_LOG_DIR="/Users/szjason72/zervi-basic/basic/backend/internal/ai-service"
if [ -d "$AI_LOG_DIR" ]; then
    echo "   📁 AI服务目录: $AI_LOG_DIR"
    # 检查最近的错误日志
    if [ -f "$AI_LOG_DIR/ai_service.log" ]; then
        ERROR_COUNT=$(tail -100 "$AI_LOG_DIR/ai_service.log" | grep -i "error" | wc -l)
        echo "   ⚠️  最近100行日志中的错误数: $ERROR_COUNT"
    else
        echo "   📝 日志文件不存在或无法访问"
    fi
else
    echo "   ❌ AI服务目录不存在"
fi

# 10. AI服务特殊功能检查
echo -e "\n10. AI服务特殊功能检查:"
echo "   🔍 检查简历分析功能..."
RESUME_ANALYSIS_RESPONSE=$(curl -s -w "%{http_code}" -o /dev/null ${AI_SERVICE_URL}/api/v1/analyze/resume -X POST -H "Content-Type: application/json" -d '{"test": "unauthorized"}')
echo "   📊 简历分析API状态: HTTP $RESUME_ANALYSIS_RESPONSE"

echo "   🔍 检查向量搜索功能..."
VECTOR_SEARCH_RESPONSE=$(curl -s -w "%{http_code}" -o /dev/null ${AI_SERVICE_URL}/api/v1/vectors/search -X POST -H "Content-Type: application/json" -d '{"test": "unauthorized"}')
echo "   📊 向量搜索API状态: HTTP $VECTOR_SEARCH_RESPONSE"

# 11. 成本控制建议
echo -e "\n11. 成本控制建议:"
echo "   💡 建议检查项目:"
echo "   - 用户认证状态和权限"
echo "   - 每日/每月使用限制"
echo "   - AI模型调用成本"
echo "   - 外部API使用费用"
echo "   - 缓存命中率优化"

echo -e "\n=== AI服务监控完成 ==="
echo "💡 提示: AI服务需要特殊关注认证和成本控制"
echo "🔐 确保所有AI API都经过用户认证"
echo "💰 监控AI服务的使用成本和限制"
echo "📊 定期检查外部AI API的可用性和费用"
