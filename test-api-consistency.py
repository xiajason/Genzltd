#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
API数据一致性测试脚本
基于三环境架构的API数据一致性验证
"""

import requests
import json
import time
import sys
from datetime import datetime
from typing import Dict, List, Any, Optional, Tuple
import concurrent.futures
from dataclasses import dataclass

@dataclass
class APIEndpoint:
    path: str
    method: str = 'GET'
    expected_status: int = 200
    timeout: int = 10
    description: str = ""

class APIConsistencyTester:
    def __init__(self):
        self.environments = {
            'local': {
                'base_url': 'http://localhost:3000',
                'name': '本地开发环境',
                'timeout': 5
            },
            'tencent': {
                'base_url': 'http://101.33.251.158:9200',
                'name': '腾讯云测试环境',
                'timeout': 10
            },
            'alibaba': {
                'base_url': 'http://47.115.168.107:9200',
                'name': '阿里云生产环境',
                'timeout': 10
            }
        }
        
        self.test_endpoints = [
            APIEndpoint('/api/health', 'GET', 200, 5, '健康检查'),
            APIEndpoint('/api/trpc/daoConfig.getDAOTypes', 'GET', 200, 5, 'DAO类型获取'),
            APIEndpoint('/api/users', 'GET', 200, 5, '用户列表'),
            APIEndpoint('/api/dao/configs', 'GET', 200, 5, 'DAO配置列表'),
            APIEndpoint('/api/dao/settings', 'GET', 200, 5, 'DAO设置列表'),
        ]
        
        self.results = {
            'timestamp': datetime.now().isoformat(),
            'environments': {},
            'comparisons': {},
            'summary': {}
        }

    def make_request(self, env_name: str, endpoint: APIEndpoint) -> Dict[str, Any]:
        """发送API请求"""
        env = self.environments[env_name]
        url = f"{env['base_url']}{endpoint.path}"
        
        try:
            response = requests.request(
                method=endpoint.method,
                url=url,
                timeout=endpoint.timeout
            )
            
            return {
                'success': True,
                'status_code': response.status_code,
                'response_time': response.elapsed.total_seconds(),
                'content_type': response.headers.get('content-type', ''),
                'content_length': len(response.content),
                'data': response.json() if response.headers.get('content-type', '').startswith('application/json') else response.text[:1000],
                'headers': dict(response.headers),
                'url': url,
                'timestamp': datetime.now().isoformat()
            }
        except requests.exceptions.Timeout:
            return {
                'success': False,
                'error': 'Timeout',
                'url': url,
                'timestamp': datetime.now().isoformat()
            }
        except requests.exceptions.ConnectionError:
            return {
                'success': False,
                'error': 'Connection Error',
                'url': url,
                'timestamp': datetime.now().isoformat()
            }
        except Exception as e:
            return {
                'success': False,
                'error': str(e),
                'url': url,
                'timestamp': datetime.now().isoformat()
            }

    def test_environment_apis(self, env_name: str) -> Dict[str, Any]:
        """测试单个环境的所有API"""
        print(f"🔍 测试 {self.environments[env_name]['name']} API...")
        
        env_results = {
            'environment': env_name,
            'base_url': self.environments[env_name]['base_url'],
            'endpoints': {},
            'summary': {
                'total_endpoints': len(self.test_endpoints),
                'successful_requests': 0,
                'failed_requests': 0,
                'average_response_time': 0,
                'total_response_time': 0
            }
        }
        
        for endpoint in self.test_endpoints:
            print(f"  📡 测试端点: {endpoint.path}")
            
            result = self.make_request(env_name, endpoint)
            env_results['endpoints'][endpoint.path] = result
            
            if result['success']:
                env_results['summary']['successful_requests'] += 1
                env_results['summary']['total_response_time'] += result.get('response_time', 0)
            else:
                env_results['summary']['failed_requests'] += 1
        
        # 计算平均响应时间
        if env_results['summary']['successful_requests'] > 0:
            env_results['summary']['average_response_time'] = (
                env_results['summary']['total_response_time'] / 
                env_results['summary']['successful_requests']
            )
        
        return env_results

    def compare_api_responses(self, env1_results: Dict, env2_results: Dict) -> Dict[str, Any]:
        """比较两个环境的API响应"""
        comparison = {
            'endpoint_comparisons': {},
            'summary': {
                'total_endpoints': len(self.test_endpoints),
                'consistent_endpoints': 0,
                'inconsistent_endpoints': 0,
                'response_time_diff': 0
            }
        }
        
        for endpoint in self.test_endpoints:
            path = endpoint.path
            env1_result = env1_results['endpoints'].get(path, {})
            env2_result = env2_results['endpoints'].get(path, {})
            
            endpoint_comparison = {
                'path': path,
                'description': endpoint.description,
                'env1_success': env1_result.get('success', False),
                'env2_success': env2_result.get('success', False),
                'status_code_match': False,
                'response_time_diff': 0,
                'data_consistency': 'unknown',
                'issues': []
            }
            
            # 检查请求成功性
            if env1_result.get('success') and env2_result.get('success'):
                # 比较状态码
                if env1_result.get('status_code') == env2_result.get('status_code'):
                    endpoint_comparison['status_code_match'] = True
                else:
                    endpoint_comparison['issues'].append(
                        f"状态码不一致: {env1_result.get('status_code')} vs {env2_result.get('status_code')}"
                    )
                
                # 比较响应时间
                env1_time = env1_result.get('response_time', 0)
                env2_time = env2_result.get('response_time', 0)
                endpoint_comparison['response_time_diff'] = abs(env1_time - env2_time)
                
                # 比较响应数据
                env1_data = env1_result.get('data')
                env2_data = env2_result.get('data')
                
                if isinstance(env1_data, dict) and isinstance(env2_data, dict):
                    if env1_data == env2_data:
                        endpoint_comparison['data_consistency'] = 'consistent'
                        comparison['summary']['consistent_endpoints'] += 1
                    else:
                        endpoint_comparison['data_consistency'] = 'inconsistent'
                        endpoint_comparison['issues'].append("响应数据不一致")
                        comparison['summary']['inconsistent_endpoints'] += 1
                elif env1_data == env2_data:
                    endpoint_comparison['data_consistency'] = 'consistent'
                    comparison['summary']['consistent_endpoints'] += 1
                else:
                    endpoint_comparison['data_consistency'] = 'inconsistent'
                    endpoint_comparison['issues'].append("响应数据不一致")
                    comparison['summary']['inconsistent_endpoints'] += 1
            else:
                if not env1_result.get('success'):
                    endpoint_comparison['issues'].append(f"环境1请求失败: {env1_result.get('error', 'Unknown error')}")
                if not env2_result.get('success'):
                    endpoint_comparison['issues'].append(f"环境2请求失败: {env2_result.get('error', 'Unknown error')}")
            
            comparison['endpoint_comparisons'][path] = endpoint_comparison
        
        return comparison

    def run_comprehensive_test(self):
        """运行全面的API一致性测试"""
        print("🚀 开始三环境API数据一致性测试...")
        
        # 测试每个环境
        for env_name in self.environments.keys():
            self.results['environments'][env_name] = self.test_environment_apis(env_name)
        
        # 进行环境间比较
        print("\n🔄 进行环境间API响应比较...")
        
        envs = list(self.environments.keys())
        for i in range(len(envs)):
            for j in range(i + 1, len(envs)):
                env1, env2 = envs[i], envs[j]
                
                print(f"📊 比较 {env1} 和 {env2} 环境API响应...")
                
                comparison = self.compare_api_responses(
                    self.results['environments'][env1],
                    self.results['environments'][env2]
                )
                
                self.results['comparisons'][f"{env1}_vs_{env2}"] = comparison
        
        # 生成总结
        self.generate_summary()
        
        # 保存结果
        self.save_results()

    def generate_summary(self):
        """生成测试总结"""
        print("\n📊 生成测试总结...")
        
        summary = {
            'total_environments': len(self.environments),
            'total_endpoints': len(self.test_endpoints),
            'total_comparisons': len(self.results['comparisons']),
            'consistency_score': 0,
            'average_response_time': 0,
            'issues': [],
            'recommendations': []
        }
        
        # 计算一致性得分
        total_comparisons = 0
        consistent_comparisons = 0
        total_response_time = 0
        successful_requests = 0
        
        for comparison in self.results['comparisons'].values():
            summary_data = comparison['summary']
            total_comparisons += summary_data['total_endpoints']
            consistent_comparisons += summary_data['consistent_endpoints']
        
        # 计算环境响应时间
        for env_results in self.results['environments'].values():
            total_response_time += env_results['summary']['total_response_time']
            successful_requests += env_results['summary']['successful_requests']
        
        if total_comparisons > 0:
            summary['consistency_score'] = (consistent_comparisons / total_comparisons) * 100
        
        if successful_requests > 0:
            summary['average_response_time'] = total_response_time / successful_requests
        
        # 收集问题
        for comparison_name, comparison in self.results['comparisons'].items():
            for endpoint_path, endpoint_comparison in comparison['endpoint_comparisons'].items():
                if endpoint_comparison['issues']:
                    summary['issues'].extend([
                        f"{comparison_name} - {endpoint_path}: {issue}"
                        for issue in endpoint_comparison['issues']
                    ])
        
        # 生成建议
        if summary['consistency_score'] >= 90:
            summary['recommendations'].append("✅ API数据一致性良好，可以继续后续测试")
        elif summary['consistency_score'] >= 70:
            summary['recommendations'].append("⚠️ 存在少量API不一致，建议修复后继续")
        else:
            summary['recommendations'].append("❌ 存在严重API不一致，需要全面检查和修复")
        
        if summary['average_response_time'] > 2:
            summary['recommendations'].append("⚠️ API响应时间较慢，建议优化性能")
        
        self.results['summary'] = summary

    def save_results(self):
        """保存测试结果"""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"api-consistency-test-{timestamp}.json"
        
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(self.results, f, indent=2, ensure_ascii=False)
        
        print(f"📁 测试结果已保存到: {filename}")
        
        # 生成Markdown报告
        self.generate_markdown_report(filename)

    def generate_markdown_report(self, json_filename: str):
        """生成Markdown格式的报告"""
        md_filename = json_filename.replace('.json', '.md')
        
        with open(md_filename, 'w', encoding='utf-8') as f:
            f.write(f"# API数据一致性测试报告\n\n")
            f.write(f"**测试时间**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
            f.write(f"**测试版本**: v1.0\n")
            f.write(f"**数据源**: {json_filename}\n\n")
            
            # 添加总结
            summary = self.results['summary']
            f.write(f"## 📊 测试总结\n\n")
            f.write(f"- **测试环境数**: {summary['total_environments']}\n")
            f.write(f"- **测试端点数**: {summary['total_endpoints']}\n")
            f.write(f"- **比较次数**: {summary['total_comparisons']}\n")
            f.write(f"- **一致性得分**: {summary['consistency_score']:.1f}%\n")
            f.write(f"- **平均响应时间**: {summary['average_response_time']:.3f}秒\n\n")
            
            # 添加问题列表
            if summary['issues']:
                f.write(f"## ⚠️ 发现的问题\n\n")
                for issue in summary['issues']:
                    f.write(f"- {issue}\n")
                f.write("\n")
            
            # 添加建议
            f.write(f"## 💡 建议\n\n")
            for recommendation in summary['recommendations']:
                f.write(f"- {recommendation}\n")
            f.write("\n")
            
            # 添加环境详情
            f.write(f"## 🌐 环境详情\n\n")
            for env_name, env_results in self.results['environments'].items():
                env_summary = env_results['summary']
                f.write(f"### {self.environments[env_name]['name']}\n\n")
                f.write(f"- **基础URL**: {env_results['base_url']}\n")
                f.write(f"- **成功请求**: {env_summary['successful_requests']}/{env_summary['total_endpoints']}\n")
                f.write(f"- **平均响应时间**: {env_summary['average_response_time']:.3f}秒\n\n")
            
            # 添加详细比较结果
            f.write(f"## 🔍 详细比较结果\n\n")
            for comparison_name, comparison in self.results['comparisons'].items():
                f.write(f"### {comparison_name}\n\n")
                
                summary_data = comparison['summary']
                f.write(f"- **一致性端点**: {summary_data['consistent_endpoints']}/{summary_data['total_endpoints']}\n")
                f.write(f"- **不一致端点**: {summary_data['inconsistent_endpoints']}/{summary_data['total_endpoints']}\n\n")
                
                for endpoint_path, endpoint_comparison in comparison['endpoint_comparisons'].items():
                    status = "✅" if endpoint_comparison['data_consistency'] == 'consistent' else "❌"
                    f.write(f"#### {endpoint_path} {status}\n\n")
                    f.write(f"- **描述**: {endpoint_comparison['description']}\n")
                    f.write(f"- **数据一致性**: {endpoint_comparison['data_consistency']}\n")
                    f.write(f"- **响应时间差异**: {endpoint_comparison['response_time_diff']:.3f}秒\n")
                    
                    if endpoint_comparison['issues']:
                        f.write(f"- **问题**:\n")
                        for issue in endpoint_comparison['issues']:
                            f.write(f"  - {issue}\n")
                    f.write("\n")
            
            f.write(f"---\n\n")
            f.write(f"**报告生成时间**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        
        print(f"📄 Markdown报告已保存到: {md_filename}")

def main():
    tester = APIConsistencyTester()
    tester.run_comprehensive_test()
    
    # 显示总结
    summary = tester.results['summary']
    print(f"\n🎯 API一致性测试完成!")
    print(f"📊 一致性得分: {summary['consistency_score']:.1f}%")
    print(f"⏱️ 平均响应时间: {summary['average_response_time']:.3f}秒")
    print(f"📋 发现问题: {len(summary['issues'])} 个")
    
    for recommendation in summary['recommendations']:
        print(f"💡 {recommendation}")

if __name__ == "__main__":
    main()
