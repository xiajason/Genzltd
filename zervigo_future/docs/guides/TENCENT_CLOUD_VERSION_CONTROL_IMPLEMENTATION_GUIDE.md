# 腾讯云轻量服务器版本控制实施方案

## 📋 项目概述

**目标**: 在腾讯云轻量服务器上建立完整的版本控制系统，支持团队协作开发和自动化部署。

**资源**: 轻量应用服务器、轻量对象存储、DNS解析、SSL证书、企业网盘、数据万象CI

**方案**: 方案B - 增强版本控制方案

---

## 🚀 第一阶段：基础设置

### 1.1 在轻量应用服务器上配置Git仓库

#### 步骤1：初始化Git仓库
```bash
# 连接到服务器
ssh root@101.33.251.158

# 进入项目目录
cd /opt/jobfirst

# 初始化Git仓库
git init

# 设置Git配置
git config user.name "Tencent Cloud Server"
git config user.email "server@jobfirst.com"

# 查看当前状态
git status
```

#### 步骤2：创建.gitignore文件
```bash
# 创建.gitignore文件
cat > .gitignore << 'EOF'
# 日志文件
*.log
logs/

# 临时文件
tmp/
temp/

# 备份文件
backup/
*.backup

# 数据库文件
*.db
*.sqlite

# 配置文件（包含敏感信息）
config/secrets.yaml
config/database.yaml

# 进程文件
*.pid

# 上传文件
uploads/

# 版本备份
/opt/backup/versions/
EOF
```

#### 步骤3：创建初始提交
```bash
# 添加所有文件
git add .

# 创建初始提交
git commit -m "Initial commit: JobFirst system deployment"

# 查看提交历史
git log --oneline
```

### 1.2 设置轻量对象存储作为备份

#### 步骤1：安装COS命令行工具
```bash
# 下载COS命令行工具
wget https://cosbrowser.cloud.tencent.com/software/coscli/coscli-linux

# 重命名并设置权限
mv coscli-linux coscli
chmod +x coscli

# 移动到系统路径
sudo mv coscli /usr/local/bin/
```

#### 步骤2：配置COS访问
```bash
# 配置COS访问密钥
coscli config set

# 输入以下信息：
# Secret ID: [您的Secret ID]
# Secret Key: [您的Secret Key]
# Region: ap-beijing
# Bucket: [您的存储桶名称]
```

#### 步骤3：创建备份脚本
```bash
# 创建COS备份脚本
cat > scripts/backup-to-cos.sh << 'EOF'
#!/bin/bash

# COS备份脚本
BUCKET_NAME="your-bucket-name"
BACKUP_DIR="/opt/backup/versions"
COS_PATH="jobfirst/backups/"

log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1"
}

log_info "开始备份到COS..."

# 备份版本文件
if [ -d "$BACKUP_DIR" ]; then
    log_info "备份版本文件到COS..."
    coscli sync "$BACKUP_DIR" "cos://$BUCKET_NAME/$COS_PATH" --delete
    
    if [ $? -eq 0 ]; then
        log_info "备份成功！"
    else
        log_info "备份失败！"
        exit 1
    fi
else
    log_info "备份目录不存在，跳过备份"
fi
EOF

# 设置执行权限
chmod +x scripts/backup-to-cos.sh
```

### 1.3 配置DNS解析和SSL证书

#### 步骤1：配置DNS解析
```bash
# 在腾讯云控制台配置DNS解析
# 1. 登录腾讯云控制台
# 2. 进入DNS解析控制台
# 3. 添加A记录：
#    - 主机记录: jobfirst
#    - 记录类型: A
#    - 记录值: 101.33.251.158
#    - TTL: 600
```

#### 步骤2：配置SSL证书
```bash
# 在腾讯云控制台配置SSL证书
# 1. 登录腾讯云控制台
# 2. 进入SSL证书控制台
# 3. 申请单域名证书
# 4. 下载证书文件

# 创建证书目录
mkdir -p /opt/jobfirst/ssl

# 上传证书文件到服务器
# scp your-cert.crt root@101.33.251.158:/opt/jobfirst/ssl/
# scp your-key.key root@101.33.251.158:/opt/jobfirst/ssl/
```

#### 步骤3：配置Nginx SSL
```bash
# 创建Nginx SSL配置
cat > /etc/nginx/sites-available/jobfirst-ssl << 'EOF'
server {
    listen 80;
    server_name jobfirst.yourdomain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl;
    server_name jobfirst.yourdomain.com;

    ssl_certificate /opt/jobfirst/ssl/your-cert.crt;
    ssl_certificate_key /opt/jobfirst/ssl/your-key.key;

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# 启用站点
ln -s /etc/nginx/sites-available/jobfirst-ssl /etc/nginx/sites-enabled/

# 测试配置
nginx -t

# 重启Nginx
systemctl restart nginx
```

---

## 👥 第二阶段：团队协作

### 2.1 配置企业网盘作为文档共享

#### 步骤1：创建项目文档结构
```bash
# 在服务器上创建文档目录
mkdir -p /opt/jobfirst/docs/{api,deployment,development,testing}

# 创建主要文档
cat > /opt/jobfirst/docs/README.md << 'EOF'
# JobFirst 项目文档

## 项目概述
JobFirst是一个基于微服务架构的招聘管理系统。

## 技术栈
- 后端: Go, Python
- 数据库: MySQL, Redis, Neo4j
- 前端: Taro (React)
- 部署: 腾讯云轻量服务器

## 快速开始
1. 查看部署文档: [deployment/README.md](deployment/README.md)
2. 查看开发文档: [development/README.md](development/README.md)
3. 查看API文档: [api/README.md](api/README.md)

## 团队协作
- 代码仓库: Git
- 文档共享: 企业网盘
- 部署管理: 自动化脚本
EOF
```

#### 步骤2：配置企业网盘同步
```bash
# 创建网盘同步脚本
cat > scripts/sync-to-netdisk.sh << 'EOF'
#!/bin/bash

# 企业网盘同步脚本
NETDISK_DIR="/opt/jobfirst/docs"
SYNC_TARGET="your-netdisk-path"

log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1"
}

log_info "开始同步文档到企业网盘..."

# 使用rsync同步文档
rsync -avz --delete "$NETDISK_DIR/" "$SYNC_TARGET/"

if [ $? -eq 0 ]; then
    log_info "文档同步成功！"
else
    log_info "文档同步失败！"
    exit 1
fi
EOF

# 设置执行权限
chmod +x scripts/sync-to-netdisk.sh
```

### 2.2 设置团队成员访问权限

#### 步骤1：创建用户管理脚本
```bash
# 创建用户管理脚本
cat > scripts/user-management.sh << 'EOF'
#!/bin/bash

# 用户管理脚本
USER_CONFIG="/opt/jobfirst/config/users.yaml"

log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1"
}

# 添加团队成员
add_team_member() {
    local username=$1
    local role=$2
    local email=$3
    
    log_info "添加团队成员: $username ($role)"
    
    # 创建用户账号
    useradd -m -s /bin/bash "jobfirst-$username"
    
    # 设置用户组
    usermod -aG "jobfirst-$role" "jobfirst-$username"
    
    # 创建用户目录
    mkdir -p "/home/jobfirst-$username/workspace"
    chown "jobfirst-$username:jobfirst-$username" "/home/jobfirst-$username/workspace"
    
    # 记录用户信息
    echo "- username: $username" >> "$USER_CONFIG"
    echo "  role: $role" >> "$USER_CONFIG"
    echo "  email: $email" >> "$USER_CONFIG"
    echo "  created: $(date)" >> "$USER_CONFIG"
    echo "" >> "$USER_CONFIG"
    
    log_info "用户 $username 添加成功"
}

# 主函数
case "$1" in
    "add")
        add_team_member "$2" "$3" "$4"
        ;;
    *)
        echo "用法: $0 add <username> <role> <email>"
        echo "角色: frontend, backend, fullstack, admin"
        exit 1
        ;;
esac
EOF

# 设置执行权限
chmod +x scripts/user-management.sh
```

#### 步骤2：配置SSH密钥管理
```bash
# 创建SSH密钥管理脚本
cat > scripts/ssh-key-management.sh << 'EOF'
#!/bin/bash

# SSH密钥管理脚本
SSH_DIR="/opt/jobfirst/ssh-keys"

log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1"
}

# 添加SSH公钥
add_ssh_key() {
    local username=$1
    local public_key=$2
    
    log_info "为用户 $username 添加SSH公钥"
    
    # 创建用户SSH目录
    mkdir -p "/home/jobfirst-$username/.ssh"
    
    # 添加公钥到authorized_keys
    echo "$public_key" >> "/home/jobfirst-$username/.ssh/authorized_keys"
    
    # 设置正确的权限
    chmod 700 "/home/jobfirst-$username/.ssh"
    chmod 600 "/home/jobfirst-$username/.ssh/authorized_keys"
    chown -R "jobfirst-$username:jobfirst-$username" "/home/jobfirst-$username/.ssh"
    
    log_info "SSH公钥添加成功"
}

# 主函数
case "$1" in
    "add")
        add_ssh_key "$2" "$3"
        ;;
    *)
        echo "用法: $0 add <username> <public_key>"
        exit 1
        ;;
esac
EOF

# 设置执行权限
chmod +x scripts/ssh-key-management.sh
```

### 2.3 建立协作工作流程

#### 步骤1：创建Git工作流程文档
```bash
# 创建Git工作流程文档
cat > /opt/jobfirst/docs/development/GIT_WORKFLOW.md << 'EOF'
# Git 工作流程

## 分支策略
- `main`: 主分支，用于生产环境
- `develop`: 开发分支，用于集成测试
- `feature/*`: 功能分支，用于新功能开发
- `hotfix/*`: 热修复分支，用于紧急修复

## 工作流程
1. 从 `develop` 分支创建功能分支
2. 在功能分支上开发
3. 提交代码并推送到远程仓库
4. 创建 Pull Request 到 `develop` 分支
5. 代码审查通过后合并
6. 定期将 `develop` 合并到 `main` 分支

## 提交规范
- feat: 新功能
- fix: 修复bug
- docs: 文档更新
- style: 代码格式调整
- refactor: 代码重构
- test: 测试相关
- chore: 构建过程或辅助工具的变动

## 示例
```bash
# 创建功能分支
git checkout develop
git pull origin develop
git checkout -b feature/user-authentication

# 开发并提交
git add .
git commit -m "feat: add user authentication system"

# 推送到远程
git push origin feature/user-authentication
```
EOF
```

#### 步骤2：创建代码审查流程
```bash
# 创建代码审查脚本
cat > scripts/code-review.sh << 'EOF'
#!/bin/bash

# 代码审查脚本
REVIEW_DIR="/opt/jobfirst/reviews"

log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1"
}

# 创建代码审查
create_review() {
    local pr_number=$1
    local reviewer=$2
    
    log_info "创建代码审查: PR #$pr_number"
    
    # 创建审查目录
    mkdir -p "$REVIEW_DIR/PR-$pr_number"
    
    # 记录审查信息
    cat > "$REVIEW_DIR/PR-$pr_number/review.yaml" << EOL
pr_number: $pr_number
reviewer: $reviewer
status: pending
created: $(date)
EOL
    
    log_info "代码审查创建成功"
}

# 主函数
case "$1" in
    "create")
        create_review "$2" "$3"
        ;;
    *)
        echo "用法: $0 create <pr_number> <reviewer>"
        exit 1
        ;;
esac
EOF

# 设置执行权限
chmod +x scripts/code-review.sh
```

---

## 🤖 第三阶段：自动化部署

### 3.1 配置数据万象CI

#### 步骤1：创建CI配置文件
```bash
# 创建CI配置文件
cat > .github/workflows/tencent-deploy.yml << 'EOF'
name: Deploy to Tencent Cloud

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v3
      
    - name: Setup Go
      uses: actions/setup-go@v3
      with:
        go-version: '1.21'
        
    - name: Build application
      run: |
        cd basic/backend
        go mod tidy
        go build -o basic-server
        
    - name: Deploy to Tencent Cloud
      uses: appleboy/ssh-action@v0.1.5
      with:
        host: ${{ secrets.TENCENT_HOST }}
        username: ${{ secrets.TENCENT_USER }}
        key: ${{ secrets.TENCENT_SSH_KEY }}
        script: |
          cd /opt/jobfirst
          git pull origin main
          ./scripts/deploy-from-git.sh
          
    - name: Verify deployment
      uses: appleboy/ssh-action@v0.1.5
      with:
        host: ${{ secrets.TENCENT_HOST }}
        username: ${{ secrets.TENCENT_USER }}
        key: ${{ secrets.TENCENT_SSH_KEY }}
        script: |
          ./scripts/verify-deployment.sh
EOF
```

#### 步骤2：配置GitHub Secrets
```bash
# 在GitHub仓库设置以下Secrets:
# TENCENT_HOST: 101.33.251.158
# TENCENT_USER: root
# TENCENT_SSH_KEY: [您的SSH私钥]
```

### 3.2 建立自动化部署流程

#### 步骤1：创建部署脚本
```bash
# 创建完整部署脚本
cat > scripts/auto-deploy.sh << 'EOF'
#!/bin/bash

# 自动化部署脚本
LOG_FILE="/opt/jobfirst/logs/auto-deploy.log"
VERSION=$(date +%Y%m%d_%H%M%S)

log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" | tee -a "$LOG_FILE"
}

# 检查Git状态
check_git_status() {
    log_info "检查Git状态..."
    
    if [ ! -d ".git" ]; then
        log_error "当前目录不是Git仓库"
        exit 1
    fi
    
    # 检查是否有未提交的更改
    if ! git diff --quiet; then
        log_error "有未提交的更改，请先提交"
        exit 1
    fi
}

# 拉取最新代码
pull_latest_code() {
    log_info "拉取最新代码..."
    
    git fetch origin
    git pull origin main
    
    if [ $? -ne 0 ]; then
        log_error "Git拉取失败"
        exit 1
    fi
}

# 创建版本备份
create_version_backup() {
    log_info "创建版本备份: $VERSION"
    
    ./scripts/version-manager.sh create "$VERSION"
    
    if [ $? -ne 0 ]; then
        log_error "版本备份失败"
        exit 1
    fi
}

# 部署新版本
deploy_new_version() {
    log_info "开始部署新版本..."
    
    # 停止服务
    ./scripts/stop-services.sh
    
    # 构建服务
    ./scripts/build-services.sh
    
    # 启动服务
    ./scripts/start-services.sh
    
    if [ $? -ne 0 ]; then
        log_error "服务启动失败"
        exit 1
    fi
}

# 验证部署
verify_deployment() {
    log_info "验证部署..."
    
    sleep 10
    
    # 检查服务状态
    if lsof -i :8080 > /dev/null 2>&1; then
        log_info "部署成功！基础服务在8080端口运行"
    else
        log_error "部署失败！基础服务未启动"
        exit 1
    fi
    
    # 备份到COS
    ./scripts/backup-to-cos.sh
}

# 主函数
main() {
    log_info "开始自动化部署流程..."
    
    check_git_status
    pull_latest_code
    create_version_backup
    deploy_new_version
    verify_deployment
    
    log_info "自动化部署完成！版本: $VERSION"
}

# 执行主函数
main "$@"
EOF

# 设置执行权限
chmod +x scripts/auto-deploy.sh
```

#### 步骤2：创建构建脚本
```bash
# 创建构建脚本
cat > scripts/build-services.sh << 'EOF'
#!/bin/bash

# 构建脚本
LOG_FILE="/opt/jobfirst/logs/build.log"

log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1" | tee -a "$LOG_FILE"
}

log_info "开始构建服务..."

# 构建Go服务
cd /opt/jobfirst/backend
go mod tidy
go build -o basic-server

if [ $? -eq 0 ]; then
    log_info "Go服务构建成功"
else
    log_info "Go服务构建失败"
    exit 1
fi

# 构建Python服务
cd /opt/jobfirst/ai-service
pip install -r requirements.txt

if [ $? -eq 0 ]; then
    log_info "Python服务构建成功"
else
    log_info "Python服务构建失败"
    exit 1
fi

log_info "所有服务构建完成"
EOF

# 设置执行权限
chmod +x scripts/build-services.sh
```

### 3.3 实现监控和日志系统

#### 步骤1：创建监控脚本
```bash
# 创建监控脚本
cat > scripts/monitor.sh << 'EOF'
#!/bin/bash

# 监控脚本
LOG_FILE="/opt/jobfirst/logs/monitor.log"
ALERT_EMAIL="admin@jobfirst.com"

log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" | tee -a "$LOG_FILE"
}

# 检查服务状态
check_services() {
    log_info "检查服务状态..."
    
    # 检查基础服务
    if ! lsof -i :8080 > /dev/null 2>&1; then
        log_error "基础服务未运行"
        send_alert "基础服务未运行"
        return 1
    fi
    
    # 检查MySQL
    if ! systemctl is-active --quiet mysql; then
        log_error "MySQL服务未运行"
        send_alert "MySQL服务未运行"
        return 1
    fi
    
    # 检查Redis
    if ! systemctl is-active --quiet redis; then
        log_error "Redis服务未运行"
        send_alert "Redis服务未运行"
        return 1
    fi
    
    log_info "所有服务运行正常"
    return 0
}

# 检查系统资源
check_resources() {
    log_info "检查系统资源..."
    
    # 检查磁盘空间
    DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    if [ "$DISK_USAGE" -gt 80 ]; then
        log_error "磁盘空间不足: ${DISK_USAGE}%"
        send_alert "磁盘空间不足: ${DISK_USAGE}%"
    fi
    
    # 检查内存使用
    MEM_USAGE=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
    if [ "$MEM_USAGE" -gt 80 ]; then
        log_error "内存使用过高: ${MEM_USAGE}%"
        send_alert "内存使用过高: ${MEM_USAGE}%"
    fi
    
    log_info "系统资源检查完成"
}

# 发送告警
send_alert() {
    local message=$1
    log_error "发送告警: $message"
    
    # 这里可以集成邮件、短信、微信等告警方式
    echo "$message" | mail -s "JobFirst系统告警" "$ALERT_EMAIL"
}

# 主函数
main() {
    log_info "开始系统监控..."
    
    check_services
    check_resources
    
    log_info "系统监控完成"
}

# 执行主函数
main "$@"
EOF

# 设置执行权限
chmod +x scripts/monitor.sh
```

#### 步骤2：配置定时任务
```bash
# 配置定时任务
crontab -e

# 添加以下内容：
# 每分钟检查服务状态
* * * * * /opt/jobfirst/scripts/monitor.sh

# 每小时备份到COS
0 * * * * /opt/jobfirst/scripts/backup-to-cos.sh

# 每天凌晨2点清理日志
0 2 * * * find /opt/jobfirst/logs -name "*.log" -mtime +7 -delete
```

#### 步骤3：创建日志管理脚本
```bash
# 创建日志管理脚本
cat > scripts/log-manager.sh << 'EOF'
#!/bin/bash

# 日志管理脚本
LOG_DIR="/opt/jobfirst/logs"
BACKUP_DIR="/opt/backup/logs"

log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1"
}

# 清理旧日志
cleanup_old_logs() {
    log_info "清理旧日志..."
    
    # 清理7天前的日志
    find "$LOG_DIR" -name "*.log" -mtime +7 -delete
    
    log_info "旧日志清理完成"
}

# 压缩日志
compress_logs() {
    log_info "压缩日志..."
    
    # 压缩3天前的日志
    find "$LOG_DIR" -name "*.log" -mtime +3 -exec gzip {} \;
    
    log_info "日志压缩完成"
}

# 备份日志
backup_logs() {
    log_info "备份日志..."
    
    # 创建备份目录
    mkdir -p "$BACKUP_DIR/$(date +%Y%m%d)"
    
    # 备份重要日志
    cp "$LOG_DIR"/*.log "$BACKUP_DIR/$(date +%Y%m%d)/" 2>/dev/null
    
    log_info "日志备份完成"
}

# 主函数
case "$1" in
    "cleanup")
        cleanup_old_logs
        ;;
    "compress")
        compress_logs
        ;;
    "backup")
        backup_logs
        ;;
    "all")
        cleanup_old_logs
        compress_logs
        backup_logs
        ;;
    *)
        echo "用法: $0 {cleanup|compress|backup|all}"
        exit 1
        ;;
esac
EOF

# 设置执行权限
chmod +x scripts/log-manager.sh
```

---

## 📋 实施检查清单

### 第一阶段检查清单
- [ ] Git仓库初始化完成
- [ ] .gitignore文件创建
- [ ] 初始提交完成
- [ ] COS命令行工具安装
- [ ] COS访问配置完成
- [ ] 备份脚本创建
- [ ] DNS解析配置
- [ ] SSL证书配置
- [ ] Nginx SSL配置

### 第二阶段检查清单
- [ ] 项目文档结构创建
- [ ] 企业网盘同步配置
- [ ] 用户管理脚本创建
- [ ] SSH密钥管理脚本创建
- [ ] Git工作流程文档
- [ ] 代码审查流程配置

### 第三阶段检查清单
- [ ] CI配置文件创建
- [ ] GitHub Secrets配置
- [ ] 自动化部署脚本创建
- [ ] 构建脚本创建
- [ ] 监控脚本创建
- [ ] 定时任务配置
- [ ] 日志管理脚本创建

---

## 🎯 验证步骤

### 1. 基础功能验证
```bash
# 测试Git功能
git status
git log --oneline

# 测试版本管理
./scripts/version-manager.sh create "v1.0.0"
./scripts/version-manager.sh list

# 测试服务管理
./scripts/stop-services.sh
./scripts/start-services.sh
```

### 2. 团队协作验证
```bash
# 测试用户管理
./scripts/user-management.sh add "testuser" "frontend" "test@example.com"

# 测试SSH密钥管理
./scripts/ssh-key-management.sh add "testuser" "ssh-rsa AAAAB3NzaC1yc2E..."

# 测试文档同步
./scripts/sync-to-netdisk.sh
```

### 3. 自动化部署验证
```bash
# 测试自动部署
./scripts/auto-deploy.sh

# 测试监控功能
./scripts/monitor.sh

# 测试日志管理
./scripts/log-manager.sh all
```

---

## 📞 技术支持

如果在实施过程中遇到问题，请：

1. 检查日志文件：`/opt/jobfirst/logs/`
2. 查看脚本执行状态
3. 验证配置文件格式
4. 检查权限设置

**完成实施后，请通知我参与验证和测试！**
