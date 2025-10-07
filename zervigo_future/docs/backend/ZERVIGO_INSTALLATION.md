# ZerviGo - 超级管理员工具 (v3.1.1)

## 概述

ZerviGo 是一个强大的超级管理员控制工具，专为 Zervi-Basic 微服务架构设计。经过 v3.1.1 版本迭代，现已完全适配重构后的三个微服务（Template Service、Statistics Service、Banner Service），并修正了端口配置显示问题。

## 安装

### 方式一：使用安装脚本
```bash
sudo ./install.sh
```

### 方式二：手动编译安装
```bash
# 进入项目目录
cd /Users/szjason72/zervi-basic/basic/backend

# 使用构建脚本编译（推荐）
./scripts/backend/build.sh

# 或者直接编译独立版本
cd build/zervigo-standalone
go build -o ../zervigo.v3.1.1 .

# 设置执行权限
chmod +x zervigo.v3.1.1

# 移动到系统路径（可选）
sudo mv zervigo.v3.1.1 /usr/local/bin/zervigo
```

## 配置

### 配置文件位置
- **系统配置**: `/etc/superadmin/superadmin-config.json`
- **项目配置**: `/Users/szjason72/zervi-basic/basic/backend/pkg/jobfirst-core/superadmin/superadmin-config.json`

### 配置文件内容
编辑配置文件:

```json
{
  "server_ip": "101.33.251.158",
  "server_user": "ubuntu",
  "ssh_key_path": "~/.ssh/basic.pem",
  "project_dir": "/opt/jobfirst",
  "timeout": 10,
  "verbose": false,
  "services": {
    "refactored": {
      "template-service": {
        "port": 8085,
        "description": "模板管理服务 - 支持评分、搜索、统计"
      },
      "statistics-service": {
        "port": 8086,
        "description": "数据统计服务 - 系统分析和趋势监控"
      },
      "banner-service": {
        "port": 8087,
        "description": "内容管理服务 - Banner、Markdown、评论"
      }
    },
    "core": {
      "basic-server": {
        "port": 8080,
        "description": "基础服务器 - API网关"
      },
      "user-service": {
        "port": 8081,
        "description": "用户管理服务"
      },
      "company-service": {
        "port": 8083,
        "description": "公司管理服务"
      },
      "dev-team-service": {
        "port": 8088,
        "description": "开发团队管理服务"
      }
    }
  }
}
```

## 使用方法

### 基础命令

```bash
# 查看帮助信息
zervigo help

# 查看系统整体状态
zervigo status

# 查看重构后的微服务状态
zervigo services refactored

# 查看核心微服务状态
zervigo services core
```

### 重构后的微服务管理

```bash
# 查看Template Service状态
zervigo service template-service status

# 查看Statistics Service状态
zervigo service statistics-service status

# 查看Banner Service状态
zervigo service banner-service status

# 重启重构后的服务
zervigo services restart refactored

# 查看重构服务的详细日志
zervigo logs template-service
zervigo logs statistics-service
zervigo logs banner-service
```

### 基础设施管理

```bash
# 重启基础设施服务
zervigo infrastructure restart

# 查看数据库状态
zervigo database status

# 执行数据库校验
zervigo validate all
```

### 用户和权限管理

```bash
# 查看用户列表
zervigo users list

# 查看角色列表
zervigo roles list

# 检查权限
zervigo permissions check

# 设置超级管理员
zervigo super-admin setup
```

### 系统监控

```bash
# 实时监控
zervigo monitor

# 查看告警
zervigo alerts

# 查看日志
zervigo logs
```

## 功能特性

### v3.1.1 新特性
- ✅ **端口配置修正**: 修正了服务端口显示问题，现在显示正确的端口配置
- ✅ **重构服务监控**: 完全适配三个重构后的微服务
- ✅ **服务分类管理**: 按功能分类管理服务（重构、核心、基础设施）
- ✅ **增强健康检查**: 支持新的API端点和健康检查机制
- ✅ **服务版本追踪**: 监控服务版本和更新状态
- ✅ **性能指标监控**: 监控重构后服务的性能指标
- ✅ **独立编译**: 解决了Go模块导入问题，确保稳定运行

### 核心功能
- **基础设施管理**: MySQL, Redis, PostgreSQL, Nginx, Consul
- **微服务集群监控**: 14个微服务（包括3个重构服务）
- **重构服务专项管理**: Template, Statistics, Banner 服务
- **用户和角色管理**: 完整的权限控制体系
- **系统备份管理**: 自动化备份和恢复
- **实时监控和告警**: 系统状态实时监控
- **系统日志查看**: 集中化日志管理

### 重构服务专项功能
- **Template Service**: 监控模板管理、评分系统、搜索功能
- **Statistics Service**: 监控数据统计、趋势分析、性能指标
- **Banner Service**: 监控内容管理、Markdown处理、评论系统
