#!/bin/bash
# AI身份社交网络日志查看脚本

echo "📄 AI身份社交网络日志查看"
echo "=========================="

# 检查日志文件是否存在
check_log_file() {
    local log_file=$1
    local service_name=$2
    
    if [ -f "$log_file" ]; then
        echo "✅ $service_name 日志文件存在: $log_file"
        return 0
    else
        echo "❌ $service_name 日志文件不存在: $log_file"
        return 1
    fi
}

# 显示日志文件信息
show_log_info() {
    local log_file=$1
    local service_name=$2
    
    if [ -f "$log_file" ]; then
        echo ""
        echo "📊 $service_name 日志信息:"
        echo "   文件大小: $(ls -lh "$log_file" | awk '{print $5}')"
        echo "   最后修改: $(ls -l "$log_file" | awk '{print $6, $7, $8}')"
        echo "   最后10行:"
        tail -10 "$log_file" | sed 's/^/   /'
    fi
}

echo "🔍 检查日志文件..."
echo "-------------------"

# 检查LoomaCRM Future日志
check_log_file "looma_crm_future/logs/ai-identity-network.log" "LoomaCRM Future"

# 检查AI服务日志
check_log_file "looma_crm_future/services/ai_services_independent/logs/ai_gateway.log" "AI网关服务"
check_log_file "looma_crm_future/services/ai_services_independent/logs/resume_ai.log" "简历AI服务"
check_log_file "looma_crm_future/services/ai_services_independent/logs/dual_ai_collaboration.log" "双AI协作"

# 检查Zervigo Future日志
check_log_file "zervigo_future/logs/zervigo.log" "Zervigo Future"

# 检查Docker容器日志
echo ""
echo "🐳 Docker容器日志:"
echo "-------------------"
if command -v docker &> /dev/null; then
    echo "📊 运行中的容器:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(future|looma|zervigo)"
    
    echo ""
    echo "📄 容器日志查看命令:"
    echo "   LoomaCRM Future: docker logs future-looma-crm"
    echo "   AI网关: docker logs future-ai-gateway"
    echo "   简历AI: docker logs future-resume-ai"
    echo "   MinerU: docker logs future-mineru"
    echo "   AI模型: docker logs future-ai-models"
    echo "   PostgreSQL: docker logs future-postgres"
    echo "   MongoDB: docker logs future-mongodb"
    echo "   Redis: docker logs future-redis"
    echo "   Neo4j: docker logs future-neo4j"
    echo "   Elasticsearch: docker logs future-elasticsearch"
    echo "   Weaviate: docker logs future-weaviate"
else
    echo "❌ Docker未安装或未运行"
fi

# 显示详细日志信息
echo ""
echo "📊 详细日志信息:"
echo "-------------------"

show_log_info "looma_crm_future/logs/ai-identity-network.log" "LoomaCRM Future"
show_log_info "looma_crm_future/services/ai_services_independent/logs/ai_gateway.log" "AI网关服务"
show_log_info "looma_crm_future/services/ai_services_independent/logs/resume_ai.log" "简历AI服务"
show_log_info "looma_crm_future/services/ai_services_independent/logs/dual_ai_collaboration.log" "双AI协作"

echo ""
echo "🔧 实时日志查看命令:"
echo "-------------------"
echo "   LoomaCRM Future: tail -f looma_crm_future/logs/ai-identity-network.log"
echo "   AI网关服务: tail -f looma_crm_future/services/ai_services_independent/logs/ai_gateway.log"
echo "   简历AI服务: tail -f looma_crm_future/services/ai_services_independent/logs/resume_ai.log"
echo "   双AI协作: tail -f looma_crm_future/services/ai_services_independent/logs/dual_ai_collaboration.log"
echo "   Zervigo Future: tail -f zervigo_future/logs/zervigo.log"

echo ""
echo "📄 日志查看完成！"
echo "=========================="
