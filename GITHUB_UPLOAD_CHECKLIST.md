# GitHub 上传文件清单

**创建时间**: 2025年10月7日  
**目的**: 为腾讯云 CI/CD 自动化部署准备必要文件  
**参考文档**: `THREE_ENVIRONMENT_ARCHITECTURE_REDEFINITION.md`

---

## 📋 必需上传的文件 (核心部署文件)

### 1️⃣ **CI/CD 工作流文件** (最关键)
```yaml
必需文件:
  ✅ .github/workflows/deploy-tencent-cloud.yml (已创建)
     - 用途: GitHub Actions 自动部署到腾讯云
     - 触发: push to main 或手动触发
     - 部署: Zervigo + AI服务1 + AI服务2 + LoomaCRM
     - 时间: 30-45分钟自动完成

可选文件:
  📌 .github/workflows/deploy-alibaba-cloud.yml (参考)
     - 阿里云部署工作流（可复用代码）
```

### 2️⃣ **Zervigo 统一认证服务** (端口 8207)
```yaml
核心文件:
  ✅ zervigo_future/backend/cmd/unified-auth/main.go
     - 统一认证服务主程序
  
  ✅ zervigo_future/backend/configs/config.yaml
     - Zervigo 配置文件
  
  ✅ zervigo_future/backend/go.mod
  ✅ zervigo_future/backend/go.sum
     - Go 依赖管理文件

依赖代码:
  ✅ zervigo_future/backend/internal/ (整个目录)
     - 内部业务逻辑
  
  ✅ zervigo_future/backend/pkg/ (整个目录)
     - 公共包和工具

预计大小: ~50-100MB
```

### 3️⃣ **AI 服务 1 - 智能推荐** (端口 8100)
```yaml
核心文件:
  ✅ zervigo_future/ai-services/ai-service/ai_service_with_zervigo.py
     - AI服务主程序（已集成Zervigo认证）
  
  ✅ zervigo_future/ai-services/ai-service/requirements.txt
     - Python依赖（transformers, torch等）

依赖代码:
  ✅ zervigo_future/ai-services/ai-service/*.py
     - 所有AI服务相关Python文件
     - ai_identity_data_model.py
     - ai_identity_vectorization.py
     - ai_identity_similarity.py
     - competency_assessment_engine.py
     - experience_quantification_engine.py
     - skill_standardization_engine.py

配置文件:
  ✅ zervigo_future/ai-services/ai-service/.env.example (如有)
     - 环境变量示例

预计大小: ~20-50MB (不含AI模型)
```

### 4️⃣ **AI 服务 2 - NLP & Q&A** (端口 8110)
```yaml
说明: AI服务2与AI服务1使用相同的代码库
部署时使用不同的环境变量和端口配置

环境变量差异:
  - SERVICE_PORT=8110 (vs 8100)
  - 其他配置相同
```

### 5️⃣ **LoomaCRM - 客户关系管理** (端口 8700)
```yaml
核心文件:
  ✅ looma_crm_future/looma_crm/app.py
     - LoomaCRM 主程序
  
  ✅ looma_crm_future/requirements.txt
     - Python依赖

依赖代码:
  ✅ looma_crm_future/looma_crm/ (整个目录)
     - LoomaCRM所有业务代码
     - models/
     - routes/
     - services/
     - utils/

配置文件:
  ✅ looma_crm_future/.env.example (如有)
     - 环境变量示例

预计大小: ~30-80MB
```

---

## 📚 推荐上传的文件 (文档和配置)

### 6️⃣ **架构文档**
```yaml
✅ @dao/THREE_ENVIRONMENT_ARCHITECTURE_REDEFINITION.md
   - 三环境架构定义和CI/CD方案

✅ TENCENT_CLOUD_CICD_SOLUTION.md
   - CI/CD完整方案分析

✅ TENCENT_CLOUD_DEPLOYMENT_CHECKLIST.md
   - 部署条件检查清单

✅ GITHUB_SECRETS_SETUP_GUIDE.md
   - GitHub Secrets配置指南

✅ CICD_QUICK_START_GUIDE.md
   - 5分钟快速开始指南
```

### 7️⃣ **数据库管理文档**
```yaml
✅ @alibaba_cloud_database_management/README.md
   - 阿里云数据库管理文档

✅ @alibaba_cloud_practices/README.md
   - 阿里云实践文档

✅ ALIBABA_CLOUD_CAPACITY_ANALYSIS.md
   - 阿里云资源承载能力分析

✅ TENCENT_CLOUD_CAPACITY_ANALYSIS.md
   - 腾讯云资源承载能力分析
```

### 8️⃣ **项目配置文件**
```yaml
✅ .gitignore (已创建)
   - Git忽略规则

✅ README.md (主项目说明)
   - 项目整体说明文档

可选:
  📌 requirements.txt (如有项目级依赖)
  📌 package.json (如有前端项目)
```

---

## ❌ 不需要上传的文件 (已被 .gitignore 排除)

### 🚫 **大文件和备份**
```yaml
❌ database-backups/ (数据库备份)
❌ docker-images/ (Docker镜像)
❌ logs/ (日志文件)
❌ *.tar.gz, *.tar, *.zip (压缩文件)
❌ *.db, *.sqlite, *.rdb (数据库文件)
```

### 🚫 **临时文件**
```yaml
❌ __pycache__/ (Python缓存)
❌ venv/, alibaba_cloud_test_env/ (虚拟环境)
❌ node_modules/ (Node.js依赖)
❌ .DS_Store (Mac系统文件)
❌ *.pyc, *.pyo, *.pyd (Python编译文件)
❌ *.log, *.pid (日志和进程ID)
❌ tmp/, temp/ (临时目录)
```

### 🚫 **敏感信息**
```yaml
❌ *.pem, *.key (SSH密钥)
❌ .env (环境变量实际值)
❌ *_password_*.txt (密码文件)
```

---

## 📊 文件大小估算

### **必需文件总大小**
```yaml
核心服务代码:
  - Zervigo后端: ~50-100MB
  - AI服务: ~20-50MB
  - LoomaCRM: ~30-80MB
  - CI/CD工作流: <1MB
  
总计: ~100-230MB (代码部分)
```

### **文档和配置**
```yaml
架构文档: ~5-10MB
数据库文档: ~5-10MB
配置文件: <5MB

总计: ~10-25MB (文档部分)
```

### **GitHub 仓库总大小估算**
```yaml
当前清理后: 562MB (Git历史)
新增必需文件: ~100-230MB
新增文档: ~10-25MB

预计总大小: ~670-820MB
✅ 在GitHub 1GB建议限制内
✅ 在GitHub 5GB强烈建议限制内
```

---

## 🎯 上传策略建议

### **方案 1: 全量上传 (推荐)**
```bash
# 优势: 一次性完成，简单直接
# 适用: 如果总大小 < 1GB

git add .
git commit -m "feat: 添加CI/CD自动化部署和应用服务代码"
git push origin main
```

### **方案 2: 分批上传**
```bash
# 优势: 可控，易于排查问题
# 适用: 如果担心文件太大

# 第一批: CI/CD工作流
git add .github/
git commit -m "feat: 添加腾讯云CI/CD工作流"
git push origin main

# 第二批: Zervigo服务
git add zervigo_future/backend/
git commit -m "feat: 添加Zervigo统一认证服务"
git push origin main

# 第三批: AI服务
git add zervigo_future/ai-services/
git commit -m "feat: 添加双AI服务代码"
git push origin main

# 第四批: LoomaCRM
git add looma_crm_future/
git commit -m "feat: 添加LoomaCRM客户关系管理系统"
git push origin main

# 第五批: 文档
git add @dao/ @alibaba_cloud_database_management/ *.md
git commit -m "docs: 添加架构和部署文档"
git push origin main
```

### **方案 3: 选择性上传 (精简)**
```bash
# 优势: 只上传CI/CD必需文件，最小化仓库大小
# 适用: 如果GitHub空间有限

# 只上传CI/CD和核心服务代码
git add .github/
git add zervigo_future/backend/
git add zervigo_future/ai-services/ai-service/
git add looma_crm_future/looma_crm/
git add looma_crm_future/requirements.txt
git add .gitignore
git add README.md

git commit -m "feat: CI/CD自动化部署和核心服务代码"
git push origin main
```

---

## ✅ 检查清单

在上传之前，请确认：

- [ ] **.gitignore 已创建并生效**
  ```bash
  git status
  # 确认不包含venv/, __pycache__/, *.log等
  ```

- [ ] **敏感信息已移除**
  ```bash
  grep -r "password" . --exclude-dir=.git
  grep -r "secret" . --exclude-dir=.git
  # 确认没有硬编码的密码
  ```

- [ ] **Git仓库大小检查**
  ```bash
  git count-objects -vH
  # 确认 < 1GB
  ```

- [ ] **大文件检查**
  ```bash
  find . -type f -size +50M | grep -v ".git"
  # 确认没有超大文件
  ```

- [ ] **GitHub Secrets 已准备**
  - [ ] TENCENT_CLOUD_USER
  - [ ] TENCENT_CLOUD_SSH_KEY
  - [ ] TENCENT_DB_PASSWORD
  - [ ] JWT_SECRET

---

## 🚀 下一步

1. **确认文件完整性**
   ```bash
   # 检查关键文件是否存在
   ls -lh .github/workflows/deploy-tencent-cloud.yml
   ls -lh zervigo_future/backend/cmd/unified-auth/main.go
   ls -lh zervigo_future/ai-services/ai-service/ai_service_with_zervigo.py
   ls -lh looma_crm_future/looma_crm/app.py
   ```

2. **选择上传方案**
   - 推荐: 方案1 (全量上传)
   - 如果有顾虑: 方案2 (分批上传)

3. **执行上传**
   ```bash
   git add .
   git commit -m "feat: CI/CD自动化部署和应用服务完整代码"
   git push origin main
   ```

4. **验证上传结果**
   - 访问 GitHub 仓库
   - 检查文件是否完整
   - 查看仓库大小

5. **配置 GitHub Secrets**
   - 按照 GITHUB_SECRETS_SETUP_GUIDE.md 配置

6. **测试 CI/CD**
   - 手动触发 workflow_dispatch
   - 观察部署过程

---

## 📞 需要帮助？

如果在上传过程中遇到问题：
- 检查 .gitignore 是否生效
- 检查文件大小是否超限
- 检查网络连接是否稳定
- 检查 Git 配置是否正确

---

**总结**: 
- ✅ 必需上传: CI/CD工作流 + 4个服务代码 + 核心文档
- ✅ 总大小: ~670-820MB (在GitHub限制内)
- ✅ 推荐方案: 全量上传 (方案1)
- ✅ 准备就绪: 可以开始上传到GitHub了！

