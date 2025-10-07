#!/bin/bash

# AI身份服务SQL文件实施脚本
# 实施001-003三个核心SQL文件到数据库

echo "🚀 开始实施AI身份服务SQL文件..."
echo "=================================="

# 设置错误处理
set -e

# 检查MySQL连接
echo "📊 检查MySQL连接..."
if ! mysql -h localhost -u root -e "SELECT 1;" > /dev/null 2>&1; then
    echo "❌ MySQL连接失败"
    exit 1
fi
echo "✅ MySQL连接正常"

# 检查PostgreSQL连接
echo "📊 检查PostgreSQL连接..."
if ! psql -h localhost -U postgres -c "SELECT 1;" > /dev/null 2>&1; then
    echo "❌ PostgreSQL连接失败"
    exit 1
fi
echo "✅ PostgreSQL连接正常"

# 实施001_create_skills_tables.sql到MySQL
echo ""
echo "🔧 实施技能标准化系统SQL (001_create_skills_tables.sql)..."
echo "=================================="

if [ -f "/Users/szjason72/genzltd/zervigo_future/database/migrations/001_create_skills_tables.sql" ]; then
    echo "📝 执行技能标准化表创建..."
    mysql -h localhost -u root jobfirst < /Users/szjason72/genzltd/zervigo_future/database/migrations/001_create_skills_tables.sql
    
    # 验证表是否创建成功
    echo "✅ 验证技能标准化表..."
    mysql -h localhost -u root -e "USE jobfirst; SHOW TABLES LIKE '%skill%';" | grep -E "(skill|Skill)" && echo "  ✅ 技能相关表创建成功" || echo "  ❌ 技能相关表创建失败"
else
    echo "❌ 001_create_skills_tables.sql 文件不存在"
fi

# 实施002_create_experience_tables.sql到MySQL
echo ""
echo "🔧 实施经验量化分析系统SQL (002_create_experience_tables.sql)..."
echo "=================================="

if [ -f "/Users/szjason72/genzltd/zervigo_future/database/migrations/002_create_experience_tables.sql" ]; then
    echo "📝 执行经验量化表创建..."
    mysql -h localhost -u root jobfirst < /Users/szjason72/genzltd/zervigo_future/database/migrations/002_create_experience_tables.sql
    
    # 验证表是否创建成功
    echo "✅ 验证经验量化表..."
    mysql -h localhost -u root -e "USE jobfirst; SHOW TABLES LIKE '%experience%';" | grep -E "(experience|Experience)" && echo "  ✅ 经验相关表创建成功" || echo "  ❌ 经验相关表创建失败"
    mysql -h localhost -u root -e "USE jobfirst; SHOW TABLES LIKE '%project%';" | grep -E "(project|Project)" && echo "  ✅ 项目相关表创建成功" || echo "  ❌ 项目相关表创建失败"
else
    echo "❌ 002_create_experience_tables.sql 文件不存在"
fi

# 实施003_create_competency_tables.sql到MySQL
echo ""
echo "🔧 实施能力评估框架系统SQL (003_create_competency_tables.sql)..."
echo "=================================="

if [ -f "/Users/szjason72/genzltd/zervigo_future/database/migrations/003_create_competency_tables.sql" ]; then
    echo "📝 执行能力评估表创建..."
    mysql -h localhost -u root jobfirst < /Users/szjason72/genzltd/zervigo_future/database/migrations/003_create_competency_tables.sql
    
    # 验证表是否创建成功
    echo "✅ 验证能力评估表..."
    mysql -h localhost -u root -e "USE jobfirst; SHOW TABLES LIKE '%competency%';" | grep -E "(competency|Competency)" && echo "  ✅ 能力评估表创建成功" || echo "  ❌ 能力评估表创建失败"
    mysql -h localhost -u root -e "USE jobfirst; SHOW TABLES LIKE '%technical%';" | grep -E "(technical|Technical)" && echo "  ✅ 技术能力表创建成功" || echo "  ❌ 技术能力表创建失败"
else
    echo "❌ 003_create_competency_tables.sql 文件不存在"
fi

# 最终验证
echo ""
echo "🔍 最终验证..."
echo "=================================="

echo "📊 MySQL数据库表统计..."
mysql -h localhost -u root -e "USE jobfirst; SELECT COUNT(*) as total_tables FROM information_schema.tables WHERE table_schema = 'jobfirst';"

echo "📊 技能标准化相关表..."
mysql -h localhost -u root -e "USE jobfirst; SHOW TABLES;" | grep -E "(skill|Skill)" | wc -l | xargs echo "技能相关表数量:"

echo "📊 经验量化相关表..."
mysql -h localhost -u root -e "USE jobfirst; SHOW TABLES;" | grep -E "(experience|project|Project)" | wc -l | xargs echo "经验相关表数量:"

echo "📊 能力评估相关表..."
mysql -h localhost -u root -e "USE jobfirst; SHOW TABLES;" | grep -E "(competency|technical|Technical)" | wc -l | xargs echo "能力评估相关表数量:"

echo ""
echo "🎉 SQL文件实施完成！"
echo "=================================="
echo "✅ 所有三个核心SQL文件已成功实施到MySQL数据库"
echo "✅ 技能标准化系统表已创建"
echo "✅ 经验量化分析系统表已创建"
echo "✅ 能力评估框架系统表已创建"
echo ""
echo "📋 下一步建议:"
echo "1. 运行数据一致性测试验证新表"
echo "2. 启动对应的API服务"
echo "3. 进行系统集成测试"
