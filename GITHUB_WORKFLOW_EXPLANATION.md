# GitHub 工作流文件说明

**创建时间**: 2025年10月7日  
**问题**: `deploy-tencent-cloud.yml` 会覆盖腾讯云服务器上的文件吗？  
**答案**: ❌ **不会！**

---

## 🎯 核心概念

### **GitHub 工作流文件 vs 腾讯云服务器文件**

```yaml
两个完全不同的位置:

1. GitHub 仓库 (代码托管平台):
   📁 .github/workflows/deploy-tencent-cloud.yml
   🌐 存储在 GitHub.com
   🤖 由 GitHub Actions 执行器运行
   ✅ 这是部署"脚本"

2. 腾讯云服务器 (目标服务器):
   📁 /opt/services/zervigo/
   📁 /opt/services/ai-service-1/
   📁 /opt/services/ai-service-2/
   📁 /opt/services/looma-crm/
   🖥️ 运行在 101.33.251.158
   ✅ 这是部署"目标"
```

---

## 📊 完整执行流程图

```
┌─────────────────────────────────────────────────────────────┐
│ 第一步: 本地开发                                              │
│ /Users/szjason72/genzltd/                                   │
│ ├── .github/workflows/deploy-tencent-cloud.yml (工作流)      │
│ ├── zervigo_future/backend/ (Zervigo源码)                   │
│ ├── zervigo_future/ai-services/ (AI服务源码)                 │
│ └── looma_crm_future/ (LoomaCRM源码)                        │
└─────────────────────────────────────────────────────────────┘
                         │
                         │ git push origin main
                         ↓
┌─────────────────────────────────────────────────────────────┐
│ 第二步: GitHub 仓库                                           │
│ https://github.com/你的用户名/genzltd                         │
│ ├── .github/workflows/deploy-tencent-cloud.yml              │
│ ├── zervigo_future/                                         │
│ ├── looma_crm_future/                                       │
│ └── 其他文件...                                              │
└─────────────────────────────────────────────────────────────┘
                         │
                         │ 触发 GitHub Actions
                         ↓
┌─────────────────────────────────────────────────────────────┐
│ 第三步: GitHub Actions 执行服务器                             │
│ (GitHub 提供的免费 CI/CD 服务器)                              │
│                                                              │
│ 执行任务:                                                     │
│ 1. ✅ 读取 deploy-tencent-cloud.yml                         │
│ 2. ✅ 检出代码 (checkout)                                    │
│ 3. ✅ 构建服务 (build Go, Python)                            │
│ 4. ✅ 运行测试 (test)                                        │
│ 5. ✅ 通过SSH连接腾讯云                                       │
│ 6. ✅ 上传代码到腾讯云                                        │
│ 7. ✅ 在腾讯云上执行部署命令                                   │
└─────────────────────────────────────────────────────────────┘
                         │
                         │ SSH连接 (使用 TENCENT_CLOUD_SSH_KEY)
                         ↓
┌─────────────────────────────────────────────────────────────┐
│ 第四步: 腾讯云服务器 (101.33.251.158)                         │
│                                                              │
│ /opt/services/                                              │
│ ├── zervigo/                                                │
│ │   ├── unified-auth (二进制文件)                            │
│ │   ├── configs/config.yaml                                │
│ │   ├── logs/zervigo.log                                   │
│ │   └── zervigo.pid                                        │
│ │                                                            │
│ ├── ai-service-1/                                           │
│ │   ├── current/                                           │
│ │   │   ├── ai_service_with_zervigo.py                    │
│ │   │   ├── requirements.txt                               │
│ │   │   └── venv/ (虚拟环境)                               │
│ │   ├── logs/service.log                                   │
│ │   └── ai_service_1.pid                                   │
│ │                                                            │
│ ├── ai-service-2/                                           │
│ │   └── (同AI服务1结构)                                     │
│ │                                                            │
│ └── looma-crm/                                              │
│     ├── current/                                            │
│     │   ├── looma_crm/app.py                               │
│     │   ├── requirements.txt                                │
│     │   └── venv/ (虚拟环境)                                │
│     ├── logs/looma_crm.log                                  │
│     └── looma_crm.pid                                       │
│                                                              │
│ ⚠️ 注意: 这里没有 deploy-tencent-cloud.yml 文件！            │
└─────────────────────────────────────────────────────────────┘
```

---

## ✅ 关键点说明

### **1. 工作流文件永远不会上传到腾讯云**

```yaml
原因:
  - GitHub工作流文件是"部署脚本"
  - 它在 GitHub Actions 服务器上运行
  - 它不是"应用服务代码"
  - 它只负责指挥部署过程

类比:
  - 工作流文件 = 指挥官 (在GitHub)
  - 应用服务代码 = 士兵 (部署到腾讯云)
  - 指挥官不会跟着士兵去前线
```

### **2. 部署的内容**

```yaml
会部署到腾讯云的:
  ✅ zervigo_future/backend/ (Go编译后的二进制文件)
  ✅ zervigo_future/ai-services/ai-service/*.py (Python源码)
  ✅ looma_crm_future/looma_crm/ (Python源码)
  ✅ requirements.txt, configs/ (配置和依赖)

不会部署到腾讯云的:
  ❌ .github/ (GitHub配置目录)
  ❌ @dao/ (文档目录)
  ❌ @alibaba_cloud_database_management/ (文档)
  ❌ *.md (Markdown文档)
  ❌ .gitignore, .git/ (Git配置)
```

### **3. 工作流文件的作用**

```yaml
deploy-tencent-cloud.yml 文件做什么:

第一阶段 (在GitHub Actions服务器):
  1. 检出代码
  2. 安装依赖 (Go, Python)
  3. 编译Go代码
  4. 运行测试
  5. 准备部署包

第二阶段 (通过SSH操作腾讯云):
  6. 连接到腾讯云 (SSH)
  7. 创建目录 (/opt/services/xxx)
  8. 上传应用代码
  9. 创建虚拟环境
  10. 安装Python依赖
  11. 启动服务
  12. 健康检查
  13. 生成部署报告
```

---

## 🔧 当前配置检查

### **工作流文件配置**

```yaml
✅ 服务器IP: 101.33.251.158
✅ 部署路径: /opt/services
✅ Python版本: 3.11
✅ Go版本: 1.23

✅ 部署的服务:
  - Zervigo (端口8207)
  - AI服务1 (端口8100)
  - AI服务2 (端口8110)
  - LoomaCRM (端口8700)

✅ GitHub Secrets需要配置:
  - TENCENT_CLOUD_USER (ubuntu 或 root)
  - TENCENT_CLOUD_SSH_KEY (basic.pem内容)
  - TENCENT_DB_PASSWORD (数据库密码)
  - JWT_SECRET (JWT密钥)
```

---

## 🚀 修改和上传工作流

### **可以安全修改**

```bash
# 修改工作流文件
vim .github/workflows/deploy-tencent-cloud.yml

# 修改后上传到GitHub
git add .github/workflows/deploy-tencent-cloud.yml
git commit -m "feat: 更新CI/CD工作流配置"
git push origin main

# 结果:
# ✅ GitHub仓库中的工作流文件会更新
# ✅ 下次推送代码时使用新的工作流
# ❌ 腾讯云服务器不受影响 (没有这个文件)
```

### **修改不会影响腾讯云**

```yaml
修改工作流的影响范围:

影响:
  ✅ GitHub仓库中的工作流文件更新
  ✅ GitHub Actions的执行逻辑变化
  ✅ 下次部署时使用新的逻辑

不影响:
  ❌ 腾讯云服务器上的现有文件
  ❌ 正在运行的服务
  ❌ 已部署的应用代码

只有执行部署时才会:
  ✅ 根据新的工作流逻辑
  ✅ 重新部署应用代码到腾讯云
```

---

## 📋 常见问题

### **Q1: 如果我修改了工作流文件，已经部署的服务会受影响吗？**
```
A: ❌ 不会！
   - 工作流文件只影响"下一次部署"
   - 已部署的服务继续运行
   - 不会自动重新部署
```

### **Q2: 工作流文件会占用腾讯云的磁盘空间吗？**
```
A: ❌ 不会！
   - 工作流文件只存在于GitHub
   - 不会上传到腾讯云
   - 腾讯云只有应用服务代码
```

### **Q3: 如何测试工作流修改？**
```
A: 有两种方式
   1. 推送代码到main分支 → 自动触发
   2. 在GitHub Actions页面 → 手动触发 (workflow_dispatch)
```

### **Q4: 如果工作流执行失败会怎样？**
```
A: 
   ✅ GitHub Actions会显示失败状态
   ✅ 腾讯云上的服务保持原状态
   ✅ 可以在Actions页面查看日志
   ✅ 修复后重新触发即可
```

---

## 🎯 总结

```yaml
核心要点:

1. GitHub工作流文件的位置:
   📍 .github/workflows/deploy-tencent-cloud.yml
   🏠 存储在: GitHub仓库
   🤖 执行在: GitHub Actions服务器
   🎯 作用: 部署脚本/指挥官

2. 腾讯云服务器的内容:
   📍 /opt/services/xxx/
   🏠 运行在: 腾讯云服务器 (101.33.251.158)
   🎯 作用: 应用服务代码/士兵

3. 关系:
   ✅ 工作流文件 → 指挥部署过程
   ✅ 应用代码 → 被部署到腾讯云
   ✅ 两者分离 → 互不影响

4. 结论:
   ✅ 可以安全修改工作流文件
   ✅ 修改后上传到GitHub
   ✅ 不会影响腾讯云现有文件
   ✅ 下次部署时使用新配置
```

---

**您可以放心修改和上传 `deploy-tencent-cloud.yml` 文件！** ✅

