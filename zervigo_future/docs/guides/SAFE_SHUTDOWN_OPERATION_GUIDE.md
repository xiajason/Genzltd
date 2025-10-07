# JobFirst 安全关闭操作指南

**文档版本**: v1.0  
**更新日期**: 2025-09-12  
**适用版本**: JobFirst Basic v3.1.1

## 🎯 概述

本指南详细说明了如何安全地关闭JobFirst系统，确保数据完整性和系统稳定性。安全关闭脚本提供了完整的数据保护机制和优雅关闭流程。

## 🚨 重要提醒

### ⚠️ 数据安全警告
- **始终使用安全关闭脚本**，避免直接使用 `kill` 命令
- **关闭前会自动备份**关键数据，确保数据安全
- **数据库完整性确保**，防止数据损坏
- **优雅关闭机制**，避免进程异常终止

### 🔒 安全特性
- ✅ 自动数据备份
- ✅ 数据库完整性确保
- ✅ 优雅关闭机制
- ✅ 超时保护
- ✅ 服务注销
- ✅ 临时文件清理

## 📋 安全关闭脚本功能

### 核心功能
```bash
./scripts/maintenance/safe-shutdown.sh [选项]
```

#### 主要功能
1. **服务状态检查** - 检查所有运行中的服务
2. **关键数据备份** - 自动备份MySQL、Redis、配置文件
3. **数据库完整性确保** - 刷新数据到磁盘
4. **优雅关闭微服务** - 按正确顺序关闭服务
5. **Consul服务注销** - 从服务发现中注销
6. **临时文件清理** - 清理PID文件和临时文件
7. **基础设施服务停止** - 停止Nginx、Consul等
8. **关闭验证** - 验证所有服务已正确关闭
9. **生成关闭报告** - 详细的关闭报告

## 🛠️ 使用方法

### 1. 基本用法

#### 安全关闭（保留数据库）
```bash
# 关闭所有微服务，但保留数据库运行
./scripts/maintenance/safe-shutdown.sh
```

#### 完全关闭（包括数据库）
```bash
# 关闭所有服务，包括数据库
./scripts/maintenance/safe-shutdown.sh --stop-databases
```

#### 查看帮助
```bash
# 显示详细帮助信息
./scripts/maintenance/safe-shutdown.sh --help
```

### 2. 关闭流程详解

#### 第一阶段：准备阶段
```bash
[STEP] 检查当前服务状态...
[INFO] ✅ api_gateway 正在运行 (端口: 8080, PID: 12345)
[INFO] ✅ user_service 正在运行 (端口: 8081, PID: 12346)
[INFO] ✅ MySQL 正在运行
[INFO] ✅ Redis 正在运行
[INFO] ✅ Consul 正在运行
```

#### 第二阶段：数据备份
```bash
[STEP] 执行关键数据备份...
[INFO] 备份MySQL数据库...
[SUCCESS] MySQL数据库备份完成: /backups/20250912_183500/jobfirst_backup.sql
[INFO] 备份Redis数据...
[SUCCESS] Redis数据备份完成: /backups/20250912_183500/redis_backup.rdb
[INFO] 备份配置文件...
[SUCCESS] 配置文件备份完成
[INFO] 备份重要日志文件...
[SUCCESS] 日志文件备份完成
```

#### 第三阶段：数据完整性确保
```bash
[STEP] 确保数据库数据完整性...
[INFO] 刷新MySQL数据到磁盘...
[SUCCESS] MySQL数据完整性确保完成
[INFO] 保存Redis数据到磁盘...
[SUCCESS] Redis数据保存完成
```

#### 第四阶段：优雅关闭服务
```bash
[STEP] 优雅关闭微服务...
[INFO] 优雅关闭 ai_service (PID: 12350)...
[SUCCESS] ai_service 已关闭
[INFO] 优雅关闭 dev_team_service (PID: 12349)...
[SUCCESS] dev_team_service 已关闭
...
```

#### 第五阶段：服务注销和清理
```bash
[STEP] 从Consul注销服务...
[INFO] 注销服务: ai-service-8206
[SUCCESS] ✅ 服务 ai-service-8206 注销成功
[INFO] 注销服务: dev-team-service-8088
[SUCCESS] ✅ 服务 dev-team-service-8088 注销成功
...
```

#### 第六阶段：验证和报告
```bash
[STEP] 验证关闭结果...
[SUCCESS] 所有微服务已成功关闭
[STEP] 生成关闭报告...
[SUCCESS] 关闭报告已生成: /logs/shutdown_report_20250912_183500.txt
```

## 📊 数据备份详情

### 自动备份内容

#### 1. 数据库备份
```bash
# MySQL数据库备份
mysqldump -u root jobfirst > backup/jobfirst_backup.sql

# Redis数据备份
redis-cli --rdb backup/redis_backup.rdb
```

#### 2. 配置文件备份
```bash
# 备份配置文件
cp -r configs/ backup/configs_backup/
cp -r nginx/ backup/nginx_backup/
```

#### 3. 日志文件备份
```bash
# 备份重要日志文件
find logs/ -name "*.log" -mtime -1 -exec cp {} backup/ \;
```

#### 4. 备份清单
```bash
# 自动生成备份清单
cat > backup/backup_manifest.txt << EOF
JobFirst 数据备份清单
备份时间: 2025-09-12 18:35:00
备份路径: /backups/20250912_183500

包含内容:
- MySQL数据库: jobfirst_backup.sql
- Redis数据: redis_backup.rdb
- 配置文件: configs_backup/, nginx_backup/
- 日志文件: *.log

恢复命令:
- MySQL恢复: mysql -u root jobfirst < jobfirst_backup.sql
- Redis恢复: redis-cli --pipe < redis_backup.rdb
EOF
```

## 🔄 数据恢复指南

### MySQL数据恢复
```bash
# 恢复MySQL数据库
mysql -u root jobfirst < /backups/20250912_183500/jobfirst_backup.sql
```

### Redis数据恢复
```bash
# 停止Redis服务
brew services stop redis

# 恢复Redis数据
redis-cli --pipe < /backups/20250912_183500/redis_backup.rdb

# 启动Redis服务
brew services start redis
```

### 配置文件恢复
```bash
# 恢复配置文件
cp -r /backups/20250912_183500/configs_backup/* configs/
cp -r /backups/20250912_183500/nginx_backup/* nginx/
```

## 📈 关闭报告示例

### 关闭报告内容
```bash
==========================================
JobFirst 安全关闭报告
==========================================
关闭时间: 2025-09-12 18:35:00
关闭脚本: ./scripts/maintenance/safe-shutdown.sh
关闭日志: /logs/safe-shutdown.log

关闭步骤:
✅ 服务状态检查
✅ 关键数据备份
✅ 微服务优雅关闭
✅ Consul服务注销
✅ 数据库完整性确保
✅ 临时文件清理
✅ 基础设施服务停止

数据安全措施:
- MySQL数据库备份
- Redis数据备份
- 配置文件备份
- 日志文件备份
- 数据库完整性确保

关闭状态:
✅ 所有服务已成功关闭

备份位置: /backups/20250912_183500

恢复建议:
- 如需恢复数据，请使用备份文件
- 重新启动服务请使用启动脚本
- 检查日志文件以获取详细信息

==========================================
```

## 🚀 安全启动脚本

### 对应启动脚本
```bash
# 安全启动所有服务
./scripts/maintenance/safe-startup.sh

# 安全启动包括前端
./scripts/maintenance/safe-startup.sh --with-frontend
```

### 启动顺序
1. **基础设施服务** (MySQL, Redis, Consul)
2. **核心微服务** (API Gateway, User Service, Resume Service)
3. **业务微服务** (Company Service, Notification Service)
4. **重构微服务** (Template, Statistics, Banner, Dev Team)
5. **AI服务**

## ⚡ 快速操作指南

### 日常操作
```bash
# 1. 安全关闭系统
./scripts/maintenance/safe-shutdown.sh

# 2. 等待确认后关闭数据库（可选）
# 系统会询问是否关闭数据库服务

# 3. 重新启动系统
./scripts/maintenance/safe-startup.sh
```

### 紧急情况
```bash
# 如果需要强制关闭（不推荐）
# 1. 先尝试优雅关闭
./scripts/maintenance/safe-shutdown.sh

# 2. 如果失败，检查进程
ps aux | grep -E "(go run|python|node)"

# 3. 手动清理（最后手段）
kill -9 <PID>
```

## 🔧 故障排除

### 常见问题

#### 1. 端口被占用
```bash
# 检查端口占用
lsof -Pi :8080 -sTCP:LISTEN

# 强制清理端口
kill -9 $(lsof -Pi :8080 -sTCP:LISTEN -t)
```

#### 2. 服务无法关闭
```bash
# 检查服务状态
./scripts/maintenance/safe-shutdown.sh

# 手动关闭特定服务
kill -TERM <PID>
```

#### 3. 数据库连接问题
```bash
# 检查数据库状态
brew services list | grep mysql
brew services list | grep redis

# 重启数据库服务
brew services restart mysql
brew services restart redis
```

#### 4. 备份文件问题
```bash
# 检查备份目录
ls -la /backups/

# 检查备份文件大小
du -sh /backups/*/
```

## 📝 最佳实践

### 1. 定期备份
```bash
# 建议每天自动备份
0 2 * * * /path/to/safe-shutdown.sh --backup-only
```

### 2. 监控关闭日志
```bash
# 查看关闭日志
tail -f logs/safe-shutdown.log

# 检查关闭报告
cat logs/shutdown_report_*.txt
```

### 3. 验证数据完整性
```bash
# 启动后验证数据
./scripts/maintenance/safe-startup.sh
./backend/pkg/jobfirst-core/superadmin/zervigo_standalone full
```

### 4. 定期清理备份
```bash
# 保留最近7天的备份
find /backups/ -type d -mtime +7 -exec rm -rf {} \;
```

## 🎉 总结

### ✅ 安全关闭的优势
- **数据安全**: 自动备份所有关键数据
- **优雅关闭**: 按正确顺序关闭服务
- **完整性确保**: 数据库数据完整性保护
- **服务注销**: 从Consul正确注销服务
- **详细日志**: 完整的关闭过程记录

### 🔒 数据保护机制
- **多层备份**: MySQL、Redis、配置文件、日志
- **完整性验证**: 关闭前确保数据完整性
- **恢复机制**: 提供完整的数据恢复方案
- **监控报告**: 详细的关闭状态报告

**使用安全关闭脚本，确保您的JobFirst系统数据安全和系统稳定性！** 🏆

---

**文档维护**: AI Assistant  
**最后更新**: 2025-09-12  
**版本**: v1.0
