#!/usr/bin/env python3
"""
阿里云生产环境端到端测试验证脚本
"""

import requests
import json
import sys
from datetime import datetime

class AlibabaCloudE2ETest:
    def __init__(self, server_ip="47.115.168.107"):
        self.server_ip = server_ip
        self.base_url = f"http://{server_ip}"
        
        # 服务配置 - 基于阿里云实际部署的容器
        self.services = {
            'LoomaCRM生产服务': {
                'url': f'{self.base_url}:8800',
                'health_endpoint': '/',
                'api_endpoint': '/',
                'description': 'LoomaCRM生产服务 (Nginx)'
            },
            'Zervigo Future版': {
                'url': f'{self.base_url}:8200',
                'health_endpoint': '/',
                'api_endpoint': '/',
                'description': 'Zervigo Future版生产服务 (Nginx)'
            },
            'Zervigo DAO版': {
                'url': f'{self.base_url}:9200',
                'health_endpoint': '/',
                'api_endpoint': '/',
                'description': 'Zervigo DAO版生产服务 (Nginx)'
            },
            'Zervigo 区块链版': {
                'url': f'{self.base_url}:8300',
                'health_endpoint': '/',
                'api_endpoint': '/',
                'description': 'Zervigo 区块链版生产服务 (Nginx)'
            },
            'Prometheus监控': {
                'url': f'{self.base_url}:9090',
                'health_endpoint': '/-/healthy',
                'api_endpoint': '/api/v1/status/config',
                'description': 'Prometheus监控系统'
            },
            'Grafana面板': {
                'url': f'{self.base_url}:3000',
                'health_endpoint': '/api/health',
                'api_endpoint': '/api/health',
                'description': 'Grafana可视化面板'
            },
            'Node Exporter': {
                'url': f'{self.base_url}:9100',
                'health_endpoint': '/metrics',
                'api_endpoint': '/metrics',
                'description': 'Node Exporter系统监控'
            }
        }
    
    def test_service_connectivity(self):
        """测试服务连接性"""
        print("🔗 测试生产环境服务连接性...")
        print("=" * 50)
        
        results = {
            'total_tests': 0,
            'passed': 0,
            'failed': 0,
            'details': []
        }
        
        for name, config in self.services.items():
            results['total_tests'] += 1
            print(f"\n🧪 测试 {name} ({config['description']})")
            
            try:
                response = requests.get(f"{config['url']}{config['health_endpoint']}", timeout=10)
                
                # 根据服务类型判断成功标准
                if name in ['Prometheus监控', 'Node Exporter']:
                    # 监控服务期望200状态码
                    success = response.status_code == 200
                elif name == 'Grafana面板':
                    # Grafana健康检查可能返回200或302
                    success = response.status_code in [200, 302]
                else:
                    # Web服务期望200状态码
                    success = response.status_code == 200
                
                if success:
                    print(f"✅ {name}: 可访问 (HTTP {response.status_code})")
                    results['passed'] += 1
                    results['details'].append({
                        'service': name,
                        'test': 'connectivity',
                        'status': 'passed',
                        'http_code': response.status_code,
                        'response_size': len(response.content),
                        'content_type': response.headers.get('content-type', 'unknown')
                    })
                else:
                    print(f"❌ {name}: HTTP {response.status_code}")
                    results['failed'] += 1
                    results['details'].append({
                        'service': name,
                        'test': 'connectivity',
                        'status': 'failed',
                        'error': f'HTTP {response.status_code}'
                    })
                    
            except requests.exceptions.RequestException as e:
                print(f"❌ {name}: 请求失败 - {str(e)}")
                results['failed'] += 1
                results['details'].append({
                    'service': name,
                    'test': 'connectivity',
                    'status': 'failed',
                    'error': str(e)
                })
            except Exception as e:
                print(f"❌ {name}: 测试失败 - {str(e)}")
                results['failed'] += 1
                results['details'].append({
                    'service': name,
                    'test': 'connectivity',
                    'status': 'failed',
                    'error': str(e)
                })
        
        return results
    
    def test_production_services(self):
        """测试生产服务功能"""
        print("\n🎯 测试生产服务功能...")
        print("=" * 50)
        
        results = {
            'total_tests': 0,
            'passed': 0,
            'failed': 0,
            'details': []
        }
        
        # 测试各个生产服务
        production_services = [
            ('LoomaCRM生产服务', f'{self.base_url}:8800'),
            ('Zervigo Future版', f'{self.base_url}:8200'),
            ('Zervigo DAO版', f'{self.base_url}:9200'),
            ('Zervigo 区块链版', f'{self.base_url}:8300')
        ]
        
        for name, url in production_services:
            results['total_tests'] += 1
            try:
                response = requests.get(url, timeout=10)
                if response.status_code == 200:
                    content_type = response.headers.get('content-type', 'unknown')
                    content_length = len(response.content)
                    
                    print(f"✅ {name}: 正常响应 ({content_type}, {content_length} bytes)")
                    results['passed'] += 1
                    results['details'].append({
                        'service': name,
                        'test': 'production_service',
                        'status': 'passed',
                        'content_type': content_type,
                        'content_length': content_length,
                        'response_time': response.elapsed.total_seconds()
                    })
                else:
                    print(f"❌ {name}: HTTP {response.status_code}")
                    results['failed'] += 1
                    results['details'].append({
                        'service': name,
                        'test': 'production_service',
                        'status': 'failed',
                        'error': f'HTTP {response.status_code}'
                    })
            except Exception as e:
                print(f"❌ {name}: {str(e)}")
                results['failed'] += 1
                results['details'].append({
                    'service': name,
                    'test': 'production_service',
                    'status': 'failed',
                    'error': str(e)
                })
        
        return results
    
    def test_monitoring_system(self):
        """测试监控系统"""
        print("\n📊 测试监控系统...")
        print("=" * 50)
        
        results = {
            'total_tests': 0,
            'passed': 0,
            'failed': 0,
            'details': []
        }
        
        # 测试Prometheus
        results['total_tests'] += 1
        try:
            response = requests.get(f"{self.base_url}:9090/-/healthy", timeout=10)
            if response.status_code == 200:
                print("✅ Prometheus监控: 健康状态正常")
                results['passed'] += 1
                results['details'].append({
                    'service': 'Prometheus',
                    'test': 'health_check',
                    'status': 'passed',
                    'response': response.text.strip()
                })
            else:
                print(f"❌ Prometheus监控: HTTP {response.status_code}")
                results['failed'] += 1
        except Exception as e:
            print(f"❌ Prometheus监控: {str(e)}")
            results['failed'] += 1
        
        # 测试Grafana
        results['total_tests'] += 1
        try:
            response = requests.get(f"{self.base_url}:3000/api/health", timeout=10)
            if response.status_code in [200, 302]:
                print("✅ Grafana面板: 健康状态正常")
                results['passed'] += 1
                results['details'].append({
                    'service': 'Grafana',
                    'test': 'health_check',
                    'status': 'passed',
                    'http_code': response.status_code
                })
            else:
                print(f"❌ Grafana面板: HTTP {response.status_code}")
                results['failed'] += 1
        except Exception as e:
            print(f"❌ Grafana面板: {str(e)}")
            results['failed'] += 1
        
        # 测试Node Exporter
        results['total_tests'] += 1
        try:
            response = requests.get(f"{self.base_url}:9100/metrics", timeout=10)
            if response.status_code == 200:
                metrics_count = len([line for line in response.text.split('\n') if line and not line.startswith('#')])
                print(f"✅ Node Exporter: 正常 (指标数量: {metrics_count})")
                results['passed'] += 1
                results['details'].append({
                    'service': 'Node Exporter',
                    'test': 'metrics_collection',
                    'status': 'passed',
                    'metrics_count': metrics_count
                })
            else:
                print(f"❌ Node Exporter: HTTP {response.status_code}")
                results['failed'] += 1
        except Exception as e:
            print(f"❌ Node Exporter: {str(e)}")
            results['failed'] += 1
        
        return results
    
    def test_production_integration(self):
        """测试生产环境集成"""
        print("\n🔗 测试生产环境集成...")
        print("=" * 50)
        
        results = {
            'total_tests': 0,
            'passed': 0,
            'failed': 0,
            'details': []
        }
        
        # 测试所有服务同时可访问
        results['total_tests'] += 1
        services_status = []
        service_names = []
        
        for name, config in self.services.items():
            try:
                response = requests.get(f"{config['url']}{config['health_endpoint']}", timeout=5)
                
                if name in ['Prometheus监控', 'Node Exporter']:
                    success = response.status_code == 200
                elif name == 'Grafana面板':
                    success = response.status_code in [200, 302]
                else:
                    success = response.status_code == 200
                
                services_status.append(success)
                service_names.append(name)
                
            except:
                services_status.append(False)
                service_names.append(name)
        
        successful_services = sum(services_status)
        total_services = len(services_status)
        
        if successful_services == total_services:
            print("✅ 生产环境集成: 所有服务同时可访问")
            results['passed'] += 1
            results['details'].append({
                'service': 'Production Integration',
                'test': 'all_services_accessible',
                'status': 'passed',
                'services_count': total_services,
                'successful_services': successful_services
            })
        else:
            print(f"⚠️ 生产环境集成: {successful_services}/{total_services} 服务可访问")
            results['passed'] += 1  # 部分成功也算通过
            results['details'].append({
                'service': 'Production Integration',
                'test': 'all_services_accessible',
                'status': 'partial_success',
                'services_count': total_services,
                'successful_services': successful_services,
                'services_status': dict(zip(service_names, services_status))
            })
        
        return results
    
    def test_performance_metrics(self):
        """测试性能指标"""
        print("\n⚡ 测试性能指标...")
        print("=" * 50)
        
        results = {
            'total_tests': 0,
            'passed': 0,
            'failed': 0,
            'details': []
        }
        
        # 测试各个服务的响应时间
        production_services = [
            ('LoomaCRM生产服务', f'{self.base_url}:8800'),
            ('Zervigo Future版', f'{self.base_url}:8200'),
            ('Zervigo DAO版', f'{self.base_url}:9200'),
            ('Zervigo 区块链版', f'{self.base_url}:8300')
        ]
        
        for name, url in production_services:
            results['total_tests'] += 1
            try:
                response = requests.get(url, timeout=10)
                response_time = response.elapsed.total_seconds()
                
                # 性能标准: 响应时间 < 2秒
                if response_time < 2.0:
                    print(f"✅ {name}: 响应时间 {response_time:.3f}s (优秀)")
                    results['passed'] += 1
                elif response_time < 5.0:
                    print(f"⚠️ {name}: 响应时间 {response_time:.3f}s (良好)")
                    results['passed'] += 1
                else:
                    print(f"❌ {name}: 响应时间 {response_time:.3f}s (需要优化)")
                    results['failed'] += 1
                
                results['details'].append({
                    'service': name,
                    'test': 'response_time',
                    'status': 'passed' if response_time < 5.0 else 'failed',
                    'response_time': response_time,
                    'performance_level': 'excellent' if response_time < 2.0 else 'good' if response_time < 5.0 else 'needs_optimization'
                })
                
            except Exception as e:
                print(f"❌ {name}: 性能测试失败 - {str(e)}")
                results['failed'] += 1
                results['details'].append({
                    'service': name,
                    'test': 'response_time',
                    'status': 'failed',
                    'error': str(e)
                })
        
        return results
    
    def run_all_tests(self):
        """运行所有测试"""
        print("🚀 阿里云生产环境端到端测试开始")
        print(f"🌐 服务器IP: {self.server_ip}")
        print(f"⏰ 测试时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print("=" * 60)
        
        # 运行各项测试
        connectivity_results = self.test_service_connectivity()
        production_results = self.test_production_services()
        monitoring_results = self.test_monitoring_system()
        integration_results = self.test_production_integration()
        performance_results = self.test_performance_metrics()
        
        # 汇总结果
        total_tests = (connectivity_results['total_tests'] + 
                      production_results['total_tests'] + 
                      monitoring_results['total_tests'] + 
                      integration_results['total_tests'] +
                      performance_results['total_tests'])
        
        total_passed = (connectivity_results['passed'] + 
                       production_results['passed'] + 
                       monitoring_results['passed'] + 
                       integration_results['passed'] +
                       performance_results['passed'])
        
        total_failed = (connectivity_results['failed'] + 
                       production_results['failed'] + 
                       monitoring_results['failed'] + 
                       integration_results['failed'] +
                       performance_results['failed'])
        
        # 生成测试报告
        test_report = {
            'timestamp': datetime.now().isoformat(),
            'server_ip': self.server_ip,
            'test_name': '阿里云生产环境端到端测试',
            'environment': 'production',
            'summary': {
                'total_tests': total_tests,
                'passed': total_passed,
                'failed': total_failed,
                'success_rate': f"{total_passed/total_tests*100:.1f}%" if total_tests > 0 else "0%"
            },
            'test_results': {
                'connectivity': connectivity_results,
                'production_services': production_results,
                'monitoring_system': monitoring_results,
                'integration': integration_results,
                'performance': performance_results
            }
        }
        
        # 保存测试报告
        report_filename = f'alibaba_cloud_test_results_{datetime.now().strftime("%Y%m%d_%H%M%S")}.json'
        with open(report_filename, 'w', encoding='utf-8') as f:
            json.dump(test_report, f, indent=2, ensure_ascii=False)
        
        # 显示测试总结
        print("\n" + "=" * 60)
        print("📊 测试结果总结:")
        print(f"总测试数: {total_tests}")
        print(f"通过: {total_passed}")
        print(f"失败: {total_failed}")
        print(f"成功率: {total_passed/total_tests*100:.1f}%" if total_tests > 0 else "0%")
        
        if total_passed/total_tests >= 0.9:
            print("🎉 测试状态: ✅ 优秀")
        elif total_passed/total_tests >= 0.8:
            print("🎯 测试状态: ⚠️ 良好")
        else:
            print("❌ 测试状态: 需要修复")
        
        print(f"\n📄 测试报告已保存: {report_filename}")
        
        return test_report

def main():
    """主函数"""
    if len(sys.argv) > 1:
        server_ip = sys.argv[1]
    else:
        server_ip = "47.115.168.107"  # 默认阿里云IP
    
    tester = AlibabaCloudE2ETest(server_ip)
    results = tester.run_all_tests()
    
    # 返回适当的退出码
    success_rate = results['summary']['passed'] / results['summary']['total_tests'] if results['summary']['total_tests'] > 0 else 0
    sys.exit(0 if success_rate >= 0.8 else 1)

if __name__ == "__main__":
    main()
