# CI/CD自动化部署快速开始指南

**目标**: 5分钟了解如何使用GitHub Actions自动部署到腾讯云  
**受众**: 开发者、运维人员

---

## 🎯 一句话总结

**代码推送到main分支，GitHub Actions自动部署到腾讯云，30-45分钟完成！** 🚀

---

## 🚀 快速开始 (3步)

### **第1步: 配置GitHub Secrets** (30分钟，一次性)

```bash
# 1. 获取SSH密钥
cat ~/.ssh/basic.pem

# 2. 生成JWT密钥
openssl rand -base64 32

# 3. 在GitHub仓库中添加4个Secrets:
#    - TENCENT_CLOUD_USER: ubuntu
#    - TENCENT_CLOUD_SSH_KEY: (basic.pem内容)
#    - TENCENT_DB_PASSWORD: (数据库密码)
#    - JWT_SECRET: (生成的JWT密钥)
```

详细步骤见: `GITHUB_SECRETS_SETUP_GUIDE.md`

### **第2步: 推送代码** (1分钟)

```bash
# 修改代码后
git add .
git commit -m "feat: 更新AI服务功能"
git push origin main

# GitHub Actions自动触发部署！
```

### **第3步: 查看部署** (自动完成)

1. 访问: https://github.com/your-username/genzltd/actions
2. 查看 "Deploy to Tencent Cloud" 工作流
3. 观察部署进度
4. 30-45分钟后部署完成 ✅

---

## 📊 部署流程

```
本地修改代码
    ↓
git push origin main
    ↓
GitHub Actions自动触发
    ↓
代码检查 (3-5分钟)
    ↓
构建服务 (2-3分钟)
    ↓
SSH部署到腾讯云 (20-30分钟)
├─ Zervigo (8207) ✅
├─ AI Service 1 (8100) ✅
├─ AI Service 2 (8110) ✅
└─ LoomaCRM (8700) ✅
    ↓
健康检查 (2-3分钟)
    ↓
部署完成通知 ✅
```

---

## 🎯 手动触发

**场景**: 不想推送代码，只想重新部署

**步骤**:
1. GitHub仓库 → Actions标签
2. 选择 "Deploy to Tencent Cloud"
3. Run workflow
4. 选择:
   - Branch: main
   - Environment: production
   - Services: all (或选择特定服务)
5. Run workflow

---

## ✅ 验证部署

### **方法1: GitHub Actions日志**
- 查看工作流执行日志
- 每个步骤的详细输出
- 健康检查结果

### **方法2: SSH登录检查**
```bash
# 连接腾讯云
ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158

# 检查服务进程
ps aux | grep -E 'unified-auth|ai_service|looma'

# 检查服务健康
curl http://localhost:8207/health  # Zervigo
curl http://localhost:8100/health  # AI Service 1
curl http://localhost:8110/health  # AI Service 2
curl http://localhost:8700/health  # LoomaCRM

# 查看服务日志
tail -f /opt/services/zervigo/logs/zervigo.log
tail -f /opt/services/ai-service-1/current/logs/service.log
tail -f /opt/services/ai-service-2/current/logs/service.log
tail -f /opt/services/looma-crm/current/logs/looma_crm.log
```

---

## 🔧 常见问题

### **Q1: 部署失败怎么办？**
```yaml
检查步骤:
  1. 查看GitHub Actions日志
  2. 找到失败的步骤
  3. 检查错误信息
  4. 常见问题:
     - SSH连接失败 → 检查TENCENT_CLOUD_SSH_KEY
     - 依赖安装失败 → 检查网络或依赖版本
     - 服务启动失败 → 检查数据库密码和配置
     - 健康检查失败 → 查看服务日志

解决方案:
  - 修复问题后重新推送代码
  - 或手动触发工作流
```

### **Q2: 如何回滚到上一个版本？**
```yaml
方法一: Git回滚
  git revert HEAD
  git push origin main
  # 自动部署上一个版本

方法二: 手动回滚
  ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158
  cd /opt/services/ai-service-1
  # 恢复备份
  mv current current.failed
  mv backup.YYYYMMDD_HHMMSS current
  # 重启服务
```

### **Q3: 如何只部署单个服务？**
```yaml
使用手动触发:
  1. GitHub → Actions → Deploy to Tencent Cloud
  2. Run workflow
  3. Services: 选择特定服务
     - zervigo: 只部署Zervigo
     - ai1: 只部署AI Service 1
     - ai2: 只部署AI Service 2
     - looma: 只部署LoomaCRM
     - all: 部署所有服务
```

---

## 📋 服务端口清单

| 服务 | 端口 | 健康检查 | 日志位置 |
|------|------|---------|---------|
| Zervigo | 8207 | http://localhost:8207/health | /opt/services/zervigo/logs/ |
| AI Service 1 | 8100 | http://localhost:8100/health | /opt/services/ai-service-1/current/logs/ |
| AI Service 2 | 8110 | http://localhost:8110/health | /opt/services/ai-service-2/current/logs/ |
| LoomaCRM | 8700 | http://localhost:8700/health | /opt/services/looma-crm/current/logs/ |

---

## 🎉 优势

### **相比手动部署**
- ⏱️ 节省时间: 1-2小时 → 30-45分钟
- 🤖 零人工干预: 全自动执行
- 📊 完整日志: 每次部署都有记录
- 🔄 可重复: 流程标准化
- 🛡️ 更可靠: 自动备份和回滚

### **长期收益**
- 每月部署10-20次
- 每月节省10-30小时
- 减少人为错误
- 提升团队效率

---

## 📚 相关文档

- `GITHUB_SECRETS_SETUP_GUIDE.md` - GitHub Secrets详细配置指南
- `TENCENT_CLOUD_CICD_SOLUTION.md` - 完整CI/CD方案分析
- `TENCENT_CLOUD_DEPLOYMENT_CHECKLIST.md` - 部署条件检查清单
- `.github/workflows/deploy-tencent-cloud.yml` - CI/CD工作流配置

---

**🎯 现在就开始配置GitHub Secrets，让CI/CD为你自动部署服务！** 🚀

---
*阅读时间: 5分钟*  
*配置时间: 30分钟*  
*首次部署: 30-45分钟*  
*后续部署: 自动完成*
