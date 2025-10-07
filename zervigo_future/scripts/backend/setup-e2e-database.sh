#!/bin/bash

# JobFirst E2E测试数据库初始化脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# 数据库配置
DB_HOST="localhost"
DB_PORT="3306"
DB_USER="root"
DB_PASSWORD=""
DB_NAME="jobfirst_e2e_test"

log_info "开始设置E2E测试数据库..."

# 检查MySQL是否运行
log_info "检查MySQL服务状态..."
if ! mysqladmin ping -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" --silent; then
    log_error "MySQL服务未运行，请先启动MySQL服务"
    exit 1
fi
log_success "MySQL服务运行正常"

# 创建E2E测试数据库
log_info "创建E2E测试数据库: $DB_NAME"
mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -e "DROP DATABASE IF EXISTS $DB_NAME;"
mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -e "CREATE DATABASE $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
log_success "E2E测试数据库创建成功"

# 创建基础表结构
log_info "创建基础表结构..."

# 用户表
mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" "$DB_NAME" <<EOF
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100),
    phone VARCHAR(20),
    avatar_url VARCHAR(500),
    status ENUM('active', 'inactive', 'suspended') DEFAULT 'active',
    role ENUM('user', 'admin', 'super_admin') DEFAULT 'user',
    points INT DEFAULT 100,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL
);
EOF

# 企业表
mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" "$DB_NAME" <<EOF
CREATE TABLE companies (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    short_name VARCHAR(100),
    logo_url VARCHAR(500),
    industry VARCHAR(100),
    company_size VARCHAR(50),
    location VARCHAR(200),
    website VARCHAR(500),
    description TEXT,
    founded_year INT,
    business_license VARCHAR(100),
    status ENUM('pending', 'verified', 'rejected') DEFAULT 'pending',
    verification_level ENUM('basic', 'premium', 'vip') DEFAULT 'basic',
    job_count INT DEFAULT 0,
    view_count INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL
);
EOF

# 职位分类表
mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" "$DB_NAME" <<EOF
CREATE TABLE job_categories (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    parent_id INT NULL,
    level INT DEFAULT 1,
    sort_order INT DEFAULT 0,
    icon VARCHAR(50),
    description TEXT,
    job_count INT DEFAULT 0,
    status ENUM('active', 'inactive') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    FOREIGN KEY (parent_id) REFERENCES job_categories(id)
);
EOF

# 职位表
mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" "$DB_NAME" <<EOF
CREATE TABLE jobs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    company_id INT NOT NULL,
    category_id INT NOT NULL,
    title VARCHAR(200) NOT NULL,
    job_type ENUM('full_time', 'part_time', 'internship', 'contract') DEFAULT 'full_time',
    location VARCHAR(200) NOT NULL,
    salary_min INT,
    salary_max INT,
    salary_type ENUM('monthly', 'yearly', 'hourly') DEFAULT 'monthly',
    experience_required ENUM('entry', 'junior', 'mid', 'senior', 'expert'),
    education_required ENUM('high_school', 'college', 'bachelor', 'master', 'phd'),
    description TEXT NOT NULL,
    requirements TEXT,
    benefits TEXT,
    skills JSON,
    tags JSON,
    status ENUM('draft', 'published', 'paused', 'closed') DEFAULT 'draft',
    priority INT DEFAULT 0,
    view_count INT DEFAULT 0,
    application_count INT DEFAULT 0,
    favorite_count INT DEFAULT 0,
    publish_at TIMESTAMP NULL,
    expire_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    FOREIGN KEY (company_id) REFERENCES companies(id),
    FOREIGN KEY (category_id) REFERENCES job_categories(id)
);
EOF

# 职位申请表
mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" "$DB_NAME" <<EOF
CREATE TABLE job_applications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    job_id INT NOT NULL,
    resume_id INT NULL,
    status ENUM('pending', 'reviewing', 'accepted', 'rejected', 'withdrawn') DEFAULT 'pending',
    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    reviewed_at TIMESTAMP NULL,
    reviewed_by INT NULL,
    review_notes TEXT,
    cover_letter TEXT,
    expected_salary INT NULL,
    available_date DATE NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (job_id) REFERENCES jobs(id),
    UNIQUE KEY unique_user_job (user_id, job_id)
);
EOF

# 职位收藏表
mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" "$DB_NAME" <<EOF
CREATE TABLE job_favorites (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    job_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (job_id) REFERENCES jobs(id),
    UNIQUE KEY unique_user_job_favorite (user_id, job_id)
);
EOF

log_success "基础表结构创建成功"

# 插入测试数据
log_info "插入E2E测试数据..."

# 插入测试用户
mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" "$DB_NAME" <<EOF
INSERT INTO users (username, email, password_hash, full_name, role, points) VALUES
('testuser1', 'testuser1@example.com', '\$2a\$12\$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj4J/8KzKz2a', '测试用户1', 'user', 1000),
('testuser2', 'testuser2@example.com', '\$2a\$12\$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj4J/8KzKz2a', '测试用户2', 'user', 1000),
('testadmin', 'admin@example.com', '\$2a\$12\$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj4J/8KzKz2a', '测试管理员', 'admin', 1000);
EOF

# 插入测试企业
mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" "$DB_NAME" <<EOF
INSERT INTO companies (name, short_name, logo_url, industry, company_size, location, website, description, founded_year, status, verification_level, job_count, view_count) VALUES
('腾讯科技有限公司', '腾讯', '/images/company/tencent.png', '互联网', 'enterprise', '深圳', 'https://www.tencent.com', '腾讯是一家以互联网为基础的科技与文化公司', 1998, 'verified', 'vip', 156, 12580),
('阿里巴巴集团', '阿里巴巴', '/images/company/alibaba.png', '电商', 'enterprise', '杭州', 'https://www.alibaba.com', '阿里巴巴集团是全球领先的电子商务平台', 1999, 'verified', 'vip', 89, 9876),
('字节跳动', '字节跳动', '/images/company/bytedance.png', '互联网', 'enterprise', '北京', 'https://www.bytedance.com', '字节跳动是一家全球化的互联网技术公司', 2012, 'verified', 'vip', 234, 15678);
EOF

# 插入测试分类
mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" "$DB_NAME" <<EOF
INSERT INTO job_categories (name, parent_id, level, sort_order, icon, description, job_count, status) VALUES
('技术开发', NULL, 1, 1, '💻', '技术开发相关职位', 500, 'active'),
('产品管理', NULL, 1, 2, '📱', '产品管理相关职位', 200, 'active'),
('前端开发', 1, 2, 1, '🎨', '前端开发相关职位', 150, 'active');
EOF

# 插入测试职位
mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" "$DB_NAME" <<EOF
INSERT INTO jobs (company_id, category_id, title, job_type, location, salary_min, salary_max, salary_type, experience_required, education_required, description, requirements, benefits, skills, tags, status, priority, view_count, application_count, favorite_count, publish_at, expire_at) VALUES
(1, 3, '前端开发工程师', 'full_time', '深圳', 15000, 25000, 'monthly', 'mid', 'bachelor', '负责公司前端产品的开发和维护，参与产品需求分析和技术方案设计。', '1. 熟练掌握React、Vue等前端框架\n2. 熟悉TypeScript、ES6+语法\n3. 有移动端开发经验优先', '1. 五险一金\n2. 年终奖\n3. 带薪年假', '["React", "Vue", "TypeScript", "JavaScript"]', '["前端", "React", "Vue", "TypeScript"]', 'published', 1, 1000, 150, 80, NOW(), DATE_ADD(NOW(), INTERVAL 30 DAY)),
(2, 2, '产品经理', 'full_time', '杭州', 20000, 35000, 'monthly', 'senior', 'bachelor', '负责产品规划、需求分析和产品设计，推动产品迭代和优化。', '1. 5年以上产品经理经验\n2. 熟悉产品设计流程\n3. 具备数据分析能力', '1. 五险一金\n2. 股票期权\n3. 带薪年假', '["产品设计", "数据分析", "用户研究", "项目管理"]', '["产品", "电商", "B2B", "数据分析"]', 'published', 2, 800, 120, 60, NOW(), DATE_ADD(NOW(), INTERVAL 28 DAY)),
(3, 1, '后端开发工程师', 'full_time', '北京', 18000, 30000, 'monthly', 'senior', 'bachelor', '负责后端服务开发和维护，参与系统架构设计。', '1. 熟练掌握Go、Java等后端技术\n2. 有微服务架构经验\n3. 熟悉MySQL、Redis等数据库', '1. 五险一金\n2. 技术培训\n3. 带薪年假', '["Go", "Java", "MySQL", "Redis", "微服务"]', '["后端", "Go", "Java", "微服务", "高并发"]', 'published', 3, 600, 80, 40, NOW(), DATE_ADD(NOW(), INTERVAL 25 DAY));
EOF

log_success "E2E测试数据插入成功"

# 创建索引
log_info "创建数据库索引..."
mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" "$DB_NAME" <<EOF
CREATE INDEX idx_jobs_status ON jobs(status);
CREATE INDEX idx_jobs_company_id ON jobs(company_id);
CREATE INDEX idx_jobs_category_id ON jobs(category_id);
CREATE INDEX idx_jobs_location ON jobs(location);
CREATE INDEX idx_jobs_experience ON jobs(experience_required);
CREATE INDEX idx_jobs_created_at ON jobs(created_at);
CREATE INDEX idx_job_applications_user_id ON job_applications(user_id);
CREATE INDEX idx_job_applications_job_id ON job_applications(job_id);
CREATE INDEX idx_job_applications_status ON job_applications(status);
CREATE INDEX idx_job_favorites_user_id ON job_favorites(user_id);
CREATE INDEX idx_job_favorites_job_id ON job_favorites(job_id);
EOF

log_success "数据库索引创建成功"

# 验证数据
log_info "验证E2E测试数据..."
USER_COUNT=$(mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" "$DB_NAME" -s -e "SELECT COUNT(*) FROM users;")
COMPANY_COUNT=$(mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" "$DB_NAME" -s -e "SELECT COUNT(*) FROM companies;")
JOB_COUNT=$(mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" "$DB_NAME" -s -e "SELECT COUNT(*) FROM jobs;")
CATEGORY_COUNT=$(mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" "$DB_NAME" -s -e "SELECT COUNT(*) FROM job_categories;")

log_success "E2E测试数据库设置完成！"
log_info "数据统计:"
log_info "  - 用户数量: $USER_COUNT"
log_info "  - 企业数量: $COMPANY_COUNT"
log_info "  - 职位数量: $JOB_COUNT"
log_info "  - 分类数量: $CATEGORY_COUNT"
log_info "  - 数据库名称: $DB_NAME"
log_info "  - 数据库主机: $DB_HOST:$DB_PORT"

echo ""
log_success "E2E测试数据库初始化完成！"
log_info "现在可以启动E2E测试服务了"
