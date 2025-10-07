#!/usr/bin/env python3
"""
腾讯云三版本端到端测试验证脚本
"""

import requests
import json
import sys
from datetime import datetime

class TencentCloudE2ETest:
    def __init__(self, server_ip="101.33.251.158"):
        self.server_ip = server_ip
        self.base_url = f"http://{server_ip}"
        
        # 服务配置 - 基于腾讯云实际部署的容器
        self.services = {
            'DAO版服务': {
                'url': f'{self.base_url}:9200',
                'health_endpoint': '/',
                'api_endpoint': '/',
                'description': 'DAO版Web服务 (Nginx)'
            },
            'DAO PostgreSQL': {
                'url': f'{self.base_url}:5433',
                'health_endpoint': None,  # PostgreSQL没有HTTP健康检查
                'api_endpoint': None,
                'description': 'DAO版PostgreSQL数据库'
            },
            'DAO Redis': {
                'url': f'{self.base_url}:6380',
                'health_endpoint': None,  # Redis没有HTTP健康检查
                'api_endpoint': None,
                'description': 'DAO版Redis缓存'
            },
            '区块链服务': {
                'url': f'{self.base_url}:8300',
                'health_endpoint': '/',
                'api_endpoint': '/',
                'description': '区块链Web服务 (Node.js)'
            }
        }
    
    def test_service_connectivity(self):
        """测试服务连接性"""
        print("🔗 测试服务连接性...")
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
                if config['health_endpoint']:
                    # HTTP服务测试
                    response = requests.get(f"{config['url']}{config['health_endpoint']}", timeout=10)
                    if response.status_code in [200, 302]:
                        print(f"✅ {name}: 可访问 (HTTP {response.status_code})")
                        results['passed'] += 1
                        results['details'].append({
                            'service': name,
                            'test': 'connectivity',
                            'status': 'passed',
                            'http_code': response.status_code,
                            'response_size': len(response.content)
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
                else:
                    # 数据库服务测试 (通过端口连接测试)
                    import socket
                    try:
                        host, port = config['url'].replace('http://', '').split(':')
                        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                        sock.settimeout(5)
                        result = sock.connect_ex((host, int(port)))
                        sock.close()
                        
                        if result == 0:
                            print(f"✅ {name}: 端口可连接")
                            results['passed'] += 1
                            results['details'].append({
                                'service': name,
                                'test': 'connectivity',
                                'status': 'passed',
                                'port': port
                            })
                        else:
                            print(f"❌ {name}: 端口连接失败")
                            results['failed'] += 1
                            results['details'].append({
                                'service': name,
                                'test': 'connectivity',
                                'status': 'failed',
                                'error': 'Port connection failed'
                            })
                    except Exception as e:
                        print(f"❌ {name}: 连接测试失败 - {str(e)}")
                        results['failed'] += 1
                        results['details'].append({
                            'service': name,
                            'test': 'connectivity',
                            'status': 'failed',
                            'error': str(e)
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
    
    def test_dao_version_functionality(self):
        """测试DAO版功能"""
        print("\n🎯 测试DAO版功能...")
        print("=" * 50)
        
        results = {
            'total_tests': 0,
            'passed': 0,
            'failed': 0,
            'details': []
        }
        
        # 测试DAO Web服务
        results['total_tests'] += 1
        try:
            response = requests.get(f"{self.base_url}:9200/", timeout=10)
            if response.status_code == 200:
                print("✅ DAO Web服务: 正常响应")
                results['passed'] += 1
                results['details'].append({
                    'service': 'DAO Web',
                    'test': 'web_response',
                    'status': 'passed',
                    'content_type': response.headers.get('content-type', 'unknown'),
                    'content_length': len(response.content)
                })
            else:
                print(f"❌ DAO Web服务: HTTP {response.status_code}")
                results['failed'] += 1
        except Exception as e:
            print(f"❌ DAO Web服务: {str(e)}")
            results['failed'] += 1
        
        # 测试DAO PostgreSQL连接 (通过简单的HTTP请求模拟)
        results['total_tests'] += 1
        try:
            # 这里我们只能测试端口连接，因为PostgreSQL没有HTTP接口
            import socket
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(5)
            result = sock.connect_ex((self.server_ip, 5433))
            sock.close()
            
            if result == 0:
                print("✅ DAO PostgreSQL: 端口可连接")
                results['passed'] += 1
                results['details'].append({
                    'service': 'DAO PostgreSQL',
                    'test': 'port_connection',
                    'status': 'passed'
                })
            else:
                print("❌ DAO PostgreSQL: 端口连接失败")
                results['failed'] += 1
        except Exception as e:
            print(f"❌ DAO PostgreSQL: {str(e)}")
            results['failed'] += 1
        
        # 测试DAO Redis连接
        results['total_tests'] += 1
        try:
            import socket
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(5)
            result = sock.connect_ex((self.server_ip, 6380))
            sock.close()
            
            if result == 0:
                print("✅ DAO Redis: 端口可连接")
                results['passed'] += 1
                results['details'].append({
                    'service': 'DAO Redis',
                    'test': 'port_connection',
                    'status': 'passed'
                })
            else:
                print("❌ DAO Redis: 端口连接失败")
                results['failed'] += 1
        except Exception as e:
            print(f"❌ DAO Redis: {str(e)}")
            results['failed'] += 1
        
        return results
    
    def test_blockchain_version_functionality(self):
        """测试区块链版功能"""
        print("\n⛓️ 测试区块链版功能...")
        print("=" * 50)
        
        results = {
            'total_tests': 0,
            'passed': 0,
            'failed': 0,
            'details': []
        }
        
        # 测试区块链Web服务
        results['total_tests'] += 1
        try:
            response = requests.get(f"{self.base_url}:8300/", timeout=10)
            if response.status_code == 200:
                content = response.text
                print("✅ 区块链Web服务: 正常响应")
                results['passed'] += 1
                results['details'].append({
                    'service': 'Blockchain Web',
                    'test': 'web_response',
                    'status': 'passed',
                    'content_type': response.headers.get('content-type', 'unknown'),
                    'content_preview': content[:100] + '...' if len(content) > 100 else content
                })
            else:
                print(f"❌ 区块链Web服务: HTTP {response.status_code}")
                results['failed'] += 1
                results['details'].append({
                    'service': 'Blockchain Web',
                    'test': 'web_response',
                    'status': 'failed',
                    'error': f'HTTP {response.status_code}'
                })
        except Exception as e:
            print(f"❌ 区块链Web服务: {str(e)}")
            results['failed'] += 1
            results['details'].append({
                'service': 'Blockchain Web',
                'test': 'web_response',
                'status': 'failed',
                'error': str(e)
            })
        
        return results
    
    def test_cross_service_integration(self):
        """测试跨服务集成"""
        print("\n🔗 测试跨服务集成...")
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
        
        for name, config in self.services.items():
            try:
                if config['health_endpoint']:
                    response = requests.get(f"{config['url']}{config['health_endpoint']}", timeout=5)
                    services_status.append(response.status_code in [200, 302])
                else:
                    # 数据库服务端口测试
                    import socket
                    host, port = config['url'].replace('http://', '').split(':')
                    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                    sock.settimeout(3)
                    result = sock.connect_ex((host, int(port)))
                    sock.close()
                    services_status.append(result == 0)
            except:
                services_status.append(False)
        
        if all(services_status):
            print("✅ 跨服务集成: 所有服务同时可访问")
            results['passed'] += 1
            results['details'].append({
                'service': 'Cross Service Integration',
                'test': 'all_services_accessible',
                'status': 'passed',
                'services_count': len(services_status)
            })
        else:
            print("❌ 跨服务集成: 部分服务不可访问")
            results['failed'] += 1
            results['details'].append({
                'service': 'Cross Service Integration',
                'test': 'all_services_accessible',
                'status': 'failed',
                'services_status': services_status
            })
        
        return results
    
    def run_all_tests(self):
        """运行所有测试"""
        print("🚀 腾讯云三版本端到端测试开始")
        print(f"🌐 服务器IP: {self.server_ip}")
        print(f"⏰ 测试时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print("=" * 60)
        
        # 运行各项测试
        connectivity_results = self.test_service_connectivity()
        dao_results = self.test_dao_version_functionality()
        blockchain_results = self.test_blockchain_version_functionality()
        integration_results = self.test_cross_service_integration()
        
        # 汇总结果
        total_tests = (connectivity_results['total_tests'] + 
                      dao_results['total_tests'] + 
                      blockchain_results['total_tests'] + 
                      integration_results['total_tests'])
        
        total_passed = (connectivity_results['passed'] + 
                       dao_results['passed'] + 
                       blockchain_results['passed'] + 
                       integration_results['passed'])
        
        total_failed = (connectivity_results['failed'] + 
                       dao_results['failed'] + 
                       blockchain_results['failed'] + 
                       integration_results['failed'])
        
        # 生成测试报告
        test_report = {
            'timestamp': datetime.now().isoformat(),
            'server_ip': self.server_ip,
            'test_name': '腾讯云三版本端到端测试',
            'summary': {
                'total_tests': total_tests,
                'passed': total_passed,
                'failed': total_failed,
                'success_rate': f"{total_passed/total_tests*100:.1f}%" if total_tests > 0 else "0%"
            },
            'test_results': {
                'connectivity': connectivity_results,
                'dao_version': dao_results,
                'blockchain_version': blockchain_results,
                'integration': integration_results
            }
        }
        
        # 保存测试报告
        report_filename = f'tencent_cloud_test_results_{datetime.now().strftime("%Y%m%d_%H%M%S")}.json'
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
        server_ip = "101.33.251.158"  # 默认腾讯云IP
    
    tester = TencentCloudE2ETest(server_ip)
    results = tester.run_all_tests()
    
    # 返回适当的退出码
    success_rate = results['summary']['passed'] / results['summary']['total_tests'] if results['summary']['total_tests'] > 0 else 0
    sys.exit(0 if success_rate >= 0.8 else 1)

if __name__ == "__main__":
    main()
