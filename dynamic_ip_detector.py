#!/usr/bin/env python3
"""
动态IP地址检测器
解决Docker容器重启和版本切换导致的IP地址变化问题
"""

import docker
import json
import sys
from typing import Dict, List, Optional

class DynamicIPDetector:
    """动态IP地址检测器"""
    
    def __init__(self):
        self.client = docker.from_env()
        self.version_configs = {
            'future': {
                'network': 'future_f-network',
                'containers': ['f-mysql', 'f-postgres', 'f-redis', 'f-neo4j', 'f-mongodb', 'f-elasticsearch', 'f-weaviate', 'f-ai-service-db', 'f-dao-system-db', 'f-enterprise-credit-db']
            },
            'dao': {
                'network': 'dao_d-network', 
                'containers': ['d-mysql', 'd-postgres', 'd-redis', 'd-neo4j', 'd-mongodb', 'd-elasticsearch', 'd-weaviate', 'd-ai-service-db', 'd-dao-system-db', 'd-enterprise-credit-db']
            },
            'blockchain': {
                'network': 'blockchain_b-network',
                'containers': ['b-mysql', 'b-postgres', 'b-redis', 'b-neo4j', 'b-mongodb', 'b-elasticsearch', 'b-weaviate', 'b-ai-service-db', 'b-dao-system-db', 'b-enterprise-credit-db']
            }
        }
    
    def get_container_ip(self, container_name: str, network_name: str) -> Optional[str]:
        """获取容器IP地址"""
        try:
            container = self.client.containers.get(container_name)
            if container.status != 'running':
                return None
            
            # 获取容器网络信息
            networks = container.attrs['NetworkSettings']['Networks']
            if network_name in networks:
                return networks[network_name]['IPAddress']
            return None
        except Exception as e:
            print(f"获取容器 {container_name} IP地址失败: {e}")
            return None
    
    def detect_version_ips(self, version: str) -> Dict[str, str]:
        """检测指定版本的容器IP地址"""
        if version not in self.version_configs:
            raise ValueError(f"不支持的版本: {version}")
        
        config = self.version_configs[version]
        network_name = config['network']
        containers = config['containers']
        
        ip_mapping = {}
        
        print(f"🔍 检测 {version.upper()}版容器IP地址...")
        print(f"📡 网络: {network_name}")
        print("=" * 50)
        
        for container_name in containers:
            ip = self.get_container_ip(container_name, network_name)
            if ip:
                ip_mapping[container_name] = ip
                print(f"✅ {container_name}: {ip}")
            else:
                print(f"❌ {container_name}: 未运行或网络未连接")
        
        return ip_mapping
    
    def generate_test_config(self, version: str, ip_mapping: Dict[str, str]) -> Dict[str, str]:
        """生成测试配置"""
        # 主要数据库的IP映射
        test_config = {}
        
        # MySQL
        mysql_container = f"{version[0]}-mysql"
        if mysql_container in ip_mapping:
            test_config['mysql_ip'] = ip_mapping[mysql_container]
        
        # PostgreSQL  
        postgres_container = f"{version[0]}-postgres"
        if postgres_container in ip_mapping:
            test_config['postgres_ip'] = ip_mapping[postgres_container]
        
        # Redis
        redis_container = f"{version[0]}-redis"
        if redis_container in ip_mapping:
            test_config['redis_ip'] = ip_mapping[redis_container]
        
        # Neo4j
        neo4j_container = f"{version[0]}-neo4j"
        if neo4j_container in ip_mapping:
            test_config['neo4j_ip'] = ip_mapping[neo4j_container]
        
        return test_config
    
    def save_ip_mapping(self, version: str, ip_mapping: Dict[str, str], output_file: str = None):
        """保存IP地址映射到文件"""
        if output_file is None:
            output_file = f"{version}_ip_mapping.json"
        
        data = {
            'version': version,
            'detection_time': self._get_current_time(),
            'network': self.version_configs[version]['network'],
            'ip_mapping': ip_mapping,
            'test_config': self.generate_test_config(version, ip_mapping)
        }
        
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        
        print(f"📄 IP地址映射已保存到: {output_file}")
        return output_file
    
    def _get_current_time(self) -> str:
        """获取当前时间"""
        from datetime import datetime
        return datetime.now().isoformat()
    
    def update_test_scripts(self, version: str, ip_mapping: Dict[str, str]):
        """更新测试脚本中的IP地址"""
        test_config = self.generate_test_config(version, ip_mapping)
        
        # 更新数据一致性测试脚本
        script_file = f"enhanced_{version}_database_test.py"
        if version == 'blockchain':
            script_file = "enhanced_blockchain_database_test.py"
        
        print(f"🔧 更新测试脚本: {script_file}")
        print(f"📊 测试配置: {test_config}")
        
        # 这里可以添加自动更新测试脚本的逻辑
        # 或者生成新的测试脚本文件
    
    def run_detection(self, version: str):
        """运行IP地址检测"""
        print(f"🚀 开始检测 {version.upper()}版容器IP地址...")
        print("=" * 60)
        
        try:
            # 检测IP地址
            ip_mapping = self.detect_version_ips(version)
            
            if not ip_mapping:
                print(f"❌ 未检测到 {version.upper()}版运行中的容器")
                return False
            
            # 生成测试配置
            test_config = self.generate_test_config(version, ip_mapping)
            
            # 保存结果
            output_file = self.save_ip_mapping(version, ip_mapping)
            
            # 显示结果
            print("\n📊 检测结果:")
            print("=" * 30)
            for key, value in test_config.items():
                print(f"{key}: {value}")
            
            return True
            
        except Exception as e:
            print(f"❌ 检测失败: {e}")
            return False

def main():
    """主函数"""
    if len(sys.argv) != 2:
        print("用法: python3 dynamic_ip_detector.py <future|dao|blockchain>")
        sys.exit(1)
    
    version = sys.argv[1].lower()
    detector = DynamicIPDetector()
    
    success = detector.run_detection(version)
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
