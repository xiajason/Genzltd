# GitHub Secrets配置指南

**目标**: 配置GitHub Actions所需的密钥和密码  
**时间**: 约30分钟  
**优先级**: ⭐⭐⭐ 必须优先完成

---

## 🔐 需要配置的Secrets

### **1. TENCENT_CLOUD_USER**
```yaml
名称: TENCENT_CLOUD_USER
值: ubuntu
说明: 腾讯云服务器SSH登录用户名
重要性: ⭐⭐⭐ 必需
```

### **2. TENCENT_CLOUD_SSH_KEY**
```yaml
名称: TENCENT_CLOUD_SSH_KEY
值: (basic.pem文件的完整内容)
说明: SSH私钥，用于自动登录腾讯云服务器
重要性: ⭐⭐⭐ 必需

如何获取:
  1. 在本地终端运行:
     cat ~/.ssh/basic.pem
  
  2. 复制完整输出 (包括 -----BEGIN RSA PRIVATE KEY----- 和 -----END RSA PRIVATE KEY-----)
  
  3. 粘贴到GitHub Secrets中

注意:
  - 必须是完整的私钥内容
  - 包括开头和结尾的标记行
  - 不要有额外的空格或换行
```

### **3. TENCENT_DB_PASSWORD**
```yaml
名称: TENCENT_DB_PASSWORD
值: 腾讯云数据库密码
说明: MySQL和PostgreSQL的密码
重要性: ⭐⭐⭐ 必需

如何获取:
  1. SSH连接到腾讯云
  2. 查看MySQL密码配置
  3. 或者使用统一密码 (如已设置)

注意:
  - MySQL和PostgreSQL建议使用相同密码
  - 密码要有足够强度
  - 不要包含特殊字符 (避免shell转义问题)
```

### **4. JWT_SECRET**
```yaml
名称: JWT_SECRET
值: 随机生成的JWT密钥
说明: 用于JWT Token签名和验证
重要性: ⭐⭐⭐ 必需

如何生成:
  方法一 (推荐):
    openssl rand -base64 32
  
  方法二:
    python3 -c "import secrets; print(secrets.token_urlsafe(32))"
  
  方法三:
    node -e "console.log(require('crypto').randomBytes(32).toString('base64'))"

建议:
  - 长度至少32字节
  - 使用Base64编码
  - 保持唯一性
```

---

## 📋 配置步骤

### **步骤1: 获取basic.pem内容**
```bash
# 在本地终端执行
cat ~/.ssh/basic.pem

# 复制完整输出，包括:
# -----BEGIN RSA PRIVATE KEY-----
# ... (私钥内容)
# -----END RSA PRIVATE KEY-----
```

### **步骤2: 生成JWT密钥**
```bash
# 在本地终端执行
openssl rand -base64 32

# 复制输出，例如:
# ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuv==
```

### **步骤3: 确认数据库密码**
```bash
# 如果不确定，SSH连接腾讯云查看
ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158

# 查看MySQL配置
sudo cat /etc/mysql/my.cnf | grep password

# 或使用之前设置的统一密码
```

### **步骤4: 添加到GitHub**
1. **打开GitHub仓库**
   - 访问: https://github.com/your-username/genzltd

2. **进入Settings**
   - 点击仓库页面顶部的 "Settings" 标签

3. **进入Secrets设置**
   - 左侧菜单: Secrets and variables → Actions

4. **添加第一个Secret (TENCENT_CLOUD_USER)**
   - 点击 "New repository secret"
   - Name: `TENCENT_CLOUD_USER`
   - Secret: `ubuntu`
   - 点击 "Add secret"

5. **添加第二个Secret (TENCENT_CLOUD_SSH_KEY)**
   - 点击 "New repository secret"
   - Name: `TENCENT_CLOUD_SSH_KEY`
   - Secret: (粘贴basic.pem的完整内容)
   - 点击 "Add secret"

6. **添加第三个Secret (TENCENT_DB_PASSWORD)**
   - 点击 "New repository secret"
   - Name: `TENCENT_DB_PASSWORD`
   - Secret: (输入数据库密码)
   - 点击 "Add secret"

7. **添加第四个Secret (JWT_SECRET)**
   - 点击 "New repository secret"
   - Name: `JWT_SECRET`
   - Secret: (粘贴生成的JWT密钥)
   - 点击 "Add secret"

---

## ✅ 验证配置

### **检查Secrets列表**
配置完成后，应该看到以下4个Secrets：
- ✅ TENCENT_CLOUD_USER
- ✅ TENCENT_CLOUD_SSH_KEY
- ✅ TENCENT_DB_PASSWORD
- ✅ JWT_SECRET

### **注意事项**
```yaml
安全性:
  - Secrets一旦保存无法查看
  - 只能更新或删除
  - GitHub Actions运行时会自动隐藏
  - 不会出现在日志中

常见错误:
  - SSH密钥不完整 (缺少开头或结尾)
  - 密码包含特殊字符导致转义问题
  - JWT密钥太短或太简单
  - 用户名拼写错误

最佳实践:
  - 定期更换密钥和密码
  - 使用强密码
  - 限制SSH密钥权限
  - 记录密钥更换历史
```

---

## 🚀 配置完成后

### **下一步**
1. ✅ 创建或更新 .github/workflows/deploy-tencent-cloud.yml
2. ✅ 推送代码到main分支
3. ✅ 观察GitHub Actions自动部署
4. ✅ 验证服务启动成功

### **手动触发测试**
1. 进入GitHub仓库
2. 点击 "Actions" 标签
3. 选择 "Deploy to Tencent Cloud"
4. 点击 "Run workflow"
5. 选择分支: main
6. 选择服务: all
7. 点击 "Run workflow"

---

## 📊 快速参考

### **命令速查**
```bash
# 查看SSH密钥
cat ~/.ssh/basic.pem

# 生成JWT密钥
openssl rand -base64 32

# 测试SSH连接
ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158

# 查看服务器资源
ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158 "free -h && df -h"
```

### **Secrets清单**
| Secret名称 | 值来源 | 示例 |
|-----------|-------|------|
| TENCENT_CLOUD_USER | 固定值 | ubuntu |
| TENCENT_CLOUD_SSH_KEY | ~/.ssh/basic.pem | -----BEGIN RSA... |
| TENCENT_DB_PASSWORD | 数据库配置 | your_db_password |
| JWT_SECRET | 随机生成 | ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuv== |

---

**🎯 配置完成后，GitHub Actions即可自动部署服务到腾讯云！**

---
*配置时间: 约30分钟*  
*难度: ⭐⭐☆☆☆ 简单*  
*重要性: ⭐⭐⭐ 必需*  
*下一步: 创建CI/CD工作流文件*
