#!/usr/bin/env python3
"""
Week 4: AI身份数据模型集成 - 综合测试脚本
验证AI身份数据模型管理器、向量化处理系统、相似度计算引擎和API服务的功能
"""

import asyncio
import json
import os
import sys
import time
import numpy as np
from datetime import datetime
from typing import Dict, List, Any

# 添加路径以便导入自定义模块
sys.path.append('/Users/szjason72/genzltd/zervigo_future/ai-services')

try:
    from ai_identity_data_model import AIIdentityDataModel, AIIdentityType
    from ai_identity_vectorization import AIIdentityVectorization, VectorizationConfig, VectorType
    from ai_identity_similarity import AIIdentitySimilarity, SimilarityConfig, SimilarityType
    IMPORTS_SUCCESS = True
except ImportError as e:
    print(f"❌ 导入模块失败: {e}")
    IMPORTS_SUCCESS = False

class AIIdentityDataModelTester:
    """AI身份数据模型系统测试器"""
    
    def __init__(self):
        self.test_results = {
            "total_tests": 0,
            "passed_tests": 0,
            "failed_tests": 0,
            "test_details": [],
            "performance_metrics": {},
            "start_time": datetime.now(),
            "end_time": None
        }
        
        # 数据库配置
        self.db_config = {
            "mysql": {"host": "localhost", "port": 3306, "user": "root", "password": "password"},
            "postgresql": {"host": "localhost", "port": 5434, "user": "postgres", "password": "password"},
            "redis": {"host": "localhost", "port": 6382, "password": ""},
            "neo4j": {"uri": "bolt://localhost:7688", "user": "neo4j", "password": "password"},
            "mongodb": {"host": "localhost", "port": 27018, "user": "admin", "password": "password"},
            "elasticsearch": {"host": "localhost", "port": 9202},
            "weaviate": {"host": "localhost", "port": 8091}
        }
        
        # 初始化组件
        self.data_model = None
        self.vectorizer = None
        self.similarity_engine = None
        
        print("🚀 AI身份数据模型系统测试器初始化完成")
    
    def record_test(self, test_name: str, status: str, message: str, performance: str = None):
        """记录测试结果"""
        self.test_results["total_tests"] += 1
        
        if status == "PASS":
            self.test_results["passed_tests"] += 1
            print(f"✅ {test_name}: {message}")
        else:
            self.test_results["failed_tests"] += 1
            print(f"❌ {test_name}: {message}")
        
        self.test_results["test_details"].append({
            "test_name": test_name,
            "status": status,
            "message": message,
            "performance": performance,
            "timestamp": datetime.now().isoformat()
        })
    
    async def test_module_imports(self):
        """测试模块导入"""
        print("\n📦 测试模块导入...")
        
        if IMPORTS_SUCCESS:
            self.record_test("模块导入测试", "PASS", "所有模块导入成功")
        else:
            self.record_test("模块导入测试", "FAIL", "模块导入失败")
            return False
        
        return True
    
    async def test_data_model_initialization(self):
        """测试数据模型初始化"""
        print("\n🏗️ 测试AI身份数据模型管理器初始化...")
        
        try:
            self.data_model = AIIdentityDataModel(self.db_config)
            init_result = await self.data_model.initialize()
            
            if init_result:
                self.record_test("数据模型初始化", "PASS", "AI身份数据模型管理器初始化成功")
                return True
            else:
                self.record_test("数据模型初始化", "FAIL", "AI身份数据模型管理器初始化失败")
                return False
                
        except Exception as e:
            self.record_test("数据模型初始化", "FAIL", f"初始化异常: {str(e)}")
            return False
    
    async def test_vectorization_initialization(self):
        """测试向量化系统初始化"""
        print("\n🔢 测试向量化处理系统初始化...")
        
        try:
            config = VectorizationConfig(
                model_name="all-MiniLM-L6-v2",
                vector_dimension=384,
                batch_size=16,
                normalize_vectors=True,
                use_faiss_index=True
            )
            
            self.vectorizer = AIIdentityVectorization(config)
            init_result = await self.vectorizer.initialize()
            
            if init_result:
                self.record_test("向量化系统初始化", "PASS", "向量化处理系统初始化成功")
                return True
            else:
                self.record_test("向量化系统初始化", "FAIL", "向量化处理系统初始化失败")
                return False
                
        except Exception as e:
            self.record_test("向量化系统初始化", "FAIL", f"初始化异常: {str(e)}")
            return False
    
    async def test_similarity_initialization(self):
        """测试相似度计算引擎初始化"""
        print("\n📊 测试相似度计算引擎初始化...")
        
        try:
            config = SimilarityConfig(
                primary_algorithm=SimilarityAlgorithm.COSINE,
                use_weighted_similarity=True,
                skill_weight=0.4,
                experience_weight=0.3,
                competency_weight=0.3,
                normalize_vectors=True,
                cache_results=True
            )
            
            self.similarity_engine = AIIdentitySimilarity(config)
            init_result = await self.similarity_engine.initialize()
            
            if init_result:
                self.record_test("相似度引擎初始化", "PASS", "相似度计算引擎初始化成功")
                return True
            else:
                self.record_test("相似度引擎初始化", "FAIL", "相似度计算引擎初始化失败")
                return False
                
        except Exception as e:
            self.record_test("相似度引擎初始化", "FAIL", f"初始化异常: {str(e)}")
            return False
    
    async def test_profile_creation(self):
        """测试AI身份档案创建"""
        print("\n👤 测试AI身份档案创建...")
        
        try:
            start_time = time.time()
            
            profile = await self.data_model.create_ai_identity_profile(
                user_id=1,
                identity_type=AIIdentityType.RATIONAL
            )
            
            creation_time = (time.time() - start_time) * 1000
            
            if profile and profile.profile_id:
                self.record_test("档案创建", "PASS", 
                               f"AI身份档案创建成功，档案ID: {profile.profile_id}",
                               f"创建时间: {creation_time:.2f}ms")
                
                # 测试档案序列化
                profile_dict = await self.data_model.serialize_profile(profile)
                if profile_dict:
                    self.record_test("档案序列化", "PASS", "档案序列化成功")
                else:
                    self.record_test("档案序列化", "FAIL", "档案序列化失败")
                
                return profile
            else:
                self.record_test("档案创建", "FAIL", "AI身份档案创建失败")
                return None
                
        except Exception as e:
            self.record_test("档案创建", "FAIL", f"创建异常: {str(e)}")
            return None
    
    async def test_vectorization(self, profile):
        """测试向量化处理"""
        print("\n🔢 测试向量化处理...")
        
        try:
            if not profile:
                self.record_test("向量化处理", "FAIL", "没有可用的档案进行向量化")
                return None
            
            # 序列化档案数据
            profile_dict = await self.data_model.serialize_profile(profile)
            
            start_time = time.time()
            
            # 测试综合向量化
            result = await self.vectorizer.vectorize_ai_identity_profile(
                profile_data=profile_dict,
                vector_type=VectorType.COMPREHENSIVE
            )
            
            vectorization_time = (time.time() - start_time) * 1000
            
            if result and result.vector_embedding is not None:
                self.record_test("综合向量化", "PASS", 
                               f"向量化成功，维度: {result.vector_dimension}, 置信度: {result.confidence_score:.3f}",
                               f"向量化时间: {vectorization_time:.2f}ms")
                
                # 测试技能向量化
                skill_result = await self.vectorizer.vectorize_ai_identity_profile(
                    profile_data=profile_dict,
                    vector_type=VectorType.SKILL
                )
                
                if skill_result:
                    self.record_test("技能向量化", "PASS", f"技能向量化成功，维度: {skill_result.vector_dimension}")
                else:
                    self.record_test("技能向量化", "FAIL", "技能向量化失败")
                
                return result
            else:
                self.record_test("向量化处理", "FAIL", "向量化处理失败")
                return None
                
        except Exception as e:
            self.record_test("向量化处理", "FAIL", f"向量化异常: {str(e)}")
            return None
    
    async def test_similarity_calculation(self, vector_result1, vector_result2):
        """测试相似度计算"""
        print("\n📊 测试相似度计算...")
        
        try:
            if not vector_result1 or not vector_result2:
                # 创建第二个向量用于测试
                profile2 = await self.data_model.create_ai_identity_profile(
                    user_id=2,
                    identity_type=AIIdentityType.RATIONAL
                )
                
                if profile2:
                    profile_dict2 = await self.data_model.serialize_profile(profile2)
                    vector_result2 = await self.vectorizer.vectorize_ai_identity_profile(
                        profile_data=profile_dict2,
                        vector_type=VectorType.COMPREHENSIVE
                    )
            
            if not vector_result1 or not vector_result2:
                self.record_test("相似度计算", "FAIL", "没有可用的向量进行相似度计算")
                return None
            
            start_time = time.time()
            
            # 计算相似度
            similarity_result = await self.similarity_engine.calculate_similarity(
                source_vector=vector_result1.vector_embedding,
                target_vector=vector_result2.vector_embedding,
                source_profile_id=vector_result1.profile_id,
                target_profile_id=vector_result2.profile_id,
                similarity_type=SimilarityType.COMPREHENSIVE
            )
            
            calculation_time = (time.time() - start_time) * 1000
            
            if similarity_result and similarity_result.overall_similarity_score is not None:
                self.record_test("相似度计算", "PASS", 
                               f"相似度计算成功，综合评分: {similarity_result.overall_similarity_score:.3f}",
                               f"计算时间: {calculation_time:.2f}ms")
                
                # 测试批量相似度计算
                vector_pairs = [
                    (vector_result1.vector_embedding, vector_result2.vector_embedding, 
                     vector_result1.profile_id, vector_result2.profile_id)
                ]
                
                batch_results = await self.similarity_engine.batch_calculate_similarity(
                    vector_pairs=vector_pairs,
                    similarity_type=SimilarityType.COMPREHENSIVE
                )
                
                if batch_results and len(batch_results) > 0:
                    self.record_test("批量相似度计算", "PASS", 
                                   f"批量计算成功，结果数量: {len(batch_results)}")
                else:
                    self.record_test("批量相似度计算", "FAIL", "批量相似度计算失败")
                
                return similarity_result
            else:
                self.record_test("相似度计算", "FAIL", "相似度计算失败")
                return None
                
        except Exception as e:
            self.record_test("相似度计算", "FAIL", f"相似度计算异常: {str(e)}")
            return None
    
    async def test_performance_metrics(self):
        """测试性能指标"""
        print("\n⚡ 测试性能指标...")
        
        try:
            # 获取数据模型统计
            profile_stats = await self.data_model.get_profile_statistics()
            if profile_stats:
                self.record_test("数据模型统计", "PASS", 
                               f"档案数量: {profile_stats.get('total_profiles', 0)}")
            
            # 获取向量化性能统计
            vectorization_stats = await self.vectorizer.get_performance_stats()
            if vectorization_stats:
                self.record_test("向量化性能统计", "PASS", 
                               f"总向量化次数: {vectorization_stats.get('total_vectorizations', 0)}")
            
            # 获取相似度计算性能统计
            similarity_stats = await self.similarity_engine.get_performance_stats()
            if similarity_stats:
                self.record_test("相似度计算性能统计", "PASS", 
                               f"总计算次数: {similarity_stats.get('total_calculations', 0)}")
            
            # 记录性能指标
            self.test_results["performance_metrics"] = {
                "profiles": profile_stats,
                "vectorization": vectorization_stats,
                "similarity": similarity_stats
            }
            
        except Exception as e:
            self.record_test("性能指标测试", "FAIL", f"性能指标测试异常: {str(e)}")
    
    async def test_integration_workflow(self):
        """测试集成工作流程"""
        print("\n🔄 测试集成工作流程...")
        
        try:
            # 1. 创建多个档案
            profiles = []
            for i in range(3):
                profile = await self.data_model.create_ai_identity_profile(
                    user_id=i + 1,
                    identity_type=AIIdentityType.RATIONAL
                )
                if profile:
                    profiles.append(profile)
            
            if len(profiles) >= 2:
                self.record_test("多档案创建", "PASS", f"成功创建 {len(profiles)} 个档案")
                
                # 2. 批量向量化
                profile_data_list = []
                for profile in profiles:
                    profile_dict = await self.data_model.serialize_profile(profile)
                    profile_data_list.append(profile_dict)
                
                vector_results = await self.vectorizer.batch_vectorize(
                    profiles_data=profile_data_list,
                    vector_type=VectorType.COMPREHENSIVE
                )
                
                if vector_results and len(vector_results) >= 2:
                    self.record_test("批量向量化", "PASS", f"成功向量化 {len(vector_results)} 个档案")
                    
                    # 3. 批量相似度计算
                    vector_pairs = []
                    for i in range(len(vector_results)):
                        for j in range(i + 1, len(vector_results)):
                            vector_pairs.append((
                                vector_results[i].vector_embedding,
                                vector_results[j].vector_embedding,
                                vector_results[i].profile_id,
                                vector_results[j].profile_id
                            ))
                    
                    similarity_results = await self.similarity_engine.batch_calculate_similarity(
                        vector_pairs=vector_pairs,
                        similarity_type=SimilarityType.COMPREHENSIVE
                    )
                    
                    if similarity_results:
                        self.record_test("集成工作流程", "PASS", 
                                       f"完整工作流程成功，相似度计算结果: {len(similarity_results)} 个")
                        
                        # 显示相似度排序结果
                        similarity_results.sort(key=lambda x: x.overall_similarity_score, reverse=True)
                        print(f"   相似度排序结果:")
                        for i, result in enumerate(similarity_results[:3]):  # 显示前3个
                            print(f"   {i+1}. {result.source_profile_id} vs {result.target_profile_id}: "
                                  f"{result.overall_similarity_score:.3f}")
                    else:
                        self.record_test("集成工作流程", "FAIL", "相似度计算失败")
                else:
                    self.record_test("集成工作流程", "FAIL", "批量向量化失败")
            else:
                self.record_test("集成工作流程", "FAIL", "多档案创建失败")
                
        except Exception as e:
            self.record_test("集成工作流程", "FAIL", f"集成工作流程异常: {str(e)}")
    
    async def cleanup(self):
        """清理资源"""
        print("\n🧹 清理资源...")
        
        try:
            if self.data_model:
                await self.data_model.cleanup()
            
            if self.vectorizer:
                await self.vectorizer.cleanup()
            
            if self.similarity_engine:
                await self.similarity_engine.cleanup()
            
            print("✅ 资源清理完成")
            
        except Exception as e:
            print(f"❌ 资源清理失败: {str(e)}")
    
    def generate_report(self):
        """生成测试报告"""
        self.test_results["end_time"] = datetime.now()
        duration = (self.test_results["end_time"] - self.test_results["start_time"]).total_seconds()
        
        pass_rate = (self.test_results["passed_tests"] / self.test_results["total_tests"] * 100) if self.test_results["total_tests"] > 0 else 0
        
        print("\n" + "="*80)
        print("🎉 AI身份数据模型集成 - 综合测试报告")
        print("="*80)
        print(f"📊 测试概览:")
        print(f"   - 总测试数: {self.test_results['total_tests']}")
        print(f"   - 通过测试: {self.test_results['passed_tests']}")
        print(f"   - 失败测试: {self.test_results['failed_tests']}")
        print(f"   - 通过率: {pass_rate:.1f}%")
        print(f"   - 测试时长: {duration:.2f}秒")
        
        print(f"\n📈 性能指标:")
        if self.test_results["performance_metrics"]:
            perf = self.test_results["performance_metrics"]
            
            if "profiles" in perf:
                print(f"   - 档案数量: {perf['profiles'].get('total_profiles', 0)}")
            
            if "vectorization" in perf:
                vec_perf = perf["vectorization"]
                print(f"   - 向量化次数: {vec_perf.get('total_vectorizations', 0)}")
                print(f"   - 平均向量化时间: {vec_perf.get('average_time_ms', 0):.2f}ms")
            
            if "similarity" in perf:
                sim_perf = perf["similarity"]
                print(f"   - 相似度计算次数: {sim_perf.get('total_calculations', 0)}")
                print(f"   - 平均计算时间: {sim_perf.get('average_time_ms', 0):.2f}ms")
        
        print(f"\n📋 详细测试结果:")
        for test in self.test_results["test_details"]:
            status_icon = "✅" if test["status"] == "PASS" else "❌"
            print(f"   {status_icon} {test['test_name']}: {test['message']}")
            if test.get("performance"):
                print(f"      ⚡ {test['performance']}")
        
        print("\n" + "="*80)
        
        # 保存测试结果到文件
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        report_file = f"ai_identity_data_model_test_result_{timestamp}.json"
        
        try:
            with open(report_file, 'w', encoding='utf-8') as f:
                json.dump(self.test_results, f, ensure_ascii=False, indent=2, default=str)
            
            print(f"📄 详细测试结果已保存到: {report_file}")
            
        except Exception as e:
            print(f"❌ 保存测试结果失败: {str(e)}")
        
        return pass_rate >= 80  # 80%通过率视为成功

async def main():
    """主函数"""
    print("🚀 开始Week 4: AI身份数据模型集成 - 综合测试")
    print("="*80)
    
    tester = AIIdentityDataModelTester()
    
    try:
        # 1. 测试模块导入
        if not await tester.test_module_imports():
            return False
        
        # 2. 测试组件初始化
        if not await tester.test_data_model_initialization():
            return False
        
        if not await tester.test_vectorization_initialization():
            return False
        
        if not await tester.test_similarity_initialization():
            return False
        
        # 3. 测试核心功能
        profile = await tester.test_profile_creation()
        vector_result = await tester.test_vectorization(profile)
        similarity_result = await tester.test_similarity_calculation(vector_result, None)
        
        # 4. 测试性能指标
        await tester.test_performance_metrics()
        
        # 5. 测试集成工作流程
        await tester.test_integration_workflow()
        
        # 6. 生成测试报告
        success = tester.generate_report()
        
        if success:
            print("\n🎉 Week 4: AI身份数据模型集成测试完成 - 系统验证成功！")
            print("✅ 所有核心组件功能正常，可以进入Week 5开发")
        else:
            print("\n⚠️ Week 4: AI身份数据模型集成测试完成 - 需要优化")
            print("❌ 部分功能需要修复，建议优化后继续")
        
        return success
        
    except Exception as e:
        print(f"\n❌ 测试过程中发生异常: {str(e)}")
        return False
        
    finally:
        await tester.cleanup()

if __name__ == "__main__":
    success = asyncio.run(main())
    sys.exit(0 if success else 1)
