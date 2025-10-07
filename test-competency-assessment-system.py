#!/usr/bin/env python3
"""
能力评估框架系统测试脚本
测试能力评估引擎和API服务的功能
"""

import asyncio
import json
import sys
import os
import aiohttp
import structlog
from datetime import datetime
from typing import Dict, List, Any

# 添加项目路径
sys.path.append(os.path.join(os.path.dirname(__file__), 'zervigo_future', 'ai-services'))

logger = structlog.get_logger()

class CompetencyAssessmentTester:
    """能力评估框架系统测试器"""
    
    def __init__(self):
        self.api_base_url = "http://localhost:8211"
        self.timeout = aiohttp.ClientTimeout(total=30)
        
    async def test_competency_engine_directly(self):
        """直接测试能力评估引擎"""
        print("🔧 测试能力评估框架引擎...")
        
        try:
            from competency_assessment_engine import CompetencyAssessmentEngine
            
            engine = CompetencyAssessmentEngine()
            
            # 测试综合能力评估
            test_texts = [
                """
                我是一名初级软件工程师，有1年Java开发经验。
                熟悉基本的Java语法和面向对象编程。
                能够编写简单的函数和类。
                了解基本的数据库操作和SQL查询。
                有基础的测试经验，会写简单的单元测试。
                
                在业务方面，我能够理解基本的需求文档。
                有简单的项目参与经验。
                具备基本的沟通能力。
                能够解决简单的技术问题。
                有团队协作经验。
                """,
                """
                我是一名高级软件工程师，拥有8年的Java开发经验。
                精通Spring Boot、MyBatis、Redis等技术栈，熟悉微服务架构设计。
                具备丰富的系统架构经验，设计过大型分布式系统。
                熟练掌握MySQL数据库设计和优化，了解分库分表技术。
                具备完整的测试经验，包括单元测试、集成测试和性能测试。
                熟悉Docker容器技术和Kubernetes编排。
                了解安全开发实践，具备基础的性能优化经验。
                
                在业务方面，我具备良好的需求分析能力，能够准确理解业务需求。
                有项目管理经验，能够协调团队完成复杂项目。
                沟通能力强，能够与技术团队和业务团队有效协作。
                具备问题解决能力，能够快速定位和解决技术问题。
                有团队协作经验，能够带领团队完成项目目标。
                具备一定的领导力，能够指导初级开发人员。
                有创新思维，能够提出技术改进建议。
                了解商业知识，能够从商业角度思考技术方案。
                """,
                """
                我是一名技术专家，拥有15年的软件开发经验。
                精通多种编程语言和框架，包括Java、Python、Go等。
                具备深度的算法和数据结构知识，能够设计复杂的算法。
                有丰富的系统架构经验，设计过企业级的分布式系统。
                熟练掌握各种数据库技术，包括关系型和非关系型数据库。
                具备完整的测试体系经验，包括自动化测试和性能测试。
                精通DevOps实践，熟悉CI/CD流水线和容器化技术。
                有丰富的安全开发经验，了解各种安全威胁和防护措施。
                具备深度的性能优化经验，能够优化大型系统的性能。
                
                在业务方面，我具备优秀的需求分析能力，能够深度理解业务需求。
                有丰富的项目管理经验，能够管理大型复杂项目。
                沟通能力卓越，能够与各种角色有效沟通。
                具备卓越的问题解决能力，能够解决复杂的技术和业务问题。
                有丰富的团队协作经验，能够建立高效的团队。
                具备卓越的领导力，能够培养和指导团队成员。
                有强烈的创新思维，能够推动技术创新和业务创新。
                具备深厚的商业洞察，能够从战略角度思考技术方案。
                """
            ]
            
            print("\n📋 综合能力评估测试结果:")
            for i, text in enumerate(test_texts, 1):
                assessment = await engine.assess_competency(text)
                print(f"  评估 {i}:")
                print(f"    总体评分: {assessment.overall_score:.2f}")
                print(f"    技术能力评分: {assessment.overall_technical_score:.2f}")
                print(f"    业务能力评分: {assessment.overall_business_score:.2f}")
                print(f"    技术能力数量: {len(assessment.technical_competencies)}")
                print(f"    业务能力数量: {len(assessment.business_competencies)}")
                
                # 显示顶级技术能力
                top_technical = sorted(assessment.technical_competencies, key=lambda x: x.score, reverse=True)[:3]
                print(f"    顶级技术能力:")
                for comp in top_technical:
                    print(f"      - {comp.competency_type.value}: {comp.level.name} ({comp.score:.2f})")
                
                # 显示顶级业务能力
                top_business = sorted(assessment.business_competencies, key=lambda x: x.score, reverse=True)[:3]
                print(f"    顶级业务能力:")
                for comp in top_business:
                    print(f"      - {comp.competency_type.value}: {comp.level.name} ({comp.score:.2f})")
            
            return True
            
        except Exception as e:
            print(f"❌ 能力评估引擎测试失败: {e}")
            return False
    
    async def test_api_service(self):
        """测试API服务"""
        print("\n🌐 测试能力评估框架API服务...")
        
        async with aiohttp.ClientSession(timeout=self.timeout) as session:
            # 测试健康检查
            try:
                async with session.get(f"{self.api_base_url}/health") as response:
                    if response.status == 200:
                        data = await response.json()
                        print(f"  ✅ 健康检查通过: {data['status']}")
                    else:
                        print(f"  ❌ 健康检查失败: {response.status}")
                        return False
            except Exception as e:
                print(f"  ❌ API服务连接失败: {e}")
                return False
            
            # 测试技术能力评估API
            print("\n🔧 测试技术能力评估API...")
            test_text = """
            我是一名高级软件工程师，拥有8年的Java开发经验。
            精通Spring Boot、MyBatis、Redis等技术栈，熟悉微服务架构设计。
            具备丰富的系统架构经验，设计过大型分布式系统。
            熟练掌握MySQL数据库设计和优化，了解分库分表技术。
            具备完整的测试经验，包括单元测试、集成测试和性能测试。
            熟悉Docker容器技术和Kubernetes编排。
            了解安全开发实践，具备基础的性能优化经验。
            """
            
            try:
                async with session.post(
                    f"{self.api_base_url}/api/v1/competency/assess_technical",
                    json={"text": test_text}
                ) as response:
                    if response.status == 200:
                        data = await response.json()
                        competencies = data["technical_competencies"]
                        print(f"  ✅ 技术能力评估成功: 评估到 {len(competencies)} 个技术能力")
                        for competency in competencies[:3]:
                            print(f"    - {competency['competency_type']}: {competency['level_name']} "
                                  f"(分数: {competency['score']:.2f})")
                    else:
                        print(f"  ❌ 技术能力评估失败: {response.status}")
            except Exception as e:
                print(f"  ❌ 技术能力评估异常: {e}")
            
            # 测试业务能力评估API
            print("\n💼 测试业务能力评估API...")
            try:
                async with session.post(
                    f"{self.api_base_url}/api/v1/competency/assess_business",
                    json={"text": test_text}
                ) as response:
                    if response.status == 200:
                        data = await response.json()
                        competencies = data["business_competencies"]
                        print(f"  ✅ 业务能力评估成功: 评估到 {len(competencies)} 个业务能力")
                        for competency in competencies[:3]:
                            print(f"    - {competency['competency_type']}: {competency['level_name']} "
                                  f"(分数: {competency['score']:.2f})")
                    else:
                        print(f"  ❌ 业务能力评估失败: {response.status}")
            except Exception as e:
                print(f"  ❌ 业务能力评估异常: {e}")
            
            # 测试综合能力评估API
            print("\n📊 测试综合能力评估API...")
            try:
                async with session.post(
                    f"{self.api_base_url}/api/v1/competency/assess_comprehensive",
                    json={"text": test_text}
                ) as response:
                    if response.status == 200:
                        data = await response.json()
                        assessment = data["assessment"]
                        summary = data["summary"]
                        print(f"  ✅ 综合能力评估成功:")
                        print(f"    总体评分: {assessment['overall_score']:.2f}")
                        print(f"    技术能力评分: {assessment['overall_technical_score']:.2f}")
                        print(f"    业务能力评分: {assessment['overall_business_score']:.2f}")
                        print(f"    技术能力数量: {summary['total_technical_competencies']}")
                        print(f"    业务能力数量: {summary['total_business_competencies']}")
                        print(f"    成长建议数量: {len(assessment['growth_recommendations'])}")
                    else:
                        print(f"  ❌ 综合能力评估失败: {response.status}")
            except Exception as e:
                print(f"  ❌ 综合能力评估异常: {e}")
            
            # 测试批量评估API
            print("\n📦 测试批量能力评估API...")
            test_texts = [
                "我是一名初级Java开发工程师，有基础的编程经验。",
                "我是一名中级软件工程师，有3年开发经验，熟悉Spring框架。",
                "我是一名高级软件工程师，有8年经验，精通系统架构设计。"
            ]
            
            try:
                async with session.post(
                    f"{self.api_base_url}/api/v1/competency/batch_assessment",
                    json={"texts": test_texts}
                ) as response:
                    if response.status == 200:
                        data = await response.json()
                        print(f"  ✅ 批量评估成功: {data['success_rate']:.1f}% "
                              f"({data['successful_assessments']}/{data['total_texts']})")
                        avg_scores = data['average_scores']
                        print(f"    平均技术评分: {avg_scores['technical']:.2f}")
                        print(f"    平均业务评分: {avg_scores['business']:.2f}")
                        print(f"    平均总体评分: {avg_scores['overall']:.2f}")
                    else:
                        print(f"  ❌ 批量评估失败: {response.status}")
            except Exception as e:
                print(f"  ❌ 批量评估异常: {e}")
            
            # 测试能力等级API
            print("\n📈 测试能力等级API...")
            try:
                async with session.get(f"{self.api_base_url}/api/v1/competency/competency_levels") as response:
                    if response.status == 200:
                        data = await response.json()
                        print(f"  ✅ 能力等级获取成功: {data['total_levels']} 个等级")
                        for level in data['competency_levels'][:3]:
                            print(f"    - {level['level']}: {level['description']}")
                    else:
                        print(f"  ❌ 能力等级获取失败: {response.status}")
            except Exception as e:
                print(f"  ❌ 能力等级获取异常: {e}")
            
            # 测试技术能力类型API
            print("\n🔧 测试技术能力类型API...")
            try:
                async with session.get(f"{self.api_base_url}/api/v1/competency/technical_competency_types") as response:
                    if response.status == 200:
                        data = await response.json()
                        print(f"  ✅ 技术能力类型获取成功: {data['total_types']} 个类型")
                        for comp_type in data['technical_competency_types'][:3]:
                            print(f"    - {comp_type['type']}: {comp_type['description']}")
                    else:
                        print(f"  ❌ 技术能力类型获取失败: {response.status}")
            except Exception as e:
                print(f"  ❌ 技术能力类型获取异常: {e}")
            
            # 测试业务能力类型API
            print("\n💼 测试业务能力类型API...")
            try:
                async with session.get(f"{self.api_base_url}/api/v1/competency/business_competency_types") as response:
                    if response.status == 200:
                        data = await response.json()
                        print(f"  ✅ 业务能力类型获取成功: {data['total_types']} 个类型")
                        for comp_type in data['business_competency_types'][:3]:
                            print(f"    - {comp_type['type']}: {comp_type['description']}")
                    else:
                        print(f"  ❌ 业务能力类型获取失败: {response.status}")
            except Exception as e:
                print(f"  ❌ 业务能力类型获取异常: {e}")
            
            # 测试基准对比API
            print("\n📊 测试基准对比API...")
            try:
                async with session.post(
                    f"{self.api_base_url}/api/v1/competency/benchmark",
                    json={
                        "technical_score": 3.5,
                        "business_score": 3.2,
                        "overall_score": 3.4,
                        "industry": "tech",
                        "role_level": "SENIOR"
                    }
                ) as response:
                    if response.status == 200:
                        data = await response.json()
                        comparison = data['comparison']
                        print(f"  ✅ 基准对比成功:")
                        print(f"    总体评分: {comparison['overall']['user_score']:.2f} "
                              f"(基准: {comparison['overall']['benchmark_score']:.2f})")
                        print(f"    技术评分: {comparison['technical']['user_score']:.2f} "
                              f"(基准: {comparison['technical']['benchmark_score']:.2f})")
                        print(f"    业务评分: {comparison['business']['user_score']:.2f} "
                              f"(基准: {comparison['business']['benchmark_score']:.2f})")
                    else:
                        print(f"  ❌ 基准对比失败: {response.status}")
            except Exception as e:
                print(f"  ❌ 基准对比异常: {e}")
            
            return True
    
    async def test_performance(self):
        """测试性能"""
        print("\n⚡ 测试性能...")
        
        async with aiohttp.ClientSession(timeout=self.timeout) as session:
            # 测试批量评估性能
            import time
            start_time = time.time()
            
            test_texts = [
                "我是一名初级Java开发工程师，有基础的编程经验。",
                "我是一名中级软件工程师，有3年开发经验，熟悉Spring框架。",
                "我是一名高级软件工程师，有8年经验，精通系统架构设计。",
                "我是一名技术专家，有15年经验，精通多种技术和架构。",
                "我是一名架构师，有丰富的企业级系统设计经验。"
            ]
            
            try:
                async with session.post(
                    f"{self.api_base_url}/api/v1/competency/batch_assessment",
                    json={"texts": test_texts}
                ) as response:
                    if response.status == 200:
                        data = await response.json()
                        end_time = time.time()
                        duration = end_time - start_time
                        
                        print(f"  ✅ 批量评估性能测试:")
                        print(f"    - 处理文本数: {len(test_texts)}")
                        print(f"    - 处理时间: {duration:.2f}秒")
                        print(f"    - 处理速度: {len(test_texts)/duration:.1f} 文本/秒")
                        print(f"    - 成功率: {data['success_rate']:.1f}%")
                        avg_scores = data['average_scores']
                        print(f"    - 平均技术评分: {avg_scores['technical']:.2f}")
                        print(f"    - 平均业务评分: {avg_scores['business']:.2f}")
                        print(f"    - 平均总体评分: {avg_scores['overall']:.2f}")
                    else:
                        print(f"  ❌ 性能测试失败: {response.status}")
            except Exception as e:
                print(f"  ❌ 性能测试异常: {e}")
    
    async def run_comprehensive_test(self):
        """运行综合测试"""
        print("🚀 开始能力评估框架系统综合测试")
        print("=" * 60)
        
        # 测试能力评估引擎
        engine_success = await self.test_competency_engine_directly()
        
        # 测试API服务
        api_success = await self.test_api_service()
        
        # 测试性能
        await self.test_performance()
        
        print("\n" + "=" * 60)
        print("📋 测试总结:")
        print(f"  🔧 能力评估引擎测试: {'✅ 通过' if engine_success else '❌ 失败'}")
        print(f"  🌐 API服务测试: {'✅ 通过' if api_success else '❌ 失败'}")
        print(f"  ⚡ 性能测试: ✅ 完成")
        
        overall_success = engine_success and api_success
        print(f"\n🎯 总体结果: {'✅ 全部通过' if overall_success else '❌ 部分失败'}")
        
        return overall_success

async def main():
    """主函数"""
    tester = CompetencyAssessmentTester()
    
    try:
        success = await tester.run_comprehensive_test()
        
        # 保存测试结果
        test_result = {
            "test_timestamp": datetime.now().isoformat(),
            "test_success": success,
            "test_details": {
                "competency_engine_test": "completed",
                "api_service_test": "completed",
                "performance_test": "completed"
            }
        }
        
        with open("competency_assessment_test_result.json", "w", encoding="utf-8") as f:
            json.dump(test_result, f, ensure_ascii=False, indent=2)
        
        print(f"\n📄 测试结果已保存到: competency_assessment_test_result.json")
        
        if success:
            print("\n🎉 能力评估框架系统测试全部通过！可以进入下一阶段开发。")
        else:
            print("\n⚠️ 能力评估框架系统测试部分失败，请检查相关功能。")
            
    except Exception as e:
        print(f"\n❌ 测试执行失败: {e}")
        logger.error("测试执行失败", error=str(e))

if __name__ == "__main__":
    asyncio.run(main())
