# DAO Genie API密钥配置指南

## 🔑 必需的API密钥配置

为了让DAO Genie完全运行，需要配置以下API密钥：

### 1. Anthropic API Key (必需)
**用途**: AI功能支持
**获取方式**:
1. 访问 https://console.anthropic.com/
2. 注册账号并登录
3. 在API Keys页面创建新的API密钥
4. 格式: `sk-ant-api03-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

**配置方法**:
```env
ANTHROPIC_API_KEY="sk-ant-api03-your-actual-key-here"
```

### 2. Dynamic Labs Environment ID (必需)
**用途**: 钱包连接功能
**获取方式**:
1. 访问 https://app.dynamic.xyz/
2. 注册账号并登录
3. 创建新的项目
4. 获取Environment ID

**配置方法**:
```env
DYNAMIC_ENV_ID="your-environment-id"
NEXT_PUBLIC_DYNAMIC_ENV_ID="your-environment-id"
```

### 3. Aloria API Key (可选)
**用途**: 特定服务集成
**获取方式**: 根据Aloria服务文档获取

**配置方法**:
```env
ALORIA_API_KEY="your-aloria-key"
```

## 🚀 快速启动方案

### 方案一：使用测试密钥（开发环境）
```env
# 测试配置 - 仅用于开发
ANTHROPIC_API_KEY="sk-test-key"
DYNAMIC_ENV_ID="dev-12345"
NEXT_PUBLIC_DYNAMIC_ENV_ID="dev-12345"
ALORIA_API_KEY="aloria-test-key"
```

### 方案二：配置真实密钥（生产环境）
1. 按照上述方式获取真实API密钥
2. 更新.env.local文件
3. 重启开发服务器

## 🔧 配置步骤

1. **编辑环境变量文件**:
   ```bash
   nano .env.local
   ```

2. **更新API密钥**:
   将测试密钥替换为真实密钥

3. **重启服务**:
   ```bash
   npm run dev
   ```

## ⚠️ 安全注意事项

1. **不要提交密钥**: 确保.env.local在.gitignore中
2. **使用环境变量**: 生产环境使用系统环境变量
3. **定期轮换**: 定期更新API密钥
4. **权限控制**: 仅给予必要的API权限

## 🆘 故障排除

### 问题1: "Invalid environment variables"
**解决方案**: 检查.env.local文件中的API密钥格式

### 问题2: "API key not found"
**解决方案**: 确认API密钥已正确配置且有效

### 问题3: "Database connection failed"
**解决方案**: 确保PostgreSQL运行在9508端口

## 📞 获取帮助

如果遇到API密钥配置问题，可以：
1. 查看官方文档
2. 联系API服务提供商
3. 使用测试密钥进行开发
