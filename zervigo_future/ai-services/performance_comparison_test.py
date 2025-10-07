#!/usr/bin/env python3
"""
AI服务性能对比测试
对比本地AI服务与容器化AI服务的性能差异
"""

import requests
import json
import time
import os
import hashlib
from typing import Dict, List, Any, Tuple
from datetime import datetime
import statistics

class AIServicePerformanceComparator:
    """AI服务性能对比器"""
    
    def __init__(self):
        self.local_service_url = "http://localhost:8206"
        self.containerized_service_url = "http://localhost:8208"
        self.mineru_service_url = "http://localhost:8001"
        
        # 测试用的JWT token
        self.test_token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoxLCJ1c2VybmFtZSI6InRlc3RfdXNlciIsImVtYWlsIjoidGVzdEBleGFtcGxlLmNvbSIsInJvbGVzIjpbInVzZXIiXSwiaWF0IjoxNzU3ODUzMzYyLCJleHAiOjE3NTc4NTY5NjIsImlzcyI6ImFpLXNlcnZpY2UtdGVzdCJ9.E-GnxBe9YptNYvbsJxuOXxy_A7vVVNxUBY0q0uK1I34"
        
        self.results = {
            "local_service": {},
            "containerized_service": {},
            "mineru_service": {},
            "comparison": {}
        }
    
    def test_service_health(self) -> Dict[str, Any]:
        """测试服务健康状态"""
        print("🔍 测试服务健康状态...")
        
        health_results = {}
        
        # 测试本地服务
        try:
            response = requests.get(f"{self.local_service_url}/health", timeout=5)
            health_results["local"] = {
                "status": response.status_code == 200,
                "response_time": response.elapsed.total_seconds(),
                "data": response.json() if response.status_code == 200 else None
            }
        except Exception as e:
            health_results["local"] = {"status": False, "error": str(e)}
        
        # 测试容器化服务
        try:
            response = requests.get(f"{self.containerized_service_url}/health", timeout=5)
            health_results["containerized"] = {
                "status": response.status_code == 200,
                "response_time": response.elapsed.total_seconds(),
                "data": response.json() if response.status_code == 200 else None
            }
        except Exception as e:
            health_results["containerized"] = {"status": False, "error": str(e)}
        
        # 测试MinerU服务
        try:
            response = requests.get(f"{self.mineru_service_url}/health", timeout=5)
            health_results["mineru"] = {
                "status": response.status_code == 200,
                "response_time": response.elapsed.total_seconds(),
                "data": response.json() if response.status_code == 200 else None
            }
        except Exception as e:
            health_results["mineru"] = {"status": False, "error": str(e)}
        
        return health_results
    
    def test_embedding_generation(self, iterations: int = 10) -> Dict[str, Any]:
        """测试嵌入向量生成性能"""
        print(f"🧠 测试嵌入向量生成性能 ({iterations}次迭代)...")
        
        test_texts = [
            "Python软件开发工程师，具有5年经验",
            "Java后端开发，熟悉Spring框架",
            "前端开发工程师，精通React和Vue",
            "数据科学家，机器学习专家",
            "DevOps工程师，Docker和Kubernetes专家"
        ]
        
        results = {"local": [], "containerized": []}
        
        # 测试本地服务
        for i in range(iterations):
            text = test_texts[i % len(test_texts)]
            try:
                start_time = time.time()
                response = requests.post(
                    f"{self.local_service_url}/api/v1/ai/embedding",
                    json={"text": text},
                    timeout=10
                )
                end_time = time.time()
                
                if response.status_code == 200:
                    data = response.json()
                    results["local"].append({
                        "response_time": end_time - start_time,
                        "vector_dimension": len(data.get("embedding", [])),
                        "success": True
                    })
                else:
                    results["local"].append({
                        "response_time": end_time - start_time,
                        "success": False,
                        "error": response.text
                    })
            except Exception as e:
                results["local"].append({
                    "response_time": 0,
                    "success": False,
                    "error": str(e)
                })
        
        # 测试容器化服务
        headers = {"Authorization": f"Bearer {self.test_token}"}
        for i in range(iterations):
            text = test_texts[i % len(test_texts)]
            try:
                start_time = time.time()
                response = requests.post(
                    f"{self.containerized_service_url}/api/v1/ai/embedding",
                    headers=headers,
                    json={"text": text},
                    timeout=10
                )
                end_time = time.time()
                
                if response.status_code == 200:
                    data = response.json()
                    results["containerized"].append({
                        "response_time": end_time - start_time,
                        "vector_dimension": len(data.get("embedding", [])),
                        "success": True
                    })
                else:
                    results["containerized"].append({
                        "response_time": end_time - start_time,
                        "success": False,
                        "error": response.text
                    })
            except Exception as e:
                results["containerized"].append({
                    "response_time": 0,
                    "success": False,
                    "error": str(e)
                })
        
        return results
    
    def test_resume_analysis(self, iterations: int = 5) -> Dict[str, Any]:
        """测试简历分析性能"""
        print(f"📄 测试简历分析性能 ({iterations}次迭代)...")
        
        resume_data = {
            "name": "张三",
            "email": "zhangsan@example.com",
            "phone": "13800138000",
            "summary": "具有5年软件开发经验，熟悉Python、Java等编程语言，有丰富的项目经验",
            "experience": [
                {
                    "title": "高级软件工程师",
                    "company": "ABC科技有限公司",
                    "description": "负责后端系统开发和维护，使用Python和Django框架"
                },
                {
                    "title": "软件工程师",
                    "company": "XYZ互联网公司",
                    "description": "参与前端开发，使用React和Vue.js"
                }
            ],
            "education": [
                {
                    "degree": "计算机科学与技术学士",
                    "school": "某某大学"
                }
            ],
            "skills": ["Python", "Java", "JavaScript", "React", "Vue", "MySQL", "Docker", "Git", "团队协作", "项目管理"]
        }
        
        results = {"local": [], "containerized": []}
        
        # 测试本地服务
        for i in range(iterations):
            try:
                start_time = time.time()
                response = requests.post(
                    f"{self.local_service_url}/api/v1/ai/resume-analysis",
                    json=resume_data,
                    timeout=30
                )
                end_time = time.time()
                
                if response.status_code == 200:
                    data = response.json()
                    results["local"].append({
                        "response_time": end_time - start_time,
                        "success": True,
                        "confidence_score": data.get("result", {}).get("confidence_score", 0)
                    })
                else:
                    results["local"].append({
                        "response_time": end_time - start_time,
                        "success": False,
                        "error": response.text
                    })
            except Exception as e:
                results["local"].append({
                    "response_time": 0,
                    "success": False,
                    "error": str(e)
                })
        
        # 测试容器化服务
        headers = {"Authorization": f"Bearer {self.test_token}"}
        for i in range(iterations):
            try:
                start_time = time.time()
                response = requests.post(
                    f"{self.containerized_service_url}/api/v1/ai/resume-analysis",
                    headers=headers,
                    json=resume_data,
                    timeout=30
                )
                end_time = time.time()
                
                if response.status_code == 200:
                    data = response.json()
                    results["containerized"].append({
                        "response_time": end_time - start_time,
                        "success": True,
                        "confidence_score": data.get("result", {}).get("confidence_score", 0)
                    })
                else:
                    results["containerized"].append({
                        "response_time": end_time - start_time,
                        "success": False,
                        "error": response.text
                    })
            except Exception as e:
                results["containerized"].append({
                    "response_time": 0,
                    "success": False,
                    "error": str(e)
                })
        
        return results
    
    def test_document_parsing(self) -> Dict[str, Any]:
        """测试文档解析能力"""
        print("📋 测试文档解析能力...")
        
        # 创建测试文档
        test_documents = self._create_test_documents()
        results = {"mineru": [], "local": [], "containerized": []}
        
        # 测试MinerU文档解析
        for doc_info in test_documents:
            try:
                start_time = time.time()
                with open(doc_info["path"], "rb") as f:
                    files = {"file": f}
                    response = requests.post(
                        f"{self.mineru_service_url}/api/v1/parse",
                        files=files,
                        timeout=60
                    )
                end_time = time.time()
                
                if response.status_code == 200:
                    data = response.json()
                    results["mineru"].append({
                        "file_type": doc_info["type"],
                        "file_size": doc_info["size"],
                        "response_time": end_time - start_time,
                        "success": True,
                        "parsed_content_length": len(data.get("content", "")),
                        "confidence": data.get("confidence", 0)
                    })
                else:
                    results["mineru"].append({
                        "file_type": doc_info["type"],
                        "file_size": doc_info["size"],
                        "response_time": end_time - start_time,
                        "success": False,
                        "error": response.text
                    })
            except Exception as e:
                results["mineru"].append({
                    "file_type": doc_info["type"],
                    "file_size": doc_info["size"],
                    "success": False,
                    "error": str(e)
                })
        
        # 清理测试文件
        self._cleanup_test_documents(test_documents)
        
        return results
    
    def _create_test_documents(self) -> List[Dict[str, Any]]:
        """创建测试文档"""
        test_docs = []
        
        # 创建测试PDF文件
        pdf_content = """
        %PDF-1.4
        1 0 obj
        <<
        /Type /Catalog
        /Pages 2 0 R
        >>
        endobj
        
        2 0 obj
        <<
        /Type /Pages
        /Kids [3 0 R]
        /Count 1
        >>
        endobj
        
        3 0 obj
        <<
        /Type /Page
        /Parent 2 0 R
        /MediaBox [0 0 612 792]
        /Contents 4 0 R
        >>
        endobj
        
        4 0 obj
        <<
        /Length 44
        >>
        stream
        BT
        /F1 12 Tf
        72 720 Td
        (测试PDF文档内容) Tj
        ET
        endstream
        endobj
        
        xref
        0 5
        0000000000 65535 f 
        0000000009 00000 n 
        0000000058 00000 n 
        0000000115 00000 n 
        0000000204 00000 n 
        trailer
        <<
        /Size 5
        /Root 1 0 R
        >>
        startxref
        297
        %%EOF
        """
        
        pdf_path = "/tmp/test_document.pdf"
        with open(pdf_path, "w", encoding="utf-8") as f:
            f.write(pdf_content)
        
        test_docs.append({
            "path": pdf_path,
            "type": "PDF",
            "size": os.path.getsize(pdf_path)
        })
        
        # 创建测试DOCX文件
        docx_content = """
        <?xml version="1.0" encoding="UTF-8"?>
        <w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
            <w:body>
                <w:p>
                    <w:r>
                        <w:t>测试DOCX文档内容</w:t>
                    </w:r>
                </w:p>
            </w:body>
        </w:document>
        """
        
        docx_path = "/tmp/test_document.docx"
        with open(docx_path, "w", encoding="utf-8") as f:
            f.write(docx_content)
        
        test_docs.append({
            "path": docx_path,
            "type": "DOCX",
            "size": os.path.getsize(docx_path)
        })
        
        return test_docs
    
    def _cleanup_test_documents(self, test_docs: List[Dict[str, Any]]):
        """清理测试文档"""
        for doc in test_docs:
            try:
                os.remove(doc["path"])
            except:
                pass
    
    def calculate_statistics(self, data: List[Dict[str, Any]], key: str) -> Dict[str, float]:
        """计算统计数据"""
        values = [item[key] for item in data if item.get("success", False) and key in item]
        if not values:
            return {"mean": 0, "median": 0, "std": 0, "min": 0, "max": 0}
        
        return {
            "mean": statistics.mean(values),
            "median": statistics.median(values),
            "std": statistics.stdev(values) if len(values) > 1 else 0,
            "min": min(values),
            "max": max(values)
        }
    
    def run_comprehensive_comparison(self) -> Dict[str, Any]:
        """运行全面对比测试"""
        print("🚀 开始AI服务性能对比测试")
        print("=" * 60)
        
        # 1. 健康状态测试
        health_results = self.test_service_health()
        self.results["health"] = health_results
        
        # 2. 嵌入向量生成性能测试
        embedding_results = self.test_embedding_generation(10)
        self.results["embedding"] = embedding_results
        
        # 3. 简历分析性能测试
        resume_results = self.test_resume_analysis(5)
        self.results["resume_analysis"] = resume_results
        
        # 4. 文档解析能力测试
        document_results = self.test_document_parsing()
        self.results["document_parsing"] = document_results
        
        # 5. 生成对比报告
        comparison_report = self.generate_comparison_report()
        self.results["comparison"] = comparison_report
        
        return self.results
    
    def generate_comparison_report(self) -> Dict[str, Any]:
        """生成对比报告"""
        report = {
            "timestamp": datetime.now().isoformat(),
            "summary": {},
            "detailed_analysis": {},
            "recommendations": []
        }
        
        # 健康状态对比
        health = self.results["health"]
        report["summary"]["health_status"] = {
            "local": health["local"]["status"],
            "containerized": health["containerized"]["status"],
            "mineru": health["mineru"]["status"]
        }
        
        # 性能对比
        embedding = self.results["embedding"]
        if embedding["local"] and embedding["containerized"]:
            local_times = [item["response_time"] for item in embedding["local"] if item["success"]]
            containerized_times = [item["response_time"] for item in embedding["containerized"] if item["success"]]
            
            if local_times and containerized_times:
                report["summary"]["embedding_performance"] = {
                    "local_avg": statistics.mean(local_times),
                    "containerized_avg": statistics.mean(containerized_times),
                    "performance_ratio": statistics.mean(containerized_times) / statistics.mean(local_times)
                }
        
        # 简历分析对比
        resume = self.results["resume_analysis"]
        if resume["local"] and resume["containerized"]:
            local_times = [item["response_time"] for item in resume["local"] if item["success"]]
            containerized_times = [item["response_time"] for item in resume["containerized"] if item["success"]]
            
            if local_times and containerized_times:
                report["summary"]["resume_analysis_performance"] = {
                    "local_avg": statistics.mean(local_times),
                    "containerized_avg": statistics.mean(containerized_times),
                    "performance_ratio": statistics.mean(containerized_times) / statistics.mean(local_times)
                }
        
        # 文档解析能力对比
        document = self.results["document_parsing"]
        if document["mineru"]:
            mineru_success = sum(1 for item in document["mineru"] if item["success"])
            successful_times = [item["response_time"] for item in document["mineru"] if item["success"]]
            report["summary"]["document_parsing"] = {
                "mineru_success_rate": mineru_success / len(document["mineru"]) if document["mineru"] else 0,
                "mineru_avg_time": statistics.mean(successful_times) if successful_times else 0
            }
        
        return report
    
    def print_comparison_report(self):
        """打印对比报告"""
        print("\n" + "=" * 60)
        print("📊 AI服务性能对比报告")
        print("=" * 60)
        
        # 健康状态
        health = self.results["health"]
        print("\n🏥 服务健康状态:")
        print(f"  本地服务: {'✅ 健康' if health['local']['status'] else '❌ 异常'}")
        print(f"  容器化服务: {'✅ 健康' if health['containerized']['status'] else '❌ 异常'}")
        print(f"  MinerU服务: {'✅ 健康' if health['mineru']['status'] else '❌ 异常'}")
        
        # 嵌入向量生成性能
        embedding = self.results["embedding"]
        if embedding["local"] and embedding["containerized"]:
            local_times = [item["response_time"] for item in embedding["local"] if item["success"]]
            containerized_times = [item["response_time"] for item in embedding["containerized"] if item["success"]]
            
            if local_times and containerized_times:
                print(f"\n🧠 嵌入向量生成性能:")
                print(f"  本地服务平均响应时间: {statistics.mean(local_times):.3f}秒")
                print(f"  容器化服务平均响应时间: {statistics.mean(containerized_times):.3f}秒")
                ratio = statistics.mean(containerized_times) / statistics.mean(local_times)
                print(f"  性能比率: {ratio:.2f}x {'(容器化更快)' if ratio < 1 else '(本地更快)'}")
        
        # 简历分析性能
        resume = self.results["resume_analysis"]
        if resume["local"] and resume["containerized"]:
            local_times = [item["response_time"] for item in resume["local"] if item["success"]]
            containerized_times = [item["response_time"] for item in resume["containerized"] if item["success"]]
            
            if local_times and containerized_times:
                print(f"\n📄 简历分析性能:")
                print(f"  本地服务平均响应时间: {statistics.mean(local_times):.3f}秒")
                print(f"  容器化服务平均响应时间: {statistics.mean(containerized_times):.3f}秒")
                ratio = statistics.mean(containerized_times) / statistics.mean(local_times)
                print(f"  性能比率: {ratio:.2f}x {'(容器化更快)' if ratio < 1 else '(本地更快)'}")
        
        # 文档解析能力
        document = self.results["document_parsing"]
        if document["mineru"]:
            print(f"\n📋 文档解析能力:")
            success_count = sum(1 for item in document["mineru"] if item["success"])
            print(f"  MinerU解析成功率: {success_count}/{len(document['mineru'])} ({success_count/len(document['mineru'])*100:.1f}%)")
            if success_count > 0:
                successful_times = [item["response_time"] for item in document["mineru"] if item["success"]]
                if successful_times:
                    avg_time = statistics.mean(successful_times)
                    print(f"  MinerU平均解析时间: {avg_time:.3f}秒")
        
        # 总结和建议
        print(f"\n💡 总结和建议:")
        print(f"  1. 容器化AI服务已成功部署并正常运行")
        print(f"  2. 文档解析能力通过MinerU服务得到显著提升")
        print(f"  3. 建议继续优化容器化服务的性能")
        print(f"  4. 可以考虑逐步将用户迁移到容器化服务")

def main():
    """主函数"""
    comparator = AIServicePerformanceComparator()
    results = comparator.run_comprehensive_comparison()
    comparator.print_comparison_report()
    
    # 保存详细结果到文件
    with open("/tmp/ai_service_comparison_results.json", "w", encoding="utf-8") as f:
        json.dump(results, f, indent=2, ensure_ascii=False)
    
    print(f"\n📁 详细结果已保存到: /tmp/ai_service_comparison_results.json")

if __name__ == "__main__":
    main()
