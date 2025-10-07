#!/bin/bash

# 数据迁移脚本：将现有数据迁移到AI身份服务表结构
# 基于Week 1-3完成的技能标准化、经验量化、能力评估系统

echo "🔄 AI身份服务数据迁移脚本 - $(date)"
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

# 迁移技能数据
migrate_skill_data() {
    log_info "开始迁移技能数据..."
    
    # 从现有数据中提取技能信息
    # 1. 从resume_metadata中提取技能
    log_info "从简历元数据中提取技能信息..."
    
    mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -D"$MYSQL_DATABASE" -e "
    -- 创建临时表存储提取的技能
    CREATE TEMPORARY TABLE temp_extracted_skills AS
    SELECT DISTINCT 
        rm.user_id,
        JSON_UNQUOTE(JSON_EXTRACT(skill_item.value, '$.name')) as skill_name,
        JSON_UNQUOTE(JSON_EXTRACT(skill_item.value, '$.category')) as skill_category,
        JSON_UNQUOTE(JSON_EXTRACT(skill_item.value, '$.level')) as skill_level,
        rm.created_at
    FROM resume_metadata rm
    CROSS JOIN JSON_TABLE(
        COALESCE(rm.parsed_data, '[]'),
        '\$[*]' COLUMNS (
            skill_item JSON PATH '\$'
        )
    ) AS skills
    CROSS JOIN JSON_TABLE(
        skill_item,
        '\$.skills[*]' COLUMNS (
            skill_item JSON PATH '\$'
        )
    ) AS skill_item
    WHERE JSON_UNQUOTE(JSON_EXTRACT(skill_item.value, '\$.name')) IS NOT NULL
    AND JSON_UNQUOTE(JSON_EXTRACT(skill_item.value, '\$.name')) != '';
    
    -- 插入到user_skills表
    INSERT IGNORE INTO user_skills (user_id, skill_id, skill_level, proficiency_score, years_experience, last_used_date, created_at, updated_at)
    SELECT 
        tes.user_id,
        COALESCE(ss.id, 1) as skill_id,  -- 默认技能ID为1，如果标准化技能不存在
        COALESCE(tes.skill_level, 'INTERMEDIATE') as skill_level,
        CASE 
            WHEN tes.skill_level = 'BEGINNER' THEN 1.0
            WHEN tes.skill_level = 'INTERMEDIATE' THEN 2.5
            WHEN tes.skill_level = 'ADVANCED' THEN 4.0
            WHEN tes.skill_level = 'EXPERT' THEN 5.0
            ELSE 2.5
        END as proficiency_score,
        2 as years_experience,  -- 默认2年经验
        NOW() as last_used_date,
        NOW() as created_at,
        NOW() as updated_at
    FROM temp_extracted_skills tes
    LEFT JOIN standardized_skills ss ON ss.name = tes.skill_name;
    
    -- 显示迁移结果
    SELECT '技能数据迁移完成' as status, COUNT(*) as migrated_count FROM user_skills;
    "
    
    if [ $? -eq 0 ]; then
        log_success "技能数据迁移完成"
    else
        log_warning "技能数据迁移部分失败"
    fi
}

# 迁移项目经验数据
migrate_project_data() {
    log_info "开始迁移项目经验数据..."
    
    # 从现有数据中提取项目经验
    mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -D"$MYSQL_DATABASE" -e "
    -- 创建临时表存储提取的项目经验
    CREATE TEMPORARY TABLE temp_extracted_projects AS
    SELECT DISTINCT 
        rm.user_id,
        JSON_UNQUOTE(JSON_EXTRACT(project_item.value, '\$.title')) as project_title,
        JSON_UNQUOTE(JSON_EXTRACT(project_item.value, '\$.description')) as project_description,
        JSON_UNQUOTE(JSON_EXTRACT(project_item.value, '\$.role')) as project_role,
        JSON_UNQUOTE(JSON_EXTRACT(project_item.value, '\$.duration')) as project_duration,
        JSON_UNQUOTE(JSON_EXTRACT(project_item.value, '\$.technologies')) as project_technologies,
        rm.created_at
    FROM resume_metadata rm
    CROSS JOIN JSON_TABLE(
        COALESCE(rm.parsed_data, '[]'),
        '\$[*]' COLUMNS (
            project_item JSON PATH '\$'
        )
    ) AS projects
    CROSS JOIN JSON_TABLE(
        project_item,
        '\$.experience[*]' COLUMNS (
            project_item JSON PATH '\$'
        )
    ) AS project_item
    WHERE JSON_UNQUOTE(JSON_EXTRACT(project_item.value, '\$.title')) IS NOT NULL
    AND JSON_UNQUOTE(JSON_EXTRACT(project_item.value, '\$.title')) != '';
    
    -- 插入到project_complexity_assessments表
    INSERT IGNORE INTO project_complexity_assessments (
        user_id, project_title, project_description, 
        technical_complexity, business_complexity, team_complexity, overall_complexity, 
        complexity_level, complexity_factors, assessment_timestamp, is_active, created_at, updated_at
    )
    SELECT 
        tep.user_id,
        tep.project_title,
        tep.project_description,
        -- 基于项目描述长度和内容复杂度评估技术复杂度
        CASE 
            WHEN CHAR_LENGTH(tep.project_description) > 500 THEN 4.0
            WHEN CHAR_LENGTH(tep.project_description) > 200 THEN 3.0
            WHEN CHAR_LENGTH(tep.project_description) > 100 THEN 2.0
            ELSE 1.0
        END as technical_complexity,
        -- 基于项目角色评估业务复杂度
        CASE 
            WHEN tep.project_role LIKE '%lead%' OR tep.project_role LIKE '%manager%' THEN 4.0
            WHEN tep.project_role LIKE '%senior%' THEN 3.0
            WHEN tep.project_role LIKE '%junior%' THEN 2.0
            ELSE 2.5
        END as business_complexity,
        -- 基于项目持续时间评估团队复杂度
        CASE 
            WHEN tep.project_duration LIKE '%year%' OR tep.project_duration LIKE '%年%' THEN 4.0
            WHEN tep.project_duration LIKE '%month%' OR tep.project_duration LIKE '%月%' THEN 3.0
            ELSE 2.0
        END as team_complexity,
        -- 整体复杂度
        (CASE 
            WHEN CHAR_LENGTH(tep.project_description) > 500 THEN 4.0
            WHEN CHAR_LENGTH(tep.project_description) > 200 THEN 3.0
            WHEN CHAR_LENGTH(tep.project_description) > 100 THEN 2.0
            ELSE 1.0
        END + 
        CASE 
            WHEN tep.project_role LIKE '%lead%' OR tep.project_role LIKE '%manager%' THEN 4.0
            WHEN tep.project_role LIKE '%senior%' THEN 3.0
            WHEN tep.project_role LIKE '%junior%' THEN 2.0
            ELSE 2.5
        END + 
        CASE 
            WHEN tep.project_duration LIKE '%year%' OR tep.project_duration LIKE '%年%' THEN 4.0
            WHEN tep.project_duration LIKE '%month%' OR tep.project_duration LIKE '%月%' THEN 3.0
            ELSE 2.0
        END) / 3 as overall_complexity,
        -- 复杂度等级
        CASE 
            WHEN (CASE 
                WHEN CHAR_LENGTH(tep.project_description) > 500 THEN 4.0
                WHEN CHAR_LENGTH(tep.project_description) > 200 THEN 3.0
                WHEN CHAR_LENGTH(tep.project_description) > 100 THEN 2.0
                ELSE 1.0
            END + 
            CASE 
                WHEN tep.project_role LIKE '%lead%' OR tep.project_role LIKE '%manager%' THEN 4.0
                WHEN tep.project_role LIKE '%senior%' THEN 3.0
                WHEN tep.project_role LIKE '%junior%' THEN 2.0
                ELSE 2.5
            END + 
            CASE 
                WHEN tep.project_duration LIKE '%year%' OR tep.project_duration LIKE '%年%' THEN 4.0
                WHEN tep.project_duration LIKE '%month%' OR tep.project_duration LIKE '%月%' THEN 3.0
                ELSE 2.0
            END) / 3 >= 4.0 THEN 'VERY_HIGH'
            WHEN (CASE 
                WHEN CHAR_LENGTH(tep.project_description) > 500 THEN 4.0
                WHEN CHAR_LENGTH(tep.project_description) > 200 THEN 3.0
                WHEN CHAR_LENGTH(tep.project_description) > 100 THEN 2.0
                ELSE 1.0
            END + 
            CASE 
                WHEN tep.project_role LIKE '%lead%' OR tep.project_role LIKE '%manager%' THEN 4.0
                WHEN tep.project_role LIKE '%senior%' THEN 3.0
                WHEN tep.project_role LIKE '%junior%' THEN 2.0
                ELSE 2.5
            END + 
            CASE 
                WHEN tep.project_duration LIKE '%year%' OR tep.project_duration LIKE '%年%' THEN 4.0
                WHEN tep.project_duration LIKE '%month%' OR tep.project_duration LIKE '%月%' THEN 3.0
                ELSE 2.0
            END) / 3 >= 3.0 THEN 'HIGH'
            WHEN (CASE 
                WHEN CHAR_LENGTH(tep.project_description) > 500 THEN 4.0
                WHEN CHAR_LENGTH(tep.project_description) > 200 THEN 3.0
                WHEN CHAR_LENGTH(tep.project_description) > 100 THEN 2.0
                ELSE 1.0
            END + 
            CASE 
                WHEN tep.project_role LIKE '%lead%' OR tep.project_role LIKE '%manager%' THEN 4.0
                WHEN tep.project_role LIKE '%senior%' THEN 3.0
                WHEN tep.project_role LIKE '%junior%' THEN 2.0
                ELSE 2.5
            END + 
            CASE 
                WHEN tep.project_duration LIKE '%year%' OR tep.project_duration LIKE '%月%' THEN 3.0
                ELSE 2.0
            END) / 3 >= 2.0 THEN 'MEDIUM'
            ELSE 'LOW'
        END as complexity_level,
        JSON_OBJECT(
            'role', tep.project_role,
            'duration', tep.project_duration,
            'technologies', tep.project_technologies,
            'source', 'resume_parsing'
        ) as complexity_factors,
        NOW() as assessment_timestamp,
        1 as is_active,
        NOW() as created_at,
        NOW() as updated_at
    FROM temp_extracted_projects tep
    WHERE tep.project_title IS NOT NULL AND tep.project_title != '';
    
    -- 显示迁移结果
    SELECT '项目经验数据迁移完成' as status, COUNT(*) as migrated_count FROM project_complexity_assessments;
    "
    
    if [ $? -eq 0 ]; then
        log_success "项目经验数据迁移完成"
    else
        log_warning "项目经验数据迁移部分失败"
    fi
}

# 迁移技术能力数据
migrate_competency_data() {
    log_info "开始迁移技术能力数据..."
    
    # 基于现有技能数据创建技术能力评估
    mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -D"$MYSQL_DATABASE" -e "
    -- 创建临时表存储技术能力评估
    CREATE TEMPORARY TABLE temp_competency_assessments AS
    SELECT DISTINCT
        us.user_id,
        CASE 
            WHEN ss.category = 'Programming' THEN 'PROGRAMMING'
            WHEN ss.category = 'Database' THEN 'DATABASE_DESIGN'
            WHEN ss.category = 'System' THEN 'SYSTEM_ARCHITECTURE'
            WHEN ss.category = 'Testing' THEN 'TESTING'
            WHEN ss.category = 'DevOps' THEN 'DEVOPS'
            WHEN ss.category = 'Security' THEN 'SECURITY'
            ELSE 'PROGRAMMING'
        END as competency_type,
        us.skill_level as competency_level,
        us.proficiency_score as competency_score,
        0.8 as confidence_score,  -- 默认置信度
        CONCAT('基于技能: ', ss.name, ' 等级: ', us.skill_level) as evidence_text,
        JSON_OBJECT(
            'skill_id', us.skill_id,
            'skill_name', ss.name,
            'years_experience', us.years_experience,
            'last_used', us.last_used_date
        ) as assessment_details,
        NOW() as assessment_timestamp
    FROM user_skills us
    JOIN standardized_skills ss ON us.skill_id = ss.id
    WHERE us.skill_level IS NOT NULL;
    
    -- 插入到technical_competency_assessments表
    INSERT IGNORE INTO technical_competency_assessments (
        user_id, competency_type, competency_level, competency_score, confidence_score,
        evidence_text, keywords_matched, assessment_details, assessment_timestamp, is_active, created_at, updated_at
    )
    SELECT 
        tca.user_id,
        tca.competency_type,
        tca.competency_level,
        tca.competency_score,
        tca.confidence_score,
        tca.evidence_text,
        JSON_OBJECT('skill', JSON_EXTRACT(tca.assessment_details, '$.skill_name')) as keywords_matched,
        tca.assessment_details,
        tca.assessment_timestamp,
        1 as is_active,
        NOW() as created_at,
        NOW() as updated_at
    FROM temp_competency_assessments tca;
    
    -- 显示迁移结果
    SELECT '技术能力数据迁移完成' as status, COUNT(*) as migrated_count FROM technical_competency_assessments;
    "
    
    if [ $? -eq 0 ]; then
        log_success "技术能力数据迁移完成"
    else
        log_warning "技术能力数据迁移部分失败"
    fi
}

# 创建数据质量报告
generate_migration_report() {
    log_info "生成数据迁移报告..."
    
    mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -D"$MYSQL_DATABASE" -e "
    SELECT '=== AI身份服务数据迁移报告 ===' as report_title;
    
    SELECT '1. 技能数据迁移统计' as section;
    SELECT 
        'user_skills' as table_name,
        COUNT(*) as record_count,
        COUNT(DISTINCT user_id) as unique_users,
        COUNT(DISTINCT skill_id) as unique_skills
    FROM user_skills;
    
    SELECT '2. 项目经验数据迁移统计' as section;
    SELECT 
        'project_complexity_assessments' as table_name,
        COUNT(*) as record_count,
        COUNT(DISTINCT user_id) as unique_users,
        AVG(overall_complexity) as avg_complexity
    FROM project_complexity_assessments;
    
    SELECT '3. 技术能力数据迁移统计' as section;
    SELECT 
        'technical_competency_assessments' as table_name,
        COUNT(*) as record_count,
        COUNT(DISTINCT user_id) as unique_users,
        COUNT(DISTINCT competency_type) as competency_types
    FROM technical_competency_assessments;
    
    SELECT '4. 数据质量检查' as section;
    SELECT 
        'Missing Skills' as issue,
        COUNT(*) as count
    FROM user_skills 
    WHERE skill_level IS NULL OR proficiency_score IS NULL
    UNION ALL
    SELECT 
        'Missing Projects' as issue,
        COUNT(*) as count
    FROM project_complexity_assessments 
    WHERE overall_complexity IS NULL OR complexity_level IS NULL
    UNION ALL
    SELECT 
        'Missing Competencies' as issue,
        COUNT(*) as count
    FROM technical_competency_assessments 
    WHERE competency_score IS NULL OR competency_level IS NULL;
    "
}

# 验证迁移结果
verify_migration() {
    log_info "验证数据迁移结果..."
    
    # 检查关键表的数据完整性
    local skill_count=$(mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -D"$MYSQL_DATABASE" -sN -e "SELECT COUNT(*) FROM user_skills;")
    local project_count=$(mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -D"$MYSQL_DATABASE" -sN -e "SELECT COUNT(*) FROM project_complexity_assessments;")
    local competency_count=$(mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -D"$MYSQL_DATABASE" -sN -e "SELECT COUNT(*) FROM technical_competency_assessments;")
    
    echo ""
    log_info "数据迁移验证结果:"
    echo "  技能数据记录数: $skill_count"
    echo "  项目经验记录数: $project_count"
    echo "  技术能力记录数: $competency_count"
    
    if [ "$skill_count" -gt 0 ] && [ "$project_count" -gt 0 ] && [ "$competency_count" -gt 0 ]; then
        log_success "数据迁移验证通过"
        return 0
    else
        log_warning "数据迁移验证部分失败"
        return 1
    fi
}

# 主执行函数
main() {
    echo -e "${BLUE}🚀 开始AI身份服务数据迁移...${NC}"
    
    # 检查MySQL连接
    if ! check_mysql_connection; then
        log_error "MySQL连接失败，无法继续迁移"
        exit 1
    fi
    
    echo ""
    
    # 执行数据迁移
    migrate_skill_data
    echo ""
    
    migrate_project_data
    echo ""
    
    migrate_competency_data
    echo ""
    
    # 生成迁移报告
    generate_migration_report
    echo ""
    
    # 验证迁移结果
    if verify_migration; then
        log_success "🎉 AI身份服务数据迁移完成！"
        echo ""
        echo -e "${BLUE}📋 迁移总结:${NC}"
        echo "  ✅ 技能数据已迁移到user_skills表"
        echo "  ✅ 项目经验已迁移到project_complexity_assessments表"
        echo "  ✅ 技术能力已迁移到technical_competency_assessments表"
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
    echo -e "${GREEN}🎉 AI身份服务数据迁移脚本执行完成 - $(date)${NC}"
}

# 执行主函数
main
