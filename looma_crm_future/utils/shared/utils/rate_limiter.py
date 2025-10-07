"""
限流器 - 用于AI服务的流量控制
支持令牌桶、滑动窗口等多种限流算法
"""

import asyncio
import logging
import time
from typing import Dict, Any, Optional, List
from datetime import datetime, timedelta
from collections import defaultdict, deque

logger = logging.getLogger(__name__)


class RateLimiter:
    """限流器基类"""
    
    def __init__(self, name: str = "default"):
        self.name = name
        self.total_requests = 0
        self.blocked_requests = 0
    
    async def initialize(self):
        """初始化限流器（兼容性方法）"""
        logger.info(f"限流器 {self.name} 初始化完成")
        return True
    
    async def is_allowed(self, key: str = "default") -> bool:
        """检查是否允许请求"""
        raise NotImplementedError
    
    async def check_rate_limit(self, key: str = "default", service_type: str = None) -> Dict[str, Any]:
        """检查限流状态（兼容性方法）"""
        try:
            # 如果提供了service_type，将其与key组合
            if service_type:
                combined_key = f"{key}:{service_type}"
            else:
                combined_key = key
                
            allowed = await self.is_allowed(combined_key)
            return {
                'allowed': allowed,
                'key': combined_key,
                'timestamp': datetime.now().isoformat()
            }
        except Exception as e:
            logger.error(f"限流检查失败: {e}")
            return {
                'allowed': True,  # 出错时允许请求
                'key': key,
                'error': str(e),
                'timestamp': datetime.now().isoformat()
            }
    
    async def cleanup(self):
        """清理资源"""
        pass
    
    def get_stats(self) -> Dict[str, Any]:
        """获取统计信息"""
        return {
            'name': self.name,
            'total_requests': self.total_requests,
            'blocked_requests': self.blocked_requests,
            'block_rate': self.blocked_requests / max(self.total_requests, 1),
            'timestamp': datetime.now().isoformat()
        }


class TokenBucketRateLimiter(RateLimiter):
    """令牌桶限流器"""
    
    def __init__(
        self,
        capacity: int = 100,
        refill_rate: float = 10.0,
        name: str = "token_bucket"
    ):
        super().__init__(name)
        self.capacity = capacity
        self.refill_rate = refill_rate  # 每秒补充的令牌数
        
        # 每个key独立的令牌桶
        self.buckets = defaultdict(lambda: {
            'tokens': capacity,
            'last_refill': time.time()
        })
    
    async def is_allowed(self, key: str = "default") -> bool:
        """检查是否允许请求"""
        self.total_requests += 1
        
        bucket = self.buckets[key]
        now = time.time()
        
        # 计算需要补充的令牌数
        time_passed = now - bucket['last_refill']
        tokens_to_add = time_passed * self.refill_rate
        
        # 补充令牌
        bucket['tokens'] = min(self.capacity, bucket['tokens'] + tokens_to_add)
        bucket['last_refill'] = now
        
        # 检查是否有可用令牌
        if bucket['tokens'] >= 1:
            bucket['tokens'] -= 1
            return True
        else:
            self.blocked_requests += 1
            return False
    
    def get_bucket_stats(self, key: str = "default") -> Dict[str, Any]:
        """获取指定key的令牌桶状态"""
        bucket = self.buckets[key]
        now = time.time()
        
        # 更新令牌数
        time_passed = now - bucket['last_refill']
        tokens_to_add = time_passed * self.refill_rate
        current_tokens = min(self.capacity, bucket['tokens'] + tokens_to_add)
        
        return {
            'key': key,
            'capacity': self.capacity,
            'current_tokens': current_tokens,
            'refill_rate': self.refill_rate,
            'last_refill': bucket['last_refill']
        }
    
    async def cleanup(self):
        """清理资源"""
        self.buckets.clear()
        logger.info(f"令牌桶限流器 {self.name} 资源清理完成")


class SlidingWindowRateLimiter(RateLimiter):
    """滑动窗口限流器"""
    
    def __init__(
        self,
        window_size: int = 60,
        max_requests: int = 100,
        name: str = "sliding_window"
    ):
        super().__init__(name)
        self.window_size = window_size  # 窗口大小（秒）
        self.max_requests = max_requests  # 窗口内最大请求数
        
        # 每个key独立的滑动窗口
        self.windows = defaultdict(lambda: deque())
    
    async def is_allowed(self, key: str = "default") -> bool:
        """检查是否允许请求"""
        self.total_requests += 1
        
        now = time.time()
        window = self.windows[key]
        
        # 清理过期的请求记录
        while window and window[0] <= now - self.window_size:
            window.popleft()
        
        # 检查是否超过限制
        if len(window) >= self.max_requests:
            self.blocked_requests += 1
            return False
        
        # 记录当前请求
        window.append(now)
        return True
    
    def get_window_stats(self, key: str = "default") -> Dict[str, Any]:
        """获取指定key的窗口状态"""
        window = self.windows[key]
        now = time.time()
        
        # 清理过期的请求记录
        while window and window[0] <= now - self.window_size:
            window.popleft()
        
        return {
            'key': key,
            'window_size': self.window_size,
            'max_requests': self.max_requests,
            'current_requests': len(window),
            'remaining_requests': max(0, self.max_requests - len(window))
        }
    
    async def cleanup(self):
        """清理资源"""
        self.windows.clear()
        logger.info(f"滑动窗口限流器 {self.name} 资源清理完成")


class FixedWindowRateLimiter(RateLimiter):
    """固定窗口限流器"""
    
    def __init__(
        self,
        window_size: int = 60,
        max_requests: int = 100,
        name: str = "fixed_window"
    ):
        super().__init__(name)
        self.window_size = window_size  # 窗口大小（秒）
        self.max_requests = max_requests  # 窗口内最大请求数
        
        # 每个key独立的固定窗口
        self.windows = defaultdict(lambda: {
            'count': 0,
            'window_start': int(time.time() // self.window_size) * self.window_size
        })
    
    async def is_allowed(self, key: str = "default") -> bool:
        """检查是否允许请求"""
        self.total_requests += 1
        
        now = time.time()
        current_window = int(now // self.window_size) * self.window_size
        
        window = self.windows[key]
        
        # 检查是否需要重置窗口
        if window['window_start'] < current_window:
            window['count'] = 0
            window['window_start'] = current_window
        
        # 检查是否超过限制
        if window['count'] >= self.max_requests:
            self.blocked_requests += 1
            return False
        
        # 增加计数
        window['count'] += 1
        return True
    
    def get_window_stats(self, key: str = "default") -> Dict[str, Any]:
        """获取指定key的窗口状态"""
        now = time.time()
        current_window = int(now // self.window_size) * self.window_size
        
        window = self.windows[key]
        
        # 检查是否需要重置窗口
        if window['window_start'] < current_window:
            window['count'] = 0
            window['window_start'] = current_window
        
        return {
            'key': key,
            'window_size': self.window_size,
            'max_requests': self.max_requests,
            'current_requests': window['count'],
            'remaining_requests': max(0, self.max_requests - window['count']),
            'window_start': window['window_start'],
            'window_end': window['window_start'] + self.window_size
        }
    
    async def cleanup(self):
        """清理资源"""
        self.windows.clear()
        logger.info(f"固定窗口限流器 {self.name} 资源清理完成")


class AdaptiveRateLimiter(RateLimiter):
    """自适应限流器 - 根据系统负载动态调整限流参数"""
    
    def __init__(
        self,
        base_rate: int = 100,
        min_rate: int = 10,
        max_rate: int = 1000,
        window_size: int = 60,
        name: str = "adaptive"
    ):
        super().__init__(name)
        self.base_rate = base_rate
        self.min_rate = min_rate
        self.max_rate = max_rate
        self.window_size = window_size
        
        # 使用滑动窗口作为底层限流器
        self.underlying_limiter = SlidingWindowRateLimiter(
            window_size=window_size,
            max_requests=base_rate,
            name=f"{name}_underlying"
        )
        
        # 系统负载监控
        self.load_history = deque(maxlen=100)
        self.adjustment_history = deque(maxlen=50)
        
        logger.info(f"自适应限流器初始化: {name}")
    
    async def is_allowed(self, key: str = "default") -> bool:
        """检查是否允许请求"""
        # 使用底层限流器
        allowed = await self.underlying_limiter.is_allowed(key)
        
        # 记录请求结果用于负载计算
        self.load_history.append({
            'timestamp': time.time(),
            'allowed': allowed
        })
        
        # 定期调整限流参数
        if len(self.load_history) % 10 == 0:
            await self._adjust_rate()
        
        return allowed
    
    async def _adjust_rate(self):
        """根据系统负载调整限流速率"""
        if len(self.load_history) < 20:
            return
        
        # 计算最近的拒绝率
        recent_requests = list(self.load_history)[-20:]
        blocked_count = sum(1 for req in recent_requests if not req['allowed'])
        block_rate = blocked_count / len(recent_requests)
        
        # 计算平均响应时间（这里用请求间隔作为代理）
        if len(self.load_history) >= 2:
            intervals = []
            for i in range(1, len(self.load_history)):
                interval = self.load_history[i]['timestamp'] - self.load_history[i-1]['timestamp']
                intervals.append(interval)
            avg_interval = sum(intervals) / len(intervals)
        else:
            avg_interval = 1.0
        
        # 根据拒绝率和响应时间调整速率
        current_rate = self.underlying_limiter.max_requests
        
        if block_rate > 0.1:  # 拒绝率过高，降低速率
            new_rate = max(self.min_rate, int(current_rate * 0.8))
        elif block_rate < 0.01 and avg_interval > 0.1:  # 拒绝率低且响应慢，提高速率
            new_rate = min(self.max_rate, int(current_rate * 1.2))
        else:
            new_rate = current_rate
        
        if new_rate != current_rate:
            # 更新底层限流器的速率
            self.underlying_limiter.max_requests = new_rate
            self.adjustment_history.append({
                'timestamp': time.time(),
                'old_rate': current_rate,
                'new_rate': new_rate,
                'block_rate': block_rate,
                'avg_interval': avg_interval
            })
            logger.info(f"自适应限流器 {self.name} 速率调整: {current_rate} -> {new_rate} (拒绝率: {block_rate:.3f})")
    
    def get_stats(self) -> Dict[str, Any]:
        """获取自适应限流器统计信息"""
        stats = self.underlying_limiter.get_stats()
        stats.update({
            'base_rate': self.base_rate,
            'min_rate': self.min_rate,
            'max_rate': self.max_rate,
            'current_rate': self.underlying_limiter.max_requests,
            'adaptive': True,
            'load_history_size': len(self.load_history),
            'adjustment_count': len(self.adjustment_history)
        })
        
        if self.adjustment_history:
            last_adjustment = self.adjustment_history[-1]
            stats['last_adjustment'] = last_adjustment
        
        return stats
    
    async def cleanup(self):
        """清理资源"""
        await self.underlying_limiter.cleanup()
        self.load_history.clear()
        self.adjustment_history.clear()
        logger.info(f"自适应限流器 {self.name} 资源清理完成")


class RateLimiterManager:
    """限流器管理器"""
    
    def __init__(self):
        self.limiters = {}
    
    def get_limiter(
        self,
        name: str,
        limiter_type: str = "token_bucket",
        **kwargs
    ) -> RateLimiter:
        """获取或创建限流器"""
        if name not in self.limiters:
            if limiter_type == "token_bucket":
                self.limiters[name] = TokenBucketRateLimiter(name=name, **kwargs)
            elif limiter_type == "sliding_window":
                self.limiters[name] = SlidingWindowRateLimiter(name=name, **kwargs)
            elif limiter_type == "fixed_window":
                self.limiters[name] = FixedWindowRateLimiter(name=name, **kwargs)
            elif limiter_type == "adaptive":
                self.limiters[name] = AdaptiveRateLimiter(name=name, **kwargs)
            else:
                raise ValueError(f"不支持的限流器类型: {limiter_type}")
        
        return self.limiters[name]
    
    def get_all_stats(self) -> Dict[str, Dict[str, Any]]:
        """获取所有限流器统计信息"""
        return {
            name: limiter.get_stats()
            for name, limiter in self.limiters.items()
        }
    
    async def cleanup(self):
        """清理所有限流器"""
        for limiter in self.limiters.values():
            await limiter.cleanup()
        self.limiters.clear()
        logger.info("限流器管理器资源清理完成")
