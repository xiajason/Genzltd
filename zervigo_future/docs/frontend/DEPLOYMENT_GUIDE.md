# 生产环境构建指南

## 📋 概述

本指南详细说明如何构建生产环境版本，确保移除所有模拟数据和测试功能。

## 🚀 快速开始

### 微信小程序生产构建
```bash
npm run build:weapp:prod
```

### H5生产构建
```bash
npm run build:h5:prod
```

### 验证生产构建
```bash
npm run verify:production
```

## 🔧 构建流程

### 1. 自动清理模拟数据
构建脚本会自动执行以下清理步骤：

- ✅ 移除所有服务文件中的模拟数据逻辑
- ✅ 清理 `shouldUseMockData()` 相关代码
- ✅ 移除模拟数据函数和条件判断
- ✅ 清理多余的导入语句

### 2. 环境配置验证
- ✅ 验证生产环境配置正确
- ✅ 确认模拟数据已禁用
- ✅ 检查功能开关配置

### 3. 服务文件检查
检查以下服务文件：
- `src/services/aiService.ts`
- `src/services/resumeService.ts`
- `src/services/resumeServiceV3.ts`
- `src/services/jobService.ts`
- `src/services/fileService.ts`
- `src/services/pointsService.ts`

### 4. 测试页面排除
- ✅ 自动排除测试页面 (`pages/test-mock/index`)
- ✅ 验证应用配置正确

### 5. 构建产物验证
- ✅ 检查构建产物中无测试页面
- ✅ 验证生产环境配置生效

## 📁 文件结构

```
scripts/
├── build-production.js      # 生产环境构建脚本
├── clean-mock-data.js       # 模拟数据清理脚本
└── verify-production.js     # 生产环境验证脚本

src/config/
├── api.ts                   # API配置管理
└── environment.ts           # 环境配置管理
```

## ⚙️ 环境配置

### 生产环境配置
```typescript
production: {
  useMockData: false,        // 禁用模拟数据
  enableDebugLogs: false,    // 禁用调试日志
  enableTestPages: false,    // 禁用测试页面
  enableAnalytics: true,     // 启用分析功能
  enableErrorReporting: true // 启用错误报告
}
```

### 开发环境配置
```typescript
development: {
  useMockData: true,         // 启用模拟数据
  enableDebugLogs: true,     // 启用调试日志
  enableTestPages: true,     // 启用测试页面
  enableAnalytics: false,    // 禁用分析功能
  enableErrorReporting: false // 禁用错误报告
}
```

## 🔍 验证检查

### 自动验证项目
- ✅ 模拟数据关键词检查
- ✅ 环境配置验证
- ✅ 测试页面排除验证
- ✅ 构建产物检查

### 手动验证项目
- ✅ 功能测试
- ✅ 性能测试
- ✅ 安全检查
- ✅ 兼容性测试

## 🚨 注意事项

### 构建前检查
1. **环境变量**: 确保 `NODE_ENV=production`
2. **依赖版本**: 检查所有依赖版本是否稳定
3. **配置文件**: 验证所有配置文件正确
4. **API地址**: 确认生产环境API地址正确

### 构建后检查
1. **功能测试**: 测试所有核心功能
2. **性能测试**: 检查加载速度和响应时间
3. **错误处理**: 验证错误处理机制
4. **日志检查**: 确认无调试日志输出

## 🛠️ 故障排除

### 常见问题

#### 1. 模拟数据未清理
```bash
# 手动清理模拟数据
node scripts/clean-mock-data.js

# 重新构建
npm run build:weapp:prod
```

#### 2. 测试页面仍存在
```bash
# 检查应用配置
cat src/app.config.ts

# 验证环境变量
echo $NODE_ENV
```

#### 3. 构建失败
```bash
# 清理构建缓存
npm run clean

# 重新安装依赖
rm -rf node_modules package-lock.json
npm install

# 重新构建
npm run build:weapp:prod
```

### 调试模式
```bash
# 启用详细日志
DEBUG=* npm run build:weapp:prod

# 检查构建产物
ls -la dist/
```

## 📊 构建报告

### 成功构建示例
```
🚀 开始生产环境构建...
📋 构建环境信息: { NODE_ENV: 'production', TARO_ENV: 'weapp' }

🧹 步骤1: 清理模拟数据...
✅ 模拟数据清理完成

🔍 步骤2: 验证环境配置...
✅ 生产环境配置正确 - 模拟数据已禁用

🔍 步骤3: 检查服务文件...
✅ 所有服务文件已清理 (6/6)

🔍 步骤4: 检查测试页面配置...
✅ app.config.ts - 测试页面仅在开发环境包含

🔍 步骤5: 最终验证...
✅ 测试页面文件不存在

🎯 生产环境构建准备完成!
📝 构建说明:
  - 模拟数据: 已清理
  - 测试页面: 已排除
  - 调试日志: 已禁用
  - 分析功能: 已启用
  - 错误报告: 已启用

✅ 生产环境构建脚本执行完成!
```

## 🔄 持续集成

### GitHub Actions 集成
```yaml
- name: Build Production
  run: |
    npm run build:weapp:prod
    npm run verify:production
```

### 部署检查清单
- [ ] 模拟数据已清理
- [ ] 测试页面已排除
- [ ] 环境配置正确
- [ ] API地址正确
- [ ] 功能测试通过
- [ ] 性能测试通过
- [ ] 安全检查通过

## 📞 支持

如果遇到问题，请：
1. 查看构建日志
2. 运行验证脚本
3. 检查环境配置
4. 联系开发团队

---

**注意**: 生产环境构建会完全移除所有模拟数据和测试功能，确保应用在生产环境中的稳定性和安全性。
