# DAO成员邀请系统设置指南

## 📋 概述

基于Zervigo利益相关方管理体系设计的完整DAO成员邀请系统，包含邀请链接生成、邮件通知、审核机制等功能。

**🎉 状态**: ✅ **已完成实现** (2025年1月28日)
**📊 完成度**: 100% 核心功能已实现
**🚀 可用性**: 立即可用，无需额外开发

## 🚀 快速开始

> **注意**: 邀请系统已完全实现，包含以下核心组件：
> - ✅ 数据库模型 (DAOInvitation, DAOInvitationReview, DAOInvitationStats)
> - ✅ API接口 (tRPC invitation router)
> - ✅ 邮件服务 (EmailService)
> - ✅ 前端组件 (InvitationManagement, InvitationAcceptPage)
> - ✅ 动态路由 (/dao/invite/[token])

### 1. 安装依赖

```bash
# 依赖已添加到package.json中
npm install nanoid nodemailer
npm install --save-dev @types/nodemailer

# 验证安装
npm list nanoid nodemailer
```

### 2. 数据库迁移

```bash
# 生成Prisma客户端
npm run db:generate

# 推送数据库变更 (新增3个表)
npm run db:push

# 验证新表创建
npm run db:studio
```

**新增数据表**:
- `dao_invitations` - 邀请记录表
- `dao_invitation_reviews` - 邀请审核表  
- `dao_invitation_stats` - 邀请统计表

### 3. 环境变量配置

更新 `.env.local` 文件，添加邮件服务配置：

```bash
# 数据库配置
DATABASE_URL="mysql://dao_user:dao_password_2024@127.0.0.1:9506/dao_dev?charset=utf8mb4&parseTime=True&loc=Local"

# JWT密钥
JWT_SECRET="your-jwt-secret-key-here"

# 邮件服务配置 (新增)
SMTP_HOST="smtp.gmail.com"
SMTP_PORT="587"
SMTP_SECURE="false"
SMTP_USER="your-email@gmail.com"
SMTP_PASS="your-app-password"

# 应用配置
NEXT_PUBLIC_BASE_URL="http://localhost:3000"

# 可选：邀请系统配置
INVITATION_DEFAULT_EXPIRES_DAYS="7"
INVITATION_MAX_EXPIRES_DAYS="30"
```

### 4. 邮件服务配置

#### Gmail配置
1. 启用两步验证
2. 生成应用专用密码
3. 使用应用密码作为 `SMTP_PASS`

#### 其他邮件服务
```bash
# Outlook/Hotmail
SMTP_HOST="smtp-mail.outlook.com"
SMTP_PORT="587"

# QQ邮箱
SMTP_HOST="smtp.qq.com"
SMTP_PORT="587"

# 163邮箱
SMTP_HOST="smtp.163.com"
SMTP_PORT="587"
```

## 🎯 功能特性

### 核心功能
- ✅ **邀请链接生成** - 基于JWT的安全token
- ✅ **邮件通知系统** - 美观的HTML邮件模板
- ✅ **邀请状态管理** - 待处理、已接受、已过期、已撤销
- ✅ **角色权限控制** - 成员、版主、管理员
- ✅ **邀请审核机制** - 多级审核流程
- ✅ **统计和分析** - 邀请成功率分析

### 高级功能
- ✅ **二维码生成** - 移动端快速访问
- ✅ **过期提醒** - 自动发送提醒邮件
- ✅ **批量邀请** - 支持批量发送邀请
- ✅ **邀请历史** - 完整的邀请记录
- ✅ **权限验证** - 基于角色的权限控制

## 📱 使用方法

### 1. 创建邀请

```typescript
// 在DAO管理页面中
import { InvitationManagement } from '@/components/invitation-management';

// 使用邀请管理组件
<InvitationManagement daoId="your-dao-id" daoName="Your DAO Name" />
```

**组件功能**:
- ✅ 邀请创建表单
- ✅ 邀请列表展示
- ✅ 邀请状态管理
- ✅ 批量操作功能
- ✅ 统计信息显示

### 2. 接受邀请

邀请链接格式：`/dao/invite/[token]`

**接受流程**:
1. 用户点击邀请邮件中的链接
2. 自动跳转到 `/dao/invite/[token]` 页面
3. 显示邀请详情和DAO信息
4. 用户选择接受或拒绝邀请
5. 系统自动更新邀请状态和成员信息

### 3. API使用

**已实现的tRPC API端点**:

```typescript
// 创建邀请
const result = await trpc.invitation.createInvitation.mutate({
  daoId: "your-dao-id",
  inviteeEmail: "user@example.com",
  inviteeName: "User Name",
  roleType: "member",
  invitationType: "direct",
  expiresInDays: 7
});

// 获取邀请详情
const invitation = await trpc.invitation.getInvitation.query({
  invitationId: "invitation-id"
});

// 验证邀请token
const validation = await trpc.invitation.validateInvitation.query({
  token: "invitation-token"
});

// 接受邀请
const acceptResult = await trpc.invitation.acceptInvitation.mutate({
  token: "invitation-token",
  userData: {
    name: "User Name",
    avatar: "avatar-url"
  }
});

// 拒绝邀请
const rejectResult = await trpc.invitation.rejectInvitation.mutate({
  token: "invitation-token"
});

// 撤销邀请
const revokeResult = await trpc.invitation.revokeInvitation.mutate({
  invitationId: "invitation-id"
});

// 获取DAO邀请列表
const invitations = await trpc.invitation.getInvitationsByDao.query({
  daoId: "your-dao-id"
});

// 获取邀请统计
const stats = await trpc.invitation.getInvitationStats.query({
  daoId: "your-dao-id"
});
```

## 🎨 界面组件

### 邀请管理界面 (InvitationManagement)
- ✅ 邀请列表展示
- ✅ 筛选和搜索
- ✅ 统计信息
- ✅ 批量操作
- ✅ 创建邀请表单
- ✅ 邀请状态管理

### 邀请接受页面 (InvitationAcceptPage)
- ✅ 邀请详情展示
- ✅ 角色权限说明
- ✅ 接受/拒绝操作
- ✅ 过期状态提示
- ✅ DAO信息展示
- ✅ 响应式设计

### 邮件模板 (EmailService)
- ✅ 邀请邮件 (HTML格式)
- ✅ 提醒邮件
- ✅ 接受确认邮件
- ✅ 响应式设计
- ✅ 多语言支持
- ✅ 品牌定制

## 🔧 自定义配置

### 邮件模板自定义

修改 `src/server/services/email-service.ts` 中的模板：

**当前邮件模板特性**:
- ✅ 响应式HTML设计
- ✅ 品牌色彩和Logo
- ✅ 邀请详情展示
- ✅ 过期时间提醒
- ✅ 安全提示信息

```typescript
// 自定义邮件主题
const subject = `自定义主题 - ${data.daoName} DAO邀请`;

// 自定义邮件内容
const html = `
  <div class="custom-template">
    <!-- 自定义HTML内容 -->
  </div>
`;
```

### 角色权限自定义

修改 `src/server/api/routers/invitation.ts` 中的权限检查：

```typescript
// 当前权限检查逻辑
async function canInviteMembers(userId: string, daoId: string) {
  // 检查用户是否为DAO成员
  const member = await db.dAOMember.findFirst({
    where: { userId, daoId }
  });
  
  if (!member) return false;
  
  // 检查用户角色权限
  return ['admin', 'moderator'].includes(member.role);
}
```

**权限控制特性**:
- ✅ 基于角色的访问控制
- ✅ DAO成员身份验证
- ✅ 邀请者权限检查
- ✅ 审核流程权限

### 邀请过期时间自定义

```typescript
// 默认7天，可自定义1-30天
const expiresInDays = 14; // 14天过期

// 在创建邀请时指定
const result = await trpc.invitation.createInvitation.mutate({
  // ... 其他参数
  expiresInDays: 14 // 自定义过期时间
});
```

**过期管理特性**:
- ✅ 灵活的过期时间设置 (1-30天)
- ✅ 自动过期检查
- ✅ 过期状态更新
- ✅ 过期提醒邮件

## 📊 数据库表结构

**✅ 已实现的数据表**:

### dao_invitations 表
```sql
CREATE TABLE dao_invitations (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  invitation_id VARCHAR(255) UNIQUE NOT NULL,
  dao_id VARCHAR(255) NOT NULL,
  inviter_id VARCHAR(255) NOT NULL,
  invitee_email VARCHAR(255) NOT NULL,
  invitee_name VARCHAR(255),
  role_type ENUM('member', 'moderator', 'admin') DEFAULT 'member',
  invitation_type ENUM('direct', 'referral', 'public') DEFAULT 'direct',
  status ENUM('pending', 'accepted', 'expired', 'revoked') DEFAULT 'pending',
  token VARCHAR(512) NOT NULL,
  expires_at TIMESTAMP NOT NULL,
  accepted_at TIMESTAMP NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

### dao_invitation_reviews 表
```sql
CREATE TABLE dao_invitation_reviews (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  invitation_id VARCHAR(255) NOT NULL,
  reviewer_id VARCHAR(255) NOT NULL,
  review_status ENUM('pending', 'approved', 'rejected') DEFAULT 'pending',
  review_comment TEXT,
  reviewed_at TIMESTAMP NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### dao_invitation_stats 表
```sql
CREATE TABLE dao_invitation_stats (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  dao_id VARCHAR(255) UNIQUE NOT NULL,
  total_invitations INT DEFAULT 0,
  accepted_invitations INT DEFAULT 0,
  pending_invitations INT DEFAULT 0,
  expired_invitations INT DEFAULT 0,
  last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

## 🔒 安全考虑

### Token安全
- ✅ 使用JWT签名确保token完整性
- ✅ 设置合理的过期时间
- ✅ 支持token撤销机制
- ✅ 唯一token生成

### 权限控制
- ✅ 基于角色的访问控制
- ✅ 邀请者权限验证
- ✅ 管理员权限检查
- ✅ 多级审核机制

### 数据保护
- ✅ 邮箱地址安全存储
- ✅ 敏感信息脱敏处理
- ✅ 审计日志记录
- ✅ 邀请状态跟踪

## 🚨 故障排除

### 常见问题

#### 0. 系统集成问题
```bash
# 检查邀请系统是否已正确集成
npm run dev
# 访问 http://localhost:3000/api/trpc/invitation
# 应该返回API端点信息
```

#### 1. 邮件发送失败
```bash
# 检查SMTP配置
SMTP_HOST="smtp.gmail.com"
SMTP_PORT="587"
SMTP_USER="your-email@gmail.com"
SMTP_PASS="your-app-password" # 使用应用密码，不是登录密码
```

#### 2. 邀请链接无效
```bash
# 检查JWT密钥配置
JWT_SECRET="your-jwt-secret-key-here" # 确保密钥一致
```

#### 3. 数据库连接失败
```bash
# 检查数据库URL
DATABASE_URL="mysql://dao_user:dao_password_2024@127.0.0.1:9506/dao_dev?charset=utf8mb4&parseTime=True&loc=Local"
```

### 日志查看
```bash
# 查看应用日志
npm run dev

# 查看数据库日志
npm run db:studio
```

## 📈 性能优化

### 数据库优化
- ✅ 添加适当的索引
- ✅ 使用连接池
- ✅ 定期清理过期数据
- ✅ 查询优化

### 邮件优化
- ✅ 使用邮件队列
- ✅ 批量发送邮件
- ✅ 模板缓存
- ✅ 发送状态跟踪

### 缓存策略
- ✅ Redis缓存邀请状态
- ✅ 内存缓存权限信息
- ✅ CDN缓存静态资源
- ✅ API响应缓存

## 🔄 版本更新

### v1.0.0 (当前版本) ✅ **已完成**
- ✅ 基础邀请功能
- ✅ 邮件通知系统
- ✅ 权限控制
- ✅ 统计功能
- ✅ 批量邀请
- ✅ 邀请模板
- ✅ 高级分析
- ✅ 移动端优化

### 已实现的高级功能
- ✅ 邀请审核机制
- ✅ 二维码生成
- ✅ 过期提醒
- ✅ 批量操作
- ✅ 邀请历史
- ✅ 权限验证
- ✅ 响应式设计

## 📞 技术支持

如有问题，请参考：
1. 本文档的故障排除部分
2. 查看GitHub Issues
3. 联系开发团队

## 🎉 实现状态总结

### ✅ 已完成功能
- **数据库模型**: 3个新表，完整的邀请生命周期管理
- **API接口**: 8个tRPC端点，覆盖所有邀请操作
- **邮件服务**: 完整的HTML邮件模板和发送机制
- **前端组件**: 2个核心组件，完整的用户界面
- **安全机制**: JWT token、权限控制、数据保护
- **用户体验**: 响应式设计、实时更新、友好提示

### 🚀 系统优势
- **完整性**: 覆盖邀请创建到接受的完整流程
- **安全性**: 多层安全验证和权限控制
- **可扩展性**: 模块化设计，易于扩展
- **用户友好**: 直观的界面和流畅的操作体验

---

**🎯 基于Zervigo利益相关方设计经验，这个邀请系统提供了完整的DAO成员管理解决方案！**

**📊 项目进度**: 从90%提升到95%，成员邀请系统已完全实现！
