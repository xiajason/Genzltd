# 微信小程序特定组件库

本组件库专为微信小程序开发设计，基于Taro框架，提供了一套完整的UI组件解决方案。

## 📦 组件分类

### 基础UI组件
- **Button** - 按钮组件
- **Input** - 输入框组件
- **Modal** - 模态框组件
- **Loading** - 加载组件
- **TabBar** - 标签栏组件
- **Form** - 表单组件
- **Empty** - 空状态组件
- **Toast** - 提示组件
- **Image** - 图片组件
- **Container** - 容器组件
- **SearchBar** - 搜索栏组件

### 业务组件
- **ResumeCard** - 简历卡片组件
- **JobCard** - 职位卡片组件

## 🚀 快速开始

### 导入组件
```typescript
import { Button, Input, Modal, Loading } from '@/components'
```

### 基础使用
```typescript
import React from 'react'
import { View } from '@tarojs/components'
import { Button, Input, Modal } from '@/components'

const ExamplePage = () => {
  const [visible, setVisible] = useState(false)
  const [inputValue, setInputValue] = useState('')

  return (
    <View>
      <Input
        placeholder="请输入内容"
        value={inputValue}
        onInput={setInputValue}
      />
      
      <Button
        variant="primary"
        onClick={() => setVisible(true)}
      >
        打开模态框
      </Button>
      
      <Modal
        visible={visible}
        title="提示"
        content="这是一个模态框"
        onClose={() => setVisible(false)}
      />
    </View>
  )
}
```

## 📋 组件详细说明

### Button 按钮组件
```typescript
<Button
  variant="primary"        // 按钮类型: primary | secondary | outline
  size="medium"           // 按钮尺寸: small | medium | large
  loading={false}         // 加载状态
  disabled={false}        // 禁用状态
  onClick={() => {}}      // 点击事件
>
  按钮文本
</Button>
```

### Input 输入框组件
```typescript
<Input
  variant="default"       // 输入框类型: default | outline | filled
  size="medium"          // 输入框尺寸: small | medium | large
  placeholder="请输入"    // 占位符
  value={value}          // 输入值
  onInput={setValue}     // 输入事件
  error={false}          // 错误状态
  label="标签"           // 标签文本
  required={true}        // 必填标识
  helperText="帮助文本"  // 帮助文本
  errorText="错误文本"   // 错误文本
/>
```

### Modal 模态框组件
```typescript
<Modal
  visible={visible}      // 显示状态
  title="标题"          // 标题
  content="内容"        // 内容
  showCancel={true}     // 显示取消按钮
  cancelText="取消"     // 取消按钮文本
  confirmText="确定"    // 确认按钮文本
  onCancel={() => {}}   // 取消事件
  onConfirm={() => {}}  // 确认事件
  onClose={() => {}}    // 关闭事件
  size="medium"         // 尺寸: small | medium | large
  type="info"           // 类型: info | success | warning | error
/>
```

### Loading 加载组件
```typescript
<Loading
  visible={true}         // 显示状态
  text="加载中..."      // 加载文本
  size="medium"         // 尺寸: small | medium | large
  type="spinner"        // 类型: spinner | dots | pulse
  color="#3b82f6"      // 颜色
  overlay={false}       // 是否覆盖层
/>

// 便捷组件
<FullScreenLoading text="加载中..." />
<InlineLoading text="加载中..." />
```

### TabBar 标签栏组件
```typescript
<TabBar
  items={[
    {
      key: 'home',
      title: '首页',
      icon: '🏠',
      selectedIcon: '🏠',
      path: '/pages/index/index'
    }
  ]}
  current="home"
  onChange={(key, item) => {}}
  fixed={true}
  color="#999"
  selectedColor="#3b82f6"
/>
```

### Form 表单组件
```typescript
<Form
  onSubmit={(values) => {}}
  initialValues={{ name: '', email: '' }}
  layout="vertical"
>
  <FormItem name="name" label="姓名" required>
    <Input placeholder="请输入姓名" />
  </FormItem>
  
  <FormItem name="email" label="邮箱" required>
    <Input placeholder="请输入邮箱" />
  </FormItem>
</Form>
```

### Empty 空状态组件
```typescript
<Empty
  title="暂无数据"
  description="当前没有相关数据"
  type="default"        // 类型: default | search | network | error
  size="medium"         // 尺寸: small | medium | large
  action={{
    text: '刷新',
    onClick: () => {}
  }}
/>

// 便捷组件
<SearchEmpty />
<NetworkEmpty />
<ErrorEmpty />
```

### Toast 提示组件
```typescript
<Toast
  visible={visible}
  message="操作成功"
  type="success"        // 类型: success | error | warning | info
  duration={2000}       // 显示时长
  position="center"     // 位置: top | center | bottom
  onClose={() => {}}
/>

// 便捷方法
showSuccess('操作成功')
showError('操作失败')
showWarning('警告信息')
showInfo('提示信息')
```

### Image 图片组件
```typescript
<Image
  src="image.jpg"
  alt="图片描述"
  variant="rounded"     // 类型: default | rounded | circle | square
  size="medium"         // 尺寸: small | medium | large | xlarge
  lazy={true}           // 懒加载
  preview={true}        // 预览功能
  fit="cover"           // 适应方式: contain | cover | fill | scale-down | none
  onLoad={() => {}}
  onError={() => {}}
/>

// 头像组件
<Avatar
  src="avatar.jpg"
  name="张三"
  size="medium"
/>
```

### Container 容器组件
```typescript
<Container
  size="medium"         // 尺寸: small | medium | large | full
  padding={true}        // 内边距
  margin={false}        // 外边距
  background="white"    // 背景: white | gray | transparent
  rounded={true}        // 圆角
  shadow={true}         // 阴影
  border={false}        // 边框
>
  内容
</Container>

// 页面容器
<PageContainer
  title="页面标题"
  showHeader={true}
  safeArea={true}
>
  页面内容
</PageContainer>

// 卡片容器
<Card
  title="卡片标题"
  extra={<Button>操作</Button>}
>
  卡片内容
</Card>
```

### SearchBar 搜索栏组件
```typescript
<SearchBar
  placeholder="请输入搜索关键词"
  value={searchValue}
  onSearch={handleSearch}
  onChange={setSearchValue}
  size="medium"         // 尺寸: small | medium | large
  shape="round"         // 形状: round | square
  showAction={true}     // 显示搜索按钮
  actionText="搜索"     // 搜索按钮文本
  disabled={false}      // 禁用状态
/>

// 搜索历史
<SearchHistory
  history={searchHistory}
  onItemClick={handleHistoryClick}
  onClear={clearHistory}
  maxItems={10}
/>
```

### ResumeCard 简历卡片组件
```typescript
<ResumeCard
  resume={resume}
  onView={handleView}
  onEdit={handleEdit}
  onDelete={handleDelete}
  showActions={true}
  variant="default"     // 类型: default | compact | detailed
/>
```

### JobCard 职位卡片组件
```typescript
<JobCard
  job={job}
  onView={handleView}
  onApply={handleApply}
  onFavorite={handleFavorite}
  isFavorite={false}
  showActions={true}
  variant="default"     // 类型: default | compact | featured
/>
```

## 🎨 主题定制

### 颜色变量
```scss
// 主色调
$primary-color: #3b82f6;
$success-color: #52c41a;
$warning-color: #faad14;
$error-color: #ff4d4f;
$info-color: #1890ff;

// 中性色
$text-color: #333;
$text-color-secondary: #666;
$text-color-disabled: #999;
$border-color: #e5e5e5;
$background-color: #f5f5f5;
```

### 尺寸变量
```scss
// 字体大小
$font-size-small: 12px;
$font-size-base: 14px;
$font-size-large: 16px;

// 间距
$spacing-xs: 4px;
$spacing-sm: 8px;
$spacing-md: 16px;
$spacing-lg: 24px;
$spacing-xl: 32px;

// 圆角
$border-radius-sm: 4px;
$border-radius-base: 8px;
$border-radius-lg: 12px;
```

## 📱 响应式设计

所有组件都支持响应式设计，在移动端会自动调整样式：

```scss
// 移动端适配
@media (max-width: 480px) {
  .custom-button {
    font-size: 14px;
    padding: 8px 16px;
  }
}
```

## 🔧 开发指南

### 添加新组件
1. 在 `src/components/ui/` 或 `src/components/business/` 目录下创建组件文件夹
2. 创建 `index.tsx` 和 `index.scss` 文件
3. 在 `src/components/index.ts` 中导出组件
4. 添加TypeScript类型定义
5. 编写组件文档

### 组件规范
- 使用TypeScript编写，提供完整的类型定义
- 支持多种变体和尺寸
- 提供便捷的API和默认值
- 支持响应式设计
- 遵循微信小程序设计规范

### 测试
```bash
# 运行测试
npm test

# 运行类型检查
npm run type-check

# 运行lint检查
npm run lint
```

## 📄 许可证

MIT License
