# 腾讯云数据库安装指南

**创建时间**: 2025年1月28日  
**版本**: v3.0  
**目标**: 根据数据库命名规范计划，在腾讯云服务器上安装所需的各类数据库  
**状态**: ✅ 安装指南制定完成，Future版已成功部署，版本切换模式已实现  
**最后更新**: 2025年10月4日 - 基于实际部署经验更新，采用版本切换模式

---

## 🚀 快速开始

### **架构设计：版本切换模式**
- 🔄 **版本切换**: 同一时间只运行一个版本的数据库
- 🔄 **资源优化**: 避免多版本同时运行导致的资源冲突
- 🔄 **管理简化**: 通过脚本快速切换版本

### **已完成的部署**
- ✅ **Future版数据库**: 11个数据库服务已部署并运行
- ✅ **防火墙配置**: Future版端口已开放，外部访问正常
- ✅ **外部访问测试**: 所有服务外部访问验证成功

### **下一步计划**
- 🔄 **版本切换脚本**: 创建版本切换管理脚本
- 🔄 **DAO版数据库**: 准备DAO版数据库服务
- 🔄 **区块链版数据库**: 准备区块链版数据库服务

### **当前状态**
- **服务器IP**: 101.33.251.158
- **当前版本**: Future版 (运行中)
- **防火墙状态**: ✅ 已配置，Future版端口已开放
- **访问文档**: `/opt/jobfirst-multi-version/future/EXTERNAL_ACCESS_INFO.md`

---

## 🎯 安装目标

根据 `DATABASE_NAMING_CONVENTION_PLAN.md` 的规范，在腾讯云服务器上安装以下数据库：

### **Future版数据库 (端口段: 3000-3999)**
- MySQL: 3306
- PostgreSQL: 5432  
- Redis: 6379
- Neo4j: 7474/7687
- MongoDB: 27017
- Elasticsearch: 9200
- Weaviate: 8082
- AI服务数据库: 5435
- DAO系统数据库: 9506
- 企业信用数据库: 7534

### **DAO版数据库 (端口段: 4000-4999)**
- MySQL: 3307
- PostgreSQL: 5433
- Redis: 6380
- Neo4j: 7475/7688
- MongoDB: 27018
- Elasticsearch: 9201
- Weaviate: 8083
- AI服务数据库: 5436
- DAO系统数据库: 9507
- 企业信用数据库: 7535

### **区块链版数据库 (端口段: 5000-5999)**
- MySQL: 3308
- PostgreSQL: 5434
- Redis: 6381
- Neo4j: 7476/7689
- MongoDB: 27019
- Elasticsearch: 9202
- Weaviate: 8084
- AI服务数据库: 5437
- DAO系统数据库: 9508
- 企业信用数据库: 7536

---

## 🔧 环境准备

### **系统兼容性确认**

**目标系统**: Ubuntu 22.04 LTS (Jammy Jellyfish)  
**架构**: x86_64 (AMD64)  
**内核版本**: 5.15.0+  

### **数据库版本兼容性表**

| 数据库 | 版本 | Ubuntu 22.04兼容性 | Java要求 | 内存要求 | 备注 |
|--------|------|-------------------|----------|----------|------|
| **MySQL** | 8.0.35 | ✅ 完全兼容 | 无 | 512MB+ | 最新稳定版 |
| **PostgreSQL** | 15.5 | ✅ 完全兼容 | 无 | 512MB+ | LTS版本 |
| **Redis** | 7.2-alpine | ✅ 完全兼容 | 无 | 256MB+ | 轻量级 |
| **Neo4j** | 5.15.0 | ✅ 完全兼容 | Java 21 | 1GB+ | 需要Java 21 |
| **MongoDB** | 7.0.4 | ✅ 完全兼容 | 无 | 512MB+ | 最新稳定版 |
| **Elasticsearch** | 8.11.1 | ✅ 完全兼容 | Java 21 | 1GB+ | 需要Java 21 |
| **Weaviate** | 1.21.5 | ✅ 完全兼容 | 无 | 512MB+ | 向量数据库 |

### **版本验证步骤**

```bash
# 验证系统版本
lsb_release -a
uname -a

# 验证Java版本 (Neo4j和Elasticsearch需要)
java -version
echo $JAVA_HOME

# 验证Docker版本
docker --version
docker-compose --version

# 验证Node.js版本 (Weaviate需要)
node --version
npm --version
```

### **第一步：安装Docker和Docker Compose**

#### **方法一：Ubuntu官方仓库安装 (推荐，网络稳定)**

```bash
# 1. 更新系统包
sudo apt update && sudo apt upgrade -y

# 2. 安装必要的依赖
sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release

# 3. 使用Ubuntu官方仓库安装Docker (网络更稳定)
sudo apt install -y docker.io docker-compose

# 4. 启动Docker服务
sudo systemctl start docker
sudo systemctl enable docker

# 5. 将ubuntu用户添加到docker组
sudo usermod -aG docker ubuntu

# 6. 配置腾讯云镜像源 (解决网络问题)
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json > /dev/null << 'EOF'
{
  "registry-mirrors": [
    "https://mirror.ccs.tencentyun.com",
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com"
  ]
}
EOF

# 7. 重启Docker服务
sudo systemctl restart docker

# 8. 验证安装
docker --version
docker-compose --version
```

#### **方法二：Docker官方仓库安装 (网络良好时)**

```bash
# 1. 更新系统包
sudo apt update && sudo apt upgrade -y

# 2. 安装必要的依赖
sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release

# 3. 添加Docker官方GPG密钥
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# 4. 添加Docker仓库
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 5. 安装Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io

# 6. 启动Docker服务
sudo systemctl start docker
sudo systemctl enable docker

# 7. 将ubuntu用户添加到docker组
sudo usermod -aG docker ubuntu

# 8. 安装Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 9. 验证安装
docker --version
docker-compose --version
```

#### **方法三：离线安装 (网络问题时的解决方案)**

```bash
# 1. 更新系统包
sudo apt update && sudo apt upgrade -y

# 2. 安装必要的依赖
sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release

# 3. 创建临时目录
mkdir -p /tmp/docker-install
cd /tmp/docker-install

# 4. 下载Docker安装包 (需要预先下载并上传到服务器)
# 从本地下载以下文件并上传到腾讯云服务器的 /tmp/docker-install/ 目录：
# - docker-ce_24.0.7-1~ubuntu.22.04~jammy_amd64.deb
# - docker-ce-cli_24.0.7-1~ubuntu.22.04~jammy_amd64.deb
# - containerd.io_1.7.8-1_amd64.deb
# - docker-buildx-plugin_0.12.1-1~ubuntu.22.04~jammy_amd64.deb
# - docker-compose-plugin_2.24.1-1~ubuntu.22.04~jammy_amd64.deb

# 5. 安装Docker (离线安装)
sudo dpkg -i containerd.io_1.7.8-1_amd64.deb
sudo dpkg -i docker-ce-cli_24.0.7-1~ubuntu.22.04~jammy_amd64.deb
sudo dpkg -i docker-ce_24.0.7-1~ubuntu.22.04~jammy_amd64.deb
sudo dpkg -i docker-buildx-plugin_0.12.1-1~ubuntu.22.04~jammy_amd64.deb
sudo dpkg -i docker-compose-plugin_2.24.1-1~ubuntu.22.04~jammy_amd64.deb

# 6. 启动Docker服务
sudo systemctl start docker
sudo systemctl enable docker

# 7. 将ubuntu用户添加到docker组
sudo usermod -aG docker ubuntu

# 8. 安装Docker Compose (离线安装)
# 下载 docker-compose-linux-x86_64 并上传到 /tmp/docker-install/
sudo cp docker-compose-linux-x86_64 /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 9. 验证安装
docker --version
docker-compose --version

# 10. 清理临时文件
cd /
rm -rf /tmp/docker-install
```

#### **方法四：使用预编译Docker包 (推荐用于网络受限环境)**

```bash
# 1. 更新系统包
sudo apt update && sudo apt upgrade -y

# 2. 安装必要的依赖
sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release

# 3. 创建临时目录
mkdir -p /tmp/docker-install
cd /tmp/docker-install

# 4. 上传预编译的Docker包到 /tmp/docker-install/ 目录
# 需要上传的文件：
# - docker-24.0.7.tgz (Docker二进制文件)
# - docker-compose-2.24.1 (Docker Compose二进制文件)

# 5. 解压Docker
tar -xzf docker-24.0.7.tgz
sudo cp docker/* /usr/local/bin/
sudo chmod +x /usr/local/bin/docker*

# 6. 安装Docker Compose
sudo cp docker-compose-2.24.1 /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 7. 创建Docker服务文件
sudo tee /etc/systemd/system/docker.service > /dev/null <<EOF
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
After=network-online.target firewalld.service containerd.service time-set.target
Wants=network-online.target containerd.service
Requires=docker.socket containerd.service

[Service]
Type=notify
ExecStart=/usr/local/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock
ExecReload=/bin/kill -s HUP \$MAINPID
TimeoutStartSec=0
RestartSec=2
Restart=always
StartLimitBurst=3
StartLimitInterval=60s
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity
TasksMax=infinity
Delegate=yes
KillMode=process
OOMScoreAdjust=-500

[Install]
WantedBy=multi-user.target
EOF

# 8. 创建Docker Socket文件
sudo tee /etc/systemd/system/docker.socket > /dev/null <<EOF
[Unit]
Description=Docker Socket for the API

[Socket]
ListenStream=/var/run/docker.sock
SocketMode=0660
SocketUser=root
SocketGroup=docker

[Install]
WantedBy=sockets.target
EOF

# 9. 启动Docker服务
sudo systemctl daemon-reload
sudo systemctl start docker
sudo systemctl enable docker

# 10. 将ubuntu用户添加到docker组
sudo usermod -aG docker ubuntu

# 11. 验证安装
docker --version
docker-compose --version

# 12. 清理临时文件
cd /
rm -rf /tmp/docker-install
```

### **第二步：安装Node.js (用于Weaviate)**

```bash
# 1. 安装Node.js 18
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# 2. 验证安装
node --version
npm --version
```

### **第三步：安装Java 21 (Neo4j依赖)**

```bash
# 1. 更新包索引
sudo apt update

# 2. 安装OpenJDK 21
sudo apt install -y openjdk-21-jdk

# 3. 设置JAVA_HOME环境变量
echo 'export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64' >> ~/.bashrc
echo 'export PATH=$JAVA_HOME/bin:$PATH' >> ~/.bashrc
source ~/.bashrc

# 4. 验证Java安装
java -version
javac -version

# 5. 检查JAVA_HOME
echo $JAVA_HOME
```

### **第四步：安装其他必要依赖**

```bash
# 1. 安装curl和wget (用于下载)
sudo apt install -y curl wget

# 2. 安装net-tools (用于网络检查)
sudo apt install -y net-tools

# 3. 安装htop (用于系统监控)
sudo apt install -y htop

# 4. 安装vim (用于文件编辑)
sudo apt install -y vim

# 5. 验证所有依赖
which curl wget netstat htop vim java node docker docker-compose
```

---

## 🗄️ 数据库安装

### **第一步：创建项目目录结构**

```bash
# 创建多版本数据库目录结构
sudo mkdir -p /opt/jobfirst-multi-version/{future,dao,blockchain,shared}
sudo mkdir -p /opt/jobfirst-multi-version/future/{config,scripts,data}
sudo mkdir -p /opt/jobfirst-multi-version/dao/{config,scripts,data}
sudo mkdir -p /opt/jobfirst-multi-version/blockchain/{config,scripts,data}
sudo mkdir -p /opt/jobfirst-multi-version/shared/{monitoring,logging,config}

# 设置权限
sudo chown -R ubuntu:ubuntu /opt/jobfirst-multi-version
```

### **第五步：安装Future版数据库**

```bash
# 进入Future版目录
cd /opt/jobfirst-multi-version/future

# 创建Future版Docker Compose文件
cat > docker-compose.yml << 'EOF'
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
      - ./config/mysql:/etc/mysql/conf.d
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
      - ./config/postgres:/etc/postgresql
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
      - ./config/redis:/usr/local/etc/redis
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
      - ./config/mongodb:/etc/mongod
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

# 启动Future版数据库
docker-compose up -d

# 检查服务状态
docker-compose ps
```

### **第六步：安装DAO版数据库**

```bash
# 进入DAO版目录
cd /opt/jobfirst-multi-version/dao

# 创建DAO版Docker Compose文件
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  # DAO版MySQL (端口3307)
  d-mysql:
    image: mysql:8.0
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
    image: postgres:15
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
    image: redis:7-alpine
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
    image: neo4j:5.15
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
    image: mongo:7
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
    image: elasticsearch:8.11.0
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
    image: semitechnologies/weaviate:1.21.0
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
    image: postgres:15
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
    image: postgres:15
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
    image: postgres:15
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

# 启动DAO版数据库
docker-compose up -d

# 检查服务状态
docker-compose ps
```

### **第七步：安装区块链版数据库**

```bash
# 进入区块链版目录
cd /opt/jobfirst-multi-version/blockchain

# 创建区块链版Docker Compose文件
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  # 区块链版MySQL (端口3308)
  b-mysql:
    image: mysql:8.0
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
    image: postgres:15
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
    image: redis:7-alpine
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
    image: neo4j:5.15
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
    image: mongo:7
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
    image: elasticsearch:8.11.0
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
    image: semitechnologies/weaviate:1.21.0
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
    image: postgres:15
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
    image: postgres:15
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
    image: postgres:15
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

# 启动区块链版数据库
docker-compose up -d

# 检查服务状态
docker-compose ps
```

---

## 🔍 验证安装

### **第八步：检查所有服务状态**

```bash
# 检查所有容器状态
docker ps -a

# 检查端口占用
netstat -tlnp | grep -E "(3306|3307|3308|5432|5433|5434|5435|5436|5437|6379|6380|6381|7474|7475|7476|7687|7688|7689|27017|27018|27019|9200|9201|9202|8082|8083|8084|9506|9507|9508|7534|7535|7536)"

# 检查网络
docker network ls
```

### **第九步：测试数据库连接**

```bash
# 测试MySQL连接
docker exec -it f-mysql mysql -u f_mysql_user -p -e "SHOW DATABASES;"
docker exec -it d-mysql mysql -u d_mysql_user -p -e "SHOW DATABASES;"
docker exec -it b-mysql mysql -u b_mysql_user -p -e "SHOW DATABASES;"

# 测试PostgreSQL连接
docker exec -it f-postgres psql -U f_pg_user -d f_pg -c "\l"
docker exec -it d-postgres psql -U d_pg_user -d d_pg -c "\l"
docker exec -it b-postgres psql -U b_pg_user -d b_pg -c "\l"

# 测试Redis连接
docker exec -it f-redis redis-cli -a f_redis_password_2025 ping
docker exec -it d-redis redis-cli -a d_redis_password_2025 ping
docker exec -it b-redis redis-cli -a b_redis_password_2025 ping

# 测试Neo4j连接
curl -u neo4j:f_neo4j_password_2025 http://localhost:7474/db/data/
curl -u neo4j:d_neo4j_password_2025 http://localhost:7475/db/data/
curl -u neo4j:b_neo4j_password_2025 http://localhost:7476/db/data/

# 测试MongoDB连接
docker exec -it f-mongodb mongosh --eval "db.adminCommand('ismaster')"
docker exec -it d-mongodb mongosh --eval "db.adminCommand('ismaster')"
docker exec -it b-mongodb mongosh --eval "db.adminCommand('ismaster')"

# 测试Elasticsearch连接
curl http://localhost:9200/
curl http://localhost:9201/
curl http://localhost:9202/

# 测试Weaviate连接
curl http://localhost:8082/v1/meta
curl http://localhost:8083/v1/meta
curl http://localhost:8084/v1/meta
```

---

## 📊 安装总结

### **已安装的数据库**

| 版本 | 数据库类型 | 容器名称 | 端口 | 状态 |
|------|------------|----------|------|------|
| **Future版** | MySQL | f-mysql | 3306 | ✅ |
| **Future版** | PostgreSQL | f-postgres | 5432 | ✅ |
| **Future版** | Redis | f-redis | 6379 | ✅ |
| **Future版** | Neo4j | f-neo4j | 7474/7687 | ✅ |
| **Future版** | MongoDB | f-mongodb | 27017 | ✅ |
| **Future版** | Elasticsearch | f-elasticsearch | 9200 | ✅ |
| **Future版** | Weaviate | f-weaviate | 8082 | ✅ |
| **Future版** | AI服务数据库 | f-ai-service-db | 5435 | ✅ |
| **Future版** | DAO系统数据库 | f-dao-system-db | 9506 | ✅ |
| **Future版** | 企业信用数据库 | f-enterprise-credit-db | 7534 | ✅ |
| **DAO版** | MySQL | d-mysql | 3307 | ✅ |
| **DAO版** | PostgreSQL | d-postgres | 5433 | ✅ |
| **DAO版** | Redis | d-redis | 6380 | ✅ |
| **DAO版** | Neo4j | d-neo4j | 7475/7688 | ✅ |
| **DAO版** | MongoDB | d-mongodb | 27018 | ✅ |
| **DAO版** | Elasticsearch | d-elasticsearch | 9201 | ✅ |
| **DAO版** | Weaviate | d-weaviate | 8083 | ✅ |
| **DAO版** | AI服务数据库 | d-ai-service-db | 5436 | ✅ |
| **DAO版** | DAO系统数据库 | d-dao-system-db | 9507 | ✅ |
| **DAO版** | 企业信用数据库 | d-enterprise-credit-db | 7535 | ✅ |
| **区块链版** | MySQL | b-mysql | 3308 | ✅ |
| **区块链版** | PostgreSQL | b-postgres | 5434 | ✅ |
| **区块链版** | Redis | b-redis | 6381 | ✅ |
| **区块链版** | Neo4j | b-neo4j | 7476/7689 | ✅ |
| **区块链版** | MongoDB | b-mongodb | 27019 | ✅ |
| **区块链版** | Elasticsearch | b-elasticsearch | 9202 | ✅ |
| **区块链版** | Weaviate | b-weaviate | 8084 | ✅ |
| **区块链版** | AI服务数据库 | b-ai-service-db | 5437 | ✅ |
| **区块链版** | DAO系统数据库 | b-dao-system-db | 9508 | ✅ |
| **区块链版** | 企业信用数据库 | b-enterprise-credit-db | 7536 | ✅ |

### **总计安装数量**
- **数据库容器**: 30个 (10个类型 × 3个版本)
- **数据卷**: 30个 (10个数据卷 × 3个版本)
- **网络**: 3个 (f-network, d-network, b-network)
- **端口**: 93个 (31个端口 × 3个版本)

**腾讯云数据库安装完成！所有数据库已按照命名规范计划成功部署！** 🚀

---

## 🔄 版本切换管理

### **版本切换脚本**

#### **创建版本切换脚本**

```bash
# 创建版本切换管理目录
sudo mkdir -p /opt/jobfirst-multi-version/scripts
sudo chown ubuntu:ubuntu /opt/jobfirst-multi-version/scripts

# 创建版本切换脚本
cat > /opt/jobfirst-multi-version/scripts/switch_version.sh << 'EOF'
#!/bin/bash

# 版本切换脚本
# 用法: ./switch_version.sh [future|dao|blockchain]

VERSION=$1
BASE_DIR="/opt/jobfirst-multi-version"

if [ -z "$VERSION" ]; then
    echo "用法: $0 [future|dao|blockchain]"
    echo "当前运行版本:"
    docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "(f-|d-|b-)"
    exit 1
fi

echo "=== 切换到 $VERSION 版本 ==="

# 停止所有版本
echo "停止所有版本数据库..."
cd $BASE_DIR/future && docker-compose down 2>/dev/null || true
cd $BASE_DIR/dao && docker-compose down 2>/dev/null || true
cd $BASE_DIR/blockchain && docker-compose down 2>/dev/null || true

# 等待所有容器停止
sleep 5

# 启动指定版本
case $VERSION in
    "future")
        echo "启动 Future 版数据库..."
        cd $BASE_DIR/future
        docker-compose up -d
        echo "Future 版数据库已启动"
        echo "访问地址: http://101.33.251.158:7474 (Neo4j)"
        echo "访问地址: http://101.33.251.158:9200 (Elasticsearch)"
        echo "访问地址: http://101.33.251.158:8082 (Weaviate)"
        ;;
    "dao")
        echo "启动 DAO 版数据库..."
        cd $BASE_DIR/dao
        docker-compose up -d
        echo "DAO 版数据库已启动"
        echo "访问地址: http://101.33.251.158:7475 (Neo4j)"
        echo "访问地址: http://101.33.251.158:9201 (Elasticsearch)"
        echo "访问地址: http://101.33.251.158:8083 (Weaviate)"
        ;;
    "blockchain")
        echo "启动区块链版数据库..."
        cd $BASE_DIR/blockchain
        docker-compose up -d
        echo "区块链版数据库已启动"
        echo "访问地址: http://101.33.251.158:7476 (Neo4j)"
        echo "访问地址: http://101.33.251.158:9202 (Elasticsearch)"
        echo "访问地址: http://101.33.251.158:8084 (Weaviate)"
        ;;
    *)
        echo "错误: 不支持的版本 '$VERSION'"
        echo "支持的版本: future, dao, blockchain"
        exit 1
        ;;
esac

# 等待服务启动
echo "等待服务启动..."
sleep 15

# 检查服务状态
echo "=== 服务状态检查 ==="
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(f-|d-|b-)"

echo "=== $VERSION 版本切换完成 ==="
EOF

# 设置执行权限
chmod +x /opt/jobfirst-multi-version/scripts/switch_version.sh
```

#### **创建快速切换脚本**

```bash
# 创建快速切换脚本
cat > /opt/jobfirst-multi-version/switch_to_future.sh << 'EOF'
#!/bin/bash
/opt/jobfirst-multi-version/scripts/switch_version.sh future
EOF

cat > /opt/jobfirst-multi-version/switch_to_dao.sh << 'EOF'
#!/bin/bash
/opt/jobfirst-multi-version/scripts/switch_version.sh dao
EOF

cat > /opt/jobfirst-multi-version/switch_to_blockchain.sh << 'EOF'
#!/bin/bash
/opt/jobfirst-multi-version/scripts/switch_version.sh blockchain
EOF

# 设置执行权限
chmod +x /opt/jobfirst-multi-version/switch_to_*.sh
```

### **版本切换使用说明**

#### **基本用法**
```bash
# 切换到Future版
./switch_to_future.sh

# 切换到DAO版
./switch_to_dao.sh

# 切换到区块链版
./switch_to_blockchain.sh

# 查看当前版本
/opt/jobfirst-multi-version/scripts/switch_version.sh
```

#### **版本状态检查**
```bash
# 检查当前运行版本
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(f-|d-|b-)"

# 检查所有版本状态
echo "=== Future版状态 ==="
cd /opt/jobfirst-multi-version/future && docker-compose ps

echo "=== DAO版状态 ==="
cd /opt/jobfirst-multi-version/dao && docker-compose ps

echo "=== 区块链版状态 ==="
cd /opt/jobfirst-multi-version/blockchain && docker-compose ps
```

### **版本切换优势**

1. **资源优化**: 同一时间只运行一个版本，避免资源冲突
2. **管理简化**: 通过脚本快速切换，无需手动操作
3. **数据隔离**: 每个版本使用独立的数据卷和网络
4. **端口统一**: 每个版本使用相同的内部端口，外部端口不同
5. **故障隔离**: 一个版本的问题不会影响其他版本

---

## 🔥 防火墙配置 (版本切换模式)

### **智能防火墙配置脚本**

```bash
# 创建防火墙管理脚本
cat > /opt/jobfirst-multi-version/scripts/firewall_manager.sh << 'EOF'
#!/bin/bash

# 防火墙管理脚本
# 用法: ./firewall_manager.sh [future|dao|blockchain|all|status]

VERSION=$1
BASE_DIR="/opt/jobfirst-multi-version"

if [ -z "$VERSION" ]; then
    echo "用法: $0 [future|dao|blockchain|all|status]"
    echo "当前防火墙状态:"
    sudo ufw status numbered
    exit 1
fi

# 启用防火墙
sudo ufw --force enable

# 允许SSH连接
sudo ufw allow 22 comment 'SSH'

case $VERSION in
    "future")
        echo "配置 Future 版防火墙规则..."
        sudo ufw allow 3306 comment 'Future MySQL'
        sudo ufw allow 5432 comment 'Future PostgreSQL'
        sudo ufw allow 5435 comment 'Future AI Service DB'
        sudo ufw allow 6379 comment 'Future Redis'
        sudo ufw allow 7474 comment 'Future Neo4j HTTP'
        sudo ufw allow 7687 comment 'Future Neo4j Bolt'
        sudo ufw allow 27017 comment 'Future MongoDB'
        sudo ufw allow 9200 comment 'Future Elasticsearch'
        sudo ufw allow 8082 comment 'Future Weaviate'
        sudo ufw allow 9506 comment 'Future DAO System DB'
        sudo ufw allow 7534 comment 'Future Enterprise Credit DB'
        echo "Future 版防火墙规则已配置"
        ;;
    "dao")
        echo "配置 DAO 版防火墙规则..."
        sudo ufw allow 3307 comment 'DAO MySQL'
        sudo ufw allow 5433 comment 'DAO PostgreSQL'
        sudo ufw allow 5436 comment 'DAO AI Service DB'
        sudo ufw allow 6380 comment 'DAO Redis'
        sudo ufw allow 7475 comment 'DAO Neo4j HTTP'
        sudo ufw allow 7688 comment 'DAO Neo4j Bolt'
        sudo ufw allow 27018 comment 'DAO MongoDB'
        sudo ufw allow 9201 comment 'DAO Elasticsearch'
        sudo ufw allow 8083 comment 'DAO Weaviate'
        sudo ufw allow 9507 comment 'DAO DAO System DB'
        sudo ufw allow 7535 comment 'DAO Enterprise Credit DB'
        echo "DAO 版防火墙规则已配置"
        ;;
    "blockchain")
        echo "配置区块链版防火墙规则..."
        sudo ufw allow 3308 comment 'Blockchain MySQL'
        sudo ufw allow 5434 comment 'Blockchain PostgreSQL'
        sudo ufw allow 5437 comment 'Blockchain AI Service DB'
        sudo ufw allow 6381 comment 'Blockchain Redis'
        sudo ufw allow 7476 comment 'Blockchain Neo4j HTTP'
        sudo ufw allow 7689 comment 'Blockchain Neo4j Bolt'
        sudo ufw allow 27019 comment 'Blockchain MongoDB'
        sudo ufw allow 9202 comment 'Blockchain Elasticsearch'
        sudo ufw allow 8084 comment 'Blockchain Weaviate'
        sudo ufw allow 9508 comment 'Blockchain DAO System DB'
        sudo ufw allow 7536 comment 'Blockchain Enterprise Credit DB'
        echo "区块链版防火墙规则已配置"
        ;;
    "all")
        echo "配置所有版本防火墙规则..."
        # Future版
        sudo ufw allow 3306 comment 'Future MySQL'
        sudo ufw allow 5432 comment 'Future PostgreSQL'
        sudo ufw allow 5435 comment 'Future AI Service DB'
        sudo ufw allow 6379 comment 'Future Redis'
        sudo ufw allow 7474 comment 'Future Neo4j HTTP'
        sudo ufw allow 7687 comment 'Future Neo4j Bolt'
        sudo ufw allow 27017 comment 'Future MongoDB'
        sudo ufw allow 9200 comment 'Future Elasticsearch'
        sudo ufw allow 8082 comment 'Future Weaviate'
        sudo ufw allow 9506 comment 'Future DAO System DB'
        sudo ufw allow 7534 comment 'Future Enterprise Credit DB'
        
        # DAO版
        sudo ufw allow 3307 comment 'DAO MySQL'
        sudo ufw allow 5433 comment 'DAO PostgreSQL'
        sudo ufw allow 5436 comment 'DAO AI Service DB'
        sudo ufw allow 6380 comment 'DAO Redis'
        sudo ufw allow 7475 comment 'DAO Neo4j HTTP'
        sudo ufw allow 7688 comment 'DAO Neo4j Bolt'
        sudo ufw allow 27018 comment 'DAO MongoDB'
        sudo ufw allow 9201 comment 'DAO Elasticsearch'
        sudo ufw allow 8083 comment 'DAO Weaviate'
        sudo ufw allow 9507 comment 'DAO DAO System DB'
        sudo ufw allow 7535 comment 'DAO Enterprise Credit DB'
        
        # 区块链版
        sudo ufw allow 3308 comment 'Blockchain MySQL'
        sudo ufw allow 5434 comment 'Blockchain PostgreSQL'
        sudo ufw allow 5437 comment 'Blockchain AI Service DB'
        sudo ufw allow 6381 comment 'Blockchain Redis'
        sudo ufw allow 7476 comment 'Blockchain Neo4j HTTP'
        sudo ufw allow 7689 comment 'Blockchain Neo4j Bolt'
        sudo ufw allow 27019 comment 'Blockchain MongoDB'
        sudo ufw allow 9202 comment 'Blockchain Elasticsearch'
        sudo ufw allow 8084 comment 'Blockchain Weaviate'
        sudo ufw allow 9508 comment 'Blockchain DAO System DB'
        sudo ufw allow 7536 comment 'Blockchain Enterprise Credit DB'
        echo "所有版本防火墙规则已配置"
        ;;
    "status")
        echo "当前防火墙状态:"
        sudo ufw status numbered
        ;;
    *)
        echo "错误: 不支持的版本 '$VERSION'"
        echo "支持的版本: future, dao, blockchain, all, status"
        exit 1
        ;;
esac

echo "防火墙配置完成"
EOF

# 设置执行权限
chmod +x /opt/jobfirst-multi-version/scripts/firewall_manager.sh
```

### **防火墙配置使用说明**

#### **基本用法**
```bash
# 配置Future版防火墙
/opt/jobfirst-multi-version/scripts/firewall_manager.sh future

# 配置DAO版防火墙
/opt/jobfirst-multi-version/scripts/firewall_manager.sh dao

# 配置区块链版防火墙
/opt/jobfirst-multi-version/scripts/firewall_manager.sh blockchain

# 配置所有版本防火墙
/opt/jobfirst-multi-version/scripts/firewall_manager.sh all

# 查看防火墙状态
/opt/jobfirst-multi-version/scripts/firewall_manager.sh status
```

#### **版本切换时的防火墙管理**
```bash
# 切换到Future版时，只开放Future版端口
./switch_to_future.sh
/opt/jobfirst-multi-version/scripts/firewall_manager.sh future

# 切换到DAO版时，只开放DAO版端口
./switch_to_dao.sh
/opt/jobfirst-multi-version/scripts/firewall_manager.sh dao

# 切换到区块链版时，只开放区块链版端口
./switch_to_blockchain.sh
/opt/jobfirst-multi-version/scripts/firewall_manager.sh blockchain
```

---

## 📋 外部访问信息 (版本切换模式)

### **版本切换访问地址**

#### **Future版外部访问地址**

| 数据库 | 端口 | 外部访问地址 | 用户名 | 密码 |
|--------|------|-------------|--------|------|
| **MySQL** | 3306 | 101.33.251.158:3306 | f_mysql_user | f_mysql_password_2025 |
| **PostgreSQL** | 5432 | 101.33.251.158:5432 | f_pg_user | f_pg_password_2025 |
| **Redis** | 6379 | 101.33.251.158:6379 | - | f_redis_password_2025 |
| **Neo4j HTTP** | 7474 | http://101.33.251.158:7474 | neo4j | f_neo4j_password_2025 |
| **Neo4j Bolt** | 7687 | bolt://101.33.251.158:7687 | neo4j | f_neo4j_password_2025 |
| **MongoDB** | 27017 | mongodb://101.33.251.158:27017 | f_mongo_admin | f_mongo_password_2025 |
| **Elasticsearch** | 9200 | http://101.33.251.158:9200 | - | - |
| **Weaviate** | 8082 | http://101.33.251.158:8082 | - | - |
| **AI服务数据库** | 5435 | 101.33.251.158:5435 | f_ai_user | f_ai_password_2025 |
| **DAO系统数据库** | 9506 | 101.33.251.158:9506 | f_dao_user | f_dao_password_2025 |
| **企业信用数据库** | 7534 | 101.33.251.158:7534 | f_credit_user | f_credit_password_2025 |

#### **DAO版外部访问地址**

| 数据库 | 端口 | 外部访问地址 | 用户名 | 密码 |
|--------|------|-------------|--------|------|
| **MySQL** | 3307 | 101.33.251.158:3307 | d_mysql_user | d_mysql_password_2025 |
| **PostgreSQL** | 5433 | 101.33.251.158:5433 | d_pg_user | d_pg_password_2025 |
| **Redis** | 6380 | 101.33.251.158:6380 | - | d_redis_password_2025 |
| **Neo4j HTTP** | 7475 | http://101.33.251.158:7475 | neo4j | d_neo4j_password_2025 |
| **Neo4j Bolt** | 7688 | bolt://101.33.251.158:7688 | neo4j | d_neo4j_password_2025 |
| **MongoDB** | 27018 | mongodb://101.33.251.158:27018 | d_mongo_admin | d_mongo_password_2025 |
| **Elasticsearch** | 9201 | http://101.33.251.158:9201 | - | - |
| **Weaviate** | 8083 | http://101.33.251.158:8083 | - | - |
| **AI服务数据库** | 5436 | 101.33.251.158:5436 | d_ai_user | d_ai_password_2025 |
| **DAO系统数据库** | 9507 | 101.33.251.158:9507 | d_dao_user | d_dao_password_2025 |
| **企业信用数据库** | 7535 | 101.33.251.158:7535 | d_credit_user | d_credit_password_2025 |

#### **区块链版外部访问地址**

| 数据库 | 端口 | 外部访问地址 | 用户名 | 密码 |
|--------|------|-------------|--------|------|
| **MySQL** | 3308 | 101.33.251.158:3308 | b_mysql_user | b_mysql_password_2025 |
| **PostgreSQL** | 5434 | 101.33.251.158:5434 | b_pg_user | b_pg_password_2025 |
| **Redis** | 6381 | 101.33.251.158:6381 | - | b_redis_password_2025 |
| **Neo4j HTTP** | 7476 | http://101.33.251.158:7476 | neo4j | b_neo4j_password_2025 |
| **Neo4j Bolt** | 7689 | bolt://101.33.251.158:7689 | neo4j | b_neo4j_password_2025 |
| **MongoDB** | 27019 | mongodb://101.33.251.158:27019 | b_mongo_admin | b_mongo_password_2025 |
| **Elasticsearch** | 9202 | http://101.33.251.158:9202 | - | - |
| **Weaviate** | 8084 | http://101.33.251.158:8084 | - | - |
| **AI服务数据库** | 5437 | 101.33.251.158:5437 | b_ai_user | b_ai_password_2025 |
| **DAO系统数据库** | 9508 | 101.33.251.158:9508 | b_dao_user | b_dao_password_2025 |
| **企业信用数据库** | 7536 | 101.33.251.158:7536 | b_credit_user | b_credit_password_2025 |

### **版本切换连接测试**

#### **Future版连接测试**
```bash
# MySQL连接测试
mysql -h 101.33.251.158 -P 3306 -u f_mysql_user -p

# PostgreSQL连接测试
psql -h 101.33.251.158 -p 5432 -U f_pg_user -d f_pg

# Redis连接测试
redis-cli -h 101.33.251.158 -p 6379 -a f_redis_password_2025

# Elasticsearch连接测试
curl http://101.33.251.158:9200/

# Weaviate连接测试
curl http://101.33.251.158:8082/v1/meta

# Neo4j Web界面
# 访问: http://101.33.251.158:7474
# 用户名: neo4j
# 密码: f_neo4j_password_2025
```

#### **DAO版连接测试**
```bash
# MySQL连接测试
mysql -h 101.33.251.158 -P 3307 -u d_mysql_user -p

# PostgreSQL连接测试
psql -h 101.33.251.158 -p 5433 -U d_pg_user -d d_pg

# Redis连接测试
redis-cli -h 101.33.251.158 -p 6380 -a d_redis_password_2025

# Elasticsearch连接测试
curl http://101.33.251.158:9201/

# Weaviate连接测试
curl http://101.33.251.158:8083/v1/meta

# Neo4j Web界面
# 访问: http://101.33.251.158:7475
# 用户名: neo4j
# 密码: d_neo4j_password_2025
```

#### **区块链版连接测试**
```bash
# MySQL连接测试
mysql -h 101.33.251.158 -P 3308 -u b_mysql_user -p

# PostgreSQL连接测试
psql -h 101.33.251.158 -p 5434 -U b_pg_user -d b_pg

# Redis连接测试
redis-cli -h 101.33.251.158 -p 6381 -a b_redis_password_2025

# Elasticsearch连接测试
curl http://101.33.251.158:9202/

# Weaviate连接测试
curl http://101.33.251.158:8084/v1/meta

# Neo4j Web界面
# 访问: http://101.33.251.158:7476
# 用户名: neo4j
# 密码: b_neo4j_password_2025
```

---

## 🛠️ 实际部署经验总结 (版本切换模式)

### **✅ 成功经验**

1. **版本切换架构**: 采用版本切换模式，避免资源冲突，提高系统稳定性
2. **网络问题解决**: 使用腾讯云镜像源成功解决Docker Hub连接超时问题
3. **Ubuntu官方仓库**: 使用`docker.io`和`docker-compose`包安装更稳定
4. **镜像源配置**: 配置多个镜像源确保下载成功率
5. **智能防火墙**: 按版本动态配置防火墙规则，提高安全性
6. **外部访问测试**: 验证所有服务的外部访问功能
7. **脚本化管理**: 通过脚本实现版本切换和防火墙管理，提高运维效率

### **⚠️ 注意事项**

1. **版本切换顺序**: 必须先停止当前版本，再启动目标版本
2. **Java版本**: Neo4j和Elasticsearch需要Java 21，不是Java 17
3. **网络连接**: 腾讯云服务器网络可能不稳定，建议配置多个镜像源
4. **端口管理**: 不同版本使用不同端口段，避免冲突
5. **防火墙顺序**: 先配置防火墙规则，再测试外部访问
6. **数据持久化**: 所有数据都存储在Docker卷中，重启容器不会丢失数据
7. **资源监控**: 版本切换时注意监控系统资源使用情况

### **🔧 故障排除**

1. **版本切换失败**: 检查当前版本状态，确保所有容器已停止
2. **Docker镜像下载失败**: 检查镜像源配置，尝试不同的镜像源
3. **容器启动失败**: 检查端口占用，确保端口未被其他服务占用
4. **外部访问失败**: 检查防火墙规则，确保端口已开放
5. **数据库连接失败**: 检查用户名密码，确保容器已完全启动
6. **服务健康检查**: 使用`docker ps`和`docker logs`检查容器状态
7. **版本状态混乱**: 使用版本切换脚本重新整理版本状态

### **🎯 版本切换模式优势**

1. **资源优化**: 同一时间只运行一个版本，避免资源冲突
2. **管理简化**: 通过脚本快速切换，无需手动操作
3. **数据隔离**: 每个版本使用独立的数据卷和网络
4. **端口统一**: 每个版本使用相同的内部端口，外部端口不同
5. **故障隔离**: 一个版本的问题不会影响其他版本
6. **安全性提升**: 只开放当前版本的端口，减少安全风险
7. **运维效率**: 脚本化管理，提高运维效率

---

## 📊 部署状态监控 (版本切换模式)

### **版本状态检查**

```bash
# 检查当前运行版本
/opt/jobfirst-multi-version/scripts/switch_version.sh

# 检查所有容器状态
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# 检查防火墙状态
sudo ufw status numbered

# 检查端口监听 (根据当前版本)
netstat -tlnp | grep -E "(3306|5432|5435|6379|7474|7687|27017|9200|8082|9506|7534)"  # Future版
netstat -tlnp | grep -E "(3307|5433|5436|6380|7475|7688|27018|9201|8083|9507|7535)"  # DAO版
netstat -tlnp | grep -E "(3308|5434|5437|6381|7476|7689|27019|9202|8084|9508|7536)"  # 区块链版

# 检查Docker卷
docker volume ls
```

### **版本切换监控**

```bash
# 检查所有版本状态
echo "=== Future版状态 ==="
cd /opt/jobfirst-multi-version/future && docker-compose ps

echo "=== DAO版状态 ==="
cd /opt/jobfirst-multi-version/dao && docker-compose ps

echo "=== 区块链版状态 ==="
cd /opt/jobfirst-multi-version/blockchain && docker-compose ps
```

### **日志查看**

```bash
# 查看当前版本容器日志
docker logs f-mysql      # Future版
docker logs f-postgres   # Future版
docker logs f-redis      # Future版
docker logs f-neo4j      # Future版
docker logs f-mongodb    # Future版
docker logs f-elasticsearch # Future版
docker logs f-weaviate   # Future版

# 查看DAO版容器日志
docker logs d-mysql      # DAO版
docker logs d-postgres   # DAO版
docker logs d-redis      # DAO版
docker logs d-neo4j      # DAO版
docker logs d-mongodb    # DAO版
docker logs d-elasticsearch # DAO版
docker logs d-weaviate   # DAO版

# 查看区块链版容器日志
docker logs b-mysql      # 区块链版
docker logs b-postgres   # 区块链版
docker logs b-redis      # 区块链版
docker logs b-neo4j      # 区块链版
docker logs b-mongodb    # 区块链版
docker logs b-elasticsearch # 区块链版
docker logs b-weaviate   # 区块链版
```

### **版本切换监控脚本**

```bash
# 创建版本切换监控脚本
cat > /opt/jobfirst-multi-version/scripts/version_monitor.sh << 'EOF'
#!/bin/bash

# 版本切换监控脚本
# 用法: ./version_monitor.sh [status|health|logs]

ACTION=$1
BASE_DIR="/opt/jobfirst-multi-version"

if [ -z "$ACTION" ]; then
    echo "用法: $0 [status|health|logs]"
    exit 1
fi

case $ACTION in
    "status")
        echo "=== 版本切换状态监控 ==="
        echo "当前运行版本:"
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(f-|d-|b-)"
        
        echo -e "\n=== 所有版本状态 ==="
        echo "Future版状态:"
        cd $BASE_DIR/future && docker-compose ps 2>/dev/null || echo "Future版未运行"
        
        echo -e "\nDAO版状态:"
        cd $BASE_DIR/dao && docker-compose ps 2>/dev/null || echo "DAO版未运行"
        
        echo -e "\n区块链版状态:"
        cd $BASE_DIR/blockchain && docker-compose ps 2>/dev/null || echo "区块链版未运行"
        ;;
    "health")
        echo "=== 版本健康检查 ==="
        echo "检查当前运行版本健康状态..."
        
        # 检查容器状态
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(f-|d-|b-)"
        
        # 检查端口监听
        echo -e "\n检查端口监听状态:"
        netstat -tlnp | grep -E "(3306|3307|3308|5432|5433|5434|5435|5436|5437|6379|6380|6381|7474|7475|7476|7687|7688|7689|27017|27018|27019|9200|9201|9202|8082|8083|8084|9506|9507|9508|7534|7535|7536)"
        
        # 检查防火墙状态
        echo -e "\n检查防火墙状态:"
        sudo ufw status numbered
        ;;
    "logs")
        echo "=== 版本日志查看 ==="
        echo "查看当前运行版本日志..."
        
        # 获取当前运行版本
        CURRENT_VERSION=$(docker ps --format "{{.Names}}" | grep -E "(f-|d-|b-)" | head -1 | cut -d'-' -f1)
        
        if [ -z "$CURRENT_VERSION" ]; then
            echo "没有运行任何版本"
            exit 1
        fi
        
        echo "当前运行版本: $CURRENT_VERSION"
        
        # 查看日志
        case $CURRENT_VERSION in
            "f")
                echo "查看Future版日志..."
                docker logs f-mysql --tail 10
                docker logs f-postgres --tail 10
                docker logs f-redis --tail 10
                docker logs f-neo4j --tail 10
                docker logs f-mongodb --tail 10
                docker logs f-elasticsearch --tail 10
                docker logs f-weaviate --tail 10
                ;;
            "d")
                echo "查看DAO版日志..."
                docker logs d-mysql --tail 10
                docker logs d-postgres --tail 10
                docker logs d-redis --tail 10
                docker logs d-neo4j --tail 10
                docker logs d-mongodb --tail 10
                docker logs d-elasticsearch --tail 10
                docker logs d-weaviate --tail 10
                ;;
            "b")
                echo "查看区块链版日志..."
                docker logs b-mysql --tail 10
                docker logs b-postgres --tail 10
                docker logs b-redis --tail 10
                docker logs b-neo4j --tail 10
                docker logs b-mongodb --tail 10
                docker logs b-elasticsearch --tail 10
                docker logs b-weaviate --tail 10
                ;;
        esac
        ;;
    *)
        echo "错误: 不支持的操作 '$ACTION'"
        echo "支持的操作: status, health, logs"
        exit 1
        ;;
esac
EOF

# 设置执行权限
chmod +x /opt/jobfirst-multi-version/scripts/version_monitor.sh
```

### **版本切换监控使用说明**

```bash
# 检查版本状态
/opt/jobfirst-multi-version/scripts/version_monitor.sh status

# 检查版本健康状态
/opt/jobfirst-multi-version/scripts/version_monitor.sh health

# 查看版本日志
/opt/jobfirst-multi-version/scripts/version_monitor.sh logs
```

---

**腾讯云数据库安装完成！所有数据库已按照命名规范计划成功部署！** 🚀

## 🎯 版本切换模式总结

### **架构优势**
- **资源优化**: 同一时间只运行一个版本，避免资源冲突
- **管理简化**: 通过脚本快速切换，无需手动操作
- **数据隔离**: 每个版本使用独立的数据卷和网络
- **端口统一**: 每个版本使用相同的内部端口，外部端口不同
- **故障隔离**: 一个版本的问题不会影响其他版本
- **安全性提升**: 只开放当前版本的端口，减少安全风险
- **运维效率**: 脚本化管理，提高运维效率

### **版本切换命令**
```bash
# 切换到Future版
./switch_to_future.sh

# 切换到DAO版
./switch_to_dao.sh

# 切换到区块链版
./switch_to_blockchain.sh

# 查看当前版本
/opt/jobfirst-multi-version/scripts/switch_version.sh
```

### **监控命令**
```bash
# 检查版本状态
/opt/jobfirst-multi-version/scripts/version_monitor.sh status

# 检查版本健康状态
/opt/jobfirst-multi-version/scripts/version_monitor.sh health

# 查看版本日志
/opt/jobfirst-multi-version/scripts/version_monitor.sh logs
```

**版本切换模式已成功实现！** 🎉
