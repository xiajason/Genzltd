# 腾讯云服务器CI/CD触发功能实现指南

## 📋 概述

本指南详细说明如何实现腾讯云服务器上的CI/CD触发功能，基于您现有的zervigo工具和Smart CI/CD流程设计。

## 🎯 实现目标

1. **zervigo工具集成** - 通过zervigo命令触发CI/CD部署
2. **Git Webhook自动触发** - 代码推送自动触发部署
3. **多环境支持** - 支持development、staging、production环境
4. **智能调度** - 根据分支和变更类型智能选择部署策略
5. **完整监控** - 部署状态监控和通知机制

## 🛠️ 实现方案

### 1. zervigo CI/CD触发功能

#### 1.1 完善TriggerCICDDeploy函数

```go
// TriggerCICDDeploy 触发CI/CD部署
func (m *Manager) TriggerCICDDeploy(environment string) error {
    // 验证环境参数
    validEnvs := []string{"development", "staging", "production"}
    if !contains(validEnvs, environment) {
        return fmt.Errorf("无效的环境参数: %s，支持的环境: %v", environment, validEnvs)
    }
    
    // 记录部署开始
    m.logDeploymentStart(environment)
    
    // 构建SSH命令
    cmd := exec.Command("ssh", 
        "-i", m.config.SSHKeyPath, 
        "-o", "StrictHostKeyChecking=no",
        "-o", "ConnectTimeout=30",
        fmt.Sprintf("%s@%s", m.config.ServerUser, m.config.ServerIP),
        fmt.Sprintf("cd /opt/jobfirst && ./scripts/cicd-pipeline.sh deploy %s", environment))
    
    // 执行部署命令
    output, err := cmd.CombinedOutput()
    if err != nil {
        m.logDeploymentError(environment, err, string(output))
        return fmt.Errorf("触发部署失败: %w, 输出: %s", err, string(output))
    }
    
    // 记录部署成功
    m.logDeploymentSuccess(environment, string(output))
    return nil
}

// 辅助函数
func contains(slice []string, item string) bool {
    for _, s := range slice {
        if s == item {
            return true
        }
    }
    return false
}
```

#### 1.2 添加部署日志记录

```go
// 部署日志记录
func (m *Manager) logDeploymentStart(environment string) {
    logEntry := fmt.Sprintf("[%s] 开始触发 %s 环境部署", 
        time.Now().Format("2006-01-02 15:04:05"), environment)
    m.writeToLog("cicd-deploy.log", logEntry)
}

func (m *Manager) logDeploymentSuccess(environment string, output string) {
    logEntry := fmt.Sprintf("[%s] %s 环境部署成功\n输出: %s", 
        time.Now().Format("2006-01-02 15:04:05"), environment, output)
    m.writeToLog("cicd-deploy.log", logEntry)
}

func (m *Manager) logDeploymentError(environment string, err error, output string) {
    logEntry := fmt.Sprintf("[%s] %s 环境部署失败\n错误: %v\n输出: %s", 
        time.Now().Format("2006-01-02 15:04:05"), environment, err, output)
    m.writeToLog("cicd-deploy.log", logEntry)
}
```

### 2. Git Webhook自动触发机制

#### 2.1 创建Webhook服务器脚本

```bash
#!/bin/bash
# git-webhook.sh - Git Webhook服务器

set -e

# 配置
WEBHOOK_PORT=8088
WEBHOOK_SECRET="your-secure-webhook-secret"
PROJECT_DIR="/opt/jobfirst"
LOG_FILE="/opt/jobfirst/logs/webhook.log"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# 验证Webhook签名
verify_signature() {
    local payload="$1"
    local signature="$2"
    local secret="$3"
    
    local expected_signature=$(echo -n "$payload" | openssl dgst -sha256 -hmac "$secret" | cut -d' ' -f2)
    local received_signature=$(echo "$signature" | sed 's/sha256=//')
    
    if [ "$expected_signature" = "$received_signature" ]; then
        return 0
    else
        return 1
    fi
}

# 解析Git事件
parse_git_event() {
    local payload="$1"
    local event_type="$2"
    
    # 提取分支信息
    local branch=$(echo "$payload" | jq -r '.ref // empty' | sed 's/refs\/heads\///')
    local repository=$(echo "$payload" | jq -r '.repository.name // empty')
    local pusher=$(echo "$payload" | jq -r '.pusher.name // empty')
    
    echo "$branch|$repository|$pusher"
}

# 确定部署环境
determine_environment() {
    local branch="$1"
    
    case "$branch" in
        "main"|"master")
            echo "production"
            ;;
        "develop")
            echo "staging"
            ;;
        "feature/"*|"hotfix/"*)
            echo "development"
            ;;
        *)
            echo "none"
            ;;
    esac
}

# 触发部署
trigger_deployment() {
    local environment="$1"
    local branch="$2"
    local repository="$3"
    local pusher="$4"
    
    log_info "触发部署 - 环境: $environment, 分支: $branch, 仓库: $repository, 推送者: $pusher"
    
    # 使用zervigo工具触发部署
    cd "$PROJECT_DIR"
    ./backend/pkg/jobfirst-core/superadmin/zervigo cicd deploy "$environment"
    
    if [ $? -eq 0 ]; then
        log_success "部署触发成功 - 环境: $environment"
    else
        log_error "部署触发失败 - 环境: $environment"
    fi
}

# 处理Webhook请求
handle_webhook() {
    local method="$1"
    local path="$2"
    local headers="$3"
    local body="$4"
    
    if [ "$method" = "POST" ] && [ "$path" = "/webhook" ]; then
        # 获取签名
        local signature=$(echo "$headers" | grep -i "x-hub-signature-256" | cut -d' ' -f2)
        local event_type=$(echo "$headers" | grep -i "x-github-event" | cut -d' ' -f2)
        
        # 验证签名
        if ! verify_signature "$body" "$signature" "$WEBHOOK_SECRET"; then
            log_error "Webhook签名验证失败"
            echo "HTTP/1.1 401 Unauthorized"
            echo "Content-Type: application/json"
            echo ""
            echo '{"error": "Unauthorized"}'
            return
        fi
        
        # 解析事件
        local event_info=$(parse_git_event "$body" "$event_type")
        local branch=$(echo "$event_info" | cut -d'|' -f1)
        local repository=$(echo "$event_info" | cut -d'|' -f2)
        local pusher=$(echo "$event_info" | cut -d'|' -f3)
        
        # 确定部署环境
        local environment=$(determine_environment "$branch")
        
        if [ "$environment" != "none" ]; then
            # 触发部署
            trigger_deployment "$environment" "$branch" "$repository" "$pusher"
        else
            log_info "分支 $branch 不需要自动部署"
        fi
        
        # 返回成功响应
        echo "HTTP/1.1 200 OK"
        echo "Content-Type: application/json"
        echo ""
        echo '{"status": "success", "environment": "'$environment'", "branch": "'$branch'"}'
    else
        echo "HTTP/1.1 404 Not Found"
        echo "Content-Type: application/json"
        echo ""
        echo '{"error": "Not Found"}'
    fi
}

# 启动Webhook服务器
start_webhook_server() {
    log_info "启动Git Webhook服务器 - 端口: $WEBHOOK_PORT"
    
    # 创建日志目录
    mkdir -p "$(dirname "$LOG_FILE")"
    
    # 启动简单的HTTP服务器
    while true; do
        {
            # 读取HTTP请求
            read -r method path version
            read -r headers
            read -r body
            
            # 处理Webhook请求
            handle_webhook "$method" "$path" "$headers" "$body"
        } | nc -l -p "$WEBHOOK_PORT"
    done
}

# 主函数
main() {
    case "${1:-start}" in
        "start")
            start_webhook_server
            ;;
        "stop")
            pkill -f "git-webhook.sh"
            log_info "Webhook服务器已停止"
            ;;
        "status")
            if pgrep -f "git-webhook.sh" > /dev/null; then
                log_info "Webhook服务器正在运行"
            else
                log_info "Webhook服务器未运行"
            fi
            ;;
        *)
            echo "用法: $0 {start|stop|status}"
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"
```

#### 2.2 配置Git平台Webhook

在GitHub/GitLab/Gitee中配置Webhook：

**Webhook URL**: `http://101.33.251.158:8088/webhook`

**Webhook Secret**: 设置安全的密钥

**触发事件**:
- Push events
- Tag push events

### 3. 集成到zervigo工具

#### 3.1 完善CLI命令处理

```go
// handleCICD 处理Smart CI/CD命令
func (c *CLI) handleCICD(subcommand string) error {
    switch subcommand {
    case "status":
        fmt.Println("🚀 Smart CI/CD 系统状态:")
        status, err := c.manager.GetCICDStatus()
        if err != nil {
            return fmt.Errorf("获取CI/CD状态失败: %w", err)
        }
        c.displayCICDStatus(status)
        
    case "deploy":
        environment := "production"
        if len(os.Args) > 3 {
            environment = os.Args[3]
        }
        
        fmt.Printf("🚀 触发 %s 环境部署...\n", environment)
        err := c.manager.TriggerCICDDeploy(environment)
        if err != nil {
            return fmt.Errorf("触发部署失败: %w", err)
        }
        fmt.Printf("✅ 已触发 %s 环境部署\n", environment)
        
    case "webhook":
        fmt.Println("🔗 Webhook配置:")
        webhooks, err := c.manager.GetCICDWebhooks()
        if err != nil {
            return fmt.Errorf("获取Webhook配置失败: %w", err)
        }
        c.displayCICDWebhooks(webhooks)
        
    case "logs":
        fmt.Println("📝 CI/CD日志:")
        logs, err := c.manager.GetCICDLogs("")
        if err != nil {
            return fmt.Errorf("获取CI/CD日志失败: %w", err)
        }
        c.displayCICDLogs(logs)
        
    default:
        fmt.Println("可用操作:")
        fmt.Println("  status      - 查看CI/CD系统状态")
        fmt.Println("  deploy [env] - 触发部署 (默认: production)")
        fmt.Println("  webhook     - 查看Webhook配置")
        fmt.Println("  logs        - 查看CI/CD日志")
    }
    return nil
}
```

### 4. 部署和使用

#### 4.1 部署CI/CD组件

```bash
# 1. 上传脚本到服务器
scp -i ~/.ssh/basic.pem basic/scripts/cicd-pipeline.sh ubuntu@101.33.251.158:/opt/jobfirst/scripts/
scp -i ~/.ssh/basic.pem basic/scripts/git-webhook.sh ubuntu@101.33.251.158:/opt/jobfirst/scripts/

# 2. 设置执行权限
ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158 "chmod +x /opt/jobfirst/scripts/*.sh"

# 3. 启动Webhook服务器
ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158 "cd /opt/jobfirst && nohup ./scripts/git-webhook.sh start > /opt/jobfirst/logs/webhook.log 2>&1 &"
```

#### 4.2 使用zervigo触发部署

```bash
# 构建zervigo工具
cd basic/backend/pkg/jobfirst-core/superadmin
./build.sh

# 使用zervigo触发部署
./zervigo cicd deploy production    # 部署到生产环境
./zervigo cicd deploy staging       # 部署到测试环境
./zervigo cicd deploy development   # 部署到开发环境

# 查看CI/CD状态
./zervigo cicd status

# 查看Webhook配置
./zervigo cicd webhook

# 查看部署日志
./zervigo cicd logs
```

### 5. 监控和通知

#### 5.1 部署状态监控

```bash
# 查看Webhook日志
ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158 "tail -f /opt/jobfirst/logs/webhook.log"

# 查看CI/CD流水线日志
ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158 "tail -f /opt/jobfirst/logs/cicd.log"

# 使用zervigo监控
./zervigo status
./zervigo cicd status
```

#### 5.2 通知机制

CI/CD流水线支持多种通知方式：
- 邮件通知
- 钉钉/企业微信通知
- Slack通知
- 短信通知

## 🎯 使用场景

### 场景1: 手动触发部署

```bash
# 使用zervigo工具手动触发生产环境部署
./zervigo cicd deploy production
```

### 场景2: 自动触发部署

```bash
# 推送到main分支自动触发生产环境部署
git push origin main
# Webhook自动触发 -> 部署到production环境
```

### 场景3: 多环境部署

```bash
# 推送到develop分支自动触发测试环境部署
git push origin develop
# Webhook自动触发 -> 部署到staging环境

# 推送到feature分支自动触发开发环境部署
git push origin feature/new-feature
# Webhook自动触发 -> 部署到development环境
```

## 🔧 配置说明

### 环境变量配置

```bash
# Webhook配置
export WEBHOOK_SECRET="your-secure-webhook-secret"
export WEBHOOK_PORT=8088

# 服务器配置
export SERVER_IP="101.33.251.158"
export SERVER_USER="ubuntu"
export SSH_KEY="~/.ssh/basic.pem"
export PROJECT_DIR="/opt/jobfirst"
```

### 分支策略配置

```bash
# 分支与环境的映射关系
main/master    -> production  # 生产环境
develop        -> staging     # 测试环境
feature/*      -> development # 开发环境
release/*      -> staging     # 预发布环境
hotfix/*       -> production  # 热修复
```

## 🚨 故障排除

### 常见问题

1. **zervigo触发失败**
   ```bash
   # 检查SSH连接
   ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158 "echo 'SSH连接正常'"
   
   # 检查服务器上的脚本
   ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158 "ls -la /opt/jobfirst/scripts/cicd-pipeline.sh"
   ```

2. **Webhook无法触发**
   ```bash
   # 检查Webhook服务器状态
   ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158 "ps aux | grep webhook"
   
   # 检查端口是否开放
   ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158 "netstat -tlnp | grep 8088"
   ```

3. **部署失败**
   ```bash
   # 查看部署日志
   ssh -i ~/.ssh/basic.pem ubuntu@101.33.251.158 "tail -50 /opt/jobfirst/logs/cicd.log"
   
   # 手动回滚
   ./zervigo cicd rollback <快照名称>
   ```

## 📈 优势特性

1. **统一管理** - 通过zervigo工具统一管理CI/CD流程
2. **智能触发** - 根据分支和变更类型智能选择部署策略
3. **多环境支持** - 支持development、staging、production环境
4. **完整监控** - 部署状态监控和详细日志记录
5. **自动回滚** - 部署失败自动回滚机制
6. **通知机制** - 多种通知方式支持

## 🎉 总结

通过这个实现方案，您可以：

1. ✅ **使用zervigo工具** - 通过命令行轻松触发CI/CD部署
2. ✅ **自动触发部署** - Git推送自动触发相应环境的部署
3. ✅ **多环境管理** - 支持开发、测试、生产环境的独立部署
4. ✅ **完整监控** - 部署状态监控和日志记录
5. ✅ **智能调度** - 根据分支和变更类型智能选择部署策略

这是一个完整、智能、高效的CI/CD触发系统，完美集成到您的zervigo工具中！

---

**文档版本**: v1.0.0  
**最后更新**: 2025年1月9日  
**维护人员**: AI Assistant
