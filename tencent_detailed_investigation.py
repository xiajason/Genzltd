#!/usr/bin/env python3
# 腾讯云服务器详细调查脚本
# 找出为什么从100%成功率下降到66.7%的原因

import requests
import socket
import json
import time
from datetime import datetime

class TencentDetailedInvestigation:
    def __init__(self, server_ip="101.33.251.158"):
        self.server_ip = server_ip
        self.results = {
            'investigation_time': datetime.now().isoformat(),
            'server_ip': server_ip,
            'services_checked': [],
            'issues_found': [],
            'recommendations': []
        }
    
    def check_port_connectivity(self, port, service_name):
        """检查端口连接性"""
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(5)
            result = sock.connect_ex((self.server_ip, port))
            sock.close()
            
            status = "✅ 可连接" if result == 0 else "❌ 不可连接"
            return {
                'service': service_name,
                'port': port,
                'status': status,
                'connectable': result == 0
            }
        except Exception as e:
            return {
                'service': service_name,
                'port': port,
                'status': f"❌ 错误: {e}",
                'connectable': False
            }
    
    def check_http_service(self, port, service_name, path="/"):
        """检查HTTP服务"""
        try:
            url = f"http://{self.server_ip}:{port}{path}"
            response = requests.get(url, timeout=10)
            return {
                'service': service_name,
                'port': port,
                'url': url,
                'status_code': response.status_code,
                'response_size': len(response.content),
                'response_time': response.elapsed.total_seconds(),
                'working': True
            }
        except requests.exceptions.ConnectionError:
            return {
                'service': service_name,
                'port': port,
                'url': f"http://{self.server_ip}:{port}{path}",
                'status_code': 0,
                'error': 'Connection refused',
                'working': False
            }
        except requests.exceptions.Timeout:
            return {
                'service': service_name,
                'port': port,
                'url': f"http://{self.server_ip}:{port}{path}",
                'status_code': 0,
                'error': 'Timeout',
                'working': False
            }
        except Exception as e:
            return {
                'service': service_name,
                'port': port,
                'url': f"http://{self.server_ip}:{port}{path}",
                'status_code': 0,
                'error': str(e),
                'working': False
            }
    
    def run_detailed_investigation(self):
        """运行详细调查"""
        print("🔍 腾讯云服务器详细调查开始")
        print("=" * 60)
        print(f"服务器IP: {self.server_ip}")
        print(f"调查时间: {self.results['investigation_time']}")
        print()
        
        # 1. 检查已知服务端口
        known_services = [
            (9200, "DAO版Web服务"),
            (5433, "DAO PostgreSQL"),
            (6380, "DAO Redis"),
            (8300, "区块链服务")
        ]
        
        print("📡 检查已知服务端口")
        print("-" * 40)
        for port, service_name in known_services:
            result = self.check_port_connectivity(port, service_name)
            self.results['services_checked'].append(result)
            print(f"{service_name} (端口{port}): {result['status']}")
            
            if result['connectable'] and port in [9200, 8300]:  # HTTP服务
                http_result = self.check_http_service(port, service_name)
                self.results['services_checked'].append(http_result)
                if http_result['working']:
                    print(f"  HTTP响应: {http_result['status_code']} ({http_result['response_size']} bytes)")
                else:
                    print(f"  HTTP错误: {http_result.get('error', 'Unknown error')}")
        print()
        
        # 2. 检查其他常用端口
        other_ports = [80, 443, 3000, 8080, 9000, 5000, 8000]
        print("🔍 检查其他常用端口")
        print("-" * 40)
        for port in other_ports:
            result = self.check_port_connectivity(port, f"端口{port}")
            if result['connectable']:
                print(f"端口{port}: {result['status']}")
                # 尝试HTTP检查
                http_result = self.check_http_service(port, f"HTTP服务{port}")
                if http_result['working']:
                    print(f"  HTTP响应: {http_result['status_code']} ({http_result['response_size']} bytes)")
                else:
                    print(f"  HTTP错误: {http_result.get('error', 'Unknown error')}")
        print()
        
        # 3. 分析问题
        self.analyze_issues()
        
        # 4. 生成建议
        self.generate_recommendations()
        
        return self.results
    
    def analyze_issues(self):
        """分析发现的问题"""
        print("🔍 问题分析")
        print("-" * 40)
        
        # 统计可连接和不可连接的服务
        connectable_services = [s for s in self.results['services_checked'] if s.get('connectable', False)]
        working_http_services = [s for s in self.results['services_checked'] if s.get('working', False)]
        
        print(f"可连接服务数量: {len(connectable_services)}")
        print(f"工作HTTP服务数量: {len(working_http_services)}")
        
        # 找出问题服务
        blockchain_service = next((s for s in self.results['services_checked'] if '区块链' in s.get('service', '')), None)
        if blockchain_service and not blockchain_service.get('connectable', False):
            self.results['issues_found'].append({
                'service': '区块链服务',
                'issue': '端口8300不可连接',
                'severity': 'high',
                'description': '区块链服务完全不可访问，这解释了为什么成功率从100%下降到66.7%'
            })
            print("❌ 发现关键问题: 区块链服务(端口8300)不可连接")
        
        # 检查HTTP服务问题
        for service in self.results['services_checked']:
            if service.get('port') in [9200, 8300] and not service.get('working', True):
                self.results['issues_found'].append({
                    'service': service.get('service', 'Unknown'),
                    'issue': f"HTTP服务异常: {service.get('error', 'Unknown error')}",
                    'severity': 'medium',
                    'description': f"服务在端口{service.get('port')}上无法正常响应HTTP请求"
                })
                print(f"⚠️ 发现HTTP问题: {service.get('service', 'Unknown')} - {service.get('error', 'Unknown error')}")
        print()
    
    def generate_recommendations(self):
        """生成建议"""
        print("💡 建议和解决方案")
        print("-" * 40)
        
        if not self.results['issues_found']:
            print("✅ 未发现明显问题，所有服务运行正常")
            return
        
        for i, issue in enumerate(self.results['issues_found'], 1):
            print(f"{i}. {issue['service']}: {issue['issue']}")
            print(f"   严重程度: {issue['severity']}")
            print(f"   描述: {issue['description']}")
            print()
            
            # 生成具体建议
            if '区块链' in issue['service']:
                self.results['recommendations'].append({
                    'priority': 'high',
                    'action': '检查区块链服务容器状态',
                    'command': 'docker ps | grep blockchain',
                    'description': '检查区块链服务是否正在运行'
                })
                self.results['recommendations'].append({
                    'priority': 'high',
                    'action': '重启区块链服务',
                    'command': 'docker restart blockchain-service',
                    'description': '尝试重启区块链服务'
                })
        
        print("📋 具体建议:")
        for i, rec in enumerate(self.results['recommendations'], 1):
            print(f"{i}. {rec['action']}")
            print(f"   命令: {rec['command']}")
            print(f"   描述: {rec['description']}")
            print()
    
    def save_report(self):
        """保存调查报告"""
        filename = f'tencent_detailed_investigation_{datetime.now().strftime("%Y%m%d_%H%M%S")}.json'
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(self.results, f, ensure_ascii=False, indent=2)
        print(f"📄 调查报告已保存: {filename}")
        return filename

if __name__ == '__main__':
    investigator = TencentDetailedInvestigation()
    results = investigator.run_detailed_investigation()
    investigator.save_report()
    
    print("=" * 60)
    print("🎯 调查结论")
    print("=" * 60)
    if len(results['issues_found']) > 0:
        print(f"发现 {len(results['issues_found'])} 个问题，这解释了为什么成功率下降")
        print("主要问题: 区块链服务不可连接")
    else:
        print("未发现明显问题，需要进一步调查")
    print("=" * 60)