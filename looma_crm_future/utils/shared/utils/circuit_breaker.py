"""
熔断器 - 用于AI服务的熔断保护
防止服务雪崩，提高系统稳定性
"""

import asyncio
import logging
import time
from typing import Dict, Any, Optional, Callable
from datetime import datetime, timedelta
from enum import Enum

logger = logging.getLogger(__name__)


class CircuitState(Enum):
    """熔断器状态"""
    CLOSED = "closed"      # 关闭状态，正常请求
    OPEN = "open"          # 开启状态，拒绝请求
    HALF_OPEN = "half_open" # 半开启状态，允许少量请求


class CircuitBreaker:
    """熔断器"""
    
    def __init__(
        self,
        failure_threshold: int = 5,
        timeout: int = 60,
        expected_exception: type = Exception,
        name: str = "default"
    ):
        """初始化熔断器"""
        self.failure_threshold = failure_threshold
        self.timeout = timeout
        self.expected_exception = expected_exception
        self.name = name
        
        # 状态管理
        self.state = CircuitState.CLOSED
        self.failure_count = 0
        self.last_failure_time = None
        self.success_count = 0
        
        # 统计信息
        self.total_requests = 0
        self.successful_requests = 0
        self.failed_requests = 0
        
        logger.info(f"熔断器初始化: {name}, 失败阈值: {failure_threshold}, 超时: {timeout}秒")
    
    async def initialize(self):
        """初始化熔断器（兼容性方法）"""
        logger.info(f"熔断器 {self.name} 初始化完成")
        return True
    
    async def call(self, func: Callable, *args, **kwargs) -> Any:
        """执行函数调用，带熔断保护"""
        self.total_requests += 1
        
        # 检查熔断器状态
        if self.state == CircuitState.OPEN:
            if self._should_attempt_reset():
                self.state = CircuitState.HALF_OPEN
                logger.info(f"熔断器 {self.name} 进入半开启状态")
            else:
                self.failed_requests += 1
                raise Exception(f"熔断器 {self.name} 处于开启状态，请求被拒绝")
        
        try:
            # 执行函数
            result = await func(*args, **kwargs) if asyncio.iscoroutinefunction(func) else func(*args, **kwargs)
            
            # 成功处理
            await self._on_success()
            self.successful_requests += 1
            return result
            
        except self.expected_exception as e:
            # 失败处理
            await self._on_failure()
            self.failed_requests += 1
            logger.warning(f"熔断器 {self.name} 捕获异常: {e}")
            raise e
        except Exception as e:
            # 非预期异常，不计数
            self.failed_requests += 1
            logger.error(f"熔断器 {self.name} 非预期异常: {e}")
            raise e
    
    def _should_attempt_reset(self) -> bool:
        """检查是否应该尝试重置"""
        if self.last_failure_time is None:
            return True
        
        return time.time() - self.last_failure_time >= self.timeout
    
    async def _on_success(self):
        """成功处理"""
        self.failure_count = 0
        self.success_count += 1
        
        if self.state == CircuitState.HALF_OPEN:
            # 半开启状态下，成功请求达到阈值则关闭熔断器
            if self.success_count >= self.failure_threshold:
                self.state = CircuitState.CLOSED
                self.success_count = 0
                logger.info(f"熔断器 {self.name} 重置为关闭状态")
    
    async def _on_failure(self):
        """失败处理"""
        self.failure_count += 1
        self.last_failure_time = time.time()
        
        if self.state == CircuitState.HALF_OPEN:
            # 半开启状态下，任何失败都重新开启熔断器
            self.state = CircuitState.OPEN
            logger.warning(f"熔断器 {self.name} 重新开启")
        elif self.failure_count >= self.failure_threshold:
            # 失败次数达到阈值，开启熔断器
            self.state = CircuitState.OPEN
            logger.warning(f"熔断器 {self.name} 开启，失败次数: {self.failure_count}")
    
    def get_state(self) -> Dict[str, Any]:
        """获取熔断器状态"""
        return {
            'name': self.name,
            'state': self.state.value,
            'failure_count': self.failure_count,
            'success_count': self.success_count,
            'last_failure_time': self.last_failure_time,
            'total_requests': self.total_requests,
            'successful_requests': self.successful_requests,
            'failed_requests': self.failed_requests,
            'failure_rate': self.failed_requests / max(self.total_requests, 1),
            'timestamp': datetime.now().isoformat()
        }
    
    def reset(self):
        """重置熔断器"""
        self.state = CircuitState.CLOSED
        self.failure_count = 0
        self.success_count = 0
        self.last_failure_time = None
        logger.info(f"熔断器 {self.name} 已重置")
    
    async def cleanup(self):
        """清理资源"""
        self.reset()
        logger.info(f"熔断器 {self.name} 资源清理完成")


class CircuitBreakerManager:
    """熔断器管理器"""
    
    def __init__(self):
        self.circuit_breakers = {}
    
    def get_circuit_breaker(
        self,
        name: str,
        failure_threshold: int = 5,
        timeout: int = 60,
        expected_exception: type = Exception
    ) -> CircuitBreaker:
        """获取或创建熔断器"""
        if name not in self.circuit_breakers:
            self.circuit_breakers[name] = CircuitBreaker(
                failure_threshold=failure_threshold,
                timeout=timeout,
                expected_exception=expected_exception,
                name=name
            )
        
        return self.circuit_breakers[name]
    
    def get_all_states(self) -> Dict[str, Dict[str, Any]]:
        """获取所有熔断器状态"""
        return {
            name: breaker.get_state()
            for name, breaker in self.circuit_breakers.items()
        }
    
    def reset_all(self):
        """重置所有熔断器"""
        for breaker in self.circuit_breakers.values():
            breaker.reset()
        logger.info("所有熔断器已重置")
    
    async def cleanup(self):
        """清理所有熔断器"""
        for breaker in self.circuit_breakers.values():
            await breaker.cleanup()
        self.circuit_breakers.clear()
        logger.info("熔断器管理器资源清理完成")


class AdaptiveCircuitBreaker(CircuitBreaker):
    """自适应熔断器 - 根据历史数据动态调整参数"""
    
    def __init__(
        self,
        initial_failure_threshold: int = 5,
        min_failure_threshold: int = 2,
        max_failure_threshold: int = 20,
        timeout: int = 60,
        expected_exception: type = Exception,
        name: str = "adaptive"
    ):
        super().__init__(initial_failure_threshold, timeout, expected_exception, name)
        self.initial_failure_threshold = initial_failure_threshold
        self.min_failure_threshold = min_failure_threshold
        self.max_failure_threshold = max_failure_threshold
        self.history_window = 100  # 历史记录窗口
        self.request_history = []
        
        logger.info(f"自适应熔断器初始化: {name}")
    
    async def _on_success(self):
        """成功处理 - 自适应调整"""
        await super()._on_success()
        self.request_history.append({'success': True, 'timestamp': time.time()})
        self._cleanup_history()
        self._adjust_threshold()
    
    async def _on_failure(self):
        """失败处理 - 自适应调整"""
        await super()._on_failure()
        self.request_history.append({'success': False, 'timestamp': time.time()})
        self._cleanup_history()
        self._adjust_threshold()
    
    def _cleanup_history(self):
        """清理历史记录"""
        if len(self.request_history) > self.history_window:
            self.request_history = self.request_history[-self.history_window:]
    
    def _adjust_threshold(self):
        """根据历史数据调整失败阈值"""
        if len(self.request_history) < 10:
            return
        
        # 计算最近的成功率
        recent_requests = self.request_history[-20:]  # 最近20个请求
        success_count = sum(1 for req in recent_requests if req['success'])
        success_rate = success_count / len(recent_requests)
        
        # 根据成功率调整阈值
        if success_rate > 0.9:
            # 成功率高，可以降低阈值（更敏感）
            new_threshold = max(self.min_failure_threshold, self.failure_threshold - 1)
        elif success_rate < 0.7:
            # 成功率低，提高阈值（更宽松）
            new_threshold = min(self.max_failure_threshold, self.failure_threshold + 1)
        else:
            # 成功率中等，保持当前阈值
            return
        
        if new_threshold != self.failure_threshold:
            old_threshold = self.failure_threshold
            self.failure_threshold = new_threshold
            logger.info(f"熔断器 {self.name} 阈值调整: {old_threshold} -> {new_threshold} (成功率: {success_rate:.2f})")
    
    def get_state(self) -> Dict[str, Any]:
        """获取自适应熔断器状态"""
        state = super().get_state()
        state.update({
            'initial_threshold': self.initial_failure_threshold,
            'min_threshold': self.min_failure_threshold,
            'max_threshold': self.max_failure_threshold,
            'history_size': len(self.request_history),
            'adaptive': True
        })
        return state
