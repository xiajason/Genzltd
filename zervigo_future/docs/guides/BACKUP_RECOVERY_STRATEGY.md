# 备份和恢复策略

## 🎯 概述

本文档详细说明JobFirst系统的备份和恢复策略，确保数据安全和业务连续性。

## 🏗️ 备份架构

### 备份层次结构
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   实时备份       │    │   定期备份       │    │   灾难恢复       │
├─────────────────┤    ├─────────────────┤    ├─────────────────┤
│ • 数据库主从     │    │ • 每日全量备份   │    │ • 异地备份       │
│ • Redis主从     │    │ • 每周增量备份   │    │ • 云存储备份     │
│ • 文件同步       │    │ • 每月归档备份   │    │ • 快速恢复       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │   备份管理       │
                    ├─────────────────┤
                    │ • 自动化脚本     │
                    │ • 备份验证       │
                    │ • 恢复测试       │
                    │ • 监控告警       │
                    └─────────────────┘
```

## 🔧 备份策略

### 1. 数据库备份

#### 1.1 MySQL备份策略
```bash
#!/bin/bash
# scripts/backup-mysql.sh
#!/bin/bash

# 配置变量
DB_HOST="localhost"
DB_USER="backup_user"
DB_PASSWORD="backup_password"
DB_NAME="jobfirst"
BACKUP_DIR="/opt/jobfirst/backup/mysql"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=30

# 创建备份目录
mkdir -p $BACKUP_DIR

# 全量备份
echo "开始MySQL全量备份..."
mysqldump -h $DB_HOST -u $DB_USER -p$DB_PASSWORD \
    --single-transaction \
    --routines \
    --triggers \
    --events \
    --hex-blob \
    --master-data=2 \
    $DB_NAME > $BACKUP_DIR/mysql_full_$DATE.sql

# 压缩备份文件
gzip $BACKUP_DIR/mysql_full_$DATE.sql

# 验证备份文件
if [ -f "$BACKUP_DIR/mysql_full_$DATE.sql.gz" ]; then
    echo "MySQL备份成功: mysql_full_$DATE.sql.gz"
    
    # 计算文件大小
    BACKUP_SIZE=$(du -h $BACKUP_DIR/mysql_full_$DATE.sql.gz | cut -f1)
    echo "备份文件大小: $BACKUP_SIZE"
    
    # 验证备份完整性
    gunzip -t $BACKUP_DIR/mysql_full_$DATE.sql.gz
    if [ $? -eq 0 ]; then
        echo "备份文件完整性验证通过"
    else
        echo "备份文件完整性验证失败"
        exit 1
    fi
else
    echo "MySQL备份失败"
    exit 1
fi

# 清理过期备份
find $BACKUP_DIR -name "mysql_full_*.sql.gz" -mtime +$RETENTION_DAYS -delete
echo "清理$RETENTION_DAYS天前的备份文件"

echo "MySQL备份完成"
```

#### 1.2 PostgreSQL备份策略
```bash
#!/bin/bash
# scripts/backup-postgresql.sh
#!/bin/bash

# 配置变量
DB_HOST="localhost"
DB_USER="backup_user"
DB_NAME="jobfirst_vector"
BACKUP_DIR="/opt/jobfirst/backup/postgresql"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=30

# 创建备份目录
mkdir -p $BACKUP_DIR

# 全量备份
echo "开始PostgreSQL全量备份..."
pg_dump -h $DB_HOST -U $DB_USER \
    --verbose \
    --clean \
    --no-owner \
    --no-privileges \
    --format=custom \
    $DB_NAME > $BACKUP_DIR/postgresql_full_$DATE.dump

# 验证备份文件
if [ -f "$BACKUP_DIR/postgresql_full_$DATE.dump" ]; then
    echo "PostgreSQL备份成功: postgresql_full_$DATE.dump"
    
    # 计算文件大小
    BACKUP_SIZE=$(du -h $BACKUP_DIR/postgresql_full_$DATE.dump | cut -f1)
    echo "备份文件大小: $BACKUP_SIZE"
    
    # 验证备份完整性
    pg_restore --list $BACKUP_DIR/postgresql_full_$DATE.dump > /dev/null
    if [ $? -eq 0 ]; then
        echo "备份文件完整性验证通过"
    else
        echo "备份文件完整性验证失败"
        exit 1
    fi
else
    echo "PostgreSQL备份失败"
    exit 1
fi

# 清理过期备份
find $BACKUP_DIR -name "postgresql_full_*.dump" -mtime +$RETENTION_DAYS -delete
echo "清理$RETENTION_DAYS天前的备份文件"

echo "PostgreSQL备份完成"
```

#### 1.3 Redis备份策略
```bash
#!/bin/bash
# scripts/backup-redis.sh
#!/bin/bash

# 配置变量
REDIS_HOST="localhost"
REDIS_PORT="6379"
REDIS_PASSWORD="redis_password"
BACKUP_DIR="/opt/jobfirst/backup/redis"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=7

# 创建备份目录
mkdir -p $BACKUP_DIR

# Redis备份
echo "开始Redis备份..."
redis-cli -h $REDIS_HOST -p $REDIS_PORT -a $REDIS_PASSWORD BGSAVE

# 等待备份完成
while [ $(redis-cli -h $REDIS_HOST -p $REDIS_PORT -a $REDIS_PASSWORD LASTSAVE) -eq $(redis-cli -h $REDIS_HOST -p $REDIS_PORT -a $REDIS_PASSWORD LASTSAVE) ]; do
    sleep 1
done

# 复制备份文件
cp /var/lib/redis/dump.rdb $BACKUP_DIR/redis_$DATE.rdb

# 验证备份文件
if [ -f "$BACKUP_DIR/redis_$DATE.rdb" ]; then
    echo "Redis备份成功: redis_$DATE.rdb"
    
    # 计算文件大小
    BACKUP_SIZE=$(du -h $BACKUP_DIR/redis_$DATE.rdb | cut -f1)
    echo "备份文件大小: $BACKUP_SIZE"
else
    echo "Redis备份失败"
    exit 1
fi

# 清理过期备份
find $BACKUP_DIR -name "redis_*.rdb" -mtime +$RETENTION_DAYS -delete
echo "清理$RETENTION_DAYS天前的备份文件"

echo "Redis备份完成"
```

### 2. 文件备份

#### 2.1 应用文件备份
```bash
#!/bin/bash
# scripts/backup-files.sh
#!/bin/bash

# 配置变量
SOURCE_DIR="/opt/jobfirst"
BACKUP_DIR="/opt/jobfirst/backup/files"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=30

# 创建备份目录
mkdir -p $BACKUP_DIR

# 备份应用文件
echo "开始应用文件备份..."
tar -czf $BACKUP_DIR/app_files_$DATE.tar.gz \
    --exclude="logs/*" \
    --exclude="backup/*" \
    --exclude="temp/*" \
    -C $SOURCE_DIR .

# 验证备份文件
if [ -f "$BACKUP_DIR/app_files_$DATE.tar.gz" ]; then
    echo "应用文件备份成功: app_files_$DATE.tar.gz"
    
    # 计算文件大小
    BACKUP_SIZE=$(du -h $BACKUP_DIR/app_files_$DATE.tar.gz | cut -f1)
    echo "备份文件大小: $BACKUP_SIZE"
    
    # 验证备份完整性
    tar -tzf $BACKUP_DIR/app_files_$DATE.tar.gz > /dev/null
    if [ $? -eq 0 ]; then
        echo "备份文件完整性验证通过"
    else
        echo "备份文件完整性验证失败"
        exit 1
    fi
else
    echo "应用文件备份失败"
    exit 1
fi

# 清理过期备份
find $BACKUP_DIR -name "app_files_*.tar.gz" -mtime +$RETENTION_DAYS -delete
echo "清理$RETENTION_DAYS天前的备份文件"

echo "应用文件备份完成"
```

#### 2.2 用户上传文件备份
```bash
#!/bin/bash
# scripts/backup-uploads.sh
#!/bin/bash

# 配置变量
UPLOADS_DIR="/opt/jobfirst/uploads"
BACKUP_DIR="/opt/jobfirst/backup/uploads"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=90

# 创建备份目录
mkdir -p $BACKUP_DIR

# 备份用户上传文件
echo "开始用户上传文件备份..."
if [ -d "$UPLOADS_DIR" ]; then
    tar -czf $BACKUP_DIR/uploads_$DATE.tar.gz -C $UPLOADS_DIR .
    
    # 验证备份文件
    if [ -f "$BACKUP_DIR/uploads_$DATE.tar.gz" ]; then
        echo "用户上传文件备份成功: uploads_$DATE.tar.gz"
        
        # 计算文件大小
        BACKUP_SIZE=$(du -h $BACKUP_DIR/uploads_$DATE.tar.gz | cut -f1)
        echo "备份文件大小: $BACKUP_SIZE"
    else
        echo "用户上传文件备份失败"
        exit 1
    fi
else
    echo "用户上传目录不存在，跳过备份"
fi

# 清理过期备份
find $BACKUP_DIR -name "uploads_*.tar.gz" -mtime +$RETENTION_DAYS -delete
echo "清理$RETENTION_DAYS天前的备份文件"

echo "用户上传文件备份完成"
```

### 3. 配置备份

#### 3.1 系统配置备份
```bash
#!/bin/bash
# scripts/backup-configs.sh
#!/bin/bash

# 配置变量
CONFIG_DIR="/opt/jobfirst/configs"
BACKUP_DIR="/opt/jobfirst/backup/configs"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=365

# 创建备份目录
mkdir -p $BACKUP_DIR

# 备份配置文件
echo "开始配置文件备份..."
tar -czf $BACKUP_DIR/configs_$DATE.tar.gz -C $CONFIG_DIR .

# 备份系统配置
cp /etc/nginx/sites-available/jobfirst $BACKUP_DIR/nginx_jobfirst_$DATE.conf
cp /etc/systemd/system/jobfirst-*.service $BACKUP_DIR/ 2>/dev/null || true

# 验证备份文件
if [ -f "$BACKUP_DIR/configs_$DATE.tar.gz" ]; then
    echo "配置文件备份成功: configs_$DATE.tar.gz"
    
    # 计算文件大小
    BACKUP_SIZE=$(du -h $BACKUP_DIR/configs_$DATE.tar.gz | cut -f1)
    echo "备份文件大小: $BACKUP_SIZE"
else
    echo "配置文件备份失败"
    exit 1
fi

# 清理过期备份
find $BACKUP_DIR -name "configs_*.tar.gz" -mtime +$RETENTION_DAYS -delete
echo "清理$RETENTION_DAYS天前的备份文件"

echo "配置文件备份完成"
```

## 🔄 恢复策略

### 1. 数据库恢复

#### 1.1 MySQL恢复
```bash
#!/bin/bash
# scripts/restore-mysql.sh
#!/bin/bash

# 配置变量
DB_HOST="localhost"
DB_USER="root"
DB_PASSWORD="root_password"
DB_NAME="jobfirst"
BACKUP_FILE="$1"

if [ -z "$BACKUP_FILE" ]; then
    echo "用法: $0 <备份文件路径>"
    echo "示例: $0 /opt/jobfirst/backup/mysql/mysql_full_20240910_120000.sql.gz"
    exit 1
fi

# 检查备份文件是否存在
if [ ! -f "$BACKUP_FILE" ]; then
    echo "备份文件不存在: $BACKUP_FILE"
    exit 1
fi

# 停止应用服务
echo "停止应用服务..."
systemctl stop jobfirst-backend
systemctl stop jobfirst-ai

# 创建数据库备份
echo "创建当前数据库备份..."
CURRENT_BACKUP="/opt/jobfirst/backup/mysql/current_backup_$(date +%Y%m%d_%H%M%S).sql"
mysqldump -h $DB_HOST -u $DB_USER -p$DB_PASSWORD $DB_NAME > $CURRENT_BACKUP

# 恢复数据库
echo "开始恢复数据库..."
if [[ "$BACKUP_FILE" == *.gz ]]; then
    gunzip -c $BACKUP_FILE | mysql -h $DB_HOST -u $DB_USER -p$DB_PASSWORD $DB_NAME
else
    mysql -h $DB_HOST -u $DB_USER -p$DB_PASSWORD $DB_NAME < $BACKUP_FILE
fi

if [ $? -eq 0 ]; then
    echo "数据库恢复成功"
    
    # 启动应用服务
    echo "启动应用服务..."
    systemctl start jobfirst-backend
    systemctl start jobfirst-ai
    
    # 验证服务状态
    sleep 10
    curl -f http://localhost:8080/health || echo "服务健康检查失败"
else
    echo "数据库恢复失败"
    exit 1
fi

echo "数据库恢复完成"
```

#### 1.2 PostgreSQL恢复
```bash
#!/bin/bash
# scripts/restore-postgresql.sh
#!/bin/bash

# 配置变量
DB_HOST="localhost"
DB_USER="postgres"
DB_NAME="jobfirst_vector"
BACKUP_FILE="$1"

if [ -z "$BACKUP_FILE" ]; then
    echo "用法: $0 <备份文件路径>"
    echo "示例: $0 /opt/jobfirst/backup/postgresql/postgresql_full_20240910_120000.dump"
    exit 1
fi

# 检查备份文件是否存在
if [ ! -f "$BACKUP_FILE" ]; then
    echo "备份文件不存在: $BACKUP_FILE"
    exit 1
fi

# 停止应用服务
echo "停止应用服务..."
systemctl stop jobfirst-ai

# 恢复数据库
echo "开始恢复PostgreSQL数据库..."
pg_restore -h $DB_HOST -U $DB_USER \
    --verbose \
    --clean \
    --no-owner \
    --no-privileges \
    --dbname $DB_NAME \
    $BACKUP_FILE

if [ $? -eq 0 ]; then
    echo "PostgreSQL数据库恢复成功"
    
    # 启动应用服务
    echo "启动应用服务..."
    systemctl start jobfirst-ai
    
    # 验证服务状态
    sleep 10
    curl -f http://localhost:8206/health || echo "AI服务健康检查失败"
else
    echo "PostgreSQL数据库恢复失败"
    exit 1
fi

echo "PostgreSQL数据库恢复完成"
```

### 2. 文件恢复

#### 2.1 应用文件恢复
```bash
#!/bin/bash
# scripts/restore-files.sh
#!/bin/bash

# 配置变量
TARGET_DIR="/opt/jobfirst"
BACKUP_FILE="$1"

if [ -z "$BACKUP_FILE" ]; then
    echo "用法: $0 <备份文件路径>"
    echo "示例: $0 /opt/jobfirst/backup/files/app_files_20240910_120000.tar.gz"
    exit 1
fi

# 检查备份文件是否存在
if [ ! -f "$BACKUP_FILE" ]; then
    echo "备份文件不存在: $BACKUP_FILE"
    exit 1
fi

# 停止应用服务
echo "停止应用服务..."
systemctl stop jobfirst-backend
systemctl stop jobfirst-ai
systemctl stop nginx

# 备份当前文件
echo "备份当前应用文件..."
CURRENT_BACKUP="/opt/jobfirst/backup/files/current_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
tar -czf $CURRENT_BACKUP -C $TARGET_DIR .

# 恢复应用文件
echo "开始恢复应用文件..."
tar -xzf $BACKUP_FILE -C $TARGET_DIR

if [ $? -eq 0 ]; then
    echo "应用文件恢复成功"
    
    # 设置权限
    chown -R root:root $TARGET_DIR
    chmod +x $TARGET_DIR/scripts/*.sh
    
    # 启动应用服务
    echo "启动应用服务..."
    systemctl start nginx
    systemctl start jobfirst-backend
    systemctl start jobfirst-ai
    
    # 验证服务状态
    sleep 10
    curl -f http://localhost/health || echo "服务健康检查失败"
else
    echo "应用文件恢复失败"
    exit 1
fi

echo "应用文件恢复完成"
```

## ⏰ 自动化备份

### 1. 定时任务配置
```bash
# 编辑crontab
crontab -e

# 添加以下定时任务
# 每日凌晨2点执行数据库备份
0 2 * * * /opt/jobfirst/scripts/backup-mysql.sh >> /opt/jobfirst/logs/backup.log 2>&1
0 2 * * * /opt/jobfirst/scripts/backup-postgresql.sh >> /opt/jobfirst/logs/backup.log 2>&1

# 每日凌晨3点执行Redis备份
0 3 * * * /opt/jobfirst/scripts/backup-redis.sh >> /opt/jobfirst/logs/backup.log 2>&1

# 每日凌晨4点执行文件备份
0 4 * * * /opt/jobfirst/scripts/backup-files.sh >> /opt/jobfirst/logs/backup.log 2>&1
0 4 * * * /opt/jobfirst/scripts/backup-uploads.sh >> /opt/jobfirst/logs/backup.log 2>&1

# 每日凌晨5点执行配置备份
0 5 * * * /opt/jobfirst/scripts/backup-configs.sh >> /opt/jobfirst/logs/backup.log 2>&1

# 每周日凌晨1点执行完整备份
0 1 * * 0 /opt/jobfirst/scripts/backup-full.sh >> /opt/jobfirst/logs/backup.log 2>&1
```

### 2. 完整备份脚本
```bash
#!/bin/bash
# scripts/backup-full.sh
#!/bin/bash

# 配置变量
BACKUP_DIR="/opt/jobfirst/backup"
DATE=$(date +%Y%m%d_%H%M%S)
FULL_BACKUP_DIR="$BACKUP_DIR/full_$DATE"

# 创建完整备份目录
mkdir -p $FULL_BACKUP_DIR

echo "开始完整系统备份..."

# 执行所有备份
/opt/jobfirst/scripts/backup-mysql.sh
/opt/jobfirst/scripts/backup-postgresql.sh
/opt/jobfirst/scripts/backup-redis.sh
/opt/jobfirst/scripts/backup-files.sh
/opt/jobfirst/scripts/backup-uploads.sh
/opt/jobfirst/scripts/backup-configs.sh

# 复制所有备份到完整备份目录
cp -r $BACKUP_DIR/mysql $FULL_BACKUP_DIR/
cp -r $BACKUP_DIR/postgresql $FULL_BACKUP_DIR/
cp -r $BACKUP_DIR/redis $FULL_BACKUP_DIR/
cp -r $BACKUP_DIR/files $FULL_BACKUP_DIR/
cp -r $BACKUP_DIR/uploads $FULL_BACKUP_DIR/
cp -r $BACKUP_DIR/configs $FULL_BACKUP_DIR/

# 创建完整备份压缩包
cd $BACKUP_DIR
tar -czf full_backup_$DATE.tar.gz full_$DATE/

# 计算备份大小
BACKUP_SIZE=$(du -h full_backup_$DATE.tar.gz | cut -f1)
echo "完整备份完成: full_backup_$DATE.tar.gz (大小: $BACKUP_SIZE)"

# 清理临时目录
rm -rf full_$DATE

echo "完整系统备份完成"
```

## 🚨 灾难恢复

### 1. 快速恢复流程
```bash
#!/bin/bash
# scripts/disaster-recovery.sh
#!/bin/bash

# 配置变量
BACKUP_FILE="$1"
RECOVERY_DIR="/opt/jobfirst/recovery"

if [ -z "$BACKUP_FILE" ]; then
    echo "用法: $0 <完整备份文件路径>"
    echo "示例: $0 /opt/jobfirst/backup/full_backup_20240910_120000.tar.gz"
    exit 1
fi

# 检查备份文件是否存在
if [ ! -f "$BACKUP_FILE" ]; then
    echo "备份文件不存在: $BACKUP_FILE"
    exit 1
fi

echo "开始灾难恢复..."

# 停止所有服务
echo "停止所有服务..."
systemctl stop nginx
systemctl stop jobfirst-backend
systemctl stop jobfirst-ai
systemctl stop mysql
systemctl stop postgresql
systemctl stop redis

# 创建恢复目录
mkdir -p $RECOVERY_DIR

# 解压备份文件
echo "解压备份文件..."
tar -xzf $BACKUP_FILE -C $RECOVERY_DIR

# 恢复数据库
echo "恢复MySQL数据库..."
mysql -u root -p < $RECOVERY_DIR/full_*/mysql/mysql_full_*.sql

echo "恢复PostgreSQL数据库..."
pg_restore -U postgres -d jobfirst_vector $RECOVERY_DIR/full_*/postgresql/postgresql_full_*.dump

# 恢复Redis
echo "恢复Redis数据..."
cp $RECOVERY_DIR/full_*/redis/redis_*.rdb /var/lib/redis/dump.rdb

# 恢复应用文件
echo "恢复应用文件..."
tar -xzf $RECOVERY_DIR/full_*/files/app_files_*.tar.gz -C /opt/jobfirst/

# 恢复配置文件
echo "恢复配置文件..."
tar -xzf $RECOVERY_DIR/full_*/configs/configs_*.tar.gz -C /opt/jobfirst/configs/

# 启动服务
echo "启动服务..."
systemctl start mysql
systemctl start postgresql
systemctl start redis
systemctl start nginx
systemctl start jobfirst-backend
systemctl start jobfirst-ai

# 验证服务状态
echo "验证服务状态..."
sleep 30
curl -f http://localhost/health || echo "服务健康检查失败"

# 清理恢复目录
rm -rf $RECOVERY_DIR

echo "灾难恢复完成"
```

### 2. 异地备份
```bash
#!/bin/bash
# scripts/remote-backup.sh
#!/bin/bash

# 配置变量
LOCAL_BACKUP_DIR="/opt/jobfirst/backup"
REMOTE_HOST="backup-server"
REMOTE_USER="backup"
REMOTE_DIR="/backup/jobfirst"
DATE=$(date +%Y%m%d_%H%M%S)

echo "开始异地备份..."

# 同步备份文件到远程服务器
rsync -avz --delete $LOCAL_BACKUP_DIR/ $REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/

if [ $? -eq 0 ]; then
    echo "异地备份成功"
else
    echo "异地备份失败"
    exit 1
fi

echo "异地备份完成"
```

## 📊 备份监控

### 1. 备份状态监控
```bash
#!/bin/bash
# scripts/backup-monitor.sh
#!/bin/bash

# 配置变量
BACKUP_DIR="/opt/jobfirst/backup"
LOG_FILE="/opt/jobfirst/logs/backup-monitor.log"

# 检查备份文件
check_backup() {
    local backup_type=$1
    local backup_dir=$2
    local retention_days=$3
    
    echo "检查 $backup_type 备份..."
    
    # 检查最新备份文件
    latest_backup=$(find $backup_dir -name "*$backup_type*" -type f -mtime -1 | head -1)
    
    if [ -n "$latest_backup" ]; then
        backup_size=$(du -h $latest_backup | cut -f1)
        backup_time=$(stat -c %y $latest_backup)
        echo "✅ $backup_type 备份正常: $latest_backup (大小: $backup_size, 时间: $backup_time)"
    else
        echo "❌ $backup_type 备份缺失或过期"
        return 1
    fi
}

# 检查所有备份
echo "=== 备份状态检查 ===" > $LOG_FILE
check_backup "mysql" "$BACKUP_DIR/mysql" 30 >> $LOG_FILE
check_backup "postgresql" "$BACKUP_DIR/postgresql" 30 >> $LOG_FILE
check_backup "redis" "$BACKUP_DIR/redis" 7 >> $LOG_FILE
check_backup "files" "$BACKUP_DIR/files" 30 >> $LOG_FILE
check_backup "uploads" "$BACKUP_DIR/uploads" 90 >> $LOG_FILE
check_backup "configs" "$BACKUP_DIR/configs" 365 >> $LOG_FILE

echo "备份状态检查完成，详情请查看: $LOG_FILE"
```

### 2. 备份告警
```bash
#!/bin/bash
# scripts/backup-alert.sh
#!/bin/bash

# 配置变量
BACKUP_DIR="/opt/jobfirst/backup"
ALERT_EMAIL="admin@jobfirst.com"
ALERT_SLACK_WEBHOOK="https://hooks.slack.com/services/..."

# 发送告警
send_alert() {
    local message=$1
    local severity=$2
    
    # 发送邮件告警
    echo "$message" | mail -s "JobFirst备份告警 - $severity" $ALERT_EMAIL
    
    # 发送Slack告警
    curl -X POST -H 'Content-type: application/json' \
        --data "{\"text\":\"$message\"}" \
        $ALERT_SLACK_WEBHOOK
}

# 检查备份状态
/opt/jobfirst/scripts/backup-monitor.sh

# 检查是否有备份失败
if grep -q "❌" /opt/jobfirst/logs/backup-monitor.log; then
    send_alert "备份检查发现异常，请及时处理" "WARNING"
fi
```

## 📋 备份检查清单

### 配置检查
- [ ] 备份脚本配置正确
- [ ] 定时任务配置完成
- [ ] 备份目录权限正确
- [ ] 恢复脚本测试通过
- [ ] 监控告警配置完成

### 功能检查
- [ ] 数据库备份正常
- [ ] 文件备份正常
- [ ] 配置备份正常
- [ ] 备份验证通过
- [ ] 恢复测试通过

### 安全检查
- [ ] 备份文件加密存储
- [ ] 访问权限控制
- [ ] 异地备份配置
- [ ] 备份文件完整性
- [ ] 恢复权限控制

---

**配置完成时间**: 2024年9月10日  
**配置状态**: ✅ 完成  
**下一步**: 完成阶段六部署和监控
