-- MBTI感性AI身份统一实施计划 - 数据库表结构
-- 创建时间: 2025年10月4日
-- 版本: v1.5 (华中师范大学创新版)
-- 基于: 开放生态系统理念 + 花语花卉人格化设计
-- 目标: 构建完整的MBTI开放生态系统数据基础

-- ==================== 数据库初始化 ====================

-- 创建MBTI数据库 (如果不存在)
CREATE DATABASE IF NOT EXISTS mbti_open_ecosystem 
CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE mbti_open_ecosystem;

-- ==================== MBTI核心数据表 ====================

-- 1. MBTI类型定义表
CREATE TABLE IF NOT EXISTS mbti_types (
    id INT PRIMARY KEY AUTO_INCREMENT,
    type_code VARCHAR(4) NOT NULL UNIQUE COMMENT 'MBTI类型代码 (如INTJ)',
    type_name VARCHAR(100) NOT NULL COMMENT 'MBTI类型名称',
    description TEXT COMMENT '类型描述',
    flower_name VARCHAR(100) COMMENT '对应花卉名称',
    flower_meaning TEXT COMMENT '花语含义',
    flower_color VARCHAR(50) COMMENT '花卉颜色',
    personality_traits JSON COMMENT '性格特征 (JSON格式)',
    strengths JSON COMMENT '优势特征 (JSON格式)',
    challenges JSON COMMENT '挑战特征 (JSON格式)',
    career_suggestions JSON COMMENT '职业建议 (JSON格式)',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_type_code (type_code),
    INDEX idx_flower_name (flower_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='MBTI类型定义表';

-- 2. MBTI维度定义表
CREATE TABLE IF NOT EXISTS mbti_dimensions (
    id INT PRIMARY KEY AUTO_INCREMENT,
    dimension_code VARCHAR(2) NOT NULL UNIQUE COMMENT '维度代码 (如E/I)',
    dimension_name VARCHAR(100) NOT NULL COMMENT '维度名称',
    dimension_description TEXT COMMENT '维度描述',
    left_pole VARCHAR(50) COMMENT '左极 (如外向)',
    right_pole VARCHAR(50) COMMENT '右极 (如内向)',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_dimension_code (dimension_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='MBTI维度定义表';

-- 3. MBTI测试题库表
CREATE TABLE IF NOT EXISTS mbti_questions (
    id INT PRIMARY KEY AUTO_INCREMENT,
    question_text TEXT NOT NULL COMMENT '题目内容',
    question_type ENUM('standard', 'simplified', 'advanced') DEFAULT 'standard' COMMENT '题目类型',
    dimension_code VARCHAR(2) NOT NULL COMMENT '测试维度',
    question_order INT COMMENT '题目顺序',
    is_active BOOLEAN DEFAULT TRUE COMMENT '是否启用',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (dimension_code) REFERENCES mbti_dimensions(dimension_code),
    INDEX idx_dimension_code (dimension_code),
    INDEX idx_question_type (question_type),
    INDEX idx_question_order (question_order)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='MBTI测试题库表';

-- 4. 用户MBTI测试记录表
CREATE TABLE IF NOT EXISTS user_mbti_tests (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL COMMENT '用户ID',
    test_type ENUM('standard', 'simplified', 'advanced') DEFAULT 'standard' COMMENT '测试类型',
    test_status ENUM('in_progress', 'completed', 'abandoned') DEFAULT 'in_progress' COMMENT '测试状态',
    start_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '开始时间',
    end_time TIMESTAMP NULL COMMENT '结束时间',
    total_questions INT DEFAULT 0 COMMENT '总题数',
    answered_questions INT DEFAULT 0 COMMENT '已回答题数',
    test_duration INT COMMENT '测试时长(秒)',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_user_id (user_id),
    INDEX idx_test_status (test_status),
    INDEX idx_start_time (start_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户MBTI测试记录表';

-- 5. 用户MBTI测试答案表
CREATE TABLE IF NOT EXISTS user_mbti_answers (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    test_id BIGINT NOT NULL COMMENT '测试记录ID',
    question_id INT NOT NULL COMMENT '题目ID',
    user_id BIGINT NOT NULL COMMENT '用户ID',
    answer_value ENUM('A', 'B', 'C', 'D', 'E') COMMENT '答案选项',
    answer_score INT COMMENT '答案分数',
    answered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '答题时间',
    
    FOREIGN KEY (test_id) REFERENCES user_mbti_tests(id) ON DELETE CASCADE,
    FOREIGN KEY (question_id) REFERENCES mbti_questions(id),
    UNIQUE KEY uk_test_question (test_id, question_id),
    INDEX idx_user_id (user_id),
    INDEX idx_answered_at (answered_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户MBTI测试答案表';

-- 6. 用户MBTI评估结果表
CREATE TABLE IF NOT EXISTS user_mbti_results (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL COMMENT '用户ID',
    test_id BIGINT NOT NULL COMMENT '测试记录ID',
    mbti_type VARCHAR(4) NOT NULL COMMENT 'MBTI类型',
    e_score INT COMMENT 'E维度分数',
    i_score INT COMMENT 'I维度分数',
    s_score INT COMMENT 'S维度分数',
    n_score INT COMMENT 'N维度分数',
    t_score INT COMMENT 'T维度分数',
    f_score INT COMMENT 'F维度分数',
    j_score INT COMMENT 'J维度分数',
    p_score INT COMMENT 'P维度分数',
    confidence_level DECIMAL(3,2) COMMENT '置信度 (0-1)',
    assessment_method ENUM('local', 'api', 'hybrid') DEFAULT 'local' COMMENT '评估方法',
    result_data JSON COMMENT '详细结果数据',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (test_id) REFERENCES user_mbti_tests(id) ON DELETE CASCADE,
    FOREIGN KEY (mbti_type) REFERENCES mbti_types(type_code),
    INDEX idx_user_id (user_id),
    INDEX idx_mbti_type (mbti_type),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户MBTI评估结果表';

-- ==================== 花语花卉人格化系统 ====================

-- 7. 花卉信息表
CREATE TABLE IF NOT EXISTS flowers (
    id INT PRIMARY KEY AUTO_INCREMENT,
    flower_name VARCHAR(100) NOT NULL UNIQUE COMMENT '花卉名称',
    flower_scientific_name VARCHAR(200) COMMENT '学名',
    flower_color VARCHAR(50) COMMENT '主要颜色',
    flower_season VARCHAR(50) COMMENT '开花季节',
    flower_origin VARCHAR(100) COMMENT '原产地',
    flower_meaning TEXT COMMENT '花语含义',
    flower_description TEXT COMMENT '花卉描述',
    flower_image_url VARCHAR(500) COMMENT '花卉图片URL',
    personality_associations JSON COMMENT '性格关联特征',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_flower_name (flower_name),
    INDEX idx_flower_color (flower_color)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='花卉信息表';

-- 8. MBTI类型与花卉映射表
CREATE TABLE IF NOT EXISTS mbti_flower_mappings (
    id INT PRIMARY KEY AUTO_INCREMENT,
    mbti_type VARCHAR(4) NOT NULL COMMENT 'MBTI类型',
    flower_id INT NOT NULL COMMENT '花卉ID',
    mapping_strength DECIMAL(3,2) DEFAULT 1.00 COMMENT '映射强度 (0-1)',
    mapping_reason TEXT COMMENT '映射理由',
    is_primary BOOLEAN DEFAULT FALSE COMMENT '是否为主要映射',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (mbti_type) REFERENCES mbti_types(type_code),
    FOREIGN KEY (flower_id) REFERENCES flowers(id),
    UNIQUE KEY uk_mbti_flower (mbti_type, flower_id),
    INDEX idx_mbti_type (mbti_type),
    INDEX idx_flower_id (flower_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='MBTI类型与花卉映射表';

-- ==================== 兼容性匹配系统 ====================

-- 9. MBTI类型兼容性矩阵表
CREATE TABLE IF NOT EXISTS mbti_compatibility_matrix (
    id INT PRIMARY KEY AUTO_INCREMENT,
    type_a VARCHAR(4) NOT NULL COMMENT '类型A',
    type_b VARCHAR(4) NOT NULL COMMENT '类型B',
    compatibility_score DECIMAL(3,2) COMMENT '兼容性分数 (0-1)',
    relationship_type VARCHAR(50) COMMENT '关系类型',
    compatibility_description TEXT COMMENT '兼容性描述',
    communication_tips JSON COMMENT '沟通建议',
    conflict_resolution JSON COMMENT '冲突解决建议',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (type_a) REFERENCES mbti_types(type_code),
    FOREIGN KEY (type_b) REFERENCES mbti_types(type_code),
    UNIQUE KEY uk_type_pair (type_a, type_b),
    INDEX idx_type_a (type_a),
    INDEX idx_type_b (type_b)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='MBTI类型兼容性矩阵表';

-- ==================== 职业匹配系统 ====================

-- 10. 职业信息表
CREATE TABLE IF NOT EXISTS careers (
    id INT PRIMARY KEY AUTO_INCREMENT,
    career_name VARCHAR(200) NOT NULL COMMENT '职业名称',
    career_category VARCHAR(100) COMMENT '职业类别',
    career_description TEXT COMMENT '职业描述',
    required_skills JSON COMMENT '所需技能',
    career_prospects TEXT COMMENT '职业前景',
    salary_range VARCHAR(100) COMMENT '薪资范围',
    education_requirements VARCHAR(200) COMMENT '教育要求',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_career_name (career_name),
    INDEX idx_career_category (career_category)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='职业信息表';

-- 11. MBTI类型与职业匹配表
CREATE TABLE IF NOT EXISTS mbti_career_mappings (
    id INT PRIMARY KEY AUTO_INCREMENT,
    mbti_type VARCHAR(4) NOT NULL COMMENT 'MBTI类型',
    career_id INT NOT NULL COMMENT '职业ID',
    match_score DECIMAL(3,2) COMMENT '匹配分数 (0-1)',
    match_reason TEXT COMMENT '匹配理由',
    is_recommended BOOLEAN DEFAULT FALSE COMMENT '是否推荐',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (mbti_type) REFERENCES mbti_types(type_code),
    FOREIGN KEY (career_id) REFERENCES careers(id),
    UNIQUE KEY uk_mbti_career (mbti_type, career_id),
    INDEX idx_mbti_type (mbti_type),
    INDEX idx_career_id (career_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='MBTI类型与职业匹配表';

-- ==================== 分析报告系统 ====================

-- 12. 用户MBTI分析报告表
CREATE TABLE IF NOT EXISTS user_mbti_reports (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL COMMENT '用户ID',
    result_id BIGINT NOT NULL COMMENT '评估结果ID',
    report_type ENUM('personal', 'team', 'career') DEFAULT 'personal' COMMENT '报告类型',
    report_title VARCHAR(200) COMMENT '报告标题',
    report_content JSON COMMENT '报告内容',
    report_summary TEXT COMMENT '报告摘要',
    flower_analysis JSON COMMENT '花卉人格分析',
    career_analysis JSON COMMENT '职业分析',
    growth_suggestions JSON COMMENT '成长建议',
    report_status ENUM('generating', 'completed', 'failed') DEFAULT 'generating' COMMENT '报告状态',
    generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (result_id) REFERENCES user_mbti_results(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_result_id (result_id),
    INDEX idx_report_type (report_type),
    INDEX idx_generated_at (generated_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户MBTI分析报告表';

-- ==================== 开放生态系统支持 ====================

-- 13. 第三方API服务配置表
CREATE TABLE IF NOT EXISTS third_party_apis (
    id INT PRIMARY KEY AUTO_INCREMENT,
    api_name VARCHAR(100) NOT NULL UNIQUE COMMENT 'API服务名称',
    api_provider VARCHAR(100) COMMENT 'API提供商',
    api_endpoint VARCHAR(500) COMMENT 'API端点',
    api_key VARCHAR(500) COMMENT 'API密钥',
    api_secret VARCHAR(500) COMMENT 'API密钥',
    api_status ENUM('active', 'inactive', 'maintenance') DEFAULT 'active' COMMENT 'API状态',
    rate_limit INT COMMENT '速率限制',
    cost_per_request DECIMAL(10,4) COMMENT '每次请求成本',
    api_config JSON COMMENT 'API配置',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_api_name (api_name),
    INDEX idx_api_status (api_status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='第三方API服务配置表';

-- 14. API调用记录表
CREATE TABLE IF NOT EXISTS api_call_logs (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    api_id INT NOT NULL COMMENT 'API服务ID',
    user_id BIGINT COMMENT '用户ID',
    request_type VARCHAR(50) COMMENT '请求类型',
    request_data JSON COMMENT '请求数据',
    response_data JSON COMMENT '响应数据',
    response_time INT COMMENT '响应时间(毫秒)',
    status_code INT COMMENT '状态码',
    success BOOLEAN DEFAULT TRUE COMMENT '是否成功',
    error_message TEXT COMMENT '错误信息',
    cost DECIMAL(10,4) COMMENT '调用成本',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (api_id) REFERENCES third_party_apis(id),
    INDEX idx_api_id (api_id),
    INDEX idx_user_id (user_id),
    INDEX idx_created_at (created_at),
    INDEX idx_success (success)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='API调用记录表';

-- ==================== 系统配置表 ====================

-- 15. 系统配置表
CREATE TABLE IF NOT EXISTS system_configs (
    id INT PRIMARY KEY AUTO_INCREMENT,
    config_key VARCHAR(100) NOT NULL UNIQUE COMMENT '配置键',
    config_value TEXT COMMENT '配置值',
    config_type ENUM('string', 'number', 'boolean', 'json') DEFAULT 'string' COMMENT '配置类型',
    config_description TEXT COMMENT '配置描述',
    is_public BOOLEAN DEFAULT FALSE COMMENT '是否公开',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_config_key (config_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='系统配置表';

-- ==================== 初始化数据 ====================

-- 插入MBTI维度数据
INSERT INTO mbti_dimensions (dimension_code, dimension_name, dimension_description, left_pole, right_pole) VALUES
('EI', '能量方向', '关注外部世界还是内心世界', '外向(E)', '内向(I)'),
('SN', '信息收集', '关注具体事实还是抽象概念', '感觉(S)', '直觉(N)'),
('TF', '决策方式', '基于逻辑还是价值观', '思考(T)', '情感(F)'),
('JP', '生活方式', '喜欢计划还是灵活应变', '判断(J)', '感知(P)');

-- 插入基础MBTI类型数据 (带花语花卉映射)
INSERT INTO mbti_types (type_code, type_name, description, flower_name, flower_meaning, flower_color, personality_traits, strengths, challenges, career_suggestions) VALUES
('INTJ', '建筑师', '富有想象力和战略性的思想家，一切皆在计划之中', '紫罗兰', '智慧、独立、神秘', '紫色', '["独立", "战略", "理性", "专注"]', '["战略思维", "独立自主", "理性分析", "专注力强"]', '["过于独立", "缺乏耐心", "过于理性", "不善于表达情感"]', '["软件工程师", "建筑师", "科学家", "投资分析师"]'),
('INTP', '思想家', '具有创新精神的发明家，对知识有着止不住的渴望', '紫色菊花', '智慧、独立、创新', '紫色', '["好奇", "分析", "独立", "灵活"]', '["逻辑思维", "创新精神", "独立思考", "学习能力强"]', '["缺乏执行力", "过于理论化", "社交困难", "不注重细节"]', '["程序员", "研究员", "哲学家", "系统分析师"]'),
('ENTJ', '指挥官', '大胆，富有想象力，意志强烈的领导者，总能找到或创造解决方法', '红玫瑰', '领导力、热情、决心', '红色', '["领导力", "决断", "自信", "目标导向"]', '["领导能力", "执行力强", "战略思维", "自信果断"]', '["过于强势", "缺乏耐心", "不善于倾听", "过于完美主义"]', '["CEO", "律师", "投资银行家", "政治家"]'),
('ENTP', '辩论家', '聪明好奇的思想家，不会放弃任何智力挑战', '向日葵', '乐观、创新、活力', '黄色', '["创新", "灵活", "热情", "好奇"]', '["创新思维", "适应性强", "沟通能力", "学习能力强"]', '["缺乏耐心", "过于理想化", "不注重细节", "难以坚持"]', '["企业家", "律师", "记者", "营销专家"]'),
('INFJ', '提倡者', '安静而神秘，同时鼓舞人心的理想主义者', '白色百合', '纯洁、理想、智慧', '白色', '["理想主义", "直觉", "创意", "独立"]', '["洞察力强", "创造力", "理想主义", "同理心"]', '["过于理想化", "敏感", "难以理解", "完美主义"]', '["心理咨询师", "作家", "艺术家", "社会工作者"]'),
('INFP', '调停者', '富有诗意，善良且利他主义，总是热切地想要帮助正义事业', '粉色樱花', '温柔、理想、纯真', '粉色', '["理想主义", "价值观", "灵活", "忠诚"]', '["创造力", "同理心", "价值观驱动", "灵活性"]', '["过于敏感", "缺乏执行力", "难以做决定", "过于理想化"]', '["艺术家", "作家", "心理咨询师", "社会工作者"]'),
('ENFJ', '主人公', '富有魅力，鼓舞人心的领导者，有使听众着迷的能力', '橙色郁金香', '热情、领导力、温暖', '橙色', '["领导力", "同理心", "热情", "社交"]', '["领导能力", "沟通能力", "同理心", "激励他人"]', '["过于理想化", "过于关注他人", "难以拒绝", "完美主义"]', '["教师", "培训师", "人力资源", "政治家"]'),
('ENFP', '竞选者', '热情，有创造力，社交能力强的自由精神，总是能找到微笑的理由', '红色菊花', '热情、创造力、活力', '红色', '["热情", "创造力", "社交", "灵活"]', '["创造力", "热情", "社交能力", "适应性强"]', '["缺乏专注", "过于情绪化", "难以做决定", "缺乏耐心"]', '["演员", "作家", "营销专家", "活动策划"]'),
('ISTJ', '物流师', '实用性和事实导向，可靠性无可争议', '白色菊花', '务实、坚韧、可靠', '白色', '["务实", "可靠", "有序", "忠诚"]', '["可靠性", "执行力", "组织能力", "忠诚度"]', '["缺乏灵活性", "抗拒变化", "过于传统", "不善于创新"]', '["会计师", "工程师", "医生", "律师"]'),
('ISFJ', '守护者', '非常专注和温暖的守护者，时刻准备着保护爱着的人们', '粉色康乃馨', '关爱、保护、温柔', '粉色', '["关爱", "负责", "耐心", "忠诚"]', '["责任心", "同理心", "耐心", "忠诚度"]', '["过于自我牺牲", "难以拒绝", "抗拒变化", "过于传统"]', '["护士", "教师", "社会工作者", "行政助理"]'),
('ESTJ', '总经理', '出色的管理者，在管理事情或人员方面无与伦比', '黄色向日葵', '领导力、阳光、活力', '黄色', '["组织", "领导", "实用", "负责"]', '["领导能力", "组织能力", "执行力", "责任心"]', '["缺乏灵活性", "过于严格", "不善于倾听", "抗拒创新"]', '["经理", "法官", "军官", "项目经理"]'),
('ESFJ', '执政官', '极有同情心，爱社交，总是渴望帮助', '橙色玫瑰', '温暖、社交、关爱', '橙色', '["社交", "负责", "温暖", "合作"]', '["社交能力", "责任心", "合作精神", "同理心"]', '["过于关注他人", "难以拒绝", "抗拒变化", "过于传统"]', '["护士", "教师", "人力资源", "客户服务"]'),
('ISTP', '鉴赏家', '大胆而实际的实验家，擅长使用各种工具', '蓝色矢车菊', '独立、冷静、实用', '蓝色', '["实用", "灵活", "冷静", "独立"]', '["实用技能", "灵活性", "冷静分析", "独立性"]', '["缺乏计划", "不善于表达", "难以承诺", "缺乏耐心"]', '["机械师", "飞行员", "程序员", "摄影师"]'),
('ISFP', '探险家', '灵活有魅力的艺术家，时刻准备着探索新的可能性', '紫色薰衣草', '艺术、敏感、独立', '紫色', '["艺术", "敏感", "灵活", "独立"]', '["艺术天赋", "敏感性", "灵活性", "独立性"]', '["过于敏感", "难以做决定", "缺乏自信", "难以坚持"]', '["艺术家", "设计师", "音乐家", "摄影师"]'),
('ESTP', '企业家', '聪明，精力充沛，善于感知，真正享受生活', '红色罂粟', '活力、冒险、热情', '红色', '["活力", "冒险", "实用", "社交"]', '["活力", "冒险精神", "实用技能", "社交能力"]', '["缺乏耐心", "难以专注", "不善于规划", "过于冲动"]', '["销售员", "运动员", "演员", "企业家"]'),
('ESFP', '娱乐家', '自发的，精力充沛而热情的表演者', '黄色菊花', '外向、热情、社交', '黄色', '["外向", "热情", "社交", "灵活"]', '["社交能力", "热情", "灵活性", "表演天赋"]', '["缺乏专注", "难以做决定", "过于情绪化", "缺乏耐心"]', '["演员", "主持人", "销售员", "活动策划"]');

-- 插入基础花卉数据
INSERT INTO flowers (flower_name, flower_scientific_name, flower_color, flower_season, flower_origin, flower_meaning, flower_description, personality_associations) VALUES
('紫罗兰', 'Viola odorata', '紫色', '春季', '欧洲', '智慧、独立、神秘', '紫罗兰象征着智慧和独立，如同INTJ型人格的理性与神秘', '["智慧", "独立", "神秘", "理性"]'),
('紫色菊花', 'Chrysanthemum morifolium', '紫色', '秋季', '中国', '智慧、独立、创新', '紫色菊花代表智慧和创新，如同INTP型人格的独立思考', '["智慧", "独立", "创新", "思考"]'),
('红玫瑰', 'Rosa rubiginosa', '红色', '全年', '亚洲', '领导力、热情、决心', '红玫瑰象征着领导力和决心，如同ENTJ型人格的强势领导', '["领导力", "热情", "决心", "强势"]'),
('向日葵', 'Helianthus annuus', '黄色', '夏季', '北美', '乐观、创新、活力', '向日葵代表乐观和活力，如同ENTP型人格的创新精神', '["乐观", "创新", "活力", "阳光"]'),
('白色百合', 'Lilium candidum', '白色', '夏季', '地中海', '纯洁、理想、智慧', '白色百合象征纯洁和理想，如同INFJ型人格的理想主义', '["纯洁", "理想", "智慧", "优雅"]'),
('粉色樱花', 'Prunus serrulata', '粉色', '春季', '日本', '温柔、理想、纯真', '粉色樱花代表温柔和纯真，如同INFP型人格的纯真理想', '["温柔", "理想", "纯真", "浪漫"]'),
('橙色郁金香', 'Tulipa gesneriana', '橙色', '春季', '土耳其', '热情、领导力、温暖', '橙色郁金香象征热情和温暖，如同ENFJ型人格的领导魅力', '["热情", "领导力", "温暖", "魅力"]'),
('红色菊花', 'Chrysanthemum indicum', '红色', '秋季', '中国', '热情、创造力、活力', '红色菊花代表热情和活力，如同ENFP型人格的创造力', '["热情", "创造力", "活力", "激情"]'),
('白色菊花', 'Chrysanthemum morifolium', '白色', '秋季', '中国', '务实、坚韧、可靠', '白色菊花象征务实和可靠，如同ISTJ型人格的可靠性', '["务实", "坚韧", "可靠", "稳重"]'),
('粉色康乃馨', 'Dianthus caryophyllus', '粉色', '全年', '地中海', '关爱、保护、温柔', '粉色康乃馨代表关爱和保护，如同ISFJ型人格的守护特质', '["关爱", "保护", "温柔", "守护"]'),
('黄色向日葵', 'Helianthus annuus', '黄色', '夏季', '北美', '领导力、阳光、活力', '黄色向日葵象征阳光和活力，如同ESTJ型人格的领导力', '["领导力", "阳光", "活力", "积极"]'),
('橙色玫瑰', 'Rosa hybrida', '橙色', '全年', '亚洲', '温暖、社交、关爱', '橙色玫瑰代表温暖和关爱，如同ESFJ型人格的温暖特质', '["温暖", "社交", "关爱", "友善"]'),
('蓝色矢车菊', 'Centaurea cyanus', '蓝色', '夏季', '欧洲', '独立、冷静、实用', '蓝色矢车菊象征冷静和独立，如同ISTP型人格的实用主义', '["独立", "冷静", "实用", "理性"]'),
('紫色薰衣草', 'Lavandula angustifolia', '紫色', '夏季', '地中海', '艺术、敏感、独立', '紫色薰衣草代表艺术和敏感，如同ISFP型人格的艺术天赋', '["艺术", "敏感", "独立", "优雅"]'),
('红色罂粟', 'Papaver rhoeas', '红色', '夏季', '欧洲', '活力、冒险、热情', '红色罂粟象征活力和冒险，如同ESTP型人格的冒险精神', '["活力", "冒险", "热情", "勇敢"]'),
('黄色菊花', 'Chrysanthemum morifolium', '黄色', '秋季', '中国', '外向、热情、社交', '黄色菊花代表外向和社交，如同ESFP型人格的社交能力', '["外向", "热情", "社交", "活跃"]');

-- 插入MBTI类型与花卉映射数据
INSERT INTO mbti_flower_mappings (mbti_type, flower_id, mapping_strength, mapping_reason, is_primary) 
SELECT 
    mt.type_code,
    f.id,
    1.00,
    CONCAT('MBTI类型 ', mt.type_name, ' 与 ', f.flower_name, ' 的完美匹配'),
    TRUE
FROM mbti_types mt
JOIN flowers f ON mt.flower_name = f.flower_name;

-- 插入系统配置数据
INSERT INTO system_configs (config_key, config_value, config_type, config_description, is_public) VALUES
('mbti_test_standard_questions', '93', 'number', '标准MBTI测试题数', TRUE),
('mbti_test_simplified_questions', '28', 'number', '简化MBTI测试题数', TRUE),
('mbti_test_time_limit', '1800', 'number', 'MBTI测试时间限制(秒)', TRUE),
('flower_personality_enabled', 'true', 'boolean', '是否启用花语花卉人格化功能', TRUE),
('hzun_integration_enabled', 'true', 'boolean', '是否启用华中师范大学创新元素', TRUE),
('local_assessment_priority', 'true', 'boolean', '是否优先使用本地评估', TRUE),
('api_enhancement_enabled', 'false', 'boolean', '是否启用外部API增强功能', FALSE);

-- ==================== 创建视图 ====================

-- 创建用户MBTI结果详细视图
CREATE VIEW user_mbti_results_detailed AS
SELECT 
    umr.id,
    umr.user_id,
    umr.test_id,
    umr.mbti_type,
    mt.type_name,
    mt.description,
    mt.flower_name,
    mt.flower_meaning,
    mt.flower_color,
    umr.e_score,
    umr.i_score,
    umr.s_score,
    umr.n_score,
    umr.t_score,
    umr.f_score,
    umr.j_score,
    umr.p_score,
    umr.confidence_level,
    umr.assessment_method,
    umr.created_at
FROM user_mbti_results umr
JOIN mbti_types mt ON umr.mbti_type = mt.type_code;

-- 创建MBTI类型花卉映射视图
CREATE VIEW mbti_flower_mappings_detailed AS
SELECT 
    mfm.id,
    mfm.mbti_type,
    mt.type_name,
    mt.description as type_description,
    f.flower_name,
    f.flower_color,
    f.flower_meaning,
    f.personality_associations,
    mfm.mapping_strength,
    mfm.mapping_reason,
    mfm.is_primary
FROM mbti_flower_mappings mfm
JOIN mbti_types mt ON mfm.mbti_type = mt.type_code
JOIN flowers f ON mfm.flower_id = f.id;

-- ==================== 创建存储过程 ====================

-- 创建计算MBTI类型的存储过程
DELIMITER //
CREATE PROCEDURE CalculateMBTIType(
    IN p_user_id BIGINT,
    IN p_test_id BIGINT,
    OUT p_mbti_type VARCHAR(4),
    OUT p_confidence DECIMAL(3,2)
)
BEGIN
    DECLARE v_e_score INT DEFAULT 0;
    DECLARE v_i_score INT DEFAULT 0;
    DECLARE v_s_score INT DEFAULT 0;
    DECLARE v_n_score INT DEFAULT 0;
    DECLARE v_t_score INT DEFAULT 0;
    DECLARE v_f_score INT DEFAULT 0;
    DECLARE v_j_score INT DEFAULT 0;
    DECLARE v_p_score INT DEFAULT 0;
    
    -- 计算各维度分数
    SELECT 
        SUM(CASE WHEN q.dimension_code = 'EI' AND uma.answer_score > 0 THEN uma.answer_score ELSE 0 END) INTO v_e_score,
        SUM(CASE WHEN q.dimension_code = 'EI' AND uma.answer_score < 0 THEN ABS(uma.answer_score) ELSE 0 END) INTO v_i_score,
        SUM(CASE WHEN q.dimension_code = 'SN' AND uma.answer_score > 0 THEN uma.answer_score ELSE 0 END) INTO v_s_score,
        SUM(CASE WHEN q.dimension_code = 'SN' AND uma.answer_score < 0 THEN ABS(uma.answer_score) ELSE 0 END) INTO v_n_score,
        SUM(CASE WHEN q.dimension_code = 'TF' AND uma.answer_score > 0 THEN uma.answer_score ELSE 0 END) INTO v_t_score,
        SUM(CASE WHEN q.dimension_code = 'TF' AND uma.answer_score < 0 THEN ABS(uma.answer_score) ELSE 0 END) INTO v_f_score,
        SUM(CASE WHEN q.dimension_code = 'JP' AND uma.answer_score > 0 THEN uma.answer_score ELSE 0 END) INTO v_j_score,
        SUM(CASE WHEN q.dimension_code = 'JP' AND uma.answer_score < 0 THEN ABS(uma.answer_score) ELSE 0 END) INTO v_p_score
    FROM user_mbti_answers uma
    JOIN mbti_questions q ON uma.question_id = q.id
    WHERE uma.test_id = p_test_id;
    
    -- 确定MBTI类型
    SET p_mbti_type = CONCAT(
        CASE WHEN v_e_score > v_i_score THEN 'E' ELSE 'I' END,
        CASE WHEN v_s_score > v_n_score THEN 'S' ELSE 'N' END,
        CASE WHEN v_t_score > v_f_score THEN 'T' ELSE 'F' END,
        CASE WHEN v_j_score > v_p_score THEN 'J' ELSE 'P' END
    );
    
    -- 计算置信度
    SET p_confidence = (
        ABS(v_e_score - v_i_score) + 
        ABS(v_s_score - v_n_score) + 
        ABS(v_t_score - v_f_score) + 
        ABS(v_j_score - v_p_score)
    ) / (v_e_score + v_i_score + v_s_score + v_n_score + v_t_score + v_f_score + v_j_score + v_p_score);
    
    -- 插入结果
    INSERT INTO user_mbti_results (
        user_id, test_id, mbti_type, 
        e_score, i_score, s_score, n_score, 
        t_score, f_score, j_score, p_score, 
        confidence_level, assessment_method
    ) VALUES (
        p_user_id, p_test_id, p_mbti_type,
        v_e_score, v_i_score, v_s_score, v_n_score,
        v_t_score, v_f_score, v_j_score, v_p_score,
        p_confidence, 'local'
    );
END //
DELIMITER ;

-- ==================== 创建触发器 ====================

-- 创建测试完成时自动计算结果的触发器
DELIMITER //
CREATE TRIGGER tr_test_completed
AFTER UPDATE ON user_mbti_tests
FOR EACH ROW
BEGIN
    IF NEW.test_status = 'completed' AND OLD.test_status != 'completed' THEN
        -- 更新结束时间
        UPDATE user_mbti_tests 
        SET end_time = NOW(),
            test_duration = TIMESTAMPDIFF(SECOND, start_time, NOW())
        WHERE id = NEW.id;
        
        -- 自动计算MBTI类型
        CALL CalculateMBTIType(NEW.user_id, NEW.id, @mbti_type, @confidence);
    END IF;
END //
DELIMITER ;

-- ==================== 创建索引优化 ====================

-- 为常用查询创建复合索引
CREATE INDEX idx_user_test_status ON user_mbti_tests(user_id, test_status);
CREATE INDEX idx_user_result_type ON user_mbti_results(user_id, mbti_type);
CREATE INDEX idx_test_question_dimension ON mbti_questions(test_type, dimension_code);
CREATE INDEX idx_flower_mapping_primary ON mbti_flower_mappings(mbti_type, is_primary);

-- ==================== 完成信息 ====================

SELECT 'MBTI感性AI身份统一实施计划数据库表结构创建完成！' as message;
SELECT '版本: v1.5 (华中师范大学创新版)' as version;
SELECT '特色: 花语花卉人格化设计 + 开放生态系统架构' as features;
SELECT '支持: 本地题库 + 外部API混合评估策略' as support;
SELECT NOW() as created_at;
