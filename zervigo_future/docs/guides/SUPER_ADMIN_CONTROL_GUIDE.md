# 超级管理员控制指南

## 📋 概述

本指南为超级管理员提供**全局基础设施管理**和**权限角色分配**的解决方案，专注于微服务集群的整体管理。通过`zervigo`工具实现企业级的统一管理。

## 🎯 核心职责

- **基础设施管理** - 管理MySQL、Redis、Nginx、Consul等基础服务
- **权限角色分配** - 管理用户权限和角色分配，确保系统安全
- **服务注册管理** - 监控Consul服务注册，防止服务逃逸
- **项目成员管理** - 管理项目团队成员和权限分配
- **AI服务管理** - 管理AI服务配置和OpenAI API接入
- **数据库管理** - 管理数据库初始化和数据完整性
- **前端开发环境** - 管理前端开发服务器和热重载
- **配置管理统一化** - 统一管理所有服务的配置
- **环境管理** - 管理开发、测试、生产等多环境
- **Smart CI/CD** - 智能持续集成和持续部署自动化管理
- **全局监控** - 监控整个微服务集群的健康状态
- **系统备份** - 管理系统的备份和恢复
- **访问控制** - 控制系统的访问权限和安全

## 🛠️ 统一控制工具

### 1. Shell脚本版本 (`super-admin.sh`)

**设计理念**: 一个工具，全局管理，专注核心职责

**核心命令**:
```bash
# 基础设施管理
./super-admin.sh infrastructure restart    # 重启基础设施服务
./super-admin.sh infrastructure status     # 查看基础设施状态

# 权限角色管理
./super-admin.sh users list                # 列出所有用户
./super-admin.sh roles list                # 列出所有角色
./super-admin.sh permissions check         # 检查系统权限
./super-admin.sh access ssh                # SSH访问控制

# 系统管理
./super-admin.sh status                    # 查看系统整体状态
./super-admin.sh backup create             # 创建系统备份
./super-admin.sh deploy restart            # 重启所有服务
./super-admin.sh monitor                   # 实时监控
./super-admin.sh alerts                    # 告警管理
./super-admin.sh logs                      # 系统日志
```

### 2. Go包版本 (`zervigo`) - 推荐使用

**设计理念**: 企业级Go私有包，类型安全，可扩展，功能完整

**包结构**:
```
pkg/jobfirst-core/superadmin/
├── types.go          # 类型定义
├── manager.go        # 核心管理器
├── cli.go           # CLI工具
├── cmd/zervigo/main.go # 主程序入口
├── superadmin_test.go # 单元测试
├── build.sh         # 构建脚本
└── superadmin-config.json # 配置文件
```

**核心功能**:
- **类型安全**: 完整的Go类型定义
- **模块化设计**: 清晰的功能分离
- **可测试性**: 完整的单元测试覆盖
- **可扩展性**: 易于添加新功能
- **企业级**: 集成到JobFirst核心包
- **服务注册管理**: 智能Consul服务注册检查
- **权限管理**: 完整的RBAC权限体系
- **项目成员管理**: 团队协作管理
- **AI服务管理**: OpenAI API配置和向量数据管理
- **数据库管理**: 数据库初始化和数据完整性检查
- **前端开发环境**: 前端开发服务器管理和热重载支持
- **配置管理统一化**: 跨环境的配置版本管理和部署
- **环境管理**: 多环境配置管理和同步
- **Smart CI/CD**: 智能持续集成和持续部署自动化管理

**完整命令列表**:
```bash
# 基础设施管理
zervigo status                    # 查看系统整体状态
zervigo infrastructure restart    # 重启基础设施服务
zervigo infrastructure status     # 查看基础设施状态

# Consul服务注册管理
zervigo consul status             # 查看Consul服务注册状态
zervigo consul services           # 查看已注册服务列表
zervigo consul bypass             # 检查绕过注册的服务

# 数据库校验和验证 (新增功能)
zervigo validate all              # 执行完整数据库校验
zervigo validate mysql            # 校验MySQL数据库
zervigo validate redis            # 校验Redis数据库
zervigo validate postgresql       # 校验PostgreSQL数据库
zervigo validate neo4j            # 校验Neo4j数据库
zervigo validate consistency      # 校验数据一致性
zervigo validate performance      # 校验数据库性能
zervigo validate security         # 校验数据库安全

# 地理位置服务管理 (新增功能)
zervigo geo status                # 查看地理位置服务状态
zervigo geo fields                # 检查地理位置字段
zervigo geo extend                # 扩展地理位置字段
zervigo geo beidou                # 查看北斗服务状态
zervigo geo test                  # 测试地理位置功能

# Neo4j图数据库管理 (新增功能)
zervigo neo4j status              # 查看Neo4j状态
zervigo neo4j init                # 初始化Neo4j数据库
zervigo neo4j schema              # 创建地理位置关系模型
zervigo neo4j data                # 导入地理位置数据
zervigo neo4j query               # 测试地理位置查询
zervigo neo4j match               # 测试智能匹配功能

# 用户管理
zervigo users list                # 列出所有用户
zervigo users create <用户名> <角色> [SSH公钥]  # 创建新用户
zervigo users delete <用户名>     # 删除用户
zervigo users assign <用户名> <角色>  # 分配角色
zervigo users ssh <用户名> <add|remove> <SSH公钥>  # SSH密钥管理

# 角色管理
zervigo roles list                # 列出所有角色

# 权限管理
zervigo permissions check         # 检查系统权限
zervigo permissions user <用户名> # 检查用户权限
zervigo permissions validate <用户名> <资源> <操作>  # 验证访问权限

# 项目成员管理
zervigo members list              # 列出项目成员
zervigo members add <用户名> <角色> [部门]  # 添加项目成员
zervigo members remove <用户名>   # 移除项目成员
zervigo members activity <用户名> # 查看成员活动记录

# 超级管理员管理 (新增功能)
zervigo super-admin setup         # 设置超级管理员
zervigo super-admin status        # 查看超级管理员状态
zervigo super-admin team          # 团队成员管理
zervigo super-admin permissions   # 查看权限信息
zervigo super-admin logs          # 查看操作日志
zervigo super-admin backup        # 备份超级管理员数据

# AI服务管理
zervigo ai status                 # 查看AI服务状态
zervigo ai test                   # 测试AI服务功能
zervigo ai configure <provider> <api_key> <base_url> <model>  # 配置AI服务
zervigo ai restart                # 重启AI服务

# 数据库管理
zervigo database status           # 查看数据库状态
zervigo database init-mysql       # 初始化MySQL数据库
zervigo database init-postgresql  # 初始化PostgreSQL数据库
zervigo database init-redis       # 初始化Redis数据库
zervigo database init-all         # 初始化所有数据库

# 前端开发环境管理
zervigo frontend status           # 查看前端开发环境状态
zervigo frontend start            # 启动前端开发服务器
zervigo frontend stop             # 停止前端开发服务器
zervigo frontend restart          # 重启前端开发服务器
zervigo frontend build            # 构建生产版本
zervigo frontend sync             # 同步源代码
zervigo frontend deps             # 安装/更新依赖

# 配置管理统一化
zervigo config collect            # 收集所有服务配置
zervigo config deploy <env>       # 部署配置到指定环境
zervigo config compare <env1> <env2> # 比较配置差异
zervigo config backup             # 备份当前配置
zervigo config restore <backup>   # 恢复配置
zervigo config validate           # 验证配置完整性

# 环境管理
zervigo env list                  # 列出所有环境
zervigo env create <name>         # 创建新环境
zervigo env switch <name>         # 切换环境
zervigo env delete <name>         # 删除环境
zervigo env sync <source> <target> # 同步环境配置

# Smart CI/CD管理
zervigo cicd status               # 查看CI/CD系统状态
zervigo cicd pipeline             # 查看流水线列表
zervigo cicd deploy [env]         # 触发部署 (默认: production)
zervigo cicd webhook              # 查看Webhook配置
zervigo cicd repository           # 查看代码仓库状态
zervigo cicd logs [id]            # 查看CI/CD日志

# 访问控制
zervigo access ssh                # SSH访问控制
zervigo access ports              # 端口访问控制
zervigo access firewall           # 防火墙状态

# 系统管理
zervigo backup create             # 创建系统备份
zervigo deploy restart            # 重启所有服务
zervigo monitor                   # 实时监控
zervigo alerts                    # 告警管理
zervigo logs                      # 系统日志
```

**使用方法**:
```bash
# 构建
cd pkg/jobfirst-core/superadmin
./build.sh

# 安装
cd build && sudo ./install.sh

# 使用
zervigo --help                    # 查看帮助信息
zervigo status                    # 查看系统状态
```

## 🎯 设计优势

### 1. 企业级架构
- **Go包实现**: 类型安全，性能优异，可扩展
- **模块化设计**: 清晰的功能分离和职责划分
- **统一接口**: 所有功能通过一个命令入口

### 2. 智能服务管理
- **Consul集成**: 智能服务注册检查和逃逸检测
- **服务发现**: 自动发现和监控微服务状态
- **健康检查**: 实时监控服务健康状态

### 3. 完整权限体系
- **RBAC模型**: 基于角色的访问控制
- **7级角色**: 从超级管理员到访客用户的完整权限体系
- **动态权限**: 支持实时权限分配和验证
- **项目成员管理**: 团队协作和权限管理

### 4. 全局视角
- **集群健康度**: 显示整个微服务集群的健康状态
- **基础设施优先**: 优先管理基础设施服务
- **权限集中**: 集中管理用户权限和角色
- **统一监控**: 一站式系统监控和告警

### 5. 企业级特性
- **类型安全**: Go的强类型系统
- **可测试性**: 完整的单元测试覆盖
- **可扩展性**: 模块化设计，易于扩展
- **集成性**: 集成到JobFirst核心包
- **安全性**: SSH密钥管理和访问控制

## 🚀 快速开始

### 1. 环境准备

确保您已经具备以下条件：
- SSH密钥文件: `~/.ssh/basic.pem`
- 服务器访问权限: `ubuntu@101.33.251.158`
- 脚本执行权限: `chmod +x *.sh`

### 2. Shell脚本版本使用

```bash
# 1. 查看系统整体状态
./super-admin.sh status

# 2. 检查基础设施状态
./super-admin.sh infrastructure status

# 3. 查看用户和角色
./super-admin.sh users list
./super-admin.sh roles list

# 4. 创建初始备份
./super-admin.sh backup create
```

### 3. Go包版本使用 (推荐)

```bash
# 1. 构建Go包
cd pkg/jobfirst-core/superadmin
./build.sh

# 2. 安装
cd build && sudo ./install.sh

# 3. 基础使用
zervigo status                    # 查看系统整体状态
zervigo infrastructure status     # 查看基础设施状态
zervigo consul status             # 查看Consul服务注册状态

# 4. 用户和权限管理
zervigo users list                # 列出所有用户
zervigo roles list                # 列出所有角色
zervigo members list              # 列出项目成员
zervigo permissions check         # 检查系统权限

# 5. AI服务和数据库管理
zervigo ai status                 # 查看AI服务状态
zervigo database status           # 查看数据库状态
zervigo database init-all         # 初始化所有数据库
```

### 4. 日常管理

```bash
# 每日检查
zervigo status                    # 查看系统整体状态
zervigo consul status             # 检查服务注册状态
zervigo alerts                    # 查看告警信息

# 基础设施管理
zervigo infrastructure restart    # 重启基础设施服务
zervigo infrastructure status     # 查看基础设施状态

# 权限和用户管理
zervigo users list                # 查看用户列表
zervigo members list              # 查看项目成员
zervigo permissions check         # 检查系统权限
zervigo access ssh                # 检查SSH访问控制

# AI服务和数据库管理
zervigo ai status                 # 查看AI服务状态
zervigo ai test                   # 测试AI服务功能
zervigo database status           # 查看数据库状态

# 实时监控
zervigo monitor                   # 实时监控系统
zervigo logs                      # 查看系统日志
```

## 📊 使用场景

### 场景1: 基础设施故障处理

```bash
# 1. 检查系统整体状态
zervigo status

# 2. 查看基础设施状态
zervigo infrastructure status

# 3. 重启基础设施服务
zervigo infrastructure restart

# 4. 验证服务恢复
zervigo status
```

### 场景2: 权限和用户管理

```bash
# 1. 查看用户列表
zervigo users list

# 2. 查看角色定义
zervigo roles list

# 3. 创建新用户
zervigo users create developer1 后端开发

# 4. 分配角色
zervigo users assign developer1 开发负责人

# 5. 检查用户权限
zervigo permissions user developer1

# 6. 验证访问权限
zervigo permissions validate developer1 system restart

# 7. 检查访问控制
zervigo access ssh
```

### 场景3: 服务注册管理

```bash
# 1. 检查Consul服务注册状态
zervigo consul status

# 2. 查看已注册服务列表
zervigo consul services

# 3. 检查绕过注册的服务
zervigo consul bypass

# 4. 查看系统整体状态
zervigo status
```

### 场景4: 项目成员管理

```bash
# 1. 查看项目成员列表
zervigo members list

# 2. 添加新项目成员
zervigo members add developer2 前端开发

# 3. 查看成员活动记录
zervigo members activity developer2

# 4. 移除项目成员
zervigo members remove developer2
```

### 场景5: 系统监控

```bash
# 1. 实时监控系统
zervigo monitor

# 2. 检查告警信息
zervigo alerts

# 3. 查看系统日志
zervigo logs

# 4. 创建备份
zervigo backup create
```

### 场景6: AI服务管理

```bash
# 1. 查看AI服务状态
zervigo ai status

# 2. 测试AI服务功能
zervigo ai test

# 3. 配置OpenAI API
zervigo ai configure openai sk-your-api-key https://api.openai.com/v1 gpt-3.5-turbo

# 4. 重启AI服务
zervigo ai restart

# 5. 验证配置
zervigo ai status
```

### 场景7: 数据库初始化

```bash
# 1. 查看数据库状态
zervigo database status

# 2. 初始化MySQL数据库
zervigo database init-mysql

# 3. 初始化PostgreSQL数据库
zervigo database init-postgresql

# 4. 初始化Redis数据库
zervigo database init-redis

# 5. 或者一次性初始化所有数据库
zervigo database init-all

# 6. 验证初始化结果
zervigo database status
```

### 场景8: 前端开发环境管理

```bash
# 1. 查看前端开发环境状态
zervigo frontend status

# 2. 启动前端开发服务器
zervigo frontend start

# 3. 同步最新源代码
zervigo frontend sync

# 4. 安装/更新依赖
zervigo frontend deps

# 5. 构建生产版本
zervigo frontend build

# 6. 验证前端环境
zervigo frontend status
```

### 场景9: 配置管理统一化

```bash
# 1. 收集所有服务配置
zervigo config collect

# 2. 验证配置完整性
zervigo config validate

# 3. 备份当前配置
zervigo config backup

# 4. 部署配置到生产环境
zervigo config deploy production

# 5. 比较环境配置差异
zervigo config compare development production

# 6. 恢复配置
zervigo config restore config-backup-20250909
```

### 场景10: 环境管理

```bash
# 1. 查看所有环境
zervigo env list

# 2. 创建新环境
zervigo env create staging

# 3. 同步环境配置
zervigo env sync development staging

# 4. 切换环境
zervigo env switch production

# 5. 删除环境
zervigo env delete staging
```

### 场景11: Smart CI/CD管理

```bash
# 1. 查看CI/CD系统状态
zervigo cicd status

# 2. 查看流水线执行历史
zervigo cicd pipeline

# 3. 触发生产环境部署
zervigo cicd deploy production

# 4. 查看Webhook配置
zervigo cicd webhook

# 5. 检查代码仓库状态
zervigo cicd repository

# 6. 查看部署日志
zervigo cicd logs pipeline-001
```

### 场景12: 数据库校验和验证

```bash
# 1. 执行完整数据库校验
zervigo validate all

# 2. 校验特定数据库
zervigo validate mysql
zervigo validate redis
zervigo validate postgresql
zervigo validate neo4j

# 3. 校验数据一致性
zervigo validate consistency

# 4. 校验数据库性能
zervigo validate performance

# 5. 校验数据库安全
zervigo validate security
```

### 场景13: 地理位置服务部署

```bash
# 1. 检查地理位置服务状态
zervigo geo status

# 2. 检查地理位置字段
zervigo geo fields

# 3. 扩展地理位置字段
zervigo geo extend

# 4. 查看北斗服务状态
zervigo geo beidou

# 5. 测试地理位置功能
zervigo geo test
```

### 场景14: Neo4j图数据库管理

```bash
# 1. 查看Neo4j状态
zervigo neo4j status

# 2. 初始化Neo4j数据库
zervigo neo4j init

# 3. 创建地理位置关系模型
zervigo neo4j schema

# 4. 导入地理位置数据
zervigo neo4j data

# 5. 测试地理位置查询
zervigo neo4j query

# 6. 测试智能匹配功能
zervigo neo4j match
```

### 场景15: 超级管理员管理

```bash
# 1. 设置超级管理员
zervigo super-admin setup

# 2. 查看超级管理员状态
zervigo super-admin status

# 3. 查看权限信息
zervigo super-admin permissions

# 4. 查看操作日志
zervigo super-admin logs

# 5. 备份超级管理员数据
zervigo super-admin backup
```

### 场景16: 系统维护

```bash
# 1. 查看系统状态
zervigo status

# 2. 执行完整数据库校验
zervigo validate all

# 3. 重启所有服务
zervigo deploy restart

# 4. 检查告警
zervigo alerts

# 5. 创建维护备份
zervigo backup create
```

## 🔧 配置说明

### 服务器配置

```bash
# 服务器信息
SERVER_IP="101.33.251.158"
SERVER_USER="ubuntu"
SSH_KEY="~/.ssh/basic.pem"
PROJECT_DIR="/opt/jobfirst"
```

### 服务配置

```bash
# 微服务集群 (9个服务)
MICROSERVICES=(
    "basic-server:8080:Basic Server"
    "user-service:8081:User Service"
    "resume-service:8082:Resume Service"
    "company-service:8083:Company Service"
    "notification-service:8084:Notification Service"
    "banner-service:8085:Banner Service"
    "statistics-service:8086:Statistics Service"
    "template-service:8087:Template Service"
    "ai-service:8206:AI Service"
)

# 基础设施服务
INFRASTRUCTURE_SERVICES=(
    "mysql:3306:MySQL Database"
    "redis-server:6379:Redis Cache"
    "postgresql:5432:PostgreSQL Database"
    "nginx:80:Nginx Web Server"
    "consul:8500:Consul Service Discovery"
)

# AI服务配置
AI_SERVICE_CONFIG=(
    "port:8206:AI Service Port"
    "provider:openai:AI Provider (openai/deepseek/ollama)"
    "model:gpt-3.5-turbo:AI Model"
    "vector_db:postgresql:Vector Database"
)
```

### 角色权限配置

```bash
# 7级角色体系
ROLES=(
    "超级管理员:100:完全系统访问权限"
    "系统管理员:80:基础设施管理权限"
    "开发负责人:60:项目开发管理权限"
    "前端开发:40:前端开发权限"
    "后端开发:40:后端开发权限"
    "测试工程师:30:测试环境权限"
    "访客用户:10:只读访问权限"
)
```

### 监控阈值

```bash
# 监控阈值配置
CPU_THRESHOLD=80
MEMORY_THRESHOLD=80
DISK_THRESHOLD=85
```

## 📈 最佳实践

### 1. 日常运维

- **每日检查**: 使用 `zervigo status` 检查所有服务状态
- **服务注册检查**: 使用 `zervigo consul status` 确保服务正常注册
- **AI服务检查**: 使用 `zervigo ai status` 检查AI服务状态
- **数据库检查**: 使用 `zervigo database status` 检查数据库状态
- **权限审计**: 定期使用 `zervigo permissions check` 检查权限配置
- **日志分析**: 定期查看服务日志，及时发现问题
- **备份管理**: 定期创建系统备份，保留多个版本

### 2. 故障处理

- **快速诊断**: 使用 `zervigo status` 快速诊断问题
- **服务注册检查**: 使用 `zervigo consul bypass` 检查服务逃逸
- **AI服务诊断**: 使用 `zervigo ai test` 测试AI服务功能
- **数据库诊断**: 使用 `zervigo database status` 检查数据库状态
- **日志分析**: 使用 `zervigo logs` 查看详细错误信息
- **服务重启**: 使用 `zervigo infrastructure restart` 重启故障服务
- **权限验证**: 使用 `zervigo permissions validate` 验证访问权限

### 3. 用户和权限管理

- **用户创建**: 使用 `zervigo users create` 创建新用户
- **角色分配**: 使用 `zervigo users assign` 分配角色
- **权限检查**: 使用 `zervigo permissions user` 检查用户权限
- **项目成员管理**: 使用 `zervigo members` 管理项目团队
- **SSH密钥管理**: 使用 `zervigo users ssh` 管理SSH访问

### 4. AI服务和数据库管理

- **AI服务配置**: 使用 `zervigo ai configure` 配置OpenAI API
- **AI服务测试**: 定期使用 `zervigo ai test` 测试AI服务功能
- **数据库初始化**: 使用 `zervigo database init-all` 初始化所有数据库
- **向量数据管理**: 监控PostgreSQL中的向量数据存储
- **API密钥管理**: 安全存储和管理AI服务API密钥

### 5. 前端开发环境管理

- **开发服务器管理**: 使用 `zervigo frontend start/stop/restart` 管理开发服务器
- **源代码同步**: 定期使用 `zervigo frontend sync` 同步最新代码
- **依赖管理**: 使用 `zervigo frontend deps` 管理依赖包
- **生产构建**: 使用 `zervigo frontend build` 构建生产版本
- **环境监控**: 使用 `zervigo frontend status` 监控开发环境状态

### 6. 配置管理统一化

- **配置收集**: 定期使用 `zervigo config collect` 收集所有服务配置
- **配置验证**: 使用 `zervigo config validate` 验证配置完整性
- **配置备份**: 部署前使用 `zervigo config backup` 备份配置
- **环境部署**: 使用 `zervigo config deploy` 部署配置到不同环境
- **配置比较**: 使用 `zervigo config compare` 比较环境差异

### 7. Smart CI/CD管理

- **系统监控**: 定期使用 `zervigo cicd status` 监控CI/CD系统状态
- **流水线管理**: 使用 `zervigo cicd pipeline` 查看流水线执行历史
- **部署控制**: 使用 `zervigo cicd deploy` 精确控制部署时机
- **Webhook管理**: 使用 `zervigo cicd webhook` 管理自动触发配置
- **代码监控**: 使用 `zervigo cicd repository` 监控代码仓库状态
- **日志追踪**: 使用 `zervigo cicd logs` 追踪部署过程和问题

### 7. 部署管理

- **部署前备份**: 每次部署前创建完整备份
- **服务注册验证**: 部署后验证服务是否正确注册到Consul
- **AI服务验证**: 部署后验证AI服务配置和功能
- **数据库验证**: 部署后验证数据库初始化和数据完整性
- **权限验证**: 确保新用户具有正确的访问权限
- **版本管理**: 使用版本号管理不同部署版本

### 8. 安全考虑

- **SSH密钥管理**: 确保SSH密钥文件安全
- **权限控制**: 使用RBAC模型控制访问权限
- **服务逃逸检测**: 定期检查是否有服务绕过Consul注册
- **AI服务安全**: 保护AI服务API密钥和配置信息
- **数据库安全**: 确保数据库连接和访问安全
- **日志审计**: 定期审计操作日志
- **备份加密**: 考虑对敏感数据进行加密备份

## 🚨 故障排除

### 常见问题

1. **SSH连接失败**
   ```bash
   # 检查SSH密钥权限
   chmod 600 ~/.ssh/basic.pem
   
   # 测试SSH连接
   ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158
   ```

2. **服务启动失败**
   ```bash
   # 查看系统状态
   zervigo status
   
   # 查看服务日志
   zervigo logs
   
   # 检查端口占用
   zervigo access ports
   ```

3. **服务注册问题**
   ```bash
   # 检查Consul状态
   zervigo consul status
   
   # 查看已注册服务
   zervigo consul services
   
   # 检查服务逃逸
   zervigo consul bypass
   ```

4. **权限问题**
   ```bash
   # 检查用户权限
   zervigo permissions user <用户名>
   
   # 验证访问权限
   zervigo permissions validate <用户名> <资源> <操作>
   
   # 检查访问控制
   zervigo access ssh
   ```

5. **AI服务问题**
   ```bash
   # 检查AI服务状态
   zervigo ai status
   
   # 测试AI服务功能
   zervigo ai test
   
   # 重启AI服务
   zervigo ai restart
   
   # 检查API配置
   zervigo ai configure
   ```

6. **数据库问题**
   ```bash
   # 检查数据库状态
   zervigo database status
   
   # 初始化数据库
   zervigo database init-all
   
   # 检查PostgreSQL连接
   zervigo database init-postgresql
   ```

7. **性能问题**
   ```bash
   # 查看系统资源
   zervigo status
   
   # 检查告警信息
   zervigo alerts
   
   # 实时监控
   zervigo monitor
   ```

### 紧急恢复

```bash
# 1. 检查系统状态
zervigo status

# 2. 停止所有服务
zervigo deploy stop

# 3. 恢复最新备份
zervigo backup restore

# 4. 启动所有服务
zervigo deploy restart

# 5. 验证系统状态
zervigo status

# 6. 检查服务注册
zervigo consul status
```

## 📞 支持信息

### 联系方式

- **技术支持**: admin@jobfirst.com
- **紧急联系**: 24/7 技术支持热线
- **文档更新**: 定期更新使用指南

### 相关文档

- [腾讯云服务器验证最终报告](./TENCENT_CLOUD_VERIFICATION_FINAL_REPORT.md)
- [部署指南](../DEPLOYMENT_GUIDE.md)
- [系统架构文档](./PRODUCTION_ARCHITECTURE.md)

## 🔄 更新日志

### v2.3.0 (2025-09-09) - Smart CI/CD自动化管理
- **新增**: Smart CI/CD系统集成到zervigo工具
- **新增**: CI/CD流水线状态监控和管理
- **新增**: 智能部署触发和控制
- **新增**: Webhook配置管理
- **新增**: 代码仓库状态监控
- **新增**: CI/CD日志追踪和问题诊断
- **优化**: 基于经验教训的CI/CD架构设计
- **优化**: 超级管理员集中控制CI/CD流程
- **完善**: CI/CD最佳实践和操作指南

### v2.2.0 (2025-09-09) - 前端开发环境和配置管理统一化
- **新增**: 前端开发环境管理功能
- **新增**: 前端开发服务器启动/停止/重启
- **新增**: 前端源代码同步和依赖管理
- **新增**: 前端生产版本构建
- **新增**: 配置管理统一化功能
- **新增**: 跨环境配置收集和部署
- **新增**: 配置验证和备份恢复
- **新增**: 多环境管理功能
- **优化**: 完整的开发环境生命周期管理
- **优化**: 配置版本控制和环境隔离
- **完善**: 前端开发和配置管理文档

### v2.1.0 (2025-09-09) - AI服务和数据库管理
- **新增**: AI服务管理功能 (OpenAI API配置)
- **新增**: 数据库初始化和数据完整性检查
- **新增**: PostgreSQL向量数据管理
- **新增**: AI服务测试和配置功能
- **新增**: 数据库状态监控
- **优化**: 完整的AI服务生命周期管理
- **优化**: 数据库初始化自动化
- **完善**: AI服务和数据库管理文档

### v2.0.0 (2025-09-09) - 企业级升级
- **新增**: 完整的用户管理和权限体系
- **新增**: 项目成员管理功能
- **新增**: Consul服务注册智能检查
- **新增**: 服务逃逸检测功能
- **新增**: SSH密钥管理
- **新增**: 7级角色权限体系
- **优化**: 企业级Go包架构
- **优化**: 类型安全和可扩展性
- **完善**: 完整的文档和示例

### v1.0.0 (2025-09-09)
- 初始版本发布
- 包含基础管理功能
- 完整的文档和示例

---

**文档版本**: v2.3.0  
**最后更新**: 2025年9月9日  
**维护人员**: AI Assistant
