#!/bin/bash

# 简化版数据库镜像下载脚本
# 只下载镜像，不创建配置文件

echo "🚀 开始下载数据库镜像..."

# 定义数据库镜像列表
declare -A DATABASE_IMAGES=(
    ["mysql"]="mysql:8.0.35"
    ["postgres"]="postgres:15.5"
    ["redis"]="redis:7.2-alpine"
    ["neo4j"]="neo4j:5.15.0"
    ["mongodb"]="mongo:7.0.4"
    ["elasticsearch"]="elasticsearch:8.11.1"
    ["weaviate"]="semitechnologies/weaviate:1.21.5"
    ["ai-service-db"]="postgres:15.5"
    ["dao-system-db"]="postgres:15.5"
    ["enterprise-credit-db"]="postgres:15.5"
)

# 下载并保存镜像
for db in "${!DATABASE_IMAGES[@]}"; do
    image="${DATABASE_IMAGES[$db]}"
    echo "📦 正在下载 $image ($db)..."
    docker pull $image
    
    # 保存到future目录
    echo "💾 保存到 future/${db}.tar"
    docker save $image -o future/${db}.tar
    
    # 保存到dao目录
    echo "💾 保存到 dao/${db}.tar"
    docker save $image -o dao/${db}.tar
    
    # 保存到blockchain目录
    echo "💾 保存到 blockchain/${db}.tar"
    docker save $image -o blockchain/${db}.tar
done

echo "✅ 所有数据库镜像下载完成！"
echo "📊 镜像统计:"
echo "  - 镜像数量: ${#DATABASE_IMAGES[@]} 个"
echo "  - 版本数量: 3 个 (future, dao, blockchain)"
echo "  - 总文件数: $((${#DATABASE_IMAGES[@]} * 3)) 个"
echo "  - 总大小: 约3-15GB (取决于压缩率)"
echo ""
echo "📁 文件位置:"
ls -la future/ dao/ blockchain/
