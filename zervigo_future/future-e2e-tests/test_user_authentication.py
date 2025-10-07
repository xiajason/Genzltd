#!/usr/bin/env python3
"""
Future版用户认证端到端测试
"""

import json
import requests
import logging
from datetime import datetime

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class FutureE2EAuthenticationTest:
    def __init__(self):
        self.base_url = "http://localhost:7500"  # 修复端口配置：从7530改为7500 (LoomaCRM)
        # 使用正确的密码
        self.test_users = [
            {"username": "admin", "password": "password"},
            {"username": "testuser", "password": "testuser123"},
            {"username": "szjason72", "password": "@SZxym2006"}
        ]
        
    def test_user_login(self):
        """测试用户登录功能"""
        logger.info("🧪 开始测试用户登录功能...")
        
        results = {
            "test_name": "用户登录测试",
            "passed": 0,
            "failed": 0,
            "tokens": [],
            "details": []
        }
        
        for user in self.test_users:
            try:
                login_data = {
                    "username": user["username"],
                    "password": user["password"]
                }
                
                response = requests.post(
                    f"{self.base_url}/api/v1/auth/login",
                    json=login_data,
                    timeout=10
                )
                
                if response.status_code == 200:
                    result = response.json()
                    if result.get("success") and result.get("data", {}).get("success"):
                        token = result.get("data", {}).get("token")
                        results["tokens"].append({"username": user["username"], "token": token})
                        results["passed"] += 1
                        results["details"].append({
                            "user": user["username"],
                            "status": "success",
                            "message": "登录成功"
                        })
                        logger.info(f"✅ 用户 {user['username']} 登录成功")
                    else:
                        results["failed"] += 1
                        results["details"].append({
                            "user": user["username"],
                            "status": "failed",
                            "message": "登录响应格式错误"
                        })
                        logger.error(f"❌ 用户 {user['username']} 登录响应格式错误")
                else:
                    results["failed"] += 1
                    results["details"].append({
                        "user": user["username"],
                        "status": "failed",
                        "message": f"登录失败: {response.status_code}"
                    })
                    logger.error(f"❌ 用户 {user['username']} 登录失败: {response.status_code}")
                    
            except Exception as e:
                results["failed"] += 1
                results["details"].append({
                    "user": user["username"],
                    "status": "error",
                    "message": str(e)
                })
                logger.error(f"❌ 用户 {user['username']} 登录异常: {e}")
        
        results["success_rate"] = results["passed"] / (results["passed"] + results["failed"]) * 100 if (results["passed"] + results["failed"]) > 0 else 0
        logger.info(f"🎯 用户登录测试完成: {results['passed']}/{results['passed'] + results['failed']} 成功")
        return results
    
    def run_all_tests(self):
        """运行所有认证测试"""
        logger.info("🚀 开始运行Future版用户认证端到端测试...")
        
        start_time = datetime.now()
        
        # 执行测试
        login_results = self.test_user_login()
        
        end_time = datetime.now()
        
        # 汇总结果
        summary = {
            "test_suite": "Future版用户认证端到端测试",
            "start_time": start_time.isoformat(),
            "end_time": end_time.isoformat(),
            "duration": str(end_time - start_time),
            "total_tests": 1,
            "passed_tests": 1 if login_results["success_rate"] >= 80 else 0,
            "failed_tests": 1 if login_results["success_rate"] < 80 else 0,
            "test_results": [login_results]
        }
        
        summary["overall_success_rate"] = summary["passed_tests"] / summary["total_tests"] * 100
        
        # 保存测试结果
        with open("test-results/authentication_test_results.json", "w", encoding="utf-8") as f:
            json.dump(summary, f, ensure_ascii=False, indent=2)
        
        logger.info(f"🎉 认证测试完成! 总体成功率: {summary['overall_success_rate']:.1f}%")
        return summary

if __name__ == "__main__":
    tester = FutureE2EAuthenticationTest()
    results = tester.run_all_tests()
    
    print("\n" + "="*60)
    print("🎯 Future版用户认证端到端测试结果")
    print("="*60)
    print(f"总测试数: {results['total_tests']}")
    print(f"通过测试: {results['passed_tests']}")
    print(f"失败测试: {results['failed_tests']}")
    print(f"总体成功率: {results['overall_success_rate']:.1f}%")
    print(f"测试耗时: {results['duration']}")
    print("="*60)
