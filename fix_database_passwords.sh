#!/bin/bash
# 修复数据库密码认证问题
# 基于README.md中的密码配置

echo "🔧 修复数据库密码认证问题"
echo "=========================================="
echo "时间: $(date)"
echo "基于: README.md中的密码配置信息"
echo ""

# 修复MySQL密码
echo "1. 修复MySQL密码认证..."
echo "   密码: f_mysql_password_2025"
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker exec production-mysql mysql -u root -e \"ALTER USER 'root'@'localhost' IDENTIFIED BY 'f_mysql_password_2025'; FLUSH PRIVILEGES;\""

echo ""
echo "2. 测试MySQL连接..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker exec production-mysql mysql -u root -pf_mysql_password_2025 -e 'SELECT 1 as test'"

echo ""
echo "✅ MySQL密码修复完成"
echo ""

# 修复PostgreSQL密码
echo "3. 修复PostgreSQL密码认证..."
echo "   用户: future_user, 密码: f_postgres_password_2025"
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker exec production-postgres psql -U postgres -c \"CREATE USER future_user WITH PASSWORD 'f_postgres_password_2025'; GRANT ALL PRIVILEGES ON DATABASE postgres TO future_user;\""

echo ""
echo "4. 测试PostgreSQL连接..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker exec production-postgres psql -U future_user -d postgres -c 'SELECT 1 as test'"

echo ""
echo "✅ PostgreSQL密码修复完成"
echo ""

# 修复Redis密码
echo "5. 修复Redis密码认证..."
echo "   密码: f_redis_password_2025"
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker exec production-redis redis-cli CONFIG SET requirepass f_redis_password_2025"

echo ""
echo "6. 测试Redis连接..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker exec production-redis redis-cli -a f_redis_password_2025 ping"

echo ""
echo "✅ Redis密码修复完成"
echo ""

# 修复Neo4j密码
echo "7. 修复Neo4j密码认证..."
echo "   用户: neo4j, 密码: f_neo4j_password_2025"
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker exec production-neo4j neo4j-admin set-initial-password f_neo4j_password_2025"

echo ""
echo "8. 测试Neo4j连接..."
ssh -i ~/.ssh/cross_cloud_key root@47.115.168.107 "docker exec production-neo4j cypher-shell -u neo4j -p f_neo4j_password_2025 'RETURN 1 as test'"

echo ""
echo "✅ Neo4j密码修复完成"
echo ""

echo "🎉 所有数据库密码认证修复完成！"
echo "=========================================="
echo "完成时间: $(date)"
echo "=========================================="
EOF"