#!/usr/bin/env python3
"""
数据访问审计系统
实现完整的数据访问审计、监控和合规性检查
"""

import asyncio
import logging
import json
import hashlib
from typing import Dict, Any, List, Optional, Set, Union
from datetime import datetime, timedelta
from enum import Enum
from dataclasses import dataclass, field, asdict
from abc import ABC, abstractmethod
import uuid

logger = logging.getLogger(__name__)

class AuditEventType(Enum):
    """审计事件类型"""
    LOGIN = "login"
    LOGOUT = "logout"
    DATA_ACCESS = "data_access"
    DATA_MODIFICATION = "data_modification"
    DATA_DELETION = "data_deletion"
    PERMISSION_CHANGE = "permission_change"
    ROLE_ASSIGNMENT = "role_assignment"
    SYSTEM_CONFIG = "system_config"
    SECURITY_VIOLATION = "security_violation"
    API_ACCESS = "api_access"

class AuditLevel(Enum):
    """审计级别"""
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"

class AuditStatus(Enum):
    """审计状态"""
    SUCCESS = "success"
    FAILURE = "failure"
    WARNING = "warning"
    SUSPICIOUS = "suspicious"

@dataclass
class AuditEvent:
    """审计事件"""
    event_id: str
    event_type: AuditEventType
    user_id: str
    username: str
    session_id: Optional[str] = None
    ip_address: Optional[str] = None
    user_agent: Optional[str] = None
    resource_type: Optional[str] = None
    resource_id: Optional[str] = None
    action: Optional[str] = None
    status: AuditStatus = AuditStatus.SUCCESS
    level: AuditLevel = AuditLevel.LOW
    details: Dict[str, Any] = field(default_factory=dict)
    timestamp: datetime = field(default_factory=datetime.now)
    duration_ms: Optional[int] = None
    error_message: Optional[str] = None
    
    def to_dict(self) -> Dict[str, Any]:
        """转换为字典"""
        data = asdict(self)
        data['timestamp'] = self.timestamp.isoformat()
        return data

@dataclass
class AuditRule:
    """审计规则"""
    rule_id: str
    name: str
    description: str
    event_types: List[AuditEventType]
    conditions: Dict[str, Any]
    actions: List[str]
    is_active: bool = True
    created_at: datetime = field(default_factory=datetime.now)

@dataclass
class AuditAlert:
    """审计告警"""
    alert_id: str
    rule_id: str
    event_id: str
    severity: AuditLevel
    message: str
    details: Dict[str, Any] = field(default_factory=dict)
    timestamp: datetime = field(default_factory=datetime.now)
    is_resolved: bool = False
    resolved_by: Optional[str] = None
    resolved_at: Optional[datetime] = None

class AuditStorage(ABC):
    """审计存储抽象基类"""
    
    @abstractmethod
    async def store_event(self, event: AuditEvent) -> bool:
        """存储审计事件"""
        pass
    
    @abstractmethod
    async def get_events(self, filters: Dict[str, Any], limit: int = 100) -> List[AuditEvent]:
        """获取审计事件"""
        pass
    
    @abstractmethod
    async def get_events_by_user(self, user_id: str, limit: int = 100) -> List[AuditEvent]:
        """获取用户审计事件"""
        pass

class MemoryAuditStorage(AuditStorage):
    """内存审计存储"""
    
    def __init__(self):
        self.events: List[AuditEvent] = []
        self.max_events = 10000  # 最大存储事件数
    
    async def store_event(self, event: AuditEvent) -> bool:
        """存储审计事件"""
        self.events.append(event)
        
        # 保持最大事件数限制
        if len(self.events) > self.max_events:
            self.events = self.events[-self.max_events:]
        
        logger.debug(f"审计事件已存储: {event.event_id}")
        return True
    
    async def get_events(self, filters: Dict[str, Any], limit: int = 100) -> List[AuditEvent]:
        """获取审计事件"""
        filtered_events = []
        
        for event in self.events:
            if self._matches_filters(event, filters):
                filtered_events.append(event)
        
        # 按时间倒序排列
        filtered_events.sort(key=lambda x: x.timestamp, reverse=True)
        
        return filtered_events[:limit]
    
    async def get_events_by_user(self, user_id: str, limit: int = 100) -> List[AuditEvent]:
        """获取用户审计事件"""
        user_events = [event for event in self.events if event.user_id == user_id]
        user_events.sort(key=lambda x: x.timestamp, reverse=True)
        return user_events[:limit]
    
    def _matches_filters(self, event: AuditEvent, filters: Dict[str, Any]) -> bool:
        """检查事件是否匹配过滤器"""
        for key, value in filters.items():
            if key == 'event_type' and event.event_type != value:
                return False
            elif key == 'user_id' and event.user_id != value:
                return False
            elif key == 'status' and event.status != value:
                return False
            elif key == 'level' and event.level != value:
                return False
            elif key == 'start_time' and event.timestamp < value:
                return False
            elif key == 'end_time' and event.timestamp > value:
                return False
        
        return True

class AuditRuleEngine:
    """审计规则引擎"""
    
    def __init__(self):
        self.rules: Dict[str, AuditRule] = {}
        self.alerts: List[AuditAlert] = []
        self._initialize_default_rules()
    
    def _initialize_default_rules(self):
        """初始化默认审计规则"""
        # 登录失败规则
        login_failure_rule = AuditRule(
            rule_id="login_failure",
            name="登录失败检测",
            description="检测多次登录失败",
            event_types=[AuditEventType.LOGIN],
            conditions={
                "status": AuditStatus.FAILURE,
                "threshold": 5,
                "time_window_minutes": 15
            },
            actions=["alert", "block_user"]
        )
        
        # 权限提升规则
        privilege_escalation_rule = AuditRule(
            rule_id="privilege_escalation",
            name="权限提升检测",
            description="检测异常权限提升",
            event_types=[AuditEventType.ROLE_ASSIGNMENT, AuditEventType.PERMISSION_CHANGE],
            conditions={
                "new_role": ["admin", "super_admin"],
                "time_window_hours": 24
            },
            actions=["alert", "require_approval"]
        )
        
        # 数据大量访问规则
        bulk_data_access_rule = AuditRule(
            rule_id="bulk_data_access",
            name="大量数据访问检测",
            description="检测大量数据访问行为",
            event_types=[AuditEventType.DATA_ACCESS],
            conditions={
                "threshold": 1000,
                "time_window_minutes": 60
            },
            actions=["alert", "rate_limit"]
        )
        
        # 敏感数据访问规则
        sensitive_data_rule = AuditRule(
            rule_id="sensitive_data_access",
            name="敏感数据访问检测",
            description="检测敏感数据访问",
            event_types=[AuditEventType.DATA_ACCESS],
            conditions={
                "resource_type": ["user", "company", "resume"],
                "action": ["read", "export"]
            },
            actions=["alert", "log_detailed"]
        )
        
        self.rules = {
            "login_failure": login_failure_rule,
            "privilege_escalation": privilege_escalation_rule,
            "bulk_data_access": bulk_data_access_rule,
            "sensitive_data_access": sensitive_data_rule
        }
    
    async def evaluate_event(self, event: AuditEvent) -> List[AuditAlert]:
        """评估审计事件"""
        alerts = []
        
        for rule in self.rules.values():
            if not rule.is_active:
                continue
            
            if event.event_type in rule.event_types:
                if await self._check_rule_conditions(event, rule):
                    alert = await self._create_alert(event, rule)
                    alerts.append(alert)
                    self.alerts.append(alert)
        
        return alerts
    
    async def _check_rule_conditions(self, event: AuditEvent, rule: AuditRule) -> bool:
        """检查规则条件"""
        conditions = rule.conditions
        
        # 检查状态条件
        if 'status' in conditions and event.status != conditions['status']:
            return False
        
        # 检查资源类型条件
        if 'resource_type' in conditions:
            if isinstance(conditions['resource_type'], list):
                if event.resource_type not in conditions['resource_type']:
                    return False
            elif event.resource_type != conditions['resource_type']:
                return False
        
        # 检查操作条件
        if 'action' in conditions:
            if isinstance(conditions['action'], list):
                if event.action not in conditions['action']:
                    return False
            elif event.action != conditions['action']:
                return False
        
        # 检查阈值条件（需要历史数据）
        if 'threshold' in conditions:
            # 这里需要查询历史事件来计算阈值
            # 暂时返回False，实际实现需要数据库查询
            pass
        
        return True
    
    async def _create_alert(self, event: AuditEvent, rule: AuditRule) -> AuditAlert:
        """创建告警"""
        alert = AuditAlert(
            alert_id=str(uuid.uuid4()),
            rule_id=rule.rule_id,
            event_id=event.event_id,
            severity=event.level,
            message=f"审计规则触发: {rule.name}",
            details={
                "rule_description": rule.description,
                "event_details": event.details,
                "conditions": rule.conditions
            }
        )
        
        logger.warning(f"审计告警: {alert.alert_id} - {alert.message}")
        return alert

class AuditSystem:
    """审计系统"""
    
    def __init__(self, storage: Optional[AuditStorage] = None):
        self.storage = storage or MemoryAuditStorage()
        self.rule_engine = AuditRuleEngine()
        self.is_enabled = True
    
    async def log_event(self, event_type: AuditEventType, user_id: str, username: str,
                       session_id: Optional[str] = None, ip_address: Optional[str] = None,
                       user_agent: Optional[str] = None, resource_type: Optional[str] = None,
                       resource_id: Optional[str] = None, action: Optional[str] = None,
                       status: AuditStatus = AuditStatus.SUCCESS, level: AuditLevel = AuditLevel.LOW,
                       details: Optional[Dict[str, Any]] = None, duration_ms: Optional[int] = None,
                       error_message: Optional[str] = None) -> str:
        """记录审计事件"""
        if not self.is_enabled:
            return ""
        
        event = AuditEvent(
            event_id=str(uuid.uuid4()),
            event_type=event_type,
            user_id=user_id,
            username=username,
            session_id=session_id,
            ip_address=ip_address,
            user_agent=user_agent,
            resource_type=resource_type,
            resource_id=resource_id,
            action=action,
            status=status,
            level=level,
            details=details or {},
            duration_ms=duration_ms,
            error_message=error_message
        )
        
        # 存储事件
        await self.storage.store_event(event)
        
        # 评估规则
        alerts = await self.rule_engine.evaluate_event(event)
        
        # 处理告警
        for alert in alerts:
            await self._handle_alert(alert)
        
        logger.info(f"审计事件已记录: {event.event_id} - {event.event_type.value}")
        return event.event_id
    
    async def _handle_alert(self, alert: AuditAlert):
        """处理告警"""
        # 这里可以实现告警处理逻辑，如发送邮件、短信等
        logger.warning(f"审计告警处理: {alert.alert_id} - {alert.message}")
    
    async def get_audit_logs(self, filters: Optional[Dict[str, Any]] = None, limit: int = 100) -> List[AuditEvent]:
        """获取审计日志"""
        return await self.storage.get_events(filters or {}, limit)
    
    async def get_user_audit_logs(self, user_id: str, limit: int = 100) -> List[AuditEvent]:
        """获取用户审计日志"""
        return await self.storage.get_events_by_user(user_id, limit)
    
    async def get_alerts(self, resolved: Optional[bool] = None) -> List[AuditAlert]:
        """获取告警"""
        if resolved is None:
            return self.rule_engine.alerts
        else:
            return [alert for alert in self.rule_engine.alerts if alert.is_resolved == resolved]
    
    async def resolve_alert(self, alert_id: str, resolved_by: str) -> bool:
        """解决告警"""
        for alert in self.rule_engine.alerts:
            if alert.alert_id == alert_id:
                alert.is_resolved = True
                alert.resolved_by = resolved_by
                alert.resolved_at = datetime.now()
                logger.info(f"告警已解决: {alert_id} by {resolved_by}")
                return True
        return False
    
    async def generate_audit_report(self, start_time: datetime, end_time: datetime) -> Dict[str, Any]:
        """生成审计报告"""
        filters = {
            'start_time': start_time,
            'end_time': end_time
        }
        
        events = await self.storage.get_events(filters, limit=10000)
        
        # 统计信息
        total_events = len(events)
        event_types = {}
        user_activities = {}
        status_counts = {}
        
        for event in events:
            # 事件类型统计
            event_types[event.event_type.value] = event_types.get(event.event_type.value, 0) + 1
            
            # 用户活动统计
            user_activities[event.user_id] = user_activities.get(event.user_id, 0) + 1
            
            # 状态统计
            status_counts[event.status.value] = status_counts.get(event.status.value, 0) + 1
        
        return {
            "report_id": str(uuid.uuid4()),
            "start_time": start_time.isoformat(),
            "end_time": end_time.isoformat(),
            "total_events": total_events,
            "event_types": event_types,
            "user_activities": user_activities,
            "status_counts": status_counts,
            "generated_at": datetime.now().isoformat()
        }

# 全局审计系统实例
audit_system = AuditSystem()

async def main():
    """测试审计系统"""
    logger.info("🚀 开始审计系统测试...")
    
    # 测试记录登录事件
    logger.info("📋 测试记录登录事件...")
    login_event_id = await audit_system.log_event(
        event_type=AuditEventType.LOGIN,
        user_id="user_1",
        username="admin",
        ip_address="192.168.1.100",
        user_agent="Mozilla/5.0",
        status=AuditStatus.SUCCESS,
        level=AuditLevel.MEDIUM
    )
    logger.info(f"✅ 登录事件已记录: {login_event_id}")
    
    # 测试记录数据访问事件
    logger.info("📋 测试记录数据访问事件...")
    access_event_id = await audit_system.log_event(
        event_type=AuditEventType.DATA_ACCESS,
        user_id="user_1",
        username="admin",
        resource_type="user",
        resource_id="user_123",
        action="read",
        status=AuditStatus.SUCCESS,
        level=AuditLevel.LOW,
        details={"query": "SELECT * FROM users WHERE id = 123"}
    )
    logger.info(f"✅ 数据访问事件已记录: {access_event_id}")
    
    # 测试记录权限变更事件
    logger.info("📋 测试记录权限变更事件...")
    permission_event_id = await audit_system.log_event(
        event_type=AuditEventType.ROLE_ASSIGNMENT,
        user_id="user_1",
        username="admin",
        resource_type="user",
        resource_id="user_456",
        action="assign_role",
        status=AuditStatus.SUCCESS,
        level=AuditLevel.HIGH,
        details={"new_role": "admin", "assigned_by": "super_admin"}
    )
    logger.info(f"✅ 权限变更事件已记录: {permission_event_id}")
    
    # 测试获取审计日志
    logger.info("📋 测试获取审计日志...")
    audit_logs = await audit_system.get_audit_logs(limit=10)
    logger.info(f"✅ 审计日志数量: {len(audit_logs)}")
    
    # 测试获取用户审计日志
    logger.info("📋 测试获取用户审计日志...")
    user_logs = await audit_system.get_user_audit_logs("user_1", limit=5)
    logger.info(f"✅ 用户审计日志数量: {len(user_logs)}")
    
    # 测试获取告警
    logger.info("📋 测试获取告警...")
    alerts = await audit_system.get_alerts()
    logger.info(f"✅ 告警数量: {len(alerts)}")
    
    # 测试生成审计报告
    logger.info("📋 测试生成审计报告...")
    end_time = datetime.now()
    start_time = end_time - timedelta(hours=1)
    report = await audit_system.generate_audit_report(start_time, end_time)
    logger.info(f"✅ 审计报告已生成: {report['report_id']}")
    logger.info(f"✅ 报告统计: 总事件数={report['total_events']}")
    
    logger.info("🎉 审计系统测试完成！")

if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    asyncio.run(main())
