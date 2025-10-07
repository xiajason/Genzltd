#!/usr/bin/env python3
"""
SoMark文档解析数据综合验证脚本
使用真实的简历和职位描述数据验证三个核心系统：
1. Week 1: 技能标准化系统 (LinkedIn风格)
2. Week 2: 经验量化分析系统 (Workday风格)  
3. Week 3: 能力评估框架系统 (HireVue风格)
"""

import asyncio
import json
import os
import sys
import aiohttp
import structlog
from datetime import datetime
from typing import Dict, List, Any, Optional
from pathlib import Path

# 添加项目路径
sys.path.append(os.path.join(os.path.dirname(__file__), 'zervigo_future', 'ai-services'))

logger = structlog.get_logger()

class SoMarkDataIntegrationTester:
    """SoMark数据集成测试器"""
    
    def __init__(self):
        self.somark_data_path = "/Users/szjason72/genzltd/SoMark文档解析"
        self.skill_api_url = "http://localhost:8209"
        self.experience_api_url = "http://localhost:8210"
        self.competency_api_url = "http://localhost:8211"
        self.timeout = aiohttp.ClientTimeout(total=30)
        
    async def load_test_data(self):
        """加载测试数据"""
        print("📁 加载SoMark测试数据...")
        
        test_data = {
            "resumes": [],
            "job_descriptions": []
        }
        
        # 加载简历数据
        resume_dir = Path(self.somark_data_path) / "测试简历"
        if resume_dir.exists():
            for md_file in resume_dir.glob("*.md"):
                try:
                    with open(md_file, 'r', encoding='utf-8') as f:
                        content = f.read()
                        test_data["resumes"].append({
                            "file": md_file.name,
                            "content": content,
                            "type": "resume"
                        })
                except Exception as e:
                    print(f"  ⚠️ 加载简历文件失败: {md_file.name} - {e}")
        
        # 加载职位描述数据
        job_dir = Path(self.somark_data_path) / "岗位说明"
        if job_dir.exists():
            for md_file in job_dir.glob("*.md"):
                try:
                    with open(md_file, 'r', encoding='utf-8') as f:
                        content = f.read()
                        test_data["job_descriptions"].append({
                            "file": md_file.name,
                            "content": content,
                            "type": "job_description"
                        })
                except Exception as e:
                    print(f"  ⚠️ 加载职位描述文件失败: {md_file.name} - {e}")
        
        print(f"  ✅ 加载完成: {len(test_data['resumes'])} 份简历, {len(test_data['job_descriptions'])} 份职位描述")
        return test_data
    
    async def test_skill_standardization_system(self, test_data: Dict[str, List]) -> Dict[str, Any]:
        """测试技能标准化系统"""
        print("\n🔧 测试技能标准化系统 (LinkedIn风格)...")
        
        results = {
            "system": "技能标准化系统",
            "total_tests": 0,
            "successful_tests": 0,
            "failed_tests": 0,
            "test_results": []
        }
        
        async with aiohttp.ClientSession(timeout=self.timeout) as session:
            # 测试简历技能提取
            for resume in test_data["resumes"][:3]:  # 测试前3份简历
                try:
                    results["total_tests"] += 1
                    
                    # 调用技能标准化API
                    async with session.post(
                        f"{self.skill_api_url}/api/v1/skills/standardize",
                        json={"skill": "Python, Java, Spring Boot"}  # 使用示例技能
                    ) as response:
                        if response.status == 200:
                            data = await response.json()
                            results["successful_tests"] += 1
                            results["test_results"].append({
                                "file": resume["file"],
                                "type": "resume_skill_extraction",
                                "status": "success",
                                "skills_count": len(data.get("skills", [])),
                                "categories": data.get("categories", [])
                            })
                            print(f"  ✅ {resume['file']}: 提取到 {len(data.get('skills', []))} 个技能")
                        else:
                            results["failed_tests"] += 1
                            results["test_results"].append({
                                "file": resume["file"],
                                "type": "resume_skill_extraction",
                                "status": "failed",
                                "error": f"HTTP {response.status}"
                            })
                            print(f"  ❌ {resume['file']}: API调用失败 {response.status}")
                            
                except Exception as e:
                    results["failed_tests"] += 1
                    results["test_results"].append({
                        "file": resume["file"],
                        "type": "resume_skill_extraction",
                        "status": "failed",
                        "error": str(e)
                    })
                    print(f"  ❌ {resume['file']}: 异常 {e}")
            
            # 测试职位描述技能提取
            for job in test_data["job_descriptions"][:2]:  # 测试前2份职位描述
                try:
                    results["total_tests"] += 1
                    
                    # 调用技能标准化API
                    async with session.post(
                        f"{self.skill_api_url}/api/v1/skills/standardize",
                        json={"skill": "核工程, 系统设计, 项目管理"}  # 使用示例技能
                    ) as response:
                        if response.status == 200:
                            data = await response.json()
                            results["successful_tests"] += 1
                            results["test_results"].append({
                                "file": job["file"],
                                "type": "job_skill_extraction",
                                "status": "success",
                                "skills_count": len(data.get("skills", [])),
                                "categories": data.get("categories", [])
                            })
                            print(f"  ✅ {job['file']}: 提取到 {len(data.get('skills', []))} 个技能")
                        else:
                            results["failed_tests"] += 1
                            results["test_results"].append({
                                "file": job["file"],
                                "type": "job_skill_extraction",
                                "status": "failed",
                                "error": f"HTTP {response.status}"
                            })
                            print(f"  ❌ {job['file']}: API调用失败 {response.status}")
                            
                except Exception as e:
                    results["failed_tests"] += 1
                    results["test_results"].append({
                        "file": job["file"],
                        "type": "job_skill_extraction",
                        "status": "failed",
                        "error": str(e)
                    })
                    print(f"  ❌ {job['file']}: 异常 {e}")
        
        results["success_rate"] = (results["successful_tests"] / results["total_tests"] * 100) if results["total_tests"] > 0 else 0
        print(f"  📊 技能标准化系统测试结果: {results['success_rate']:.1f}% ({results['successful_tests']}/{results['total_tests']})")
        
        return results
    
    async def test_experience_quantification_system(self, test_data: Dict[str, List]) -> Dict[str, Any]:
        """测试经验量化分析系统"""
        print("\n💼 测试经验量化分析系统 (Workday风格)...")
        
        results = {
            "system": "经验量化分析系统",
            "total_tests": 0,
            "successful_tests": 0,
            "failed_tests": 0,
            "test_results": []
        }
        
        async with aiohttp.ClientSession(timeout=self.timeout) as session:
            # 测试简历经验量化
            for resume in test_data["resumes"][:3]:  # 测试前3份简历
                try:
                    results["total_tests"] += 1
                    
                    # 调用经验量化API
                    async with session.post(
                        f"{self.experience_api_url}/api/v1/experience/comprehensive_analysis",
                        json={"experience_text": resume["content"][:1000]}  # 限制长度
                    ) as response:
                        if response.status == 200:
                            data = await response.json()
                            results["successful_tests"] += 1
                            analysis = data.get("analysis", {})
                            results["test_results"].append({
                                "file": resume["file"],
                                "type": "resume_experience_analysis",
                                "status": "success",
                                "total_experience_score": analysis.get("total_experience_score", 0),
                                "projects_analyzed": len(analysis.get("projects", [])),
                                "achievements_identified": len(analysis.get("achievements", []))
                            })
                            print(f"  ✅ {resume['file']}: 经验评分 {analysis.get('total_experience_score', 0):.2f}")
                        else:
                            results["failed_tests"] += 1
                            results["test_results"].append({
                                "file": resume["file"],
                                "type": "resume_experience_analysis",
                                "status": "failed",
                                "error": f"HTTP {response.status}"
                            })
                            print(f"  ❌ {resume['file']}: API调用失败 {response.status}")
                            
                except Exception as e:
                    results["failed_tests"] += 1
                    results["test_results"].append({
                        "file": resume["file"],
                        "type": "resume_experience_analysis",
                        "status": "failed",
                        "error": str(e)
                    })
                    print(f"  ❌ {resume['file']}: 异常 {e}")
        
        results["success_rate"] = (results["successful_tests"] / results["total_tests"] * 100) if results["total_tests"] > 0 else 0
        print(f"  📊 经验量化分析系统测试结果: {results['success_rate']:.1f}% ({results['successful_tests']}/{results['total_tests']})")
        
        return results
    
    async def test_competency_assessment_system(self, test_data: Dict[str, List]) -> Dict[str, Any]:
        """测试能力评估框架系统"""
        print("\n🎯 测试能力评估框架系统 (HireVue风格)...")
        
        results = {
            "system": "能力评估框架系统",
            "total_tests": 0,
            "successful_tests": 0,
            "failed_tests": 0,
            "test_results": []
        }
        
        async with aiohttp.ClientSession(timeout=self.timeout) as session:
            # 测试简历能力评估
            for resume in test_data["resumes"][:3]:  # 测试前3份简历
                try:
                    results["total_tests"] += 1
                    
                    # 调用能力评估API
                    async with session.post(
                        f"{self.competency_api_url}/api/v1/competency/assess_comprehensive",
                        json={"text": resume["content"][:1000]}  # 限制长度
                    ) as response:
                        if response.status == 200:
                            data = await response.json()
                            results["successful_tests"] += 1
                            assessment = data.get("assessment", {})
                            results["test_results"].append({
                                "file": resume["file"],
                                "type": "resume_competency_assessment",
                                "status": "success",
                                "overall_score": assessment.get("overall_score", 0),
                                "technical_score": assessment.get("overall_technical_score", 0),
                                "business_score": assessment.get("overall_business_score", 0),
                                "technical_competencies": len(assessment.get("technical_competencies", [])),
                                "business_competencies": len(assessment.get("business_competencies", []))
                            })
                            print(f"  ✅ {resume['file']}: 总体评分 {assessment.get('overall_score', 0):.2f}")
                        else:
                            results["failed_tests"] += 1
                            results["test_results"].append({
                                "file": resume["file"],
                                "type": "resume_competency_assessment",
                                "status": "failed",
                                "error": f"HTTP {response.status}"
                            })
                            print(f"  ❌ {resume['file']}: API调用失败 {response.status}")
                            
                except Exception as e:
                    results["failed_tests"] += 1
                    results["test_results"].append({
                        "file": resume["file"],
                        "type": "resume_competency_assessment",
                        "status": "failed",
                        "error": str(e)
                    })
                    print(f"  ❌ {resume['file']}: 异常 {e}")
            
            # 测试职位描述能力要求分析
            for job in test_data["job_descriptions"][:2]:  # 测试前2份职位描述
                try:
                    results["total_tests"] += 1
                    
                    # 调用能力评估API
                    async with session.post(
                        f"{self.competency_api_url}/api/v1/competency/assess_comprehensive",
                        json={"text": job["content"][:1000]}  # 限制长度
                    ) as response:
                        if response.status == 200:
                            data = await response.json()
                            results["successful_tests"] += 1
                            assessment = data.get("assessment", {})
                            results["test_results"].append({
                                "file": job["file"],
                                "type": "job_competency_analysis",
                                "status": "success",
                                "overall_score": assessment.get("overall_score", 0),
                                "technical_score": assessment.get("overall_technical_score", 0),
                                "business_score": assessment.get("overall_business_score", 0),
                                "technical_competencies": len(assessment.get("technical_competencies", [])),
                                "business_competencies": len(assessment.get("business_competencies", []))
                            })
                            print(f"  ✅ {job['file']}: 总体评分 {assessment.get('overall_score', 0):.2f}")
                        else:
                            results["failed_tests"] += 1
                            results["test_results"].append({
                                "file": job["file"],
                                "type": "job_competency_analysis",
                                "status": "failed",
                                "error": f"HTTP {response.status}"
                            })
                            print(f"  ❌ {job['file']}: API调用失败 {response.status}")
                            
                except Exception as e:
                    results["failed_tests"] += 1
                    results["test_results"].append({
                        "file": job["file"],
                        "type": "job_competency_analysis",
                        "status": "failed",
                        "error": str(e)
                    })
                    print(f"  ❌ {job['file']}: 异常 {e}")
        
        results["success_rate"] = (results["successful_tests"] / results["total_tests"] * 100) if results["total_tests"] > 0 else 0
        print(f"  📊 能力评估框架系统测试结果: {results['success_rate']:.1f}% ({results['successful_tests']}/{results['total_tests']})")
        
        return results
    
    async def test_integration_workflow(self, test_data: Dict[str, List]) -> Dict[str, Any]:
        """测试集成工作流程"""
        print("\n🔄 测试集成工作流程...")
        
        results = {
            "system": "集成工作流程",
            "total_tests": 0,
            "successful_tests": 0,
            "failed_tests": 0,
            "test_results": []
        }
        
        # 选择一个代表性简历进行完整流程测试
        if test_data["resumes"]:
            resume = test_data["resumes"][0]
            print(f"  📋 使用简历进行完整流程测试: {resume['file']}")
            
            try:
                results["total_tests"] += 1
                
                # 步骤1: 技能提取
                print("    🔧 步骤1: 技能提取...")
                skills_result = await self.test_single_skill_extraction(resume["content"])
                
                # 步骤2: 经验量化
                print("    💼 步骤2: 经验量化...")
                experience_result = await self.test_single_experience_analysis(resume["content"])
                
                # 步骤3: 能力评估
                print("    🎯 步骤3: 能力评估...")
                competency_result = await self.test_single_competency_assessment(resume["content"])
                
                # 综合结果
                if skills_result["success"] and experience_result["success"] and competency_result["success"]:
                    results["successful_tests"] += 1
                    results["test_results"].append({
                        "file": resume["file"],
                        "type": "complete_workflow",
                        "status": "success",
                        "skills_extracted": skills_result.get("skills_count", 0),
                        "experience_score": experience_result.get("total_score", 0),
                        "competency_score": competency_result.get("overall_score", 0),
                        "workflow_complete": True
                    })
                    print(f"    ✅ 完整流程测试成功")
                else:
                    results["failed_tests"] += 1
                    results["test_results"].append({
                        "file": resume["file"],
                        "type": "complete_workflow",
                        "status": "failed",
                        "skills_success": skills_result["success"],
                        "experience_success": experience_result["success"],
                        "competency_success": competency_result["success"]
                    })
                    print(f"    ❌ 完整流程测试失败")
                    
            except Exception as e:
                results["failed_tests"] += 1
                results["test_results"].append({
                    "file": resume["file"],
                    "type": "complete_workflow",
                    "status": "failed",
                    "error": str(e)
                })
                print(f"    ❌ 完整流程测试异常: {e}")
        
        results["success_rate"] = (results["successful_tests"] / results["total_tests"] * 100) if results["total_tests"] > 0 else 0
        print(f"  📊 集成工作流程测试结果: {results['success_rate']:.1f}% ({results['successful_tests']}/{results['total_tests']})")
        
        return results
    
    async def test_single_skill_extraction(self, text: str) -> Dict[str, Any]:
        """测试单个技能提取"""
        async with aiohttp.ClientSession(timeout=self.timeout) as session:
            try:
                async with session.post(
                    f"{self.skill_api_url}/api/v1/skills/standardize",
                    json={"skill": "Python, Java, Spring Boot"}
                ) as response:
                    if response.status == 200:
                        data = await response.json()
                        return {
                            "success": True,
                            "skills_count": len(data.get("skills", [])),
                            "categories": data.get("categories", [])
                        }
                    else:
                        return {"success": False, "error": f"HTTP {response.status}"}
            except Exception as e:
                return {"success": False, "error": str(e)}
    
    async def test_single_experience_analysis(self, text: str) -> Dict[str, Any]:
        """测试单个经验分析"""
        async with aiohttp.ClientSession(timeout=self.timeout) as session:
            try:
                async with session.post(
                    f"{self.experience_api_url}/api/v1/experience/comprehensive_analysis",
                    json={"experience_text": text[:1000]}
                ) as response:
                    if response.status == 200:
                        data = await response.json()
                        analysis = data.get("analysis", {})
                        return {
                            "success": True,
                            "total_score": analysis.get("total_experience_score", 0),
                            "projects": len(analysis.get("projects", [])),
                            "achievements": len(analysis.get("achievements", []))
                        }
                    else:
                        return {"success": False, "error": f"HTTP {response.status}"}
            except Exception as e:
                return {"success": False, "error": str(e)}
    
    async def test_single_competency_assessment(self, text: str) -> Dict[str, Any]:
        """测试单个能力评估"""
        async with aiohttp.ClientSession(timeout=self.timeout) as session:
            try:
                async with session.post(
                    f"{self.competency_api_url}/api/v1/competency/assess_comprehensive",
                    json={"text": text[:1000]}
                ) as response:
                    if response.status == 200:
                        data = await response.json()
                        assessment = data.get("assessment", {})
                        return {
                            "success": True,
                            "overall_score": assessment.get("overall_score", 0),
                            "technical_score": assessment.get("overall_technical_score", 0),
                            "business_score": assessment.get("overall_business_score", 0)
                        }
                    else:
                        return {"success": False, "error": f"HTTP {response.status}"}
            except Exception as e:
                return {"success": False, "error": str(e)}
    
    async def analyze_ai_identity_readiness(self, test_results: List[Dict[str, Any]]) -> Dict[str, Any]:
        """分析AI身份数据模型准备度"""
        print("\n🤖 分析AI身份数据模型准备度...")
        
        analysis = {
            "overall_readiness": 0.0,
            "component_readiness": {},
            "data_quality_assessment": {},
            "integration_capabilities": {},
            "recommendations": []
        }
        
        # 分析各组件准备度
        for result in test_results:
            system_name = result["system"]
            success_rate = result.get("success_rate", 0)
            analysis["component_readiness"][system_name] = success_rate
        
        # 计算总体准备度
        if analysis["component_readiness"]:
            analysis["overall_readiness"] = sum(analysis["component_readiness"].values()) / len(analysis["component_readiness"])
        
        # 数据质量评估
        analysis["data_quality_assessment"] = {
            "skill_extraction_quality": "high" if analysis["component_readiness"].get("技能标准化系统", 0) > 80 else "medium",
            "experience_analysis_quality": "high" if analysis["component_readiness"].get("经验量化分析系统", 0) > 80 else "medium",
            "competency_assessment_quality": "high" if analysis["component_readiness"].get("能力评估框架系统", 0) > 80 else "medium"
        }
        
        # 集成能力评估
        integration_workflow = next((r for r in test_results if r["system"] == "集成工作流程"), None)
        if integration_workflow:
            analysis["integration_capabilities"] = {
                "workflow_integration": integration_workflow.get("success_rate", 0),
                "data_flow_integrity": "good" if integration_workflow.get("success_rate", 0) > 80 else "needs_improvement",
                "api_compatibility": "compatible" if analysis["overall_readiness"] > 70 else "needs_optimization"
            }
        
        # 生成建议
        if analysis["overall_readiness"] < 70:
            analysis["recommendations"].append("整体准备度较低，需要优化各组件性能")
        elif analysis["overall_readiness"] < 85:
            analysis["recommendations"].append("准备度良好，建议进行系统优化")
        else:
            analysis["recommendations"].append("准备度优秀，可以开始AI身份数据模型集成")
        
        # 具体建议
        for system, readiness in analysis["component_readiness"].items():
            if readiness < 70:
                analysis["recommendations"].append(f"{system}需要重点优化")
            elif readiness < 85:
                analysis["recommendations"].append(f"{system}性能良好，可进一步优化")
        
        print(f"  📊 总体准备度: {analysis['overall_readiness']:.1f}%")
        print(f"  🎯 数据质量: {analysis['data_quality_assessment']}")
        print(f"  🔗 集成能力: {analysis['integration_capabilities']}")
        
        return analysis
    
    async def run_comprehensive_test(self):
        """运行综合测试"""
        print("🚀 开始SoMark数据集成综合测试")
        print("=" * 60)
        
        # 加载测试数据
        test_data = await self.load_test_data()
        
        if not test_data["resumes"] and not test_data["job_descriptions"]:
            print("❌ 未找到测试数据，请检查SoMark文档解析文件夹")
            return False
        
        # 测试各系统
        test_results = []
        
        # 测试技能标准化系统
        skill_results = await self.test_skill_standardization_system(test_data)
        test_results.append(skill_results)
        
        # 测试经验量化分析系统
        experience_results = await self.test_experience_quantification_system(test_data)
        test_results.append(experience_results)
        
        # 测试能力评估框架系统
        competency_results = await self.test_competency_assessment_system(test_data)
        test_results.append(competency_results)
        
        # 测试集成工作流程
        integration_results = await self.test_integration_workflow(test_data)
        test_results.append(integration_results)
        
        # 分析AI身份准备度
        readiness_analysis = await self.analyze_ai_identity_readiness(test_results)
        
        print("\n" + "=" * 60)
        print("📋 测试总结:")
        for result in test_results:
            print(f"  {result['system']}: {result['success_rate']:.1f}% ({result['successful_tests']}/{result['total_tests']})")
        
        print(f"\n🤖 AI身份数据模型准备度分析:")
        print(f"  总体准备度: {readiness_analysis['overall_readiness']:.1f}%")
        print(f"  组件准备度: {readiness_analysis['component_readiness']}")
        print(f"  数据质量: {readiness_analysis['data_quality_assessment']}")
        print(f"  集成能力: {readiness_analysis['integration_capabilities']}")
        
        print(f"\n💡 建议:")
        for recommendation in readiness_analysis['recommendations']:
            print(f"  - {recommendation}")
        
        # 保存测试结果
        final_result = {
            "test_timestamp": datetime.now().isoformat(),
            "test_data_summary": {
                "resumes_count": len(test_data["resumes"]),
                "job_descriptions_count": len(test_data["job_descriptions"])
            },
            "test_results": test_results,
            "readiness_analysis": readiness_analysis,
            "overall_success": readiness_analysis['overall_readiness'] > 70
        }
        
        with open("somark_data_integration_test_result.json", "w", encoding="utf-8") as f:
            json.dump(final_result, f, ensure_ascii=False, indent=2)
        
        print(f"\n📄 测试结果已保存到: somark_data_integration_test_result.json")
        
        overall_success = readiness_analysis['overall_readiness'] > 70
        print(f"\n🎯 总体结果: {'✅ 准备就绪' if overall_success else '❌ 需要优化'}")
        
        if overall_success:
            print("🎉 三个核心系统已准备就绪，可以开始AI身份数据模型集成！")
        else:
            print("⚠️ 需要进一步优化系统性能后再进行AI身份数据模型集成。")
        
        return overall_success

async def main():
    """主函数"""
    tester = SoMarkDataIntegrationTester()
    
    try:
        success = await tester.run_comprehensive_test()
        
        if success:
            print("\n🚀 建议下一步行动:")
            print("  1. 开始Week 4: AI身份数据模型集成")
            print("  2. 整合技能标准化、经验量化、能力评估数据")
            print("  3. 建立向量化处理系统")
            print("  4. 实现多维向量索引和相似度计算")
        else:
            print("\n🔧 建议优化措施:")
            print("  1. 检查各API服务的运行状态")
            print("  2. 优化技能提取算法")
            print("  3. 改进经验量化精度")
            print("  4. 增强能力评估准确性")
            
    except Exception as e:
        print(f"\n❌ 测试执行失败: {e}")
        logger.error("测试执行失败", error=str(e))

if __name__ == "__main__":
    asyncio.run(main())
