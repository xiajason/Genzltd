# GitHub Secrets配置检查清单

## 🎯 目标
配置GitHub Secrets以支持阿里云CI/CD自动化部署

## 📋 配置检查清单

### ✅ 必需的Secrets

| Secret名称 | 状态 | 说明 | 示例值 |
|-----------|------|------|--------|
| `ALIBABA_CLOUD_SERVER_IP` | ⬜ | 阿里云ECS公网IP | `47.xxx.xxx.xxx` |
| `ALIBABA_CLOUD_SERVER_USER` | ⬜ | 服务器用户名 | `root` |
| `ALIBABA_CLOUD_DEPLOY_PATH` | ⬜ | 部署路径 | `/opt/jobfirst` |
| `ALIBABA_CLOUD_SSH_PRIVATE_KEY` | ⬜ | SSH私钥内容 | `-----BEGIN OPENSSH PRIVATE KEY-----...` |

### 🔧 配置步骤

#### 步骤1: 进入GitHub仓库设置
1. 打开GitHub仓库: `https://github.com/your-username/zervi-basic`
2. 点击 **Settings** 标签
3. 在左侧菜单中找到 **Secrets and variables** → **Actions**

#### 步骤2: 添加Secrets
对每个必需的Secret，点击 **New repository secret** 并填入：

**ALIBABA_CLOUD_SERVER_IP**
- Name: `ALIBABA_CLOUD_SERVER_IP`
- Value: 您的阿里云ECS公网IP地址

**ALIBABA_CLOUD_SERVER_USER**
- Name: `ALIBABA_CLOUD_SERVER_USER`
- Value: `root`

**ALIBABA_CLOUD_DEPLOY_PATH**
- Name: `ALIBABA_CLOUD_DEPLOY_PATH`
- Value: `/opt/jobfirst`

**ALIBABA_CLOUD_SSH_PRIVATE_KEY**
- Name: `ALIBABA_CLOUD_SSH_PRIVATE_KEY`
- Value: 完整的SSH私钥内容（包括BEGIN和END行）

### 🔑 SSH密钥配置

#### 生成SSH密钥对（如果还没有）
```bash
# 生成新的SSH密钥对
ssh-keygen -t rsa -b 4096 -C "github-actions@jobfirst.com" -f ~/.ssh/github_actions_key

# 查看私钥内容（复制到GitHub Secrets）
cat ~/.ssh/github_actions_key

# 查看公钥内容（添加到阿里云ECS）
cat ~/.ssh/github_actions_key.pub
```

#### 将公钥添加到阿里云ECS
```bash
# 方法1: 使用ssh-copy-id
ssh-copy-id -i ~/.ssh/github_actions_key.pub root@your-alibaba-cloud-ip

# 方法2: 手动添加
# 1. 复制公钥内容
# 2. 登录阿里云ECS
# 3. 编辑 ~/.ssh/authorized_keys
# 4. 添加公钥内容
```

### 🧪 测试连接

#### 测试SSH连接
```bash
# 测试SSH连接
ssh -i ~/.ssh/github_actions_key root@your-alibaba-cloud-ip

# 如果连接成功，您应该能够登录到阿里云ECS
```

#### 测试GitHub Actions
```bash
# 推送代码触发CI/CD
git add .
git commit -m "test: 测试GitHub Actions CI/CD"
git push origin main

# 在GitHub Actions页面查看执行状态
# https://github.com/your-username/zervi-basic/actions
```

### 📊 配置验证

#### 检查Secrets配置
- [ ] 所有4个必需的Secrets都已配置
- [ ] SSH私钥格式正确（包含BEGIN和END行）
- [ ] 服务器IP地址正确
- [ ] 部署路径正确

#### 检查SSH连接
- [ ] SSH密钥对已生成
- [ ] 公钥已添加到阿里云ECS
- [ ] SSH连接测试成功
- [ ] 可以正常登录服务器

#### 检查CI/CD触发
- [ ] GitHub Actions工作流已配置
- [ ] 推送代码后自动触发
- [ ] 部署过程无错误
- [ ] 服务健康检查通过

### 🚨 常见问题

#### SSH连接失败
```bash
# 检查密钥权限
chmod 600 ~/.ssh/github_actions_key
chmod 700 ~/.ssh

# 检查服务器安全组
# 确保开放22端口（SSH）
```

#### GitHub Actions失败
```bash
# 检查Secrets配置
# 确保所有必需的Secrets都已正确配置

# 检查服务器连接
# 确保服务器可以正常访问
```

#### 部署失败
```bash
# 检查服务器资源
# 确保有足够的磁盘空间和内存

# 检查Docker服务
# 确保Docker和Docker Compose已安装
```

### 📝 配置完成确认

配置完成后，您应该看到：

1. **GitHub Secrets页面**显示4个配置的Secrets
2. **SSH连接测试**成功
3. **GitHub Actions**可以正常执行
4. **部署过程**无错误
5. **服务健康检查**通过

### 🎉 下一步

配置完成后，您可以：

1. **触发CI/CD部署**
   ```bash
   git push origin main
   ```

2. **监控部署过程**
   - 查看GitHub Actions执行日志
   - 监控服务器资源使用情况
   - 检查服务健康状态

3. **验证部署结果**
   ```bash
   curl -f http://your-server-ip/health
   curl -f http://your-server-ip/api/v1/consul/status
   ```

---

**配置时间**: 预计15分钟  
**配置状态**: ⬜ 待配置  
**下一步**: 开始配置GitHub Secrets
