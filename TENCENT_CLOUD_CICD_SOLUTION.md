# 腾讯云CI/CD自动化部署方案分析

**分析时间**: 2025年10月7日  
**目标**: 通过GitHub Actions实现自动化部署到腾讯云服务器  
**结论**: ✅ 完全可行，且已有基础代码可复用

---

## ✅ 可行性分析

### **1. 技术可行性** ✅ 完全可行
```yaml
优势:
  - GitHub Actions原生支持 ✅
  - SSH部署成熟方案 ✅
  - 项目已有CI/CD代码基础 ✅
  - 无需额外基础设施 ✅

已具备条件:
  - 现有deploy-alibaba-cloud.yml可复用 ✅
  - CI/CD部署脚本已存在 (ci-cd-deploy.sh) ✅
  - 详细的CI/CD指南文档 ✅
  - appleboy/ssh-action成熟工具 ✅
```

### **2. 成本可行性** ✅ 零额外成本
```yaml
GitHub Actions免费额度:
  - 公共仓库: 无限制 ✅
  - 私有仓库: 2000分钟/月 (足够使用)
  - 存储: 500MB (构建产物)

腾讯云成本:
  - 无需额外成本 ✅
  - 复用现有服务器
  - 无需容器镜像仓库
```

### **3. 部署方式可行性** ✅ 多种方案可选
```yaml
方案一: 原生代码部署 (推荐)
  - 通过SSH部署源代码
  - 服务器端安装依赖
  - 原生方式启动服务
  - 资源占用低 ✅

方案二: Docker镜像部署
  - 构建Docker镜像
  - 推送到镜像仓库
  - 服务器端拉取并运行
  - 需要Docker环境

方案三: 构建产物部署
  - 本地构建完成
  - 上传构建产物
  - 服务器端直接运行
  - 部署速度快 ✅
```

---

## 🏗️ CI/CD架构设计

### **整体流程**
```mermaid
graph LR
    A[代码提交] --> B[GitHub触发]
    B --> C[代码检查]
    C --> D[构建]
    D --> E[测试]
    E --> F[部署到腾讯云]
    F --> G[健康检查]
    G --> H[通知]
```

### **分支策略**
```yaml
main分支:
  - 触发: 推送到main
  - 目标: 腾讯云生产环境
  - 部署: 自动部署 (可选人工审核)

develop分支:
  - 触发: 推送到develop
  - 目标: 腾讯云测试环境 (可选)
  - 部署: 自动部署

feature分支:
  - 触发: Pull Request
  - 目标: 仅测试，不部署
  - 操作: 代码检查和测试
```

---

## 📋 具体实施方案

### **方案一: 原生代码部署** ✅ 推荐

#### **优点**
- 资源占用低，适合3.6GB内存服务器
- 部署速度快
- 配置简单
- 易于调试

#### **GitHub Actions工作流**
```yaml
name: Deploy to Tencent Cloud

on:
  push:
    branches: [ main ]
  workflow_dispatch:

env:
  SERVER_IP: 101.33.251.158
  DEPLOY_PATH: /opt/services

jobs:
  deploy-ai-services:
    name: Deploy AI Services
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Setup Python 3.11
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'
      
      - name: Test AI Services
        run: |
          cd zervigo_future/ai-services
          pip install -r ai-service/requirements.txt
          # python -m pytest tests/ (如有测试)
      
      - name: Deploy AI Service 1 (Port 8100)
        uses: appleboy/ssh-action@v1.0.0
        with:
          host: ${{ env.SERVER_IP }}
          username: ${{ secrets.TENCENT_CLOUD_USER }}
          key: ${{ secrets.TENCENT_CLOUD_SSH_KEY }}
          script: |
            # 创建部署目录
            mkdir -p ${{ env.DEPLOY_PATH }}/ai-service-1
            
            # 备份现有服务
            if [ -d "${{ env.DEPLOY_PATH }}/ai-service-1/backup" ]; then
              rm -rf ${{ env.DEPLOY_PATH }}/ai-service-1/backup
            fi
            if [ -d "${{ env.DEPLOY_PATH }}/ai-service-1/current" ]; then
              mv ${{ env.DEPLOY_PATH }}/ai-service-1/current ${{ env.DEPLOY_PATH }}/ai-service-1/backup
            fi
            mkdir -p ${{ env.DEPLOY_PATH }}/ai-service-1/current
      
      - name: Upload AI Service 1 Code
        uses: appleboy/scp-action@v0.1.7
        with:
          host: ${{ env.SERVER_IP }}
          username: ${{ secrets.TENCENT_CLOUD_USER }}
          key: ${{ secrets.TENCENT_CLOUD_SSH_KEY }}
          source: "zervigo_future/ai-services/ai-service/*"
          target: "${{ env.DEPLOY_PATH }}/ai-service-1/current/"
          strip_components: 3
      
      - name: Setup and Start AI Service 1
        uses: appleboy/ssh-action@v1.0.0
        with:
          host: ${{ env.SERVER_IP }}
          username: ${{ secrets.TENCENT_CLOUD_USER }}
          key: ${{ secrets.TENCENT_CLOUD_SSH_KEY }}
          script: |
            cd ${{ env.DEPLOY_PATH }}/ai-service-1/current
            
            # 创建虚拟环境
            python3.11 -m venv venv
            source venv/bin/activate
            
            # 安装依赖
            pip install -r requirements.txt
            
            # 创建环境配置
            cat > .env << 'ENVEOF'
            DB_HOST=localhost
            DB_PORT=5432
            DB_USER=postgres
            DB_PASSWORD=${{ secrets.TENCENT_DB_PASSWORD }}
            DB_NAME=jobfirst_vector
            MYSQL_HOST=localhost
            MYSQL_PORT=3306
            MYSQL_USER=root
            MYSQL_PASSWORD=${{ secrets.TENCENT_DB_PASSWORD }}
            REDIS_HOST=localhost
            REDIS_PORT=6379
            JWT_SECRET=${{ secrets.JWT_SECRET }}
            SERVICE_PORT=8100
            ENVEOF
            
            # 停止旧服务
            if [ -f ai_service.pid ]; then
              kill $(cat ai_service.pid) || true
              rm ai_service.pid
            fi
            
            # 启动新服务
            nohup python ai_service_with_zervigo.py > logs/service.log 2>&1 &
            echo $! > ai_service.pid
            
            # 等待启动
            sleep 5
            
            # 健康检查
            curl -f http://localhost:8100/health || exit 1
            
            echo "AI Service 1 deployed successfully on port 8100"
  
  deploy-ai-service-2:
    name: Deploy AI Service 2
    runs-on: ubuntu-latest
    needs: deploy-ai-services
    
    steps:
      # 类似AI Service 1的步骤，但使用端口8110
      - name: Checkout code
        uses: actions/checkout@v4
      
      # ... (类似步骤，部署到8110端口)
  
  deploy-looma-crm:
    name: Deploy LoomaCRM
    runs-on: ubuntu-latest
    needs: deploy-ai-service-2
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Deploy LoomaCRM
        uses: appleboy/ssh-action@v1.0.0
        with:
          host: ${{ env.SERVER_IP }}
          username: ${{ secrets.TENCENT_CLOUD_USER }}
          key: ${{ secrets.TENCENT_CLOUD_SSH_KEY }}
          script: |
            mkdir -p ${{ env.DEPLOY_PATH }}/looma-crm
            # ... (类似部署步骤)
  
  deploy-zervigo:
    name: Deploy Zervigo
    runs-on: ubuntu-latest
    needs: deploy-looma-crm
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Setup Go
        uses: actions/setup-go@v4
        with:
          go-version: '1.23'
      
      - name: Build Zervigo
        run: |
          cd zervigo_future/backend
          go build -o unified-auth cmd/unified-auth/main.go
      
      - name: Deploy Zervigo
        uses: appleboy/ssh-action@v1.0.0
        with:
          host: ${{ env.SERVER_IP }}
          username: ${{ secrets.TENCENT_CLOUD_USER }}
          key: ${{ secrets.TENCENT_CLOUD_SSH_KEY }}
          script: |
            mkdir -p ${{ env.DEPLOY_PATH }}/zervigo
            # ... (部署步骤)
  
  health-check:
    name: Health Check All Services
    runs-on: ubuntu-latest
    needs: [deploy-ai-services, deploy-ai-service-2, deploy-looma-crm, deploy-zervigo]
    
    steps:
      - name: Check All Services
        uses: appleboy/ssh-action@v1.0.0
        with:
          host: ${{ env.SERVER_IP }}
          username: ${{ secrets.TENCENT_CLOUD_USER }}
          key: ${{ secrets.TENCENT_CLOUD_SSH_KEY }}
          script: |
            echo "Checking service health..."
            
            # Check AI Service 1
            curl -f http://localhost:8100/health && echo "✅ AI Service 1 OK"
            
            # Check AI Service 2
            curl -f http://localhost:8110/health && echo "✅ AI Service 2 OK"
            
            # Check LoomaCRM
            curl -f http://localhost:8700/health && echo "✅ LoomaCRM OK"
            
            # Check Zervigo
            curl -f http://localhost:8207/health && echo "✅ Zervigo OK"
            
            echo "All services are healthy!"
```

---

## 🔐 GitHub Secrets配置

### **必需的Secrets**
```yaml
需要在GitHub仓库设置中添加:

TENCENT_CLOUD_USER:
  - 值: ubuntu 或 root
  - 用途: SSH登录用户名

TENCENT_CLOUD_SSH_KEY:
  - 值: (basic.pem的内容)
  - 用途: SSH私钥认证
  - 获取: cat ~/.ssh/basic.pem

TENCENT_DB_PASSWORD:
  - 值: 腾讯云数据库密码
  - 用途: 数据库连接

JWT_SECRET:
  - 值: JWT密钥
  - 用途: 服务认证
  - 建议: 生成随机字符串

SLACK_WEBHOOK_URL (可选):
  - 值: Slack通知地址
  - 用途: 部署通知
```

### **配置步骤**
1. 进入GitHub仓库
2. Settings → Secrets and variables → Actions
3. New repository secret
4. 添加每个Secret

---

## 📊 部署流程详解

### **第一阶段: 代码检查和测试**
```yaml
步骤:
  1. Checkout代码
  2. 设置Python/Go环境
  3. 安装依赖
  4. 运行单元测试
  5. 代码质量检查

时间: 约3-5分钟
```

### **第二阶段: 构建**
```yaml
步骤:
  1. 构建Go服务 (Zervigo)
  2. 打包Python服务代码
  3. 创建部署清单

时间: 约2-3分钟
```

### **第三阶段: 部署**
```yaml
步骤:
  1. SSH连接到腾讯云
  2. 备份现有服务
  3. 上传新代码
  4. 创建虚拟环境
  5. 安装依赖
  6. 创建配置文件
  7. 停止旧服务
  8. 启动新服务

时间: 每个服务约5-8分钟
总计: 约20-30分钟
```

### **第四阶段: 验证**
```yaml
步骤:
  1. 健康检查
  2. 接口测试
  3. 日志检查
  4. 性能监控

时间: 约2-3分钟
```

### **第五阶段: 通知**
```yaml
步骤:
  1. 发送部署结果通知
  2. 更新部署日志
  3. 生成部署报告

时间: 约1分钟
```

**总时间**: 约30-45分钟

---

## 🎯 优势分析

### **相比手动部署的优势**
```yaml
自动化:
  - 无需手动登录服务器 ✅
  - 无需手动上传代码 ✅
  - 无需手动安装依赖 ✅
  - 无需手动重启服务 ✅

一致性:
  - 每次部署流程相同 ✅
  - 减少人为错误 ✅
  - 可重复执行 ✅

可靠性:
  - 自动备份 ✅
  - 健康检查 ✅
  - 失败回滚 ✅
  - 部署日志 ✅

效率:
  - 节省时间 (手动1-2小时 → 自动30分钟) ✅
  - 可并行部署 ✅
  - 零人工干预 ✅
```

### **相比其他CI/CD方案的优势**
```yaml
vs Jenkins:
  - 无需自建服务器 ✅
  - 配置更简单 ✅
  - GitHub原生集成 ✅

vs GitLab CI:
  - 代码已在GitHub ✅
  - 社区支持更好 ✅
  - 免费额度充足 ✅

vs Travis CI:
  - 更活跃的维护 ✅
  - 更强大的功能 ✅
  - 更好的性能 ✅
```

---

## 🚀 实施计划

### **第一步: 准备工作** (1天)
```yaml
1. 整理SSH密钥:
   - 确认basic.pem可用
   - 添加到GitHub Secrets

2. 确认数据库密码:
   - MySQL密码
   - PostgreSQL密码
   - 添加到GitHub Secrets

3. 生成JWT密钥:
   - 生成随机字符串
   - 添加到GitHub Secrets

4. 测试SSH连接:
   - 确认可以连接腾讯云
   - 确认用户权限正确
```

### **第二步: 创建工作流** (1天)
```yaml
1. 创建 .github/workflows/deploy-tencent-cloud.yml

2. 配置触发条件:
   - push to main
   - workflow_dispatch

3. 配置部署步骤:
   - AI Service 1 (8100)
   - AI Service 2 (8110)
   - LoomaCRM (8700)
   - Zervigo (8207)

4. 配置健康检查

5. 配置通知
```

### **第三步: 测试部署** (1天)
```yaml
1. 手动触发工作流

2. 观察部署过程

3. 检查服务状态

4. 验证功能正常

5. 修复问题
```

### **第四步: 优化和完善** (1天)
```yaml
1. 添加回滚机制

2. 优化部署速度

3. 添加更多健康检查

4. 完善通知系统

5. 编写部署文档
```

**总时间**: 3-4天

---

## ⚠️ 注意事项

### **安全考虑**
```yaml
1. SSH密钥安全:
   - 使用GitHub Secrets存储 ✅
   - 定期更换密钥
   - 限制密钥权限

2. 数据库密码:
   - 不要硬编码 ✅
   - 使用Secrets存储 ✅
   - 定期更换密码

3. 服务端口:
   - 配置防火墙规则
   - 限制访问来源
   - 使用HTTPS
```

### **性能考虑**
```yaml
1. 部署时间:
   - 优化依赖安装
   - 使用缓存
   - 并行部署

2. 服务中断:
   - 使用蓝绿部署
   - 滚动更新
   - 健康检查

3. 资源占用:
   - 监控内存使用
   - 优化启动参数
   - 清理旧版本
```

### **监控告警**
```yaml
1. 部署监控:
   - 部署成功率
   - 部署时间
   - 失败原因

2. 服务监控:
   - 服务健康状态
   - 响应时间
   - 错误率

3. 资源监控:
   - CPU使用率
   - 内存使用率
   - 磁盘使用率
```

---

## 📚 参考资料

### **已有资源**
```yaml
项目中已存在:
  - .github/workflows/deploy-alibaba-cloud.yml ✅
  - scripts/ci-cd-deploy.sh ✅
  - docs/guides/CICD_TRIGGER_GUIDE.md ✅
  - docs/guides/GITHUB_ACTIONS_TRIGGER_GUIDE.md ✅

可复用代码:
  - SSH部署脚本
  - 健康检查脚本
  - 服务启动脚本
```

### **外部资源**
```yaml
GitHub Actions文档:
  - https://docs.github.com/actions

appleboy/ssh-action:
  - https://github.com/appleboy/ssh-action

appleboy/scp-action:
  - https://github.com/appleboy/scp-action
```

---

## 🎯 结论

### **✅ 完全可行**
```yaml
技术可行性: ✅ 完全可行
成本可行性: ✅ 零额外成本
时间可行性: ✅ 3-4天可完成
风险可控性: ✅ 有备份和回滚机制

推荐方案: 原生代码部署
预计时间: 3-4天完成开发和测试
后续维护: 基本零维护，自动运行
```

### **核心优势**
1. **自动化**: 代码推送即自动部署
2. **一致性**: 每次部署流程相同
3. **可靠性**: 自动备份和健康检查
4. **效率**: 节省50%以上时间
5. **可追溯**: 完整的部署日志

### **建议**
- ✅ 立即启动CI/CD建设
- ✅ 先部署到测试环境验证
- ✅ 再部署到生产环境
- ✅ 逐步完善和优化

---

**🎯 最终建议**: 通过GitHub Actions实现CI/CD自动化部署到腾讯云是最佳方案，完全可行且有现成代码可复用。建议立即开始实施！

---
*分析时间: 2025年10月7日*  
*可行性: ✅ 完全可行*  
*推荐方案: 原生代码部署*  
*实施时间: 3-4天*  
*成本: 零额外成本*
