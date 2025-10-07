# 阶段六：阿里云CI/CD部署实施计划

## 📋 概述

基于项目中已有的完整CI/CD配置，本阶段将实施阿里云服务器的生产环境部署，实现环境隔离和自动化部署。

## 🎯 目标

1. **环境隔离**: 开发、测试、生产环境完全分离
2. **自动化部署**: 通过GitHub Actions实现智能CI/CD
3. **生产环境**: 阿里云ECS服务器部署
4. **监控系统**: 应用性能监控和日志聚合
5. **备份策略**: 自动化备份和灾难恢复

## 📁 现有资源分析

### ✅ 已配置的CI/CD组件

1. **GitHub Actions工作流**
   - 文件: `.github/workflows/smart-cicd.yml`
   - 功能: 智能CI/CD流水线，支持变更检测、质量检查、自动化测试、智能部署

2. **部署脚本**
   - 文件: `scripts/ci-cd-deploy.sh`
   - 功能: 完整的自动化部署脚本，支持前端/后端构建、配置更新、服务重启

3. **Docker配置**
   - 文件: `docker-compose.production.yml`
   - 功能: 生产环境Docker配置，使用阿里云镜像源

4. **配置文档**
   - `GITHUB_SECRETS_CONFIGURATION_GUIDE.md`: GitHub Secrets配置指南
   - `ALIBABA_CLOUD_CICD_IMPLEMENTATION_SUMMARY.md`: 阿里云CI/CD实施总结

## 🚀 实施步骤

### 步骤1: 阿里云服务器配置 (30分钟)

#### 1.1 ECS实例配置
```bash
# 推荐配置
- 实例规格: ecs.c6.large (2核4GB) 或更高
- 操作系统: Ubuntu 20.04 LTS
- 存储: 40GB SSD系统盘 + 100GB数据盘
- 网络: VPC专有网络
- 安全组: 开放22(SSH), 80(HTTP), 443(HTTPS), 8080(API), 8206(AI)
```

#### 1.2 系统环境准备
```bash
# 安装Docker和Docker Compose
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# 安装Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 安装必要工具
sudo apt update
sudo apt install -y nginx mysql-client redis-tools postgresql-client
```

#### 1.3 目录结构创建
```bash
# 创建部署目录
sudo mkdir -p /opt/jobfirst/{configs,logs,uploads,temp,backup}
sudo chown -R $USER:$USER /opt/jobfirst
```

### 步骤2: GitHub Secrets配置 (15分钟)

#### 2.1 配置SSH密钥
```bash
# 在本地生成SSH密钥对
ssh-keygen -t rsa -b 4096 -C "github-actions@jobfirst.com" -f ~/.ssh/github_actions_key

# 将公钥添加到阿里云ECS
ssh-copy-id -i ~/.ssh/github_actions_key.pub root@your-alibaba-cloud-ip
```

#### 2.2 配置GitHub Secrets
在GitHub仓库设置中添加以下Secrets：

| Secret名称 | 值 | 说明 |
|-----------|----|----|
| `ALIBABA_CLOUD_SERVER_IP` | 阿里云ECS公网IP | 例如: 47.xxx.xxx.xxx |
| `ALIBABA_CLOUD_SERVER_USER` | root | 服务器用户名 |
| `ALIBABA_CLOUD_DEPLOY_PATH` | /opt/jobfirst | 部署路径 |
| `ALIBABA_CLOUD_SSH_PRIVATE_KEY` | SSH私钥内容 | 完整的私钥文件内容 |

### 步骤3: 环境隔离配置 (20分钟)

#### 3.1 多环境配置
```yaml
# 开发环境 (本地)
environment: development
database:
  host: localhost
  name: jobfirst_dev

# 测试环境 (阿里云测试实例)
environment: testing  
database:
  host: test-db-server
  name: jobfirst_test

# 生产环境 (阿里云生产实例)
environment: production
database:
  host: prod-db-server
  name: jobfirst_prod
```

#### 3.2 分支策略
- `main`: 生产环境，自动部署到阿里云生产服务器
- `develop`: 开发环境，部署到阿里云测试服务器
- `feature/*`: 功能分支，仅执行质量检查

### 步骤4: 触发CI/CD部署 (10分钟)

#### 4.1 手动触发
```bash
# 在GitHub Actions页面手动触发
1. 进入仓库的Actions页面
2. 选择"Smart CI/CD Pipeline"
3. 点击"Run workflow"
4. 选择目标环境: production
5. 点击"Run workflow"
```

#### 4.2 自动触发
```bash
# 推送到main分支自动触发生产部署
git add .
git commit -m "feat: 完成数据库统一和微服务适配"
git push origin main
```

### 步骤5: 部署验证 (15分钟)

#### 5.1 服务健康检查
```bash
# 检查服务状态
curl -f http://your-server-ip/health
curl -f http://your-server-ip/api/v1/consul/status
curl -f http://your-server-ip/ai/health

# 检查容器状态
docker-compose ps
```

#### 5.2 功能验证
```bash
# 前端访问测试
curl -I http://your-server-ip/

# API接口测试
curl -X GET http://your-server-ip/api/v1/health
```

### 步骤6: 监控系统设置 (30分钟)

#### 6.1 应用监控
```yaml
# 添加Prometheus监控配置
monitoring:
  enabled: true
  metrics_port: "9090"
  prometheus_enabled: true
  grafana_enabled: true
```

#### 6.2 日志聚合
```yaml
# 配置ELK Stack或类似日志系统
logging:
  level: "info"
  format: "json"
  output: "file"
  file: "/opt/jobfirst/logs/app.log"
  max_size: 100
  max_age: 30
  max_backups: 10
```

### 步骤7: 备份策略 (20分钟)

#### 7.1 数据库备份
```bash
# 创建自动备份脚本
#!/bin/bash
# 数据库备份
mysqldump -h localhost -u jobfirst -p jobfirst > /opt/jobfirst/backup/db_$(date +%Y%m%d_%H%M%S).sql

# 文件备份
tar -czf /opt/jobfirst/backup/files_$(date +%Y%m%d_%H%M%S).tar.gz /opt/jobfirst/uploads
```

#### 7.2 定时备份
```bash
# 添加到crontab
0 2 * * * /opt/jobfirst/scripts/backup.sh
```

## 🔧 技术架构

### CI/CD流水线架构
```
代码推送 → 智能检测 → 并行质量检查 → 自动化测试 → 智能部署 → 部署验证
    ↓           ↓            ↓           ↓          ↓         ↓
  GitHub   变更检测    后端/前端/配置   集成/性能/安全  阿里云ECS   健康检查
  Actions   调度       质量检查        测试         部署      功能验证
```

### 环境隔离架构
```
开发环境 (本地)    测试环境 (阿里云)    生产环境 (阿里云)
     ↓                ↓                ↓
  localhost        test-server      prod-server
  jobfirst_dev     jobfirst_test    jobfirst_prod
  develop分支      develop分支       main分支
```

## 📊 预期结果

### 部署成功指标
- ✅ GitHub Actions执行成功
- ✅ 所有服务健康检查通过
- ✅ 前端页面正常访问
- ✅ API接口正常响应
- ✅ 数据库连接正常
- ✅ 监控系统正常运行

### 性能指标
- 部署时间: < 10分钟
- 服务启动时间: < 2分钟
- 健康检查响应时间: < 1秒
- 系统可用性: > 99.9%

## 🚨 故障排除

### 常见问题
1. **SSH连接失败**: 检查密钥配置和服务器安全组
2. **部署超时**: 检查服务器资源和网络连接
3. **服务启动失败**: 检查配置文件和依赖服务
4. **健康检查失败**: 检查端口开放和服务状态

### 回滚策略
```bash
# 快速回滚到上一个版本
cd /opt/jobfirst
docker-compose down
cp -r backup/backup_YYYYMMDD_HHMMSS/* .
docker-compose up -d
```

## 📝 总结

本阶段将完成：
1. ✅ 阿里云服务器配置和SSH连接
2. ✅ GitHub Secrets配置
3. ✅ 环境隔离设置
4. ✅ CI/CD自动化部署
5. ✅ 监控和备份系统

预计总耗时: **2小时**
预计完成时间: **2024年9月10日 22:00**

---

**下一步**: 开始执行步骤1 - 阿里云服务器配置
