#!/usr/bin/env python3
"""
JobFirst Future版独立AI服务配置
"""

import os
from typing import Dict, Any

class FutureAIConfig:
    """Future版AI服务配置"""
    
    def __init__(self):
        self.config = self._load_config()
    
    def _load_config(self) -> Dict[str, Any]:
        """加载配置"""
        return {
            # 服务配置
            'services': {
                'ai_gateway': {
                    'host': os.getenv('AI_GATEWAY_HOST', '0.0.0.0'),
                    'port': int(os.getenv('AI_GATEWAY_PORT', '7510')),
                    'debug': os.getenv('DEBUG', 'False').lower() == 'true'
                },
                'resume_ai': {
                    'host': os.getenv('RESUME_AI_HOST', '0.0.0.0'),
                    'port': int(os.getenv('RESUME_AI_PORT', '7511')),
                    'debug': os.getenv('DEBUG', 'False').lower() == 'true'
                }
            },
            
            # 数据库配置
            'databases': {
                'redis': {
                    'host': os.getenv('REDIS_HOST', 'localhost:6382'),
                    'db': int(os.getenv('REDIS_DB', '1')),
                    'password': os.getenv('REDIS_PASSWORD', 'looma_independent_password'),
                    'key_prefix': os.getenv('REDIS_KEY_PREFIX', 'future:')
                },
                'postgresql': {
                    'host': os.getenv('POSTGRES_HOST', 'localhost:5434'),
                    'database': os.getenv('POSTGRES_DB', 'jobfirst_future'),
                    'user': os.getenv('POSTGRES_USER', 'jobfirst_future'),
                    'password': os.getenv('POSTGRES_PASSWORD', 'secure_future_password_2025')
                },
                'mongodb': {
                    'host': os.getenv('MONGODB_HOST', 'localhost:27018'),
                    'database': os.getenv('MONGODB_DB', 'jobfirst_future'),
                    'user': os.getenv('MONGODB_USER', 'jobfirst_future'),
                    'password': os.getenv('MONGODB_PASSWORD', 'secure_future_password_2025')
                }
            },
            
            # AI服务配置
            'ai_services': {
                'mineru_service': {
                    'url': os.getenv('MINERU_SERVICE_URL', 'http://localhost:8000'),
                    'timeout': int(os.getenv('MINERU_TIMEOUT', '60')),
                    'max_retries': int(os.getenv('MINERU_MAX_RETRIES', '3'))
                },
                'ai_models_service': {
                    'url': os.getenv('AI_MODELS_SERVICE_URL', 'http://localhost:8002'),
                    'timeout': int(os.getenv('AI_MODELS_TIMEOUT', '120')),
                    'max_retries': int(os.getenv('AI_MODELS_MAX_RETRIES', '3'))
                }
            },
            
            # 处理配置
            'processing': {
                'max_concurrent_requests': int(os.getenv('MAX_CONCURRENT_REQUESTS', '10')),
                'request_timeout': int(os.getenv('REQUEST_TIMEOUT', '300')),
                'max_file_size': int(os.getenv('MAX_FILE_SIZE', '10485760')),  # 10MB
                'supported_formats': ['pdf', 'docx', 'doc', 'txt', 'rtf'],
                'processing_timeout': int(os.getenv('PROCESSING_TIMEOUT', '300'))
            },
            
            # 监控配置
            'monitoring': {
                'enable_metrics': os.getenv('ENABLE_METRICS', 'True').lower() == 'true',
                'metrics_port': int(os.getenv('METRICS_PORT', '9091')),
                'log_level': os.getenv('LOG_LEVEL', 'INFO'),
                'enable_tracing': os.getenv('ENABLE_TRACING', 'False').lower() == 'true'
            },
            
            # 安全配置
            'security': {
                'enable_auth': os.getenv('ENABLE_AUTH', 'True').lower() == 'true',
                'jwt_secret': os.getenv('JWT_SECRET', 'jobfirst-future-ai-secret-key-2025'),
                'jwt_expiry': int(os.getenv('JWT_EXPIRY', '3600')),  # 1小时
                'rate_limit': {
                    'enabled': os.getenv('RATE_LIMIT_ENABLED', 'True').lower() == 'true',
                    'requests_per_minute': int(os.getenv('RATE_LIMIT_RPM', '60')),
                    'burst_size': int(os.getenv('RATE_LIMIT_BURST', '10'))
                }
            },
            
            # 集成配置
            'integration': {
                'zervigo_services': {
                    'auth_service': os.getenv('ZERVIGO_AUTH_URL', 'http://localhost:7520'),
                    'user_service': os.getenv('ZERVIGO_USER_URL', 'http://localhost:7530'),
                    'resume_service': os.getenv('ZERVIGO_RESUME_URL', 'http://localhost:7532'),
                    'company_service': os.getenv('ZERVIGO_COMPANY_URL', 'http://localhost:7534'),
                    'job_service': os.getenv('ZERVIGO_JOB_URL', 'http://localhost:7539')
                },
                'looma_services': {
                    'looma_crm': os.getenv('LOOMA_CRM_URL', 'http://localhost:7500'),
                    'looma_saas': os.getenv('LOOMA_SAAS_URL', 'http://localhost:8700')
                }
            },
            
            # 缓存配置
            'cache': {
                'enabled': os.getenv('CACHE_ENABLED', 'True').lower() == 'true',
                'default_ttl': int(os.getenv('CACHE_DEFAULT_TTL', '3600')),  # 1小时
                'max_size': int(os.getenv('CACHE_MAX_SIZE', '1000'))
            },
            
            # 负载均衡配置
            'load_balancer': {
                'strategy': os.getenv('LB_STRATEGY', 'round_robin'),  # round_robin, weighted, least_connections
                'health_check_interval': int(os.getenv('LB_HEALTH_CHECK_INTERVAL', '30')),
                'max_retries': int(os.getenv('LB_MAX_RETRIES', '3')),
                'circuit_breaker': {
                    'enabled': os.getenv('CB_ENABLED', 'True').lower() == 'true',
                    'failure_threshold': int(os.getenv('CB_FAILURE_THRESHOLD', '5')),
                    'recovery_timeout': int(os.getenv('CB_RECOVERY_TIMEOUT', '60'))
                }
            }
        }
    
    def get_service_config(self, service_name: str) -> Dict[str, Any]:
        """获取服务配置"""
        return self.config['services'].get(service_name, {})
    
    def get_database_config(self, db_name: str) -> Dict[str, Any]:
        """获取数据库配置"""
        return self.config['databases'].get(db_name, {})
    
    def get_ai_service_config(self, service_name: str) -> Dict[str, Any]:
        """获取AI服务配置"""
        return self.config['ai_services'].get(service_name, {})
    
    def get_processing_config(self) -> Dict[str, Any]:
        """获取处理配置"""
        return self.config['processing']
    
    def get_monitoring_config(self) -> Dict[str, Any]:
        """获取监控配置"""
        return self.config['monitoring']
    
    def get_security_config(self) -> Dict[str, Any]:
        """获取安全配置"""
        return self.config['security']
    
    def get_integration_config(self) -> Dict[str, Any]:
        """获取集成配置"""
        return self.config['integration']
    
    def get_cache_config(self) -> Dict[str, Any]:
        """获取缓存配置"""
        return self.config['cache']
    
    def get_load_balancer_config(self) -> Dict[str, Any]:
        """获取负载均衡配置"""
        return self.config['load_balancer']
    
    def is_development(self) -> bool:
        """检查是否为开发环境"""
        return self.config['services']['ai_gateway']['debug']
    
    def is_production(self) -> bool:
        """检查是否为生产环境"""
        return not self.is_development()

# 全局配置实例
config = FutureAIConfig()

# 导出配置
__all__ = ['config', 'FutureAIConfig']
