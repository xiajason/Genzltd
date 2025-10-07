#!/bin/bash

# SQL文件实施检查脚本
# 检查001-003三个核心SQL文件是否已在数据库中实施

echo "🔍 检查SQL文件实施状态..."
echo "=================================="

# 检查MySQL数据库
echo "📊 检查MySQL数据库 (jobfirst)..."
mysql -h localhost -u root -e "USE jobfirst; SHOW TABLES;" 2>/dev/null | grep -E "(skill|experience|competency)" | while read table; do
    echo "  ✅ 找到表: $table"
done

# 检查PostgreSQL数据库
echo "📊 检查PostgreSQL数据库 (jobfirst_vector)..."
psql -h localhost -U postgres -d jobfirst_vector -c "\dt" 2>/dev/null | grep -E "(skill|experience|competency)" | while read table; do
    echo "  ✅ 找到表: $table"
done

echo ""
echo "🔍 检查SQL文件存在性..."
echo "=================================="

# 检查三个核心SQL文件
for file in "001_create_skills_tables.sql" "002_create_experience_tables.sql" "003_create_competency_tables.sql"; do
    if [ -f "/Users/szjason72/genzltd/zervigo_future/database/migrations/$file" ]; then
        echo "  ✅ $file 存在"
        # 显示文件大小
        size=$(wc -c < "/Users/szjason72/genzltd/zervigo_future/database/migrations/$file")
        echo "     文件大小: $size 字节"
    else
        echo "  ❌ $file 不存在"
    fi
done

echo ""
echo "🔍 检查数据一致性影响..."
echo "=================================="

# 检查是否有相关的API服务在运行
echo "📡 检查API服务状态..."
for port in 8201 8202 8203; do
    if curl -s "http://localhost:$port/health" > /dev/null 2>&1; then
        echo "  ✅ 端口 $port 服务正常"
    else
        echo "  ❌ 端口 $port 服务异常"
    fi
done

echo ""
echo "📋 总结..."
echo "=================================="
echo "1. 三个核心SQL文件已创建但可能未实施到数据库"
echo "2. 需要运行SQL文件来创建对应的数据表"
echo "3. 这可能会影响数据一致性测试的结果"
echo "4. 建议先实施SQL文件，再进行数据一致性测试"
