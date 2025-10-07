#!/usr/bin/env python3
"""
区块链版多数据库结构统一执行器
创建时间: 2025-10-05
版本: Blockchain Version
功能: 一键执行所有区块链版数据库结构创建
"""

import subprocess
import sys
import time
from datetime import datetime

class BlockchainDatabaseExecutor:
    def __init__(self):
        """初始化区块链版数据库执行器"""
        self.scripts = [
            {
                "name": "MySQL数据库结构",
                "script": "blockchain_mysql_database_structure.sql",
                "type": "sql",
                "description": "区块链版MySQL数据库结构创建"
            },
            {
                "name": "PostgreSQL数据库结构", 
                "script": "blockchain_postgresql_database_structure.sql",
                "type": "sql",
                "description": "区块链版PostgreSQL数据库结构创建"
            },
            {
                "name": "Redis数据库结构",
                "script": "blockchain_redis_database_structure.py",
                "type": "python",
                "description": "区块链版Redis缓存结构创建"
            },
            {
                "name": "Neo4j数据库结构",
                "script": "blockchain_neo4j_database_structure.py", 
                "type": "python",
                "description": "区块链版Neo4j图数据库结构创建"
            },
            {
                "name": "Elasticsearch数据库结构",
                "script": "blockchain_elasticsearch_database_structure.py",
                "type": "python", 
                "description": "区块链版Elasticsearch搜索结构创建"
            },
            {
                "name": "Weaviate数据库结构",
                "script": "blockchain_weaviate_database_structure.py",
                "type": "python",
                "description": "区块链版Weaviate向量数据库结构创建"
            }
        ]
        
        self.results = []
        
    def execute_mysql_structure(self):
        """执行MySQL数据库结构创建"""
        print("🗄️ 执行MySQL数据库结构创建...")
        
        try:
            # 使用mysql命令执行SQL脚本
            cmd = [
                "mysql",
                "-h", "localhost",
                "-P", "3309",  # 区块链版MySQL端口
                "-u", "root",
                "-p" + "b_mysql_password_2025",
                "<", "blockchain_mysql_database_structure.sql"
            ]
            
            # 由于需要重定向，使用shell执行
            result = subprocess.run(
                "mysql -h localhost -P 3309 -u root -p" + "b_mysql_password_2025" + " < blockchain_mysql_database_structure.sql",
                shell=True,
                capture_output=True,
                text=True
            )
            
            if result.returncode == 0:
                print("✅ MySQL数据库结构创建成功")
                return True
            else:
                print(f"❌ MySQL数据库结构创建失败: {result.stderr}")
                return False
                
        except Exception as e:
            print(f"❌ MySQL数据库结构创建异常: {e}")
            return False
    
    def execute_postgresql_structure(self):
        """执行PostgreSQL数据库结构创建"""
        print("🐘 执行PostgreSQL数据库结构创建...")
        
        try:
            # 使用psql命令执行SQL脚本
            cmd = [
                "psql",
                "-h", "localhost",
                "-p", "5433",  # 区块链版PostgreSQL端口
                "-U", "postgres",
                "-d", "b_pg",
                "-f", "blockchain_postgresql_database_structure.sql"
            ]
            
            # 设置密码环境变量
            env = {"PGPASSWORD": "b_postgres_password_2025"}
            
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                env=env
            )
            
            if result.returncode == 0:
                print("✅ PostgreSQL数据库结构创建成功")
                return True
            else:
                print(f"❌ PostgreSQL数据库结构创建失败: {result.stderr}")
                return False
                
        except Exception as e:
            print(f"❌ PostgreSQL数据库结构创建异常: {e}")
            return False
    
    def execute_python_script(self, script_name):
        """执行Python脚本"""
        print(f"🐍 执行{script_name}...")
        
        try:
            result = subprocess.run(
                [sys.executable, script_name],
                capture_output=True,
                text=True
            )
            
            if result.returncode == 0:
                print(f"✅ {script_name}执行成功")
                return True
            else:
                print(f"❌ {script_name}执行失败: {result.stderr}")
                return False
                
        except Exception as e:
            print(f"❌ {script_name}执行异常: {e}")
            return False
    
    def execute_all_structures(self):
        """执行所有数据库结构创建"""
        print("🚀 开始执行区块链版多数据库结构创建...")
        print(f"📅 执行时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print("=" * 60)
        
        success_count = 0
        total_count = len(self.scripts)
        
        for i, script_info in enumerate(self.scripts, 1):
            print(f"\n📋 [{i}/{total_count}] {script_info['name']}")
            print(f"📝 描述: {script_info['description']}")
            print(f"📄 脚本: {script_info['script']}")
            print("-" * 40)
            
            start_time = time.time()
            
            if script_info['type'] == 'sql':
                if 'mysql' in script_info['script'].lower():
                    success = self.execute_mysql_structure()
                elif 'postgresql' in script_info['script'].lower():
                    success = self.execute_postgresql_structure()
                else:
                    print(f"❌ 未知的SQL脚本类型: {script_info['script']}")
                    success = False
            elif script_info['type'] == 'python':
                success = self.execute_python_script(script_info['script'])
            else:
                print(f"❌ 未知的脚本类型: {script_info['type']}")
                success = False
            
            end_time = time.time()
            execution_time = end_time - start_time
            
            # 记录结果
            result_info = {
                "script_name": script_info['name'],
                "script_file": script_info['script'],
                "success": success,
                "execution_time": execution_time,
                "timestamp": datetime.now().isoformat()
            }
            self.results.append(result_info)
            
            if success:
                success_count += 1
                print(f"✅ 执行成功 (耗时: {execution_time:.2f}秒)")
            else:
                print(f"❌ 执行失败 (耗时: {execution_time:.2f}秒)")
            
            print("-" * 40)
        
        # 输出总结
        print("\n" + "=" * 60)
        print("📊 执行结果总结")
        print("=" * 60)
        print(f"✅ 成功: {success_count}/{total_count}")
        print(f"❌ 失败: {total_count - success_count}/{total_count}")
        print(f"📈 成功率: {(success_count/total_count)*100:.1f}%")
        
        # 详细结果
        print("\n📋 详细执行结果:")
        for result in self.results:
            status = "✅ 成功" if result['success'] else "❌ 失败"
            print(f"  {result['script_name']}: {status} ({result['execution_time']:.2f}秒)")
        
        return success_count == total_count
    
    def generate_report(self):
        """生成执行报告"""
        print("\n📄 生成执行报告...")
        
        report_content = f"""
# 区块链版多数据库结构创建执行报告

**执行时间**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
**执行状态**: {'✅ 全部成功' if all(r['success'] for r in self.results) else '❌ 部分失败'}

## 📊 执行统计

- **总脚本数**: {len(self.results)}
- **成功数**: {sum(1 for r in self.results if r['success'])}
- **失败数**: {sum(1 for r in self.results if not r['success'])}
- **成功率**: {(sum(1 for r in self.results if r['success'])/len(self.results))*100:.1f}%

## 📋 详细结果

"""
        
        for result in self.results:
            status = "✅ 成功" if result['success'] else "❌ 失败"
            report_content += f"""
### {result['script_name']}
- **状态**: {status}
- **执行时间**: {result['execution_time']:.2f}秒
- **脚本文件**: {result['script_file']}
- **时间戳**: {result['timestamp']}

"""
        
        report_content += """
## 🎯 下一步建议

1. **验证数据库连接**: 确保所有数据库服务正常运行
2. **检查数据结构**: 验证表结构和索引是否正确创建
3. **测试功能**: 进行基本的功能测试
4. **性能优化**: 根据实际使用情况优化数据库性能

## 📞 技术支持

如有问题，请检查：
- 数据库服务是否正常运行
- 连接参数是否正确
- 脚本文件是否存在
- 权限是否足够

---
**报告生成时间**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
"""
        
        # 保存报告
        report_filename = f"blockchain_database_execution_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.md"
        with open(report_filename, 'w', encoding='utf-8') as f:
            f.write(report_content)
        
        print(f"📄 执行报告已保存: {report_filename}")
        return report_filename

def main():
    """主函数"""
    print("🚀 区块链版多数据库结构统一执行器")
    print("=" * 60)
    
    # 创建执行器
    executor = BlockchainDatabaseExecutor()
    
    # 执行所有数据库结构创建
    success = executor.execute_all_structures()
    
    # 生成执行报告
    report_file = executor.generate_report()
    
    if success:
        print("\n🎉 区块链版多数据库结构创建全部完成!")
        print("✅ 所有数据库结构已成功创建")
        print("📄 详细报告请查看:", report_file)
    else:
        print("\n⚠️ 区块链版多数据库结构创建部分失败")
        print("❌ 请检查失败的脚本并重新执行")
        print("📄 详细报告请查看:", report_file)
    
    return success

if __name__ == "__main__":
    main()
