# API配置指南

## 📋 概述

本项目已实现统一的API配置管理系统，支持多环境、多平台的灵活配置。

## 🔧 配置结构

### 1. 核心配置文件
- `src/config/api.ts` - API配置管理核心文件
- `src/services/request.ts` - 统一请求处理

### 2. 环境配置
- **开发环境**: `NODE_ENV=development`
- **生产环境**: `NODE_ENV=production`
- **测试环境**: `NODE_ENV=test`

### 3. 平台配置
- **微信小程序**: `TARO_ENV=weapp`
- **H5**: `TARO_ENV=h5`
- **React Native**: `TARO_ENV=rn`

## 🚀 使用方法

### 基本用法
```typescript
import { request } from '@/services/request'

// 使用统一请求函数
const data = await request({
  url: '/api/v1/users',
  method: 'GET',
  showLoading: true
})
```

### 便捷方法
```typescript
import { api } from '@/services/request'

// GET请求
const users = await api.get('/api/v1/users')

// POST请求
const result = await api.post('/api/v1/users', { name: 'John' })

// PUT请求
const updated = await api.put('/api/v1/users/1', { name: 'Jane' })

// DELETE请求
await api.delete('/api/v1/users/1')
```

## ⚙️ 配置说明

### 环境配置映射
```typescript
const environmentConfigs = {
  development: {
    baseUrl: 'http://localhost:8080',
    version: 'v1',
    timeout: 10000,
    retryCount: 3
  },
  production: {
    baseUrl: 'https://api.jobfirst.com',
    version: 'v1',
    timeout: 15000,
    retryCount: 2
  },
  test: {
    baseUrl: 'http://localhost:8080',
    version: 'v1',
    timeout: 5000,
    retryCount: 1
  }
}
```

### 平台特殊配置
```typescript
const platformOverrides = {
  weapp: {
    timeout: 20000, // 小程序网络请求超时时间更长
    retryCount: 3
  },
  h5: {
    timeout: 10000,
    retryCount: 2
  }
}
```

## 🔄 重试机制

- **开发环境**: 最多重试3次
- **生产环境**: 最多重试2次
- **测试环境**: 最多重试1次
- **重试间隔**: 递增延迟 (1s, 2s, 3s...)

## 🛡️ 错误处理

### 自动处理
- **401未授权**: 自动清除token并跳转登录页
- **403权限不足**: 显示权限错误提示
- **500服务器错误**: 显示服务器错误提示
- **网络错误**: 自动重试机制

### 自定义错误处理
```typescript
const data = await request({
  url: '/api/v1/users',
  showError: false, // 禁用自动错误提示
  showLoading: true // 显示加载状态
})
```

## 📱 平台适配

### 微信小程序
- 自动使用小程序优化的超时时间
- 支持小程序特有的网络请求配置
- 兼容小程序的存储API

### H5
- 支持浏览器环境
- 兼容CORS配置
- 支持现代浏览器的网络API

## 🔍 调试信息

开发环境下会在控制台输出配置信息：
```
🔧 API配置信息: {
  environment: "development",
  platform: "weapp",
  config: {
    baseUrl: "http://localhost:8080",
    version: "v1",
    timeout: 20000,
    retryCount: 3
  }
}
```

## 📝 最佳实践

1. **统一使用request函数**: 避免直接使用Taro.request
2. **合理设置超时时间**: 根据网络环境调整
3. **启用重试机制**: 提高请求成功率
4. **错误处理**: 根据业务需求选择是否显示错误提示
5. **加载状态**: 长时间请求建议显示加载状态

## 🚨 注意事项

1. **环境变量**: 确保正确设置NODE_ENV和TARO_ENV
2. **API地址**: 生产环境必须使用HTTPS
3. **跨域问题**: H5环境需要后端支持CORS
4. **小程序域名**: 微信小程序需要配置合法域名
5. **网络超时**: 根据实际网络环境调整超时时间

## 🔧 自定义配置

如需自定义配置，可以修改`src/config/api.ts`文件：

```typescript
// 添加新的环境配置
const environmentConfigs = {
  // ... 现有配置
  staging: {
    baseUrl: 'https://staging-api.jobfirst.com',
    version: 'v1',
    timeout: 12000,
    retryCount: 2
  }
}

// 添加新的平台配置
const platformOverrides = {
  // ... 现有配置
  alipay: {
    timeout: 15000,
    retryCount: 2
  }
}
```
