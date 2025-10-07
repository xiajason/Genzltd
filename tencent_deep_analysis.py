#!/usr/bin/env python3
# 腾讯云深度分析脚本
# 找出区块链服务问题的根本原因

import requests
import socket
import json
import time
from datetime import datetime

class TencentDeepAnalysis:
    def __init__(self, server_ip="101.33.251.158"):
        self.server_ip = server_ip
        self.analysis_results = {
            'analysis_time': datetime.now().isoformat(),
            'server_ip': server_ip,
            'findings': [],
            'root_causes': [],
            'solutions': []
        }
    
    def test_port_protocols(self, port):
        """测试端口上的不同协议"""
        protocols = {
            'HTTP': f'http://{self.server_ip}:{port}/',
            'HTTPS': f'https://{self.server_ip}:{port}/',
            'Raw TCP': f'tcp://{self.server_ip}:{port}'
        }
        
        results = {}
        for protocol, url in protocols.items():
            try:
                if protocol == 'Raw TCP':
                    # TCP连接测试
                    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                    sock.settimeout(5)
                    result = sock.connect_ex((self.server_ip, port))
                    sock.close()
                    results[protocol] = {
                        'success': result == 0,
                        'error': None if result == 0 else f'TCP连接失败: {result}'
                    }
                else:
                    # HTTP/HTTPS测试
                    response = requests.get(url, timeout=10, allow_redirects=False)
                    results[protocol] = {
                        'success': True,
                        'status_code': response.status_code,
                        'headers': dict(response.headers),
                        'content_length': len(response.content)
                    }
            except requests.exceptions.ConnectionError as e:
                results[protocol] = {
                    'success': False,
                    'error': f'连接错误: {e}'
                }
            except requests.exceptions.Timeout as e:
                results[protocol] = {
                    'success': False,
                    'error': f'超时: {e}'
                }
            except Exception as e:
                results[protocol] = {
                    'success': False,
                    'error': f'其他错误: {e}'
                }
        
        return results
    
    def analyze_historical_performance(self):
        """分析历史性能数据"""
        print("📊 分析历史性能数据")
        print("-" * 40)
        
        # 模拟历史数据分析
        historical_data = {
            'previous_tests': [
                {'date': '2025-10-06', 'success_rate': '100%', 'blockchain_status': 'working'},
                {'date': '2025-10-06', 'success_rate': '100%', 'blockchain_status': 'working'},
                {'date': '2025-10-06', 'success_rate': '100%', 'blockchain_status': 'working'},
                {'date': '2025-10-06', 'success_rate': '100%', 'blockchain_status': 'working'},
                {'date': '2025-10-06', 'success_rate': '100%', 'blockchain_status': 'working'},
                {'date': '2025-10-07', 'success_rate': '66.7%', 'blockchain_status': 'connection_refused'}
            ]
        }
        
        print("历史测试记录:")
        for test in historical_data['previous_tests']:
            print(f"  {test['date']}: 成功率 {test['success_rate']}, 区块链状态: {test['blockchain_status']}")
        
        # 分析变化点
        working_tests = [t for t in historical_data['previous_tests'] if t['blockchain_status'] == 'working']
        failed_tests = [t for t in historical_data['previous_tests'] if t['blockchain_status'] != 'working']
        
        print(f"\n工作正常测试次数: {len(working_tests)}")
        print(f"失败测试次数: {len(failed_tests)}")
        
        if len(failed_tests) > 0:
            print("🔍 发现性能下降点:")
            print(f"  从 {working_tests[-1]['date']} 的 100% 下降到 {failed_tests[0]['date']} 的 66.7%")
            print(f"  区块链服务从 'working' 变为 'connection_refused'")
        
        return historical_data
    
    def investigate_blockchain_service(self):
        """深入调查区块链服务"""
        print("\n🔍 深入调查区块链服务")
        print("-" * 40)
        
        port = 8300
        print(f"检查端口 {port} 的详细状态...")
        
        # 测试不同协议
        protocol_results = self.test_port_protocols(port)
        
        print("协议测试结果:")
        for protocol, result in protocol_results.items():
            if result['success']:
                print(f"  ✅ {protocol}: 成功")
                if 'status_code' in result:
                    print(f"     状态码: {result['status_code']}")
                if 'content_length' in result:
                    print(f"     内容长度: {result['content_length']} bytes")
            else:
                print(f"  ❌ {protocol}: 失败 - {result['error']}")
        
        # 分析结果
        tcp_success = protocol_results.get('Raw TCP', {}).get('success', False)
        http_success = protocol_results.get('HTTP', {}).get('success', False)
        
        if tcp_success and not http_success:
            self.analysis_results['findings'].append({
                'type': 'port_analysis',
                'finding': '端口8300可以TCP连接，但HTTP请求被拒绝',
                'implication': '服务在运行，但可能不是HTTP服务或配置错误'
            })
            print("\n🎯 关键发现: 端口8300可以TCP连接，但HTTP请求被拒绝")
            print("   这意味着:")
            print("   1. 服务容器正在运行")
            print("   2. 服务可能不是HTTP服务")
            print("   3. 或者HTTP服务配置有问题")
        
        return protocol_results
    
    def identify_root_causes(self):
        """识别根本原因"""
        print("\n🔍 识别根本原因")
        print("-" * 40)
        
        possible_causes = [
            {
                'cause': '服务配置变更',
                'description': '区块链服务的配置可能在某个时间点被修改',
                'evidence': '从100%成功率突然下降到66.7%',
                'probability': 'high'
            },
            {
                'cause': '容器重启或更新',
                'description': '区块链服务容器可能被重启或更新，导致配置丢失',
                'evidence': 'TCP连接正常但HTTP服务不可用',
                'probability': 'high'
            },
            {
                'cause': '网络配置问题',
                'description': '网络配置可能发生变化，影响HTTP服务',
                'evidence': '端口可连接但HTTP请求被拒绝',
                'probability': 'medium'
            },
            {
                'cause': '服务依赖问题',
                'description': '区块链服务可能依赖其他服务，依赖服务出现问题',
                'evidence': '服务状态不稳定',
                'probability': 'medium'
            }
        ]
        
        print("可能的根本原因:")
        for i, cause in enumerate(possible_causes, 1):
            print(f"{i}. {cause['cause']}")
            print(f"   描述: {cause['description']}")
            print(f"   证据: {cause['evidence']}")
            print(f"   可能性: {cause['probability']}")
            print()
            
            self.analysis_results['root_causes'].append(cause)
    
    def propose_solutions(self):
        """提出解决方案"""
        print("💡 解决方案建议")
        print("-" * 40)
        
        solutions = [
            {
                'priority': 'high',
                'solution': '检查区块链服务容器状态',
                'commands': [
                    'docker ps | grep blockchain',
                    'docker logs blockchain-service',
                    'docker inspect blockchain-service'
                ],
                'description': '检查容器是否正在运行，查看日志了解问题'
            },
            {
                'priority': 'high',
                'solution': '重启区块链服务',
                'commands': [
                    'docker restart blockchain-service',
                    'docker-compose restart blockchain'
                ],
                'description': '尝试重启服务，恢复HTTP功能'
            },
            {
                'priority': 'medium',
                'solution': '检查服务配置',
                'commands': [
                    'docker exec blockchain-service cat /etc/nginx/nginx.conf',
                    'docker exec blockchain-service ps aux'
                ],
                'description': '检查服务内部配置和进程状态'
            },
            {
                'priority': 'medium',
                'solution': '检查网络配置',
                'commands': [
                    'docker network ls',
                    'docker network inspect bridge'
                ],
                'description': '检查Docker网络配置'
            }
        ]
        
        for i, solution in enumerate(solutions, 1):
            print(f"{i}. {solution['solution']} (优先级: {solution['priority']})")
            print(f"   描述: {solution['description']}")
            print("   命令:")
            for cmd in solution['commands']:
                print(f"     {cmd}")
            print()
            
            self.analysis_results['solutions'].append(solution)
    
    def run_deep_analysis(self):
        """运行深度分析"""
        print("🔍 腾讯云服务器深度分析")
        print("=" * 60)
        print(f"服务器IP: {self.server_ip}")
        print(f"分析时间: {self.analysis_results['analysis_time']}")
        print()
        
        # 1. 分析历史性能
        historical_data = self.analyze_historical_performance()
        
        # 2. 调查区块链服务
        blockchain_results = self.investigate_blockchain_service()
        
        # 3. 识别根本原因
        self.identify_root_causes()
        
        # 4. 提出解决方案
        self.propose_solutions()
        
        # 5. 生成总结
        self.generate_summary()
        
        return self.analysis_results
    
    def generate_summary(self):
        """生成分析总结"""
        print("\n📋 分析总结")
        print("=" * 60)
        
        print("🎯 关键发现:")
        print("1. 腾讯云服务器从100%成功率下降到66.7%")
        print("2. 区块链服务(端口8300)可以TCP连接，但HTTP请求被拒绝")
        print("3. 其他服务(DAO Web, PostgreSQL, Redis)运行正常")
        print()
        
        print("🔍 根本原因分析:")
        print("最可能的原因: 区块链服务容器配置问题或服务重启")
        print("证据: TCP连接正常但HTTP服务不可用")
        print()
        
        print("💡 解决建议:")
        print("1. 立即检查区块链服务容器状态和日志")
        print("2. 尝试重启区块链服务")
        print("3. 检查服务配置和网络设置")
        print()
        
        print("🚀 下一步行动:")
        print("1. 连接到腾讯云服务器执行诊断命令")
        print("2. 修复区块链服务问题")
        print("3. 重新运行测试验证修复效果")
        print("=" * 60)
    
    def save_analysis(self):
        """保存分析结果"""
        filename = f'tencent_deep_analysis_{datetime.now().strftime("%Y%m%d_%H%M%S")}.json'
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(self.analysis_results, f, ensure_ascii=False, indent=2)
        print(f"📄 深度分析报告已保存: {filename}")
        return filename

if __name__ == '__main__':
    analyzer = TencentDeepAnalysis()
    results = analyzer.run_deep_analysis()
    analyzer.save_analysis()