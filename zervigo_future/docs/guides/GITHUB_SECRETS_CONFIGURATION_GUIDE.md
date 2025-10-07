# GitHub Secrets配置指南

**更新时间**: 2025年1月14日  
**状态**: ✅ CI/CD触发成功，需要配置GitHub Secrets完成部署

## 📋 概述

为了完成AI Job Matching系统的阿里云部署，需要在GitHub仓库中配置以下Secrets。

## 🔐 必需的GitHub Secrets

### 1. **ALIBABA_CLOUD_SSH_PRIVATE_KEY**
- **描述**: 阿里云服务器的SSH私钥
- **类型**: SSH私钥文件内容
- **获取方式**: 
  ```bash
  # 如果已有SSH密钥对
  cat ~/.ssh/id_rsa
  
  # 或生成新的SSH密钥对
  ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
  ```

### 2. **ALIBABA_CLOUD_SERVER_IP**
- **描述**: 阿里云服务器的公网IP地址
- **示例**: `47.96.123.45`
- **获取方式**: 阿里云ECS控制台 → 实例详情 → 公网IP

### 3. **ALIBABA_CLOUD_SERVER_USER**
- **描述**: 阿里云服务器的登录用户名
- **示例**: `root` 或 `ubuntu`
- **获取方式**: 根据服务器操作系统确定

### 4. **ALIBABA_CLOUD_DEPLOY_PATH**
- **描述**: 阿里云服务器上的部署路径
- **示例**: `/opt/jobfirst` 或 `/var/www/html`
- **说明**: 确保该路径存在且有写权限

## 🛠️ 配置步骤

### 步骤1: 访问GitHub仓库设置
1. 打开 [GitHub仓库](https://github.com/xiajason/zervi-basic)
2. 点击 **Settings** 标签
3. 在左侧菜单中点击 **Secrets and variables** → **Actions**

### 步骤2: 添加Repository Secrets
点击 **New repository secret** 按钮，逐个添加以下Secrets：

#### Secret 1: ALIBABA_CLOUD_SSH_PRIVATE_KEY
- **Name**: `ALIBABA_CLOUD_SSH_PRIVATE_KEY`
- **Secret**: 粘贴SSH私钥的完整内容（包括`-----BEGIN OPENSSH PRIVATE KEY-----`和`-----END OPENSSH PRIVATE KEY-----`）

#### Secret 2: ALIBABA_CLOUD_SERVER_IP
- **Name**: `ALIBABA_CLOUD_SERVER_IP`
- **Secret**: 阿里云服务器的公网IP地址

#### Secret 3: ALIBABA_CLOUD_SERVER_USER
- **Name**: `ALIBABA_CLOUD_SERVER_USER`
- **Secret**: 服务器登录用户名（通常是`root`）

#### Secret 4: ALIBABA_CLOUD_DEPLOY_PATH
- **Name**: `ALIBABA_CLOUD_DEPLOY_PATH`
- **Secret**: 部署路径（例如：`/opt/jobfirst`）

### 步骤3: 验证配置
配置完成后，可以手动触发workflow来验证：
1. 访问 [GitHub Actions页面](https://github.com/xiajason/zervi-basic/actions)
2. 点击 **Smart CI/CD Pipeline**
3. 点击 **Run workflow** 按钮
4. 选择分支和参数，点击 **Run workflow**

## 🔧 阿里云服务器准备

### 1. 安装必要软件
```bash
# 更新系统
sudo apt update && sudo apt upgrade -y

# 安装Docker和Docker Compose
sudo apt install -y docker.io docker-compose
sudo systemctl enable docker
sudo systemctl start docker

# 安装Nginx
sudo apt install -y nginx

# 安装Git
sudo apt install -y git
```

### 2. 配置SSH密钥认证
```bash
# 在服务器上创建.ssh目录
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# 添加公钥到authorized_keys
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQD... your_email@example.com" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

# 确保SSH服务配置正确
sudo nano /etc/ssh/sshd_config
# 确保以下配置：
# PubkeyAuthentication yes
# AuthorizedKeysFile .ssh/authorized_keys
sudo systemctl restart ssh
```

### 3. 创建部署目录
```bash
# 创建部署目录
sudo mkdir -p /opt/jobfirst
sudo chown $USER:$USER /opt/jobfirst

# 或使用其他路径，确保与ALIBABA_CLOUD_DEPLOY_PATH一致
```

## 🚀 部署流程

配置完Secrets后，GitHub Actions将自动执行以下流程：

1. **智能检测**: 分析代码变更
2. **质量检查**: 后端、前端、配置验证
3. **自动化测试**: 集成测试、性能测试、安全测试
4. **智能部署**: 构建并部署到阿里云
5. **部署验证**: 验证服务状态和功能

## 📊 监控部署状态

### 查看GitHub Actions日志
1. 访问 [Actions页面](https://github.com/xiajason/zervi-basic/actions)
2. 点击具体的workflow run
3. 查看各个job的执行日志

### 检查服务器状态
```bash
# 连接到阿里云服务器
ssh your_user@your_server_ip

# 检查服务状态
cd /opt/jobfirst
docker-compose ps

# 查看服务日志
docker-compose logs -f
```

## ⚠️ 常见问题

### 1. SSH连接失败
- 检查SSH私钥格式是否正确
- 确认服务器IP地址和用户名
- 验证SSH服务是否运行

### 2. 权限问题
- 确认部署路径的权限设置
- 检查Docker权限配置

### 3. 服务启动失败
- 查看Docker容器日志
- 检查端口占用情况
- 验证配置文件

## 🎯 下一步

配置完成GitHub Secrets后：

1. **手动触发部署**: 在GitHub Actions页面手动运行workflow
2. **验证部署**: 检查所有服务是否正常运行
3. **功能测试**: 进行端到端功能验证
4. **监控设置**: 配置服务监控和告警

---

**配置完成后，AI Job Matching系统将通过GitHub Actions自动部署到阿里云，实现完整的CI/CD流程！** 🎉