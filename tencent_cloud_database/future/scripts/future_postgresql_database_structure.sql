-- Future版PostgreSQL数据库结构创建脚本
-- 版本: V1.0
-- 日期: 2025年10月5日
-- 描述: 创建Future版完整的PostgreSQL数据库结构和表单 (AI服务+向量数据)

-- ==============================================
-- 创建数据库
-- ==============================================
CREATE DATABASE jobfirst_future;

-- 连接到数据库
\c jobfirst_future;

-- ==============================================
-- 启用PostgreSQL扩展
-- ==============================================

-- 启用向量扩展 (pgvector)
CREATE EXTENSION IF NOT EXISTS vector;

-- 启用JSON扩展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 启用全文搜索扩展
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- ==============================================
-- 1. AI模型管理模块
-- ==============================================

-- 1.1 AI模型管理表
CREATE TABLE IF NOT EXISTS ai_models (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    version VARCHAR(20) NOT NULL,
    model_type VARCHAR(50) NOT NULL CHECK (model_type IN ('text_generation', 'embedding', 'classification', 'regression', 'recommendation')),
    provider VARCHAR(50) NOT NULL CHECK (provider IN ('openai', 'anthropic', 'google', 'azure', 'ollama', 'local', 'custom')),
    model_identifier VARCHAR(200) NOT NULL,
    description TEXT,
    parameters JSONB,
    performance_metrics JSONB,
    cost_per_token DECIMAL(10,8) DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 1.2 模型版本管理表
CREATE TABLE IF NOT EXISTS model_versions (
    id BIGSERIAL PRIMARY KEY,
    model_id BIGINT NOT NULL REFERENCES ai_models(id) ON DELETE CASCADE,
    version VARCHAR(20) NOT NULL,
    model_path VARCHAR(500),
    config JSONB,
    training_data_hash VARCHAR(64),
    performance_score DECIMAL(5,4),
    is_production BOOLEAN DEFAULT FALSE,
    deployed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(model_id, version)
);

-- ==============================================
-- 2. 企业AI分析模块
-- ==============================================

-- 2.1 企业AI画像表
CREATE TABLE IF NOT EXISTS company_ai_profiles (
    id BIGSERIAL PRIMARY KEY,
    company_id BIGINT NOT NULL,
    profile_type VARCHAR(50) NOT NULL CHECK (profile_type IN ('basic', 'detailed', 'competitive', 'culture', 'comprehensive')),
    profile_data JSONB NOT NULL,
    confidence_score DECIMAL(5,4),
    generated_by_model_id BIGINT REFERENCES ai_models(id) ON DELETE SET NULL,
    generated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE,
    is_valid BOOLEAN DEFAULT TRUE
);

-- 2.2 企业嵌入向量表
CREATE TABLE IF NOT EXISTS company_embeddings (
    id BIGSERIAL PRIMARY KEY,
    company_id BIGINT NOT NULL,
    embedding_type VARCHAR(50) NOT NULL CHECK (embedding_type IN ('description', 'culture', 'benefits', 'overall')),
    embedding_vector vector(1536), -- 使用pgvector扩展
    model_id BIGINT NOT NULL REFERENCES ai_models(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ==============================================
-- 3. 职位AI分析模块
-- ==============================================

-- 3.1 职位AI分析表
CREATE TABLE IF NOT EXISTS job_ai_analysis (
    id BIGSERIAL PRIMARY KEY,
    job_id INTEGER NOT NULL,
    analysis_type VARCHAR(50) NOT NULL CHECK (analysis_type IN ('description_enhancement', 'skill_extraction', 'salary_prediction', 'match_score', 'comprehensive')),
    analysis_result JSONB NOT NULL,
    confidence_score DECIMAL(5,4),
    generated_by_model_id BIGINT REFERENCES ai_models(id) ON DELETE SET NULL,
    generated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE,
    is_valid BOOLEAN DEFAULT TRUE
);

-- 3.2 职位嵌入向量表
CREATE TABLE IF NOT EXISTS job_embeddings (
    id BIGSERIAL PRIMARY KEY,
    job_id INTEGER NOT NULL,
    embedding_type VARCHAR(50) NOT NULL CHECK (embedding_type IN ('description', 'requirements', 'benefits', 'overall')),
    embedding_vector vector(1536),
    model_id BIGINT NOT NULL REFERENCES ai_models(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ==============================================
-- 4. 简历AI分析模块
-- ==============================================

-- 4.1 简历AI分析表
CREATE TABLE IF NOT EXISTS resume_ai_analysis (
    id BIGSERIAL PRIMARY KEY,
    resume_id BIGINT NOT NULL,
    analysis_type VARCHAR(50) NOT NULL CHECK (analysis_type IN ('skill_extraction', 'experience_analysis', 'strength_weakness', 'optimization_suggestions', 'comprehensive')),
    analysis_result JSONB NOT NULL,
    confidence_score DECIMAL(5,4),
    generated_by_model_id BIGINT REFERENCES ai_models(id) ON DELETE SET NULL,
    generated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE,
    is_valid BOOLEAN DEFAULT TRUE
);

-- 4.2 简历嵌入向量表
CREATE TABLE IF NOT EXISTS resume_embeddings (
    id BIGSERIAL PRIMARY KEY,
    resume_id BIGINT NOT NULL,
    embedding_type VARCHAR(50) NOT NULL CHECK (embedding_type IN ('overall', 'skills', 'experience', 'education', 'projects')),
    embedding_vector vector(1536),
    model_id BIGINT NOT NULL REFERENCES ai_models(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ==============================================
-- 5. 用户AI分析模块
-- ==============================================

-- 5.1 用户AI画像表
CREATE TABLE IF NOT EXISTS user_ai_profiles (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    profile_type VARCHAR(50) NOT NULL CHECK (profile_type IN ('basic', 'detailed', 'career_path', 'skill_assessment', 'comprehensive')),
    profile_data JSONB NOT NULL,
    confidence_score DECIMAL(5,4),
    generated_by_model_id BIGINT REFERENCES ai_models(id) ON DELETE SET NULL,
    generated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE,
    is_valid BOOLEAN DEFAULT TRUE
);

-- 5.2 用户嵌入向量表
CREATE TABLE IF NOT EXISTS user_embeddings (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    embedding_type VARCHAR(50) NOT NULL CHECK (embedding_type IN ('profile', 'skills', 'preferences', 'overall')),
    embedding_vector vector(1536),
    model_id BIGINT NOT NULL REFERENCES ai_models(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ==============================================
-- 6. AI匹配模块
-- ==============================================

-- 6.1 职位匹配表
CREATE TABLE IF NOT EXISTS job_matches (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    job_id INTEGER NOT NULL,
    match_score DECIMAL(5,4) NOT NULL,
    match_algorithm VARCHAR(50) NOT NULL,
    match_factors JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT TRUE
);

-- 6.2 简历匹配表
CREATE TABLE IF NOT EXISTS resume_matches (
    id BIGSERIAL PRIMARY KEY,
    job_id INTEGER NOT NULL,
    resume_id BIGINT NOT NULL,
    match_score DECIMAL(5,4) NOT NULL,
    match_algorithm VARCHAR(50) NOT NULL,
    match_factors JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT TRUE
);

-- ==============================================
-- 7. AI服务使用统计模块
-- ==============================================

-- 7.1 AI服务调用记录表
CREATE TABLE IF NOT EXISTS ai_service_calls (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT,
    service_type VARCHAR(50) NOT NULL,
    model_id BIGINT REFERENCES ai_models(id) ON DELETE SET NULL,
    input_tokens INTEGER DEFAULT 0,
    output_tokens INTEGER DEFAULT 0,
    total_tokens INTEGER DEFAULT 0,
    cost DECIMAL(10,6) DEFAULT 0,
    response_time_ms INTEGER,
    success BOOLEAN DEFAULT TRUE,
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 7.2 AI服务性能统计表
CREATE TABLE IF NOT EXISTS ai_service_stats (
    id BIGSERIAL PRIMARY KEY,
    model_id BIGINT NOT NULL REFERENCES ai_models(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    total_calls INTEGER DEFAULT 0,
    successful_calls INTEGER DEFAULT 0,
    failed_calls INTEGER DEFAULT 0,
    total_tokens INTEGER DEFAULT 0,
    total_cost DECIMAL(10,6) DEFAULT 0,
    avg_response_time_ms DECIMAL(10,2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(model_id, date)
);

-- ==============================================
-- 8. 向量搜索模块
-- ==============================================

-- 8.1 向量搜索历史表
CREATE TABLE IF NOT EXISTS vector_search_history (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT,
    search_query TEXT NOT NULL,
    search_type VARCHAR(50) NOT NULL,
    results_count INTEGER DEFAULT 0,
    search_duration_ms INTEGER,
    model_id BIGINT REFERENCES ai_models(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 8.2 向量相似度缓存表
CREATE TABLE IF NOT EXISTS vector_similarity_cache (
    id BIGSERIAL PRIMARY KEY,
    source_id BIGINT NOT NULL,
    target_id BIGINT NOT NULL,
    similarity_type VARCHAR(50) NOT NULL,
    similarity_score DECIMAL(5,4) NOT NULL,
    model_id BIGINT NOT NULL REFERENCES ai_models(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE,
    
    UNIQUE(source_id, target_id, similarity_type, model_id)
);

-- ==============================================
-- 创建索引
-- ==============================================

-- AI模型索引
CREATE INDEX IF NOT EXISTS idx_ai_models_name ON ai_models(name);
CREATE INDEX IF NOT EXISTS idx_ai_models_type ON ai_models(model_type);
CREATE INDEX IF NOT EXISTS idx_ai_models_provider ON ai_models(provider);
CREATE INDEX IF NOT EXISTS idx_ai_models_active ON ai_models(is_active);

-- 企业AI分析索引
CREATE INDEX IF NOT EXISTS idx_company_ai_profiles_company_id ON company_ai_profiles(company_id);
CREATE INDEX IF NOT EXISTS idx_company_ai_profiles_type ON company_ai_profiles(profile_type);
CREATE INDEX IF NOT EXISTS idx_company_embeddings_company_id ON company_embeddings(company_id);
CREATE INDEX IF NOT EXISTS idx_company_embeddings_type ON company_embeddings(embedding_type);

-- 职位AI分析索引
CREATE INDEX IF NOT EXISTS idx_job_ai_analysis_job_id ON job_ai_analysis(job_id);
CREATE INDEX IF NOT EXISTS idx_job_ai_analysis_type ON job_ai_analysis(analysis_type);
CREATE INDEX IF NOT EXISTS idx_job_embeddings_job_id ON job_embeddings(job_id);
CREATE INDEX IF NOT EXISTS idx_job_embeddings_type ON job_embeddings(embedding_type);

-- 简历AI分析索引
CREATE INDEX IF NOT EXISTS idx_resume_ai_analysis_resume_id ON resume_ai_analysis(resume_id);
CREATE INDEX IF NOT EXISTS idx_resume_ai_analysis_type ON resume_ai_analysis(analysis_type);
CREATE INDEX IF NOT EXISTS idx_resume_embeddings_resume_id ON resume_embeddings(resume_id);
CREATE INDEX IF NOT EXISTS idx_resume_embeddings_type ON resume_embeddings(embedding_type);

-- 用户AI分析索引
CREATE INDEX IF NOT EXISTS idx_user_ai_profiles_user_id ON user_ai_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_ai_profiles_type ON user_ai_profiles(profile_type);
CREATE INDEX IF NOT EXISTS idx_user_embeddings_user_id ON user_embeddings(user_id);
CREATE INDEX IF NOT EXISTS idx_user_embeddings_type ON user_embeddings(embedding_type);

-- 匹配索引
CREATE INDEX IF NOT EXISTS idx_job_matches_user_id ON job_matches(user_id);
CREATE INDEX IF NOT EXISTS idx_job_matches_job_id ON job_matches(job_id);
CREATE INDEX IF NOT EXISTS idx_job_matches_score ON job_matches(match_score);
CREATE INDEX IF NOT EXISTS idx_resume_matches_job_id ON resume_matches(job_id);
CREATE INDEX IF NOT EXISTS idx_resume_matches_resume_id ON resume_matches(resume_id);
CREATE INDEX IF NOT EXISTS idx_resume_matches_score ON resume_matches(match_score);

-- AI服务调用索引
CREATE INDEX IF NOT EXISTS idx_ai_service_calls_user_id ON ai_service_calls(user_id);
CREATE INDEX IF NOT EXISTS idx_ai_service_calls_service_type ON ai_service_calls(service_type);
CREATE INDEX IF NOT EXISTS idx_ai_service_calls_created_at ON ai_service_calls(created_at);
CREATE INDEX IF NOT EXISTS idx_ai_service_stats_model_id ON ai_service_stats(model_id);
CREATE INDEX IF NOT EXISTS idx_ai_service_stats_date ON ai_service_stats(date);

-- 向量搜索索引
CREATE INDEX IF NOT EXISTS idx_vector_search_history_user_id ON vector_search_history(user_id);
CREATE INDEX IF NOT EXISTS idx_vector_search_history_type ON vector_search_history(search_type);
CREATE INDEX IF NOT EXISTS idx_vector_similarity_cache_source_id ON vector_similarity_cache(source_id);
CREATE INDEX IF NOT EXISTS idx_vector_similarity_cache_target_id ON vector_similarity_cache(target_id);

-- ==============================================
-- 创建完成提示
-- ==============================================
SELECT 'Future版PostgreSQL数据库结构创建完成！' AS message;
SELECT '包含15个表：AI模型管理、企业分析、职位分析、简历分析、用户分析、匹配算法、服务统计、向量搜索' AS details;
