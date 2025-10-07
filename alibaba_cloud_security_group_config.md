# 阿里云多数据库集群安全组配置指南

## 🔐 需要开放的端口列表

### 1️⃣ MySQL
```yaml
端口号: 3306
协议: TCP
应用类型: MySQL/关系型数据库
来源: 腾讯云服务器 (101.33.251.158/32) 或 0.0.0.0/0 (允许所有)
优先级: 1
描述: MySQL数据库主从复制和外部访问
用途: 
  - 腾讯云从库连接
  - 数据库管理工具访问
  - 应用程序访问
```

### 2️⃣ PostgreSQL
```yaml
端口号: 5432
协议: TCP
应用类型: PostgreSQL/关系型数据库
来源: 腾讯云服务器 (101.33.251.158/32) 或 0.0.0.0/0 (允许所有)
优先级: 1
描述: PostgreSQL数据库流复制和外部访问
用途:
  - 腾讯云从库连接
  - 数据库管理工具访问
  - 应用程序访问
```

### 3️⃣ Redis
```yaml
端口号: 6379
协议: TCP
应用类型: Redis/缓存数据库
来源: 腾讯云服务器 (101.33.251.158/32) 或 0.0.0.0/0 (允许所有)
优先级: 1
描述: Redis数据库主从复制和外部访问
用途:
  - 腾讯云从库连接
  - Redis客户端访问
  - 应用程序访问
```

### 4️⃣ Neo4j (HTTP)
```yaml
端口号: 7474
协议: TCP
应用类型: Neo4j HTTP/图数据库
来源: 腾讯云服务器 (101.33.251.158/32) 或 0.0.0.0/0 (允许所有)
优先级: 1
描述: Neo4j HTTP接口访问
用途:
  - Neo4j浏览器界面
  - HTTP API访问
  - 应用程序访问
```

### 5️⃣ Neo4j (Bolt)
```yaml
端口号: 7687
协议: TCP
应用类型: Neo4j Bolt/图数据库
来源: 腾讯云服务器 (101.33.251.158/32) 或 0.0.0.0/0 (允许所有)
优先级: 1
描述: Neo4j Bolt协议连接
用途:
  - Neo4j客户端连接
  - 集群复制
  - 应用程序访问
```

### 6️⃣ Elasticsearch (HTTP)
```yaml
端口号: 9200
协议: TCP
应用类型: Elasticsearch HTTP/搜索引擎
来源: 腾讯云服务器 (101.33.251.158/32) 或 0.0.0.0/0 (允许所有)
优先级: 1
描述: Elasticsearch HTTP接口访问
用途:
  - Elasticsearch HTTP API
  - 跨集群复制
  - 应用程序访问
```

### 7️⃣ Elasticsearch (Transport)
```yaml
端口号: 9300
协议: TCP
应用类型: Elasticsearch Transport/搜索引擎
来源: 腾讯云服务器 (101.33.251.158/32) 或 0.0.0.0/0 (允许所有)
优先级: 1
描述: Elasticsearch节点间通信
用途:
  - 集群节点通信
  - 跨集群复制
  - 集群管理
```

### 8️⃣ Weaviate
```yaml
端口号: 8080
协议: TCP
应用类型: Weaviate/向量数据库
来源: 腾讯云服务器 (101.33.251.158/32) 或 0.0.0.0/0 (允许所有)
优先级: 1
描述: Weaviate HTTP接口访问
用途:
  - Weaviate HTTP API
  - 跨集群复制
  - 应用程序访问
```

## 📋 端口开放清单汇总

### 必须开放的端口 (8个)
```
端口    协议    数据库           用途
3306    TCP     MySQL           数据库主从复制和外部访问
5432    TCP     PostgreSQL      数据库流复制和外部访问
6379    TCP     Redis           数据库主从复制和外部访问
7474    TCP     Neo4j           HTTP接口访问
7687    TCP     Neo4j           Bolt协议连接
9200    TCP     Elasticsearch   HTTP接口访问
9300    TCP     Elasticsearch   节点间通信
8080    TCP     Weaviate        HTTP接口访问
```

## 🔧 阿里云安全组配置步骤

### 方法一: 阿里云控制台配置

#### 1. 登录阿里云控制台
```
1. 访问: https://ecs.console.aliyun.com
2. 选择区域: 确保选择正确的地域
3. 进入: 网络与安全 > 安全组
```

#### 2. 选择安全组
```
1. 找到您的ECS实例对应的安全组
2. 点击 "配置规则"
3. 选择 "入方向" 规则
```

#### 3. 添加安全组规则
```
对于每个端口，点击 "添加安全组规则"，填写以下信息:

规则方向: 入方向
授权策略: 允许
协议类型: 自定义TCP
端口范围: [对应端口号]
授权对象: 
  - 腾讯云专用: 101.33.251.158/32
  - 或者全部开放: 0.0.0.0/0
优先级: 1
描述: [对应描述]
```

### 方法二: 阿里云CLI配置

#### 批量添加安全组规则脚本
```bash
#!/bin/bash
# 阿里云安全组规则批量添加脚本

SECURITY_GROUP_ID="sg-xxxxxxxxxxxxxx"  # 替换为您的安全组ID
REGION_ID="cn-hangzhou"                 # 替换为您的地域ID

# 添加MySQL端口
aliyun ecs AuthorizeSecurityGroup \
  --SecurityGroupId $SECURITY_GROUP_ID \
  --RegionId $REGION_ID \
  --IpProtocol tcp \
  --PortRange 3306/3306 \
  --SourceCidrIp 0.0.0.0/0 \
  --Description "MySQL数据库主从复制和外部访问"

# 添加PostgreSQL端口
aliyun ecs AuthorizeSecurityGroup \
  --SecurityGroupId $SECURITY_GROUP_ID \
  --RegionId $REGION_ID \
  --IpProtocol tcp \
  --PortRange 5432/5432 \
  --SourceCidrIp 0.0.0.0/0 \
  --Description "PostgreSQL数据库流复制和外部访问"

# 添加Redis端口
aliyun ecs AuthorizeSecurityGroup \
  --SecurityGroupId $SECURITY_GROUP_ID \
  --RegionId $REGION_ID \
  --IpProtocol tcp \
  --PortRange 6379/6379 \
  --SourceCidrIp 0.0.0.0/0 \
  --Description "Redis数据库主从复制和外部访问"

# 添加Neo4j HTTP端口
aliyun ecs AuthorizeSecurityGroup \
  --SecurityGroupId $SECURITY_GROUP_ID \
  --RegionId $REGION_ID \
  --IpProtocol tcp \
  --PortRange 7474/7474 \
  --SourceCidrIp 0.0.0.0/0 \
  --Description "Neo4j HTTP接口访问"

# 添加Neo4j Bolt端口
aliyun ecs AuthorizeSecurityGroup \
  --SecurityGroupId $SECURITY_GROUP_ID \
  --RegionId $REGION_ID \
  --IpProtocol tcp \
  --PortRange 7687/7687 \
  --SourceCidrIp 0.0.0.0/0 \
  --Description "Neo4j Bolt协议连接"

# 添加Elasticsearch HTTP端口
aliyun ecs AuthorizeSecurityGroup \
  --SecurityGroupId $SECURITY_GROUP_ID \
  --RegionId $REGION_ID \
  --IpProtocol tcp \
  --PortRange 9200/9200 \
  --SourceCidrIp 0.0.0.0/0 \
  --Description "Elasticsearch HTTP接口访问"

# 添加Elasticsearch Transport端口
aliyun ecs AuthorizeSecurityGroup \
  --SecurityGroupId $SECURITY_GROUP_ID \
  --RegionId $REGION_ID \
  --IpProtocol tcp \
  --PortRange 9300/9300 \
  --SourceCidrIp 0.0.0.0/0 \
  --Description "Elasticsearch节点间通信"

# 添加Weaviate端口
aliyun ecs AuthorizeSecurityGroup \
  --SecurityGroupId $SECURITY_GROUP_ID \
  --RegionId $REGION_ID \
  --IpProtocol tcp \
  --PortRange 8080/8080 \
  --SourceCidrIp 0.0.0.0/0 \
  --Description "Weaviate HTTP接口访问"

echo "✅ 所有安全组规则添加完成！"
```

## 🔒 安全建议

### 推荐配置 (最安全)
```yaml
授权对象: 101.33.251.158/32
说明: 只允许腾讯云服务器访问
优点: 最高安全性
缺点: 需要手动添加其他授权IP
```

### 便捷配置 (较安全)
```yaml
授权对象: 0.0.0.0/0
说明: 允许所有IP访问
优点: 配置简单，访问方便
缺点: 安全性较低
建议: 
  - 数据库必须配置强密码
  - 启用数据库防火墙
  - 定期审计访问日志
```

### 混合配置 (推荐)
```yaml
核心数据库 (MySQL, PostgreSQL):
  授权对象: 101.33.251.158/32 (仅腾讯云)
  
其他数据库 (Redis, Neo4j, ES, Weaviate):
  授权对象: 0.0.0.0/0 (开放访问)
  
说明: 核心业务数据库限制访问，其他服务开放访问
```

## ✅ 配置验证

### 配置完成后验证
```bash
# 从腾讯云服务器测试连接
ssh -i ~/.ssh/basic.pem root@101.33.251.158

# 测试MySQL连接
telnet 47.115.168.107 3306

# 测试PostgreSQL连接
telnet 47.115.168.107 5432

# 测试Redis连接
telnet 47.115.168.107 6379

# 测试Neo4j HTTP连接
curl http://47.115.168.107:7474

# 测试Elasticsearch连接
curl http://47.115.168.107:9200

# 测试Weaviate连接
curl http://47.115.168.107:8080/v1/meta
```

## 📊 快速配置表格 (复制到阿里云控制台)

```
序号 | 端口  | 协议 | 授权对象           | 描述
----|------|------|-------------------|----------------------------------
1   | 3306 | TCP  | 0.0.0.0/0         | MySQL数据库主从复制和外部访问
2   | 5432 | TCP  | 0.0.0.0/0         | PostgreSQL数据库流复制和外部访问
3   | 6379 | TCP  | 0.0.0.0/0         | Redis数据库主从复制和外部访问
4   | 7474 | TCP  | 0.0.0.0/0         | Neo4j HTTP接口访问
5   | 7687 | TCP  | 0.0.0.0/0         | Neo4j Bolt协议连接
6   | 9200 | TCP  | 0.0.0.0/0         | Elasticsearch HTTP接口访问
7   | 9300 | TCP  | 0.0.0.0/0         | Elasticsearch节点间通信
8   | 8080 | TCP  | 0.0.0.0/0         | Weaviate HTTP接口访问
```

## 🎯 注意事项

### 1. 数据库绑定地址
确保数据库容器已绑定到 0.0.0.0，而不是 127.0.0.1:
```bash
# 检查容器端口绑定
docker ps --format "table {{.Names}}\t{{.Ports}}"

# 应该看到类似: 0.0.0.0:3306->3306/tcp
# 而不是: 127.0.0.1:3306->3306/tcp
```

### 2. 防火墙配置
确保服务器内部防火墙也允许这些端口:
```bash
# 检查防火墙状态
systemctl status firewalld

# 如果防火墙启用，添加规则
firewall-cmd --permanent --add-port=3306/tcp
firewall-cmd --permanent --add-port=5432/tcp
firewall-cmd --permanent --add-port=6379/tcp
firewall-cmd --permanent --add-port=7474/tcp
firewall-cmd --permanent --add-port=7687/tcp
firewall-cmd --permanent --add-port=9200/tcp
firewall-cmd --permanent --add-port=9300/tcp
firewall-cmd --permanent --add-port=8080/tcp
firewall-cmd --reload
```

### 3. 密码安全
所有数据库都已配置密码保护:
```yaml
MySQL: f_mysql_password_2025
PostgreSQL: f_postgres_password_2025
Redis: f_redis_password_2025
Neo4j: f_neo4j_password_2025
```

---
**🎉 配置完成后，阿里云多数据库集群将可以进行外部访问，支持跨云数据同步！** 🚀
EOF"