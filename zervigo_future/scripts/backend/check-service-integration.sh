#!/bin/bash

# JobFirst Core集成状态检查脚本
# 检查各微服务的jobfirst-core集成情况

echo "🔍 检查JobFirst Core集成状态..."
echo "=================================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 检查函数
check_service() {
    local service_name=$1
    local service_path=$2
    local port=$3
    
    echo -e "\n${BLUE}📋 检查 $service_name${NC}"
    echo "路径: $service_path"
    echo "端口: $port"
    
    # 检查main.go文件
    if [ -f "$service_path/main.go" ]; then
        if grep -q "jobfirst.*core\|jobfirst-core" "$service_path/main.go"; then
            echo -e "${GREEN}✅ main.go 已集成 jobfirst-core${NC}"
        else
            echo -e "${RED}❌ main.go 未集成 jobfirst-core${NC}"
        fi
    else
        echo -e "${RED}❌ main.go 文件不存在${NC}"
    fi
    
    # 检查main_core.go文件
    if [ -f "$service_path/main_core.go" ]; then
        echo -e "${YELLOW}⚠️  发现 main_core.go 文件${NC}"
        if grep -q "jobfirst.*core\|jobfirst-core" "$service_path/main_core.go"; then
            echo -e "${GREEN}✅ main_core.go 已集成 jobfirst-core${NC}"
        else
            echo -e "${RED}❌ main_core.go 未集成 jobfirst-core${NC}"
        fi
    fi
    
    # 检查go.mod文件
    if [ -f "$service_path/go.mod" ]; then
        if grep -q "jobfirst-core" "$service_path/go.mod"; then
            echo -e "${GREEN}✅ go.mod 包含 jobfirst-core 依赖${NC}"
        else
            echo -e "${RED}❌ go.mod 缺少 jobfirst-core 依赖${NC}"
        fi
    fi
    
    # 检查服务是否运行
    if curl -s "http://localhost:$port/health" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ 服务正在运行 (端口 $port)${NC}"
        
        # 检查健康检查响应
        health_response=$(curl -s "http://localhost:$port/health")
        if echo "$health_response" | grep -q "core_health\|jobfirst"; then
            echo -e "${GREEN}✅ 健康检查显示 jobfirst-core 集成${NC}"
        else
            echo -e "${YELLOW}⚠️  健康检查未显示 jobfirst-core 信息${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  服务未运行 (端口 $port)${NC}"
    fi
}

# 检查AI服务
check_ai_service() {
    echo -e "\n${BLUE}📋 检查 AI Service${NC}"
    echo "路径: basic/backend/internal/ai-service"
    echo "端口: 8206"
    
    if [ -f "basic/backend/internal/ai-service/ai_service.py" ]; then
        if grep -q "jobfirst.*core\|jobfirst-core" "basic/backend/internal/ai-service/ai_service.py"; then
            echo -e "${GREEN}✅ Python服务已集成 jobfirst-core${NC}"
        else
            echo -e "${RED}❌ Python服务未集成 jobfirst-core${NC}"
        fi
        
        # 检查是否有Python的jobfirst-core包
        if [ -f "basic/backend/internal/ai-service/requirements.txt" ]; then
            if grep -q "jobfirst-core" "basic/backend/internal/ai-service/requirements.txt"; then
                echo -e "${GREEN}✅ requirements.txt 包含 jobfirst-core${NC}"
            else
                echo -e "${RED}❌ requirements.txt 缺少 jobfirst-core${NC}"
            fi
        fi
    else
        echo -e "${RED}❌ ai_service.py 文件不存在${NC}"
    fi
    
    # 检查AI服务是否运行
    if curl -s "http://localhost:8206/health" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ AI服务正在运行${NC}"
    else
        echo -e "${YELLOW}⚠️  AI服务未运行${NC}"
    fi
}

# 主检查逻辑
echo "开始检查各微服务..."

# 检查Go微服务
check_service "User Service" "basic/backend/internal/user" "8081"
check_service "Resume Service" "basic/backend/internal/resume" "8082"
check_service "Company Service" "basic/backend/internal/company-service" "8083"
check_service "Notification Service" "basic/backend/internal/notification-service" "8084"
check_service "Template Service" "basic/backend/internal/template-service" "8085"
check_service "Statistics Service" "basic/backend/internal/statistics-service" "8086"
check_service "Banner Service" "basic/backend/internal/banner-service" "8087"
check_service "Dev Team Service" "basic/backend/internal/dev-team-service" "8088"

# 检查AI服务
check_ai_service

echo -e "\n${BLUE}=================================="
echo "🎯 集成状态总结"
echo "=================================="

# 统计集成状态
total_services=9
integrated_services=0

# 重新检查集成状态并统计
services=(
    "User Service:basic/backend/internal/user:8081"
    "Resume Service:basic/backend/internal/resume:8082"
    "Company Service:basic/backend/internal/company-service:8083"
    "Notification Service:basic/backend/internal/notification-service:8084"
    "Template Service:basic/backend/internal/template-service:8085"
    "Statistics Service:basic/backend/internal/statistics-service:8086"
    "Banner Service:basic/backend/internal/banner-service:8087"
    "Dev Team Service:basic/backend/internal/dev-team-service:8088"
    "AI Service:basic/backend/internal/ai-service:8206"
)

for service_info in "${services[@]}"; do
    IFS=':' read -r name path port <<< "$service_info"
    
    if [ "$name" = "AI Service" ]; then
        # AI服务的特殊检查
        if [ -f "$path/ai_service.py" ] && grep -q "jobfirst.*core\|jobfirst-core" "$path/ai_service.py"; then
            integrated_services=$((integrated_services + 1))
        fi
    else
        # Go服务的检查
        if [ -f "$path/main.go" ] && grep -q "jobfirst.*core\|jobfirst-core" "$path/main.go"; then
            integrated_services=$((integrated_services + 1))
        fi
    fi
done

integration_percentage=$((integrated_services * 100 / total_services))

echo -e "${GREEN}✅ 已集成服务: $integrated_services/$total_services${NC}"
echo -e "${BLUE}📊 集成完成度: ${integration_percentage}%${NC}"

if [ $integration_percentage -ge 80 ]; then
    echo -e "${GREEN}🎉 集成状态良好！${NC}"
elif [ $integration_percentage -ge 60 ]; then
    echo -e "${YELLOW}⚠️  集成状态中等，需要继续改进${NC}"
else
    echo -e "${RED}❌ 集成状态较差，需要大量工作${NC}"
fi

echo -e "\n${BLUE}📋 下一步建议:${NC}"
echo "1. 修复未集成的服务"
echo "2. 验证已集成服务的功能"
echo "3. 进行端到端测试"
echo "4. 更新文档"

echo -e "\n✅ 检查完成！"
