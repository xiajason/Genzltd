#!/bin/bash

# 用户SQLite数据库创建脚本
# 用途：为指定用户创建独立的SQLite数据库
# 创建时间：2025-09-13

set -e

# 检查参数
if [ $# -eq 0 ]; then
    echo "用法: $0 <user_id> [user_id2] [user_id3] ..."
    echo "示例: $0 4"
    echo "示例: $0 4 5 6"
    exit 1
fi

# 设置基础路径
BASE_DIR="data/users"
SCHEMA_FILE="database/migrations/create_sqlite_architecture.sql"

echo "🔄 开始创建用户SQLite数据库..."

# 检查架构文件是否存在
if [ ! -f "$SCHEMA_FILE" ]; then
    echo "❌ 架构文件不存在: $SCHEMA_FILE"
    exit 1
fi

# 为每个用户创建数据库
for USER_ID in "$@"; do
    echo "📊 为用户 $USER_ID 创建SQLite数据库..."
    
    # 创建用户目录
    USER_DIR="$BASE_DIR/$USER_ID"
    mkdir -p "$USER_DIR"
    
    # 数据库文件路径
    DB_FILE="$USER_DIR/resume.db"
    
    # 检查数据库是否已存在
    if [ -f "$DB_FILE" ]; then
        echo "⚠️  数据库已存在: $DB_FILE"
        read -p "是否覆盖现有数据库？(y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "⏭️  跳过用户 $USER_ID"
            continue
        fi
        rm -f "$DB_FILE"
    fi
    
    # 创建数据库并执行架构脚本
    echo "📝 执行架构脚本..."
    sqlite3 "$DB_FILE" < "$SCHEMA_FILE"
    
    # 验证数据库创建
    if [ -f "$DB_FILE" ]; then
        # 检查表是否创建成功
        TABLE_COUNT=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM sqlite_master WHERE type='table';")
        echo "✅ 用户 $USER_ID 数据库创建成功"
        echo "   📁 路径: $DB_FILE"
        echo "   📊 表数量: $TABLE_COUNT"
        
        # 显示创建的表
        echo "   📋 创建的表:"
        sqlite3 "$DB_FILE" "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;" | while read table; do
            echo "      - $table"
        done
    else
        echo "❌ 用户 $USER_ID 数据库创建失败"
        exit 1
    fi
    
    echo ""
done

echo "✅ 所有用户SQLite数据库创建完成！"
echo "📁 数据库位置: $BASE_DIR/"
echo "🎯 下一步: 执行数据迁移脚本"
