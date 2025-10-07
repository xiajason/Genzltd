#!/bin/bash

# JobFirst 数据库统一迁移执行脚本
# 执行前请确保已备份所有数据

set -e  # 遇到错误立即退出

echo "=== JobFirst 数据库统一迁移开始 ==="
echo "时间: $(date)"
echo ""

# 检查MySQL连接
echo "1. 检查MySQL连接..."
mysql -u root -e "SELECT 'MySQL connection successful' as status;" || {
    echo "错误: 无法连接到MySQL"
    exit 1
}

# 检查数据库是否存在
echo "2. 检查数据库是否存在..."
mysql -u root -e "SHOW DATABASES LIKE 'jobfirst';" | grep -q jobfirst || {
    echo "错误: jobfirst 数据库不存在"
    exit 1
}

mysql -u root -e "SHOW DATABASES LIKE 'jobfirst_v3';" | grep -q jobfirst_v3 || {
    echo "错误: jobfirst_v3 数据库不存在"
    exit 1
}

echo "✅ 数据库检查通过"
echo ""

# 执行第一步：创建表结构
echo "3. 执行第一步：创建统一表结构..."
mysql -u root < database_migration_step1_create_tables.sql
if [ $? -eq 0 ]; then
    echo "✅ 第一步完成：表结构创建成功"
else
    echo "❌ 第一步失败：表结构创建失败"
    exit 1
fi
echo ""

# 执行第二步：数据迁移
echo "4. 执行第二步：数据迁移..."
mysql -u root < database_migration_step2_migrate_data.sql
if [ $? -eq 0 ]; then
    echo "✅ 第二步完成：数据迁移成功"
else
    echo "❌ 第二步失败：数据迁移失败"
    exit 1
fi
echo ""

# 执行第三步：完成迁移
echo "5. 执行第三步：完成迁移..."
mysql -u root < database_migration_step3_finalize.sql
if [ $? -eq 0 ]; then
    echo "✅ 第三步完成：迁移完成"
else
    echo "❌ 第三步失败：迁移完成失败"
    exit 1
fi
echo ""

# 最终验证
echo "6. 最终验证..."
echo "=== 迁移结果验证 ==="
mysql -u root jobfirst -e "
SELECT 'Migration Summary' as info;
SELECT COUNT(*) as total_users FROM users;
SELECT COUNT(*) as total_sessions FROM user_sessions;
SELECT COUNT(*) as total_configs FROM system_configs;
SELECT COUNT(*) as total_logs FROM operation_logs;
SELECT COUNT(*) as total_business_tables FROM information_schema.tables 
    WHERE table_schema = 'jobfirst' 
    AND table_name NOT IN ('users', 'user_sessions', 'system_configs', 'operation_logs')
    AND table_name NOT LIKE '%_backup_%';
"

echo ""
echo "=== JobFirst 数据库统一迁移完成 ==="
echo "时间: $(date)"
echo ""
echo "注意事项："
echo "1. 原表已备份为 *_backup_* 格式"
echo "2. 请验证所有微服务配置是否正常"
echo "3. 建议进行全面的功能测试"
echo "4. 确认无误后可删除备份表"
