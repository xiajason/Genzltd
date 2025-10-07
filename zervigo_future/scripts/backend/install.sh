#!/bin/bash

# 超级管理员工具安装脚本

set -e

INSTALL_DIR="/usr/local/bin"
CONFIG_DIR="/etc/superadmin"

echo "安装超级管理员工具..."

# 创建配置目录
sudo mkdir -p $CONFIG_DIR

# 复制二进制文件
sudo cp zervigo $INSTALL_DIR/
sudo chmod +x $INSTALL_DIR/zervigo

# 复制配置文件
sudo cp superadmin-config.json $CONFIG_DIR/

echo "安装完成！"
echo "使用方法: zervigo --help"
