#!/bin/bash

# 简历存储架构测试脚本
# 用途：验证新架构的数据分离存储功能
# 创建时间：2025-09-13

set -e

echo "🚀 开始测试简历存储架构..."

# 设置测试参数
USER_ID=4
TEST_TITLE="测试简历 - 新架构验证"
TEST_CONTENT="# 测试简历\n\n## 个人信息\n- 姓名：张三\n- 邮箱：zhangsan@example.com\n\n## 工作经历\n- 公司A：软件工程师 (2020-2023)\n- 公司B：高级工程师 (2023-至今)"

echo "📊 测试用户ID: $USER_ID"
echo "📝 测试标题: $TEST_TITLE"

# ==============================================
# 第一步：验证MySQL元数据存储
# ==============================================

echo ""
echo "🔍 第一步：验证MySQL元数据存储"

# 检查resume_metadata表是否存在
echo "检查resume_metadata表..."
mysql -u root jobfirst -e "DESCRIBE resume_metadata;" > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ resume_metadata表存在"
else
    echo "❌ resume_metadata表不存在"
    exit 1
fi

# 检查表结构
echo "检查表结构..."
mysql -u root jobfirst -e "SELECT COUNT(*) as field_count FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'resume_metadata' AND TABLE_SCHEMA = 'jobfirst';"
mysql -u root jobfirst -e "SELECT COLUMN_NAME, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'resume_metadata' AND TABLE_SCHEMA = 'jobfirst' ORDER BY ORDINAL_POSITION;"

# ==============================================
# 第二步：验证SQLite内容存储
# ==============================================

echo ""
echo "🔍 第二步：验证SQLite内容存储"

# 检查用户SQLite数据库是否存在
SQLITE_DB="data/users/$USER_ID/resume.db"
if [ -f "$SQLITE_DB" ]; then
    echo "✅ 用户SQLite数据库存在: $SQLITE_DB"
else
    echo "❌ 用户SQLite数据库不存在: $SQLITE_DB"
    exit 1
fi

# 检查SQLite表结构
echo "检查SQLite表结构..."
sqlite3 "$SQLITE_DB" ".tables"

# 检查关键表是否存在
echo "检查关键表..."
for table in resume_content user_privacy_settings resume_versions parsed_resume_data; do
    if sqlite3 "$SQLITE_DB" "SELECT name FROM sqlite_master WHERE type='table' AND name='$table';" | grep -q "$table"; then
        echo "✅ $table 表存在"
    else
        echo "❌ $table 表不存在"
        exit 1
    fi
done

# ==============================================
# 第三步：验证数据分离存储
# ==============================================

echo ""
echo "🔍 第三步：验证数据分离存储"

# 检查MySQL中是否没有content字段
echo "检查MySQL中的字段..."
CONTENT_FIELD=$(mysql -u root jobfirst -e "SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'resume_metadata' AND COLUMN_NAME = 'content' AND TABLE_SCHEMA = 'jobfirst';" -s -N)
if [ "$CONTENT_FIELD" -eq 0 ]; then
    echo "✅ MySQL中没有content字段（符合设计原则）"
else
    echo "❌ MySQL中存在content字段（违反设计原则）"
    exit 1
fi

# 检查SQLite中是否有content字段
echo "检查SQLite中的字段..."
if sqlite3 "$SQLITE_DB" "PRAGMA table_info(resume_content);" | grep -q "content"; then
    echo "✅ SQLite中有content字段（符合设计原则）"
else
    echo "❌ SQLite中没有content字段（违反设计原则）"
    exit 1
fi

# ==============================================
# 第四步：模拟数据插入测试
# ==============================================

echo ""
echo "🔍 第四步：模拟数据插入测试"

# 在MySQL中插入测试元数据
echo "在MySQL中插入测试元数据..."
mysql -u root jobfirst -e "
INSERT INTO resume_metadata (
    user_id, file_id, title, creation_mode, status, is_public, view_count, 
    parsing_status, sqlite_db_path, created_at, updated_at
) VALUES (
    $USER_ID, NULL, '$TEST_TITLE', 'markdown', 'draft', FALSE, 0, 
    'completed', '$SQLITE_DB', NOW(), NOW()
);
"

# 获取插入的记录ID
METADATA_ID=$(mysql -u root jobfirst -e "SELECT id FROM resume_metadata WHERE title = '$TEST_TITLE' ORDER BY id DESC LIMIT 1;" -s -N)
echo "插入的元数据ID: $METADATA_ID"

# 在SQLite中插入测试内容
echo "在SQLite中插入测试内容..."
sqlite3 "$SQLITE_DB" "
INSERT INTO resume_content (
    resume_metadata_id, title, content, content_hash, created_at, updated_at
) VALUES (
    $METADATA_ID, '$TEST_TITLE', '$TEST_CONTENT', 'test_hash_$(date +%s)', 
    datetime('now'), datetime('now')
);
"

# 获取插入的内容ID
CONTENT_ID=$(sqlite3 "$SQLITE_DB" "SELECT id FROM resume_content WHERE resume_metadata_id = $METADATA_ID;")
echo "插入的内容ID: $CONTENT_ID"

# ==============================================
# 第五步：验证数据一致性
# ==============================================

echo ""
echo "🔍 第五步：验证数据一致性"

# 验证MySQL中的数据
echo "验证MySQL中的元数据..."
mysql -u root jobfirst -e "SELECT id, user_id, title, creation_mode, status FROM resume_metadata WHERE id = $METADATA_ID;"

# 验证SQLite中的数据
echo "验证SQLite中的内容..."
sqlite3 "$SQLITE_DB" "SELECT id, resume_metadata_id, title, length(content) as content_length FROM resume_content WHERE resume_metadata_id = $METADATA_ID;"

# 验证数据关联
echo "验证数据关联..."
MYSQL_TITLE=$(mysql -u root jobfirst -e "SELECT title FROM resume_metadata WHERE id = $METADATA_ID;" -s -N)
SQLITE_TITLE=$(sqlite3 "$SQLITE_DB" "SELECT title FROM resume_content WHERE resume_metadata_id = $METADATA_ID;")

if [ "$MYSQL_TITLE" = "$SQLITE_TITLE" ]; then
    echo "✅ 数据关联正确：标题一致"
else
    echo "❌ 数据关联错误：标题不一致"
    echo "MySQL标题: $MYSQL_TITLE"
    echo "SQLite标题: $SQLITE_TITLE"
    exit 1
fi

# ==============================================
# 第六步：清理测试数据
# ==============================================

echo ""
echo "🔍 第六步：清理测试数据"

# 删除SQLite中的测试数据
echo "删除SQLite中的测试数据..."
sqlite3 "$SQLITE_DB" "DELETE FROM resume_content WHERE resume_metadata_id = $METADATA_ID;"

# 删除MySQL中的测试数据
echo "删除MySQL中的测试数据..."
mysql -u root jobfirst -e "DELETE FROM resume_metadata WHERE id = $METADATA_ID;"

echo "✅ 测试数据清理完成"

# ==============================================
# 测试结果总结
# ==============================================

echo ""
echo "🎉 简历存储架构测试完成！"
echo ""
echo "📊 测试结果总结："
echo "✅ MySQL元数据存储：正常"
echo "✅ SQLite内容存储：正常"
echo "✅ 数据分离架构：符合设计原则"
echo "✅ 数据一致性：正常"
echo "✅ 数据关联：正常"
echo ""
echo "🎯 新架构验证成功！"
echo "📁 MySQL存储：元数据（用户ID、标题、状态、统计等）"
echo "📁 SQLite存储：内容（简历内容、解析结果、隐私设置等）"
echo ""
echo "🚀 下一步：可以开始使用新架构进行开发"
