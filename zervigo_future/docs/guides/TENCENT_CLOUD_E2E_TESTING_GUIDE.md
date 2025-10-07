# 腾讯云E2E测试框架使用指南

## 概述
本指南介绍如何使用腾讯云E2E测试框架对JobFirst系统进行端到端测试。

## 测试框架组成

### 1. 配置文件
- `configs/tencent-e2e-config.yaml` - 腾讯云E2E测试专用配置

### 2. 测试脚本
- `scripts/setup-tencent-e2e-database.sh` - 数据库初始化脚本
- `scripts/run-tencent-e2e-tests.sh` - 完整E2E测试脚本
- `scripts/quick-tencent-e2e-test.sh` - 快速E2E测试脚本

### 3. 测试报告
- `logs/tencent-e2e-test-report.md` - 完整测试报告
- `logs/quick-tencent-e2e-test-report.md` - 快速测试报告

## 使用方法

### 1. 首次使用 - 完整测试

#### 步骤1: 初始化测试数据库
```bash
cd basic/backend
./scripts/setup-tencent-e2e-database.sh
```

#### 步骤2: 执行完整E2E测试
```bash
./scripts/run-tencent-e2e-tests.sh
```

#### 步骤3: 查看测试报告
```bash
cat logs/tencent-e2e-test-report.md
```

### 2. 日常使用 - 快速测试

#### 执行快速E2E测试
```bash
cd basic/backend
./scripts/quick-tencent-e2e-test.sh
```

#### 查看快速测试报告
```bash
cat logs/quick-tencent-e2e-test-report.md
```

## 测试覆盖范围

### 完整E2E测试 (19项)
- **基础设施测试** (4项): SSH连接、数据库连接、数据完整性、服务状态
- **API功能测试** (6项): 健康检查、用户注册、用户登录、职位列表、企业列表
- **AI服务测试** (2项): AI聊天、简历分析
- **前端集成测试** (2项): 页面访问、Nginx代理
- **数据库功能测试** (3项): 职位查询、企业查询、用户查询
- **Nginx代理测试** (2项): API代理、AI代理

### 快速E2E测试 (7项)
- **健康检查** (4项): 前端访问、API健康、AI健康、SSH连接
- **API测试** (2项): 用户登录、职位列表
- **AI测试** (1项): AI聊天

## 测试环境

### 服务器信息
- **服务器地址**: 101.33.251.158
- **服务器用户**: ubuntu
- **SSH密钥**: ~/.ssh/basic.pem

### 测试数据库
- **数据库名称**: jobfirst_tencent_e2e_test
- **Redis数据库**: db=2
- **测试端口**: 8082

### 服务地址
- **前端地址**: http://101.33.251.158/
- **API地址**: http://101.33.251.158/api/
- **AI地址**: http://101.33.251.158/ai/

## 测试数据

### 测试用户
- **用户名**: tencent_test_user1
- **密码**: password
- **角色**: user

### 测试企业
- 腾讯科技有限公司
- 阿里巴巴集团
- 字节跳动

### 测试职位
- 腾讯前端开发工程师
- 阿里巴巴产品经理
- 字节跳动后端开发工程师

## 常见问题

### 1. SSH连接失败
```bash
# 检查SSH密钥权限
chmod 600 ~/.ssh/basic.pem

# 测试SSH连接
ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158
```

### 2. MySQL权限问题
```bash
# 检查MySQL服务状态
ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158 "sudo systemctl status mysql"

# 重启MySQL服务
ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158 "sudo systemctl restart mysql"
```

### 3. 服务不可访问
```bash
# 检查服务状态
ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158 "sudo systemctl status nginx"
ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158 "sudo systemctl status redis"

# 重启服务
ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158 "sudo systemctl restart nginx"
ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158 "sudo systemctl restart redis"
```

### 4. 测试数据库问题
```bash
# 重新初始化测试数据库
./scripts/setup-tencent-e2e-database.sh
```

## 测试最佳实践

### 1. 测试频率
- **完整E2E测试**: 每周执行一次
- **快速E2E测试**: 每日执行一次
- **部署后测试**: 每次部署后立即执行

### 2. 测试时机
- **开发完成**: 功能开发完成后
- **部署前**: 生产部署前
- **部署后**: 生产部署后
- **定期检查**: 定期系统健康检查

### 3. 问题处理
- **测试失败**: 立即检查相关服务状态
- **网络问题**: 检查网络连接和防火墙设置
- **服务问题**: 检查服务日志和配置

## 扩展测试

### 1. 添加新的测试用例
在相应的测试脚本中添加新的测试函数：

```bash
# 在 run-tencent-e2e-tests.sh 中添加
test_new_feature() {
    increment_test
    log_info "测试新功能..."
    
    if curl -s --connect-timeout 10 "$API_BASE_URL/api/v1/new-feature" > /dev/null 2>&1; then
        test_passed "新功能测试通过"
    else
        test_failed "新功能测试失败"
    fi
}
```

### 2. 自定义测试配置
修改 `tencent-e2e-config.yaml` 文件：

```yaml
# 添加新的配置项
new_feature:
  enabled: true
  test_url: "http://101.33.251.158/api/v1/new-feature"
  timeout: 30s
```

### 3. 集成到CI/CD
将测试脚本集成到CI/CD流水线：

```yaml
# GitHub Actions 示例
- name: Run Tencent Cloud E2E Tests
  run: |
    cd basic/backend
    ./scripts/quick-tencent-e2e-test.sh
```

## 监控和告警

### 1. 测试结果监控
- 监控测试成功率
- 跟踪测试执行时间
- 记录测试失败原因

### 2. 告警设置
- 测试失败时发送告警
- 服务不可用时通知
- 性能下降时提醒

### 3. 日志管理
- 定期清理测试日志
- 保存重要的测试报告
- 分析测试趋势

## 总结

腾讯云E2E测试框架提供了完整的端到端测试解决方案：

- **✅ 全面覆盖**: 从基础设施到应用功能的完整测试
- **✅ 自动化**: 一键执行，自动生成报告
- **✅ 环境隔离**: 独立的测试环境，不影响生产
- **✅ 快速反馈**: 快速测试脚本，日常使用便捷
- **✅ 易于扩展**: 模块化设计，支持自定义测试

通过使用这个测试框架，可以确保JobFirst系统在腾讯云环境中的稳定性和可靠性。

---

**文档版本**: v1.0.0  
**创建时间**: 2025年1月9日  
**适用环境**: 腾讯云轻量应用服务器  
**维护人员**: AI Assistant
