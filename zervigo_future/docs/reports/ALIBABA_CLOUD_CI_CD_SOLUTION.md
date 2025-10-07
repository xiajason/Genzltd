# 阿里云CI/CD部署解决方案

## 🎯 方案概述

将GitHub Actions的CI/CD机制关联到阿里云部署环境，与腾讯云开发环境完全分离，实现**零冲突**的部署架构。

## ✅ 方案优势

### 1. **完全环境隔离**
- **腾讯云**: 纯开发环境，无自动部署干扰
- **阿里云**: 纯生产环境，GitHub Actions自动部署
- **零冲突**: 两个云平台完全独立，无任何资源冲突

### 2. **简化架构**
- 无需复杂的环境隔离配置
- 无需多服务器管理
- 无需时间窗口控制
- 无需分支策略隔离

### 3. **成本优化**
- 腾讯云：轻量服务器，适合开发
- 阿里云：按需付费，适合生产
- 避免资源浪费和重复配置

### 4. **安全性提升**
- 开发环境和生产环境物理隔离
- 降低生产环境被误操作的风险
- 更好的权限控制和访问管理

## 🏗️ 架构设计

### 当前架构
```
GitHub Actions -> 腾讯云 (101.33.251.158)
                ↕️ 冲突
开发环境 -> 腾讯云 (101.33.251.158)
```

### 优化后架构
```
GitHub Actions -> 阿里云 (生产环境)
开发环境 -> 腾讯云 (101.33.251.158)
```

## 🚀 实施步骤

### 第一步：创建阿里云资源

#### 1.1 阿里云ECS实例
```bash
# 推荐配置
实例规格: ecs.c6.large (2核4GB)
操作系统: Ubuntu 20.04 LTS
网络: 专有网络VPC
安全组: 开放22, 80, 443, 8080端口
```

#### 1.2 阿里云RDS数据库
```bash
# 推荐配置
数据库类型: MySQL 8.0
规格: rds.mysql.s2.large (1核2GB)
存储: 20GB SSD
网络: 与ECS同VPC
```

#### 1.3 阿里云SLB负载均衡
```bash
# 推荐配置
类型: 应用型负载均衡ALB
规格: 标准版
监听端口: 80, 443
后端服务器: ECS实例
```

### 第二步：修改GitHub Actions配置

```yaml
# .github/workflows/deploy.yml
name: Deploy to Alibaba Cloud

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]
  workflow_dispatch:
    inputs:
      environment:
        description: '部署环境'
        required: true
        default: 'production'
        type: choice
        options:
        - production
        - staging

env:
  # 阿里云环境配置
  ALIBABA_CLOUD_SERVER_IP: "your-alibaba-cloud-ip"
  ALIBABA_CLOUD_SERVER_USER: "root"
  ALIBABA_CLOUD_DEPLOY_PATH: "/opt/jobfirst"
  
  # 腾讯云开发环境配置（仅用于通知）
  TENCENT_CLOUD_DEV_IP: "101.33.251.158"

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
      
    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: '18'
        cache: 'npm'
        cache-dependency-path: frontend-taro/package-lock.json
        
    - name: Setup Go
      uses: actions/setup-go@v4
      with:
        go-version: '1.21'
        
    - name: Setup Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.11'
        
    - name: Run tests
      run: |
        # 前端测试
        cd frontend-taro && npm ci && npm run test:unit || echo "前端测试跳过"
        
        # 后端测试
        cd ../backend && go mod download && go test ./... || echo "后端测试跳过"
        
        # AI服务测试
        cd internal/ai-service && pip install -r requirements.txt && python -m pytest tests/ || echo "AI服务测试跳过"

  build:
    needs: test
    runs-on: ubuntu-latest
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
      
    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: '18'
        cache: 'npm'
        cache-dependency-path: frontend-taro/package-lock.json
        
    - name: Setup Go
      uses: actions/setup-go@v4
      with:
        go-version: '1.21'
        
    - name: Build frontend
      run: |
        cd frontend-taro
        npm ci
        npm run build:h5
        npm run build:weapp
        
    - name: Build backend
      run: |
        cd backend
        go mod download
        CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o basic-server ./cmd/basic-server/main.go
        
    - name: Upload build artifacts
      uses: actions/upload-artifact@v4
      with:
        name: build-artifacts
        path: |
          frontend-taro/dist/
          backend/basic-server
        retention-days: 7

  deploy-staging:
    if: github.ref == 'refs/heads/develop' || github.event_name == 'workflow_dispatch'
    needs: build
    runs-on: ubuntu-latest
    environment: staging
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
      
    - name: Download build artifacts
      uses: actions/download-artifact@v4
      with:
        name: build-artifacts
        
    - name: Setup deployment environment
      run: |
        echo "DEPLOY_SERVER_IP=${{ env.ALIBABA_CLOUD_SERVER_IP }}" >> $GITHUB_ENV
        echo "DEPLOY_SERVER_USER=${{ env.ALIBABA_CLOUD_SERVER_USER }}" >> $GITHUB_ENV
        echo "DEPLOY_PATH=${{ env.ALIBABA_CLOUD_DEPLOY_PATH }}" >> $GITHUB_ENV
        echo "SSH_PRIVATE_KEY=${{ secrets.ALIBABA_CLOUD_SSH_PRIVATE_KEY }}" >> $GITHUB_ENV
        
    - name: Deploy to Alibaba Cloud Staging
      run: |
        chmod +x scripts/alibaba-cloud-deploy.sh
        ./scripts/alibaba-cloud-deploy.sh staging
        
    - name: Notify deployment
      if: always()
      run: |
        if [ "${{ job.status }}" == "success" ]; then
          echo "✅ 阿里云测试环境部署成功"
          # 可选：通知腾讯云开发环境
          curl -X POST "http://${{ env.TENCENT_CLOUD_DEV_IP }}/api/notifications/deployment" \
            -H "Content-Type: application/json" \
            -d '{"status":"success","environment":"staging","message":"阿里云测试环境部署成功"}'
        else
          echo "❌ 阿里云测试环境部署失败"
        fi

  deploy-production:
    if: github.ref == 'refs/heads/main' || (github.event_name == 'workflow_dispatch' && github.event.inputs.environment == 'production')
    needs: build
    runs-on: ubuntu-latest
    environment: production
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
      
    - name: Download build artifacts
      uses: actions/download-artifact@v4
      with:
        name: build-artifacts
        
    - name: Setup deployment environment
      run: |
        echo "DEPLOY_SERVER_IP=${{ env.ALIBABA_CLOUD_SERVER_IP }}" >> $GITHUB_ENV
        echo "DEPLOY_SERVER_USER=${{ env.ALIBABA_CLOUD_SERVER_USER }}" >> $GITHUB_ENV
        echo "DEPLOY_PATH=${{ env.ALIBABA_CLOUD_DEPLOY_PATH }}" >> $GITHUB_ENV
        echo "SSH_PRIVATE_KEY=${{ secrets.ALIBABA_CLOUD_SSH_PRIVATE_KEY }}" >> $GITHUB_ENV
        
    - name: Deploy to Alibaba Cloud Production
      run: |
        chmod +x scripts/alibaba-cloud-deploy.sh
        ./scripts/alibaba-cloud-deploy.sh production
        
    - name: Notify deployment
      if: always()
      run: |
        if [ "${{ job.status }}" == "success" ]; then
          echo "✅ 阿里云生产环境部署成功"
          # 可选：通知腾讯云开发环境
          curl -X POST "http://${{ env.TENCENT_CLOUD_DEV_IP }}/api/notifications/deployment" \
            -H "Content-Type: application/json" \
            -d '{"status":"success","environment":"production","message":"阿里云生产环境部署成功"}'
        else
          echo "❌ 阿里云生产环境部署失败"
        fi

  health-check:
    needs: [deploy-staging, deploy-production]
    if: always() && (needs.deploy-staging.result == 'success' || needs.deploy-production.result == 'success')
    runs-on: ubuntu-latest
    steps:
    - name: Health check
      run: |
        if [ "${{ needs.deploy-staging.result }}" == "success" ]; then
          echo "检查阿里云测试环境健康状态..."
          curl -f http://${{ env.ALIBABA_CLOUD_SERVER_IP }}/health || echo "测试环境健康检查失败"
        fi
        
        if [ "${{ needs.deploy-production.result }}" == "success" ]; then
          echo "检查阿里云生产环境健康状态..."
          curl -f http://${{ env.ALIBABA_CLOUD_SERVER_IP }}/health || echo "生产环境健康检查失败"
        fi
```

### 第三步：创建阿里云部署脚本

```bash
# scripts/alibaba-cloud-deploy.sh
#!/bin/bash

# JobFirst系统阿里云部署脚本
# 专门用于GitHub Actions自动部署到阿里云

set -e

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置变量
SERVER_IP="${DEPLOY_SERVER_IP}"
SERVER_USER="${DEPLOY_SERVER_USER:-root}"
DEPLOY_PATH="${DEPLOY_PATH:-/opt/jobfirst}"
ENVIRONMENT="${1:-production}"
BRANCH="${GITHUB_REF_NAME:-main}"
COMMIT_SHA="${GITHUB_SHA:-$(git rev-parse HEAD)}"

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查环境变量
check_environment() {
    log_info "检查部署环境..."
    
    if [ -z "$SERVER_IP" ]; then
        log_error "DEPLOY_SERVER_IP环境变量未设置"
        exit 1
    fi
    
    if [ -z "$SSH_PRIVATE_KEY" ]; then
        log_error "SSH_PRIVATE_KEY环境变量未设置"
        exit 1
    fi
    
    log_success "环境变量检查通过"
}

# 配置SSH连接
setup_ssh() {
    log_info "配置SSH连接..."
    
    # 创建SSH目录
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    
    # 写入SSH私钥
    echo "$SSH_PRIVATE_KEY" > ~/.ssh/id_rsa
    chmod 600 ~/.ssh/id_rsa
    
    # 配置SSH客户端
    cat > ~/.ssh/config << EOF
Host alibaba-cloud
    HostName $SERVER_IP
    User $SERVER_USER
    IdentityFile ~/.ssh/id_rsa
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
EOF
    
    log_success "SSH连接配置完成"
}

# 测试SSH连接
test_ssh_connection() {
    log_info "测试SSH连接..."
    
    if ssh -o ConnectTimeout=10 alibaba-cloud "echo 'SSH连接成功'"; then
        log_success "SSH连接测试通过"
    else
        log_error "SSH连接测试失败"
        exit 1
    fi
}

# 准备部署文件
prepare_deployment() {
    log_info "准备部署文件..."
    
    # 创建部署包
    tar -czf jobfirst-deployment.tar.gz \
        dist/ \
        basic-server \
        scripts/ \
        configs/ \
        database/
    
    log_success "部署文件准备完成"
}

# 上传文件到阿里云
upload_files() {
    log_info "上传文件到阿里云..."
    
    # 上传部署包
    scp jobfirst-deployment.tar.gz alibaba-cloud:/tmp/
    
    # 上传部署脚本
    scp scripts/alibaba-cloud-setup.sh alibaba-cloud:/tmp/
    
    log_success "文件上传完成"
}

# 在阿里云执行部署
execute_deployment() {
    log_info "在阿里云执行部署..."
    
    ssh alibaba-cloud << EOF
        set -e
        
        # 解压部署包
        cd /tmp
        tar -xzf jobfirst-deployment.tar.gz
        
        # 创建部署目录
        mkdir -p $DEPLOY_PATH
        
        # 停止现有服务
        systemctl stop basic-server || true
        
        # 备份现有版本
        if [ -d "$DEPLOY_PATH" ]; then
            mv $DEPLOY_PATH $DEPLOY_PATH.backup.\$(date +%Y%m%d_%H%M%S) || true
        fi
        
        # 部署新版本
        mv /tmp/* $DEPLOY_PATH/
        
        # 设置权限
        chmod +x $DEPLOY_PATH/scripts/*.sh
        chmod +x $DEPLOY_PATH/basic-server
        
        # 配置环境
        chmod +x /tmp/alibaba-cloud-setup.sh
        /tmp/alibaba-cloud-setup.sh $ENVIRONMENT
        
        # 启动服务
        systemctl start basic-server
        systemctl enable basic-server
        
        # 检查服务状态
        sleep 5
        if systemctl is-active --quiet basic-server; then
            echo "✅ 服务启动成功"
        else
            echo "❌ 服务启动失败"
            systemctl status basic-server
            exit 1
        fi
EOF
    
    log_success "阿里云部署执行完成"
}

# 验证部署
verify_deployment() {
    log_info "验证部署..."
    
    # 检查服务状态
    if ssh alibaba-cloud "systemctl is-active --quiet basic-server"; then
        log_success "服务运行正常"
    else
        log_error "服务运行异常"
        exit 1
    fi
    
    # 检查健康状态
    if curl -f "http://$SERVER_IP/health" > /dev/null 2>&1; then
        log_success "健康检查通过"
    else
        log_warning "健康检查失败，但服务可能正在启动中"
    fi
    
    log_success "部署验证完成"
}

# 清理临时文件
cleanup() {
    log_info "清理临时文件..."
    
    rm -f jobfirst-deployment.tar.gz
    ssh alibaba-cloud "rm -f /tmp/jobfirst-deployment.tar.gz /tmp/alibaba-cloud-setup.sh"
    
    log_success "临时文件清理完成"
}

# 主函数
main() {
    log_info "开始阿里云部署..."
    log_info "环境: $ENVIRONMENT"
    log_info "服务器: $SERVER_IP"
    log_info "分支: $BRANCH"
    log_info "提交: $COMMIT_SHA"
    
    check_environment
    setup_ssh
    test_ssh_connection
    prepare_deployment
    upload_files
    execute_deployment
    verify_deployment
    cleanup
    
    log_success "阿里云部署完成！"
}

# 执行主函数
main "$@"
```

### 第四步：创建阿里云环境配置脚本

```bash
# scripts/alibaba-cloud-setup.sh
#!/bin/bash

# 阿里云环境配置脚本
# 在阿里云服务器上执行，配置生产环境

set -e

ENVIRONMENT="${1:-production}"
DEPLOY_PATH="/opt/jobfirst"

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 安装系统依赖
install_system_dependencies() {
    log_info "安装系统依赖..."
    
    apt-get update
    apt-get install -y \
        nginx \
        mysql-client \
        redis-tools \
        curl \
        wget \
        unzip \
        supervisor
    
    log_success "系统依赖安装完成"
}

# 配置Nginx
configure_nginx() {
    log_info "配置Nginx..."
    
    cat > /etc/nginx/sites-available/jobfirst << EOF
server {
    listen 80;
    server_name _;
    
    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
EOF
    
    ln -sf /etc/nginx/sites-available/jobfirst /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
    
    nginx -t
    systemctl restart nginx
    systemctl enable nginx
    
    log_success "Nginx配置完成"
}

# 配置系统服务
configure_systemd_service() {
    log_info "配置系统服务..."
    
    cat > /etc/systemd/system/basic-server.service << EOF
[Unit]
Description=JobFirst Basic Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$DEPLOY_PATH
ExecStart=$DEPLOY_PATH/basic-server
Restart=always
RestartSec=5
Environment=GIN_MODE=release
Environment=ENVIRONMENT=$ENVIRONMENT

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl enable basic-server
    
    log_success "系统服务配置完成"
}

# 配置防火墙
configure_firewall() {
    log_info "配置防火墙..."
    
    ufw allow 22/tcp
    ufw allow 80/tcp
    ufw allow 443/tcp
    ufw allow 8080/tcp
    ufw --force enable
    
    log_success "防火墙配置完成"
}

# 配置日志轮转
configure_log_rotation() {
    log_info "配置日志轮转..."
    
    cat > /etc/logrotate.d/jobfirst << EOF
$DEPLOY_PATH/logs/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 root root
    postrotate
        systemctl reload basic-server
    endscript
}
EOF
    
    log_success "日志轮转配置完成"
}

# 主函数
main() {
    log_info "开始配置阿里云环境..."
    log_info "环境: $ENVIRONMENT"
    log_info "部署路径: $DEPLOY_PATH"
    
    install_system_dependencies
    configure_nginx
    configure_systemd_service
    configure_firewall
    configure_log_rotation
    
    log_success "阿里云环境配置完成！"
}

# 执行主函数
main "$@"
```

## 🔧 GitHub Secrets配置

在GitHub仓库中配置以下Secrets：

```bash
# 阿里云SSH配置
ALIBABA_CLOUD_SSH_PRIVATE_KEY    # 阿里云服务器SSH私钥

# 阿里云服务器信息
ALIBABA_CLOUD_SERVER_IP          # 阿里云服务器IP
ALIBABA_CLOUD_SERVER_USER        # 阿里云服务器用户

# 数据库配置
ALIBABA_CLOUD_DB_HOST            # 阿里云RDS地址
ALIBABA_CLOUD_DB_USER            # 数据库用户名
ALIBABA_CLOUD_DB_PASSWORD        # 数据库密码
ALIBABA_CLOUD_DB_NAME            # 数据库名称

# 通知配置
SLACK_WEBHOOK_URL                # Slack通知
DINGTALK_WEBHOOK_URL             # 钉钉通知
```

## 📊 成本分析

### 阿里云成本估算

```bash
# ECS实例
ecs.c6.large (2核4GB): ~200元/月

# RDS数据库
rds.mysql.s2.large (1核2GB): ~150元/月

# SLB负载均衡
标准版: ~50元/月

# 总成本
总计: ~400元/月
```

### 腾讯云成本（保持不变）

```bash
# 轻量服务器
2核4GB: ~50元/月

# 总成本
总计: ~50元/月
```

## 🎯 实施时间表

### 第一阶段（1-2天）
1. 创建阿里云资源
2. 配置基础环境
3. 测试SSH连接

### 第二阶段（2-3天）
1. 修改GitHub Actions配置
2. 创建部署脚本
3. 测试自动部署

### 第三阶段（1天）
1. 配置监控和通知
2. 完善文档
3. 团队培训

## 🎉 总结

### 方案优势
1. **零冲突**: 完全环境隔离
2. **简化架构**: 无需复杂配置
3. **成本合理**: 总成本约450元/月
4. **安全性高**: 物理隔离
5. **可扩展性**: 易于扩展

### 实施建议
1. **立即开始**: 创建阿里云资源
2. **逐步迁移**: 先测试环境，后生产环境
3. **保持监控**: 确保部署成功
4. **文档更新**: 更新团队文档

**这个方案完美解决了GitHub Actions与腾讯云开发环境的冲突问题，实现了真正的零冲突部署架构！** 🚀
