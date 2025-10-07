#!/bin/bash
# DAO Genie 数据库初始化脚本

echo "=== DAO Genie 数据库初始化 ==="

# 检查PostgreSQL是否运行
if ! pg_isready -h localhost -p 9508 >/dev/null 2>&1; then
    echo "❌ PostgreSQL未运行在端口9508"
    echo "请先启动PostgreSQL服务"
    exit 1
fi

# 创建数据库
echo "📊 创建dao_genie数据库..."
createdb -h localhost -p 9508 -U postgres dao_genie 2>/dev/null || echo "数据库可能已存在"

# 运行Prisma迁移
echo "🔄 运行Prisma数据库迁移..."
npx prisma migrate dev --name init

# 生成Prisma客户端
echo "🔧 生成Prisma客户端..."
npx prisma generate

echo "✅ 数据库初始化完成！"
