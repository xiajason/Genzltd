-- Job Service 数据库修复脚本
-- 创建缺失的表和基础数据

USE jobfirst;

-- 1. 创建简历元数据表
CREATE TABLE IF NOT EXISTS resume_metadata (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    file_path VARCHAR(500),
    file_size INT,
    parsing_status ENUM('pending', 'processing', 'completed', 'failed') DEFAULT 'pending',
    parsing_result TEXT,
    sqlite_db_path VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    INDEX idx_user_id (user_id),
    INDEX idx_parsing_status (parsing_status),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. 创建公司信息表
CREATE TABLE IF NOT EXISTS company_infos (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    short_name VARCHAR(100),
    logo_url VARCHAR(500),
    industry VARCHAR(100),
    location VARCHAR(200),
    description TEXT,
    website VARCHAR(255),
    employee_count INT,
    founded_year INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_industry (industry),
    INDEX idx_location (location)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. 创建职位收藏表
CREATE TABLE IF NOT EXISTS job_favorites (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    job_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_user_job (user_id, job_id),
    INDEX idx_user_id (user_id),
    INDEX idx_job_id (job_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. 插入基础公司信息数据
INSERT IGNORE INTO company_infos (id, name, short_name, industry, location, description) VALUES
(1, 'JobFirst科技有限公司', 'JobFirst', 'technology', '深圳', '领先的AI驱动招聘平台'),
(2, '创新科技有限公司', '创新科技', 'technology', '北京', '专注于人工智能和机器学习'),
(3, '数据智能公司', '数据智能', 'technology', '上海', '大数据分析和商业智能解决方案'),
(4, '腾讯科技', '腾讯', 'technology', '深圳', '互联网科技公司'),
(5, '阿里巴巴集团', '阿里巴巴', 'technology', '杭州', '电商和云计算公司');

-- 5. 插入测试简历数据
INSERT IGNORE INTO resume_metadata (user_id, title, parsing_status, parsing_result) VALUES
(1, 'admin-技术管理简历', 'completed', '{"skills": ["Python", "Go", "JavaScript", "Kubernetes", "Docker"], "experience": "8 years", "education": "Master", "location": "深圳", "position": "技术总监"}'),
(4, 'szjason72-前端开发简历', 'completed', '{"skills": ["JavaScript", "React", "Vue", "Node.js", "TypeScript"], "experience": "3 years", "education": "Bachelor", "location": "深圳", "position": "前端开发工程师"}'),
(4, 'szjason72-全栈开发简历', 'completed', '{"skills": ["Python", "Django", "React", "MySQL", "Redis"], "experience": "2 years", "education": "Bachelor", "location": "深圳", "position": "全栈开发工程师"}');

-- 6. 验证表创建结果
SELECT 'resume_metadata' as table_name, COUNT(*) as record_count FROM resume_metadata
UNION ALL
SELECT 'company_infos' as table_name, COUNT(*) as record_count FROM company_infos
UNION ALL
SELECT 'job_favorites' as table_name, COUNT(*) as record_count FROM job_favorites;

-- 7. 显示表结构验证
SHOW CREATE TABLE resume_metadata;
SHOW CREATE TABLE company_infos;
SHOW CREATE TABLE job_favorites;
