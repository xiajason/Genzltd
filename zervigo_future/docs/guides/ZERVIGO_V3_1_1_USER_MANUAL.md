# ZerviGo v3.1.1 使用手册

**版本**: v3.1.1  
**更新日期**: 2025-09-12  
**状态**: ✅ 已发布

## 📋 目录

1. [概述](#概述)
2. [安装指南](#安装指南)
3. [快速开始](#快速开始)
4. [基础命令](#基础命令)
5. [服务管理](#服务管理)
6. [系统监控](#系统监控)
7. [故障排除](#故障排除)
8. [高级功能](#高级功能)
9. [配置参考](#配置参考)
10. [更新日志](#更新日志)

## 🎯 概述

ZerviGo v3.1.1 是 Zervi-Basic 微服务架构的超级管理员控制工具，经过重大更新，现在提供：

- ✅ **正确的端口配置**: 修正了服务端口显示问题
- ✅ **完整的服务监控**: 支持 8080-8088 端口范围的所有服务
- ✅ **重构服务支持**: 专门适配三个重构后的微服务
- ✅ **独立编译**: 解决了Go模块导入问题
- ✅ **实时监控**: 提供系统健康状态实时监控

### 支持的服务

#### 重构后的微服务 (v3.1.1)
- **Template Service** (端口: 8085) - 模板管理服务
- **Statistics Service** (端口: 8086) - 数据统计服务  
- **Banner Service** (端口: 8087) - 内容管理服务

#### 核心微服务
- **API Gateway** (端口: 8080) - 基础服务器
- **User Service** (端口: 8081) - 用户管理服务
- **Resume Service** (端口: 8082) - 简历管理服务
- **Company Service** (端口: 8083) - 公司管理服务
- **Notification Service** (端口: 8084) - 通知服务
- **Dev Team Service** (端口: 8088) - 开发团队管理服务

#### 基础设施服务
- **MySQL** (端口: 3306) - 数据库服务
- **Redis** (端口: 6379) - 缓存服务
- **PostgreSQL** (端口: 5432) - 数据库服务
- **Consul** (端口: 8500) - 服务发现
- **Nginx** (端口: 80) - 反向代理
- **AI Service** (端口: 8206) - AI服务

## 🚀 安装指南

### 前提条件

- macOS/Linux 系统
- Go 1.19+ (如果从源码编译)
- 网络访问权限

### 安装方式

#### 方式一：使用预编译版本（推荐）

```bash
# 下载并设置权限
chmod +x backend/pkg/jobfirst-core/superadmin/zervigo

# 测试运行
./backend/pkg/jobfirst-core/superadmin/zervigo
```

#### 方式二：从源码编译

```bash
# 进入项目目录
cd /Users/szjason72/zervi-basic/basic/backend

# 编译独立版本
cd build/zervigo-standalone
go build -o ../zervigo.v3.1.1 .

# 设置权限
chmod +x ../zervigo.v3.1.1
```

## ⚡ 快速开始

### 1. 基本系统状态检查

```bash
# 查看系统整体状态
./backend/pkg/jobfirst-core/superadmin/zervigo
```

**预期输出**:
```
🔍 获取系统整体状态...
🕐 时间: 2025-09-12 06:27:25
🏥 健康状态: warning (80.0%)
📊 运行服务: 12/15

🔧 基础设施服务:
  ✅ mysql (端口:3306) - active
  ✅ redis (端口:6379) - active
  ❌ consul (端口:8500) - error
  ❌ nginx (端口:80) - error
  ✅ postgresql (端口:5432) - active

⚙️ 微服务集群:
  ✅ template_service (端口:8085) - active
  ✅ statistics_service (端口:8086) - active
  ✅ banner_service (端口:8087) - active
  ✅ api_gateway (端口:8080) - active
  ✅ resume_service (端口:8082) - active
  ✅ company_service (端口:8083) - active
  ✅ notification_service (端口:8084) - active
  ✅ dev_team_service (端口:8088) - active
  ✅ ai_service (端口:8206) - active
```

### 2. 验证端口配置

ZerviGo v3.1.1 现在显示正确的端口配置：

- ✅ **Template Service**: 端口 8085 (之前错误显示为 8087)
- ✅ **Statistics Service**: 端口 8086 (保持正确)
- ✅ **Banner Service**: 端口 8087 (之前错误显示为 8085)

## 🔧 基础命令

### 系统状态监控

```bash
# 查看完整系统状态
./backend/pkg/jobfirst-core/superadmin/zervigo

# 检查特定服务健康状态
curl http://localhost:8085/health  # Template Service
curl http://localhost:8086/health  # Statistics Service  
curl http://localhost:8087/health  # Banner Service
```

### 服务健康检查

```bash
# 检查重构后的微服务
curl -s http://localhost:8085/health | jq '.service'  # Template Service
curl -s http://localhost:8086/health | jq '.service'  # Statistics Service
curl -s http://localhost:8087/health | jq '.service'  # Banner Service
```

## 🎛️ 服务管理

### 重构后的微服务管理

#### Template Service (端口: 8085)

```bash
# 健康检查
curl http://localhost:8085/health

# 获取模板分类
curl http://localhost:8085/api/v1/template/public/categories

# 获取模板列表
curl http://localhost:8085/api/v1/template/public/templates

# 搜索模板
curl "http://localhost:8085/api/v1/template/public/templates?search=简历"

# 获取热门模板
curl http://localhost:8085/api/v1/template/public/templates/popular?limit=5
```

#### Statistics Service (端口: 8086)

```bash
# 健康检查
curl http://localhost:8086/health

# 获取系统概览
curl http://localhost:8086/api/v1/statistics/public/overview

# 获取用户趋势
curl "http://localhost:8086/api/v1/statistics/public/users/trend?days=30"

# 获取模板使用统计
curl http://localhost:8086/api/v1/statistics/public/templates/usage?limit=10

# 获取分类统计
curl http://localhost:8086/api/v1/statistics/public/categories/popular

# 获取性能指标
curl http://localhost:8086/api/v1/statistics/public/performance
```

#### Banner Service (端口: 8087)

```bash
# 健康检查
curl http://localhost:8087/health

# 获取Banner列表
curl http://localhost:8087/api/v1/content/public/banners

# 获取特定Banner
curl http://localhost:8087/api/v1/content/public/banners/1

# 获取Markdown内容
curl http://localhost:8087/api/v1/content/public/markdown

# 获取特定Markdown内容
curl http://localhost:8087/api/v1/content/public/markdown/1

# 按分类获取Markdown内容
curl "http://localhost:8087/api/v1/content/public/markdown?category=求职指导"

# 获取评论列表
curl http://localhost:8087/api/v1/content/public/comments

# 获取特定内容的评论
curl "http://localhost:8087/api/v1/content/public/comments?content_id=1"
```

### 服务重启和管理

```bash
# 重启Template Service
cd backend/internal/template-service
go run main.go &

# 重启Statistics Service  
cd backend/internal/statistics-service
go run main.go &

# 重启Banner Service
cd backend/internal/banner-service
go run main.go &
```

## 📊 系统监控

### 实时监控

ZerviGo v3.1.1 提供实时系统监控，包括：

- **健康状态**: 整体系统健康百分比
- **服务状态**: 每个服务的运行状态
- **端口监控**: 正确的端口配置显示
- **基础设施**: 数据库、缓存、服务发现状态

### 监控指标

```bash
# 查看系统健康状态
./backend/pkg/jobfirst-core/superadmin/zervigo | grep "健康状态"

# 查看运行服务数量
./backend/pkg/jobfirst-core/superadmin/zervigo | grep "运行服务"

# 查看特定服务状态
./backend/pkg/jobfirst-core/superadmin/zervigo | grep "template_service"
./backend/pkg/jobfirst-core/superadmin/zervigo | grep "statistics_service"
./backend/pkg/jobfirst-core/superadmin/zervigo | grep "banner_service"
```

## 🔍 故障排除

### 常见问题

#### 1. 端口显示错误

**问题**: ZerviGo 显示错误的端口配置

**解决方案**: 使用 ZerviGo v3.1.1，已修正端口配置问题

```bash
# 验证端口配置
./backend/pkg/jobfirst-core/superadmin/zervigo | grep -E "(template_service|statistics_service|banner_service)"
```

#### 2. 服务无法启动

**问题**: 微服务启动失败

**解决方案**: 检查端口占用和依赖服务

```bash
# 检查端口占用
lsof -i :8085  # Template Service
lsof -i :8086  # Statistics Service
lsof -i :8087  # Banner Service

# 检查依赖服务
curl http://localhost:3306  # MySQL
curl http://localhost:6379  # Redis
```

#### 3. 编译问题

**问题**: Go 模块导入错误

**解决方案**: 使用独立编译版本

```bash
# 使用预编译版本
./backend/pkg/jobfirst-core/superadmin/zervigo

# 或编译独立版本
cd build/zervigo-standalone
go build -o ../zervigo.v3.1.1 .
```

### 调试技巧

```bash
# 详细日志查看
tail -f logs/template-service.log
tail -f logs/statistics-service.log  
tail -f logs/banner-service.log

# 服务进程检查
ps aux | grep template-service
ps aux | grep statistics-service
ps aux | grep banner-service

# 网络连接检查
netstat -tlnp | grep :8085
netstat -tlnp | grep :8086
netstat -tlnp | grep :8087
```

## 🚀 高级功能

### 批量操作

```bash
# 检查所有重构服务的健康状态
for port in 8085 8086 8087; do
  echo "检查端口 $port:"
  curl -s http://localhost:$port/health | jq '.status'
done

# 获取所有服务的版本信息
for port in 8085 8086 8087; do
  echo "端口 $port 版本:"
  curl -s http://localhost:$port/health | jq '.version'
done
```

### 性能监控

```bash
# 监控API响应时间
time curl -s http://localhost:8085/health > /dev/null
time curl -s http://localhost:8086/health > /dev/null  
time curl -s http://localhost:8087/health > /dev/null

# 监控数据库连接
curl -s http://localhost:8085/health | jq '.core_health.database.mysql.status'
curl -s http://localhost:8086/health | jq '.core_health.database.mysql.status'
curl -s http://localhost:8087/health | jq '.core_health.database.mysql.status'
```

### 自动化脚本

创建监控脚本 `monitor-services.sh`:

```bash
#!/bin/bash
echo "=== ZerviGo v3.1.1 服务监控 ==="
echo "时间: $(date)"
echo ""

# 检查重构后的微服务
echo "重构后的微服务状态:"
echo "Template Service (8085): $(curl -s http://localhost:8085/health | jq -r '.status')"
echo "Statistics Service (8086): $(curl -s http://localhost:8086/health | jq -r '.status')"
echo "Banner Service (8087): $(curl -s http://localhost:8087/health | jq -r '.status')"

echo ""
echo "=== 完整系统状态 ==="
./backend/pkg/jobfirst-core/superadmin/zervigo
```

## ⚙️ 配置参考

### 服务端口配置

ZerviGo v3.1.1 正确的端口配置：

```json
{
  "services": {
    "refactored": {
      "template_service": {
        "port": 8085,
        "description": "模板管理服务 - 支持评分、搜索、统计"
      },
      "statistics_service": {
        "port": 8086,
        "description": "数据统计服务 - 系统分析和趋势监控"
      },
      "banner_service": {
        "port": 8087,
        "description": "内容管理服务 - Banner、Markdown、评论"
      }
    },
    "core": {
      "api_gateway": {
        "port": 8080,
        "description": "基础服务器 - API网关"
      },
      "user_service": {
        "port": 8081,
        "description": "用户管理服务"
      },
      "resume_service": {
        "port": 8082,
        "description": "简历管理服务"
      },
      "company_service": {
        "port": 8083,
        "description": "公司管理服务"
      },
      "notification_service": {
        "port": 8084,
        "description": "通知服务"
      },
      "dev_team_service": {
        "port": 8088,
        "description": "开发团队管理服务"
      }
    },
    "infrastructure": {
      "mysql": {
        "port": 3306,
        "description": "MySQL数据库服务"
      },
      "redis": {
        "port": 6379,
        "description": "Redis缓存服务"
      },
      "postgresql": {
        "port": 5432,
        "description": "PostgreSQL数据库服务"
      },
      "consul": {
        "port": 8500,
        "description": "Consul服务发现"
      },
      "nginx": {
        "port": 80,
        "description": "Nginx反向代理"
      },
      "ai_service": {
        "port": 8206,
        "description": "AI服务"
      }
    }
  }
}
```

## 📝 更新日志

### v3.1.1 (2025-09-12)

#### ✅ 修复
- **端口配置修正**: 修正了服务端口显示问题
  - Template Service: 现在正确显示端口 8085
  - Banner Service: 现在正确显示端口 8087
  - Statistics Service: 保持端口 8086

#### 🚀 新功能
- **独立编译**: 解决了Go模块导入问题
- **完整端口范围**: 支持 8080-8088 端口范围的所有服务
- **增强监控**: 提供更准确的系统状态监控

#### 🔧 改进
- **编译稳定性**: 使用独立编译方式，避免模块依赖问题
- **显示准确性**: 服务端口配置显示完全准确
- **监控完整性**: 覆盖所有微服务和基础设施服务

### v3.1.0 (2025-09-11)

#### ✅ 功能
- 重构服务监控支持
- 服务分类管理
- 增强健康检查
- 服务版本追踪
- 性能指标监控

## 🎯 总结

ZerviGo v3.1.1 是一个功能强大、稳定可靠的超级管理员工具，专门为 Zervi-Basic 微服务架构设计。通过修正端口配置问题和解决编译问题，现在提供了：

- ✅ **准确的端口显示**: 所有服务端口配置正确
- ✅ **完整的服务覆盖**: 支持 8080-8088 端口范围的所有服务
- ✅ **稳定的运行**: 独立编译确保稳定运行
- ✅ **实时监控**: 提供系统健康状态实时监控
- ✅ **易于使用**: 简单的命令行界面

使用 ZerviGo v3.1.1，您可以轻松管理和监控整个微服务系统，确保系统稳定运行。

---

**技术支持**: 如有问题，请查看故障排除部分或联系开发团队。  
**版本**: v3.1.1  
**最后更新**: 2025-09-12
