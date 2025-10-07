# 数据迁移工具

## 概述

这个工具用于将 JobFirst 系统的数据从 V1.0 结构迁移到 V3.0 结构。V3.0 采用了模块化、标准化、关联化的设计模式，提供了更好的数据组织和扩展性。

## 主要特性

- **完整数据迁移**: 支持简历、技能、工作经历、教育背景、项目经验、证书等数据的迁移
- **智能数据转换**: 自动将 JSON 格式的简历内容转换为 Markdown 格式
- **技能标准化**: 自动分类和标准化技能数据
- **数据验证**: 提供完整的数据验证和报告生成功能
- **备份支持**: 支持源数据库备份
- **试运行模式**: 支持试运行模式，不执行实际迁移

## 文件结构

```
cmd/migrate/
├── main.go          # 主迁移程序
├── validate.go      # 数据验证工具
├── config.yaml      # 配置文件
├── migrate.sh       # 迁移脚本
└── README.md        # 说明文档
```

## 安装要求

- Go 1.19+
- MySQL 8.0+
- MySQL 客户端工具 (mysqldump, mysql)

## 使用方法

### 1. 基本使用

```bash
# 使用默认配置执行完整迁移
./migrate.sh

# 显示帮助信息
./migrate.sh --help
```

### 2. 高级选项

```bash
# 备份源数据库并验证迁移结果
./migrate.sh -b -v

# 试运行模式，不执行实际迁移
./migrate.sh -d

# 跳过技能迁移，只迁移简历
./migrate.sh --skip-skills

# 强制迁移，覆盖已存在的数据
./migrate.sh --force

# 指定自定义配置
./migrate.sh -c custom_config.yaml
```

### 3. 直接使用 Go 程序

```bash
# 编译迁移工具
go build -o migrate main.go

# 运行迁移
./migrate

# 编译验证工具
go build -o validate validate.go

# 运行验证
./validate
```

## 配置说明

### 数据库配置

```yaml
database:
  source:
    host: "localhost"
    port: 3306
    user: "root"
    password: "password"
    database: "jobfirst"
  
  target:
    host: "localhost"
    port: 3306
    user: "root"
    password: "password"
    database: "jobfirst_v3"
```

### 迁移选项

```yaml
migration:
  backup_source: true      # 是否备份源数据库
  validate_result: true    # 是否验证迁移结果
  batch_size: 100         # 批处理大小
  skip_existing: true     # 是否跳过已存在的记录
  verbose_logging: true   # 是否启用详细日志
```

## 数据迁移流程

### 1. 技能数据迁移

- 从用户资料中提取技能信息
- 自动分类技能（前端开发、后端开发、数据库、运维部署、设计等）
- 识别热门技能
- 创建标准化的技能表

### 2. 简历数据迁移

- 迁移简历基本信息
- 将 JSON 格式内容转换为 Markdown 格式
- 生成 URL 友好的 slug
- 设置正确的状态和可见性

### 3. 关联数据迁移

- **简历技能关联**: 创建简历与技能的关联关系
- **工作经历**: 迁移工作经历数据
- **教育背景**: 迁移教育背景数据
- **项目经验**: 迁移项目经验数据
- **证书**: 迁移证书数据

## 数据转换规则

### 技能分类映射

| 分类 | 包含技能 |
|------|----------|
| 前端开发 | React, Vue, Angular, JavaScript, TypeScript, HTML, CSS 等 |
| 后端开发 | Go, Java, Python, Node.js, PHP, Spring, Django 等 |
| 数据库 | MySQL, PostgreSQL, MongoDB, Redis, Elasticsearch 等 |
| 运维部署 | Docker, Kubernetes, AWS, Azure, Jenkins 等 |
| 设计 | Photoshop, Illustrator, Figma, Sketch, UI/UX 等 |

### 熟练度映射

| V1.0 | V3.0 |
|------|------|
| 初级/beginner | beginner |
| 中级/intermediate | intermediate |
| 高级/advanced | advanced |
| 专家/expert | expert |

### 状态映射

| V1.0 | V3.0 |
|------|------|
| draft | draft |
| published | published |
| archived | archived |

## 验证和报告

### 数据验证

迁移完成后，工具会自动验证：

- 数据完整性
- 关联关系正确性
- 数据格式正确性
- 记录数量匹配

### 验证报告

工具会生成详细的验证报告 `migration_report.md`，包含：

- 数据统计信息
- 验证结果
- 问题汇总
- 建议和后续步骤

## 故障排除

### 常见问题

1. **数据库连接失败**
   - 检查数据库配置
   - 确认数据库服务正在运行
   - 验证用户名和密码

2. **权限不足**
   - 确保数据库用户有足够的权限
   - 检查数据库访问权限

3. **数据格式错误**
   - 检查源数据的 JSON 格式
   - 验证数据完整性

4. **迁移中断**
   - 检查日志文件
   - 使用备份恢复
   - 重新运行迁移

### 日志文件

迁移过程中的详细日志会输出到控制台，包括：

- 迁移进度
- 错误信息
- 警告信息
- 统计信息

## 安全注意事项

1. **备份数据**: 始终在迁移前备份源数据库
2. **测试环境**: 先在测试环境中验证迁移过程
3. **权限控制**: 使用最小权限原则
4. **数据验证**: 迁移后仔细验证数据完整性

## 性能优化

1. **批处理**: 使用适当的批处理大小
2. **索引**: 确保目标数据库有适当的索引
3. **连接池**: 使用数据库连接池
4. **内存管理**: 监控内存使用情况

## 后续步骤

迁移完成后，建议执行以下步骤：

1. **验证数据**: 使用验证工具检查数据完整性
2. **更新配置**: 更新应用程序配置以使用新数据库
3. **功能测试**: 测试所有应用程序功能
4. **性能测试**: 进行性能测试
5. **用户培训**: 培训用户使用新功能
6. **监控**: 设置监控和告警

## 技术支持

如果遇到问题，请：

1. 查看日志文件
2. 检查配置文件
3. 验证数据库连接
4. 联系技术支持团队

## 版本历史

- v1.0.0: 初始版本，支持基本数据迁移
- v1.1.0: 添加数据验证功能
- v1.2.0: 添加备份和恢复功能
- v1.3.0: 优化性能和错误处理
