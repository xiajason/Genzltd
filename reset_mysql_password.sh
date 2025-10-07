#!/bin/bash
echo "=== 重置MySQL密码为f_mysql_password_2025 ==="

# 停止MySQL服务
systemctl stop mysqld

# 启动MySQL安全模式
mysqld_safe --skip-grant-tables --skip-networking &
sleep 5

# 重置密码
mysql -u root << 'MYSQL_EOF'
USE mysql;
UPDATE user SET authentication_string=PASSWORD('f_mysql_password_2025') WHERE User='root';
FLUSH PRIVILEGES;
MYSQL_EOF

echo "MySQL密码重置完成"

# 重启MySQL服务
pkill mysqld
systemctl start mysqld
sleep 3

# 测试新密码
echo "测试新密码:"
mysql -u root -pf_mysql_password_2025 -e "SHOW DATABASES;" 2>/dev/null
if [ $? -eq 0 ]; then
    echo "MySQL密码重置成功"
else
    echo "MySQL密码重置失败"
fi
