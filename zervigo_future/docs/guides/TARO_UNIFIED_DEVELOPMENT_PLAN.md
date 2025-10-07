# JobFirst Taro统一开发方案

## 📋 项目概述

基于对当前项目结构的分析，JobFirst项目包含微信小程序端（原生开发）和Web端（Next.js + React），两者功能重叠导致代码重复开发、功能同步困难和维护成本高等问题。

本方案采用Taro框架实现跨端统一开发，一套代码同时支持微信小程序和Web端，显著提升开发效率和维护性。

## 🎯 当前项目分析

### 技术栈对比

| 项目 | 小程序端 | Web端 |
|------|----------|-------|
| **框架** | 微信小程序原生 | Next.js 14 + React 18 |
| **语言** | JavaScript ES6+ | TypeScript |
| **样式** | WXSS | Tailwind CSS + CSS Modules |
| **状态管理** | 页面级数据绑定 | React Query + Zustand |
| **UI组件** | 原生组件 | Ant Design 5.x |
| **API调用** | wx.request | Axios |

### 功能重叠分析

- ✅ **用户认证**：登录、注册、用户信息管理
- ✅ **简历管理**：创建、编辑、删除、列表展示
- ✅ **职位搜索**：职位列表、详情、申请
- ✅ **AI助手**：聊天功能、简历分析
- ✅ **数据分析**：统计图表、个人数据

### 开发挑战

1. **代码重复**：相同功能需要两套代码实现
2. **功能同步**：新功能需要在两个端分别开发
3. **维护成本**：Bug修复和功能更新需要重复操作
4. **测试复杂**：需要分别测试两个端的兼容性

## 🚀 Taro统一开发方案

### 1. 技术架构设计

```
┌─────────────────────────────────────────────────────────────┐
│                    Taro统一开发架构                          │
├─────────────────────────────────────────────────────────────┤
│  Taro 4.x Framework                                        │
│  ├── React 18 + TypeScript                                │
│  ├── 统一组件库 (Taro UI + 自定义组件)                     │
│  ├── 统一状态管理 (Zustand)                               │
│  └── 统一API服务层                                        │
├─────────────────────────────────────────────────────────────┤
│  编译输出                                                  │
│  ├── 微信小程序 (--type weapp)                            │
│  ├── H5 Web端 (--type h5)                                │
│  └── 其他平台 (--type rn, --type swan)                   │
├─────────────────────────────────────────────────────────────┤
│  后端微服务架构 (保持不变)                                 │
│  ├── User Service (Port 8001)                            │
│  ├── Resume Service (Port 8002)                          │
│  ├── AI Service (Port 8206)                              │
│  └── API Gateway (Port 8080)                             │
└─────────────────────────────────────────────────────────────┘
```

### 2. 项目结构设计

```
frontend/
├── taro-unified/                    # Taro统一项目
│   ├── src/
│   │   ├── app.tsx                  # 应用入口
│   │   ├── app.config.ts            # 应用配置
│   │   ├── pages/                   # 页面目录
│   │   │   ├── index/              # 首页
│   │   │   ├── login/              # 登录页
│   │   │   ├── register/           # 注册页
│   │   │   ├── profile/            # 个人中心
│   │   │   ├── resume/             # 简历管理
│   │   │   ├── jobs/               # 职位列表
│   │   │   ├── chat/               # AI助手
│   │   │   └── analytics/          # 数据分析
│   │   ├── components/             # 共享组件
│   │   │   ├── common/            # 通用组件
│   │   │   ├── business/          # 业务组件
│   │   │   └── ui/                # UI组件
│   │   ├── services/              # API服务层
│   │   │   ├── api.ts             # API配置
│   │   │   ├── auth.ts            # 认证服务
│   │   │   ├── user.ts            # 用户服务
│   │   │   ├── resume.ts          # 简历服务
│   │   │   ├── job.ts             # 职位服务
│   │   │   └── ai.ts              # AI服务
│   │   ├── stores/                # 状态管理
│   │   │   ├── auth.ts            # 认证状态
│   │   │   ├── user.ts            # 用户状态
│   │   │   ├── resume.ts          # 简历状态
│   │   │   └── job.ts             # 职位状态
│   │   ├── utils/                 # 工具函数
│   │   │   ├── request.ts         # 请求封装
│   │   │   ├── storage.ts         # 存储封装
│   │   │   ├── auth.ts            # 认证工具
│   │   │   └── common.ts          # 通用工具
│   │   ├── types/                 # 类型定义
│   │   │   ├── api.ts             # API类型
│   │   │   ├── user.ts            # 用户类型
│   │   │   ├── resume.ts          # 简历类型
│   │   │   └── job.ts             # 职位类型
│   │   └── styles/                # 样式文件
│   │       ├── global.scss        # 全局样式
│   │       ├── variables.scss     # 变量定义
│   │       └── mixins.scss        # 混入
│   ├── config/                    # 配置文件
│   │   ├── index.ts               # 主配置
│   │   ├── dev.ts                 # 开发配置
│   │   └── prod.ts                # 生产配置
│   ├── package.json               # 依赖配置
│   ├── tsconfig.json              # TypeScript配置
│   └── taro.config.ts             # Taro配置
├── miniprogram/                   # 原有小程序 (保留备份)
└── web/                          # 原有Web端 (保留备份)
```

### 3. 核心组件设计

#### 3.1 统一API服务层

```typescript
// src/api/request.ts
import Taro from '@tarojs/taro'

// API基础配置
const API_BASE_URL = process.env.NODE_ENV === 'development' 
  ? 'http://localhost:8080' 
  : 'https://api.jobfirst.com'

// 统一响应格式
interface ApiResponse<T = any> {
  code: number
  message: string
  data: T
  meta?: {
    pagination?: Pagination
    timestamp: number
    version: string
  }
}

// 请求配置接口
interface RequestOptions {
  url: string
  method?: 'GET' | 'POST' | 'PUT' | 'DELETE'
  data?: any
  header?: Record<string, string>
  timeout?: number
  showLoading?: boolean
  showError?: boolean
}

// 统一请求函数
export async function request<T>(options: RequestOptions): Promise<T> {
  const { 
    url, 
    method = 'GET', 
    data, 
    header = {}, 
    timeout = 10000,
    showLoading = false,
    showError = true
  } = options
  
  // 显示加载状态
  if (showLoading) {
    Taro.showLoading({ title: '加载中...' })
  }
  
  // 添加通用header
  const commonHeader = {
    'Content-Type': 'application/json',
    'API-Version': 'v2',
    ...header
  }
  
  // 添加token
  const token = Taro.getStorageSync('access_token')
  if (token) {
    commonHeader['Authorization'] = `Bearer ${token}`
  }
  
  try {
    const response = await Taro.request({
      url: `${API_BASE_URL}${url}`,
      method,
      data,
      header: commonHeader,
      timeout
    })
    
    // 隐藏加载状态
    if (showLoading) {
      Taro.hideLoading()
    }
    
    // 统一处理响应
    if (response.statusCode === 200) {
      const result = response.data as ApiResponse<T>
      
      // 检查业务状态码
      if (result.code === 200) {
        return result.data
      } else {
        throw new Error(result.message || '请求失败')
      }
    } else if (response.statusCode === 401) {
      // 处理未授权
      handleUnauthorized()
      throw new Error('未授权，请重新登录')
    } else if (response.statusCode === 403) {
      // 处理权限不足
      throw new Error('权限不足')
    } else if (response.statusCode >= 500) {
      // 处理服务器错误
      throw new Error('服务器错误，请稍后重试')
    } else {
      throw new Error(response.data?.message || '请求失败')
    }
  } catch (error) {
    // 隐藏加载状态
    if (showLoading) {
      Taro.hideLoading()
    }
    
    // 统一错误处理
    const errorMessage = error.message || '网络错误'
    
    if (showError) {
      Taro.showToast({
        title: errorMessage,
        icon: 'none',
        duration: 2000
      })
    }
    
    console.error('API request error:', error)
    throw error
  }
}

// 处理未授权情况
function handleUnauthorized() {
  // 清除本地存储的认证信息
  Taro.removeStorageSync('access_token')
  Taro.removeStorageSync('refresh_token')
  Taro.removeStorageSync('user_info')
  
  // 跳转到登录页
  Taro.reLaunch({
    url: '/pages/login/index'
  })
}

// 便捷的请求方法
export const api = {
  get: <T>(url: string, params?: any, options?: Partial<RequestOptions>) =>
    request<T>({ url, method: 'GET', data: params, ...options }),
    
  post: <T>(url: string, data?: any, options?: Partial<RequestOptions>) =>
    request<T>({ url, method: 'POST', data, ...options }),
    
  put: <T>(url: string, data?: any, options?: Partial<RequestOptions>) =>
    request<T>({ url, method: 'PUT', data, ...options }),
    
  delete: <T>(url: string, data?: any, options?: Partial<RequestOptions>) =>
    request<T>({ url, method: 'DELETE', data, ...options })
}

// 业务API服务
export class ApiService {
  // 用户相关API
  static user = {
    login: (data: LoginRequest) => 
      api.post<LoginResponse>('/api/v2/auth/login', data),
      
    register: (data: RegisterRequest) => 
      api.post<RegisterResponse>('/api/v2/auth/register', data),
      
    getInfo: () => 
      api.get<UserInfo>('/api/v2/user/info'),
      
    updateInfo: (data: UpdateUserRequest) => 
      api.put<UserInfo>('/api/v2/user/update', data),
      
    changePassword: (data: ChangePasswordRequest) => 
      api.put('/api/v2/user/change-password', data)
  }
  
  // 简历相关API
  static resume = {
    getList: (params?: ResumeListParams) => 
      api.get<ResumeListResponse>('/api/v1/resume/list', params),
      
    getDetail: (id: string) => 
      api.get<ResumeDetail>('/api/v1/resume/detail', { id }),
      
    create: (data: CreateResumeRequest) => 
      api.post<ResumeDetail>('/api/v1/resume/create', data),
      
    update: (id: string, data: UpdateResumeRequest) => 
      api.put<ResumeDetail>(`/api/v1/resume/update/${id}`, data),
      
    delete: (id: string) => 
      api.delete(`/api/v1/resume/delete/${id}`),
      
    upload: (file: File) => 
      api.post<UploadResponse>('/api/v1/resume/upload', file)
  }
  
  // 职位相关API
  static job = {
    getList: (params?: JobListParams) => 
      api.get<JobListResponse>('/api/v2/jobs', params),
      
    getDetail: (id: string) => 
      api.get<JobDetail>(`/api/v2/jobs/${id}`),
      
    search: (params: JobSearchParams) => 
      api.get<JobListResponse>('/api/v2/jobs/search', params),
      
    apply: (data: JobApplyRequest) => 
      api.post('/api/v2/jobs/apply', data),
      
    favorite: (jobId: string) => 
      api.post(`/api/v2/jobs/${jobId}/favorite`),
      
    unfavorite: (jobId: string) => 
      api.delete(`/api/v2/jobs/${jobId}/favorite`)
  }
  
  // AI相关API
  static ai = {
    analyzeResume: (data: AnalyzeResumeRequest) => 
      api.post<AnalyzeResumeResponse>('/api/v1/analyze/resume', data),
      
    chat: (data: ChatRequest) => 
      api.post<ChatResponse>('/api/v1/chat/aiChat', data),
      
    getVectors: (resumeId: string) => 
      api.get<VectorResponse>(`/api/v1/vectors/${resumeId}`),
      
    searchSimilar: (data: SearchSimilarRequest) => 
      api.post<SimilarResumeResponse>('/api/v1/vectors/search', data)
  }
  
  // 统计数据API
  static statistics = {
    getMarketData: () => 
      api.get<MarketData>('/api/v1/statistics/market'),
      
    getPersonalData: () => 
      api.get<PersonalData>('/api/v1/statistics/personal'),
      
    getEnterpriseData: () => 
      api.get<EnterpriseData>('/api/v1/statistics/enterprise')
  }
}
```

#### 3.1.1 使用示例

```typescript
// 在页面中使用API服务
import { ApiService } from '@/api/request'

// 用户登录
const handleLogin = async (loginData: LoginRequest) => {
  try {
    const response = await ApiService.user.login(loginData)
    // 处理登录成功
    console.log('登录成功:', response)
  } catch (error) {
    // 错误已在request函数中统一处理
    console.error('登录失败:', error)
  }
}

// 获取简历列表（带加载状态）
const loadResumeList = async () => {
  try {
    const resumes = await ApiService.resume.getList(
      { page: 1, size: 10 },
      { showLoading: true }
    )
    setResumeList(resumes)
  } catch (error) {
    // 错误处理
  }
}

// 静默请求（不显示错误提示）
const checkUserStatus = async () => {
  try {
    const userInfo = await ApiService.user.getInfo({
      showError: false
    })
    return userInfo
  } catch (error) {
    return null
  }
}
```

#### 3.2 业务逻辑服务层

```typescript
// src/services/resumeService.ts
import { request } from '../api/request'
import { Resume, ResumeForm, ResumeListParams } from '../types/resume'

export const resumeService = {
  // 获取简历列表
  getList: (params?: ResumeListParams) => request<Resume[]>({
    url: '/api/v1/resume/list',
    method: 'GET',
    data: params
  }),
  
  // 获取简历详情
  getDetail: (id: string) => request<Resume>({
    url: `/api/v1/resume/detail/${id}`,
    method: 'GET'
  }),
  
  // 创建简历
  create: (data: ResumeForm) => request<Resume>({
    url: '/api/v1/resume/create',
    method: 'POST',
    data
  }),
  
  // 更新简历
  update: (id: string, data: ResumeForm) => request<Resume>({
    url: `/api/v1/resume/update/${id}`,
    method: 'PUT',
    data
  }),
  
  // 删除简历
  delete: (id: string) => request<boolean>({
    url: `/api/v1/resume/delete/${id}`,
    method: 'DELETE'
  }),

  // 上传简历文件
  upload: (file: File) => request<{ url: string; filename: string }>({
    url: '/api/v1/resume/upload',
    method: 'POST',
    data: file,
    header: {
      'Content-Type': 'multipart/form-data'
    }
  }),

  // 获取简历模板
  getTemplates: () => request<ResumeTemplate[]>({
    url: '/api/v1/resume/templates',
    method: 'GET'
  }),

  // 复制简历
  duplicate: (id: string, name: string) => request<Resume>({
    url: `/api/v1/resume/duplicate/${id}`,
    method: 'POST',
    data: { name }
  }),

  // 导出简历
  export: (id: string, format: 'pdf' | 'docx') => request<{ url: string }>({
    url: `/api/v1/resume/export/${id}`,
    method: 'POST',
    data: { format }
  })
}

// src/services/userService.ts
import { request } from '../api/request'
import { User, UserForm, LoginForm, RegisterForm } from '../types/user'

export const userService = {
  // 用户登录
  login: (data: LoginForm) => request<{ user: User; token: string }>({
    url: '/api/v2/auth/login',
    method: 'POST',
    data
  }),
  
  // 用户注册
  register: (data: RegisterForm) => request<{ user: User; token: string }>({
    url: '/api/v2/auth/register',
    method: 'POST',
    data
  }),
  
  // 获取用户信息
  getInfo: () => request<User>({
    url: '/api/v2/user/info',
    method: 'GET'
  }),
  
  // 更新用户信息
  updateInfo: (data: UserForm) => request<User>({
    url: '/api/v2/user/update',
    method: 'PUT',
    data
  }),
  
  // 修改密码
  changePassword: (data: { oldPassword: string; newPassword: string }) => request<boolean>({
    url: '/api/v2/user/change-password',
    method: 'PUT',
    data
  }),

  // 发送验证码
  sendCode: (phone: string) => request<boolean>({
    url: '/api/v2/auth/send-code',
    method: 'POST',
    data: { phone }
  }),

  // 微信登录
  wechatLogin: (code: string) => request<{ user: User; token: string }>({
    url: '/api/v2/auth/wechat-login',
    method: 'POST',
    data: { code }
  }),

  // 退出登录
  logout: () => request<boolean>({
    url: '/api/v2/auth/logout',
    method: 'POST'
  })
}

// src/services/jobService.ts
import { request } from '../api/request'
import { Job, JobListParams, JobSearchParams, JobApplyForm } from '../types/job'

export const jobService = {
  // 获取职位列表
  getList: (params?: JobListParams) => request<{ jobs: Job[]; total: number }>({
    url: '/api/v2/jobs',
    method: 'GET',
    data: params
  }),
  
  // 获取职位详情
  getDetail: (id: string) => request<Job>({
    url: `/api/v2/jobs/${id}`,
    method: 'GET'
  }),
  
  // 搜索职位
  search: (params: JobSearchParams) => request<{ jobs: Job[]; total: number }>({
    url: '/api/v2/jobs/search',
    method: 'GET',
    data: params
  }),
  
  // 申请职位
  apply: (data: JobApplyForm) => request<{ applicationId: string }>({
    url: '/api/v2/jobs/apply',
    method: 'POST',
    data
  }),

  // 收藏职位
  favorite: (jobId: string) => request<boolean>({
    url: `/api/v2/jobs/${jobId}/favorite`,
    method: 'POST'
  }),

  // 取消收藏
  unfavorite: (jobId: string) => request<boolean>({
    url: `/api/v2/jobs/${jobId}/favorite`,
    method: 'DELETE'
  }),

  // 获取收藏列表
  getFavorites: () => request<Job[]>({
    url: '/api/v2/jobs/favorites',
    method: 'GET'
  }),

  // 获取申请记录
  getApplications: () => request<JobApplication[]>({
    url: '/api/v2/jobs/applications',
    method: 'GET'
  })
}

// src/services/aiService.ts
import { request } from '../api/request'
import { ChatMessage, ResumeAnalysis, VectorSearch } from '../types/ai'

export const aiService = {
  // 简历分析
  analyzeResume: (resumeId: string) => request<ResumeAnalysis>({
    url: '/api/v1/analyze/resume',
    method: 'POST',
    data: { resumeId }
  }),
  
  // AI聊天
  chat: (message: string, history?: ChatMessage[]) => request<ChatMessage>({
    url: '/api/v1/chat/aiChat',
    method: 'POST',
    data: { message, history }
  }),
  
  // 获取简历向量
  getVectors: (resumeId: string) => request<number[]>({
    url: `/api/v1/vectors/${resumeId}`,
    method: 'GET'
  }),
  
  // 搜索相似简历
  searchSimilar: (data: VectorSearch) => request<Resume[]>({
    url: '/api/v1/vectors/search',
    method: 'POST',
    data
  }),

  // 智能推荐职位
  recommendJobs: (resumeId: string) => request<Job[]>({
    url: '/api/v1/ai/recommend-jobs',
    method: 'POST',
    data: { resumeId }
  }),

  // 简历优化建议
  getOptimizationSuggestions: (resumeId: string) => request<OptimizationSuggestion[]>({
    url: '/api/v1/ai/optimization-suggestions',
    method: 'POST',
    data: { resumeId }
  }),

  // 技能匹配分析
  analyzeSkillMatch: (resumeId: string, jobId: string) => request<SkillMatchAnalysis>({
    url: '/api/v1/ai/skill-match',
    method: 'POST',
    data: { resumeId, jobId }
  })
}

// src/services/statisticsService.ts
import { request } from '../api/request'
import { MarketData, PersonalData, EnterpriseData } from '../types/statistics'

export const statisticsService = {
  // 获取市场数据
  getMarketData: () => request<MarketData>({
    url: '/api/v1/statistics/market',
    method: 'GET'
  }),
  
  // 获取个人数据
  getPersonalData: () => request<PersonalData>({
    url: '/api/v1/statistics/personal',
    method: 'GET'
  }),
  
  // 获取企业数据
  getEnterpriseData: () => request<EnterpriseData>({
    url: '/api/v1/statistics/enterprise',
    method: 'GET'
  }),

  // 获取简历统计数据
  getResumeStats: () => request<ResumeStats>({
    url: '/api/v1/statistics/resume',
    method: 'GET'
  }),

  // 获取职位申请统计
  getApplicationStats: () => request<ApplicationStats>({
    url: '/api/v1/statistics/applications',
    method: 'GET'
  }),

  // 获取行业趋势数据
  getIndustryTrends: (industry?: string) => request<IndustryTrend[]>({
    url: '/api/v1/statistics/industry-trends',
    method: 'GET',
    data: { industry }
  })
}
```

#### 3.2.1 服务层使用示例

```typescript
// 在页面中使用业务服务
import { resumeService, userService, jobService, aiService } from '@/services'

// 简历管理页面
const ResumePage = () => {
  const [resumes, setResumes] = useState<Resume[]>([])
  const [loading, setLoading] = useState(false)

  // 加载简历列表
  const loadResumes = async () => {
    setLoading(true)
    try {
      const resumeList = await resumeService.getList({ page: 1, size: 10 })
      setResumes(resumeList)
    } catch (error) {
      console.error('加载简历列表失败:', error)
    } finally {
      setLoading(false)
    }
  }

  // 创建简历
  const handleCreateResume = async (formData: ResumeForm) => {
    try {
      const newResume = await resumeService.create(formData)
      setResumes(prev => [newResume, ...prev])
      Taro.showToast({ title: '创建成功', icon: 'success' })
    } catch (error) {
      console.error('创建简历失败:', error)
    }
  }

  // 删除简历
  const handleDeleteResume = async (id: string) => {
    try {
      await resumeService.delete(id)
      setResumes(prev => prev.filter(resume => resume.id !== id))
      Taro.showToast({ title: '删除成功', icon: 'success' })
    } catch (error) {
      console.error('删除简历失败:', error)
    }
  }

  return (
    // 页面组件
  )
}

// 职位搜索页面
const JobSearchPage = () => {
  const [jobs, setJobs] = useState<Job[]>([])
  const [searchParams, setSearchParams] = useState<JobSearchParams>({})

  // 搜索职位
  const searchJobs = async (params: JobSearchParams) => {
    try {
      const result = await jobService.search(params)
      setJobs(result.jobs)
    } catch (error) {
      console.error('搜索职位失败:', error)
    }
  }

  // 申请职位
  const applyJob = async (jobId: string, resumeId: string) => {
    try {
      await jobService.apply({ jobId, resumeId })
      Taro.showToast({ title: '申请成功', icon: 'success' })
    } catch (error) {
      console.error('申请职位失败:', error)
    }
  }

  return (
    // 页面组件
  )
}

// AI助手页面
const AIPage = () => {
  const [messages, setMessages] = useState<ChatMessage[]>([])
  const [analyzing, setAnalyzing] = useState(false)

  // 发送消息
  const sendMessage = async (message: string) => {
    try {
      const response = await aiService.chat(message, messages)
      setMessages(prev => [...prev, { role: 'user', content: message }, response])
    } catch (error) {
      console.error('发送消息失败:', error)
    }
  }

  // 分析简历
  const analyzeResume = async (resumeId: string) => {
    setAnalyzing(true)
    try {
      const analysis = await aiService.analyzeResume(resumeId)
      // 处理分析结果
      console.log('简历分析结果:', analysis)
    } catch (error) {
      console.error('简历分析失败:', error)
    } finally {
      setAnalyzing(false)
    }
  }

  return (
    // 页面组件
  )
}
```

#### 3.2.2 服务层统一导出

```typescript
// src/services/index.ts
export { resumeService } from './resumeService'
export { userService } from './userService'
export { jobService } from './jobService'
export { aiService } from './aiService'
export { statisticsService } from './statisticsService'

// 统一的服务对象
export const services = {
  resume: resumeService,
  user: userService,
  job: jobService,
  ai: aiService,
  statistics: statisticsService
}

// 类型导出
export type {
  Resume,
  ResumeForm,
  ResumeListParams,
  User,
  UserForm,
  LoginForm,
  RegisterForm,
  Job,
  JobListParams,
  JobSearchParams,
  JobApplyForm,
  ChatMessage,
  ResumeAnalysis,
  VectorSearch,
  MarketData,
  PersonalData,
  EnterpriseData
} from '../types'
```

#### 3.2.3 服务层优势

1. **业务逻辑封装**：将API调用逻辑封装在服务层，页面组件只需关注UI逻辑
2. **类型安全**：完整的TypeScript类型定义，提供智能代码提示
3. **统一接口**：所有业务服务都使用相同的request函数，保证一致性
4. **易于测试**：服务层可以独立进行单元测试
5. **易于维护**：业务逻辑集中管理，便于修改和扩展
6. **复用性强**：服务层可以在不同页面和组件中复用

#### 3.3 跨平台UI组件库

```typescript
// src/components/ResumeCard/index.tsx
import React from 'react'
import { View, Text } from '@tarojs/components'
import { Resume } from '../../types/resume'
import './index.scss'

interface ResumeCardProps {
  resume: Resume
  onView: (id: string) => void
  onEdit: (id: string) => void
  onDelete: (id: string) => void
  showActions?: boolean
  variant?: 'default' | 'compact' | 'detailed'
}

export const ResumeCard: React.FC<ResumeCardProps> = ({ 
  resume, 
  onView, 
  onEdit, 
  onDelete,
  showActions = true,
  variant = 'default'
}) => {
  const cardClass = `resume-card resume-card--${variant}`
  
  return (
    <View className={cardClass}>
      <View className="resume-card__header">
        <Text className="resume-card__title">{resume.title}</Text>
        <View className="resume-card__status">
          <Text className={`resume-card__status-text resume-card__status-text--${resume.status}`}>
            {getStatusText(resume.status)}
          </Text>
        </View>
      </View>
      
      <View className="resume-card__content">
        <Text className="resume-card__desc">模板: {resume.templateName || '默认模板'}</Text>
        <Text className="resume-card__date">创建时间: {formatDate(resume.createdAt)}</Text>
        {variant === 'detailed' && (
          <Text className="resume-card__summary">{resume.summary}</Text>
        )}
      </View>
      
      {showActions && (
        <View className="resume-card__footer">
          <View 
            className="resume-card__btn resume-card__btn--primary" 
            onClick={() => onView(resume.id)}
          >
            查看
          </View>
          <View 
            className="resume-card__btn resume-card__btn--secondary" 
            onClick={() => onEdit(resume.id)}
          >
            编辑
          </View>
          <View 
            className="resume-card__btn resume-card__btn--danger" 
            onClick={() => onDelete(resume.id)}
          >
            删除
          </View>
        </View>
      )}
    </View>
  )
}

function getStatusText(status: string): string {
  const statusMap: Record<string, string> = {
    draft: '草稿',
    published: '已发布',
    archived: '已归档',
    reviewing: '审核中'
  }
  return statusMap[status] || '草稿'
}

function formatDate(date: string | Date): string {
  const d = new Date(date)
  return d.toLocaleDateString('zh-CN')
}
```

```typescript
// src/components/JobCard/index.tsx
import React from 'react'
import { View, Text, Image } from '@tarojs/components'
import { Job } from '../../types/job'
import './index.scss'

interface JobCardProps {
  job: Job
  onView: (id: string) => void
  onApply: (id: string) => void
  onFavorite: (id: string) => void
  isFavorite?: boolean
  showActions?: boolean
  variant?: 'default' | 'compact' | 'featured'
}

export const JobCard: React.FC<JobCardProps> = ({
  job,
  onView,
  onApply,
  onFavorite,
  isFavorite = false,
  showActions = true,
  variant = 'default'
}) => {
  const cardClass = `job-card job-card--${variant}`
  
  return (
    <View className={cardClass} onClick={() => onView(job.id)}>
      <View className="job-card__header">
        <View className="job-card__company">
          {job.companyLogo && (
            <Image 
              className="job-card__logo" 
              src={job.companyLogo} 
              mode="aspectFit"
            />
          )}
          <View className="job-card__info">
            <Text className="job-card__title">{job.title}</Text>
            <Text className="job-card__company-name">{job.company}</Text>
          </View>
        </View>
        <View 
          className={`job-card__favorite ${isFavorite ? 'job-card__favorite--active' : ''}`}
          onClick={(e) => {
            e.stopPropagation()
            onFavorite(job.id)
          }}
        >
          <Text className="job-card__favorite-icon">♥</Text>
        </View>
      </View>
      
      <View className="job-card__content">
        <View className="job-card__salary">
          <Text className="job-card__salary-text">{job.salary}</Text>
        </View>
        <View className="job-card__location">
          <Text className="job-card__location-text">{job.location}</Text>
        </View>
        <View className="job-card__tags">
          {job.tags?.slice(0, 3).map((tag, index) => (
            <Text key={index} className="job-card__tag">{tag}</Text>
          ))}
        </View>
      </View>
      
      {showActions && (
        <View className="job-card__footer">
          <View 
            className="job-card__btn job-card__btn--primary"
            onClick={(e) => {
              e.stopPropagation()
              onApply(job.id)
            }}
          >
            立即申请
          </View>
        </View>
      )}
    </View>
  )
}
```

```typescript
// src/components/StatisticsCard/index.tsx
import React from 'react'
import { View, Text } from '@tarojs/components'
import './index.scss'

interface StatisticsCardProps {
  title: string
  value: string | number
  unit?: string
  trend?: 'up' | 'down' | 'stable'
  trendValue?: string
  icon?: string
  color?: 'primary' | 'success' | 'warning' | 'danger'
  onClick?: () => void
}

export const StatisticsCard: React.FC<StatisticsCardProps> = ({
  title,
  value,
  unit = '',
  trend,
  trendValue,
  icon,
  color = 'primary',
  onClick
}) => {
  const cardClass = `statistics-card statistics-card--${color} ${onClick ? 'statistics-card--clickable' : ''}`
  
  return (
    <View className={cardClass} onClick={onClick}>
      <View className="statistics-card__header">
        <Text className="statistics-card__title">{title}</Text>
        {icon && (
          <Text className="statistics-card__icon">{icon}</Text>
        )}
      </View>
      
      <View className="statistics-card__content">
        <Text className="statistics-card__value">
          {value}
          {unit && <Text className="statistics-card__unit">{unit}</Text>}
        </Text>
        
        {trend && trendValue && (
          <View className={`statistics-card__trend statistics-card__trend--${trend}`}>
            <Text className="statistics-card__trend-icon">
              {trend === 'up' ? '↗' : trend === 'down' ? '↘' : '→'}
            </Text>
            <Text className="statistics-card__trend-value">{trendValue}</Text>
          </View>
        )}
      </View>
    </View>
  )
}
```

#### 3.3.1 组件库统一导出

```typescript
// src/components/index.ts
export { ResumeCard } from './ResumeCard'
export { JobCard } from './JobCard'
export { UserProfile } from './UserProfile'
export { ChatMessage } from './ChatMessage'
export { StatisticsCard } from './StatisticsCard'

// 基础组件
export { Button } from './Button'
export { Input } from './Input'
export { Modal } from './Modal'
export { Loading } from './Loading'
export { Empty } from './Empty'

// 布局组件
export { Container } from './Container'
export { Row } from './Row'
export { Col } from './Col'
export { Card } from './Card'
export { List } from './List'

// 业务组件
export { SearchBar } from './SearchBar'
export { FilterBar } from './FilterBar'
export { TabBar } from './TabBar'
export { NavigationBar } from './NavigationBar'
```

#### 3.3.2 组件库使用示例

```typescript
// 在页面中使用组件
import { ResumeCard, JobCard, UserProfile } from '@/components'

// 简历列表页面
const ResumeListPage = () => {
  const [resumes, setResumes] = useState<Resume[]>([])

  const handleViewResume = (id: string) => {
    Taro.navigateTo({ url: `/pages/resume/detail?id=${id}` })
  }

  const handleEditResume = (id: string) => {
    Taro.navigateTo({ url: `/pages/resume/edit?id=${id}` })
  }

  const handleDeleteResume = (id: string) => {
    Taro.showModal({
      title: '确认删除',
      content: '确定要删除这个简历吗？',
      success: (res) => {
        if (res.confirm) {
          resumeService.delete(id)
        }
      }
    })
  }

  return (
    <View className="resume-list">
      {resumes.map(resume => (
        <ResumeCard
          key={resume.id}
          resume={resume}
          onView={handleViewResume}
          onEdit={handleEditResume}
          onDelete={handleDeleteResume}
          variant="default"
        />
      ))}
    </View>
  )
}
```

#### 3.3.3 组件库优势

1. **跨平台兼容**：使用Taro组件，自动适配小程序和H5
2. **类型安全**：完整的TypeScript类型定义
3. **主题统一**：统一的样式规范和设计语言
4. **高度可配置**：支持多种变体和自定义选项
5. **易于维护**：组件化设计，便于修改和扩展
6. **性能优化**：合理的组件结构和样式优化
7. **无障碍支持**：符合可访问性标准

#### 3.4 平台特定功能适配

```typescript
// src/utils/platform.ts
import Taro from '@tarojs/taro'

// 平台检测
export const isWeapp = process.env.TARO_ENV === 'weapp'
export const isH5 = process.env.TARO_ENV === 'h5'
export const isRN = process.env.TARO_ENV === 'rn'
export const isSwan = process.env.TARO_ENV === 'swan'

// 获取当前平台信息
export const getPlatformInfo = () => {
  return {
    platform: process.env.TARO_ENV,
    isWeapp,
    isH5,
    isRN,
    isSwan,
    userAgent: isH5 ? navigator.userAgent : '',
    systemInfo: Taro.getSystemInfoSync()
  }
}

// 分享功能适配
export interface ShareOptions {
  title: string
  path?: string
  imageUrl?: string
  desc?: string
  type?: 'link' | 'image' | 'video'
}

export function shareContent(options: ShareOptions) {
  if (isWeapp) {
    // 小程序分享逻辑
    return {
      title: options.title,
      path: options.path || '/pages/index/index',
      imageUrl: options.imageUrl
    }
  } else if (isH5) {
    // Web端分享逻辑
    if (navigator.share) {
      // 使用Web Share API
      return navigator.share({
        title: options.title,
        text: options.desc,
        url: window.location.href
      })
    } else {
      // 降级到自定义分享弹窗
      return showCustomShareModal(options)
    }
  }
}

// 文件上传适配
export interface UploadOptions {
  filePath?: string
  file?: File
  url: string
  name?: string
  formData?: Record<string, any>
  header?: Record<string, string>
}

export async function uploadFile(options: UploadOptions) {
  if (isWeapp) {
    // 小程序上传
    return await Taro.uploadFile({
      url: options.url,
      filePath: options.filePath!,
      name: options.name || 'file',
      formData: options.formData,
      header: options.header
    })
  } else if (isH5) {
    // Web端上传
    if (!options.file) {
      throw new Error('Web端上传需要提供file对象')
    }
    
    const formData = new FormData()
    formData.append(options.name || 'file', options.file)
    
    // 添加额外的表单数据
    if (options.formData) {
      Object.keys(options.formData).forEach(key => {
        formData.append(key, options.formData![key])
      })
    }
    
    const response = await fetch(options.url, {
      method: 'POST',
      body: formData,
      headers: options.header
    })
    
    return {
      statusCode: response.status,
      data: await response.json()
    }
  }
}

// 存储适配
export const storage = {
  setItem: (key: string, value: any) => {
    if (isWeapp) {
      Taro.setStorageSync(key, value)
    } else if (isH5) {
      localStorage.setItem(key, JSON.stringify(value))
    }
  },
  
  getItem: (key: string) => {
    if (isWeapp) {
      return Taro.getStorageSync(key)
    } else if (isH5) {
      const value = localStorage.getItem(key)
      return value ? JSON.parse(value) : null
    }
  },
  
  removeItem: (key: string) => {
    if (isWeapp) {
      Taro.removeStorageSync(key)
    } else if (isH5) {
      localStorage.removeItem(key)
    }
  }
}

// 条件编译宏
export const platform = {
  isWeapp,
  isH5,
  isRN,
  isSwan,
  getPlatformInfo,
  shareContent,
  uploadFile,
  storage
}
```

#### 3.4.1 平台特定组件示例

```typescript
// src/components/ShareButton/index.tsx
import React from 'react'
import { View, Button } from '@tarojs/components'
import { platform } from '../../utils/platform'

interface ShareButtonProps {
  title: string
  path?: string
  imageUrl?: string
  desc?: string
  onSuccess?: () => void
  onFail?: (error: any) => void
}

export const ShareButton: React.FC<ShareButtonProps> = ({
  title,
  path,
  imageUrl,
  desc,
  onSuccess,
  onFail
}) => {
  const handleShare = async () => {
    try {
      if (platform.isWeapp) {
        // 小程序分享
        const shareData = platform.shareContent({
          title,
          path,
          imageUrl
        })
        console.log('小程序分享数据:', shareData)
        onSuccess?.()
      } else if (platform.isH5) {
        // Web端分享
        await platform.shareContent({
          title,
          desc,
          type: 'link'
        })
        onSuccess?.()
      }
    } catch (error) {
      onFail?.(error)
    }
  }

  return (
    <View className="share-button">
      {platform.isWeapp ? (
        <Button 
          className="share-button__btn"
          openType="share"
          onClick={handleShare}
        >
          分享
        </Button>
      ) : (
        <Button 
          className="share-button__btn"
          onClick={handleShare}
        >
          分享
        </Button>
      )}
    </View>
  )
}
```

#### 3.4.2 平台适配优势

1. **统一接口**：提供统一的API接口，隐藏平台差异
2. **自动适配**：根据运行环境自动选择对应的实现
3. **降级处理**：Web端不支持的功能提供降级方案
4. **类型安全**：完整的TypeScript类型定义
5. **易于维护**：平台特定逻辑集中管理
6. **扩展性强**：易于添加新平台支持

#### 3.5 统一状态管理

```typescript
// src/store/resumeStore.ts
import { create } from 'zustand'
import { persist } from 'zustand/middleware'
import { resumeService } from '../services/resumeService'
import { Resume, ResumeForm } from '../types/resume'
import { platform } from '../utils/platform'

interface ResumeState {
  resumes: Resume[]
  currentResume: Resume | null
  loading: boolean
  error: string | null
  lastFetchTime: number | null
  
  // 同步方法
  setResumes: (resumes: Resume[]) => void
  setCurrentResume: (resume: Resume | null) => void
  setLoading: (loading: boolean) => void
  setError: (error: string | null) => void
  clearError: () => void
  
  // 异步方法
  fetchResumes: (forceRefresh?: boolean) => Promise<void>
  fetchResumeDetail: (id: string) => Promise<void>
  createResume: (data: ResumeForm) => Promise<Resume | null>
  updateResume: (id: string, data: ResumeForm) => Promise<Resume | null>
  deleteResume: (id: string) => Promise<boolean>
  duplicateResume: (id: string, name: string) => Promise<Resume | null>
  
  // 工具方法
  getResumeById: (id: string) => Resume | undefined
  refreshResumes: () => Promise<void>
}

export const useResumeStore = create<ResumeState>()(
  persist(
    (set, get) => ({
      resumes: [],
      currentResume: null,
      loading: false,
      error: null,
      lastFetchTime: null,
      
      // 同步方法
      setResumes: (resumes) => set({ resumes }),
      setCurrentResume: (resume) => set({ currentResume: resume }),
      setLoading: (loading) => set({ loading }),
      setError: (error) => set({ error }),
      clearError: () => set({ error: null }),
      
      // 异步方法
      fetchResumes: async (forceRefresh = false) => {
        const { lastFetchTime, loading } = get()
        
        // 防止重复请求
        if (loading) return
        
        // 检查缓存时间（5分钟内不重复请求）
        const now = Date.now()
        if (!forceRefresh && lastFetchTime && (now - lastFetchTime) < 5 * 60 * 1000) {
          return
        }
        
        set({ loading: true, error: null })
        
        try {
          const response = await resumeService.getList()
          set({ 
            resumes: response, 
            loading: false, 
            lastFetchTime: now 
          })
        } catch (error) {
          set({ 
            error: error instanceof Error ? error.message : '获取简历列表失败', 
            loading: false 
          })
        }
      },
      
      fetchResumeDetail: async (id) => {
        set({ loading: true, error: null })
        
        try {
          const resume = await resumeService.getDetail(id)
          set({ 
            currentResume: resume, 
            loading: false 
          })
        } catch (error) {
          set({ 
            error: error instanceof Error ? error.message : '获取简历详情失败', 
            loading: false 
          })
        }
      },
      
      createResume: async (data) => {
        set({ loading: true, error: null })
        
        try {
          const newResume = await resumeService.create(data)
          
          // 更新本地状态
          const { resumes } = get()
          set({ 
            resumes: [newResume, ...resumes],
            currentResume: newResume,
            loading: false 
          })
          
          return newResume
        } catch (error) {
          set({ 
            error: error instanceof Error ? error.message : '创建简历失败', 
            loading: false 
          })
          return null
        }
      },
      
      updateResume: async (id, data) => {
        set({ loading: true, error: null })
        
        try {
          const updatedResume = await resumeService.update(id, data)
          
          // 更新本地状态
          const { resumes, currentResume } = get()
          const updatedResumes = resumes.map(resume => 
            resume.id === id ? updatedResume : resume
          )
          
          set({ 
            resumes: updatedResumes,
            currentResume: currentResume?.id === id ? updatedResume : currentResume,
            loading: false 
          })
          
          return updatedResume
        } catch (error) {
          set({ 
            error: error instanceof Error ? error.message : '更新简历失败', 
            loading: false 
          })
          return null
        }
      },
      
      deleteResume: async (id) => {
        set({ loading: true, error: null })
        
        try {
          await resumeService.delete(id)
          
          // 更新本地状态
          const { resumes, currentResume } = get()
          const filteredResumes = resumes.filter(resume => resume.id !== id)
          
          set({ 
            resumes: filteredResumes,
            currentResume: currentResume?.id === id ? null : currentResume,
            loading: false 
          })
          
          return true
        } catch (error) {
          set({ 
            error: error instanceof Error ? error.message : '删除简历失败', 
            loading: false 
          })
          return false
        }
      },
      
      duplicateResume: async (id, name) => {
        set({ loading: true, error: null })
        
        try {
          const duplicatedResume = await resumeService.duplicate(id, name)
          
          // 更新本地状态
          const { resumes } = get()
          set({ 
            resumes: [duplicatedResume, ...resumes],
            loading: false 
          })
          
          return duplicatedResume
        } catch (error) {
          set({ 
            error: error instanceof Error ? error.message : '复制简历失败', 
            loading: false 
          })
          return null
        }
      },
      
      // 工具方法
      getResumeById: (id) => {
        const { resumes } = get()
        return resumes.find(resume => resume.id === id)
      },
      
      refreshResumes: async () => {
        await get().fetchResumes(true)
      }
    }),
    {
      name: 'resume-storage',
      getStorage: () => ({
        getItem: (name: string) => {
          return platform.storage.getItem(name)
        },
        setItem: (name: string, value: string) => {
          platform.storage.setItem(name, value)
        },
        removeItem: (name: string) => {
          platform.storage.removeItem(name)
        }
      }),
      // 只持久化必要的数据
      partialize: (state) => ({
        resumes: state.resumes,
        lastFetchTime: state.lastFetchTime
      })
    }
  )
)
```

```typescript
// src/store/jobStore.ts
import { create } from 'zustand'
import { persist } from 'zustand/middleware'
import { jobService } from '../services/jobService'
import { Job, JobSearchParams } from '../types/job'
import { platform } from '../utils/platform'

interface JobState {
  jobs: Job[]
  favorites: Set<string>
  applications: string[]
  searchParams: JobSearchParams | null
  loading: boolean
  error: string | null
  lastFetchTime: number | null
  
  // 同步方法
  setJobs: (jobs: Job[]) => void
  setFavorites: (favorites: Set<string>) => void
  setApplications: (applications: string[]) => void
  setSearchParams: (params: JobSearchParams | null) => void
  setLoading: (loading: boolean) => void
  setError: (error: string | null) => void
  clearError: () => void
  
  // 异步方法
  fetchJobs: (params?: JobSearchParams, forceRefresh?: boolean) => Promise<void>
  searchJobs: (params: JobSearchParams) => Promise<void>
  fetchJobDetail: (id: string) => Promise<Job | null>
  applyJob: (jobId: string, resumeId: string) => Promise<boolean>
  favoriteJob: (jobId: string) => Promise<boolean>
  unfavoriteJob: (jobId: string) => Promise<boolean>
  fetchFavorites: () => Promise<void>
  fetchApplications: () => Promise<void>
  
  // 工具方法
  getJobById: (id: string) => Job | undefined
  isFavorite: (jobId: string) => boolean
  isApplied: (jobId: string) => boolean
  refreshJobs: () => Promise<void>
}

export const useJobStore = create<JobState>()(
  persist(
    (set, get) => ({
      jobs: [],
      favorites: new Set(),
      applications: [],
      searchParams: null,
      loading: false,
      error: null,
      lastFetchTime: null,
      
      // 同步方法
      setJobs: (jobs) => set({ jobs }),
      setFavorites: (favorites) => set({ favorites }),
      setApplications: (applications) => set({ applications }),
      setSearchParams: (params) => set({ searchParams: params }),
      setLoading: (loading) => set({ loading }),
      setError: (error) => set({ error }),
      clearError: () => set({ error: null }),
      
      // 异步方法
      fetchJobs: async (params, forceRefresh = false) => {
        const { lastFetchTime, loading } = get()
        
        if (loading) return
        
        const now = Date.now()
        if (!forceRefresh && lastFetchTime && (now - lastFetchTime) < 3 * 60 * 1000) {
          return
        }
        
        set({ loading: true, error: null })
        
        try {
          const response = await jobService.getList(params)
          set({ 
            jobs: response.jobs, 
            loading: false, 
            lastFetchTime: now 
          })
        } catch (error) {
          set({ 
            error: error instanceof Error ? error.message : '获取职位列表失败', 
            loading: false 
          })
        }
      },
      
      searchJobs: async (params) => {
        set({ loading: true, error: null, searchParams: params })
        
        try {
          const response = await jobService.search(params)
          set({ 
            jobs: response.jobs, 
            loading: false 
          })
        } catch (error) {
          set({ 
            error: error instanceof Error ? error.message : '搜索职位失败', 
            loading: false 
          })
        }
      },
      
      fetchJobDetail: async (id) => {
        set({ loading: true, error: null })
        
        try {
          const job = await jobService.getDetail(id)
          set({ loading: false })
          return job
        } catch (error) {
          set({ 
            error: error instanceof Error ? error.message : '获取职位详情失败', 
            loading: false 
          })
          return null
        }
      },
      
      applyJob: async (jobId, resumeId) => {
        set({ loading: true, error: null })
        
        try {
          await jobService.apply({ jobId, resumeId })
          
          // 更新本地状态
          const { applications } = get()
          set({ 
            applications: [...applications, jobId],
            loading: false 
          })
          
          return true
        } catch (error) {
          set({ 
            error: error instanceof Error ? error.message : '申请职位失败', 
            loading: false 
          })
          return false
        }
      },
      
      favoriteJob: async (jobId) => {
        try {
          await jobService.favorite(jobId)
          
          // 更新本地状态
          const { favorites } = get()
          const newFavorites = new Set(favorites)
          newFavorites.add(jobId)
          set({ favorites: newFavorites })
          
          return true
        } catch (error) {
          set({ 
            error: error instanceof Error ? error.message : '收藏职位失败' 
          })
          return false
        }
      },
      
      unfavoriteJob: async (jobId) => {
        try {
          await jobService.unfavorite(jobId)
          
          // 更新本地状态
          const { favorites } = get()
          const newFavorites = new Set(favorites)
          newFavorites.delete(jobId)
          set({ favorites: newFavorites })
          
          return true
        } catch (error) {
          set({ 
            error: error instanceof Error ? error.message : '取消收藏失败' 
          })
          return false
        }
      },
      
      fetchFavorites: async () => {
        set({ loading: true, error: null })
        
        try {
          const favorites = await jobService.getFavorites()
          const favoriteIds = new Set(favorites.map(job => job.id))
          set({ 
            favorites: favoriteIds,
            loading: false 
          })
        } catch (error) {
          set({ 
            error: error instanceof Error ? error.message : '获取收藏列表失败', 
            loading: false 
          })
        }
      },
      
      fetchApplications: async () => {
        set({ loading: true, error: null })
        
        try {
          const applications = await jobService.getApplications()
          const applicationIds = applications.map(app => app.jobId)
          set({ 
            applications: applicationIds,
            loading: false 
          })
        } catch (error) {
          set({ 
            error: error instanceof Error ? error.message : '获取申请记录失败', 
            loading: false 
          })
        }
      },
      
      // 工具方法
      getJobById: (id) => {
        const { jobs } = get()
        return jobs.find(job => job.id === id)
      },
      
      isFavorite: (jobId) => {
        const { favorites } = get()
        return favorites.has(jobId)
      },
      
      isApplied: (jobId) => {
        const { applications } = get()
        return applications.includes(jobId)
      },
      
      refreshJobs: async () => {
        await get().fetchJobs(undefined, true)
      }
    }),
    {
      name: 'job-storage',
      getStorage: () => ({
        getItem: (name: string) => {
          return platform.storage.getItem(name)
        },
        setItem: (name: string, value: string) => {
          platform.storage.setItem(name, value)
        },
        removeItem: (name: string) => {
          platform.storage.removeItem(name)
        }
      }),
      // 持久化用户相关数据
      partialize: (state) => ({
        favorites: Array.from(state.favorites),
        applications: state.applications,
        searchParams: state.searchParams
      })
    }
  )
)
```

```typescript
// src/store/authStore.ts
import { create } from 'zustand'
import { persist } from 'zustand/middleware'
import { userService } from '../services/userService'
import { User, LoginForm, RegisterForm } from '../types/user'
import { platform } from '../utils/platform'

interface AuthState {
  user: User | null
  token: string | null
  isAuthenticated: boolean
  loading: boolean
  error: string | null
  
  // 同步方法
  setUser: (user: User | null) => void
  setToken: (token: string | null) => void
  setLoading: (loading: boolean) => void
  setError: (error: string | null) => void
  clearError: () => void
  
  // 异步方法
  login: (data: LoginForm) => Promise<boolean>
  register: (data: RegisterForm) => Promise<boolean>
  logout: () => Promise<void>
  refreshUserInfo: () => Promise<void>
  updateUserInfo: (data: Partial<User>) => Promise<boolean>
  changePassword: (oldPassword: string, newPassword: string) => Promise<boolean>
  wechatLogin: (code: string) => Promise<boolean>
  
  // 工具方法
  checkAuth: () => boolean
  clearAuth: () => void
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set, get) => ({
      user: null,
      token: null,
      isAuthenticated: false,
      loading: false,
      error: null,
      
      // 同步方法
      setUser: (user) => set({ user, isAuthenticated: !!user }),
      setToken: (token) => set({ token }),
      setLoading: (loading) => set({ loading }),
      setError: (error) => set({ error }),
      clearError: () => set({ error: null }),
      
      // 异步方法
      login: async (data) => {
        set({ loading: true, error: null })
        
        try {
          const response = await userService.login(data)
          set({ 
            user: response.user,
            token: response.token,
            isAuthenticated: true,
            loading: false 
          })
          return true
        } catch (error) {
          set({ 
            error: error instanceof Error ? error.message : '登录失败', 
            loading: false 
          })
          return false
        }
      },
      
      register: async (data) => {
        set({ loading: true, error: null })
        
        try {
          const response = await userService.register(data)
          set({ 
            user: response.user,
            token: response.token,
            isAuthenticated: true,
            loading: false 
          })
          return true
        } catch (error) {
          set({ 
            error: error instanceof Error ? error.message : '注册失败', 
            loading: false 
          })
          return false
        }
      },
      
      logout: async () => {
        set({ loading: true, error: null })
        
        try {
          await userService.logout()
          set({ 
            user: null,
            token: null,
            isAuthenticated: false,
            loading: false 
          })
        } catch (error) {
          // 即使登出失败，也要清除本地状态
          set({ 
            user: null,
            token: null,
            isAuthenticated: false,
            loading: false 
          })
        }
      },
      
      refreshUserInfo: async () => {
        set({ loading: true, error: null })
        
        try {
          const user = await userService.getInfo()
          set({ 
            user,
            loading: false 
          })
        } catch (error) {
          set({ 
            error: error instanceof Error ? error.message : '获取用户信息失败', 
            loading: false 
          })
        }
      },
      
      updateUserInfo: async (data) => {
        set({ loading: true, error: null })
        
        try {
          const updatedUser = await userService.updateInfo(data)
          set({ 
            user: updatedUser,
            loading: false 
          })
          return true
        } catch (error) {
          set({ 
            error: error instanceof Error ? error.message : '更新用户信息失败', 
            loading: false 
          })
          return false
        }
      },
      
      changePassword: async (oldPassword, newPassword) => {
        set({ loading: true, error: null })
        
        try {
          await userService.changePassword({ oldPassword, newPassword })
          set({ loading: false })
          return true
        } catch (error) {
          set({ 
            error: error instanceof Error ? error.message : '修改密码失败', 
            loading: false 
          })
          return false
        }
      },
      
      wechatLogin: async (code) => {
        set({ loading: true, error: null })
        
        try {
          const response = await userService.wechatLogin(code)
          set({ 
            user: response.user,
            token: response.token,
            isAuthenticated: true,
            loading: false 
          })
          return true
        } catch (error) {
          set({ 
            error: error instanceof Error ? error.message : '微信登录失败', 
            loading: false 
          })
          return false
        }
      },
      
      // 工具方法
      checkAuth: () => {
        const { token, user } = get()
        return !!(token && user)
      },
      
      clearAuth: () => {
        set({ 
          user: null,
          token: null,
          isAuthenticated: false,
          error: null 
        })
      }
    }),
    {
      name: 'auth-storage',
      getStorage: () => ({
        getItem: (name: string) => {
          return platform.storage.getItem(name)
        },
        setItem: (name: string, value: string) => {
          platform.storage.setItem(name, value)
        },
        removeItem: (name: string) => {
          platform.storage.removeItem(name)
        }
      }),
      // 持久化认证信息
      partialize: (state) => ({
        user: state.user,
        token: state.token,
        isAuthenticated: state.isAuthenticated
      })
    }
  )
)
```

#### 3.5.1 状态管理统一导出

```typescript
// src/store/index.ts
export { useResumeStore } from './resumeStore'
export { useJobStore } from './jobStore'
export { useAuthStore } from './authStore'

// 组合Store Hook
export const useAppStore = () => {
  const auth = useAuthStore()
  const resume = useResumeStore()
  const job = useJobStore()
  
  return {
    auth,
    resume,
    job
  }
}
```

#### 3.5.2 状态管理使用示例

```typescript
// 在页面中使用状态管理
import { useResumeStore, useJobStore, useAuthStore } from '@/store'

const ResumeListPage = () => {
  const { 
    resumes, 
    loading, 
    error, 
    fetchResumes, 
    createResume, 
    deleteResume,
    clearError 
  } = useResumeStore()
  
  const { isAuthenticated } = useAuthStore()
  
  useEffect(() => {
    if (isAuthenticated) {
      fetchResumes()
    }
  }, [isAuthenticated, fetchResumes])
  
  const handleCreateResume = async (formData: ResumeForm) => {
    const success = await createResume(formData)
    if (success) {
      Taro.showToast({ title: '创建成功', icon: 'success' })
    }
  }
  
  const handleDeleteResume = async (id: string) => {
    const success = await deleteResume(id)
    if (success) {
      Taro.showToast({ title: '删除成功', icon: 'success' })
    }
  }
  
  return (
    <View className="resume-list">
      {loading && <Loading />}
      {error && (
        <View className="error-message">
          <Text>{error}</Text>
          <Button onClick={clearError}>重试</Button>
        </View>
      )}
      {resumes.map(resume => (
        <ResumeCard
          key={resume.id}
          resume={resume}
          onEdit={() => Taro.navigateTo({ url: `/pages/resume/edit?id=${resume.id}` })}
          onDelete={() => handleDeleteResume(resume.id)}
        />
      ))}
    </View>
  )
}
```

#### 3.5.3 状态管理优势

1. **统一接口**：所有Store都使用相同的模式和方法
2. **自动持久化**：支持跨端数据持久化
3. **类型安全**：完整的TypeScript类型定义
4. **性能优化**：智能缓存和防重复请求
5. **错误处理**：统一的错误处理机制
6. **易于测试**：Store可以独立进行单元测试
7. **跨端兼容**：使用平台适配的存储方案

interface User {
  id: string
  username: string
  email: string
  avatar?: string
  role: string
}

interface AuthState {
  user: User | null
  token: string | null
  isAuthenticated: boolean
  login: (user: User, token: string) => void
  logout: () => void
  updateUser: (user: Partial<User>) => void
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set, get) => ({
      user: null,
      token: null,
      isAuthenticated: false,

      login: (user: User, token: string) => {
        set({
          user,
          token,
          isAuthenticated: true
        })
      },

      logout: () => {
        set({
          user: null,
          token: null,
          isAuthenticated: false
        })
      },

      updateUser: (userData: Partial<User>) => {
        const currentUser = get().user
        if (currentUser) {
          set({
            user: { ...currentUser, ...userData }
          })
        }
      }
    }),
    {
      name: 'auth-storage',
      getStorage: () => ({
        getItem: (name: string) => {
          return Taro.getStorageSync(name)
        },
        setItem: (name: string, value: string) => {
          Taro.setStorageSync(name, value)
        },
        removeItem: (name: string) => {
          Taro.removeStorageSync(name)
        }
      })
    }
  )
)
```

#### 3.3 跨端适配组件

```typescript
// components/common/Button.tsx
import { View, Button as TaroButton } from '@tarojs/components'
import { ButtonProps } from '@tarojs/components/types/Button'
import classNames from 'classnames'
import './Button.scss'

interface CustomButtonProps extends ButtonProps {
  variant?: 'primary' | 'secondary' | 'outline'
  size?: 'small' | 'medium' | 'large'
  loading?: boolean
  disabled?: boolean
  children: React.ReactNode
  onClick?: () => void
}

export const Button: React.FC<CustomButtonProps> = ({
  variant = 'primary',
  size = 'medium',
  loading = false,
  disabled = false,
  children,
  onClick,
  className,
  ...props
}) => {
  const buttonClass = classNames(
    'custom-button',
    `custom-button--${variant}`,
    `custom-button--${size}`,
    {
      'custom-button--loading': loading,
      'custom-button--disabled': disabled
    },
    className
  )

  return (
    <TaroButton
      className={buttonClass}
      disabled={disabled || loading}
      onClick={onClick}
      {...props}
    >
      {loading && <View className="custom-button__loading" />}
      <View className="custom-button__content">{children}</View>
    </TaroButton>
  )
}
```

### 4. 迁移实施计划

#### 阶段1：环境搭建 (1周)

1. **安装Taro CLI**
   ```bash
   npm install -g @tarojs/cli
   ```

2. **创建Taro项目**
   ```bash
   taro init jobfirst-unified
   cd jobfirst-unified
   ```

3. **配置开发环境**
   ```bash
   # 安装依赖
   npm install
   
   # 安装额外依赖
   npm install zustand @tarojs/plugin-platform-weapp
   npm install -D @types/node typescript
   ```

4. **配置Taro**
   ```typescript
   // config/index.ts
   export default {
     projectName: 'jobfirst-unified',
     date: '2024-1-1',
     designWidth: 750,
     deviceRatio: {
       640: 2.34 / 2,
       750: 1,
       828: 1.81 / 2
     },
     sourceRoot: 'src',
     outputRoot: 'dist',
     plugins: [
       '@tarojs/plugin-platform-weapp'
     ],
     defineConstants: {},
     alias: {},
     copy: {
       patterns: [],
       options: {}
     },
     framework: 'react',
     compiler: 'webpack5',
     cache: {
       enable: false
     },
     mini: {
       postcss: {
         pxtransform: {
           enable: true,
           config: {}
         },
         url: {
           enable: true,
           config: {
             limit: 1024
           }
         },
         cssModules: {
           enable: false,
           config: {
             namingPattern: 'module',
             generateScopedName: '[name]__[local]___[hash:base64:5]'
           }
         }
       }
     },
     h5: {
       publicPath: '/',
       staticDirectory: 'static',
       postcss: {
         autoprefixer: {
           enable: true,
           config: {}
         },
         cssModules: {
           enable: false,
           config: {
             namingPattern: 'module',
             generateScopedName: '[name]__[local]___[hash:base64:5]'
           }
         }
       }
     }
   }
   ```

#### 阶段2：核心功能迁移 (2-3周)

1. **用户认证模块**
   - 登录/注册页面
   - JWT Token管理
   - 用户信息管理

2. **简历管理模块**
   - 简历列表页面
   - 简历创建/编辑
   - 文件上传功能

3. **职位搜索模块**
   - 职位列表页面
   - 职位详情页面
   - 搜索和筛选功能

#### 阶段3：高级功能迁移 (2周)

1. **AI助手模块**
   - 聊天界面
   - 简历分析功能
   - 智能推荐

2. **数据分析模块**
   - 统计图表
   - 数据可视化
   - 报表生成

#### 阶段4：优化和测试 (1-2周)

1. **性能优化**
   - 代码分割
   - 懒加载
   - 缓存策略

2. **兼容性测试**
   - 微信小程序测试
   - H5端测试
   - 跨端功能验证

3. **用户体验优化**
   - 界面适配
   - 交互优化
   - 错误处理

### 5. 后端适配方案

#### 5.1 API标准化

```go
// 统一响应格式
type ApiResponse struct {
    Code    int         `json:"code"`
    Message string      `json:"message"`
    Data    interface{} `json:"data"`
    Meta    *Meta       `json:"meta,omitempty"`
}

type Meta struct {
    Pagination *Pagination `json:"pagination,omitempty"`
    Timestamp  int64       `json:"timestamp"`
    Version    string      `json:"version"`
}

// 统一错误处理
func ErrorResponse(code int, message string) gin.H {
    return gin.H{
        "code":    code,
        "message": message,
        "data":    nil,
        "meta": gin.H{
            "timestamp": time.Now().Unix(),
            "version":   "v2",
        },
    }
}
```

#### 5.2 跨端认证支持

```go
// 增强JWT Claims
type JWTClaims struct {
    UserID     string `json:"user_id"`
    TenantType string `json:"tenant_type"`
    Role       string `json:"role"`
    Platform   string `json:"platform"` // miniprogram/web
    ExpiresAt  int64  `json:"exp"`
}

// 统一认证中间件
func AuthMiddleware() gin.HandlerFunc {
    return func(c *gin.Context) {
        token := extractToken(c) // 支持多种方式获取token
        
        claims, err := validateToken(token)
        if err != nil {
            c.JSON(401, ErrorResponse(401, "Unauthorized"))
            c.Abort()
            return
        }
        
        c.Set("user", claims)
        c.Next()
    }
}
```

### 6. 预期收益

#### 开发效率提升
- **代码复用率**：从30%提升到80%
- **开发时间**：新功能开发时间减少50%
- **维护成本**：降低60%

#### 系统稳定性提升
- **API一致性**：统一的错误处理和响应格式
- **测试覆盖**：统一的测试策略
- **监控统一**：统一的日志和监控

#### 用户体验改善
- **功能同步**：新功能在所有端同时上线
- **数据一致性**：跨端数据实时同步
- **性能优化**：统一的性能优化策略

### 7. 风险评估与应对

#### 技术风险
- **Taro版本兼容性**：选择稳定版本，充分测试
- **平台差异**：建立完善的适配层
- **性能问题**：优化打包体积和运行时性能

#### 业务风险
- **功能缺失**：确保所有现有功能都能正常迁移
- **用户体验**：保持或提升现有用户体验
- **数据安全**：确保跨端数据安全

#### 应对策略
- **分阶段迁移**：逐步迁移，降低风险
- **充分测试**：每个阶段都要进行充分测试
- **回滚方案**：保留原有代码，确保可以快速回滚

### 8. 实施时间表

| 阶段 | 时间 | 主要任务 | 交付物 | 状态 |
|------|------|----------|--------|------|
| 阶段1 | 第1周 | 环境搭建 | Taro项目框架 | ✅ 已完成 |
| 阶段2 | 第2-4周 | 核心功能迁移 | 用户认证、简历管理、职位搜索 | ✅ 已完成 |
| 阶段3 | 第5-6周 | 高级功能迁移 | AI助手、数据分析 | ✅ 已完成 |
| 阶段4 | 第7-8周 | 优化和测试 | 完整的产品版本 | ✅ 已完成 |

### 8.1 当前实施状态 (2025年1月)

#### ✅ 已完成的功能模块

1. **项目框架搭建**
   - Taro 4.1.6 + React 18 + TypeScript
   - 完整的项目结构和配置
   - 微信小程序和H5双端支持

2. **核心功能实现**
   - ✅ 用户认证系统（登录、注册、用户管理）
   - ✅ 简历管理系统（创建、编辑、删除、列表）
   - ✅ 职位搜索系统（职位列表、详情、申请）
   - ✅ AI助手功能（聊天、简历分析）
   - ✅ 数据分析模块（统计图表、个人数据）

3. **技术架构完善**
   - ✅ 统一API服务层（request.ts）
   - ✅ 状态管理（Zustand）
   - ✅ 组件库（UI组件、业务组件）
   - ✅ 类型定义（完整的TypeScript类型）
   - ✅ 平台适配（跨端兼容）

4. **页面结构完整**
   - ✅ 首页（搜索、轮播图、快捷功能）
   - ✅ 登录/注册页面
   - ✅ 简历管理页面（列表、创建、编辑、详情）
   - ✅ 职位搜索页面
   - ✅ AI助手页面
   - ✅ 个人中心页面
   - ✅ 数据分析页面
   - ✅ 系统设置页面
   - ✅ 积分系统页面
   - ✅ 文件管理页面

5. **构建和部署**
   - ✅ 微信小程序构建成功
   - ✅ H5端构建支持
   - ✅ 配置文件自动生成
   - ✅ 微信开发者工具兼容

6. **热加载开发环境**
   - ✅ API Gateway: air热加载配置完成
   - ✅ User Service: air热加载配置完成
   - ✅ Resume Service: air热加载配置完成
   - ✅ AI Service: Sanic热加载配置完成
   - ✅ 前端: Taro HMR支持
   - ✅ 统一开发环境启动脚本 (`scripts/start-dev-environment.sh`)

#### ⚠️ 需要完善的部分

1. **微服务集成**
   - 后端微服务未启动（需要启动API网关、用户服务、简历服务、AI服务）
   - 数据库连接正常，包含5个测试用户
   - Consul服务发现正常运行

2. **功能测试**
   - 需要启动后端服务进行端到端测试
   - API接口集成测试
   - 跨端功能验证

3. **性能优化**
   - CSS冲突警告（不影响功能）
   - 构建体积优化
   - 运行时性能调优

### 8.2 热加载开发环境使用指南

#### 快速启动开发环境

```bash
# 启动完整开发环境 (数据库 + 后端 + 前端，支持热加载)
./scripts/start-dev-environment.sh start

# 仅启动后端服务 (数据库 + 微服务，支持热加载)
./scripts/start-dev-environment.sh backend

# 仅启动前端开发服务器
./scripts/start-dev-environment.sh frontend
```

#### 热加载特性

1. **Go服务热加载 (Air)**
   - API Gateway: 修改Go代码自动重启
   - User Service: 修改Go代码自动重启
   - Resume Service: 修改Go代码自动重启

2. **Python服务热加载 (Sanic)**
   - AI Service: 修改Python代码自动重启

3. **前端热加载 (Taro HMR)**
   - 修改React组件自动刷新
   - 修改样式自动更新
   - 修改TypeScript代码自动编译

#### 开发效率提升

- **代码修改即时生效**: 无需手动重启服务
- **实时错误反馈**: 编译错误和运行时错误实时显示
- **统一开发环境**: 团队成员使用相同的开发环境
- **快速调试**: 支持断点调试和日志输出

### 9. 总结

采用Taro统一开发方案将显著提升JobFirst项目的开发效率和维护性：

1. **技术优势**：一套代码，多端运行，减少重复开发
2. **维护优势**：统一的代码库，简化维护和更新
3. **扩展优势**：易于扩展到其他平台（支付宝小程序、百度小程序等）
4. **团队优势**：统一的开发流程，提高团队协作效率

通过合理的迁移计划和充分的测试验证，可以确保项目的平稳过渡和功能完整性。

## ❓ 常见问题解答

### Q1: Taro前端架构与后端API的关系是什么？

**A:** Taro前端架构是前端应用架构，通过API调用与后端交互，具体关系如下：

```
┌─────────────────────────────────────────────────────────────┐
│                    Taro统一前端架构                          │
├─────────────────────────────────────────────────────────────┤
│  src/                                                      │
│  ├── services/          ←→ 后端API接口层                    │
│  │   ├── auth.ts       ←→ /api/v2/auth/*                   │
│  │   ├── user.ts       ←→ /api/v2/user/*                   │
│  │   ├── resume.ts     ←→ /api/v1/resume/*                 │
│  │   ├── job.ts        ←→ /api/v2/jobs/*                   │
│  │   └── ai.ts         ←→ /api/v1/ai/*                     │
│  ├── stores/           ←→ 状态管理 + API调用                │
│  ├── components/       ←→ UI组件库                          │
│  └── pages/            ←→ 页面组件                          │
├─────────────────────────────────────────────────────────────┤
│  编译输出                                                  │
│  ├── 微信小程序 (dist/weapp)                               │
│  └── H5 Web端 (dist/h5)                                   │
└─────────────────────────────────────────────────────────────┘
```

**与后端微服务的对应关系：**
```
┌─────────────────────────────────────────────────────────────┐
│                   后端微服务架构                             │
├─────────────────────────────────────────────────────────────┤
│  User Service (Port 8001)     ←→ 前端 services/auth.ts     │
│  Resume Service (Port 8002)   ←→ 前端 services/resume.ts   │
│  AI Service (Port 8206)       ←→ 前端 services/ai.ts       │
│  API Gateway (Port 8080)      ←→ 前端统一入口              │
└─────────────────────────────────────────────────────────────┘
```

### Q2: 每个组件目录的具体作用是什么？

**A:** 各组件目录的详细功能解析：

#### **services/ 目录 - API集成层**
```typescript
// src/services/resumeService.ts
// 这是前端对后端API的封装，不是API管理
export const resumeService = {
  // 调用后端 /api/v1/resume/list
  getList: () => request<Resume[]>({
    url: '/api/v1/resume/list',
    method: 'GET'
  }),
  
  // 调用后端 /api/v1/resume/create  
  create: (data: ResumeForm) => request<Resume>({
    url: '/api/v1/resume/create',
    method: 'POST',
    data
  })
}
```

**作用**：
- ✅ **API集成**：封装后端API调用
- ✅ **类型安全**：提供TypeScript类型定义
- ✅ **错误处理**：统一处理API错误
- ❌ **不是API管理**：不管理后端API定义

#### **stores/ 目录 - 状态管理 + API调用**
```typescript
// src/stores/resumeStore.ts
export const useResumeStore = create<ResumeState>()(
  (set, get) => ({
    // 状态
    resumes: [],
    loading: false,
    error: null,
    
    // 调用API服务
    fetchResumes: async () => {
      set({ loading: true })
      try {
        const response = await resumeService.getList() // ← 调用API服务
        set({ resumes: response, loading: false })
      } catch (error) {
        set({ error: error.message, loading: false })
      }
    }
  })
)
```

**作用**：
- ✅ **状态管理**：管理前端应用状态
- ✅ **API调用**：通过services调用后端API
- ✅ **数据缓存**：缓存API返回的数据
- ❌ **不是API管理**：不管理后端API

#### **components/ 目录 - UI组件库**
```typescript
// src/components/ResumeCard/index.tsx
export const ResumeCard: React.FC<ResumeCardProps> = ({ 
  resume, 
  onView, 
  onEdit, 
  onDelete 
}) => {
  return (
    <View className="resume-card">
      <Text className="resume-card__title">{resume.title}</Text>
      <Button onClick={() => onEdit(resume.id)}>编辑</Button>
    </View>
  )
}
```

**作用**：
- ✅ **UI展示**：展示数据
- ✅ **用户交互**：处理用户操作
- ✅ **组件复用**：跨页面复用
- ❌ **不直接调用API**：通过props接收数据和回调

### Q3: Gin框架在前端开发中的角色是什么？

**A:** Gin框架是后端API服务提供者，不直接服务前端页面：

#### **Gin框架的实际作用**
```go
// 后端 - Gin框架提供API服务
func main() {
    router := gin.Default()
    
    // API路由定义
    api := router.Group("/api/v1")
    {
        api.GET("/resume/list", getResumeList)      // ← 前端调用
        api.POST("/resume/create", createResume)    // ← 前端调用
        api.PUT("/resume/update/:id", updateResume) // ← 前端调用
    }
    
    router.Run(":8002")
}
```

```typescript
// 前端 - Taro调用后端API
// src/services/resumeService.ts
export const resumeService = {
  getList: () => request<Resume[]>({
    url: '/api/v1/resume/list',    // ← 调用后端Gin API
    method: 'GET'
  }),
  
  create: (data: ResumeForm) => request<Resume>({
    url: '/api/v1/resume/create',  // ← 调用后端Gin API
    method: 'POST',
    data
  })
}
```

#### **Gin框架的作用**
- ✅ **后端API服务**：提供RESTful API接口
- ✅ **路由管理**：定义API路由和处理器
- ✅ **中间件支持**：认证、日志、CORS等
- ✅ **JSON响应**：返回JSON格式数据

#### **Gin不直接服务前端页面**
```go
// Gin提供API服务，不直接服务HTML页面
router.GET("/api/v1/resume/list", func(c *gin.Context) {
    // 返回JSON数据，不是HTML页面
    c.JSON(200, gin.H{
        "code": 200,
        "data": resumes,
    })
})

// Taro编译后的前端页面由Web服务器（如Nginx）服务
// 前端页面通过fetch/axios调用Gin API获取数据
```

### Q4: 完整的调用链路是怎样的？

**A:** 数据流向和调用链路：

#### **数据流向**
```
用户操作 → 组件事件 → Store方法 → Service API → 后端Gin API → 数据库
    ↓           ↓          ↓           ↓            ↓
  UI交互    状态更新    API调用    网络请求    数据存储
```

#### **具体示例**
```typescript
// 1. 用户在页面中点击"创建简历"
const ResumeCreatePage = () => {
  const { createResume } = useResumeStore() // ← 从Store获取方法
  
  const handleSubmit = async (formData: ResumeForm) => {
    await createResume(formData) // ← 调用Store方法
  }
  
  return <ResumeForm onSubmit={handleSubmit} />
}

// 2. Store调用Service
// src/stores/resumeStore.ts
createResume: async (data) => {
  const newResume = await resumeService.create(data) // ← 调用Service
  // 更新本地状态...
}

// 3. Service调用后端API
// src/services/resumeService.ts
create: (data: ResumeForm) => request<Resume>({
  url: '/api/v1/resume/create', // ← 调用后端Gin API
  method: 'POST',
  data
})

// 4. 后端Gin处理请求
// backend/internal/resume/main.go
func createResume(c *gin.Context) {
  // 处理业务逻辑
  // 保存到数据库
  c.JSON(200, gin.H{"data": resume})
}
```

### Q5: 生产环境如何部署？

**A:** 生产环境部署架构：

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Nginx/CDN     │    │   Taro H5       │    │   Gin API       │
│   (静态资源)     │    │   (前端应用)     │    │   (后端服务)     │
│   Port: 80/443  │    │   Port: 3000    │    │   Port: 8080    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │   数据库/缓存    │
                    │   MySQL/Redis   │
                    └─────────────────┘
```

**部署说明**：
1. **Nginx/CDN**：服务静态资源（HTML、CSS、JS）
2. **Taro H5**：编译后的前端应用
3. **Gin API**：后端微服务API
4. **数据库**：MySQL存储业务数据，Redis缓存

### Q6: 这个架构的核心优势是什么？

**A:** 核心优势总结：

1. **前后端分离**：前端专注于用户界面和交互，后端专注于业务逻辑和数据管理
2. **统一技术栈**：一套代码支持多端，减少重复开发
3. **类型安全**：完整的TypeScript类型定义，提供智能代码提示
4. **统一接口**：所有业务服务都使用相同的request函数，保证一致性
5. **易于维护**：业务逻辑集中管理，便于修改和扩展
6. **跨端兼容**：使用平台适配的存储方案和组件库
7. **性能优化**：智能缓存、防重复请求、代码分割等

### Q7: 如何理解"不是API管理"这个概念？

**A:** 重要概念澄清：

- **前端services/目录**：是API的**消费者**，封装对后端API的调用
- **后端Gin框架**：是API的**提供者**，定义和管理API接口
- **API管理**：通常指API网关、API文档、API版本控制等后端服务

**具体区别**：
```typescript
// 前端 - API消费者（调用方）
export const resumeService = {
  getList: () => request<Resume[]>({
    url: '/api/v1/resume/list',  // ← 调用后端定义的API
    method: 'GET'
  })
}

// 后端 - API提供者（定义方）
func main() {
  router.GET("/api/v1/resume/list", getResumeList) // ← 定义API接口
}
```

前端不管理API的定义，只负责调用和封装。
