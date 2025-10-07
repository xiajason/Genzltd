#!/usr/bin/env python3
"""
Future版快速验证测试
"""

import requests
import json
from datetime import datetime

def test_services():
    """测试所有Future版服务"""
    print("🚀 Future版服务快速验证测试")
    print("=" * 50)
    
    # 服务配置
    services = {
        'LoomaCRM': {
            'url': 'http://localhost:7500',
            'health_endpoint': '/health',
            'api_endpoint': '/crm/users'
        },
        'AI Gateway': {
            'url': 'http://localhost:7510',
            'health_endpoint': '/health',
            'api_endpoint': '/ai/chat'
        },
        'Resume AI': {
            'url': 'http://localhost:7511',
            'health_endpoint': '/health',
            'api_endpoint': '/resume/analyze'
        },
        'MinerU': {
            'url': 'http://localhost:8000',
            'health_endpoint': '/health',
            'api_endpoint': None
        },
        'AI Models': {
            'url': 'http://localhost:8002',
            'health_endpoint': '/health',
            'api_endpoint': None
        },
        'AI Service': {
            'url': 'http://localhost:7540',
            'health_endpoint': '/health',
            'api_endpoint': None
        }
    }
    
    results = {
        'total_tests': 0,
        'passed': 0,
        'failed': 0,
        'details': []
    }
    
    # 测试健康检查
    print("\n📊 健康检查测试:")
    for name, config in services.items():
        results['total_tests'] += 1
        try:
            response = requests.get(f"{config['url']}{config['health_endpoint']}", timeout=5)
            if response.status_code == 200:
                data = response.json()
                print(f"✅ {name}: 健康 ({data.get('service', 'unknown')})")
                results['passed'] += 1
                results['details'].append({
                    'service': name,
                    'test': 'health',
                    'status': 'passed',
                    'service_name': data.get('service', 'unknown')
                })
            else:
                print(f"❌ {name}: HTTP {response.status_code}")
                results['failed'] += 1
                results['details'].append({
                    'service': name,
                    'test': 'health',
                    'status': 'failed',
                    'error': f'HTTP {response.status_code}'
                })
        except Exception as e:
            print(f"❌ {name}: {str(e)}")
            results['failed'] += 1
            results['details'].append({
                'service': name,
                'test': 'health',
                'status': 'failed',
                'error': str(e)
            })
    
    # 测试API端点
    print("\n🔧 API端点测试:")
    
    # 测试LoomaCRM API
    results['total_tests'] += 1
    try:
        response = requests.get(f"{services['LoomaCRM']['url']}{services['LoomaCRM']['api_endpoint']}", timeout=5)
        if response.status_code == 200:
            data = response.json()
            print(f"✅ LoomaCRM API: 正常 (用户数: {data.get('total', 0)})")
            results['passed'] += 1
            results['details'].append({
                'service': 'LoomaCRM',
                'test': 'api',
                'status': 'passed',
                'users_count': data.get('total', 0)
            })
        else:
            print(f"❌ LoomaCRM API: HTTP {response.status_code}")
            results['failed'] += 1
    except Exception as e:
        print(f"❌ LoomaCRM API: {str(e)}")
        results['failed'] += 1
    
    # 测试AI Gateway API
    results['total_tests'] += 1
    try:
        response = requests.post(
            f"{services['AI Gateway']['url']}{services['AI Gateway']['api_endpoint']}",
            json={"prompt": "Hello", "user_id": "test"},
            timeout=10
        )
        if response.status_code == 200:
            data = response.json()
            print(f"✅ AI Gateway API: 正常 (响应: {data.get('response', '')[:50]}...)")
            results['passed'] += 1
            results['details'].append({
                'service': 'AI Gateway',
                'test': 'api',
                'status': 'passed',
                'response': data.get('response', '')[:50]
            })
        else:
            print(f"❌ AI Gateway API: HTTP {response.status_code}")
            results['failed'] += 1
    except Exception as e:
        print(f"❌ AI Gateway API: {str(e)}")
        results['failed'] += 1
    
    # 测试Resume AI API
    results['total_tests'] += 1
    try:
        response = requests.post(
            f"{services['Resume AI']['url']}{services['Resume AI']['api_endpoint']}",
            json={"resume_text": "Software Engineer with 5 years experience"},
            timeout=10
        )
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Resume AI API: 正常")
            results['passed'] += 1
            results['details'].append({
                'service': 'Resume AI',
                'test': 'api',
                'status': 'passed'
            })
        else:
            print(f"❌ Resume AI API: HTTP {response.status_code}")
            results['failed'] += 1
    except Exception as e:
        print(f"❌ Resume AI API: {str(e)}")
        results['failed'] += 1
    
    # 测试监控服务
    print("\n📈 监控服务测试:")
    monitoring_services = {
        'Grafana': 'http://localhost:3001',
        'Prometheus': 'http://localhost:9091/-/healthy',
        'AI Monitor': 'http://localhost:8623/-/healthy'
    }
    
    for name, url in monitoring_services.items():
        results['total_tests'] += 1
        try:
            response = requests.get(url, timeout=5)
            if response.status_code in [200, 302]:
                print(f"✅ {name}: 正常")
                results['passed'] += 1
            else:
                print(f"❌ {name}: HTTP {response.status_code}")
                results['failed'] += 1
        except Exception as e:
            print(f"❌ {name}: {str(e)}")
            results['failed'] += 1
    
    # 生成测试报告
    print("\n" + "=" * 50)
    print("📊 测试结果总结:")
    print(f"总测试数: {results['total_tests']}")
    print(f"通过: {results['passed']}")
    print(f"失败: {results['failed']}")
    print(f"成功率: {results['passed']/results['total_tests']*100:.1f}%")
    
    if results['passed']/results['total_tests'] >= 0.9:
        print("🎉 测试状态: ✅ 优秀")
    elif results['passed']/results['total_tests'] >= 0.8:
        print("🎯 测试状态: ⚠️ 良好")
    else:
        print("❌ 测试状态: 需要修复")
    
    # 保存测试结果
    test_report = {
        'timestamp': datetime.now().isoformat(),
        'test_name': 'Future版快速验证测试',
        'summary': {
            'total_tests': results['total_tests'],
            'passed': results['passed'],
            'failed': results['failed'],
            'success_rate': f"{results['passed']/results['total_tests']*100:.1f}%"
        },
        'details': results['details']
    }
    
    with open('/Users/szjason72/genzltd/quick_future_test_results.json', 'w', encoding='utf-8') as f:
        json.dump(test_report, f, indent=2, ensure_ascii=False)
    
    print(f"\n📄 测试报告已保存: quick_future_test_results.json")
    
    return results

if __name__ == "__main__":
    test_services()
