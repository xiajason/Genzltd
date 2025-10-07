#!/bin/bash

# 超级管理员工具构建脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=============================================================================${NC}"
echo -e "${BLUE}                    超级管理员工具构建${NC}"
echo -e "${BLUE}=============================================================================${NC}"

# 检查Go环境
if ! command -v go &> /dev/null; then
    echo -e "${RED}错误: Go未安装或不在PATH中${NC}"
    exit 1
fi

echo -e "${YELLOW}Go版本:${NC}"
go version

# 设置构建参数
BUILD_DIR="build"
BINARY_NAME="zervigo"
VERSION=$(date +%Y%m%d-%H%M%S)

# 创建构建目录
mkdir -p $BUILD_DIR

echo -e "\n${YELLOW}开始构建...${NC}"

# 构建二进制文件
echo -e "${BLUE}构建二进制文件...${NC}"
# 检测操作系统
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    CGO_ENABLED=0 go build -ldflags="-s -w -X main.version=$VERSION" -o $BUILD_DIR/$BINARY_NAME ./cmd/zervigo
else
    # Linux
    CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-s -w -X main.version=$VERSION" -o $BUILD_DIR/$BINARY_NAME ./cmd/zervigo
fi

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ 构建成功${NC}"
else
    echo -e "${RED}✗ 构建失败${NC}"
    exit 1
fi

# 复制配置文件
echo -e "${BLUE}复制配置文件...${NC}"
cp superadmin-config.json $BUILD_DIR/

# 创建安装脚本
echo -e "${BLUE}创建安装脚本...${NC}"
cat > $BUILD_DIR/install.sh << 'EOF'
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
EOF

chmod +x $BUILD_DIR/install.sh

# 创建使用说明
echo -e "${BLUE}创建使用说明...${NC}"
cat > $BUILD_DIR/README.md << 'EOF'
# ZerviGo - 超级管理员工具

## 安装

```bash
sudo ./install.sh
```

## 配置

编辑配置文件 `/etc/superadmin/superadmin-config.json`:

```json
{
  "server_ip": "101.33.251.158",
  "server_user": "ubuntu",
  "ssh_key_path": "~/.ssh/basic.pem",
  "project_dir": "/opt/jobfirst",
  "timeout": 10,
  "verbose": false
}
```

## 使用方法

```bash
# 查看系统整体状态
zervigo status

# 重启基础设施服务
zervigo infrastructure restart

# 查看用户列表
zervigo users list

# 查看角色列表
zervigo roles list

# 检查权限
zervigo permissions check

# 实时监控
zervigo monitor

# 查看告警
zervigo alerts

# 查看日志
zervigo logs
```

## 功能特性

- 基础设施管理 (MySQL, Redis, PostgreSQL, Nginx, Consul)
- 微服务集群监控 (9个微服务)
- 用户和角色管理
- 权限和访问控制
- 系统备份管理
- 实时监控和告警
- 系统日志查看
EOF

# 显示构建结果
echo -e "\n${GREEN}=============================================================================${NC}"
echo -e "${GREEN}                        构建完成${NC}"
echo -e "${GREEN}=============================================================================${NC}"

echo -e "${YELLOW}构建文件:${NC}"
ls -la $BUILD_DIR/

echo -e "\n${YELLOW}安装方法:${NC}"
echo "cd $BUILD_DIR && sudo ./install.sh"

echo -e "\n${YELLOW}使用方法:${NC}"
echo "zervigo --help"

echo -e "\n${GREEN}构建完成！${NC}"
