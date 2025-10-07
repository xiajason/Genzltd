#!/bin/bash

# 调试统一认证服务数据库连接问题

echo "=== 调试统一认证服务数据库连接 ==="

# 1. 检查统一认证服务是否创建了自己的表
echo "1. 检查数据库表结构..."
mysql -u root -p -e "USE jobfirst; SHOW TABLES;" 2>/dev/null | grep -E "(users|permissions|role_permissions|access_logs)"

# 2. 检查用户数据
echo -e "\n2. 检查用户数据..."
mysql -u root -p -e "USE jobfirst; SELECT id, username, email, role, status FROM users WHERE id = 4;" 2>/dev/null

# 3. 检查统一认证服务期望的查询
echo -e "\n3. 测试统一认证服务期望的查询..."
mysql -u root -p -e "USE jobfirst; SELECT id, username, email, password_hash, role, status, subscription_type, subscription_expiry, last_login, created_at, updated_at FROM users WHERE id = 4 AND status = 'active';" 2>/dev/null

# 4. 检查是否有重复的users表
echo -e "\n4. 检查是否有重复的users表..."
mysql -u root -p -e "USE jobfirst; SELECT TABLE_NAME FROM information_schema.TABLES WHERE TABLE_SCHEMA = 'jobfirst' AND TABLE_NAME LIKE '%users%';" 2>/dev/null

# 5. 检查统一认证服务是否使用了不同的数据库
echo -e "\n5. 检查统一认证服务的数据库连接..."
echo "统一认证服务使用的数据库URL: root:@tcp(localhost:3306)/jobfirst?charset=utf8mb4&parseTime=True&loc=Local"

# 6. 测试JWT token解析
echo -e "\n6. 测试JWT token解析..."
TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjo0LCJ1c2VybmFtZSI6InN6amFzb243MiIsImVtYWlsIjoiMzQ3Mzk5QHFxLmNvbSIsInJvbGUiOiJndWVzdCIsImxldmVsIjoxLCJwZXJtaXNzaW9ucyI6WyJyZWFkOnB1YmxpYyJdLCJpc3MiOiJqb2JmaXJzdC1hdXRoIiwic3ViIjoiNCIsImV4cCI6MTc1ODgwMjcxOCwibmJmIjoxNzU4MTk3OTE4LCJpYXQiOjE3NTgxOTc5MTh9._lK3kqQjCrBJzNGldP2zm1_R44xAykVOlVYeUDt6SRw"

# 解码JWT token的payload部分
PAYLOAD=$(echo $TOKEN | cut -d'.' -f2)
# 添加padding如果需要
PADDING_LENGTH=$((4 - ${#PAYLOAD} % 4))
if [ $PADDING_LENGTH -ne 4 ]; then
    PAYLOAD="${PAYLOAD}$(printf '%*s' $PADDING_LENGTH | tr ' ' '=')"
fi

echo "JWT Token Payload:"
echo $PAYLOAD | base64 -d 2>/dev/null | jq . 2>/dev/null || echo "无法解析JWT payload"

echo -e "\n=== 调试完成 ==="
