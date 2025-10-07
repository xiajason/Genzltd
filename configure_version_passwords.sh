#!/bin/bash
echo "=== 配置阿里云数据库版本化密码 ==="

# 配置MySQL密码为Future版本
echo "=== 配置MySQL密码为f_mysql_password_2025 ==="
systemctl stop mysqld
mysqld_safe --skip-grant-tables --skip-networking &
sleep 5
mysql -u root -e "USE mysql; UPDATE user SET authentication_string=PASSWORD('f_mysql_password_2025') WHERE User='root'; FLUSH PRIVILEGES;"
echo "MySQL密码重置完成"
pkill mysqld
systemctl start mysqld
sleep 3
echo "测试新密码:"
mysql -u root -pf_mysql_password_2025 -e "SHOW DATABASES;" && echo "MySQL密码重置成功" || echo "MySQL密码重置失败"

# 配置PostgreSQL密码为Future版本
echo "=== 配置PostgreSQL密码为f_postgres_password_2025 ==="
sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'f_postgres_password_2025';"
sudo -u postgres psql -c "ALTER USER test_user PASSWORD 'f_postgres_password_2025';"
echo "PostgreSQL密码配置完成"

# 配置Redis密码为Future版本
echo "=== 配置Redis密码为f_redis_password_2025 ==="
redis-cli CONFIG SET requirepass f_redis_password_2025
echo "Redis密码配置完成"

# 配置Neo4j密码为Future版本
echo "=== 配置Neo4j密码为f_neo4j_password_2025 ==="
# Neo4j密码需要通过Docker容器配置
docker exec production-neo4j cypher-shell -u neo4j -p test_neo4j_password "CALL dbms.security.changePassword('f_neo4j_password_2025');"
echo "Neo4j密码配置完成"

echo "=== 版本化密码配置完成 ==="
