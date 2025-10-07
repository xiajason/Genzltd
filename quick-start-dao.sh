#!/bin/bash
# DAO版三环境快速启动脚本

echo "🚀 DAO版三环境快速启动脚本"
echo "=================================="

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🎯 选择启动模式:${NC}"
echo "1. 🏠 仅启动本地开发环境"
echo "2. 🌐 仅启动腾讯云集成环境"
echo "3. ☁️ 仅启动阿里云生产环境"
echo "4. 🚀 启动所有环境 (本地 + 腾讯云 + 阿里云)"
echo "5. 📊 检查所有环境状态"
echo "6. 🎛️ 打开环境管理器"
echo "0. ❌ 退出"
echo "=================================="

read -p "请选择模式 (0-6): " mode

case $mode in
    1)
        echo -e "${GREEN}🏠 启动本地开发环境...${NC}"
        ./start-dao-development.sh
        echo ""
        echo -e "${GREEN}✅ 本地开发环境启动完成！${NC}"
        echo "🌐 访问地址:"
        echo "  - MySQL: localhost:9506"
        echo "  - Redis: localhost:9507"
        ;;
    2)
        echo -e "${GREEN}🌐 部署腾讯云集成环境...${NC}"
        ./deploy-dao-tencent.sh
        echo ""
        echo -e "${GREEN}✅ 腾讯云集成环境部署完成！${NC}"
        echo "🌐 访问地址:"
        echo "  - DAO Resume服务: http://101.33.251.158:9502"
        echo "  - DAO Job服务: http://101.33.251.158:7531"
        echo "  - DAO治理服务: http://101.33.251.158:9503"
        echo "  - DAO AI服务: http://101.33.251.158:8206"
        echo "  - 监控面板: http://101.33.251.158:3000"
        ;;
    3)
        echo -e "${GREEN}☁️ 部署阿里云生产环境...${NC}"
        ./deploy-dao-alibaba.sh
        echo ""
        echo -e "${GREEN}✅ 阿里云生产环境部署完成！${NC}"
        echo "🌐 访问地址:"
        echo "  - DAO治理服务: http://47.115.168.107:9503"
        echo "  - DAO投票服务: http://47.115.168.107:9504"
        echo "  - DAO提案服务: http://47.115.168.107:9505"
        echo "  - DAO奖励服务: http://47.115.168.107:9506"
        echo "  - 监控面板: http://47.115.168.107:9515"
        ;;
    4)
        echo -e "${GREEN}🚀 启动所有环境...${NC}"
        
        echo -e "${YELLOW}步骤 1/3: 启动本地开发环境${NC}"
        ./start-dao-development.sh
        sleep 5
        
        echo -e "${YELLOW}步骤 2/3: 部署腾讯云集成环境${NC}"
        ./deploy-dao-tencent.sh
        sleep 5
        
        echo -e "${YELLOW}步骤 3/3: 部署阿里云生产环境${NC}"
        ./deploy-dao-alibaba.sh
        
        echo ""
        echo -e "${GREEN}🎉 所有环境启动完成！${NC}"
        echo ""
        echo "🌐 环境访问地址:"
        echo "🏠 本地开发环境:"
        echo "  - MySQL: localhost:9506"
        echo "  - Redis: localhost:9507"
        echo ""
        echo "🌐 腾讯云集成环境:"
        echo "  - DAO Resume服务: http://101.33.251.158:9502"
        echo "  - DAO Job服务: http://101.33.251.158:7531"
        echo "  - DAO治理服务: http://101.33.251.158:9503"
        echo "  - DAO AI服务: http://101.33.251.158:8206"
        echo "  - 监控面板: http://101.33.251.158:3000"
        echo ""
        echo "☁️ 阿里云生产环境:"
        echo "  - DAO治理服务: http://47.115.168.107:9503"
        echo "  - DAO投票服务: http://47.115.168.107:9504"
        echo "  - DAO提案服务: http://47.115.168.107:9505"
        echo "  - DAO奖励服务: http://47.115.168.107:9506"
        echo "  - 监控面板: http://47.115.168.107:9515"
        ;;
    5)
        echo -e "${GREEN}📊 检查所有环境状态...${NC}"
        ./dao-environment-manager.sh
        ;;
    6)
        echo -e "${GREEN}🎛️ 打开环境管理器...${NC}"
        ./dao-environment-manager.sh
        ;;
    0)
        echo -e "${GREEN}👋 退出${NC}"
        exit 0
        ;;
    *)
        echo -e "${RED}❌ 无效选择${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${BLUE}🎯 下一步操作:${NC}"
echo "1. 使用 ./dao-environment-manager.sh 管理环境"
echo "2. 使用 ./health-check-dao-local.sh 检查本地环境"
echo "3. 查看 RESUME_JOB_DAO_OPTIMAL_DEV_ENVIRONMENT.md 了解详细配置"
echo ""
echo -e "${GREEN}🚀 DAO版三环境协同架构已就绪！${NC}"
