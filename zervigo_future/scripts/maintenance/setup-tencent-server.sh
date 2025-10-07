#!/bin/bash

# 腾讯云轻量应用服务器环境准备脚本
# 用于在服务器上安装和配置必要的软件环境

set -e

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# 检测系统类型
detect_system() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    else
        log_error "无法检测系统类型"
        exit 1
    fi
    
    log_info "检测到系统: $OS $VER"
}

# 更新系统包
update_system() {
    log_info "更新系统包..."
    
    if [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
        apt update && apt upgrade -y
    elif [[ "$OS" == *"CentOS"* ]] || [[ "$OS" == *"Red Hat"* ]]; then
        yum update -y
    else
        log_warning "未知系统类型，跳过系统更新"
    fi
    
    log_success "系统包更新完成"
}

# 安装基础工具
install_basic_tools() {
    log_info "安装基础工具..."
    
    if [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
        apt install -y curl wget git vim unzip software-properties-common
    elif [[ "$OS" == *"CentOS"* ]] || [[ "$OS" == *"Red Hat"* ]]; then
        yum install -y curl wget git vim unzip epel-release
    fi
    
    log_success "基础工具安装完成"
}

# 安装Go
install_go() {
    log_info "安装Go 1.21..."
    
    # 检查Go是否已安装
    if command -v go &> /dev/null; then
        local current_version=$(go version | cut -d' ' -f3 | sed 's/go//')
        log_info "Go已安装，当前版本: $current_version"
        return 0
    fi
    
    # 下载并安装Go
    cd /tmp
    wget https://go.dev/dl/go1.21.5.linux-amd64.tar.gz
    tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz
    
    # 配置环境变量
    echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile
    echo 'export GOPATH=/opt/go' >> /etc/profile
    echo 'export GOBIN=$GOPATH/bin' >> /etc/profile
    source /etc/profile
    
    # 创建Go工作目录
    mkdir -p /opt/go/{bin,src,pkg}
    
    log_success "Go安装完成"
}

# 安装Python
install_python() {
    log_info "安装Python 3.11..."
    
    if [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
        # Ubuntu/Debian
        apt install -y python3.11 python3.11-pip python3.11-venv python3.11-dev
        update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1
        update-alternatives --install /usr/bin/pip3 pip3 /usr/bin/pip3.11 1
    elif [[ "$OS" == *"CentOS"* ]] || [[ "$OS" == *"Red Hat"* ]]; then
        # CentOS/RHEL
        yum install -y python311 python311-pip python311-devel
        alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1
        alternatives --install /usr/bin/pip3 pip3 /usr/bin/pip3.11 1
    fi
    
    log_success "Python安装完成"
}

# 安装Node.js
install_nodejs() {
    log_info "安装Node.js 18..."
    
    # 检查Node.js是否已安装
    if command -v node &> /dev/null; then
        local current_version=$(node --version)
        log_info "Node.js已安装，当前版本: $current_version"
        return 0
    fi
    
    # 使用NodeSource仓库安装Node.js 18
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    
    if [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
        apt install -y nodejs
    elif [[ "$OS" == *"CentOS"* ]] || [[ "$OS" == *"Red Hat"* ]]; then
        yum install -y nodejs npm
    fi
    
    log_success "Node.js安装完成"
}

# 安装MySQL
install_mysql() {
    log_info "安装MySQL 8.0..."
    
    if [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
        # Ubuntu/Debian
        apt install -y mysql-server mysql-client
    elif [[ "$OS" == *"CentOS"* ]] || [[ "$OS" == *"Red Hat"* ]]; then
        # CentOS/RHEL
        yum install -y mysql-server mysql
        systemctl enable mysqld
        systemctl start mysqld
    fi
    
    # 启动MySQL服务
    systemctl enable mysql
    systemctl start mysql
    
    # 安全配置
    mysql_secure_installation << EOF
y
jobfirst_root_2024
jobfirst_root_2024
y
y
y
y
EOF
    
    log_success "MySQL安装完成"
}

# 安装PostgreSQL
install_postgresql() {
    log_info "安装PostgreSQL 14..."
    
    if [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
        # Ubuntu/Debian
        apt install -y postgresql postgresql-contrib
    elif [[ "$OS" == *"CentOS"* ]] || [[ "$OS" == *"Red Hat"* ]]; then
        # CentOS/RHEL
        yum install -y postgresql14-server postgresql14-contrib
        postgresql-14-setup initdb
    fi
    
    # 启动PostgreSQL服务
    systemctl enable postgresql
    systemctl start postgresql
    
    # 配置PostgreSQL
    sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'postgres_root_2024';"
    
    log_success "PostgreSQL安装完成"
}

# 安装Redis
install_redis() {
    log_info "安装Redis 7.0..."
    
    if [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
        # Ubuntu/Debian
        apt install -y redis-server
    elif [[ "$OS" == *"CentOS"* ]] || [[ "$OS" == *"Red Hat"* ]]; then
        # CentOS/RHEL
        yum install -y redis
    fi
    
    # 配置Redis
    sed -i 's/^# requirepass foobared/requirepass redis_root_2024/' /etc/redis/redis.conf
    sed -i 's/^bind 127.0.0.1/bind 0.0.0.0/' /etc/redis/redis.conf
    
    # 启动Redis服务
    systemctl enable redis
    systemctl start redis
    
    log_success "Redis安装完成"
}

# 安装Nginx
install_nginx() {
    log_info "安装Nginx..."
    
    if [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
        # Ubuntu/Debian
        apt install -y nginx
    elif [[ "$OS" == *"CentOS"* ]] || [[ "$OS" == *"Red Hat"* ]]; then
        # CentOS/RHEL
        yum install -y nginx
    fi
    
    # 启动Nginx服务
    systemctl enable nginx
    systemctl start nginx
    
    log_success "Nginx安装完成"
}

# 配置防火墙
configure_firewall() {
    log_info "配置防火墙..."
    
    # 检查防火墙状态
    if systemctl is-active --quiet ufw; then
        # Ubuntu/Debian UFW
        ufw allow 22/tcp
        ufw allow 80/tcp
        ufw allow 443/tcp
        ufw allow 8080/tcp
        ufw allow 8206/tcp
        ufw --force enable
    elif systemctl is-active --quiet firewalld; then
        # CentOS/RHEL Firewalld
        firewall-cmd --permanent --add-port=22/tcp
        firewall-cmd --permanent --add-port=80/tcp
        firewall-cmd --permanent --add-port=443/tcp
        firewall-cmd --permanent --add-port=8080/tcp
        firewall-cmd --permanent --add-port=8206/tcp
        firewall-cmd --reload
    else
        log_warning "未检测到防火墙服务，请手动配置防火墙规则"
    fi
    
    log_success "防火墙配置完成"
}

# 创建用户和目录
create_user_and_directories() {
    log_info "创建用户和目录..."
    
    # 创建jobfirst用户
    if ! id "jobfirst" &>/dev/null; then
        useradd -m -s /bin/bash jobfirst
        usermod -aG sudo jobfirst
        log_success "用户jobfirst创建完成"
    else
        log_info "用户jobfirst已存在"
    fi
    
    # 创建应用目录
    mkdir -p /opt/jobfirst/{backend,frontend,scripts,configs,logs,uploads}
    chown -R jobfirst:jobfirst /opt/jobfirst
    
    log_success "目录创建完成"
}

# 配置SSH
configure_ssh() {
    log_info "配置SSH..."
    
    # 备份SSH配置
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
    
    # 配置SSH
    sed -i 's/#PermitRootLogin yes/PermitRootLogin yes/' /etc/ssh/sshd_config
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
    sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
    
    # 重启SSH服务
    systemctl restart sshd
    
    log_success "SSH配置完成"
}

# 安装监控工具
install_monitoring() {
    log_info "安装监控工具..."
    
    if [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
        apt install -y htop iotop nethogs
    elif [[ "$OS" == *"CentOS"* ]] || [[ "$OS" == *"Red Hat"* ]]; then
        yum install -y htop iotop nethogs
    fi
    
    log_success "监控工具安装完成"
}

# 主函数
main() {
    log_info "开始配置腾讯云轻量应用服务器环境..."
    
    # 检测系统
    detect_system
    
    # 更新系统
    update_system
    
    # 安装基础工具
    install_basic_tools
    
    # 安装开发环境
    install_go
    install_python
    install_nodejs
    
    # 安装数据库
    install_mysql
    install_postgresql
    install_redis
    
    # 安装Web服务器
    install_nginx
    
    # 配置系统
    configure_firewall
    create_user_and_directories
    configure_ssh
    install_monitoring
    
    log_success "=== 服务器环境配置完成 ==="
    log_info "已安装的软件:"
    log_info "  - Go 1.21"
    log_info "  - Python 3.11"
    log_info "  - Node.js 18"
    log_info "  - MySQL 8.0"
    log_info "  - PostgreSQL 14"
    log_info "  - Redis 7.0"
    log_info "  - Nginx"
    log_info ""
    log_info "数据库密码:"
    log_info "  - MySQL root: jobfirst_root_2024"
    log_info "  - PostgreSQL postgres: postgres_root_2024"
    log_info "  - Redis: redis_root_2024"
    log_info ""
    log_info "下一步:"
    log_info "  1. 配置SSH密钥认证"
    log_info "  2. 运行部署脚本: ./deploy-to-tencent-cloud.sh <服务器IP>"
}

# 执行主函数
main "$@"
