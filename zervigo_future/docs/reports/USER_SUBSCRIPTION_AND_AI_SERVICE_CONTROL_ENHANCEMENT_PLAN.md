# 用户订阅和AI服务调用控制增强计划

**创建日期**: 2025年9月15日  
**基于报告**: Company服务和MinerU集成测试报告  
**目标用户**: szjason72 (试用用户)  
**计划类型**: 系统能力提升计划

---

## 📋 执行摘要

基于Company服务和MinerU集成测试报告的分析，我们发现系统已经具备了基础的订阅管理和AI服务调用控制机制，但还需要进一步完善以支持更精细的权限控制和成本管理。本计划旨在提升系统的订阅管理能力和AI服务调用控制机制。

### 🎯 核心目标

1. **完善用户订阅体系** - 支持试用、VIP、Pro等不同订阅模式
2. **实现AI服务调用限制** - 基于用户订阅状态控制AI服务调用次数
3. **建立成本控制机制** - 防止AI服务被滥用，控制运营成本
4. **优化用户体验** - 提供清晰的订阅状态和限制提示

---

## 🔍 当前系统分析

### 现有订阅机制

#### 用户订阅状态字段
```sql
-- 用户表订阅相关字段
subscription_status ENUM('free','trial','premium','enterprise') DEFAULT 'free'
subscription_type ENUM('monthly','yearly','lifetime')
subscription_expires_at TIMESTAMP
subscription_features JSON
```

#### 订阅状态类型
- **free**: 免费用户
- **trial**: 试用用户 (如szjason72)
- **premium**: 高级用户
- **enterprise**: 企业用户

#### AI服务调用控制
```python
# AI服务中的订阅检查逻辑
async def check_user_subscription(user_id: int) -> dict:
    # 检查是否为试用用户
    is_trial_user = subscription_status == 'trial'
    
    # 检查是否为付费用户
    has_active_subscription = subscription_status in ['premium', 'enterprise']
    
    # 检查试用是否过期
    if is_trial_user and subscription_expires_at:
        expires_at = datetime.fromisoformat(subscription_expires_at.replace('Z', '+00:00'))
        if datetime.now() > expires_at:
            is_trial_user = False
    
    # 判断用户是否有AI功能访问权限
    has_access = has_active_subscription or is_trial_user
```

### 当前限制和问题

#### 1. 缺少调用次数限制
- **问题**: 试用用户可以无限制调用AI服务
- **风险**: 可能导致AI服务成本过高
- **影响**: 运营成本控制困难

#### 2. 缺少细粒度权限控制
- **问题**: 只有基础的订阅状态检查
- **风险**: 无法根据用户类型提供差异化服务
- **影响**: 用户体验和商业价值受限

#### 3. 缺少使用量统计
- **问题**: 无法统计用户AI服务使用情况
- **风险**: 无法进行成本分析和优化
- **影响**: 商业决策缺乏数据支持

---

## 🚀 增强计划

### 阶段一：基础调用限制机制 (优先级：高)

#### 1.1 用户调用次数表设计
```sql
-- 创建用户AI服务调用统计表
CREATE TABLE user_ai_usage (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    service_type VARCHAR(50) NOT NULL, -- 'job_matching', 'document_parsing', 'chat'
    call_count INT DEFAULT 0,
    last_reset_date DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    UNIQUE KEY uk_user_service_date (user_id, service_type, last_reset_date),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 创建用户订阅限制配置表
CREATE TABLE subscription_limits (
    id INT PRIMARY KEY AUTO_INCREMENT,
    subscription_status VARCHAR(20) NOT NULL,
    service_type VARCHAR(50) NOT NULL,
    daily_limit INT NOT NULL,
    monthly_limit INT NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    UNIQUE KEY uk_subscription_service (subscription_status, service_type)
);

-- 插入默认限制配置
INSERT INTO subscription_limits (subscription_status, service_type, daily_limit, monthly_limit) VALUES
('trial', 'job_matching', 10, 100),
('trial', 'document_parsing', 5, 50),
('trial', 'chat', 20, 200),
('premium', 'job_matching', 100, 1000),
('premium', 'document_parsing', 50, 500),
('premium', 'chat', 200, 2000),
('enterprise', 'job_matching', 1000, 10000),
('enterprise', 'document_parsing', 500, 5000),
('enterprise', 'chat', 2000, 20000);
```

#### 1.2 AI服务调用限制中间件
```python
# 新增AI服务调用限制中间件
async def check_ai_service_quota(user_id: int, service_type: str) -> dict:
    """检查用户AI服务调用配额"""
    try:
        # 获取用户订阅状态
        subscription_info = await check_user_subscription(user_id)
        if not subscription_info['has_access']:
            return {
                'allowed': False,
                'reason': 'subscription_expired',
                'message': '订阅已过期，请升级订阅以继续使用AI服务'
            }
        
        # 获取用户订阅限制
        subscription_status = subscription_info['subscription_status']
        limits = await get_subscription_limits(subscription_status, service_type)
        
        # 检查今日调用次数
        today_usage = await get_user_daily_usage(user_id, service_type)
        
        if today_usage >= limits['daily_limit']:
            return {
                'allowed': False,
                'reason': 'daily_limit_exceeded',
                'message': f'今日{service_type}调用次数已达上限({limits["daily_limit"]}次)',
                'reset_time': '明天00:00'
            }
        
        # 检查本月调用次数
        monthly_usage = await get_user_monthly_usage(user_id, service_type)
        if monthly_usage >= limits['monthly_limit']:
            return {
                'allowed': False,
                'reason': 'monthly_limit_exceeded',
                'message': f'本月{service_type}调用次数已达上限({limits["monthly_limit"]}次)',
                'reset_time': '下月1日00:00'
            }
        
        return {
            'allowed': True,
            'daily_remaining': limits['daily_limit'] - today_usage,
            'monthly_remaining': limits['monthly_limit'] - monthly_usage
        }
        
    except Exception as e:
        logger.error(f"配额检查异常: {e}")
        return {
            'allowed': False,
            'reason': 'system_error',
            'message': '系统错误，请稍后重试'
        }

async def increment_ai_usage(user_id: int, service_type: str):
    """增加用户AI服务使用计数"""
    try:
        today = datetime.now().date()
        
        # 更新或插入使用记录
        query = """
        INSERT INTO user_ai_usage (user_id, service_type, call_count, last_reset_date)
        VALUES (%s, %s, 1, %s)
        ON DUPLICATE KEY UPDATE 
        call_count = call_count + 1,
        updated_at = CURRENT_TIMESTAMP
        """
        
        cursor.execute(query, (user_id, service_type, today))
        conn.commit()
        
    except Exception as e:
        logger.error(f"使用计数更新异常: {e}")
```

#### 1.3 更新AI服务API
```python
@app.route("/api/v1/ai/job-matching", methods=["POST"])
async def job_matching_api(request: Request):
    """职位匹配API - 增加调用限制"""
    try:
        # 用户认证
        auth_result = await authenticate_user(request)
        if auth_result:
            return auth_result
        
        # 检查AI服务调用配额
        quota_check = await check_ai_service_quota(request.ctx.user_id, 'job_matching')
        if not quota_check['allowed']:
            return sanic_json({
                "error": quota_check['message'],
                "code": quota_check['reason'],
                "quota_info": quota_check
            }, status=429)
        
        # 执行AI服务调用
        result = await job_matching_service._handle_job_matching(request)
        
        # 增加使用计数
        await increment_ai_usage(request.ctx.user_id, 'job_matching')
        
        # 在响应中添加配额信息
        if isinstance(result, dict):
            result['quota_info'] = {
                'daily_remaining': quota_check['daily_remaining'],
                'monthly_remaining': quota_check['monthly_remaining']
            }
        
        return result
        
    except Exception as e:
        logger.error(f"职位匹配API异常: {e}")
        return sanic_json({"error": f"服务器内部错误: {str(e)}"}, status=500)
```

### 阶段二：订阅管理增强 (优先级：中)

#### 2.1 订阅状态管理API
```go
// 新增订阅管理API
type SubscriptionManager struct {
    db *gorm.DB
}

// 获取用户订阅信息
func (sm *SubscriptionManager) GetUserSubscription(userID uint) (*UserSubscription, error) {
    var user User
    if err := sm.db.First(&user, userID).Error; err != nil {
        return nil, err
    }
    
    // 获取使用统计
    usage, err := sm.getUserUsage(userID)
    if err != nil {
        return nil, err
    }
    
    // 获取订阅限制
    limits, err := sm.getSubscriptionLimits(user.SubscriptionStatus)
    if err != nil {
        return nil, err
    }
    
    return &UserSubscription{
        UserID:              userID,
        SubscriptionStatus:  user.SubscriptionStatus,
        SubscriptionType:    user.SubscriptionType,
        SubscriptionExpires: user.SubscriptionExpiresAt,
        Usage:              usage,
        Limits:             limits,
    }, nil
}

// 升级用户订阅
func (sm *SubscriptionManager) UpgradeSubscription(userID uint, newStatus string) error {
    return sm.db.Model(&User{}).Where("id = ?", userID).Updates(map[string]interface{}{
        "subscription_status": newStatus,
        "subscription_expires_at": time.Now().AddDate(0, 1, 0), // 默认1个月
    }).Error
}
```

#### 2.2 订阅状态查询API
```go
// 订阅状态查询API
func (c *CompanyController) GetSubscriptionStatus(ctx *gin.Context) {
    userID := ctx.GetUint("user_id")
    
    subscription, err := c.subscriptionManager.GetUserSubscription(userID)
    if err != nil {
        ctx.JSON(http.StatusInternalServerError, gin.H{
            "error": "获取订阅信息失败",
        })
        return
    }
    
    ctx.JSON(http.StatusOK, gin.H{
        "status": "success",
        "data": subscription,
    })
}
```

### 阶段三：用户体验优化 (优先级：中)

#### 3.1 前端订阅状态显示
```typescript
// 前端订阅状态组件
interface SubscriptionInfo {
  status: 'free' | 'trial' | 'premium' | 'enterprise';
  type?: 'monthly' | 'yearly' | 'lifetime';
  expiresAt?: string;
  usage: {
    jobMatching: { daily: number; monthly: number; };
    documentParsing: { daily: number; monthly: number; };
    chat: { daily: number; monthly: number; };
  };
  limits: {
    jobMatching: { daily: number; monthly: number; };
    documentParsing: { daily: number; monthly: number; };
    chat: { daily: number; monthly: number; };
  };
}

const SubscriptionStatus: React.FC = () => {
  const [subscription, setSubscription] = useState<SubscriptionInfo | null>(null);
  
  useEffect(() => {
    fetchSubscriptionStatus().then(setSubscription);
  }, []);
  
  if (!subscription) return <div>加载中...</div>;
  
  return (
    <div className="subscription-status">
      <h3>订阅状态</h3>
      <div className="status-info">
        <span className={`status-badge ${subscription.status}`}>
          {getStatusText(subscription.status)}
        </span>
        {subscription.expiresAt && (
          <span className="expires-info">
            到期时间: {formatDate(subscription.expiresAt)}
          </span>
        )}
      </div>
      
      <div className="usage-info">
        <h4>使用情况</h4>
        {Object.entries(subscription.usage).map(([service, usage]) => (
          <div key={service} className="service-usage">
            <span className="service-name">{getServiceName(service)}</span>
            <div className="usage-bars">
              <div className="daily-usage">
                今日: {usage.daily}/{subscription.limits[service].daily}
              </div>
              <div className="monthly-usage">
                本月: {usage.monthly}/{subscription.limits[service].monthly}
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};
```

#### 3.2 调用限制提示
```typescript
// AI服务调用限制提示组件
const AIServiceCall: React.FC<{ serviceType: string }> = ({ serviceType }) => {
  const [quotaInfo, setQuotaInfo] = useState<QuotaInfo | null>(null);
  
  const handleServiceCall = async () => {
    try {
      const result = await callAIService(serviceType);
      
      // 更新配额信息
      if (result.quota_info) {
        setQuotaInfo(result.quota_info);
      }
      
      // 显示结果
      showResult(result);
      
    } catch (error) {
      if (error.code === 'daily_limit_exceeded' || error.code === 'monthly_limit_exceeded') {
        showUpgradePrompt(error.message);
      } else {
        showError(error.message);
      }
    }
  };
  
  return (
    <div className="ai-service-call">
      <button onClick={handleServiceCall} disabled={!quotaInfo?.allowed}>
        调用AI服务
      </button>
      
      {quotaInfo && (
        <div className="quota-info">
          <div className="daily-remaining">
            今日剩余: {quotaInfo.daily_remaining} 次
          </div>
          <div className="monthly-remaining">
            本月剩余: {quotaInfo.monthly_remaining} 次
          </div>
        </div>
      )}
    </div>
  );
};
```

### 阶段四：监控和分析 (优先级：低)

#### 4.1 使用量统计API
```go
// 使用量统计API
func (c *CompanyController) GetUsageStatistics(ctx *gin.Context) {
    userID := ctx.GetUint("user_id")
    
    // 获取使用统计
    stats, err := c.subscriptionManager.GetUsageStatistics(userID)
    if err != nil {
        ctx.JSON(http.StatusInternalServerError, gin.H{
            "error": "获取使用统计失败",
        })
        return
    }
    
    ctx.JSON(http.StatusOK, gin.H{
        "status": "success",
        "data": stats,
    })
}
```

#### 4.2 成本分析报告
```python
# 成本分析报告生成
async def generate_cost_analysis_report(start_date: datetime, end_date: datetime):
    """生成成本分析报告"""
    try:
        # 获取AI服务调用统计
        usage_stats = await get_ai_usage_statistics(start_date, end_date)
        
        # 计算成本
        cost_analysis = {
            'total_calls': usage_stats['total_calls'],
            'total_cost': calculate_ai_service_cost(usage_stats),
            'cost_by_service': {},
            'cost_by_user_type': {},
            'recommendations': []
        }
        
        # 按服务类型分析成本
        for service_type, calls in usage_stats['by_service'].items():
            cost_analysis['cost_by_service'][service_type] = {
                'calls': calls,
                'cost': calculate_service_cost(service_type, calls)
            }
        
        # 按用户类型分析成本
        for user_type, calls in usage_stats['by_user_type'].items():
            cost_analysis['cost_by_user_type'][user_type] = {
                'calls': calls,
                'cost': calculate_user_type_cost(user_type, calls)
            }
        
        # 生成优化建议
        cost_analysis['recommendations'] = generate_cost_optimization_recommendations(cost_analysis)
        
        return cost_analysis
        
    except Exception as e:
        logger.error(f"成本分析报告生成异常: {e}")
        return None
```

---

## 📊 实施计划

### 时间安排

| 阶段 | 时间 | 主要任务 | 交付物 |
|------|------|----------|--------|
| 阶段一 | 1-2天 | 基础调用限制机制 | 数据库表、中间件、API更新 |
| 阶段二 | 2-3天 | 订阅管理增强 | 订阅管理API、状态查询 |
| 阶段三 | 3-4天 | 用户体验优化 | 前端组件、提示系统 |
| 阶段四 | 2-3天 | 监控和分析 | 统计API、成本分析 |

### 优先级排序

1. **高优先级**: 基础调用限制机制 - 防止成本失控
2. **中优先级**: 订阅管理增强 - 提升商业价值
3. **中优先级**: 用户体验优化 - 提升用户满意度
4. **低优先级**: 监控和分析 - 支持长期优化

---

## 🎯 预期效果

### 成本控制效果

| 用户类型 | 当前状态 | 预期效果 |
|----------|----------|----------|
| 试用用户 | 无限制调用 | 每日10次，每月100次 |
| 高级用户 | 无限制调用 | 每日100次，每月1000次 |
| 企业用户 | 无限制调用 | 每日1000次，每月10000次 |

### 商业价值提升

1. **成本控制**: AI服务调用成本可控
2. **用户分层**: 不同订阅级别提供差异化服务
3. **收入增长**: 引导用户升级订阅
4. **数据驱动**: 基于使用数据优化服务

### 用户体验改善

1. **透明化**: 用户清楚了解使用限制
2. **引导性**: 合理引导用户升级订阅
3. **友好性**: 优雅处理限制情况
4. **个性化**: 根据订阅状态提供个性化服务

---

## 🚨 风险控制

### 技术风险

1. **性能影响**: 配额检查可能影响API响应时间
   - **缓解措施**: 使用Redis缓存配额信息
   
2. **数据一致性**: 并发调用可能导致计数不准确
   - **缓解措施**: 使用数据库事务和锁机制

### 业务风险

1. **用户流失**: 限制过严可能导致用户流失
   - **缓解措施**: 合理设置限制，提供升级路径
   
2. **收入影响**: 限制可能影响用户付费意愿
   - **缓解措施**: 提供有吸引力的升级方案

---

## 📝 总结

这个增强计划将显著提升系统的订阅管理能力和AI服务调用控制机制，实现：

1. **精细化的权限控制** - 基于用户订阅状态控制AI服务调用
2. **成本可控的运营模式** - 防止AI服务被滥用
3. **差异化的用户体验** - 不同订阅级别提供不同服务
4. **数据驱动的优化** - 基于使用数据持续优化服务

通过这个计划，我们可以为szjason72这样的试用用户提供合理的AI服务使用体验，同时控制运营成本，并为未来的商业化运营奠定基础。

---

**文档创建者**: AI Assistant  
**最后更新**: 2025年9月15日  
**状态**: 📋 计划制定完成，准备实施

---

*"The best way to predict the future is to create it."* - 预测未来的最好方法就是创造未来。
