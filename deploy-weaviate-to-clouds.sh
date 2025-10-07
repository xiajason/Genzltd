#!/bin/bash

# Weaviate数据库云端部署脚本
# 支持阿里云开发环境和腾讯云测试环境

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

echo "🚀 Weaviate数据库云端部署脚本"
echo "=================================="
echo -e "${BLUE}目标版本: semitechnologies/weaviate:$WEAVIATE_VERSION${NC}"
echo -e "${BLUE}部署端口: $WEAVIATE_PORT${NC}"
echo ""

# 检查本地Weaviate镜像
check_local_image() {
    echo -e "${BLUE}📋 检查本地Weaviate镜像...${NC}"
    if docker images | grep -q "semitechnologies/weaviate.*$WEAVIATE_VERSION"; then
        echo -e "${GREEN}✅ 本地镜像存在${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️ 本地镜像不存在，开始下载...${NC}"
        docker pull semitechnologies/weaviate:$WEAVIATE_VERSION
        echo -e "${GREEN}✅ 镜像下载完成${NC}"
        return 0
    fi
}

# 导出Weaviate镜像
export_weaviate_image() {
    echo -e "${BLUE}📦 导出Weaviate镜像...${NC}"
    docker save semitechnologies/weaviate:$WEAVIATE_VERSION | gzip > weaviate-$WEAVIATE_VERSION.tar.gz
    echo -e "${GREEN}✅ 镜像导出完成: weaviate-$WEAVIATE_VERSION.tar.gz${NC}"
}

# 部署到阿里云
deploy_to_alibaba() {
    echo -e "${BLUE}☁️ 部署到阿里云开发环境...${NC}"
    
    # 检查SSH连接
    if ! ssh -i $SSH_KEY_ALIBABA -o ConnectTimeout=5 root@$ALIBABA_CLOUD_IP "echo 'SSH连接成功'" > /dev/null 2>&1; then
        echo -e "${RED}❌ 阿里云SSH连接失败${NC}"
        return 1
    fi
    
    # 上传镜像
    echo -e "${BLUE}📤 上传镜像到阿里云...${NC}"
    scp -i $SSH_KEY_ALIBABA weaviate-$WEAVIATE_VERSION.tar.gz root@$ALIBABA_CLOUD_IP:/tmp/
    
    # 停止现有容器
    echo -e "${BLUE}🛑 停止现有Weaviate容器...${NC}"
    ssh -i $SSH_KEY_ALIBABA root@$ALIBABA_CLOUD_IP "docker stop $WEAVIATE_CONTAINER_NAME 2>/dev/null || true"
    ssh -i $SSH_KEY_ALIBABA root@$ALIBABA_CLOUD_IP "docker rm $WEAVIATE_CONTAINER_NAME 2>/dev/null || true"
    
    # 加载镜像
    echo -e "${BLUE}📥 加载镜像到阿里云...${NC}"
    ssh -i $SSH_KEY_ALIBABA root@$ALIBABA_CLOUD_IP "docker load < /tmp/weaviate-$WEAVIATE_VERSION.tar.gz"
    
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
    sleep 10
    
    # 验证部署
    echo -e "${BLUE}🔍 验证Weaviate服务...${NC}"
    if ssh -i $SSH_KEY_ALIBABA root@$ALIBABA_CLOUD_IP "curl -s http://localhost:$WEAVIATE_PORT/v1/meta" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ 阿里云Weaviate部署成功${NC}"
        
        # 显示服务信息
        echo -e "${BLUE}📊 阿里云Weaviate服务信息:${NC}"
        ssh -i $SSH_KEY_ALIBABA root@$ALIBABA_CLOUD_IP "curl -s http://localhost:$WEAVIATE_PORT/v1/meta | jq ."
        
        return 0
    else
        echo -e "${RED}❌ 阿里云Weaviate部署失败${NC}"
        ssh -i $SSH_KEY_ALIBABA root@$ALIBABA_CLOUD_IP "docker logs $WEAVIATE_CONTAINER_NAME"
        return 1
    fi
}

# 部署到腾讯云
deploy_to_tencent() {
    echo -e "${BLUE}☁️ 部署到腾讯云测试环境...${NC}"
    
    # 检查SSH连接
    if ! ssh -i $SSH_KEY_TENCENT -o ConnectTimeout=5 ubuntu@$TENCENT_CLOUD_IP "echo 'SSH连接成功'" > /dev/null 2>&1; then
        echo -e "${RED}❌ 腾讯云SSH连接失败${NC}"
        return 1
    fi
    
    # 上传镜像
    echo -e "${BLUE}📤 上传镜像到腾讯云...${NC}"
    scp -i $SSH_KEY_TENCENT weaviate-$WEAVIATE_VERSION.tar.gz ubuntu@$TENCENT_CLOUD_IP:/tmp/
    
    # 停止现有容器
    echo -e "${BLUE}🛑 停止现有Weaviate容器...${NC}"
    ssh -i $SSH_KEY_TENCENT ubuntu@$TENCENT_CLOUD_IP "docker stop $WEAVIATE_CONTAINER_NAME 2>/dev/null || true"
    ssh -i $SSH_KEY_TENCENT ubuntu@$TENCENT_CLOUD_IP "docker rm $WEAVIATE_CONTAINER_NAME 2>/dev/null || true"
    
    # 加载镜像
    echo -e "${BLUE}📥 加载镜像到腾讯云...${NC}"
    ssh -i $SSH_KEY_TENCENT ubuntu@$TENCENT_CLOUD_IP "docker load < /tmp/weaviate-$WEAVIATE_VERSION.tar.gz"
    
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
    sleep 10
    
    # 验证部署
    echo -e "${BLUE}🔍 验证Weaviate服务...${NC}"
    if ssh -i $SSH_KEY_TENCENT ubuntu@$TENCENT_CLOUD_IP "curl -s http://localhost:$WEAVIATE_PORT/v1/meta" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ 腾讯云Weaviate部署成功${NC}"
        
        # 显示服务信息
        echo -e "${BLUE}📊 腾讯云Weaviate服务信息:${NC}"
        ssh -i $SSH_KEY_TENCENT ubuntu@$TENCENT_CLOUD_IP "curl -s http://localhost:$WEAVIATE_PORT/v1/meta | jq ."
        
        return 0
    else
        echo -e "${RED}❌ 腾讯云Weaviate部署失败${NC}"
        ssh -i $SSH_KEY_TENCENT ubuntu@$TENCENT_CLOUD_IP "docker logs $WEAVIATE_CONTAINER_NAME"
        return 1
    fi
}

# 清理临时文件
cleanup() {
    echo -e "${BLUE}🧹 清理临时文件...${NC}"
    rm -f weaviate-$WEAVIATE_VERSION.tar.gz
    echo -e "${GREEN}✅ 清理完成${NC}"
}

# 主函数
main() {
    echo -e "${BLUE}🎯 开始Weaviate云端部署...${NC}"
    
    # 检查本地镜像
    check_local_image
    
    # 导出镜像
    export_weaviate_image
    
    # 部署到阿里云
    if deploy_to_alibaba; then
        echo -e "${GREEN}✅ 阿里云部署成功${NC}"
    else
        echo -e "${RED}❌ 阿里云部署失败${NC}"
    fi
    
    echo ""
    
    # 部署到腾讯云
    if deploy_to_tencent; then
        echo -e "${GREEN}✅ 腾讯云部署成功${NC}"
    else
        echo -e "${RED}❌ 腾讯云部署失败${NC}"
    fi
    
    # 清理临时文件
    cleanup
    
    echo ""
    echo -e "${GREEN}🎉 Weaviate云端部署完成！${NC}"
    echo -e "${BLUE}📊 部署状态:${NC}"
    echo -e "  阿里云开发环境: $WEAVIATE_CONTAINER_NAME (端口 $WEAVIATE_PORT)"
    echo -e "  腾讯云测试环境: $WEAVIATE_CONTAINER_NAME (端口 $WEAVIATE_PORT)"
    echo ""
    echo -e "${BLUE}🔍 验证命令:${NC}"
    echo -e "  阿里云: ssh -i $SSH_KEY_ALIBABA root@$ALIBABA_CLOUD_IP 'curl http://localhost:$WEAVIATE_PORT/v1/meta'"
    echo -e "  腾讯云: ssh -i $SSH_KEY_TENCENT ubuntu@$TENCENT_CLOUD_IP 'curl http://localhost:$WEAVIATE_PORT/v1/meta'"
}

# 运行主函数
main "$@"
