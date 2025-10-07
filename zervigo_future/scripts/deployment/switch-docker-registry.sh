#!/bin/bash

# Docker镜像源切换脚本
# 用于在不同镜像源之间切换，提高部署速度

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 镜像源配置
ALIYUN_REGISTRY="registry.cn-hangzhou.aliyuncs.com/library"
TENCENT_REGISTRY="ccr.ccs.tencentyun.com/library"
NETEASE_REGISTRY="hub-mirror.c.163.com"
USTC_REGISTRY="docker.mirrors.ustc.edu.cn"
DOCKER_HUB=""

# 显示帮助信息
show_help() {
    echo -e "${BLUE}Docker镜像源切换脚本${NC}"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -a, --aliyun     使用阿里云镜像源 (默认)"
    echo "  -t, --tencent    使用腾讯云镜像源"
    echo "  -n, --netease    使用网易云镜像源"
    echo "  -u, --ustc       使用中科大镜像源"
    echo "  -d, --dockerhub  使用Docker Hub官方源"
    echo "  -l, --list       列出所有可用的镜像源"
    echo "  -h, --help       显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 --aliyun      # 切换到阿里云镜像源"
    echo "  $0 --tencent     # 切换到腾讯云镜像源"
    echo "  $0 --list        # 列出所有镜像源"
}

# 列出所有镜像源
list_registries() {
    echo -e "${BLUE}可用的Docker镜像源:${NC}"
    echo ""
    echo "1. 阿里云镜像源 (aliyun)"
    echo "   ${ALIYUN_REGISTRY}"
    echo "   推荐用于国内部署，速度快，稳定性好"
    echo ""
    echo "2. 腾讯云镜像源 (tencent)"
    echo "   ${TENCENT_REGISTRY}"
    echo "   适合腾讯云环境，与腾讯云服务集成好"
    echo ""
    echo "3. 网易云镜像源 (netease)"
    echo "   ${NETEASE_REGISTRY}"
    echo "   网易提供的镜像源，速度较快"
    echo ""
    echo "4. 中科大镜像源 (ustc)"
    echo "   ${USTC_REGISTRY}"
    echo "   中科大提供的镜像源，教育网用户推荐"
    echo ""
    echo "5. Docker Hub官方源 (dockerhub)"
    echo "   官方源，国外访问速度快"
}

# 更新docker-compose文件中的镜像源
update_docker_compose() {
    local registry=$1
    local files=("docker-compose.yml" "docker-compose.production.yml")
    
    echo -e "${YELLOW}正在更新docker-compose文件...${NC}"
    
    for file in "${files[@]}"; do
        if [[ -f "$file" ]]; then
            echo -e "${BLUE}更新文件: $file${NC}"
            
            # 备份原文件
            cp "$file" "${file}.backup.$(date +%Y%m%d_%H%M%S)"
            
            # 更新镜像源
            if [[ -n "$registry" ]]; then
                sed -i.tmp "s|registry\.cn-hangzhou\.aliyuncs\.com/library|$registry|g" "$file"
                sed -i.tmp "s|ccr\.ccs\.tencentyun\.com/library|$registry|g" "$file"
                sed -i.tmp "s|hub-mirror\.c\.163\.com|$registry|g" "$file"
                sed -i.tmp "s|docker\.mirrors\.ustc\.edu\.cn|$registry|g" "$file"
                rm -f "${file}.tmp"
            else
                # 恢复为官方源
                sed -i.tmp "s|registry\.cn-hangzhou\.aliyuncs\.com/library/||g" "$file"
                sed -i.tmp "s|ccr\.ccs\.tencentyun\.com/library/||g" "$file"
                sed -i.tmp "s|hub-mirror\.c\.163\.com/||g" "$file"
                sed -i.tmp "s|docker\.mirrors\.ustc\.edu\.cn/||g" "$file"
                rm -f "${file}.tmp"
            fi
            
            echo -e "${GREEN}✓ $file 更新完成${NC}"
        else
            echo -e "${RED}⚠ 文件不存在: $file${NC}"
        fi
    done
}

# 更新Dockerfile中的镜像源
update_dockerfile() {
    local registry=$1
    local dockerfiles=("backend/Dockerfile" "backend/internal/ai-service/Dockerfile")
    
    echo -e "${YELLOW}正在更新Dockerfile文件...${NC}"
    
    for dockerfile in "${dockerfiles[@]}"; do
        if [[ -f "$dockerfile" ]]; then
            echo -e "${BLUE}更新文件: $dockerfile${NC}"
            
            # 备份原文件
            cp "$dockerfile" "${dockerfile}.backup.$(date +%Y%m%d_%H%M%S)"
            
            # 更新镜像源
            if [[ -n "$registry" ]]; then
                sed -i.tmp "s|FROM registry\.cn-hangzhou\.aliyuncs\.com/library/|FROM $registry/|g" "$dockerfile"
                sed -i.tmp "s|FROM ccr\.ccs\.tencentyun\.com/library/|FROM $registry/|g" "$dockerfile"
                sed -i.tmp "s|FROM hub-mirror\.c\.163\.com/|FROM $registry/|g" "$dockerfile"
                sed -i.tmp "s|FROM docker\.mirrors\.ustc\.edu\.cn/|FROM $registry/|g" "$dockerfile"
                rm -f "${dockerfile}.tmp"
            else
                # 恢复为官方源
                sed -i.tmp "s|FROM registry\.cn-hangzhou\.aliyuncs\.com/library/|FROM |g" "$dockerfile"
                sed -i.tmp "s|FROM ccr\.ccs\.tencentyun\.com/library/|FROM |g" "$dockerfile"
                sed -i.tmp "s|FROM hub-mirror\.c\.163\.com/|FROM |g" "$dockerfile"
                sed -i.tmp "s|FROM docker\.mirrors\.ustc\.edu\.cn/|FROM |g" "$dockerfile"
                rm -f "${dockerfile}.tmp"
            fi
            
            echo -e "${GREEN}✓ $dockerfile 更新完成${NC}"
        else
            echo -e "${RED}⚠ 文件不存在: $dockerfile${NC}"
        fi
    done
}

# 测试镜像源连接
test_registry() {
    local registry=$1
    
    if [[ -z "$registry" ]]; then
        echo -e "${BLUE}测试Docker Hub连接...${NC}"
        if docker pull hello-world >/dev/null 2>&1; then
            echo -e "${GREEN}✓ Docker Hub连接正常${NC}"
        else
            echo -e "${RED}✗ Docker Hub连接失败${NC}"
        fi
    else
        echo -e "${BLUE}测试镜像源连接: $registry${NC}"
        if docker pull "${registry}/hello-world" >/dev/null 2>&1; then
            echo -e "${GREEN}✓ 镜像源连接正常${NC}"
        else
            echo -e "${RED}✗ 镜像源连接失败${NC}"
        fi
    fi
}

# 主函数
main() {
    local registry=""
    local action=""
    
    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -a|--aliyun)
                registry="$ALIYUN_REGISTRY"
                action="switch"
                shift
                ;;
            -t|--tencent)
                registry="$TENCENT_REGISTRY"
                action="switch"
                shift
                ;;
            -n|--netease)
                registry="$NETEASE_REGISTRY"
                action="switch"
                shift
                ;;
            -u|--ustc)
                registry="$USTC_REGISTRY"
                action="switch"
                shift
                ;;
            -d|--dockerhub)
                registry=""
                action="switch"
                shift
                ;;
            -l|--list)
                action="list"
                shift
                ;;
            -h|--help)
                action="help"
                shift
                ;;
            *)
                echo -e "${RED}未知选项: $1${NC}"
                show_help
                exit 1
                ;;
        esac
    done
    
    # 默认使用阿里云镜像源
    if [[ -z "$action" ]]; then
        registry="$ALIYUN_REGISTRY"
        action="switch"
    fi
    
    # 执行相应操作
    case $action in
        help)
            show_help
            ;;
        list)
            list_registries
            ;;
        switch)
            echo -e "${BLUE}正在切换到镜像源...${NC}"
            if [[ -n "$registry" ]]; then
                echo -e "${YELLOW}目标镜像源: $registry${NC}"
            else
                echo -e "${YELLOW}目标镜像源: Docker Hub官方源${NC}"
            fi
            
            # 测试连接
            test_registry "$registry"
            
            # 更新配置文件
            update_docker_compose "$registry"
            update_dockerfile "$registry"
            
            echo -e "${GREEN}✓ 镜像源切换完成${NC}"
            echo -e "${BLUE}提示: 请重新构建Docker镜像以使用新的镜像源${NC}"
            ;;
    esac
}

# 检查Docker是否安装
if ! command -v docker &> /dev/null; then
    echo -e "${RED}错误: Docker未安装或未在PATH中找到${NC}"
    exit 1
fi

# 运行主函数
main "$@"
