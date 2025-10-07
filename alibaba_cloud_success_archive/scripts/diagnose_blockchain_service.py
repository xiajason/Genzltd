#!/usr/bin/env python3
"""
区块链服务诊断脚本
专门用于诊断阿里云区块链版服务(8300端口)的连接问题
"""

import requests
import socket
import time
import json
from datetime import datetime

# 配置
ALIBABA_CLOUD_IP = "47.115.168.107"
BLOCKCHAIN_PORT = 8300

def check_port_connectivity(host, port, timeout=5):
    """检查端口连接性"""
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.settimeout(timeout)
            result = s.connect_ex((host, port))
            return result == 0
    except Exception as e:
        print(f"端口连接检查异常: {e}")
        return False

def test_http_protocols(host, port):
    """测试不同的HTTP协议和请求"""
    protocols_to_test = [
        {"name": "HTTP GET", "method": "GET", "url": f"http://{host}:{port}"},
        {"name": "HTTP GET /", "method": "GET", "url": f"http://{host}:{port}/"},
        {"name": "HTTP GET /health", "method": "GET", "url": f"http://{host}:{port}/health"},
        {"name": "HTTP GET /status", "method": "GET", "url": f"http://{host}:{port}/status"},
        {"name": "HTTP GET /api", "method": "GET", "url": f"http://{host}:{port}/api"},
        {"name": "HTTP POST", "method": "POST", "url": f"http://{host}:{port}", "data": {}},
    ]
    
    results = []
    
    for protocol in protocols_to_test:
        print(f"\n🧪 测试 {protocol['name']}...")
        try:
            if protocol['method'] == 'GET':
                response = requests.get(protocol['url'], timeout=10)
            else:
                response = requests.post(protocol['url'], json=protocol.get('data', {}), timeout=10)
            
            print(f"✅ {protocol['name']}: HTTP {response.status_code}")
            print(f"   响应大小: {len(response.content)} bytes")
            print(f"   Content-Type: {response.headers.get('Content-Type', 'N/A')}")
            if response.text:
                print(f"   响应预览: {response.text[:100]}...")
            
            results.append({
                "protocol": protocol['name'],
                "status": "success",
                "http_code": response.status_code,
                "content_length": len(response.content),
                "content_type": response.headers.get('Content-Type'),
                "response_preview": response.text[:200]
            })
            
        except requests.exceptions.ConnectionError as e:
            print(f"❌ {protocol['name']}: 连接错误 - {e}")
            results.append({
                "protocol": protocol['name'],
                "status": "connection_error",
                "error": str(e)
            })
            
        except requests.exceptions.Timeout as e:
            print(f"❌ {protocol['name']}: 超时 - {e}")
            results.append({
                "protocol": protocol['name'],
                "status": "timeout",
                "error": str(e)
            })
            
        except requests.exceptions.RequestException as e:
            print(f"❌ {protocol['name']}: 请求异常 - {e}")
            results.append({
                "protocol": protocol['name'],
                "status": "request_error",
                "error": str(e)
            })
    
    return results

def main():
    print("🔍 阿里云区块链服务诊断")
    print(f"🌐 目标服务器: {ALIBABA_CLOUD_IP}:{BLOCKCHAIN_PORT}")
    print(f"⏰ 诊断时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 60)
    
    # 1. 检查端口连接性
    print("\n📡 步骤1: 检查端口连接性")
    print("-" * 40)
    port_open = check_port_connectivity(ALIBABA_CLOUD_IP, BLOCKCHAIN_PORT)
    print(f"端口 {BLOCKCHAIN_PORT} 连接状态: {'✅ 开放' if port_open else '❌ 关闭'}")
    
    if not port_open:
        print("❌ 端口不可达，请检查:")
        print("   1. 服务是否启动")
        print("   2. 防火墙配置")
        print("   3. 安全组规则")
        return
    
    # 2. 测试HTTP协议
    print("\n🌐 步骤2: 测试HTTP协议")
    print("-" * 40)
    http_results = test_http_protocols(ALIBABA_CLOUD_IP, BLOCKCHAIN_PORT)
    
    # 3. 分析结果
    print("\n📊 步骤3: 诊断结果分析")
    print("-" * 40)
    
    successful_protocols = [r for r in http_results if r['status'] == 'success']
    failed_protocols = [r for r in http_results if r['status'] != 'success']
    
    print(f"成功协议数: {len(successful_protocols)}")
    print(f"失败协议数: {len(failed_protocols)}")
    
    if successful_protocols:
        print("\n✅ 成功的协议:")
        for result in successful_protocols:
            print(f"   - {result['protocol']}: HTTP {result['http_code']}")
    
    if failed_protocols:
        print("\n❌ 失败的协议:")
        for result in failed_protocols:
            print(f"   - {result['protocol']}: {result['error']}")
    
    # 4. 建议
    print("\n💡 诊断建议")
    print("-" * 40)
    
    if successful_protocols:
        print("✅ 服务正常运行，HTTP请求成功")
        print("   建议: 检查应用层配置和路由规则")
    elif port_open and not successful_protocols:
        print("⚠️ 端口开放但HTTP服务异常")
        print("   可能原因:")
        print("   1. 服务监听非HTTP协议")
        print("   2. 服务配置错误")
        print("   3. 应用层防火墙")
        print("   4. 负载均衡器配置")
    else:
        print("❌ 端口不可达")
        print("   建议检查服务状态和网络配置")
    
    # 保存诊断报告
    report = {
        "timestamp": datetime.now().isoformat(),
        "target": f"{ALIBABA_CLOUD_IP}:{BLOCKCHAIN_PORT}",
        "port_connectivity": port_open,
        "http_test_results": http_results,
        "summary": {
            "total_tests": len(http_results),
            "successful": len(successful_protocols),
            "failed": len(failed_protocols)
        }
    }
    
    report_filename = f"blockchain_diagnosis_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
    with open(report_filename, "w", encoding="utf-8") as f:
        json.dump(report, f, ensure_ascii=False, indent=2)
    
    print(f"\n📄 诊断报告已保存: {report_filename}")

if __name__ == "__main__":
    main()
