#!/bin/bash

# Weaviate数据库云端部署脚本 - AMD64架构
# 直接在云端拉取AMD64架构的Weaviate镜像

set -e

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 服务器配置
ALIBABA_CLOUD_IP="47.115.168.107"
TENCENT_CLOUD_IP="101.33.251.158"
SSH_KEY_ALIBABA="~/.ssh/cross_cloud_key"
SSH_KEY_TENCENT="~/.ssh/basic.pem"

# Weaviate配置
WEAVIATE_VERSION="latest"
WEAVIATE_PORT="8082"
WEAVIATE_CONTAINER_NAME="weaviate"

echo "🚀 Weaviate数据库云端部署脚本 (AMD64架构)"
echo "=============================================="
echo -e "${BLUE}目标版本: semitechnologies/weaviate:$WEAVIATE_VERSION (AMD64)${NC}"
echo -e "${BLUE}部署端口: $WEAVIATE_PORT${NC}"
echo ""

# 配置云端Docker镜像源
configure_docker_registry() {
    local server_ip=$1
    local ssh_key=$2
    local user=$3
    
    echo -e "${BLUE}🔧 配置 $server_ip 的Docker镜像源...${NC}"
    
    # 配置阿里云镜像源
    if [ "$server_ip" = "$ALIBABA_CLOUD_IP" ]; then
        ssh -i $ssh_key $user@$server_ip "sudo mkdir -p /etc/docker && echo '{
            \"registry-mirrors\": [
                \"https://registry.cn-hangzhou.aliyuncs.com\",
                \"https://docker.mirrors.ustc.edu.cn\",
                \"https://hub-mirror.c.163.com\"
            ]
        }' | sudo tee /etc/docker/daemon.json && sudo systemctl restart docker"
    else
        # 配置腾讯云镜像源
        ssh -i $ssh_key $user@$server_ip "sudo mkdir -p /etc/docker && echo '{
            \"registry-mirrors\": [
                \"https://mirror.ccs.tencentyun.com\",
                \"https://docker.mirrors.ustc.edu.cn\",
                \"https://hub-mirror.c.163.com\"
            ]
        }' | sudo tee /etc/docker/daemon.json && sudo systemctl restart docker"
    fi
    
    echo -e "${GREEN}✅ Docker镜像源配置完成${NC}"
    sleep 5
}

# 部署到阿里云
deploy_to_alibaba() {
    echo -e "${BLUE}☁️ 部署到阿里云开发环境...${NC}"
    
    # 检查SSH连接
    if ! ssh -i $SSH_KEY_ALIBABA -o ConnectTimeout=5 root@$ALIBABA_CLOUD_IP "echo 'SSH连接成功'" > /dev/null 2>&1; then
        echo -e "${RED}❌ 阿里云SSH连接失败${NC}"
        return 1
    fi
    
    # 配置Docker镜像源
    configure_docker_registry $ALIBABA_CLOUD_IP $SSH_KEY_ALIBABA root
    
    # 停止现有容器
    echo -e "${BLUE}🛑 停止现有Weaviate容器...${NC}"
    ssh -i $SSH_KEY_ALIBABA root@$ALIBABA_CLOUD_IP "docker stop $WEAVIATE_CONTAINER_NAME 2>/dev/null || true"
    ssh -i $SSH_KEY_ALIBABA root@$ALIBABA_CLOUD_IP "docker rm $WEAVIATE_CONTAINER_NAME 2>/dev/null || true"
    
    # 拉取AMD64架构镜像
    echo -e "${BLUE}📥 拉取AMD64架构Weaviate镜像...${NC}"
    ssh -i $SSH_KEY_ALIBABA root@$ALIBABA_CLOUD_IP "docker pull --platform linux/amd64 semitechnologies/weaviate:$WEAVIATE_VERSION"
    
    # 创建数据目录
    echo -e "${BLUE}📁 创建数据目录...${NC}"
    ssh -i $SSH_KEY_ALIBABA root@$ALIBABA_CLOUD_IP "mkdir -p /var/lib/weaviate"
    
    # 启动Weaviate容器
    echo -e "${BLUE}🚀 启动Weaviate容器...${NC}"
    ssh -i $SSH_KEY_ALIBABA root@$ALIBABA_CLOUD_IP "docker run -d \
        --name $WEAVIATE_CONTAINER_NAME \
        --restart unless-stopped \
        -p $WEAVIATE_PORT:8080 \
        -v /var/lib/weaviate:/var/lib/weaviate \
        -e QUERY_DEFAULTS_LIMIT=25 \
        -e AUTHENTICATION_ANONYMOUS_ACCESS_ENABLED=true \
        -e PERSISTENCE_DATA_PATH='/var/lib/weaviate' \
        -e DEFAULT_VECTORIZER_MODULE='none' \
        -e CLUSTER_HOSTNAME='node1' \
        -e HOST='0.0.0.0' \
        -e PORT='8080' \
        semitechnologies/weaviate:$WEAVIATE_VERSION"
    
    # 等待服务启动
    echo -e "${BLUE}⏳ 等待Weaviate服务启动...${NC}"
    sleep 15
    
    # 验证部署
    echo -e "${BLUE}🔍 验证Weaviate服务...${NC}"
    local max_attempts=10
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if ssh -i $SSH_KEY_ALIBABA root@$ALIBABA_CLOUD_IP "curl -s http://localhost:$WEAVIATE_PORT/v1/meta" > /dev/null 2>&1; then
            echo -e "${GREEN}✅ 阿里云Weaviate部署成功${NC}"
            
            # 显示服务信息
            echo -e "${BLUE}📊 阿里云Weaviate服务信息:${NC}"
            ssh -i $SSH_KEY_ALIBABA root@$ALIBABA_CLOUD_IP "curl -s http://localhost:$WEAVIATE_PORT/v1/meta"
            
            return 0
        else
            echo -e "${YELLOW}⏳ 尝试 $attempt/$max_attempts: 等待服务启动...${NC}"
            sleep 5
            ((attempt++))
        fi
    done
    
    echo -e "${RED}❌ 阿里云Weaviate部署失败 - 服务启动超时${NC}"
    ssh -i $SSH_KEY_ALIBABA root@$ALIBABA_CLOUD_IP "docker logs $WEAVIATE_CONTAINER_NAME"
    return 1
}

# 部署到腾讯云
deploy_to_tencent() {
    echo -e "${BLUE}☁️ 部署到腾讯云测试环境...${NC}"
    
    # 检查SSH连接
    if ! ssh -i $SSH_KEY_TENCENT -o ConnectTimeout=5 ubuntu@$TENCENT_CLOUD_IP "echo 'SSH连接成功'" > /dev/null 2>&1; then
        echo -e "${RED}❌ 腾讯云SSH连接失败${NC}"
        return 1
    fi
    
    # 配置Docker镜像源
    configure_docker_registry $TENCENT_CLOUD_IP $SSH_KEY_TENCENT ubuntu
    
    # 停止现有容器
    echo -e "${BLUE}🛑 停止现有Weaviate容器...${NC}"
    ssh -i $SSH_KEY_TENCENT ubuntu@$TENCENT_CLOUD_IP "docker stop $WEAVIATE_CONTAINER_NAME 2>/dev/null || true"
    ssh -i $SSH_KEY_TENCENT ubuntu@$TENCENT_CLOUD_IP "docker rm $WEAVIATE_CONTAINER_NAME 2>/dev/null || true"
    
    # 拉取AMD64架构镜像
    echo -e "${BLUE}📥 拉取AMD64架构Weaviate镜像...${NC}"
    ssh -i $SSH_KEY_TENCENT ubuntu@$TENCENT_CLOUD_IP "docker pull --platform linux/amd64 semitechnologies/weaviate:$WEAVIATE_VERSION"
    
    # 创建数据目录
    echo -e "${BLUE}📁 创建数据目录...${NC}"
    ssh -i $SSH_KEY_TENCENT ubuntu@$TENCENT_CLOUD_IP "sudo mkdir -p /var/lib/weaviate && sudo chown ubuntu:ubuntu /var/lib/weaviate"
    
    # 启动Weaviate容器
    echo -e "${BLUE}🚀 启动Weaviate容器...${NC}"
    ssh -i $SSH_KEY_TENCENT ubuntu@$TENCENT_CLOUD_IP "docker run -d \
        --name $WEAVIATE_CONTAINER_NAME \
        --restart unless-stopped \
        -p $WEAVIATE_PORT:8080 \
        -v /var/lib/weaviate:/var/lib/weaviate \
        -e QUERY_DEFAULTS_LIMIT=25 \
        -e AUTHENTICATION_ANONYMOUS_ACCESS_ENABLED=true \
        -e PERSISTENCE_DATA_PATH='/var/lib/weaviate' \
        -e DEFAULT_VECTORIZER_MODULE='none' \
        -e CLUSTER_HOSTNAME='node1' \
        -e HOST='0.0.0.0' \
        -e PORT='8080' \
        semitechnologies/weaviate:$WEAVIATE_VERSION"
    
    # 等待服务启动
    echo -e "${BLUE}⏳ 等待Weaviate服务启动...${NC}"
    sleep 15
    
    # 验证部署
    echo -e "${BLUE}🔍 验证Weaviate服务...${NC}"
    local max_attempts=10
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if ssh -i $SSH_KEY_TENCENT ubuntu@$TENCENT_CLOUD_IP "curl -s http://localhost:$WEAVIATE_PORT/v1/meta" > /dev/null 2>&1; then
            echo -e "${GREEN}✅ 腾讯云Weaviate部署成功${NC}"
            
            # 显示服务信息
            echo -e "${BLUE}📊 腾讯云Weaviate服务信息:${NC}"
            ssh -i $SSH_KEY_TENCENT ubuntu@$TENCENT_CLOUD_IP "curl -s http://localhost:$WEAVIATE_PORT/v1/meta"
            
            return 0
        else
            echo -e "${YELLOW}⏳ 尝试 $attempt/$max_attempts: 等待服务启动...${NC}"
            sleep 5
            ((attempt++))
        fi
    done
    
    echo -e "${RED}❌ 腾讯云Weaviate部署失败 - 服务启动超时${NC}"
    ssh -i $SSH_KEY_TENCENT ubuntu@$TENCENT_CLOUD_IP "docker logs $WEAVIATE_CONTAINER_NAME"
    return 1
}

# 主函数
main() {
    echo -e "${BLUE}🎯 开始Weaviate云端部署 (AMD64架构)...${NC}"
    
    local alibaba_success=false
    local tencent_success=false
    
    # 部署到阿里云
    if deploy_to_alibaba; then
        alibaba_success=true
        echo -e "${GREEN}✅ 阿里云部署成功${NC}"
    else
        echo -e "${RED}❌ 阿里云部署失败${NC}"
    fi
    
    echo ""
    
    # 部署到腾讯云
    if deploy_to_tencent; then
        tencent_success=true
        echo -e "${GREEN}✅ 腾讯云部署成功${NC}"
    else
        echo -e "${RED}❌ 腾讯云部署失败${NC}"
    fi
    
    echo ""
    echo -e "${GREEN}🎉 Weaviate云端部署完成！${NC}"
    echo -e "${BLUE}📊 部署状态:${NC}"
    echo -e "  阿里云开发环境: $([ $alibaba_success = true ] && echo "✅ 成功" || echo "❌ 失败") (端口 $WEAVIATE_PORT)"
    echo -e "  腾讯云测试环境: $([ $tencent_success = true ] && echo "✅ 成功" || echo "❌ 失败") (端口 $WEAVIATE_PORT)"
    echo ""
    echo -e "${BLUE}🔍 验证命令:${NC}"
    echo -e "  阿里云: ssh -i $SSH_KEY_ALIBABA root@$ALIBABA_CLOUD_IP 'curl http://localhost:$WEAVIATE_PORT/v1/meta'"
    echo -e "  腾讯云: ssh -i $SSH_KEY_TENCENT ubuntu@$TENCENT_CLOUD_IP 'curl http://localhost:$WEAVIATE_PORT/v1/meta'"
    
    # 返回适当的退出码
    if [ $alibaba_success = true ] && [ $tencent_success = true ]; then
        exit 0
    else
        exit 1
    fi
}

# 运行主函数
main "$@"
