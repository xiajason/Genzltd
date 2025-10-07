# CI/CD触发指南

## 🎯 概述

本指南详细说明如何触发GitHub Actions CI/CD自动化部署到阿里云服务器。

## 🚀 触发方式

### 1. 自动触发（推荐）

#### 1.1 推送到main分支
```bash
# 推送到main分支自动触发生产环境部署
git add .
git commit -m "feat: 完成数据库统一和微服务适配"
git push origin main
```

#### 1.2 推送到develop分支
```bash
# 推送到develop分支自动触发测试环境部署
git add .
git commit -m "feat: 新功能开发完成"
git push origin develop
```

#### 1.3 创建Pull Request
```bash
# 创建PR自动触发完整CI/CD检查
git checkout -b feature/new-feature
git add .
git commit -m "feat: 添加新功能"
git push origin feature/new-feature

# 在GitHub上创建Pull Request
# 自动触发质量检查、测试、安全扫描等
```

### 2. 手动触发

#### 2.1 通过GitHub Actions页面
1. 进入GitHub仓库: `https://github.com/your-username/zervi-basic`
2. 点击 **Actions** 标签
3. 选择 **Smart CI/CD Pipeline**
4. 点击 **Run workflow**
5. 选择参数：
   - **Force full CI/CD check**: `false` (默认)
   - **Target environment**: `auto` (自动检测)
6. 点击 **Run workflow**

#### 2.2 通过GitHub CLI
```bash
# 安装GitHub CLI
brew install gh

# 登录GitHub
gh auth login

# 手动触发工作流
gh workflow run "Smart CI/CD Pipeline" --ref main
```

## 📊 工作流执行流程

### 智能检测阶段
```
代码推送 → 智能检测 → 执行计划生成
    ↓           ↓           ↓
  GitHub   变更检测    选择部署策略
  Actions   调度        (智能/配置/最小)
```

### 并行质量检查
```
后端质量检查 ← 并行执行 → 前端质量检查
     ↓                        ↓
  代码质量、测试、安全扫描    构建验证、安全扫描
     ↓                        ↓
  质量门禁 ← 汇总结果 → 配置验证
```

### 自动化测试
```
集成测试 ← 并行执行 → 性能测试
     ↓                        ↓
  后端/前端集成测试          基准测试、负载测试
     ↓                        ↓
  安全测试 ← 汇总结果 → 部署准备
```

### 智能部署
```
构建应用 → 创建部署包 → 部署到阿里云
    ↓           ↓           ↓
  前端/后端构建  压缩打包    SSH上传执行
     ↓           ↓           ↓
  部署验证 ← 服务启动 → 健康检查
```

## 🔍 监控执行状态

### 1. GitHub Actions页面
- 访问: `https://github.com/your-username/zervi-basic/actions`
- 查看: 工作流执行状态、日志、错误信息
- 监控: 各阶段执行时间、成功率

### 2. 实时日志查看
```bash
# 使用GitHub CLI查看实时日志
gh run watch

# 查看特定工作流运行
gh run view --log
```

### 3. 服务器监控
```bash
# SSH连接到阿里云服务器
ssh root@your-alibaba-cloud-ip

# 查看部署日志
tail -f /opt/jobfirst/logs/deployment.log

# 查看服务状态
docker-compose ps
```

## 📋 执行检查清单

### 触发前检查
- [ ] 代码已提交到正确的分支
- [ ] GitHub Secrets已正确配置
- [ ] 阿里云服务器可正常访问
- [ ] 服务器有足够的资源（磁盘空间、内存）

### 执行中监控
- [ ] GitHub Actions工作流正常启动
- [ ] 智能检测阶段通过
- [ ] 并行质量检查通过
- [ ] 自动化测试通过
- [ ] 智能部署执行成功

### 执行后验证
- [ ] 服务健康检查通过
- [ ] 前端页面正常访问
- [ ] API接口正常响应
- [ ] 数据库连接正常
- [ ] 监控系统正常运行

## 🚨 故障排除

### 常见错误及解决方案

#### 1. SSH连接失败
```bash
# 错误: SSH connection failed
# 解决: 检查SSH密钥配置
ssh -i ~/.ssh/github_actions_key root@your-server-ip

# 检查服务器安全组是否开放22端口
```

#### 2. 部署超时
```bash
# 错误: Deployment timeout
# 解决: 检查服务器资源
df -h  # 检查磁盘空间
free -h  # 检查内存使用
```

#### 3. 服务启动失败
```bash
# 错误: Service startup failed
# 解决: 检查配置文件
cat /opt/jobfirst/configs/config.prod.yaml

# 检查Docker服务
systemctl status docker
```

#### 4. 健康检查失败
```bash
# 错误: Health check failed
# 解决: 检查服务状态
curl -f http://localhost:8080/health
curl -f http://localhost:8206/health

# 检查端口开放
netstat -tlnp | grep -E ":(80|8080|8206)"
```

### 回滚操作
```bash
# 快速回滚到上一个版本
cd /opt/jobfirst
docker-compose down
cp -r backup/backup_YYYYMMDD_HHMMSS/* .
docker-compose up -d
```

## 📈 性能优化

### 1. 并行执行优化
- 质量检查并行执行，减少总执行时间
- 智能跳过不必要的检查，提高效率
- 增量部署，只部署变更的部分

### 2. 缓存优化
- 使用Docker层缓存，减少构建时间
- 缓存依赖包，避免重复下载
- 使用GitHub Actions缓存，加速构建

### 3. 资源优化
- 压缩部署包，减少传输时间
- 清理临时文件，节省磁盘空间
- 优化镜像大小，减少存储使用

## 🎉 成功指标

### 部署成功标准
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

## 📝 最佳实践

### 1. 分支管理
- 使用feature分支开发新功能
- 通过PR合并到develop分支
- 定期合并develop到main分支

### 2. 提交信息
- 使用清晰的提交信息
- 遵循约定式提交规范
- 包含变更类型和描述

### 3. 测试策略
- 在本地进行充分测试
- 使用测试环境验证功能
- 生产部署前进行最终检查

---

**配置完成时间**: 2024年9月10日  
**配置状态**: ✅ 完成  
**下一步**: 触发CI/CD部署并验证结果
