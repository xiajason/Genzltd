# CI/CD触发功能快速使用指南

## 🚀 快速开始

### 1. 构建zervigo工具

```bash
# 进入zervigo目录
cd basic/backend/pkg/jobfirst-core/superadmin

# 构建zervigo工具
./build.sh
```

### 2. 使用zervigo触发CI/CD部署

```bash
# 进入zervigo目录
cd basic/backend/pkg/jobfirst-core/superadmin

# 触发生产环境部署
./zervigo cicd deploy production

# 触发测试环境部署
./zervigo cicd deploy staging

# 触发开发环境部署
./zervigo cicd deploy development
```

### 3. 查看CI/CD状态

```bash
# 查看CI/CD系统状态
./zervigo cicd status

# 查看Webhook配置
./zervigo cicd webhook

# 查看部署日志
./zervigo cicd logs
```

### 4. 测试CI/CD功能

```bash
# 运行完整测试
./basic/scripts/test-cicd-trigger.sh test staging

# 测试特定功能
./basic/scripts/test-cicd-trigger.sh deploy production
./basic/scripts/test-cicd-trigger.sh webhook
```

## 📋 常用命令

### zervigo CI/CD命令

```bash
# 基础命令
./zervigo cicd status                    # 查看CI/CD系统状态
./zervigo cicd deploy [环境]             # 触发部署
./zervigo cicd webhook                   # 查看Webhook配置
./zervigo cicd logs                      # 查看部署日志

# 环境参数
production     # 生产环境
staging        # 测试环境
development    # 开发环境
```

### 测试脚本命令

```bash
# 测试命令
./basic/scripts/test-cicd-trigger.sh test [环境]        # 完整测试
./basic/scripts/test-cicd-trigger.sh status            # 状态测试
./basic/scripts/test-cicd-trigger.sh deploy [环境]     # 部署测试
./basic/scripts/test-cicd-trigger.sh webhook           # Webhook测试
./basic/scripts/test-cicd-trigger.sh pipeline [环境]   # 流水线测试
```

## 🔧 配置说明

### 服务器配置

- **服务器IP**: 101.33.251.158
- **用户名**: ubuntu
- **SSH密钥**: ~/.ssh/basic.pem
- **项目目录**: /opt/jobfirst

### Webhook配置

- **Webhook URL**: http://101.33.251.158:8088/webhook
- **Webhook端口**: 8088
- **支持事件**: push, tag

### 分支策略

- **main/master** → production (生产环境)
- **develop** → staging (测试环境)
- **feature/*** → development (开发环境)

## 🎯 使用场景

### 场景1: 手动部署

```bash
# 部署到生产环境
./zervigo cicd deploy production
```

### 场景2: 自动部署

```bash
# 推送到main分支自动触发生产环境部署
git push origin main
```

### 场景3: 测试部署

```bash
# 推送到develop分支自动触发测试环境部署
git push origin develop
```

## 🚨 故障排除

### 常见问题

1. **zervigo命令不存在**
   ```bash
   # 构建zervigo工具
   cd basic/backend/pkg/jobfirst-core/superadmin
   ./build.sh
   ```

2. **SSH连接失败**
   ```bash
   # 检查SSH连接
   ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158 "echo 'SSH连接正常'"
   ```

3. **部署失败**
   ```bash
   # 查看部署日志
   ./zervigo cicd logs
   
   # 检查服务器状态
   ./zervigo status
   ```

### 紧急恢复

```bash
# 1. 检查系统状态
./zervigo status

# 2. 检查CI/CD状态
./zervigo cicd status

# 3. 查看错误日志
./zervigo cicd logs

# 4. 重新触发部署
./zervigo cicd deploy production
```

## 📞 支持信息

### 相关文档

- [CI/CD触发功能实现指南](./CICD_TRIGGER_IMPLEMENTATION_GUIDE.md)
- [超级管理员控制指南](./docs/SUPER_ADMIN_CONTROL_GUIDE.md)
- [腾讯云部署指南](./TENCENT_CLOUD_DEPLOYMENT_GUIDE.md)

### 联系方式

- **技术支持**: admin@jobfirst.com
- **紧急联系**: 24/7 技术支持热线

---

**文档版本**: v1.0.0  
**最后更新**: 2025年1月9日  
**维护人员**: AI Assistant
