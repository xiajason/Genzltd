# 腾讯云数据库镜像下载包

**创建时间**: 2025年1月28日  
**目标**: 为腾讯云服务器准备所有需要的数据库镜像，实现快速部署  
**状态**: 📦 镜像包准备完成

---

## 🎯 项目结构

```
tencent_cloud_database/
├── future/                    # Future版数据库镜像
│   ├── mysql_8.0.35.tar
│   ├── postgres_15.5.tar
│   ├── redis_7.2-alpine.tar
│   ├── neo4j_5.15.0.tar
│   ├── mongo_7.0.4.tar
│   ├── elasticsearch_8.11.1.tar
│   ├── semitechnologies_weaviate_1.21.5.tar
│   ├── postgres_15.5.tar  # AI服务数据库
│   ├── postgres_15.5.tar  # DAO系统数据库
│   └── postgres_15.5.tar  # 企业信用数据库
├── dao/                       # DAO版数据库镜像
│   ├── mysql_8.0.35.tar
│   ├── postgres_15.5.tar
│   ├── redis_7.2-alpine.tar
│   ├── neo4j_5.15.0.tar
│   ├── mongo_7.0.4.tar
│   ├── elasticsearch_8.11.1.tar
│   ├── semitechnologies_weaviate_1.21.5.tar
│   ├── postgres_15.5.tar  # AI服务数据库
│   ├── postgres_15.5.tar  # DAO系统数据库
│   └── postgres_15.5.tar  # 企业信用数据库
├── blockchain/                # 区块链版数据库镜像
│   ├── mysql_8.0.35.tar
│   ├── postgres_15.5.tar
│   ├── redis_7.2-alpine.tar
│   ├── neo4j_5.15.0.tar
│   ├── mongo_7.0.4.tar
│   ├── elasticsearch_8.11.1.tar
│   ├── semitechnologies_weaviate_1.21.5.tar
│   ├── postgres_15.5.tar  # AI服务数据库
│   ├── postgres_15.5.tar  # DAO系统数据库
│   └── postgres_15.5.tar  # 企业信用数据库
├── download_database_images.sh    # 完整下载脚本
├── simple_download.sh              # 简化下载脚本
├── deploy_to_tencent.sh            # 部署脚本
└── README.md                       # 说明文档
```

---

## 🚀 使用方法

### **第一步：下载数据库镜像**

#### **方法一：使用简化脚本 (推荐)**
```bash
# 运行简化下载脚本
./simple_download.sh
```

#### **方法二：使用完整脚本**
```bash
# 运行完整下载脚本 (包含配置文件)
./download_database_images.sh
```

### **第二步：上传到腾讯云服务器**

```bash
# 使用scp上传整个目录
scp -r -i ~/.ssh/basic.pem tencent_cloud_database/ ubuntu@101.33.251.158:/opt/

# 或者使用rsync (推荐)
rsync -avz -e "ssh -i ~/.ssh/basic.pem" tencent_cloud_database/ ubuntu@101.33.251.158:/opt/tencent_cloud_database/
```

### **第三步：在腾讯云服务器上部署**

```bash
# 连接到腾讯云服务器
ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158

# 进入数据库目录
cd /opt/tencent_cloud_database

# 部署Future版数据库
./deploy_to_tencent.sh future

# 部署DAO版数据库
./deploy_to_tencent.sh dao

# 部署区块链版数据库
./deploy_to_tencent.sh blockchain
```

---

## 📊 镜像信息

### **数据库版本列表**

| 数据库 | 版本 | 大小 | 用途 |
|--------|------|------|------|
| **MySQL** | 8.0.35 | ~200MB | 主数据库 |
| **PostgreSQL** | 15.5 | ~150MB | 向量数据库 |
| **Redis** | 7.2-alpine | ~50MB | 缓存数据库 |
| **Neo4j** | 5.15.0 | ~300MB | 图数据库 |
| **MongoDB** | 7.0.4 | ~200MB | 文档数据库 |
| **Elasticsearch** | 8.11.1 | ~500MB | 搜索引擎 |
| **Weaviate** | 1.21.5 | ~400MB | 向量数据库 |
| **AI服务数据库** | 15.5 | ~150MB | AI身份网络 |
| **DAO系统数据库** | 15.5 | ~150MB | DAO治理 |
| **企业信用数据库** | 15.5 | ~150MB | 企业信用 |

### **总计统计**
- **镜像数量**: 10个数据库 × 3个版本 = 30个镜像文件
- **总大小**: 约3-15GB (取决于压缩率)
- **部署时间**: 每个版本约8-15分钟

---

## 🔧 部署脚本说明

### **deploy_to_tencent.sh**
```bash
#!/bin/bash
# 腾讯云数据库部署脚本
# 使用方法: ./deploy_to_tencent.sh [future|dao|blockchain]

VERSION=${1:-future}

# 功能:
# 1. 加载指定版本的数据库镜像
# 2. 启动Docker Compose服务
# 3. 检查服务状态
# 4. 显示部署结果
```

### **simple_download.sh**
```bash
#!/bin/bash
# 简化版数据库镜像下载脚本
# 功能:
# 1. 下载10个数据库镜像
# 2. 保存到3个版本目录
# 3. 显示下载统计
```

---

## 🎯 优势

### **✅ 快速部署**
- 预下载所有镜像，避免网络问题
- 一键部署脚本，自动化安装
- 支持多版本并行部署

### **✅ 版本管理**
- 清晰的目录结构
- 版本隔离，避免冲突
- 统一的命名规范

### **✅ 离线安装**
- 不依赖网络下载
- 适合网络受限环境
- 可重复部署

---

## 📋 注意事项

### **系统要求**
- Ubuntu 22.04 LTS
- Docker 24.0+
- Docker Compose 2.24+
- Java 21 (Neo4j和Elasticsearch需要)
- Node.js 18+ (Weaviate需要)

### **内存要求**
- 每个版本至少需要4GB内存
- 建议服务器配置8GB+内存
- 确保有足够的磁盘空间

### **端口冲突**
- Future版: 3000-3999端口段
- DAO版: 4000-4999端口段
- 区块链版: 5000-5999端口段

**现在可以开始下载数据库镜像了！运行 `./simple_download.sh` 开始下载。** 🚀
