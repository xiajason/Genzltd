# 跨平台文件上传组件

## 概述

基于 Taro 框架实现的跨平台文件上传组件，支持微信小程序和 H5 端，自动适配平台差异，提供统一的开发体验。

## 核心特性

- ✅ **跨平台兼容**：一套代码支持微信小程序和 H5 端
- ✅ **平台自适应**：自动检测平台并选择最佳上传方式
- ✅ **文件类型支持**：图片、文档、视频、音频等多种格式
- ✅ **进度监控**：实时显示上传进度
- ✅ **错误处理**：完善的错误处理和用户提示
- ✅ **类型安全**：完整的 TypeScript 类型定义

## 平台差异处理

### 微信小程序端
- ✅ 支持图片上传（JPG、PNG、GIF、WebP）
- ✅ 支持视频上传（MP4、MOV）
- ✅ 支持音频上传（MP3、WAV、AAC）
- ❌ 不支持文档上传（PDF、DOC、DOCX）
- 📱 使用微信原生 API

### H5 端
- ✅ 支持图片上传（JPG、PNG、GIF、WebP、SVG）
- ✅ 支持视频上传（MP4、MOV、AVI、WMV、FLV、WebM）
- ✅ 支持音频上传（MP3、WAV、AAC、OGG、M4A）
- ✅ 支持文档上传（PDF、DOC、DOCX、TXT、XLS、XLSX、PPT、PPTX）
- 🌐 使用 Web API

## 使用方法

### 基础用法

```tsx
import { Upload } from '@/components'
import { FileType } from '@/services/uploadService'

const MyComponent = () => {
  const handleUpload = (files) => {
    console.log('上传文件:', files)
  }

  const handleSuccess = (result) => {
    console.log('上传成功:', result)
  }

  const handleError = (error) => {
    console.error('上传失败:', error)
  }

  return (
    <Upload
      type={FileType.IMAGE}
      multiple={true}
      maxCount={5}
      onUpload={handleUpload}
      onSuccess={handleSuccess}
      onError={handleError}
    />
  )
}
```

### 简历上传组件

```tsx
import { ResumeUpload } from '@/components'

const ResumePage = () => {
  return (
    <ResumeUpload
      onUpload={(files) => console.log('上传文件:', files)}
      onSuccess={(result) => console.log('上传成功:', result)}
      onError={(error) => console.error('上传失败:', error)}
    />
  )
}
```

### 直接使用上传服务

```tsx
import { uploadUtils, FileType } from '@/utils/upload'

const handleFileUpload = async () => {
  try {
    // 选择文件
    const files = await uploadUtils.chooseFile(FileType.IMAGE, true)
    
    // 验证文件
    for (const file of files) {
      const validation = uploadUtils.validateFile(file, FileType.IMAGE)
      if (!validation.valid) {
        console.error('文件验证失败:', validation.message)
        return
      }
    }
    
    // 上传文件
    const result = await uploadUtils.uploadFile({
      url: 'https://api.example.com/upload',
      file: files[0], // H5端
      filePath: files[0], // 小程序端
      onProgress: (progress) => {
        console.log('上传进度:', progress)
      }
    })
    
    console.log('上传成功:', result)
  } catch (error) {
    console.error('上传失败:', error)
  }
}
```

## API 参考

### Upload 组件属性

| 属性 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| type | FileType | - | 文件类型（必填） |
| multiple | boolean | false | 是否支持多选 |
| maxCount | number | 9 | 最大文件数量 |
| maxSize | number | - | 最大文件大小（MB） |
| onUpload | function | - | 文件选择回调 |
| onSuccess | function | - | 上传成功回调 |
| onError | function | - | 上传失败回调 |
| onProgress | function | - | 上传进度回调 |
| showPreview | boolean | true | 是否显示预览 |
| showProgress | boolean | true | 是否显示进度 |
| showDelete | boolean | true | 是否显示删除按钮 |
| uploadText | string | - | 自定义上传文本 |
| placeholder | string | - | 自定义占位文本 |
| disabled | boolean | false | 是否禁用 |

### FileType 枚举

```typescript
enum FileType {
  IMAGE = 'image',
  DOCUMENT = 'document',
  VIDEO = 'video',
  AUDIO = 'audio'
}
```

### UploadTask 接口

```typescript
interface UploadTask {
  id: string
  file: File | string
  fileName: string
  fileSize: number
  fileType: string
  status: UploadStatus
  progress: number
  error?: string
  result?: UploadResponse
  onProgress?: (progress: number) => void
  onSuccess?: (result: UploadResponse) => void
  onError?: (error: string) => void
}
```

### UploadStatus 枚举

```typescript
enum UploadStatus {
  PENDING = 'pending',
  UPLOADING = 'uploading',
  SUCCESS = 'success',
  FAILED = 'failed',
  CANCELLED = 'cancelled'
}
```

## 平台特定处理

### 微信小程序限制处理

```tsx
// 自动检测平台并显示相应提示
{uploadUtils.isWeapp && type === FileType.DOCUMENT && (
  <View className="upload-tip">
    <Text>微信小程序暂不支持文档上传，请使用网页版</Text>
  </View>
)}
```

### H5 端增强功能

```tsx
// H5 端支持更多文件格式和功能
{uploadUtils.isH5 && (
  <Upload
    type={FileType.DOCUMENT}
    multiple={true}
    maxCount={10}
    // H5 端支持更多配置选项
  />
)}
```

## 错误处理

组件会自动处理以下错误情况：

1. **文件格式不支持**：显示支持的格式列表
2. **文件大小超限**：显示大小限制提示
3. **网络错误**：显示网络错误信息
4. **平台限制**：显示平台特定提示

## 样式定制

组件提供了完整的 SCSS 样式文件，支持：

- 响应式设计
- 暗色主题
- 自定义样式变量
- 平台特定样式

## 最佳实践

1. **文件验证**：始终在上传前验证文件格式和大小
2. **错误处理**：提供友好的错误提示和重试机制
3. **进度反馈**：显示上传进度提升用户体验
4. **平台适配**：根据平台特性提供不同的功能选项
5. **性能优化**：合理设置并发上传数量

## 注意事项

1. 微信小程序不支持直接上传文档文件
2. 不同平台支持的文件格式有差异
3. 文件大小限制因平台而异
4. 上传进度在小程序端可能不够精确
5. 建议在生产环境中配置合适的服务器端上传接口
