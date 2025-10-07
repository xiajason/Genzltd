#!/usr/bin/env python3
# 基于@future_optimized/经验的阿里云数据库监控系统
# 版本: V1.0
# 日期: 2025年10月6日
# 描述: 实时监控阿里云多数据库状态，基于Future版经验

import subprocess
import json
import time
from datetime import datetime
import os

class AlibabaCloudDatabaseMonitor:
    def __init__(self):
        self.server_ip = "47.115.168.107"
        self.ssh_key = "~/.ssh/cross_cloud_key"
        self.monitor_results = []
        
    def execute_remote_command(self, command):
        """执行远程命令"""
        try:
            result = subprocess.run([
                'ssh', '-i', self.ssh_key, '-o', 'ConnectTimeout=30', 
                '-o', 'StrictHostKeyChecking=no', 
                f'root@{self.server_ip}', command
            ], capture_output=True, text=True, timeout=30)
            return result
        except Exception as e:
            return None
    
    def check_container_status(self):
        """检查容器状态"""
        result = self.execute_remote_command("docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'")
        if result and result.returncode == 0:
            return result.stdout.strip()
        return "Container status check failed"
    
    def check_database_connections(self):
        """检查数据库连接"""
        connections = {}
        
        # MySQL连接检查
        mysql_result = self.execute_remote_command(
            "docker exec production-mysql mysql -u root -p'f_mysql_password_2025' -e 'SELECT 1;' 2>/dev/null"
        )
        connections['mysql'] = {
            'status': 'connected' if mysql_result and mysql_result.returncode == 0 else 'disconnected',
            'response_time': 'N/A'
        }
        
        # PostgreSQL连接检查
        postgresql_result = self.execute_remote_command(
            "docker exec production-postgres psql -U future_user -d jobfirst_future -c 'SELECT 1;' 2>/dev/null"
        )
        connections['postgresql'] = {
            'status': 'connected' if postgresql_result and postgresql_result.returncode == 0 else 'disconnected',
            'response_time': 'N/A'
        }
        
        # Redis连接检查
        redis_result = self.execute_remote_command(
            "redis-cli -h localhost -p 6379 -a 'f_redis_password_2025' ping 2>/dev/null"
        )
        connections['redis'] = {
            'status': 'connected' if redis_result and redis_result.returncode == 0 else 'disconnected',
            'response_time': 'N/A'
        }
        
        # Neo4j连接检查
        neo4j_result = self.execute_remote_command(
            "docker exec production-neo4j cypher-shell -u neo4j -p'f_neo4j_password_2025' 'RETURN 1;' 2>/dev/null"
        )
        connections['neo4j'] = {
            'status': 'connected' if neo4j_result and neo4j_result.returncode == 0 else 'disconnected',
            'response_time': 'N/A'
        }
        
        # Elasticsearch连接检查
        elasticsearch_result = self.execute_remote_command("curl -s http://localhost:9200 2>/dev/null")
        connections['elasticsearch'] = {
            'status': 'connected' if elasticsearch_result and elasticsearch_result.returncode == 0 else 'disconnected',
            'response_time': 'N/A'
        }
        
        # Weaviate连接检查
        weaviate_result = self.execute_remote_command("curl -s http://localhost:8080 2>/dev/null")
        connections['weaviate'] = {
            'status': 'connected' if weaviate_result and weaviate_result.returncode == 0 else 'disconnected',
            'response_time': 'N/A'
        }
        
        return connections
    
    def check_system_resources(self):
        """检查系统资源"""
        # 检查内存使用
        memory_result = self.execute_remote_command("free -h")
        memory_info = memory_result.stdout.strip() if memory_result else "Memory check failed"
        
        # 检查磁盘使用
        disk_result = self.execute_remote_command("df -h")
        disk_info = disk_result.stdout.strip() if disk_result else "Disk check failed"
        
        # 检查CPU使用
        cpu_result = self.execute_remote_command("top -bn1 | grep 'Cpu(s)'")
        cpu_info = cpu_result.stdout.strip() if cpu_result else "CPU check failed"
        
        return {
            'memory': memory_info,
            'disk': disk_info,
            'cpu': cpu_info
        }
    
    def run_monitoring_cycle(self):
        """运行监控周期"""
        print(f"=== 开始监控周期 - {datetime.now().strftime('%Y-%m-%d %H:%M:%S')} ===")
        
        monitor_result = {
            'timestamp': datetime.now().isoformat(),
            'server': f'阿里云ECS ({self.server_ip})',
            'container_status': self.check_container_status(),
            'database_connections': self.check_database_connections(),
            'system_resources': self.check_system_resources()
        }
        
        # 计算连接状态
        connected_dbs = sum(1 for db in monitor_result['database_connections'].values() 
                           if db['status'] == 'connected')
        total_dbs = len(monitor_result['database_connections'])
        
        monitor_result['summary'] = {
            'connected_databases': connected_dbs,
            'total_databases': total_dbs,
            'connection_rate': f'{(connected_dbs/total_dbs)*100:.1f}%',
            'status': 'healthy' if connected_dbs >= total_dbs * 0.8 else 'warning' if connected_dbs >= total_dbs * 0.5 else 'critical'
        }
        
        self.monitor_results.append(monitor_result)
        
        print(f"=== 监控完成: {connected_dbs}/{total_dbs} 数据库连接正常 ===")
        print(f"=== 系统状态: {monitor_result['summary']['status']} ===")
        
        return monitor_result
    
    def run_continuous_monitoring(self, duration_minutes=10, interval_seconds=30):
        """运行持续监控"""
        print(f"=== 开始持续监控 {duration_minutes} 分钟，间隔 {interval_seconds} 秒 ===")
        
        start_time = time.time()
        end_time = start_time + (duration_minutes * 60)
        
        while time.time() < end_time:
            self.run_monitoring_cycle()
            
            if time.time() < end_time:
                print(f"=== 等待 {interval_seconds} 秒后进行下次监控 ===")
                time.sleep(interval_seconds)
        
        print("=== 持续监控完成 ===")
        return self.monitor_results
    
    def generate_monitoring_report(self):
        """生成监控报告"""
        if not self.monitor_results:
            return "没有监控数据"
        
        report = {
            'monitoring_summary': {
                'total_cycles': len(self.monitor_results),
                'monitoring_duration': f"{len(self.monitor_results) * 30 / 60:.1f} 分钟",
                'start_time': self.monitor_results[0]['timestamp'],
                'end_time': self.monitor_results[-1]['timestamp']
            },
            'database_stability': {},
            'system_health': {},
            'recommendations': []
        }
        
        # 分析数据库稳定性
        databases = ['mysql', 'postgresql', 'redis', 'neo4j', 'elasticsearch', 'weaviate']
        
        for db in databases:
            connected_count = sum(1 for cycle in self.monitor_results 
                                if cycle['database_connections'][db]['status'] == 'connected')
            total_cycles = len(self.monitor_results)
            stability_rate = (connected_count / total_cycles) * 100
            
            report['database_stability'][db] = {
                'connected_cycles': connected_count,
                'total_cycles': total_cycles,
                'stability_rate': f'{stability_rate:.1f}%',
                'status': 'stable' if stability_rate >= 90 else 'unstable' if stability_rate >= 70 else 'critical'
            }
        
        # 分析系统健康状态
        healthy_cycles = sum(1 for cycle in self.monitor_results 
                           if cycle['summary']['status'] == 'healthy')
        total_cycles = len(self.monitor_results)
        health_rate = (healthy_cycles / total_cycles) * 100
        
        report['system_health'] = {
            'healthy_cycles': healthy_cycles,
            'total_cycles': total_cycles,
            'health_rate': f'{health_rate:.1f}%',
            'overall_status': 'excellent' if health_rate >= 90 else 'good' if health_rate >= 70 else 'needs_attention'
        }
        
        # 生成建议
        unstable_dbs = [db for db, stats in report['database_stability'].items() 
                        if stats['status'] in ['unstable', 'critical']]
        
        if unstable_dbs:
            report['recommendations'].append(f"需要关注不稳定的数据库: {', '.join(unstable_dbs)}")
        
        if health_rate < 70:
            report['recommendations'].append("系统健康状态需要改进，建议检查配置和资源")
        elif health_rate >= 90:
            report['recommendations'].append("系统运行非常稳定，可以进入下一阶段")
        else:
            report['recommendations'].append("系统基本稳定，建议进行优化")
        
        return report
    
    def save_monitoring_results(self):
        """保存监控结果"""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        
        # 保存详细监控数据
        detailed_filename = f"@alibaba_cloud_database_management/alibaba_cloud_monitoring_{timestamp}.json"
        with open(detailed_filename, 'w', encoding='utf-8') as f:
            json.dump(self.monitor_results, f, ensure_ascii=False, indent=2)
        
        # 生成并保存监控报告
        report = self.generate_monitoring_report()
        report_filename = f"@alibaba_cloud_database_management/alibaba_cloud_monitoring_report_{timestamp}.json"
        with open(report_filename, 'w', encoding='utf-8') as f:
            json.dump(report, f, ensure_ascii=False, indent=2)
        
        print(f"=== 监控数据已保存到 {detailed_filename} ===")
        print(f"=== 监控报告已保存到 {report_filename} ===")
        
        return detailed_filename, report_filename

if __name__ == '__main__':
    monitor = AlibabaCloudDatabaseMonitor()
    
    # 运行持续监控 (10分钟，每30秒一次)
    results = monitor.run_continuous_monitoring(duration_minutes=10, interval_seconds=30)
    
    # 生成监控报告
    report = monitor.generate_monitoring_report()
    
    # 保存结果
    detailed_file, report_file = monitor.save_monitoring_results()
    
    print("=== 监控完成 ===")
    print(f"监控周期数: {report['monitoring_summary']['total_cycles']}")
    print(f"系统健康率: {report['system_health']['health_rate']}")
    print(f"整体状态: {report['system_health']['overall_status']}")
    
    if report['recommendations']:
        print("建议:")
        for rec in report['recommendations']:
            print(f"  - {rec}")
