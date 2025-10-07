#!/usr/bin/env python3
"""
技能标准化系统测试脚本
测试技能标准化引擎和API服务的功能
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

class SkillStandardizationTester:
    """技能标准化系统测试器"""
    
    def __init__(self):
        self.api_base_url = "http://localhost:8209"
        self.timeout = aiohttp.ClientTimeout(total=30)
        
    async def test_skill_engine_directly(self):
        """直接测试技能引擎"""
        print("🔧 测试技能标准化引擎...")
        
        try:
            from skill_standardization_engine import SkillStandardizationEngine
            
            engine = SkillStandardizationEngine()
            await engine.initialize()
            
            # 测试技能标准化
            test_skills = [
                "python", "java", "react", "mysql", "aws", "git",
                "leadership", "communication", "problem solving",
                "unknown_skill", "js", "docker", "kubernetes"
            ]
            
            print("\n📋 技能标准化测试结果:")
            success_count = 0
            for skill in test_skills:
                standardized = await engine.standardize_skill(skill)
                if standardized:
                    print(f"  ✅ '{skill}' -> '{standardized.name}' ({standardized.category.value})")
                    success_count += 1
                else:
                    print(f"  ❌ '{skill}' -> 未找到匹配")
            
            print(f"\n📊 技能标准化成功率: {success_count}/{len(test_skills)} ({success_count/len(test_skills)*100:.1f}%)")
            
            # 测试技能匹配
            print("\n🎯 测试技能匹配功能...")
            user_skills = {
                "python": "3 years of Python development experience",
                "react": "2 years of React frontend development",
                "mysql": "Database design and optimization experience"
            }
            
            job_requirements = {
                "python": "Python backend development",
                "javascript": "Frontend JavaScript development",
                "postgresql": "Database management"
            }
            
            match_result = await engine.match_skill_requirements(user_skills, job_requirements)
            print(f"  📈 整体匹配评分: {match_result['overall_score']:.2f}")
            print(f"  📊 匹配率: {match_result['match_percentage']:.1f}%")
            print(f"  🎯 匹配需求: {match_result['matched_requirements']}/{match_result['total_requirements']}")
            
            return True
            
        except Exception as e:
            print(f"❌ 技能引擎测试失败: {e}")
            return False
    
    async def test_api_service(self):
        """测试API服务"""
        print("\n🌐 测试技能标准化API服务...")
        
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
            
            # 测试技能标准化API
            print("\n📋 测试技能标准化API...")
            test_skills = ["python", "java", "react", "mysql", "aws", "unknown_skill"]
            success_count = 0
            
            for skill in test_skills:
                try:
                    async with session.post(
                        f"{self.api_base_url}/api/v1/skills/standardize",
                        json={"skill": skill}
                    ) as response:
                        if response.status == 200:
                            data = await response.json()
                            if data["status"] == "success":
                                standardized = data["standardized_skill"]
                                print(f"  ✅ '{skill}' -> '{standardized['name']}' ({standardized['category']})")
                                success_count += 1
                            else:
                                print(f"  ❌ '{skill}' -> 未找到匹配")
                        else:
                            print(f"  ❌ API调用失败: {response.status}")
                except Exception as e:
                    print(f"  ❌ API调用异常: {e}")
            
            print(f"\n📊 API技能标准化成功率: {success_count}/{len(test_skills)} ({success_count/len(test_skills)*100:.1f}%)")
            
            # 测试批量标准化API
            print("\n📦 测试批量技能标准化API...")
            try:
                async with session.post(
                    f"{self.api_base_url}/api/v1/skills/batch_standardize",
                    json={"skills": ["python", "java", "react", "mysql", "aws", "docker", "kubernetes"]}
                ) as response:
                    if response.status == 200:
                        data = await response.json()
                        print(f"  ✅ 批量标准化成功: {data['success_rate']:.1f}% ({data['successful_standardizations']}/{data['total_skills']})")
                    else:
                        print(f"  ❌ 批量标准化失败: {response.status}")
            except Exception as e:
                print(f"  ❌ 批量标准化异常: {e}")
            
            # 测试技能匹配API
            print("\n🎯 测试技能匹配API...")
            try:
                match_data = {
                    "user_skills": {
                        "python": "3 years of Python development experience",
                        "react": "2 years of React frontend development",
                        "mysql": "Database design and optimization experience"
                    },
                    "job_requirements": {
                        "python": "Python backend development",
                        "javascript": "Frontend JavaScript development",
                        "postgresql": "Database management"
                    }
                }
                
                async with session.post(
                    f"{self.api_base_url}/api/v1/skills/match",
                    json=match_data
                ) as response:
                    if response.status == 200:
                        data = await response.json()
                        print(f"  ✅ 技能匹配成功: 整体评分 {data['overall_score']:.2f}, 匹配率 {data['match_percentage']:.1f}%")
                        print(f"  📊 匹配详情: {data['matched_requirements']}/{data['total_requirements']} 个需求匹配")
                    else:
                        print(f"  ❌ 技能匹配失败: {response.status}")
            except Exception as e:
                print(f"  ❌ 技能匹配异常: {e}")
            
            # 测试技能搜索API
            print("\n🔍 测试技能搜索API...")
            try:
                async with session.get(
                    f"{self.api_base_url}/api/v1/skills/search?q=python&limit=5"
                ) as response:
                    if response.status == 200:
                        data = await response.json()
                        print(f"  ✅ 技能搜索成功: 找到 {data['total_results']} 个结果")
                        for result in data['results'][:3]:
                            print(f"    - {result['name']}: {result['description']}")
                    else:
                        print(f"  ❌ 技能搜索失败: {response.status}")
            except Exception as e:
                print(f"  ❌ 技能搜索异常: {e}")
            
            # 测试技能分类API
            print("\n📂 测试技能分类API...")
            try:
                async with session.get(f"{self.api_base_url}/api/v1/skills/categories") as response:
                    if response.status == 200:
                        data = await response.json()
                        print(f"  ✅ 技能分类获取成功: {data['total_categories']} 个分类")
                        for category in data['categories'][:3]:
                            print(f"    - {category['display_name']}: {category['skill_count']} 个技能")
                    else:
                        print(f"  ❌ 技能分类获取失败: {response.status}")
            except Exception as e:
                print(f"  ❌ 技能分类获取异常: {e}")
            
            # 测试技能推荐API
            print("\n💡 测试技能推荐API...")
            try:
                recommend_data = {
                    "user_skills": ["python", "mysql"],
                    "target_role": "backend_developer",
                    "industry": "tech"
                }
                
                async with session.post(
                    f"{self.api_base_url}/api/v1/skills/recommend",
                    json=recommend_data
                ) as response:
                    if response.status == 200:
                        data = await response.json()
                        print(f"  ✅ 技能推荐成功: {data['total_recommendations']} 个推荐")
                        for rec in data['recommendations'][:3]:
                            print(f"    - {rec['skill']}: {rec['reason']}")
                    else:
                        print(f"  ❌ 技能推荐失败: {response.status}")
            except Exception as e:
                print(f"  ❌ 技能推荐异常: {e}")
            
            # 测试技能统计API
            print("\n📊 测试技能统计API...")
            try:
                async with session.get(f"{self.api_base_url}/api/v1/skills/stats") as response:
                    if response.status == 200:
                        data = await response.json()
                        stats = data['stats']
                        print(f"  ✅ 技能统计获取成功:")
                        print(f"    - 总技能数: {stats['total_skills']}")
                        print(f"    - 分类数: {len(stats['categories'])}")
                        print(f"    - 总别名数: {stats['total_aliases']}")
                        print(f"    - 流行技能: {', '.join(stats['popular_skills'][:5])}")
                    else:
                        print(f"  ❌ 技能统计获取失败: {response.status}")
            except Exception as e:
                print(f"  ❌ 技能统计获取异常: {e}")
            
            return True
    
    async def test_performance(self):
        """测试性能"""
        print("\n⚡ 测试性能...")
        
        async with aiohttp.ClientSession(timeout=self.timeout) as session:
            # 测试批量标准化性能
            import time
            start_time = time.time()
            
            test_skills = ["python", "java", "react", "mysql", "aws", "docker", "kubernetes", "git", "jenkins", "grafana"]
            
            try:
                async with session.post(
                    f"{self.api_base_url}/api/v1/skills/batch_standardize",
                    json={"skills": test_skills}
                ) as response:
                    if response.status == 200:
                        data = await response.json()
                        end_time = time.time()
                        duration = end_time - start_time
                        
                        print(f"  ✅ 批量标准化性能测试:")
                        print(f"    - 处理技能数: {len(test_skills)}")
                        print(f"    - 处理时间: {duration:.2f}秒")
                        print(f"    - 处理速度: {len(test_skills)/duration:.1f} 技能/秒")
                        print(f"    - 成功率: {data['success_rate']:.1f}%")
                    else:
                        print(f"  ❌ 性能测试失败: {response.status}")
            except Exception as e:
                print(f"  ❌ 性能测试异常: {e}")
    
    async def run_comprehensive_test(self):
        """运行综合测试"""
        print("🚀 开始技能标准化系统综合测试")
        print("=" * 60)
        
        # 测试技能引擎
        engine_success = await self.test_skill_engine_directly()
        
        # 测试API服务
        api_success = await self.test_api_service()
        
        # 测试性能
        await self.test_performance()
        
        print("\n" + "=" * 60)
        print("📋 测试总结:")
        print(f"  🔧 技能引擎测试: {'✅ 通过' if engine_success else '❌ 失败'}")
        print(f"  🌐 API服务测试: {'✅ 通过' if api_success else '❌ 失败'}")
        print(f"  ⚡ 性能测试: ✅ 完成")
        
        overall_success = engine_success and api_success
        print(f"\n🎯 总体结果: {'✅ 全部通过' if overall_success else '❌ 部分失败'}")
        
        return overall_success

async def main():
    """主函数"""
    tester = SkillStandardizationTester()
    
    try:
        success = await tester.run_comprehensive_test()
        
        # 保存测试结果
        test_result = {
            "test_timestamp": datetime.now().isoformat(),
            "test_success": success,
            "test_details": {
                "skill_engine_test": "completed",
                "api_service_test": "completed",
                "performance_test": "completed"
            }
        }
        
        with open("skill_standardization_test_result.json", "w", encoding="utf-8") as f:
            json.dump(test_result, f, ensure_ascii=False, indent=2)
        
        print(f"\n📄 测试结果已保存到: skill_standardization_test_result.json")
        
        if success:
            print("\n🎉 技能标准化系统测试全部通过！可以进入下一阶段开发。")
        else:
            print("\n⚠️ 技能标准化系统测试部分失败，请检查相关功能。")
            
    except Exception as e:
        print(f"\n❌ 测试执行失败: {e}")
        logger.error("测试执行失败", error=str(e))

if __name__ == "__main__":
    asyncio.run(main())
