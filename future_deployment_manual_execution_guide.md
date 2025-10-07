# Future版部署手动执行指南

**创建时间**: 2025年10月4日  
**版本**: v1.0  
**状态**: 🚀 **准备执行**  
**目标**: 手动执行阿里云和腾讯云环境的Future版部署

---

## 🎯 部署执行总览

### **部署状态**
- **阿里云部署**: ⚠️ 需要手动执行（配置文件不存在）
- **腾讯云部署**: ✅ 准备完成（部署包和脚本已准备）
- **总体状态**: 需要手动执行配置和部署

---

## 📋 手动执行步骤

### **阿里云环境手动部署**

#### **步骤1: 准备配置文件**
```bash
# 1. 检查当前目录
pwd
ls -la | grep -E "(docker-compose|\.env)"

# 2. 如果不存在docker-compose.yml，创建基础配置
cat > docker-compose.yml << 'EOF'
version: '3.8'
services:
  # 基础服务配置
EOF

# 3. 如果不存在.env，创建基础环境变量
cat > .env << 'EOF'
# 基础环境变量
APP_ENV=production
EOF
```

#### **步骤2: 应用Future版配置**
```bash
# 1. 备份现有配置
cp docker-compose.yml docker-compose.yml.backup
cp .env .env.backup

# 2. 应用Future版Docker Compose配置
cp aliyun-future-docker-compose.yml docker-compose.yml

# 3. 应用Future版环境变量配置
cp aliyun-future.env .env

# 4. 验证配置
docker-compose config
```

#### **步骤3: 启动服务**
```bash
# 1. 停止现有服务（如果有）
docker-compose down

# 2. 启动Future版服务
docker-compose up -d

# 3. 检查服务状态
docker-compose ps

# 4. 检查端口状态
netstat -tlnp | grep -E "(7510|7511|6383|5435|27019|7476|7689|9203|8083)"
```

#### **步骤4: 验证部署**
```bash
# 1. 检查服务健康
curl -s http://localhost:7510/health
curl -s http://localhost:7511/health

# 2. 检查数据库连接
docker-compose exec future-redis redis-cli ping
docker-compose exec future-postgres psql -U jobfirst_future -d jobfirst_future -c "SELECT 1;"

# 3. 检查日志
docker-compose logs future-ai-gateway
docker-compose logs future-resume-ai
```

### **腾讯云环境手动部署**

#### **步骤1: 准备部署文件**
```bash
# 1. 检查部署文件
ls -la | grep tencent

# 2. 设置脚本权限
chmod +x tencent-*.sh

# 3. 验证脚本内容
cat tencent-install.sh
cat tencent-start.sh
cat tencent-stop.sh
cat tencent-status.sh
```

#### **步骤2: 上传到腾讯云服务器**
```bash
# 1. 上传部署包
scp tencent-future-deployment-package.json user@tencent-server:/opt/
scp tencent-*.sh user@tencent-server:/opt/

# 2. 设置服务器权限
ssh user@tencent-server 'chmod +x /opt/tencent-*.sh'

# 3. 验证上传
ssh user@tencent-server 'ls -la /opt/tencent-*'
```

#### **步骤3: 执行安装**
```bash
# 1. 连接到腾讯云服务器
ssh user@tencent-server

# 2. 执行安装脚本
cd /opt
./tencent-install.sh

# 3. 启动服务
./tencent-start.sh

# 4. 检查状态
./tencent-status.sh
```

#### **步骤4: 验证部署**
```bash
# 1. 检查服务状态
./tencent-status.sh

# 2. 检查端口状态
netstat -tlnp | grep -E "(7510|7511|6383|5435|27019|7476|7689|9203|8083)"

# 3. 检查服务健康
curl -s http://localhost:7510/health
curl -s http://localhost:7511/health
```

---

## 🔧 配置文件详情

### **阿里云Docker Compose配置**
- **文件**: `aliyun-future-docker-compose.yml`
- **服务**: 8个AI服务 + 6个数据库服务
- **端口**: 8700-8727 AI服务端口 + Future版专用数据库端口
- **网络**: future-network
- **数据卷**: 持久化数据存储

### **阿里云环境变量配置**
- **文件**: `aliyun-future.env`
- **AI服务**: 端口7510, 7511
- **数据库**: Redis(6383), PostgreSQL(5435), MongoDB(27019), Neo4j(7476/7689), Elasticsearch(9203), Weaviate(8083)
- **安全**: JWT密钥、加密密钥

### **腾讯云部署包**
- **文件**: `tencent-future-deployment-package.json`
- **组件**: AI服务 + 数据库服务
- **脚本**: 4个部署脚本
- **监控**: Prometheus + Grafana

---

## 🚨 故障排除

### **常见问题**

#### **1. Docker Compose配置错误**
```bash
# 问题: 配置文件语法错误
# 解决: 验证配置文件
docker-compose config

# 问题: 端口冲突
# 解决: 检查端口占用
netstat -tlnp | grep -E "(7510|7511|6383|5435|27019|7476|7689|9203|8083)"
```

#### **2. 环境变量加载失败**
```bash
# 问题: 环境变量未加载
# 解决: 检查环境变量文件
cat .env
source .env
echo $AI_GATEWAY_PORT
```

#### **3. 服务启动失败**
```bash
# 问题: 服务启动失败
# 解决: 检查日志
docker-compose logs future-ai-gateway
docker-compose logs future-resume-ai

# 问题: 数据库连接失败
# 解决: 检查数据库状态
docker-compose exec future-redis redis-cli ping
```

#### **4. 腾讯云部署失败**
```bash
# 问题: 脚本执行失败
# 解决: 检查权限
chmod +x /opt/tencent-*.sh

# 问题: 服务启动失败
# 解决: 检查依赖
docker --version
docker-compose --version
```

---

## 📊 验证标准

### **成功标准**
- ✅ **服务启动**: 所有服务正常启动
- ✅ **端口监听**: 所有端口正常监听
- ✅ **健康检查**: 所有健康检查API正常响应
- ✅ **数据库连接**: 所有数据库连接正常
- ✅ **服务通信**: 服务间通信正常

### **验证命令**
```bash
# 检查服务状态
docker-compose ps

# 检查端口状态
netstat -tlnp | grep -E "(7510|7511|6383|5435|27019|7476|7689|9203|8083)"

# 检查服务健康
curl -s http://localhost:7510/health
curl -s http://localhost:7511/health

# 检查数据库连接
docker-compose exec future-redis redis-cli ping
docker-compose exec future-postgres psql -U jobfirst_future -d jobfirst_future -c "SELECT 1;"
```

---

## 🎯 下一步计划

### **阶段1: 立即执行 (1-2天)**
1. **阿里云**: 手动执行Docker Compose配置和环境变量更新
2. **腾讯云**: 手动执行部署包上传和安装脚本

### **阶段2: 监控配置 (3-5天)**
1. **更新Prometheus配置**: 添加AI服务监控指标
2. **更新Grafana仪表板**: 添加AI服务监控面板
3. **配置告警规则**: 设置AI服务告警

### **阶段3: 文档更新 (1-2周)**
1. **更新部署文档**: 记录新的部署流程
2. **更新API文档**: 记录新的API接口
3. **更新配置说明**: 记录新的配置参数

---

## ✅ 总结

**🎉 Future版部署配置完成！**

1. **阿里云环境**: 需要手动执行配置更新
2. **腾讯云环境**: 部署包和脚本准备完成
3. **执行计划**: 3阶段实施计划已制定
4. **验证标准**: 成功标准和验证命令已定义

**🚀 下一步**: 可以开始手动执行部署，或继续优化配置！ 🚀
