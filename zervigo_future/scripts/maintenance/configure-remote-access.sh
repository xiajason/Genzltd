#!/bin/bash

# JobFirst系统远程访问配置脚本
# 用于配置远程协同开发环境

set -e

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置变量
SERVER_IP=""
SERVER_USER="root"
DOMAIN=""
SSL_EMAIL=""

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

# 显示帮助信息
show_help() {
    echo -e "${CYAN}JobFirst系统远程访问配置脚本${NC}"
    echo ""
    echo "用法: $0 <服务器IP> [选项]"
    echo ""
    echo "参数:"
    echo "  <服务器IP>    腾讯云轻量服务器的公网IP地址"
    echo ""
    echo "选项:"
    echo "  --user USER    服务器用户名 (默认: root)"
    echo "  --domain DOMAIN 域名 (可选，用于SSL配置)"
    echo "  --ssl-email EMAIL SSL证书邮箱 (可选)"
    echo "  --help         显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 123.456.789.0"
    echo "  $0 123.456.789.0 --domain jobfirst.example.com --ssl-email admin@example.com"
    echo ""
    echo "功能:"
    echo "  1. 配置Nginx反向代理"
    echo "  2. 设置SSL证书 (如果提供域名)"
    echo "  3. 配置CORS跨域访问"
    echo "  4. 设置API文档访问"
    echo "  5. 配置WebSocket支持"
    echo "  6. 设置文件上传限制"
}

# 配置Nginx反向代理
configure_nginx_proxy() {
    log_info "配置Nginx反向代理..."
    
    ssh $SERVER_USER@$SERVER_IP << 'EOF'
        # 备份现有配置
        sudo cp /etc/nginx/sites-available/jobfirst /etc/nginx/sites-available/jobfirst.backup
        
        # 创建新的Nginx配置
        sudo tee /etc/nginx/sites-available/jobfirst > /dev/null << 'NGINX_EOF'
# JobFirst系统Nginx配置

# 上游服务器配置
upstream backend {
    server localhost:8080;
    keepalive 32;
}

upstream ai_service {
    server localhost:8206;
    keepalive 16;
}

# 主服务器配置
server {
    listen 80;
    server_name _;
    
    # 客户端最大请求体大小
    client_max_body_size 50M;
    
    # 超时设置
    proxy_connect_timeout 60s;
    proxy_send_timeout 60s;
    proxy_read_timeout 60s;
    
    # 前端静态文件
    location / {
        root /opt/jobfirst/frontend/dist/build/h5;
        index index.html;
        try_files $uri $uri/ /index.html;
        
        # 缓存静态资源
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
    
    # API代理
    location /api/ {
        proxy_pass http://backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # CORS配置
        add_header Access-Control-Allow-Origin *;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS";
        add_header Access-Control-Allow-Headers "Origin, Content-Type, Accept, Authorization, API-Version, X-Requested-With, X-API-Key, X-Client-Version";
        
        # 处理预检请求
        if ($request_method = 'OPTIONS') {
            add_header Access-Control-Allow-Origin *;
            add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS";
            add_header Access-Control-Allow-Headers "Origin, Content-Type, Accept, Authorization, API-Version, X-Requested-With, X-API-Key, X-Client-Version";
            add_header Access-Control-Max-Age 1728000;
            add_header Content-Type 'text/plain charset=UTF-8';
            add_header Content-Length 0;
            return 204;
        }
    }
    
    # AI服务代理
    location /ai/ {
        proxy_pass http://ai_service/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket支持
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # CORS配置
        add_header Access-Control-Allow-Origin *;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS";
        add_header Access-Control-Allow-Headers "Origin, Content-Type, Accept, Authorization, API-Version, X-Requested-With, X-API-Key, X-Client-Version";
    }
    
    # 文件上传代理
    location /upload/ {
        proxy_pass http://backend/upload/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # 文件上传配置
        client_max_body_size 50M;
        proxy_request_buffering off;
    }
    
    # 健康检查
    location /health {
        proxy_pass http://backend/api/v1/consul/status;
        access_log off;
    }
    
    # API文档 (如果启用)
    location /docs/ {
        proxy_pass http://backend/docs/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # 监控面板 (如果启用)
    location /monitor/ {
        proxy_pass http://backend/monitor/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # 基本认证
        auth_basic "Monitor Access";
        auth_basic_user_file /etc/nginx/.htpasswd;
    }
    
    # 错误页面
    error_page 404 /404.html;
    error_page 500 502 503 504 /50x.html;
    
    location = /50x.html {
        root /usr/share/nginx/html;
    }
}
NGINX_EOF
        
        # 测试Nginx配置
        sudo nginx -t
        
        # 重启Nginx
        sudo systemctl restart nginx
        
        echo "Nginx反向代理配置完成"
EOF
    
    log_success "Nginx反向代理配置完成"
}

# 配置SSL证书
configure_ssl() {
    if [ -z "$DOMAIN" ] || [ -z "$SSL_EMAIL" ]; then
        log_warning "未提供域名或邮箱，跳过SSL配置"
        return 0
    fi
    
    log_info "配置SSL证书..."
    
    ssh $SERVER_USER@$SERVER_IP << EOF
        # 安装Certbot
        sudo apt update
        sudo apt install -y certbot python3-certbot-nginx
        
        # 申请SSL证书
        sudo certbot --nginx -d $DOMAIN --email $SSL_EMAIL --agree-tos --non-interactive
        
        # 配置自动续期
        echo "0 12 * * * /usr/bin/certbot renew --quiet" | sudo crontab -
        
        echo "SSL证书配置完成"
EOF
    
    log_success "SSL证书配置完成"
}

# 配置CORS跨域访问
configure_cors() {
    log_info "配置CORS跨域访问..."
    
    ssh $SERVER_USER@$SERVER_IP << 'EOF'
        # 创建CORS配置文件
        sudo tee /etc/nginx/conf.d/cors.conf > /dev/null << 'CORS_EOF'
# CORS跨域配置

# 允许的域名列表
map $http_origin $cors_origin {
    default "";
    "~^https?://localhost(:[0-9]+)?$" $http_origin;
    "~^https?://127.0.0.1(:[0-9]+)?$" $http_origin;
    "~^https?://.*\.ngrok\.io$" $http_origin;
    "~^https?://.*\.vercel\.app$" $http_origin;
    "~^https?://.*\.netlify\.app$" $http_origin;
}

# CORS头部配置
add_header Access-Control-Allow-Origin $cors_origin always;
add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
add_header Access-Control-Allow-Headers "Origin, Content-Type, Accept, Authorization, API-Version, X-Requested-With, X-API-Key, X-Client-Version" always;
add_header Access-Control-Allow-Credentials true always;
add_header Access-Control-Max-Age 1728000 always;
CORS_EOF
        
        # 重启Nginx
        sudo systemctl restart nginx
        
        echo "CORS跨域配置完成"
EOF
    
    log_success "CORS跨域配置完成"
}

# 配置API文档访问
configure_api_docs() {
    log_info "配置API文档访问..."
    
    ssh $SERVER_USER@$SERVER_IP << 'EOF'
        # 创建API文档配置
        sudo tee /etc/nginx/conf.d/api-docs.conf > /dev/null << 'DOCS_EOF'
# API文档配置

# Swagger UI配置
location /api-docs/ {
    alias /opt/jobfirst/docs/;
    index index.html;
    try_files $uri $uri/ /api-docs/index.html;
    
    # 缓存配置
    expires 1h;
    add_header Cache-Control "public";
}

# API文档代理
location /docs/ {
    proxy_pass http://backend/docs/;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}
DOCS_EOF
        
        # 创建API文档目录
        sudo mkdir -p /opt/jobfirst/docs
        
        # 重启Nginx
        sudo systemctl restart nginx
        
        echo "API文档配置完成"
EOF
    
    log_success "API文档配置完成"
}

# 配置WebSocket支持
configure_websocket() {
    log_info "配置WebSocket支持..."
    
    ssh $SERVER_USER@$SERVER_IP << 'EOF'
        # 创建WebSocket配置
        sudo tee /etc/nginx/conf.d/websocket.conf > /dev/null << 'WS_EOF'
# WebSocket配置

# WebSocket代理配置
map $http_upgrade $connection_upgrade {
    default upgrade;
    '' close;
}

# WebSocket代理
location /ws/ {
    proxy_pass http://backend/ws/;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection $connection_upgrade;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    
    # WebSocket超时设置
    proxy_read_timeout 86400;
    proxy_send_timeout 86400;
}
WS_EOF
        
        # 重启Nginx
        sudo systemctl restart nginx
        
        echo "WebSocket配置完成"
EOF
    
    log_success "WebSocket配置完成"
}

# 配置文件上传
configure_file_upload() {
    log_info "配置文件上传..."
    
    ssh $SERVER_USER@$SERVER_IP << 'EOF'
        # 创建文件上传配置
        sudo tee /etc/nginx/conf.d/upload.conf > /dev/null << 'UPLOAD_EOF'
# 文件上传配置

# 文件上传大小限制
client_max_body_size 50M;
client_body_buffer_size 128k;
client_body_timeout 60s;
client_header_timeout 60s;

# 文件上传代理
location /upload/ {
    proxy_pass http://backend/upload/;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    
    # 文件上传特殊配置
    proxy_request_buffering off;
    proxy_buffering off;
    proxy_max_temp_file_size 0;
}
UPLOAD_EOF
        
        # 重启Nginx
        sudo systemctl restart nginx
        
        echo "文件上传配置完成"
EOF
    
    log_success "文件上传配置完成"
}

# 配置监控面板
configure_monitoring() {
    log_info "配置监控面板..."
    
    ssh $SERVER_USER@$SERVER_IP << 'EOF'
        # 安装htpasswd工具
        sudo apt install -y apache2-utils
        
        # 创建监控用户
        sudo htpasswd -c /etc/nginx/.htpasswd admin
        
        # 创建监控配置
        sudo tee /etc/nginx/conf.d/monitoring.conf > /dev/null << 'MONITOR_EOF'
# 监控面板配置

# 监控面板访问
location /monitor/ {
    proxy_pass http://backend/monitor/;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    
    # 基本认证
    auth_basic "Monitor Access";
    auth_basic_user_file /etc/nginx/.htpasswd;
    
    # 限制访问IP
    allow 127.0.0.1;
    allow 10.0.0.0/8;
    allow 172.16.0.0/12;
    allow 192.168.0.0/16;
    deny all;
}
MONITOR_EOF
        
        # 重启Nginx
        sudo systemctl restart nginx
        
        echo "监控面板配置完成"
EOF
    
    log_success "监控面板配置完成"
}

# 配置安全策略
configure_security() {
    log_info "配置安全策略..."
    
    ssh $SERVER_USER@$SERVER_IP << 'EOF'
        # 创建安全配置
        sudo tee /etc/nginx/conf.d/security.conf > /dev/null << 'SECURITY_EOF'
# 安全配置

# 隐藏Nginx版本
server_tokens off;

# 安全头部
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' data:; connect-src 'self' ws: wss:;" always;

# 限制请求方法
if ($request_method !~ ^(GET|HEAD|POST|PUT|DELETE|OPTIONS)$) {
    return 405;
}

# 限制请求大小
client_max_body_size 50M;
client_body_buffer_size 128k;

# 限制连接数
limit_conn_zone $binary_remote_addr zone=conn_limit_per_ip:10m;
limit_req_zone $binary_remote_addr zone=req_limit_per_ip:10m rate=10r/s;

# 应用限制
limit_conn conn_limit_per_ip 20;
limit_req zone=req_limit_per_ip burst=20 nodelay;
SECURITY_EOF
        
        # 重启Nginx
        sudo systemctl restart nginx
        
        echo "安全策略配置完成"
EOF
    
    log_success "安全策略配置完成"
}

# 验证配置
verify_configuration() {
    log_info "验证远程访问配置..."
    
    # 等待服务启动
    sleep 5
    
    # 检查服务状态
    ssh $SERVER_USER@$SERVER_IP << 'EOF'
        echo "=== Nginx配置检查 ==="
        sudo nginx -t
        
        echo "=== 服务状态检查 ==="
        sudo systemctl status nginx --no-pager -l
        
        echo "=== 端口检查 ==="
        netstat -tlnp | grep :80
        
        echo "=== 配置验证完成 ==="
EOF
    
    # 测试远程访问
    log_info "测试远程访问..."
    
    # 测试前端访问
    if curl -f "http://$SERVER_IP/" > /dev/null 2>&1; then
        log_success "前端访问正常"
    else
        log_warning "前端访问异常"
    fi
    
    # 测试API访问
    if curl -f "http://$SERVER_IP/api/v1/consul/status" > /dev/null 2>&1; then
        log_success "API访问正常"
    else
        log_warning "API访问异常"
    fi
    
    # 测试AI服务访问
    if curl -f "http://$SERVER_IP/ai/health" > /dev/null 2>&1; then
        log_success "AI服务访问正常"
    else
        log_warning "AI服务访问异常"
    fi
    
    log_success "远程访问配置验证完成"
}

# 主配置函数
main() {
    log_info "开始配置远程访问..."
    log_info "服务器: $SERVER_IP"
    if [ -n "$DOMAIN" ]; then
        log_info "域名: $DOMAIN"
    fi
    
    # 配置Nginx反向代理
    configure_nginx_proxy
    
    # 配置SSL证书
    configure_ssl
    
    # 配置CORS跨域访问
    configure_cors
    
    # 配置API文档访问
    configure_api_docs
    
    # 配置WebSocket支持
    configure_websocket
    
    # 配置文件上传
    configure_file_upload
    
    # 配置监控面板
    configure_monitoring
    
    # 配置安全策略
    configure_security
    
    # 验证配置
    verify_configuration
    
    log_success "=== 远程访问配置完成 ==="
    log_info "系统访问地址:"
    log_info "  前端: http://$SERVER_IP"
    log_info "  API: http://$SERVER_IP/api/v1/"
    log_info "  AI服务: http://$SERVER_IP/ai/"
    log_info "  健康检查: http://$SERVER_IP/health"
    log_info "  监控面板: http://$SERVER_IP/monitor/"
    if [ -n "$DOMAIN" ]; then
        log_info "  HTTPS: https://$DOMAIN"
    fi
    log_info ""
    log_info "远程协同开发配置:"
    log_info "  - CORS跨域访问已启用"
    log_info "  - WebSocket支持已配置"
    log_info "  - 文件上传限制: 50MB"
    log_info "  - API文档访问已启用"
    log_info "  - 监控面板已配置"
    log_info "  - 安全策略已应用"
}

# 主函数
main() {
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            --user)
                SERVER_USER="$2"
                shift 2
                ;;
            --domain)
                DOMAIN="$2"
                shift 2
                ;;
            --ssl-email)
                SSL_EMAIL="$2"
                shift 2
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                if [ -z "$SERVER_IP" ]; then
                    SERVER_IP="$1"
                else
                    log_error "未知参数: $1"
                    show_help
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # 检查参数
    if [ -z "$SERVER_IP" ]; then
        log_error "请提供服务器IP地址"
        show_help
        exit 1
    fi
    
    # 执行配置
    main
}

# 执行主函数
main "$@"
