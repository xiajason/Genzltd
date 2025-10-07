#!/bin/bash

# 备份脚本
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/opt/production/backup"
LOG_FILE="/opt/production/logs/backup.log"

echo "$(date): 开始备份..." >> $LOG_FILE

# 创建备份目录
mkdir -p $BACKUP_DIR/$DATE

# 备份数据库
mysqldump -h rds-host -u user -p database > $BACKUP_DIR/$DATE/database.sql

# 备份应用数据
tar -czf $BACKUP_DIR/$DATE/app-data.tar.gz /opt/production/data/

# 备份配置文件
tar -czf $BACKUP_DIR/$DATE/config.tar.gz /opt/production/config/

# 清理旧备份（保留7天）
find $BACKUP_DIR -type d -mtime +7 -exec rm -rf {} \;

echo "$(date): 备份完成" >> $LOG_FILE
