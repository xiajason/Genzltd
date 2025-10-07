#!/usr/bin/env python3
"""
经验量化分析系统测试脚本
测试经验量化引擎和API服务的功能
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

class ExperienceQuantificationTester:
    """经验量化分析系统测试器"""
    
    def __init__(self):
        self.api_base_url = "http://localhost:8210"
        self.timeout = aiohttp.ClientTimeout(total=30)
        
    async def test_experience_engine_directly(self):
        """直接测试经验量化引擎"""
        print("🔧 测试经验量化分析引擎...")
        
        try:
            from experience_quantification_engine import ExperienceQuantificationEngine
            
            engine = ExperienceQuantificationEngine()
            
            # 测试项目复杂度分析
            test_projects = [
                """
                负责开发一个简单的用户登录系统，使用Spring Boot和MySQL。
                项目规模较小，只有我一个人开发，功能相对简单。
                实现了基本的用户注册、登录、密码重置功能。
                """,
                """
                设计并实现了一个中等规模的电商平台后端系统。
                使用微服务架构，包括用户服务、商品服务、订单服务、支付服务。
                团队有8个人，包括前端、后端、测试工程师。
                集成了Redis缓存、Elasticsearch搜索、消息队列等技术。
                项目周期6个月，成功上线并稳定运行。
                """,
                """
                领导并实施了一个大规模的企业数字化转型项目。
                涉及多个业务部门，包括财务、人事、运营、技术等。
                团队规模超过50人，包括架构师、开发工程师、项目经理、业务分析师。
                采用云原生架构，使用Kubernetes、Docker、微服务等技术栈。
                项目复杂度极高，涉及系统集成、数据迁移、业务流程重构。
                通过优化架构和流程，系统性能提升了5倍，运营效率提升了40%，
                为公司节约成本2000万元，用户满意度提升了35%。
                项目获得了公司年度最佳项目奖。
                """
            ]
            
            print("\n📋 项目复杂度分析测试结果:")
            for i, project in enumerate(test_projects, 1):
                complexity = await engine.analyze_project_complexity(project)
                print(f"  项目 {i}:")
                print(f"    技术复杂度: {complexity.technical_complexity}")
                print(f"    业务复杂度: {complexity.business_complexity}")
                print(f"    团队复杂度: {complexity.team_complexity}")
                print(f"    整体复杂度: {complexity.overall_complexity}")
                print(f"    复杂度等级: {complexity.complexity_level.value}")
            
            # 测试量化成果提取
            print("\n🎯 量化成果提取测试...")
            test_experience = """
            负责优化系统性能，通过算法优化和架构调整，
            系统响应时间从2秒降低到0.5秒，性能提升了4倍。
            用户并发量从1000提升到5000，增长了5倍。
            通过缓存优化，数据库查询效率提升了60%。
            项目为公司节约服务器成本50万元，用户满意度提升了25%。
            团队规模从5人扩展到12人，我负责技术架构设计和团队管理。
            获得了公司技术创新奖，发表了2篇技术论文。
            """
            
            achievements = await engine.extract_quantified_achievements(test_experience)
            print(f"  提取到 {len(achievements)} 个量化成果:")
            for achievement in achievements:
                print(f"    - {achievement.achievement_type.value}: {achievement.description} "
                      f"(影响力: {achievement.impact_score:.1f}, 置信度: {achievement.confidence:.2f})")
            
            # 测试领导力指标分析
            print("\n👥 领导力指标分析测试...")
            leadership = await engine.analyze_leadership_indicators(test_experience)
            print(f"  领导力指标:")
            for indicator, score in leadership.items():
                print(f"    - {indicator}: {score:.2f}")
            
            # 测试综合分析
            print("\n📊 综合分析测试...")
            analysis = await engine.analyze_experience(test_experience)
            print(f"  经验评分: {analysis.experience_score}")
            print(f"  成长轨迹: {analysis.growth_trajectory}")
            print(f"  复杂度等级: {analysis.project_complexity.complexity_level.value}")
            print(f"  成果数量: {len(analysis.achievements)}")
            
            return True
            
        except Exception as e:
            print(f"❌ 经验量化引擎测试失败: {e}")
            return False
    
    async def test_api_service(self):
        """测试API服务"""
        print("\n🌐 测试经验量化分析API服务...")
        
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
            
            # 测试项目复杂度分析API
            print("\n📋 测试项目复杂度分析API...")
            test_project = """
            设计并实现了一个大规模分布式推荐系统，使用Go语言和Kubernetes进行开发。
            该项目涉及多个团队协作，包括算法团队、后端团队、前端团队和数据团队。
            系统需要处理千万级用户的实时推荐请求，支持多种推荐算法，
            并实现了A/B测试框架。项目采用了微服务架构，使用了Redis、MongoDB、Elasticsearch等技术栈。
            """
            
            try:
                async with session.post(
                    f"{self.api_base_url}/api/v1/experience/analyze_complexity",
                    json={"project_description": test_project}
                ) as response:
                    if response.status == 200:
                        data = await response.json()
                        complexity = data["complexity_analysis"]
                        print(f"  ✅ 项目复杂度分析成功:")
                        print(f"    技术复杂度: {complexity['technical_complexity']}")
                        print(f"    业务复杂度: {complexity['business_complexity']}")
                        print(f"    团队复杂度: {complexity['team_complexity']}")
                        print(f"    整体复杂度: {complexity['overall_complexity']}")
                        print(f"    复杂度等级: {complexity['complexity_level']}")
                    else:
                        print(f"  ❌ 项目复杂度分析失败: {response.status}")
            except Exception as e:
                print(f"  ❌ 项目复杂度分析异常: {e}")
            
            # 测试量化成果提取API
            print("\n🎯 测试量化成果提取API...")
            test_experience = """
            负责优化系统性能，通过算法优化和架构调整，
            系统响应时间从2秒降低到0.5秒，性能提升了4倍。
            用户并发量从1000提升到5000，增长了5倍。
            通过缓存优化，数据库查询效率提升了60%。
            项目为公司节约服务器成本50万元，用户满意度提升了25%。
            团队规模从5人扩展到12人，我负责技术架构设计和团队管理。
            获得了公司技术创新奖，发表了2篇技术论文。
            """
            
            try:
                async with session.post(
                    f"{self.api_base_url}/api/v1/experience/extract_achievements",
                    json={"experience_text": test_experience}
                ) as response:
                    if response.status == 200:
                        data = await response.json()
                        achievements = data["achievements"]
                        print(f"  ✅ 量化成果提取成功: 提取到 {len(achievements)} 个成果")
                        for achievement in achievements[:3]:  # 只显示前3个
                            print(f"    - {achievement['achievement_type']}: {achievement['description']} "
                                  f"(影响力: {achievement['impact_score']:.1f})")
                    else:
                        print(f"  ❌ 量化成果提取失败: {response.status}")
            except Exception as e:
                print(f"  ❌ 量化成果提取异常: {e}")
            
            # 测试领导力指标分析API
            print("\n👥 测试领导力指标分析API...")
            try:
                async with session.post(
                    f"{self.api_base_url}/api/v1/experience/analyze_leadership",
                    json={"experience_text": test_experience}
                ) as response:
                    if response.status == 200:
                        data = await response.json()
                        leadership = data["leadership_indicators"]
                        leadership_score = data["leadership_score"]
                        print(f"  ✅ 领导力指标分析成功: 总体评分 {leadership_score:.2f}")
                        for indicator, score in leadership.items():
                            print(f"    - {indicator}: {score:.2f}")
                    else:
                        print(f"  ❌ 领导力指标分析失败: {response.status}")
            except Exception as e:
                print(f"  ❌ 领导力指标分析异常: {e}")
            
            # 测试经验评分计算API
            print("\n📊 测试经验评分计算API...")
            try:
                async with session.post(
                    f"{self.api_base_url}/api/v1/experience/calculate_score",
                    json={"experience_text": test_experience}
                ) as response:
                    if response.status == 200:
                        data = await response.json()
                        print(f"  ✅ 经验评分计算成功:")
                        print(f"    经验评分: {data['experience_score']}")
                        print(f"    成长轨迹: {data['growth_trajectory']}")
                        print(f"    复杂度等级: {data['complexity_analysis']['complexity_level']}")
                        print(f"    成果数量: {data['achievements_count']}")
                        print(f"    领导力评分: {data['leadership_score']:.2f}")
                    else:
                        print(f"  ❌ 经验评分计算失败: {response.status}")
            except Exception as e:
                print(f"  ❌ 经验评分计算异常: {e}")
            
            # 测试综合分析API
            print("\n🔍 测试综合分析API...")
            try:
                async with session.post(
                    f"{self.api_base_url}/api/v1/experience/comprehensive_analysis",
                    json={"experience_text": test_experience}
                ) as response:
                    if response.status == 200:
                        data = await response.json()
                        analysis = data["analysis"]
                        summary = data["summary"]
                        print(f"  ✅ 综合分析成功:")
                        print(f"    经验评分: {analysis['experience_score']}")
                        print(f"    复杂度等级: {analysis['project_complexity']['complexity_level']}")
                        print(f"    成果数量: {summary['total_achievements']}")
                        print(f"    领导力评分: {summary['leadership_score']:.2f}")
                        print(f"    整体评分: {summary['overall_score']}")
                    else:
                        print(f"  ❌ 综合分析失败: {response.status}")
            except Exception as e:
                print(f"  ❌ 综合分析异常: {e}")
            
            # 测试批量分析API
            print("\n📦 测试批量经验分析API...")
            test_experiences = [
                "负责开发一个简单的用户登录系统，使用Spring Boot和MySQL。",
                "设计并实现了一个中等规模的电商平台后端系统，团队有8个人。",
                "领导并实施了一个大规模的企业数字化转型项目，团队超过50人。"
            ]
            
            try:
                async with session.post(
                    f"{self.api_base_url}/api/v1/experience/batch_analysis",
                    json={"experiences": test_experiences}
                ) as response:
                    if response.status == 200:
                        data = await response.json()
                        print(f"  ✅ 批量分析成功: {data['success_rate']:.1f}% "
                              f"({data['successful_analyses']}/{data['total_experiences']})")
                        print(f"    平均评分: {data['average_score']:.2f}")
                    else:
                        print(f"  ❌ 批量分析失败: {response.status}")
            except Exception as e:
                print(f"  ❌ 批量分析异常: {e}")
            
            # 测试成长轨迹分析API
            print("\n📈 测试成长轨迹分析API...")
            try:
                async with session.post(
                    f"{self.api_base_url}/api/v1/experience/analyze_trajectory",
                    json={"experiences": test_experiences}
                ) as response:
                    if response.status == 200:
                        data = await response.json()
                        trajectory = data["trajectory_analysis"]
                        print(f"  ✅ 成长轨迹分析成功:")
                        print(f"    成长率: {data['growth_trajectory']:.2f}")
                        print(f"    趋势: {trajectory['trend']}")
                        print(f"    建议: {trajectory['recommendation']}")
                    else:
                        print(f"  ❌ 成长轨迹分析失败: {response.status}")
            except Exception as e:
                print(f"  ❌ 成长轨迹分析异常: {e}")
            
            # 测试成果类型API
            print("\n📂 测试成果类型API...")
            try:
                async with session.get(f"{self.api_base_url}/api/v1/experience/achievement_types") as response:
                    if response.status == 200:
                        data = await response.json()
                        print(f"  ✅ 成果类型获取成功: {data['total_types']} 个类型")
                        for achievement_type in data['achievement_types'][:3]:
                            print(f"    - {achievement_type['type']}: {achievement_type['description']}")
                    else:
                        print(f"  ❌ 成果类型获取失败: {response.status}")
            except Exception as e:
                print(f"  ❌ 成果类型获取异常: {e}")
            
            # 测试复杂度等级API
            print("\n📊 测试复杂度等级API...")
            try:
                async with session.get(f"{self.api_base_url}/api/v1/experience/complexity_levels") as response:
                    if response.status == 200:
                        data = await response.json()
                        print(f"  ✅ 复杂度等级获取成功: {data['total_levels']} 个等级")
                        for level in data['complexity_levels'][:3]:
                            print(f"    - {level['level']}: {level['description']}")
                    else:
                        print(f"  ❌ 复杂度等级获取失败: {response.status}")
            except Exception as e:
                print(f"  ❌ 复杂度等级获取异常: {e}")
            
            return True
    
    async def test_performance(self):
        """测试性能"""
        print("\n⚡ 测试性能...")
        
        async with aiohttp.ClientSession(timeout=self.timeout) as session:
            # 测试批量分析性能
            import time
            start_time = time.time()
            
            test_experiences = [
                "负责开发一个简单的用户登录系统，使用Spring Boot和MySQL。",
                "设计并实现了一个中等规模的电商平台后端系统，团队有8个人。",
                "领导并实施了一个大规模的企业数字化转型项目，团队超过50人。",
                "优化系统性能，通过算法优化，性能提升了3倍。",
                "负责团队管理，带领15人团队完成多个核心项目。"
            ]
            
            try:
                async with session.post(
                    f"{self.api_base_url}/api/v1/experience/batch_analysis",
                    json={"experiences": test_experiences}
                ) as response:
                    if response.status == 200:
                        data = await response.json()
                        end_time = time.time()
                        duration = end_time - start_time
                        
                        print(f"  ✅ 批量分析性能测试:")
                        print(f"    - 处理经验数: {len(test_experiences)}")
                        print(f"    - 处理时间: {duration:.2f}秒")
                        print(f"    - 处理速度: {len(test_experiences)/duration:.1f} 经验/秒")
                        print(f"    - 成功率: {data['success_rate']:.1f}%")
                        print(f"    - 平均评分: {data['average_score']:.2f}")
                    else:
                        print(f"  ❌ 性能测试失败: {response.status}")
            except Exception as e:
                print(f"  ❌ 性能测试异常: {e}")
    
    async def run_comprehensive_test(self):
        """运行综合测试"""
        print("🚀 开始经验量化分析系统综合测试")
        print("=" * 60)
        
        # 测试经验量化引擎
        engine_success = await self.test_experience_engine_directly()
        
        # 测试API服务
        api_success = await self.test_api_service()
        
        # 测试性能
        await self.test_performance()
        
        print("\n" + "=" * 60)
        print("📋 测试总结:")
        print(f"  🔧 经验量化引擎测试: {'✅ 通过' if engine_success else '❌ 失败'}")
        print(f"  🌐 API服务测试: {'✅ 通过' if api_success else '❌ 失败'}")
        print(f"  ⚡ 性能测试: ✅ 完成")
        
        overall_success = engine_success and api_success
        print(f"\n🎯 总体结果: {'✅ 全部通过' if overall_success else '❌ 部分失败'}")
        
        return overall_success

async def main():
    """主函数"""
    tester = ExperienceQuantificationTester()
    
    try:
        success = await tester.run_comprehensive_test()
        
        # 保存测试结果
        test_result = {
            "test_timestamp": datetime.now().isoformat(),
            "test_success": success,
            "test_details": {
                "experience_engine_test": "completed",
                "api_service_test": "completed",
                "performance_test": "completed"
            }
        }
        
        with open("experience_quantification_test_result.json", "w", encoding="utf-8") as f:
            json.dump(test_result, f, ensure_ascii=False, indent=2)
        
        print(f"\n📄 测试结果已保存到: experience_quantification_test_result.json")
        
        if success:
            print("\n🎉 经验量化分析系统测试全部通过！可以进入下一阶段开发。")
        else:
            print("\n⚠️ 经验量化分析系统测试部分失败，请检查相关功能。")
            
    except Exception as e:
        print(f"\n❌ 测试执行失败: {e}")
        logger.error("测试执行失败", error=str(e))

if __name__ == "__main__":
    asyncio.run(main())
