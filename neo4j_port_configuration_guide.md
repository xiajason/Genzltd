# Neo4j端口配置指南

**创建时间**: 2025-01-04 11:45:00  
**版本**: v1.0  
**状态**: ✅ **端口配置已确认**

---

## 🔍 Neo4j端口说明

### 两个不同的端口

Neo4j使用两个不同的端口，各有不同的用途：

#### 1. HTTP端口 (7474)
- **用途**: Neo4j Browser Web界面
- **协议**: HTTP/HTTPS
- **访问方式**: 浏览器访问
- **URL**: http://localhost:7474
- **功能**: 
  - 图形化查询界面
  - 数据可视化
  - 管理界面
  - 密码设置

#### 2. Bolt端口 (7687)
- **用途**: 数据库连接
- **协议**: Bolt (Neo4j专有协议)
- **访问方式**: 程序连接
- **URL**: bolt://localhost:7687
- **功能**:
  - 应用程序连接
  - 数据库操作
  - 事务处理
  - 查询执行

---

## 📊 端口验证结果

### 当前运行状态
```bash
# 检查端口监听状态
netstat -an | grep -E "(7474|7687)"

# 结果:
tcp4       0      0  127.0.0.1.7474         *.*                    LISTEN     # HTTP端口
tcp4       0      0  127.0.0.1.7687         *.*                    LISTEN     # Bolt端口
tcp46      0      0  *.7474                 *.*                    LISTEN     # HTTP端口(IPv6)
tcp46      0      0  *.7687                 *.*                    LISTEN     # Bolt端口(IPv6)
```

### 配置文件设置
```yaml
# unified_config.yaml
neo4j:
  host: localhost
  http_port: 7474  # Web界面端口
  bolt_port: 7687   # 数据库连接端口
  username: neo4j
  password: mbti_neo4j_2025
```

---

## 🛠️ 使用方法

### 1. 设置Neo4j密码
```bash
# 访问Web界面
open http://localhost:7474

# 或使用命令行
curl http://localhost:7474
```

### 2. 程序连接Neo4j
```python
from neo4j import GraphDatabase

# 使用Bolt端口连接
driver = GraphDatabase.driver(
    "bolt://localhost:7687",  # 使用7687端口
    auth=("neo4j", "mbti_neo4j_2025")
)

with driver.session() as session:
    result = session.run("RETURN 1 as test")
    print(result.single())
```

### 3. 测试连接
```bash
# 测试HTTP端口
curl -I http://localhost:7474

# 测试Bolt端口
telnet localhost 7687
```

---

## ⚠️ 常见问题

### 问题1: 端口混淆
**错误**: 使用7474端口进行程序连接
**解决**: 使用7687端口进行程序连接

### 问题2: 连接失败
**错误**: `Connection refused`
**解决**: 检查Neo4j服务是否运行
```bash
brew services list | grep neo4j
```

### 问题3: 认证失败
**错误**: `Authentication failed`
**解决**: 访问 http://localhost:7474 设置密码

---

## 📋 配置更新

### 已更新的文件
1. **`unified_config.yaml`** - 添加了http_port和bolt_port
2. **`unified_config.json`** - 添加了http_port和bolt_port
3. **`mbti_neo4j_integration.py`** - 更新了默认密码

### 配置验证
```python
# 验证配置
import yaml

with open('unified_config.yaml', 'r') as f:
    config = yaml.safe_load(f)
    
neo4j_config = config['database']['neo4j']
print(f"HTTP端口: {neo4j_config['http_port']}")
print(f"Bolt端口: {neo4j_config['bolt_port']}")
```

---

## 🎯 总结

### 正确的端口使用
- **Web界面**: http://localhost:7474
- **程序连接**: bolt://localhost:7687
- **密码设置**: 通过Web界面完成
- **程序测试**: 使用Bolt端口

### 配置完成状态
- ✅ 端口配置已确认
- ✅ 配置文件已更新
- ✅ 集成代码已更新
- ⚠️ 需要设置Neo4j密码

---

*此指南解决了Neo4j端口配置问题，确保正确使用两个不同的端口*
