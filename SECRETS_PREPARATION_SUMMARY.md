# GitHub Secrets准备总结

**生成时间**: 2025年10月7日  
**状态**: ✅ 信息已准备完毕

---

## 🔐 4个Secrets信息总结

### **1. TENCENT_CLOUD_USER**
```yaml
名称: TENCENT_CLOUD_USER
值: ubuntu
说明: 腾讯云SSH登录用户名
状态: ✅ 已确认
```

### **2. TENCENT_CLOUD_SSH_KEY**
```yaml
名称: TENCENT_CLOUD_SSH_KEY
值: (basic.pem的完整内容)
说明: SSH私钥，26行内容
位置: ~/.ssh/basic.pem
状态: ✅ 文件已找到

获取命令:
  cat ~/.ssh/basic.pem

注意:
  - 必须复制完整内容
  - 包括 -----BEGIN RSA PRIVATE KEY-----
  - 包括 -----END RSA PRIVATE KEY-----
  - 所有中间行都要复制
```

### **3. TENCENT_DB_PASSWORD**
```yaml
名称: TENCENT_DB_PASSWORD
推荐值: jobfirst123
说明: 腾讯云MySQL和PostgreSQL密码
来源: 项目配置文件中发现的密码
状态: ⚠️ 需要您确认

确认方法:
  方法一: SSH连接腾讯云测试
    ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158
    mysql -u root -p
    # 输入密码测试

  方法二: 如果不确定，可以重置密码
    # 建议使用统一密码便于管理

建议:
  - 如果现有密码是 jobfirst123，直接使用
  - 如果不确定，建议重置为新密码
  - 密码建议使用字母数字组合，避免特殊字符
```

### **4. JWT_SECRET**
```yaml
名称: JWT_SECRET
值: 4PACMyWp7OZn4zzHuS7uZCqhWgz9OyEyYtpKIdyXKi0=
说明: 刚刚生成的JWT密钥
状态: ✅ 已生成

重要:
  - 这个密钥已经生成，请保存
  - 如果丢失，可以重新生成: openssl rand -base64 32
  - 但建议使用上面生成的密钥保持一致性
```

---

## 📋 配置GitHub Secrets步骤

### **步骤1: 打开GitHub仓库**
1. 访问您的GitHub仓库
2. 如果是私有仓库，请先登录GitHub

### **步骤2: 进入Settings**
1. 点击仓库页面顶部的 **Settings** 标签
2. 如果看不到Settings，说明您没有仓库管理员权限

### **步骤3: 进入Secrets设置**
1. 在左侧菜单找到: **Secrets and variables**
2. 点击展开，选择: **Actions**
3. 您会看到 "Repository secrets" 页面

### **步骤4: 添加第1个Secret**
```yaml
操作:
  1. 点击 "New repository secret" 按钮
  2. Name输入: TENCENT_CLOUD_USER
  3. Secret输入: ubuntu
  4. 点击 "Add secret" 按钮
  5. 看到绿色提示 "Secret added" ✅
```

### **步骤5: 添加第2个Secret (SSH密钥)**
```yaml
操作:
  1. 点击 "New repository secret" 按钮
  2. Name输入: TENCENT_CLOUD_SSH_KEY
  3. 在本地终端运行: cat ~/.ssh/basic.pem
  4. 复制完整输出 (包括 BEGIN 和 END 行)
  5. 粘贴到 Secret 文本框
  6. 点击 "Add secret" 按钮
  7. 看到绿色提示 "Secret added" ✅

重要:
  - 必须是完整的26行内容
  - 不要遗漏任何一行
  - 包括开头和结尾的标记行
```

### **步骤6: 添加第3个Secret (数据库密码)**
```yaml
操作:
  1. 点击 "New repository secret" 按钮
  2. Name输入: TENCENT_DB_PASSWORD
  3. Secret输入: jobfirst123 (或您确认的密码)
  4. 点击 "Add secret" 按钮
  5. 看到绿色提示 "Secret added" ✅

如果不确定密码:
  - 先使用 jobfirst123 试试
  - 如果部署失败，SSH登录腾讯云确认密码
  - 然后更新这个Secret
```

### **步骤7: 添加第4个Secret (JWT密钥)**
```yaml
操作:
  1. 点击 "New repository secret" 按钮
  2. Name输入: JWT_SECRET
  3. Secret输入: 4PACMyWp7OZn4zzHuS7uZCqhWgz9OyEyYtpKIdyXKi0=
  4. 点击 "Add secret" 按钮
  5. 看到绿色提示 "Secret added" ✅
```

---

## ✅ 验证配置

### **检查Secrets列表**
配置完成后，在 "Repository secrets" 页面应该看到：

```
✅ TENCENT_CLOUD_USER        Updated now by you
✅ TENCENT_CLOUD_SSH_KEY     Updated now by you
✅ TENCENT_DB_PASSWORD       Updated now by you
✅ JWT_SECRET                Updated now by you

Total: 4 secrets
```

### **注意事项**
- ✅ Secrets一旦保存就看不到内容了
- ✅ 只能看到名称和更新时间
- ✅ 可以随时更新或删除
- ✅ GitHub Actions运行时会自动隐藏密钥值

---

## 🚀 配置完成后的下一步

### **立即测试CI/CD**
```bash
方法一: 手动触发 (推荐)
  1. GitHub仓库 → Actions标签
  2. 左侧选择 "Deploy to Tencent Cloud"
  3. 点击 "Run workflow" 按钮
  4. Branch: main
  5. Environment: production
  6. Services: zervigo (先测试单个服务)
  7. 点击 "Run workflow"
  8. 观察部署过程

方法二: 推送代码触发
  git add .
  git commit -m "feat: 启动CI/CD自动部署"
  git push origin main
```

### **观察部署过程**
1. 在Actions页面查看工作流执行
2. 展开每个步骤查看详细日志
3. 等待约10-15分钟 (Zervigo部署)
4. 查看健康检查结果

### **验证部署成功**
```bash
# SSH连接腾讯云
ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158

# 检查Zervigo服务
curl http://localhost:8207/health

# 查看进程
ps aux | grep unified-auth

# 查看日志
tail -f /opt/services/zervigo/logs/zervigo.log
```

---

## 🎯 配置清单

- [ ] 1. 复制SSH密钥内容
- [ ] 2. 记录JWT密钥: 4PACMyWp7OZn4zzHuS7uZCqhWgz9OyEyYtpKIdyXKi0=
- [ ] 3. 确认数据库密码 (推荐: jobfirst123)
- [ ] 4. 打开GitHub仓库Settings
- [ ] 5. 添加TENCENT_CLOUD_USER
- [ ] 6. 添加TENCENT_CLOUD_SSH_KEY
- [ ] 7. 添加TENCENT_DB_PASSWORD
- [ ] 8. 添加JWT_SECRET
- [ ] 9. 验证4个Secrets都已添加
- [ ] 10. 手动触发工作流测试

---

**🎯 准备好了吗？现在就打开GitHub仓库，开始配置Secrets！** 🚀

---
*准备时间: 已完成*  
*配置时间: 约10-15分钟*  
*测试时间: 约10-15分钟*  
*总计: 约30分钟即可完成首次部署*
