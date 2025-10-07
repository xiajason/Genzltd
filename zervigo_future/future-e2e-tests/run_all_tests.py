#!/usr/bin/env python3
"""
Future版端到端测试主执行脚本
"""

import json
import logging
from datetime import datetime
from test_user_authentication import FutureE2EAuthenticationTest
from test_ai_services import FutureE2EAIServicesTest
from test_end_to_end_flow import FutureE2EEndToEndTest

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class FutureE2ETestRunner:
    def __init__(self):
        self.test_results = {}
        self.start_time = None
        self.end_time = None
        
    def run_authentication_tests(self):
        """运行用户认证测试"""
        logger.info("🚀 开始运行用户认证测试...")
        tester = FutureE2EAuthenticationTest()
        results = tester.run_all_tests()
        return results
    
    def run_ai_services_tests(self):
        """运行AI服务测试"""
        logger.info("🚀 开始运行AI服务测试...")
        tester = FutureE2EAIServicesTest()
        results = tester.run_all_tests()
        return results
    
    def run_end_to_end_tests(self):
        """运行端到端流程测试"""
        logger.info("🚀 开始运行端到端流程测试...")
        tester = FutureE2EEndToEndTest()
        results = tester.run_complete_flow()
        return results
    
    def generate_comprehensive_report(self):
        """生成综合测试报告"""
        logger.info("📊 生成综合测试报告...")
        
        # 计算总体统计
        total_tests = 0
        total_passed = 0
        total_failed = 0
        
        # 统计各测试套件
        test_suites = []
        
        if "authentication" in self.test_results:
            auth_results = self.test_results["authentication"]
            test_suites.append({
                "name": "用户认证测试",
                "passed": auth_results["passed_tests"],
                "failed": auth_results["failed_tests"],
                "total": auth_results["total_tests"],
                "success_rate": auth_results["overall_success_rate"]
            })
            total_tests += auth_results["total_tests"]
            total_passed += auth_results["passed_tests"]
            total_failed += auth_results["failed_tests"]
        
        if "ai_services" in self.test_results:
            ai_results = self.test_results["ai_services"]
            test_suites.append({
                "name": "AI服务测试",
                "passed": ai_results["passed_tests"],
                "failed": ai_results["failed_tests"],
                "total": ai_results["total_tests"],
                "success_rate": ai_results["overall_success_rate"]
            })
            total_tests += ai_results["total_tests"]
            total_passed += ai_results["passed_tests"]
            total_failed += ai_results["failed_tests"]
        
        if "end_to_end" in self.test_results:
            e2e_results = self.test_results["end_to_end"]
            test_suites.append({
                "name": "端到端流程测试",
                "passed": e2e_results["successful_steps"],
                "failed": e2e_results["failed_steps"],
                "total": e2e_results["total_steps"],
                "success_rate": e2e_results["success_rate"]
            })
            total_tests += e2e_results["total_steps"]
            total_passed += e2e_results["successful_steps"]
            total_failed += e2e_results["failed_steps"]
        
        # 生成综合报告
        overall_success_rate = (total_passed / total_tests * 100) if total_tests > 0 else 0
        
        comprehensive_report = {
            "report_metadata": {
                "test_suite": "JobFirst Future版端到端功能测试综合报告",
                "generated_at": datetime.now().isoformat(),
                "test_duration": str(self.end_time - self.start_time) if self.start_time and self.end_time else "N/A",
                "test_environment": "Future版开发环境"
            },
            "overall_summary": {
                "total_tests": total_tests,
                "total_passed": total_passed,
                "total_failed": total_failed,
                "overall_success_rate": overall_success_rate,
                "test_status": "✅ PASS" if overall_success_rate >= 90 else "⚠️ PARTIAL" if overall_success_rate >= 70 else "❌ FAIL"
            },
            "test_suites": test_suites,
            "detailed_results": self.test_results
        }
        
        return comprehensive_report
    
    def run_all_tests(self):
        """运行所有测试"""
        logger.info("🚀 开始运行Future版端到端功能测试套件...")
        
        self.start_time = datetime.now()
        
        try:
            # 运行用户认证测试
            logger.info("=" * 60)
            logger.info("🧪 阶段1: 用户认证测试")
            logger.info("=" * 60)
            self.test_results["authentication"] = self.run_authentication_tests()
            
            # 运行AI服务测试
            logger.info("=" * 60)
            logger.info("🧪 阶段2: AI服务测试")
            logger.info("=" * 60)
            self.test_results["ai_services"] = self.run_ai_services_tests()
            
            # 运行端到端流程测试
            logger.info("=" * 60)
            logger.info("🧪 阶段3: 端到端流程测试")
            logger.info("=" * 60)
            self.test_results["end_to_end"] = self.run_end_to_end_tests()
            
        except Exception as e:
            logger.error(f"❌ 测试执行过程中发生异常: {e}")
        
        self.end_time = datetime.now()
        
        # 生成综合报告
        comprehensive_report = self.generate_comprehensive_report()
        
        # 保存综合报告
        with open("test-results/comprehensive_test_report.json", "w", encoding="utf-8") as f:
            json.dump(comprehensive_report, f, ensure_ascii=False, indent=2)
        
        return comprehensive_report

if __name__ == "__main__":
    runner = FutureE2ETestRunner()
    report = runner.run_all_tests()
    
    print("\n" + "="*80)
    print("🎯 JobFirst Future版端到端功能测试综合报告")
    print("="*80)
    print(f"测试时间: {report['report_metadata']['generated_at']}")
    print(f"测试耗时: {report['report_metadata']['test_duration']}")
    print(f"测试环境: {report['report_metadata']['test_environment']}")
    print("")
    print("📊 总体统计:")
    print(f"  总测试数: {report['overall_summary']['total_tests']}")
    print(f"  通过测试: {report['overall_summary']['total_passed']}")
    print(f"  失败测试: {report['overall_summary']['total_failed']}")
    print(f"  成功率: {report['overall_summary']['overall_success_rate']:.1f}%")
    print(f"  测试状态: {report['overall_summary']['test_status']}")
    print("")
    print("📋 各测试套件:")
    for suite in report['test_suites']:
        print(f"  {suite['name']}: {suite['passed']}/{suite['total']} ({suite['success_rate']:.1f}%)")
    print("="*80)
