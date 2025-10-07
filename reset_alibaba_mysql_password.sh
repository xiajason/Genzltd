#!/bin/bash
echo "=== 重置阿里云MySQL密码 ==="
systemctl stop mysqld
mysqld_safe --skip-grant-tables --skip-networking &
sleep 5
mysql -u root -e "USE mysql; UPDATE user SET authentication_string=PASSWORD('test_mysql_password') WHERE User='root'; FLUSH PRIVILEGES;"
echo "MySQL密码重置完成"
pkill mysqld
systemctl start mysqld
sleep 3
echo "测试新密码连接:"
mysql -u root -ptest_mysql_password -e "SELECT VERSION();" 2>/dev/null && echo "阿里云MySQL密码重置成功" || echo "密码重置失败"
