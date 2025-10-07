# 前端代码质量检查指南

## 📋 概述

本文档描述了 `frontend-taro/` 项目的代码质量检查体系，包括代码规范、检查工具、CI/CD集成等内容。

## 🛠️ 质量检查工具

### 1. ESLint - JavaScript/TypeScript 代码检查

**配置文件**: `.eslintrc.js`

**主要规则**:
- 代码复杂度控制 (max-lines: 200, max-params: 3)
- 代码质量规则 (no-unused-vars, prefer-const)
- React/Taro 特定规则
- 安全规则 (no-eval, no-script-url)

**使用方法**:
```bash
# 检查代码
npm run lint

# 自动修复
npm run lint:fix
```

### 2. Stylelint - CSS/SCSS 样式检查

**配置文件**: `.stylelintrc.js`

**主要规则**:
- 代码风格统一 (indentation: 2, string-quotes: 'single')
- 性能优化规则
- 兼容性检查
- 代码质量规则

**使用方法**:
```bash
# 检查样式
npm run lint:css

# 自动修复
npm run lint:css:fix
```

### 3. Prettier - 代码格式化

**配置文件**: `.prettierrc.js`

**格式化规则**:
- 行宽: 80字符
- 缩进: 2个空格
- 引号: 单引号
- 分号: 必须
- 尾随逗号: 无

**使用方法**:
```bash
# 格式化代码
npm run format

# 检查格式
npm run format:check
```

### 4. TypeScript - 类型检查

**配置文件**: `tsconfig.json`

**检查内容**:
- 类型安全
- 接口定义
- 泛型使用
- 模块导入/导出

**使用方法**:
```bash
# 类型检查
npm run type-check

# 监听模式
npm run type-check:watch
```

### 5. Jest - 单元测试

**配置文件**: `jest.config.js`

**测试要求**:
- 覆盖率: 0% (开发阶段)
- 测试文件: `**/*.test.{js,ts,tsx}`
- 测试环境: jsdom

**使用方法**:
```bash
# 运行测试
npm run test

# 监听模式
npm run test:watch

# 覆盖率报告
npm run test:coverage

# CI模式
npm run test:ci
```

## 🚀 质量检查脚本

### 1. 完整质量检查

```bash
# 运行完整质量检查
npm run quality-check
```

**检查内容**:
- ESLint 代码检查
- Stylelint 样式检查
- TypeScript 类型检查
- 单元测试执行
- 构建测试

**输出**:
- 控制台彩色输出
- 质量报告文件: `quality-report.json`
- 退出码: 0 (通过) / 1 (失败)

### 2. 简化质量检查

```bash
# 运行简化质量检查
npm run quality-check:simple
```

**检查内容**:
- ESLint 代码检查
- Stylelint 样式检查
- TypeScript 类型检查
- 单元测试执行

### 3. 自动修复

```bash
# 自动修复代码问题
npm run quality-check:fix
```

**修复内容**:
- 代码格式化 (Prettier)
- ESLint 自动修复
- Stylelint 自动修复

## 📊 质量指标

### 代码复杂度
- 函数复杂度: ≤ 8
- 文件行数: ≤ 200
- 函数行数: ≤ 30
- 参数个数: ≤ 3
- 嵌套深度: ≤ 3

### 代码质量
- 无未使用变量
- 无重复导入
- 使用 const 而非 let
- 无 console.log (生产环境)
- 无 debugger 语句

### 样式规范
- 2空格缩进
- 单引号字符串
- 无尾随空格
- 统一的分号使用
- 合理的空行

## 🔧 CI/CD 集成

### GitHub Actions 集成

在 `.github/workflows/smart-cicd.yml` 中，前端质量检查任务会执行：

```yaml
- name: Code quality check
  run: |
    cd frontend-taro
    echo "=== 前端代码质量检查 ==="
    
    # ESLint检查 - 使用warn模式，避免因代码风格问题导致失败
    npm run lint || {
      echo "⚠️ ESLint检查发现问题，但继续执行"
      echo "建议：修复代码风格问题以提高代码质量"
    }
    
    # TypeScript检查
    npm run type-check || {
      echo "⚠️ TypeScript类型检查发现问题，但继续执行"
      echo "建议：修复类型错误以提高代码质量"
    }
    
    echo "✅ 前端代码质量检查完成"
```

### 质量门禁

- **通过标准**: 80% 以上检查通过
- **失败处理**: 显示警告但继续执行
- **报告生成**: 自动生成质量报告

## 📝 开发工作流

### 1. 开发前
```bash
# 安装依赖
npm install

# 运行质量检查
npm run quality-check
```

### 2. 开发中
```bash
# 监听模式运行测试
npm run test:watch

# 监听模式类型检查
npm run type-check:watch

# 自动格式化
npm run format
```

### 3. 提交前
```bash
# 运行完整质量检查
npm run quality-check

# 自动修复问题
npm run quality-check:fix
```

### 4. 提交时
- Husky 自动运行 `pre-commit` 钩子
- 执行 `npm run quality-check:simple`

## 🐛 常见问题

### 1. ESLint 错误
```bash
# 查看具体错误
npm run lint

# 自动修复
npm run lint:fix
```

### 2. TypeScript 类型错误
```bash
# 查看类型错误
npm run type-check

# 修复类型定义
# 编辑对应的 .ts/.tsx 文件
```

### 3. 样式检查错误
```bash
# 查看样式错误
npm run lint:css

# 自动修复
npm run lint:css:fix
```

### 4. 测试失败
```bash
# 运行测试查看错误
npm run test

# 修复测试用例
# 编辑对应的 .test.ts/.test.tsx 文件
```

## 📈 质量改进建议

### 1. 代码质量
- 减少函数复杂度
- 提取公共逻辑
- 使用 TypeScript 严格模式
- 增加单元测试覆盖率

### 2. 性能优化
- 避免不必要的重渲染
- 使用 React.memo 和 useMemo
- 优化图片和资源加载
- 减少包体积

### 3. 可维护性
- 统一的代码风格
- 清晰的注释和文档
- 模块化设计
- 错误处理机制

## 🔗 相关链接

- [ESLint 官方文档](https://eslint.org/)
- [Stylelint 官方文档](https://stylelint.io/)
- [Prettier 官方文档](https://prettier.io/)
- [TypeScript 官方文档](https://www.typescriptlang.org/)
- [Jest 官方文档](https://jestjs.io/)
- [Taro 官方文档](https://taro-docs.jd.com/)

---

**注意**: 本指南会随着项目发展持续更新，请定期查看最新版本。
