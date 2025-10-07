#!/usr/bin/env python3
"""
Future版端到端流程测试
"""

import json
import requests
import logging
from datetime import datetime

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class FutureE2EEndToEndTest:
    def __init__(self):
        self.user_service_url = "http://localhost:7500"  # 修复端口配置：从7530改为7500 (LoomaCRM)
        self.ai_gateway_url = "http://localhost:7510"
        self.resume_ai_url = "http://localhost:7511"
        
        # 使用现有的测试用户
        self.test_user = {
            "username": "admin",
            "password": "password"
        }
        
        self.user_token = None
    
    def step1_user_login(self):
        """步骤1: 用户登录"""
        logger.info("🧪 步骤1: 测试用户登录...")
        
        result = {
            "step": "用户登录",
            "success": False,
            "details": {}
        }
        
        try:
            login_data = {
                "username": self.test_user["username"],
                "password": self.test_user["password"]
            }
            
            response = requests.post(
                f"{self.user_service_url}/api/v1/auth/login",
                json=login_data,
                timeout=10
            )
            
            if response.status_code == 200:
                response_data = response.json()
                if response_data.get("success") and response_data.get("data", {}).get("success"):
                    token = response_data.get("data", {}).get("token")
                    self.user_token = token
                    result["success"] = True
                    result["details"] = {
                        "status_code": response.status_code,
                        "message": "用户登录成功",
                        "token_received": bool(token)
                    }
                    logger.info("✅ 步骤1: 用户登录成功，获得Token")
                else:
                    result["details"] = {
                        "status_code": response.status_code,
                        "error": "登录响应格式错误"
                    }
                    logger.error("❌ 步骤1: 用户登录响应格式错误")
            else:
                result["details"] = {
                    "status_code": response.status_code,
                    "error": response.text
                }
                logger.error(f"❌ 步骤1: 用户登录失败: {response.status_code}")
                
        except Exception as e:
            result["details"] = {"error": str(e)}
            logger.error(f"❌ 步骤1: 用户登录异常: {e}")
        
        return result
    
    def step2_ai_gateway_test(self):
        """步骤2: AI Gateway测试"""
        logger.info("🧪 步骤2: 测试AI Gateway...")
        
        result = {
            "step": "AI Gateway测试",
            "success": False,
            "details": {}
        }
        
        try:
            response = requests.get(f"{self.ai_gateway_url}/health", timeout=10)
            
            if response.status_code == 200:
                health_data = response.json()
                if health_data.get("service") == "future-ai-gateway":
                    result["success"] = True
                    result["details"] = {
                        "status_code": response.status_code,
                        "message": "AI Gateway健康检查通过",
                        "service": health_data.get("service"),
                        "version": health_data.get("version")
                    }
                    logger.info("✅ 步骤2: AI Gateway测试通过")
                else:
                    result["details"] = {
                        "status_code": response.status_code,
                        "error": "服务名称不匹配"
                    }
                    logger.error("❌ 步骤2: AI Gateway服务名称不匹配")
            else:
                result["details"] = {
                    "status_code": response.status_code,
                    "error": "健康检查失败"
                }
                logger.error("❌ 步骤2: AI Gateway健康检查失败")
                
        except Exception as e:
            result["details"] = {"error": str(e)}
            logger.error(f"❌ 步骤2: AI Gateway测试异常: {e}")
        
        return result
    
    def step3_resume_ai_test(self):
        """步骤3: Resume AI测试"""
        logger.info("🧪 步骤3: 测试Resume AI...")
        
        result = {
            "step": "Resume AI测试",
            "success": False,
            "details": {}
        }
        
        try:
            response = requests.get(f"{self.resume_ai_url}/health", timeout=10)
            
            if response.status_code == 200:
                health_data = response.json()
                if health_data.get("service") == "future-resume-ai":
                    result["success"] = True
                    result["details"] = {
                        "status_code": response.status_code,
                        "message": "Resume AI健康检查通过",
                        "service": health_data.get("service"),
                        "version": health_data.get("version")
                    }
                    logger.info("✅ 步骤3: Resume AI测试通过")
                else:
                    result["details"] = {
                        "status_code": response.status_code,
                        "error": "服务名称不匹配"
                    }
                    logger.error("❌ 步骤3: Resume AI服务名称不匹配")
            else:
                result["details"] = {
                    "status_code": response.status_code,
                    "error": "健康检查失败"
                }
                logger.error("❌ 步骤3: Resume AI健康检查失败")
                
        except Exception as e:
            result["details"] = {"error": str(e)}
            logger.error(f"❌ 步骤3: Resume AI测试异常: {e}")
        
        return result
    
    def run_complete_flow(self):
        """运行完整端到端流程"""
        logger.info("🚀 开始运行Future版端到端流程测试...")
        
        start_time = datetime.now()
        
        # 执行所有步骤
        steps = [
            self.step1_user_login(),
            self.step2_ai_gateway_test(),
            self.step3_resume_ai_test()
        ]
        
        end_time = datetime.now()
        
        # 统计结果
        successful_steps = sum(1 for step in steps if step["success"])
        total_steps = len(steps)
        
        # 汇总结果
        summary = {
            "test_suite": "Future版端到端流程测试",
            "start_time": start_time.isoformat(),
            "end_time": end_time.isoformat(),
            "duration": str(end_time - start_time),
            "total_steps": total_steps,
            "successful_steps": successful_steps,
            "failed_steps": total_steps - successful_steps,
            "success_rate": (successful_steps / total_steps) * 100,
            "steps": steps,
            "flow_completion": successful_steps == total_steps
        }
        
        # 保存测试结果
        with open("test-results/end_to_end_flow_test_results.json", "w", encoding="utf-8") as f:
            json.dump(summary, f, ensure_ascii=False, indent=2)
        
        logger.info(f"🎉 端到端流程测试完成! 成功率: {summary['success_rate']:.1f}% ({successful_steps}/{total_steps})")
        return summary

if __name__ == "__main__":
    tester = FutureE2EEndToEndTest()
    results = tester.run_complete_flow()
    
    print("\n" + "="*60)
    print("🎯 Future版端到端流程测试结果")
    print("="*60)
    print(f"总步骤数: {results['total_steps']}")
    print(f"成功步骤: {results['successful_steps']}")
    print(f"失败步骤: {results['failed_steps']}")
    print(f"成功率: {results['success_rate']:.1f}%")
    print(f"流程完整性: {'✅ 完整' if results['flow_completion'] else '❌ 不完整'}")
    print(f"测试耗时: {results['duration']}")
    print("="*60)
    
    # 显示各步骤状态
    print("\n📋 各步骤状态:")
    for i, step in enumerate(results['steps'], 1):
        status = "✅" if step['success'] else "❌"
        print(f"  {i}. {step['step']}: {status}")
