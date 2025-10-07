# 数据库适配问题解决手册

## 🎯 手册概述
基于Future版测试数据和数据库适配过程中遇到的问题，整理出常见问题的解决方案和最佳实践，为后续工作提供参考。

## 🔍 常见问题及解决方案

### ❌ 问题1：表结构不匹配
**问题描述**: 生成的SQL脚本字段与目标表结构不匹配

**错误信息**:
```
ERROR 1054 (42S22) at line 4: Unknown column 'field_name' in 'field list'
```

**解决步骤**:
1. **分析表结构**:
   ```sql
   DESCRIBE table_name;
   SHOW CREATE TABLE table_name;
   ```

2. **对比字段**:
   - 检查SQL脚本中的字段名
   - 对比目标表的实际字段
   - 找出不匹配的字段

3. **修复SQL脚本**:
   - 删除不存在的字段
   - 调整字段顺序
   - 修正数据类型

4. **验证修复**:
   ```sql
   SELECT * FROM table_name LIMIT 1;
   ```

**预防措施**:
- 在生成SQL脚本前先分析目标表结构
- 使用动态字段检测
- 准备多个版本的SQL脚本

### ❌ 问题2：数据类型不匹配
**问题描述**: 数据类型在数据库间不兼容

**错误信息**:
```
ERROR 1366 (HY000): Incorrect string value
ERROR 1264 (22003): Out of range value
```

**解决步骤**:
1. **识别数据类型**:
   - 检查源数据的类型
   - 确认目标数据库支持的类型
   - 找出不兼容的类型

2. **类型转换**:
   ```python
   # Python示例
   if db_type == 'mysql':
       bool_value = 1 if value else 0
   elif db_type == 'postgresql':
       bool_value = 'true' if value else 'false'
   ```

3. **验证转换**:
   - 测试少量数据
   - 验证转换结果
   - 确认数据完整性

**预防措施**:
- 建立数据类型映射表
- 使用数据库原生类型
- 增加类型验证

### ❌ 问题3：文件路径问题
**问题描述**: 脚本中路径不存在或错误

**错误信息**:
```
FileNotFoundError: [Errno 2] No such file or directory
```

**解决步骤**:
1. **检查路径**:
   ```bash
   pwd
   ls -la
   find . -name "filename"
   ```

2. **修正路径**:
   - 使用相对路径
   - 避免硬编码绝对路径
   - 检查路径分隔符

3. **路径验证**:
   ```python
   import os
   if os.path.exists(file_path):
       print("文件存在")
   else:
       print("文件不存在")
   ```

**预防措施**:
- 使用相对路径
- 增加路径检查
- 使用配置文件管理路径

### ❌ 问题4：数据库连接失败
**问题描述**: 无法连接到数据库

**错误信息**:
```
ERROR 2003 (HY000): Can't connect to MySQL server
ERROR: connection to server at "localhost" failed
```

**解决步骤**:
1. **检查服务状态**:
   ```bash
   docker-compose ps
   docker logs container_name
   ```

2. **测试连接**:
   ```bash
   mysql -h host -P port -u user -p
   psql -h host -p port -U user -d database
   redis-cli -h host -p port
   ```

3. **检查配置**:
   - 确认主机和端口
   - 验证用户名和密码
   - 检查网络连接

**预防措施**:
- 建立连接测试脚本
- 使用连接池
- 增加重试机制

### ❌ 问题5：权限不足
**问题描述**: 数据库用户权限不足

**错误信息**:
```
ERROR 1142 (42000): INSERT command denied to user
ERROR: permission denied for table
```

**解决步骤**:
1. **检查权限**:
   ```sql
   SHOW GRANTS FOR 'user'@'host';
   ```

2. **授权**:
   ```sql
   GRANT INSERT, UPDATE, DELETE ON database.* TO 'user'@'host';
   FLUSH PRIVILEGES;
   ```

3. **验证权限**:
   ```sql
   SELECT * FROM information_schema.user_privileges;
   ```

**预防措施**:
- 使用最小权限原则
- 定期检查权限
- 建立权限管理流程

## 🔧 最佳实践

### 📋 数据注入前检查清单
- [ ] 数据库服务状态正常
- [ ] 数据库连接测试通过
- [ ] 表结构分析完成
- [ ] SQL脚本适配完成
- [ ] 权限验证通过
- [ ] 备份策略确认

### 📋 脚本开发规范
- [ ] 使用相对路径
- [ ] 增加错误处理
- [ ] 记录详细日志
- [ ] 支持配置管理
- [ ] 增加数据验证
- [ ] 支持回滚操作

### 📋 故障排除流程
1. **问题识别**: 分析错误信息和日志
2. **影响评估**: 评估问题影响范围
3. **解决方案**: 制定解决方案
4. **实施修复**: 执行修复操作
5. **验证结果**: 验证修复效果
6. **经验记录**: 记录问题和解决方案

## 📚 工具和命令

### 🔧 数据库连接测试
```bash
# MySQL
mysql -h host -P port -u user -p -e "SELECT 1;"

# PostgreSQL
psql -h host -p port -U user -d database -c "SELECT 1;"

# Redis
redis-cli -h host -p port ping

# Neo4j
cypher-shell -u user -p password -a bolt://host:port
```

### 🔧 表结构分析
```sql
-- MySQL
DESCRIBE table_name;
SHOW CREATE TABLE table_name;
SHOW COLUMNS FROM table_name;

-- PostgreSQL
\d table_name
SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'table_name';
```

### 🔧 数据验证
```sql
-- 检查数据数量
SELECT COUNT(*) FROM table_name;

-- 检查数据质量
SELECT * FROM table_name LIMIT 10;

-- 检查数据完整性
SELECT COUNT(*) FROM table_name WHERE column_name IS NULL;
```

## 🚀 自动化改进

### 📋 脚本优化
1. **动态表结构检测**:
   ```python
   def get_table_structure(connection, table_name):
       cursor = connection.cursor()
       cursor.execute(f"DESCRIBE {table_name}")
       return cursor.fetchall()
   ```

2. **数据类型自动转换**:
   ```python
   def convert_data_type(value, target_type):
       if target_type == 'BOOLEAN':
           return 1 if value else 0
       elif target_type == 'VARCHAR':
           return str(value)
       # 更多类型转换
   ```

3. **错误自动恢复**:
   ```python
   def retry_operation(func, max_retries=3):
       for attempt in range(max_retries):
           try:
               return func()
           except Exception as e:
               if attempt == max_retries - 1:
                   raise e
               time.sleep(2 ** attempt)
   ```

### 📋 监控和告警
1. **连接状态监控**:
   ```python
   def check_database_health():
       for db in databases:
           try:
               connection = connect(db)
               connection.ping()
               print(f"{db} 连接正常")
           except Exception as e:
               print(f"{db} 连接失败: {e}")
   ```

2. **数据质量监控**:
   ```python
   def check_data_quality():
       for table in tables:
           count = get_row_count(table)
           if count == 0:
               print(f"警告: {table} 表为空")
   ```

## 📞 经验总结

### 💪 技术要点
- **表结构分析**: 必须通过实际查询确认
- **数据类型**: 不同数据库的表示方式不同
- **路径管理**: 使用相对路径，避免硬编码
- **错误处理**: 增加完整的错误处理机制

### 💼 管理要点
- **故障排除**: 建立系统化的故障排除流程
- **文档管理**: 及时更新操作文档
- **经验分享**: 建立知识传承机制

### 🎯 质量保证
- **测试验证**: 每个步骤都要验证
- **回滚机制**: 建立数据回滚机制
- **监控告警**: 建立完善的监控系统

---
*文档创建时间: 2025年10月6日*  
*项目: JobFirst Future版数据库适配*  
*状态: 完成*  
*经验总结: 完成*
