#!/bin/bash

# 腾讯云数据库部署脚本
# 使用方法: ./deploy_to_tencent.sh [future|dao|blockchain]

VERSION=${1:-future}

if [ ! -d "$VERSION" ]; then
    echo "❌ 版本目录 $VERSION 不存在"
    echo "可用版本: future, dao, blockchain"
    exit 1
fi

echo "🚀 开始部署 $VERSION 版数据库到腾讯云..."

# 进入版本目录
cd $VERSION

# 检查Docker是否运行
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker未运行，请先启动Docker服务"
    exit 1
fi

# 加载镜像
echo "📦 加载数据库镜像..."
for image in *.tar; do
    if [ -f "$image" ]; then
        echo "正在加载 $image..."
        docker load -i "$image"
    fi
done

# 检查是否有docker-compose.yml文件
if [ ! -f "docker-compose.yml" ]; then
    echo "⚠️  未找到docker-compose.yml文件，跳过服务启动"
    echo "请手动创建docker-compose.yml文件或使用TENCENT_CLOUD_DATABASE_INSTALLATION_GUIDE.md中的配置"
    exit 0
fi

# 启动服务
echo "🔧 启动数据库服务..."
docker-compose up -d

# 等待服务启动
echo "⏳ 等待服务启动..."
sleep 10

# 检查服务状态
echo "🔍 检查服务状态..."
docker-compose ps

# 显示连接信息
echo "📋 服务连接信息:"
echo "=================="
case $VERSION in
    "future")
        echo "Future版数据库端口:"
        echo "  MySQL: 3306"
        echo "  PostgreSQL: 5432"
        echo "  Redis: 6379"
        echo "  Neo4j: 7474/7687"
        echo "  MongoDB: 27017"
        echo "  Elasticsearch: 9200"
        echo "  Weaviate: 8082"
        echo "  AI服务数据库: 5435"
        echo "  DAO系统数据库: 9506"
        echo "  企业信用数据库: 7534"
        ;;
    "dao")
        echo "DAO版数据库端口:"
        echo "  MySQL: 3307"
        echo "  PostgreSQL: 5433"
        echo "  Redis: 6380"
        echo "  Neo4j: 7475/7688"
        echo "  MongoDB: 27018"
        echo "  Elasticsearch: 9201"
        echo "  Weaviate: 8083"
        echo "  AI服务数据库: 5436"
        echo "  DAO系统数据库: 9507"
        echo "  企业信用数据库: 7535"
        ;;
    "blockchain")
        echo "区块链版数据库端口:"
        echo "  MySQL: 3308"
        echo "  PostgreSQL: 5434"
        echo "  Redis: 6381"
        echo "  Neo4j: 7476/7689"
        echo "  MongoDB: 27019"
        echo "  Elasticsearch: 9202"
        echo "  Weaviate: 8084"
        echo "  AI服务数据库: 5437"
        echo "  DAO系统数据库: 9508"
        echo "  企业信用数据库: 7536"
        ;;
esac

echo ""
echo "✅ $VERSION 版数据库部署完成！"
echo "💡 提示: 使用 'docker-compose logs -f' 查看服务日志"
echo "💡 提示: 使用 'docker-compose down' 停止服务"
