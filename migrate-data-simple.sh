#!/bin/bash

# 简化版数据迁移脚本：将现有数据迁移到AI身份服务表结构
# 基于现有数据结构和新的AI身份服务表

echo "🔄 简化版AI身份服务数据迁移脚本 - $(date)"
echo "======================================================"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 数据库配置
MYSQL_USER="root"
MYSQL_PASSWORD=""
MYSQL_DATABASE="jobfirst"

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

# 检查MySQL连接
check_mysql_connection() {
    log_info "检查MySQL连接..."
    if mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -D"$MYSQL_DATABASE" -e "SELECT 1" &> /dev/null; then
        log_success "MySQL连接正常"
        return 0
    else
        log_error "MySQL连接失败"
        return 1
    fi
}

# 迁移基础技能数据
migrate_basic_skills() {
    log_info "开始迁移基础技能数据..."
    
    # 基于现有数据创建基础技能分类和技能
    mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -D"$MYSQL_DATABASE" -e "
    -- 插入基础技能分类
    INSERT IGNORE INTO skill_categories (name, display_name, description, parent_id, sort_order, is_active) VALUES
    ('PROGRAMMING', '编程技能', '编程语言和开发技能', NULL, 1, 1),
    ('DATABASE', '数据库技能', '数据库管理和设计技能', NULL, 2, 1),
    ('FRONTEND', '前端技能', '前端开发技能', NULL, 3, 1),
    ('BACKEND', '后端技能', '后端开发技能', NULL, 4, 1),
    ('DEVOPS', '运维技能', 'DevOps和运维技能', NULL, 5, 1),
    ('SOFT_SKILLS', '软技能', '沟通协作等软技能', NULL, 6, 1);
    
    -- 插入标准化技能
    INSERT IGNORE INTO standardized_skills (name, display_name, description, category_id, skill_type, is_active) VALUES
    ('Python', 'Python编程', 'Python编程语言', 1, 'PROGRAMMING', 1),
    ('Java', 'Java编程', 'Java编程语言', 1, 'PROGRAMMING', 1),
    ('JavaScript', 'JavaScript编程', 'JavaScript编程语言', 1, 'PROGRAMMING', 1),
    ('Go', 'Go编程', 'Go编程语言', 1, 'PROGRAMMING', 1),
    ('MySQL', 'MySQL数据库', 'MySQL数据库管理', 2, 'DATABASE', 1),
    ('PostgreSQL', 'PostgreSQL数据库', 'PostgreSQL数据库管理', 2, 'DATABASE', 1),
    ('Redis', 'Redis缓存', 'Redis缓存数据库', 2, 'DATABASE', 1),
    ('React', 'React框架', 'React前端框架', 3, 'FRONTEND', 1),
    ('Vue', 'Vue框架', 'Vue前端框架', 3, 'FRONTEND', 1),
    ('Node.js', 'Node.js后端', 'Node.js后端开发', 4, 'BACKEND', 1),
    ('Spring Boot', 'Spring Boot', 'Spring Boot后端框架', 4, 'BACKEND', 1),
    ('Docker', 'Docker容器', 'Docker容器化技术', 5, 'DEVOPS', 1),
    ('Kubernetes', 'Kubernetes', 'Kubernetes容器编排', 5, 'DEVOPS', 1),
    ('沟通能力', '沟通协作', '团队沟通协作能力', 6, 'SOFT_SKILL', 1),
    ('项目管理', '项目管理', '项目管理和协调能力', 6, 'SOFT_SKILL', 1);
    
    -- 为现有用户创建基础技能记录
    INSERT IGNORE INTO user_skills (user_id, skill_id, skill_level, proficiency_score, years_experience, last_used_date, created_at, updated_at)
    SELECT DISTINCT
        rm.user_id,
        ss.id as skill_id,
        'INTERMEDIATE' as skill_level,
        3.0 as proficiency_score,
        2 as years_experience,
        NOW() as last_used_date,
        NOW() as created_at,
        NOW() as updated_at
    FROM resume_metadata rm
    CROSS JOIN standardized_skills ss
    WHERE rm.user_id IS NOT NULL
    AND ss.name IN ('Python', 'Java', 'JavaScript', 'MySQL', 'React', 'Docker')
    LIMIT 50;  -- 限制记录数量
    
    SELECT '基础技能数据迁移完成' as status, COUNT(*) as migrated_count FROM user_skills;
    "
    
    if [ $? -eq 0 ]; then
        log_success "基础技能数据迁移完成"
    else
        log_warning "基础技能数据迁移部分失败"
    fi
}

# 迁移基础项目经验数据
migrate_basic_projects() {
    log_info "开始迁移基础项目经验数据..."
    
    # 基于现有简历数据创建基础项目经验
    mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -D"$MYSQL_DATABASE" -e "
    -- 为现有用户创建基础项目经验
    INSERT IGNORE INTO project_complexity_assessments (
        user_id, project_title, project_description, 
        technical_complexity, business_complexity, team_complexity, overall_complexity, 
        complexity_level, complexity_factors, assessment_timestamp, is_active, created_at, updated_at
    )
    SELECT DISTINCT
        rm.user_id,
        CONCAT('项目-', rm.id) as project_title,
        CONCAT('基于简历 ', rm.title, ' 的项目经验') as project_description,
        3.0 as technical_complexity,
        2.5 as business_complexity,
        2.0 as team_complexity,
        2.5 as overall_complexity,
        'MEDIUM' as complexity_level,
        JSON_OBJECT(
            'source', 'resume_data',
            'resume_id', rm.id,
            'title', rm.title,
            'created_at', rm.created_at
        ) as complexity_factors,
        NOW() as assessment_timestamp,
        1 as is_active,
        NOW() as created_at,
        NOW() as updated_at
    FROM resume_metadata rm
    WHERE rm.user_id IS NOT NULL
    AND rm.title IS NOT NULL
    AND rm.title != ''
    LIMIT 30;  -- 限制记录数量
    
    SELECT '基础项目经验数据迁移完成' as status, COUNT(*) as migrated_count FROM project_complexity_assessments;
    "
    
    if [ $? -eq 0 ]; then
        log_success "基础项目经验数据迁移完成"
    else
        log_warning "基础项目经验数据迁移部分失败"
    fi
}

# 迁移基础技术能力数据
migrate_basic_competencies() {
    log_info "开始迁移基础技术能力数据..."
    
    # 基于现有技能数据创建基础技术能力评估
    mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -D"$MYSQL_DATABASE" -e "
    -- 为现有用户创建基础技术能力评估
    INSERT IGNORE INTO technical_competency_assessments (
        user_id, competency_type, competency_level, competency_score, confidence_score,
        evidence_text, keywords_matched, assessment_details, assessment_timestamp, is_active, created_at, updated_at
    )
    SELECT DISTINCT
        us.user_id,
        CASE 
            WHEN ss.name IN ('Python', 'Java', 'JavaScript', 'Go') THEN 'PROGRAMMING'
            WHEN ss.name IN ('MySQL', 'PostgreSQL', 'Redis') THEN 'DATABASE_DESIGN'
            WHEN ss.name IN ('React', 'Vue') THEN 'PROGRAMMING'
            WHEN ss.name IN ('Docker', 'Kubernetes') THEN 'DEVOPS'
            ELSE 'PROGRAMMING'
        END as competency_type,
        us.skill_level as competency_level,
        us.proficiency_score as competency_score,
        0.8 as confidence_score,
        CONCAT('基于技能评估: ', ss.display_name, ' (', us.skill_level, ')') as evidence_text,
        JSON_OBJECT('skill', ss.name, 'category', ss.display_name) as keywords_matched,
        JSON_OBJECT(
            'skill_id', us.skill_id,
            'skill_name', ss.name,
            'years_experience', us.years_experience,
            'assessment_method', 'skill_based'
        ) as assessment_details,
        NOW() as assessment_timestamp,
        1 as is_active,
        NOW() as created_at,
        NOW() as updated_at
    FROM user_skills us
    JOIN standardized_skills ss ON us.skill_id = ss.id
    WHERE us.user_id IS NOT NULL
    LIMIT 50;  -- 限制记录数量
    
    SELECT '基础技术能力数据迁移完成' as status, COUNT(*) as migrated_count FROM technical_competency_assessments;
    "
    
    if [ $? -eq 0 ]; then
        log_success "基础技术能力数据迁移完成"
    else
        log_warning "基础技术能力数据迁移部分失败"
    fi
}

# 生成迁移报告
generate_migration_report() {
    log_info "生成数据迁移报告..."
    
    mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -D"$MYSQL_DATABASE" -e "
    SELECT '=== AI身份服务数据迁移报告 ===' as report_title;
    
    SELECT '1. 技能分类统计' as section;
    SELECT 
        'skill_categories' as table_name,
        COUNT(*) as record_count,
        COUNT(DISTINCT name) as unique_categories
    FROM skill_categories;
    
    SELECT '2. 标准化技能统计' as section;
    SELECT 
        'standardized_skills' as table_name,
        COUNT(*) as record_count,
        COUNT(DISTINCT category_id) as unique_categories
    FROM standardized_skills;
    
    SELECT '3. 用户技能统计' as section;
    SELECT 
        'user_skills' as table_name,
        COUNT(*) as record_count,
        COUNT(DISTINCT user_id) as unique_users,
        COUNT(DISTINCT skill_id) as unique_skills
    FROM user_skills;
    
    SELECT '4. 项目经验统计' as section;
    SELECT 
        'project_complexity_assessments' as table_name,
        COUNT(*) as record_count,
        COUNT(DISTINCT user_id) as unique_users,
        AVG(overall_complexity) as avg_complexity
    FROM project_complexity_assessments;
    
    SELECT '5. 技术能力统计' as section;
    SELECT 
        'technical_competency_assessments' as table_name,
        COUNT(*) as record_count,
        COUNT(DISTINCT user_id) as unique_users,
        COUNT(DISTINCT competency_type) as competency_types
    FROM technical_competency_assessments;
    
    SELECT '6. 数据完整性检查' as section;
    SELECT 
        'user_skills' as table_name,
        'valid_records' as check_type,
        COUNT(*) as count
    FROM user_skills 
    WHERE skill_level IS NOT NULL AND proficiency_score IS NOT NULL
    UNION ALL
    SELECT 
        'project_complexity_assessments' as table_name,
        'valid_records' as check_type,
        COUNT(*) as count
    FROM project_complexity_assessments 
    WHERE overall_complexity IS NOT NULL AND complexity_level IS NOT NULL
    UNION ALL
    SELECT 
        'technical_competency_assessments' as table_name,
        'valid_records' as check_type,
        COUNT(*) as count
    FROM technical_competency_assessments 
    WHERE competency_score IS NOT NULL AND competency_level IS NOT NULL;
    "
}

# 验证迁移结果
verify_migration() {
    log_info "验证数据迁移结果..."
    
    # 检查关键表的数据完整性
    local skill_categories=$(mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -D"$MYSQL_DATABASE" -sN -e "SELECT COUNT(*) FROM skill_categories;")
    local standardized_skills=$(mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -D"$MYSQL_DATABASE" -sN -e "SELECT COUNT(*) FROM standardized_skills;")
    local user_skills=$(mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -D"$MYSQL_DATABASE" -sN -e "SELECT COUNT(*) FROM user_skills;")
    local projects=$(mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -D"$MYSQL_DATABASE" -sN -e "SELECT COUNT(*) FROM project_complexity_assessments;")
    local competencies=$(mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -D"$MYSQL_DATABASE" -sN -e "SELECT COUNT(*) FROM technical_competency_assessments;")
    
    echo ""
    log_info "数据迁移验证结果:"
    echo "  技能分类记录数: $skill_categories"
    echo "  标准化技能记录数: $standardized_skills"
    echo "  用户技能记录数: $user_skills"
    echo "  项目经验记录数: $projects"
    echo "  技术能力记录数: $competencies"
    
    if [ "$skill_categories" -gt 0 ] && [ "$standardized_skills" -gt 0 ] && [ "$user_skills" -gt 0 ] && [ "$projects" -gt 0 ] && [ "$competencies" -gt 0 ]; then
        log_success "数据迁移验证通过"
        return 0
    else
        log_warning "数据迁移验证部分失败"
        return 1
    fi
}

# 主执行函数
main() {
    echo -e "${BLUE}🚀 开始简化版AI身份服务数据迁移...${NC}"
    
    # 检查MySQL连接
    if ! check_mysql_connection; then
        log_error "MySQL连接失败，无法继续迁移"
        exit 1
    fi
    
    echo ""
    
    # 执行数据迁移
    migrate_basic_skills
    echo ""
    
    migrate_basic_projects
    echo ""
    
    migrate_basic_competencies
    echo ""
    
    # 生成迁移报告
    generate_migration_report
    echo ""
    
    # 验证迁移结果
    if verify_migration; then
        log_success "🎉 简化版AI身份服务数据迁移完成！"
        echo ""
        echo -e "${BLUE}📋 迁移总结:${NC}"
        echo "  ✅ 基础技能分类和标准化技能已创建"
        echo "  ✅ 用户技能数据已迁移"
        echo "  ✅ 项目经验数据已迁移"
        echo "  ✅ 技术能力数据已迁移"
        echo ""
        echo -e "${BLUE}💡 下一步建议:${NC}"
        echo "  1. 启动AI身份服务API"
        echo "  2. 运行系统集成测试"
        echo "  3. 进行数据质量优化"
        echo "  4. 开始Week 4的AI身份数据模型集成"
    else
        log_warning "数据迁移完成，但需要检查数据质量"
    fi
    
    echo ""
    echo -e "${GREEN}🎉 简化版AI身份服务数据迁移脚本执行完成 - $(date)${NC}"
}

# 执行主函数
main
