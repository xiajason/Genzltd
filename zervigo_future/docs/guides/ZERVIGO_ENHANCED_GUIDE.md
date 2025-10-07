# Zervigo 增强版使用指南 (v3.1.0)

## 🎯 概述

Zervigo 是一个强大的超级管理员控制工具，结合了数据库校验和超级管理员功能。经过 v3.1.0 版本迭代，现已完全适配重构后的三个微服务架构，提供更强大的服务管理和监控能力。

## 🆕 v3.1.0 更新内容

### 重构服务支持
- ✅ **Template Service (8085)**: 模板管理服务 - 支持评分、搜索、统计
- ✅ **Statistics Service (8086)**: 数据统计服务 - 系统分析和趋势监控  
- ✅ **Banner Service (8087)**: 内容管理服务 - Banner、Markdown、评论

### 新增功能
- 🎯 **服务分类管理**: 按重构、核心、基础设施分类管理服务
- 📊 **增强监控**: 支持新API端点和健康检查机制
- 🔍 **专项管理**: 重构服务的专项监控和管理功能
- 📈 **性能追踪**: 监控服务版本和性能指标

## 🚀 快速开始

### 1. 编译和安装

```bash
# 进入项目目录
cd /Users/szjason72/zervi-basic/basic/backend/pkg/jobfirst-core/superadmin

# 编译 zervigo 工具
./build.sh

# 或者手动编译
go build -o zervigo main.go
```

### 2. 基本使用

```bash
# 查看帮助信息
./zervigo help

# 查看系统整体状态
./zervigo status
```

## 🔄 重构服务管理

### 重构服务概览

v3.1.0 版本新增了对三个重构微服务的专项管理功能：

| 服务名称 | 端口 | 功能描述 | 版本 |
|---------|------|----------|------|
| **Template Service** | 8085 | 模板管理服务 - 支持评分、搜索、统计 | 3.1.0 |
| **Statistics Service** | 8086 | 数据统计服务 - 系统分析和趋势监控 | 3.1.0 |
| **Banner Service** | 8087 | 内容管理服务 - Banner、Markdown、评论 | 3.1.0 |

### 重构服务状态监控

```bash
# 查看所有重构服务状态
./zervigo services refactored

# 查看特定重构服务状态
./zervigo service template-service status
./zervigo service statistics-service status
./zervigo service banner-service status

# 查看重构服务详细信息
./zervigo service template-service info
./zervigo service statistics-service info
./zervigo service banner-service info
```

### Template Service 专项管理

```bash
# 查看Template Service健康状态
./zervigo service template-service health

# 查看Template Service API状态
./zervigo service template-service api

# 监控Template Service性能
./zervigo service template-service performance

# 查看Template Service日志
./zervigo logs template-service

# 重启Template Service
./zervigo service template-service restart
```

### Statistics Service 专项管理

```bash
# 查看Statistics Service健康状态
./zervigo service statistics-service health

# 查看统计数据
./zervigo service statistics-service stats

# 查看趋势分析
./zervigo service statistics-service trends

# 监控Statistics Service性能
./zervigo service statistics-service performance

# 查看Statistics Service日志
./zervigo logs statistics-service
```

### Banner Service 专项管理

```bash
# 查看Banner Service健康状态
./zervigo service banner-service health

# 查看内容管理状态
./zervigo service banner-service content

# 查看评论系统状态
./zervigo service banner-service comments

# 监控Banner Service性能
./zervigo service banner-service performance

# 查看Banner Service日志
./zervigo logs banner-service
```

### 重构服务批量操作

```bash
# 重启所有重构服务
./zervigo services restart refactored

# 查看所有重构服务状态
./zervigo services status refactored

# 查看所有重构服务日志
./zervigo logs refactored

# 执行重构服务健康检查
./zervigo services health-check refactored

# 监控所有重构服务性能
./zervigo services performance refactored
```

### 重构服务配置管理

```bash
# 查看重构服务配置
./zervigo config services refactored

# 更新重构服务配置
./zervigo config update refactored

# 验证重构服务配置
./zervigo config validate refactored

# 备份重构服务配置
./zervigo config backup refactored
```

## 📊 数据库校验功能

### 完整数据库校验

```bash
# 执行完整数据库校验
./zervigo validate all

# 校验特定数据库
./zervigo validate mysql
./zervigo validate redis
./zervigo validate postgresql
./zervigo validate neo4j

# 校验数据一致性
./zervigo validate consistency

# 校验数据库性能
./zervigo validate performance

# 校验数据库安全
./zervigo validate security
```

### 校验结果说明

- ✅ **passed**: 校验通过
- ⚠️ **warning**: 校验警告
- ❌ **failed**: 校验失败

## 🌍 地理位置服务管理

### 地理位置服务状态

```bash
# 查看地理位置服务状态
./zervigo geo status

# 检查地理位置字段
./zervigo geo fields

# 扩展地理位置字段
./zervigo geo extend

# 查看北斗服务状态
./zervigo geo beidou

# 测试地理位置功能
./zervigo geo test
```

### 地理位置字段扩展

系统会自动检查并扩展以下字段：

**用户表 (users)**:
- `latitude` - 纬度 (DECIMAL(10,8))
- `longitude` - 经度 (DECIMAL(11,8))
- `address_detail` - 详细地址 (TEXT)
- `city_code` - 城市代码 (VARCHAR(20))
- `district_code` - 区县代码 (VARCHAR(20))

**公司表 (companies)**:
- `latitude` - 纬度 (DECIMAL(10,8))
- `longitude` - 经度 (DECIMAL(11,8))
- `address_detail` - 详细地址 (TEXT)
- `city_code` - 城市代码 (VARCHAR(20))
- `district_code` - 区县代码 (VARCHAR(20))

## 🕸️ Neo4j 图数据库管理

### Neo4j 状态和初始化

```bash
# 查看 Neo4j 状态
./zervigo neo4j status

# 初始化 Neo4j 数据库
./zervigo neo4j init

# 创建地理位置关系模型
./zervigo neo4j schema

# 导入地理位置数据
./zervigo neo4j data

# 测试地理位置查询
./zervigo neo4j query

# 测试智能匹配功能
./zervigo neo4j match
```

### 地理位置关系模型

系统会创建以下 Neo4j 关系模型：

```cypher
// 地理位置节点
CREATE (l:Location {
    id: 'loc_001',
    name: '北京市朝阳区',
    latitude: 39.9042,
    longitude: 116.4074,
    city_code: '110100',
    district_code: '110105',
    level: 'district'
})

// 用户-地理位置关系
CREATE (u:User)-[:LIVES_IN]->(l:Location)

// 公司-地理位置关系
CREATE (c:Company)-[:LOCATED_IN]->(l:Location)

// 地理位置层级关系
CREATE (city:Location)-[:CONTAINS]->(district:Location)
```

## 👑 超级管理员管理

### 超级管理员设置

```bash
# 设置超级管理员
./zervigo super-admin setup

# 查看超级管理员状态
./zervigo super-admin status

# 查看权限信息
./zervigo super-admin permissions

# 查看操作日志
./zervigo super-admin logs

# 备份超级管理员数据
./zervigo super-admin backup
```

### 团队成员管理

```bash
# 添加团队成员
./zervigo super-admin team add <username> <role> <email>

# 示例
./zervigo super-admin team add john_doe frontend_dev john@example.com

# 列出团队成员
./zervigo super-admin team list

# 移除团队成员
./zervigo super-admin team remove <username>
```

### 超级管理员权限

超级管理员拥有以下权限：

**服务器访问**:
- ✅ SSH 访问
- ✅ 文件系统访问
- ✅ 服务管理

**用户管理**:
- ✅ 创建用户
- ✅ 删除用户
- ✅ 修改用户
- ✅ 分配角色

**数据库操作**:
- ✅ 读取数据
- ✅ 写入数据
- ✅ 备份数据
- ✅ 恢复数据

## 🔧 基础设施管理

### 系统状态监控

```bash
# 查看系统整体状态
./zervigo status

# 管理基础设施服务
./zervigo infrastructure restart
./zervigo infrastructure status

# Consul 服务注册管理
./zervigo consul status
./zervigo consul services
./zervigo consul bypass
```

### 数据库管理

```bash
# 查看数据库状态
./zervigo database status

# 查看数据库初始化状态
./zervigo database init

# 初始化特定数据库
./zervigo database init-mysql
./zervigo database init-postgresql
./zervigo database init-redis

# 初始化所有数据库
./zervigo database init-all
```

### AI 服务管理

```bash
# 查看 AI 服务状态
./zervigo ai status

# 测试 AI 服务功能
./zervigo ai test

# 配置 AI 服务
./zervigo ai configure <provider> <api_key> <base_url> <model>

# 重启 AI 服务
./zervigo ai restart
```

## 📱 前端开发环境管理

### 前端服务管理

```bash
# 查看前端开发环境状态
./zervigo frontend status

# 启动前端开发服务器
./zervigo frontend start

# 停止前端开发服务器
./zervigo frontend stop

# 重启前端开发服务器
./zervigo frontend restart

# 构建生产版本
./zervigo frontend build

# 同步前端源代码
./zervigo frontend sync

# 安装/更新前端依赖
./zervigo frontend deps
```

## ⚙️ 配置管理

### 配置统一管理

```bash
# 收集所有服务配置
./zervigo config collect

# 部署配置到指定环境
./zervigo config deploy <环境名>

# 比较配置差异
./zervigo config compare <环境1> <环境2>

# 备份当前配置
./zervigo config backup

# 恢复配置
./zervigo config restore <备份名>

# 验证配置完整性
./zervigo config validate
```

### 环境管理

```bash
# 列出所有环境
./zervigo env list

# 创建新环境
./zervigo env create <环境名>

# 切换环境
./zervigo env switch <环境名>

# 删除环境
./zervigo env delete <环境名>

# 同步环境配置
./zervigo env sync <源环境> <目标环境>
```

## 🚀 Smart CI/CD 管理

### CI/CD 系统管理

```bash
# 查看 CI/CD 系统状态
./zervigo cicd status

# 查看流水线列表
./zervigo cicd pipeline

# 触发部署
./zervigo cicd deploy [环境名]

# 查看 Webhook 配置
./zervigo cicd webhook

# 查看代码仓库状态
./zervigo cicd repository

# 查看 CI/CD 日志
./zervigo cicd logs [流水线ID]
```

## 👥 用户和权限管理

### 用户管理

```bash
# 列出所有用户
./zervigo users list

# 创建新用户
./zervigo users create <用户名> <角色> [SSH公钥]

# 删除用户
./zervigo users delete <用户名>

# 分配角色
./zervigo users assign <用户名> <角色>

# SSH 密钥管理
./zervigo users ssh <用户名> <add|remove> <SSH公钥>
```

### 角色管理

```bash
# 列出所有角色
./zervigo roles list
```

### 权限管理

```bash
# 检查系统权限
./zervigo permissions check

# 检查用户权限
./zervigo permissions user <用户名>

# 验证访问权限
./zervigo permissions validate <用户名> <资源> <操作>
```

### 访问控制

```bash
# SSH 访问控制
./zervigo access ssh

# 端口访问控制
./zervigo access ports

# 防火墙状态
./zervigo access firewall
```

### 项目成员管理

```bash
# 列出项目成员
./zervigo members list

# 添加项目成员
./zervigo members add <用户名> <角色> [部门]

# 移除项目成员
./zervigo members remove <用户名>

# 查看成员活动记录
./zervigo members activity <用户名>
```

## 📊 系统监控

### 实时监控

```bash
# 实时监控系统 (按 Ctrl+C 退出)
./zervigo monitor
```

### 告警管理

```bash
# 查看系统告警
./zervigo alerts
```

### 系统日志

```bash
# 查看系统日志 (最近10条)
./zervigo logs
```

## 💾 备份和部署

### 系统备份

```bash
# 创建系统备份
./zervigo backup create
```

### 全局部署

```bash
# 重启所有服务
./zervigo deploy restart
```

## 🎯 使用场景示例

### 场景1: 系统初始化

```bash
# 1. 查看系统状态
./zervigo status

# 2. 初始化所有数据库
./zervigo database init-all

# 3. 执行完整数据库校验
./zervigo validate all

# 4. 设置超级管理员
./zervigo super-admin setup

# 5. 启动前端开发环境
./zervigo frontend start
```

### 场景2: 重构服务部署验证

```bash
# 1. 查看重构服务状态
./zervigo services refactored

# 2. 验证Template Service功能
./zervigo service template-service health
./zervigo service template-service api

# 3. 验证Statistics Service功能
./zervigo service statistics-service health
./zervigo service statistics-service stats

# 4. 验证Banner Service功能
./zervigo service banner-service health
./zervigo service banner-service content

# 5. 执行重构服务性能测试
./zervigo services performance refactored
```

### 场景3: 地理位置功能部署

```bash
# 1. 检查地理位置字段
./zervigo geo fields

# 2. 扩展地理位置字段
./zervigo geo extend

# 3. 初始化 Neo4j 数据库
./zervigo neo4j init

# 4. 创建地理位置关系模型
./zervigo neo4j schema

# 5. 导入地理位置数据
./zervigo neo4j data

# 6. 测试地理位置功能
./zervigo geo test
```

### 场景4: 团队成员管理

```bash
# 1. 查看超级管理员状态
./zervigo super-admin status

# 2. 添加前端开发人员
./zervigo super-admin team add alice frontend_dev alice@example.com

# 3. 添加后端开发人员
./zervigo super-admin team add bob backend_dev bob@example.com

# 4. 查看团队成员列表
./zervigo super-admin team list

# 5. 查看操作日志
./zervigo super-admin logs
```

### 场景5: 系统维护

```bash
# 1. 执行完整数据库校验
./zervigo validate all

# 2. 检查数据一致性
./zervigo validate consistency

# 3. 检查数据库性能
./zervigo validate performance

# 4. 检查数据库安全
./zervigo validate security

# 5. 创建系统备份
./zervigo backup create

# 6. 查看系统告警
./zervigo alerts
```

## 🔍 故障排除

### 常见问题

#### 1. 数据库连接失败

```bash
# 检查数据库状态
./zervigo database status

# 检查数据库初始化状态
./zervigo database init

# 重新初始化数据库
./zervigo database init-all
```

#### 2. 服务启动失败

```bash
# 查看系统状态
./zervigo status

# 重启基础设施服务
./zervigo infrastructure restart

# 查看系统日志
./zervigo logs
```

#### 3. 权限问题

```bash
# 检查系统权限
./zervigo permissions check

# 查看超级管理员状态
./zervigo super-admin status

# 查看超级管理员权限
./zervigo super-admin permissions
```

#### 4. 地理位置功能异常

```bash
# 检查地理位置服务状态
./zervigo geo status

# 检查地理位置字段
./zervigo geo fields

# 测试地理位置功能
./zervigo geo test

# 检查 Neo4j 状态
./zervigo neo4j status
```

## 📋 最佳实践

### 1. 定期维护

- 每周执行一次完整数据库校验
- 每月检查数据一致性
- 定期备份系统数据
- 监控系统性能指标

### 2. 安全建议

- 定期更换超级管理员密码
- 监控异常登录行为
- 及时更新系统权限
- 定期审查团队成员权限

### 3. 性能优化

- 定期检查数据库性能
- 优化数据库索引
- 监控系统资源使用
- 及时处理性能告警

### 4. 团队协作

- 合理分配团队成员角色
- 记录重要操作日志
- 建立标准操作流程
- 定期培训团队成员

## 🎉 总结

Zervigo 增强版 v3.1.0 提供了完整的系统管理和监控功能，包括：

### v3.1.0 核心功能
- ✅ **重构服务管理**: 完全适配Template、Statistics、Banner三个重构服务
- ✅ **服务分类管理**: 按重构、核心、基础设施分类管理服务
- ✅ **增强监控**: 支持新API端点和健康检查机制
- ✅ **专项管理**: 重构服务的专项监控和管理功能
- ✅ **性能追踪**: 监控服务版本和性能指标

### 传统功能
- ✅ **数据库校验**: 完整的四个数据库校验功能
- ✅ **地理位置服务**: 地理位置字段扩展和北斗服务集成
- ✅ **Neo4j 图数据库**: 地理位置关系建模和智能匹配
- ✅ **超级管理员**: 完整的权限管理和团队成员管理
- ✅ **系统监控**: 实时监控和告警管理
- ✅ **配置管理**: 统一的配置管理和环境管理
- ✅ **CI/CD 集成**: Smart CI/CD 自动化管理

### 重构服务专项支持
- 🎯 **Template Service**: 模板管理、评分系统、搜索功能监控
- 📊 **Statistics Service**: 数据统计、趋势分析、性能指标监控
- 📝 **Banner Service**: 内容管理、Markdown处理、评论系统监控

通过本指南，您可以充分利用 Zervigo v3.1.0 的强大功能，实现高效的系统管理和团队协作，特别是对重构后微服务的专项管理！

---

**文档版本**: v3.1.0  
**最后更新**: 2025年9月11日  
**维护人员**: 技术团队  
**适配版本**: Zervi-Basic v3.1.0
