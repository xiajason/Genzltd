# Basic Server集群开发环境脚本

## 📋 概述

这些脚本用于在单机上启动多个Basic Server实例，模拟集群环境进行开发和测试。

## 🚀 快速开始

### 1. 启动集群
```bash
./start-cluster-dev.sh
```

### 2. 检查集群状态
```bash
./check-cluster-status.sh
```

### 3. 停止集群
```bash
./stop-cluster-dev.sh
```

## 📁 脚本说明

### start-cluster-dev.sh
**功能**: 启动Basic Server集群开发环境
- 检查依赖（Go、MySQL、Redis）
- 编译Basic Server
- 启动3个Basic Server实例（端口8080、8180、8280）
- 等待服务启动并验证健康状态
- 显示集群状态和访问信息

### stop-cluster-dev.sh
**功能**: 停止Basic Server集群
- 优雅停止所有Basic Server实例
- 清理PID文件
- 检查端口释放状态
- 验证进程停止状态

### check-cluster-status.sh
**功能**: 检查集群状态
- 检查进程运行状态
- 检查端口占用情况
- 验证各节点健康状态
- 获取集群状态信息
- 显示节点详细信息

## 🔧 配置说明

### 环境变量
每个Basic Server实例使用以下环境变量：
- `NODE_ID`: 节点标识符
- `NODE_PORT`: 服务端口

### 端口分配
- **Node 1**: 8080 (主服务端口，保持兼容性)
- **Node 2**: 8180 (集群节点2)
- **Node 3**: 8280 (集群节点3)

### 日志文件
- Node 1: `basic/logs/basic-server-node1.log`
- Node 2: `basic/logs/basic-server-node2.log`
- Node 3: `basic/logs/basic-server-node3.log`

## 🌐 访问地址

### 服务地址
- Node 1: http://localhost:8080 (主服务)
- Node 2: http://localhost:8180 (集群节点)
- Node 3: http://localhost:8280 (集群节点)

### 集群API
- 健康检查: `/health`
- 集群状态: `/api/v1/cluster/status`
- 节点信息: `/api/v1/cluster/nodes`

## 📊 集群架构

```
┌─────────────────────────────────────────────────────────┐
│                Basic Server 集群                        │
├─────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐      │
│  │Basic Server │  │Basic Server │  │Basic Server │      │
│  │   Node 1    │  │   Node 2    │  │   Node 3    │      │
│  │  (8080)     │  │  (8180)     │  │  (8280)     │      │
│  │             │  │             │  │             │      │
│  │ 集群管理器   │  │ 集群管理器   │  │ 集群管理器   │      │
│  └─────────────┘  └─────────────┘  └─────────────┘      │
└─────────────────────────────────────────────────────────┘
```

## 🔍 故障排除

### 常见问题

1. **端口被占用**
   ```bash
   # 检查端口占用
   lsof -i :8080
   lsof -i :8180
   lsof -i :8280
   
   # 停止占用进程
   kill -9 <PID>
   ```

2. **服务启动失败**
   ```bash
   # 查看日志
   tail -f basic/logs/basic-server-node1.log
   tail -f basic/logs/basic-server-node2.log
   tail -f basic/logs/basic-server-node3.log
   ```

3. **健康检查失败**
   ```bash
   # 手动检查健康状态
   curl http://localhost:8080/health
   curl http://localhost:8180/health
   curl http://localhost:8280/health
   ```

### 日志分析

每个节点的日志包含：
- 服务启动信息
- 集群管理器状态
- 节点注册信息
- 健康检查结果
- 错误和警告信息

## 🎯 开发建议

1. **开发环境**: 使用单机多端口部署进行开发测试
2. **生产环境**: 使用多机部署，每台机器运行一个Basic Server实例
3. **监控**: 定期检查集群状态和日志文件
4. **测试**: 使用集群API验证各节点功能

## 📝 注意事项

- 确保MySQL和Redis服务正在运行
- 检查端口8080、8180、8280未被其他服务占用
- 定期清理日志文件避免磁盘空间不足
- 在生产环境中使用前进行充分测试
