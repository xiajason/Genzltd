#!/bin/bash
# DAO版简化环境管理器 - 替代有问题的dao-environment-manager.sh

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🎛️  DAO版简化环境管理器${NC}"
echo "=================================="
echo "1. 🏠 本地开发环境管理"
echo "2. 🌐 腾讯云集成环境管理"
echo "3. ☁️ 阿里云生产环境管理"
echo "4. 📊 三环境状态检查"
echo "5. 🔄 数据同步到云端"
echo "6. 📋 查看环境日志"
echo "7. 🧹 清理环境资源"
echo "8. 📚 查看环境信息"
echo "0. ❌ 退出"
echo "=================================="

read -p "请选择操作 (0-8): " choice

case $choice in
    1)
        echo -e "${GREEN}启动本地开发环境...${NC}"
        ./start-dao-development.sh
        ;;
    2)
        echo -e "${GREEN}部署腾讯云集成环境...${NC}"
        ./deploy-dao-tencent-native.sh
        ;;
    3)
        echo -e "${GREEN}部署阿里云生产环境...${NC}"
        ./deploy-dao-alibaba.sh
        ;;
    4)
        echo -e "${GREEN}检查三环境状态...${NC}"
        ./health-check-all-environments.sh
        ;;
    5)
        echo -e "${GREEN}同步数据到云端...${NC}"
        ./sync-dao-data-to-clouds.sh
        ;;
    6)
        echo -e "${GREEN}查看环境日志...${NC}"
        echo "本地环境日志:"
        docker logs dao-mysql-local --tail 10
        echo "Redis日志:"
        docker logs dao-redis-local --tail 10
        ;;
    7)
        echo -e "${YELLOW}清理环境资源...${NC}"
        read -p "确定要清理本地环境吗? (y/N): " confirm
        if [[ $confirm == [yY] ]]; then
            docker-compose -f looma_crm_future/services/dao_services/docker-compose.local.yml down
            echo "本地环境已清理"
        fi
        ;;
    8)
        echo -e "${BLUE}环境信息:${NC}"
        echo "本地环境:"
        docker ps | grep dao-
        echo "系统资源:"
        df -h | head -2
        free -h | head -2
        ;;
    0)
        echo -e "${GREEN}退出管理器${NC}"
        exit 0
        ;;
    *)
        echo -e "${RED}❌ 无效选择，请重新运行脚本${NC}"
        exit 1
        ;;
esac

echo -e "${GREEN}操作完成${NC}"
