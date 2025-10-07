#!/usr/bin/env python3
"""
AI服务Consul注册脚本
专门为AI服务提供增强的Consul注册，包含认证和成本控制信息
"""

import json
import requests
import time
import logging
from datetime import datetime

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class AIServiceConsulRegistry:
    def __init__(self):
        self.consul_host = "localhost"
        self.consul_port = 8500
        self.ai_service_host = "localhost"
        self.ai_service_port = 8206
        self.consul_url = f"http://{self.consul_host}:{self.consul_port}"
        self.ai_service_url = f"http://{self.ai_service_host}:{self.ai_service_port}"
        
    def register_ai_service(self):
        """注册AI服务到Consul，包含特殊标签和元数据"""
        try:
            # 检查AI服务是否健康
            if not self._check_ai_service_health():
                logger.error("AI服务不健康，无法注册到Consul")
                return False
                
            # 构建AI服务注册信息
            registration_data = {
                "ID": "ai-service-1",
                "Name": "ai-service",
                "Tags": [
                    "ai",
                    "ml", 
                    "vector",
                    "analysis",
                    "chat",
                    "authenticated",  # 需要认证
                    "cost-controlled",  # 成本控制
                    "external-api",  # 使用外部API
                    "deepseek",  # DeepSeek集成
                    "ollama"  # Ollama集成
                ],
                "Address": self.ai_service_host,
                "Port": self.ai_service_port,
                "Meta": {
                    "service_type": "ai",
                    "framework": "sanic",
                    "language": "python",
                    "requires_auth": "true",
                    "cost_controlled": "true",
                    "external_apis": "deepseek,ollama",
                    "database": "postgresql",
                    "version": "1.0.0",
                    "description": "JobFirst AI服务 - 需要认证和成本控制",
                    "usage_limits": "daily,monthly",
                    "billing_enabled": "true"
                },
                "Check": {
                    "HTTP": f"{self.ai_service_url}/health",
                    "Timeout": "5s",
                    "Interval": "10s",
                    "DeregisterCriticalServiceAfter": "30s",
                    "Header": {
                        "Content-Type": ["application/json"]
                    }
                },
                "Weights": {
                    "Passing": 1,
                    "Warning": 1
                },
                "EnableTagOverride": False
            }
            
            # 注册到Consul
            response = requests.put(
                f"{self.consul_url}/v1/agent/service/register",
                json=registration_data,
                timeout=10
            )
            
            if response.status_code == 200:
                logger.info("AI服务成功注册到Consul")
                logger.info(f"服务ID: {registration_data['ID']}")
                logger.info(f"服务名称: {registration_data['Name']}")
                logger.info(f"服务标签: {', '.join(registration_data['Tags'])}")
                logger.info(f"元数据: {registration_data['Meta']}")
                return True
            else:
                logger.error(f"AI服务注册失败: HTTP {response.status_code}")
                logger.error(f"响应内容: {response.text}")
                return False
                
        except Exception as e:
            logger.error(f"AI服务注册异常: {e}")
            return False
    
    def _check_ai_service_health(self):
        """检查AI服务健康状态"""
        try:
            response = requests.get(f"{self.ai_service_url}/health", timeout=5)
            if response.status_code == 200:
                health_data = response.json()
                logger.info(f"AI服务健康检查通过: {health_data.get('status', 'unknown')}")
                return True
            else:
                logger.warning(f"AI服务健康检查失败: HTTP {response.status_code}")
                return False
        except Exception as e:
            logger.error(f"AI服务健康检查异常: {e}")
            return False
    
    def update_service_metadata(self, metadata_updates):
        """更新AI服务元数据"""
        try:
            # 获取当前服务信息
            response = requests.get(f"{self.consul_url}/v1/agent/service/ai-service-1")
            if response.status_code != 200:
                logger.error("无法获取当前服务信息")
                return False
                
            service_data = response.json()
            
            # 更新元数据
            if 'Meta' not in service_data:
                service_data['Meta'] = {}
                
            service_data['Meta'].update(metadata_updates)
            service_data['Meta']['last_updated'] = datetime.now().isoformat()
            
            # 重新注册服务
            return self.register_ai_service()
            
        except Exception as e:
            logger.error(f"更新服务元数据失败: {e}")
            return False
    
    def add_cost_control_metadata(self, cost_info):
        """添加成本控制元数据"""
        cost_metadata = {
            "cost_per_request": str(cost_info.get('cost_per_request', '0.01')),
            "daily_limit": str(cost_info.get('daily_limit', '100')),
            "monthly_limit": str(cost_info.get('monthly_limit', '1000')),
            "currency": cost_info.get('currency', 'USD'),
            "billing_provider": cost_info.get('billing_provider', 'internal'),
            "cost_control_enabled": "true"
        }
        return self.update_service_metadata(cost_metadata)
    
    def add_auth_metadata(self, auth_info):
        """添加认证元数据"""
        auth_metadata = {
            "auth_required": "true",
            "auth_type": auth_info.get('auth_type', 'jwt'),
            "user_service_url": auth_info.get('user_service_url', 'http://localhost:8081'),
            "permission_required": auth_info.get('permission_required', 'ai_service_access'),
            "rate_limit": auth_info.get('rate_limit', '100/hour')
        }
        return self.update_service_metadata(auth_metadata)
    
    def deregister_service(self):
        """注销AI服务"""
        try:
            response = requests.put(f"{self.consul_url}/v1/agent/service/deregister/ai-service-1")
            if response.status_code == 200:
                logger.info("AI服务已从Consul注销")
                return True
            else:
                logger.error(f"AI服务注销失败: HTTP {response.status_code}")
                return False
        except Exception as e:
            logger.error(f"AI服务注销异常: {e}")
            return False

def main():
    """主函数"""
    print("=== AI服务Consul注册管理 ===")
    
    registry = AIServiceConsulRegistry()
    
    # 注册AI服务
    print("1. 注册AI服务到Consul...")
    if registry.register_ai_service():
        print("   ✅ AI服务注册成功")
        
        # 添加成本控制元数据
        print("2. 添加成本控制元数据...")
        cost_info = {
            "cost_per_request": 0.01,
            "daily_limit": 100,
            "monthly_limit": 1000,
            "currency": "USD",
            "billing_provider": "internal"
        }
        if registry.add_cost_control_metadata(cost_info):
            print("   ✅ 成本控制元数据添加成功")
        else:
            print("   ⚠️  成本控制元数据添加失败")
        
        # 添加认证元数据
        print("3. 添加认证元数据...")
        auth_info = {
            "auth_type": "jwt",
            "user_service_url": "http://localhost:8081",
            "permission_required": "ai_service_access",
            "rate_limit": "100/hour"
        }
        if registry.add_auth_metadata(auth_info):
            print("   ✅ 认证元数据添加成功")
        else:
            print("   ⚠️  认证元数据添加失败")
            
    else:
        print("   ❌ AI服务注册失败")
        return 1
    
    print("\n=== AI服务Consul注册完成 ===")
    print("💡 提示: AI服务已注册，包含认证和成本控制信息")
    print("🔐 认证要求: JWT Token + 用户权限验证")
    print("💰 成本控制: 每日/每月使用限制")
    print("📊 外部API: DeepSeek + Ollama集成")
    
    return 0

if __name__ == "__main__":
    exit(main())
