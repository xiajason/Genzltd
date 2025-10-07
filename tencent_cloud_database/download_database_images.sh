#!/bin/bash

# 腾讯云数据库镜像下载脚本
# 创建时间: 2025年1月28日
# 目标: 下载所有需要的数据库镜像到本地备用

echo "🚀 开始下载腾讯云数据库镜像..."

# 创建镜像保存目录
mkdir -p future dao blockchain

# 定义数据库镜像列表
declare -A DATABASE_IMAGES=(
    # Future版数据库镜像
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

# 下载Future版数据库镜像
echo "📦 下载Future版数据库镜像..."
for db in "${!DATABASE_IMAGES[@]}"; do
    echo "正在下载 ${DATABASE_IMAGES[$db]}..."
    docker pull ${DATABASE_IMAGES[$db]}
    
    # 保存镜像到文件
    echo "保存镜像到 future/${db}.tar..."
    docker save ${DATABASE_IMAGES[$db]} -o future/${db}.tar
done

# 下载DAO版数据库镜像 (使用相同版本，但端口不同)
echo "📦 下载DAO版数据库镜像..."
for db in "${!DATABASE_IMAGES[@]}"; do
    echo "正在下载 ${DATABASE_IMAGES[$db]} (DAO版)..."
    docker pull ${DATABASE_IMAGES[$db]}
    
    # 保存镜像到文件
    echo "保存镜像到 dao/${db}.tar..."
    docker save ${DATABASE_IMAGES[$db]} -o dao/${db}.tar
done

# 下载区块链版数据库镜像 (使用相同版本，但端口不同)
echo "📦 下载区块链版数据库镜像..."
for db in "${!DATABASE_IMAGES[@]}"; do
    echo "正在下载 ${DATABASE_IMAGES[$db]} (区块链版)..."
    docker pull ${DATABASE_IMAGES[$db]}
    
    # 保存镜像到文件
    echo "保存镜像到 blockchain/${db}.tar..."
    docker save ${DATABASE_IMAGES[$db]} -o blockchain/${db}.tar
done

# 下载Docker Compose文件
echo "📄 下载Docker Compose文件..."

# Future版Docker Compose
cat > future/docker-compose.yml << 'EOF'
version: '3.8'

services:
  # Future版MySQL (端口3306)
  f-mysql:
    image: mysql:8.0.35
    container_name: f-mysql
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: f_mysql_root_2025
      MYSQL_DATABASE: f_mysql
      MYSQL_USER: f_mysql_user
      MYSQL_PASSWORD: f_mysql_password_2025
    ports:
      - "3306:3306"
    volumes:
      - f_mysql_data:/var/lib/mysql
    networks:
      - f-network

  # Future版PostgreSQL (端口5432)
  f-postgres:
    image: postgres:15.5
    container_name: f-postgres
    restart: always
    environment:
      POSTGRES_DB: f_pg
      POSTGRES_USER: f_pg_user
      POSTGRES_PASSWORD: f_pg_password_2025
    ports:
      - "5432:5432"
    volumes:
      - f_postgres_data:/var/lib/postgresql/data
    networks:
      - f-network

  # Future版Redis (端口6379)
  f-redis:
    image: redis:7.2-alpine
    container_name: f-redis
    restart: always
    command: redis-server --requirepass f_redis_password_2025
    ports:
      - "6379:6379"
    volumes:
      - f_redis_data:/data
    networks:
      - f-network

  # Future版Neo4j (端口7474/7687)
  f-neo4j:
    image: neo4j:5.15.0
    container_name: f-neo4j
    restart: always
    environment:
      NEO4J_AUTH: neo4j/f_neo4j_password_2025
      NEO4J_dbms_security_auth__enabled: "true"
    ports:
      - "7474:7474"
      - "7687:7687"
    volumes:
      - f_neo4j_data:/data
      - f_neo4j_logs:/logs
      - f_neo4j_import:/var/lib/neo4j/import
      - f_neo4j_plugins:/plugins
    networks:
      - f-network

  # Future版MongoDB (端口27017)
  f-mongodb:
    image: mongo:7.0.4
    container_name: f-mongodb
    restart: always
    environment:
      MONGO_INITDB_ROOT_USERNAME: f_mongo_admin
      MONGO_INITDB_ROOT_PASSWORD: f_mongo_password_2025
      MONGO_INITDB_DATABASE: f_mongo
    ports:
      - "27017:27017"
    volumes:
      - f_mongodb_data:/data/db
    networks:
      - f-network

  # Future版Elasticsearch (端口9200)
  f-elasticsearch:
    image: elasticsearch:8.11.1
    container_name: f-elasticsearch
    restart: always
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    ports:
      - "9200:9200"
    volumes:
      - f_elasticsearch_data:/usr/share/elasticsearch/data
    networks:
      - f-network

  # Future版Weaviate (端口8082)
  f-weaviate:
    image: semitechnologies/weaviate:1.21.5
    container_name: f-weaviate
    restart: always
    environment:
      QUERY_DEFAULTS_LIMIT: 25
      AUTHENTICATION_ANONYMOUS_ACCESS_ENABLED: 'true'
      PERSISTENCE_DATA_PATH: '/var/lib/weaviate'
      DEFAULT_VECTORIZER_MODULE: 'none'
      ENABLE_MODULES: 'text2vec-cohere,text2vec-huggingface,text2vec-palm,text2vec-openai,generative-openai,generative-cohere,generative-palm,ref2vec-centroid,reranker-cohere,qna-openai'
      CLUSTER_HOSTNAME: 'node1'
    ports:
      - "8082:8080"
    volumes:
      - f_weaviate_data:/var/lib/weaviate
    networks:
      - f-network

  # Future版AI服务数据库 (端口5435)
  f-ai-service-db:
    image: postgres:15.5
    container_name: f-ai-service-db
    restart: always
    environment:
      POSTGRES_DB: f_ai
      POSTGRES_USER: f_ai_user
      POSTGRES_PASSWORD: f_ai_password_2025
    ports:
      - "5435:5432"
    volumes:
      - f_ai_service_data:/var/lib/postgresql/data
    networks:
      - f-network

  # Future版DAO系统数据库 (端口9506)
  f-dao-system-db:
    image: postgres:15.5
    container_name: f-dao-system-db
    restart: always
    environment:
      POSTGRES_DB: f_dao
      POSTGRES_USER: f_dao_user
      POSTGRES_PASSWORD: f_dao_password_2025
    ports:
      - "9506:5432"
    volumes:
      - f_dao_system_data:/var/lib/postgresql/data
    networks:
      - f-network

  # Future版企业信用数据库 (端口7534)
  f-enterprise-credit-db:
    image: postgres:15.5
    container_name: f-enterprise-credit-db
    restart: always
    environment:
      POSTGRES_DB: f_credit
      POSTGRES_USER: f_credit_user
      POSTGRES_PASSWORD: f_credit_password_2025
    ports:
      - "7534:5432"
    volumes:
      - f_enterprise_credit_data:/var/lib/postgresql/data
    networks:
      - f-network

volumes:
  f_mysql_data:
  f_postgres_data:
  f_redis_data:
  f_neo4j_data:
  f_neo4j_logs:
  f_neo4j_import:
  f_neo4j_plugins:
  f_mongodb_data:
  f_elasticsearch_data:
  f_weaviate_data:
  f_ai_service_data:
  f_dao_system_data:
  f_enterprise_credit_data:

networks:
  f-network:
    driver: bridge
EOF

# DAO版Docker Compose
cat > dao/docker-compose.yml << 'EOF'
version: '3.8'

services:
  # DAO版MySQL (端口3307)
  d-mysql:
    image: mysql:8.0.35
    container_name: d-mysql
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: d_mysql_root_2025
      MYSQL_DATABASE: d_mysql
      MYSQL_USER: d_mysql_user
      MYSQL_PASSWORD: d_mysql_password_2025
    ports:
      - "3307:3306"
    volumes:
      - d_mysql_data:/var/lib/mysql
    networks:
      - d-network

  # DAO版PostgreSQL (端口5433)
  d-postgres:
    image: postgres:15.5
    container_name: d-postgres
    restart: always
    environment:
      POSTGRES_DB: d_pg
      POSTGRES_USER: d_pg_user
      POSTGRES_PASSWORD: d_pg_password_2025
    ports:
      - "5433:5432"
    volumes:
      - d_postgres_data:/var/lib/postgresql/data
    networks:
      - d-network

  # DAO版Redis (端口6380)
  d-redis:
    image: redis:7.2-alpine
    container_name: d-redis
    restart: always
    command: redis-server --requirepass d_redis_password_2025
    ports:
      - "6380:6379"
    volumes:
      - d_redis_data:/data
    networks:
      - d-network

  # DAO版Neo4j (端口7475/7688)
  d-neo4j:
    image: neo4j:5.15.0
    container_name: d-neo4j
    restart: always
    environment:
      NEO4J_AUTH: neo4j/d_neo4j_password_2025
      NEO4J_dbms_security_auth__enabled: "true"
    ports:
      - "7475:7474"
      - "7688:7687"
    volumes:
      - d_neo4j_data:/data
      - d_neo4j_logs:/logs
      - d_neo4j_import:/var/lib/neo4j/import
      - d_neo4j_plugins:/plugins
    networks:
      - d-network

  # DAO版MongoDB (端口27018)
  d-mongodb:
    image: mongo:7.0.4
    container_name: d-mongodb
    restart: always
    environment:
      MONGO_INITDB_ROOT_USERNAME: d_mongo_admin
      MONGO_INITDB_ROOT_PASSWORD: d_mongo_password_2025
      MONGO_INITDB_DATABASE: d_mongo
    ports:
      - "27018:27017"
    volumes:
      - d_mongodb_data:/data/db
    networks:
      - d-network

  # DAO版Elasticsearch (端口9201)
  d-elasticsearch:
    image: elasticsearch:8.11.1
    container_name: d-elasticsearch
    restart: always
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    ports:
      - "9201:9200"
    volumes:
      - d_elasticsearch_data:/usr/share/elasticsearch/data
    networks:
      - d-network

  # DAO版Weaviate (端口8083)
  d-weaviate:
    image: semitechnologies/weaviate:1.21.5
    container_name: d-weaviate
    restart: always
    environment:
      QUERY_DEFAULTS_LIMIT: 25
      AUTHENTICATION_ANONYMOUS_ACCESS_ENABLED: 'true'
      PERSISTENCE_DATA_PATH: '/var/lib/weaviate'
      DEFAULT_VECTORIZER_MODULE: 'none'
      ENABLE_MODULES: 'text2vec-cohere,text2vec-huggingface,text2vec-palm,text2vec-openai,generative-openai,generative-cohere,generative-palm,ref2vec-centroid,reranker-cohere,qna-openai'
      CLUSTER_HOSTNAME: 'node1'
    ports:
      - "8083:8080"
    volumes:
      - d_weaviate_data:/var/lib/weaviate
    networks:
      - d-network

  # DAO版AI服务数据库 (端口5436)
  d-ai-service-db:
    image: postgres:15.5
    container_name: d-ai-service-db
    restart: always
    environment:
      POSTGRES_DB: d_ai
      POSTGRES_USER: d_ai_user
      POSTGRES_PASSWORD: d_ai_password_2025
    ports:
      - "5436:5432"
    volumes:
      - d_ai_service_data:/var/lib/postgresql/data
    networks:
      - d-network

  # DAO版DAO系统数据库 (端口9507)
  d-dao-system-db:
    image: postgres:15.5
    container_name: d-dao-system-db
    restart: always
    environment:
      POSTGRES_DB: d_dao
      POSTGRES_USER: d_dao_user
      POSTGRES_PASSWORD: d_dao_password_2025
    ports:
      - "9507:5432"
    volumes:
      - d_dao_system_data:/var/lib/postgresql/data
    networks:
      - d-network

  # DAO版企业信用数据库 (端口7535)
  d-enterprise-credit-db:
    image: postgres:15.5
    container_name: d-enterprise-credit-db
    restart: always
    environment:
      POSTGRES_DB: d_credit
      POSTGRES_USER: d_credit_user
      POSTGRES_PASSWORD: d_credit_password_2025
    ports:
      - "7535:5432"
    volumes:
      - d_enterprise_credit_data:/var/lib/postgresql/data
    networks:
      - d-network

volumes:
  d_mysql_data:
  d_postgres_data:
  d_redis_data:
  d_neo4j_data:
  d_neo4j_logs:
  d_neo4j_import:
  d_neo4j_plugins:
  d_mongodb_data:
  d_elasticsearch_data:
  d_weaviate_data:
  d_ai_service_data:
  d_dao_system_data:
  d_enterprise_credit_data:

networks:
  d-network:
    driver: bridge
EOF

# 区块链版Docker Compose
cat > blockchain/docker-compose.yml << 'EOF'
version: '3.8'

services:
  # 区块链版MySQL (端口3308)
  b-mysql:
    image: mysql:8.0.35
    container_name: b-mysql
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: b_mysql_root_2025
      MYSQL_DATABASE: b_mysql
      MYSQL_USER: b_mysql_user
      MYSQL_PASSWORD: b_mysql_password_2025
    ports:
      - "3308:3306"
    volumes:
      - b_mysql_data:/var/lib/mysql
    networks:
      - b-network

  # 区块链版PostgreSQL (端口5434)
  b-postgres:
    image: postgres:15.5
    container_name: b-postgres
    restart: always
    environment:
      POSTGRES_DB: b_pg
      POSTGRES_USER: b_pg_user
      POSTGRES_PASSWORD: b_pg_password_2025
    ports:
      - "5434:5432"
    volumes:
      - b_postgres_data:/var/lib/postgresql/data
    networks:
      - b-network

  # 区块链版Redis (端口6381)
  b-redis:
    image: redis:7.2-alpine
    container_name: b-redis
    restart: always
    command: redis-server --requirepass b_redis_password_2025
    ports:
      - "6381:6379"
    volumes:
      - b_redis_data:/data
    networks:
      - b-network

  # 区块链版Neo4j (端口7476/7689)
  b-neo4j:
    image: neo4j:5.15.0
    container_name: b-neo4j
    restart: always
    environment:
      NEO4J_AUTH: neo4j/b_neo4j_password_2025
      NEO4J_dbms_security_auth__enabled: "true"
    ports:
      - "7476:7474"
      - "7689:7687"
    volumes:
      - b_neo4j_data:/data
      - b_neo4j_logs:/logs
      - b_neo4j_import:/var/lib/neo4j/import
      - b_neo4j_plugins:/plugins
    networks:
      - b-network

  # 区块链版MongoDB (端口27019)
  b-mongodb:
    image: mongo:7.0.4
    container_name: b-mongodb
    restart: always
    environment:
      MONGO_INITDB_ROOT_USERNAME: b_mongo_admin
      MONGO_INITDB_ROOT_PASSWORD: b_mongo_password_2025
      MONGO_INITDB_DATABASE: b_mongo
    ports:
      - "27019:27017"
    volumes:
      - b_mongodb_data:/data/db
    networks:
      - b-network

  # 区块链版Elasticsearch (端口9202)
  b-elasticsearch:
    image: elasticsearch:8.11.1
    container_name: b-elasticsearch
    restart: always
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    ports:
      - "9202:9200"
    volumes:
      - b_elasticsearch_data:/usr/share/elasticsearch/data
    networks:
      - b-network

  # 区块链版Weaviate (端口8084)
  b-weaviate:
    image: semitechnologies/weaviate:1.21.5
    container_name: b-weaviate
    restart: always
    environment:
      QUERY_DEFAULTS_LIMIT: 25
      AUTHENTICATION_ANONYMOUS_ACCESS_ENABLED: 'true'
      PERSISTENCE_DATA_PATH: '/var/lib/weaviate'
      DEFAULT_VECTORIZER_MODULE: 'none'
      ENABLE_MODULES: 'text2vec-cohere,text2vec-huggingface,text2vec-palm,text2vec-openai,generative-openai,generative-cohere,generative-palm,ref2vec-centroid,reranker-cohere,qna-openai'
      CLUSTER_HOSTNAME: 'node1'
    ports:
      - "8084:8080"
    volumes:
      - b_weaviate_data:/var/lib/weaviate
    networks:
      - b-network

  # 区块链版AI服务数据库 (端口5437)
  b-ai-service-db:
    image: postgres:15.5
    container_name: b-ai-service-db
    restart: always
    environment:
      POSTGRES_DB: b_ai
      POSTGRES_USER: b_ai_user
      POSTGRES_PASSWORD: b_ai_password_2025
    ports:
      - "5437:5432"
    volumes:
      - b_ai_service_data:/var/lib/postgresql/data
    networks:
      - b-network

  # 区块链版DAO系统数据库 (端口9508)
  b-dao-system-db:
    image: postgres:15.5
    container_name: b-dao-system-db
    restart: always
    environment:
      POSTGRES_DB: b_dao
      POSTGRES_USER: b_dao_user
      POSTGRES_PASSWORD: b_dao_password_2025
    ports:
      - "9508:5432"
    volumes:
      - b_dao_system_data:/var/lib/postgresql/data
    networks:
      - b-network

  # 区块链版企业信用数据库 (端口7536)
  b-enterprise-credit-db:
    image: postgres:15.5
    container_name: b-enterprise-credit-db
    restart: always
    environment:
      POSTGRES_DB: b_credit
      POSTGRES_USER: b_credit_user
      POSTGRES_PASSWORD: b_credit_password_2025
    ports:
      - "7536:5432"
    volumes:
      - b_enterprise_credit_data:/var/lib/postgresql/data
    networks:
      - b-network

volumes:
  b_mysql_data:
  b_postgres_data:
  b_redis_data:
  b_neo4j_data:
  b_neo4j_logs:
  b_neo4j_import:
  b_neo4j_plugins:
  b_mongodb_data:
  b_elasticsearch_data:
  b_weaviate_data:
  b_ai_service_data:
  b_dao_system_data:
  b_enterprise_credit_data:

networks:
  b-network:
    driver: bridge
EOF

# 创建部署脚本
cat > deploy_to_tencent.sh << 'EOF'
#!/bin/bash

# 腾讯云数据库部署脚本
# 使用方法: ./deploy_to_tencent.sh [future|dao|blockchain]

VERSION=${1:-future}

if [ ! -d "$VERSION" ]; then
    echo "❌ 版本目录 $VERSION 不存在"
    exit 1
fi

echo "🚀 开始部署 $VERSION 版数据库到腾讯云..."

# 进入版本目录
cd $VERSION

# 加载镜像
echo "📦 加载数据库镜像..."
for image in *.tar; do
    if [ -f "$image" ]; then
        echo "正在加载 $image..."
        docker load -i "$image"
    fi
done

# 启动服务
echo "🔧 启动数据库服务..."
docker-compose up -d

# 检查服务状态
echo "🔍 检查服务状态..."
docker-compose ps

echo "✅ $VERSION 版数据库部署完成！"
EOF

chmod +x deploy_to_tencent.sh

# 创建镜像列表文件
cat > database_images.txt << 'EOF'
# 腾讯云数据库镜像列表

## Future版数据库镜像
mysql:8.0.35
postgres:15.5
redis:7.2-alpine
neo4j:5.15.0
mongo:7.0.4
elasticsearch:8.11.1
semitechnologies/weaviate:1.21.5

## 总计镜像数量
- 7个数据库镜像 × 3个版本 = 21个镜像文件
- 每个镜像约100-500MB
- 总大小约2-10GB

## 部署说明
1. 下载完成后，将整个目录上传到腾讯云服务器
2. 使用 deploy_to_tencent.sh 脚本部署对应版本
3. 支持 future、dao、blockchain 三个版本
EOF

echo "✅ 数据库镜像下载脚本创建完成！"
echo "📁 目录结构:"
echo "  tencent_cloud_database/"
echo "  ├── future/          # Future版数据库镜像和配置"
echo "  ├── dao/             # DAO版数据库镜像和配置"
echo "  ├── blockchain/      # 区块链版数据库镜像和配置"
echo "  ├── download_database_images.sh  # 下载脚本"
echo "  ├── deploy_to_tencent.sh         # 部署脚本"
echo "  └── database_images.txt          # 镜像列表"
echo ""
echo "🚀 运行下载脚本: ./download_database_images.sh"
