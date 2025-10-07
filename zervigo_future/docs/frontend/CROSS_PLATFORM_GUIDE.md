# Taro跨端适配组件使用指南

## 📋 概述

根据Taro统一开发方案，我们创建了专门的跨端适配组件来解决`enablePullDownRefresh`等API在不同平台下的兼容性问题。这些组件确保在微信小程序和H5环境下都能正常工作。

## 🎯 核心组件

### 1. PullToRefresh - 下拉刷新组件

#### 功能特性
- ✅ **微信小程序**: 使用原生下拉刷新API
- ✅ **H5环境**: 使用自定义触摸事件实现下拉刷新
- ✅ **跨端兼容**: 自动检测平台并使用对应实现
- ✅ **阻尼效果**: H5环境下提供平滑的下拉体验
- ✅ **状态管理**: 支持刷新状态和错误处理

#### 使用方法

```typescript
import { PullToRefresh } from '@/components'

const MyPage = () => {
  const [refreshing, setRefreshing] = useState(false)

  const handleRefresh = async () => {
    setRefreshing(true)
    try {
      // 执行刷新逻辑
      await fetchData()
    } finally {
      setRefreshing(false)
    }
  }

  return (
    <PullToRefresh
      onRefresh={handleRefresh}
      refreshing={refreshing}
      threshold={50}
    >
      <View>页面内容</View>
    </PullToRefresh>
  )
}
```

#### 属性说明

| 属性 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| children | ReactNode | - | 子组件内容 |
| onRefresh | () => Promise<void> \| void | - | 刷新回调函数 |
| refreshing | boolean | false | 是否正在刷新 |
| disabled | boolean | false | 是否禁用下拉刷新 |
| threshold | number | 50 | 触发刷新的下拉距离阈值 |
| className | string | '' | 自定义样式类名 |

### 2. LoadMore - 上拉加载更多组件

#### 功能特性
- ✅ **微信小程序**: 使用原生上拉加载API
- ✅ **H5环境**: 使用滚动事件监听实现上拉加载
- ✅ **智能检测**: 自动检测是否接近页面底部
- ✅ **状态管理**: 支持加载状态、错误状态、无更多数据状态
- ✅ **重试机制**: 支持加载失败后重试

#### 使用方法

```typescript
import { LoadMore } from '@/components'

const MyPage = () => {
  const [loading, setLoading] = useState(false)
  const [hasMore, setHasMore] = useState(true)
  const [data, setData] = useState([])

  const handleLoadMore = async () => {
    setLoading(true)
    try {
      const newData = await fetchMoreData()
      setData(prev => [...prev, ...newData])
      setHasMore(newData.length > 0)
    } finally {
      setLoading(false)
    }
  }

  return (
    <LoadMore
      onLoadMore={handleLoadMore}
      hasMore={hasMore}
      loading={loading}
      threshold={100}
    >
      {data.map(item => (
        <View key={item.id}>{item.content}</View>
      ))}
    </LoadMore>
  )
}
```

#### 属性说明

| 属性 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| children | ReactNode | - | 子组件内容 |
| onLoadMore | () => Promise<void> \| void | - | 加载更多回调函数 |
| hasMore | boolean | true | 是否还有更多数据 |
| loading | boolean | false | 是否正在加载 |
| disabled | boolean | false | 是否禁用上拉加载 |
| threshold | number | 100 | 触发加载的滚动距离阈值 |
| loadingText | string | '加载中...' | 加载中的提示文字 |
| noMoreText | string | '没有更多了' | 无更多数据的提示文字 |
| errorText | string | '加载失败，点击重试' | 加载失败的提示文字 |
| onRetry | () => void | - | 重试回调函数 |

### 3. CrossPlatformPageContainer - 页面容器组件

#### 功能特性
- ✅ **集成功能**: 同时支持下拉刷新和上拉加载
- ✅ **跨端适配**: 自动适配不同平台的实现方式
- ✅ **统一接口**: 提供统一的API接口
- ✅ **状态管理**: 统一管理刷新和加载状态

#### 使用方法

```typescript
import { CrossPlatformPageContainer } from '@/components'

const JobsPage = () => {
  const [jobs, setJobs] = useState([])
  const [loading, setLoading] = useState(false)
  const [hasMore, setHasMore] = useState(true)

  const handleRefresh = async () => {
    setLoading(true)
    try {
      const newJobs = await fetchJobs()
      setJobs(newJobs)
    } finally {
      setLoading(false)
    }
  }

  const handleLoadMore = async () => {
    setLoading(true)
    try {
      const moreJobs = await fetchMoreJobs()
      setJobs(prev => [...prev, ...moreJobs])
      setHasMore(moreJobs.length > 0)
    } finally {
      setLoading(false)
    }
  }

  return (
    <CrossPlatformPageContainer
      onRefresh={handleRefresh}
      onLoadMore={handleLoadMore}
      refreshing={loading}
      loading={loading}
      hasMore={hasMore}
      className="jobs-page"
    >
      <View className="page-header">
        <Text>职位搜索</Text>
      </View>
      
      {jobs.map(job => (
        <JobCard key={job.id} job={job} />
      ))}
    </CrossPlatformPageContainer>
  )
}
```

#### 属性说明

| 属性 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| children | ReactNode | - | 子组件内容 |
| onRefresh | () => Promise<void> \| void | - | 下拉刷新回调 |
| onLoadMore | () => Promise<void> \| void | - | 上拉加载回调 |
| refreshing | boolean | false | 是否正在刷新 |
| loading | boolean | false | 是否正在加载 |
| hasMore | boolean | true | 是否还有更多数据 |
| disabled | boolean | false | 是否禁用所有功能 |
| pullRefreshThreshold | number | 50 | 下拉刷新阈值 |
| loadMoreThreshold | number | 100 | 上拉加载阈值 |
| loadingText | string | '加载中...' | 加载提示文字 |
| noMoreText | string | '没有更多了' | 无更多数据提示 |
| errorText | string | '加载失败，点击重试' | 错误提示文字 |
| onRetry | () => void | - | 重试回调 |

## 🔧 平台适配原理

### 微信小程序环境

```typescript
// 微信小程序使用原生API
if (platform.isWeapp) {
  // 下拉刷新：通过页面配置启用
  // 上拉加载：通过onReachBottom事件处理
  return <View className="native-implementation">{children}</View>
}
```

### H5环境

```typescript
// H5环境使用自定义实现
if (platform.isH5) {
  // 下拉刷新：监听touchstart/touchmove/touchend事件
  // 上拉加载：监听scroll事件检测滚动位置
  return <View className="custom-implementation">{children}</View>
}
```

## 📱 实际应用示例

### 职位列表页面

```typescript
// pages/jobs/index.tsx
import { CrossPlatformPageContainer } from '@/components'

const JobsPage = () => {
  const [jobs, setJobs] = useState([])
  const [loading, setLoading] = useState(false)
  const [hasMore, setHasMore] = useState(true)

  const handleRefresh = async () => {
    setLoading(true)
    try {
      const newJobs = await jobService.getList()
      setJobs(newJobs)
    } finally {
      setLoading(false)
    }
  }

  const handleLoadMore = async () => {
    setLoading(true)
    try {
      const moreJobs = await jobService.getList({ page: currentPage + 1 })
      setJobs(prev => [...prev, ...moreJobs])
      setHasMore(moreJobs.length > 0)
    } finally {
      setLoading(false)
    }
  }

  return (
    <CrossPlatformPageContainer
      onRefresh={handleRefresh}
      onLoadMore={handleLoadMore}
      refreshing={loading}
      loading={loading}
      hasMore={hasMore}
    >
      {/* 页面内容 */}
    </CrossPlatformPageContainer>
  )
}
```

### 简历列表页面

```typescript
// pages/resume/index.tsx
import { CrossPlatformPageContainer } from '@/components'

const ResumePage = () => {
  const { resumes, loading, fetchResumes } = useResumeStore()

  const handleRefresh = async () => {
    await fetchResumes(true) // 强制刷新
  }

  return (
    <CrossPlatformPageContainer
      onRefresh={handleRefresh}
      refreshing={loading}
      hasMore={false} // 简历列表通常不需要分页
    >
      {resumes.map(resume => (
        <ResumeCard key={resume.id} resume={resume} />
      ))}
    </CrossPlatformPageContainer>
  )
}
```

## 🎨 样式定制

### 自定义下拉刷新样式

```scss
// 自定义样式
.my-pull-refresh {
  .pull-to-refresh__indicator {
    background: linear-gradient(180deg, #your-color 0%, transparent 100%);
  }
  
  .pull-to-refresh__icon-text {
    color: #your-color;
  }
}
```

### 自定义加载更多样式

```scss
// 自定义样式
.my-load-more {
  .load-more__footer {
    background: #your-background;
    border-top-color: #your-border-color;
  }
  
  .load-more__text {
    color: #your-text-color;
  }
}
```

## ⚡ 性能优化

### 1. 防抖处理
```typescript
const handleRefresh = debounce(async () => {
  // 刷新逻辑
}, 300)
```

### 2. 缓存策略
```typescript
const handleLoadMore = useCallback(async () => {
  // 使用useCallback避免重复创建函数
}, [dependencies])
```

### 3. 状态管理
```typescript
// 使用Zustand管理状态
const { data, loading, fetchData } = useDataStore()
```

## 🐛 常见问题

### Q1: H5环境下下拉刷新不生效？
**A:** 确保页面在顶部时才能触发下拉刷新，检查是否有其他滚动容器干扰。

### Q2: 微信小程序下拉刷新配置？
**A:** 在页面配置文件中添加：
```json
{
  "enablePullDownRefresh": true,
  "onReachBottomDistance": 50
}
```

### Q3: 如何自定义刷新动画？
**A:** 通过CSS动画自定义：
```scss
.pull-to-refresh__icon-text--spinning {
  animation: custom-spin 1s linear infinite;
}
```

## 📚 最佳实践

1. **统一使用CrossPlatformPageContainer**: 对于需要下拉刷新和上拉加载的页面
2. **合理设置阈值**: 根据页面内容调整threshold值
3. **错误处理**: 始终处理异步操作的错误情况
4. **状态管理**: 使用状态管理库统一管理数据状态
5. **性能优化**: 使用防抖和缓存策略优化用户体验

## 🔄 迁移指南

### 从原生API迁移

```typescript
// 旧代码
useEffect(() => {
  Taro.enablePullDownRefresh()
  Taro.onReachBottom(handleReachBottom)
}, [])

// 新代码
<CrossPlatformPageContainer
  onRefresh={handleRefresh}
  onLoadMore={handleLoadMore}
>
  {/* 页面内容 */}
</CrossPlatformPageContainer>
```

这样就完成了从平台特定API到跨端适配组件的迁移，确保在所有平台上都能正常工作。
