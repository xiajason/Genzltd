#!/bin/bash

echo "🚀 Future版数据库初始化优化脚本"
echo "=========================================="

# 1. MySQL数据库初始化
echo "📊 初始化MySQL数据库..."
mysql -h 127.0.0.1 -P 3306 -u root -pf_mysql_root_2025 -e "
CREATE DATABASE IF NOT EXISTS future_users;
USE future_users;
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50),
    email VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
"

# 2. PostgreSQL数据库初始化
echo "📊 初始化PostgreSQL数据库..."
PGPASSWORD=f_postgres_password_2025 psql -h 127.0.0.1 -p 5432 -U future_user -d f_pg -c "
CREATE TABLE IF NOT EXISTS future_users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50),
    email VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
"

# 3. Redis数据库初始化
echo "📊 初始化Redis数据库..."
docker exec future-redis redis-cli CONFIG SET requirepass 'f_redis_password_2025'
docker exec future-redis redis-cli -a 'f_redis_password_2025' set 'future:init' 'completed'

# 4. Neo4j数据库初始化
echo "📊 初始化Neo4j数据库..."
curl -u neo4j:password -X POST http://127.0.0.1:7474/db/data/transaction/commit -H 'Content-Type: application/json' -d '{
  "statements": [{
    "statement": "CREATE (n:FutureUser {username: \"test\", email: \"test@example.com\"}) RETURN n"
  }]
}'

# 5. Elasticsearch数据库初始化
echo "📊 初始化Elasticsearch数据库..."
curl -X PUT "http://127.0.0.1:9200/future_users" -H 'Content-Type: application/json' -d '{
  "mappings": {
    "properties": {
      "username": { "type": "text" },
      "email": { "type": "text" },
      "created_at": { "type": "date" }
    }
  }
}'

# 6. Weaviate数据库初始化
echo "📊 初始化Weaviate数据库..."
curl -X POST http://127.0.0.1:8080/v1/schema -H 'Content-Type: application/json' -d '{
  "class": "FutureUser",
  "description": "Future version user class",
  "properties": [
    {
      "name": "username",
      "dataType": ["text"],
      "description": "User username"
    },
    {
      "name": "email",
      "dataType": ["text"],
      "description": "User email"
    }
  ]
}'

echo "✅ Future版数据库初始化完成！"
