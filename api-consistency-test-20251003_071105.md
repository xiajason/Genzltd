# API数据一致性测试报告

**测试时间**: 2025-10-03 07:11:05
**测试版本**: v1.0
**数据源**: api-consistency-test-20251003_071105.json

## 📊 测试总结

- **测试环境数**: 3
- **测试端点数**: 5
- **比较次数**: 3
- **一致性得分**: 0.0%
- **平均响应时间**: 0.016秒

## ⚠️ 发现的问题

- local_vs_tencent - /api/health: 状态码不一致: 500 vs 404
- local_vs_tencent - /api/health: 响应数据不一致
- local_vs_tencent - /api/trpc/daoConfig.getDAOTypes: 状态码不一致: 500 vs 404
- local_vs_tencent - /api/trpc/daoConfig.getDAOTypes: 响应数据不一致
- local_vs_tencent - /api/users: 状态码不一致: 500 vs 404
- local_vs_tencent - /api/users: 响应数据不一致
- local_vs_tencent - /api/dao/configs: 状态码不一致: 500 vs 404
- local_vs_tencent - /api/dao/configs: 响应数据不一致
- local_vs_tencent - /api/dao/settings: 状态码不一致: 500 vs 404
- local_vs_tencent - /api/dao/settings: 响应数据不一致
- local_vs_alibaba - /api/health: 状态码不一致: 500 vs 404
- local_vs_alibaba - /api/health: 响应数据不一致
- local_vs_alibaba - /api/trpc/daoConfig.getDAOTypes: 状态码不一致: 500 vs 404
- local_vs_alibaba - /api/trpc/daoConfig.getDAOTypes: 响应数据不一致
- local_vs_alibaba - /api/users: 状态码不一致: 500 vs 404
- local_vs_alibaba - /api/users: 响应数据不一致
- local_vs_alibaba - /api/dao/configs: 状态码不一致: 500 vs 404
- local_vs_alibaba - /api/dao/configs: 响应数据不一致
- local_vs_alibaba - /api/dao/settings: 状态码不一致: 500 vs 404
- local_vs_alibaba - /api/dao/settings: 响应数据不一致
- tencent_vs_alibaba - /api/health: 响应数据不一致
- tencent_vs_alibaba - /api/trpc/daoConfig.getDAOTypes: 响应数据不一致
- tencent_vs_alibaba - /api/users: 响应数据不一致
- tencent_vs_alibaba - /api/dao/configs: 响应数据不一致
- tencent_vs_alibaba - /api/dao/settings: 响应数据不一致

## 💡 建议

- ❌ 存在严重API不一致，需要全面检查和修复

## 🌐 环境详情

### 本地开发环境

- **基础URL**: http://localhost:3000
- **成功请求**: 5/5
- **平均响应时间**: 0.003秒

### 腾讯云测试环境

- **基础URL**: http://101.33.251.158:9200
- **成功请求**: 5/5
- **平均响应时间**: 0.023秒

### 阿里云生产环境

- **基础URL**: http://47.115.168.107:9200
- **成功请求**: 5/5
- **平均响应时间**: 0.021秒

## 🔍 详细比较结果

### local_vs_tencent

- **一致性端点**: 0/5
- **不一致端点**: 5/5

#### /api/health ❌

- **描述**: 健康检查
- **数据一致性**: inconsistent
- **响应时间差异**: 0.021秒
- **问题**:
  - 状态码不一致: 500 vs 404
  - 响应数据不一致

#### /api/trpc/daoConfig.getDAOTypes ❌

- **描述**: DAO类型获取
- **数据一致性**: inconsistent
- **响应时间差异**: 0.019秒
- **问题**:
  - 状态码不一致: 500 vs 404
  - 响应数据不一致

#### /api/users ❌

- **描述**: 用户列表
- **数据一致性**: inconsistent
- **响应时间差异**: 0.020秒
- **问题**:
  - 状态码不一致: 500 vs 404
  - 响应数据不一致

#### /api/dao/configs ❌

- **描述**: DAO配置列表
- **数据一致性**: inconsistent
- **响应时间差异**: 0.020秒
- **问题**:
  - 状态码不一致: 500 vs 404
  - 响应数据不一致

#### /api/dao/settings ❌

- **描述**: DAO设置列表
- **数据一致性**: inconsistent
- **响应时间差异**: 0.022秒
- **问题**:
  - 状态码不一致: 500 vs 404
  - 响应数据不一致

### local_vs_alibaba

- **一致性端点**: 0/5
- **不一致端点**: 5/5

#### /api/health ❌

- **描述**: 健康检查
- **数据一致性**: inconsistent
- **响应时间差异**: 0.019秒
- **问题**:
  - 状态码不一致: 500 vs 404
  - 响应数据不一致

#### /api/trpc/daoConfig.getDAOTypes ❌

- **描述**: DAO类型获取
- **数据一致性**: inconsistent
- **响应时间差异**: 0.018秒
- **问题**:
  - 状态码不一致: 500 vs 404
  - 响应数据不一致

#### /api/users ❌

- **描述**: 用户列表
- **数据一致性**: inconsistent
- **响应时间差异**: 0.016秒
- **问题**:
  - 状态码不一致: 500 vs 404
  - 响应数据不一致

#### /api/dao/configs ❌

- **描述**: DAO配置列表
- **数据一致性**: inconsistent
- **响应时间差异**: 0.017秒
- **问题**:
  - 状态码不一致: 500 vs 404
  - 响应数据不一致

#### /api/dao/settings ❌

- **描述**: DAO设置列表
- **数据一致性**: inconsistent
- **响应时间差异**: 0.019秒
- **问题**:
  - 状态码不一致: 500 vs 404
  - 响应数据不一致

### tencent_vs_alibaba

- **一致性端点**: 0/5
- **不一致端点**: 5/5

#### /api/health ❌

- **描述**: 健康检查
- **数据一致性**: inconsistent
- **响应时间差异**: 0.002秒
- **问题**:
  - 响应数据不一致

#### /api/trpc/daoConfig.getDAOTypes ❌

- **描述**: DAO类型获取
- **数据一致性**: inconsistent
- **响应时间差异**: 0.002秒
- **问题**:
  - 响应数据不一致

#### /api/users ❌

- **描述**: 用户列表
- **数据一致性**: inconsistent
- **响应时间差异**: 0.004秒
- **问题**:
  - 响应数据不一致

#### /api/dao/configs ❌

- **描述**: DAO配置列表
- **数据一致性**: inconsistent
- **响应时间差异**: 0.003秒
- **问题**:
  - 响应数据不一致

#### /api/dao/settings ❌

- **描述**: DAO设置列表
- **数据一致性**: inconsistent
- **响应时间差异**: 0.003秒
- **问题**:
  - 响应数据不一致

---

**报告生成时间**: 2025-10-03 07:11:05
