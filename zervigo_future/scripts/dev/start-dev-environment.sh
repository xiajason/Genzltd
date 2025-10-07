#!/bin/bash

# JobFirst 开发环境启动脚本
# 支持热加载的微服务开发环境

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 服务端口定义 (符合联邦架构规划)
API_GATEWAY_PORT=8601
USER_SERVICE_PORT=8602
RESUME_SERVICE_PORT=8603
COMPANY_SERVICE_PORT=8604
NOTIFICATION_SERVICE_PORT=8605
STATISTICS_SERVICE_PORT=8606
MULTI_DATABASE_SERVICE_PORT=8607
JOB_SERVICE_PORT=8609
TEMPLATE_SERVICE_PORT=8611
BANNER_SERVICE_PORT=8612
DEV_TEAM_SERVICE_PORT=8613
AI_SERVICE_PORT=8620

MYSQL_PORT=3306
POSTGRES_PORT=5432
REDIS_PORT=6379
NEO4J_PORT=7474

# 检查端口是否被占用
check_port() {
    lsof -i :$1 >/dev/null 2>&1
    return $?
}

# 检查服务是否运行
check_service() {
    local service_name=$1
    local port=$2
    if check_port $port; then
        echo -e "${GREEN}[SUCCESS] $service_name 已在端口 $port 运行${NC}"
        return 0
    else
        echo -e "${RED}[ERROR] $service_name 未在端口 $port 运行${NC}"
        return 1
    fi
}

# 启动数据库服务
start_databases() {
    echo -e "${BLUE}[INFO] === 启动数据库服务 ===${NC}"
    
    # MySQL
    if check_port $MYSQL_PORT; then
        echo -e "${YELLOW}[WARNING] MySQL 已在端口 $MYSQL_PORT 运行${NC}"
    else
        echo -e "${BLUE}[INFO] 启动 MySQL...${NC}"
        brew services start mysql > /dev/null 2>&1
        sleep 2
        if check_port $MYSQL_PORT; then
            echo -e "${GREEN}[SUCCESS] MySQL 启动成功${NC}"
        else
            echo -e "${RED}[ERROR] MySQL 启动失败${NC}"
        fi
    fi

    # PostgreSQL
    if check_port $POSTGRES_PORT; then
        echo -e "${YELLOW}[WARNING] PostgreSQL 已在端口 $POSTGRES_PORT 运行${NC}"
    else
        echo -e "${BLUE}[INFO] 启动 PostgreSQL...${NC}"
        brew services start postgresql@14 > /dev/null 2>&1
        sleep 2
        if check_port $POSTGRES_PORT; then
            echo -e "${GREEN}[SUCCESS] PostgreSQL 启动成功${NC}"
        else
            echo -e "${RED}[ERROR] PostgreSQL 启动失败${NC}"
        fi
    fi

    # Redis
    if check_port $REDIS_PORT; then
        echo -e "${YELLOW}[WARNING] Redis 已在端口 $REDIS_PORT 运行${NC}"
    else
        echo -e "${BLUE}[INFO] 启动 Redis...${NC}"
        brew services start redis > /dev/null 2>&1
        sleep 2
        if check_port $REDIS_PORT; then
            echo -e "${GREEN}[SUCCESS] Redis 启动成功${NC}"
        else
            echo -e "${RED}[ERROR] Redis 启动失败${NC}"
        fi
    fi

    # Neo4j
    if check_port $NEO4J_PORT; then
        echo -e "${YELLOW}[WARNING] Neo4j 已在端口 $NEO4J_PORT 运行${NC}"
    else
        echo -e "${BLUE}[INFO] 启动 Neo4j...${NC}"
        brew services start neo4j > /dev/null 2>&1
        sleep 5 # Neo4j启动较慢
        if check_port $NEO4J_PORT; then
            echo -e "${GREEN}[SUCCESS] Neo4j 启动成功${NC}"
        else
            echo -e "${RED}[ERROR] Neo4j 启动失败${NC}"
        fi
    fi
}

# 启动API Gateway (带热加载)
start_api_gateway() {
    echo -e "${BLUE}[INFO] === 启动API Gateway (热加载模式) ===${NC}"
    if check_port $API_GATEWAY_PORT; then
        echo -e "${YELLOW}[WARNING] API Gateway 已在端口 $API_GATEWAY_PORT 运行${NC}"
    else
        echo -e "${BLUE}[INFO] 启动API Gateway服务 (air热加载)...${NC}"
        cd backend
        air &
        API_GATEWAY_PID=$!
        echo $API_GATEWAY_PID > /tmp/jobfirst_api_gateway.pid
        sleep 5
        if check_port $API_GATEWAY_PORT; then
            echo -e "${GREEN}[SUCCESS] API Gateway 启动成功 (PID: $API_GATEWAY_PID)${NC}"
        else
            echo -e "${RED}[ERROR] API Gateway 启动失败${NC}"
        fi
        cd ..
    fi
}

# 启动User Service (带热加载)
start_user_service() {
    echo -e "${BLUE}[INFO] === 启动User Service (热加载模式) ===${NC}"
    if check_port $USER_SERVICE_PORT; then
        echo -e "${YELLOW}[WARNING] User Service 已在端口 $USER_SERVICE_PORT 运行${NC}"
    else
        echo -e "${BLUE}[INFO] 启动User Service (air热加载)...${NC}"
        cd backend/internal/user-service
        air &
        USER_SERVICE_PID=$!
        echo $USER_SERVICE_PID > /tmp/jobfirst_user_service.pid
        sleep 3
        if check_port $USER_SERVICE_PORT; then
            echo -e "${GREEN}[SUCCESS] User Service 启动成功 (PID: $USER_SERVICE_PID)${NC}"
        else
            echo -e "${RED}[ERROR] User Service 启动失败${NC}"
        fi
        cd ../../..
    fi
}

# 启动Resume Service (带热加载)
start_resume_service() {
    echo -e "${BLUE}[INFO] === 启动Resume Service (热加载模式) ===${NC}"
    if check_port $RESUME_SERVICE_PORT; then
        echo -e "${YELLOW}[WARNING] Resume Service 已在端口 $RESUME_SERVICE_PORT 运行${NC}"
    else
        echo -e "${BLUE}[INFO] 启动Resume Service (air热加载)...${NC}"
        cd backend/internal/resume-service
        air &
        RESUME_SERVICE_PID=$!
        echo $RESUME_SERVICE_PID > /tmp/jobfirst_resume_service.pid
        sleep 3
        if check_port $RESUME_SERVICE_PORT; then
            echo -e "${GREEN}[SUCCESS] Resume Service 启动成功 (PID: $RESUME_SERVICE_PID)${NC}"
        else
            echo -e "${RED}[ERROR] Resume Service 启动失败${NC}"
        fi
        cd ../../..
    fi
}

# 启动Company Service (带热加载)
start_company_service() {
    echo -e "${BLUE}[INFO] === 启动Company Service (热加载模式) ===${NC}"
    if check_port $COMPANY_SERVICE_PORT; then
        echo -e "${YELLOW}[WARNING] Company Service 已在端口 $COMPANY_SERVICE_PORT 运行${NC}"
    else
        echo -e "${BLUE}[INFO] 启动Company Service (air热加载)...${NC}"
        cd backend/internal/company-service
        air &
        COMPANY_SERVICE_PID=$!
        echo $COMPANY_SERVICE_PID > /tmp/jobfirst_company_service.pid
        sleep 3
        if check_port $COMPANY_SERVICE_PORT; then
            echo -e "${GREEN}[SUCCESS] Company Service 启动成功 (PID: $COMPANY_SERVICE_PID)${NC}"
        else
            echo -e "${RED}[ERROR] Company Service 启动失败${NC}"
        fi
        cd ../../..
    fi
}

# 启动Notification Service (带热加载)
start_notification_service() {
    echo -e "${BLUE}[INFO] === 启动Notification Service (热加载模式) ===${NC}"
    if check_port $NOTIFICATION_SERVICE_PORT; then
        echo -e "${YELLOW}[WARNING] Notification Service 已在端口 $NOTIFICATION_SERVICE_PORT 运行${NC}"
    else
        echo -e "${BLUE}[INFO] 启动Notification Service (air热加载)...${NC}"
        cd backend/internal/notification-service
        air &
        NOTIFICATION_SERVICE_PID=$!
        echo $NOTIFICATION_SERVICE_PID > /tmp/jobfirst_notification_service.pid
        sleep 3
        if check_port $NOTIFICATION_SERVICE_PORT; then
            echo -e "${GREEN}[SUCCESS] Notification Service 启动成功 (PID: $NOTIFICATION_SERVICE_PID)${NC}"
        else
            echo -e "${RED}[ERROR] Notification Service 启动失败${NC}"
        fi
        cd ../../..
    fi
}

# 启动Template Service (带热加载)
start_template_service() {
    echo -e "${BLUE}[INFO] === 启动Template Service (热加载模式) ===${NC}"
    if check_port $TEMPLATE_SERVICE_PORT; then
        echo -e "${YELLOW}[WARNING] Template Service 已在端口 $TEMPLATE_SERVICE_PORT 运行${NC}"
    else
        echo -e "${BLUE}[INFO] 启动Template Service (air热加载)...${NC}"
        cd backend/internal/template-service
        air &
        TEMPLATE_SERVICE_PID=$!
        echo $TEMPLATE_SERVICE_PID > /tmp/jobfirst_template_service.pid
        sleep 3
        if check_port $TEMPLATE_SERVICE_PORT; then
            echo -e "${GREEN}[SUCCESS] Template Service 启动成功 (PID: $TEMPLATE_SERVICE_PID)${NC}"
        else
            echo -e "${RED}[ERROR] Template Service 启动失败${NC}"
        fi
        cd ../../..
    fi
}

# 启动Job Service (带热加载)
start_job_service() {
    echo -e "${BLUE}[INFO] === 启动Job Service (热加载模式) ===${NC}"
    if check_port $JOB_SERVICE_PORT; then
        echo -e "${YELLOW}[WARNING] Job Service 已在端口 $JOB_SERVICE_PORT 运行${NC}"
    else
        echo -e "${BLUE}[INFO] 启动Job Service (air热加载)...${NC}"
        cd backend/internal/job-service
        air &
        JOB_SERVICE_PID=$!
        echo $JOB_SERVICE_PID > /tmp/jobfirst_job_service.pid
        sleep 3
        if check_port $JOB_SERVICE_PORT; then
            echo -e "${GREEN}[SUCCESS] Job Service 启动成功 (PID: $JOB_SERVICE_PID)${NC}"
        else
            echo -e "${RED}[ERROR] Job Service 启动失败${NC}"
        fi
        cd ../../..
    fi
}

# 启动Banner Service (带热加载)
start_banner_service() {
    echo -e "${BLUE}[INFO] === 启动Banner Service (热加载模式) ===${NC}"
    if check_port $BANNER_SERVICE_PORT; then
        echo -e "${YELLOW}[WARNING] Banner Service 已在端口 $BANNER_SERVICE_PORT 运行${NC}"
    else
        echo -e "${BLUE}[INFO] 启动Banner Service (air热加载)...${NC}"
        cd backend/internal/banner-service
        air &
        BANNER_SERVICE_PID=$!
        echo $BANNER_SERVICE_PID > /tmp/jobfirst_banner_service.pid
        sleep 3
        if check_port $BANNER_SERVICE_PORT; then
            echo -e "${GREEN}[SUCCESS] Banner Service 启动成功 (PID: $BANNER_SERVICE_PID)${NC}"
        else
            echo -e "${RED}[ERROR] Banner Service 启动失败${NC}"
        fi
        cd ../../..
    fi
}

# 启动Dev Team Service (带热加载)
start_dev_team_service() {
    echo -e "${BLUE}[INFO] === 启动Dev Team Service (热加载模式) ===${NC}"
    if check_port $DEV_TEAM_SERVICE_PORT; then
        echo -e "${YELLOW}[WARNING] Dev Team Service 已在端口 $DEV_TEAM_SERVICE_PORT 运行${NC}"
    else
        echo -e "${BLUE}[INFO] 启动Dev Team Service (air热加载)...${NC}"
        cd backend/internal/dev-team-service
        air &
        DEV_TEAM_SERVICE_PID=$!
        echo $DEV_TEAM_SERVICE_PID > /tmp/jobfirst_dev_team_service.pid
        sleep 3
        if check_port $DEV_TEAM_SERVICE_PORT; then
            echo -e "${GREEN}[SUCCESS] Dev Team Service 启动成功 (PID: $DEV_TEAM_SERVICE_PID)${NC}"
        else
            echo -e "${RED}[ERROR] Dev Team Service 启动失败${NC}"
        fi
        cd ../../..
    fi
}

# 启动Statistics Service (带热加载)
start_statistics_service() {
    echo -e "${BLUE}[INFO] === 启动Statistics Service (热加载模式) ===${NC}"
    if check_port $STATISTICS_SERVICE_PORT; then
        echo -e "${YELLOW}[WARNING] Statistics Service 已在端口 $STATISTICS_SERVICE_PORT 运行${NC}"
    else
        echo -e "${BLUE}[INFO] 启动Statistics Service (air热加载)...${NC}"
        cd backend/internal/statistics-service
        export PORT=$STATISTICS_SERVICE_PORT
        air &
        STATISTICS_SERVICE_PID=$!
        echo $STATISTICS_SERVICE_PID > /tmp/jobfirst_statistics_service.pid
        sleep 3
        if check_port $STATISTICS_SERVICE_PORT; then
            echo -e "${GREEN}[SUCCESS] Statistics Service 启动成功 (PID: $STATISTICS_SERVICE_PID)${NC}"
        else
            echo -e "${RED}[ERROR] Statistics Service 启动失败${NC}"
        fi
        cd ../../..
    fi
}

# 启动Multi Database Service (带热加载)
start_multi_database_service() {
    echo -e "${BLUE}[INFO] === 启动Multi Database Service (热加载模式) ===${NC}"
    if check_port $MULTI_DATABASE_SERVICE_PORT; then
        echo -e "${YELLOW}[WARNING] Multi Database Service 已在端口 $MULTI_DATABASE_SERVICE_PORT 运行${NC}"
    else
        echo -e "${BLUE}[INFO] 启动Multi Database Service (air热加载)...${NC}"
        cd backend/internal/multi-database-service
        export PORT=$MULTI_DATABASE_SERVICE_PORT
        air &
        MULTI_DATABASE_SERVICE_PID=$!
        echo $MULTI_DATABASE_SERVICE_PID > /tmp/jobfirst_multi_database_service.pid
        sleep 3
        if check_port $MULTI_DATABASE_SERVICE_PORT; then
            echo -e "${GREEN}[SUCCESS] Multi Database Service 启动成功 (PID: $MULTI_DATABASE_SERVICE_PID)${NC}"
        else
            echo -e "${RED}[ERROR] Multi Database Service 启动失败${NC}"
        fi
        cd ../../..
    fi
}


# 启动AI Service (容器化部署) - 依赖用户认证服务
start_ai_service() {
    echo -e "${BLUE}[INFO] === 启动AI Service (容器化部署) ===${NC}"
    
    # 检查用户认证服务是否已启动
    if ! check_port $USER_SERVICE_PORT; then
        echo -e "${RED}[ERROR] AI Service 需要 User Service 先启动 (端口 $USER_SERVICE_PORT)${NC}"
        echo -e "${YELLOW}[INFO] 请确保 User Service 已启动，AI Service 依赖用户认证功能${NC}"
        return 1
    fi
    
    # 检查API Gateway是否已启动
    if ! check_port $API_GATEWAY_PORT; then
        echo -e "${RED}[ERROR] AI Service 需要 API Gateway 先启动 (端口 $API_GATEWAY_PORT)${NC}"
        return 1
    fi
    
    if check_port $AI_SERVICE_PORT; then
        echo -e "${YELLOW}[WARNING] AI Service 已在端口 $AI_SERVICE_PORT 运行${NC}"
    else
        echo -e "${BLUE}[INFO] 启动AI Service (Docker容器化)...${NC}"
        echo -e "${CYAN}[INFO] AI Service 使用容器化部署，支持个性化AI服务${NC}"
        
        cd ai-services
        
        # 检查Docker是否运行
        if ! docker info > /dev/null 2>&1; then
            echo -e "${RED}[ERROR] Docker 未运行，请先启动Docker Desktop${NC}"
            return 1
        fi
        
        # 检查Docker Compose文件
        if [ ! -f "docker-compose.yml" ]; then
            echo -e "${RED}[ERROR] 未找到 docker-compose.yml 文件${NC}"
            return 1
        fi
        
        # 启动AI服务容器
        echo -e "${BLUE}[INFO] 启动AI服务容器...${NC}"
        docker-compose up -d ai-service
        
        # 等待服务启动
        echo -e "${BLUE}[INFO] 等待AI Service启动...${NC}"
        sleep 10
        
        if check_port $AI_SERVICE_PORT; then
            echo -e "${GREEN}[SUCCESS] AI Service 启动成功 (容器化部署)${NC}"
            echo -e "${CYAN}[INFO] AI Service 已启用JWT认证，需要用户登录后才能访问${NC}"
            echo -e "${CYAN}[INFO] AI Service 地址: http://localhost:$AI_SERVICE_PORT${NC}"
        else
            echo -e "${RED}[ERROR] AI Service 启动失败${NC}"
            echo -e "${YELLOW}[INFO] 检查容器日志: docker-compose logs ai-service${NC}"
            return 1
        fi
        cd ..
    fi
}

# 启动前端开发服务器
start_frontend() {
    echo -e "${BLUE}[INFO] === 启动前端开发服务器 ===${NC}"
    if check_port 10086; then
        echo -e "${YELLOW}[WARNING] 前端开发服务器已在端口 10086 运行${NC}"
    else
        echo -e "${BLUE}[INFO] 启动Taro前端开发服务器...${NC}"
        cd frontend-taro
        npm run dev:h5 &
        FRONTEND_PID=$!
        echo $FRONTEND_PID > /tmp/jobfirst_frontend.pid
        sleep 8
        if check_port 10086; then
            echo -e "${GREEN}[SUCCESS] 前端开发服务器启动成功 (PID: $FRONTEND_PID)${NC}"
            echo -e "${CYAN}[INFO] 前端访问地址: http://localhost:10086${NC}"
        else
            echo -e "${RED}[ERROR] 前端开发服务器启动失败${NC}"
        fi
        cd ..
    fi
}

# 停止所有服务
stop_all_services() {
    echo -e "${BLUE}[INFO] === 停止所有开发服务 ===${NC}"
    
    # 定义专业版端口
    PRO_PORTS="8601 8602 8603 8604 8605 8606 8607 8609 8611 8612 8613 10086"
    
    # 停止前端
    if [ -f /tmp/jobfirst_frontend.pid ]; then
        FRONTEND_PID=$(cat /tmp/jobfirst_frontend.pid)
        if kill -0 $FRONTEND_PID 2>/dev/null; then
            kill -TERM $FRONTEND_PID 2>/dev/null
            sleep 2
            if kill -0 $FRONTEND_PID 2>/dev/null; then
                kill -KILL $FRONTEND_PID 2>/dev/null
            fi
        fi
        rm -f /tmp/jobfirst_frontend.pid
        echo -e "${GREEN}[SUCCESS] 前端服务已停止${NC}"
    fi
    
    # 停止AI服务容器
    if [ -d "ai-services" ]; then
        cd ai-services
        if docker-compose ps ai-service | grep -q "Up"; then
            echo -e "${BLUE}[INFO] 停止AI服务容器...${NC}"
            docker-compose stop ai-service
            echo -e "${GREEN}[SUCCESS] AI服务容器已停止${NC}"
        fi
        cd ..
    fi
    
    # 停止Job服务
    if [ -f /tmp/jobfirst_job_service.pid ]; then
        JOB_SERVICE_PID=$(cat /tmp/jobfirst_job_service.pid)
        if kill -0 $JOB_SERVICE_PID 2>/dev/null; then
            kill -TERM $JOB_SERVICE_PID 2>/dev/null
            sleep 2
            if kill -0 $JOB_SERVICE_PID 2>/dev/null; then
                kill -KILL $JOB_SERVICE_PID 2>/dev/null
            fi
        fi
        rm -f /tmp/jobfirst_job_service.pid
        echo -e "${GREEN}[SUCCESS] Job服务已停止${NC}"
    fi
    
    # 停止Banner服务
    if [ -f /tmp/jobfirst_banner_service.pid ]; then
        BANNER_SERVICE_PID=$(cat /tmp/jobfirst_banner_service.pid)
        if kill -0 $BANNER_SERVICE_PID 2>/dev/null; then
            kill -TERM $BANNER_SERVICE_PID 2>/dev/null
            sleep 2
            if kill -0 $BANNER_SERVICE_PID 2>/dev/null; then
                kill -KILL $BANNER_SERVICE_PID 2>/dev/null
            fi
        fi
        rm -f /tmp/jobfirst_banner_service.pid
        echo -e "${GREEN}[SUCCESS] Banner服务已停止${NC}"
    fi
    
    # 停止Dev Team服务
    if [ -f /tmp/jobfirst_dev_team_service.pid ]; then
        DEV_TEAM_SERVICE_PID=$(cat /tmp/jobfirst_dev_team_service.pid)
        if kill -0 $DEV_TEAM_SERVICE_PID 2>/dev/null; then
            kill -TERM $DEV_TEAM_SERVICE_PID 2>/dev/null
            sleep 2
            if kill -0 $DEV_TEAM_SERVICE_PID 2>/dev/null; then
                kill -KILL $DEV_TEAM_SERVICE_PID 2>/dev/null
            fi
        fi
        rm -f /tmp/jobfirst_dev_team_service.pid
        echo -e "${GREEN}[SUCCESS] Dev Team服务已停止${NC}"
    fi
    
    # 停止Template服务
    if [ -f /tmp/jobfirst_template_service.pid ]; then
        TEMPLATE_SERVICE_PID=$(cat /tmp/jobfirst_template_service.pid)
        if kill -0 $TEMPLATE_SERVICE_PID 2>/dev/null; then
            kill -TERM $TEMPLATE_SERVICE_PID 2>/dev/null
            sleep 2
            if kill -0 $TEMPLATE_SERVICE_PID 2>/dev/null; then
                kill -KILL $TEMPLATE_SERVICE_PID 2>/dev/null
            fi
        fi
        rm -f /tmp/jobfirst_template_service.pid
        echo -e "${GREEN}[SUCCESS] Template服务已停止${NC}"
    fi
    
    # 停止Notification服务
    if [ -f /tmp/jobfirst_notification_service.pid ]; then
        NOTIFICATION_SERVICE_PID=$(cat /tmp/jobfirst_notification_service.pid)
        if kill -0 $NOTIFICATION_SERVICE_PID 2>/dev/null; then
            kill -TERM $NOTIFICATION_SERVICE_PID 2>/dev/null
            sleep 2
            if kill -0 $NOTIFICATION_SERVICE_PID 2>/dev/null; then
                kill -KILL $NOTIFICATION_SERVICE_PID 2>/dev/null
            fi
        fi
        rm -f /tmp/jobfirst_notification_service.pid
        echo -e "${GREEN}[SUCCESS] Notification服务已停止${NC}"
    fi
    
    # 停止Company服务
    if [ -f /tmp/jobfirst_company_service.pid ]; then
        COMPANY_SERVICE_PID=$(cat /tmp/jobfirst_company_service.pid)
        if kill -0 $COMPANY_SERVICE_PID 2>/dev/null; then
            kill -TERM $COMPANY_SERVICE_PID 2>/dev/null
            sleep 2
            if kill -0 $COMPANY_SERVICE_PID 2>/dev/null; then
                kill -KILL $COMPANY_SERVICE_PID 2>/dev/null
            fi
        fi
        rm -f /tmp/jobfirst_company_service.pid
        echo -e "${GREEN}[SUCCESS] Company服务已停止${NC}"
    fi
    
    # 停止Resume服务
    if [ -f /tmp/jobfirst_resume_service.pid ]; then
        RESUME_SERVICE_PID=$(cat /tmp/jobfirst_resume_service.pid)
        if kill -0 $RESUME_SERVICE_PID 2>/dev/null; then
            kill -TERM $RESUME_SERVICE_PID 2>/dev/null
            sleep 2
            if kill -0 $RESUME_SERVICE_PID 2>/dev/null; then
                kill -KILL $RESUME_SERVICE_PID 2>/dev/null
            fi
        fi
        rm -f /tmp/jobfirst_resume_service.pid
        echo -e "${GREEN}[SUCCESS] Resume服务已停止${NC}"
    fi
    
    # 停止User服务
    if [ -f /tmp/jobfirst_user_service.pid ]; then
        USER_SERVICE_PID=$(cat /tmp/jobfirst_user_service.pid)
        if kill -0 $USER_SERVICE_PID 2>/dev/null; then
            kill -TERM $USER_SERVICE_PID 2>/dev/null
            sleep 2
            if kill -0 $USER_SERVICE_PID 2>/dev/null; then
                kill -KILL $USER_SERVICE_PID 2>/dev/null
            fi
        fi
        rm -f /tmp/jobfirst_user_service.pid
        echo -e "${GREEN}[SUCCESS] User服务已停止${NC}"
    fi
    
    # 停止API Gateway
    if [ -f /tmp/jobfirst_api_gateway.pid ]; then
        API_GATEWAY_PID=$(cat /tmp/jobfirst_api_gateway.pid)
        if kill -0 $API_GATEWAY_PID 2>/dev/null; then
            kill -TERM $API_GATEWAY_PID 2>/dev/null
            sleep 2
            if kill -0 $API_GATEWAY_PID 2>/dev/null; then
                kill -KILL $API_GATEWAY_PID 2>/dev/null
            fi
        fi
        rm -f /tmp/jobfirst_api_gateway.pid
        echo -e "${GREEN}[SUCCESS] API Gateway已停止${NC}"
    fi
    
    # 停止所有air进程
    pkill -f "air" 2>/dev/null
    echo -e "${GREEN}[SUCCESS] 所有air热加载进程已停止${NC}"
    
    # 强制清理专业版相关进程
    echo -e "${BLUE}[INFO] 强制清理专业版相关进程...${NC}"
    for port in $PRO_PORTS; do
        # 查找占用端口的进程
        PID=$(lsof -ti:$port 2>/dev/null)
        if [ ! -z "$PID" ]; then
            echo -e "${YELLOW}[WARNING] 端口 $port 被进程 $PID 占用，强制终止...${NC}"
            kill -TERM $PID 2>/dev/null
            sleep 1
            if kill -0 $PID 2>/dev/null; then
                kill -KILL $PID 2>/dev/null
            fi
        fi
    done
    
    # 清理所有jobfirst相关进程
    pkill -f "jobfirst" 2>/dev/null
    pkill -f "company-service" 2>/dev/null
    pkill -f "notification-service" 2>/dev/null
    pkill -f "template-service" 2>/dev/null
    pkill -f "statistics-service" 2>/dev/null
    pkill -f "resume-service" 2>/dev/null
    pkill -f "user-service" 2>/dev/null
    pkill -f "api-gateway" 2>/dev/null
    pkill -f "job-service" 2>/dev/null
    pkill -f "banner-service" 2>/dev/null
    pkill -f "dev-team-service" 2>/dev/null
    pkill -f "multi-database-service" 2>/dev/null
    
    # 清理临时文件
    rm -f /tmp/jobfirst_*.pid
    
    # 验证所有服务已停止
    echo -e "${BLUE}[INFO] 验证所有服务已停止...${NC}"
    sleep 2
    
    for port in $PRO_PORTS; do
        if lsof -ti:$port >/dev/null 2>&1; then
            echo -e "${RED}[ERROR] 端口 $port 仍被占用${NC}"
        else
            echo -e "${GREEN}[SUCCESS] 端口 $port 已释放${NC}"
        fi
    done
    
    echo -e "${GREEN}[SUCCESS] 专业版服务清理完成！${NC}"
}

# 健康检查
health_check() {
    echo -e "${BLUE}[INFO] === 开发环境健康检查 ===${NC}"
    
    # 检查数据库
    echo -e "${CYAN}[INFO] 检查数据库服务...${NC}"
    mysql -u root -e "SELECT 1;" > /dev/null 2>&1
    if [ $? -eq 0 ]; then echo -e "${GREEN}[SUCCESS] MySQL 连接正常${NC}"; else echo -e "${RED}[ERROR] MySQL 连接失败${NC}"; fi
    
    psql -U szjason72 -d jobfirst_vector -c "SELECT 1;" > /dev/null 2>&1
    if [ $? -eq 0 ]; then echo -e "${GREEN}[SUCCESS] PostgreSQL 连接正常${NC}"; else echo -e "${RED}[ERROR] PostgreSQL 连接失败${NC}"; fi
    
    redis-cli ping > /dev/null 2>&1
    if [ $? -eq 0 ]; then echo -e "${GREEN}[SUCCESS] Redis 连接正常${NC}"; else echo -e "${RED}[ERROR] Redis 连接失败${NC}"; fi
    
    curl -s http://localhost:$NEO4J_PORT > /dev/null 2>&1
    if [ $? -eq 0 ]; then echo -e "${GREEN}[SUCCESS] Neo4j 连接正常${NC}"; else echo -e "${RED}[ERROR] Neo4j 连接失败${NC}"; fi
    
    # 检查微服务
    echo -e "${CYAN}[INFO] 检查微服务...${NC}"
    curl -s http://localhost:$API_GATEWAY_PORT/health | grep -q '"status":true'
    if [ $? -eq 0 ]; then echo -e "${GREEN}[SUCCESS] API Gateway 健康检查通过${NC}"; else echo -e "${RED}[ERROR] API Gateway 健康检查失败${NC}"; fi
    
    curl -s http://localhost:$USER_SERVICE_PORT/health | grep -q '"status":"healthy"'
    if [ $? -eq 0 ]; then echo -e "${GREEN}[SUCCESS] User Service 健康检查通过${NC}"; else echo -e "${RED}[ERROR] User Service 健康检查失败${NC}"; fi
    
    curl -s http://localhost:$RESUME_SERVICE_PORT/health | grep -q '"status":"healthy"'
    if [ $? -eq 0 ]; then echo -e "${GREEN}[SUCCESS] Resume Service 健康检查通过${NC}"; else echo -e "${RED}[ERROR] Resume Service 健康检查失败${NC}"; fi
    
    curl -s http://localhost:$COMPANY_SERVICE_PORT/health | grep -q '"status":"healthy"'
    if [ $? -eq 0 ]; then echo -e "${GREEN}[SUCCESS] Company Service 健康检查通过${NC}"; else echo -e "${RED}[ERROR] Company Service 健康检查失败${NC}"; fi
    
    curl -s http://localhost:$NOTIFICATION_SERVICE_PORT/health | grep -q '"status":"healthy"'
    if [ $? -eq 0 ]; then echo -e "${GREEN}[SUCCESS] Notification Service 健康检查通过${NC}"; else echo -e "${RED}[ERROR] Notification Service 健康检查失败${NC}"; fi
    
    curl -s http://localhost:$TEMPLATE_SERVICE_PORT/health | grep -q '"status":"healthy"'
    if [ $? -eq 0 ]; then echo -e "${GREEN}[SUCCESS] Template Service 健康检查通过${NC}"; else echo -e "${RED}[ERROR] Template Service 健康检查失败${NC}"; fi
    
    curl -s http://localhost:$JOB_SERVICE_PORT/health | grep -q '"status":"healthy"'
    if [ $? -eq 0 ]; then echo -e "${GREEN}[SUCCESS] Job Service 健康检查通过${NC}"; else echo -e "${RED}[ERROR] Job Service 健康检查失败${NC}"; fi
    
    curl -s http://localhost:$BANNER_SERVICE_PORT/health | grep -q '"status":"healthy"'
    if [ $? -eq 0 ]; then echo -e "${GREEN}[SUCCESS] Banner Service 健康检查通过${NC}"; else echo -e "${RED}[ERROR] Banner Service 健康检查失败${NC}"; fi
    
    curl -s http://localhost:$DEV_TEAM_SERVICE_PORT/health | grep -q '"status":"healthy"'
    if [ $? -eq 0 ]; then echo -e "${GREEN}[SUCCESS] Dev Team Service 健康检查通过${NC}"; else echo -e "${RED}[ERROR] Dev Team Service 健康检查失败${NC}"; fi
    
    curl -s http://localhost:$STATISTICS_SERVICE_PORT/health | grep -q '"status":"healthy"'
    if [ $? -eq 0 ]; then echo -e "${GREEN}[SUCCESS] Statistics Service 健康检查通过${NC}"; else echo -e "${RED}[ERROR] Statistics Service 健康检查失败${NC}"; fi
    
    curl -s http://localhost:$MULTI_DATABASE_SERVICE_PORT/health | grep -q '"status":"healthy"'
    if [ $? -eq 0 ]; then echo -e "${GREEN}[SUCCESS] Multi Database Service 健康检查通过${NC}"; else echo -e "${RED}[ERROR] Multi Database Service 健康检查失败${NC}"; fi
    
    curl -s http://localhost:$AI_SERVICE_PORT/health | grep -q '"status":"healthy"'
    if [ $? -eq 0 ]; then echo -e "${GREEN}[SUCCESS] AI Service 健康检查通过${NC}"; else echo -e "${RED}[ERROR] AI Service 健康检查失败${NC}"; fi
    
    # 检查前端
    curl -s http://localhost:10086 > /dev/null 2>&1
    if [ $? -eq 0 ]; then echo -e "${GREEN}[SUCCESS] 前端服务运行正常${NC}"; else echo -e "${RED}[ERROR] 前端服务运行异常${NC}"; fi
}

# 显示服务状态
show_status() {
    echo -e "${BLUE}[INFO] === 开发环境服务状态 ===${NC}"
    echo ""
    echo -e "${CYAN}数据库服务:${NC}"
    echo "  MySQL ($MYSQL_PORT): $(if check_port $MYSQL_PORT; then echo -e "${GREEN}运行中${NC}"; else echo -e "${RED}未运行${NC}"; fi)"
    echo "  PostgreSQL ($POSTGRES_PORT): $(if check_port $POSTGRES_PORT; then echo -e "${GREEN}运行中${NC}"; else echo -e "${RED}未运行${NC}"; fi)"
    echo "  Redis ($REDIS_PORT): $(if check_port $REDIS_PORT; then echo -e "${GREEN}运行中${NC}"; else echo -e "${RED}未运行${NC}"; fi)"
    echo "  Neo4j ($NEO4J_PORT): $(if check_port $NEO4J_PORT; then echo -e "${GREEN}运行中${NC}"; else echo -e "${RED}未运行${NC}"; fi)"
    echo ""
    echo -e "${CYAN}微服务 (热加载模式):${NC}"
    echo "  API Gateway ($API_GATEWAY_PORT): $(if check_port $API_GATEWAY_PORT; then echo -e "${GREEN}运行中 (air)${NC}"; else echo -e "${RED}未运行${NC}"; fi)"
    echo "  User Service ($USER_SERVICE_PORT): $(if check_port $USER_SERVICE_PORT; then echo -e "${GREEN}运行中 (air)${NC}"; else echo -e "${RED}未运行${NC}"; fi)"
    echo "  Resume Service ($RESUME_SERVICE_PORT): $(if check_port $RESUME_SERVICE_PORT; then echo -e "${GREEN}运行中 (air)${NC}"; else echo -e "${RED}未运行${NC}"; fi)"
    echo "  Company Service ($COMPANY_SERVICE_PORT): $(if check_port $COMPANY_SERVICE_PORT; then echo -e "${GREEN}运行中 (air)${NC}"; else echo -e "${RED}未运行${NC}"; fi)"
    echo "  Notification Service ($NOTIFICATION_SERVICE_PORT): $(if check_port $NOTIFICATION_SERVICE_PORT; then echo -e "${GREEN}运行中 (air)${NC}"; else echo -e "${RED}未运行${NC}"; fi)"
    echo "  Template Service ($TEMPLATE_SERVICE_PORT): $(if check_port $TEMPLATE_SERVICE_PORT; then echo -e "${GREEN}运行中 (air)${NC}"; else echo -e "${RED}未运行${NC}"; fi)"
    echo "  Job Service ($JOB_SERVICE_PORT): $(if check_port $JOB_SERVICE_PORT; then echo -e "${GREEN}运行中 (air)${NC}"; else echo -e "${RED}未运行${NC}"; fi)"
    echo "  Banner Service ($BANNER_SERVICE_PORT): $(if check_port $BANNER_SERVICE_PORT; then echo -e "${GREEN}运行中 (air)${NC}"; else echo -e "${RED}未运行${NC}"; fi)"
    echo "  Dev Team Service ($DEV_TEAM_SERVICE_PORT): $(if check_port $DEV_TEAM_SERVICE_PORT; then echo -e "${GREEN}运行中 (air)${NC}"; else echo -e "${RED}未运行${NC}"; fi)"
    echo "  AI Service ($AI_SERVICE_PORT): $(if check_port $AI_SERVICE_PORT; then echo -e "${GREEN}运行中 (Docker容器)${NC}"; else echo -e "${RED}未运行${NC}"; fi)"
    echo ""
    echo -e "${CYAN}前端服务:${NC}"
    echo "  Taro H5 (10086): $(if check_port 10086; then echo -e "${GREEN}运行中${NC}"; else echo -e "${RED}未运行${NC}"; fi)"
    echo ""
    echo -e "${PURPLE}访问地址:${NC}"
    echo "  前端应用: http://localhost:10086"
    echo "  API Gateway: http://localhost:$API_GATEWAY_PORT"
    echo "  AI Service: http://localhost:$AI_SERVICE_PORT"
    echo "  Neo4j Browser: http://localhost:$NEO4J_PORT"
}

# 显示帮助信息
show_help() {
    echo -e "${BLUE}JobFirst 开发环境管理脚本${NC}"
    echo ""
    echo -e "${CYAN}用法:${NC}"
    echo "  $0 {start|stop|restart|status|health|frontend|backend|help}"
    echo ""
    echo -e "${CYAN}命令说明:${NC}"
    echo "  start     - 启动完整的开发环境 (数据库 + 后端 + 前端)"
    echo "  stop      - 停止所有开发服务"
    echo "  restart   - 重启所有开发服务"
    echo "  status    - 显示服务状态"
    echo "  health    - 执行健康检查"
    echo "  frontend  - 仅启动前端开发服务器"
    echo "  backend   - 仅启动后端服务 (数据库 + 微服务)"
    echo "  help      - 显示此帮助信息"
    echo ""
    echo -e "${CYAN}热加载特性:${NC}"
    echo "  - API Gateway: air热加载 (Go代码修改自动重启)"
    echo "  - User Service: air热加载 (Go代码修改自动重启)"
    echo "  - Resume Service: air热加载 (Go代码修改自动重启)"
    echo "  - Company Service: air热加载 (Go代码修改自动重启)"
    echo "  - Notification Service: air热加载 (Go代码修改自动重启)"
    echo "  - Template Service: air热加载 (Go代码修改自动重启)"
    echo "  - Job Service: air热加载 (Go代码修改自动重启)"
    echo "  - Banner Service: air热加载 (Go代码修改自动重启)"
    echo "  - Dev Team Service: air热加载 (Go代码修改自动重启)"
    echo "  - AI Service: Docker容器化部署 (个性化AI服务)"
    echo "  - 前端: Taro HMR (前端代码修改自动刷新)"
    echo ""
    echo -e "${PURPLE}开发建议:${NC}"
    echo "  1. 首次启动使用: $0 start"
    echo "  2. 开发过程中修改代码会自动热加载"
    echo "  3. 使用 $0 status 查看服务状态"
    echo "  4. 使用 $0 health 检查服务健康状态"
    echo "  5. 开发完成后使用: $0 stop"
}

# 主逻辑
case "$1" in
    start)
        echo -e "${GREEN}[INFO] 启动JobFirst完整开发环境 (热加载模式)...${NC}"
        start_databases
        start_api_gateway
        start_user_service
        start_resume_service
        start_company_service
        start_notification_service
        start_template_service
        start_banner_service
        start_dev_team_service
        start_statistics_service
        start_multi_database_service
        start_job_service
        start_ai_service
        start_frontend
        sleep 3
        health_check
        show_status
        echo -e "${GREEN}[SUCCESS] 开发环境启动完成！${NC}"
        echo -e "${CYAN}[INFO] 前端访问地址: http://localhost:10086${NC}"
        ;;
    stop)
        stop_all_services
        echo -e "${GREEN}[SUCCESS] 所有开发服务已停止！${NC}"
        ;;
    restart)
        stop_all_services
        sleep 2
        echo -e "${GREEN}[INFO] 重启JobFirst开发环境...${NC}"
        start_databases
        start_api_gateway
        start_user_service
        start_resume_service
        start_company_service
        start_notification_service
        start_template_service
        start_statistics_service
        start_multi_database_service
        start_job_service
        start_ai_service
        start_frontend
        sleep 3
        health_check
        show_status
        echo -e "${GREEN}[SUCCESS] 开发环境重启完成！${NC}"
        ;;
    status)
        show_status
        ;;
    health)
        health_check
        ;;
    frontend)
        echo -e "${GREEN}[INFO] 启动前端开发服务器...${NC}"
        start_frontend
        ;;
    backend)
        echo -e "${GREEN}[INFO] 启动后端服务 (热加载模式)...${NC}"
        start_databases
        start_api_gateway
        start_user_service
        start_resume_service
        start_company_service
        start_notification_service
        start_template_service
        start_statistics_service
        start_multi_database_service
        start_job_service
        start_ai_service
        sleep 3
        health_check
        show_status
        echo -e "${GREEN}[SUCCESS] 后端服务启动完成！${NC}"
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo -e "${RED}[ERROR] 未知命令: $1${NC}"
        echo ""
        show_help
        exit 1
        ;;
esac
