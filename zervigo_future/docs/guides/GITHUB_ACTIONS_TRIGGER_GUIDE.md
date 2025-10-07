# GitHub Actions 触发指南

## 🔍 为什么GitHub Actions没有触发？

### 问题分析

经过检查，发现GitHub Actions没有触发的原因是：

1. **Git仓库结构问题**
   - 项目的主要Git仓库在 `frontend-taro/.git`
   - 这是一个**子模块结构**，只有前端Taro项目是Git仓库
   - 我们创建的所有SSH访问配置脚本都在 `basic/scripts/` 目录下，但这个目录**不在Git仓库中**

2. **GitHub Actions配置位置**
   - GitHub Actions配置文件在 `basic/.github/workflows/deploy.yml`
   - 但这个 `.github` 目录也不在Git仓库中
   - 所以GitHub Actions实际上**无法被触发**

3. **触发条件分析**
   GitHub Actions的触发条件是：
   ```yaml
   on:
     push:
       branches: [ main, develop ]
     pull_request:
       branches: [ main ]
     workflow_dispatch:
   ```

   即使有Git仓库，我们的修改也没有推送到GitHub，因为：
   - 我们只是在本地文件系统中创建和修改文件
   - 没有执行 `git add`、`git commit`、`git push` 等Git操作

## ✅ 解决方案

### 方案1：初始化完整的Git仓库（已执行）

我们已经执行了以下步骤：

```bash
# 1. 初始化Git仓库
cd /Users/szjason72/zervi-basic/basic
git init

# 2. 添加文件到Git
git add scripts/ .github/ *.md

# 3. 提交更改
git commit -m "feat: 添加SSH访问配置和开发团队管理系统"
```

### 方案2：连接到GitHub远程仓库

要将代码推送到GitHub并触发Actions，需要：

```bash
# 1. 添加远程仓库
git remote add origin https://github.com/your-username/your-repo.git

# 2. 推送到GitHub
git push -u origin main
```

### 方案3：手动触发GitHub Actions

如果已经连接到GitHub，可以通过以下方式手动触发：

1. **通过GitHub Web界面**
   - 进入GitHub仓库页面
   - 点击 "Actions" 标签
   - 选择 "Deploy to Tencent Cloud" 工作流
   - 点击 "Run workflow" 按钮

2. **通过API触发**
   ```bash
   curl -X POST \
     -H "Authorization: token YOUR_GITHUB_TOKEN" \
     -H "Accept: application/vnd.github.v3+json" \
     https://api.github.com/repos/your-username/your-repo/actions/workflows/deploy.yml/dispatches \
     -d '{"ref":"main"}'
   ```

## 🚀 GitHub Actions 工作流说明

### 触发条件

```yaml
on:
  push:
    branches: [ main, develop ]  # 推送到main或develop分支时触发
  pull_request:
    branches: [ main ]           # 向main分支提交PR时触发
  workflow_dispatch:             # 手动触发
```

### 工作流步骤

1. **测试阶段 (test)**
   - 设置Node.js、Go、Python环境
   - 安装依赖
   - 运行前端、后端、AI服务测试

2. **构建阶段 (build)**
   - 构建前端应用 (H5和小程序)
   - 构建后端服务
   - 上传构建产物

3. **部署阶段**
   - **测试环境部署** (deploy-staging): 推送到develop分支时触发
   - **生产环境部署** (deploy-production): 推送到main分支时触发

4. **健康检查 (health-check)**
   - 检查部署后的服务健康状态

## 🔧 配置GitHub Secrets

为了GitHub Actions能够正常工作，需要在GitHub仓库中配置以下Secrets：

### 必需的Secrets

```bash
# SSH连接配置
SSH_PRIVATE_KEY                    # SSH私钥
STAGING_SERVER_IP                  # 测试环境服务器IP
STAGING_SERVER_USER                # 测试环境服务器用户
PRODUCTION_SERVER_IP               # 生产环境服务器IP
PRODUCTION_SERVER_USER             # 生产环境服务器用户

# 可选的通知配置
SLACK_WEBHOOK_URL                  # Slack通知
DINGTALK_WEBHOOK_URL               # 钉钉通知
```

### 配置步骤

1. 进入GitHub仓库页面
2. 点击 "Settings" 标签
3. 在左侧菜单中点击 "Secrets and variables" > "Actions"
4. 点击 "New repository secret" 添加每个Secret

## 📊 监控GitHub Actions

### 查看运行状态

1. **GitHub Web界面**
   - 进入仓库的 "Actions" 页面
   - 查看工作流运行历史和状态

2. **命令行工具**
   ```bash
   # 安装GitHub CLI
   brew install gh
   
   # 查看工作流运行状态
   gh run list
   
   # 查看特定运行的日志
   gh run view <run-id>
   ```

### 常见问题排查

1. **工作流没有触发**
   - 检查触发条件是否正确
   - 确认代码已推送到正确的分支
   - 验证GitHub Actions是否启用

2. **部署失败**
   - 检查SSH连接配置
   - 验证服务器访问权限
   - 查看详细的错误日志

3. **测试失败**
   - 检查依赖安装是否正确
   - 验证测试环境配置
   - 查看测试输出日志

## 🎯 最佳实践

### 1. 分支策略

```bash
# 开发分支
git checkout -b develop
git push -u origin develop

# 功能分支
git checkout -b feature/ssh-access-config
git push -u origin feature/ssh-access-config

# 主分支
git checkout main
git merge develop
git push origin main
```

### 2. 提交信息规范

```bash
# 功能添加
git commit -m "feat: 添加SSH访问配置功能"

# 问题修复
git commit -m "fix: 修复SSH连接问题"

# 文档更新
git commit -m "docs: 更新部署指南"

# 样式调整
git commit -m "style: 调整代码格式"
```

### 3. 标签管理

```bash
# 创建版本标签
git tag -a v1.0.0 -m "SSH访问配置系统v1.0.0"
git push origin v1.0.0
```

## 📞 技术支持

### 联系方式

- **GitHub Issues**: 在仓库中创建Issue
- **技术文档**: 查看项目文档
- **团队协作**: 使用开发团队管理系统

### 相关文档

- [SSH访问配置完整指南](./SSH_ACCESS_CONFIGURATION_GUIDE.md)
- [快速部署指南](./QUICK_SSH_DEPLOYMENT_GUIDE.md)
- [开发团队管理实施指南](./DEV_TEAM_MANAGEMENT_IMPLEMENTATION_GUIDE.md)

---

**注意**: 本指南基于JobFirst项目的GitHub Actions配置，请根据实际情况调整配置参数。
