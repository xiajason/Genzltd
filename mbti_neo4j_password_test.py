#!/usr/bin/env python3
"""
Neo4j密码测试和设置脚本
Neo4j Password Test and Setup Script

用于测试和设置Neo4j的密码
"""

import sys
import time
from neo4j import GraphDatabase

def test_neo4j_passwords():
    """测试Neo4j密码"""
    print("=" * 80)
    print("🔐 Neo4j密码测试和设置工具")
    print("=" * 80)
    
    # Neo4j配置
    host = "localhost"
    bolt_port = 7687
    user = "neo4j"
    
    # 从文档中找到的所有可能密码
    passwords = [
        "neo4j",  # 默认密码
        "looma_password",  # Looma项目密码
        "jobfirst_password_2024",  # Zervigo项目密码
        "password",  # 简单密码
        "password123",
        "admin",
        "123456",
        "",  # 空密码
    ]
    
    print(f"Neo4j连接信息:")
    print(f"  主机: {host}")
    print(f"  端口: {bolt_port}")
    print(f"  用户: {user}")
    print(f"  测试密码数量: {len(passwords)}")
    print()
    
    successful_password = None
    
    for i, password in enumerate(passwords, 1):
        try:
            print(f"[{i}/{len(passwords)}] 测试密码: {password if password else '(空密码)'}")
            
            driver = GraphDatabase.driver(
                f"bolt://{host}:{bolt_port}",
                auth=(user, password)
            )
            
            with driver.session() as session:
                result = session.run("RETURN 1 as test")
                record = result.single()
                if record and record["test"] == 1:
                    print(f"✅ 成功连接！密码是: {password if password else '(空密码)'}")
                    successful_password = password
                    driver.close()
                    break
                    
            driver.close()
            
        except Exception as e:
            error_msg = str(e)
            if "AuthenticationRateLimit" in error_msg:
                print(f"❌ 密码 {password if password else '(空密码)'} 失败: 认证速率限制")
                print("   等待5秒后继续...")
                time.sleep(5)
            else:
                print(f"❌ 密码 {password if password else '(空密码)'} 失败: {error_msg[:80]}...")
            
            time.sleep(1)  # 避免速率限制
    
    if successful_password is not None:
        print(f"\n🎉 Neo4j连接成功！")
        print(f"   用户名: {user}")
        print(f"   密码: {successful_password if successful_password else '(空密码)'}")
        print(f"   连接URL: bolt://{host}:{bolt_port}")
        
        # 记录到文件
        with open("neo4j_connection_info.txt", "w", encoding="utf-8") as f:
            f.write(f"Neo4j连接信息记录\n")
            f.write(f"==================\n")
            f.write(f"测试时间: {time.strftime('%Y-%m-%d %H:%M:%S')}\n")
            f.write(f"主机: {host}\n")
            f.write(f"端口: {bolt_port}\n")
            f.write(f"用户名: {user}\n")
            f.write(f"密码: {successful_password if successful_password else '(空密码)'}\n")
            f.write(f"连接URL: bolt://{host}:{bolt_port}\n")
            f.write(f"状态: 连接成功\n")
        
        print(f"   连接信息已保存到: neo4j_connection_info.txt")
        return True
    else:
        print(f"\n❌ 所有密码都失败了")
        print(f"   请检查Neo4j是否正在运行")
        print(f"   请访问 http://localhost:7474 设置初始密码")
        print(f"   Neo4j状态: 运行中" if check_neo4j_status() else "Neo4j状态: 未运行")
        return False

def check_neo4j_status():
    """检查Neo4j状态"""
    import subprocess
    try:
        result = subprocess.run(['ps', 'aux'], capture_output=True, text=True)
        return 'neo4j' in result.stdout.lower()
    except:
        return False

def main():
    """主函数"""
    print("开始Neo4j密码测试...")
    success = test_neo4j_passwords()
    
    if success:
        print("\n✅ Neo4j连接测试完成")
        sys.exit(0)
    else:
        print("\n❌ Neo4j连接测试失败")
        print("请手动访问 http://localhost:7474 设置密码")
        sys.exit(1)

if __name__ == "__main__":
    main()
