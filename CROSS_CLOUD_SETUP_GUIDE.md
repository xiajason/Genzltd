# 跨云数据库集群通信和数据同步设置指南

## 🎯 设置概述

本指南将帮助您完成阿里云和腾讯云多数据库集群之间的通信和数据同步设置。

**设置时间**: 2025年10月7日  
**目标**: 建立阿里云 ↔ 腾讯云跨云数据库集群通信和数据同步  
**状态**: 待用户配置阿里云安全组

## 📋 设置步骤总览

### 第一步: 配置阿里云安全组 ⏳ (当前步骤)

**目标**: 开放8个数据库端口，允许跨云访问

**端口清单**:
```
序号 | 端口  | 协议 | 数据库           | 描述
-----|------|------|-----------------|----------------------------------
 1   | 3306 | TCP  | MySQL           | MySQL数据库主从复制和外部访问
 2   | 5432 | TCP  | PostgreSQL      | PostgreSQL数据库流复制和外部访问
 3   | 6379 | TCP  | Redis           | Redis数据库主从复制和外部访问
 4   | 7474 | TCP  | Neo4j           | Neo4j HTTP接口访问
 5   | 7687 | TCP  | Neo4j           | Neo4j Bolt协议连接
 6   | 9200 | TCP  | Elasticsearch   | Elasticsearch HTTP接口访问
 7   | 9300 | TCP  | Elasticsearch   | Elasticsearch节点间通信
 8   | 8080 | TCP  | Weaviate        | Weaviate HTTP接口访问
```

**配置步骤**:
1. 登录阿里云控制台: https://ecs.console.aliyun.com
2. 进入: 网络与安全 > 安全组
3. 找到您的ECS实例对应的安全组
4. 点击 "配置规则" > "入方向"
5. 点击 "添加安全组规则"，逐个添加以上8个端口

**每个端口的配置信息**:
```
规则方向: 入方向
授权策略: 允许
协议类型: 自定义TCP
端口范围: [对应端口号]
授权对象: 0.0.0.0/0 (推荐) 或 101.33.251.158/32 (更安全)
优先级: 1
描述: [对应描述]
```

**参考文档**:
- `alibaba_cloud_security_group_config.md` - 完整配置指南
- `alibaba_cloud_ports_checklist.txt` - 快速配置清单

**配置完成后**:
运行验证脚本: `./verify_alibaba_security_group.sh`

---

### 第二步: 验证跨云网络连通性

**目标**: 确认阿里云和腾讯云之间的网络连接正常

**验证脚本**: `./verify_alibaba_security_group.sh`

**验证内容**:
- 测试阿里云8个端口的连通性
- 确认防火墙规则正确配置
- 验证网络延迟和稳定性

**成功标准**: 所有8个端口验证通过

---

### 第三步: 实施数据库复制配置

**目标**: 配置6个数据库的主从复制

**实施脚本**: `./implement_cross_cloud_sync.sh`

**配置内容**:
1. MySQL主从复制
2. PostgreSQL流复制
3. Redis主从复制
4. Neo4j集群复制
5. Elasticsearch跨集群复制
6. Weaviate跨集群复制

**执行命令**:
```bash
./implement_cross_cloud_sync.sh
```

---

### 第四步: 测试数据同步功能

**目标**: 验证跨云数据同步是否正常工作

**测试脚本**: `test_cross_cloud_sync.py`

**测试内容**:
1. 跨云连接性测试
2. MySQL数据同步测试
3. Redis数据同步测试
4. Neo4j数据同步测试
5. Elasticsearch数据同步测试
6. Weaviate数据同步测试

**执行命令**:
```bash
python3 test_cross_cloud_sync.py
```

**成功标准**: 所有数据库同步测试通过

---

### 第五步: 部署监控系统

**目标**: 建立实时同步状态监控

**监控脚本**:
- `alibaba_sync_monitor.py` - 阿里云监控
- `tencent_sync_monitor.py` - 腾讯云监控

**监控内容**:
- 连接状态监控
- 复制延迟监控
- 数据一致性监控
- 故障告警

**执行命令**:
```bash
# 阿里云监控
python3 alibaba_sync_monitor.py

# 腾讯云监控
python3 tencent_sync_monitor.py
```

---

### 第六步: 性能优化和持续维护

**目标**: 优化复制性能，建立持续维护机制

**优化内容**:
1. 分析复制延迟
2. 优化复制配置
3. 提高复制性能
4. 建立告警机制

**维护内容**:
1. 定期健康检查
2. 性能监控
3. 日志审计
4. 安全更新

---

## 🔐 安全配置建议

### 推荐配置 (最安全)
```yaml
授权对象: 101.33.251.158/32
说明: 只允许腾讯云服务器访问
优点: 最高安全性
适用: 仅需要跨云同步
```

### 便捷配置 (较安全)
```yaml
授权对象: 0.0.0.0/0
说明: 允许所有IP访问
优点: 配置简单，访问方便
适用: 需要本地管理工具访问
注意: 所有数据库已配置强密码保护
```

### 混合配置 (推荐)
```yaml
核心数据库 (MySQL, PostgreSQL):
  授权对象: 101.33.251.158/32
  
其他数据库 (Redis, Neo4j, ES, Weaviate):
  授权对象: 0.0.0.0/0
```

---

## 📊 配置验证清单

### 阿里云安全组配置
- [ ] MySQL端口 (3306) 已开放
- [ ] PostgreSQL端口 (5432) 已开放
- [ ] Redis端口 (6379) 已开放
- [ ] Neo4j HTTP端口 (7474) 已开放
- [ ] Neo4j Bolt端口 (7687) 已开放
- [ ] Elasticsearch HTTP端口 (9200) 已开放
- [ ] Elasticsearch Transport端口 (9300) 已开放
- [ ] Weaviate端口 (8080) 已开放

### 网络连通性验证
- [ ] 阿里云到腾讯云网络连接正常
- [ ] 腾讯云到阿里云网络连接正常
- [ ] 所有端口连通性测试通过
- [ ] 网络延迟在可接受范围内

### 数据库复制配置
- [ ] MySQL主从复制配置完成
- [ ] PostgreSQL流复制配置完成
- [ ] Redis主从复制配置完成
- [ ] Neo4j集群复制配置完成
- [ ] Elasticsearch跨集群复制配置完成
- [ ] Weaviate跨集群复制配置完成

### 数据同步测试
- [ ] MySQL数据同步测试通过
- [ ] Redis数据同步测试通过
- [ ] Neo4j数据同步测试通过
- [ ] Elasticsearch数据同步测试通过
- [ ] Weaviate数据同步测试通过
- [ ] 数据一致性验证通过

### 监控系统部署
- [ ] 阿里云监控脚本部署完成
- [ ] 腾讯云监控脚本部署完成
- [ ] 监控指标配置完成
- [ ] 告警机制建立完成

---

## 🚀 快速开始

### 当前步骤 (第一步)

**您现在需要做的**:

1. **打开阿里云控制台**
   - 访问: https://ecs.console.aliyun.com
   
2. **配置安全组**
   - 进入: 网络与安全 > 安全组
   - 参考: `alibaba_cloud_ports_checklist.txt`
   - 配置8个端口 (3306, 5432, 6379, 7474, 7687, 9200, 9300, 8080)

3. **验证配置**
   - 配置完成后，运行: `./verify_alibaba_security_group.sh`
   - 确认所有端口验证通过

4. **通知我**
   - 配置完成后，告诉我验证结果
   - 我会帮您继续后续步骤

---

## 📋 相关文档

### 配置指南
- `alibaba_cloud_security_group_config.md` - 阿里云安全组完整配置指南
- `alibaba_cloud_ports_checklist.txt` - 端口快速配置清单
- `CROSS_CLOUD_SETUP_GUIDE.md` - 本文档

### 解决方案文档
- `cross_cloud_sync_summary.md` - 跨云同步解决方案总结
- `THREE_ENVIRONMENT_ARCHITECTURE_REDEFINITION.md` - 三环境架构定义

### 实施脚本
- `implement_cross_cloud_sync.sh` - 跨云同步实施脚本
- `test_cross_cloud_sync.py` - 跨云同步测试脚本
- `verify_alibaba_security_group.sh` - 安全组验证脚本

### 监控脚本
- `alibaba_sync_monitor.py` - 阿里云同步监控
- `tencent_sync_monitor.py` - 腾讯云同步监控

---

## 💡 注意事项

1. **端口绑定检查**
   - 确保数据库容器端口绑定到 0.0.0.0，而不是 127.0.0.1
   - 检查命令: `ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker ps --format 'table {{.Names}}\t{{.Ports}}'"`

2. **防火墙配置**
   - 除了阿里云安全组，还需要检查服务器内部防火墙
   - 如果启用了防火墙，需要开放对应端口

3. **密码安全**
   - 所有数据库都已配置强密码保护
   - 密码信息:
     - MySQL: f_mysql_password_2025
     - PostgreSQL: f_postgres_password_2025
     - Redis: f_redis_password_2025
     - Neo4j: f_neo4j_password_2025

4. **网络延迟**
   - 跨云数据同步会有一定网络延迟
   - 建议在低峰期进行初始数据同步
   - 持续监控复制延迟

5. **数据一致性**
   - 定期验证数据一致性
   - 建立自动化验证机制
   - 出现问题及时告警

---

## 🎉 设置完成标准

当以下所有条件满足时，跨云数据库集群通信和数据同步设置完成:

✅ 阿里云安全组配置完成 (8个端口开放)  
✅ 跨云网络连通性验证通过  
✅ 数据库复制配置完成 (6个数据库)  
✅ 数据同步测试通过 (所有数据库)  
✅ 监控系统部署完成  
✅ 性能优化完成  

**🚀 设置完成后，将支持阿里云和腾讯云之间的无缝数据交互，为AI服务部署奠定坚实基础！**

---
*设置指南创建时间: 2025年10月7日*  
*当前状态: 待用户配置阿里云安全组*  
*下一步: 用户完成安全组配置后运行验证脚本*
