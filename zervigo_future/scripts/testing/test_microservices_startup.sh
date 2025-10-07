#!/bin/bash

# JobFirst 微服务启动测试脚本
# 验证所有微服务启动是否正常

set -e  # 遇到错误立即退出

echo "=== JobFirst 微服务启动测试开始 ==="
echo "时间: $(date)"
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 测试结果统计
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# 服务端口配置（简化版本）
# basic-server: 8080
# api-gateway: 8081
# user-service: 8082
# resume-service: 8083
# company-service: 8084
# banner-service: 8085
# template-service: 8086
# notification-service: 8087
# statistics-service: 8088
# ai-service: 8206

# 测试函数
test_service() {
    local service_name=$1
    local port=$2
    local start_command=$3
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -n "测试 $service_name (端口:$port): "
    
    # 检查端口是否被占用
    if lsof -i :$port >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  端口已被占用${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
    
    # 启动服务（后台运行）
    echo "启动中..."
    if eval "$start_command" >/dev/null 2>&1 & then
        local pid=$!
        sleep 3  # 等待服务启动
        
        # 检查服务是否启动成功
        if lsof -i :$port >/dev/null 2>&1; then
            echo -e "${GREEN}✅ 启动成功 (PID: $pid)${NC}"
            PASSED_TESTS=$((PASSED_TESTS + 1))
            
            # 测试健康检查
            if curl -s http://localhost:$port/health >/dev/null 2>&1; then
                echo "  ✅ 健康检查通过"
            else
                echo "  ⚠️  健康检查失败"
            fi
            
            # 停止服务
            kill $pid 2>/dev/null || true
            sleep 1
            return 0
        else
            echo -e "${RED}❌ 启动失败${NC}"
            kill $pid 2>/dev/null || true
            FAILED_TESTS=$((FAILED_TESTS + 1))
            return 1
        fi
    else
        echo -e "${RED}❌ 启动命令失败${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
}

# 1. 基础设施服务测试
echo "1. 基础设施服务启动测试"
echo "========================"

# Basic Server测试
echo "测试 Basic Server:"
cd /Users/szjason72/zervi-basic/basic/backend/cmd/basic-server
if [ -f "main.go" ]; then
    test_service "basic-server" "8080" "go run main.go"
else
    echo -e "Basic Server: ${RED}❌ main.go文件不存在${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
fi

echo ""

# 2. 微服务启动测试
echo "2. 微服务启动测试"
echo "=================="

# Resume Service测试
echo "测试 Resume Service:"
cd /Users/szjason72/zervi-basic/basic/backend/internal/resume
if [ -f "main.go" ]; then
    test_service "resume-service" "8083" "go run main.go"
else
    echo -e "Resume Service: ${RED}❌ main.go文件不存在${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
fi

# Banner Service测试
echo "测试 Banner Service:"
cd /Users/szjason72/zervi-basic/basic/backend/internal/banner-service
if [ -f "main.go" ]; then
    test_service "banner-service" "8085" "go run main.go"
else
    echo -e "Banner Service: ${RED}❌ main.go文件不存在${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
fi

# Company Service测试
echo "测试 Company Service:"
cd /Users/szjason72/zervi-basic/basic/backend/internal/company-service
if [ -f "main.go" ]; then
    test_service "company-service" "8084" "go run main.go"
else
    echo -e "Company Service: ${RED}❌ main.go文件不存在${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
fi

# Template Service测试
echo "测试 Template Service:"
cd /Users/szjason72/zervi-basic/basic/backend/internal/template-service
if [ -f "main.go" ]; then
    test_service "template-service" "8086" "go run main.go"
else
    echo -e "Template Service: ${RED}❌ main.go文件不存在${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
fi

# Notification Service测试
echo "测试 Notification Service:"
cd /Users/szjason72/zervi-basic/basic/backend/internal/notification-service
if [ -f "main.go" ]; then
    test_service "notification-service" "8087" "go run main.go"
else
    echo -e "Notification Service: ${RED}❌ main.go文件不存在${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
fi

# Statistics Service测试
echo "测试 Statistics Service:"
cd /Users/szjason72/zervi-basic/basic/backend/internal/statistics-service
if [ -f "main.go" ]; then
    test_service "statistics-service" "8088" "go run main.go"
else
    echo -e "Statistics Service: ${RED}❌ main.go文件不存在${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
fi

echo ""

# 3. AI Service测试
echo "3. AI Service启动测试"
echo "====================="

echo "测试 AI Service:"
cd /Users/szjason72/zervi-basic/basic/backend/internal/ai-service
if [ -f "ai_service.py" ]; then
    # 检查Python虚拟环境
    if [ -d "venv" ]; then
        test_service "ai-service" "8206" "source venv/bin/activate && python ai_service.py"
    else
        echo -e "AI Service: ${RED}❌ Python虚拟环境不存在${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        TOTAL_TESTS=$((TOTAL_TESTS + 1))
    fi
else
    echo -e "AI Service: ${RED}❌ ai_service.py文件不存在${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
fi

echo ""

# 4. 服务发现测试
echo "4. 服务发现测试"
echo "================"

# 检查Consul服务
echo "检查Consul服务:"
if curl -s http://localhost:8500/v1/status/leader >/dev/null 2>&1; then
    echo -e "Consul服务: ${GREEN}✅ 运行正常${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    echo -e "Consul服务: ${RED}❌ 未运行或无法访问${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))

echo ""

# 5. 测试结果汇总
echo "5. 测试结果汇总"
echo "================"
echo "总测试数: $TOTAL_TESTS"
echo -e "通过测试: ${GREEN}$PASSED_TESTS${NC}"
echo -e "失败测试: ${RED}$FAILED_TESTS${NC}"

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "\n${GREEN}🎉 所有微服务启动测试通过！${NC}"
    exit 0
else
    echo -e "\n${RED}❌ 有 $FAILED_TESTS 个测试失败，请检查服务配置${NC}"
    exit 1
fi
