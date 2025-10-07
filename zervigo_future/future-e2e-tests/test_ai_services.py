#!/usr/bin/env python3
"""
Future版AI服务端到端测试
"""

import json
import requests
import logging
from datetime import datetime

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class FutureE2EAIServicesTest:
    def __init__(self):
        self.ai_gateway_url = "http://localhost:7510"
        self.resume_ai_url = "http://localhost:7511"
        self.mineru_url = "http://localhost:8000"
        self.ai_models_url = "http://localhost:8002"
        
    def test_ai_gateway_health(self):
        """测试AI Gateway健康状态"""
        logger.info("🧪 开始测试AI Gateway健康状态...")
        
        results = {
            "test_name": "AI Gateway健康检查",
            "passed": 0,
            "failed": 0,
            "details": []
        }
        
        try:
            response = requests.get(f"{self.ai_gateway_url}/health", timeout=10)
            
            if response.status_code == 200:
                health_data = response.json()
                if health_data.get("service") == "future-ai-gateway":
                    results["passed"] += 1
                    results["details"].append({
                        "status": "success",
                        "message": "AI Gateway健康检查通过",
                        "service": health_data.get("service"),
                        "version": health_data.get("version")
                    })
                    logger.info("✅ AI Gateway健康检查通过")
                else:
                    results["failed"] += 1
                    results["details"].append({
                        "status": "failed",
                        "message": f"服务名称不匹配: {health_data.get('service')}"
                    })
            else:
                results["failed"] += 1
                results["details"].append({
                    "status": "failed",
                    "message": f"健康检查失败: {response.status_code}"
                })
                
        except Exception as e:
            results["failed"] += 1
            results["details"].append({
                "status": "error",
                "message": str(e)
            })
            logger.error(f"❌ AI Gateway健康检查异常: {e}")
        
        results["success_rate"] = results["passed"] / (results["passed"] + results["failed"]) * 100 if (results["passed"] + results["failed"]) > 0 else 0
        return results
    
    def test_resume_ai_health(self):
        """测试Resume AI健康状态"""
        logger.info("🧪 开始测试Resume AI健康状态...")
        
        results = {
            "test_name": "Resume AI健康检查",
            "passed": 0,
            "failed": 0,
            "details": []
        }
        
        try:
            response = requests.get(f"{self.resume_ai_url}/health", timeout=10)
            
            if response.status_code == 200:
                health_data = response.json()
                if health_data.get("service") == "future-resume-ai":
                    results["passed"] += 1
                    results["details"].append({
                        "status": "success",
                        "message": "Resume AI健康检查通过",
                        "service": health_data.get("service"),
                        "version": health_data.get("version")
                    })
                    logger.info("✅ Resume AI健康检查通过")
                else:
                    results["failed"] += 1
                    results["details"].append({
                        "status": "failed",
                        "message": f"服务名称不匹配: {health_data.get('service')}"
                    })
            else:
                results["failed"] += 1
                results["details"].append({
                    "status": "failed",
                    "message": f"健康检查失败: {response.status_code}"
                })
                
        except Exception as e:
            results["failed"] += 1
            results["details"].append({
                "status": "error",
                "message": str(e)
            })
            logger.error(f"❌ Resume AI健康检查异常: {e}")
        
        results["success_rate"] = results["passed"] / (results["passed"] + results["failed"]) * 100 if (results["passed"] + results["failed"]) > 0 else 0
        return results
    
    def run_all_tests(self):
        """运行所有AI服务测试"""
        logger.info("🚀 开始运行Future版AI服务端到端测试...")
        
        start_time = datetime.now()
        
        # 执行测试
        test_results = [
            self.test_ai_gateway_health(),
            self.test_resume_ai_health()
        ]
        
        end_time = datetime.now()
        
        # 汇总结果
        summary = {
            "test_suite": "Future版AI服务端到端测试",
            "start_time": start_time.isoformat(),
            "end_time": end_time.isoformat(),
            "duration": str(end_time - start_time),
            "total_tests": len(test_results),
            "passed_tests": 0,
            "failed_tests": 0,
            "test_results": test_results
        }
        
        # 计算总体成功率
        for result in test_results:
            if result["success_rate"] >= 80:
                summary["passed_tests"] += 1
            else:
                summary["failed_tests"] += 1
        
        summary["overall_success_rate"] = summary["passed_tests"] / summary["total_tests"] * 100
        
        # 保存测试结果
        with open("test-results/ai_services_test_results.json", "w", encoding="utf-8") as f:
            json.dump(summary, f, ensure_ascii=False, indent=2)
        
        logger.info(f"🎉 AI服务测试完成! 总体成功率: {summary['overall_success_rate']:.1f}%")
        return summary

if __name__ == "__main__":
    tester = FutureE2EAIServicesTest()
    results = tester.run_all_tests()
    
    print("\n" + "="*60)
    print("🎯 Future版AI服务端到端测试结果")
    print("="*60)
    print(f"总测试数: {results['total_tests']}")
    print(f"通过测试: {results['passed_tests']}")
    print(f"失败测试: {results['failed_tests']}")
    print(f"总体成功率: {results['overall_success_rate']:.1f}%")
    print(f"测试耗时: {results['duration']}")
    print("="*60)
