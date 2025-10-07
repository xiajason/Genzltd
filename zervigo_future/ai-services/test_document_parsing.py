#!/usr/bin/env python3
"""
文档解析功能测试
测试MinerU服务的文档解析能力
"""

import requests
import json
import time
import os
from typing import Dict, Any

class DocumentParsingTester:
    """文档解析测试器"""
    
    def __init__(self):
        self.mineru_url = "http://localhost:8001"
    
    def create_test_documents(self) -> Dict[str, str]:
        """创建测试文档"""
        test_docs = {}
        
        # 使用已创建的PDF文件
        pdf_path = "/tmp/test_resume.pdf"
        if os.path.exists(pdf_path):
            test_docs["pdf"] = pdf_path
        else:
            print("⚠️ PDF测试文件不存在，请先运行 create_test_pdf.py")
        
        return test_docs
    
    def test_upload_and_parse(self, file_path: str) -> Dict[str, Any]:
        """测试上传并解析文档"""
        try:
            print(f"📄 测试文档解析: {file_path}")
            
            with open(file_path, "rb") as f:
                files = {"file": f}
                data = {"user_id": "1"}  # 添加用户ID参数
                start_time = time.time()
                response = requests.post(
                    f"{self.mineru_url}/api/v1/parse/upload",
                    files=files,
                    data=data,
                    timeout=30
                )
                end_time = time.time()
            
            result = {
                "file_path": file_path,
                "response_time": end_time - start_time,
                "status_code": response.status_code,
                "success": response.status_code == 200
            }
            
            if response.status_code == 200:
                data = response.json()
                result_data = data.get("result", {})
                result.update({
                    "parsed_content": result_data.get("content", ""),
                    "content_length": len(result_data.get("content", "")),
                    "confidence": result_data.get("confidence", 0),
                    "file_type": result_data.get("file_type", "unknown")
                })
                print(f"  ✅ 解析成功: {result['content_length']}字符, 置信度: {result['confidence']}")
            else:
                result["error"] = response.text
                print(f"  ❌ 解析失败: {response.status_code} - {response.text}")
            
            return result
            
        except Exception as e:
            print(f"  ❌ 测试异常: {e}")
            return {
                "file_path": file_path,
                "success": False,
                "error": str(e)
            }
    
    def test_parse_status(self) -> Dict[str, Any]:
        """测试解析状态"""
        try:
            response = requests.get(f"{self.mineru_url}/api/v1/parse/status", timeout=5)
            if response.status_code == 200:
                data = response.json()
                print(f"📊 解析状态: {data.get('current_tasks', 0)}个任务进行中")
                return data
            else:
                print(f"❌ 状态查询失败: {response.status_code}")
                return {"error": response.text}
        except Exception as e:
            print(f"❌ 状态查询异常: {e}")
            return {"error": str(e)}
    
    def run_document_parsing_test(self):
        """运行文档解析测试"""
        print("🚀 开始文档解析功能测试")
        print("=" * 50)
        
        # 1. 检查服务状态
        print("🔍 检查MinerU服务状态...")
        status = self.test_parse_status()
        
        # 2. 创建测试文档
        print("\n📝 创建测试文档...")
        test_docs = self.create_test_documents()
        
        # 3. 测试文档解析
        print("\n📄 测试文档解析...")
        results = []
        for doc_type, file_path in test_docs.items():
            result = self.test_upload_and_parse(file_path)
            results.append(result)
        
        # 4. 清理测试文件
        print("\n🧹 清理测试文件...")
        for file_path in test_docs.values():
            try:
                os.remove(file_path)
                print(f"  删除: {file_path}")
            except:
                pass
        
        # 5. 生成测试报告
        print("\n" + "=" * 50)
        print("📊 文档解析测试报告")
        print("=" * 50)
        
        success_count = sum(1 for r in results if r.get("success", False))
        total_count = len(results)
        
        print(f"测试文档数量: {total_count}")
        print(f"解析成功数量: {success_count}")
        print(f"成功率: {success_count/total_count*100:.1f}%")
        
        if success_count > 0:
            successful_results = [r for r in results if r.get("success", False)]
            avg_time = sum(r["response_time"] for r in successful_results) / len(successful_results)
            avg_confidence = sum(r.get("confidence", 0) for r in successful_results) / len(successful_results)
            avg_content_length = sum(r.get("content_length", 0) for r in successful_results) / len(successful_results)
            
            print(f"平均解析时间: {avg_time:.3f}秒")
            print(f"平均置信度: {avg_confidence:.2f}")
            print(f"平均内容长度: {avg_content_length:.0f}字符")
        
        # 6. 详细结果
        print(f"\n📋 详细结果:")
        for i, result in enumerate(results, 1):
            print(f"  文档{i}: {os.path.basename(result['file_path'])}")
            if result.get("success", False):
                print(f"    ✅ 成功 - 时间: {result['response_time']:.3f}s, 长度: {result['content_length']}字符")
            else:
                print(f"    ❌ 失败 - {result.get('error', '未知错误')}")
        
        return results

def main():
    """主函数"""
    tester = DocumentParsingTester()
    results = tester.run_document_parsing_test()
    
    # 保存结果到文件
    with open("/tmp/document_parsing_test_results.json", "w", encoding="utf-8") as f:
        json.dump(results, f, indent=2, ensure_ascii=False)
    
    print(f"\n📁 详细结果已保存到: /tmp/document_parsing_test_results.json")

if __name__ == "__main__":
    main()
